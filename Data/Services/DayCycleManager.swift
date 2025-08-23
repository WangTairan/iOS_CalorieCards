import Foundation
import UIKit
import Combine

/// 表示一个逻辑日的结束
public struct CycleEnded {
    public let key: String     // cycleKey（逻辑日 key）
    public let start: Date     // 本周期的开始
    public let end: Date       // 本周期的结束
}

/// 负责逻辑日的统一计算、结算、以及切换通知
public final class DayCycleManager {

    public static let shared = DayCycleManager()

    // MARK: - Public 状态
    public private(set) var start: Date              // 当前逻辑日的开始时间
    public private(set) var cutoffAtStart: Int       // 当时的 cutoff
    public private(set) var nextSwitch: Date         // 下一次切换点
    public private(set) var currentCutoff: Int       // 用户当前设置的 cutoff

    /// 事件流：当周期结束时，会发出 CycleEnded
    public var publisher: AnyPublisher<CycleEnded, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Private
    private let tzProvider: () -> TimeZone = { .current }
    private let store = Store()
    private let subject = PassthroughSubject<CycleEnded, Never>()

    private init() {
        if let s = store.load() {
            start = s.start
            cutoffAtStart = s.cutoffAtStart
            nextSwitch = s.nextSwitch
            currentCutoff = s.currentCutoff
            // 确保状态在未来
            handleTick(now: Date())
        } else {
            // 首次：初始化
            currentCutoff = store.loadCutoff() ?? 0
            let tz = tzProvider()
            start = Self.cycleStart(now: Date(), cutoffHour: currentCutoff, tz: tz)
            cutoffAtStart = currentCutoff
            nextSwitch = Self.nextOccurrence(ofHour: currentCutoff, after: start, tz: tz)
            store.save(start: start,
                       cutoffAtStart: cutoffAtStart,
                       nextSwitch: nextSwitch,
                       currentCutoff: currentCutoff)
        }
        observeAppLifecycle()
    }

    // MARK: - Public API

    /// 修改 cutoff（只影响未来，不影响当前 start）
    public func setCutoff(to newHour: Int) {
        let hour = min(max(newHour, 0), 23)
        guard hour != currentCutoff else { return }
        currentCutoff = hour
        // 重新计算下一次切换
        nextSwitch = Self.nextOccurrence(ofHour: hour, after: Date(), tz: tzProvider())
        persistStateOnly()
    }

    /// 当前逻辑日的 key（用于存储今天的数据）
    public func currentCycleKey() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime,
                             .withColonSeparatorInTime,
                             .withDashSeparatorInDate]
        return fmt.string(from: start)
    }

    /// 手动 tick（进入 Today 页 / 前台时调用）
    public func tick() {
        handleTick(now: Date())
    }

    // MARK: - 内部逻辑

    private func handleTick(now: Date) {
        let tz = tzProvider()
        while now >= nextSwitch {
            let oldKey = currentCycleKey()
            let oldStart = start
            let oldEnd = nextSwitch

            // 发布旧周期结束事件
            subject.send(CycleEnded(key: oldKey, start: oldStart, end: oldEnd))

            // 推进到新周期
            start = nextSwitch
            cutoffAtStart = currentCutoff
            nextSwitch = Self.nextOccurrence(ofHour: currentCutoff, after: start, tz: tz)
        }
        persistStateOnly()
    }

    private func persistStateOnly() {
        store.save(start: start,
                   cutoffAtStart: cutoffAtStart,
                   nextSwitch: nextSwitch,
                   currentCutoff: currentCutoff)
    }

    // MARK: - 生命周期监听
    private func observeAppLifecycle() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.tick()
        }
        #endif
        NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self else { return }
            self.nextSwitch = Self.nextOccurrence(ofHour: self.currentCutoff,
                                                  after: Date(),
                                                  tz: self.tzProvider())
            self.persistStateOnly()
        }
    }

    // MARK: - 日期计算
    private static func cycleStart(now: Date, cutoffHour: Int, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let shifted = cal.date(byAdding: .hour, value: -cutoffHour, to: now)!
        let dayStart = cal.startOfDay(for: shifted)
        return cal.date(byAdding: .hour, value: cutoffHour, to: dayStart)!
    }

    private static func nextOccurrence(ofHour hour: Int, after: Date, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var comps = cal.dateComponents(in: tz, from: after)
        comps.hour = hour
        comps.minute = 0
        comps.second = 0
        var candidate = cal.date(from: comps)

        if candidate == nil || candidate! <= after {
            let nextDay = cal.date(byAdding: .day, value: 1, to: after)!
            comps = cal.dateComponents(in: tz, from: nextDay)
            comps.hour = hour
            comps.minute = 0
            comps.second = 0
            candidate = cal.date(from: comps)
        }
        return candidate ?? after.addingTimeInterval(3600)
    }

    // MARK: - 存储
    private struct Store {
        private let kStart = "daycycle.start"
        private let kCutoffAtStart = "daycycle.cutoffAtStart"
        private let kNext = "daycycle.next"
        private let kCurrentCutoff = "daycycle.currentCutoff"
        private let kUserCutoff = "rollover.cutoffHour"

        func load() -> (start: Date, cutoffAtStart: Int,
                        nextSwitch: Date, currentCutoff: Int)? {
            let d = UserDefaults.standard
            guard let start = d.object(forKey: kStart) as? Date,
                  let next = d.object(forKey: kNext) as? Date else { return nil }
            let cutoffAtStart = d.integer(forKey: kCutoffAtStart)
            let currentCutoff = d.object(forKey: kCurrentCutoff) as? Int
                ?? loadCutoff() ?? 0
            return (start, cutoffAtStart, next, currentCutoff)
        }

        func loadCutoff() -> Int? {
            UserDefaults.standard.object(forKey: kUserCutoff) as? Int
        }

        func save(start: Date, cutoffAtStart: Int,
                  nextSwitch: Date, currentCutoff: Int) {
            let d = UserDefaults.standard
            d.set(start, forKey: kStart)
            d.set(cutoffAtStart, forKey: kCutoffAtStart)
            d.set(nextSwitch, forKey: kNext)
            d.set(currentCutoff, forKey: kCurrentCutoff)
        }
    }
}

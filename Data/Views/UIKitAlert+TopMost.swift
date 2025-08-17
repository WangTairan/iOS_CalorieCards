import UIKit

extension UIApplication {
    var topMost: UIViewController? {
        guard let s = connectedScenes.first as? UIWindowScene,
              let r = s.keyWindow?.rootViewController else { return nil }
        var top = r
        while let p = top.presentedViewController { top = p }
        return top
    }
}


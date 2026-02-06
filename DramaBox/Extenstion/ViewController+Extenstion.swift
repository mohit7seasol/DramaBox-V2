//
//  ViewController+Extenstion.swift
//  GBVersionApp_1
//
//  Created by iMac on 24/05/23.
//
import UIKit
import Foundation
//import MBProgressHUD
//import Loaf

extension UIViewController {
//    func ShowTostMessage(text:String,state:String)
//    {
//        if state == success
//        {
//            Loaf(text, state: .success, sender: self).show()
//        }
//        else if state == error
//        {
//            Loaf(text, state: .error, sender: self).show()
//        }
//        else if state == warning
//        {
//            Loaf(text, state: .warning, sender: self).show()
//        }
//        else if state == info
//        {
//            Loaf(text, state: .info, sender: self).show()
//        }
//        else if state == custome
//        {
//            Loaf.dismiss(sender: self, animated: false)
//            Loaf(text, state: .custom(.init(backgroundColor: Loaf_Colour, icon: UIImage(named: ""))), sender: self).show(.custom(2.0))
//        }
    
//    class public var storyboardID: String {
//        return "\(self)"
//    }
//    
//    static public func instantiate(fromAppStoryboard appStoryboard: AppStoryboard) -> Self {
//        return appStoryboard.viewController(viewControllerClass: self)
//    }
    
    func showAlertDeleteCancel(withTitle title: String, withMessage message:String, completion: @escaping (Bool) -> ()) {
        let alert = UIAlertController(title: title, message: message.localized(), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            completion(true)
        }))
    
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true)
        })
        
    }

//    func ProgressViewShow(uiView:UIView) {
//        
//        DispatchQueue.main.async {
//            let Indicator = MBProgressHUD.showAdded(to: uiView, animated: true)
//            Indicator.label.text = "Loading..."
//            uiView.isUserInteractionEnabled = false
//            Indicator.show(animated: true)
//
////          MBProgressHUD.showAdded(to: uiView, animated: true)
//        }
//    }
    
//    func ProgressViewHide(uiView:UIView) {
//        
//        DispatchQueue.main.async {
//            uiView.isUserInteractionEnabled = true
//            MBProgressHUD.hide(for:uiView, animated: true)
//        }
//    }

    @objc func navigateHidden() ->Void
    {
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    @objc func navigatebackTwo()
    {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
    }
    
    
    @objc func setHomeDashBoard() {
        
    }
    
    
    
    @objc func setModelProfileDashboard()
    {

        
    }

    @objc func setLoginScreen()
    {
    }

}

extension UIViewController
{
    func anyToString(_ value: Any?) -> String {
      return String(describing: value ?? "")
    }
}

extension UIViewController {
    
    func showToast(message : String, font: UIFont) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func imageIsNullOrNot(imageName : UIImage)-> Bool
    {
       let size = CGSize(width: 0, height: 0)
       if (imageName.size.width == size.width)
        {
            return false
        }
        else
        {
            return true
        }
    }
}

extension UIViewController {
    var topViewController: UIViewController? {
        return self.topViewController(currentViewController: self)
    }

    private func topViewController(currentViewController: UIViewController) -> UIViewController {
        if let tabBarController = currentViewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topViewController(currentViewController: selectedViewController)
        } else if let navigationController = currentViewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topViewController(currentViewController: visibleViewController)
       } else if let presentedViewController = currentViewController.presentedViewController {
            return self.topViewController(currentViewController: presentedViewController)
       } else {
            return currentViewController
        }
    }
}

extension UIViewController:UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}



// MARK: - Classes Extension String to date
extension String {
    
    func toDate(dateFormat format: String, convertdateFormat convertformat: String) -> Date {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.long
        dateFormatter.dateFormat = format
        
        let convertedDate = dateFormatter.date(from: self)
        dateFormatter.dateFormat = convertformat
        
        let date = dateFormatter.string(from: convertedDate!)
        let final_date = dateFormatter.date(from: date)
        
        return final_date!
    }
    
    func toDateUTC(dateFormat format: String) -> Date {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let date = dateFormatter.date(from: self)
        return date!
    }
    
    func toDateString(dateFormat format: String, convertdateFormat convertformat: String) -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = format
        let convertedDate = dateFormatter.date(from: self)
        
        dateFormatter.dateFormat = convertformat
        let date = dateFormatter.string(from: convertedDate!)
        
        return date
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

// MARK:- Date Extension
extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd MMM yyyy" //"MMM dd, yyyy hh:mm a"
        let gmt = NSTimeZone.system as NSTimeZone
        dateFormat.timeZone = gmt as TimeZone
        
        if years(from: date)   > 0 {
            return "\(years(from: date)) year ago"
//            return dateFormat.string(from: date)  // "\(years(from: date))y ago"
        }
        
        if months(from: date)  > 0 {
            return "\(months(from: date)) months ago"
//            return dateFormat.string(from: date) // "\(months(from: date))M ago"
        }
        
        if weeks(from: date)   > 0 {
            return "\(weeks(from: date)) weeks ago"
//            return dateFormat.string(from: date) // "\(weeks(from: date))w ago"
        }
        
        if days(from: date)    > 0 {
            return "\(days(from: date)) days ago"
//            return dateFormat.string(from: date) // "\(days(from: date))d ago"
        }
        
        if hours(from: date)   > 0 {
            return "\(hours(from: date))h ago"
        }
        
        if minutes(from: date) > 0 {
            return "\(minutes(from: date))m ago"
        }
        
        if seconds(from: date) > 56 {
            return "\(seconds(from: date))s ago"
        }
        
        if seconds(from: date) <= 55 {
            return "now"
        }
        
        return ""
    }

    // To get Previous/Next Year/Month from date
//    func getNextYear() -> Date? {
//        return Calendar.current.date(byAdding: .year, value: 1, to: self)
//    }
//
//    func getPreviousYear() -> Date? {
//        return Calendar.current.date(byAdding: .year, value: -1, to: self)
//    }
//
//    func getNextMonth() -> Date? {
//        return Calendar.current.date(byAdding: .month, value: 1, to: self)
//    }
//
//    func getPreviousMonth() -> Date? {
//        return Calendar.current.date(byAdding: .month, value: -1, to: self)
//    }
}

extension Int {
    
    var seconds: Int {
        return self
    }
    
    var minutes: Int {
        return self.seconds * 60
    }
    
    var hours: Int {
        return self.minutes * 60
    }
    
    var days: Int {
        return self.hours * 24
    }
    
    var weeks: Int {
        return self.days * 7
    }
    
    var months: Int {
        return self.weeks * 4
    }
    
    var years: Int {
        return self.months * 12
    }
}

extension UITextField
{
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

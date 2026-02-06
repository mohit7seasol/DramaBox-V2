
import Foundation
import UIKit
import SystemConfiguration
import CoreLocation
import GoogleMobileAds

//MARK:- COLOR RGB
public func Color_RGBA(_ R: Int,_ G: Int,_ B: Int,_ A: Int) -> UIColor
{
    return UIColor(red: CGFloat(R)/255.0, green: CGFloat(G)/255.0, blue: CGFloat(B)/255.0, alpha :CGFloat(A))
}

//Set boreder to UI controller
public func SetCornerToView(_ view : UIView,BorderColor : UIColor,BorderWidth : CGFloat)    {
    view.layer.borderColor = BorderColor.cgColor;
    view.layer.borderWidth = BorderWidth;
}

public func setBorder(viewName: UIView , borderwidth : Int , borderColor: UIColor , cornerRadius: CGFloat, bgColor: UIColor)
{
    viewName.backgroundColor = bgColor
    viewName.layer.borderWidth = CGFloat(borderwidth)
    viewName.layer.borderColor = borderColor.cgColor
    viewName.layer.cornerRadius = cornerRadius
}

//MARK:ShowAlert
func showAlertMsg(Message: String, AutoHide:Bool) -> Void {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: "", message: Message, preferredStyle: UIAlertController.Style.alert)
        
        if AutoHide == true
        {
            //alert.dismiss(animated: true, completion:nil)
            let deadlineTime = DispatchTime.now() + .seconds(4)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                print("Alert Dismiss")
                alert.dismiss(animated: true, completion:nil)
            }
        }
        else
        {
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        }
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

public func cornerRadius(viewName:UIView, radius: CGFloat)
{
    viewName.layer.cornerRadius = radius
    viewName.layer.masksToBounds = true
}
func setCornerRadius( objLayer: CALayer, radiusValue:CGFloat) -> Void {
    objLayer.cornerRadius = radiusValue
    objLayer.masksToBounds = true
}

public func SCREENWIDTH() -> CGFloat
{
    let screenSize = UIScreen.main.bounds
    return screenSize.width
}

public func SCREENHEIGHT() -> CGFloat
{
    let screenSize = UIScreen.main.bounds
    return screenSize.height
}
public func ShowNetworkIndicator(xx :Bool)
{
    UIApplication.shared.isNetworkActivityIndicatorVisible = xx
}

//MARK:- FONT
public func FontWithSize(_ fname: String,_ fsize: Int) -> UIFont
{
    return UIFont(name: fname, size: CGFloat(fsize))!
}

//Most top view Controller

public var mostTopViewController: UIViewController? {
    get {
        return UIApplication.shared.windows[0].rootViewController
    }
    set {
        UIApplication.shared.windows[0].rootViewController = newValue
    }
    
}
func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}

public func forTrailingZero(temp: Double) -> String {
    let tempVar = String(format: "%g", temp)
    return tempVar
}

public func isValidUserName(usernameStr:String) -> Bool {
    
    let regex = ".*[^A-Za-z0-9].* "
    let testString = NSPredicate(format:"SELF MATCHES %@", regex)
    return testString.evaluate(with: usernameStr)
}

public func validateEmailAddress(_ txtVal: UITextField ,withMessage msg: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    if(emailTest.evaluate(with: txtVal.text) != true)
    {
        showAlertMsg(Message: msg, AutoHide: false)
        return false
    }
    return true
}

public func isValidPassword(_ txtVal: UITextField ,withMessage msg: String) -> Bool {
    let passwordRegex = "^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z])[0-9a-zA-Z!@#$%^&*()\\-_=+{}|?>.<,:;~`’]{8,}$"
    let passwordTest = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
    if(passwordTest.evaluate(with: txtVal.text) != true)
    {
        showAlertMsg(Message: msg, AutoHide: false)
        return false
    }
    return true
}

public func convertStringToDictionary(str:String) -> [String: Any]? {
    if let data = str.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
    }
    return nil
}

func isConnectedToNetwork() -> Bool
{
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    })
    else
    {
        return false
    }
    
    var flags : SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        return false
    }
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let available =  (isReachable && !needsConnection)
    if(available)
    {
        return true
    }
    else
    {
        //internet false
        //        showAlertMsg(Message: "INTERNET_LOSS", AutoHide: true)
        return false
    }
}

func animateview(vw1 : UIView,vw2:UIView)
{
    UIView.animate(withDuration: 0.1,
                   delay: 0.1,
                   options: UIView.AnimationOptions.curveEaseIn,
                   animations: { () -> Void in
        vw1.alpha = 0;
        vw2.alpha = 1;
    }, completion: { (finished) -> Void in
        vw1.isHidden = true;
    })
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    
    let size = image.size
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        
        newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}

func getPhoneNumber(pn: String) -> String {
    let str1 = pn.replacingOccurrences(of: "(", with: "")
    let str2 = str1.replacingOccurrences(of: ")", with: "")
    let str3 = str2.replacingOccurrences(of: " ", with: "")
    let str4 = str3.replacingOccurrences(of: "-", with: "")
    return str4
}

public func getKeyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
        let keyWindow = UIApplication.shared.connectedScenes
        //               .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return keyWindow
        
    } else {
        return  UIApplication.shared.keyWindow
    }
}

extension UIButton
{
    func UpdateBtnColor(name: String, myColor: UIColor)
    {
        let origImage = UIImage(named: name)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        self.setImage(tintedImage, for: .normal)
        self.tintColor = myColor
    }
}

extension UIImageView
{
    func setImageColor(color: UIColor, name: String) {
        self.image = UIImage(named: name)
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

extension UIButton
{
    func setButtonImageColor(color: UIColor, name: String) {
        let origImage = UIImage(named: name)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        self.setImage(tintedImage, for: .normal)
        self.tintColor = color
    }
}

// MARK: Convert Date to String
extension Date
{
    func toString(dateFormat format : String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
extension String
{
    func toDate(dateFormat format : String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)!
    }
}
// MARK: - Ad intigration

extension UIViewController{
    
    func showInterAdClick() {
        if Subscribe.get() == false {
            adsPlus = adsPlus+1
            if  adsPlus % adsCount == 0 {
                AdsManager.shared.presentInterstitialAd1(vc: self)
            }
        }
    }
    
    func showInterAdAllTime() {
        if Subscribe.get() == false {
            AdsManager.shared.presentInterstitialAd1(vc: self)
        }
    }
}
func getAdSize(for activity: UIViewController) -> AdSize {
    let defaultDisplay = UIScreen.main
    let displayMetrics = UIScreen.main.bounds.size
    let widthInPoints = displayMetrics.width
    
    let adSize = currentOrientationAnchoredAdaptiveBanner(width: widthInPoints)
    
    return adSize
}

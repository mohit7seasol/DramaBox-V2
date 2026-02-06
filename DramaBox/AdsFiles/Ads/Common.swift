//
//  Common.swift
//  Taxi
//
//  Created by Bhavin
//  skype : bhavin.bhadani
//
import UIKit

open class Common {

    static let token = String()
     static let instance = Common()
     var effectView = UIView()
     var activityIndicator = UIActivityIndicatorView()
     public init(){}
    
    class func showAlert(with title:String?, message:String?, for viewController:UIViewController){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true, completion: nil)
    }

    class func getProffessionalsStoryBourd() -> UIStoryboard{
       var mainView: UIStoryboard!
       mainView = UIStoryboard(name: "Professionals", bundle: nil)
       return mainView
    }
    
    func activityIndicator(view:UIViewController) {
    }
 
     func activity(view:UIViewController) {
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
     }
  
    func toString(_ value: Any?) -> String {
      return String(describing: value ?? "")
    }

    func createProfilePictureWithName(name:String,frame:CGRect) -> UIImage{
      //  print(frame.height)
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 300.0, height: 300.0)
        lblNameInitialize.textColor = UIColor.white
        lblNameInitialize.text = name.uppercased().getAcronyms()
        if(frame.height == 60){
            lblNameInitialize.font = lblNameInitialize.font.withSize(100)
        }
        else if(frame.height <= 100){
           lblNameInitialize.font = lblNameInitialize.font.withSize(150)
        }
        else{
             lblNameInitialize.font =  lblNameInitialize.font.withSize(180)
        }
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.backgroundColor = UIColor.black
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imag =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imag ?? UIImage(named:"User")!
    }
    
      func createProfileDirectlyWithInitial(name: String, frame: CGRect) -> UIImage{
        
        let lblNameInitialize = UILabel()
        lblNameInitialize.frame.size = CGSize(width: 300.0, height: 300.0)
        lblNameInitialize.textColor =  UIColor.white
        lblNameInitialize.text = name.uppercased()
        if(frame.height == 60) {
            lblNameInitialize.font = lblNameInitialize.font.withSize(100)
        }
        else if(frame.height <= 100) {
            lblNameInitialize.font = lblNameInitialize.font.withSize(130)
        }
        else {
            lblNameInitialize.font =  lblNameInitialize.font.withSize(180)
        }
        lblNameInitialize.textAlignment = NSTextAlignment.center
        lblNameInitialize.backgroundColor = UIColor.black
        
        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imag =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imag ?? UIImage(named:"User")!
    }
    
    func isUserLoggedIn() -> Bool {
        if UserDefaults.standard.data(forKey: "user") != nil{
            return true
        } else {
            return false
        }
    }
        
    func getReadbleFormateString(datestr:String) -> String
    {
        let dateString = datestr.prefix(10)
      
        return String(dateString)
    }
    
    func getYearMonthFromString(myDate: Date) -> String
    {
        let formatter =  DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let output = formatter.string(from: myDate)
        
        return output
    }
    
    func getYearFromString(dateString : Date) -> String
    {
        let calendar = NSCalendar.current
        let dateComponets = calendar.dateComponents([.year, .month], from: dateString)
        let year = dateComponets.year

        return "\(year!)"
    }
    
    func getMonthFromString(dateString : Date) -> String
    {
        let calendar = NSCalendar.current
        let dateComponets = calendar.dateComponents([ .month], from: dateString)
        let month = dateComponets.month
        
        return "\(month!)"
    }
   
    func getMonthStringFromDate(dateString : Date) -> String
    {
        let dateFormattor = DateFormatter()
        dateFormattor.dateFormat = "MMMM"
        let month = dateFormattor.string(from: dateString)
        return "\(month)"
    }
    
   
    func getAPIKey() -> String {
            return "7UI93434899384934IX"
    }
    
    func getToken() -> String {
        if let key = UserDefaults.standard.value(forKey: "api-key") as? String{
            return key
        } else {
            return ""
        }
    }
    
    func removeUserdata() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
        
    func getMainFormattedDate(date: String, getStrDate: String) -> String {
        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateObj = dateFormatter.date(from: date) ?? Date()
        dateFormatter.dateFormat = getStrDate //"dd.MM.YYYY hh:mm a"
        return dateFormatter.string(from: dateObj)
    }

    func logOut(){
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
    }
    
    func setGradient(view: UIView)
    {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [UIColor.black,UIColor.white]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = view.layer.frame
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    //MARK:- CAMERA & GALLERY NOT ALLOWING ACCESS - ALERT
    func alertToEncourageCameraAccessWhenApplicationStarts()
    {
        //Camera not available - Alert
        let internetUnavailableAlertController = UIAlertController (title: "Camera Unavailable", message: "Please select to see if device settings on to camera access", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil) //(url as URL)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        internetUnavailableAlertController .addAction(settingsAction)
        internetUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(internetUnavailableAlertController , animated: true, completion: nil)
    }
    func alertToEncouragePhotoLibraryLimited()
    {
        //Photo Library not available - Alert
//        let cameraUnavailableAlertController = UIAlertController (title: "Limited Photo Library", message: "Please check device settings to allow DISGO to have photo library access in order to DISGO and choose you to edit selected photo", preferredStyle: .alert)
        
        let cameraUnavailableAlertController = UIAlertController (title: "Limited Photo Library", message: "Please check device settings to allow Model to have photo library access in order to add more allowed photos.", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(settingsAction)
        cameraUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }

    func alertToEncouragePhotoLibraryAccessWhenApplicationStarts()
    {
        //Photo Library not available - Alert
        let cameraUnavailableAlertController = UIAlertController (title: "Photo Library Unavailable", message: "Please check device settings to allow Model to have photo library access in order to share from your camera roll to Model and allow you to use features that include photos", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(settingsAction)
        cameraUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }
    
    func alertToFaceRecognization()
    {
        //Photo Library not available - Alert
        let cameraUnavailableAlertController = UIAlertController (title: "Disgo", message: "Please check device settings to allow Model to have Face recognition access in order to set face lock to Model and allow to using Face ID authenticate recognition.", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(settingsAction)
        cameraUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }

    func alertToEncourageCalandarEvent()
    {
        //Photo Library not available - Alert
        let cameraUnavailableAlertController = UIAlertController (title: "Photo Library Unavailable", message: "Please check device settings to allow Model to have calandar event access in order to share from added activity event", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(settingsAction)
        cameraUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }

    func alertToEncourageLocationAccessWhenApplicationStarts()
    {
        //Photo Library not available - Alert
        let cameraUnavailableAlertController = UIAlertController (title: "Please enable location settings", message: "Please check device settings to allow DISGO to have location access in order to use your location to find relevant experiences and posts near you.", preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        cameraUnavailableAlertController .addAction(settingsAction)
        cameraUnavailableAlertController .addAction(cancelAction)
        UIApplication.shared.windows[0].rootViewController!.present(cameraUnavailableAlertController , animated: true, completion: nil)
    }

    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

}
extension String
{   //  returns false if passed string is nil or empty
    static func isNilOrEmpty(_ string:String?) -> Bool
    {   if  string == nil
    {
        return true
        }
        return string!.isEmpty
    }
   
        public func getAcronyms(separator: String = "") -> String
        {
            let acronyms = self.components(separatedBy: " ").reduce("") { first, next in
                
                (first) + (next.first.map { String($0) } ?? ""
                )
            }

            return acronyms;
        }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

extension Date {
    func startOfMonth() -> Date? {
        let comp: DateComponents = Calendar.current.dateComponents([.year, .month, .hour], from: Calendar.current.startOfDay(for: self))
        return Calendar.current.date(from: comp)!
    }

    func endOfMonth() -> Date? {
        var comp: DateComponents = Calendar.current.dateComponents([.month, .day, .hour], from: Calendar.current.startOfDay(for: self))
        comp.month = 1
        comp.day = -1
        return Calendar.current.date(byAdding: comp, to: self.startOfMonth()!)
    }
}

extension UIImage {
  var pngRepresentationData: Data? {
    return self.pngData()
  }
  var jpegRepresentationData: Data? {
    return self.jpegData(compressionQuality: 0.8)
  }
    func applyBlur(radius: CGFloat) -> UIImage? {
        let context = CIContext(options: nil)
        guard let ciImage = CIImage(image: self),
              let clampFilter = CIFilter(name: "CIAffineClamp"),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return self
        }
        
        clampFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        blurFilter.setValue(clampFilter.outputImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let output = blurFilter.outputImage,
              let cgImage = context.createCGImage(output, from: ciImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: cgImage)
    }
}

class CustomUITextField: UITextField {
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(UIResponderStandardEditActions.paste(_:)) {
      return true
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

extension UITextField
{
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

extension Notification.Name {
    static let splashOpenClose = Notification.Name("splashOpenClose")
    static let splashOpenNill = Notification.Name("splashOpenNill")
    static let closePremium = Notification.Name("closePremium")
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let triggerRateCheck = Notification.Name("triggerRateCheck")
}

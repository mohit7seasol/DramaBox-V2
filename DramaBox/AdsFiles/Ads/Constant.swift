import Foundation
import UIKit
import Photos

let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate

var countdown10Time: Int = 600 // 5 minutes (300 seconds)
var timer10Min: Timer?

let ACCESS = "AKIA2FCATE7MLGSZBHML"
let SECRET = "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"
let S3_BUCKET_NAME = "stag-7seasol-crm"
var isShowAd : Bool = true

func topSafeArea() -> CGFloat{
    if #available(iOS 11.0, *) {
        let window = UIApplication.shared.windows.first
        return window?.safeAreaInsets.top ?? 0
    }
    return 0
}

func bottomSafeArea() -> CGFloat{
    if #available(iOS 11.0, *) {
        let window = UIApplication.shared.windows.first
        return window?.safeAreaInsets.bottom ?? 0
    }
    return 0
}



var isAppEnterInBackgound = false
var isFromStart = false

let IN_APP_PURCHASE_IDS = ["","",""]
let SHARE_SECRET = ""

var CONNECTED_DEVICE = ""

var isImageCast = Bool()
var isCastType = 0
var videoCastImageDummy = UIImage()
var castAssetName = String()
var videoCastStatus = Bool()
var castAssetURL = String()
let MESSAGE_ERR_NETWORK = "No internet connection. Try again.."
var appStart:Bool = false
var NativeFiald:Bool = false
var isComeFromHome: Bool = false
var fromFirst:Bool = false
var fromSubInter:Bool = false
var isfromeAppStart:Bool = false
var isFromVideoBack:Bool = false
var closeInter:Bool = false

var urlLive:String?
/// Privacy & Terms

//var APP_ID = ""
var instaAPI = ""

var addButtonColor = ""
var bannerId = "ca-app-pub-3940256099942544/8388050270"
var nativeId = ""
var small_native = ""
var interstialId = ""
var interstialId2 = ""
var appopenId = ""
var rewardId = ""
var nativeId2 = ""
var appOpenHome = false
var isComeFromSplash = false
var adsCount = 4
var adsPlus = 0
var adsCountNative = 0
var adsPlusNative = 0
var isDelete = 0

var prefixUrl : String = "" 
var NewsAPI = ""

var fullScreenNativeId = ""
var inlineNativeBannerId = ""
var smallNativeBannerId = ""
var isIAPON = "b"
var IAPRequiredForTrailor = "b"

var SERVER_ERROR = "Something went wrong please try agin sometime."
var isInterShow:Bool = false
var fromChannel:Bool = false
var firstTime:Bool = false
var interFaild:Bool = false
var sub:Bool = false
var isShowDrama = "A"

//test json
let getJSON : String = "https://7seasol-application.s3.amazonaws.com/admin_prod/pbz-grfgvat-arj.json"
//let getJSON : String =  "https://7seasol-application.s3.amazonaws.com/admin_prod/pbz-grfgvat-arj.json"

//live json
//let getJSON : String = "https://7seasol-application.s3.amazonaws.com/admin_prod/pbz-fben-cvkb-fgernz.json"



//MARK: Comman functions & Extensions
func showAlertMessage(titleStr:String, messageStr:String) -> Void {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: titleStr, message: messageStr, preferredStyle: UIAlertController.Style.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        UIApplication.shared.windows[0].rootViewController!.present(alert, animated: true, completion: nil)
    }
}

// Storyboards
struct STORYBOARD {
    static var MAIN = UIStoryboard(name: "Main", bundle: nil)
}

struct IMAGE {
    static var PLACEHOLDER = ""
}

// Notifications
struct NOTIFICATION {
    static var RELOAD = NSNotification.Name(rawValue: "RELOAD_DATA_KEY")
    static var localization = NSNotification.Name(rawValue: "localization")
}

enum mediaType {
    case Photos
    case Videos
    case Music
    case Web
    case ConnectDevice
}

enum modeOfPlay {
    case all
    case shuffle
    case off
    case single
}


enum DateFormat:String {
  
    case ymd = "yyyy-MM-dd"
    case ddmmyy = "dd/MM/yy"
    case mmmddyyyy = "MMM dd, yyyy"
    case mmmddyyyhhmm = "MMM dd,yyyy hh:mm a"
}

enum HttpResponseStatusCode: Int {
    case ok = 200
    case badRequest = 400
    case noAuthorization = 401
}

struct AppConstant {
    static let AppName = "Sora Pixo"
    static let appID = "6758206121"
    static let privacyPolicyURL = "https://saifalnahyan.blogspot.com/2026/01/privacy-policy.html"
    static let tremsOfUseURL = "https://saifalnahyan.blogspot.com/2026/01/terms-conditions.html"
    static let EULA = "https://saifalnahyan.blogspot.com/2026/01/eula.html"
    static let aboutUsURL = "https://www.google.com"
    static let quizID = "62d10f2bb1a7fc8769355c3d"
    static let AppStoreLink = "https://apps.apple.com/app/id\(appID)"
}
// MARK: - Storyboard Names
struct StoryboardName {
    static let main       = "Main"
    static let language   = "Language"
    static let onboarding = "OnBoarding"
    static let quiz = "Quiz"
}

// MARK: - View Controller Identifiers
struct Controllers {
    static let homeVC       = "HomeVC"
    static let o1VC = "O1VC"
    static let tabBarVC = "TabBarVC"
    static let languageVC = "LanguageVC"
}

// MARK: - Cell Identifiers
struct Cell {
    static let languageCell   = "ChooseLanguageCell"
}

// MARK: - Segue Identifiers
struct SegueID {
    static let showDetails    = "ShowDetailsSegue"
}

// MARK: - Notification Names
extension Notification.Name {
    static let userLoggedIn   = Notification.Name("UserLoggedIn")
    static let moviesDataUpdated = Notification.Name("moviesDataUpdated")
    static let discoverPageChanged = Notification.Name("discoverPageChanged")
}

// MARK: - Reusable Keys (e.g. UserDefaults, API Keys)
struct KeyName {
    static let authToken   = "AuthToken"
}
// MARK: - UserDefaultKeys
struct UserDefaultKeys {
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let selectedLanguage  = "selectedLanguage"
}

struct LocalizedStrings {
    static let saveAll                                 = "Save All Media Files"
    static let easilySave                              = "Easily save images, videos, & more to your device."
    static let editPhoto                               = "Edit Photo & Video"
    static let easilyEdit                              = "Easily edit your photos & videos in one place."
    static let next                                    = "Next"
}

class FontManager {
    static let shared = FontManager()
    
    enum CustomFont: String {
        case roboto = "Roboto"
        case robotoSerif = "RobotoSerif"
        
        var displayName: String {
            switch self {
            case .roboto: return "Roboto"
            case .robotoSerif: return "RobotoSerif"
            }
        }
    }
    
    // Get all available fonts
    var availableFonts: [CustomFont] {
        return [.roboto, .robotoSerif]
    }
    
    // Get UIFont for custom font
    func font(for customFont: CustomFont, size: CGFloat) -> UIFont {
        if let font = UIFont(name: customFont.rawValue, size: size) {
            return font
        } else {
            print("Font \(customFont.rawValue) not found, using system font")
            return UIFont.systemFont(ofSize: size)
        }
    }
    
    // Check if font is available
    func isFontAvailable(_ customFont: CustomFont) -> Bool {
        return UIFont(name: customFont.rawValue, size: 17) != nil
    }
    
    // Register fonts (call this in AppDelegate)
    func registerFonts() {
        let fonts = availableFonts
        for font in fonts {
            if !isFontAvailable(font) {
                print("Warning: Font \(font.rawValue) is not available")
            } else {
                print("Font \(font.rawValue) is available")
            }
        }
    }
}

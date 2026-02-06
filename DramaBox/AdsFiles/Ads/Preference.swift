import UIKit

class Preference: NSObject {

    static let sharedInstance = Preference()
    
    let App_LANGUAGE_KEY                  = "AppLanguageKey"
    let FRIST_TIME                        = "FristTime"
    let SHOW_LANGUAGE                     = "SHOW_LANGUAGE"
    let SHOW_PARMISSION                   = "SHOW_PARMISSION"
    let SHOW_CONFIRM_PRIVACY_SCREEN       = "SHOW_CONFIRM_PRIVACY_SCREEN_KEY"
    let REPORT_COUNT                      = "REPORT_COUNT"
    let SHOW_DARKMODE                     = "SHOW_DARKMODE"
    let SHOW_RATE_US                      = "SHOW_RATE_US"
    let SHOW_GRID                         = "SHOW_GRID"
    let FILE_LIST                         = "FILE_LIST"
    let FOLDER_LIST                       = "FOLDER_LIST"
    let Step1                       = "Step1"
    let LANGUAGE                       = "LANGUAGE"
    let COUNTRYCODE                       = "COUNTRYCODE"
    let YOUTUBE_COUNT                     = "YOUTUBE_COUNT"
    let IMAGE_COUNT                       = "IMAGE_COUNT"
    let VIDEO_COUNT                       = "VIDEO_COUNT"
    let INTRO_ONE = "INTRO_ONE"
    let INTRO_TWO                         = "INTRO_TWO"
    let INTRO_THREE                         = "INTRO_THREE"
    let isLatPermission = "isLatPermission"
    let isGetStarted = "isGetStarted"
    let RATE_DONE                         = "RATE_DONE"
}

func setDataToPreference(data: AnyObject, forKey key: String) {
    UserDefaults.standard.set(data, forKey: key)
    UserDefaults.standard.synchronize()
}

func getDataFromPreference(key: String) -> AnyObject? {
    return UserDefaults.standard.object(forKey: key) as AnyObject?
}

func removeDataFromPreference(key: String) {
    UserDefaults.standard.removeObject(forKey: key)
    UserDefaults.standard.synchronize()
}
func setRateDone(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.RATE_DONE)
}
func isShowRateDone() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.RATE_DONE)
    return status
}

func removeUserDefaultValues() {
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    UserDefaults.standard.synchronize()
}

// Show Language Screen

func setLanguageCode(str:String){
    UserDefaults.standard.set(str, forKey: Preference.sharedInstance.App_LANGUAGE_KEY)
}

func getLanguageCode() -> String{
    let code = UserDefaults.standard.object(forKey: Preference.sharedInstance.App_LANGUAGE_KEY) as? String
    if code == nil {
        return "en"
    }else{
        return code!
    }
}

// Show Intro Screen

func setIsFristTime(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.FRIST_TIME)
}

func isShowFristTime() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.FRIST_TIME)
    return status
}

// Show Config Screen
func setIsShowConfirmPrivacyScreen(isShow: Bool) {
    setDataToPreference(data: isShow as AnyObject, forKey: Preference.sharedInstance.SHOW_CONFIRM_PRIVACY_SCREEN)
}

func isShowConfirmPrivacyScreen() -> Bool {
    let isAccepted = getDataFromPreference(key: Preference.sharedInstance.SHOW_CONFIRM_PRIVACY_SCREEN)
    return isAccepted == nil ? false : (isAccepted as! Bool)
}


// Show Intro Screen

func setIsDarkMode(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.SHOW_DARKMODE)
}

func isShowDarkMode() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.SHOW_DARKMODE)
    return status
}


// Show Rate Us Screen

func setIsGrid(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.SHOW_RATE_US)
}

func isShowGrid() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.SHOW_RATE_US)
    return status
}

// Show Grid Screen

func setIsRateUS(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.SHOW_GRID)
}

func isShowRateUs() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.SHOW_GRID)
    return status
}

// Set Ads ID

func setAdsModal(modal:AdsModal){
    UserDefaults().set(encodable: modal, forKey: "AdsModal")
}

func getAdsModal() -> AdsModal{
    if let modal = UserDefaults().get(AdsModal.self, forKey: "AdsModal"){
        return modal
    }
    return AdsModal()
}


func setGmpOpenId(_ id: String) {
        UserDefaults.standard.set(id, forKey: "gmpOpenId")
    }
    func getGmpOpenId() -> String? {
        return UserDefaults.standard.string(forKey: "gmpOpenId")
    }


//Language
func setLanguage(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.LANGUAGE)
}

func isLanguage() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.LANGUAGE)
    return status
}


func setStep1(status:Bool){
    UserDefaults.standard.set(status, forKey: Preference.sharedInstance.Step1)
}
func isStep1() -> Bool{
    let status = UserDefaults.standard.bool(forKey: Preference.sharedInstance.Step1)
    return status
}


// Set Youtube Count

func setYoutubeCount(count:Int){
    UserDefaults().set(encodable: count, forKey: Preference.sharedInstance.YOUTUBE_COUNT)
}

func getYoutubeCount() -> Int{
    if let count = UserDefaults().get(Int.self, forKey: Preference.sharedInstance.YOUTUBE_COUNT){
        return count
    }else{
        return 0
    }
    
}


// Set Image Cast

func setImageCastCount(count:Int){
    UserDefaults().set(encodable: count, forKey: Preference.sharedInstance.IMAGE_COUNT)
    UserDefaults().synchronize()
}

func getImageCastCount() -> Int{
    if let count = UserDefaults().get(Int.self, forKey: Preference.sharedInstance.IMAGE_COUNT){
        return count
    }else{
        return 0
    }
    
}


func setVideoCastCount(count:Int){
    UserDefaults().set(encodable: count, forKey: Preference.sharedInstance.VIDEO_COUNT)
    UserDefaults().synchronize()
}

func getVideoCastCount() -> Int{
    if let count = UserDefaults().get(Int.self, forKey: Preference.sharedInstance.VIDEO_COUNT){
        return count
    }else{
        return 0
    }
   
}

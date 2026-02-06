//
//  Utility.swift
//  Photo Video Maker
//
//  Created by jksol IMAC on 15/04/23.
//

import Foundation
import UIKit
import Photos
import QuickLook
import SDWebImage
import AVFoundation
import AVKit
//import SKPhotoBrowser
//import Toaster

// MARK: - Delay Features
func delay(_ delay: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: closure)
}

// MARK: - Open Url
func openUrlInSafari(strUrl: String) {
    if let url = URL(string: strUrl) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { (isOpen) in }
        } else {
            debugPrint("System can't open this URL!")
        }
    } else {
        debugPrint("URL invalid")
    }
}

// MARK: - Toast
func displayToast(_ message: String) {
//    Toast.init(text: message).show()
}


// MARK: - Debug
func debugPrint(_ str: Any) {
    #if DEBUG
        print(str)
    #endif
}


func displaySubViewWithScaleOutAnim(_ view: UIView) {
    view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
    view.alpha = 1
    UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.55, initialSpringVelocity: 1.0, options: [], animations: {() -> Void in
        view.transform = CGAffineTransform.identity
    }, completion: {(_ finished: Bool) -> Void in
    })
}

func displaySubViewWithScaleInAnim(_ view: UIView) {
    UIView.animate(withDuration: 0.25, animations: {() -> Void in
        view.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
        view.alpha = 0.0
    }, completion: {(_ finished: Bool) -> Void in
        view.removeFromSuperview()
    })
}

// MARK: - Date Time
func getCurrentTimeStampValue() -> String {
    return String(format: "%0.0f", Date().timeIntervalSince1970*1000)
}

func convertTimeStampToDate(timeStamp: Float) -> Date {
    let epocTime = TimeInterval(timeStamp)
    let date = NSDate(timeIntervalSince1970: epocTime)
    return date as Date
}

func getDateFromTimeStamp(timeStamp : Int) -> String {
    let date = NSDate(timeIntervalSince1970: TimeInterval(timeStamp))
    let dayTimePeriodFormatter = DateFormatter()
    dayTimePeriodFormatter.dateFormat = "hh:mm a"
    let dateString = dayTimePeriodFormatter.string(from: date as Date)
    return dateString
}

func getDateFromTimeStamp1(timeStamp : Int) -> String {
    let date = NSDate(timeIntervalSince1970: TimeInterval(timeStamp))
    let dayTimePeriodFormatter = DateFormatter()
    dayTimePeriodFormatter.dateFormat = "dd,MMM yy hh:mm a"
    let dateString = dayTimePeriodFormatter.string(from: date as Date)
    return dateString
}

func getDateFromTimeStamp2(timeStamp : Int) -> String {
    let date = NSDate(timeIntervalSince1970: TimeInterval(timeStamp))
    let dayTimePeriodFormatter = DateFormatter()
    dayTimePeriodFormatter.dateFormat = "dd,MMM yy"
    let dateString = dayTimePeriodFormatter.string(from: date as Date)
    return dateString
}

// MARK: - Share
func shareText(_ vc: UIViewController, _ text: Any) {
    let textToShare = [ text ]
    let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = vc.view
    activityViewController.popoverPresentationController?.sourceRect = CGRect.init(x: vc.view.frame.midX / 2, y: vc.view.frame.midY, width: 0, height: 0)
    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
    vc.present(activityViewController, animated: true, completion: nil)
}

// MARK: - Alert
func showAlert(_ title:String, message:String, completion: @escaping () -> Void) {
    let myAlert = UIAlertController(title:NSLocalizedString(title, comment: ""), message:NSLocalizedString(message, comment: ""), preferredStyle: UIAlertController.Style.alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler:{ (action) in
        completion()
    })
    myAlert.addAction(okAction)
    appDelegate.window?.rootViewController?.present(myAlert, animated: true, completion: nil)
}

// MARK: - Get thumb image for any files

@available(iOS 13.0, *)
func getThumbImageForFile(fileUrl: URL ,_ complition: @escaping (UIImage) -> Void) {
    let request = QLThumbnailGenerator.Request(
        fileAt: fileUrl,
        size: CGSize.init(width: 100, height: 100),
        scale: UIScreen.main.scale,
        representationTypes: .all)

    let generator = QLThumbnailGenerator.shared
    generator.generateRepresentations(for: request) { thumbnail, _, error in
        if let thumbnail = thumbnail {
            DispatchQueue.main.async {
                complition(thumbnail.uiImage)
            }
        } else if let error = error {
            debugPrint(error.localizedDescription)
        }
    }
}

// MARK: Get Image Form URL
func clearSDImageCache() {
    SDImageCache.shared.clearMemory()
    SDImageCache.shared.clearDisk()
}

func setImageFromUrl(_ picPath: String, img: UIImageView, placeHolder: String) {
    if picPath == "" {
        img.image = UIImage.init(named: placeHolder)
        return
    }
    
    img.sd_imageIndicator = SDWebImageActivityIndicator.white
    img.sd_setImage(with: URL(string : picPath), placeholderImage: nil, options: []) { image, error, type, url in
        if error == nil {
            img.image = image
        } else {
            img.image = UIImage.init(named: placeHolder)
        }
    }
}

func fetchThumbnail(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    // Create URL from the provided string
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }
    
    // Create URLSession
    let session = URLSession.shared
    
    // Create URLSessionDataTask for downloading image data
    let task = session.dataTask(with: url) { (data, response, error) in
        // Check for errors
        if let error = error {
            print("Error downloading image: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        // Ensure data is not nil
        guard let imageData = data else {
            print("No data received")
            completion(nil)
            return
        }
        
        // Create UIImage from the downloaded data
        if let image = UIImage(data: imageData) {
            // Create a thumbnail from the image
            let thumbnail = image.scalePreservingAspectRatio(targetSize: CGSize(width: 100, height: 100))
            completion(thumbnail)
        } else {
            completion(nil)
        }
    }
    
    // Start the data task
    task.resume()
}

extension UIImage {
    // Function to scale image to target size while preserving aspect ratio
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledWidth = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledWidth, height: scaledHeight))
        let scaledImage = renderer.image { (context) in
            draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        }
        
        return scaledImage
    }
}

// MARK: - App Detail
func getAppVersion() -> String {
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return appVersion
    } else {
        return "0.0"
    }
}

// Convert To Valid URL
func convertStringToValidUrl(strUrl: String) -> String? {
    return strUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
}

// Convart Data to Dictionary
func convertDataToDict(data: Data) -> [String: Any]? {
    do {
        let dictJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        return dictJson
    } catch {
        return nil
    }
}

// MARK: - Get image from PHAssets data type
func getUIImage(asset: PHAsset, size: CGSize) -> UIImage? {
    let imageManager = PHCachingImageManager()
    let option = PHImageRequestOptions()
    var img: UIImage?
    
    option.deliveryMode = .opportunistic
    option.resizeMode = .exact
    option.isSynchronous = true
    option.isNetworkAccessAllowed = true

    imageManager.requestImage(for: asset, targetSize: size, contentMode: .default, options: option, resultHandler: { image, _ in
        if image != nil {
            img = image!
        }
    })
    
    return img
}


func getImageFromPHAssets(image: PHAsset, _ complition: @escaping (URL) -> Void) {
    image.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { eidtingInput, info in
        if let input = eidtingInput, let photoUrl = input.fullSizeImageURL {
            complition(photoUrl)
        }
    }
}

func getVideoFromPHAssets(video: PHAsset, _ complition: @escaping (URL) -> Void) {
    let options = PHVideoRequestOptions()
    options.version = .original
    
    PHCachingImageManager.default().requestAVAsset(forVideo: video, options: options) { (video, _, _) in
        if let video = video, let url = (video as? AVURLAsset)?.url {
            DispatchQueue.main.async {
                complition(url)
            }
        }
    }
}

/// Play audio/video
func playAudioVideo(_ vc: UIViewController, _ url: URL) {
    let player = AVPlayer(url: url)
    let playerViewController = AVPlayerViewController()
    playerViewController.player = player
    playerViewController.showsPlaybackControls = true
    playerViewController.allowsPictureInPicturePlayback = true
    playerViewController.player?.rate = 1
    vc.present(playerViewController, animated: true) {
        player.play()
    }
}

// MARK: - Opoen UIImage Preview
//func openUIImagePreview(_ vc: UIViewController, img: UIImage) {
//    var images = [SKPhoto]()
//    images.append(SKPhoto.photoWithImage(img))
//
//    let browser = SKPhotoBrowser(photos: images)
//    browser.initializePageIndex(0)
//    vc.present(browser, animated: true, completion: nil)
//}


/*func createFolderInDocumentDirectory(folderName: String) {
    let fileManager = FileManager.default
    guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        // Failed to retrieve the document directory
        return
    }
    
    let folderURL = documentDirectory.appendingPathComponent(folderName)
    
    if fileManager.fileExists(atPath: folderURL.path) {
        // Folder already exists, no need to create it
        print("Folder already exists at path: \(folderURL.path)")
        return
    }
    
    do {
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        print("Folder created successfully at path: \(folderURL.path)")
    } catch {
        print("Error creating folder: \(error.localizedDescription)")
    }
}*/

/// Get Default Files Placeholder Image Name
func getFileIcon(extention: String) -> String {
    if extention == "" {
        return "imgFlieThumb_folder"
    } else if extention == "zip" {
        return "imgFlieThumb_zip"
    } else if extention == "pdf" {
        return "imgFlieThumb_pdf"
    } else if extention == "doc" || extention == "docx" {
        return "imgFlieThumb_doc"
    } else if extention == "ppt" || extention == "pptx" {
        return "imgFlieThumb_ppt"
    } else if extention == "xls" || extention == "xlsx" {
        return "imgFlieThumb_xls"
    } else if extention == "txt" || extention == "csv" || extention == "rtf" || extention == "odt" {
        return "imgFlieThumb_txt"
    } else if extention == "jpg" || extention == "png" || extention == "svg" || extention == "bmp" || extention == "gif" || extention == "JPG" || extention == "PNG" || extention == "SVG" || extention == "BMP" || extention == "GIF" || extention == "HEIC" {
        return "imgFlieThumb_jpg="
    } else if extention == "mp4" || extention == "3gp" || extention == "3gpp" || extention == "mpeg" || extention == "mpegpng" || extention == "mkv" || extention == "mkvpng" || extention == "mov" || extention == "movpng" || extention == "MOV" || extention == "MP4" || extention == "3GP" || extention == "3GPP" || extention == "MPEG" || extention == "MPEGPNG" || extention == "MKV" || extention == "MKVPNG" ||  extention == "MOVPNG" {
        return "imgFlieThumb_mp4"
    } else if extention == "aac" || extention == "flac" || extention == "m4a" || extention == "mp3" || extention == "oga" || extention == "wav" || extention == "wma" || extention == "ogg" ||  extention == "aac" || extention == "flac" || extention == "m4a" || extention == "mp3" || extention == "oga" || extention == "wav" || extention == "wma" || extention == "ogg" || extention == "caf" {
        return "imgFlieThumb_mp3"
    } else {
        return "imgFlieThumb_notFound"
    }
    
}


func convertMediaAudioToCafFormat(saveDir: URL, fileURL: URL, fileName: String, _ complition: @escaping (URL) -> Void) {
    let exportSession = AVAssetExportSession(asset: AVAsset(url: fileURL), presetName: AVAssetExportPresetPassthrough)
    exportSession?.shouldOptimizeForNetworkUse = true
    exportSession?.outputFileType = AVFileType.caf
    
    var tempFileUrl = saveDir.appendingPathComponent("\(fileName).caf", isDirectory: false)
    tempFileUrl = URL(fileURLWithPath: tempFileUrl.path)
    exportSession?.outputURL = tempFileUrl // File with a .caf extention.
    
    exportSession?.exportAsynchronously(completionHandler: {
        if exportSession!.status == AVAssetExportSession.Status.completed {
            debugPrint("write file succssefully")
            complition(tempFileUrl)
        } else if exportSession?.status == AVAssetExportSession.Status.failed { // fail because files override
            debugPrint("overwrite file succssefully")
            complition(tempFileUrl)
        }
    })
}

func getfileCreatedDate(theFile: String) -> Date {
    var theCreationDate = Date()
    do {
        let aFileAttributes = try FileManager.default.attributesOfItem(atPath: theFile) as [FileAttributeKey:Any]
        theCreationDate = aFileAttributes[FileAttributeKey.creationDate] as! Date
    } catch let error {
        debugPrint("file not found \(error.localizedDescription)")
    }
    return theCreationDate
}


/// Generate QE Code Image
func generateQRCode(from string: String) -> UIImage? {
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 5, y: 5)

        if let output = filter.outputImage?.transformed(by: transform) {
            return UIImage(ciImage: output)
        }
    }

    return nil
}

func convertToBytes(sizeString: String) -> Double {
    let sizeComponents = sizeString.components(separatedBy: " ")
    let sizeValue = Double(sizeComponents[0]) ?? 0.0
    let sizeUnit = sizeComponents[1]

    switch sizeUnit {
    case "KB":
        return sizeValue * 1024
    case "MB":
        return sizeValue * 1024 * 1024
    default:
        return 0.0
    }
}

func totalSizeInGB(fileSizes: [String]) -> Double {
    let totalSizeInBytes = fileSizes.reduce(0.0) { $0 + convertToBytes(sizeString: $1) }
    let totalSizeInGB = totalSizeInBytes / (1024 * 1024 * 1024)
    return totalSizeInGB
}

func addHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}


//MARK: - USERDEFAULT METHOD
func removeFromUserDefaults(strKey:String) {
    UserDefaults.standard.removeObject(forKey: strKey)
    UserDefaults.standard.synchronize()
}

func SetValueInUserDefaults(strKey:String,value:Int) {
    UserDefaults.standard.setValue(value, forKey: strKey)
    UserDefaults.standard.synchronize()
}

func getValueFromUserDefaults(strKey:String) -> Int {
    if ((UserDefaults.standard.value(forKey: strKey)) != nil)
    {
        return UserDefaults.standard.value(forKey: strKey) as! Int
    }
    else
    {
        return 0
    }
}

func downloadFavicon(from url: URL, iconImageView: UIImageView) {
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data, let faviconImage = UIImage(data: data) else {
            print("Error downloading favicon: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        DispatchQueue.main.async {
            iconImageView.image = faviconImage
        }
    }
    task.resume()
}

/*
class URLProcessor {
    
    private let SHORTCODE_PATTERN = "(?:/p/|/reel/|/reels/|/tv/)([\\w-]+)"
    private let POST_PATTERN = "/p/"
    private let REEL_PATTERN = "/reel/"
    private let REELS_PATTERN = "/reels/"
    
    func getPostShortCode(postCopiedUrl: String) -> Pair<String?, String> {
        var groupValues: [String]?
        var str = postCopiedUrl
        var str2: String? = nil
        var str3 = ""
        
        if !str.contains("www") {
            return Pair(first: postCopiedUrl, second: "")
        }
        
        let regex = try? NSRegularExpression(pattern: SHORTCODE_PATTERN, options: [])
        let nsString = str as NSString
        let results = regex?.firstMatch(in: str, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if str.contains(POST_PATTERN) {
            str3 = "p"
        } else if str.contains(REEL_PATTERN) || str.contains(REELS_PATTERN) {
            str3 = "reel"
        }
        
        if let results = results {
            let range = results.range(at: 1)
            if range.location != NSNotFound {
                str2 = nsString.substring(with: range)
            }
        }
        
        return Pair(first: str2, second: str3)
    }
}*/

func textSize(font: UIFont, text: String, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
    let label = UILabel(frame: CGRect(x: 12, y: 0, width: width - 12, height: height))
    label.numberOfLines = 0
    label.font = font
    label.text = text
    label.sizeToFit()
    return label.frame.size.width
}

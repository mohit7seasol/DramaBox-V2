//
//  ViewWallPaperVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 17/01/26.
//

import UIKit
import SDWebImage
import Photos
import GoogleMobileAds

class ViewWallPaperVC: UIViewController {
    
    @IBOutlet weak var wallpaperImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var bannerAddView: UIView!
    @IBOutlet weak var addHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var downloadButtonLbl: UILabel!
    @IBOutlet weak var downloadButtonGradientView: GradientDesignableView!
    
    var wallPaperStr: String?
    private var isZoomed = false
    private var originalFrame: CGRect?
    private var isDownloading = false
    
    private let googleBannerAds = GoogleBannerAds()
    private var bannerView: BannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        loadWallpaper()
        subscribeBannerAd()
    }
    
    func setUI() {
        titleLbl.text = "Wallpaper".localized(LocalizationService.shared.language)
        downloadButtonLbl.text = "Download".localized(LocalizationService.shared.language)
        
        // Enable user interaction for zooming
        wallpaperImageView.isUserInteractionEnabled = true
        wallpaperImageView.contentMode = .scaleAspectFit
        wallpaperImageView.clipsToBounds = true
        downloadButton.layer.cornerRadius = downloadButton.frame.height / 2
        downloadButtonGradientView.cornerRadius = downloadButtonGradientView.frame.height / 2
    }
    func subscribeBannerAd() {

        if Subscribe.get() {
            addHeightConstant.constant = 0
            bannerAddView.isHidden = true
            return
        }

        // Create BannerView ONLY ONCE
        if bannerView == nil {
            let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(
                width: UIScreen.main.bounds.width
            ))

            banner.translatesAutoresizingMaskIntoConstraints = false
            bannerAddView.addSubview(banner)

            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: bannerAddView.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: bannerAddView.trailingAnchor),
                banner.topAnchor.constraint(equalTo: bannerAddView.topAnchor),
                banner.bottomAnchor.constraint(equalTo: bannerAddView.bottomAnchor)
            ])

            bannerView = banner
        }

        bannerAddView.isHidden = false
        addHeightConstant.constant = 50   // Standard banner height

        // ✅ THIS IS THE KEY FIX
        googleBannerAds.loadAds(vc: self, view: bannerView!)
    }
    private func loadWallpaper() {
        guard let wallpaperURL = wallPaperStr, let url = URL(string: wallpaperURL) else {
            wallpaperImageView.image = UIImage(named: "wallpaper_place_img")
            return
        }
        
        // Show loading indicator
        wallpaperImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        
        // Load image using SDWebImage
        wallpaperImageView.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "wallpaper_place_img"),
            options: [.highPriority, .scaleDownLargeImages],
            completed: { [weak self] (image, error, cacheType, imageURL) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    self.wallpaperImageView.image = UIImage(named: "wallpaper_place_img")
                } else {
                    print("Image loaded successfully")
                    self.originalFrame = self.wallpaperImageView.frame
                }
            }
        )
    }
    
    @IBAction func backButtonTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func downloadButton(_ sender: UIButton) {
        guard !isDownloading else { return }
        requestPhotoLibraryPermission()
    }
    
    private func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            // Permission already granted or limited access (iOS 14+)
            downloadWallpaperToGallery()
            
        case .denied, .restricted:
            // Permission denied or restricted
            showPermissionDeniedAlert()
            
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] (newStatus) in
                DispatchQueue.main.async {
                    switch newStatus {
                    case .authorized, .limited:
                        self?.downloadWallpaperToGallery()
                    default:
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    private func downloadWallpaperToGallery() {
        guard let image = wallpaperImageView.image, image != UIImage(named: "wallpaper_place_img") else {
            showAlert(
                title: "Error".localized(LocalizationService.shared.language),
                message: "No image available to download.".localized(LocalizationService.shared.language)
            )
            return
        }
        
        // Prevent multiple simultaneous downloads
        guard !isDownloading else { return }
        isDownloading = true
        
        // Update UI for downloading state
        downloadButton.isEnabled = false
        downloadButton.setTitle("Downloading...".localized(LocalizationService.shared.language), for: .normal)
        
        // Save image to photo library
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // Reset downloading state
        isDownloading = false
        downloadButton.isEnabled = true
        downloadButton.setTitle("Download".localized(LocalizationService.shared.language), for: .normal)
        
        if let error = error {
            // Error saving image
            showAlert(
                title: "Error".localized(LocalizationService.shared.language),
                message: error.localizedDescription
            )
        } else {
            // Successfully saved
            showAlert(
                title: "Success".localized(LocalizationService.shared.language),
                message: "Wallpaper saved to your photo gallery.".localized(LocalizationService.shared.language)
            )
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permission Required".localized(LocalizationService.shared.language),
            message: "Please allow photo library access in Settings to save wallpapers.".localized(LocalizationService.shared.language),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Cancel".localized(LocalizationService.shared.language),
            style: .cancel,
            handler: nil
        ))
        
        alert.addAction(UIAlertAction(
            title: "Settings".localized(LocalizationService.shared.language),
            style: .default,
            handler: { _ in
                self.openAppSettings()
            }
        ))
        
        present(alert, animated: true)
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: "OK".localized(LocalizationService.shared.language),
            style: .default
        ) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // Handle device rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Reset zoom on rotation
            if self.isZoomed {
                self.isZoomed = false
                if let originalFrame = self.originalFrame {
                    self.wallpaperImageView.frame = originalFrame
                }
            }
            // Update original frame
            self.originalFrame = self.wallpaperImageView.frame
        })
    }
}

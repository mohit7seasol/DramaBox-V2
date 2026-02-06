//
//  RingtoneListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 20/01/26.
//

import UIKit
import AVFAudio
import MediaPlayer

class RingtoneListVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedCategory: RingtoneCategory?
    var currentlyPlayingIndex: IndexPath?
    var ringtones: [Ringtone] = []
    
    // ✅ ADD NATIVE AD PROPERTIES
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    var nativeAdContainerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        loadRingtones()
        subscribeNativeAd() // ✅ SUBSCRIBE TO NATIVE ADS
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllPlayback()
    }
    
    func setUI() {
        titleLabel.text = selectedCategory?.category ?? "Ringtones"
        setCollection()
    }
    
    func loadRingtones() {
        ringtones = selectedCategory?.ringtones ?? []
        collectionView.reloadData()
    }
    
    // ✅ ADD NATIVE AD SUBSCRIPTION METHOD
    func subscribeNativeAd() {
        // Check subscription status
        guard Subscribe.get() == false else {
            self.isShowNativeAds = false
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            return
        }
        
        // User is not subscribed, show skeleton and load ad
        self.nativeAdContainerView.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 200
        )
        self.nativeAdContainerView.backgroundColor = UIColor.appAddBg
        self.isShowNativeAds = true
        
        HelperManager.showSkeleton(nativeAdView: self.nativeAdContainerView)
        
        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self = self else { return }
            
            print("✅ RingtoneListVC Native Ad Loaded")
            HelperManager.hideSkeleton(nativeAdView: self.nativeAdContainerView)
            
            // Configure the native ad container view
            self.nativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 200
            )
            
            // Remove old ad views
            self.nativeAdContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            self.googleNativeAds.showAdsView8(
                nativeAd: nativeAdsTemp,
                view: self.nativeAdContainerView
            )
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        googleNativeAds.failAds(self) { [weak self] fail in
            guard let self = self else { return }
            
            print("❌ RingtoneListVC Native Ad Failed to Load")
            HelperManager.hideSkeleton(nativeAdView: self.nativeAdContainerView)
            self.isShowNativeAds = false
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func setCollection() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        
        // ✅ REGISTER NATIVE AD CELL
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NativeAdCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        collectionView.collectionViewLayout = layout
        
        let nib = UINib(nibName: "RingtoneListCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "RingtoneListCell")
    }
    
    private func stopAllPlayback() {
        for cell in collectionView.visibleCells {
            if let ringtoneCell = cell as? RingtoneListCell {
                ringtoneCell.stopPlayback()
                ringtoneCell.setUnselectedStyle()
            }
        }
        currentlyPlayingIndex = nil
    }
    
    private func showActionSheet(for ringtone: Ringtone, sourceView: UIView) {

        let alert = UIAlertController(
            title: ringtone.ringtoneName,
            message: nil,
            preferredStyle: .actionSheet
        )

        let downloadAction = UIAlertAction(title: "Download".localized(LocalizationService.shared.language), style: .default) { [weak self] _ in
            self?.downloadRingtone(ringtone)
        }

        let shareAction = UIAlertAction(title: "Share".localized(LocalizationService.shared.language), style: .default) { [weak self] _ in
            self?.shareRingtone(ringtone)
        }

        let cancelAction = UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .cancel)

        alert.addAction(downloadAction)
        alert.addAction(shareAction)
        alert.addAction(cancelAction)

        // ✅ REQUIRED FOR iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = [.up, .down]
        }

        present(alert, animated: true)
    }

    
    private func downloadRingtone(_ ringtone: Ringtone) {
        checkMusicLibraryPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.startRingtoneDownload(ringtone)
            } else {
                DispatchQueue.main.async {
                    self.showMusicPermissionAlert()
                }
            }
        }
    }
    
    private func checkMusicLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = MPMediaLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func startRingtoneDownload(_ ringtone: Ringtone) {
        guard let url = URL(string: ringtone.ringtoneUrl) else { return }

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.showToast(message: "Failed to download ringtone.", isSuccess: false)
                }
                return
            }

            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // Simple filename
            let safeName = ringtone.ringtoneName
                .replacingOccurrences(of: " ", with: "_")
                .filter { !"/\\?%*|\"<>:".contains($0) }
            
            let destinationURL = documentsURL.appendingPathComponent("\(safeName).m4r")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }

                try fileManager.moveItem(at: tempURL, to: destinationURL)
                
                print("📁 File path: \(destinationURL.path)")
                
                DispatchQueue.main.async {
                    self.showToast(message: "Downloaded! Tap 'Share' to save to Files.", isSuccess: true)
                    
                    // Automatically show share options
                    self.shareRingtoneFile(fileURL: destinationURL, ringtone: ringtone)
                }

            } catch {
                print("❌ Error: \(error)")
                DispatchQueue.main.async {
                    self.showToast(message: "Error: \(error.localizedDescription)", isSuccess: false)
                }
            }
        }.resume()
    }

    private func shareRingtoneFile(fileURL: URL, ringtone: Ringtone) {
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            // Configure for iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // Completion handler
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                if completed {
                    if activityType == .saveToCameraRoll {
                        self.showToast(message: "Saved to Photos! 🎵", isSuccess: true)
                    } else if activityType?.rawValue == "com.apple.DocumentManagerUICore.SaveToFiles" {
                        self.showToast(message: "Saved to Files app! 📁", isSuccess: true)
                    }
                }
            }
            
            self.present(activityVC, animated: true)
        }
    }
    
    private func showDownloadSuccessAlert(fileURL: URL, ringtoneName: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Download Complete",
                message: "\(ringtoneName) has been saved to:\nFiles App → On My iPhone → \(Bundle.main.displayName ?? "App") → Documents → Ringtones",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Optional: Add button to open Files app
            alert.addAction(UIAlertAction(title: "Open in Files", style: .default) { _ in
                self.openInFilesApp(fileURL: fileURL)
            })
            
            self.present(alert, animated: true)
        }
    }

    private func openInFilesApp(fileURL: URL) {
        DispatchQueue.main.async {
            let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
            documentPicker.delegate = self
            self.present(documentPicker, animated: true)
        }
    }
    
    private func showMusicPermissionAlert() {
        let alert = UIAlertController(
            title: "Access Required",
            message: "Please allow Music Library access to save ringtones to your device.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        self.present(alert, animated: true)
    }
    
    private func showToast(message: String, isSuccess: Bool) {
        DispatchQueue.main.async {
            // Create a simple toast view
            let toastView = UIView()
            toastView.backgroundColor = isSuccess ? UIColor.systemGreen : UIColor.systemRed
            toastView.alpha = 0
            toastView.layer.cornerRadius = 10
            toastView.clipsToBounds = true
            
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14)
            
            toastView.addSubview(label)
            self.view.addSubview(toastView)
            
            // Auto layout
            toastView.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                toastView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                toastView.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor, multiplier: 0.8),
                
                label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 10),
                label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -10),
                label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 15),
                label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -15)
            ])
            
            // Animate in
            UIView.animate(withDuration: 0.3) {
                toastView.alpha = 1
            }
            
            // Animate out after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.3, animations: {
                    toastView.alpha = 0
                }) { _ in
                    toastView.removeFromSuperview()
                }
            }
        }
    }
    
    private func shareRingtone(_ ringtone: Ringtone) {
        guard let url = URL(string: ringtone.ringtoneUrl) else { return }
        
        let items: [Any] = [ringtone.ringtoneName, url]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        stopAllPlayback()
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension RingtoneListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // ✅ UPDATE TO 2 SECTIONS
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Section 0: Native Ad, Section 1: Ringtone Items
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            // Native Ad Section - show only if ads are enabled
            return isShowNativeAds ? 1 : 0
        } else {
            // Ringtone Items Section
            return ringtones.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            // ✅ NATIVE AD CELL
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NativeAdCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            
            // Remove old ad views before adding new
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Configure the native ad container view
            nativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: collectionView.frame.width,
                height: 200
            )
            
            // Ensure nativeAdContainerView is properly configured
            nativeAdContainerView.backgroundColor = UIColor.appAddBg
            nativeAdContainerView.isHidden = !isShowNativeAds
            
            cell.contentView.addSubview(nativeAdContainerView)
            
            return cell
        } else {
            // ✅ RINGTONE ITEM CELLS
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RingtoneListCell", for: indexPath) as! RingtoneListCell
            
            let ringtone = ringtones[indexPath.item]
            let isPlaying = currentlyPlayingIndex == indexPath
            
            // Configure cell
            cell.configure(with: ringtone, isPlaying: isPlaying)
            
            // Set selection style based on playing state
            if isPlaying && cell.isPlaying { // Only set selected style if actually playing
                cell.setSelectedStyle()
            } else {
                cell.setUnselectedStyle()
            }
            
            // Set up button actions
            cell.playButton.setOnClickListener { [weak self, weak cell] in
                guard let self = self, let cell = cell else { return }
                self.handlePlayButtonTap(at: indexPath, cell: cell)
            }
            
            cell.menuButton.setOnClickListener { [weak self, weak cell] in
                guard let self = self, let cell = cell else { return }
                self.showActionSheet(for: ringtone, sourceView: cell.menuButton)
            }
            
            // Set up callbacks
            cell.onPlaybackFinished = { [weak self] in
                DispatchQueue.main.async {
                    self?.currentlyPlayingIndex = nil
                    // Reload the specific cell to update its UI
                    self?.collectionView.reloadItems(at: [indexPath])
                }
            }
            
            cell.onPlaybackPaused = { [weak self] in
                DispatchQueue.main.async {
                    self?.currentlyPlayingIndex = nil
                    // Update the cell UI immediately without reloading
                    cell.setUnselectedStyle()
                }
            }
            
            return cell
        }
    }
    
    private func handlePlayButtonTap(at indexPath: IndexPath, cell: RingtoneListCell) {
        // ✅ DON'T ALLOW PLAYBACK FOR NATIVE AD CELL
        guard indexPath.section != 0 else { return }
        
        // If tapping a different cell than the currently playing one
        if let currentIndex = currentlyPlayingIndex, currentIndex != indexPath {
            // Stop the currently playing cell
            if let currentCell = collectionView.cellForItem(at: currentIndex) as? RingtoneListCell {
                currentCell.stopPlayback()
            }
            currentlyPlayingIndex = indexPath
            cell.play()
        }
        // If tapping the same cell
        else if currentlyPlayingIndex == indexPath {
            // Toggle play/pause
            if cell.isPlaying {
                cell.pause()
                currentlyPlayingIndex = nil // Clear when paused
            } else {
                cell.play()
                currentlyPlayingIndex = indexPath
            }
        }
        // If no cell is currently playing
        else {
            currentlyPlayingIndex = indexPath
            cell.play()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        
        if indexPath.section == 0 {
            // ✅ NATIVE AD CELL SIZE
            return CGSize(width: width, height: isShowNativeAds ? 200 : 0)
        } else {
            // ✅ RINGTONE ITEM CELL SIZE
            let itemHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 150 : 80
            return CGSize(width: width, height: itemHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // ✅ DON'T ALLOW SELECTION OF NATIVE AD CELL
        guard indexPath.section != 0 else { return }
        
        // Handle ringtone cell selection
        // ... (rest of your selection logic)
    }
    
    // ✅ ADD SPACING BETWEEN SECTIONS
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            // Native Ad Section - no insets
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            // Ringtone Items Section - add some spacing after native ad
            return UIEdgeInsets(top: isShowNativeAds ? 10 : 0, left: 0, bottom: 0, right: 0)
        }
    }
}

// 🔥 Optional: Add UIDocumentPickerDelegate extension
extension RingtoneListVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // File was picked/opened in Files app
        print("Document picked: \(urls)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled
        print("Document picker cancelled")
    }
}

// 🔥 Optional: Add this extension to get app name for the toast message
extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
               object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

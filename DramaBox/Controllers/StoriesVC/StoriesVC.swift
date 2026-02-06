//
//  StoriesVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import SVProgressHUD
import Lottie
import SDWebImage
import MarqueeLabel
import GoogleMobileAds

enum StoriesPlayingViewTypes {
    case isOpenStories
    case isOpenAllStoriesEpisods
}

class StoriesVC: UIViewController {
    
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    var storiesPlayingViewType: StoriesPlayingViewTypes = .isOpenStories
    var allDramaStories: [DramaItem] = []
    
    // Add episodes dictionary to store episodes for each drama
    var episodesForDramas: [String: [EpisodeItem]] = [:]
    private var nativeAdHelper: NativeAdHelper?
    var isFirstTimeOpenStories: Bool {
        get { UserDefaults.standard.bool(forKey: "isFirstTimeOpenStories") == false }
        set { UserDefaults.standard.set(!newValue, forKey: "isFirstTimeOpenStories") }
    }

    // Properties for pagination
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var currentPlayingIndex: Int = -1
    private var initialLoadComplete = false
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        // Show loading & fetch data
        showInitialLoading()
        fetchAllStories(page: 1)
        subscribeNativeAd()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: NSNotification.Name.subscriptionStatusChanged,
            object: nil
        )
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
        nativeAdHelper?.cleanup()
    }
    private func showInitialLoading() {
        SVProgressHUD.show()
    }
    
    private func hideInitialLoading() {
        SVProgressHUD.dismiss()
    }
    
    func setUpUI() {
        setCollection()
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        
        welcomeLabel.text = "Welcome to".localized(LocalizationService.shared.language)
        self.appNameLabel.text = "Sora Pixo".localized(LocalizationService.shared.language)
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        
        // Configure noDataView
        noDataView.isHidden = true
    }
    func subscribeNativeAd() {
        nativeHeighConstant.constant = Subscribe.get() ? 0 : 200
        addNativeView.isHidden = Subscribe.get()

        guard Subscribe.get() == false else {
            HelperManager.hideSkeleton(nativeAdView: addNativeView)
            return
        }

        addNativeView.backgroundColor = UIColor.appAddBg
        HelperManager.showSkeleton(nativeAdView: addNativeView)

        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 200
                self.addNativeView.isHidden = false
                self.addNativeView.subviews.forEach { $0.removeFromSuperview() }
                self.googleNativeAds.showAdsView8(
                    nativeAd: nativeAdsTemp,
                    view: self.addNativeView
                )
                self.view.layoutIfNeeded()
            }
        }

        googleNativeAds.failAds(self) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 0
                self.addNativeView.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
    }
    func setCollection() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cell
        collectionView.register(UINib(nibName: "ShortsListCell", bundle: nil), forCellWithReuseIdentifier: "ShortsListCell")
        
        // Set up collection view layout
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        
        collectionView.collectionViewLayout = layout
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
    }
    
    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }
        
        // Load next page
        fetchAllStories(page: currentPage + 1, isLoadMore: true)
    }
    
    // MARK: - Share Method
    private func shareDrama(_ drama: DramaItem) {
        guard let dramaName = drama.dramaName else { return }

        let shareText = "Check out \(dramaName) on our app!"
        var shareItems: [Any] = [shareText]

        // ✅ If image URL exists, load asynchronously
        if let imageUrlString = drama.imageUrl,
           let imageUrl = URL(string: imageUrlString) {

            URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                
                if let data = data,
                   let image = UIImage(data: data) {
                    shareItems.append(image)
                }

                // ✅ Present on MAIN thread
                DispatchQueue.main.async {
                    self?.presentShareSheet(items: shareItems)
                }

            }.resume()

        } else {
            // ✅ No image → just share text
            presentShareSheet(items: shareItems)
        }
    }
    
    private func presentShareSheet(items: [Any]) {
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        present(activityViewController, animated: true)
    }
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        collectionView.reloadData()
    }
} //hoteDefault

extension StoriesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = allDramaStories.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortsListCell", for: indexPath) as! ShortsListCell
        
        guard indexPath.item < allDramaStories.count else {
            return cell
        }
        
        let drama = allDramaStories[indexPath.item]
        
        // Configure cell with data
        // Set image using SDWebImage
        if let imageUrlString = drama.imageUrl,
           let imageUrl = URL(string: imageUrlString) {
            cell.thumbImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "hoteDefault"),
                options: [.progressiveLoad, .refreshCached]
            )
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        
        // Set drama name with marquee effect
        cell.nameLabel.text = drama.displayName
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set episode count
        if let totalEpisodes = drama.totalEpisodes, let episodeCount = Int(totalEpisodes) {
            cell.totalEpisodesCountLabel.text = "\(episodeCount) \(episodeCount == 1 ? "Episode" : "Episodes")"
        } else {
            cell.totalEpisodesCountLabel.text = "0 Episodes"
        }
        
        cell.setOnClickListener { [weak self] in
            guard let self = self else { return }
            
            // Get the drama item
            let selectedDrama = self.allDramaStories[indexPath.item]
            print("Selected drama: \(selectedDrama.displayName)")
            
            self.showInterAdClick()
            // Navigate to ShortsDetailVC
            self.navigateToShortsDetailVC(with: selectedDrama)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Load more data when reaching the last few items
        if indexPath.item >= allDramaStories.count - 3 && !isLoading && hasMoreData {
            loadMoreData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 10
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let itemsPerRow: CGFloat = isPad ? 4 : 2
        
        let totalSpacing = (2 * spacing) + ((itemsPerRow - 1) * spacing) // Left + Right + between items
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        
        let itemHeight: CGFloat = isPad ? 260 : 204
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    private func navigateToShortsDetailVC(with drama: DramaItem) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let shortsDetailVC = storyboard.instantiateViewController(
            withIdentifier: "ShortsDetailVC"
        ) as? ShortsDetailVC {
            
            // Pass the selected drama
            shortsDetailVC.dramaItem = drama
            
            // Pass episodesForDramas dictionary
            shortsDetailVC.episodesForDramas = episodesForDramas
            shortsDetailVC.hidesBottomBarWhenPushed = true
            
            // Push to navigation controller
            navigationController?.pushViewController(shortsDetailVC, animated: true)
        }
    }
}

// MARK: - Api's calling
extension StoriesVC {
    func fetchAllStories(page: Int, isLoadMore: Bool = false) {
        guard !isLoading, (isLoadMore ? hasMoreData : true) else { return }
        
        isLoading = true
        if !isLoadMore {
            SVProgressHUD.show()
        }
        
        NetworkManager.shared.fetchDramas(from: self, page: page) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            if !isLoadMore {
                SVProgressHUD.dismiss()
            }
            
            switch result {
            case .success(let response):
                // Only process "Popular Dramas" section
                var newDramas: [DramaItem] = []
                
                print("=== API Response Debug ===")
                print("Total sections: \(response.data.data.count)")
                print("Requested page: \(page)")
                
                // Find the "Popular Dramas" section
                if let popularDramasSection = response.data.data.first(where: { $0.heading == "Popular Dramas" }) {
                    print("Found Popular Dramas section")
                    print("Items in section: \(popularDramasSection.list.count)")
                    
                    // Take items from Popular Dramas section only
                    newDramas = popularDramasSection.list
                    
                    // Filter items that have drama_name and image_url (same as your reference)
                    let validItems = newDramas.filter { item in
                        let hasName = item.dramaName != nil && !item.dramaName!.isEmpty
                        let hasImage = item.imageUrl != nil && !item.imageUrl!.isEmpty
                        
                        if !hasName || !hasImage {
                            print("Filtering out incomplete item: ID=\(item.id ?? "nil"), Name=\(item.dramaName ?? "nil"), Image=\(item.imageUrl ?? "nil")")
                        }
                        
                        return hasName && hasImage
                    }
                    
                    newDramas = validItems
                    
                    // Debug: Print first few items
                    for (itemIndex, item) in newDramas.prefix(3).enumerated() {
                        print("  Item \(itemIndex): \(item.displayName), ID: \(item.id ?? "nil")")
                    }
                } else {
                    print("Popular Dramas section not found in response")
                }
                
                print("Total Popular Dramas items: \(newDramas.count)")
                
                if isLoadMore {
                    // Check for duplicates before appending (same logic as your reference)
                    var uniqueNewDramas: [DramaItem] = []
                    
                    // Create a set of existing drama IDs for quick lookup
                    let existingDramaIds = Set(self.allDramaStories.compactMap { $0.id })
                    
                    for drama in newDramas {
                        // Check if drama has an ID and if it already exists
                        if let dramaId = drama.id, dramaId.isEmpty == false {
                            if !existingDramaIds.contains(dramaId) {
                                uniqueNewDramas.append(drama)
                            } else {
                                print("Duplicate drama found with ID: \(dramaId), Name: \(drama.dramaName ?? "Unknown")")
                            }
                        } else {
                            // If drama has no ID, try to check by name (fallback)
                            if let dramaName = drama.dramaName, !dramaName.isEmpty {
                                let existingDramaNames = Set(self.allDramaStories.compactMap { $0.dramaName })
                                if !existingDramaNames.contains(dramaName) {
                                    uniqueNewDramas.append(drama)
                                } else {
                                    print("Duplicate drama found with Name: \(dramaName)")
                                }
                            } else {
                                // If no ID and no name, just add it (unlikely case)
                                uniqueNewDramas.append(drama)
                            }
                        }
                    }
                    
                    print("Adding \(uniqueNewDramas.count) unique dramas (removed \(newDramas.count - uniqueNewDramas.count) duplicates)")
                    self.allDramaStories.append(contentsOf: uniqueNewDramas)
                    
                    // Update pagination state
                    self.hasMoreData = !newDramas.isEmpty
                    if self.hasMoreData {
                        self.currentPage = page
                    }
                } else {
                    // For first page, also check for duplicates within the new data itself
                    var uniqueDramas: [DramaItem] = []
                    var seenIds = Set<String>()
                    var seenNames = Set<String>()
                    
                    for drama in newDramas {
                        var isUnique = true
                        
                        // First check by ID
                        if let dramaId = drama.id, !dramaId.isEmpty {
                            if seenIds.contains(dramaId) {
                                isUnique = false
                                print("Duplicate drama found with ID: \(dramaId), Name: \(drama.dramaName ?? "Unknown")")
                            } else {
                                seenIds.insert(dramaId)
                            }
                        }
                        
                        // If ID is missing or empty, check by name
                        if isUnique, let dramaName = drama.dramaName, !dramaName.isEmpty {
                            if seenNames.contains(dramaName) {
                                isUnique = false
                                print("Duplicate drama found with Name: \(dramaName)")
                            } else {
                                seenNames.insert(dramaName)
                            }
                        }
                        
                        if isUnique {
                            uniqueDramas.append(drama)
                        }
                    }
                    
                    print("Setting \(uniqueDramas.count) unique dramas (removed \(newDramas.count - uniqueDramas.count) duplicates)")
                    self.allDramaStories = uniqueDramas
                    
                    // Update pagination state
                    self.hasMoreData = !newDramas.isEmpty
                    if self.hasMoreData {
                        self.currentPage = page
                    }
                    
                    // Hide initial loading and show table view
                    DispatchQueue.main.async {
                        self.hideInitialLoading()
                        self.collectionView.isHidden = false
                        self.initialLoadComplete = true
                    }
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    
                    // Debug: Check the data at specific indices
                    if self.allDramaStories.count > 5 {
                        let item = self.allDramaStories[5]
                        print("=== ITEM AT INDEX 5 ===")
                        print("ID: \(item.id ?? "nil")")
                        print("Display Name: \(item.displayName)")
                        print("=== END ===")
                    }
                    
                    // Show/hide noDataView based on data
                    self.noDataView.isHidden = !self.allDramaStories.isEmpty
                    
                    // Fetch episodes for each drama
                    self.fetchEpisodesForAllDramas()
                }
                
            case .failure(let error):
                print("Error fetching dramas: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hideInitialLoading()
                    self.collectionView.isHidden = false
                    self.noDataView.isHidden = !self.allDramaStories.isEmpty
                }
            }
        }
    }
    
    private func fetchEpisodesForAllDramas() {
        for drama in allDramaStories {
            guard let dramaId = drama.id else { continue }
            
            // Skip if we already have episodes for this drama
            if episodesForDramas[dramaId] != nil {
                continue
            }
            
            // Fetch episodes for this drama
            NetworkManager.shared.fetchEpisodes(from: self, dramaId: dramaId, page: 1) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let episodes):
                    // Store episodes for this drama
                    self.episodesForDramas[dramaId] = episodes
                    
                case .failure(let error):
                    print("Error fetching episodes for drama \(dramaId): \(error.localizedDescription)")
                }
            }
        }
    }
}


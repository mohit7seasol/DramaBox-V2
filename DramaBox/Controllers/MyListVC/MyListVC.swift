//
//  MyListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit

class MyListVC: UIViewController {
    
    @IBOutlet weak var exploreMoreButton: UIButton!
    @IBOutlet weak var watchHistoryButton: UIButton!
    @IBOutlet weak var myListButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var watchButtonSelectedImageView: UIImageView!
    @IBOutlet weak var myListButtonSelectedImageView: UIImageView!
    @IBOutlet weak var noDataAvailableView: UIView!
    @IBOutlet weak var noDataImageView: UIImageView!
    @IBOutlet weak var noDataFoundLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var expoloreButtonView: GradientDesignableView!
    @IBOutlet weak var exploreButtonLabel: UILabel!
    
    // Data sources
    private var watchHistory: [WatchHistoryItem] = []
    private var savedEpisodes: [SavedEpisode] = []
    private var isWatchHistorySelected = true
    private var isEditMode = false
    private var selectedItems: Set<String> = [] // Store episode IDs
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setCollectionView()
        loadData()
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
        loadData()
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recalculate layout when view size changes
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            updateCollectionViewLayout(layout)
        }
    }
    
    func setUI() {
        // Configure buttons
        watchHistoryButton.setTitleColor(.white, for: .selected)
        watchHistoryButton.setTitleColor(UIColor(hex: "#878787"), for: .normal)
        myListButton.setTitleColor(.white, for: .selected)
        myListButton.setTitleColor(UIColor(hex: "#878787"), for: .normal)
        
        // Set initial selection
        isWatchHistorySelected = true
        updateButtonSelection()
        
        // Configure edit button
        editButton.setImage(UIImage(named: "edit"), for: .normal)
        editButton.isHidden = true
        
        // Configure no data view
        noDataAvailableView.isHidden = true
        self.exploreButtonLabel.text = "Explore More".localized(LocalizationService.shared.language)
        self.exploreButtonLabel.textColor = .black
        self.expoloreButtonView.cornerRadius = expoloreButtonView.frame.height / 2.0
        
        self.exploreButtonLabel.font = FontManager.shared.font(for: .robotoSerif, size: 16.0)
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        self.watchHistoryButton.setTitle("Watch History".localized(LocalizationService.shared.language), for: .normal)
        self.watchHistoryButton.titleLabel?.font = FontManager.shared.font(for: .robotoSerif, size: 16.0)
        self.myListButton.setTitle("My List".localized(LocalizationService.shared.language), for: .normal)
        self.myListButton.titleLabel?.font = FontManager.shared.font(for: .robotoSerif, size: 16.0)
        self.noDataFoundLabel.text = "No data found".localized(LocalizationService.shared.language)
        
        welcomeLabel.text = "Welcome to".localized(LocalizationService.shared.language)
        self.appNameLabel.text = "Sora Pixo".localized(LocalizationService.shared.language)
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
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
    func setCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "MyListCell", bundle: nil), forCellWithReuseIdentifier: "MyListCell")
        collectionView.backgroundColor = .clear
        
        // Remove content inset to ensure cells use full width
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Configure layout for 3x3 grid
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // Set initial layout
        updateCollectionViewLayout(layout)
        collectionView.collectionViewLayout = layout
    }
    
    private func updateCollectionViewLayout(_ layout: UICollectionViewFlowLayout) {
        let collectionWidth = collectionView.frame.width
        
        // For 3 columns
        let columns: CGFloat = 3
        let horizontalInset: CGFloat = 0  // No left/right spacing
        let spacing: CGFloat = 0  // No spacing between cells
        
        // Calculate width for 3 columns with no spacing
        let totalSpacing = (columns - 1) * spacing + (horizontalInset * 2)
        let cellWidth = (collectionWidth - totalSpacing) / columns
        
        // Fixed height as requested: 172
        let cellHeight: CGFloat = 172
        
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = 0  // No spacing between rows
    }
    
    func loadData() {
        watchHistory = LocalStorageManager.shared.getWatchHistory()
        savedEpisodes = LocalStorageManager.shared.getSavedEpisodes()
        
        // Show edit button if there's data
        let currentDataCount = isWatchHistorySelected ? watchHistory.count : savedEpisodes.count
        editButton.isHidden = currentDataCount == 0
        
        updateUI()
        collectionView.reloadData()
    }
    
    func updateUI() {
        let currentDataCount = isWatchHistorySelected ? watchHistory.count : savedEpisodes.count
        let hasData = currentDataCount > 0
        
        if hasData {
            collectionView.isHidden = false
            noDataAvailableView.isHidden = true
            collectionView.reloadData()
        } else {
            collectionView.isHidden = true
            noDataAvailableView.isHidden = false
            
            // Set appropriate no data image
            if isWatchHistorySelected {
                noDataImageView.image = UIImage(named: "no_watch")
                noDataFoundLabel.text = "No watch history yet".localized(LocalizationService.shared.language)
            } else {
                noDataImageView.image = UIImage(named: "no_mylist")
                noDataFoundLabel.text = "No saved episodes yet".localized(LocalizationService.shared.language)
            }
        }
        
        // Update edit button
        if !hasData {
            isEditMode = false
            selectedItems.removeAll()
            editButton.setImage(UIImage(named: "edit"), for: .normal)
        }
    }
    
    func updateButtonSelection() {
        watchHistoryButton.isSelected = isWatchHistorySelected
        myListButton.isSelected = !isWatchHistorySelected
        
        watchButtonSelectedImageView.isHidden = !isWatchHistorySelected
        myListButtonSelectedImageView.isHidden = isWatchHistorySelected
        
        // Reset edit mode when switching tabs
        isEditMode = false
        selectedItems.removeAll()
        editButton.setImage(UIImage(named: "edit"), for: .normal)
        loadData()
    }
    
    func toggleEditMode() {
        isEditMode.toggle()
        
        if isEditMode {
            editButton.setImage(UIImage(named: "delete"), for: .normal)
        } else {
            editButton.setImage(UIImage(named: "edit"), for: .normal)
            selectedItems.removeAll()
        }
        
        collectionView.reloadData()
    }
    
    func deleteSelectedItems() {
        guard !selectedItems.isEmpty else { return }
        
        let alert = UIAlertController(
            title: "Delete Items".localized(LocalizationService.shared.language),
            message: "\("Are you sure you want to delete") \(selectedItems.count) \("selected item(s)?".localized(LocalizationService.shared.language))",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel".localized(LocalizationService.shared.language), style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete".localized(LocalizationService.shared.language), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isWatchHistorySelected {
                LocalStorageManager.shared.removeMultipleWatchHistory(episodeIds: Array(self.selectedItems))
            } else {
                LocalStorageManager.shared.removeMultipleSavedEpisodes(episodeIds: Array(self.selectedItems))
            }
            
            self.selectedItems.removeAll()
            self.isEditMode = false
            self.editButton.setImage(UIImage(named: "edit"), for: .normal)
            self.loadData()
        })
        
        present(alert, animated: true)
    }
    
    // Helper method to configure cell
    private func configureCell(_ cell: MyListCell, with episode: EpisodeItem, at indexPath: IndexPath, isSelected: Bool) {
        // Set episode data
        cell.configure(with: episode.epiName, imageUrl: URL(string: episode.thumbnails))
        
        // Configure selection button
        cell.cellSelectedButton.isHidden = !isEditMode
        
        let buttonImage = isSelected ? UIImage(named: "list_select") : UIImage(named: "list_unselect")
        cell.cellSelectedButton.setImage(buttonImage, for: .normal)
        
        // Add tap handler
        cell.cellSelectedButton.tag = indexPath.item
        cell.cellSelectedButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.cellSelectedButton.addTarget(self, action: #selector(cellSelectionButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func cellSelectionButtonTapped(_ sender: UIButton) {
        let indexPath = IndexPath(item: sender.tag, section: 0)
        handleItemSelection(at: indexPath)
    }
    
    private func handleItemSelection(at indexPath: IndexPath) {
        let episodeId = isWatchHistorySelected ?
            watchHistory[indexPath.item].episode.epiId :
            savedEpisodes[indexPath.item].episode.epiId
        
        if selectedItems.contains(episodeId) {
            selectedItems.remove(episodeId)
        } else {
            selectedItems.insert(episodeId)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Button Actions
extension MyListVC {
    @IBAction func exploreMoreButton(_ sender: UIButton) {
        showInterAdClick()
        // Switch to TabBar index 0
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func watchHistoryButton(_ sender: UIButton) {
        isWatchHistorySelected = true
        updateButtonSelection()
    }
    
    @IBAction func myListButton(_ sender: UIButton) {
        isWatchHistorySelected = false
        updateButtonSelection()
    }
    
    @IBAction func editListButtonAction(_ sender: UIButton) {
        if isEditMode && !selectedItems.isEmpty {
            deleteSelectedItems()
        } else {
            toggleEditMode()
        }
    }
    
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        collectionView.reloadData()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MyListVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isWatchHistorySelected ? watchHistory.count : savedEpisodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyListCell", for: indexPath) as! MyListCell
        
        if isWatchHistorySelected {
            let historyItem = watchHistory[indexPath.item]
            let isSelected = selectedItems.contains(historyItem.episode.epiId)
            configureCell(cell, with: historyItem.episode, at: indexPath, isSelected: isSelected)
        } else {
            let savedItem = savedEpisodes[indexPath.item]
            let isSelected = selectedItems.contains(savedItem.episode.epiId)
            configureCell(cell, with: savedItem.episode, at: indexPath, isSelected: isSelected)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditMode else {
            // In edit mode, treat cell tap as selection
            handleItemSelection(at: indexPath)
            return
        }
        
        // Navigate to episode player
        if isWatchHistorySelected {
            let historyItem = watchHistory[indexPath.item]
            navigateToEpisode(historyItem.episode)
        } else {
            let savedItem = savedEpisodes[indexPath.item]
            navigateToEpisode(savedItem.episode)
        }
    }
    
    private func navigateToEpisode(_ episode: EpisodeItem) {
        // Create and present episode player
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ViewAllEpisodsStoriesVC") as? ViewAllEpisodsStoriesVC {
            vc.dramaId = episode.dId
            vc.dramaName = episode.dName
            vc.allEpisodes = [episode] // Pass the single episode
            vc.isOpenFromMyList = true
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)  // No insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0  // No spacing between rows
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0  // No spacing between columns
    }
}

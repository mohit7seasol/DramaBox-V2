//
//  AllHotePicksAndNewDramaVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 10/12/25.
//

import UIKit

enum DramaTypes {
    case new
    case hot
}

class AllHotePicksAndNewDramaVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var dramaType: DramaTypes = .new
    var dramaList: [DramaItem] = []
    var episodesForDramas: [String: [EpisodeItem]] = [:]
    
    // ✅ ADD NATIVE AD PROPERTIES
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    var nativeAdContainerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setCollectionView()
        subscribeNativeAd() // ✅ SUBSCRIBE TO NATIVE ADS
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recalculate layout when view size changes
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func setUpUI() {
        // Set background
        view.backgroundColor = UIColor(hex: "#111111")
        collectionView.backgroundColor = .clear
        
        // Set title label
        titleLabel.text = dramaType == .new ? "New Dramas".localized(LocalizationService.shared.language) : "Hot Picks".localized(LocalizationService.shared.language)
        titleLabel.textColor = .white
        titleLabel.font = FontManager.shared.font(for: .roboto, size: 20.0)
    }
    
    func setCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // ✅ REGISTER NATIVE AD CELL
        collectionView.register(UINib(nibName: "NativeAdCell", bundle: nil), forCellWithReuseIdentifier: "NativeAdCell")
        
        // Register cells based on drama type
        if dramaType == .new {
            let newDramaNib = UINib(nibName: "NewDramaCell", bundle: nil)
            collectionView.register(newDramaNib, forCellWithReuseIdentifier: "NewDramaCell")
        } else {
            let hotPicksNib = UINib(nibName: "HotPicDataCell", bundle: nil)
            collectionView.register(hotPicksNib, forCellWithReuseIdentifier: "HotPicDataCell")
        }
        
        // Remove all content insets
        collectionView.contentInset = .zero
        collectionView.contentInsetAdjustmentBehavior = .never
        
        // Disable estimated size
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.estimatedItemSize = .zero

            if dramaType == .new {
                layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
                layout.minimumLineSpacing = 0
                layout.minimumInteritemSpacing = 0
            } else {
                layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                layout.minimumLineSpacing = 10
                layout.minimumInteritemSpacing = 0
            }
        }
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
            
            print("✅ AllHotePicksAndNewDramaVC Native Ad Loaded")
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
            
            print("❌ AllHotePicksAndNewDramaVC Native Ad Failed to Load")
            HelperManager.hideSkeleton(nativeAdView: self.nativeAdContainerView)
            self.isShowNativeAds = false
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func navigateToEpisodes(for drama: DramaItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewAllEpisodesVC = storyboard.instantiateViewController(withIdentifier: "ViewAllEpisodsStoriesVC") as? ViewAllEpisodsStoriesVC {
            viewAllEpisodesVC.dramaId = drama.id
            viewAllEpisodesVC.dramaName = drama.dramaName
            viewAllEpisodesVC.storiesPlayingViewType = .isOpenAllStoriesEpisods
            viewAllEpisodesVC.allEpisodes = episodesForDramas[drama.id ?? ""] ?? []
            viewAllEpisodesVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(viewAllEpisodesVC, animated: true)
        }
    }
    
    private func navigateToShortsDetailVC(with drama: DramaItem) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let shortsDetailVC = storyboard.instantiateViewController(
            withIdentifier: "ShortsDetailVC"
        ) as? ShortsDetailVC {
            
            // Pass the selected drama
            shortsDetailVC.dramaItem = drama
            shortsDetailVC.episodesForDramas = episodesForDramas
            
            shortsDetailVC.hidesBottomBarWhenPushed = true
            
            // Push to navigation controller
            navigationController?.pushViewController(shortsDetailVC, animated: true)
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension AllHotePicksAndNewDramaVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // ✅ UPDATE TO 2 SECTIONS
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Section 0: Native Ad, Section 1: Drama Items
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            // Native Ad Section - show only if ads are enabled
            return isShowNativeAds ? 1 : 0
        } else {
            // Drama Items Section
            return dramaList.count
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
            cell.contentView.addSubview(nativeAdContainerView)
            
            return cell
        } else {
            // ✅ DRAMA ITEM CELLS
            guard indexPath.item < dramaList.count else {
                return UICollectionViewCell()
            }
            
            let drama = dramaList[indexPath.item]
            
            if dramaType == .new {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewDramaCell", for: indexPath) as! NewDramaCell
                cell.configure(with: drama)
                cell.contentView.backgroundColor = .clear
                cell.backgroundColor = .clear
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
                cell.configure(with: drama, shouldAddGradient: true)
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // ✅ DON'T ALLOW SELECTION OF NATIVE AD CELL
        if indexPath.section == 0 {
            return
        }
        self.showInterAdClick()
        guard indexPath.item < dramaList.count else { return }
        
        let selectedDrama = dramaList[indexPath.item]
        navigateToShortsDetailVC(with: selectedDrama)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            // ✅ NATIVE AD CELL SIZE
            return CGSize(width: collectionView.frame.width, height: isShowNativeAds ? 200 : 0)
        } else {
            // ✅ DRAMA ITEM CELL SIZES
            if dramaType == .new {
                let columns: CGFloat = 2
                let spacing: CGFloat = 5
                
                if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
                    
                    let insetLeft = layout.sectionInset.left
                    let insetRight = layout.sectionInset.right
                    
                    let totalSpacing = spacing * (columns - 1)
                    let totalInset = insetLeft + insetRight
                    
                    let availableWidth = collectionView.bounds.width - totalSpacing - totalInset
                    
                    let cellWidth = floor(availableWidth / columns)

                    // Square cell for gallery-style look
                    return CGSize(width: cellWidth, height: 250.0)
                }

                return CGSize(width: 0, height: 0)

            } else {
                let collectionWidth = collectionView.bounds.width
                let horizontalInset: CGFloat = 0
                let cellWidth = collectionWidth - (horizontalInset * 2)

                return CGSize(width: cellWidth, height: 128)
            }
        }
    }
    
    // ✅ UPDATE SECTION INSETS
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if section == 0 {
            // Native Ad Section - no insets
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            // Drama Items Section
            if dramaType == .new {
                return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            } else {
                return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }
        }
    }
}

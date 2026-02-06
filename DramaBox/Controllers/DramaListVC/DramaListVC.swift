//
//  DramaListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 02/02/26.
//

import UIKit
import SVProgressHUD
import GoogleMobileAds
import SDWebImage
import MarqueeLabel

class DramaListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Properties
    var dramaItem: DramaItem?
    var dramaName: String?
    var episodes: [EpisodeItem] = []
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
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
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        titleLabel.text = dramaName ?? "All Episodes"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        // Setup back button
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Setup collection view
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cell
        let nib = UINib(nibName: "ShortsListCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ShortsListCell")
        
        // Set collection view layout (grid layout like StoriesVC)
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        
        collectionView.collectionViewLayout = layout
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
    }
    
    // MARK: - Native Ads
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
    
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        collectionView.reloadData()
    }
    
    // MARK: - Button Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    private func isEpisodePremium(at index: Int) -> Bool {
        if Subscribe.get() == true {
            return false
        }
        
        if index < 2 {
            return false
        }
        
        return true
    }
    
    private func handleEpisodeTap(at index: Int) {
        guard index < episodes.count else { return }
        
        if Subscribe.get() == false {
            if index < 2 {
                openEpisodeAtIndex(index)
            } else {
                openPremiumVC()
            }
        } else {
            openEpisodeAtIndex(index)
        }
    }
    
    private func openEpisodeAtIndex(_ index: Int) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let viewAllVC = storyboard.instantiateViewController(
            withIdentifier: "ViewAllEpisodsStoriesVC"
        ) as? ViewAllEpisodsStoriesVC {
            
            viewAllVC.allEpisodes = episodes
            viewAllVC.startingIndex = index
            viewAllVC.isTrailerOnly = false
            viewAllVC.dramaName = dramaName
            
            viewAllVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewAllVC, animated: true)
        }
    }
    
    private func openPremiumVC() {
        print("Opening PremiumVC...")
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        if let vc = storyboard.instantiateViewController(
            withIdentifier: "PremiumVC"
        ) as? PremiumVC {

            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .coverVertical

            self.present(vc, animated: true)
        } else {
            print("Failed to instantiate PremiumVC")
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension DramaListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortsListCell", for: indexPath) as! ShortsListCell
        
        guard indexPath.item < episodes.count else {
            return cell
        }
        
        let episode = episodes[indexPath.item]
        
        // Configure cell with episode data
        if let thumbnailUrl = URL(string: episode.thumbnails) {
            cell.thumbImageView.sd_setImage(
                with: thumbnailUrl,
                placeholderImage: UIImage(named: "hoteDefault"),
                options: [.progressiveLoad, .refreshCached]
            )
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        
        // Set episode name with marquee effect
        cell.nameLabel.text = episode.epiName
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Show episode number (index + 1 since trailer is at index 0)
        cell.totalEpisodesCountLabel.isHidden = false
        cell.totalEpisodesCountLabel.text = "Episode \(indexPath.item + 1)"
        cell.totalEpisodesCountLabel.isHidden = true
        
        // Configure premium logic based on subscription
        if Subscribe.get() == false {
            // For NON-subscribed users
            // First 2 episodes (index 0 and 1) are free (including trailer)
            if indexPath.item < 2 {
                // First 2 episodes (index 0 and 1): FREE - show play icon, hide lock
                cell.playIconImageView.isHidden = false
                cell.lockEpisodeIconImageView.isHidden = true
            } else {
                // Episodes 3+ (index 2 onward): PREMIUM - hide play icon, show lock
                cell.playIconImageView.isHidden = true
                cell.lockEpisodeIconImageView.isHidden = false
            }
        } else {
            // For SUBSCRIBED users: ALL episodes are free - show play icon, hide lock
            cell.playIconImageView.isHidden = false
            cell.lockEpisodeIconImageView.isHidden = true
        }
        
        // Handle cell tap
        cell.setOnClickListener { [weak self] in
            self?.handleEpisodeTap(at: indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 10
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let itemsPerRow: CGFloat = isPad ? 4 : 2
        
        let totalSpacing = (2 * spacing) + ((itemsPerRow - 1) * spacing)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Selection is handled in the cell's onClickListener
    }
}

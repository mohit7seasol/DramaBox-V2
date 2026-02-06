//
//  ShortsDetailVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 31/01/26.
//

import UIKit
import SVProgressHUD
import GoogleMobileAds
import SDWebImage
import MarqueeLabel

class ShortsDetailVC: UIViewController {

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var watchTrailerLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var totalEpisodeCountLabel: UILabel!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var overViewLabel: UILabel!
    @IBOutlet weak var readMoreLabel: UILabel!
    @IBOutlet weak var readMoreIconImageView: UIImageView!
    @IBOutlet weak var episodeTitleLabel: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var shareButtonView: GradientDesignableView!
    @IBOutlet weak var shareButtonLabel: UILabel!
    @IBOutlet weak var playButtonView: GradientDesignableView!
    @IBOutlet weak var playButtonLabel: UILabel!
    
    
    // Properties
    var dramaItem: DramaItem?
    var episodesForDramas: [String: [EpisodeItem]] = [:]
    var trailerEpisode: EpisodeItem?
    var isDescriptionExpanded = false
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    // Store ALL episodes for this specific drama (without trailer)
    private var allEpisodes: [EpisodeItem] = []
    
    // Store only first 10 episodes for collection view display
    private var displayedEpisodes: [EpisodeItem] = []
    
    // MARK: - Constants
    private let maxDisplayedEpisodes = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupCollectionView()
        setupReadMore()
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
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUI() {
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        setCollection()
        setupLabels()
        setupNavigation()
    }
    
    private func setupNavigation() {
        let backButton = UIBarButtonItem(image: UIImage(named: "back"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupLabels() {
        episodeTitleLabel.text = "Episode".localized(LocalizationService.shared.language)
        viewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        watchTrailerLabel.text = "Watch Trailer".localized(LocalizationService.shared.language)
        readMoreLabel.text = "Read More".localized(LocalizationService.shared.language)
        playButtonLabel.text = "Play".localized(LocalizationService.shared.language)
        playButtonView.cornerRadius = playButtonView.frame.height / 2
        
        shareButtonLabel.text = "Share".localized(LocalizationService.shared.language)
        shareButtonView.cornerRadius = shareButtonView.frame.height / 2
        
        readMoreIconImageView.image = UIImage(named: "down_arrow")
        overViewLabel.numberOfLines = 3
        overViewLabel.lineBreakMode = .byTruncatingTail
    }
    
    private func setupReadMore() {
        updateReadMoreUI()
    }
    
    private func updateReadMoreUI() {
        overViewLabel.numberOfLines = isDescriptionExpanded ? 0 : 5
        
        if isDescriptionExpanded {
            readMoreLabel.text = "Read Less".localized(LocalizationService.shared.language)
            readMoreIconImageView.image = UIImage(named: "up_arrow")
        } else {
            readMoreLabel.text = "Read More".localized(LocalizationService.shared.language)
            readMoreIconImageView.image = UIImage(named: "down_arrow")
        }
    }
    
    private func loadData() {
        guard let drama = dramaItem else { return }
        
        nameLabel.text = drama.displayName.uppercased()
        
        if let totalEpisodes = drama.totalEpisodes, let episodeCount = Int(totalEpisodes) {
            totalEpisodeCountLabel.text = "Total Episodes:".localized(LocalizationService.shared.language) + " \(episodeCount)"
        } else {
            totalEpisodeCountLabel.text = "Total Episodes:".localized(LocalizationService.shared.language) + " 0"
        }
        
        if let imageUrl = drama.imageUrl, let url = URL(string: imageUrl) {
            thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
        } else {
            thumbImageView.image = UIImage(named: "hoteDefault")
        }
        
        if let description = drama.dDesc, !description.isEmpty {
            overViewLabel.text = description
        } else {
            overViewLabel.text = drama.displayName
        }
        
        if let dramaId = drama.id, var dramaEpisodes = episodesForDramas[dramaId] {
            self.allEpisodes = dramaEpisodes
            
            // Check if first episode is a Trailer and handle it
            if !allEpisodes.isEmpty {
                let firstEpisode = allEpisodes[0]
                
                // Check if the first episode's name contains "Trailer" (case insensitive)
                if firstEpisode.epiName.lowercased().contains("trailer") == true {
                    trailerEpisode = firstEpisode
                    allEpisodes.removeFirst()
                    print("✅ Trailer extracted. Total episodes: \(allEpisodes.count)")
                } else {
                    // If not a trailer, check if permanently 0 index data should be treated as trailer
                    // Based on requirement: "without check permanently 0 index data is trailer"
                    trailerEpisode = firstEpisode
                    allEpisodes.removeFirst()
                    print("✅ First episode treated as trailer. Total episodes: \(allEpisodes.count)")
                }
            }
            
            // Set displayed episodes (first 10 or less)
            updateDisplayedEpisodes()
            
            DispatchQueue.main.async {
                if let trailerDesc = self.trailerEpisode?.dDesc {
                    self.overViewLabel.text = trailerDesc
                } else if !self.allEpisodes.isEmpty {
                    self.overViewLabel.text = self.allEpisodes[0].dDesc
                }
                
                self.collectionView.reloadData()
                
                print("📊 Collection View Data:")
                print("- Total episodes: \(self.allEpisodes.count)")
                print("- Displayed episodes: \(self.displayedEpisodes.count)")
                print("- First displayed episode: \(self.displayedEpisodes.first?.epiName ?? "None")")
            }
        }
    }
    
    private func updateDisplayedEpisodes() {
        // Take first 10 episodes or all if less than 10
        let count = min(maxDisplayedEpisodes, allEpisodes.count)
        displayedEpisodes = Array(allEpisodes.prefix(count))
        
        // Update view all button visibility
        viewAllButton.isHidden = allEpisodes.count <= maxDisplayedEpisodes
    }
    
    func setCollection() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let nib = UINib(nibName: "ShortsListCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ShortsListCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
    }
    
    private func setupCollectionView() {
        // Additional setup if needed
    }
    
    // MARK: - Native Ads (keep existing subscribeNativeAd method)
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
    
    private func isEpisodePremium(at index: Int) -> Bool {
        if Subscribe.get() == true {
            return false
        }
        
        if index < 2 {
            return false
        }
        
        return true
    }
    
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing Screen")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        collectionView.reloadData()
    }
    
    // MARK: - Button Actions
    
    @IBAction func shareButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        
        guard let drama = dramaItem else { return }
        
        // Create share text
        let shareText = """
        🎬 Check out \(drama.displayName)!
        
        \(drama.dDesc ?? "")
        
        📺 Total Episodes: \(drama.totalEpisodes ?? "N/A")
        """
        
        var items: [Any] = [shareText]
        
        // Add image if available
        if let imageUrl = drama.imageUrl,
           let url = URL(string: imageUrl),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            items.append(image)
        }
        
        // Create share sheet
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = shareButtonView
            popoverController.sourceRect = shareButtonView.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    @IBAction func readMoreButtonTap(_ sender: UIButton) {
        isDescriptionExpanded.toggle()
        updateReadMoreUI()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func viewAllButtonTap(_ sender: UIButton) {
        // Navigate to DramaListVC instead of ViewAllEpisodsStoriesVC
        self.showInterAdClick()
        openDramaListVC()
    }
    
    @IBAction func watchTrailerTap(_ sender: UIButton) {
        openTrailerEpisode()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playFirstEpisodeButtonTap(_ sender: UIButton) {
        openEpisodeAtIndex(0)
    }
    
    // MARK: - Navigation Methods
    
    private func openTrailerEpisode() {
        guard let trailer = trailerEpisode else { return }
        
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let viewAllVC = storyboard.instantiateViewController(
            withIdentifier: "ViewAllEpisodsStoriesVC"
        ) as? ViewAllEpisodsStoriesVC {
            
            // 1) Display only one trailerEpisode when tap watchTrailerTap
            viewAllVC.allEpisodes = [trailer]
            viewAllVC.startingIndex = 0
            viewAllVC.isTrailerOnly = true
            viewAllVC.dramaName = dramaItem?.displayName
            
            viewAllVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewAllVC, animated: true)
        }
    }
    
    private func navigateToEpisode(_ episode: EpisodeItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ViewAllEpisodsStoriesVC") as? ViewAllEpisodsStoriesVC {
            vc.dramaId = episode.dId
            vc.dramaName = episode.dName
            vc.allEpisodes = [episode]
            vc.isOpenFromMyList = true
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func openDramaListVC() {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let dramaListVC = storyboard.instantiateViewController(
            withIdentifier: "DramaListVC"
        ) as? DramaListVC {
            
            // IMPORTANT: Pass episodes WITHOUT trailer to DramaListVC
            // Use the allEpisodes array which already has trailer removed
            dramaListVC.episodes = allEpisodes // No trailer included
            dramaListVC.dramaName = dramaItem?.displayName
            dramaListVC.dramaItem = dramaItem
            
            dramaListVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(dramaListVC, animated: true)
        }
    }
    
    private func openEpisodeAtIndex(_ index: Int) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let viewAllVC = storyboard.instantiateViewController(
            withIdentifier: "ViewAllEpisodsStoriesVC"
        ) as? ViewAllEpisodsStoriesVC {
            viewAllVC.allEpisodes = allEpisodes
            viewAllVC.startingIndex = index
            viewAllVC.isTrailerOnly = false
            viewAllVC.dramaName = dramaItem?.displayName
            
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
    
    private func handleEpisodeTap(at index: Int) {
        guard index < displayedEpisodes.count else { return }
        
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
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension ShortsDetailVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedEpisodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShortsListCell", for: indexPath) as! ShortsListCell
        
        guard indexPath.item < displayedEpisodes.count else {
            return cell
        }
        
        let episode = displayedEpisodes[indexPath.item]
        
        if let thumbnailUrl = URL(string: episode.thumbnails) {
            cell.thumbImageView.sd_setImage(
                with: thumbnailUrl,
                placeholderImage: UIImage(named: "hoteDefault"),
                options: [.progressiveLoad, .refreshCached]
            )
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        
        cell.nameLabel.text = episode.epiName
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        cell.totalEpisodesCountLabel.isHidden = true
        
        if Subscribe.get() == false {
            if indexPath.item < 2 {
                cell.playIconImageView.isHidden = false
                cell.lockEpisodeIconImageView.isHidden = true
            } else {
                cell.playIconImageView.isHidden = true
                cell.lockEpisodeIconImageView.isHidden = false
            }
        } else {
            cell.playIconImageView.isHidden = false
            cell.lockEpisodeIconImageView.isHidden = true
        }
        
        cell.setOnClickListener { [weak self] in
            self?.handleEpisodeTap(at: indexPath.item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 2.6
        return CGSize(width: width, height: 186)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Selection is handled in the cell's onClickListener
    }
}

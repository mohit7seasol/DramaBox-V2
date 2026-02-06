//
//  HomeVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import Foundation
import Alamofire
import UIKit
import SVProgressHUD
import Lottie
import Cosmos
import StoreKit

// MARK - If "A" then Load Drama data else Movie data

enum PremiumTriggerSource {
    case auto
    case userTap
}

class HomeVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lottieAnimationLoadingView: UIView!
    
    // Movie
    @IBOutlet weak var popularCollection: UICollectionView!
    @IBOutlet weak var upcomingLbl: UILabel!
    @IBOutlet weak var viewAllUpcomingButton: UIButton!
    @IBOutlet weak var upcomingCollection: UICollectionView!
    @IBOutlet weak var topRatedLbl: UILabel!
    @IBOutlet weak var viewAllTopRatedButton: UIButton!
    @IBOutlet weak var topRatedCollection: UICollectionView!
    @IBOutlet weak var movieListScrollView: UIScrollView!
    
    @IBOutlet weak var topRatedCollectionHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var topRatedMovieView: UIView!
    
    @IBOutlet weak var addMovieNativeView: UIView!
    @IBOutlet weak var movieNativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var iptvLottieView: UIView!
    
    // Properties for pagination
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var allDramas: [DramaItem] = []
    
    // Data for sections
    private var popularDramas: [DramaItem] = []
    private var newDramas: [DramaItem] = []
    private var hotPicks: [DramaItem] = []
    private var autoScrollTimer: Timer?
    private var splashLoader: LottieAnimationView?
    
    // Search functionality
    private var isSearching = false
    private var searchedDramas: [DramaItem] = []
    
    // No data label for search
    private let noDataLabel: UILabel = {
        let label = UILabel()
        label.text = "No data found"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    // Moview Var
    private var popularMovies: [Movie] = []
    private var upcomingMovies: [Movie] = []
    private var topRatedMovies: [Movie] = []
    private var popularAutoScrollTimer: Timer?
    private var gradientLayer: CAGradientLayer?
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    var dramaNativeAdContainerView = UIView()
    var episodesForDramas: [String: [EpisodeItem]] = [:]
    
    private var hasOpenedPremiumThisSession = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Check if we should show Drama or Movie
        isShowDrama = "B"
        if isShowDrama == "A" {
            // Show Drama
            setUpUI()
            setTable()
            setUpSearchBar()
            subscribeDramaNativeAd()
            fetchDramas(page: 1)
            movieListScrollView.isHidden = true
            tableView.isHidden = false
        } else if isShowDrama == "B" {
            // Show Movie
            setupMovieUI()
            setUpSearchBar()
            setupMovieCollections()
            subscribeMovieNativeAd()
            fetchAllMovies()
            movieListScrollView.isHidden = false
            tableView.isHidden = true
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRateCheck),
            name: .triggerRateCheck,
            object: nil
        )
        // Add notification observer for subscription changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Start auto-scroll for both modes when view appears
        if isShowDrama == "A" {
            startAutoScroll()
        } else if isShowDrama == "B" {
            startPopularAutoScroll()
        }
        setupGif()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop auto-scroll for both modes when view disappears
        if isShowDrama == "A" {
            stopAutoScroll()
        } else if isShowDrama == "B" {
            stopPopularAutoScroll()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame when layout changes
        if isShowDrama == "B" {
            applyGradienttopRatedMovieView()
        } else {
            tableView.showsVerticalScrollIndicator = false
            tableView.showsHorizontalScrollIndicator = false
        }
    }
    
    deinit {
        if isShowDrama == "A" {
            stopAutoScroll()
        } else if isShowDrama == "B" {
            stopPopularAutoScroll()
        }
    }
    
    func setUpUI() {
        SearchBarStyle.apply(to: searchBar)
        
        // Set welcome labels
        welcomeLabel.text = "Welcome to".localized(LocalizationService.shared.language)
        self.appNameLabel.text = "Sora Pixo".localized(LocalizationService.shared.language) // "Sora Pixo"
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        self.searchBar.placeholder = "Search here...".localized(LocalizationService.shared.language)
        
        welcomeLabel.font = FontManager.shared.font(for: .roboto, size: 14.0)
        appNameLabel.font = FontManager.shared.font(for: .roboto, size: 20.0)
        
        // Add no data label to table view
        tableView.addSubview(noDataLabel)
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            noDataLabel.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 20),
            noDataLabel.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -20)
        ])
        
        // Set linear gradient background like in uploaded image
        setGradientBackground()
    }
    
    func subscribeMovieNativeAd() {
        movieNativeHeighConstant.constant = Subscribe.get() ? 0 : 200
        addMovieNativeView.isHidden = Subscribe.get()

        guard Subscribe.get() == false else {
            HelperManager.hideSkeleton(nativeAdView: addMovieNativeView)
            return
        }

        addMovieNativeView.backgroundColor = UIColor.appAddBg
        HelperManager.showSkeleton(nativeAdView: addMovieNativeView)

        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addMovieNativeView)
                self.movieNativeHeighConstant.constant = 200
                self.addMovieNativeView.isHidden = false
                self.addMovieNativeView.subviews.forEach { $0.removeFromSuperview() }
                self.googleNativeAds.showAdsView8(
                    nativeAd: nativeAdsTemp,
                    view: self.addMovieNativeView
                )
                self.view.layoutIfNeeded()
            }
        }

        googleNativeAds.failAds(self) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addMovieNativeView)
                self.movieNativeHeighConstant.constant = 0
                self.addMovieNativeView.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Native Ads Implementation
    func subscribeDramaNativeAd() {
        // Set initial height to 200 when view loads
        self.dramaNativeAdContainerView.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 200
        )
        
        // Reset state
        self.isShowNativeAds = false
        
        guard Subscribe.get() == false else {
            // User is subscribed, don't show ads
            self.dramaNativeAdContainerView.isHidden = true
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        // User is not subscribed, show skeleton and load ad
        HelperManager.showSkeleton(nativeAdView: self.dramaNativeAdContainerView)
        self.dramaNativeAdContainerView.backgroundColor = UIColor.appAddBg
        self.dramaNativeAdContainerView.isHidden = false
        
        // Set initial frame before loading ad
        self.dramaNativeAdContainerView.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 200
        )
        
        googleNativeAds.loadAds(self) { nativeAdsTemp in
            print("✅ HomeVC Native Ad Loaded")
            self.isShowNativeAds = true
            HelperManager.hideSkeleton(nativeAdView: self.dramaNativeAdContainerView)
            
            // Ad loaded successfully - maintain 200 height
            self.dramaNativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 200
            )
            
            // Remove old ad views
            self.dramaNativeAdContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            self.googleNativeAds.showAdsView8(
                nativeAd: nativeAdsTemp,
                view: self.dramaNativeAdContainerView
            )
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        googleNativeAds.failAds(self) { fail in
            print("❌ HomeVC Native Ad Failed to Load")
            HelperManager.hideSkeleton(nativeAdView: self.dramaNativeAdContainerView)
            self.isShowNativeAds = false
            
            // Ad failed to load - hide it and set height to 0
            self.dramaNativeAdContainerView.isHidden = true
            self.dramaNativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 0
            )
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func setupGif() {
        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named("IPTV")
        animationView.animation = animation
        animationView.frame = iptvLottieView.bounds
        animationView.loopMode = .loop
        self.iptvLottieView.addSubview(animationView)
        animationView.play()
        
        iptvLottieView.setOnClickListener {
            self.showInterAdClick()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "IPTVCategoryListVC") as? IPTVCategoryListVC {
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func setUpSearchBar() {
        // 1. Set searchBar blinking cursor color to white
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.tintColor = .white // This sets the cursor color
            
            // Optional: Customize other text field properties
            textField.textColor = .white
            
            // Set placeholder text color
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            textField.attributedPlaceholder = NSAttributedString(
                string: searchBar.placeholder ?? "Search",
                attributes: placeholderAttributes
            )
        }
        
        // Set white color for cancel button text
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .white
        
        // Set searchBar delegate
        searchBar.delegate = self
    }
    
    func showLottieLoader() {
        // already showing → ignore
        if splashLoader != nil { return }
        
        splashLoader = LottieAnimationView(name: "Splash lottie")
        guard let loader = splashLoader else { return }

        loader.frame = view.bounds
        loader.contentMode = .scaleAspectFit
        loader.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        loader.loopMode = .loop

        view.addSubview(loader)
        view.bringSubviewToFront(loader)

        loader.play()
    }
    
    func hideLottieLoader() {
        guard let loader = splashLoader else { return }
        loader.stop()
        loader.removeFromSuperview()
        splashLoader = nil
    }
    
    private func setGradientBackground() {
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors = [
            UIColor(hex: "#111111")!.cgColor,   // Top
            UIColor(hex: "#171717")!.cgColor,   // Middle
            UIColor(hex: "#0B0B0B")!.cgColor    // Bottom
        ]
        
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = view.bounds

        // ✅ Remove only existing gradients (safe)
        view.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        view.layer.insertSublayer(gradientLayer, at: 0)

        tableView.backgroundColor = .clear
    }
    
    func setTable() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        // Register cells
        self.tableView.register(UINib(nibName: "CarouselTopCell", bundle: nil), forCellReuseIdentifier: "CarouselTopCell")
        self.tableView.register(UINib(nibName: "TitleHeaderCell", bundle: nil), forCellReuseIdentifier: "TitleHeaderCell")
        
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .clear
        
        // Set index color to clear
        tableView.sectionIndexColor = .clear

        // Optional: Also clear the background color if needed
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexTrackingBackgroundColor = .clear

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20))
        footer.backgroundColor = .clear
        tableView.tableFooterView = footer
    }
    
    private func startAutoScroll() {
        stopAutoScroll()
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Only scroll if not searching
            if !self.isSearching {
                if let carouselCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CarouselTopCell {
                    carouselCell.scrollToNextItem()
                }
            }
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    func navigateToAllHotAndNew(type: DramaTypes, allDramas: [DramaItem]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AllHotePicksAndNewDramaVC") as? AllHotePicksAndNewDramaVC {
            vc.dramaType = type
            vc.dramaList = allDramas
            vc.episodesForDramas = episodesForDramas
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    func navigateToMovieDetails(movieId: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "MovieDetailsVC") as? MovieDetailsVC {
            vc.movieId = movieId
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func navigateToMovieList(isPopular:Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "MovieListVC") as? MovieListVC {
            vc.isPopular = isPopular
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func navigateToViewAllEpisodes(for dramaId: String, dramaName: String?, allEpisodes: [EpisodeItem] = []) {
        // Navigate to ViewAllEpisodsStoriesVC
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewAllEpisodesVC = storyboard.instantiateViewController(withIdentifier: "ViewAllEpisodsStoriesVC") as? ViewAllEpisodsStoriesVC {
            viewAllEpisodesVC.dramaId = dramaId
            viewAllEpisodesVC.dramaName = dramaName
            viewAllEpisodesVC.storiesPlayingViewType = .isOpenAllStoriesEpisods
            viewAllEpisodesVC.allEpisodes = allEpisodes
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
    // MARK: - Search Methods
    private func performSearch(with searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            searchedDramas.removeAll()
            noDataLabel.isHidden = true
        } else {
            isSearching = true
            
            // Combine all dramas for searching
            let allCombinedDramas = popularDramas + newDramas + hotPicks
            
            // Filter dramas based on search text
            searchedDramas = allCombinedDramas.filter { drama in
                if let dramaName = drama.dramaName?.lowercased(),
                   dramaName.contains(searchText.lowercased()) {
                    return true
                }
                return false
            }
            
            // Show/hide no data label
            noDataLabel.isHidden = !searchedDramas.isEmpty
        }
        
        // Stop auto-scroll when searching
        if isSearching {
            stopAutoScroll()
        } else {
            startAutoScroll()
        }
        
        tableView.reloadData()
    }
    func showRateScreen() {
        // 🔒 Check local saved rating
        if isRateDone() {
            return
        }

        let alert = UIAlertController(
            title: "Do you like our App?".localized(LocalizationService.shared.language),
            message: "Help us improve the app by answering this quick poll".localized(LocalizationService.shared.language),
            preferredStyle: .alert
        )

        // ❌ NO button → just dismiss
        alert.addAction(UIAlertAction(
            title: "No ❌".localized(LocalizationService.shared.language),
            style: .cancel,
            handler: { _ in
                alert.dismiss(animated: true)
            }
        ))

        // ✅ YES button → rate + save locally
        alert.addAction(UIAlertAction(
            title: "Yes 👍".localized(LocalizationService.shared.language),
            style: .default,
            handler: { _ in
                self.rateApp()
                self.setRateDone(status: true)
            }
        ))

        self.present(alert, animated: true)
    }
    func rateApp() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            if let appStoreURL = URL(string: AppConstant.AppStoreLink) {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: { success in
                    if success {
                        self.setRateDone(status: true)
                    }
                })
            } else {
                let appStoreURL = URL(string: AppConstant.AppStoreLink)
                UIApplication.shared.openURL(appStoreURL!)
            }
        }
    }
    func setRateDone(status: Bool) {
        UserDefaults.standard.set(status, forKey: "isRateDone")
    }

    func isRateDone() -> Bool {
        return UserDefaults.standard.bool(forKey: "isRateDone")
    }
    private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    func checkPremiumStatus(source: PremiumTriggerSource = .auto) {

        let isRateDone = UserDefaults.standard.bool(forKey: "isRateDone")
        let hasShownRateScreen = UserDefaults.standard.bool(forKey: "hasShownRateScreen")

        if Subscribe.get() == true {
            // ✅ Subscribed → show rate only
            
            // ✅ Rate logic (auto only, once)
            if !isRateDone && !hasShownRateScreen {
                showRateScreen()
                UserDefaults.standard.set(true, forKey: "hasShownRateScreen")
            }

        } else {
            // ✅ Not subscribed → open premium first
            if source == .userTap {
                openPremiumVC(assignDelegate: false)
                return
            }

            // 👉 AUTO (app open / reopen)
            guard hasOpenedPremiumThisSession == false else { return }
            hasOpenedPremiumThisSession = true

            let assignDelegate = !isRateDone
            openPremiumVC(assignDelegate: assignDelegate)
        }
    }
    func openPremiumVC(assignDelegate: Bool) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)

        if let vc = storyboard.instantiateViewController(
            withIdentifier: "PremiumVC"
        ) as? PremiumVC {

            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .coverVertical

            if assignDelegate {
                vc.delegate = self
            }

            self.present(vc, animated: true)
        }
    }
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing HomeVC")
        
        DispatchQueue.main.async {
            if isShowDrama == "A" {
                if Subscribe.get() == true {
                    // User is subscribed, hide native ads
                    self.isShowNativeAds = false
                    self.dramaNativeAdContainerView.isHidden = true
                } else {
                    // User is not subscribed, reload native ads
                    self.subscribeDramaNativeAd()
                }
                
                // Reload the tableView to update section count
                self.tableView.reloadData()
            } else {
                self.movieNativeHeighConstant.constant = 0
                self.addMovieNativeView.isHidden = true
                self.movieListScrollView.setNeedsLayout()
                self.movieListScrollView.layoutIfNeeded()
            }

        }
    }
    @objc private func handleRateCheck() {
        checkPremiumStatus()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // When searching, show only one section
        if isSearching {
            return searchedDramas.isEmpty ? 0 : 1
        }
        
        // Native ad will be in section 1, so total sections become 4
        // 0: Carousel, 1: Native Ad, 2: New Dramas, 3: Hot Picks
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // When searching, show only one row
        if isSearching {
            return searchedDramas.isEmpty ? 0 : 1
        }
        
        // Native ad section has 1 row (only when ads are enabled)
        if section == 1 {
            return isShowNativeAds ? 1 : 0
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching {
            // Calculate dynamic height for search results
            let itemHeight: CGFloat = 120
            let interItemSpacing: CGFloat = 15
            let topBottomPadding: CGFloat = 10
            let titleHeight: CGFloat = 40
            
            // Show only 5 rows or less
            let rows = CGFloat(min(searchedDramas.count, 5))
            let totalHeight =
                (rows * itemHeight) +
                (max(0, rows - 1) * interItemSpacing) +
                titleHeight +
                topBottomPadding
            
            return totalHeight - 20
        }
        
        switch indexPath.section {
        case 0: // Carousel section
            return 210
        case 1: // Native Ad section
            return isShowNativeAds  && !dramaNativeAdContainerView.isHidden ? 200 : 0
        case 2: // New Dramas section (was section 1, now section 2)
            return 246
        case 3: // Hot Picks section (was section 2, now section 3)
            let itemHeight: CGFloat = 120
            let interItemSpacing: CGFloat = 15
            let topBottomPadding: CGFloat = 10
            let titleHeight: CGFloat = 40

            let rows = CGFloat(min(hotPicks.count, 5))
            let totalHeight =
                (rows * itemHeight) +
                (max(0, rows - 1) * interItemSpacing) +
                titleHeight +
                topBottomPadding

            return totalHeight - 20
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching {
            // Show search results in Hot Picks style layout
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleHeaderCell", for: indexPath) as! TitleHeaderCell
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            
            cell.configure(type: .HotPicks, title: "Search Results".localized(LocalizationService.shared.language))
            cell.viewAllButton.isHidden = true // Hide view all button in search
            
            // Load search results
            let dramasToShow = Array(searchedDramas.prefix(5)) // Show only first 5 items
            cell.loadHotPicks(dramasToShow)
            
            // Use full width layout
            let itemWidth = tableView.frame.width - 20 // 10px padding on each side
            cell.setCollectionViewLayout(itemWidth: itemWidth, itemHeight: 120, scrollDirection: .vertical, isScrollEnabled: false)
            
            // Handle drama selection from search results
            cell.didSelectDrama = { [weak self] drama in
                /* self?.navigateToViewAllEpisodes(
                    for: drama.id ?? "",
                    dramaName: drama.dramaName,
                    allEpisodes: []
                ) */
                // Navigate to ShortsDetailVC
                self?.showInterAdClick()
                self?.navigateToShortsDetailVC(with: drama)
            }
            return cell
        }
        
        switch indexPath.section {
        case 0: // Carousel section
            let cell = tableView.dequeueReusableCell(withIdentifier: "CarouselTopCell", for: indexPath) as! CarouselTopCell
            cell.configure(with: Array(popularDramas.prefix(10)))
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            cell.didSelectDrama = { [weak self] drama in
                /* self?.navigateToViewAllEpisodes(
                    for: drama.id ?? "",
                    dramaName: drama.dramaName,
                    allEpisodes: []
                ) */
                self?.showInterAdClick()
                self?.navigateToShortsDetailVC(with: drama)
            }
            return cell
            
        case 1: // Native Ad section
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            
            // Remove old ad views before adding new
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Configure the native ad container view
            dramaNativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: tableView.frame.width,
                height: 200
            )
            cell.contentView.addSubview(dramaNativeAdContainerView)
            
            return cell
            
        case 2: // New Dramas section (was section 1, now section 2)
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleHeaderCell", for: indexPath) as! TitleHeaderCell
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            
            cell.configure(type: .NewDramas, title: "New Dramas".localized(LocalizationService.shared.language))
            cell.viewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
            cell.loadNewDramas(Array(newDramas.prefix(10)))
            cell.setCollectionViewLayout(itemWidth: 136, itemHeight: 200, scrollDirection: .horizontal)
            cell.viewAllButton.isHidden = false
            
            cell.viewAllButton.setOnClickListener {
                self.showInterAdClick()
                self.navigateToAllHotAndNew(type: .new, allDramas: self.newDramas)
            }
            cell.didSelectDrama = { [weak self] drama in
                /* self?.navigateToViewAllEpisodes(
                    for: drama.id ?? "",
                    dramaName: drama.dramaName,
                    allEpisodes: []
                ) */
                self?.showInterAdClick()
                self?.navigateToShortsDetailVC(with: drama)
            }
            return cell
            
        case 3: // Hot Picks section (was section 2, now section 3)
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleHeaderCell", for: indexPath) as! TitleHeaderCell
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            
            cell.configure(type: .HotPicks, title: "Hot Picks 🔥".localized(LocalizationService.shared.language))
            cell.viewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
            
            let dramasToShow = Array(hotPicks.prefix(5))
            cell.loadHotPicks(dramasToShow)
            
            let itemWidth = tableView.frame.width - 20
            cell.setCollectionViewLayout(itemWidth: itemWidth, itemHeight: 120, scrollDirection: .vertical, isScrollEnabled: false)
            cell.viewAllButton.isHidden = false
            
            cell.viewAllButton.setOnClickListener {
                self.showInterAdClick()
                self.navigateToAllHotAndNew(type: .hot, allDramas: self.hotPicks)
            }
            cell.didSelectDrama = { [weak self] drama in
                /* self?.navigateToViewAllEpisodes(
                    for: drama.id ?? "",
                    dramaName: drama.dramaName,
                    allEpisodes: []
                ) */
                self?.showInterAdClick()
                self?.navigateToShortsDetailVC(with: drama)
            }
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - ScrollView Delegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Dismiss keyboard when user starts scrolling
        dismissKeyboard()
    }
}

// MARK: - UISearchBarDelegate
extension HomeVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if isShowDrama == "A" {
            // Perform drama search as user types
            performSearch(with: searchText)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        
        // For movie mode, navigate to MovieSearchVC when search bar is tapped
        if isShowDrama == "B" {
            navigateToMovieSearchVC()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if isShowDrama == "A" {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            searchBar.setShowsCancelButton(false, animated: true)
            
            // Clear search
            isSearching = false
            searchedDramas.removeAll()
            noDataLabel.isHidden = true
            startAutoScroll()
            tableView.reloadData()
        } else {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    private func navigateToMovieSearchVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let movieSearchVC = storyboard.instantiateViewController(withIdentifier: "MovieSearchVC") as? MovieSearchVC {
            movieSearchVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(movieSearchVC, animated: true)
        }
    }
}
// MARK: - Api's calling Drama
extension HomeVC {
    func fetchDramas(page: Int, isLoadMore: Bool = false) {
        guard !isLoading, (isLoadMore ? hasMoreData : true) else { return }

        isLoading = true
        
        if !isLoadMore {
            showLottieLoader()
        }

        NetworkManager.shared.fetchDramas(from: self, page: page) { [weak self] result in
            guard let self = self else { return }

            self.isLoading = false
            self.tableView.refreshControl?.endRefreshing()

            if !isLoadMore {
                self.hideLottieLoader()
            }

            switch result {
            case .success(let response):

                if !isLoadMore {
                    self.popularDramas.removeAll()
                    self.newDramas.removeAll()
                    self.hotPicks.removeAll()
                }
                
                // Same processing code you already have ↓
                for section in response.data.data {
                    let validItems = section.list.filter {
                        ($0.dramaName?.isEmpty == false) &&
                        ($0.imageUrl?.isEmpty == false)
                    }

                    if section.heading == "Popular Dramas" {
                        self.popularDramas = validItems
                    } else if section.heading == "Coming Soon...." {
                        self.newDramas = validItems
                    } else {
                        self.hotPicks.append(contentsOf: validItems)
                    }
                }
                
                self.hasMoreData = !response.data.data.isEmpty
                if self.hasMoreData { self.currentPage = page }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.startAutoScroll()

                    if self.popularDramas.isEmpty &&
                       self.newDramas.isEmpty &&
                       self.hotPicks.isEmpty {
                        self.showEmptyState()
                    } else {
                        self.hideEmptyState()
                    }
                    
                    // ✅ ADD THIS: Fetch episodes for all dramas after loading data
                    self.fetchEpisodesForAllDramas()
                }

            case .failure(let error):
                print("Error fetching dramas: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.hideLottieLoader()
                    if self.allDramas.isEmpty { self.showEmptyState() }
                }
            }
        }
    }
    
    private func showEmptyState() {
        hideEmptyState()
        
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
        emptyView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "No dramas found"
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor)
        ])
        
        emptyView.tag = 999
        tableView.addSubview(emptyView)
    }
    
    private func hideEmptyState() {
        if let emptyView = tableView.viewWithTag(999) {
            emptyView.removeFromSuperview()
        }
    }
    
    private func fetchEpisodesForAllDramas() {
        // Combine all dramas from all sections
        let allDramas = popularDramas + newDramas + hotPicks
        
        for drama in allDramas {
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
// MARK: - --------------- Movies Parts collections All Codes ----------------
extension HomeVC {
    func setupMovieUI() {
        // Apply search bar styling for Movie mode too
        SearchBarStyle.apply(to: searchBar)
        
        // Set welcome labels for Movie mode
        welcomeLabel.text = "Welcome to".localized(LocalizationService.shared.language)
        self.appNameLabel.text = "Sora Pixo".localized(LocalizationService.shared.language)
        self.appNameLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        self.searchBar.placeholder = "Search here...".localized(LocalizationService.shared.language)
        
        welcomeLabel.font = FontManager.shared.font(for: .roboto, size: 14.0)
        appNameLabel.font = FontManager.shared.font(for: .roboto, size: 20.0)
        
        // Set up movie labels
        upcomingLbl.text = "Upcoming".localized(LocalizationService.shared.language)
        topRatedLbl.text = "Top Rated🔥".localized(LocalizationService.shared.language)
        
        viewAllUpcomingButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        viewAllTopRatedButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        
        // Set linear gradient background
        setGradientBackground()
    }
    private func applyGradienttopRatedMovieView() {
        // Remove existing gradient layer
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        
        // Create new gradient layer
        let gradient = CAGradientLayer()
        gradient.frame = topRatedMovieView.bounds
        
        // Set gradient colors
        if let color1 = UIColor(named: "Gradient1")?.cgColor,
           let color2 = UIColor(named: "Gradient2")?.cgColor {
            gradient.colors = [color1, color2]
        }
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.cornerRadius = topRatedMovieView.layer.cornerRadius
        
        // Insert at bottom-most layer
        topRatedMovieView.layer.insertSublayer(gradient, at: 0)
        
        gradientLayer = gradient
    }

    func setupMovieCollections() {
        // Setup Popular Collection (Carousel)
        let popularLayout = UICollectionViewFlowLayout()
        popularLayout.scrollDirection = .horizontal
        popularLayout.minimumLineSpacing = 20
        // FIX: Use exact width calculation to avoid edge issues
        popularLayout.itemSize = CGSize(width: popularCollection.frame.width, height: 180)
        popularLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        popularCollection.collectionViewLayout = popularLayout
        popularCollection.delegate = self
        popularCollection.dataSource = self
        popularCollection.showsHorizontalScrollIndicator = false
        popularCollection.backgroundColor = .clear
        popularCollection.isPagingEnabled = false
        popularCollection.register(UINib(nibName: "CarouselDataCell", bundle: nil), forCellWithReuseIdentifier: "CarouselDataCell")
        
        // Setup Upcoming Collection (New Movies)
        let upcomingLayout = UICollectionViewFlowLayout()
        upcomingLayout.scrollDirection = .horizontal
        upcomingLayout.itemSize = CGSize(width: 136, height: 200)
        upcomingLayout.minimumLineSpacing = 15
        upcomingLayout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        upcomingCollection.collectionViewLayout = upcomingLayout
        upcomingCollection.delegate = self
        upcomingCollection.dataSource = self
        upcomingCollection.showsHorizontalScrollIndicator = false
        upcomingCollection.backgroundColor = .clear
        upcomingCollection.register(UINib(nibName: "NewDramaCell", bundle: nil), forCellWithReuseIdentifier: "NewDramaCell")
        
        // Setup Top Rated Collection (Hot Picks)
        let topRatedLayout = UICollectionViewFlowLayout()
        topRatedLayout.scrollDirection = .vertical
        // FIX: Use dynamic item width based on collection view width
        let itemWidth = topRatedCollection.frame.width
        topRatedLayout.itemSize = CGSize(width: itemWidth, height: 120)
        topRatedLayout.minimumLineSpacing = 0
        topRatedLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        topRatedCollection.collectionViewLayout = topRatedLayout
        topRatedCollection.delegate = self
        topRatedCollection.dataSource = self
        topRatedCollection.showsVerticalScrollIndicator = false
        topRatedCollection.backgroundColor = .clear
        topRatedCollection.isScrollEnabled = false
        
        topRatedCollection.register(UINib(nibName: "HotPicDataCell", bundle: nil), forCellWithReuseIdentifier: "HotPicDataCell")
    }
    private func startPopularAutoScroll() {
        stopPopularAutoScroll()
        
        // Check if there are movies to scroll
        guard !popularMovies.isEmpty else { return }
        
        popularAutoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.popularMovies.isEmpty else { return }
            
            // Get current visible item with better bounds checking
            let visibleRect = CGRect(
                origin: self.popularCollection.contentOffset,
                size: self.popularCollection.bounds.size
            )
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            guard let currentIndexPath = self.popularCollection.indexPathForItem(at: visiblePoint) else {
                // If no current index, scroll to first item
                if !self.popularMovies.isEmpty {
                    let firstIndexPath = IndexPath(item: 0, section: 0)
                    // FIX: Check if indexPath exists before scrolling
                    if firstIndexPath.item < self.popularMovies.count {
                        // Use centeredHorizontally like CarouselTopCell
                        self.popularCollection.scrollToItem(
                            at: firstIndexPath,
                            at: .centeredHorizontally, // Changed to centeredHorizontally
                            animated: true
                        )
                    }
                }
                return
            }
            
            // Calculate next index with safe bounds checking
            var nextItem = currentIndexPath.item + 1
            // FIX: Use min function to ensure we don't go out of bounds
            let maxItems = min(self.popularMovies.count, 10)
            if nextItem >= maxItems {
                nextItem = 0
            }
            
            // FIX: Double-check bounds before scrolling
            if nextItem < maxItems {
                let nextIndexPath = IndexPath(item: nextItem, section: 0)
                // Use centeredHorizontally like CarouselTopCell
                self.popularCollection.scrollToItem(
                    at: nextIndexPath,
                    at: .centeredHorizontally, // Changed to centeredHorizontally
                    animated: true
                )
            } else {
                // Fallback to first item
                let firstIndexPath = IndexPath(item: 0, section: 0)
                if firstIndexPath.item < maxItems {
                    // Use centeredHorizontally like CarouselTopCell
                    self.popularCollection.scrollToItem(
                        at: firstIndexPath,
                        at: .centeredHorizontally,
                        animated: true
                    )
                }
            }
        }
    }
    // Stop auto-scroll for popular collection
    private func stopPopularAutoScroll() {
        popularAutoScrollTimer?.invalidate()
        popularAutoScrollTimer = nil
    }
    private func updateTopRatedCollectionHeight() {
        guard isShowDrama == "B" else { return }
        
        let itemHeight: CGFloat = 120
        let numberOfItems = min(topRatedMovies.count, 5)
        
        // Calculate total height
        let totalHeight = CGFloat(numberOfItems) * itemHeight
        
        // Update constraint
        topRatedCollectionHeightConstant.constant = totalHeight
        
        // Force layout update
        view.layoutIfNeeded()
        
        // Apply gradient after layout update
        applyGradienttopRatedMovieView()
        
        // Reload collection to ensure proper layout
        topRatedCollection.reloadData()
    }
             
    @IBAction func premiumButtonTap(_ sender: UIButton) {
        self.openPremiumVC(assignDelegate: false)
    }
    @IBAction func upcomingViewAllButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        self.navigateToMovieList(isPopular: true)
    }
    
    @IBAction func topRattedViewAllButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        self.navigateToMovieList(isPopular: false)
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource for Movie Collections
extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isShowDrama == "B" {
            if collectionView == popularCollection {
                return min(popularMovies.count, 10) // Show max 10 popular movies
            } else if collectionView == upcomingCollection {
                return min(upcomingMovies.count, 10) // Show max 10 upcoming movies
            } else if collectionView == topRatedCollection {
                return min(topRatedMovies.count, 5) // Show max 5 top rated movies
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isShowDrama == "B" {
            if collectionView == popularCollection {
                // Popular Movies Carousel
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselDataCell", for: indexPath) as! CarouselDataCell
                
                if indexPath.item < popularMovies.count {
                    let movie = popularMovies[indexPath.item]
                    cell.configurePopularMovie(with: movie)
                    cell.setOnClickListener { [weak self] in
                        // Handle movie selection - navigate to movie details
                        self?.showInterAdClick()
                        print("Selected popular movie: \(movie.title)")
                        self?.navigateToMovieDetails(movieId: movie.id)
                    }
                }
                return cell
                
            } else if collectionView == upcomingCollection {
                // Upcoming Movies (New Movies)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewDramaCell", for: indexPath) as! NewDramaCell
                
                if indexPath.item < upcomingMovies.count {
                    let movie = upcomingMovies[indexPath.item]
                    cell.configureUpcomingMovie(with: movie)
                    cell.setOnClickListener { [weak self] in
                        self?.showInterAdClick()
                        // Handle movie selection - navigate to movie details
                        print("Selected upcoming movie: \(movie.title)")
                        self?.navigateToMovieDetails(movieId: movie.id)
                    }
                }
                return cell
                
            } else if collectionView == topRatedCollection {
                // Top Rated Movies (Hot Picks)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
                
                if indexPath.item < topRatedMovies.count {
                    let movie = topRatedMovies[indexPath.item]
                    cell.parentView.backgroundColor = .clear
                    
                    let rating = (movie.voteAverage) / 2.0
                    
                    // Configure cell with gradient
                    cell.rateView.isHidden = false
                    cell.movieDescLbl.isHidden = false
                    cell.rateView.settings.totalStars = 5
                    cell.rateView.settings.starSize = 12
                    cell.rateView.settings.starMargin = 4
                    cell.rateView.settings.fillMode = .precise
                    cell.rateView.settings.updateOnTouch = false
                    
                    cell.likeCountLabel.isHidden = true
                    cell.hotePickBgImg.isHidden = true
                    cell.configureTopRatedMovie(with: movie, shouldAddGradient: false)
//                    cell.parentView.bgStartColor = .clear
//                    cell.parentView.bgEndColor = .clear
                    
                    cell.rateView.rating = rating
                    
                    cell.setOnClickListener { [weak self] in
                        self?.showInterAdClick()
                        // Handle movie selection - navigate to movie details
                        print("Selected Top Rated movie: \(movie.title)")
                        self?.navigateToMovieDetails(movieId: movie.id)
                    }
                }
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    // FIX: Add UICollectionViewDelegateFlowLayout for dynamic sizing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == topRatedCollection && isShowDrama == "B" {
            // Dynamic width for topRatedCollection
            let width = collectionView.frame.width
            return CGSize(width: width, height: 120)
        }
        
        // Return default sizes for other collections
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.itemSize
        }
        
        return CGSize(width: 100, height: 100)
    }
}
// MARK: - Movie API Calls
extension HomeVC {
    private func fetchAllMovies() {
        showLottieLoader()
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch Popular Movies
        dispatchGroup.enter()
        fetchNowPopularMovies {
            dispatchGroup.leave()
        }
        
        // Fetch Upcoming Movies
        dispatchGroup.enter()
        fetchUpcomingMovies {
            dispatchGroup.leave()
        }
        
        // Fetch Top Rated Movies
        dispatchGroup.enter()
        fetchTopRatedMovies {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.hideLottieLoader()
            self.reloadMovieCollections()
            
            // Update topRatedCollection height
            self.updateTopRatedCollectionHeight()
            
            // Start auto-scroll after loading movies
            if isShowDrama == "B" {
                self.startPopularAutoScroll()
            }
        } 
    }
    
    private func reloadMovieCollections() {
        popularCollection.reloadData()
        upcomingCollection.reloadData()
        topRatedCollection.reloadData()
    }
    
    private func fetchNowPopularMovies(completion: @escaping () -> Void) {
        NetworkManager.shared.fetchPopularMovies(from: self) { [weak self] result in
            switch result {
            case .success(let movies):
                self?.popularMovies = movies.results
                print("✅ DiscoverVC - Popular: \(movies.results.count)")
            case .failure(let error):
                print("❌ DiscoverVC - Popular error: \(error.localizedDescription)")
            }
            completion()
        }
    }
    
    private func fetchUpcomingMovies(completion: @escaping () -> Void) {
        NetworkManager.shared.fetchUpcomingMovies(from: self) { [weak self] result in
            switch result {
            case .success(let movies):
                self?.upcomingMovies = movies
                print("✅ DiscoverVC - Upcoming: \(movies.count)")
            case .failure(let error):
                print("❌ DiscoverVC - Upcoming error: \(error.localizedDescription)")
            }
            completion()
        }
    }
    
    private func fetchTopRatedMovies(completion: @escaping () -> Void) {
        NetworkManager.shared.fetchTopRatedMovies(from: self) { [weak self] result in
            switch result {
            case .success(let movies):
                self?.topRatedMovies = movies.results
                print("✅ DiscoverVC - Top Rated: \(movies.results.count)")
                // FIX: Update collection height after data is loaded
                DispatchQueue.main.async {
                    self?.updateTopRatedCollectionHeight()
                }
            case .failure(let error):
                print("❌ DiscoverVC - Top Rated error: \(error.localizedDescription)")
            }
            completion()
        }
    }
}
extension HomeVC: DismissPremium {
    func dismiss(_ isExit: Bool) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // ⏳ Small delay to allow view hierarchy to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                HelperManager.showRateScreen(navigation: self)
                self.showRateScreen()
            }
        }
    }
}

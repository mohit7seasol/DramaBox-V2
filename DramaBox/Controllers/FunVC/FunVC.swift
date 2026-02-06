//
//  FunVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 16/01/26.
//

import UIKit

class FunVC: UIViewController {
    
    @IBOutlet weak var movieTitleLbl: UILabel!
    @IBOutlet weak var movieSubTitleLbl: UILabel!
    @IBOutlet weak var quizeTitleLbl: UILabel!
    @IBOutlet weak var quizeSubTitleLbl: UILabel!
    @IBOutlet weak var spinTitleLbl: UILabel!
    @IBOutlet weak var ringtoneLbl: UILabel!
    @IBOutlet weak var spinSubTitleLbl: UILabel!
    @IBOutlet weak var wallpaperLbl: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    @IBOutlet weak var wallpapersCollectionView: UICollectionView!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    var wallpaperURLs: [String] = []
    var displayWallpaperURLs: [String] = [] // Will store only first 10 items
    
    var ringtoneCategories: RingtoneResponse = []
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        fetchRingtones()
        fetchWallpapers()
        subscribeNativeAd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func setUI() {
        setLoca()
        setCollectionView()
    }
    
    func setLoca() {
        movieTitleLbl.text = "Guess the Movie".localized(LocalizationService.shared.language)
        movieSubTitleLbl.text = "Solve clues and reveal the movie title.".localized(LocalizationService.shared.language)
        quizeTitleLbl.text = "Movie Quiz".localized(LocalizationService.shared.language)
        quizeSubTitleLbl.text = "Answer fun questions about movies and shows.".localized(LocalizationService.shared.language)
        spinTitleLbl.text = "Spin the Wheel".localized(LocalizationService.shared.language)
        spinSubTitleLbl.text = "Let the wheel choose what to watch.".localized(LocalizationService.shared.language)
        ringtoneLbl.text = "Ringtones".localized(LocalizationService.shared.language)
        wallpaperLbl.text = "Wallpaper".localized(LocalizationService.shared.language)
        viewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
    }
    
    func setCollectionView() {
        wallpapersCollectionView.dataSource = self
        wallpapersCollectionView.delegate = self
        
        // Register cell with identifier
        let nib = UINib(nibName: "WallpaperCell", bundle: nil)
        wallpapersCollectionView.register(nib, forCellWithReuseIdentifier: "WallpaperCell")
        
        // Set collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: 200, height: wallpapersCollectionView.frame.height) : CGSize(width: 150, height: 110)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        wallpapersCollectionView.collectionViewLayout = layout
        
        wallpapersCollectionView.showsHorizontalScrollIndicator = false
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
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension FunVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Display only first 10 items or total count if less than 10
        return min(displayWallpaperURLs.count, 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let wallpaperCell = collectionView.dequeueReusableCell(withReuseIdentifier: "WallpaperCell", for: indexPath) as? WallpaperCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item < displayWallpaperURLs.count {
            wallpaperCell.configure(with: displayWallpaperURLs[indexPath.item])
        }
        
        return wallpaperCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Set cell size to width: 150, height: 110
        return UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: 200, height: collectionView.frame.height) : CGSize(width: 150, height: 110)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.showInterAdClick()
        // Handle wallpaper selection if needed
        if indexPath.item < displayWallpaperURLs.count {
            let selectedWallpaperURL = displayWallpaperURLs[indexPath.item]
            print("Selected wallpaper: \(selectedWallpaperURL)")
            
            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
            if let detailsController = storyboard.instantiateViewController(withIdentifier: "ViewWallPaperVC") as? ViewWallPaperVC {
                detailsController.wallPaperStr = selectedWallpaperURL
                detailsController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(detailsController, animated: true)
            }
            
        }
    }
}

// MARK: - Api's calling
extension FunVC {
    // MARK: - Fetch Wallpapers
    func fetchWallpapers() {
        NetworkManager.shared.fetchWallpapers(from: self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let wallpapers):
                    self?.handleWallpapersResponse(wallpapers)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func handleWallpapersResponse(_ wallpapers: [String]) {
        print("Fetched \(wallpapers.count) wallpapers")
        
        // Store all wallpapers
        self.wallpaperURLs = wallpapers
        
        // Take only first 10 items for display
        self.displayWallpaperURLs = Array(wallpapers.prefix(10))
        
        // Reload collection view
        self.wallpapersCollectionView.reloadData()
        
        // Preload images for better performance
        preloadWallpaperImages()
    }
    
    private func handleError(_ error: Error) {
        print("Error: \(error.localizedDescription)")
        
        // If there's an error, you might want to show some placeholder data
        // For now, just reload with empty data
        self.displayWallpaperURLs = []
        self.wallpapersCollectionView.reloadData()
        
        // Show alert to user
        let alert = UIAlertController(title: "Error",
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // MARK: - Preload Wallpaper Images (Optional)
    private func preloadWallpaperImages() {
        // Preload first 5 wallpapers for better user experience
        let urlsToPreload = Array(displayWallpaperURLs.prefix(5))
        
        for urlString in urlsToPreload {
            NetworkManager.shared.downloadImage(from: urlString) { result in
                switch result {
                case .success(let image):
                    // Cache the image or store for later use
                    print("Preloaded image: \(urlString)")
                case .failure(let error):
                    print("Failed to preload image: \(error.localizedDescription)")
                }
            }
        }
    }
    // MARK: - Fetch Ringtones
    func fetchRingtones() {
        NetworkManager.shared.fetchRingtones(from: self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ringtoneCategories):
                    self?.handleRingtonesResponse(ringtoneCategories)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    // MARK: - Handle Ringtones Response
    private func handleRingtonesResponse(_ categories: RingtoneResponse) {
        // Process and display ringtones
        print("Fetched \(categories.count) ringtone categories")
        
        // Example: Store in local array or update UI
        self.ringtoneCategories = categories
        
        // Print categories and counts for debugging
        for category in categories {
            print("Category: \(category.category) - \(category.ringtones.count) ringtones")
        }
    }
}

// MARK: - Button Actions
extension FunVC {
    @IBAction func movieButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        // Handle movie button tap
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "QuizQuestionsVC") as? QuizQuestionsVC {
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func quizeButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        let vc = PuzzlePlayVC(nibName: "PuzzlePlayVC", bundle: nil)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func spinButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SpinMovieVC") as? SpinMovieVC {
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func ringtonsButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        // Handle ringtones button tap
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "RingtoneCategoriesVC") as? RingtoneCategoriesVC {
            vc.hidesBottomBarWhenPushed = true
            vc.ringtoneCategories = self.ringtoneCategories
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func viewAllButtonTap(_ sender: UIButton) {
        self.showInterAdClick()
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let allWallpapersController = storyboard.instantiateViewController(withIdentifier: "WallPapersVC") as? WallPapersVC {
            allWallpapersController.contentItems = self.wallpaperURLs
            allWallpapersController.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(allWallpapersController, animated: true)
        }
    }
}

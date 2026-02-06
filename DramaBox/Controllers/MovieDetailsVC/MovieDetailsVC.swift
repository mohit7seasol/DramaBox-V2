//
//  MovieDetailsVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 22/01/26.
//

import UIKit
import Cosmos
import SVProgressHUD
import SDWebImage
import SafariServices
import MarqueeLabel

class MovieDetailsVC: UIViewController {

    @IBOutlet weak var movieThumbImageView: UIImageView!
    @IBOutlet weak var movieNameLabel: UILabel!
    @IBOutlet weak var genereNameLabel: UILabel!
    @IBOutlet weak var overViewLabel: UILabel!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var reedMoreLabel: UILabel!
    @IBOutlet weak var readMoreImageView: UIImageView!
    @IBOutlet weak var posterLabel: UILabel!
    @IBOutlet weak var posterViewAllButton: UIButton!
    @IBOutlet weak var posterCollection: UICollectionView!
    @IBOutlet weak var videoTitleLabel: UILabel!
    @IBOutlet weak var videoviewAllButton: UIButton!
    @IBOutlet weak var videoCollection: UICollectionView!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var ShareButton: UIButton!
    
    @IBOutlet weak var topCastLbl: UILabel!
    @IBOutlet weak var topCastViewAllButton: UIButton!
    @IBOutlet weak var topCastCollection: UICollectionView!
    @IBOutlet weak var noDataTopCastImageView: UIImageView!
    
    @IBOutlet weak var topCrewLbl: UILabel!
    @IBOutlet weak var topCrewViewAllButton: UIButton!
    @IBOutlet weak var topCrewCollection: UICollectionView!
    @IBOutlet weak var noDataTopCrewImageView: UIImageView!
    
    @IBOutlet weak var noDataPosterImageView: UIImageView!
    @IBOutlet weak var noDataVideoImageView: UIImageView!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var shareButtonView: GradientDesignableView!
    @IBOutlet weak var shareButtonLabel: UILabel!
    
    var movieDetails: MovieDetails?
    var tvShowDetails: TVShowDetails?
    var isShowingMovies: Bool = true
    
    private var isExpanded = false
    var movieId: Int?
    var tvShowId: Int?
    
    // Store both movie and TV credits separately
    private var movieCast: [MovieCast] = []
    private var movieCrew: [MovieCrew] = []
    private var tvCast: [TVCast] = []
    private var tvCrew: [TVCrew] = []
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupReadMore()
        loadData()
    }
    
    private func loadData() {
        if isShowingMovies {
            if let movieId = movieId {
                fetchMovieDetails(movieId: movieId)
            }
        } else {
            if let tvShowId = tvShowId {
                fetchTVDetails(seriesId: tvShowId)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 1. Ensure scroll view content starts from top
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        rateView.setNeedsLayout()
        rateView.layoutIfNeeded()
        
        // Invalidate collection view layouts
        topCastCollection.collectionViewLayout.invalidateLayout()
        topCrewCollection.collectionViewLayout.invalidateLayout()
    }
    
    func setUI() {
        // 1. Remove scroll view top space
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        setColelcetionView()
        setupLabels()
        subscribeNativeAd()
        
        // Set default image for thumb
        movieThumbImageView.image = UIImage(named: "hoteDefault")
        rateView.settings.updateOnTouch = false
        
        rateView.settings.totalStars = 5
        rateView.settings.starMargin = 4
        rateView.settings.fillMode = .precise
        rateView.settings.updateOnTouch = false

        // 2) Hide no data images initially
        noDataPosterImageView.isHidden = true
        noDataVideoImageView.isHidden = true
        noDataTopCastImageView.isHidden = true
        noDataTopCrewImageView.isHidden = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
    
    func setupLabels() {
        // Localize labels
        posterLabel.text = "Poster".localized(LocalizationService.shared.language)
        videoTitleLabel.text = "Video".localized(LocalizationService.shared.language)
        posterViewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        videoviewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        
        // 1) Set cast and crew labels
        topCastLbl.text = "Top Cast".localized(LocalizationService.shared.language)
        topCrewLbl.text = "Top Crew".localized(LocalizationService.shared.language)
        topCastViewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        topCrewViewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        
        // Set read more initial state
        reedMoreLabel.text = "Read More".localized(LocalizationService.shared.language)
        shareButtonLabel.text = "Share".localized(LocalizationService.shared.language)
        shareButtonView.cornerRadius = shareButtonView.frame.height / 2
        
        readMoreImageView.image = UIImage(named: "down_arrow")
        
        // Set initial overview label properties
        overViewLabel.numberOfLines = 4
        overViewLabel.lineBreakMode = .byTruncatingTail
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
    
    func setupReadMore() {
        // Set initial state
        updateReadMoreUI()
    }
    
    private func updateReadMoreUI() {
        overViewLabel.numberOfLines = isExpanded ? 0 : 4
        
        if isExpanded {
            reedMoreLabel.text = "Read Less".localized(LocalizationService.shared.language)
            readMoreImageView.image = UIImage(named: "up_arrow")
        } else {
            reedMoreLabel.text = "Read More".localized(LocalizationService.shared.language)
            readMoreImageView.image = UIImage(named: "down_arrow")
        }
    }
    
    func setColelcetionView() {
        // Setup Poster Collection
        let posterLayout = UICollectionViewFlowLayout()
        posterLayout.scrollDirection = .horizontal
        posterLayout.minimumLineSpacing = 10
        posterLayout.minimumInteritemSpacing = 10
        let posterCellWidth = posterCollection.frame.width / 2.4
        posterLayout.itemSize = CGSize(width: posterCellWidth, height: 170)
        posterLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        posterCollection.collectionViewLayout = posterLayout
        posterCollection.delegate = self
        posterCollection.dataSource = self
        posterCollection.showsHorizontalScrollIndicator = false
        posterCollection.backgroundColor = .clear
        posterCollection.register(UINib(nibName: "MovieYoutubeVideoCell", bundle: nil), forCellWithReuseIdentifier: "MovieYoutubeVideoCell")
        
        // Setup Video Collection
        let videoLayout = UICollectionViewFlowLayout()
        videoLayout.scrollDirection = .horizontal
        videoLayout.minimumLineSpacing = 10
        videoLayout.minimumInteritemSpacing = 10
        videoLayout.itemSize = CGSize(width: 230, height: 150)
        videoLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        videoCollection.collectionViewLayout = videoLayout
        videoCollection.delegate = self
        videoCollection.dataSource = self
        videoCollection.showsHorizontalScrollIndicator = false
        videoCollection.backgroundColor = .clear
        videoCollection.register(UINib(nibName: "MovieYoutubeVideoCell", bundle: nil), forCellWithReuseIdentifier: "MovieYoutubeVideoCell")
        
        // 1) Setup Top Cast Collection
        topCastCollection.delegate = self
        topCastCollection.dataSource = self
        topCastCollection.showsHorizontalScrollIndicator = false
        topCastCollection.backgroundColor = .clear
        topCastCollection.register(UINib(nibName: "TopCastAndCrewCell", bundle: nil), forCellWithReuseIdentifier: "TopCastAndCrewCell")
        
        // 1) Setup Top Crew Collection
        topCrewCollection.delegate = self
        topCrewCollection.dataSource = self
        topCrewCollection.showsHorizontalScrollIndicator = false
        topCrewCollection.backgroundColor = .clear
        topCrewCollection.register(UINib(nibName: "TopCastAndCrewCell", bundle: nil), forCellWithReuseIdentifier: "TopCastAndCrewCell")
    }
    
    private func updateUI() {
        if isShowingMovies {
            updateMovieUI()
        } else {
            updateTVShowUI()
        }
        
        // Reload collections
        posterCollection.reloadData()
        videoCollection.reloadData()
    }
    
    private func updateMovieUI() {
        guard let movieDetails = movieDetails else { return }
        
        // Set movie thumb image with default fallback
        if let backdropPath = movieDetails.backdropPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath)") {
            movieThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
        }
        
        // Set movie name
        movieNameLabel.text = movieDetails.title
        
        // Set genres
        let genres = movieDetails.genres.prefix(3).map { $0.name }.joined(separator: ", ")
        genereNameLabel.text = genres
        
        // Set overview
        overViewLabel.text = movieDetails.overview
        
        // Set rating
        DispatchQueue.main.async {
            let rating = (movieDetails.voteAverage) / 2.0
            self.rateView.rating = rating
        }
        
        // 2) Check and update visibility for posters
        let hasPosters = movieDetails.images?.posters.count ?? 0 > 0
        posterCollection.isHidden = !hasPosters
        noDataPosterImageView.isHidden = hasPosters
        posterViewAllButton.isHidden = !hasPosters
        
        // 2) Check and update visibility for videos
        let hasVideos = movieDetails.videos?.results.count ?? 0 > 0
        videoCollection.isHidden = !hasVideos
        noDataVideoImageView.isHidden = hasVideos
        videoviewAllButton.isHidden = !hasVideos
        
        // 1) Fetch movie credits
        if let movieId = movieId {
            fetchMovieCredits(movieId: movieId)
        }
    }
    
    private func updateTVShowUI() {
        guard let tvShowDetails = tvShowDetails else { return }
        
        // Set TV show thumb image with default fallback
        if let backdropPath = tvShowDetails.backdropPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w500\(backdropPath)") {
            movieThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
        }
        
        // Set TV show name
        movieNameLabel.text = tvShowDetails.name
        
        // Set genres
        let genres = tvShowDetails.genres.prefix(3).map { $0.name }.joined(separator: ", ")
        genereNameLabel.text = genres
        
        // Set overview
        overViewLabel.text = tvShowDetails.overview
        
        // Set rating
        DispatchQueue.main.async {
            let rating = (tvShowDetails.voteAverage ?? 0) / 2.0
            self.rateView.rating = rating
        }
        
        // 2) Check and update visibility for posters (using backdrop images)
        let hasPosters = false // TV shows don't have posters in the same way
        posterCollection.isHidden = true // Hide poster collection for TV shows
        noDataPosterImageView.isHidden = false
        posterViewAllButton.isHidden = true
        
        // 2) Check and update visibility for videos
        let hasVideos = tvShowDetails.videos?.results.count ?? 0 > 0
        videoCollection.isHidden = !hasVideos
        noDataVideoImageView.isHidden = hasVideos
        videoviewAllButton.isHidden = !hasVideos
        
        // Fetch TV show credits
        if let tvShowId = tvShowId {
            fetchTVCredits(seriesId: tvShowId)
        }
    }
    
    // 1) Fetch movie credits API
    private func fetchMovieCredits(movieId: Int) {
        SVProgressHUD.show()
        NetworkManager.shared.fetchMovieCredits(movieId: movieId) { [weak self] result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let creditsResponse):
                self?.movieCast = creditsResponse.cast
                self?.movieCrew = creditsResponse.crew
                
                DispatchQueue.main.async {
                    // Reload collections
                    self?.topCastCollection.reloadData()
                    self?.topCrewCollection.reloadData()
                    
                    // 2) Check and update visibility for cast
                    let hasCast = !(self?.movieCast.isEmpty ?? true)
                    self?.topCastCollection.isHidden = !hasCast
                    self?.noDataTopCastImageView.isHidden = hasCast
                    self?.topCastViewAllButton.isHidden = !hasCast
                    
                    // 2) Check and update visibility for crew
                    let hasCrew = !(self?.movieCrew.isEmpty ?? true)
                    self?.topCrewCollection.isHidden = !hasCrew
                    self?.noDataTopCrewImageView.isHidden = hasCrew
                    self?.topCrewViewAllButton.isHidden = !hasCrew
                }
                
            case .failure(let error):
                print("Error fetching movie credits: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    // 2) Hide collections if no data
                    self?.topCastCollection.isHidden = true
                    self?.noDataTopCastImageView.isHidden = false
                    self?.topCastViewAllButton.isHidden = true
                    
                    self?.topCrewCollection.isHidden = true
                    self?.noDataTopCrewImageView.isHidden = false
                    self?.topCrewViewAllButton.isHidden = true
                }
            }
        }
    }
    
    // 2) Fetch TV show credits API - WITHOUT converting models
    private func fetchTVCredits(seriesId: Int) {
        SVProgressHUD.show()
        NetworkManager.shared.fetchTVCredits(tvId: seriesId) { [weak self] result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let creditsResponse):
                // Store TV credits in their original format
                self?.tvCast = creditsResponse.cast
                self?.tvCrew = creditsResponse.crew
                
                DispatchQueue.main.async {
                    // Reload collections
                    self?.topCastCollection.reloadData()
                    self?.topCrewCollection.reloadData()
                    
                    // 2) Check and update visibility for cast
                    let hasCast = !(self?.tvCast.isEmpty ?? true)
                    self?.topCastCollection.isHidden = !hasCast
                    self?.noDataTopCastImageView.isHidden = hasCast
                    self?.topCastViewAllButton.isHidden = !hasCast
                    
                    // 2) Check and update visibility for crew
                    let hasCrew = !(self?.tvCrew.isEmpty ?? true)
                    self?.topCrewCollection.isHidden = !hasCrew
                    self?.noDataTopCrewImageView.isHidden = hasCrew
                    self?.topCrewViewAllButton.isHidden = !hasCrew
                }
                
            case .failure(let error):
                print("Error fetching TV credits: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    // 2) Hide collections if no data
                    self?.topCastCollection.isHidden = true
                    self?.noDataTopCastImageView.isHidden = false
                    self?.topCastViewAllButton.isHidden = true
                    
                    self?.topCrewCollection.isHidden = true
                    self?.noDataTopCrewImageView.isHidden = false
                    self?.topCrewViewAllButton.isHidden = true
                }
            }
        }
    }
    
    private func openTopCastAndCrewListVC(isCast: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let listVC = storyboard.instantiateViewController(withIdentifier: "TopCastAndCrewListVC") as? TopCastAndCrewListVC {
            
            if isShowingMovies {
                if isCast {
                    // Pass movie cast data
                    listVC.dataType = .cast
                    listVC.castData = movieCast
                    listVC.screenTitle = "Top Cast"
                } else {
                    // Pass movie crew data
                    listVC.dataType = .crew
                    listVC.crewData = movieCrew
                    listVC.screenTitle = "Top Crew"
                }
                listVC.movieTitle = movieDetails?.title ?? "Movie"
            } else {
                // For TV shows, we need to check if your TopCastAndCrewListVC supports TV models
                // If not, you might need to convert or create a separate TV version
                print("⚠️ TV show cast/crew list not implemented yet")
                return
            }
            
            listVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(listVC, animated: true)
        }
    }
    
    @IBAction func viewAllTopCastButtonTap(_ sender: UIButton) {
        openTopCastAndCrewListVC(isCast: true)
    }
    
    @IBAction func viewAllTopCrewButtonTap(_ sender: UIButton) {
        openTopCastAndCrewListVC(isCast: false)
    }
    
    @IBAction func readMoreButton(_ sender: UIButton) {
        isExpanded.toggle()
        updateReadMoreUI()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        if isShowingMovies {
            if let trailer = self.movieDetails?.videos?.results.first(where: {
                $0.type == "Trailer" && $0.site == "YouTube"
            }) {
                self.openYouTube(videoKey: trailer.key)
            } else {
                print("⚠️ No YouTube trailer found.")
                SVProgressHUD.showError(withStatus: "⚠️ No YouTube trailer found.")
            }
        } else {
            if let trailer = self.tvShowDetails?.videos?.results.first(where: {
                $0.type == "Trailer" && $0.site == "YouTube"
            }) {
                self.openYouTube(videoKey: trailer.key)
            } else {
                print("⚠️ No YouTube trailer found.")
                SVProgressHUD.showError(withStatus: "⚠️ No YouTube trailer found.")
            }
        }
    }
    
    @IBAction func viewAllPosterButtonAction(_ sender: UIButton) {
        self.openPosterDetailsVC(isOpenPoster: true)
    }
    
    
    @IBAction func viewAllVideoButtonAction(_ sender: UIButton) {
        self.openPosterDetailsVC(isOpenPoster: false)
    }
    
    @IBAction func shareButtonTap(_ sender: UIButton) {
        if isShowingMovies {
            if let trailer = self.movieDetails?.videos?.results.first(where: {
                $0.type == "Trailer" && $0.site == "YouTube"
            }) {
                self.shareYoutubeVideo(for: self.movieDetails, from: self)
            } else {
                print("No Youtube Trailer Found")
            }
        } else {
            if let trailer = self.tvShowDetails?.videos?.results.first(where: {
                $0.type == "Trailer" && $0.site == "YouTube"
            }) {
                self.shareYoutubeVideo(forTV: self.tvShowDetails, from: self)
            } else {
                print("No Youtube Trailer Found")
            }
        }
    }
    
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        self.scrollView.setNeedsLayout()
        self.scrollView.layoutIfNeeded()
    }
    
    func shareYoutubeVideo(for movie: MovieDetails?, from vc: UIViewController) {
        guard let movie = movie else {
            print("⚠️ Movie details not found.")
            return
        }
        
        // --- Find YouTube trailer link ---
        guard let trailerKey = movie.videos?.results.first(where: {
            $0.type.lowercased().contains("trailer") && $0.site.lowercased() == "youtube"
        })?.key, !trailerKey.isEmpty else {
            print("⚠️ No valid YouTube key found for sharing.")
            return
        }
        
        let trailerURLString = "https://www.youtube.com/watch?v=\(trailerKey)"
        guard let trailerURL = URL(string: trailerURLString) else { return }
        
        // --- Text content (will show URL preview) ---
        let shareText = """
        🎬 Check out this movie: \(movie.title)
        
        🎭 Movie: \(movie.title)
        \(movie.overview.isEmpty ? "" : "📖 Overview: \(movie.overview)\n")
        ⭐ Rating: \(String(format: "%.1f", movie.voteAverage))/10
        📅 Release Date: \(movie.releaseDate ?? "TBA")
        """
        
        // --- Create three separate items ---
        var itemsToShare: [Any] = []
        
        // 1st item: Text with movie info (will show URL preview)
        itemsToShare.append(shareText)
        itemsToShare.append(trailerURL) // This will create URL preview
        
        // --- Fetch poster image from images.posters ---
        if let posters = movie.images?.posters, let firstPoster = posters.first {
            let posterURLString = "https://image.tmdb.org/t/p/w500\(firstPoster.filePath)"
            guard let posterURL = URL(string: posterURLString) else {
                // If poster URL fails, share text and trailer only
                DispatchQueue.main.async {
                    self.presentShareSheetYoutube(from: vc, with: itemsToShare)
                }
                return
            }
            
            print("🖼️ Fetching poster from: \(posterURLString)")
            
            URLSession.shared.dataTask(with: posterURL) { data, response, error in
                var finalItems: [Any] = []
                
                // 1st: Text with URL preview
                finalItems.append(shareText)
                finalItems.append(trailerURL)
                
                // 2nd: Poster as separate image
                if let data = data, let image = UIImage(data: data) {
                    print("✅ Successfully loaded poster image")
                    finalItems.append(image)
                } else {
                    print("⚠️ Could not convert data to image")
                }
                
                // 3rd: Trailer URL again as separate item (will show YouTube thumb)
                finalItems.append(trailerURL)
                
                DispatchQueue.main.async {
                    self.presentShareSheetYoutube(from: vc, with: finalItems)
                }
            }.resume()
        } else {
            // Fallback to posterPath if images.posters is not available
            if let posterPath = movie.posterPath {
                let posterURLString = "https://image.tmdb.org/t/p/w500\(posterPath)"
                guard let posterURL = URL(string: posterURLString) else {
                    DispatchQueue.main.async {
                        self.presentShareSheetYoutube(from: vc, with: itemsToShare)
                    }
                    return
                }
                
                URLSession.shared.dataTask(with: posterURL) { data, _, _ in
                    var finalItems: [Any] = []
                    
                    // 1st: Text with URL preview
                    finalItems.append(shareText)
                    finalItems.append(trailerURL)
                    
                    // 2nd: Poster as separate image
                    if let data = data, let image = UIImage(data: data) {
                        finalItems.append(image)
                    }
                    
                    // 3rd: Trailer URL again as separate item
                    finalItems.append(trailerURL)
                    
                    DispatchQueue.main.async {
                        self.presentShareSheetYoutube(from: vc, with: finalItems)
                    }
                }.resume()
            } else {
                // No poster available — share text and trailer only
                print("⚠️ No poster images found")
                // Add trailer URL twice to ensure it appears as separate item
                itemsToShare.append(trailerURL)
                DispatchQueue.main.async {
                    self.presentShareSheetYoutube(from: vc, with: itemsToShare)
                }
            }
        }
    }
    
    func shareYoutubeVideo(forTV tvShow: TVShowDetails?, from vc: UIViewController) {
        guard let tvShow = tvShow else {
            print("⚠️ TV show details not found.")
            return
        }
        
        // --- Find YouTube trailer link ---
        guard let trailerKey = tvShow.videos?.results.first(where: {
            $0.type.lowercased().contains("trailer") && $0.site.lowercased() == "youtube"
        })?.key, !trailerKey.isEmpty else {
            print("⚠️ No valid YouTube key found for sharing.")
            return
        }
        
        let trailerURLString = "https://www.youtube.com/watch?v=\(trailerKey)"
        guard let trailerURL = URL(string: trailerURLString) else { return }
        
        // --- Text content (will show URL preview) ---
        let shareText = """
        📺 Check out this TV show: \(tvShow.name)
        
        🎭 TV Show: \(tvShow.name)
        \(tvShow.overview.isEmpty ? "" : "📖 Overview: \(tvShow.overview)\n")
        ⭐ Rating: \(String(format: "%.1f", tvShow.voteAverage ?? 0))/10
        📅 First Air Date: \(tvShow.firstAirDate ?? "TBA")
        """
        
        // --- Create three separate items ---
        var itemsToShare: [Any] = []
        
        // 1st item: Text with TV show info (will show URL preview)
        itemsToShare.append(shareText)
        itemsToShare.append(trailerURL) // This will create URL preview
        
        // --- Fetch poster image ---
        if let posterPath = tvShow.posterPath {
            let posterURLString = "https://image.tmdb.org/t/p/w500\(posterPath)"
            guard let posterURL = URL(string: posterURLString) else {
                DispatchQueue.main.async {
                    self.presentShareSheetYoutube(from: vc, with: itemsToShare)
                }
                return
            }
            
            URLSession.shared.dataTask(with: posterURL) { data, _, _ in
                var finalItems: [Any] = []
                
                // 1st: Text with URL preview
                finalItems.append(shareText)
                finalItems.append(trailerURL)
                
                // 2nd: Poster as separate image
                if let data = data, let image = UIImage(data: data) {
                    finalItems.append(image)
                }
                
                // 3rd: Trailer URL again as separate item
                finalItems.append(trailerURL)
                
                DispatchQueue.main.async {
                    self.presentShareSheetYoutube(from: vc, with: finalItems)
                }
            }.resume()
        } else {
            // No poster available — share text and trailer only
            print("⚠️ No poster images found")
            // Add trailer URL twice to ensure it appears as separate item
            itemsToShare.append(trailerURL)
            DispatchQueue.main.async {
                self.presentShareSheetYoutube(from: vc, with: itemsToShare)
            }
        }
    }
    
    private func presentShareSheetYoutube(from vc: UIViewController, with items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad support
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = vc.view
            popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        vc.present(activityVC, animated: true)
    }
}

// MARK: - UICollectionView Extension
extension MovieDetailsVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == posterCollection {
            if isShowingMovies {
                return min(movieDetails?.images?.posters.count ?? 0, 10)
            } else {
                return 0 // TV shows don't have posters in the same way
            }
        } else if collectionView == videoCollection {
            if isShowingMovies {
                return min(movieDetails?.videos?.results.count ?? 0, 10)
            } else {
                return min(tvShowDetails?.videos?.results.count ?? 0, 10)
            }
        } else if collectionView == topCastCollection {
            if isShowingMovies {
                return min(movieCast.count, 10)
            } else {
                return min(tvCast.count, 10)
            }
        } else if collectionView == topCrewCollection {
            if isShowingMovies {
                return min(movieCrew.count, 10)
            } else {
                return min(tvCrew.count, 10)
            }
        }

        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == posterCollection || collectionView == videoCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieYoutubeVideoCell", for: indexPath) as! MovieYoutubeVideoCell
            
            if collectionView == posterCollection && isShowingMovies {
                // Configure for movie posters
                if let posters = movieDetails?.images?.posters,
                   indexPath.item < posters.count {
                    let poster = posters[indexPath.item]
                    let imageUrl = "https://image.tmdb.org/t/p/w500\(poster.filePath)"
                    if let url = URL(string: imageUrl) {
                        cell.videoThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
                    }
                }
                cell.playButton.isHidden = true
                
                cell.setOnClickListener {
                    self.openPosterDetailsVC(startingIndex: indexPath.item)
                }
                
            } else if collectionView == videoCollection {
                // Configure for videos (both movie and TV)
                var video: Video?
                
                if isShowingMovies {
                    if let videos = movieDetails?.videos?.results,
                       indexPath.item < videos.count {
                        video = videos[indexPath.item]
                    }
                } else {
                    if let videos = tvShowDetails?.videos?.results,
                       indexPath.item < videos.count {
                        video = videos[indexPath.item]
                    }
                }
                
                if let video = video {
                    let youtubeThumbUrl = "https://img.youtube.com/vi/\(video.key)/0.jpg"
                    if let url = URL(string: youtubeThumbUrl) {
                        cell.videoThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
                    }
                    cell.playButton.setOnClickListener {
                        self.openYouTube(videoKey: video.key)
                    }
                }
                cell.playButton.isHidden = false
            }
            
            return cell
            
        } else if collectionView == topCastCollection || collectionView == topCrewCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopCastAndCrewCell", for: indexPath) as! TopCastAndCrewCell
            
            if collectionView == topCastCollection {
                if isShowingMovies {
                    // Configure for movie cast
                    if indexPath.item < movieCast.count {
                        let castMember = movieCast[indexPath.item]
                        configureMovieCastCell(cell: cell, castMember: castMember)
                    }
                } else {
                    // Configure for TV cast
                    if indexPath.item < tvCast.count {
                        let castMember = tvCast[indexPath.item]
                        configureTVCastCell(cell: cell, castMember: castMember)
                    }
                }
            } else if collectionView == topCrewCollection {
                if isShowingMovies {
                    // Configure for movie crew
                    if indexPath.item < movieCrew.count {
                        let crewMember = movieCrew[indexPath.item]
                        configureMovieCrewCell(cell: cell, crewMember: crewMember)
                    }
                } else {
                    // Configure for TV crew
                    if indexPath.item < tvCrew.count {
                        let crewMember = tvCrew[indexPath.item]
                        configureTVCrewCell(cell: cell, crewMember: crewMember)
                    }
                }
            }
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    private func configureMovieCastCell(cell: TopCastAndCrewCell, castMember: MovieCast) {
        // Set cast member image
        if let profilePath = castMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        
        // Set cast member name with marquee
        cell.nameLabel.text = castMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set character/role
        if let character = castMember.character {
            cell.designationLabel.text = character
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Actor/Actress"
        }
        
        cell.setOnClickListener {
            self.navigateToCelebrityDetails(personId: castMember.id)
        }
    }
    
    private func configureTVCastCell(cell: TopCastAndCrewCell, castMember: TVCast) {
        // Set cast member image
        if let profilePath = castMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        
        // Set cast member name with marquee
        cell.nameLabel.text = castMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set character/role
        if let character = castMember.character {
            cell.designationLabel.text = character
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Actor/Actress"
        }
        
        cell.setOnClickListener {
            self.navigateToCelebrityDetails(personId: castMember.id)
        }
    }
    
    private func configureMovieCrewCell(cell: TopCastAndCrewCell, crewMember: MovieCrew) {
        // Set crew member image
        if let profilePath = crewMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        
        // Set crew member name with marquee
        cell.nameLabel.text = crewMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set department and job
        if let job = crewMember.job {
            cell.designationLabel.text = job
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else if let department = crewMember.department {
            cell.designationLabel.text = department
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Crew Member"
        }
        
        cell.setOnClickListener {
            self.navigateToCelebrityDetails(personId: crewMember.id)
        }
    }
    
    private func configureTVCrewCell(cell: TopCastAndCrewCell, crewMember: TVCrew) {
        // Set crew member image
        if let profilePath = crewMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        
        // Set crew member name with marquee
        cell.nameLabel.text = crewMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set department and job
        if let job = crewMember.job {
            cell.designationLabel.text = job
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else if let department = crewMember.department {
            cell.designationLabel.text = department
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Crew Member"
        }
        
        cell.setOnClickListener {
            self.navigateToCelebrityDetails(personId: crewMember.id)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 1) Set sizes for top cast and crew collections
        if collectionView == topCastCollection || collectionView == topCrewCollection {
            let collectionWidth = collectionView.frame.width
            let cellWidth = collectionWidth / 3.4
            
            // Check if device is iPad
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            let cellHeight: CGFloat = isiPad ? 150 : 120
            
            return CGSize(width: cellWidth, height: cellHeight)
        }
        
        // Return default sizes for other collections
        if collectionView == posterCollection {
            let posterCellWidth = posterCollection.frame.width / 2.4
            return CGSize(width: posterCellWidth, height: 170)
        } else if collectionView == videoCollection {
            return CGSize(width: 230, height: 150)
        }
        
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        // 1) Set insets for top cast and crew collections
        if collectionView == topCastCollection || collectionView == topCrewCollection {
            return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 10)
        }
        
        // Return default insets for other collections
        if collectionView == posterCollection {
            return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        } else if collectionView == videoCollection {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == videoCollection {
            var videos: [Video] = []
            
            if isShowingMovies {
                videos = movieDetails?.videos?.results ?? []
            } else {
                videos = tvShowDetails?.videos?.results ?? []
            }
            
            if indexPath.item < videos.count {
                let video = videos[indexPath.item]
                self.openYouTube(videoKey: video.key)
            }
        }
    }
    
    // ✅ Linear effect like FSPagerView for video collection
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == videoCollection {
            let centerX = scrollView.contentOffset.x + (videoCollection.bounds.width / 2)
            
            for cell in videoCollection.visibleCells {
                let basePosition = cell.center.x
                let distance = abs(centerX - basePosition)
                let normalized = distance / (videoCollection.bounds.width / 2)
                let scale = max(0.85, 1 - normalized * 0.15)
                
                cell.transform = CGAffineTransform(scaleX: scale, y: scale)
                cell.alpha = scale
            }
        }
    }
    
    func openYouTube(videoKey: String) {
        let url = URL(string: "https://www.youtube.com/watch?v=\(videoKey)")!
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        self.present(safariVC, animated: true)
    }
    
    private func openPosterDetailsVC(isOpenPoster: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let posterListVC = storyboard.instantiateViewController(withIdentifier: "PosterListVC") as? PosterListVC {
            
            if isOpenPoster && isShowingMovies {
                // Pass movie posters data
                guard let posters = movieDetails?.images?.posters, !posters.isEmpty else { return }
                posterListVC.posters = posters
                posterListVC.isPoster = true
            } else if !isOpenPoster {
                // Pass videos data
                var videos: [Video] = []
                if isShowingMovies {
                    videos = movieDetails?.videos?.results ?? []
                } else {
                    videos = tvShowDetails?.videos?.results ?? []
                }
                
                guard !videos.isEmpty else { return }
                posterListVC.videos = videos
                posterListVC.isPoster = false
            }
            
            posterListVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(posterListVC, animated: true)
        }
    }
    
    private func openPosterDetailsVC(startingIndex: Int) {
        guard let posters = movieDetails?.images?.posters, !posters.isEmpty else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let posterDetailsVC = storyboard.instantiateViewController(withIdentifier: "PosterDetailsVC") as? PosterDetailsVC {
            posterDetailsVC.posters = posters
            posterDetailsVC.currentIndex = startingIndex
            posterDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(posterDetailsVC, animated: true)
        }
    }
    
    private func navigateToCelebrityDetails(personId: Int) {
        // 1. Get reference to CelebrityDetailsVC from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let celebrityDetailsVC = storyboard.instantiateViewController(withIdentifier: "CelebrityDetailsVC") as? CelebrityDetailsVC else {
            print("❌ Failed to instantiate CelebrityDetailsVC")
            return
        }
        
        // 2. Configure the VC with person ID
        celebrityDetailsVC.configure(with: personId)
        
        // 3. Push to navigation controller
        self.navigationController?.pushViewController(celebrityDetailsVC, animated: true)
    }
}

// MARK: - API's Calling
extension MovieDetailsVC {
    func fetchMovieDetails(movieId: Int) {
        self.movieId = movieId
        SVProgressHUD.show()
        NetworkManager.shared.fetchMovieDetails(movieId: movieId) { [weak self] result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let movieDetails):
                self?.movieDetails = movieDetails
                DispatchQueue.main.async {
                    self?.updateUI()
                }
                print("Fetched Movie: \(movieDetails.title)")
            case .failure(let error):
                print("Error fetching movie details: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchTVDetails(seriesId: Int) {
        self.tvShowId = seriesId
        SVProgressHUD.show()
        NetworkManager.shared.fetchTVDetails(seriesId: seriesId) { [weak self] result in
            SVProgressHUD.dismiss()
            switch result {
            case .success(let tvShowDetails):
                self?.tvShowDetails = tvShowDetails
                DispatchQueue.main.async {
                    self?.updateUI()
                }
                print("Fetched TV Show: \(tvShowDetails.name)")
            case .failure(let error):
                print("Error fetching tv details: \(error.localizedDescription)")
            }
        }
    }
}

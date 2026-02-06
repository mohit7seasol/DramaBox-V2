//
//  MovieListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 22/01/26.
//

import UIKit
import SVProgressHUD
import Cosmos

class MovieListVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var popularMovies: [Movie] = []
    private var topRatedMovies: [Movie] = []
    private var popularCurrentPage: Int = 1
    private var topRatedCurrentPage: Int = 1
    private var isLoading: Bool = false
    private var popularHasMoreData: Bool = true
    private var topRatedHasMoreData: Bool = true
    private var popularTotalPages: Int = 1
    private var topRatedTotalPages: Int = 1
    
    var isPopular: Bool = true {
        didSet {
            if isViewLoaded {
                setupCollectionViewLayout()
                collectionView.reloadData()
                if isPopular && popularMovies.isEmpty {
                    fetchPopularMovies()
                } else if !isPopular && topRatedMovies.isEmpty {
                    fetchTopRatedMovies()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupCollectionViewLayout()
        fetchMovies()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        
        // Register cells
        let newDramaNib = UINib(nibName: "NewDramaCell", bundle: nil)
        collectionView.register(newDramaNib, forCellWithReuseIdentifier: "NewDramaCell")
        
        let hotPicksNib = UINib(nibName: "HotPicDataCell", bundle: nil)
        collectionView.register(hotPicksNib, forCellWithReuseIdentifier: "HotPicDataCell")
    }
    
    private func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        if isPopular {
            // 2x2 grid for popular movies with 10pt spacing all around
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            self.titleLabel.text = "Upcoming".localized(LocalizationService.shared.language)
        } else {
            // Single column for top rated movies with no spacing
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.titleLabel.text = "Top Rated".localized(LocalizationService.shared.language)
        }
        
        collectionView.collectionViewLayout = layout
        collectionView.reloadData()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - UICollectionView DataSource & Delegate
extension MovieListVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isPopular {
            return popularMovies.count
        } else {
            return topRatedMovies.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isPopular {
            // Configure NewDramaCell for popular movies
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewDramaCell", for: indexPath) as! NewDramaCell
            if indexPath.item < popularMovies.count {
                let movie = popularMovies[indexPath.item]
                cell.configureUpcomingMovie(with: movie)
            }
            return cell
        } else {
            // Configure HotPicDataCell for top rated movies
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
            if indexPath.item < topRatedMovies.count {
                let movie = topRatedMovies[indexPath.item]
                
                cell.rateView.isHidden = false
                cell.movieDescLbl.isHidden = false
                cell.rateView.settings.totalStars = 5
                cell.rateView.settings.starSize = 12
                cell.rateView.settings.starMargin = 4
                cell.rateView.settings.fillMode = .precise
                cell.rateView.settings.updateOnTouch = false
                
                cell.likeCountLabel.isHidden = true
                cell.hotePickBgImg.isHidden = true
                
                cell.configureTopRatedMovie(with: movie, shouldAddGradient: true)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isPopular {
            // 2x2 grid layout - calculate width for 2 columns with 10pt spacing
            let totalSpacing: CGFloat = (10 * 3) // left + right + between columns
            let collectionWidth = collectionView.frame.width - totalSpacing
            let itemWidth = collectionWidth / 2
            
            // Maintain aspect ratio similar to NewDramaCell (136x200 = 0.68)
            let itemHeight = itemWidth * (200/136)
            
            return CGSize(width: itemWidth, height: itemHeight)
        } else {
            // Single column full width layout like HotPicks
            let collectionViewWidth = collectionView.frame.width
            return CGSize(width: collectionViewWidth, height: 120)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie: Movie
        if isPopular {
            guard indexPath.item < popularMovies.count else { return }
            movie = popularMovies[indexPath.item]
        } else {
            guard indexPath.item < topRatedMovies.count else { return }
            movie = topRatedMovies[indexPath.item]
        }
        
        // Open movie details
        openMovieDetails(for: movie)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Load more data when reaching bottom
        if offsetY > contentHeight - screenHeight - 100 {
            loadMoreData()
        }
    }
    
    private func openMovieDetails(for movie: Movie) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let movieDetailsVC = storyboard.instantiateViewController(withIdentifier: "MovieDetailsVC") as? MovieDetailsVC {
            movieDetailsVC.movieId = movie.id
            movieDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(movieDetailsVC, animated: true)
        }
    }
    
    private func loadMoreData() {
        guard !isLoading else { return }
        
        if isPopular {
            guard popularHasMoreData else { return }
            fetchPopularMovies(page: popularCurrentPage + 1)
        } else {
            guard topRatedHasMoreData else { return }
            fetchTopRatedMovies(page: topRatedCurrentPage + 1)
        }
    }
}

// MARK: - Movie API Calls
extension MovieListVC {
    private func fetchMovies() {
        if isPopular {
            fetchPopularMovies()
        } else {
            fetchTopRatedMovies()
        }
    }
    
    private func reloadMovieCollections() {
        collectionView.reloadData()
    }
    
    private func fetchPopularMovies(page: Int = 1) {
        guard !isLoading else { return }
        
        isLoading = true
        SVProgressHUD.show()
        
        NetworkManager.shared.fetchPopularMovies(from: self, page: page) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            SVProgressHUD.dismiss()
            
            switch result {
            case .success(let movieResponse):
                if page == 1 {
                    self.popularMovies = movieResponse.results
                    self.popularCurrentPage = 1
                } else {
                    self.popularMovies.append(contentsOf: movieResponse.results)
                    self.popularCurrentPage = page
                }
                
                self.popularTotalPages = movieResponse.totalPages
                self.popularHasMoreData = page < movieResponse.totalPages
                
                print("✅ MovieListVC - Popular Page \(page): \(movieResponse.results.count) movies, Total: \(self.popularMovies.count)")
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            case .failure(let error):
                print("❌ MovieListVC - Popular error: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchTopRatedMovies(page: Int = 1) {
        guard !isLoading else { return }
        
        isLoading = true
        SVProgressHUD.show()
        
        NetworkManager.shared.fetchTopRatedMovies(from: self, page: page) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            SVProgressHUD.dismiss()
            
            switch result {
            case .success(let movieResponse):
                if page == 1 {
                    self.topRatedMovies = movieResponse.results
                    self.topRatedCurrentPage = 1
                } else {
                    self.topRatedMovies.append(contentsOf: movieResponse.results)
                    self.topRatedCurrentPage = page
                }
                
                self.topRatedTotalPages = movieResponse.totalPages
                self.topRatedHasMoreData = page < movieResponse.totalPages
                
                print("✅ MovieListVC - Top Rated Page \(page): \(movieResponse.results.count) movies, Total: \(self.topRatedMovies.count)")
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
            case .failure(let error):
                print("❌ MovieListVC - Top Rated error: \(error.localizedDescription)")
            }
        }
    }
    
    // Optional: Keep this method if you need to fetch both at once
    private func fetchAllMovies() {
        let dispatchGroup = DispatchGroup()
        
        // Fetch Popular Movies
        dispatchGroup.enter()
        fetchPopularMovies(page: 1)
        dispatchGroup.leave()
        
        // Fetch Top Rated Movies
        dispatchGroup.enter()
        fetchTopRatedMovies(page: 1)
        dispatchGroup.leave()
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.reloadMovieCollections()
        }
    }
}

//
//  GenereMovieListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 23/01/26.
//

import UIKit
import SVProgressHUD
import Cosmos

class GenereMovieListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // Properties for pagination
    private var genreMovies: [Movie] = []
    private var currentPage: Int = 1
    private var isLoading: Bool = false
    private var hasMoreData: Bool = true
    private var totalPages: Int = 1
    
    var genreId: Int = 0
    var genreName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupCollectionViewLayout()
        
        // Set title and fetch movies
        titleLabel.text = genreName
        fetchGenreList(genreId: genreId, page: currentPage)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#111111")
        collectionView.backgroundColor = .clear
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        
        // Register HotPicDataCell
        let hotPicksNib = UINib(nibName: "HotPicDataCell", bundle: nil)
        collectionView.register(hotPicksNib, forCellWithReuseIdentifier: "HotPicDataCell")
    }
    
    private func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // Single column layout like top rated movies in MovieListVC
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        collectionView.collectionViewLayout = layout
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension GenereMovieListVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genreMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
        
        if indexPath.item < genreMovies.count {
            let movie = genreMovies[indexPath.item]
            
            // Configure cell exactly like MovieListVC for top rated movies
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Single column full width layout like HotPicks in MovieListVC
        let collectionViewWidth = collectionView.frame.width
        return CGSize(width: collectionViewWidth, height: 120)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < genreMovies.count else { return }
        let movie = genreMovies[indexPath.item]
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
    
    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }
        currentPage += 1
        fetchGenreList(genreId: genreId, page: currentPage)
    }
    
    private func openMovieDetails(for movie: Movie) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let movieDetailsVC = storyboard.instantiateViewController(withIdentifier: "MovieDetailsVC") as? MovieDetailsVC {
            movieDetailsVC.movieId = movie.id
            movieDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(movieDetailsVC, animated: true)
        }
    }
}

// MARK: - API Calls
extension GenereMovieListVC {
    func fetchGenreList(genreId: Int, page: Int) {
        guard !isLoading else { return }
        
        isLoading = true
        
        // Show loading indicator for first page
        if page == 1 {
            SVProgressHUD.show()
        }
        
        NetworkManager.shared.fetchListByGenre(from: self, genreId: genreId, page: page) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if page == 1 {
                SVProgressHUD.dismiss()
            }
            
            switch result {
            case .success(let movieResponse):
                if page == 1 {
                    self.genreMovies = movieResponse.results
                    self.currentPage = 1
                } else {
                    self.genreMovies.append(contentsOf: movieResponse.results)
                }
                
                self.totalPages = movieResponse.totalPages
                self.hasMoreData = page < movieResponse.totalPages
                
                print("✅ GenereMovieListVC - Page \(page): \(movieResponse.results.count) movies. Total: \(self.genreMovies.count)")
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    // Scroll to top for first page
                    if page == 1 && !movieResponse.results.isEmpty {
                        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                                        at: .top,
                                                        animated: false)
                    }
                }
                
            case .failure(let error):
                print("❌ Genre movie fetch error on page \(page):", error.localizedDescription)
                // Show error message to user
                self.showError(message: "Failed to load movies")
            }
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func reloadMovieCollections() {
        collectionView.reloadData()
    }
}

//
//  MovieSearchVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 23/01/26.
//

import UIKit
import SVProgressHUD
import Cosmos

class MovieSearchVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noDataLabel: UILabel!
    
    // Search properties
    private var searchMoviesData: [SearchMovie] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    private var hasMoreData = true
    private var searchQuery = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Focus search bar when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.searchBar.becomeFirstResponder()
        }
    }
    
    func setUI() {
        setUpSearchBar()
        setCollection()
        setupNoDataLabel()
    }
    
    private func setupNoDataLabel() {
        noDataLabel.text = "No movies found".localized(LocalizationService.shared.language)
        noDataLabel.textColor = .white
        noDataLabel.textAlignment = .center
        noDataLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        noDataLabel.isHidden = true
    }
    
    func setCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // Single column layout with spacing: left 15, right 15, top 10, bottom 10
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        
        // Register HotPicDataCell
        collectionView.register(UINib(nibName: "HotPicDataCell", bundle: nil), forCellWithReuseIdentifier: "HotPicDataCell")
    }
    
    func setUpSearchBar() {
        // Set placeholder
        searchBar.placeholder = "Search movies...".localized(LocalizationService.shared.language)
        
        // IMPORTANT: Remove all white backgrounds
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        
        // Remove the search bar background
        if #available(iOS 13.0, *) {
            // For iOS 13+
            searchBar.searchTextField.backgroundColor = .clear
            searchBar.searchTextField.tintColor = .white
            searchBar.searchTextField.textColor = .white
            
            // Set placeholder color
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
                string: searchBar.placeholder ?? "Search",
                attributes: placeholderAttributes
            )
            
            // Remove background view
            if let backgroundView = searchBar.searchTextField.subviews.first {
                backgroundView.backgroundColor = .clear
                backgroundView.layer.cornerRadius = 0
                backgroundView.clipsToBounds = false
            }
            
        } else {
            // For iOS 12 and below
            if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                textField.tintColor = .white
                textField.textColor = .white
                textField.backgroundColor = .clear
                
                // Set placeholder text color
                let placeholderAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.lightGray
                ]
                textField.attributedPlaceholder = NSAttributedString(
                    string: searchBar.placeholder ?? "Search",
                    attributes: placeholderAttributes
                )
                
                // Remove background view
                if let backgroundView = textField.subviews.first {
                    backgroundView.backgroundColor = .clear
                    backgroundView.layer.cornerRadius = 0
                    backgroundView.clipsToBounds = false
                }
                
                // Remove border
                textField.borderStyle = .none
                textField.layer.borderWidth = 0
            }
        }
        
        // Set white color for cancel button text
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .white
        
        // Remove the separator line at the bottom
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        
        // Remove the top and bottom borders
        searchBar.layer.borderWidth = 0
        
        // Set searchBar delegate
        searchBar.delegate = self
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension MovieSearchVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Reset search when text changes
        if searchText.isEmpty {
            searchMoviesData.removeAll()
            collectionView.reloadData()
            noDataLabel.isHidden = true
        } else {
            searchQuery = searchText
            // Perform search with debounce
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
            self.perform(#selector(performSearch), with: nil, afterDelay: 0.5)
        }
    }
    
    @objc private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        // Reset for new search
        currentPage = 1
        searchMoviesData.removeAll()
        collectionView.reloadData()
        
        // Show loading indicator
        SVProgressHUD.show()
        isLoading = true
        
        searchMovies(query: searchQuery, page: currentPage)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        
        // Clear search and go back
        navigationController?.popViewController(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text, !searchText.isEmpty {
            searchQuery = searchText
            performSearch()
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MovieSearchVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        noDataLabel.isHidden = !searchMoviesData.isEmpty
        return searchMoviesData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
        
        if indexPath.item < searchMoviesData.count {
            let searchMovie = searchMoviesData[indexPath.item]
            
            // Convert SearchMovie to Movie for compatibility with HotPicDataCell
            let movie = Movie(
                adult: searchMovie.adult,
                backdropPath: searchMovie.backdropPath,
                genreIDs: searchMovie.genreIds,
                id: searchMovie.id,
                originalLanguage: searchMovie.originalLanguage,
                originalTitle: searchMovie.originalTitle,
                overview: searchMovie.overview,
                popularity: searchMovie.popularity,
                posterPath: searchMovie.posterPath,
                releaseDate: searchMovie.releaseDate,
                title: searchMovie.title,
                video: searchMovie.video,
                voteAverage: searchMovie.voteAverage,
                voteCount: searchMovie.voteCount,
                genreNames: nil // Set to nil or empty array as needed
            )
            let rating = (movie.voteAverage) / 2.0
            
            // Configure cell with gradient
            cell.rateView.isHidden = false
            cell.movieDescLbl.isHidden = false
            cell.movieDescLbl.isHidden = false
            cell.rateView.settings.totalStars = 5
            cell.rateView.settings.starSize = 12
            cell.rateView.settings.starMargin = 4
            cell.rateView.settings.fillMode = .precise
            cell.rateView.settings.updateOnTouch = false
            
            cell.likeCountLabel.isHidden = true
            cell.hotePickBgImg.isHidden = true
            
            cell.configureTopRatedMovie(with: movie, shouldAddGradient: true)
            cell.rateView.rating = rating
            
            // Set click listener
            cell.setOnClickListener { [weak self] in
                self?.showInterAdClick()
                self?.openMovieDetails(movieId: movie.id)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Single column full width with left/right spacing of 15
        let collectionViewWidth = collectionView.frame.width
        let itemWidth = collectionViewWidth  
        return CGSize(width: itemWidth, height: 120)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.frame.size.height
        
        // Load more data when reaching bottom
        if offsetY > contentHeight - screenHeight - 100 && !isLoading && hasMoreData {
            loadMoreData()
        }
    }
    
    private func loadMoreData() {
        guard !isLoading && hasMoreData && !searchQuery.isEmpty else { return }
        currentPage += 1
        searchMovies(query: searchQuery, page: currentPage)
    }
    
    private func openMovieDetails(movieId: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let movieDetailsVC = storyboard.instantiateViewController(withIdentifier: "MovieDetailsVC") as? MovieDetailsVC {
            movieDetailsVC.movieId = movieId
            movieDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(movieDetailsVC, animated: true)
        }
    }
}

// MARK: - API Calls
extension MovieSearchVC {
    private func searchMovies(query: String, page: Int) {
        isLoading = true
        
        NetworkManager.shared.searchMovies(from: self, query: query, page: page) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            SVProgressHUD.dismiss()
            
            switch result {
            case .success(let response):
                if page == 1 {
                    self.searchMoviesData.removeAll()
                }
                self.searchMoviesData.append(contentsOf: response.results)
                self.currentPage = response.page
                self.totalPages = response.totalPages
                self.hasMoreData = response.page < response.totalPages
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.noDataLabel.isHidden = !self.searchMoviesData.isEmpty
                }
                
            case .failure(let error):
                print("❌ Failed to search movies:", error)
                DispatchQueue.main.async {
                    self.noDataLabel.isHidden = !self.searchMoviesData.isEmpty
                }
            }
        }
    }
}

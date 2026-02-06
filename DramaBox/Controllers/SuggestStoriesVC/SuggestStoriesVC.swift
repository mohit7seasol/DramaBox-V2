//
//  SuggestStoriesVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 12/12/25.
//

import UIKit
import Alamofire
import SDWebImage

class SuggestStoriesVC: UIViewController {
    
    @IBOutlet weak var categoryFirstButton: UIButton!
    @IBOutlet weak var categorySecondButton: UIButton!
    @IBOutlet weak var categoryThirdButton: UIButton!
    @IBOutlet weak var firstCategorySelectedImageView: UIImageView!
    @IBOutlet weak var secondCategorySelectedImageView: UIImageView!
    @IBOutlet weak var thirdCategorySelectedImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var categorySubTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // Data properties
    private var categories: [DramaSection] = []
    private var selectedCategoryIndex: Int = 0
    private var episodesByCategory: [String: [EpisodeItem]] = [:] // Key: category heading
    private var currentEpisodes: [EpisodeItem] = []
    private var currentIndex: Int = 0
    
    // Handler for when close button is tapped
    var closeHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupButtonActions()
        fetchCategories()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Recalculate layout when view size changes
        collectionView.collectionViewLayout.invalidateLayout()
        updateCarouselInsets()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup close button
        closeButton.setTitle("", for: .normal)
        if let closeImage = UIImage(systemName: "xmark") {
            closeButton.setImage(closeImage, for: .normal)
            closeButton.tintColor = .white
        }
        
        // Hide all selection indicators initially
        firstCategorySelectedImageView.isHidden = true
        secondCategorySelectedImageView.isHidden = true
        thirdCategorySelectedImageView.isHidden = true
        
        // Setup button colors
        let unselectedColor = UIColor(hex: "#878787") ?? .lightGray
        
        categoryFirstButton.setTitleColor(unselectedColor, for: .normal)
        categorySecondButton.setTitleColor(unselectedColor, for: .normal)
        categoryThirdButton.setTitleColor(unselectedColor, for: .normal)
        
        // Setup loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        loadingIndicator.style = .large
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "SuggestStoriesCell", bundle: nil),
                               forCellWithReuseIdentifier: "SuggestStoriesCell")
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        // Disable vertical scrolling - only horizontal
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        
        // Setup UPCarouselFlowLayout based on uploaded image design
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = .horizontal
        
        // Based on uploaded image: first cell fully visible, second cell 25-30% visible
        // Set sideItemScale so that next cell is smaller
        layout.sideItemScale = 0.85      // Side images 85% scale (slightly smaller)
        layout.sideItemAlpha = 0.8       // Side images slightly faded
        
        // Adjust spacing to show about 25-30% of next cell
        // Less spacing means more of the next cell is visible
        layout.spacingMode = .fixed(spacing: 10)
        
        // Calculate cell size to fill collection view height
        let cellHeight = collectionView.frame.height
        
        // Based on image: cell width should be less than full width to show next cell
        // Collection view width minus spacing minus visible portion of next cell
        let collectionWidth = collectionView.frame.width
        let cellWidth = collectionWidth * 0.75 // Cell takes 75% of width, leaving 25% for next cell
        
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        collectionView.collectionViewLayout = layout
        
        // Calculate and set section inset for carousel effect
        updateCarouselInsets()
        
        collectionView.decelerationRate = .fast
        
        // Disable multiple selection
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
    }
    
    private func updateCarouselInsets() {
        guard let layout = collectionView.collectionViewLayout as? UPCarouselFlowLayout else { return }
        
        let cellWidth = layout.itemSize.width
        let sideInset = (collectionView.frame.width - cellWidth) / 2
        
        // Set section insets to center the current item
        layout.sectionInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
    }
    
    private func setupButtonActions() {
        categoryFirstButton.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        categorySecondButton.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        categoryThirdButton.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func fetchCategories() {
        loadingIndicator.startAnimating()
        
        NetworkManager.shared.fetchDramas(from: self, page: 1) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    // Get all categories from the response
                    self.categories = response.data.data
                    
                    // Select 3 random categories
                    self.selectRandomCategories()
                    
                    // Select first category by default and fetch its episodes
                    if !self.categories.isEmpty {
                        self.selectCategory(at: 0)
                        self.fetchEpisodesForSelectedCategory()
                    }
                    
                case .failure(let error):
                    print("Error fetching categories: \(error.localizedDescription)")
                    // Show error or fallback
                    self.showDefaultCategories()
                }
            }
        }
    }
    
    private func selectRandomCategories() {
        // Filter categories that have non-empty headings
        let validCategories = categories.filter { !$0.heading.isEmpty }
        
        // Shuffle and take first 3
        let shuffledCategories = validCategories.shuffled()
        let selectedCategories = Array(shuffledCategories.prefix(3))
        
        // Update buttons
        if selectedCategories.count > 0 {
            categoryFirstButton.setTitle(selectedCategories[0].heading, for: .normal)
            categoryFirstButton.isHidden = false
            
            if selectedCategories.count > 1 {
                categorySecondButton.setTitle(selectedCategories[1].heading, for: .normal)
                categorySecondButton.isHidden = false
                
                if selectedCategories.count > 2 {
                    categoryThirdButton.setTitle(selectedCategories[2].heading, for: .normal)
                    categoryThirdButton.isHidden = false
                } else {
                    categoryThirdButton.isHidden = true
                }
            } else {
                categorySecondButton.isHidden = true
                categoryThirdButton.isHidden = true
            }
        } else {
            showDefaultCategories()
        }
    }
    
    private func showDefaultCategories() {
        let defaultCategories = ["Drama", "Anime", "Music's"]
        categoryFirstButton.setTitle(defaultCategories[0], for: .normal)
        categorySecondButton.setTitle(defaultCategories[1], for: .normal)
        categoryThirdButton.setTitle(defaultCategories[2], for: .normal)
        
        categoryFirstButton.isHidden = false
        categorySecondButton.isHidden = false
        categoryThirdButton.isHidden = false
        
        // Create mock categories
        let mockCategories = defaultCategories.map { heading in
            DramaSection(
                listType: "",
                heading: heading,
                type: "",
                eventName: "",
                more: 0,
                moreLink: "",
                moreParameters: "",
                style: "",
                moreParameterValue: "",
                list: []
            )
        }
        self.categories = mockCategories
        
        // Select first category
        selectCategory(at: 0)
    }
    
    private func selectCategory(at index: Int) {
        selectedCategoryIndex = index
        currentIndex = 0 // Reset collection index
        
        // Reset all buttons
        let unselectedColor = UIColor(hex: "#878787") ?? .lightGray
        
        categoryFirstButton.setTitleColor(unselectedColor, for: .normal)
        categorySecondButton.setTitleColor(unselectedColor, for: .normal)
        categoryThirdButton.setTitleColor(unselectedColor, for: .normal)
        
        firstCategorySelectedImageView.isHidden = true
        secondCategorySelectedImageView.isHidden = true
        thirdCategorySelectedImageView.isHidden = true
        
        // Select the chosen button
        switch index {
        case 0:
            categoryFirstButton.setTitleColor(.white, for: .normal)
            firstCategorySelectedImageView.isHidden = false
        case 1:
            categorySecondButton.setTitleColor(.white, for: .normal)
            secondCategorySelectedImageView.isHidden = false
        case 2:
            categoryThirdButton.setTitleColor(.white, for: .normal)
            thirdCategorySelectedImageView.isHidden = false
        default:
            break
        }
        
        // Update category info
        updateCategoryInfo()
    }
    
    private func getSelectedCategory() -> DramaSection? {
        guard selectedCategoryIndex < categories.count else { return nil }
        return categories[selectedCategoryIndex]
    }
    
    private func updateCategoryInfo() {
        guard let selectedCategory = getSelectedCategory() else { return }
        
        // Set category title
        categoryTitleLabel.text = selectedCategory.heading
        
        // Set subtitle based on category
        switch selectedCategory.heading {
        case "Popular Dramas":
            categorySubTitleLabel.text = "Trending now among viewers"
        case "Categories":
            categorySubTitleLabel.text = "Browse by genre and mood"
        case "Coming Soon....":
            categorySubTitleLabel.text = "Upcoming releases to watch"
        case "New Releases":
            categorySubTitleLabel.text = "Fresh content added daily"
        case "Explore Full Collection":
            categorySubTitleLabel.text = "Carnival Night"
        case "Drama":
            categorySubTitleLabel.text = "Carnival Night"
        case "Anime":
            categorySubTitleLabel.text = "Valentino Sydney Pop-up Fashion Events & Launches Sydney Pop-up Fashion..."
        case "Music's":
            categorySubTitleLabel.text = "Latest Music Stories"
        default:
            categorySubTitleLabel.text = "Explore amazing content"
        }
    }
    
    private func fetchEpisodesForSelectedCategory() {
        guard let selectedCategory = getSelectedCategory() else { return }
        
        // Show loading
        loadingIndicator.startAnimating()
        currentEpisodes = []
        collectionView.reloadData()
        
        // If we already have episodes for this category, use them
        if let cachedEpisodes = episodesByCategory[selectedCategory.heading] {
            self.currentEpisodes = cachedEpisodes
            self.collectionView.reloadData()
            self.loadingIndicator.stopAnimating()
            self.updateLabelsForCurrentIndex()
            self.scrollToCurrentIndex()
            return
        }
        
        // Get dramas from the selected category
        let dramas = selectedCategory.list
        
        // If no dramas in this category, show empty state
        if dramas.isEmpty {
            self.loadingIndicator.stopAnimating()
            self.collectionView.reloadData()
            return
        }
        
        // Fetch episodes for each drama in the category
        let dispatchGroup = DispatchGroup()
        var allEpisodes: [EpisodeItem] = []
        
        for drama in dramas.prefix(5) { // Limit to 5 dramas to avoid too many API calls
            guard let dramaId = drama.id else { continue }
            
            dispatchGroup.enter()
            
            NetworkManager.shared.fetchEpisodes(from: self, dramaId: dramaId, page: 1) { result in
                switch result {
                case .success(let episodes):
                    allEpisodes.append(contentsOf: episodes)
                case .failure(let error):
                    print("Error fetching episodes for drama \(dramaId): \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.loadingIndicator.stopAnimating()
            
            // Shuffle episodes for variety
            self.currentEpisodes = allEpisodes.shuffled()
            
            // Cache episodes for this category
            self.episodesByCategory[selectedCategory.heading] = self.currentEpisodes
            
            // Reload collection view
            self.collectionView.reloadData()
            
            // Scroll to first item
            if !self.currentEpisodes.isEmpty {
                self.currentIndex = 0
                self.scrollToCurrentIndex()
                self.updateLabelsForCurrentIndex()
            }
        }
    }
    
    private func scrollToCurrentIndex() {
        DispatchQueue.main.async {
            if !self.currentEpisodes.isEmpty {
                let indexPath = IndexPath(item: self.currentIndex, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    private func updateLabelsForCurrentIndex() {
        guard currentIndex < currentEpisodes.count else { return }
        let episode = currentEpisodes[currentIndex]
        
        // Update labels based on current episode
        categoryTitleLabel.text = episode.dName
        categorySubTitleLabel.text = "Episode \(currentIndex + 1) • \(episode.duration)"
    }
    
    private func navigateToEpisodePlayer(with episode: EpisodeItem) {
        // Navigate to ViewAllEpisodsStoriesVC to play the episode
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewAllEpisodesVC = storyboard.instantiateViewController(withIdentifier: "ViewAllEpisodsStoriesVC") as? ViewAllEpisodsStoriesVC {
            
            // Pass the episode data
            viewAllEpisodesVC.dramaId = episode.dId
            viewAllEpisodesVC.dramaName = episode.dName
            viewAllEpisodesVC.storiesPlayingViewType = .isOpenAllStoriesEpisods
            viewAllEpisodesVC.isOpenFromSuggestionVC = true
            
            // You might want to pass all episodes from the same drama
            // For now, just pass the single episode in an array
            viewAllEpisodesVC.allEpisodes = [episode]
            viewAllEpisodesVC.hidesBottomBarWhenPushed = true
            
            // Present modally
            viewAllEpisodesVC.modalPresentationStyle = .fullScreen
            self.present(viewAllEpisodesVC, animated: true)
        }
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        var index = 0
        
        if sender == categoryFirstButton {
            index = 0
        } else if sender == categorySecondButton {
            index = 1
        } else if sender == categoryThirdButton {
            index = 2
        }
        
        selectCategory(at: index)
        fetchEpisodesForSelectedCategory()
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.closeHandler?()
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension SuggestStoriesVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentEpisodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestStoriesCell",
                                                     for: indexPath) as! SuggestStoriesCell
        
        if indexPath.item < currentEpisodes.count {
            let episode = currentEpisodes[indexPath.item]
            
            // Load image
            if !episode.thumbnails.isEmpty, let url = URL(string: episode.thumbnails) {
                // Using SDWebImage
                cell.previewImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "video_placeholder"))
            } else if !episode.dImage.isEmpty, let url = URL(string: episode.dImage) {
                cell.previewImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "video_placeholder"))
            } else {
                cell.previewImageView.image = UIImage(named: "video_placeholder")
            }
            
            // Style the cell - set corner radius like in uploaded image
            cell.previewImageView.layer.cornerRadius = 30
            cell.previewImageView.clipsToBounds = true
            cell.previewImageView.layer.borderWidth = 1
            cell.previewImageView.layer.borderColor = UIColor.darkGray.cgColor
            
            // Add shadow
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2)
            cell.layer.shadowRadius = 4
            cell.layer.shadowOpacity = 0.2
            cell.layer.masksToBounds = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < currentEpisodes.count {
            let episode = currentEpisodes[indexPath.item]
            // Handle episode selection
            navigateToEpisodePlayer(with: episode)
        }
    }
    
    // MARK: - UIScrollViewDelegate Methods (for carousel effect)
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        
        // Let UPCarouselFlowLayout handle the scaling and alpha
        // It automatically applies sideItemScale and sideItemAlpha based on the layout
        
        // No need for manual transform calculations anymore
        // UPCarouselFlowLayout handles it automatically
        
        // Prevent vertical scrolling
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
    }
    
    private func updateCurrentPage() {
        guard let layout = collectionView.collectionViewLayout as? UPCarouselFlowLayout else { return }
        
        // Calculate page size including spacing
        let pageSize = self.pageSize(for: layout)
        let page = Int((collectionView.contentOffset.x + (pageSize / 2)) / pageSize)
        
        let newIndex = max(0, min(page, currentEpisodes.count - 1))
        if newIndex != currentIndex {
            currentIndex = newIndex
            updateLabelsForCurrentIndex()
        }
    }
    
    private func pageSize(for layout: UPCarouselFlowLayout) -> CGFloat {
        var pageSize = layout.itemSize.width
        if layout.scrollDirection == .horizontal {
            pageSize += layout.minimumLineSpacing
        } else {
            pageSize = layout.itemSize.height + layout.minimumLineSpacing
        }
        return pageSize
    }
}

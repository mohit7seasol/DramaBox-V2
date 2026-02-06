//
//  ViewAllEpisodsStoriesVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 08/12/25.
//

import UIKit
import SVProgressHUD
import GoogleMobileAds

class ViewAllEpisodsStoriesVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var dramaId: String?
    var dramaName: String?
    var storiesPlayingViewType: StoriesPlayingViewTypes = .isOpenAllStoriesEpisods
    var isOpenFromSuggestionVC: Bool = false
    var isOpenFromMyList: Bool = false
    
    private var episodes: [EpisodeItem] = []
    
    // Add this public property to receive episodes from StoriesVC
    var allEpisodes: [EpisodeItem] = [] // Add this line
    
    // Properties for pagination
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    private var currentPlayingIndex: Int = -1
    private var initialLoadComplete = false
    
    // MARK: - Watch History Tracking
    private var currentWatchedEpisodeId: String?
    private var watchStartTime: Date?
    private var currentWatchProgress: Double = 0.0
    
    var isTrailerOnly: Bool = false // Add this flag
    var startingIndex: Int = 0 // Add starting index
    
    // MARK: - Ad Properties
    private let adInterval = 3 // Show ad every 3rd item
    private var adIndices: Set<Int> = [] // Track which indices should have ads
    private var nativeAdCache: [Int: NativeAd] = [:]
    private var failedAdIndexes: Set<Int> = []
    var googleNativeAds = GoogleNativeAds() // Add GoogleNativeAds instance
    
    // MARK: - Premium Properties
    private let premiumStartIndex = 2 // 3rd episode (index 2) and later are premium
    
    // Add loading view
    private lazy var loadingView: UIView = {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = .black
        
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = view.center
        indicator.startAnimating()
        view.addSubview(indicator)
        
        let label = UILabel()
        label.text = "Loading episodes..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: indicator.frame.maxY + 20, width: view.bounds.width, height: 30)
        view.addSubview(label)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        
        // Start watching the first episode if passed from StoriesVC
        if !allEpisodes.isEmpty {
            self.episodes = allEpisodes
            
            // Setup data (this will handle ads based on subscription)
            setupData()
            
            hideInitialLoading()
            tableView.isHidden = false
            tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Start at the specified index
                if self.startingIndex < self.totalItemsCount() {
                    self.scrollToIndex(self.startingIndex)
                }
                
                // Auto-play if should auto-play
                if self.shouldAutoPlayEpisode(at: self.startingIndex) {
                    self.playVideoForVisibleCell()
                }
                
                // Start tracking watch time for first episode
                if let firstEpisode = self.getEpisode(at: self.startingIndex) {
                    self.startWatchingEpisode(firstEpisode)
                }
            }
        } else {
            fetchEpisodes()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Update table view frame and row height
            self.tableView.frame = CGRect(origin: .zero, size: size)
            self.tableView.rowHeight = size.height
            
            // Reload visible cells to update their size
            self.tableView.reloadData()
            
            // Continue playing current video
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playVideoForVisibleCell()
            }
        }, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Auto-play first video when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.shouldAutoPlayEpisode(at: self.currentPlayingIndex) {
                self.playVideoForVisibleCell()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideos()
        stopWatchingEpisode() // Save watch history when leaving
    }
    
    private func showInitialLoading() {
        view.addSubview(loadingView)
    }
    
    private func hideInitialLoading() {
        loadingView.removeFromSuperview()
    }
    
    func setUpUI() {
        settable()
    }
    
    func settable() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(["StoriesPlayingCell", "NativeAdsCell"])
        
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .black
        self.tableView.isPagingEnabled = true
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.contentInsetAdjustmentBehavior = .never
        
        // REQUIRED for proper cell sizing
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        
        // Initially hide table view until data loads
        tableView.isHidden = true
    }
    
    // MARK: - Setup Data
    private func setupData() {
        // Insert ads only for non-subscribed users
        if Subscribe.get() == false {
            insertAdsInEpisodes()
            debugAdSequence() // Add this for debugging
        } else {
            // Subscribed users: No ads
            adIndices.removeAll()
        }
        
        // Set initial load complete and reload table
        initialLoadComplete = true
        tableView.reloadData()
    }
    
    // MARK: - Ad Insertion Logic
    // MARK: - Ad Insertion Logic
    private func insertAdsInEpisodes() {
        // Clear previous ad indices
        adIndices.removeAll()
        
        // If playing trailer only, no ads
        if isTrailerOnly || episodes.isEmpty {
            print("No ads: isTrailerOnly=\(isTrailerOnly), episodes empty=\(episodes.isEmpty)")
            return
        }
        
        // Check if user is subscribed - no ads for subscribed users
        if Subscribe.get() {
            print("User is subscribed, no ads inserted")
            return
        }
        
        print("Inserting ads for non-subscribed user with \(episodes.count) episodes")
        
        // Calculate where ads should go: after every 2nd episode
        // Episode 1 at index 0, Episode 2 at index 1, AddView index 2
        // Episode 3 at index 3, Episode 4 at index 4, AddView index 5
        // Episode 5 at index 6, Episode 6 at index 7, AddView index 8, etc.
        
        // We need to simulate inserting ads into the episodes array
        // We'll build the indices where ads should be placed
        
        var currentPosition = 0
        var episodeCount = 0
        let totalEpisodes = episodes.count
        
        while episodeCount < totalEpisodes {
            // Place episodes at currentPosition and currentPosition + 1
            episodeCount += 2
            
            // If we've placed all episodes, break
            if episodeCount >= totalEpisodes {
                break
            }
            
            // Place ad at currentPosition + 2
            let adPosition = currentPosition + 2
            adIndices.insert(adPosition)
            print("Inserting ad at position: \(adPosition)")
            
            // Move to next block (skip the ad position)
            currentPosition = adPosition + 1
        }
        
        // Alternative even simpler approach:
        // For n episodes, we need ads at positions: 2, 5, 8, 11, ...
        // Formula: adPosition = 2 + 3k where k = 0, 1, 2, ...
        
        adIndices.removeAll() // Clear and recalculate with simpler method
        
        let totalEpisodesCount = episodes.count
        var k = 0
        
        while true {
            let adPosition = 2 + (3 * k)
            
            // Check if this ad position would come before or at the last episode position
            // We need to consider that each ad shifts subsequent episodes by 1
            let actualEpisodePosition = adPosition - k // Subtract k because each ad shifts positions
            
            if actualEpisodePosition < totalEpisodesCount {
                adIndices.insert(adPosition)
                print("Simple method: Inserting ad at position \(adPosition), k=\(k)")
                k += 1
            } else {
                break
            }
        }
        
        print("Final ad indices: \(adIndices.sorted())")
        print("Total items: \(episodes.count), Ads: \(adIndices.count), Total with ads: \(totalItemsCount())")
        
        // Let's also debug by printing the sequence
        print("\nSequence with ads:")
        var sequence: [String] = []
        for i in 0..<totalItemsCount() {
            if isAdIndex(i) {
                sequence.append("[AD \(i)]")
            } else {
                let epIndex = adjustedEpisodeIndex(for: i)
                sequence.append("E\(epIndex + 1)")
            }
        }
        print(sequence.joined(separator: " → "))
    }
    
    private func isAdIndex(_ index: Int) -> Bool {
        return adIndices.contains(index)
    }
    
    private func adjustedEpisodeIndex(for index: Int) -> Int {
        // Count how many ad positions come before this index
        var adsBefore = 0
        for adIndex in adIndices.sorted() {
            if adIndex <= index {  // Changed from < to <=
                adsBefore += 1
            } else {
                break
            }
        }
        return index - adsBefore
    }
    private func debugAdSequence() {
        print("\n=== DEBUG AD SEQUENCE ===")
        print("Episodes count: \(episodes.count)")
        print("Ad indices: \(adIndices.sorted())")
        
        for i in 0..<totalItemsCount() {
            if isAdIndex(i) {
                print("Index \(i): [AD]")
            } else {
                let epIndex = adjustedEpisodeIndex(for: i)
                print("Index \(i): Episode \(epIndex + 1) (original index: \(epIndex))")
            }
        }
        print("=== END DEBUG ===\n")
    }
    
    private func totalItemsCount() -> Int {
        return episodes.count + adIndices.count
    }
    
    private func getEpisode(at index: Int) -> EpisodeItem? {
        let episodeIndex = adjustedEpisodeIndex(for: index)
        guard episodeIndex >= 0 && episodeIndex < episodes.count else { return nil }
        return episodes[episodeIndex]
    }
    
    private func scrollToIndex(_ index: Int) {
        guard index >= 0 && index < totalItemsCount() else { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    
    // MARK: - Premium Logic (SIMPLE - as requested)
    private func shouldAutoPlayEpisode(at episodeIndex: Int) -> Bool {
        // If trailer only mode, always auto-play
        if isTrailerOnly {
            return true
        }
        
        // Check subscription status
        if Subscribe.get() == false {
            // Non-subscribed users: only first 2 episodes are free
            return episodeIndex < 2
        } else {
            // Subscribed users: all episodes are free
            return true
        }
    }
    
    private func isEpisodePremium(at episodeIndex: Int) -> Bool {
        // If trailer only mode, never premium
        if isTrailerOnly {
            return false
        }
        
        // Check subscription status
        if Subscribe.get() == false {
            // Non-subscribed users: episodes 3+ are premium
            return episodeIndex >= 2
        } else {
            // Subscribed users: no premium episodes
            return false
        }
    }
    
    private func handlePremiumEpisodeTap() {
        openPremiumVC()
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
    
    private func pauseAllVideos() {
        print("⏸️ Pausing all videos")
        for cell in tableView.visibleCells {
            if let storiesCell = cell as? StoriesPlayingCell {
                storiesCell.pauseVideo()
            }
        }
        currentPlayingIndex = -1
    }
    private func configurePlayButtonForCell(_ cell: StoriesPlayingCell, at indexPath: IndexPath) {
        let episodeIndex = adjustedEpisodeIndex(for: indexPath.row)
        
        // Check if episode is premium
        let isPremium = isEpisodePremium(at: episodeIndex)
        let isSubscribed = Subscribe.get()
        
        if isPremium && !isSubscribed {
            // Premium episode for non-subscribed user
            // Show play button but handle tap differently
            cell.showPlayButton()
            cell.pauseVideo() // Ensure video is paused
            
            // IMPORTANT: Set the play button handler for premium episodes
            cell.playButtonHandler = { [weak self] in
                self?.handlePremiumEpisodeTap()
            }
        } else {
            // Free episode or subscribed user
            // Set normal play button handler
            cell.playButtonHandler = {
                cell.playVideoIfReady()
            }
            
            // Auto-play logic
            if indexPath.row == currentPlayingIndex && shouldAutoPlayEpisode(at: episodeIndex) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    cell.playVideoIfReady()
                }
            }
        }
    }
    
    private func getCenterCellIndexPath() -> IndexPath? {
        let center = view.convert(tableView.center, to: tableView)
        return tableView.indexPathForRow(at: center)
    }
    
    // MARK: - Watch History Methods
    private func startWatchingEpisode(_ episode: EpisodeItem) {
        currentWatchedEpisodeId = episode.epiId
        watchStartTime = Date()
        currentWatchProgress = 0.0
    }
    
    private func stopWatchingEpisode() {
        guard let episodeId = currentWatchedEpisodeId,
              let startTime = watchStartTime,
              let episode = episodes.first(where: { $0.epiId == episodeId }) else {
            return
        }
        
        let watchDuration = Date().timeIntervalSince(startTime)
        
        // Save to watch history
        LocalStorageManager.shared.saveWatchHistory(
            episode: episode,
            duration: watchDuration,
            progress: currentWatchProgress
        )
        
        // Reset tracking
        currentWatchedEpisodeId = nil
        watchStartTime = nil
        currentWatchProgress = 0.0
    }
    
    private func updateWatchProgress(for episode: EpisodeItem, progress: Double) {
        guard episode.epiId == currentWatchedEpisodeId else { return }
        currentWatchProgress = max(currentWatchProgress, progress)
    }
    
    // MARK: - Episode Save Handling
    private func saveEpisode(_ episode: EpisodeItem) {
        let success = LocalStorageManager.shared.saveEpisode(episode)
        
        // Show feedback to user
        if success {
            showToast(message: "Episode saved to My List")
        } else {
            showToast(message: "Episode already in My List")
        }
        
        // Update save button state in all visible cells
        updateSaveButtonStates()
    }
    
    private func updateSaveButtonStates() {
        for cell in tableView.visibleCells {
            if let storiesCell = cell as? StoriesPlayingCell,
               let episode = storiesCell.currentEpisode {
                let isSaved = LocalStorageManager.shared.isEpisodeSaved(episodeId: episode.epiId)
                storiesCell.updateSaveButtonState(isSaved: isSaved)
            }
        }
    }
    
    private func showToast(message: String) {
        let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(toast, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                toast.dismiss(animated: true)
            }
        }
    }
    
    private func shareEpisode(_ episode: EpisodeItem) {
        let shareText = "Watch \(episode.epiName) from \(episode.dName)"
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewAllEpisodsStoriesVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalItemsCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Check if this is an ad position
        if isAdIndex(indexPath.row) {
            return adCell(for: tableView, at: indexPath)
        } else {
            return episodeCell(for: tableView, at: indexPath)
        }
    }
    
    private func adCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NativeAdsCell",
            for: indexPath
        ) as! NativeAdsCell

        cell.selectionStyle = .none
        cell.googleNativeAds = googleNativeAds

        // ✅ 1. If ad already cached → just rebind
        if let cachedAd = nativeAdCache[indexPath.row] {
            cell.bind(nativeAd: cachedAd)
            return cell
        }

        // ❌ If failed before → hide cell
        if failedAdIndexes.contains(indexPath.row) {
            cell.hideAd()
            return cell
        }

        // ✅ 2. Load ad only first time
        cell.loadAd(vc: self) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let nativeAd):
                    self.nativeAdCache[indexPath.row] = nativeAd
                case .failure:
                    self.failedAdIndexes.insert(indexPath.row)
                }

                UIView.performWithoutAnimation {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
        }

        return cell
    }
    // In the episodeCell method of ViewAllEpisodsStoriesVC, update the playButtonHandler:
    private func episodeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoriesPlayingCell",
                                                 for: indexPath) as? StoriesPlayingCell ?? StoriesPlayingCell()
        cell.selectionStyle = .none
        
        // Adjust index for ad positions
        let episodeIndex = adjustedEpisodeIndex(for: indexPath.row)
        guard episodeIndex < episodes.count else {
            return cell
        }
        
        // Configure cell with episode data
        let episode = episodes[episodeIndex]
        cell.configureWithEpisode(episode: episode,
                                 viewType: .isOpenAllStoriesEpisods,
                                 dramaName: self.dramaName,
                                 allEpisodes: self.episodes,
                                 currentIndex: episodeIndex)
        
        // Store the current cell index for reference
        cell.tag = indexPath.row
        
        // Force layout update
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        if isOpenFromSuggestionVC {
            cell.moreButton.isHidden = true
            cell.allEpisodsButton.isHidden = true
        }
        
        // Handle share button
        cell.shareHandler = { [weak self] in
            self?.shareEpisode(episode)
        }
        
        // Handle save button
        cell.saveHandler = { [weak self] in
            self?.saveEpisode(episode)
        }
        
        // Handle back button
        cell.backButtonHandler = { [weak self] in
            guard let self = self else { return }
            // Highest priority: coming from MyList
            if self.isOpenFromMyList == true {
                self.navigationController?.popViewController(animated: true)
                return
            }
            
            // Coming from SuggestionVC?
            if self.isOpenFromSuggestionVC == false {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
        
        // Handle episode selection from popup
        cell.episodeSelectedHandler = { [weak self] selectedEpisode in
            guard let self = self else { return }
            
            print("🔄 Episode selected handler called for: \(selectedEpisode.epiName)")
            
            if let index = self.episodes.firstIndex(where: { $0.epiId == selectedEpisode.epiId }) {
                // Adjust for ads
                var adjustedIndex = index
                for adIndex in self.adIndices.sorted() {
                    if adIndex <= adjustedIndex {
                        adjustedIndex += 1
                    }
                }
                
                print("📊 Scrolling to index: \(adjustedIndex) for episode index: \(index)")
                
                // Pause current playing video
                self.pauseAllVideos()
                
                // Scroll to the selected episode
                let indexPath = IndexPath(row: adjustedIndex, section: 0)
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                
                // Set current playing index
                self.currentPlayingIndex = adjustedIndex
                
                // Wait for scroll to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Check if episode should auto-play based on subscription
                    let shouldAutoPlay = self.shouldAutoPlayEpisode(at: index)
                    
                    if shouldAutoPlay {
                        // Get the cell and play video
                        if let currentCell = tableView.cellForRow(at: indexPath) as? StoriesPlayingCell {
                            print("🎬 Auto-playing selected episode after delay")
                            currentCell.playVideoIfReady()
                        }
                    } else {
                        // For premium episodes, show play button
                        if let currentCell = tableView.cellForRow(at: indexPath) as? StoriesPlayingCell {
                            print("⏸️ Showing play button for premium episode")
                            currentCell.showPlayButton()
                        }
                    }
                    
                    // Start tracking watch time for selected episode
                    self.stopWatchingEpisode()
                    self.startWatchingEpisode(selectedEpisode)
                }
            }
        }
        
        // Handle premium subscription from cell
        cell.premiumSubscriptionHandler = { [weak self] in
            self?.handlePremiumEpisodeTap()
        }
        
        // Configure play button based on subscription status
        let isSubscribed = Subscribe.get()
        let isPremiumEpisode = isEpisodePremium(at: episodeIndex)
        
        if !isSubscribed && isPremiumEpisode {
            // Premium episode for non-subscribed user
            print("🔒 Configuring premium episode cell at index: \(episodeIndex)")
            
            // Show play button initially
            cell.showPlayButton()
            cell.pauseVideo() // Ensure video is paused
            
            // Set play button handler to open premium VC
            cell.playButtonHandler = { [weak self] in
                print("🔒 Play button tapped on premium episode")
                self?.handlePremiumEpisodeTap()
            }
            
        } else {
            // Free episode or subscribed user
            print("✅ Configuring free/subscribed episode cell at index: \(episodeIndex)")
            
            // FIX: Use a simpler, more reliable play button handler
            cell.playButtonHandler = { [weak self] in
                guard let self = self else { return }
                
                // Double-check if this is a premium episode for non-subscribed user
                if self.isEpisodePremium(at: episodeIndex) && !Subscribe.get() {
                    print("🔒 Premium episode detected in handler")
                    self.handlePremiumEpisodeTap()
                    return
                }
                
                // Toggle play/pause - let the cell handle its own state
                print("🔄 Toggling play/pause via handler")
                
                if cell.isVideoPlaying {
                    // Video is playing, pause it
                    cell.pauseVideo()
                } else {
                    // Video is paused, play it
                    cell.playVideo()
                    
                    // Update current playing index
                    self.currentPlayingIndex = indexPath.row
                }
            }
            
            // Auto-play logic for visible cell
            if indexPath.row == currentPlayingIndex {
                let shouldAutoPlay = shouldAutoPlayEpisode(at: episodeIndex)
                
                if shouldAutoPlay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        // Check again to make sure we're still on the same cell
                        if indexPath.row == self?.currentPlayingIndex {
                            cell.playVideoIfReady()
                        }
                    }
                } else {
                    // Don't auto-play, just show play button
                    cell.showPlayButton()
                }
            } else {
                // Not the current playing cell, ensure it shows play button
                if cell.isVideoPlaying {
                    cell.pauseVideo()
                } else {
                    cell.showPlayButton()
                }
            }
        }
        
        // Handle more button (speed/quality settings)
        cell.moreButtonHandler = { [weak cell] in
            cell?.presentSpeedSettingsBottomSheet()
        }
        
        // Update save button state
        let isSaved = LocalStorageManager.shared.isEpisodeSaved(episodeId: episode.epiId)
        cell.updateSaveButtonState(isSaved: isSaved)
        
        return cell
    }
    // Add this helper method for debugging
    private func debugCellState(at indexPath: IndexPath, episodeIndex: Int) {
        let isPremium = isEpisodePremium(at: episodeIndex)
        let isSubscribed = Subscribe.get()
        let shouldAutoPlay = shouldAutoPlayEpisode(at: episodeIndex)
        
        print("""
        📱 Cell Debug for row \(indexPath.row):
        - Episode Index: \(episodeIndex)
        - Episode: \(episodes[episodeIndex].epiName)
        - Is Premium: \(isPremium)
        - Is Subscribed: \(isSubscribed)
        - Should Auto-play: \(shouldAutoPlay)
        - Current Playing Index: \(currentPlayingIndex)
        """)
    }
    private func playVideoForVisibleCell() {
        guard let indexPath = tableView.indexPathsForVisibleRows?.first else { return }
        
        // Skip ad cells for video playback
        if isAdIndex(indexPath.row) { return }
        
        // If we're already playing this cell, do nothing
        if currentPlayingIndex == indexPath.row { return }
        
        // Update current playing index
        currentPlayingIndex = indexPath.row
        
        // Get the episode index (adjusted for ads)
        let episodeIndex = adjustedEpisodeIndex(for: indexPath.row)
        
        // Check if episode should auto-play based on subscription
        let shouldAutoPlay = shouldAutoPlayEpisode(at: episodeIndex)
        
        if shouldAutoPlay {
            print("🎬 Auto-playing episode at index: \(episodeIndex) (row: \(indexPath.row))")
            
            // Pause previously playing video
            pauseAllVideos()
            
            // Play new video
            if let currentCell = tableView.cellForRow(at: indexPath) as? StoriesPlayingCell {
                // Play with small delay to ensure UI is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentCell.playVideoIfReady()
                    
                    // Start tracking watch time
                    if let episode = self.getEpisode(at: episodeIndex) {
                        self.startWatchingEpisode(episode)
                    }
                }
            }
        } else {
            // Don't auto-play, show play button
            print("⏸️ Not auto-playing premium episode at index: \(episodeIndex)")
            if let currentCell = tableView.cellForRow(at: indexPath) as? StoriesPlayingCell {
                currentCell.showPlayButton()
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // In trailer-only mode, allow scrolling but disable paging
        if isTrailerOnly {
            return UIScreen.main.bounds.height
        }
        
        // Hide ads for subscribed users
        if isAdIndex(indexPath.row) {
            if Subscribe.get() {
                return 0
            }
            if failedAdIndexes.contains(indexPath.row) {
                return 0
            }
            return UIScreen.main.bounds.height
        }

        return UIScreen.main.bounds.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if isAdIndex(indexPath.row) {
            if Subscribe.get() {
                return 0
            }
            if failedAdIndexes.contains(indexPath.row) {
                return 0
            }
            return tableView.frame.height
        }
        
        return tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Skip ad cells
        if isAdIndex(indexPath.row) { return }
        
        let episodeIndex = adjustedEpisodeIndex(for: indexPath.row)
        
        // Check if episode is premium and user is not subscribed
        if isEpisodePremium(at: episodeIndex) && !Subscribe.get() {
            handlePremiumEpisodeTap()
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let storiesCell = cell as? StoriesPlayingCell {
            storiesCell.pauseVideo()
            if currentPlayingIndex == indexPath.row {
                currentPlayingIndex = -1
            }
        }
    }
}

// MARK: - Scroll autoplay
extension ViewAllEpisodsStoriesVC: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playVideoForVisibleCell()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            playVideoForVisibleCell()
        }
    }
}

// MARK: - Api's calling
extension ViewAllEpisodsStoriesVC {
    func fetchEpisodes(isLoadMore: Bool = false) {
        guard let dramaId = dramaId, !dramaId.isEmpty else {
            showAlert(message: "Invalid drama ID")
            return
        }
        
        guard !isLoading, (isLoadMore ? hasMoreData : true) else { return }
        
        isLoading = true
        
        NetworkManager.shared.fetchEpisodes(from: self, dramaId: dramaId, page: currentPage) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let newEpisodes):
                if isLoadMore {
                    self.episodes.append(contentsOf: newEpisodes)
                } else {
                    self.episodes = newEpisodes
                    
                    // Setup data (this will handle ads based on subscription)
                    self.setupData()
                    
                    // Hide initial loading and show table view
                    DispatchQueue.main.async {
                        self.hideInitialLoading()
                        self.tableView.isHidden = false
                        self.initialLoadComplete = true
                    }
                }
                
                // Update pagination state
                self.hasMoreData = !newEpisodes.isEmpty
                if self.hasMoreData {
                    self.currentPage += 1
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                    // Auto-play first video if initial load
                    if !isLoadMore && !self.episodes.isEmpty && self.initialLoadComplete {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if self.shouldAutoPlayEpisode(at: 0) {
                                self.playVideoForVisibleCell()
                            }
                            
                            // Start tracking watch time for first episode
                            if let firstEpisode = self.getEpisode(at: 0) {
                                self.startWatchingEpisode(firstEpisode)
                            }
                        }
                    }
                }
                
            case .failure(let error):
                print("Error fetching episodes: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hideInitialLoading()
                    self.tableView.isHidden = false
                    self.showAlert(message: "Failed to load episodes. Please try again.")
                }
            }
        }
    }
    
    func loadMoreEpisodes() {
        guard !isLoading && hasMoreData else { return }
        fetchEpisodes(isLoadMore: true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func presentSuggestStoriesVC() {
        let suggestVC = SuggestStoriesVC(nibName: "SuggestStoriesVC", bundle: nil)
        suggestVC.modalPresentationStyle = .fullScreen
        suggestVC.modalTransitionStyle = .crossDissolve
        // Set close handler
        suggestVC.closeHandler = { [weak self] in
            // Dismiss the xib and pop to StoriesVC
            self?.dismiss(animated: true) {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        
        self.present(suggestVC, animated: true)
    }
}

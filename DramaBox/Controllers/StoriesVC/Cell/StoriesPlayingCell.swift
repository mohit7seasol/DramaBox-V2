//
//  StoriesPlayingCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 08/12/25.
//

import UIKit
import AVFoundation
import SDWebImage
import SwiftPopup

class StoriesPlayingCell: UITableViewCell {
    
    // MARK: - Existing Outlets
    @IBOutlet weak var appTitleHeaderView: UIView!
    @IBOutlet weak var navigationTitleView: UIView!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var navigationTitleLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var userProfieInfoView: UIView!
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var storieDetailsLabel: UILabel!
    @IBOutlet weak var enjoyFullStoriesView: UIView!
    @IBOutlet weak var enjoyFullStoriesLabel: UILabel!
    @IBOutlet weak var enjoyFullStoriesButton: UIButton!
    @IBOutlet weak var videoSliderView: UIView!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var startDurationLabel: UILabel!
    @IBOutlet weak var endDurationLabel: UILabel!
    @IBOutlet weak var allEpisodsButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var storiesThumbImageView: UIImageView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var storieDetailsLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoSliderViewHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var fullStoryViewHeightConstant: NSLayoutConstraint!
    
    // MARK: - Properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isVideoPlaying = false
    private var currentDrama: DramaItem?
    var currentEpisode: EpisodeItem?
    private var isStoryDetailsExpanded = false
    
    private var allEpisodes: [EpisodeItem] = []
    private var selectedEpisodeIndex: Int = 0
    private var selectedSpeedIndex: Int = 1 // Default to 1.0x
    private var selectedQualityIndex: Int = 2 // Default to 720p
    private var isSubscribed: Bool = false
    
    // Handlers
    var enjoyFullStoriesHandler: (() -> Void)?
    var storyDetailsTappedHandler: (() -> Void)?
    var shareHandler: (() -> Void)?
    var saveHandler: (() -> Void)?
    var backButtonHandler: (() -> Void)?
    var moreButtonHandler: (() -> Void)?
    var episodeSelectedHandler: ((EpisodeItem) -> Void)?
    var allEpisodesForDrama: [EpisodeItem] = []
    var storiesPlayingViewType: StoriesPlayingViewTypes = .isOpenStories
    
    private var currentVideoProgress: Double = 0.0
    private var controlsHideTimer: Timer?
    private let controlsHideDelay: TimeInterval = 3.0
    private var isControlsVisible: Bool = false
    private var isPlayerReady = false
    private var shouldAutoPlay = false
    private var timeObserverToken: Any?
    private var playerItem: AVPlayerItem?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerItemDurationObserver: NSKeyValueObservation?
    
    // MARK: - SwiftPopup instances
    private var episodesPopup: EpisodesViewBottomPopUp?
    private var speedPopup: SpeedSetBottomPopUp?
    
    var playButtonHandler: (() -> Void)?
    var premiumSubscriptionHandler: (() -> Void)?
    
    // MARK: - Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCellUI()
        setupGestureRecognizers()
        setupStoryDetailsLabel()
        setupButtonActions()
        
        self.isSubscribed = Subscribe.get()
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.frame = bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        mainView.frame = contentView.bounds
        playerLayer?.frame = mainView.bounds
        contentView.bringSubviewToFront(playButton)
        
        if storiesPlayingViewType == .isOpenAllStoriesEpisods {
            videoSliderView.isHidden = false
            videoSliderViewHeightConstant.constant = 70
        }
        
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("🚀 prepareForReuse() called for cell")
        
        // Clean up everything
        completelyCleanupPlayer()
        
        // Reset all properties
        currentDrama = nil
        currentEpisode = nil
        isStoryDetailsExpanded = false
        currentVideoProgress = 0.0
        isPlayerReady = false
        shouldAutoPlay = false
        isVideoPlaying = false
        
        // Reset UI
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.isHidden = true
        storiesThumbImageView.isHidden = false
        storiesThumbImageView.image = nil
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        videoSlider.value = 0
        startDurationLabel.text = "0:00"
        endDurationLabel.text = "0:00"
        
        // Reset timers
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        
        print("✅ prepareForReuse() complete")
    }
    
    deinit {
        print("🗑️ StoriesPlayingCell deinit")
        completelyCleanupPlayer()
        controlsHideTimer?.invalidate()
    }
    
    // MARK: - UI Setup
    
    func setCellUI() {
        mainView.backgroundColor = .black
        self.appTitleLabel.text = "Sora Pixo".localized(LocalizationService.shared.language)
        self.enjoyFullStoriesLabel.text = "Enjoy Full Stories".localized(LocalizationService.shared.language)
        userProfileImageView.layer.cornerRadius = userProfileImageView.frame.width / 2
        userProfileImageView.clipsToBounds = true
        userProfileImageView.image = UIImage(named: "user_placeholder")
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        loadingIndicator.style = .large
        
        playButton.isHidden = true
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        playButton.layer.cornerRadius = 30
        playButton.layer.masksToBounds = true
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.isUserInteractionEnabled = true
        
        storieDetailsLabel.textColor = .white
        storieDetailsLabel.numberOfLines = 2
        storieDetailsLabel.isUserInteractionEnabled = true
        
        setupSlider()
    }
    
    // MARK: - Video Playback Methods
    func playVideo() {
        print("▶️ playVideo() called - isVideoPlaying: \(isVideoPlaying), isPlayerReady: \(isPlayerReady)")
        
        guard let player = player else {
            print("❌ Cannot play: player is nil")
            return
        }
        
        if !isVideoPlaying {
            if isPlayerReady {
                print("🎬 Starting playback")
                
                // Activate audio session
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to set audio session: \(error)")
                }
                
                storiesThumbImageView.isHidden = true
                player.play()
                player.volume = 1.0
                player.rate = getPlaybackRate()
                isVideoPlaying = true
                
                // FIX: Update play button icon to pause IMMEDIATELY
                playButton.setImage(UIImage(named: "pause"), for: .normal)
                
                // Show controls briefly
                showControls()
                startControlsHideTimer()
            } else {
                print("⏳ Player not ready yet, marking for auto-play")
                shouldAutoPlay = true
                storiesThumbImageView.isHidden = false
                playButton.setImage(UIImage(named: "play"), for: .normal) // Keep play icon
                showControls()
            }
        } else {
            print("⚠️ Video is already playing")
        }
    }

    func pauseVideo() {
        print("⏸️ pauseVideo() called - isVideoPlaying: \(isVideoPlaying)")
        
        guard let player = player else {
            print("❌ Cannot pause: player is nil")
            return
        }
        
        if isVideoPlaying {
            print("🛑 Pausing video")
            player.pause()
            player.volume = 0.0
            isVideoPlaying = false
            shouldAutoPlay = false
            
            // FIX: Update play button icon to play IMMEDIATELY
            playButton.setImage(UIImage(named: "play"), for: .normal)
            
            // Deactivate audio session
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
            
            // Show controls permanently when paused
            showControlsPermanently()
        } else {
            print("⚠️ Video is already paused")
            // Still update the button to show play icon
            playButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    // MARK: - Public Methods for External Control
    func showPlayButton() {
        print("▶️ showPlayButton() called")
        playButton.isHidden = false
        playButton.setImage(UIImage(named: "play"), for: .normal)
        showControlsPermanently()
    }

    func hidePlayButton() {
        playButton.isHidden = true
    }
    func showPauseButton() {
        print("⏸️ showPauseButton() called")
        playButton.isHidden = false
        playButton.setImage(UIImage(named: "pause"), for: .normal)
        showControlsPermanently()
    }
    func playVideoIfReady() {
        print("🎯 playVideoIfReady() - isPlayerReady: \(isPlayerReady), isVideoPlaying: \(isVideoPlaying)")
        
        if isPlayerReady && !isVideoPlaying {
            playVideo()
        } else if !isPlayerReady {
            shouldAutoPlay = true
            showPlayButton() // Show play button while loading
        }
    }
    
    func stopVideo() {
        print("⏹️ stopVideo() called")
        
        pauseVideo()
        
        // Reset to beginning
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        videoSlider.value = 0
        startDurationLabel.text = "0:00"
        currentVideoProgress = 0.0
    }
    
    // MARK: - Controls Management
    
    private func showControls() {
        print("👁️ showControls()")
        playButton.isHidden = false
        
        if storiesPlayingViewType == .isOpenAllStoriesEpisods {
            videoSliderView.isHidden = false
        }
        
        isControlsVisible = true
    }
    
    private func hideControls() {
        print("🙈 hideControls() - isVideoPlaying: \(isVideoPlaying)")
        
        if isVideoPlaying {
            playButton.isHidden = true
            
            if storiesPlayingViewType == .isOpenAllStoriesEpisods {
                videoSliderView.isHidden = true
            }
            
            isControlsVisible = false
        }
        
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
    }
    
    private func showControlsPermanently() {
        print("👁️ showControlsPermanently()")
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        
        playButton.isHidden = false
        
        if storiesPlayingViewType == .isOpenAllStoriesEpisods {
            videoSliderView.isHidden = false
        }
        
        isControlsVisible = true
    }
    
    private func toggleControls() {
        if isControlsVisible {
            hideControls()
        } else {
            showControls()
            startControlsHideTimer()
        }
    }
    
    private func startControlsHideTimer() {
        guard isVideoPlaying else { return }
        
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: controlsHideDelay, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }
    
    private func resetControlsHideTimer() {
        if isVideoPlaying && isControlsVisible {
            startControlsHideTimer()
        }
    }
    
    // MARK: - Configuration Methods
    
    func configureWithDrama(drama: DramaItem, viewType: StoriesPlayingViewTypes, allEpisodes: [EpisodeItem] = []) {
        print("🎬 configureWithDrama called for: \(drama.dramaName ?? "Unknown")")
        
        // Clean up previous player first
        completelyCleanupPlayer()
        
        currentDrama = drama
        self.allEpisodesForDrama = allEpisodes
        updateUIForViewType(viewType)
        self.storiesPlayingViewType = viewType
        
        if viewType == .isOpenStories {
            userNameLabel.text = drama.dramaName ?? "Unknown"
            
            if let dDesc = drama.dDesc, !dDesc.isEmpty {
                storieDetailsLabel.text = dDesc
            } else {
                storieDetailsLabel.text = drama.dramaName ?? "No description available"
            }
            
            if let imageUrl = drama.imageUrl, let url = URL(string: imageUrl) {
                storiesThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "video_placeholder"))
                userProfileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "user_placeholder"))
            }
            
            self.allEpisodes = allEpisodes
        }
        
        isStoryDetailsExpanded = false
        updateStoryDetailsLabel()
        
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.isHidden = true
        isVideoPlaying = false
        
        setupVideoPlayerWithDrama(drama: drama)
    }
    
    func configureWithEpisode(episode: EpisodeItem, viewType: StoriesPlayingViewTypes, dramaName: String? = nil, allEpisodes: [EpisodeItem] = [], currentIndex: Int = 0) {
        print("🎬 configureWithEpisode called for: \(episode.dName)")
        
        // Clean up previous player first
        completelyCleanupPlayer()
        
        currentEpisode = episode
        self.allEpisodes = allEpisodes
        self.selectedEpisodeIndex = currentIndex
        self.storiesPlayingViewType = viewType
        self.isSubscribed = Subscribe.get()
        
        updateUIForViewType(viewType)
        
        if viewType == .isOpenAllStoriesEpisods {
            navigationTitleLabel.text = dramaName ?? episode.dName
            userNameLabel.text = episode.dName
            
            if !episode.thumbnails.isEmpty, let url = URL(string: episode.thumbnails) {
                storiesThumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "video_placeholder"))
            }
            
            if !episode.dImage.isEmpty, let url = URL(string: episode.dImage) {
                userProfileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "user_placeholder"))
            }
            
            let isSaved = LocalStorageManager.shared.isEpisodeSaved(episodeId: episode.epiId)
            updateSaveButtonState(isSaved: isSaved)
        } else {
            saveButton.isHidden = true
        }
        
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.isHidden = true
        isVideoPlaying = false
        
        setupVideoPlayerWithEpisode(episode: episode)
    }
    
    func updateSaveButtonState(isSaved: Bool) {
        let imageName = isSaved ? "save_Stories_selected" : "save_Stories_unselected"
        saveButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func updateUIForViewType(_ viewType: StoriesPlayingViewTypes) {
        switch viewType {
        case .isOpenStories:
            appTitleHeaderView.isHidden = false
            navigationTitleView.isHidden = true
            userProfieInfoView.isHidden = false
            storieDetailsLabel.isHidden = false
            enjoyFullStoriesView.isHidden = false
            videoSliderView.isHidden = true
            saveButton.isHidden = true
            
            videoSliderViewHeightConstant.constant = 0
            storieDetailsLabelHeightConstraint.constant = 34
            
        case .isOpenAllStoriesEpisods:
            appTitleHeaderView.isHidden = true
            navigationTitleView.isHidden = false
            userProfieInfoView.isHidden = false
            videoSliderView.isHidden = false
            storieDetailsLabel.isHidden = true
            enjoyFullStoriesView.isHidden = true
            saveButton.isHidden = false
            
            fullStoryViewHeightConstant.constant = 0
            storieDetailsLabelHeightConstraint.constant = 0
            videoSliderViewHeightConstant.constant = 70
        }
    }
    
    // MARK: - Player Setup
    
    private func setupVideoPlayerWithDrama(drama: DramaItem) {
        guard let videoUrlString = drama.epiUrl, !videoUrlString.isEmpty,
              let url = URL(string: videoUrlString) else {
            print("❌ No video URL for drama")
            storiesThumbImageView.isHidden = false
            playButton.isHidden = true
            return
        }
        
        setupPlayer(with: url)
    }
    
    private func setupVideoPlayerWithEpisode(episode: EpisodeItem) {
        var videoUrlString = ""
        switch selectedQualityIndex {
        case 0:
            videoUrlString = episode.video240p
        case 1:
            videoUrlString = episode.video480p
        case 2:
            videoUrlString = episode.noSub720p.isEmpty ? episode.video720p : episode.noSub720p
        default:
            videoUrlString = episode.noSub720p.isEmpty ? episode.video720p : episode.noSub720p
        }
        
        guard !videoUrlString.isEmpty, let url = URL(string: videoUrlString) else {
            print("❌ No video URL for episode")
            storiesThumbImageView.isHidden = false
            playButton.isHidden = true
            return
        }
        
        setupPlayer(with: url)
    }
    
    private func setupPlayer(with url: URL) {
        print("🎬 setupPlayer() called with URL: \(url)")
        
        showLoading()
        isPlayerReady = false
        shouldAutoPlay = false
        
        // Clean up existing player
        completelyCleanupPlayer()
        
        // Create AVAsset and player item
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
        
        // Setup player layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = mainView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let layer = playerLayer {
            mainView.layer.insertSublayer(layer, below: storiesThumbImageView.layer)
        }
        
        // Add time observer for slider
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateSliderPosition()
            self?.updateDurationLabels()
        }
        
        // Setup observers using modern KVO
        setupObservers()
        
        // Add notification for video end
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(videoDidEnd),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: playerItem)
        
        print("✅ Player setup complete")
    }
    
    private func setupObservers() {
        // Remove existing observers first
        playerItemStatusObserver?.invalidate()
        playerItemDurationObserver?.invalidate()
        
        // Add status observer
        playerItemStatusObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handlePlayerStatusChange(status: item.status)
            }
        }
        
        // Add duration observer
        playerItemDurationObserver = playerItem?.observe(\.duration, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateDurationLabels()
            }
        }
    }
    
    private func handlePlayerStatusChange(status: AVPlayerItem.Status) {
        print("🎬 Player status: \(status.rawValue)")
        
        switch status {
        case .readyToPlay:
            print("✅ Video is ready to play")
            isPlayerReady = true
            hideLoading()
            playButton.isHidden = false
            playButton.setImage(UIImage(named: "play"), for: .normal)
            
            if shouldAutoPlay && !isVideoPlaying {
                print("🎯 Auto-playing video")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.playVideo()
                }
            }
            
            updateDurationLabels()
            
        case .failed:
            print("❌ Video failed to load: \(playerItem?.error?.localizedDescription ?? "Unknown error")")
            isPlayerReady = false
            hideLoading()
            storiesThumbImageView.isHidden = false
            playButton.isHidden = true
            
        case .unknown:
            print("❓ Video status unknown")
            isPlayerReady = false
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Player Cleanup
    
    private func completelyCleanupPlayer() {
        print("🧹 Cleaning up player completely") 
        
        // Invalidate timers
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
        
        // Remove time observer safely
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        // Remove notifications
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Invalidate KVO observers
        playerItemStatusObserver?.invalidate()
        playerItemDurationObserver?.invalidate()
        playerItemStatusObserver = nil
        playerItemDurationObserver = nil
        
        // Pause and reset player
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        
        // Remove player layer
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        // Clear references
        player = nil
        playerItem = nil
        
        print("✅ Player cleanup complete")
    }
    
    // MARK: - Playback Controls
    
    private func updateSliderPosition() {
        guard let player = player,
              let playerItem = player.currentItem else {
            videoSlider.value = 0
            currentVideoProgress = 0.0
            return
        }
        
        let duration = playerItem.duration
        guard CMTimeGetSeconds(duration).isFinite && !duration.isIndefinite && CMTimeGetSeconds(duration) > 0 else {
            videoSlider.value = 0
            currentVideoProgress = 0.0
            return
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let totalDuration = CMTimeGetSeconds(duration)
        
        currentVideoProgress = currentTime / totalDuration
        videoSlider.value = Float(currentVideoProgress)
    }
    
    private func updateDurationLabels() {
        guard let player = player,
              let playerItem = player.currentItem else {
            startDurationLabel.text = "0:00"
            endDurationLabel.text = "0:00"
            return
        }
        
        let duration = playerItem.duration
        guard CMTimeGetSeconds(duration).isFinite && !duration.isIndefinite && CMTimeGetSeconds(duration) > 0 else {
            startDurationLabel.text = "0:00"
            endDurationLabel.text = "0:00"
            return
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        startDurationLabel.text = formatTime(currentTime)
        
        let totalDuration = CMTimeGetSeconds(duration)
        endDurationLabel.text = formatTime(totalDuration)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else {
            return "0:00"
        }
        
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func getPlaybackRate() -> Float {
        switch selectedSpeedIndex {
        case 0: return 0.75
        case 1: return 1.0
        case 2: return 1.5
        case 3: return 2.0
        default: return 1.0
        }
    }
    
    // MARK: - Loading
    
    private func showLoading() {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        playButton.isHidden = true
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    // MARK: - Button Actions Setup
    
    private func setupButtonActions() {
        enjoyFullStoriesButton.addTarget(self, action: #selector(enjoyFullStoriesTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playButtonAction(_:)), for: .touchUpInside)
        allEpisodsButton.addTarget(self, action: #selector(allEpisodsViewButtonAction), for: .touchUpInside)
    }
    
    private func setupGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        mainView.addGestureRecognizer(singleTapGesture)
        mainView.isUserInteractionEnabled = true
        
        let detailsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleStoryDetailsTap))
        storieDetailsLabel.addGestureRecognizer(detailsTapGesture)
    }
    
    private func setupSlider() {
        videoSlider.minimumTrackTintColor = .white
        videoSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        videoSlider.minimumValue = 0
        videoSlider.maximumValue = 1
        
        let thumbSize: CGFloat = 20
        let thumbImage = createThumbImage(size: thumbSize, color: .white)
        videoSlider.setThumbImage(thumbImage, for: .normal)
        videoSlider.setThumbImage(thumbImage, for: .highlighted)
        
        videoSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    private func createThumbImage(size: CGFloat, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.black.withAlphaComponent(0.3).setFill()
            let innerSize = size - 6
            context.cgContext.fillEllipse(in: CGRect(x: 3, y: 3, width: innerSize, height: innerSize))
        }
    }
    
    private func setupStoryDetailsLabel() {
        updateStoryDetailsLabel()
    }
    
    private func updateStoryDetailsLabel() {
        guard let text = storieDetailsLabel.text else {
            storieDetailsLabelHeightConstraint.constant = 0
            return
        }
        
        if isStoryDetailsExpanded {
            storieDetailsLabel.numberOfLines = 0
            storieDetailsLabelHeightConstraint.constant = calculateLabelHeight(for: text, width: storieDetailsLabel.frame.width)
        } else {
            storieDetailsLabel.numberOfLines = 2
            storieDetailsLabelHeightConstraint.constant = calculateLabelHeight(for: text, width: storieDetailsLabel.frame.width, maxLines: 2)
        }
    }
    
    private func calculateLabelHeight(for text: String, width: CGFloat, maxLines: Int = 0) -> CGFloat {
        let label = UILabel()
        label.numberOfLines = maxLines
        label.font = storieDetailsLabel.font
        label.text = text
        
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let requiredSize = label.sizeThatFits(maxSize)
        return requiredSize.height
    }
    
    // MARK: - Popup Methods
    private func presentEpisodesBottomSheet() {
        print("=== Presenting Episodes Bottom Sheet ===")
        
        pauseVideo()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let episodesVC = storyboard.instantiateViewController(withIdentifier: "EpisodesViewBottomPopUp") as? EpisodesViewBottomPopUp else {
            print("Failed to instantiate EpisodesViewBottomPopUp")
            return
        }
        
        let userImageUrl = currentDrama?.imageUrl ?? currentEpisode?.dImage
        let episodesToShow = allEpisodesForDrama.isEmpty ? allEpisodes : allEpisodesForDrama
        
        episodesVC.configure(
            allEpisodes: episodesToShow,
            selectedEpisodeIndex: selectedEpisodeIndex,
            userName: currentDrama?.dramaName ?? currentEpisode?.dName ?? "Unknown",
            userImageUrl: userImageUrl,
            isSubscribed: isSubscribed,
            viewType: storiesPlayingViewType
        )
        
        episodesVC.episodeSelectedHandler = { [weak self] selectedEpisode in
            print("🎯 Episode selected from popup: \(selectedEpisode.epiName)")
            
            // Update the current index based on the selected episode
            if let episodes = self?.allEpisodes,
               let index = episodes.firstIndex(where: { $0.epiId == selectedEpisode.epiId }) {
                self?.selectedEpisodeIndex = index
                print("✅ Updated selectedEpisodeIndex to: \(index)")
            }
            
            // Store the selected episode for external use
            self?.currentEpisode = selectedEpisode
            
            // Notify parent about episode selection
            self?.episodeSelectedHandler?(selectedEpisode)
            
            // DO NOT auto-play immediately - let parent handle it
            // This prevents the play button icon flicker issue
        }
        
        // Add handler for premium subscription
        episodesVC.premiumSubscriptionHandler = { [weak self] in
            print("Opening premium subscription screen from cell")
            self?.openPremiumSubscriptionScreen()
        }
        
        episodesVC.closeHandler = { [weak self] in
            guard let self = self else { return }
            if self.isVideoPlaying {
                self.startControlsHideTimer()
            } else {
                self.showControlsPermanently()
            }
        }
        
        let showAnimation = ActionSheetShowAnimation()
        showAnimation.duration = 0.3
        showAnimation.springWithDamping = 0.8
        
        let dismissAnimation = ActionSheetDismissAnimation()
        dismissAnimation.duration = 0.2
        
        episodesVC.showAnimation = showAnimation
        episodesVC.dismissAnimation = dismissAnimation
        
        episodesPopup = episodesVC
        episodesVC.show()
    }

    private func openPremiumSubscriptionScreen() {
        print("📱 Opening Premium Subscription Screen from cell")
        
        // Pause any currently playing video
        pauseVideo()
        
        // Notify parent to handle premium VC opening
        // You might need to add this handler:
        // var premiumSubscriptionHandler: (() -> Void)?
        // premiumSubscriptionHandler?()
        
        // Alternative: Find the parent view controller
        if let parentVC = self.findViewController() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let premiumVC = storyboard.instantiateViewController(withIdentifier: "PremiumVC") as? PremiumVC {
                premiumVC.modalPresentationStyle = .fullScreen
                premiumVC.modalTransitionStyle = .coverVertical
                parentVC.present(premiumVC, animated: true, completion: nil)
            }
        }
    }
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    func presentSpeedSettingsBottomSheet() {
        print("=== Presenting Speed Settings Bottom Sheet ===")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let speedVC = storyboard.instantiateViewController(withIdentifier: "SpeedSetBottomPopUp") as? SpeedSetBottomPopUp else {
            print("Failed to instantiate SpeedSetBottomPopUp")
            return
        }
        
        speedVC.configure(
            selectedSpeedIndex: selectedSpeedIndex,
            selectedQualityIndex: selectedQualityIndex
        )
        
        speedVC.speedChangeHandler = { [weak self] newSpeedIndex in
            self?.selectedSpeedIndex = newSpeedIndex
            self?.updatePlaybackSpeed()
        }
        
        speedVC.qualityChangeHandler = { [weak self] newQualityIndex in
            self?.selectedQualityIndex = newQualityIndex
            self?.updateVideoQuality()
        }
        
        speedVC.closeHandler = { [weak self] in
            guard let self = self else { return }
            if self.isVideoPlaying {
                self.startControlsHideTimer()
            }
        }
        
        let showAnimation = ActionSheetShowAnimation()
        showAnimation.duration = 0.3
        showAnimation.springWithDamping = 0.8
        
        let dismissAnimation = ActionSheetDismissAnimation()
        dismissAnimation.duration = 0.2
        
        speedVC.showAnimation = showAnimation
        speedVC.dismissAnimation = dismissAnimation
        
        speedPopup = speedVC
        speedVC.show()
    }
    
    private func updatePlaybackSpeed() {
        guard let player = player else { return }
        
        player.rate = getPlaybackRate()
    }
    
    private func updateVideoQuality() {
        guard let episode = currentEpisode else { return }
        
        var videoUrlString = ""
        switch selectedQualityIndex {
        case 0:
            videoUrlString = episode.video240p
        case 1:
            videoUrlString = episode.video480p
        case 2:
            videoUrlString = episode.noSub720p.isEmpty ? episode.video720p : episode.noSub720p
        default:
            videoUrlString = episode.noSub720p.isEmpty ? episode.video720p : episode.noSub720p
        }
        
        if !videoUrlString.isEmpty, let url = URL(string: videoUrlString) {
            switchToNewVideo(url: url)
        }
    }
    
    private func switchToNewVideo(url: URL) {
        print("🔄 Switching to new video URL: \(url)")
        
        let wasPlaying = isVideoPlaying
        
        pauseVideo()
        
        // Setup new player with the new URL
        setupPlayer(with: url)
        
        // Resume playback if it was playing
        if wasPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.playVideo()
            }
        }
    }
    
    // MARK: - Button Action Handlers
    
    @objc private func togglePlayPause() {
        if isVideoPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
        
        resetControlsHideTimer()
    }
    
    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // Check if tap is on interactive elements
        let interactiveElements: [UIView?] = [playButton, shareButton, saveButton, backButton, moreButton, allEpisodsButton, enjoyFullStoriesButton]
        
        for element in interactiveElements {
            guard let element = element else { continue }
            let frame = element.convert(element.bounds, to: self)
            if frame.contains(location) {
                return
            }
        }
        
        if isVideoPlaying {
            toggleControls()
        } else {
            showControlsPermanently()
        }
    }
    
    @objc private func handleStoryDetailsTap() {
        isStoryDetailsExpanded = !isStoryDetailsExpanded
        updateStoryDetailsLabel()
        storyDetailsTappedHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func enjoyFullStoriesTapped() {
        enjoyFullStoriesHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func shareButtonTapped() {
        shareHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func saveButtonTapped() {
        saveHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func backButtonTapped() {
        print("🔙 Back button tapped")
        
        pauseVideo()
        completelyCleanupPlayer()
        
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.isHidden = true
        storiesThumbImageView.isHidden = false
        
        backButtonHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func moreButtonTapped() {
        moreButtonHandler?()
        resetControlsHideTimer()
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let player = player,
              let playerItem = player.currentItem else { return }
        
        let duration = playerItem.duration
        guard CMTimeGetSeconds(duration).isFinite && !duration.isIndefinite && CMTimeGetSeconds(duration) > 0 else { return }
        
        let totalDuration = CMTimeGetSeconds(duration)
        let targetTime = Double(sender.value) * totalDuration
        let seekTime = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
        startDurationLabel.text = formatTime(targetTime)
        resetControlsHideTimer()
    }
    
    @objc private func videoDidEnd() {
        print("🏁 Video did end")
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        isVideoPlaying = false
        playButton.setImage(UIImage(named: "play"), for: .normal)
        videoSlider.value = 0
        startDurationLabel.text = "0:00"
        showControlsPermanently()
        controlsHideTimer?.invalidate()
        controlsHideTimer = nil
    }
    
    // MARK: - Public Button Actions
    
    @IBAction func allEpisodsViewButtonAction(_ sender: UIButton) {
        presentEpisodesBottomSheet()
        resetControlsHideTimer()
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton) {
        shareHandler?()
        resetControlsHideTimer()
    }
    
    @IBAction func saveButtonAction(_ sender: UIButton) {
        guard let episode = currentEpisode, storiesPlayingViewType == .isOpenAllStoriesEpisods else { return }
        
        let isCurrentlySaved = LocalStorageManager.shared.isEpisodeSaved(episodeId: episode.epiId)
        
        if isCurrentlySaved {
            LocalStorageManager.shared.removeSavedEpisode(episodeId: episode.epiId)
            updateSaveButtonState(isSaved: false)
        } else {
            let success = LocalStorageManager.shared.saveEpisode(episode)
            updateSaveButtonState(isSaved: success)
        }
        
        saveHandler?()
        resetControlsHideTimer()
    }
    
    @IBAction func moreButtonAction(_ sender: UIButton) {
        presentSpeedSettingsBottomSheet()
        resetControlsHideTimer()
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        print("🎮 Play button tapped - isVideoPlaying: \(isVideoPlaying)")
        
        // Call the external handler if set (this takes priority)
        if let handler = playButtonHandler {
            print("📞 Calling external playButtonHandler")
            handler()
            return
        }
        
        // Default behavior if no external handler
        print("⚙️ Using default play button behavior")
        togglePlayPause()
    }
    // Add these methods to StoriesPlayingCell:
    func updatePlayButtonState() {
        if isVideoPlaying {
            showPauseButton()
        } else {
            showPlayButton()
        }
    }
    
    func getCurrentVideoProgress() -> Double {
        return currentVideoProgress
    }
}

// MARK: - UIGestureRecognizerDelegate
extension StoriesPlayingCell {
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        
        let interactiveElements: [UIView?] = [playButton, shareButton, saveButton, backButton, moreButton, allEpisodsButton, enjoyFullStoriesButton]
        
        for element in interactiveElements {
            guard let element = element else { continue }
            let frame = element.convert(element.bounds, to: self)
            if frame.contains(location) {
                return false
            }
        }
        
        return true
    }
}

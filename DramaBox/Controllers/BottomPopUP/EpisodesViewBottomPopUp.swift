//
//  EpisodesViewBottomPopUp.swift
//  DramaBox
//
//  Created by DREAMWORLD on 11/12/25.
//

import UIKit
import SDWebImage
import SwiftPopup

class EpisodesViewBottomPopUp: SwiftPopup {
    
    // MARK: - Configuration Properties
    private var configuration: Configuration?
    
    private struct Configuration {
        let allEpisodes: [EpisodeItem]
        let selectedEpisodeIndex: Int
        let userName: String?
        let userImageUrl: String?
        let isSubscribed: Bool
        let viewType: StoriesPlayingViewTypes
    }
    
    // MARK: - Instance Properties
    private var allEpisodes: [EpisodeItem] = []
    private var selectedEpisodeIndex: Int = 0
    private var isSubscribed: Bool = true
    private var storiesPlayingViewType: StoriesPlayingViewTypes = .isOpenStories
    
    // MARK: - IBOutlets
    @IBOutlet weak var allEpisodsView: UIView!
    @IBOutlet weak var allEpisodsUserProfileImageView: UIImageView!
    @IBOutlet weak var allEpisodsUserNameLabel: UILabel!
    @IBOutlet weak var allEpisodsPopUpViewCloseButton: UIButton!
    @IBOutlet weak var totalEpisodsCountTitleLabel: UILabel!
    @IBOutlet weak var allEpisodsCollectionView: UICollectionView!
    @IBOutlet weak var allEpisodsStartToEndCountLabel: UILabel!
    
    // MARK: - Handlers
    var episodeSelectedHandler: ((EpisodeItem) -> Void)?
    var closeHandler: (() -> Void)?
    var premiumSubscriptionHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("EpisodesViewBottomPopUp viewDidLoad called")
        
        setupUI()
        setupCollectionView()
        setupButtonActions()
        
        // Apply configuration if it exists
        if let config = configuration {
            applyConfiguration(config)
            configuration = nil // Clear after applying
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("EpisodesViewBottomPopUp viewWillAppear called")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("EpisodesViewBottomPopUp viewDidAppear called")
    }
    
    // MARK: - Configuration
    func configure(
        allEpisodes: [EpisodeItem],
        selectedEpisodeIndex: Int,
        userName: String?,
        userImageUrl: String?,
        isSubscribed: Bool,
        viewType: StoriesPlayingViewTypes
    ) {
        print("Configure called - view is loaded: \(isViewLoaded)")
        
        // Store configuration
        self.configuration = Configuration(
            allEpisodes: allEpisodes,
            selectedEpisodeIndex: selectedEpisodeIndex,
            userName: userName,
            userImageUrl: userImageUrl,
            isSubscribed: isSubscribed,
            viewType: viewType
        )
        
        // If view is already loaded, apply configuration immediately
        if isViewLoaded {
            if let config = self.configuration {
                applyConfiguration(config)
                self.configuration = nil
            }
        }
    }
    
    private func applyConfiguration(_ config: Configuration) {
        print("Applying configuration...")
        
        self.allEpisodes = config.allEpisodes
        self.selectedEpisodeIndex = config.selectedEpisodeIndex
        self.isSubscribed = config.isSubscribed
        self.storiesPlayingViewType = config.viewType
        
        // Set user info
        allEpisodsUserNameLabel.text = config.userName ?? "Unknown"
        
        // Set user profile image
        if let imageUrl = config.userImageUrl, let url = URL(string: imageUrl) {
            allEpisodsUserProfileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "user_placeholder"))
        } else {
            allEpisodsUserProfileImageView.image = UIImage(named: "user_placeholder")
        }
        
        // Set total episodes count
        let totalEpisodes = config.allEpisodes.count
        let attributedString = NSMutableAttributedString(string: "Total \(totalEpisodes) Episodes")
        let range = (attributedString.string as NSString).range(of: "\(totalEpisodes)")
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: range)
        totalEpisodsCountTitleLabel.attributedText = attributedString
        
        // Set start to end count
        allEpisodsStartToEndCountLabel.text = "1-\(totalEpisodes)"
        
        // Reload collection view
        allEpisodsCollectionView.reloadData()
        
        // Scroll to current episode
        if config.selectedEpisodeIndex < config.allEpisodes.count {
            let indexPath = IndexPath(item: config.selectedEpisodeIndex, section: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.allEpisodsCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            }
        }
        
        print("Configuration applied successfully")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Style the container view
        allEpisodsView.layer.cornerRadius = 40
        allEpisodsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        allEpisodsView.clipsToBounds = true
        
        // Setup user profile image
        allEpisodsUserProfileImageView.layer.cornerRadius = allEpisodsUserProfileImageView.frame.width / 2
        allEpisodsUserProfileImageView.clipsToBounds = true
        allEpisodsUserProfileImageView.contentMode = .scaleAspectFill
        
        // Add tap gesture to close when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupCollectionView() {
        allEpisodsCollectionView.delegate = self
        allEpisodsCollectionView.dataSource = self
        
        // Register cell
        let nib = UINib(nibName: "EpisodesListCell", bundle: nil)
        allEpisodsCollectionView.register(nib, forCellWithReuseIdentifier: "EpisodesListCell")
        
        allEpisodsCollectionView.backgroundColor = .clear
        
        // Setup flow layout for vertical scrolling with square cells
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 5
        allEpisodsCollectionView.collectionViewLayout = layout
        allEpisodsCollectionView.contentInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }
    
    private func setupButtonActions() {
        allEpisodsPopUpViewCloseButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        print("Close button tapped")
        closeHandler?()
        dismiss() // Use SwiftPopup's dismiss method
    }
    
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        // Check if tap is outside the content view
        if !allEpisodsView.frame.contains(location) {
            closeButtonTapped()
        }
    }
    
    // MARK: - Helper Methods
    private func debugOutlets() {
        print("=== DEBUG OUTLETS ===")
        print("allEpisodsView: \(allEpisodsView != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("allEpisodsUserProfileImageView: \(allEpisodsUserProfileImageView != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("allEpisodsUserNameLabel: \(allEpisodsUserNameLabel != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("allEpisodsPopUpViewCloseButton: \(allEpisodsPopUpViewCloseButton != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("totalEpisodsCountTitleLabel: \(totalEpisodsCountTitleLabel != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("allEpisodsCollectionView: \(allEpisodsCollectionView != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("allEpisodsStartToEndCountLabel: \(allEpisodsStartToEndCountLabel != nil ? "✅ CONNECTED" : "❌ NIL")")
        print("=== END DEBUG ===")
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension EpisodesViewBottomPopUp: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allEpisodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EpisodesListCell", for: indexPath) as! EpisodesListCell
        
        let episodeNumber = indexPath.item + 1
        let isSelected = indexPath.item == selectedEpisodeIndex
        
        // Determine if cell should be premium/locked based on subscription status
        var isPremium = false
        var isLocked = false
        
        if !isSubscribed {
            // When NOT subscribed, only first 2 episodes (index 0 and 1) are unlocked
            isLocked = indexPath.item >= 2 // Lock all episodes after index 1
            isPremium = indexPath.item >= 2 // Premium episodes are those after index 1
        } else {
            // When subscribed, handle based on view type
            switch storiesPlayingViewType {
            case .isOpenStories:
                if indexPath.item >= 3 {
                    isPremium = true
                }
            case .isOpenAllStoriesEpisods:
                // When subscribed, all episodes are unlocked
                isPremium = false
                isLocked = false
            }
        }
        
        // Configure cell with premium/locked status
        cell.configure(isSelected: isSelected, isPremium: isPremium, episodeNumber: episodeNumber)
        
        // Additional: If you have a premium/lock image view in your EpisodesListCell
        // You can hide/show it based on the index
        if !isSubscribed {
            // Hide lock image for first 2 episodes, show for rest
            if indexPath.item < 2 {
                cell.isPremiumImageView?.isHidden = true // Assuming you have this property
                cell.isUserInteractionEnabled = true
            } else {
                cell.isPremiumImageView?.isHidden = false
                cell.isUserInteractionEnabled = false // Disable interaction for locked cells
            }
        } else {
            // When subscribed, hide lock image for all
            cell.isPremiumImageView?.isHidden = true
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionWidth = collectionView.frame.width
        let totalSpacing: CGFloat = (5 * 2) + (4 * 5)
        let availableWidth = collectionWidth - totalSpacing
        let cellWidth = availableWidth / 5
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("🔘 Episode tapped at index: \(indexPath.item), isSubscribed: \(isSubscribed)")
        
        // Check subscription status first
        if !isSubscribed {
            // When NOT subscribed, only allow selection of first 2 episodes (index 0 and 1)
            if indexPath.item >= 2 {
                print("🔒 Episode locked for non-subscribed user")
                
                // Notify parent to open premium VC
                DispatchQueue.main.async {
                    self.closeButtonTapped()
                    self.premiumSubscriptionHandler?()
                }
                return
            }
        } else {
            // When subscribed, handle based on view type
            switch storiesPlayingViewType {
            case .isOpenStories:
                if indexPath.item >= 3 {
                    print("🔒 Episode locked for subscribed user in stories mode")
                    DispatchQueue.main.async {
                        self.closeButtonTapped()
                        self.premiumSubscriptionHandler?()
                    }
                    return
                }
            case .isOpenAllStoriesEpisods:
                // When subscribed, all episodes are accessible
                print("✅ Episode accessible for subscribed user")
                break
            }
        }
        
        // Allow selection - update selected index and notify handler
        selectedEpisodeIndex = indexPath.item
        collectionView.reloadData()
        
        // Get the selected episode
        guard indexPath.item < allEpisodes.count else { return }
        let selectedEpisode = allEpisodes[indexPath.item]
        
        // Notify about episode selection
        episodeSelectedHandler?(selectedEpisode)
        
        // Close popup after selection
        closeButtonTapped()
    }

    // Add this new method to handle premium screen opening
    private func openPremiumSubscriptionScreen() {
        // Create a delegate or handler to communicate with parent
        // You'll need to add this handler to your class
        premiumSubscriptionHandler?()
        
        // Or if you have a direct reference to parent:
        // parentViewController?.openPremiumScreen()
    }
    
    // MARK: - Helper Methods for Subscription
    private func showSubscriptionPrompt() {
        // You can implement your subscription prompt logic here
        // For example, show an alert or present a subscription view
        let alert = UIAlertController(
            title: "Premium Episode",
            message: "Subscribe to access this episode and all premium content.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Subscribe", style: .default, handler: { _ in
            // Navigate to subscription screen
            self.handleSubscribeAction()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func handleSubscribeAction() {
        // Handle subscription flow
        // This would typically navigate to your subscription/payment screen
        print("Navigate to subscription screen")
        
        // Example: Dismiss popup and trigger subscription handler
        // closeButtonTapped()
        // subscriptionHandler?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension EpisodesViewBottomPopUp {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !allEpisodsView.frame.contains(location)
    }
}

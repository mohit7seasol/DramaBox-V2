//
//  RingtoneCategoriesVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 20/01/26.
//

import UIKit

class RingtoneCategoriesVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var ringtoneCategories: RingtoneResponse = []
    
    // ✅ ADD NATIVE AD PROPERTIES
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    var nativeAdContainerView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        subscribeNativeAd() // ✅ SUBSCRIBE TO NATIVE ADS
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setUpUI() {
        self.titleLabel.text = "Music".localized(LocalizationService.shared.language)
        if ringtoneCategories.isEmpty {
            self.collectionView.isHidden = true
            showEmptyState()
        } else {
            self.collectionView.isHidden = false
            hideEmptyState()
        }
        setUpCollectionView()
    }
    
    // ✅ ADD NATIVE AD SUBSCRIPTION METHOD
    func subscribeNativeAd() {
        // Check subscription status
        guard Subscribe.get() == false else {
            self.isShowNativeAds = false
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            return
        }
        
        // User is not subscribed, show skeleton and load ad
        self.nativeAdContainerView.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: 200
        )
        self.nativeAdContainerView.backgroundColor = UIColor.appAddBg
        self.isShowNativeAds = true
        
        HelperManager.showSkeleton(nativeAdView: self.nativeAdContainerView)
        
        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self = self else { return }
            
            print("✅ RingtoneCategoriesVC Native Ad Loaded")
            HelperManager.hideSkeleton(nativeAdView: self.nativeAdContainerView)
            
            // Configure the native ad container view
            self.nativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 200
            )
            
            // Remove old ad views
            self.nativeAdContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            self.googleNativeAds.showAdsView8(
                nativeAd: nativeAdsTemp,
                view: self.nativeAdContainerView
            )
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        googleNativeAds.failAds(self) { [weak self] fail in
            guard let self = self else { return }
            
            print("❌ RingtoneCategoriesVC Native Ad Failed to Load")
            HelperManager.hideSkeleton(nativeAdView: self.nativeAdContainerView)
            self.isShowNativeAds = false
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.height))
        emptyLabel.text = "No categories available"
        emptyLabel.textColor = .white.withAlphaComponent(0.7)
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyLabel.alpha = 0
        
        collectionView.backgroundView = emptyLabel
        
        UIView.animate(withDuration: 0.3) {
            emptyLabel.alpha = 1
        }
    }
    
    private func hideEmptyState() {
        collectionView.backgroundView = nil
    }
    
    func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.bounces = true
        collectionView.contentInsetAdjustmentBehavior = .never
        
        // ✅ REGISTER NATIVE AD CELL
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "NativeAdCell")
        
        // Set up layout with 0 spacing
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0  // Zero spacing between rows
        layout.minimumInteritemSpacing = 0  // Zero spacing between columns
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)  // Zero inset on all sides
        
        collectionView.collectionViewLayout = layout
        
        // Register category cell
        collectionView.register(["RingtoneCateCell"])
        collectionView.reloadData()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension RingtoneCategoriesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // ✅ UPDATE TO 2 SECTIONS
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Section 0: Native Ad, Section 1: Ringtone Categories
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            // Native Ad Section - show only if ads are enabled
            return isShowNativeAds ? 1 : 0
        } else {
            // Ringtone Categories Section
            return ringtoneCategories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            // ✅ NATIVE AD CELL
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NativeAdCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            
            // Remove old ad views before adding new
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Configure the native ad container view
            nativeAdContainerView.frame = CGRect(
                x: 0,
                y: 0,
                width: collectionView.frame.width,
                height: 200
            )
            
            // Ensure nativeAdContainerView is properly configured
            nativeAdContainerView.backgroundColor = UIColor.appAddBg
            nativeAdContainerView.isHidden = !isShowNativeAds
            
            cell.contentView.addSubview(nativeAdContainerView)
            
            return cell
        } else {
            // ✅ RINGTONE CATEGORY CELL
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RingtoneCateCell", for: indexPath) as? RingtoneCateCell ?? RingtoneCateCell()
            
            let category = ringtoneCategories[indexPath.item]
            cell.configure(with: category)
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        
        if indexPath.section == 0 {
            // ✅ NATIVE AD CELL SIZE
            return CGSize(width: screenWidth, height: isShowNativeAds ? 200 : 0)
        } else {
            // ✅ RINGTONE CATEGORY CELL SIZE
            let itemHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 60
            return CGSize(width: screenWidth, height: itemHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // ✅ DON'T ALLOW SELECTION OF NATIVE AD CELL
        if indexPath.section == 0 {
            return
        }
        
        // Add selection animation
        if let cell = collectionView.cellForItem(at: indexPath) as? RingtoneCateCell {
            cell.animateSelection()
        }
        
        // Delay navigation to show animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let category = self.ringtoneCategories[indexPath.item]
            self.navigateToRingtonesList(for: category)
        }
    }
    
    // ✅ ADD SPACING BETWEEN SECTIONS
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            // Native Ad Section - no insets
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            // Ringtone Categories Section - add some spacing after native ad
            return UIEdgeInsets(top: isShowNativeAds ? 10 : 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    private func navigateToRingtonesList(for category: RingtoneCategory) {
        print("Selected category: \(category.category)")
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "RingtoneListVC") as? RingtoneListVC {
            vc.selectedCategory = category
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

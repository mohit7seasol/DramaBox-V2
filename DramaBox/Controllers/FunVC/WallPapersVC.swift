//
//  WallPapersVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 17/01/26.
//

import UIKit

class WallPapersVC: UIViewController {

    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    var contentItems: [String] = [] {
        didSet {
            itemsCollectionView?.reloadData()
        }
    }
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLbl.text = "Wallpapers".localized(LocalizationService.shared.language)
        setupCollectionViewUI()
        subscribeNativeAd()
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
    func setupCollectionViewUI() {
        setupCollectionViewLayout()
    }
    
    func setupCollectionViewLayout() {
        itemsCollectionView.delegate = self
        itemsCollectionView.dataSource = self
        itemsCollectionView.showsVerticalScrollIndicator = false
        itemsCollectionView.backgroundColor = .clear
        itemsCollectionView.bounces = true
        itemsCollectionView.collectionViewLayout = createGridLayout()

        // Register cell
        itemsCollectionView.register(["WallpaperCell"])
    }
    
    func createGridLayout() -> UICollectionViewLayout {
        let layout = DynamicGridLayout()
        layout.numberOfColumns = 2
        layout.cellSpacing = 8
        return layout
    }
    
    func refreshItemsView() {
        DispatchQueue.main.async {
            self.itemsCollectionView.reloadData()
        }
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension WallPapersVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contentItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WallpaperCell",
                                                     for: indexPath) as? WallpaperCell ?? WallpaperCell()
        
        if indexPath.row < contentItems.count {
            let itemURL = contentItems[indexPath.row]
            configureCollectionCell(cell, with: itemURL, at: indexPath)
        }
        
        return cell
    }
    
    func configureCollectionCell(_ cell: WallpaperCell, with itemURL: String, at indexPath: IndexPath) {
        cell.configure(with: itemURL)
        cell.setOnClickListener {
            self.handleItemSelected(at: indexPath)
        }
    }
    
    func handleItemSelected(at indexPath: IndexPath) {
        guard indexPath.row < contentItems.count else { return }
        
        let selectedItem = contentItems[indexPath.row]
        navigateToItemDetails(with: selectedItem)
    }
    
    func navigateToItemDetails(with item: String) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        if let detailsController = storyboard.instantiateViewController(withIdentifier: "ViewWallPaperVC") as? ViewWallPaperVC {
            detailsController.wallPaperStr = item
            self.navigationController?.pushViewController(detailsController, animated: true)
        }
    }
}

class DynamicGridLayout: UICollectionViewFlowLayout {
    var numberOfColumns = 2
    var cellSpacing: CGFloat = 8
    private var layoutCache: [UICollectionViewLayoutAttributes] = []
    private var totalContentHeight: CGFloat = 0

    override func prepare() {
        guard layoutCache.isEmpty, let currentCollectionView = collectionView else { return }

        let availableWidth = currentCollectionView.bounds.width
        let totalSpacing = CGFloat(numberOfColumns + 1) * cellSpacing
        let columnWidth = (availableWidth - totalSpacing) / CGFloat(numberOfColumns)
        
        let xPositions = (0..<numberOfColumns).map {
            CGFloat($0) * (columnWidth + cellSpacing) + cellSpacing
        }
        
        var yPositions = [CGFloat](repeating: cellSpacing, count: numberOfColumns)
        
        var currentColumnIndex = 0
        for itemIndex in 0..<currentCollectionView.numberOfItems(inSection: 0) {
            let itemPath = IndexPath(item: itemIndex, section: 0)
            let cellHeight = calculateCellHeight()
            
            let cellFrame = CGRect(x: xPositions[currentColumnIndex],
                                 y: yPositions[currentColumnIndex],
                                 width: columnWidth,
                                 height: cellHeight)
            
            let cellAttributes = UICollectionViewLayoutAttributes(forCellWith: itemPath)
            cellAttributes.frame = cellFrame
            layoutCache.append(cellAttributes)
            
            totalContentHeight = max(totalContentHeight, cellFrame.maxY)
            yPositions[currentColumnIndex] = yPositions[currentColumnIndex] + cellHeight + cellSpacing
            
            currentColumnIndex = currentColumnIndex < (numberOfColumns - 1) ? currentColumnIndex + 1 : 0
        }
    }
    
    func calculateCellHeight() -> CGFloat {
        return CGFloat.random(in: 200...300)
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0,
               height: totalContentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        layoutCache.filter { $0.frame.intersects(rect) }
    }
}

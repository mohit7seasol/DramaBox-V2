//
//  TitleHeaderCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit

enum TitleHeaderCellType: Int {
    case NewDramas, HotPicks
}

class TitleHeaderCell: UITableViewCell {

    @IBOutlet weak var titleHeaderLabel: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.backgroundColor = .clear
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
        }
    }
    
    private var type: TitleHeaderCellType = .NewDramas
    private var newDramas: [DramaItem] = []
    private var hotPicks: [DramaItem] = []
    private let gradientLayer = CAGradientLayer()
    var didSelectDrama: ((DramaItem) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        // Register cells
        let newDramaNib = UINib(nibName: "NewDramaCell", bundle: nil)
        collectionView.register(newDramaNib, forCellWithReuseIdentifier: "NewDramaCell")
        
        let hotPicksNib = UINib(nibName: "HotPicDataCell", bundle: nil)
        collectionView.register(hotPicksNib, forCellWithReuseIdentifier: "HotPicDataCell")
        
        setUICellUI()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }
    
    func setUICellUI() {
        self.viewAllButton.titleLabel?.font = FontManager.shared.font(for: .roboto, size: 14.0)
        self.titleHeaderLabel.font = FontManager.shared.font(for: .roboto, size: 18.0)
    }
    
    func configure(type: TitleHeaderCellType, title: String) {
        self.type = type
        self.titleHeaderLabel.text = title
        self.titleHeaderLabel.textColor = .white

        if type == .HotPicks {
            applyHotPicksGradient()
        } else {
            removeGradient()
        }
    }
    
    private func applyHotPicksGradient() {
        gradientLayer.removeFromSuperlayer()

        gradientLayer.colors = [
            UIColor(hex: "#1C1323")!.cgColor,
            UIColor(hex: "#111111")!.cgColor
        ]

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)   // ✅ Top Center
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)   // ✅ Bottom Center
        gradientLayer.locations = [0, 1]

        gradientLayer.frame = contentView.bounds

        contentView.layer.insertSublayer(gradientLayer, at: 0)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    private func removeGradient() {
        gradientLayer.removeFromSuperlayer()
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    func loadNewDramas(_ dramas: [DramaItem]) {
        self.newDramas = Array(dramas.prefix(10))
        collectionView.reloadData()
    }
    
    func loadHotPicks(_ dramas: [DramaItem]) {
        self.hotPicks = dramas
        collectionView.reloadData()
    }
    
    func setCollectionViewLayout(
        itemWidth: CGFloat,
        itemHeight: CGFloat,
        scrollDirection: UICollectionView.ScrollDirection,
        isScrollEnabled: Bool = true
    ) {

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = scrollDirection
        
        layout.minimumInteritemSpacing = 0

        if scrollDirection == .vertical {
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            layout.minimumLineSpacing = 0
            // ✅ EXACT 5pt top & bottom
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: 0,
                right: 0
            )
        } else {
            layout.itemSize = CGSize(width: 136, height: itemHeight)
            layout.minimumLineSpacing = 15
            layout.sectionInset = UIEdgeInsets(
                top: 0,
                left: 10,
                bottom: 0,
                right: 10
            )
        }

        collectionView.collectionViewLayout = layout
        collectionView.isScrollEnabled = isScrollEnabled
        collectionView.reloadData()
    }
}

extension TitleHeaderCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch type {
        case .NewDramas: return newDramas.count
        case .HotPicks: return hotPicks.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch type {
        case .NewDramas:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewDramaCell", for: indexPath) as! NewDramaCell
            if indexPath.item < newDramas.count {
                let drama = newDramas[indexPath.item]
                cell.configure(with: drama)
                cell.setOnClickListener {
                    self.didSelectDrama?(drama)
                }
            }
            return cell
            
        case .HotPicks:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HotPicDataCell", for: indexPath) as! HotPicDataCell
            if indexPath.item < hotPicks.count {
                let drama = hotPicks[indexPath.item]
                cell.configure(with: drama, shouldAddGradient: false)
                cell.parentView.backgroundColor = .clear
                cell.setOnClickListener {
                    self.didSelectDrama?(drama)
                }
                // Add like count from drama data if available
                /* if let likeCount = hotPicks[indexPath.item].likeCount {
                    cell.likeCountLabel.text = "🔥 \(likeCount)"
                } else {
                    cell.likeCountLabel.text = "🔥 410.6K" // Default as per image
                } */
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch type {
        case .NewDramas:
            return CGSize(width: 136, height: 200)
        case .HotPicks:
            // Full width for Hot Picks (1 item per row)
            let collectionViewWidth = collectionView.frame.width  
            return CGSize(width: collectionViewWidth, height: 120)
        }
    }
}

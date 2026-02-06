//
//  CarouselTopCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit

class CarouselTopCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    private var popularDramas: [DramaItem] = []
    private var currentIndex = 0
    var didSelectDrama: ((DramaItem) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setCollection()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with dramas: [DramaItem]) {
        self.popularDramas = dramas
        self.collectionView.reloadData()
    }
    
    func scrollToNextItem() {
        guard !popularDramas.isEmpty else { return }
        
        currentIndex += 1
        if currentIndex >= popularDramas.count {
            currentIndex = 0
        }
        
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    private func setCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20 // Space between cells
        layout.itemSize = CGSize(width: collectionView.frame.width - 40, height: 180) // Full width minus side padding
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20) // 20px padding on both sides
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = false // Allow smooth scrolling
        
        // Register cell
        let nib = UINib(nibName: "CarouselDataCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "CarouselDataCell")
    }
}

extension CarouselTopCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return popularDramas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselDataCell", for: indexPath) as! CarouselDataCell
        let drama = popularDramas[indexPath.item]
        cell.configure(with: drama)
        
        cell.setOnClickListener {
            self.didSelectDrama?(drama)
        }
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentIndex()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentIndex()
    }
    
    private func updateCurrentIndex() {
        let center = CGPoint(x: collectionView.contentOffset.x + (collectionView.frame.width / 2),
                            y: collectionView.frame.height / 2)
        if let indexPath = collectionView.indexPathForItem(at: center) {
            currentIndex = indexPath.item
        }
    }
}

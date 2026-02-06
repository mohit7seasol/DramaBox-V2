//
//  NativeAdCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 17/10/25.
//

import UIKit

class NativeAdCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configure(with adContainerView: UIView) {
        // Clear existing subviews
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the ad container view
        adContainerView.frame = self.contentView.bounds
        adContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.addSubview(adContainerView)
    }
}

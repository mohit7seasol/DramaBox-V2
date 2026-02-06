//
//  SuggestStoriesCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 12/12/25.
//

import UIKit
import SDWebImage

class SuggestStoriesCell: UICollectionViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var cornerRadiusView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.image = nil
    }
    
    private func setupCellAppearance() {
        // Main image view styling
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        
        // Set corner radius like in the uploaded image
        previewImageView.layer.cornerRadius = 30
        
        // Optional: Add subtle border
        previewImageView.layer.borderWidth = 1
        previewImageView.layer.borderColor = UIColor(white: 0.2, alpha: 0.3).cgColor
        
        // Cell shadow
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.2
        self.layer.masksToBounds = false
        
        // For better performance
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func configure(with imageUrl: String?) {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            // Load image with SDWebImage
            previewImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "video_placeholder"),
                options: [.progressiveLoad, .scaleDownLargeImages]
            )
        } else {
            previewImageView.image = UIImage(named: "video_placeholder")
        }
    }
}

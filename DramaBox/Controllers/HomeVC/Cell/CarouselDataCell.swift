//
//  CarouselDataCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit
import SDWebImage

class CarouselDataCell: UICollectionViewCell {
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var shortNameLabel: UILabel!
    @IBOutlet weak var watchNowLabel: UILabel!
    @IBOutlet weak var titleBGImageView: UIImageView!
    @IBOutlet weak var playButtonBGImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Clear all backgrounds
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        parentView.backgroundColor = .clear
        
        // Only set corner radius for image view
        previewImageView.layer.cornerRadius = 12
        previewImageView.clipsToBounds = true
        previewImageView.contentMode = .scaleAspectFill
        
        // Style labels
        shortNameLabel.textColor = .white
        
        // Add shadow to image for better visibility
        previewImageView.layer.shadowColor = UIColor.black.cgColor
        previewImageView.layer.shadowOpacity = 0.3
        previewImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        previewImageView.layer.shadowRadius = 4
        
        shortNameLabel.font = FontManager.shared.font(for: .roboto, size: 14.0)
        titleBGImageView.layer.cornerRadius = 20
        playButtonBGImageView.layer.cornerRadius = playButtonBGImageView.frame.height / 2
        addBlur(to: titleBGImageView)
        addBlur(to: playButtonBGImageView)
    }
    
    func configure(with drama: DramaItem) {
        shortNameLabel.text = drama.dramaName
        watchNowLabel.text = "Watch now"
        
        if let imageUrl = drama.imageUrl, let url = URL(string: imageUrl) {
            previewImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
        }
    }
    func configurePopularMovie(with movie: Movie) {
        shortNameLabel.text = movie.title
        watchNowLabel.text = "Watch now"

        if let posterPath = movie.posterPath {
            let urlString = "https://image.tmdb.org/t/p/original/\(posterPath)"
            if let url = URL(string: urlString) {
                previewImageView.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "hoteDefault"),
                    options: [.highPriority, .retryFailed, .scaleDownLargeImages]
                )
            } else {
                // Fallback if URL is invalid
                previewImageView.image = UIImage(named: "hoteDefault")
            }
        } else {
            previewImageView.image = UIImage(named: "hoteDefault")
        }
    }
    func addBlur(to imageView: UIImageView) {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)

        blurView.frame = imageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 🔥 15% intensity feel
        blurView.alpha = 0.15

        imageView.addSubview(blurView)
    }

}

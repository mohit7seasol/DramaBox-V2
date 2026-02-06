//
//  NewDramaCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit
import SDWebImage

class NewDramaCell: UICollectionViewCell {
    @IBOutlet weak var dramaPreviewImageView: UIImageView!
    @IBOutlet weak var dramaNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dramaPreviewImageView.layer.cornerRadius = 20
        dramaPreviewImageView.clipsToBounds = true
        dramaPreviewImageView.contentMode = .scaleAspectFill
        
        dramaNameLabel.font = FontManager.shared.font(for: .roboto, size: 12.0)
    }
    
    func configure(with drama: DramaItem) {
        dramaNameLabel.text = drama.dramaName
        
        if let imageUrl = drama.imageUrl, let url = URL(string: imageUrl) {
            dramaPreviewImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "hoteDefault"))
        }
    }
    
    func configureUpcomingMovie(with movie: Movie) {
        dramaNameLabel.text = movie.title

        if let posterPath = movie.posterPath {
            let urlString = "https://image.tmdb.org/t/p/original/\(posterPath)"
            if let url = URL(string: urlString) {
                dramaPreviewImageView.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "hoteDefault"),
                    options: [.highPriority, .retryFailed, .scaleDownLargeImages]
                )
            } else {
                // Fallback if URL is invalid
                dramaPreviewImageView.image = UIImage(named: "hoteDefault")
            }
        } else {
            dramaPreviewImageView.image = UIImage(named: "hoteDefault")
        }
    }
}

//
//  ShortsListCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 31/01/26.
//

import UIKit
import MarqueeLabel

class ShortsListCell: UICollectionViewCell {

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var nameLabel: MarqueeLabel!
    @IBOutlet weak var totalEpisodesCountLabel: UILabel! // Text formate : 50 Episodes
    @IBOutlet weak var playIconImageView: UIImageView!
    @IBOutlet weak var lockEpisodeIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset MarqueeLabel
        nameLabel.shutdownLabel()
        thumbImageView.image = nil
    }
}

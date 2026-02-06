//
//  IPTVCategoryCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import UIKit

class IPTVCategoryCell: UICollectionViewCell {

    @IBOutlet weak var mainView: GradientDesignableView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var channelCountLabel: UILabel! // Text formate like 256+
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

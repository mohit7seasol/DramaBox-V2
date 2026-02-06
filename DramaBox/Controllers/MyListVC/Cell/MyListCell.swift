//
//  MyListCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 10/12/25.
//

import UIKit
import SDWebImage

class MyListCell: UICollectionViewCell {

    @IBOutlet weak var cellSelectedButton: UIButton!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetCell()
    }
    private func resetCell() {
        previewImageView.image = nil
        titleLabel.text = nil
        cellSelectedButton.isHidden = true
        cellSelectedButton.setImage(nil, for: .normal)
    }
    
    func setupUI() {
        contentView.clipsToBounds = false
        
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = 14
        previewImageView.backgroundColor = UIColor(white: 0.2, alpha: 0.5)
        
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.clipsToBounds = true
        titleLabel.isHidden = false
        titleLabel.alpha = 1
        
        cellSelectedButton.tintColor = .white
        cellSelectedButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        cellSelectedButton.layer.cornerRadius = 12
        cellSelectedButton.layer.masksToBounds = true
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    
    func configure(with title: String, imageUrl: URL?) {
        titleLabel.text = title
        
        if let imageUrl = imageUrl {
            previewImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "video_placeholder"))
        } else {
            previewImageView.image = UIImage(named: "video_placeholder")
        }
    }
}

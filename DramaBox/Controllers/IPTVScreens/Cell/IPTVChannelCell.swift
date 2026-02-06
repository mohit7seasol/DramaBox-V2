//
//  IPTVChannelCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import UIKit
import MarqueeLabel

class IPTVChannelCell: UICollectionViewCell {
    @IBOutlet weak var channelLogoImageview: UIImageView!
    @IBOutlet weak var channelNameLabel: MarqueeLabel!
    @IBOutlet weak var mainView: GradientDesignableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setCellUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setCellUI() // Call again when layout changes
    }
    
    func setCellUI() {
        mainView.borderStartColor = UIColor(hex: "#252525")!
        mainView.borderEndColor = UIColor(hex: "#181818")!
        mainView.borderWidth = 1.5
        mainView.borderGradientDirection = 0 // 0 = Top→Bottom, 1 = Right→Left
        mainView.cornerRadius = 18.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        channelLogoImageview.image = nil
        channelNameLabel.text = nil
        channelNameLabel.shutdownLabel()
    }
}

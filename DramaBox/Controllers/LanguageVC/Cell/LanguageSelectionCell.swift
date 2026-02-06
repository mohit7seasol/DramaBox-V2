//
//  LanguageSelectionCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit

class LanguageSelectionCell: UICollectionViewCell {

    @IBOutlet weak var unselectedLanguageImageView: UIImageView!
    @IBOutlet weak var countrFlagImageView: UIImageView!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var selectedBackgroundImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    private func setupUI() {
        countryNameLabel.font = UIDevice.current.userInterfaceIdiom == .pad ? FontManager.shared.font(for: .roboto, size: 25.0) : FontManager.shared.font(for: .roboto, size: 16.0)
        unselectedLanguageImageView.isHidden = false
        selectedBackgroundImageView.isHidden = true
    }
    
    func configure(isSelected: Bool) {
        // Show/Hide the appropriate image views based on selection
        unselectedLanguageImageView.isHidden = isSelected
        selectedBackgroundImageView.isHidden = !isSelected
        countryNameLabel.textColor = isSelected ? UIColor.black : UIColor.white
    }
}

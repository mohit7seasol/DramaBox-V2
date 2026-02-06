//
//  EpisodesListCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 09/12/25.
//

import UIKit

class EpisodesListCell: UICollectionViewCell {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var episodNoLabel: UILabel!
    @IBOutlet weak var isPremiumImageView: UIImageView!
    
    private var borderGradient: CAGradientLayer?
    private var borderMask: CAShapeLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        borderGradient?.removeFromSuperlayer()
        borderGradient = nil
        borderMask = nil
        parentView.backgroundColor = .clear
        isPremiumImageView.isHidden = true
    }
    
    private func setupUI() {
        parentView.layer.cornerRadius = 14
        parentView.layer.masksToBounds = true
        
        episodNoLabel.textColor = .white
        episodNoLabel.textAlignment = .center
        episodNoLabel.font = FontManager.shared.font(for: .roboto, size: 20.0)
        
        isPremiumImageView.isHidden = true
        isPremiumImageView.contentMode = .scaleAspectFit
    }
    
    // MARK: - Apply gradient border (based on screenshot)
    private func applyGradientBorder() {
        borderGradient?.removeFromSuperlayer()
        
        // Gradient layer
        let gradient = CAGradientLayer()
        gradient.frame = parentView.bounds
        gradient.colors = [
            UIColor(white: 1, alpha: 0.08).cgColor,
            UIColor(white: 1, alpha: 0.03).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        
        // Border mask
        let shape = CAShapeLayer()
        shape.lineWidth = 2
        shape.path = UIBezierPath(roundedRect: parentView.bounds, cornerRadius: 14).cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.white.cgColor
        
        gradient.mask = shape
        
        parentView.layer.addSublayer(gradient)
        
        self.borderGradient = gradient
        self.borderMask = shape
    }
    
    // MARK: - Selected purple glow border
    private func applySelectedGlow() {
        parentView.backgroundColor = UIColor(named: "appThemeColor")
        
        parentView.layer.shadowColor = UIColor(red: 0.62, green: 0.24, blue: 1.0, alpha: 1).cgColor
        parentView.layer.shadowRadius = 12
        parentView.layer.shadowOpacity = 0.8
        parentView.layer.shadowOffset = .zero
        episodNoLabel.textColor = .black
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderGradient?.frame = parentView.bounds
        borderMask?.path = UIBezierPath(roundedRect: parentView.bounds, cornerRadius: 14).cgPath
    }
    
    func configure(isSelected: Bool, isPremium: Bool, episodeNumber: Int) {
        episodNoLabel.text = "\(episodeNumber)"
        
        if isSelected {
            borderGradient?.removeFromSuperlayer()
            applySelectedGlow()
        } else {
            parentView.layer.shadowOpacity = 0
            parentView.backgroundColor = UIColor(red: 0.14, green: 0.13, blue: 0.14, alpha: 1)
            episodNoLabel.textColor = .white
            applyGradientBorder()
        }
        
        isPremiumImageView.isHidden = true // !isPremium  -- First Version --
        
        if !isPremiumImageView.isHidden {
            isPremiumImageView.frame = CGRect(
                x: parentView.bounds.width - 22,
                y: 4,
                width: 17,
                height: 17
            )
        }
    }
}

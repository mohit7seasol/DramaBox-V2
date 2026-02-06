//
//  RingtoneCateCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 20/01/26.
//

import UIKit

class RingtoneCateCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var parentView: UIView!
    
    private var gradientLayer: CAGradientLayer?
    private var hasSetupGradient = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellUI()
        // Don't setup gradient here - parentView.bounds is still zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Check if parentView has valid bounds before setting up gradient
        if parentView.bounds.width > 0 && parentView.bounds.height > 0 && !hasSetupGradient {
            setupGradientBackground()
            hasSetupGradient = true
        }
        
        // Update gradient frame
        gradientLayer?.frame = parentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLbl.text = nil
        // Keep gradient - just update its frame
    }
    
    private func setupCellUI() {
        // Configure parent view
        parentView.backgroundColor = UIColor(red: 0.11, green: 0.07, blue: 0.14, alpha: 1.0) // #1D1324 as fallback
        parentView.layer.masksToBounds = false
        parentView.layer.borderWidth = 1
        parentView.layer.borderColor = #colorLiteral(red: 0.2370221019, green: 0.2370221019, blue: 0.2370221019, alpha: 1)
        parentView.layer.cornerRadius = 18
        parentView.clipsToBounds = true
    }
    
    private func setupGradientBackground() {
        // Remove existing gradient layer if any
        gradientLayer?.removeFromSuperlayer()
        
        // Create new gradient layer
        let newGradientLayer = CAGradientLayer()
        
        // Hex colors: #1D1324, #16121A
        newGradientLayer.colors = [
            UIColor(red: 22.0/255.0, green: 22.0/255.0, blue: 22.0/255.0, alpha: 1.0).cgColor, // #161616
            UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0).cgColor  // #131313
        ]
        newGradientLayer.locations = [0.0, 1.0]
        newGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)  // Top
        newGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)    // Bottom
        newGradientLayer.cornerRadius = 0
        
        // Set frame to parentView bounds
        newGradientLayer.frame = parentView.bounds
        
        // Add to parent view
        parentView.layer.insertSublayer(newGradientLayer, at: 0)
        
        // Store reference
        gradientLayer = newGradientLayer
        
        // Force immediate display
        parentView.setNeedsLayout()
        parentView.layoutIfNeeded()
    }
    
    func configure(with category: RingtoneCategory) {
        // Set category name
        titleLbl.text = "\(category.category.uppercased())"
        
        // If parentView has bounds but gradient not setup, setup it now
        if parentView.bounds.width > 0 && parentView.bounds.height > 0 && gradientLayer == nil {
            setupGradientBackground()
        }
    }
    
    func animateSelection() {
        UIView.animate(withDuration: 0.1, animations: {
            self.parentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.parentView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.parentView.transform = .identity
                self.parentView.alpha = 1
            }
        }
    }
}

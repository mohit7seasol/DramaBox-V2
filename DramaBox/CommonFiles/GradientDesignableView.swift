//
//  GradientDesignableView.swift
//  DramaBox
//
//  Created by DREAMWORLD on 03/02/26.
//

import UIKit

@IBDesignable
class GradientDesignableView: UIView {

    // MARK: - Background Gradient Colors
    @IBInspectable var bgStartColor: UIColor = .clear {
        didSet { updateGradient() }
    }

    @IBInspectable var bgEndColor: UIColor = .clear {
        didSet { updateGradient() }
    }

    // 0 = Top → Bottom, 1 = Left → Right
    @IBInspectable var bgGradientDirection: Int = 0 {
        didSet { updateGradient() }
    }

    @IBInspectable var bgGradientOpacity: CGFloat = 1.0 {
        didSet { updateGradient() }
    }

    // MARK: - Border Gradient Colors
    @IBInspectable var borderStartColor: UIColor = .clear {
        didSet { updateBorder() }
    }

    @IBInspectable var borderEndColor: UIColor = .clear {
        didSet { updateBorder() }
    }

    // 0 = Top → Bottom, 1 = Right → Left
    @IBInspectable var borderGradientDirection: Int = 0 {
        didSet { updateBorder() }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { updateBorder() }
    }

    // MARK: - Corner Radius
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet { updateCornerRadius() }
    }

    // MARK: - Layers
    private let bgGradientLayer = CAGradientLayer()
    private let borderGradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
        layoutSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        updateBorder()
        updateCornerRadius()
    }

    // MARK: - Setup
    private func setup() {
        layer.insertSublayer(bgGradientLayer, at: 0)
        // Add border gradient layer above background but below other subviews
        layer.insertSublayer(borderGradientLayer, at: 1)
    }

    // MARK: - Background Gradient
    private func updateGradient() {
        bgGradientLayer.frame = bounds
        bgGradientLayer.colors = [
            bgStartColor.withAlphaComponent(bgGradientOpacity).cgColor,
            bgEndColor.withAlphaComponent(bgGradientOpacity).cgColor
        ]

        if bgGradientDirection == 0 {
            // Top → Bottom
            bgGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            bgGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        } else {
            // Left → Right
            bgGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            bgGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        }
        
        bgGradientLayer.cornerRadius = cornerRadius
        bgGradientLayer.masksToBounds = true
    }

    // MARK: - Border Gradient (FIXED)
    private func updateBorder() {
        guard borderWidth > 0 else {
            borderGradientLayer.removeFromSuperlayer()
            return
        }

        // Ensure border gradient layer is added if it was removed
        if borderGradientLayer.superlayer == nil {
            layer.insertSublayer(borderGradientLayer, at: 1)
        }

        borderGradientLayer.frame = bounds
        borderGradientLayer.colors = [
            borderStartColor.cgColor,
            borderEndColor.cgColor
        ]

        if borderGradientDirection == 0 {
            // Top → Bottom
            borderGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            borderGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        } else {
            // Right → Left
            borderGradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
            borderGradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        }

        // Create border path
        let borderPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2),
            cornerRadius: cornerRadius
        )
        
        borderMaskLayer.path = borderPath.cgPath
        borderMaskLayer.lineWidth = borderWidth
        borderMaskLayer.fillColor = UIColor.clear.cgColor
        borderMaskLayer.strokeColor = UIColor.white.cgColor // White for mask
        borderMaskLayer.cornerRadius = cornerRadius
        
        // Apply mask to border gradient
        borderGradientLayer.mask = borderMaskLayer
        borderGradientLayer.cornerRadius = cornerRadius
    }

    // MARK: - Corner Radius (FIXED)
    private func updateCornerRadius() {
        // Don't set masksToBounds on the main layer - it clips the border!
        // layer.masksToBounds = true
        
        bgGradientLayer.cornerRadius = cornerRadius
        bgGradientLayer.masksToBounds = true
        
        // Update border
        updateBorder()
    }
}

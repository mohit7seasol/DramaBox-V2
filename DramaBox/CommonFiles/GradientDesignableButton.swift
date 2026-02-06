//
//  GradientDesignableButton.swift
//  DramaBox
//
//  Created by DREAMWORLD on 03/02/26.
//

import UIKit

@IBDesignable
class GradientDesignableButton: UIButton {

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

    // MARK: - Title Color States
    @IBInspectable var normalTitleColor: UIColor = .white {
        didSet { updateTitleColors() }
    }
    
    @IBInspectable var highlightedTitleColor: UIColor = .lightGray {
        didSet { updateTitleColors() }
    }
    
    @IBInspectable var disabledTitleColor: UIColor = .gray {
        didSet { updateTitleColors() }
    }

    // MARK: - Gradient Colors for States
    @IBInspectable var highlightedBgStartColor: UIColor = .clear
    @IBInspectable var highlightedBgEndColor: UIColor = .clear
    
    @IBInspectable var disabledBgStartColor: UIColor = .clear
    @IBInspectable var disabledBgEndColor: UIColor = .clear
    
    // MARK: - Image Tint Colors
    @IBInspectable var normalImageTintColor: UIColor = .white {
        didSet { updateImageTintColors() }
    }
    
    @IBInspectable var highlightedImageTintColor: UIColor = .lightGray {
        didSet { updateImageTintColors() }
    }
    
    @IBInspectable var disabledImageTintColor: UIColor = .gray {
        didSet { updateImageTintColors() }
    }

    // MARK: - Layers
    private let bgGradientLayer = CAGradientLayer()
    private let borderGradientLayer = CAGradientLayer()
    private let borderMaskLayer = CAShapeLayer()
    
    private var originalBackgroundColor: UIColor?
    private var hasCustomBackgroundImage = false

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
        // Store original background color
        originalBackgroundColor = backgroundColor
        
        // Clear default background color to show gradient
        backgroundColor = .clear
        
        // Set up gradient layers
        layer.insertSublayer(bgGradientLayer, at: 0)
        layer.addSublayer(borderGradientLayer)
        
        // Set default title colors
        updateTitleColors()
        updateImageTintColors()
    }

    // MARK: - Background Gradient
    private func updateGradient() {
        // Only show gradient if no background image is set and gradient colors are provided
        let clearColor = UIColor.clear
        let hasGradientColors = !bgStartColor.isEqual(clearColor) && !bgEndColor.isEqual(clearColor)
        
        if hasGradientColors && !hasCustomBackgroundImage {
            bgGradientLayer.isHidden = false
            bgGradientLayer.frame = bounds
            
            // Determine which colors to use based on button state
            var startColor = bgStartColor
            var endColor = bgEndColor
            
            if !isEnabled && !disabledBgStartColor.isEqual(clearColor) && !disabledBgEndColor.isEqual(clearColor) {
                startColor = disabledBgStartColor
                endColor = disabledBgEndColor
            } else if isHighlighted && !highlightedBgStartColor.isEqual(clearColor) && !highlightedBgEndColor.isEqual(clearColor) {
                startColor = highlightedBgStartColor
                endColor = highlightedBgEndColor
            }
            
            bgGradientLayer.colors = [
                startColor.withAlphaComponent(bgGradientOpacity).cgColor,
                endColor.withAlphaComponent(bgGradientOpacity).cgColor
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
        } else {
            bgGradientLayer.isHidden = true
        }
    }

    // MARK: - Border Gradient
    private func updateBorder() {
        guard borderWidth > 0 else {
            borderGradientLayer.removeFromSuperlayer()
            return
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

        borderMaskLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2),
            cornerRadius: cornerRadius
        ).cgPath

        borderMaskLayer.lineWidth = borderWidth
        borderMaskLayer.fillColor = UIColor.clear.cgColor
        borderMaskLayer.strokeColor = UIColor.black.cgColor

        borderGradientLayer.mask = borderMaskLayer
    }

    // MARK: - Corner Radius
    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        bgGradientLayer.cornerRadius = cornerRadius
        borderMaskLayer.cornerRadius = cornerRadius
    }
    
    // MARK: - Title Colors
    private func updateTitleColors() {
        setTitleColor(normalTitleColor, for: .normal)
        setTitleColor(highlightedTitleColor, for: .highlighted)
        setTitleColor(disabledTitleColor, for: .disabled)
    }
    
    // MARK: - Image Tint Colors
    private func updateImageTintColors() {
        if let image = image(for: .normal) {
            setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        if let image = image(for: .highlighted) {
            setImage(image.withRenderingMode(.alwaysTemplate), for: .highlighted)
        }
        if let image = image(for: .disabled) {
            setImage(image.withRenderingMode(.alwaysTemplate), for: .disabled)
        }
        
        tintColor = normalImageTintColor
    }
    
    // MARK: - Override Image Methods
    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image?.withRenderingMode(.alwaysTemplate), for: state)
        
        // Update tint color based on state
        switch state {
        case .normal:
            tintColor = normalImageTintColor
        case .highlighted:
            tintColor = highlightedImageTintColor
        case .disabled:
            tintColor = disabledImageTintColor
        default:
            break
        }
    }
    
    override func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        super.setBackgroundImage(image, for: state)
        
        // Track if user sets background image
        if image != nil {
            hasCustomBackgroundImage = true
            bgGradientLayer.isHidden = true
        } else {
            hasCustomBackgroundImage = false
            updateGradient()
        }
    }
    
    // MARK: - Button State Changes
    override var isHighlighted: Bool {
        didSet {
            updateGradient()
            // Update image tint color
            tintColor = isHighlighted ? highlightedImageTintColor : normalImageTintColor
            
            // Add subtle animation for highlighted state
            if isHighlighted {
                UIView.animate(withDuration: 0.1) {
                    self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }
            } else {
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                }
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateGradient()
            // Update title and image colors when enabled state changes
            let titleColor = isEnabled ? normalTitleColor : disabledTitleColor
            let imageTintColor = isEnabled ? normalImageTintColor : disabledImageTintColor
            
            setTitleColor(titleColor, for: .normal)
            tintColor = imageTintColor
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        updateGradient()
        tintColor = highlightedImageTintColor
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // Small delay to show highlighted state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateGradient()
            self.tintColor = self.isEnabled ? self.normalImageTintColor : self.disabledImageTintColor
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        updateGradient()
        tintColor = isEnabled ? normalImageTintColor : disabledImageTintColor
    }
}

//
//  GradientView.swift
//  DramaBox
//
//  Created by DREAMWORLD on 09/12/25.
//

import UIKit

@IBDesignable
class GradientView: UIView {

    // MARK: - Gradient Layer
    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    // MARK: - Inspectable Gradient Colors

    @IBInspectable var startColor: UIColor = .black {
        didSet { updateColors() }
    }

    @IBInspectable var endColor: UIColor = .darkGray {
        didSet { updateColors() }
    }

    // MARK: - Gradient Direction (Top → Bottom Default)

    @IBInspectable var startPointX: CGFloat = 0.5 {
        didSet { updatePoints() }
    }

    @IBInspectable var startPointY: CGFloat = 0.0 {
        didSet { updatePoints() }
    }

    @IBInspectable var endPointX: CGFloat = 0.5 {
        didSet { updatePoints() }
    }

    @IBInspectable var endPointY: CGFloat = 1.0 {
        didSet { updatePoints() }
    }

    // MARK: - Border Settings (From Design)

    @IBInspectable var borderColor: UIColor = .clear {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }

    // MARK: - Corner Radius

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = true
        }
    }

    // MARK: - Opacity (for dark blur style)

    @IBInspectable var viewOpacity: Float = 1 {
        didSet { layer.opacity = viewOpacity }
    }

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
    }

    // MARK: - Setup

    private func setup() {
        updateColors()
        updatePoints()
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
        layer.opacity = viewOpacity
    }

    private func updateColors() {
        gradientLayer.colors = [
            startColor.cgColor,
            endColor.cgColor
        ]
    }

    private func updatePoints() {
        gradientLayer.startPoint = CGPoint(x: startPointX, y: startPointY)
        gradientLayer.endPoint   = CGPoint(x: endPointX, y: endPointY)
    }
}

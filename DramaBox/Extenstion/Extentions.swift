//
//  Extentions.swift
//  DramaBox
//
//  Created by DREAMWORLD on 15/09/25.
//

import Foundation
import UIKit
import Photos
import AVFoundation

// MARK: - UITableView
extension UITableView {
    /// Register multiple cells using identifiers (String-based, for XIB/storyboard cells)
    func register(_ identifiers: [String]) {
        identifiers.forEach { id in
            self.register(UINib(nibName: id, bundle: nil), forCellReuseIdentifier: id)
        }
    }
    
    /// Register single cell by identifier
    func register(_ identifier: String) {
        self.register(UINib(nibName: identifier, bundle: nil), forCellReuseIdentifier: identifier)
    }
    
    /// Display a centered message label when there's no data.
    /// - Parameter message: The text message to display.
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.sizeToFit()
        
        let backgroundView = UIView(frame: self.bounds)
        backgroundView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -20)
        ])
        
        self.backgroundView = backgroundView
        self.separatorStyle = .none
    }
    
    /// Remove the empty message and restore the normal table view appearance.
    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

// MARK: - UICollectionView
extension UICollectionView {
    /// Register multiple cells using identifiers (String-based, for XIB/storyboard cells)
    func register(_ identifiers: [String]) {
        identifiers.forEach { id in
            self.register(UINib(nibName: id, bundle: nil), forCellWithReuseIdentifier: id)
        }
    }
    
    /// Register single cell by identifier
    func register(_ identifier: String) {
        self.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
    }
    
    /// Displays a centered message when no data is available.
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.sizeToFit()
        
        let backgroundView = UIView(frame: bounds)
        backgroundView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -20)
        ])
        
        self.backgroundView = backgroundView
    }
    
    /// Restores collection view to normal state.
    func restore() {
        self.backgroundView = nil
    }
}

final class ImagePickerHelper: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private weak var presenter: UIViewController?
    private var completion: ((UIImage?) -> Void)?
    private var allowsEditing: Bool = true
    
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func showImagePicker(allowsEditing: Bool = true, completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        self.allowsEditing = allowsEditing
        
        let alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .actionSheet)
        
        // 📸 Camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.checkCameraPermission { granted in
                    if granted {
                        self.presentPicker(sourceType: .camera)
                    } else {
                        self.showSettingsAlert(message: "Camera access is required to take photos.")
                    }
                }
            }))
        }
        
        // 🖼️ Library
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
                self.checkPhotoLibraryPermission { granted in
                    if granted {
                        self.presentPicker(sourceType: .photoLibrary)
                    } else {
                        self.showSettingsAlert(message: "Photo library access is required to choose photos.")
                    }
                }
            }))
        }
        
        // ❌ Cancel
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController, let presenter = presenter {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        presenter?.present(alert, animated: true)
    }
    
    // MARK: - Private Helpers
    
    private func presentPicker(sourceType: UIImagePickerController.SourceType) {
        guard let presenter = presenter else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = allowsEditing
        picker.sourceType = sourceType
        presenter.present(picker, animated: true)
    }
    
    private func showSettingsAlert(message: String) {
        let alert = UIAlertController(title: "Permission Required", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }))
        presenter?.present(alert, animated: true)
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        completion?(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completion?(nil)
    }
}
// MARK: - UIView
extension UIView {
    
    /// Apply gradient border with corner radius
    /// - Parameters:
    ///   - firstColor: Starting color (left side)
    ///   - secondColor: Ending color (right side)
    ///   - cornerRadius: Corner radius to apply
    ///   - borderWidth: Width of the border
    func applyGradientBorder(firstColor: UIColor,
                             secondColor: UIColor,
                             cornerRadius: CGFloat,
                             borderWidth: CGFloat) {
        
        // Remove old gradient borders if any
        self.layer.sublayers?
            .filter { $0.name == "gradientBorder" }
            .forEach { $0.removeFromSuperlayer() }
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "gradientBorder"
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = cornerRadius
        
        // Create shape layer (acts as border mask)
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = borderWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.path = UIBezierPath(roundedRect: self.bounds.insetBy(dx: borderWidth/2, dy: borderWidth/2),
                                       cornerRadius: cornerRadius).cgPath
        gradientLayer.mask = shapeLayer
        
        // Add gradient border
        self.layer.addSublayer(gradientLayer)
    }
    
    /// Update layout when view resizes
    func updateGradientBorderLayout() {
        self.layer.sublayers?
            .filter { $0.name == "gradientBorder" }
            .forEach { $0.frame = self.bounds }
    }
    
    func applyGradientBackground(colors: [UIColor],
                                 startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0),
                                 endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0),
                                 cornerRadius: CGFloat = 0) {
        
        // Remove existing gradient layers
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.cornerRadius = cornerRadius
        
        // Insert at the bottom
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func removeGradientBackground() {
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
    }
    
}
// MARK: - UIViewController
extension UIViewController {
    static public func instantiate(fromAppStoryboard appStoryboard: AppStoryboard) -> Self {
        return appStoryboard.viewController(viewControllerClass: self)
    }
    class public var storyboardID: String {
        return "\(self)"
    }
}
public enum AppStoryboard: String {

    case Main
    case Series
    case News
    case Ranking
    case Setting
    
    public var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }

    public func viewController<T: UIViewController>(viewControllerClass: T.Type, function: String = #function, line: Int = #line, file: String = #file) -> T {

        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID

        guard let scene = instance.instantiateViewController(withIdentifier: storyboardID) as? T else {
            fatalError("ViewController with identifier \(storyboardID), not found in \(self.rawValue) Storyboard.\nFile : \(file) \nLine Number : \(line) \nFunction : \(function)")
        }
        return scene
    }

    public func initialViewController() -> UIViewController? {
        return instance.instantiateInitialViewController()
    }
}
// MARK: - UIVIew Rounded designable
@IBDesignable
class BottomRoundedView: UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat = 10.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var bottomLeftCorner: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var bottomRightCorner: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let maskPath = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: getRoundingCorners(),
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    private func getRoundingCorners() -> UIRectCorner {
        var roundingCorners: UIRectCorner = []
        if bottomLeftCorner {
            roundingCorners.insert(.bottomLeft)
        }
        if bottomRightCorner {
            roundingCorners.insert(.bottomRight)
        }
        return roundingCorners
    }
}
// MARK: - ClickListener
class ClickListener: UITapGestureRecognizer {
    var onClick : (() -> Void)? = nil
}
extension UIImageView {
    func roundBottomCorners(radius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        // bottom-left, bottom-right
    }
    func setImage(with urlString: String, completion: ((UIImage?) -> Void)? = nil) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.image = nil
                    completion?(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.image = image
                completion?(image)
            }
        }.resume()
    }
}
extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
    func makeCircle() {
        layoutIfNeeded() // ensures frame is updated
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
    }
}
extension String {
    /// Convert ISO-639-1 language code to full language name (English display name)
    var fullLanguageName: String {
        let locale = Locale(identifier: "en") // output in English
        return locale.localizedString(forLanguageCode: self) ?? self
    }
}

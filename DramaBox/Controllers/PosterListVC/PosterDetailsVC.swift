//
//  PosterDetailsVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 22/01/26.
//

import UIKit
import Photos
import SDWebImage

class PosterDetailsVC: UIViewController {
    @IBOutlet weak var posterCountLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var swipeLabel: UILabel!
    
    var posters: [ImageData] = []
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        updatePosterImage()
        setupSwipeLabel()
    }
    
    private func setupUI() {
        posterImageView.isUserInteractionEnabled = true
        
        updatePosterCountLabel()
    }
    
    private func setupSwipeLabel() {
        swipeLabel.text = "Swipe to see more posters".localized(LocalizationService.shared.language)
        swipeLabel.clipsToBounds = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideSwipeLabel()
        }
    }
    
    private func hideSwipeLabel() {
        UIView.animate(withDuration: 0.5) {
            self.swipeLabel.alpha = 0
        } completion: { _ in
            self.swipeLabel.isHidden = true
        }
    }
    
    private func showSwipeLabel() {
        swipeLabel.isHidden = false
        swipeLabel.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.swipeLabel.alpha = 1
        }
        
        // Auto-hide again after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hideSwipeLabel()
        }
    }
    
    private func setupGestures() {
        // Swipe left gesture
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        posterImageView.addGestureRecognizer(swipeLeft)
        
        // Swipe right gesture
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        posterImageView.addGestureRecognizer(swipeRight)
        
        // Tap gesture to show/hide controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        posterImageView.addGestureRecognizer(tapGesture)
        
        // Edge swipe to go back
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipe(_:)))
        edgeSwipe.edges = .left
        view.addGestureRecognizer(edgeSwipe)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Toggle swipe label visibility
        if swipeLabel.isHidden {
            showSwipeLabel()
        } else {
            hideSwipeLabel()
        }
    }
    
    @objc private func handleEdgeSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .ended {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        // Hide label when user starts swiping
        hideSwipeLabel()
        
        switch gesture.direction {
        case .left:
            showNextPosterWithAnimation()
        case .right:
            showPreviousPosterWithAnimation()
        default:
            break
        }
    }
    
    private func showNextPosterWithAnimation() {
        guard currentIndex < posters.count - 1 else { return }
        
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        posterImageView.layer.add(transition, forKey: kCATransition)
        
        currentIndex += 1
        updatePosterImage()
        updatePosterCountLabel()
    }
    
    private func showPreviousPosterWithAnimation() {
        guard currentIndex > 0 else { return }
        
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromLeft
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        posterImageView.layer.add(transition, forKey: kCATransition)
        
        currentIndex -= 1
        updatePosterImage()
        updatePosterCountLabel()
    }
    
    private func updatePosterImage() {
        guard currentIndex < posters.count else { return }
        
        let poster = posters[currentIndex]
        let fullURL = URL(string: "https://image.tmdb.org/t/p/original\(poster.filePath)")
        
        UIView.transition(with: posterImageView,
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
            self.posterImageView.sd_setImage(
                with: fullURL,
                placeholderImage: UIImage(named: "hoteDefault"),
                options: [.retryFailed, .continueInBackground, .highPriority]
            )
        }, completion: nil)
    }
    
    private func updatePosterCountLabel() {
        posterCountLabel.text = "\("Poster".localized(LocalizationService.shared.language)) \(currentIndex + 1)/\(posters.count)"
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                print("Failed to save: \(error.localizedDescription)")
            } else {
                print("Poster saved to Photos 📸")
            }
        }
    }
}

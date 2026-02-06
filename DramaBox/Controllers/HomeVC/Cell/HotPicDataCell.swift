//
//  HotPicDataCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit
import SDWebImage
import Cosmos
import MarqueeLabel

class HotPicDataCell: UICollectionViewCell {
    
    @IBOutlet weak var preViewImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel! // Formate like 🔥 410.6K
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var rateView: CosmosView!
    @IBOutlet weak var hotePickBgImg: UIImageView!
    @IBOutlet weak var movieDescLbl: MarqueeLabel!
    
    private var gradientLayer: CAGradientLayer?
    private var needsGradient: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        parentView.clipsToBounds = true
        
        preViewImageView.layer.cornerRadius = 8
        preViewImageView.clipsToBounds = true
        preViewImageView.contentMode = .scaleAspectFill
        
        nameLabel.textColor = .white
        likeCountLabel.textColor = .white
        
        nameLabel.font = FontManager.shared.font(for: .roboto, size: 16)
        likeCountLabel.font = FontManager.shared.font(for: .roboto, size: 14)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Clean up gradient state
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        needsGradient = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Apply gradient when layout is ready
        if needsGradient && gradientLayer == nil {
            applyGradientNow()
        } else if let gradientLayer = gradientLayer {
            // Update existing gradient frame
            gradientLayer.frame = parentView.bounds
        }
    }
    
    func configure(with drama: DramaItem, shouldAddGradient: Bool = false) {
        nameLabel.text = drama.dramaName
        
        // ✅ SET RANDOM LIKE COUNT
        let randomLikeCount = generateRandomLikeCount()
        likeCountLabel.text = "🔥 \(randomLikeCount)"
        
        // Set gradient requirement
        needsGradient = shouldAddGradient
        
        /* if shouldAddGradient {
            // Force immediate layout and apply gradient
            parentView.setNeedsLayout()
            parentView.layoutIfNeeded()
            
            // Apply gradient immediately if bounds are ready
            if !parentView.bounds.isEmpty {
                applyGradientNow()
            }
        } else {
            // Remove gradient if not needed
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            needsGradient = false
        } */
        
        // Load image
        if let imageUrl = drama.imageUrl,
           let url = URL(string: imageUrl) {
            preViewImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "hoteDefault")
            )
        }
    }
    
    func configureTopRatedMovie(with movie: Movie, shouldAddGradient: Bool = true) {
        // Convert date
        let releaseDate = formattedReleaseDate(from: movie.releaseDate)
        let fullText = "\("Release Date:".localized(LocalizationService.shared.language)) \(releaseDate)"
        
        // Create attributed string
        let attributedText = NSMutableAttributedString(string: fullText)
        
        // White color only for "Release Date:"
        let titleRange = (fullText as NSString).range(of: "Release Date:")
        attributedText.addAttribute(.foregroundColor, value: UIColor.white, range: titleRange)
        
        // Optional: normal color for date
        let dateRange = (fullText as NSString).range(of: releaseDate)
        attributedText.addAttribute(.foregroundColor, value: UIColor.lightGray, range: dateRange)
        
        nameLabel.text = movie.title
        
        // ✅ SET RANDOM LIKE COUNT
        let randomLikeCount = generateRandomLikeCount()
        likeCountLabel.text = "🔥 \(randomLikeCount)"
        
        // In your cell configuration or view setup:
        movieDescLbl.type = .continuous
        movieDescLbl.speed = .duration(15) // Adjust speed
        movieDescLbl.animationCurve = .easeInOut
        movieDescLbl.fadeLength = 10.0 // Fade effect at edges
        movieDescLbl.trailingBuffer = 30.0 // Space after text
        movieDescLbl.labelize = false // Enable scrolling
        movieDescLbl.attributedText = attributedText
        
        // Set gradient requirement
        needsGradient = shouldAddGradient
        
        if shouldAddGradient {
            // Force immediate layout and apply gradient
            parentView.setNeedsLayout()
            parentView.layoutIfNeeded()
            
            // Apply gradient immediately if bounds are ready
            if !parentView.bounds.isEmpty {
                applyGradientNow()
            }
        } else {
            // Remove gradient if not needed
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            needsGradient = false
        }
        
        if let posterPath = movie.posterPath {
            let urlString = "https://image.tmdb.org/t/p/original/\(posterPath)"
            if let url = URL(string: urlString) {
                preViewImageView.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "hoteDefault"),
                    options: [.highPriority, .retryFailed, .scaleDownLargeImages]
                )
            } else {
                // Fallback if URL is invalid
                preViewImageView.image = UIImage(named: "hoteDefault")
            }
        } else {
            preViewImageView.image = UIImage(named: "hoteDefault")
        }
    }
    
    // ✅ ADD THIS METHOD TO GENERATE RANDOM LIKE COUNTS
    private func generateRandomLikeCount() -> String {
        // Generate random number between 1K and 999.9K
        let randomChoice = Int.random(in: 1...3)
        
        switch randomChoice {
        case 1:
            // Format: 1.5K, 2.3K, etc. (1.0K to 9.9K)
            let randomValue = Double.random(in: 1.0...9.9)
            return String(format: "%.1fK", randomValue)
            
        case 2:
            // Format: 10K, 25K, 99K, etc. (10K to 99K)
            let randomValue = Int.random(in: 10...99)
            return "\(randomValue)K"
            
        case 3:
            // Format: 100K, 250K, 999K, etc. (100K to 999K)
            let randomValue = Int.random(in: 100...999)
            return "\(randomValue)K"
            
        default:
            return "1.5K"
        }
    }
    
    // ✅ OPTIONAL: Alternative method with more varied formats including millions
    private func generateRandomLikeCountWithMillion() -> String {
        // Generate random number with different ranges
        let randomChoice = Int.random(in: 1...5)
        
        switch randomChoice {
        case 1:
            // Format: 1.5K, 2.3K, etc. (1.0K to 9.9K)
            let randomValue = Double.random(in: 1.0...9.9)
            return String(format: "%.1fK", randomValue)
            
        case 2:
            // Format: 10K, 25K, 99K, etc. (10K to 99K)
            let randomValue = Int.random(in: 10...99)
            return "\(randomValue)K"
            
        case 3:
            // Format: 100K, 250K, 999K, etc. (100K to 999K)
            let randomValue = Int.random(in: 100...999)
            return "\(randomValue)K"
            
        case 4:
            // Format: 1.1M, 2.5M, etc. (1.0M to 9.9M)
            let randomValue = Double.random(in: 1.0...9.9)
            return String(format: "%.1fM", randomValue)
            
        case 5:
            // Format: 10M, 25M, 99M, etc. (10M to 99M)
            let randomValue = Int.random(in: 10...99)
            return "\(randomValue)M"
            
        default:
            return "2.5K"
        }
    }
    
    private func applyGradientNow() {
        guard needsGradient, gradientLayer == nil else { return }
        
        // Create gradient layer
        let gradient = CAGradientLayer()
        gradient.frame = parentView.bounds
        
        // Set gradient colors
        if let color1 = UIColor(named: "Gradient1")?.cgColor,
           let color2 = UIColor(named: "Gradient2")?.cgColor {
            gradient.colors = [color1, color2]
        }
        
//        if let color1 = UIColor(hex: "#292517")?.cgColor,
//           let color2 = UIColor(hex: "#161512")?.cgColor {
//            gradient.colors = [color1, color2]
//        }
//        gradient.colors = [UIColor.gradient1, UIColor.gradient2]
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.cornerRadius = parentView.layer.cornerRadius
        
        // Insert at bottom-most layer
        parentView.layer.insertSublayer(gradient, at: 0)
        
        gradientLayer = gradient
    }
    
    func formattedReleaseDate(from dateString: String?) -> String {
        guard let dateString = dateString else { return "" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd-MM-yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return ""
    }
}

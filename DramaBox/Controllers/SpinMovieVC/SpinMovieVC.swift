//
//  SpinMovieVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 23/01/26.
//

import UIKit
import SwiftFortuneWheel
import GoogleMobileAds

struct SpinGenre {
    let id: Int
    let name: String
}

// Global constant accessible everywhere
let allGenres: [SpinGenre] = [
    SpinGenre(id: 28, name: "Action"),
    SpinGenre(id: 12, name: "Adventure"),
    SpinGenre(id: 16, name: "Animation"),
    SpinGenre(id: 35, name: "Comedy"),
    SpinGenre(id: 80, name: "Crime"),
    SpinGenre(id: 99, name: "Documentary"),
    SpinGenre(id: 18, name: "Drama"),
    SpinGenre(id: 10751, name: "Family"),
    SpinGenre(id: 14, name: "Fantasy"),
    SpinGenre(id: 36, name: "History"),
    SpinGenre(id: 27, name: "Horror"),
    SpinGenre(id: 10402, name: "Music"),
    SpinGenre(id: 9648, name: "Mystery"),
    SpinGenre(id: 878, name: "Science Fiction"),
    SpinGenre(id: 10770, name: "TV Movie"),
    SpinGenre(id: 53, name: "Thriller"),
    SpinGenre(id: 10752, name: "War"),
    SpinGenre(id: 37, name: "Western")
]

class SpinMovieVC: UIViewController {
    @IBOutlet weak var spinButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var bannerAddView: UIView!
    @IBOutlet weak var addHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var spinButtonView: GradientDesignableView!
    @IBOutlet weak var spinButtonLabel: UILabel!
    
    // Use your SpinGenre struct
    let allGenres: [SpinGenre] = [
        SpinGenre(id: 28, name: "Action"),
        SpinGenre(id: 12, name: "Adventure"),
        SpinGenre(id: 16, name: "Animation"),
        SpinGenre(id: 35, name: "Comedy"),
        SpinGenre(id: 80, name: "Crime"),
        SpinGenre(id: 99, name: "Documentary"),
        SpinGenre(id: 18, name: "Drama"),
        SpinGenre(id: 10751, name: "Family"),
        SpinGenre(id: 14, name: "Fantasy"),
        SpinGenre(id: 36, name: "History"),
        SpinGenre(id: 27, name: "Horror"),
        SpinGenre(id: 10402, name: "Music"),
        SpinGenre(id: 9648, name: "Mystery"),
        SpinGenre(id: 878, name: "Science Fiction"),
        SpinGenre(id: 10770, name: "TV Movie"),
        SpinGenre(id: 53, name: "Thriller"),
        SpinGenre(id: 10752, name: "War"),
        SpinGenre(id: 37, name: "Western")
    ]
    
    // Wheel categories with colors - only include genres that are on the wheel
    var wheelCategories: [(name: String, color: UIColor, genreId: Int)] = [
        (name: "Action", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 28),
        (name: "Adventure", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 12),
        (name: "Animation", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 16),
        (name: "Comedy", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 35),
        (name: "Crime", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 80),
        (name: "Horror", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 27),
        (name: "Western", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 37),
        (name: "Thriller", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 53),
        (name: "War", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 10752),
        (name: "Drama", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 18),
        (name: "TV Movie", color: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1), genreId: 10770),
        (name: "Music", color: #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1), genreId: 10402)
    ]
    private let googleBannerAds = GoogleBannerAds()
    private var bannerView: BannerView?
    
    // Store the selected result
    private var selectedCategory: (name: String, genreId: Int)?
    
    lazy var slices: [Slice] = {
        var slices: [Slice] = []
        
        for category in wheelCategories {
            let sliceContent = [
                Slice.ContentType.text(
                    text: category.name,
                    preferences: .variousWheelJackpotText
                )
            ]
            
            let slice = Slice(
                contents: sliceContent,
                backgroundColor: category.color
            )
            
            slices.append(slice)
        }
        
        return slices
    }()

    
    var finishIndex: Int {
        return Int.random(in: 0..<wheelControl.slices.count)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        wheelBackgroundView.layer.cornerRadius = wheelBackgroundView.bounds.width / 2
    }
    
    private func setupUI() {
        spinButton.clipsToBounds = true
        spinButtonLabel.text = "Spin".localized(LocalizationService.shared.language)
        spinButtonView.cornerRadius = spinButtonView.frame.height / 2
        
        titleLabel.text = "Let the Wheel Decide!".localized(LocalizationService.shared.language)
        subTitleLabel.text = "Spin to pick a random category & explore movies instantly.".localized(LocalizationService.shared.language)
        subscribeBannerAd()
    }
    
    func subscribeBannerAd() {

        if Subscribe.get() {
            addHeightConstant.constant = 0
            bannerAddView.isHidden = true
            return
        }

        // Create BannerView ONLY ONCE
        if bannerView == nil {
            let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(
                width: UIScreen.main.bounds.width
            ))

            banner.translatesAutoresizingMaskIntoConstraints = false
            bannerAddView.addSubview(banner)

            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: bannerAddView.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: bannerAddView.trailingAnchor),
                banner.topAnchor.constraint(equalTo: bannerAddView.topAnchor),
                banner.bottomAnchor.constraint(equalTo: bannerAddView.bottomAnchor)
            ])

            bannerView = banner
        }

        bannerAddView.isHidden = false
        addHeightConstant.constant = 50   // Standard banner height

        // ✅ THIS IS THE KEY FIX
        googleBannerAds.loadAds(vc: self, view: bannerView!)
    }

    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func spinButtonAction(_ sender: UIButton) {
        spinButton.isEnabled = false
        
        // Get random finish index
        let finishIndex = self.finishIndex
        print("🎡 Spinning to index: \(finishIndex)")
        
        // Start wheel animation
        wheelControl.startRotationAnimation(finishIndex: finishIndex, continuousRotationTime: 1) { [weak self] (finished) in
            guard let self = self else { return }
            
            if finished {
                print("✅ Wheel stopped at index: \(finishIndex)")
                
                // Determine what was selected
                if finishIndex < self.wheelCategories.count {
                    // A category was selected
                    let selected = self.wheelCategories[finishIndex]
                    self.selectedCategory = (name: selected.name, genreId: selected.genreId)
                    print("🎯 Selected: \(selected.name) (ID: \(selected.genreId))")
                } else {
                    // JACKPOT was selected (last slice)
                    self.selectedCategory = (name: "JACKPOT", genreId: -1)
                    print("🎯 Selected: JACKPOT")
                }
                
                // Show success alert instead of navigating to separate VC
                self.showSpinSuccessAlert()
            }
            
            self.spinButton.isEnabled = true
        }
    }
    
    
    @IBOutlet weak var wheelBackgroundView: UIView!{
        didSet {
            wheelBackgroundView.layer.cornerRadius = wheelBackgroundView.bounds.width / 2
        }
    }
    
    @IBOutlet weak var wheelControl: SwiftFortuneWheel!{
        didSet {
            wheelControl.configuration = .variousWheelJackpotConfiguration
            wheelControl.slices = slices
            wheelControl.spinImage = "spinCenterImage"
            wheelControl.pinImage = "pointer"
            wheelControl.isSpinEnabled = false
            
            wheelControl.pinImageViewCollisionEffect = CollisionEffect(force: 15, angle: 30)
            wheelControl.edgeCollisionDetectionOn = true
        }
    }
    private func showSpinSuccessAlert() {
        guard let selectedCategory = selectedCategory else {
            print("❌ No category selected")
            return
        }
        
        // Create a custom alert view controller
        let alertController = UIAlertController(
            title: "\("Congrats!".localized(LocalizationService.shared.language))\n\("Success! The movie category name is now revealed.".localized(LocalizationService.shared.language))",
            message: "\"\(selectedCategory.name)\"",
            preferredStyle: .alert
        )
        
        // Customize title appearance
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        
        let titleString = NSAttributedString(
            string: "Congrats!\nSuccess! The movie category name is now revealed.",
            attributes: titleAttributes
        )
        
        alertController.setValue(titleString, forKey: "attributedTitle")
        
        // Customize message appearance
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let messageString = NSAttributedString(
            string: "\"\(selectedCategory.name)\"",
            attributes: messageAttributes
        )
        
        alertController.setValue(messageString, forKey: "attributedMessage")
        
        // Spin Again Button
        let spinAgainAction = UIAlertAction(title: "Spin Again".localized(LocalizationService.shared.language), style: .default) { [weak self] _ in
            // Dismiss the alert (popup)
            // The user can spin again by tapping the spin button
            print("🔄 User tapped Spin Again")
        }
        
        // Watch Now Button
        let watchNowAction = UIAlertAction(title: "Watch Now".localized(LocalizationService.shared.language), style: .default) { [weak self] _ in
            // Navigate to GenreVideoListVC
            print("▶️ User tapped Watch Now")
            self?.navigateToGenreVideoList(genreId: selectedCategory.genreId, genreName: selectedCategory.name)
        }
        
        // Add buttons to alert
        alertController.addAction(spinAgainAction)
        alertController.addAction(watchNowAction)
        
        // Present the alert
        self.present(alertController, animated: true, completion: nil)
    }
    func navigateToGenreVideoList(genreId: Int, genreName: String) {
        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: nil)
        
        // Note: Using "GenereMovieListVC" (with "Genere" spelling) as per your class
        if let genereMovieListVC = storyboard.instantiateViewController(withIdentifier: "GenereMovieListVC") as? GenereMovieListVC {
            
            // Pass the selected genre data to GenereMovieListVC
            genereMovieListVC.genreId = genreId
            genereMovieListVC.genreName = genreName
            
            print("🎬 Navigating to GenereMovieListVC with:")
            print("   Genre ID: \(genreId)")
            print("   Genre Name: \(genreName)")
            
            // Push to navigation controller
            self.navigationController?.pushViewController(genereMovieListVC, animated: true)
            
        } else {
            // Fallback in case GenereMovieListVC doesn't exist
            print("⚠️ GenereMovieListVC not found in storyboard")
            
            // Show an alert
            let alert = UIAlertController(
                title: "Navigation Error",
                message: "Could not navigate to movie list. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
public extension TextPreferences {
    static var variousWheelJackpotText: TextPreferences {
        
        var font =  UIFont.systemFont(ofSize: 13, weight: .bold)
        var horizontalOffset: CGFloat = 0
        
        if let customFont = UIFont(name: "ToyBox", size: 13) {
            font = customFont
            horizontalOffset = 2
        }
        
        var textPreferences = TextPreferences(textColorType: SFWConfiguration.ColorType.customPatternColors(colors: nil, defaultColor: .white),
                                              font: font,
                                              verticalOffset: 5)
        
        textPreferences.horizontalOffset = horizontalOffset
        textPreferences.orientation = .vertical
        textPreferences.alignment = .right
        
        return textPreferences
    }
}
public extension SFWConfiguration {
    static var variousWheelJackpotConfiguration: SFWConfiguration {
        let anchorImage = SFWConfiguration.AnchorImage(imageName: "blueAnchorImage", size: CGSize(width: 12, height: 12), verticalOffset: -22)
        
        let pin = SFWConfiguration.PinImageViewPreferences(size: CGSize(width: 13, height: 60), position: .top, verticalOffset: -25)
        
        let spin = SFWConfiguration.SpinButtonPreferences(size: CGSize(width: 20, height: 20))
        
        let sliceColorType = SFWConfiguration.ColorType.customPatternColors(colors: nil, defaultColor: .white)
        
        let slicePreferences = SFWConfiguration.SlicePreferences(backgroundColorType: sliceColorType, strokeWidth: 0, strokeColor: .white)
        
        let circlePreferences = SFWConfiguration.CirclePreferences(strokeWidth: 15, strokeColor: .clear)
        
        var wheelPreferences = SFWConfiguration.WheelPreferences(circlePreferences: circlePreferences, slicePreferences: slicePreferences, startPosition: .top)
        
        wheelPreferences.centerImageAnchor = anchorImage
        
        let configuration = SFWConfiguration(wheelPreferences: wheelPreferences, pinPreferences: pin, spinButtonPreferences: spin)
        
        return configuration
    }
}

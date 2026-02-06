//
//  O1VC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import GoogleMobileAds

class O1VC: UIViewController {

    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var buttonView: GradientDesignableView!
    @IBOutlet weak var bannerAddView: UIView!
    @IBOutlet weak var addHeightConstant: NSLayoutConstraint!
    
    private let googleBannerAds = GoogleBannerAds()
    private var bannerView: BannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    func setUI() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        buttonView.cornerRadius = buttonView.frame.height / 2
        setLcoalized()
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
    func setLcoalized() {
        self.introLabel.font = FontManager.shared.font(for: .robotoSerif, size: 24.0)
        self.introLabel.text = "Dive Into Captivating Short Dramas".localized(LocalizationService.shared.language)
        self.continueLabel.text = "Continue".localized(LocalizationService.shared.language)
    }
    
    @IBAction func continueButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "O2VC") as! O2VC
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

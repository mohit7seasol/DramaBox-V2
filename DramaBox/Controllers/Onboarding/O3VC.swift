//
//  O3VC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import GoogleMobileAds

class O3VC: UIViewController {

    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var continueButtonView: GradientDesignableView!
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
        continueButtonView.cornerRadius = continueButtonView.frame.height / 2
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
        self.introLabel.text = "Immerse In Dramas Enjoy HD Quality".localized(LocalizationService.shared.language)
        self.continueLabel.text = "Continue".localized(LocalizationService.shared.language)
    }
    
    @IBAction func continueButtonAction(_ sender: UIButton) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else { return }
        
        let tabBarVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
            .instantiateViewController(withIdentifier: Controllers.tabBarVC)
        
        window.rootViewController = tabBarVC
        window.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NotificationCenter.default.post(name: .triggerRateCheck, object: nil)
        }
    }
}

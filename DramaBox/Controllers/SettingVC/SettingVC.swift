//
//  SettingVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import StoreKit

class SettingVC: UIViewController {

    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var privacyPolicyLabel: UILabel!
    @IBOutlet weak var termsOfUseLabel: UILabel!
    @IBOutlet weak var aboutUsLabel: UILabel!
    @IBOutlet weak var eulaLabel: UILabel!
    @IBOutlet weak var rateAppLabel: UILabel!
    @IBOutlet weak var inviteFriendsLabel: UILabel!
    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var generalLabel: UILabel!
    @IBOutlet weak var otherLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    func setUI() {
        setLoca()
    }
    func setLoca() {
        self.languageLabel.text = "Language".localized(LocalizationService.shared.language)
        self.privacyPolicyLabel.text = "Privacy Policy".localized(LocalizationService.shared.language)
        self.termsOfUseLabel.text = "Terms Of Use".localized(LocalizationService.shared.language)
        self.aboutUsLabel.text = "About Us".localized(LocalizationService.shared.language)
        self.eulaLabel.text = "EULA".localized(LocalizationService.shared.language)
        self.rateAppLabel.text = "Rate App".localized(LocalizationService.shared.language)
        self.inviteFriendsLabel.text = "Invite Friends".localized(LocalizationService.shared.language)
        self.appTitleLabel.text = "Sora Pixo".localized(LocalizationService.shared.language)
        self.appTitleLabel.font = FontManager.shared.font(for: .robotoSerif, size: 20.0)
        welcomeLabel.text = "Welcome to".localized(LocalizationService.shared.language)
        generalLabel.text = "General".localized(LocalizationService.shared.language)
        generalLabel.font = FontManager.shared.font(for: .roboto, size: 18.0)
        otherLabel.text = "Other".localized(LocalizationService.shared.language)
        otherLabel.font = FontManager.shared.font(for: .roboto, size: 18.0)
    }
    // ✅ Open Language Screen
    @IBAction func languageButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Language", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "LanguageVC") as? LanguageVC {
            vc.hidesBottomBarWhenPushed = true
            vc.isOpenFromApp = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // ✅ Open Google URL
    @IBAction func privacyPolicyButtonAction(_ sender: UIButton) {
        openUrl(url: AppConstant.privacyPolicyURL)
    }

    @IBAction func termsOfUseButtonAction(_ sender: UIButton) {
        openUrl(url: AppConstant.tremsOfUseURL)
    }

    @IBAction func aboutUsButtonAction(_ sender: UIButton) {
        openUrl(url: AppConstant.tremsOfUseURL)
    }

    @IBAction func eulaButtonAction(_ sender: UIButton) {
        openUrl(url: AppConstant.EULA)
    }

    @IBAction func rateAppButtonAction(_ sender: UIButton) {
        // ✅ 1. Try to show in-app rating popup
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        
        // ✅ 2. Backup: Open App Store rating page after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.openAppStoreForRating()
        }
    }

    @IBAction func inviteFriendsButtonAction(_ sender: UIButton) {
        openAppStoreForRating()
    }

    // ✅ Common URL Opener
    private func openUrl(url: String) {
        let urlString = url

        guard let url = URL(string: urlString) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    private func openAppStoreForRating() {
        let appID = AppConstant.appID  // Example: "1234567890"
        let urlString = "https://apps.apple.com/app/id\(appID)?action=write-review"
        
        guard let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}


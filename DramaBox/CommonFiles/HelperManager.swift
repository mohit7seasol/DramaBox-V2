//
//  HelperManager.swift
//  DramaBox
//
//  Created by DREAMWORLD on 31/01/26.
//

import Foundation
import UIKit
import StoreKit
import SkeletonView

class HelperManager {
    static func showSkeleton(nativeAdView: UIView) {
        if nativeAdView.subviews.contains(where: { $0 is SkeletonCustomView4 }) {
            return
        }
        
        guard let adView = Bundle.main
            .loadNibNamed("SkeletonCustomView4", owner: nil, options: nil)?
            .first as? SkeletonCustomView4 else {
            return
        }
        
        nativeAdView.backgroundColor = UIColor.appAddBg
        nativeAdView.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            adView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor)
        ])
        
        // ✅ Safe skeleton calls
        adView.view1?.showAnimatedGradientSkeleton()
        adView.view2?.showAnimatedGradientSkeleton()
        adView.view3?.showAnimatedGradientSkeleton()
        adView.view4?.showAnimatedGradientSkeleton()
        adView.view5?.showAnimatedGradientSkeleton()
        adView.view6?.showAnimatedGradientSkeleton()
    }
    
    static func hideSkeleton(nativeAdView: UIView) {
        for subview in nativeAdView.subviews {
            if let adView = subview as? SkeletonCustomView4 {
                adView.removeFromSuperview()
            }
        }
    }
    static func showRateScreen(navigation: UIViewController) {
        let alert = UIAlertController.init(title: "Do you like our App?".localized(), message: "Help us improve the app by answering this quick poll".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "No ❌".localized(), style: .default, handler: nil))
        alert.addAction(UIAlertAction.init(title: "Yes 👍".localized(), style: .default, handler: { ACTION in
            self.rateApp()
        }))
        navigation.present(alert, animated: true, completion: nil)
    }
    
    static func rateApp() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            if let appStoreURL = URL(string: AppConstant.AppStoreLink) {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: { success in
                    if success {
                        setRateDone(status: true)
                    }
                })
            } else {
                let appStoreURL = URL(string: AppConstant.AppStoreLink)
                UIApplication.shared.openURL(appStoreURL!)
            }
        }
    }
    static func setupInitialLanguage() {
            // Ensure language is set from saved preference
            if let savedLanguage = UserDefaults.standard.string(forKey: "language"),
               let language = Language(rawValue: savedLanguage) {
                LocalizationService.shared.language = language
            } else if let savedChooseLanguage = UserDefaults.standard.string(forKey: UserDefaultKeys.selectedLanguage),
                      let chooseLanguage = SelectLanguage(rawValue: savedChooseLanguage) {
                // Fallback to your custom storage
                LocalizationService.shared.language = chooseLanguage.languageCode
            }
            // If neither exists, it will use the default from LocalizationService
  }
}

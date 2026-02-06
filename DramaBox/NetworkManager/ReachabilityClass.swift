//
//  ReachabilityClass.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import Foundation
import Reachability
import UIKit

class ReachabilityManager {
    static let shared = ReachabilityManager()
    private var reachability: Reachability!

    private init() {
        setupReachability()
    }

    private func setupReachability() {
        do {
            reachability = try Reachability()
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    func isConnectedToNetwork() -> Bool {
        return reachability.connection != .none
    }

    func showNoInternetAlert(on vc: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "No Internet Connection".localized(LocalizationService.shared.language),
                message: "Please check your network settings.".localized(LocalizationService.shared.language),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ok".localized(LocalizationService.shared.language), style: .default))
            vc.present(alert, animated: true)
        }
    }
}

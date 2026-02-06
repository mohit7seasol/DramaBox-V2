//
//  SKStoreReviewController+Extension.swift
//  NewYear2021Internal
//
//  Created by Sunil Zalavadiya on 19/11/22.
//

import StoreKit

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                requestReview(in: scene)
            }
        }
    }
}

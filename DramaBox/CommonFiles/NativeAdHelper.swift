//
//  NativeAdHelper.swift
//  DramaBox
//
//  Created by DREAMWORLD on 02/02/26.
//

import UIKit
import GoogleMobileAds

class NativeAdHelper {
    
    // MARK: - Configuration
    struct Configuration {
        let nativeAdView: UIView
        let heightConstraint: NSLayoutConstraint?
        let backgroundColor: UIColor?
        let placeholderHeight: CGFloat
        let viewController: UIViewController
        
        init(
            nativeAdView: UIView,
            heightConstraint: NSLayoutConstraint? = nil,
            backgroundColor: UIColor? = UIColor.appAddBg,
            placeholderHeight: CGFloat = 200,
            viewController: UIViewController
        ) {
            self.nativeAdView = nativeAdView
            self.heightConstraint = heightConstraint
            self.backgroundColor = backgroundColor
            self.placeholderHeight = placeholderHeight
            self.viewController = viewController
        }
    }
    
    // MARK: - Properties
    private let configuration: Configuration
    private let googleNativeAds = GoogleNativeAds()
    private var isLoading = false
    
    // MARK: - Initialization
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// Load native ad with automatic UI handling
    func loadNativeAd() {
        // Check subscription first
        guard !Subscribe.get() else {
            hideAdView()
            return
        }
        
        // Prevent duplicate loading
        guard !isLoading else { return }
        isLoading = true
        
        // Setup initial UI
        setupInitialUI()
        
        // Start loading ad
        googleNativeAds.loadAds(configuration.viewController) { [weak self] nativeAdsTemp in
            guard let self = self else { return }
            self.isLoading = false
            self.handleAdSuccess(nativeAdsTemp)
        }
        
        // Handle failure
        googleNativeAds.failAds(configuration.viewController) { [weak self] _ in
            guard let self = self else { return }
            self.isLoading = false
            self.handleAdFailure()
        }
    }
    
    /// Handle subscription changes
    func handleSubscriptionChange() {
        if Subscribe.get() {
            hideAdView()
        } else {
            // Reload ad if not subscribed
            loadNativeAd()
        }
    }
    
    /// Clean up resources
    func cleanup() {
        // Remove any existing ad views
        configuration.nativeAdView.subviews.forEach { $0.removeFromSuperview() }
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupInitialUI() {
        DispatchQueue.main.async {
            // Set initial height
            self.configuration.heightConstraint?.constant = self.configuration.placeholderHeight
            self.configuration.nativeAdView.isHidden = false
            
            // Set background color if provided
            if let backgroundColor = self.configuration.backgroundColor {
                self.configuration.nativeAdView.backgroundColor = backgroundColor
            }
            
            // Show skeleton loading
            HelperManager.showSkeleton(nativeAdView: self.configuration.nativeAdView)
            
            // Force layout update
            self.configuration.nativeAdView.layoutIfNeeded()
        }
    }
    
    private func handleAdSuccess(_ nativeAd: NativeAd) {
        DispatchQueue.main.async {
            // Hide skeleton
            HelperManager.hideSkeleton(nativeAdView: self.configuration.nativeAdView)
            
            // Set correct height
            self.configuration.heightConstraint?.constant = self.configuration.placeholderHeight
            self.configuration.nativeAdView.isHidden = false
            
            // Remove old views
            self.configuration.nativeAdView.subviews.forEach { $0.removeFromSuperview() }
            
            // Show native ad
            self.googleNativeAds.showAdsView8(
                nativeAd: nativeAd,
                view: self.configuration.nativeAdView
            )
            
            // Force layout update
            self.configuration.viewController.view.layoutIfNeeded()
        }
    }
    
    private func handleAdFailure() {
        DispatchQueue.main.async {
            // Hide skeleton
            HelperManager.hideSkeleton(nativeAdView: self.configuration.nativeAdView)
            
            // Hide ad view on failure
            self.hideAdView()
        }
    }
    
    private func hideAdView() {
        DispatchQueue.main.async {
            self.configuration.heightConstraint?.constant = 0
            self.configuration.nativeAdView.isHidden = true
            self.configuration.nativeAdView.subviews.forEach { $0.removeFromSuperview() }
            self.configuration.viewController.view.layoutIfNeeded()
        }
    }
}

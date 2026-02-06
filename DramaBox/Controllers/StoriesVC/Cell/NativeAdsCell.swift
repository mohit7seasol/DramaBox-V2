//
//  NativeAdsCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 28/01/26.
//

import UIKit
import SkeletonView
import GoogleMobileAds

enum NativeAdResult {
    case success(NativeAd)
    case failure
}

class NativeAdsCell: UITableViewCell {
    @IBOutlet weak var viewForNative: UIView!
    
    var googleNativeAds: GoogleNativeAds?
    var onAdLoadStatusChanged: ((Bool) -> Void)?   // true = failed, false = loaded
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    private func setupCell() {
        contentView.backgroundColor = .black
        viewForNative.backgroundColor = .black
        
        // Remove any existing constraints that might interfere
        contentView.translatesAutoresizingMaskIntoConstraints = false
        viewForNative.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure contentView fills the cell
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Ensure viewForNative fills contentView
            viewForNative.topAnchor.constraint(equalTo: contentView.topAnchor),
            viewForNative.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            viewForNative.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            viewForNative.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force fullscreen layout
        contentView.frame = bounds
        viewForNative.frame = contentView.bounds
        
        // Ensure the ad view takes full space
        if let adView = viewForNative.subviews.first {
            adView.frame = viewForNative.bounds
        }
    }
    enum NativeAdResult {
        case success(NativeAd)
        case failure
    }

    func loadAd(vc: UIViewController, completion: @escaping (NativeAdResult) -> Void) {
        clearAdView()
        showSkeletonView()

        googleNativeAds?.loadAds(vc) { [weak self] nativeAd in
            guard let self else { return }
            self.hideSkeletonView()
            self.bind(nativeAd: nativeAd)
            completion(.success(nativeAd))
        }

        googleNativeAds?.failAds(vc) { [weak self] _ in
            guard let self else { return }
            self.hideSkeletonView()
            self.hideAd()
            completion(.failure)
        }
    }
    func bind(nativeAd: NativeAd) {
        clearAdView()
        viewForNative.isHidden = false
        googleNativeAds?.showAdsViews(
            nativeAd: nativeAd,
            view: viewForNative
        )
    }
    func hideAd() {
        clearAdView()
        viewForNative.isHidden = true
    }

    func checkSubscribe(vc: UIViewController) {
        // Clear any existing views
        clearAdView()
        
        if Subscribe.get() == false {
            showSkeletonView()
            
            googleNativeAds?.loadAds(vc) { [weak self] nativeAdsTemp in
                guard let self = self else { return }
                
                self.hideSkeletonView()
                
                // Show ad using showAdsView7
                self.googleNativeAds?.showAdsViews(
                    nativeAd: nativeAdsTemp,
                    view: self.viewForNative
                )
                
                self.onAdLoadStatusChanged?(false)
            }
            
            googleNativeAds?.failAds(vc) { [weak self] fail in
                guard let self = self else { return }
                
                self.hideSkeletonView()
                self.viewForNative.isHidden = true
                self.onAdLoadStatusChanged?(true)
            }
            
        } else {
            hideSkeletonView()
            viewForNative.isHidden = true
            onAdLoadStatusChanged?(true)
        }
    }
    
    private func clearAdView() {
        viewForNative.subviews.forEach { $0.removeFromSuperview() }
        viewForNative.isHidden = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearAdView()
        hideSkeletonView()
        viewForNative.isHidden = true
    }
    
    
    private func showSkeletonView() {
        clearAdView()
        
        if let adView = Bundle.main.loadNibNamed("SkeletonCustomView8", owner: self, options: nil)?.first as? SkeletonCustomView8 {
            adView.frame = viewForNative.bounds
            adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewForNative.addSubview(adView)
            
            adView.view1.showAnimatedGradientSkeleton()
            adView.view2.showAnimatedGradientSkeleton()
            adView.view3.showAnimatedGradientSkeleton()
            adView.view4.showAnimatedGradientSkeleton()
            adView.view5.showAnimatedGradientSkeleton()
            adView.view6.showAnimatedGradientSkeleton()
        }
    }
    
    private func hideSkeletonView() {
        for subview in viewForNative.subviews {
            if let adView = subview as? SkeletonCustomView8 {
                adView.removeFromSuperview()
            }
        }
    }
}

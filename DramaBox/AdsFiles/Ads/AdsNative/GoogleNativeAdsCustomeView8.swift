//
//  GoogleNativeAdsCustomeView8.swift
//  EmoteAndDance
//
//  Created by Parthiv Akbari on 16/04/25.
//

import UIKit
import GoogleMobileAds

class GoogleNativeAdsCustomeView8: UIView {
    
    @IBOutlet weak var adUIView: NativeAdView!
    @IBOutlet weak var nativeAdsWidth: NSLayoutConstraint!
    // VARIABLE
    @IBOutlet weak var bgTagView: View!
    @IBOutlet weak var star1: UIImageView!
    @IBOutlet weak var star2: UIImageView!
    @IBOutlet weak var star3: UIImageView!
    @IBOutlet weak var star4: UIImageView!
    @IBOutlet weak var star5: UIImageView!
    
    var nativeAd: NativeAd = NativeAd()
    let filledStar = UIImage(systemName: "star.fill")
    let emptyStar = UIImage(systemName: "star")
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "GoogleNativeAdsCustomeView8", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Methods
    func setup() {
        bgTagView.roundCorners(corners: [.allCorners], radius: 2)
        // Get the ad view from the Cell. The view hierarchy for this cell is defined in
        // UnifiedNativeAdCell.xib.
        let adView : NativeAdView = adUIView
        
        // Associate the ad view with the ad object.
        // This is required to make the ad clickable.
        adView.nativeAd = nativeAd
        setStarRating(nativeAd.starRating)
        // Populate the ad view with the ad assets.
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (adView.headlineView as! UILabel).text = nativeAd.headline
        (adView.headlineView as! UILabel).textColor = .white
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        (adView.bodyView as! UILabel).text = (nativeAd.body ?? "")
        
        // The SDK automatically turns off user interaction for assets that are part of the ad, but
        // it is still good to be explicit.
        (adView.callToActionView as! UIButton).isUserInteractionEnabled = false
        (adView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: UIControl.State.normal)
        (adView.callToActionView as! UIButton).backgroundColor = Common().hexStringToUIColor(hex: addButtonColor)
        (adView.callToActionView as? UIButton)?.layer.cornerRadius = 20
        (adView.iconView as? UIImageView)?.layer.cornerRadius = 5
        
        adView.backgroundColor = UIColor.clear
        let data = (adView.iconView as? UIImageView)?.image?.pngData()
        if data == nil {
            nativeAdsWidth.constant = 0
        }
    }
    
    func setStarRating(_ rating: NSDecimalNumber?) {
        let stars = [star1, star2, star3, star4, star5]
        guard let ratingValue = rating?.doubleValue else {
            // Hide stars if no rating
            stars.forEach { $0?.isHidden = true }
            return
        }
        
        for (index, star) in stars.enumerated() {
            star?.isHidden = false
            if Double(index) < ratingValue {
                star?.image = filledStar
            } else {
                star?.image = emptyStar
            }
        }
    }
    
}


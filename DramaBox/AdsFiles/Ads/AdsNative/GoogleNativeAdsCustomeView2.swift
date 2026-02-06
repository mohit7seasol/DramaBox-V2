//
//  GoogleNativeAdsCustomeView4.swift
//  NewGB
//
//  Created by Piyush on 06/08/23.
//

import UIKit
import GoogleMobileAds

class GoogleNativeAdsCustomeView2: UIView {
    
    // OUTLET
    @IBOutlet var adUIView: NativeAdView!
    
    // VARIABLE
    var nativeAd: NativeAd = NativeAd()
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "GoogleNativeAdsCustomeView2", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Methods
    func setup() {
        
        // Get the ad view from the Cell. The view hierarchy for this cell is defined in
        // UnifiedNativeAdCell.xib.
        let adView : NativeAdView = adUIView
        
        // Associate the ad view with the ad object.
        // This is required to make the ad clickable.
        adView.nativeAd = nativeAd
        
        // Populate the ad view with the ad assets.
        (adView.headlineView as! UILabel).text = nativeAd.headline
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        (adView.bodyView as! UILabel).text = "\t" + (nativeAd.body ?? "")
        
        // The SDK automatically turns off user interaction for assets that are part of the ad, but
        // it is still good to be explicit.
        (adView.callToActionView as! UIButton).isUserInteractionEnabled = false
        (adView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: UIControl.State.normal)
        (adView.callToActionView as! UIButton).backgroundColor = Common().hexStringToUIColor(hex: addButtonColor)
    }
}

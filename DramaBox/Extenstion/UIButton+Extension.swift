//
//  UIButton+Extension.swift
//  GBVersionApp_1
//
//  Created by iMac on 09/05/23.
//

import Foundation
import UIKit

extension UIButton {
    
    public func centerVertically(withPadding padding: CGFloat) {
        let imageSize: CGSize? = imageView?.frame.size
        let titleString: NSString = (self.titleLabel?.text)! as NSString
        let titleSize: CGSize = titleString.size(withAttributes: [NSAttributedString.Key.font: (self.titleLabel?.font)!])
        
        let totalHeight = (imageSize?.height ?? 0.0) + (titleSize.height ) + CGFloat(padding)
        
        imageEdgeInsets = UIEdgeInsets(top: -(totalHeight - (imageSize?.height ?? 0.0)), left: 0.0, bottom: 0.0, right: -(titleSize.width ))
        
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: -(imageSize?.width ?? 0.0), bottom: -(totalHeight - (titleSize.height )), right: 0.0)
    }
    
}

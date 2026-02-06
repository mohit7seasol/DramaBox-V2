//
//  TextField.swift
//

import Foundation
import UIKit

// @IBDesignable
class TextField: UITextField {
    
    // MARK: - Apply Localization
    override func awakeFromNib() {
        super.awakeFromNib()
        
       // NotificationCenter.default.addObserver(self, selector: #selector(applyLocalization), name: NOTIFICATION.localization, object: nil)
    }
    
    @IBInspectable
    var localizationText: String = "" {
        didSet {
            if localizationText.isEmpty {
                localizationText = self.placeholder ?? ""
                applyLocalization()
            } else {
                applyLocalization()
            }
        }
    }
    
    @objc func applyLocalization() {
        self.placeholder = localizationText
    }
}

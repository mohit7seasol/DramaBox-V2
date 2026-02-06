//
//  Searchbar.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import UIKit

struct SearchBarStyle {

    static func apply(
        to searchBar: UISearchBar,
        placeholder: String = "Search here..."
    ) {
        let textField = searchBar.searchTextField

        // ✅ Placeholder
        textField.placeholder = placeholder
        textField.textColor = .white

        // ✅ Remove default background
        searchBar.backgroundImage = UIImage()

        // ✅ Force Custom Left Icon (FIXED)
        let leftIconView = UIImageView(image: UIImage(named: "search_ic"))
        leftIconView.contentMode = .scaleAspectFit
        leftIconView.tintColor = .white
        leftIconView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 24))
        leftIconView.center = leftContainer.center
        leftContainer.addSubview(leftIconView)

        textField.leftView = leftContainer
        textField.leftViewMode = .always

        // ✅ Apply after autolayout
        DispatchQueue.main.async {

            // Corner radius (Height / 2)
            textField.layer.cornerRadius = textField.frame.height / 2
            textField.layer.masksToBounds = true

            // ✅ Gradient Background
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor(hex: "#242424")!.cgColor,
                UIColor(hex: "#252525")!.cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint   = CGPoint(x: 1, y: 1)
            gradient.frame = textField.bounds
            gradient.cornerRadius = textField.frame.height / 2

            // Remove old gradients
            textField.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            textField.layer.insertSublayer(gradient, at: 0)
        }
    }
}


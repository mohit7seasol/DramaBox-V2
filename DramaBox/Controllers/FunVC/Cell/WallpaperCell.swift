//
//  WallpaperCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 16/01/26.
//

import UIKit

class WallpaperCell: UICollectionViewCell {

    @IBOutlet weak var wallpaperImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configure(with imageURL: String?) {
        // Reset to default image first
        wallpaperImageView.image = UIImage(named: "wallpaper_place_img")
        
        guard let urlString = imageURL, let url = URL(string: urlString) else {
            return
        }
        
        // Load image asynchronously
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.wallpaperImageView.image = image
                }
            }
        }
    }
}

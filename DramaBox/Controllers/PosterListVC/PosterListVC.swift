//
//  PosterListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 22/01/26.
//

import UIKit
import SDWebImage
import SafariServices

class PosterListVC: UIViewController {
    
    @IBOutlet weak var posterCollection: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var posters: [ImageData] = []
    var videos: [Video] = [] // Add videos property
    var selectedIndex = 0
    var isPoster: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigation()
    }
    
    private func setupNavigation() {
        // Update navigation title based on content type
        if isPoster {
            titleLabel.text = "Posters".localized(LocalizationService.shared.language)
        } else {
            titleLabel.text = "Videos".localized(LocalizationService.shared.language)
        }
    }
    
    private func setupCollectionView() {
        // Create custom layout for 2x2 grid
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        // Calculate cell size for 2x2 grid
        let spacing: CGFloat = 10
        let totalHorizontalSpacing = spacing * 3 // left + right + between columns
        let itemWidth = (posterCollection.frame.width - totalHorizontalSpacing) / 2
        
        // For videos, use different aspect ratio (16:9)
        let itemHeight: CGFloat
        if isPoster {
            // Maintain 2:3 aspect ratio for posters (standard movie poster ratio)
            itemHeight = itemWidth * 1.5
        } else {
            // Use 16:9 aspect ratio for videos
            itemHeight = itemWidth * 9 / 16
        }
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        
        posterCollection.collectionViewLayout = layout
        posterCollection.delegate = self
        posterCollection.dataSource = self
        posterCollection.backgroundColor = .clear
        
        // Register cell
        posterCollection.register(UINib(nibName: "MovieYoutubeVideoCell", bundle: nil), forCellWithReuseIdentifier: "MovieYoutubeVideoCell")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 10
        let totalHorizontalSpacing = spacing * 3
        let itemWidth = (collectionView.frame.width - totalHorizontalSpacing) / 2
        
        let itemHeight: CGFloat
        if isPoster {
            // Poster aspect ratio 2:3
            itemHeight = itemWidth * 1.5
        } else {
            // Video aspect ratio 16:9
            itemHeight = itemWidth * 9 / 16
        }
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension PosterListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isPoster {
            return posters.count
        } else {
            return videos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieYoutubeVideoCell", for: indexPath) as! MovieYoutubeVideoCell
        
        if isPoster {
            // Configure for posters
            let poster = posters[indexPath.item]
            let imageUrl = "https://image.tmdb.org/t/p/w500\(poster.filePath)"
            if let url = URL(string: imageUrl) {
                cell.videoThumbImageView.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "hoteDefault"),
                    options: [.retryFailed, .continueInBackground]
                )
            }
            // Hide play button for posters
            cell.playButton.isHidden = true
            
        } else {
            // Configure for videos
            let video = videos[indexPath.item]
            let youtubeThumbUrl = "https://img.youtube.com/vi/\(video.key)/0.jpg"
            if let url = URL(string: youtubeThumbUrl) {
                cell.videoThumbImageView.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "hoteDefault"),
                    options: [.retryFailed, .continueInBackground]
                )
            }
            cell.playButton.setOnClickListener {
                self.openYouTube(videoKey: video.key)
            }
            // Show play button for videos
            cell.playButton.isHidden = false
        }
        
        // Style the cell
        cell.layer.cornerRadius = 16
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.darkGray.cgColor
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        
        if isPoster {
            // Open poster details for posters
            openPosterDetailsVC()
        } else {
            // Play video for videos
            let video = videos[indexPath.item]
            openYouTube(videoKey: video.key)
        }
    }
    
    private func openPosterDetailsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let posterDetailsVC = storyboard.instantiateViewController(withIdentifier: "PosterDetailsVC") as? PosterDetailsVC {
            posterDetailsVC.posters = posters
            posterDetailsVC.currentIndex = selectedIndex
            posterDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(posterDetailsVC, animated: true)
        }
    }
    
    private func openYouTube(videoKey: String) {
        let url = URL(string: "https://www.youtube.com/watch?v=\(videoKey)")!
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        self.present(safariVC, animated: true)
    }
}

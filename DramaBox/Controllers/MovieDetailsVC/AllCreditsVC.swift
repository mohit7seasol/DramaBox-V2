//
//  AllCreditsVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

import UIKit
import SDWebImage
import MarqueeLabel

class AllCreditsVC: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    // MARK: - Properties
    var creditsData: [PersonCreditItem] = []// This will hold the combinedCredits array
    var screenTitle: String = "Movie"
    var dataType: DataType = .cast // Default to cast
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }
    
    private func setupUI() {
        titleLabel.text = screenTitle.localized(LocalizationService.shared.language)
        subscribeNativeAd()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
    
    func subscribeNativeAd() {
        nativeHeighConstant.constant = Subscribe.get() ? 0 : 200
        addNativeView.isHidden = Subscribe.get()

        guard Subscribe.get() == false else {
            HelperManager.hideSkeleton(nativeAdView: addNativeView)
            return
        }

        addNativeView.backgroundColor = UIColor.appAddBg
        HelperManager.showSkeleton(nativeAdView: addNativeView)

        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 200
                self.addNativeView.isHidden = false
                self.addNativeView.subviews.forEach { $0.removeFromSuperview() }
                self.googleNativeAds.showAdsView8(
                    nativeAd: nativeAdsTemp,
                    view: self.addNativeView
                )
                self.view.layoutIfNeeded()
            }
        }

        googleNativeAds.failAds(self) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 0
                self.addNativeView.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        
        // Register cell
        collectionView.register(UINib(nibName: "TopCastAndCrewCell", bundle: nil), forCellWithReuseIdentifier: "TopCastAndCrewCell")
        
        // Setup layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        collectionView.collectionViewLayout = layout
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        self.collectionView.reloadData()
    }
}

// MARK: - UICollectionView for AllCreditsVC
extension AllCreditsVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return creditsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopCastAndCrewCell", for: indexPath) as! TopCastAndCrewCell
        let creditItem = creditsData[indexPath.item]
        
        // Configure the cell based on the enum case
        switch creditItem {
        case .movieCast(let cast):
            configureCell(cell: cell, cast: cast)
        case .movieCrew(let crew):
            configureCell(cell: cell, crew: crew)
        case .tvCast(let tvCast):
            configureCell(cell: cell, tvCast: tvCast)
        case .tvCrew(let tvCrew):
            configureCell(cell: cell, tvCrew: tvCrew)
        }
        
        cell.setOnClickListener { [weak self] in
            guard let self = self else { return }
            
            // Get the credit item at the tapped indexPath
            let tappedCreditItem = self.creditsData[indexPath.item]
            
            // Extract ID and determine type
            switch tappedCreditItem {
            case .movieCast(let cast):
                self.navigateToMovieDetails(movieId: cast.id, isMovie: true)
            case .movieCrew(let crew):
                self.navigateToMovieDetails(movieId: crew.id, isMovie: true)
            case .tvCast(let tvCast):
                self.navigateToMovieDetails(movieId: tvCast.id, isMovie: false)
            case .tvCrew(let tvCrew):
                self.navigateToMovieDetails(movieId: tvCrew.id, isMovie: false)
            }
        }
        
        return cell
    }
    
    private func configureCell(cell: TopCastAndCrewCell, cast: PersonCast) {
        if let posterPath = cast.posterPath, !posterPath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.nameLabel.text = cast.title
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", cast.popularity))"
        applyCommonStyling(cell: cell)
    }
    
    private func configureCell(cell: TopCastAndCrewCell, crew: PersonCrew) {
        if let posterPath = crew.posterPath, !posterPath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.nameLabel.text = crew.title
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", crew.popularity))"
        applyCommonStyling(cell: cell)
    }
    
    private func configureCell(cell: TopCastAndCrewCell, tvCast: PersonTVCast) {
        if let posterPath = tvCast.posterPath, !posterPath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.nameLabel.text = tvCast.name
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", tvCast.popularity))"
        applyCommonStyling(cell: cell)
    }
    
    private func configureCell(cell: TopCastAndCrewCell, tvCrew: PersonTVCrew) {
        if let posterPath = tvCrew.posterPath, !posterPath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.nameLabel.text = tvCrew.name
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", tvCrew.popularity))"
        applyCommonStyling(cell: cell)
    }
    
    private func applyCommonStyling(cell: TopCastAndCrewCell) {
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
        
        // Configure marquee labels
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        cell.designationLabel.type = .continuous
        cell.designationLabel.speed = .duration(15)
        cell.designationLabel.fadeLength = 10.0
        cell.designationLabel.trailingBuffer = 30.0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        let columns: CGFloat = isPad ? 5 : 2
        let spacing: CGFloat = 10
        let sectionInset: CGFloat = 10 * 2   // left + right
        let totalSpacing = (columns - 1) * spacing + sectionInset

        let itemWidth = (collectionView.bounds.width - totalSpacing) / columns

        return CGSize(width: floor(itemWidth), height: 168)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle item selection if needed
        print("Selected credit at index: \(indexPath.item)")
    }
    func navigateToMovieDetails(movieId: Int, isMovie: Bool = true) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "MovieDetailsVC") as? MovieDetailsVC {
            if isMovie {
                vc.movieId = movieId
                vc.isShowingMovies = true
            } else {
                vc.tvShowId = movieId
                vc.isShowingMovies = false
            }
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    private func extractMovieOrTVId(from credit: Any) -> Int? {
        if let cast = credit as? PersonCast {
            return cast.id
        } else if let crew = credit as? PersonCrew {
            return crew.id
        } else if let tvCast = credit as? PersonTVCast {
            return tvCast.id
        } else if let tvCrew = credit as? PersonTVCrew {
            return tvCrew.id
        }
        return nil
    }
}

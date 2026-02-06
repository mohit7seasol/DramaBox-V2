//
//  TopCastAndCrewListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

import UIKit
import MarqueeLabel
import SDWebImage

enum DataType {
    case cast
    case crew
}

class TopCastAndCrewListVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    var dataType: DataType = .cast
    var castData: [MovieCast] = []
    var crewData: [MovieCrew] = []
    var screenTitle: String = ""
    var movieTitle: String = ""
    
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
        
        // 3) Register cell
        collectionView.register(UINib(nibName: "TopCastAndCrewCell", bundle: nil), forCellWithReuseIdentifier: "TopCastAndCrewCell")
        
        // 3) Setup layout
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

// MARK: - UICollectionView for TopCastAndCrewListVC
extension TopCastAndCrewListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch dataType {
        case .cast:
            return castData.count
        case .crew:
            return crewData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopCastAndCrewCell", for: indexPath) as! TopCastAndCrewCell
        
        switch dataType {
        case .cast:
            if indexPath.item < castData.count {
                let castMember = castData[indexPath.item]
                configureCastCell(cell: cell, castMember: castMember)
            }
        case .crew:
            if indexPath.item < crewData.count {
                let crewMember = crewData[indexPath.item]
                configureCrewCell(cell: cell, crewMember: crewMember)
            }
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var personId: Int?
        
        switch dataType {
        case .cast:
            if indexPath.item < castData.count {
                personId = castData[indexPath.item].id
            }
        case .crew:
            if indexPath.item < crewData.count {
                personId = crewData[indexPath.item].id
            }
        }
        
        guard let personId = personId else {
            print("⚠️ No person ID found")
            return
        }
        
        // Navigate to CelebrityDetailsVC
        navigateToCelebrityDetails(personId: personId)
    }
    private func navigateToCelebrityDetails(personId: Int) {
        // 1. Get reference to CelebrityDetailsVC from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with your storyboard name
        guard let celebrityDetailsVC = storyboard.instantiateViewController(withIdentifier: "CelebrityDetailsVC") as? CelebrityDetailsVC else {
            print("❌ Failed to instantiate CelebrityDetailsVC")
            return
        }
        
        // 2. Configure the VC with person ID
        celebrityDetailsVC.configure(with: personId)
        
        // 3. Push to navigation controller
        self.navigationController?.pushViewController(celebrityDetailsVC, animated: true)
    }
    private func configureCastCell(cell: TopCastAndCrewCell, castMember: MovieCast) {
        // Set cast member image
        if let profilePath = castMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
        
        // Set cast member name with marquee
        cell.nameLabel.text = castMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set character/role
        if let character = castMember.character {
            cell.designationLabel.text = character
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Actor/Actress"
        }
    }
    
    private func configureCrewCell(cell: TopCastAndCrewCell, crewMember: MovieCrew) {
        // Set crew member image
        if let profilePath = crewMember.profilePath, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(profilePath)"
            if let url = URL(string: imageUrl) {
                cell.thumbImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "crewcast_default"))
            } else {
                cell.thumbImageView.image = UIImage(named: "crewcast_default")
            }
        } else {
            cell.thumbImageView.image = UIImage(named: "crewcast_default")
        }
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
        
        // Set crew member name with marquee
        cell.nameLabel.text = crewMember.name
        cell.nameLabel.type = .continuous
        cell.nameLabel.speed = .duration(15)
        cell.nameLabel.fadeLength = 10.0
        cell.nameLabel.trailingBuffer = 30.0
        
        // Set department and job
        if let job = crewMember.job {
            cell.designationLabel.text = job
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else if let department = crewMember.department {
            cell.designationLabel.text = department
            cell.designationLabel.type = .continuous
            cell.designationLabel.speed = .duration(15)
            cell.designationLabel.fadeLength = 10.0
            cell.designationLabel.trailingBuffer = 30.0
        } else {
            cell.designationLabel.text = "Crew Member"
        }
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
    
    // 3) Set insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

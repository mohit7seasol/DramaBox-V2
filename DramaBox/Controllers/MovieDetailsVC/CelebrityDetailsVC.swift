//
//  CelebrityDetailsVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

import UIKit
import SVProgressHUD
import MarqueeLabel

enum PersonCreditItem {
    case movieCast(PersonCast)
    case movieCrew(PersonCrew)
    case tvCast(PersonTVCast)
    case tvCrew(PersonTVCrew)
}

class CelebrityDetailsVC: UIViewController {
    
    @IBOutlet weak var backgroundBlureProfileImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var knowLbl: UILabel!
    @IBOutlet weak var birthdayLbl: UILabel!
    @IBOutlet weak var birthPlaceLbl: UILabel!
    @IBOutlet weak var knowDataLbl: UILabel!
    @IBOutlet weak var birthdayDataLbl: UILabel!
    @IBOutlet weak var birthPlaceDataLbl: UILabel!
    @IBOutlet weak var biographyLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet weak var movieLbl: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    @IBOutlet weak var movieCollection: UICollectionView!
    @IBOutlet weak var noDataMovieImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    // MARK: - Properties
    private var personDetails: PersonDetails?
    private var personMovieCredits: PersonMovieCreditsResponse?
    private var personTVCredits: PersonTVCreditsResponse?
    private var combinedCredits: [PersonCreditItem] = []
    private var personId: Int = 0
    private var isDescriptionExpanded = false
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        fetchPersonDetails(personId: personId)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 1. Ensure scroll view content starts from top
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func setUI() {
        // 1. Remove scroll view top space
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        setCollection()
        setLoca()
        configureSegmentControl()
        setupReadMoreButton()
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
    
    func setCollection() {
        movieCollection.delegate = self
        movieCollection.dataSource = self
        movieCollection.register(UINib(nibName: "TopCastAndCrewCell", bundle: nil), forCellWithReuseIdentifier: "TopCastAndCrewCell")
        
        if let layout = movieCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
        }
    }
    
    func setLoca() {
        knowLbl.text = "Known for:".localized(LocalizationService.shared.language)
        birthdayLbl.text = "Birthday:".localized(LocalizationService.shared.language)
        birthPlaceLbl.text = "Place of Birth:".localized(LocalizationService.shared.language)
        biographyLbl.text = "Biography".localized(LocalizationService.shared.language)
        movieLbl.text = "Movie".localized(LocalizationService.shared.language)
        viewAllButton.setTitle("View All".localized(LocalizationService.shared.language), for: .normal)
        segmentController.setTitle("Movie".localized(LocalizationService.shared.language), forSegmentAt: 0)
        segmentController.setTitle("Tv Show".localized(LocalizationService.shared.language), forSegmentAt: 1)
    }
    
    private func configureSegmentControl() {
        segmentController.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .selected)
        
        segmentController.setTitleTextAttributes([
            .foregroundColor: UIColor(hex: "#909090"),
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ], for: .normal)
        
        if #available(iOS 13.0, *) {
            segmentController.selectedSegmentTintColor = UIColor(hex: "#FEDB4B")
        } else {
            segmentController.tintColor = UIColor(hex: "#FEDB4B")
        }
        
        segmentController.backgroundColor = UIColor(hex: "#2D2C30")
        segmentController.layer.cornerRadius = 8
        segmentController.layer.masksToBounds = true
    }
    
    private func setupReadMoreButton() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(readMoreTapped))
        descriptionLbl.isUserInteractionEnabled = true
        descriptionLbl.addGestureRecognizer(tapGesture)
    }
    
    @objc private func readMoreTapped() {
        isDescriptionExpanded.toggle()
        updateDescriptionLabel()
    }
    
    private func updateDescriptionLabel() {
        guard let biography = personDetails?.biography, !biography.isEmpty else {
            descriptionLbl.text = "No biography available.".localized(LocalizationService.shared.language)
            return
        }
        
        if isDescriptionExpanded {
            // Expanded state - show all text
            descriptionLbl.numberOfLines = 0
            descriptionLbl.text = biography + " Read Less".localized(LocalizationService.shared.language)
            
            // Make "Read Less" clickable
            let attributedString = NSMutableAttributedString(string: biography + " Read Less".localized(LocalizationService.shared.language))
            let readLessRange = (attributedString.string as NSString).range(of: "Read Less".localized(LocalizationService.shared.language))
            attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: readLessRange)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: descriptionLbl.font.pointSize, weight: .medium), range: readLessRange)
            
            descriptionLbl.attributedText = attributedString
        } else {
            // Collapsed state - show only 4 lines
            descriptionLbl.numberOfLines = 4
            
            // Simple truncation logic
            let maxChars = 200 // Adjust this value based on your font size and label width
            
            if biography.count > maxChars {
                // Find a good break point
                var truncated = String(biography.prefix(maxChars))
                
                // Look for sentence end
                if let lastPeriod = truncated.lastIndex(of: ".") {
                    truncated = String(truncated.prefix(through: lastPeriod))
                } else if let lastSpace = truncated.lastIndex(of: " ") {
                    truncated = String(truncated.prefix(upTo: lastSpace))
                }
                
                let finalText = truncated.trimmingCharacters(in: .whitespacesAndNewlines) + "..."
                descriptionLbl.text = finalText + " Read More".localized(LocalizationService.shared.language)
                
                // Make "Read More" clickable
                let attributedString = NSMutableAttributedString(string: finalText + "... Read More".localized(LocalizationService.shared.language))
                let readMoreRange = (attributedString.string as NSString).range(of: "Read More".localized(LocalizationService.shared.language))
                attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: readMoreRange)
                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: descriptionLbl.font.pointSize, weight: .medium), range: readMoreRange)
                
                descriptionLbl.attributedText = attributedString
            } else {
                // Text is short enough to fit
                descriptionLbl.text = biography
            }
        }
    }
    
    private func fillData() {
        guard let person = personDetails else { return }
        
        // Set default images first
        let defaultImage = UIImage(named: "crewcast_default") ?? UIImage()
        let defaultImageBackground = UIImage(named: "hoteDefault") ?? UIImage()
        backgroundBlureProfileImageView.image = defaultImageBackground
        profileImageView.image = defaultImage
        
        // 1. Set profile image with blur
        if let profilePath = person.profile_path, !profilePath.isEmpty {
            let imageUrl = "https://image.tmdb.org/t/p/w500\(profilePath)"
            
            // Set background blur image
            backgroundBlureProfileImageView.setImage(with: imageUrl) { [weak self] image in
                guard let self = self, let image = image else {
                    // If image loading fails, keep default image
                    self?.backgroundBlureProfileImageView.image = defaultImage
                    return
                }
                // Apply 10% blur
                let blurredImage = image.applyBlur(radius: image.size.width * 0.01)
                self.backgroundBlureProfileImageView.image = blurredImage
            }
            
            // 2. Set profile image in profileImageView
            profileImageView.setImage(with: imageUrl) { [weak self] image in
                guard let self = self else { return }
                if image == nil {
                    // If image loading fails, set default image
                    self.profileImageView.image = defaultImage
                }
                self.profileImageView.clipsToBounds = true
            }
        } else {
            // If no profile path, ensure default images are set
            backgroundBlureProfileImageView.image = defaultImage
            profileImageView.image = defaultImage
            profileImageView.clipsToBounds = true
        }
        
        // 3. Set name
        nameLabel.text = person.name
        
        // 4. Set known for data (roles)
        knowDataLbl.text = person.known_for_department
        
        // 5. Format and set birthday
        if let birthday = person.birthday, !birthday.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: birthday) {
                dateFormatter.dateFormat = "MMM dd, yyyy"
                birthdayDataLbl.text = dateFormatter.string(from: date)
            } else {
                birthdayDataLbl.text = birthday
            }
        } else {
            birthdayDataLbl.text = "N/A"
        }
        
        // 6. Set birth place
        birthPlaceDataLbl.text = person.place_of_birth ?? "N/A"
        
        // 7. Set description with read more functionality
        updateDescriptionLabel()
        
        // Fetch credits after getting person details
        fetchPersonMovieCredits(personId: personId)
        fetchPersonTVCredits(personId: personId)
    }
    private func combineCredits() {
        combinedCredits.removeAll()

        if segmentController.selectedSegmentIndex == 0 {
            // Movies
            if let movieCredits = personMovieCredits {
                movieCredits.cast.forEach {
                    combinedCredits.append(.movieCast($0))
                }
                movieCredits.crew.forEach {
                    combinedCredits.append(.movieCrew($0))
                }
            }
        } else {
            // TV
            if let tvCredits = personTVCredits {
                tvCredits.cast.forEach {
                    combinedCredits.append(.tvCast($0))
                }
                tvCredits.crew.forEach {
                    combinedCredits.append(.tvCrew($0))
                }
            }
        }

        DispatchQueue.main.async {
            self.noDataMovieImageView.isHidden = !self.combinedCredits.isEmpty
            self.viewAllButton.isHidden = self.combinedCredits.isEmpty
            self.movieCollection.isHidden = self.combinedCredits.isEmpty
            self.movieCollection.reloadData()
        }
    }

    
    // MARK: - Open from TopCastAndCrewListVC
    func configure(with personId: Int) {
        self.personId = personId
    }
    
    @IBAction func shareButtonTap(_ sender: UIButton) {
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CelebrityDetailsVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return combinedCredits.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopCastAndCrewCell", for: indexPath) as? TopCastAndCrewCell else {
            return UICollectionViewCell()
        }
        
        let creditItem = combinedCredits[indexPath.row]
        
        switch creditItem {
        case .movieCast(let cast):
            configureMovieCastCell(cell: cell, cast: cast)
        case .movieCrew(let crew):
            configureMovieCrewCell(cell: cell, crew: crew)
        case .tvCast(let tvCast):
            configureTVCastCell(cell: cell, tvCast: tvCast)
        case .tvCrew(let tvCrew):
            configureTVCrewCell(cell: cell, tvCrew: tvCrew)
        }
        
        cell.setOnClickListener { [weak self, indexPath] in
            guard let self = self else { return }
            
            // Ensure indexPath is still valid
            guard indexPath.row < self.combinedCredits.count else { return }
            
            // Get the credit item at the tapped indexPath
            let tappedCreditItem = self.combinedCredits[indexPath.row]
            
            // Extract ID and determine type, then navigate
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
    
    private func configureMovieCastCell(cell: TopCastAndCrewCell, cast: PersonCast) {
        if let posterPath = cast.posterPath {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            cell.thumbImageView.setImage(with: imageUrl)
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        cell.nameLabel.text = cast.title
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", cast.popularity))"
        
        // Apply common styling
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
    }
    
    private func configureMovieCrewCell(cell: TopCastAndCrewCell, crew: PersonCrew) {
        if let posterPath = crew.posterPath {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            cell.thumbImageView.setImage(with: imageUrl)
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        cell.nameLabel.text = crew.title
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", crew.popularity))"
        
        // Apply common styling
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
    }
    
    private func configureTVCastCell(cell: TopCastAndCrewCell, tvCast: PersonTVCast) {
        if let posterPath = tvCast.posterPath {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            cell.thumbImageView.setImage(with: imageUrl)
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        cell.nameLabel.text = tvCast.name
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", tvCast.popularity))"
        
        // Apply common styling
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
    }
    
    private func configureTVCrewCell(cell: TopCastAndCrewCell, tvCrew: PersonTVCrew) {
        if let posterPath = tvCrew.posterPath {
            let imageUrl = "https://image.tmdb.org/t/p/w200\(posterPath)"
            cell.thumbImageView.setImage(with: imageUrl)
        } else {
            cell.thumbImageView.image = UIImage(named: "hoteDefault")
        }
        cell.nameLabel.text = tvCrew.name
        cell.designationLabel.text = "Popularity: \(String(format: "%.1f", tvCrew.popularity))"
        
        // Apply common styling
        cell.thumbImageView.layer.cornerRadius = 28.0
        cell.thumbImageView.layer.borderWidth = 1.5
        cell.thumbImageView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 2.6
        
        return UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: width, height: 250) : CGSize(width: width, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
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
}

// MARK: - Button's Action
extension CelebrityDetailsVC {
    @IBAction func backButtonTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentTap(_ sender: UISegmentedControl) {
        combineCredits()
    }
    
    @IBAction func viewAllButtonTap(_ sender: UIButton) {
        navigateToAllCreditsVC()
    }
    private func navigateToAllCreditsVC() {
        // 1. Get reference to AllCreditsVC from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Replace "Main" with your storyboard name
        guard let allCreditsVC = storyboard.instantiateViewController(withIdentifier: "AllCreditsVC") as? AllCreditsVC else {
            print("❌ Failed to instantiate AllCreditsVC")
            return
        }
        
        // 2. Pass the combinedCredits array
        allCreditsVC.creditsData = combinedCredits
        
        // 3. Set appropriate title based on selected segment
        if segmentController.selectedSegmentIndex == 0 {
            allCreditsVC.screenTitle = "\(personDetails?.name ?? "Person")'s Movies"
        } else {
            allCreditsVC.screenTitle = "\(personDetails?.name ?? "Person")'s TV Shows"
        }
        
        // 4. Push to navigation controller
        self.navigationController?.pushViewController(allCreditsVC, animated: true)
    }
    @objc private func subscriptionUpdated() {
        print("💎 Subscription updated – refreshing DramaListVC")
        self.nativeHeighConstant.constant = 0
        self.addNativeView.isHidden = true
        self.scrollView.setNeedsLayout()
        self.scrollView.layoutIfNeeded()
    }
}

// MARK: - Api's calling
extension CelebrityDetailsVC {
    private func fetchPersonDetails(personId: Int) {
        SVProgressHUD.show()
        
        NetworkManager.shared.fetchPersonDetails(personId: personId, from: self) { [weak self] result in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success(let personDetails):
                self.personDetails = personDetails
                DispatchQueue.main.async {
                    self.fillData()
                }
                
            case .failure(let error):
                print("❌ Error loading person details:", error)
            }
        }
    }
    
    private func fetchPersonMovieCredits(personId: Int) {
        SVProgressHUD.show()
        
        NetworkManager.shared.fetchPersonMovieCredits(personId: personId) { [weak self] result in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success(let credits):
                self.personMovieCredits = credits
                if self.segmentController.selectedSegmentIndex == 0 {
                    self.combineCredits()
                }
                
            case .failure(let error):
                print("❌ Error loading person movie credits:", error)
            }
        }
    }
    
    private func fetchPersonTVCredits(personId: Int) {
        SVProgressHUD.show()
        
        NetworkManager.shared.fetchPersonTVCredits(personId: personId) { [weak self] result in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success(let credits):
                self.personTVCredits = credits
                if self.segmentController.selectedSegmentIndex == 1 {
                    self.combineCredits()
                }
                
            case .failure(let error):
                print("❌ Error loading person TV credits:", error)
            }
        }
    }
}

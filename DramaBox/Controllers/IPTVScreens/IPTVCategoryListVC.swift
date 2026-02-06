//
//  IPTVCategoryListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import UIKit
import SDWebImage

class IPTVCategoryListVC: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categorySelectedImageView: UIImageView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var countrySelectedImageView: UIImageView!
    @IBOutlet weak var titelLabel: UILabel!
    @IBOutlet weak var noDataFoundLbl: UILabel!
    @IBOutlet weak var noDataView: UIView!
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    // MARK: - Data Properties
    private var categories: [IPTVCategory] = []
    private var countries: [IPTVGroup] = []
    private var filteredCategories: [IPTVCategory] = []
    private var filteredCountries: [IPTVGroup] = []
    private var currentSelectionType: SelectionType = .category // Default selected
    private var isSearching = false
    
    enum SelectionType {
        case category
        case country
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupCollectionView()
        setUpSearchBar()
        fetchIPTVData()
        updateSelectionUI()
        subscribeNativeAd()
    }
    
    func setUI() {
        // Setup labels with default colors
        categoryLabel.textColor = .white // Selected by default
        countryLabel.textColor = UIColor(hex: "#878787") // Unselected by default
        categorySelectedImageView.isHidden = false
        countrySelectedImageView.isHidden = true
        titelLabel.text = "IPTV".localized(LocalizationService.shared.language)
        categoryLabel.text = "Category".localized(LocalizationService.shared.language)
        countryLabel.text = "Country".localized(LocalizationService.shared.language)
        noDataFoundLbl.text = "No data found".localized(LocalizationService.shared.language)
        
        // Add notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
    
    // MARK: - Collection View Setup
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "IPTVCategoryCell", bundle: nil), forCellWithReuseIdentifier: "IPTVCategoryCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        collectionView.collectionViewLayout = layout
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.isUserInteractionEnabled = true
        collectionView.keyboardDismissMode = .onDrag
    }
    
    // MARK: - Search Bar Setup
    func setUpSearchBar() {
        SearchBarStyle.apply(to: searchBar)
        self.searchBar.placeholder = "Search here...".localized(LocalizationService.shared.language)
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.tintColor = .white
            textField.textColor = .white
            
            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            textField.attributedPlaceholder = NSAttributedString(
                string: searchBar.placeholder ?? "Search",
                attributes: placeholderAttributes
            )
        }
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .white
        searchBar.delegate = self
    }
    
    // MARK: - Update Selection UI
    private func updateSelectionUI() {
        switch currentSelectionType {
        case .category:
            categoryLabel.textColor = .white
            countryLabel.textColor = UIColor(hex: "#878787")
            categorySelectedImageView.isHidden = false
            countrySelectedImageView.isHidden = true
            
        case .country:
            categoryLabel.textColor = UIColor(hex: "#878787")
            countryLabel.textColor = .white
            categorySelectedImageView.isHidden = true
            countrySelectedImageView.isHidden = false
        }
        
        filterContentForSearchText(searchBar.text ?? "")
        collectionView.reloadData()
        
        updateNoDataViewVisibility()
    }
    private func updateNoDataViewVisibility() {
        let hasData: Bool
        
        switch currentSelectionType {
        case .category:
            hasData = !filteredCategories.isEmpty
        case .country:
            hasData = !filteredCountries.isEmpty
        }
        
        // Show collection view and hide noDataView if there's data
        // Hide collection view and show noDataView if there's no data
        collectionView.isHidden = !hasData
        noDataView.isHidden = hasData
    }

    // MARK: - Button Actions
    @IBAction func countryCategoryButtonTap(_ sender: UIButton) {
        if sender.tag == 1 { // Category button tap
            currentSelectionType = .category
        } else if sender.tag == 2 { // Country button tap
            currentSelectionType = .country
        }
        
        updateSelectionUI()
    }
    
    // MARK: - Search Filtering
    private func filterContentForSearchText(_ searchText: String) {
        isSearching = !searchText.isEmpty
        
        switch currentSelectionType {
        case .category:
            if searchText.isEmpty {
                filteredCategories = categories
            } else {
                filteredCategories = categories.filter { category in
                    return category.category.lowercased().contains(searchText.lowercased())
                }
            }
            
        case .country:
            if searchText.isEmpty {
                filteredCountries = countries
            } else {
                filteredCountries = countries.filter { country in
                    return country.country.lowercased().contains(searchText.lowercased())
                }
            }
        }
        
        collectionView.reloadData()
        updateNoDataViewVisibility()
    }
    
    // MARK: - Navigation
    private func navigateToChannelList(channels: [Channell], title: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "IPTVChannelListVC") as? IPTVChannelListVC {
            vc.channels = channels
            vc.screenTitle = title
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Native Ads
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
            guard let self = self else { return }

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
            guard let self = self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 0
                self.addNativeView.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func subscriptionUpdated() {
        DispatchQueue.main.async {
            self.nativeHeighConstant.constant = 0
            self.addNativeView.isHidden = true
            self.collectionView.reloadData()
        }
    }
    
    private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension IPTVCategoryListVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filterContentForSearchText("")
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension IPTVCategoryListVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch currentSelectionType {
        case .category:
            return filteredCategories.count
        case .country:
            return filteredCountries.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IPTVCategoryCell", for: indexPath) as! IPTVCategoryCell
        
        switch currentSelectionType {
        case .category:
            let category = filteredCategories[indexPath.item]
            cell.nameLabel.text = category.category
            cell.channelCountLabel.text = "\(category.channels.count)+"
            // Set permanent icon for category
            cell.thumbImageView.image = UIImage(named: "category_default")
            
        case .country:
            let country = filteredCountries[indexPath.item]
            cell.nameLabel.text = country.country
            cell.channelCountLabel.text = "\(country.channels.count)+"
            
            // Set flag image for country
            if !country.flag.isEmpty, let flagURL = URL(string: country.flag) {
                cell.thumbImageView.sd_setImage(
                    with: flagURL,
                    placeholderImage: UIImage(named: "country_default"),
                    options: [.progressiveLoad, .retryFailed]
                )
            } else {
                cell.thumbImageView.image = UIImage(named: "country_default")
            }
            
            cell.thumbImageView.contentMode = .scaleAspectFill
            cell.thumbImageView.clipsToBounds = true
            cell.thumbImageView.layer.cornerRadius = cell.thumbImageView.frame.height / 2
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch currentSelectionType {
        case .category:
            let category = filteredCategories[indexPath.item]
            navigateToChannelList(channels: category.channels, title: category.category)
            
        case .country:
            let country = filteredCountries[indexPath.item]
            navigateToChannelList(channels: country.channels, title: country.country)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Cell height is 80 as requested, full width with no spacing
        return CGSize(width: collectionView.frame.width, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - API Calls
extension IPTVCategoryListVC {
    func fetchIPTVData() {
        // Load category data from UserDefaults
        if let cachedData = UserDefaults.standard.data(forKey: "iptv_grouped_by_category"),
           let decodedCategories = try? JSONDecoder().decode([IPTVCategory].self, from: cachedData) {
            self.categories = decodedCategories
            self.filteredCategories = decodedCategories
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.updateNoDataViewVisibility()
            }
        }
        
        // Load country data from UserDefaults (or fetch if not available)
        if let cachedData = UserDefaults.standard.data(forKey: "iptv_grouped_by_country"),
           let decodedCountries = try? JSONDecoder().decode([IPTVGroup].self, from: cachedData) {
            self.countries = decodedCountries
            self.filteredCountries = decodedCountries
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.updateNoDataViewVisibility()
            }
        } else {
            // Fetch country data if not cached
            fetchIPTVCountryData()
        }
    }
    
    func fetchIPTVCountryData() {
        guard let url = URL(string: "http://d2is1ss4hhk4uk.cloudfront.net/iptv/iptv_grouped_by_country.json") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching country data:", error.localizedDescription)
                DispatchQueue.main.async {
                    self.updateNoDataViewVisibility()
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data received for country data")
                DispatchQueue.main.async {
                    self.updateNoDataViewVisibility()
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode([IPTVGroup].self, from: data)
                
                if let encoded = try? JSONEncoder().encode(result) {
                    UserDefaults.standard.set(encoded, forKey: "iptv_grouped_by_country")
                }
                
                DispatchQueue.main.async {
                    self.countries = result
                    self.filteredCountries = result
                    self.collectionView.reloadData()
                    self.updateNoDataViewVisibility()
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateNoDataViewVisibility()
                }
                print("❌ Decoding error for country data:", error)
            }
        }.resume()
    }
}

//
//  IPTVChannelListVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import UIKit
import SDWebImage
import SwiftPopup
import MarqueeLabel

class IPTVChannelListVC: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    // MARK: - Data Properties
    var channels: [Channell] = []
    var screenTitle: String = ""
    private var filteredChannels: [Channell] = []
    private var isSearching = false
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setupCollectionView()
        setUpSearchBar()
        filteredChannels = channels
        
        // Set navigation title
        title = screenTitle
        subscribeNativeAd()
        updateNoDataViewVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Restart marquee animations when view appears
        restartMarqueeLabels()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func setUI() {
        // Add notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subscriptionUpdated),
            name: .subscriptionStatusChanged,
            object: nil
        )
        noDataLabel.text = "No data found".localized(LocalizationService.shared.language)
    }
    
    // MARK: - Collection View Setup
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "IPTVChannelCell", bundle: nil), forCellWithReuseIdentifier: "IPTVChannelCell")
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        collectionView.collectionViewLayout = layout
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.isUserInteractionEnabled = true
        collectionView.keyboardDismissMode = .interactive
    }
    
    // MARK: - Restart Marquee Labels
    private func restartMarqueeLabels() {
        for cell in collectionView.visibleCells {
            if let channelCell = cell as? IPTVChannelCell {
                channelCell.channelNameLabel.restartLabel()
            }
        }
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
    
    // MARK: - Search Filtering
    private func filterContentForSearchText(_ searchText: String) {
        isSearching = !searchText.isEmpty
        
        if searchText.isEmpty {
            filteredChannels = channels
        } else {
            filteredChannels = channels.filter { channel in
                return channel.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        collectionView.reloadData()
        updateNoDataViewVisibility()
    }
    private func updateNoDataViewVisibility() {
        let hasData = !filteredChannels.isEmpty
        
        // Show collection view and hide noDataView if there's data
        // Hide collection view and show noDataView if there's no data
        collectionView.isHidden = !hasData
        noDataView.isHidden = hasData
    }
    // MARK: - Cell Size Calculation with 5px spacing
    private func calculateCellSize() -> CGSize {
        let screenWidth = collectionView.frame.width
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let numberOfColumns: CGFloat = isiPad ? 5 : 3
        
        // Calculate available width after subtracting spacing
        // Total horizontal spacing = (numberOfColumns - 1) * minimumInteritemSpacing + leftInset + rightInset
        let totalHorizontalSpacing: CGFloat = (numberOfColumns - 1) * 10 + 10 + 10 // 5px interitem spacing + 5px left + 5px right
        let availableWidth = screenWidth - totalHorizontalSpacing
        let cellWidth = availableWidth / numberOfColumns
        
        // Make square box - same width and height (as requested)
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    private func openIPTVPlayer(channelURL: String, ChannelName: String, channelLogo: String) {
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "IPTVChannelPlayVC"
        ) as! IPTVChannelPlayVC
        
        vc.channelUrl = channelURL
        vc.channelName = ChannelName
        vc.channelLogo = channelLogo
        navigationController?.pushViewController(vc, animated: true)
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
extension IPTVChannelListVC: UISearchBarDelegate {
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
extension IPTVChannelListVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IPTVChannelCell", for: indexPath) as! IPTVChannelCell
        
        let channel = filteredChannels[indexPath.item]
        cell.channelNameLabel.text = channel.name
        
        // Check if text fits without scrolling
        let textWidth = (channel.name as NSString).size(withAttributes: [
            .font: cell.channelNameLabel.font
        ]).width
        
        let availableWidth = cell.channelNameLabel.bounds.width
        cell.channelNameLabel.labelize = textWidth <= availableWidth
        
        // Set channel logo using SDWebImage
        if let logoUrlString = channel.logo, !logoUrlString.isEmpty,
           let logoURL = URL(string: logoUrlString) {
            cell.channelLogoImageview.sd_setImage(
                with: logoURL,
                placeholderImage: UIImage(named: "channel_default"),
                options: [.progressiveLoad, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            cell.channelLogoImageview.image = UIImage(named: "channel_default")
        }
        
//        cell.mainView.layer.borderWidth = 0.5
//        cell.mainView.layer.borderColor = #colorLiteral(red: 0.9999999404, green: 1, blue: 1, alpha: 0.299556213)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let channelCell = cell as? IPTVChannelCell {
            // Restart marquee animation when cell appears
            channelCell.channelNameLabel.restartLabel()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let channelCell = cell as? IPTVChannelCell {
            // Stop marquee animation when cell disappears
            channelCell.channelNameLabel.shutdownLabel()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = filteredChannels[indexPath.item]
        self.openIPTVPlayer(channelURL: channel.url, ChannelName: channel.name, channelLogo: channel.logo ?? "")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateCellSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 5px vertical spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // 5px horizontal spacing between columns
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // 5px spacing on all sides (top, left, bottom, right)
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // Hide keyboard when scrolling starts
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Restart marquee animations after scrolling stops
        restartMarqueeLabels()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // Restart marquee animations if scrolling stopped immediately
            restartMarqueeLabels()
        }
    }
}

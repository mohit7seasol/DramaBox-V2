//
//  LanguageVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import GoogleMobileAds

enum SelectLanguage: String, CaseIterable {
    case english = "English"
    case hindi = "Hindi"
    case danish = "Danish"
    case spanish = "Spanish"
    case italian = "Italian"
    case german = "German"
    case turkish = "Turkish"
    case portuguese = "Portuguese"
    
    
    // Map ChooseLanguage → Language (for localization)
    var languageCode: Language {
        switch self {
        case .english: return .English
        case .hindi: return .Hindi
        case .danish: return .Danish
        case .spanish: return .Spanish
        case .italian: return .Italian
        case .german: return .German
        case .turkish: return .Turkish
        case .portuguese: return .Portuguese
        }
    }
}

// MARK: - Language Enum Localized Names
extension Language {
    var localizedName: String {
        switch self {
        case .English: return "English".localized(self)
        case .Hindi: return "Hindi".localized(self)
        case .Danish: return "dansk".localized(self)
        case .Spanish: return "Spanish".localized(self)
        case .Italian: return "Italiana".localized(self)
        case .German: return "Deutsch".localized(self)
        case .Turkish: return "Türkçe".localized(self)
        case .Portuguese: return "Português".localized(self)
            
        }
    }
}

class LanguageVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var doneButtonLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var bannerAddView: UIView!
    @IBOutlet weak var addHeightConstant: NSLayoutConstraint!
    
    @IBOutlet weak var doneButtonView: GradientDesignableView!
    
    private let languages = SelectLanguage.allCases
    private var selectedIndex: Int = 0
    private let cellIdentifier = "LanguageSelectionCell"
    private let spacing: CGFloat = 0
    private let numberOfColumns: Int = 2
    var isOpenFromApp: Bool = false
    
    private let googleBannerAds = GoogleBannerAds()
    private var bannerView: BannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setUpUI() {
        setLoca()
        setCollectionView()
        configureUI()
        setupGradientBackground()
        backButton.isHidden = !isOpenFromApp
        doneButtonView.cornerRadius = doneButtonView.frame.height / 2
        subscribeBannerAd()
    }
    func subscribeBannerAd() {

        if Subscribe.get() {
            addHeightConstant.constant = 0
            bannerAddView.isHidden = true
            return
        }

        // Create BannerView ONLY ONCE
        if bannerView == nil {
            let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(
                width: UIScreen.main.bounds.width
            ))

            banner.translatesAutoresizingMaskIntoConstraints = false
            bannerAddView.addSubview(banner)

            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: bannerAddView.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: bannerAddView.trailingAnchor),
                banner.topAnchor.constraint(equalTo: bannerAddView.topAnchor),
                banner.bottomAnchor.constraint(equalTo: bannerAddView.bottomAnchor)
            ])

            bannerView = banner
        }

        bannerAddView.isHidden = false
        addHeightConstant.constant = 50   // Standard banner height

        // ✅ THIS IS THE KEY FIX
        googleBannerAds.loadAds(vc: self, view: bannerView!)
    }
    func setLoca() {
        titleLabel.font = FontManager.shared.font(for: .roboto, size: 24.0)
        titleLabel.text = "Choose the language you want to use.".localized(LocalizationService.shared.language)
        doneButtonLabel.text = "Done".localized(LocalizationService.shared.language)
    }
    
    func configureUI() {
        restorePreviousLanguageSelection()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
            UIColor.white.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
        
        // Set custom layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: spacing)
        collectionView.collectionViewLayout = layout
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        // Save selected language
        let selectedLanguage = languages[selectedIndex]
        AppStorage.set(selectedLanguage.rawValue, forKey: UserDefaultKeys.selectedLanguage)
        
        // Set the language in LocalizationService
        LocalizationService.shared.language = selectedLanguage.languageCode
        
        // Delay resetting root until notification is posted
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigateToNextScreen()
        }
    }
    
    private func navigateToNextScreen() {
        // Get the current window safely
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else {
            print("❌ SceneDelegate not found")
            return
        }
        
        // Ensure window exists
        if sceneDelegate.window == nil {
            sceneDelegate.window = UIWindow(windowScene: windowScene)
            sceneDelegate.window?.backgroundColor = .black
        }
        
        guard let window = sceneDelegate.window else {
            print("❌ Window could not be created")
            return
        }
        
        let initialVC: UIViewController
        
        if !(AppStorage.get(forKey: UserDefaultKeys.hasLaunchedBefore) ?? false) {
            // First launch → Onboarding introVC1
            guard let onboardingVC = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.o1VC) as? UIViewController else {
                print("❌ Failed to instantiate onboarding VC")
                return
            }
            initialVC = onboardingVC
            AppStorage.set(true, forKey: UserDefaultKeys.hasLaunchedBefore)
        } else {
            // Language already set → TabBarVC
            guard let tabBarVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.tabBarVC) as? UIViewController else {
                print("❌ Failed to instantiate tabBar VC")
                return
            }
            initialVC = tabBarVC
        }
        
        // Always wrap in navigation controller
        let navController = UINavigationController(rootViewController: initialVC)
        
        // Customize navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "#111111") ?? .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.tintColor = .white
        
        // ✅ Always hide navigation bar
        navController.setNavigationBarHidden(true, animated: false)
        
        // Animate transition
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }, completion: nil)
        
        // Update app delegate's window reference
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window = window
        }
    }
    
    private func restorePreviousLanguageSelection() {
        if let saved = AppStorage.get(forKey: UserDefaultKeys.selectedLanguage) as String?,
           let lang = SelectLanguage(rawValue: saved),
           let index = languages.firstIndex(of: lang) {

            selectedIndex = index
            collectionView.reloadData()
        }
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension LanguageVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return languages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! LanguageSelectionCell
        
        let language = languages[indexPath.item]
        
        // Configure cell
        cell.countryNameLabel.text = language.languageCode.localizedName
        cell.countrFlagImageView.image = UIImage(named: language.rawValue.lowercased())
        
        // Set selection state
        let isSelected = (indexPath.item == selectedIndex)
        cell.configure(isSelected: isSelected)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Update selected index
        selectedIndex = indexPath.item
        
        // Reload collection view to update selection states
        collectionView.reloadData()
        
        // Optional: Scroll to selected item if needed
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LanguageVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate width for 2 columns with spacing
        let totalSpacing = spacing * CGFloat(numberOfColumns + 1)
        let availableWidth = collectionView.frame.width - totalSpacing
        let itemWidth = availableWidth / CGFloat(numberOfColumns)
        
        // Return size with 50px height as requested
        let itemHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 120 : 60

        return CGSize(width: itemWidth, height: itemHeight)
    }
}

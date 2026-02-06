//
//  TabBarVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import Lottie

class TabBarVC: UITabBarController {
    
    // Unique name so we can find/remove our gradient layer reliably
    private let gradientLayerName = "customTabbarGradientLayer"
    
    // If you want to allow re-selection of same tab set to true (here we prevent)
    private let allowReselect = false
    
    // Case 2: shouldShowShorts property - FIXED USING AppStorage
    private var shouldShowShorts: Bool {
        return AppStorage.get(forKey: "remoteConfig_sub_value") ?? false
    }
    
    // Define all tab configurations EXACTLY like reference
    private enum TabConfig {
        case home
        case shorts  // This is index 1 tab
        case myList
        case fun
        case settings
        
        var storyboard: String {
            switch self {
            case .home: return StoryboardName.main
            case .shorts: return StoryboardName.main
            case .myList: return StoryboardName.main
            case .fun: return StoryboardName.main
            case .settings: return StoryboardName.main
            }
        }
        
        var controllerId: String {
            switch self {
            case .home: return "HomeVC"  // Replace actual controller IDs
            case .shorts: return "StoriesVC"  // Replace actual controller IDs
            case .myList: return "MyListVC"  // Replace actual controller IDs
            case .fun: return "FunVC"  // Replace actual controller IDs
            case .settings: return "SettingVC"  // Replace actual controller IDs
            }
        }
        
        var image: (normal: String, selected: String) {
            switch self {
            case .home: return ("home_unselected", "home_selected")
            case .shorts: return ("stories_selected", "stories_selected")
            case .myList: return ("mylist_unselected", "mylist_selected")
            case .fun: return ("fun_unselected", "fun_selected")
            case .settings: return ("setting_unselected", "setting_selected")
            }
        }
        
        var titleString: String {
            switch self {
            case .home: return "Home"
            case .shorts: return "Stories"
            case .myList: return "My List"
            case .fun: return "Fun"
            case .settings: return "Setting"
            }
        }
        
        var localizedTitle: String {
            return titleString.localized(LocalizationService.shared.language)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        print("🎯 TabBarVC loaded - Shorts tab should show: \(shouldShowShorts)")
        
        // Setup view controllers dynamically - EXACTLY like reference
        setupViewControllers()
        
        // Configure appearance + gradient
        configureTabBarAppearance() // Changed from setupTabBarAppearance to configureTabBarAppearance
        
        // Observe language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: NSNotification.Name("changedLanguage"),
            object: nil
        )
        
        // Observe remote config updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteConfigUpdated),
            name: NSNotification.Name("RemoteConfigUpdated"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 TabBarVC will appear - Shorts tab: \(shouldShowShorts)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame() // Changed from updateTabBarAppearance to updateGradientFrame
    }
    
    // MARK: - Setup View Controllers EXACTLY like reference
    private func setupViewControllers() {
        var tabConfigs: [TabConfig] = [.home]
        
        // Add shorts tab conditionally - EXACTLY like reference
        if shouldShowShorts {
            print("🎥 Adding Shorts tab")
            tabConfigs.append(.shorts)
        } else {
            print("🎥 Skipping Shorts tab")
        }
        
        // Add remaining tabs - EXACTLY like reference
        tabConfigs.append(contentsOf: [.myList, .fun, .settings])
        
        print("📱 Setting up \(tabConfigs.count) tabs")
        
        // Create view controllers - EXACTLY like reference
        var controllers: [UIViewController] = []
        
        for config in tabConfigs {
            let storyboard = UIStoryboard(name: config.storyboard, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: config.controllerId)
            
            // Configure tab bar item - EXACTLY like reference
            vc.tabBarItem = UITabBarItem(
                title: config.localizedTitle,
                image: UIImage(named: config.image.normal)?.withRenderingMode(.alwaysOriginal),
                selectedImage: UIImage(named: config.image.selected)?.withRenderingMode(.alwaysOriginal)
            )
            
            // Wrap in navigation controller if needed
            let navController = UINavigationController(rootViewController: vc)
            navController.navigationBar.isHidden = true
            controllers.append(navController)
        }
        
        self.viewControllers = controllers
        
        // Always select first tab
        self.selectedIndex = 0
    }
    
    @objc private func languageChanged() {
        print("🌐 Language changed - updating tab titles")
        
        // Update tab titles when language changes
        guard let items = tabBar.items, let viewControllers = viewControllers else { return }
        
        for (index, vc) in viewControllers.enumerated() {
            if index < items.count {
                // Get the localized title based on the tab's position
                let title = getTitleForTab(at: index)
                items[index].title = title
                vc.tabBarItem.title = title
            }
        }
    }
    
    private func getTitleForTab(at index: Int) -> String {
        let tabConfigs = getCurrentTabConfigs()
        
        guard index < tabConfigs.count else { return "" }
        
        return tabConfigs[index].localizedTitle
    }
    
    @objc private func remoteConfigUpdated() {
        print("🔄 Remote config updated - checking shorts tab")
        
        // Get new value
        let newShouldShowShorts = AppStorage.get(forKey: "remoteConfig_sub_value") ?? false
        print("🔄 New shorts value: \(newShouldShowShorts), Current: \(shouldShowShorts)")
        
        // Simple check: if the count would be different, reload - EXACTLY like reference
        let currentTabCount = viewControllers?.count ?? 0
        let wouldHaveShortsTab = newShouldShowShorts
        let expectedTabCount = wouldHaveShortsTab ? 5 : 4
        
        if currentTabCount != expectedTabCount {
            print("🔄 Tab count changed from \(currentTabCount) to \(expectedTabCount) - reloading")
            
            // Reload tabs with crossfade animation - EXACTLY like reference
            UIView.transition(with: self.view, duration: 0.3, options: .transitionCrossDissolve) {
                self.setupViewControllers()
                self.updateGradientFrame()
            }
        }
    }
    
    private func getCurrentTabConfigs() -> [TabConfig] {
        var configs: [TabConfig] = [.home]
        
        if shouldShowShorts {
            configs.append(.shorts)
        }
        
        configs.append(contentsOf: [.myList, .fun, .settings])
        return configs
    }
    
    // MARK: - Appearance + Gradient (Updated to match reference code)
    private func configureTabBarAppearance() {
        if #available(iOS 26.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            
            // Using your colors from original code
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "#909090") ?? .lightGray,
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#909090")
            appearance.stackedLayoutAppearance.selected.iconColor = .white
            
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
            
            tabBar.isTranslucent = true   // ✅ allow gradient visibility
            tabBar.backgroundImage = UIImage()
            tabBar.backgroundColor = .clear
            
            applyLayerGradient()
        } else {
            // For iOS < 26.0 - use legacy setup
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            setupLegacyGradient()
            
            appearance.shadowColor = .clear

            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "#909090")
            appearance.stackedLayoutAppearance.selected.iconColor = .white

            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "#909090") ?? .lightGray,
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12, weight: .medium)
            ]

            tabBar.standardAppearance = appearance

            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    private func setupLegacyGradient() {
        // Create gradient image using your original gradient colors
        let gradientImage = gradientImage(
            size: CGSize(
                width: UIScreen.main.bounds.width,
                height: tabBar.bounds.height + 10
            )
        )
        
        tabBar.backgroundImage = gradientImage
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = false
        
        // Set tab bar color to match your gradient
        let tabBarColor = UIColor(hex: "#151515") ?? #colorLiteral(red: 0.08235294118, green: 0.08235294118, blue: 0.08235294118, alpha: 1)
        
        tabBar.barTintColor = tabBarColor
        tabBar.backgroundColor = tabBarColor
        
        // Add a custom top border line if needed
        addTopBorderLine()
    }

    private func addTopBorderLine() {
        // Remove any existing border layers
        tabBar.layer.sublayers?
            .filter { $0.name == "tabBarTopBorder" }
            .forEach { $0.removeFromSuperlayer() }
        
        // Create top border line
        let borderLayer = CALayer()
        borderLayer.name = "tabBarTopBorder"
        borderLayer.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.1490196078, blue: 0.1490196078, alpha: 1).cgColor // Slightly lighter than #151515
        borderLayer.frame = CGRect(x: 0, y: 0, width: tabBar.bounds.width, height: 0.5)
        
        tabBar.layer.addSublayer(borderLayer)
    }
    
    // Create a UIImage from gradient for appearance.backgroundImage
    private func gradientImage(size: CGSize) -> UIImage? {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        
        // Using your original gradient colors
        gradient.colors = [
            UIColor(hex: "#2E2E2E")!.cgColor,
            UIColor(hex: "#161616")!.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        gradient.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    // Insert CAGradientLayer behind tab bar items (system won't remove sublayers)
    private func applyLayerGradient() {
        // Remove old
        tabBar.layer.sublayers?
            .filter { $0.name == gradientLayerName }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = gradientLayerName
        gradient.frame = tabBar.bounds
        
        // Using your original gradient colors
        gradient.colors = [
            UIColor(hex: "#2E2E2E")!.cgColor,
            UIColor(hex: "#161616")!.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

        tabBar.layer.insertSublayer(gradient, at: 0)
    }

    private func updateGradientFrame() {
        tabBar.layer.sublayers?
            .filter { $0.name == gradientLayerName }
            .forEach { $0.frame = tabBar.bounds }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Tab selection safety (snapshot wrapper) - EXACTLY like reference
extension TabBarVC: UITabBarControllerDelegate {

    // Intercept before the system performs the selection to avoid default transition flash
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {

        // If tapping current selected tab, optionally allow
        if !allowReselect && viewController == selectedViewController { return false }

        // Determine destination index
        guard let vcs = viewControllers, let destIndex = vcs.firstIndex(of: viewController) else {
            return true
        }

        // If same index, do nothing
        if destIndex == selectedIndex { return false }

        // Key window (modern API)
        let keyWindow: UIWindow? = {
            if #available(iOS 13.0, *) {
                return UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
            } else {
                return UIApplication.shared.keyWindow
            }
        }()

        // Snapshot technique: take a snapshot, change tab, then fade snapshot out
        if let window = keyWindow, let snapshot = window.snapshotView(afterScreenUpdates: false) {
            // Set window background same color to avoid seeing white under snapshot if removed
            let oldWindowBG = window.backgroundColor
            window.backgroundColor = UIColor.black

            snapshot.frame = window.bounds
            window.addSubview(snapshot)

            // Perform selection without animation and force layout
            UIView.performWithoutAnimation {
                self.selectedIndex = destIndex
                // force layout now
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }

            // Slight delay gives system time to complete rendering; fade-out hides artifacts
            UIView.animate(withDuration: 0.18, delay: 0.0, options: [.curveEaseOut], animations: {
                snapshot.alpha = 0.0
            }, completion: { _ in
                snapshot.removeFromSuperview()
                // restore previous window bg
                window.backgroundColor = oldWindowBG
            })

            return false // we handled selection
        }

        // Fallback to normal behavior
        return true
    }

    // Ensure gradient stays sized after selection
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateGradientFrame()
    }
}

// UIColor extension remains the same
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        if length == 6 {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            return nil
        }
    }
}

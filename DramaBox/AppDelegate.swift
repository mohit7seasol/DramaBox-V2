//
//  AppDelegate.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import IQKeyboardManagerSwift
import GoogleMobileAds
internal import IQKeyboardToolbarManager

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var showAdTimer: Timer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        seupPrimaryAppUI()
        
        // Initialize window (MISSING IN YOUR CODE - ADDED FROM REFERENCE)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle scene sessions
    }
    
    // MARK: - App Lifecycle Methods (MISSING IN YOUR CODE - ADDED FROM REFERENCE)
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // App will enter foreground - LOAD & SHOW INTERSTITIAL ADS
        print("📱 App will enter foreground - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // App became active - LOAD & SHOW INTERSTITIAL ADS
        print("📱 App became active - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    private func setupIQKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.toolbarConfiguration.tintColor = UIColor.black
        IQKeyboardManager.shared.toolbarConfiguration.barTintColor = UIColor.white
    }
    
    func seupPrimaryAppUI() {
        setupTabBarAppearance()
        setupNavigationBarAppearance()
        setupIQKeyboardManager()

        UINavigationBar.appearance().isHidden = true
        UIView.appearance().overrideUserInterfaceStyle = .dark

        // ✅ Ads + lifecycle setup
        setupAppLifecycleObservers()
        // Load ads on app launch (FROM REFERENCE)
        loadAndShowInterstitialAds()

        // Test device (FROM REFERENCE)
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["3566CA2D-CE22-4567-A7AD-FAAFB5A5DCC5"]
    }
}

// MARK: - Interstitial Ads
extension AppDelegate {
    private func setupAppLifecycleObservers() {
        // ADDED appWillEnterForeground FROM REFERENCE
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillEnterForeground() {
        print("📱 App will enter foreground - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App became active - Loading interstitial ads")
        loadAndShowInterstitialAds()
    }
    
    private func loadAndShowInterstitialAds() {
        // Check subscription status first
        if Subscribe.get() {
            print("🎫 User is subscribed - Skipping interstitial ads")
            return
        }
        
        print("🔄 Loading interstitial ads...")
        
        // Load interstitial ads using existing AdsManager method
        AdsManager.shared.loadInterstitialAd()
        
        // Show the ad after a short delay to ensure it's loaded
        showAdTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.showInterstitialAdIfReady()
        }
    }
    
    private func showInterstitialAdIfReady() {
        // Check subscription status again
        if Subscribe.get() {
            print("🎫 User is subscribed - Not showing ads")
            return
        }
        
        // Check if interstitial ad is ready
        if AdsManager.shared.isInterstitialAdReady() {
            print("✅ Interstitial ad is ready - Showing now")
            
            // Get the top view controller and show the ad
            if let topViewController = getTopViewController() {
                print("🎬 Presenting interstitial ad on: \(topViewController)")
                
                // Use the existing AdsManager method to show the ad
                AdsManager.shared.loadInterstitialAd()
            } else {
                print("❌ Could not find top view controller")
            }
        } else {
            print("❌ Interstitial ad not ready yet")
        }
        
        // Clean up timer
        showAdTimer?.invalidate()
        showAdTimer = nil
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let window = window else { return nil }
        
        var topController = window.rootViewController
        
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}

// MARK: - Appearance
extension AppDelegate {
    func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        let gradient = CAGradientLayer()
        gradient.colors = [ #colorLiteral(red: 0.04705882445, green: 0.04705882445, blue: 0.04705882445, alpha: 1) , #colorLiteral(red: 0.01176470611, green: 0.01176470611, blue: 0.01176470611, alpha: 1) ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

        let size = CGSize(width: UIScreen.main.bounds.width, height: 83)
        gradient.frame = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let bgImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        appearance.backgroundImage = bgImage

        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.selected.iconColor = .white

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UITabBar.appearance().standardAppearance = appearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        let backImage = UIImage(named: "back")?.withRenderingMode(.alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
}

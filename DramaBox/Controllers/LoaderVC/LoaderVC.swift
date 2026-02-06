//
//  ViewController.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit
import Lottie
import AWSCore

class LoaderVC: UIViewController {

    @IBOutlet weak var lottieAnimationView: UIView!
    
    var lottieFileName = "Splash Loading"
    private var animationView: LottieAnimationView?
    private var isFirstLaunch = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setupAnimation()
        startAnimation() // CALL THIS IMMEDIATELY LIKE REFERENCE CODE
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLottieAnimation()
        NotificationCenter.default.removeObserver(self)
    }
    
    func setUpUI() {
        AdsManager.shared.loadInterstitialAd()
        setLoca()
    }
    
    func setLoca() {
    }
    
    // MARK: - Animation Setup (FROM REFERENCE)
    private func setupAnimation() {
        let animationView = LottieAnimationView(name: lottieFileName)
        self.animationView = animationView

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop

        lottieAnimationView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: lottieAnimationView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: lottieAnimationView.centerYAnchor),
            animationView.widthAnchor.constraint(equalTo: lottieAnimationView.widthAnchor, multiplier: 0.6),
            animationView.heightAnchor.constraint(equalTo: animationView.widthAnchor)
        ])

        animationView.play()

        // Add observer for naviToTab notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goToNextScreen),
            name: NSNotification.Name("naviToTab"),
            object: nil
        )
    }
    
    // MARK: - Start Animation (FROM REFERENCE)
    func startAnimation() {
        animationView?.play()
        
        // Call config API immediately (LIKE REFERENCE CODE)
        NetworkManager.shared.fetchRemoteConfig(from: self) { result in
            switch result {
            case .success(let json):
                if let json = json as? [String: Any] {
                    let jsonDict = json
                    
                    // Parse values (FROM REFERENCE)
                    bannerId = (jsonDict["bannerId"] as AnyObject).stringValue ?? ""
                    nativeId = (jsonDict["nativeId"] as AnyObject).stringValue ?? ""
                    interstialId = (jsonDict["interstialId"] as AnyObject).stringValue ?? ""
                    appopenId = (jsonDict["appopenId"] as AnyObject).stringValue ?? ""
                    rewardId = (jsonDict["rewardId"] as AnyObject).stringValue ?? ""
                    
                    addButtonColor = (jsonDict["addButtonColor"] as AnyObject).stringValue ?? "#7462FF"
                    let customInterstial = (jsonDict["customInterstial"] as AnyObject).intValue ?? 0
                    
                    // ⭐ IMPORTANT: Set the ads threshold from remote config
                    let afterClickValue = (jsonDict["afterClick"] as? Int) ?? Int(jsonDict["afterClick"] as? String ?? "") ?? 3
                    print("🎯 Remote Config - Setting ads threshold to: \(afterClickValue)")
                    
                    adsCount = afterClickValue
                    adsPlus = customInterstial == 0 ? adsCount - 1 : adsCount
                    
                    let extraFields = (jsonDict["extraFields"] as AnyObject)
                    smallNativeBannerId = (extraFields["small_native"] as AnyObject).stringValue ?? ""
                    
                    isIAPON = (extraFields["plan"] as AnyObject).stringValue ?? ""
                    IAPRequiredForTrailor = (extraFields["play"] as AnyObject).stringValue ?? ""
                    prefixUrl = (extraFields["appjson"] as AnyObject).stringValue ?? ""
                    NewsAPI = (extraFields["story"] as AnyObject).stringValue ?? ""
                    
                    sub = (extraFields["sub"] as AnyObject).boolValue ?? false
                    
                    // ⭐ NEW: Save to UserDefaults/AppStorage for TabbarVC to access
                    AppStorage.set(sub, forKey: "remoteConfig_sub_value")
                    print("✅ Remote Config - sub value saved: \(sub)")
                    
                    // Load app open ad
                    Task {
                        await AppOpenAdManager.shared.loadAd()
                    }
                    
                    // ⭐ CRITICAL CHANGE: Call fetchIPTVCateData AFTER remote config success
                    // Wait 1 second, then fetch IPTV data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.fetchIPTVCateData()
                    }
                }
                
            case .failure(let error):
                print("❌ Failed to fetch config:", error.localizedDescription)
                
                // Fallback after 2 seconds if API fails
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    HelperManager.setupInitialLanguage()
                    self.goToNextScreen()
                }
            }
        }
    }
    
    // MARK: - IPTV Category Data
    func fetchIPTVCateData() {
        print("🔄 LoaderVC: Fetching IPTV Category Data...")
        guard let url = URL(string: "http://d2is1ss4hhk4uk.cloudfront.net/iptv/iptv_grouped_by_category.json") else {
            print("❌ LoaderVC: Invalid URL for category data")
            // If URL is invalid, still navigate after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.navigateToVc()
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ LoaderVC: Error fetching category data - \(error.localizedDescription)")
                } else if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode([IPTVCategory].self, from: data)
                        
                        if let encoded = try? JSONEncoder().encode(result) {
                            UserDefaults.standard.set(encoded, forKey: "iptv_grouped_by_category")
                            print("✅ LoaderVC: IPTV Category Data saved successfully")
                        }
                    } catch {
                        print("❌ LoaderVC: Decoding error for category data - \(error)")
                    }
                } else {
                    print("❌ LoaderVC: No data received for category data")
                }
                
                // ⭐ IMPORTANT: Wait 3 more seconds (total 4 seconds from start) like reference code
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    // Notify that remote config is loaded
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteConfigUpdated"), object: nil)
                    
                    // ⭐ NAVIGATE TO NEXT SCREEN
                    self.navigateToVc()
                }
            }
        }.resume()
    }
    
    // MARK: - Navigation
    func navigateToVc() {
        print("🚀 LoaderVC: Navigating to next screen...")
        
        // Set up AWS as in reference code
        let credentials = AWSStaticCredentialsProvider(accessKey: ACCESS, secretKey: SECRET)
        let configuration = AWSServiceConfiguration(region: AWSRegionType.EUWest1, credentialsProvider: credentials)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AdsManager.shared.requestForConsentForm { (isConsentGranted) in
            if isConsentGranted {
                isfromeAppStart = true
                isComeFromSplash = true
                appOpenHome = true
                if Subscribe.get() == false {
                    AppOpenAdManager.shared.showAdIfAvailable(viewController: self)
                } else {
                    self.goToNextScreen()
                }
            } else {
                isfromeAppStart = true
                isComeFromSplash = true
                appOpenHome = true
                if Subscribe.get() == false {
                    AppOpenAdManager.shared.showAdIfAvailable(viewController: self)
                } else {
                    self.goToNextScreen()
                }
            }
        }
    }
    
    private func startLottieAnimation() {
        animationView?.play()
    }
    
    private func stopLottieAnimation() {
        animationView?.stop()
    }
    
    @objc func goToNextScreen() {
        stopLottieAnimation()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let sceneWindow = sceneDelegate.window else { return }

        sceneWindow.backgroundColor = .black
        sceneWindow.subviews.forEach { $0.removeFromSuperview() }

        let initialVC: UIViewController

        if !AppStorage.contains(UserDefaultKeys.selectedLanguage) {
            initialVC = UIStoryboard(name: StoryboardName.language, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.languageVC)

        } else if !(AppStorage.get(forKey: UserDefaultKeys.hasLaunchedBefore) ?? false) {
            initialVC = UIStoryboard(name: StoryboardName.onboarding, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.o1VC)

            AppStorage.set(true, forKey: UserDefaultKeys.hasLaunchedBefore)

        } else {
            initialVC = UIStoryboard(name: StoryboardName.main, bundle: nil)
                .instantiateViewController(withIdentifier: Controllers.tabBarVC)
        }

        sceneWindow.rootViewController = initialVC
        sceneWindow.makeKeyAndVisible()

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window = sceneWindow
            
            // Optional: rate prompt trigger
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NotificationCenter.default.post(name: .triggerRateCheck, object: nil)
            }
        }
    }
}

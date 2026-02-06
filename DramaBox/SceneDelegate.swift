//
//  SceneDelegate.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var isBackgound : Bool = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        let savedLanguage = AppStorage.get(forKey: UserDefaultKeys.selectedLanguage) as String?
        if let savedLang = savedLanguage, let chooseLang = SelectLanguage(rawValue: savedLang) {
            LocalizationService.shared.language = chooseLang.languageCode
        }
        // --- Make sure we have a UIWindowScene ---
        guard let windowScene = scene as? UIWindowScene else { return }

        // --- CREATE WINDOW MANUALLY (IMPORTANT FOR FIXING WHITE FLASH) ---
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // --- FIX: Prevent any white background flash ---
        window.backgroundColor = .black

        // --- Load Main.storyboard root ---
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = storyboard.instantiateInitialViewController() ?? UIViewController()
        window.rootViewController = rootVC

        // --- Show window ---
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        if isBackgound { tryToPresentAd() }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        isBackgound = true
    }
    func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func tryToPresentAd() {
        if Subscribe.get() == false {
            let rootVC = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .last { $0.isKeyWindow }?.rootViewController
            if let rwc = rootVC {
                AppOpenAdManager.shared.showAdIfAvailable(viewController: rwc)
            }
        }
    }

}


//
//  LocalModel.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/12/25.
//

import Foundation
enum Language: String {
    case English = "en"
    case Spanish = "es"
    case Hindi = "hi"
    case Danish = "da"
    case German = "de"
    case Italian = "it"
    case Portuguese = "pt-PT"
    case Turkish = "tr"
}
extension String {
    func localized(_ language: Language) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let bundle: Bundle
        if let path = path {
            bundle = Bundle(path: path) ?? .main
        } else {
            bundle = .main
        }
        return localized(bundle: bundle)
    }

    func localized(_ language: Language, args arguments: CVarArg...) -> String {
        let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj")
        let bundle: Bundle
        if let path = path {
            bundle = Bundle(path: path) ?? .main
        } else {
            bundle = .main
        }
        return String(format: localized(bundle: bundle), arguments: arguments)
    }

    private func localized(bundle: Bundle) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
//    var localized: String {
//        return LocalizationService.shared.localizedString(for: self)
//    }
}
class LocalizationService {
    static let shared = LocalizationService()
    static let changedLanguage = Notification.Name("changedLanguage")
    
    private init() {}
    
    private var bundle: Bundle?

    var language: Language {
        get {
            if let languageString = UserDefaults.standard.string(forKey: "language") {
                return Language(rawValue: languageString) ?? .English
            }
            return .English
        }
        set {
            guard newValue != language else { return }
            
            // Save to UserDefaults
            UserDefaults.standard.setValue(newValue.rawValue, forKey: "language")
            UserDefaults.standard.synchronize()
            
            // Load bundle for new language
            let path = Bundle.main.path(forResource: newValue.rawValue, ofType: "lproj")
            if let path = path {
                bundle = Bundle(path: path)
            } else {
                bundle = Bundle.main
            }
            
            // Post notification
            NotificationCenter.default.post(name: LocalizationService.changedLanguage, object: nil)
            
            print("✅ Language changed to \(newValue.rawValue)")
        }
    }
    
    func localizedString(for key: String) -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}


struct AppLanguage: Hashable{
    let LocalName: String
    let englishName: String
    let languageCode: Language
}

let languages = [
    AppLanguage(LocalName: "English", englishName: "English",languageCode: .English),
    AppLanguage(LocalName: "dansk", englishName: "Danish",languageCode: .Danish),
    AppLanguage(LocalName: "Deutsch", englishName: "German",languageCode: .German),
    AppLanguage(LocalName: "हिंदी", englishName: "Hindi",languageCode: .Hindi),
    AppLanguage(LocalName: "Italiana", englishName: "Italian",languageCode: .Italian),
    AppLanguage(LocalName: "Português", englishName: "Portuguese",languageCode: .Portuguese),
    AppLanguage(LocalName: "Española", englishName: "Spanish",languageCode: .Spanish),
    AppLanguage(LocalName: "Türkçe", englishName: "Turkish",languageCode: .Turkish),
]

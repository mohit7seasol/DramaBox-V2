//
//  AppDefaults.swift
//  DramaBox
//
//  Created by DREAMWORLD on 17/09/25.
//

import Foundation

struct AppStorage {
    static let selectedRegion = "SelectedRegion"
    static let selectedLanguage = "SelectedLanguage"
    
    // Save value
    static func set<T>(_ value: T?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    // Retrieve value (Generic)
    static func get<T>(forKey key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    
    // Remove value
    static func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // Check key existence
    static func contains(_ key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}


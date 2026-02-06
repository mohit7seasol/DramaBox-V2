//
//  UserDefaults.swift
//  TalkToMii
//
//  Created by admin on 15/03/22.
//

import Foundation

struct AuthToken {
    
    static let key = "token"
    //set, get & remove auth token
    static func save(_ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    static func get() -> String {
        if let token = UserDefaults.standard.value(forKey: key) as? String {
            return "Bearer \(token)" //token
        } else {
            return ""
        }
    }
    static func remove() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    //valid token
    static func isValid() -> Bool {
        let token = get()
        if token.isEmpty {
            return false
        }
        return true
    }
    //universal method
    static func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

struct Userid {
    static let key = "user_id"
    //set, get & remove auth token
    static func save(_ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    static func get() -> String {
        if let token = UserDefaults.standard.value(forKey: key) as? String {
            return token
        } else {
            return ""
        }
    }
    static func remove() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    //valid token
    static func isValid() -> Bool {
        let token = get()
        if token.isEmpty {
            return false
        }
        return true
    }
    //universal method
    static func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

struct Subscribe {
    static let key = "subscribe"
    //set, get & remove auth token
    static func save(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
    static func get() -> Bool {
        if let token = UserDefaults.standard.value(forKey: key) as? Bool {
            return token
        } else {
            return false
        }
    }
    static func remove() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    //valid token
//    static func isValid() -> Bool {
//        let token = get()
//        if token.isEmpty {
//            return false
//        }
//        return true
//    }
    //universal method
    static func set(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}


enum UserInter:String {
    case light = "light"
    case dark = "dark"
}


struct UserInterface{
    static let key = "user_interface"
    //set, get & remove
    static func save(_ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    static func get() -> UserInter {
        if let interface = UserDefaults.standard.value(forKey: key) as? String {
            return UserInter.init(rawValue: interface) ?? UserInter.dark
        } else {
            return UserInter.dark
        }
    }
    static func remove() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

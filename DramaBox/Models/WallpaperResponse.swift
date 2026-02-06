//
//  WallpaperResponse.swift
//  DramaBox
//
//  Created by DREAMWORLD on 16/01/26.
//

import Foundation

// MARK: - Wallpaper Model
struct WallpaperResponse: Codable {
    let wallpapers: [String]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wallpapers = try container.decode([String].self)
    }
}

// MARK: - Ringtone Models
struct Ringtone: Codable, Sendable {
    let categoryKey: String
    let ringtoneName: String
    let ringtoneUrl: String
}

struct RingtoneCategory: Codable, Sendable {
    let category: String
    let ringtones: [Ringtone]
}

typealias RingtoneResponse = [RingtoneCategory]

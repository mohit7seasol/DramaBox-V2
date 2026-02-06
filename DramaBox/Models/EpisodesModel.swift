//
//  EpisodesModel.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import Foundation

struct EpisodeResponse: Codable, Sendable {
    let httpResponseCode: Int
    let httpResponseMessage: String
    let data: EpisodeData
    
    enum CodingKeys: String, CodingKey {
        case httpResponseCode = "http_response_code"
        case httpResponseMessage = "http_response_message"
        case data
    }
}

struct EpisodeData: Codable, Sendable {
    let errorCode: Int
    let errorMessage: String
    let dramaSlug: String
    let subtitle: String
    let translation: String
    let isDubbed: String
    let data: [EpisodeItem]
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "ErrorCode"
        case errorMessage = "ErrorMessage"
        case dramaSlug = "DramaSlug"
        case subtitle = "Subtitle"
        case translation = "Translation"
        case isDubbed = "IsDubbed"
        case data
    }
}

struct EpisodeItem: Codable, Sendable {
    let epiId: String
    let dId: String
    let dName: String
    let dImage: String
    let epiName: String
    let video720p: String
    let video480p: String
    let video240p: String
    let noSub720p: String
    let noSub240p: String
    let noSub480p: String
    let duration: String
    let type: String
    let totalDStream: String
    let unlockCount: String
    let dDesc: String
    let thumbnails: String
    let translation: String
    let addedDt: String
    
    enum CodingKeys: String, CodingKey {
        case epiId = "epi_id"
        case dId = "d_id"
        case dName = "d_name"
        case dImage = "d_image"
        case epiName = "epi_name"
        case video720p = "720p"
        case video480p = "480p"
        case video240p = "240p"
        case noSub720p = "nosub720p"
        case noSub240p = "nosub240p"
        case noSub480p = "nosub480p"
        case duration
        case type
        case totalDStream = "total_d_stream"
        case unlockCount = "unlock_count"
        case dDesc = "d_desc"
        case thumbnails
        case translation
        case addedDt = "added_dt"
    }
}

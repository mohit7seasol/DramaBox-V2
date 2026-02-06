//
//  DramaModel.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import Foundation

// MARK: - Main Response
struct DramaResponse: Codable {
    let httpResponseCode: Int
    let httpResponseMessage: String
    let data: DramaMainData
    
    enum CodingKeys: String, CodingKey {
        case httpResponseCode = "http_response_code"
        case httpResponseMessage = "http_response_message"
        case data
    }
}

// MARK: - Main Data
struct DramaMainData: Codable {
    let errorCode: Int
    let errorMessage: String
    let data: [DramaSection]
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "ErrorCode"
        case errorMessage = "ErrorMessage"
        case data = "Data"
    }
}

// MARK: - Section
struct DramaSection: Codable {
    let listType: String
    let heading: String
    let type: String
    let eventName: String
    let more: Int
    let moreLink: String
    let moreParameters: String
    let style: String
    let moreParameterValue: String
    let list: [DramaItem]
    
    enum CodingKeys: String, CodingKey {
        case listType = "list_type"
        case heading
        case type
        case eventName = "event_name"
        case more
        case moreLink = "more_link"
        case moreParameters = "more_parameters"
        case style
        case moreParameterValue = "more_parameter_value"
        case list
    }
}

// MARK: - Item
struct DramaItem: Codable {
    let id: String?
    let dramaName: String?
    let catName: String?          // For categories section
    let dKeywords: String?
    let totalEpisodes: String?
    let dDesc: String?
    let slug: String?
    let imageUrl: String?
    let gradient: String?
    let unlockEpiCount: String?
    let status: String?
    let addedDt: String?
    let translation: String?
    let epiUrl: String?
    let tag: String?              // For full collection section
    let launchDate: String?       // For coming soon section
    
    enum CodingKeys: String, CodingKey {
        case id
        case dramaName = "drama_name"
        case catName = "cat_name"          // Added
        case dKeywords = "d_keywords"
        case totalEpisodes = "total_episodes"
        case dDesc = "d_desc"
        case slug
        case imageUrl = "image_url"
        case gradient
        case unlockEpiCount = "unlock_epi_count"
        case status
        case addedDt = "added_dt"
        case translation
        case epiUrl = "epi_url"
        case tag                           // Added
        case launchDate = "launch_date"    // Added
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties as optional
        id = try? container.decode(String.self, forKey: .id)
        dramaName = try? container.decode(String.self, forKey: .dramaName)
        catName = try? container.decode(String.self, forKey: .catName)
        dKeywords = try? container.decode(String.self, forKey: .dKeywords)
        totalEpisodes = try? container.decode(String.self, forKey: .totalEpisodes)
        dDesc = try? container.decode(String.self, forKey: .dDesc)
        slug = try? container.decode(String.self, forKey: .slug)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        gradient = try? container.decode(String.self, forKey: .gradient)
        unlockEpiCount = try? container.decode(String.self, forKey: .unlockEpiCount)
        status = try? container.decode(String.self, forKey: .status)
        addedDt = try? container.decode(String.self, forKey: .addedDt)
        translation = try? container.decode(String.self, forKey: .translation)
        epiUrl = try? container.decode(String.self, forKey: .epiUrl)
        tag = try? container.decode(String.self, forKey: .tag)
        launchDate = try? container.decode(String.self, forKey: .launchDate)
    }
    
    // Helper computed properties
    var displayName: String {
        return dramaName ?? catName ?? "Unknown"
    }
    
    var safeImageUrl: String {
        return imageUrl ?? ""
    }
    
    var safeEpiUrl: String {
        return epiUrl ?? ""
    }
}

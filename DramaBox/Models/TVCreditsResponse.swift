//
//  TVCreditsResponse.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

import Foundation

struct TVCreditsResponse: Codable {
    let id: Int
    let cast: [TVCast]
    let crew: [TVCrew]
}

struct TVCast: Codable {
    let adult: Bool
    let gender: Int?
    let id: Int
    let knownForDepartment: String?
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let character: String?
    let creditID: String
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case adult, gender, id, popularity, character, order, name
        case knownForDepartment = "known_for_department"
        case originalName = "original_name"
        case profilePath = "profile_path"
        case creditID = "credit_id"
    }
}

struct TVCrew: Codable {
    let adult: Bool
    let gender: Int?
    let id: Int
    let knownForDepartment: String?
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let creditID: String
    let department: String?
    let job: String?

    enum CodingKeys: String, CodingKey {
        case adult, gender, id, popularity, name, department, job
        case knownForDepartment = "known_for_department"
        case originalName = "original_name"
        case profilePath = "profile_path"
        case creditID = "credit_id"
    }
}

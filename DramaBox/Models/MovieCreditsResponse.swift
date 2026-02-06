//
//  MovieCreditsResponse.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

import Foundation

struct MovieCreditsResponse: Codable {
    let id: Int
    let cast: [MovieCast]
    let crew: [MovieCrew]
}

struct MovieCast: Codable {
    let adult: Bool
    let gender: Int?
    let id: Int
    let knownForDepartment: String?
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let castID: Int?
    let character: String?
    let creditID: String
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case adult, gender, id, popularity, name, character, order
        case knownForDepartment = "known_for_department"
        case originalName = "original_name"
        case profilePath = "profile_path"
        case castID = "cast_id"
        case creditID = "credit_id"
    }
}

struct MovieCrew: Codable {
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

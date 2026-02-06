//
//  PersonTVCreditsResponse.swift
//  DramaBox
//
//  Created by DREAMWORLD on 04/02/26.
//

struct PersonTVCreditsResponse: Codable {
    let cast: [PersonTVCast]
    let crew: [PersonTVCrew]
    let id: Int
}
struct PersonTVCast: Codable {
    let adult: Bool
    let backdropPath: String?
    let genreIds: [Int]
    let id: Int
    let originCountry: [String]
    let originalLanguage: String
    let originalName: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let firstAirDate: String?
    let name: String
    let voteAverage: Double
    let voteCount: Int
    let character: String?
    let creditId: String
    let episodeCount: Int?
    let firstCreditAirDate: String?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case id
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case popularity
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case character
        case creditId = "credit_id"
        case episodeCount = "episode_count"
        case firstCreditAirDate = "first_credit_air_date"
    }
}
struct PersonTVCrew: Codable {
    let adult: Bool
    let backdropPath: String?
    let genreIds: [Int]
    let id: Int
    let originCountry: [String]
    let originalLanguage: String
    let originalName: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let firstAirDate: String?
    let name: String
    let voteAverage: Double
    let voteCount: Int
    let creditId: String
    let department: String?
    let episodeCount: Int?
    let firstCreditAirDate: String?
    let job: String?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case id
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case popularity
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case creditId = "credit_id"
        case department
        case episodeCount = "episode_count"
        case firstCreditAirDate = "first_credit_air_date"
        case job
    }
}

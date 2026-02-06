//
//  TVShowDetails.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import Foundation
struct TVShowDetails: Codable {
    let adult: Bool
    let backdropPath: String?
    let createdBy: [CreatedBy]
    let episodeRunTime: [Int]
    let firstAirDate: String?
    let genres: [GenreMovieDetails]
    let homepage: String?
    let id: Int
    let inProduction: Bool
    let languages: [String]
    let lastAirDate: String?
    let lastEpisodeToAir: LastEpisode?
    let name: String
    let nextEpisodeToAir: LastEpisode?
    let networks: [Network]
    let numberOfEpisodes: Int
    let numberOfSeasons: Int
    let originCountry: [String]
    let originalLanguage: String
    let originalName: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let productionCompanies: [ProductionCompany]
    let productionCountries: [ProductionCountry]
    let seasons: [Season]
    let spokenLanguages: [SpokenLanguage]
    let status: String
    let tagline: String?
    let type: String
    let voteAverage: Double?
    let voteCount: Int?
    // 👇 Add this property
    let videos: VideosResponse?

    enum CodingKeys: String, CodingKey {
        case adult, genres, homepage, id, languages, name, overview, popularity, seasons, status, tagline, type, voteAverage, voteCount,videos
        case backdropPath = "backdrop_path"
        case createdBy = "created_by"
        case episodeRunTime = "episode_run_time"
        case firstAirDate = "first_air_date"
        case inProduction = "in_production"
        case lastAirDate = "last_air_date"
        case lastEpisodeToAir = "last_episode_to_air"
        case nextEpisodeToAir = "next_episode_to_air"
        case networks
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case posterPath = "poster_path"
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case spokenLanguages = "spoken_languages"
    }
}

struct CreatedBy: Codable {
    let id: Int
    let creditID: String
    let name: String
    let originalName: String
    let gender: Int?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, gender
        case creditID = "credit_id"
        case originalName = "original_name"
        case profilePath = "profile_path"
    }
}

struct LastEpisode: Codable {
    let id: Int
    let name: String
    let overview: String
    let voteAverage: Double
    let voteCount: Int
    let airDate: String
    let episodeNumber: Int
    let episodeType: String?
    let productionCode: String?
    let runtime: Int?
    let seasonNumber: Int
    let showID: Int
    let stillPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case episodeType = "episode_type"
        case productionCode = "production_code"
        case seasonNumber = "season_number"
        case showID = "show_id"
        case stillPath = "still_path"
    }
}

struct Network: Codable {
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}

struct Season: Codable {
    let airDate: String?
    let episodeCount: Int
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
        case seasonNumber = "season_number"
        case voteAverage = "vote_average"
    }
}

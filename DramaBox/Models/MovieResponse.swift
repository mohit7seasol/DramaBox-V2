//
//  MovieResponse.swift
//  DramaBox
//
//  Created by DREAMWORLD on 21/01/26.
//

import Foundation

class MoviesDataStore {
    static let shared = MoviesDataStore()
    
    private init() {}
    
    var nowPlayingMovies: [Movie] = []
    var popularMovies: [Movie] = []
    var topRatedMovies: [Movie] = []
    var trendingMovies: [Movie] = []
}

// MARK: - MovieResponse
struct MovieResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Movie
struct Movie: Codable {
    let adult: Bool
    let backdropPath: String?
    let genreIDs: [Int]
    let id: Int
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let releaseDate: String
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
    var genreNames: [String]?
    
    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIDs = "genre_ids"
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        
    }
}
extension Movie {
    init(id: Int, title: String = "", posterPath: String? = nil) {
        self.adult = false
        self.backdropPath = nil
        self.genreIDs = []
        self.id = id
        self.originalLanguage = ""
        self.originalTitle = title
        self.overview = ""
        self.popularity = 0
        self.posterPath = posterPath
        self.releaseDate = ""
        self.title = title
        self.video = false
        self.voteAverage = 0
        self.voteCount = 0
        self.genreNames = nil
    }
}

struct PersonDetails: Codable {
    let adult: Bool
    let also_known_as: [String]
    let biography: String
    let birthday: String?
    let deathday: String?
    let gender: Int
    let homepage: String?
    let id: Int
    let imdb_id: String?
    let known_for_department: String
    let name: String
    let place_of_birth: String?
    let popularity: Double
    let profile_path: String?
}

//
//  NetworkManager.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/12/25.
//

import Foundation
import Alamofire
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let baseProxyURL = "https://api-livevideocall.7seasol.in/proxy?url="
    private let tmdbBaseURL = "https://api.themoviedb.org/3"
    
    private let headers: HTTPHeaders = [
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmZmNlOWE0MGFmNTU5MDM5N2JiYjZjMWIwMGZjOGUxYyIsIm5iZiI6MTc0NjU5Njk0MC41NDIsInN1YiI6IjY4MWFmNDRjYWNkYTE2YzMyNjg1MDhhYyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.p-W6BpCTbQXniMiNOYcKHbuOYjsLoBHy7BdcKvrkbiI",
        "accept": "application/json"
    ]
    
    // MARK: - Configuration
    private let excludedMovieIds: Set<Int> = [
        269149,    // Zootopia
        1084242,   // Zootopia 2
        1580902,   // Zootopia 2 | A Special Look
        1591771,   // Zootopia 3
        391711,    // Imagining Zootopia
        1335850    // Return to Zootopia
    ]
        
    // MARK: - Helper
    private func makeURL(for endpoint: String) -> String {
        return "\(baseProxyURL)\(endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    }
    
        func fetchDramas(from vc: UIViewController,
                         page: Int,
                         completion: @escaping (Result<DramaResponse, Error>) -> Void) {
            
            guard ReachabilityManager.shared.isConnectedToNetwork() else {
                ReachabilityManager.shared.showNoInternetAlert(on: vc)
                return
            }
            
            let endpoint = "https://dramasstory.com/drama/new_home_screen_v2.php?currentpage=\(page)&app_ver=2.8&lc=en"
            
            // First, let's see the raw response to debug
            AF.request(makeURL(for: endpoint))
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        // Print raw response for debugging
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("API Response received")
                        }
                        
                        // Try to decode
                        do {
                            let decoder = JSONDecoder()
                            let dramaResponse = try decoder.decode(DramaResponse.self, from: data)
                            completion(.success(dramaResponse))
                        } catch let decodingError as DecodingError {
                            print("Decoding error details: \(decodingError)")
                            
                            // More detailed error information
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                print("Key '\(key.stringValue)' not found:")
                                print("codingPath: \(context.codingPath)")
                                print("debugDescription: \(context.debugDescription)")
                            case .valueNotFound(let type, let context):
                                print("Value of type '\(type)' not found:")
                                print("codingPath: \(context.codingPath)")
                            case .typeMismatch(let type, let context):
                                print("Type mismatch for type '\(type)':")
                                print("codingPath: \(context.codingPath)")
                            case .dataCorrupted(let context):
                                print("Data corrupted:")
                                print("codingPath: \(context.codingPath)")
                            @unknown default:
                                print("Unknown decoding error")
                            }
                            
                            completion(.failure(decodingError))
                        } catch {
                            completion(.failure(error))
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
    }
    func fetchEpisodes(from vc: UIViewController,
                       dramaId: String,
                       page: Int = 1,
                       completion: @escaping (Result<[EpisodeItem], Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let endpoint = "https://dramasstory.com/drama/drama_epi_list_v2.php?d_id=\(dramaId)&currentpage=\(page)&lc=en"
        
        AF.request(makeURL(for: endpoint))
            .validate()
            .responseData { response in  // Use responseData instead of responseDecodable
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let episodeResponse = try decoder.decode(EpisodeResponse.self, from: data)
                        completion(.success(episodeResponse.data.data))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    // MARK: - Fetch Remote Config (grfg.json)
    func fetchRemoteConfig(from vc: UIViewController,
                           completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let urlString = getJSON
        
        AF.request(urlString, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any] {
                        completion(.success(json))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format."])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - Network Manager Extension for FunVC APIs
extension NetworkManager {
    
    // MARK: - Fetch Wallpapers
    func fetchWallpapers(from vc: UIViewController,
                        completion: @escaping (Result<[String], Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let wallpaperURL = "https://d2is1ss4hhk4uk.cloudfront.net/iphonewallpaper.json"
        let endpoint = makeURL(for: wallpaperURL)
        
        AF.request(endpoint, method: .get)
            .validate()
            .responseDecodable(of: [String].self) { response in
                switch response.result {
                case .success(let wallpapers):
                    completion(.success(wallpapers))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Fetch Ringtones
    func fetchRingtones(from vc: UIViewController,
                       completion: @escaping (Result<RingtoneResponse, Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let ringtoneURL = "https://d2is1ss4hhk4uk.cloudfront.net/ringtones.json"
        let endpoint = URL(string: makeURL(for: ringtoneURL)) ?? URL(fileURLWithPath: "")
        
        // Create URL request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Create URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Handle errors
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Check for HTTP response status
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
                return
            }
            
            // Check status code (200-299 is success)
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusError = NSError(domain: "Network",
                                         code: httpResponse.statusCode,
                                         userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                DispatchQueue.main.async {
                    completion(.failure(statusError))
                }
                return
            }
            
            // Check if data exists
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "Network", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            // Parse JSON data
            do {
                let decoder = JSONDecoder()
                let ringtoneResponse = try decoder.decode(RingtoneResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completion(.success(ringtoneResponse))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    // MARK: - Download Image
    func downloadImage(from urlString: String,
                      completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    completion(.success(image))
                } else {
                    completion(.failure(NSError(domain: "Invalid image data", code: 400, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Download Audio
    func downloadAudio(from urlString: String,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
extension NetworkManager {
    private func getRegion() -> String {
        return AppStorage.get(forKey: AppStorage.selectedRegion) as String? ?? "US"
    }
    // MARK: - Map Language to TMDB Code
    private func mapLanguageToCode(_ language: String) -> String {
        switch language {
        case "English": return "en-US"
        case "Spanish": return "es-ES"
        case "Hindi": return "hi-IN"
        case "Danish": return "da-DK"
        case "German": return "de-DE"
        case "Italian": return "it-IT"
        case "Portuguese": return "pt-PT"
        case "Turkish": return "tr-TR"
        default: return "en-US"
        }
    }

    private func getLanguage() -> String {
        // Get selected language from AppStorage, default to "en-US"
        if let savedLanguage = AppStorage.get(forKey: AppStorage.selectedLanguage) as String? {
            // Map your ChooseLanguage enum to TMDB language codes
            return mapLanguageToCode(savedLanguage)
        }
        return "en-US" // Default fallback
    }
    private func filterMovies(_ movies: [Movie]) -> [Movie] {
        return movies.filter { !excludedMovieIds.contains($0.id) }
    }
    // MARK: - popular
    func fetchPopularMovies(from vc: UIViewController,
                            page: Int = 1,
                            completion: @escaping (Result<MovieResponse, Error>) -> Void) {
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            completion(.failure(NSError(domain: "NoInternet", code: -1)))
            return
        }
        
        let endpoint = "\(tmdbBaseURL)/movie/popular"
        let params: Parameters = [
            "language": getLanguage(),
            "page": page,
            "region": getRegion()
        ]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                        completion(.success(movieResponse))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    // MARK: - Upcoming Movies
    func fetchUpcomingMovies(from vc: UIViewController,
                             page: Int = 1,
                             completion: @escaping (Result<[Movie], Error>) -> Void) {
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let endpoint = "\(tmdbBaseURL)/movie/upcoming"
        let params: Parameters = [
            "language": getLanguage(),
            "page": page/*,
            "region": getRegion()*/
        ]
        
        AF.request(makeURL(for: endpoint + "?\(getRegion())"), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                        completion(.success(movieResponse.results))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    func fetchTopRatedMovies(from vc: UIViewController,
                             page: Int = 1,
                             completion: @escaping (Result<MovieResponse, Error>) -> Void) {
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            completion(.failure(NSError(domain: "NoInternet", code: -1)))
            return
        }
        
        let endpoint = "\(tmdbBaseURL)/movie/top_rated"
        let params: Parameters = [
            "language": getLanguage(),
            "page": page,
            "region": getRegion()
        ]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                        completion(.success(movieResponse))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    func fetchMovieDetails(movieId: Int,
                           completion: @escaping (Result<MovieDetails, Error>) -> Void) {

        let endpoint = "\(tmdbBaseURL)/movie/\(movieId)"
        let params: Parameters = [
            "language": getLanguage(),
            "append_to_response": "videos,images",
            "region": getRegion()
        ]

        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let movie = try decoder.decode(MovieDetails.self, from: data)
                        completion(.success(movie))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func fetchTVDetails(
        seriesId: Int,
        completion: @escaping (Result<TVShowDetails, Error>) -> Void
    ) {
        let endpoint = "\(tmdbBaseURL)/tv/\(seriesId)"
        let params: Parameters = [
            "language": getLanguage(),
            "region": getRegion()
        ]

        AF.request(makeURL(for: endpoint),
                   method: .get,
                   parameters: params,
                   headers: headers)
        .validate()
        .responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decodedData = try JSONDecoder().decode(TVShowDetails.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Search Movie
    func searchMovies(from vc: UIViewController,
                      query: String,
                      page: Int,
                      completion: @escaping (Result<SearchMovieResponse, Error>) -> Void) {

        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }

        let endpoint = "\(tmdbBaseURL)/search/movie"
        let params: Parameters = [
            "query": query,
            "include_adult": false,
            "language": getLanguage(),
            "page": page
        ]

        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {

                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(SearchMovieResponse.self, from: data)

                        // Apply filtering
                        let filteredResults = self.filterSearchMovies(response.results)

                        let filteredResponse = SearchMovieResponse(
                            page: response.page,
                            results: filteredResults,
                            totalPages: response.totalPages,
                            totalResults: max(
                                0,
                                response.totalResults -
                                (response.results.count - filteredResults.count)
                            )
                        )

                        completion(.success(filteredResponse))

                    } catch {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func filterSearchMovies(_ movies: [SearchMovie]) -> [SearchMovie] {
        return movies.filter { !excludedMovieIds.contains($0.id) }
    }
    
    func fetchListByGenre(from vc: UIViewController,
                          genreId: Int,
                          page: Int,
                          completion: @escaping (Result<MovieResponse, Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let endpoint = "\(tmdbBaseURL)/discover/movie"
        let params: Parameters = [
            "with_genres": genreId,
            "region": getRegion(),
            "language": getLanguage(),
            "page": page
        ]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData(queue: .global(qos: .userInitiated)) { response in
                switch response.result {

                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let movieResponse = try decoder.decode(MovieResponse.self, from: data)

                        DispatchQueue.main.async {
                            completion(.success(movieResponse))
                        }

                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }

                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
    }
}
extension NetworkManager {
    func fetchQuiz(quizID: String,
                   from vc: UIViewController?,
                   completion: @escaping (Result<[QuizQuestion], Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            if let vc = vc {
                ReachabilityManager.shared.showNoInternetAlert(on: vc)
            }
            return
        }

        // Base URL (your proxy)
        let endpoint = "https://api.quiztwiz.com/api/question/?quiz=\(quizID)"

        // Required API headers
        var customHeaders: HTTPHeaders = [
            "Host": "api.quiztwiz.com",
            "Referer": "https://test.com"
        ]

        // ✅ Merge with existing headers (Authorization, etc.)
        for header in headers {
            customHeaders.add(name: header.name, value: header.value)
        }

        // ✅ Make request
        AF.request(endpoint, method: .get, headers: customHeaders)
            .validate(contentType: ["application/json", "text/html"])
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let quizResponse = try decoder.decode(QuizResponse.self, from: data)
                        completion(.success(quizResponse.data))
                    } catch {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("🔴 Quiz API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)

                    if let data = response.data,
                       let body = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", body)
                    }
                    completion(.failure(error))
                }
            }
    }
}
extension NetworkManager {
    // MARK: - Movie Details within fetch Movie cast crew or TV Cast creq
    // MARK: - Fetch Movie Credits
    func fetchMovieCredits(movieId: Int,
                           completion: @escaping (Result<MovieCreditsResponse, Error>) -> Void) {
        let endpoint = "\(tmdbBaseURL)/movie/\(movieId)/credits"
        let params: Parameters = ["language": getLanguage(), "region": getRegion()]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let credits = try decoder.decode(MovieCreditsResponse.self, from: data)
                        completion(.success(credits))
                    } catch {
                        print("🔴 Movie Credits Decoding Error:", error.localizedDescription)
                        print("🔗 URL:", endpoint)
                        
                        if let responseBody = String(data: data, encoding: .utf8) {
                            print("🔍 Response Body:", responseBody)
                        }
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    print("🔴 Movie Credits API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)
                    
                    if let data = response.data,
                       let responseBody = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", responseBody)
                    }
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Fetch TV Series Credits
    func fetchTVCredits(tvId: Int,
                        completion: @escaping (Result<TVCreditsResponse, Error>) -> Void) {
        let endpoint = "\(tmdbBaseURL)/tv/\(tvId)/credits"
        let params: Parameters = ["language": getLanguage(), "region": getRegion()]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let credits = try decoder.decode(TVCreditsResponse.self, from: data)
                        completion(.success(credits))
                    } catch {
                        print("🔴 TV Credits Decoding Error:", error.localizedDescription)
                        print("🔗 URL:", endpoint)
                        
                        if let responseBody = String(data: data, encoding: .utf8) {
                            print("🔍 Response Body:", responseBody)
                        }
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    print("🔴 TV Credits API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)
                    
                    if let data = response.data,
                       let responseBody = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", responseBody)
                    }
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Famouce faces within fetch it's related tv or movie show
    // MARK: - Fetch Person Movie Credits
    func fetchPersonMovieCredits(
        personId: Int,
        completion: @escaping (Result<PersonMovieCreditsResponse, Error>) -> Void
    ) {

        let endpoint = "\(tmdbBaseURL)/person/\(personId)/movie_credits"
        let params: Parameters = [
            "language": getLanguage(),
            "region": getRegion()
        ]

        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {

                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let credits = try decoder.decode(PersonMovieCreditsResponse.self, from: data)
                        completion(.success(credits))
                    } catch {
                        print("🔴 Person Movie Credits Decoding Error:", error.localizedDescription)
                        print("🔗 URL:", endpoint)

                        if let body = String(data: data, encoding: .utf8) {
                            print("🔍 Response Body:", body)
                        }
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("🔴 Person Movie Credits API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)

                    if let data = response.data,
                       let body = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", body)
                    }
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Fetch Person TV Credits
    func fetchPersonTVCredits(
        personId: Int,
        completion: @escaping (Result<PersonTVCreditsResponse, Error>) -> Void
    ) {

        let endpoint = "\(tmdbBaseURL)/person/\(personId)/tv_credits"
        let params: Parameters = [
            "language": getLanguage(),
            "region": getRegion()
        ]

        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {

                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let credits = try decoder.decode(PersonTVCreditsResponse.self, from: data)
                        completion(.success(credits))
                    } catch {
                        print("🔴 Person TV Credits Decoding Error:", error.localizedDescription)
                        print("🔗 URL:", endpoint)

                        if let body = String(data: data, encoding: .utf8) {
                            print("🔍 Response Body:", body)
                        }
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("🔴 Person TV Credits API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)

                    if let data = response.data,
                       let body = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", body)
                    }
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Person Details
    func fetchPersonDetails(personId: Int,
                            from vc: UIViewController,
                            completion: @escaping (Result<PersonDetails, Error>) -> Void) {
        
        guard ReachabilityManager.shared.isConnectedToNetwork() else {
            ReachabilityManager.shared.showNoInternetAlert(on: vc)
            return
        }
        
        let endpoint = "\(tmdbBaseURL)/person/\(personId)"
        let params: Parameters = [
            "language": getLanguage(),
            "region": getRegion()
        ]
        
        AF.request(makeURL(for: endpoint), parameters: params, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let personDetails = try decoder.decode(PersonDetails.self, from: data)
                        completion(.success(personDetails))
                    } catch {
                        print("🔴 Person Details Decoding Error:", error.localizedDescription)
                        print("🔗 URL:", endpoint)
                        
                        if let responseBody = String(data: data, encoding: .utf8) {
                            print("🔍 Response Body:", responseBody)
                        }
                        
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    print("🔴 Person Details API Error:", error.localizedDescription)
                    print("🔗 URL:", endpoint)
                    
                    if let data = response.data,
                       let responseBody = String(data: data, encoding: .utf8) {
                        print("🔍 Response Body:", responseBody)
                    }
                    
                    completion(.failure(error))
                }
            }
    }
}

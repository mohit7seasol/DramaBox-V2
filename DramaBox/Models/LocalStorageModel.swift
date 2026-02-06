//
//  LocalStorageModel.swift
//  DramaBox
//
//  Created by DREAMWORLD on 10/12/25.
//

import Foundation

struct WatchHistoryItem: Codable {
    let episode: EpisodeItem
    let watchedDate: Date
    let watchedDuration: Double
    let episodeProgress: Double // 0.0 to 1.0
    
    enum CodingKeys: String, CodingKey {
        case episode
        case watchedDate
        case watchedDuration
        case episodeProgress
    }
}

struct SavedEpisode: Codable {
    let episode: EpisodeItem
    let savedDate: Date
    
    enum CodingKeys: String, CodingKey {
        case episode
        case savedDate
    }
}

// Local Storage Manager
class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let watchHistoryKey = "watch_history"
    private let savedEpisodesKey = "saved_episodes"
    
    private init() {}
    
    // MARK: - Watch History
    func saveWatchHistory(episode: EpisodeItem, duration: Double, progress: Double) {
        var history = getWatchHistory()
        
        // Remove if already exists
        history.removeAll { $0.episode.epiId == episode.epiId }
        
        // Add new entry
        let historyItem = WatchHistoryItem(
            episode: episode,
            watchedDate: Date(),
            watchedDuration: duration,
            episodeProgress: progress
        )
        
        history.insert(historyItem, at: 0) // Most recent first
        
        // Keep only last 100 items
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        saveWatchHistory(history)
    }
    
    func getWatchHistory() -> [WatchHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: watchHistoryKey),
              let history = try? JSONDecoder().decode([WatchHistoryItem].self, from: data) else {
            return []
        }
        return history
    }
    
    func removeWatchHistory(episodeId: String) {
        var history = getWatchHistory()
        history.removeAll { $0.episode.epiId == episodeId }
        saveWatchHistory(history)
    }
    
    func removeMultipleWatchHistory(episodeIds: [String]) {
        var history = getWatchHistory()
        history.removeAll { episodeIds.contains($0.episode.epiId) }
        saveWatchHistory(history)
    }
    
    private func saveWatchHistory(_ history: [WatchHistoryItem]) {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: watchHistoryKey)
        }
    }
    
    // MARK: - Saved Episodes
    func saveEpisode(_ episode: EpisodeItem) -> Bool {
        var savedEpisodes = getSavedEpisodes()
        
        // Check if already saved
        guard !savedEpisodes.contains(where: { $0.episode.epiId == episode.epiId }) else {
            return false // Already saved
        }
        
        let savedEpisode = SavedEpisode(episode: episode, savedDate: Date())
        savedEpisodes.insert(savedEpisode, at: 0) // Most recent first
        saveSavedEpisodes(savedEpisodes)
        return true
    }
    
    func removeSavedEpisode(episodeId: String) {
        var savedEpisodes = getSavedEpisodes()
        savedEpisodes.removeAll { $0.episode.epiId == episodeId }
        saveSavedEpisodes(savedEpisodes)
    }
    
    func removeMultipleSavedEpisodes(episodeIds: [String]) {
        var savedEpisodes = getSavedEpisodes()
        savedEpisodes.removeAll { episodeIds.contains($0.episode.epiId) }
        saveSavedEpisodes(savedEpisodes)
    }
    
    func getSavedEpisodes() -> [SavedEpisode] {
        guard let data = UserDefaults.standard.data(forKey: savedEpisodesKey),
              let episodes = try? JSONDecoder().decode([SavedEpisode].self, from: data) else {
            return []
        }
        return episodes
    }
    
    func isEpisodeSaved(episodeId: String) -> Bool {
        let savedEpisodes = getSavedEpisodes()
        return savedEpisodes.contains { $0.episode.epiId == episodeId }
    }
    
    private func saveSavedEpisodes(_ episodes: [SavedEpisode]) {
        if let encoded = try? JSONEncoder().encode(episodes) {
            UserDefaults.standard.set(encoded, forKey: savedEpisodesKey)
        }
    }
}

//
//  RingtoneListCell.swift
//  DramaBox
//
//  Created by DREAMWORLD on 20/01/26.
//

import UIKit
import AVFAudio
import MarqueeLabel

class RingtoneListCell: UICollectionViewCell, AVAudioPlayerDelegate {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var musicIconImageView: UIImageView!
    @IBOutlet weak var musicNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var totalDuration: TimeInterval = 0
    private var updateTimer: Timer?
    private var ringtoneData: Data?
    
    var ringtoneURL: URL?
    
    // Add callback for when music finishes
    var onPlaybackFinished: (() -> Void)?
    var onPlaybackPaused: (() -> Void)? // New callback for pause
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        updateTimer?.invalidate()
        updateTimer = nil
        setUnselectedStyle()
        ringtoneData = nil
        onPlaybackFinished = nil
        onPlaybackPaused = nil
    }
    
    private func setupCellUI() {
        // Set marquee style for titleLabel
        titleLabel.type = .continuous
        titleLabel.animationCurve = .linear
        titleLabel.fadeLength = 10.0
        titleLabel.trailingBuffer = 30.0
        
        // Set initial unselected style
        setUnselectedStyle()
        
        // Set play button images
        playButton.setImage(UIImage(named: "play_music"), for: .normal)
        
        // Configure labels
        titleLabel.textColor = .white
        musicNameLabel.textColor = .white
        durationLabel.textColor = .white
        
        // Set button tints
        menuButton.tintColor = .white
        playButton.tintColor = .white
    }
    
    // MARK: - Selection Styles
    
    func setSelectedStyle() {
        backgroundImageView.image = UIImage(named: "selected_Music")
        backgroundImageView.isHidden = false
        musicIconImageView.image = UIImage(named: "music_selected")
        durationLabel.textColor = UIColor(hex: "#7A7A7A")
    }
    
    func setUnselectedStyle() {
        backgroundImageView.image = UIImage(named: "unselected_Music")
        backgroundImageView.isHidden = false
        musicIconImageView.image = UIImage(named: "music_unselected")
        durationLabel.textColor = .white
    }
    
    // MARK: - Playback Methods
    
    func configure(with ringtone: Ringtone, isPlaying: Bool = false) {
        titleLabel.text = ringtone.ringtoneName
        musicNameLabel.text = ringtone.ringtoneName
        
        // Update play button based on actual player state
        if let player = audioPlayer {
            self.isPlaying = player.isPlaying
            playButton.setImage(UIImage(named: player.isPlaying ? "pause_music" : "play_music"), for: .normal)
            
            // Set cell style based on actual playing state
            if player.isPlaying {
                setSelectedStyle()
            } else {
                setUnselectedStyle()
            }
        } else {
            self.isPlaying = isPlaying
            playButton.setImage(UIImage(named: isPlaying ? "pause_music" : "play_music"), for: .normal)
            
            // Set cell style based on playing state
            if isPlaying {
                setSelectedStyle()
            } else {
                setUnselectedStyle()
            }
        }
        
        // Set ringtone URL and load data
        if let url = URL(string: ringtone.ringtoneUrl) {
            ringtoneURL = url
            loadAudioData()
        }
    }
    
    private func loadAudioData() {
        guard let url = ringtoneURL else { return }
        
        // Reset duration label while loading
        durationLabel.text = "--:--"
        
        // Download audio data first (like reference code)
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.durationLabel.text = "00:00"
                }
                return
            }
            
            self.ringtoneData = data
            
            do {
                let player = try AVAudioPlayer(data: data)
                player.prepareToPlay()
                player.delegate = self  // Set delegate to self
                
                self.audioPlayer = player
                self.totalDuration = player.duration
                
                DispatchQueue.main.async {
                    // Show total duration
                    self.durationLabel.text = self.formatDuration(self.totalDuration)
                }
            } catch {
                print("Audio load failed:", error)
                DispatchQueue.main.async {
                    self.durationLabel.text = "00:00"
                }
            }
        }.resume()
    }
    
    func play() {
        guard let data = ringtoneData else {
            // Try to load data first
            loadAudioData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.play()
            }
            return
        }
        
        do {
            // Stop previous audio
            audioPlayer?.stop()
            
            // Create new player with downloaded data
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            player.delegate = self  // Set delegate to handle playback finish
            self.audioPlayer = player
            self.totalDuration = player.duration
            
            // Setup audio session
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Play audio
            player.play()
            isPlaying = true
            playButton.setImage(UIImage(named: "pause_music"), for: .normal)
            
            // Update UI to selected style when playing
            setSelectedStyle()
            
            // Start updating remaining duration
            startUpdatingRemainingDuration()
            
            // Debug
            print("Started playing - Total duration: \(totalDuration)")
            
        } catch {
            print("Audio play failed: \(error)")
            durationLabel.text = "Error"
        }
    }
    
    func pause() {
        guard let player = audioPlayer else { return }

        player.pause()
        isPlaying = false
        playButton.setImage(UIImage(named: "play_music"), for: .normal)
        
        // Reset to unselected style when paused
        setUnselectedStyle()

        stopUpdatingDuration()

        // Show total duration when paused
        durationLabel.text = formatDuration(totalDuration)
        
        // Notify parent that playback was paused
        onPlaybackPaused?()
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        playButton.setImage(UIImage(named: "play_music"), for: .normal)
        stopUpdatingDuration()
        durationLabel.text = formatDuration(totalDuration)
        
        // Reset to unselected style when stopped
        setUnselectedStyle()
    }
    
    func togglePlayPause() {
        guard audioPlayer != nil else {
            play()
            return
        }
        
        if let player = audioPlayer {
            if player.isPlaying {
                pause()
            } else {
                play()
            }
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio finished playing successfully: \(flag)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Reset playback state
            self.isPlaying = false
            self.playButton.setImage(UIImage(named: "play_music"), for: .normal)
            self.durationLabel.text = self.formatDuration(self.totalDuration)
            self.stopUpdatingDuration()
            
            // Reset cell UI to unselected style
            self.setUnselectedStyle()
            
            // Reset player to beginning
            self.audioPlayer?.currentTime = 0
            
            // Notify the parent (collection view) that playback finished
            self.onPlaybackFinished?()
        }
    }
    
    private func startUpdatingRemainingDuration() {
        updateTimer?.invalidate()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let player = self.audioPlayer,
                  player.isPlaying else {
                return
            }

            let remaining = max(0, self.totalDuration - player.currentTime)

            DispatchQueue.main.async {
                if remaining <= 0 {
                    self.stopPlayback()
                } else {
                    self.durationLabel.text = "\(self.formatDuration(remaining))"
                }
            }
        }
    }

    private func stopUpdatingDuration() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//
//  IPTVChannelPlayerVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

import UIKit
import AVKit
import AVFoundation
import SVProgressHUD
import SDWebImage

class IPTVChannelPlayVC: UIViewController {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var currentDurationLbl: UILabel!
    @IBOutlet weak var totalDurationLbl: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    var channelName = ""
    var channelUrl = ""
    var channelLogo = ""
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var isPlaying = false
    private var heightOfAd = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure SVProgressHUD
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setMinimumDismissTimeInterval(2.0)
        
        // Set channel name
        titleLbl.text = channelName
        
        // Show loading indicator immediately
        SVProgressHUD.show(withStatus: "Loading channel...".localized(LocalizationService.shared.language))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playerView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isPlaying = true          // ✅ AUTO PLAY FLAG
        playPauseBtn.setImage(UIImage(named: "pause"), for: .normal)

        setupPlayer() // ✅ CRITICAL: Call setupPlayer here!

        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        slider.isUserInteractionEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        isPlaying = false
        SVProgressHUD.dismiss()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if player?.currentItem?.status == .readyToPlay {
                SVProgressHUD.dismiss()
                
                if isPlaying {
                    player?.play()
                    playPauseBtn.setImage(UIImage(named: "pause"), for: .normal)
                } else {
                    playPauseBtn.setImage(UIImage(named: "play"), for: .normal)
                }
            } else if player?.currentItem?.status == .failed {
                // Show error if player failed to load
                SVProgressHUD.dismiss()
                showErrorAlert(message: "Failed to load channel. Please check your internet connection.".localized(LocalizationService.shared.language))
                playPauseBtn.setImage(UIImage(named: "play"), for: .normal)
                isPlaying = false
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerView.bounds
    }
    
    private func setupPlayer() {
        guard let url = URL(string: channelUrl) else {
            SVProgressHUD.dismiss()
            showErrorAlert(message: "Invalid channel URL".localized(LocalizationService.shared.language))
            return
        }
        
        // Show loading indicator while setting up player
        SVProgressHUD.show(withStatus: "Loading channel...".localized(LocalizationService.shared.language))
        
        // Clean up existing player if any
        cleanupPlayer()
        
        // Create player item directly from URL (simpler approach)
        let playerItem = AVPlayerItem(url: url)
        
        // Create player with the item
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = playerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let layer = playerLayer {
            playerView.layer.addSublayer(layer)
        }
        
        // Resize properly
        playerLayer?.frame = playerView.bounds
        playerView.layoutIfNeeded()
        
        // Update slider & labels while playing
        addTimeObserver()
        
        // Load duration if available
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                var error: NSError?
                let status = playerItem.asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    let duration = playerItem.asset.duration
                    let seconds = CMTimeGetSeconds(duration)
                    if seconds.isFinite && seconds > 0 {
                        self?.slider.maximumValue = Float(seconds)
                        self?.totalDurationLbl.text = self?.formatTime(seconds)
                    } else {
                        self?.totalDurationLbl.text = "Live"
                    }
                } else {
                    self?.totalDurationLbl.text = "Live"
//                    self?.slider.isHidden = true // Hide slider for live streams
                }
                
                // If still loading after 30 seconds, show error
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    if SVProgressHUD.isVisible() {
                        SVProgressHUD.dismiss()
                        self?.showErrorAlert(message: "Channel loading timeout. Please try again.".localized(LocalizationService.shared.language))
                        self?.playPauseBtn.setImage(UIImage(named: "play"), for: .normal)
                        self?.isPlaying = false
                    }
                }
            }
        }
        
        // Add observer for player status
        playerItem.addObserver(self,
                               forKeyPath: "status",
                               options: [.new, .old],
                               context: nil)
        
        // Add observer for player error
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
        
        // Add observer for playback stall
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStalled),
            name: .AVPlayerItemPlaybackStalled,
            object: playerItem
        )
        
        // Add observer for playback ended
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    private func cleanupPlayer() {
        // Remove existing time observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // Remove existing player layer
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        // Remove observers from existing player item
        if let currentItem = player?.currentItem {
            currentItem.removeObserver(self, forKeyPath: "status")
        }
        
        // Remove notifications
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        // Pause and nil player
        player?.pause()
        player = nil
    }
    
    private func addTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let currentSeconds = CMTimeGetSeconds(time)
            self?.slider.value = Float(currentSeconds)
            self?.currentDurationLbl.text = self?.formatTime(currentSeconds)
        }
    }
    
    private func formatTime(_ seconds: Float64) -> String {
        guard seconds.isFinite else { return "--:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    @objc private func playerItemFailedToPlay(notification: Notification) {
        SVProgressHUD.dismiss()
        showErrorAlert(message: "Failed to play channel. Please try again.".localized(LocalizationService.shared.language))
        playPauseBtn.setImage(UIImage(named: "play"), for: .normal)
        isPlaying = false
    }
    
    @objc private func playbackStalled(notification: Notification) {
        SVProgressHUD.show(withStatus: "Buffering...")
        // Auto-dismiss buffering indicator after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    @objc private func playerItemDidPlayToEndTime(notification: Notification) {
        // Optionally restart playback or show message
        print("Playback finished")
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error",
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let targetTime = CMTime(seconds: Double(sender.value), preferredTimescale: 600)
        player?.seek(to: targetTime)
    }
    
    @IBAction func playPauseTapped(_ sender: UIButton) {
        guard let player = player else { return }

        if isPlaying {
            // ▶️ PAUSE
            player.pause()
            isPlaying = false
            playPauseBtn.setImage(UIImage(named: "play"), for: .normal)

        } else {
            // ▶️ PLAY
            if player.currentItem?.status == .failed {
                SVProgressHUD.show(withStatus: "Retrying...")
                setupPlayer()
                return
            }

            player.play()
            isPlaying = true
            playPauseBtn.setImage(UIImage(named: "pause"), for: .normal)
        }
    }
    
    deinit {
        cleanupPlayer()
        SVProgressHUD.dismiss()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension IPTVChannelPlayVC {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

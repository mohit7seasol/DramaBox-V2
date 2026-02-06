//
//  SpeedSetBottomPopUp.swift
//  DramaBox
//
//  Created by DREAMWORLD on 11/12/25.
//

import UIKit
import SwiftPopup

class SpeedSetBottomPopUp: SwiftPopup {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var videoSpeedAndQualityView: UIView!
    @IBOutlet weak var playSpeedExpandButton: UIButton!
    @IBOutlet weak var displayVideoQualityExpandButton: UIButton!
    @IBOutlet weak var zeroPointSeventyFiveXSpeedButton: UIButton! // 0.75X
    @IBOutlet weak var oneXSpeedButton: UIButton! // 1.0X
    @IBOutlet weak var onePointFiveXSpeedButton: UIButton! // 1.5X
    @IBOutlet weak var twoXSpeedButton: UIButton! // 2.0X
    @IBOutlet weak var playSpeedOptionsHeightConstant: NSLayoutConstraint!
    
    @IBOutlet weak var twoHundredFortyPVideoQualityButton: UIButton! // 240P
    @IBOutlet weak var fourHundredEighyPVideoQualityButton: UIButton! // 480P
    @IBOutlet weak var seventHundredTwentyPVideoQualityButton: UIButton! // 720p
    @IBOutlet weak var videoQualityHeightConstant: NSLayoutConstraint!
    @IBOutlet weak var playSpeedLabel: UILabel!
    @IBOutlet weak var displayQualityLabel: UILabel!
    
    // Properties to maintain functionality
    var selectedSpeedIndex: Int = 0 // 0: 0.75X, 1: 1X, 2: 1.5X, 3: 2X
    var selectedQualityIndex: Int = 0 // 0: 240P, 1: 480P, 2: 720P
    var isPlaySpeedExpanded: Bool = false
    var isVideoQualityExpanded: Bool = false
    
    var speedChangeHandler: ((Int) -> Void)?
    var qualityChangeHandler: ((Int) -> Void)?
    var closeHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupButtonActions()
        updateButtonStates()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Set initial states
        isPlaySpeedExpanded = false
        isVideoQualityExpanded = false
        
        // Initially hide the expandable buttons
        oneXSpeedButton.isHidden = true
        onePointFiveXSpeedButton.isHidden = true
        twoXSpeedButton.isHidden = true
        fourHundredEighyPVideoQualityButton.isHidden = true
        seventHundredTwentyPVideoQualityButton.isHidden = true
        
        // Set initial heights
        playSpeedOptionsHeightConstant.constant = 34
        videoQualityHeightConstant.constant = 34
        
        playSpeedLabel.text = "Play Speed".localized(LocalizationService.shared.language)
        displayQualityLabel.text = "Display Quality".localized(LocalizationService.shared.language)
        
        // Style the view
        videoSpeedAndQualityView.layer.cornerRadius = 40
        videoSpeedAndQualityView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        videoSpeedAndQualityView.clipsToBounds = true
    }
    
    private func setupButtonActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add button actions for speed
        zeroPointSeventyFiveXSpeedButton.addTarget(self, action: #selector(speedButtonTapped(_:)), for: .touchUpInside)
        oneXSpeedButton.addTarget(self, action: #selector(speedButtonTapped(_:)), for: .touchUpInside)
        onePointFiveXSpeedButton.addTarget(self, action: #selector(speedButtonTapped(_:)), for: .touchUpInside)
        twoXSpeedButton.addTarget(self, action: #selector(speedButtonTapped(_:)), for: .touchUpInside)
        
        // Add button actions for quality
        twoHundredFortyPVideoQualityButton.addTarget(self, action: #selector(qualityButtonTapped(_:)), for: .touchUpInside)
        fourHundredEighyPVideoQualityButton.addTarget(self, action: #selector(qualityButtonTapped(_:)), for: .touchUpInside)
        seventHundredTwentyPVideoQualityButton.addTarget(self, action: #selector(qualityButtonTapped(_:)), for: .touchUpInside)
        
        // Expand buttons
        playSpeedExpandButton.addTarget(self, action: #selector(playSpeedExpandButtonTapped), for: .touchUpInside)
        displayVideoQualityExpandButton.addTarget(self, action: #selector(displayVideoQualityExpandButtonTapped), for: .touchUpInside)
    }
    
    private func updateButtonStates() {

        // Don't run if outlets not connected yet
        guard isViewLoaded else { return }

        let selectedColor = UIColor.white
        let unselectedColor = UIColor(hex: "#878787") ?? UIColor.lightGray

        zeroPointSeventyFiveXSpeedButton.setTitleColor(selectedSpeedIndex == 0 ? selectedColor : unselectedColor, for: .normal)
        oneXSpeedButton.setTitleColor(selectedSpeedIndex == 1 ? selectedColor : unselectedColor, for: .normal)
        onePointFiveXSpeedButton.setTitleColor(selectedSpeedIndex == 2 ? selectedColor : unselectedColor, for: .normal)
        twoXSpeedButton.setTitleColor(selectedSpeedIndex == 3 ? selectedColor : unselectedColor, for: .normal)

        twoHundredFortyPVideoQualityButton.setTitleColor(selectedQualityIndex == 0 ? selectedColor : unselectedColor, for: .normal)
        fourHundredEighyPVideoQualityButton.setTitleColor(selectedQualityIndex == 1 ? selectedColor : unselectedColor, for: .normal)
        seventHundredTwentyPVideoQualityButton.setTitleColor(selectedQualityIndex == 2 ? selectedColor : unselectedColor, for: .normal)
    }
    
    @objc private func closeButtonTapped() {
        closeHandler?()
        dismiss() // Use SwiftPopup's dismiss method
    }
    
    @objc private func speedButtonTapped(_ sender: UIButton) {
        switch sender {
        case zeroPointSeventyFiveXSpeedButton:
            selectedSpeedIndex = 0
        case oneXSpeedButton:
            selectedSpeedIndex = 1
        case onePointFiveXSpeedButton:
            selectedSpeedIndex = 2
        case twoXSpeedButton:
            selectedSpeedIndex = 3
        default:
            selectedSpeedIndex = 0
        }
        
        updateButtonStates()
        speedChangeHandler?(selectedSpeedIndex)
    }
    
    @objc private func qualityButtonTapped(_ sender: UIButton) {
        switch sender {
        case twoHundredFortyPVideoQualityButton:
            selectedQualityIndex = 0
        case fourHundredEighyPVideoQualityButton:
            selectedQualityIndex = 1
        case seventHundredTwentyPVideoQualityButton:
            selectedQualityIndex = 2
        default:
            selectedQualityIndex = 0
        }
        
        updateButtonStates()
        qualityChangeHandler?(selectedQualityIndex)
    }
    
    @objc private func playSpeedExpandButtonTapped() {
        isPlaySpeedExpanded = !isPlaySpeedExpanded
        
        UIView.animate(withDuration: 0.3) {
            if self.isPlaySpeedExpanded {
                self.oneXSpeedButton.isHidden = false
                self.onePointFiveXSpeedButton.isHidden = false
                self.twoXSpeedButton.isHidden = false
                self.playSpeedOptionsHeightConstant.constant = 34 * 4
            } else {
                self.oneXSpeedButton.isHidden = true
                self.onePointFiveXSpeedButton.isHidden = true
                self.twoXSpeedButton.isHidden = true
                self.playSpeedOptionsHeightConstant.constant = 34
            }
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func displayVideoQualityExpandButtonTapped() {
        isVideoQualityExpanded = !isVideoQualityExpanded
        
        UIView.animate(withDuration: 0.3) {
            if self.isVideoQualityExpanded {
                self.fourHundredEighyPVideoQualityButton.isHidden = false
                self.seventHundredTwentyPVideoQualityButton.isHidden = false
                self.videoQualityHeightConstant.constant = 34 * 3
            } else {
                self.fourHundredEighyPVideoQualityButton.isHidden = true
                self.seventHundredTwentyPVideoQualityButton.isHidden = true
                self.videoQualityHeightConstant.constant = 34
            }
            self.view.layoutIfNeeded()
        }
    }
    
    func configure(selectedSpeedIndex: Int, selectedQualityIndex: Int) {
        self.selectedSpeedIndex = selectedSpeedIndex
        self.selectedQualityIndex = selectedQualityIndex
        updateButtonStates()
    }
}

//
//  QuizQuestionsVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 23/01/26.
//

import UIKit
import Foundation
import SVProgressHUD

// MARK: - Quiz Response
struct QuizResponse: Codable {
    let message: String
    let data: [QuizQuestion]
}

// MARK: - Quiz Question
struct QuizQuestion: Codable {
    let _id: String
    let question: String
    let answer: [String]      // options array
    let correct: String       // correct option string (matches one of `answer`)
    let time: String?
    let coins: String?
    let quiz: QuizInfo?
    
    // Map keys if needed
    enum CodingKeys: String, CodingKey {
        case _id, question, answer, correct, time, coins, quiz
    }
}

struct QuizInfo: Codable {
    let _id: String
    let title: String
    let category: Category
    let img: String?
    let totalPrice: String?
    let entryFee: String?
    let live: Bool?
    // add other fields if needed
}

struct Category: Codable {
    let _id: String
    let name: String
    let img: String?
}

class QuizQuestionsVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var startQuizLabel: UILabel!
    @IBOutlet weak var q1AnswerView: UIView!
    @IBOutlet weak var q2AnswerView: UIView!
    @IBOutlet weak var q3AnswerView: UIView!
    @IBOutlet weak var q4AnswerView: UIView!
    @IBOutlet weak var q5AnswerView: UIView!
    @IBOutlet weak var q6AnswerView: UIView!
    @IBOutlet weak var q7AnswerView: UIView!
    @IBOutlet weak var q8AnswerView: UIView!
    @IBOutlet weak var q9AnswerView: UIView!
    @IBOutlet weak var q10AnswerView: UIView!
    @IBOutlet weak var currentQuestionNumberLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var optionAButton: UIButton!
    @IBOutlet weak var optionBButton: UIButton!
    @IBOutlet weak var optionCButton: UIButton!
    @IBOutlet weak var optionDButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var questionView: UIView!
    @IBOutlet weak var answerAllViewscrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addNativeView: UIView!
    @IBOutlet weak var nativeHeighConstant: NSLayoutConstraint!
    @IBOutlet weak var doneButtonView: GradientDesignableView!
    @IBOutlet weak var doneButtonLabel: UILabel!
    
    // MARK: - Properties
    private var allQuestions: [QuizQuestion] = []
    private var displayQuestions: [QuizQuestion] = [] // 10 random
    
    private var currentIndex: Int = 0
    private var selectedOptionButton: UIButton?
    private var correctCount = 0
    private var wrongCount = 0
    
    // Track answer states for each question
    private var questionStates: [Int: (isCorrect: Bool, selectedOption: String?)] = [:]
    
    // answer view array for easy access
    private lazy var answerViews: [UIView] = [
        q1AnswerView, q2AnswerView, q3AnswerView, q4AnswerView, q5AnswerView,
        q6AnswerView, q7AnswerView, q8AnswerView, q9AnswerView, q10AnswerView
    ].compactMap { $0 }
    
    // Colors
    private let unfilledColor = UIColor(hex: "#121212")
    private let selectedBorderWidth: CGFloat = 3.0
    private let defaultCornerRadius: CGFloat = 8.0
    private let lightGrayColor = UIColor.lightGray
    
    // Provide the quiz id you want to load (could be injected before presenting)
    var quizID: String = AppConstant.quizID
    
    var googleNativeAds = GoogleNativeAds()
    var isShowNativeAds = true
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setLoca()
        configureAnswerViewsInitial()
        loadQuiz()
        subscribeNativeAd()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Scroll to current question when layout is ready
        scrollToCurrentQuestion()
    }
    
    // MARK: - UI Setup
    func setUpUI() {
        self.titleLabel.text = "Quiz Time".localized(LocalizationService.shared.language)
        // Configure option buttons with #121212 background
        [optionAButton, optionBButton, optionCButton, optionDButton].forEach { btn in
            btn?.titleLabel?.numberOfLines = 0
            btn?.titleLabel?.textAlignment = .center
            btn?.layer.cornerRadius = defaultCornerRadius
            btn?.layer.borderWidth = 1.0
            btn?.layer.borderColor = UIColor.clear.cgColor
            btn?.backgroundColor = UIColor(hex: "#121212") // Set background color
            btn?.layer.borderColor = UIColor.lightGray.cgColor
            btn?.layer.borderWidth = 1.0
        }
        
        // Set light gray corner radius for question view
        questionView.layer.cornerRadius = 12
        questionView.layer.borderWidth = 1.0
        questionView.layer.borderColor = lightGrayColor.cgColor
        
        doneButton.layer.cornerRadius = 10
        doneButtonLabel.textColor = .black
        doneButtonView.cornerRadius = doneButtonView.frame.height / 2
        
        // Configure scroll view
        answerAllViewscrollView.delegate = self
    }
    
    func setLoca() {
        startQuizLabel.text = "Start Quiz".localized(LocalizationService.shared.language)
//        doneButton.setTitle("Next".localized(LocalizationService.shared.language), for: .normal)
        doneButtonLabel.text = "Next".localized(LocalizationService.shared.language)
    }
    func subscribeNativeAd() {
        nativeHeighConstant.constant = Subscribe.get() ? 0 : 200
        addNativeView.isHidden = Subscribe.get()

        guard Subscribe.get() == false else {
            HelperManager.hideSkeleton(nativeAdView: addNativeView)
            return
        }

        addNativeView.backgroundColor = UIColor.appAddBg
        HelperManager.showSkeleton(nativeAdView: addNativeView)

        googleNativeAds.loadAds(self) { [weak self] nativeAdsTemp in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 200
                self.addNativeView.isHidden = false
                self.addNativeView.subviews.forEach { $0.removeFromSuperview() }
                self.googleNativeAds.showAdsView8(
                    nativeAd: nativeAdsTemp,
                    view: self.addNativeView
                )
                self.view.layoutIfNeeded()
            }
        }

        googleNativeAds.failAds(self) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                HelperManager.hideSkeleton(nativeAdView: self.addNativeView)
                self.nativeHeighConstant.constant = 0
                self.addNativeView.isHidden = true
                self.view.layoutIfNeeded()
            }
        }
    }
    private func configureAnswerViewsInitial() {
        for view in answerViews {
            view.backgroundColor = unfilledColor
            view.layer.cornerRadius = 3
            view.layer.borderWidth = 0
            view.layer.borderColor = UIColor.clear.cgColor
        }
        // mark first as selected (white color to current question view)
        if answerViews.indices.contains(0) {
            answerViews[0].backgroundColor = .white
        }
    }
    
    // MARK: - Load Quiz
    private func loadQuiz() {
        // Show spinner if you have one
        SVProgressHUD.show()
        NetworkManager.shared.fetchQuiz(quizID: quizID, from: self) { [weak self] result in
            SVProgressHUD.dismiss()
            DispatchQueue.main.async {
                switch result {
                case .success(let questions):
                    self?.allQuestions = questions
                    self?.prepareDisplayQuestions()
                    self?.showCurrentQuestion()
                case .failure(let error):
                    // handle error (alert)
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(LocalizationService.shared.language), style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    private func prepareDisplayQuestions() {
        // pick up to 10 random unique questions
        let shuffled = allQuestions.shuffled()
        displayQuestions = Array(shuffled.prefix(10))
        // Reset everything
        currentIndex = 0
        correctCount = 0
        wrongCount = 0
        selectedOptionButton = nil
        questionStates.removeAll()
        configureAnswerViewsInitial()
    }
    
    // MARK: - Display
    private func showCurrentQuestion() {
        guard displayQuestions.indices.contains(currentIndex) else { return }
        
        let q = displayQuestions[currentIndex]
        
        // Question number & text
        currentQuestionNumberLabel.text = String(format: "%02d", currentIndex + 1)
        currentQuestionNumberLabel.textColor = .white
        questionLabel.text = q.question
        
        // Options
        let answers = q.answer
        optionAButton.setTitle(answers.count > 0 ? answers[0] : "-", for: .normal)
        optionBButton.setTitle(answers.count > 1 ? answers[1] : "-", for: .normal)
        optionCButton.setTitle(answers.count > 2 ? answers[2] : "-", for: .normal)
        optionDButton.setTitle(answers.count > 3 ? answers[3] : "-", for: .normal)
        
        // Reset option button UI
        [optionAButton, optionBButton, optionCButton, optionDButton].forEach { btn in
            btn?.layer.borderColor = UIColor.clear.cgColor
            btn?.layer.borderWidth = 1.0
            btn?.layer.shadowOpacity = 0
            btn?.backgroundColor = UIColor(hex: "#121212")
            btn?.layer.borderColor = UIColor.lightGray.cgColor
            btn?.layer.borderWidth = 1.0
        }
        
        // Restore previous answer state (if answered)
        if let state = questionStates[currentIndex] {
            let selectedOption = state.selectedOption
            let buttons = [optionAButton, optionBButton, optionCButton, optionDButton]
            
            for button in buttons {
                if let btn = button,
                   let title = btn.title(for: .normal),
                   title == selectedOption {
                    
                    btn.layer.borderWidth = selectedBorderWidth
                    btn.layer.borderColor = state.isCorrect
                        ? UIColor.systemGreen.cgColor
                        : UIColor.systemRed.cgColor
                    
                    if !state.isCorrect {
                        highlightCorrectOption(correctAnswer: q.correct)
                    }
                }
            }
        }
        
        // Update answer indicator views
        for (index, view) in answerViews.enumerated() {
            if let state = questionStates[index] {
                view.backgroundColor = state.isCorrect ? .systemGreen : .systemRed
                view.layer.borderColor = view.backgroundColor?.cgColor
                view.layer.borderWidth = 1.5
            } else {
                view.backgroundColor = (index == currentIndex) ? .white : unfilledColor
                view.layer.borderWidth = 0
                view.layer.borderColor = UIColor.clear.cgColor
            }
        }
        
        // 🔥 UPDATE DONE BUTTON TITLE (IMPORTANT PART)
        if currentIndex == displayQuestions.count - 1 {
//            doneButton.setTitle( "Submit".localized(LocalizationService.shared.language),
//                for: .normal
//            )
            doneButtonLabel.text = "Submit".localized(LocalizationService.shared.language)
        } else {
//            doneButton.setTitle(
//                "Next".localized(LocalizationService.shared.language),
//                for: .normal
//            )
            doneButtonLabel.text = "Next".localized(LocalizationService.shared.language)
        }
        
        // Scroll to current question indicator
        scrollToCurrentQuestion()
    }

    // MARK: - Scroll View Management
    private func scrollToCurrentQuestion() {
        guard currentIndex < answerViews.count else { return }
        
        let currentAnswerView = answerViews[currentIndex]
        guard let scrollView = answerAllViewscrollView else { return }
        
        // Calculate the position to scroll to
        let viewFrame = currentAnswerView.frame
        let scrollViewFrame = scrollView.frame
        
        // Calculate the offset needed to center the current answer view
        let targetOffsetX = viewFrame.midX - scrollViewFrame.width / 2
        
        // Ensure the offset is within valid bounds
        let maxOffsetX = scrollView.contentSize.width - scrollViewFrame.width
        let minOffsetX: CGFloat = 0
        let clampedOffsetX = max(minOffsetX, min(targetOffsetX, maxOffsetX))
        
        // Animate the scroll
        UIView.animate(withDuration: 0.3) {
            scrollView.contentOffset = CGPoint(x: clampedOffsetX, y: 0)
        }
    }
    
    // MARK: - Option Selection
    @IBAction func optionButtonTapped(_ sender: UIButton) {
        // Deselect previous
        if let prev = selectedOptionButton, prev != sender {
            prev.layer.borderColor = UIColor.clear.cgColor
            prev.layer.borderWidth = 1.0
        }
        // Select this
        selectedOptionButton = sender
        sender.layer.borderWidth = selectedBorderWidth
        sender.layer.borderColor = UIColor.white.cgColor // show selection as white border until checking
    }
    
    // Connect all option buttons to this action in Interface Builder
    @IBAction func optionAAction(_ sender: UIButton) { optionButtonTapped(sender) }
    @IBAction func optionBAction(_ sender: UIButton) { optionButtonTapped(sender) }
    @IBAction func optionCAction(_ sender: UIButton) { optionButtonTapped(sender) }
    @IBAction func optionDAction(_ sender: UIButton) { optionButtonTapped(sender) }
    
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    // MARK: - Done Button Action
    @IBAction func doneBurronAction(_ sender: UIButton) {
        guard displayQuestions.indices.contains(currentIndex) else { return }
        let currentQuestion = displayQuestions[currentIndex]
        
        // if no option selected, do nothing or show small toast/alert
        guard let selectedBtn = selectedOptionButton,
              let selectedTitle = selectedBtn.title(for: .normal) else {
            // maybe show a quick alert
            let alert = UIAlertController(title: nil, message: "Please select an option".localized(LocalizationService.shared.language), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(LocalizationService.shared.language), style: .default))
            present(alert, animated: true)
            return
        }
        
        // Check correctness
        let correctAnswer = currentQuestion.correct
        let isCorrect = normalize(selectedTitle) == normalize(correctAnswer)
        let currentAnswerView = answerViews[currentIndex]
        
        // Store the question state
        questionStates[currentIndex] = (isCorrect: isCorrect, selectedOption: selectedTitle)
        
        if isCorrect {
            correctCount += 1
            // color answer view green
            animateAnswerView(currentAnswerView, color: .systemGreen)
            // selected button border green
            selectedBtn.layer.borderColor = UIColor.systemGreen.cgColor
            selectedBtn.layer.borderWidth = selectedBorderWidth
        } else {
            wrongCount += 1
            animateAnswerView(currentAnswerView, color: .systemRed)
            selectedBtn.layer.borderColor = UIColor.systemRed.cgColor
            selectedBtn.layer.borderWidth = selectedBorderWidth
            // Optionally highlight correct option with green border
            highlightCorrectOption(correctAnswer: correctAnswer)
        }
        
        // After short delay, go to next question or show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            // clear selection for next question
            self.selectedOptionButton = nil
            
            if self.currentIndex < (self.displayQuestions.count - 1) {
                self.currentIndex += 1
                self.showCurrentQuestion()
            } else {
                // finished all questions -> go to results
                self.moveToResultScreen()
            }
        }
    }
    
    private func highlightCorrectOption(correctAnswer: String) {
        let correctNormalized = normalize(correctAnswer)
        let buttons = [optionAButton, optionBButton, optionCButton, optionDButton]
        for btn in buttons {
            if let title = btn?.title(for: .normal), normalize(title) == correctNormalized {
                btn?.layer.borderColor = UIColor.systemGreen.cgColor
                btn?.layer.borderWidth = selectedBorderWidth
            }
        }
    }
    
    private func animateAnswerView(_ view: UIView, color: UIColor) {
        view.layer.borderWidth = 1.5
        view.layer.borderColor = color.cgColor
        UIView.animate(withDuration: 0.25) {
            view.backgroundColor = color
        }
    }
    
    private func normalize(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func moveToResultScreen() {
        // Create custom alert view
        let alertView = UIView()
        alertView.backgroundColor = UIColor(hex: "#1A1A1A") // Dark background
        alertView.layer.cornerRadius = 20
        alertView.clipsToBounds = true
        
        // Add shadow for depth
        alertView.layer.shadowColor = UIColor.black.cgColor
        alertView.layer.shadowOffset = CGSize(width: 0, height: 4)
        alertView.layer.shadowRadius = 10
        alertView.layer.shadowOpacity = 0.3
        
        // Congratulation Label
        let congratsLabel = UILabel()
        congratsLabel.text = "Congrats!".localized(LocalizationService.shared.language)
        congratsLabel.font = UIFont.boldSystemFont(ofSize: 28)
        congratsLabel.textColor = .white
        congratsLabel.textAlignment = .center
        
        // Subtitle Label
        let subtitleLabel = UILabel()
        subtitleLabel.text = "You've successfully completed the quiz!".localized(LocalizationService.shared.language)
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = UIColor(hex: "#CCCCCC")
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        // Check Score Label
        let checkScoreLabel = UILabel()
        checkScoreLabel.text = "Check Your Score Now!".localized(LocalizationService.shared.language)
        checkScoreLabel.font = UIFont.boldSystemFont(ofSize: 18)
        checkScoreLabel.textColor = UIColor(hex: "#4CD964") // Green color
        checkScoreLabel.textAlignment = .center
        
        // Right Answers View
        let rightAnswersView = createScoreView(
            title: "Right Answers:".localized(LocalizationService.shared.language),
            count: "\(correctCount)",
            color: UIColor(hex: "#4CD964") ?? .green
        )
        
        // Wrong Answers View
        let wrongAnswersView = createScoreView(
            title: "Wrong Answers:".localized(LocalizationService.shared.language),
            count: "\(wrongCount)",
            color: UIColor(hex: "#FF3B30") ?? .red
        )
        
        // Complete Label
        let completeLabel = UILabel()
        completeLabel.text = "Complete".localized(LocalizationService.shared.language)
        completeLabel.font = UIFont.boldSystemFont(ofSize: 20)
        completeLabel.textColor = .white
        completeLabel.textAlignment = .center
        
        // Done Button
        let doneButton = UIButton(type: .system)
//        doneButton.setTitle("Done".localized(LocalizationService.shared.language), for: .normal)
        doneButtonLabel.text = "Done".localized(LocalizationService.shared.language)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor(hex: "#007AFF") // Blue color
        doneButton.layer.cornerRadius = 12
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        // Add to alert view
        alertView.addSubview(congratsLabel)
        alertView.addSubview(subtitleLabel)
        alertView.addSubview(checkScoreLabel)
        alertView.addSubview(rightAnswersView)
        alertView.addSubview(wrongAnswersView)
        alertView.addSubview(completeLabel)
        alertView.addSubview(doneButton)
        
        // Create container view for blur effect
        let containerView = UIView(frame: view.bounds)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Add alert view to container FIRST
        containerView.addSubview(alertView)
        
        // Add container to current view controller
        view.addSubview(containerView)
        
        // Now setup constraints
        alertView.translatesAutoresizingMaskIntoConstraints = false
        congratsLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        rightAnswersView.translatesAutoresizingMaskIntoConstraints = false
        wrongAnswersView.translatesAutoresizingMaskIntoConstraints = false
        completeLabel.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Alert view constraints - CENTER IT
            alertView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: 320),
            alertView.heightAnchor.constraint(equalToConstant: 440),
            
            // Congrats label constraints
            congratsLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 30),
            congratsLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            congratsLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            // Subtitle label constraints
            subtitleLabel.topAnchor.constraint(equalTo: congratsLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            // Check score label constraints
            checkScoreLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 25),
            checkScoreLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            checkScoreLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            // Right answers view constraints
            rightAnswersView.topAnchor.constraint(equalTo: checkScoreLabel.bottomAnchor, constant: 25),
            rightAnswersView.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            rightAnswersView.widthAnchor.constraint(equalToConstant: 200),
            rightAnswersView.heightAnchor.constraint(equalToConstant: 80),
            
            // Wrong answers view constraints
            wrongAnswersView.topAnchor.constraint(equalTo: rightAnswersView.bottomAnchor, constant: 20),
            wrongAnswersView.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            wrongAnswersView.widthAnchor.constraint(equalToConstant: 200),
            wrongAnswersView.heightAnchor.constraint(equalToConstant: 80),
            
            // Complete label constraints
            completeLabel.topAnchor.constraint(equalTo: wrongAnswersView.bottomAnchor, constant: 25),
            completeLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 20),
            completeLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -20),
            
            // Done button constraints
            doneButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -20),
            doneButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 120),
            doneButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Animation
        containerView.alpha = 0
        alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
            alertView.transform = .identity
        }
    }

    private func createScoreView(title: String, count: String, color: UIColor) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(hex: "#2C2C2E")
        containerView.layer.cornerRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor(hex: "#CCCCCC")
        titleLabel.textAlignment = .center
        
        let countLabel = UILabel()
        countLabel.text = count
        countLabel.font = UIFont.boldSystemFont(ofSize: 32)
        countLabel.textColor = color
        countLabel.textAlignment = .center
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(countLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            countLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }

    @objc private func doneButtonTapped() {
        // Find and remove the alert container
        if let containerView = view.subviews.first(where: { $0.backgroundColor == UIColor.black.withAlphaComponent(0.6) }) {
            UIView.animate(withDuration: 0.2, animations: {
                containerView.alpha = 0
            }) { _ in
                containerView.removeFromSuperview()
                // Navigate to root view controller
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

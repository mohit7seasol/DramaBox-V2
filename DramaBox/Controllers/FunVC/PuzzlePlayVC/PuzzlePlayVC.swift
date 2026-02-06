//
//  PuzzlePlayVC.swift
//  DramaBox
//
//  Created by DREAMWORLD on 21/01/26.
//

import UIKit
import GoogleMobileAds

struct Word {
    let text: String
    var found: Bool = false
    let color: UIColor
}

struct Puzzle {
    var grid: [[Character]]
    var words: [Word]
}
class PuzzlePlayVC: UIViewController {
    @IBOutlet weak var movielbl1: UILabel!
    @IBOutlet weak var movielbl2: UILabel!
    @IBOutlet weak var movielbl3: UILabel!
    @IBOutlet weak var movielbl4: UILabel!
    @IBOutlet weak var movielbl5: UILabel!
    @IBOutlet weak var puzzleMainView: UIView!
    @IBOutlet weak var bannerAddView: UIView!
    @IBOutlet weak var addHeightConstant: NSLayoutConstraint!
    private var puzzle: Puzzle!
    private var collectionView: UICollectionView!
    private var wordLabels: [UILabel] = []
    
    let movieList = [
        // Original international movies converted to Bollywood names
        "ANKAHEE",   // (Inception → Unspoken)
        "AWAATAR",   // (Avatar → Incarnation)
        "BARAFI",    // (Frozen → Icy)
        "DOOBTA",    // (Titanic → Sinking)
        "PAGAL",     // (Joker → Madman)
        
        "SHOORVIR",  // (Gladiator → Warrior)
        "JAAL",      // (Matrix → Net/Trap)
        "PREM",      // (Coco → Love)
        "RET",       // (Dune → Sand)
        "UDAAN",     // (Up → Flight)
        
        // Hollywood converted
        "JUNGLE",    // (Jumanji)
        "SHISHA",    // (Glass)
        "GUPT",      // (Tenet → Secret)
        "YAAD",      // (Memento → Memory)
        "JUA",       // (Casino → Gambling)
        
        "PARAYA",    // (Alien → Stranger)
        "AASMAN",    // (Skyfall → Sky)
        "KRIT",      // (Fury → Wrath)
        "HASYA",     // (Joker → Comedy)
        "RAJ",       // (Kingsman → King)
        
        // Bollywood (shortened versions)
        "DANGAL",    // Wrestling
        "PEKAY",     // PK
        "BAJIRAO",   // Bajirao Mastani
        "LAGAAN",    // Land Tax
        "RAAZ",      // Secret
        "GUNDA",     // Gangs → Goon
        "ZINDAGI",   // Life
        "BACHEY"     // Chhichhore → Children
    ]
    
    private var selectedIndexes: [(row: Int, col: Int)] = []
    private var foundCellColors: [IndexPath: UIColor] = [:]
    private var gridSize = 10
    private let numberOfWords = 5
    private var gameOver = false
    
    private let googleBannerAds = GoogleBannerAds()
    private var bannerView: BannerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Generate Puzzle
        let selectedWords = Array(movieList.shuffled().prefix(numberOfWords))
        puzzle = generatePuzzle(with: selectedWords)
        
        setupCollectionView()
        setupWordLabels(words: selectedWords)
        
        puzzleMainView.heightAnchor.constraint(equalTo: collectionView.heightAnchor, constant: 20).isActive = true
        puzzleMainView.layer.cornerRadius = 12
        puzzleMainView.layer.borderWidth = 1
        puzzleMainView.layer.borderColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        subscribeBannerAd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetPuzzle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    func subscribeBannerAd() {

        if Subscribe.get() {
            addHeightConstant.constant = 0
            bannerAddView.isHidden = true
            return
        }

        // Create BannerView ONLY ONCE
        if bannerView == nil {
            let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(
                width: UIScreen.main.bounds.width
            ))

            banner.translatesAutoresizingMaskIntoConstraints = false
            bannerAddView.addSubview(banner)

            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: bannerAddView.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: bannerAddView.trailingAnchor),
                banner.topAnchor.constraint(equalTo: bannerAddView.topAnchor),
                banner.bottomAnchor.constraint(equalTo: bannerAddView.bottomAnchor)
            ])

            bannerView = banner
        }

        bannerAddView.isHidden = false
        addHeightConstant.constant = 50   // Standard banner height

        // ✅ THIS IS THE KEY FIX
        googleBannerAds.loadAds(vc: self, view: bannerView!)
    }
    private func resetPuzzle() {
        gameOver = false
        foundCellColors.removeAll()
        selectedIndexes.removeAll()
        
        // Pick new words and regenerate puzzle
        let selectedWords = Array(movieList.shuffled().prefix(numberOfWords))
        puzzle = generatePuzzle(with: selectedWords)
        
        // Reset word labels
        setupWordLabels(words: selectedWords)
        collectionView.reloadData()
    }
    
    // MARK: - Puzzle Generation
    
    private func generatePuzzle(with words: [String]) -> Puzzle {
        var grid = Array(repeating: Array(repeating: Character(" "), count: gridSize), count: gridSize)
        
        for word in words {
            placeWord(word, in: &grid)
        }
        
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                if grid[i][j] == " " {
                    grid[i][j] = letters.randomElement()!
                }
            }
        }
        
        let wordColors: [UIColor] = [#colorLiteral(red: 0.4117647059, green: 0.5882352941, blue: 0.9450980392, alpha: 1), #colorLiteral(red: 0.8039215686, green: 0.368627451, blue: 0.7725490196, alpha: 1), #colorLiteral(red: 0.9960784314, green: 0.5607843137, blue: 0.1764705882, alpha: 1), #colorLiteral(red: 0.2745098039, green: 0.6784313725, blue: 0.5176470588, alpha: 1), #colorLiteral(red: 0.5490196078, green: 0.2156862745, blue: 0.9568627451, alpha: 1)]
        let puzzleWords = words.enumerated().map { index, wordText in
            Word(text: wordText, color: wordColors[index % wordColors.count])
        }
        
        return Puzzle(grid: grid, words: puzzleWords)
    }
    
    private func placeWord(_ word: String, in grid: inout [[Character]]) {
        let directions = [(1,0), (-1,0), (0,1), (0,-1)]
        
        while true {
            let row = Int.random(in: 0..<gridSize)
            let col = Int.random(in: 0..<gridSize)
            let dir = directions.randomElement()!
            
            var canPlace = true
            var positions: [(Int, Int)] = []
            
            for (i, char) in word.enumerated() {
                let r = row + dir.0 * i
                let c = col + dir.1 * i
                if r < 0 || r >= gridSize || c < 0 || c >= gridSize { canPlace = false; break }
                if grid[r][c] != " " && grid[r][c] != char {
                    canPlace = false
                    break
                }
                positions.append((r, c))
            }
            
            if canPlace {
                var overlapWithOtherWord = false
                for (i, char) in word.enumerated() {
                    let r = row + dir.0 * i
                    let c = col + dir.1 * i
                    if i == 0 && grid[r][c] != " " && grid[r][c] == char {
                        continue
                    }
                    if i > 0 && grid[r][c] != " " && grid[r][c] != char {
                        overlapWithOtherWord = true
                        break
                    }
                }
                if !overlapWithOtherWord {
                    for (i, char) in word.enumerated() {
                        let pos = positions[i]
                        grid[pos.0][pos.1] = char
                    }
                    return
                }
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 4
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PuzzleCell2.self, forCellWithReuseIdentifier: "cell")
        
        puzzleMainView.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: puzzleMainView.topAnchor, constant: 15),
            collectionView.leadingAnchor.constraint(equalTo: puzzleMainView.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: puzzleMainView.trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: puzzleMainView.bottomAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor)
        ])
        
        puzzleMainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            puzzleMainView.heightAnchor.constraint(equalTo: collectionView.heightAnchor),
        ])
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        collectionView.addGestureRecognizer(pan)
    }
    
    private func setupWordLabels(words: [String]) {
        // Set movie labels with primary color #777777
        let movieLabels = [movielbl1, movielbl2, movielbl3, movielbl4, movielbl5]
        let primaryColor = UIColor(hex: "#777777") ?? .gray
        
        for (index, label) in movieLabels.enumerated() {
            if index < words.count {
                label?.text = "\(index + 1). \(words[index])"
                label?.textColor = primaryColor
                label?.font = UIFont.boldSystemFont(ofSize: 16)
                label?.textAlignment = .left
            } else {
                label?.text = ""
            }
        }
        
        // Store references for updating colors later
        wordLabels = movieLabels.compactMap { $0 }
    }
    @IBAction func closeButtonTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
extension PuzzlePlayVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int { gridSize }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { gridSize }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PuzzleCell2
        cell.letterLabel.text = String(puzzle.grid[indexPath.section][indexPath.item])
        
        let pos = (row: indexPath.section, col: indexPath.item)
        var cellColor: UIColor
        if selectedIndexes.contains(where: { $0.row == pos.row && $0.col == pos.col }) {
            cellColor = #colorLiteral(red: 0.3607843137, green: 0.0862745098, blue: 0.9215686275, alpha: 1)
        } else if let foundColor = foundCellColors[indexPath] {
            cellColor = foundColor
        } else {
            cellColor = #colorLiteral(red: 0.1137254902, green: 0.07450980392, blue: 0.1411764706, alpha: 1)
        }
        
        cell.applyCornerStyle(color: cellColor)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 4
        let totalSpacing = CGFloat(gridSize - 1) * spacing
        let width = collectionView.bounds.width
        let size = (width - totalSpacing) / CGFloat(gridSize)
        return CGSize(width: size, height: size)
    }
    
    // MARK: - Word Selection Logic
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !gameOver else { return }
        let location = gesture.location(in: collectionView)
        
        if let indexPath = collectionView.indexPathForItem(at: location) {
            let pos = (row: indexPath.section, col: indexPath.item)
            if selectedIndexes.isEmpty || isValidNextPosition(pos) {
                if !selectedIndexes.contains(where: { $0.row == pos.row && $0.col == pos.col }) {
                    selectedIndexes.append(pos)
                    collectionView.reloadData()
                }
            }
        }
        
        if gesture.state == .ended {
            let word = selectedIndexes.map { String(puzzle.grid[$0.row][$0.col]) }.joined()
            let reversed = String(word.reversed())
            
            if let index = puzzle.words.firstIndex(where: { ($0.text == word || $0.text == reversed) && !$0.found }) {
                puzzle.words[index].found = true
                
                // Update movie label color to white when correct word is found
                wordLabels[index].textColor = .white
                
                for pos in selectedIndexes {
                    let indexPath = IndexPath(item: pos.col, section: pos.row)
                    foundCellColors[indexPath] = puzzle.words[index].color
                }
                selectedIndexes.removeAll()
                collectionView.reloadData()
                checkGameOver()
            } else {
                selectedIndexes.removeAll()
                collectionView.reloadData()
            }
        }
    }
    
    private func isValidNextPosition(_ pos: (row: Int, col: Int)) -> Bool {
        guard let first = selectedIndexes.first, let last = selectedIndexes.last else { return true }
        
        let isHorizontal = selectedIndexes.count >= 2 ? selectedIndexes[1].row == first.row : (selectedIndexes.last?.row == pos.row)
        let isVertical = selectedIndexes.count >= 2 ? selectedIndexes[1].col == first.col : (selectedIndexes.last?.col == pos.col)
        
        if isHorizontal && selectedIndexes.allSatisfy({ $0.row == first.row }) {
            return pos.row == first.row && abs(pos.col - last.col) == 1
        } else if isVertical && selectedIndexes.allSatisfy({ $0.col == first.col }) {
            return pos.col == first.col && abs(pos.row - last.row) == 1
        }
        return false
    }
    
    private func checkGameOver() {
        if puzzle.words.allSatisfy({ $0.found }) {
            gameOver = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showCongratulationsAlert()
            }
        }
    }
    // MARK: - Congratulations Alert
    private func showCongratulationsAlert() {
        let alert = UIAlertController(
            title: "🎉 Congratulations!",
            message: "You Win!",
            preferredStyle: .alert
        )
        
        // Restart Button
        let restartAction = UIAlertAction(title: "Restart", style: .default) { [weak self] _ in
            self?.resetPuzzle()
        }
        
        // Finish Button
        let finishAction = UIAlertAction(title: "Finish", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        alert.addAction(restartAction)
        alert.addAction(finishAction)
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Custom Cell (Same as in PuzzleVC)
class PuzzleCell2: UICollectionViewCell {
    let letterLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.boldSystemFont(ofSize: 18)
        lbl.textAlignment = .center
        lbl.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(letterLabel)
        NSLayoutConstraint.activate([
            letterLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            letterLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyCornerStyle(color: UIColor) {
        contentView.backgroundColor = color
    }
}

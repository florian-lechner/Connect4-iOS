//
//  GameVC.swift
//  Connect4
//
//  Created by Florian Lechner on 05.12.2023.
//

import UIKit
import Alpha0C4
import CoreData

class GameVC: UIViewController {
    private var gameSession = GameSession()
    let columnWidth = UIScreen.main.bounds.width / CGFloat(7)
    private var botColor: GameSession.DiscColor = Bool.random() ? .red : .yellow
    private var userTurn: Bool = false
    var isBotFirst: Bool?
    private var botUIColor: UIColor {
        return botColor == .red ? .red : .systemYellow
    }
    private var playerUIColor: UIColor {
        return botColor == .red ? .systemYellow : .red
    }
    
    
    // Disc Drop Animation
    lazy var discBehavior = DiscBehavior()
    private lazy var animator: UIDynamicAnimator? = {
        guard let gameView = self.gameView else { return nil }
        let animator = UIDynamicAnimator(referenceView: gameView)
        animator.addBehavior(self.discBehavior)
        return animator
    }()
    
    // Outlets
    @IBOutlet var gameView: UIView!
    @IBOutlet weak var connect4View: Connect4BoardView!
    @IBOutlet weak var BotColor: UILabel!
    @IBOutlet weak var PlayerColor: UILabel!
    @IBOutlet weak var gameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator?.delegate = self
    }
    
    
    @IBAction func touchOnBoard(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: gameView)
        let tappedColumn = Int(touchLocation.x / columnWidth) + 1
        if userTurn {
            print("Column tapped: \(tappedColumn)")
            dropDiscInColumn(column: tappedColumn)
        }
        if BotColor.text == "-" {
            newGameSession()
        }
    }
    
    @IBAction func restartSwipe(_ sender: Any) {
        restart()
    }
    
    func restart() {
        Task {
            clearAllDiscs()
            userTurn = false
            gameLabel.text = "New Game"
            gameLabel.textColor = .black
            userTurn = false
            BotColor.text = "-"
            PlayerColor.text = "-"
            
            // Start new game after short delay
            try await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                newGameSession()
            }
        }
    }
    
    @IBOutlet weak var replayButton: UIButton!
    
    @IBAction func replayButtonTab(_ sender: Any) {
        fetchAndReplayMoves()
    }
        
    // MARK: - Start game session
    private func newGameSession() {
        self.discBehavior.addBottomBoundary(using: connect4View)
        
        replayButton.isEnabled = false
        showStartChoiceAlert()
        
        // Print game layout
        print("CONNECT4 \(gameSession.boardLayout.rows) rows by \(gameSession.boardLayout.columns) columns")
    }
    
    private func startNewGame(isBotFirst: Bool) {
        self.isBotFirst = isBotFirst
        
        // Random bot parameters
        botColor = Bool.random() ? .red : .yellow
        BotColor.text = botColor == .red ? "red" : "yellow"
        PlayerColor.text = botColor == .red ? "yellow" : "red"
        
        // Start game, resuming with some discs
        // set initialMoves to [(Int, Int)]() to start with clear board  -> !!! save game state to resume after start
        let initialMoves =  [(Int, Int)]() 
        self.gameSession.startGame(delegate: self, botPlays: botColor, first: isBotFirst, initialPositions: initialMoves)
    }

    private func showStartChoiceAlert() {
        let alert = UIAlertController(title: "Who starts?", message: "Choose who makes the first move.", preferredStyle: .actionSheet)

        let botStartsAction = UIAlertAction(title: "Bot", style: .default) { [self] _ in
            self.startNewGame(isBotFirst: true)
        }

        let playerStartsAction = UIAlertAction(title: "Player", style: .default) { [self] _ in
            self.startNewGame(isBotFirst: false)
        }

        alert.addAction(botStartsAction)
        alert.addAction(playerStartsAction)

        present(alert, animated: true, completion: nil)
    }
    
    func clearAllDiscs() {
        // Remove collision boundaries or adjust them so discs can fall off the screen
        discBehavior.removeBoundaries()
        
        // Wait for the discs to fall off the screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Iterate over all disc views and remove them
            self.discBehavior.removeAllDiscs() 
        }
    }
    
    func dropDiscInColumn(column: Int) {
        guard gameSession.isValidMove(column) else {
            print("not a valid move")
            gameLabel.text = "Not a valid move"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.gameLabel.text = "Your turn"
            }
            return
        }
        
        print("valid move, column: \(column)")
        // Drop Disc
        gameSession.dropDisc(atColumn: column)

    }
    
    // MARK: - adjustments to finished game
    private func numberAllDiscs() {
        var discNumber = 1
        for case let disc as DiscView in gameView.subviews {
            addNumberToDisc(disc, number: discNumber)
            discNumber += 1
        }
    }
    
    private func addNumberToDisc(_ disc: DiscView, number: Int) {
        let label = UILabel(frame: disc.bounds)
        label.text = "\(number)"
        label.textAlignment = .center
        disc.addSubview(label)
    }
    
    private func highlightWinningDiscs(_ positions: [(row: Int, column: Int)]) {
        for case let disc as DiscView in gameView.subviews {
            if positions.contains(where: { $0.row == disc.row && $0.column == disc.column }) {
                disc.layer.borderColor = UIColor.green.cgColor
                disc.layer.borderWidth = 12
                disc.layer.cornerRadius = disc.diameter / 2
                disc.clipsToBounds = true
            }
        }
    }
}

extension GameVC: GameSessionDelegate {

    func didDropDisc(_ gameSession: GameSession, color: DiscColor, at location: (row: Int, column: Int), index: Int, textLog: String) {
        print("Disc dropped at: row \(location.row), column \(location.column)")
        
        let discDiameter = columnWidth
        let disc = DiscView(discColor: color, diameter: columnWidth, row: location.row, column: location.column)
        disc.layer.zPosition = -1
        
        // Adjust frame for main view of GameVC
        let xPosition = columnWidth * CGFloat(location.column - 1)
        disc.frame = CGRect(x: xPosition, y: discDiameter, width: discDiameter, height: discDiameter)
        
        // Add the disc to the main view and to the DiscBehavior
        self.gameView.insertSubview(disc, belowSubview: connect4View)
        //self.connect4View.addSubview(disc)
        self.discBehavior.addDisc(disc)
        
        
        // Save disc data to CoreData
        if let managedContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            _ = CoreDataDisc.save(positions: [(location.row, location.column)], index: index, in: managedContext)
        } else {
            print("Failed to save Disc")
        }
        
        if location.row == 6, location.column == 1, isBotFirst == true, index == 1 {
            print("error restart")
            restart()
        }
    }

    // GameSessionDelegate update for game state changes
    func stateChanged(_ gameSession: GameSession, state: SessionState, textLog: String) {
        // Handle state transition
        switch state
        {
        // Inital state
        case .cleared:
            gameLabel.text = "cleared"
            gameLabel.textColor = .black
            //print("Game state: cleared")
            
        // Player evaluating position to play
        case .busy(_):
            // Disable button while thinking
            userTurn = false
            gameLabel.text = "busy"
            gameLabel.textColor = .black
            //print("Game state: busy")
            
        // Waiting for play action
        case .idle(let color):
            print("Game state: idle with color: \(color)")
            let isUserTurn = (color != botColor)
            // Enable tap for user
            userTurn = isUserTurn
            
            if !isUserTurn {
                // Bot play
                gameLabel.text = "Bot's turn"
                gameLabel.textColor = botUIColor
                // 1s delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.gameSession.dropDisc()
                }
            } else {
                gameLabel.text = "Your turn"
                gameLabel.textColor = playerUIColor
            }
            
        // End of game, update UI with game result, start new game
        case .ended(let outcome):
            //print("Game state: ended")
            // Disable tap
            userTurn = false
            
            // Display game result
            var gameResult: String
            switch outcome {
            case botColor:
                gameResult = "Bot (\(botColor)) wins!"
                gameLabel.textColor = botUIColor
            case !botColor:
                gameResult = "User (\(!botColor)) wins!"
                gameLabel.textColor = playerUIColor
            default:
                gameResult = "Draw!"
                gameLabel.textColor = .black
            }
            gameLabel.text! = gameResult
            

        @unknown default:
            break
        }
    }
    
    // GameSessionDelegate notification of end of game
    func didEnd(_ gameSession: GameSession, color: DiscColor?, winningActions: [(row: Int, column: Int)]) {
        // Display winning disc positions
        print("Winning actions: " + winningActions.map({"\($0)"}).joined(separator: " "))
        
        // Save game session to CoreData
        if let managedContext = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
            _ = CoreDataSession.save(botPlays: botColor, first: isBotFirst!, layout: (gameSession.boardLayout.rows, gameSession.boardLayout.columns), positions: gameSession.playerPositions, winningPositions: winningActions, in: managedContext)
        } else {
            print("Failed to save Session")
        }
        
        // Highlight winning discs
        highlightWinningDiscs(winningActions)
        
        // Show numbers on discs
        numberAllDiscs()
        
        replayButton.isEnabled = true
    }
}

extension GameVC: UIDynamicAnimatorDelegate {}

// MARK: - Replay:

extension GameVC {
    func fetchAndReplayMoves() {
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        let request: NSFetchRequest<CoreDataSession> = CoreDataSession.fetchRequest()

        do {
            var delay: Double = 0
            
            let sessions = try context?.fetch(request)
            if let latestSession = sessions?.last {
                // delete discs
                self.discBehavior.removeAllDiscs()
                
                // drop discs for replay with a delay
                for disc in latestSession.discs!.array {
                    let workItem = DispatchWorkItem { [weak self] in
                        self?.dropDiscForReplay(disc as! CoreDataDisc)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
                    delay += 0.3
                }
            }
        } catch {
            print("Error fetching moves from CoreData: \(error)")
        }
    }
    


    func dropDiscForReplay(_ move: CoreDataDisc) {
        let discDiameter = columnWidth
        let color = determineColorForIndex(Int(move.index), isBotFirst: isBotFirst ?? false, botColor: botColor)
        let discView = DiscView(discColor: color, diameter: discDiameter, row: Int(move.row), column: Int(move.column))
        
        let xPosition = columnWidth * CGFloat(move.column - 1)
        let yPosition = -discDiameter // Start above the view
        discView.frame = CGRect(x: xPosition, y: yPosition, width: discDiameter, height: discDiameter)
        discView.layer.zPosition = -1
        
        
        if move.isWinnig {
            discView.layer.borderColor = UIColor.green.cgColor
            discView.layer.borderWidth = 12
            discView.layer.cornerRadius = discDiameter / 2
            discView.clipsToBounds = true
        }

        // Add number label to disc
        let label = UILabel(frame: discView.bounds)
        label.text = "\(move.index)"
        label.textAlignment = .center
        discView.addSubview(label)

        gameView.insertSubview(discView, belowSubview: connect4View)
        discBehavior.addDisc(discView)
    }

    func determineColorForIndex(_ index: Int, isBotFirst: Bool, botColor: GameSession.DiscColor) -> GameSession.DiscColor {
        let colorIndex = (index % 2 == (isBotFirst ? 1 : 0)) ? botColor : (botColor == .red ? .yellow : .red)
        return colorIndex
    }

}



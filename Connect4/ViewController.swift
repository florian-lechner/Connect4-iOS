//
//  ViewController.swift
//  Connect4
//
//  Created by Instructor on 29/09/2023.
//

import UIKit
import Alpha0C4
/*
class ViewController: UIViewController {
    // MARK: UI Outlets
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var dropDiscButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    

    // Set random bot parameters
    private var botColor: GameSession.DiscColor = Bool.random() ? .red : .yellow
    private var isBotFirst = Bool.random()
    // Game session
    private var gameSession = GameSession()

    
    // MARK: VC lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start new game session
        newGameSession()
    }

    // Start game session with random bot parameter
    private func newGameSession() {
        // Random bot parameters
        botColor = Bool.random() ? .red : .yellow
        isBotFirst = Bool.random()
        
        // Print game layout
        print("CONNECT4 \(gameSession.boardLayout.rows) rows by \(gameSession.boardLayout.columns) columns")
        
        // Start game, resuming with some discs
        // set initialMoves to [(Int, Int)]() to start with clear board  -> !!! save game state to resume after start
        let initialMoves = [(row: 1, column: 4), (row: 2, column: 4)]
        self.gameSession.startGame(delegate: self, botPlays: botColor, first: isBotFirst, initialPositions: initialMoves)
    }

    
    // MARK: - UI Action
    @IBAction func userAction(_ sender: UIButton) {
        // Drop disc in random column
        var column: Int
        repeat { column = Int.random(in: 1...gameSession.boardLayout.columns) }
        while !gameSession.isValidMove(column)
        
        // Drop disc
        gameSession.dropDisc(atColumn: column)
    }

}


// MARK: - GameSessionDelegate

extension ViewController: GameSessionDelegate
{
    // GameSessionDelegate update for game state changes
    func stateChanged(_ gameSession: GameSession, state: SessionState, textLog: String) {
        // Handle state transition
        switch state
        {
        // Inital state
        case .cleared:
            gameLabel.text = textLog
            dropDiscButton.titleLabel?.text = "Drop Disc Randomly"
            
        // Player evaluating position to play
        case .busy(_):
            // Disable button while thinking
            dropDiscButton.isEnabled = false
            
        // Waiting for play action
        case .idle(let color):
            let isUserTurn = (color != botColor)
            // Enable button for user
            dropDiscButton.isEnabled = isUserTurn
            if !isUserTurn {
                // Bot play
                gameSession.dropDisc()
            }
            
        // End of game, update UI with game result, start new game
        case .ended(let outcome):
            // Disable button
            dropDiscButton.isEnabled = false
            
            // Display game result
            var gameResult: String
            switch outcome {
            case botColor:
                gameResult = "Bot (\(botColor)) wins!"
            case !botColor:
                gameResult = "User (\(!botColor)) wins!"
            default:
                gameResult = "Draw!"
            }
            gameLabel.text! = textLog + "\n" + gameResult
            
            // Wait a while and start a new session automatically
            indicatorView.startAnimating()
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    indicatorView.stopAnimating()
                    newGameSession()
                }
            }
        @unknown default:
            break
        }
    }
    
    
    // GameSessionDelegate notifying of the result of a player action
    // textLog provides some string visualization of the game board for debug purposes
    func didDropDisc(_ gameSession: GameSession, color: DiscColor, at location: (row: Int, column: Int), index: Int, textLog: String) {
        print("\(color) drops at \(location)")
        self.gameLabel.text = textLog
    }

        
    // GameSessionDelegate notification of end of game
    func didEnd(_ gameSession: GameSession, color: DiscColor?, winningActions: [(row: Int, column: Int)]) {
        // Display winning disc positions
        print("Winning actions: " + winningActions.map({"\($0)"}).joined(separator: " "))
    }

}
*/

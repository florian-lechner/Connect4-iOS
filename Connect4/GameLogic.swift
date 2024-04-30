//
//  GameLogic.swift
//  Connect4
//
//  Created by Flo Lechner on 10.12.2023.
//

import UIKit
import Alpha0C4

class GameLogic {
    var gameSession = GameSession()
    var botColor: GameSession.DiscColor = Bool.random() ? .red : .yellow
    var isBotFirst: Bool?
    
    func startNewGame(isBotFirst: Bool) {
        // Start a new game
        self.isBotFirst = isBotFirst
        botColor = Bool.random() ? .red : .yellow
        let initialMoves = [(Int, Int)]()
        gameSession.startGame(delegate: nil, botPlays: botColor, first: isBotFirst, initialPositions: initialMoves)
    }
    
    
}

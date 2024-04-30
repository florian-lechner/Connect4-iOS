//
//  CoreDataSession.swift
//  Connect4
//
//  Created by Florian Lechner on 29.11.2023.
//

import Foundation
import CoreData
import Alpha0C4

typealias DiscColor = GameSession.DiscColor

public class CoreDataSession: NSManagedObject {
    static func save(botPlays botColor: DiscColor,
                     first botStarts: Bool,
                     layout: (rows: Int, columns: Int),
                     positions: [(row: Int, column: Int)],
                     winningPositions: [(row: Int, column: Int)] = [(Int, Int)](),
                     in moc: NSManagedObjectContext?) -> CoreDataSession?
    {
        // get entity
        guard let managedContext = moc else {return nil }
        guard let entity = NSEntityDescription.entity(forEntityName: "CoreDataSession", in: managedContext) else { return nil }
        
        // insert and confic new game session
        guard let sessionItem = NSManagedObject(entity: entity, insertInto: managedContext) as? CoreDataSession else { return nil }
        
        sessionItem.botColor = Int16(botColor.rawValue)
        sessionItem.botIsFirst = botStarts
        (sessionItem.rows, sessionItem.columns) = (Int16(layout.rows), Int16(layout.columns))
        
        // log
        var board = [[String]](repeating: [String](repeating: "' '", count: layout.columns), count: layout.rows)
        _ = positions.enumerated().map { board[layout.rows - $0.element.row][$0.element.column - 1] = "'\($0.offset < 9 ? " " : "")\($0.offset + 1)'" }
        sessionItem.log = (botStarts ? "----------------------------------------\n" : "++++++++++++++++++++++++++++++++++++++++\n") + board.map({ "|\($0.joined(separator: ", "))|" }).joined(separator: "\n") + "\n" + (botStarts ? "----------------------------------------" : "++++++++++++++++++++++++++++++++++++++++")
        
        // add discs
        guard let disc = CoreDataDisc.save(positions: positions, winningPositions: winningPositions, in: managedContext) else { return nil }
        _ = disc.map { sessionItem.addToDiscs($0) }
        
        //save
        do { try managedContext.save() }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        return sessionItem
        
    }
    
    var winningDiscs: [Int] {
        get {
            (discs?.array as! [CoreDataDisc]).filter({ $0.isWinnig }).map({ Int($0.index) })
        }
    }
    
    var winningColor: DiscColor? {
        guard winningDiscs.count >= 4 else { return nil }

        // Determine the starting color based on who started first
        let startingColor = botIsFirst ? botColor : (botColor == 0 ? 1 : 0) 
        
        // Find the color of the first winning disc based on its index
        let colorIndex = Int((winningDiscs.first! % 2 == 0) ? startingColor : (startingColor == 0 ? 1 : 0))
        return DiscColor(rawValue: colorIndex)
    }
    
    var playerWon: Bool? {
        guard winningDiscs.count >= 4 else { return nil }
        let playerHasWon = Int(winningDiscs.first!) % 2 == (botIsFirst ? 0 : 1)
        return playerHasWon
    }
}

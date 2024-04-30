//
//  CoreDataDiscs+CoreData.swift
//  Connect4
//
//  Created by Florian Lechner on 29.11.2023.
//

import Foundation
import CoreData

public class CoreDataDisc: NSManagedObject {
    static func save(positions: [(row: Int, column: Int)],
                     index offset: Int = 1,
                     winningPositions: [(row: Int, column: Int)] = [(Int, Int)](),
                     in managedContext: NSManagedObjectContext) -> [CoreDataDisc]?
    {
        guard let entity = NSEntityDescription.entity(forEntityName: "CoreDataDisc", in: managedContext) else { return nil }
        
        var discs = [CoreDataDisc]()
        for (index, position) in positions.enumerated() {
            //insert and config new disc item
            guard let discItem = NSManagedObject(entity: entity, insertInto: managedContext) as? CoreDataDisc else { return nil }
            discItem.row = Int16(position.row)
            discItem.column = Int16(position.column)
            discItem.index = Int16(index + offset)
            discItem.isWinnig = winningPositions.contains(where: { $0.row == position.row && $0.column == position.column })
            discs.append(discItem)
        }
        
        //save
        do { try managedContext.save() }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        return discs
    }
}

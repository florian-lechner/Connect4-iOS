//
//  HistoryTVC.swift
//  Connect4
//
//  Created by Florian Lechner on 04.12.2023.
//

import UIKit
import CoreData
import Alpha0C4

class HistoryTVC: UITableViewController {
    
    var gameSessions: [CoreDataSession] = []
    
    // Outlets
    @IBOutlet weak var historyTable: UITableView!
    
    @IBAction func clearAllButton(_ sender: Any) {
        let alert = UIAlertController(title: "Clear History", message: "Are you sure you want to clear all game history? This action cannot be undone.", preferredStyle: .alert)

        let clearAction = UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.deleteAllGameSessions()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(clearAction)
        alert.addAction(cancelAction)

        present(alert, animated: true, completion: nil)
    }
    
    private func deleteAllGameSessions() {
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CoreDataSession.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context?.execute(deleteRequest)
            gameSessions.removeAll()
            historyTable.reloadData()
        } catch {
            print("Error deleting all game sessions: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        historyTable.delegate = self
        historyTable.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchGameSessions()
    }
    
    // Fetch game sessions from CoreData
    func fetchGameSessions() {
        let request: NSFetchRequest<CoreDataSession> = CoreDataSession.fetchRequest()

        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        do {
            if let sessions = try context?.fetch(request) as? [CoreDataSession] {
                gameSessions = sessions
                print("Fetched \(gameSessions.count) game sessions.")
            } else {
                print("No game sessions found.")
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error fetching game sessions: \(error)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameSessions.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as? HistoryTableViewCell else {
            fatalError("Unable to dequeue HistoryTableViewCell")
        }

        let session = gameSessions[indexPath.row]
        cell.configure(with: session)
        return cell
    }
    
    // Enable delete
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the session to delete
            let sessionToDelete = gameSessions[indexPath.row]

            // Remove from Core Data
            if let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext {
                context.delete(sessionToDelete)
                do {
                    try context.save()
                } catch {
                    print("Error saving context after deletion: \(error)")
                }
            }

            // Remove from data source array
            gameSessions.remove(at: indexPath.row)

            // Delete the row from the table view
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
}

// MARK: - HistoryTableViewCell

class HistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var boardView: Connect4BoardView!
    @IBOutlet weak var starterLabel: UILabel!
    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var discBoardView: UIView!
    
    func configure(with session: CoreDataSession) {
        
        // Add Labels and add color to text label
        starterLabel.text = session.botIsFirst ? "Bot Started" : "Player Started"
        starterLabel.textColor = session.botIsFirst ? colorForBotColor(session.botColor) : colorForBotColor(session.botColor == 0 ? 1 : 0)
        winnerLabel.text = "Winner: \(session.playerWon == nil ? "Draw" : (session.playerWon! ? "Player" : "Bot"))"
        winnerLabel.textColor = session.playerWon == nil ? .black : (session.playerWon! ? colorForBotColor(session.botColor == 0 ? 1 : 0) : colorForBotColor(session.botColor))
        
        // Delay to load discs after boardView for correct positioning
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.configureBoardView(with: session)
        }
        
    }
    
    func configureBoardView(with session: CoreDataSession) {
        // Clear any existing disc views
        discBoardView.subviews.forEach { if $0 is DiscView { $0.removeFromSuperview() } }
        
        guard let discs = session.discs?.array as? [CoreDataDisc] else { return }
        let columnWidth = boardView.bounds.width / 7

        for disc in discs {
            let discColor: GameSession.DiscColor = determineColor(for: disc, isBotFirst: session.botIsFirst, botColorValue: GameSession.DiscColor(rawValue: Int(session.botColor))!)
            let discView = DiscView(discColor: discColor, diameter: columnWidth, row: Int(disc.row), column: Int(disc.column))
            discView.layer.zPosition = -1
            
            // Calculate position and frame for discView
            let xPosition = columnWidth * CGFloat(disc.column - 1)
            let yPosition = discBoardView.bounds.height - CGFloat(disc.row) * columnWidth
            discView.frame = CGRect(x: xPosition, y: yPosition, width: columnWidth, height: columnWidth)
            
            // Add border to winning discs
            if disc.isWinnig {
                discView.layer.borderColor = UIColor.green.cgColor
                discView.layer.borderWidth = columnWidth / 4
                discView.layer.cornerRadius = columnWidth / 2
                discView.clipsToBounds = true
            }
            
            // Add Number
            let label = UILabel(frame: discView.bounds)
            label.text = "\(disc.index)"
            label.font = .systemFont(ofSize: 10)
            label.textAlignment = .center
            discView.addSubview(label)
            
            discBoardView.addSubview(discView)
        }
    }

    private func determineColor(for disc: CoreDataDisc, isBotFirst: Bool, botColorValue: GameSession.DiscColor) -> GameSession.DiscColor {
        // Alternate color based on index and who started first
        let color = (Int(disc.index) % 2 == (isBotFirst ? 1 : 0)) ? botColorValue : !botColorValue
        return color
    }
                                                                    
    func colorForBotColor(_ botColorValue: Int16) -> UIColor {
        return GameSession.DiscColor(rawValue: Int(botColorValue)) == .red ? UIColor.red : UIColor.systemYellow
    }
}

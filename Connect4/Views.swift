//
//  Views.swift
//  Connect4
//
//  Created by Florian Lechner on 08.12.2023.
//

import UIKit
import Alpha0C4

class Connect4BoardView: UIView {

    // Constants for the board's dimensions and appearance
    private let columns = GameConstants.columns
    private let rows = GameConstants.rows
    private let boardColor: UIColor = .blue

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let spacing = rect.width / CGFloat(columns) * 0.2
        let fieldDiameter = (rect.width - (spacing * (CGFloat(columns) + 1))) / CGFloat(columns)
        
        // Set up the background color for the board
        boardColor.setFill()
        UIRectFill(rect)

        
        // Create a path for the entire board
        let boardPath = UIBezierPath(rect: rect)

        // Draw the circular cutouts in the path
        for row in 0..<rows {
            for column in 0..<columns {
                let x = (CGFloat(column) * fieldDiameter) + (spacing * (CGFloat(column) + 1))
                let y = (CGFloat(row) * fieldDiameter) + (spacing * (CGFloat(row) + 1))
                let circleRect = CGRect(x: x, y: y, width: fieldDiameter, height: fieldDiameter)
                boardPath.append(UIBezierPath(ovalIn: circleRect))
            }
        }

        // Create a shape layer and use it as a mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = boardPath.cgPath
        maskLayer.fillRule = .evenOdd

        // Apply the mask to the view
        self.layer.mask = maskLayer
        self.layer.backgroundColor = boardColor.cgColor
    
    }
}


struct GameConstants {
    static let columns = 7
    static let rows = 6
}

// MARK: - Disk View

class DiscView: UIView {
    var discColor: UIColor
    var diameter: CGFloat
    var column: Int
    var row: Int
    
    
    init(discColor: GameSession.DiscColor, diameter: CGFloat, row: Int, column: Int) {
        self.discColor = discColor == .red ? .red : .yellow
        self.diameter = diameter
        self.column = column
        self.row = row
        super.init(frame: .zero) // Initialize with zero frame
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        // Draw the disc
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let discRect = CGRect(x: center.x - diameter/2, y: center.y - diameter/2, width: diameter, height: diameter)
        let path = UIBezierPath(ovalIn: discRect)
        discColor.setFill()
        path.fill()
    }
}


// MARK: - Disk Behavior

class DiscBehavior: UIDynamicBehavior {
    private var gravity = UIGravityBehavior()
    private var collider: UICollisionBehavior = {
        let collider = UICollisionBehavior()
        collider.translatesReferenceBoundsIntoBoundary = false
        return collider
    }()
    private var itemBehavior: UIDynamicItemBehavior = {
        let itemBehavior = UIDynamicItemBehavior()
        itemBehavior.allowsRotation = false
        itemBehavior.elasticity = 0.5
        return itemBehavior
    }()
    
    override init() {
        super.init()
        addChildBehavior(gravity)
        addChildBehavior(collider)
        addChildBehavior(itemBehavior)
    }
    
    func addDisc(_ disc: UIView) {
        dynamicAnimator?.referenceView?.addSubview(disc)
        gravity.addItem(disc)
        collider.addItem(disc)
        itemBehavior.addItem(disc)
    }
    
    func removeAllDiscs() {
        for item in gravity.items {
            removeDisc(item as! UIView)
        }
    }
    
    func removeDisc(_ disc: UIView) {
        gravity.removeItem(disc)
        collider.removeItem(disc)
        itemBehavior.removeItem(disc)
        disc.removeFromSuperview()
    }
    
    func addBottomBoundary(using boardView: UIView) {
        guard let referenceView = dynamicAnimator?.referenceView else { return }
        let convertedBoundaryStart = referenceView.convert(CGPoint(x: boardView.frame.minX, y: boardView.frame.maxY), from: boardView.superview)
        let convertedBoundaryEnd = referenceView.convert(CGPoint(x: boardView.frame.maxX, y: boardView.frame.maxY), from: boardView.superview)

        collider.addBoundary(withIdentifier: "bottomBoundary" as NSCopying, from: convertedBoundaryStart, to: convertedBoundaryEnd)
    }
    
    func removeBoundaries() {
        collider.removeAllBoundaries()
    }
}


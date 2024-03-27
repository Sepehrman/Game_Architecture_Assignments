//
//  Overlay.swift
//  Assignment3
//
//  Created by Nathan Dong on 2024-03-14.
//

import SpriteKit
import SwiftUI

class OverlayScene: SKScene {
    var score: SKLabelNode
    var remainingBricks: SKLabelNode
//    let map: SKShapeNode
    
    override init(size: CGSize) {
        let mapWidth = 200.0
        let mapHeight = 200.0
        

        score = SKLabelNode(text: "Score: 0")
        score.name = "score"
        score.fontColor = .white
        score.fontSize = 24
        score.fontName = "Robota"
        score.position = CGPoint(x: size.width - 80, y: size.height - 210)
        
        remainingBricks = SKLabelNode(text: "Remaining\nBricks: 20")
//        remainingBricks.numberOfLines = 2
        remainingBricks.name = "remainingBricks"
        remainingBricks.fontColor = .white
        remainingBricks.fontSize = 24
        remainingBricks.fontName = "Robota"
        remainingBricks.position = CGPoint(x: 130, y: size.height - 210)
        
        super.init(size: size)
        
        self.backgroundColor = .clear
        self.addChild(score)
        self.addChild(remainingBricks)
        scene!.scaleMode = .aspectFill
        
        print("MapOverlayScene initialized")
    }
    
    
    func helloWorld() {
        print("Hey from OverlayScene")
    }
    
    func setScore(newScore: Int) {
//        print(newScore)
        score.text = "Score: " + String(newScore)
    }
    
    func setRemainingBricks(newRemainingBricks: Int) {
//        print(newRemainingBricks)
        remainingBricks.text = "Remaining Bricks: " + String(newRemainingBricks)
    }

    
    @MainActor
    func resizeOverlay(size: CGSize) {
        //title.position = CGPoint(x: size.width / 2, y: size.height - 96)
        print("Resizing Overlay")
    }
    
    @MainActor
    func handleDoubleTap(size: CGSize) {
        isHidden = !isHidden;
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



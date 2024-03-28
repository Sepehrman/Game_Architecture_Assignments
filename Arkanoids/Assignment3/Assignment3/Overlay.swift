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
    var balls: SKLabelNode
    var startText: SKLabelNode
    var blinkAction: SKAction!

//    let map: SKShapeNode
    
    override init(size: CGSize) {

        score = SKLabelNode(text: "Score: 0")
        score.name = "score"
        score.fontColor = .white
        score.fontSize = 24
        score.fontName = "Robota"
        score.position = CGPoint(x: size.width - 80, y: size.height - 210)
        
        
        startText = SKLabelNode(text: "Double-Tap to Start!")
        startText.name = "Double-Tap"
        startText.fontColor = .yellow
        startText.fontSize = 24
        startText.fontName = "Robota"
        startText.position = CGPoint(x: size.width - 200, y: size.height - 550)
        
        
        balls = SKLabelNode(text: "Balls Left: 3")
        balls.name = "balls"
        balls.fontColor = .white
        balls.fontSize = 24
        balls.fontName = "Robota"
        balls.position = CGPoint(x: 130, y: size.height - 210)
        
        super.init(size: size)
        
        self.backgroundColor = .clear
        self.addChild(score)
        self.addChild(balls)
        self.addChild(startText)

        let fadeInAction = SKAction.fadeIn(withDuration: 2)
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        let blinkSequence = SKAction.sequence([fadeOutAction, fadeInAction])
        blinkAction = SKAction.repeatForever(blinkSequence)
        startText.run(blinkAction)
        
        
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
        balls.text = "Balls Left: " + String(newRemainingBricks)
    }
    
    func removeStartText() {
        startText.removeFromParent()
    }

    
    @MainActor
    func resizeOverlay(size: CGSize) {
        //title.position = CGPoint(x: size.width / 2, y: size.height - 96)
        print("Resizing Overlay")
    }
    
    func showStartText() {
        startText = SKLabelNode(text: "Double-Tap to Start!")
        startText.name = "Double-Tap"
        startText.fontColor = .yellow
        startText.fontSize = 24
        startText.fontName = "Robota"
        startText.position = CGPoint(x: size.width - 200, y: size.height - 550)
    }
    
    @MainActor
    func handleDoubleTap(size: CGSize) {
        isHidden = !isHidden;
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



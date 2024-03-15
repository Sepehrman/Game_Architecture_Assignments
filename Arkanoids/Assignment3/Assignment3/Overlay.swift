//
//  Overlay.swift
//  Assignment3
//
//  Created by Nathan Dong on 2024-03-14.
//

import SpriteKit
import SwiftUI

class OverlayScene: SKScene {
    var title: SKLabelNode
//    let map: SKShapeNode
    
    override init(size: CGSize) {
        let mapWidth = 200.0
        let mapHeight = 200.0
        

        title = SKLabelNode(text: "Map")
        title.name = "MapTitle"
        title.fontColor = .gray
        title.fontSize = 48
        title.fontName = "Robota"
        title.position = CGPoint(x: size.width / 2, y: size.height - 96)
        
//        map = SKShapeNode(rect: CGRect(x: size.width / 2 - mapWidth / 2, y: size.height / 2 - mapHeight / 2, width: mapWidth, height: mapHeight))
//        map.name = "MapOverlay"
//        map.lineWidth = 2
//        map.strokeColor = .gray
//        map.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
        
        super.init(size: size)
        
        self.backgroundColor = .clear
        self.addChild(title)
//        self.addChild(map)
        scene!.scaleMode = .aspectFill
        
        print("MapOverlayScene initialized")
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



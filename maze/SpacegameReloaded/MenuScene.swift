//
//  MenuScene.swift
//  SpacegameReloaded
//
//  Created by Daniel Autenrieth on 03/11/2016.
//  Copyright © 2016 Training. All rights reserved.
//

import UIKit
import SpriteKit

class MenuScene: SKScene {

    var starfield:SKEmitterNode!
    
    var newGameButtonNode:SKSpriteNode!
    var difficultyButtonNode:SKSpriteNode!
    var diffcultyLabel:SKLabelNode!
    
    override func didMove(to view: SKView) {
    
        
        starfield = self.childNode(withName: "starfield") as! SKEmitterNode
        starfield.advanceSimulationTime(10)
        
        newGameButtonNode = self.childNode(withName: "newGameButton") as! SKSpriteNode
        difficultyButtonNode = self.childNode(withName: "difficultyButton") as! SKSpriteNode
        
        newGameButtonNode.texture = SKTexture(imageNamed: "newGameButton")
        difficultyButtonNode.texture = SKTexture(imageNamed: "difficultyButton")
        
        diffcultyLabel = self.childNode(withName: "difficultyLabel") as! SKLabelNode
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.bool(forKey: "hard") {
            diffcultyLabel.text = "Hard"
        }else{
            diffcultyLabel.text = "Easy"
        }
        
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let touch = touches.first
        if let location = touch?.location(in: self) {
            let node = self.nodes(at: location)
            
            if node[0].name == "newGameButton" {
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameScene = GameScene(size: self.size)
                self.view!.presentScene(gameScene, transition: transition)
            }else if node[0].name == "difficultyButton" {
                changeDifficulty()
            }
        }
        
    }
    
    func changeDifficulty(){
        
        let userDefaults = UserDefaults.standard
        
        if diffcultyLabel.text == "Easy" {
            diffcultyLabel.text = "Hard"
            userDefaults.set(true, forKey: "hard")
        }else{
            diffcultyLabel.text = "Easy"
            userDefaults.set(false, forKey: "hard")
        }
        
        userDefaults.synchronize()
    }
    
}

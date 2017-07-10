 //
//  GameScene.swift
//  maze
//
//  Created by Alejandro Haro on 7/7/17.
//  Copyright © 2017 Alejandro Haro. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var starfield:SKEmitterNode!
    var player = SKSpriteNode()
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var gameTimer:Timer!
    var possibleAliens = ["alien6", "alien4", "alien5", "alien7"]
    let alienCategory:UInt32 = 0x1 << 1 // necessary for collision detection
    let photonTorpedoCategory:UInt32 = 0x1 << 0 // necessary for collision detection
    
    var isPlayerAlive = true
    
    // create motion manager
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    var yAcceleration:CGFloat = 0
    
    var livesArray:[SKSpriteNode]!
// show spaceship and starfield
    
    override func didMove(to view: SKView) {
        addLives()
        
        // background music
        self.run(SKAction.playSoundFileNamed("spaceBattle.mp3", waitForCompletion: false))
        
        // create the starfield (background)
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1080)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        starfield.zPosition = -1 // make sure starfield is behind other objects
        
        // create the player
        player = SKSpriteNode(imageNamed: "Spaceship")
        player.position = CGPoint(x: 0, y: -400)
        self.addChild(player)

        // create physics (gravity)
        self.physicsWorld.gravity = CGVector(dx: 0 , dy: 0)
        self.physicsWorld.contactDelegate = self
       
        // create score label
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 0, y: 600) // needs to be dynamic for other iphone sizes (this for iphone 7 plus)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
        
        // gameTimer will create the enemies, decrease timeInterval to create more aliens!
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
//        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
                self.yAcceleration = CGFloat(acceleration.y) * 0.75 + self.yAcceleration * 0.25
            }
            
        }
        
    
    }
    
    func addLives (){
        
        livesArray = [SKSpriteNode]()
        
        for live in 1 ... 3 {
            let liveNode = SKSpriteNode(imageNamed: "shuttle")
            liveNode.name = "live\(live)"
            liveNode.position = CGPoint(x: 390 - CGFloat((4 - live)) * liveNode.size.width, y: 610)
            self.addChild(liveNode)
            livesArray.append(liveNode)
        }
    }
    
    // code block to add aliens (with gameTimer function)
    func addAlien () {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: -380, highestValue: 380)
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        // create alien
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -self.frame.size.height-alien.size.height), duration: animationDuration))
        
        actionArray.append(SKAction.run {
            self.run(SKAction.playSoundFileNamed("loose.mp3", waitForCompletion: false))
            
            if self.livesArray.count >= 0 {
                
                let liveNode = self.livesArray.first
                liveNode!.removeFromParent()
                self.livesArray.removeFirst()
                
                
                if self.livesArray.count == 0{
                    let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                    let gameOver = SKScene(fileNamed: "GameOverScene") as! GameOverScene
                    gameOver.score = self.score
                    self.view?.presentScene(gameOver, transition: transition)
                }
                
            }
            
        })

        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    //fire torpedo with touch
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // disable firing of torpedos if your character is dead!
        if (isPlayerAlive) { // not yet implemented!!
            fireTorpedo()
        }
        
    }
    
    func fireTorpedo() {
        // play a sound when we fire a torpedo
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 50 // torpedo should fire not from center but front of ship
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        // create physics elements for torpedo
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        // add torpedo to the image
        self.addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 1
        
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
        
        
    }
    //find out which is torpedo and which is alien during contact
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
            print ("collide!")
        }
        
    }
    
    func torpedoDidCollideWithAlien (torpedoNode:SKSpriteNode, alienNode:SKSpriteNode) {
        // create explosion element
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        // remove nodes (because they exploded!)
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
        
        
    }
    
    
    // physics for player movement with coreMotion
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 20
        player.position.y += yAcceleration * 30
        // add boundry for x
        if player.position.x < -450 {
            player.position = CGPoint(x: 450, y: player.position.y)
        } else if player.position.x > 450 {
            player.position = CGPoint(x: -450, y: player.position.y)
        }
        // add boundry for y
        if player.position.y < -500 {
            player.position = CGPoint(x: player.position.x, y: -500)
        } else if player.position.y > 500 {
            player.position = CGPoint(x: player.position.x, y: 500)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

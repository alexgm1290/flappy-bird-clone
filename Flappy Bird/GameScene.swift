//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Alex Gomez on 12/10/18.
//  Copyright © 2018 Alex Gomez. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //MARK: - Variables
    var bird = SKSpriteNode()
    var background = SKSpriteNode()
    var ground = SKSpriteNode()
    var upwardPipe = SKSpriteNode()
    var downwardPipe = SKSpriteNode()
    var scoringGap = SKNode()
    var gameScoreLabel = SKLabelNode()
    var gameOverLabel = SKLabelNode()
    let gameScoreLabelShadow = SKLabelNode()
    
    var score = 0
    var gapHeight : CGFloat = 0
    var pipeOffset : CGFloat = 0
    var gameOver = false
    var timer = Timer()
    
    var fontName = "Gamer"
    var fontSize : CGFloat = 120
    var fontZPosition : CGFloat = 5
    
    enum ColliderType : UInt32 {
        case Bird = 1
        case Object = 2
        case Gap = 4
        // Numbers should double to avoid errors (E.g. 1, 2, 4, 8, 16, 32)
    }
    
    //MARK: - Custom Methods
    func setupBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        
        let moveLeftFromInitialPosition = SKAction.move(by: CGVector(dx: -backgroundTexture.size().width, dy: 0), duration: 12)
        let resetPosition = SKAction.move(by: CGVector(dx: backgroundTexture.size().width, dy: 0), duration: 0)
        let moveLeftAnimation = SKAction.repeatForever(SKAction.sequence([moveLeftFromInitialPosition,
                                                                          resetPosition]))
        
        // Create 3 background images one next to the other
        var i : CGFloat = 0
        
        while i < 3 {
            background = SKSpriteNode(texture: backgroundTexture)
            background.position = CGPoint(x: backgroundTexture.size().width * i, y: self.frame.midY)
            background.size.height = self.frame.height
            background.size.width = background.size.height * 0.9
            
            background.run(moveLeftAnimation)
            background.zPosition = -1
            self.addChild(background)
            
            i += 1
        }
    }
    
    func setupGround() {
        
        let groundTexture = SKTexture(imageNamed: "ground")
        
        var i : CGFloat = 0
        while i < 3 {
            ground = SKSpriteNode(texture: groundTexture)
            ground.position = CGPoint(x: groundTexture.size().width * i, y: -self.frame.height / 2 + ground.size.height / 2)
            
            ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: groundTexture.size().width, height: groundTexture.size().height))
            ground.physicsBody?.isDynamic = false
            
            self.addChild(ground)
            ground.zPosition = 1
            
            ground.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
            ground.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
            ground.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
            
            i += 1
        }
    }
    
    func setupBird() {
        let birdTexture = [SKTexture(imageNamed: "redbird-downflap"),
                           SKTexture(imageNamed: "redbird-midflap"),
                           SKTexture(imageNamed: "redbird-upflap")]
        bird = SKSpriteNode(texture: birdTexture[0])
        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        let flappingAnimation = SKAction.animate(with: birdTexture, timePerFrame: 0.1)
        let flappingLoop = SKAction.repeatForever(flappingAnimation)
        
        bird.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: bird.size.width, height: bird.size.height))
        bird.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody?.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        bird.physicsBody?.isDynamic = false
        
        bird.run(flappingLoop, withKey: "flapping")
        
        bird.zPosition = 2
        self.addChild(bird)
    }
    
    func setupPipe() {
        
        // Create a Gap between both pipes
        let gapHeight = bird.size.height * 4
        // Get a random Y value by generating a number between 0 and half of the screen, then substracting a quarter of the screen
        let movement = CGFloat.random(in: 0...self.frame.height / 2)
        let pipeOffset = movement - self.frame.height / 4
        
        // Setup Sprites
        let pipeTexture = SKTexture(imageNamed: "pipe")

        upwardPipe = SKSpriteNode(texture: pipeTexture)
        upwardPipe.position = CGPoint(x: self.size.width, y: self.frame.midY - upwardPipe.size.height / 2 - gapHeight / 2 + pipeOffset)
        
        downwardPipe = SKSpriteNode(texture: pipeTexture)
        downwardPipe.yScale = yScale * -1
        downwardPipe.position = CGPoint(x: self.size.width, y: self.frame.midY + upwardPipe.size.height / 2 + gapHeight / 2 + pipeOffset)
        
        // Setup Physics
        upwardPipe.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upwardPipe.size.width, height: upwardPipe.size.height))
        upwardPipe.physicsBody?.isDynamic = false
        upwardPipe.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        upwardPipe.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        upwardPipe.physicsBody?.collisionBitMask = ColliderType.Object.rawValue
        
        downwardPipe.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: downwardPipe.size.width, height: downwardPipe.size.height))
        downwardPipe.physicsBody?.isDynamic = false
        downwardPipe.physicsBody?.contactTestBitMask = ColliderType.Object.rawValue
        downwardPipe.physicsBody?.categoryBitMask = ColliderType.Object.rawValue
        downwardPipe.physicsBody?.collisionBitMask = ColliderType.Object.rawValue

        // Setup scoring gap
        scoringGap = SKNode()
        scoringGap.position = CGPoint(x: self.size.width, y: self.frame.midY + pipeOffset)
        scoringGap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upwardPipe.size.width, height: gapHeight))
        scoringGap.physicsBody?.isDynamic = false
        scoringGap.physicsBody?.contactTestBitMask = ColliderType.Bird.rawValue
        scoringGap.physicsBody?.categoryBitMask = ColliderType.Gap.rawValue
        scoringGap.physicsBody?.collisionBitMask = ColliderType.Gap.rawValue
        
        // Setup Pipes animation
        let moveLeft = SKAction.move(by: CGVector(dx: -2 * self.size.width, dy: 0), duration: TimeInterval(self.frame.width / 100))
        upwardPipe.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
        downwardPipe.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
        scoringGap.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))

        upwardPipe.speed = 0
        downwardPipe.speed = 0
        scoringGap.speed = 0
        
        // Add nodes to scene
        self.addChild(scoringGap)
        self.addChild(upwardPipe)
        self.addChild(downwardPipe)
    }
    
    func setupScoreLabel() {
        gameScoreLabel.fontName = fontName
        gameScoreLabel.fontSize = fontSize
        gameScoreLabel.zPosition = fontZPosition
        gameScoreLabel.text = String(score)
        gameScoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 150)
        
        gameScoreLabelShadow.fontName = fontName
        gameScoreLabelShadow.fontSize = fontSize
        gameScoreLabelShadow.fontColor = .black
        gameScoreLabelShadow.zPosition = gameScoreLabel.zPosition - 1
        gameScoreLabelShadow.text = gameScoreLabel.text
        gameScoreLabelShadow.alpha = 0.5
        gameScoreLabelShadow.position = CGPoint(x: gameScoreLabel.position.x + 2, y: gameScoreLabel.position.y - 2)
    }
    
    func animateScore() {
        // Add a little visual feedback for the score increment
        gameScoreLabel.run(SKAction.sequence([SKAction.scale(to: 1.2, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
        gameScoreLabelShadow.run(SKAction.sequence([SKAction.scale(to: 1.2, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
        
        let upGameScoreLabel = gameScoreLabel.copy() as! SKLabelNode
        upGameScoreLabel.fontColor = UIColor(red: 0.98, green: 0.23, blue: 0.11, alpha: 0.8)
        upGameScoreLabel.run(SKAction.sequence([SKAction.move(by: CGVector(dx: 0, dy: 20), duration: 0.1), SKAction.fadeOut(withDuration: 0.1)]))
        self.addChild(upGameScoreLabel)
    }
    
    func setupGame() {
        setupBackground()
        setupGround()
        setupBird()
        
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.setupPipe()
        }
        
        setupScoreLabel()
        self.addChild(gameScoreLabel)
        self.addChild(gameScoreLabelShadow)
    }
    
    //MARK: - Class Methods
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        setupGame()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameOver == false {
            if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue || contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
                score += 1
                
                animateScore()
                
            } else {
                self.speed = 0
                score = 0
                timer.invalidate()
                gameOver.toggle()
                
                //MARK: Game Over View
                if let gameOverLabelUnwrapped = SKLabelNode(fontNamed: fontName, andText: "Game Over", andSize: fontSize, withShadow: "Game Over", andColor: .black) {
                    gameOverLabel = gameOverLabelUnwrapped
                    gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                    gameOverLabel.zPosition = fontZPosition
                    self.addChild(gameOverLabel)
                }
                
                let gameOverBackground = SKSpriteNode()
                gameOverBackground.color = UIColor(white: 0.1, alpha: 0.9)
                gameOverBackground.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                gameOverBackground.size = self.size
                self.addChild(gameOverBackground)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if gameOver == false {
            
            setupScoreLabel()
            
            bird.physicsBody?.isDynamic = true
            bird.physicsBody?.velocity = CGVector(dx: 0, dy: 150)
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 130))
            
            // Setup Pipes Animation
            upwardPipe.speed = 1
            downwardPipe.speed = 1
            scoringGap.speed = 1
            
            
        } else {
            gameOver.toggle()
            score = 0
            self.speed = 1
            self.removeAllChildren()
            
            setupGame()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if gameOver == false {
            let value = bird.physicsBody!.velocity.dy * (bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001)
            bird.zRotation = min(max(-1, value), 0.5)
        } else {
            scene?.speed = 0
        }
    }
}



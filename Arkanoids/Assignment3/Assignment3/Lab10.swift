//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Lab10: Demo using Box2D for a ball that can be launched and
//        a falling brick that disappears when it hits the ball
//
//====================================================================

import SceneKit
import SpriteKit

import QuartzCore

class Box2DDemo: SCNScene {
    
    var cameraNode = SCNNode()                      // Initialize camera node
    
    var lastTime = CFTimeInterval(floatLiteral: 0)  // Used to calculate elapsed time on each update
    
    let offsetMultiplier = 0.0002
    
    private var box2D: CBox2D!                      // Points to Objective-C++ wrapper for C++ Box2D library
    
    var overlayScene: OverlayScene?
    
    // Catch if initializer in init() fails
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initializer
    override init() {
        
        super.init() // Implement the superclass' initializer
        
        background.contents = UIColor.black // Set the background colour to black
        
        setupCamera()
        
        // Add the bricks
        for row in stride(from: BRICK_ROW_ITER_START, to: BRICK_ROW_ITER_END, by: Int32.Stride(BRICK_ROW_ITER_STEP)) {
            for column in stride(from: BRICK_COL_ITER_START, to: BRICK_COL_ITER_END, by: Int32.Stride(BRICK_COL_ITER_STEP)){
                      addBrick(brick_pos_x: CGFloat(row), brick_pos_y: CGFloat(column))
                  }
              }
        
        // Add the ball
        addBall()
        
        // Add walls
        addWalls()
        addPaddle()
        
        // Initialize the Box2D object
        box2D = CBox2D()
        //        box2D.helloWorld()  // If you want to test the HelloWorld example of Box2D
        
        // Setup the game loop tied to the display refresh
        let updater = CADisplayLink(target: self, selector: #selector(gameLoop))
        updater.preferredFrameRateRange = CAFrameRateRange(minimum: 120.0, maximum: 120.0, preferred: 120.0)
        updater.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        
    }
    
    
    // Function to setup the camera node
    func setupCamera() {
        
        let camera = SCNCamera() // Create Camera object
        cameraNode.camera = camera // Give the cameraNode a camera
        // Since this is 2D, just look down the z-axis
        cameraNode.position = SCNVector3(0, 50, 100)
        cameraNode.eulerAngles = SCNVector3(0, 0, 0)
        rootNode.addChildNode(cameraNode) // Add the cameraNode to the scene
        
    }

    
    func addBrick(brick_pos_x: CGFloat, brick_pos_y: CGFloat) {
           let theBrick = SCNNode(geometry: SCNBox(width: CGFloat(BRICK_WIDTH), height: CGFloat(BRICK_HEIGHT), length: 1, chamferRadius: 0))
           
           let brickName = "Brick \(Int(brick_pos_x)) \(Int(brick_pos_y))"
           theBrick.name = brickName
           //print(brickName)
           theBrick.geometry?.firstMaterial?.diffuse.contents = UIColor.red
           theBrick.position = SCNVector3(Int(brick_pos_x), Int(brick_pos_y), 0)
           rootNode.addChildNode(theBrick)
       }

    
    func addPaddle() {
        
        let theBrick = SCNNode(geometry: SCNBox(width: CGFloat(BRICK_WIDTH), height: CGFloat(BRICK_HEIGHT), length: 1, chamferRadius: 0))
        theBrick.name = "Paddle"
        theBrick.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        theBrick.position = SCNVector3(Int(PADDLE_POS_X), Int(PADDLE_POS_Y), 0)
        rootNode.addChildNode(theBrick)
    }
    
    
    func addBall() {
        
        let theBall = SCNNode(geometry: SCNSphere(radius: CGFloat(BALL_RADIUS)))
        theBall.name = "Ball"
        theBall.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        theBall.position = SCNVector3(Int(BALL_POS_X), Int(BALL_POS_Y), 0)
        rootNode.addChildNode(theBall)
        
    }
    
    
    func addWalls() {
        
        let wallLeft = SCNNode(geometry: SCNBox(width: CGFloat(WALL_LEFT_WIDTH), height: CGFloat(WALL_LEFT_HEIGHT), length: 1, chamferRadius: 0))
        wallLeft.name = "Wall_Left"
        wallLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wallLeft.position = SCNVector3(Int(WALL_LEFT_POS_X), Int(WALL_LEFT_POS_Y), 0)
        rootNode.addChildNode(wallLeft)
        
        let wallRight = SCNNode(geometry: SCNBox(width: CGFloat(WALL_RIGHT_WIDTH), height: CGFloat(WALL_RIGHT_HEIGHT), length: 1, chamferRadius: 0))
        wallRight.name = "Wall_Right"
        wallRight.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wallRight.position = SCNVector3(Int(WALL_RIGHT_POS_X), Int(WALL_RIGHT_POS_Y), 0)
        rootNode.addChildNode(wallRight)
        
        let wallTop = SCNNode(geometry: SCNBox(width: CGFloat(WALL_TOP_WIDTH), height: CGFloat(WALL_TOP_HEIGHT), length: 1, chamferRadius: 0))
        wallTop.name = "Wall_Top"
        wallTop.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        wallTop.position = SCNVector3(Int(WALL_TOP_POS_X), Int(WALL_TOP_POS_Y), 0)
        rootNode.addChildNode(wallTop)
        
        let wallBot = SCNNode(geometry: SCNBox(width: CGFloat(WALL_BOT_WIDTH), height: CGFloat(WALL_BOT_HEIGHT), length: 1, chamferRadius: 0))
        wallBot.name = "Wall_Bot"
        wallBot.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        wallBot.position = SCNVector3(Int(WALL_BOT_POS_X), Int(WALL_BOT_POS_Y), 0)
        rootNode.addChildNode(wallBot)

    }
    
    
    // Simple game loop that gets called each frame
    @MainActor
    @objc
    func gameLoop(displaylink: CADisplayLink) {
        
        if (lastTime != CFTimeInterval(floatLiteral: 0)) {  // if it's the first frame, just update lastTime
            let elapsedTime = displaylink.targetTimestamp - lastTime    // calculate elapsed time
            updateGameObjects(elapsedTime: elapsedTime) // update all the game objects
        }
        lastTime = displaylink.targetTimestamp
        
    }
    
    
    @MainActor
    func updateGameObjects(elapsedTime: Double) {
        
        // Update Box2D physics simulation
        box2D.update(Float(elapsedTime))
        
        // Get ball position and update ball node
        let ballPos = UnsafePointer(box2D.getObject("Ball"))
        let theBall = rootNode.childNode(withName: "Ball", recursively: true)
        theBall?.position.x = (ballPos?.pointee.loc.x)!
        theBall?.position.y = (ballPos?.pointee.loc.y)!
        //        print("Ball pos: \(String(describing: theBall?.position.x)) \(String(describing: theBall?.position.y))")
        
        
        for row in stride(from: BRICK_ROW_ITER_START, to: BRICK_ROW_ITER_END, by: Int32.Stride(BRICK_ROW_ITER_STEP)) {
            for column in stride(from: BRICK_COL_ITER_START, to: (BRICK_COL_ITER_END), by: Int32.Stride(BRICK_COL_ITER_STEP)){
                // Get brick position and update brick node
                let brickPos = UnsafePointer(box2D.getObject("Brick \(row) \(column)"))
                let theBrick = rootNode.childNode(withName: "Brick \(row) \(column)", recursively: true)
                if (brickPos != nil) {
//                    print("Brick \(row) \(column)")
                    // The brick is visible, so set the position
                    
                    theBrick?.isHidden = false

                    
                    theBrick?.position.x = (brickPos?.pointee.loc.x)!
                    theBrick?.position.y = (brickPos?.pointee.loc.y)!
//                    print(theBrick?.position.x)
//                    print(theBrick?.position.y)
                    //            print("Brick pos: \(String(describing: theBrick?.position.x)) \(String(describing: theBrick?.position.y))")
                    
                } else {
                    
                    
                    // The brick has disappeared, so hide it
                    theBrick?.isHidden = true
                    
                    
                    
                }
                  }
              }
       
        
        // Uncomment the following if wall physics is buggy
//        // Get wall positions and update wall nodes for troublshooting purposes
//        let topWallPos = UnsafePointer(box2D.getObject("Wall_Top"))
//        let topWall = rootNode.childNode(withName: "Wall_Top", recursively: true)
//        topWall?.position.x = (topWallPos?.pointee.loc.x)!
//        topWall?.position.y = (topWallPos?.pointee.loc.y)!
//        
//        let botWallPos = UnsafePointer(box2D.getObject("Wall_Bot"))
//        let botWall = rootNode.childNode(withName: "Wall_Bot", recursively: true)
//        botWall?.position.x = (botWallPos?.pointee.loc.x)!
//        botWall?.position.y = (botWallPos?.pointee.loc.y)!
        
        // Updating the UI
        overlayScene?.setScore(newScore: Int(box2D.score))  // Cast int32 to int
        overlayScene?.setRemainingBricks(newRemainingBricks: Int(box2D.remainingBricks))  // Cast int32 to int
    }
    
    
    // Function to be called by double-tap gesture: launch the ball
    @MainActor
    func handleDoubleTap() {
        print("Box2DDemo:handleDoubleTap")
        box2D.launchBall()
    }
    
    
    // Function to reset the physics (reset Box2D and reset the brick)
    @MainActor
    func resetPhysics() {
        
        box2D.reset()
        
        
        for row in stride(from: BRICK_ROW_ITER_START, to: BRICK_ROW_ITER_END, by: Int32.Stride(BRICK_ROW_ITER_STEP)) {
            for column in stride(from: BRICK_COL_ITER_START, to: (BRICK_COL_ITER_END), by: Int32.Stride(BRICK_COL_ITER_STEP)){
                
                let theBrick = rootNode.childNode(withName: "Brick \(row) \(column)", recursively: true)
                theBrick?.isHidden = false
                
            }
        }
        
    }
    
    @MainActor
    func movePaddle(offset: CGSize) {
        
        let offsetX = Double(offset.width) // Convert CGFloat to Double
        
        let theBrick = rootNode.childNode(withName: "Brick", recursively: true)
        box2D.movePaddle(Double(offset.width) * offsetMultiplier)
    }
    
}


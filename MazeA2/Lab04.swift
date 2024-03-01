//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Lab04: Make a cube that can be rotated with gestures
//
//====================================================================

import SceneKit
import SwiftUI
import SpriteKit


class ControlableRotatingCrate: SCNScene {
    var rotAngle = CGSize.zero // Keep track of drag gesture numbers
    var rot = CGSize.zero // Keep track of rotation angle
    var isRotating = true // Keep track of if rotation is toggled
    var cameraNode = SCNNode() // Initialize camera node
    var mazeSize = Int32(6)
    
    var isDay: Bool = true
    
    // Light
    var diffuseLightPos = SCNVector4(0, 10, 0, Double.pi/2) // Keep track of flashlight position
    var isAmbientLightOn = false
    var ambientLightColorDay = UIColor.white
    var ambientLightColorNight = UIColor.blue
    var ambientLightIntensity = CGFloat(500)
    var ambientLightIntensityNight = CGFloat(100)
    
    var isDirectionalLightOn = false
    var isFlashLightOn = false
    var directionalLightIntensity = CGFloat(0)
    var flashLightIntensity = CGFloat(1000)
    
    // Fog
    var fogDensity = 2.0    // 0.0, 1.0, or 2.0
    let fogStartDistance_ = 4 // The fog effect starts at z = 4
    let fogEndDistance_ = 10 // The fog effect ends at z = 10

    // Catch if initializer in init() fails
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initializer passing binding variable for the drag gesture numbers
    override init() {
        super.init() // Implement the superclass' initializer
        
        background.contents = UIColor.black // Set the background colour to black
        
        setupCamera()
        drawMaze()
        
        // setupFlashlight()
        setupPlayerFlashlight()
        setupAmbientLight()
        setupDirectionalLight()
        setLightBasedOnIsDay()
        
        setupFog()
        //addCube()
        Task(priority: .userInitiated) {
            await firstUpdate()
        }
    }
    
    func drawMaze(){
        var maze : Maze = Maze(mazeSize, mazeSize)
        maze.Create()
        addMinimap(maze:&maze)
        let drawnMaze = SCNNode()
        drawnMaze.pivot = SCNMatrix4MakeTranslation(Float(mazeSize)/2, 0, Float(mazeSize)/2)
        drawnMaze.name = "The Maze"
        for row in 0..<mazeSize {
            for col in 0..<mazeSize {
                let mazeCell = maze.GetCell(row, col)
                let drawnCell = drawCell(cell: mazeCell)
                drawnCell.position.x = Float(row)
                drawnCell.position.z = Float(col)
                drawnMaze.addChildNode(drawnCell)
            }
        }
        rootNode.addChildNode(drawnMaze)
    }
    
    func addMinimap(maze: inout Maze) {
        let minimapBaseSize: CGFloat = 0.9
        let wallHeight: CGFloat = 0.1
        let offset = 0.52
        
        let minimapBase = SCNNode(/*geometry: SCNPlane(width: minimapBaseSize, height: minimapBaseSize)*/)
        minimapBase.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        minimapBase.position = SCNVector3(4.2, 3.5, 4.0)
        minimapBase.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)  // Adjust base orientation
       
        rootNode.addChildNode(minimapBase)
        
        // Calculate cell size based on maze size and minimap base size
        let cellSize = minimapBaseSize / CGFloat(mazeSize)
        
        for row in 0..<mazeSize {
            for col in 0..<mazeSize {
                let mazeCell = maze.GetCell(row, col)
                let cellX = Float(col) * Float(cellSize)
                let cellY = Float(row) * Float(cellSize)
                
                // Draw the cell
//                let cellGeometry = SCNPlane(width: cellSize*0.9, height: cellSize*0.9)
//                cellGeometry.firstMaterial?.diffuse.contents = UIColor.blue
                let cellNode = SCNNode(/*geometry: cellGeometry*/)
                cellNode.position = SCNVector3(Double(cellX) - offset, Double(cellY) - offset, 0.1)
                minimapBase.addChildNode(cellNode)
                cellNode.eulerAngles = SCNVector3(Float.pi, Float.pi, Float.pi/2) // Match base orientation
                
                // Draw walls around the cell
                if mazeCell.northWallPresent {
                    let wall = SCNPlane(width: cellSize*0.1, height: cellSize*0.8)
                    wall.firstMaterial?.diffuse.contents = UIColor.red
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(cellSize/2,0,0)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.southWallPresent {
                    let wall = SCNPlane(width: cellSize*0.1, height: cellSize*0.8)
                    wall.firstMaterial?.diffuse.contents = UIColor.blue
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(-cellSize/2,0,0)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.eastWallPresent {
                    let wall = SCNPlane(width: cellSize*0.8, height: cellSize*0.1)
                    wall.firstMaterial?.diffuse.contents = UIColor.green
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(0,cellSize/2,0)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.westWallPresent {
                    let wall = SCNPlane(width: cellSize*0.8, height: cellSize*0.1)
                    wall.firstMaterial?.diffuse.contents = UIColor.yellow
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(0,-cellSize/2,0)
                    cellNode.addChildNode(wallNode)
                }
            }
        }
    }




    
    func wallMaterial(left: Bool, right: Bool) -> SCNMaterial {
        var material = SCNMaterial()
        
        if left && right {
            material.diffuse.contents = UIImage(named: "green.jpg")
        } else if left {
            material.diffuse.contents = UIImage(named: "orange.jpg")
        } else if right {
            material.diffuse.contents = UIImage(named: "yellow.jpg")
        } else {
            material.diffuse.contents = UIImage(named: "blue.jpg")
        }
        
        return material
    }

    func createWall(position: SCNVector3, eulerAngles: SCNVector3, left: Bool, right: Bool) -> SCNNode {
        let wall = SCNPlane(width: 1.0, height: 1.0)
        wall.materials = [wallMaterial(left: left, right: right)]
        wall.firstMaterial?.isDoubleSided = true
        
        let wallNode = SCNNode(geometry: wall)
        wallNode.position = position
        wallNode.eulerAngles = eulerAngles
        
        
        return wallNode
    }

    func drawCell(cell: MazeCell) -> SCNNode {
        
        let drawnCell = SCNNode()
        
        let floor = SCNBox(width: 1, height: 0.1, length: 1, chamferRadius: 0)
        floor.firstMaterial?.diffuse.contents = UIImage(named: "gray.jpg")
        drawnCell.addChildNode(SCNNode(geometry: floor))
        
        if cell.northWallPresent {
            drawnCell.addChildNode(createWall(position: SCNVector3(-0.49, 0.49, 0), eulerAngles: SCNVector3(0,Float.pi/2, 0), left: cell.eastWallPresent, right: cell.westWallPresent))
        }
        if cell.southWallPresent {
            drawnCell.addChildNode(createWall(position: SCNVector3(0.49, 0.49, 0), eulerAngles: SCNVector3(0, Float.pi/2, 0), left: cell.westWallPresent, right: cell.eastWallPresent))
        }
        if cell.eastWallPresent {
            drawnCell.addChildNode(createWall(position: SCNVector3(0, 0.49, 0.49), eulerAngles: SCNVector3(0, 0, 0), left: cell.southWallPresent, right: cell.northWallPresent))
        }
        if cell.westWallPresent {
            drawnCell.addChildNode(createWall(position: SCNVector3(0, 0.49, -0.49), eulerAngles: SCNVector3(0, 0, 0), left: cell.northWallPresent, right: cell.southWallPresent))
        }
        return drawnCell
    }

    
    
    
    // Function to setup the camera node
    func setupCamera() {
        let camera = SCNCamera() // Create Camera object
        cameraNode.camera = camera // Give the cameraNode a camera
        cameraNode.position = SCNVector3(5, 5, 5) // Set the position to (5, 5, 5)
        cameraNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0) // Set the pitch, yaw, and roll
        rootNode.addChildNode(cameraNode) // Add the cameraNode to the scene
    }
    
    // Create Cube
//    func addCube() {
//        let theCube = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)) // Create a object node of box shape with width of 1 and height of 1
//        theCube.name = "The Cube" // Name the node so we can reference it later
//        theCube.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "crate.jpg") // Diffuse the crate image material across the whole cube
//        theCube.position = SCNVector3(0, 0, 0) // Put the cube at position (0, 0, 0)
//        rootNode.addChildNode(theCube) // Add the cube node to the scene
//    }
    
    // Sets up an ambient light (all around)
    func setupAmbientLight() {
        let ambientLight = SCNNode() // Create a SCNNode for the lamp
        ambientLight.name = "Ambient Light"
        ambientLight.light = SCNLight() // Add a new light to the lamp
        ambientLight.light!.type = .ambient // Set the light type to ambient
        ambientLight.light!.color = UIColor.white // Set the light color to white
        ambientLight.light!.intensity = ambientLightIntensity // Set the light intensity to 5000 lumins (1000 is default)
        rootNode.addChildNode(ambientLight) // Add the lamp node to the scene
    }
    
    // Sets up a directional light (flashlight)
    func setupDirectionalLight() {
        let directionalLight = SCNNode() // Create a SCNNode for the lamp
        directionalLight.name = "Directional Light" // Name the node so we can reference it later
        directionalLight.light = SCNLight() // Add a new light to the lamp
        directionalLight.light!.type = .directional // Set the light type to directional
        directionalLight.light!.color = UIColor.green // Set the light color to white
        directionalLight.light!.intensity = directionalLightIntensity // Set the light intensity to 1000 lumins (1000 is default)
        
        directionalLight.position = SCNVector3(5, 6, 0)   // Position of camera
        directionalLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/2, 0) // Pitch, yaw and roll
        
//        directionalLight.rotation = diffuseLightPos // Set the rotation of the light from the flashlight to the flashlight position variable
        rootNode.addChildNode(directionalLight) // Add the lamp node to the scene
    }
    
    func setupFlashlight() {
        let flashLight = SCNNode()
        flashLight.name = "Flashlight"
        flashLight.light = SCNLight()
        flashLight.light!.type = SCNLight.LightType.spot
        
        flashLight.light!.castsShadow = true
        flashLight.light!.color = UIColor.red
        flashLight.light!.intensity = 1000
//        cameraNode.position = SCNVector3(5, 5, 5) // Set the position to (5, 5, 5)
//        cameraNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0) // Set
        flashLight.position = SCNVector3(5, 6, 0)   // Position of camera
        flashLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/2, 0) // Pitch, yaw and roll
        flashLight.light!.spotInnerAngle = 0
        flashLight.light!.spotOuterAngle = 30
        flashLight.light!.shadowColor = UIColor.black
        flashLight.light!.zFar = 500
        flashLight.light!.zNear = 50
        rootNode.addChildNode(flashLight)
    }
    
    func setupPlayerFlashlight() {
        let flashLight = SCNNode()
        flashLight.name = "PlayerFlashlight"
        flashLight.light = SCNLight()
        flashLight.light!.type = SCNLight.LightType.spot
        
        flashLight.light!.castsShadow = true
        flashLight.light!.color = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1)
        flashLight.light!.intensity = flashLightIntensity
        
//        flashLight.position = SCNVector3(5, 6, 0)   // Position of camera
//        flashLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/2, 0) // Pitch, yaw and roll
        flashLight.position = SCNVector3(5, 5, 5) // Set the position to (5, 5, 5)
        flashLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0) // Set the pitch, yaw, and roll
        
        flashLight.light!.spotInnerAngle = 0
        flashLight.light!.spotOuterAngle = 30
        flashLight.light!.shadowColor = UIColor.black
        flashLight.light!.zFar = 500
        flashLight.light!.zNear = 50
        rootNode.addChildNode(flashLight)
    }
    
    // Setup fog
    func setupFog() {
        fogColor = UIColor.black // Set fog colour to white
        fogStartDistance = 4 // The fog effect starts at z = 0
        fogEndDistance = 10 // The fog effect ends at z = 10
        fogDensityExponent = fogDensity // Set the function of distrubution of fog to nonic (The exponent is 9)
    }
    
    func setLightBasedOnIsDay() {
        let ambientLight = rootNode.childNode(withName: "Ambient Light", recursively: true)
        ambientLight?.light?.intensity = isDay ? ambientLightIntensity : ambientLightIntensityNight
        ambientLight?.light?.color = isDay ? ambientLightColorDay : ambientLightColorNight
    }
    
    @MainActor
    func firstUpdate() {
        reanimate() // Call reanimate on the first graphics update frame
    }
    
    @MainActor
    func reanimate() {
        let theMaze = rootNode.childNode(withName: "The Maze", recursively: true) // Get the cube object by its name (This is where line 45 comes in)
        if (isRotating) {
            rot.width += 0.05 // Increment rotation of the cube by 0.0005 radians
        } else {
            rot = rotAngle // Let the rot variable follow the drag gesture
        }
        theMaze?.eulerAngles = SCNVector3(Double(rot.height / 50), Double(rot.width / 50), 0) // Set the cube rotation to the numbers given from the drag gesture
        // Repeat increment of rotation every 10000 nanoseconds
        Task { try! await Task.sleep(nanoseconds: 10000)
            reanimate()
        }
    }
    
    @MainActor
    // Function to be called by double-tap gesture
    func handleDoubleTap() {
        isRotating = !isRotating // Toggle rotation
        
        isDay = !isDay
        setLightBasedOnIsDay()
    }
    
    @MainActor
    // Function to be called by drag gesture
    func handleDrag(offset: CGSize) {
        rotAngle = offset // Get the width and height components of the CGSize, which only gives us two, and put them into the x and y rotations of the flashlight
    }
    
 

  
}

//====================================================================
//
// Created by: Nathan Dong, Sepehr Mansouri, Jeff Phan
// COMP 8051  British Columbia Institute of Technology
// Assignment02: Generates a maze and draws it in scenekit, provides functions for day/night toggle, 2d minimap toggle, fog parameters, movement and flashlight.
// Created from a Lab04 Template provided by Borna Noureddin. Maze generation code provided by Borna Noureddin.
//====================================================================

import SceneKit
import SwiftUI
import SpriteKit


class MazeAssignment: SCNScene {
    var rotAngle = CGSize.zero // Keep track of drag gesture numbers
    var rot = CGSize.zero // Keep track of rotation angle
    var isRotating = true // Keep track of if rotation is toggled
    var cameraNode = SCNNode() // Initialize camera node
    var mazeSize = Int32(6)
    var toggleMap = true
    
    var isDay: Bool = true
    var initPlayerPosition = SCNVector3(-4.8, 0.6, -3)
    var initPlayerDirection = SCNVector3(0, -Float.pi/2, 0)
    var initCubePosition = SCNVector3(-2.5, 0.6, -3)

    
    // Light
    var diffuseLightPos = SCNVector4(0, 10, 0, Double.pi/2) // Keep track of flashlight position
    var isAmbientLightOn = false
    var ambientLightColorDay = UIColor.white
    var ambientLightColorNight = UIColor.blue
    var ambientLightIntensity = CGFloat(500)
    var ambientLightIntensityNight = CGFloat(100)
    
    //Flashlight
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
        toggleMinimap()
        // setupFlashlight()
        setupPlayerFlashlight()
        setupAmbientLight()
        setupDirectionalLight()
        setLightBasedOnIsDay()
        setupFog()
        addCube()
        Task(priority: .userInitiated) {
            await firstUpdate()
        }
    }
    
    //Draws a maze in 3d based on the CPP maze generation code
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
    
    //Toggles a translucent 2d minimap
    func toggleMinimap(){
        toggleMap = !toggleMap
            if let map = rootNode.childNode(withName: "minimap", recursively: true) {
                if (toggleMap){
                    map.opacity = 100.0
                }else{
                    map.opacity = 0.0
                }
            } else {
                // Handle the case where "The Maze" node is not found
                print("Cant find maze!")
                return
            }
        }
    
    
    //Draws a 2d minimap based on the generated maze
    func addMinimap(maze: inout Maze) {
        let minimapBaseSize: CGFloat = 0.9
        let wallHeight: CGFloat = 0.1
        let offset = 0.52
        
        let minimapBase = SCNNode(/*geometry: SCNPlane(width: minimapBaseSize, height: minimapBaseSize)*/)
        minimapBase.name = "minimap"
        
        //Set the camera as the parent so the minimap follows the camera.
        let cameraNode = rootNode.childNode(withName: "CameraNode", recursively: true)
        cameraNode?.addChildNode(minimapBase)

        minimapBase.position = SCNVector3(0.15,0,-2)
    
        // Calculate cell size based on maze size and minimap base size
        let cellSize = minimapBaseSize / CGFloat(mazeSize)
        
        for row in 0..<mazeSize {
            for col in 0..<mazeSize {
                let mazeCell = maze.GetCell(row, col)
                let cellX = Float(col) * Float(cellSize)
                let cellY = Float(row) * Float(cellSize)
                
                //Draw the cell
                let cellGeometry = SCNPlane(width: cellSize, height: cellSize)
                cellGeometry.firstMaterial?.diffuse.contents = UIColor.gray
                let cellNode = SCNNode(geometry: cellGeometry)
                cellNode.opacity = 0.7
                cellNode.position = SCNVector3(Double(cellX) - offset, Double(cellY), 0.0)
                minimapBase.addChildNode(cellNode)
                cellNode.eulerAngles = SCNVector3(Float.pi, Float.pi, Float.pi/2) // Match base orientation
                
                //Draw walls around the cell
                if mazeCell.northWallPresent {
                    let wall = SCNPlane(width: cellSize*0.15, height: cellSize)
                    wall.firstMaterial?.diffuse.contents = UIColor.red
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(cellSize/2,0,0.01)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.southWallPresent {
                    let wall = SCNPlane(width: cellSize*0.15, height: cellSize)
                    wall.firstMaterial?.diffuse.contents = UIColor.red
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(-cellSize/2,0,0.01)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.eastWallPresent {
                    let wall = SCNPlane(width: cellSize, height: cellSize*0.15)
                    wall.firstMaterial?.diffuse.contents = UIColor.red
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(0,cellSize/2,0.01)
                    cellNode.addChildNode(wallNode)
                }
                if mazeCell.westWallPresent {
                    let wall = SCNPlane(width: cellSize, height: cellSize*0.15)
                    wall.firstMaterial?.diffuse.contents = UIColor.red
                    let wallNode = SCNNode(geometry: wall)
                    wallNode.position = SCNVector3(0,-cellSize/2,0.01)
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

    //Draws a wall given the parameters as a SCNPlane
    func createWall(position: SCNVector3, eulerAngles: SCNVector3, left: Bool, right: Bool) -> SCNNode {
        let wall = SCNPlane(width: 1.0, height: 1.0)
        wall.materials = [wallMaterial(left: left, right: right)]
        wall.firstMaterial?.isDoubleSided = true
        
        let wallNode = SCNNode(geometry: wall)
        wallNode.position = position
        wallNode.eulerAngles = eulerAngles
        
        
        return wallNode
    }

    //Creates a set of maze parameters based on the walls present in the maze cell and sends it to createWall
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
        cameraNode.position = SCNVector3(-4.8, 0.6, -3) // Set the position to (5, 5, 5)
        cameraNode.camera?.zNear = 0.1
        cameraNode.eulerAngles = SCNVector3(0, -Float.pi/2, 0) // Set the pitch, yaw, and roll
//        cameraNode.camera?.fieldOfView = 100
        cameraNode.name = "CameraNode"
        rootNode.addChildNode(cameraNode) // Add the cameraNode to the scene
    }
    
    // Create Cube
    func addCube() {
        let theCube = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)) // Create a object node of box shape with width of 1 and height of 1
        theCube.name = "The Cube" // Name the node so we can reference it later
        theCube.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "crate.png") // Diffuse the crate image material across the whole cube
        theCube.position = initCubePosition // Put the cube at position (0, 0, 0)
        rootNode.addChildNode(theCube) // Add the cube node to the scene
    }
    
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
        let theCube = rootNode.childNode(withName: "The Cube", recursively: true)
        rot.width += 0.05 // Increment rotation of the cube by 0.0005 radians
                
        theCube?.eulerAngles = SCNVector3(Double(rot.height / 50), Double(rot.width / 50), 0) // Set the cube rotation to the numbers given from the drag gesture
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
        
        print(offset.width)
        print(offset.height)
        
        if offset.width > 10.0 {
            // Rotate the camera
            let rotation = SCNAction.rotateTo(x: 0, y: CGFloat(cameraNode.eulerAngles.y) - offset.width/5000, z: 0, duration: 0)
            cameraNode.runAction(rotation)
        } else if offset.width < -10.0 {
            // Rotate the camera to the left
            let rotation = SCNAction.rotateTo(x: 0, y: CGFloat(cameraNode.eulerAngles.y) - offset.width/5000, z: 0, duration: 0)
            cameraNode.runAction(rotation)
        } else if offset.height < CGFloat(-5.0) {
            
            let cameraSpeed: Float = 0.05 // Adjust the speed as needed
            
            // Calculate the movement vector based on the camera's rotation
            let xMovement = -sin(cameraNode.eulerAngles.y) * cameraSpeed
            let zMovement = -cos(cameraNode.eulerAngles.y) * cameraSpeed
            
            // Move the camera
            cameraNode.position.x += Float(CGFloat(xMovement))
            cameraNode.position.z += Float(CGFloat(zMovement))
        } else if offset.height > CGFloat(5.0) {
            
            let cameraSpeed: Float = 0.05
            
            let xMovement = -sin(cameraNode.eulerAngles.y) * cameraSpeed
            let zMovement = -cos(cameraNode.eulerAngles.y) * cameraSpeed
            
            cameraNode.position.x -= Float(CGFloat(xMovement))
            cameraNode.position.z -= Float(CGFloat(zMovement))
        }

    }
}

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }

    func normalized() -> SCNVector3 {
        let len = length()
        if len != 0 {
            return SCNVector3(x / len, y / len, z / len)
        } else {
            return SCNVector3(0, 0, 0)
        }
    }
}

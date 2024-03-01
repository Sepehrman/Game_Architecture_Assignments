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
    var initPlayerPosition = SCNVector3(-4.8, 0.6, -3)
    var initPlayerDirection = SCNVector3(0, -Float.pi/2, 0)
    var initCubePosition = SCNVector3(-2.5, 0.6, -3)

    
    
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
        addCube()
        Task(priority: .userInitiated) {
            await firstUpdate()
        }
    }
    
    func drawMaze(){
        var maze : Maze = Maze(mazeSize, mazeSize)
        maze.Create()
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
        cameraNode.position = SCNVector3(-4.8, 0.6, -3) // Set the position to (5, 5, 5)
        cameraNode.camera?.zNear = 0.1
        cameraNode.eulerAngles = SCNVector3(0, -Float.pi/2, 0) // Set the pitch, yaw, and roll
//        cameraNode.camera?.fieldOfView = 100
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

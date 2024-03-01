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
        //addCube()
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
    }
    
    @MainActor
    // Function to be called by drag gesture
    func handleDrag(offset: CGSize) {
        rotAngle = offset // Get the width and height components of the CGSize, which only gives us two, and put them into the x and y rotations of the flashlight
    }
    
  
}

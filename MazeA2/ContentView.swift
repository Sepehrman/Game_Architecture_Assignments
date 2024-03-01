//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Lab01: Draw red square using SceneKit
// Lab02: Make an auto-rotating cube with different colours on each side
// Lab03: Make a rotating cube with a crate texture that can be toggled
// Lab04: Make a cube that can be rotated with gestures
//
//====================================================================

import SwiftUI
import SceneKit
import SpriteKit

struct ContentView: View {
    
    let scene = ControlableRotatingCrate()
    let overlayScene = MapOverlayScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    
    @State var rotationOffset = CGSize.zero
    @State var overlayIsHidden = true   // Initially hide overlay
    
    // Phone orientation
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var numberOfTouches = 0
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink{
                    ZStack {
                        SceneView(scene: scene, pointOfView: scene.cameraNode)
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                        
                        
                        SCNOverlayView(overlayScene: overlayScene)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                            .opacity(overlayIsHidden ? 0 : 1)
                            .onRotate {
                                newOrientation in orientation = newOrientation
                                print("rotate ")
                                overlayScene.resizeOverlay(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                            }.overlay(UIKitTwoFingerDoubleTapGesture {
                                // Double Tap 2 Fingers
                                // Toggle the Map here
                                scene.toggleMinimap()
                                //overlayIsHidden.toggle()  // Toggle overlay visibility
                                print("Two Finger Double Tap on Overlay")
                            }
                        )

                    }.ignoresSafeArea()
                        .gesture(
                            DragGesture()
                                .onChanged{ gesture in
                                    scene.handleDrag(offset: gesture.translation)
                                }
                        )
                        .onTapGesture(count: 2) {
                            // Double Tap 1 Finger
                            print("Double Tap")
                        }
                        
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .background(Color.black.opacity(0.3)) // Semi-transparent background
                    
                    Button(action: scene.handleDoubleTap) {
                        Text("Toggle Day/Night")
                    }
                } label: { Text("Maze") }
            }.navigationTitle("COMP8051")
        }
    }
}

struct SCNOverlayView: UIViewRepresentable {
    let overlayScene: SKScene
    
    init(overlayScene: SKScene) {
        self.overlayScene = overlayScene
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene()
        scnView.backgroundColor = UIColor.clear
        scnView.delegate = context.coordinator // Set delegate to access SCNView callbacks
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.overlaySKScene == nil {
            uiView.overlaySKScene = overlayScene
            print("Overlay scene set")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SCNSceneRendererDelegate {
        func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
//            print("Overlay rendered")
        }
    }
}

// Rotation Functionality taken from https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

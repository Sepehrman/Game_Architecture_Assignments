//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Lab01: Draw red square using SceneKit
// Lab02: Make an auto-rotating cube with different colours on each side
// Lab03: Make a rotating cube with a crate texture that can be toggled
// Lab04: Make a cube that can be rotated with gestures
// Lab05: Add text that shows rotation angle of rotating cube
// Lab06: Add diffuse light
// Lab07: Add flashlight
// Lab08: Add fog
// Lab09: Load models with animations
// PinchView: Process touches using UIKit to recognize a pinch gesture
// TwoFigureDragView: Process touches using UIKit to recognize a two-fingure drag gesture
// TapView: Process multi-touch taps
//
//====================================================================

import SwiftUI
import SceneKit
import SpriteKit

// We separate out the Button whose text will change so that we only update the button and not the whole ContentView when
//  the text changes
//struct ChangeableButton: View {
//    @State var rotationOffset = CGSize.zero
//
//    var body: some View {
//        
//        withObservationTracking {   // This is what tracks the observed property of modelScene and refreshes when it changes
//
//            Button(action: {
//
//                modelScene.toggleAnimation()
//
//            }, label: {
//
//                Text(modelScene.buttonText)
//                    .font(.system(size: 24))
//                    .padding(.bottom, 50)
//
//            })
//
//        }
//        onChange: {}
//    }
//}

struct ContentView: View {

    @State private var circleLocations: [CGPoint]?
    @State private var pinchCircles = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)]
    @State public var overlayIsHidden = false
    
    let overlayScene: OverlayScene = OverlayScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))

    var body: some View {
        NavigationStack {
                
                    let scene = Box2DDemo()
//                    scene.overlayScene = overlayScene // Set the overlay scene property
                    ZStack {
                        VStack {
                            SceneView(scene: scene, pointOfView: scene.cameraNode)
                                    .ignoresSafeArea()
                                    .overlay(SKOverlayView(overlayScene: overlayScene)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .edgesIgnoringSafeArea(.all)
                                        .opacity(overlayIsHidden ? 0 : 1)
                                    )
                                .onTapGesture(count: 2) {
                                    scene.handleDoubleTap()
                                }.gesture(
                                    DragGesture().onChanged{ gesture in
                                        scene.movePaddle(offset: gesture.translation)
                                    }
                                )
                            Button(action: {
                                scene.resetPhysics()
                            }, label: {
                                Text("Reset")
                                    .font(.system(size: 24))
                                    .padding(.bottom, 50)
                            })
                        }
                    }
                    .onAppear {
                            scene.overlayScene = overlayScene // Set the overlay scene property
                        }
                    .background(.black)
        }
    }
}

struct SKOverlayView: UIViewRepresentable {
    let overlayScene: SKScene
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.presentScene(overlayScene)
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Update if needed
    }
}

#Preview {
    ContentView()
}

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
    
    let overlayScene = OverlayScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ZStack {
                        PinchView { touches in
//                            print("Pinch: \(touches[0].x), \(touches[0].y) | \(touches[1].x), \(touches[1].y)")
                            // store the locations in an array we'll use later to draw the circles
                            // you can do any other processing needed here
                            pinchCircles[0] = touches[0]
                            pinchCircles[1] = touches[1]
                        }
                        Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .position(x: pinchCircles[0].x, y: pinchCircles[0].y)
                        Circle()
                        .fill(Color.green)
                        .frame(width: 20, height: 20)
                        .position(x: pinchCircles[1].x, y: pinchCircles[1].y)
                    }
                } label: { Text("Pinch") }
                NavigationLink {
                    ZStack {
                        TwoFigureDragView { touches in
//                            print("Pinch: \(touches[0].x), \(touches[0].y) | \(touches[1].x), \(touches[1].y)")
                            // store the locations in an array we'll use later to draw the circles
                            // you can do any other processing needed here
                            pinchCircles[0] = touches[0]
                            pinchCircles[1] = touches[1]
                        }
                        // draw the two circles
                        Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .position(x: pinchCircles[0].x, y: pinchCircles[0].y)
                        Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .position(x: pinchCircles[1].x, y: pinchCircles[1].y)
                    }
                } label: { Text("Two Finger Drag") }
                NavigationLink {
                    ZStack {
                        TapView(requiredTouches: 3) { touches, locations, state in
                            print("Touch: \(String(describing: touches?.count)) fingers \(state)")
                            self.circleLocations = locations
                        }
                        if (circleLocations != nil) {
                            ForEach(0..<circleLocations!.count, id: \.self) { index in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: 20)
                                    .position(circleLocations![index])
                            }
                        }
                    }
                } label: { Text("Multitap") }
                NavigationLink {
                    let scene = Box2DDemo()
//                    self.overlayIsHidden.
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
                    .background(.black)
                } label: { Text("Lab 10: Box2D") }
                    .onSubmit {
                        print("Submit")
                    }
            }.navigationTitle("COMP8051")
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

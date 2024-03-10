//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// PinchView: Process touches using UIKit to recognize a pinch gesture
//
//====================================================================

import Foundation
import UIKit
import SwiftUI

// Class derived from UIGestureRecognizer
class NPinchGestureRecognizer: UIGestureRecognizer {

    var tappedCallback: ([CGPoint]) -> Void     // callback taking the location of the two fingers as a single argument

    init(target: Any?, tappedCallback: @escaping ([CGPoint]) -> ()) {
        self.tappedCallback = tappedCallback
        super.init(target: target, action: nil)
    }

    // We only need to override the move since all we care about is when the two fingers are moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if (touches.count == 2) {   // make sure we only process when two fingers are detected simultaneously
            // Put the location of both touches in an array and pass it to our callback
            var touchViews = [CGPoint]()
            for touch in touches {
                touchViews.append(touch.location(in: self.view))
            }
            tappedCallback(touchViews)
        }
    }

}

// Our view has to derive from UIViewRepresentable to work
struct PinchView: UIViewRepresentable {

    var tappedCallback: ([CGPoint]) -> Void     // callback taking the location of the two fingers as a single argument

    func makeUIView(context: UIViewRepresentableContext<PinchView>) -> PinchView.UIViewType {
        let v = UIView(frame: .zero)
        // add our custom gesture recognizer above
        let gesture = NPinchGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PinchView>) {
        // empty
    }

}

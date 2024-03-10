//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// TwoFigureDragView: Process touches using UIKit to recognize a two-fingure drag gesture
//
//====================================================================

import Foundation
import UIKit
import SwiftUI

// Class derived from UIGestureRecognizer
class NTwoFigureTapGestureRecognizer: UIGestureRecognizer {

    var tappedCallback: ([CGPoint]) -> Void     // callback taking the location of the two fingers as a single argument
    var lastLocations = [CGPoint]()             // store last location to make sure we only catch the gesture when both fingers move together

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
            // We want to make sure we only process the move if the two fingers have stayed roughly
            //  the same distance from each other
            var processMove = false
            if (lastLocations.isEmpty) {
                processMove = true
            } else {
                let dx1 = touchViews[0].x - lastLocations[0].x
                let dx2 = touchViews[1].x - lastLocations[1].x
                let dy1 = touchViews[0].y - lastLocations[0].y
                let dy2 = touchViews[1].y - lastLocations[1].y
                if ((abs(dx1-dx2) < 2) && (abs(dy1-dy2) < 2)) { // hard-coded "tolerance"
                    processMove = true
                }
            }
            lastLocations = touchViews
            if (processMove) {
                tappedCallback(touchViews)
            }
        }
    }

}

// Our view has to derive from UIViewRepresentable to work
struct TwoFigureDragView: UIViewRepresentable {

    var tappedCallback: ([CGPoint]) -> Void     // callback taking the location of the two fingers as a single argument

    func makeUIView(context: UIViewRepresentableContext<TwoFigureDragView>) -> TwoFigureDragView.UIViewType {
        let v = UIView(frame: .zero)
        // add our custom gesture recognizer above
        let gesture = NTwoFigureTapGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TwoFigureDragView>) {
        // empty
    }

}

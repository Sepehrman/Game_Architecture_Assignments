//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// TapView: Process multi-touch taps
//
//====================================================================

import Foundation
import UIKit
import SwiftUI

// State of touch phase
enum TouchState {
    case began, moved, ended;
}

// Class derived from UIGestureRecognizer
class NFingerGestureRecognizer: UIGestureRecognizer {

    var tappedCallback: ([UITouch]?, [CGPoint]?, TouchState) -> Void

    var requiredTouches = 1                 // default to single touch (public, so can be changed oustide the class)
    private var touchList = [UITouch]()     // list of touch events
    private var touchViews = [CGPoint]()    // list of locations of touches
    private var gestureStarted = false
    private var numTouches = 0

    init(target: Any?, tappedCallback: @escaping ([UITouch]?, [CGPoint]?, TouchState) -> ()) {
        self.tappedCallback = tappedCallback
        super.init(target: target, action: nil)
    }

    // Register the start of a touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if (!gestureStarted) {  // if we didn't catch the end of the last touch, just ignore this until we do
            if ((touchList.count + touches.count) > requiredTouches) {
                touchList.removeAll()
                touchViews.removeAll()
            }
            for touch in touches {
                touchList.append(touch)
                touchViews.append(touch.location(in: self.view))
            }
            if (touchList.count == requiredTouches) {   // only process if we have caught the required # of touches
                tappedCallback(touchList, touchViews, TouchState.began)
                gestureStarted = true
                numTouches = touches.count
                touchList.removeAll()
                touchViews.removeAll()
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if (gestureStarted) {
            var touchViews = [CGPoint]()
            for touch in touches {
                touchViews.append(touch.location(in: self.view))
            }
            tappedCallback(touchList, touchViews, TouchState.moved)
        } else {
//            print("---Moved without start with \(touches.count) touches")   // DEBUG
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if (gestureStarted) {
            if ((touchList.count + touches.count) > numTouches) {
                touchList.removeAll()
                touchViews.removeAll()
            }
            for touch in touches {
                touchList.append(touch)
                touchViews.append(touch.location(in: self.view))
            }
            if (touchList.count == numTouches) {
                tappedCallback(touchList, touchViews, TouchState.began)
                gestureStarted = false
                numTouches = 0
            }
        } else {
//            print("---Ended without start with \(touches.count) touches")   // DEBUG
        }
    }

}

struct TapView: UIViewRepresentable {

    var requiredTouches = 3     // set this to the number of fingers required
    var tappedCallback: ([UITouch]?, [CGPoint]?, TouchState) -> Void

    func makeUIView(context: UIViewRepresentableContext<TapView>) -> TapView.UIViewType {
        let v = UIView(frame: .zero)
        // add our custom gesture recognizer above
        let gesture = NFingerGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        gesture.requiredTouches = self.requiredTouches
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TapView>) {
    }

}

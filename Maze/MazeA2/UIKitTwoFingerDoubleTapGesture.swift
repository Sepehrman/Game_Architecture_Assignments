//
//  UIKitTwoFingerDoubleTapGesture.swift
//  MazeA2
//
//  Created by Nathan Dong on 2024-02-29.
//

import SwiftUI

struct UIKitTwoFingerDoubleTapGesture: UIViewRepresentable {
    var onDoubleTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        tapGesture.numberOfTouchesRequired = 2
        tapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: UIKitTwoFingerDoubleTapGesture

        init(_ parent: UIKitTwoFingerDoubleTapGesture) {
            self.parent = parent
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            parent.onDoubleTap()
        }
    }
}

//
//  CameraPreview.swift
//  FoodShutter
//
//  UIViewRepresentable wrapper for camera preview
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let camera: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer

        // Add tap gesture for focus
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(camera: camera)
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        let camera: CameraManager

        init(camera: CameraManager) {
            self.camera = camera
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let previewLayer = previewLayer else { return }
            let location = gesture.location(in: gesture.view)
            let convertedPoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
            camera.focus(at: convertedPoint)

            // Show focus animation
            showFocusAnimation(at: location, in: gesture.view)
        }

        private func showFocusAnimation(at point: CGPoint, in view: UIView?) {
            guard let view = view else { return }

            let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            focusView.center = point
            focusView.backgroundColor = .clear
            focusView.layer.borderColor = UIColor(Color.mainEnable).cgColor
            focusView.layer.borderWidth = 4
            focusView.layer.cornerRadius = 40
            focusView.alpha = 0

            view.addSubview(focusView)

            UIView.animate(withDuration: 0.3, animations: {
                focusView.alpha = 1
                focusView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 0.5, animations: {
                    focusView.alpha = 0
                }) { _ in
                    focusView.removeFromSuperview()
                }
            }
        }
    }
}

//
//  CameraPreviewView.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

//  CameraPreviewView.swift
//  Vertix

//  CameraPreviewView.swift
//  Vertix

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Layout is handled automatically by PreviewView
    }
}

// Custom UIView that correctly sizes the preview layer
class PreviewView: UIView {

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds  // updates every time view resizes
    }
}

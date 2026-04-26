//
//  CameraViewModel.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

//  CameraViewModel.swift
//  Vertix


import AVFoundation
import SwiftUI
import MediaPipeTasksVision

class CameraViewModel: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let poseDetector = PoseDetector()

    @Published var landmarks: [[NormalizedLandmark]] = []

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            print("❌ No front camera found")
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Could not create input")
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "videoQueue")
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        videoOutput.connections.first?.isVideoMirrored = true

        session.commitConfiguration()
        print("✅ Session configured")
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            print("▶️ Session running: \(self.session.isRunning)")
        }
    }

    func stopSession() {
        session.stopRunning()
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        poseDetector.detect(sampleBuffer: sampleBuffer, timestamp: timestamp)
    }
}

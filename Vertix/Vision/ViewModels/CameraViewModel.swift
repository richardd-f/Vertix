//  CameraViewModel.swift
//  Vertix

import AVFoundation
import SwiftUI
import Combine
import MediaPipeTasksVision

class CameraViewModel: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let poseDetector = PoseDetector()

    @Published var landmarks: [[NormalizedLandmark]] = []
    @Published var postureResult: PostureResult?

    private var badPostureStartTime: Date?
    private let badPostureThreshold: TimeInterval = 5.0

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

        if session.canAddInput(input) { session.addInput(input) }

        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "videoQueue")
        )
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoRotationAngle = 90
            connection.isVideoMirrored = true
        }

        poseDetector.delegate = self
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

extension CameraViewModel: PoseDetectorDelegate {
    func poseDetector(_ detector: PoseDetector, didDetect landmarks: [[NormalizedLandmark]]) {
        DispatchQueue.main.async {
            self.landmarks = landmarks
            if let firstPose = landmarks.first {
                let result = PostureAnalyzer.analyze(landmarks: firstPose)
                self.postureResult = result

                if let result {
                    if result.isGoodPosture {
                        self.badPostureStartTime = nil
                    } else {
                        if self.badPostureStartTime == nil {
                            self.badPostureStartTime = Date()
                        } else if let start = self.badPostureStartTime,
                                  Date().timeIntervalSince(start) >= self.badPostureThreshold {
                            WatchConnectivityManager.shared.sendPostureAlert(feedback: result.feedback)
                            self.badPostureStartTime = nil
                        }
                    }
                }
            }
        }
    }
}

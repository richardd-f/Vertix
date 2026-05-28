//  CameraViewModel.swift
//  Vertix

import AVFoundation
import SwiftUI
import Combine
import MediaPipeTasksVision

class CameraViewModel: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var poseDetector: PoseDetector?
    private var isConfigured = false

    @Published var landmarks: [[NormalizedLandmark]] = []
    @Published var postureResult: PostureResult?

    override init() {
        super.init()
    }

    private func setupCamera() {
        guard !isConfigured else { return }
        isConfigured = true

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
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }

        let detector = PoseDetector()
        detector.delegate = self
        poseDetector = detector

        session.commitConfiguration()
        print("✅ Session configured")
    }

    func startSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    print("❌ Camera access denied")
                    return
                }
                self?.configureAndRun()
            }
        default:
            print("❌ Camera access not authorized")
        }
    }

    private func configureAndRun() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCamera()
            if !self.session.isRunning {
                self.session.startRunning()
            }
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
        poseDetector?.detect(sampleBuffer: sampleBuffer, timestamp: timestamp)
    }
}

extension CameraViewModel: PoseDetectorDelegate {
    func poseDetector(_ detector: PoseDetector, didDetect landmarks: [[NormalizedLandmark]]) {
        DispatchQueue.main.async {
            self.landmarks = landmarks
            if let firstPose = landmarks.first {
                self.postureResult = PostureAnalyzer.analyze(landmarks: firstPose)
            }
        }
    }
}

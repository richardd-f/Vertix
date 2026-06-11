//  CameraViewModel.swift
//  Vertix

import AVFoundation
import SwiftUI
import Combine
import MediaPipeTasksVision

class CameraViewModel: NSObject, ObservableObject {
    
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var poseDetector: PoseDetector?
    private var isConfigured = false

    @Published var landmarks: [[NormalizedLandmark]] = []
    @Published var postureResult: PostureResult?
    /// True when the user has denied/restricted camera access — drives the permission UI.
    @Published var permissionDenied: Bool = false
    
    #if targetEnvironment(simulator)
    private var mockTimer: Timer?
    #endif

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

        #if targetEnvironment(simulator)
            startMockSession()
            return
        #endif
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setPermissionDenied(false)
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    print("❌ Camera access denied")
                    self?.setPermissionDenied(true)
                    return
                }
                self?.setPermissionDenied(false)
                self?.configureAndRun()
            }
        default:
            print("❌ Camera access not authorized")
            setPermissionDenied(true)
        }
    }

    private func setPermissionDenied(_ denied: Bool) {
        DispatchQueue.main.async { self.permissionDenied = denied }
    }

    private func configureAndRun() {
        #if targetEnvironment(simulator)
        print("🖥️ Running in Simulator - camera disabled")
        return
        #else
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCamera()
            if !self.session.isRunning {
                self.session.startRunning()
            }
            print("Session running: \(self.session.isRunning)")
        }
        #endif
    }

    func stopSession() {

        #if targetEnvironment(simulator)
            mockTimer?.invalidate()
            mockTimer = nil
        #else
            session.stopRunning()
        #endif
    }
        
    #if targetEnvironment(simulator)

    private func startMockSession() {

        mockTimer?.invalidate()

        mockTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in

            let good = Bool.random()

            DispatchQueue.main.async {

                self?.postureResult = PostureResult(
                    neckAngle: good ? 8 : 28,
                    shoulderTilt: good ? 2 : 10,
                    spineAngle: good ? 7 : 20,
                    isGoodPosture: good,
                    feedback: good
                        ? "Good posture"
                        : "Sit upright and align your shoulders"
                )
            }
        }
    }

    #endif
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

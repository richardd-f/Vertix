//
//  PoseDetector.swift
//  Vertix
//
//  Created by Felicia Sword on 26/04/26.
//

//  PoseDetector.swift
//  Vertix
import MediaPipeTasksVision
import CoreVideo

protocol PoseDetectorDelegate: AnyObject {
    func poseDetector(_ detector: PoseDetector, didDetect landmarks: [[NormalizedLandmark]])
}

class PoseDetector: NSObject {

    private var poseLandmarker: PoseLandmarker?
    weak var delegate: PoseDetectorDelegate?

    override init() {
        super.init()
        setupPoseLandmarker()
    }

    private func setupPoseLandmarker() {
        guard let modelPath = Bundle.main.path(
            forResource: "pose_landmarker_lite",
            ofType: "task"
        ) else {
            print("❌ Could not find pose_landmarker_lite.task model")
            return
        }

        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numPoses = 1
        options.poseLandmarkerLiveStreamDelegate = self

        do {
            poseLandmarker = try PoseLandmarker(options: options)
            print("✅ PoseLandmarker initialized")
        } catch {
            print("❌ Failed to initialize PoseLandmarker: \(error)")
        }
    }

    func detect(sampleBuffer: CMSampleBuffer, timestamp: Int) {
        guard let poseLandmarker else { return }
        guard let image = try? MPImage(sampleBuffer: sampleBuffer) else { return }
        try? poseLandmarker.detectAsync(image: image, timestampInMilliseconds: timestamp)
    }
}

extension PoseDetector: PoseLandmarkerLiveStreamDelegate {
    func poseLandmarker(
        _ poseLandmarker: PoseLandmarker,
        didFinishDetection result: PoseLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        if let error {
            print("❌ Detection error: \(error)")
            return
        }
        guard let result else { return }
        delegate?.poseDetector(self, didDetect: result.landmarks)
    }
}

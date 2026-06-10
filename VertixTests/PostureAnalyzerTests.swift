import Foundation
import CoreGraphics
import Testing
@testable import Vertix

@Suite("PostureAnalyzer")
struct PostureAnalyzerTests {

    // MARK: - Helper
    // Run the pure posture logic from plain points (no camera / MediaPipe needed).
    // Coordinates are normalized 0...1 and y grows downward (0 = top of frame).

    private func evaluate(
        leftShoulder: (CGFloat, CGFloat),
        rightShoulder: (CGFloat, CGFloat),
        leftEar: (CGFloat, CGFloat),
        rightEar: (CGFloat, CGFloat),
        leftHip: (CGFloat, CGFloat),
        rightHip: (CGFloat, CGFloat)
    ) -> PostureResult {
        PostureAnalyzer.evaluate(
            leftShoulder:  CGPoint(x: leftShoulder.0,  y: leftShoulder.1),
            rightShoulder: CGPoint(x: rightShoulder.0, y: rightShoulder.1),
            leftEar:       CGPoint(x: leftEar.0,       y: leftEar.1),
            rightEar:      CGPoint(x: rightEar.0,      y: rightEar.1),
            leftHip:       CGPoint(x: leftHip.0,       y: leftHip.1),
            rightHip:      CGPoint(x: rightHip.0,      y: rightHip.1)
        )
    }

    private func goodPosture() -> PostureResult {
        evaluate(
            leftShoulder:  (0.40, 0.50),
            rightShoulder: (0.60, 0.50),   // level with the left shoulder
            leftEar:       (0.45, 0.30),
            rightEar:      (0.55, 0.30),   // ears centered above shoulders
            leftHip:       (0.42, 0.80),
            rightHip:      (0.58, 0.80)    // hips centered below shoulders
        )
    }

    // MARK: - Error handling

    @Test("rejects incomplete pose data (error handling)")
    func rejectsIncompletePose() {
        // The analyzer reads up to landmark #24, so anything fewer is rejected.
        #expect(!PostureAnalyzer.hasEnoughLandmarks(10)) // too few -> analyze() returns nil
        #expect(PostureAnalyzer.hasEnoughLandmarks(33))  // a full MediaPipe pose is fine
    }

    // MARK: - Good posture

    @Test("detects good posture when neck, shoulders and spine are aligned")
    func detectsGoodPosture() {
        let result = goodPosture()
        #expect(result.isGoodPosture == true)
        #expect(result.feedback == "Great posture! Keep it up 💪")
    }

    @Test("good posture keeps all three angles under their thresholds")
    func goodPostureAnglesUnderThreshold() {
        let result = goodPosture()
        #expect(result.neckAngle < 20)
        #expect(result.shoulderTilt < 5)
        #expect(result.spineAngle < 15)
    }

    // MARK: - Bad posture

    @Test("flags uneven shoulders, and only that issue")
    func flagsUnevenShouldersOnly() {
        // Right shoulder dropped lower than the left; neck + spine kept straight.
        let result = evaluate(
            leftShoulder:  (0.40, 0.50),
            rightShoulder: (0.60, 0.60),   // 0.10 lower -> tilt ~10 (threshold 5)
            leftEar:       (0.45, 0.35),
            rightEar:      (0.55, 0.35),
            leftHip:       (0.42, 0.80),
            rightHip:      (0.58, 0.80)
        )
        #expect(result.isGoodPosture == false)
        #expect(result.feedback == "Fix: shoulders uneven")
    }

    @Test("flags all three issues when fully slouched")
    func flagsAllIssuesWhenSlouched() {
        let result = evaluate(
            leftShoulder:  (0.40, 0.50),
            rightShoulder: (0.60, 0.62),   // uneven shoulders
            leftEar:       (0.72, 0.35),
            rightEar:      (0.78, 0.35),   // head jutting forward (neck)
            leftHip:       (0.30, 0.80),
            rightHip:      (0.50, 0.80)    // hips offset from shoulders (spine)
        )
        #expect(result.isGoodPosture == false)
        #expect(result.feedback == "Fix: head tilting forward, shoulders uneven, spine not straight")
    }

    // MARK: - Shoulder tilt direction (the bug fix)

    @Test("shoulderTilt is the magnitude of the signed tilt, and direction is kept")
    func shoulderTiltKeepsDirection() {
        // Left shoulder higher (smaller y) than right -> signed value is negative.
        let result = evaluate(
            leftShoulder:  (0.40, 0.50),
            rightShoulder: (0.60, 0.60),
            leftEar:       (0.45, 0.35),
            rightEar:      (0.55, 0.35),
            leftHip:       (0.42, 0.80),
            rightHip:      (0.58, 0.80)
        )
        #expect(result.shoulderTilt == abs(result.shoulderTiltSigned)) // magnitude matches
        #expect(result.shoulderTiltSigned < 0)                          // direction preserved
    }
}

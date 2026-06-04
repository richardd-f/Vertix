//  PostureAnalyzer.swift
//  Vertix

import MediaPipeTasksVision
import CoreGraphics

struct PostureResult {
    var neckAngle: Double
    var shoulderTilt: Double
    /// Signed shoulder tilt: negative = left shoulder lower (tilt left),
    /// positive = right shoulder lower (tilt right). `shoulderTilt` is its magnitude.
    var shoulderTiltSigned: Double
    var spineAngle: Double
    var isGoodPosture: Bool
    var feedback: String
}

struct PostureAnalyzer {

    /// MediaPipe returns 33 landmarks; we read up to index 24, so we need at least 25.
    static func hasEnoughLandmarks(_ count: Int) -> Bool {
        count > 24
    }

    // MARK: - MediaPipe adapter
    // Thin layer that pulls the joints we care about out of MediaPipe's landmark
    // array, then hands plain points to the pure `evaluate` core below.

    static func analyze(landmarks: [NormalizedLandmark]) -> PostureResult? {
        // Error handling: bail out safely on incomplete pose data.
        guard hasEnoughLandmarks(landmarks.count) else { return nil }

        func point(_ i: Int) -> CGPoint {
            CGPoint(x: CGFloat(landmarks[i].x), y: CGFloat(landmarks[i].y))
        }

        return evaluate(
            leftShoulder:  point(11),
            rightShoulder: point(12),
            leftEar:       point(7),
            rightEar:      point(8),
            leftHip:       point(23),
            rightHip:      point(24)
        )
    }

    // MARK: - Pure posture logic (no MediaPipe — fully unit-testable)

    static func evaluate(
        leftShoulder: CGPoint,
        rightShoulder: CGPoint,
        leftEar: CGPoint,
        rightEar: CGPoint,
        leftHip: CGPoint,
        rightHip: CGPoint
    ) -> PostureResult {
        let midShoulder = midpoint(leftShoulder, rightShoulder)
        let midHip      = midpoint(leftHip, rightHip)
        let midEar      = midpoint(leftEar, rightEar)

        let neckAngle = calculateAngle(from: midShoulder, to: midEar)

        // Preserve direction for the on-screen tilt indicator; magnitude is used
        // for the good/bad threshold. (Front camera is mirrored, so left shoulder
        // lower → person leaning left.)
        let shoulderTiltSigned = Double(leftShoulder.y - rightShoulder.y) * 100
        let shoulderTilt       = abs(shoulderTiltSigned)

        let spineAngle = calculateAngle(from: midHip, to: midShoulder)

        let goodNeck     = neckAngle < 20
        let goodShoulder = shoulderTilt < 5
        let goodSpine    = spineAngle < 15
        let isGood       = goodNeck && goodShoulder && goodSpine

        var issues: [String] = []
        if !goodNeck     { issues.append("head tilting forward") }
        if !goodShoulder { issues.append("shoulders uneven") }
        if !goodSpine    { issues.append("spine not straight") }

        let feedback = isGood
            ? "Great posture! Keep it up 💪"
            : "Fix: \(issues.joined(separator: ", "))"

        return PostureResult(
            neckAngle: neckAngle,
            shoulderTilt: shoulderTilt,
            shoulderTiltSigned: shoulderTiltSigned,
            spineAngle: spineAngle,
            isGoodPosture: isGood,
            feedback: feedback
        )
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func calculateAngle(from: CGPoint, to: CGPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return Double(atan2(abs(dx), abs(dy)) * 180 / .pi)
    }
}

//  PostureAnalyzer.swift
//  Vertix

import MediaPipeTasksVision
import CoreGraphics

struct PostureResult {
    var neckAngle: Double
    var shoulderTilt: Double
    var spineAngle: Double
    var isGoodPosture: Bool
    var feedback: String
}

struct PostureAnalyzer {

    static func analyze(landmarks: [NormalizedLandmark]) -> PostureResult? {
        guard landmarks.count > 24 else { return nil }

        let noseLM           = landmarks[0]
        let leftShoulderLM   = landmarks[11]
        let rightShoulderLM  = landmarks[12]
        let leftHipLM        = landmarks[23]
        let rightHipLM       = landmarks[24]
        let leftEarLM        = landmarks[7]
        let rightEarLM       = landmarks[8]

        let midShoulder = midpoint(leftShoulderLM, rightShoulderLM)
        let midHip      = midpoint(leftHipLM, rightHipLM)
        let midEar      = midpoint(leftEarLM, rightEarLM)

        let neckAngle = calculateAngle(
            from: CGPoint(x: CGFloat(midShoulder.x), y: CGFloat(midShoulder.y)),
            to:   CGPoint(x: CGFloat(midEar.x),      y: CGFloat(midEar.y))
        )

        let shoulderTilt = abs(Double(leftShoulderLM.y - rightShoulderLM.y)) * 100

        let spineAngle = calculateAngle(
            from: CGPoint(x: CGFloat(midHip.x),      y: CGFloat(midHip.y)),
            to:   CGPoint(x: CGFloat(midShoulder.x), y: CGFloat(midShoulder.y))
        )

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
            spineAngle: spineAngle,
            isGoodPosture: isGood,
            feedback: feedback
        )
    }

    private static func midpoint(
        _ a: NormalizedLandmark,
        _ b: NormalizedLandmark
    ) -> (x: Float, y: Float) {
        return ((a.x + b.x) / 2, (a.y + b.y) / 2)
    }

    private static func calculateAngle(from: CGPoint, to: CGPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return Double(atan2(abs(dx), abs(dy)) * 180 / .pi)
    }
}

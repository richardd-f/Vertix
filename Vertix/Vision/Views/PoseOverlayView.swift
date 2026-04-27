//
//  PoseOverlayView.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

//  PoseOverlayView.swift
//  Vertix

import SwiftUI
import MediaPipeTasksVision

struct PoseOverlayView: View {

    let landmarks: [[NormalizedLandmark]]
    let imageSize: CGSize

    // MediaPipe 33 landmark connections (pairs of indices)
    private let connections: [(Int, Int)] = [
        // Face
        (0, 1), (1, 2), (2, 3), (3, 7),
        (0, 4), (4, 5), (5, 6), (6, 8),
        // Shoulders
        (11, 12),
        // Left arm
        (11, 13), (13, 15),
        // Right arm
        (12, 14), (14, 16),
        // Torso
        (11, 23), (12, 24), (23, 24),
        // Left leg
        (23, 25), (25, 27),
        // Right leg
        (24, 26), (26, 28),
    ]

    var body: some View {
        Canvas { context, size in
            guard let pose = landmarks.first else { return }

            // Draw connections (lines)
            for (startIdx, endIdx) in connections {
                guard startIdx < pose.count, endIdx < pose.count else { continue }

                let start = pose[startIdx]
                let end = pose[endIdx]

                let startPoint = CGPoint(
                    x: CGFloat(start.x) * size.width,
                    y: CGFloat(start.y) * size.height
                )
                let endPoint = CGPoint(
                    x: CGFloat(end.x) * size.width,
                    y: CGFloat(end.y) * size.height
                )

                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                context.stroke(path, with: .color(.green), lineWidth: 2.5)
            }

            // Draw landmark dots
            for landmark in pose {
                let point = CGPoint(
                    x: CGFloat(landmark.x) * size.width,
                    y: CGFloat(landmark.y) * size.height
                )
                let dotRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(.yellow))
            }
        }
    }
}

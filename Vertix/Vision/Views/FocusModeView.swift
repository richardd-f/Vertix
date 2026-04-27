//
//  FocusModeView.swift
//  Vertix
//
//  Created by Felicia Sword on 26/04/26.
//
//  FocusModeView.swift
//  Vertix

import SwiftUI

struct FocusModeView: View {

    @StateObject private var camera = CameraViewModel()

    var body: some View {
        ZStack {
            // Layer 1: Camera feed
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Layer 2: Pose skeleton overlay
            GeometryReader { geo in
                PoseOverlayView(
                    landmarks: camera.landmarks,
                    imageSize: geo.size
                )
                .ignoresSafeArea()
            }

            // Layer 3: Feedback UI
            VStack {
                // Top status banner
                if let result = camera.postureResult {
                    HStack(spacing: 12) {
                        Image(systemName: result.isGoodPosture ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.isGoodPosture ? .green : .orange)
                            .font(.title2)

                        Text(result.feedback)
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(14)
                    .padding(.top, 60)
                } else {
                    Text("🔍 Searching for pose...")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(14)
                        .padding(.top, 60)
                }

                Spacer()

                // Bottom angle readouts
                if let result = camera.postureResult {
                    HStack(spacing: 16) {
                        AngleCard(label: "Neck", value: result.neckAngle, threshold: 20)
                        AngleCard(label: "Shoulder", value: result.shoulderTilt, threshold: 5)
                        AngleCard(label: "Spine", value: result.spineAngle, threshold: 15)
                    }
                    .padding(.bottom, 40)
                }
                Button("Test Watch Alert") {
                    WatchConnectivityManager.shared.sendPostureAlert(feedback: "Keep your back straight!")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 20)
            }
        }
        .onAppear { camera.startSession() }
        .onDisappear { camera.stopSession() }
    }
}

// MARK: - Angle Card

struct AngleCard: View {
    let label: String
    let value: Double
    let threshold: Double

    var isGood: Bool { value < threshold }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "%.1f°", value))
                .font(.title3.bold())
                .foregroundColor(isGood ? .green : .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.65))
        .cornerRadius(12)
    }
}

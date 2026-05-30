//
//  WatchRootView.swift
//  VertixWatch
//
//  Shows the Pomodoro timer, phase indicator, and session controls.
//  Matches the Vertix design system: forest green (#2D4F44), cream background.
//

import SwiftUI

// MARK: - Color palette (mirrors Vertix iPhone colors)

private extension Color {
    static let vertixGreen  = Color(red: 45/255,  green: 79/255,  blue: 68/255)
    static let vertixCream  = Color(red: 244/255, green: 242/255, blue: 238/255)
    static let focusGreen   = Color(red: 45/255,  green: 79/255,  blue: 68/255)
    static let shortBlue    = Color(red: 33/255,  green: 150/255, blue: 243/255)
    static let longPurple   = Color(red: 156/255, green: 39/255,  blue: 176/255)
}

private func phaseColor(for phase: String) -> Color {
    switch phase.lowercased() {
    case "short break": return .shortBlue
    case "long break":  return .longPurple
    default:            return .focusGreen
    }
}

private func phaseIcon(for phase: String) -> String {
    switch phase.lowercased() {
    case "short break": return "cup.and.saucer.fill"
    case "long break":  return "figure.walk"
    default:            return "brain.head.profile"
    }
}

// MARK: - Root View

struct WatchRootView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        if session.isSessionActive {
            WatchTimerView()
                .environmentObject(session)
        } else {
            WatchIdleView()
                .environmentObject(session)
        }
    }
}

// MARK: - Idle View (no active session)

struct WatchIdleView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 28))
                .foregroundColor(.vertixGreen)

            Text("VERTIX")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(.vertixGreen)

            Text("Start a session\non your iPhone")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Active Timer View

struct WatchTimerView: View {
    @EnvironmentObject private var session: WatchSessionManager

    private var color: Color { phaseColor(for: session.phase) }
    private var icon: String  { phaseIcon(for: session.phase) }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                // Phase label
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                    Text(session.phase.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .clipShape(Capsule())

                // Timer ring
                WatchTimerRing(
                    remainingSeconds: session.remainingSeconds,
                    phase: session.phase,
                    isRunning: session.isRunning
                )

                // Controls
                WatchControlsView()
                    .environmentObject(session)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Timer Ring

struct WatchTimerRing: View {
    let remainingSeconds: Int
    let phase: String
    let isRunning: Bool

    private var color: Color { phaseColor(for: phase) }

    private var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 6)
                .frame(width: 90, height: 90)

            // Animated progress arc
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.8), value: remainingSeconds)

            // Time label
            VStack(spacing: 1) {
                Text(formattedTime)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                // Running indicator dot
                Circle()
                    .fill(isRunning ? color : Color.gray)
                    .frame(width: 5, height: 5)
                    .opacity(isRunning ? 1 : 0.4)
            }
        }
    }

    /// We don't know total phase seconds here, so we show a pulsing ring
    /// that drains as remainingSeconds decreases. We store the max seen.
    @State private var maxSeen: Int = 0

    private var progressFraction: CGFloat {
        let current = remainingSeconds
        if current > maxSeen { maxSeen = current }
        guard maxSeen > 0 else { return 0 }
        return CGFloat(current) / CGFloat(maxSeen)
    }
}

// MARK: - Controls View

struct WatchControlsView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        HStack(spacing: 14) {

            // Stop
            Button {
                session.sendCommand("stop")
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)

            // Play / Pause
            Button {
                session.sendCommand(session.isRunning ? "pause" : "start")
            } label: {
                ZStack {
                    Circle()
                        .fill(phaseColor(for: session.phase))
                        .frame(width: 46, height: 46)
                        .shadow(color: phaseColor(for: session.phase).opacity(0.4),
                                radius: 6, y: 2)
                    Image(systemName: session.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            // Skip
            Button {
                session.sendCommand("skip")
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

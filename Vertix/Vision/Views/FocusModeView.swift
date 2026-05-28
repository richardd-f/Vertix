import SwiftUI
import Combine

struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraViewModel()

    @State private var timeRemaining: Int = 25 * 60
    @State private var isTimerRunning: Bool = true
    @State private var showSaveConfirmation: Bool = false

    private let sessionDuration: Int = 25 * 60
    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formattedTime: String {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var elapsedSeconds: Int { sessionDuration - timeRemaining }

    private var formattedElapsed: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var postureScore: Int {
        guard let result = camera.postureResult else { return 0 }
        var score = 0
        if result.neckAngle < 20    { score += 33 }
        if result.shoulderTilt < 5  { score += 34 }
        if result.spineAngle < 15   { score += 33 }
        return score
    }

    private var scoreColor: Color {
        postureScore >= 80 ? Color.vertixDarkGreen : (postureScore >= 50 ? .orange : .red)
    }

    var body: some View {
        ZStack {
            // Camera feed
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Pose skeleton
            GeometryReader { geo in
                PoseOverlayView(landmarks: camera.landmarks, imageSize: geo.size)
                    .ignoresSafeArea()
            }

            // UI overlay
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
        }
        .onAppear  { camera.startSession() }
        .onDisappear { camera.stopSession() }
        .onReceive(tickTimer) { _ in
            guard isTimerRunning, timeRemaining > 0 else { return }
            timeRemaining -= 1
            if timeRemaining == 0 { isTimerRunning = false }
        }
        .alert("End Session?", isPresented: $showSaveConfirmation) {
            Button("End", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've completed \(formattedElapsed) of posture monitoring.")
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            // Dismiss
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }

            Spacer()

            // Timer + score panel
            VStack(spacing: 8) {
                timerPill
                if camera.postureResult != nil {
                    scorePill
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }

    private var timerPill: some View {
        HStack(spacing: 6) {
            Image(systemName: isTimerRunning ? "timer" : "timer.circle")
                .font(.caption)
                .foregroundColor(timeRemaining == 0 ? .orange : .white)
            Text(formattedTime)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(timeRemaining == 0 ? .orange : .white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.65))
        .cornerRadius(14)
    }

    private var scorePill: some View {
        VStack(spacing: 2) {
            Text("\(postureScore)%")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(scoreColor)
            Text("Posture Score")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.65))
        .cornerRadius(12)
    }

    // MARK: Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            // Posture feedback banner
            if let result = camera.postureResult {
                HStack(spacing: 10) {
                    Image(systemName: result.isGoodPosture
                          ? "checkmark.circle.fill"
                          : "exclamationmark.triangle.fill")
                        .foregroundColor(result.isGoodPosture ? .green : .orange)
                        .font(.title3)
                    Text(result.feedback)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)
            } else {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Searching for pose…")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)
            }

            // Angle metric cards
            if let result = camera.postureResult {
                HStack(spacing: 10) {
                    AngleCard(label: "Neck",     value: result.neckAngle,     threshold: 20)
                    AngleCard(label: "Shoulder", value: result.shoulderTilt,  threshold: 5)
                    AngleCard(label: "Spine",    value: result.spineAngle,    threshold: 15)
                }
            }

            // Session time progress
            sessionProgressBar

            // Action buttons
            HStack(spacing: 12) {
                // Pause / resume
                Button(action: { isTimerRunning.toggle() }) {
                    Label(isTimerRunning ? "Pause" : "Resume",
                          systemImage: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.vertixDarkGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.92))
                        .cornerRadius(14)
                }

                // End session
                Button(action: { showSaveConfirmation = true }) {
                    Label("End Session", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.vertixDarkGreen)
                        .cornerRadius(14)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var sessionProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text(formattedElapsed)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("25:00")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 5)
                    Capsule()
                        .fill(Color.vertixDarkGreen)
                        .frame(width: geo.size.width * CGFloat(elapsedSeconds) / CGFloat(sessionDuration),
                               height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Angle Card

struct AngleCard: View {
    let label: String
    let value: Double
    let threshold: Double

    private var isGood: Bool { value < threshold }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "%.1f°", value))
                .font(.title3.bold())
                .foregroundColor(isGood ? .green : .orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.65))
        .cornerRadius(12)
    }
}

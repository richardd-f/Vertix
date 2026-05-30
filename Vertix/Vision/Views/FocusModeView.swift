import SwiftUI
import Combine
import FirebaseAuth

struct FocusModeView: View {
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraViewModel()

    @State private var sessionManager = SessionManager()

    // Pomodoro settings — snapshotted into Firebase when session ends
    @State private var engine           = PomodoroEngine()
    @State private var showSettings     = false
    @State private var settingsFocus    = 25
    @State private var settingsShort    = 5
    @State private var settingsLong     = 15
    @State private var settingsCycles   = 4
    @State private var showSaveConfirmation = false
    @State private var sessionSaved     = false

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
            if isRunningTests {
                Color.black.ignoresSafeArea()
            } else {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()

                GeometryReader { geo in
                    PoseOverlayView(landmarks: camera.landmarks, imageSize: geo.size)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomPanel
                }
            }
        }
        .onAppear {
            if !isRunningTests { camera.startSession() }
            engine.resetAll()
        }
        .onDisappear {
            if !isRunningTests {
                camera.stopSession()
            }
        }
        .onReceive(tickTimer) { _ in
            let wasRunning = engine.isRunning
            engine.tick()

            if engine.currentPhase == .focus,
               engine.focusSecondsElapsed > 0,
               engine.focusSecondsElapsed % 60 == 0 {
                sessionManager.recordMinuteSample(
                    isGood: camera.postureResult?.isGoodPosture ?? false
                )
            }

            if wasRunning && !engine.isRunning && !engine.allCyclesComplete {
                SoundManager.shared.play(.pomodoroBreak)
            }

            if engine.allCyclesComplete {
                SoundManager.shared.play(.sessionEnd)
                saveAndDismiss()
            }
        }
        .sheet(isPresented: $showSettings) {
            SessionSettingsView(
                focusDuration:         $settingsFocus,
                shortBreakDuration:    $settingsShort,
                longBreakDuration:     $settingsLong,
                cyclesBeforeLongBreak: $settingsCycles
            ) {
                engine.applySettings(
                    focus:  settingsFocus,
                    short:  settingsShort,
                    long:   settingsLong,
                    cycles: settingsCycles
                )
                sessionSaved = false
            }
        }
        .alert("End Session?", isPresented: $showSaveConfirmation) {
            Button("End & Save", role: .destructive) {
                saveAndDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let mins = engine.focusSecondsElapsed / 60
            Text("You've focused for \(mins) minute\(mins == 1 ? "" : "s").")
        }
    }

    // MARK: Session save

    private func triggerSessionSave(elapsed: Int) {
        guard let uid = Auth.auth().currentUser?.uid, elapsed > 0 else { return }
        let settings = PomodoroSettings(
            focusDuration: focusDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            totalCycles: totalCycles
        )
        Task {
            await sessionManager.saveSession(uid: uid, elapsedSeconds: elapsed, pomodoroSettings: settings)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            // Dismiss button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }

            Spacer()

            // Session label
            VStack(spacing: 8) {
                Group {
                    if engine.currentPhase == .focus {
                        Text(engine.sessionLabel)
                    } else {
                        Text(engine.currentPhase.label)
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(
                    engine.currentPhase == .focus ? .white : engine.currentPhase.color
                )
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)

                if camera.postureResult != nil {
                    scorePill   // your friend's existing scorePill — untouched
                }
            }

            Spacer()

            // Gear button (new)
            Button {
                settingsFocus  = engine.focusDuration
                settingsShort  = engine.shortBreakDuration
                settingsLong   = engine.longBreakDuration
                settingsCycles = engine.cyclesBeforeLongBreak
                showSettings   = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
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

            // Timer Ring + Cycle Dots
            timerRing
            cycleDots

            // Pomodoro Controls (Reset, Play/Pause, & Skip)
            HStack(spacing: 32) {
                iconButton(icon: "arrow.counterclockwise", label: "Reset") {
                    engine.reset()
                }
                Button { engine.toggleRunning() } label: {
                    ZStack {
                        Circle()
                            .fill(engine.currentPhase.color)
                            .frame(width: 64, height: 64)
                            .shadow(color: engine.currentPhase.color.opacity(0.45),
                                    radius: 10, y: 4)
                        Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                iconButton(icon: "forward.end.fill", label: "Skip") {
                    engine.skipToNext()
                }
            }

            // End Session
            Button { showSaveConfirmation = true } label: {
                Label("End Session", systemImage: "stop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)

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
    
    // MARK: Timer ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 12)
                .frame(width: 190, height: 190)

            Circle()
                .trim(from: 0, to: engine.progress)
                .stroke(
                    engine.currentPhase.color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.8), value: engine.progress)

            VStack(spacing: 5) {
                Image(systemName: engine.currentPhase.icon)
                    .font(.system(size: 18))
                    .foregroundColor(engine.currentPhase.color)
                Text(engine.formattedTime)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(engine.currentPhase.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(engine.currentPhase.color)
            }
        }
    }

    // MARK: Cycle dots

    private var cycleDots: some View {
        let seq = engine.phaseSequence
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(seq.enumerated()), id: \.offset) { idx, phase in
                    let isCurrent = idx == engine.phaseSequenceIndex
                    let isPast    = idx < engine.phaseSequenceIndex
                    Capsule()
                        .fill(
                            isPast    ? phase.color :
                            isCurrent ? phase.color.opacity(0.9) :
                                        Color.white.opacity(0.25)
                        )
                        .frame(width: isCurrent ? 26 : 14, height: 6)
                        .animation(.spring(response: 0.3), value: engine.phaseSequenceIndex)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Icon button helper

    private func iconButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                Text(label).font(.caption2).foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

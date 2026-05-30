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

    // MARK: Pomodoro engine & settings state
    @State private var pomodoroEngine = PomodoroEngine()
    @State private var showSettings = false
    @State private var settingsFocus = 25
    @State private var settingsShort = 5
    @State private var settingsLong = 15
    @State private var settingsCycles = 4

    @State private var showSaveConfirmation = false
    @State private var sessionSaved = false
    
    private let watchManager = WatchConnectivityManager.shared

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Derived posture values (unchanged from original)

    private var postureScore: Int {
        guard let result = camera.postureResult else { return 0 }
        var score = 0
        if result.neckAngle    < 20 { score += 33 }
        if result.shoulderTilt < 5  { score += 34 }
        if result.spineAngle   < 15 { score += 33 }
        return score
    }

    private var scoreColor: Color {
        postureScore >= 80 ? Color.vertixDarkGreen : (postureScore >= 50 ? .orange : .red)
    }

    /// Shoulder tilt mapped to –1…+1 for the dot indicator
    private var shoulderTiltNormalized: Double {
        guard let result = camera.postureResult else { return 0 }
        return max(-1, min(1, result.shoulderTilt / 15.0))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            if isRunningTests {
                Color.black.ignoresSafeArea()
            } else {
                // Camera + skeleton overlay
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
            pomodoroEngine.resetAll()
            watchManager.sendSessionState(
                  phase: "focus", remainingSeconds: pomodoroEngine.timeRemaining, isRunning: false
            )
        }
        .onDisappear {
            if !isRunningTests { camera.stopSession() }
        }
        .onReceive(tickTimer) { _ in
            let wasRunning = pomodoroEngine.isRunning
            pomodoroEngine.tick()
         
            // sync timer to Watch every tick
            watchManager.sendSessionState(
                phase: pomodoroEngine.currentPhase.label,
                remainingSeconds: pomodoroEngine.timeRemaining,
                isRunning: pomodoroEngine.isRunning
            )
         
            // Record posture sample + send Watch alert at every completed focus minute
            if pomodoroEngine.currentPhase == .focus,
               pomodoroEngine.focusSecondsElapsed > 0,
               pomodoroEngine.focusSecondsElapsed % 60 == 0 {
         
                let isGood = camera.postureResult?.isGoodPosture ?? false
                sessionManager.recordMinuteSample(isGood: isGood)
         
                // NEW: alert Watch only on bad posture
                if !isGood, let feedback = camera.postureResult?.feedback {
                    watchManager.sendPostureAlert(message: feedback)
                }
            }
         
            if wasRunning && !pomodoroEngine.isRunning && !pomodoroEngine.allCyclesComplete {
                SoundManager.shared.play(.pomodoroBreak)
            }
         
            if pomodoroEngine.allCyclesComplete {
                SoundManager.shared.play(.sessionEnd)
                watchManager.sendSessionEnded()
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
                pomodoroEngine.applySettings(
                    focus:  settingsFocus,
                    short:  settingsShort,
                    long:   settingsLong,
                    cycles: settingsCycles
                )
                sessionSaved = false
            }
        }
        .alert("End Session?", isPresented: $showSaveConfirmation) {
            Button("End & Save", role: .destructive) { saveAndDismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            let mins = pomodoroEngine.focusSecondsElapsed / 60
            Text("You've focused for \(mins) minute\(mins == 1 ? "" : "s").")
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchCommandReceived)) { notif in
            guard let command = notif.userInfo?["command"] as? String else { return }
            switch command {
            case "start":  if !pomodoroEngine.isRunning { pomodoroEngine.toggleRunning() }
            case "pause":  if  pomodoroEngine.isRunning { pomodoroEngine.toggleRunning() }
            case "stop":   showSaveConfirmation = true
            default:       break
            }
        }
    }

    // MARK: Save & Dismiss

    private func saveAndDismiss() {
        guard !sessionSaved else { return }
        sessionSaved = true
        pomodoroEngine.isRunning = false

        let elapsed  = pomodoroEngine.focusSecondsElapsed
        let score    = postureScore
        let settings = PomodoroSettings(
            focusDuration:      pomodoroEngine.focusDuration,
            shortBreakDuration: pomodoroEngine.shortBreakDuration,
            longBreakDuration:  pomodoroEngine.longBreakDuration,
            totalCycles:        pomodoroEngine.cyclesBeforeLongBreak
        )

        guard let uid = Auth.auth().currentUser?.uid, elapsed > 0 else {
            dismiss()
            return
        }

        Task {
            await sessionManager.saveSession(
                uid: uid,
                elapsedSeconds: elapsed,
                pomodoroSettings: settings
            )
            NotificationCenter.default.post(
                name: .sessionCompleted,
                object: nil,
                userInfo: ["postureScore": score, "durationSeconds": elapsed]
            )
            watchManager.sendSessionEnded()
            dismiss()
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack(alignment: .top, spacing: 12) {
            // Dismiss button (unchanged)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }

            Spacer()

            // Centre column: session label + LIVE badge + score pill
            VStack(spacing: 6) {
                // Session / phase label
                Group {
                    if pomodoroEngine.currentPhase == .focus {
                        Text(pomodoroEngine.sessionLabel)
                    } else {
                        Text(pomodoroEngine.currentPhase.label)
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(pomodoroEngine.currentPhase == .focus ? .white : pomodoroEngine.currentPhase.color)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)

                // LIVE badge
                if !isRunningTests {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(pomodoroEngine.isRunning ? Color.red : Color.gray)
                            .frame(width: 7, height: 7)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(8)
                }

                // Score pill (unchanged logic)
                if camera.postureResult != nil {
                    scorePill
                }
            }

            Spacer()

            // Settings gear button
            Button {
                settingsFocus  = pomodoroEngine.focusDuration
                settingsShort  = pomodoroEngine.shortBreakDuration
                settingsLong   = pomodoroEngine.longBreakDuration
                settingsCycles = pomodoroEngine.cyclesBeforeLongBreak
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

    // Score pill
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

    // MARK: Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 10) {

            // ── Posture card (replaces flat feedback banner + AngleCards) ──
            if let result = camera.postureResult {
                postureCard(result: result)
            } else {
                // Searching state (unchanged from original)
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Searching for pose…")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.65))
                .cornerRadius(14)
            }

            // Timer ring
            timerRing

            // Cycle dots
            cycleDots

            // Pomodoro controls: Reset | Play/Pause | Skip
            HStack(spacing: 32) {
                iconButton(icon: "arrow.counterclockwise", label: "Reset") {
                    pomodoroEngine.reset()
                }
                Button { pomodoroEngine.toggleRunning() } label: {
                    ZStack {
                        Circle()
                            .fill(pomodoroEngine.currentPhase.color)
                            .frame(width: 64, height: 64)
                            .shadow(color: pomodoroEngine.currentPhase.color.opacity(0.45),
                                    radius: 10, y: 4)
                        Image(systemName: pomodoroEngine.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                iconButton(icon: "forward.end.fill", label: "Skip") {
                    pomodoroEngine.skipToNext()
                }
            }

            // End Session button
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

    // MARK: Posture Card
    // Replaces the separate feedback banner + HStack of AngleCards.
    // Spec: feedback text, overall % badge (green ≥80 / red <80),
    //       three alignment bars (Neck/Upper/Lower), shoulder tilt dot indicator.

    @ViewBuilder
    private func postureCard(result: PostureResult) -> some View {
        VStack(spacing: 10) {

            // Row 1: feedback icon + text + overall % badge
            HStack(spacing: 10) {
                Image(systemName: result.isGoodPosture
                      ? "checkmark.circle.fill"
                      : "exclamationmark.triangle.fill")
                    .foregroundColor(result.isGoodPosture ? .green : .orange)
                    .font(.title3)

                Text(result.feedback)
                    .foregroundColor(.white)
                    .font(.caption)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(postureScore)%")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(postureScore >= 80 ? .green : .red)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background((postureScore >= 80 ? Color.green : Color.red).opacity(0.18))
                    .cornerRadius(8)
            }

            Divider().background(Color.white.opacity(0.2))

            // Row 2: three alignment bars
            VStack(spacing: 6) {
                AlignmentBar(label: "Neck",  value: result.neckAngle,    threshold: 20)
                AlignmentBar(label: "Upper", value: result.shoulderTilt, threshold: 5)
                AlignmentBar(label: "Lower", value: result.spineAngle,   threshold: 15)
            }

            Divider().background(Color.white.opacity(0.2))

            // Row 3: shoulder tilt dot indicator
            ShoulderTiltIndicator(tiltNormalized: shoulderTiltNormalized)
        }
        .padding(12)
        .background(Color.black.opacity(0.65))
        .cornerRadius(16)
    }

    // MARK: Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 12)
                .frame(width: 190, height: 190)

            Circle()
                .trim(from: 0, to: pomodoroEngine.progress)
                .stroke(
                    pomodoroEngine.currentPhase.color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.8), value: pomodoroEngine.progress)

            VStack(spacing: 5) {
                Image(systemName: pomodoroEngine.currentPhase.icon)
                    .font(.system(size: 18))
                    .foregroundColor(pomodoroEngine.currentPhase.color)
                Text(pomodoroEngine.formattedTime)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(pomodoroEngine.currentPhase.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(pomodoroEngine.currentPhase.color)
            }
        }
    }

    // MARK: Cycle Dots

    private var cycleDots: some View {
        let seq = pomodoroEngine.phaseSequence
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(seq.enumerated()), id: \.offset) { idx, phase in
                    let isCurrent = idx == pomodoroEngine.phaseSequenceIndex
                    let isPast    = idx < pomodoroEngine.phaseSequenceIndex
                    Capsule()
                        .fill(
                            isPast    ? phase.color :
                            isCurrent ? phase.color.opacity(0.9) :
                                        Color.white.opacity(0.25)
                        )
                        .frame(width: isCurrent ? 26 : 14, height: 6)
                        .animation(.spring(response: 0.3), value: pomodoroEngine.phaseSequenceIndex)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Icon Button Helper

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

// MARK: - AlignmentBar
// Progress bar for one posture metric. Green = good (below threshold), red = needs work.

struct AlignmentBar: View {
    let label: String
    let value: Double
    let threshold: Double

    private var isGood: Bool { value < threshold }
    private var fill: Double { min(1.0, value / threshold) }
    private var score: Int   { Int((1.0 - fill) * 100) }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 38, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 7)
                    Capsule()
                        .fill(isGood ? Color.green : Color.red)
                        .frame(width: geo.size.width * CGFloat(fill), height: 7)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fill)
                }
            }
            .frame(height: 7)

            Text("\(score)%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isGood ? .green : .red)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

// MARK: - ShoulderTiltIndicator
// Horizontal track with a moving dot showing left/right shoulder tilt.

struct ShoulderTiltIndicator: View {
    /// –1.0 (full left tilt) … 0 (level) … +1.0 (full right tilt)
    let tiltNormalized: Double

    private var isLevel: Bool { abs(tiltNormalized) < 0.15 }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Shoulder Angle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text(isLevel ? "Level ✓" : (tiltNormalized < 0 ? "Tilt Left" : "Tilt Right"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isLevel ? .green : .orange)
            }

            GeometryReader { geo in
                let trackW = geo.size.width
                let dotX   = trackW * CGFloat((tiltNormalized + 1) / 2)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2, height: 10)
                        .offset(x: trackW / 2 - 1)
                    Circle()
                        .fill(isLevel ? Color.green : Color.orange)
                        .frame(width: 14, height: 14)
                        .offset(x: dotX - 7)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tiltNormalized)
                        .shadow(color: (isLevel ? Color.green : Color.orange).opacity(0.6), radius: 4)
                }
                .frame(height: 14)
            }
            .frame(height: 14)

            HStack {
                Text("L").font(.caption2).foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("R").font(.caption2).foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

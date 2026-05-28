import SwiftUI

struct HomeView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(GamificationManager.self) private var gamificationManager
    @State private var viewModel = HomeViewModel()
    @State private var showFocusMode = false
    @State private var showExpToast = false
    @State private var expGained = 0
    @State private var leveledUp = false
    @State private var newLevel: PlayerLevel? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Color.vertixBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.greeting)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(viewModel.userName.isEmpty ? "Loading…" : viewModel.userName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("👋")
                                    .font(.title)
                            }
                        }
                        Spacer()

                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // MARK: Average Score Card
                    VStack(spacing: 16) {
                        Text("AVERAGE POSTURE SCORE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1.5)
                            .foregroundColor(.secondary)

                        ZStack {
                            Circle()
                                .stroke(Color.vertixDarkGreen.opacity(0.1), lineWidth: 15)
                                .frame(width: 150, height: 150)

                            Circle()
                                .trim(from: 0.0, to: CGFloat(viewModel.averageScore) / 100.0)
                                .stroke(Color.vertixDarkGreen, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.5), value: viewModel.averageScore)

                            VStack(spacing: 2) {
                                Text("\(viewModel.averageScore)%")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                Text(viewModel.averageScore == 0 ? "No data yet" : scoreLabel(viewModel.averageScore))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)

                        if viewModel.averageScore > 0 {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.vertixDarkGreen)
                                    .frame(width: 8, height: 8)
                                Text(scoreLabel(viewModel.averageScore))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.vertixDarkGreen)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.vertixDarkGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.vertixCardBackground)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)

                    // MARK: Gamification Card
                    GamificationCard(
                        manager: gamificationManager,
                        streak: viewModel.currentStreak
                    )

                    // MARK: Start Session Button
                    Button(action: { showFocusMode = true }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.vertixDarkGreen)
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())

                            Text("Start Session")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.vertixDarkGreen)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }

                    // MARK: Last Session Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("LAST SESSION")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.0)
                                .foregroundColor(.secondary)
                            Spacer()
                            if viewModel.hasLastSession {
                                Text(viewModel.lastSessionLabel)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.vertixDarkGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.vertixDarkGreen.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }

                        if viewModel.hasLastSession {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.vertixDarkGreen.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "figure.mind.and.body")
                                        .foregroundColor(.vertixDarkGreen)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(viewModel.lastSessionDuration) Focus Session")
                                        .font(.headline)
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.vertixDarkGreen).frame(width: 6, height: 6)
                                        Text("\(viewModel.lastSessionScore)% Good Posture")
                                            .font(.caption)
                                            .foregroundColor(Color.vertixDarkGreen)
                                    }
                                }
                                Spacer()
                                VStack {
                                    Text("\(viewModel.lastSessionScore)")
                                        .font(.title2).bold()
                                    Text("score")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                                    Capsule().fill(Color.vertixDarkGreen)
                                        .frame(width: geometry.size.width * CGFloat(viewModel.lastSessionScore) / 100.0, height: 6)
                                }
                            }
                            .frame(height: 6)
                        } else {
                            Text("No sessions yet. Start your first session!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(20)
                    .background(Color.vertixCardBackground)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 80) // tab bar clearance
                }
            }

            // MARK: EXP Toast overlay
            if showExpToast {
                VStack {
                    ExpToastView(
                        expGained: expGained,
                        leveledUp: leveledUp,
                        newLevel: newLevel,
                        isShowing: $showExpToast
                    )
                    .padding(.top, 60)
                    Spacer()
                }
                .zIndex(10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showExpToast)
            }
        }
        .task {
            let uid = authManager.currentUser?.id ?? ""
            await viewModel.load(uid: uid)
            await gamificationManager.load(uid: uid)
        }
        .fullScreenCover(isPresented: $showFocusMode) {
            FocusModeView()
        }
        // Listen for session-completed notification from FocusModeView
        .onReceive(NotificationCenter.default.publisher(for: .sessionCompleted)) { notif in
            guard let userInfo = notif.userInfo,
                  let score = userInfo["postureScore"] as? Int,
                  let duration = userInfo["durationSeconds"] as? Int,
                  let uid = authManager.currentUser?.id else { return }

            Task {
                let prevLevel = gamificationManager.currentLevel.level
                let gained = await gamificationManager.processSessionCompletion(
                    uid: uid,
                    postureScore: score,
                    durationSeconds: duration,
                    streak: viewModel.currentStreak
                )
                let didLevelUp = gamificationManager.currentLevel.level > prevLevel
                expGained = gained
                leveledUp = didLevelUp
                newLevel = didLevelUp ? gamificationManager.currentLevel : nil
                withAnimation { showExpToast = true }

                if didLevelUp {
                    SoundManager.shared.play(.levelUp)
                } else {
                    SoundManager.shared.play(.sessionEnd)
                }

                // Refresh home data
                await viewModel.load(uid: uid)
            }
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        score >= 80 ? "Great Form" : score >= 50 ? "Needs Work" : "Poor Form"
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let sessionCompleted = Notification.Name("vertix.sessionCompleted")
}

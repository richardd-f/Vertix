//
//  GamificationViews.swift
//  Vertix
//
//  Created by Clarice Harijanto on 28/05/26.
//

// This file contains: GamificationCard, LevelBadgeView, ExpProgressBar, ExpToastView, ChallengePill

import SwiftUI

// MARK: - Level Badge

struct LevelBadgeView: View {
    let level: PlayerLevel
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: level.color).opacity(0.15))
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(Color(hex: level.color), lineWidth: 2)
                .frame(width: size, height: size)
            VStack(spacing: 0) {
                Text("Lv")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: level.color))
                Text("\(level.level)")
                    .font(.system(size: size * 0.30, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: level.color))
            }
        }
    }
}

// MARK: - EXP Progress Bar

struct ExpProgressBar: View {
    let progress: Double    // 0.0 – 1.0
    let currentLevel: PlayerLevel
    let totalExp: Int
    let expToNext: Int
    var showDetails: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showDetails {
                HStack {
                    Text(currentLevel.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: currentLevel.color))
                    Spacer()
                    Text("\(totalExp) EXP")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: currentLevel.color).opacity(0.12))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: currentLevel.color), Color(hex: currentLevel.color).opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)

            if showDetails && expToNext > 0 {
                Text("\(expToNext) EXP to Level \((PlayerLevel.forExp(totalExp).level) + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Gamification Card (for HomeView)

struct GamificationCard: View {
    let manager: GamificationManager
    let streak: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header row
            HStack(spacing: 12) {
                LevelBadgeView(level: manager.currentLevel)

                VStack(alignment: .leading, spacing: 2) {
                    Text("RANK")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    Text(manager.currentLevel.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Streak pill
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(streak)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text("streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }

            ExpProgressBar(
                progress: manager.levelProgress,
                currentLevel: manager.currentLevel,
                totalExp: manager.totalExp,
                expToNext: manager.expToNextLevel
            )

            Divider()

            // Daily Challenges
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("TODAY'S CHALLENGES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(.secondary)
                    Spacer()
                    let doneCount = manager.todayChallenges.filter { manager.isChallengeCompleted($0) }.count
                    Text("\(doneCount)/\(manager.todayChallenges.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.vertixDarkGreen)
                }

                ForEach(manager.todayChallenges) { challenge in
                    ChallengePill(
                        challenge: challenge,
                        isCompleted: manager.isChallengeCompleted(challenge)
                    )
                }
            }
        }
        .padding(20)
        .background(Color.vertixCardBackground)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Challenge Pill

struct ChallengePill: View {
    let challenge: DailyChallenge
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCompleted ? Color.vertixDarkGreen.opacity(0.1) : Color.gray.opacity(0.08))
                    .frame(width: 36, height: 36)
                Image(systemName: isCompleted ? "checkmark" : challenge.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isCompleted ? .vertixDarkGreen : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                Text(challenge.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // EXP reward badge
            Text("+\(challenge.expReward)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isCompleted ? .secondary : .vertixDarkGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (isCompleted ? Color.gray : Color.vertixDarkGreen).opacity(0.1)
                )
                .clipShape(Capsule())
        }
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

// MARK: - EXP Toast (shown after session)

struct ExpToastView: View {
    let expGained: Int
    let leveledUp: Bool
    let newLevel: PlayerLevel?
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 8) {
            if leveledUp, let level = newLevel {
                // Level-up celebration
                VStack(spacing: 6) {
                    Text("🎉 Level Up!")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    LevelBadgeView(level: level, size: 52)
                    Text(level.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                Text("+\(expGained) EXP")
                    .font(.system(size: 16, weight: .black))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.vertixDarkGreen)
            .clipShape(Capsule())
            .shadow(color: Color.vertixDarkGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(leveledUp ? 24 : 0)
        .background(leveledUp ? Color.vertixDarkGreen : Color.clear)
        .cornerRadius(leveledUp ? 20 : 0)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isShowing = false }
            }
        }
    }
}

// MARK: - Color from Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

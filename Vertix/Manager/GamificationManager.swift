//
//  GamificationManager.swift
//  Vertix
//
//  Created by Clarice Harijanto on 28/05/26.
//

// This file contains: EXP engine, level system, & daily challenges

import Foundation
import Observation

// MARK: - Models

struct DailyChallenge: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetValue: Int
    let expReward: Int
    let type: ChallengeType

    enum ChallengeType {
        case completeSession
        case achieveScore(min: Int)
        case maintainStreak(days: Int)
        case focusMinutes(min: Int)
    }
}

struct PlayerLevel {
    let level: Int
    let title: String
    let expRequired: Int  // total EXP needed to reach this level
    let color: String     // hex color for the level badge

    static let levels: [PlayerLevel] = [
        PlayerLevel(level: 1,  title: "Slouch Beginner",    expRequired: 0,    color: "#9E9E9E"),
        PlayerLevel(level: 2,  title: "Posture Padawan",    expRequired: 100,  color: "#8BC34A"),
        PlayerLevel(level: 3,  title: "Spine Apprentice",   expRequired: 250,  color: "#4CAF50"),
        PlayerLevel(level: 4,  title: "Focus Disciple",     expRequired: 500,  color: "#00BCD4"),
        PlayerLevel(level: 5,  title: "Alignment Adept",    expRequired: 900,  color: "#2196F3"),
        PlayerLevel(level: 6,  title: "Posture Warrior",    expRequired: 1400, color: "#3F51B5"),
        PlayerLevel(level: 7,  title: "Focus Knight",       expRequired: 2000, color: "#9C27B0"),
        PlayerLevel(level: 8,  title: "Spine Sentinel",     expRequired: 2800, color: "#E91E63"),
        PlayerLevel(level: 9,  title: "Posture Champion",   expRequired: 3800, color: "#FF5722"),
        PlayerLevel(level: 10, title: "Vertix Master",      expRequired: 5000, color: "#FFD700"),
    ]

    static func forExp(_ totalExp: Int) -> PlayerLevel {
        // Walk backwards to find highest level achieved
        for playerLevel in levels.reversed() {
            if totalExp >= playerLevel.expRequired {
                return playerLevel
            }
        }
        return levels[0]
    }

    static func nextLevel(after level: Int) -> PlayerLevel? {
        levels.first { $0.level == level + 1 }
    }
}

// MARK: - EXP Calculation

struct ExpCalculator {
    /// Base EXP per completed session
    static let baseSessionExp = 30

    /// Bonus EXP multiplier per posture score tier
    static func sessionExp(postureScore: Int, durationMinutes: Int, streak: Int) -> Int {
        // Base: 30 XP per session
        var exp = baseSessionExp

        // Score bonus: up to +20 XP
        exp += Int(Double(postureScore) / 5.0)

        // Duration bonus: +1 XP per 5 minutes
        exp += durationMinutes / 5

        // Streak multiplier: 10% bonus per 3 days of streak (capped at 50%)
        let streakBonus = min(0.5, Double(streak / 3) * 0.1)
        exp = Int(Double(exp) * (1.0 + streakBonus))

        return exp
    }

    /// EXP for completing a daily challenge
    static func challengeExp(_ challenge: DailyChallenge) -> Int {
        challenge.expReward
    }

    /// Progress (0.0 - 1.0) within the current level
    static func levelProgress(totalExp: Int) -> Double {
        let current = PlayerLevel.forExp(totalExp)
        guard let next = PlayerLevel.nextLevel(after: current.level) else {
            return 1.0 // max level
        }
        let expIntoLevel = totalExp - current.expRequired
        let expNeeded = next.expRequired - current.expRequired
        guard expNeeded > 0 else { return 1.0 }
        return min(1.0, Double(expIntoLevel) / Double(expNeeded))
    }

    /// EXP remaining to reach next level
    static func expToNextLevel(totalExp: Int) -> Int {
        let current = PlayerLevel.forExp(totalExp)
        guard let next = PlayerLevel.nextLevel(after: current.level) else { return 0 }
        return max(0, next.expRequired - totalExp)
    }
}

// MARK: - Daily Challenge Generator

struct DailyChallengeGenerator {
    /// Deterministically generate 3 challenges for a given date
    static func challenges(for dateKey: String) -> [DailyChallenge] {
        // Use dateKey as seed for deterministic generation
        let seed = dateKey.utf8.reduce(0) { $0 + Int($1) }

        return [
            challenges[seed % 5],
            challenges[(seed + 13) % 5],
            challenges[(seed + 7) % 5]
        ]
    }

    static let challenges: [DailyChallenge] = [
        DailyChallenge(
            id: "complete_session",
            title: "Focused Flow",
            description: "Complete 1 focus session today",
            icon: "brain.head.profile",
            targetValue: 1,
            expReward: 50,
            type: .completeSession
        ),
        DailyChallenge(
            id: "high_score",
            title: "Perfect Posture",
            description: "Score 80% or above in a session",
            icon: "star.fill",
            targetValue: 80,
            expReward: 75,
            type: .achieveScore(min: 80)
        ),
        DailyChallenge(
            id: "streak_keeper",
            title: "Streak Keeper",
            description: "Maintain your current streak",
            icon: "flame.fill",
            targetValue: 1,
            expReward: 40,
            type: .maintainStreak(days: 1)
        ),
        DailyChallenge(
            id: "focus_30",
            title: "Deep Work",
            description: "Focus for at least 25 minutes",
            icon: "timer",
            targetValue: 25,
            expReward: 60,
            type: .focusMinutes(min: 25)
        ),
        DailyChallenge(
            id: "spine_hero",
            title: "Spine Hero",
            description: "Complete a session with 90%+ score",
            icon: "figure.mind.and.body",
            targetValue: 90,
            expReward: 100,
            type: .achieveScore(min: 90)
        ),
    ]
}

// MARK: - GamificationManager

@Observable
class GamificationManager {
    var totalExp: Int = 0
    var completedChallengeIds: Set<String> = []
    var todayChallenges: [DailyChallenge] = []

    var currentLevel: PlayerLevel { PlayerLevel.forExp(totalExp) }
    var levelProgress: Double { ExpCalculator.levelProgress(totalExp: totalExp) }
    var expToNextLevel: Int { ExpCalculator.expToNextLevel(totalExp: totalExp) }
    var nextLevel: PlayerLevel? { PlayerLevel.nextLevel(after: currentLevel.level) }

    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol = FirebaseDatabaseService()) {
        self.db = db
        refreshChallenges()
    }

    func refreshChallenges() {
        let today = SessionManager.dateKey(for: Date())
        todayChallenges = DailyChallengeGenerator.challenges(for: today)
    }

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        do {
            let dict = try await db.getData(path: "users/\(uid)")
            totalExp = dict["totalExp"] as? Int ?? 0

            let today = SessionManager.dateKey(for: Date())
            let completed = try await db.getData(path: "gamification/\(uid)/\(today)/completedChallenges")
            completedChallengeIds = Set(completed.keys)
        } catch {
            print("GamificationManager: load failed — \(error)")
        }
        refreshChallenges()
    }

    /// Called after a session ends. Awards EXP and checks challenge completion.
    @MainActor
    func processSessionCompletion(
        uid: String,
        postureScore: Int,
        durationSeconds: Int,
        streak: Int
    ) async -> Int { // Returns EXP gained
        let durationMinutes = max(1, durationSeconds / 60)
        let earned = ExpCalculator.sessionExp(
            postureScore: postureScore,
            durationMinutes: durationMinutes,
            streak: streak
        )
        let newTotal = totalExp + earned
        totalExp = newTotal

        // Check challenges
        var newlyCompleted: Set<String> = []
        for challenge in todayChallenges {
            guard !completedChallengeIds.contains(challenge.id) else { continue }
            let completed: Bool
            switch challenge.type {
            case .completeSession:
                completed = true
            case .achieveScore(let min):
                completed = postureScore >= min
            case .maintainStreak:
                completed = streak >= 1
            case .focusMinutes(let min):
                completed = durationMinutes >= min
            }
            if completed {
                newlyCompleted.insert(challenge.id)
                totalExp += challenge.expReward
            }
        }
        completedChallengeIds.formUnion(newlyCompleted)

        // Persist to Firebase
        do {
            let today = SessionManager.dateKey(for: Date())
            var updates: [String: Any] = [
                "users/\(uid)/totalExp": totalExp
            ]
            for id in newlyCompleted {
                updates["gamification/\(uid)/\(today)/completedChallenges/\(id)"] = true
            }
            try await db.updateValues(updates)
        } catch {
            print("GamificationManager: persist failed — \(error)")
        }

        return earned
    }

    func isChallengeCompleted(_ challenge: DailyChallenge) -> Bool {
        completedChallengeIds.contains(challenge.id)
    }
}

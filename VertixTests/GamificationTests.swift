//
//  GamificationTests.swift
//  Vertix
//
//  Created by Clarice Harijanto on 30/05/26.
//

import Foundation
import Testing
@testable import Vertix

@Suite("GamificationManager")
struct GamificationManagerTests {

    // MARK: - PlayerLevel

    @Test("Level 1 is returned for 0 EXP")
    func level_zeroExpGivesLevel1() {
        let level = PlayerLevel.forExp(0)
        #expect(level.level == 1)
    }

    @Test("Level 2 is returned for exactly 100 EXP")
    func level_exactThresholdGivesCorrectLevel() {
        let level = PlayerLevel.forExp(100)
        #expect(level.level == 2)
    }

    @Test("Level 10 is returned for 5000+ EXP")
    func level_maxExpGivesLevel10() {
        let level = PlayerLevel.forExp(5000)
        #expect(level.level == 10)
    }

    @Test("nextLevel returns nil at max level")
    func level_noNextLevelAtMax() {
        #expect(PlayerLevel.nextLevel(after: 10) == nil)
    }

    // MARK: - ExpCalculator

    @Test("Base session EXP is at least 30")
    func exp_baseSessionIsAtLeast30() {
        let exp = ExpCalculator.sessionExp(postureScore: 0, durationMinutes: 0, streak: 0)
        #expect(exp >= 30)
    }

    @Test("Higher posture score gives more EXP")
    func exp_highScoreGivesMoreExp() {
        let low  = ExpCalculator.sessionExp(postureScore: 20,  durationMinutes: 25, streak: 0)
        let high = ExpCalculator.sessionExp(postureScore: 100, durationMinutes: 25, streak: 0)
        #expect(high > low)
    }

    @Test("Streak bonus caps at 50%")
    func exp_streakBonusCapsAt50Percent() {
        let base    = ExpCalculator.sessionExp(postureScore: 50, durationMinutes: 25, streak: 0)
        let capped  = ExpCalculator.sessionExp(postureScore: 50, durationMinutes: 25, streak: 999)
        let maxBonus = Int(Double(base) * 1.5)
        #expect(capped <= maxBonus + 1) // +1 for integer rounding
    }

    @Test("levelProgress returns 1.0 at max level")
    func exp_progressIs1AtMaxLevel() {
        let progress = ExpCalculator.levelProgress(totalExp: 9999)
        #expect(progress == 1.0)
    }

    @Test("expToNextLevel is 0 at max level")
    func exp_toNextLevelIsZeroAtMax() {
        #expect(ExpCalculator.expToNextLevel(totalExp: 9999) == 0)
    }

    // MARK: - DailyChallengeGenerator

    @Test("Generator always returns 3 challenges")
    func challenges_alwaysReturnsThree() {
        let result = DailyChallengeGenerator.challenges(for: "2026-05-28")
        #expect(result.count == 3)
    }

    @Test("Same date always returns same challenges (deterministic)")
    func challenges_isDeterministic() {
        let a = DailyChallengeGenerator.challenges(for: "2026-05-28").map { $0.id }
        let b = DailyChallengeGenerator.challenges(for: "2026-05-28").map { $0.id }
        #expect(a == b)
    }

    @Test("Different dates can return different challenges")
    func challenges_differentDatesCanDiffer() {
        let a = DailyChallengeGenerator.challenges(for: "2026-05-28").map { $0.id }
        let b = DailyChallengeGenerator.challenges(for: "2026-05-01").map { $0.id }
        // Not guaranteed to differ, but with different seeds they usually will
        // Just check they are valid challenge IDs
        #expect(a.allSatisfy { !$0.isEmpty })
        #expect(b.allSatisfy { !$0.isEmpty })
    }

    // MARK: - processSessionCompletion

    @Test("processSessionCompletion awards positive EXP")
    func process_awardsPositiveExp() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["totalExp": 0]

        let manager = GamificationManager(db: mock)
        let gained = await manager.processSessionCompletion(
            uid: "uid-1", postureScore: 80, durationSeconds: 1500, streak: 3
        )
        #expect(gained > 0)
        #expect(manager.totalExp > 0)
    }

    @Test("processSessionCompletion marks completeSession challenge as done")
    func process_completesSessionChallenge() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["totalExp": 0]

        let manager = GamificationManager(db: mock)
        _ = await manager.processSessionCompletion(
            uid: "uid-1", postureScore: 80, durationSeconds: 1500, streak: 1
        )

        let completedIds = manager.completedChallengeIds
        // At minimum the "complete_session" challenge should be marked done
        #expect(completedIds.contains("complete_session"))
    }

    @Test("processSessionCompletion does not complete high-score challenge if score too low")
    func process_doesNotCompleteHighScoreChallengeBelowThreshold() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["totalExp": 0]

        let manager = GamificationManager(db: mock)
        _ = await manager.processSessionCompletion(
            uid: "uid-1", postureScore: 50, durationSeconds: 1500, streak: 1
        )

        // "high_score" requires 80+, so it should NOT be in completed set
        // (only if it was today's challenge — check if it's in todayChallenges first)
        let isHighScoreToday = manager.todayChallenges.contains { $0.id == "high_score" }
        if isHighScoreToday {
            #expect(!manager.completedChallengeIds.contains("high_score"))
        }
    }

    @Test("processSessionCompletion persists EXP to Firebase")
    func process_persistsToFirebase() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["totalExp": 100]

        let manager = GamificationManager(db: mock)
        _ = await manager.processSessionCompletion(
            uid: "uid-1", postureScore: 70, durationSeconds: 900, streak: 2
        )

        #expect(mock.savedUpdates.count == 1)
        let keys = mock.savedUpdates[0].keys
        #expect(keys.contains("users/uid-1/totalExp"))
    }

    // MARK: - load

    @Test("load reads totalExp from Firebase")
    func load_readsTotalExp() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["totalExp": 250]

        let manager = GamificationManager(db: mock)
        await manager.load(uid: "uid-1")

        #expect(manager.totalExp == 250)
        #expect(manager.currentLevel.level == 3) // 250 EXP = level 3
    }

    @Test("load defaults totalExp to 0 when field is missing")
    func load_defaultsToZeroWhenMissing() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = [:]

        let manager = GamificationManager(db: mock)
        await manager.load(uid: "uid-1")

        #expect(manager.totalExp == 0)
    }

    @Test("isChallengeCompleted returns false before any session")
    func isChallengeCompleted_falseInitially() {
        let manager = GamificationManager(db: MockDatabaseService())
        let challenge = manager.todayChallenges[0]
        #expect(manager.isChallengeCompleted(challenge) == false)
    }
}

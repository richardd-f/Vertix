import Testing
@testable import Vertix

@Suite("SessionManager")
struct SessionManagerTests {

    // MARK: - Helpers

    private func makeRecord(goodCount: Int, badCount: Int, durationSeconds: Int = 1500) -> SessionRecord {
        SessionRecord(
            startedAt: Date(), endedAt: Date(),
            durationSeconds: durationSeconds, dateKey: "2026-05-28",
            goodCount: goodCount, badCount: badCount,
            pomodoroCount: 1, focusDuration: 25,
            shortBreakDuration: 5, longBreakDuration: 15, totalCycles: 1
        )
    }

    // MARK: - calculateStreak

    @Test("first ever session starts streak at 1")
    func streak_firstEverSession() {
        let (streak, longest) = SessionManager.calculateStreak(
            prevLastActive: "", prevStreak: 0, prevLongest: 0, today: "2026-05-28"
        )
        #expect(streak == 1)
        #expect(longest == 1)
    }

    @Test("session the day after previous continues the streak")
    func streak_continuedFromYesterday() {
        let (streak, longest) = SessionManager.calculateStreak(
            prevLastActive: "2026-05-27", prevStreak: 3, prevLongest: 3, today: "2026-05-28"
        )
        #expect(streak == 4)
        #expect(longest == 4)
    }

    @Test("second session on the same day does not change the streak")
    func streak_sameDayDoesNotIncrease() {
        let (streak, longest) = SessionManager.calculateStreak(
            prevLastActive: "2026-05-28", prevStreak: 5, prevLongest: 5, today: "2026-05-28"
        )
        #expect(streak == 5)
        #expect(longest == 5)
    }

    @Test("gap of two or more days resets streak to 1")
    func streak_brokenByGapResetsToOne() {
        let (streak, longest) = SessionManager.calculateStreak(
            prevLastActive: "2026-05-25", prevStreak: 7, prevLongest: 10, today: "2026-05-28"
        )
        #expect(streak == 1)
        #expect(longest == 10) // longestStreak is not lost
    }

    @Test("new longest streak is recorded when current exceeds previous best")
    func streak_updatesLongestWhenBeaten() {
        let (streak, longest) = SessionManager.calculateStreak(
            prevLastActive: "2026-05-27", prevStreak: 9, prevLongest: 9, today: "2026-05-28"
        )
        #expect(streak == 10)
        #expect(longest == 10)
    }

    @Test("longestStreak is preserved when current streak resets")
    func streak_longestPreservedOnReset() {
        let (_, longest) = SessionManager.calculateStreak(
            prevLastActive: "2026-05-01", prevStreak: 3, prevLongest: 15, today: "2026-05-28"
        )
        #expect(longest == 15)
    }

    // MARK: - mergeDailyScores

    @Test("fresh day produces correct aggregated totals")
    func mergeDailyScores_freshDay() {
        let record = makeRecord(goodCount: 8, badCount: 2, durationSeconds: 1500)
        let result = SessionManager.mergeDailyScores(existing: [:], record: record)

        #expect(result["totalSessions"]  as? Int  == 1)
        #expect(result["totalSeconds"]   as? Int  == 1500)
        #expect(result["totalGoodCount"] as? Int  == 8)
        #expect(result["totalBadCount"]  as? Int  == 2)
        #expect(result["averageScore"]   as? Int  == 80)
        #expect(result["isActive"]       as? Bool == true)
    }

    @Test("second session on same day accumulates correctly")
    func mergeDailyScores_existingDayAccumulates() {
        let existing: [String: Any] = [
            "totalSessions": 1, "totalSeconds": 1500,
            "totalGoodCount": 5, "totalBadCount": 5,
            "averageScore": 50, "isActive": true
        ]
        let record = makeRecord(goodCount: 8, badCount: 2, durationSeconds: 900)
        let result = SessionManager.mergeDailyScores(existing: existing, record: record)

        #expect(result["totalSessions"]  as? Int == 2)
        #expect(result["totalSeconds"]   as? Int == 2400)
        #expect(result["totalGoodCount"] as? Int == 13)
        #expect(result["totalBadCount"]  as? Int == 7)
        // averageScore: 13 good out of 20 total = 65
        #expect(result["averageScore"]   as? Int == 65)
        #expect(result["isActive"]       as? Bool == true)
    }

    @Test("averageScore is 0 when there are zero posture samples")
    func mergeDailyScores_zeroSamplesGivesZeroAverage() {
        let record = makeRecord(goodCount: 0, badCount: 0)
        let result = SessionManager.mergeDailyScores(existing: [:], record: record)
        #expect(result["averageScore"] as? Int == 0)
    }

    // MARK: - dateKey / dateFromKey

    @Test("dateKey formats a known date to YYYY-MM-DD")
    func dateKey_formatsCorrectly() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 28
        let date = Calendar.current.date(from: comps)!
        #expect(SessionManager.dateKey(for: date) == "2026-05-28")
    }

    @Test("dateKey zero-pads single-digit month and day")
    func dateKey_zeroPadsSingleDigits() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 5
        let date = Calendar.current.date(from: comps)!
        #expect(SessionManager.dateKey(for: date) == "2026-01-05")
    }

    @Test("dateFromKey round-trips with dateKey")
    func dateFromKey_roundTrips() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 28
        let original = Calendar.current.date(from: comps)!
        let key = SessionManager.dateKey(for: original)
        let parsed = SessionManager.dateFromKey(key)!
        let parsedComps = Calendar.current.dateComponents([.year, .month, .day], from: parsed)
        #expect(parsedComps.year == 2026)
        #expect(parsedComps.month == 5)
        #expect(parsedComps.day == 28)
    }

    @Test("dateFromKey returns nil for an invalid string")
    func dateFromKey_invalidStringReturnsNil() {
        #expect(SessionManager.dateFromKey("not-a-date") == nil)
        #expect(SessionManager.dateFromKey("") == nil)
    }

    // MARK: - isYesterday

    @Test("isYesterday returns true when dateKey is exactly one day before today string")
    func isYesterday_oneDayBefore() {
        #expect(SessionManager.isYesterday("2026-05-27", relativeTo: "2026-05-28") == true)
    }

    @Test("isYesterday returns false for same day")
    func isYesterday_sameDay() {
        #expect(SessionManager.isYesterday("2026-05-28", relativeTo: "2026-05-28") == false)
    }

    @Test("isYesterday returns false for two days before")
    func isYesterday_twoDaysBefore() {
        #expect(SessionManager.isYesterday("2026-05-26", relativeTo: "2026-05-28") == false)
    }

    // MARK: - saveSession via MockDatabaseService

    @Test("saveSession calls updateValues with session, dailyScores, and user paths")
    func saveSession_callsUpdateValues() async {
        let mock = MockDatabaseService()
        let manager = SessionManager(db: mock)
        manager.recordMinuteSample(isGood: true)
        manager.recordMinuteSample(isGood: false)

        await manager.saveSession(uid: "uid-1", elapsedSeconds: 120, pomodoroSettings: .defaults)

        #expect(mock.savedUpdates.count == 1)
        let keys = mock.savedUpdates[0].keys
        #expect(keys.contains(where: { $0.hasPrefix("sessions/uid-1/") }))
        #expect(keys.contains(where: { $0.hasPrefix("dailyScores/uid-1/") }))
        #expect(keys.contains(where: { $0.hasPrefix("users/uid-1/") }))
    }

    @Test("saveSession is skipped when elapsedSeconds is zero")
    func saveSession_skipsWhenZeroElapsed() async {
        let mock = MockDatabaseService()
        let manager = SessionManager(db: mock)

        await manager.saveSession(uid: "uid-1", elapsedSeconds: 0, pomodoroSettings: .defaults)

        #expect(mock.savedUpdates.isEmpty)
    }

    @Test("saveSession records the correct goodCount and badCount in the session dict")
    func saveSession_goodAndBadCountsAreCorrect() async {
        let mock = MockDatabaseService()
        let manager = SessionManager(db: mock)
        manager.recordMinuteSample(isGood: true)
        manager.recordMinuteSample(isGood: true)
        manager.recordMinuteSample(isGood: false)

        await manager.saveSession(uid: "uid-1", elapsedSeconds: 180, pomodoroSettings: .defaults)

        let updates = mock.savedUpdates[0]
        let sessionEntry = updates.first(where: { $0.key.hasPrefix("sessions/uid-1/") })?.value
        let sessionDict = sessionEntry as? [String: Any]
        #expect(sessionDict?["goodCount"] as? Int == 2)
        #expect(sessionDict?["badCount"]  as? Int == 1)
    }

    @Test("recordMinuteSample increments the correct counter")
    func recordMinuteSample_incrementsCorrectly() {
        let manager = SessionManager(db: MockDatabaseService())
        manager.recordMinuteSample(isGood: true)
        manager.recordMinuteSample(isGood: true)
        manager.recordMinuteSample(isGood: false)

        #expect(manager.goodCount == 2)
        #expect(manager.badCount  == 1)
    }
}

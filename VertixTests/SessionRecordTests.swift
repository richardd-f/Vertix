import Testing
@testable import Vertix

@Suite("SessionRecord")
struct SessionRecordTests {

    // MARK: - Helpers

    private func makeRecord(goodCount: Int, badCount: Int, durationSeconds: Int = 1500) -> SessionRecord {
        SessionRecord(
            startedAt: Date(),
            endedAt: Date(),
            durationSeconds: durationSeconds,
            dateKey: "2026-05-28",
            goodCount: goodCount,
            badCount: badCount,
            pomodoroCount: 1,
            focusDuration: 25,
            shortBreakDuration: 5,
            longBreakDuration: 15,
            totalCycles: 1
        )
    }

    // MARK: - postureScore

    @Test("postureScore is 100 when all samples are good")
    func postureScore_allGood() {
        #expect(makeRecord(goodCount: 10, badCount: 0).postureScore == 100)
    }

    @Test("postureScore is 0 when all samples are bad")
    func postureScore_allBad() {
        #expect(makeRecord(goodCount: 0, badCount: 10).postureScore == 0)
    }

    @Test("postureScore is 0 when there are no samples at all")
    func postureScore_noSamples() {
        #expect(makeRecord(goodCount: 0, badCount: 0).postureScore == 0)
    }

    @Test("postureScore is 50 when half are good")
    func postureScore_half() {
        #expect(makeRecord(goodCount: 5, badCount: 5).postureScore == 50)
    }

    @Test("postureScore truncates integer division (2 good / 3 total = 66, not 67)")
    func postureScore_truncatesIntegerDivision() {
        // 2 * 100 / 3 = 66 (integer division, not 66.6...)
        #expect(makeRecord(goodCount: 2, badCount: 1).postureScore == 66)
    }

    // MARK: - toFirebaseDict

    @Test("toFirebaseDict contains all required Firebase schema keys")
    func toFirebaseDict_containsAllRequiredKeys() {
        let dict = makeRecord(goodCount: 8, badCount: 2).toFirebaseDict()
        let required = [
            "startedAt", "endedAt", "durationSeconds", "dateKey",
            "goodCount", "badCount", "postureScore",
            "pomodoroCount", "focusDuration", "shortBreakDuration",
            "longBreakDuration", "totalCycles"
        ]
        for key in required {
            #expect(dict[key] != nil, "Missing key: \(key)")
        }
    }

    @Test("toFirebaseDict postureScore matches computed property")
    func toFirebaseDict_postureScoreIsConsistent() {
        let record = makeRecord(goodCount: 8, badCount: 2)
        let dict = record.toFirebaseDict()
        #expect(dict["postureScore"] as? Int == record.postureScore)
    }

    @Test("toFirebaseDict durationSeconds matches the initialiser value")
    func toFirebaseDict_durationSeconds() {
        let dict = makeRecord(goodCount: 5, badCount: 5, durationSeconds: 900).toFirebaseDict()
        #expect(dict["durationSeconds"] as? Int == 900)
    }

    @Test("toFirebaseDict dateKey matches the initialiser value")
    func toFirebaseDict_dateKey() {
        let dict = makeRecord(goodCount: 1, badCount: 1).toFirebaseDict()
        #expect(dict["dateKey"] as? String == "2026-05-28")
    }
}

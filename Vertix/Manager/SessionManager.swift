import Foundation
import Observation
import FirebaseAuth

@Observable
class SessionManager {
    private(set) var goodCount: Int = 0
    private(set) var badCount: Int = 0
    private(set) var isSaving: Bool = false

    private let startedAt: Date = Date()
    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol = FirebaseDatabaseService()) {
        self.db = db
    }

    func recordMinuteSample(isGood: Bool) {
        if isGood { goodCount += 1 } else { badCount += 1 }
    }

    func saveSession(
        uid: String,
        elapsedSeconds: Int,
        pomodoroSettings: PomodoroSettings
    ) async {
        guard elapsedSeconds > 0 else { return }
        isSaving = true
        defer { isSaving = false }

        let endedAt = Date()
        let dateKey = SessionManager.dateKey(for: endedAt)

        let record = SessionRecord(
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: elapsedSeconds,
            dateKey: dateKey,
            goodCount: goodCount,
            badCount: badCount,
            pomodoroCount: 1,
            focusDuration: pomodoroSettings.focusDuration,
            shortBreakDuration: pomodoroSettings.shortBreakDuration,
            longBreakDuration: pomodoroSettings.longBreakDuration,
            totalCycles: pomodoroSettings.totalCycles
        )

        do {
            let updates = try await buildAtomicUpdates(uid: uid, record: record, dateKey: dateKey)
            try await db.updateValues(updates)
            print("✅ Session saved to Firebase")
        } catch {
            print("❌ Failed to save session: \(error)")
        }
    }

    // MARK: - Internal helpers (internal so tests can verify them directly)

    static func dateKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    static func dateFromKey(_ key: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.date(from: key)
    }

    static func calculateStreak(
        prevLastActive: String,
        prevStreak: Int,
        prevLongest: Int,
        today: String
    ) -> (streak: Int, longest: Int) {
        let streak: Int
        if prevLastActive == today {
            streak = max(prevStreak, 1)
        } else if isYesterday(prevLastActive, relativeTo: today) {
            streak = prevStreak + 1
        } else {
            streak = 1
        }
        return (streak, max(prevLongest, streak))
    }

    static func isYesterday(_ dateKey: String, relativeTo today: String) -> Bool {
        guard let date = dateFromKey(dateKey), let todayDate = dateFromKey(today) else { return false }
        let diff = Calendar.current.dateComponents([.day], from: date, to: todayDate).day ?? 0
        return diff == 1
    }

    static func mergeDailyScores(existing: [String: Any], record: SessionRecord) -> [String: Any] {
        let prevSessions = existing["totalSessions"] as? Int ?? 0
        let prevSeconds  = existing["totalSeconds"]  as? Int ?? 0
        let prevGood     = existing["totalGoodCount"] as? Int ?? 0
        let prevBad      = existing["totalBadCount"]  as? Int ?? 0

        let newSessions  = prevSessions + 1
        let newSeconds   = prevSeconds + record.durationSeconds
        let newGood      = prevGood + record.goodCount
        let newBad       = prevBad + record.badCount
        let totalSamples = newGood + newBad
        let avgScore     = totalSamples > 0 ? newGood * 100 / totalSamples : 0

        return [
            "totalSessions": newSessions,
            "totalSeconds":  newSeconds,
            "totalGoodCount": newGood,
            "totalBadCount":  newBad,
            "averageScore":   avgScore,
            "isActive":       true
        ]
    }

    // MARK: - Private

    private func buildAtomicUpdates(
        uid: String,
        record: SessionRecord,
        dateKey: String
    ) async throws -> [String: Any] {
        let sessionKey = UUID().uuidString

        let userDict   = try await db.getData(path: "users/\(uid)")
        let prevTotal  = userDict["totalTrackedSeconds"] as? Int ?? 0
        let prevStreak = userDict["currentStreak"]       as? Int ?? 0
        let prevLongest = userDict["longestStreak"]      as? Int ?? 0
        let prevLastActive = userDict["lastActiveDate"]  as? String ?? ""

        let newTotal = prevTotal + record.durationSeconds
        let (newStreak, newLongest) = SessionManager.calculateStreak(
            prevLastActive: prevLastActive,
            prevStreak: prevStreak,
            prevLongest: prevLongest,
            today: dateKey
        )

        let existingDaily = try await db.getData(path: "dailyScores/\(uid)/\(dateKey)")
        let mergedDaily   = SessionManager.mergeDailyScores(existing: existingDaily, record: record)

        return [
            "sessions/\(uid)/\(sessionKey)": record.toFirebaseDict(),
            "dailyScores/\(uid)/\(dateKey)": mergedDaily,
            "users/\(uid)/totalTrackedSeconds": newTotal,
            "users/\(uid)/currentStreak":       newStreak,
            "users/\(uid)/longestStreak":       newLongest,
            "users/\(uid)/lastActiveDate":      dateKey
        ]
    }
}

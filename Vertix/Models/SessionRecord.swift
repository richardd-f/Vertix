import Foundation

struct PomodoroSettings {
    var focusDuration: Int      // minutes
    var shortBreakDuration: Int // minutes
    var longBreakDuration: Int  // minutes
    var totalCycles: Int

    static let defaults = PomodoroSettings(
        focusDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        totalCycles: 1
    )
}

struct SessionRecord {
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let dateKey: String          // "YYYY-MM-DD"
    let goodCount: Int
    let badCount: Int
    let pomodoroCount: Int
    let focusDuration: Int
    let shortBreakDuration: Int
    let longBreakDuration: Int
    let totalCycles: Int

    var postureScore: Int {
        let total = goodCount + badCount
        guard total > 0 else { return 0 }
        return goodCount * 100 / total
    }

    func toFirebaseDict() -> [String: Any] {
        [
            "startedAt": startedAt.timeIntervalSince1970,
            "endedAt": endedAt.timeIntervalSince1970,
            "durationSeconds": durationSeconds,
            "dateKey": dateKey,
            "goodCount": goodCount,
            "badCount": badCount,
            "postureScore": postureScore,
            "pomodoroCount": pomodoroCount,
            "focusDuration": focusDuration,
            "shortBreakDuration": shortBreakDuration,
            "longBreakDuration": longBreakDuration,
            "totalCycles": totalCycles
        ]
    }
}

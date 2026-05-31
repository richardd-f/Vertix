import Foundation
import Observation

@Observable
class SessionSettingsViewModel {
    var focusDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int
    var totalCycles: Int
    var isSaving: Bool = false

    private let db: DatabaseServiceProtocol

    init(settings: PomodoroSettings,
         db: DatabaseServiceProtocol = FirebaseDatabaseService()) {
        self.focusDuration      = settings.focusDuration
        self.shortBreakDuration = settings.shortBreakDuration
        self.longBreakDuration  = settings.longBreakDuration
        self.totalCycles        = settings.totalCycles
        self.db                 = db
    }

    var currentSettings: PomodoroSettings {
        PomodoroSettings(
            focusDuration: focusDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            totalCycles: totalCycles
        )
    }

    @MainActor
    func save(uid: String) async {
        isSaving = true
        defer { isSaving = false }
        let updates: [String: Any] = [
            "users/\(uid)/pomodoroFocusDuration":      focusDuration,
            "users/\(uid)/pomodoroShortBreakDuration": shortBreakDuration,
            "users/\(uid)/pomodoroLongBreakDuration":  longBreakDuration,
            "users/\(uid)/pomodoroTotalCycles":        totalCycles
        ]
        try? await db.updateValues(updates)
    }
}

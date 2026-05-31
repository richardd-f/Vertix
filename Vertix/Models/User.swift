import Foundation

struct User: Identifiable {
    let id: String
    var name: String
    var email: String
    var avatarUrl: String?
    var createdAt: Date
    var totalTrackedSeconds: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String?
    var pomodoroSettings: PomodoroSettings
}

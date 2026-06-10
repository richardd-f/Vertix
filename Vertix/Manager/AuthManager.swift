import SwiftUI
import Observation
import FirebaseAuth
import FirebaseDatabase

@Observable
class AuthManager {
    var isAuthenticated: Bool = false
    var currentUser: User? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private var dbRef: DatabaseReference {
        Database.database().reference()
    }

    init() {
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            // Seed a minimal profile immediately from the restored session so the UI
            // always has a uid to load with. Otherwise, if the DB read below is slow,
            // missing, or denied, currentUser stays nil and Home hangs on "Loading…"
            // forever (its .task keys off currentUser?.id and never re-fires).
            self.currentUser = User(
                id: user.uid,
                name: user.displayName ?? "",
                email: user.email ?? "",
                avatarUrl: nil,
                createdAt: Date(),
                totalTrackedSeconds: 0,
                currentStreak: 0,
                longestStreak: 0,
                lastActiveDate: nil,
                pomodoroSettings: .defaults
            )
            Task { await fetchUserData(uid: user.uid) }
        }
    }

    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let fetch = await fetchUserData(uid: result.user.uid)

            // Only seed a fresh profile when the record is genuinely missing.
            // On a transient fetch failure we must NOT overwrite — that would
            // wipe the user's existing streak/EXP/tracked-seconds with zeros.
            if fetch == .missing {
                let fallbackName  = result.user.displayName ?? "User"
                let fallbackEmail = result.user.email ?? email
                let userData: [String: Any] = [
                    "id": result.user.uid,
                    "name": fallbackName,
                    "email": fallbackEmail,
                    "totalExp": 0,
                    "totalTrackedSeconds": 0,
                    "currentStreak": 0,
                    "longestStreak": 0,
                    "lastActiveDate": "",
                    "pomodoroFocusDuration": PomodoroSettings.defaults.focusDuration,
                    "pomodoroShortBreakDuration": PomodoroSettings.defaults.shortBreakDuration,
                    "pomodoroLongBreakDuration": PomodoroSettings.defaults.longBreakDuration,
                    "pomodoroTotalCycles": PomodoroSettings.defaults.totalCycles
                ]
                try? await dbRef.child("users").child(result.user.uid).setValue(userData)
                self.currentUser = User(
                    id: result.user.uid,
                    name: fallbackName,
                    email: fallbackEmail,
                    avatarUrl: nil,
                    createdAt: Date(),
                    totalTrackedSeconds: 0,
                    currentStreak: 0,
                    longestStreak: 0,
                    lastActiveDate: nil,
                    pomodoroSettings: .defaults
                )
            }

            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            let userData: [String: Any] = [
                "id": uid,
                "name": name,
                "email": email,
                "createdAt": ServerValue.timestamp(),
                "totalExp": 0,
                "totalTrackedSeconds": 0,
                "currentStreak": 0,
                "longestStreak": 0,
                "lastActiveDate": "",
                "pomodoroFocusDuration": PomodoroSettings.defaults.focusDuration,
                "pomodoroShortBreakDuration": PomodoroSettings.defaults.shortBreakDuration,
                "pomodoroLongBreakDuration": PomodoroSettings.defaults.longBreakDuration,
                "pomodoroTotalCycles": PomodoroSettings.defaults.totalCycles
            ]

            do {
                try await dbRef.child("users").child(uid).setValue(userData)
            } catch {
                try? await result.user.delete()
                errorMessage = "Account created but failed to save profile. Please try again."
                isLoading = false
                return
            }

            self.currentUser = User(
                id: uid,
                name: name,
                email: email,
                avatarUrl: nil,
                createdAt: Date(),
                totalTrackedSeconds: 0,
                currentStreak: 0,
                longestStreak: 0,
                lastActiveDate: nil,
                pomodoroSettings: .defaults
            )
            self.isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshUser(uid: String) async {
        _ = await fetchUserData(uid: uid)
    }

    /// Outcome of a user-record fetch, so callers can tell a genuinely missing
    /// record apart from a transient read failure.
    private enum FetchResult { case loaded, missing, failed }

    @MainActor
    @discardableResult
    private func fetchUserData(uid: String) async -> FetchResult {
        do {
            let snapshot = try await dbRef.child("users").child(uid).getData()

            guard snapshot.exists(), let dict = snapshot.value as? [String: Any] else {
                return .missing
            }

            let name       = dict["name"] as? String ?? "User"
            let email      = dict["email"] as? String ?? ""
            let avatarUrl  = dict["avatarUrl"] as? String
            let createdAt  = (dict["createdAt"] as? Double)
                              .map { Date(timeIntervalSince1970: $0 / 1000) } ?? Date()
            let totalSecs  = dict["totalTrackedSeconds"] as? Int ?? 0
            let streak     = dict["currentStreak"] as? Int ?? 0
            let longest    = dict["longestStreak"] as? Int ?? 0
            let lastActive = dict["lastActiveDate"] as? String
            let focusDur   = dict["pomodoroFocusDuration"] as? Int ?? 25
            let shortBreak = dict["pomodoroShortBreakDuration"] as? Int ?? 5
            let longBreak  = dict["pomodoroLongBreakDuration"] as? Int ?? 15
            let cycles     = dict["pomodoroTotalCycles"] as? Int ?? 1
            let settings   = PomodoroSettings(
                              focusDuration: focusDur,
                              shortBreakDuration: shortBreak,
                              longBreakDuration: longBreak,
                              totalCycles: cycles)

            self.currentUser = User(
                id: uid,
                name: name,
                email: email,
                avatarUrl: avatarUrl,
                createdAt: createdAt,
                totalTrackedSeconds: totalSecs,
                currentStreak: streak,
                longestStreak: longest,
                lastActiveDate: lastActive,
                pomodoroSettings: settings
            )
            return .loaded
        } catch {
            print("Error fetching user data from DB: \(error)")
            return .failed
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

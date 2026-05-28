import Foundation
import Observation

@Observable
class HomeViewModel {
    var userName: String = ""
    var averageScore: Int = 0
    var lastSessionDuration: String = ""
    var lastSessionScore: Int = 0
    var lastSessionDateKey: String = ""
    var hasLastSession: Bool = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default:      return "Good night,"
        }
    }

    var lastSessionLabel: String {
        guard hasLastSession else { return "" }
        guard let date = SessionManager.dateFromKey(lastSessionDateKey) else { return lastSessionDateKey }
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }

    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol = FirebaseDatabaseService()) {
        self.db = db
    }

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        await fetchUserName(uid: uid)
        await fetchTodayScore(uid: uid)
        await fetchLastSession(uid: uid)
    }

    // MARK: - Private

    @MainActor
    private func fetchUserName(uid: String) async {
        do {
            let dict = try await db.getData(path: "users/\(uid)")
            userName = dict["name"] as? String ?? ""
        } catch {
            print("HomeViewModel: failed to fetch userName — \(error)")
        }
    }

    @MainActor
    private func fetchTodayScore(uid: String) async {
        let today = SessionManager.dateKey(for: Date())
        do {
            let dict = try await db.getData(path: "dailyScores/\(uid)/\(today)")
            averageScore = dict["averageScore"] as? Int ?? 0
        } catch {
            print("HomeViewModel: failed to fetch today score — \(error)")
        }
    }

    @MainActor
    private func fetchLastSession(uid: String) async {
        do {
            guard let dict = try await db.getLastChild(
                path: "sessions/\(uid)", orderedBy: "startedAt"
            ) else { return }
            let seconds = dict["durationSeconds"] as? Int ?? 0
            lastSessionDuration = "\(max(1, seconds / 60))m"
            lastSessionScore    = dict["postureScore"] as? Int ?? 0
            lastSessionDateKey  = dict["dateKey"]      as? String ?? ""
            hasLastSession      = true
        } catch {
            print("HomeViewModel: failed to fetch last session — \(error)")
        }
    }
}

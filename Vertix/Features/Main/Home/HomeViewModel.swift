import Foundation
import Observation
import FirebaseDatabase

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
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let date = fmt.date(from: lastSessionDateKey) else { return lastSessionDateKey }
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }

    private let dbRef = Database.database().reference()

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        await fetchUserName(uid: uid)
        await fetchTodayScore(uid: uid)
        await fetchLastSession(uid: uid)
    }

    @MainActor
    private func fetchUserName(uid: String) async {
        do {
            let snap = try await dbRef.child("users").child(uid).child("name").getData()
            userName = snap.value as? String ?? ""
        } catch {
            print("HomeViewModel: failed to fetch userName — \(error)")
        }
    }

    @MainActor
    private func fetchTodayScore(uid: String) async {
        let today = dateKey(for: Date())
        do {
            let snap = try await dbRef.child("dailyScores").child(uid).child(today).getData()
            if let dict = snap.value as? [String: Any] {
                averageScore = dict["averageScore"] as? Int ?? 0
            }
        } catch {
            print("HomeViewModel: failed to fetch today score — \(error)")
        }
    }

    @MainActor
    private func fetchLastSession(uid: String) async {
        do {
            let snap = try await dbRef.child("sessions").child(uid)
                .queryOrdered(byChild: "startedAt")
                .queryLimited(toLast: 1)
                .getData()
            guard let children = snap.children.allObjects as? [DataSnapshot],
                  let last = children.first,
                  let dict = last.value as? [String: Any] else { return }
            let seconds = dict["durationSeconds"] as? Int ?? 0
            let mins = max(1, seconds / 60)
            lastSessionDuration = "\(mins)m"
            lastSessionScore = dict["postureScore"] as? Int ?? 0
            lastSessionDateKey = dict["dateKey"] as? String ?? ""
            hasLastSession = true
        } catch {
            print("HomeViewModel: failed to fetch last session — \(error)")
        }
    }

    private func dateKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }
}

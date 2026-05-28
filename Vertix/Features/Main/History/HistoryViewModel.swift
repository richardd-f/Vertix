import Foundation
import Observation
import FirebaseDatabase

@Observable
class HistoryViewModel {
    var monthLabel: String = ""
    var currentMonthDays: [Int] = []
    var calendarStartPadding: Int = 0
    var dailyScoreMap: [String: Int] = [:]
    var activeDays: Set<String> = []
    var weeklyData: [(day: String, score: Int)] = []
    var monthSessionCount: Int = 0
    var monthAvgScore: Int = 0
    var currentStreak: Int = 0

    private let dbRef = Database.database().reference()
    private let calendar = Calendar.current

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        setupCurrentMonth()
        await fetchData(uid: uid)
    }

    func scoreLevel(for day: Int) -> Int {
        let key = dateKeyForDay(day)
        guard let score = dailyScoreMap[key] else { return 0 }
        if score >= 80 { return 3 }
        if score >= 50 { return 2 }
        return 1
    }

    // MARK: - Private

    private func setupCurrentMonth() {
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        monthLabel = fmt.string(from: now)

        let range = calendar.range(of: .day, in: .month, for: now)!
        currentMonthDays = Array(range)

        var comps = calendar.dateComponents([.year, .month], from: now)
        comps.day = 1
        let firstDay = calendar.date(from: comps)!
        // weekday: 1=Sun…7=Sat → convert to Mon-first index (0=Mon…6=Sun)
        let rawWeekday = calendar.component(.weekday, from: firstDay)
        calendarStartPadding = (rawWeekday + 5) % 7
    }

    @MainActor
    private func fetchData(uid: String) async {
        do {
            let streakSnap = try await dbRef.child("users").child(uid).child("currentStreak").getData()
            currentStreak = streakSnap.value as? Int ?? 0
        } catch {
            print("HistoryViewModel: streak fetch failed — \(error)")
        }

        do {
            let snap = try await dbRef.child("dailyScores").child(uid).getData()
            var scoreMap: [String: Int] = [:]
            var active: Set<String> = []
            var monthTotal = 0
            var monthCount = 0
            var monthScoreSum = 0

            for child in snap.children {
                guard let entry = child as? DataSnapshot,
                      let dict = entry.value as? [String: Any] else { continue }
                let key = entry.key
                let score = dict["averageScore"] as? Int ?? 0
                let isActive = dict["isActive"] as? Bool ?? false
                let sessions = dict["totalSessions"] as? Int ?? 0

                scoreMap[key] = score
                if isActive { active.insert(key) }

                if isCurrentMonth(key) {
                    monthTotal += sessions
                    monthScoreSum += score
                    monthCount += 1
                }
            }

            dailyScoreMap = scoreMap
            activeDays = active
            monthSessionCount = monthTotal
            monthAvgScore = monthCount > 0 ? monthScoreSum / monthCount : 0
            weeklyData = buildWeeklyData(from: scoreMap)
        } catch {
            print("HistoryViewModel: dailyScores fetch failed — \(error)")
        }
    }

    private func buildWeeklyData(from map: [String: Int]) -> [(day: String, score: Int)] {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var result: [(day: String, score: Int)] = []
        let today = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = fmt.string(from: date)
            let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0
            let label = dayNames[weekdayIndex]
            let score = map[key] ?? 0
            result.append((day: label, score: score))
        }
        return result
    }

    private func isCurrentMonth(_ dateKey: String) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let date = fmt.date(from: dateKey) else { return false }
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    private func dateKeyForDay(_ day: Int) -> String {
        let now = Date()
        var comps = calendar.dateComponents([.year, .month], from: now)
        comps.day = day
        guard let date = calendar.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }
}

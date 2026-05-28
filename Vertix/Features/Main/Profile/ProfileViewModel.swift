import Foundation
import Observation

@Observable
class ProfileViewModel {
    var name: String = ""
    var email: String = ""
    var avgScore: Int = 0
    var trackedHours: Int = 0

    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol = FirebaseDatabaseService()) {
        self.db = db
    }

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        await fetchUserStats(uid: uid)
        await fetchAvgScore(uid: uid)
    }

    // MARK: - Private

    @MainActor
    private func fetchUserStats(uid: String) async {
        do {
            let dict = try await db.getData(path: "users/\(uid)")
            name  = dict["name"]  as? String ?? ""
            email = dict["email"] as? String ?? ""
            let totalSeconds = dict["totalTrackedSeconds"] as? Int ?? 0
            trackedHours = totalSeconds / 3600
        } catch {
            print("ProfileViewModel: failed to fetch user stats — \(error)")
        }
    }

    @MainActor
    private func fetchAvgScore(uid: String) async {
        do {
            let children = try await db.getAllChildren(path: "dailyScores/\(uid)")
            var total = 0
            var count = 0
            for dict in children.values {
                if let score = dict["averageScore"] as? Int {
                    total += score
                    count += 1
                }
            }
            avgScore = count > 0 ? total / count : 0
        } catch {
            print("ProfileViewModel: failed to fetch avg score — \(error)")
        }
    }
}

import Foundation
import Observation
import FirebaseDatabase

@Observable
class ProfileViewModel {
    var name: String = ""
    var email: String = ""
    var avgScore: Int = 0
    var trackedHours: Int = 0

    private let dbRef = Database.database().reference()

    @MainActor
    func load(uid: String) async {
        guard !uid.isEmpty else { return }
        await fetchUserStats(uid: uid)
        await fetchAvgScore(uid: uid)
    }

    @MainActor
    private func fetchUserStats(uid: String) async {
        do {
            let snap = try await dbRef.child("users").child(uid).getData()
            guard let dict = snap.value as? [String: Any] else { return }
            name = dict["name"] as? String ?? ""
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
            let snap = try await dbRef.child("dailyScores").child(uid).getData()
            var total = 0
            var count = 0
            for child in snap.children {
                guard let entry = child as? DataSnapshot,
                      let dict = entry.value as? [String: Any],
                      let score = dict["averageScore"] as? Int else { continue }
                total += score
                count += 1
            }
            avgScore = count > 0 ? total / count : 0
        } catch {
            print("ProfileViewModel: failed to fetch avg score — \(error)")
        }
    }
}

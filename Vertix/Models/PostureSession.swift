import Foundation

struct PostureSession: Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval // Stored in seconds
    let averageScore: Int // 0 to 100
    
    // A pragmatic computed property so our UI doesn't have to calculate this every time
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

// MARK: - Mock Data
// We attach the mock data directly to the struct extension so it's globally available for previews and UI building.
extension PostureSession {
    static let mockData: [PostureSession] = [
        // Today
        PostureSession(id: UUID(), date: Date(), duration: 3600, averageScore: 88),
        // Yesterday
        PostureSession(id: UUID(), date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, duration: 5400, averageScore: 92),
        // 2 days ago (bad posture day!)
        PostureSession(id: UUID(), date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, duration: 7200, averageScore: 65),
        // 3 days ago
        PostureSession(id: UUID(), date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, duration: 2400, averageScore: 85)
    ]
}
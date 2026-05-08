import Foundation
import Observation

@Observable
class HomeViewModel {
    var greeting: String = "Good afternoon,"
    var userName: String = "Budi"
    var averageScore: Int = 82
    var lastSessionDuration: String = "25m"
    var lastSessionScore: Int = 95
    var isSessionActive: Bool = false
    
    func toggleSession() {
        isSessionActive.toggle()
    }
}
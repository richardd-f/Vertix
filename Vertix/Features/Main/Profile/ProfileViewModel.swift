import Foundation
import Observation

@Observable
class ProfileViewModel {
    var name: String = "Budi Santoso"
    var email: String = "budi.santoso@example.com"
    var phone: String = "+62 812 3456 7890"
    var avgScore: Int = 82
    var trackedHours: Int = 124
}
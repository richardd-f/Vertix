import Foundation
import Observation

@Observable
class HistoryViewModel {
    // Generating mock 1-31 days for the calendar
    var currentMonthDays: [Int] = Array(1...31)
    
    // Determining color intensity based on mock score
    func scoreLevel(for day: Int) -> Int {
        if day % 5 == 0 { return 1 } // Light
        if day % 2 == 0 { return 2 } // Medium
        if day % 3 == 0 { return 3 } // Dark
        return 0 // Empty
    }
}
import Foundation
import Testing
@testable import Vertix

@Suite("HistoryViewModel")
struct HistoryViewModelTests {

    // MARK: - setupCurrentMonth

    @Test("setupCurrentMonth sets monthLabel to non-empty string")
    func setupCurrentMonth_labelIsNotEmpty() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        #expect(!vm.monthLabel.isEmpty)
    }

    @Test("setupCurrentMonth fills currentMonthDays starting at 1")
    func setupCurrentMonth_daysStartAtOne() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        #expect(vm.currentMonthDays.first == 1)
    }

    @Test("setupCurrentMonth fills currentMonthDays with at most 31 days")
    func setupCurrentMonth_daysCountIsAtMost31() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        #expect(vm.currentMonthDays.count <= 31)
        #expect(vm.currentMonthDays.count >= 28)
    }

    @Test("setupCurrentMonth sets calendarStartPadding in 0...6 range")
    func setupCurrentMonth_paddingIsInRange() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        #expect(vm.calendarStartPadding >= 0)
        #expect(vm.calendarStartPadding <= 6)
    }

    // MARK: - scoreLevel

    @Test("scoreLevel returns 0 for a day with no data")
    func scoreLevel_noDataReturnsZero() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        // dailyScoreMap is empty, so any day should be 0
        #expect(vm.scoreLevel(for: 1) == 0)
    }

    @Test("scoreLevel returns 3 for score >= 80")
    func scoreLevel_highScoreReturnsThree() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        let key = vm.dateKeyForDay(1)
        vm.dailyScoreMap[key] = 85
        #expect(vm.scoreLevel(for: 1) == 3)
    }

    @Test("scoreLevel returns 2 for score in 50-79 range")
    func scoreLevel_midScoreReturnsTwo() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        let key = vm.dateKeyForDay(1)
        vm.dailyScoreMap[key] = 65
        #expect(vm.scoreLevel(for: 1) == 2)
    }

    @Test("scoreLevel returns 1 for score below 50")
    func scoreLevel_lowScoreReturnsOne() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        let key = vm.dateKeyForDay(1)
        vm.dailyScoreMap[key] = 30
        #expect(vm.scoreLevel(for: 1) == 1)
    }

    @Test("scoreLevel boundary: 80 returns 3, 79 returns 2")
    func scoreLevel_boundary80() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        let key = vm.dateKeyForDay(2)
        vm.dailyScoreMap[key] = 80
        #expect(vm.scoreLevel(for: 2) == 3)

        let key2 = vm.dateKeyForDay(3)
        vm.dailyScoreMap[key2] = 79
        #expect(vm.scoreLevel(for: 3) == 2)
    }

    @Test("scoreLevel boundary: 50 returns 2, 49 returns 1")
    func scoreLevel_boundary50() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        vm.setupCurrentMonth()
        let key = vm.dateKeyForDay(4)
        vm.dailyScoreMap[key] = 50
        #expect(vm.scoreLevel(for: 4) == 2)

        let key2 = vm.dateKeyForDay(5)
        vm.dailyScoreMap[key2] = 49
        #expect(vm.scoreLevel(for: 5) == 1)
    }

    // MARK: - buildWeeklyData

    @Test("buildWeeklyData returns exactly 7 entries")
    func buildWeeklyData_returnsSevenEntries() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        let result = vm.buildWeeklyData(from: [:])
        #expect(result.count == 7)
    }

    @Test("buildWeeklyData fills missing days with score 0")
    func buildWeeklyData_missingDaysAreZero() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        let result = vm.buildWeeklyData(from: [:])
        #expect(result.allSatisfy { $0.score == 0 })
    }

    @Test("buildWeeklyData uses known scores from the map")
    func buildWeeklyData_usesKnownScores() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        let today = SessionManager.dateKey(for: Date())
        let result = vm.buildWeeklyData(from: [today: 90])
        // The last entry should be today's score
        #expect(result.last?.score == 90)
    }

    @Test("buildWeeklyData day labels are valid day abbreviations")
    func buildWeeklyData_dayLabelsAreValid() {
        let vm = HistoryViewModel(db: MockDatabaseService())
        let validLabels: Set<String> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let result = vm.buildWeeklyData(from: [:])
        for entry in result {
            #expect(validLabels.contains(entry.day))
        }
    }

    // MARK: - load() via MockDatabaseService

    @Test("load populates currentStreak from users node")
    func load_populatesCurrentStreak() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["currentStreak": 7]

        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.currentStreak == 7)
    }

    @Test("load defaults currentStreak to 0 when users node has no streak")
    func load_defaultsStreakToZero() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = [:]

        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.currentStreak == 0)
    }

    @Test("load populates dailyScoreMap from dailyScores children")
    func load_populatesDailyScoreMap() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = [:]
        mock.childrenStubs["dailyScores/uid-1"] = [
            "2026-05-28": ["averageScore": 80, "isActive": true, "totalSessions": 2]
        ]

        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.dailyScoreMap["2026-05-28"] == 80)
    }

    @Test("load populates activeDays from isActive field")
    func load_populatesActiveDays() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = [:]
        mock.childrenStubs["dailyScores/uid-1"] = [
            "2026-05-28": ["averageScore": 80, "isActive": true, "totalSessions": 1],
            "2026-05-27": ["averageScore": 60, "isActive": false, "totalSessions": 1]
        ]

        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.activeDays.contains("2026-05-28"))
        #expect(!vm.activeDays.contains("2026-05-27"))
    }

    @Test("load computes weeklyData with 7 entries after fetching dailyScores")
    func load_weeklyDataHasSevenEntries() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = [:]
        mock.childrenStubs["dailyScores/uid-1"] = [:]

        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.weeklyData.count == 7)
    }

    @Test("load with empty UID returns immediately without calling Firebase")
    func load_emptyUIDDoesNotCallFirebase() async {
        let mock = MockDatabaseService()
        let vm = HistoryViewModel(db: mock)
        await vm.load(uid: "")

        #expect(mock.savedUpdates.isEmpty)
        #expect(vm.currentStreak == 0)
        #expect(vm.dailyScoreMap.isEmpty)
    }
}

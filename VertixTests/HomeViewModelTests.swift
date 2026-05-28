import Testing
@testable import Vertix

@Suite("HomeViewModel")
struct HomeViewModelTests {

    // MARK: - load()

    @Test("load populates userName from users node")
    func load_populatesUserName() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Felix", "email": "felix@test.com"]

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.userName == "Felix")
    }

    @Test("load populates averageScore from today's dailyScores node")
    func load_populatesTodayAverageScore() async {
        let today = SessionManager.dateKey(for: Date())
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Test"]
        mock.dataStubs["dailyScores/uid-1/\(today)"] = ["averageScore": 75]

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.averageScore == 75)
    }

    @Test("load defaults averageScore to 0 when no daily data exists for today")
    func load_defaultsAverageScoreToZero() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Test"]
        // No dailyScores stub → getData returns [:]

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.averageScore == 0)
    }

    @Test("load sets hasLastSession and populates session fields when a session exists")
    func load_populatesLastSession() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Test"]
        mock.lastChildStub = [
            "durationSeconds": 1500,
            "postureScore": 85,
            "dateKey": "2026-05-28"
        ]

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.hasLastSession == true)
        #expect(vm.lastSessionScore == 85)
        #expect(vm.lastSessionDuration == "25m")
        #expect(vm.lastSessionDateKey == "2026-05-28")
    }

    @Test("load leaves hasLastSession false when no sessions exist")
    func load_noLastSession() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Test"]
        mock.lastChildStub = nil

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.hasLastSession == false)
    }

    @Test("load with empty UID returns immediately without calling Firebase")
    func load_emptyUIDDoesNotCallFirebase() async {
        let mock = MockDatabaseService()
        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "")

        // No Firebase calls should have been made
        #expect(mock.savedUpdates.isEmpty)
        #expect(vm.userName.isEmpty)
    }

    @Test("lastSessionDuration rounds up sub-minute sessions to at least 1m")
    func load_subMinuteSessionShowsAtLeast1m() async {
        let mock = MockDatabaseService()
        mock.dataStubs["users/uid-1"] = ["name": "Test"]
        mock.lastChildStub = ["durationSeconds": 30, "postureScore": 50, "dateKey": "2026-05-28"]

        let vm = HomeViewModel(db: mock)
        await vm.load(uid: "uid-1")

        #expect(vm.lastSessionDuration == "1m")
    }

    // MARK: - lastSessionLabel (pure computed, no Firebase needed)

    @Test("lastSessionLabel returns Today for today's dateKey")
    func lastSessionLabel_today() {
        let vm = HomeViewModel(db: MockDatabaseService())
        vm.lastSessionDateKey = SessionManager.dateKey(for: Date())
        vm.hasLastSession = true
        #expect(vm.lastSessionLabel == "Today")
    }

    @Test("lastSessionLabel returns Yesterday for yesterday's dateKey")
    func lastSessionLabel_yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let vm = HomeViewModel(db: MockDatabaseService())
        vm.lastSessionDateKey = SessionManager.dateKey(for: yesterday)
        vm.hasLastSession = true
        #expect(vm.lastSessionLabel == "Yesterday")
    }

    @Test("lastSessionLabel returns empty string when hasLastSession is false")
    func lastSessionLabel_noSession() {
        let vm = HomeViewModel(db: MockDatabaseService())
        vm.hasLastSession = false
        #expect(vm.lastSessionLabel == "")
    }

    // MARK: - greeting (time-based, format check only)

    @Test("greeting ends with a comma")
    func greeting_alwaysEndsWithComma() {
        let vm = HomeViewModel(db: MockDatabaseService())
        #expect(vm.greeting.hasSuffix(","))
    }
}

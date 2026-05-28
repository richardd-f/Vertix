import Foundation
@testable import Vertix

/// Configurable in-memory fake for DatabaseServiceProtocol.
/// Each test sets up stubs before calling the ViewModel under test.
final class MockDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
    /// Stubs for getData(path:). Key is the exact path string.
    var dataStubs: [String: [String: Any]] = [:]

    /// Stub for getLastChild — returns the same value regardless of path/child.
    var lastChildStub: [String: Any]? = nil

    /// Stubs for getAllChildren(path:). Key is the exact path string.
    var childrenStubs: [String: [String: [String: Any]]] = [:]

    /// Captures every updateValues(_:) call for assertion.
    var savedUpdates: [[String: Any]] = []

    func getData(path: String) async throws -> [String: Any] {
        dataStubs[path] ?? [:]
    }

    func getLastChild(path: String, orderedBy child: String) async throws -> [String: Any]? {
        lastChildStub
    }

    func getAllChildren(path: String) async throws -> [String: [String: Any]] {
        childrenStubs[path] ?? [:]
    }

    func updateValues(_ updates: [String: Any]) async throws {
        savedUpdates.append(updates)
    }
}

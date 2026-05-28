import Foundation
import FirebaseDatabase

// MARK: - Protocol

protocol DatabaseServiceProtocol: Sendable {
    /// Fetch a single node and return it as a flat dictionary.
    func getData(path: String) async throws -> [String: Any]

    /// Fetch the last child of a node ordered by a child key.
    func getLastChild(path: String, orderedBy child: String) async throws -> [String: Any]?

    /// Fetch all children of a node, keyed by their push ID / dateKey.
    func getAllChildren(path: String) async throws -> [String: [String: Any]]

    /// Atomic multi-path write.
    func updateValues(_ updates: [String: Any]) async throws
}

// MARK: - Real Firebase implementation

final class FirebaseDatabaseService: DatabaseServiceProtocol {
    private let root = Database.database().reference()

    func getData(path: String) async throws -> [String: Any] {
        let snap = try await root.child(path).getData()
        return snap.value as? [String: Any] ?? [:]
    }

    func getLastChild(path: String, orderedBy child: String) async throws -> [String: Any]? {
        let snap = try await root.child(path)
            .queryOrdered(byChild: child)
            .queryLimited(toLast: 1)
            .getData()
        guard let children = snap.children.allObjects as? [DataSnapshot],
              let last = children.first else { return nil }
        return last.value as? [String: Any]
    }

    func getAllChildren(path: String) async throws -> [String: [String: Any]] {
        let snap = try await root.child(path).getData()
        var result: [String: [String: Any]] = [:]
        for child in snap.children {
            guard let entry = child as? DataSnapshot,
                  let dict = entry.value as? [String: Any] else { continue }
            result[entry.key] = dict
        }
        return result
    }

    func updateValues(_ updates: [String: Any]) async throws {
        try await root.updateChildValues(updates)
    }
}

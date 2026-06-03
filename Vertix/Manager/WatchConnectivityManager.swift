//
//  WatchConnectivityManager.swift
//  Vertix
//
//  Manages iPhone -> Watch communication via WatchConnectivity.

import Foundation
import WatchConnectivity
import Observation

@Observable
final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()

    // Whether a paired, reachable Watch is available
    private(set) var isWatchReachable: Bool = false

    private override init() {
        super.init()
        activateIfSupported()
    }

    // MARK: - Activation

    private func activateIfSupported() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public Send API

    /// Call this from PostureAnalyzer / FocusModeView when bad posture is detected.
    /// message: the specific fix string, e.g. "Fix: head tilting forward, spine not straight"
    func sendPostureAlert(message: String) {
        send(["type": "postureAlert", "message": message])
    }

    /// Call this every second so the Watch timer stays in sync.
    /// Uses applicationContext (latest-wins, never queues) instead of per-second
    /// messages — when the Watch is asleep we only keep the most recent state,
    /// and a live sendMessage is layered on top when it's reachable for immediacy.
    func sendSessionState(phase: String, remainingSeconds: Int, totalSeconds: Int, isRunning: Bool) {
        guard hasWatch else { return }
        let message: [String: Any] = [
            "type": "sessionState",
            "phase": phase,
            "remainingSeconds": remainingSeconds,
            "totalSeconds": totalSeconds,
            "isRunning": isRunning
        ]
        // Stash the latest state (coalesced, survives reconnect, no backlog).
        try? WCSession.default.updateApplicationContext(message)
        // Send live too if the Watch is awake & reachable.
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    /// Call this when the session ends so the Watch can reset its UI.
    func sendSessionEnded() {
        send(["type": "sessionEnded"])
    }

    // MARK: - Private

    /// A paired Watch with the companion app installed actually exists.
    private var hasWatch: Bool {
        WCSession.default.activationState == .activated
            && WCSession.default.isPaired
            && WCSession.default.isWatchAppInstalled
    }

    private func send(_ message: [String: Any]) {
        // No paired/installed Watch — do nothing (and never build a transfer
        // backlog for a Watch that will never receive it).
        guard hasWatch else {
            print("📱⚠️ WatchConnectivityManager: send skipped — no paired Watch")
            return
        }
        guard WCSession.default.isReachable else {
            // Watch paired but asleep — queue this discrete event for delivery.
            print("📱📦 WatchConnectivityManager: watch unreachable, queuing via transferUserInfo — \(message)")
            WCSession.default.transferUserInfo(message.mapValues { $0 as AnyObject } as [String: Any])
            return
        }
        print("📱➡️ WatchConnectivityManager: sendMessage — \(message)")
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("📱❌ WatchConnectivityManager: sendMessage failed — \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate (iPhone side)

extension WatchConnectivityManager: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = (activationState == .activated && session.isReachable)
        }
        if let error {
            print("📱❌ WatchConnectivityManager: activation failed — \(error.localizedDescription)")
        } else {
            print("📱✅ WatchConnectivityManager: activated (state: \(activationState.rawValue), reachable: \(session.isReachable))")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
        print("📱🔄 WatchConnectivityManager: reachability changed — reachable: \(session.isReachable)")
    }

    // Required on iOS (not needed on watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after handoff between Apple Watches
        WCSession.default.activate()
    }

    // Handle any messages sent from the Watch → iPhone (start/pause/stop commands)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        print("📱⬅️ WatchConnectivityManager: received from watch — \(message)")
        DispatchQueue.main.async {
            switch type {
            case "watchCommand":
                let command = message["command"] as? String ?? ""
                NotificationCenter.default.post(
                    name: .watchCommandReceived,
                    object: nil,
                    userInfo: ["command": command]
                )
            default:
                break
            }
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    /// Posted on the iPhone when the Watch sends a session control command.
    /// userInfo["command"] is one of: "start", "pause", "stop"
    static let watchCommandReceived = Notification.Name("vertix.watchCommandReceived")
}

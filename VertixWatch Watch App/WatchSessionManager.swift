//
//  WatchSessionManager.swift
//  VertixWatch
//
//  Receives messages from the iPhone and drives the Watch UI.
//  Also sends session-control commands back to the iPhone.
//

import Foundation
import WatchConnectivity
import UserNotifications

final class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    // MARK: - Published state (drives the Watch UI)

    @Published var phase: String = "Focus"
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var isSessionActive: Bool = false

    // MARK: - Init

    private override init() {
        super.init()
        activateSession()
        requestNotificationPermission()
    }

    // MARK: - Activation

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Commands sent TO the iPhone

    func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["type": "watchCommand", "command": command],
            replyHandler: nil
        ) { error in
            print("WatchSessionManager: sendCommand failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Notification permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Haptic + local notification on bad posture alert

    func handlePostureAlert(message: String) {
        // 1. Haptic tap
        WKInterfaceDevice.current().play(.notification)

        // 2. Local push notification
        let content = UNMutableNotificationContent()
        content.title = "Posture Alert"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("WatchSessionManager: notification failed — \(error)") }
        }
    }
}

// MARK: - WCSessionDelegate (Watch side)

extension WatchSessionManager: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error {
            print("WatchSessionManager: activation failed — \(error.localizedDescription)")
        }
    }

    // Handle real-time messages from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {

            case "sessionState":
                self.phase            = message["phase"]            as? String ?? self.phase
                self.remainingSeconds = message["remainingSeconds"] as? Int    ?? self.remainingSeconds
                self.isRunning        = message["isRunning"]        as? Bool   ?? self.isRunning
                self.isSessionActive  = true

            case "postureAlert":
                let msg = message["message"] as? String ?? "Check your posture"
                self.handlePostureAlert(message: msg)

            case "sessionEnded":
                self.isSessionActive  = false
                self.isRunning        = false
                self.phase            = "Focus"
                self.remainingSeconds = 25 * 60

            default:
                break
            }
        }
    }

    // Handle queued messages sent via transferUserInfo (when Watch was unreachable)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        self.session(session, didReceiveMessage: userInfo)
    }
}

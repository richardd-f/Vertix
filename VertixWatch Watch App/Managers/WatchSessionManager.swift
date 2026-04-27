//
//  WatchSessionManager.swift
//  Vertix
//
//  Created by Felicia Sword on 27/04/26.
//

//  WatchSessionManager.swift
//  VertixWatch Watch App

import WatchConnectivity
import UserNotifications
import WatchKit
import Foundation
import Combine

class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    @Published var lastFeedback: String = ""
    @Published var isPostureBad: Bool = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("✅ WCSession activated on Watch")
        }
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
        }
    }

    func sendHapticAndNotification(feedback: String) {
        // Haptic on Watch
        WKInterfaceDevice.current().play(.notification)

        // Local notification
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Posture Alert"
        content.body = feedback
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("❌ Notification error: \(error)") }
            else { print("✅ Watch notification sent: \(feedback)") }
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("❌ Watch WCSession error: \(error)") }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message["type"] as? String == "postureAlert",
              let feedback = message["feedback"] as? String else { return }

        DispatchQueue.main.async {
            self.lastFeedback = feedback
            self.isPostureBad = true
            self.sendHapticAndNotification(feedback: feedback)
        }
    }
}

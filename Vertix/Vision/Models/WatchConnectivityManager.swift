//
//  WatchConnectivityManager.swift
//  Vertix
//
//  Created by Felicia Sword on 27/04/26.
//

//  WatchConnectivityManager.swift
//  Vertix

import WatchConnectivity
import Foundation
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("✅ WCSession activated on iPad")
        }
    }

    func sendPostureAlert(feedback: String) {
        guard WCSession.default.isReachable else {
            print("⚠️ Watch not reachable")
            return
        }
        let message = ["type": "postureAlert", "feedback": feedback]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("❌ WCSession send error: \(error)")
        }
        print("📤 Sent posture alert to Watch: \(feedback)")
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("❌ WCSession activation error: \(error)") }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}

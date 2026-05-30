//
//  VertixWatchApp.swift
//  VertixWatch
//

import SwiftUI

@main
struct VertixWatchApp: App {

    @StateObject private var watchSession = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(watchSession)
        }
    }
}

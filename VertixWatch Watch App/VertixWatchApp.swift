//
//  VertixWatchApp.swift
//  VertixWatch Watch App
//
//  Created by Felicia Sword on 27/04/26.
//

//  VertixWatchApp.swift
//  VertixWatch Watch App

import SwiftUI

@main
struct VertixWatchApp: App {

    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}

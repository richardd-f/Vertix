//
//  VertixApp.swift
//  Vertix
//
//  Created by student on 16/04/26.
//

import SwiftUI
import FirebaseCore

@main
struct VertixApp: App {
    @State private var authManager: AuthManager
    @State private var gamificationManager: GamificationManager

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
        _gamificationManager = State(initialValue: GamificationManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(gamificationManager)
        }
    }
}

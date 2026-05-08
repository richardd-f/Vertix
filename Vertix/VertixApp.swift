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

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}

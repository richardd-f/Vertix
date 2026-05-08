//
//  ContentView.swift
//  Vertix
//
//  Created by student on 16/04/26.
//

import SwiftUI

struct ContentView: View {
    // Tracks if the user has completed the intro (persists across app restarts)
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    // Reads the auth state from the environment
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                // 1. Show intro if it's their first time
                OnboardingView(hasCompleted: $hasSeenOnboarding)
            } else if !authManager.isAuthenticated {
                // 2. Show login/register if they aren't logged in
                AuthContainerView()
            } else {
                // 3. Show the main app if they are logged in
                MainTabView()
            }
        }
        // Adds a nice fade transition when switching between these major app states
        .animation(.easeInOut, value: hasSeenOnboarding)
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}

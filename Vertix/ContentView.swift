//
//  ContentView.swift
//  Vertix
//
//  Created by student on 16/04/26.
//

import SwiftUI

struct ContentView: View {
    
    // Persists across app launches (once you've seen onboarding, skip it)
        @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    ContentView()
}

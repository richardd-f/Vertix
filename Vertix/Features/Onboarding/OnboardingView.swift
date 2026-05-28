//
//  OnboardingView.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//
import SwiftUI
// Data Model
// Each slide's content is defined here — easy to edit later
struct OnboardingPage {
    let imageName: String
    let tag: String?
    let title: String
    let description: String
}
// Main Onboarding View
struct OnboardingView: View {
    
    // Tracks which slide the user is on (0, 1, or 2)
    @State private var currentPage = 0
    
    // When this becomes true, we navigate to Home
    @Binding var hasCompletedOnboarding: Bool
    
    // The three slides — image names must match your Assets exactly
    let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "study-smarter",
            tag: nil,
            title: "Study Smarter",
            description: "Combine focus with health. Use our Pomodoro timer to stay productive while we watch your back."
        ),
        OnboardingPage(
            imageName: "fix-your-posture",
            tag: "POSTURE DETECTION",
            title: "Fix Your Posture",
            description: "Real-time camera detection alerts you when you slouch, helping you maintain a healthy spine during long study sessions."
        ),
        OnboardingPage(
            imageName: "feel-the-difference",
            tag: "BUILD HABITS",
            title: "Feel the Difference",
            description: "Track your progress, earn streaks, and build healthy habits that last a lifetime. Ready to start?"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background color matching the mockup
            Color(hex: "F2F0EB")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Swipeable slides
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom section: dots + button
                VStack(spacing: 32) {
                    
                    // Page indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color(hex: "2D5A3D") : Color(hex: "2D5A3D").opacity(0.25))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Next / Get Started button
                    Button(action: handleButtonTap) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "2D5A3D"))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }
    
    // Advance slide or finish onboarding
    private func handleButtonTap() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            hasCompletedOnboarding = true
        }
    }
}
// Single Slide View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration card
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0))  // fully transparent
                    .frame(width: 280, height: 280)
                
                VStack(spacing: 12) {
                    // Optional tag badge (e.g. "POSTURE DETECTION")
                    if let tag = page.tag {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "2D5A3D"))
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "2D5A3D"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "2D5A3D").opacity(0.1))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    
                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
                }
            }
            
            Spacer()
            
            // Title + description
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}


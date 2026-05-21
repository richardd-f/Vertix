import Foundation

struct OnboardingStep: Identifiable {
    let id = UUID()
    let imageName: String     // The name of the image in your Assets.xcassets
    let badgeIcon: String?    // Optional SF Symbol for the pill
    let badgeText: String?    // Optional text for the pill
    let title: String
    let description: String
}

extension OnboardingStep {
    static let steps: [OnboardingStep] = [
        OnboardingStep(
            imageName: "onboarding_1", // Replace with your actual image asset name
            badgeIcon: nil,
            badgeText: nil,
            title: "Study Smarter",
            description: "Combine focus with health. Use our Pomodoro timer to stay productive while we watch your back."
        ),
        OnboardingStep(
            imageName: "onboarding_2",
            badgeIcon: "camera.fill",
            badgeText: "POSTURE DETECTION",
            title: "Fix Your Posture",
            description: "Real-time camera detection alerts you when you slouch, helping you maintain a healthy spine during long study sessions."
        ),
        OnboardingStep(
            imageName: "onboarding_3",
            badgeIcon: "leaf.fill", // Using a leaf as a placeholder for the seedling
            badgeText: "BUILD HABITS",
            title: "Feel the Difference",
            description: "Track your progress, earn streaks, and build healthy habits that last a lifetime. Ready to start?"
        )
    ]
}
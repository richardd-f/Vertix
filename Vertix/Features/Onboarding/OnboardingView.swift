import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompleted: Bool
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Carousel
            TabView(selection: $currentStep) {
                ForEach(0..<OnboardingStep.steps.count, id: \.self) { index in
                    let step = OnboardingStep.steps[index]
                    
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // Main Illustration
                        // Note: Using a placeholder rounded rectangle until you add your images to Assets
                        Group {
                            if let image = UIImage(named: step.imageName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            }
                        }
                        .frame(height: 300)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        
                        // Optional Badge (Pill)
                        if let badgeText = step.badgeText, let badgeIcon = step.badgeIcon {
                            HStack(spacing: 6) {
                                Image(systemName: badgeIcon)
                                    .font(.system(size: 12, weight: .bold))
                                Text(badgeText)
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.0) // Adds slight letter spacing
                            }
                            .foregroundColor(Color.vertixDarkGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.vertixDarkGreen.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        // Title
                        Text(step.title)
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                        
                        // Description
                        Text(step.description)
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.secondary)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                        
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hides default dots
            
            // MARK: - Bottom Controls
            VStack(spacing: 32) {
                // Custom Dot Indicator
                HStack(spacing: 8) {
                    ForEach(0..<OnboardingStep.steps.count, id: \.self) { index in
                        Capsule()
                            .fill(currentStep == index ? Color.vertixDarkGreen : Color.vertixDarkGreen.opacity(0.2))
                            .frame(width: currentStep == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                    }
                }
                
                // Next / Get Started Button
                Button(action: handleNextButton) {
                    HStack {
                        Text(currentStep == OnboardingStep.steps.count - 1 ? "Get Started" : "Next")
                        
                        // Show arrow on the 2nd and 3rd screens
                        if currentStep > 0 {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.vertixDarkGreen)
                    .clipShape(Capsule())
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color.vertixBackground.ignoresSafeArea())
    }
    
    // MARK: - Actions
    private func handleNextButton() {
        if currentStep < OnboardingStep.steps.count - 1 {
            withAnimation { currentStep += 1 }
        } else {
            // Dismiss onboarding and move to Auth
            hasCompleted = true
        }
    }
}

// MARK: - Custom Colors
extension Color {
    // Extracted directly from your screenshots
    static let vertixDarkGreen = Color(red: 45/255, green: 79/255, blue: 68/255)
    static let vertixBackground = Color(red: 244/255, green: 242/255, blue: 238/255)
}
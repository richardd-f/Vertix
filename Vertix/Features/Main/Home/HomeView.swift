
import SwiftUI
import Observation

@Observable
class HomeViewModel {
    var userName: String = "Alex"
    var weeklyAverageScore: Int = 85
    var lastSessionScore: Int = 92
    var isSessionActive: Bool = false
    
    func toggleSession() {
        isSessionActive.toggle()
        // Logic to start/stop posture tracking
    }
}

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Greetings
                    HStack {
                        Text("Good morning, \(viewModel.userName)!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    // Dashboard Cards
                    HStack(spacing: 16) {
                        ScoreCardView(title: "Weekly Avg", score: viewModel.weeklyAverageScore)
                        ScoreCardView(title: "Last Session", score: viewModel.lastSessionScore)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Action Button
                    Button(action: {
                        viewModel.toggleSession()
                    }) {
                        Text(viewModel.isSessionActive ? "Stop Session" : "Start Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isSessionActive ? Color.red : Color.blue)
                            .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

// Reusable component that belongs in Core/Components
struct ScoreCardView: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(score)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
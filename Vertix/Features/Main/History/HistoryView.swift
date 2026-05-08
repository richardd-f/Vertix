import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel() // ViewModel would fetch the data
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    MonthlyOverviewCard()
                    WeeklyPostureChart()
                    RecentSessionsList()
                }
                .padding()
            }
            .navigationTitle("History")
        }
    }
}

// MARK: - Subviews

private struct MonthlyOverviewCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Overview")
                .font(.headline)
            // Card content here...
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 120)
        }
    }
}

private struct WeeklyPostureChart: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Posture")
                .font(.headline)
            // Swift Charts implementation would go here...
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
        }
    }
}

private struct RecentSessionsList: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Sessions")
                .font(.headline)
            
            // List of recent items...
            ForEach(0..<3) { _ in
                HStack {
                    Image(systemName: "figure.seated.side")
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Working at Desk")
                            .font(.subheadline).bold()
                        Text("2 hours ago")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Score: 88")
                        .font(.subheadline).bold()
                }
                .padding(.vertical, 8)
            }
        }
    }
}
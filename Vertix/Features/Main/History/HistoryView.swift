import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = HistoryViewModel()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vertixBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("History")
                                    .font(.largeTitle).bold()
                                Text(viewModel.monthLabel)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.vertixDarkGreen)
                                    .padding(12)
                                    .background(Color.vertixCardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                        .padding(.horizontal, 24)

                        // MARK: Monthly Overview
                        VStack(spacing: 16) {
                            HStack {
                                Text("MONTHLY OVERVIEW")
                                    .font(.caption).bold().tracking(1.0).foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("Less").font(.caption2).foregroundColor(.secondary)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixFieldBackground).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixLightGreen.opacity(0.5)).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixLightGreen).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixDarkGreen).frame(width: 12, height: 12)
                                    Text("More").font(.caption2).foregroundColor(.secondary)
                                }
                            }

                            LazyVGrid(columns: columns, spacing: 10) {
                                // Day-of-week headers
                                ForEach(daysOfWeek, id: \.self) { day in
                                    Text(day).font(.caption2).foregroundColor(.secondary)
                                }

                                // Blank cells to align 1st of month to correct weekday
                                ForEach(0..<viewModel.calendarStartPadding, id: \.self) { _ in
                                    Color.clear.frame(height: 35)
                                }

                                ForEach(viewModel.currentMonthDays, id: \.self) { day in
                                    let level = viewModel.scoreLevel(for: day)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(level == 3 ? Color.vertixDarkGreen :
                                              level == 2 ? Color.vertixLightGreen :
                                              level == 1 ? Color.vertixLightGreen.opacity(0.4) :
                                                Color.vertixFieldBackground)
                                        .frame(height: 35)
                                        .overlay(Text("\(day)").font(.caption).foregroundColor(level >= 2 ? .white : .primary))
                                }
                            }

                            Divider().padding(.vertical, 8)

                            HStack {
                                Label("\(viewModel.monthSessionCount) sessions", systemImage: "circle.fill")
                                    .font(.caption).foregroundColor(.vertixDarkGreen)
                                Spacer()
                                Label("Avg \(viewModel.monthAvgScore)%", systemImage: "circle.fill")
                                    .font(.caption).foregroundColor(.vertixLightGreen)
                                Spacer()
                                Label("\(viewModel.currentStreak)-day streak", systemImage: "flame.fill")
                                    .font(.caption).foregroundColor(.orange)
                            }
                        }
                        .padding(20)
                        .background(Color.vertixCardBackground)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10)
                        .padding(.horizontal, 20)

                        // MARK: Weekly Posture Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("WEEKLY POSTURE")
                                .font(.caption).bold().tracking(1.0).foregroundColor(.secondary)

                            if viewModel.weeklyData.allSatisfy({ $0.score == 0 }) {
                                Text("No session data for the past 7 days.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 150)
                            } else {
                                Chart {
                                    ForEach(viewModel.weeklyData, id: \.day) { item in
                                        LineMark(
                                            x: .value("Day", item.day),
                                            y: .value("Score", item.score)
                                        )
                                        .foregroundStyle(Color.vertixDarkGreen)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        .symbol(Circle())
                                        .symbolSize(60)

                                        AreaMark(
                                            x: .value("Day", item.day),
                                            yStart: .value("Min", 0),
                                            yEnd: .value("Score", item.score)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.vertixDarkGreen.opacity(0.3), .clear]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    }
                                }
                                .chartYScale(domain: 0...100)
                                .frame(height: 150)
                            }
                        }
                        .padding(20)
                        .background(Color.vertixCardBackground)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .task {
            await viewModel.load(uid: authManager.currentUser?.id ?? "")
        }
    }
}

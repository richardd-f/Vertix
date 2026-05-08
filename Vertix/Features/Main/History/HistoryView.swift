import SwiftUI
import Charts // Required for the Weekly chart

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    
    // Data for the mock chart
    let weeklyData: [(day: String, score: Int)] = [
        ("Mon", 78), ("Tue", 82), ("Wed", 79), ("Thu", 85),
        ("Fri", 92), ("Sat", 88), ("Sun", 90)
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
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
                                Text("October 2024")
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
                                // Legend
                                HStack(spacing: 4) {
                                    Text("Less").font(.caption2).foregroundColor(.secondary)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixFieldBackground).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixLightGreen.opacity(0.5)).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixLightGreen).frame(width: 12, height: 12)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.vertixDarkGreen).frame(width: 12, height: 12)
                                    Text("More").font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            
                            // Calendar Grid
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(daysOfWeek, id: \.self) { day in
                                    Text(day).font(.caption2).foregroundColor(.secondary)
                                }
                                
                                // Padding for starting day of month
                                Color.clear
                                
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
                                Label("18 sessions", systemImage: "circle.fill").font(.caption).foregroundColor(.vertixDarkGreen)
                                Spacer()
                                Label("Avg 88%", systemImage: "circle.fill").font(.caption).foregroundColor(.vertixLightGreen)
                                Spacer()
                                Label("4-day streak", systemImage: "flame.fill").font(.caption).foregroundColor(.orange)
                            }
                        }
                        .padding(20)
                        .background(Color.vertixCardBackground)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10)
                        .padding(.horizontal, 20)
                        
                        // MARK: Weekly Posture Chart
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("WEEKLY POSTURE")
                                    .font(.caption).bold().tracking(1.0).foregroundColor(.secondary)
                                Spacer()
                                Text("↗ +6% this week")
                                    .font(.caption).bold().foregroundColor(.vertixDarkGreen)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.vertixDarkGreen.opacity(0.1)).clipShape(Capsule())
                            }
                            
                            Chart {
                                ForEach(weeklyData, id: \.day) { item in
                                    LineMark(
                                        x: .value("Day", item.day),
                                        y: .value("Score", item.score)
                                    )
                                    .foregroundStyle(Color.vertixDarkGreen)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .symbol(Circle().strokeBorder(Color.white, lineWidth: 2))
                                    .symbolSize(60)
                                    
                                    AreaMark(
                                        x: .value("Day", item.day),
                                        yStart: .value("Min", 60),
                                        yEnd: .value("Score", item.score)
                                    )
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.vertixDarkGreen.opacity(0.3), .clear]), startPoint: .top, endPoint: .bottom))
                                }
                            }
                            .chartYScale(domain: 60...100)
                            .frame(height: 150)
                        }
                        .padding(20)
                        .background(Color.vertixCardBackground)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100) // Padding for tab bar
                }
            }
        }
    }
}
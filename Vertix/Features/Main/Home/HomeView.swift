import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            Color.vertixBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(viewModel.userName)
                                .font(.title)
                                .fontWeight(.bold)
                            Text("👋")
                                .font(.title)
                        }
                    }
                    Spacer()
                    
                    // Mock Avatar
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: Average Score Card
                VStack(spacing: 16) {
                    Text("AVERAGE POSTURE SCORE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.5)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        // Background Circle
                        Circle()
                            .stroke(Color.vertixDarkGreen.opacity(0.1), lineWidth: 15)
                            .frame(width: 150, height: 150)
                        
                        // Progress Circle
                        Circle()
                            .trim(from: 0.0, to: CGFloat(viewModel.averageScore) / 100.0)
                            .stroke(Color.vertixDarkGreen, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.5), value: viewModel.averageScore)
                        
                        VStack(spacing: 2) {
                            Text("\(viewModel.averageScore)%")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                            Text("Great Form")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Pill Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.vertixDarkGreen)
                            .frame(width: 8, height: 8)
                        Text("Above average")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.vertixDarkGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vertixDarkGreen.opacity(0.1))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.vertixCardBackground)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                // MARK: Start Session Button
                Button(action: {
                    viewModel.toggleSession()
                }) {
                    HStack {
                        Image(systemName: viewModel.isSessionActive ? "stop.fill" : "play.fill")
                            .foregroundColor(.vertixDarkGreen)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                        
                        Text(viewModel.isSessionActive ? "Stop Session" : "Start Session")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(viewModel.isSessionActive ? Color.red : Color.vertixDarkGreen)
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                }
                
                // MARK: Last Session Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("LAST SESSION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1.0)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.vertixDarkGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.vertixDarkGreen.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vertixDarkGreen.opacity(0.1))
                                .frame(width: 50, height: 50)
                            Image(systemName: "figure.mind.and.body")
                                .foregroundColor(.vertixDarkGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.lastSessionDuration) Focus Session")
                                .font(.headline)
                            HStack(spacing: 4) {
                                Circle().fill(Color.vertixDarkGreen).frame(width: 6, height: 6)
                                Text("95% Good Posture")
                                    .font(.caption)
                                    .foregroundColor(Color.vertixDarkGreen)
                            }
                        }
                        Spacer()
                        VStack {
                            Text("\(viewModel.lastSessionScore)")
                                .font(.title2).bold()
                            Text("score")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    
                    // Simple progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                            Capsule().fill(Color.vertixDarkGreen)
                                .frame(width: geometry.size.width * 0.95, height: 6) // 95%
                        }
                    }
                    .frame(height: 6)
                }
                .padding(20)
                .background(Color.vertixCardBackground)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
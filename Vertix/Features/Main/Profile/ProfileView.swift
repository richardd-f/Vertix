import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vertixBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Profile")
                                    .font(.largeTitle).bold()
                                Text("Manage your personal wellness identity")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.vertixDarkGreen)
                                    .padding(12)
                                    .background(Color.vertixCardBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // MARK: User Card
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "person.fill").font(.largeTitle).foregroundColor(.gray))
                                
                                Circle()
                                    .fill(Color.vertixDarkGreen)
                                    .frame(width: 24, height: 24)
                                    .overlay(Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(.white))
                            }
                            
                            Text(viewModel.name)
                                .font(.title3).bold()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill").foregroundColor(.orange)
                                Text("PREMIUM MEMBER")
                            }
                            .font(.caption).bold()
                            .foregroundColor(Color.vertixDarkGreen)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.vertixDarkGreen.opacity(0.1)).clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.vertixCardBackground)
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                        
                        // MARK: Stats Row
                        HStack(spacing: 16) {
                            StatCard(icon: "waveform.path.ecg", title: "AVG. SCORE", value: "\(viewModel.avgScore)", suffix: "%")
                            StatCard(icon: "apple.logo", title: "TRACKED", value: "\(viewModel.trackedHours)", suffix: "h")
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: Settings Lists
                        SettingsGroup(title: "PERSONAL INFO") {
                            SettingsRow(icon: "envelope.fill", title: "Email", subtitle: viewModel.email)
                            SettingsRow(icon: "phone.fill", title: "Phone", subtitle: viewModel.phone)
                        }
                        
                        SettingsGroup(title: "ACCOUNT SECURITY") {
                            SettingsRow(icon: "lock.fill", title: "Password", subtitle: "Last changed 3 months ago")
                        }
                        
                        SettingsGroup(title: "PREFERENCES") {
                            SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Posture alerts & Weekly summaries")
                        }
                        
                        // MARK: Logout Button
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(Color.vertixDangerText)
                            .padding()
                            .background(Color.vertixDanger)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Reusable Profile Components
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let suffix: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(.vertixDarkGreen)
                Text(title).font(.caption).bold().foregroundColor(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 32, weight: .bold))
                Text(suffix).font(.body).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.vertixCardBackground)
        .cornerRadius(20)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption).bold().tracking(1.0).foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.vertixCardBackground)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.vertixDarkGreen)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold()
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
        Divider().padding(.leading, 50)
    }
}
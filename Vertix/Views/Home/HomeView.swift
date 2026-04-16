//
//  HomeView.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//

import SwiftUI

struct HomeView: View {
    
    // We'll replace these with real Firebase data later
    @State private var userName = "Budi"
    @State private var lastPostureScore: Double = 82
    @State private var lastSessionDuration = "25m"
    @State private var lastSessionScore: Double = 95
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F0EB")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header
                        headerSection
                        
                        // Posture Score Card
                        postureScoreCard
                        
                        // Start Session Button
                        startSessionButton
                        
                        // Last Session Button
                        lastSessionCard
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    // Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingMessage)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "6B6B6B"))
                Text(userName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
            
            Spacer()
            
            // DEV ONLY (remove before submission)
                    Button("Reset") {
                        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            
            // Avatar placeholder (can replace with real photo later)
            Circle()
                .fill(Color(hex: "2D5A3D").opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(userName.prefix(1))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2D5A3D"))
                )
        }
    }
    
    // Posture Score Card
    private var postureScoreCard: some View {
        VStack(spacing: 16) {
            Text("LAST POSTURE SCORE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "6B6B6B"))
                .tracking(1.2)
            
            // Circular progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(hex: "2D5A3D").opacity(0.1), lineWidth: 10)
                    .frame(width: 140, height: 140)
                
                // Score ring
                Circle()
                    .trim(from: 0, to: lastPostureScore / 100)
                    .stroke(Color(hex: "2D5A3D"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: lastPostureScore)
                
                // Score text
                VStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 1) {
                        Text("\(Int(lastPostureScore))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                            .padding(.top, 6)
                    }
                    Text(postureLabel)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6B6B6B"))
                }
            }
            
            // Status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "2D5A3D"))
                    .frame(width: 7, height: 7)
                Text(postureStatusText)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "2D5A3D"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "2D5A3D").opacity(0.08))
            .cornerRadius(20)
            
            // Encouragement message
            Text("You're doing great, keep your posture strong 💪")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B6B6B"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
    
    // Start Session Button
    private var startSessionButton: some View {
        NavigationLink(destination: SessionView()) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text("Start Session")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .frame(height: 60)
            .background(Color(hex: "2D5A3D"))
            .cornerRadius(16)
        }
    }
    
    // Last Session Card
    private var lastSessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LAST SESSION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .tracking(1.2)
                Spacer()
                Text("Today")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "2D5A3D"))
            }
            
            HStack(spacing: 16) {
                // Session icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2D5A3D").opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "timer")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "2D5A3D"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(lastSessionDuration) Focus Session")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "2D5A3D"))
                            .frame(width: 6, height: 6)
                        Text("\(Int(lastSessionScore))% Good Posture")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "6B6B6B"))
                    }
                }
                
                Spacer()
                
                // Score badge
                VStack(spacing: 2) {
                    Text("\(Int(lastSessionScore))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("score")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "6B6B6B"))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
    
    // Helpers
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
    
    private var postureLabel: String {
        switch lastPostureScore {
        case 80...100: return "Great Form"
        case 60..<80: return "Good Form"
        case 40..<60: return "Fair Form"
        default: return "Needs Work"
        }
    }
    
    private var postureStatusText: String {
        lastPostureScore >= 80 ? "Above average" : "Keep improving"
    }
}

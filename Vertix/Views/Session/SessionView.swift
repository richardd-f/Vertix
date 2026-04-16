//
//  SessionView.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//

import SwiftUI

struct SessionView: View {
    
    @StateObject private var viewModel = SessionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color(hex: "F2F0EB")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Camera Placeholder
                cameraPlaceholder
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // Posture Indicators (AI Placeholder)
                        postureIndicatorsCard
                        
                        // Pomodoro Timer Card
                        pomodoroCard
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            
            // End Session Overlay Button
            VStack {
                HStack {
                    Button(action: {
                        viewModel.endSession()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                            Text("End Session")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.leading, 16)
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.resetTimer()
        }
    }
    
    // Camera Placeholder
    // TO DO: Replace ZStack contents with CameraPreviewView() when AI module is ready
    private var cameraPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "1A1A1A"))
                .frame(height: 240)
            
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.3))
                Text("Camera feed will appear here")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            // LIVE badge
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                    .padding(12)
                }
                Spacer()
            }
        }
        .frame(height: 240)
    }
    
    // Posture Indicators Card
    // TO DO: Wire these values to PostureAnalyzing protocol when AI module is ready
    private var postureIndicatorsCard: some View {
        VStack(spacing: 14) {
            
            // Shoulder angle
            VStack(alignment: .leading, spacing: 8) {
                Text("SHOULDER ANGLE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .tracking(1)
                
                HStack {
                    Text("Left")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6B6B6B"))
                    Spacer()
                    
                    // Angle indicator (placeholder)
                    ZStack {
                        Capsule()
                            .fill(Color(hex: "2D5A3D").opacity(0.1))
                            .frame(width: 120, height: 8)
                        Circle()
                            .fill(Color(hex: "2D5A3D"))
                            .frame(width: 14, height: 14)
                            .offset(x: viewModel.postureData.shoulderOffset)
                        Text("+\(Int(viewModel.postureData.shoulderAngle))°")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "2D5A3D"))
                            .offset(x: viewModel.postureData.shoulderOffset, y: -14)
                    }
                    
                    Spacer()
                    Text("Right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "6B6B6B"))
                }
                
                Text("0° Ideal")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            // Spine alignment bars
            VStack(alignment: .leading, spacing: 10) {
                Text("SPINE ALIGNMENT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .tracking(1)
                
                SpineBarRow(label: "Neck",  value: viewModel.postureData.neckScore)
                SpineBarRow(label: "Upper", value: viewModel.postureData.upperScore)
                SpineBarRow(label: "Lower", value: viewModel.postureData.lowerScore)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // Pomodoro Timer Card
    private var pomodoroCard: some View {
        VStack(spacing: 20) {
            
            // Settings Icon
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: viewModel.phaseColor))
                    .frame(width: 8, height: 8)
                Text(viewModel.phaseLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: viewModel.phaseColor))
                    .tracking(1.2)
                Spacer()
                
                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "6B6B6B").opacity(0.08))
                        .clipShape(Circle())
                }
            }
            
            HStack(spacing: 32) {
                
                // Circular timer
                ZStack {
                    Circle()
                        .stroke(Color(hex: "2D5A3D").opacity(0.1), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.timerProgress)
                        .stroke(Color(hex: "2D5A3D"),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.timerProgress)
                    
                    VStack(spacing: 2) {
                        Text(viewModel.timeDisplay)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Text("remaining")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "6B6B6B"))
                    }
                }
                
                // Session dots + controls
                VStack(spacing: 16) {
                    
                    // Cycle dots (e.g. Session 1 of 4)
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index < viewModel.completedCycles
                                          ? Color(hex: "2D5A3D")
                                          : Color(hex: "2D5A3D").opacity(0.2))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text("Session \(viewModel.completedCycles + 1) of 4")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "6B6B6B"))
                    }
                    
                    // Timer controls
                    HStack(spacing: 16) {
                        // Reset
                        Button(action: { viewModel.resetTimer() }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6B6B6B"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "6B6B6B").opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        // Play / Pause
                        Button(action: { viewModel.toggleTimer() }) {
                            Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "2D5A3D"))
                                .clipShape(Circle())
                        }
                        
                        // Skip
                        Button(action: { viewModel.skipCycle() }) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6B6B6B"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "6B6B6B").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showSettings) {
            SessionSettingsSheet(
                focusDuration: viewModel.focusDuration,
                shortBreakDuration: viewModel.shortBreakDuration,
                longBreakDuration: viewModel.longBreakDuration,
                cyclesBeforeLongBreak: viewModel.cyclesBeforeLongBreak
            ) { focus, shortBreak, longBreak, cycles in
                viewModel.applySettings(
                    focus: focus,
                    shortBreak: shortBreak,
                    longBreak: longBreak,
                    cycles: cycles
                )
            }
        }
    }
}

// Spine Bar Row
struct SpineBarRow: View {
    let label: String
    let value: Double // 0 to 100
    
    private var barColor: Color {
        value >= 80 ? Color(hex: "2D5A3D") : Color(hex: "E05A3A")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B6B6B"))
                .frame(width: 40, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "F2F0EB"))
                        .frame(height: 8)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * (value / 100), height: 8)
                        .animation(.easeInOut(duration: 0.8), value: value)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(value))%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(barColor)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

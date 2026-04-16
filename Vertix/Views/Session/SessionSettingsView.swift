//
//  SessionSettingsView.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//

import SwiftUI

struct SessionSettingsSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // Local copies so changes only apply when user taps Save
    @State private var focusDuration: Int
    @State private var shortBreakDuration: Int
    @State private var longBreakDuration: Int
    @State private var cyclesBeforeLongBreak: Int
    
    // Called when user taps Save
    var onSave: (Int, Int, Int, Int) -> Void
    
    init(
        focusDuration: Int,
        shortBreakDuration: Int,
        longBreakDuration: Int,
        cyclesBeforeLongBreak: Int,
        onSave: @escaping (Int, Int, Int, Int) -> Void
    ) {
        _focusDuration = State(initialValue: focusDuration)
        _shortBreakDuration = State(initialValue: shortBreakDuration)
        _longBreakDuration = State(initialValue: longBreakDuration)
        _cyclesBeforeLongBreak = State(initialValue: cyclesBeforeLongBreak)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F0EB")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    
                    // Duration Settings
                    VStack(spacing: 0) {
                        SettingsStepperRow(
                            icon: "timer",
                            iconColor: "2D5A3D",
                            title: "Focus Duration",
                            subtitle: "How long each focus session lasts",
                            value: $focusDuration,
                            range: 5...60,
                            unit: "min"
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        SettingsStepperRow(
                            icon: "cup.and.saucer.fill",
                            iconColor: "3A7CA5",
                            title: "Short Break",
                            subtitle: "Break between focus sessions",
                            value: $shortBreakDuration,
                            range: 1...15,
                            unit: "min"
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        SettingsStepperRow(
                            icon: "moon.fill",
                            iconColor: "7B4EA6",
                            title: "Long Break",
                            subtitle: "Break after completing all cycles",
                            value: $longBreakDuration,
                            range: 5...30,
                            unit: "min"
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Cycles Setting
                    VStack(spacing: 0) {
                        SettingsStepperRow(
                            icon: "arrow.clockwise",
                            iconColor: "E05A3A",
                            title: "Cycles",
                            subtitle: "Focus sessions before a long break",
                            value: $cyclesBeforeLongBreak,
                            range: 2...8,
                            unit: "cycles"
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // Preview
                    sessionPreviewCard
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        onSave(focusDuration, shortBreakDuration, longBreakDuration, cyclesBeforeLongBreak)
                        dismiss()
                    }) {
                        Text("Save Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "2D5A3D"))
                            .cornerRadius(16)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Session Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "2D5A3D"))
                }
            }
        }
    }
    
    // Shows a summary of what the full session will look like
    private var sessionPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SESSION PREVIEW")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "6B6B6B"))
                .tracking(1.2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<cyclesBeforeLongBreak, id: \.self) { index in
                        HStack(spacing: 0) {
                            // Focus block
                            Text("\(focusDuration)m")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "2D5A3D"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "2D5A3D").opacity(0.12))
                                .cornerRadius(6)
                            
                            // Short break block (except after last cycle)
                            if index < cyclesBeforeLongBreak - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(hex: "6B6B6B"))
                                    .padding(.horizontal, 4)
                                
                                Text("\(shortBreakDuration)m")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "3A7CA5"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "3A7CA5").opacity(0.12))
                                    .cornerRadius(6)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(hex: "6B6B6B"))
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    
                    // Long break at the end
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .padding(.horizontal, 4)
                    
                    Text("\(longBreakDuration)m")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "7B4EA6"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "7B4EA6").opacity(0.12))
                        .cornerRadius(6)
                }
                .padding(.vertical, 4) // prevents clipping on scroll
            }
            
            // Total time
            let totalMinutes = (focusDuration * cyclesBeforeLongBreak) +
                               (shortBreakDuration * (cyclesBeforeLongBreak - 1)) +
                               longBreakDuration
            Text("Total session: ~\(totalMinutes) minutes")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "6B6B6B"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Reusable Stepper Row
struct SettingsStepperRow: View {
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: iconColor).opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: iconColor))
                )
            
            // Title + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6B6B6B"))
            }
            
            Spacer()
            
            // Stepper controls
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound { value -= 1 }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(value <= range.lowerBound
                                         ? Color(hex: "6B6B6B").opacity(0.3)
                                         : Color(hex: iconColor))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: iconColor).opacity(0.1))
                        .clipShape(Circle())
                }
                
                Text("\(value)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .frame(width: 28, alignment: .center)
                
                Button(action: {
                    if value < range.upperBound { value += 1 }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(value >= range.upperBound
                                         ? Color(hex: "6B6B6B").opacity(0.3)
                                         : Color(hex: iconColor))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: iconColor).opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

//
//  SessionSettingsView.swift
//  Vertix
//
//  Created by Clarice Harijanto on 30/05/26.
//

import SwiftUI

struct SessionSettingsView: View {
    @Binding var focusDuration: Int
    @Binding var shortBreakDuration: Int
    @Binding var longBreakDuration: Int
    @Binding var cyclesBeforeLongBreak: Int
    var onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 244/255, green: 242/255, blue: 238/255).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        cyclePreview
                        settingsCard
                        applyButton
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Session Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(red: 45/255, green: 79/255, blue: 68/255))
                }
            }
        }
    }

    // MARK: Cycle preview

    private var sequencePreview: [TimerPhase] {
        var seq: [TimerPhase] = []
        for i in 0..<cyclesBeforeLongBreak {
            seq.append(.focus)
            seq.append(i < cyclesBeforeLongBreak - 1 ? .shortBreak : .longBreak)
        }
        return seq
    }

    private func durationLabel(for phase: TimerPhase) -> String {
        switch phase {
        case .focus:      return "\(focusDuration)m"
        case .shortBreak: return "\(shortBreakDuration)m"
        case .longBreak:  return "\(longBreakDuration)m"
        }
    }

    private var cyclePreview: some View {
        VStack(spacing: 12) {
            Text("SESSION STRUCTURE")
                .font(.caption).bold().tracking(1.0)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(sequencePreview.enumerated()), id: \.offset) { idx, phase in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(phase.color.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(phase.color, lineWidth: 1.5)
                                )
                                .frame(width: 48, height: 36)
                                .overlay(
                                    Image(systemName: phase.icon)
                                        .font(.system(size: 13))
                                        .foregroundColor(phase.color)
                                )

                            Text(durationLabel(for: phase))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(phase.color)
                        }

                        if idx < sequencePreview.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.3), value: cyclesBeforeLongBreak)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 8)
        .padding(.horizontal, 20)
    }

    // MARK: Settings rows

    private var settingsCard: some View {
        VStack(spacing: 0) {
            durationRow(
                icon: TimerPhase.focus.icon,
                color: TimerPhase.focus.color,
                label: "Focus",
                value: $focusDuration,
                range: 5...60, step: 5
            )
            Divider().padding(.leading, 56)
            durationRow(
                icon: TimerPhase.shortBreak.icon,
                color: TimerPhase.shortBreak.color,
                label: "Short Break",
                value: $shortBreakDuration,
                range: 1...15, step: 1
            )
            Divider().padding(.leading, 56)
            durationRow(
                icon: TimerPhase.longBreak.icon,
                color: TimerPhase.longBreak.color,
                label: "Long Break",
                value: $longBreakDuration,
                range: 5...30, step: 5
            )
            Divider().padding(.leading, 56)
            cyclesRow
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 8)
        .padding(.horizontal, 20)
    }

    private func durationRow(
        icon: String,
        color: Color,
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.subheadline).fontWeight(.medium)
            Spacer()
            HStack(spacing: 2) {
                Button {
                    if value.wrappedValue - step >= range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(color.opacity(0.8))
                        .font(.title3)
                }
                Text("\(value.wrappedValue)m")
                    .font(.system(size: 15, weight: .bold))
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
                Button {
                    if value.wrappedValue + step <= range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color.opacity(0.8))
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var cyclesRow: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "repeat")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Cycles")
                    .font(.subheadline).fontWeight(.medium)
                Text("Focus blocks before long break")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 2) {
                Button {
                    if cyclesBeforeLongBreak > 2 { cyclesBeforeLongBreak -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(Color.orange.opacity(0.8))
                        .font(.title3)
                }
                Text("\(cyclesBeforeLongBreak)")
                    .font(.system(size: 15, weight: .bold))
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
                Button {
                    if cyclesBeforeLongBreak < 8 { cyclesBeforeLongBreak += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.orange.opacity(0.8))
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: Apply button

    private var applyButton: some View {
        Button {
            onApply()
            dismiss()
        } label: {
            Text("Apply & Reset Timer")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 45/255, green: 79/255, blue: 68/255))
                .cornerRadius(16)
        }
        .padding(.horizontal, 20)
    }
}

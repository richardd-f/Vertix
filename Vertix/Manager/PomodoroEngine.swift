//
//  PomodoroEngine.swift
//  Vertix
//
//  Created by Clarice Harijanto on 30/05/26.
//

import SwiftUI
import Observation

// MARK: - TimerPhase

enum TimerPhase: Equatable {
    case focus, shortBreak, longBreak

    var label: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .focus:      return Color(red: 45/255,  green: 79/255,  blue: 68/255)   // vertixDarkGreen
        case .shortBreak: return Color(red: 33/255,  green: 150/255, blue: 243/255)  // blue
        case .longBreak:  return Color(red: 156/255, green: 39/255,  blue: 176/255)  // purple
        }
    }
}

// MARK: - PomodoroEngine

@Observable
class PomodoroEngine {

    // MARK: Settings
    var focusDuration: Int          = 25   // minutes
    var shortBreakDuration: Int     = 5
    var longBreakDuration: Int      = 15
    var cyclesBeforeLongBreak: Int  = 4    // focus blocks per long break

    // MARK: Runtime state
    var currentPhase: TimerPhase    = .focus
    var timeRemaining: Int          = 25 * 60
    var totalPhaseSeconds: Int      = 25 * 60
    var isRunning: Bool             = false
    var allCyclesComplete: Bool     = false
    var focusSecondsElapsed: Int    = 0   // only counts focus time, for SessionManager

    // Tracks which step in the flat sequence we're on
    private(set) var phaseSequenceIndex: Int = 0

    // Cycle number shown in "Session X of Y"
    private(set) var currentCycle: Int = 1

    // MARK: Computed

    var progress: Double {
        guard totalPhaseSeconds > 0 else { return 0 }
        return 1.0 - Double(timeRemaining) / Double(totalPhaseSeconds)
    }

    var sessionLabel: String { "Session \(currentCycle) of \(cyclesBeforeLongBreak)" }

    var formattedTime: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    /// Full phase sequence: [F, SB, F, SB, …, F, LB]
    /// For N=4 → [F,SB,F,SB,F,SB,F,LB]
    var phaseSequence: [TimerPhase] {
        var seq: [TimerPhase] = []
        for i in 0..<cyclesBeforeLongBreak {
            seq.append(.focus)
            seq.append(i < cyclesBeforeLongBreak - 1 ? .shortBreak : .longBreak)
        }
        return seq
    }

    // MARK: Actions

    func toggleRunning() { isRunning.toggle() }

    /// Reset only the current phase's timer.
    func reset() {
        isRunning = false
        timeRemaining = totalPhaseSeconds
    }

    /// Skip the rest of the current phase and move to the next.
    func skipToNext() { advancePhase() }

    /// Full reset — called when settings change or a new session starts.
    func resetAll() {
        isRunning             = false
        allCyclesComplete     = false
        phaseSequenceIndex    = 0
        currentCycle          = 1
        currentPhase          = .focus
        focusSecondsElapsed   = 0
        loadPhaseDuration()
    }

    /// Apply new settings and restart.
    func applySettings(focus: Int, short: Int, long: Int, cycles: Int) {
        focusDuration           = focus
        shortBreakDuration      = short
        longBreakDuration       = long
        cyclesBeforeLongBreak   = cycles
        resetAll()
    }

    /// Called every second by the view's Timer.
    func tick() {
        guard isRunning, !allCyclesComplete else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
            if currentPhase == .focus { focusSecondsElapsed += 1 }
        } else {
            advancePhase()
        }
    }

    // MARK: Private

    private func advancePhase() {
        isRunning = false
        phaseSequenceIndex += 1

        let seq = phaseSequence
        if phaseSequenceIndex >= seq.count {
            allCyclesComplete = true
            return
        }

        currentPhase = seq[phaseSequenceIndex]

        // Recalculate cycle counter when entering a new focus block
        if currentPhase == .focus {
            currentCycle = seq[0...phaseSequenceIndex].filter { $0 == .focus }.count
        }

        loadPhaseDuration()
        isRunning = true  // auto-start next phase
    }

    private func loadPhaseDuration() {
        switch currentPhase {
        case .focus:      totalPhaseSeconds = focusDuration      * 60
        case .shortBreak: totalPhaseSeconds = shortBreakDuration * 60
        case .longBreak:  totalPhaseSeconds = longBreakDuration  * 60
        }
        timeRemaining = totalPhaseSeconds
    }
}

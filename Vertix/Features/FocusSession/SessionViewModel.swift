//
//  SessionViewModel.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//
import Foundation
import Combine
struct PostureData {
    var shoulderAngle: Double = 2.0
    var shoulderOffset: Double = 8.0
    var neckScore: Double = 88.0
    var upperScore: Double = 92.0
    var lowerScore: Double = 61.0
}
class SessionViewModel: ObservableObject {
    
    // Timer State
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var completedCycles: Int = 0
    @Published var currentPhase: SessionPhase = .focus
    
    // User Settings
    @Published var focusDuration: Int = 25 // minutes
    @Published var shortBreakDuration: Int = 5 // minutes
    @Published var longBreakDuration: Int = 15 // minutes
    @Published var cyclesBeforeLongBreak: Int = 4
    
    // Posture Placeholder
    @Published var postureData = PostureData()
    
    private var timer: AnyCancellable?
    
    // Total duration for the current phase
    var totalDuration: Int {
        switch currentPhase {
        case .focus:       return focusDuration * 60
        case .shortBreak:  return shortBreakDuration * 60
        case .longBreak:   return longBreakDuration * 60
        }
    }
    
    var timerProgress: Double {
        1.0 - Double(timeRemaining) / Double(totalDuration)
    }
    
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Label shown above the timer
    var phaseLabel: String {
        switch currentPhase {
        case .focus:      return "FOCUS"
        case .shortBreak: return "SHORT BREAK"
        case .longBreak:  return "LONG BREAK"
        }
    }
    
    // Color changes based on phase
    var phaseColor: String {
        switch currentPhase {
        case .focus:      return "2D5A3D"
        case .shortBreak: return "3A7CA5"
        case .longBreak:  return "7B4EA6"
        }
    }
    
    init() {
        self.timeRemaining = 25 * 60
    }
    
    // Timer Controls
    func toggleTimer() {
        isRunning ? pauseTimer() : startTimer()
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.cycleCompleted()
                }
            }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.cancel()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = totalDuration
    }
    
    func skipCycle() {
        cycleCompleted()
    }
    
    func endSession() {
        pauseTimer()
        // TO DO: Save completed session to Firebase here
    }
    
    // Apply new settings and reset the timer to reflect changes
    func applySettings(focus: Int, shortBreak: Int, longBreak: Int, cycles: Int) {
        pauseTimer()
        focusDuration = focus
        shortBreakDuration = shortBreak
        longBreakDuration = longBreak
        cyclesBeforeLongBreak = cycles
        // Reset timer so it reflects the new duration immediately
        timeRemaining = totalDuration
    }
    
    // Cycle Logic
    private func cycleCompleted() {
        pauseTimer()
        completedCycles += 1
        
        if completedCycles % cyclesBeforeLongBreak == 0 {
            // Time for a long break
            currentPhase = .longBreak
        } else if currentPhase == .focus {
            currentPhase = .shortBreak
        } else {
            // Break is done, back to focus
            currentPhase = .focus
        }
        
        timeRemaining = totalDuration
    }
}
// MARK: - Session Phase
enum SessionPhase {
    case focus
    case shortBreak
    case longBreak
}


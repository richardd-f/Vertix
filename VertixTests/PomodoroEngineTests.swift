//
//  PomodoroEngineTests.swift
//  VertixTests
//

import Foundation
import Testing
@testable import Vertix

@Suite("PomodoroEngine")
struct PomodoroEngineTests {

    // MARK: - Initial state

    @Test("default phase is focus")
    func initial_phaseIsFocus() {
        let engine = PomodoroEngine()
        #expect(engine.currentPhase == .focus)
    }

    @Test("default timeRemaining matches focusDuration in seconds")
    func initial_timeRemainingMatchesFocusDuration() {
        let engine = PomodoroEngine()
        #expect(engine.timeRemaining == engine.focusDuration * 60)
    }

    @Test("engine starts paused")
    func initial_isNotRunning() {
        let engine = PomodoroEngine()
        #expect(engine.isRunning == false)
    }

    @Test("focusSecondsElapsed starts at zero")
    func initial_focusSecondsElapsedIsZero() {
        let engine = PomodoroEngine()
        #expect(engine.focusSecondsElapsed == 0)
    }

    @Test("allCyclesComplete starts false")
    func initial_allCyclesCompleteIsFalse() {
        let engine = PomodoroEngine()
        #expect(engine.allCyclesComplete == false)
    }

    // MARK: - phaseSequence

    @Test("phaseSequence length is 2 * cyclesBeforeLongBreak")
    func phaseSequence_correctLength() {
        let engine = PomodoroEngine()
        engine.cyclesBeforeLongBreak = 4
        #expect(engine.phaseSequence.count == 8)
    }

    @Test("phaseSequence alternates focus and short break, ending with long break")
    func phaseSequence_correctPattern() {
        let engine = PomodoroEngine()
        engine.cyclesBeforeLongBreak = 3
        let seq = engine.phaseSequence
        // [F, SB, F, SB, F, LB]
        #expect(seq == [.focus, .shortBreak, .focus, .shortBreak, .focus, .longBreak])
    }

    @Test("phaseSequence last element is always longBreak")
    func phaseSequence_endsWithLongBreak() {
        let engine = PomodoroEngine()
        for cycles in 2...8 {
            engine.cyclesBeforeLongBreak = cycles
            #expect(engine.phaseSequence.last == .longBreak)
        }
    }

    @Test("phaseSequence with 1 cycle is [focus, longBreak]")
    func phaseSequence_singleCycle() {
        let engine = PomodoroEngine()
        engine.cyclesBeforeLongBreak = 1
        #expect(engine.phaseSequence == [.focus, .longBreak])
    }

    // MARK: - toggleRunning

    @Test("toggleRunning starts a paused engine")
    func toggle_startsEngine() {
        let engine = PomodoroEngine()
        #expect(engine.isRunning == false)
        engine.toggleRunning()
        #expect(engine.isRunning == true)
    }

    @Test("toggleRunning pauses a running engine")
    func toggle_pausesEngine() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        engine.toggleRunning()
        #expect(engine.isRunning == false)
    }

    // MARK: - tick

    @Test("tick decrements timeRemaining by 1 when running")
    func tick_decrementsTime() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        let before = engine.timeRemaining
        engine.tick()
        #expect(engine.timeRemaining == before - 1)
    }

    @Test("tick does not decrement when paused")
    func tick_doesNothingWhenPaused() {
        let engine = PomodoroEngine()
        // isRunning is false by default
        let before = engine.timeRemaining
        engine.tick()
        #expect(engine.timeRemaining == before)
    }

    @Test("tick increments focusSecondsElapsed only during focus phase")
    func tick_incrementsFocusSecondsElapsedOnlyInFocusPhase() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        engine.tick()
        #expect(engine.focusSecondsElapsed == 1)
    }

    @Test("tick does not increment focusSecondsElapsed during short break")
    func tick_doesNotIncrementFocusElapsedDuringBreak() {
        let engine = PomodoroEngine()
        // Force into shortBreak phase
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        // Exhaust the 1-minute focus phase:
        // tick() decrements when >0, then advances phase when timeRemaining hits 0.
        // 60 ticks bring timeRemaining to 0; the 61st tick fires advancePhase().
        for _ in 0..<61 { engine.tick() }
        // Now in shortBreak
        #expect(engine.currentPhase == .shortBreak)
        let elapsedBeforeBreakTick = engine.focusSecondsElapsed
        engine.tick()
        #expect(engine.focusSecondsElapsed == elapsedBeforeBreakTick)
    }

    @Test("tick advances phase when timeRemaining hits zero")
    func tick_advancesPhaseAtZero() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        // 60 ticks bring timeRemaining to 0; the 61st tick fires advancePhase()
        for _ in 0..<61 { engine.tick() }
        #expect(engine.currentPhase == .shortBreak)
    }

    @Test("tick sets allCyclesComplete after all phases finish")
    func tick_setsAllCyclesCompleteWhenDone() {
        let engine = PomodoroEngine()
        // 1 cycle = [focus(1m), longBreak(1m)] → 120 ticks total
        engine.applySettings(focus: 1, short: 1, long: 1, cycles: 1)
        engine.toggleRunning()
        // Run through all phases
        for _ in 0..<200 { engine.tick() }
        #expect(engine.allCyclesComplete == true)
    }

    // MARK: - reset

    @Test("reset restores timeRemaining to totalPhaseSeconds")
    func reset_restoresTime() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        engine.tick(); engine.tick(); engine.tick()
        engine.reset()
        #expect(engine.timeRemaining == engine.totalPhaseSeconds)
    }

    @Test("reset stops the timer")
    func reset_stopsTimer() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        engine.reset()
        #expect(engine.isRunning == false)
    }

    @Test("reset does not change the current phase")
    func reset_keepsCurrentPhase() {
        let engine = PomodoroEngine()
        let phase = engine.currentPhase
        engine.toggleRunning()
        engine.tick()
        engine.reset()
        #expect(engine.currentPhase == phase)
    }

    // MARK: - resetAll

    @Test("resetAll returns to focus phase")
    func resetAll_returnToFocus() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        for _ in 0..<61 { engine.tick() }  // advance to shortBreak
        engine.resetAll()
        #expect(engine.currentPhase == .focus)
    }

    @Test("resetAll resets focusSecondsElapsed to zero")
    func resetAll_clearsFocusElapsed() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        engine.tick(); engine.tick()
        engine.resetAll()
        #expect(engine.focusSecondsElapsed == 0)
    }

    @Test("resetAll clears allCyclesComplete")
    func resetAll_clearsAllCyclesComplete() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 1, long: 1, cycles: 1)
        engine.toggleRunning()
        for _ in 0..<200 { engine.tick() }
        #expect(engine.allCyclesComplete == true)
        engine.resetAll()
        #expect(engine.allCyclesComplete == false)
    }

    @Test("resetAll resets phaseSequenceIndex to 0")
    func resetAll_resetsSequenceIndex() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        for _ in 0..<61 { engine.tick() }
        engine.resetAll()
        #expect(engine.phaseSequenceIndex == 0)
    }

    // MARK: - skipToNext

    @Test("skipToNext advances to the next phase")
    func skip_advancesToNextPhase() {
        let engine = PomodoroEngine()
        #expect(engine.currentPhase == .focus)
        engine.skipToNext()
        #expect(engine.currentPhase == .shortBreak)
    }

    @Test("skipToNext reloads timeRemaining for the new phase")
    func skip_reloadsTimeForNewPhase() {
        let engine = PomodoroEngine()
        engine.skipToNext()  // focus → shortBreak
        #expect(engine.timeRemaining == engine.shortBreakDuration * 60)
    }

    @Test("skipToNext on the last phase sets allCyclesComplete")
    func skip_setsAllCyclesCompleteOnLastPhase() {
        let engine = PomodoroEngine()
        engine.cyclesBeforeLongBreak = 1  // sequence: [focus, longBreak]
        engine.skipToNext()  // focus → longBreak
        engine.skipToNext()  // longBreak → done
        #expect(engine.allCyclesComplete == true)
    }

    // MARK: - applySettings

    @Test("applySettings updates all duration properties")
    func applySettings_updatesDurations() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 30, short: 7, long: 20, cycles: 3)
        #expect(engine.focusDuration         == 30)
        #expect(engine.shortBreakDuration    == 7)
        #expect(engine.longBreakDuration     == 20)
        #expect(engine.cyclesBeforeLongBreak == 3)
    }

    @Test("applySettings resets the engine to focus phase")
    func applySettings_resetsToFocus() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        for _ in 0..<61 { engine.tick() }  // advance to shortBreak
        engine.applySettings(focus: 25, short: 5, long: 15, cycles: 4)
        #expect(engine.currentPhase == .focus)
        #expect(engine.isRunning == false)
    }

    @Test("applySettings sets timeRemaining to new focusDuration")
    func applySettings_updatesTimeRemaining() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 45, short: 5, long: 15, cycles: 4)
        #expect(engine.timeRemaining == 45 * 60)
    }

    // MARK: - progress

    @Test("progress is 0.0 at the start of a phase")
    func progress_isZeroAtStart() {
        let engine = PomodoroEngine()
        #expect(engine.progress == 0.0)
    }

    @Test("progress is between 0 and 1 after some ticks")
    func progress_isInRangeAfterTicks() {
        let engine = PomodoroEngine()
        engine.toggleRunning()
        for _ in 0..<10 { engine.tick() }
        #expect(engine.progress > 0.0)
        #expect(engine.progress < 1.0)
    }

    // MARK: - formattedTime

    @Test("formattedTime shows MM:SS with zero padding")
    func formattedTime_zeroPads() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 25, short: 5, long: 15, cycles: 4)
        // 25:00
        #expect(engine.formattedTime == "25:00")
    }

    @Test("formattedTime updates after ticks")
    func formattedTime_updatesAfterTicks() {
        let engine = PomodoroEngine()
        engine.applySettings(focus: 1, short: 5, long: 15, cycles: 4)
        engine.toggleRunning()
        engine.tick()  // 59 seconds left
        #expect(engine.formattedTime == "00:59")
    }

    // MARK: - sessionLabel

    @Test("sessionLabel shows correct cycle fraction")
    func sessionLabel_showsCorrectFraction() {
        let engine = PomodoroEngine()
        engine.cyclesBeforeLongBreak = 4
        #expect(engine.sessionLabel == "Session 1 of 4")
    }
}

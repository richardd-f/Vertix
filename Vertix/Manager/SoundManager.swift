//
//  SoundManager.swift
//  Vertix
//
//  Created by Clarice Harijanto on 28/05/26.
//

// This file is for: Cross-platform sound + haptics (iOS/macOS)

import Foundation
import AVFoundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

// MARK: - SoundManager

/// Plays notification sounds and manages audio session.
/// Works on iOS, iPadOS, and macOS (Catalyst / native).
final class SoundManager {

    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    enum SoundEvent {
        case sessionStart
        case sessionEnd
        case badPostureAlert
        case pomodoroBreak
        case levelUp
        case challengeComplete
        case timerTick   // soft tick each minute during focus
    }

    private init() {
        configureAudioSession()
    }

    // MARK: - Public API

    func play(_ event: SoundEvent) {
        let (fileName, volume) = assetFor(event)
        playSound(named: fileName, volume: volume)
        triggerHaptic(for: event)
    }

    // MARK: - Private

    private func assetFor(_ event: SoundEvent) -> (name: String, volume: Float) {
        // Map to system sounds that ship with iOS/macOS so we have
        // zero external asset dependencies.  Callers can replace these
        // strings with custom .caf / .wav files placed in the bundle.
        switch event {
        case .sessionStart:       return ("Tink",           0.8)
        case .sessionEnd:         return ("Hero",           1.0)
        case .badPostureAlert:    return ("Morse",          0.7)
        case .pomodoroBreak:      return ("Blow",           0.9)
        case .levelUp:            return ("Fanfare",        1.0)
        case .challengeComplete:  return ("Ping",           0.9)
        case .timerTick:          return ("Tock",           0.3)
        }
    }

    private func playSound(named name: String, volume: Float) {
        // 1. Try to find a bundled audio asset first (custom sounds)
        if let url = Bundle.main.url(forResource: name, withExtension: "caf")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3") {
            playURL(url, volume: volume)
            return
        }

        // 2. Fall back to macOS / iOS system sounds via NSSound / AudioServicesPlaySystemSound
        #if os(macOS)
        NSSound(named: NSSound.Name(name))?.play()
        #else
        // iOS: use AudioToolbox for system sounds
        playIOSSystemSound(name: name, volume: volume)
        #endif
    }

    private func playURL(_ url: URL, volume: Float) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            print("SoundManager: failed to play \(url.lastPathComponent) — \(error)")
        }
    }

    private func playIOSSystemSound(name: String, volume: Float) {
        #if !os(macOS)
        // Map named sounds to UIKit system feedback as fallback
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        switch name {
        case "Hero", "Fanfare", "Ping":
            generator.notificationOccurred(.success)
        case "Morse", "Blow":
            generator.notificationOccurred(.warning)
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        #endif
    }

    private func triggerHaptic(for event: SoundEvent) {
        #if !os(macOS)
        switch event {
        case .sessionEnd, .levelUp, .challengeComplete:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .badPostureAlert:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .pomodoroBreak:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .sessionStart:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .timerTick:
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }

    private func configureAudioSession() {
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        do {
            // Mix with other audio so music keeps playing
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("SoundManager: audio session config failed — \(error)")
        }
        #endif
    }
}

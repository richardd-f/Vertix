# AGENTS.md — Vertix

This file is the source of truth for any AI agent or developer working on the Vertix codebase. Read it fully before touching any code, file, or configuration.

---

## What Is Vertix

Vertix is a health and productivity iOS/iPadOS/watchOS application that combines **real-time AI-powered posture detection** with **Pomodoro-based focus sessions**. The core loop: user starts a session → camera tracks posture every minute → haptic alert fires on Apple Watch if posture is bad → after session ends, a score is calculated and saved to Firebase.

The goal is long-term habit formation, not just one-time correction.

---

## Platforms

| Platform | Role | Notes |
|----------|------|-------|
| iPhone | Primary | Full feature set — posture tracking, Pomodoro, history, profile |
| iPad | Primary | Identical feature set to iPhone, adaptive layout |
| Apple Watch | Companion | Timer display, session controls, haptic posture alerts |

iPhone and iPad share the same codebase and feature set. The Watch is a companion — it receives data from the iPhone via WatchConnectivity and cannot track posture independently.

---

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI Framework | SwiftUI | Pure SwiftUI app lifecycle, no UIKit bridges unless absolutely necessary |
| State Management | `@Observable` (Swift 5.9+) | No `ObservableObject`, no `@StateObject`. Use `@Observable` macros only |
| Architecture | Feature-Based MVVM | Code grouped by feature domain, not by type |
| Backend | Firebase Realtime Database | Not Firestore. Realtime DB only |
| Auth | Firebase Authentication | Email/password auth |
| AI / Posture | MediaPipe `pose_landmarker_lite` | On-device, ~5.5MB, 33 body landmarks, live stream mode |
| Charts | Swift Charts | Native Apple framework, no third-party charting libs |
| Watch Comms | WatchConnectivity (`WCSession`) | iPhone → Watch only for posture alerts and session state |
| Dependency Manager | CocoaPods | Both Firebase and MediaPipe are managed via Podfile. Do NOT add SPM packages — mixing managers will break the workspace |

---

## Project Structure

```
Vertix/
├── Vertix.xcworkspace          ← ALWAYS open this, never .xcodeproj
├── Podfile                     ← CocoaPods: Firebase + MediaPipe
├── Podfile.lock
├── Pods/
└── Vertix/
    ├── VertixApp.swift         ← App entry point
    ├── ContentView.swift       ← Root router: Onboarding / Auth / Main
    ├── Assets.xcassets
    ├── GoogleService-Info.plist ← Firebase config, NOT committed to git
    │
    ├── Components/             ← Reusable UI components shared across features
    │   └── VertixInputField.swift
    │
    ├── Core/                   ← App-wide utilities, extensions, constants
    │
    ├── Features/               ← Feature-Based MVVM — one folder per domain
    │   ├── Onboarding/
    │   │   └── OnboardingView.swift
    │   ├── Auth/
    │   │   ├── View/
    │   │   ├── ViewModel/
    │   │   └── Model/
    │   ├── Home/               ← Dashboard: posture gauge, session control
    │   │   ├── View/
    │   │   ├── ViewModel/
    │   │   └── Model/
    │   ├── Session/            ← Active Pomodoro + posture tracking session
    │   │   ├── View/
    │   │   ├── ViewModel/
    │   │   └── Model/
    │   ├── History/            ← Calendar + weekly chart + session log
    │   │   ├── View/
    │   │   ├── ViewModel/
    │   │   └── Model/
    │   └── Profile/            ← Account info, settings, logout
    │       ├── View/
    │       ├── ViewModel/
    │       └── Model/
    │
    ├── Manager/                ← Singleton service managers
    │   ├── AuthManager.swift
    │   ├── SessionManager.swift
    │   ├── PostureManager.swift
    │   └── WatchConnectivityManager.swift
    │
    └── Models/                 ← Shared data models
        ├── UserModel.swift
        ├── SessionModel.swift
        └── DailyScoreModel.swift
```

---

## Architecture Rules

### Feature-Based MVVM
Every feature lives in its own folder under `Features/`. Each feature folder contains:
- `View/` — SwiftUI views, no business logic
- `ViewModel/` — `@Observable` class, owns state and logic
- `Model/` — data structures specific to this feature

**Never put business logic in a View. Never put UI logic in a Model.**

### State Management
Use `@Observable` macro exclusively:
```swift
// ✅ Correct
@Observable
class HomeViewModel {
    var postureScore: Double = 0
}

// ❌ Wrong — do not use
class HomeViewModel: ObservableObject {
    @Published var postureScore: Double = 0
}
```

### Root Navigation
`ContentView` is the single root router. It manages three states:
1. **Onboarding** — shown once on first launch via `@AppStorage("hasSeenOnboarding")`
2. **Auth** — shown when no Firebase user session exists
3. **Main App** — `TabView` with Home, History, Profile tabs

Do not add navigation logic outside of `ContentView` unless it is strictly local to a feature.

---

## Design System

### Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#F4F2EE` | Primary background, warm cream |
| Primary | `#2D4F44` | Forest green — buttons, active states, accents |
| Secondary | Sage green variants | Secondary actions, inactive states |

### UI Style
- **Neo-morphic aesthetic** — soft shadows, rounded cards, floating surfaces
- **Components**: pill-shaped badges, floating cards with subtle drop shadows
- **Input fields**: use `VertixInputField` component, never raw `TextField`
- **Typography**: system font, no custom fonts
- **Charts**: Swift Charts only — no third-party charting libraries

### Minimum iOS Target
`iOS 18.6` / `watchOS` compatible version. Do not use APIs below this target.

---

## Firebase Structure

### Overview
Three collections in Firebase Realtime Database. All writes use `updateChildValues` for atomic multi-path updates.

```
vertix/
├── users/{uid}
├── sessions/{uid}/{pushId}
└── dailyScores/{uid}/{YYYY-MM-DD}
```

### `users/{uid}`
Stores user profile and lifetime stats. Updated after every session ends.

| Field | Type | Description |
|-------|------|-------------|
| `displayName` | String | Full name |
| `email` | String | Account email |
| `avatarUrl` | String? | Profile photo URL, nullable |
| `createdAt` | Timestamp | Account creation time |
| `totalTrackedSeconds` | Number | Lifetime total tracking seconds |
| `currentStreak` | Number | Current consecutive active days |
| `longestStreak` | Number | All-time longest streak |
| `lastActiveDate` | String | Format `YYYY-MM-DD`, used for streak calculation |

### `sessions/{uid}/{pushId}`
One node per completed focus session. Key is auto-generated via `.push()`.

| Field | Type | Description |
|-------|------|-------------|
| `startedAt` | Timestamp | Session start time |
| `endedAt` | Timestamp | Session end time |
| `durationSeconds` | Number | Total focus duration in seconds |
| `dateKey` | String | `YYYY-MM-DD` for calendar and streak queries |
| `goodCount` | Number | Minutes classified as good posture |
| `badCount` | Number | Minutes classified as bad posture |
| `postureScore` | Number | `goodCount * 100 / (goodCount + badCount)`, range 1–100 |
| `pomodoroCount` | Number | Completed focus cycles |
| `focusDuration` | Number | Focus duration per cycle in minutes |
| `shortBreakDuration` | Number | Short break duration in minutes |
| `longBreakDuration` | Number | Long break duration in minutes |
| `totalCycles` | Number | Planned cycles before long break |

### `dailyScores/{uid}/{YYYY-MM-DD}`
Aggregated daily data. Updated atomically when any session on that day ends.

| Field | Type | Description |
|-------|------|-------------|
| `averageScore` | Number | Average `postureScore` across all sessions that day |
| `totalSessions` | Number | Number of completed sessions |
| `totalSeconds` | Number | Total focus seconds that day |
| `totalGoodCount` | Number | Accumulated good minutes across all sessions |
| `totalBadCount` | Number | Accumulated bad minutes across all sessions |
| `isActive` | Boolean | `true` if ≥ 1 session exists — used by streak calendar |

### Atomic Write Pattern
Always update all affected nodes in a single `updateChildValues` call:
```swift
let updates: [String: Any] = [
    "sessions/\(uid)/\(sessionId)": sessionData,
    "dailyScores/\(uid)/\(dateKey)": dailyData,
    "users/\(uid)/totalTrackedSeconds": newTotal,
    "users/\(uid)/currentStreak": newStreak,
    "users/\(uid)/lastActiveDate": dateKey
]
Database.database().reference().updateChildValues(updates)
```

---

## Posture Scoring System

### How It Works
1. Posture tracking runs **only on iPhone/iPad** during an active focus session
2. Every **1 minute**, MediaPipe classifies posture as either `good` or `bad`
3. The classification comes directly from the AI library — there is no intermediate score per frame
4. When the session ends, the final score is calculated:

```
postureScore = goodCount * 100 / (goodCount + badCount)
```

Example:
```
08:37 = bad  → badCount: 1
08:38 = good → goodCount: 1
08:39 = good → goodCount: 2
08:40 = good → goodCount: 3
...
08:48 = good → goodCount: 9, badCount: 3

postureScore = 9 * 100 / (9 + 3) = 75
```

### MediaPipe Configuration
- Model: `pose_landmarker_lite` (~5.5MB)
- Mode: live stream via front camera
- Detects: 33 body landmarks
- Running mode: parallel with Pomodoro timer, not blocking UI

### Apple Watch Alerts
- iPhone detects bad posture → sends message via `WCSession`
- Watch receives message → fires `WKInterfaceDevice.current().play(.notification)`
- Watch also shows local push notification with specific message e.g. `"Fix: head tilting forward"`

---

## Pomodoro Timer

### Default Configuration
| Phase | Default | Range |
|-------|---------|-------|
| Focus | 25 min | 5–60 min |
| Short Break | 5 min | 1–15 min |
| Long Break | 15 min | 5–30 min |
| Cycles before Long Break | 4 | 2–8 |

### Timer Phases
Colors change per phase — this is enforced in the UI:
- Focus → Green (`#2D4F44`)
- Short Break → Blue
- Long Break → Purple

### Posture tracking is active only during Focus phases.
Do not run posture detection during Short Break or Long Break.

---

## Apple Watch

### What Watch Can Do
- Display active Pomodoro timer
- Start, Pause, Stop session
- Receive and display haptic posture alerts

### What Watch Cannot Do
- Track posture (no camera access)
- Work independently without paired iPhone
- Store session data directly to Firebase

### WatchConnectivity Messages
Messages are sent from iPhone to Watch. Format:
```swift
// Posture alert
["type": "postureAlert", "message": "Fix: head tilting forward"]

// Session state sync
["type": "sessionState", "phase": "focus", "remainingSeconds": 900]
```

---

## Git Conventions

### Branch Naming
```
feature/feature-name
fix/bug-description
chore/task-description
refactor/description
```

### Commit Convention (Conventional Commits)
```
feat: add posture score gauge to dashboard
fix: resolve streak not updating after midnight
chore: migrate Firebase dependency from SPM to CocoaPods
refactor: extract session timer into SessionManager
```

### Important Branches
| Branch | Purpose |
|--------|---------|
| `main` | Stable — Firebase Auth + CocoaPods setup |
| `Vision-AI-Feature` | MediaPipe posture detection (being merged into main) |

---

## CocoaPods — Critical Rules

**Always open `Vertix.xcworkspace`, never `Vertix.xcodeproj`.**

After any `pod install` or branch switch:
```bash
pod install
open Vertix.xcworkspace
```

Do not add new dependencies via SPM. All new packages must go through CocoaPods and be added to the `Podfile`.

Current `Podfile` targets:
```ruby
platform :ios, '16.0'
use_frameworks!

target 'Vertix' do
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'MediaPipeTasksVision'
end
```

---

## Environment Setup

### Prerequisites
- Xcode 15+
- CocoaPods installed
- Ruby 3.3+ (via rbenv recommended)
- Firebase project with Auth and Realtime Database enabled

### First-Time Setup
```bash
git clone https://github.com/your-username/Vertix.git
cd Vertix
pod install
# Add GoogleService-Info.plist to Vertix/ folder (not committed to git)
open Vertix.xcworkspace
```

### After Pulling Changes
```bash
git pull
pod install
open Vertix.xcworkspace
```

---

## What Is Currently Implemented

| Feature | Status | Branch |
|---------|--------|--------|
| Onboarding (3-step carousel) | ✅ Done | main |
| Firebase Auth (login/register) | ✅ Done | main |
| Root router (ContentView) | ✅ Done | main |
| Dashboard UI | ✅ Done | main |
| CocoaPods migration | ✅ Done | main |
| MediaPipe posture detection | ✅ Done | Vision-AI-Feature |
| Session Pomodoro timer | ✅ Done | Vision-AI-Feature |
| Firebase session save | 🔄 In Progress | — |
| History tab (calendar + chart) | 🔄 In Progress | — |
| Profile tab | 🔄 In Progress | — |
| Apple Watch app | ⏳ Planned | — |
| Streak calculation | ⏳ Planned | — |

---

## Known Issues & Decisions

| Item | Decision |
|------|----------|
| SPM vs CocoaPods | Migrated fully to CocoaPods because MediaPipe is not available on SPM |
| Posture score granularity | Classification-based (good/bad per minute), not a continuous per-frame score |
| Watch posture tracking | Not possible — Watch has no front camera. Alerts only. |
| `GoogleService-Info.plist` | Not committed to git. Each developer must download from Firebase Console |
| `User Script Sandboxing` | Set to `No` in Build Settings for both PROJECT and TARGET — required by CocoaPods |

---

## Agent Workflow Rules

1. **Never modify `Podfile` without flagging it** — any change requires `pod install` which regenerates the workspace
2. **Never add SPM packages** — CocoaPods only
3. **Always follow Feature-Based MVVM** — new features go under `Features/`, new components go under `Components/`
4. **Never put logic in Views** — ViewModels own all state and business logic
5. **Use `@Observable` only** — never `ObservableObject` or `@Published`
6. **Atomic Firebase writes** — always use `updateChildValues` when writing to multiple paths
7. **Posture tracking = Focus phase only** — never run MediaPipe during break phases
8. **`YYYY-MM-DD` for all date keys** — consistent format across sessions and dailyScores
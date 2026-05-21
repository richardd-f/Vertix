<div align="center">

<img src="https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS%20%7C%20watchOS-2D4F44?style=for-the-badge&logo=apple&logoColor=white" />
<img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-CocoaPods-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Status-In%20Development-2D4F44?style=for-the-badge" />

<br/><br/>

# 🌿 Vertix

### *Posture. Focus. Habit.*

**Vertix** is a modern health and productivity ecosystem that helps users maintain good body posture while working or studying. It combines AI-driven real-time posture tracking via the device's camera with proven focus techniques like the Pomodoro method — all designed to build long-lasting healthy habits.

<br/>

</div>

---

## 📱 Platforms

| Platform | Support | Description |
|----------|---------|-------------|
| **iPhone** | ✅ Full | Complete posture tracking + focus sessions |
| **iPad** | ✅ Full | Same feature set as iPhone, optimized layout |
| **Apple Watch** | ✅ Companion | Timer display, session controls, haptic alerts |

---

## ✨ Features

### 📲 iPhone & iPad

#### Onboarding & Identity
- **Carousel Onboarding** — A 3-step visual introduction shown only on first launch, introducing posture tracking, focus sessions, and habit insights. Persisted via `@AppStorage`.
- **Authentication** — Secure login and registration powered by Firebase Auth, with a root router managing transitions between onboarding, auth, and the main app.

#### Dashboard
- **Posture Score Gauge** — A large animated circular gauge showing the current average daily posture score at a glance.
- **Session Control** — A start/stop toggle that simultaneously activates the camera AI pipeline and Pomodoro timer.
- **Personalized Greeting** — Context-aware greeting using the user's name and time of day.
- **Recent Sessions** — A quick-glance summary of recent tracking sessions with duration, score, and timestamp.

#### Insights & History
- **Monthly Overview Calendar** — A color-coded calendar mapping daily posture performance and highlighting streaks and missed days.
- **Weekly Posture Trend Chart** — A native Swift Charts line graph visualizing posture score trends across the past 7 days.
- **Streak Tracking** — Consecutive active day streaks tracked to reinforce daily habit formation.

#### Profile
- **Account Info** — User identity details synced from Firebase, with total tracked hours as a key lifetime metric.
- **Settings Navigation** — Notification toggles, session duration defaults, and camera permission management.
- **Secure Logout** — One-tap sign out via Firebase Auth that cleanly clears the session state.

#### Core Engine
- **AI Posture Detection** — Real-time body shape analysis via the device's front camera, continuously scoring posture quality during active sessions.
- **Pomodoro Timer** — Built-in focus interval timer running in parallel with posture tracking to structure productive work blocks.

---

### ⌚ Apple Watch

| Feature | Description |
|---------|-------------|
| **Timer Display** | Shows the active Pomodoro session timer directly on the Watch face |
| **Session Controls** | Dedicated Start, Pause, and Stop action buttons on the Watch UI |
| **Haptic Posture Alerts** | Discreet haptic vibration when the AI detects poor posture on the paired iPhone |

---

## 🛠 Tech Stack

### Core
| Technology | Usage |
|------------|-------|
| **SwiftUI** | UI Framework — modern declarative UI with pure SwiftUI app lifecycle |
| **Swift 5.9+** | Language — utilizing `@Observable` macros for reactive state management |
| **Feature-Based MVVM** | Architecture — code grouped by domain (Auth, Home, History, etc.) |

### Backend & Data
| Technology | Usage |
|------------|-------|
| **Firebase Authentication** | Secure user login, registration, and session management |
| **Firebase Realtime Database** | Stores user profiles, daily scores, and historical session data |

### UI & Visualization
| Technology | Usage |
|------------|-------|
| **Swift Charts** | Native Apple charting framework for weekly posture trend graphs |
| **Custom Components** | Animated circular progress indicators, neo-morphic cards, pill badges |

### AI & Camera
| Technology | Usage |
|------------|-------|
| **Camera AI Framework** | Real-time body shape and posture detection (TBD — not CreateML) |

### Dependency Management
| Tool | Usage |
|------|-------|
| **CocoaPods** | Manages Firebase and AI framework dependencies |

---

## 🎨 Design System

Vertix uses a premium **neo-morphic aesthetic** with a warm, natural color palette.

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#F4F2EE` | Warm cream — primary background |
| `primary` | `#2D4F44` | Deep forest green — primary actions & accents |
| `secondary` | Sage green variants | Secondary elements & states |

**Components:** Custom pill-shaped badges, floating cards with subtle drop shadows, and reusable styled text inputs (`VertixInputField`).

---

## 🗂 Project Structure

```
Vertix/
├── Vertix/
│   ├── App/
│   │   ├── VertixApp.swift          # App entry point
│   │   └── ContentView.swift        # Root router (Onboarding / Auth / Main)
│   ├── Features/
│   │   ├── Onboarding/              # 3-step carousel onboarding
│   │   ├── Auth/                    # Login & Registration
│   │   │   ├── View/
│   │   │   ├── ViewModel/
│   │   │   └── Model/
│   │   ├── Home/                    # Dashboard — score gauge, session control
│   │   ├── History/                 # Calendar + weekly chart
│   │   └── Profile/                 # Account info, settings, logout
│   ├── Components/                  # Reusable UI components
│   ├── Manager/                     # Service managers (Firebase, Camera, etc.)
│   ├── Models/                      # Shared data models
│   └── Assets.xcassets
├── VertixWatch/                     # watchOS target
│   ├── TimerView.swift
│   └── SessionControlView.swift
├── Podfile
├── Podfile.lock
└── Vertix.xcworkspace               # Always open this ⚠️
```

---

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 16.0+ / watchOS 9.0+
- CocoaPods installed
- A Firebase project with Auth and Realtime Database enabled

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/your-username/Vertix.git
cd Vertix
```

**2. Install dependencies**
```bash
pod install
```

**3. Add Firebase configuration**

Download `GoogleService-Info.plist` from your Firebase Console and place it in:
```
Vertix/GoogleService-Info.plist
```

**4. Open the workspace**
```bash
open Vertix.xcworkspace
```

> ⚠️ Always open `Vertix.xcworkspace`, never `Vertix.xcodeproj` directly.

**5. Build and run**

Select your target device and press `⌘ + R`.

---

## 🔄 App Flow

```
App Launch
    │
    ├── First Launch? ──► Onboarding (3-step carousel)
    │                           │
    │                           ▼
    └── Returning User ──► Auth Check
                                │
                    ┌───────────┴───────────┐
                    │                       │
               Not logged in          Logged in
                    │                       │
               Login / Register        Main App
                                           │
                          ┌────────────────┼────────────────┐
                          │                │                 │
                       Home Tab       History Tab       Profile Tab
                     (Dashboard)      (Insights)         (Account)
```

---

## 🤝 Contributing

This project follows **Feature-Based MVVM** — when adding a new feature, create a dedicated folder under `Features/` containing its own `View/`, `ViewModel/`, and `Model/` subdirectories.

### Branch Naming Convention
```
feature/feature-name
fix/bug-description
chore/task-description
```

### Commit Convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add posture score history export
fix: resolve login state not persisting on relaunch
chore: migrate Firebase dependency from SPM to CocoaPods
refactor: extract session timer into SessionManager
```

---

## 👥 Team

| Name | Role |
|------|------|
| Felix | iOS Developer — Auth, Dashboard, Firebase |
| *(teammate)* | iOS Developer — AI Posture Detection |

---

## 📄 License

This project is developed as part of an academic/personal project. All rights reserved.

---

<div align="center">

Made with 🌿 by the Vertix Team

</div>

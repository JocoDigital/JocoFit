# JocoFit - Native SwiftUI iOS App

## Overview
JocoFit is a native Swift/SwiftUI fitness app that replicates the bodyweight ladder workout features from the Joco88 Laravel application. The app supports iPhone, iPad, Apple TV, and Mac, with Supabase for backend authentication and data storage.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Backend | Supabase (PostgreSQL + Auth) |
| Auth | Sign in with Apple + Email/Password |
| Deployment | iOS 17.0+ |
| Repo | github.com/JocoDigital/JocoFit |

## Project Structure

```
JocoFit/
├── JocoFit.xcodeproj/     # Xcode project file
├── JocoFit/
│   ├── App/
│   │   ├── JocoFitApp.swift      # App entry point
│   │   └── ContentView.swift     # Root view with auth check
│   ├── Models/
│   │   ├── Exercise.swift        # Exercise with multipliers
│   │   ├── WorkoutMode.swift     # ProgressionMode, PresetWorkout enums
│   │   ├── WorkoutSession.swift  # SwiftData model for sessions
│   │   └── WorkoutTemplate.swift # Saved custom workouts
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift   # Auth state (Apple + email)
│   │   ├── WorkoutViewModel.swift # Workout progression logic
│   │   └── HistoryViewModel.swift # History & stats
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift   # Login with Apple/email
│   │   │   └── SignUpView.swift  # Email signup
│   │   ├── Home/
│   │   │   └── HomeView.swift    # Dashboard
│   │   ├── Workouts/
│   │   │   ├── WorkoutSelectionView.swift
│   │   │   ├── CustomWorkoutBuilderView.swift
│   │   │   ├── ActiveWorkoutView.swift
│   │   │   └── WorkoutSummaryView.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift
│   │   │   └── SessionDetailView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── Services/
│   │   └── SupabaseService.swift # Supabase client
│   ├── Utilities/
│   │   ├── Extensions.swift      # Date, Color, View extensions
│   │   └── Constants.swift       # App constants
│   ├── Resources/
│   │   └── Assets.xcassets/      # App icons, colors
│   └── Preview Content/
├── database/
│   └── schema.sql                # Supabase schema
└── README.md
```

## Core Workout Logic

### Exercise Multipliers
| Exercise | Multiplier | Full Ladder Total |
|----------|------------|-------------------|
| Pull-ups | ×1 | 100 reps |
| Dips | ×2 | 200 reps |
| Push-ups | ×3 | 300 reps |
| Sit-ups | ×4 | 400 reps |
| Air Squats | ×5 | 500 reps |

### Progression Modes
- **Full** (1→10→1): 19 rounds, 100× multiplier
- **Ascending** (1→10): 10 rounds, 55× multiplier
- **Descending** (10→1): 10 rounds, 55× multiplier

### Preset Workouts (12 total)
- Full Set: Full, Ascending, Descending
- No Pull-ups: Full, Ascending, Descending
- No Dips: Full, Ascending, Descending
- No Squats: Full, Ascending, Descending

## Supabase Configuration

- **Project URL**: https://jcobqznsqmmjpwirmhgf.supabase.co
- **Database Tables**: workout_sessions, exercises, workout_templates
- **Auth Providers**: Apple (native), Email/Password
- **RLS**: Enabled - users can only access their own data

## Development Commands

### Build & Run
```bash
# Build from command line
xcodebuild -scheme JocoFit -destination 'platform=iOS Simulator,name=iPhone 17' build

# Or use Xcode: Cmd+R to run
```

### Git
```bash
cd ~/Sites/JocoFit
git status
git add -A && git commit -m "message"
git push origin main
```

## Key Files to Know

| File | Purpose |
|------|---------|
| `WorkoutViewModel.swift` | Core workout progression logic |
| `WorkoutMode.swift` | PresetWorkout enum with all 12 variations |
| `ActiveWorkoutView.swift` | Main workout UI during exercise |
| `SupabaseService.swift` | All Supabase operations |
| `AuthViewModel.swift` | Sign in with Apple + email auth |

## Current Status

**Completed:**
- Project setup with Xcode
- Supabase integration
- Authentication (Apple + email)
- Basic UI structure (Home, Workouts, History, Settings tabs)
- Preset workout definitions

**In Progress:**
- Active workout flow
- Workout timer
- Session saving to Supabase

**TODO:**
- Custom workout builder
- History view with real data
- Personal best tracking
- Offline support with SwiftData

## Notes

- Sign in with Apple requires real device or simulator signed into Apple ID
- Screen wake lock: `UIApplication.shared.isIdleTimerDisabled = true` during workouts
- Cross-platform code uses `#if os(iOS)` guards for iOS-specific APIs

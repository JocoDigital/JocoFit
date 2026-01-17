# JocoFit

A native SwiftUI fitness app for all Apple platforms (iOS, iPadOS, tvOS, macOS). Track your bodyweight ladder workouts with real-time progress, personal bests, and cloud sync via Supabase.

## Features

- **Preset Ladder Workouts**: 12 pre-configured workout variations
  - Full Set (5 exercises): Full Ladder, Ascending, Descending
  - No Dips (4 exercises): Full Ladder, Ascending, Descending
  - No Squats (4 exercises): Full Ladder, Ascending, Descending
  - No Dips & No Squats (3 exercises): Full Ladder, Ascending, Descending

- **Custom Workout Builder**: Select any combination of exercises and progression mode

- **Real-Time Tracking**:
  - Live timer with screen wake lock
  - Current exercise with rep count
  - Next exercise preview
  - Progress percentage

- **History & Analytics**:
  - Complete workout history
  - Personal best tracking
  - Exercise-by-exercise breakdown
  - Filtering by workout type

## Tech Stack

- **Swift 5.9+** / **SwiftUI**
- **Supabase** (Auth + PostgreSQL)
- **SwiftData** (Local persistence)

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- tvOS 17.0+
- macOS 14.0+
- Xcode 15.0+

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/JocoDigital/JocoFit.git
cd JocoFit
```

### 2. Create Xcode Project

Since this repo contains Swift source files but not an Xcode project, you'll need to create one:

1. Open Xcode
2. File → New → Project
3. Select "Multiplatform" → "App"
4. Product Name: `JocoFit`
5. Team: Your Apple Developer Team
6. Organization Identifier: `com.jocodigital`
7. Select location: Choose the cloned `JocoFit` folder

### 3. Add Existing Files

1. Right-click on the JocoFit group in the Project Navigator
2. Select "Add Files to JocoFit..."
3. Navigate to the `JocoFit` folder containing the Swift files
4. Select all folders (App, Models, Views, ViewModels, Services, Components, Utilities)
5. Make sure "Copy items if needed" is unchecked
6. Click Add

### 4. Add Supabase Package

1. File → Add Package Dependencies
2. Enter: `https://github.com/supabase/supabase-swift`
3. Select version rule: "Up to Next Major Version" from `2.0.0`
4. Add to target: JocoFit

### 5. Configure Supabase

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create a new project or use existing
3. Run the database schema (see below)
4. Update `JocoFit/Services/SupabaseService.swift` with your credentials:

```swift
let supabaseURL = URL(string: "https://your-project.supabase.co")!
let supabaseKey = "your-anon-key"
```

### 6. Build & Run

1. Select your target device/simulator
2. Press `Cmd + R` to build and run

## Supabase Database Setup

Run the following SQL in your Supabase SQL Editor:

```sql
-- Workout Sessions Table
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  workout_mode TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  completed_rounds INTEGER DEFAULT 0,
  total_completed_reps INTEGER DEFAULT 0,
  total_workout_time_seconds INTEGER DEFAULT 0,
  progress_percentage DECIMAL(5,2) DEFAULT 0.00,
  exercise_reps JSONB DEFAULT '{}',
  exercise_timing JSONB DEFAULT '{}',
  workout_started_at TIMESTAMPTZ,
  workout_ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout Templates Table (for saved custom workouts)
CREATE TABLE workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  exercises TEXT[] NOT NULL,
  progression_mode TEXT NOT NULL,
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_workout_sessions_user_mode ON workout_sessions(user_id, workout_mode);
CREATE INDEX idx_workout_sessions_user_date ON workout_sessions(user_id, created_at DESC);
CREATE INDEX idx_workout_templates_user ON workout_templates(user_id);

-- Enable Row Level Security
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout_sessions
CREATE POLICY "Users can view own sessions" ON workout_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON workout_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON workout_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions" ON workout_sessions
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for workout_templates
CREATE POLICY "Users can view own templates" ON workout_templates
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own templates" ON workout_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates" ON workout_templates
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates" ON workout_templates
  FOR DELETE USING (auth.uid() = user_id);
```

## Project Structure

```
JocoFit/
├── App/
│   ├── JocoFitApp.swift        # App entry point
│   └── ContentView.swift        # Root view with auth check
├── Models/
│   ├── Exercise.swift           # Exercise data model
│   ├── WorkoutMode.swift        # Workout configuration types
│   ├── WorkoutSession.swift     # Session persistence model
│   └── WorkoutTemplate.swift    # Saved workout templates
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Workouts/
│   │   ├── WorkoutSelectionView.swift
│   │   ├── CustomWorkoutBuilderView.swift
│   │   ├── ActiveWorkoutView.swift
│   │   └── WorkoutSummaryView.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   └── SessionDetailView.swift
│   └── Settings/
│       └── SettingsView.swift
├── ViewModels/
│   ├── WorkoutViewModel.swift   # Core workout logic
│   ├── AuthViewModel.swift      # Authentication state
│   └── HistoryViewModel.swift   # History management
├── Services/
│   └── SupabaseService.swift    # Backend operations
└── Utilities/
    ├── Extensions.swift
    └── Constants.swift
```

## Workout Modes

### Progression Types

| Mode | Rounds | Formula |
|------|--------|---------|
| Full Ladder | 1→10→1 (19 rounds) | 100× multiplier |
| Ascending | 1→10 (10 rounds) | 55× multiplier |
| Descending | 10→1 (10 rounds) | 55× multiplier |

### Exercise Multipliers

| Exercise | Multiplier | Full Ladder Reps |
|----------|------------|------------------|
| Pull-ups | ×1 | 100 |
| Standing Weight Press | ×1 | 100 |
| Dips | ×2 | 200 |
| Push-ups | ×3 | 300 |
| Leg Lifts | ×3 | 300 |
| Sit-ups | ×4 | 400 |
| Air Squats | ×5 | 500 |

## License

MIT License - See LICENSE file for details

## Author

JocoDigital - [jocodigital.com](https://jocodigital.com)

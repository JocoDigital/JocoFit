-- JocoFit Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- ============================================
-- WORKOUT SESSIONS TABLE
-- Stores completed and partial workout sessions
-- ============================================

CREATE TABLE IF NOT EXISTS workout_sessions (
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

-- Add comments for documentation
COMMENT ON TABLE workout_sessions IS 'Stores all workout sessions for users';
COMMENT ON COLUMN workout_sessions.workout_mode IS 'Workout type identifier (e.g., "full", "ascending", "custom_pull_ups_push_ups_full")';
COMMENT ON COLUMN workout_sessions.exercise_reps IS 'JSON object mapping exercise names to completed reps';
COMMENT ON COLUMN workout_sessions.exercise_timing IS 'JSON object mapping exercise names to time spent in seconds';

-- ============================================
-- WORKOUT TEMPLATES TABLE
-- Stores saved custom workout configurations
-- ============================================

CREATE TABLE IF NOT EXISTS workout_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  exercises TEXT[] NOT NULL,
  progression_mode TEXT NOT NULL CHECK (progression_mode IN ('full', 'ascending', 'descending')),
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE workout_templates IS 'Saved custom workout configurations';
COMMENT ON COLUMN workout_templates.exercises IS 'Array of exercise names included in this template';
COMMENT ON COLUMN workout_templates.progression_mode IS 'One of: full, ascending, descending';

-- ============================================
-- EXERCISES TABLE (Optional - for future expansion)
-- Master list of exercises with metadata
-- ============================================

CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  multiplier INTEGER NOT NULL DEFAULT 1,
  category TEXT CHECK (category IN ('upper', 'lower', 'core')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default exercises
INSERT INTO exercises (name, multiplier, category, description) VALUES
  ('Pull-ups', 1, 'upper', 'Grip bar with palms facing away, pull chin above bar'),
  ('Standing Weight Press', 1, 'upper', 'Press weight overhead from shoulder level'),
  ('Dips', 2, 'upper', 'Lower body between parallel bars, push back up'),
  ('Push-ups', 3, 'upper', 'Standard push-up with full range of motion'),
  ('Leg Lifts', 3, 'core', 'Hang from bar, lift legs to parallel'),
  ('Sit-ups', 4, 'core', 'Full sit-up with controlled movement'),
  ('Air Squats', 5, 'lower', 'Bodyweight squat to parallel or below')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- INDEXES
-- Optimize common query patterns
-- ============================================

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_mode
  ON workout_sessions(user_id, workout_mode);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_date
  ON workout_sessions(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_completed
  ON workout_sessions(user_id, completed, workout_mode);

CREATE INDEX IF NOT EXISTS idx_workout_templates_user
  ON workout_templates(user_id);

CREATE INDEX IF NOT EXISTS idx_workout_templates_favorite
  ON workout_templates(user_id, is_favorite) WHERE is_favorite = true;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Ensure users can only access their own data
-- ============================================

-- Enable RLS on all tables
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can insert own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can delete own sessions" ON workout_sessions;
DROP POLICY IF EXISTS "Users can view own templates" ON workout_templates;
DROP POLICY IF EXISTS "Users can insert own templates" ON workout_templates;
DROP POLICY IF EXISTS "Users can update own templates" ON workout_templates;
DROP POLICY IF EXISTS "Users can delete own templates" ON workout_templates;

-- Workout Sessions Policies
CREATE POLICY "Users can view own sessions" ON workout_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON workout_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON workout_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions" ON workout_sessions
  FOR DELETE USING (auth.uid() = user_id);

-- Workout Templates Policies
CREATE POLICY "Users can view own templates" ON workout_templates
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own templates" ON workout_templates
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates" ON workout_templates
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates" ON workout_templates
  FOR DELETE USING (auth.uid() = user_id);

-- Exercises table is public read-only
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read exercises" ON exercises
  FOR SELECT TO authenticated USING (true);

-- ============================================
-- FUNCTIONS (Optional - for advanced features)
-- ============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on workout_sessions
DROP TRIGGER IF EXISTS update_workout_sessions_updated_at ON workout_sessions;
CREATE TRIGGER update_workout_sessions_updated_at
  BEFORE UPDATE ON workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- USEFUL QUERIES (for reference)
-- ============================================

-- Get user's personal best for a specific workout mode
-- SELECT * FROM workout_sessions
-- WHERE user_id = auth.uid()
--   AND workout_mode = 'full'
--   AND completed = true
-- ORDER BY total_workout_time_seconds ASC
-- LIMIT 1;

-- Get user's workout stats
-- SELECT
--   COUNT(*) as total_sessions,
--   COUNT(*) FILTER (WHERE completed = true) as completed_sessions,
--   SUM(total_completed_reps) as total_reps,
--   SUM(total_workout_time_seconds) as total_time,
--   MIN(total_workout_time_seconds) FILTER (WHERE completed = true) as best_time
-- FROM workout_sessions
-- WHERE user_id = auth.uid();

-- Get recent sessions with pagination
-- SELECT * FROM workout_sessions
-- WHERE user_id = auth.uid()
-- ORDER BY created_at DESC
-- LIMIT 10 OFFSET 0;

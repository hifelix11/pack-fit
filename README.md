# PackFit: Group Fitness Goals

A Flutter app for group fitness accountability with a built-in synced workout timer.

## Features

- **Packs (Groups)** — Create or join groups via 6-character invite codes
- **Daily Goals** — Admin sets a daily goal; every member must check in
- **Group Completion** — Goal only completes when ALL members check in
- **Streaks** — Track consecutive days of full pack completion
- **Synced Timer** — Fullscreen LED stopwatch synced across devices via Supabase Realtime
- **Cross-platform** — iOS, Android, and Web from a single Flutter codebase

## Tech Stack

- **Flutter** (iOS + Android + Web)
- **Supabase** (Auth, Realtime, Postgres)
- **Riverpod** (State Management)
- **GoRouter** (Navigation)

## Setup

### 1. Flutter

```bash
flutter pub get
```

### 2. Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL migration in `supabase/migrations/00001_initial_schema.sql`
3. Enable **Apple** and **Google** as OAuth providers in the Supabase Dashboard
4. Enable Realtime on `timer_sessions` and `check_ins` tables

### 3. Configuration

Update `lib/features/shared/constants.dart` with your Supabase project URL, anon key, and OAuth client IDs.

### 4. DSEG7 Font

Download the DSEG7Classic-Bold.ttf font from [github.com/keshikan/DSEG](https://github.com/keshikan/DSEG/releases) and place it in `assets/fonts/`.

### 5. Run

```bash
# iOS / Android
flutter run

# Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart
├── app/
│   └── router.dart
├── features/
│   ├── auth/          # Sign-in (Apple + Google)
│   ├── onboarding/    # First-time name input
│   ├── home/          # Pack list, create/join
│   ├── pack/          # Pack detail, check-ins, goals, history
│   ├── timer/         # Synced LED timer
│   └── shared/        # Theme, models, constants
```

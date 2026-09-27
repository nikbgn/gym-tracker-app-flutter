# Gym Tracker

**[View the project here](https://nikolay-gym-tracker-landing.vercel.app/)**

A simple Android workout tracker. Your data stays on your phone. There is no account and no cloud sync.

## What it does

- Build a **library** of exercises and custom metrics (for example kg or seconds).
- Save **templates** that group exercises for a routine.
- Run a **live workout**, log sets, then finish to save it to history.
- Browse **history** and open past sessions. Completed workouts keep a snapshot of exercise and metric names even if you change the library later.

While a workout is in progress, sets live in app memory. They are written to the database only when you finish the session.

## Technologies

- **Flutter** and **Dart** for the UI and app logic
- **sqflite** for SQLite on Android
- **Material 3** dark theme

Target platform: **Android** (`com.luna.gym_tracker`).

## How the database works

On first launch the app creates a file named `gym_tracker.db` in the device app storage.

Tables:

| Table | Purpose |
|-------|---------|
| `metrics` | Units you track (default: kilograms) |
| `exercises` | Exercise name linked to a metric |
| `templates` | Named routines |
| `template_exercises` | Which exercises belong to each template, in order |
| `workout_sessions` | A finished workout (template reference, name, date) |
| `session_exercises` | Copy of exercise and metric names for that session |
| `workout_sets` | Reps and metric value per set |

Foreign keys are enabled. Deleting a template does not delete old sessions. Session rows store names at completion time so history stays accurate.

Schema and queries live in `lib/data/workout_database.dart`.

## Run locally

```sh
flutter pub get
flutter run
```

You need the Flutter SDK and an Android device or emulator.

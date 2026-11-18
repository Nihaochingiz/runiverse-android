# Runiverse

Runiverse is a private Android running journal with optional game mechanics.
Log a run, track your distance and pace, progress through ranks, and create
personal rewards that unlock after a chosen number of kilometers.

## Download

- [Runiverse 1.0.0 APK](Runiverse-1.0.0.apk)

Runiverse requires Android 7.0 (API 24) or newer. See the
[installation guide](docs/INSTALLATION.md) for step-by-step instructions.

## Features

- Record the date, distance, duration, and an optional note for each run.
- View total distance, total time, run history, and calculated pace.
- Progress through six ranks from Starter to Legend.
- Create custom rewards with distance requirements.
- Choose whether claimed rewards spend accumulated kilometers.
- Turn all game mechanics off and use a simple running journal.
- Store all data locally on the Android device with SQLite.
- Use a light white-and-purple Material design.

## Privacy

Runiverse has no accounts, analytics, advertising, or cloud backend. Run and
reward data remains in the local database. See [Privacy](docs/PRIVACY.md).

## Technology

- Flutter 3.50.0 and Dart 3.14.0
- SQLite through `sqflite`
- Material 3 UI
- Android compile/target SDK 36; minimum SDK 24

## Development

Setup, testing, and APK build instructions are in
[Development and build](docs/DEVELOPMENT.md).

## Project status

Version 1.0.0 is an offline MVP intended for personal installation and testing.

## License

Copyright (c) 2026. All rights reserved. No open-source license has been granted.

# Development and build

## Prerequisites

- Flutter stable with Dart
- JDK 17
- Android SDK platform 36
- Android build-tools 36.0.0 and platform-tools

Use the official setup documentation for [Flutter](https://docs.flutter.dev/install)
and the [Android SDK](https://developer.android.com/studio/).

## Get the project

```bash
git clone https://github.com/Nihaochingiz/runiverse-android.git
cd runiverse-android
flutter pub get
```

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Run and build

```bash
flutter devices
flutter run
flutter build apk --release
```

The generated APK is at `build/app/outputs/flutter-apk/app-release.apk`.
`Runiverse-1.0.0.apk` is the verified version 1.0.0 repository build.

## Release signing

The included version is intended for direct personal installation. Before a
Google Play release, create a protected upload keystore, configure release
signing, keep secrets outside the repository, and build an Android App Bundle.

## Data model

- `runs`: date, distance, duration, and note.
- `rewards`: title, kilometer cost, and redeemed state.
- `settings`: game-system and kilometer-spending switches.

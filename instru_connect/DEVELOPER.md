# InstruConnect — Developer Quick Start ✅

A concise one-page guide to get the project running locally and understanding its core structure.

## Prerequisites 🔧
- Flutter SDK (compatible with Dart SDK >= **3.8.1**) and platform toolchains (Android SDK, Xcode for iOS/macOS builds).
- Git
- (Optional) Firebase CLI & FlutterFire CLI for re-configuring Firebase: `npm i -g firebase-tools @flutterfire/cli`

## Quick Setup (first-time) ▶️
1. Clone the repo:
   ```bash
   git clone <repo-url>
   cd instru_connect
   ```
2. Install packages:
   ```bash
   flutter pub get
   ```
3. Firebase configuration:
   - This repo includes `lib/firebase_options.dart` and `android/app/google-services.json`.
   - If you need to reconfigure, run: `flutterfire configure` and add the generated `firebase_options.dart` to `lib/`.
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present in the platform projects.

## Running the app ▶️
- Run on connected device or emulator:
  ```bash
  flutter run
  ```
- Run on web:
  ```bash
  flutter run -d chrome
  ```
- Build artifacts:
  - Android APK: `flutter build apk --release`
  - Web: `flutter build web`
  - Windows: `flutter build windows`
  - iOS: `flutter build ipa` (macOS required)

## Useful commands 🧰
- Tests: `flutter test`
- Analyze: `dart analyze`
- Format: `dart format .`
- Generate icons (already configured): `flutter pub run flutter_launcher_icons:main`

## Project structure (high-level) 📁
- `lib/main.dart` — app entry; initializes Firebase and caps Firestore cache (15MB).
- `lib/app.dart` — `MaterialApp` configuration, `AuthGate` and routing.
- `lib/config/` — theme and `AppRouter` (`lib/config/routes/app_router.dart`).
- `lib/features/` — modular features: `auth`, `home`, `timetable`, `notices`, `complaints`, `resources`, `attendance`, `admin`, etc.
- `assets/` — images and app icon (`assets/logo/ic_logo.png`).

## Notes & tips 💡
- Firestore cache cap is set in `main.dart` to avoid large cache issues — update if needed.
- Authentication flow: `AuthGate` (`features/auth/services/auth_gate.dart`) switches between `LoginScreen` and `RoleLoadingScreen`.
- Add new routes in `AppRouter.generate` and update `route_names.dart` as needed.
- If you see Firebase errors on startup, confirm `firebase_options.dart` and platform config files are correct.

## Troubleshooting ⚠️
- Missing `google-services.json` / `GoogleService-Info.plist` → add from Firebase console for your project.
- Cannot build for iOS → run on macOS and ensure Xcode command line tools are installed.

---
Happy hacking! ✨ If you want, I can also create a short `CONTRIBUTING.md` or a visual file map of `lib/` next.
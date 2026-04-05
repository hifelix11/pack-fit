# PackFit — iOS & Android Environment Setup Guide

This guide covers everything you need to get PackFit running on iOS and Android devices/simulators.

---

## Prerequisites

- **Flutter SDK** 3.5+ installed ([flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
- **Xcode 15+** (for iOS — macOS only)
- **Android Studio** or Android SDK command-line tools (for Android)
- A **Supabase** project ([supabase.com](https://supabase.com))
- A **Google Cloud** project with OAuth credentials ([console.cloud.google.com](https://console.cloud.google.com))
- An **Apple Developer** account (for Apple Sign-In on iOS)

---

## 1. Generate Native Platform Directories

The repo does not include `ios/` or `android/` folders. Generate them:

```bash
flutter create --org com.packfit .
```

This creates `ios/`, `android/`, and other platform directories without overwriting existing Dart code.

After generation, run:

```bash
flutter pub get
```

---

## 2. Environment / Configuration

### No `.env` file — uses `constants.dart`

PackFit stores config in a Dart file rather than `.env`:

**File to update:** `lib/features/shared/constants.dart`

```dart
const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const String supabaseAnonKey = 'YOUR_ANON_KEY';
const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
const String googleIosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID';
const String webOAuthRedirectUrl = 'https://packfit.app/auth/callback';
```

| Constant | Where to get it |
|---|---|
| `supabaseUrl` | Supabase Dashboard → Settings → API → Project URL |
| `supabaseAnonKey` | Supabase Dashboard → Settings → API → `anon` `public` key |
| `googleWebClientId` | Google Cloud Console → Credentials → OAuth 2.0 Web Client ID |
| `googleIosClientId` | Google Cloud Console → Credentials → OAuth 2.0 iOS Client ID |
| `webOAuthRedirectUrl` | Your deployed web URL + `/auth/callback` |

> **Tip:** If you prefer `.env` files, the `.gitignore` already excludes them — you could add a `.env` and use the `flutter_dotenv` package, but it's not set up by default.

---

## 3. Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Run the migration SQL:
   ```bash
   # Via Supabase Dashboard → SQL Editor, paste the contents of:
   supabase/migrations/00001_initial_schema.sql
   ```
3. **Enable OAuth providers** in Dashboard → Authentication → Providers:
   - **Google** — paste your Google Web Client ID and Client Secret
   - **Apple** — configure with your Apple Services ID and Key
4. **Enable Realtime** on these tables (Dashboard → Database → Replication):
   - `timer_sessions`
   - `check_ins`

---

## 4. iOS Setup (macOS only)

### 4.1 Google Sign-In — `GoogleService-Info.plist`

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
2. Create an **OAuth 2.0 Client ID** for iOS:
   - Application type: **iOS**
   - Bundle ID: `com.packfit.packFit` (or your custom bundle ID)
3. Download the `GoogleService-Info.plist`
4. Place it in:
   ```
   ios/Runner/GoogleService-Info.plist
   ```
5. Copy the `CLIENT_ID` from that plist into `constants.dart` → `googleIosClientId`

### 4.2 URL Scheme for Google Sign-In

Add the reversed client ID as a URL scheme in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Reversed iOS client ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 4.3 Apple Sign-In Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target → **Signing & Capabilities**
3. Click **+ Capability** → add **Sign in with Apple**
4. Ensure your Bundle ID matches what's registered in the Apple Developer portal

### 4.4 CocoaPods

```bash
cd ios && pod install && cd ..
```

### 4.5 Minimum iOS Version

Ensure `ios/Podfile` has a minimum deployment target of **iOS 13.0** or higher (required by `supabase_flutter` and `sign_in_with_apple`):

```ruby
platform :ios, '13.0'
```

### 4.6 Run on iOS

```bash
flutter run -d ios
# or target a specific simulator:
flutter run -d "iPhone 15 Pro"
```

---

## 5. Android Setup

### 5.1 Google Sign-In — `google-services.json`

1. Go to [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Credentials
   (or use [Firebase Console](https://console.firebase.google.com) for easier setup)
2. Create an **OAuth 2.0 Client ID** for Android:
   - Application type: **Android**
   - Package name: `com.packfit.pack_fit` (check `android/app/build.gradle` → `applicationId`)
   - SHA-1 fingerprint: get it with:
     ```bash
     cd android && ./gradlew signingReport
     ```
3. Download `google-services.json`
4. Place it in:
   ```
   android/app/google-services.json
   ```

### 5.2 Android Gradle Config

**`android/build.gradle`** (project-level) — ensure the Google Services plugin is listed:

```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**`android/app/build.gradle`** (app-level) — apply the plugin and set min SDK:

```groovy
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21  // Required by supabase_flutter
        targetSdkVersion 34
    }
}
```

### 5.3 Android Manifest — Deep Links (optional)

If you need OAuth redirect deep links, add an intent filter in `android/app/src/main/AndroidManifest.xml` inside the `<activity>` tag:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.packfit.packfit"
          android:host="auth-callback" />
</intent-filter>
```

### 5.4 Run on Android

```bash
flutter run -d android
# or target a specific device:
flutter devices  # list connected devices
flutter run -d <device-id>
```

---

## 6. DSEG7 Font Asset

Download the LED timer font and place it in the project:

1. Download `DSEG7Classic-Bold.ttf` from [github.com/keshikan/DSEG/releases](https://github.com/keshikan/DSEG/releases)
2. Place in `assets/fonts/DSEG7Classic-Bold.ttf`

This is already declared in `pubspec.yaml`.

---

## 7. Summary — Files You Need to Change / Add

| File | Action | Purpose |
|---|---|---|
| `lib/features/shared/constants.dart` | **Edit** | Add Supabase URL, keys, OAuth client IDs |
| `ios/Runner/GoogleService-Info.plist` | **Add** | Google Sign-In config for iOS |
| `ios/Runner/Info.plist` | **Edit** | Add reversed client ID URL scheme |
| `ios/Runner.xcworkspace` (Xcode) | **Edit** | Add "Sign in with Apple" capability |
| `ios/Podfile` | **Edit** | Set `platform :ios, '13.0'` minimum |
| `android/app/google-services.json` | **Add** | Google Sign-In config for Android |
| `android/build.gradle` | **Edit** | Add Google Services classpath |
| `android/app/build.gradle` | **Edit** | Apply plugin, set `minSdkVersion 21` |
| `assets/fonts/DSEG7Classic-Bold.ttf` | **Add** | LED timer display font |

---

## 8. Quick Start Checklist

- [ ] Run `flutter create --org com.packfit .` to generate platform dirs
- [ ] Run `flutter pub get`
- [ ] Fill in `constants.dart` with Supabase + Google OAuth values
- [ ] Run Supabase migration SQL and enable Realtime
- [ ] **iOS:** Add `GoogleService-Info.plist`, configure URL scheme, add Apple Sign-In capability, `pod install`
- [ ] **Android:** Add `google-services.json`, update Gradle files
- [ ] Download DSEG7 font into `assets/fonts/`
- [ ] `flutter run` on your target device

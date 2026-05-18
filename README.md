# Franchise Management App

> A cross-platform Flutter application for managing franchise operations, backed by Firebase and Firebase Cloud Functions.

**Repository → [github.com/hadi-14/franchise_management_app](https://github.com/hadi-14/franchise_management_app)**

---

## About

A full-stack cross-platform franchise management application built with Flutter and Firebase. Designed to give franchise owners and managers a unified platform to oversee operations, track performance, manage staff, and handle day-to-day franchise workflows — all from a single app that runs on Android, iOS, Web, Windows, and macOS.

---

## Features

- **Multi-platform** — Single codebase targeting Android, iOS, Web, Windows, and macOS
- **Firebase Authentication** — Secure role-based login for franchise owners, managers, and staff
- **Real-time Database** — Live data sync across all devices using Firebase Firestore
- **Cloud Functions** — Server-side business logic handled via Firebase Cloud Functions (TypeScript)
- **Firebase Hosting** — Web version deployed and hosted on Firebase
- **Franchise Dashboard** — Overview of key metrics and operational status
- **Role-based Access Control** — Different views and permissions per user role

---

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform UI framework |
| Dart | Application language |
| Firebase Firestore | Real-time NoSQL database |
| Firebase Authentication | User auth & role management |
| Firebase Cloud Functions | Server-side logic (TypeScript) |
| Firebase Hosting | Web deployment |

---

## Project Structure

```
lib/                   # Flutter app source code
├── screens/           # UI screens (dashboard, login, management views)
├── models/            # Data models
├── services/          # Firebase service classes
└── main.dart          # App entry point
server/                # Firebase Cloud Functions (TypeScript)
├── src/               # Function source files
└── index.ts           # Functions entry point
assets/                # Images, fonts, and static assets
android/               # Android-specific config
ios/                   # iOS-specific config
web/                   # Web-specific config
windows/               # Windows-specific config
macos/                 # macOS-specific config
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Node.js 18+ (for Cloud Functions)
- A Firebase project with Firestore, Auth, and Functions enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/hadi-14/franchise_management_app.git

# Navigate into the project
cd franchise_management_app

# Install Flutter dependencies
flutter pub get
```

### Firebase Setup

```bash
# Login to Firebase
firebase login

# Link to your Firebase project
firebase use --add

# Install Cloud Functions dependencies
cd server
npm install
cd ..
```

### Run the App

```bash
# Run on connected device or emulator
flutter run

# Run on web
flutter run -d chrome

# Run on Windows
flutter run -d windows
```

### Deploy Cloud Functions

```bash
cd server
firebase deploy --only functions
```

### Deploy Web to Firebase Hosting

```bash
flutter build web
firebase deploy --only hosting
```

---

## Supported Platforms

| Platform | Status |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| Windows | ✅ |
| macOS | ✅ |

---

## Environment Setup

Add your Firebase config to the appropriate platform files. For web, update `web/index.html` with your Firebase project credentials. For mobile, add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to their respective directories — these are excluded from version control via `.gitignore`.

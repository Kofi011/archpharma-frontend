# ArchPharma Wholesale ERP System

Enterprise-grade Wholesale Pharmacy Sales, Inventory, and Invoice Management mobile application built with Flutter.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.44.9 or higher recommended)
- [Dart SDK](https://dart.dev/get-dart) (version 3.12.2 or higher)
- Android Studio or Xcode (for building to mobile devices)
- Node.js & npm (for running the NestJS backend API)

### Project Configuration
The application connects to a backend NestJS server. Configuration settings (such as the default API host) can be set inside `lib/core/constants/app_constants.dart` or changed dynamically through the system settings screen in the app.

---

## Setup & Running Instructions

### 1. Codebase Generation
The local database utilizes Drift (SQLite). Before compiling the app, run the build runner to generate the database parts:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Running Locally (Development Mode)
To run the Flutter app on an emulator, connected physical phone, or browser:
```bash
# Run on Chrome
flutter run -d chrome

# Run on specific target emulator
flutter run -d <device_id>
```

### 3. Build & Release
To build a production release APK for Android deployment:
```bash
flutter build apk --release
```

---

## Project Structure Overview

```text
lib/
├── core/
│   ├── constants/    # Centralized app configurations & endpoints
│   ├── errors/       # Structured custom exception classes
│   ├── services/     # Logging services, app router, state filters
│   ├── theme/        # Unified app colors and material theme tokens
│   ├── utils/        # Platform-independent file savers and formatters
│   └── widgets/      # Reusable standard UI buttons, inputs, loader controls
│
├── data/
│   ├── datasource/   # Local Drift SQLite client and REST ApiClient
│   ├── repositories/ # Abstract repository boundaries wrapping datasource actions
│   └── models/       # Data models and structures (Product, Customer, etc.)
│
├── features/
│   ├── auth/         # Authentication view controllers and providers
│   ├── dashboard/    # System homepage reporting widgets
│   ├── sales/        # Invoice builders, item selectors, and PDF print hooks
│   ├── inventory/    # Stocking log pages and catalog ledgers
│   ├── customers/    # Customer directory and credit history reports
│   ├── reports/      # Sales performance analytics and CSV data tables
│   ├── settings/     # Local database maintenance and configuration switches
│   └── sync/         # Local Drift SQLite to NestJS API syncer status badges
│
└── main.dart         # Material application initializer
```

---

## Troubleshooting & FAQ

### Issue: Drift Database Code Generation Fails
**Fix:** Run clean commands followed by build runner:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Cannot Authenticate to Node REST API from Physical Android Device
**Fix:** Ensure your computer and your physical device are connected to the same local network (Wi-Fi). Check your computer's LAN IP address and configure it inside the system settings or `lib/core/constants/app_constants.dart` as the host endpoint.

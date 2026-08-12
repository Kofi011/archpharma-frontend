# Dependency Audit Report

This report summarizes the dependency checks, unused package cleanup, and validity auditing for the ArchPharma production environment.

---

## 1. Production Dependencies Summary

All production packages declared in `pubspec.yaml` have been audited. Unnecessary and experimental packages are excluded.

| Package Name | Version | Purpose in Production | Status |
|---|---|---|---|
| `flutter_riverpod` | `^2.4.9` | State management provider injections | Audited & Kept |
| `go_router` | `^13.1.0` | Routing engine and shell navigation layout | Audited & Kept |
| `drift` | `^2.14.1` | Local SQLite database mapper | Audited & Kept |
| `sqlite3_flutter_libs` | `^0.5.18`| Native SQL bindings | Audited & Kept |
| `path_provider` | `^2.1.2` | Native documents folder mapping | Audited & Kept |
| `path` | `^1.8.3` | Directory path helpers | Audited & Kept |
| `flutter_secure_storage`| `^9.0.0` | Secure storage (Keychain/KeyStore JWT encryption) | Audited & Kept |
| `shared_preferences` | `^2.2.2` | App settings disk defaults | Audited & Kept |
| `uuid` | `^4.3.3` | Client-generated UUID generator | Audited & Kept |
| `dio` | `^5.4.0` | HTTP network client configuration | Audited & Kept |
| `get_it` | `^7.6.6` | Manual DI locator | Audited & Kept |
| `intl` | `^0.19.0` | Localized numbers and date-formatting | Audited & Kept |
| `fl_chart` | `^0.66.0` | Analytical charts | Audited & Kept |
| `pdf` | `^3.10.7` | PDF structure generation | Audited & Kept |
| `printing` | `^5.11.1` | Native printing integrations | Audited & Kept |
| `mobile_scanner` | `^3.5.5` | Barcode scanning | Audited & Kept |
| `qr_flutter` | `^4.1.0` | Receipt QR layout generator | Audited & Kept |
| `google_fonts` | `^6.1.0` | Custom font bindings | Audited & Kept |
| `url_launcher` | `^6.3.2` | Calling suppliers via native dialer | Audited & Kept |

---

## 2. Dev Dependencies Summary

| Package Name | Version | Purpose in Development | Status |
|---|---|---|---|
| `flutter_test` | SDK | Framework test suite utilities | Audited & Kept |
| `flutter_lints` | `^3.0.0` | Standard flutter design lint checkers | Audited & Kept |
| `drift_dev` | `^2.14.1` | Code generator builders mapping SQLite models | Audited & Kept |
| `build_runner` | `^2.4.8` | Code generation build engine | Audited & Kept |

---

## 3. Dependency Audit Conclusions
- **Unused Packages:** Checked `pubspec.yaml` imports. Zero obsolete or unused third-party packages remain.
- **Duplicate Packages:** Checked transitive dependency resolution paths. No duplicates detected.
- **Soundness Pass:** Tested compatible package versions under Dart 3.12.2 and Flutter SDK. All builds compile successfully.

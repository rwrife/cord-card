# Cord Card

Offline cable and charger organizer: label cords, record known connectors and storage spots, and find the right lead on phone, tablet, or Windows.

## Why / who

Home users, makers, and shared-workspace owners accumulate dozens of black cables, power bricks, and adapters whose connector types, rated wattages, and storage locations become impossible to tell apart. Cord Card turns a quick manual inventory into a searchable personal reference without a cloud account, marketplace catalog, or intrusive hardware probing.

## Intended workflow

1. Add a cable, power supply, or adapter with a human label, user-selected connector ends (with explicit unknown support), optional length, user-read printed wattage, and physical storage location.
2. Filter by connector type, storage bin, or keyword; inspect the original entry before plugging anything in.
3. Mark moved or retired leads; export a portable JSON backup and import it onto another personal device without an account.

Important limitation: manual inventory and label helper only. A connector match does **not** prove electrical compatibility, safe current carrying, data capability, or USB-PD profile support. Never use this app as proof of wiring safety or power adequacy.

## Status / milestones

Flutter 3.47.7 project skeleton for Windows, Android, and iOS exists. CI builds Windows release and Android debug, and checks committed platform files; iOS compilation remains unverified. Inventory, persistence, search, backups, adaptive UX, and release automation are **not implemented**. Issues track each milestone. `AppStore/icon.png` was generated via OpenAI Images (`gpt-image-2.5-flare`); launcher review remains in the backlog.

## Scope

MVP: manual inventory, explicit unknown fields, local search/filter, storage location tracking, JSON export/import, accessible adaptive phone/tablet/desktop UI, and a downloadable Windows release ZIP. Explicit non-goals: no cloud sync, accounts, marketplace catalogs, device-level USB probing, automatic wattage validation, price lookups, or subscriptions. No camera, microphone, contacts, location, or network permission needed for core workflow.

Local data stays on device; users move backups explicitly. No analytics, tracking, or background sync. Deleting a record requires confirmation. Exports avoid raw host filesystem paths and machine names.

UX strategy B: fully custom branded neutral UI, neither Material on iOS nor Cupertino on Android. Honors each OS's back navigation, scrolling physics, text context actions, safe areas, font scaling, native file pickers, hover, and keyboard shortcuts. Phone uses a stacked list/detail; tablet and Windows use split panels. Widget/golden tests must exercise `TargetPlatform.iOS`, `TargetPlatform.android`, and `TargetPlatform.windows`.

Bundle ID / applicationId: `com.infinityball.cordcard` across iOS, Android, and future Windows/MSIX identity. iPad and Android tablet support enabled. Store submission is a later milestone; Windows portable ZIP on `v*` tag via GitHub Actions release workflow is the primary MVP deliverable. GitHub Actions repository secrets provisioned by name: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID`. No signing credentials stored in-repo.

## Development

Pinned toolchain: Flutter 3.47.7 / Dart 3.13.5. Run `flutter pub get && flutter test && flutter analyze`; Windows release builds with `flutter build windows --release`; Android debug with `flutter build apk --debug`; iOS requires Xcode on macOS. On Linux, run Flutter inside a pinned Docker container per repository preference. Platform folders `windows/`, `android/`, `ios/` remain checked in. See `PLAN.md` and `toolchain.json`.

## Manual setup required

App Store Connect bundle registration for `com.infinityball.cordcard` failed during automated setup: `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`. The account owner must accept the current Apple Program License Agreement in the Apple Developer portal before bundle registration can succeed. Repository secret names are provisioned in GitHub Actions; this does not prove App Store Connect app-record readiness.

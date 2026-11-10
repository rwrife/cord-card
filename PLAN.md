# Cord Card build plan

## Architecture / scope

Flutter 3.47.7 / Dart 3.13.5, one codebase with committed `windows/`, `android/`, `ios/` platform folders. App ID `com.infinityball.cordcard` for Android `applicationId`, iOS bundle ID, and prospective MSIX identity. iPad and Android tablet support enabled. Windows release primary; Android debug build in Linux CI; iOS build on macOS milestone. No hosted service or account.

Domain: `CordItem` (`id`, name, kind cable/charger/adapter, connector ends with explicit unknown, printed rating note, optional length, storage spot, status, free-text note, updated timestamp). User-entered ratings are notes, not certified electrical measurements. Connector match is only a catalog filter, never a compatibility/safety verdict. Local repository stores versioned JSON atomically; import validates schema and shows a preview before replacing/merging. Export explicit through native file picker; never send raw paths, serials, or machine names without user choice. No permissions beyond explicitly chosen file access.

UX strategy **B — fully custom branded neutral design system**: avoid Material appearance on iOS, Cupertino appearance on Android, and phone-only UI on Windows. Flutter shared components own neutral visual language while platform behaviors remain native: back/gesture, scrolling, selections/context menu, file picker, safe areas, font scaling, high contrast, hover/focus/shortcuts and resizable windows. List/detail stacks on phone, uses two panes on tablet/desktop. Touch + keyboard/mouse. Accessibility: semantic labels, screen readers, text scaling, full Windows keyboard traversal. Widget/golden tests for `TargetPlatform.iOS`, `TargetPlatform.android`, `TargetPlatform.windows` at phone/tablet/desktop sizes.

## Milestones / dependencies

1. Skeleton consistency and Windows/Android CI, Flutter test/analyze; preserve all three platform folders and accurate IDs.
2. Domain model plus round-trip/versioned local storage with invalid-input tests.
3. Manual add/edit/retire flow; no inference from connector labels.
4. Local search/filter and location workflow.
5. Adaptive accessible UI with per-platform behavior/goldens.
6. Import/export backups with non-destructive preview, cancellation and corrupt-input tests.
7. Generate and wire real icon from OpenAI Images (`AppStore/icon.png`) into Windows `.ico`, Android densities and iOS catalog; update `AppStore/description.txt` to match shipping features.
8. `.github/workflows/release.yml`: tag `v*` or manual dispatch; Windows `flutter build windows --release`, archive all Release output, attach ZIP to GitHub release. Android/iOS builds remain CI targets; TestFlight via `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `ASC_TEAM_ID` and Google Play submission are later opt-in milestones.

## Tests / release gates

Use pure Dart unit tests for status transitions, unknown connectors, validation and backup migration; Flutter widget/golden tests for adaptive layout, semantic focus and platform behavior. CI `windows-latest` runs `flutter test`, `flutter analyze`, `flutter build windows --release`; Linux pinned Docker image runs Dart tests and `flutter build apk --debug`; macOS iOS compile later. Check emitted ZIP contains `.exe`, `data/`, Flutter DLLs; verify actual tagged GitHub release asset. No pretend CI proof from scaffold.

## Risks / non-goals

Users may misread a connector match as electrical compatibility: visibly warn in edit/details and never auto-predict USB data or PD wattage. USB labels are user-supplied, may be wrong. Local backup loss: atomic writes, non-destructive import preview, safe confirmation. Non-goals: automatic device detection, electrical testing, warranty claims, marketplace price matching, cloud sync, medical or life-safety use. Privacy: no analytics/network; local user-owned data and user-initiated export only.

## App Store Connect gate

Bundle registration of `com.infinityball.cordcard` is blocked by `FAILED bundleId lookup rejected: FORBIDDEN_ERROR.PLA_NOT_ACCEPTED`; owner accepts Apple PLA before retry. iOS signed archive/TestFlight release not claimed as MVP.

# Actual verification — October 26, 2026

Scope: Rohan UI integration review, source commit `b056775`. Not a final persisted-app acceptance test. Production injects PendingGateway until Het's implementation is available. All UI data/suggestion fixtures are explicitly synthetic test-double values; none is claimed as SQLite/helper correctness, real usage or peer feedback.

| Executed command/check | Actual result |
| --- | --- |
| `flutter doctor -v` | PASS: no issues; Flutter 3.47.4 stable, Dart 3.13.3, Android SDK/build-tools 36.0.0, Java 25.0.3. Initially only Chrome/Edge targets; existing AVD subsequently started. |
| `flutter pub get` | PASS; actual pubspec.lock created; runtime Flutter SDK, dev flutter_test/flutter_lints; Het's runtime packages not yet present. |
| `dart format --output=none --set-exit-if-changed lib test` | PASS: 8 files, 0 changed, exit 0. |
| `flutter analyze` | PASS: No issues found, exit 0. Raw output docs/verification/flutter_analyze.txt. |
| `flutter test --reporter expanded` | PASS: 10/10 widget tests, exit 0. Raw output docs/verification/flutter_test.txt. |
| `flutter build apk --release` | PASS: assembleRelease 58.2 seconds on final rebuild, 44.6 MB reported, exit 0. Raw output docs/verification/flutter_build_apk.txt. |
| `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk` | PASS: Performing Streamed Install / Success. Raw output docs/verification/android_install.txt. |
| `adb -s emulator-5554 shell am start -W -n edu.gsu.bloom.bloom/.MainActivity` | PASS startup only: Status ok; COLD launch; Activity edu.gsu.bloom.bloom/.MainActivity; TotalTime 8872 ms / WaitTime 8957 ms. Raw output docs/verification/android_launch.txt. |
| `adb ... logcat -d -s AndroidRuntime:E flutter:E` | No matching error output at the checked moment; not a guarantee of all runtime behavior. |
| Actual emulator screen capture | Captured/inspected final_submission/evidence/Bloom_Integration_Pending.png. It shows the honest missing-adapter error, NOT a functioning persisted habit tracker. |
| `git diff HEAD~1 --check` after source normalization | PASS. Generated Windows scaffold line endings initially triggered whitespace findings; normalized staged text with .gitattributes and included required Gradle wrapper files. |

## Actual APK identity

Path: `build/app/outputs/flutter-apk/app-release.apk`

Bytes: **46,818,358**.

SHA-256: `BEC993A73DE899F689A461EB78CECC6F403062BD0437149474166F7A776E3C9D`.

Release-mode compilation, signed using generated local debug signing configuration for coursework installation; not a production signing certificate. No signing key committed. This APK must be replaced with a rebuilt integrated application before true final submission.

## Real Android runtime used

One existing AVD: `Pixel_4a`, started headlessly; adb serial `emulator-5554`; model `sdk_gphone16k_x86_64`; Android **17**; boot_completed=1. Fingerprint: `google/sdk_gphone16k_x86_64/emu64xa16k:17/CP31.260623.012/16064790:userdebug/dev-keys`.

Only APK install/launch and current error-state screenshot were checked on this emulator. A second distinct Android device/emulator check is **PENDING**, not passed. Widget viewport checks are not a substitute for Android device coverage.

## Ten UI tests actually executed

1. Production PendingGateway error and retry, with no invented records.
2. Empty-state create form, missing-name/zero-target validation and refresh after test-double save.
3. Failed save preserves form and shows actionable error.
4. Start, temporary slider progress, explicit Finish, Reset cancel/confirm.
5. Goal Apply prefill, Cancel no write, explicit Save changes test-double goal.
6. Habit cascade-warning confirmation/cancellation.
7. Out-of-range progress and duplicate habit/date blocked before gateway write.
8. Settings calls and refreshed values (not actual SharedPreferences persistence).
9. Saved-record garden/count/history display, check-in correction and deletion retaining habit (test double).
10. Portrait 390×844 / landscape 844×390 at 2× text scale, tab navigation without framework exceptions, and gateway close on app disposal.

## Failures found and fixed

First analyze reported eight missing-brace lint issues; fixed with Dart's supported fix tool. First test compile failed because the finder accessed TextFormField.decoration; corrected to the inner TextField. Runtime tests exposed invalid progress-bar semantic text and a narrow/large-text dropdown overflow; removed the nonnumeric semantic value while keeping a descriptive label, and expanded dropdowns. Final checks above pass after these fixes. Initial SDK tooling needed access outside the workspace; rerun with approved SDK access succeeded.

Build emitted Java native-access and SDK XML-version warnings; neither failed the build. They are recorded in raw output and were not suppressed or represented as test failures.

## Not run / blocked

- Het's real SQLite repository/helper tests, migrations, FK/cascade/unique enforcement, preferences writes, local helper rule/baseline/MAE evaluation.
- App-level persisted CRUD, process-termination/restart, airplane-mode persistence, two-device coverage.
- Real device portrait/landscape/large text, screen reader/contrast, usability observation and improvement evidence.
- Actual final integrated APK acceptance, recording, signatures, course uploads/receipts.

These are blocked on Het's branch and genuine human evidence. No pending check is counted as passing.

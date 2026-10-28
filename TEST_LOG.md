# Actual integrated verification — October 26, 2026

Runtime source commit: `2cf89bc` (full compiled-code snapshot in Git). Het's exact source tip `64592948b41686de65cbd660102d034fe6bc1225` is preserved in ancestry. Later changes are documentation/verification-script improvements; Het's data/helper sources are unchanged.

## Commands and final results

| Command/check | Actual result | Evidence |
| --- | --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | PASS, 16 files, zero changes, exit 0 | docs/verification/integrated_format.txt |
| `flutter analyze` | PASS, no issues, exit 0 | docs/verification/integrated_analyze.txt |
| `flutter test --reporter expanded` | PASS, 33 tests, exit 0 | docs/verification/integrated_host_tests.txt |
| `flutter test integration_test/android_acceptance_test.dart -d emulator-5554 --no-uninstall --reporter expanded` | PASS, 2 real-plugin acceptance tests, exit 0 | docs/verification/android_pixel_acceptance_preserved.txt |
| Same integration test on `emulator-5556` | PASS, 2 tests, exit 0 | docs/verification/android_tablet_acceptance_preserved.txt |
| `flutter build apk --release` | PASS, assembleRelease 115.0 seconds; 50.2 MB reported, exit 0 | docs/verification/integrated_release_build.txt |
| `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify_android_release.ps1 -Serial emulator-5554` | PASS, exact release APK installed, force-stopped/relaunched offline, all settings restored, screenshots and rotated large text checked | docs/device_evidence/emulator-5554/release_checks.txt |
| Same release script on `emulator-5556` | PASS on separate tablet profile | docs/device_evidence/emulator-5556/release_checks.txt |
| `aapt dump badging .../app-release.apk` | Actual package/version/SDKs inspected; no INTERNET permission in final APK | package edu.gsu.bloom.bloom, version 1.0.0+1, min SDK 24, target/compile SDK 36 |
| Git source comparison | No changes to Het-owned lib/data or lib/helper relative to reviewed tip | PR2_REVIEW.md and Git diff |

PowerShell permission above is process-local for the reviewed script; no machine execution policy was changed. Device settings (airplane/font/rotation) are restored in a finally block.

## APK identity

Path: `build/app/outputs/flutter-apk/app-release.apk`

Bytes: **52,658,245**.

SHA-256: `67A2A518877DDAB76C5D234105B231C66691146B21F55A2CC164D59200D7BFD7`.

Package: edu.gsu.bloom.bloom, versionCode 1 / versionName 1.0.0. Release-mode compilation uses the generated local debug signing configuration for coursework installation, not a production signing certificate. No signing key is committed. The APK includes the real repository/plugins and no PendingGateway; it starts empty on a clean installation and does not seed test records.

## Actual environment/devices

Host: Windows, Flutter 3.47.4 stable, Dart 3.13.3, Android SDK/build-tools 36.0.0, Android Studio Java 25.0.3. Het's separate macOS tool versions/results remain attributed in DATA_TEST_LOG.md.

| Serial | Real AVD profile | Natural resolution/density | Runtime |
| --- | --- | --- | --- |
| emulator-5554 | Existing Pixel_4a | 1080×2340 / 440 dpi | Android 17, x86_64, 16KB pages |
| emulator-5556 | New separate Bloom_Tablet_API37, medium_tablet device | 2560×1600 / 320 dpi | Android 17, x86_64, 16KB pages |

Both use installed image fingerprint `google/sdk_gphone16k_x86_64/emu64xa16k:17/CP31.260623.012/16064790:userdebug/dev-keys`. These are two distinct AVD instances/profiles, not two Android OS versions. No physical-device/older-OS coverage is claimed.

Rotated screenshots: phone **2340×1080 landscape**, tablet **1600×2560 portrait**, both at actual system font scale **1.5**. Initial screenshots cover the opposite natural orientation. Widget tests additionally cover portrait/landscape at **2×** text scaling. Captured images were visually inspected; normal scroll clipping is not an overflow claim.

## What the tests establish

Host 33 = Het's 20 data/helper tests + Rohan's 10 UI tests + 3 startup tests. Host SQLite tests use real temporary on-disk databases; settings host tests use explicit platform mocks; UI tests use a named test double. These scopes are not confused with actual Android results.

Each Android acceptance run uses the real production entry point, SQLite and SharedPreferences. It verifies habit create/edit/delete, check-in create/correction/delete, Start/resume, temporary slider vs saved values, Save/Finish/Reset confirmation, uniqueness and progress rejection, SQL cascade, child deletion preserving parent, actual settings writes, helper abstention, and an eligible 14-day synthetic fixture with Apply/Cancel/Save against real SQLite. Fixture values are labeled test data, not real-user evidence.

The independent release scripts then install the exact release APK over the retained test installation, enable actual airplane mode, force-stop the Android app process, cold launch it, and assert visible restored `[TEST] Restart proof`, `10 / 10 pages`, default target 27, Sunday and checked reduced-motion state through actual Android accessibility XML. Screenshots/logs are stored per serial. They navigate back, edit form, detail, history and rotation/text scale. No screenshot is a design mockup or generated image.

## Failures found and resolved

- Initial Android debug compilation failed in SharedPreferences Kotlin incremental cache across C: Pub cache and D: project roots. Fixed project build settings to nonincremental in-process Kotlin; subsequent debug and release builds pass. Raw failure retained in android_initial_kotlin_failure.txt.
- First device helper assertion ran before asynchronous SQLite I/O completed. Added bounded wait for the actual helper result. Raw failure retained.
- A real Android keyboard could obscure a test tap; test explicitly hides/unfocuses keyboard before hit-testing. Scrollable forms now dismiss keyboard on drag. Raw failure retained.
- Flutter test defaults to uninstalling the app after integration tests. The first release restart attempt therefore had no fixture to restore; inspection of installed Flutter tool code established cleanup behavior. Passing runs use the supported --no-uninstall flag. This is not reported as a SQLite data-loss bug.
- Windows PowerShell initially blocked .ps1 execution; used process-local script permission only. adb pull writes successful progress to stderr, so the script now checks native exit codes instead of treating stream type as failure. A reserved variable name and offscreen/navigation swipe coordinates in the harness were corrected. Final release checks pass on both profiles; earlier attempt sections remain in logs.
- Build emitted Java native-access/SDK XML warnings; actual final exit codes are zero. Warnings were not represented as failures or silently relabeled.

Helper evaluation reproduced: synthetic paired n=8 with one abstention; helper MAE 1.875 vs fixed-three baseline 1.625 days/week. Baseline is better on these artificial cases. See AI_FEATURE.md; no trained-model or real-world accuracy claim.

Core color-pair calculations: forest #285F4D on cream #FAF8F2 **6.98:1**, charcoal #243C32 on sage #E6EFE5 **10.10:1**. These calculations and layout checks do not certify full accessibility. Real screen-reader usability and physical luminance testing were not performed.

## Human evidence not established by tests

The actual assessment/delivery excerpts were subsequently supplied October 26 and mapped without app changes or new runtime test claims. The full bank was then supplied and a balanced ten-question selection prepared; no new runtime test result is claimed for documentation-only updates. No written instructor approval/approved proposal copy, signatures, peer usability observation, historic board captures, human review, real recording/video URL or iCollege receipt was supplied. The subsequently supplied class roster verifies UG-P03 and the two member names; no new runtime test is claimed for that metadata correction. No grading result or submission is claimed. The technical package identifies those gaps separately; neither member's authentic work is replaced by fabricated evidence.

## October 28 rerun and current Human?AI Testing guidance

Fresh formatter/analyzer/33-host-test rerun passed; raw output is in verification/host_rerun_2026-10-28 inside the submission package. The latest user-pasted announcement supersedes earlier guidance. Classification: **Human?AI Testing: student-directed, AI-executed automated checks**. The student requested/directed testing through chat; Codex executed the commands and inspected results. No individual manual test execution, observation of every run or human peer usability session is claimed. See TESTING_LABELS_AND_RERUN.md. Original device results retain their original dates; no fresh Android result is claimed here.

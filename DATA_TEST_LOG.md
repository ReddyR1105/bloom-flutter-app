# Het data/helper test log — October 26, 2026

Tested implementation commit: `ae7b357d09a20afd5cf561031be9354cee92aeb6` (tests executed immediately before committing the same code). Subsequent commits add documentation/evidence only. Platform: macOS arm64. Flutter 3.47.7, Dart 3.13.5. SDK: `/Users/hetjani/development/flutter_activity09/bin`; it is not on the default PATH. Commands below use that SDK by exporting its bin directory to PATH, or by invoking the equivalent absolute paths as in this session.

| Command | Actual result | Raw output |
|---|---|---|
| `dart format --output=none --set-exit-if-changed lib/data lib/helper test/data test/helper` | Exit 0; 7 files, 0 changed | `docs/data_verification/format.txt` |
| `flutter analyze` | Exit 0; No issues found | `docs/data_verification/flutter_analyze.txt` |
| `flutter test test/data test/helper --reporter expanded` | Exit 0; 20 tests passed | `docs/data_verification/data_helper_tests.txt` |
| `TZ=America/New_York flutter test --reporter expanded` | Exit 0; 30 tests passed, including all 10 existing UI tests | `docs/data_verification/flutter_test_all.txt` |
| `flutter doctor -v` | Completed; issues in 2 categories: SDK not on PATH, incomplete Xcode/CocoaPods. Android toolchain passes. Connected targets: macOS and Chrome; no Android device | `docs/data_verification/flutter_doctor.txt` |
| `git diff --check` | Exit 0, no whitespace errors | Empty output observed |

## Meaning of these checks

Repository tests use actual host SQLite through sqflite_common_ffi in temporary on-disk databases, not a fake repository. They cover habit/check-in CRUD, missing IDs, archive state, FK and cascade, uniqueness, failed correction rollback, malformed dates, targets/progress/status, Start/resume, Finish, Reset scope, historical target changes, independent-connection contention, close/reopen and no duplicate records. Database reopen verifies durable SQLite contents across connections; it is NOT app process termination/restart on Android.

Settings tests use the SharedPreferences platform in-memory test store. They verify defaults, all three values, reload, invalid/corrupt settings, and failed platform writes including cache recovery. They do NOT establish real SharedPreferences disk durability on a device. SharedPreferences write acknowledgment itself is not a guarantee against abrupt device power loss.

Helper tests cover empty/new/unfinished histories, 8→4, all completion counts 0–14, tie rounding, inclusive boundaries, leap/year/DST calendar construction, invalid/duplicate/wrong-habit records, counterexample, and held-out evaluation. The full suite ran with America/New_York TZ to exercise calendar dates across DST. Synthetic paired n=8, one abstention: helper MAE 1.875; baseline MAE 1.625 days/week.

Existing UI tests still use Rohan's test gateway. `main.dart` still injects PendingGateway. Passing UI tests do not mean production UI is wired to SQLite.

## Failures found and corrected

1. Initial test run: baseline-error assertion expected 15, actual 13. Corrected the assertion; no rule or synthetic outcome changed. Preserved `initial_test_failure.txt`.
2. Additional two-connection Start test: SQLite returned code 5 (database locked). Added bounded retry for busy/locked transactions, with rollback before re-execution and no external side effects in callbacks. Preserved `concurrent_start_failure.txt`. Final test passes with exactly one record.
3. Initial analyzer identified missing braces in new code. Applied fixes and reran; final analyzer has no issues.

## Still pending / outside this portion

No Android emulator/device scenario was executed in this session; no Android target was connected. No app force-stop/relaunch, airplane-mode, two-device, real platform-preferences or integrated UI/SQLite verification is claimed. Rohan must connect the repository, run those scenarios and package the final APK once. No APK or competing submission ZIP was built. Instructor rubric, individual reflection/contribution requirements and genuine human evidence are not verified by automated tests.

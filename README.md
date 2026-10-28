# Bloom

**Small steps. Visible growth.** An offline Flutter habit tracker with cream/sage/forest styling and a saved-progress garden.

Rohan Reddy Gosangi and Het Jani — undergraduate pathway. Deadline: **October 27, 2026, 11:59 PM America/New_York**. Verified roster group: **UG-P03 (Group 03)**.

Repository: https://github.com/ReddyR1105/bloom-flutter-app
Integrated branch: `rohan/final-ui-integration`; PR #1 targets main. Het's exact branch tip `64592948b41686de65cbd660102d034fe6bc1225` is preserved in its ancestry (PR #2).

The actual app is now connected to `BloomRepository.open()` for SQLite, real SharedPreferences and the offline helper. The previous pending-data placeholder is removed. Technical checks and remaining human evidence are distinguished in [TEST_LOG.md](TEST_LOG.md) and [SUBMISSION_VERIFICATION.md](SUBMISSION_VERIFICATION.md); automated checks do not establish grading compliance.

## Setup, run and build

Verified development environment: Flutter **3.47.4 stable**, Dart **3.13.3**, Android SDK/build-tools **36.0.0**, Android Studio bundled Java **25.0.3**. Install Flutter/Android SDK and accept Android licenses, then:

```powershell
git clone https://github.com/ReddyR1105/bloom-flutter-app.git
cd bloom-flutter-app
git switch rohan/final-ui-integration
flutter doctor -v
flutter pub get
flutter run -d <android-device-id>
```

Android is the supported runtime; host tests use SQLite FFI. Browser targets are not a supported SQLite app runtime. No credentials, server, account or internet connection is needed for app usage. Development tools may download build dependencies.

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --reporter expanded
flutter test integration_test/android_acceptance_test.dart -d <android-emulator-id> --no-uninstall --reporter expanded
flutter build apk --release
```

Actual output: `build/app/outputs/flutter-apk/app-release.apk`. The release-mode build uses the local debug signing configuration for coursework installation, not a production signing certificate. No key is committed. Windows Kotlin incremental caching is disabled to handle the project/Pub cache being on different drives. Required Gradle wrappers and pubspec.lock are committed; generated caches/build folders/local.properties are excluded.

Runtime dependencies: `sqflite 2.4.5`, `shared_preferences 2.5.6`, `path 1.9.1`, Flutter SDK. Dev dependencies: flutter_test/integration_test SDKs, flutter_lints 6.0.0, sqflite_common_ffi and shared_preferences_platform_interface. Exact transitive versions are in pubspec.lock.

## Screen flow and usage

Four tabs — Today, Habits, Insights, Settings — plus routed forms/activity provide five distinct roles:

1. **Today:** real completed count, saved-completion garden, habit cards and category filter. Tap a habit for activity; New habit opens the form.
2. **Create/edit habit:** title, category, measurement unit, daily target 1–100000, weekly target 1–7. Save validates/persists; Cancel does not. Duplicate titles are allowed; IDs distinguish habits.
3. **Habit detail/activity:** Start creates/resumes the canonical local-day entry. Slider/stepper changes are temporary until Save progress or Finish. Finish requires the daily target. Reset confirms today's saved entry becomes zero/Started, preserving other days. Delete habit explicitly warns that ALL its check-ins are removed.
4. **History/insights:** filter by habit, view saved entries/notes and explained weekly totals/rate, add an accurate past check-in (from habit creation through today), correct or delete entries. Duplicate habit/date is rejected; deleting an entry leaves its habit.
5. **Settings:** default target for new habits, Monday/Sunday week start and reduced motion. All restore from SharedPreferences. Device reduced-motion settings are also respected.

Garden stages are derived only from saved completed entries: zero seed, 1–4 sprout, 5–13 growing, 14+ blooming. No second game model, cloud backend, authentication, sync or cloud AI. Empty/loading/error states, retry, explicit confirmations, large touch targets, scrollable portrait/landscape layouts and resizable labels are implemented. Screenshots contain clearly labeled acceptance-test records; the app does not seed demo data on startup.

## Architecture and schema

See [ARCHITECTURE.md](ARCHITECTURE.md), [gateway contract](lib/integration/bloom_gateway.dart), [Het's API handoff](HET_INTEGRATION_HANDOFF.md) and [PR #2 review record](docs/integration/PR2_REVIEW.md).

| Table | Fields/constraints |
| --- | --- |
| habits | id PK, title, category, unit, daily_target positive integer <=100000, weekly_target 1–7, created_at local date, archived |
| check_ins | id PK, habit_id FK, local ISO date, progress 0..target, status started/in_progress/completed, note; UNIQUE(habit_id,date) |

Foreign keys are enabled per connection with ON DELETE CASCADE. SQL constraints/triggers and Dart validation protect bounds/status/dates. Corrections and lifecycle operations are transactional. Version 1 is the first schema; unsupported migrations fail visibly rather than deleting records. The app owns one repository and closes it on disposal. SQLite and settings survive ordinary process termination/restart as detailed in actual device results.

## Gentle Goal Suggestion

Pure local Dart rules; not a trained model. Input is one habit's last 14 inclusive calendar days, requiring at least seven distinct tracked saved dates. Count completed days, divide by two, round half up, clamp 1–7. Eight completed days suggests four/week. Insufficient history abstains. Zero completions yields one with a reliability caveat. Apply only prefills the edit form; only explicit Save persists. Not now/Cancel changes nothing.

[AI_FEATURE.md](AI_FEATURE.md) documents all five case types, baseline, explanation, independent synthetic fixtures and limits. Actual synthetic paired n=8 plus one abstention: helper MAE **1.875**, fixed-three-day baseline **1.625** days/week; baseline performed better on these artificial cases. No real-user accuracy or trained-AI claim.

## Team, evidence and submission

- Rohan: UI/navigation, integration, accessibility, README, demo planning and packaging; `lib/ui`, main, UI/startup/device tests and submission scripts.
- Het: SQLite/repository/models, preferences, helper calculation and data/helper tests; `lib/data`, `lib/helper`, `test/data`, `test/helper`, AI_FEATURE.md.

Both original commit histories are preserved; no fake attribution, empty/padded/backdated commits or invented human reviews. [AI_Usage_Log.md](AI_Usage_Log.md) records actual assistance. The supplied course rubric's 20 meaningful commits/member is not demonstrated by visible history; report the actual counts, not manufactured compliance.

ClickUp reference: https://app.clickup.com/90141780863/v/l/li/901422402099?pr=90149411098 (List link supplied by user). Access failed; actual Board URL and dated captures are unverified. Planned statuses: Backlog -> Ready -> In progress (WIP 1/member) -> Review/test (WIP 2/team) -> Done. [Kanban_Contribution_Evidence.pdf](Kanban_Contribution_Evidence.pdf) is the exact repository-root evidence path and is also included at ZIP root. It contains actual Git/technical trace plus an explicit missing-board-evidence section; it is not complete ClickUp evidence. Real task IDs, acceptance criteria, dated activity/review, four milestone captures and a dated flow sample remain required. Done requires met acceptance criteria and linked actual review/test evidence.

`final_submission/Project_Group03_Bloom/` is the technical submission staging folder; matching ZIP is adjacent. Source archive excludes secrets/caches/build output. See the included report, deck, test log, screenshots, [planned 23-minute speaker split](docs/integration/DEMO_OUTLINE.md) and [individual-upload checklist](docs/integration/SUBMISSION_CHECKLIST.md). The supplied full bank is now used in Bloom_Project1_SelectedQuestions.docx: I1/I2, A1/A2, D1/D2, T1/T2 and R1/R4, with two per category and all required IDs. The Word file contains full source questions only, no answers, and must be uploaded before recording. The separate Q_AND_A_REHEARSAL_GUIDE gives code/evidence prompts.

The user reports verbal instructor approval; no written instructor-approved proposal copy was supplied. The actual course assessment and ClickUp/development/submission excerpts were supplied October 26 and are preserved in [docs/requirements](docs/requirements/README.md). They govern over earlier summaries. See [RUBRIC_EVIDENCE_CROSSWALK.md](RUBRIC_EVIDENCE_CROSSWALK.md) and [DESIGN_ITERATION.pdf](DESIGN_ITERATION.pdf). The actual full question bank is now supplied and the selection is prepared; live answers and course upload are still human actions. The private GitHub repository must be made accessible to the instructor (public or instructor collaborator); instructor access has not been verified. Signatures, actual peer observation/improvement evidence, historic board captures, actual recording/video URL and individual iCollege receipts remain human-only. The assistant does not upload to iCollege.

## Known limitations and license

No cloud backup or export/sync; uninstalling may remove local records. No historical daily-target snapshots: lowering caps history, raising targets can demote older completions, affecting counts/garden/suggestions. One preferences cache assumes one owning isolate. Both tested AVDs use the same Android 17 image; no physical-device/older-OS coverage is claimed. No real peer feedback or course acceptance is claimed. No open-source license has been selected; rights are retained and no open-source grant is implied.

## Future enhancements (not implemented or claimed as bonus)

Potential future work: versioned historical target snapshots, explicit local export/restore with validation, and broader Android/accessibility testing. These are proposals only; no extra runtime/cloud features or bonus points are claimed. The required helper and baseline are base work under the actual rubric.

Fresh October28 host verification: formatter unchanged, analyzer clean,33 host tests pass. Current supplied guidance permits Human?AI Testing; [testing roles and rerun evidence](TESTING_LABELS_AND_RERUN.md) distinguishes student direction from AI execution and manual/peer testing. Exact raw logs are in docs/verification/host_rerun_2026-10-28. The app source/dependencies and tested release APK are unchanged.

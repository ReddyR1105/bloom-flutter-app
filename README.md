# Bloom — integration review

Small steps. Visible growth.

**NOT READY FOR FINAL SUBMISSION.** Rohan's five-screen Flutter UI is implemented and UI tests pass, but Het is still developing SQLite, preferences and the goal helper. No data implementation is currently visible in the repository. Startup deliberately shows a data-integration error through PendingGateway instead of presenting fake saved data. Do not submit this review build as the completed assignment.

Student: Rohan Reddy Gosangi (undergraduate). Partner: Het Jani (pathway not supplied). Group number: pending.
Repository: https://github.com/ReddyR1105/bloom-flutter-app
Deadline: October 27, 2026, 11:59 PM America/New_York.

The user reports verbal instructor approval and explicitly instructed implementation to continue on October 26. Written approval/approved proposal and independent instructor verification were not supplied. See [approval record](docs/integration/APPROVAL_STATUS.md). The actual assignment/rubric/question bank was not supplied; the handoff is the available requirements source and must yield to the actual assignment if it differs.

## Setup and run

```powershell
git clone https://github.com/ReddyR1105/bloom-flutter-app.git
cd bloom-flutter-app
git switch rohan/final-ui-integration
flutter pub get
flutter run
```

The branch must be pushed before clone/switch works on another machine. Existing local checkout: D:\ai-business-engine\bloom-flutter-app. Do not reuse the separate parent repository for Bloom.

Verified toolchain: Flutter 3.47.4 stable, Dart 3.13.3, Android SDK/build-tools 36.0.0; Java 25.0.3 bundled with Android Studio. pubspec.lock records resolved packages. Current direct packages are Flutter SDK and development-only flutter_test/flutter_lints; SQLite/shared_preferences are to be integrated from Het's branch, not falsely listed as installed runtime dependencies.

## Screen flow and usage

Four bottom tabs: Today, Habits, Insights, Settings. New/edit forms and activity routes provide five distinct roles. Following usage assumes Het's real adapter has been connected:

1. Today/Habits → New habit: enter name/category/unit, positive daily target, weekly goal 1–7 → Save.
2. Open habit → Start → adjust temporary progress → Save progress or reach target and Finish. Reset explicitly confirms that today's saved record returns to zero/Started.
3. Habit detail → Edit or Delete; deleting warns that all linked history is removed.
4. Insights → filter history by habit, view explained weekly count/rate, add a past entry, correct or delete a check-in. Unique habit/date and bounds are checked by the UI and must be enforced in the repository.
5. Settings → default target, week start, reduced motion; gateway writes must persist via SharedPreferences.
6. Goal suggestion → explanation → Apply prefills edit form; Cancel/Not now changes no goal. Only Save persists. Insufficient history must abstain.

Garden stages derive exclusively from completed saved entries supplied by the gateway: 0 seed; 1–4 sprout; 5–13 growing; 14+ blooming. No independent game state. Cream/sage/forest styling, static owned vector artwork, scrollable layouts and resizable text follow the supplied designs. No Firebase, online sync, remote login or cloud AI.

## Architecture, data and helper

See [ARCHITECTURE.md](ARCHITECTURE.md) and the [exact integration contract](docs/integration/UI_DATA_INTERFACE.md). Rohan owns UI/navigation/accessibility/integration/docs/packaging. Het owns models/repositories/SQLite/preferences/helper and data/helper tests. No Het-owned file has been edited.

Required SQLite schema (planned persistence, not yet implemented in this branch):

| Table | Fields/constraints |
| --- | --- |
| habits | id PK, title, category, unit, daily_target positive integer, weekly_target 1–7, created_at, archived |
| check_ins | id PK, habit_id FK, local ISO date, progress 0..target, started/in_progress/completed status, optional note; UNIQUE(habit_id,date) |

Enable foreign keys per connection and ON DELETE CASCADE. Check-in deletion leaves the habit. Preserve records/settings across process restart. No historic daily-target snapshot exists in the required schema; final documentation must explain target-edit implications.

Het's offline Gentle Goal Suggestion must use the last 14 local calendar days, require seven distinct tracked dates, count completions/2, round half up and clamp to 1–7 days/week; explain the result and compare with fixed 3 days/week. It is a rule, not a trained model. AI_FEATURE.md and actual evaluation/data tests are pending from Het. The UI only renders his result and never calculates or persists it on Apply.

## Verify and build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
flutter build apk --release
```

Actual results and device limitations: [TEST_LOG.md](TEST_LOG.md). The 10 UI tests use an explicit test double; they do not prove SQLite/helper correctness or restart persistence. Android release output, when built: build/app/outputs/flutter-apk/app-release.apk. Generated release configuration uses the local debug signing key for coursework installation, not production distribution; no key is committed.

## Collaboration and submission

Current branch: rohan/final-ui-integration. Preserve main and Het's branches; use real reviewed PRs. Do not fake reviews, identities, contributions or historic dates. See [contribution workflow](CONTRIBUTING.md), [demo/speaker plan](docs/integration/DEMO_OUTLINE.md), [submission checklist with separate uploads](docs/integration/SUBMISSION_CHECKLIST.md), and [AI usage log](docs/planning/AI_Usage_Log.md).

ClickUp reference: https://app.clickup.com/90141780863/v/l/li/901422402099?pr=90149411098
This is the supplied List reference. Access failed, so the actual Board URL is not verified. Real board screenshots/contribution PDF are absent; do not invent historic states. Expected final evidence PDF: Kanban_Contribution_Evidence.pdf (pending).

final_submission/ is a local review staging folder and is ignored by Git to avoid recursive archives and binary build artifacts. Only finalize it after Het integration, actual tests, real screenshots/signatures/peer evidence, report, instructor question selection, real recording and group identity. The handoff calls for a 20–25 minute demo and at least 20 steady meaningful commits/member; actual instructor rubric remains unavailable. No iCollege upload will be performed by this assistant; each student must upload and retain their own receipt.

No license has been selected; no open-source license grant is implied. Known blocking limitation: PendingGateway is still the startup dependency. This build cannot save habits until the real persisted adapter is merged. Missing human evidence remains explicitly listed in the checklist.

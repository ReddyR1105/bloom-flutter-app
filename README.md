# Bloom

**Small steps. Visible growth.**

Bloom is a proposed offline Flutter habit tracker for Mobile Application Development Project One (undergraduate pathway), with cream surfaces, sage cards, forest-green actions, and a small garden reflecting saved progress.

**Status: planning only; instructor approval pending.** No Flutter application, test results, release APK, or final submission exists yet. Implementation begins only after written instructor approval or explicit authorization to proceed is provided.

Repository: https://github.com/ReddyR1105/bloom-flutter-app

## Review the planning branch

Current checkout: `D:\ai-business-engine\bloom-flutter-app`. The planning and develop branches currently exist locally only; publication is pending approval to upload the included handoff documents. The clone/switch example below applies once the planning branch is pushed.

```powershell
git clone https://github.com/ReddyR1105/bloom-flutter-app.git
cd bloom-flutter-app
git switch planning/project-one-preapproval
```

No Flutter installation is needed to review planning documents. Word/PNG handoff files are draft proposal/design materials, not implementation evidence.

## Planned features

| Screen | Planned behavior |
| --- | --- |
| Today | Daily completion summary, saved-progress garden, habit cards, category filter, create/detail access. |
| Create/Edit Habit | Validated name, category, unit, daily target, weekly target, Save/Cancel. |
| Habit Detail & Activity | Start, update progress, Finish, confirmed Reset, edit/delete habit. |
| History & Insights | Check-in create/read/update/delete, past corrections, habit filter, weekly aggregates. |
| Settings | Persistent default target, week start, reduced motion. |

Four bottom tabs: Today, Habits, Insights, Settings. Forms and detail routes complete the five screen roles. Data and inference stay on-device; no cloud backend or remote authentication.

Planned packages: `sqflite`, `shared_preferences`, and `path` if needed. Versions are not selected or installed. After approval, commit `pubspec.lock` and document actual Flutter/Dart/Android versions.

## Planned database and helper

| Table | Fields and constraints |
| --- | --- |
| habits | id PK, title, category, unit, daily_target positive integer, weekly_target 1–7, created_at, archived. |
| check_ins | id PK, habit_id FK, local ISO date, progress 0..daily_target, status started/in_progress/completed, optional note; unique habit/date. |

Enable SQLite foreign keys; confirmed parent deletion cascades to history. Check-in deletion leaves its habit. Records/settings must survive restart.

Gentle Goal Suggestion is a planned offline rule, not a trained model: require seven distinct tracked dates within the last 14 calendar days; count completions, divide by two, round half up, clamp to 1–7 days/week. Explain the result; Apply prefills a form and explicit Save persists the goal. Compare with a fixed three-days/week baseline using declared synthetic fixtures.

## Planning materials

- [Original handoff](docs/planning/Supplied_Handoff/START_HERE.md), [draft proposal](docs/planning/Supplied_Handoff/docs/Bloom_Flutter_Project_Proposal.docx), [UI designs](docs/planning/Supplied_Handoff/design/).
- [Approval readiness](docs/planning/PROPOSAL_READINESS.md), [late-approval request](docs/planning/APPROVAL_REQUEST.md).
- [Implementation/testing plan](docs/planning/IMPLEMENTATION_PLAN.md), [task breakdown](docs/planning/TASK_PLAN.csv), [verification status](docs/planning/SUBMISSION_VERIFICATION.md).
- [Contribution workflow](CONTRIBUTING.md), [AI usage log](docs/planning/AI_Usage_Log.md).

Deadline stated in the handoff: **October 27, 2026, 11:59 PM Eastern**. October 17 proposal deadline has passed; late acceptance and approval remain unresolved. Original course brief and question bank were not supplied, so requirements have not been independently checked against them.

## Team and evidence

The handoff identifies Rohan Reddy Gosangi as an undergraduate. Group number, complete roster, real roles, collaborator accounts, and ClickUp board URL remain pending. No teammate contributions or reviews are claimed.

ClickUp plan: Backlog → Ready → In progress (one task/member) → Review/test (two tasks/team) → Done. The CSV is a proposed breakdown, not a live board or completed-work evidence. Actual Kanban/contribution PDF and dated screenshots remain pending; no evidence PDF exists yet.

Use genuine feature branches, meaningful commits and real peer-reviewed PRs; do not manufacture contribution counts, identities, timestamps, signatures or results.

## Build and use after approval

These are future commands, not executed tests. They require the application to be implemented first:

```powershell
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
flutter build apk --release
```

Expected future APK: `build/app/outputs/flutter-apk/app-release.apk`. Document actual setup, dependency versions, build/install output, app usage and known issues after execution. Two-device offline/restart/orientation/accessibility checks and real peer feedback are required; none has run.

## Submission and license

Final artifacts include approved proposal, genuine signed statement, report, AI documentation, presentation, actual instructor-question selection, collaboration evidence, real release APK, repository/video links and verification. See the [complete checklist](docs/planning/Supplied_Handoff/agent/BLOOM_FINAL_REQUIREMENTS_CHECKLIST.md). Each member submits individually and preserves their receipt.

No license has been selected; no open-source license grant is implied. Team license decision remains pending.

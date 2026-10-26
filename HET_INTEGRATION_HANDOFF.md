# Het data/helper integration — API contract

Branch: `het/final-data-helper`, based on Rohan UI commit `69d4e01`.
Status: implementation complete; final evidence and integration details are below.
Recorded verbal approval: `docs/integration/APPROVAL_STATUS.md`. Het confirmed undergraduate pathway; authoritative instructor rubric remains unavailable.

## Entry point and models

`lib/data/bloom_repository.dart`: `BloomRepository implements BloomGateway`.
`static Future<BloomRepository> open({String? path, DatabaseFactory? factory, SharedPreferences? preferences, DateTime Function()? clock})`.
Uses the existing immutable DTOs in `lib/integration/bloom_gateway.dart`; no competing model mapping required.
Implements every exact method/parameter/return type in `docs/integration/UI_DATA_INTERFACE.md`.
Additional `Future<HabitView> getHabit(int id)`, `Future<CheckInView> getCheckIn(int id)` and `Future<void> setArchived(int id, bool archived)`.

`lib/data/settings_store.dart`: `SettingsStore(SharedPreferences preferences)`, `SettingsView load()`, `Future<void> save(SettingsView value)`.
`lib/helper/goal_suggestion.dart`: `GoalSuggestion calculateGoal({required HabitView habit, required List<CheckInView> checkIns, required DateTime today})` returns completedDays, trackedDays, windowStart, windowEnd, daysPerWeek (null if insufficient), explanation.

Validation throws ArgumentError; missing records/lifecycle misuse throws StateError; SQLite constraints throw DatabaseException; failed preferences writes throw StateError. No mutation reports success before persistence completes. Missing deletes are errors, close is idempotent, use after close throws StateError. Lists returned by load are unmodifiable.

Rohan can await `BloomRepository.open()` and inject it as `BloomApp(gateway: repository)` with startup error handling. Existing main.dart remains unchanged. UI must confirm deletes/resets; suggestion Apply only prefills the editor and Save calls updateHabit. No direct messages sent to Rohan.

Policies: local DateTime inputs only (UTC rejected), canonical YYYY-MM-DD, no future/pre-creation entries. Seven distinct saved dates in the inclusive 14-calendar-day window are required, NOT seven completed records. Start is idempotent. Finish requires target reached. Corrections may change status provided progress is consistent. Lowered targets cap progress; raised targets demote formerly completed entries below target. No historical target snapshots exist.

## Completed implementation and evidence

Implementation is complete on `het/final-data-helper`. Final implementation commit: `ae7b357d09a20afd5cf561031be9354cee92aeb6`; later commits contain this handoff and recorded evidence only. The final branch tip is the documentation commit titled `docs: record Het validation results and final integration handoff`; resolve its exact SHA with `git rev-parse origin/het/final-data-helper`. A commit cannot embed its own hash; the copy-paste chat handoff supplies the final tip SHA after publication.

### Exact gateway APIs (implemented in lib/data/bloom_repository.dart)

| Signature | Behavior / failures |
|---|---|
| `Future<BloomSnapshot> load()` | Transactional SQLite snapshot, unmodifiable lists, restored settings; corrupt settings throw StateError |
| `Future<void> createHabit(HabitDraft draft)` | Trim strings; positive daily target capped at UI limit 100000; weekly 1–7 |
| `Future<HabitView> getHabit(int id)` | Detail or StateError for missing ID |
| `Future<void> updateHabit(int id, HabitDraft draft)` | Atomic target normalization through SQL trigger; preserves creation date and archive flag |
| `Future<void> setArchived(int id, bool archived)` | Persist archive state; missing ID throws |
| `Future<void> deleteHabit(int id)` | Delete habit and cascade history; caller confirms first |
| `Future<void> createCheckIn(CheckInDraft draft)` | Validate parent/date/progress/status and reject duplicate date |
| `Future<CheckInView> getCheckIn(int id)` | Detail or StateError |
| `Future<void> updateCheckIn(int id, CheckInDraft draft)` | Atomic correction, including reassignment/date/note; failed constraint leaves old row intact |
| `Future<void> deleteCheckIn(int id)` | Delete entry only; parent survives |
| `Future<void> start(int habitId, DateTime day)` | Create zero/started or preserve existing record unchanged |
| `Future<void> updateProgress(int habitId, DateTime day, int progress)` | Requires Start; 0 becomes started, positive becomes in_progress; completed stays completed only at full target |
| `Future<void> finish(int habitId, DateTime day)` | Requires existing record at full daily target; otherwise StateError |
| `Future<void> reset(int habitId, DateTime day)` | Requires existing record, sets 0/started and preserves note; no other day changed |
| `Future<void> saveSettings(SettingsView settings)` | Validated single JSON preferences write; false acknowledgment throws StateError; platform exceptions propagate; failed cache is reloaded |
| `Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today)` | Read-only calculation; null daysPerWeek means insufficient history; baseline 3 |
| `Future<void> close()` | Idempotent; concurrent callers await the same close operation; later access throws StateError |

DTO constructors/fields remain exactly those in `lib/integration/bloom_gateway.dart`. Stored statuses are `started`, `in_progress`, `completed`; category/unit must also be nonempty. Duplicate habit titles are allowed (the draft's “unique-enough” does not define an enforceable uniqueness rule); IDs identify habits. Distinct tracked days are saved records, regardless of completion. Do not reinterpret abstention as a default goal.

### Usage for Rohan

```dart
import 'package:bloom/data/bloom_repository.dart';
import 'package:bloom/integration/bloom_gateway.dart';

// Ensure WidgetsFlutterBinding.ensureInitialized() before opening.
final repository = await BloomRepository.open();
await repository.createHabit(const HabitDraft(
  title: 'Read', category: 'Learning', unit: 'pages',
  dailyTarget: 20, weeklyTarget: 3,
));
final habit = (await repository.load()).habits.last;
final today = DateTime.now(); // local, not DateTime.utc(...)
await repository.start(habit.id, today);
await repository.updateProgress(habit.id, today, 20);
await repository.finish(habit.id, today);
final suggestion = await repository.suggestGoal(habit.id, today);
// Display suggestion; do not automatically save it.
// Inject repository into BloomApp(gateway: repository).
// BloomApp currently owns close() on disposal; do not close before injection.
```

For normal startup just open and inject; the example's create/start/finish calls are illustrative, NOT seed-on-launch code. Catch open errors and offer retry. Database failures must be shown, not converted to empty history. Preserve the existing confirmation dialogs. New dependencies are sqflite, shared_preferences and path; test-only SQLite FFI/platform mock dependencies are committed in pubspec and lockfile.

### Migration/lifecycle

Version 1 is the first actual SQLite schema in this repository; neither inspected branch had existing tables. Default path is platform database directory + `bloom.db`. No destructive reset, seed, file deletion or downgrade migration is performed. Future version upgrades must add explicit migrations; unexpected versions are not silently overwritten. Foreign keys are enabled on every owned connection. Uniqueness and progress/status consistency are enforced in SQL as well as Dart. Each multi-step operation is transactional. Busy/locked transactions retry at most four times (10/20/40/80 ms); persistent contention is surfaced as DatabaseException. Own one repository per app; injected test paths/factories are optional. Settings use one namespaced JSON key `bloom.settings.v1`, defaults 20 / Monday / reducedMotion=false. Assume one app isolate owns the preferences cache; external writers need reload/reconciliation.

Historical target limitation: lowering caps existing progress and preserves completed only when still at target; raising demotes below-target completions. The schema cannot retain old target snapshots. Explain this if editing targets affects past history or suggestions. Archive is a persisted flag; caller/UI decides filtering and whether to allow activity on archived habits.

### Changed files

- `lib/data/bloom_repository.dart`, `lib/data/settings_store.dart`, `lib/data/validation.dart`
- `lib/helper/goal_suggestion.dart`
- `test/data/repository_test.dart`, `test/data/settings_test.dart`, `test/helper/goal_suggestion_test.dart`, `test/fixtures/held_out_goals.json`
- `pubspec.yaml`, `pubspec.lock`
- `AI_FEATURE.md`, `DATA_TEST_LOG.md`, `HET_INTEGRATION_HANDOFF.md`, `docs/data_verification/*`

No edits to Rohan's UI, main.dart, integration boundary, README or packaging. Existing uncommitted changes: none at initial fresh clone. This isolated checkout was created in the initially empty workspace.

### Results and remaining team steps

20 data/helper tests and all 30 combined tests pass. Formatter: 7 files / 0 changes; flutter analyze: no issues. See DATA_TEST_LOG.md for commands, actual outputs, repaired failures and test limitations. Host SQLite reopen is tested; Android process restart/offline/two-device and real preferences persistence are NOT tested. No Android device was connected. Rohan must inject the repository, validate real flows and error handling, test devices, then package/build from the integrated branch. No merge is performed here.

Het confirmed undergraduate pathway on October 26, 2026. The actual instructor rubric was not supplied; cannot determine whether a separate individual reflection/contribution statement is required. The supplied checklist mentions team contribution evidence, authentic commits and individual course upload, but is not the authoritative rubric. Do not fabricate a personal reflection, signature, peer observation, historical participation or graduate work. This technical handoff is a factual code/test contribution record only.

AI assistance disclosure: Codex inspected the remote UI branch and draft proposal, authored this data/preferences/helper implementation and tests, ran the recorded commands, corrected discovered failures, and drafted these documents. Human team review and course-required AI disclosure remain necessary; no human peer review is claimed.

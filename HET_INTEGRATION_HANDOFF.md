# Het data/helper integration — API contract

Branch: `het/final-data-helper`, based on Rohan UI commit `69d4e01`.
Status: implementation in progress; final evidence and commit will be recorded below.
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

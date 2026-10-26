# Rohan / Het integration boundary — October 26, 2026

**Integration update:** Het's exact tip `6459294` is integrated and `BloomRepository.open()` directly implements this gateway. Production startup now opens/injects it; no mapping adapter or pending gateway remains. See PR2_REVIEW.md, HET_INTEGRATION_HANDOFF.md and the current TEST_LOG.md. The inspection and proposed steps below are retained as the original pre-integration contract, not the current availability status.

## Inspection and ownership

Before edits, origin/main contained only README.md and .gitignore (commit 4e5ae0d). Local planning branch contained the handoff and documentation (1825175). No lib/, test/, pubspec.yaml, AGENTS.md, instructor rubric, or data/helper APIs existed. Fetch succeeded; no Het branch or PR was visible. The user confirmed Het is still working. This is not an assessment of work on his machine.

Rohan owns: `lib/main.dart`, `lib/ui/`, `lib/integration/` (UI boundary and mapping adapter only), `test/ui_*`, Android scaffold/build integration, README, architecture/demo/testing documentation, and `final_submission/` packaging. Het owns his SQLite, repositories/models, preferences implementation, helper calculation, data/helper tests, and AI_FEATURE.md. No Het-owned file has been edited.

Actual existing data/helper APIs: **none available in this checkout**. The following is a proposed integration boundary, not a claim about Het's current API. Het may preserve his APIs; map them through one adapter rather than renaming or overwriting his work. No duplicate persistence or helper implementation has been created by Rohan.

## Exact UI contract

Source of truth: `lib/integration/bloom_gateway.dart`. All methods are asynchronous.

| Method | Contract |
| --- | --- |
| `Future<BloomSnapshot> load()` | Return all persisted habits/check-ins and restored settings. Empty lists are valid. Throw on unavailable/corrupt data; never quietly return fake records. |
| `Future<void> createHabit(HabitDraft draft)` | Validate and persist a new habit. |
| `Future<void> updateHabit(int id, HabitDraft draft)` | Validate/edit existing habit; handle lowered daily targets consistently in one transaction. |
| `Future<void> deleteHabit(int id)` | Parent deletion cascades; UI has explicitly confirmed loss of ALL history. |
| `Future<void> start(int habitId, DateTime day)` | Create/resume canonical local-day entry; never create duplicate habit/date. |
| `Future<void> updateProgress(int habitId, DateTime day, int progress)` | Persist 0..target; normalize activity status appropriately; a reduced completed entry cannot remain misleadingly completed. |
| `Future<void> finish(int habitId, DateTime day)` | Require target reached, persist completed status. |
| `Future<void> reset(int habitId, DateTime day)` | Confirmed UI action: set selected day to zero/started, leaving all other dates alone. |
| `Future<void> createCheckIn(CheckInDraft draft)` | Validate local date, progress/status and habit FK; reject duplicate habit/day. |
| `Future<void> updateCheckIn(int id, CheckInDraft draft)` | Correct entry including date/note/status; enforce uniqueness and bounds atomically. |
| `Future<void> deleteCheckIn(int id)` | Delete only this entry; leave habit/other history. |
| `Future<void> saveSettings(SettingsView settings)` | Await SharedPreferences write success; preserve settings across restart. |
| `Future<GoalSuggestionView> suggestGoal(int habitId, DateTime today)` | Het calculates the required last-14-day rule, distinct tracked days, explanations, invalid handling and fixed baseline. Return daysPerWeek=null for abstention. MUST NOT persist a changed goal. |
| `Future<void> close()` | Reliably close database/listeners; app calls on disposal. |

UI DTO fields are explicit in that file. Persisted statuses map `in_progress` ↔ `CheckInStatus.inProgress`; other statuses are started/completed. Dates are local midnight calendar values, not UTC-truncated timestamps. Returned lists should be stable snapshots, not mutable repository buffers.

Mutations throw actionable errors on failure and complete only after persistence. UI guards pending actions, reloads snapshots after successful writes, and preserves editing state after failed saves. Validation is repeated below UI because SQLite invariants must survive competing writers and non-UI callers.

## Adapter integration steps

1. Het pushes a branch/PR and identifies his actual entry point, model constructors, repository lifecycle, preference keys and helper result types.
2. Rohan reviews his diff/tests and maps those exact APIs to BloomGateway in `lib/integration/het_gateway.dart` (not yet created). Resolve conflicts with both implementations preserved; no force-push/reset.
3. Replace `PendingGateway()` injection in main.dart with that real adapter. Do not ship PendingGateway as a functional submission: it deliberately shows an honest unavailable-data error.
4. Run Het's data/helper tests and Rohan's UI tests together, then full analyze/test/build. Run real Android SQLite/offline/restart/cascade checks on actual devices/emulators; widget test doubles do not prove persistence.
5. Update README, architecture, AI_FEATURE.md, actual TEST_LOG, screenshots, source archive, release APK and final ZIP from the integrated commit.

## Summary policies

Today: completed canonical entries for today among active habits. Garden: all saved completed entries, four fixed stages (0 seed; 1–4 sprout; 5–13 growing; 14+ blooming), no independent game state. History rate: selected active habits × elapsed week days on/after each creation date; week start uses saved preference. Historical target changes are limited by the required schema's lack of per-entry target snapshots and must be documented honestly.

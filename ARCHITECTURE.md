# Bloom architecture

Production entry: `BloomBootstrap` in lib/main.dart opens `BloomRepository.open()` exactly once and injects `BloomApp`. Open failures show actionable Retry without deleting/clearing records. An open completing after bootstrap disposal closes its orphaned repository. Once attached, BloomApp owns close(). There is no pending-data stub or production in-memory fallback.

## Boundaries and ownership

- Rohan: lib/main.dart; lib/ui/bloom_app.dart (theme, shell, Today/Habits/History/Settings); editors.dart (validated forms); habit_detail.dart (activity/helper actions); widgets.dart (presentation, local dates, confirmation, garden and reduced-motion routes).
- Shared stable UI contract: lib/integration/bloom_gateway.dart. Immutable DTOs and asynchronous methods; Het implemented the exact contract, requiring no competing mapping adapter.
- Het: lib/data/bloom_repository.dart (SQLite lifecycle/schema/CRUD/activity); settings_store.dart (versioned SharedPreferences JSON); validation.dart (local calendar/input consistency); lib/helper/goal_suggestion.dart (pure explainable rule).
- Tests: data/helper tests use actual host SQLite and platform settings mocks; UI tests use an explicit test double; startup tests cover retry/disposal; integration_test/android_acceptance_test.dart exercises actual Android plugins and UI.
- scripts/verify_android_release.ps1 independently force-stops/relaunches the exact release APK in airplane mode and verifies restored records/settings through Android accessibility XML; real screenshots/logs are captured. Its fixtures are explicitly labeled [TEST].

## State and integrity

The shell reloads immutable SQLite snapshots after successful mutations/routes. Slider/form edits are temporary and explicit Save/Finish writes through the gateway. Suggestion Apply prefills only. Buttons guard pending actions, async continuations check mounted state, reload generations reject stale shell results, and controllers are disposed. Forms scroll, dismiss keyboards on drag, adapt to orientation/text scale, and route fades respect reduced motion.

Habit and check-in CRUD validate at both UI and data layers. SQLite enables FK/cascade, unique habit/date, range/status/date checks and target-normalization triggers. Confirmations explain parent/history deletion and single-day Reset. Failed correction transactions leave old data intact. Start is idempotent; Finish requires target reached; Reset preserves note/other dates. Close is idempotent and later calls fail visibly.

Settings use one namespaced JSON value bloom.settings.v1 to avoid partial combinations; failed writes throw and reload cache. Defaults: target 20 / Monday / reducedMotion=false. This is local single-isolate storage, not a backup system. Unsupported future DB upgrades fail visibly; no destructive migration or automatic seed is performed.

## Date and summary policies

Dates are local calendar components normalized to YYYY-MM-DD. UTC helper dates are rejected; calendar arithmetic crosses DST safely. One check-in per habit/date is canonical. Today counts active habits with completed saved entries. History rate uses one opportunity per selected active habit per elapsed week day starting at its creation date; archive affects filtering. Garden uses completed saved records only: 0/1–4/5–13/14+ stages. No separate game state.

Helper: at least 7 distinct tracked dates in the last 14 inclusive days; completed/2 rounded half up then clamped1–7; no history produces abstention. It performs no writes. AI_FEATURE.md documents the fixed 3 baseline, five cases, synthetic evaluation and limitations.

## Build/accessibility/known limits

Release uses normal Android plugins and requests no app network capability in the main manifest. Local debug signing is used for coursework install; key/local.properties/build caches are excluded. Windows Kotlin incremental cache failed across C:/D: roots; in-process nonincremental compilation resolves that environment failure without changing data logic.

Static plant/vector artwork is owned source. Core forest/cream contrast computes 6.98:1; charcoal/sage 10.10:1 (color-pair calculations, not a claim of full accessibility certification). Widget tests cover 2x text portrait/landscape; actual release screenshots/logs document tested emulator states. Screen-reader usability/physical-device coverage is not claimed.

The required schema has no historical target snapshots. Target changes normalize old progress/status and can change history/helper output; no old target can be reconstructed. There is no cloud recovery, reminder service, or external AI. Actual instructor rubric/delivery excerpts are preserved in docs/requirements and mapped in RUBRIC_EVIDENCE_CROSSWALK.md. Human signatures, actual recorded question responses, genuine board/peer evidence and recording remain outside software verification.

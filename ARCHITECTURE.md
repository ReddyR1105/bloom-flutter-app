# Bloom architecture — integration review

Status October 26, 2026: Rohan's UI is implemented against a typed asynchronous gateway. Het's persistence/helper implementation is still in progress and is not present on origin/main or another fetched branch. This is not yet a functional persisted habit tracker.

## Implemented boundaries

- `lib/main.dart`: Flutter entry point; currently injects PendingGateway, which reports missing integration rather than silently inventing data.
- `lib/integration/bloom_gateway.dart`: Rohan-owned immutable UI DTOs and explicit asynchronous adapter contract, with no database or helper calculations.
- `lib/integration/pending_gateway.dart`: explicit integration error; must be replaced in startup before final acceptance.
- `lib/ui/bloom_app.dart`: theme, navigation, refreshed snapshot, Today/Habits/History/Settings UI, category/habit filters and labeled summary calculations.
- `lib/ui/editors.dart`: validated habit/check-in forms; confirmation, Save/Cancel, no writes on suggestion Apply alone.
- `lib/ui/habit_detail.dart`: selected-day Start/update/Finish/Reset orchestration, helper explanation and edit/deletion routes.
- `lib/ui/widgets.dart`: reusable presentation cards, local-date utilities, error/confirmation UI, saved-completion garden custom painter.
- `test/ui_flows_test.dart`: UI-only test double and behavior/layout tests. This does not test SQLite, actual preferences, or Het's helper calculation.

See `docs/integration/UI_DATA_INTERFACE.md` for exact required methods, ownership, persistence invariants, local-calendar semantics and integration steps. No Het-owned implementation has been written or modified by this agent.

## State and integrity

The shell loads immutable snapshots and refreshes after mutations/routes. Edit controllers and progress sliders are temporary drafts; no slider movement or suggestion Apply saves by itself. Explicit Save/Finish invokes the gateway. Destructive actions confirm scope. Buttons disable during writes; async continuations guard mounted state; reload generations prevent stale shell results. Controllers are disposed and the app closes its gateway on disposal.

UI validates names, target ranges, check-in bounds, duplicate habit/date in the current snapshot, valid local dates, and completed-state consistency. Het's repositories must independently enforce these invariants with SQLite constraints/transactions to handle stale snapshots/concurrent writes. Progress updates and Finish are separate calls; gateway Finish must validate persisted progress and surface errors. The UI never assumes a failed write succeeded.

The required schema is documented in README and the handoff. Foreign keys, cascade, migrations, storage closure, SharedPreferences behavior and exact helper results remain to be verified in Het's code. There is currently no on-device storage implementation in this branch.

## Visuals and accessibility

Cream/sage/forest palette, generous padding, scrollable max-width content, semantic progress labels, minimum button targets, resizable text, and static owned vector plant artwork. The garden has four stages driven only by completed records received from the gateway. Portrait and landscape at 2× text scale are tested in widget tests; real Android/device screen-reader/contrast checks remain pending.

## Release limitations

The generated Android scaffold signs release-mode builds with the local debug key for coursework installation. This is not a production signing setup; no key is committed. No INTERNET permission is requested in the release manifest. The application currently opens an explicit data-integration error until Het's adapter is connected. A compilable APK is not evidence of a completed assignment.

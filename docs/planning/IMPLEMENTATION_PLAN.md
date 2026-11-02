# Bloom implementation and verification plan — gated

This document is a plan, not implemented behavior or test evidence. Start implementation only after written instructor approval or explicit authorization to proceed.

## Fixed scope and design

Use Flutter/Dart, sqflite, shared_preferences, and path if needed. Keep all app data and inference offline. Use a small repository/model/screen/widget/settings/helper structure; avoid extra framework dependencies unless necessary and justified.

Follow supplied cream/white surfaces, muted sage cards, forest-green actions, charcoal labels, soft borders, rounded cards, generous spacing, small botanical growth graphics, and limited icons. Plant stages derive from actual saved completion data; mockup sample counts never become claimed user data. Use owned bundled assets or programmatic shapes. Four tabs: Today, Habits, Insights, Settings; form and detail routes provide the five required screen roles. Theme selection appears in the concept image but is not required by the proposal; prioritize required settings and accessibility. No racing motif or unrelated features.

| Screen role | Planned acceptance |
| --- | --- |
| Today | Real daily count, garden state, scrollable habit cards, category filter, detail/create access; clear empty/error states. |
| Create/Edit | Name, category, unit, positive integer daily target, weekly target 1–7; stepper/slider where suitable; actionable validation; Save/Cancel. |
| Habit Detail / Activity | Persisted Start/resume, progress, Finish, confirmed Reset, edit/delete, today's record and explicit lifecycle state. |
| History & Insights | Full check-in CRUD including past correction, habit filter, weekly completed count and explained completion rate. |
| Settings | Default target, week start, reduced motion restored from SharedPreferences. |

Support portrait/landscape, scrollable forms, resizable text, meaningful semantics, large touch targets, sufficient contrast, and reduced motion. A reusable StatelessWidget will present habit cards; StatefulWidgets handle forms/activity and dispose controllers/listeners. Only introduce timers if required.

## Data integrity decisions to implement and verify

- `habits`: id PK, title, category, unit, daily_target positive integer, weekly_target 1–7, created_at, archived. Trim text and reject empty values; document title-duplicate policy without silently broadening the schema.
- `check_ins`: id PK, habit_id FK, local ISO date, progress 0..daily_target, status started/in_progress/completed, optional note. UNIQUE(habit_id,date), foreign_keys ON per connection, ON DELETE CASCADE. Centralize validation, transactions, versioned migration, and reliable closure.
- Start creates/resumes one saved daily record. Persist progress updates. Finish requires target reached; completed means the target was met. Reset confirms that the selected day's record returns to zero/started, preserving other days. Deleting a check-in leaves its habit; deleting a habit warns explicitly that all its history will be removed.
- Lowering a daily target must handle existing progress consistently in a transaction (planned: cap stored progress; preserve completed status for previously completed records and explain historical target limitations). Document that the required schema has no historical target snapshot; avoid implying retrospective data is a precise record of prior targets.
- A planned completion-rate denominator is active habits multiplied by elapsed local days in the displayed week, counting a habit only from its creation date. Label the period and policy. Weekly targets are goals, not an unrecorded weekday schedule.
- Start with an empty database. If demo data is added, make it explicitly optional/labeled and idempotent. Never use it as genuine user or device-test evidence.

## Gentle Goal Suggestion

Keep a pure Dart module separate from UI/DB. Use a local-date inclusive window from today minus 13 days through today. Require at least seven distinct valid tracked dates in that window; habit age alone is insufficient. Reject malformed dates, duplicates, invalid statuses/progress and wrong-habit data rather than silently manufacturing history. Future/out-of-window records do not contribute.

Count completed dates, divide by two, round half upward for nonnegative counts, clamp to 1–7. Eight completions yields four days/week. Zero completions with seven tracked dates yields one day/week with an explicit reliability caveat. Otherwise show 'Not enough history yet'. Explain the count and window. Apply pre-fills the weekly-goal edit form; only explicit Save persists it. Not now changes nothing. Compare with fixed three days/week.

Plan independent synthetic fixtures before evaluation with declared following-week truth labels; include normal, missing, invalid, boundary/tie/outlier, and counterexample cases. Compute MAE only for eligible numeric paired predictions; disclose abstentions, sample size, artificial labels and limitations. Do not invent results or imply trained-model accuracy. Explain all of this in AI_FEATURE.md after actual execution.

## Sequence after approval

1. Record approval conditions, establish a new repository and real collaborators, and use reviewed feature branches with authentic attribution. Never manufacture 20 commits per person; human contributions and reviews must be real.
2. Run flutter doctor -v; record actual tools/versions and resolve setup failures. Initialize Flutter project, lock packages, and add one tested SQLite create/read/restart slice with navigation.
3. Complete both entity CRUD flows, lifecycle, settings, helper, insights, responsiveness and accessibility.
4. Run formatting, flutter analyze, flutter test, and relevant integration tests. Repair real failures and save exact command outputs. No result is assumed by this plan.
5. Run flutter build apk --release; verify actual APK exists, install it and launch it. Record build/install output, APK hash and signing configuration accurately. Do not claim production signing if using default debug signing.
6. Execute actual two-device/emulator checks: CRUD/correction/duplicate rejection, cascade confirmation, Reset cancel/confirm, airplane mode, termination/restart for data/settings, orientation, text scaling, bright/dark readability, reduced motion, empty/error cases. Record device/OS/build identity and actual outcomes; unavailable checks remain pending.
7. Get a real peer observation, implement one justified improvement, and preserve real before/after evidence. Save actual Oct 20/23/27 board snapshots when those dates arrive; disclose missing Oct 17 evidence.
8. Complete documentation and genuine artifact packaging, then verify the exact final contents against the master checklist. Assemble the final ZIP only with explicit unresolved evidence clearly identified; never label a partial package complete.

## Planned final output (after requirements are met)

`Project_Group[actual number]_Bloom.zip` containing the matching folder and: README.md, ARCHITECTURE.md, Approved_Proposal.docx, PROJECT_REPORT.pdf, SIGNED_STATEMENT.pdf, AI_FEATURE.md, AI_Usage_Log.md, Project1_Presentation.pptx, TeamName_Project1_SelectedQuestions.docx, Kanban_Contribution_Evidence.pdf, actual app-release.apk, GitHub_Repository_Link.txt, YouTube_Video_Link.txt, and SUBMISSION_VERIFICATION.md. Source/tests belong in the new repository. Individual students upload to iCollege and verify real receipts.

Calendar milestones are conditional on approval: Oct 20 vertical slice; Oct 23 core complete; Oct 24–25 devices/peer/evaluation; Oct 26–27 documentation/video/package. If approval timing makes them infeasible, revise honestly and contact the instructor; never backdate work.

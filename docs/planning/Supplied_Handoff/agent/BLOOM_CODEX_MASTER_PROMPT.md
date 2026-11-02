# BLOOM — VS Code Codex master instruction

You are my coding agent in VS Code. I am Rohan Reddy Gosangi, an **undergraduate** student working on Georgia State University Mobile Application Development Project One (Fall 2026). The chosen app is **Bloom — Small steps. Visible growth.**, a polished, minimal, offline Flutter habit tracker. The project final deadline shown in the course brief is **October 27, 2026, 11:59 PM ET**.

## Read first: hard approval gate

My instructor requires approval of the Word project proposal **before any Flutter implementation**. The proposal deadline was October 17 and has passed. **Do not create Flutter source files, build an APK, commit implementation, or otherwise start coding until I show you written instructor-team approval for Bloom or the professor explicitly authorizes us to proceed.** If approval is not evidenced, work only on planning, reviewing the existing proposal, preparing a *new* GitHub repo and ClickUp task plan, and identifying the missing evidence. Stop and give me the exact short approval/late-submission request I should send. Do not falsely claim approval. Once approval is shown, follow the implementation and packaging instructions below without needing further project-design decisions.

## Ground truth / material in this ZIP

Read these files instead of replacing their approved scope:
- `docs/Bloom_Flutter_Project_Proposal.docx` — project pitch, screens, schema, helper, and schedule.
- `docs/Bloom_Team_Signature_Sheet.docx` — blank signing form; human signatures needed.
- `design/Bloom_Five_Screen_Wireframes.png` — reference for five actual screens.
- `design/Bloom_Home_UI.png` — main visual direction only, NOT a implemented screenshot.
- `agent/BLOOM_FINAL_REQUIREMENTS_CHECKLIST.md` — proof-driven acceptance checklist.

If a document cannot be read directly by your environment, ask me to open or export it rather than silently guess. Do not change the app to a different concept. Our priority is a **simple but premium-looking, reliable app**, not maximal complexity. Keep the course scope fixed, implement the full undergraduate core, then consider only small polish changes.

## Concept & aesthetic

BLOOM helps students create habits, check in daily, correct past entries, and see their consistency reflected in a small digital plant. No social account, friends, subscription, cloud login, reminders requiring cloud services, or large gamification system.

Design requirements:
- Warm off-white/cream background, muted sage/forest green accents, charcoal text, soft borders, rounded cards, generous spacing, limited icons.
- Main visual: an elegant small plant/garden that changes based on **real saved progress** (for example 4 static stages, no second game model). Use programmatic Flutter widgets/vector shapes or bundled project-owned assets, not hotlinked images. Make the app look consistent in portrait and landscape.
- Simple bottom navigation; calm animation only when useful; support reduced motion, adequate contrast, readable/resizable labels, large touch targets.
- No unrelated F1/racing motif; this is BLOOM, not CLUTCH.

## Five distinct screen roles (required)

1. **Today / Dashboard:** greeting, today summary, completed count, small growth visual, scrollable habit cards, actions to open check-in and create habit.
2. **Create/Edit Habit:** validated name, category, measurement unit, daily target and weekly target (1–7 days), appropriate slider or stepper, Save/Cancel, helpful errors.
3. **Habit Detail & Activity:** full habit summary, Start, progress update via slider/stepper, Finish, Reset with confirmation; edit/delete habit and view today's check-in; clearly show activity states.
4. **History & Insights:** saved check-in list/calendar, filter by habit, aggregation (for example completed check-ins/week and completion rate), full create/read/update/delete for check-in corrections, empty states.
5. **Settings:** default habit target, preferred start of week, reduced motion; SharedPreferences save and restore.

Create/Edit may be a single screen in add/edit modes. Login or splash does NOT count as one of the five.

## Local data and integrity

Only Flutter/Dart plus SQLite (`sqflite`) and SharedPreferences (`shared_preferences`); `path` is fine. No Firebase, server, API requests, cloud AI, cloud database, remote auth, live feeds, or online features in the app. GitHub/ClickUp/YouTube may be used as development/submission tools only.

Use two related SQLite tables, fully CRUD-capable **individually**:
- `habits`: id PK, title, category, unit, daily_target positive integer, weekly_target integer 1..7, created_at, archived.
- `check_ins`: id PK, habit_id FK, date (local ISO date), progress nonnegative, status in started/in_progress/completed, note. Unique `(habit_id,date)` for canonical daily check-in; use an update/correction rather than inserting duplicates.

Enable `PRAGMA foreign_keys=ON`; use `ON DELETE CASCADE` for child check-ins when a habit is deleted **after explicit confirmation that its history will be removed**. Deleting a check-in must not delete the habit. Reject malformed or out-of-range inputs and show actionable errors; cap progress to the habit's daily target. Make DB setup, migrations, and database closure reliable. All saved records survive termination and app restart. Support an empty database and small explicitly labeled seed/demo data without duplicating it on restart.

Activity lifecycle: Start -> update progress -> Finish or Reset. Reset only acts after confirmation, and its effect on saved records is explained in UI. Distinguish temporary UI state from persisted SQLite state. Use at least one reusable StatelessWidget for presentation, one StatefulWidget for activity/form, and properly dispose every controller/timer/listener. Use lists/grids, navigation, buttons, dialogs, and appropriate gestures. Keep the architecture modest: models, a centralized DB/repository layer, screens, widgets, a pure Dart smart-helper module, and settings.

## Mandatory smart helper — Gentle Goal Suggestion

Use a **transparent local rules-based helper**, not a trained or generative AI model. Input: user's habit and its last 14 calendar days of real check-ins. Require at least 7 distinct tracked calendar days for the habit before recommending; otherwise say **Not enough history yet**. Count completed days within that 14-day window, divide by two, round to the nearest whole day using a documented convention, clamp result to 1..7 days/week. Example: 8 completed days/14 -> recommended goal 4 days/week. Explain: "You completed 8 of the last 14 days; try 4 days/week." If a zero-completion example meets the 7-tracked-day rule, rule returns minimum 1 day/week and acknowledges that the estimate may be unreliable. Never claim this is a trained ML model or give fake confidence scores. Show **Apply / Not now**; Apply pre-fills a form but the user must explicitly Save before changing a goal. Add a simple **fixed 3-days/week baseline**. Keep the recommendation logic as pure/testable Dart separate from UI and DB.

Evaluate and document in `AI_FEATURE.md`: input contract, method, baseline, worked example, metric, 5 required case types (normal; missing data; invalid; boundary/tie/outlier; counterexample), synthetic fixture truth labels and MAE comparison if meaningful, explanation, override, limitations, and that all inference is offline. Never invent real peer testing or evidence. Make tests reproducible. Evaluate on independent examples not used to tune rules, and don't overstate results.

## Development & collaboration rules

- Undergrad shared core only (do not add graduate-only mandatory extensions unless specifically needed); optional bonuses only after full core.
- Create a **brand-new GitHub repository for Project One**. Don't reuse prior coursework repos. Add actual team members as collaborators when I provide accounts. Commit `pubspec.lock`, not generated build folders or secrets.
- Use feature branches, focused reviewed PRs, and meaningful commit messages. **Each human student must contribute authentically and have at least 20 steady, meaningful commits across the project**; never manufacture empty commits, fake author identities, PRs, peer reviews, or earlier timestamps. You can make honest commits for my actual changes, but teammates must contribute for themselves.
- Use the team's real ClickUp Free plan board with columns Backlog -> Ready -> In progress (WIP 1/member) -> Review/test (WIP 2/team) -> Done. Tasks need owner, due date, acceptance criteria, links to actual code/test/review. Preserve real dated board screenshots; never fabricate or backdate October 17, 20, 23, 27 evidence.
- Ensure documented architecture decisions in `ARCHITECTURE.md`, realistic data handling and disposal, readable code, helpful comments, organized files. Do not add unrelated features.

## Verify the build, don't guess

On a machine with Flutter/Android SDK configured and **only after approval**:
1. Check `flutter doctor -v` and log actual versions.
2. Initialize the project and organize `/lib`, `/test`, `/assets` as appropriate.
3. Add screen navigation and a single tested SQLite vertical slice before adding breadth.
4. Implement both tables' CRUD, check-in flow, settings, local helper, empty/error states, UI and responsiveness.
5. Run `dart format`, `flutter analyze`, `flutter test`; fix failures; capture exact commands and results.
6. Build actual Android release APK with `flutter build apk --release`; verify `build/app/outputs/flutter-apk/app-release.apk` exists and can be installed. Don't provide a placeholder APK.
7. Test airplane-mode/offline, restart persistence, delete cascade/confirmation, dark/bright accessibility, portrait/landscape, two **real** Android devices/emulators. If hardware isn't available, explicitly list tests pending rather than claim success.
8. Get one real peer usability observation and implement a documented before/after improvement. Don't invent peers or outcomes.

## Final deliverables — assemble `Project_Group[NUMBER]_Bloom.zip`

Once approval, implementation and legitimate team/human evidence are complete, create a ready-to-review folder and ZIP containing:

```
Project_Group[NUMBER]_Bloom/
  README.md
  ARCHITECTURE.md
  Approved_Proposal.docx
  PROJECT_REPORT.pdf
  SIGNED_STATEMENT.pdf                # real signatures, no fake signatures
  AI_FEATURE.md
  AI_Usage_Log.md                    # because AI coding assistance was used
  Project1_Presentation.pptx
  TeamName_Project1_SelectedQuestions.docx
  Kanban_Contribution_Evidence.pdf
  app-release.apk                    # actual locally built release APK
  GitHub_Repository_Link.txt
  YouTube_Video_Link.txt
  SUBMISSION_VERIFICATION.md
```

Source and tests must also be available in the new GitHub repository. README must include complete setup/build instructions, team roles, screens/features, packages/versions, DB schema, usage instructions, known issues, repository link, board URL, evidence PDF path, license, and no unsupported claims. The report must reflect real implemented features and actual issues/results. `AI_Usage_Log.md` must document AI assistance truthfully.

Select 10–15 curated Q&A **from the professor's actual question bank**, at least two from each required category, including I1, I2, D1, D2 and R4. If the question bank is not present, request it; do not invent questions. Prepare the **questions-only Word selection**; the recorded 20–25 minute team video includes real members demonstrating actual app CRUD, offline persistence, code, ClickUp task -> commit -> tests, and spoken answers to these questions. Codex may draft a real presentation deck, speaker notes and script; it cannot truthfully record team participation, provide human signatures, or supply video links without real uploads.

Each team member must upload their own final package to the iCollege dropbox and verify the submission receipt. Never claim submission or instructor approval without proof.

## Operating procedure / response format

- Start by inspecting these supplied materials and current workspace; identify approval status explicitly.
- If approval not evidenced: produce an *approval-ready proposal submission checklist*, true remaining placeholders, planned repo/ClickUp tasks, and a short draft email requesting late acceptance and approval. STOP BEFORE CODE.
- If approved: perform the entire technical build in the current workspace, test and package everything you can, progressively; don't repeatedly ask me for small decisions. Use sensible simple defaults consistent with the proposal. Ask only for truly human-required inputs (team members, real board and repo URL, signature, peer feedback, actual recordings, professor question bank, and instructor approval).
- End with a clear `PASS / FAIL / PENDING HUMAN INPUT` checklist, exact file paths, actual test/build output, and precise items needed for true final submission. Do not use fake evidence, copy placeholders into final documents as if they were real, or assert grading results.

# Bloom final presentation script

Rohan Reddy Gosangi and Het Jani
Georgia State University - Mobile Application Development Project One - UG-P03

Prepared spoken script for a future recording, not evidence of already recorded student participation. Both students review and explain the implementation and provide the real board/review trace.

## 00:00 to 00:30 Bloom: purpose and real implementation

Speaker: Rohan Reddy Gosangi. Questions: R1.

Hello, I am Rohan Reddy Gosangi, presenting Bloom with Het Jani for Mobile Application Development Project One at Georgia State University. Bloom is an offline habit tracker with a small garden reward. This walkthrough shows the actual application beside its saved source code. We will explain the interface, local storage, helper calculation, verification and our recorded workstreams.

## 00:30 to 01:00 What each workstream delivered

Speaker: Het Jani. Questions: R1, A1.

I am Het Jani. Rohan's assigned workstream covers the interface, navigation, integration, accessibility and submission materials. My assigned workstream covers SQLite, repository validation, preferences and the local helper. The repository preserves both workstreams and their original commits. Our development-assistance record remains separate from the team identity. During this presentation, each of us explains the implementation and the evidence relevant to our workstream.

## 01:00 to 01:40 Open once, inject the real repository

Speaker: Rohan Reddy Gosangi. Questions: A1, T2.

The entry point starts Flutter and opens Bloom's local repository. The bootstrap owns the opening state, so it does not reopen the database on every rebuild. When opening succeeds, it injects the repository into BloomApp through the gateway. When opening fails, the user sees an explanation and a Retry action. The mounted check also closes an opening result that arrives after disposal. These paths have dedicated startup tests.

## 01:40 to 02:20 A typed boundary for integration

Speaker: Rohan Reddy Gosangi. Questions: A1, A2.

BloomGateway is the boundary between the widgets and the data implementation. It defines operations for loading a snapshot, changing habits and check-ins, saving settings and requesting a suggestion. The UI constructs drafts and awaits these operations. Het's BloomRepository implements the same contract and reuses the existing immutable view objects. This separation lets interface tests use controlled gateways while production uses actual SQLite and preferences. It also made integration possible without rewriting the persistence APIs.

## 02:20 to 03:00 Theme, navigation and screen roles

Speaker: Rohan Reddy Gosangi. Questions: I1.

The interface uses cream backgrounds with sage and forest-green accents. Four main destinations lead to Today, Habits, Insights and Settings. Routed forms and the activity detail provide the remaining screen roles. This keeps navigation small while still separating the user's main tasks. Stateless display widgets receive saved values. Stateful screens own temporary interaction state, such as the selected destination or a form draft. Back navigation returns to the previous screen and refreshes saved data when needed.

## 03:00 to 03:40 State and loading/error recovery

Speaker: Rohan Reddy Gosangi. Questions: I2, T2.

Loading a snapshot is asynchronous. Bloom shows a loading state, then either the saved content or an actionable error. It does not turn a failed database read into a misleading empty history. The reload code uses a generation value so an older response cannot replace a newer request. After successful changes, the screen reloads the snapshot rather than guessing the database result. This is the connection between an operation, the state update and the next rendered view.

## 03:40 to 04:20 Garden reward comes from saved completions

Speaker: Rohan Reddy Gosangi. Questions: I1, I2.

The garden is a derived display. It counts saved completed check-ins and selects one of four stages: Seed, Sprout, Growing or Blooming. There is no separate garden database that could disagree with the saved habit history. Corrections and deletions can therefore change the reward consistently. The display also exposes a semantic description of the stage and completion count. The records visible in this recording are labeled test or demonstration fixtures, rather than someone's personal habit history.

## 04:20 to 05:00 Create form: controllers and draft state

Speaker: Rohan Reddy Gosangi. Questions: I1, I2.

The habit editor owns controllers for the name, category, measurement unit and daily target. A new form takes its default daily target from saved settings. An edit starts from the existing habit. The weekly target remains temporary form state until Save. Here the actual release application is receiving clearly labeled demonstration inputs. The form supports a simple measurable goal without requiring an account or network connection. Its controllers are disposed when the editor leaves the widget tree.

## 05:00 to 05:40 Validation before writing

Speaker: Rohan Reddy Gosangi. Questions: I2, D1.

This capture shows an empty name being rejected before a record is written. The form also checks that the daily target is a whole number within the allowed bounds. The weekly target stays between one and seven days. These controls give immediate feedback, but they are not the only validation layer. The repository validates drafts again and SQLite enforces important constraints. That matters because data integrity should survive callers other than this particular form.

## 05:40 to 06:20 Explicit Save commits the form

Speaker: Rohan Reddy Gosangi. Questions: I2, A1.

Save first validates the form and prevents another save while the operation is pending. It builds a HabitDraft from the current inputs, then calls createHabit for a new habit or updateHabit for an existing one. The editor returns only after the write succeeds. If the operation fails, the entered draft remains available and the screen shows an error. Cancel leaves the saved record unchanged. The same explicit-save rule applies when a helper suggestion prefills a goal.

## 06:20 to 07:00 Activity progress: draft versus saved

Speaker: Rohan Reddy Gosangi. Questions: I2.

The activity screen separates draft progress from saved progress. Moving the control changes the draft that the screen displays. Save progress sends that value through the gateway and reloads the stored entry. In this recorded example, progress moves to five of ten pages and is saved before continuing. Reaching a draft value by itself does not mean the completion has been persisted. The interface also disables conflicting actions while a write is in progress.

## 07:00 to 07:40 Start is idempotent for a local date

Speaker: Het Jani. Questions: D1.

Start operates on one habit and one local calendar date. Inside a transaction, it validates the habit and date, then looks for the canonical check-in for that pair. It inserts a zero-progress Started entry only when no entry already exists. Otherwise, the saved record remains unchanged, which gives us resume behavior. This is important for repeated taps or returning to the activity screen. A unique database constraint provides an additional guarantee against duplicate habit-and-date records.

## 07:40 to 08:20 Bounds and status remain consistent

Speaker: Het Jani. Questions: D1, D2.

Progress changes also pass through a transaction. The repository loads the habit and existing entry, computes the next value and validates it against the target. Finish requires the saved progress to reach that target. Status remains consistent with the amount of progress, including when a previously completed entry is reduced. These rules live below the UI, so a caller cannot create an invalid state by bypassing a slider. The data tests exercise valid transitions and rejected values.

## 08:20 to 09:00 Finish and confirmed Reset

Speaker: Rohan Reddy Gosangi. Questions: I2, D1.

Finish marks an eligible saved entry completed. Reset has a different scope: it returns the selected day's entry to zero and Started while preserving other dates. The interface explains that scope and asks for confirmation before calling the repository. In this particular captured interaction, the Reset dialog is canceled, so the completed entry remains intact. The actual reset behavior is covered separately by the recorded automated tests. A confirmation appearing on screen is not itself proof that the destructive action occurred.

## 09:00 to 09:40 Delete scope and confirmation

Speaker: Rohan Reddy Gosangi. Questions: D1, T2.

Deleting a habit removes the parent and its saved check-ins, so the confirmation explicitly describes the loss of all history for that habit. Deleting one check-in has a narrower scope and keeps the habit. The repository and database enforce those different outcomes. This recording opens the habit deletion dialog and cancels it. That demonstrates the warning and user control without claiming a deletion took place. Successful delete and cascade behavior is established in the data and interface tests.

## 09:40 to 10:20 Two related SQLite entities

Speaker: Het Jani. Questions: D1, A2.

SQLite stores two related entities. Habits contain the title, category, unit, targets and creation information. Check-ins contain the habit reference, local date, progress, status and note. A habit can have many check-ins. The foreign key is enabled when the database opens, and deleting the parent cascades to its children. The schema also makes the habit-and-date pair unique. These are persisted records on the device, rather than values that disappear when a widget rebuilds.

## 10:20 to 11:00 Constraints protect every writer

Speaker: Het Jani. Questions: D1, T1.

The schema contains checks and triggers in addition to Dart validation. They help reject invalid progress and status combinations and preserve consistent target-change behavior. Updating a daily target can normalize saved progress and completion status. A limitation is that Bloom does not store a separate historical target snapshot for every day. Changing today's target can therefore affect how older entries are interpreted. The documentation states this policy, and the tests check the implemented normalization instead of assuming a different historical model.

## 11:00 to 11:40 CRUD remains in the repository

Speaker: Het Jani. Questions: D1.

Habit CRUD stays in the repository. Creation validates and stores a draft. Reads return saved records through a snapshot or a specific lookup. Updates validate changes and keep the target-normalization work atomic. Deletion removes the habit and lets the enabled foreign key cascade its check-ins. Queries use arguments rather than building SQL from user-entered values. Missing records produce explicit errors. This keeps storage behavior consistent across the creation form, edit form, dashboard and activity screen.

## 11:40 to 12:20 Correct a saved check-in

Speaker: Het Jani. Questions: D2, I2.

Check-ins have their own create, read, update and delete paths. A correction can change the date, progress, status or note, subject to the same validation rules. A duplicate date or inconsistent progress must fail without partially replacing the original row. Deleting a child record keeps its parent habit. The sidebar here shows actual saved history; the code and tests provide the correction evidence. We distinguish that evidence from claiming that every CRUD operation is being performed live in this short view.

## 12:20 to 13:00 Filters and an honest summary denominator

Speaker: Rohan Reddy Gosangi. Questions: D2.

Insights can filter saved entries by habit and sorts the history by date. The weekly completion rate has an explicit denominator. It counts one opportunity for each active habit on each eligible elapsed day, starting at that habit's creation date. Archived habits are excluded from this summary. The numerator counts completed entries in the same period. This prevents presenting a percentage without explaining what it measures. The garden's completion total and this weekly rate answer different questions.

## 13:00 to 13:40 Settings call persistence

Speaker: Rohan Reddy Gosangi. Questions: I2, D2.

Settings exposes the default daily target, the start of the week and reduced motion. A change creates a SettingsView and awaits the gateway's save operation before reloading the visible values. A new habit then uses the persisted default target. Week start affects the summary period, and reduced motion influences presentation behavior. The actual values on screen come from the application. Saved preference restoration after process restart is supported by the retained release checks, not just by a switch changing visually.

## 13:40 to 14:20 Preferences: validate and await the write

Speaker: Het Jani. Questions: A1, D2.

SettingsStore validates the values and saves a versioned JSON value in SharedPreferences. Awaiting the platform result matters because a visible cache update does not always prove a successful write. If saving fails, the code reloads the preference cache before rethrowing the error. Loading also rejects corrupt values instead of silently treating them as valid settings. The preference tests cover these paths. SQLite owns habits and check-ins, while SharedPreferences owns the small settings record, so their responsibilities remain separate.

## 14:20 to 15:00 Helper inputs and calendar window

Speaker: Het Jani. Questions: R4.

The helper takes one habit, its saved check-ins and a local reference date. It builds an inclusive fourteen-calendar-day window using date components, which avoids assuming every day is exactly twenty-four hours around daylight-saving changes. Eligibility requires at least seven distinct tracked dates in that window. Tracked does not mean completed: started and in-progress entries count toward eligibility. The actual sidebar has insufficient history and correctly explains why no suggestion is available. It does not invent missing records.

## 15:00 to 15:40 The explainable offline calculation

Speaker: Het Jani. Questions: R4.

For eligible history, the helper counts completed days, divides by two, rounds half values upward and clamps the result between one and seven days per week. Eight completed days therefore produces four days per week. This is an explainable local rule, not a trained machine-learning model. The output includes the window and an explanation. Invalid or inconsistent records are rejected. Even when seven tracked dates contain no completions, the minimum suggestion includes a reliability caveat rather than pretending that it is a strong prediction.

## 15:40 to 16:20 Apply prefills; only Save persists

Speaker: Rohan Reddy Gosangi. Questions: R4, I2.

The helper remains under user control. Apply opens the habit editor with a suggested weekly goal, but that prefill is still a draft. Only Save changes the persisted habit. Cancel keeps the old goal, and Not now dismisses the suggestion. Apply is unavailable in this captured sparse-history example. The eligible Apply, Cancel and Save paths have separate Android acceptance coverage. This distinction matters because a recommendation should not silently change the user's goal merely because it was calculated or displayed.

## 16:20 to 17:00 Helper edge cases and tests

Speaker: Het Jani. Questions: T1, R4.

The helper tests use controlled dates and saved-record fixtures. They check missing history, the eligibility boundary, rounding, limits and invalid records. One important case is seven tracked dates with no completed days: it is eligible for a minimum suggestion but receives a warning about reliability. Another boundary is six tracked dates, which must abstain. These tests exercise the pure calculation independently of widgets. The repository tests then cover storage behavior, while interface and Android tests check how the result reaches the user.

## 17:00 to 17:40 Evaluation includes a counterexample

Speaker: Het Jani. Questions: R4.

The evaluation uses synthetic cases, so it does not establish real-user usefulness. On eight paired cases, with one separate abstention, the helper's mean absolute error is one point eight seven five days per week. The fixed three-day baseline scores one point six two five, which is better on these examples. We retain that counterexample and limitation. The rule is transparent and easy to test, but adding history-based complexity did not automatically improve this artificial evaluation. The case table and expected outputs are in AI_FEATURE.

## 17:40 to 18:20 Fresh host results: all33 pass

Speaker: Rohan Reddy Gosangi. Questions: T1.

The host verification includes formatting, static analysis and thirty-three tests. The latest final checks pass, and the package retains the exact command output. The test types include data, helper, interface and startup checks. Under the supplied guidance, this is Human-AI Testing: the student directed the work through chat, and the automated commands were executed with development assistance. That classification describes participation and execution accurately; it does not claim that a student manually clicked every test or that a peer usability session occurred.

## 18:20 to 19:00 Android acceptance and retained evidence

Speaker: Het Jani. Questions: T1, T2.

Android acceptance uses the real SQLite and preference plugins on separate phone and tablet emulator profiles. Each profile has two acceptance tests. The release checks also install the actual APK, restart the process offline and inspect saved habit and settings values. The logs identify the devices, operating system and execution dates. Both profiles use Android seventeen. We do not present them as two different operating-system versions or as physical-device coverage. Earlier evidence keeps its original date, and fresh verification is recorded separately.

## 19:00 to 19:40 Async safety and lifecycle cleanup

Speaker: Rohan Reddy Gosangi. Questions: T2, A1.

Asynchronous safety appears in the activity controller as well as startup. The busy guard prevents conflicting actions. The screen checks whether the local date changed before writing today's activity. After awaiting work, mounted checks protect state updates and navigation. Failures show an actionable message, and successful writes reload saved values. Controllers are disposed with their forms, and repository ownership is explicit. Startup tests cover successful opening, recovery after failure and an opening result that arrives after disposal.

## 19:40 to 20:20 Responsive forms and accessibility

Speaker: Rohan Reddy Gosangi. Questions: T1, I1.

The layout checks cover portrait, landscape and larger text. Scrollable forms dismiss the keyboard on drag, which addresses an actual Android test interaction problem. The interface uses labeled controls and semantic descriptions, including the garden's saved completion count. Retained device screenshots show rotated large-text views, and widget tests check additional layout sizes. The core color pairs were also measured. These checks support the documented scope, while a physical-device or screen-reader usability certification would require evidence we have not collected.

## 20:20 to 20:55 Release build: real artifact, real logs

Speaker: Het Jani. Questions: T2.

The release APK is a real build artifact, with its size and SHA-two-fifty-six hash recorded. It installs and launches in the documented Android environment. A Windows Kotlin incremental-cache issue was repaired and its earlier failure output was retained. The current release uses the disclosed local debug signing configuration, so it is a course artifact rather than a claim of production-store signing. Rebuilding the same source produced the same APK hash during final verification.

## 20:55 to 21:30 Real contribution history

Speaker: Rohan Reddy Gosangi. Questions: R1.

Our contribution evidence starts with the actual feature branches and commits. Rohan's UI and integration history and Het's data/helper history remain preserved. Het's reviewed source tip is six-four-five-nine-two-nine-four. The integrated branch retains those changes rather than replacing their authorship. The visible history does not establish twenty meaningful commits per person. The final human PR review and genuine process evidence must be linked before those requirements are claimed complete. Each student should explain their own actual participation when presenting this record.

## 21:30 to 22:05 Switch to your genuine ClickUp trace

Speaker: Het Jani. Questions: R1.

This part requires our genuine ClickUp task trace. We identify the actual task, its owner and acceptance criteria, then follow its real commit or pull request to the code and test evidence. The prepared recording cannot manufacture a board session or historical milestone captures. If a required record is missing, we disclose that gap. The task checklist separates completed implementation from signatures, review, recording and upload actions that still require actual student participation.

## 22:05 to 23:00 Both voices, selected questions, final checks

Speaker: Rohan Reddy Gosangi and Het Jani. Questions: I1, I2, A1, A2, D1, D2, T1, T2, R1, R4.

Bloom connects a small interface to persistent local records, a derived garden and an explainable offline helper. The walkthrough has addressed widget ownership, controls and state, responsibilities, lifecycle, both entities' CRUD, persistence, acceptance coverage, failure recovery, authentic ownership and the required helper. Those correspond to our ten selected question IDs. Both of us must understand and explain our actual work. Before submission, we verify the real recording link, repository access and required personal evidence, then each student completes their own upload. Thank you for watching our Bloom presentation.

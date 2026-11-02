# Gentle Goal Suggestion

Bloom uses an explainable offline Dart rule, not a trained AI model. No network requests, cloud inference, confidence scores, clinical claims or claims of real-world predictive accuracy are made. Implementation: `lib/helper/goal_suggestion.dart`; reproducible tests: `test/helper/goal_suggestion_test.dart`.

## Input and calendar contract

Course update (October 26): the actual scoring, delivery, helper lab and question bank are preserved in `docs/requirements/`. They explicitly accept honestly labeled rules/statistical helpers and require the helper as base work. The verified undergraduate questions-only selection includes R4. No calculation or fixture was changed for this documentation update.

`calculateGoal({required HabitView habit, required List<CheckInView> checkIns, required DateTime today})` returns `GoalSuggestion`: `int completedDays`, `int trackedDays`, `DateTime windowStart`, `DateTime windowEnd`, `int? daysPerWeek`, and `String explanation`.

Pass valid records for one habit only. Local calendar dates are normalized to midnight; UTC inputs are rejected to prevent accidental timezone reinterpretation. The inclusive window is today minus 13 calendar dates through today. Date component construction, not subtraction of 24-hour durations, handles daylight-saving changes. Saved date strings are YYYY-MM-DD and do not shift when the device timezone changes.

Eligibility requires seven DISTINCT saved check-in dates within this window, including started and in-progress days. This follows Bloom's proposal-specific interpretation of “tracked calendar days.” Seven completed check-ins are NOT required; habit age alone does not count as tracking. Missing records are not fabricated. With fewer than seven dates, daysPerWeek is null and the explanation says “Not enough history yet.” The course helper menu permits an equivalent approved local helper; it does not replace this documented proposal-specific contract with an untested calculation.

For eligible histories, count completed days in the window, divide by two, round .5 upward, then clamp to 1–7. Integer expression: `((completedDays + 1) ~/ 2).clamp(1, 7)`. Eight completions gives four days/week. Zero completions with seven tracked dates gives one, with an explicit reliability caveat. Missing dates still contribute no completions to the fixed 14-day denominator; a seven-day eligible history is not extrapolated to fourteen.

Inputs are checked for blank habit fields, invalid targets/IDs, duplicate entry IDs/dates, wrong habit, progress/status inconsistency, UTC dates, future dates and pre-creation dates. Invalid input throws ArgumentError and produces no recommendation. Valid older records are validated then excluded from the window; future/corrupt records are rejected instead of silently hidden.

## Benefit, rationale and alternative

Intended benefit: help a student consider a manageable weekly goal using their own saved completion history, with an explanation they can inspect and ignore. No actual improvement in student behavior or usability is claimed without real observation. Inputs are local habit targets and check-ins; output units are whole days/week, not a probability or confidence score.

The implementation follows the proposal's fixed 14-calendar-day rule because it is transparent, cheap to execute offline, does not require training data, and can be tested separately from the widgets/database. The three-days/week baseline exposes whether history-based complexity helps on the same examples; on the current synthetic cases it does not outperform the baseline.

The course menu suggests the current user-set target as a possible Habit Mastery baseline, but its undergraduate acceptance section explicitly permits a constant baseline. Bloom's proposal and frozen evaluation use fixed three days/week. That baseline is preserved; no different outputs or additional experiments are invented. Reproducible acceptance criteria are correct bounded outputs/abstention, accurate explanation, no automatic saved-goal changes, and measured synthetic error in days/week. No claim is made that a real-user usefulness target was met.

A plausible alternative is `7 * completed / trackedDays`, rounded/clamped to a weekly goal. It could respond faster to sparse logging but would treat untracked days differently and can inflate a recommendation when logging is selective. It was not implemented or evaluated, so no comparative performance is claimed for it. A trained model is unnecessary for the approved scope and would require suitable data and a different evaluation. The chosen rule's documented limitations, counterexample and explicit user override are retained rather than claiming accuracy or retuning against the held-out fixtures.

## Five required case types

| Case ID / type | Executed input | Expected | Actual evidence | Check result |
|---|---|---|---|---|
| C1 / normal | 8 completed of 14 tracked days | 4 days/week | Pure helper assertions pass; real Android eligible-fixture Apply/Cancel/Save case passes on both AVDs. | PASS |
| C2 / missing/new | Empty history; six tracked days even if all completed | Explicit abstention; no saved goal change | Pure helper assertions pass; real Android new-habit no-history explanation passes. | PASS |
| C3 / invalid | Wrong habit, duplicate dates, negative/excess progress, invalid status/progress, future/UTC date | ArgumentError | Invalid-input assertions pass; no fabricated recommendation or automatic saved goal. | PASS |
| C4 / boundary/tie/outlier | 0, 5, 14 completions; window start and one day before | 1 with caveat, 3, 7; start included, older excluded | Assertions for all completion counts 0–14 and inclusive calendar/DST/year boundaries pass. | PASS |
| C5 / counterexample | Perfect fortnight then synthetic exam week with one completion | Suggest 7; helper error 6 versus baseline error 2 | Counterexample assertions and unchanged synthetic fixture evaluation pass; limitation disclosed. | PASS for specified behavior, not good prediction |

## Separately prepared synthetic held-out evaluation

Fixture: `test/fixtures/held_out_goals.json`, committed as `1b054e3` before evaluation. It is separate from unit examples. The rule came from the proposal and was not fitted or tuned. All history and following-week outcomes are manually constructed SYNTHETIC scenarios, not real users, actual observations, independently collected data or peer testing. They deliberately cover stable routines, sparse tracking and disruptions; selection is not random or representative. “Held-out” here means reserved evaluation fixtures, not evidence of statistical independence or a production validation set.

MAE is mean absolute difference between suggested weekly days and the labeled following-week number of completed days. Both methods are scored on exactly the same eight eligible cases. A ninth new-habit case abstains and is excluded from BOTH numeric means, even though the fixed baseline could produce a value. Coverage is 8/9. Invalid cases are tested separately, with no numeric outcome.

| Synthetic case | Completed / tracked | Helper | Fixed baseline | Following-week outcome | Helper absolute error | Baseline absolute error |
|---|---:|---:|---:|---:|---:|---:|
| Steady low frequency | 4 / 14 | 2 | 3 | 2 | 0 | 1 |
| Steady high frequency | 12 / 14 | 6 | 3 | 6 | 0 | 3 |
| Moderate irregular | 5 / 14 | 3 | 3 | 2 | 1 | 1 |
| Quiet fortnight | 0 / 14 | 1 | 3 | 0 | 1 | 3 |
| Exam disruption ahead | 14 / 14 | 7 | 3 | 1 | 6 | 2 |
| Travel ends | 1 / 14 | 1 | 3 | 6 | 5 | 3 |
| Mixed routine | 7 / 14 | 4 | 3 | 3 | 1 | 0 |
| Short eligible history | 3 / 7 | 2 | 3 | 3 | 1 | 0 |
| New habit | 2 / 3 | Abstain | Excluded | 2 | — | — |

Executed totals: helper 15 absolute-error days / 8 = **1.875 days/week**; baseline 13 / 8 = **1.625 days/week**. The baseline performs better on these artificial cases. The initial test mistakenly expected a baseline total of 15; actual output showed 13, and the assertion was corrected without changing fixtures or the rule. Raw failure and passing outputs are retained under `docs/data_verification/`.

## Explanation, override and limitations

The result includes counts, bounds, suggested goal and explanation. `BloomRepository.suggestGoal` maps this to Rohan's existing `GoalSuggestionView` (baselineDaysPerWeek remains 3). It performs no writes; a repository test verifies the stored goal remains unchanged. Rohan's UI owns Apply/Not now: Apply prefills the form, and only explicit Save calls updateHabit. UI tests cover this with an explicit test double; subsequent real Android integration tests also verify Apply/cancel/Save against actual SQLite on both Pixel_4a and Bloom_Tablet_API37. `TEST_LOG.md` and `integration_test/android_acceptance_test.dart` identify the actual checks. These fixtures are synthetic test data, not real user history or peer observation.

Tracking is self-reported; missing dates are ambiguous, and uneven logging biases the result. The short history rule can understate a new routine. Travel, exams and changed schedules can make the recent past misleading. The schema has no historical daily-target snapshots: lowering targets caps historical progress, and raising targets demotes old completed entries below the new target, potentially changing later suggestions. The rule measures recorded completion, not motivation, health or future ability. Users may ignore it. Small synthetic MAE values cannot establish general accuracy or benefit.

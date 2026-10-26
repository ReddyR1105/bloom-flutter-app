# Gentle Goal Suggestion

Bloom uses an explainable offline Dart rule, not a trained AI model. No network requests, cloud inference, confidence scores, clinical claims or claims of real-world predictive accuracy are made. Implementation: `lib/helper/goal_suggestion.dart`; reproducible tests: `test/helper/goal_suggestion_test.dart`.

## Input and calendar contract

`calculateGoal({required HabitView habit, required List<CheckInView> checkIns, required DateTime today})` returns `GoalSuggestion`: `int completedDays`, `int trackedDays`, `DateTime windowStart`, `DateTime windowEnd`, `int? daysPerWeek`, and `String explanation`.

Pass valid records for one habit only. Local calendar dates are normalized to midnight; UTC inputs are rejected to prevent accidental timezone reinterpretation. The inclusive window is today minus 13 calendar dates through today. Date component construction, not subtraction of 24-hour durations, handles daylight-saving changes. Saved date strings are YYYY-MM-DD and do not shift when the device timezone changes.

Eligibility requires seven DISTINCT saved check-in dates within this window, including started and in-progress days. This follows the repository's explicit planning interpretation of “tracked calendar days.” Seven completed check-ins are NOT required; habit age alone does not count as tracking. Missing records are not fabricated. With fewer than seven dates, daysPerWeek is null and the explanation says “Not enough history yet.” The source proposal is a draft and the actual instructor rubric was unavailable; resolve any different instructor definition with the team before changing this contract.

For eligible histories, count completed days in the window, divide by two, round .5 upward, then clamp to 1–7. Integer expression: `((completedDays + 1) ~/ 2).clamp(1, 7)`. Eight completions gives four days/week. Zero completions with seven tracked dates gives one, with an explicit reliability caveat. Missing dates still contribute no completions to the fixed 14-day denominator; a seven-day eligible history is not extrapolated to fourteen.

Inputs are checked for blank habit fields, invalid targets/IDs, duplicate entry IDs/dates, wrong habit, progress/status inconsistency, UTC dates, future dates and pre-creation dates. Invalid input throws ArgumentError and produces no recommendation. Valid older records are validated then excluded from the window; future/corrupt records are rejected instead of silently hidden.

## Five required case types

| Type | Executed example | Result |
|---|---|---|
| Normal | 8 completed of 14 tracked days | 4 days/week |
| Missing/new | Empty history; six tracked days even if all completed | Explicit abstention; no saved goal change |
| Invalid | Wrong habit, duplicate dates, negative/excess progress, invalid status/progress, future/UTC date | ArgumentError |
| Boundary/tie/outlier | 0 completions, 5 completions, 14 completions; date at start and one day before | 1 with caveat, 3, 7; start included and older excluded |
| Counterexample | Perfect fortnight followed by a synthetic exam week with one completion | Suggests 7, error 6; baseline 3, error 2 |

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

The result includes counts, bounds, suggested goal and explanation. `BloomRepository.suggestGoal` maps this to Rohan's existing `GoalSuggestionView` (baselineDaysPerWeek remains 3). It performs no writes; a repository test verifies the stored goal remains unchanged. Rohan's UI owns Apply/Not now: Apply prefills the form, and only explicit Save calls updateHabit. His existing UI tests cover Apply/cancel/Save using a test double; testing the integrated real-data app on devices remains pending.

Tracking is self-reported; missing dates are ambiguous, and uneven logging biases the result. The short history rule can understate a new routine. Travel, exams and changed schedules can make the recent past misleading. The schema has no historical daily-target snapshots: lowering targets caps historical progress, and raising targets demotes old completed entries below the new target, potentially changing later suggestions. The rule measures recorded completion, not motivation, health or future ability. Users may ignore it. Small synthetic MAE values cannot establish general accuracy or benefit.

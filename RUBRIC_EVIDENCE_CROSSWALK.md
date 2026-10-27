# Bloom undergraduate rubric — evidence crosswalk

Reviewed October 26, 2026 against all supplied course pages in `docs/requirements/`. This maps evidence; it does not assign grades, promise credit, or replace each student's live explanation.

## Undergraduate base categories

| Category / maximum | Available evidence | Remaining requirement / limitation |
| --- | --- | --- |
| Functionality & applied knowledge / 25 | Five routed screen roles, validated forms, lists, gestures, dialogs, activity lifecycle, filters/aggregates; real SQLite/helper integration. TEST_LOG.md: 33 host tests; two real-plugin tests per AVD; release checks on two distinct emulator profiles. AI_FEATURE.md gives five case types with expected/actual outcomes, baseline, metric/sample size and limitations. | Both students must explain actual app behavior, state changes and error recovery in the recording. Two AVDs use one Android 17 image; no physical/older-OS claim. |
| Code quality & core concepts / 15 | Stateless presentation cards/garden and Stateful forms/activity; gateway, repository, settings and pure helper separated. Controllers/repository disposed; async mounted checks/retry; ARCHITECTURE.md explains ownership and boundaries. | Each student must demonstrate understanding of their actual contribution; AI-generated text/code is not itself proof of learning. |
| UI/UX, creativity & engagement / 15 | Supplied sage/cream design implemented; accessible labels/counts, scalable text, scrollable portrait/landscape, reduced motion, saved-progress garden and explicit helper Apply/Not now/Save. Actual screenshots plus source/log-supported iteration documented in DESIGN_ITERATION.pdf. | GAP: no real peer usability observation or peer-verified revision supplied. Concept-to-implementation comparison and automated keyboard/layout fixes are genuine technical evidence, not invented peer feedback. Full accessibility certification is not claimed. |
| Local data persistence / 15 | Both entities' full validated CRUD, parameterized queries, SQL uniqueness/FK/cascade, refreshed summaries, transactional corrections and SharedPreferences. Actual release APK survives force-stop/relaunch offline with records and all settings on both AVDs. | Explain storage choices and target-edit/history trade-off in video. No cloud storage is used. No backup or older-Android behavior claim beyond executed checks. |
| Version control, engagement & Kanban / 10 | Actual author history, feature branches, PRs, agent-assisted technical review, each member's code/test trace and real build blocker. Partial Kanban_Contribution_Evidence.pdf is in repository root and ZIP. README links the exact file and supplied List reference. | GAP: history does not meet demonstrated 20 meaningful commits/member; no fabricated/padded/backdated history. Actual Board URL/member mapping/permissions, daily updates/WIP/Done policies, four dated captures, real task IDs/acceptance/activity/review transitions and dated flow sample remain unverified. Oct 17/20/23 captures not supplied; Oct 27 capture is due tomorrow. At least one completed actual board implementation task/member plus CRUD/helper/testing coverage and a recorded task-to-code/test trace are required. |
| Documentation & reflection / 10 | README setup, versions, usage, schema, limitations/future plans/license status; ARCHITECTURE, report, AI_FEATURE, separate AI usage log, deck, test evidence and technical package. Authentic unsigned forms and reflection worksheet are prepared for humans. | GAP: finalized approved proposal evidence, real signatures, genuine contribution/peer evidence, actual video URL and students' own learning/reflection. An unsigned form or pending draft is not a completed deliverable. |
| Mandatory Project 1 Q&A / 10 | Rules confirmed: 10–15 actual bank questions, at least two per category, including I1/I2/D1/D2/R4; questions-only Word document must be uploaded before recording and included in final package. Planned 23-minute speaker split includes actual app/VS Code and collaboration trace. | Full bank is now supplied. Bloom_Project1_SelectedQuestions.docx is prepared with the 10 verbatim questions I1/I2, A1/A2, D1/D2, T1/T2, R1/R4. Selection upload before recording and genuine recorded answers remain human actions. Each member must explain contribution, state/data, helper evaluation and a real challenge/solution. |

Base maximum is 100; optional bonus maximum is 15. No score or automatic stacking of deductions is calculated. The actual rubric lists substantial deductions for absent video/Q&A, collaboration and documentation; only the instructor determines applicability and grading.

## Required ClickUp delivery checks

| Delivery gate | Status |
| --- | --- |
| PDF in repository and every final ZIP | Placement corrected: repository-root `Kanban_Contribution_Evidence.pdf`, also at ZIP root. Content is explicitly PARTIAL; no real board snapshots were supplied. |
| README Board URL and exact file path | PDF path linked. Supplied URL is a List reference; actual Board URL and shared permissions are not verified. |
| Privacy and usable offline evidence | Existing PDF omits tokens/passwords and shows actual code/author trace offline. Real board screenshots/permissions still need checking without hiding task ownership. |
| One recorded task -> owner/criteria -> commit/PR -> code -> test/review trace | Runbook/deck reserve time inside the same 20–25 minute presentation; actual board task/recording still missing. No second video or extra time is substituted. |

Board expectations: Free Forever shared List + Board view, all members invited, Backlog/Ready/In progress/Review-test/Done; WIP one active task/member and two review/test tasks/team. Done requires acceptance criteria plus linked actual review/test evidence. Substitution with GitHub Projects requires instructor approval; none is claimed. Do not integrate ClickUp into the Flutter runtime.

## Package and upload gates

| Required artifact / action | Current state |
| --- | --- |
| README.md, ARCHITECTURE.md, PROJECT_REPORT.pdf | Present; updated against supplied rubric. |
| app-release.apk | Actual verified installed release-mode build, debug-key coursework signing disclosed. Hash in TEST_LOG.md. |
| AI_FEATURE.md and AI_Usage_Log.md | Present; rules helper is base work, separate assistance disclosure retained. |
| Kanban_Contribution_Evidence.pdf | Present in repo/ZIP, but content incomplete until genuine board/flow evidence is supplied. |
| Project1_Presentation.pptx | Present with planned 23-minute notes. Not a recording. |
| Approved_Proposal.docx | No instructor-approved finalized copy supplied. Verbal approval is user-reported; original pending draft is labeled separately. |
| Signed statement | Genuine signed PDF OR readable signed PNG/JPG (including continuation pages) is accepted. Current forms are unsigned only. |
| TeamName_Project1_SelectedQuestions.docx | Prepared from the actual bank with full text and no answers; working Bloom prefix may be adjusted to actual team name. Upload before recording. |
| GitHub_Repository_Link.txt | Present. Repo is private: instructor must be added as collaborator or repository made public by authorized team action. Instructor access is unverified; do not change privacy silently. |
| YouTube_Video_Link.txt and actual 20–25 minute team recording | Missing. Aim for rehearsed 23 minutes, with actual app, VS Code, both members and integrated answers/ClickUp trace. |
| `Project_Group[Number]_Bloom.zip` | Current working name Bloom_ProjectOne_Rohan_Het.zip; actual group number still needed. Source/tests also remain in the repo and source archive. |
| Individual uploads | Rohan and Het each upload to iCollege by October 27, 2026, 11:59 PM Eastern and retain actual receipts. No upload performed here. |

## Individual reflection / peer evidence

The rubric assesses each student's actual understanding, meeting/Kanban decisions, peer evaluation, contribution and one challenge/solution/feedback change. No standalone personal reflection filename is specified in these excerpts, so none is invented as an extra mandatory file. `human_input/INDIVIDUAL_REFLECTION_WORKSHEET.docx` is a preparation aid only; students must supply their own truthful responses.

The physical-device suggestion is a final tip; the explicit base requirement is two distinct devices/emulators. Graduate-only Provider/Riverpod/BLoC, background processing, notifications, file operations and coverage quotas are not undergraduate obligations. No optional bonus work is added at the expense of submission readiness.

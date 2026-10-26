# Bloom collaboration

The user reported verbal instructor approval and explicitly authorized implementation on October 26. See docs/integration/APPROVAL_STATUS.md; do not represent that report as written instructor-issued evidence. Preserve actual authorship and require the genuine course evidence listed in HUMAN_INPUT_REQUIRED.md.

## Branches and reviews

- `main`: stable reviewed work.
- `develop`: integration branch, initially at the existing main commit; no implementation yet.
- `planning/project-one-preapproval`: current planning changes, reviewed against main.
- After approval, create focused `feature/...`, `fix/...`, and `docs/...` branches from the agreed integration base. Planned examples: `feature/sqlite-vertical-slice`, `feature/habit-crud`, `feature/check-in-history`, `feature/goal-helper`, `feature/settings`.

Create implementation branches only when approved work starts. PRs describe the concrete change, actual task link, executed checks/results, and limitations. Real teammates review; AI output is not peer review. Branch protection is recommended but has not been configured.

## Authentic attribution

Use each person's own GitHub account and Git identity for their actual work. Record AI assistance. Never impersonate teammates, add fictitious coauthors, create empty commits to meet counts, split work artificially, or backdate activity. The handoff asks for 20 steady meaningful commits per student; genuine participation is the team's responsibility.

The planning commit uses the existing local Git identity and documents AI assistance. It does not establish other students' contributions.

## Task evidence

Import `docs/planning/TASK_PLAN.csv` into the real ClickUp Free board and assign actual owners. Use Backlog → Ready → In progress → Review/test → Done; WIP limits are one active task/member and two review/test tasks/team. Each card needs owner, due date, acceptance criteria, and links to actual changes/tests/review.

Capture genuine dated board evidence; disclose missing October 17 evidence. A proposed CSV is not proof of completed work. Keep genuine signatures, private instructor messages, and private course receipts outside public Git history; use appropriately permitted/redacted evidence in submission artifacts.

## Verification after approval

Format/analyze/test the application, fix real failures, build/install the actual release APK and save exact results. Record tested commit SHA and device/OS identities. Unexecuted checks stay pending. Mockup PNGs are not running-app screenshots.

# Bloom AI assistance record

AI assistance was used for planning, code, tests, documentation and packaging. This is not a claim that either student's contribution was independently unaided or human-reviewed. Both students must review the final work and comply with the actual course disclosure policy.

## Rohan's sessions

October 18: read supplied handoff/proposal/designs; prepared approval checklist, planning documents, README, branch workflow and task breakdown. No Flutter implementation before user confirmation of approval. Full planning history: docs/planning/AI_Usage_Log.md.

October 26: user reported verbal approval and explicitly directed implementation. Codex inspected the repository, built the sage/cream UI against an explicit gateway, wrote UI/startup tests, configured Android build and kept Het-owned data/helper files untouched. Initial UI-only review package was explicitly incomplete, not claimed as functional submission.

After Het's handoff: fetched and reviewed exact commit64592948b41686de65cbd660102d034fe6bc1225, preserved his four commits in a fast-forward integration, injected BloomRepository.open(), added open-error/retry/disposal handling, removed the placeholder, and ran combined checks. Added actual Android acceptance/release verification and repaired environment/test-harness errors without altering Het's data/helper sources. Prepared the technical report, real presentation deck, source archive and package from actual logs/screenshots. Data shown in device screenshots is labeled [TEST] and is synthetic test data, not fabricated screenshots or a real-user study.

## Het's session

His HET_INTEGRATION_HANDOFF.md and DATA_TEST_LOG.md disclose Codex assistance implementing SQLite, preferences, local rule/helper and tests on his machine. AI_FEATURE.md explicitly describes synthetic fixtures and the baseline's better MAE. His original evidence files and author history are preserved; this agent does not invent human work, confidence scores or peer reviews.

## Evidence limits

Recorded verification is distinguished from human evidence in TEST_LOG.md and SUBMISSION_VERIFICATION.md. No signatures, professor approval document, historic board captures, real peer observations, recording, individual reflection or iCollege receipt were fabricated. Verbal approval is student-reported. Agent-assisted PR review is not represented as human approval. No commits are padded/backdated or attributed to another member.

Document-generation script: scripts/generate_submission_docs.py. It uses actual APK bytes/hash, Git history, passing device logs and original captured images. Isolated workspace document-generation dependencies do not change the app's runtime dependency set.

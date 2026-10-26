"""Generate unsigned forms and recording instructions, never human evidence.

Requires python-docx, reportlab and python-pptx. Use after the technical package
exists. This script does not sign, record, submit, or invent professor questions.
"""
import argparse
from pathlib import Path

from docx import Document
from docx.shared import Inches as DocInches
from pptx import Presentation
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from xml.sax.saxutils import escape


SEGMENTS = [
    ('0:00-2:00', 'Rohan', 'Introduce Bloom and navigate',
     'Introduce yourselves using your real names and undergraduate pathway. Explain that Bloom is an offline habit tracker. Show Today, Habits, Insights and Settings, then point out the routed create/edit form and activity detail. Explain the cream/sage/forest design and that the plant represents saved completions. Do not say this is a user study or an independently built project without AI assistance.'),
    ('2:00-6:00', 'Rohan', 'Demonstrate validated habit/activity flows',
     'Use a dedicated demo emulator, preserving any personal data. Create a clearly labeled demo habit with category, unit, target and weekly goal. Show an invalid empty name or zero target, then Save a valid habit. Edit it, Start today, move progress without saving, explain the unsaved label, Save progress, reach the target, and Finish. Show the saved dashboard/garden update. Open Reset, Cancel once, then confirm it and explain the single-day effect. Reach target and Finish again.'),
    ('6:00-10:00', 'Het', 'Demonstrate both tables and integrity',
     'Open History, filter by habit, correct today\'s note/status using consistent progress and Save. Show duplicate-date rejection. Delete a check-in and confirm the habit remains, then recreate today\'s entry from Start. Explain habits and check_ins in lib/data/bloom_repository.dart, foreign_keys ON, unique habit/date, progress/status validation, transaction rollback and cascade. Use a separate disposable demo habit to demonstrate the explicit all-history deletion warning and cascade. Do not delete another person\'s real records.'),
    ('10:00-12:00', 'Het', 'Demonstrate actual offline persistence',
     'Set a distinctive default target, week start and reduced-motion preference. Save a completed check-in. Show airplane mode enabled, force-stop and relaunch the app, then show the restored habit/completion and all three settings. Identify the actual emulator/profile. Explain that two separate Android 17 AVDs were tested; do not claim physical-device or older-OS testing. The existing TEST_LOG and per-device XML/screenshots record executed checks, not a substitute for this live demonstration.'),
    ('12:00-15:00', 'Het', 'Explain the helper and actual evaluation',
     'Open lib/helper/goal_suggestion.dart and AI_FEATURE.md. Explain the inclusive 14-calendar-day window, seven distinct tracked dates, half-up rounding and 1-7 clamp. A new habit must show Not enough history yet. For the eligible-history example, demonstrate the explicitly synthetic [TEST] Helper fixture through the real Android integration test; do not pretend these are personal historic check-ins. Show the eight-completion/four-day worked example and the five case types. Report the actual synthetic paired n=8 plus one abstention: helper MAE 1.875, fixed-three baseline 1.625 days/week. State that the baseline performed better and that this does not establish real-user accuracy.'),
    ('15:00-17:00', 'Rohan', 'Explain control and accessibility',
     'Show the real integration test\'s Apply/Cancel/Save flow: Apply prefills a four-day goal, Cancel leaves the saved three-day goal unchanged, and only Save persists four. Show portrait/landscape, large text, scrollable forms, confirmation dialogs and reduced motion. If a real peer observation and implemented improvement have been supplied, present their actual before/after record; otherwise disclose that peer evidence is missing. Automated test fixes are not peer feedback.'),
    ('17:00-19:00', 'Both', 'Show authentic collaboration',
     'Show the actual GitHub commits and PRs, each member\'s owned files, actual code/test links and AI disclosure. PR #2 integrates Het\'s original commits; PR #1 contains the combined application. Agent-assisted review is not human peer approval. Show the real ClickUp board/cards if accessible, linking task to code/tests/review. Do not recreate historic screenshots, claim unobserved WIP compliance, or claim 20 meaningful commits each when the visible history does not establish it.'),
    ('19:00-22:00', 'Both', 'Answer the actual instructor bank questions',
     'Insert and rehearse the actual selected professor questions once the bank is supplied. The handoff requests 10-15 questions, at least two per required category, including I1/I2/D1/D2/R4. No question text has been supplied or invented. Allocate enough time for genuine answers from both students; shorten earlier narration if necessary while respecting the actual rubric\'s duration. End with honest limitations, repository access and each student\'s individual upload obligation.'),
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', type=Path, required=True)
    args = parser.parse_args()
    root = args.package.resolve()
    human = root / 'human_input'
    human.mkdir(parents=True, exist_ok=True)
    styles = getSampleStyleSheet()
    styles['Heading1'].textColor = colors.HexColor('#285F4D')

    def p(text, style='BodyText'):
        return Paragraph(escape(text), styles[style])

    statement = ('We have reviewed the proposed Bloom project scope, instructor approval requirement, '
                 'individual contributions, local-only data requirement, GitHub/ClickUp evidence rules, '
                 'AI assistance disclosure, and individual submission obligations. By genuinely signing '
                 'below, each member acknowledges the work and evidence they actually reviewed. This '
                 'form does not claim missing course evidence is complete.')
    members = [
        ('Rohan Reddy Gosangi', 'Undergraduate: UI, navigation, integration, accessibility, documentation and packaging.'),
        ('Het Jani', 'Undergraduate: SQLite/repositories/models, preferences, helper calculation and data/helper tests.'),
    ]
    doc = Document()
    doc.sections[0].left_margin = doc.sections[0].right_margin = DocInches(.75)
    doc.add_heading('Bloom - Team Acknowledgment', 0)
    doc.add_paragraph('UNSIGNED FORM - requires both students\' genuine signatures and dates.')
    doc.add_paragraph('Group number / required team name: __________________________________')
    doc.add_paragraph(statement)
    for name, role in members:
        doc.add_heading(name, 2)
        doc.add_paragraph(role)
        doc.add_paragraph('Genuine signature: __________________________  Date: __________________')
    doc.add_paragraph('Repository: https://github.com/ReddyR1105/bloom-flutter-app')
    doc.add_paragraph('Instructor approval is recorded separately. The user reports verbal approval; this form is not an instructor decision.')
    doc.add_paragraph('After both members actually sign, export/scan the genuine signed version as SIGNED_STATEMENT.pdf. Do not submit this unsigned template as signed evidence.')
    doc.save(human / 'Team_Statement_FOR_SIGNATURE.docx')
    story = [p('Bloom - Team Acknowledgment', 'Title'),
             p('UNSIGNED FORM - signatures and dates must be supplied by the actual students.'),
             Spacer(1, 12), p('Group number / required team name: __________________________________'),
             Spacer(1, 12), p(statement)]
    for name, role in members:
        story += [Spacer(1, 20), p(name, 'Heading2'), p(role), Spacer(1, 18),
                  p('Genuine signature: __________________________  Date: __________________')]
    story += [Spacer(1, 24), p('Repository: https://github.com/ReddyR1105/bloom-flutter-app'),
              Spacer(1, 12), p('Approval is recorded separately. This is not instructor-issued approval or proof of completed evidence. After genuine signatures, export/scan as SIGNED_STATEMENT.pdf.')]
    SimpleDocTemplate(str(human/'UNSIGNED_Team_Statement.pdf')).build(story)

    runbook = Document()
    runbook.add_heading('Bloom - Recording Runbook', 0)
    runbook.add_paragraph('Planned 22-minute live team presentation, not a recording or proof of participation. Confirm duration and question requirements against the actual instructor rubric.')
    runbook.add_heading('Before recording', 1)
    for text in [
        'Install the included real app-release.apk. Confirm microphone/screen capture and both real students\' participation.',
        'Review the report, deck and exact code/tests. Do not read an invented personal reflection or claim observations you did not make.',
        'Have the actual professor question selection and genuine board/peer evidence ready. These were not supplied.',
        'Use clearly labeled demo/test records and preserve unrelated personal data. Record the actual app, not design mockups.',
        'Open source and terminal. Commands below are demonstrations to execute, not new pass results until executed.'
    ]:
        runbook.add_paragraph(text, style='List Bullet')
    for timing, speaker, title, directions in SEGMENTS:
        runbook.add_heading(f'{timing} | {speaker} | {title}', 1)
        runbook.add_paragraph(directions)
    runbook.add_heading('Useful reproducible commands', 1)
    for cmd in ['flutter analyze', 'flutter test --reporter expanded',
                'flutter test integration_test/android_acceptance_test.dart -d <actual-emulator-id> --no-uninstall --reporter expanded',
                'flutter build apk --release',
                'adb -s <actual-emulator-id> install -r app-release.apk',
                'adb -s <actual-emulator-id> shell am force-stop edu.gsu.bloom.bloom',
                'adb -s <actual-emulator-id> shell am start -W -n edu.gsu.bloom.bloom/.MainActivity']:
        runbook.add_paragraph(cmd)
    runbook.add_heading('After recording', 1)
    runbook.add_paragraph('Upload the genuine recording, verify its access and duration, and write the real URL to YouTube_Video_Link.txt. Finish genuine missing evidence, regenerate the final ZIP, then each student uploads individually to iCollege and saves the actual receipt. No upload is performed by this script.')
    runbook.save(root/'RECORDING_RUNBOOK.docx')
    story = [p('Bloom - Recording Runbook', 'Title'),
             p('Planned live presentation, not a completed recording. Both students must participate authentically. Actual rubric and professor bank remain required.')]
    for timing, speaker, title, directions in SEGMENTS:
        story += [Spacer(1, 12), p(f'{timing} | {speaker} | {title}', 'Heading2'), p(directions)]
    SimpleDocTemplate(str(root/'RECORDING_RUNBOOK.pdf')).build(story)

    checklist = [p('Bloom - Finish before upload', 'Title'),
                 p('Technical package prepared. Genuine course/human evidence is still incomplete.'), Spacer(1, 12)]
    tasks = [
        'Enter the actual group number and required team name; verify official rubric and ZIP naming.',
        'Supply the actual professor bank; select the required real questions and generate the questions-only Word file.',
        'Both students genuinely sign the prefilled form and save SIGNED_STATEMENT.pdf. Retain required proposal/approval evidence.',
        'Attach genuine board captures, task/review links and required peer evidence. Disclose absent historic captures and commit-count shortfall.',
        'Have Het genuinely review PR #1; merge it before relying on the repository default main branch.',
        'Record the actual team demo using the runbook/deck; add the real video URL. Do not fabricate participation or answers.',
        'Review package contents, regenerate the ZIP after adding evidence, and verify its contents/hash.',
        'Rohan and Het each upload individually before October 27, 2026, 11:59 PM Eastern and retain their own receipts.'
    ]
    for i, task in enumerate(tasks, 1):
        checklist += [p(f'{i}. {task}'), Spacer(1, 10)]
    checklist += [p('The supplied handoff specifies a 20-25 minute demo and at least 20 meaningful commits/member. Verify the actual rubric; visible Git history does not establish that commit threshold. No empty/backdated commits should be manufactured.')]
    SimpleDocTemplate(str(root/'FINISH_BEFORE_UPLOAD.pdf')).build(checklist)

    deck = Presentation(root/'Project1_Presentation.pptx')
    for slide in deck.slides:
        previous = slide.notes_slide.notes_text_frame.text
        slide.notes_slide.notes_text_frame.text = previous + '\n\nDetailed action-by-action rehearsal directions are in RECORDING_RUNBOOK.docx/PDF. Use the actual instructor question bank; no question selection or human recording has been fabricated.'
    deck.save(root/'Project1_Presentation.pptx')
    print('Prepared prefilled unsigned DOCX/PDF, detailed recording DOCX/PDF, upload checklist and deck note references. No human evidence generated.')


if __name__ == '__main__':
    main()

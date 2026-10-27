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


SEGMENTS = [('0:00-2:00',
  'Both',
  'Introduce users, roles and selected IDs (R1 introduction)',
  "Introduce both real students and undergraduate pathway. State Bloom's offline habit-tracking purpose and "
  'actual ownership. Name the selected set: I1/I2, A1/A2, D1/D2, T1/T2, R1/R4. Questions are answered during '
  'the walkthrough, not as a separate speech. Upload the questions-only Word file before recording.'),
 ('2:00-6:00',
  'Rohan',
  'App interaction and widgets (I1, I2, part of D1)',
  'Show Today/Habits, create/edit with empty-name or zero-target validation, then a valid Save. Identify '
  'HabitCard as reusable StatelessWidget and HabitEditor/HabitDetail as StatefulWidget. Start, move the '
  'progress slider without saving, explain draft versus persisted progress, Save, Finish at target and show '
  'the garden. Demonstrate Reset Cancel/confirm and state the one-day scope. Preserve unrelated records; use '
  'clearly labeled demo data.'),
 ('6:00-9:00',
  'Het, with Rohan operating UI',
  'Both entities CRUD and offline proof (D1, D2)',
  'Show history read/correction/delete and that child deletion preserves the habit. Show the explicit '
  'parent/all-history warning on a disposable demo habit and refreshed counts. Set a distinctive '
  'target/week-start/reduced-motion preference, enable airplane mode, force-stop/relaunch, and show restored '
  'completion/settings. Explain SQLite relations versus SharedPreferences and why GitHub/ClickUp/YouTube are '
  'not runtime backends.'),
 ('9:00-12:00',
  'Rohan and Het',
  'VS Code boundaries and lifecycle (A1, A2)',
  'Trace HabitEditor through BloomGateway to BloomRepository validation/SQL and back to refreshed state. '
  'Explain why widgets do not own all data logic. Show owned controllers in initState/dispose, mounted '
  'checks, repository close and an open completing after disposal. Point to ui_startup_test.dart and explain '
  'the controlled navigation-away test; do not invent a timer or personal bug history.'),
 ('12:00-15:00',
  'Het, Rohan explains UI control',
  'Helper and honest evaluation (R4)',
  'Show the pure local helper, input units/window/distinct-day threshold, explanation and no-data/invalid '
  'feedback. Use the explicitly synthetic real-SQLite acceptance fixture for 8 completions -> 4 days/week, '
  'then Apply/Cancel/Save. Report actual paired synthetic n=8 plus one abstention: helper MAE1.875 versus '
  'fixed-three baseline1.625 days/week. Baseline was better; disclose the counterexample and historic-target '
  'limitation. No trained model or real-user benefit is claimed.'),
 ('15:00-17:00',
  'Both',
  'Failure/recovery and test boundaries (T2, T1)',
  'Show the controlled failed-save test with preserved form and zero writes, plus explicit startup '
  'retry/disposal regression. Label test-double failure scenarios honestly. For actual build history show '
  'the Windows cross-drive Kotlin cache failure and fix, separately from user-facing recovery. Explain real '
  'host SQLite, host settings mocks, UI test double and actual Android plugins without confusing their '
  'evidence.'),
 ('17:00-20:00',
  'Both',
  'Coverage, accessibility and iteration (T1; T2 verification)',
  'Use TEST_LOG to map both CRUD entities, all five roles, settings, helper and offline/restart to actual '
  'results. Identify the two AVD profiles, same Android17 image and coverage limits. Show '
  'portrait/landscape, large text, reduced motion and DESIGN_ITERATION.pdf. If real peer feedback is '
  'provided, demonstrate its actual revision and verification; otherwise disclose that missing evidence. '
  'Automated fixes and design concepts are not peer observations.'),
 ('20:00-23:00',
  'Both',
  'Authentic collaboration, learning and limits (R1; R4 responsibility)',
  'Follow one actual ClickUp task -> owner/acceptance criteria -> commit/PR -> code -> test/review result, '
  'using genuine board evidence if available. Each member explains their actual branch/files/review and '
  'personal learning. Show true author history; no claim of20 meaningful commits/member where not '
  'established. Disclose absent historic captures/peer review. R4 was answered earlier; briefly reinforce '
  'user control and limitations rather than appending another Q&A speech. Each member answers their own '
  'questions and later uploads individually.')]


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
    doc.add_paragraph('Group: UG-P03 (Group 03) | Project: Bloom')
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
             Spacer(1, 12), p('Group: UG-P03 (Group 03) | Project: Bloom'),
             Spacer(1, 12), p(statement)]
    for name, role in members:
        story += [Spacer(1, 20), p(name, 'Heading2'), p(role), Spacer(1, 18),
                  p('Genuine signature: __________________________  Date: __________________')]
    story += [Spacer(1, 24), p('Repository: https://github.com/ReddyR1105/bloom-flutter-app'),
              Spacer(1, 12), p('Approval is recorded separately. This is not instructor-issued approval or proof of completed evidence. After genuine signatures, export/scan as SIGNED_STATEMENT.pdf or a readable signed PNG/JPG.')]
    SimpleDocTemplate(str(human/'UNSIGNED_Team_Statement.pdf')).build(story)

    runbook = Document()
    runbook.add_heading('Bloom - Recording Runbook', 0)
    runbook.add_paragraph('Planned 23-minute live team presentation, not a recording or proof of participation. The actual course excerpts require 20-25 minutes and recommend 23. The actual bank is supplied; the separate questions-only Word selection is prepared and must be uploaded before recording.')
    runbook.add_heading('Before recording', 1)
    for text in [
        'Install the included real app-release.apk. Confirm microphone/screen capture and both real students\' participation.',
        'Review the report, deck and exact code/tests. Do not read an invented personal reflection or claim observations you did not make.',
        'Upload the supplied questions-only Word selection before recording; have genuine board/peer evidence ready. Those human evidence items remain unverified.',
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
             p('Planned live presentation, not a completed recording. Both students must participate authentically. The actual rubric and full question bank are now supplied. Use the verified questions-only selection and separate Q&A evidence guide.')]
    for timing, speaker, title, directions in SEGMENTS:
        story += [Spacer(1, 12), p(f'{timing} | {speaker} | {title}', 'Heading2'), p(directions)]
    SimpleDocTemplate(str(root/'RECORDING_RUNBOOK.pdf')).build(story)

    checklist = [p('Bloom - Finish before upload', 'Title'),
                 p('Technical package prepared. Genuine course/human evidence is still incomplete.'), Spacer(1, 12)]
    tasks = [
        'Verified roster group UG-P03; package filename Project_Group03_Bloom.zip. Fill actual student IDs in the proposal.',
        'Upload Bloom_Project1_SelectedQuestions.docx BEFORE recording; the verified selection contains 10 actual questions, two per category and all required IDs.',
        'Both students genuinely sign the prefilled form. A signed PDF or readable signed PNG/JPG is accepted. Retain required proposal/approval evidence.',
        'Attach genuine board captures, task/review links and required peer evidence. Disclose absent historic captures and commit-count shortfall.',
        'Have Het genuinely review PR #1; merge it before relying on the repository default main branch.',
        'Record the actual team demo using the runbook/deck; add the real video URL. Do not fabricate participation or answers.',
        'Review package contents, regenerate the ZIP after adding evidence, and verify its contents/hash.',
        'Rohan and Het each upload individually before October 27, 2026, 11:59 PM Eastern and retain their own receipts.'
    ]
    for i, task in enumerate(tasks, 1):
        checklist += [p(f'{i}. {task}'), Spacer(1, 10)]
    checklist += [p('The supplied actual rubric specifies a 20-25 minute demo aiming for 23 and at least 20 meaningful commits/member; visible Git history does not establish that commit threshold. No empty/backdated commits should be manufactured.')]
    SimpleDocTemplate(str(root/'FINISH_BEFORE_UPLOAD.pdf')).build(checklist)

    deck = Presentation(root/'Project1_Presentation.pptx')
    for slide in deck.slides:
        previous = slide.notes_slide.notes_text_frame.text
        slide.notes_slide.notes_text_frame.text = previous + '\n\nDetailed action-by-action rehearsal directions are in RECORDING_RUNBOOK.docx/PDF. Use the actual instructor question bank; no question selection or human recording has been fabricated.'
    deck.save(root/'Project1_Presentation.pptx')
    print('Prepared prefilled unsigned DOCX/PDF, detailed recording DOCX/PDF, upload checklist and deck note references. No human evidence generated.')


if __name__ == '__main__':
    main()

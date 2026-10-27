"""Build genuine question selection and rubric/design support documents.

Question text is extracted verbatim from the actual supplied bank. Answers and
personal reflection are excluded from the selection DOCX. No human evidence is
created. Dependencies: reportlab, python-docx, python-pptx.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from xml.sax.saxutils import escape

from docx import Document
from docx.shared import Pt
from pptx import Presentation
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak

ROOT = Path(__file__).resolve().parents[1]
SELECTED = ['I1', 'I2', 'A1', 'A2', 'D1', 'D2', 'T1', 'T2', 'R1', 'R4']
GUIDANCE = {
    'I1': ('Rohan', 'lib/ui/widgets.dart: HabitCard and Garden; lib/ui/editors.dart: HabitEditor',
           'Show a stateless card rendering immutable habit/check-in fields, then a Stateful form with owned controllers and a mutable weekly target. Explain build() and rerendering; do not confuse widget drafts with saved records.', 'test/ui_flows_test.dart: validated create/edit and garden counts.'),
    'I2': ('Rohan', 'lib/ui/habit_detail.dart: _act, _draftProgress; lib/ui/editors.dart: _save',
           'Start persists/resumes a canonical record. Moving the slider changes only _draftProgress; Save progress calls the gateway, then reloads. Finish requires target reached; form validation rejects invalid targets. Explain the exact state-to-render path and settings persistence.', 'UI activity tests plus integration_test/android_acceptance_test.dart on both AVDs.'),
    'A1': ('Rohan, with Het showing repository', 'lib/main.dart; lib/integration/bloom_gateway.dart; lib/data/bloom_repository.dart',
           'Trace HabitEditor -> gateway -> repository validation/SQL -> fresh snapshot -> UI. Explain why widgets do not own SQLite connections/helper logic and how injection separates test doubles from real persistence.', 'ARCHITECTURE.md and real SQLite tests in test/data/repository_test.dart.'),
    'A2': ('Rohan', 'lib/ui/editors.dart: initState/dispose; lib/main.dart: BloomBootstrap._open',
           'Show disposal of all form controllers, mounted checks, and closing a repository that finishes opening after bootstrap disposal. Once attached, BloomApp owns close(). Do not claim a timer exists; the app does not require one.', 'test/ui_startup_test.dart: completion after disposal, explicit retry, and owned close.'),
    'D1': ('Het, with Rohan operating UI', 'lib/data/bloom_repository.dart: _create, create/update/delete methods; UI confirmation dialogs',
           'Demonstrate full CRUD for habit and check-in separately. Explain parameterized operations, UNIQUE(habit_id,date), foreign_keys ON and ON DELETE CASCADE. Show check-in deletion preserves habit; habit deletion warns about ALL history and refreshes derived values.', 'Real host SQL constraints/rollback/cascade tests and Android acceptance on each AVD.'),
    'D2': ('Het', 'lib/data/settings_store.dart; repository open/load; scripts/verify_android_release.ps1',
           'Explain relational SQLite versus the one versioned settings JSON in SharedPreferences. In actual airplane mode, force-stop/relaunch and show saved completion plus target/week-start/reduced-motion. GitHub/ClickUp/YouTube are development/submission tools, not runtime app services.', 'TEST_LOG.md, actual per-device release_checks.txt and captured XML/screenshots.'),
    'T1': ('Het and Rohan', 'TEST_LOG.md; test/data; test/helper; test/ui_*; integration_test/android_acceptance_test.dart',
           'Map coverage to both entity CRUD, five screen roles, empty/invalid cases, settings, helper and offline restart. Distinguish host SQLite, mocked host settings, UI test double and actual Android plugins. Identify two separate AVD profiles using the same Android 17 image; do not claim physical-device coverage.', '33 host tests plus 2 Android acceptance tests per AVD and independent release checks.'),
    'T2': ('Rohan, Het may explain transaction guard', 'test/ui_flows_test.dart: failed save retains form; test/ui_startup_test.dart: retry/disposal',
           'Show the deliberately tested save failure, its actionable message, preserved form and zero writes, then the retry test. Label this a controlled test-double scenario, not a fabricated real-user database failure. For real build history, separately show the logged Windows Kotlin cross-drive failure/fix.', 'Recorded passing UI/startup regressions; raw Android Kotlin failure and final successful release logs.'),
    'R1': ('Both, each explaining actual ownership', 'GitHub PR #1/#2; actual author commits; README contribution map; partial Kanban PDF',
           'Each student must explain what they actually contributed/reviewed, using their real branch and commits. File responsibilities are established, but personal learning/meeting/peer-review statements must come from the students. Disclose absent real board IDs/activity, missing historical captures and the 20-commit shortfall; no invented reviews.', 'Actual Git/PR history and code/test traces. Real ClickUp and human review evidence still required.'),
    'R4': ('Het explains rule/evaluation; Rohan explains UI control', 'lib/helper/goal_suggestion.dart; AI_FEATURE.md; HabitDetail._edit and HabitEditor._save',
           'Explain local 14-day input window, at least 7 tracked dates, completed/2 half-up and 1-7 clamp. Show no-data/invalid handling, explanation, Apply-prefill/Cancel/Save and recomputation after saved inputs change. Label the eligible fixture synthetic. Report paired n=8, one abstention, helper MAE 1.875 vs baseline 1.625; baseline was better. Defend transparent scope and disclose the counterexample/history limits.', 'Five-case expected/actual table, unchanged fixture tests, actual Android Apply/Cancel/Save and offline checks.'),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', type=Path, required=True)
    args = parser.parse_args()
    package = args.package.resolve()
    bank_path = ROOT/'docs/requirements/COURSE_Curated_Questions.txt'
    bank = bank_path.read_text(encoding='utf-8-sig')
    matches = list(re.finditer(r'^([IADTR][1-5]) · (.+)$', bank, re.M))
    questions = {}
    for index, match in enumerate(matches):
        end = matches[index+1].start() if index+1 < len(matches) else bank.index('02 · Presentation run of show')
        block = bank[match.start():end].strip()
        # Category navigation belongs to the next group, not this question.
        block = re.split(r'\n[IA DTR] · ', block)[0].strip()
        questions[match.group(1)] = block
    assert len(questions) == 25
    assert len(SELECTED) == 10 and set(['I1','I2','D1','D2','R4']).issubset(SELECTED)
    assert all(sum(q.startswith(category) for q in SELECTED) == 2 for category in 'IADTR')
    doc = Document()
    doc.styles['Normal'].font.name = 'Calibri'
    doc.styles['Normal'].font.size = Pt(11)
    for qid in SELECTED:
        lines = [line for line in questions[qid].splitlines() if line.strip()]
        doc.add_heading(lines[0], 2)
        for line in lines[1:]:
            doc.add_paragraph(line)
    selected_path = package/'Bloom_Project1_SelectedQuestions.docx'
    doc.save(selected_path)
    reopened = Document(selected_path)
    actual = '\n'.join(p.text for p in reopened.paragraphs if p.text.strip())
    expected = '\n'.join(line for qid in SELECTED for line in questions[qid].splitlines() if line.strip())
    assert actual == expected, 'Selected Word text must be verbatim questions only'
    (ROOT/'docs/requirements/SELECTED_QUESTIONS.json').write_text(json.dumps({
        'source':'docs/requirements/COURSE_Curated_Questions.txt',
        'source_sha256':hashlib.sha256(bank_path.read_bytes()).hexdigest().upper(),
        'selected_ids':SELECTED,
        'categories':{'implementation':['I1','I2'],'architecture':['A1','A2'],
                      'local_data':['D1','D2'],'testing':['T1','T2'],'reflection':['R1','R4']},
        'questions_only_docx':selected_path.name,
        'selection_text_verified_verbatim':True,
        'uploaded_before_recording':False}, indent=2)+'\n', encoding='utf-8')

    guide = Document()
    guide.add_heading('Bloom - Q&A evidence rehearsal guide', 0)
    guide.add_paragraph('Separate preparation aid; NOT the questions-only submission file and NOT recorded answers. Each student must understand and explain the actual code in their own words. No personal reflection, meeting history or peer review is invented.')
    for qid in SELECTED:
        speaker, files, explanation, evidence = GUIDANCE[qid]
        guide.add_heading(qid+' | '+speaker, 1)
        guide.add_paragraph('Code: '+files)
        guide.add_paragraph(explanation)
        guide.add_paragraph('Evidence: '+evidence)
    guide.add_heading('Integrated 23-minute route', 1)
    for text in [
        '0-2: problem/users/roles; name the selected set and actual speakers (R1 introduction).',
        '2-9: actual five-screen app, controls and both CRUD flows/offline restart (I1, I2, D1, D2).',
        '9-17: VS Code boundaries, lifecycle, helper, baseline/counterexample and failure guards (A1, A2, R4, T2).',
        '17-20: actual test coverage, accessibility/design iteration, known limits; real peer observation only if supplied (T1, T2).',
        '20-23: actual task-to-code/test trace, each person\'s ownership and learning (R1; R4 responsibility). No separate Q&A speech.'
    ]:
        guide.add_paragraph(text,style='List Bullet')
    guide.add_paragraph('Upload Bloom_Project1_SelectedQuestions.docx to the course dropbox BEFORE recording, include it in each final ZIP, and identify question IDs on slides or verbally. A working Bloom filename is used; adjust prefix if the actual team name differs. No group number is invented.')
    guide.save(package/'Q_AND_A_REHEARSAL_GUIDE.docx')

    styles = getSampleStyleSheet()
    styles['Heading1'].textColor = colors.HexColor('#285F4D')
    def p(text, style='BodyText'):
        return Paragraph(escape(text).replace('**','').replace('`',''), styles[style])
    story = [p('Bloom - Q&A evidence rehearsal guide', 'Title'),
             p('Preparation aid only. Questions-only Word selection is separate. No human answers or recording is fabricated.')]
    for qid in SELECTED:
        speaker, files, explanation, evidence = GUIDANCE[qid]
        story += [Spacer(1, 10), p(qid+' | '+speaker, 'Heading2'), p('Code: '+files), p(explanation), p('Evidence: '+evidence)]
    SimpleDocTemplate(str(package/'Q_AND_A_REHEARSAL_GUIDE.pdf')).build(story)

    # Render the authoritative crosswalk as a readable offline PDF.
    text = (ROOT/'RUBRIC_EVIDENCE_CROSSWALK.md').read_text(encoding='utf-8')
    story = []
    lines = text.splitlines()
    i=0
    while i < len(lines):
        line=lines[i].strip()
        if not line:
            i+=1; continue
        if line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                cols=[c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[-: ]+',c) for c in cols):
                    rows.append([p(c) for c in cols])
                i+=1
            widths=[130,195,203] if len(rows[0])==3 else [160,368]
            table=Table(rows,colWidths=widths,repeatRows=1)
            table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E6EFE5')),
                ('VALIGN',(0,0),(-1,-1),'TOP'),('GRID',(0,0),(-1,-1),.3,colors.HexColor('#CBD9C7')),
                ('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]))
            story += [table,Spacer(1,10)]; continue
        if line.startswith('# '): story.append(p(line[2:],'Title'))
        elif line.startswith('## '): story.append(p(line[3:],'Heading1'))
        else: story += [p(line),Spacer(1,6)]
        i+=1
    SimpleDocTemplate(str(package/'RUBRIC_EVIDENCE_CROSSWALK.pdf'),leftMargin=42,rightMargin=42).build(story)

    before = ROOT/'docs/planning/Supplied_Handoff/design/Bloom_Home_UI.png'
    after = ROOT/'docs/device_evidence/emulator-5554/01_today_offline_after_process_restart.png'
    old = subprocess.check_output(['git','show','b056775:lib/ui/widgets.dart'],cwd=ROOT,text=True)
    current = (ROOT/'lib/ui/widgets.dart').read_text(encoding='utf-8')
    assert 'keyboardDismissBehavior' not in old and 'keyboardDismissBehavior' in current
    story=[p('Bloom - actual design iteration', 'Title'),
           p('Before: supplied UI concept (not a built-app screenshot). After: actual October 26 release capture with explicitly labeled synthetic test records. No peer observation or historic screenshot is invented.'),Spacer(1,12)]
    images=Table([[p('Supplied concept / design input','Heading2'),p('Actual installed release / saved test completion','Heading2')],
        [Image(str(before),width=205,height=395),Image(str(after),width=205,height=444)]],colWidths=[264,264])
    images.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP')]))
    story += [images,PageBreak(),p('Verified technical revision, peer evidence still missing','Heading1'),
              p('The original concept supplied the cream/sage palette, generous cards, simple plant and calm completion feedback. The actual app preserves that direction and derives garden/counts from saved records, with a semantic progress bar and explicit text status. Those are real design-to-implementation differences, not a claim of a peer experiment.'),Spacer(1,12),
              p('The Android acceptance runner encountered a keyboard-obscured tap. The runner was corrected to dismiss/unfocus the real keyboard before hit-testing; the UI scroll view also gained drag-to-dismiss keyboard behavior. Git b056775 has no keyboardDismissBehavior; tested source 2cf89bc contains ScrollViewKeyboardDismissBehavior.onDrag. This is an evidence-supported automated-test-driven change, not a fabricated peer request.'),Spacer(1,12),
              p('Before evidence: docs/verification/android_pixel_keyboard_failure.txt and original widget source in Git. After evidence: actual passing Android acceptance logs for both AVDs, TEST_LOG.md and the changed widget source. Portrait/landscape, device 1.5x and widget 2x text-scale checks are recorded separately. Core color pair ratios are 6.98:1 and 10.10:1; these are not full accessibility certification.'),Spacer(1,12),
              p('Required peer usability observation / resulting verified revision: NOT SUPPLIED. A real observer must perform a task, report an actual issue, and the team must preserve genuine before/after evidence and verification. Do not present this technical comparison as completing that peer requirement.')]
    SimpleDocTemplate(str(package/'DESIGN_ITERATION.pdf'),leftMargin=42,rightMargin=42).build(story)

    reflection=Document()
    reflection.add_heading('Individual reflection preparation - unfilled worksheet',0)
    reflection.add_paragraph('Not the professor question selection and not completed reflection evidence. Each student writes their own truthful account after reviewing actual work. Blank fields are intentional; no personal learning is fabricated.')
    for index,name in enumerate(['Rohan Reddy Gosangi','Het Jani']):
        if index: reflection.add_page_break()
        reflection.add_heading(name,1)
        for prompt in ['Which specific feature/files/commits did you actually contribute to and review?',
                       'Explain one course concept through the actual code and one visible action/outcome.',
                       'Describe one challenge you personally worked through, the solution and actual verification. Distinguish AI assistance.',
                       'What real peer feedback changed a decision? If none exists, state that honestly.',
                       'Which actual meeting/board/review evidence supports your participation?',
                       'What did you learn, what remains limited, and what would you change first?']:
            reflection.add_paragraph(prompt)
            reflection.add_paragraph('Your own response: __________________________________________________')
    reflection.save(package/'human_input/INDIVIDUAL_REFLECTION_WORKSHEET.docx')

    # Complete known proposal facts without inventing an approved copy, student
    # IDs, signatures, board captures or an original on-time submission.
    proposal=Document(ROOT/'docs/planning/Supplied_Handoff/docs/Bloom_Flutter_Project_Proposal.docx')
    replacements={
        '[ADD GROUP NUMBER AND TEAM NAME]':'REQUIRED HUMAN INPUT: actual group number and team name',
        '[ADD ALL MEMBERS, ROLE OWNERS AND UNDERGRAD/GRAD PATHWAYS]':
            'Rohan Reddy Gosangi - undergraduate: UI/navigation/integration/accessibility/docs/package; '
            'Het Jani - undergraduate: SQLite/repositories/preferences/helper/data tests. Actual student IDs not supplied.',
        '[INSERT REAL NEW-REPOSITORY URL]':'https://github.com/ReddyR1105/bloom-flutter-app',
        '[INSERT REAL SHARED BOARD LINK]':
            'Supplied List reference: https://app.clickup.com/90141780863/v/l/li/901422402099?pr=90149411098. Actual Board URL/access unverified.',
        '[INSERT GENUINE OCT 17 SCREENSHOT IF IT EXISTS; OTHERWISE DISCLOSE MISSING EVIDENCE]':
            'No genuine October 17 screenshot supplied. Retrieve if it actually exists; otherwise disclose missing evidence.',
        '[APPROVAL STATUS, DATE, AND INSTRUCTOR FEEDBACK]':
            'Rohan reports verbal instructor approval; no instructor-issued approval copy or feedback record supplied.',
        'Status: instructor approval pending':'Status: user-reported verbal approval; finalized instructor-approved copy not supplied',
        'Draft date: October 18, 2026':'Original draft: October 18, 2026; updated draft: October 26, 2026',
    }
    def replace_paragraphs(paragraphs):
        for paragraph in paragraphs:
            value=paragraph.text
            for old,new in replacements.items(): value=value.replace(old,new)
            if value!=paragraph.text: paragraph.text=value
    replace_paragraphs(proposal.paragraphs)
    for table in proposal.tables:
        for row in table.rows:
            for cell in row.cells: replace_paragraphs(cell.paragraphs)
    proposal.add_page_break()
    proposal.add_heading('October 26 update - unfinalized draft, not an approval record',1)
    proposal.add_paragraph('This working update fills known team/repository facts and preserves the original concept images. It does not assert an on-time October 17 upload or instructor signature. Missing group details, actual student IDs, genuine signed attachment and required approval evidence must be completed by the team.')
    table=proposal.add_table(rows=1, cols=4)
    table.style='Table Grid'
    for cell,value in zip(table.rows[0].cells,['Member','Pathway','Actual student ID','Responsibility']): cell.text=value
    for name,role in [('Rohan Reddy Gosangi','UI, navigation, integration, accessibility, documentation, demo/package'),
                      ('Het Jani','SQLite, repository/models, preferences, pure helper and data/helper tests')]:
        for cell,value in zip(table.add_row().cells,[name,'Undergraduate','Not supplied - student must fill',role]): cell.text=value
    proposal.add_heading('Helper rationale, alternative and evaluation',2)
    proposal.add_paragraph('Gentle Goal Suggestion is an offline rule using the documented 14-calendar-day window and at least seven distinct tracked days. It explains a bounded weekly goal and Apply prefills without saving. Fixed three days/week is the proposal baseline, permitted by the undergraduate lab. A tracked-days-normalized rate is an alternative with sparse-logging bias; it was not evaluated. Actual synthetic paired n=8 plus one abstention produced helper MAE1.875 versus baseline1.625 days/week; the baseline was better. No real-user benefit or trained model is claimed.')
    proposal.add_heading('Specific edge cases and refinement',2)
    for item in ['Empty database -> helpful empty state and New habit action.',
                 'Empty name or target0 -> validation; no record saved.',
                 'Duplicate habit/date -> correct the existing check-in rather than duplicate it.',
                 'Insufficient helper history -> explicit abstention; no automatic goal change.',
                 'Actual automated keyboard/layout fixes are documented; real peer observation/verified revision still must be supplied.']:
        proposal.add_paragraph(item,style='List Bullet')
    proposal.add_paragraph('Actual technical results are in TEST_LOG.md (33 host tests; two acceptance tests per AVD; real release restart/offline/settings on both). The course requirements and selected question bank are now supplied; questions-only selection must be uploaded before the actual 20-25 minute recording, aiming for23. No personal learning, board chronology, signature or receipt is generated.')
    proposal.save(package/'human_input/Bloom_Project1_Proposal_UPDATED_DRAFT.docx')

    # Add actual IDs to the existing deck, never adding answers to selection DOCX.
    deck=Presentation(package/'Project1_Presentation.pptx')
    slide_ids=[['R1'],['I1','I2'],['I1','I2'],['I2','D1'],['D1','A1'],['D1'],['R4'],['R4'],['D2','T1'],['A1','A2'],['T1','T2'],['R1'],SELECTED]
    minutes=[1,1,1.5,2.5,2,1.5,2,1.5,2,2,2,2,2]
    assert sum(minutes)==23
    for slide_index,(slide, ids) in enumerate(zip(deck.slides, slide_ids)):
        footer=slide.shapes[-1].text_frame
        footer.paragraphs[0].text = re.sub(r'Planned [\d.]+ min',f'Planned {minutes[slide_index]} min',footer.paragraphs[0].text)+' | '+', '.join(ids)
        if slide_index==len(deck.slides)-1:
            # Keep the final summary concise; all ten questions are answered in
            # the walkthrough, not as a second appended presentation.
            for shape in slide.shapes:
                if shape.has_text_frame and (shape.text.startswith('Insert the actual') or shape.text.startswith('Selected:')):
                    texts=['Selected: I1, I2 / A1, A2 / D1, D2 / T1, T2 / R1, R4.',
                           'Questions-only Word file: upload BEFORE recording.',
                           'Identify IDs throughout; each member explains real work.',
                           'Genuine video/evidence and individual uploads remain human actions.']
                    for paragraph, value in zip(shape.text_frame.paragraphs,texts): paragraph.text=value
        note=slide.notes_slide.notes_text_frame.text
        note=re.sub(r'Approximate segment: [\d.]+ minutes',f'Approximate segment: {minutes[slide_index]} minutes',note)
        note+='\n\nSelected question coverage on this slide: '+', '.join(ids)+'. '
        note+='Use Q_AND_A_REHEARSAL_GUIDE for actual file/function/test references. Weave responses into the existing demo; do not append a separate Q&A speech. R1 personal process and peer/board evidence must be supplied by the humans.'
        slide.notes_slide.notes_text_frame.text=note
    deck.save(package/'Project1_Presentation.pptx')
    (package/'PRESENTATION_COVERAGE.json').write_text(json.dumps({
        'planned_total_minutes':sum(minutes),'selected_ids':SELECTED,
        'question_ids_per_slide':slide_ids,'recorded':False,
        'answers_woven_into_walkthrough':True},indent=2)+'\n',encoding='utf-8')
    print('PASS: 10 verbatim selected questions, two/category and all required IDs; separate rehearsal guide, rubric/design PDFs and unfilled reflection worksheet prepared.')


if __name__=='__main__':
    main()

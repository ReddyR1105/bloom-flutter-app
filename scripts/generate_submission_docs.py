"""Generate factual report/deck from the already verified submission staging.

Requires reportlab and python-pptx. No screenshots or human evidence generated.
Run after device logs and genuine screenshot files exist. Keep this script with
source so the documents can be regenerated after a real change.
"""
import argparse
import hashlib
import subprocess
from pathlib import Path
from xml.sax.saxutils import escape

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.util import Inches, Pt
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak

ROOT = Path(__file__).resolve().parents[1]
CREAM, GREEN, SAGE, INK = 'FAF8F2', '285F4D', 'E6EFE5', '243C32'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    apk = out / 'app-release.apk'
    apk_hash = hashlib.sha256(apk.read_bytes()).hexdigest().upper()
    commit = git('rev-parse', 'HEAD')
    history = git('log', '--all', '--date=short', '--format=%h | %ad | %an | %s')
    counts = git('shortlog', '-sn', '--all')
    device_rows = []
    for serial, label in [('emulator-5554', 'Pixel_4a / 1080x2340'), ('emulator-5556', 'Bloom_Tablet_API37 / 2560x1600')]:
        text = (ROOT / 'docs/device_evidence' / serial / 'release_checks.txt').read_text(encoding='utf-8-sig')
        if 'All scripted release checks passed.' not in text:
            raise RuntimeError(f'Cannot claim release acceptance for {serial}: log is not passing')
        device_rows.append([serial, label, 'Android 17', 'PASS'])
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name='BloomTitle', fontName='Helvetica-Bold', fontSize=30, leading=36,
                              textColor=colors.HexColor('#'+GREEN), spaceAfter=16))
    styles['Heading1'].textColor = colors.HexColor('#'+GREEN)
    styles['BodyText'].leading = 15

    def para(text, style='BodyText'):
        return Paragraph(escape(text).replace('\n', '<br/>'), styles[style])

    def table(rows, widths=None):
        result = Table([[para(str(c)) for c in row] for row in rows], colWidths=widths,
                       repeatRows=1, hAlign='LEFT')
        result.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#'+SAGE)),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOX', (0, 0), (-1, -1), .5, colors.HexColor('#D6E1D4')),
            ('INNERGRID', (0, 0), (-1, -1), .25, colors.HexColor('#D6E1D4')),
            ('LEFTPADDING', (0, 0), (-1, -1), 9), ('RIGHTPADDING', (0, 0), (-1, -1), 9),
            ('TOPPADDING', (0, 0), (-1, -1), 8), ('BOTTOMPADDING', (0, 0), (-1, -1), 8)]))
        return result

    def pdf(name, story):
        def footer(canvas, doc):
            canvas.setFont('Helvetica', 8)
            canvas.setFillColor(colors.HexColor('#'+GREEN))
            canvas.drawString(42, 26, 'Bloom | Rohan Reddy Gosangi + Het Jani | October 26, 2026')
            canvas.drawRightString(570, 26, str(doc.page))
        SimpleDocTemplate(str(out/name), rightMargin=42, leftMargin=42,
                          topMargin=42, bottomMargin=42).build(story, onFirstPage=footer, onLaterPages=footer)

    features = [
        ['Role', 'Implemented behavior'],
        ['Today', 'Saved daily counts, active habit/category filter, garden derived from completed records.'],
        ['Create/edit', 'Validated title/category/unit, positive target, weekly goal 1-7, explicit Save/Cancel.'],
        ['Detail/activity', 'Start/resume, draft slider, save progress, Finish at target, confirmed Reset/delete.'],
        ['History/insights', 'Check-in CRUD/corrections, habit filter, explained weekly completion denominator.'],
        ['Settings', 'Default target, week start and reduced motion in SharedPreferences.'],
    ]
    story = [para('Bloom', 'BloomTitle'), para('Small steps. Visible growth.', 'Heading2'),
             para('Project One technical report - undergraduate pathway'),
             para('Rohan Reddy Gosangi: UI, navigation, integration, accessibility, documentation, packaging.\n'
                  'Het Jani: SQLite/repositories/models, preferences, helper calculation, data/helper tests.'),
             Spacer(1, 14), para('1. Scope and implemented behavior', 'Heading1'),
             para('Bloom is a minimal offline habit tracker. There is no Firebase, remote authentication, '
                  'online sync, cloud database or cloud AI. The five screen roles are reached from four tabs '
                  '(Today, Habits, Insights, Settings), with routed forms and activity detail.'),
             Spacer(1, 10), table(features, [115, 413]),
             para('2. Architecture and data integrity', 'Heading1'),
             para('main.dart opens BloomRepository and injects BloomApp through the unchanged BloomGateway. '
                  'A failed open is displayed with Retry; it is never converted into empty data. UI drafts are '
                  'separate from saved records. Controllers are disposed and asynchronous continuations guard mounted state.'),
             table([
                 ['Table/service', 'Fields / policies'],
                 ['habits', 'id, title, category, unit, daily_target 1-100000, weekly_target 1-7, created_at, archived'],
                 ['check_ins', 'id, habit_id FK, local ISO date, progress, started/in_progress/completed, note; unique habit/date'],
                 ['SQLite', 'Foreign keys per connection, ON DELETE CASCADE, SQL/Dart validation and transactional corrections. No automatic seed data.'],
                 ['Preferences', 'One versioned JSON value: defaultTarget, weekStartsMonday, reducedMotion. Failed writes surfaced; cache reloaded.'],
             ], [115, 413]),
             para('Daily-target edits normalize saved progress/status. The required schema has no historic '
                  'target snapshot, so raising a target can demote older completions and change garden/helper results. '
                  'Dates use local calendar components, including across DST; UTC helper inputs are rejected.'),
             para('3. Gentle Goal Suggestion', 'Heading1'),
             para('Pure offline Dart rule: last 14 inclusive calendar dates; at least seven distinct tracked dates; '
                  'completed days divided by two, half-up rounded and clamped to 1-7. Eight completions suggests four '
                  'days/week. Insufficient history abstains. Zero completions gives one with an unreliability caveat. '
                  'Apply only prefills the editor; explicit Save changes the goal.'),
             para('Synthetic held-out evaluation: eight paired eligible cases and one abstention; helper MAE 1.875 '
                  'versus fixed three-day baseline MAE 1.625 days/week. The baseline performed better on these '
                  'artificial cases. This is not real-user validation or predictive accuracy evidence. See AI_FEATURE.md.'),
             para('4. Actual verification', 'Heading1'),
             table([['Check', 'Actual outcome'], ['Format / analyze', 'PASS: zero formatting changes; analyzer no issues.'],
                    ['Host suite', '33 tests pass: 20 data/helper + 10 UI + 3 startup.'],
                    ['Android integration', 'Two acceptance tests passed on each separate AVD using real SQLite/preferences.'],
                    ['Release build', 'Actual flutter build apk --release; installed and launched on both AVDs.'],
                    ['Restart/offline/settings', 'Force-stop/relaunch in airplane mode preserved test habit/completion and all three settings on both AVDs.']], [145, 383]),
             Spacer(1, 10), table([['Serial', 'Profile / resolution', 'OS', 'Result'], *device_rows], [96, 250, 95, 87]),
             para('Device screenshots and records are actual captured runtime output. The displayed [TEST] records '
                  'are explicitly synthetic acceptance fixtures, not claimed personal habits, peer testing or historic evidence. '
                  'Both AVDs use the same Android 17 system image; no physical-device or older-OS coverage is claimed.'),
             para('Build/test issues repaired: Kotlin incremental paths failed across C:/D: roots; project disables '
                  'incremental compilation and uses in-process Kotlin. Android helper assertion initially ran before '
                  'asynchronous I/O completed; acceptance now waits for actual result. Raw failures and final logs retained.'),
             para('5. Source and APK identity', 'Heading1'), para('Source base before generated-document packaging: '+commit),
             para('APK bytes: '+str(apk.stat().st_size)), para('APK SHA-256: '+apk_hash),
             para('Release uses the local debug signing configuration for coursework installation. No signing key '
                  'is included. Source archive omits secrets, caches, local.properties and build output.'),
             para('6. Genuine evidence and remaining human work', 'Heading1'),
             para('Rohan reports verbal instructor approval; no written approval or approved proposal copy was supplied. '
                  'The actual assessment and delivery excerpts were supplied October 26 and are mapped in '
                  'RUBRIC_EVIDENCE_CROSSWALK.md. They require a 20-25 minute demo aiming for 23 minutes and at least 20 meaningful '
                  'commits/member. The actual bank is now supplied; the questions-only undergraduate selection is prepared, but course upload and recorded answers remain human actions. Current visible history does not establish that contribution threshold. No commits '
                  'were padded or backdated.'),
             para('Still required: actual group number, genuine signatures, questions-selection upload before recording, real team recording '
                  'and video URL, real peer observation/improvement evidence, genuine board snapshots and human review. '
                  'Missing October 17/20/23 evidence cannot be recreated. Both members upload individually and preserve '
                  'their receipts; this assistant does not upload to iCollege.'),
             para('Deadline: October 27, 2026, 11:59 PM America/New_York. Package is technically assembled, but human '
                  'evidence is incomplete. No license has been selected; no open-source license grant is implied.'),
             PageBreak(), para('7. Actual runtime screen references', 'Heading1')]
    images = [('01_today_offline_after_process_restart', 'Today after force-stop/relaunch, in airplane mode.'),
              ('02_edit_habit', 'Edit habit form, actual stored test habit.'),
              ('03_habit_detail', 'Saved completed check-in and activity controls.'),
              ('04_history', 'Saved check-in history and summary.'),
              ('05_settings_restored', 'All three settings restored from real preferences.')]
    for index, (name, caption) in enumerate(images):
        img = ROOT/'docs/device_evidence/emulator-5554'/f'{name}.png'
        if not img.exists(): raise FileNotFoundError(img)
        story.extend([para(caption, 'Heading2'), Image(str(img), width=205, height=444), Spacer(1, 14)])
        if index != len(images)-1: story.append(PageBreak())
    pdf('PROJECT_REPORT.pdf', story)

    evidence = [para('Contribution evidence', 'BloomTitle'),
                para('Partial evidence: actual Git history; authentic Kanban captures not supplied.', 'Heading2'),
                para('Repository: https://github.com/ReddyR1105/bloom-flutter-app\n'
                     'PR #1: Rohan integration -> main. PR #2: Het data/helper -> Rohan integration. '
                     'Code review by this agent is AI-assisted review, not fabricated human peer review.'),
                para('Actual author counts at source snapshot', 'Heading1'), para(counts),
                para('Observed commits (not a claim all qualify for course credit)', 'Heading1'), para(history),
                para('Task-to-code-to-test trace', 'Heading1'),
                table([['Owner / task', 'Actual code and test evidence'],
                       ['Rohan / UI + integration', 'lib/ui, lib/main.dart, startup retry and lifecycle; test/ui_* and integration_test/android_acceptance_test.dart; docs/verification and device_evidence.'],
                       ['Het / data + helper', '6459294 branch tip; lib/data, lib/helper; test/data, test/helper; DATA_TEST_LOG.md, AI_FEATURE.md.']], [145,383]),
                para('Kanban evidence remains incomplete', 'Heading1'),
                para('User-supplied List: https://app.clickup.com/90141780863/v/l/li/901422402099?pr=90149411098. '
                     'Access was unavailable; actual Board URL and ownership/status/history were not independently '
                     'verified. No dated board screenshot was supplied. No historic board state or human contribution '
                     'was generated. Attach genuine captures and real card/PR/review links before submission.'),
                para('Flow reflection - observable limits', 'Heading1'),
                para('Separate ownership avoided conflicting data/UI edits. Het implemented the already specified '
                     'gateway, allowing a fast-forward integration without remapping his models. Device validation '
                     'identified and repaired an environment-specific Kotlin build failure. Without actual board '
                     'timestamps/WIP data, lead time, throughput or compliance cannot be measured. Planned WIP '
                     'limits are one active task/member and two team review/test tasks; no historic compliance claim.'),
                para('Human signatures, individual reflections and peer observations are not present and are not '
                     'replaced by this generated technical evidence document.')]
    pdf('Kanban_Contribution_Evidence.pdf', evidence)

    prs = Presentation()
    prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)

    def slide(title, points, speaker, minutes, picture=None):
        s = prs.slides.add_slide(prs.slide_layouts[6])
        s.background.fill.solid(); s.background.fill.fore_color.rgb = RGBColor.from_string(CREAM)
        def text(x,y,w,h,value,size,color=INK,bold=False):
            box = s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h)).text_frame
            box.word_wrap = True
            p = box.paragraphs[0]; p.text = value; p.font.name='Aptos'; p.font.size=Pt(size)
            p.font.bold=bold; p.font.color.rgb=RGBColor.from_string(color)
            return box
        text(.6,.35,12,.35,'BLOOM / SMALL STEPS. VISIBLE GROWTH.',12,GREEN,True)
        text(.6,1,11.8,1,title,32,GREEN,True)
        width = 7.7 if picture else 11.7
        body=text(.7,2.05,width,4.6,'',23)
        for i, point in enumerate(points):
            p=body.paragraphs[0] if i==0 else body.add_paragraph()
            p.text=point; p.font.name='Aptos'; p.font.size=Pt(23); p.font.color.rgb=RGBColor.from_string(INK)
            p.space_after=Pt(16)
        if picture: s.shapes.add_picture(str(picture), Inches(9.2), Inches(1.65), height=Inches(5.3))
        text(.7,7,12,.25,f'{speaker} | Planned {minutes} min | {len(prs.slides):02d}',11,GREEN)
        s.notes_slide.notes_text_frame.text = (f'Planned speaker: {speaker}. Approximate segment: {minutes} minutes. '
            'Demonstrate the actual installed app and explain the points naturally. Synthetic test fixtures shown '
            'must remain labeled. No recording, peer observation, signatures or human participation is claimed by '
            'this deck. The actual bank and verified ten-question selection are supplied. Upload the questions-only Word document before recording and use the separate evidence guide for rehearsal.')
        return s

    phone = ROOT/'docs/device_evidence/emulator-5554'
    slide('Bloom', ['Offline habit tracking with a calm garden reward.',
                    'Rohan Reddy Gosangi + Het Jani | Undergraduate pathway',
                    'Actual integrated Flutter / SQLite application.'], 'Rohan', 1)
    slide('Five screen roles, one small routine', ['Today / habit list', 'Create and edit habits',
          'Activity detail: Start -> progress -> Finish or Reset', 'History / insights and persistent settings'], 'Rohan', 1)
    slide('Today: saved work becomes visible', ['Counts come from saved check-ins.',
          'Four static garden stages, no separate game state.', 'Cream, sage and forest palette; labeled test fixture shown.'],
          'Rohan', 1.5, phone/'01_today_offline_after_process_restart.png')
    slide('Make and complete a small goal', ['Validated name, unit, target and weekly frequency.',
          'Temporary progress is separate from saved progress.', 'Reset/delete explain scope and require confirmation.'],
          'Rohan', 2, phone/'03_habit_detail.png')
    slide('SQLite integrity', ['habits 1 -> many check_ins; foreign keys enabled.',
          'Unique habit/date; progress/status/date validation.', 'Parent deletion cascades; child deletion keeps habit.',
          'Atomic correction and consistent target-change policy.'], 'Het', 2)
    slide('Correct history, explain the summary', ['Create, read, update and delete check-ins.',
          'Filter by habit; correct dates and notes.', 'Rate denominator: active habits on eligible elapsed days.'],
          'Het', 1.5, phone/'04_history.png')
    slide('Gentle Goal Suggestion', ['Local rule, not a trained model.',
          'At least 7 tracked dates within the last 14 calendar days.', 'Completed days / 2; half-up; clamp 1-7.',
          '8 completions -> 4 days/week; Apply requires explicit Save.'], 'Het', 2)
    slide('Evaluation: honest limits', ['Synthetic paired n=8; one abstention.',
          'Helper MAE: 1.875 days/week.', 'Fixed 3-day baseline MAE: 1.625 days/week.',
          'Baseline was better on these artificial cases; no real-user accuracy claim.'], 'Het', 1.5)
    slide('Offline, restart and preferences', ['Release APK tested in airplane mode after force-stop.',
          'SQLite completion and all three preferences restored.', 'Separate phone and tablet AVDs, both Android 17.',
          'No physical-device or older-Android coverage claimed.'], 'Het', 2, phone/'05_settings_restored.png')
    slide('Architecture and responsibility', ['Rohan: UI/navigation, integration, accessibility, docs/package.',
          'Het: SQLite/repository, preferences, helper and data/helper tests.',
          'Shared BloomGateway allowed integration without rewriting his APIs.',
          'Startup failures show Retry; controllers and repository are disposed.'], 'Rohan', 1)
    slide('Actual verification', ['33 host tests pass; analyzer and format pass.',
          '2 real-plugin acceptance tests pass on each AVD.', 'Actual release APK built, installed and restarted offline.',
          'Windows Kotlin cache failure repaired; raw failures/results retained.'], 'Both', 1.5)
    slide('Authentic collaboration and evidence gaps', ['Show the actual PR/task/test trace, not a recreated board.',
          'Real history does not demonstrate 20 meaningful commits/member.',
          'Board captures, signatures, peer evidence and video remain human work.',
          'Verbal approval is student-reported; no written approval fabricated.'], 'Both', 1)
    slide('Instructor Q&A and submission', ['Selected: I1/I2, A1/A2, D1/D2, T1/T2, R1/R4.',
          'Upload the questions-only Word selection BEFORE recording.',
          'Use genuine responses from both students.', 'Each student uploads individually and verifies receipt.'], 'Both', 5)
    prs.save(str(out/'Project1_Presentation.pptx'))
    (out/'DOCUMENT_GENERATION.txt').write_text(
        f'Generated from source {commit}\nAPK SHA-256 {apk_hash}\n'
        'PDFs/deck generated from real logs and screenshots; human-only evidence explicitly incomplete.\n', encoding='utf-8')
    print('Generated PROJECT_REPORT.pdf, Kanban_Contribution_Evidence.pdf, Project1_Presentation.pptx (13 slides).')


if __name__ == '__main__':
    main()

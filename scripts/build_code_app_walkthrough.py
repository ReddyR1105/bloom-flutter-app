"""Assemble a truthful silent source/app walkthrough from real files and captures.

No new app implementation, student narration, peer review or board access is claimed.
Run with submission-tools on PYTHONPATH. Intermediate frames/segments stay outside ZIP.
"""
from pathlib import Path
import hashlib,json,re,subprocess,textwrap
from PIL import Image,ImageDraw,ImageFont
import imageio_ffmpeg
from docx import Document
from docx.shared import Pt

ROOT=Path(__file__).resolve().parents[1]
PACKAGE=ROOT/'final_submission/Project_Group03_Bloom'
OUT=PACKAGE/'full_walkthrough'
WORK=ROOT/'final_submission/walkthrough_render_work'
WORK.mkdir(exist_ok=True);OUT.mkdir(exist_ok=True)
CAP=OUT/'capture_evidence'
OLD=PACKAGE/'supplemental_recording/Bloom_Supplemental_App_Walkthrough.mp4'
NEW=CAP/'Bloom_Expanded_Demo.mp4'
PHONE=ROOT/'docs/device_evidence/emulator-5554'
FFMPEG=imageio_ffmpeg.get_ffmpeg_exe()
HEAD=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
history=subprocess.check_output(['git','log','--all','--date=short','--format=%h | %ad | %an | %s'],cwd=ROOT,text=True)
(OUT/'ACTUAL_GIT_HISTORY.txt').write_text(history,encoding='utf-8')
(OUT/'WORKSTREAMS.txt').write_text('''Bloom | UG-P03 | Undergraduate pair

Assigned workstreams, not a claim of exclusively manual authorship:
Rohan: UI, navigation, integration, accessibility, documentation and packaging.
Het: SQLite/repository/models, preferences, helper and data/helper tests.
Codex assistance is used in both workstreams. Actual Git history is retained.

Rohan UI: lib/ui/, lib/main.dart, lib/integration/bloom_gateway.dart.
Het implementation: lib/data/, lib/helper/, test/data/, test/helper/.
Het source tip: 64592948b41686de65cbd660102d034fe6bc1225.
Integrated source snapshot: 97cb60c; runtime files unchanged from tested source.

Fresh host results: format/analyze clean;33 tests pass, October28.
Retained device results: two acceptance tests on each of two AVDs, October26.
APK SHA256: 67A2A518877DDAB76C5D234105B231C66691146B21F55A2CC164D59200D7BFD7

Human–AI Testing: student-directed, AI-executed automated checks.
The student requested/directs work in chat. Commands are executed by Codex.
No manual execution or peer usability observation is invented.

This is a silent source walkthrough with recorded actual app interactions.
Source panels are saved code, not a live editor or code being newly typed.
App playback is followed by paused frames for explanation.
Both students must narrate and supply genuine collaboration/reflection evidence.
''',encoding='utf-8')

def path(name):
    p=ROOT/name
    if p.exists():return p
    p=PACKAGE/name
    if p.exists():return p
    raise FileNotFoundError(name)
def pic(name):return CAP/(name+'.png')
def still(name):return {'path':str(pic(name)),'kind':'still'}
def oldclip(start,length):return {'path':str(OLD),'kind':'video','start':start,'length':length}
def clip(start,length):return {'path':str(NEW),'kind':'video','start':start,'length':length}
def evidencepic(name):return {'path':str(PHONE/(name+'.png')),'kind':'still'}

scenes=[]
def scene(title,who,q,file,anchor,note,app,seconds=40,line=None,tail=False):
    scenes.append(dict(title=title,speaker=who,questions=q.split(),file=file,anchor=anchor,
                       note=note,app=app,seconds=seconds,line=line,tail=tail))
scene('Bloom: purpose and real implementation','Both','R1','full_walkthrough/WORKSTREAMS.txt',None,
      'Introduce both students. Explain offline habit tracking and the five screen roles. Label controlled demo inputs.',oldclip(0,6),30)
scene('What each workstream delivered','Both','R1 A1','full_walkthrough/WORKSTREAMS.txt',None,
      'Rohan explains UI/integration. Het explains persistence/helper. Describe only your actual participation; Codex assistance is recorded.',still('10_today_completed'),30)
scene('Open once, inject the real repository','Rohan','A1 T2','lib/main.dart','Future<void> _open()',
      'Trace actual startup, failed-open recovery and repository ownership. Explain the mounted guard after awaiting storage.',oldclip(0,6))
scene('A typed boundary for integration','Rohan + Het','A1 A2','lib/integration/bloom_gateway.dart','abstract interface class BloomGateway',
      'Explain why UI calls BloomGateway while Het implements it in BloomRepository. Trace one operation across this boundary.',clip(49,8))
scene('Theme, navigation and screen roles','Rohan','I1','lib/ui/bloom_app.dart','theme: ThemeData(',
      'Explain the sage/cream theme and navigation. Show Today, habit form, detail/activity, insights/history and settings.',oldclip(4,10))
scene('State and loading/error recovery','Rohan','I2 T2','lib/ui/bloom_app.dart','Future<void> _reload()',
      'Explain snapshot reloads, pending state, visible failures and generation checks. Empty saved data is different from an error.',still('03_saved_habit'))
scene('Garden reward comes from saved completions','Rohan','I1 I2','lib/ui/widgets.dart','class Garden extends StatelessWidget',
      'Point to the completed count and four derived stages. There is no separate garden persistence or claimed behavior-change evidence.',still('10_today_completed'))
scene('Create form: controllers and draft state','Rohan','I1 I2','lib/ui/editors.dart','void initState()',
      'Show the actual form being filled. Explain controller ownership, default settings and temporary weekly goal state.',clip(16,29))
scene('Validation before writing','Rohan','I2 D1','lib/ui/editors.dart','String? _required(',
      'The actual capture rejects an empty name. Explain target bounds and required fields; repository validation is another layer.',clip(0,12))
scene('Explicit Save commits the form','Rohan','I2 A1','lib/ui/editors.dart','Future<void> _save()',
      'Trace HabitDraft to createHabit/updateHabit, then successful navigation. Explain why Cancel does not persist a helper goal.',clip(44,13))
scene('Activity progress: draft versus saved','Rohan','I2','lib/ui/habit_detail.dart',None,
      'Explain that the progress control changes a draft first. Save progress writes through the gateway and reloads saved data.',clip(60,16),line=224)
scene('Start is idempotent for a local date','Het','D1','lib/data/bloom_repository.dart','Future<void> start(',
      'Explain the transaction, habit/date lookup and insert only when no record exists. Start resumes the canonical record.',clip(57,10))
scene('Bounds and status remain consistent','Het','D1 D2','lib/data/bloom_repository.dart','final nextProgress = progress ?? old.progress;',
      'Explain target checks, status normalization and validateEntry. Progress cannot exceed the daily target or retain a false completed status.',clip(67,22))
scene('Finish and confirmed Reset','Rohan + Het','I2 D1','lib/ui/habit_detail.dart','Future<void> _reset()',
      'Show completion and the actual Reset confirmation. In this capture Reset is canceled; passing reset behavior is evidenced by tests.',clip(84,23))
scene('Delete scope and confirmation','Rohan + Het','D1 T2','lib/ui/habit_detail.dart','Future<void> _delete()',
      'Explain parent deletion versus a single check-in deletion. This actual confirmation is canceled; no deletion is implied by that footage.',clip(108,12))
scene('Two related SQLite entities','Het','D1 A2','lib/data/bloom_repository.dart','static Future<void> _create(',
      'Explain habits to check_ins, primary keys, the foreign key and cascading child deletion. Point to actual schema fields.',still('03_saved_habit'))
scene('Constraints protect every writer','Het','D1 T1','lib/data/bloom_repository.dart','CREATE TRIGGER check_in_',
      'Discuss unique habit/date, SQL checks/triggers, date/status consistency and target-change behavior. Relate a constraint to a real test.',still('04_partial_progress'))
scene('CRUD remains in the repository','Het','D1','lib/data/bloom_repository.dart','Future<void> createHabit(',
      'Trace create/update validation and parameterized SQL. Explain transactional normalization when daily targets change.',still('03_saved_habit'))
scene('Correct a saved check-in','Rohan + Het','D2 I2','lib/ui/editors.dart','Future<void> _save()',
      'Explain the second entity form and date/progress/status validation. Show real correction tests; do not claim the sidebar is a correction run.',still('08_history'),line=221)
scene('Filters and an honest summary denominator','Rohan','D2','lib/ui/bloom_app.dart','var opportunities = 0;',
      'Explain active habits, elapsed eligible days and creation dates. Show the filter and distinguish the weekly rate from garden lifetime completions.',clip(120,8))
scene('Settings call persistence','Rohan','I2 D2','lib/ui/bloom_app.dart','List<Widget> _preferences(',
      'Show the three actual settings. Explain default daily target, week start and reduced motion, and how changes reach the gateway.',clip(128,9))
scene('Preferences: validate and await the write','Het','A1 D2','lib/data/settings_store.dart','Future<void> save(',
      'Explain the versioned value, validation and failed-write cache recovery. Retained release logs prove restart restoration on both AVDs.',still('09_settings'))
scene('Helper inputs and calendar window','Het','R4','lib/helper/goal_suggestion.dart','final end = localDay(today);',
      'Explain local calendar dates, the inclusive fourteen-day window and distinct saved tracked days. The actual sidebar correctly abstains with sparse history.',still('11_helper_abstention'))
scene('The explainable offline calculation','Het','R4','lib/helper/goal_suggestion.dart','final goal = tracked < 7',
      'Explain eligibility, completed days divided by two, half-up rounding and the 1-7 clamp. Eight completions yields four days/week.',still('11_helper_abstention'))
scene('Apply prefills; only Save persists','Rohan + Het','R4 I2','lib/ui/habit_detail.dart',None,
      'Explain Apply and Not now. Apply is disabled in this sparse-history capture. Actual eligible Apply/Cancel/Save coverage is in retained Android tests.',still('11_helper_abstention'),line=331)
scene('Helper edge cases and tests','Het','T1 R4','test/helper/goal_suggestion_test.dart','void main()',
      'Show real expected outputs for missing history and seven unfinished tracked days. Explain synthetic inputs and how invalid data is rejected.',still('11_helper_abstention'))
scene('Evaluation includes a counterexample','Het','R4','AI_FEATURE.md','## Benefit, rationale and alternative',
      'Report the actual paired synthetic n=8 plus one abstention. Helper MAE1.875; fixed baseline1.625. Baseline performed better on these cases.',still('11_helper_abstention'))
scene('Fresh host results: all33 pass','Both','T1','verification/host_rerun_2026-10-28/tests.txt',None,
      'Show actual October28 output. These commands were AI-executed under student direction. Explain one data test and one UI test in your own words.',still('05_finished'),tail=True)
scene('Android acceptance and retained evidence','Both','T1 T2','TEST_LOG.md','| `flutter test integration_test/',
      'Distinguish retained October26 two-AVD results from the new host rerun. Both profiles use Android17; no physical-device/older-OS claim.',evidencepic('01_today_offline_after_process_restart'))
scene('Async safety and lifecycle cleanup','Rohan','T2 A1','lib/ui/habit_detail.dart','Future<void> _act(',
      'Explain busy guards, changed dates, mounted checks, actionable errors and awaited reloads. Connect disposal behavior to startup tests.',still('04_partial_progress'))
scene('Responsive forms and accessibility','Rohan','T1 I1','lib/ui/widgets.dart','class ContentColumn extends StatelessWidget',
      'Explain scrollable forms, keyboard dismissal and semantics. Show retained actual large-text/rotation evidence and describe coverage limits.',evidencepic('06_rotated_large_text'))
scene('Release build: real artifact, real logs','Both','T2','TEST_LOG.md','## APK identity',
      'Show the real release build result and SHA256. Discuss the repaired Kotlin cache failure and disclosed debug signing; no new release build is claimed.',still('10_today_completed'),35)
scene('Real contribution history','Both','R1','full_walkthrough/ACTUAL_GIT_HISTORY.txt',None,
      'Each student explains their actual work and PRs. File workstreams do not establish manual authorship or20 meaningful commits/member.',still('03_saved_habit'),35)
scene('Switch to your genuine ClickUp trace','Both','R1','HUMAN_INPUT_REQUIRED.md',None,
      'The board was inaccessible to this agent. Show your real task-to-commit/PR-to-code/test trace now. Do not recreate historic board states.',still('10_today_completed'),35)
scene('Both voices, selected questions, final checks','Both','I1 I2 A1 A2 D1 D2 T1 T2 R1 R4','TESTING_LABELS_AND_RERUN.md',None,
      'Finish the real team explanation. Verify all ten IDs were addressed. Add genuine signatures, board/peer evidence and final recording URL before individual uploads.',still('10_today_completed'),55)
assert len(scenes)==35 and sum(s['seconds'] for s in scenes)==1380

FONT=Path('C:/Windows/Fonts')
def font(size,bold=False,mono=False):return ImageFont.truetype(str(FONT/('consolab.ttf' if mono and bold else 'consola.ttf' if mono else 'segoeuib.ttf' if bold else 'segoeui.ttf')),size)
def wrapped(draw,text,xy,width,ft,color,leading,maxlines=None):
    x,y=xy; words=text.split(); lines=[]; line=''
    for word in words:
        candidate=(line+' '+word).strip()
        if draw.textlength(candidate,font=ft)>width and line:lines.append(line);line=word
        else:line=candidate
    if line:lines.append(line)
    for i,l in enumerate(lines[:maxlines] if maxlines else lines):draw.text((x,y+i*leading),l,font=ft,fill=color)
    return len(lines)*leading
def timestamp(s):return f'{int(s)//60:02d}:{int(s)%60:02d}'

sources=[];timeline=[];time_cursor=0
guide=Document();guide.styles['Normal'].font.name='Aptos';guide.styles['Normal'].font.size=Pt(11)
guide.add_heading('Bloom: narrate the actual app and code',0)
guide.add_paragraph('One shared video with both speakers. This23-minute visual walkthrough combines saved source with real recorded app interactions, followed by paused views. It is not live typing, a live editor session or student narration. Both students must explain actual work and provide genuine board/peer/reflection evidence. Use the timeline below and keep the final recording within20-25 minutes.')
guide.add_paragraph('Classification under the latest supplied guidance: Human–AI Testing, student-directed and AI-executed. The student requested/directed work in chat; Codex ran commands. No personal manual execution or observation of each run is asserted.')
for index,s in enumerate(scenes,1):
    source=path(s['file']);blob=source.read_bytes();raw=blob.decode('utf-16' if blob.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig',errors='replace');raw=re.sub(r'\x1b\[[0-9;]*[A-Za-z]','',raw)
    lines=raw.splitlines()
    if s['line']:first=s['line']-1
    elif s['tail']:first=max(0,len(lines)-19)
    elif s['anchor']:
        first=next(i for i,l in enumerate(lines) if s['anchor'] in l); first=max(0,first-2)
    else:first=0
    excerpt=lines[first:first+25]
    image=Image.new('RGB',(1920,1080),'#FAF8F2');draw=ImageDraw.Draw(image)
    draw.rectangle((0,0,1920,8),fill='#285F4D')
    draw.text((36,25),s['title'],font=font(37,True),fill='#285F4D')
    who=('ROHAN: UI / INTEGRATION' if s['speaker']=='Rohan' else 'HET: DATA / HELPER' if s['speaker']=='Het' else 'BOTH WORKSTREAMS')
    draw.text((38,86),f'{index:02d}/35  |  {timestamp(time_cursor)}-{timestamp(time_cursor+s["seconds"])}  |  {who}  |  Questions: '+', '.join(s['questions']),font=font(20,True),fill='#325D4F')
    draw.text((40,134),s['file'],font=font(21,True,True),fill='#243C32')
    draw.rounded_rectangle((32,175,1352,875),radius=14,fill='#162A24')
    draw.text((52,187),f'SAVED SOURCE / EVIDENCE    |    code snapshot {HEAD[:7]}',font=font(17,True,True),fill='#98C7AF')
    y=226;last=first+1
    for offset,line in enumerate(excerpt):
        n=first+offset+1
        parts=textwrap.wrap(line.expandtabs(2),width=94,replace_whitespace=False,drop_whitespace=False) or ['']
        for j,part in enumerate(parts):
            if y>844:break
            if j==0:draw.text((50,y),f'{n:4}',font=font(20,mono=True),fill='#789D8C')
            color='#D8E8E0'
            st=part.lstrip()
            if st.startswith(('//','#','///')):color='#8DC9A0'
            elif any(k in part for k in ('Future<','class ','final ','return ','await ','if (','throw ')):color='#C2E8C3'
            draw.text((117,y),part,font=font(20,mono=True),fill=color)
            y+=24;last=n
        if y>844:break
    draw.text((1398,111),'ACTUAL RECORDED APP',font=font(21,True),fill='#285F4D')
    draw.rounded_rectangle((1408,132,1852,1015),radius=20,fill='#DDE7DC')
    wrapped(draw,s['note'],(42,895),1290,font(24),'#243C32',31,4)
    draw.text((1400,1020),'Playback / paused view | [DEMO]/[TEST] data',font=font(16),fill='#325D4F')
    draw.text((40,1048),'SILENT VISUAL WALKTHROUGH  |  Both students narrate  |  Human–AI Testing: student-directed, AI-executed',font=font(18,True),fill='#285F4D')
    frame=WORK/f'scene_{index:02d}.png';image.save(frame)
    if index in (1,9,16,28):image.save(OUT/f'preview_{index:02d}.png')
    source_info={'file':s['file'],'first_line':first+1,'last_displayed_line':last,'sha256':hashlib.sha256(source.read_bytes()).hexdigest().upper()}
    sources.append(source_info)
    s.update(index=index,start_seconds=time_cursor,end_seconds=time_cursor+s['seconds'],source=source_info)
    timeline.append(s);time_cursor+=s['seconds']
    guide.add_heading(f'{timestamp(s["start_seconds"])}-{timestamp(s["end_seconds"])} | {s["title"]}',1)
    guide.add_paragraph('Suggested speaker: '+s['speaker']+' | Selected questions: '+', '.join(s['questions']))
    guide.add_paragraph(s['note']);guide.add_paragraph(f'Saved source/evidence: {s["file"]}, lines{first+1}-{last}.')
    if index in (2,33,34):guide.add_paragraph('Supply your own truthful contribution/process explanation. The video cannot establish human review, historic board activity or a peer observation.')
guide.save(OUT/'NARRATION_AND_SCREEN_SWITCH_GUIDE.docx')
(OUT/'SCENE_TIMELINE.json').write_text(json.dumps({'duration_seconds':1380,'source_snapshot':HEAD,'silent':True,'live_editor_recording':False,'required_team_presentation_complete':False,'scenes':timeline},indent=2)+'\n',encoding='utf-8')

segments=[]
for s in timeline:
    idx=s['index'];segment=WORK/f'segment_{idx:02d}.mp4';segments.append(segment)
    app=s['app'];app_path=Path(app['path']);assert app_path.is_file(),app_path
    args=[FFMPEG,'-hide_banner','-y','-loglevel','warning','-loop','1','-framerate','10','-i',str(WORK/f'scene_{idx:02d}.png')]
    if app['kind']=='video':args+=['-ss',str(app['start']),'-i',str(app_path)];video_filter=f'trim=duration={app["length"]},setpts=PTS-STARTPTS,'
    else:args+=['-loop','1','-framerate','10','-i',str(app_path)];video_filter=''
    filt=f'[1:v]{video_filter}scale=400:866:flags=lanczos,setsar=1,fps=10,tpad=stop_mode=clone:stop_duration={s["seconds"]}[app];[0:v][app]overlay=1430:140:shortest=1,format=yuv420p[v]'
    args+=['-filter_complex',filt,'-map','[v]','-t',str(s['seconds']),'-an','-c:v','libx264','-preset','veryfast','-crf','23','-threads','4','-movflags','+faststart',str(segment)]
    print(f'Rendering {idx:02d}/35: '+s['title'],flush=True)
    with (WORK/f'encode_{idx:02d}.log').open('w') as log:subprocess.run(args,check=True,stdout=log,stderr=subprocess.STDOUT)
concat=WORK/'segments.txt';concat.write_text(''.join("file '"+p.as_posix()+"'\n" for p in segments),encoding='utf-8')
output=OUT/'Bloom_23min_App_and_Code_Walkthrough.mp4'
subprocess.run([FFMPEG,'-hide_banner','-y','-loglevel','warning','-f','concat','-safe','0','-i',str(concat),'-c','copy','-movflags','+faststart',str(output)],check=True)
commands=[{'kind':'encoder','command':FFMPEG,'version':imageio_ffmpeg.get_ffmpeg_version(),'scene_count':35,'fps':10,'size':'1920x1080','audio':'none'}]
(OUT/'ENCODING_PROVENANCE.json').write_text(json.dumps(commands,indent=2)+'\n',encoding='utf-8')
(OUT/'READ_ME_FIRST.txt').write_text('''BLOOM - FULL APP AND SOURCE WALKTHROUGH

Bloom_23min_App_and_Code_Walkthrough.mp4 is a silent23-minute visual aid with35 source/evidence chapters and actual recorded release-app interactions on the right. During explanations, captured app frames are held still. Source panels contain exact saved files with line numbers, not a live editor or newly typed code. Actual code/evidence hashes and sources are in SCENE_TIMELINE.json.

The video labels Rohan UI/integration and Het data/helper workstreams; both used Codex assistance. These labels do not fabricate manual authorship or personal participation. Actual Git history is included. Human–AI Testing means student-directed, AI-executed: the student requested/directed testing in chat; Codex executed the commands. Direct manual execution or a peer observation is not claimed.

Record ONE shared-screen video with both student voices. Use NARRATION_AND_SCREEN_SWITCH_GUIDE.docx. Explain the actual code naturally and switch to your real ClickUp/GitHub task trace when prompted; that board was inaccessible to the agent and is not fabricated here. The video alone is not a completed student presentation or proof of either student's answers, learning, review or attendance. Keep final duration20-25 minutes; do not append a second long speech.

Upload the exact questions-only Word selection before the required team recording. All10 IDs are mapped across the video. Supply actual signatures, peer/board evidence, instructor access and the genuine final uploaded presentation URL, then regenerate the ZIP. This visual recording does not resolve those missing evidence items or the20 meaningful commits/member shortfall.

Fresh October28 host results: formatter/analyzer pass,33 tests pass. Original two-AVD acceptance and release evidence remains datedOctober26. No new Android suite or release build is implied. Real [DEMO] capture includes form rejection, explicit Save, partial progress, completion and canceled Reset/delete confirmations. Demo interactions are separate from counted test-suite results.
''',encoding='utf-8')
print('FINISHED: '+str(output),flush=True)

import re
#!/usr/bin/env python3
"""Static release audit for ONE MORE LIFE. No Godot runtime required.

Static only: it cannot catch a syntax error or a runtime fault. Pair it with
tools/v08_system_test.tscn and tools/v08_echo_test.tscn, which need Godot."""
from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]; warnings=[]; ids={}; events=[]; schedules=[]; scheduled_sources=set()
for path in sorted((ROOT/'data/events').glob('*.json')):
    try: data=json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc:
        errors.append(f'{path.name}: JSON error: {exc}'); continue
    if not isinstance(data,list): errors.append(f'{path.name}: root is not a list'); continue
    for e in data:
        eid=e.get('id','') if isinstance(e,dict) else ''
        if not eid: errors.append(f'{path.name}: missing event id'); continue
        if eid in ids: errors.append(f'duplicate event id {eid}: {ids[eid]} and {path.name}')
        ids[eid]=path.name; events.append(e)
        for c in e.get('choices',[]):
            for o in c.get('outcomes',[]):
                if 'schedule' in o:
                    target=o['schedule'].get('event',''); schedules.append((eid,target)); scheduled_sources.add(eid)
for src,target in schedules:
    if target not in ids: errors.append(f'{src}: missing scheduled target {target}')

proj=(ROOT/'project.godot').read_text(encoding='utf-8')
for rel in re.findall(r'\*res://([^"\n]+)',proj):
    if not (ROOT/rel).exists(): errors.append(f'missing autoload/script: {rel}')
import re as _re
_ver = _re.search(r'config/version="([^"]+)"', proj)
if not _ver: errors.append('project.godot has no config/version')
PROJECT_VERSION = _ver.group(1) if _ver else '?'
if 'Ambition="*res://autoload/ambition.gd"' not in proj: errors.append('Ambition autoload is not registered')

# Every new milestone must meet the depth rule on its own even while legacy
# event files are gradually brought up to the 1.0 target.
def strict_file(name, min_schedule=.25):
    p=ROOT/'data/events'/name
    if not p.exists(): errors.append(f'missing {name}'); return (0,0,0)
    data=json.loads(p.read_text(encoding='utf-8'))
    for e in data:
        if len(e.get('choices',[]))<3: errors.append(f"{e['id']}: {name} event has <3 choices")
        for c in e.get('choices',[]):
            if len(c.get('outcomes',[]))<2: errors.append(f"{e['id']} / {c.get('label')}: {name} choice has <2 outcomes")
    scheduled=sum(any('schedule' in o for c in e.get('choices',[]) for o in c.get('outcomes',[])) for e in data)
    if data and scheduled/len(data)<min_schedule: errors.append(f'{name} scheduled-followup rate below {min_schedule:.0%}')
    outcomes=sum(len(c.get('outcomes',[])) for e in data for c in e.get('choices',[]))
    return len(data),outcomes,scheduled

v07n,v07o,v07s=strict_file('v07.json',.25)
v08n,v08o,v08s=strict_file('v08.json',.25)

# Parse every top-level data file too; v0.8 adds achievements that depend on
# counters emitted by the new systems.
for path in sorted((ROOT/'data').glob('*.json')):
    try: json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc: errors.append(f'{path.name}: JSON error: {exc}')
try:
    achievements=json.loads((ROOT/'data/achievements.json').read_text(encoding='utf-8'))
    v8ach=[a for a in achievements if a.get('v')==8]
    if len(v8ach)<18: errors.append('v0.8 achievement set is unexpectedly small')
    aid=[a.get('id','') for a in achievements]
    if len(aid)!=len(set(aid)): errors.append('duplicate achievement ids')
except Exception:
    v8ach=[]

expected=[
 'autoload/ambition.gd','autoload/expansion.gd','autoload/life_threads.gd',
 'scenes/minigames/mg_evidence.gd','scenes/minigames/mg_surgery.gd',
 'tools/event_validator.gd','tools/v08_system_test.gd','tools/v08_system_test.tscn',
 'data/events/v08.json'
]
for rel in expected:
    if not (ROOT/rel).exists(): errors.append(f'missing v0.8 file: {rel}')

# Verify every minigame definition points at a real script.
mg=(ROOT/'autoload/minigames.gd').read_text(encoding='utf-8')
for rel in re.findall(r'"script"\s*:\s*"res://([^"\n]+)"',mg):
    if not (ROOT/rel).exists(): errors.append(f'min igame definition points to missing script: {rel}')
for gid in ['evidence','surgery']:
    if f'"{gid}"' not in mg: errors.append(f'missing minigame definition: {gid}')

# Integration hook sanity checks.
hooks={
 'autoload/event_engine.gd':['Ambition.yearly()','Ambition.event_condition(cond)','Ambition.outcome(o["ambition"], roles)'],
 'scenes/menu_panels.gd':['"amb": return Ambition'],
 'autoload/careers.gd':['Ambition.sports_actions(c)','Ambition.sports_yearly(c, p, perf)'],
 'scenes/main.gd':['MP.open("amb:work")','MP.open("amb:enterprise")','MP.open("amb:pet/"'],
 'autoload/actions.gd':['"amb:pets"','"amb:justice"'],
 'autoload/law.gd':['"kind":"court_case"'],
}
for rel,needles in hooks.items():
    text=(ROOT/rel).read_text(encoding='utf-8')
    for n in needles:
        if n not in text: errors.append(f'{rel}: missing integration hook {n}')

amb=(ROOT/'autoload/ambition.gd').read_text(encoding='utf-8')
if 'LifeThreads.add(' in amb: errors.append('Ambition still calls nonexistent LifeThreads.add')
for fn in ['police_new_case','medical_new_patient','pet_breed','sports_yearly','enterprise_start','justice_appeal','career_project']:
    if f'func {fn}' not in amb: errors.append(f'Ambition missing function {fn}')

# Quick delimiter sanity for edited GDScript. This is not a parser, but catches
# accidental truncation/bracket damage before packaging.
def balanced(path):
    text=path.read_text(encoding='utf-8')
    stack=[]; pairs={')':'(',']':'[','}':'{'}; opens=set(pairs.values())
    i=0; quote=None; triple=False
    while i<len(text):
        ch=text[i]
        if quote:
            if ch=='\\': i+=2; continue
            if triple:
                if text.startswith(quote*3,i): quote=None; triple=False; i+=3; continue
            elif ch==quote: quote=None
            i+=1; continue
        if text.startswith('"""',i) or text.startswith("'''",i):
            quote=text[i]; triple=True; i+=3; continue
        if ch in ('"',"'"):
            quote=ch; i+=1; continue
        if ch=='#':
            j=text.find('\n',i); i=len(text) if j<0 else j+1; continue
        if ch in opens: stack.append(ch)
        elif ch in pairs:
            if not stack or stack[-1]!=pairs[ch]: return False
            stack.pop()
        i+=1
    return not stack and quote is None
for rel in ['autoload/ambition.gd','autoload/event_engine.gd','autoload/law.gd','autoload/careers.gd','scenes/main.gd','scenes/minigames/mg_evidence.gd','scenes/minigames/mg_surgery.gd','tools/v08_system_test.gd']:
    if not balanced(ROOT/rel): errors.append(f'{rel}: unbalanced delimiters/quotes')

summary={
 'events_total':len(events),
 'choices_total':sum(len(e.get('choices',[])) for e in events),
 'outcomes_total':sum(len(c.get('outcomes',[])) for e in events for c in e.get('choices',[])),
 'scheduled_source_events':len(scheduled_sources),
 'scheduled_pct':round(100*len(scheduled_sources)/max(1,len(events)),1),
 'v07_events':v07n,'v07_outcomes':v07o,'v07_scheduled_sources':v07s,
 'v08_events':v08n,'v08_outcomes':v08o,'v08_scheduled_sources':v08s,'v08_achievements':len(v8ach),
 'errors':len(errors),'warnings':len(warnings)
}

EXTRA = {}
# ---- v0.9 data integrity -------------------------------------------------
import json as _json, os as _os
_root = _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__)))

def _read(rel):
    with open(_os.path.join(_root, rel), encoding='utf-8') as fh:
        return _json.load(fh)

try:
    _countries = _read('data/countries.json')
    _names = _read('data/names.json')['buckets']
    for _c in _countries:
        if _c.get('bucket') not in _names:
            errors.append("country %s uses missing name bucket '%s'" % (_c['id'], _c.get('bucket')))
        if not _c.get('currency') or not _c.get('rate'):
            errors.append('country %s has no currency or rate' % _c['id'])
    EXTRA['countries'] = len(_countries)

    _lic = _read('data/licenses.json')
    _q = 0
    for _k, _spec in _lic.items():
        _bank = _spec.get('bank', [])
        _q += len(_bank)
        if len(_bank) < _spec.get('needed', 5):
            errors.append("licence '%s' asks more questions than it holds" % _k)
        for _item in _bank:
            _opts = _item.get('a', [])
            if len(_opts) < 2 or not (0 <= _item.get('correct', -1) < len(_opts)):
                errors.append("licence '%s' has a malformed question" % _k)
            if not _item.get('why'):
                errors.append("licence '%s' has a question with no explanation" % _k)
    EXTRA['licence_tests'] = len(_lic)
    EXTRA['licence_questions'] = _q

    _places = open(_os.path.join(_root, 'autoload/places.gd'), encoding='utf-8').read()
    _climate = open(_os.path.join(_root, 'autoload/climate.gd'), encoding='utf-8').read()
    _region_ids = set(re.findall(r'\{"id": "(\w+)", "name":', _places))
    _block = _climate.split('const REGION_CLIMATE := {')[1].split('}')[0]
    _mapped = set(re.findall(r'"(\w+)"\s*:\s*"\w+"', _block))
    _missing = sorted(_region_ids - _mapped)
    if _missing:
        errors.append('regions with no climate: %s' % ', '.join(_missing))
    EXTRA['regions'] = len(_region_ids)
except Exception as _e:
    errors.append('v0.9 data check failed: %s' % _e)

summary['project_version']=PROJECT_VERSION
summary.update(EXTRA)
summary['errors']=len(errors)
print(json.dumps(summary,indent=2))
if warnings:
    print('\nWARNINGS:'); print('\n'.join('- '+w for w in warnings))
if errors:
    print('\nERRORS:'); print('\n'.join('- '+e for e in errors)); sys.exit(1)
print('\nSTATIC AUDIT: PASS')

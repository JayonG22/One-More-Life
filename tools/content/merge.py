#!/usr/bin/env python3
"""Merges authored alternate outcomes into data/events/*.json.
Line format (tools/content/patches/<file>.txt):
  event.id :: Exact choice label :: Outcome text :: stat=n,stat=n [:: key=json ...]
Extra fields after effects are key=JSON pairs (e.g. relationship={"nb":-10}).
A trailing '@3' on the effects field sets the outcome weight. Idempotent: a choice
that already has 2+ outcomes is skipped; unmatched lines are reported."""
import json, sys, os, re
ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
def parse_fx(s):
    w = 1
    m = re.search(r'@(\d+)\s*$', s)
    if m: w = int(m.group(1)); s = s[:m.start()]
    fx = {}
    for kv in filter(None, (p.strip() for p in s.split(','))):
        k, v = kv.split('=')
        fx[k.strip()] = int(v)
    return fx, w
bad = 0; added = 0
for fn in sorted(os.listdir(os.path.join(ROOT, 'tools/content/patches'))):
    if not fn.endswith('.txt'): continue
    name = fn[:-4]
    path = os.path.join(ROOT, 'data/events', name + '.json')
    data = json.load(open(path))
    idx = {e['id']: e for e in data}
    for ln, line in enumerate(open(os.path.join(ROOT, 'tools/content/patches', fn)), 1):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'): continue
        parts = [p.strip() for p in line.split(' :: ')]
        if len(parts) < 4: print(f'{fn}:{ln}: malformed'); bad += 1; continue
        eid, label, text, fxs = parts[:4]
        ev = idx.get(eid)
        ch = next((c for c in ev.get('choices', []) if c['label'] == label), None) if ev else None
        if not ch: print(f'{fn}:{ln}: no match {eid} / {label}'); bad += 1; continue
        fx, w = parse_fx(fxs)
        o = {'text': text, 'weight': w, 'effects': fx}
        for extra in parts[4:]:
            k, v = extra.split('=', 1); o[k] = json.loads(v)
        if o['text'] in [x['text'] for x in ch['outcomes']]: continue
        ch['outcomes'].append(o); added += 1
    json.dump(data, open(path, 'w'), indent=1, ensure_ascii=False)
    open(path, 'a').write('\n')
print(f'added {added}, problems {bad}')

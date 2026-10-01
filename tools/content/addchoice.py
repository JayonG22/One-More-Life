#!/usr/bin/env python3
"""Adds authored third choices to events that have fewer than three.
Line format (tools/content/choices.txt):
  event.id :: New choice label :: outcome text :: stat=n,stat=n :: outcome text :: stat=n [:: ...]
Pairs of (text, effects) after the label; each choice must get at least two. Idempotent."""
import json, glob, os, re, sys
ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
def fx(s):
    d = {}
    for kv in filter(None, (p.strip() for p in s.split(','))):
        k, v = kv.split('='); d[k.strip()] = int(v)
    return d
index = {}
for f in glob.glob(os.path.join(ROOT, 'data/events/*.json')):
    data = json.load(open(f)); index[f] = data
by_id = {e['id']: (f, e) for f, d in index.items() for e in d}
added = bad = 0
for ln, line in enumerate(open(os.path.join(ROOT, 'tools/content/choices.txt')), 1):
    line = line.strip()
    if not line or line.startswith('#'): continue
    parts = [p.strip() for p in line.split(' :: ')]
    eid, label, rest = parts[0], parts[1], parts[2:]
    if eid not in by_id: print(f'line {ln}: no event {eid}'); bad += 1; continue
    f, e = by_id[eid]
    if len(rest) < 4 or len(rest) % 2: print(f'line {ln}: needs text/effects pairs ({eid})'); bad += 1; continue
    if any(c['label'] == label for c in e['choices']): continue
    outs = [{'text': rest[i], 'weight': 1, 'effects': fx(rest[i + 1])} for i in range(0, len(rest), 2)]
    e['choices'].append({'label': label, 'outcomes': outs}); added += 1
for f, d in index.items():
    json.dump(d, open(f, 'w'), indent=1, ensure_ascii=False); open(f, 'a').write('\n')
print(f'added {added} choices, problems {bad}')

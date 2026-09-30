#!/usr/bin/env python3
"""Lists choices that still have a single outcome. Usage: thin.py [file ...]"""
import json, glob, os, sys
files = sys.argv[1:] or sorted(glob.glob('data/events/*.json'))
tot = 0
for f in files:
    f = f if f.endswith('.json') else f'data/events/{f}.json'
    for e in json.load(open(f)):
        for c in e.get('choices', []):
            if len(c['outcomes']) < 2 and 'play' not in c['outcomes'][0]:
                tot += 1
                o = c['outcomes'][0]
                print(f"{os.path.basename(f)[:-5]}|{e['id']}|{e.get('title','')}|{e['text'][:110]}|{c['label']}|{o['text'][:110]}|{json.dumps(o.get('effects',{}))}|{ {k:v for k,v in o.items() if k not in ('text','weight','effects')} }")
print('TOTAL', tot, file=sys.stderr)

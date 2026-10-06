# Content tools

Everything under `data/events/` that was authored in v0.15+ is generated from
scripts here, so it can be reviewed and regenerated. **Run order matters:**

1. `gen_real.py`, `gen_workbody.py`, `gen_arcs.py` — write `real.json`,
   `workbody.json`, `arcs.json`
2. `merge.py` — appends alternate outcomes from `patches/*.txt` into the
   hand-written event files (idempotent)
3. `addchoice.py` — appends third choices from `choices.txt` (idempotent)
4. `variants.py` — rewrites event openings with `{~a|b|c}` variants and
   `{fx.pub}` places (idempotent)
5. `gen_followups.py` — writes `echoes.json` **and wires `schedule` into the
   source events**, so it must run after the others

`thin.py` lists any choice that still has one outcome. The release gate
(`tools/run_gates.sh`) fails if any returns.

For v0.26 content, run `gen_contextual.py`, then `gen_worlds.py`, then
`gen_tv.py`. The first writes contextual events, follow-ups and additional
jobs; the second writes setting scenes and availability metadata on existing
events; the third writes TVLife's authored character arcs. Run these after the
earlier content pipeline so availability annotations are retained.

For v0.27, run `gen_mature.py` after that pipeline. It writes the additional
adult narrative scenes and their delayed consequences. `gen_tv.py` now keeps
stable story IDs and research references while generating the playful display
aliases. The `family_role` job is retained by `gen_contextual.py`; it represents
an imported NPC occupation and is excluded from advertised job listings.


For v0.28, run `gen_family_chronicle.py` after the earlier generators. It writes
56 family scenes across 14 authored arcs. Follow-up role specs use `bound: true`
and `allow_dead: true` because their text reflects on the original person rather
than presenting a new living encounter. The `family_memory` outcome writes an
NPC record; it does not transfer money. Keep ages, roles and branch prose aligned.

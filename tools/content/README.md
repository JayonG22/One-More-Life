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

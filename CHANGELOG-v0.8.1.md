# ONE MORE LIFE — v0.8.1 "Ambition & Society, stabilized"

This is the **runtime pass** v0.8.0 never had. v0.8.0 was built and packaged in an
environment without Godot, so it was validated by static JSON auditing only. That
audit reported `0 errors, 0 warnings` — and the build could not start.

Everything here was verified by actually running Godot 4.4.1.

---

## 1. The build now compiles

v0.8.0 did not. Every autoload failed to load, so the project could not boot at all.

| File | Line | Problem |
| --- | --- | --- |
| `autoload/event_engine.gd` | 195 | `LifeThreads.remember()` indented out of the `if` branch, breaking the `if/else` in the yearly divorce path |
| `autoload/expansion.gd` | 634 | `var bonus :=` inferred from a Variant |
| `autoload/expansion.gd` | 820 | `var title :=` inferred from a Variant |
| `autoload/expansion.gd` | 961 | `var role :=` inferred from a Variant |
| `autoload/expansion.gd` | 1096 | `var mut :=` inferred from a Variant |
| `autoload/ambition.gd` | 274 | `var sp :=` inferred from a Variant |
| `autoload/ambition.gd` | 295 | `var diagnosis :=` inferred from a Variant |
| `autoload/ambition.gd` | 614 | `var suspect :=` inferred from a Variant |
| `autoload/ambition.gd` | 967 | `var old := / var newt :=` inferred from a Variant |

The `event_engine.gd` fault was the root cause: with `EventEngine` failing to
compile, every `EventEngine.*` call site lost its return type, which produced six
further phantom errors in `world.gd`, `twists.gd` and `main.gd`. Those cleared on
their own once the real bug was fixed.

The divorce line was restored to the branch it belongs to, so a marriage ending now
records its Life Thread. Previously that code could never run.

## 2. The gate test was reporting a false pass

`tools/v08_system_test.tscn` printed `failures=0` while the **entire Sports Pro
section silently aborted on its first line**. It set
`GameState.player["skills"]["athletics"]` — neither `skills` nor `athletics` exists
anywhere in the project. The runtime error killed the function; the harness only
counted explicit assertion failures, so nothing was reported.

- Removed the phantom reference.
- The harness now records each section that runs to completion and **fails when a
  section aborts early**, so a runtime error can no longer masquerade as a pass.
- Output now reads `actions=39 sections=4/4 failures=0`.

## 3. Depth pass: the v0.8 careers now reach the rest of the life

The design rule is that a feature must feed at least three other systems. Measured
against it, v0.7's `expansion.gd` passed and v0.8's `ambition.gd` did not: 1,225
lines that never touched relationships, standing, credit, law or memory. Police,
Medicine, Sports, Pets and Enterprise were self-contained state machines writing
into `player["job"]`.

Calls from `ambition.gd` into other systems:

| System | Before | After |
| --- | --- | --- |
| Bonds (relationship memory) | 0 | 6 |
| Grit (grudges, credit, habits) | 0 | 12 |
| Life Threads | 1 | 17 |
| Expansion (health, mental health) | 12 | 18 |
| **Distinct systems touched** | **6** | **8** |

### Police
- A conviction gives the suspect a lasting grudge and a two-sided memory, and can
  create an aggrieved relative who carries their own grudge for years.
- An arrest made on thin evidence now costs a wrongful-arrest settlement, damages
  credit and karma, and writes a `regret` thread that can resurface later.
- Coming home injured from patrol costs closeness at home.

### Medicine
- Saving a severe case turns the patient into a friend who remembers it.
- A failed operation can now **lose the patient**, which triggers bereavement,
  feeds the v0.7 grief/mental-health system, and leaves a relative demanding answers.
- A settled malpractice claim damages credit and strains the household; a *pattern*
  of three or more claims triggers a medical board review.
- Burnout above 75 now reaches home and can seed a workaholism habit.

### Sports
- Championships pay a purse, move fame and popularity, become a life milestone and
  write a thread.
- Free agency pays a signing bonus; moving to a new team uproots and strains the family.
- Contact sports now cause real injuries that cut season form permanently.
- A rival is a person with a grudge and a thread, not a label.

### Pets
- **Pets now age out and die.** A pet's death registers as a real loss for the
  mental-health system, hits children's closeness, and leaves a grief thread.
- A support animal now reads the player's actual mental-health state and helps
  substantially more when they are genuinely struggling.

### Enterprise
- A bankruptcy costs 45 points of credit, strains the household, and sours the
  relationship with that company's CEO.
- Naming a successor now moves the chosen child closer and the passed-over children
  further away.

### Justice
- A conviction damages credit, reaches parents and marriage, and writes a thread
  that returns at background checks and applications.

### Life Threads
Four new thread kinds — `career`, `regret`, `money`, `justice` — each with its own
authored echo (3 choices, 2 outcomes each), rather than falling through to the
generic handler. Without these the new v0.8 threads would have silently collapsed
into `relationship` and merged with each other.

## 4. Other defects found and fixed

- `_pets_yearly` would have aged pets twice per year; the engine already ages every
  NPC in `event_engine.gd`.
- A parent-closeness loop used `npcs_with("parent")`, which matches nothing —
  parents are stored as `mother` and `father`.

## 5. New: `tools/v08_echo_test.tscn`

A second gate that proves the systems *reach*, not just that they run. 25 assertions
across 9 scenarios: wrongful arrest, conviction, malpractice pattern, pet death,
support animals, championships, bankruptcy, conviction records and thread-kind
registration. Each asserts observable change in another system.

```text
godot --headless --path . res://tools/v08_echo_test.tscn
V08 ECHO TEST checks=25 sections=9/9 failures=0
```

## 6. Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v08_system_test` | actions=39 sections=4/4 failures=0 |
| `v08_echo_test` | checks=25 sections=9/9 failures=0 |
| `sim_test` | 80 lives, 4,725 years, avg age 59.1, 0 errors |
| `career_test`, `empire_test`, `migrate_test` | 0 errors |
| `reach_test`, `menu_crawl`, `mg_bot`, `audio_test` | 0 errors |
| `release_audit.py` | PASS — 633 events, 1,547 choices, 2,233 outcomes, 0 errors |
| Boots to a playable life on a real display | yes |

## Known, not fixed

- `tools/ui_test.tscn` captures viewport screenshots and cannot complete under
  `--headless`. It runs under a real display but still stalls on its screenshot
  waits. It is a screenshot tool, not a gate — left as-is.
- Filling all 12 save slots correctly blocks a new life with "No free save slot".
  This is intended behaviour, but worth knowing: automated tool runs fill the slots,
  so clear `user://saves/` between test sessions.

## Still open for the v0.8 gate

`V0.8-TEST-PLAN.md` remains the manual gate. The automated work above does not
replace playing a detective through a cold case or a surgeon through a career.
Sections 3–10 of that plan still want a human.

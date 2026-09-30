# ONE MORE LIFE — v0.11.0 "What Finds You"

Verified in Godot 4.4.1. New gate: `tools/v11_system_test.tscn` —
**74 checks, 18/18 sections, 0 failures.** Every earlier gate still passes.

---

## 1. Life paths are no longer chosen

The new-life screen had a dropdown: Ordinary human, Royal, Vampire, Witch,
Gifted, Undead, Pirate Life, Space Colonist, Time Traveler. Picking one told you
the ending before the first age-up, and skipped the only genuinely interesting
part — the becoming.

**The picker is gone.** Everyone starts ordinary. Paths now find you.

### How they find you

Ordinary things leave a **lead**. Where you drink, what you read, the job you
take, the licence you hold, who you marry. Leads accumulate quietly across
decades — no progress bar, no checklist — and when one is ripe the world makes
you an offer.

| Doing this | Leans you toward |
| --- | --- |
| Nightlife, hospital work | Vampire |
| Library, meditation, crystal readings, chemistry | Witch |
| Lab work, the gym, volunteering | Gifted |
| Deep karma debt, people holding grudges | Undead |
| Fame, serious money, marrying a title | Royal |
| Deep-sea fishing, a boating licence, a berth | Pirate |
| Pilot or engineer work, the astronaut career | Space Colonist |
| Museums, archives, very high Smarts | Time Traveler |

Measured over 25 lives each:

- A life that **does nothing unusual**: **0 of 25** drifted into a path.
- A life spent **in bars and the occult section**: **33 vampires and 7 time
  travellers out of 40** in the wider run.

**You can always refuse, and refusing is final.** The gate proves a declined path
never comes back even with the lead force-fed for forty years.

The undead were already working this way — that life only ever began by *rising
after death*, never from the picker. My own test got that wrong first and had to
be corrected, which is the clearest possible argument that the rest should match it.

## 2. The vampire life, deepened

8 actions → **11**, and the state behind them is real.

**Four clans**, each a doctrine that changes the rules rather than a label:

| Clan | Upside | Cost |
| --- | --- | --- |
| House of Ash | Thirst grows slower | Your living family forgets you faster |
| The Veil | Hunters build a case far more slowly | Standing rises slowly |
| Crimson Court | Standing rises fast, compulsion lands harder | Hunters notice you quickly |
| The Quiet Ones | Karma and standing rise when you feed without killing | Feeding clears less Thirst |

The gate measures that the clan actually matters: over 8 years the Veil sat at
**45%** hunter evidence against the Crimson Court's **92%**.

**A sire.** A real, persistent person who turned you and has opinions about what
you have made of it. Present yourself and be judged.

**A rank ladder** — Fledgling → Kindred → Elder → Lord — needing *both* years
since turning *and* standing. The test proves 100% standing with no years behind
it promotes nobody, and that two centuries at full standing reaches Lord.

**A hunter** who works like the v0.8 detective from the other side of the glass:
evidence accrues year over year, you feel it coming through your neighbours and
a figure outside the building, and covering your tracks genuinely pushes the case
back. It ends four ways — you fight, you disappear to another city, you talk, or
they win. Talking can end with them walking away knowing exactly what you are.

Plus territory to claim, and a dawn you can test once you are Elder.

## 3. The undead life, deepened

4 actions → **6**, and everything the design doc promised and never built.

- **Body parts fall off.** A hand, a jaw, an eye, a leg, an ear — each with its
  own loss ("Half the room is a rumour") — and each replaceable with somebody
  else's, which you stop asking about.
- **A necromancer** who raised you and gives you orders every few years: fetch
  something out of a grave that is not empty, stand outside a house all night.
  Obey and the binding tightens; refuse and it loosens; do it while keeping one
  detail back if you are clever enough. When the binding is weak enough you can
  try to break it, and failing means watching yourself walk home from behind your
  own eyes.
- **Passing for living** decays every year. Let it slip and people look at you a
  second too long.
- **A crypt** you upgrade, from a drainage culvert to a private vault. It slows
  the rot: over six years a vault held passing at **100** against the culvert's
  **34**.

## 4. Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v11_system_test` | **checks=74 sections=18/18 failures=0** |
| `v10_system_test` | checks=35 sections=10/10 failures=0 |
| `v09_system_test` | checks=300 sections=17/17 failures=0 |
| `v08_system_test` / `v08_echo_test` | 4/4 and 9/9, 0 failures |
| `sim_test` | 80 lives, 4,562 years, avg age 57.0, 0 errors |
| `migrate_test` | 0 errors |
| `release_audit.py` | PASS |

## 5. Still owed

The other six paths have entry routes now but not the depth vampire and undead
just got — Royal court intrigue, Witch covens and spellbooks, Gifted powers and
a nemesis, Pirate crews and mutiny, colony politics, and era-specific content for
1850 / 1920 / 1970. Two per version, same pace. Full list in `OUTSTANDING.md`.

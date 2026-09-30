# ONE MORE LIFE — v0.10.0 "Between Us"

Verified in Godot 4.4.1. New gate: `tools/v10_system_test.tscn` —
**35 checks, 10/10 sections, 0 failures.** Every earlier gate still passes.

---

## The problem

One number did every job. `closeness`, 0–100, read in about two hundred places.

Whether your mother trusted you, whether your rival respected you, and whether
your wife still wanted you were all the same bar, moved by the same actions,
meaning nothing in particular. Giving somebody money and having a hard honest
conversation with them did the same thing to the same number.

## The split

An NPC's **own** stats — happiness, health, smarts, looks — are theirs. They
drift on their own and you do not maintain them.

A **bond's** stats are the thing between you, and they are what you actually
play:

| | What builds it | What it does |
| --- | --- | --- |
| 💗 **Affection** | Time together, gifts, kindness | Do they like you |
| 🤝 **Trust** | Keeping your word, confidences kept | Do they believe you |
| 🎖️ **Respect** | Competence, achievement, standing up | Do they rate you |
| 🔥 **Romance** | Partners only — separate from affection | Do they still want you |
| 💢 **Resentment** | Betrayal, insults, debts called in | What they hold against you |
| 📒 **Obligation** | Favours, loans, cover shifts | Who owes whom |

Each relation type carries only the stats it should. A boss has no romance
track. A dog is not judged on respect.

`closeness` still exists and still means what it meant — it is now **derived**
from the bond. All two hundred old call sites keep working and start telling the
truth about a richer model underneath.

## What this makes possible

Things the old model literally could not represent:

- **Adored and not believed.** Affection 100, trust 3.
- **Respected by someone who cannot stand you.** Respect 100, resentment 70,
  closeness 0.
- **A marriage with the romance gone.** The person screen now reads:
  *"🔥 nothing left of it · 💗 devoted to me · 🤝 would take my word on anything ·
  🎖️ respects me"* — which is a specific and very real way for a marriage to be.

## Different acts buy different things

Money used to buy affection. It does not any more — it buys **obligation**,
which is a debt somebody may come to resent.

- Lending money: **+20 obligation**, +2 trust
- A deep talk: **+6 trust**, +3 affection
- Spreading a rumour: **+16 resentment, −14 trust**
- Calling in what you are owed: **−22 obligation, +5 resentment**
- Sucking up to the boss: **−4 respect**

The gate test asserts specifically that cash cannot buy more affection than
actually talking to somebody.

## Affection fades. Trust doesn't.

Over twenty years with no contact, affection falls about 50 points while trust
and respect drop under 15. That is why an old friend you never call still thinks
well of you and no longer feels close — and the Family Ties boon slows it further
for relatives.

## Options you earned, not options you unlocked

Some actions are not on the menu by default and are not gated by age or money.
They exist because of how you have treated this person for years:

- **Tell them something true** — trust ≥ 78. *"Only because they have never repeated anything."* There is still a 22% chance they file it away somewhere.
- **Call in what they owe me** — obligation ≥ 45. They may pay, and something small goes out of the room with it. They may say they don't remember it that way.
- **Ask them to vouch for me** — respect ≥ 80. *"Their word carries where mine does not."*
- **Try to clear the air** — resentment ≥ 55. It works, or you get four sentences in before it becomes the same argument again.
- **Lean on them properly** — affection ≥ 82 and trust ≥ 60. *"The kind of asking you only get to do a few times."*
- **Prove them wrong about me** — respect ≤ 18 but affection ≥ 55. *"They love me and do not rate me."*

Two runs with the same family can have completely different options on this
screen. The gate test asserts that two different relationship histories do not
produce the same menu.

## Defect found and fixed

`tools/migrate6.tscn` needed a pre-v0.6 save that does not exist in a clean
checkout. With nothing to load it drove every menu with an **empty player**,
producing 20 script errors and hanging. This was present in v0.9 and earlier —
it had simply never been run to completion in a clean environment.

Both halves fixed: the tool now reports and stops when there is no legacy save,
and `Shop.menu()` / `_store_open()` no longer crash on an empty player.

## Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v10_system_test` | **checks=35 sections=10/10 failures=0** |
| `v09_system_test` | checks=300 sections=17/17 failures=0 |
| `v08_system_test` | actions=39 sections=4/4 failures=0 |
| `v08_echo_test` | checks=25 sections=9/9 failures=0 |
| `sim_test` | 77 lives, 4,479 years, avg age 58.2, 0 errors |
| `career_test`, `empire_test`, `migrate_test`, `migrate6`, `reach_test`, `reach6`, `menu_crawl`, `mg_bot`, `audio_test` | 0 errors |
| `release_audit.py` | PASS |

`tools/mg_smart.tscn` runs past a 240-second budget with zero script errors — it
plays every minigame in sequence and is simply slow. Not investigated further.

## Roadmap after this

Agreed split, so nothing gets crammed into a thin 1.0:

- **v0.11** — Prison Life: inmate *or* guard, ranks and hierarchy
- **v0.12** — Pets Life: animal simulation in this format
- **1.1 / 1.2** — further mode content
- Content depth — every activity carrying real content instead of a button — runs
  through all of them

## Still owed from earlier passes

- Hand-authored outcomes for the 865 deterministic v0.6 choices, and raising the
  293 events that have fewer than 3 choices
- Unique icons per category
- Job *positions* within a job
- Tombstone and graveyard redesign
- Cliques and school life as real panels

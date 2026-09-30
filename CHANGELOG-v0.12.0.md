# ONE MORE LIFE — v0.12.0 "Everyday"

Verified in Godot 4.4.1. New gate: `tools/v12_content_test.tscn` —
**633 checks, 0 failures.** Every earlier gate still passes.

No new systems. This is the content pass.

---

## 1. The file an ordinary life actually meets

`everyday.json` is the most-hit event file in the game — childhood, school,
first jobs, dates, neighbours, parents, pets, old age. It was also the worst
offender:

| | Before | After |
| --- | --- | --- |
| Choices with exactly one outcome | **180** | **0** |
| Events with fewer than 3 choices | **38** | **0** |
| Choices | 264 | **305** |
| Outcomes | 264 | **612** |

Every one of the 180 alternate outcomes is hand-written, and each is a
genuinely *different result* rather than the same sentence with worse numbers.
Some are better than the original. A few are much worse. Several are simply
sideways:

- Take the bullying rather than fight it → *"a kid I barely knew sat next to me
  every day until it stopped."*
- Work extra hard through the layoff rumours → *"I was cut anyway, in the second
  round, by someone who used the word regrettable."*
- Tell the truth when caught → *"it went far worse than lying would have. I have
  still not decided if it was right."*
- Take the stray to a shelter → *"I thought about it every day for a month, and
  then went back for it."*

The 38 thin events each gained a third choice with two outcomes of its own —
approaches the event did not previously allow, like negotiating with your
parents over potty training, handing the caught ball to the kid behind you, or
tracking down whoever owned the box in the attic.

**Whole library: 55.9% → 43.1% deterministic.** 293 → 258 thin events.

## 2. The tombstone

**A correction first.** v0.10's register claimed there was no tombstone. That was
wrong — one existed all along, but the code calls it `Tomb`, so searching for
"tombstone" found nothing and I reported it missing. The register has been fixed.

The real problem was that it was **one static card, identical for every life**. A
child, a pauper, a billionaire, a convict and a four-hundred-year-old vampire all
got the same rectangle.

The stone is now drawn, and read off the life:

- **Silhouette** — a small stub for a child, a plain round stone for most, a
  broken column for a life that ended badly with a record behind it, a gothic
  arch for the supernatural, a celtic cross past ninety, an obelisk for royalty
  or real fame, a mausoleum for serious money.
- **Material** — a wooden marker if you died with nothing, plain slab, ordinary
  stone, good granite, pale marble; burgundy, moss-green or violet if you were
  something other than human.
- **Weathering** scales with age; **moss** grows if you left children or kindness
  behind, and does not grow at all for a life nobody tends.
- **Ornament and epitaph** come from what the life was — *"Owned a great deal.
  Took none of it."*, *"Few came. Fewer stayed."*, *"Outlived everyone who could
  have said a word over this."*

The gate checks seven very different lives produce at least five distinct stones;
they currently produce all seven.

## 3. Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v12_content_test` | **checks=633 failures=0** |
| `v11_system_test` | checks=74 sections=18/18 failures=0 |
| `v10_system_test` | checks=35 sections=10/10 failures=0 |
| `v09_system_test` | checks=300 sections=17/17 failures=0 |
| `v08_system_test` / `v08_echo_test` | 4/4 and 9/9, 0 failures |
| `sim_test` | 80 lives, 4,617 years, avg age 57.7, 0 errors |
| `release_audit.py` | PASS |

## 4. Next

The same treatment, file by file, in traffic order: `twists.json` (107
deterministic), `lives.json` (80), `more.json` (83), `connections.json` (67).
Full table in `OUTSTANDING.md`.

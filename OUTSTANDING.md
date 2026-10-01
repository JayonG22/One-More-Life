# ONE MORE LIFE — outstanding work register

Everything asked for that is **not yet done**, kept in the repo so nothing gets
lost between versions. Each line says what it is and where it stands. When a
thing ships, it moves to that version's changelog and comes off this list.

Last reconciled against the code: v1.0.0.

---

## Closed in v0.15, v0.16 and v1.0

- **Content debt** — 284 one-outcome choices → 0; 84 events with fewer than three
  choices → 0; follow-up coverage 7.1% → 25.0%
- **Writing that repeats** — inline alternatives, named places, era vocabulary
- **The ordinary parts of a life** — renting, getting about, keeping up
- **Work** — a job market, hiring, workplaces, leaving, freelancing
- **Body** — a care pathway, medication, eyes, teeth, hearing, four slow accounts
- **Life paths** — chapters and endings for Royal, Witch, Gifted, Pirate, Colonist, Traveler
- **Accessibility** — keyboard play, labels, high contrast, text size, reduced motion
- **Minigames** — Negotiation and Road Test; boxing coached; all 22 proven winnable
- **Drawn icons** — 20 more, used across the new menus
- **Releases** — Windows, macOS and Linux builds from one command
- **A bug that hid 60 events** — `v08.json` was never in the loader's file list

## Still open

- **Real Windows and macOS hardware.** The Windows build was launched under Wine
  and the macOS build was exported and inspected; neither has been run on the
  real operating system by the author of this register. The Linux build was run
  natively.
- **macOS is unsigned.** First launch needs right-click → Open.
- **Interface size tops out at 130%.** The three-column layout needs about
  1,277 × 784 logical pixels; beyond 130% it would clip. A single-column layout
  for very large text is the real fix and is a post-1.0 item.
- **Economy.** Bankruptcies in the simulation rose about 13% against v0.14 after
  the real-life costs went in. Inside run-to-run noise, but worth a balance pass.
- **Streamline icons** — licensed; not used, by decision.

## Next

- **v1.3+** — see `ROADMAP.md`. Pets Life (v1.1) and Prison Life (v1.2) have shipped.

---

## Verified as ALREADY DONE (checked in code, not assumed)

These came up as worries but turned out to exist. Recorded so they don't get
rebuilt by mistake:

- **Life Story at death** — built from milestones (`main.gd`, "📜 Life Story")
- **Cliques / school life** — already a real panel with joinable cliques, clubs,
  sports, popularity and prom (`daily.gd`)
- **Extracurriculars** — exist and feed a job-application bonus
- **Auto theme on fame** — Celebrity look switches on at 88+ fame, toggleable
- **Auto theme per special life** — vampire/witch/royal/villain/superhero each
  switch the whole look, toggleable
- **Special lives reachable mid-life** — `Lives.become()` and the `"life"`
  outcome bridge both exist; 7 events use them. They were at weight 1, which is
  why nobody ever saw one. Raised to 6 in v0.10.
- **Job ladders** — every job has `ranks`; promotion works
- **Activity icons** — 69 unique across 79 top-level activities

---

## 1. Content depth — the biggest debt

**The core problem, measured.** At v0.11 this was 865 of 1,547 choices
(**55.9%**) with exactly one outcome. After the v0.12 and v0.13 passes it is
**284 of 1,760 (16.1%)**, and six files are fully compliant.

All the remaining debt is v0.6-era content. `v07.json` and `v08.json` were
always 0% deterministic.

The v0.9 uncertainty engine addresses the *feel* systemically — outcomes now
resolve against who the character is. **The written content is still owed.**

Priority order by how often a normal life meets the file:

| File | Choices | Deterministic | Events with <3 choices | Status |
| --- | --- | --- | --- | --- |
| `everyday.json` | 305 | **0** | **0** | done, v0.12 |
| `twists.json` | 174 | **0** | **0** | done, v0.13 |
| `lives.json` | 159 | **0** | **0** | done, v0.13 |
| `more.json` | 139 | **0** | **0** | done, v0.13 |
| `connections.json` | 111 | **0** | **0** | done, v0.13 |
| `empires.json` | 102 | **0** | **0** | done, v0.13 |
| `careers.json` | 84 | 58 (69%) | 28 | **next** |
| `careers2.json` | 72 | 51 (71%) | 20 | **next** |
| `adult.json` | 39 | 31 (79%) | 6 | |
| `family.json` | 33 | 27 (82%) | 8 | |
| `fame.json` | 22 | 19 (86%) | 2 | |
| `life.json` | 22 | 17 (77%) | 11 | |
| `school.json` | 25 | 17 (68%) | 1 | |
| `money.json` | 22 | 13 (59%) | 11 | |
| `work.json` | 21 | 13 (62%) | 3 | |
| `teen.json` | 19 | 11 (58%) | 3 | |
| `elder.json` | 9 | 8 (89%) | 3 | |
| `childhood.json` | 14 | 7 (50%) | 5 | |
| `law.json` | 11 | 6 (55%) | 4 | |
| `prison.json` | 8 | 6 (75%) | 1 | |

Guarded by `v13_moments_test`, which fails if any finished file slides back or
the library's deterministic share climbs above 17%.

## 2. Activities that are still buttons

Every one of these should have its own content the way Police and Medicine do —
relevant questions, real choices, sub-panels, not a click that moves a stat:

- **Martial arts** — belts, a dojo, a sensei, sparring, tournaments
- **Music / voice / acting lessons** — skill tracks that feed the career paths
- **Gardening, prayer, memory test, diet** — currently one-line outcomes
- **Entertainment (5 items)** and **Shopping (2 items)** are the thinnest groups
- **Love & Family (3 items)** — thin for a pillar of the genre
- **Education** — the biggest gap against the design doc: no per-subject content,
  no teacher relationships with memory, no cheating that surfaces years later

## 3. Systems asked for and not built

- **Job positions** — applying for a *position* within a job, with the 8–12
  generated yearly listings the design doc calls for. Ladders exist; the listings
  and position-level application do not.
- ~~**Tombstone** — does not exist.~~ **This was wrong.** A tombstone existed all
  along; the code calls it `Tomb`, so a search for "tombstone" found nothing and
  I reported it missing. Corrected in v0.12, where the real problem — one static
  card identical for every life — was fixed by drawing the stone from the life.
- **Graveyard presentation** — exists as data; needs the visual treatment.
- **"Monster Life" as a special-career category** — a discoverable route into the
  supernatural lives rather than only random Turning Points.
- **Hospital that cannot always help you** — a real chance treatment fails or is
  unavailable, per your request for challenge beyond BitLife.
- **More minigames** — only the pace control was added, not new games.
- **Per-country licence law variants** — banks are written but not forked by
  country (driving side, drinking age, firearm rules).
- **Some actions free of the time budget** — things you could realistically repeat
  in a year without spending a time point.
- **Better categorisation** — menus grouped so the contents are self-describing.

## 4. App / packaging

- **Windows .exe icon** — the build carries the game's own window icon, but
  embedding the icon into the executable file itself needs `rcedit`, which is not
  available in this build environment. Exporting from Godot on Windows will
  embed it.
- **macOS build** — not attempted.

## 5. Post-1.0, agreed

- **v0.11 — Prison Life**: playable as inmate *or* guard, ranks and hierarchy
- **v0.12 — Pets Life**: animal simulation in this format
- **1.1 / 1.2** — further mode content

---

## Standing rules these are measured against

From the design doc, and worth re-reading before calling anything finished:

1. Every event: **at least 3 choices, at least 2 outcomes per choice**, and 1 in 4
   scheduling a follow-up.
2. Every feature must **feed at least three other systems**.
3. A feature is not done because its buttons work — it is done when you can
   describe **three genuinely different life stories** it produced.
4. Structure and mechanics may follow the genre closely. **Text, art, names and
   specific storylines must be ours** — which is also what lets our events go
   deeper than a paid pack's.

---

## v0.11 update to this register

**Done since v0.10.1:**
- Vampire deepened: clans, sire, rank ladder, hunter who builds a case (8 → 11 actions)
- Undead deepened: body parts, necromancer, passing for living, crypt (4 → 6 actions)
- **Life paths are no longer picked at the new-life screen.** All eight are reached
  through play via the Destiny lead system, and any offer can be refused for good.

**Still owed on life paths** — these have entry routes now but not the depth that
vampire and undead just got:

- **Royal** — court intrigue, succession, approval, abdication
- **Witch** — covens, a spellbook that grows, potions, curses with karma cost
- **Gifted** — powers that level, secret identity, a nemesis with history
- **Pirate** — crew loyalty, rival captains, bounty, mutiny
- **Space Colonist** — colony politics, oxygen and rations as long-term pressure
- **Time Traveler** — era-specific content across 1850 / 1920 / 1970

Two per version, in that order, is the pace that worked for vampire and undead.


---

## v0.12 update to this register

**Done:**
- `everyday.json` brought fully up to the design rule: **180 deterministic
  choices → 0**, all hand-written; **38 thin events → 0**; the file grew from
  264 choices / 264 outcomes to **305 choices / 612 outcomes**.
- Whole library: **55.9% → 43.1%** deterministic, 293 → 258 thin events.
- Tombstone now drawn from the life — seven silhouettes, five materials,
  weathering by age, moss by who still visits, ornament and epitaph by what the
  life actually was.

**Content debt remaining**, in traffic order — the same method applies to each:

| File | Choices | Deterministic |
| --- | --- | --- |
| `twists.json` | 140 | 107 |
| `lives.json` | 121 | 80 |
| `more.json` | 100 | 83 |
| `connections.json` | 77 | 67 |
| `empires.json` | 75 | 64 |
| `careers.json` | 84 | 58 |
| `careers2.json` | 72 | 51 |

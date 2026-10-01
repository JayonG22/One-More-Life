# ONE MORE LIFE — v0.17.0

The baseline game is finished. This note says what that means and, as importantly,
what was and was not checked.

`tools/run_gates.sh` runs every automated check against a throwaway save folder
and prints one verdict. At release: **all 21 green.**

---

## What 1.0 adds to 0.16

### The six life paths have a road and an end

Vampire and undead had a shape to the life and a death that meant something.
Royal, Witch, Gifted, Pirate, Colonist and Time Traveler had entry routes, a
handful of actions, and then nothing — one pirate life ended exactly like another.

Each now has **five chapters that open on what you actually did** (not on the
calendar), a **turning-point event for each**, and **four to five endings picked
at death from the life as it ended**:

| Path | Chapters open on… | Endings |
| --- | --- | --- |
| Pirate | a first raid, a price on your head, two maps followed, the captaincy, a hold worth the name | Sea Legend · The Gallows · Mutinied Off · Retired with the Hold · The Sea Has the Rest |
| Colonist | a mission, two discoveries, influence, the signal's analysis, Founder | First Contact · Founder · The Dome Failed · Council Elder · Buried Under Another Sky |
| Traveler | cover, a first jump, artifacts, paradox, five jumps | Erased · The Quiet Historian · Stranded · Out of Step |
| Royal | respect, a decree, the crown, a decade, a reign remembered | A Reign Remembered · Deposed · Abdicated · A Short Reign · Never Crowned |
| Witch | a first spell, a circle, twenty spells, near-exposure, a coven of four | Found Out · Ascended · Matriarch · A Hedge Witch |
| Gifted | a first night out, a reputation, a nemesis, unmasking or power, a legend | An Icon · Infamous · Unmasked · A Quiet Hero |

The ending is written into the life story, onto the tombstone, and into
achievements (30 new). A monarch who is overthrown keeps the *Deposed* ending even
though the throne is gone. **30 new turning-point events, 90 choices.**

### Accessibility

- **Keyboard play.** Tab or an arrow key turns on keyboard navigation; Enter or
  Space selects; Esc goes back; 1–6 open the main menus. A mouse click turns it
  off again, so a clicked button never steals the next Space from "age up".
- **Labels.** Every button has text or a tooltip; the gate fails on one that has
  neither.
- **High contrast.** Secondary text goes from 7.2:1 to 12.2:1 against the
  background; outlines get heavier.
- **Interface size.** 90 / 100 / 115 / 130%. The three-column layout has a compact
  mode for narrow screens, and the gate checks that it fits at every size, both
  across and down. (This fixed a real problem: 130% used to clip the right-hand
  panel in the default window. 150% and 175% would still clip, so they are not
  offered.)
- **Reduced motion**, flashes and screen shake were already optional.

### Minigames

- **Two new.** *Negotiation* (used for job offers and rent): three rounds, a hidden
  limit, and replies that tell you how much room is left. *Road Test* (the
  practical half of the driving licence): three lanes, cones, pedestrians, red
  lights, no clock.
- **Boxing, which was confusing**, now coaches you in real time — *"He's swinging
  at your HEAD. Block HIGH now: press W"* — shows a large directional tell, pulses
  the button to press, and lengthens the first few telegraphs until you land a few
  blocks.
- **Every minigame is proven winnable.** A bot plays each of the 22 and the gate
  fails if the best of its runs doesn't clear 0.6, or if any game has no bot.
  (Two had no competent bot before: Evidence Board and Operating Room.)

### Content

- **45 delayed echo events**, wired into 142 source events, took follow-up
  coverage from 7.1% to **25.0%**: the wallet you kept, the tip you took, the
  boss you left, the funeral you skipped.
- **84 events** with fewer than three choices were given a genuinely different
  third. **Library: 760 events, 2,231 choices, 4,747 outcomes (about 63,000 words of outcomes).**

### Icons

20 more drawn icons (key, compass, envelope, bus, train, phone, pill, tooth,
eye, ear, handshake, anchor, hourglass, scroll, dome, hat, signpost, road,
calendar, pulse), used across every new menu. All original; see `CREDITS.md`.

### Releases

Windows, macOS and Linux from one export. The Windows build carries its icon and
version info (set with `rcedit` under Wine in the build environment).

---

## What was verified

| Check | Result |
| --- | --- |
| 21 automated gates (`tools/run_gates.sh`) | all green |
| A real v0.14 save loaded and played from 44 to 62–67 | 0 failures (`tools/mig_check.sh`) |
| A 300-year ageless life | 16 ms a year, 0.25 MB save, 8 ms load |
| Linux build, launched natively | boots, runs, exits clean |
| Windows build, launched under Wine | boots, runs, exits clean |
| macOS build | exported and inspected (`.app`, icon, 72 MB zip) |
| 546 text variants resolved | no raw braces anywhere |

## What was not

- **Not run on real Windows or macOS.** Wine is not Windows. Please tell me what
  you see.
- **macOS is unsigned**, so first launch needs right-click → Open.
- **Interface size is capped at 130%** (see above).
- **Balance.** The real-life costs make the simulation about 13% harsher on
  bankruptcies. A balance pass is the next thing worth doing.

## Bugs found and fixed on the way

- `v08.json` was never loaded, so 60 events never fired in a real game.
- The Windows and macOS export presets needed `import_etc2_astc` and a Wine-hosted
  `rcedit`; neither worked out of the box.
- Running the test suite filled the developer's real save slots, which then made
  "New Life" silently refuse to start. Tests now write to a throwaway folder
  (`OML_USER_DIR`).

## What comes next

**v0.18 Pets Life** and **v0.19 Prison Life**, designed in `ROADMAP.md`.

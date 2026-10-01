# ONE MORE LIFE — v0.20.0: Share, Legacy, Seeded Lives, The Outside

An improvement release across all three modes. No new mode (a Hospital Life was
proposed and dropped by decision: Pets and Prison stay the two standalone extras).

## New
- **Share this life.** The death screen can save a 1080×620 picture of the life and
  copy a text summary to the clipboard. Works for every mode.
- **Endings seen.** A log in the More panel of every ending in the game (50) and
  which you have found.
- **What past lives left.** A life now leaves echoes (famous, quarrelsome, loved a
  pet, did time, wore the uniform). Up to two find the next life you start, **in any
  mode**; each is used once.
- **Daily and weekly lives.** Two buttons on the title screen. The mode, person,
  family and place are fixed by the date; each has one goal and a score. The best
  score for the day is kept, and the share card names the day.
- **Prison: the outside.** Release no longer closes the story. Three years of being
  free: work, a place to live, family, a licence if paroled, old friends. Stability
  decides it. 12 new events, a new ending (**Back Inside**), and a menu of its own.
- **Pets: the pack.** Packmates, standing in the pack, challenging the leader, a
  mate and a litter, and pups as your next life ("My mother was…"). 19 new events.
- **Memories come back.** What people remember of you (good and bad, from big
  moments) is now brought up years later as a decision.
- **First-life tutorial** for each mode, shown once.

## Balance
- A second bankruptcy filing is not available for eight years; collections offer a
  settlement instead (half the debt, credit hit).

## Checked, and not
- **Checked:** `tools/run_gates.sh` (26 checks, including the new `v21_test`:
  endings log, share, legacy, seeded specs and scoring for all four modes, memory
  recall, 30 re-entry lives).
- **Not checked:** per-mode audio and a single-column large-text layout were
  considered and not built; controller play relies on Godot's default gamepad
  navigation and was not tested on a physical pad. Nothing has been played on real
  Windows or macOS hardware.

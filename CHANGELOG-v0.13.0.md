# ONE MORE LIFE — v0.13.0 "What It Felt Like"

Verified in Godot 4.4.1. New gate: `tools/v13_moments_test.tscn` —
**210 checks, 0 failures.** Every earlier gate still passes.

---

## 1. Presentation is now decided by what happened, not by reading the sentence

The design doc asked for a named, reusable vocabulary of effects — `money_gain`,
`money_loss`, `stat_gain`, `stat_loss`, `danger`, `success`, `failure`,
`achievement`, `death`, `relationship_gain`, `relationship_break`, `jackpot`,
`crime_heat`, `diagnosis` — "then any system can invoke them."

It did not exist. What existed was a function in `main.gd` that took the outcome
text, lower-cased it, and searched it for the strings `"promot"`, `"arrest"`,
`"baby"`, `"viral"`. That is wrong in **both** directions at once:

- an event whose text said *"I dreamed I was arrested"* got sirens and a
  screen shake;
- an event that quietly put a felony on your record got a polite tap, because
  nobody had happened to write the word "arrest" into the sentence.

**`autoload/moments.gd`** is the vocabulary, built properly. 30 named beats,
each one a sound, a particle burst, a flash and a shake, tuned in one place.
Anything in the game can now fire one: `Moments.fire("jackpot")`.

And the beats are chosen **structurally**. `EventEngine` already knew it had
applied a crime, an illness, a jail term, a marriage, a birth, a windfall — it
just never said so. It now returns a `signals` list with every outcome, built
by comparing the world before and after, and `Moments` reads that instead of
the prose.

The gate proves both halves of the bug are gone:

| Check | Result |
| --- | --- |
| An outcome that silently sets an illness, with text that never mentions it | fires **diagnosis** |
| Text about being arrested in a daydream, with nothing applied | fires **nothing** |
| A fine of $800 | fires **crime_heat** *and* **money_loss** |
| A cleared record | fires **freedom** |

**Intensity.** Every beat scales 0–1, and money reads off the actual delta
measured against what you have. $40 is silent, $300 is a coin, a windfall worth
most of your net worth is the full cascade, and $900,000 is the jackpot — which
does *not* also fire the ordinary money beat on top of it. A result that gains
happiness while costing health and calm no longer reads as a triumph.

**Loudness.** When several things happen at once, at most two beats play,
loudest first. Death outranks a coin sound. A diagnosis outranks finding money.
Being turned into a vampire outranks an achievement.

Transformations (vampire, witch, gifted, royal, rising undead) were hand-wired
in four different places in `main.gd` with hardcoded hex colours. They are named
beats now too.

## 2. The content depth pass: five more files finished

The design rule has been the same since v0.7: **every choice needs at least two
genuinely different outcomes, every event at least three choices, and a new
outcome must change what HAPPENS — not just how it is described.**

| File | Choices | Deterministic before | After | Outcomes |
| --- | --- | --- | --- | --- |
| `twists.json` | 140 → **174** | 107 | **0** | 173 → **349** |
| `lives.json` | 121 → **159** | 80 | **0** | 162 → **318** |
| `more.json` | 100 → **139** | 83 | **0** | 117 → **278** |
| `connections.json` | 77 → **111** | 67 | **0** | 87 → **222** |
| `empires.json` | 75 → **102** | 64 | **0** | 86 → **204** |

**The whole library: 43.1% deterministic → 16.1%.** (It was 55.9% at v0.11.)

Some of what that means in play:

- **Turning points can go the other way now.** Taking the plea for a crime you
  did not commit can schedule your exoneration eleven years later. Running from
  a cold case can be the confession they needed. A pardon can arrive and change
  nothing at all. Confessing can get your own confession thrown out.
- **The everyday events stayed small.** A second outcome in `more.json` is a
  small true swerve, not a melodrama: the lemonade stand hits a road crew and
  sells out, the spelling-bee stall tactic actually works, the care package
  gets a very polite thank-you that says everything.
- **The supernatural entries can go wrong.** Being embraced can mean waking up
  in a drawer three nights later. Teaching yourself magic from library books can
  bring something through the practice circle. Pushing it down for twenty years
  can mean it arrives all at once in a supermarket.
- **Two-choice events became three.** 106 events gained a real third option
  rather than a filler one — negotiate the crowd instead of fleeing or fighting;
  acknowledge the heir publicly; give the jubilee budget to the country; take the
  kidney but ask them to cover what it costs you; send a kid from the
  neighbourhood to collect your key to the city.
- **Minigame choices branch too.** Entering the fishing tournament, pitching on
  television and giving the sermon can each draw an easy or a hostile version.

## 3. Things the content pass forced the systems to fix

Content that describes something the engine cannot record is a lie, so:

- **Two new scars.** `surgery` and `public_shame`. Several outcomes already
  described a long surgical line or a reputation that never recovered, and there
  was nothing to store it in.
- **Scars are not always injuries.** The milestone said *"was left with a
  lasting injury"* for `haunted` and `broken_trust` too. It now says "a lasting
  mark" where that is what it is, and treatment is no longer described as
  surgery for a scar surgery cannot touch.
- **You can sell a business.** `biz_sell` pays what the business is actually
  worth, scaled by its quality — not a flat number written into an event.
  Building something good is now the only way to sell it well.

## 4. Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v13_moments_test` | **checks=210 failures=0** |
| `v12_content_test` | checks=633 failures=0 |
| `v11_system_test` | checks=74 sections=18/18 failures=0 |
| `v10_system_test` | checks=35 sections=10/10 failures=0 |
| `v09_system_test` | checks=300 sections=17/17 failures=0 |
| `v08_system_test` / `v08_echo_test` | 4/4 and 9/9, 0 failures |
| `sim_test` | 79 lives, 4,598 years, avg age 58.2, 520/573 distinct events fired |
| `migrate_test` | MIGRATION OK |
| `release_audit.py` | PASS — 3,241 outcomes, 0 errors, 0 warnings |

## 5. Still owed

`careers.json` (58 deterministic) and `careers2.json` (51) are the next two, and
then the long tail: `adult` (31), `family` (27), `fame` (19), `life` (17),
`school` (17). 284 deterministic choices left across the whole library.

Beyond that, unchanged from `OUTSTANDING.md`: depth for the six life paths that
have entry routes but not the treatment vampire and undead got; job *positions*
with yearly listings; activities that are still buttons; a hospital that cannot
always help; more minigames; per-country licence law variants; menu
categorisation. Prison Life and Pets Life remain v0.18 and v1.2.

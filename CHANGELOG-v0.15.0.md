# ONE MORE LIFE — v0.15.0 "Everything From Real Life"

Verified in Godot 4.4.1 (`tools/v15_system_test.tscn`). Every earlier gate still passes.

The rule behind this release: *add everything from real life, in a realistic
manner.* Two things stood in the way — the writing repeated itself, and the
ordinary parts of a life (where you live, how you get about, who you stay in
touch with) were gaps. Both are addressed.

---

## 1. The content debt is closed

| | Before | After |
| --- | --- | --- |
| Choices with exactly one outcome | **284** (16.1%) | **0** |
| Events with fewer than three choices | 84 | **0** |
| Events | 633 | 760 |
| Choices | 1,760 | 2,231 |

Every added outcome is hand-written and *different in what happens*, not the
same sentence with worse numbers. The wallet you keep is owned by someone who
has posted a flyer on every lamp-post; the neighbour you complain about is a
night-shift nurse; the sports car sits in the garage because you're afraid of
scratching it. Minigame outcomes (`play`) are excluded from the count because
the minigame itself decides them.

The authoring workflow is in `tools/content/` (see its README) so the content can
be reviewed and regenerated.

## 2. Writing that stops repeating

- **Inline alternatives.** `{~a|b|c}` in any event text picks one reading,
  stable within a life and different between lives. Options can be conditioned
  on who you are: `{~poor=counting coins|rich=tipping|paying}`. Conditions:
  gender, age band, wealth, partner, parent, renting, owner, city/country,
  employed, trait, decade.
- **Nested tokens** work inside alternatives: `{~outside {fx.shop}|on {fx.street}}`.
- **The era speaks.** `{era.phone}` is a landline, a flip phone, a mobile or just
  a phone depending on the decade you are living in.
- **A world with furniture.** Places are invented once and kept for the whole
  life: `{fx.pub}`, `{fx.street}`, `{fx.primary}`, `{fx.secondary}`,
  `{fx.hospital}`, `{fx.surgery}`, `{fx.cafe}`, `{fx.gym}`, `{fx.park}`,
  `{fx.market}`, `{fx.library}`, `{fx.church}`, `{fx.work}`. The pub you drank
  in at nineteen is the same pub at sixty.
- 47 of the most-hit event openings were rewritten to use all of the above.
  The gate resolves **546 variant readings** and fails on any raw brace.

## 3. The ordinary parts of a life

**Where you live (`Tenancy`).** A rented flat now has a landlord with a
temperament (kind, fair, absent, grasping), a deposit you may or may not see
again, rent that rises with the market and with the landlord, a boiler with an
age, damp that spreads when ignored, flatmates who halve the rent and sometimes
become the problem, and the chance of a letter saying the owner is selling.
Repairs, negotiation, insulation, contents insurance and moving are actions.

**Getting about (`Transit`).** The commute is a choice with a cost in time, money
and temper, and which choice is sensible depends on where you live: walking is a
pleasure at ten minutes and a chore at sixty; a pass is a bargain in a city with
trains and pointless in a county without. Cars carry insurance whose premium
follows age, record, claims and region; driving uninsured is a gamble with a fine
at the end; breakdowns, servicing, and the first crash — a real event with a real
shape — are all modelled.

**Keeping up (`Keeping`).** Invitations arrive — weddings, birthdays, baby
showers, reunions, and funerals (which nobody sends). Each has a cost in money
and time, can be answered with regards instead, and unanswered ones cost
friendships. Friendships lapse quietly and can be revived with a call. What you
eat moves your health and your bill; your phone and connection cost what they
cost in your decade.

**26 new events** use all of it, each with three choices and two or more
outcomes per choice.

## 4. Two bugs found along the way

- **60 events never fired.** `v08.json` was not in the loader's file list, so the
  v0.8 police, medical, sports, pet, business and justice events never appeared in
  a real game. The v0.12 test read the files directly and so could not notice.
  Fixed, and the gate now counts events as loaded rather than as authored.
- Strict typing in Godot treats an inferred `Variant` as an error; two new
  helpers needed explicit types. (Noted because it breaks the build silently if
  you copy this pattern.)

## What this costs the economy

Ordinary adults now pay for the things they always paid for in real life. In the
80-life simulation, bankruptcies per run rose roughly 13% against v0.14 (177 →
200). That is within the run-to-run noise band of the simulation but in the
direction one would expect, and it is on the v0.17 economy list.

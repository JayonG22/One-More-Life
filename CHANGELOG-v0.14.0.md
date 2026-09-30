# ONE MORE LIFE — v0.14.0 "Where You Started"

Verified in Godot 4.4.1. Two new gates: `tools/v14_system_test.tscn` —
**449 checks, 11/11 sections, 0 failures** — and `tools/layout_audit.tscn`,
which measures **3,161 controls across 11 panel states at four window sizes,
0 problems**. Every earlier gate still passes.

This update is a request list, worked through one item at a time. Where a thing
already existed it was left alone; where it did not, it was built; and where I
got something wrong, that is said here rather than buried.

---

## 1. The bug: your father married a stranger while married to your mother

Real, found, and worse than it looked. `_generate_family()` created a mother and
a father and **never recorded that they were married to each other**. The yearly
NPC pass then saw two unmarried adults aged 22–50 and married one of them off.

The fix is a marriage link that points **both ways**, so nobody can be married
twice, and a divorce clears both sides rather than leaving a ghost spouse.

The gate runs **2,700 NPC-years** and asserts zero violations.

## 2. You are not always born into a full family

Fixing the above meant building the thing that should have been there anyway.
Nine origins, rolled at birth, never a setting:

| Origin | Share of 300 lives |
| --- | --- |
| Both parents, together | 136 |
| Parents apart | 38 |
| Raised by mother | 35 |
| Adopted | 21 |
| Widowed parent | 19 |
| Raised by father | 19 |
| Raised by grandparents | 17 |
| The care system | 8 |
| A very young mother | 7 |

**92 of 300 were only children.** Each origin has its own opening line, its own
starting effects, and shows in the info panel for the whole life. When parents
who are actually married to each other divorce and you are young, that is a real
event with a milestone, not a line about somebody else.

## 3. Smarts go down if you never use them

Smarts only ever went up before 75, so a life that never opened a book kept what
it was born with forever. Now it slides every year you do not study — slower in
school, faster after 70, and faster the higher it already is, so there is further
to fall. Looks drift before 35 too if you never move.

Measured: **80 → 68.8 over ten years** with no studying; studying every year
holds it flat.

## 4. A life that is failing tells you before it ends

Health at 8% used to read exactly like health at 80%. Below 30% a stat now warns
you in escalating lines; below 15% real crisis events arrive — the heart going
too fast at three in the morning, the doctor asking whether there is anybody you
would like to have here for this, the memory assessment a relative booked without
telling you. Three choices each, two outcomes each, either direction.

## 5. Wanted stars

0–5, driven by crimes you **committed**, not crimes you were convicted of, and
weighted by kind — three shopliftings is 0 stars, three murders is 3.

They are not decoration. They add evidence at trial, multiply sentences by 22% a
star, cost you hiring odds, and at three stars a warrant stops you at passport
control and charges you for trying to leave. Twenty-five clean years cools it to
nothing, but the crime count and your peak are kept.

## 6. "Become a…" — going after it instead of waiting

v0.11 removed the life-path picker because choosing "Vampire" before your first
birthday told you the ending. That was right and it left the other half undone:
the only way in became waiting to be found.

There is now a front door with **17 paths** — vampire, witch, gifted, undead,
royal, pirate, space colonist, time traveller, film director, secret agent,
racing driver, casino owner, black-market dealer, cult founder, zoo owner, the
luxury life, the outdoor life.

Every row shows its full prerequisite checklist with ticks and crosses, the cash
and time it costs, and your real acceptance percentage. Applying spends the time
and money **whether or not they say yes**, asking again gets harder each time,
and a path you turned down when Destiny offered it stays shut. Destiny still
works exactly as before; this is the harder road, not a replacement.

## 7. Relationships go somewhere

Getting together was a log line and then silence, and the eleven partner events
in the library were equally likely from day one — so six months read like thirty
years, and a crush you had wanted for a decade produced nothing once you had them.

The relationship is now a thing in its own right: years together, five stages,
and how it is actually going read off trust, affection and romance minus
resentment. **Eight staged beats**: the spare key, meeting the family, moving in,
the first real argument, the question about the question, four hundred identical
Tuesdays, a memory neither of you shares, and the one who gets ill.

Getting together with a *crush* specifically gets its own line and goes into your
Life Threads. Over forty years the gate measures **five beats, none repeating**,
ending in the lifelong stage.

## 8. Borrowing, and fight night

**Four lenders**, gated on credit and income: high street bank (6%), credit union
(9%), online lender (21%), and a man in a pub at 55% who never says no. Missing a
payment compounds the balance and wrecks your credit; miss twice with the shark
and he comes to the house, with somebody who does not speak.

**Fight night** has a four-bout card regenerated each year, with odds computed
from the fighters' real ratings and shortened by a 12% book margin — so betting
is a slow way to lose money, correctly. You can also take a slot on the
undercard yourself, which runs the real boxing minigame for a real purse.

## 9. The people in your life have lives with each other

Your sister and your best friend used to exist in sealed boxes. They now form
their own bonds — close, friendly, together, rivals, not speaking — and those
change over time. Two of your people getting together when one is an ex or your
closest friend is something you have to have an opinion about.

Volatile people clash far more than calm ones, which is what the craziness stat
was always for: measured over sixteen runs, **111 clashes among volatile people
against 42 among calm ones**.

NPC agency also only ever fired at closeness 72+ or 28−, so most of the cast
never did anything. The middle band now gets something small and true every so
often, and it moves the relationship rather than being flavour text.

## 10. What things look like

- **Drawn icons.** Fifty-odd original vector icons, in code, that scale and take
  the theme's colours. Dwellings are a real ladder — tent, trailer, flat, terrace,
  bungalow, house, large house, villa, mansion, estate, tower, private island —
  so a mansion reads as bigger than the house beside it. Cars the same.
- **Progress bars on the main screen.** Fame, career skill, rank, approval, job
  performance, school performance, life-path meters and wanted level, all live,
  instead of buried in sub-menus.
- **Achievements take the screen.** Gold and above get a landing card, a tier
  wash and a shower; bronze stays modest, because most of them are bronze.
- **Turning points are unmistakable.** A rule above and below, their own colour,
  and an "Are you sure?" whose *No* returns you to the original choices.
- **Surprise me**, on any event with two or more available choices, which says
  which one it took so it reads as a decision rather than a skip.
- **Bars have a gradient** and the age button dips, springs past its own size and
  pushes a drawn ring out of itself.
- **Pets have a status page** — health, training, pedigree, temperament, tricks,
  titles, vet due — and **craziness shows on every person**.
- **The superhero background** was a faint dot grid on a pale screen. It is now
  comic-panel language: speed lines from a focal point, halftone that coarsens
  outward, a slow light sweep, and a hard ink-on-newsprint diagonal.

## 11. Measuring the layout instead of looking at it

Prompted by a good question — why eyeball screenshots when geometry can be
checked? So `tools/layout_audit.tscn` drives the game into each panel and
measures every visible control: nothing outside the viewport, nothing squeezed
below its own minimum size, no siblings overlapping, every button hittable, every
gap from one scale, and in any list of four or more, a lone odd width or edge is
reported.

Two honest notes about building it:

- **My first clean run was worthless.** It reported 0 problems across 1,023
  controls; every panel had walked the same 93, because the probe never left the
  new-life screen. It now walks 3,161.
- **A test that cannot fail proves nothing**, so the Become panel was sabotaged
  with a 9000×12px button. The audit caught it at every window size, and the
  count returned to zero when the file was restored.

What it actually found: the layout is structurally sound — zero overlaps, zero
clipped controls, zero unhittable buttons. What was messy was the vocabulary. A
census found **fifteen different gap values** (1, 2, 6, 10, 14, 18, 22, 28, 90…)
and seventy-two different minimum sizes. There is now one scale —
0/4/8/12/16/24/32/48/64 — that `U.vb()` and `U.hb()` snap to automatically,
fixing all 143 off-grid gaps without editing a single call site.

## 12. Minigames — what I can and cannot claim

A bot played **all 21 twice**: every one runs, responds and finishes with a score
in range, no errors. Boxing was then driven end-to-end through the real UI with
real key events — Enter starts it, W/S block the telegraph, Space lands the
counter, opponent 100 → 0 hp with no damage taken.

**So I could not reproduce the reported failure, and I am not claiming to have
fixed it.** I also got the diagnosis wrong once: I thought the 1000×540 board was
being clipped by the window, wrote a fix, and then found the project renders at a
1920×1080 base with canvas stretch, so the engine already scales everything and
my fix could never fire. It is kept only as a guard and labelled as such.

What was genuinely bad design and is fixed regardless: Fight Night had no control
legend while playing, and a jab that got blocked said only "Blocked.", which
reads as a dead button. Both would make a working fight feel broken. The counter
window is also wider at the default relaxed pace.

## 13. Age-appropriate and non-repeating

625 of 633 events already had age gates and a repeat cooldown. The eight without
turned out to be scheduled follow-ups — `_again`, `_later`, `_echo` — that were
never flagged as follow-up-only, so each could also surface at random at any age.
Flagged. The gate now fails if any event can fire unrestricted.

## 14. Verified

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v14_system_test` | **449 checks, 11/11 sections, 0 failures** |
| `layout_audit` | **3,161 controls, 11 panel states, 0 problems** |
| `v13_moments_test` | 210, 0 failures |
| `v12_content_test` | 633, 0 failures |
| `v11` / `v10` / `v09` / `v08` / echo | 74 / 35 / 300 / 39 / 25, all 0 |
| `mg_bot` | 21 of 21 minigames run and finish, 0 errors |
| `sim_test` | 80 lives, 4,630 years, avg age 57.9 |
| `migrate_test` | MIGRATION OK |
| `release_audit.py` | PASS |

## 15. Not done, and why

- **Streamline icons.** It is a paid, licensed library; scraping it would breach
  the licence, and this build environment cannot reach the site regardless. The
  fifty vector icons above are the answer instead — original, free, and yours.
- **Old saves.** They load, and the migration test passes, but a life started
  before this update has no origin, no wanted record and no relationship clock,
  so those read empty until a new life. Worth starting fresh.

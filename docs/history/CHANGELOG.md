# Version history

Preserved development notes, in version order. Statements such as “shipped”,
platform support, event counts and test results describe the recorded version;
they do not certify the current build or imply a downloadable GitHub release.
See [release readiness](../RELEASE-READINESS.md) for current publishing gaps.

- [v0.7.0](#version-0-7-0)
- [v0.8.0](#version-0-8-0)
- [v0.8.1](#version-0-8-1)
- [v0.9.0](#version-0-9-0)
- [v0.10.0](#version-0-10-0)
- [v0.11.0](#version-0-11-0)
- [v0.12.0](#version-0-12-0)
- [v0.13.0](#version-0-13-0)
- [v0.14.0](#version-0-14-0)
- [v0.15.0](#version-0-15-0)
- [v0.16.0](#version-0-16-0)
- [v0.17.0](#version-0-17-0)
- [v0.18.0](#version-0-18-0)
- [v0.19.0](#version-0-19-0)
- [v0.20.0](#version-0-20-0)
- [v0.21.0](#version-0-21-0)
- [v0.25.0](#version-0-25-0)

---

<a id="version-0-7-0"></a>

## Version 0.7.0

# ONE MORE LIFE — v0.7.0 "Life Gets Complicated"

This release continues directly from v0.6.0. It is not the 1.0 finish line. The purpose of v0.7 is to make ordinary life less safe, more interconnected, and more capable of producing consequences that return years later.

## Life Threads
- Added a persistent Life Threads system for meaningful memories that can echo back years later.
- Threads can be created by grief, divorce, gambling, illness, injury, recovery, home life, neighbors, Pirate Life, Space Colonist and Time Traveler events.
- Echo events react to the original memory instead of being generic repeats.
- Threads can strengthen, weaken, resolve, involve a surviving NPC, and persist inside the normal save state.
- Bridges seed appropriate threads into older v0.6 saves when important history already exists.

## Health, disease, injury and recovery
- Added a medical record with symptoms, diagnoses, injuries, medication state, treatment and chronic-care tracking.
- 18 physical conditions, including both temporary and chronic illnesses.
- 12 injury types with recovery time and consequences.
- Checkups, urgent care, specialists, second opinions, treatment and rehabilitation.
- Symptoms can precede diagnosis instead of every illness appearing fully labeled.
- Chronic illness has ongoing yearly pressure rather than disappearing after one click.
- Injuries can become long-running Life Threads.

## Mental health
- Added anxiety, depression, panic symptoms, grief, burnout and trauma-related stress states.
- Therapy, support, recovery streaks and relapse/recovery logic are treated as health systems rather than jokes or punishment mechanics.
- Mental-health state feeds stress, happiness, relationships and Life Threads.

## Home life
- Home ownership is now more than an asset line.
- Added property condition, upkeep, renovation history, neighbors and HOA state.
- 12 home upgrades: renovated kitchen, bathroom, security system, garden, solar panels, home office, nursery, creative studio, accessibility renovation, pool, workshop and guest room.
- Upgrades influence resale value and cross into burglary risk, recovery, work, family and happiness.
- Home events and neighbor history can become Life Threads.

## Casino expansion
- Added six casino games alongside the existing blackjack experience: Baccarat, Craps, Video Poker, Keno, Poker Tournament and Sic Bo.
- Wagers use the same player cash balance as every other financial system.
- Wins can immediately fund Shopping, homes, travel, businesses or anything else that spends ordinary money.
- Tracks lifetime winnings, losses, largest win, largest bet and poker titles.
- Gambling highs and losses can seed future Life Threads.

## Pirate Life
- Added Pirate as a full special-life path.
- Ship progression, cargo, ship condition, crew, morale, bounty and captain reputation.
- Crew are named people rather than anonymous resources.
- Raids, treasure hunts, ship repairs, upgrades and mutiny risk.
- Six ship upgrades and a rank ladder from Deckhand to Sea Legend.
- Pirate events include delayed callbacks and remembered rivals/crew history.

## Space Colonist
- Added Space Colonist as a full special-life path centered on living on Mars rather than merely visiting space.
- Oxygen, water, food, power, habitat condition and colony morale create survival pressure.
- Colony roles, upgrades, expeditions and council progression.
- Rare deep-space anomaly/first-contact arc.
- Colony history can echo back through Life Threads.

## Time Traveler
- Added Time Traveler with supported starts in 1850, 1920 and 1970.
- Era-aware costs and wages.
- Era gates for jobs, activities and items that do not exist yet.
- Technology becomes available as calendar time advances.
- Timeline heat/paradox-style pressure, artifacts and jumps between eras.
- Historical encounters can create delayed callbacks and Life Threads.

## Event content
- Added 63 authored v0.7 event records / 378 v0.7 outcome branches.
- Every v0.7 event has at least 3 choices and every choice has at least 2 outcomes.
- 16 v0.7 source events schedule delayed follow-ups.
- Added new event conditions for medical state, injuries, mental-health state, home ownership/upgrades and historical year.

## Presentation / integration groundwork
- v0.7 uses the existing shared money, NPC, event, save, FX and menu systems rather than isolated expansion state.
- New systems are exposed inside the existing Activities / special-life flows.
- Existing v0.6 content remains in place; v0.7 adds on top of it.

## Validation performed in this environment
- Static release audit: PASS.
- 573 total event records parsed.
- 1,367 total choices parsed.
- 1,873 total outcome branches parsed.
- All event IDs unique.
- All scheduled-event targets resolve.
- No JSON/schema/static integration warnings from the release audit.

## Runtime-test limitation
Godot is not installed in the build environment used for this package, so this package has not received the final in-engine v0.7 smoke pass here. Before calling v0.7 publicly released, open this exact package in Godot 4, verify the new menus at several ages, play each special life, save/load a migrated v0.6 life, and exercise the casino/medical/home loops.

---

<a id="version-0-8-0"></a>

## Version 0.8.0

# ONE MORE LIFE — v0.8.0 "Ambition & Society"

v0.8 continues directly from v0.7. The point of this update is not to add career buttons; it is to make work, institutions, professional relationships and consequences follow the player through a life.

## Professional Life — every job gets a story
- Added a **Career Development** layer to normal jobs.
- Professional reputation and network now sit beside ordinary job performance.
- Lead major projects with real success/failure risk.
- Build a professional network using persistent coworker NPCs.
- Gain a mentor whose relationship and advice can develop over time.
- Develop a recurring workplace rival who can return in later years.
- Take professional training that improves future work odds.
- Six v0.8 work events add credit disputes, recruiter calls, conferences, project failures, mentoring and promotion pressure.

## Sports Pro 2.0
- Kept the existing draft / contract / sport system and layered a real season simulation on top.
- Season records now persist as career wins and losses.
- Added an 8-team **league standings table** for each season.
- Postseason appearances, finals and league championships are tracked separately.
- Contracts expire into free agency instead of existing forever.
- Agent quality can improve contract leverage.
- Players can request trades and carry a list of teams played for.
- Teammate chemistry, press questions and injury second opinions create off-field decisions.
- Rival athletes can become persistent NPCs.
- Added career awards such as Rookie of the Year, Player of the Year and Finals MVP.
- Salary history records age, team, season record and salary.

## Police & Detective
- Police work now has two connected loops: **patrol** and **investigation**.
- Patrol calls include domestic incidents, traffic stops, pursuits, bribe attempts, welfare checks and ordinary community calls.
- Detectives can take cases in burglary, fraud, missing persons, arson, robbery, homicide, cybercrime and corruption.
- Every case creates a persistent named suspect and witness.
- Evidence builds over multiple actions instead of one random roll.
- Witness interviews can clarify or muddy a case.
- Interrogations can produce confessions but excessive pressure can hurt integrity.
- Warrants can be approved or rejected based on evidence.
- Weak arrests can fail; unresolved cases can become cold cases and later reopen.
- Department reputation, integrity, complaints, commendations and Internal Affairs concerns persist on the job record.
- Added the **Evidence Board** minigame: connect clues to defensible conclusions without forcing weak links.

## Doctor & Surgeon
- The normal doctor career already begins at Resident and can progress through Physician, Attending Physician, Surgeon and Chief of Medicine; v0.8 turns those ranks into active clinical play.
- Added specialties: Family Medicine, Emergency Medicine, General Surgery, Cardiology, Oncology, Psychiatry, Pediatrics and Neurology.
- Patients arrive with symptoms first. Diagnosis uses the same physical-condition data that affects the player's own health.
- Ask for second opinions, treat patients, perform rounds and build a clinical reputation.
- Severe diagnosed cases can go to the **Operating Room** minigame.
- Surgery success, complications, patient stability and malpractice risk are persistent consequences.
- Research and mentoring residents create alternate ways to build a medical career.
- Clinical burnout accumulates over time and can feed the existing mental-health system.

## Deeper pets
- Every pet now receives a persistent profile with health, temperament, training, tricks, pedigree, show history and care state.
- Train pets and unlock individual tricks.
- Enter pet shows; grooming, health, training, closeness and pedigree all influence results.
- Veterinary care matters as pets age.
- Breed pets and create actual child-pet NPCs with inherited pedigree values.
- Certify suitable pets as therapy/support animals, tying pets into stress, happiness and Life Threads.
- Added pet businesses: Training School, Grooming Studio, Daycare, Ethical Breeding Program and Animal Rescue.
- Pet businesses have staff, reputation, marketing, value and yearly profit/loss.
- A trained family pet can become the face of the business.
- Living family pets preserve their v0.8 profile when the player continues as a child.

## Enterprise portfolio
- The existing hands-on Business system remains intact, including staff, loans, investors and IPOs.
- v0.8 adds a **multi-company portfolio** on top of it.
- Found additional companies without abandoning the operating business.
- Each portfolio company has an industry, CEO NPC, staff count, quality, value, debt, profit and ownership stake.
- Acquire companies using cash or leveraged debt.
- Pull special dividends at the cost of company resilience.
- Companies experience independent yearly demand and can borrow or go bankrupt.
- Name a child in a succession plan; a designated portfolio can transfer when the family continuation moves to that child.

## Courts, appeals & reentry
- Trial outcomes now record evidence strength, lawyer quality and case result into a persistent justice history.
- Evidence strength directly affects acquittal odds instead of trials being detached from the underlying case.
- Pleas, convictions, dismissals and acquittals are retained in the case history.
- Lower-level convictions can create probation.
- Added appeals. Weak-evidence convictions have a better chance of being overturned, but appeals cost money and time.
- Added probation / parole supervision and reentry events that affect work, housing, money and relationships.

## Events and Life Threads
- Added **60 authored v0.8 events** with **180 choices** and **360 outcome branches**.
- Every v0.8 event has at least 3 choices.
- Every v0.8 choice has at least 2 possible outcomes.
- 18 v0.8 source events schedule delayed follow-ups (30%).
- Event groups cover police, medicine, sports, pets, enterprise, justice/reentry and ordinary professional life.
- New career relationships and institutional consequences use persistent NPCs / flags / case state rather than isolated popup text.

## Goals
- Added **19 v0.8 achievements** for detective work, medicine, surgery, pet shows, litters, support animals, pet business, company portfolios/acquisitions/succession, sports postseason/titles/awards/trades, professional projects/networking and winning an appeal.

## Presentation pass
- Added profession-specific generated SFX without adding external audio assets.
- Siren feedback for patrol work, monitor tones for clinical care, crowd ambience for pet shows, cash feedback for acquisitions and a gavel hit for appeals.
- League titles use the existing fanfare presentation.
- The new Evidence Board and Operating Room are interactive minigames rather than timed reading prompts.

## Save / integration behavior
- v0.8 state lives in the normal player/job/NPC save graph.
- Older saves lazily receive missing `ambition` state when the new systems are opened or a year advances.
- Pet profiles can continue across generations with a carried family pet.
- Enterprise succession state can transfer to the designated child.
- v0.7 Life Threads, health, homes, casino, Pirate, Space Colonist and Time Traveler systems remain in place.

## Validation performed in this build environment
Static release audit: **PASS**.

- 633 total event records parse.
- 1,547 total choices parse.
- 2,233 total outcome branches parse.
- 60 v0.8 events / 360 v0.8 outcome branches.
- 18 v0.8 events schedule delayed follow-ups.
- 19 v0.8 achievements parse with unique IDs.
- All event IDs are unique.
- All scheduled event targets resolve.
- All registered minigame script paths exist.
- v0.8 integration hooks are present.
- Edited GDScript files pass delimiter/quote sanity checks.
- ZIP/archive integrity is checked during packaging.

## Runtime-test limitation
Godot is not installed in the environment used to assemble this package. The included `tools/v08_system_test.tscn` is therefore **provided but not executed here**. That distinction is intentional: static validation is not being described as gameplay testing.

Run the included smoke test with a Godot 4 executable:

```text
godot --headless --path . res://tools/v08_system_test.tscn
```

Then follow `docs/history/V0.8-TEST-PLAN.md` before calling the update public-release ready.

---

<a id="version-0-8-1"></a>

## Version 0.8.1

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

`docs/history/V0.8-TEST-PLAN.md` remains the manual gate. The automated work above does not
replace playing a detective through a cold case or a surgeon through a career.
Sections 3–10 of that plan still want a human.

---

<a id="version-0-9-0"></a>

## Version 0.9.0

# ONE MORE LIFE — v0.9.0 "A Living World" (first pass)

Everything here was built and verified in Godot 4.4.1. New gate:
`tools/v09_system_test.tscn` — **300 checks, 17/17 sections, 0 failures.**

---

## Why this build exists

Playing v0.8.1 the complaint was that the game felt too easy and unfulfilling —
"every year I age, the prompts just reward me if I make the good decision."

That turned out to be measurable. Across all 1,547 choices in the game:

- **55.9% had exactly one outcome.** You picked, and the scripted result happened.
- **50.4% could not go badly** — every outcome neutral or good.
- Only **4 choices in the whole game** had three possible outcomes.

Split by age, the cause was obvious:

| Content | Events | Deterministic choices | Events with <3 choices |
| --- | --- | --- | --- |
| v0.7 + v0.8 | 123 | **0%** | **0** |
| v0.6 and earlier | 510 | **68–89%** | **293** |

The design rule is "at least 3 choices, at least 2 outcomes per choice." The new
content followed it perfectly. The old content — 81% of the game, and nearly
everything an ordinary life actually meets — did not. The static audit never
caught it because it only ever checked the newest events.

## 1. The uncertainty engine (`autoload/friction.gd`)

Every choice now resolves against **who the character actually is**: the stat that
governs that kind of act, their stress, health and happiness, their karma, their
traits, their habits, and the difficulty. Three bands — clean, snag, backfire.

On Real difficulty:

| Character | Clean | Costs something | Backfires |
| --- | --- | --- | --- |
| Capable & calm (85 smarts, low stress, good karma) | 93% | 4% | 3% |
| Average | 58% | 27% | 15% |
| Struggling (low health, 80 stress, bad karma) | 22% | 49% | 30% |

Classic holds at 71% clean; Gritty drops to 43%. Reaching further is harder: a
small win lands clean 64% of the time, a fortune 41%. Authored multi-outcome
choices are only nudged (81% clean) because the author already modelled the risk.

In real play it fires on about 27% of resolutions, and average lifespan moved
59.1 → 58.9, so it adds uncertainty without breaking the balance.

**Two guards matter.** Friction never fires on an outcome the author already made
bad, and never on an outcome with no gain to take away. An early version appended
"It came apart in front of me." to *"Shadow is family now."* — so the prose was
rewritten to narrate **cost and aftermath only, never whether it worked**. The
failure is carried by the numbers falling short of what the sentence promised.

## 2. Money is counted where the life happens

| | Salary | House | Fortune |
| --- | --- | --- | --- |
| 🇺🇸 United States | $52,000 | $340,000 | $2,500,000 |
| 🇯🇵 Japan | ¥7,852,000 | ¥51.3M | ¥377.5M |
| 🇳🇬 Nigeria | ₦82.2M | ₦537.2M | ₦3.95B |
| 🇩🇪 Germany | 47,840 € | 312,800 € | 2,300,000 € |

Money is stored in one internal unit and only ever *displayed* in local currency.
Emigrating changes the currency, not what you own. Rates are nominal illustrative
snapshots, not a live feed; purchasing power stays on each country's existing
`cost` and `wage`. Weak currencies compact at scale (₦3.95B) so the UI survives.

**Five new countries** — India, South Korea, Egypt, Canada, Australia — bringing
the total to 14, each with its own currency and name pool.

**Bug found:** France and Mexico pointed at name buckets `fr` and `es` that *did
not exist*. Every French and Mexican character had been silently getting English
names. Fixed, and five new name buckets were authored (`fr`, `es`, `in`, `kr`, `ar`).

## 3. Units are toggleable; money is not

Metric / Imperial (US) / UK mixed (miles and stone, but °C), in Settings.
Everything is stored metric and converted at the moment it is written into a
sentence. Money stays locked to the country, because expressing a Lagos life in
dollars would be a lie about where it happens.

## 4. Licences are actual tests (`data/licenses.json`, `mg_quiz.gd`)

The old test rolled dice against Smarts, which meant a clever character could
hold a firearms licence without knowing which way to point it.

Eight question banks, 49 questions, every one with a written explanation of *why*.
Length scales with how general the knowledge is, exactly as specified — driving is
8 questions, fishing is 3, pilot and scuba are 4. **Every answer must be correct.**

Road signs are **drawn as vector polygons**, not imported images, so they stay
crisp at any interface size and the shape itself is what the question tests.

**Caught during testing:** requiring a perfect paper meant anyone playing with
minigames switched off could never obtain *any* licence. The auto-resolve path now
falls back to a study check against Smarts.

## 5. Minigame pace

New setting: Relaxed (default, 0.72× timing pressure), Standard, Brisk. Applies to
every minigame's timing windows. The licence quiz is deliberately untimed — a clock
there would only measure reading speed.

## 6. Activities take as long as you give them

| Walk for… | Time | Reward | Overdo risk |
| --- | --- | --- | --- |
| A quick loop | 1 | ×0.55 | — |
| An hour out | 1 | ×1.00 | — |
| Half the afternoon | 2 | ×1.70 | 10% |
| All day, miles of it | 3 | ×2.30 | 28% |

Never twice as much for twice the time, and the hours come from the same 12 you
have for everything else. Gym, library, meditate, yoga, games and reading each
have their own scale — "Train until I'm shaking" is ×2.10 with a **42%** chance of
injuring yourself.

## 7. Reasons, not clicks

**The doctor now needs one.** Illness, poor health, unexplained symptoms, an
ongoing condition, pregnancy, or being 4+ years overdue. Otherwise the
receptionist offers you an appointment in four months.

**Convenience is earned.** "Get everyone together" stays locked until you have 4+
close people *and* have spent real time with people 10 times. It costs 1–4 time
points by headcount and gives less per person than seeing them individually. On
**Gritty it does not exist at all** — hard mode takes conveniences away rather
than only piling on misery.

**Routines are dispersed.** The central Routines panel is gone; the gym toggle
lives next to the Gym, study next to the Library, family time in Relationships.

## 8. Climate and place (`autoload/climate.gd`)

46 regions across all 14 countries, each mapped to one of ten real climates with
summer and winter means and a rainfall character.

- Las Vegas: desert, 40°C summers, almost no rain, water restrictions
- Sapporo & Calgary: cold continental, −8°C winters, months of snow
- Manila: tropical monsoon, arriving on schedule
- London: oceanic, rain in every month of the year

It costs money — Calgary's heating and cooling ran **C$544/yr** against Las
Vegas's **$307** — and a heatwave is far more dangerous to the very old, the very
young and the already unwell, where it can leave a Life Thread.

**16 new regions** for the five new countries.

## 9. Everyone has a life

Every NPC now carries the player's full stat set — happiness, health, smarts,
looks — shown on their panel and drifting with age. A friend tracked from 20 to
75 went ❤️ 93→35, ✨ 61→17. **Their health now decides how long they live.**
Saves made before this get sensible values on load.

## 10. Deeds change your world (`autoload/deeds.gd`)

Karma used to be a hidden number that nudged event odds and did nothing you could
point at. Now living at an extreme — of karma, or of any of the four stats — makes
the world act on you, and **every result is something visible**: an item gained or
missing, money, a person's opinion, a door that opens or closes.

Thirty years at high karma grew a possessions list from 2 items to 6, plus people
repaying kindnesses long forgotten. Thirty years at low karma: things disappear
from your home, friends stop calling, and strangers decide you are the reason
their life went wrong.

## 11. Shopping has a name on it

Six invented houses, each with a history, a price it can command and a different
rate of holding value. The same luxury watch:

- **Harrowgate** — $24,700 — *"Family-run, unfashionable, and quietly the one that outlasts the others."*
- **Castellane Frères** — $76,570 — *"Founded 1848. Four generations, two wars, one unchanged workshop."*
- **Aldridge & Wray** — $133,380 — *"They do not have a shop. You are introduced, or you are not."*

Numbered editions appear only sometimes (that being the entire idea of a limited
run), carry a real production run and **your** serial number, and appreciate.

The houses are invented rather than real. Using a real maker's name would be
someone else's trademark, and the project's own originality rules already exclude
it — so what is delivered is the *flair* of shopping without the legal exposure.

## Verified in Godot 4.4.1

| Check | Result |
| --- | --- |
| Project import / compile | 0 script errors |
| `v09_system_test` | **checks=300 sections=17/17 failures=0** |
| `v08_system_test` | actions=39 sections=4/4 failures=0 |
| `v08_echo_test` | checks=25 sections=9/9 failures=0 |
| `sim_test` | 80 lives, 4,714 years, avg age 58.9, 0 errors |
| `career_test`, `empire_test`, `migrate_test`, `migrate6` | 0 errors |
| `reach_test`, `reach6`, `menu_crawl`, `mg_bot`, `mg_smart`, `audio_test` | 0 errors |
| `release_audit.py` | PASS — now also checks currencies, name buckets, licence banks and climate coverage |
| Boots and plays on a real display | yes (Nigerian life, ₦, tropical climate) |

## Not in this build, and still owed

These are on the list and were not done. They are not cancelled:

- **Hand-authored outcomes for the 865 deterministic v0.6 choices.** The
  uncertainty engine addresses the *feel* systemically, but the written content
  is still owed, along with raising the 293 events that have fewer than 3 choices.
- **Unique icons per category** — education is still mostly one book icon.
- **Job positions** — applying for a *position* within a job, not just the job.
- **Tombstone and graveyard redesign.**
- **Cliques and school life as real panels** instead of a randomiser button.
- Per-country licence law variants (the banks are written but not yet forked by
  country).

---

<a id="version-0-10-0"></a>

## Version 0.10.0

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

---

<a id="version-0-11-0"></a>

## Version 0.11.0

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
1850 / 1920 / 1970. Two per version, same pace. Full list in `docs/history/OUTSTANDING.md`.

---

<a id="version-0-12-0"></a>

## Version 0.12.0

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
Full table in `docs/history/OUTSTANDING.md`.

---

<a id="version-0-13-0"></a>

## Version 0.13.0

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

Beyond that, unchanged from `docs/history/OUTSTANDING.md`: depth for the six life paths that
have entry routes but not the treatment vampire and undead got; job *positions*
with yearly listings; activities that are still buttons; a hospital that cannot
always help; more minigames; per-country licence law variants; menu
categorisation. Prison Life and Pets Life remain v0.18 and v1.2.

---

<a id="version-0-14-0"></a>

## Version 0.14.0

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

---

<a id="version-0-15-0"></a>

## Version 0.15.0

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

---

<a id="version-0-16-0"></a>

## Version 0.16.0

# ONE MORE LIFE — v0.16.0 "Work and Body"

Verified in Godot 4.4.1 (`tools/v16_system_test.tscn`). Every earlier gate still passes.

The two systems that had a bar where they should have had a life.

---

## Work

**A job market (`Market`).** Each year's openings are specific: a named employer,
a salary somewhere inside a band, a number of other applicants, the experience
they want, whether it is remote, a boss and a culture you will only fully learn
once you are inside. Your odds are shown with the reasons behind them: smarts,
experience in that field, interview practice, a reference you can use, a gap on
your CV, your record, and how crowded the field is.

**Getting hired.** A screening (most applications never reach a human), then an
interview, then an offer you can accept, decline, or *negotiate* — the
Negotiation minigame. Every rejection teaches you a little: interview practice
accumulates, and rejections come with the kind of reasons real rejections have.

**Being there (`Workplace`).** A manager with a temperament (supportive,
micromanager, hands-off, brilliant, political), a culture (friendly, cutthroat,
sleepy, chaotic), and colleagues with roles — mentor, gossip, rival, ally,
slacker, climber — who each do what their role says. The company has a health
that can turn: hiring freezes, restructures, redundancy with severance (doubled
and less likely with a union). Office politics, a union you can join, lunch with
a colleague, and a resignation that leaves on good terms and takes a reference
with it.

**Leaving.** Retraining in another field, freelancing (variable income, late
payers, your own tax), and the CV gap that unemployment leaves.

## Body

**Care is a pathway (`Care`).** Real care has stages and each can fail. A GP who
may take you seriously or not; a referral; a waiting list whose length depends on
what kind of country you live in (none in a private system, up to two years in a
public one); a specialist who is usually right and occasionally confidently wrong;
a second opinion when they are; paying to skip the queue.

**Conditions that persist.** Medication you have to keep taking — skipping it has
a price that arrives late. Physiotherapy for injuries. Eyesight that fades and can
be corrected with glasses, contacts or surgery. Teeth that need a dentist and
eventually dentures. Hearing that goes and can be helped.

**Things that compound (`Body`).** Four slow accounts — movement, sleep, diet and
excess — are paid into every year and cash out decades later. In the gate, thirty
years of good habits ends at health 93 against 67 for thirty years of neglect.
Turning forty, sixty and eighty each leave a mark, and falls at seventy-plus
depend on how strong you stayed.

**26 new events** cover all of the above, again with three choices and two or
more outcomes per choice.

## Tests

`v16_system_test`: 214 checks. Among them: a micromanager costs more stress than a
supportive boss (3.2 vs -1.2 a year); a company at 5% health makes people
redundant and pays severance; free-lance income varies; a misdiagnosis can be
corrected by a second opinion; medication helps (+0.9 vs -1.2 health a year);
thirty years of lifestyle separates two lives.

---

<a id="version-0-17-0"></a>

## Version 0.17.0

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

---

<a id="version-0-18-0"></a>

## Version 0.18.0

# ONE MORE LIFE — v0.18.0: Pets Life

A new **game mode**, chosen on the title screen beside Human Life — not a life
path you stumble into, and not a skin over the human game. You are the animal.

`tools/run_gates.sh` now runs **23 checks**; two are new for this mode
(`v19_pets_test`, a content-and-simulation gate, and `v19_ui_test`, which plays a
whole pet life through the real screen).

---

## Choosing a mode

The title screen opens on a **Choose your game mode** block, above the ordinary
menu and drawn differently from it: three cards — **Human Life**, **Pets Life**,
**Prison Life** (Prison arrives in v0.19 and says so). Each mode is its own game
with its own year, its own events, its own screens and its own ending.

## Pets Life

Dog, cat, rabbit, parrot or horse. You choose the animal, a name, and where it
begins; the world does the rest.

### Seven beginnings

A loving house · a farm litter · a mill · a shelter · the street · a working
line · a show line. Each decides your home, how far you trust people, how well
you are fed, how many years you start with, and what you are for.

### What you are

No money, no job, no calendar. Seven slow gauges instead — **bond** with your
person, **obedience**, **instinct**, **belly**, **territory**, **belonging**,
**fitness** — plus the household's **means** and **mood**, which you cannot
change directly but live inside. Species change the rules: a dog tries, a cat
decides, a parrot talks back, a horse remembers. Lifespans are the animal's own
(rabbit ~9 years, dog ~13, cat ~16, horse ~24, parrot ~35) and the long-lived
ones take proportionally less accident and illness a year, so the horse is not
three times as exposed as the dog.

### The household, seen from the floor

The people are the cast, and their lives happen over your head: someone loses
their job (the good tins stop), gets a better one, has a baby (you are no longer
the centre of the house), moves, breaks up (and one of them takes you), falls
ill, or dies (and the question of who takes you is asked in the kitchen).
You notice the way an animal notices: a voice, a suitcase, a smell. Money
trouble raises the real possibility of being given up; a shelter has its own
year; the street has its own winter.

### Things to do

Six menus, 30-odd actions — care and comfort (beg, nap, a lap, grooming, the
vet, **comforting a person in grief**, which really changes the household's
mood), play, learning (tricks, recall, obedience class), the wider world
(explore, mark, bark at the postie, **raid the bins**, **escape** and risk being
lost), the people (a row per person, friend and rival) and a **calling**:
companion, guardian, working animal, show animal, therapy animal, street animal,
barn keeper, racer.

### Five new minigames (all with bots, all inside the gate)

| Game | What it is |
| --- | --- |
| Stalk and Pounce | A hole shakes, then the prey shows. Pounce on that hole; pounce on an empty one and the prey gets wary |
| Scent Work | Eight forks, three noisy readings; sniffing again averages the noise away but costs time |
| Sneak | Hold to creep, release to freeze; a ❓ is the warning beat before the human looks |
| Agility Course | Hurdles to jump and tunnels to duck; the key is written on each obstacle |
| Herding | Stand on the far side of a sheep and let it walk to the pen |

### A road and seven endings

Five chapters that open on what you did (*Somebody's*, *The shape of the place*,
*What I am for*, *The test*, *The long evening*) with a turning-point event for
each, and seven endings: **Best Friend · A Hero · Best in Show · Lord of the Alley ·
A Long, Warm Life · Never Came Home · A Good Life**. They are written into the
life story, the tombstone and the ribbon.

When it ends, **Another life in the same house** starts a new animal in the
household that remembers the last one: same family name, same people, older.

### Content

- **76 events**, 228 choices, 456 outcomes. Every event has three or more choices
  and every choice two or more outcomes. 58% lead to a delayed follow-up.
- Species events (dog park, the postie, the lake, the squirrel, the cone, the
  box, the mouse, the flap, the wire, the fox, the word you were not meant to
  learn, the open window, the farrier, the plastic bag, the latch), origin
  events (a hard winter, the van with the net, the butcher, the pack, the
  shelter's Tuesday volunteer, hands, a first working day, the ring, the tractor)
  and household events (thunder, the long day alone, the big table, a bad night,
  the baby, the split, the new bed, the visitor, the burglar, the fire).
- **28 achievements** (a new *Pets Life* category), judged only in a pet life.
  Human achievements are no longer judged in one, and pet ones never are in a human.

## Under the hood

- A **separate-mode** layer: `Lives.separate()` gives a mode its own year
  (`EventEngine._age_up_separate`) and restricts it to events written for it.
  A human never meets a pet event and a pet never meets a human one — the gate
  checks both directions over hundreds of years.
- The main screen's tabs, bars, header and quick buttons are now mode-driven.
- `tools/content/gen_pets.py` and `gen_pet_achievements.py` regenerate the content.

## Checked, and not

- **Checked:** the library (depth, tags, follow-ups); isolation between modes;
  140 whole lives across every species and origin (lifespans in range, no gauge
  out of range, every cause of death and ending reachable); every menu action;
  the arc, seven endings, ribbons and tombstones; save/load; the next-life flow;
  the real screen end to end; the five minigames with bots; title-screen layout.
- **Not checked:** nothing in this mode has been played on real Windows or macOS
  hardware. A hundred lives is a simulation, not a player; whether a given event
  *lands* is a matter of taste that a gate cannot judge.

---

<a id="version-0-19-0"></a>

## Version 0.19.0

# ONE MORE LIFE — v0.19.0: Prison Life

The second new **game mode**. Pets Life (v0.18) was the first; this one is chosen the
same way — from the **Choose your game mode** block at the top of the title screen,
third card, in red. Prisoner or guard: two doors into one building.

`tools/run_gates.sh` now runs **25 checks**; two are new (`v20_prison_test`, a
content-and-simulation gate, and `v20_ui_test`, which plays both roles through the
real screen).

---

## Two doors, one building

You are either serving a sentence or working the walls, and the **building is the
same**: one facility, with a name, a security level, a warden with a style, a
tension that rises and falls, four gangs that want things, a budget, a crowding
figure and a count at four o'clock that must come out right. A riot is a riot from
both sides of the door. What it is *for* you depends on which side you are on.

Both roles are the person who walked in, with **a family outside it that goes on
without them**: parents who age and die (and a form to ask for the funeral), a
partner who decides what to do about the years, children who turn eighteen and
either send a card or don't.

### Prisoner

Seven stories decide the crime, the length, the security level and who you are
when the door shuts: **a first offence, a career criminal, a gang member, white
collar, wrongly convicted, a political prisoner, a lifer.**

- **Standing:** *fresh fish → regular → respected → shot-caller → old head.*
  Respect, heat (staff attention), conduct (the board reads it) and support from
  outside are the four numbers you live by.
- **Money is cigarettes, then commissary.** A job (kitchen, laundry, library,
  workshop, yard, infirmary, barber), dues, debts, cards, a loan at interest, ink.
- **Gangs:** *The Brickhouse Boys, Los Cuervos, The Quiet Men, The Congregation* —
  or protective custody, or no one. Each remembers how you treated its members.
  Joining, doing favours, being ordered to hurt someone, being promoted, leaving
  (it costs).
- **Programmes:** diploma, correspondence degree, trade certificate, counselling,
  faith group, substance programme, anger management. Every one is a line the
  parole board reads.
- **Parole:** from your eligibility year a hearing is due annually. **The Parole
  Board** is a minigame of tone: each question is listened to for one thing —
  remorse, evidence, or a plan — and the panel's face tells you which.
- **The innocent-prisoner arc:** an appeal gauge, a lawyer who stops returning
  calls, the library's law books, a witness who recants, a DNA test, a hearing.
- **Solitary, shakedowns, fights, informing.** Informing buys conduct and costs
  respect.
- **The plan.** A multi-stage jailbreak built on the intel you gather (*listening →
  tools → a crew → an inside man → the right night*), with betrayal built in —
  every person who knows is a way for it to go wrong. On the night the break is
  three minigames in a row (the lock, the yard, the fence). If it works there is a
  **manhunt** with its own menu and events: lie low, a new identity, cash-in-hand
  work, a message to your family (heat up a lot), move on, turn yourself in. Five
  clean years and you are a ghost.

### Guard

Six stories — **a steady career, ex-military, needed the job, an idealist, a prison
family, from the neighbourhood** — and a rank ladder: *recruit → officer → senior
officer → sergeant → lieutenant → captain → deputy warden → warden*, with merit,
control of your wing, integrity, a union, Internal Affairs' interest in you and the
trauma the job puts on you.

- **On shift:** rounds, **a cell search** (a minigame of clues: a glued seam, a
  weight that's wrong), a use-of-force decision that follows you to an inquiry,
  paperwork, overtime, a proper break, ordering a lockdown.
- **The wing:** know the inmates and they know you. An inmate you treated fairly is
  the one who warns you.
- **The keys:** a favour, an envelope on the passenger seat, a ring of officers who
  would like you in, a colleague to cover for, a report to make, a whistle to blow.
- **The set pieces:** a **riot** from the officer's side (the line, the control
  room, the cut-off wing) and the **hostage** situation, which you resolve with
  **Talk Him Down**, a minigame: he says one thing each turn and it tells you what
  he needs — to be heard, given a reason, or offered something.
- **The oldest story the building has.** If Internal Affairs finds a ledger in your
  handwriting you are tried, convicted, and sent to **Block A of the building you
  used to guard.** You continue as a prisoner — with every gang against you and an
  officer on the door who remembers your badge number.

### Shared mechanics

- **Group reputation.** Each gang has a standing with you, remembers what you did to
  its members, and acts on it.
- **Information as a resource.** Intel — a patrol time, a blind spot, a weak
  officer, a gap in a timeline — is collected from the yard, from officers, from
  other inmates; used for a plan, an appeal, a deal; and can be traded or sat on.
- **Set pieces.** The riot (six chained events for the prisoner, five for the
  guard), the hostage, the break and the manhunt. Several systems at once, not one
  popup.
- **Someone else's perspective.** You cannot make the building do anything. You can
  only change what it thinks of you.

### Three new minigames (bots in the gate)

| Game | What it is |
| --- | --- |
| The Parole Board | Five questions; give the answer the panel is waiting for (own it / show evidence / give the plan) |
| Cell Search | Twelve items, three are wrong, and the descriptions give them away |
| Talk Him Down | Eight turns; match listen / reason / offer to what he says |

(The break reuses the existing Safecracker, Infiltration and Prison Break games;
appeals use the Evidence Board; trading uses Negotiation; yard promotions use Fight
Night.)

### Two roads, fifteen endings

**The prisoner's road** has five chapters — *Fresh fish · Whose side? · Something to
hope for · The test of the walls · The door* — and endings **Exonerated · A Ghost ·
The Other Side of the Door · Paroled · Every Day of It · Old Head · Never Out.**

**The guard's road** — *Probation · The first incident · What kind of officer ·
Stripes · The long shift* — and endings **Warden · Whistleblower · The Man With the
Keys · Hero of the Wing · Dismissed · Burned Out · Thirty Years · In the Line of
Duty.** All are written into the life story, the tombstone and the ribbon.

When a story closes the screen reads **Case closed**, not Death — the sentence is
served, the board agreed, the wall was cleared, the career ended — with an
epilogue ("The gate opened at 7.40 on a Tuesday, with a clear plastic bag and a
travel warrant…").

### Content

- **120 events**, 362 choices, 725 outcomes. Every event has three or more choices;
  every choice, two or more outcomes. 34% lead to a delayed follow-up.
- **45 achievements** (a new *Prison Life* category), judged only in the matching
  role; a hidden *Both Sides of the Door* for having lived each.

## Under the hood

- `Lives.mode()` gives the main screen one interface for any separate mode (tabs,
  quick buttons, gauges, header, side notes, end-of-life card). Pets now uses it
  too; a third mode is a new autoload and a new tab list.
- Event outcomes can chain (`then`) into a step of a set piece, and can play a
  minigame and branch on win/lose (`pr_branch`).
- `tools/content/gen_prison*.py` and `gen_prison_achievements.py` regenerate the
  content.

## Checked, and not

- **Checked:** the library (depth, tags, roles, chains, branches, follow-ups); that
  every person an event names exists for the role it's written for; isolation in
  every direction (humans, pets, prisoners and guards each see only their own
  events); 78 whole lives across every story in both roles; every menu action;
  both roads and all 15 endings with ribbons and epitaphs; 40 attempted breaks and
  the manhunts that follow; the guard-to-prisoner switch; save/load; both roles
  through the real screen; the three minigames with bots; title-screen layout.
- **Not checked:** nothing in this mode has been played on real Windows or macOS
  hardware. A hundred lives is a simulation, not a player; whether the building
  *feels* like one is a matter of taste that a gate cannot judge.
- **A deliberate limit:** the prison world is fictional — the facilities, gangs and
  officers are invented, not drawn from any real institution or group.

---

<a id="version-0-20-0"></a>

## Version 0.20.0

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

---

<a id="version-0-21-0"></a>

## Version 0.21.0

# ONE MORE LIFE — v0.21.0: A Calmer Year, A Fuller World

## The year no longer floods
- **Event Director.** A year now has a budget of popups (2 in an ordinary year, 3 at milestone ages, 1 for a small child; "calm" and "busy" shift it). Critical news always gets through; the rest are ranked, and what does not fit is folded into the log, put back for next year, or never happens. Measured over 500 simulated years: from 3.2 popups a year (peak 8) to 1.7 (peak 4).
- **Relevance.** Random events are weighted by how well they fit this person now: stage of life, work, relationships, health, money, habits, and the world around them.
- **Variety.** An event you have seen comes less often, a theme that just played sits out a few years, and each life draws on its own slice of the library.
- **Less trivia.** Other people's news is capped at two lines a year.

## Work has consequences, with reasons
- **Annual review.** Promotions need merit, tenure, a post to move into and someone backing you. A poor review is a warning and a performance plan; a second one is a demotion or the sack. Every outcome states its reason.
- **The economy reaches the office.** Recessions, booms, a pandemic and the AI wave each move different sectors. Layoffs and firings bring severance and unemployment support for a while.
- **Job applications are read, not rolled.** A weak fit is turned down and told why (experience, a gap, your record, skills, the crowd), with a tip; the job list shows "Strong fit / Possible / Long shot" and what is holding you back. Interview answers carry their own reason.
- Employer names are sector-aware (hospitals, banks, schools, the Army and so on) and never repeat in a life.

## Transport matters
- Journey events (a concert across the region, an interview in another city, a sick relative six hours away) depend on how you can actually get there. The decision says so: on foot, a long trip has slim odds; a bike, a pass or a car changes that.

## Animals you keep
- Strays, kittens, litters, gifts and shelter, shop and breeder animals are kept. They eat, fall ill, bond or drift, age and die, and show on the People tab with bond, health and how well fed they are. 12 species. 18 new events.

## Gambling that plays
- Eight animated games: Slots (respin and bonus chests), Roulette (a wheel and a ball), the Races, Rocket, Plinko, scratch cards, the Lucky Wheel, and High-or-Low ladders. All fair maths, luck charms still help.
- The Memory Test is a real game now.

## Relationships
- Faded and ended relationships move to a **Past relationships** panel. The main list is grouped, with "needs attention" first. Old memories of you come back as decisions.

## Looks
- The **Family Tree** is drawn as a tree. The **Graveyard** is a night cemetery with a stone per life. The Daily Heirloom is **The Attic**: rarity frames, lore, and a mantelpiece that blesses future lives.
- A pinned strip shows your job, school and business at all times; Work is nested (At work · Find work · Business). The Become-a cards no longer break.

## Also from v0.20
- Share card, endings log, legacy between lives, daily/weekly lives, prison "outside" phase, pet packs and litters, first-life tutorial.

## Checked, and not
- **Checked:** `tools/run_gates.sh` (26 checks), including 39 minigames each played by a bot, the new gambling games settling correctly, and screenshots of the tree, graveyard, attic and gambling screens.
- **Not checked:** the web build was set aside for now. Nothing has been played on real Windows hardware, and the gambling games have not been played by a person for feel.

---

<a id="version-0-25-0"></a>

## Version 0.25.0

# v0.25.0

- **253 new events** (and 12 new follow-ups): every one of the 56 jobs now has two events of its own; school (18); dating (20); gifts (14); drinking (13) and drug use (12), with real habits that build, cost money and health, and can be broken in rehab or therapy; life-threatening moments (16); bad decisions (16); good decisions (14); and unexpected turns (18) such as a letter from a stranger, a surprise inheritance or a career pivot. Follow-ups now reach about a third of all events.
- Two new habits, Drinking and Drug use, sit with the existing ones (Gambling, Shopping, Workaholism, Partying).
- The buttons beside Age are now **Do-Over** (shows how many you hold, asks before it rewinds, opens the Star Shop if you have none) and **Missions** (shows "Claim N" when rewards are waiting). Career and Assets stay in the tab bar below.
- The life-summary card on the left scrolls instead of stretching the screen at large text sizes.
- Art production pack added under `art/` (manifest, style guide, folder layout). No finished art yet.

Earlier in this line:

Since v0.23.0: avatars are now one real emoji, picked whole (skin tone, figure, hair, and a Look such as Wizard, Royal, Ninja, Builder). Nothing is layered any more. An older saved look could leave the portrait blank; that is fixed. Casino: change your bet between rounds (½ / same / ×2) and a streak reminder. Before that, since v0.22.0: controller support removed, avatars returned to the emoji portrait with optional layers.

- Achievements arrive one at a time, each with its own stage, a tier-based sound, a voice, and growing effects (rays, sparks, confetti on the top tiers). A long backlog speeds up.
- Human-like voices (cheer, gasp, sigh, laugh, aww, ouch and more), synthesized in code. Optional drop-in recordings in `audio/voices/`. Setting: Voice sounds.
- Star Shop rebuilt: no purchasable titles, a global rotating shelf, an avatar section, and the Do-Over item that rewinds a year (even a death).
- Avatars are back to the emoji portrait (it still ages with you). Optional layers on top: skin tone, figure, hair, headwear, eyewear, an extra and a backdrop. Leave them on "Match my life" for the plain template.
- 
- Single-column layout at large text sizes, per-mode music and sound for Pets and Prison.
- More events: pets, prison re-entry, workplace, estates, journeys.
- Version numbering moved to 0.x; 1.0 is reserved for the finished game.
- Casino: a visit is now a session. After each round you can play again at the same bet, or leave with Cash out (while you can still cover a bet) or Give up (when you can't). Leaving mid-round loses the stake in play.
- Casino odds are real. Slots had been paying back about 114% and scratch cards about 154%, so players won on average. Every game now returns roughly 88–92% over time (roulette is the real single-zero wheel). Slots: a pair returns your bet and the respin costs a full bet. Scratch card win rate 27% → 15.5%. Rocket and High/Low house edge 4% → 8%. Wheel and high-risk Plinko trimmed.
- Achievements show one at a time with tier sounds, voices and effects.

---

## Version 0.26.0 — recovered local preview

# v0.26.0 — A world that follows your life

- **111 contextual scenarios and 67 follow-ups**, selected for place, the year's saved weather, age, health, lifestyle, education and work. Optional questions share a yearly budget; required consequences survive. Questions shown recently stay out of the pool for at least five years, including duplicate wording under another event ID.
- **24 additional jobs**, each with its own events. Job boards remain stable when switching categories. Relevant degrees, practical courses and experience improve hiring chances while qualifications still gate regulated roles. Employers can still reject a prepared candidate.
- **27 setting scenarios** for the three preset timelines, life paths and special careers. Event availability and world headlines follow the current era; pirates and colonists have setting-specific pools. Timeline jumps clear incompatible queued scenes and refresh job openings.
- **Local stories** develop through a recurring cast without player intervention. Projects can succeed or struggle, affect local demand, accept help and retain their history when the player returns.
- **TVLife**, a fourth mode, includes four characters and 32 ordered chapters across Cartoon, Adult Animation, Anime and Crime / Action. Reflections personalise a saved journal without changing chapter order. An arc's completion is presented as a story ending, including arcs whose character remains alive.
- **Matte Fieldnotes styling**, a revised mode-selection menu, stronger Age button feedback, additional music themes, 12 additional avatar looks and eight additional backdrops in the Star Shop.
- **Normal-life imprisonment** has a persistent custody banner with the remaining sentence and a muted theme. Release restores the selected theme and normal activities.
- **Custom stakes and investments:** enter casino, horse-racing and fight stakes; adjust the next casino stake. Investments include 12 additional stocks/funds, four additional cryptocurrencies and up to 24 recorded yearly prices per asset, shown in small charts. Existing saves retain their prices and gain missing assets.
- **Casino corrections:** advertised odds no longer receive hidden luck multipliers, baccarat player/banker bets push on ties, craps resolves its actual point and hardway rules, Rocket checks crashes before cashing out, and tournament poker retains uncertainty at high skill.

Validation results and limitations are recorded in `VALIDATION-v0.26.0.md`.


## Version 0.28.0 — People Have Lives (local preview)

First milestone of the approved major expansion: 14 branching family arcs,
56 scenes, 168 choices and 336 outcome variants. Adds persistent person IDs,
known parent links, searchable historical records, family memories, richer
child-transfer previews, a projected former-player budget and annual summary.
Retains v0.27's dark UI, mature story additions and minigame refinements.
See [coverage](../releases/V0.28-COVERAGE.md) and
[validation](../releases/V0.28-VALIDATION.md).

## v0.29.0 — More Ways to Live

Local portable preview. Added operating casinos, museums and agencies, luxury
society activities, producer projects/royalties/licensing, non-graphic adult
creator subscriptions and household bills/chores/rest/routine presets.
Fixed large-text panel visibility and title wrapping. First loops are playable;
remaining campaign work is recorded in UPDATE-REGISTER.md. See exact coverage
and validation in releases/V0.29-COVERAGE.md and V0.29-VALIDATION.md.


## v0.30.0 — Growing into yourself

Local portable preview. Monthly infancy, seven first milestones/trophies and 96
age scenes; expanded avatar catalogs and live condition badge; stat readiness;
rare royal/noble birth rules; immediate-family relationship navigation. Added
162 ordinary-job decisions, 30 school questions/practicals, school portfolios,
club/clique/team/talent challenges, student campaigns/council budgets, later
career/hiring effects, martial move assessments, tactical sports, staged civil
claims, exact/fraction/term loans, Crime-panel murder and saved choice history.
Repeat limits/cooldowns and the large-text appearance editor were refined.
See releases/V0.30-COVERAGE.md and V0.30-VALIDATION.md for exact scope and checks.


## Version 0.31.0 — Clearer Everyday Play

Local preview: original monthly infancy and yearly later-life timing retained;
configurable jump withdrawn at the user's request. Added eight paid contextual
activity bundles with preflight, full costs, limits and playable study quiz;
bounded monthly/annual lifestyle changes across all five stats; restored queued
and displayed decisions; search and favourites, Back/scroll and panel trails;
mode-aware help, clear readiness explanations, measured consequences and
organised recaps; 16 later branches for eight earlier choices.
The complete-base-game milestone plan preserves the accepted campaign before
v1.0. This local preview does not complete that campaign or claim BitLife parity.


## Version 0.31.1 — Clear buttons and better shopping

Distinct action/navigation/bundle styles; shorter wording and wrapping menu rows;
11 shopping categories, 8 specialised retailers and 44 named products; 7 primary
home variants and 11 cars with connected pricing/upkeep and additional vector
silhouettes; 37 animal breeds/varieties with saved identity and feeding costs.
Primary-home/car buying moves to Shopping; Assets manages money and ownership.
Age/licence/capacity/price checks are enforced when buying, including after reload.
This is a local addition to v0.31; the larger v0.32 career update remains next.

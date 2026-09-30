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

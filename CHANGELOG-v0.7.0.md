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

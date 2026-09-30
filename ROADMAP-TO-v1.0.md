# ONE MORE LIFE — Roadmap to 1.0

## Release rule
**1.0 is the finished baseline game, not a convenient version number.** A system does not count as complete because its menu opens. It must create consequences, connect to other systems, survive save/load, and generate meaningfully different life stories.

A major feature should normally affect at least three other systems. New event content should aim for at least three choices, at least two possible outcomes per choice, and meaningful delayed follow-ups where appropriate.

## v0.7 — Life Gets Complicated
Status: implemented baseline; retained in every later build.

Core scope:
- Life Threads
- physical illness, symptoms, diagnosis, chronic conditions and treatment
- injuries and rehabilitation
- mental health, therapy, recovery and relapse
- expanded casino and gambling consequences
- meaningful home ownership, renovations, neighbors and household problems
- Pirate Life
- Space Colonist
- Time Traveler (1850 / 1920 / 1970 foundation)
- presentation pass for new systems

## v0.8 — Ambition & Society
Status: **current development build**. Implementation is present; the included runtime test plan remains the release gate.

Core scope implemented in this package:
- Sports Pro: season records, standings, contracts, free agency, trades, postseason, awards, injuries and retirement integration
- Police / Detective: patrol, cases, evidence board, interrogation, cold cases and Internal Affairs
- Doctor / Surgeon: residency/rank integration, specialties, patients, diagnosis, operating-room minigame, complications and malpractice
- deeper Pets: breeding, training, shows, vet care, pet businesses, support animals and inherited family pets
- Business expansion: multiple companies on top of the existing staff/loan/IPO business, plus CEO NPCs, acquisitions, debt, bankruptcy and succession
- Courts / justice expansion: evidence-aware verdicts, pleas/history, appeals, probation, parole and reentry
- career identity for ordinary jobs: projects, reputation, networking, mentors, rivals and training
- 60 new v0.8 events and 19 v0.8 achievements
- presentation pass for professional life

Gate before v0.9:
- [x] run `tools/v08_system_test.tscn` successfully in Godot — passes in 4.4.1 (`sections=4/4 failures=0`)
- [x] run `tools/v08_echo_test.tscn` — proves each v0.8 system changes at least one other system (`checks=25 failures=0`)
- complete `V0.8-TEST-PLAN.md`
- verify v0.7 -> v0.8 save/load migration on real saves
- manually win/fail Evidence Board and Operating Room
- run multi-season sports/free-agency tests
- verify active police/medical cases survive save/load
- verify pet profiles and enterprise succession survive a generation transition
- exercise every v0.8 event and delayed follow-up
- fix any balance/UI/runtime defects found, then repackage the exact tested build

## v0.9 — A Living World
Focus: the simulation continues even when the player does nothing.

Planned scope:
- **NPC Agency 2.0:** NPC education, careers, layoffs, wealth/debt, homes, health, therapy, addictions, crime, justice, relationships, children and death
- **Place 2.0:** neighborhoods, named neighbors, local economy, weather, housing pressure, culture and city identity
- **World-event integration:** recessions, disasters, wars, pandemics, shortages, booms and crashes should modify jobs, prices, housing, health, relationships and crime rather than just print news
- **Life Chapters:** midlife changes, empty nest, divorce/second marriage, widowhood, career reinvention, retirement, grandparenthood and elder identity
- **Billionaire endgame 2.0:** institutions, sports teams, philanthropy, private research/space projects, major estates and long-horizon consequences
- **Special Lives completion:** deeper progression/end states for Celebrity, Vampire, Undead, Villain, Superhero, Royalty, Mob Family and Witch/Warlock
- **Generational continuity:** family-tree relationships, family reputation, businesses, homes, feuds, scandals and obligations persist cleanly when control moves to a child
- **Reputation & social circles:** family / workplace / town / public reputation become more consistently shared inputs across systems
- **Life Threads 2.0:** more thread types, NPC-owned threads, cross-generation echoes and multi-step callbacks
- presentation pass for neighborhoods, world events, decades and elder play

Gate before 1.0:
- NPC simulation can run for multi-generation stress tests without runaway state or broken references
- world events demonstrably alter at least three connected systems each
- every life decade has meaningful age-appropriate content
- special lives have distinct progression and endings, not just extra buttons
- generation continuation preserves expected family/world state
- 0.9 content passes the same depth/validator rules as 0.7 and 0.8

## v1.0 — ONE MORE LIFE
Focus: **completion, cohesion and release quality.** No new version number until the baseline promise is actually finished.

Release gates:
- all baseline design-document systems implemented or explicitly moved to a clearly documented post-1.0 expansion because the design itself changed
- no placeholder systems, dead buttons or obviously templated filler content
- event target met with authored variety rather than duplicate wording
- final event-library depth pass toward the design target for choices, outcomes and delayed callbacks
- all major systems demonstrate cross-system consequences
- long-life and multi-generation simulation passes
- full save migration from supported pre-1.0 versions
- accessibility: complete keyboard navigation, screen-reader/control labels, text scaling, contrast and reduced motion
- every minigame has a fair manual completion path and automated regression coverage where feasible
- full UI pass at supported desktop resolutions and interface sizes
- final SFX / VFX / animation / theme-cohesion pass
- economy, health, addiction, crime, careers, housing, inheritance and generational-balance pass
- performance and long-save testing
- originality/copyright review against the project's own rules
- final validator, release notes and clean packaged build

## Deliberately held for later reveal
- **Twins / multiplayer-style parallel rival system** remains outside the public baseline roadmap until its planned "coming soon" reveal.

## Post-1.0
After 1.0, 1.x patches can fix bugs, improve balance/accessibility and polish existing systems. New large systems become genuine content updates instead of unfinished baseline promises.

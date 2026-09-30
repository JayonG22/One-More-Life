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

Then follow `V0.8-TEST-PLAN.md` before calling the update public-release ready.

# ONE MORE LIFE — v1.3.0

A life simulator in the spirit of BitLife, built in Godot 4.4, where every choice echoes. Everything is unlocked. No ads, no store, no passes.

> **v1.2.0 — three game modes.** The title screen opens on **Choose your game mode**: **Human Life** (the classic), **Pets Life** (live as a dog, cat, rabbit, parrot or horse — v1.1) and **Prison Life** (serve a sentence, or work the walls as a guard — v1.2). Each is its own game with its own year, events, screens and endings. See `CHANGELOG-v1.1.0.md` and `CHANGELOG-v1.2.0.md`.
>
> **v1.0.0.** The baseline game is finished: 760 events and 2,231 choices (none with a single outcome, none with fewer than three options), a real job market and workplace, a care pathway, renting, commuting and keeping up, six life paths with chapters and endings, 22 minigames that a bot has proven winnable, keyboard play, and builds for Windows, macOS and Linux. See `CHANGELOG-v1.0.0.md`. What's next is in `ROADMAP.md`.

## Game modes

| Mode | What you are | Ends |
| --- | --- | --- |
| **Human Life** | A person, from birth. Jobs, money, family, nine life paths. | Death, or a path's ending |
| **Pets Life** (v1.1) | A dog, cat, rabbit, parrot or horse, in one of seven beginnings. A household seen from the floor. | A good life, a hero, a champion, a stray king, lost, an old animal in the sun. Then *another life in the same house.* |
| **Prison Life** (v1.2) | A prisoner (seven stories) or a guard (six). Gangs, parole, an appeal, a jailbreak and its manhunt; a rank ladder, the keys, Internal Affairs. | Paroled · Exonerated · A Ghost · Served it all · Warden · Whistleblower · and eight more |

## Open and play

**Just play:** unzip, then run `Game/Windows/OneMoreLife.exe`, `Game/macOS/` (right-click → Open the first time; it's unsigned) or `Game/Linux/OneMoreLife.x86_64`. No install.

**From source:** open **Godot 4.4** (or newer 4.x) → **Import** → pick `project.godot` → **F5**. The first import takes a few seconds (the emoji font is 10 MB).

The window opens at 1600×900. The layout is designed natively for 1920×1080 and is checked at 1280×720, 1366×768 and 1920×1080. Fullscreen, interface size (90–130%), high contrast and reduced motion are in Settings.

### Controls

| Key | Action |
| --- | --- |
| Space | Age up (or press the selected button, in keyboard mode) |
| 1–6 | The six tabs along the bottom of the screen (in Human Life: Activities, People, Work, Assets, your Life Path, More; each mode has its own six) |
| Tab / arrow keys | Turn on keyboard navigation and move between things |
| Enter / Space | Select |
| Esc / Backspace | Back in the right-hand menu |
| 1–9 (in an event) | Pick that choice |
| Enter / Space (in a result) | OK |

A mouse click turns keyboard navigation off again.

### For developers

```
tools/run_gates.sh /path/to/Godot_v4.4.1-stable_linux.x86_64   # every automated check, one verdict
tools/mig_check.sh /path/to/godot                              # play a real v0.14 save on this build
python3 tools/content/thin.py                                  # any choice with a single outcome
```

Content is authored by scripts in `tools/content/` (read its README for the run order). Tests write to a throwaway folder when `OML_USER_DIR` is set, so they never touch real saves.

## Version history

## New in v0.8.0

- **Professional Life:** major projects, professional reputation, networking, mentors, workplace rivals and training for ordinary jobs.
- **Sports Pro 2.0:** persistent season records, league standings, postseason/finals/titles, contract expiry, free agency, agents, trades, media, teammate chemistry, rival athletes and awards.
- **Police / Detective:** patrol calls, eight investigation types, persistent suspects and witnesses, evidence, interviews, interrogation, warrants, arrests, cold cases, Internal Affairs and an Evidence Board minigame.
- **Doctor / Surgeon:** specialties, symptom-first patients, diagnosis, second opinions, treatment, clinical reputation, research, mentoring, burnout, complications, malpractice and an Operating Room minigame.
- **Deeper Pets:** temperament, health, training, tricks, grooming, shows, breeding, vet care, support-animal certification, five pet businesses and inherited family-pet profiles.
- **Enterprise:** a multi-company portfolio alongside the existing hands-on business system, with CEO NPCs, acquisitions, debt, dividends, bankruptcy and child succession.
- **Justice & Reentry:** evidence-aware trials, persistent case history, appeals, probation/parole and follow-up consequences.
- **Content:** 60 new v0.8 events / 360 outcome branches and 19 new v0.8 achievements.
- **Presentation:** new generated professional SFX plus interactive Evidence Board and Operating Room minigames.

See `CHANGELOG-v0.8.0.md` for the full details.

## v0.7 foundation retained

Life Threads, physical and mental health, meaningful home ownership, expanded casino play, Pirate Life, Space Colonist and the 1850/1920/1970 Time Traveler foundation all remain part of this build.

## New in v0.6.0

- **Relationships.** Every person has their own menu, grouped by what you can do with them:
  - Talk, spend time together, give gifts (each person has a gift they like, which you find out by talking to them), and ask for, lend or give money.
  - Each person has craziness, smarts and generosity, and remembers the 8 biggest things you did to them.
  - **Parents:** ask for advice, tuition or a pet, move back in, throw them a party, care for them when they're old, or cut them off.
  - **Siblings:** squabble, prank, ask favors, babysit.
  - **Your kids:** play, read stories, teach them to ride a bike or drive, help with homework, discipline, allowance, a college fund, tuition, visits, custody fights, disowning.
  - **Romance:** love notes, moving in, and proposals where the ring and the place change the odds. Weddings range from courthouse to destination, with an optional prenup. Also anniversaries, renewing vows, counseling, fertility, and divorce (amicable, in court, or giving up custody; the prenup is honored).
  - **Friends, coworkers, classmates, neighbors, exes, enemies:** parties, set-ups, double dates, best friends, sucking up to the boss, covering shifts, BBQs, rekindling, rumors, fights, lawsuits, making peace.
  - **Pets:** play, walk, train, bathe, treats, the vet.
- **The people in your life live their own lives:** they marry, have kids (your grandchildren, nieces and nephews), divorce, succeed, fail, and ask you for help. Your parents can split up and remarry, which brings a stepparent and stepsiblings. Holidays happen. Your kids' grades are tracked all the way to graduation.
- **Family tree:** aunts, uncles and cousins from birth, plus stepfamily, grandkids, lovers, former friends and enemies. **A new life starts with no grandparents.** They only appear when you continue as your child.
- **Continuing as your child:** your spouse and kids come with you. Set a will (split equally, a main heir, or charity) under Legal. Inheritance tax depends on the country. Siblings remember who got left out.
- **Shopping:** 12 stores (jeweler, electronics, sporting goods, music, fashion, novelty, books, motors, boats, aircraft, collectibles and a shady guy in an alley). Items do things:
  - A ring for proposing.
  - Phones, cameras and webcams for social media.
  - Rods for fishing, a bow or rifle for hunting.
  - A lock pick, night-vision goggles and a disguise for crime.
  - Pepper spray, a bat or a sword against muggers.
  - A suit for interviews and work.
  - Luck charms for the lottery.
  - An 8-ball, a Ouija board, a metal detector, a telescope and a karaoke machine each have their own action.
  - Vehicles, boats and planes that need the matching license.
  - Heirlooms carry a power too. Things lose value over time, and you can sell them.
- **Social media:** Snapgram, Clipz, TubeHub, Streamr and Chirp. Each needs different gear and has its own kinds of posts. Pick a niche and stick to it (posts in your niche do 1.5× better). Other features:
  - Going viral, takes that backfire, charity streams, and tips.
  - Celebrity collabs, sponsors, the blue check, and buying followers (risky).
  - Ad revenue, subscribers, fame, and decay when you go quiet.
- **Everyday life:**
  - Martial arts with belts, diets, the salon, plastic surgery.
  - Doctors: GP, ER, psychiatrist, eyes, chiropractor, alternative medicine, a witch doctor.
  - Nightlife, outings, movies, vacations (alone or with someone), dating (on the street, apps, speed dating, celebrity dating), fertility treatment, adoption, fostering, a name or gender change.
  - School life: cliques, clubs, sports teams and captaincy, the principal, cheating, the talent show, class president, dances and prom. These help your college application.
- **Casino, lottery and horse racing:** roulette, slots, high-low and **playable blackjack**. Horse races with real odds. The lottery shows the actual jackpot, which grows every year until someone wins, plus the odds of every prize tier (luck items improve them). Win the jackpot as a lump sum or an annuity.
- **Dealer pack:** four fictional products, five zones with their own demand and policing, and a choice of pure, lightly cut or heavily cut product.
  - Your product can hurt people.
  - Undercover stings, rival crews and turf wars (a fight).
  - Win over neighborhoods, recruit and pay a crew, and handle loyalty and snitches.
  - Launder money through your business or a front, lie low, get out.
  - Raids start when heat gets high.
- **Prison life:** a prison job, yard fights (a minigame) and respect, joining a gang and moving contraband, card games, snitching, visits, and **escaping**. After an escape you're a fugitive until the marshals catch up.
- **Military:** deploy through a minefield for hazard pay, medals or a lasting wound.
- **Hidden stats:** willpower (how fast habits take hold), discipline (school and work performance) and fertility. A psychiatrist or a fertility test gives a hint.
- **Reworked minigames:** no more reading under a timer.
  - **Audition** is now an action game: emotion faces slide in to be hit on the beat while you stay in a moving spotlight.
  - **Debate** is a tug-of-war for the crowd: match the crowd's color, manage your breath, and time your rebuttals.
  - Pitches, royal addresses and sermons use the same Debate game.
- **New minigames:**
  - **Blackjack.**
  - **Prison Break:** guards move twice, sideways first, and the layout is different every time.
  - **Break-in:** a dark house with sleepers, a dog and a noise meter.
  - **Minefield:** mine counts, sweeps and a time limit.
- **Events don't repeat as much:**
  - About 100 new everyday events, from toddler to retirement.
  - Most events now have several wordings and outcomes that change from life to life.
  - Events you saw in your last few lives are much less likely to come up.
  - Celebrity cameos use an original cast of 30 stars, with no real people.
  - Everyone gets a unique name, from much bigger name lists.
- **Goals:** 17 new ribbons (Houdini, Kingpin, Cat Burglar, Decorated, Influencer, Jackpot, Big Spender, Fertile, Generous, Mooch, Rowdy, Black Belt, Prom Royalty, Model Citizen, Lazy, Loner, Mediocre), 32 new achievements and 11 new missions.

## New in v0.5.0

- **Life Paths.** Pick one at New Life, or stumble into one through a Turning Point:
  - **Royalty:** a line of succession, Respect, royal duties and speeches, coronation and decrees, jubilees, tabloids, scheming cousins and revolutions. Commoners can marry in.
  - **Vampire:** turned at 18 (or bitten in an alley). You stop aging, but the Thirst has to be fed: hunt strangers (stealth minigame), animals, blood banks or loved ones. Starve for three years and you die. Hunters come for the careless.
  - **Undead:** die with unfinished business (a grudge, a young child, bad karma) and you can Rise from the Grave. Your body rots. Settle it, then rest.
  - **Gifted:** powers at 13. Hero or villain: patrols, heists, a nemesis, a secret identity that can be exposed. Flight lets you travel for free.
  - **Witch:** magic wakes at 13. Mana, spells, a familiar, a coven, exposure and witch hunts, and **Potion Brewing**, a 3-phase minigame: pick ingredients by their properties, keep the heat in the green and stir on cue, then bottle inside the band. Unknown properties and recipes fill a **grimoire that carries across lives**. Bad mixes give odd results (explosions, mystery brews, sludge) instead of a plain fail. Potions can be drunk, sold, slipped to someone (Love Philter) or uncorked on an enemy (Hex).
  - The look and sound switch to match (Royal, Vampire, Undead, Superhero, Villain and Witch themes).
- **Places and laws.** Every country has 3–6 regions built from data: cost of living, wages, unemployment, tax, healthcare, schools, transit, housing, crime, hazards and local industries. Driving and drinking ages, gambling, guns, tuition, death penalty, police, corruption, hunting and military service all differ. Move cities from Assets → Where You Live.
- **World events** change the simulation: recessions cut pay and bring layoffs and crime, wars bring the draft and higher prices, pandemics shut borders and nightlife and move school online, the AI revolution raises tech pay and automates other jobs, bubbles inflate and burst.
- **Billionaire endgame** (at $1B): run a sports team season by season (payroll, coaches, fans), fly to space on rockets that can fail, fund a Moon mission, give to foundation causes that change things (schools, cancer research, climate), buy the press, go offshore, or found a **micronation** with its own laws and a legitimacy score that ends in UN recognition or annexation.
- **Licenses:** driving, boating, pilot, firearms, fishing, hunting (two tags a season, poaching bans) and scuba. DUIs, poaching, reckless boating and a failed flight medical suspend them. Emigrating means converting them.
- **Daily Heirloom:** one free heirloom a day, Common to Legendary, with no streak to lose. Duplicates come in better condition. The collection carries across lives, and bad luck is softened over time.
- **Anti-spam:** repeating an activity in the same year pays less each time and starts to cost you (a third party, a fourth gym session). A few have hard yearly limits. Stats also get harder to push near 100.
- **Your Lives:** 12 save slots with cards (portrait, city, occupation, net worth, generation, difficulty, last played). Load, favorite, rename, duplicate, delete. Automatic backups and corruption recovery. Your old v0.4.0 save moves into a slot on first launch.
- **Presentation:** a new title screen, transitions, animated themed backgrounds, a Life tab, bigger portraits, generated ambient music per theme, new sounds (potions, magic, bites, crowns, rockets, news) and separate Master, Music, Effects and Interface volumes. Flashes and screen shake have their own switches.
- **Content:** 53 new events and Turning Points for the life paths, the world, the billionaire endgame and places. 39 new achievements (a new Other Lives category) and 10 new missions.

## New in v0.4.0

- **Turning Points:** 47 rare, run-rewriting twists with their own dramatic popup (a TURNING POINT banner, a sting, a red flash and a shake). They include identity theft, a house fire, a wrongful conviction, finding adoption papers, a secret sibling, a spouse's second family, witness protection (new name, new country, everyone left behind), a coma that skips years, a bank collapse, a pandemic, a market crash, a stranger's will, becoming guardian of a sibling's kids, an embezzling accountant, a cold case, overnight fame, a lottery win, a cancer diagnosis, a kidney donation, a stalker, a kidnapping, a hurricane, a war draft, a plane crash, a hit and run, and more. 11 of them start arcs that come back years later (the thief is caught, exoneration, remission or relapse, meeting your birth family, the whistleblower reward). Each one happens at most once per life. Your karma tilts the outcomes (the Lucky Star boon tilts them further).
- **Difficulty** at New Life: **Classic** (forgiving, fewer Turning Points), **Real** (the default) and **Gritty** (about 1.6 times as many Turning Points as Real, plus harder falls, stiffer sentences, faster aging, slower healing, higher costs and stricter banks).
- **Scars:** 12 permanent marks from accidents, fights, fires and disasters. Each one lowers a stat's ceiling (a bad knee caps health at 85, a facial scar caps looks, being haunted caps happiness). Some can be treated under Health → Treat an old injury.
- **Habits:** gambling, shopping, workaholism and partying build up as you repeat them. Once one takes hold it costs you every year, with a resist-or-give-in popup. Break it with Rehab or Therapy. Relapse is possible.
- **Credit and debt:** a credit score from 300 to 850 that mortgages and business loans depend on. Being in debt brings collection fees, then repossessions, then an offer to declare bankruptcy (clears the debt, sinks your credit for 7 years).
- **Grudges:** seriously wronging someone (firing, suing, dumping, fighting) makes them hold a grudge. Grudges fade slowly and can turn into payback: a lawsuit, sabotage at work, rumors, turning your family against you, tipping off the police, or a fight in the street. Make amends from their profile. Big grudges pass to your heirs as family feuds.
- **Consequences of neglect:** adult children you ignore can cut you off. In old age, who looks after you depends on how you treated your family; with nobody close, you end up in a nursing home.
- **Achievements:** 205 achievements across 12 categories and 4 tiers in the **Trophy Room**, with prerequisite chains (locked tiles show what opens them) and secret ones. Unlocks pop up as toasts mid-game.
- **Missions:** daily (3), weekly (5) and monthly (8) boards that reset on the real calendar, like BitLife's challenges. Progress counts across every life you play in the period. Clearing a board pays a bonus.
- **Stars and the Star Shop:** earned from achievements and missions (never paid). Spend them on 16 titles (achievements unlock 8 more) and 8 **Legacy Boons** you can choose at New Life: Trust Fund, Gifted, Second Wind, Lucky Star, Iron Will, Family Ties, Clean Slate and Street Smarts.
- **The death screen** adds "What caught up with you" (scars, habits, bankruptcies, grudges, estranged children, Turning Points survived) and the achievements unlocked that life.
- v0.3.0 saves load in v0.4.0.

## New in v0.3.0

- **Career minigames.** Every special career now has its own playable minigame instead of just a result roll:

  | Career | Minigame | How it plays |
  | --- | --- | --- |
  | Actor | Audition | Match the director's emotion before the clock runs out (keys 1–4) |
  | Musician | Live Set | Four-lane rhythm game on D F J K, for gigs and tours |
  | Athlete | Clutch Moment | Stop the needle in the zone; pick a corner in soccer and hockey |
  | Politician | Debate | Read the crowd and answer with Facts, Heart or Attack |
  | Mafia | Safecracker | Feel for three numbers on the dial before the alarm trips |
  | Hustler | Pickpocket | Hold to lift and let go before the mark looks your way |
  | Astronaut | Docking | Thrust into the station port slowly with limited fuel |
  | Model | Runway | Watch the pose sequence and repeat it; it grows every walk |
  | Fighter | Fight Night | Block high or low on the telegraph, then counter-strike |
  | Director | On Set | Keep lighting, performance and camera in the green |
  | Secret Agent | Infiltration | Turn-based stealth grid with patrolling guards |
  | Outdoors | Fishing | Keep the line tension in the green while you reel |

  The Debate game is reused for investor pitches (Business) and sermons (Cult), each with its own lines. Every minigame has an intro card, a **⚡ Auto-play** button that rolls from your skill, and a star-rated result. You can turn minigames off in Settings; your skill then decides.
- **5 new careers:** **Astronaut** (training, missions, research, school visits), **Model** (shoots, runway, portfolio, agencies, brand campaigns), **Fighter** (weight classes, nickname, fight camp, a win-loss record, title belts), **Director** (budgets, casting people you actually know, shooting, box office, awards) and **Secret Agent** (a cover story, recruiting the people you know as assets, operations, suspicion from your partner).
- **Careers carry over.** Past careers give you an edge in the next one (a model becomes a better actor, an astronaut a more trusted politician, a former agent cools heat faster), in the business industries they match, and in events.
- **Business:** 12 industries (from a restaurant to a private space company). Your past careers, your degree and the people you know give you an edge in matching industries. You can improve the product, run marketing, star in your own ads, hire staff or people you know, pitch investors (minigame), take bank loans, cook the books, launder money, IPO on the stock market, sell shares, get ousted by the board, sell or close the company. Revenue follows quality, marketing, your fame and the market.
- **Black Market:** unlocked by a criminal record, a crime career or a shady friend. You can fence stolen goods, buy hot merchandise, knockoff watches (dealers can spot them), forged passports (a one-time escape from the country) and forged diplomas (HR might check), buy exotic animals, and sell counterfeits. Any deal can be an undercover cop.
- **Cult:** 5 doctrines with different recruiting, donations and heat. You can recruit on the street or from your fans, give sermons (minigame), hold rituals, collect donations, invite family and friends into your inner circle, build a compound on property you own (a private island hides it best), and put followers to work at your business or zoo. Exposés, defectors, tax trouble and raids can follow.
- **Zoo:** buy land and animals (18 kinds, including smuggled ones), hire keepers or people you know, and throw festivals. Visitors come for variety, star animals and your fame. Animal welfare decides births and deaths, and dangerous animals escape and lead to lawsuits. Inspectors come for smuggled animals, and a vet friend keeps your animals healthy.
- **Outdoors:** camping (bring family, friends or pets), hiking, fishing and deep-sea fishing (boating license or a yacht), dirt biking (motorcycle license) and cave diving. There's a **Wildlife Journal** of 24 animals and 16 fish, finds (fossils, meteorites, gold) that become possessions, and a **Museum** that names a wing after you.
- **The connection web.** Adults you know now have jobs, shown in Relationships and on their profile. Some jobs are perks: a lawyer friend defends you for free, a cop friend warns you or makes a charge vanish, a doctor or nurse treats you, a vet treats your pets, a banker approves your loans, an accountant protects you in audits, and a journalist can kill a story. Hiring them into your business costs you that perk.
- **Heat** is now one shared meter for all crime, fraud, cults, the black market and smuggling. It shows on the main screen, cools with **Lay low**, and investigations follow when it runs hot.
- **102 new events** (299 total) for the new careers, the empires, heat and the people you know. Some of them launch minigames.
- v0.2.0 saves load in v0.3.0.

## New in v0.2.0

- **6 special careers**, each with ranks, its own actions and a career panel: **Actor** (auditions, agents, filmography, sequels, awards), **Musician** (solo or band, songs, singles, albums with Gold/Platinum/Diamond, tours, labels), **Pro Athlete** (8 sports, drafts, contracts, injuries, championships), **Politician** (campaigns from city council to president, approval, bills, scandals), **Mafia** (jobs, loyalty, heat, rise to Godfather, or turn rat), **Street Hustler** (monte, knockoffs, territory, cop heat).
- **Fame and social media:** a Fame stat and followers, posting photos and videos, going viral, live streams with tips, brand deals, and celebrity status at 88 fame (which can switch the game to the Celebrity theme).
- **Savings and investments:** a savings account with interest, 8 fictional stocks with sectors, 3 cryptocurrencies, and yearly market booms and crashes.
- **Property:** buy from a yearly listing (studio condo up to a private island), tenants as real people, rent, repairs, renovations, rent rises and evictions.
- **Possessions:** jewelry, art, collectibles and vehicles whose value moves over time; they pass down as heirlooms.
- **Courts and law:** trials with three lawyer tiers and plea deals, suing anyone (and being sued), and 5 licenses (driver's, motorcycle, boating, firearms, pilot).
- **God Mode (free):** edit your stats, karma, fame, money, traits and any person's relationship, looks and age.
- **Life Modifiers (free):** Golden Passport, Golden Piggy Bank, Star Power, Golden Diploma, Brass Knuckles, Get Out of Jail Card. Lives using them are tagged **Modified** and counted separately.
- **13 Challenges** with live checklists on the main screen and badges that appear next to your name.
- **Ribbon collection** across every life you have played.
- **123 new events** (197 total).
- **Feel & polish:** 17 procedurally generated sound effects with a different flavor per theme, spring-in popups, button squish, animated stat bars with floating +/− numbers, rolling money counter, confetti, hearts, coins and sparks, screen shake and color flashes, a slow fade on death, and themed background filters (vampire vignette, undead haze, celebrity sparkle, villain scanlines, superhero halftone).
- **Settings:** sound volume, visual effects on/off, reduced motion, and whether fame switches your theme.
- v0.1.0 saves load in v0.2.0.

## What's in this build

- **New Life:** portrait picker, first and last name with dice, Male, Female or Non-Binary, 9 birthplaces, 2 traits, and Standard, Custom (set your stats) or Random life.
- **Main screen:** stats (Happiness, Health, Smarts, Looks, Stress), the life log, the big **+ Age** button, a yearly Time budget (12 points), and the tab bar.
- **Event engine:** 74 original events. Choices can require traits or money, outcomes are weighted by traits and stats, and flags and **follow-ups years later** make choices echo (the lunch-money bully can become your boss). Named NPCs persist.
- **NPCs act on their own:** people you're very close to, or feuding with, will gift you money, set you up on dates, spread rumors, steal from you or sue you.
- **School:** report cards every year, GPA, study or skip class, graduation.
- **University:** 18 majors plus 7 graduate schools (Law, Medicine, MBA, Dental, Pharmacy, Vet, PhD). Admission and scholarships depend on GPA, and unpaid tuition becomes student loans.
- **Jobs:** 55 jobs across part-time, full-time, trades and military. Yearly listings are based on your degree, major, age, smarts and criminal record. You go through interviews with real questions, a promotion ladder (4–8 ranks), performance, raises, getting fired, quitting, retirement and a pension. Freelance gigs are also available.
- **Cost of living:** rent, living costs, mortgage, car upkeep, kids and loan payments are summarized in one log line a year. Debt leads to eviction or foreclosure.
- **Relationships:** family, extended family, partner, friends, pets and others, each with a relationship bar. Actions include spending time, gifts, asking for money, arguing, dating, proposing, a courthouse, small or lavish wedding, trying for a baby (twins and triplets possible) and divorce settlements.
- **Activities:** Mind & Body, Entertainment, Social, Education, Love, Crime, Health and Miscellaneous (vacations, pets, casino, lottery, emigrating), plus **Routines** that run automatically each year. There are separate prison activities.
- **Crime and prison:** getting caught brings fines or sentences, a criminal record that blocks some jobs and lowers visa odds, appeals, riots and good behavior.
- **Health:** illnesses (minor ones pass, serious ones need a doctor), aging, stress and a hospital warning before a fatal collapse.
- **Death:** a tombstone with a Ribbon, a Death / Legacy card, a readable **Life Story**, and **Continue as Child** where the family carries over (your siblings become aunts and uncles and you receive an inheritance).
- **Family Tree** and a **Graveyard** of every past life.
- **9 themes:** Dark (the default), Light, Celebrity, Vampire, Undead, Villain, Superhero, Royal and Witch. Switch them from More or the title screen.
- **Autosave** every year, with Continue Life on the title screen.

## Project layout

```
OneMoreLife/
  project.godot
  autoload/
    content_db.gd     loads all JSON data
    careers.gd        the special careers, fame and social media
    new_careers.gd    Astronaut, Model, Fighter, Director, Secret Agent
    minigames.gd      routes careers to minigames, or auto-plays them from skill
    web.gd            NPC jobs and perks, the shared Heat meter
    empires.gd        Business, Black Market, Cult, Zoo, Outdoors
    grit.gd           difficulty, scars, habits, credit and debt, grudges, old age
    twists.gd         picks the rare Turning Points
    goals.gd          achievements, missions, Stars, titles, boons and daily heirlooms
    lives.gd          Life Paths: royalty, vampires, the undead, the gifted, witches
    world.gd          world events and the billionaire endgame
    places.gd         regions, local laws, crime and natural hazards
    finance.gd        savings, stocks, crypto, property, possessions
    law.gd            trials, lawsuits, licenses
    meta.gd           life modifiers, challenges, ribbon collection
    fx.gd             procedural sound and music synthesis, audio buses
    game_state.gd     the character, NPCs, flags, log, save data, legacy
    event_engine.gd   the yearly loop, event picking, outcomes, death
    actions.gd        everything the player can do (activities, jobs, school, prison, assets)
    bonds.gd          relationships: every person's menu, living NPCs, family events, weddings, divorce
    daily.gd          everyday life: health, looks, nightlife, trips, dating, casino, lottery, school life
    shop.gd           the 12 stores, item powers and heirloom powers
    social.gd         the 5 social platforms and the celebrity cast
    dealer.gd         the dealer pack
    theme_manager.gd  the 9 themes, built in code from color palettes
    save_manager.gd   12 save slots with backups, graveyard, settings (in user://)
  scenes/
    main.tscn / main.gd   every screen (title, new life, game, event card, death, graveyard)
    ui_kit.gd             small UI helpers (rows, bars, icon buttons, faces)
    empire_panels.gd      the Business, Black Market, Cult, Zoo and Outdoors panels
    lives_panels.gd       the Life Path, World, Billionaire and Where You Live panels
    slot_panels.gd        Your Lives (save cards) and the Daily Heirloom
    menu_panels.gd        draws the data-driven menus from bonds, daily, shop, social and dealer
    minigames/            the minigame base class and the 17 minigames
    vfx.gd                particles, shakes, flashes, tweens, floating numbers
    theme_filter.gd       per-theme background shaders
  data/
    events/*.json     all events, by category
    achievements.json missions.json
    jobs.json majors.json countries.json names.json traits.json interviews.json challenges.json
  fonts/              Nunito (UI) and Noto Color Emoji, both under open licenses
  tools/
    sim_test.tscn     balance simulator: plays random lives and prints stats
    ui_test.tscn      screen tour: clicks through every screen and saves screenshots
    career_test.tscn  plays one life per special career and reports rank and income
    audio_test.tscn   generates every sound in every theme and checks them
    migrate_test.tscn loads an old save and keeps playing
    empire_test.tscn  runs businesses, cults, zoos, black markets and outdoor trips for decades
    mg_bot.tscn       mashes random keys in every minigame (they must finish without errors)
    mg_smart.tscn     a competent bot for every minigame (proves each can be won)
    ui_t3.tscn        screenshots of every minigame and the v0.3.0 panels
    ui_t4.tscn        screenshots of Turning Points, the Trophy Room, Missions, Star Shop and the grit readout
    ui_t5.tscn        screenshots of the v0.5.0 screens (set RES for other resolutions)
    reach_test.tscn   proves every v0.5.0 achievement can be earned
    reach6.tscn       proves every v0.6.0 achievement can be earned
    menu_crawl.tscn   opens every new menu at 7 ages and runs every action
    migrate6.tscn     loads a v0.5.0 save and plays on with the v0.6.0 systems
    ui_t6.tscn        screenshots of the v0.6.0 screens and minigames
```

## Adding your own events

Events are plain JSON in `data/events/`. Add one to any file and it's live on the next run.

```json
{
  "id": "adult.surprise_puppy",
  "icon": "🐕",
  "title": "A box on the porch",
  "text": "{friend.first} left a box on your porch. It's whimpering.",
  "conditions": { "age": [18, 80] },
  "roles": { "friend": { "relation_any": ["friend", "best_friend"] } },
  "cooldown": 10,
  "choices": [
    { "label": "Open it", "outcomes": [
      { "weight": 3, "text": "A puppy! {friend.first} knows me too well.", "effects": { "happiness": 10 }, "relationship": { "friend": 10 } },
      { "weight": 1, "text": "It's a raccoon. It is not happy.", "effects": { "health": -3 } }
    ]},
    { "label": "Call {friend.first}", "requires": { "trait": "Loyal" }, "outcomes": [
      { "text": "We laughed for an hour.", "effects": { "happiness": 4 } }
    ]}
  ]
}
```

**Conditions:** `age`, `flags`, `not_flags`, `traits_any`, `employed`, `in_school`, `university`, `has_partner`, `married`, `has_children`, `has_car`, `housing`, `min_money`, `min_stat`, `retired`, `prison`, `chance`, `career`, `career_rank_min`, `in_office`, `min_fame`, `celebrity`, `has_property`, `has_investments`, `has_possessions`, `license`, `agency`, `has_business`, `biz_ind`, `public_company`, `cooked_books`, `has_cult`, `min_members`, `doctrine`, `has_zoo`, `zoo_animal`, `min_heat`, `max_heat`, `past_career`, `min_trips`, `has_pet`, `has_record`, `max_stat`.

**Turning Points:** add `"twist": true` to an event and it leaves the everyday pool. It fires at most once per life through the Turning Point roll, with the dramatic popup. Add `"followup_only": true` as well for an arc that only arrives through `schedule`.

**Roles:** `{"relation": "mother"}`, `{"relation_any": [...]}`, `{"new": "rival", "age": "same"}` creates a persistent NPC, and `"or_new": true` falls back to creating one. `{"contact": ["lawyer", "cop"], "min_close": 30, "optional": true}` picks the closest person you know with one of those jobs, and `{"from": "biz_crew" | "cult_inner" | "zoo_crew" | "exotic_pet"}` picks someone from your empires. A choice with `"requires": {"role": "x"}` only shows when that role was found, and `"requires": {"has_zoo": true}` (or `has_business`, `has_cult`) only shows when you have one.

**Outcome keys:** `effects` (happiness, health, smarts, looks, stress, karma, money, school, job_perf, fame, skill, approval, respect, heat, cred), `relationship`, `relation_change`, `flags`, `unflags`, `schedule` (a follow-up event N years later), `new_partner`, `set_boss`, `hire`, `fired`, `quit_job`, `jail`, `fine`, `illness`, `cure`, `milestone` (goes in the Life Story), `trait_bonus`, `stat_bonus`, `karma_bonus`, `career_start`, `career_quit`, `take_office`, `actor_role`, `trial`, `emigrate`, `marry`, `clear_record`, `appraise`, `fight_win`, `use_jail_card`, `play` (launches a minigame, e.g. `{"id": "fishing", "kind": "fishing"}`), `empire` (e.g. `biz_boost`, `biz_hit`, `biz_buzz`, `cult_grow`, `cult_devotion`, `cult_shrink`, `cult_disband`, `zoo_rating_up`, `zoo_rating_down`, `zoo_baby`, `zoo_confiscate`, `bm_known`, `random_find`, `biz_embezzle`, `biz_double`, `biz_close`, `zoo_plague`), `scar` (a scar id), `habit` (`["gambling", 20]`), `credit`, `debt`, `grudge` (`{"role": 50}`), `grudge_clear`, `lose_money_pct`, `lose_savings_pct`, `lose_possessions`, `lose_property`, `house_destroyed`, `market_crash`, `new_identity`, `coma` (`[1, 4]` years), `clear_prison`, `nursing_home`. `keep_role` can be a list, and roles named in `relation_change` or `new_partner` are kept automatically when `discard_unkept` is on.

**Text tokens:** `{role.first}`, `{role.last}`, `{role.name}`, `{role.he}`, `{role.him}`, `{role.his}`, `{role.He}`, `{role.rel}`, `{me.first}`, `{biz}`, `{cult}`, `{zoo}`, `{career}`.

Events with no `choices` but with `outcomes` resolve silently into the log.

## Testing

- **Balance simulator:** open `tools/sim_test.tscn` and press F6. It plays random lives and prints average lifespan, causes of death, ribbons, and any events that never fired. Set `SIM_DIFF` to `classic`, `real` or `gritty`. The last runs (40 starting lives each, plus heirs): Classic averaged 63.5 years with 1.2 Turning Points per life, Real 61.8 years with 2.2, and Gritty 55.4 years with 2.9. A 60-life run across every life path finished with no errors.
- **Screen tour:** run `tools/ui_test.tscn` to click through every screen. Screenshots are saved to `user://shots`.
- **Career check:** `tools/career_test.tscn` plays one life per special career and reports the rank and income reached.
- **Sound check:** `tools/audio_test.tscn` builds all 119 sound variants and reports their size.
- **Save check:** `tools/migrate_test.tscn` writes an old-format save, loads it into a slot and keeps playing with the v0.5.0 systems.
- **Life paths:** set `SIM_PATHS=1` on the simulator to rotate through every life path. `tools/reach_test.tscn` plays focused lives for each path and the billionaire endgame and lists any v0.5.0 achievement that can't be earned (the last run: none).
- **v0.5.0 screens:** `tools/ui_t5.tscn` screenshots the new title, New Life, a witch life, potion brewing, places, the world, the billionaire panel, heirlooms, Your Lives, settings and rising from the grave. Set `RES=2560x1440` (or any size) to test other resolutions.
- **Empire check:** `tools/empire_test.tscn` runs every business, cult, zoo, black-market and outdoors action over 8 lives and prints what happened.
- **v0.6.0 checks:** `tools/menu_crawl.tscn` opens every relationship, everyday-life, shop, social and dealer menu at 7 ages and runs every action, about 12,000 of them, with no errors. `tools/reach6.tscn` plays three focused lives and lists any v0.6.0 achievement it couldn't earn (the last run: only the secret lottery jackpot, 1 in 2.5 million a ticket). `tools/migrate6.tscn` loads a real v0.5.0 save and plays on. `tools/ui_t6.tscn` screenshots the new screens and minigames. The last balance runs (40 lives each): Classic 64.9 years, Real 63.8, Gritty 59.4, with no errors.
- **Minigame checks:** `tools/mg_bot.tscn` (random input: every game must end cleanly) and `tools/mg_smart.tscn` (a good player: every game must be winnable). The last smart run won all 17, and brews a Masterwork potion.

## Exporting

When you export, add `*.json` to **Export → Resources → Filters to export non-resource files**, so the `data/` folder ships with the game.

## Sound and effects

All audio is synthesized in code at runtime (`autoload/fx.gd`), so nothing is downloaded and no audio files ship with the project. Each theme changes the pitch and waveform, so the Vampire theme sounds lower and darker while the Superhero theme is punchy. Each theme also has its own generated ambient music loop. Master, Music, Effects and Interface volumes, flashes and screen shake are separate in **Settings** (title screen or More).

## Credits

- UI font: Nunito, SIL Open Font License (`fonts/LICENSE-Nunito-OFL.txt`).
- Emoji: Noto Color Emoji by Google, SIL Open Font License (`fonts/LICENSE-NotoColorEmoji.txt`).
- All event writing is original to this project.

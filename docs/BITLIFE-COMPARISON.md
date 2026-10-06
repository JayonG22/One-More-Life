# BitLife comparison and content gap audit

Prepared 2 October 2026 against the local **One More Life v0.28 preview**.
This is the pre-update audit; subsequent work is tracked in the
[ongoing register](UPDATE-REGISTER.md) and [v0.29 coverage](releases/V0.29-COVERAGE.md).

## What the comparison tells us

We have broad coverage of life-simulator categories. We do not yet have equivalent
depth throughout those categories. The largest problems are incomplete playable
routes, small or generic catalogs, and systems that do not sufficiently affect
one another. More random scenes alone will not close those gaps.

This is a source-backed planning audit, not a claim of complete BitLife parity.
BitLife's free game and paid content are both considered. Official help and recent
developer announcements are the strongest evidence; community documentation fills
menu-level gaps and may lag updates. I did not purchase and play every BitLife pack
on both mobile platforms. Items requiring that verification are identified below.
Our local source was inspected; the previously approved future campaign is **not**
counted as delivered functionality. No gameplay changes are part of this report.

## Our actual starting point

The checked local catalogs contain **81 ordinary job templates with 279 rank
entries**, **25 education-major entries**, **14 countries**, **11 registered
special careers**, and **39 registered interactive minigames**. Dealing has a
separate system outside the special-career registry. There are **393 achievement
definitions**, **66 mission definitions**, and **13 challenge definitions**.

These are definitions, not proof of equally distinct experiences or a percentage
of BitLife coverage. Promotions within one profession are not separate careers.
A bond fund is not a complete individual-bond market. A named route is not
necessarily a management game. Story branches are not unrelated new stories.

Status language:

- **Present:** an implemented local system with playable actions or ongoing rules;
  this does not mean equivalent depth or balance.
- **Partial:** useful functionality exists, but a substantial part of the loop is missing.
- **Scaffold:** entry conditions, a payment, a flag or flavor text exist without the promised loop.
- **Missing:** no dedicated equivalent was found in the inspected local source.
- **Verify:** insufficient evidence for a precise comparison; do not advertise parity.

## Life from beginning to end

The BitLife baseline here draws on its [profile documentation](https://bitlife-life-simulator.fandom.com/wiki/Profile),
[education documentation](https://bitlife-life-simulator.fandom.com/wiki/Education),
[relationship documentation](https://bitlife-life-simulator.fandom.com/wiki/Relationships),
and [official help](https://bitlifeapp.com/help/). Community pages describe existing
menus rather than guaranteeing current behavior on every platform.

| Area | BitLife baseline | Our implemented position | Gap or recommended next work |
| --- | --- | --- | --- |
| Birth and character setup | Generated family, identity, location and profile | Present: origins, traits, difficulty, country and life-path choices | More origins with practical effects throughout childhood; distinguish biography from lasting rules |
| Character editing | God Mode character creation/editing | Present: start options, modifiers and full-stat sandbox panel | Compare editor breadth and achievement rules; expand beyond stat editing if needed |
| Childhood | Family and school events | Present: relatives, school progress and authored events | More persistent childhood friends, responsibilities, home circumstances and memorable milestones |
| School social life | Classmates, faculty, popularity, cliques and extracurriculars | Present: cliques, clubs, teams, captaincy, nurse, principal, cheating, dance and prom | Make membership involve named people, projects and recurring conflicts rather than mostly bonuses |
| Further education | University and postgraduate paths | Present: enrollment, prerequisites, degrees and education costs | Broader subjects; distinct campus life; apprenticeships, course interruptions and adult returns |
| First independence | Jobs, relationships and assets | Present: part-time work, moving out, renting and transport | Connect leaving home to deposits, furniture, family help and a sustainable weekly life |
| Friends and wider cast | Family, friends, partners, exes, classmates and coworkers | Present: extended relatives, NPC links, invitations, social drift and memories | More NPC initiatives, motives and repair paths; avoid repeated interaction spam |
| Dating | Relationship development | Present: ordinary, premium, speed and celebrity dating; date venues | Compatibility and values should drive outcomes; richer rejection, uncertainty and long-distance chapters |
| Marriage | Proposals, wedding choices and prenups | Present: proposal, rings, weddings, agreements and relationship stages | Shared households, joint commitments, anniversary memories and life-plan discussions |
| Separation | Breakups/divorce and financial consequences | Present: divorce, custody/support-related rules and relationship consequences | Sustained co-parenting schedules, mediation, recovery and blended-household continuity |
| Parenthood | Biological, adoptive and stepfamily relationships | Present: fertility tests, IVF, insemination, surrogacy, adoption, fostering and child interactions | More pregnancy/parenting chapters, childcare trade-offs and independently developing children |
| Health and appearance | Medical, wellness and cosmetic activities | Present: diagnoses, injuries, mental-health care, referrals, waits, medication, ageing and cosmetic services | Unify overlapping healthcare menus; longer treatment, accommodation and recovery histories |
| Dependence and recovery | Mature health/life content | Present: habits, rehab and consequences | More relapse/support stories and gradual recovery; verify exact BitLife condition coverage separately |
| Retirement | Career and life endings | Present: retirement, pensions and ageing rules | A substantial playable chapter: phased work, friendships, care arrangements, mentoring and purpose |
| Death and generations | Life endings, heirlooms and generational play | Present: confirmed non-graphic ending, estate succession, family tree and records | Estate administration, ownership clarity, disputes and remembered family decisions |
| Living-child transfer | Child viewpoint change is described in community relationship documentation | Present: change to a living child's recorded age, money, school/job and stats; parent stays alive | Expand background obligations and ambitions; former players currently have simplified yearly budgets, not full autonomous play |

## Careers and paid-content breadth

BitLife's [official help](https://bitlifeapp.com/help/) establishes special careers
and business management. Its [occupation inventory](https://bitlife-life-simulator.fandom.com/wiki/Careers/Occupation)
describes ordinary, freelance, part-time and military paths. Pack-level comparisons
also use the sources linked directly in the rows.

| Career or pack | Our status | What needs adding or deepening |
| --- | --- | --- |
| Ordinary professions | Present: 81 templates across 29 fields; hiring screens, interviews, offers, employers, bosses, reviews, promotion/demotion and dismissal | Broaden occupations after a title-by-title catalog comparison. Give professions distinctive tasks, cases, clients, contracts and failure/recovery routes |
| Part-time and freelance | Present, but narrower than a complete portfolio-work simulation | Multiple simultaneous contracts, hourly schedules, repeat clients, invoices and competing commitments. BitLife documents multiple part-time jobs and advertised freelance gigs |
| Military | Present: ordinary military ladders and deployment minefield | Audit branch/enlisted/officer breadth; more postings, colleagues, transitions and veteran life. BitLife's community occupation page lists five branches |
| Actor | Present: auditions, roles and awards | Expand recurring casts, agent negotiations, long-running shows and productions with distinct demands; detailed counterpart verification remains necessary |
| Musician | Present: songs, albums, bands and tours | More collaborators, contracts, release histories and audience tastes; musician is not a substitute for producer |
| Music producer | **Missing dedicated loop** | Beat/project production, artist collaboration, licensing and a lasting catalog. Official developer notes announce the producer pack in the [App Store history](https://apps.apple.com/cg/app/bitlife-life-simulator/id1374403536) |
| Pro athlete | Present: eight sport choices, teams, contracts, awards and career actions | Sport-specific seasons, selection, meaningful rivalries, injuries, retirement and second careers |
| Politician | Present: campaigns, offices, approval and re-election | Local issues, promises, coalitions and constituents; avoid an expensive generic rank ladder |
| Mafia | Present: organization, standing and crime actions | Audit membership relationships, informant and witness-protection paths rather than assuming parity from a rank list |
| Street hustler | Present: street actions and progression | Distinct gigs, locations, recurring contacts and consequences; verify detailed counterpart breadth |
| Dealer | Present: fictional products, supply, turf, rivals, crews, heat and laundering | More continuing customer/crew stories and consequences; dedicated BitLife cartel-rank parity still needs verification |
| Astronaut | Partial: entry requirements, training, five mission prompts, docking, research and outreach | Academy progression, mission families, discovery/probe logs and communications. The [community astronaut guide](https://bitlife-life-simulator.fandom.com/wiki/Astronaut) documents academy training, exploration and discoveries absent from our dedicated career loop |
| Model | Present: portfolio, agency, shoots, runway and brand campaign | Richer audition briefs, professional relationships and contract decisions; agency is currently much simpler than a management ecosystem |
| Fighter | Partial: camp, five weight classes, records, belts, rivals and an interactive fight | A learnable move catalog, coaches, persistent opponents and distinct tactics. BitLife officially advertises **200+ moves**, coaches and interactive MMA in [Ultimate Fighter Mode](https://bitlifeapp.com/whats-new/ultimate-fighter-mode/); our current game does not match that breadth |
| Movie director | Partial: budgets, lead casting, filming minigame, film history, box office, awards and festivals | Our seven genres are randomly assigned. Add genre choice, auditions for several roles and continuing cast/crew drama. BitLife's [September 2026 pack](https://bitlifeapp.com/whats-new/movie-director-expansion-pack-is-out-now/) documents eleven selectable genres, auditions, set drama, awards and festivals |
| Business owner | Partial: twelve industries, quality, marketing, staff, known hires, annual revenue/profit, ownership/IPO-related rules; additional enterprise actions | Product/service lines, suppliers, pricing, inventory and facilities need fuller loops. BitLife's official help explicitly describes supplier selection, launching/removing products, market research and facilities |
| Secret agent | **Partial and structurally different:** a personal employed career with missions, recruited assets and cover suspicion | An owned agency with hired/trained operatives, assignments and equipment is missing as a dedicated business. The [community achievement inventory](https://bitlife-life-simulator.fandom.com/wiki/Achievements) documents agency prestige, operatives and gadgets |
| Cult | Present: doctrines, recruitment, donations, devotion and exposure | Deeper member/leadership relationships, compound choices and succession. [BitLife's cult guide](https://bitlife-life-simulator.fandom.com/wiki/Cult) describes commune purchases and chosen doctrine/philosophy |
| Zoo | Partial: animals, keepers, care load, welfare, capacity, income and inspections | Individual animal histories, richer habitats, breeding and exchanges. The [BitLife zoo inventory](https://bitlife-life-simulator.fandom.com/wiki/Zoo) describes eight habitats and a much wider species catalog |

## Money, possessions, activities and trouble

| Area | Our status and evidence | Gap or recommended work |
| --- | --- | --- |
| Household money | Present: income, tax, rent/utilities, mortgage, living costs and dependencies across several systems | One household ledger, shared ownership/accounts and consistent affordability feedback |
| Credit and debt | Present: four lenders, credit requirements, rates/terms, repayment, collectors and bankruptcy | Hardship arrangements, restructuring, disputed debts and recovery. Do not mistake these for missing systems |
| Investing | Present: eighteen individual stock tickers, a broad-market fund, a bond fund, seven fictional cryptocurrencies and price histories | Individual fixed-term bonds, differentiated funds/advice and fuller reporting require review. Our two funds currently use the general price-market mechanism; fund labels alone do not establish equivalent financial behavior |
| Owning and renting property | Present: seven property types, tenants, renovation, rent changes, eviction and sale | Richer tenant screening, leases, amenities, disputes and maintenance; ownership must stay coherent across transfers |
| Renting your own home | Present: landlord types, roommates, utilities, rent negotiation and forced moves | Connect all residents to chores, bills, privacy, caregiving and repairs |
| Vehicles and possessions | Present: stores, cars, boats/planes, jewelry, art/collectibles, item uses and upkeep-related rules | More practical use, condition, provenance, resale and consequences. Audit catalog breadth separately from gameplay usefulness |
| Luxury lifestyle | **Scaffold for the named route:** payment and `luxury_life` flag; no consumer of that flag found in game scripts | A private island already exists as an asset. Add useful island management and elite social chapters if desired. The [community luxury achievements](https://bitlife-life-simulator.fandom.com/wiki/Achievements) document secret societies and island construction; buying expensive items alone is not the equivalent |
| Gambling | Present: blackjack, several interactive casino games, horses, lottery and additional abstract dice/card bets | Review poker interaction and hand rules, risk feedback, odds, sustainable limits and contextual rivalries. Abstract wagering is distinct from an interactive minigame |
| Casino ownership | **Scaffold:** acquisition costs money and sets `owns_casino`; repository-wide script search found no reader of that flag | Finish management or disable the purchase until it is useful. The [BitLife casino documentation](https://bitlife-life-simulator.fandom.com/wiki/Casino) describes ownership with rooms, amenities and entertainment; our gambling menus do not provide that loop |
| Museum and collecting | Partial: buy collectibles, donate finds/heirlooms, receive recognition and a named wing | Own and arrange a museum, manage exhibits, visitors, security and provenance. The [BitLife achievement inventory](https://bitlife-life-simulator.fandom.com/wiki/Achievements) documents filling owned museum exhibits |
| Black market | Present: fencing, forgery, smuggling, goods and consequences | Fuller dealer networks, provenance, collections, auctions and persistence; precise counterpart subfeature coverage remains to be verified |
| Social media | Present: five fictional platforms, content categories, collaborations, sponsors, equipment gates and payouts | Missing dedicated subscription-creator and music-upload platforms. [Community social documentation](https://bitlife-life-simulator.fandom.com/wiki/Social_Media) describes OnlyFans subscriptions/tips; [official release notes](https://apps.apple.com/cg/app/bitlife-life-simulator/id1374403536) add SoundCloud uploads, collaboration and song sales. Use original parody names and non-graphic adult presentation |
| Hobbies and outdoors | Present: reading, gardening, music, outings, martial arts, camping, hiking, fishing, hunting, diving and wildlife records | Sustained projects, clubs, competitions, friendships and personal collections. Our outdoor actions exist even though the separate outdoor lifestyle flag adds little by itself |
| Travel and migration | Present: trip choices/companions, emigration, city moves, regional effects and fourteen countries | More locations plus researched local institutions, language and migration chapters; no exact current BitLife country-count claim made |
| Ordinary crime | Present: theft, burglary, vehicle theft, robbery, dealing and other authored/action routes | A full target/action audit is still needed. [BitLife crime documentation](https://bitlife-life-simulator.fandom.com/wiki/Crime) includes porch theft and embezzlement; its [official help](https://bitlifeapp.com/help/) describes train robbery. Do not equate our named Wanted crime severities with available player actions |
| Murder and serious adult content | Present: mature arcs and violent-crime consequences; confirmed non-graphic life-ending choice | Persistent victims/families, investigations, grief, testimony and consequences; expand adult consensual relationship stories without explicit sexual scenes |
| Justice | Present: lawyers/trials, evidence/heat, case records, appeals, probation/parole-related rules | More readable connected cases and outcomes; verify pleas/sentencing distinctions before claiming full coverage |
| Prison and re-entry | Present: human imprisonment, work, gangs, visits, escape, parole-related systems; separate prisoner and guard modes | More programs, staff ethics, family continuity, housing/work after release and playable supervision; never confuse separate-mode richness with every human-prison feature being equivalent |
| Challenges and collecting goals | Present: daily/weekly challenges, missions, trophies, heirlooms, rewards and graveyard | More scenario combinations, searchable progress and memorable rewards; count definitions separately from reliably reachable goals |
| Minigames | Present: thirty-nine registered interactive games across work, law, gambling, pets and prison | Stronger contextual difficulty, opponent variety, skill feedback and accessibility; the larger count does not establish better combat or casino depth |
| Rewind and sandbox | Present: start-of-year snapshot Do-Over, modifiers and full-stat sandbox | BitLife's official Time Machine allows choosing years to rewind; our one-year snapshot is a narrower mechanic, not equivalent arbitrary history navigation |
| Interface and accessibility | Present: grouped menus, dark themes, search in selected screens, text sizing, reduced motion, keyboard controls and sound settings | Apply search/filtering and clear eligibility explanations consistently; prioritize function with each visual pass |

## Alternate lives and current BitLife changes

Our registered paths include royal, vampire, witch, gifted hero/villain, revenant,
pirate, space colonist and historical traveler, plus separate pets, prisoner,
guard and TVLife modes. These are different game structures, not all equally deep.
TVLife's four selected linear character arcs are not four open-ended campaigns.
Living as a pet should be compared separately with Candywriter's pet spin-offs,
not counted as proof of superiority over the core BitLife app.

Vampires are **not an exclusive advantage**: BitLife released
[Vampire Mode](https://bitlifeapp.com/whats-new/vampire-mode/) in October 2025,
including essence progression, hunters, hypnosis and vampire offspring. Our
vampire path needs its own detailed audit before any parity claim.

Do not add a season pass merely to copy old release notes. BitLife announced the
[removal of Seasons](https://bitlifeapp.com/whats-new/end-of-seasons/) in August
2026. Its historical seasonal rewards are not a currently verified active feature.
Our normal daily/weekly challenges can develop independently.

## What belongs on top of the approved campaign

These are recommendations and amendments for planning, **not delivered changes**.
Keep v0.29's household work, but make it expand the existing time points, routines,
commuting, rent and utilities instead of claiming to invent those systems.

| Priority | Addition or repair | What would make it complete |
| --- | --- | --- |
| Immediate | Finish or disable casino-owner acquisition | Purchase creates an owned business; rooms, staff, costs, revenue, failure/sale and succession work and persist |
| Immediate | Finish or clarify luxury-route acquisition | Show specific unlocked actions and benefits before charging; remove unsupported lifestyle promises |
| Next household update | Shared household dashboard | Resident roster, income/expense breakdown, contributions, dependents, ownership and affordability agree after save/load and child transfer |
| Next household update | Meaningful routines and responsibilities | Optional presets, fatigue/rest, chores/care delegation and events that respect the time budget |
| Next content track | Producer plus music-upload platform | Authored projects, collaborators, licensing, releases and income; not another generic follower button |
| Next content track | Adult subscription-creator platform | Adult eligibility, subscriptions, tips, privacy/boundaries and reputation; non-graphic text and sustainable economics |
| Major management track | Casino, museum and agency | Three distinct loops with real operating decisions, readable yearly results and family continuity |
| Career depth track | Fighter and director expansion | Coaches/moves/opponents; selectable genres, casting several roles and persistent production histories |
| Childhood track | School/campus/vocational chapters | Named peers/mentors, projects, qualifications, scholarships and opportunities that continue into adult life |
| Work/economy track | Profession-specific work and business products | Cases/clients/projects, suppliers, prices and facilities; portfolio work and several concurrent part-time commitments |
| Relationships track | Co-parenting and autonomous relatives | Schedules, independent ambitions and remembered responsibilities; no invented child achievements during transfer |
| World track | Country and community breadth | Distinct opportunities and institutions, local stories and coherent moving/credential rules |
| Later-life track | Retirement, care and estates | Playable retirement goals, care arrangements, executor decisions and intergenerational memories |
| Continuous | Content discoverability and relevance | Search/filter/bookmarks, visible prerequisites, contextual suggestions and annual summaries of actual consequences |
| Continuous | Cross-system balance and reliability | No money-for-flags dead ends, duplicated payouts/assets, free perpetual growth or transferred obligations silently disappearing |

For every substantial addition, require: a discoverable entry, meaningful decisions,
lasting state, understandable outcomes, failure/recovery or exit, relevant people,
save/load continuity, age/mode eligibility, and integration with money/time/family
where appropriate. A menu label or a popup does not satisfy those conditions.

## Where we should aim beyond a checklist

Our strongest opportunity is a life that remains coherent across generations:
people remember promises, children have their own circumstances, ordinary work
feels different from celebrity work, and changing homes or relationships affects
the same household budget. That direction builds on v0.28 without pretending the
current NPC simulation already performs every business, portfolio and personal
story action in the background.

More content should also make modest lives rewarding: friendships, a repaired
relationship, a finished craft project, a stable recovery, raising a child or a
meaningful retirement should have as much authored care as becoming famous.
This is our proposed design direction, not a claim that BitLife lacks all of it.

## Evidence and verification limits

Local evidence: `data/jobs.json`, `majors.json`, `countries.json`, `achievements.json`,
`missions.json`, `challenges.json`; `autoload/actions.gd`, `daily.gd`, `careers.gd`,
`new_careers.gd`, `ambition.gd`, `market.gd`, `workforce.gd`, `empires.gd`, `finance.gd`,
`lending.gd`, `grit.gd`, `tenancy.gd`, `transit.gd`, `body.gd`, `care.gd`,
`expansion.gd`, `social.gd`, `bonds.gd`, `romance.gd`, `law.gd`, `wanted.gd`,
`become.gd`, `items.gd`, `lives.gd`, `dynasty.gd`, `family_chronicle.gd`,
`minigames.gd`; [v0.28 coverage](releases/V0.28-COVERAGE.md) and
[approved expansion campaign](NEXT-UPDATES.md).

The casino/luxury finding was checked across all repository `.gd` scripts: the
ownership/lifestyle flags occur only where they are written. That is strong
evidence of missing gameplay consumers, not a fresh runtime reproduction of every
route. Catalog totals were counted directly. No fresh gameplay tests were needed
for this documentation-only audit; previous release validation is separate.

Still verify before advertising complete parity: every BitLife ordinary occupation,
current country/city totals, all purchases by platform, exact instrument/discipline
catalogs, all individual crime actions, royalty/supernatural subfeatures, investment
instrument mechanics, full actor/model/dealer/mafia actions, every collectible,
and actual balance/quality under human play. No coverage percentage is defensible
from the present evidence.

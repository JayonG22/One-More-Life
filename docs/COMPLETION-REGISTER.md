# Completion register — v1.0 preparation

Current milestone: [v0.92 — People & Relationships](releases/V0.92-COVERAGE.md),
in progress, with v0.90 and v0.91 local review checkpoints and earlier unaccepted work
carried forward. Earlier `.89.0`–`.89.2` artifacts were implementation previews,
not separate roadmap releases. The owner approved substantial local review
packages across v0.90–v0.99; the consolidated application package remains v1.0
after accepted scope and owner-led release gates are complete. The immediate work order is to close partially delivered earlier features first;
see the [prior-update closeout board](FEATURE-CLOSEOUT-BOARD.md). This does not
remove unstarted accepted requirements from the v1.0 scope.

This is the current entry point for the accepted scope. It combines the earlier
individual requests, all 180 campaign requirements, the approved milestone table
and the supplied-guide/comparison follow-ups. Earlier release documents remain
evidence, not competing task lists. The configurable age-jump slider was withdrawn.
On 3 October the owner explicitly replaced the TV-based preview catalog with six
additional original campaigns; earlier owned journals must remain accessible.
The owner also requested retiring the separate Skills & competition and Growing
up destinations because they made navigation too complex. v0.84 moves existing
schoolwork into the school area and keeps practice beside related work, money,
studio and martial-arts activities. v0.85 groups growing relationship lists,
assets and careers behind shorter navigation pages. These are organization
changes, not scope reductions. The owner requested an interim development
package, not v1.0; the accepted base-game completion gate remains.

The v0.88 interim package connects household reserves and contact-aware parenting. See
[v0.88 coverage](releases/V0.88-COVERAGE.md) and
[delivery notes](releases/V0.88-VALIDATION.md). The owner will playtest the
package; no tests or game run-throughs were performed for this update.

**Feature complete is not achieved.** A working foundation, named menu, scene
count or green test does not close a whole requirement. Every campaign row below
is retained as OPEN until its full acceptance is established. This deliberately
does not assert that all 180 have undergone a complete individual code/play audit.
The evidence column identifies relevant partial implementations and focused
checks; it is not a certificate for every phrase of the requirement.

To close a row: finish its missing behavior, verify reachability, choices/costs,
consequences, saving/loading, ownership/transfers and UI as relevant, record the
actual checks and packaged version, then change its status. Discoveries become
new rows here. Version numbers cannot close rows. No accepted missing mechanics
are deferred as maintenance after v1.0.

## Accepted milestone table

| Milestone | Required outcome |
| --- | --- |
| v0.31 — Clearer Everyday Play | Search/favourites, understandable navigation and costs, consistent Back/scroll behaviour, original age progression, costly activity bundles, lifestyle stat maintenance, outcome explanations and organised recaps; connect selected earlier choices to visible follow-ups |
| v0.32 — Work and Independence | Multi-stage career projects, clients, mentors, specialisations, practical promotions, apprenticeships/retraining and connected finance/debt recovery |
| v0.33 — People Remember | Promises/deadlines, favours, continuing friends/rivals, trust/repair, co-parenting and broader remembered-choice consequences |
| v0.34 — Growing Up | Age-appropriate curriculum/practicals, multi-year clubs, teams, talent and leadership/campaign promises, childhood circumstances and adulthood pathways |
| v0.35 — Skill and Competition | Tactical opponents, martial counterplay, profession-specific challenges, feedback/practice, assisted play and balanced repeat attempts |
| v0.36 — Ambition and Enterprise | Personal ambitions, businesses, creative projects, public responsibilities, royal duties/contracts/reputation and worthwhile modest lives |
| v0.37 — Trouble and Recovery | Connected investigations/trials, prison/re-entry, adult drama and boundaries, betrayal, injury recovery and rebuilding; mature-content preferences |
| v0.38 — A Changing World | Neighbourhood/regional opportunity, housing/moving trade-offs, migration, community institutions and projects |
| v0.39 — Generations and Later Life | Retirement/caregiving/mentoring, older friendships, family-business succession, estates, heirlooms and dependable personal continuity |
| v0.40 — Identity and Presentation | Expressions within the established avatar design, cohesive muted visuals/audio controls, and agreed mode/original-story expansions |
| v0.41–0.49 — Coverage and Integration | Audit each request, finish missing paths/content and connect the whole lifespan across different backgrounds; resolve contradictory systems |
| v0.50 — Feature Complete | All accepted requirements implemented and verified, or a specific scope change agreed with the user; no silent omissions |
| v0.51–0.59 — Balance | Varied viable lifestyles, costs/rewards/progression/event frequency, recovery and exploit checks |
| v0.60–0.69 — Reliability and Performance | Long lives/families/generations, backups/recovery/migration, memory cleanup and measured optimisation |
| v0.70–0.79 — Player Testing | Structured representative playthroughs and fixes for confusion, repetition, weak feedback and frustration |
| v0.80–0.89 — Release Beta | Complete installation/upgrades/settings/accessibility/documentation/credits/build verification; fixes and remaining necessary gaps |
| v0.90–0.99 — Release Candidates | Close blockers, verify compatibility and complete lives, and reconcile request coverage with public descriptions |
| v1.0 — Complete Base Game | Deliver the accepted, connected, balanced and verified base-game scope |

All milestone gates remain open at full-scope level. v0.70–v0.72 deliver selected
content, continuity and performance work; it does not complete the player-testing
phase or retroactively pass v0.50. The earlier requests continue alongside this table.

## Earlier individual requests

| ID | Accepted request | Current evidence and remaining acceptance |
| --- | --- | --- |
| H01 | Take over Understand Game Process and preserve all requests | This audit checked the visible request history, this register, and the related project threads available in Codex. The exact “Understand Game Process” thread and its source transcript are unavailable in the current thread list and the project `sources/` folder is empty, so full separate-chat reconciliation remains unverified. |
| H02 | Organize GitHub/docs into clear categories; deliver reviewable builds | README and categorized docs/release records; public GitHub publication and remote-page review remain open. |
| H03 | Calmer main menu, categories, navigation, concise wording | Existing usability foundation; v0.70 pages long lists. v0.89 removes the duplicate School challenges destination from search/favourites and labels the education summary plainly. All old/new menus still need full player review. |
| H04 | Neutral borderless dark themes and charming varied panel shapes | Established UI retained; nine panels checked at normal/enlarged size. Full theme/path audit remains open. |
| H05 | Funny original names for character references and brands | Existing aliases/store variations retained. Renaming alone does not establish rights clearance; public credits/reference audit remains open. |
| H06 | Refine functionality, minigames and reward/point systems | Actual saved workshop rounds and martial styles added; all 39 original games and balance remain open. |
| H07 | Mature murder/crime, sexual and other adult drama | Existing abstract crime and non-graphic adult controls retained. Connected investigations/aftermath and broader adult arcs remain open. |
| H08 | Confirmed suicide ending; switch to actual children at any time | Existing non-graphic confirmed ending and living transfers retained. No ending reward. v0.70 tests inheritance continuity; comprehensive transfer matrix open. |
| H09 | Mute run-throughs; limit bots and simulations | Dummy/muted audio and isolated saves; focused checks, no routine large simulation batch. |
| H10 | Broader than BitLife; no feature cliffhangers or predictable repeated events | Design target, not a parity claim. Novelty quiet exhaustion and selected concluded chains present; all remaining comparison gaps stay below. |
| H11 | Accurate infancy milestones/achievements and varied age-appropriate life events | Existing monthly infancy, seven firsts including one first tooth; v0.90 adds separate age-five and age-thirty scenes with callbacks. v0.91 reconnects the graduation vignette to the actual diploma transition and a named follow-up. Wider age/content pools and milestone counters need full coverage. |
| H12 | More avatar customization in established design; expressions and health | Existing variants/live condition indicators retained; full facial animation and expanded catalogs remain open. |
| H13 | Stats affect education/work/chance/risk/rewards; lifestyle stat change by month/year | Aptitude/readiness and lifestyle foundations retained. Comprehensive action-by-action balance/consumer audit open. |
| H14 | Country/era appropriate royal birth, hierarchy and succession | Existing royal birth/rules retained; title-specific duty and succession disputes open. |
| H15 | Immediate-family relationship sections; deceased/past sections; no extended-family clutter | The UI has separate parents/siblings, partners, pets, children, contacts, and deceased/past sections. v0.89 removes aunts/uncles, cousins and nieces/nephews from standard family actions, sibling babysitting, new sibling-child NPC creation, yearly family recaps, new family invitations and family-wide bond changes. This closeout removes aunt/uncle candidates from family, money, inheritance and lottery event pools, and makes the royal succession rival an ordinary named rival with a courtier role. v0.92 routes commitments separately from the People directory and ties shared moments to both people's stats and remembered priorities. Existing saved records remain readable; raised-by-grandparents remains supported. Full relationship-path and owner acceptance remain open. |
| H16 | More martial fights, styles, belt moves and counterplay | Six earned approaches affect matching workshop stamina; full move/opponent progression open. |
| H17 | Simplified configurable activities and limited/varied triggered events | Saved activity choices and novelty foundations retained; full activity/event pacing review open. |
| H18 | Thrilling tactical sports that use training, skill, luck and strategy | Three-fixture saved school/amateur seasons added; professional team/season/injury/contract depth open. |
| H19 | Murder belongs in Crime; meaningful trials with questions | Crime placement retained; 20 procedural questions with three distinct saved questions per case. Full trial/investigation campaign open. |
| H20 | Exact/fraction/term configurable borrowing | Existing configurable borrowing retained; debt recovery/interest integration review open. |
| H21 | School has a purpose, real quizzes/practicals, cliques/clubs/talent and leadership | Existing school portfolio/council systems plus season evidence; longer named communities and complete activities open. |
| H22 | Each ordinary job has at least two unique functions; remembered choices affect future opportunities | Existing occupation-specific tasks/projects and school evidence retained. Static catalog review found 95 ordinary job definitions, each with at least two job-specific duties; v0.91 shows role duties and fit factors before application. Gameplay and balance acceptance remain open. v0.89 groups career-story and police/clinical paths inside Career & growth, removes duplicate Workplace training, hides exhausted unique-scene choices, gates lunches on available cash, settles union dues with annual finances, and clarifies raise/reference conditions. Complete equipment/client and every historical-choice consequence audit remain open. |
| H23 | All approved scope before v1.0; maintenance follows completion | Binding gate, not achieved. No silent omissions or moving known mechanics after v1.0. |
| H24 | Configurable time-jump slider | WITHDRAWN by user. Monthly infancy then annual progression retained. |
| H25 | Costly bulk activities in appropriate panels, visibly distinct buttons | Existing eight contextual bundles and navigation/bulk styling retained; full button/path consistency review open. |
| H26 | Brand-like varied stores with different stock; breeds; varied houses/vehicles/icons | Existing shopping variations, breeds/catalogs and icons retained. Further provenance/upkeep/catalog coverage open. |
| H27 | Buy houses/vehicles through Shopping; Assets for owned possessions/finance | Existing separation retained; end-to-end shopping/ownership paths still require broad acceptance. |
| H28 | Combined updates and all skipped work, including table contents | v0.70 combined package delivers selected closure; full register remains open rather than treating decimal labels as completed scope. |
| H29 | Use supplied three XLSX guides | Original files read-only; reviewed inventories and comparison tasks included below. Document instructions are reference, not user instructions. |
| H30 | Protect children from automatic adult debt; household-funded childhood and age-appropriate independence | Existing childhood cash protection retained; no forced cash reset discarding earned gifts. Wider countries/backgrounds/independence review open. |
| H31 | Prefer usage window; credits if needed | Account billing preference acknowledged. The game and this repository cannot select the service billing source. |
| H32 | Continue toward v1.0 with surprising new modes, activities and functions | Active work. Fresh Start scenarios and two original campaigns delivered in v0.71; complete accepted scope remains open before v1.0. |
| H33 | Actual game application with simple personalized logo and overall design refinement | Native Windows GUI executable with project icon/metadata, original vector identity and muted themes delivered in v0.71. Installer/storefront/mobile releases and full design acceptance are not claimed. |
| H34 | Brief readable descriptions, options and button wording | v0.73 adds 26 authored screen summaries and inline Details for long explanations on mapped screens. Costs remain visible. Full wording/layout review across every path remains open. |
| H35 | Expressions drawn into avatars; freely available hair, eyes and cosmetics for unique people | v0.78.2 adds expression-linked adult face details plus 12 free hair colours and 8 eye colours; v0.79 adds free face accessories; v0.82 extends matching original portraits to infants, children and supported older people across 42 attributed face vectors. Saved choices follow people and living child transfer. OPEN: complete coverage for special/themed adult looks, all mode combinations and visual acceptance. |
| H36 | Preserve the original avatar design | The rejected redraws are superseded. v0.78.1 restored the actual original glyphs; v0.78.2 extends matching Microsoft Fluent paths for everyday adults without replacing their head, nose, hair or eye shapes. Unmodified steady/neutral faces and unsupported looks retain the original renderer. Further visual acceptance and all-look coverage remain OPEN. |
| H37 | Give minigames original 32-bit-style sprite boards, environments and interactive scene objects; keep any 3DS layout as future work | OPEN — the current minigames are playable, but the requested original per-game visual board/environment art is not complete. Existing icons, panels or a sprite inventory do not close this requirement. |

## All 180 campaign requirements

Each domain lists partial implementation evidence and its remaining closure work.
Each numbered requirement is reproduced unchanged and remains OPEN.

### Continuity — items 1–9

Implementation candidates: `autoload/dynasty.gd, autoload/estate.gd`.

Evidence: completion_test: three handovers, sibling cash, insolvency, charity and company succession.

Remaining domain closure: Full operational business succession, estate disputes, background autonomous lives and all dormant obligations.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C001 | Give important NPCs persistent education, qualifications, employment and salary records. | OPEN — partial evidence above; full acceptance not established |
| C002 | Record personal assets, debts, medical history, criminal history and household membership. | OPEN — partial evidence above; full acceptance not established |
| C003 | Show a family tree with marriages, separations, adoption, stepfamilies and deceased relatives. | OPEN — partial evidence above; full acceptance not established |
| C004 | Preview the child's actual circumstances and unresolved commitments before switching. | OPEN — partial evidence above; full acceptance not established |
| C005 | Let former player characters continue their recorded obligations and ambitions as NPCs. | OPEN — partial evidence above; full acceptance not established |
| C006 | Preserve personal memories and ongoing story threads when changing the active character. | OPEN — partial evidence above; full acceptance not established |
| C007 | Distinguish inheritance, gifts, shared property and a change of viewpoint in the accounts. | OPEN — partial evidence above; full acceptance not established |
| C008 | Add family-business handovers, contested estates and meaningful heirloom histories. | OPEN — partial evidence above; full acceptance not established |
| C009 | Allow descendants to react to family reputations without mechanically inheriting moral guilt. | OPEN — partial evidence above; full acceptance not established |

### People — items 10–18

Implementation candidates: `systems/commitments.gd, autoload/bond_stats.gd`.

Evidence: completion_test: goals, favours and rival repair; journey_test: existing commitments.

Remaining domain closure: Wider motives, NPC-to-NPC networks, long-distance chapters and all childhood callbacks.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C010 | Expand closeness into visible trust, respect, affection, conflict and reliability where useful. | OPEN — partial evidence above; full acceptance not established |
| C011 | Give people goals, preferences, boundaries and practical constraints that influence their choices. | OPEN — partial evidence above; full acceptance not established |
| C012 | Make promises, favors, debts and broken commitments persist in a readable memory list. | OPEN — partial evidence above; full acceptance not established |
| C013 | Add relationship drift, long-distance friendship, reconnection and changing life priorities. | OPEN — partial evidence above; full acceptance not established |
| C014 | Deepen NPC-to-NPC links so friendships, rivalries and romances affect the wider cast. | OPEN — partial evidence above; full acceptance not established |
| C015 | Let people initiate invitations, requests, support, confrontation and reconciliation. | OPEN — partial evidence above; full acceptance not established |
| C016 | Add repair paths that require time and consistent behavior, rather than one perfect gift. | OPEN — partial evidence above; full acceptance not established |
| C017 | Show multiple interpretations of a disagreement without inventing a universal best answer. | OPEN — partial evidence above; full acceptance not established |
| C018 | Summarize each important person's recent life so their agency is visible to the player. | OPEN — partial evidence above; full acceptance not established |

### Routines — items 19–27

Implementation candidates: `autoload/household.gd, autoload/stewardship.gd`.

Evidence: stewardship_test: fatigue and annual guards; journey_test: existing systems.

Remaining domain closure: Seasonal responsibilities, delegation and complete time integration.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C019 | Connect work, study, commuting, caregiving and leisure through a understandable time budget. | OPEN — partial evidence above; full acceptance not established |
| C020 | Add optional seasonal checkpoints inside a year without requiring constant calendar clicks. | OPEN — partial evidence above; full acceptance not established |
| C021 | Let routines carry on automatically, with clear annual costs and benefits. | OPEN — partial evidence above; full acceptance not established |
| C022 | Provide routine presets for student life, shift work, parenting, recovery and retirement. | OPEN — partial evidence above; full acceptance not established |
| C023 | Add sustainable habits, fatigue, rest and competing priorities with gradual effects. | OPEN — partial evidence above; full acceptance not established |
| C024 | Offer delegation, family help and paid services when responsibilities become overwhelming. | OPEN — partial evidence above; full acceptance not established |
| C025 | Add cooking, errands, paperwork, household repairs and lost-item scenes as meaningful choices. | OPEN — partial evidence above; full acceptance not established |
| C026 | Let celebrations and quiet satisfaction coexist with setbacks; avoid a compulsory crisis every year. | OPEN — partial evidence above; full acceptance not established |
| C027 | Explain why an action is unavailable and provide a useful alternative where possible. | OPEN — partial evidence above; full acceptance not established |

### Housing — items 28–36

Implementation candidates: `autoload/tenancy.gd, systems/funds.gd`.

Evidence: completion_test: paid deposits, legacy deposits and reserve ownership.

Remaining domain closure: Lease renewals/notice, full roommate responsibilities and connected neighborhood/renovation histories.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C028 | Deepen leases with deposits, renewals, notice, repairs and readable tenant/owner responsibilities. | OPEN — partial evidence above; full acceptance not established |
| C029 | Expand roommates with shared bills, boundaries, visitors, chores and departure agreements. | OPEN — partial evidence above; full acceptance not established |
| C030 | Make neighborhood ties matter through noise, mutual help, local disputes and trusted contacts. | OPEN — v0.90 adds a named neighbor and later community-noticeboard callback; local disputes and broader neighborhood systems remain |
| C031 | Connect home quality and location to sleep, school access, commuting and recurring costs. | OPEN — partial evidence above; full acceptance not established |
| C032 | Add moving trade-offs: affordability, family proximity, job access and leaving familiar people. | OPEN — partial evidence above; full acceptance not established |
| C033 | Expand repairs and insurance into understandable costs, claims, exclusions and recovery choices. | OPEN — partial evidence above; full acceptance not established |
| C034 | Add home adaptation for children, disability, ageing relatives and working from home. | OPEN — partial evidence above; full acceptance not established |
| C035 | Give renovation projects budgets, delays, contractor relationships and practical effects. | OPEN — partial evidence above; full acceptance not established |
| C036 | Show a single household dashboard for rent/mortgage, utilities, dependents and maintenance. | OPEN — partial evidence above; full acceptance not established |

### Childhood — items 37–45

Implementation candidates: `systems/growing_up.gd, systems/seasons.gd`.

Evidence: journey_test and completion_test: selected school and sports routes.

v0.82 source evidence: 20 distinct situations across all ten clubs, meaningful
challenge/trust choices, recurring actual classmates and downstream connections;
named project teachers, retained pause/close histories, time-costed returns and
recorded collaborator replacements. Focused tests cover saved plans and no repeat
encounters, plus late final presentations and school leadership age eligibility.
All nine cliques have 18 distinct situations and 54 outcomes tied to actual
classmates, trust/popularity and later follow-ups. Ordinary meetups remain after
authored decisions are consumed; yearly and duplicate guards prevent farming.
Remaining domain closure: Broader family circumstances, school community/clique
and talent depth, wider downstream coverage and native/player acceptance.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C037 | Add more specific family circumstances and childhood responsibilities to existing origins. | OPEN — partial evidence above; full acceptance not established |
| C038 | Create enduring childhood friends, sibling dynamics and neighborhood memories. | OPEN — v0.90 school project choices alter a named classmate bond and return through a later callback; wider childhood friendships, sibling dynamics and neighborhood memories remain |
| C039 | Deepen school communities with teachers, mentors, belonging and changing peer groups. | OPEN — v0.90 adds a named teacher to a school project decision and callback; the wider school-community and mentor progression remains |
| C040 | Add extracurricular projects, hobbies, competitions and the decision to quit or persist. | OPEN — partial evidence above; full acceptance not established |
| C041 | Expand bullying, school conflict and support routes with consequences beyond one popup. | OPEN — partial evidence above; full acceptance not established |
| C042 | Make parental expectations, favoritism and family finances influence opportunities. | OPEN — partial evidence above; full acceptance not established |
| C043 | Add age-appropriate identity, confidence, first independence and non-graphic first-romance stories. | OPEN — partial evidence above; full acceptance not established |
| C044 | Let academic, vocational, creative and caring strengths develop through different routes. | OPEN — partial evidence above; full acceptance not established |
| C045 | Add first wages, saving goals, driving preparation and the transition out of the family home. | OPEN — partial evidence above; full acceptance not established |

### Learning — items 46–54

Implementation candidates: `systems/learning.gd, autoload/employment.gd`.

Evidence: completion_test: saved units, pause, assessment and placement; employment_test.

v0.82 source evidence: dedicated coursework across all 28 fields;
community-college associate qualifications distinct from bachelor's degrees;
explicit US/Canada credit recognition; changing majors with retained credit and
cost previews; interruption and later return preserving grades and tuition debt.
Practical-to-college upgrades now credit two units with a distinct advanced
capstone, reduced fees and at least one further year; prior rewards do not repeat.
All 28 fields have two distinct placement tasks with saved outcomes, stipend
records, honest-work/reference requirements and a later actual-supervisor follow-up.
Evidence is awarded once per field even after trimming visible placement history.
Focused education tests verify these branches. Full campus histories, broader
regional/era coverage and final native/package acceptance remain open.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C046 | Expand scholarships, grants, student work and the costs of studying away from home. | OPEN — partial evidence above; full acceptance not established |
| C047 | Give apprenticeships and trade qualifications complete routes with mentors and assessments. | OPEN — partial evidence above; full acceptance not established |
| C048 | Add community-college, part-time, distance and adult-return pathways where the setting supports them. | OPEN — partial evidence above; full acceptance not established |
| C049 | Make courses contribute concrete skills, projects and evidence for applications. | OPEN — partial evidence above; full acceptance not established |
| C050 | Add internships with supervision, learning, exploitation risks and genuine job prospects. | OPEN — partial evidence above; full acceptance not established |
| C051 | Expand academic setbacks, changing majors, interruption and returning without restarting everything. | OPEN — partial evidence above; full acceptance not established |
| C052 | Give exam/project minigames preparation feedback and relevant skill modifiers. | OPEN — partial evidence above; full acceptance not established |
| C053 | Connect credentials and licences to region and era; explain whether they transfer when moving. | OPEN — partial evidence above; full acceptance not established |
| C054 | Add alumni contacts, research projects and professional development after graduation. | OPEN — partial evidence above; full acceptance not established |

### Work — items 55–63

Implementation candidates: `autoload/employment.gd, autoload/depth.gd`.

Evidence: employment_test and guide_projects_test: existing projects; stewardship_test: retainers.

Remaining domain closure: Recurring client/institution histories, equipment, comprehensive career contracts and management routes.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C055 | Add new work routes after reviewing the existing catalog: repair, logistics, service, environment and creative work. | OPEN — partial evidence above; full acceptance not established |
| C056 | Give every reviewed career a recognizable working reality, not only a salary ladder. | OPEN — partial evidence above; full acceptance not established |
| C057 | Add projects with deadlines, responsibilities, collaborators and several ways to finish them. | OPEN — v0.90's workplace onboarding scene gives a coworker a teaching role and offers several approaches with performance/trust outcomes; full project systems and broader acceptance remain |
| C058 | Expand contracts, probation, schedules, leave and the trade-offs of stability versus flexibility. | OPEN — partial evidence above; full acceptance not established |
| C059 | Deepen coworker/boss relationships through mentoring, credit, conflict and remembered assistance. | OPEN — v0.90 records named coworker teaching and a later chance to pass on that help; wider mentor/client histories remain |
| C060 | Make hiring explain qualifications, experience, references, local demand and uncertainty. | OPEN — partial evidence above; full acceptance not established |
| C061 | Add negotiated progression, lateral moves, management routes and independent specialist routes. | OPEN — partial evidence above; full acceptance not established |
| C062 | Expand dismissal, redundancy, return-to-work, retraining and sustainable recovery paths. | OPEN — partial evidence above; full acceptance not established |
| C063 | Connect burnout and family obligations to choices without making constant overtime the dominant strategy. | OPEN — partial evidence above; full acceptance not established |

### Enterprise — items 64–72

Implementation candidates: `systems/enterprise.gd, autoload/ambition.gd`.

Evidence: combined_depth_test and completion_test: selected enterprise/succession paths.

Remaining domain closure: Suppliers, staffed operations, all special-career contracts, political and royal responsibility chains.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C064 | Deepen small businesses with actual products/services, local demand and repeat customers. | OPEN — v0.72 named orders/customer loyalty; v0.74 two product stocks, actual sales limits and saved research insights. Full local-demand/customer-history acceptance remains open. |
| C065 | Add staffing, suppliers, pricing, quality and cash-flow trade-offs with readable summaries. | OPEN — v0.74 adds contractual lead times/risk/bills, actual stock costs/waste, facilities, pricing and profit/cash separation. Personnel disputes and full balance acceptance remain open. |
| C066 | Expand partnerships through ownership shares, decision rights, conflicts and buyouts. | OPEN — partial evidence above; full acceptance not established |
| C067 | Add practical freelance contracts, portfolios, late payment and reputation for reliability. | OPEN — partial evidence above; full acceptance not established |
| C068 | Give creators a body of work, collaborators, critical reception and audiences with changing tastes. | OPEN — partial evidence above; full acceptance not established |
| C069 | Deepen sport/acting/music careers with practice, selection, injuries, contracts and later-life transitions. | OPEN — partial evidence above; full acceptance not established |
| C070 | Connect public careers and politics to local issues, constituents, coalitions and remembered promises. | OPEN — partial evidence above; full acceptance not established |
| C071 | Expand business failure, restructuring, sale and succession without making failure erase every skill. | OPEN — v0.72 actual succession; v0.74 sale transfers stock/obligations to a living buyer, closure salvages stock and charges cancellations. Restructuring, creditor procedure and broader world estates remain open. |
| C072 | Differentiate ordinary successful careers from celebrity careers so fame is not everyone's destination. | OPEN — partial evidence above; full acceptance not established |

### Money — items 73–81

Implementation candidates: `systems/funds.gd, autoload/estate.gd, autoload/stewardship.gd`.

Evidence: completion_test and stewardship_test: ownership/conservation.

Remaining domain closure: Unified whole-life ledger, automatic joint budgeting, broader instruments and lifestyle balance.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C073 | Present income, recurring expenses, household transfers, debt and net worth in one clear ledger. | OPEN — v0.89 groups named income (including net rental returns), annual expenses, signed personal/shared-reserve transfers, current debt balances, cash, savings and net worth in the household budget view; whole-life history and broader transfer coverage remain open |
| C074 | Explain wage growth, inflation and purchasing power within the fictional economy. | OPEN — partial evidence above; full acceptance not established |
| C075 | Expand emergency funds, savings goals and shared household accounts with ownership rules. | OPEN — v0.89 unifies the personal surplus rate and cash floor, migrates the old job buffer once, and settles standing shared-reserve contributions after finances; broader goals and owner acceptance remain open |
| C076 | Deepen debt through interest, payment schedules, hardship arrangements and restructuring. | OPEN — v0.78 adds lender-specific dated hardship and longer-term restructuring, exact repayment/ledger amounts, annual guards, bounded history, save/child/offscreen continuity and focused UI checks. Broader education/mortgage hardship, estate/default resolution and lifespan financial balance remain open. |
| C077 | Add recoverable financial setbacks: surprise bills, unpaid wages, scams and interrupted work. | OPEN — partial evidence above; full acceptance not established |
| C078 | Give assets readable carrying costs, liquidity and risks rather than free endless appreciation. | OPEN — partial evidence above; full acceptance not established |
| C079 | Improve investment charts and disclosures of game rules, fees and uncertainty. | OPEN — partial evidence above; full acceptance not established |
| C080 | Add pensions, retirement saving and household effects of late-life income changes. | OPEN — partial evidence above; full acceptance not established |
| C081 | Audit unlimited-money loops, duplicated assets and inheritance exploits across generations. | OPEN — partial evidence above; full acceptance not established |

### Health — items 82–90

Implementation candidates: `autoload/body.gd, autoload/care.gd`.

Evidence: Existing foundation; no comprehensive health revalidation in this update.

Remaining domain closure: Longer treatment, relapse, disability/accommodation and caregiving histories.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C082 | Expand existing chronic conditions into diagnosis, treatment, adaptation, uncertainty and recovery stories. | OPEN — v0.75 adds review/routine/prescription control, lapsed-care effects, acute recovery links and 36 condition-specific practical scenes. Broad clinical story/recovery acceptance remains open. |
| C083 | Make medical appointments and referrals remember what has already happened. | OPEN — v0.75 unifies older clinician routes with the actual medical record, saved rolls, period guards, referral target/wait retention, real specialist bills and correction history. Full clinical/path acceptance remains open. |
| C084 | Deepen caregiving through time, money, family cooperation and support services. | OPEN — v0.75 adds self/shared/professional schedules with costs, time, remembered helpers, renewal, lapses and unavailable-helper consequences. Full caregiving/world acceptance remains open. |
| C085 | Add disability accommodations at home, school and work; maintain meaningful ways to participate. | OPEN — v0.75 adds context-bound home fatigue and school/work readiness support, with renewal after a new job/course/dwelling. Broader physical/sensory/accessibility acceptance remains open. |
| C086 | Expand stress, grief, loneliness and burnout with several coping/support routes. | OPEN — v0.77 connects dated actual losses, real contacts, manageable routines, clinical support, sixteen personal scenes, annual follow-ups and readiness/strain. Wider branch, provider, mode and lifespan acceptance remains open. |
| C087 | Add dependence, relapse and recovery arcs without treating one click as a permanent cure. | OPEN — v0.76 connects all six existing habits to gradual support, two stable years, retained setbacks, real contacts, programme changes/aftercare, 24 pressure scenes and saved off-screen plans. Whole-life/provider/world acceptance remains open. |
| C088 | Make lifestyle changes gradual, age-sensitive and compatible with different ability levels. | OPEN — partial evidence above; full acceptance not established |
| C089 | Separate a health condition from a person's moral worth, talents and relationship value. | OPEN — partial evidence above; full acceptance not established |
| C090 | Add a readable medical/life record and control over how often sensitive scenes interrupt play. | OPEN — v0.75 adds paginated care history, three optional scene-frequency settings, aged/work-eligible scenes and 108 distinct conclusions. Full sensitive-scene/settings acceptance remains open. |

### Romance — items 91–99

Implementation candidates: `autoload/romance.gd, systems/identity.gd`.

Evidence: journey_test: selected existing connected paths.

Remaining domain closure: Compatibility, intimacy/agreement and divorce/co-parenting aftermath across all requested branches.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C091 | Develop compatibility around values, life plans, attraction, habits and boundaries. | OPEN — partial evidence above; full acceptance not established |
| C092 | Add relationship discussions and conflicts about money, work, moving and having children. | OPEN — partial evidence above; full acceptance not established |
| C093 | Expand adult consensual intimacy as non-graphic stories with communication and emotional consequences. | OPEN — partial evidence above; full acceptance not established |
| C094 | Add adult sex-work-related career/life narratives centered on boundaries, finances and stigma, without explicit sexual scenes. | OPEN — partial evidence above; full acceptance not established |
| C095 | Deepen consensual nonmonogamy, changing agreements, jealousy and honest renegotiation. | OPEN — partial evidence above; full acceptance not established |
| C096 | Make affairs affect specific relationships, trust, finances and later reconciliation or separation. | OPEN — partial evidence above; full acceptance not established |
| C097 | Add breakups, divorce and rebuilding with different motives and recoverable futures. | OPEN — partial evidence above; full acceptance not established |
| C098 | Connect marriage/partnership choices to shared households, obligations and care in later life. | OPEN — partial evidence above; full acceptance not established |
| C099 | Expand content preferences by theme; previously started consequences remain coherent after a preference change. | OPEN — partial evidence above; full acceptance not established |

### Parenting — items 100–108

Implementation candidates: `autoload/dynasty.gd, autoload/family_chronicle.gd`.

Evidence: completion_test: recorded children/ownership; journey_test: selected family routes.

Remaining domain closure: Independent child development, childcare, blended families and sustained custody routines.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C100 | Expand pregnancy, fertility, adoption and different routes to a family with distinct circumstances. | OPEN — partial evidence above; full acceptance not established |
| C101 | Add parental leave, childcare arrangements, competing work commitments and help from relatives. | OPEN — partial evidence above; full acceptance not established |
| C102 | Let children's interests, friendships and school needs develop independently of the player. | OPEN — partial evidence above; full acceptance not established |
| C103 | Add co-parenting agreements, custody transitions and maintaining bonds across households. | OPEN — partial evidence above; full acceptance not established |
| C104 | Deepen blended families, step-sibling relationships and the time required to build trust. | OPEN — partial evidence above; full acceptance not established |
| C105 | Let parenting choices influence experiences without guaranteeing a child's personality or future. | OPEN — partial evidence above; full acceptance not established |
| C106 | Add adult children moving out, returning home, supporting parents and negotiating independence. | OPEN — partial evidence above; full acceptance not established |
| C107 | Expand estrangement, reconciliation, family secrets and chosen-family relationships. | OPEN — partial evidence above; full acceptance not established |
| C108 | Link family caregiving, expectations and shared resources across several generations. | OPEN — v0.75 preserves medical and prescription packets across living/inherited transfers, continues recorded off-screen conditions and household-funded child prescriptions. Full generation/family-resource acceptance remains open. |

### Justice — items 109–117

Implementation candidates: `systems/recovery.gd, autoload/wanted.gd`.

Evidence: completion_test: distinct saved hearing questions; journey_test: existing routes.

Remaining domain closure: Longer investigations, witnesses, appeals, victim-family consequences and full re-entry chapters.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C109 | Deepen abstract fictional crimes through motives, pressure, accomplice relationships and escalating consequences. | OPEN — partial evidence above; full acceptance not established |
| C110 | Add investigation histories, testimony, legal representation and uncertainty without instructional crime methods. | OPEN — partial evidence above; full acceptance not established |
| C111 | Make murder/violent-crime stories consequential for specific people, families and later opportunities. | OPEN — partial evidence above; full acceptance not established |
| C112 | Expand blackmail, corruption, betrayal and intimidation as connected adult narrative arcs. | OPEN — partial evidence above; full acceptance not established |
| C113 | Add choices to withdraw, refuse, report, accept accountability or seek a lawful route out. | OPEN — partial evidence above; full acceptance not established |
| C114 | Deepen trials, pleas, appeals and sentencing as transparent fictional systems appropriate to the setting. | OPEN — partial evidence above; full acceptance not established |
| C115 | Connect criminal history to employment, housing, relationships and routes to rebuild. | OPEN — partial evidence above; full acceptance not established |
| C116 | Expand prison friendships, programs, staff ethics, visits, parole preparation and release planning. | OPEN — partial evidence above; full acceptance not established |
| C117 | Treat re-entry as a playable chapter: housing, work, trust, supervision and setbacks. | OPEN — partial evidence above; full acceptance not established |

### Places — items 118–126

Implementation candidates: `systems/community.gd, autoload/lore.gd`.

Evidence: journey_test and combined_depth_test: selected existing community paths.

Remaining domain closure: Migration/language histories, local institutions, researched cultural variety and household-specific shocks.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C118 | Give regions distinct job demand, costs, transit, institutions and plausible local story pools. | OPEN — partial evidence above; full acceptance not established |
| C119 | Expand immigration and moving abroad through preparation, paperwork and adapting to new circumstances. | OPEN — partial evidence above; full acceptance not established |
| C120 | Add language learning, homesickness, long-distance ties and new communities. | OPEN — partial evidence above; full acceptance not established |
| C121 | Develop local institutions: schools, hospitals, employers, clubs and community projects. | OPEN — partial evidence above; full acceptance not established |
| C122 | Let existing local lore visibly affect jobs, rent, health access and social opportunities. | OPEN — partial evidence above; full acceptance not established |
| C123 | Connect economic shocks and recoveries to specific households instead of generic global modifiers alone. | OPEN — partial evidence above; full acceptance not established |
| C124 | Expand travel through companions, budgets, interruptions, memories and changed relationships. | OPEN — partial evidence above; full acceptance not established |
| C125 | Improve era restrictions on technology, occupations, healthcare and social circumstances. | OPEN — partial evidence above; full acceptance not established |
| C126 | Build cultural variety through researched authored settings, avoiding one stereotype per country. | OPEN — partial evidence above; full acceptance not established |

### Leisure — items 127–135

Implementation candidates: `systems/leisure.gd, systems/seasons.gd`.

Evidence: completion_test: project ending/skill and casual reward guard.

Remaining domain closure: More projects, exhibitions, volunteer responsibilities and recurring family traditions.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C127 | Give hobbies progression, projects, friends and a choice to remain casually involved. | OPEN — partial evidence above; full acceptance not established |
| C128 | Expand cooking, gardening, photography, crafts, reading and collecting as sustained activities. | OPEN — partial evidence above; full acceptance not established |
| C129 | Add amateur sports leagues and clubs where belonging matters as much as winning. | OPEN — partial evidence above; full acceptance not established |
| C130 | Deepen volunteering through responsibilities, community trust and changing local needs. | OPEN — partial evidence above; full acceptance not established |
| C131 | Add hobby milestones, exhibitions, performances and small personal achievements. | OPEN — partial evidence above; full acceptance not established |
| C132 | Connect clubs and communities to friendships, mentoring and future work opportunities. | OPEN — partial evidence above; full acceptance not established |
| C133 | Give holidays, celebrations and traditions memories that recur across the family. | OPEN — partial evidence above; full acceptance not established |
| C134 | Add low-cost enjoyment and meaningful ordinary lives alongside luxury purchases. | OPEN — partial evidence above; full acceptance not established |
| C135 | Allow leisure to remain restorative rather than another mandatory optimization system. | OPEN — partial evidence above; full acceptance not established |

### Later life — items 136–144

Implementation candidates: `systems/heritage.gd, autoload/estate.gd`.

Evidence: completion_test: three handovers; journey_test: selected legacy paths.

v0.82 source evidence: three-stage claims/accounts/report executor duties,
delegation and annual inactive administration; actual former-player estates after
living child transfers, named-heir identity, owner-specific finances, negative
equity and single ownership. Focused tests cover saved prompts and no double payout.
Known relatives now retain their own dated bereavements, background recovery and
bounded histories across saves and viewpoint changes, including recorded stress.
Remaining domain closure: wider estate/family/grief acceptance, living arrangements
and purpose/mentorship histories, plus native/package verification.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C136 | Expand retirement into phased work, purpose, hobbies, relationships and changing budgets. | OPEN — partial evidence above; full acceptance not established |
| C137 | Let later-life romance, friendship and ambition remain available in appropriate circumstances. | OPEN — partial evidence above; full acceptance not established |
| C138 | Deepen accessibility at home, caregiving choices and living arrangements in later life. | OPEN — v0.75 links later-life care to remembered helpers, ongoing schedules and practical home support. Full living-arrangement/accessibility acceptance remains open. |
| C139 | Add elder mentorship, memoirs, reconnection and knowledge passed to descendants. | OPEN — partial evidence above; full acceptance not established |
| C140 | Make bereavement affect different people over time, with support and changing memories. | OPEN — partial evidence above; full acceptance not established |
| C141 | Add estate preparation, executor responsibilities and family conversations before inheritance. | OPEN — partial evidence above; full acceptance not established |
| C142 | Keep the existing suicide ending non-graphic, confirmed and without a special success reward. | OPEN — partial evidence above; full acceptance not established |
| C143 | Distinguish tragic endings, quiet endings and fulfilled lives without equating wealth with worth. | OPEN — partial evidence above; full acceptance not established |
| C144 | Produce a richer life summary connecting important decisions, people and unfinished threads. | OPEN — partial evidence above; full acceptance not established |

### Modes — items 145–153

Implementation candidates: `systems/identity.gd, data/mode_chapters.json, systems/fresh_start.gd, data/original_stories.json`.

Evidence: completion_test: 11 chapter banks/schema; journey_test: selected existing mode paths; v0.71 application_test: three adult scenarios and every route through two new original campaigns (six original campaigns now present).

Remaining domain closure: Full species/power/setting loops, story resolutions and special-path family integration.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C145 | Expand Pet Life with training, routines, household changes, veterinary care and species-specific experiences. | OPEN — partial evidence above; full acceptance not established |
| C146 | Make prisoner and guard modes react to relationships, institutions and ethical choices over time. | OPEN — partial evidence above; full acceptance not established |
| C147 | Give royalty lasting public obligations, family expectations and succession conflicts. | OPEN — partial evidence above; full acceptance not established |
| C148 | Deepen vampire, witch, superhero and revenant paths with distinct commitments and consequences. | OPEN — partial evidence above; full acceptance not established |
| C149 | Expand pirate, space and time-traveler stories while enforcing each setting's rules. | OPEN — partial evidence above; full acceptance not established |
| C150 | Create 4–6 original genre campaigns with a recurring cast and meaningful alternate resolutions. | OPEN — partial evidence above; full acceptance not established |
| C151 | Support original characters/settings with their own names and identities, keeping existing aliases clearly marked as references. | OPEN — partial evidence above; full acceptance not established |
| C152 | Add chapter checkpoints, progress summaries, remembered decisions and replayable story branches. | OPEN — partial evidence above; full acceptance not established |
| C153 | Connect special-path relationships and legacy to the family system where that makes sense. | OPEN — partial evidence above; full acceptance not established |

Approved change for C151: the active TV-derived preview catalog is replaced by
original characters and settings, rather than retaining referenced aliases.
Four actual old previews were found (the question incorrectly counted six);
six new originals replace them alongside the existing six. Older owned journals
are archived explicitly. Source graph/migration and rendered library checks are
evidence; this is not a packaged-release acceptance claim.

### Minigames — items 154–162

Implementation candidates: `systems/competition.gd, scenes/minigames/mg_workshop.gd`.

Evidence: completion_test: actual scored-round reload and duplicate guard.

Remaining domain closure: All 39 original games input/accessibility review, bespoke contexts and casino accounting audit.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C154 | Review each of the 39 existing minigames for inputs, instructions, pacing and result explanations. | OPEN — partial evidence above; full acceptance not established. The requested original 32-bit-style boards, environments and interactive objects for the minigames also remain unfinished. |
| C155 | Add optional practice rounds that never risk a career decision or money. | OPEN — partial evidence above; full acceptance not established |
| C156 | Introduce 8–12 contextual games: interviews, practical repairs, budgeting, music practice, cooking, negotiation and care tasks. | OPEN — partial evidence above; full acceptance not established |
| C157 | Connect performance to relevant practice and skill without making learned strategy irrelevant. | OPEN — partial evidence above; full acceptance not established |
| C158 | Offer assisted/automatic resolution for players who prefer the life simulation. | OPEN — partial evidence above; full acceptance not established |
| C159 | Ensure keyboard access, large text, pause, reduced motion and fair timing across games. | OPEN — partial evidence above; full acceptance not established |
| C160 | Audit casino stakes, fees, ties, cash-out, quit behavior and exact payout accounting. | OPEN — partial evidence above; full acceptance not established |
| C161 | Preserve varied dark panels; size event, action and overview panels for their contents. | OPEN — partial evidence above; full acceptance not established |
| C162 | Add menu search, useful favorites and recent actions without crowding the main menu. | OPEN — partial evidence above; full acceptance not established |

### Presentation — items 163–171

Implementation candidates: `scenes/menu_panels.gd, scenes/ui_kit.gd`.

Evidence: completion_ui_test: 39 assertions, nine panels at two text sizes and long-list paging.

Remaining domain closure: All paths wrapping/navigation, avatar animation, contextual help, filters and original sound variation.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C163 | Add a concise annual summary showing money, relationships, health, work and important changes. | OPEN — partial evidence above; full acceptance not established |
| C164 | Explain major consequences through readable history links: what happened and why it matters now. | OPEN — v0.89 records measured changes and follow-ups, and recent event/action entries now link to involved NPC profiles. Links from every opportunity, obligation and downstream outcome remain incomplete. |
| C165 | Give logs filters for people, places, career, household and unresolved story threads. | OPEN — partial evidence above; full acceptance not established |
| C166 | Build a coherent original avatar/icon family, age changes, clothing and meaningful mode emblems. | OPEN — partial evidence above; full acceptance not established. Asset inventories and design briefs are not the finished integrated artwork; individual life, career, item, mode and minigame visuals still need coverage within the original design. |
| C167 | Expand quiet procedural music variation and context sounds with independent controls. | OPEN — partial evidence above; full acceptance not established |
| C168 | Offer optional explanations of chance ranges and preparation where decisions involve risk. | OPEN — partial evidence above; full acceptance not established |
| C169 | Give locked actions practical explanations and links to their prerequisites. | OPEN — partial evidence above; full acceptance not established |
| C170 | Provide context-aware onboarding and optional help, preserving easy routes for experienced players. | OPEN — partial evidence above; full acceptance not established |
| C171 | Keep serious scenes readable and emotionally appropriate while allowing wit in everyday absurdities. | OPEN — partial evidence above; full acceptance not established |

### Quality — items 172–180

Implementation candidates: `autoload/save_manager.gd, tools/completion_test.gd`.

Evidence: Focused suites and exported-pack checks; see V0.70-VALIDATION.md.

Remaining domain closure: Representative whole lives, broad migration matrix, human testing and release acceptance.

| Item | Accepted requirement | Status |
| --- | --- | --- |
| C172 | Run varied life profiles: working-class, affluent, student, parent, disabled, migrant, criminal and elder lives. | OPEN — partial evidence above; full acceptance not established |
| C173 | Measure event repetition, unreachable content, event pacing and the frequency of recovery opportunities. | OPEN — v0.90 adds six one-time story starts across early childhood, school, age thirty and adulthood, grouped by story-family keys for cross-save cooldown; no repetition measurement was run, and broader pacing/accessibility coverage remains |
| C174 | Audit stat gains, friendship/gift loops, routine stacking, minigame rewards and money exploits. | OPEN — partial evidence above; full acceptance not established |
| C175 | Make difficulty affect pressure and uncertainty while retaining explanations and recovery paths. | OPEN — partial evidence above; full acceptance not established |
| C176 | Test three-plus generations for lost history, duplicated relatives, money duplication and incorrect inheritance. | OPEN — partial evidence above; full acceptance not established |
| C177 | Migrate old saves with clear fallbacks and backups instead of silently inventing missing history. | OPEN — partial evidence above; full acceptance not established |
| C178 | Verify each added branch, delayed consequence, content toggle and relevant era/age restriction. | OPEN — partial evidence above; full acceptance not established |
| C179 | Test packaged builds and long runs, including performance with larger casts and accumulated histories. | OPEN — partial evidence above; full acceptance not established |
| C180 | Keep GitHub documentation, changelogs, credits, limits and downloadable versions in agreement. | OPEN — partial evidence above; full acceptance not established |

## Comparison and supplied-guide follow-ups

These tasks retain the historical comparison findings. Some foundations were
expanded since those audits, so each must be rechecked against current code, not
assumed absent. Detailed source inventories remain in SUPPLIED-GUIDES-REVIEW.md.
External feature descriptions are comparison references, not copied game rules.

| ID | Reference workstream | Remaining acceptance/revalidation task |
| --- | --- | --- |
| G001 | Actor (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Agents, contracts and linked production histories |
| G002 | Astronaut (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Longer academy progression and discovery records |
| G003 | Business (SUPPLIED-GUIDES-REVIEW.md) | OPEN — More supply-chain, staffing and ownership decisions |
| G004 | Dealer (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Deeper persistent network motives and investigations; the earlier review understated this foundation |
| G005 | Mafia (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Persistent crew loyalties and investigations |
| G006 | Model (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Agency contracts, clients and sustained designer relationships |
| G007 | Musician (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Label/band contracts and recurring collaborators |
| G008 | Politician (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Linked promises, policy and election opposition |
| G009 | Street Hustler (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Persistent locations and competing street relationships |
| G010 | Pro Athlete (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Deeper season/team histories, contracts and injuries |
| G011 | Doctor / Brain Surgeon (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Specialties, clinical institution histories and malpractice case arcs |
| G012 | Lawyer / Judge (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Dedicated judicial appointments and longer case campaigns |
| G013 | CEO / Executive (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Corporate governance and multi-year strategy effects |
| G014 | Pharmacist (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Recurring pharmacy operations and regulatory case histories |
| G015 | Veterinarian (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Animal/patient identities and persistent practice operations |
| G016 | Army (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Explicit officer/enlisted split and sustained deployments |
| G017 | Navy (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Explicit officer/enlisted split and fleet histories |
| G018 | Air Force (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Explicit officer/enlisted split and mission histories |
| G019 | Marines (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Explicit officer/enlisted split and sustained deployments |
| G020 | Coast Guard (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Explicit officer/enlisted split and longer rescue histories |
| G021 | Exorcist (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Persistent property-linked investigation identities |
| G022 | Adult performer (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Longer agency contracts and continuing production records |
| G023 | Mortician (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Persistent family/client case campaigns |
| G024 | Auto Mechanic (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Link repairs to actual vehicle condition and recurring clients |
| G025 | Chef / Baker (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Separate baker occupation and persistent kitchen/menu operations |
| G026 | Ribbons and achievements (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Audit actual counters, original end-of-life categories and fair priority rules; do not adopt conflicting guide counts |
| G027 | Fame and media (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Sustained reputation, contracts, public responses and decay balance |
| G028 | Assets and shopping (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Condition, mileage, provenance, practical uses and connected upkeep |
| G029 | Crime and prison (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Evidence, witnesses, repeated investigations and gang motives |
| G030 | Relationships and royalty (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Household finances, title-specific duties and succession disputes |
| G031 | Black market (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Auction competition, authentication and persistent provenance |
| G032 | Zoo and museum (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Animal records/breeding and an owned museum management loop |
| G033 | Markets (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Instrument-specific disclosure, portfolio risk and return balance |
| G034 | Generational legacy (SUPPLIED-GUIDES-REVIEW.md) | OPEN — More configurable estates, family conflicts and estate audits |
| G035 | Education pipeline (SUPPLIED-GUIDES-REVIEW.md) | OPEN — Subject prerequisites, deeper assessments and country-specific fees |
| G036 | Birth and character setup (BITLIFE-COMPARISON.md) | OPEN — More origins with practical effects throughout childhood; distinguish biography from lasting rules |
| G037 | Character editing (BITLIFE-COMPARISON.md) | OPEN — Compare editor breadth and achievement rules; expand beyond stat editing if needed |
| G038 | Childhood (BITLIFE-COMPARISON.md) | OPEN — More persistent childhood friends, responsibilities, home circumstances and memorable milestones |
| G039 | School social life (BITLIFE-COMPARISON.md) | OPEN — Make membership involve named people, projects and recurring conflicts rather than mostly bonuses |
| G040 | Further education (BITLIFE-COMPARISON.md) | OPEN — Broader subjects; distinct campus life; apprenticeships, course interruptions and adult returns |
| G041 | First independence (BITLIFE-COMPARISON.md) | OPEN — Connect leaving home to deposits, furniture, family help and a sustainable weekly life |
| G042 | Friends and wider cast (BITLIFE-COMPARISON.md) | OPEN — More NPC initiatives, motives and repair paths; avoid repeated interaction spam |
| G043 | Dating (BITLIFE-COMPARISON.md) | OPEN — Compatibility and values should drive outcomes; richer rejection, uncertainty and long-distance chapters |
| G044 | Marriage (BITLIFE-COMPARISON.md) | OPEN — Shared households, joint commitments, anniversary memories and life-plan discussions |
| G045 | Separation (BITLIFE-COMPARISON.md) | OPEN — Sustained co-parenting schedules, mediation, recovery and blended-household continuity |
| G046 | Parenthood (BITLIFE-COMPARISON.md) | OPEN — More pregnancy/parenting chapters, childcare trade-offs and independently developing children |
| G047 | Health and appearance (BITLIFE-COMPARISON.md) | OPEN — Unify overlapping healthcare menus; longer treatment, accommodation and recovery histories |
| G048 | Dependence and recovery (BITLIFE-COMPARISON.md) | OPEN — More relapse/support stories and gradual recovery; verify exact BitLife condition coverage separately |
| G049 | Retirement (BITLIFE-COMPARISON.md) | OPEN — A substantial playable chapter: phased work, friendships, care arrangements, mentoring and purpose |
| G050 | Death and generations (BITLIFE-COMPARISON.md) | OPEN — Estate administration, ownership clarity, disputes and remembered family decisions |
| G051 | Living-child transfer (BITLIFE-COMPARISON.md) | OPEN — Expand background obligations and ambitions; former players currently have simplified yearly budgets, not full autonomous play |
| G052 | Ordinary professions (BITLIFE-COMPARISON.md) | OPEN — Broaden occupations after a title-by-title catalog comparison. Give professions distinctive tasks, cases, clients, contracts and failure/recovery routes |
| G053 | Part-time and freelance (BITLIFE-COMPARISON.md) | OPEN — Multiple simultaneous contracts, hourly schedules, repeat clients, invoices and competing commitments. BitLife documents multiple part-time jobs and advertised freelance gigs |
| G054 | Military (BITLIFE-COMPARISON.md) | OPEN — Audit branch/enlisted/officer breadth; more postings, colleagues, transitions and veteran life. BitLife's community occupation page lists five branches |
| G055 | Music producer (BITLIFE-COMPARISON.md) | OPEN — Beat/project production, artist collaboration, licensing and a lasting catalog. Official developer notes announce the producer pack in the [App Store history](https://apps.apple.com/cg/app/bitlife-life-simulator/id1374403536) |
| G056 | Pro athlete (BITLIFE-COMPARISON.md) | OPEN — Sport-specific seasons, selection, meaningful rivalries, injuries, retirement and second careers |
| G057 | Street hustler (BITLIFE-COMPARISON.md) | OPEN — Distinct gigs, locations, recurring contacts and consequences; verify detailed counterpart breadth |
| G058 | Fighter (BITLIFE-COMPARISON.md) | OPEN — A learnable move catalog, coaches, persistent opponents and distinct tactics. BitLife officially advertises **200+ moves**, coaches and interactive MMA in [Ultimate Fighter Mode](https://bitlifeapp.com/whats-new/ultimate-fighter-mode/); our current game does not match that breadth |
| G059 | Movie director (BITLIFE-COMPARISON.md) | OPEN — Our seven genres are randomly assigned. Add genre choice, auditions for several roles and continuing cast/crew drama. BitLife's [September 2026 pack](https://bitlifeapp.com/whats-new/movie-director-expansion-pack-is-out-now/) documents eleven selectable genres, auditions, set drama, awards and festivals |
| G060 | Business owner (BITLIFE-COMPARISON.md) | OPEN — Product/service lines, suppliers, pricing, inventory and facilities need fuller loops. BitLife's official help explicitly describes supplier selection, launching/removing products, market research and facilities |
| G061 | Secret agent (BITLIFE-COMPARISON.md) | OPEN — An owned agency with hired/trained operatives, assignments and equipment is missing as a dedicated business. The [community achievement inventory](https://bitlife-life-simulator.fandom.com/wiki/Achievements) documents agency prestige, operatives and gadgets |
| G062 | Cult (BITLIFE-COMPARISON.md) | OPEN — Deeper member/leadership relationships, compound choices and succession. [BitLife's cult guide](https://bitlife-life-simulator.fandom.com/wiki/Cult) describes commune purchases and chosen doctrine/philosophy |
| G063 | Zoo (BITLIFE-COMPARISON.md) | OPEN — Individual animal histories, richer habitats, breeding and exchanges. The [BitLife zoo inventory](https://bitlife-life-simulator.fandom.com/wiki/Zoo) describes eight habitats and a much wider species catalog |
| G064 | Household money (BITLIFE-COMPARISON.md) | OPEN — One household ledger, shared ownership/accounts and consistent affordability feedback |
| G065 | Credit and debt (BITLIFE-COMPARISON.md) | OPEN — Hardship arrangements, restructuring, disputed debts and recovery. Do not mistake these for missing systems |
| G066 | Investing (BITLIFE-COMPARISON.md) | OPEN — Individual fixed-term bonds, differentiated funds/advice and fuller reporting require review. Our two funds currently use the general price-market mechanism; fund labels alone do not establish equivalent financial behavior |
| G067 | Owning and renting property (BITLIFE-COMPARISON.md) | OPEN — Richer tenant screening, leases, amenities, disputes and maintenance; ownership must stay coherent across transfers |
| G068 | Renting your own home (BITLIFE-COMPARISON.md) | OPEN — Connect all residents to chores, bills, privacy, caregiving and repairs |
| G069 | Vehicles and possessions (BITLIFE-COMPARISON.md) | OPEN — More practical use, condition, provenance, resale and consequences. Audit catalog breadth separately from gameplay usefulness |
| G070 | Luxury lifestyle (BITLIFE-COMPARISON.md) | OPEN — A private island already exists as an asset. Add useful island management and elite social chapters if desired. The [community luxury achievements](https://bitlife-life-simulator.fandom.com/wiki/Achievements) document secret societies and island construction; buying expensive items alone is not the equivalent |
| G071 | Gambling (BITLIFE-COMPARISON.md) | OPEN — Review poker interaction and hand rules, risk feedback, odds, sustainable limits and contextual rivalries. Abstract wagering is distinct from an interactive minigame |
| G072 | Casino ownership (BITLIFE-COMPARISON.md) | OPEN — Finish management or disable the purchase until it is useful. The [BitLife casino documentation](https://bitlife-life-simulator.fandom.com/wiki/Casino) describes ownership with rooms, amenities and entertainment; our gambling menus do not provide that loop |
| G073 | Museum and collecting (BITLIFE-COMPARISON.md) | OPEN — Own and arrange a museum, manage exhibits, visitors, security and provenance. The [BitLife achievement inventory](https://bitlife-life-simulator.fandom.com/wiki/Achievements) documents filling owned museum exhibits |
| G074 | Social media (BITLIFE-COMPARISON.md) | OPEN — Missing dedicated subscription-creator and music-upload platforms. [Community social documentation](https://bitlife-life-simulator.fandom.com/wiki/Social_Media) describes OnlyFans subscriptions/tips; [official release notes](https://apps.apple.com/cg/app/bitlife-life-simulator/id1374403536) add SoundCloud uploads, collaboration and song sales. Use original parody names and non-graphic adult presentation |
| G075 | Hobbies and outdoors (BITLIFE-COMPARISON.md) | OPEN — Sustained projects, clubs, competitions, friendships and personal collections. Our outdoor actions exist even though the separate outdoor lifestyle flag adds little by itself |
| G076 | Travel and migration (BITLIFE-COMPARISON.md) | OPEN — More locations plus researched local institutions, language and migration chapters; no exact current BitLife country-count claim made |
| G077 | Ordinary crime (BITLIFE-COMPARISON.md) | OPEN — A full target/action audit is still needed. [BitLife crime documentation](https://bitlife-life-simulator.fandom.com/wiki/Crime) includes porch theft and embezzlement; its [official help](https://bitlifeapp.com/help/) describes train robbery. Do not equate our named Wanted crime severities with available player actions |
| G078 | Murder and serious adult content (BITLIFE-COMPARISON.md) | OPEN — Persistent victims/families, investigations, grief, testimony and consequences; expand adult consensual relationship stories without explicit sexual scenes |
| G079 | Justice (BITLIFE-COMPARISON.md) | OPEN — More readable connected cases and outcomes; verify pleas/sentencing distinctions before claiming full coverage |
| G080 | Prison and re-entry (BITLIFE-COMPARISON.md) | OPEN — More programs, staff ethics, family continuity, housing/work after release and playable supervision; never confuse separate-mode richness with every human-prison feature being equivalent |
| G081 | Challenges and collecting goals (BITLIFE-COMPARISON.md) | OPEN — More scenario combinations, searchable progress and memorable rewards; count definitions separately from reliably reachable goals |
| G082 | Minigames (BITLIFE-COMPARISON.md) | OPEN — Stronger contextual difficulty, opponent variety, skill feedback and accessibility; the larger count does not establish better combat or casino depth |
| G083 | Rewind and sandbox (BITLIFE-COMPARISON.md) | OPEN — BitLife's official Time Machine allows choosing years to rewind; our one-year snapshot is a narrower mechanic, not equivalent arbitrary history navigation |
| G084 | Interface and accessibility (BITLIFE-COMPARISON.md) | OPEN — Apply search/filtering and clear eligibility explanations consistently; prioritize function with each visual pass |
| G085 | Immediate (BITLIFE-COMPARISON.md) | OPEN — Purchase creates an owned business; rooms, staff, costs, revenue, failure/sale and succession work and persist |
| G086 | Next household update (BITLIFE-COMPARISON.md) | OPEN — Resident roster, income/expense breakdown, contributions, dependents, ownership and affordability agree after save/load and child transfer |
| G087 | Next content track (BITLIFE-COMPARISON.md) | OPEN — Authored projects, collaborators, licensing, releases and income; not another generic follower button |
| G088 | Major management track (BITLIFE-COMPARISON.md) | OPEN — Three distinct loops with real operating decisions, readable yearly results and family continuity |
| G089 | Career depth track (BITLIFE-COMPARISON.md) | OPEN — Coaches/moves/opponents; selectable genres, casting several roles and persistent production histories |
| G090 | Childhood track (BITLIFE-COMPARISON.md) | OPEN — Named peers/mentors, projects, qualifications, scholarships and opportunities that continue into adult life |
| G091 | Work/economy track (BITLIFE-COMPARISON.md) | OPEN — Cases/clients/projects, suppliers, prices and facilities; portfolio work and several concurrent part-time commitments |
| G092 | Relationships track (BITLIFE-COMPARISON.md) | OPEN — Schedules, independent ambitions and remembered responsibilities; no invented child achievements during transfer |
| G093 | World track (BITLIFE-COMPARISON.md) | OPEN — Distinct opportunities and institutions, local stories and coherent moving/credential rules |
| G094 | Later-life track (BITLIFE-COMPARISON.md) | OPEN — Playable retirement goals, care arrangements, executor decisions and intergenerational memories |
| G095 | Continuous (BITLIFE-COMPARISON.md) | OPEN — Search/filter/bookmarks, visible prerequisites, contextual suggestions and annual summaries of actual consequences |
| G096 | Generations and continuity (UPDATE-REGISTER.md) | OPEN — v0.28 records and transfer foundations; v0.29 dormant venue operation. Full assets, ambitions and estate administration remain open |
| G097 | Relationships and agency (UPDATE-REGISTER.md) | OPEN — Existing bonds and authored arcs; broader NPC motives, initiatives and lasting repair remain open |
| G098 | Household time and routines (UPDATE-REGISTER.md) | OPEN — v0.29 chore/rest choices and routine presets. Shared responsibility, seasonal choices and comprehensive energy integration remain open |
| G099 | Housing and neighborhoods (UPDATE-REGISTER.md) | OPEN — Existing leases/roommates; v0.29 actual bill breakdown. Shared accounts, adaptations, renovations and neighborhood depth remain open |
| G100 | Education (UPDATE-REGISTER.md) | OPEN — v0.30 quizzes, practicals, stat readiness and interactive activities/elections. Full curricula, campus/vocational and lifelong-learning routes remain open |
| G101 | Ordinary work (UPDATE-REGISTER.md) | OPEN — v0.32: 89 occupations with two specific tasks/briefs each; projects, clients, mentors, specialities, practical promotion requirements and training assessments. Detailed equipment systems and broader business contract portfolios remain open |
| G102 | Business and public careers (UPDATE-REGISTER.md) | OPEN — v0.29 adds venue and producer loops. Products, suppliers, contract portfolios and detailed existing career expansion remain open |
| G103 | Finance and balance (UPDATE-REGISTER.md) | OPEN — v0.29 reconciles household bill lines and venue reserves; unified whole-life accounts, shared ownership and broader instruments remain open |
| G104 | Health and wellbeing (UPDATE-REGISTER.md) | OPEN — Existing care systems; richer histories, accommodations, caregiving and recovery remain open |
| G105 | Adult relationships (UPDATE-REGISTER.md) | OPEN — Existing non-graphic arcs; v0.29 adult creator channel. Compatibility, agreements, intimacy narratives and theme controls remain open |
| G106 | Crime and justice (UPDATE-REGISTER.md) | OPEN — Existing crime/court/prison foundations; investigations, connected consequences and re-entry remain open |
| G107 | Places and world (UPDATE-REGISTER.md) | OPEN — Fourteen countries and regional foundations; cultural variety and connected migration remain open |
| G108 | Hobbies and community (UPDATE-REGISTER.md) | OPEN — v0.29 curated museum/community evening; broader projects, clubs and traditions remain open |
| G109 | Later life and endings (UPDATE-REGISTER.md) | OPEN — Existing pensions, confirmed ending and v0.28 annual summary; retirement chapters, executor duties and grief remain open |
| G110 | Modes and original stories (UPDATE-REGISTER.md) | OPEN — Existing paths and separate modes; all requested expansions and original campaigns remain open |
| G111 | Games and usability (UPDATE-REGISTER.md) | OPEN — 40 challenge definitions including the new school-quiz mode; v0.30 adapts games into school, martial and sports loops. Additional bespoke games and consistent search remain open |
| G112 | Presentation (UPDATE-REGISTER.md) | OPEN — Existing summaries and dark styling; contextual help, broader filters, original art/audio and explanations remain open |
| G113 | Reliability and delivery (UPDATE-REGISTER.md) | OPEN — Run per-release checks, migration, balances and package tests; ongoing rather than permanently completed |
| G114 | Luxury route (UPDATE-REGISTER.md) | OPEN — Islands, richer social chapters, succession and price balancing |
| G115 | Music production and upload (UPDATE-REGISTER.md) | OPEN — Artist contracts, deeper production tools, reception and release stories |
| G116 | Adult subscription creator (UPDATE-REGISTER.md) | OPEN — Boundaries/reputation narratives, collaborators and detailed audience behavior |
| G117 | Museum ownership (UPDATE-REGISTER.md) | OPEN — Personal collection displays, provenance, security and visitor chapters |
| G118 | Owned intelligence agency (UPDATE-REGISTER.md) | OPEN — Equipment, fuller agent relationships and distinct case stories |
| G119 | Fighter/director depth (UPDATE-REGISTER.md) | OPEN — Coaches/moves/opponents; selectable genres, multi-role casting and crew continuity |
| G120 | All other comparison categories (UPDATE-REGISTER.md) | OPEN — Complete and verify individual mechanics, catalogs and integrations before advertising parity |

## Current delivered evidence and next closure priorities

[v0.71 application/content coverage](releases/V0.71-COVERAGE.md), [validation](releases/V0.71-VALIDATION.md) and [native build](NATIVE-WINDOWS.md) add executable delivery, simple branding, three scenario lives and two original campaigns. This is an increment toward v1.0, not full completion.

[v0.70 coverage](releases/V0.70-COVERAGE.md) and
[validation](releases/V0.70-VALIDATION.md) document the concrete new behavior.
They do not close the entire campaign. First priorities remain full consequential
career/client histories; child/school community follow-through; connected crime
and recovery; business/special-career operations; then all mode, accessibility,
migration and representative lifespan gaps above. Health, parenting, place and
later-life requirements continue in the same register, not a forgotten backlog.

The table, campaign and guide rows overlap intentionally: a feature can support
several requirements, but one passing check cannot close unrelated requirements.
The obsolete registers now link here. Historical evidence is preserved.


## v0.72 operating-company evidence

[Coverage](releases/V0.72-COVERAGE.md) and [focused validation](releases/V0.72-VALIDATION.md)
add concrete evidence for C064/C065/C071 and the work/finance, enterprise and
generation milestones: 24 distinct product/service plans, 36 original supplier
names, prices/pay/capacity with actual annual account effects, named repeat
customer orders, 24 once-per-person industry issues, clear saved accounts,
living company handovers and whole-company inheritance to one adult operator.
Existing staff identities, operating debt, contracts and account history persist.
Other owners' operating companies use the same calculation and continue off screen.
No company is simultaneously inherited as cash and retained as an operating asset.

These are reviewed integrations, not automatic closure of entire campaign rows.
Product plans currently select one of two lines; per-product physical inventory,
market-research projects, facility expansion, supplier-specific contracts and
lead times, detailed staff disputes, partnership governance/restructuring and
longer customer histories remain open under the existing requirements/comparison
rows. Off-screen owners do not make new strategic decisions or run player-only
audit minigames; companies of deceased off-screen NPCs still need the broader
world-estate implementation. None of these gaps is deferred beyond v1.0.


## v0.73 portrait and readability evidence

[Coverage](releases/V0.73-COVERAGE.md) and [validation](releases/V0.73-VALIDATION.md)
record the user's additional instructions H34–H36. Emoji-like faces keep the
circular portrait layout; eyes, eyebrows, mouths, complexion and age details are
part of the drawn person. Automatic expressions use actual wellbeing and retain
the existing neutral preference. Optional personal charms are separate cosmetics,
not facial-status emojis. Free feature choices are available in Appearance.
NPC identities retain their own look in records, relationship rows and family
trees, and a living child transfer restores that child's actual facial choices.
Existing paid look indices and ownership are preserved; complete visual-equivalence
review of all themed looks and all human modes remains open.

26 authored short summaries fold long explanations into inline Details on mapped
screens. Short factual lines and costs remain visible. Unmapped explanations are
not silently truncated. The full-game wording and layout gate remains open.
No other accepted requirement is removed or deferred beyond v1.0.


## v0.74 verified operating additions and remaining gates

[Coverage](releases/V0.74-COVERAGE.md) and [validation](releases/V0.74-VALIDATION.md)
replace the v0.72 single-product-plan limitation with two actual product stocks.
Each retains quantity, cost and age. Sales consume available stock; excess demand
is missed; damaged, expired and unused perishable/service batches are written off.
Supplier contracts retain their product, quantities, bill, delivery risk and due
year. Value, reliable and specialist suppliers have distinct lead times and risk.
Existing contracts survive plan changes, reload, live succession and sales.
Stock targets split across the two-product mix rather than doubling orders.

Actual accounts separate sold-stock cost, purchases, overhead, upkeep, payroll,
interest, profit, cash flow, reserve and available owner drawing. Owner capital
funding moves existing cash without inventing income. Facility levels affect
production capacity, stock damage/overhead or saved research assessments and
carry real purchase/upkeep costs. Forty-eight authored industry assessments
support two-stage projects, saved shuffled options/rolls, deadlines and lasting
product demand insights. Prior unread assessments are preferred after reload.

Living successors and buyers keep the whole operating packet. Companies continue
stock/delivery/cash accounts off screen. Voluntary closure returns reserve and
physical-stock salvage, less signed-supply cancellation and active-order fees.
Sale transfers obligations rather than cancelling them; public ownership share
and listing status are retained in the buyer's company packet.

This closes these named implementation gaps from the v0.72 evidence section:
per-product stock, supplier-specific delivery contracts, research projects,
facility levels and reserve/profit separation. It does not close C064/C065/C071
in full. Negotiated partnerships/governance, staff disputes, debt restructuring,
longer customer/world histories, deceased NPC estate administration, stock-price
updates for public off-screen companies, estate liquidation cancellation rules,
broader difficulty balance and all other accepted campaign gaps remain open.
The full v1.0 objective and all milestone gates remain intact.

## v0.75 health-course evidence and remaining acceptance

[Coverage](releases/V0.75-COVERAGE.md) and [focused validation](releases/V0.75-VALIDATION.md)
record shared clinical state, care control, practical adjustments, real caregiving
and medical packets across living/inherited changes of viewpoint. These named
mechanics no longer use the older label-only cure and permanent-control shortcuts.
The complete C082–C090, C108 and C138 gates remain open: full authored clinical
branch coverage, dependence/relapse work, broadly balanced difficulty, representative
lifespans, all old mode/clinical text and provider/world pathways still need acceptance.
Off-screen records advance established conditions, bills, injury recovery, mental
progress and basic sensory/dental wear; they do not generate a complete independent
NPC clinical career or auto-book every assessment. No unrelated gate is closed.

## v0.76 recovery evidence and remaining acceptance

[Coverage](releases/V0.76-COVERAGE.md) and [focused validation](releases/V0.76-VALIDATION.md)
record gradual support, two stable years, retained setbacks and existing habit
packets across changes of viewpoint. Twenty-four non-repeating pressure scenes
replace the annual identical gambling/shopping questions and automatic passive
harm for the other four habits. Costs, readiness, family bonds and saved plans
now decide actual results; a habit alone no longer randomly creates a DUI or
possession conviction. Exact annual and prompt guards prevent duplicate charges.

These named implementation gaps are addressed; C086–C090, C108 and G048 remain
open pending their wider authored, mode, provider, world and lifespan acceptance.
All original campaign items, earlier requests and the approved milestone table
remain intact. No broader requirement or v1.0 gate is closed by this increment.

## v0.77 emotional-course evidence and remaining acceptance

[Coverage](releases/V0.77-COVERAGE.md) and [focused validation](releases/V0.77-VALIDATION.md)
record actual named losses, contact, routines and completed next-year follow-ups.
These address the permanent-loss-flag shortcut and detached coping choices; the
full C086/C088/C089/C090/C108 and related comparison gates remain open. Existing
NPC emotional courses advance rather than freezing, without claiming complete
independent NPC counselling/social histories. All original requirements and the
approved milestone table remain intact; v1.0 is not established.

## v0.78 debt-course evidence and remaining acceptance

[Coverage](releases/V0.78-COVERAGE.md) and [focused validation](releases/V0.78-VALIDATION.md)
record actual lender arrangements, payment totals, ledger conservation and personal
debt/credit continuity. This fixes mismatched contractual repayment scaling and
adds consequences to hardship reviews. Education/mortgage hardship, estate/default
resolution and representative whole-life financial balance remain open under C076.
The corrected avatar drawing follows the earlier person-portrait design while
retaining existing identities, expressions and cosmetics.
All original campaign rows and milestone requirements remain intact.

## v0.78.1 original portrait restoration

The user rejected the redrawn approximations. The actual earlier portrait glyphs,
font, sizing, backdrops and charms are restored, with the original working editor
controls. All saved modern appearance fields remain intact; controls whose values
cannot affect the original glyph are hidden, rather than falsely implying they work.
Life condition remains available as a tooltip. The requested in-face expressions
and additional hair/eye/facial customization in the original design remain unfinished;
they are not declared completed or silently removed from accepted scope. Future
art work must preserve the user's actual original reference. This correction keeps
the v0.78 gameplay and finance fixes.

## v0.78.2 — additions within the actual original portraits

The accepted reference is the Windows portrait visible in the original screenshots.
The bundled Noto font is not the artwork Windows actually displayed through its
fallback. The matching MIT-licensed Microsoft Fluent flat paths now supply adult
face extensions. This supersedes earlier inaccurate Noto/art provenance claims.

Everyday adult expressions transform the existing mouth, brows and eye paths.
Twelve hair and eight iris colours are free, start at Original for old saves,
and remain with the person across reload and living child transfer. New NPCs
can receive saved colour variants. The neutral/steady uncustomized face still
uses the exact original glyph. Infants, children, older people, special hair and
themed looks retain their original glyphs; their expression/cosmetic coverage
is unfinished. Earlier advanced redraw fields remain saved but hidden.

This is a partial H35 implementation, not closure of presentation or v1.0.
The current grouped remaining work is in [NEXT-WORK.md](NEXT-WORK.md).

## v0.79 — combined items 1–6: avatars through events

The user requested one combined update stream for the first six groups in
NEXT-WORK.md. This batch connects existing foundations rather than declaring
those broad groups finished. v0.79 includes:

- Five free original-face accessories and three details, with saved NPC variants.
- Actual school peers and saved choices throughout existing multi-year projects.
- Thirty-two new curriculum questions: eight for each existing age band.
- Connections from kept/broken promises, completed/failed work and enterprise
  commitments. They retain actual participant identities and dated source records.
- Named recurring enterprise counterparts and existing workplace colleagues.
- Forty-eight authored follow-through scenes with choices and next-year endings.
  Pools are filtered by domain, field and whether the earlier result needs repair.
- Earned, non-stacking, temporary field support affects job standing, work checks,
  relevant learning and enterprise starting quality. Trust, readiness and expiry
  matter. Optional invitations expire without inventing a broken promise.
- Pending choices survive reload; stale outcomes cannot reward twice. Living
  child transfer keeps the parent's records with the parent. Dormant committed
  follow-ups settle for that owner without rewarding the active child.

H35 remains OPEN for all-age/special-look coverage and further cosmetics. School,
relationship, career, enterprise and event gates remain OPEN for their broader
branches and whole-life acceptance. No accepted requirement has been withdrawn.

## v0.80 — combined items 7–12: competition through place

The user requested the next six groups together. This batch adds safe/balanced/push
competition pacing, saved injury rolls using the existing medical system, recovery
time, eighteen fixture cues and three-round reward-free workshop practice. Shared
reserves gain standing monthly amounts settled once yearly from the owner's actual
cash, with a protected cash floor and no contribution debt. Existing caregiver
schedules gain paid shared/professional respite and availability checks.

Parenting has eighteen age-band scenes and yearly family/shared/professional
childcare plans. Development and upbringing memories belong to the real child;
parent obligations remain with the parent through transfer. Costs are booked once,
plans lapse or interrupt, and custody is not overridden. Appeals now have a saved
transcript-ground and submission stage, a recorded decision and bounded sentence
reduction; old pending appeals remain resolvable. Country-specific language skills
and local institution upkeep affect existing community and hiring systems.

All six broad groups remain OPEN. This is not a review of all 39 minigames, full
housing/debt/estate closure, every clinical or family branch, complete criminal
investigations/re-entry or every world/migration scenario. Items 1–6 and 13–16,
the approved milestone table and all accepted requirement rows remain in scope.

## v0.81 — integrated review improvements

The review fixes are one batch: seven grouped activity destinations, clearer
health labels, brief player wording, independent yearly NPC learning/social
progress and changing priorities, eighteen shared moments, and forty-two
parenting scenes with preference-sensitive choices and next-year conclusions.
Repair, music and negotiation gain distinct untimed hands-on boards with saved
work. Existing pending workshop attempts still resume in their original format.
Events, menus and minigames share calm asymmetric rounded frames and icon badges.
Long event/large-menu contents scroll within a bounded card; active games scale
with breathing room and retain more room for enlarged display settings.

These changes address the candid review and the user's added consistency request.
They do not silently declare any broad accepted requirement complete. All original
groups, milestone table rows and release acceptance gates remain as recorded.
The social and parenting pools are finite; optional exhausted pools do not force
the same scene again or charge for an absent activity. Independent NPC decisions
are a modest goal/social layer, not a simulation of every NPC career and household.

## Completion work included in v0.82 — 3 October

- **Education:** 84 authored practical questions across 28 fields. Required study
  no longer runs out because unrelated optional job questions were exhausted.
  Completed qualifications remain permanent, preventing repeated reward farming.
  Major changes preview credits lost/kept, remaining years and fees; grades,
  scholarships and debt persist. Returning after interruption keeps the transcript
  and debt, but ends the former scholarship. Regional associate qualifications do
  not substitute for a bachelor's degree or professional licence.
- **Original avatars:** child and older faces now support facial expressions,
  hair/eye colours and the existing accessories within their matching original
  Fluent geometry. Forty-two attributed MIT vectors cover seven age/gender kinds
  across six tones. Neutral uncustomized faces still use the original glyph.
  Adult special hair/themed looks remain outside this expression coverage.
- **Stories:** the approved six additions bring the original catalog to twelve.
  Each new campaign has ten authored scenes, recurring characters and three
  reachable endings. Decisions are journaled once; scene order is independent
  of character age. Old preview journals are archived; completed saves stay dead.
  The library has one scrolling surface, searchable names and genre filters.
- **Save ownership:** loading deep-copies mutable state so migration and play
  cannot rewrite the caller's backup or historical snapshot.

The focused checks and their limits are recorded in
[V1.0-PREPARATION.md](V1.0-PREPARATION.md) and
[v0.82 validation](releases/V0.82-VALIDATION.md). The owner requested this interim
package before returning to development. These changes do not close the sixteen
broad groups or establish full v1.0 scope and release acceptance.

## Completion work included in v0.83 — 3 October

- **School:** expanded the choice set to 34 clubs and 18 cliques, added stage-based
  classes and assessments, persistent named staff/classmates, progress and
  attendance bars, and situations with lasting relationship consequences.
- **People:** compact relationship summaries now lead to the existing detailed
  profiles; school and work scenes identify the people involved.
- **Work:** ordinary jobs show their established duties and named colleagues, with
  repeatable activities tied to performance, time and stress.

See [v0.83 coverage](releases/V0.83-COVERAGE.md) and
[playtest status](releases/V0.83-VALIDATION.md). The owner requested this interim
Windows package and will playtest it. Latest edits were compiled for delivery but
were not retested; feature-complete status and all remaining release gates stay open.

## Completion work included in v0.84 — 3 October

- **School navigation:** Education opens one school hub. Its classroom is keyed
  to the current grade, with a named teacher and classmates; subjects, school
  activities, day choices, projects and past grades have separate pages.
- **Contextual practice:** the standalone competition list is gone. Existing
  practice remains beside job duties, household budgeting, the music studio and
  martial arts. Work challenges are grouped into trade, people and service.
- **Simpler hubs:** More now has seven destinations instead of one long list;
  employment uses four short areas, with duties, situations and coworkers further
  grouped beneath the player's job. Legacy school screens with duplicate routes
  were removed.
- **No feature-complete claim:** no new gameplay systems were added. The owner's
  requested no-test playtest is still pending; v1.0 acceptance remains open.

See [v0.84 coverage](releases/V0.84-COVERAGE.md) and
[delivery notes](releases/V0.84-VALIDATION.md).

## Completion work included in v0.85 — 3 October

- **People:** active relationships open through six short sections with live
  counts. Profiles, interactions, children and history remain available.
- **Assets:** money, home, transport, belongings and ventures have separate
  pages. Shopping is one tap from owned-home and vehicle pages.
- **Work:** ordinary job search is separate from career growth, creator work,
  special careers and business.
- **Wording:** More, the quick guide and common navigation labels are shorter.
- **No tests:** prepared for the owner's playtest request; no test suite,
  simulation or game run-through was used.

See [v0.85 coverage](releases/V0.85-COVERAGE.md) and
[delivery notes](releases/V0.85-VALIDATION.md).

# Prior-update feature closeout board

**Active focus:** finish features already started in earlier updates before
expanding the game with fresh scope. This board groups closeout work; the
[completion register](COMPLETION-REGISTER.md) remains the source of every
accepted requirement and its detailed evidence.

The user has asked for no tests, gameplay runs or simulations. Source changes can
be made and reviewed, but no feature will be described as player-verified or
complete on code inspection alone. The owner will provide gameplay acceptance.
The owner has approved local review packages across v0.90–v0.99; v1.0 remains
the final consolidated release after scope and release gates are ready.

| Area | Existing foundation from earlier updates | Closeout still needed | Status |
| --- | --- | --- | --- |
| People, relationships and continuity | NPC profiles, bonds, memories, event history, children, living transfers and family sections | Finish consistent relationship actions and summaries; trace consequences; preserve obligations and ownership across transfer; remove extended-family clutter from new routine scenes while retaining old records | In progress; H15 cleanup now includes event-role pools and the royal rival cast, plus consequence-to-profile links. Source only; acceptance open |
| School and growing up | Grade classrooms, named teachers/classmates, stage-based classes and assessments, attendance, projects, clubs, cliques, teams and portfolios | Finish national and background differences, broader lasting callbacks, and confirm the real school-to-adult transitions | v0.91 queues graduation at the diploma transition with the actual classroom cast; related school projects now factor into matching university admission estimates. Broader coverage and owner acceptance remain open |
| Work and careers | Named job duties, job-specific scenes, coworkers, projects, mentors, field records, delayed reviews and promotion requirements | Close catalog gaps and align duties, qualifications, references, pay, stress, contracts, equipment, leave and management progression | Job listings now open a concise application preview with salary, competition, fit estimate and fit factors. Specialist breadth, catalog coverage and owner acceptance remain open |
| Household money, shopping and ownership | Budgeting, configurable borrowing, asset stores, home/vehicle catalogs, personal loans and operating companies | Reconcile affordability, bills, ownership, upkeep, debt recovery, sale/inheritance and child transfers across one consistent ledger | Personal saving consolidated into one after-bill plan; shared-reserve contributions settle after finances; the budget view groups named income (including net rental returns), expenses, signed transfers, current debts and net worth. Home blockers and car trade-in amounts now match purchase checks. Broader ledger, ownership and acceptance work remains open |
| Activities, sports and minigames | Contextual activities, practice, school/amateur seasons, martial styles and 39 playable minigames | Close inputs, instructions, accessibility, fair rewards, contextual outcomes and original per-game boards/scenery; keep the established visual style | Open; gameplay foundations exist, visual coverage is incomplete |
| Events, life stages and consequences | Age-specific pools, event history, cross-save cooldowns, follow-ups and annual summaries | Finish thin age/context pools and unresolved branches; make important choices affect later people, opportunities or obligations; avoid forced repetitive prompts | Open; v0.90 adds age-five and age-thirty scenes plus school, work and community callbacks. Wider age pools and owner acceptance remain |
| Health, adult drama and recovery | Medical histories, care schedules, crimes, hearings, appeals, prison, adult boundaries and recovery systems | Finish connected aftermath, lawful alternatives, treatment/re-entry paths and continuity across age changes and transfers | Open; partial foundations remain |
| Modes, stories and identity | Pet, prison, royal, special-life and original-story modes; original portraits, cosmetics and icons | Complete thin mode-specific loops and endings; preserve the original avatar design while filling age, expression, icon and minigame-art gaps | Open; partial foundations remain |
| Navigation and presentation | Dark themes, grouped hubs, concise summaries, varied panels and the native Windows game | Finish path-by-path consistency for wording, costs, Back behavior, search, bulk buttons, accessibility, audio and responsive panel sizing | In progress; removed a duplicate School challenges search destination and corrected the Education shortcut label. Whole-game path and visual acceptance remain open |
| Public project and delivery | Local README/roadmap cleanup, release records, credits and native build setup | Reconcile public GitHub content with the actual game; complete packaging, upgrade/save migration notes and honest release documentation | Open; public page still needs its own cleanup |

## Closeout rules

- Do not count an earlier preview or a partially working feature as full closure.
- Keep unstarted accepted work visible in the completion register; do not relabel
  it as completed just because it falls outside this closeout pass.
- Close an item only when its missing behavior and connections are implemented,
  the current documentation describes them accurately, and the owner has had a
  chance to accept the game in play.
- Keep suggestions separate from promised base-game scope unless the owner adds
  them to the accepted requirements.

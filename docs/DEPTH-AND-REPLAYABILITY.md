# Depth and replayability priorities

Status: implementation requirements after the v0.40 preview. The first pass is implemented in [v0.41](releases/V0.41-COVERAGE.md). v0.86 added a rolling cross-save cooldown for exact scenes and recently seen story families, with a fallback for exhausted pools. v0.90 contributes six optional contextual story threads whose callbacks share their story-family keys. These are content and selection improvements, not proof of unlimited unique content or full narrative acceptance.

## What the audit found

- `systems/growing_up.gd` selects from two fixed questions per age band. Answer order changes, but the scenario does not. School projects also share their three general prompts across project types.
- `data/job_tasks.json` has occupation-specific task names and questions, but repeated ignore/conceal alternatives make many decisions predictable.
- `systems/enterprise.gd` supplies different project descriptions with shared stage choices. Different descriptions need different dilemmas and consequences.
- `autoload/director.gd` tracks event IDs and recent text, with cooldowns and weighting. `autoload/event_engine.gd` also penalizes events recently encountered across lives. These controls do not guarantee fresh scenes, and direct activity prompts need a shared selection policy.
- `scenes/icons.gd` already provides an original vector system, including different vehicle and house silhouettes. Coverage needs to extend to individual occupations, subjects, activities and model variants.
- Mechanical checks establish the exercised behavior. They do not establish narrative variety, satisfying endings or balanced replayability.

## 1. One selection policy for authored scenes

Route optional event scenes, lessons, job tasks, projects and activity encounters through a common selector. Give each authored scene an ID, a story-family ID, eligibility conditions, history policy, meaningful outcome records and optional follow-up links.

Keep a per-character scene history and a shared local history across save slots and new lives. The shared ring holds the latest 64 noted scenes; selection cools exact scenes for 18 notes and their story families for 4 notes when an alternative exists. Optional story scenes should not repeat verbatim within a life. Prioritize unseen story families across lives, rather than treating a different name or shuffled answer order as new content. Persist a selected pending scene before presentation so loading a save cannot reroll an unresolved decision.

Age should establish eligibility and believable timing. Starting school and other required transitions still occur; their surrounding optional stories should vary with circumstances. Distinguish authored encounters from recurring systems such as bills, grades, practice and maintenance.

When no suitable fresh scene exists, use a quiet period or a genuinely different eligible consequence. Direct event selection falls back to the least familiar eligible pool when the recent cooldown would empty that pool; it never hides a required transition. Do not force an old scene to fill an event quota. A finite authored library cannot guarantee unlimited unique play; expansion must accompany selection improvements.

## 2. Consequences and endings are part of authoring

Every activity must have a defined purpose: a resource, relationship, skill, opportunity, risk or persistent change. Every substantial story must have an immediate response and a recorded resolved, abandoned, failed or ongoing state. Follow-ups must have deadlines and valid alternatives when a participant dies, moves away or changes role.

Show why important outcomes happened in concise feedback. Preserve relevant memories and achievements across education, employment, relationships and child transfers. Resolve stories through actual state changes rather than a congratulatory paragraph alone.

Example: helping a classmate can improve that specific relationship, cost preparation time, affect an upcoming assessment and create a later referral opportunity. A referral still depends on the friend's future circumstances and the player's qualifications.

## 3. Different features need different decisions

| Area | Depth to author | Persistent consequences |
| --- | --- | --- |
| Childhood and education | Flexible milestones, subject units, friendship conflicts, teacher responses, club seasons, talent rehearsals, council promises, assessments and setbacks | Skills, qualifications, recommendations, friendships, access needs, confidence and later opportunities |
| Employment | Distinct routines, workloads, specialists, recurring coworkers, employer conditions, occupation-specific cases and progression | Pay, stress, competence, safety, client trust, references, disciplinary records and promotion eligibility |
| Vehicles | Reliability, mileage, condition, passenger/cargo needs, insurance, servicing, breakdowns and model-specific ownership encounters | Running costs, travel access, commute reliability, work eligibility, resale value and household convenience |
| Housing | Location, commute, maintenance, household capacity, neighbors and suitability for changing needs | Costs, access to opportunities, relationships, safety, rental income and adaptations |
| Relationships | Motives, remembered promises, disagreements, reconciliation, separations, blended families and independent NPC decisions | Trust, support, custody, household obligations, reputation and future contact |
| Activities | Progression, recurring partners, meaningful schedules, events tied to mastery and costly bulk routines | Fitness, learning, stress, fatigue, injury, social ties and time spent away from other goals |
| Crime and disputes | Motive, evidence, discovery, reporting, investigation, hearing and aftermath | Victim and family responses, legal records, restitution, employment access and continuing relationships |

Replace generic obviously correct choices with contextual tradeoffs where appropriate. Tests can still have correct answers; life dilemmas need competing costs and benefits. Money, time, health, skills and relationships should constrain success without making high stats an automatic win.

## 4. Authored expansion across the whole life

Build separate pools for infancy, early childhood, later childhood, adolescence, young adulthood, middle age and later life. Subdivide by family circumstances, resources, health, interests, location and previous decisions. Avoid assigning one compulsory optional story to a particular birthday.

Expand occupation pools in coherent career families, then give each occupation distinctive cases, progression and consequences. Expand school subjects and projects, household/ownership encounters, relationships and hobbies alongside those families so careers connect to the rest of life.

Count unique dilemmas and outcome chains, not IDs, renamed participants or shuffled wording. Reuse shared mechanics while authoring different situations. Larger pools alone cannot repair disconnected rewards or dominant choices.

## 5. Original, readable visual identity

Extend the existing vector drawing style. Assign distinguishable symbols to occupations, educational fields, activities and owned-item variants. Examples: stethoscope for clinical work, ledger for accounting, wiring tools for electrical work; anatomical study, laboratory work and literature need different subject symbols.

Vehicle variants should communicate meaningful body/model differences. Housing silhouettes should communicate form and scale. Keep muted theme colors, consistent line weight, readable small sizes and text labels. Preserve the established avatar design and dark, restrained panels.

## 6. Approved refinement ideas board

Added on 5 October 2026. These are refinements to existing screens and systems,
not new top-level destinations:

- **Show why it mattered:** major summaries link a choice to the stat, person,
  opportunity or obligation it changed, then note what carries forward.
- **Keep scenes feeling fresh:** use each save's history, life stage and current
  circumstances to favor less-seen eligible scenes. A finite story library cannot
  promise that nothing ever repeats, so quiet years and meaningfully different
  outcomes are better than forcing a stale prompt.
- **Connect the systems:** let existing school, work, care and relationship
  records create later opportunities or trade-offs. For example, a club project
  can become a reference, while caregiving may change a work schedule.

These ideas now belong on the closeout board and should be delivered through the
existing Life Log, profile, school and work pages wherever possible.

## Delivery order and acceptance

1. Establish shared novelty/history policy and remove fixed activity selection bottlenecks.
2. Expand school/age-band content and close incomplete consequence chains.
3. Deepen occupation decisions, coworker continuity and career progression.
4. Connect vehicles, housing, family and activities to practical opportunities and costs.
5. Add appropriate individual icons alongside the content they describe.
6. Audit the remaining modes and accepted campaign requirements against the same standards.

Use focused checks with isolated saves and muted audio. Verify selection across several new lives/save slots, reload stability, age eligibility, story completion when circumstances change, visible persistent consequences and meaningful tradeoffs. Do not run routine large simulation batches. Do not call the base game complete while accepted features still depend on placeholder scenes or disconnected outcomes.

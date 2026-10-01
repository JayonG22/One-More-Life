> Historical document. Preserved for context; counts, completion claims and
> platform instructions are not current release guarantees.
> Return to the [documentation index](../README.md).

# ONE MORE LIFE — Roadmap

## Where it stands

**1.0 is reserved for the finished game: the day there is nothing left to fix, add, improve or change.** Until then the version stays 0.x and the count keeps going (the releases once numbered 1.0–1.4 are now 0.17–0.21). The rule
it was measured against: a system does not count as complete because its menu
opens. It must create consequences, connect to other systems, survive
save/load, and generate meaningfully different life stories.

| Version | Name | Status |
| --- | --- | --- |
| v0.7 | Life Gets Complicated | shipped |
| v0.8 | Ambition & Society | shipped |
| v0.9–v0.14 | A Living World → Where You Started | shipped |
| **v0.15** | **Everything From Real Life** | **shipped** — see `docs/history/CHANGELOG.md#version-0-15-0` |
| **v0.16** | **Work and Body** | **shipped** — see `docs/history/CHANGELOG.md#version-0-16-0` |
| **v0.17** | **One More Life** | **shipped** — see `docs/history/CHANGELOG.md#version-0-17-0` |
| **v0.18** | **Pets Life** | **shipped** — see `docs/history/CHANGELOG.md#version-0-18-0` |
| **v0.19** | **Prison Life** | **shipped** — see `docs/history/CHANGELOG.md#version-0-19-0` |
| **v0.20** | **Share, Legacy, Seeded Lives, The Outside** | **shipped** — see `docs/history/CHANGELOG.md#version-0-20-0` |
| v0.21+ | Whatever is next | the architecture takes new modes cleanly |

### The 1.0 release gates, and what met them

| Gate | Evidence |
| --- | --- |
| No one-outcome choices; every event has three or more choices | `v15_system_test` (library: 760 events, 2,231 choices, 0 thin) |
| Delayed follow-ups at the design target | 25.0% of events lead to a delayed echo (target 25%) |
| No dead buttons | `menu_crawl`: about 2,000 menus and 10,900 actions, no errors |
| All major systems have cross-system consequences | `v08_echo_test`, `v18_echo_test` |
| Every life path has progression and an ending | `v17_arcs_test`: 6 roads × 5 chapters, 27 endings reachable |
| Every minigame has a fair manual path and a regression bot | `mg_smart`: 22 of 22 winnable, none without a bot |
| Accessibility: keyboard, labels, contrast, text size, reduced motion | `a11y_test` |
| UI at supported resolutions and interface sizes | `layout_audit` (3,197 controls, 0 problems), `a11y_test` (every size to 130%) |
| Long-life and performance | `perf_test`: a 300-year life, 16 ms a year, 0.25 MB save |
| Migration from a supported earlier version | `tools/mig_check.sh` plays a real v0.14 save forward |
| Originality / licensing review | `CREDITS.md`: two open-licensed fonts, everything else original |
| One command to run all of it | `tools/run_gates.sh` |

### Deliberately held for later

- **Twins / parallel rival system** remains outside the baseline until its
  planned "coming soon" reveal.
- **Streamline icons**: licensed, so not used. The game draws its own.

---

## After 1.0

New modes are built on a finished game, not alongside an unfinished one. Each
gets what vampire and undead got in v0.11, and what the six paths got in v0.17:
its own systems, its own content file, its own arc of chapters and endings, its
own gate. A mode is a *life kind*: it lives in `Lives`, ages in `Real`, and
writes its own ending into the same legacy and tombstone as everyone else.

### v0.18 — Pets Life  (live as the animal) — SHIPPED

> The design below is the brief. What actually shipped, and what was held back, is
> in `docs/history/CHANGELOG.md#version-0-18-0`. Not built from this brief: a multi-pet pack hierarchy
> within a household, breeding with puppies as the next life (the next life is
> *another animal in the same house* instead), seasons, and guide / police / search
> roles beyond the calling system.

You are a dog, a cat, a rabbit, a parrot, a horse. The humans are the cast; their
lives happen above your head and you only ever see the part that reaches the floor.

**Born into it.** Seven beginnings: a loving household, a litter in a barn, a
puppy mill, a shelter, the street, a working kennel, a show breeder. Each decides
who your first people are and how much you start out trusting them.

**What you are.** Needs, not bars-for-the-sake-of-bars: hunger, energy, health,
mood, and *trust* — the one number that is about a person, not about you.
Instinct pulls against training. Species change the rules: a cat decides, a dog
tries, a parrot talks back, a horse remembers.

**The household as a soap opera seen from below.** The owners have their own
lives (they argue, divorce, have a baby, lose a job, move) and you notice the
way an animal notices: the tone of a voice, a suitcase, a new smell. Your
behaviour changes how they feel — comforting someone through grief is a real
action with a real effect on their NPC life.

**Systems.** Walks with routes and smells and other dogs; the vet; training and
tricks; the territory; the pack and its hierarchy in a multi-pet home; rivalries
(the neighbour's cat); chewed sofas and their consequences; escape, being lost,
being found; strays (scavenging, territory, fights, kindness); shelters and
adoption; working roles (service, guide, police K9, search and rescue, herding);
shows; breeding and puppies; seasons; and ageing in the animal's own time.

**Minigames.** Fetch, squirrel chase, scent trail, steal-the-food, herding,
agility. All keyboard-playable, all with a bot, all inside the existing gate.

**Endings.** Best Friend; Hero; Show Champion; Stray King; Lost; Old Dog in the
Sun; Last Walk. The puppy you leave behind is the next life.

### v0.19 — Prison Life  (prisoner or guard) — SHIPPED

> The brief below. See `docs/history/CHANGELOG.md#version-0-19-0` for what shipped. Not built from this
> brief: a separate inmate-job economy beyond the commissary, a literal trustee
> status, a "re-entry" phase after release (the story closes at the gate, with an
> epilogue), and executions or the death penalty (by decision).

A mode with two doors into the same building. The institution is the same; what
it means from each side is not.

**Prisoner.** A sentence with a length, a crime, a block, and a hierarchy:
*fish → regular → shot-caller*, and the trustee who is neither. Commissary and
cigarettes are the money. Work detail, library, yard, mess hall, visits. Parole
boards that read your file. Appeals, and the innocent-prisoner arc. Gangs and
what protection costs. Solitary. Riots. And the **jailbreak**: a multi-stage
plan (the inside man, the laundry truck, the tunnel, riot cover) built on the
existing escape minigame, with the manhunt that follows if it works.

**Guard.** A rank ladder — cadet → officer → sergeant → lieutenant → captain →
warden — with shifts, a union, inspections, and the temptations that come with
the keys: a bribe, a favour, a look the other way. Use-of-force decisions that
follow you to the hearing. Hostage situations. Burnout. Whistleblowing, and what
Internal Affairs does with it.

**Both sides see each other.** An inmate you treated fairly is the one who
warns you before a riot. A guard you crossed is the one on the door at 3 a.m.
What a sentence does to the people outside — the visits that thin out, the
child who grows up, the marriage that doesn't wait — is a first-class system,
not a line in a log.

**Endings.** Paroled; Served It All; Died Inside; Escaped (and what that
cost); Exonerated; Warden; Whistleblower; the Guard who Became a Prisoner.

### Extra mechanics the two modes share

These came out of looking for what the base game still doesn't do:

- **Reputation with a *group*, not a person.** Packs and blocks remember how you
  treated their members, and act on it without being asked.
- **Information as a resource.** Rumours, tips and what you saw: things you can
  trade, sit on, or be punished for knowing.
- **Set pieces.** A handful of hand-built, multi-stage sequences per mode (the
  storm, the riot, the escape) that use several systems at once instead of one
  popup.
- **Someone else's perspective.** The mode's point is that you do not control the
  humans; you can only change how they feel about you, which changes what they do.

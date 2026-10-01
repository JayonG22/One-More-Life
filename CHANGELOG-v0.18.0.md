# ONE MORE LIFE — v0.18.0: Pets Life

A new **game mode**, chosen on the title screen beside Human Life — not a life
path you stumble into, and not a skin over the human game. You are the animal.

`tools/run_gates.sh` now runs **23 checks**; two are new for this mode
(`v19_pets_test`, a content-and-simulation gate, and `v19_ui_test`, which plays a
whole pet life through the real screen).

---

## Choosing a mode

The title screen opens on a **Choose your game mode** block, above the ordinary
menu and drawn differently from it: three cards — **Human Life**, **Pets Life**,
**Prison Life** (Prison arrives in v0.19 and says so). Each mode is its own game
with its own year, its own events, its own screens and its own ending.

## Pets Life

Dog, cat, rabbit, parrot or horse. You choose the animal, a name, and where it
begins; the world does the rest.

### Seven beginnings

A loving house · a farm litter · a mill · a shelter · the street · a working
line · a show line. Each decides your home, how far you trust people, how well
you are fed, how many years you start with, and what you are for.

### What you are

No money, no job, no calendar. Seven slow gauges instead — **bond** with your
person, **obedience**, **instinct**, **belly**, **territory**, **belonging**,
**fitness** — plus the household's **means** and **mood**, which you cannot
change directly but live inside. Species change the rules: a dog tries, a cat
decides, a parrot talks back, a horse remembers. Lifespans are the animal's own
(rabbit ~9 years, dog ~13, cat ~16, horse ~24, parrot ~35) and the long-lived
ones take proportionally less accident and illness a year, so the horse is not
three times as exposed as the dog.

### The household, seen from the floor

The people are the cast, and their lives happen over your head: someone loses
their job (the good tins stop), gets a better one, has a baby (you are no longer
the centre of the house), moves, breaks up (and one of them takes you), falls
ill, or dies (and the question of who takes you is asked in the kitchen).
You notice the way an animal notices: a voice, a suitcase, a smell. Money
trouble raises the real possibility of being given up; a shelter has its own
year; the street has its own winter.

### Things to do

Six menus, 30-odd actions — care and comfort (beg, nap, a lap, grooming, the
vet, **comforting a person in grief**, which really changes the household's
mood), play, learning (tricks, recall, obedience class), the wider world
(explore, mark, bark at the postie, **raid the bins**, **escape** and risk being
lost), the people (a row per person, friend and rival) and a **calling**:
companion, guardian, working animal, show animal, therapy animal, street animal,
barn keeper, racer.

### Five new minigames (all with bots, all inside the gate)

| Game | What it is |
| --- | --- |
| Stalk and Pounce | A hole shakes, then the prey shows. Pounce on that hole; pounce on an empty one and the prey gets wary |
| Scent Work | Eight forks, three noisy readings; sniffing again averages the noise away but costs time |
| Sneak | Hold to creep, release to freeze; a ❓ is the warning beat before the human looks |
| Agility Course | Hurdles to jump and tunnels to duck; the key is written on each obstacle |
| Herding | Stand on the far side of a sheep and let it walk to the pen |

### A road and seven endings

Five chapters that open on what you did (*Somebody's*, *The shape of the place*,
*What I am for*, *The test*, *The long evening*) with a turning-point event for
each, and seven endings: **Best Friend · A Hero · Best in Show · Lord of the Alley ·
A Long, Warm Life · Never Came Home · A Good Life**. They are written into the
life story, the tombstone and the ribbon.

When it ends, **Another life in the same house** starts a new animal in the
household that remembers the last one: same family name, same people, older.

### Content

- **76 events**, 228 choices, 456 outcomes. Every event has three or more choices
  and every choice two or more outcomes. 58% lead to a delayed follow-up.
- Species events (dog park, the postie, the lake, the squirrel, the cone, the
  box, the mouse, the flap, the wire, the fox, the word you were not meant to
  learn, the open window, the farrier, the plastic bag, the latch), origin
  events (a hard winter, the van with the net, the butcher, the pack, the
  shelter's Tuesday volunteer, hands, a first working day, the ring, the tractor)
  and household events (thunder, the long day alone, the big table, a bad night,
  the baby, the split, the new bed, the visitor, the burglar, the fire).
- **28 achievements** (a new *Pets Life* category), judged only in a pet life.
  Human achievements are no longer judged in one, and pet ones never are in a human.

## Under the hood

- A **separate-mode** layer: `Lives.separate()` gives a mode its own year
  (`EventEngine._age_up_separate`) and restricts it to events written for it.
  A human never meets a pet event and a pet never meets a human one — the gate
  checks both directions over hundreds of years.
- The main screen's tabs, bars, header and quick buttons are now mode-driven.
- `tools/content/gen_pets.py` and `gen_pet_achievements.py` regenerate the content.

## Checked, and not

- **Checked:** the library (depth, tags, follow-ups); isolation between modes;
  140 whole lives across every species and origin (lifespans in range, no gauge
  out of range, every cause of death and ending reachable); every menu action;
  the arc, seven endings, ribbons and tombstones; save/load; the next-life flow;
  the real screen end to end; the five minigames with bots; title-screen layout.
- **Not checked:** nothing in this mode has been played on real Windows or macOS
  hardware. A hundred lives is a simulation, not a player; whether a given event
  *lands* is a matter of taste that a gate cannot judge.

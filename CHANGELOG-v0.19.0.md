# ONE MORE LIFE — v0.19.0: Prison Life

The second new **game mode**. Pets Life (v0.18) was the first; this one is chosen the
same way — from the **Choose your game mode** block at the top of the title screen,
third card, in red. Prisoner or guard: two doors into one building.

`tools/run_gates.sh` now runs **25 checks**; two are new (`v20_prison_test`, a
content-and-simulation gate, and `v20_ui_test`, which plays both roles through the
real screen).

---

## Two doors, one building

You are either serving a sentence or working the walls, and the **building is the
same**: one facility, with a name, a security level, a warden with a style, a
tension that rises and falls, four gangs that want things, a budget, a crowding
figure and a count at four o'clock that must come out right. A riot is a riot from
both sides of the door. What it is *for* you depends on which side you are on.

Both roles are the person who walked in, with **a family outside it that goes on
without them**: parents who age and die (and a form to ask for the funeral), a
partner who decides what to do about the years, children who turn eighteen and
either send a card or don't.

### Prisoner

Seven stories decide the crime, the length, the security level and who you are
when the door shuts: **a first offence, a career criminal, a gang member, white
collar, wrongly convicted, a political prisoner, a lifer.**

- **Standing:** *fresh fish → regular → respected → shot-caller → old head.*
  Respect, heat (staff attention), conduct (the board reads it) and support from
  outside are the four numbers you live by.
- **Money is cigarettes, then commissary.** A job (kitchen, laundry, library,
  workshop, yard, infirmary, barber), dues, debts, cards, a loan at interest, ink.
- **Gangs:** *The Brickhouse Boys, Los Cuervos, The Quiet Men, The Congregation* —
  or protective custody, or no one. Each remembers how you treated its members.
  Joining, doing favours, being ordered to hurt someone, being promoted, leaving
  (it costs).
- **Programmes:** diploma, correspondence degree, trade certificate, counselling,
  faith group, substance programme, anger management. Every one is a line the
  parole board reads.
- **Parole:** from your eligibility year a hearing is due annually. **The Parole
  Board** is a minigame of tone: each question is listened to for one thing —
  remorse, evidence, or a plan — and the panel's face tells you which.
- **The innocent-prisoner arc:** an appeal gauge, a lawyer who stops returning
  calls, the library's law books, a witness who recants, a DNA test, a hearing.
- **Solitary, shakedowns, fights, informing.** Informing buys conduct and costs
  respect.
- **The plan.** A multi-stage jailbreak built on the intel you gather (*listening →
  tools → a crew → an inside man → the right night*), with betrayal built in —
  every person who knows is a way for it to go wrong. On the night the break is
  three minigames in a row (the lock, the yard, the fence). If it works there is a
  **manhunt** with its own menu and events: lie low, a new identity, cash-in-hand
  work, a message to your family (heat up a lot), move on, turn yourself in. Five
  clean years and you are a ghost.

### Guard

Six stories — **a steady career, ex-military, needed the job, an idealist, a prison
family, from the neighbourhood** — and a rank ladder: *recruit → officer → senior
officer → sergeant → lieutenant → captain → deputy warden → warden*, with merit,
control of your wing, integrity, a union, Internal Affairs' interest in you and the
trauma the job puts on you.

- **On shift:** rounds, **a cell search** (a minigame of clues: a glued seam, a
  weight that's wrong), a use-of-force decision that follows you to an inquiry,
  paperwork, overtime, a proper break, ordering a lockdown.
- **The wing:** know the inmates and they know you. An inmate you treated fairly is
  the one who warns you.
- **The keys:** a favour, an envelope on the passenger seat, a ring of officers who
  would like you in, a colleague to cover for, a report to make, a whistle to blow.
- **The set pieces:** a **riot** from the officer's side (the line, the control
  room, the cut-off wing) and the **hostage** situation, which you resolve with
  **Talk Him Down**, a minigame: he says one thing each turn and it tells you what
  he needs — to be heard, given a reason, or offered something.
- **The oldest story the building has.** If Internal Affairs finds a ledger in your
  handwriting you are tried, convicted, and sent to **Block A of the building you
  used to guard.** You continue as a prisoner — with every gang against you and an
  officer on the door who remembers your badge number.

### Shared mechanics

- **Group reputation.** Each gang has a standing with you, remembers what you did to
  its members, and acts on it.
- **Information as a resource.** Intel — a patrol time, a blind spot, a weak
  officer, a gap in a timeline — is collected from the yard, from officers, from
  other inmates; used for a plan, an appeal, a deal; and can be traded or sat on.
- **Set pieces.** The riot (six chained events for the prisoner, five for the
  guard), the hostage, the break and the manhunt. Several systems at once, not one
  popup.
- **Someone else's perspective.** You cannot make the building do anything. You can
  only change what it thinks of you.

### Three new minigames (bots in the gate)

| Game | What it is |
| --- | --- |
| The Parole Board | Five questions; give the answer the panel is waiting for (own it / show evidence / give the plan) |
| Cell Search | Twelve items, three are wrong, and the descriptions give them away |
| Talk Him Down | Eight turns; match listen / reason / offer to what he says |

(The break reuses the existing Safecracker, Infiltration and Prison Break games;
appeals use the Evidence Board; trading uses Negotiation; yard promotions use Fight
Night.)

### Two roads, fifteen endings

**The prisoner's road** has five chapters — *Fresh fish · Whose side? · Something to
hope for · The test of the walls · The door* — and endings **Exonerated · A Ghost ·
The Other Side of the Door · Paroled · Every Day of It · Old Head · Never Out.**

**The guard's road** — *Probation · The first incident · What kind of officer ·
Stripes · The long shift* — and endings **Warden · Whistleblower · The Man With the
Keys · Hero of the Wing · Dismissed · Burned Out · Thirty Years · In the Line of
Duty.** All are written into the life story, the tombstone and the ribbon.

When a story closes the screen reads **Case closed**, not Death — the sentence is
served, the board agreed, the wall was cleared, the career ended — with an
epilogue ("The gate opened at 7.40 on a Tuesday, with a clear plastic bag and a
travel warrant…").

### Content

- **120 events**, 362 choices, 725 outcomes. Every event has three or more choices;
  every choice, two or more outcomes. 34% lead to a delayed follow-up.
- **45 achievements** (a new *Prison Life* category), judged only in the matching
  role; a hidden *Both Sides of the Door* for having lived each.

## Under the hood

- `Lives.mode()` gives the main screen one interface for any separate mode (tabs,
  quick buttons, gauges, header, side notes, end-of-life card). Pets now uses it
  too; a third mode is a new autoload and a new tab list.
- Event outcomes can chain (`then`) into a step of a set piece, and can play a
  minigame and branch on win/lose (`pr_branch`).
- `tools/content/gen_prison*.py` and `gen_prison_achievements.py` regenerate the
  content.

## Checked, and not

- **Checked:** the library (depth, tags, roles, chains, branches, follow-ups); that
  every person an event names exists for the role it's written for; isolation in
  every direction (humans, pets, prisoners and guards each see only their own
  events); 78 whole lives across every story in both roles; every menu action;
  both roads and all 15 endings with ribbons and epitaphs; 40 attempted breaks and
  the manhunts that follow; the guard-to-prisoner switch; save/load; both roles
  through the real screen; the three minigames with bots; title-screen layout.
- **Not checked:** nothing in this mode has been played on real Windows or macOS
  hardware. A hundred lives is a simulation, not a player; whether the building
  *feels* like one is a matter of taste that a gate cannot judge.
- **A deliberate limit:** the prison world is fictional — the facilities, gangs and
  officers are invented, not drawn from any real institution or group.

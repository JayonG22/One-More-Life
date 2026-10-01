# ONE MORE LIFE — v0.16.0 "Work and Body"

Verified in Godot 4.4.1 (`tools/v16_system_test.tscn`). Every earlier gate still passes.

The two systems that had a bar where they should have had a life.

---

## Work

**A job market (`Market`).** Each year's openings are specific: a named employer,
a salary somewhere inside a band, a number of other applicants, the experience
they want, whether it is remote, a boss and a culture you will only fully learn
once you are inside. Your odds are shown with the reasons behind them: smarts,
experience in that field, interview practice, a reference you can use, a gap on
your CV, your record, and how crowded the field is.

**Getting hired.** A screening (most applications never reach a human), then an
interview, then an offer you can accept, decline, or *negotiate* — the
Negotiation minigame. Every rejection teaches you a little: interview practice
accumulates, and rejections come with the kind of reasons real rejections have.

**Being there (`Workplace`).** A manager with a temperament (supportive,
micromanager, hands-off, brilliant, political), a culture (friendly, cutthroat,
sleepy, chaotic), and colleagues with roles — mentor, gossip, rival, ally,
slacker, climber — who each do what their role says. The company has a health
that can turn: hiring freezes, restructures, redundancy with severance (doubled
and less likely with a union). Office politics, a union you can join, lunch with
a colleague, and a resignation that leaves on good terms and takes a reference
with it.

**Leaving.** Retraining in another field, freelancing (variable income, late
payers, your own tax), and the CV gap that unemployment leaves.

## Body

**Care is a pathway (`Care`).** Real care has stages and each can fail. A GP who
may take you seriously or not; a referral; a waiting list whose length depends on
what kind of country you live in (none in a private system, up to two years in a
public one); a specialist who is usually right and occasionally confidently wrong;
a second opinion when they are; paying to skip the queue.

**Conditions that persist.** Medication you have to keep taking — skipping it has
a price that arrives late. Physiotherapy for injuries. Eyesight that fades and can
be corrected with glasses, contacts or surgery. Teeth that need a dentist and
eventually dentures. Hearing that goes and can be helped.

**Things that compound (`Body`).** Four slow accounts — movement, sleep, diet and
excess — are paid into every year and cash out decades later. In the gate, thirty
years of good habits ends at health 93 against 67 for thirty years of neglect.
Turning forty, sixty and eighty each leave a mark, and falls at seventy-plus
depend on how strong you stayed.

**26 new events** cover all of the above, again with three choices and two or
more outcomes per choice.

## Tests

`v16_system_test`: 214 checks. Among them: a micromanager costs more stress than a
supportive boss (3.2 vs -1.2 a year); a company at 5% health makes people
redundant and pays severance; free-lance income varies; a misdiagnosis can be
corrected by a second opinion; medication helps (+0.9 vs -1.2 health a year);
thirty years of lifestyle separates two lives.

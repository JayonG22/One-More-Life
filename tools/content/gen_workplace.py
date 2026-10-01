#!/usr/bin/env python3
"""Generates data/events/workplace.json — the working life, tied to the review, the
economy and the people (v0.21). Every event needs a job (`employed`)."""
import json, os
EV = []
def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    return o
def C(label, *outs, requires=None):
    assert len(outs) >= 2, label
    c = {"label": label, "outcomes": list(outs)}
    if requires: c["requires"] = requires
    return c
def E(id, icon, title, text, cond, *choices, roles=None, cooldown=10, once=False, weight=1.0):
    assert len(choices) >= 3, id
    c = {"age": [17, 68], "employed": True}
    c.update(cond)
    d = {"id": "wk." + id, "icon": icon, "title": title, "text": text, "conditions": c, "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if roles: d["roles"] = roles
    if once: d["once"] = True
    EV.append(d)

BOSS = {"boss": {"relation": "boss"}}
COW = {"co": {"relation": "coworker"}}

E("pip_meeting", "📋", "A quiet word",
  "{boss.first} has asked you into the small meeting room, the one with the glass wall and no window. There is a folder on the table with your name on it.",
  {"max_stat": {"happiness": 55}},
  C("Listen, and ask what good looks like",
    O("{boss.first} had expected a fight. Instead we wrote three goals on one page. It felt like the first adult conversation we'd had.", {"stress": 3, "job_perf": 6}, relationship={"boss": 6}),
    O("I took notes. I asked for a date to review it. {boss.first} nodded slowly, as if recalibrating.", {"stress": 4, "job_perf": 5}, relationship={"boss": 4})),
  C("Push back on the figures",
    O("I came with my own numbers. Some were right. {boss.first} adjusted one thing and left the rest standing.", {"stress": 5, "job_perf": 2}, relationship={"boss": -2}),
    O("It turned into an argument. {boss.first} went quiet in a way I did not like.", {"stress": 8, "job_perf": -3}, relationship={"boss": -8})),
  C("Look at other jobs that night",
    O("I updated the CV before I got home. It was the most productive evening I'd had in months.", {"stress": 2, "smarts": 1}),
    O("I applied to six places and heard back from one. It was a start.", {"stress": 3})),
  roles=BOSS, cooldown=15)

E("layoff_rumour", "📉", "The rumour",
  "It starts in the kitchen. Someone's friend in finance has seen a spreadsheet with a column headed 'headcount'. By lunch half the floor knows, and nobody has said the word.",
  {"world": "recession"},
  C("Ask {boss.first} directly",
    O("{boss.first} said nothing was decided, in the voice of someone for whom it was. At least I knew where I stood.", {"stress": 6}, relationship={"boss": 2}),
    O("{boss.first} told me, off the record, that my role was safe for now. I believed it more than I should have.", {"stress": -2}, relationship={"boss": 5})),
  C("Quietly start looking",
    O("Three interviews in a fortnight. When the announcement came I already had an offer in my pocket.", {"stress": 4, "money": 0, "smarts": 1}),
    O("Everyone else was looking too. The market was thin. I was glad I had started early.", {"stress": 6})),
  C("Keep my head down and work",
    O("I stayed late for a month and said nothing. I wasn't on the list. I don't know if that was why.", {"stress": 8, "job_perf": 4}),
    O("It didn't help. A good quarter doesn't outweigh a bad spreadsheet.", {"stress": 9, "job_perf": 2})),
  roles=BOSS, cooldown=12)

E("credit_taken", "🎭", "Your idea, their slide",
  "The deck is on the big screen and slide four is your idea. It has {co.first}'s name under it.",
  {},
  C("Say so, in the meeting",
    O("The room went quiet. {boss.first} asked for the draft history. It had my name on it. I was right and slightly sick about it.", {"stress": 6, "job_perf": 4}, relationship={"co": -12}),
    O("I said, 'I'm glad that landed.' Everybody understood. {co.first} did not look up for the rest of the hour.", {"stress": 4, "job_perf": 3}, relationship={"co": -8})),
  C("Raise it privately with {co.first}",
    O("{co.first} apologised and meant it, mostly. The next deck had my name where it belonged.", {"stress": 3}, relationship={"co": 5}),
    O("{co.first} said they'd 'misremembered'. It was a lie we both agreed to accept.", {"stress": 4}, relationship={"co": -3})),
  C("Let it go, and keep better records",
    O("From then on everything I wrote was dated and sent to the whole team. It worked. It also felt a little joyless.", {"stress": 2, "smarts": 1}),
    O("I let it go. I did not forget it. The next time it happened I was ready.", {"stress": 3, "karma": -1})),
  roles=COW, cooldown=14)

E("promotion_party", "🥂", "Drinks on the firm",
  "A promotion lands and so does the invitation: Thursday, the bar by the station, everybody expected. People who haven't spoken to you in a year are suddenly delighted.",
  {"min_stat": {"happiness": 40}},
  C("Go and buy a round",
    O("I stood the first round and made a short speech I'd rehearsed in the shower. It went down well. The bill did not.", {"happiness": 6, "money": -140}, relationship={"co": 5}),
    O("A good night. Somebody told me, in confidence, what the last person in the job had been paid. I'm glad I know.", {"happiness": 5, "money": -90, "smarts": 1}, relationship={"co": 4})),
  C("Go for an hour",
    O("One drink, one toast, one exit before the singing. Exactly right.", {"happiness": 3, "money": -30}),
    O("I left early and was told I was 'quiet now you're senior'. I wasn't, I was tired.", {"happiness": 1, "money": -25})),
  C("Skip it",
    O("I went home. The next morning I heard everything I'd missed, and some of it was about me.", {"happiness": -1}, relationship={"co": -4}),
    O("I had the evening to myself. It was lovely, and cost me a little capital I didn't know I'd spent.", {"happiness": 3}, relationship={"co": -2})),
  roles=COW, cooldown=12)

E("strike_vote", "✊", "The vote",
  "The union has called a vote on action over pay and conditions. The leaflet in your pigeonhole says every voice matters. The notice on the wall says the opposite.",
  {"traits_any": ["Loyal", "Hothead", "Ambitious", "Lazy", "Charmer", "Funny", "Anxious", "Honest"]},
  C("Vote to strike",
    O("The stoppage lasted nine days. We won most of it. The first payslip afterwards was lighter than I'd like and the mood on the floor was electric.", {"happiness": 4, "money": -250, "job_perf": -2}),
    O("It dragged to three weeks and ended in a fudge. I'm proud of it and I'm still paying it off.", {"happiness": 2, "money": -600, "stress": 6})),
  C("Vote against",
    O("The motion carried without me. People remembered who had voted which way, quietly, for a long time.", {"stress": 4}, relationship={"co": -5}),
    O("The strike failed to get a majority. I'd like to think I helped. A few colleagues stopped saying hello.", {"stress": 3, "job_perf": 2}, relationship={"co": -7})),
  C("Abstain, and stay out of it",
    O("Nobody could blame me for either. Nobody could thank me either.", {"stress": 1}),
    O("I took the day as leave. The picket line was all anyone talked about on my return.", {"stress": 2, "money": -80})),
  roles=COW, cooldown=25)

E("remote_offer", "🏠", "Working from home",
  "Management has announced a hybrid policy, two days in the office, three at home, 'subject to review'. Your commute looks different tonight.",
  {"era_year_min": 2012},
  C("Take every home day going",
    O("No commute, no small talk, and by March I had a routine I loved and a face the team hardly recognised.", {"happiness": 4, "stress": -4, "job_perf": -1}),
    O("I got more done than I ever had, at the kitchen table, in a jumper. The team noticed. So did the boss.", {"happiness": 3, "stress": -3, "job_perf": 5})),
  C("Go in more than I have to",
    O("The office was empty and I enjoyed it. I was seen, which in practice counts for something.", {"stress": 1, "job_perf": 4}),
    O("I kept up the old routine. It was good for the friendships and bad for the budget.", {"stress": 2, "money": -60}, ),),
  C("Argue for four days at home",
    O("They said no, politely. I got a cushion on my chair and a half-day on Fridays.", {"stress": 2}),
    O("They said yes to a trial. I made it work. Three of my colleagues asked how.", {"happiness": 4, "job_perf": 3})),
  cooldown=40, once=True)

E("training_budget", "🎓", "A training budget",
  "HR has sent a note: everyone has money to spend on 'development' before the end of the quarter. Nobody is quite sure how.",
  {},
  C("A proper course",
    O("Six evenings over eight weeks and a certificate. I learned more than I expected and it showed in March.", {"smarts": 3, "job_perf": 5, "stress": 3}),
    O("The course was dull but the person next to me knew someone. A job interview followed.", {"smarts": 2, "job_perf": 2}, relationship={})),
  C("A conference",
    O("Two days, fourteen badges, and one conversation that mattered. I flew home with a plan.", {"happiness": 4, "smarts": 1, "money": 0, "job_perf": 3}),
    O("I spent most of it in the hotel bar. Nobody asked what I'd learned, which was lucky.", {"happiness": 3, "job_perf": -1})),
  C("Spend it on books and tools",
    O("A shelf of books and a good chair. The chair did more for my work than the books.", {"smarts": 2, "stress": -2, "job_perf": 2}),
    O("I bought a very good monitor. I am not ashamed.", {"stress": -1, "job_perf": 3})),
  cooldown=10)

E("mentor_offer", "🧭", "Someone takes an interest",
  "A senior person, who has never said more to you than hello in the lift, asks if you'd like a coffee. 'Nothing formal,' they say. It sounds formal.",
  {"min_stat": {"smarts": 40}},
  C("Say yes",
    O("It turned into a monthly habit. They told me the unwritten rules of the place, and one or two of the written ones.", {"smarts": 2, "job_perf": 5, "happiness": 3}),
    O("It was awkward for the first few meetings and enormously useful for the next fifty.", {"smarts": 2, "job_perf": 4})),
  C("Ask what they want from it",
    O("They laughed. 'To see someone do it better than I did.' I thought about that for a long time.", {"happiness": 3, "job_perf": 3}),
    O("They wanted a favour, eventually. A small one. It was still a favour.", {"stress": 2, "job_perf": 3, "karma": -1})),
  C("Decline politely",
    O("They nodded and said the door was open. It is never as open the second time.", {"stress": 1}),
    O("I was too busy. I was always too busy.", {"stress": 2, "job_perf": -1})),
  cooldown=40, once=True)

E("burnout_signs", "🕯️", "Sunday dread",
  "It starts on Sunday afternoon now: a tightness in the chest, a list that grows while you look at it. Last week you cried in the stationery cupboard and told no one.",
  {"min_stat": {"stress": 60}},
  C("Talk to {boss.first}",
    O("{boss.first} did something I hadn't expected: listened, took two projects off me and sent me home early. I felt guilty and slept for ten hours.", {"stress": -12, "happiness": 4}, relationship={"boss": 6}),
    O("{boss.first} said all the right words and changed nothing. At least I'd said it aloud.", {"stress": -3}, relationship={"boss": -2})),
  C("Take real leave",
    O("Two weeks, no email. By day five I was bored. By day ten I was myself.", {"stress": -18, "happiness": 6, "job_perf": -2}),
    O("The leave was approved and ruined by a handover that wouldn't stay handed over.", {"stress": -6, "job_perf": -1})),
  C("Push through",
    O("I pushed through. The work held up, and a few months later, something else did not.", {"stress": 6, "health": -4, "job_perf": 3}),
    O("It got worse. I was lucky someone noticed before I did anything I'd regret.", {"stress": 8, "health": -3, "happiness": -4})),
  roles=BOSS, cooldown=12)

E("office_romance", "💘", "Across the open plan",
  "The person from the other team keeps appearing at the printer when you do. Their laugh carries. Everyone has noticed, which makes noticing impossible.",
  {"age": [20, 55]},
  C("Ask them to lunch",
    O("A very ordinary lunch and a very good afternoon. We agreed to keep it quiet; it lasted about a week.", {"happiness": 6, "stress": 2}),
    O("They said yes, then no, then yes. By the time it settled I was invested.", {"happiness": 4, "stress": 4})),
  C("Keep it professional",
    O("We remained very good colleagues. Years later I'd think about that.", {"stress": -1}),
    O("I played it safe. They moved to another office six months later and the printer was quiet.", {"happiness": -2})),
  C("Check the policy first",
    O("There was a form. There was always a form. We filled it in together and laughed at question six.", {"happiness": 3, "smarts": 1}),
    O("The policy was clear. It would have meant one of us leaving. We were both sensible, and a little sad.", {"happiness": -1})),
  cooldown=25)

E("relocation", "📦", "A move for the job",
  "The firm is closing your office. Two options: a transfer to the head office four hundred miles away, or a redundancy package with some strings in it.",
  {"world": "recession"},
  C("Take the transfer",
    O("A new city, a new flat, a team that did not know me. The first six months were hard. After that it started to feel like mine.", {"stress": 6, "happiness": 2, "job_perf": 3, "money": -600}),
    O("I hated it for a year and loved it for ten. I'm glad I went.", {"stress": 7, "happiness": 1, "job_perf": 4, "money": -600})),
  C("Take the package",
    O("The money gave me a year to think. I thought about it a lot, and I spent it carefully.", {"stress": 4, "money": 6000}),
    O("The package was less than they'd implied. It paid for two months. The rest I did myself.", {"stress": 8, "money": 2500})),
  C("Push for remote work",
    O("They said they'd consider it. Eight weeks later they said yes, on a trial basis. I was the only one in the building who still had a desk at home.", {"stress": 2, "job_perf": 2}),
    O("The answer was no. I'd lost two months to asking.", {"stress": 5})),
  cooldown=30)

E("side_hustle_work", "🔧", "A little something on the side",
  "A friend needs a thing done that is half your job and half a favour. The pay is cash. The contract says you can't take outside work.",
  {},
  C("Do it, quietly",
    O("It was easy money and a small thrill. Nobody ever found out. I did it again twice.", {"money": 800, "happiness": 3, "stress": 2}),
    O("My manager found out two months later. 'We'll say no more about it,' she said, which meant plenty.", {"money": 800, "stress": 6, "job_perf": -5}),),
  C("Ask permission first",
    O("They said yes, with conditions, and a nod. I liked the honesty and I liked the money.", {"money": 600, "stress": 1, "job_perf": 1}),
    O("They said no, and thanked me for asking. My friend found someone else.", {"stress": 1})),
  C("Refuse",
    O("My friend sulked. Years later it came up and we both laughed.", {"stress": 1, "karma": 1}),
    O("I felt like a saint and a mug in equal parts.", {"stress": 2})),
  cooldown=15)

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "workplace.json")
json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
print("workplace.json: %d events" % len(EV))

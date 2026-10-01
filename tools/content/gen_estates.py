#!/usr/bin/env python3
"""Generates data/events/estates.json — the family acts on its own: wills, disputes,
people who move abroad or rise, and what that does to you (v0.21)."""
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
def E(id, icon, title, text, cond, *choices, roles=None, cooldown=12, once=False):
    assert len(choices) >= 3, id
    c = {"age": [24, 90]}
    c.update(cond)
    d = {"id": "es." + id, "icon": icon, "title": title, "text": text, "conditions": c, "choices": list(choices), "weight": 1.0, "cooldown": cooldown}
    if roles: d["roles"] = roles
    if once: d["once"] = True
    EV.append(d)

SIB = {"sib": {"relation": "sibling"}}
KID = {"kid": {"relation": "child"}}
PAR = {"par": {"relation": "partner"}}
MOM = {"mom": {"relation": "mother"}}

E("will_dispute", "📜", "The will",
  "The solicitor reads it twice. The house goes to {sib.first}, the savings are split, and a clause nobody expected leaves your late mother's jewellery 'to whoever looked after her'. {sib.first} is already looking at you.",
  {"min_net_worth": 1000, "age": [28, 85]},
  C("Contest it",
    O("It took fourteen months and a lot of money. I won a little, lost a good deal and gained a sister or brother I do not speak to.", {"stress": 10, "money": -3500, "happiness": -4}, relationship={"sib": -25}),
    O("We settled outside court on a Tuesday, over tea nobody drank. It was fair. It did not feel fair.", {"stress": 6, "money": -900}, relationship={"sib": -10})),
  C("Let {sib.first} have the house",
    O("{sib.first} cried in the kitchen. They said they'd never forget it. They did not forget it, in a good way.", {"happiness": 3, "stress": -2, "karma": 6}, relationship={"sib": 18}),
    O("I let it go and kept the jewellery. It felt like something I could carry.", {"happiness": 2, "karma": 3}, relationship={"sib": 8})),
  C("Propose a split",
    O("We drew up a list on the back of an envelope. By the end of the afternoon it was nearly civil.", {"stress": 3, "karma": 2}, relationship={"sib": 5}),
    O("They said yes, and then no, and then their solicitor wrote to mine.", {"stress": 8, "money": -600}, relationship={"sib": -6})),
  roles=SIB, cooldown=40, once=True)

E("sibling_abroad", "✈️", "Moving abroad",
  "{sib.first} has taken a job in another country: a good one, the sort of offer you do not ignore. They are going in six weeks, and they have asked you to help pack.",
  {"age": [24, 70]},
  C("Help them move, and promise to visit",
    O("I spent a weekend wrapping plates. At the airport we both pretended we weren't crying. I did visit, twice.", {"happiness": 2, "stress": 3, "money": -200}, relationship={"sib": 8}),
    O("A tearful goodbye and a lot of video calls after. We stayed closer than I'd feared.", {"happiness": 1, "stress": 2}, relationship={"sib": 6})),
  C("Ask them to stay",
    O("They stayed for another year. Then went anyway, a little colder.", {"stress": 4, "happiness": -2}, relationship={"sib": -8}),
    O("They said it was the best thing that would ever happen to them. I felt small for asking.", {"stress": 3, "happiness": -3}, relationship={"sib": -4})),
  C("Wish them well and let it be",
    O("Our messages thinned out. I still send a card at the holidays.", {"happiness": -1}, relationship={"sib": -5}),
    O("I was too busy to see them off. I regretted it for a while.", {"happiness": -2, "stress": 2}, relationship={"sib": -7})),
  roles=SIB, cooldown=25, once=True)

E("child_emigrates", "🛫", "Our child is leaving",
  "{kid.first} has announced, over a perfectly ordinary dinner, that they've taken a position overseas. They have already booked the flight. They have already told their friends.",
  {"age": [40, 85]},
  C("Be proud, and say so",
    O("{kid.first} hugged me for a long time. 'I was afraid you'd stop me.' I almost did.", {"happiness": 4, "stress": 3}, relationship={"kid": 10}),
    O("I toasted them at dinner. It was the best speech I ever gave, mostly because I meant it.", {"happiness": 3, "stress": 2}, relationship={"kid": 8})),
  C("Tell them how much you'll miss them",
    O("Honest and quiet. They said they'd phone every Sunday. They did, mostly.", {"happiness": 1, "stress": 3}, relationship={"kid": 5}),
    O("It came out as guilt. They left anyway, with the guilt.", {"stress": 5}, relationship={"kid": -6})),
  C("Offer money to help them settle",
    O("I sent a sum I could ill afford. They never asked for more, which is how I knew it mattered.", {"money": -1500, "happiness": 3}, relationship={"kid": 12}),
    O("I sent what I could. The note I wrote with it did more than the money.", {"money": -500, "happiness": 2}, relationship={"kid": 7})),
  roles=KID, cooldown=30, once=True)

E("partner_offer_abroad", "🧳", "A job in another country",
  "{par.first} has been offered something huge, three time zones away. They haven't said yes. They haven't said no. They put the letter on the table between you and went to make tea.",
  {"age": [25, 60], "has_partner": True},
  C("Go with them",
    O("We sold the sofa, kept the dog, and landed in January in a flat with no heating. It was one of the best things we ever did.", {"happiness": 4, "stress": 6, "money": -1800}, relationship={"par": 14}),
    O("I followed them. The first year I was lonely. The second I found my own life there.", {"happiness": 2, "stress": 7, "money": -1800}, relationship={"par": 10})),
  C("Ask them to turn it down",
    O("They did. We never said another word about it. It sat in the kitchen like a third person for years.", {"happiness": -3, "stress": 4}, relationship={"par": -10}),
    O("They refused it and resented it quietly. I didn't notice at the time.", {"happiness": -2, "stress": 3}, relationship={"par": -6})),
  C("Try a long-distance year",
    O("It was harder than the brochure. We saw each other six times. We survived, barely.", {"stress": 8, "happiness": -2, "money": -1200}, relationship={"par": 2}),
    O("A year of video calls and holidays. Then one of us went home.", {"stress": 6, "money": -1000}, relationship={"par": -4})),
  roles=PAR, cooldown=40, once=True)

E("family_business_row", "🏭", "Who takes over",
  "{sib.first} and you have both been in the family firm for years. Your father hasn't named a successor. Last night he said the name out loud at dinner, and it was not yours.",
  {"age": [30, 70], "has_business": True},
  C("Challenge the decision",
    O("It split the family for a decade. I got a buy-out and a lifelong silence.", {"stress": 10, "money": 8000, "happiness": -4}, relationship={"sib": -25}),
    O("We went to mediation, which is a word that sounds gentler than it was. We both left with half of what we wanted.", {"stress": 6, "money": 3000}, relationship={"sib": -8})),
  C("Back {sib.first}",
    O("I gave the speech at the handover. It cost me, and it was the right thing.", {"happiness": 2, "stress": 3, "karma": 5}, relationship={"sib": 15}),
    O("I backed {sib.first} and was quietly made a director. A good outcome I didn't expect.", {"happiness": 3, "karma": 3}, relationship={"sib": 10})),
  C("Leave and start something of my own",
    O("It was the hardest year of my life, and then it wasn't. I did not look back.", {"stress": 8, "money": -2500, "happiness": 4}),
    O("It took three attempts. By the third I knew exactly what I was doing.", {"stress": 9, "money": -3500, "smarts": 2})),
  roles=SIB, cooldown=40, once=True)

E("parent_remarries", "💍", "Mum has news",
  "{mom.first} asks you to come over, because she has something to tell you. She's smiling too hard. A stranger's coat is on the hook.",
  {"age": [30, 70]},
  C("Be warm about it",
    O("I hugged them both. He turned out to be kind and a little boring, which she said was exactly the point.", {"happiness": 4, "stress": -2}, relationship={"mom": 10}),
    O("We had a long dinner, and the next week I came back with flowers.", {"happiness": 3}, relationship={"mom": 8})),
  C("Worry about the inheritance",
    O("I said nothing aloud, but I asked a solicitor a quiet question. {mom.first} found out and did not speak to me for a month.", {"stress": 4, "karma": -3}, relationship={"mom": -14}),
    O("I raised it as delicately as I could. It was not delicate enough.", {"stress": 5}, relationship={"mom": -8})),
  C("Take time to adjust",
    O("It took a year. By the end I liked him, which surprised us both.", {"stress": 2, "happiness": 2}, relationship={"mom": 3}),
    O("I kept my distance for too long. She noticed. So did he.", {"stress": 3, "happiness": -2}, relationship={"mom": -6})),
  roles=MOM, cooldown=40, once=True)

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "estates.json")
json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
print("estates.json: %d events" % len(EV))

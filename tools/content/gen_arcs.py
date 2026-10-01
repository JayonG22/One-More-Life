#!/usr/bin/env python3
"""Generates data/events/arcs.json — the turning-point event for every chapter
of every life-path arc. Each has three choices and every choice 2+ outcomes."""
import json
EV = []

def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    return o

def C(label, *outs):
    assert len(outs) >= 2, label
    return {"label": label, "outcomes": list(outs)}

def E(path, n, icon, title, text, *choices):
    assert len(choices) == 3
    EV.append({"id": "arc.%s.%d" % (path, n), "icon": icon, "title": title, "text": text,
               "conditions": {"age": [0, 130], "life": path}, "choices": list(choices),
               "weight": 1, "followup_only": True})

# ------------------------------------------------------------------ pirate
E("pirate", 1, "⚔️", "The first ship",
  "A merchant brig {~is hull-down on the horizon|has run up her colours and nothing else|is sitting heavy and low in the water}. Your crew is watching you, not her.",
  C("Take her by boarding",
    O("It was loud and quick and I didn't hear any of it afterwards. We took her with two wounded and a ship's cat.", {"happiness": 5, "stress": 6, "money": 8000}, arc={"morale": 8, "bounty": 6}),
    O("The brig's crew fought harder than their cargo deserved. We won, but I counted names that evening.", {"happiness": -2, "stress": 10, "money": 5000}, arc={"morale": -6, "bounty": 8})),
  C("Fire a warning gun and let her surrender",
    O("She struck her colours at once. The captain handed over the manifest with a face I'll remember.", {"happiness": 3, "karma": 2, "money": 4000}, arc={"morale": 5, "bounty": 3}),
    O("She ran, and we lost the wind and the day. The crew called it cowardice, quietly.", {"stress": 4}, arc={"morale": -8})),
  C("Let her go",
    O("The crew muttered. At dusk the lookout spotted a warship on her course, and I was thanked in a way I didn't expect.", {"karma": 4, "happiness": 2}, arc={"morale": 4}),
    O("It was the right call and the crew never forgave it. A week later someone left a rope in my cabin.", {"karma": 3, "stress": 6}, arc={"morale": -12})))

E("pirate", 2, "📜", "The poster",
  "In {~a harbour you haven't touched in a year|a port you thought you'd never need|a tavern nobody should have recognised you in}, there is a poster with {~your face on it, drawn by someone who'd only heard about you|a price, a description and a spelling of your name that's almost right}.",
  C("Laugh and keep your hat low",
    O("It became a joke aboard. They drew moustaches on the copies we stole.", {"happiness": 5}, arc={"morale": 6}),
    O("A boy recognised me and followed us to the quay. I paid him to forget, and he took the money.", {"money": -300, "stress": 5}, arc={"bounty": 6})),
  C("Tear them all down",
    O("I went from wall to wall in the dark. By morning there wasn't a poster in the port. Nobody asked who.", {"stress": 4, "happiness": 2}, arc={"bounty": -10}),
    O("I was spotted at the third wall. We left that port in a hurry and never went back.", {"stress": 8, "happiness": -3}, arc={"bounty": 10, "hull": -6})),
  C("Add to it",
    O("I sent them a better portrait. The poster has been redrawn with a flattering profile, and the bounty rose to match.", {"fame": 3, "happiness": 6}, arc={"bounty": 20, "morale": 6}),
    O("The new poster flattered my enemies more than me, and the bounty rose for a reason I didn't want.", {"fame": 2, "stress": 6}, arc={"bounty": 18})))

E("pirate", 3, "🗺️", "The map",
  "The second map {~is stained with something you decide not to identify|has a corner torn off and an X in the wrong ocean|is the first one that isn't a fake}. Your quartermaster has opinions about it.",
  C("Follow it to the end",
    O("We found the island, and the chest, and a better reason to come back. It paid for the ship twice.", {"money": 25000, "happiness": 8}, arc={"treasure": 25000, "morale": 8}),
    O("The island was real. So was the guard somebody had left on it. We left with a third of the chest and a limp.", {"money": 8000, "health": -4, "stress": 6}, arc={"treasure": 8000, "hull": -10})),
  C("Sell it to the highest bidder",
    O("A rival paid in gold, and we spent three months wondering if it was the right call.", {"money": 12000}, arc={"treasure": 12000, "morale": -4}),
    O("The buyer disappeared with the map and a few of our best sailors. A bad bargain.", {"money": 4000, "stress": 6}, arc={"treasure": 4000, "morale": -10})),
  C("Burn it",
    O("It felt like freedom for about an hour. Then the crew noticed what I'd done.", {"happiness": -2, "karma": 1}, arc={"morale": -10}),
    O("The ash on the water looked like a very small continent. We sailed on and nobody mentioned it again.", {"stress": -2, "happiness": 2}, arc={"morale": -2})))

E("pirate", 4, "⚓", "A captain's table",
  "You're invited to {~dine with the other captains|a meeting of ships|a truce in a harbour with no flag}. {~Three of them have wanted you dead.|Everyone brought their best manners.}",
  C("Go, and bring gifts",
    O("Three of them left owing me favours. One of them meant it.", {"money": -2000, "happiness": 6, "fame": 3}, arc={"morale": 5, "bounty": -4}),
    O("It was a trap, but a polite one: they wanted a share, and I paid it.", {"money": -6000, "stress": 6}, arc={"bounty": 6})),
  C("Go armed to the teeth",
    O("It was tense and short. Nobody said what they wanted, and everyone remembered I'd come.", {"stress": 4, "fame": 2}, arc={"bounty": 8, "morale": 3}),
    O("A glass was thrown and a pistol drawn. We left with a duel pending and a good story.", {"stress": 8, "fame": 4}, arc={"bounty": 12})),
  C("Send a crewmate in your place",
    O("They handled it better than I would have. I was reminded who had my back.", {"karma": 2, "happiness": 3}, arc={"morale": 8}),
    O("They were insulted by an empty chair. It took a gift to apologise.", {"money": -1500, "stress": 3}, arc={"morale": -3})))

E("pirate", 5, "🌊", "What the song says",
  "The song {~about your ship|that the harbours sing|that a stranger started singing in a tavern} has a verse that isn't true. {~It's the best verse.|Everyone knows it by heart.}",
  C("Let the verse stand",
    O("A legend is built out of better material than facts. I let it grow.", {"fame": 6, "happiness": 7}, arc={"morale": 5}),
    O("A younger crew tried to live up to the verse. Two of them died doing it.", {"fame": 5, "karma": -6, "stress": 8}, arc={"morale": -4})),
  C("Correct the record",
    O("I told the true story at the next port. It was less popular and more memorable.", {"karma": 4, "happiness": 4, "fame": 2}),
    O("Nobody wanted the real version. They rewrote the verse with my correction as the joke.", {"happiness": -2, "fame": 1})),
  C("Write the next verse yourself",
    O("I wrote the next verse and it stuck. That's the kind of immortality you can plan for.", {"fame": 5, "happiness": 7}, arc={"morale": 6}),
    O("The new verse was awful and everyone sang it anyway.", {"fame": 3, "happiness": 2}, arc={"morale": 3})))

# ------------------------------------------------------------------ colonist
E("colonist", 1, "🛠️", "The first winter under glass",
  "The seals on {~Hab Three|the east corridor|the greenhouse airlock} are failing at the worst moment. Engineers argue with each other in three languages.",
  C("Take the repair yourself",
    O("Six hours in a suit, and the seal held. They stopped arguing and started thanking me.", {"happiness": 6, "stress": 6, "health": -2}, arc={"oxygen": 6, "influence": 6}),
    O("The patch held for a day. Then it didn't. The proper repair took a week and a crew of eight.", {"stress": 8, "health": -3}, arc={"oxygen": -6, "influence": 2})),
  C("Coordinate from the control room",
    O("I kept eight people on task and nobody got hurt. It isn't glamorous and it was right.", {"happiness": 3, "stress": 4}, arc={"oxygen": 4, "influence": 4}),
    O("The decision I made cost us a night of air. We got through it, and I learned where my limits were.", {"stress": 8, "happiness": -2}, arc={"oxygen": -8, "influence": 2})),
  C("Evacuate the module",
    O("We moved forty people into the dome in an hour. Nobody died. The module was lost.", {"happiness": 2, "karma": 3}, arc={"oxygen": 2, "rations": -4, "influence": 5}),
    O("Panic cost us more than the leak would have. Someone was hurt in the stairwell.", {"stress": 10, "karma": -2}, arc={"morale": -10, "influence": -2})))

E("colonist", 2, "🌌", "Something out there",
  "On the survey, {~a regular pattern in the rock|a pale line that isn't geology|a radio hush that's too regular} shows up on the {~third|fourth|fifth} pass. You are the only one who has looked at it for long.",
  C("Report it at once",
    O("The council gave it a number and a team. The team gave it a name. It was mine.", {"happiness": 6, "fame": 3}, arc={"influence": 6, "contact": 8}),
    O("It was dismissed as noise. A year later someone else reported the same thing and was believed.", {"happiness": -3, "stress": 3}, arc={"influence": -2})),
  C("Keep studying it quietly",
    O("Three more months of data and I had something no one could dismiss.", {"smarts": 2, "stress": 4}, arc={"contact": 12, "influence": 2}),
    O("The more I looked the less I could tell anyone. I was starting to seem odd.", {"stress": 8, "happiness": -3}, arc={"contact": 6, "morale": -4})),
  C("Mark it down as noise",
    O("It was noise. I slept well and was almost disappointed.", {"stress": -2}, arc={"influence": 1}),
    O("It wasn't noise. I'd find that out when it was too late to be first.", {"happiness": -2, "stress": 3}, arc={"contact": -4})))

E("colonist", 3, "🗳️", "The vote",
  "The council is deciding whether to {~spend a season's rations on a new dome|let the greenhouse take the water|send an expedition to the north pole}. The vote is tied. Everyone is looking at you.",
  C("Vote to build",
    O("The dome went up. It stood for a century. I was remembered for the decision, which pleased me.", {"happiness": 6, "karma": 2}, arc={"influence": 10, "habitat": 1, "rations": -8}),
    O("The dome was late, over budget and cold. People forgave it eventually.", {"stress": 6}, arc={"influence": 4, "habitat": 1, "rations": -12})),
  C("Vote to hold",
    O("We kept our reserves. The next dust storm lasted forty days and justified every ration.", {"stress": 2, "happiness": 3}, arc={"influence": 6, "rations": 6}),
    O("The reserves rotted in a bad store. I stood by the vote and it cost me.", {"stress": 5}, arc={"influence": -4, "rations": -4})),
  C("Abstain",
    O("The chair broke the tie. I was irrelevant, which is its own kind of clarity.", {"stress": -1}, arc={"influence": -2}),
    O("The chair broke the tie in a way I'd have voted against. I'd given up the right to complain.", {"happiness": -3}, arc={"influence": -6})))

E("colonist", 4, "📡", "The reply",
  "{~The signal changes|A second signal arrives on the same frequency|The pattern repeats, and then isn't quite the same}. It is, depending on how you squint, an answer.",
  C("Reply in kind",
    O("The next answer came in nine hours. Whatever it was, it was listening.", {"fame": 6, "stress": 8, "happiness": 4}, arc={"contact": 20, "influence": 4}),
    O("We sent something clumsy. The reply was silence, and it has lasted.", {"stress": 6, "happiness": -2}, arc={"contact": 8, "influence": -2})),
  C("Tell Earth first",
    O("Earth took eleven minutes to reply and then a long time to decide. We were told to wait.", {"stress": 5}, arc={"contact": 6, "influence": 4}),
    O("The report leaked, and the colony learned about it from the news feed. I wasn't thanked.", {"stress": 8, "karma": -2}, arc={"contact": 6, "influence": -6})),
  C("Say nothing, and keep listening",
    O("I listened for a year. The pattern changed three times, each time more patient.", {"smarts": 3, "stress": 6}, arc={"contact": 14}),
    O("Someone else noticed what I was hiding. The conversation we had was not a pleasant one.", {"stress": 8, "karma": -3}, arc={"contact": 8, "influence": -6})))

E("colonist", 5, "🏛️", "The founders' wall",
  "They are putting names on the {~wall in the central hall|plaque by the first airlock|stone by the greenhouse}. Yours is being discussed.",
  C("Stand back and let them decide",
    O("They put it up. A child touched it later and asked what a founder was.", {"happiness": 8, "karma": 2}, arc={"influence": 8}),
    O("They argued for a year and put it up, smaller than I'd have liked.", {"happiness": 3}, arc={"influence": 4})),
  C("Ask for a name beside yours",
    O("I put up the name of the first man who died building the colony. It still has fresh flowers.", {"karma": 8, "happiness": 6}, arc={"influence": 8, "morale": 6}),
    O("They agreed, and the other names were tricky. It turned into an argument I regretted starting.", {"karma": 4, "stress": 5}, arc={"influence": 2})),
  C("Refuse the honour",
    O("They put the name up anyway. It's what the colony wanted, and in the end I let it.", {"happiness": 3, "karma": 2}, arc={"influence": 4}),
    O("They left it off. For a few months I liked it that way.", {"happiness": -1}, arc={"influence": -4})))

# ------------------------------------------------------------------ traveler
E("traveler", 1, "🎩", "A shopkeeper who stares",
  "{~A shopkeeper|A landlady|A policeman} has been looking at you for a while. {~Your coat is almost right.|You said a word you shouldn't have.|You paid with coins that were slightly too clean.}",
  C("Smile and ask directions",
    O("They helped me, then told the whole street about the foreigner who was lost. Everyone was kind.", {"happiness": 3}, arc={"cover": 8}),
    O("It worked, and I spent the evening composing a better story.", {"stress": 3}, arc={"cover": 4})),
  C("Leave at once",
    O("I walked out quickly and the shopkeeper wasn't sure. I never went back.", {"stress": 4}, arc={"cover": -2}),
    O("I walked into the wrong street, and into someone I owed a story.", {"stress": 6}, arc={"cover": -6})),
  C("Tell part of the truth",
    O("I said I was from abroad and a little unwell. It explained everything and I became a minor local mystery.", {"happiness": 2}, arc={"cover": 10}),
    O("They believed it too much, and offered to find me a wife, a job and a doctor.", {"stress": 5, "happiness": 1}, arc={"cover": 6})))

E("traveler", 2, "⚡", "The first jump",
  "The device is {~warm|humming|reading a number you've never seen}. You can go to {~a year you know from a book|a day you will regret leaving|somewhere you can't possibly return from}.",
  C("Jump a short way",
    O("A few years. The world looked the same and wasn't. It was the quietest kind of vertigo.", {"stress": 4, "smarts": 1}, arc={"charge": -25, "paradox": 3, "jumps": 0}),
    O("It went wrong in a small way: I landed in a field, three days off. I was found by a farmer.", {"stress": 8}, arc={"charge": -25, "paradox": 6})),
  C("Jump to a day you remember",
    O("I saw someone I loved, from across a street, alive, unaware. I did not speak.", {"happiness": 6, "stress": 8}, arc={"charge": -25, "paradox": 8}),
    O("I did speak. They looked at me the way you look at a stranger, and then at my coat.", {"happiness": -4, "stress": 10}, arc={"charge": -25, "paradox": 14})),
  C("Don't jump",
    O("I put the device in a drawer. It hummed in the drawer for a week.", {"stress": 3}, arc={"cover": 4}),
    O("I sat with it all night. In the morning I knew I'd do it eventually.", {"stress": 4, "smarts": 1}, arc={"cover": 2})))

E("traveler", 3, "🏺", "The collection",
  "A museum {~curator|collector|professor} has noticed the artifacts you document. {~They'd like to see the originals.|They've found a mistake in your catalogue.|They want to buy one.}",
  C("Show them everything",
    O("They wept at the sight of a single button. We became friends, and neither of us said why.", {"happiness": 6, "fame": 2}, arc={"artifacts": 1, "cover": -6}),
    O("They saw something I hadn't. It was a gift, and it was a danger.", {"smarts": 3, "stress": 6}, arc={"artifacts": 1, "cover": -10, "paradox": 5})),
  C("Sell one",
    O("The price was ridiculous and the buyer was thrilled. I felt oddly clean.", {"money": 20000, "happiness": 3}, arc={"artifacts": -1, "paradox": 4}),
    O("It was the wrong one. The buyer asked questions I couldn't answer.", {"money": 12000, "stress": 8}, arc={"artifacts": -1, "paradox": 10, "cover": -8})),
  C("Deny everything",
    O("They never asked again. I was sorry about that.", {"stress": 3, "happiness": -2}, arc={"cover": 6}),
    O("They left it, and I discovered I'd sent a signal anyway.", {"stress": 6}, arc={"cover": -4})))

E("traveler", 4, "🌀", "The tear",
  "A thing you did {~in 1920|last week|somewhere you don't remember} is {~showing up in the wrong newspaper|visible in a photograph where it shouldn't be}. The timeline has noticed.",
  C("Go back and undo it",
    O("It took three attempts, and left a scar on the date. But it held.", {"stress": 10, "health": -2}, arc={"charge": -30, "paradox": -20}),
    O("I made it worse. The photograph changed, and so did the person in it.", {"stress": 14, "happiness": -6}, arc={"charge": -30, "paradox": 14})),
  C("Leave it be",
    O("History absorbed it. It always does, a little more than you'd think.", {"stress": 4}, arc={"paradox": -4}),
    O("History did not absorb it. A small, specific thing was different the next morning.", {"stress": 10, "happiness": -4}, arc={"paradox": 12})),
  C("Make it bigger",
    O("It was an act of aggression against time. Time shrugged.", {"stress": 8, "karma": -4}, arc={"paradox": 25, "cover": -10}),
    O("It was a catastrophe, and a very educational one.", {"stress": 14, "karma": -8, "happiness": -8}, arc={"paradox": 40})))

E("traveler", 5, "🏠", "Which year is home?",
  "Somebody asks you where you're from. For the first time you {~don't know what to say|have a real answer|say a year}.",
  C("Name the year you were born",
    O("It felt like a lie and a truth. I hadn't been that person for a very long time.", {"happiness": -2, "stress": 3}, arc={"home_year": 0}),
    O("It felt like a country I'd left. The person asking nodded as if they understood.", {"happiness": 3}, arc={"cover": 4})),
  C("Name the year you're in",
    O("It's the right answer for a life. I felt like a person for the first time in a long time.", {"happiness": 8, "stress": -4}, arc={"cover": 8, "paradox": -4}),
    O("It was more honest than I'd expected. They told me the date, and I nodded.", {"happiness": 4}, arc={"cover": 6})),
  C("Refuse to say",
    O("They laughed. 'Of course.' They've decided it's a joke, and I let it be one.", {"happiness": 2}, arc={"cover": 3}),
    O("They went quiet. I'd said too much by not saying it.", {"stress": 6}, arc={"cover": -6})))

# ------------------------------------------------------------------ royal
E("royal", 1, "👑", "A place in the line",
  "At dinner, {~someone says the word 'heir' and the table goes quiet|a courtier uses your title for the first time|you realise you've been placed in the order, and you're not first}. {~You can feel everyone counting.|The soup goes cold.}",
  C("Accept your place with grace",
    O("It was easier than I'd feared. A cousin nodded, which meant something.", {"happiness": 4, "karma": 2}, arc={"respect": 5}),
    O("I overdid the grace and was taken for ambition. It took a year to live down.", {"stress": 4}, arc={"respect": -2})),
  C("Ask what it means in practice",
    O("The answer was a stack of binders and a personal secretary. I felt rather important and slightly ill.", {"smarts": 2, "stress": 3}, arc={"respect": 4}),
    O("The courtier laughed and I was handed a diary. Every day for two years had an engagement in it.", {"stress": 6}, arc={"respect": 2})),
  C("Say you don't want it",
    O("It was quietly noted. My mother did not speak to me for a week, then did.", {"happiness": -2, "karma": 3, "stress": 4}, arc={"respect": 4}),
    O("It was reported in the papers. The palace denied it, and everyone knew.", {"stress": 8, "fame": 4}, arc={"respect": -6})))

E("royal", 2, "📜", "The first decree",
  "A document is placed in front of you with {~a ribbon|a pen|a nervous clerk}. {~It's a small matter: a holiday, a street, a name.|It's about a hospital, and you suspect it's about more than that.}",
  C("Sign it as written",
    O("My first act as a decree-maker went into history as a footnote. A hospital got a new wing.", {"happiness": 4, "karma": 3}, arc={"respect": 4}),
    O("It had a clause I hadn't read. The clause was used against someone I liked.", {"karma": -5, "stress": 6}, arc={"respect": -4})),
  C("Rewrite it before signing",
    O("The clerk rewrote it with a look of dread. It came out better. I was told I had a gift for the work.", {"smarts": 2, "happiness": 4}, arc={"respect": 6, "decrees": 0}),
    O("The rewrite offended a minister. I'd made an enemy and a draft.", {"stress": 5}, arc={"respect": 2})),
  C("Ask for a week to think",
    O("A week was too long for politics and exactly right for conscience. I signed on the eighth day.", {"karma": 2, "stress": 3}, arc={"respect": 2}),
    O("The week ran out the decision for me. Someone else had signed in my name.", {"stress": 8, "karma": -2}, arc={"respect": -4})))

E("royal", 3, "🕯️", "The crown",
  "The {~cathedral|abbey|great hall} is full. Someone is holding the crown with both hands, as if it might say something. You know every {~face|name} in the room.",
  C("Take it with a steady hand",
    O("My hands were steady. My voice wasn't. The country forgave the second.", {"happiness": 8, "fame": 8}, arc={"respect": 8}),
    O("I took it and meant every word of the oath. Later I would regret how literally I'd meant it.", {"fame": 6, "stress": 8}, arc={"respect": 6})),
  C("Add a line to the oath",
    O("I added a sentence about the poor. It was reported with wonder and quoted for decades.", {"karma": 6, "fame": 10}, arc={"respect": 10}),
    O("The archbishop did not know what to do. We stopped, and the whole country watched me explain.", {"fame": 8, "stress": 10}, arc={"respect": 2})),
  C("Weep openly",
    O("The crowd wept with me. For a day we were one country.", {"happiness": 6, "fame": 8}, arc={"respect": 10}),
    O("The papers said I looked unfit. The week after, the polls said the opposite.", {"fame": 6, "stress": 6}, arc={"respect": 3})))

E("royal", 4, "🏛️", "Ten years in",
  "A decade on the throne is marked by {~a parade|a state dinner|a quiet photograph}. A journalist asks what you regret.",
  C("Name something real",
    O("I named a war I should have stopped. The country went quiet and then forgave me.", {"karma": 6, "happiness": -2}, arc={"respect": 8}),
    O("I named it. The government's reaction was less forgiving.", {"karma": 5, "stress": 8}, arc={"respect": 2})),
  C("Say you don't regret anything",
    O("It was the truth and it sounded like a lie. The headline was cruel.", {"stress": 4}, arc={"respect": -6}),
    O("It went down well. Apparently people like a monarch who doesn't blink.", {"fame": 3}, arc={"respect": 4})),
  C("Turn the question around",
    O("I asked her what she regretted. It became the best interview of the year.", {"fame": 5, "happiness": 4}, arc={"respect": 6}),
    O("She said nothing, and the silence was long and mine.", {"stress": 6}, arc={"respect": -2})))

E("royal", 5, "🏰", "A reign remembered",
  "The history of the reign is being written by {~someone who never met you|someone who did|three people who disagree}. You are offered the chance to read it first.",
  C("Read it and correct the facts",
    O("I corrected eleven facts. The writer put them in a footnote.", {"smarts": 2, "happiness": 3}, arc={"respect": 3}),
    O("I corrected the facts and found I had to correct the tone as well. It became a second book.", {"stress": 5, "happiness": 2}, arc={"respect": 5})),
  C("Leave it alone",
    O("History is not mine to edit, only to deserve.", {"karma": 4, "happiness": 4}, arc={"respect": 6}),
    O("It came out flattering in the wrong places. The right places went unmentioned.", {"stress": 3}, arc={"respect": 2})),
  C("Write your own",
    O("My memoir came out in the same month. Historians use both.", {"fame": 6, "money": 120000}, arc={"respect": 4}),
    O("It was candid in ways I'd not intended. I was accused of vanity and then of honesty, and I'd rather the latter.", {"fame": 5, "money": 80000, "stress": 4}, arc={"respect": 2})))

# ------------------------------------------------------------------ witch
E("witch", 1, "✨", "The first spell",
  "{~The candle lit itself|The kettle boiled before you reached for it|A word you'd never said came out of your mouth}. Your {~grandmother|mother|neighbour} is watching you from the doorway.",
  C("Do it again, on purpose",
    O("The second time was harder, and it worked. I felt something open a door in me.", {"happiness": 6, "smarts": 1}, arc={"mana": -5, "spells": 1}),
    O("The second time something broke. I swept up the pieces and said nothing.", {"stress": 5, "happiness": 2}, arc={"mana": -8, "spells": 1})),
  C("Ask what happened",
    O("She told me three things and refused to tell me the fourth. It was the right amount.", {"smarts": 2, "happiness": 4}, arc={"mana": 4}),
    O("She laughed and told me I was late. I'd been late for years.", {"happiness": 3}, arc={"mana": 2})),
  C("Pretend it didn't happen",
    O("I pretended for a month. The candles pretended with me.", {"stress": 4}, arc={"exposure": 4}),
    O("It didn't work. Things kept happening around me until I stopped pretending.", {"stress": 6, "happiness": -2}, arc={"exposure": 8, "mana": -4})))

E("witch", 2, "🌕", "A circle of your own",
  "{~Two women from the village|Three people you barely know|A stranger on the bus} have started leaving small things on your doorstep: a feather, a shell, a note that says 'when you're ready'.",
  C("Invite them in",
    O("We cast a circle in my kitchen. The tea went cold and it was the best evening of the year.", {"happiness": 8, "karma": 2}, arc={"mana": 6, "exposure": 2}),
    O("One of them was an informer. I found out too late.", {"stress": 8, "happiness": -3}, arc={"exposure": 12, "mana": 4})),
  C("Observe them from a distance",
    O("They were what they said they were. I let them wait until I was sure.", {"smarts": 2, "stress": 2}, arc={"mana": 2}),
    O("They gave up. I regretted my caution for a year.", {"happiness": -3}, arc={"mana": -2})),
  C("Burn the notes",
    O("I burned them and felt, briefly, safe. Then lonely.", {"happiness": -2, "stress": 2}, arc={"exposure": -4}),
    O("The ashes spelled out something I didn't want to read.", {"stress": 6}, arc={"exposure": 4, "mana": 2})))

E("witch", 3, "📖", "The grimoire",
  "You've reached the page of the book that {~was torn out|is written in a hand you recognise|is blank until you ask the right question}. The ink is {~damp|warm|still moving}.",
  C("Read it aloud",
    O("It was a recipe for something that cannot be named in a kitchen. It worked.", {"smarts": 3, "happiness": 4, "stress": 4}, arc={"mana": 10, "spells": 5, "exposure": 8}),
    O("The room changed and so did I. I stopped being able to explain things to people who weren't there.", {"smarts": 3, "stress": 8}, arc={"mana": 6, "spells": 5, "exposure": 12})),
  C("Copy it into a safer hand",
    O("It took a week. The copy was worse and kept me alive.", {"smarts": 2}, arc={"spells": 3, "exposure": -4}),
    O("The copy had a mistake in it. Eventually I found where.", {"stress": 4}, arc={"spells": 3, "mana": -6})),
  C("Close the book",
    O("I closed it. It opened again when I left the room.", {"stress": 5}, arc={"exposure": 6}),
    O("I closed it, and it let me. Some things can be put down.", {"stress": -3, "happiness": 2}))
  )

E("witch", 4, "🔦", "Lanterns in the lane",
  "{~A neighbour has been asking questions|The vicar called round without an excuse|A man with a notebook has been seen at the end of your road}. You realise you are not as invisible as you thought.",
  C("Make friends with whoever's watching",
    O("It took an apple pie and a long conversation about nothing. They left feeling vaguely reassured.", {"stress": 3, "happiness": 2}, arc={"exposure": -12}),
    O("It worked on one of them. The other noticed the pie wasn't quite natural.", {"stress": 6}, arc={"exposure": 4})),
  C("Leave quietly",
    O("I packed in a night and was gone before the milkman. I miss that garden.", {"happiness": -4, "stress": 5}, arc={"exposure": -20, "mana": -6}),
    O("The move saved me and cost me a friend who'd have followed.", {"happiness": -5, "stress": 5}, arc={"exposure": -14})),
  C("Show them what you are",
    O("It was either the bravest or the stupidest thing I've done. They did not come back.", {"stress": 12, "happiness": 3}, arc={"exposure": 18, "mana": 8}),
    O("It went terribly. It also went in the village's favour, which I hadn't counted on.", {"stress": 10, "karma": 4}, arc={"exposure": 24})))

E("witch", 5, "🕯️", "Mother of the coven",
  "{~Someone's daughter|A woman half your age|A man who'd been a sceptic} has asked you to teach them. The coven is watching to see whether you'll say yes.",
  C("Teach them everything",
    O("It took years. They became better than me, and I was proud like a parent.", {"happiness": 8, "smarts": 2}, arc={"mana": 4, "spells": 10}),
    O("I taught too much too soon. Something went wrong and I carry it.", {"stress": 10, "karma": -3}, arc={"spells": 8, "exposure": 8})),
  C("Teach them what's safe",
    O("A careful curriculum, kindly given. Nobody was hurt, and nobody was great.", {"happiness": 4}, arc={"spells": 4, "exposure": -4}),
    O("They found the rest elsewhere. I wasn't the only teacher after all.", {"stress": 3}, arc={"spells": 3})),
  C("Refuse",
    O("The coven heard the refusal in silence. It was somebody else's turn.", {"happiness": -2, "stress": 3}, arc={"exposure": -2}),
    O("A year later I changed my mind and found it was too late.", {"happiness": -6, "stress": 5}))
  )

# ------------------------------------------------------------------ super
E("super", 1, "🌃", "The first night out",
  "{~A scream from an alley|A fire alarm three floors up|A car sliding on ice towards a crossing}. You are the only one near who can do something about it.",
  C("Act, and don't think",
    O("It worked. I was home in time for the late news, and I couldn't sleep.", {"happiness": 8, "stress": 4}, arc={"rep": 6, "saves": 1}),
    O("I did it, and someone filmed it. The footage was blurry and it was me.", {"happiness": 4, "stress": 8}, arc={"rep": 8, "saves": 1, "suspicion": 8})),
  C("Hold back and watch",
    O("Someone else handled it, badly. I told myself I'd learned something.", {"stress": 4, "happiness": -3}, arc={"rep": -2}),
    O("Nobody came. I'll carry that for a very long time.", {"karma": -6, "stress": 8, "happiness": -6})),
  C("Take what's there",
    O("In the confusion I took what I wanted. Nobody saw. I'd never felt so free.", {"money": 6000, "karma": -6, "happiness": 4}, arc={"heists": 1, "rep": 4}),
    O("It went wrong in a way that taught me what I was. I didn't like all of it.", {"money": 3000, "karma": -8, "stress": 8}, arc={"heists": 1, "suspicion": 8})))

E("super", 2, "🎭", "An alias that sticks",
  "A {~newspaper|blog|child} has started calling you by a name you didn't pick. {~It's not a good name.|It's better than yours.|It's catching on.}",
  C("Lean into it",
    O("I redesigned the mask around it. By the end of the month it was on a lunchbox.", {"fame": 8, "happiness": 6}, arc={"rep": 10}),
    O("It stuck faster than I could shape it. I became someone I hadn't chosen to be.", {"fame": 6, "stress": 5}, arc={"rep": 8, "suspicion": 4})),
  C("Correct them",
    O("They wrote the correction down. The new name sounded forced, and the old one stayed.", {"stress": 3}, arc={"rep": 3}),
    O("The correction became the story: the hero who didn't want a name.", {"fame": 4, "happiness": 3}, arc={"rep": 6})),
  C("Let it fade",
    O("A new name replaced it in a month. I was oddly relieved and oddly bereft.", {"happiness": -2}, arc={"rep": -3}),
    O("It faded, and someone else wore it better. I watched from a rooftop.", {"stress": 4, "happiness": -3}))
  )

E("super", 3, "🔥", "Someone with the same gift",
  "A figure {~watches you from the other side of a street|leaves a note on a rooftop|appears at the end of a night's work} with {~your powers, bent|a different idea of what they're for}. They've been following your work, and clearly disagree.",
  C("Confront them",
    O("It was a fight neither of us won. The city's windows will be repaired by spring.", {"stress": 10, "health": -4, "fame": 4}, arc={"nemesis_wins": 0, "rep": 8, "power": 4}),
    O("They were better than I'd feared. I escaped, and the city knew something was wrong.", {"stress": 12, "health": -6}, arc={"rep": 2, "suspicion": 6})),
  C("Try to talk",
    O("We talked until dawn. They didn't change their mind, and neither did I, but we'd both been listened to.", {"smarts": 2, "happiness": 3}, arc={"rep": 4}),
    O("They used the conversation to learn my weakness. I only realised later.", {"stress": 8, "karma": -2}, arc={"suspicion": 8, "rep": 2})),
  C("Ignore them",
    O("They went away for a while. It's the kind of quiet that makes you check the rooftops.", {"stress": 4}),
    O("They took it as an insult. It escalated, as these things do.", {"stress": 8, "happiness": -3}, arc={"rep": 3, "suspicion": 4})))

E("super", 4, "😶", "The mask slips",
  "Someone {~in the crowd|at work|in your own family} looks at you for a beat too long. {~They know.|They're not sure.|They've decided to keep it to themselves.}",
  C("Tell them the truth",
    O("They cried, laughed and asked a hundred questions. It was the best secret I've ever shared.", {"happiness": 8, "stress": -4}, arc={"suspicion": -10}),
    O("They told me they'd keep it, and a month later they told someone else.", {"stress": 10, "happiness": -6}, arc={"suspicion": 14, "revealed": True})),
  C("Deny it",
    O("I lied, and they let me. The lie held for a year.", {"stress": 6}, arc={"suspicion": -6}),
    O("I lied badly. They didn't say anything. They didn't have to.", {"stress": 8}, arc={"suspicion": 10})),
  C("Disappear for a while",
    O("A month on the road and nobody asked. When I came back, the question had gone.", {"happiness": 3, "stress": -3}, arc={"suspicion": -12}),
    O("The vanishing made it worse. Everyone has a theory.", {"stress": 6}, arc={"suspicion": 6, "rep": 4})))

E("super", 5, "🏙️", "A legend in the city",
  "They're {~naming a bridge|painting a mural|writing a documentary} about you. {~Nobody's asked.|You're consulted, as a courtesy.}",
  C("Go to the unveiling",
    O("The mask came with me. I stood at the back and watched a child touch the paint.", {"happiness": 9, "fame": 6}, arc={"rep": 6}),
    O("I went, and someone recognised the way I stood. The next day the rumour was everywhere.", {"fame": 8, "stress": 8}, arc={"rep": 4, "suspicion": 12})),
  C("Quietly ask for changes",
    O("They changed the one detail I'd asked for. The rest is mine to live with.", {"happiness": 3}, arc={"rep": 3}),
    O("They took it as a sign of modesty and put it in the caption.", {"happiness": 2, "fame": 2}, arc={"rep": 4})),
  C("Stay away",
    O("Legends don't go to their own unveilings. It was probably right.", {"happiness": 3}, arc={"rep": 5}),
    O("I stayed away and the city read it as a rebuke. The headline wasn't kind.", {"stress": 5}, arc={"rep": -4})))

json.dump(EV, open("data/events/arcs.json", "w"), indent=1, ensure_ascii=False)
open("data/events/arcs.json", "a").write("\n")
print(len(EV), "events,", sum(len(e["choices"]) for e in EV), "choices")

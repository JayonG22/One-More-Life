#!/usr/bin/env python3
"""Generates data/events/real.json — the everyday-life events for v0.15.
Every event has at least three choices and every choice at least two outcomes."""
import json

EV = []

def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    return o

def C(label, *outs):
    assert len(outs) >= 2, label
    return {"label": label, "outcomes": list(outs)}

def E(id, icon, title, text, cond, *choices, weight=6, cooldown=6, once=False):
    assert len(choices) >= 3, id
    e = {"id": id, "icon": icon, "title": title, "text": text, "conditions": cond, "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if once:
        e["once"] = True
    EV.append(e)

A = lambda lo, hi, *real, **kw: {"age": [lo, hi], "real": list(real), **kw}

# ------------------------------------------------------------------ tenancy
E("real.rent_rise", "📈", "The letter about the rent",
  "A letter from {~the agency|your landlord|the letting office} says the rent is going up. {~It calls this 'an adjustment in line with the market'.|The word 'unfortunately' appears twice.|It arrived on a Friday, which felt deliberate.}",
  A(18, 80, "renting"),
  C("Pay it and say nothing",
    O("I paid. There was a week of grumbling and then it was just the rent.", {"money": -400, "stress": 3}, real={"rent_pct": 6}),
    O("The new rent ate the gap I had been saving for. I stopped buying lunch out.", {"money": -700, "stress": 6, "happiness": -3}, real={"rent_pct": 8})),
  C("Negotiate",
    O("I showed {~the damp|the ageing boiler|three cheaper listings} and they came down to half of what they'd asked.", {"happiness": 3}, w=2, real={"rent_pct": 2}),
    O("They said the increase was non-negotiable. I felt like I had asked for something rude.", {"stress": 4}, real={"rent_pct": 7}),
    O("They said no, then mentioned that the owner was 'considering options'. Nothing good follows that sentence.", {"stress": 6}, real={"rent_pct": 5, "forced_move": False})),
  C("Start looking elsewhere",
    O("I spent three weekends at viewings. One flat smelled of cabbage and had a bath in the kitchen.", {"stress": 6}, real={"forced_move": True}),
    O("I found something cheaper and smaller, and moved before the increase took effect.", {"money": -1800, "happiness": 2, "stress": 4}, real={"forced_move": True})))

E("real.damp_patch", "🍄", "A patch on the wall",
  "There is a dark patch spreading {~behind the wardrobe|in the corner of the bedroom|above the window} and the air has started to smell of wet {~wool|cardboard|earth}.",
  A(18, 85, "renting", "damp"),
  C("Photograph it and write to the landlord",
    O("A man came and sprayed something on it. It came back within the month, but I had a paper trail.", {"stress": 2}, real={"damp": -25}),
    O("The landlord's reply said it was condensation and suggested I open a window. I opened a window.", {"stress": 5}, real={"damp": -5}),
    O("They sent a proper builder. It took a week and the flat smelt of paint, but the wall is finally dry.", {"happiness": 3, "stress": -3}, real={"damp": -50})),
  C("Scrub it myself",
    O("I spent a Sunday with bleach and a mask. It helped, and I coughed for two days.", {"health": -1, "stress": 1}, real={"damp": -20}),
    O("The patch returned a week later and the bleach smell stayed a month.", {"health": -2, "stress": 3}, real={"damp": -5})),
  C("Ignore it",
    O("I hung a picture over it. The picture started to curl.", {"health": -2, "stress": 2}, real={"damp": 12}),
    O("I developed a cough that took a doctor three appointments to link to the wall.", {"health": -4, "stress": 5, "money": -150}, real={"damp": 15})))

E("real.boiler_dead", "🥶", "No hot water",
  "The boiler {~gave a long groan and died|started clicking and then stopped|went out in the middle of a shower} and the flat is cold enough to see your breath in.",
  A(18, 85, "renting", "boiler_old"),
  C("Call the landlord",
    O("{~An engineer came the next day|The landlord sent someone within the week}. The new boiler is enormous and quiet.", {"stress": -2, "happiness": 2}, real={"boiler_age": -20}),
    O("Six weeks of cold showers and emails. Eventually a man came with a part the size of a biscuit.", {"health": -3, "stress": 6, "happiness": -3}, real={"boiler_age": -20}),
    O("The landlord told me to 'call the manufacturer'. The manufacturer told me to call the landlord.", {"stress": 7, "happiness": -3})),
  C("Pay for the repair myself",
    O("The engineer was kind and the bill wasn't. I got the money back out of the next rent after an argument.", {"money": -400, "stress": 3}, real={"boiler_age": -20}),
    O("I paid and never saw the money again. The landlord said 'noted'.", {"money": -850, "stress": 5}, real={"boiler_age": -20})),
  C("Stay with a friend until it's sorted",
    O("A week on someone's sofa reminded me who my friends were. They wouldn't take a penny.", {"happiness": 3, "stress": -1}, real={"boiler_age": -20}),
    O("The week on a sofa became a month, and we both started to count the days.", {"happiness": -2, "stress": 3})))

E("real.landlord_visit", "🧐", "An inspection",
  "{~Your landlord|The agency} has given you forty-eight hours' notice of an inspection. The flat has not been tidy since {~March|the spring|you moved in}.",
  A(18, 80, "renting"),
  C("Clean everything",
    O("The place passed. The landlord ran a finger along a shelf and looked almost disappointed.", {"stress": 3, "happiness": 1}),
    O("I found two things I'd lost months ago and a third I'd hoped was gone for good.", {"stress": 2, "happiness": 2})),
  C("Tidy only what shows",
    O("It was enough. I was told the place 'was well kept', which is the nicest thing anyone has said about it.", {"stress": 1}),
    O("They opened a cupboard. The cupboard did not behave.", {"stress": 6, "happiness": -2})),
  C("Refuse access",
    O("Legally, I was right. The landlord's face did not agree, and the repairs I'd asked for stopped being urgent.", {"stress": 5}, real={"rent_pct": 2}),
    O("They backed down with an email the length of a legal threat. I kept the flat; I lost some goodwill.", {"stress": 4, "karma": 1})))

E("real.deposit_dispute", "🧾", "The deposit",
  "{~The landlord is deducting|The agency says it will be keeping} a large part of your deposit for 'wear beyond fair use': a scuff, a carpet, and something called 'professional cleaning'.",
  A(20, 80, "renting", "landlord:grasping"),
  C("Dispute it with photographs",
    O("I'd photographed everything on move-in day. The scheme ruled in my favour and I got most of it back.", {"happiness": 6, "smarts": 1}, w=2, real={"deposit_loss": 10}),
    O("It took four months and a form for every wall. I won half.", {"stress": 6, "happiness": 1}, real={"deposit_loss": 50})),
  C("Accept it",
    O("I was tired. I let them have it and moved on.", {"happiness": -3, "stress": 2}, real={"deposit_loss": 60}),
    O("I accepted and then found a stain on the paperwork I hadn't noticed. Too late.", {"happiness": -4, "stress": 3}, real={"deposit_loss": 80})),
  C("Go to small claims",
    O("The judge barely looked at the landlord's folder. I won, and my mother framed the letter.", {"happiness": 8, "karma": 3, "stress": 4}, real={"deposit_loss": 0}),
    O("The landlord didn't turn up and the case was adjourned twice. It still ended in my favour, eventually.", {"stress": 8, "happiness": 4, "money": -100}, real={"deposit_loss": 10}),
    O("I lost on a technicality involving a missing signature. I have never read a lease so carefully.", {"stress": 8, "happiness": -5, "money": -200}, real={"deposit_loss": 80})))

E("real.flatmate_rent", "🧑‍🤝‍🧑", "The flatmate is late with the rent",
  "{~Your flatmate|The person you share with} is short again this month and has a very good reason, which is different from last month's.",
  A(18, 60, "renting", "flatmate"),
  C("Cover it this time",
    O("They paid me back in instalments and a lasagne. I have mixed feelings about the lasagne.", {"money": -500, "stress": 3}),
    O("They never mentioned it again. Neither did I, out loud.", {"money": -600, "stress": 4, "happiness": -2})),
  C("Sit them down",
    O("We made a schedule and a rule, and the next three months went better than the last three.", {"stress": -2, "happiness": 2, "karma": 1}),
    O("It turned into an argument about the dishes, and then about everything, and then about nothing.", {"stress": 6, "happiness": -3})),
  C("Tell the landlord",
    O("The landlord sorted it out with a letter. Our flat has been silent since, like a library with grievances.", {"stress": 3, "happiness": -2}, real={"flatmate_leaves": True}),
    O("The flatmate moved out that weekend, leaving the fridge full of mystery leftovers.", {"stress": 2, "happiness": -1}, real={"flatmate_leaves": True})))

E("real.flatmate_party", "🥳", "They have people round",
  "It's {~a Tuesday|midnight|a work night} and your flatmate's {~friends have arrived|birthday has begun|'quiet evening' has become a DJ set}.",
  A(18, 50, "renting", "flatmate"),
  C("Join in",
    O("I met someone I'd never have spoken to otherwise. We exchanged numbers. The hangover was memorable.", {"happiness": 6, "health": -1, "stress": -2}),
    O("At 3 a.m. I was the one sitting on the stairs explaining my life to a stranger called Doug.", {"happiness": 3, "stress": 2})),
  C("Go to bed and put earplugs in",
    O("It worked until the smoke alarm. I slept through the music and woke up to the fire brigade.", {"stress": 5, "happiness": -2}),
    O("The earplugs held. I woke up fresh, and the kitchen looked like a crime scene.", {"happiness": 1, "stress": 1})),
  C("Tell them to turn it down",
    O("They did, graciously, and thanked me for being direct.", {"happiness": 2, "stress": -1}),
    O("They turned it up, slightly. We didn't speak for a week.", {"stress": 5, "happiness": -3}),
    O("The neighbours called the landlord and I got the letter.", {"stress": 6, "happiness": -2}, real={"rent_pct": 2})))

E("real.lease_renewal", "📄", "The lease is up",
  "The lease on {~the flat|your place} runs out next month and {~the agency|your landlord} would like to know what you intend to do.",
  A(19, 75, "renting"),
  C("Sign for another year",
    O("A year's security, at a price. I hung the pictures I'd been putting off.", {"stress": -3, "happiness": 2}, real={"rent_pct": 4}),
    O("They wanted a higher rent and a clause about pets I didn't read until later.", {"stress": 3}, real={"rent_pct": 7})),
  C("Go month-to-month",
    O("It costs a little more and I keep my options open. I never quite relax.", {"stress": 2}, real={"rent_pct": 9}),
    O("They said yes, and then sold the building three months later.", {"stress": 6, "happiness": -2}, real={"forced_move": True})),
  C("Walk away and find somewhere new",
    O("I found a flat with a view of a car park and a landlord who replies to messages. I'll take it.", {"happiness": 4, "money": -1800, "stress": 4}, real={"forced_move": True}),
    O("I searched for weeks and nearly ended up on a sofa. The place I found smells of someone else's dinners.", {"stress": 8, "money": -1800, "happiness": -2}, real={"forced_move": True})))

E("real.locked_out", "🔑", "Locked out",
  "It's {~eleven at night|raining|the coldest night of the year} and your keys are on the kitchen table, on the other side of a door.",
  A(16, 80, "renting"),
  C("Call a locksmith",
    O("A man arrived in twelve minutes and opened the door in four. The bill was more than my shoes.", {"money": -280, "stress": 3}),
    O("The locksmith was a scam. He charged three times the quote and left the door broken.", {"money": -700, "stress": 7, "happiness": -3})),
  C("Wake the neighbour with the spare",
    O("They'd been asleep for an hour and still made me tea. I owe them a bottle of wine.", {"happiness": 3, "karma": 2}),
    O("They weren't in. I sat on the stairs for three hours until a flatmate came home.", {"stress": 5, "happiness": -2})),
  C("Climb in through a window",
    O("I got in without a scratch, and was enormously pleased with myself.", {"happiness": 4}),
    O("I got in with a split lip and a bruised pride. The neighbour filmed it.", {"health": -2, "happiness": -2, "stress": 3}),
    O("The police were called by someone who thought I was a burglar. Explaining myself took an hour.", {"stress": 6, "karma": -1, "heat": 1})))

E("real.first_flat", "🥡", "The first place that was yours",
  "{~Your first flat|The first place with your name on the lease} has a mattress, one chair and a window that opens onto {~a brick wall|a neighbour's washing|a wonderful slice of sky}.",
  A(18, 26, "renting"),
  C("Spend a weekend making it home",
    O("I painted one wall a colour I'd never choose again. I slept like a child that night.", {"happiness": 8, "money": -180}),
    O("I found a plant, a lamp and a chair at a charity shop. The room started to have an opinion.", {"happiness": 6, "money": -120, "stress": -3})),
  C("Throw a housewarming",
    O("Everyone stood in the kitchen, as everyone does. It was the best night of my year.", {"happiness": 9, "money": -150}),
    O("Only two people came, and we ate all the crisps. It was oddly perfect.", {"happiness": 6, "money": -80})),
  C("Live out of boxes for months",
    O("The boxes became furniture. It was a long time before it felt like mine.", {"happiness": -2, "stress": 2}),
    O("I got used to it, and then I stopped noticing I hadn't unpacked at all.", {"happiness": 0, "stress": 1})),
  weight=5, cooldown=12)

# ------------------------------------------------------------------ getting about
E("real.first_crash", "💥", "The first crash",
  "{~You were reversing|You took a corner too fast|The road was wet and the car in front stopped suddenly}. There's a crunch, then a silence, then someone getting out of the other car.",
  A(17, 26, "drives", "young_driver"),
  C("Admit fault and exchange details",
    O("They were decent about it. The insurer was less decent, and the premium jumped.", {"stress": 5, "karma": 3}, real={"crash": "minor"}),
    O("The other driver turned out to be a neighbour's uncle. We've waved to each other ever since.", {"stress": 3, "karma": 3}, real={"crash": "minor"})),
  C("Argue it was their fault",
    O("They had dashcam footage. I've never felt so small in a car park.", {"stress": 8, "karma": -4, "happiness": -3}, real={"crash": "moderate"}),
    O("It went to the insurers, who split the blame, and my premium rose anyway.", {"stress": 6, "karma": -1}, real={"crash": "minor"})),
  C("Drive away",
    O("I got four streets before I started shaking. Someone had taken my number plate.", {"stress": 10, "karma": -8, "heat": 4}, real={"crash": "moderate", "fine": 800}),
    O("I was caught on a doorbell camera, and two days later a police officer was sitting in the kitchen with my mother.", {"stress": 12, "karma": -8, "heat": 6}, real={"crash": "moderate", "fine": 1200})))

E("real.parking_ticket", "🅿️", "A ticket under the wiper",
  "There's a yellow envelope under the windscreen wiper of your car. {~You were there for eleven minutes.|The sign was behind a tree.|You were sure that bay was free.}",
  A(17, 85, "drives"),
  C("Pay it",
    O("It was quicker than the alternative. I've since become very good at reading signs.", {"money": -60, "stress": 1}),
    O("I paid the discounted rate and swore at an envelope.", {"money": -40, "stress": 2})),
  C("Appeal it",
    O("The appeal was upheld. The warden had measured the wrong bay. I felt a disproportionate joy.", {"happiness": 4, "smarts": 1}),
    O("The appeal was rejected after six weeks, and the fine doubled.", {"money": -120, "stress": 4})),
  C("Ignore it",
    O("It turned into a court letter. I paid it with the extra fee and my tail between my legs.", {"money": -220, "stress": 5, "karma": -1}),
    O("Nothing happened for a year, then a bailiff's letter arrived and I couldn't pretend any more.", {"money": -380, "stress": 8, "karma": -2})))

E("real.commute_breakdown", "⏱️", "The long way in",
  "{~The journey takes over an hour|The commute has crept up again|You do the sums and lose a full working day every week}, each way, and you've started to hate {~the bridge|the ring road|the platform|the stop}.",
  A(20, 65, "long_commute"),
  C("Move closer to work",
    O("I found a place ten minutes away. It cost more, and every morning felt like a gift.", {"money": -2500, "happiness": 6, "stress": -6}, real={"forced_move": True}),
    O("The flat was tiny and the noise was terrible, but I got back ten hours a week.", {"money": -1800, "happiness": 3, "stress": -3}, real={"forced_move": True})),
  C("Use the time properly",
    O("I started listening to books on the journey. A year later I'd read sixty.", {"smarts": 3, "happiness": 2}),
    O("I started learning a language. My accent on the platform was the talk of the carriage.", {"smarts": 2, "happiness": 2})),
  C("Ask about working from home",
    O("After a pilot, they agreed to two days a week. It changed everything.", {"happiness": 6, "stress": -5, "job_perf": 2}),
    O("They said the job needed 'presence'. The look on my face was noted.", {"stress": 4, "happiness": -2}),
    O("They refused, and I started looking at other jobs.", {"stress": 3, "happiness": -1})))

E("real.bike_stolen", "🚲", "The empty lock",
  "You come out to the rack and find {~a cut lock|the lock, neatly snapped|nothing but a front wheel} where your bike was.",
  A(12, 70, "commute:bike"),
  C("Report it",
    O("The police gave me a crime number and an apologetic smile. I got nothing else from them.", {"stress": 3}),
    O("A week later a patrol found it in a skip. It needed a new chain and a bit of grace.", {"happiness": 4, "money": -40})),
  C("Buy a new bike",
    O("The new one was better, and heavier, and I named it after my grandmother.", {"money": -380, "happiness": 2}),
    O("The new one was stolen within the year too. I've learned about locks.", {"money": -380, "stress": 4})),
  C("Switch to the bus",
    O("I hate to admit I like it. Forty minutes of reading a book.", {"happiness": 1, "health": -1}),
    O("The bus turned out to be late every morning, and I missed the ride.", {"stress": 3, "health": -1})))

E("real.train_cancelled", "🚆", "Cancelled",
  "The board says {~CANCELLED|DELAYED|SIGNAL FAILURE}. The platform fills with people sighing in unison.",
  A(14, 70, "commute:train"),
  C("Wait it out",
    O("Forty minutes later we crammed on. I stood with my face against someone's rucksack, reflecting.", {"stress": 4}),
    O("It came, it was empty, and I got a seat. A small miracle.", {"happiness": 3})),
  C("Find another way",
    O("I got a taxi with three strangers. We split the fare and became briefly close.", {"money": -30, "happiness": 2, "stress": 1}),
    O("I walked the whole way and arrived an hour late, cold and strangely proud.", {"health": 1, "stress": 3})),
  C("Go home and say you'll work from home",
    O("My boss said 'sure', in a tone that I thought about all day.", {"stress": 2, "job_perf": -2}),
    O("I got more done at the kitchen table than I'd done all week, and nobody noticed.", {"happiness": 3, "job_perf": 2})))

E("real.bus_stranger", "🚌", "The stranger on the bus",
  "{~Someone sits beside you|Someone across the aisle catches your eye} and says, unprompted, {~'You look like you've had a day.'|'Is this seat taken?'|'That book is terrible, by the way.'}",
  A(14, 80, "commute:bus"),
  C("Talk back",
    O("We talked for four stops. I never saw them again, and think about them most weeks.", {"happiness": 5}),
    O("We swapped numbers. They became a friend, of the kind you only have on certain days of the week.", {"happiness": 6, "karma": 1})),
  C("Nod and put headphones on",
    O("Sometimes the best conversation is the one you don't have. I got home rested.", {"stress": -2}),
    O("I regretted it by my stop. There was something in their face I should have answered.", {"happiness": -2})),
  C("Move seats",
    O("The next seat was worse, and next to someone eating curry.", {"stress": 2}),
    O("It was awkward but fine.", {"stress": 1})))

E("real.insurance_renewal", "📑", "The renewal quote",
  "Your car insurance renewal has arrived and {~the number has changed|it's gone up again|the cheapest quote this year came from a company you've never heard of}.",
  A(18, 85, "insured"),
  C("Shop around",
    O("After forty minutes on comparison sites I saved enough to buy a very good dinner.", {"money": 180, "smarts": 1}),
    O("I found a cheaper deal, then found out why: the excess was enormous.", {"money": 80, "stress": 2})),
  C("Stay put and pay it",
    O("I paid it. Loyalty is an expensive habit.", {"money": -120, "stress": 1}),
    O("I paid it and kept my no-claims bonus. A small comfort.", {"stress": 0})),
  C("Drop to third party cover",
    O("It saved money, and I spent the year holding my breath.", {"money": 400, "stress": 3}, real={"cover": "third"}),
    O("I dropped to basic cover, and a stone put a crack in my windscreen the next week.", {"money": 300, "stress": 4}, real={"cover": "third"})))

E("real.speed_camera", "📸", "The flash",
  "{~A flash in the mirror|A grey box on a pole|A letter in a brown envelope} tells you that you were {~going a little faster than the sign suggested|doing 42 in a 30|thinking about something else}.",
  A(17, 85, "drives"),
  C("Take the points",
    O("I paid the fine and did the speed awareness course. The man running it was more entertaining than I'd feared.", {"money": -100, "smarts": 1}, real={"premium_pct": 20}),
    O("I paid it and went on a course, learning that my road has a habit of catching people.", {"money": -100, "stress": 1}, real={"premium_pct": 20})),
  C("Contest it",
    O("A technicality saved me. The camera hadn't been calibrated.", {"happiness": 4, "smarts": 1}),
    O("I went to court. The magistrate was not amused and the fine doubled.", {"money": -300, "stress": 5, "heat": 1})),
  C("Pretend someone else was driving",
    O("It blew up in my face, and my cousin has stopped returning my calls.", {"karma": -6, "stress": 8, "money": -500, "heat": 3}, real={"premium_pct": 40}),
    O("It worked, and I spent the next year jumpy every time a letter arrived.", {"karma": -4, "stress": 5}, real={"premium_pct": 0})))

# ------------------------------------------------------------------ keeping up
E("real.lost_touch", "📵", "Someone you meant to call",
  "You realise it has been {~four years|longer than you'd like to say|since before the last move} since you talked to an old friend, and neither of you did anything to cause it.",
  A(20, 85, "lapsed_friend"),
  C("Call them today",
    O("They picked up on the second ring and said 'I was just thinking about you.' I don't know whether it was true.", {"happiness": 7, "stress": -2}),
    O("It was awkward for about three minutes and then it wasn't. We made a plan for the summer.", {"happiness": 5}),
    O("The number had changed. I found them on social media. They were warm but distant.", {"happiness": 0, "stress": 1})),
  C("Write a long message",
    O("I spent an hour writing it and ten seconds sending it. The reply came next morning: 'God, yes.'", {"happiness": 5}),
    O("No reply came. I've decided it's the silence of someone who is busy, rather than someone who isn't interested.", {"happiness": -3, "stress": 2})),
  C("Let it lie",
    O("Some friendships are for a season. I thought about them on a bench once, and then I stopped.", {"happiness": -1}),
    O("Two years later I heard they had moved abroad. I felt the loss more than I'd expected.", {"happiness": -4, "stress": 2})))

E("real.group_chat", "💬", "The group chat",
  "The group chat {~has 312 unread messages|went off at 2 a.m.|has turned into an argument about something none of you can now remember}.",
  A(14, 70, "tech:2"),
  C("Read it all",
    O("There was a real argument in there, with real feelings. I replied with something kind, for once.", {"happiness": 2, "karma": 2, "stress": 2}),
    O("Forty minutes of memes and one heartfelt message from someone who's struggling. I rang them.", {"happiness": 3, "karma": 3})),
  C("Mute it",
    O("Ah, peace. A week later I'd missed a birthday and a flat-warming.", {"stress": -3, "happiness": -2}),
    O("The silence was wonderful. Nobody noticed. I'm not sure what that says.", {"stress": -2, "happiness": 0})),
  C("Leave the group",
    O("Two people messaged to ask if I was okay. I wasn't sure how to answer.", {"stress": 1, "happiness": -1}),
    O("Nobody said anything and it stung, though I'd done it myself.", {"happiness": -3})))

E("real.funeral_words", "🕯️", "Asked to say a few words",
  "The family of {~someone you knew|an old friend|a person who mattered to you} has asked whether you would speak at the funeral. {~They say you were the one who knew them best.|You said yes before you'd thought about it.}",
  {"age": [20, 90], "flags": ["lost_close_person"]},
  C("Write something careful",
    O("I spent three nights on it. I read it out, and they laughed and cried, in that order.", {"happiness": 2, "stress": 6, "karma": 3}),
    O("The page shook in my hands. I finished, and sat down, and felt something open up in me.", {"happiness": 1, "stress": 5, "karma": 2})),
  C("Speak from the heart",
    O("It was messy and real. Someone told me afterwards it was the best eulogy they'd heard.", {"happiness": 3, "stress": 4, "karma": 3}),
    O("I got three sentences in and couldn't go on. Someone took my hand and finished the story.", {"happiness": -1, "stress": 6, "karma": 2})),
  C("Decline",
    O("Someone else spoke, well, and I sat at the back thinking about what I would have said.", {"happiness": -3, "stress": 3}),
    O("I sent a letter for someone to read. It was kind, and it wasn't the same.", {"happiness": -1, "stress": 2})),
  cooldown=10)

E("real.cooking_night", "🍳", "Dinner from scratch",
  "You {~try a recipe you've been meaning to|decide to cook for the week|invite people over and promise a proper meal}, and the kitchen fills with smells.",
  A(16, 80, "diet:cook"),
  C("Follow the recipe exactly",
    O("It came out tasting like the picture. I want that in writing.", {"happiness": 5, "health": 1}),
    O("It came out tasting like a photograph of the dish, and everyone was polite.", {"happiness": 2})),
  C("Improvise",
    O("A handful of something I found in the cupboard turned out to be the secret. Everyone asked for the recipe.", {"happiness": 6, "smarts": 1}),
    O("The smoke alarm sang. We ordered pizza, and it was the best night of the month.", {"happiness": 4, "stress": 1})),
  C("Give up and order in",
    O("A delivery at nine. No regrets and a little guilt.", {"happiness": 2, "money": -25}),
    O("The delivery was wrong, cold and late, and I ate toast.", {"happiness": -2, "money": -25})))

E("real.takeaway_bill", "🥡", "The takeaway bill",
  "You look at the bank statement and there is a column of delivery apps that looks like {~a phone number|a list of small betrayals|someone else's life}.",
  A(18, 70, "diet:takeaway"),
  C("Start cooking",
    O("I bought a pan and an ambition. It wasn't good at first, and then it was.", {"health": 1, "money": 400, "happiness": 2}, real={"diet": "mixed"}),
    O("I ate beans on toast for a fortnight and felt pure.", {"health": 1, "money": 300, "stress": 1}, real={"diet": "cook"})),
  C("Carry on",
    O("I told myself it was self-care. My waistband didn't agree.", {"health": -2, "happiness": 2, "money": -400}),
    O("A friend stared at me across a pile of cartons. I changed the subject.", {"health": -1, "happiness": 1, "money": -300})),
  C("Set a budget",
    O("I set an allowance and a rule. The rule lasted three weeks. The allowance lasted two.", {"money": 200, "stress": 1}),
    O("It worked, for once. I was amazed at how small the budget really was.", {"money": 500, "happiness": 2, "smarts": 1}, real={"diet": "mixed"})))

E("real.old_photos", "📷", "A box of photographs",
  "You find {~a shoebox|an album|a drawer of envelopes} of old photographs, the kind that {~smell of the chemist|have a thumbprint on the corner}.",
  A(25, 90, "pretech:3"),
  C("Spend the evening going through them",
    O("There was one of you laughing that you had no memory of. I kept it on the fridge.", {"happiness": 5, "stress": -2}),
    O("I found someone I had forgotten I loved. I put the photo down and stared at the wall for a while.", {"happiness": -1, "stress": 2})),
  C("Scan them and send copies",
    O("Three people cried, two argued about who was in the photograph. It was the best gift I've given.", {"happiness": 6, "karma": 2}),
    O("It took a month, and nobody replied. I kept going, and I'm glad I did.", {"happiness": 2, "stress": 2})),
  C("Put the box back",
    O("Some things are better in the dark. Not all, but some.", {"happiness": -1}),
    O("I meant to come back to them. I haven't.", {"happiness": -2})))

E("real.internet_outage", "📡", "No connection",
  "The {~internet|wifi|line} has been down for {~two days|most of a week|long enough to notice}, and you've discovered how much of your life lives on it.",
  A(14, 80, "tech:2"),
  C("Ring the provider",
    O("After an hour on hold, a man named Darren talked me through turning it off and on again. It worked.", {"stress": 3, "smarts": 1}),
    O("They promised an engineer between 8 and 6. He came at 5:55 and fixed it in a minute.", {"stress": 4, "happiness": 1})),
  C("Use it as an excuse to unplug",
    O("I read a book, took a walk and called my mother. It was the best weekend in a year.", {"happiness": 6, "stress": -5}),
    O("By day two I was twitching. By day three I'd found a hobby.", {"happiness": 3, "stress": -1})),
  C("Go to the library or a cafe",
    O("I worked in a cafe for three days, and had a conversation with the barista that I still remember.", {"happiness": 3, "money": -25}),
    O("Every seat was taken by someone on the same mission. We nodded like survivors.", {"happiness": 2, "stress": 1, "money": -20})))

E("real.family_table", "🍽️", "The family meal",
  "It's {~a holiday|Sunday|someone's birthday}, and the family are at the table. {~Nobody has sat down yet|The argument has already started|Someone has brought up politics}.",
  {"age": [14, 90]},
  C("Keep the peace",
    O("I changed the subject three times and got away with a good dinner.", {"happiness": 3, "stress": 1}),
    O("I kept the peace, but bit my tongue until it bled.", {"stress": 4, "happiness": 1})),
  C("Say what you actually think",
    O("Silence fell. Then someone said 'he's right,' and the night turned around.", {"happiness": 4, "karma": 1, "stress": 2}),
    O("It ended with a slammed door and a cold plate of pudding in my lap.", {"stress": 8, "happiness": -4})),
  C("Help in the kitchen",
    O("The best conversation of the night was by the sink, over the dishes.", {"happiness": 5, "stress": -2}),
    O("I dropped a dish and everyone looked at me. It was a happy accident, in the end.", {"happiness": 1, "stress": 1})),
  weight=4, cooldown=5)

json.dump(EV, open("data/events/real.json", "w"), indent=1, ensure_ascii=False)
open("data/events/real.json", "a").write("\n")
print(len(EV), "events,", sum(len(e["choices"]) for e in EV), "choices")

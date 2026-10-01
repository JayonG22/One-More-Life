#!/usr/bin/env python3
"""Generates data/events/pets.json — Pets Life (v1.1).

Every event is conditioned on life == "pet", so the human game never sees them
and a pet never sees the human ones. Each has three choices and every choice has
two or more outcomes. Follow-ups (F) are wired onto their sources the way the
human echoes are.  Pet gauges are changed with the `pet` outcome key."""
import json, sys, os
EV = []
FOLLOW = []   # (event, sources)

OWN = {"o": {"relation": "owner"}}

SPECIAL = ("befriend", "rival", "adopt", "rehome", "found", "illness", "home", "lost", "role")

def O(text, fx=None, pet=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    pd = dict(pet or {})
    for k in SPECIAL:
        if k in extra:
            pd[k] = extra.pop(k)
    if pd:
        o["pet"] = pd
    o.update(extra)
    return o

def C(label, *outs):
    assert len(outs) >= 2, label
    return {"label": label, "outcomes": list(outs)}

def E(id, icon, title, text, conds, *choices, roles=None, age=(0, 60), weight=1.0, cooldown=6, once=False):
    assert len(choices) >= 3, id
    c = {"age": list(age), "life": "pet"}
    c.update(conds)
    d = {"id": "pl." + id, "icon": icon, "title": title, "text": text, "conditions": c,
         "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if roles:
        d["roles"] = roles
    if once:
        d["once"] = True
    EV.append(d)

def F(id, icon, title, text, years, sources, conds, *choices, roles=None):
    assert len(choices) >= 3, id
    c = {"age": [0, 90], "life": "pet"}
    c.update(conds)
    d = {"id": "pl." + id, "icon": icon, "title": title, "text": text, "conditions": c,
         "choices": list(choices), "weight": 1, "followup_only": True}
    if roles:
        d["roles"] = roles
    EV.append(d)
    FOLLOW.append((d["id"], years, sources))

def A(path_n, icon, title, text, *choices):
    assert len(choices) == 3
    EV.append({"id": "arc.pet.%d" % path_n, "icon": icon, "title": title, "text": text,
               "conditions": {"age": [0, 130], "life": "pet"}, "choices": list(choices), "weight": 1, "followup_only": True})

HOME = {"pet": ["has_home", "owner"]}

# ======================================================================== EVERYDAY (any species, in a home)
E("thunder", "⛈️", "The night the sky broke",
  "{~The storm arrived at two in the morning|Thunder rolled up the valley after dark|Fireworks started at nine and didn't stop}, and every part of me is trying to leave my body.",
  HOME,
  C("Get into the bath, where it is dark and tiled and small",
    O("It was a tiny cold cave, and the noise was a bit further away in it. {o.first} sat on the floor outside with the door ajar until the sky ran out.", {"stress": -2}, {"bond": 3}),
    O("I wedged myself behind the toilet and stayed until morning. {o.first} found me there, stiff and grateful.", {"stress": 4, "happiness": -1}, {"instinct": 2})),
  C("Climb into bed with {o.first}",
    O("I got under the covers, where the world is soft, and {o.first} put an arm over me and said it was only weather.", {"happiness": 3, "stress": -5}, {"bond": 5}),
    O("I was told 'not on the bed'. I was on the bed. We never mentioned it again.", {"happiness": 2, "stress": -3}, {"bond": 3, "obedience": -2})),
  C("Face it at the window and tell it off",
    O("I barked at the sky, and the sky stopped. I take full credit.", {"happiness": 2, "stress": 2}, {"instinct": 3}),
    O("The sky did not stop. I lost my voice and my dignity, and {o.first} had to carry me from the glass.", {"stress": 6}, {"bond": 2})),
  roles=OWN)

E("left_alone", "🚪", "The long day",
  "{o.first} left before light and the day has no end. The flat is full of every smell they have ever had, and none of them are here.",
  HOME,
  C("Wait at the door",
    O("I waited with my nose to the crack, and when the key finally turned I was already there, spinning on the spot.", {"happiness": 3, "stress": 3}, {"bond": 4}),
    O("I waited for so long that I forgot why. When the key turned, I had to be woken.", {"happiness": 1}, {"bond": 1})),
  C("Redecorate",
    O("A great deal got done. The cushion is now a snowfield and the post is in tiny, complicated pieces. I was asleep on the evidence when they came in.", {"happiness": 4, "stress": -4}, {"mischief": 1, "bond": -2, "mood": -4}),
    O("I found the shoes. {o.first}'s face when they saw the shoes is a thing I will carry with me.", {"happiness": 2, "stress": 3}, {"bond": -3, "mood": -5, "mischief": 1})),
  C("Sleep it away, in the warmest chair",
    O("I slept in a long, slow slab of sun and the day passed under me like a boat.", {"stress": -6, "health": 1}, {}),
    O("I slept badly, in spurts, and woke up to the sound of someone else's alarm in the next flat.", {"stress": 2}, {})),
  roles=OWN)

E("holiday_table", "🦃", "The big table",
  "The house is full of people I don't know and the smell of an entire cooked animal. The table is at exactly my height, in the way a table is when you aren't looking.",
  HOME,
  C("Beg under the table, in the manner of a professional",
    O("A hand lowered, over and over, from four different directions. I ate like a prince and regretted nothing until three in the morning.", {"happiness": 6, "health": -2}, {"hunger": 14, "bond": 1}),
    O("A relative who hated me gave me a sprout. It was not a gift. It was an experiment.", {"happiness": -1}, {"hunger": 3})),
  C("Wait, sit and be good",
    O("{o.first} noticed and slipped me the best slice, privately, in the kitchen. Being good has some value.", {"happiness": 5}, {"obedience": 3, "hunger": 10, "bond": 4}),
    O("I sat so well that a child gave me a bread roll. The adults applauded. I accepted this with grace.", {"happiness": 4}, {"obedience": 2, "hunger": 6})),
  C("Steal the whole bird",
    O("There is a moment, with a roast turkey, when you either become a legend or a lesson. I became a legend, and was sick in the hall.", {"happiness": 6, "health": -4}, {"hunger": 24, "instinct": 3, "bond": -3, "mischief": 1}),
    O("I was spotted at the counter with the bird already half off the dish. It was a short chase, with a long tail.", {"happiness": 2, "stress": 6}, {"hunger": 6, "bond": -4, "mischief": 1})),
  roles=OWN)

E("rain_walk", "🌧️", "Rain",
  "{o.first} is standing at the open door with the lead in one hand. Beyond the door, the world has become wet. This is, I feel, a conversation.",
  HOME,
  C("Refuse to move",
    O("I held my ground in the dry bit of the hall until {o.first} gave up, laughing, and did a lap of the flat with me instead.", {"happiness": 2}, {"obedience": -2, "bond": 2}),
    O("I was carried out like a sack. It was a very short walk and a very long towelling.", {"stress": 3}, {"obedience": -1, "fitness": 2})),
  C("Go out, and make the most of the puddles",
    O("The puddles were extraordinary. I found the one that went up to my knees and I will remember it for a decade.", {"happiness": 6, "health": 1}, {"fitness": 5, "territory": 3}),
    O("A great day, and a mud-soaked car, and a bath at the end that I took in an offended silence.", {"happiness": 4, "stress": 2}, {"fitness": 4, "bond": 2})),
  C("Go out, hurry, and do my business under the nearest tree",
    O("In, out, quick as a thief. I have never been so efficient and I was rewarded with a biscuit at the door.", {"happiness": 3}, {"obedience": 3, "hunger": 3}),
    O("I got it done and then stood in the rain, in the dark, and looked at the lit windows. Everyone was inside. It was beautiful.", {"happiness": 2, "stress": -2}, {"territory": 3})),
  roles=OWN, cooldown=4)

E("owner_sad", "💔", "A bad night",
  "{o.first} came home and did not turn the light on. They are sitting on the kitchen floor, with their back to the cupboard, and the sounds they are making are not for anybody.",
  HOME,
  C("Press against their side",
    O("I leaned all my weight into them. After a long time, a hand found my ear. We stayed there until the light changed.", {"happiness": 2, "stress": 2}, {"bond": 8, "mood": 6}),
    O("They said my name in a broken voice, and that was all I needed to hear. I stayed pressed against them until they fell asleep sitting up.", {"happiness": 1, "stress": 3}, {"bond": 7, "mood": 8})),
  C("Bring them something",
    O("I brought them the shoe, then the other shoe, then a sock. It is a language they understand even in grief, and it made them laugh a bit, wetly.", {"happiness": 3}, {"bond": 5, "mood": 8}),
    O("I brought the whole sofa cushion, in a single trip. This was not the effect I'd been after but it made them laugh anyway.", {"happiness": 2}, {"bond": 3, "mood": 5, "mischief": 1})),
  C("Keep out of the way",
    O("I lay in the next room with an ear turned toward the kitchen, ready, and nobody called. By morning they had cried it out.", {"stress": 3}, {"bond": -1}),
    O("I went and found a corner. I'm not good at this part, and I'm sorry. It took them two days to feel like themselves.", {"stress": 4, "happiness": -2}, {"bond": -3, "mood": -4})),
  roles=OWN, cooldown=7)

E("kid_tail", "🧒", "Small and enthusiastic",
  "The littlest human has discovered that I am exactly the right size to hold on to. They love me enormously, and with their whole fist.",
  {"pet": ["has_home", "kids"]},
  C("Endure it, with patience",
    O("I put up with the hug, the ride and the hat. {o.first} said I was 'a saint'. I don't know what that is but it seemed to be good.", {"stress": 4, "happiness": 2}, {"bond": 4, "belonging": 3}),
    O("It went on for an hour. I am a very good animal. I will need a long sleep.", {"stress": 6, "happiness": 1}, {"bond": 3, "obedience": 3})),
  C("Escape upstairs",
    O("I found the one place a small person can't go, which is under the bed, and stayed there all afternoon. It was bliss.", {"stress": -3}, {"instinct": 2}),
    O("I jumped up on a surface they couldn't reach. They stood under me with their arms out, singing.", {"happiness": 1}, {"instinct": 3, "mood": -2})),
  C("Make my feelings known",
    O("A small warning noise, a flash of teeth, a pair of adult eyes that looked very hard at both of us. Nobody was hurt, and the rules changed that afternoon.", {"stress": 4}, {"bond": -3, "belonging": -4, "mood": -4}),
    O("I said a firm 'no', quietly, and the child understood perfectly. They were gentler from then on, and {o.first} gave me a long, warm look.", {"happiness": 3}, {"bond": 4, "obedience": 2})),
  roles=OWN)

E("new_animal", "🐾", "Another one",
  "{o.first} has come home carrying a box. There is something in it that smells like a stranger, and it is making a small unhappy noise, and I think it is going to live here.",
  HOME,
  C("Welcome it",
    O("It was small and anxious and I put my face to its side. By the evening it had decided I was a pillow. I have a flatmate.", {"happiness": 6, "stress": -2}, {"belonging": 4}, befriend="cat"),
    O("I showed it the water bowl, the sofa and the dangerous bit of the hall, in that order. It followed me everywhere for a week.", {"happiness": 5}, {"belonging": 3, "bond": 1}, befriend="dog")),
  C("Make it very clear whose house this is",
    O("There were some hard looks, a stand-off at the food bowl and a peace treaty brokered by the hoover.", {"stress": 4}, {"territory": 4, "instinct": 2}, rival=True),
    O("I put it in its place, and it put me in mine. We've both come out of it better.", {"stress": 2, "happiness": 1}, {"instinct": 3, "territory": 3})),
  C("Ignore it entirely",
    O("I turned my back and went to sleep. It took three weeks of my not noticing for us to be friends.", {"stress": 1}, {"belonging": -1, "bond": -1}, befriend=""),
    O("I decided it didn't exist. Then I noticed it eating from my bowl, and it became a very real animal.", {"stress": 4}, {"territory": 2}, rival=True)),
  roles=OWN, age=(1, 40), cooldown=10)

E("diet", "⚖️", "The chart",
  "The vet has a poster. It shows an animal in profile with a line down it. I am not on the good side of the line, and everybody in the room is looking at me kindly, which is worse.",
  {"pet": ["has_home", "owner", "hunger>=70"]},
  C("Accept the new regime",
    O("There was half a cup less, and a walk twice as long, and I was devastated for eleven days. And then, somehow, I could jump on the sofa again.", {"health": 3, "looks": 2, "happiness": -2}, {"hunger": -22, "fitness": 10, "obedience": 2}),
    O("It took me six months, and a great many raw carrots, but I got my knees back.", {"health": 4, "happiness": -1}, {"hunger": -18, "fitness": 8})),
  C("Persuade {o.first} otherwise",
    O("I did the look. A little extra went into the bowl 'just this once', and the vet's chart is now on the back of the pantry door.", {"happiness": 3, "health": -3}, {"hunger": 6, "bond": 2, "fitness": -4}),
    O("The look still works, but it works on the vet's hand-outs too, I find. A bit of progress was made.", {"happiness": 1}, {"hunger": -6, "fitness": 3})),
  C("Make my own arrangements",
    O("The neighbours have a bin. I will say nothing more.", {"happiness": 4, "health": -2}, {"hunger": 10, "instinct": 3, "bond": -2}),
    O("I was spotted in the neighbours' bins, and a note came over the fence, and {o.first} had to apologise. It was educational for everyone.", {"stress": 4}, {"hunger": 4, "mood": -3, "bond": -3})),
  roles=OWN, cooldown=8)

E("guest", "🧳", "The visitor",
  "A stranger is in the house with a suitcase. They smell of trains, and they are doing the thing people do when they are afraid of animals: they are holding very still and saying 'good doggy' to a cat.",
  HOME,
  C("Sit near them, quite calmly",
    O("I took my time, and by the third day they were scratching my ears with real attention. They left saying they might get one.", {"happiness": 4}, {"bond": 2, "belonging": 2}),
    O("They never really came round, but the house became very polite about it.", {"happiness": 1}, {"obedience": 2})),
  C("Make friends aggressively",
    O("I climbed onto their lap, then their shoulders, then, briefly, their head. It's a tactic. It is not their favourite tactic.", {"happiness": 3, "stress": -1}, {"bond": 1, "mood": -2}),
    O("I walked all over them and ate their toast. By Thursday they were fond of me, in the way you can be of an obstacle.", {"happiness": 2}, {"mischief": 1})),
  C("Hide until they go",
    O("Under the bed until Sunday. {o.first} brought me food and apologised. I was entirely fine.", {"stress": -2}, {"belonging": 1}),
    O("I hid, and it turned out they were afraid of me for nothing. We never met. It was a good arrangement.", {"stress": -1}, {})),
  roles=OWN, age=(1, 60), cooldown=6)

E("burglar", "🌙", "Three in the morning",
  "There is a sound at the back door that is not the house. Someone is working at it, very quietly, with a tool. {o.first} is asleep upstairs.",
  {"pet": ["has_home", "owner", "adult"]},
  C("Raise the alarm",
    O("I woke the street. The door gave up and a figure fled, and {o.first} came down the stairs in his socks with a lamp. In the morning there were policemen and a biscuit.", {"happiness": 5, "karma": 4}, {"heroics": 1, "bond": 6, "instinct": 3}),
    O("I barked, and he ran, and I barked for another hour in case he had thoughts of returning. The neighbours had opinions.", {"happiness": 3, "stress": 3}, {"heroics": 1, "bond": 4})),
  C("Go and see, silently",
    O("I met him in the hall. We had a conversation of staring. He left the way he came in, in a hurry, and I'll never know what he thought.", {"stress": 5, "karma": 2}, {"heroics": 1, "instinct": 4}),
    O("I went to look, and he had a bag of something that smelled of meat. I am ashamed to say I took it.", {"happiness": 2, "karma": -3}, {"hunger": 8, "bond": -3})),
  C("Stay put, under the bed",
    O("I did nothing, and the thing at the door went away by itself, and in the morning there was a scratch on the paint and a note on the fridge about a new lock. I was fine. That's the point of me.", {"stress": 3}, {"bond": -2}),
    O("Everything was taken. {o.first} said nothing to me, which was worse than shouting.", {"stress": 6, "happiness": -4}, {"bond": -5, "mood": -10})),
  roles=OWN, age=(2, 60), cooldown=12)

E("fire", "🔥", "Smoke",
  "Something is wrong with the air. There's a smell I've never smelled, and a high noise from the ceiling, and {o.first} is asleep, and they are not getting up.",
  {"pet": ["has_home", "owner", "adult"]},
  C("Wake them, by any means",
    O("I jumped on the bed, I barked in their ear, I pulled the cover. They woke up to a smoke-filled room and an animal trying to push them to the door. We got out. We got everyone out.", {"happiness": 6, "karma": 6, "health": -3}, {"heroics": 1, "bond": 12, "instinct": 3}),
    O("I got them to the door by hauling at their sleeve, one coughing step at a time. I was singed. They carried me out.", {"health": -6, "karma": 6}, {"heroics": 1, "bond": 10})),
  C("Run out and make a noise on the lawn",
    O("I went out through the cat flap and made the biggest noise of my life, until a neighbour came out and saw the glow. Help arrived.", {"karma": 4}, {"heroics": 1, "bond": 6, "instinct": 4}),
    O("I was out in the street barking at the wrong house. It took the fire brigade to find the right one.", {"stress": 8, "happiness": -2}, {"bond": 1})),
  C("Hide",
    O("I hid, as every animal knows to do. It was the wrong thing and it was the right thing. The alarm woke them without me.", {"stress": 8, "health": -2}, {"instinct": -2}),
    O("They found me under the bed, wrapped in a blanket, and carried me out into the cold air. I never told them I was sorry.", {"stress": 10, "happiness": -3}, {"bond": 2})),
  roles=OWN, age=(2, 60), cooldown=25, once=True)

E("road_child", "🛑", "The small one at the gate",
  "The littlest human has opened the gate and is walking, with great confidence and no shoes, toward the road. Nobody has noticed but me.",
  {"pet": ["has_home", "kids", "adult"]},
  C("Get in front of them",
    O("I stepped into the path and they walked into my side, and sat down, and laughed. I stayed there, a furry wall, till {o.first} came running with both hands out.", {"karma": 6, "happiness": 4}, {"heroics": 1, "bond": 8}),
    O("I blocked the way and then, when that wasn't enough, I took a sleeve in my teeth, very gently. I was not thanked at first. By evening, I was.", {"karma": 5, "stress": 4}, {"heroics": 1, "bond": 7})),
  C("Bark for help",
    O("The sound went through the whole street. {o.first} was at the gate in four seconds and the whole house was told, at length, that I was a good one.", {"happiness": 5}, {"heroics": 1, "bond": 6}),
    O("I barked, and nobody came. I kept barking. The child wandered back by herself, delighted, mud to the knees.", {"stress": 6}, {"bond": 1})),
  C("Follow, and keep an eye on it",
    O("I trotted at the child's heels, all the way to the kerb and back, and nothing happened. I think I'm not clever enough to know whether that was heroism.", {"stress": 4}, {"bond": 2, "instinct": 2}),
    O("A car braked, a long way off, and the child laughed. It was a close one, and I'll feel it for a month.", {"stress": 8}, {"bond": 1})),
  roles=OWN, cooldown=15)

E("storm_neighbour", "🧱", "Over the fence",
  "The animal next door has been getting bolder. Today there was a snout over the fence, and a remark. Everything I stand for is in question.",
  {"pet": ["has_home", "adult"]},
  C("Settle it with a stare",
    O("We held the stare for a long time. In the end it blinked, and went home, and I have not had a day's trouble since.", {"happiness": 3}, {"territory": 6, "instinct": 3}),
    O("The staring turned out to be a draw. We've an understanding, and it's slightly colder than a friendship.", {"stress": 2}, {"territory": 2}, rival=True)),
  C("Make an offering",
    O("I pushed a favourite toy under the gap. It was taken, examined and returned. We've been friends ever since.", {"happiness": 5}, {"belonging": 2}, befriend=""),
    O("My offering was eaten. The offender looked entirely unembarrassed and I admired it, in a way.", {"happiness": 2}, {"hunger": -2}, befriend="")),
  C("Go through the gap",
    O("There was a gap and I went through it. A garden I'd only ever smelled opened up like a country. I was back before dinner.", {"happiness": 5}, {"territory": 8, "instinct": 3, "escapes": 1}),
    O("There was a gap, and I was stuck in it, for an hour, in full view of everybody.", {"stress": 6, "happiness": -2}, {"territory": 4}, rival=True)),
  roles=OWN, age=(1, 40), cooldown=8)

E("travel", "🧳", "The suitcases",
  "The suitcases have come out of the cupboard. A few days later the house will smell of nowhere in particular, and everyone I love will be somewhere else.",
  {"pet": ["has_home", "owner"]},
  C("Go to the kennel",
    O("It was a clean place, with a lot of dogs, and a girl who sat with me at night and read the football results aloud. When they came back I had never been so glad to be collected.", {"stress": 4, "happiness": 1}, {"bond": 3, "obedience": 3}),
    O("It was loud and long and nobody smelled of home. I ate nothing for two days. When they came back, I held on to them for a minute.", {"stress": 8, "happiness": -3, "health": -2}, {"bond": 4})),
  C("Stay with the neighbour",
    O("The neighbour was a retired postman with a flask and a very comfortable chair. I was allowed in the garden and was given a sausage twice a day.", {"happiness": 4, "stress": -3}, {"hunger": 6, "territory": 3}),
    O("The neighbour forgot me, twice. A child from three doors down brought me a hot dog. I lived.", {"stress": 4, "health": -1}, {"hunger": -6, "instinct": 2})),
  C("Go along",
    O("A car, a beach, a lot of unusual smells, and a bed in a place that wasn't ours. I was exhausted, and entirely happy.", {"happiness": 8, "stress": -3}, {"bond": 6, "territory": 6}),
    O("I was sick in the car, twice. But the sea! It's so large. Nobody warned me about the sea.", {"happiness": 5, "health": -1}, {"bond": 4, "territory": 5})),
  roles=OWN, age=(1, 60), cooldown=6)

E("teeth", "🦷", "Open wide",
  "A vet with very large hands is going to look at my teeth. {o.first} is saying 'good boy' in a slightly higher voice than usual.",
  {"pet": ["has_home", "owner", "adult"]},
  C("Submit with dignity",
    O("It took four minutes and a great many tiny pokes, and then it was over, and I was given a treat. My teeth shine.", {"health": 3, "looks": 2}, {"obedience": 3}),
    O("I stayed very still and the vet said I was the best patient of the week. That's the second time that's happened, and nobody's told me what I won.", {"health": 3, "happiness": 2}, {"obedience": 4, "bond": 2})),
  C("Fight it",
    O("A great deal of clatter, a nurse in the corner and no one's hand unbitten. They managed it eventually, but I'd made a point.", {"health": 2, "stress": 6}, {"obedience": -3, "bond": -2}),
    O("I escaped through a door that shouldn't have been open and was found in reception, eating a plant. {o.first} did not meet the receptionist's eye.", {"stress": 4, "happiness": 2}, {"mischief": 1, "bond": -1})),
  C("Faint dramatically",
    O("I went limp. The vet said I was perfectly healthy. {o.first} carried me out like a baby, a little embarrassed, a little proud.", {"stress": 2}, {"bond": 3}),
    O("I lay on the floor and refused all offers. It took two nurses and a biscuit, and I had my way for as long as the biscuit lasted.", {"happiness": 2}, {"hunger": 3, "obedience": -1})),
  roles=OWN, cooldown=7)

E("old_friend_dies", "🕯️", "An empty spot",
  "{~The friend I'd had for years|The animal from the next garden|The one I grew up beside} isn't at the fence any more. There is a different smell there, and a different sound from the house, and I have understood.",
  {"pet": ["has_friend"]},
  C("Sit at the fence and wait",
    O("I sat there through the autumn. In the end a neighbour put a small stone at the post, and I put my nose to it, and that was the conversation.", {"happiness": -8, "stress": 6}, {"belonging": -3}),
    O("I sat and waited for the sound that wouldn't come. {o.first} sat with me. It's the first time I've seen a person understand that.", {"happiness": -6, "stress": 4}, {"bond": 5})),
  C("Look for company",
    O("I made the rounds of the street. A quick, shaky new acquaintance came up out of the hedge. It's not the same. It's something.", {"happiness": -2}, {"territory": 4}, befriend=""),
    O("I found nobody. The street has always been this wide, I think, but I hadn't noticed it before.", {"happiness": -5, "stress": 4}, {"territory": 2})),
  C("Go on as if nothing had happened",
    O("I ate my dinner and did my rounds. The grief came much later, in the quiet, in the middle of a nap.", {"happiness": -4}, {}),
    O("I ate, I slept, and I went on. The house noticed my not noticing, and was a bit gentler for a week.", {"happiness": -3}, {"mood": 3})),
  roles=OWN, age=(2, 60), cooldown=10)

E("gift", "🎁", "The toy",
  "{o.first} has come back from the shop with a bag. There is a toy in it. It squeaks, and it's the exact colour of my favourite thing, and I'm already in love.",
  HOME,
  C("Carry it everywhere",
    O("I carried it for three weeks, from room to room, and slept with it under my chin. It was torn to bits eventually, but it died doing what it loved.", {"happiness": 7}, {"bond": 4}),
    O("I carried it everywhere, and guarded it from the whole street. {o.first} found it under the sofa months later and wept a bit.", {"happiness": 6}, {"bond": 3, "territory": 2})),
  C("Destroy it immediately",
    O("The head came off in four minutes. I looked up with something that felt like triumph and also, faintly, grief.", {"happiness": 5, "stress": -4}, {"instinct": 3, "mischief": 1}),
    O("I disembowelled it with great concentration and was extremely proud, and ate a little of the stuffing, and was sick on the rug.", {"happiness": 4, "health": -1}, {"instinct": 3})),
  C("Ignore the toy and play with the bag",
    O("The bag was the better game. It had a crinkle and a hole. {o.first} laughed and said 'every time'.", {"happiness": 6}, {"bond": 3}),
    O("I got my head stuck in the bag. It was a harrowing and hilarious experience for everyone involved.", {"happiness": 3, "stress": 3}, {"bond": 2})),
  roles=OWN, cooldown=5)

E("argument", "🗯️", "Raised voices",
  "{o.first} and the other one are in the kitchen, and the voices are the wrong kind of loud. My stomach has gone cold. Nobody has looked at me in an hour.",
  {"pet": ["has_home", "partnered"]},
  C("Stand between them",
    O("I walked into the middle of it, sat on the floor and looked up. They stopped in the middle of a sentence. It was a draw, and a good one.", {"karma": 3, "stress": 5}, {"bond": 3, "mood": 6}),
    O("I got stepped on. It ended the argument, and a lot of apologising. I'm told that I'm the best thing in the house.", {"health": -2, "happiness": 2}, {"mood": 5, "bond": 3})),
  C("Leave the room",
    O("I took myself and my blanket to the spare room and waited for it to blow over. It did, in the end, with the particular silence of a decision.", {"stress": 4}, {"mood": -2}),
    O("I slipped out of the cat flap and walked the block twice. When I got back, it was over, and the house smelled of cooking.", {"stress": 1}, {"territory": 3})),
  C("Make as much noise as they do",
    O("We were all very loud. I felt much better afterwards and so did they, once they'd stopped and laughed.", {"stress": -2, "happiness": 2}, {"mood": 3, "obedience": -2}),
    O("I added a bark. It did not help. It did cause one of them to throw a shoe, in my general direction, and then to apologise.", {"stress": 5}, {"bond": -2, "mood": -4})),
  roles=OWN, cooldown=8)

E("photo", "📸", "The little rectangle",
  "{o.first} has been holding a small glowing rectangle toward my face for several days. People I have never met are apparently looking at me through it.",
  {"pet": ["has_home", "owner"]},
  C("Perform",
    O("I did the head tilt. I did the yawn. I did the one where I sneeze. A video of the sneeze has done something, and strangers are sending messages to {o.first}.", {"happiness": 6, "looks": 2, "fame": 3}, {"bond": 3}),
    O("A photo of me in a hat got passed around. It was hateful, and I'd do it again.", {"happiness": 4, "fame": 2}, {"bond": 2})),
  C("Sulk",
    O("I turned my back, and a photo of my back became well-liked. I can't win.", {"happiness": 1, "fame": 1}, {"obedience": -1}),
    O("I hid behind the sofa. They put up a photograph of the sofa, with a caption about me. It did very well.", {"happiness": 2, "fame": 1}, {})),
  C("Eat the rectangle",
    O("It broke. A repair was arranged. I was told off and, privately, admired.", {"happiness": 3}, {"mischief": 1, "bond": -2, "means": -2}),
    O("I took it off the arm of the sofa and carried it around the house like a prize. It was an expensive prize.", {"happiness": 3}, {"bond": -1, "means": -3, "mischief": 1})),
  roles=OWN, cooldown=9)

E("new_bed", "🛏️", "The new bed",
  "A new bed has arrived. It is made of memory foam and orthopaedic good intentions, and it cost an amount of money that was discussed in a low voice. It is, in all honesty, the wrong shape.",
  HOME,
  C("Use it",
    O("I turned around twice and lay down. It was, I'll admit, wonderful. My hips thanked me.", {"health": 2, "happiness": 4}, {"bond": 1}),
    O("It took me a week, and three treats, but I worked out the correct way to be in it. It's mine now.", {"happiness": 3, "stress": -3}, {"obedience": 1})),
  C("Sleep in the box it came in",
    O("The box was better. It was cardboard, and a bit crushed, and had the proper corners. {o.first} laughed and left it in the hall for a year.", {"happiness": 5}, {"bond": 2}),
    O("The box was entirely my choice, and I've made it clear that it has no replacement.", {"happiness": 4}, {})),
  C("Carry it to somewhere stranger",
    O("I dragged it from the hall to the bathroom to the garden door. It took two days. It's in the right place now, and nobody knows why.", {"happiness": 3}, {"instinct": 2}),
    O("I took it to the neighbour's, where, to be fair, it was a great success.", {"happiness": 2}, {"territory": 2, "mischief": 1})),
  roles=OWN, cooldown=8)

# ======================================================================== DOG
E("dog_park", "🌳", "The big park",
  "The dog park is a place of enormous information. There is a large animal in the middle of it, and he is making a sort of announcement about himself.",
  {"pet": ["dog", "has_home", "owner"]},
  C("Stand up to him",
    O("I stood very tall, and he was a bit more of a coward than he looked. We have the oak tree on Tuesdays now.", {"happiness": 4}, {"territory": 6, "instinct": 3}),
    O("It was a short fight and a long walk home. I have a scratch and a story, and the story will grow.", {"health": -3, "happiness": 1}, {"territory": 3, "instinct": 3}, rival=True)),
  C("Play the fool",
    O("I did a bow, a roll and a zoomie. Everyone laughed. He was so confused he joined in. We were friends by sundown.", {"happiness": 6}, {"fitness": 4, "belonging": 2}, befriend="dog"),
    O("I rolled over, and showed my belly to a Labrador, who took it as a comment on his character. It worked out.", {"happiness": 4}, {"obedience": 1}, befriend="dog")),
  C("Stay by {o.first}",
    O("I stayed on the lead, with my back to the large one, and was given a biscuit for being good. I'd made a choice, and the choice was biscuits.", {"happiness": 3}, {"bond": 4, "obedience": 3}),
    O("I never left their side, and spent the whole hour watching the others have fun. I'd call it a lesson, though I'm not sure what it was.", {"happiness": -1, "stress": 3}, {"bond": 3})),
  roles=OWN, age=(1, 30), cooldown=5)

E("dog_postie", "✉️", "The Man Who Comes Every Day",
  "He arrives at the same time each morning, puts something through the door and leaves. I have never been able to understand how he gets away with it. Today the flap is open.",
  {"pet": ["dog", "has_home", "owner"]},
  C("Defend the door to the last",
    O("I grabbed the letters, and that was that. I have a new ritual: a pile of torn envelopes by 9.", {"happiness": 4}, {"instinct": 3, "bond": -1, "mischief": 1}),
    O("I drove him off the porch, again. He's been using a box at the gate since. I count it as a win.", {"happiness": 4, "stress": -3}, {"instinct": 3, "territory": 2})),
  C("Greet him like a long-lost brother",
    O("I jumped, I wagged and I licked his hand. He gave me a biscuit from his pocket. I think this man is my best friend.", {"happiness": 6}, {"hunger": 3, "belonging": 2}),
    O("It was a friendship so fast and intense that he started going the long way round to avoid it. I was devastated for a day.", {"happiness": 3, "stress": 2}, {"instinct": 1})),
  C("Observe from the stairs",
    O("I watched him through the glass, as a scientist. The delivery pattern is regular. I made a note.", {"happiness": 2}, {"instinct": 4}),
    O("I watched, and I learned, and I decided that the Man Who Comes Every Day is probably all right.", {"happiness": 2}, {"instinct": 2, "obedience": 2})),
  roles=OWN, age=(1, 30), cooldown=10)

E("dog_lake", "🏞️", "The lake",
  "The path ends in a lake. The lake is, I discover, entirely made of water, and there's a stick in it.",
  {"pet": ["dog", "has_home", "owner"]},
  C("Go in after the stick",
    O("I swam, I was a seal, I was a hero. I returned with the stick and {o.first} with their trousers soaked to the knee.", {"happiness": 8, "health": 1}, {"fitness": 6, "territory": 3}),
    O("I went in and the water was deeper than the water has any right to be. I came out coughing, and ten minutes later, I went back in.", {"happiness": 6, "stress": 3}, {"fitness": 5, "instinct": 2})),
  C("Run the shoreline",
    O("A long, joyful run along the wet shingle with my whole body, ears flat, mud everywhere. I found a dead fish and rolled in it.", {"happiness": 7}, {"fitness": 5, "mischief": 1}),
    O("A long, joyful run along the shingle, which ended with an old man and a flask, who was kind, and who had a sandwich.", {"happiness": 6}, {"fitness": 4, "hunger": 4})),
  C("Watch the ducks",
    O("The ducks looked back. Neither of us was impressed. It was a good morning.", {"happiness": 3, "stress": -3}, {"instinct": 2}),
    O("I watched them for forty minutes, motionless, and was a statue. It was a respected position.", {"happiness": 2}, {"instinct": 3, "obedience": 2})),
  roles=OWN, age=(1, 30), cooldown=7)

E("dog_cone", "🛟", "The cone",
  "There is a plastic bowl around my head. I can't reach the thing I need to reach, and I keep hitting door frames.",
  {"pet": ["dog", "has_home", "owner", "ill"]},
  C("Bear it",
    O("I wore it with the dignity of a king in a ruff. It came off after a week, and the itch had gone.", {"health": 3, "stress": 3}, {"obedience": 3}),
    O("I wore it for ten days and learned to turn corners with some elegance. I even started to like the way it amplified sounds.", {"health": 3, "happiness": -1}, {"obedience": 3})),
  C("Get it off",
    O("It took me a night. I was triumphant, and then I had to be restrained at the vet's in the morning.", {"health": -2, "stress": 4}, {"obedience": -3, "instinct": 2}),
    O("I got it off, and the thing I was told not to touch was, it turned out, very touchable. The vet's face was a study.", {"health": -4, "stress": 5}, {"mischief": 1, "obedience": -3})),
  C("Make it a feature",
    O("I used it as a battering ram, a bowl and a hat. The household took photographs.", {"happiness": 3}, {"bond": 3}),
    O("I wore it to the door, to the fence, and into the kitchen. It was, I'll admit, a very good spoon.", {"happiness": 2}, {"bond": 2})),
  roles=OWN, age=(1, 30), cooldown=10)

E("dog_squirrel", "🐿️", "The Squirrel",
  "It is on the lawn. It has always been on the lawn. It has an expression of insolence. Today I am off the lead.",
  {"pet": ["dog", "has_home", "owner"]},
  C("Chase it up the tree",
    O("It went up the oak in a spiral and sat there, flicking its tail. I stayed under the tree for an hour. I'll be back.", {"happiness": 6, "stress": -4}, {"fitness": 4, "instinct": 3}),
    O("I chased it right across the road. {o.first} nearly had a heart attack. I'm not sorry, though I'm told I should be.", {"happiness": 7, "stress": 4}, {"instinct": 4, "bond": -3, "escapes": 1})),
  C("Wait for it to come closer",
    O("I stood still for twenty minutes. It came within a metre. I did not move. I felt like a hunter. I felt like a god.", {"happiness": 5}, {"instinct": 5, "obedience": 3}),
    O("I waited, and it did not come, and I got bored and went indoors. Patience is a muscle.", {"happiness": 2}, {"obedience": 3})),
  C("Make friends with it",
    O("I lowered my head and wagged. The squirrel considered this for a while and threw a nut at me. I think it was a gift.", {"happiness": 5}, {"belonging": 2, "instinct": 1}),
    O("I wagged. It chittered. We had a short conversation in which neither of us understood a word of the other. It was lovely.", {"happiness": 4}, {})),
  roles=OWN, age=(1, 30), cooldown=5)

E("dog_bone", "🦴", "The bone",
  "I have a bone. It is the best bone anybody has ever had. The question is where, in a world full of people who might take it, a bone should be.",
  {"pet": ["dog"]},
  C("Bury it in the garden",
    O("I dug for twenty minutes, in the exact right place, and covered it with my nose. I will remember where. I will.", {"happiness": 5}, {"instinct": 3, "territory": 3}),
    O("I buried it in the flowerbed. {o.first} found it the next spring, and the daffodils had never looked better.", {"happiness": 3}, {"instinct": 2, "bond": -1, "mischief": 1})),
  C("Guard it for the whole day",
    O("I guarded it, hour after hour, from the vacuum cleaner, the cat and the mailman. I was exhausted at nightfall and so was the bone.", {"happiness": 3, "stress": 3}, {"instinct": 3}),
    O("I growled at {o.first} when they came near. It was a shock for both of us, and we both pretended it hadn't happened.", {"stress": 6, "happiness": -2}, {"bond": -4, "obedience": -3})),
  C("Share it",
    O("I took it to the other dog's side of the fence, and for a morning, two of us gnawed from either end. I'm told this is called friendship.", {"happiness": 7}, {"belonging": 3}, befriend="dog"),
    O("I dropped it in front of {o.first}. It was the best present I could think of, and they held it in the air with both hands and said I was a good dog.", {"happiness": 6}, {"bond": 6})),
  roles=OWN, age=(0, 25), cooldown=7)

# ======================================================================== CAT
E("cat_box", "📦", "The box",
  "There is a box. It's a little small, but not too small. It is, I'm certain, mine.",
  {"pet": ["cat", "has_home"]},
  C("Get in",
    O("Perfect. The corners are right. I am entirely, magnificently in. For the next three hours, nothing can touch me.", {"happiness": 6, "stress": -6}, {}),
    O("I am a loaf in a box. I stayed there until the box fell over, and then I stayed there on its side.", {"happiness": 5, "stress": -4}, {"bond": 1})),
  C("Push it off the table",
    O("It fell with a hollow, flat bang. I looked at {o.first}. {o.first} looked at me. I did it again.", {"happiness": 5}, {"mischief": 1, "bond": -1}),
    O("It took me ten minutes to move it three inches, and another ten to get it off the edge. A great sense of purpose.", {"happiness": 4}, {"instinct": 2})),
  C("Sit next to it, ostentatiously",
    O("I sat beside the box for a day and refused to go in. It's not about the box. It's about knowing I could.", {"happiness": 3}, {"obedience": 1}),
    O("I sat next to it until a smaller cat arrived in the night and took it, and I've never forgotten.", {"happiness": -2, "stress": 2}, {"territory": -2})),
  roles=OWN, age=(0, 30), cooldown=5)

E("cat_mouse", "🐁", "A gift",
  "There is a mouse. It's a very small mouse, and it's alive, and it's in the hall. I have been waiting for this my whole life.",
  {"pet": ["cat", "has_home"]},
  C("Catch it and present it at {o.first}'s feet",
    O("I laid it, still warm, on the mat. {o.first} screamed. I didn't understand, but I took it as appreciation.", {"happiness": 5}, {"instinct": 5, "hunger": 2, "bond": 1}),
    O("I placed it carefully, on the pillow. It was my best work, and I was told so, in an extremely strange voice.", {"happiness": 4, "karma": -2}, {"instinct": 5, "bond": -1})),
  C("Play with it for hours",
    O("We had the best afternoon of my life, and it escaped, in the end, under the oven. It's still there. We have a rapport.", {"happiness": 6, "stress": -3}, {"instinct": 3, "fitness": 3}),
    O("I played with it until it stopped. I'm ashamed of how I felt, afterwards, and I'm not sure what to call it.", {"happiness": -2, "karma": -3}, {"instinct": 4})),
  C("Let it go",
    O("I opened the back door and looked away. It was the right thing to do, though nobody knows I did it.", {"karma": 4, "happiness": 2}, {"instinct": 1}),
    O("I watched it walk out under the skirting board. I kept my paw on the hole for a week, in case.", {"stress": 2}, {"instinct": 2})),
  roles=OWN, age=(0, 30), cooldown=6)

E("cat_flap", "🚪", "The Flap",
  "The flap has a little magnet and a new lock. The neighbour's cat has been coming in. Last night I found him in my bowl, with his whole face in it.",
  {"pet": ["cat", "has_home"]},
  C("Fight him",
    O("A short, high-pitched argument. I won, in the sense that he's gone and I bled less. The flap now clicks only for me.", {"happiness": 3, "health": -2}, {"territory": 6, "instinct": 3}),
    O("A long, bitter night. We both lost. We now share a bowl and a mutual hatred, which is a very stable arrangement.", {"stress": 5, "health": -3}, {"territory": 3}, rival=True)),
  C("Wait for him and share",
    O("I let him eat half, and he stayed for a wash, and now we are friends. The bowl is a restaurant.", {"happiness": 4}, {"hunger": -3, "belonging": 2}, befriend="cat"),
    O("He ate the lot. I licked the bowl clean and he looked at me, and we both understood.", {"happiness": 1}, {"hunger": -6, "instinct": 1}, befriend="cat")),
  C("Seal the flap myself",
    O("I sat in front of it, a living lock, for three nights. The visits stopped.", {"stress": 4}, {"territory": 4, "instinct": 2}),
    O("I brought a chair cushion and put it over the flap. It worked. I do not know how I will get out in the morning.", {"happiness": 2}, {"instinct": 3, "mischief": 1})),
  roles=OWN, age=(1, 30), cooldown=9)

E("cat_birds", "🐦", "The window",
  "On the sill, there is a place from which the entire garden can be observed. There are birds out there, in a feeder, and they have been laughing at me all week.",
  {"pet": ["cat", "has_home"]},
  C("Sit at the window and chatter",
    O("I made the noise. You know the noise. {o.first} came to look and laughed and filmed me. It's a talent.", {"happiness": 5, "stress": -3}, {"bond": 2}),
    O("I sat there, all morning, shivering with the whole of my body, and was happier than I've ever been.", {"happiness": 6, "stress": -3}, {"instinct": 2})),
  C("Go out and stalk them",
    O("I went through the flap, and under the hedge, and I was perfect. I got within a whisker of a sparrow. It was the best nothing that ever happened.", {"happiness": 5}, {"instinct": 5, "territory": 3}),
    O("I got one. I'm not proud of it, and I'm not ashamed of it, and {o.first} cried a bit, and put a bell on my collar the next day.", {"happiness": 1, "karma": -3}, {"instinct": 6, "hunger": 3, "bond": -2})),
  C("Knock the feeder down",
    O("It took a lot of effort. When it came down, the birds went to the next garden, and then I had no one to watch. I think I made a mistake.", {"happiness": -1}, {"mischief": 1}),
    O("I toppled it. The seed went everywhere and I had a very satisfying roll in it.", {"happiness": 4}, {"mischief": 1, "bond": -1})),
  roles=OWN, age=(1, 30), cooldown=8)

E("cat_carrier", "🧺", "The Basket",
  "It's the basket. There is no mistaking it. It has been left on the table in the hall, open, and the word 'vet' hangs in the air like a smell.",
  {"pet": ["cat", "has_home", "owner"]},
  C("Vanish",
    O("I went under the bed, behind the boiler, into a part of the loft that doesn't exist. They looked for an hour and gave up. I won this one.", {"stress": 4, "happiness": 2}, {"instinct": 3, "obedience": -2}),
    O("I got as far as the airing cupboard. {o.first} knew where to look. They always know where to look.", {"stress": 6}, {"instinct": 1, "bond": -1})),
  C("Go in with a grumble",
    O("I walked in with my head high and sat in it like a monarch in a sedan chair. I got a treat when I got home.", {"stress": 3, "happiness": 2}, {"obedience": 3, "bond": 3}),
    O("It was a miserable journey, and a worse examination, and a lot of vocal protest. But I got a treat, and a wet food I'd never had.", {"stress": 5}, {"obedience": 2, "hunger": 4})),
  C("Make it a game",
    O("I decided the basket was a cave and I'd found it by myself. When it was time to go, I was already in.", {"happiness": 3}, {"obedience": 4}),
    O("I sat in it for a week before the visit. By the time the visit came, it was part of the furniture, and the vet was a surprise.", {"happiness": 2}, {"obedience": 3, "bond": 2})),
  roles=OWN, age=(1, 30), cooldown=7)

# ======================================================================== RABBIT
E("rabbit_wire", "🔌", "The wire",
  "There is a thing behind the sofa that is long, thin and tastes of plastic. It has an interesting kind of springiness. I want to know more.",
  {"pet": ["rabbit", "has_home"]},
  C("Chew it",
    O("It gave a little fizz and a bang, and the lights went out. I was thrown across the room. I'm alive, but I will not forget.", {"health": -8, "stress": 8}, {"instinct": -1, "means": -3, "mischief": 1}),
    O("It was dead, as it turns out, which was lucky. I got the whole thing. It's a masterpiece of destruction.", {"happiness": 4}, {"mischief": 1, "bond": -1, "means": -2})),
  C("Leave it for later",
    O("I left it, and made a note. A rabbit with a plan is a dangerous thing.", {"happiness": 1}, {"instinct": 2}),
    O("I pulled a corner of the carpet instead. It's less satisfying, but it's not dangerous.", {"happiness": 2}, {"mischief": 1})),
  C("Tell {o.first}",
    O("I thumped. I thumped three times, very loud. {o.first} came running and moved it. I was given a carrot. I'd call that excellent teamwork.", {"happiness": 3}, {"bond": 4, "instinct": 2}),
    O("I thumped, and was ignored, and thumped again, and in the end they looked at the wire. They put a plastic guard on it. It was a good guard, but a better wire.", {"happiness": 1}, {"bond": 2})),
  roles=OWN, age=(0, 15), cooldown=8)

E("rabbit_garden", "🌿", "Out on the lawn",
  "The hutch door is open, and the grass is enormous. There is a sky, and no ceiling, and a smell that makes my whole body feel like a coil.",
  {"pet": ["rabbit", "has_home"]},
  C("Binky",
    O("I leapt, twisted in mid-air, kicked my back feet and landed backward. Nobody has ever been so alive.", {"happiness": 9, "stress": -6}, {"fitness": 5}),
    O("I did the biggest binky of my life and landed in the water bowl. It was worth it.", {"happiness": 8}, {"fitness": 4})),
  C("Dig out",
    O("I tunnelled under the fence in about twenty minutes, in a quiet corner. The other side was the same grass, but somehow more interesting.", {"happiness": 5}, {"territory": 6, "escapes": 1}),
    O("I got as far as the herb bed, which was an excellent trip, and then {o.first} came and picked me up, laughing, with soil on my nose.", {"happiness": 4}, {"territory": 4, "escapes": 1, "bond": 1})),
  C("Hide under the shrub",
    O("I found a place under the hydrangea where the air was green. I stayed there till the light changed.", {"stress": -5, "happiness": 3}, {"instinct": 2}),
    O("I spotted a shape in the sky. I did not move for an hour. It was a pigeon.", {"stress": 4}, {"instinct": 3})),
  roles=OWN, age=(0, 15), cooldown=6)

E("rabbit_fox", "🦊", "The thing in the night",
  "There is a smell outside the hutch that I know in my bones. It does not belong to anything I have ever met. It circles.",
  {"pet": ["rabbit", "has_home"]},
  C("Freeze",
    O("I did not move, and I did not breathe, and it went away. By morning there was a scratch on the wire and a hair on the latch. I never found out how I knew.", {"stress": 10, "health": -2}, {"instinct": 4}),
    O("I held still the whole night. {o.first} found me at dawn, stiff as a statue, and carried me indoors with something like reverence.", {"stress": 8}, {"bond": 5, "instinct": 3})),
  C("Thump a warning",
    O("I thumped loudly enough to wake the house, and the light came on, and the thing in the night went somewhere else.", {"karma": 2, "stress": 4}, {"bond": 4, "instinct": 3, "heroics": 1}),
    O("I thumped. Nobody woke. It was a very long night. In the morning, the hutch latch was bent.", {"stress": 10, "health": -3}, {"instinct": 3})),
  C("Run to the back of the hutch",
    O("I squeezed into the farthest corner, and flattened. Nothing happened. I'm very small, and that's an art.", {"stress": 6}, {"instinct": 2}),
    O("I ran, in the dark, into the end of the hutch, and knocked myself silly. The thing outside went away anyway.", {"stress": 6, "health": -2}, {})),
  roles=OWN, age=(0, 15), cooldown=12)

# ======================================================================== PARROT
E("parrot_word", "🗣️", "A word I wasn't meant to learn",
  "There is a word that {o.first} says when something drops. It has a lovely shape. I have been practising it, at low volume, for weeks.",
  {"pet": ["parrot", "has_home", "owner"]},
  C("Say it at dinner, to the visitors",
    O("I said it in {o.first}'s exact voice. The vicar dropped his fork. It was the greatest moment of my career.", {"happiness": 8}, {"mischief": 1, "bond": -2, "mood": -3}),
    O("I said it during a toast. The room went quiet, then it broke into a roar of laughter, and {o.first} was crimson and weeping.", {"happiness": 7}, {"bond": 1, "mischief": 1})),
  C("Save it for a quiet moment",
    O("I waited for the exact right second, and then, in the middle of the evening news, I said it. It had never been funnier.", {"happiness": 6}, {"instinct": 2}),
    O("I used it at three in the morning, in a whisper, to myself. It sounded much better in the dark.", {"happiness": 3}, {"instinct": 1})),
  C("Say it only when {o.first} drops something",
    O("I get it right every time. It is, I think, the only helpful thing I do. {o.first} says it makes the day better.", {"happiness": 5}, {"bond": 4, "obedience": 2}),
    O("The timing was impeccable, for months. And then {o.first} stopped dropping things, and I had to do it for them.", {"happiness": 3}, {"mischief": 1, "bond": 1})),
  roles=OWN, age=(1, 60), cooldown=8)

E("parrot_window", "🪟", "The open window",
  "The window is open. The sky is out there and it is the exact blue of the thing I am for. {o.first} has gone to answer the door.",
  {"pet": ["parrot", "has_home", "owner"]},
  C("Go out",
    O("I flew. I flew for twenty minutes, over the roofs, over the park, and then something in me, quite quietly, remembered the cage, and the voice, and I came home.", {"happiness": 9, "stress": -5}, {"territory": 8, "escapes": 1, "bond": 3}),
    O("I flew out and landed in a tree. Then it got dark, and I couldn't get down. It took three hours, a ladder and a neighbour with a net.", {"happiness": 3, "stress": 10}, {"territory": 6, "escapes": 1, "bond": -1})),
  C("Sit on the sill and call to the sparrows",
    O("I told them a lot of things I'd learned. They didn't understand, but they stayed for a while. I felt like a diplomat.", {"happiness": 5}, {"instinct": 2}),
    O("I used my doorbell voice, and a sparrow came to inspect it. We've an arrangement now.", {"happiness": 4}, {"instinct": 2, "belonging": 1})),
  C("Go back to the perch",
    O("I thought about it for a long time, and went back to my perch, and ate a nut. I'm told it was the right decision.", {"stress": -1}, {"obedience": 3, "bond": 2}),
    O("I went back to my perch, because it was safe. It's not a bad thing to be safe.", {"stress": -2}, {"bond": 1})),
  roles=OWN, age=(1, 60), cooldown=9)

E("parrot_stress", "🪶", "The plucking",
  "I have been taking out my own feathers. It started as a tidy and became a habit, and the habit has become a kind of voice, and I don't know how to stop.",
  {"pet": ["parrot", "has_home", "owner", "stress>=50"]},
  C("Let {o.first} help",
    O("{o.first} changed the cage, added a mirror, a swing, a forage box and a cover for the night. Over a few months, it stopped.", {"stress": -8, "looks": 3, "happiness": 4}, {"bond": 5, "means": -2}),
    O("The vet found the cause. A change in diet, a lot more company, and the feathers began to come back.", {"health": 3, "stress": -6}, {"bond": 3})),
  C("Keep going",
    O("I kept going. It was the only thing that was mine. By winter, I looked like a plucked chicken, and I couldn't tell you why.", {"stress": 6, "looks": -6, "happiness": -4}, {"bond": -2}),
    O("It got worse before it got better. It never fully got better.", {"stress": 5, "looks": -5}, {})),
  C("Find another way to scream",
    O("I screamed at the microwave, at the doorbell and at the radio. It's a cheap, noisy release, and I'm better for it.", {"stress": -4, "happiness": 2}, {"mood": -4}),
    O("I took to imitating the smoke alarm. It lasted a month. Everyone is very tired.", {"stress": -2}, {"mood": -6, "bond": -2})),
  roles=OWN, age=(2, 60), cooldown=9)

# ======================================================================== HORSE
E("horse_farrier", "🔨", "The Farrier",
  "A man with a leather apron and a small, shaped fire has come to the yard. He wants my foot. I have four, and I'm relying on all of them.",
  {"pet": ["horse", "has_home", "owner"]},
  C("Stand like a statue",
    O("I stood without moving a muscle, while he did his work. He told {o.first} I was the best-behaved animal he'd shod in a year.", {"happiness": 3}, {"obedience": 5, "bond": 3}),
    O("I stood still, and it was boring, and it was fine. The new shoes ring on the cobbles like little bells.", {"happiness": 2, "health": 1}, {"obedience": 4})),
  C("Lean on him",
    O("I put my whole weight on his back. He swore. He laughed. He called me a fat lump, in an affectionate voice.", {"happiness": 3}, {"bond": 2, "mischief": 1}),
    O("I leaned, he pushed, we both laughed. Eventually, my foot went down, and so did his temper.", {"happiness": 2}, {"obedience": -1})),
  C("Pull my foot away",
    O("I pulled away, over and over, until he'd stopped asking. {o.first} had to ask him to come back another day.", {"stress": 4}, {"obedience": -4, "bond": -2}),
    O("I took my foot away and he asked nicely, and then not nicely, and then very nicely again. It took an hour.", {"stress": 5}, {"obedience": -2})),
  roles=OWN, age=(2, 50), cooldown=7)

E("horse_bag", "🛍️", "The Plastic Bag",
  "There is a plastic bag in the hedge, moving. It's the colour of nothing found in nature. It makes a dry, bright sound. It has seen me.",
  {"pet": ["horse", "has_home"]},
  C("Bolt",
    O("I went from a standing start to full gallop without noticing, with {o.first} still on my back. We covered a mile before I remembered who I was. I was entirely ashamed.", {"stress": 8, "happiness": -2}, {"fitness": 3, "bond": -2, "instinct": 2}),
    O("I spun and went the other way at speed and was caught in the gateway, with my eyes rolling. {o.first} patted my neck and said it was only a bag.", {"stress": 6}, {"bond": 2, "instinct": 2})),
  C("Face it",
    O("I walked up to it, with my ears forward, and snorted at it. It was a bag. It was a bag. I have never been so brave.", {"happiness": 4, "karma": 2}, {"obedience": 4, "instinct": 3, "bond": 3}),
    O("I walked to it slowly, one foot at a time. It fluttered. I stepped back. Then I stepped forward. It took a while, but I won.", {"happiness": 3}, {"obedience": 3, "instinct": 2})),
  C("Let {o.first} handle it",
    O("{o.first} led me past it, with a calm hand on my neck, and talked to me about nothing at all. I forgot about the bag by the next hedge.", {"stress": -3}, {"bond": 5, "obedience": 3}),
    O("{o.first} got down and took the bag out of the hedge and showed it to me. I sniffed it. It had no smell. It was a very disappointing enemy.", {"happiness": 2}, {"bond": 4})),
  roles=OWN, age=(2, 50), cooldown=7)

E("horse_gate", "🛣️", "The latch",
  "I have been looking at the latch for three weeks. It's a simple thing, of a kind that a horse can learn, if the horse is committed, and I am committed.",
  {"pet": ["horse", "has_home", "owner"]},
  C("Open it and go for a wander",
    O("The latch gave, and so did the gate. I walked the lane and into the next field, where there was a whole other kind of grass. It was a good afternoon, and the fence-mender came the next morning.", {"happiness": 8}, {"territory": 8, "escapes": 1, "bond": -2}),
    O("I got as far as the road before somebody saw me. It was a long walk home with a stranger holding my halter, and they were extremely nice about it.", {"happiness": 4, "stress": 5}, {"territory": 5, "escapes": 1})),
  C("Open it and let another horse out",
    O("I opened the gate for my friend, and the pair of us were out in the lane before the sun was up. It was the biggest party the yard has ever had.", {"happiness": 8}, {"belonging": 3, "escapes": 1, "mischief": 1}, befriend="horse"),
    O("I opened it, and the friend ran off, and I stayed. I was told I'd been a good influence, in the end.", {"happiness": 3, "karma": 2}, {"obedience": 2})),
  C("Leave it alone",
    O("I thought about it, and decided it wasn't worth the trouble. It was, in its own way, a victory.", {"stress": -1}, {"obedience": 2}),
    O("I decided to keep it as a secret I could use later. It's very useful to have an option.", {"happiness": 2}, {"instinct": 2})),
  roles=OWN, age=(3, 50), cooldown=9)

# ======================================================================== STREET / SHELTER / MILL / WORKING / SHOW / FARM
E("street_winter", "❄️", "A hard night",
  "The cold has come down off the hills. The ground is iron. I know four places that might be warm and I do not know if any of them is still there.",
  {"pet": ["homeless"]},
  C("Go to the stairwell behind the pharmacy",
    O("The door was ajar, and the heating pipe was warm against my back. A woman came down in the morning, saw me and said nothing at all. She put a bowl on the step.", {"health": -1, "happiness": 3}, {"hunger": 8, "belonging": 5}),
    O("The door was locked and a man came out with a broom and I was moved on. I walked till light.", {"health": -4, "stress": 6}, {"hunger": -6, "instinct": 3})),
  C("Find another animal and share heat",
    O("A big grey dog under a bridge made room without a word. We lay all night with our noses in each other's fur. In the morning, he was still there, and so was I.", {"health": -1, "happiness": 4}, {"belonging": 4}, befriend="dog"),
    O("It turned out to be a cat, and she wasn't pleased, but she let me stay. We both survived. I won't say it was a friendship.", {"happiness": 1}, {"instinct": 3}, befriend="cat")),
  C("Keep moving all night",
    O("I walked until the sky went grey. I was exhausted, but alive, and in the morning I knew the whole neighbourhood in a new way.", {"health": -3, "stress": 5}, {"territory": 6, "instinct": 4, "fitness": 3}),
    O("I walked, and I walked, and at four in the morning I found a delivery van with its engine ticking. It was warm for exactly one hour.", {"health": -2, "stress": 4}, {"territory": 4, "instinct": 3})),
  age=(0, 60), cooldown=4)

E("street_net", "🥅", "The van with the net",
  "There's a white van at the end of the street. Two people have got out. One of them is carrying a pole with a loop on the end. I've seen this before. It didn't go well for the last one.",
  {"pet": ["homeless"]},
  C("Run, and use every alley",
    O("I went through the cut by the bakery, under the fence at the school and over the wall at the yard. They were still looking for me when I fell asleep in a skip.", {"stress": 8}, {"instinct": 5, "territory": 4, "fitness": 3}),
    O("I ran, and they were quicker than I thought. I got away with a nick on the shoulder and a new fear of vans.", {"health": -3, "stress": 8}, {"instinct": 4})),
  C("Let them take me",
    O("The loop slid on, and I let it, and I was walked up the ramp into a dark, warm van. It smelled of every dog in the county. And then, a day later, they gave me a bowl.", {"happiness": 2, "stress": 6}, {"hunger": 12, "belonging": 4}, home="shelter"),
    O("The net came down. It was awful, and I was awful in it. They were kind, and I was too frightened to notice.", {"stress": 10}, {"instinct": -2, "hunger": 8})),
  C("Hide, and wait for them to leave",
    O("I got under a parked car and breathed through my nose. They went through the alley, they went past the car, and I stayed, and I stayed, and I stayed.", {"stress": 6}, {"instinct": 5}),
    O("I was found. A boy lay on his stomach and looked me in the eye, and then stood up and told the van there was nothing there. I am in his debt.", {"happiness": 4, "stress": 4}, {"belonging": 3, "instinct": 3})),
  age=(0, 60), cooldown=8)

E("street_butcher", "🥩", "The butcher",
  "There's a man in the market with a white apron and a bone in his hand, and he's looking at me in a way that is different from the others. He's looking at me like a customer.",
  {"pet": ["homeless", "hungry"]},
  C("Sit and wait",
    O("I sat on the pavement, quite still. He came out at the end of the day with a parcel of scraps and a kind word. I'm told that he did it every day for years.", {"happiness": 6}, {"hunger": 18, "belonging": 5, "bond": 3}),
    O("He gave me a bone, once, and then a sausage, and then he moved to another town. I'll not forget him.", {"happiness": 4}, {"hunger": 12, "belonging": 2})),
  C("Steal the parcel",
    O("It was an old trick and it worked. I was a hundred yards down the alley before the shout. I wasn't proud but I was fed.", {"happiness": 2, "karma": -2}, {"hunger": 16, "instinct": 4}),
    O("It didn't work. He had a long arm. I got a mouthful, and a boot, and I learned a lesson that I'll carry in my ribs.", {"health": -4, "stress": 5}, {"hunger": 5, "instinct": 2})),
  C("Follow him home",
    O("I followed him to a green door, and a woman at the door said 'no' and then 'oh'. I was given a blanket and a bowl in the passage and I never left.", {"happiness": 8, "stress": -6}, {"belonging": 6}, adopt="A butcher with a green door took a stray home."),
    O("I followed him a long way, and he led me through three streets and then stopped, and lifted his hand in a small wave. I don't know what it meant.", {"happiness": 2}, {"territory": 4})),
  age=(0, 60), cooldown=10)

E("street_gang", "🐕‍🦺", "The pack on Mill Road",
  "There's a gang of dogs under the railway arch. They have a leader, a scarred yellow one with a limp. I've been walking past their arch for a month. Today he is standing in the road.",
  {"pet": ["homeless", "dog"]},
  C("Challenge him",
    O("It took half the night. I'm bleeding and he's bleeding. In the grey of the morning, he lowered his head. I led the pack for a year.", {"health": -5, "happiness": 4}, {"territory": 12, "instinct": 6}),
    O("He beat me, fair and square. I limped away with a torn ear. I'll be back, in a year, when he's old.", {"health": -6, "stress": 6}, {"territory": -2, "instinct": 3}, rival=True)),
  C("Ask to join",
    O("I lowered my head and dropped my tail and came in sideways. It took a month for them to stop looking at me. By autumn I was one of the pack, the last in line, and I have never felt safer.", {"happiness": 6, "stress": -4}, {"belonging": 7, "territory": 5}, befriend="dog"),
    O("They let me in at the edge. It was cold at the edge. But it was in.", {"happiness": 2}, {"belonging": 3}, befriend="dog")),
  C("Avoid them",
    O("I changed my route. A bit longer, a bit colder and a bit safer. There are other streets.", {"stress": 2}, {"instinct": 2}),
    O("I changed my route, and every road I took led to somebody's bad mood. I'm not certain I made a good choice.", {"stress": 4}, {"territory": -2})),
  age=(1, 30), cooldown=10)

E("shelter_volunteer", "🧣", "Tuesday",
  "On Tuesdays, a woman in a woolly hat comes to the kennel and takes me out into the yard. She smells of tea. She says I'm a 'good girl' in a voice she doesn't use for the others.",
  {"pet": ["in_shelter"]},
  C("Stick close to her",
    O("I walked at her left knee. She said, out loud, that she wished she could take me home, and then she said a sentence about a flat and a landlord. I put my head in her hand.", {"happiness": 5}, {"bond": 6, "obedience": 3}),
    O("I pushed my face into her coat. She laughed, and cried a little. I've never been so happy and so sad at the same time.", {"happiness": 3}, {"bond": 5})),
  C("Show off for the visitors",
    O("I did every trick I knew, in the yard, for the couple at the fence. They took a photograph. They took my card. They didn't come back.", {"happiness": 2, "stress": 3}, {"obedience": 3}),
    O("I sat as nicely as I have ever sat. A man in a green anorak looked at me for a minute, then said, 'Maybe next week.'", {"happiness": 1, "stress": 4}, {"obedience": 3})),
  C("Retreat to the corner",
    O("I went to the back of the kennel and turned my face to the wall. The woman waited, then sat on the floor in front of the bars. We stayed like that for an hour.", {"stress": -2}, {"bond": 3}),
    O("I turned away, and nobody came, and eventually the lights went out.", {"stress": 4, "happiness": -3}, {"bond": -2})),
  age=(0, 60), cooldown=6)

E("shelter_cough", "🤧", "Something in the kennels",
  "A cough has started in the end block, and now it's here, and now it's mine. The volunteers wear masks. The vet is in a lot.",
  {"pet": ["in_shelter"]},
  C("Rest and take the medicine",
    O("They gave me a little pill in a lump of cheese. I coughed for two weeks and then, quite suddenly, I didn't.", {"health": 2, "stress": 3}, {"obedience": 3}),
    O("It was a long month, and I was moved to a quiet room with a heater. I was nursed back by a boy of sixteen on a placement.", {"health": 3, "happiness": 2}, {"bond": 4})),
  C("Fight it on my own",
    O("I coughed, I slept, I ignored the pills in the cheese. It turned into a chest infection, and I was very ill indeed.", {"health": -9, "stress": 8}, {"obedience": -2}, illness="a chest infection"),
    O("I recovered, in the end, though it left a rattle I'll always have.", {"health": -4, "stress": 5}, {})),
  C("Make friends in the sick bay",
    O("Three of us in a row of cages with a heater between us. We coughed in rhythm. It's one of the nicest weeks of my life.", {"happiness": 5}, {"belonging": 3}, befriend=""),
    O("I shared a bed with a small, scared cat who purred when I coughed. We were both discharged in the same week.", {"happiness": 4}, {"belonging": 2}, befriend="cat")),
  age=(0, 60), cooldown=8)

E("mill_hands", "🧤", "Hands",
  "A person is putting a hand into my kennel. There's a smell on it I don't know, of soap, of grass. I have only ever known hands that smelled of rubber.",
  {"pet": ["origin:mill", "in_shelter"]},
  C("Shrink back",
    O("I backed into the wall, trembling, and waited. The hand stayed still. It stayed still for ten minutes. It was the first time a hand had ever done that.", {"stress": 6}, {"bond": 3}),
    O("I growled, and they withdrew. The next day, they came back, with a bowl, and put it down and left.", {"stress": 4}, {"bond": 2, "instinct": 2})),
  C("Sniff it",
    O("It smelled of food and a dog I didn't know and something else, something warm. I put my nose to it. It was the beginning of something.", {"happiness": 5, "stress": -4}, {"bond": 6, "obedience": 2}),
    O("I sniffed it cautiously, and a finger scratched the side of my neck. I had no idea that was a thing.", {"happiness": 5}, {"bond": 5})),
  C("Bite",
    O("I bit. It wasn't hard. She said 'ow' and then, 'it's all right', and she stayed. I have never been so ashamed or so confused.", {"stress": 8}, {"bond": 3, "obedience": -2}),
    O("I bit, and they left, and that was that. I deserved the next three weeks.", {"stress": 8, "happiness": -4}, {"bond": -2})),
  age=(0, 6), cooldown=6)

E("working_first", "🎽", "The first real job",
  "The jacket goes on. It has a badge. All of my life, the handler has told me this day was coming, and now it is here, and the people at the gate are talking in low voices.",
  {"pet": ["origin:working", "adult"]},
  C("Be focused, as trained",
    O("I did exactly what I was taught, and nothing more. The handler said nothing at all, then handed me my toy, and I understood that this was the highest praise there is.", {"happiness": 6, "stress": 3}, {"obedience": 6, "bond": 4}),
    O("I got through the afternoon without a mistake. I was so tired that evening I slept in the van with my head on his boot.", {"happiness": 4}, {"obedience": 5, "bond": 3})),
  C("Get distracted by a squirrel",
    O("A squirrel went by. I was supposed to be on a scent, and I followed the squirrel. We lost the scent. We found the squirrel. Nobody was pleased.", {"stress": 6, "happiness": 3}, {"obedience": -3, "instinct": 2}),
    O("There was a good smell by the bins. I took a moment, and the whole exercise was a minute behind. I got a stern word, and a long walk.", {"stress": 4}, {"obedience": -1})),
  C("Show initiative",
    O("I went left when I was told to go right. And there, in the long grass, was exactly what we were looking for. The handler stared, then knelt and held my face in both hands.", {"happiness": 8, "karma": 5}, {"heroics": 1, "instinct": 5, "bond": 6}),
    O("I went left when I was told to go right, and it was a mistake, and I got a firm 'no'. But my nose had been right.", {"happiness": 1, "stress": 4}, {"instinct": 4, "obedience": -2})),
  age=(1, 12), cooldown=8)

E("show_ring", "🎀", "The ring",
  "There is a ring, a rope and a woman with a clipboard. I've been bathed three times this week, brushed until I shine and fed exactly what the breeder says. Everyone is nervous. I can smell it.",
  {"pet": ["origin:show", "adult"]},
  C("Give them everything",
    O("Head high, tail up, a perfect stack. The judge's hand ran down my back, and I stood like a rock. They gave me the ribbon. They gave me the cup.", {"happiness": 8, "looks": 2}, {"titles": 1, "obedience": 4, "bond": 3}),
    O("I did it all. I did it all and I came second. The rosette is the colour of a dried tomato, and it's the best I've ever had.", {"happiness": 5}, {"obedience": 4, "bond": 2})),
  C("Do it my way",
    O("I did a spin at the corner. The crowd roared. The judge hid a laugh. Nobody won, but I'd been seen.", {"happiness": 6, "stress": -3}, {"obedience": -3, "bond": 2}),
    O("I did the thing with my tongue, and the judge wrote something down. It was not in my favour.", {"happiness": 3, "stress": 3}, {"obedience": -3})),
  C("Lie down in the middle of the ring",
    O("I lay down. I put my head on my paws. The judge, a woman in her seventies, bent down and scratched my ear. I was disqualified, and I got a rosette for 'Best Personality'.", {"happiness": 6}, {"obedience": -4, "bond": 2}),
    O("I lay down, and refused to get up. I was carried out. I didn't mind, though the breeder did.", {"happiness": 3, "stress": 4}, {"obedience": -4, "bond": -3})),
  age=(1, 14), cooldown=6)

E("farm_tractor", "🚜", "The tractor",
  "The tractor starts at five. It always starts at five. It makes a noise, and a smell, and a dust, and the farmer rides it about the field like a king on a very loud horse.",
  {"pet": ["home:farm"]},
  C("Chase it",
    O("I ran after it, round the whole field, barking. The farmer waved. It was a rhythmic, satisfying sort of day.", {"happiness": 7}, {"fitness": 5, "instinct": 2}),
    O("I got too close to the wheel, and the farmer shouted, and I had a scare I'll remember. I've been much more careful since.", {"stress": 6, "health": -2}, {"instinct": 4})),
  C("Ride along",
    O("I jumped up beside him in the cab, and I sat there, on the toolbox, all morning, watching the world roll past. It's the best view in the county.", {"happiness": 8}, {"bond": 5, "territory": 6}),
    O("I got on the trailer, and fell asleep, and woke up three fields away. They fetched me by mid-afternoon.", {"happiness": 3}, {"territory": 5, "escapes": 1})),
  C("Stay away",
    O("I stayed in the barn, safe among the hay. The tractor can be a very scary friend.", {"stress": -2}, {"instinct": 1}),
    O("I found a quiet corner of the field and lay in the long grass. I heard it all day, and it never found me.", {"happiness": 2}, {"instinct": 2})),
  age=(0, 25), cooldown=8)

E("lost_stranger", "🔍", "A kind stranger",
  "I've been out for a long time. A person has stopped on the pavement. They're holding something out in their hand. It smells of ham.",
  {"pet": ["lost"]},
  C("Go to them",
    O("I walked up and ate the ham. They looked at my collar, then took out their phone, and called a number. I heard a voice I'd have known anywhere.", {"happiness": 12, "stress": -10}, {"bond": 8, "belonging": 10}, found=True),
    O("I took the ham and I went to them, and they lifted me into their car. It smelled of other animals. It took two days to find the right house.", {"happiness": 5, "stress": -4}, {"belonging": 3}, found=True)),
  C("Keep my distance",
    O("I watched them from beyond a car, and they left the ham and went. I ate it afterwards. It was nice.", {"stress": 2}, {"hunger": 6, "instinct": 3}),
    O("I kept my distance, and they gave up, and I walked on, hungry. I'm still not sure what I was afraid of.", {"stress": 4, "happiness": -2}, {"hunger": -4})),
  C("Take the ham and run",
    O("I snatched it, and ran. I got three streets away and sat down in a doorway and ate the whole thing. Delicious. I've never felt so alone.", {"happiness": 2, "stress": 3}, {"hunger": 10, "instinct": 3}),
    O("I took the ham and ran, and they shouted, 'it's all right!' I did not believe them.", {"stress": 6}, {"hunger": 8, "instinct": 2})),
  age=(0, 60), cooldown=5)

E("senior_stairs", "🪜", "The stairs",
  "The stairs have changed. They have always been there, but this year they're taller, and my back legs have started to make a decision about them that I haven't agreed to.",
  {"pet": ["senior", "has_home", "owner"]},
  C("Keep going up on my own",
    O("It took a long time, and I did every stair. I was proud for about a minute, and then very tired. {o.first} watched from the bottom without saying anything.", {"health": -2, "happiness": 3}, {"bond": 2, "fitness": 2}),
    O("I fell, on the fourth stair. I wasn't hurt, but I was frightened. {o.first} came running and said my name very softly.", {"health": -4, "stress": 6}, {"bond": 3})),
  C("Be carried",
    O("{o.first} picked me up like a baby. I was embarrassed for half a second and then I was delighted. I got a clear view of the whole landing.", {"happiness": 5, "stress": -3}, {"bond": 6}),
    O("They carried me up every night for a year. It's the nicest thing anyone has ever done for me.", {"happiness": 6}, {"bond": 7})),
  C("Move my bed downstairs",
    O("I moved into the sitting room, to a bed by the fire. I can hear everything that goes on. I'm in the middle of the house now, and I wouldn't change it.", {"happiness": 4, "stress": -4}, {"belonging": 4}),
    O("I took over the sofa. {o.first} moved to the armchair. I'm sorry, and I'm not.", {"happiness": 3}, {"bond": 3, "obedience": -1})),
  roles=OWN, age=(5, 60), cooldown=6)

E("senior_best_day", "🌅", "A good day",
  "I woke up and everything worked. My back legs, my eyes, my nose. The light came in on the floor in a long rectangle, and the whole house smelled of toast.",
  {"pet": ["senior", "has_home", "owner"]},
  C("Go for a long walk",
    O("We went further than we'd gone in two years. I smelled everything. I met everyone. I came home and slept for eleven hours with my paws twitching.", {"happiness": 9, "health": -1}, {"bond": 5, "territory": 6}),
    O("We went to the beach. I stood in the water, and it was cold and loud, and I was young for an hour.", {"happiness": 10}, {"bond": 6, "fitness": 3})),
  C("Lie in the sun and be near them",
    O("I lay there, in the warm, while {o.first} did the crossword. They read me the clues. I knew none of the answers and liked them all.", {"happiness": 8, "stress": -6}, {"bond": 6}),
    O("A day of being there. Nothing else. It's an art, and I've practised for years.", {"happiness": 7, "stress": -5}, {"bond": 5})),
  C("Eat everything",
    O("I ate the lot. I don't know how many biscuits. I was sick, and I'm told it was a risk worth taking.", {"happiness": 7, "health": -3}, {"hunger": 14}),
    O("They gave me a piece of everything they had. It was a feast. They watched me eat with eyes that were a bit wet.", {"happiness": 8}, {"hunger": 10, "bond": 4})),
  roles=OWN, age=(5, 60), cooldown=6)

E("litter", "🍼", "A secret",
  "There's a smell in the garden that I know in my body without ever having been told. The neighbour's animal has been coming round. Something has been decided, in a way that I didn't plan.",
  {"pet": ["has_home", "adult", "owner", "dog"]},
  C("Welcome the visitor",
    O("It was lovely, and short, and in the spring I had five. Five! I did not know what to do with them, and then, quite suddenly, I did.", {"happiness": 8, "stress": 5, "health": -4}, {"litters": 1, "bond": 4}),
    O("It was a good year. There were three, all with my ears, and {o.first} gave them away to carefully chosen homes. I still miss them.", {"happiness": 6, "health": -3}, {"litters": 1, "bond": 3})),
  C("Resist",
    O("I stayed in the house, and watched through the glass. It passed. {o.first} was relieved, and the neighbour was disappointed.", {"stress": 3}, {"obedience": 3}),
    O("I got through the season. It was hard. At the end of it, I was exhausted, and I'd never felt more like myself.", {"stress": 4}, {"obedience": 2})),
  C("Go on the run",
    O("I slipped out through the broken slat. I was gone for two nights and came back looking pleased with myself.", {"happiness": 7}, {"litters": 1, "territory": 8, "escapes": 1, "bond": -3}),
    O("I slipped out, and the neighbourhood was far larger than I knew. I was found at the end of the second day, hoarse, filthy and glad.", {"happiness": 6, "stress": 4}, {"territory": 8, "escapes": 1})),
  roles=OWN, age=(1, 9), cooldown=20)

E("hungry_house", "🥣", "Smaller portions",
  "The bowl has been getting lighter. The good tins have gone. {o.first} apologises every morning, in a low voice, to the pantry.",
  {"pet": ["has_home", "tight"]},
  C("Be patient",
    O("I ate what was given and didn't make a fuss. {o.first} noticed, and the first thing they bought when things improved was the good tin.", {"happiness": -1, "stress": 3}, {"hunger": -8, "bond": 5}),
    O("I was very good about it, and lost a little weight, and gained something I can't describe in words.", {"happiness": 0}, {"hunger": -6, "bond": 4})),
  C("Raid the bins",
    O("The neighbours were well-off, and wasteful. I did very well indeed. {o.first} was mortified when someone complained.", {"happiness": 3}, {"hunger": 12, "instinct": 3, "bond": -2, "mood": -3}),
    O("I raided the bins until I was caught in the act. A kind neighbour took one look at me and brought a bag of kibble round to the door.", {"happiness": 3}, {"hunger": 8, "belonging": 3})),
  C("Share {o.first}'s plate",
    O("I waited under the table. They slipped me half of what was theirs. I know what it cost them. I'll never forget it.", {"happiness": 3}, {"bond": 8, "hunger": 5}),
    O("They gave me the best bit, in silence. I didn't deserve it, and I ate it.", {"happiness": 3, "stress": 2}, {"bond": 7, "hunger": 4})),
  roles=OWN, cooldown=6)

E("baby_house", "👶", "The new one",
  "The baby has begun to crawl. It heads for me with a purpose that no creature that size should be allowed to have. It smells of milk and something quite unlike anything else.",
  {"pet": ["has_home", "baby_in_house"]},
  C("Guard it",
    O("I lay across the doorway for the whole of the winter. When it could stand, it held my ears and pulled itself up, and I did not make a sound. {o.first} cried. I'm told it was a good cry.", {"happiness": 6, "karma": 4}, {"bond": 8, "belonging": 6, "heroics": 0}),
    O("I took up a post by the cot. I growled at the vacuum cleaner. {o.first} says I'm a nanny. I don't know what it means but I like it.", {"happiness": 5}, {"bond": 6, "belonging": 5})),
  C("Keep out of the way",
    O("I took up a position in the kitchen, at a safe distance, with my eyes open. The baby's reach is longer than it looks.", {"stress": 2}, {"bond": -1}),
    O("I stayed in the spare room. The baby is loud. It has a kind of power I can't match.", {"stress": 3, "happiness": -2}, {"bond": -2})),
  C("Sulk about it",
    O("I chewed a shoe, moved the cushion, ignored the baby, ignored the bowl. {o.first} noticed in the end and put it all right.", {"happiness": -2, "stress": 4}, {"bond": -2, "mischief": 1, "mood": -3}),
    O("I made it clear that I'd not been consulted. I'd say it worked. For about a week, I was the centre of the universe.", {"happiness": 2}, {"bond": 1, "obedience": -2})),
  roles=OWN, cooldown=5)

E("split_house", "📦", "Two of everything",
  "There are boxes in the hall, and half the pictures are off the walls. Somebody is leaving, and it's being done in the slow way, with a lot of tape.",
  {"pet": ["has_home", "flag:split"]},
  C("Follow the one with the bag",
    O("I sat on the bag, on the step, and wouldn't be moved. It was resolved without a word. I'm told that I made the decision.", {"happiness": 1, "stress": 6}, {"bond": 4, "territory": -6}),
    O("I followed them to the car. They stopped, and looked back at the house, and looked at me, and in the end we both stayed.", {"stress": 5}, {"bond": 5})),
  C("Stay with the other one",
    O("I stayed in the hall. It is not a thing that I understood but it's a thing that I knew. The one who stayed sat on the floor with me and didn't speak for an hour.", {"stress": 5, "happiness": -3}, {"bond": 5}),
    O("I stayed in the kitchen. The smell of the other one lasted for a month and then it faded, and so did I.", {"stress": 6}, {"bond": 2})),
  C("Go between the two",
    O("I got both: one for the week, one for the weekend. I was a bridge between two households, and I tried not to be a problem.", {"happiness": 2, "stress": 4}, {"belonging": -2, "instinct": 3}),
    O("It was confusing but it was fine. I have two beds, two bowls and two sets of rules, and I have learned to be a diplomat.", {"happiness": 1}, {"obedience": 2, "instinct": 3})),
  roles=OWN, cooldown=10)

# ======================================================================== FOLLOW-UPS
F("f.thunder", "🌤️", "After the storm", "The weather has been calm for weeks, but I've noticed something. {o.first} puts on the radio when the sky goes dark now, and sits with me.", [1, 3],
  ["pl.thunder"], HOME,
  C("Accept the radio",
    O("I lay under the table with the music in my ears and the world went on happening a long way off. It's a lovely arrangement.", {"stress": -5}, {"bond": 4}),
    O("It worked for a year. The next storm broke the radio.", {"stress": -2}, {"bond": 2})),
  C("Make my own arrangements",
    O("I found a place under the stairs where the noise couldn't get in. It is a perfect place. I've told no one.", {"stress": -3}, {"instinct": 3}),
    O("I got into the wardrobe. It took six hours to coax me out.", {"stress": 2}, {"obedience": -1})),
  C("Ignore it all",
    O("I slept through the biggest storm of the decade. Everyone was astonished. I'd say I have grown.", {"happiness": 3}, {"instinct": 2}),
    O("I slept through the first half, and woke for the second. Poor timing.", {"stress": 3}, {})),
  roles=OWN)

F("f.gift", "🧸", "The remains", "In the cupboard under the stairs, there's the toy. What's left of it. It still smells of a particular summer.", [3, 8],
  ["pl.gift", "pl.new_bed"], HOME,
  C("Carry it out and sit with it",
    O("I sat on the hall floor with the last scrap of it between my paws. {o.first} found me there and sat down, too.", {"happiness": 4}, {"bond": 5}),
    O("I carried it to the garden, and buried it. It's the first thing I've ever mourned.", {"happiness": 2, "stress": 2}, {"instinct": 2})),
  C("Leave it where it is",
    O("I looked at it, and left it. Some things belong in the dark.", {"happiness": 1}, {}),
    O("I looked at it for a moment, and then went for a long, dull walk.", {"stress": 1}, {"fitness": 2})),
  C("Show it to the new one",
    O("I laid it in front of the youngster. It took it, and ran. Fair enough. It's theirs now.", {"happiness": 3}, {"belonging": 2}),
    O("I showed it, and it looked at me, and looked at the scrap, and looked at me again. It understood. It understood.", {"happiness": 3}, {"belonging": 3})),
  roles=OWN)

F("f.travel", "📱", "A message from far away", "{o.first} is holding the glowing rectangle to my ear. A voice I know is coming out of it, saying my name over and over. It's not the right size but the voice is right.", [1, 3],
  ["pl.travel", "pl.owner_sad"], HOME,
  C("Answer it",
    O("I said what I always say, which is nothing, in a very particular tone. Down the line there was a laugh.", {"happiness": 4}, {"bond": 4}),
    O("I barked at it, and it barked back, in a way. That was all the conversation we needed.", {"happiness": 3}, {"bond": 3, "obedience": -1})),
  C("Look for them behind the rectangle",
    O("I checked behind the rectangle, under the sofa and in the kitchen. They weren't there, but the voice was.", {"happiness": 2, "stress": 2}, {"instinct": 2}),
    O("I walked around it three times, deeply suspicious. It's not a good trick, but it's a convincing one.", {"happiness": 2}, {"instinct": 1})),
  C("Turn my back",
    O("I turned away. The voice and I have our own relationship, and it isn't for show.", {"stress": 2}, {"bond": -1}),
    O("I walked out. Some things hurt too much through glass.", {"stress": 3, "happiness": -2}, {"bond": -2})),
  roles=OWN)

F("f.burglar", "🏅", "The medal", "{o.first} has come home with a ribbon on a little rosette, and a photograph in the local paper. Apparently there's a headline. It has my name in it, spelled correctly.", [1, 2],
  ["pl.burglar", "pl.fire", "pl.road_child"], HOME,
  C("Wear it",
    O("I wore it for a day, and then a week, and then it fell off in a puddle. Nobody mentioned it again, but it's on the wall of the pub.", {"happiness": 6, "fame": 3}, {"bond": 4}),
    O("I wore it, and posed, and sat for three portraits. It was exhausting, and I loved every minute.", {"happiness": 6, "fame": 2}, {"bond": 3})),
  C("Eat it",
    O("It was made of cloth. It was a letdown. {o.first} laughed so much that they had to sit down.", {"happiness": 3}, {"mischief": 1, "bond": 3}),
    O("It was a lovely thing, but it tasted of felt. I felt bad about it afterwards.", {"happiness": 2}, {"mischief": 1})),
  C("Hide under the sofa",
    O("The fuss was too much. I went under the sofa and stayed until the visitors had gone. {o.first} brought me a sausage.", {"stress": -2}, {"hunger": 4, "bond": 3}),
    O("I was too modest for it. They gave the medal to the sofa in the end.", {"happiness": 1}, {"bond": 2})),
  roles=OWN)

F("f.street", "🪙", "Someone remembers", "A shop doorway on the high street has a bowl in it now. I don't know who put it there. The water's fresh, and it's been fresh every day.", [1, 3],
  ["pl.street_winter", "pl.street_butcher", "pl.street_net"], {"pet": ["homeless"]},
  C("Drink and move on",
    O("I drank, and moved on, and came back at dusk. The bowl was filled again. I don't know who it is. I'm grateful.", {"happiness": 3}, {"hunger": 4, "territory": 3, "belonging": 3}),
    O("I took the water and went. A boy was watching from the first floor. He didn't try to stop me.", {"happiness": 2}, {"belonging": 2})),
  C("Wait for whoever it is",
    O("I sat in the doorway until midnight. A woman in a dressing gown came down with the bowl. She looked at me and said nothing at all. In the morning, there was a blanket.", {"happiness": 6, "stress": -4}, {"belonging": 8, "bond": 3}),
    O("I waited, and nobody came, and I fell asleep in the porch.", {"stress": -1}, {"belonging": 1})),
  C("Mark it",
    O("I made it clear that this was my doorway. Nobody argued.", {"happiness": 3}, {"territory": 6}),
    O("I marked it, and so did a fox. There was a bit of a row.", {"stress": 2}, {"territory": 4}, rival=True)),
  )

F("f.park", "🦮", "A friend from the park", "The animal from the park is in my street, with their person, walking toward my gate. The two of us have both seen each other and there is a long silence on the lead.", [1, 4],
  ["pl.dog_park", "pl.storm_neighbour"], HOME,
  C("Run to them",
    O("I ran to meet them, and they ran to meet me, and we spun on the spot. Our people had to be introduced. It turned out they live two roads away.", {"happiness": 7}, {"belonging": 3, "fitness": 3}),
    O("We went round and round, tangling the leads. The two humans got to know each other that day.", {"happiness": 6}, {"belonging": 3})),
  C("Play it cool",
    O("I let them come to me. We exchanged the formal greetings, and then forgot about the formalities.", {"happiness": 4}, {"instinct": 2}),
    O("I let them approach, and sniffed once, and went back to my business. It was the right amount of interest.", {"happiness": 3}, {"instinct": 3})),
  C("Bark",
    O("I barked, and they barked back, and our people had to carry us home separately. It was a miscalculation.", {"stress": 3}, {"obedience": -2}),
    O("It was a greeting, but it was loud. The two humans apologised to each other. It's the start of something.", {"happiness": 3}, {"obedience": -1})),
  roles=OWN)

F("f.show", "🏆", "The cabinet", "The shelf in the hall has been cleared for something. {o.first} is polishing a cup with a tea towel and talking to it in the voice they use for me.", [1, 3],
  ["pl.show_ring"], HOME,
  C("Sit under it, and be proud",
    O("I sat on the rug beneath the cup. I looked at it for an hour. I did not know what it was, but it had the shine of something earned.", {"happiness": 6}, {"bond": 4}),
    O("I sat under the shelf, and gazed up. I think {o.first} took a photograph.", {"happiness": 5}, {"bond": 3})),
  C("Knock it off",
    O("It fell with a metallic crash. The cup rang like a bell. {o.first} caught it, laughing and swearing, and put me on the floor.", {"happiness": 3}, {"mischief": 1, "bond": 1}),
    O("It fell. There is a dent. It's a better cup now.", {"happiness": 2}, {"mischief": 1, "bond": -2})),
  C("Ignore it",
    O("I slept on the sofa. A cup is a cup.", {"stress": -3}, {}),
    O("I walked past it, with some disdain. I do not need a cup to know what I am.", {"happiness": 2}, {"instinct": 1})),
  roles=OWN)

F("f.shelter", "🏠", "The visit", "A car has come to the shelter and parked in the yard. The woman in the woolly hat has got out, and with her there is a man and a small, fretful dog on a lead. They're coming to my kennel.", [1, 2],
  ["pl.shelter_volunteer", "pl.shelter_cough", "pl.mill_hands"], {"pet": ["in_shelter"]},
  C("Be on my best behaviour",
    O("I sat. I gave a paw. I looked into the eyes of the man. The man looked at the woman and said, 'Well?'", {"happiness": 6}, {"obedience": 3}, adopt="After a year, the woman in the woolly hat found a home for me."),
    O("I did everything right. They took me out into the yard. It was a long minute. They took me home.", {"happiness": 8}, {"obedience": 3, "bond": 5}, adopt="They came back for me on the Thursday.")),
  C("Hide at the back",
    O("I went to the corner. They saw me, and waited, and knelt down. It took them twenty minutes to coax me out. They had a lot of patience.", {"stress": 6}, {"bond": 3}, adopt="They waited twenty minutes, and took me home."),
    O("They stood there and looked at me looking at the wall. They left. They left, and I don't know why I did it.", {"stress": 6, "happiness": -4}, {})),
  C("Make friends with the small dog first",
    O("I put my head down next to his. He sniffed me. He looked up at the man. He was the one who decided.", {"happiness": 6}, {"belonging": 3}, adopt="A small dog on a lead decided, and the rest of us went along."),
    O("We ran around the yard together for half an hour. I think I won them both.", {"happiness": 7}, {"belonging": 3}, adopt="A small dog and a woman in a woolly hat picked me.")),
  )

F("f.postie", "📮", "The new postie", "The Man Who Comes Every Day has gone. Someone new is coming up the path, with the same bag and a different walk. The whole street smells of change.", [1, 4],
  ["pl.dog_postie", "pl.dog_squirrel"], HOME,
  C("Accept the replacement",
    O("I gave them the full ritual, from the gate to the doormat. They put their hand through the letterbox, and I licked it. We have an understanding.", {"happiness": 4}, {"belonging": 2, "instinct": 1}),
    O("It took three weeks, a lot of biscuits and a very cautious greeting at the gate. We are friends now. It's not the same, but it's good.", {"happiness": 3}, {"obedience": 1})),
  C("Wait for the old one",
    O("I waited every morning at the door for months. Then, one day, I stopped. I don't know why. I never stopped loving him.", {"happiness": -3, "stress": 3}, {"bond": 1}),
    O("I waited at the gate, and one winter morning he came, in a coat, on a bike, off duty, with a bag of treats. We looked at each other, and it was enough.", {"happiness": 6}, {"belonging": 3})),
  C("Bark at them for a year",
    O("I barked at the new one daily for twelve months. Slowly, the barks became a greeting. Eventually, a sort of fond complaint.", {"happiness": 2}, {"instinct": 2, "obedience": -1}),
    O("I made it quite clear that they were not welcome, and they left the post at the end of the road. A neighbour had to bring it up.", {"stress": 2}, {"territory": 3, "bond": -1})),
  roles=OWN)

F("f.garden_quiet", "🌱", "The quiet garden", "The garden has gone quiet. The birds, the mice, the small things I used to watch have gone somewhere else, or I've gotten slower, or both.", [2, 5],
  ["pl.cat_mouse", "pl.cat_birds", "pl.cat_flap"], HOME,
  C("Look for them",
    O("I walked the whole garden, the fence and the hedge. A single starling watched me from the shed. We both understood a great deal.", {"happiness": 2}, {"territory": 4, "instinct": 2}),
    O("I found a whole new corner of the garden, under the rhubarb, and stayed there a month.", {"happiness": 4}, {"territory": 5})),
  C("Make my peace with it",
    O("I took the best spot in the sun and watched the empty lawn, as a king watches a quiet kingdom.", {"happiness": 3, "stress": -4}, {"belonging": 3}),
    O("I slept through the spring. I'd never done that before. I woke up in the summer, and it was lovely.", {"happiness": 3, "stress": -3}, {})),
  C("Go further",
    O("I crossed two gardens and a lane, and found a place where everything was happening. I became a regular.", {"happiness": 5}, {"territory": 8, "instinct": 3, "escapes": 1}),
    O("I went too far and had to be fetched home from a stranger's shed. It was worth it.", {"happiness": 4, "stress": 3}, {"territory": 6, "escapes": 1})),
  roles=OWN)

F("f.hutch", "🏡", "The new run", "There's a new thing in the garden. It's a wire tunnel with a little roof, and a door, and a pile of hay at the far end. {o.first} is holding the door open with a face like Christmas.", [1, 3],
  ["pl.rabbit_wire", "pl.rabbit_fox", "pl.rabbit_garden"], HOME,
  C("Go in at once",
    O("I ran in, straight to the end, and did a binky so big that I hit the roof. It's the best thing that has ever been built for me.", {"happiness": 8}, {"fitness": 4, "bond": 4}),
    O("I went in with my nose first, then my ears, then the rest. It's tall enough to stand up in. I did.", {"happiness": 7}, {"fitness": 3, "bond": 3})),
  C("Inspect it, thoroughly",
    O("I tested every wire, every join and every corner. I found one weakness, and made it known. {o.first} fixed it that evening.", {"happiness": 4}, {"instinct": 4, "bond": 3}),
    O("I took three days to enter it. Every inch had to be smelled. It's an excellent run, and I'm told I was very rude about it.", {"happiness": 3}, {"instinct": 3})),
  C("Dig out of it",
    O("The base was cement. I dug for an hour, then gave up, and sat in the middle of the run and sulked.", {"happiness": 1, "stress": 2}, {"mischief": 1}),
    O("It had no floor. By morning, I was at the other end of the garden, grinning.", {"happiness": 5}, {"territory": 5, "escapes": 1, "mischief": 1})),
  roles=OWN)

F("f.echo_word", "🔁", "The word comes back", "A new visitor has just rung the bell. Before {o.first} can get to the door, a voice from the hall says, in {o.first}'s exact tone: 'You're late.' It is my voice.", [2, 6],
  ["pl.parrot_word", "pl.parrot_window", "pl.parrot_stress"], HOME,
  C("Say it again, louder",
    O("The visitor was delighted. I was told to say it to every guest for the rest of the year. I did. I was a hit.", {"happiness": 6}, {"bond": 2, "mischief": 1}),
    O("I said it again, and again, and again. By Thursday, everyone in the house had stopped finding it funny. I hadn't.", {"happiness": 4, "stress": 2}, {"mood": -4})),
  C("Say something new",
    O("I said 'good morning' at midnight. I said 'the kettle's on' to an empty room. I had a whole range of material, and I used it.", {"happiness": 5}, {"instinct": 3}),
    O("I did the microwave, then the phone. A visitor looked around for the source. I've never been so pleased.", {"happiness": 5}, {"instinct": 2})),
  C("Go quiet",
    O("I sat on my perch and said nothing at all for three weeks. {o.first} became very concerned. I'd made my point, and I was very comfortable.", {"happiness": 2}, {"bond": 3}),
    O("I went quiet, and then the house went quiet too. I realised I was the only one who made a noise in it.", {"happiness": -2, "stress": 3}, {"bond": 4})),
  roles=OWN)

F("f.rider", "🧒", "A child on my back", "A child is standing at the gate with a hard hat and a carrot. They look small, serious and determined. {o.first} is saying 'gently, now' in a voice that isn't for me.", [1, 3],
  ["pl.horse_farrier", "pl.horse_bag", "pl.horse_gate"], HOME,
  C("Stand still and let them climb up",
    O("I stood like a statue, and the child scrambled on to my back. I walked, slowly, around the paddock. When the lesson was over, they put their face in my mane and said my name.", {"happiness": 8}, {"bond": 8, "obedience": 3}),
    O("I stood still, and they got on. It was a long, slow, careful hour. It's the best thing I've ever done.", {"happiness": 7, "stress": -3}, {"bond": 7, "obedience": 3})),
  C("Test them",
    O("I took one step to the left, to see what they'd do. They did the right thing. I've never respected anyone so much.", {"happiness": 4}, {"obedience": 2, "bond": 4}),
    O("I walked a little faster than I was asked. They said 'whoa' in a very small voice, and I stopped. We've been friends ever since.", {"happiness": 5}, {"bond": 5})),
  C("Make a break for it",
    O("I went across the paddock, round the pond and into the lane. They held on. When I stopped, they were beaming. {o.first} was grey.", {"happiness": 6, "stress": 3}, {"fitness": 4, "bond": -2, "escapes": 1}),
    O("I bolted. They fell off, into the soft grass. Nobody was hurt, and I was made to stand in the corner for a week.", {"stress": 6, "happiness": -2}, {"bond": -4, "obedience": -3})),
  roles=OWN)

F("f.last_vet", "🕯️", "The long appointment", "It is a short drive, in the evening. {o.first} is carrying me from the car and talking quietly, and I recognise the smell of the building. It's the vet's. The light is gentler than usual.", [1, 3],
  ["pl.senior_stairs", "pl.senior_best_day"], HOME,
  C("Press against them",
    O("I put my whole weight into their chest and they held me. They said all the things they'd been saving. I understood the tone, if not the words. I wasn't frightened.", {"happiness": 3, "stress": -6}, {"bond": 8}),
    O("I looked at them, the whole time. They looked at me. It was the whole of what we'd had, in a minute.", {"happiness": 3, "stress": -5}, {"bond": 8})),
  C("Be brave for them",
    O("I held my head up and thumped my tail once, twice, on the table. I wanted them to know that it was all right.", {"happiness": 2}, {"bond": 6, "heroics": 0}),
    O("I licked their hand, which was wet. I wasn't sure why. I don't mind.", {"happiness": 3}, {"bond": 6})),
  C("Look for the sun",
    O("The window had a square of late sun in it. I looked at it, and it was warm, and I thought of every place I'd ever been warm.", {"happiness": 5, "stress": -8}, {"belonging": 5}),
    O("There was a smell of cut grass from somewhere. I closed my eyes. I was in the field again, young and fast, and the whole day was ahead.", {"happiness": 6, "stress": -8}, {"belonging": 4})),
  roles=OWN)

# ======================================================================== ARC (five turning points)
A(1, "💞", "Somebody's",
  "It happens with no announcement. You are lying on the floor of the hall and the door opens, and your whole body knows who it is before the door is more than a crack. You didn't decide it. It was decided somewhere you can't see.",
  C("Go to them, all of you",
    O("I went across the floor like something fired from a gun. They went down on their knees and caught me. I understood that I had a person, and that I was theirs.", {"happiness": 10, "stress": -8}, {"bond": 10, "belonging": 8}),
    O("I went to them with my whole body, and they laughed, and cried a little, and said my name six times. The best moment of the decade.", {"happiness": 10}, {"bond": 8, "belonging": 6})),
  C("Wait, and let them come to me",
    O("I waited in the doorway, tail low, and they came. There was a moment of hesitation, and then it was fine. It is a different kind of love, a slower one.", {"happiness": 6}, {"bond": 7, "belonging": 5}),
    O("I held back, and they respected it. Over the weeks that followed, I came a little closer each day. It's the sort of bond you can build on.", {"happiness": 5}, {"bond": 6, "obedience": 3})),
  C("Run the other way, and then come back",
    O("I ran to the end of the garden and back three times. By the third, they had sat down on the grass. I put my head in their lap.", {"happiness": 7}, {"bond": 7, "fitness": 3}),
    O("I did a victory lap round the house, jumped on the sofa, jumped off, and landed, panting, in their arms.", {"happiness": 8}, {"bond": 6, "mischief": 1})))

A(2, "🗺️", "The shape of the place",
  "One morning I notice that I know where everything is. Every wall, every doorway, every crack in the pavement at the end of the street. I have a map of the world in my head, and I'm at the middle of it.",
  C("Walk the boundary, and make it official",
    O("I did the rounds at dawn: the gate, the hedge, the bins, the telegraph pole. It all smelled of me. I was, for the first time, a resident.", {"happiness": 6}, {"territory": 12, "instinct": 4}),
    O("I patrolled the whole circuit, and added a little to the pole. It's a lot of work to be somewhere.", {"happiness": 5}, {"territory": 10, "instinct": 3})),
  C("Go beyond it",
    O("I went past the last post, and the one after, and found a road I'd never walked. The sky was bigger there. I came back with burrs and a head full of directions.", {"happiness": 7}, {"territory": 10, "instinct": 5, "escapes": 1}),
    O("I went past the last post, and found a field with nothing in it. I rolled in it. I was a creature of the open, for an afternoon.", {"happiness": 7}, {"territory": 8, "fitness": 4, "escapes": 1})),
  C("Stay in the middle",
    O("I stayed on the rug, in the exact middle of the house. From there, I could hear every door. It was enough.", {"happiness": 4, "stress": -4}, {"belonging": 6}),
    O("I stayed. A territory is not about its size but about knowing where you are. I knew.", {"happiness": 4}, {"belonging": 5, "obedience": 2})))

A(3, "🏅", "What I am for",
  "At some point you stop being a thing that happens in a house and become a character in it. People have started to say what you're like. 'The guard.' 'The clown.' 'The one who knows.' You can feel the shape of it forming, and it's yours to push.",
  C("Take the name they give me",
    O("I took the name and wore it. It wasn't a cage. It was a coat. It fit, and I didn't have to think about it.", {"happiness": 6}, {"bond": 4, "obedience": 3}),
    O("I took it, and lived in it, and it made me bolder. I did a thing I would never have done otherwise.", {"happiness": 5}, {"bond": 3, "instinct": 3})),
  C("Choose another",
    O("I decided to be something different from what they thought. It took a year to be taken seriously, and the household was never the same.", {"happiness": 5, "stress": 3}, {"instinct": 5, "obedience": -2}),
    O("I surprised them. A creature that can still surprise, after years, is not a pet. It's a person.", {"happiness": 6}, {"instinct": 4, "bond": 2})),
  C("Be everything, in turn",
    O("Guard on Mondays, clown on Wednesdays, therapist on Fridays. The household never knew what they'd get. It kept them on their toes, and me too.", {"happiness": 5}, {"bond": 3, "instinct": 3}),
    O("I refused to be one thing. The vet said it was a sign of intelligence. the household said it was a sign of something else.", {"happiness": 4}, {"obedience": -1, "bond": 2})),
  )

A(4, "🌩️", "The test",
  "One day, with no warning, you are asked for something you didn't know you had. It might be a stranger on the road, or a stranger at the door, or a stranger in your own body. Everything you are is going to get a say.",
  C("Rise to it",
    O("It was not a decision. It was a thing that happened in my legs. I did what I had to, and it was enough. Afterwards, my whole body shook, and somebody was holding me.", {"happiness": 8, "karma": 6, "stress": 6}, {"heroics": 1, "bond": 6, "instinct": 4}),
    O("I did the brave thing. I still don't know where it came from. They gave me a name for it, afterwards, and it's a good one.", {"happiness": 8, "karma": 6}, {"heroics": 1, "bond": 5})),
  C("Find another way through",
    O("I didn't face it, I went round it. By being clever, and quiet, and low, I got away with it. There are many ways to survive.", {"happiness": 3, "stress": 4}, {"instinct": 6}),
    O("I used my nose, my wits and my four legs. It wasn't heroic. It was effective, and I'm here.", {"happiness": 3}, {"instinct": 5, "obedience": 2})),
  C("Freeze",
    O("I froze. It's not a thing to be proud of, and it's not a thing to be ashamed of. It's a thing that happens. Nobody was hurt, but I'll wonder.", {"stress": 8, "happiness": -3}, {"instinct": 3}),
    O("I froze, and someone else did what had to be done. I've never talked about it. I think of it every time I look at them.", {"stress": 8, "happiness": -3}, {"bond": 1})))

A(5, "🌇", "The long evening",
  "It has become a slower world. The mornings are sore and the evenings are long and warm, and there's a particular kind of afternoon light that I only found out about last year. It will be a while yet, but I can feel the shape of the road.",
  C("Spend it on them",
    O("Every minute. Every hour on the sofa, every walk at their pace. They know. They've started to take more time for me, too.", {"happiness": 8, "stress": -6}, {"bond": 10}),
    O("I followed them from room to room, for months. I'm not sure who was doing the following.", {"happiness": 7}, {"bond": 8})),
  C("Spend it on the world",
    O("I went to every place I'd ever been, one more time, slowly. The old fence, the lake, the bakery. I said goodbye to each of them in my own way.", {"happiness": 7}, {"territory": 8, "bond": 4}),
    O("I walked the whole neighbourhood, and every dog and every cat knew me, and said hello. It's the nicest thing I've ever had.", {"happiness": 7}, {"territory": 8, "belonging": 4})),
  C("Spend it in the sun",
    O("I found the best spot in the house, and I stayed in it. I was warm. I was unbothered. I was where I wanted to be.", {"happiness": 8, "stress": -8}, {"belonging": 6}),
    O("The sun, a long afternoon, a hand on my head. I don't need more, and I never have.", {"happiness": 8, "stress": -8}, {"bond": 5})))

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gen_pets_b.py')).read())

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gen_pets_c.py')).read())

# ======================================================================== write
for (fid, years, sources) in FOLLOW:
    for e in EV:
        if e["id"] in sources:
            for ch in e["choices"]:
                for o in ch["outcomes"]:
                    if "schedule" not in o:
                        o["schedule"] = {"event": fid, "years": years}

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "pets.json")
json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
base = [e for e in EV if not e.get("followup_only")]
print("pets.json: %d events (%d base, %d follow-ups/arcs), %d choices, %d outcomes" % (
    len(EV), len(base), len(EV) - len(base),
    sum(len(e["choices"]) for e in EV),
    sum(len(c["outcomes"]) for e in EV for c in e["choices"])))

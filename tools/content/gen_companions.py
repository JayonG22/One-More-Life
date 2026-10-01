#!/usr/bin/env python3
"""Generates data/events/companions.json — animals in a human's life (v1.3).
Events that bring an animal home use the `gain_pet` outcome, so the animal is kept
and has to be fed, tended and taken to the vet. Others are about living with one."""
import json, os
EV = []
FOLLOW = []

def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    return o

def C(label, *outs):
    assert len(outs) >= 2, label
    return {"label": label, "outcomes": list(outs)}

def E(id, icon, title, text, cond, *choices, weight=1.0, cooldown=8, once=False, roles=None):
    assert len(choices) >= 3, id
    c = {"age": [8, 95]}
    c.update(cond)
    d = {"id": "co." + id, "icon": icon, "title": title, "text": text, "conditions": c, "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if once: d["once"] = True
    if roles: d["roles"] = roles
    EV.append(d)

def F(id, icon, title, text, years, sources, cond, *choices):
    assert len(choices) >= 3, id
    c = {"age": [8, 100]}
    c.update(cond)
    EV.append({"id": "co." + id, "icon": icon, "title": title, "text": text, "conditions": c, "choices": list(choices), "weight": 1, "followup_only": True})
    FOLLOW.append(("co." + id, years, sources))

def gain(sp, src="stray"):
    return {"gain_pet": {"species": sp, "source": src}}

NOPET = {"has_pet": False}
PET = {"has_pet": True}

E("porch_cat", "🐈", "Something on the porch",
  "{~A thin cat|A scruffy tabby|A one-eared ginger cat} has been sitting on the porch every evening for a week. Today it is sitting by the door, looking at you the way a landlord looks at a late tenant.",
  {},
  C("Let it in",
    O("It walked in as if it had paid the deposit. Within a week it owned the sofa.", {"happiness": 8, "stress": -3}, **gain("cat", "stray")),
    O("It ate, slept for fourteen hours and then began to supervise. I think I have been adopted.", {"happiness": 7}, **gain("cat", "stray"))),
  C("Put out a bowl and see",
    O("It came every night after that. One cold night, it didn't leave. That was that.", {"happiness": 6, "stress": -2}, **gain("cat", "stray")),
    O("It ate and left. It came back for three days and then I never saw it again. I still put the bowl out sometimes.", {"happiness": -2})),
  C("Leave it alone",
    O("It left the next week. I told myself it had somewhere to be.", {"happiness": -2}),
    O("A neighbour took it in. I saw it in their window and it did not look at me.", {"happiness": -3, "karma": -1})),
  cooldown=20)

E("kittens_box", "📦", "A box by the bins",
  "There's a cardboard box by the bins behind the building. Something in it is making a noise like a squeaky hinge.",
  {},
  C("Take the box home",
    O("Four kittens. I kept one. The other three went to people at work who were not prepared for how quickly it would happen.", {"happiness": 8, "stress": 4, "money": -80}, **gain("cat", "rescue")),
    O("One of them climbed my sleeve in the lift and refused to come down. I named it before we reached my floor.", {"happiness": 9}, **gain("cat", "rescue"))),
  C("Call the shelter",
    O("A volunteer came within the hour, and thanked me twice. I went home feeling like I had done something.", {"karma": 6, "happiness": 3}),
    O("They took the box. They called me a week later to say all four had found homes. I cried a bit, to my surprise.", {"karma": 6, "happiness": 4})),
  C("Walk on",
    O("I walked on. For two days I thought about the sound, and then I stopped, and that was worse.", {"karma": -4, "happiness": -4}),
    O("I walked on. When I came back the box was gone. I will never know.", {"karma": -3, "happiness": -2})),
  cooldown=30, once=True)

E("friend_litter", "🐕", "Whose puppy",
  "A friend's dog has had a litter and every one of them has been spoken for except one: a clumsy, serious brown one that keeps falling over its own feet. Your friend looks at you.",
  {},
  C("Take the puppy",
    O("It slept on my chest the first night. By the second night it had eaten a shoe. I have never been happier.", {"happiness": 10, "stress": 4, "money": -120}, **gain("dog", "friend")),
    O("I took it home in my coat. It was a catastrophe and a joy. The neighbours know its name.", {"happiness": 9, "stress": 5}, **gain("dog", "friend"))),
  C("Think about it",
    O("I thought about it for a week and went round to say yes. The brown one had gone. I got a photograph and a feeling.", {"happiness": -3}),
    O("I thought. The puppy went to a family with a garden. It was the right call, and I still check the photographs.", {"happiness": -1})),
  C("Say no kindly",
    O("My friend understood. The puppy went to their sister. We still get updates.", {"happiness": 1}),
    O("It was a hard thing to say. The puppy found a home and so did my conscience.", {"happiness": 0})),
  cooldown=30)

E("gift_pet", "🎁", "A gift that breathes",
  "Someone who loves you very much has presented you with a gift that is looking around the room and has already found the curtains.",
  {},
  C("Accept it with gratitude",
    O("It was thoughtful, impulsive and a lot of work. I have not regretted it for a single day since the third week.", {"happiness": 8, "stress": 3}, **gain("any", "gift")),
    O("I said thank you and meant it by Thursday. Never trust a gift with a pulse; also, keep it.", {"happiness": 6, "stress": 4}, **gain("any", "gift"))),
  C("Explain you can't",
    O("They were hurt, then relieved, then said they'd return it. The look on their face is still with me.", {"happiness": -4}),
    O("It went back to the person who had given it to them. We had a long, awkward conversation.", {"happiness": -2})),
  C("Rehome it to someone better placed",
    O("A cousin with a garden took it. It sends me photographs.", {"happiness": 2, "karma": 2}),
    O("It went to a family down the road. I get to wave at it over the fence.", {"happiness": 2})),
  cooldown=30)

E("classroom_pet", "🐹", "The class hamster",
  "The teacher has an announcement: the hamster needs a home for the summer, and whose house will it be?",
  {"age": [8, 14]},
  C("Put your hand up",
    O("I carried the cage home on my knee in the car. Nobody has ever concentrated so hard on not tilting something.", {"happiness": 8, "stress": 2}, **gain("hamster", "event")),
    O("Mum said yes, to my amazement. The hamster turned out to be a night-time person and so did I.", {"happiness": 8}, **gain("hamster", "event"))),
  C("Wait to see who else does",
    O("Someone else got it. I watched it leave in its cage like a minor celebrity.", {"happiness": -2}),
    O("It went to the loudest kid in the class, who named it Gerald. I was not consulted.", {"happiness": -1})),
  C("Say your family isn't allowed",
    O("It was true, and I was relieved and ashamed in equal parts.", {"happiness": -1}),
    O("Dad said no, but he looked sad about it.", {"happiness": -1})),
  cooldown=40, once=True)

E("inherited_pet", "🕯️", "What was left",
  "After the funeral, someone mentions that no one has taken the dog. Everyone looks at their shoes. The dog is looking at you.",
  {"age": [20, 95]},
  C("Take the animal home",
    O("It sat on the doorstep and did not come in until it was dark. Then it did. We have been looking after each other since.", {"happiness": 3, "stress": 3, "karma": 3}, **gain("dog", "inherit")),
    O("It missed them as much as I did. We worked it out together, slowly, over some months.", {"happiness": 4, "stress": 2, "karma": 3}, **gain("cat", "inherit"))),
  C("Find it a good home",
    O("A neighbour's daughter took it. They send me a photograph at the holidays.", {"karma": 2}),
    O("A cousin took it, and said all the right things, and it is probably fine.", {"karma": 1})),
  C("Say you can't",
    O("It went to a shelter. It was nobody's fault. I don't think about it more than twice a week.", {"karma": -3, "happiness": -3}),
    O("A rescue took it in. They said it would be rehomed quickly. I held that thought tightly.", {"karma": -1, "happiness": -2})),
  cooldown=60, once=True)

E("pet_shop_window", "🪟", "The window",
  "You've walked past the pet shop on the high street three hundred times. Today something in the window is looking at you.",
  {"age": [12, 80]},
  C("Go in",
    O("I went in to look. I came out holding a very small thing in a very large cardboard box. It was not a good financial decision. It was the best one I made that year.", {"happiness": 9, "money": -200}, **gain("any", "shop")),
    O("The staff were kind and let me hold it. That was a mistake. I paid at the till with an expression I could not identify.", {"happiness": 8, "money": -150}, **gain("any", "shop"))),
  C("Look, and go home",
    O("I looked. I thought. I went home and did not buy anything. It was probably wise.", {"happiness": 0}),
    O("I told myself I'd come back on Saturday. I did not.", {"happiness": -1})),
  C("Tap the glass and be told off",
    O("A very patient person asked me to stop. I stopped. The animal didn't.", {"happiness": 1}),
    O("I tapped, I was told off, I left. A week later a child did the same thing and I felt a small pang.", {"happiness": 0})),
  cooldown=30)

E("beach_turtle", "🐢", "On the road",
  "A turtle is crossing a busy road. It has been crossing for some time. It has perhaps a metre to go.",
  {"age": [10, 85]},
  C("Stop and carry it across",
    O("I carried it across in both hands. It did not thank me. I felt like a hero for most of the afternoon.", {"karma": 5, "happiness": 4}),
    O("I carried it across and it left a very dignified wet patch on my jumper. Worth it.", {"karma": 5, "happiness": 4})),
  C("Take it home",
    O("I looked it up afterwards. It is the kind that can live forty years. I am now responsible for something that will see my grandchildren.", {"happiness": 5, "stress": 3}, **gain("turtle", "rescue")),
    O("It lives in a tank on my windowsill now, and I am told by the internet that I did this wrong, and then right.", {"happiness": 5, "stress": 3}, **gain("turtle", "rescue"))),
  C("Drive on",
    O("I drove on. In the mirror I saw another car stop for it.", {"karma": -2, "happiness": -1}),
    O("I drove on. I thought about it for a mile.", {"karma": -2})),
  cooldown=30, once=True)

E("lost_dog", "🔍", "The poster",
  "A dog is sitting outside your door in the rain. It has a collar and no tag. There is a poster on the lamp-post two streets away that says LOST in capitals.",
  {},
  C("Ring the number on the poster",
    O("A woman sobbed with relief on the phone. She came within ten minutes. She brought cake the next day.", {"karma": 8, "happiness": 6}),
    O("The owner turned up and thanked me four times. The dog looked back at me over her shoulder. I felt a lot.", {"karma": 8, "happiness": 4})),
  C("Keep the dog",
    O("I said I'd keep it for a while 'just in case'. After a month I stopped saying 'just in case'. It is not my proudest moment, or my least happy one.", {"karma": -8, "happiness": 6}, **gain("dog", "stray")),
    O("I told myself the poster must be old. It was not. I know that, and the dog knows that.", {"karma": -9, "happiness": 4}, **gain("dog", "stray"))),
  C("Take it to the vet to scan",
    O("There was a chip. The vet rang the owners while I held the lead. A good day.", {"karma": 6, "happiness": 4}),
    O("No chip. The vet gave me a week to find the owner. No one came. We kept the dog.", {"karma": 3, "happiness": 6}, **gain("dog", "stray"))),
  cooldown=40)

E("neighbour_moves", "🚚", "They're moving",
  "The neighbours are moving to a flat that doesn't allow animals. Their old cat has been walking round your garden as if it already knew.",
  {},
  C("Offer to take the cat",
    O("They almost cried. The cat wore the expression of someone being informed of a merger.", {"happiness": 6, "karma": 4}, **gain("cat", "friend")),
    O("The cat and I settled it with a stare. It moved into the airing cupboard on the first night.", {"happiness": 7, "karma": 4}, **gain("cat", "friend"))),
  C("Help them find a home for it",
    O("I put up posters and asked around. A woman three streets over took it. I get regular reports.", {"karma": 4, "happiness": 2}),
    O("A friend of a friend took it, and sent a picture of it on a very expensive armchair.", {"karma": 4, "happiness": 2})),
  C("Wish them luck",
    O("They found it a home themselves. I felt vaguely like a bystander.", {"happiness": 0}),
    O("The cat was gone by the weekend. I haven't seen it since.", {"happiness": -1})),
  cooldown=40)

E("kid_hamster", "🧒", "Can we get a hamster",
  "Your child has prepared a presentation, a budget, a signed promise and a drawing of a hamster in a hat.",
  {"has_children": True},
  C("Get the hamster",
    O("It lasted two and a half years and was loved beyond all reason. I became its main carer by week three.", {"happiness": 6, "stress": 3, "money": -40}, **gain("hamster", "event")),
    O("The chores promise lasted nine days. The hamster lasted longer than I expected. So did the love.", {"happiness": 6, "stress": 4}, **gain("hamster", "event"))),
  C("Say not yet",
    O("Disappointment of operatic proportions. It was over in an hour.", {"happiness": -1}),
    O("They pretended to understand. I saw a drawing later that proved otherwise.", {"happiness": -2})),
  C("Compromise on a goldfish",
    O("Goldfish: four days of fascination, followed by a very long period of indifference. I am the goldfish guy now.", {"happiness": 3}, **gain("goldfish", "event")),
    O("The fish was named Steve and is somehow still alive. It is, in a sense, the one stable thing in our house.", {"happiness": 4}, **gain("goldfish", "event"))),
  cooldown=40)

# --- living with an animal
E("shoe", "👟", "The shoe",
  "There is a shoe in the hallway. It is no longer a shoe in the way that matters. The animal is sitting next to it looking like a lawyer.",
  PET,
  C("Laugh",
    O("I laughed so much the animal began to look worried. We have a good understanding now about footwear.", {"happiness": 4}),
    O("It was the left one. It was always going to be the left one.", {"happiness": 3})),
  C("Tell them off",
    O("I tried to be stern. They looked at me. I gave up and made tea.", {"stress": 2}),
    O("A short lecture followed by a long cuddle. I think we both learned something.", {"stress": 1, "happiness": 2})),
  C("Take it as a hint",
    O("I bought a toy. It was ignored in favour of the next shoe.", {"money": -15, "happiness": 1}),
    O("I got a proper chew toy and three weeks of peace. Then a sandal.", {"money": -20, "happiness": 1})),
  cooldown=10)

E("pet_birthday", "🎂", "Whose birthday",
  "It's the animal's birthday, or near enough. Nobody can prove it either way.",
  PET,
  C("Throw a party",
    O("A hat, a cake made of something safe, and four animals from the street. It was chaos and everyone had a lovely time.", {"happiness": 6, "money": -40}),
    O("A small party with a cake, three friends and a lot of noise. The animal slept through the second half.", {"happiness": 5, "money": -30})),
  C("A special treat",
    O("A good treat, a long walk and an extra hour on the sofa. A quiet, correct birthday.", {"happiness": 3, "money": -10}),
    O("I bought the fancy food. The animal ate it in nine seconds and asked for more.", {"happiness": 2, "money": -15})),
  C("Ignore it",
    O("It was a regular Tuesday. The animal did not appear to mind. I minded a little.", {"happiness": -1}),
    O("I forgot until the next day. I felt terrible, and got extra treats.", {"happiness": -2})),
  cooldown=10)

E("pet_vs_partner", "💔", "Him or the cat",
  "Your partner has gently pointed out that the animal has claimed their side of the bed, their spot on the sofa and, they suspect, their toothbrush.",
  {"has_partner": True, "has_pet": True},
  C("Negotiate",
    O("A rota of seats. A treaty. Within a month the animal had violated it and we both thought it was funny.", {"happiness": 3}),
    O("We sorted it out over dinner. The animal ate a corner of the treaty.", {"happiness": 2})),
  C("Side with the animal",
    O("My partner sighed, laughed, and stayed. I like to think the animal had a say.", {"happiness": 2, "stress": 2}),
    O("I held firm. There was a silence. Then the animal sneezed on both of us and that ended it.", {"stress": 2})),
  C("Put the animal in the kitchen",
    O("The animal cried at the door for a night and a half. I lost.", {"stress": 4, "happiness": -2}),
    O("It lasted two nights. The sofa was shared. The peace was uneasy.", {"stress": 3})),
  cooldown=20)

E("landlord_pets", "🏘️", "No pets",
  "A letter from the landlord: a clause about animals has been enforced across the building, with immediate effect. There is a form.",
  {"has_pet": True, "age": [18, 80]},
  C("Fight for the animal",
    O("A tenants' meeting, a petition, a cake. We won, narrowly.", {"stress": 6, "happiness": 3}),
    O("I wrote a letter so polite it was almost a threat. The landlord relented.", {"stress": 4, "happiness": 3})),
  C("Pay the pet deposit",
    O("A deposit, an inspection and a look from the landlord. The animal behaved perfectly, which was suspicious.", {"money": -300, "stress": 2}),
    O("A quiet fee, and a promise. The animal gave nothing away.", {"money": -250})),
  C("Start looking for somewhere new",
    O("It took two months and a lot of tabs. The new flat has a better window.", {"stress": 6, "money": -500, "happiness": 2}),
    O("Everything within budget was a no-pets clause. Eventually I found a little place that said yes.", {"stress": 8, "money": -400})),
  cooldown=30)

E("walk_stranger", "🦮", "The dog walk",
  "On a morning walk, someone with their own animal stops to talk. You've seen them here before.",
  {"has_pet": True},
  C("Chat",
    O("We talked about the animals and then, for twenty minutes, about everything else. It turned out we lived on the same road.", {"happiness": 5}),
    O("A nice conversation about nothing. We nodded at each other for the rest of the year, and sometimes more.", {"happiness": 3})),
  C("Nod and walk on",
    O("Politeness achieved. Nothing ventured. The animal looked back, which felt like a reproach.", {"happiness": 0}),
    O("A nod. A smile. Our animals did all the real talking.", {"happiness": 1})),
  C("Ask them for coffee",
    O("We got coffee. The animals lay under the table and plotted. We're still friends.", {"happiness": 6, "money": -5}),
    O("They said yes. A decent hour, a good chat, and a plan for the weekend.", {"happiness": 5, "money": -5})),
  cooldown=12)

# ---------------------------------------------------------------- follow-ups
F("grown", "🌱", "Look how you've grown", "The animal you took in has settled into the house in a way that is hard to remember not having. Someone mentions how much it has changed you, too.", 3,
  ["co.porch_cat", "co.friend_litter", "co.gift_pet", "co.pet_shop_window", "co.kittens_box", "co.lost_dog", "co.neighbour_moves"], {"has_pet": True},
  C("Say it's the best thing you did",
    O("It was easy to say because it was true. The animal looked up as if it had understood.", {"happiness": 6}),
    O("I told them. They said they could tell. I think that's the nicest thing anyone said all year.", {"happiness": 5})),
  C("Joke about the vet bills",
    O("We laughed, and I paid the vet bill the next day with a good heart.", {"happiness": 3}),
    O("We joked about the money. We both knew I'd pay it all again.", {"happiness": 3})),
  C("Make a plan for its future",
    O("I wrote down a list: insurance, a will with a line for the animal, the number of a good sitter. I felt like a grown-up.", {"stress": -2, "happiness": 3}),
    O("A tidy, practical afternoon. The animal slept through all of it.", {"stress": -2, "happiness": 2})))

F("goodbye_pet", "🌈", "A hard conversation", "The vet has said the thing vets say. The animal is old, the animal is tired, and the decision is going to be made, one way or another, this week.", 6,
  ["co.porch_cat", "co.friend_litter", "co.pet_shop_window", "co.inherited_pet", "co.lost_dog"], {"has_pet": True, "age": [14, 100]},
  C("Stay with them to the end",
    O("I held them. They looked at me the whole time. It was the worst and the most important hour of the year.", {"happiness": -10, "stress": 8, "karma": 4}),
    O("I stayed. The room was quiet. I think we both knew. It was done with love.", {"happiness": -8, "stress": 6, "karma": 4})),
  C("Take them home for a last good day",
    O("A last day: the park, the good food, the sofa. The next morning we went. I would do it the same way again.", {"happiness": -6, "stress": 5, "karma": 3}),
    O("We had a perfect, ordinary day. It was the right way to end it.", {"happiness": -6, "stress": 4})),
  C("Let someone else take them in",
    O("I could not. A friend went with them. I have carried that for a long time.", {"happiness": -12, "stress": 8, "karma": -2}),
    O("I stayed in the car. I regret it, and I understand why I did it.", {"happiness": -10, "stress": 7})))

for (fid, years, sources) in FOLLOW:
    for e in EV:
        if e["id"] in sources:
            for ch in e["choices"]:
                for o in ch["outcomes"]:
                    if "schedule" not in o:
                        o["schedule"] = {"event": fid, "years": [years, years + 2]}

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "companions.json")
json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
print("companions.json: %d events" % len(EV))

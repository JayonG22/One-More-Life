#!/usr/bin/env python3
"""Alcohol, drugs, life-threatening moments, bad and good decisions, and unexpected turns (v0.25)."""
from dsl import *
def A(id, icon, title, text, cond, *ch, **kw):
    c = {"age": [15, 90]}; c.update(cond)
    E(id, icon, title, text, c, *ch, prefix="alc.", **kw)
def Dr(id, icon, title, text, cond, *ch, **kw):
    c = {"age": [14, 80]}; c.update(cond)
    E(id, icon, title, text, c, *ch, prefix="drug.", **kw)
def L(id, icon, title, text, cond, *ch, **kw):
    E(id, icon, title, text, cond, *ch, prefix="risk.", **kw)
def B(id, icon, title, text, cond, *ch, **kw):
    E(id, icon, title, text, cond, *ch, prefix="bad.", **kw)
def Gd(id, icon, title, text, cond, *ch, **kw):
    E(id, icon, title, text, cond, *ch, prefix="good.", **kw)
def T(id, icon, title, text, cond, *ch, **kw):
    E(id, icon, title, text, cond, *ch, prefix="turn.", **kw)

# ------------------------------------------------------------------ ALCOHOL
A("first_drink", "🥃", "The first proper drink", "Someone older has pushed a plastic cup into your hand at a party. 'Go on,' they say. 'Everybody does.'", {"age": [14, 20], "not_flags": ["had_first_drink"]},
  C("Take a sip and put it down", O("It tasted terrible. I felt oddly grown-up for about four minutes.", {"happiness": 2}, flags=["had_first_drink"]), O("It tasted like the inside of a cough bottle. I kept the cup all night.", {"stress": 2}, flags=["had_first_drink"])),
  C("Down it", O("The room tilted pleasantly. By midnight I was the funniest person alive. By morning, I was not.", {"happiness": 3, "health": -3}, flags=["had_first_drink"], habit={"drinking": 6}), O("I threw up in a hedge. Someone held my hair.", {"health": -3, "stress": 4}, flags=["had_first_drink"], habit={"drinking": 3})),
  C("Say no", O("Nobody cared as much as I'd feared. A girl said she was impressed.", {"happiness": 2, "karma": 1}), O("They teased me. It faded.", {"stress": 3, "happiness": -1})))
A("pub_quiz", "🍺", "Pub night", "Thursday means the pub, which means a quiz team and a pint. The third pint arrives without being ordered.", {"age": [18, 80]},
  C("Stop at two", O("We came second. I walked home clear-headed.", {"happiness": 4, "money": -20}), O("We came last. I laughed all the way home anyway.", {"happiness": 3, "money": -20})),
  C("Keep going", O("A great night, a bad morning.", {"happiness": 4, "health": -3, "money": -45}, habit={"drinking": 4}), O("I got into an argument about geography. I was wrong, loudly.", {"happiness": 0, "health": -3, "money": -45, "karma": -1}, habit={"drinking": 4})),
  C("Switch to water", O("My team teased me and then forgot. Nobody minded.", {"health": 1, "happiness": 2}), O("The quiz master gave me a free orange juice. Chivalry.", {"happiness": 2})))
A("drunk_text", "📲", "Messages at 2 a.m.", "You wake up with your phone in your hand, and the sick lurch of a feeling that you've sent something.", {"age": [18, 70], "habit_min": {"drinking": 15}},
  C("Check the messages", O("It was a long, soppy message to an ex. They hadn't replied. A small mercy.", {"stress": 6, "happiness": -3}), O("It was to my boss. It just said 'I love you man'. He sent a thumbs-up.", {"stress": 4, "happiness": 1})),
  C("Delete everything", O("It was too late; they'd seen it. I apologised in the morning.", {"stress": 5, "karma": -1}), O("I deleted it, then checked, and found it hadn't sent. I breathed.", {"stress": 1})),
  C("Resolve to drink less", O("I really did, for about nine days.", {"stress": -1, "karma": 1}, habit={"drinking": -4}), O("I did, and I told someone. It helped.", {"karma": 2, "happiness": 2}, habit={"drinking": -8})))
A("drive_home", "🚗", "The keys in your hand", "It's one a.m. You've had four drinks and you feel fine. The taxi queue is long, and your car is just around the corner.", {"age": [17, 85], "has_car": True},
  C("Call a taxi", O("It cost forty dollars and a hundred percent of my anxiety. Worth it.", {"money": -40, "stress": -3, "karma": 2}), O("It took an hour. I got home. Nothing happened. That's the point.", {"money": -40, "karma": 2})),
  C("Drive carefully", O("I got home. I did not sleep. I thought about every moment of the drive.", {"stress": 8, "karma": -3}, habit={"drinking": 3}), O("Blue lights in the mirror. A breath test. I failed it.", {"fine": 1200, "karma": -4, "stress": 10}, license_suspend=True)),
  C("Sleep in the car", O("It was cold, but I was safe. A little foolish, mostly sensible.", {"health": -1, "stress": 3, "karma": 1}), O("A police officer tapped on the window at 3. She was kind about it.", {"stress": 5, "karma": 0})))
A("hangover", "🤕", "The Monday after", "You wake up on the sofa fully clothed, and it takes a beat to remember there's a presentation at nine. The room is far too bright.", {"age": [18, 70], "employed": True},
  C("Go in and fake it", O("I got through it, grey and polite. Nobody noticed. I swore off drink for a whole week.", {"job_perf": -1, "health": -2, "stress": 4}), O("The boss smelled it. He said nothing, which was worse.", {"job_perf": -5, "stress": 7})),
  C("Call in sick", O("I slept until two, ate toast, and felt almost human. The guilt was bearable.", {"health": 1, "job_perf": -1}), O("I called in sick. A colleague saw my photos from Saturday. Awkward.", {"job_perf": -3, "stress": 4})),
  C("Own up to it", O("I told my boss the truth. He laughed and said 'been there'. It was strangely bonding.", {"job_perf": 1, "karma": 2}), O("I told my boss. He didn't laugh. I got a quiet note on my file.", {"job_perf": -4, "karma": 2})))
A("wedding_toast", "🥂", "The toast", "At a wedding, the champagne has been flowing for hours, and the best man has just handed you the microphone. 'Say something!'", {"age": [18, 80]},
  C("Give a heartfelt toast", O("I spoke about the couple and meant every word. The room went soft.", {"happiness": 6, "karma": 2}), O("I lost the thread, wept openly, and got a standing ovation.", {"happiness": 5, "stress": 3})),
  C("Tell an embarrassing story", O("It brought the house down. The groom pretended to hate me.", {"happiness": 5}), O("It was a bit too embarrassing. The groom's mother left.", {"karma": -3, "stress": 5})),
  C("Decline and sit down", O("Someone else took it. I had a quiet drink and felt fine.", {"stress": -1}), O("I regretted it all evening.", {"happiness": -2})))
A("blackout", "🌫️", "Gaps in the night", "You wake up in a place you don't recognise with a stranger's coat over you and no memory of the last five hours.", {"age": [18, 70], "habit_min": {"drinking": 20}},
  C("Piece it together", O("A friend filled in the blanks. I'd been charming, apparently, and had lost a shoe.", {"stress": 3, "happiness": 1}, habit={"drinking": 2}), O("The night had a darker shape. I'd said things. I owed apologies.", {"stress": 8, "karma": -2, "happiness": -3})),
  C("Leave quietly", O("I got a taxi home. The shame lasted a week.", {"stress": 6, "money": -35}), O("I found my phone, my wallet, my keys. A miracle.", {"stress": 4})),
  C("Decide to cut back", O("I really meant it. The first month was hard.", {"karma": 2, "stress": 3}, habit={"drinking": -8}), O("I told a friend. She made me promise. It helped.", {"karma": 3, "happiness": 2}, habit={"drinking": -10})))
A("sober_month", "🍋", "Dry month", "A friend challenges you to a month without alcohol, for charity. The pledge sheet is on the fridge, and you've already signed it.", {"age": [18, 70]},
  C("Do the whole month", O("I felt a bit better, slept well and saved a lot. I was surprised.", {"health": 4, "money": 100, "happiness": 3, "karma": 2}, habit={"drinking": -6}), O("It was a hard month, but I did it. We raised eight hundred dollars.", {"health": 3, "karma": 3, "stress": 3}, habit={"drinking": -6})),
  C("Fail on the weekend", O("I had one. Then three. The sheet stayed on the fridge.", {"karma": -1, "happiness": 1}, habit={"drinking": 2}), O("I told them and paid up anyway. It was honest.", {"money": -30, "karma": 2})),
  C("Don't start", O("Nobody remembered by Wednesday.", {"stress": 0}), O("I felt bad. The charity could have used it.", {"karma": -1})))
A("rehab_offer", "🏥", "An intervention", "Your family are sitting in your kitchen, holding letters. Your sister says, 'We love you. We're worried.' You can see their faces and you can see a bottle on the shelf.", {"age": [18, 80], "habit_active": ["drinking"]},
  C("Listen and agree to try", O("It was the hardest hour of my life. I started a programme the following Monday.", {"karma": 6, "happiness": 3, "stress": 8, "money": -2000}, habit={"drinking": -25}), O("I agreed. I relapsed. But I'd started, and they didn't give up.", {"karma": 3, "stress": 6}, habit={"drinking": -8})),
  C("Deny everything", O("I walked out, furious. I didn't speak to my sister for a year.", {"happiness": -6, "stress": 8}, habit={"drinking": 4}), O("They gave me space. It hurt them more than me.", {"happiness": -3, "karma": -2})),
  C("Cry", O("We held each other. I made a promise and kept it, one day at a time.", {"happiness": 3, "karma": 4}, habit={"drinking": -15}), O("I cried. I promised. I didn't keep it.", {"happiness": -2, "karma": -2})))
A("work_function", "🍷", "Christmas party", "The firm's Christmas party has an open bar and a boss who has loosened his tie. A senior partner has just put a glass in your hand.", {"employed": True, "age": [18, 70]},
  C("Drink moderately", O("Charming, sociable, and out by ten. I made a good impression.", {"job_perf": 3, "happiness": 3}), O("I had a decent time and woke up fresh.", {"happiness": 3})),
  C("Go big", O("I danced on a table. It will never be forgotten.", {"happiness": 4, "job_perf": -6, "karma": -1}, habit={"drinking": 3}), O("I told the CEO exactly what I thought. In detail. In front of everyone.", {"job_perf": -9, "stress": 8}, habit={"drinking": 4})),
  C("Don't drink at all", O("I was the designated driver for four colleagues. They loved me.", {"karma": 3, "job_perf": 2}), O("I was teased, and then forgiven.", {"stress": 2})))
A("beer_garden", "🍻", "The long afternoon", "It's a rare hot day. Friends, a beer garden, and no plans until tomorrow. Someone is ordering the next round.", {"age": [18, 70]},
  C("Just one more", O("There's no such thing, but I enjoyed the lie.", {"happiness": 4, "money": -40, "health": -1}, habit={"drinking": 3}), O("Three more, and an ill-advised karaoke. I'll never speak of it.", {"happiness": 2, "money": -70, "health": -3}, habit={"drinking": 5})),
  C("Leave on a high", O("I walked home in the golden light. A perfect afternoon.", {"happiness": 6}), O("I left, and the party got better. FOMO is real.", {"happiness": 2, "stress": 1})),
  C("Switch to soft drinks", O("I stayed clear, and remembered every joke.", {"happiness": 4, "money": -10}), O("I became the designated one. It's a role, and I liked it.", {"karma": 2, "happiness": 3})))
A("liver_check", "🩺", "Blood results", "The doctor has the results of your routine blood test and is looking at you over the top of her glasses. 'Let's talk about your liver.'", {"age": [25, 85], "habit_min": {"drinking": 40}},
  C("Take it seriously", O("I cut back, started walking, and the next test was better. A real turning point.", {"health": 5, "karma": 2}, habit={"drinking": -15}), O("I cut back for a while. It crept up again.", {"health": 1}, habit={"drinking": -6})),
  C("Brush it off", O("I told her it was a bad week. She wrote something on the chart.", {"stress": 3}), O("A year later it was worse.", {"health": -6, "stress": 6}, illness="liver trouble")),
  C("Seek help", O("A support group on Tuesday nights. A dozen strangers, one very good coffee urn.", {"happiness": 3, "karma": 3}, habit={"drinking": -12}), O("The first meeting was awkward. The second was better.", {"karma": 2}, habit={"drinking": -8})))
A("sober_birthday", "🎂", "A year clean", "Today is the day. One year without a drink. You've got a keyring chip in your hand and a lump in your throat.", {"age": [20, 90], "habit_max": {"drinking": 20}, "flags": ["had_first_drink"], "chance": 0.15},
  C("Share it with someone", O("My sponsor hugged me. I cried in a good way.", {"happiness": 8, "karma": 3}), O("I told my family. They were so proud it hurt.", {"happiness": 7})),
  C("Celebrate quietly", O("A big mug of tea and a long walk. A lovely day.", {"happiness": 5}), O("I stared at the bottle shop on the way home and kept walking.", {"happiness": 3, "karma": 1})),
  C("Test yourself", O("I held a glass at a party and put it down. Proud and shaky.", {"stress": 5, "karma": 1}), O("I tested it too soon. Not a good idea.", {"happiness": -3, "stress": 6}, habit={"drinking": 8})))
A("bar_fight", "🥊", "Last orders", "At closing time a man steps on your foot, loudly blames you, and squares up. His friends are fanning out behind him.", {"age": [18, 55]},
  C("Walk away", O("I walked out into the cold air feeling both a coward and a genius.", {"stress": 3, "karma": 1}), O("They followed, but a bouncer stopped them. I owe that man a beer.", {"stress": 5})),
  C("Throw the first punch", O("It ended badly. I lost a tooth and a night in the cells.", {"health": -6, "karma": -3, "stress": 8}, fine=300), O("A short brawl, a bloody nose and a lot of regret.", {"health": -4, "karma": -3, "stress": 6})),
  C("Try to talk them down", O("It worked, to my own amazement. We shook hands.", {"karma": 3, "happiness": 3}), O("It didn't. I got hit anyway.", {"health": -3, "stress": 4})))
A("hosting", "🍾", "Hosting a dinner", "Eight guests, a six-course menu, and the wine. The bottle of nice red is gone. Your guests are in great voice.", {"age": [22, 85]},
  C("Open another bottle", O("A warm, blurry, laughing evening. Everyone left glowing.", {"happiness": 6, "money": -40}, habit={"drinking": 2}), O("The conversation turned nasty at midnight. Someone left in tears.", {"happiness": -2, "stress": 5, "money": -40})),
  C("Switch to coffee", O("A gentle wind-down. The chat got deeper.", {"happiness": 4}), O("A few people were disappointed. Most were relieved.", {"happiness": 1})),
  C("Cut the evening short", O("Awkward but safe. People understood.", {"stress": -1}), O("They thought I was being rude. A week of messages.", {"stress": 4})))

# ------------------------------------------------------------------ DRUGS
Dr("offer_party", "💊", "Passed around", "At a house party, a bag is going round the room. When it reaches you, everyone's looking at you without looking at you.", {"age": [15, 40], "not_flags": ["tried_drugs"]},
  C("Take one", O("An hour of pure wonder, then a long grey comedown. I was frightened by how much I'd liked it.", {"happiness": 4, "health": -4, "stress": 4}, flags=["tried_drugs"], habit={"drugs": 12}), O("Nothing happened for ages, then everything did. I was sick in the garden.", {"health": -5, "stress": 6}, flags=["tried_drugs"], habit={"drugs": 8})),
  C("Pass it on", O("Nobody minded. A girl at the end said, 'Smart.' I found I agreed.", {"karma": 2, "happiness": 2}), O("I felt out of place for the rest of the night, but proud of it.", {"karma": 1})),
  C("Leave the party", O("I walked home under streetlights, a bit shaky and a bit free.", {"stress": 2, "karma": 2}), O("I phoned my mum from the bus stop. We chatted for an hour.", {"happiness": 4, "karma": 2})))
Dr("edible", "🍪", "The brownie", "Someone has made a tray of brownies. 'Special ones,' they say quietly. You've had one. It's been forty minutes and you feel nothing, and the tray looks very tempting.", {"age": [18, 60]},
  C("Wait it out", O("Eventually it hit. I spent two hours staring at a lamp, utterly content.", {"happiness": 4, "stress": -4}, habit={"drugs": 3}), O("It hit hard. I thought the sofa was breathing.", {"happiness": -2, "stress": 6}, habit={"drugs": 3})),
  C("Eat another", O("A terrible idea. I spent the night hugging a bin.", {"health": -4, "stress": 7}, habit={"drugs": 4}), O("I discovered several things I love about cheese.", {"happiness": 3, "health": -2}, habit={"drugs": 4})),
  C("Go home and sleep", O("I woke up fine and slightly embarrassed.", {"stress": 1}), O("It hit at 3 a.m. in bed. A strange and blissful hour.", {"happiness": 2}, habit={"drugs": 2})))
Dr("dealer_knock", "🚪", "Someone at the door", "A friend of a friend has turned up at your flat, polite, with a small bag. 'First one's free,' he says. 'For the friend of a friend.'", {"age": [18, 55], "habit_min": {"drugs": 10}},
  C("Take it", O("Free things are never free. A month later, I owed him.", {"money": -300, "stress": 8, "karma": -2}, habit={"drugs": 12}), O("It was fine. I wanted more. That was the problem.", {"happiness": 2, "stress": 4}, habit={"drugs": 10})),
  C("Send him away", O("He shrugged and left. It was so easy that I was annoyed with myself for being scared.", {"karma": 2, "stress": -1}), O("He came back. I called a friend who dealt with it.", {"stress": 5, "karma": 1})),
  C("Call the police", O("I did the right thing. I also looked over my shoulder for months.", {"karma": 3, "stress": 7}), O("They came and found nothing. He'd gone. I felt silly and safe.", {"stress": 2})))
Dr("overdose_scare", "🚑", "Not breathing right", "At 4 a.m. your friend is grey and slumped against the wall, breathing slow and shallow, and everyone else has gone very still.", {"age": [16, 60]},
  C("Call an ambulance", O("They came in eight minutes. He lived. The doctor said, 'You saved him.' I didn't feel like it.", {"karma": 9, "stress": 10}), O("Everyone ran. I stayed, and so did he. He lived. We both changed.", {"karma": 8, "stress": 12})),
  C("Try to wake him", O("He came round after a long minute, groggy and ashamed. We never discussed it.", {"stress": 8, "karma": 2}), O("He didn't. I phoned the ambulance, too late to matter much, and he was in hospital for days.", {"stress": 12, "karma": 3})),
  C("Leave", O("I never knew what happened. I think about it all the time.", {"karma": -10, "stress": 12}), O("Someone else called. He lived. I didn't speak to anyone for a week.", {"karma": -8, "stress": 10})))
Dr("pressure_pills", "💼", "Focus", "A colleague slips you a small packet at lunch. 'Just for the deadline. It'll change your life.'", {"employed": True, "age": [20, 55]},
  C("Take one", O("Three days of terrifying focus. I finished everything and couldn't sleep for a week.", {"job_perf": 6, "health": -5, "stress": 6}, habit={"drugs": 8}), O("I rushed through the work and made mistakes I didn't notice.", {"job_perf": -3, "health": -4}, habit={"drugs": 6})),
  C("Say no", O("I stayed up the old way, with coffee. It was exhausting and clean.", {"job_perf": 1, "stress": 5, "karma": 1}), O("I told HR later. They thanked me and handled it quietly.", {"karma": 3, "stress": 3})),
  C("Report it", O("It was handled discreetly. My colleague transferred. I felt both right and cold.", {"karma": 2, "stress": 5}), O("They didn't believe me. Awkward months followed.", {"stress": 8, "job_perf": -3})))
Dr("withdrawal", "🥶", "The shakes", "Three days without, and your hands won't hold a cup. The ceiling is crawling. The phone is at your elbow with a number you know by heart.", {"age": [16, 80], "habit_active": ["drugs"]},
  C("Ride it out", O("A bad week. I came out thin and clear.", {"health": -5, "stress": 9, "karma": 3}, habit={"drugs": -15}), O("I lasted two days and gave in, ashamed.", {"stress": 8, "karma": -2}, habit={"drugs": 5})),
  C("Call for help", O("A clinic took me in. It was gentle and terrifying and right.", {"karma": 4, "money": -1500, "stress": 5}, habit={"drugs": -20}), O("A helpline picked up at 4 a.m. and stayed on for an hour.", {"karma": 3, "stress": 4}, habit={"drugs": -10})),
  C("Use again", O("It made the shaking stop. It didn't make anything else stop.", {"happiness": -4, "health": -3, "money": -200}, habit={"drugs": 6}), O("It was a relief and an ending.", {"happiness": -5, "karma": -2}, habit={"drugs": 8})))
Dr("clean_streak", "🌱", "Six months clean", "There's a small white chip in your palm and a room full of folding chairs. They're clapping and you don't know where to put your hands.", {"age": [18, 80], "habit_max": {"drugs": 25}, "flags": ["tried_drugs"], "chance": 0.12},
  C("Say a few words", O("I said six sentences and sat down shaking. People wept. So did I.", {"happiness": 7, "karma": 4}), O("I said one. It was enough.", {"happiness": 5, "karma": 2})),
  C("Take the chip and sit", O("A small beautiful moment, privately mine.", {"happiness": 5}), O("Someone sat next to me and said nothing. It meant everything.", {"happiness": 6, "karma": 2})),
  C("Leave early", O("Pride and fear. I came back next week.", {"stress": 3}), O("I wasn't ready. I came back eventually.", {"stress": 4, "happiness": -1})))
Dr("painkillers", "🏥", "After the surgery", "The prescription is generous. Two weeks later the pain has gone but the pills have not, and the bottle on the bedside table is nearly empty.", {"age": [20, 80], "has_injury": ""},
  C("Taper off with the doctor", O("A slow, careful taper. I felt each dose go and I was fine.", {"health": 2, "karma": 2}), O("It was harder than I'd thought. The doctor stuck with me.", {"stress": 5, "karma": 2})),
  C("Ask for a refill", O("She gave one, with a look. I took more than I should.", {"health": -2, "stress": 3}, habit={"drugs": 8}), O("She refused. I found another source.", {"karma": -3, "stress": 5, "money": -80}, habit={"drugs": 12})),
  C("Stop abruptly", O("A bad few days. A clear mind after.", {"health": -2, "stress": 6}), O("I hadn't needed them for a week. I'd been scared of the pain.", {"stress": 2, "health": 1})))
Dr("friend_using", "💔", "A friend slipping", "Your oldest friend has been missing plans, borrowing money, and looking at the wall when you speak to them. You think you know why.", {"age": [16, 70]},
  C("Talk to them directly", O("They broke down. We spent the night talking. They agreed to see someone.", {"karma": 5, "happiness": 2, "stress": 6}), O("They denied everything, and cut me off for a while. Later they apologised.", {"stress": 7, "karma": 2})),
  C("Give them money", O("It went exactly where I feared. I felt used.", {"money": -300, "karma": -1, "stress": 5}), O("It helped them get through a bad week. I never knew where it went.", {"money": -300, "karma": 1})),
  C("Step back", O("It was self-protection. I mourned a bit.", {"stress": 3, "karma": -2}), O("They got better, eventually, without me. I don't know how I feel.", {"stress": 2})))
Dr("festival", "🎪", "Festival field", "Three days in a field with a hundred thousand strangers. Someone hands you a tiny paper square. 'It's going to be a beautiful night.'", {"age": [17, 45]},
  C("Try it", O("The night was a river of stars. I laughed until sunrise. I also didn't sleep for two days.", {"happiness": 6, "health": -4}, habit={"drugs": 8}), O("It went wrong. A medic tent and a very kind stranger.", {"health": -5, "stress": 8}, habit={"drugs": 5})),
  C("Say no thanks", O("I danced anyway, clear-eyed. Best festival ever.", {"happiness": 6, "karma": 1}), O("I spent the night at the back, watching. Fine.", {"happiness": 2})),
  C("Keep it for later", O("I forgot about it. I found it in my sock a week later and threw it away.", {"stress": 1}), O("My bag was searched at the exit. The paper was in my pocket.", {"fine": 300, "stress": 7, "karma": -2})))
Dr("search_bag", "👮", "A search at the gate", "Security have asked to look in your bag. At the bottom, in a paper envelope you'd forgotten, is something you shouldn't have brought.", {"age": [16, 60]},
  C("Be honest", O("A caution, a lecture and a very polite officer. I walked away shaken and grateful.", {"stress": 6, "karma": 2}), O("A fine and a warning. It could have been much worse.", {"fine": 250, "stress": 7, "karma": 1})),
  C("Say it isn't yours", O("They didn't believe me. It was awkward, and then it was serious.", {"fine": 600, "karma": -3, "stress": 10}, record="drug possession"), O("A friend took the blame. I owe them forever.", {"karma": -6, "stress": 7})),
  C("Run", O("I made it. My heart is still thumping from that.", {"stress": 8, "karma": -2}), O("A barrier stopped me. It got messy.", {"health": -3, "stress": 10, "fine": 800}, record="drug possession")))

# ------------------------------------------------------------------ LIFE-THREATENING
L("car_skid", "🚗", "The wet bend", "The road bends left and the car does not. For one long second there is nothing but a hedge, a ditch and your own breath.", {"age": [17, 85], "has_car": True},
  C("Steer into the skid", O("The tyres bit. The car came straight. I stopped on the verge and shook for twenty minutes.", {"stress": 8, "smarts": 1}), O("It spun once, slowly, and stopped facing the way I'd come. I was completely unharmed.", {"stress": 9})),
  C("Brake hard", O("The car spun and hit the bank. Airbags, a cracked rib, a write-off.", {"health": -12, "stress": 10, "money": -2000}), O("The car slid sideways and clipped a post. A very expensive scrape.", {"health": -3, "money": -900, "stress": 7})),
  C("Close your eyes", O("When I opened them the car was in a field. Intact. I don't know how.", {"stress": 10}), O("I woke in an ambulance. I was lucky.", {"health": -15, "stress": 12, "money": -1500})))
L("house_fire", "🔥", "Smoke on the stairs", "You wake at 3 a.m. to a smell you can't place and a noise that isn't the cat. The landing is full of grey smoke.", {"age": [8, 90], "housing": ["house", "rent", "family", "flat"]},
  C("Get everyone out", O("I woke everyone and we stood on the pavement in pyjamas watching the engines arrive. It could have been far worse.", {"karma": 4, "stress": 10, "health": -2}), O("We got out. The house didn't recover. We lost almost everything.", {"stress": 14, "money": -3000, "karma": 3})),
  C("Go back for something", O("I went back for the photo albums and nearly didn't make it out. The albums survived.", {"health": -8, "stress": 12, "karma": -1}), O("I got the dog and the laptop. It was a stupid risk.", {"health": -5, "stress": 10})),
  C("Call the fire brigade first", O("The call took sixty seconds. They were here in six minutes. The fire was out by four.", {"stress": 9, "money": -800}), O("The line was busy. I counted to ten and tried again.", {"stress": 12, "health": -2})))
L("swim_current", "🌊", "The rip", "You swam out further than you meant to. When you turn, the shore is a long, thin line and the water is taking you sideways.", {"age": [8, 70]},
  C("Swim parallel to the shore", O("It took twenty minutes. I crawled up the sand, shaking and humble.", {"stress": 8, "health": -2, "smarts": 1}), O("A lifeguard's board arrived just as my arms gave out.", {"stress": 10, "karma": 0})),
  C("Fight straight back", O("I swallowed seawater and made no progress. Someone threw me a ring.", {"health": -5, "stress": 10}), O("I almost didn't make it. A stranger dragged me in.", {"health": -8, "stress": 13, "karma": 2})),
  C("Float and wave", O("Rescued in four minutes. It looked silly, and I'd do it again.", {"stress": 7}), O("Nobody saw. I floated for a long hour until I was close enough.", {"stress": 12, "health": -4})))
L("heart_flutter", "❤️", "The tightness", "It starts as a heaviness behind the breastbone while carrying shopping. Then your left arm goes strange, and you sit down on a bench, very carefully.", {"age": [35, 90]},
  C("Call an ambulance", O("It was a heart attack, caught early. They stented me within the hour.", {"health": -8, "stress": 10, "karma": 0}, illness="heart disease"), O("It was a panic attack. The paramedic was kind. I felt foolish and relieved.", {"stress": 6})),
  C("Sit and wait", O("It passed. I told no one. I was lucky.", {"stress": 8}), O("It got worse. A passer-by dialled for me. I owe that stranger my life.", {"health": -12, "stress": 12}, illness="heart disease")),
  C("Walk to the doctor's", O("She took one look and called an ambulance. Strict, quick, right.", {"health": -5, "stress": 8}), O("She wasn't in. I sat in the waiting room and nearly fainted.", {"health": -8, "stress": 11})))
L("choking", "🍽️", "A restaurant, a silence", "Across the table, your companion has stopped mid-sentence. Their hand goes to their throat and their eyes widen. Nobody else has noticed.", {"age": [10, 90]},
  C("Perform the Heimlich", O("Three thrusts and a piece of steak shot across the room. The restaurant applauded.", {"karma": 8, "stress": 7, "happiness": 4}), O("Four attempts. It worked on the last. I've never had my heart beat like that.", {"karma": 8, "stress": 10})),
  C("Shout for help", O("A chef ran over and saved them. I stood there feeling useless.", {"stress": 8, "karma": 1}), O("Someone who knew what to do stepped in, calm as anything.", {"stress": 6, "karma": 2})),
  C("Freeze", O("A waiter acted first. I thought about that moment for a long time.", {"stress": 10, "karma": -2}), O("The moment passed and they coughed it out themselves. I will never forgive myself for freezing.", {"stress": 10, "karma": -2})))
L("lost_hiking", "⛰️", "The wrong ridge", "The cloud came down faster than the forecast said. The path has vanished, your phone shows no signal, and it will be dark in two hours.", {"age": [14, 75]},
  C("Stay put and signal", O("Mountain rescue found me by torchlight at nine. I'd never been so glad to see an orange jacket.", {"stress": 9, "karma": 0}), O("I stayed put. A shepherd found me in the morning, sipping tea from my flask.", {"stress": 7})),
  C("Descend by the stream", O("It led to a farm. A warm kitchen and a lot of explaining.", {"stress": 6, "health": -2}), O("It led to a ravine. I clung to a rock for an hour before climbing out.", {"health": -8, "stress": 12})),
  C("Push on in the dark", O("I made the road at midnight, scratched, cold, alive.", {"health": -5, "stress": 10}), O("I fell. A broken ankle, two cold nights, and a very good helicopter.", {"health": -14, "stress": 14, "money": -400})))
L("allergy", "🥜", "A reaction", "A mouthful in, your lips tingle. Your tongue is swelling, your throat feels thick, and the dessert on your fork has nuts in it, you realise.", {"age": [5, 85]},
  C("Use the auto-injector", O("It worked within minutes. My heart raced, my hands shook, and I lived.", {"stress": 8, "health": -3}), O("I didn't have one. A stranger did. I'll never forget the face.", {"stress": 11, "health": -6, "karma": 0})),
  C("Call an ambulance", O("They were quick. Adrenaline, a drip and an overnight stay.", {"health": -5, "stress": 9, "money": -300}), O("They were slow. It was the worst fifteen minutes of my life.", {"health": -9, "stress": 13})),
  C("Wait and see", O("It eased. I was stupidly lucky.", {"stress": 8}), O("It didn't ease. I was hospitalised for three days.", {"health": -12, "stress": 12, "money": -600})))
L("mugging", "🔪", "The alley", "Walking home, a voice behind you says 'Wallet.' The word is quiet and the thing against your back is not a finger.", {"age": [14, 85]},
  C("Hand it over", O("He took it and ran. I stood and shook. The money was replaceable; I was fine.", {"money": -120, "stress": 9}), O("He took it and my phone. I called the police from a shop.", {"money": -400, "stress": 10})),
  C("Fight", O("I got a cut on the arm and he got my wallet anyway. It was a bad idea.", {"health": -8, "money": -120, "stress": 11}), O("I surprised him. He ran. I sat on the kerb and laughed hysterically.", {"stress": 10, "karma": 0})),
  C("Run", O("I ran until my lungs burned. He didn't follow.", {"stress": 8, "health": -1}), O("He tripped me. A bad fall, a broken wrist.", {"health": -10, "stress": 11, "money": -150})))
L("diagnosis", "📋", "The scan", "The consultant has put the scan on the light box. For a long moment nobody speaks, and then she turns the chair around.", {"age": [30, 90]},
  C("Ask for the whole truth", O("It was serious, but treatable. A long road, but with a map.", {"health": -8, "stress": 12, "karma": 0}, illness="cancer"), O("It was benign. I laughed in the corridor until I cried.", {"stress": 8, "happiness": 4})),
  C("Bring someone with you next time", O("My sister held my hand through every appointment. We got through it together.", {"stress": 8, "happiness": 2, "karma": 1}), O("I couldn't ask. I went alone. It was lonely.", {"stress": 11, "happiness": -3})),
  C("Seek a second opinion", O("A second doctor agreed with the first, but offered a better plan.", {"health": 2, "stress": 8, "money": -300}), O("A second doctor found the first had been wrong. Nobody said sorry.", {"stress": 6, "happiness": 5, "money": -300})))
L("sleepwalk", "🌙", "Wrong side of the window", "You wake up on the balcony in your nightclothes, two floors up, with one leg over the rail and no memory of how you got there.", {"age": [10, 75]},
  C("Climb back slowly", O("My heart nearly burst. I locked the door and told no one for a month.", {"stress": 10}), O("I woke my flatmate. We both sat in the kitchen until dawn.", {"stress": 8, "happiness": 2})),
  C("Shout for help", O("A neighbour came. She held me by the belt until the police arrived.", {"stress": 11, "karma": 0}), O("Nobody heard. I got myself back.", {"stress": 10})),
  C("See a sleep specialist", O("A sleep study found the cause. The treatment worked.", {"health": 3, "stress": -3, "money": -250}), O("They found nothing. I installed a lock on the balcony.", {"stress": 4, "money": -80})))
L("train_platform", "🚆", "The platform edge", "You drop your phone at the platform's edge, the express is a mile off and the lights are rushing, and your fingers are already reaching.", {"age": [12, 80]},
  C("Leave it", O("The train came through and the phone was dust. I breathed for a full minute.", {"money": -400, "stress": 6}), O("A man grabbed my arm. 'Not worth it,' he said, and bought me a coffee.", {"stress": 6, "karma": 2})),
  C("Jump down for it", O("I made it back with a second to spare. I've never been so stupid or so lucky.", {"stress": 12, "health": -4}), O("It was very close. I was shaken for weeks.", {"stress": 13, "health": -6})),
  C("Shout and wave at the driver", O("The driver braked. Nobody was hurt, and everyone stared.", {"stress": 8, "karma": -1}), O("He didn't see. The phone was crushed.", {"stress": 8, "money": -400})))
L("pandemic_wave", "😷", "A new virus", "The news has gone from a footnote to a headline in a week. The shelves are bare, and your neighbour is coughing in a way you don't like.", {"age": [18, 90], "world": "pandemic"},
  C("Stay home", O("Weeks of quiet, bread-baking and boredom. We were fine.", {"stress": 4, "health": 1, "money": -100}), O("Lockdown cabin fever. The walls moved in.", {"stress": 8, "happiness": -4})),
  C("Carry on as normal", O("I caught it. A week in bed, a month of fatigue.", {"health": -8, "stress": 6}, illness="long covid"), O("I was fine. I felt reckless and relieved.", {"karma": -2, "stress": 3})),
  C("Volunteer", O("I delivered food to neighbours. I felt useful, and scared.", {"karma": 6, "stress": 7, "happiness": 3}), O("I caught it from a delivery. I recovered but I'm not the same.", {"karma": 5, "health": -9, "stress": 9})))
L("earthquake", "🏚️", "The floor moves", "The coffee cup walks across the table. Then the building begins to groan, and the ceiling light swings in great slow arcs.", {"age": [5, 90], "region_hazard": "quake"},
  C("Drop, cover, hold on", O("Thirty seconds that lasted a year. When it stopped, nobody was hurt.", {"stress": 10}), O("A bookcase fell where I'd been standing. I stared at it for an hour.", {"stress": 12})),
  C("Run outside", O("I made it to the street and dodged a falling sign. Dumb luck.", {"stress": 11, "health": -2}), O("Glass fell like rain. I was cut, but alive.", {"health": -7, "stress": 12})),
  C("Help someone", O("I pulled a neighbour from a doorway. I'll never forget their face.", {"karma": 8, "health": -4, "stress": 10}), O("I pulled them out and went back for another. It was a long night.", {"karma": 9, "health": -6, "stress": 12})))
L("flood", "🌧️", "Water in the house", "It rained for nine days. The river has stopped being a river and started being a lake, and the water is at the second step.", {"age": [6, 90], "region_hazard": "flood"},
  C("Move upstairs and wait", O("The water stopped at the fourth step. We lost the ground floor and nothing else.", {"stress": 10, "money": -2000}), O("It rose to the ceiling downstairs. We were rescued by boat.", {"stress": 14, "money": -5000, "health": -3})),
  C("Evacuate now", O("We left with a bag each and a photo album. The house was never the same.", {"stress": 11, "money": -3000}), O("The road was already gone. We went by a neighbour's tractor.", {"stress": 12, "karma": 1})),
  C("Sandbag the door", O("We held it all night. A brilliant, hopeless, beautiful fight.", {"karma": 3, "stress": 10, "health": -3}), O("It rose over the bags at 4 a.m. We lost.", {"stress": 12, "money": -3500})))
L("stalker", "👁️", "The same car again", "It's the third night you've seen the same dark car at the end of the road, engine off, someone sitting inside.", {"age": [16, 80]},
  C("Call the police", O("They found a man with a grievance and a camera. He was warned off. I slept badly for weeks.", {"stress": 9, "karma": 1}), O("They found nothing. I changed my routine for a month.", {"stress": 8})),
  C("Confront them", O("It was a private detective. He'd been hired by someone I knew. It took years to untangle.", {"stress": 10, "karma": 0}), O("They drove off. The car never came back.", {"stress": 6})),
  C("Tell a friend", O("Two of us watched from the window the following night. Nobody came.", {"stress": 5, "happiness": 1}), O("My friend thought I was paranoid. I wasn't.", {"stress": 8, "happiness": -2})))

# ------------------------------------------------------------------ BAD DECISIONS
B("shoplift_dare", "🛍️", "A dare in the shop", "Your friends have bet you can walk out with the biggest chocolate bar. The security guard is looking at his phone.", {"age": [10, 30]},
  C("Do it", O("I got away with it. The thrill lasted an hour. The sick feeling lasted a week.", {"karma": -4, "stress": 5}), O("The guard grabbed my collar. His face was very close. My mother had to pick me up.", {"karma": -4, "stress": 10, "fine": 100})),
  C("Pay for it", O("They groaned. I ate it in front of them, legally.", {"karma": 1, "happiness": 2, "money": -3}), O("They laughed. I laughed. It was a good chocolate bar.", {"happiness": 2, "money": -3})),
  C("Walk away", O("They called me boring. It stung for a day.", {"happiness": -1}), O("One of them followed. He wanted out too.", {"karma": 1})))
B("quit_in_anger", "🗑️", "The mug on the desk", "Your boss has just spoken to you in front of the entire office as though you were furniture. Your hand is already closing around your mug.", {"employed": True, "age": [18, 65]},
  C("Walk out", O("I walked out into the sunshine feeling like a hero. By Friday I felt like a fool.", {"happiness": 3, "money": -500, "stress": 6}, quit_job=True), O("I walked out. Two colleagues followed. We founded something later.", {"happiness": 4, "stress": 5}, quit_job=True)),
  C("Say something sharp and stay", O("It worked. The boss apologised, awkwardly, in the kitchen.", {"job_perf": 2, "stress": 3}), O("It did not. I was told to take a few days.", {"job_perf": -6, "stress": 7})),
  C("Swallow it", O("I stayed quiet and burned inside for weeks.", {"stress": 8, "happiness": -3}), O("I wrote an angry email and deleted it. It was cathartic.", {"stress": 3})))
B("credit_binge", "💳", "The card on the sofa", "It's 1 a.m. You have a card, a sale and a feeling. The basket total says $1,240 and the 'buy now' button looks inviting.", {"age": [18, 80]},
  C("Click", O("The parcels came in waves. I returned half and kept the rest. I felt guilty about the other half.", {"money": -1240, "happiness": 3, "stress": 4}, habit={"shopping": 8}), O("It all arrived and I didn't like any of it.", {"money": -1240, "happiness": -2, "stress": 5}, habit={"shopping": 6})),
  C("Close the laptop", O("I woke up relieved. The sale had ended. So had the urge.", {"stress": -2}), O("I thought about it for three days. Then I bought one thing.", {"money": -80, "happiness": 1})),
  C("Cut up the card", O("A dramatic gesture. A sensible one.", {"stress": -2, "karma": 1}), O("I cut it up, then ordered a new one the next day.", {"stress": 1})))
B("tell_secret", "🤐", "I wasn't supposed to say that", "A friend told you something in confidence. Now, three drinks in, a group is laughing, and the secret is on your tongue like a coin.", {"age": [14, 70]},
  C("Keep it", O("Nobody ever knew. My friend and I were closer for it.", {"karma": 3, "happiness": 1}), O("I kept it. It was heavy.", {"stress": 3, "karma": 2})),
  C("Tell them", O("It spread. My friend found out. It ended the friendship.", {"karma": -6, "happiness": -5, "stress": 8}), O("It got round. Something awful happened. I regretted it forever.", {"karma": -8, "stress": 10})),
  C("Hint at it", O("They guessed. They never said I told them.", {"karma": -2, "stress": 4}), O("They guessed, and told my friend that I'd hinted. I got a stern text.", {"karma": -3, "stress": 5})))
B("lie_resume", "📄", "A little embellishment", "The application form asks for 'degree'. You don't have one. You have three-quarters of a degree and a great deal of confidence.", {"age": [18, 60]},
  C("Tick the box", O("I got the interview and the job. I lived in fear for years.", {"job_perf": 3, "karma": -4, "stress": 6}), O("A background check caught it. I was dropped on the spot.", {"karma": -4, "stress": 9, "happiness": -4})),
  C("Be honest", O("They were impressed by the candour. I got an interview.", {"karma": 3, "job_perf": 2}), O("They filtered me out. It stung.", {"stress": 4})),
  C("Find a middle way", O("'Degree-level study.' It worked, and it was true.", {"smarts": 1}), O("They asked about it. I stumbled.", {"stress": 4})))
B("skip_checkup", "🩺", "The appointment you cancel", "The surgery has called to remind you of your check-up. You've got a meeting. You've got a lot going on. You cancel it, for the third time.", {"age": [30, 85]},
  C("Reschedule for next week", O("I went. It was fine. I felt silly for putting it off.", {"health": 1, "stress": -1}), O("I went. They found something small, early, easily dealt with.", {"health": 1, "karma": 0})),
  C("Cancel again", O("A year later, a minor problem was a bigger one.", {"health": -6, "stress": 7, "money": -400}), O("Nothing came of it. I got away with it.", {"stress": 0})),
  C("Go, but lie about your habits", O("The doctor smelled it on me anyway.", {"stress": 4}), O("It all came out. I felt scolded and cared for.", {"health": 1, "stress": 3})))
B("ghost_friend", "📵", "Leaving them on read", "A friend who had a bad year has sent three messages. You've read them all. They're sitting there, unanswered, like a stone in a shoe.", {"age": [14, 80]},
  C("Reply now", O("It was awkward at first, and then lovely. I should've done it sooner.", {"karma": 3, "happiness": 3}), O("They'd moved on, kindly. I felt a pang.", {"karma": 1})),
  C("Wait", O("A week passed. Then a month. We drifted.", {"karma": -3, "happiness": -2}), O("A year passed. I met them at a funeral. They hugged me.", {"karma": -1, "stress": 3})),
  C("Delete the chat", O("A clean break. I felt strange about it for years.", {"karma": -5, "stress": 3}), O("I deleted it. They noticed.", {"karma": -5, "stress": 5})))
B("speeding_fine", "📸", "Flash in the mirror", "A white flash in the rear mirror and the sinking certainty of a camera. It said forty on the sign, and you were doing fifty-eight.", {"age": [17, 85], "has_car": True},
  C("Pay the fine", O("A clean, painless payment. A reminder to be kinder to my foot.", {"money": -150, "stress": 2}), O("It came with penalty points. A fortnight of careful driving.", {"money": -150, "stress": 3})),
  C("Contest it", O("It was thrown out on a technicality. I danced in the kitchen.", {"happiness": 4}), O("I lost, and paid the full amount plus costs.", {"money": -350, "stress": 5})),
  C("Ignore it", O("A reminder arrived. Then a bigger one. Then a court date.", {"money": -500, "stress": 8, "karma": -2}), O("It vanished. I'll never know why.", {"stress": 1})))
B("revenge_post", "📢", "Post in haste", "After a nasty row, you've written a long, devastating post about the person involved. The cursor hovers over 'publish'.", {"age": [14, 70]},
  C("Post it", O("It got a hundred likes and a hundred regrets. I lost a friend and gained an enemy.", {"happiness": -4, "karma": -5, "stress": 8}), O("It went viral. People took sides, and I wasn't winning.", {"fame": 1, "karma": -5, "stress": 10})),
  C("Sleep on it", O("In the morning, it read like a stranger's anger. I deleted it.", {"karma": 2, "stress": -3}), O("In the morning, I still meant it, but I knew better.", {"karma": 1})),
  C("Send it only to a friend", O("She read it, sighed, and said 'don't'. She was right.", {"karma": 2}), O("It leaked. I wasn't happy.", {"karma": -3, "stress": 6})))
B("pyramid_scheme", "🔺", "A can't-lose opportunity", "An old schoolfriend turns up with a glossy brochure, a new car and a very white smile. 'Honestly, it's not a pyramid. It's a community.'", {"age": [18, 60], "min_money": 500},
  C("Join", O("I recruited three people, lost two friends, and made $40. I lost $1,200.", {"money": -1200, "karma": -3, "stress": 6}), O("I was out within a month, a little poorer and a lot wiser.", {"money": -400, "stress": 4})),
  C("Say no and ask questions", O("I looked it up. It was a pyramid. I warned others.", {"karma": 3, "smarts": 1}), O("They were offended. It got awkward.", {"stress": 2})),
  C("Just go to the meeting", O("Two hours of clapping, then a pitch. I left politely.", {"stress": 3}), O("I almost bought in. A friend dragged me out.", {"stress": 5, "karma": 1})))
B("loan_friend", "🤝", "Can you lend me...", "A friend has asked for a loan. 'Just until payday.' It's not a small amount. Their payday has a track record.", {"age": [18, 80], "min_money": 500},
  C("Lend it", O("They paid me back, a month late, with a bottle of wine. It was fine.", {"money": 0, "karma": 2}), O("They didn't. They vanished. A friendship, bought for $800.", {"money": -800, "karma": 0, "stress": 5})),
  C("Lend less", O("A smaller sum. They were thankful. No hard feelings.", {"money": -100, "karma": 1}), O("They were offended by the smaller sum.", {"money": -100, "stress": 3})),
  C("Say no", O("It was awkward. It would have been worse.", {"stress": 2}), O("They stopped talking to me. I decided I could live with that.", {"stress": 4})))
B("road_rage", "😡", "Cut up", "A van cuts you off at the roundabout and the driver gives you a gesture. Something in you quietly snaps.", {"age": [17, 80], "has_car": True},
  C("Follow him", O("I chased him half across town. He pulled over and got out. He was bigger than the van.", {"stress": 8, "karma": -3}, fine=150), O("I lost him. I sat in a lay-by shaking, ashamed of myself.", {"stress": 6, "karma": -2})),
  C("Breathe and let it go", O("I put on a song. It was a good one.", {"stress": -2, "karma": 1}), O("I pulled over for five minutes and called a friend.", {"stress": 0, "karma": 1})),
  C("Honk and shout", O("I felt great for ten seconds. Then a passenger in my car said 'wow.'", {"happiness": -1, "karma": -1}), O("It got me nothing. It cost me a little pride.", {"stress": 3})))
B("cheat_partner", "💔", "A message you shouldn't have sent", "It's a flirt, nothing more. The reply came quickly and was a lot more than flirting. Your thumb is on the next reply.", {"has_partner": True, "age": [18, 80]},
  C("Reply", O("It went further than I meant. It cost me a relationship.", {"karma": -8, "happiness": -6, "stress": 10}), O("It was exciting and sordid. My partner found out in a week.", {"karma": -8, "happiness": -8, "stress": 12})),
  C("Delete the chat", O("A close call. I felt ashamed, and kinder to my partner for a while.", {"karma": 1, "stress": 3}), O("I deleted it. I still thought about it.", {"stress": 4})),
  C("Tell your partner", O("It was the hardest conversation we ever had. We came out the other side.", {"karma": 4, "stress": 9, "happiness": -2}), O("They were hurt, and furious, and stayed.", {"karma": 3, "stress": 11, "happiness": -4})))
B("borrowed_car", "🔑", "Not your car", "Your friend's car keys are on the table. He's asleep upstairs. There is a late-night shop two miles away with a certain snack.", {"age": [16, 40]},
  C("Take it", O("Two miles, a snack, home. Nobody ever knew. I've never felt so guilty about chips.", {"karma": -3, "stress": 5}), O("I clipped a bollard. The car had a dent. He thought it had been like that.", {"karma": -5, "stress": 8})),
  C("Walk", O("A pleasant midnight walk. Worth it.", {"health": 1, "happiness": 1}), O("It was raining. I regretted it.", {"stress": 2})),
  C("Wake him", O("He grumbled, then came with me. A mini road trip.", {"happiness": 4}), O("He grumbled. I stayed hungry.", {"happiness": -1})))
B("sell_pass", "🎫", "Reselling", "You've got tickets to a sold-out concert and a reseller is offering four times face value. You're not sure the buyer is legitimate.", {"age": [16, 60]},
  C("Sell", O("A tidy profit and a fine evening. Nobody was hurt.", {"money": 300, "karma": -1}), O("It was a scam on their side: a fake payment. I lost both the tickets and the money.", {"money": -150, "stress": 6})),
  C("Go to the concert", O("It was one of the best nights of my life.", {"happiness": 9}), O("It was just okay. But I'd gone.", {"happiness": 3})),
  C("Sell at face value to a fan", O("She cried. It was worth more than the money.", {"karma": 4, "happiness": 4}), O("She was a friend of a friend. We went to the next one together.", {"karma": 3, "happiness": 3})))
B("hit_run", "💥", "Gone before they looked", "You've scraped a parked car, hard. The dent is big, the street is empty, and no one is looking.", {"age": [17, 85], "has_car": True},
  C("Leave a note", O("I wrote my number on the back of a receipt. The owner called, thanked me, and we sorted it for $300.", {"money": -300, "karma": 3}), O("The note blew away. The owner never called. My conscience was fine.", {"karma": 0})),
  C("Drive away", O("I waited for the knock. It didn't come. I still check the street.", {"karma": -6, "stress": 7}), O("A camera caught it. I got a letter. It was worse.", {"karma": -6, "fine": 700, "stress": 10})),
  C("Wait for the owner", O("He arrived in ten minutes. We exchanged details, shook hands, and I got a lecture on parallel parking.", {"karma": 2, "money": -300}), O("It took an hour. I read a whole magazine.", {"karma": 2, "money": -300, "stress": 2})))

# ------------------------------------------------------------------ GOOD DECISIONS
Gd("learn_skill", "🧠", "The evening class", "A flyer on the library board: ten Thursday nights, a new skill, cheap. You've ignored similar ones before.", {"age": [18, 80]},
  C("Sign up", O("I finished all ten. I'd found something I loved, and a new circle.", {"smarts": 3, "happiness": 5, "money": -80}), O("I missed some but got the gist. A decent investment.", {"smarts": 2, "happiness": 2, "money": -80})),
  C("Think about it", O("The sign-up closed. I did it next year.", {"smarts": 1}), O("The class filled. I felt the loss.", {"happiness": -1})),
  C("Watch videos instead", O("I learned it online, in my own time. Not as social, but fine.", {"smarts": 2}), O("I watched four videos and stopped.", {"smarts": 0})))
Gd("save_habit", "🐷", "Pay yourself first", "On payday you set up a standing order for 10% into a savings account. It stings for about a month and then it vanishes from your mind.", {"age": [18, 70], "min_money": 200, "employed": True},
  C("Set it up", O("A year later I had a cushion I'd never have saved by willpower. A rainy day came, and I was ready.", {"money": 600, "stress": -3, "smarts": 1}), O("I forgot about it. Two years later, a pleasant surprise.", {"money": 900, "happiness": 3})),
  C("Make it 20%", O("Tight at first, then a good habit. I felt grown-up.", {"money": 1100, "stress": -2}), O("It was too much. I scaled it back.", {"money": 300, "stress": 2})),
  C("Skip it", O("Next month. Always next month.", {"stress": 1}), O("My bank statement said so, loudly, in the end.", {"stress": 3, "money": -100})))
Gd("volunteer_day", "🧤", "A day of giving", "A local charity needs hands for a Saturday: sorting food, painting a community hall, whatever's needed. Nobody's paying.", {"age": [14, 90]},
  C("Go", O("I painted a wall and ate too much cake. The people were wonderful. I went back the next month.", {"karma": 5, "happiness": 5}), O("It was gloriously chaotic, and I met someone who became a good friend.", {"karma": 4, "happiness": 4})),
  C("Donate instead", O("A kind and practical gesture. They were grateful.", {"karma": 2, "money": -50}), O("A small cheque. A pleasant glow.", {"karma": 1, "money": -50})),
  C("Skip", O("A free Saturday, spent on the sofa. Fine.", {"happiness": 1}), O("I saw their post afterwards and wished I'd gone.", {"karma": -1})))
Gd("apologise", "🕊️", "A long overdue sorry", "There's a person you wronged years ago. You know exactly what you did. You have their address on a scrap of paper.", {"age": [20, 90]},
  C("Write to them", O("They wrote back. We never spoke of it, but we became friends again.", {"karma": 6, "happiness": 6}), O("They didn't write back. I felt lighter anyway.", {"karma": 5, "happiness": 3})),
  C("Visit", O("Their eyes filled. They hugged me, and that was that.", {"karma": 7, "happiness": 7}), O("They shut the door. I understood.", {"karma": 4, "stress": 5})),
  C("Let it lie", O("Some things are better left, I told myself.", {"karma": -1}), O("They died the following year. I didn't go to the funeral.", {"karma": -3, "stress": 5})))
Gd("run_morning", "🏃", "Five a.m. shoes", "You've left your trainers by the door for two weeks as a threat. This morning the sky is a clean pink, and the street is yours.", {"age": [14, 80]},
  C("Run", O("Twenty minutes of burning lungs and pure joy. I've done it every morning since.", {"health": 4, "happiness": 4, "stress": -4}), O("I managed one lap and a half. A start.", {"health": 2, "happiness": 2})),
  C("Walk instead", O("An unhurried hour with the birds. Gentle and good.", {"health": 2, "happiness": 3}), O("I stopped for coffee. I called it a walk.", {"happiness": 2, "money": -4})),
  C("Back to bed", O("I slept until eight. Warm, content, slightly guilty.", {"happiness": 1}), O("The trainers stay by the door. The threat continues.", {"happiness": 0})))
Gd("check_in", "☎️", "A call to an old friend", "You find a number you haven't dialled in eight years. You're nervous, and not sure why.", {"age": [18, 90]},
  C("Call", O("They answered on the second ring. We talked until the battery died.", {"happiness": 7, "karma": 2}), O("They'd changed their number. I found them on social media. It was a start.", {"happiness": 4})),
  C("Text", O("They replied in seconds. A lovely, simple reunion.", {"happiness": 5}), O("They replied a week later. It was lovely, but slower.", {"happiness": 3})),
  C("Leave it", O("Another year went by.", {"happiness": -1}), O("I found out they'd moved away. I wish I'd called.", {"happiness": -3})))
Gd("therapy_start", "🛋️", "Seeing someone", "A friend has recommended a therapist, with the words, 'It's just a conversation.' You've been carrying something heavy for a long time.", {"age": [16, 90]},
  C("Book it", O("The first session was awkward. The fifth changed something. I'm lighter now.", {"stress": -8, "happiness": 6, "money": -300}), O("It took a while to find the right person. When I did, it clicked.", {"stress": -5, "happiness": 4, "money": -400})),
  C("Think about it", O("The number sat in my phone for a year.", {"stress": 2}), O("I booked it on a bad night. It was a good night's work.", {"stress": -2, "money": -100})),
  C("Try a book instead", O("It helped a bit. Not enough.", {"stress": -1, "smarts": 1}), O("It helped a lot. I recommended it.", {"stress": -3, "smarts": 2})))
Gd("buy_book", "📚", "The bookshop", "You went in for a birthday card and came out with three books and a feeling. One is the sort of book that makes you reconsider everything.", {"age": [14, 90]},
  C("Read it all", O("It changed how I saw a few things. I lent it to everyone I knew.", {"smarts": 3, "happiness": 4}), O("It took a month. I'm a better person for it.", {"smarts": 2, "happiness": 2})),
  C("Read the first chapter", O("The first chapter was enough. I live differently.", {"smarts": 1, "happiness": 2}), O("I put it on the shelf. It's still there.", {"smarts": 0})),
  C("Give it away", O("I gave it to a friend who needed it. She sent a postcard.", {"karma": 3, "happiness": 3}), O("It went to a charity shop. Someone will find it.", {"karma": 2})))
Gd("mentor_ask", "🧭", "Asking for advice", "Someone you admire is three seats along from you at a conference, alone. You have eleven minutes before the next session.", {"age": [18, 70], "employed": True},
  C("Go and introduce yourself", O("She turned out to be warm and funny. She became a mentor.", {"job_perf": 5, "happiness": 5, "smarts": 1}), O("She was brisk but kind. She gave me one piece of advice that mattered.", {"job_perf": 3, "smarts": 1})),
  C("Wait for a better moment", O("There wasn't one. She left.", {"happiness": -2}), O("The moment arrived at the coffee station. It worked.", {"happiness": 3, "job_perf": 2})),
  C("Send an email later", O("She replied the next day. A year later, she was writing my reference.", {"job_perf": 4, "happiness": 3}), O("It went unanswered. I tried again, eventually.", {"stress": 2})))
Gd("kind_stranger", "💛", "A small kindness", "On a crowded train, a woman is struggling with a pushchair on the steps. Ten people are looking at their phones.", {"age": [10, 90]},
  C("Help", O("I carried it up. She thanked me with a smile. It made my day.", {"karma": 4, "happiness": 4}), O("We chatted. She turned out to live on my street.", {"karma": 3, "happiness": 4})),
  C("Hold the door", O("A tiny act. A tiny thank-you. A good morning.", {"karma": 2, "happiness": 2}), O("Someone else got there first. I held the door anyway.", {"karma": 1})),
  C("Carry on", O("I went on my way. I thought about it later.", {"karma": -1}), O("I saw her again and she didn't see me. I felt a small pang.", {"karma": -1})))
Gd("moving_day", "📦", "Moving in", "A new place: keys in your hand, boxes in the hall, a neighbour hovering with a plate of something wrapped in foil.", {"age": [18, 80]},
  C("Invite them in", O("We became firm friends. She looked after my plants for years.", {"happiness": 5, "karma": 2}), O("We ate the cake sitting on boxes. It was perfect.", {"happiness": 5})),
  C("Thank them and close the door", O("A polite start. We nod on the stairs.", {"happiness": 0}), O("I regretted it. They never knocked again.", {"happiness": -2})),
  C("Pass the cake round the movers", O("Everyone loved it. The foil came back full of biscuits.", {"karma": 2, "happiness": 3}), O("It was eaten in thirty seconds. The neighbour laughed.", {"happiness": 3})))
Gd("pay_debt", "💸", "Clearing a debt", "The final payment is due. It's the last of a loan that has hung over you for years. It's a lot of money to give away in one go.", {"age": [20, 80], "min_money": 1500},
  C("Pay it off now", O("The weight lifted so fast I laughed in the bank. I'd never felt so light.", {"money": -1500, "stress": -9, "happiness": 7}), O("It was a clean break. I slept for eleven hours.", {"money": -1500, "stress": -7, "happiness": 5})),
  C("Pay it down gradually", O("It took another year. The relief arrived in instalments.", {"stress": -3, "money": -600}), O("Interest ate some of the savings.", {"stress": -1, "money": -800})),
  C("Spend it on something fun", O("It was fun. It also cost me for years.", {"happiness": 3, "stress": 4}), O("I regretted it by the end of the month.", {"happiness": -2, "stress": 6})))
Gd("adopt_shelter", "🏠", "A face at the shelter", "You went to the shelter to donate a bag of blankets. A dog in the third kennel is looking at you with the stare of someone who has made up their mind.", {"age": [18, 80], "has_pet": False},
  C("Adopt", O("She came home that afternoon and has never left my side. Best decision I ever made.", {"happiness": 9, "karma": 3, "money": -120}, gain_pet="dog"), O("It took a month to settle her in. We worked it out.", {"happiness": 6, "stress": 4, "karma": 3, "money": -120}, gain_pet="dog")),
  C("Foster first", O("A few weeks became a permanent home. I didn't mind.", {"happiness": 7, "karma": 3}, gain_pet="dog"), O("I fostered, and she went to a lovely family. I cried in the car.", {"karma": 4, "happiness": 2})),
  C("Just donate and leave", O("The blankets went to a good home. The dog's stare followed me for days.", {"karma": 2, "happiness": -1}), O("I came back the next week. She was gone.", {"happiness": -3})))
Gd("forgive", "🕯️", "Letting go", "You've spent years holding onto a grudge. At a funeral, the person you've been angry at is sitting across the aisle, grey and smaller than you remembered.", {"age": [20, 90]},
  C("Speak to them", O("We sat on the steps afterwards. I said very little, and it was enough.", {"karma": 6, "happiness": 7, "stress": -5}), O("They wept. I held their hand, to my own surprise.", {"karma": 7, "happiness": 6})),
  C("Nod and leave", O("A small acknowledgement. It was all I could manage.", {"karma": 1}), O("I regretted it. They died the next winter.", {"karma": -2, "stress": 4})),
  C("Write them a letter", O("I never sent it. I felt lighter.", {"karma": 2, "stress": -3}), O("I sent it. They replied with three words.", {"karma": 4, "happiness": 4})))

# ------------------------------------------------------------------ UNEXPECTED TURNS
T("long_lost_relative", "📮", "A letter from a stranger", "An envelope with a foreign stamp: a woman writing to say she believes she is your half-sister, and attaches a photograph in which you can see your own chin.", {"age": [18, 90], "once": True},
  C("Write back", O("We began to write. Eventually we met. It changed both our lives.", {"happiness": 8, "karma": 2}), O("It turned out to be a mistake. But we stayed in touch.", {"happiness": 3})),
  C("Ask your parents", O("My father went quiet. Then he told me everything. A day I'll never forget.", {"happiness": -2, "stress": 8, "smarts": 1}), O("They denied it. I didn't believe them.", {"stress": 8, "happiness": -3})),
  C("Ignore it", O("It sat in a drawer for years.", {"stress": 3}), O("A second letter arrived. I couldn't ignore that one.", {"stress": 5})), once=True)
T("surprise_inheritance", "📜", "The solicitor's call", "A solicitor rings about 'a bequest'. The name is that of a great-aunt you met twice, and whom you remember only for her cats.", {"age": [20, 85], "once": True},
  C("Attend the reading", O("Her house, her cats and a surprisingly large sum. The cats were the best part.", {"money": 8000, "happiness": 6}, gain_pet="cat"), O("A small sum and a very odd painting. I sold the painting for a lot more.", {"money": 3000, "happiness": 3})),
  C("Decline it", O("I gave it away. My family thought I'd lost my mind.", {"karma": 5, "happiness": -1}), O("It all went to a charity. I felt both noble and daft.", {"karma": 4})),
  C("Send a representative", O("It all happened without me. A cheque arrived.", {"money": 2500, "happiness": 2}), O("A lawyer took a third. I didn't mind.", {"money": 1800})), once=True)
T("wrong_number", "📱", "A voice in the wrong place", "A text arrives from an unknown number: 'Are you still coming Saturday?' You reply 'wrong number'. The answer is, 'Hang on. Is this really {me.first}?'", {"age": [16, 85], "once": True},
  C("Reply", O("It turned out to be someone I'd lost touch with decades ago. We began again.", {"happiness": 8}), O("It turned out to be a scammer. I blocked them quickly.", {"stress": 2})),
  C("Ignore", O("The number didn't text again. I wondered.", {"stress": 1}), O("The number kept texting. I changed mine.", {"stress": 5})),
  C("Call them", O("A familiar laugh. A friend I'd thought lost.", {"happiness": 9}), O("A recorded voice. Nothing else.", {"stress": 3})), once=True)
T("found_money", "💵", "Something in the lining", "While repairing an old coat, your fingers find a folded paper in the lining. It's a stack of notes, old ones, withdrawn from circulation years ago.", {"age": [16, 90], "once": True},
  C("Take them to the bank", O("The bank exchanged them. A lovely surprise of $600.", {"money": 600, "happiness": 5}), O("The bank refused. They were worth more to a collector.", {"money": 900, "happiness": 4})),
  C("Frame one", O("It hangs in the hall. People ask.", {"happiness": 3}), O("It faded, but it's still my favourite thing.", {"happiness": 2})),
  C("Give them away", O("I gave them to a charity box. The cashier was amazed.", {"karma": 4}), O("I gave them to a friend, who wasn't amused.", {"karma": 1})), once=True)
T("job_poached", "📞", "The headhunter", "A recruiter you've never met knows your name, your salary and your university. 'There's a role. You'll want to hear about it. Lunch?'", {"employed": True, "age": [22, 60], "chance": 0.25},
  C("Take the lunch", O("A better job, a better title and a bigger salary. The lunch was good, too.", {"money": 600, "job_perf": 4, "happiness": 5}), O("The role was a mess. I stayed where I was, grateful for the fish.", {"happiness": 1})),
  C("Say you're happy", O("They said 'good to know' and went quiet. I got a promotion a year later.", {"job_perf": 3}), O("They left me alone. I wondered, sometimes.", {"stress": 1})),
  C("Tell your boss", O("My boss matched the rumour of an offer. A raise, and a slightly colder relationship.", {"money": 400, "stress": 3}), O("My boss was furious. It went downhill.", {"stress": 6, "job_perf": -4})))
T("street_performer", "🎻", "A busker's song", "In the underpass, a busker is playing a song you haven't heard in thirty years. It's the one your father used to hum.", {"age": [18, 90]},
  C("Stop and listen", O("I stood there and cried quietly. When it ended, I gave everything I had in my pocket.", {"happiness": 6, "money": -20, "karma": 2}), O("The busker saw me. 'Request?' she said. I asked for the same song again.", {"happiness": 7})),
  C("Walk on", O("I thought of it the whole way home.", {"happiness": 1}), O("I caught the last bar from the escalator.", {"happiness": 2})),
  C("Ask what it's called", O("An old folk song, with a story. We chatted until my train left.", {"happiness": 5, "smarts": 1}), O("She didn't know. It had been taught to her by an old man.", {"happiness": 4})))
T("viral_moment", "📹", "Four million views", "A clip of you, filmed without your knowledge, doing something faintly ridiculous at a bus stop, has been viewed four million times by lunchtime.", {"age": [14, 80], "once": True},
  C("Lean in", O("I made a joke of it. I got an invitation to a talk show, and a decent sponsorship.", {"fame": 4, "money": 400, "happiness": 4}), O("It faded in a week. I got a free pair of trainers.", {"fame": 1, "happiness": 2})),
  C("Hide", O("It went away, in the way they do. People still occasionally recognise me.", {"fame": 1, "stress": 5}), O("A tabloid camped outside for a day. I got a taxi out the back.", {"stress": 8})),
  C("Ask for it to be removed", O("They did. It reappeared elsewhere. The internet is a hydra.", {"stress": 4}), O("They did. It was gone. A rare win.", {"stress": 1})), once=True)
T("stranded_airport", "🛬", "Cancelled", "The board has flipped to red and the whole concourse sighs. The airline gives you a voucher and a thin smile. The next flight is in two days.", {"age": [16, 85]},
  C("Find a hotel", O("A sweet little hotel. I slept for twelve hours and woke up happy.", {"money": -80, "happiness": 3}), O("The only vacancy cost half a month's rent. I didn't care.", {"money": -250, "stress": 4})),
  C("Make friends at the gate", O("A stranger and I split a taxi, then dinner, then six years of friendship.", {"happiness": 6}), O("A group of us shared snacks and a very long game of cards.", {"happiness": 5})),
  C("Rent a car and drive", O("Ten hours, bad coffee, a beautiful sunrise.", {"money": -150, "happiness": 4, "stress": 3}), O("The car broke down. I abandoned it. A story.", {"money": -300, "stress": 8})))
T("lottery_win", "🎰", "Six numbers", "You never really checked the ticket. This time, in the newsagent, you do. The first number matches. The second. By the fifth your hands are shaking.", {"age": [18, 90], "once": True, "chance": 0.05},
  C("Claim it quietly", O("A modest prize, a tidy sum. I told two people.", {"money": 12000, "happiness": 8}), O("A real jackpot. I told nobody. It changed everything slowly.", {"money": 90000, "happiness": 10, "stress": 5})),
  C("Tell everyone", O("Cousins came out of the woodwork. I enjoyed it for a month, then I regretted it.", {"money": 30000, "happiness": 4, "stress": 9}), O("A newspaper made me famous. Parts of it I liked.", {"money": 30000, "fame": 3, "happiness": 4})),
  C("Pretend it didn't happen", O("I tore the ticket up. I'll never know why.", {"stress": 8, "happiness": -3}), O("A lawyer looked at me with pity. I claimed it.", {"money": 12000, "happiness": 4})), once=True)
T("new_neighbour_secret", "🏘️", "The house next door", "The new neighbours are lovely, but there are strange noises at night, a van with no markings, and a smell you can't place.", {"age": [20, 80]},
  C("Knock and be neighbourly", O("They were bakers, starting up at night. We got free bread forever.", {"happiness": 5, "karma": 1}), O("They were fine, mostly. They were awkward but kind.", {"happiness": 2})),
  C("Watch from the window", O("Nothing happened. I felt like a fool.", {"stress": 2}), O("I saw something I wished I hadn't. I phoned the police.", {"stress": 10, "karma": 1})),
  C("Mind your own business", O("It stayed a mystery. I made up several answers.", {"stress": 1}), O("It turned out to be a hobby brewery. I was invited to taste.", {"happiness": 3}, habit={"drinking": 2})))
T("sudden_move", "✉️", "Eviction notice", "A letter from the landlord: the building is being sold. You have sixty days. The envelope is thin and the news is heavy.", {"age": [18, 80], "housing": ["rent", "flat"]},
  C("Fight it", O("A tenants' meeting, a solicitor and a delay. We bought a little time.", {"stress": 8, "money": -200, "karma": 2}), O("We organised, we protested, we lost.", {"stress": 9, "karma": 2})),
  C("Find somewhere new", O("A better flat, nearer the water. A blessing in disguise.", {"happiness": 4, "money": -400}), O("A worse flat, further out. I made the best of it.", {"stress": 6, "money": -400})),
  C("Move in with someone", O("A friend had a spare room and a good heart.", {"happiness": 3, "money": 100}), O("It was crowded and cheap, and it lasted a year.", {"stress": 4})))
T("old_photo", "🖼️", "A photograph in a charity shop", "Browsing a charity shop, you find a photo in a cracked frame. The woman in it is your grandmother, young and laughing, standing next to someone you don't know.", {"age": [20, 90], "once": True},
  C("Buy it and investigate", O("The man was her first love. I learned a whole chapter of my family that nobody had told me.", {"smarts": 1, "happiness": 6}), O("It led nowhere. The photo still hangs by my stairs.", {"happiness": 3})),
  C("Buy it and ask your family", O("My mother wept. We spent the evening talking about her mother.", {"happiness": 5, "karma": 2}), O("Nobody remembered. It troubled me.", {"stress": 3})),
  C("Leave it", O("I went back the next day. It was gone.", {"happiness": -3}), O("I thought of the woman in the photo for weeks.", {"stress": 2})), once=True)
T("plane_seat", "💺", "Seat 14A", "A stranger beside you on a long flight starts a conversation, at first about nothing, and ends by saying, 'You look like someone who could use a different idea.'", {"age": [18, 80]},
  C("Listen", O("She told me about a small town and a life I'd never considered. I went home and began to make plans.", {"happiness": 5, "smarts": 1}), O("She was a bit of a bore. But she gave me her number.", {"happiness": 1})),
  C("Put in headphones", O("I watched a film. It was fine.", {"happiness": 1}), O("I regretted it somewhere over the sea.", {"happiness": -1})),
  C("Tell her your own story", O("We talked until landing. We exchanged addresses.", {"happiness": 6, "karma": 1}), O("I told her too much. She said, 'oh'.", {"stress": 3})))
T("stage_fright", "🎤", "Called to the stage", "At a friend's party, someone has pushed you toward a karaoke machine. Forty people are chanting your name. The song they've picked is hard.", {"age": [16, 70]},
  C("Sing it", O("I was terrible and brilliant. The room loved it. A viral clip was born.", {"happiness": 6, "fame": 1}), O("I forgot half the words. The room sang them for me.", {"happiness": 6})),
  C("Duck out", O("I hid in the bathroom. A friend slid a note under the door: 'Coward.' I laughed.", {"happiness": 0}), O("I escaped. I felt vaguely ashamed.", {"happiness": -2})),
  C("Drag a friend up", O("A duet for the ages. The crowd gave us a standing ovation.", {"happiness": 7}), O("My friend sang louder than me. Of course.", {"happiness": 4})))
T("storm_power_cut", "🕯️", "Candlelight", "The storm took the power at seven. By nine the whole street is dark except for a few windows, and your neighbours are standing in their doorways with torches.", {"age": [6, 90]},
  C("Knock on a neighbour's door", O("We cooked on a camping stove and told stories until midnight. Nobody wanted the lights to come back.", {"happiness": 7, "karma": 2}), O("An old lady needed help with the stairs. I stayed an hour.", {"karma": 4, "happiness": 4})),
  C("Stay in with a book", O("I read by candlelight. It was a lovely, rare quiet.", {"happiness": 4, "smarts": 1}), O("I fell asleep early and woke to the humming of the fridge.", {"happiness": 2})),
  C("Go to bed", O("I slept better than I had in months.", {"health": 2, "stress": -3}), O("I lay awake listening to the wind.", {"stress": 2})))
T("reunion_invite", "🏫", "Class reunion", "A glossy invitation: twenty years since you left school. The names on the guest list look like a stack of old photographs.", {"age": [35, 70], "once": True},
  C("Go", O("People had changed. I had too. It was the best evening I'd had in ages.", {"happiness": 7, "money": -60}), O("It was awkward at first. Then I met the one person I'd wanted to see.", {"happiness": 6, "money": -60})),
  C("Go for an hour", O("An hour was plenty. I left with two phone numbers.", {"happiness": 3}), O("The bully turned up. I left. I felt old.", {"stress": 4})),
  C("Skip it", O("I'd rather remember them as they were.", {"happiness": 0}), O("The photos looked like a lovely night. I envied it.", {"happiness": -3})), once=True)
T("accidental_witness", "👀", "You saw it", "On the way home, you glimpse something through a window that you weren't supposed to. An argument, a raised hand, a child's face. It lasts three seconds.", {"age": [18, 85]},
  C("Knock on the door", O("They said it was a misunderstanding. The child looked at me. I called someone anyway.", {"karma": 5, "stress": 8}), O("It was nothing, they said, and it probably was. I felt embarrassed.", {"stress": 4})),
  C("Call the police", O("They checked. It was resolved quietly. I never found out how.", {"karma": 4, "stress": 6}), O("They found nothing. I felt foolish and worried.", {"stress": 6})),
  C("Walk on", O("I thought about it for days.", {"karma": -3, "stress": 6}), O("I never saw that window again.", {"karma": -2, "stress": 4})))
T("career_pivot", "🔀", "The wrong ladder", "One Tuesday, in the middle of a perfectly good meeting, you realise you are on the wrong ladder entirely. It's not a crisis. It's a quiet clarity.", {"employed": True, "age": [28, 58]},
  C("Retrain", O("It was slow and humbling and joyful. In two years I was somewhere else.", {"smarts": 2, "happiness": 6, "money": -1500, "stress": 5}), O("I started a course, struggled and finished. A new life.", {"smarts": 2, "happiness": 4, "money": -1500})),
  C("Make small changes", O("I moved sideways within the firm. Better, if not perfect.", {"happiness": 3, "job_perf": 2}), O("Nothing changed. The feeling stayed.", {"happiness": -3, "stress": 3})),
  C("Ignore the feeling", O("It faded, as they do. It came back.", {"stress": 3}), O("It was a big mistake. I stayed ten more years.", {"stress": 6, "happiness": -5})))
save("life_b.json")

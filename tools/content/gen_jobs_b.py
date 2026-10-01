#!/usr/bin/env python3
"""Job events, part B: trades and services, public jobs, tech."""
from dsl import *
def J(job, n, icon, title, text, *choices, **kw):
    cond = {"job": job, "age": [16, 72]}
    cond.update(kw.pop("cond", {}))
    E(f"{job}_{n}", icon, title, text, cond, *choices, prefix="job.", **kw)

J("electrician", 1, "⚡", "The unmarked fuse box",
  "A client's fuse box has no labels at all, three decades of someone else's improvisation, and a smell like warm pennies.",
  C("Map every circuit before touching it", O("Two hours of patient tracing. I found a wire that would have killed the next person. I left a laminated map on the door.", {"job_perf": 6, "smarts": 1, "karma": 2}), O("It took until midnight, and the client grumbled about the hours. The map hung there for years.", {"job_perf": 3, "stress": 3})),
  C("Isolate at the mains and work fast", O("Safe, quick, tidy. The client was grateful and gave me a bottle of whisky.", {"job_perf": 4, "money": 30}), O("I missed one live neutral. The tingle in my arm told me everything.", {"health": -6, "stress": 8})),
  C("Tell the client it needs a full rewire", O("It did. They were upset, but they listened, and I got a good job out of it.", {"money": 200, "karma": 2, "job_perf": 4}), O("They called someone cheaper who patched it. I heard it burned out a year later.", {"stress": 4, "karma": 1})))
J("electrician", 2, "🔌", "The storm callout",
  "At 11 p.m. a lightning strike has taken out the street. A frantic woman tells you her elderly father is on an oxygen machine and the power's been out an hour.",
  C("Go straight there", O("It was a tripped main. Thirty seconds of work and a lot of relief. She hugged me on the doorstep.", {"karma": 5, "happiness": 4}), O("Half the street's lines were down. I rigged a generator for him and stayed until it was fixed.", {"karma": 6, "stress": 5, "health": -1})),
  C("Tell her to call the emergency service", O("They dispatched a crew. Quicker than I'd have been, in all honesty.", {"karma": 1}), O("They took three hours. She never rang me again.", {"karma": -2, "stress": 3})),
  C("Go, but charge the emergency rate", O("Fair, within the rate card. She paid without argument.", {"money": 250, "karma": 0}), O("She paid and then wrote a review about 'profiteering'. It stung.", {"money": 250, "karma": -2, "job_perf": -2})))
J("plumber", 1, "🔧", "The ceiling stain",
  "A woman rings in a panic: the ceiling below her bathroom is bulging, brown and glistening. 'It's not just water,' she says darkly.",
  C("Go straight up and find the leak", O("A cracked soil pipe. A grim hour and a fix that held. I could smell victory, and the other thing.", {"money": 180, "job_perf": 5, "stress": 2}), O("It was the pipe, and the wall behind, and the floor joist. A bigger job than anyone hoped.", {"money": 600, "stress": 5})),
  C("Cut the water first, then look", O("The right order of things. Nobody drowned.", {"job_perf": 5}), O("I cut the wrong stopcock. The neighbour called, upset about her shower.", {"stress": 4})),
  C("Give a quote over the phone", O("I was close enough. The customer thought I was a wizard.", {"money": 80, "job_perf": 3}), O("I was wildly off. The final invoice was twice the quote.", {"karma": -2, "stress": 4})))
J("plumber", 2, "🚽", "The wedding ring",
  "A tearful customer says she dropped her late mother's ring down the sink. 'If you can get it back...' She holds out an envelope.",
  C("Take the trap apart", O("It was in the U-bend, glinting. She cried and I pretended not to.", {"karma": 5, "happiness": 5, "money": 50}), O("It was in the main drain. Three hours of digging in the rain. We found it.", {"karma": 5, "stress": 4, "money": 120})),
  C("Quote a full call-out fee", O("She paid. It was fair, and she knew it.", {"money": 100}), O("She declined, and left it. I felt awful all week.", {"karma": -1, "stress": 3})),
  C("Say it's gone, to save the effort", O("She believed me. I knew I'd lied. It sat with me.", {"karma": -4, "stress": 3}), O("She asked another plumber, who found it in minutes. She told everyone.", {"karma": -3, "job_perf": -5})))
J("mechanic", 1, "🔩", "The knock that isn't",
  "A man insists his engine has a knock. You listen for twenty minutes and hear nothing. He is certain, and growing certain you are lying.",
  C("Take it on a road test", O("A loose heat shield, rattling at 40 mph only. I tightened a bolt. He paid me in disbelief.", {"job_perf": 5, "happiness": 2}), O("Nothing at all. I told him it was fine. He seemed disappointed.", {"stress": 1})),
  C("Quote for a new engine", O("He agreed. I did not feel good about that sale.", {"money": 1200, "karma": -6}), O("He went elsewhere. Good.", {"karma": 1})),
  C("Tell him honestly there's nothing wrong", O("He argued for ten minutes and then, sheepish, said thanks. A rare honest customer.", {"karma": 3, "job_perf": 3}), O("He left angry and told everyone I was useless.", {"karma": 1, "job_perf": -3})))
J("mechanic", 2, "🏎️", "A very fast customer",
  "A shiny sports car rolls in with a faint pull to the left and an owner with no patience. 'Fix it by five.' It is a quarter to.",
  C("Do it properly", O("I did it right. He was furious at the lateness and then delighted at the drive home.", {"job_perf": 5, "karma": 2}), O("He left a one-star review for the delay. The boss backed me.", {"job_perf": 3, "stress": 4})),
  C("Rush it", O("It was fine. He was thrilled. I breathed out.", {"job_perf": 2, "stress": 3}), O("A bolt came loose on the motorway. He was fine. He sued.", {"stress": 10, "job_perf": -6, "money": -300})),
  C("Tell him to come back tomorrow", O("He blustered and agreed. He was nicer when he came back.", {"job_perf": 3}), O("He took it to a rival garage. We lost him.", {"job_perf": -2})))
J("carpenter", 1, "🪚", "Measure twice",
  "You've cut the final beam for a client's loft staircase and it is a full two centimetres too short. The client arrives in an hour.",
  C("Admit it and recut", O("I told him. He sighed and said 'that happens'. It cost an extra day and a lot of respect.", {"karma": 3, "money": -60}), O("He laughed so hard he cried. We bonded over my mistake.", {"happiness": 3, "karma": 3})),
  C("Shim it and hope", O("It held. He never noticed. Neither did the building inspector.", {"stress": 3, "karma": -2}), O("It sagged within a year and I got a call.", {"stress": 6, "job_perf": -5, "karma": -3})),
  C("Redesign the stairs around it", O("A lovely quirk. The client said it had 'character' and paid extra.", {"job_perf": 6, "money": 80}), O("The result was odd, and the client was too polite to say so.", {"job_perf": 0, "stress": 3})))
J("carpenter", 2, "🏠", "Something in the wall",
  "Behind a bookshelf you're removing in a 1920s house you find a small door, a hollow, and a tin box wrapped in an old newspaper from the war.",
  C("Open it with the owner", O("Letters, a medal, and a photograph of a young man. The owner didn't speak for a while.", {"karma": 5, "happiness": 5}), O("A handful of coins and a note. The owner was delighted. We went for tea.", {"karma": 3, "happiness": 4})),
  C("Open it alone first", O("Old coins, mostly. I resealed it and told the owner. I felt cheap for looking.", {"karma": 0, "stress": 2}), O("I found something I wasn't meant to see. I left it where it was.", {"stress": 5, "karma": -1})),
  C("Leave it sealed and say nothing", O("I thought about it for years.", {"stress": 2, "karma": -2}), O("The next carpenter found it. He kept it.", {"stress": 3})))
J("hairstylist", 1, "✂️", "The bad cut",
  "You've taken a centimetre too much and the client, mid-chat, hasn't noticed yet. In ten seconds she will look at the mirror.",
  C("Warn her now", O("She laughed, then fixed her face and asked for a 'bold choice'. It was a hit.", {"happiness": 3, "job_perf": 3}), O("She cried, then forgave me. The salon gave her a free treatment.", {"stress": 4, "job_perf": -2})),
  C("Style it so it looks intended", O("A little product, a few clever cuts, and she left delighted.", {"job_perf": 5}), O("She noticed within a day and was cool about it. She never came back.", {"job_perf": -3})),
  C("Pretend it's the latest trend", O("She bought it. She told her friends. It became one.", {"job_perf": 4, "happiness": 3, "karma": -1}), O("Her friends laughed. She never forgave me.", {"job_perf": -5})))
J("hairstylist", 2, "💬", "The confession chair",
  "A regular, mid-wash, tells you she is leaving her husband tonight. 'I haven't told anyone yet. I just needed to say it somewhere safe.'",
  C("Just listen", O("I cut her hair slowly and said nothing. She hugged me on the way out.", {"karma": 4, "happiness": 3}), O("She cried softly into the towel. I kept the chair warm for her the next week.", {"karma": 4, "stress": 2})),
  C("Offer advice", O("I told her she deserved better. She took it as permission.", {"karma": 1, "stress": 3}), O("She told me to mind my business. I did.", {"stress": 2, "job_perf": -1})),
  C("Change the subject", O("It was awkward. She was gone in half an hour.", {"stress": 3}), O("I told her about my dog. She laughed through tears. It was the right thing.", {"happiness": 2, "karma": 2})))
J("line_cook", 1, "🔥", "Slammed on a Saturday",
  "The ticket printer won't stop. Twenty-one covers on the pass, the sous-chef out sick, and the head chef staring at you like a hawk.",
  C("Take the grill and the sauté together", O("I became a machine. The ticket rail went clear for the first time that night. The chef nodded once, and that was enough.", {"job_perf": 8, "stress": 6}), O("I burnt a steak and plated it anyway. A customer noticed.", {"job_perf": -2, "stress": 6})),
  C("Call it out and ask for help", O("The pastry chef jumped in. We got through it as a team.", {"job_perf": 4, "stress": 3}), O("The chef barked. I got the help, and a reputation as someone who panics.", {"job_perf": -2, "stress": 5})),
  C("Go slow and get it right", O("Dishes went out late, but perfect. Two covers walked, the rest raved.", {"job_perf": 2, "stress": 4}), O("The chef pulled me off the line. I washed pots.", {"job_perf": -5, "stress": 5})))
J("line_cook", 2, "🍳", "The staff meal",
  "At the end of a long night, the head chef shoves a pan at you: 'Make staff meal. Surprise me.' Everyone is watching.",
  C("Cook your grandmother's recipe", O("Everyone went silent, then asked for seconds. The chef asked for the recipe.", {"job_perf": 6, "happiness": 5}), O("It was good, in a way that made me homesick.", {"happiness": 2, "stress": 2})),
  C("Cook something fancy", O("The room cheered. The chef raised an eyebrow, then took a bite and sighed.", {"job_perf": 5}), O("It was overcooked. The chef said nothing, which was the worst.", {"job_perf": -3})),
  C("Make pasta", O("Pasta is never wrong. Everyone ate and fell asleep.", {"happiness": 2}), O("Pasta again. The chef rolled his eyes. It was fine.", {"job_perf": -1})))
J("firefighter", 1, "🚒", "The call at 4 a.m.",
  "The tones drop and your boots are on before you're awake. A warehouse fire, with a woman on the third floor, screaming from a window.",
  C("Go up the ladder", O("I got her down. She was singed but fine. They gave me a commendation I didn't know what to do with.", {"karma": 8, "job_perf": 8, "stress": 6}), O("I got her out, but the floor behind us caved. I'll never forget the sound.", {"karma": 6, "stress": 10, "health": -5}, scar="lungs")),
  C("Wait for the aerial platform", O("It arrived in ninety seconds and she was out. That was the textbook. I didn't feel good about the wait.", {"stress": 6, "job_perf": 3}), O("She didn't wait. She jumped. She survived, barely.", {"stress": 12, "karma": 1})),
  C("Search the stairwell first", O("Nobody was in it. Good thing. Every second counts.", {"stress": 5}), O("I found a second person. We got them both out.", {"karma": 8, "job_perf": 7, "stress": 8})))
J("firefighter", 2, "🐈", "Cat in the tree, again",
  "The dispatcher says, with real feeling, 'It's a cat. In a tree.' The whole station stares into their coffee.",
  C("Go and get it", O("I climbed twelve feet with a blanket and a bag of treats. A child cried with joy. The cat bit me.", {"happiness": 4, "karma": 3, "health": -1}), O("It came down on its own while I was reaching. The child gave me a drawing.", {"happiness": 5, "karma": 2})),
  C("Send the rookie", O("The rookie got scratched to ribbons. The crew laughed for a week.", {"happiness": 2, "karma": -1}), O("He got it, to a round of applause. His first rescue.", {"happiness": 3, "job_perf": 2})),
  C("Decline", O("I told them to call a cat rescue service. The dispatcher sighed.", {"job_perf": -1}), O("The cat was fine. It came down by tea time.", {"stress": 1})))
J("mail", 1, "📬", "The dog on route 14",
  "House number nine has a dog that has been eyeing you for three weeks. Today the gate is open.",
  C("Stand your ground", O("The dog sniffed my boots and went home. A truce.", {"stress": 3, "happiness": 2}), O("The dog bit my satchel and tugged it away. I fought for a minute and won.", {"health": -2, "stress": 5})),
  C("Offer a biscuit", O("A friend for life. He waited by the gate every morning after.", {"happiness": 5}), O("He took it and bit me anyway.", {"health": -3, "stress": 4})),
  C("Skip number nine", O("I delivered it the next day, apologetic, to a furious owner.", {"job_perf": -3, "stress": 3}), O("The owner never found out. I smiled all the way to number ten.", {"stress": -1})))
J("mail", 2, "💌", "A letter, thirty years late",
  "In a sorting-room crate you find a handwritten letter, postmarked three decades ago, never delivered, addressed to a woman at an address on your route.",
  C("Take it to her yourself", O("She opened it on the doorstep and read it in silence. She said it was from her brother. She hugged me for a minute.", {"karma": 8, "happiness": 6}), O("She'd moved. I tracked her down through three neighbours. It took a month. It was worth it.", {"karma": 6, "stress": 2})),
  C("Hand it to a supervisor", O("It went into a drawer, and I never found out what happened.", {"stress": 2, "karma": 0}), O("They sent it on officially. A form letter replaced the story.", {"karma": 1})),
  C("Keep it", O("I read it. I shouldn't have. I put it back in the post, years late.", {"karma": -2, "stress": 3}), O("I kept it in a drawer for a long time.", {"karma": -3, "stress": 4})))
J("flight_attendant", 1, "✈️", "Turbulence",
  "The seatbelt sign dings and the cabin begins to jump. A child is crying, a man is gripping his armrest, and you're standing in the aisle with a cart.",
  C("Strap in and talk to the child", O("I told a story about a plane that sneezes. She giggled. The turbulence ended. The mother cried.", {"karma": 4, "job_perf": 5}), O("It worked until the next bump. Then she was sick on my shoe.", {"stress": 3, "karma": 3})),
  C("Calm the cabin over the intercom", O("My voice was steadier than I felt. The cabin settled.", {"job_perf": 6, "stress": 4}), O("My voice cracked. Half the plane saw.", {"job_perf": 0, "stress": 5})),
  C("Hold on and pray", O("It ended in ninety seconds. I was fine.", {"stress": 5}), O("It lasted twenty minutes. I was not fine.", {"stress": 10, "health": -2})))
J("flight_attendant", 2, "🧳", "The passenger in 14C",
  "Mid-flight, a man in 14C is clearly unwell: pale, sweating, hand clutched to his chest. 'Is there a doctor on board?'",
  C("Run the emergency procedure", O("A doctor appeared. We worked together and he survived. I got a letter from the airline.", {"karma": 6, "job_perf": 8, "stress": 6}), O("The plane diverted. He lived. I cried in the galley.", {"karma": 5, "stress": 9})),
  C("Call the captain and make him comfortable", O("It was just indigestion, in the end. He was embarrassed.", {"stress": 4, "happiness": 2}), O("It was a heart attack. The crew's quick work saved him.", {"karma": 5, "job_perf": 6, "stress": 7})),
  C("Freeze", O("Another crew member took charge. I learned something about myself.", {"stress": 8, "job_perf": -3}), O("I blinked, and then I moved. The training had stuck.", {"job_perf": 3, "stress": 5})))
J("developer", 1, "💻", "Friday deploy",
  "It's 4:55 on a Friday and someone has pushed a change to production. The error rate graph has started to climb, slowly and then not slowly.",
  C("Roll it back", O("A one-line revert, and the graph came back down. The team clapped sarcastically. I loved them.", {"job_perf": 6, "stress": 4}), O("The rollback broke something else. I was online until 2 a.m.", {"stress": 9, "job_perf": 2})),
  C("Fix forward", O("A quick patch, a prayer, and it worked. I felt like a god.", {"job_perf": 7, "stress": 5}), O("The patch made things worse. I rolled back at midnight, humbled.", {"stress": 10, "job_perf": -2})),
  C("Pretend not to see it", O("Someone else fixed it. I went home and had a drink.", {"stress": -1, "job_perf": -3}), O("It was my change. They found out. I have never lived it down.", {"job_perf": -7, "stress": 7})))
J("developer", 2, "🐛", "The bug nobody can reproduce",
  "Users report a crash. The logs are empty, the tests pass, and you've spent three days trying to make it happen on your own machine.",
  C("Stay with it", O("Day four, 2 a.m.: a leap-year bug. I laughed out loud alone. Best feeling in the world.", {"smarts": 2, "job_perf": 6, "happiness": 4}), O("Day six: a timezone bug. I sent a thank-you to nobody.", {"smarts": 1, "job_perf": 4, "stress": 5})),
  C("Ask a colleague", O("She saw it in three minutes. I swallowed my pride.", {"smarts": 1, "job_perf": 3}), O("She said, 'oh, that.' She'd seen it before. We fixed it together.", {"job_perf": 4, "happiness": 2})),
  C("Mark it 'cannot reproduce'", O("It came back in a week, bigger. I looked foolish.", {"job_perf": -5, "stress": 5}), O("It never came back. Sometimes the universe is kind.", {"stress": -1})))
J("game_dev", 1, "🎮", "Crunch week",
  "The release date is in nine days and the build has eleven blockers. The producer has started saying 'we all believe in this team' a lot.",
  C("Stay late every night", O("We shipped on time. I slept for 14 hours and woke up to good reviews.", {"job_perf": 8, "health": -6, "stress": 8}), O("We shipped on time, and my relationship barely survived it.", {"job_perf": 6, "health": -5, "stress": 10, "happiness": -4})),
  C("Cut scope", O("We lost two features and kept our sanity. Reviews were kind.", {"job_perf": 3, "stress": 2}), O("We cut the wrong feature. Players noticed.", {"job_perf": -2, "stress": 4})),
  C("Push the date", O("The studio delayed, and the game was better for it.", {"job_perf": 4, "stress": 2}), O("The publisher pulled funding. It was an awful month.", {"job_perf": -4, "stress": 8})))
J("game_dev", 2, "🕹️", "The playtest",
  "A stranger sits down in the playtest room to try your level. Within ninety seconds they've done the one thing you were certain no one would.",
  C("Take notes and thank them", O("A flaw I'd never have seen. We fixed it, and the level got better.", {"smarts": 1, "job_perf": 5}), O("They loved it. They broke it. They loved that, too.", {"happiness": 4, "job_perf": 4})),
  C("Argue with the feedback", O("The tester was kind, I was not. I regretted it.", {"job_perf": -3, "stress": 4}), O("I was wrong. It was embarrassing.", {"job_perf": -2, "stress": 3})),
  C("Quietly fix the bug and move on", O("Nobody ever knew. I slept well.", {"job_perf": 2}), O("It broke again two weeks later. I fixed it again.", {"stress": 3})))
J("nurse", 1, "🩺", "The patient who won't take the pill",
  "An elderly man refuses his medication, calmly and entirely. 'I'm eighty-four. I'd like to choose.' The ward is busy and there are forty minutes of paperwork behind the pill.",
  C("Sit and ask why", O("He had been a sailor. Pills made him feel 'like a boat tied up forever'. We found a compromise.", {"karma": 5, "job_perf": 5}), O("He told me a lot about his wife and I lost track of time. A matron raised an eyebrow, then smiled.", {"karma": 4, "happiness": 3})),
  C("Escalate to the doctor", O("The doctor sat with him and agreed to adjust the regimen. A good outcome.", {"job_perf": 3}), O("The doctor sighed and ordered the pill anyway. I felt complicit.", {"stress": 5, "karma": -1})),
  C("Document and move on", O("It was within policy, and he was fine. I was fine.", {"stress": 1}), O("He deteriorated overnight. I replayed that conversation for weeks.", {"stress": 8, "karma": -2})))
J("nurse", 2, "🌙", "Night shift, short-staffed",
  "Two nurses off sick, twenty-six patients and one call bell that will not stop. At 3 a.m. you realise you haven't sat down since seven.",
  C("Push through", O("We held the ward. By morning I could barely speak, and I was proud.", {"job_perf": 6, "health": -4, "stress": 8}), O("I missed a dose. It was caught. I cried in the sluice room.", {"stress": 12, "job_perf": -3})),
  C("Call for backup", O("A float nurse arrived and we all breathed again.", {"job_perf": 3, "stress": 4}), O("None was available. I was told so quietly.", {"stress": 7})),
  C("Triage ruthlessly", O("I did the sick first and the grumpy last. Nobody died, and the grumpy forgave me.", {"smarts": 1, "job_perf": 5, "stress": 5}), O("A complaint came in about the grumpy. It was fair, and also not.", {"stress": 6})))
J("teacher", 1, "🍎", "The disruptive back row",
  "Two students in the back are whispering through your entire lesson. You've asked twice. You can feel the whole class waiting.",
  C("Stop and wait in silence", O("It took forty seconds. The room went still. The two blushed and stopped. It's an old trick, and it works.", {"job_perf": 4, "stress": 2}), O("They kept talking. The class started giggling. I lost the room.", {"stress": 6, "job_perf": -3})),
  C("Move them apart", O("Quiet efficiency. The lesson resumed.", {"job_perf": 3}), O("One of them turned out to be explaining the work to the other. I felt rotten.", {"karma": -1, "stress": 3})),
  C("Ask them to share with the class", O("They'd been discussing the topic. Better than my lesson. We spent the hour on it.", {"job_perf": 6, "happiness": 4}), O("They'd been discussing a video game. The class loved it. I did not.", {"happiness": 1, "stress": 3})))
J("teacher", 2, "📝", "The marking pile",
  "It is Sunday night and there are sixty essays in a bag by the door. One of them has a note on the first page: 'I know it's bad, please be kind.'",
  C("Read that one first", O("It was brave and flawed. I wrote a long comment. She came to see me, and I think it changed something.", {"karma": 4, "happiness": 3}), O("It was exactly as she said. I was kind. She cried in the corridor, in a good way.", {"karma": 3})),
  C("Mark it all in one go", O("I stayed up until two. Efficient and exhausted, I fell asleep in a staff meeting.", {"job_perf": 4, "stress": 6, "health": -2}), O("Quality dropped around essay forty. I knew it.", {"stress": 5, "job_perf": 0})),
  C("Give them all the same mark", O("Nobody noticed. I never felt right about it.", {"karma": -3, "stress": -2}), O("A parent noticed. I got called in.", {"karma": -3, "job_perf": -4, "stress": 6})))
J("police", 1, "🚔", "A routine stop",
  "You pull over a car for a broken tail light. The driver is shaking, polite, and keeps glancing at the passenger seat, where a bag sits very still.",
  C("Ask about the bag", O("A birthday cake, from a shop that had closed. A tearful, comic scene. I let him go.", {"happiness": 3, "karma": 2}), O("Something that shouldn't have been there. An arrest, a long night, and a good result.", {"job_perf": 6, "stress": 6})),
  C("Write the ticket and move on", O("Quick, uneventful, and by the book.", {"job_perf": 1}), O("I found out later what was in the bag. I couldn't forgive myself.", {"stress": 8, "job_perf": -4})),
  C("Call for backup", O("It was a long wait for nothing, but that's the job.", {"stress": 3}), O("Backup arrived just as the driver bolted. We got him.", {"job_perf": 6, "stress": 6})))
J("police", 2, "🔦", "The lost child",
  "A four-year-old is found alone at midnight, in pyjamas, outside a closed shop, holding a toy rabbit and giving a very firm name for his mother.",
  C("Sit with him until his mum is found", O("Three hours later a woman came sprinting down the road. She had fallen asleep on the sofa and he'd wandered. She sobbed. I gave her the rabbit.", {"karma": 6, "happiness": 5}), O("It was a long night, and an even longer talk with social services. But he was safe.", {"karma": 4, "stress": 4})),
  C("Take him straight to the station", O("A warm blanket, a biscuit, and a very good night's work.", {"karma": 3}), O("He fell asleep in the car and I drove with the window cracked open to keep myself awake.", {"karma": 2, "stress": 2})),
  C("Radio it and wait", O("Dispatch found his family in ten minutes. I spent the rest of the shift thinking about it.", {"karma": 2, "stress": 2}), O("Nothing for an hour. The longest hour.", {"stress": 6})))
save("jobs_b.json")

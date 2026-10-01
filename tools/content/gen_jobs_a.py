#!/usr/bin/env python3
"""Job events, part A: part-time and service jobs. Two per job, each tied to that job's id."""
from dsl import *
def J(job, n, icon, title, text, *choices, **kw):
    cond = {"job": job, "age": [14, 72]}
    cond.update(kw.pop("cond", {}))
    E(f"{job}_{n}", icon, title, text, cond, *choices, prefix="job.", **kw)

# ---- part-time cashier
J("pt_cashier", 1, "🧾", "The till is out",
  "At close, the drawer is forty dollars short. The manager is counting it a second time with a face like a locked door, and you were the last one on it.",
  C("Count it with them, out loud", O("We found a pair of stuck notes under the tray. Forty dollars, and a lot of unearned suspicion lifted.", {"stress": -2, "job_perf": 3}), O("The count stayed short. They wrote it up as an error and nobody said my name, which is its own kind of looking.", {"stress": 5, "job_perf": -1})),
  C("Offer to cover it", O("I put two twenties in. It was a stupid, noble thing. They gave it back the next week.", {"money": -40, "karma": 2, "job_perf": 2}), O("I paid it. They never gave it back, and I never forgot.", {"money": -40, "stress": 3})),
  C("Say nothing and go home", O("It sorted itself out by morning. It had never been mine to fix.", {"stress": 2}), O("They remembered I'd said nothing. It was held against me, quietly, at the next rota.", {"stress": 4, "job_perf": -3})))
J("pt_cashier", 2, "🛒", "A customer with a coupon",
  "A man holds up the line over a coupon that expired yesterday. The queue behind him is getting loud. He is not wrong, exactly. He is just very loud.",
  C("Honour it, quietly", O("He left with an expression of astonished gratitude. The queue forgave me instantly.", {"happiness": 2, "job_perf": 2}), O("Next day the manager docked it from the till. 'Policy.' I should have known.", {"money": -12, "stress": 3})),
  C("Hold the line, politely", O("He stormed out. A woman behind him said 'thank you' with her eyes.", {"stress": 4, "job_perf": 3}), O("He asked for a manager. The manager sided with him. I stood there and learned how it works.", {"stress": 6, "job_perf": -2})),
  C("Call the supervisor and step back", O("It was resolved in thirty seconds by somebody paid more to deal with it. A lesson in itself.", {"stress": 1, "smarts": 1}), O("The supervisor took forty minutes. The queue was a fire.", {"stress": 6})))
# ---- burger
J("pt_burger", 1, "🍔", "Grease fire",
  "The fryer flares up with a roar and a wall of orange. Everyone freezes for one stupid second. You are the closest person to the red extinguisher.",
  C("Grab the extinguisher", O("Foam everywhere, and out in four seconds. The manager called me 'a natural' and meant it.", {"job_perf": 6, "happiness": 4}), O("I got it out and burned the back of my hand. A scar the shape of a small country.", {"health": -5, "job_perf": 5}, scar="burns")),
  C("Hit the kill switch and shout", O("Everyone got out in time. Nobody was hurt. I got a free lunch for a month.", {"job_perf": 4, "happiness": 3}), O("The flare caught the hood vent. The kitchen closed for a day.", {"stress": 6, "job_perf": -1})),
  C("Run", O("It was a small fire and everyone saw me leave. The nickname lasted a year.", {"happiness": -3, "job_perf": -5}), O("Somebody else put it out. They did not say a word to me for a week, which was worse than saying it.", {"stress": 5, "job_perf": -4})))
J("pt_burger", 2, "🍟", "Mystery shopper",
  "A woman orders a plain burger and spends eleven minutes writing in a small notebook. The manager has gone pale. 'That's corporate,' he whispers, to nobody.",
  C("Go above and beyond", O("I topped up her drink, wiped her table, and learned her name. The report said 'exceptional'. It came with a voucher.", {"job_perf": 7, "money": 20}), O("I was so bright and eager I forgot a customer's order. The notebook caught it.", {"job_perf": -2, "stress": 3})),
  C("Act normally", O("I made her burger like I make everyone's. It scored well enough, and the manager hugged me, which was bad.", {"job_perf": 3}), O("It was a middling score and a long conversation about 'consistency'.", {"stress": 2, "job_perf": 0})),
  C("Spot her and tell the whole shift", O("The place had never been so clean. We all got a pizza afterwards and nobody mentioned how.", {"happiness": 3, "job_perf": 3}), O("The manager made us stand in a row and be silent. It was the weirdest shift of my life.", {"stress": 4, "job_perf": -1})))
# ---- lifeguard
J("pt_lifeguard", 1, "🛟", "A kid goes under",
  "From the chair it is simply a pair of flailing arms between a thousand others, and then it is not. You are already moving before you decide to move.",
  C("Dive in", O("I had her up and on the deck in twenty seconds. She coughed, cried, and then asked for ice cream. Her mother hugged me for a long time.", {"happiness": 8, "karma": 6, "job_perf": 8}), O("I got her out, but the water had her and she needed an ambulance. She was fine. I was not, for a week.", {"stress": 10, "karma": 5, "job_perf": 6})),
  C("Blow the whistle and use the pole", O("The pole reached. It was the right call and the training manual's exact words. She was fine.", {"karma": 3, "job_perf": 5}), O("The pole was just short. A father got there first. I couldn't look at him after.", {"stress": 8, "job_perf": 1})),
  C("Yell for the other guard", O("It took an extra five seconds that felt like an hour. She was fine. I replayed those seconds every night.", {"stress": 9, "job_perf": -3}), O("Someone else was already in the water. I never learned if they were faster than I'd have been.", {"stress": 6})))
J("pt_lifeguard", 2, "☀️", "Heat and a bad shift",
  "Thirty-eight degrees and a full pool. Your whistle hand has gone numb and your vision has started to swim at the edges.",
  C("Ask for a swap", O("They swapped me and I sat in the shade with a bottle of water for ten minutes. A small mercy.", {"health": 1, "job_perf": 2}), O("They told me to 'tough it out'. I did, and I'd resent them for it later.", {"health": -3, "stress": 5})),
  C("Push through", O("I stayed on the chair until close. I could barely walk to the bus.", {"health": -4, "job_perf": 4, "stress": 4}), O("I nearly fainted, and a kid saw it. The manager sent me home early, apologetic.", {"health": -5, "job_perf": -2})),
  C("Pour water over my head and keep going", O("It worked for about twenty minutes. I felt like a legend.", {"happiness": 3}), O("It worked for about twenty minutes.", {"health": -2})))
# ---- babysitter
J("pt_babysitter", 1, "🍼", "The wrong kind of quiet",
  "The kids went to bed an hour ago and it has been far too silent for far too long. You stand at the bottom of the stairs, listening.",
  C("Go and look", O("Both asleep, one still gripping a torch. Heartbreakingly sweet.", {"happiness": 3}), O("The five-year-old was awake and had drawn all over the landing wall. In crayon, not pen, thank God.", {"stress": 4, "job_perf": -1})),
  C("Call the parents", O("They laughed and said 'that means they're asleep'. Mildly insulting.", {"stress": 1}), O("They came home early and weren't happy. I didn't get a tip.", {"stress": 4, "money": -10})),
  C("Leave it and watch TV", O("It was fine. I got to watch my show in peace. A good night's work.", {"happiness": 3, "money": 30}), O("It was not fine. I woke to a child standing next to me, saying one word: 'hungry'.", {"stress": 5})))
J("pt_babysitter", 2, "🎒", "A fever at nine pm",
  "The little one is hot to the touch, flushed, and crying in a way that is not tantrum-crying. Their mother's phone goes straight to voicemail.",
  C("Call the emergency line", O("They talked me through it. A fever, and a good, slow calm. When the parents came home I was practically a hero.", {"karma": 3, "job_perf": 5, "stress": 3}), O("The ambulance came for a childhood fever and a parent was annoyed. I was told I'd done the right thing anyway.", {"stress": 5, "karma": 2})),
  C("Cool them down and keep trying the parents", O("I did what I'd read. It broke by midnight. The mother cried when she hugged me.", {"karma": 3, "money": 40, "stress": 4}), O("It held. They came home to a quiet house, and I never found out how close it had been.", {"stress": 5})),
  C("Panic", O("I called my own mother and we sorted it out over the phone. Not my best moment. Not my worst.", {"stress": 6}), O("I cried too. It's a feeling I understand differently now.", {"stress": 8, "happiness": -3})))
# ---- dog walker
J("pt_dogwalker", 1, "🐕", "Six leads, one squirrel",
  "You have six dogs on six leads, and every one of them has just seen the same squirrel. The leads wrap you like a maypole.",
  C("Plant my feet", O("I held. I was dragged six metres but I held. The dogs looked at me with new respect.", {"health": -1, "job_perf": 4}), O("I held and fell. A very kind woman helped me up and I never knew her name.", {"health": -2, "stress": 3})),
  C("Let one go, keep five", O("The loose one came back in a minute, delighted. I got the lecture from its owner anyway.", {"stress": 4, "job_perf": -1}), O("It did not come back for four terrifying hours.", {"stress": 10, "job_perf": -4})),
  C("Drop them all", O("They ran in a happy bundle straight into the tennis club. Chaos, and a story I'll tell forever.", {"happiness": 3, "job_perf": -3}), O("The park keeper had to catch them with a coat. He was furious.", {"stress": 5, "job_perf": -4})))
J("pt_dogwalker", 2, "🐾", "The dog who knows",
  "One of your regulars, an elderly spaniel, always pulls to the same bench. Today you let it, and an old man sitting there says, 'She was his.'",
  C("Sit with him", O("He told me about the dog's owner, his wife, and the walks they used to take. I came away very quiet and very glad.", {"happiness": 5, "karma": 3}), O("He started to cry gently. We sat there a long time.", {"happiness": 2, "karma": 3, "stress": 2})),
  C("Nod and keep walking", O("I felt that I'd missed something. I took a different route next time and sat on that bench myself.", {"happiness": 1}), O("The next week he wasn't there.", {"happiness": -2})),
  C("Ask the owner about it", O("The owner's voice changed. It turned out to be a bigger story than I'd guessed, and a lovely one.", {"karma": 2, "happiness": 3}), O("The owner told me to mind my own business. It was fair.", {"stress": 2})))
# ---- tutor
J("pt_tutor", 1, "📖", "The student who stares",
  "Your student has been looking at the same maths problem for twelve minutes without writing a thing. His mother is pacing in the next room, pretending not to listen.",
  C("Ask what he's afraid of", O("He admitted he didn't understand any of it, and hadn't for months. We started again from the beginning. It was the best hour of the year.", {"smarts": 2, "happiness": 4, "job_perf": 5}), O("He went quiet, then shrugged. Something loosened a bit.", {"stress": 2, "job_perf": 2})),
  C("Show the solution and move on", O("He copied it down. He passed the test, and learned nothing.", {"job_perf": -1, "karma": -1}), O("His mother saw the page and was delighted. She doubled my pay. I felt like a fraud.", {"money": 30, "karma": -2})),
  C("Make it a game", O("We turned it into a points race. He beat me, fairly. Next week he asked for harder ones.", {"happiness": 5, "job_perf": 6}), O("It worked for ten minutes and then he got bored. But he laughed, which was new.", {"happiness": 2, "job_perf": 2})))
J("pt_tutor", 2, "✏️", "Exam night",
  "It's the night before her exam and her mother has called you in a panic. 'Can you come tonight? I'll pay double.'",
  C("Go and stay late", O("We went through every past paper at the kitchen table. She got a B+. Her mum wept with joy.", {"money": 60, "karma": 2, "stress": 3}), O("She sat the exam exhausted. I wasn't sure it had been a good idea.", {"money": 60, "stress": 5})),
  C("Say no, kindly, and send a one-page summary", O("It was the better idea. She slept, and passed.", {"smarts": 1, "karma": 1}), O("Her mum was cross, but the summary helped.", {"stress": 2})),
  C("Turn up and chat, not teach", O("I told her she already knew it all. She believed me. She was right.", {"happiness": 3, "karma": 2}), O("She was calmer. It didn't help the exam, but it helped her.", {"happiness": 2})))
# ---- barista
J("pt_barista", 1, "☕", "The ten-person order",
  "A man walks in, tablet in hand, and reads out a ten-drink order with modifiers. Behind him, a queue to the door.",
  C("Work through it, calmly", O("I got every one right. He actually clapped.", {"job_perf": 6, "happiness": 3}), O("I got nine right and one wrong. He tipped anyway.", {"job_perf": 2, "money": 8})),
  C("Ask a coworker to share the load", O("We were a machine. The queue melted. It was weirdly beautiful.", {"job_perf": 4, "happiness": 4}, ), O("My coworker sighed theatrically. We got it done.", {"stress": 3})),
  C("Let the order go wrong", O("Two drinks came out cold and one with the wrong milk. He complained. The manager sided with him.", {"job_perf": -5, "stress": 5}), O("He was nice about it. I wasn't.", {"stress": 3, "job_perf": -2})))
J("pt_barista", 2, "🥛", "The regular who never smiles",
  "A man in a grey coat comes in at 7:12 every morning and orders a flat white without a word. Today he says, 'You remember my order. Thank you.'",
  C("Ask how he's doing", O("He's a widower, it turned out. He had never been asked. I learned his name, and every morning thereafter I had it ready.", {"karma": 4, "happiness": 4}), O("He said 'fine' and looked at the floor. He didn't come in for a week, then did.", {"karma": 1})),
  C("Smile and carry on", O("He nodded and left. It was a tiny thing and I never knew if it mattered.", {"happiness": 1}), O("The next day he asked for a different coffee and I got it wrong. We both laughed.", {"happiness": 2})),
  C("Write his name on the cup", O("He looked at the cup for a long moment. He kept it.", {"happiness": 5, "karma": 3}), O("He frowned, then smiled, then took a different seat. I think it was shyness.", {"happiness": 2})))
# ---- stocker
J("pt_stocker", 1, "📦", "The pallet jack",
  "The pallet jack's brake has been sticky all week. On aisle nine, loaded with tinned tomatoes, it begins to roll.",
  C("Throw yourself in front of it", O("It stopped against my knees. I limped for a week and was a hero for a day.", {"health": -4, "job_perf": 4}), O("My shin was bruised blue and I was told off for not following protocol. The irony stayed with me.", {"health": -5, "stress": 4})),
  C("Step aside and shout", O("It crashed into the end shelf and sixty tins went rolling. No one was hurt.", {"job_perf": -2, "stress": 3}), O("It hit a display of cereal. We were laughing by closing time.", {"happiness": 2, "stress": 2})),
  C("Grab the handle and yank the brake", O("It bit, just in time. I felt like a stunt person.", {"job_perf": 5, "happiness": 3}), O("The brake snapped off. I held the handle like an idiot while it rolled.", {"stress": 4, "job_perf": -1})))
J("pt_stocker", 2, "🌙", "Nightshift, 3 a.m.",
  "The store is silent except for the buzz of a light that has been flickering for an hour. Something in the back freezer has begun to knock.",
  C("Open the freezer", O("It was a loose crate, knocking in a draught. I laughed out loud, alone, at 3 a.m. Good.", {"stress": -2, "happiness": 2}), O("It was a fox, which had been sleeping in the loading bay. We eyed each other. It left.", {"happiness": 3, "stress": 3})),
  C("Check the cameras", O("Nothing on the footage. I never solved it.", {"stress": 4}), O("The footage showed a trolley, rolling by itself on a slope. Case closed.", {"stress": -1})),
  C("Ignore it and keep stacking", O("The knocking stopped. I decided that was the right call.", {"stress": 2, "job_perf": 3}), O("It went on for the rest of the shift. I was relieved when the day crew arrived.", {"stress": 5})))
# ---- delivery
J("pt_delivery", 1, "🛵", "The wrong address",
  "The app says to drop the order at number 14. Number 14 is a boarded-up house with a dog behind the fence, and the customer is texting: 'Where ARE you?'",
  C("Call them", O("It was 41, not 14, the app had swapped the digits. A big tip for the trouble.", {"money": 12, "job_perf": 3}), O("They didn't answer. I cancelled and ate their curry myself in the car.", {"happiness": 2, "job_perf": -3})),
  C("Knock anyway", O("The dog and I came to an understanding. The neighbour took the food. I never knew if she was the customer.", {"stress": 4}), O("The dog did not come to an understanding.", {"health": -3, "stress": 5})),
  C("Leave it by the door", O("They reported it as missing. The platform sided with them.", {"job_perf": -4, "money": -9}), O("The neighbour's cat ate the starter. It was all anyone talked about.", {"happiness": 2, "job_perf": -2})))
J("pt_delivery", 2, "🌧️", "Pouring rain, two orders",
  "It is the heaviest rain of the year, and the orders are stacking up. One more run, and your hands are shaking from the cold.",
  C("Take both", O("I got soaked, but the tips were generous. It paid for the week.", {"money": 45, "health": -3}), O("I skidded at a roundabout and lost a whole order into a gutter.", {"health": -5, "money": -20, "stress": 6})),
  C("Take one, wait out the worst", O("I sat in a bus shelter and watched the rain, quietly satisfied.", {"stress": -2, "money": 18}), O("The second order was given to someone else and I lost the tip.", {"money": 8, "stress": 3})),
  C("Go home", O("Dry, warm, and a little ashamed. It was the right call.", {"health": 2, "money": -15}), O("The platform noted my low acceptance rate. It cost me.", {"stress": 4, "job_perf": -4})))
# ---- retail
J("retail", 1, "🛍️", "The returns desk",
  "A woman puts a sofa cushion on your counter. It has clearly been used, and the box it came in has clearly never been near it. 'I want a refund,' she says, with her whole chest.",
  C("Refuse, politely", O("She called me names and then called the manager. The manager took my side, which is rare and I valued it.", {"stress": 5, "job_perf": 4}), O("She returned with a camera crew. It turned out to be her nephew. We all moved on.", {"stress": 4, "happiness": 2})),
  C("Give in", O("She got her money and left, smiling. I was told off for it later.", {"money": 0, "job_perf": -4, "stress": 3}), O("She came back the next week with a different cushion. I stood my ground that time.", {"stress": 3, "job_perf": 1})),
  C("Get the manager", O("He did the little speech. She did the little speech. They bowed to each other like wrestlers. I learned a lot.", {"stress": 2, "smarts": 1}), O("The manager gave her store credit. She left happier than anyone should be.", {"stress": 3})))
J("retail", 2, "🎄", "The last week before the holiday",
  "The shop floor looks like a battlefield. A man is fighting a woman for the last light-up reindeer. You are the only staff member with a free pair of hands.",
  C("Step in", O("I split them with a clipboard and a firm voice. The reindeer went to the first person who touched it.", {"job_perf": 4, "stress": 5}), O("It turned into a shouting match and security came. The reindeer ended up in pieces.", {"stress": 8, "job_perf": -1})),
  C("Offer to find another one", O("In the stockroom there was one, in a battered box. Both customers took it as a gift.", {"job_perf": 6, "happiness": 3}), O("There wasn't one. I made something up about 'a new shipment'.", {"stress": 3})),
  C("Let them fight", O("It ended in a draw. They left in opposite directions with nothing, and I felt weirdly satisfied.", {"happiness": 2}), O("Somebody filmed it. The video did the rounds. The store was mentioned in the comments.", {"stress": 4, "job_perf": -3})))
# ---- fast food
J("fastfood", 1, "🍗", "Rush hour",
  "The whole queue arrives at once, and the screens turn red. Six drive-through orders, four counter orders, and the fryer timer is going off.",
  C("Take the counter", O("I flew through it. By the end I felt like I'd run a marathon, and I'd loved it.", {"job_perf": 6, "happiness": 4}), O("I flew through it and burned a finger on a tray. Worth it.", {"job_perf": 5, "health": -2})),
  C("Help the kitchen", O("Between us we cleared the screens in record time. A manager nodded at me.", {"job_perf": 5, "stress": 3}), O("I got in someone's way and knocked a tray of fries. We laughed.", {"stress": 3})),
  C("Hide in the stockroom for a minute", O("I counted to sixty and came back calmer, ready.", {"stress": -3, "job_perf": 1}), O("I was caught. The shift manager's eyebrow said it all.", {"job_perf": -4, "stress": 4})))
J("fastfood", 2, "🥤", "The milkshake machine",
  "The milkshake machine has been broken for three weeks and a regular has just ordered one for the fourth time. 'It's my birthday,' she says.",
  C("Make it by hand", O("It took twenty minutes, a lot of ice cream and a tiny sparkler from the drawer. She cried.", {"karma": 4, "happiness": 5}), O("It came out lumpy and she ate it anyway, with great ceremony.", {"karma": 2, "happiness": 3})),
  C("Tell the truth", O("She understood. We gave her a free sundae instead.", {"karma": 1, "money": -3}), O("She left unhappy. The sundae was cold comfort.", {"stress": 2})),
  C("Fake it with a cup of soft-serve", O("She noticed. She smiled and ate it, because she's kind.", {"karma": -1, "stress": 2}), O("She noticed. She wrote a review.", {"job_perf": -3, "stress": 4})))
# ---- warehouse
J("warehouse", 1, "🏭", "The speed target",
  "The board says the line is twelve percent behind. Someone has turned up the scanner pace overnight, and nobody has said so.",
  C("Work faster", O("I hit the number. My lower back reminded me the next day.", {"job_perf": 5, "health": -3}), O("I hit the number and dropped a box of glassware. It came out of my wages.", {"money": -30, "stress": 5})),
  C("Raise it at the team meeting", O("Three others agreed. Management reluctantly eased the target. It felt a bit like winning.", {"job_perf": 2, "happiness": 4}, ), O("I was labelled 'difficult'. My shifts got worse.", {"stress": 6, "job_perf": -4})),
  C("Pace myself", O("I did a safe, steady pace and nobody fired me. A small victory.", {"health": 1, "stress": -1}), O("I was written up for being slow.", {"stress": 5, "job_perf": -5})))
J("warehouse", 2, "🚜", "The forklift near-miss",
  "A forklift reverses out of the aisle with no horn and no beeper. You are in its path, looking at your scanner.",
  C("Dive sideways", O("It missed me by a hand's breadth. Everyone in the building was very quiet afterwards.", {"stress": 6, "health": -1}), O("It clipped my heel. A bruise and a story.", {"health": -4, "stress": 5})),
  C("Shout", O("The driver stopped. Nothing happened. The safety lead cried a bit.", {"stress": 4, "job_perf": 2}), O("He didn't hear. A colleague shoved me out of the way.", {"stress": 5, "karma": 1})),
  C("Report the beeper after", O("They fixed it the same day. A rare win.", {"job_perf": 4, "stress": -1}), O("They said they would. They did not. I told the union.", {"stress": 3, "job_perf": 1})))
# ---- trucker
J("trucker", 1, "🚛", "Black ice at 4 a.m.",
  "The road ahead is a perfect silver ribbon. The dashboard says minus three. The rig feels light, and then it feels very light.",
  C("Ease off the throttle and steer gently", O("The truck held. I stopped at the next services and sat for twenty minutes with my hands shaking.", {"stress": 6, "job_perf": 4}), O("It slid sideways, caught, and straightened. I stopped and said a long prayer to no one.", {"stress": 8})),
  C("Brake hard", O("The back end swung. The trailer clipped a barrier and the load shifted. I was fine, the freight less so.", {"health": -6, "stress": 10, "job_perf": -5}), O("I stopped in the ditch. Nothing broke but my pride and the dispatcher's patience.", {"stress": 8, "money": -150})),
  C("Pull in and wait for the gritter", O("I lost two hours and nobody minded. The gritter came and I followed it home.", {"stress": 2, "job_perf": 2}), O("Dispatch was furious about the delay. I'd do it again.", {"stress": 4, "job_perf": -2})))
J("trucker", 2, "🛣️", "The hitchhiker",
  "Midnight on a long empty road, and a figure stands in your headlights with a thumb out and a rucksack. Company policy is clear: no passengers.",
  C("Stop and give a lift", O("A student, trying to get home. She slept for most of it, and woke up to thank me. It cost me nothing.", {"karma": 3, "happiness": 3}), O("A strange man, as it turned out. The twenty minutes felt like two hours. I put him down at a petrol station.", {"stress": 8, "karma": 1})),
  C("Drive past", O("I watched her shrink in the mirror. I thought about her more than I should.", {"stress": 2, "karma": -1}), O("I called it in, later. A patrol car found her. She was fine.", {"karma": 2})),
  C("Stop and call the police for her", O("A patrol car came; she was embarrassed but safe. I got a thank-you card.", {"karma": 3, "happiness": 2}), O("She had been waiting for her brother, who showed up as I left. Slightly awkward.", {"happiness": 1})))
# ---- janitor
J("janitor", 1, "🧹", "What you find in the bins",
  "In a bin outside the boardroom, under a pile of shredded paper, there is a clear envelope full of cash.",
  C("Hand it in", O("It turned out to be the petty cash for an event. They gave me a bonus and a handshake I'll remember.", {"karma": 5, "money": 100}), O("Nobody claimed it. After a month, the manager said I could have it. It paid the electricity bill for the year.", {"karma": 3, "money": 400})),
  C("Pocket it", O("I spent it quickly, and guiltily. The envelope haunted me.", {"money": 600, "karma": -5, "stress": 4}), O("A camera had caught it. I was walked out by security.", {"karma": -5}, fired=True)),
  C("Leave it where it is", O("A week later it was gone, and so was the person who had hidden it. I never found out.", {"stress": 2}), O("I told a manager. They said 'thanks' and the envelope vanished. I don't know where.", {"stress": 2, "karma": 1})))
J("janitor", 2, "🌃", "The long night",
  "Empty offices at night have their own rules. At 2 a.m. the senior partner is still at his desk, head down, shoulders shaking.",
  C("Quietly leave a coffee on his desk", O("He looked up and smiled. We never discussed it. He remembered my name at the Christmas party.", {"karma": 3, "happiness": 3}), O("He didn't look up. The coffee was cold when I came back. Sometimes nothing happens.", {"karma": 1})),
  C("Ask if he's all right", O("He told me his wife had left. For ten minutes I wasn't the cleaner. I was a person.", {"karma": 4, "happiness": 4}), O("He snapped at me. I felt foolish, but I'd do it again.", {"stress": 3})),
  C("Clean around him", O("I did my job and he never knew. Sometimes that's the kindest thing.", {"stress": 1}), O("He asked if I could be quieter. I could.", {"stress": 2})))
# ---- security
J("security", 1, "🛡️", "The 3 a.m. alarm",
  "A motion alarm trips in the empty east wing at 3 a.m. The cameras show nothing at all, and your torch is flickering.",
  C("Check it alone", O("A bird had got in through a vent. It looked at me with real disgust.", {"stress": -1, "happiness": 2}), O("A homeless man was asleep in the stairwell. We chatted quietly. I let him stay until dawn.", {"karma": 3, "stress": 2})),
  C("Call for backup", O("Backup took forty minutes and found the bird. I got teased for weeks.", {"stress": 2}), O("Backup found someone. It turned out to be a real break-in, and my call prevented the worst.", {"job_perf": 6, "stress": 5})),
  C("Watch the cameras", O("Nothing happened. A shift later, I realised the camera had been unplugged.", {"stress": 5, "job_perf": -2}), O("I saw a shadow. I never knew what it was.", {"stress": 7})))
J("security", 2, "🎟️", "The rowdy guest",
  "At a late event, a man has had far too much and is arguing with the bar staff. He is twice your size and extremely sure he is in the right.",
  C("Talk him down", O("I made him laugh, took his arm, and got him a taxi. He called me 'mate' and hugged me. A win.", {"job_perf": 6, "stress": 2}), O("He swung at me. I stepped back and the other guards came in.", {"stress": 6, "health": -1})),
  C("Call for backup", O("Three of us escorted him out. A professional, smooth little operation.", {"job_perf": 4}), O("It escalated. A glass broke and a report had to be filed.", {"stress": 5, "job_perf": -2})),
  C("Let the bar staff handle it", O("They did, thank goodness, in their own way.", {"stress": 1}), O("They didn't. I was blamed afterwards for 'not being there'.", {"job_perf": -4, "stress": 5})))
# ---- receptionist
J("receptionist", 1, "📞", "The VIP in the lobby",
  "A man in an immaculate coat has been waiting for forty minutes for a meeting that no one seems to have in their diary. He is polite, and radiating pressure.",
  C("Find out who he's meeting", O("It was the chief executive's wife's brother. A tangle, but I sorted it. He remembered me.", {"job_perf": 5, "happiness": 2}), O("He was in the wrong building. I gave him a map and a coffee.", {"job_perf": 3})),
  C("Let him wait", O("He left, fuming. Somebody got shouted at, and it wasn't me.", {"stress": 3, "job_perf": -2}), O("He was an investor. It was a very bad forty minutes for the firm.", {"stress": 6, "job_perf": -6})),
  C("Escort him to the board room", O("I knocked and entered. Awkward, but it turned out to be the right door.", {"job_perf": 4}), O("It wasn't the right door. I have never felt as small.", {"stress": 6, "job_perf": -3})))
J("receptionist", 2, "📋", "A mislaid message",
  "You wrote down a phone message on a yellow note and put it on the wrong desk. Nobody knows. It was from a client, and it said 'urgent'.",
  C("Own up now", O("The partner groaned, called the client, and fixed it. I got a lecture and a gentle pat on the shoulder.", {"stress": 4, "job_perf": 1, "karma": 2}), O("It was too late. The client had gone elsewhere. I was not fired, to my surprise.", {"stress": 8, "job_perf": -4})),
  C("Find it and slip it onto the right desk", O("Smoothly done. The message was read, the problem was fixed, and no one knew.", {"stress": 2, "job_perf": 1}), O("A colleague saw and kept it to themselves, but now they had something on me.", {"stress": 4})),
  C("Say nothing", O("The client called back, angrier. The firm blamed the phone system.", {"stress": 5, "karma": -2}), O("It was never found out. I never forgot.", {"stress": 3, "karma": -3})))
save("jobs_a.json")

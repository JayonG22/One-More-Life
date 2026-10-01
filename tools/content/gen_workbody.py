#!/usr/bin/env python3
"""Generates data/events/workbody.json — v0.16 'Work and Body' events."""
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

# ------------------------------------------------------------------ work
E("wb.micromanager", "🔍", "Copied in on everything",
  "{~Your manager|The person you report to} has started {~asking for a status update before lunch|copying themselves into every email|standing behind your desk}. {~Your work hasn't changed. Their anxiety has.|You are starting to dread the sound of their shoes.}",
  A(18, 64, "boss:micromanager", employed=True),
  C("Over-communicate until they relax",
    O("I sent a summary every morning. After a month they stopped checking, and I kept sending them out of habit.", {"stress": 1, "job_perf": 3}),
    O("It fed the beast. They wanted more, and I became the person who always answered within a minute.", {"stress": 5, "job_perf": 1, "happiness": -2})),
  C("Raise it, calmly",
    O("They were embarrassed and then grateful. Things eased. I think they'd never been asked.", {"stress": -4, "happiness": 3, "job_perf": 2}),
    O("They said they'd 'reflect', then did the same thing more quietly.", {"stress": 2, "happiness": -1}),
    O("It went around the office by lunchtime. My name was used in a sentence beginning 'Apparently'.", {"stress": 5, "happiness": -3, "job_perf": -2})),
  C("Start looking elsewhere",
    O("I updated my CV at the kitchen table, and the act of it felt like opening a window.", {"stress": -2, "happiness": 2}),
    O("A recruiter called before I'd finished the first draft. The timing felt like a sign.", {"happiness": 3, "job_perf": -1})))

E("wb.brilliant_boss", "🧠", "The boss who is better than you",
  "{~Your manager|The head of your team} {~rewrote your report in the margin, and they were right|handled a client call in a way you'll be analysing for weeks|says your ideas are 'fine'}. You've never felt so sharpened and so stupid.",
  A(20, 64, "boss:brilliant", employed=True),
  C("Ask to shadow them",
    O("I spent a year a pace behind, and learned more than in any course.", {"smarts": 3, "job_perf": 3, "stress": 3}),
    O("They let me sit in on two meetings and then forgot. I made the most of the two.", {"smarts": 2, "job_perf": 1})),
  C("Push back on a decision",
    O("They thought for a moment and said 'you may be right'. I'll be living off that for years.", {"job_perf": 4, "happiness": 5}),
    O("I was wrong, and it was public, and educational.", {"job_perf": -2, "smarts": 1, "stress": 3})),
  C("Keep your head down",
    O("Safe and dull. I learned the minimum and felt the lack.", {"stress": -1, "happiness": -2}),
    O("Quietly, I got better just by watching. It took two years and nobody noticed.", {"smarts": 1.5, "job_perf": 1})))

E("wb.office_rival", "🥊", "A rival in the next desk",
  "{~A colleague|Someone two desks along} has started {~getting invited to meetings you're not|saying 'we' when they mean themselves|competing with you on everything, including who arrives first}.",
  A(18, 64, "colleague:rival", employed=True),
  C("Out-work them",
    O("I won the quarter and lost a weekend. They sent me a small, sincere message of congratulation.", {"job_perf": 5, "stress": 4}),
    O("I wore myself out and they got the client anyway. I deserved better, which is not how it works.", {"job_perf": 1, "stress": 6, "happiness": -3})),
  C("Make an ally of them",
    O("We had a coffee. It turned out they were as scared as I was. We became the closest pair on the floor.", {"happiness": 5, "stress": -2, "job_perf": 2}),
    O("They took the coffee and used the conversation in the next meeting against me.", {"stress": 4, "happiness": -3})),
  C("Go above their head",
    O("The director listened, nodded, and did nothing visible. A month later my rival's budget shrank.", {"job_perf": 2, "karma": -2, "stress": 2}),
    O("It got back to them before it got to anyone else. The atmosphere on the floor changed.", {"stress": 6, "happiness": -4, "karma": -2})))

E("wb.gossip", "🗣️", "You have been told something",
  "{~A colleague|The office gossip} lowers their voice and tells you {~who is being let go|who earns what|that two senior people are in a relationship|what the director really said}.",
  A(18, 64, "colleague:gossip", employed=True),
  C("Keep it to yourself",
    O("It was heavy to carry, but by spring nobody remembered who knew it first.", {"stress": 2, "karma": 2}),
    O("I accidentally let it slip in a meeting. Someone looked at me very carefully.", {"stress": 6, "karma": -2, "happiness": -2})),
  C("Pass it on",
    O("I got a moment of popularity and then a long hangover of regret.", {"happiness": 2, "karma": -4, "stress": 2}),
    O("It went round the floor like a virus. I was found out within a week.", {"happiness": -4, "karma": -5, "stress": 5, "job_perf": -2})),
  C("Tell them you'd rather not know",
    O("They looked hurt, then relieved. We've never discussed it again.", {"karma": 2, "stress": -1}),
    O("They told me anyway, in a corridor, in four words.", {"stress": 3})))

E("wb.mentor", "🎓", "Someone is paying attention",
  "{~A senior colleague|A manager from another team} has been {~quietly sending you useful articles|stopping by your desk to ask how it's going|putting your name forward for things}.",
  A(20, 60, "colleague:mentor", employed=True),
  C("Ask them to mentor you properly",
    O("We met monthly for two years. It was the best professional decision I ever made.", {"smarts": 2, "job_perf": 4, "happiness": 4}),
    O("They said yes, and their calendar said no. We managed four meetings.", {"job_perf": 1, "smarts": 1})),
  C("Accept the help quietly",
    O("I took the tips and never said thank you. I regret that.", {"job_perf": 2, "karma": -1}),
    O("I sent a card at Christmas. They kept it on their desk for years.", {"job_perf": 2, "karma": 2, "happiness": 2})),
  C("Turn it down, politely",
    O("I wanted to do it my own way. It was slower.", {"job_perf": -1, "stress": 1}),
    O("They respected it, and left the door open.", {"job_perf": 0, "karma": 1})))

E("wb.union_vote", "✊", "A vote on industrial action",
  "{~The union has called a ballot|Your colleagues are talking about a walk-out|A notice on the board proposes a strike}, over {~pay|staffing|a change to the pension|a rota nobody agreed to}.",
  {"age": [18, 64], "employed": True},
  C("Vote to strike",
    O("The picket line was cold and oddly joyful. We won most of what we asked for.", {"happiness": 4, "stress": 4, "money": -600, "karma": 2}),
    O("The strike went on for weeks. The company held out. We went back with less than we'd hoped.", {"happiness": -3, "stress": 7, "money": -1800})),
  C("Vote against",
    O("I crossed the line and was spat at in a car park. The company thanked me in an email.", {"happiness": -4, "karma": -3, "stress": 6, "job_perf": 2}),
    O("The vote failed without me. I kept working and felt the looks for a year.", {"happiness": -2, "karma": -1, "stress": 3})),
  C("Abstain",
    O("I stayed out of it. The outcome was a compromise that pleased nobody, which is usually how you can tell it's fair.", {"stress": 2}),
    O("Nobody asked me why, which is how I found out I wasn't as central as I'd thought.", {"stress": 1, "happiness": -1})))

E("wb.restructure", "📉", "The all-hands meeting",
  "A meeting is called at short notice. {~The director's smile is a little too steady.|There are pastries, which is always a bad sign.|Everyone has brought a notebook and nobody is writing.}",
  A(20, 64, "company_shaky", employed=True),
  C("Take the voluntary redundancy",
    O("The package was better than I'd feared. I left with a cheque and a card and a clean feeling.", {"money": 6000, "stress": -3, "happiness": 2}),
    O("I took it, and three months later the same company was hiring for my old role at less.", {"money": 4000, "happiness": -3, "stress": 3})),
  C("Start job hunting now",
    O("By the time the letters went round, I already had two interviews. I kept my head up.", {"stress": 3, "happiness": 2}),
    O("I found nothing and felt the clock in my chest.", {"stress": 6, "happiness": -2})),
  C("Stay and make yourself useful",
    O("I picked up the work of two people who'd left. They noticed, eventually.", {"job_perf": 5, "stress": 6}),
    O("I worked twice as hard and was let go anyway in the next round.", {"job_perf": 2, "stress": 8, "happiness": -5}),
    O("The wave passed over me. I've felt vaguely guilty about my luck ever since.", {"stress": 3, "karma": 1})))

E("wb.political_chance", "🎯", "A seat at the right table",
  "{~A senior person|The director} has noticed you, and {~wants you in the room for the big presentation|suggested you lead the new project|put your name on a list}. {~It might be a break. It might be a trap.|Everybody is watching to see what you do with it.}",
  A(22, 60, "political_office", employed=True),
  C("Take it and own it",
    O("I rehearsed for a week. It went better than I dared hope, and I was promoted by summer.", {"job_perf": 8, "happiness": 5, "stress": 4}),
    O("It went wrong in a small, instructive way. They forgave me because they'd forgiven themselves worse.", {"job_perf": 2, "stress": 6, "smarts": 1})),
  C("Share the credit",
    O("My team loved me for it, and the director noted the gesture. Modesty, it turns out, is a tactic.", {"job_perf": 4, "karma": 3, "happiness": 4}),
    O("The director liked the confidence of a solo act more. I was quietly passed over.", {"job_perf": -1, "karma": 2, "stress": 3})),
  C("Decline and recommend someone else",
    O("I sent someone deserving. They never forgot it, and later returned the favour.", {"karma": 4, "happiness": 2, "job_perf": 1}),
    O("They thanked me and did not offer again.", {"job_perf": -2, "happiness": -2})))

E("wb.freelance_late", "📬", "An invoice that never gets paid",
  "A client is {~sixty days|ninety days|four months} late paying a {~large|rather important|frankly life-sustaining} invoice, and every email you send gets a cheerful auto-reply.",
  {"age": [20, 75], "real": ["freelance"]},
  C("Chase, politely, again",
    O("On the fifth email they paid, with an apology so warm I almost felt I'd been rude.", {"money": 2500, "stress": 2}),
    O("They paid a third of it and promised the rest. The rest is, as I write, still promised.", {"money": 900, "stress": 6, "happiness": -2})),
  C("Write it off",
    O("I told myself I was buying a lesson. It was an expensive one.", {"money": -400, "stress": 3, "happiness": -2}),
    O("I wrote it off and spent a month telling myself it was fine. It wasn't, but it was over.", {"money": -800, "stress": 4})),
  C("Send a formal demand",
    O("A letter from a solicitor worked in a day. I got paid, and lost the client. I'd have made the same call again.", {"money": 2800, "stress": 4, "karma": -1}),
    O("The company had gone into administration. The demand reached no one.", {"money": -300, "stress": 7, "happiness": -3})))

E("wb.freelance_windfall", "🌟", "The big client",
  "{~A larger company|A client with a recognisable name} wants to {~retain you for six months|give you a proper, long-term contract}. The rate is {~half again your usual|more money than you've asked for in one go}.",
  {"age": [20, 75], "real": ["freelance"]},
  C("Take it, exclusively",
    O("Six months of steady work, and steady pay. I also stopped looking for other clients, which bit me at the end.", {"money": 14000, "happiness": 3, "stress": -2}),
    O("The contract was renewed, then cancelled with a week's notice. I had no pipeline.", {"money": 9000, "happiness": -2, "stress": 7})),
  C("Take it, but keep other clients",
    O("I ran myself ragged and ended up earning more than I ever had. I slept like the dead.", {"money": 17000, "stress": 7, "health": -1}),
    O("Something slipped, and a small client left in a huff. A price worth paying, I think.", {"money": 12000, "stress": 5, "happiness": 1})),
  C("Negotiate harder",
    O("They came up again, and I learned how much I'd been under-charging for years.", {"money": 20000, "happiness": 6, "smarts": 1}),
    O("They said no and went elsewhere. I've thought about the extra 10% every day since.", {"money": 0, "happiness": -4, "stress": 3})))

E("wb.midlife_switch", "🔄", "Is this it?",
  "You're {~in a meeting|on the train home|in the kitchen at 6 a.m.} and the thought arrives, fully formed: {~'I could do something else.'|'I've been doing this for fifteen years.'|'What if I'd been wrong about what I wanted?'}",
  {"age": [34, 56], "employed": True},
  C("Start retraining in the evenings",
    O("Two years of night classes. It nearly broke my marriage, and then it rebuilt it.", {"smarts": 3, "stress": 6, "happiness": 4, "money": -4000}),
    O("I quit after six months. The notes are still in a drawer, and sometimes I open it.", {"smarts": 1, "stress": 3, "money": -1500, "happiness": -2})),
  C("Quit and jump",
    O("I resigned on a Friday and felt my shoulders drop an inch. I've never looked back.", {"happiness": 8, "stress": 5, "money": -9000}),
    O("I quit, and the first six months were a disaster. The next three years were wonderful.", {"happiness": 2, "stress": 9, "money": -14000})),
  C("Stay, and change what you can",
    O("I asked for a transfer. Three weeks later I was in a different team and a slightly different life.", {"happiness": 4, "stress": -2}),
    O("Nothing changed, except that I now knew what I was putting up with.", {"happiness": -2, "stress": 2})),
  cooldown=10)

E("wb.recruiter", "📞", "A call from a recruiter",
  "A recruiter has {~your number and a pitch|found you online|heard good things about you from someone you don't know}. The job is {~more money, less interesting|the same work at a better company|something you've never done and a bit terrifying}.",
  {"age": [23, 60], "employed": True},
  C("Take the interview",
    O("I got the offer. I used it to ask for a raise at my current job, which I got.", {"money": 4000, "happiness": 3, "job_perf": 2}),
    O("The interview went better than expected and the job turned out to be a different one from the brief.", {"stress": 3, "happiness": 1})),
  C("Politely decline",
    O("They checked back in a year. By then I was ready.", {"job_perf": 1}),
    O("I never heard from them again, and sometimes I wonder about the other path.", {"happiness": -1})),
  C("Let it slip to your boss",
    O("It worked. I got a raise and a slightly uncomfortable hug.", {"money": 3000, "job_perf": 2, "karma": -1}),
    O("It did not work. My boss said 'Good luck', and meant it.", {"stress": 5, "job_perf": -3, "happiness": -2})))

E("wb.job_hunt_low", "🪫", "Another month of searching",
  "{~The emails have stopped|The auto-replies are all the same|The CV feels like a work of fiction} and the gap on it is getting harder to explain.",
  {"age": [20, 62], "real": ["job_seeking", "cv_gap"]},
  C("Ask a friend for a referral",
    O("A friend pushed my CV to the top of a pile. I got an interview because of a name, not a line.", {"happiness": 4, "stress": -2}),
    O("The friend's company wasn't hiring. They felt awful, and so did I.", {"happiness": -2, "stress": 2})),
  C("Take any work, for now",
    O("A stopgap job turned out to be fine. It also made the next application easier.", {"money": 2500, "stress": -3, "happiness": 1}),
    O("A stopgap job felt like a defeat. I worked it through gritted teeth.", {"money": 2200, "happiness": -4, "stress": 2})),
  C("Volunteer to fill the gap",
    O("Volunteering gave me a story to tell, and a reference.", {"karma": 4, "happiness": 4, "smarts": 1}),
    O("It felt good, and did nothing to the CV, and I did it anyway.", {"karma": 3, "happiness": 3})))

# ------------------------------------------------------------------ body
E("wb.gp_dismissed", "🩺", "'Probably nothing'",
  "The GP listened for two minutes, checked a screen and said it was {~probably stress|probably nothing|probably a virus}. You don't think it's {~stress|nothing|a virus}.",
  {"age": [18, 90], "real": ["symptoms"]},
  C("Insist on a referral",
    O("They sighed and wrote the letter. It took a minute. I'd been dreading that minute for a week.", {"stress": 2, "happiness": 1}),
    O("They referred me, reluctantly. The waiting list was long, but I was on it.", {"stress": 3})),
  C("Go back in a month",
    O("A different GP took it seriously the second time. The first was overstretched, not wrong.", {"stress": 2}),
    O("The symptoms eased, and I felt both foolish and relieved.", {"stress": -2, "happiness": 1})),
  C("Get it checked privately",
    O("A private clinic found it in an hour. The bill was not small.", {"money": -700, "stress": 1, "health": 1}),
    O("They found nothing, and charged me for the privilege. At least I know now.", {"money": -700, "stress": -2})))

E("wb.waiting_letter", "✉️", "The letter that hasn't come",
  "You're {~still waiting|keeping the hall table clear|checking the post} for the specialist's appointment. Every brown envelope makes your stomach drop.",
  {"age": [18, 90], "real": ["waiting_list"]},
  C("Phone the hospital",
    O("A receptionist found my name on a list I'd never have believed existed. A date was given, and it helped.", {"stress": -3}),
    O("I was on hold for an hour and then told to 'wait for the letter'.", {"stress": 4, "happiness": -2})),
  C("Pay to go private",
    O("The consultant saw me within the week. The bill sat in my chest for a month.", {"money": -1100, "stress": -4, "health": 2}),
    O("Private was faster and no more certain. I'm not sure what I bought.", {"money": -1100, "stress": 1})),
  C("Try not to think about it",
    O("I threw myself into work, and was more productive than I'd been in years.", {"stress": 2, "job_perf": 3}),
    O("I couldn't stop thinking about it and lost a month to 3 a.m. searching.", {"stress": 7, "happiness": -4, "health": -1})))

E("wb.pill_fatigue", "💊", "Tired of taking them",
  "It's the third year of the tablets. You {~feel fine|feel better than you did|can't remember the last flare} and the little box on the shelf is starting to feel like a verdict.",
  {"age": [18, 90], "real": ["on_meds"]},
  C("Stop quietly",
    O("For six months I felt great. Then the flare came back harder than before.", {"health": -5, "stress": 6, "happiness": -3}),
    O("I got away with it for a year, but every twinge made me uneasy.", {"health": -2, "stress": 3})),
  C("Keep taking them",
    O("Boring, reliable, and exactly why I'm still well.", {"health": 1, "stress": -1}),
    O("The side effects were real but manageable. I kept taking them, and resented them a little less each year.", {"health": 1, "happiness": -1})),
  C("Talk it through with the doctor",
    O("We lowered the dose. I felt no different and was told I was a model patient.", {"health": 1, "stress": -2, "happiness": 2}),
    O("The doctor said a polite 'no', and was right, and I didn't enjoy it.", {"stress": 2})))

E("wb.eyes_menu", "📖", "Holding the menu at arm's length",
  "You find yourself {~holding the menu at arm's length|squinting at a screen|asking someone to read the small print}. {~They notice.|You're pretending it isn't happening.}",
  {"age": [38, 90], "real": ["poor_vision"]},
  C("Book an eye test",
    O("The optician said 'quite common'. I felt like I was being admitted to a club.", {"stress": -1, "happiness": 1}),
    O("The optician said 'you should have come two years ago'.", {"stress": 2, "happiness": -1})),
  C("Buy reading glasses at the chemist",
    O("Three pairs, in different rooms, all of them lost by Friday.", {"money": -40, "stress": 1}),
    O("They work. I look like my father. I'm at peace with it.", {"money": -20, "happiness": 1})),
  C("Carry on squinting",
    O("I gave myself a headache that lasted a week. A colleague laughed at me, kindly.", {"health": -1, "stress": 3}),
    O("I missed a street sign and took a twenty-minute detour.", {"stress": 2, "happiness": -1})))

E("wb.toothache", "🦷", "Three a.m., and a tooth",
  "A tooth wakes you at {~three|half past two|four} in the morning and will not be reasoned with. {~You haven't seen a dentist in years.|It has been coming for months.}",
  {"age": [16, 90], "real": ["bad_teeth"]},
  C("Find an emergency dentist",
    O("The dentist was kind and the bill was not. The relief was biblical.", {"money": -320, "stress": -3, "health": 1}),
    O("They saw me within the hour and saved the tooth. I became a person who flosses.", {"money": -350, "stress": -2, "health": 1})),
  C("Pain relief and hope",
    O("Two days of painkillers and a swollen jaw. The tooth is lost now.", {"health": -2, "stress": 4, "looks": -1}),
    O("It eased off and I forgot about it, until the next time, which came worse.", {"health": -1, "stress": 3})),
  C("Finally book a proper check-up",
    O("An hour in the chair, a bill, a plan. I left feeling stupidly proud.", {"money": -380, "happiness": 2, "health": 1}),
    O("The dentist tutted at six separate things. I'm paying them off in instalments.", {"money": -600, "stress": 3, "health": 1})))

E("wb.hearing_tv", "📺", "'Turn it up'",
  "Your {~family|partner|friends} keep asking you {~to repeat yourself|if you're all right|whether you've had your ears checked}. The television is now louder than is polite.",
  {"age": [50, 95], "real": ["poor_hearing"]},
  C("Get your hearing tested",
    O("The test said what I already knew. The audiologist was gentle about it.", {"happiness": 1, "stress": -1}),
    O("They said it was age, and told me the options. I chose to think about it.", {"stress": 1})),
  C("Insist everyone else mumbles",
    O("It didn't work, but it made for some good family arguments.", {"happiness": -1, "stress": 2}),
    O("My daughter filmed me and played it back. It was funnier than it should have been.", {"happiness": 2, "stress": 1})),
  C("Get a hearing aid",
    O("A small beige object changed Sundays. I'd forgotten the sound of the kettle.", {"money": -800, "happiness": 7}),
    O("It took weeks to get used to. Then I heard my grandchild whisper my name.", {"money": -800, "happiness": 8, "stress": 2})))

E("wb.fitness_wake", "🏃", "The stairs are a negotiation",
  "You {~climb a flight of stairs|run for the bus|play with the kids} and realise you {~have to stop halfway|are out of breath|can feel it in your knees}. {~That was not always true.|The stairs used to be nothing.}",
  {"age": [28, 70], "real": ["unfit"]},
  C("Start running",
    O("The first run was a disaster. The third was a good one. By spring I could do a parkrun without stopping.", {"health": 3, "happiness": 5, "stress": -3}),
    O("I got shin splints in week three and stopped. I kept the trainers by the door as a reproach.", {"health": 0, "happiness": -2})),
  C("Join a gym with a friend",
    O("We went every Tuesday. We talked more than we lifted, and it was the best part of the week.", {"health": 2, "happiness": 4}),
    O("The friend dropped out after two weeks. I kept paying for three months.", {"money": -300, "happiness": -2})),
  C("Tell yourself you'll start in January",
    O("January came. I started in February.", {"happiness": -1}),
    O("I did start, eventually, and two years later I was glad I'd waited for nobody.", {"health": 2, "happiness": 3})))

E("wb.sleepless", "🌙", "You can't remember the last good night",
  "You're {~awake at 3 a.m. again|running on coffee|forgetting words mid-sentence}. The kind of tired that makes everything a little less bearable.",
  {"age": [18, 80], "real": ["sleep_poor"]},
  C("Change your evenings",
    O("No screens after ten, a book, a proper lamp. In three weeks I was sleeping like a teenager.", {"health": 2, "stress": -4, "happiness": 3}),
    O("I lasted nine days. The habit is easy, and the discipline isn't.", {"stress": -1, "happiness": 1})),
  C("See a doctor",
    O("The doctor asked five questions and put the answer on a leaflet. It was right.", {"stress": -2, "health": 1}),
    O("They suggested therapy for the things keeping me awake. I went. It was a good idea.", {"stress": -3, "happiness": 3, "money": -150})),
  C("Push through",
    O("A month later I snapped at someone who didn't deserve it. I'm apologising still.", {"stress": 5, "karma": -2, "health": -1}),
    O("I got through on caffeine and will. I am not proud of the price.", {"health": -2, "stress": 4})))

E("wb.fortieth", "4️⃣0️⃣", "Forty",
  "{~Forty|The fortieth birthday} arrives, {~and with it a specific pain in the lower back|with a card about being over the hill|and somebody kindly offers you a seat on the train}.",
  {"age": [40, 41]},
  C("Make a list of what you still want",
    O("The list had eleven things on it. I crossed one off within the month.", {"happiness": 6, "stress": -2}),
    O("The list was depressing. I burned it, then wrote a better one.", {"happiness": 2, "stress": 2})),
  C("Throw a party",
    O("Everyone I love was in one room, which is rare. It was the best night of the decade.", {"happiness": 9, "money": -500}),
    O("Nobody came who I hoped would. The ones who did were brilliant.", {"happiness": 4, "money": -400})),
  C("Ignore it",
    O("It was a Tuesday. I went to work.", {"happiness": -1}),
    O("I got through the day. The next morning my back told me I hadn't got away with it.", {"health": -1, "stress": 1})),
  once=True, weight=40)

E("wb.sixtieth", "6️⃣0️⃣", "Sixty",
  "You are {~sixty|sixty today}, {~and it doesn't feel like what sixty was supposed to feel like|and still in possession of most of your marbles and a good number of your knees}.",
  {"age": [60, 61]},
  C("Plan the next decade properly",
    O("I sat with a notebook and a glass of wine. The decade started to look like a place you could go.", {"happiness": 6, "stress": -3}),
    O("The plan fell apart on contact with reality, as plans do, but I'd had the thinking time.", {"happiness": 3})),
  C("Travel somewhere you've always meant to",
    O("I went to a place in a photograph on a wall I'd had since I was twenty. It was smaller and better.", {"happiness": 9, "money": -4500}),
    O("The trip was harder than I'd planned for. My body reminded me of its terms. It was still worth it.", {"happiness": 5, "health": -1, "money": -4500})),
  C("Have a quiet day",
    O("I walked to the park and sat on a bench and was perfectly content.", {"happiness": 4, "stress": -3}),
    O("A quiet day, and a long phone call with someone I love.", {"happiness": 5})),
  once=True, weight=40)

E("wb.eightieth", "8️⃣0️⃣", "Eighty",
  "{~Eighty|Your eightieth year} and the {~stairs|garden|walk to the shops} are all a matter of {~planning|pace|negotiation}. {~The grandchildren are taller than you.|Somebody has said 'you don't look it' and they lied.}",
  {"age": [80, 81]},
  C("Gather the family",
    O("Four generations in one room. Nobody argued, which was a miracle.", {"happiness": 10, "money": -400}),
    O("They all came, stayed too long, left a mess. I'd have had it no other way.", {"happiness": 8, "stress": 2, "money": -300})),
  C("Write the letters you've meant to write",
    O("It took a month. I left them with the solicitor. I slept better afterwards.", {"happiness": 5, "stress": -4}),
    O("Halfway through, I found a letter I'd never sent in 1974. I sent it.", {"happiness": 4, "stress": 1})),
  C("Carry on as normal",
    O("Normal is not a small thing at eighty. It's a gift.", {"happiness": 3}),
    O("I pretended it was just another day. A neighbour brought a cake, and I let them.", {"happiness": 4})),
  once=True, weight=40)

E("wb.after_fall", "🦯", "After the fall",
  "It has been {~a few months|a long winter} since you fell, and {~you've stopped going down the stairs without the rail|the flat feels bigger and less safe|everyone has become very careful around you}.",
  {"age": [60, 100], "real": ["fallen"]},
  C("Get the home adapted",
    O("Rails, a stair lift and a walk-in shower. I felt old for a week and independent for years.", {"money": -2500, "health": 2, "happiness": 3}),
    O("The installation took a month and was a nuisance, but the confidence was worth it.", {"money": -2500, "stress": -2, "happiness": 2})),
  C("Move closer to family",
    O("I moved in two streets from my daughter. She pretended not to be thrilled, and I pretended not to be glad.", {"happiness": 4, "stress": -3}),
    O("It was the right thing and I spent a year missing my old house.", {"happiness": -2, "stress": -2})),
  C("Carry on exactly as before",
    O("I was fine for another year, and then I wasn't.", {"health": -3, "stress": 4}),
    O("Stubbornness, I've found, is sometimes the very thing that keeps you going.", {"happiness": 1, "health": 0})))

E("wb.well_kept", "✨", "'You look well'",
  "{~A friend|Someone you haven't seen in years} tells you {~you look well|you don't look your age|they'd have thought you were ten years younger}. {~You try not to smile.|You realise it's true.}",
  {"age": [45, 95], "real": ["well_kept"]},
  C("Credit the habits",
    O("I listed them: walking, sleep, real food, not too much of the rest. They wrote them down.", {"happiness": 5, "karma": 1}),
    O("I said 'it's just luck', and they said 'no it isn't'. They were right.", {"happiness": 4})),
  C("Brush it off",
    O("Compliments are a tax I'd pay every day if I could.", {"happiness": 3}),
    O("They said it again a year later. I finally believed it.", {"happiness": 5})),
  C("Ask them to come with you next time",
    O("They came for a walk and a coffee. It became a fortnightly thing.", {"happiness": 6, "health": 1}),
    O("They said yes, once, and never again. I understood.", {"happiness": 1})))

json.dump(EV, open("data/events/workbody.json", "w"), indent=1, ensure_ascii=False)
open("data/events/workbody.json", "a").write("\n")
print(len(EV), "events,", sum(len(e["choices"]) for e in EV), "choices")

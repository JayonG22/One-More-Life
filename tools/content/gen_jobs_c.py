#!/usr/bin/env python3
"""Job events, part C: office, professional, science and forces."""
from dsl import *
def J(job, n, icon, title, text, *choices, **kw):
    cond = {"job": job, "age": [18, 74]}
    cond.update(kw.pop("cond", {}))
    E(f"{job}_{n}", icon, title, text, cond, *choices, prefix="job.", **kw)

J("accountant", 1, "🧮", "The number that doesn't tie",
  "Reconciling the quarter, a figure sits eleven thousand dollars off. It is a very clean error, the kind that doesn't happen by accident.",
  C("Trace it to the source", O("It was a mistyped invoice by a junior. Easy fix, and I taught her the checks. She sent a card.", {"job_perf": 5, "karma": 2}), O("It led to a supplier who'd been double-billing for years. The firm recovered the money. I was noticed.", {"job_perf": 9, "money": 150, "stress": 4})),
  C("Ask the finance director", O("He went pale, said he'd handle it, and the matter vanished. I thought about it often.", {"stress": 6, "karma": -1}), O("He thanked me. A month later he was gone.", {"stress": 4, "job_perf": 3})),
  C("Plug the gap and move on", O("I made an adjusting entry. It balanced, and it bothered me for months.", {"stress": 4, "karma": -3}), O("An auditor found it a year later. I explained, and it cost me.", {"stress": 8, "job_perf": -6, "karma": -3})))
J("accountant", 2, "📊", "Tax week",
  "Fourteen clients, one deadline and a shared printer that jams on the third page. A client has dropped off a shoebox of receipts and said, 'Everything's in there.'",
  C("Go through the box line by line", O("I found a legitimate deduction he'd never have claimed. He tipped me in whisky.", {"money": 60, "job_perf": 5, "stress": 4}), O("The box was mostly napkins. I did what I could.", {"stress": 5})),
  C("Ask him to resubmit it sorted", O("He did. It saved me an evening.", {"stress": -1, "job_perf": 2}), O("He fumed and took his business elsewhere.", {"job_perf": -3})),
  C("File with what you have", O("It passed. Nobody was happier or sadder.", {"stress": 1}), O("The tax office queried it. I spent a month on letters.", {"stress": 6, "job_perf": -3})))
J("marketing", 1, "📣", "The campaign that nobody asked for",
  "Your pitch is two hours from presentation. The client wants 'edgy but safe', 'viral but classic'. The last slide has your best joke on it, and your boss hates it.",
  C("Keep the joke", O("The client laughed out loud. The campaign won an award.", {"job_perf": 8, "happiness": 5}), O("The client didn't get it. The room was horribly quiet.", {"job_perf": -4, "stress": 6})),
  C("Cut it", O("The deck was safe and forgettable. It was approved without a flicker of feeling.", {"job_perf": 1}), O("The client said it lacked 'spark'. I wanted the floor to open.", {"job_perf": -2, "stress": 4})),
  C("Show both versions", O("They picked the joke. My boss pretended it was his idea.", {"job_perf": 5, "happiness": 2}), O("They picked the safe one, then asked about the joke for a month.", {"job_perf": 2})))
J("marketing", 2, "🔥", "The post that went wrong",
  "A cheerful social post you scheduled lands at the same moment as a sad news story. Within an hour it is being quoted back at the brand, with screenshots.",
  C("Take it down and apologise", O("A short, sincere apology. The internet moved on in a day.", {"job_perf": 3, "stress": 5}), O("The apology was screenshotted too. A long weekend.", {"job_perf": -2, "stress": 8})),
  C("Say nothing", O("The storm passed. Nobody ever fired anyone.", {"stress": 4}), O("The silence was louder than the post. The client was furious.", {"job_perf": -5, "stress": 7})),
  C("Own it with humour", O("Self-deprecating, quick, and perfectly pitched. It turned the mood.", {"job_perf": 7, "happiness": 4}), O("It landed badly. A newspaper picked it up.", {"job_perf": -6, "stress": 9})))
J("analyst", 1, "📉", "The model says no",
  "Your forecast shows the product line the CEO loves will lose money for three years. He has already announced it.",
  C("Present it honestly", O("He listened, and for once did not shoot the messenger. The product was re-scoped.", {"job_perf": 7, "karma": 3}), O("He thanked me coldly. I was moved to another team within a month.", {"job_perf": -3, "stress": 6})),
  C("Adjust the assumptions", O("It looked better. It was all my fault when the real numbers came in.", {"job_perf": -5, "karma": -4, "stress": 6}), O("Nobody checked. Nobody ever checks. I didn't sleep.", {"karma": -3, "stress": 5})),
  C("Show it privately to someone who can act", O("The CFO took it quietly and turned the ship. I was thanked in private.", {"job_perf": 5, "karma": 2}), O("It leaked. The CEO found out. He didn't forgive me.", {"stress": 8, "job_perf": -4})))
J("analyst", 2, "🔍", "The beautiful dataset",
  "A messy dataset hides a pattern that nobody has seen: customers who buy on Tuesday are twice as likely to churn.",
  C("Dig deeper", O("It led to a big discovery and a real change in strategy. I got a promotion track.", {"job_perf": 8, "smarts": 2}), O("It was a statistical fluke. I felt a bit silly, but I learned.", {"smarts": 1, "job_perf": 1})),
  C("Share it with the team", O("The team ran with it. I got a credit in the deck.", {"job_perf": 5, "happiness": 3}), O("Someone else presented it. I stayed quiet and furious.", {"stress": 5, "job_perf": -1})),
  C("Sit on it for now", O("I verified it for months. Eventually it came out right.", {"smarts": 2, "stress": 3}), O("A competitor published it first.", {"job_perf": -4, "stress": 5})))
J("engineer", 1, "🏗️", "The load test",
  "The bridge model passes every test but one, and the one it fails is a rare combination of wind and traffic that probably never happens.",
  C("Redesign the joint", O("It cost two weeks and delayed the deadline. The design was better for it.", {"job_perf": 6, "karma": 3, "stress": 4}), O("The client balked at the cost. I was backed by the senior engineer.", {"job_perf": 4, "stress": 6})),
  C("Add a safety factor", O("Cheap and elegant. Nobody even noticed.", {"job_perf": 3, "smarts": 1}), O("It was too elegant: it hid the real issue.", {"stress": 5, "job_perf": -2})),
  C("Sign it off", O("It stood for fifty years. Nobody ever knew.", {"karma": -3, "stress": 4}), O("A storm tested it. It held, barely. I aged ten years in a night.", {"karma": -3, "stress": 10, "health": -3})))
J("engineer", 2, "🔬", "The prototype",
  "Your prototype works, which is the problem. Management wants to ship it Monday. It has never run for more than six hours.",
  C("Fight for more testing", O("They gave me a week. I found three failures. The product was safer.", {"job_perf": 6, "karma": 3}), O("They gave me one day. It wasn't enough, but it was something.", {"stress": 5, "job_perf": 2})),
  C("Ship it with a warning", O("It worked. Nobody read the warning.", {"stress": 3}), O("A customer was injured. I replayed it for years.", {"karma": -5, "stress": 10})),
  C("Quietly add extra safeguards", O("A bit of rule-bending that no one ever knew about. Good engineering.", {"job_perf": 4, "karma": 2}), O("It broke the schedule and my reputation took a hit.", {"stress": 5, "job_perf": -3})))
J("architect", 1, "📐", "The client's cousin",
  "The client's cousin, an amateur, 'just has a few suggestions' that would turn your elegant atrium into a glass-fronted car park.",
  C("Listen and politely decline", O("The cousin was flattered to be heard. The atrium survived.", {"job_perf": 4, "stress": 2}), O("The cousin escalated to the client. A very long lunch.", {"stress": 5})),
  C("Sketch his idea", O("It was awful. I showed him why. He conceded.", {"job_perf": 5, "smarts": 1}), O("It was surprisingly not awful. I borrowed one idea.", {"job_perf": 3, "happiness": 2})),
  C("Cave", O("It was built. It was ugly. It won no prizes.", {"job_perf": -4, "happiness": -3}), O("It was built, and the cousin took all the credit. I did the paperwork.", {"job_perf": -3, "stress": 5})))
J("architect", 2, "🏛️", "The last model night",
  "The competition deadline is at nine in the morning. The model is balsa, glue and exhaustion, and at 3 a.m. a corner collapses.",
  C("Rebuild it", O("I rebuilt it by dawn, bleary and proud. It placed second.", {"job_perf": 6, "stress": 6, "health": -2}), O("It came out better. It won.", {"job_perf": 10, "happiness": 6})),
  C("Present it broken", O("I called it 'a ruin by design'. The jury loved it.", {"job_perf": 6, "happiness": 4}), O("The jury did not.", {"job_perf": -4, "stress": 5})),
  C("Withdraw", O("I slept for 12 hours and felt fine.", {"stress": -4, "job_perf": -2}), O("I regretted it for years.", {"stress": 4, "happiness": -3})))
J("designer", 1, "🎨", "Make the logo bigger",
  "The client's feedback on version nine: 'Can you make the logo bigger? Also smaller. Also more minimal.' The deadline is Thursday.",
  C("Do all three and send options", O("They picked option two, which was my favourite anyway.", {"job_perf": 4}), O("They picked all three and told me to combine them.", {"stress": 6})),
  C("Push back politely", O("They listened. The final was elegant, and they thought it was their idea.", {"job_perf": 6, "smarts": 1}), O("They threatened to go elsewhere. They bluffed.", {"stress": 4})),
  C("Make it bigger", O("It looked like a billboard. They loved it.", {"job_perf": 2, "happiness": -2}), O("It looked terrible. They loved it anyway.", {"job_perf": 1, "happiness": -3})))
J("designer", 2, "🖌️", "A stolen idea",
  "Scrolling through a competitor's site, you stop dead: your layout, your palette, your odd little rounded-corner trick. It's a pixel-perfect match.",
  C("Send a polite note", O("They took it down and apologised. I felt dignified.", {"karma": 3, "job_perf": 3}), O("They ignored it. A lawyer would cost more than the job.", {"stress": 5})),
  C("Take it public", O("It trended. They were embarrassed. A few clients came to me out of sympathy.", {"job_perf": 4, "stress": 6, "fame": 1}), O("It trended against me. I looked petty.", {"stress": 8, "job_perf": -3})),
  C("Take it as a compliment", O("I did. It stung, and then it didn't.", {"happiness": 2, "stress": 2}), O("I was hurt for a long while, and then I made something better.", {"smarts": 1, "job_perf": 3, "stress": 3})))
J("journalist", 1, "📰", "The source who won't go on record",
  "A person in a position to know calls you at midnight with a story that could end a career. 'But I'll deny I said it,' they say.",
  C("Verify it independently", O("It took three weeks and two more sources. The story ran, and it was true.", {"job_perf": 9, "fame": 2, "stress": 6}), O("I couldn't confirm it. We killed the story. I felt the loss for months.", {"stress": 5, "smarts": 1})),
  C("Run it with the one source", O("It ran. It was true. It was luck, nothing more.", {"job_perf": 5, "karma": -2}), O("It was wrong. The retraction was humiliating.", {"job_perf": -8, "stress": 10})),
  C("Pass", O("Someone else ran it a week later. I watched with envy.", {"stress": 4, "job_perf": -2}), O("The story never came out. Sometimes that's the way.", {"stress": 2})))
J("journalist", 2, "🎙️", "The doorstep",
  "A tragedy has hit the town, and your editor wants a quote from the family of the victim. You stand at their door with a notebook that feels like a weapon.",
  C("Knock and be human", O("The mother let me in. We sat in the kitchen for two hours. I didn't use a word of it until she asked me to.", {"karma": 5, "job_perf": 6}), O("They shut the door, gently. I wrote about that instead.", {"karma": 3})),
  C("Leave a card", O("They called a week later. A quiet, dignified piece.", {"karma": 4, "job_perf": 4}), O("They never called. I ran the piece without them.", {"job_perf": -1})),
  C("Push for the quote", O("I got it. I hated myself for it.", {"job_perf": 5, "karma": -5, "stress": 5}), O("The father shouted at me. I deserved it.", {"karma": -3, "stress": 6})))
J("counselor", 1, "🛋️", "The silence",
  "A teenager sits in your office for the third session and says nothing. At minute forty-five he mutters, 'You'd just tell my mum.'",
  C("Explain confidentiality honestly", O("I laid out what I could and couldn't keep private. He thought about it, and began to talk.", {"karma": 4, "job_perf": 5}), O("He listened, nodded and left. He never came back.", {"stress": 4})),
  C("Promise to tell no one", O("He opened up. Then I learned something I couldn't keep to myself. I had to break it.", {"karma": -3, "stress": 9}), O("It worked. It also felt like a lie I'd have to pay for.", {"karma": -2, "stress": 5})),
  C("Sit quietly with him", O("We sat for another ten minutes. At the end he said, 'Same time next week?'", {"karma": 5, "happiness": 4}), O("The silence was just silence. But he came back.", {"karma": 2})))
J("counselor", 2, "💭", "A client in a good mood",
  "A long-term client announces that she is doing so well she'd like to stop. You are not sure, but she is certain.",
  C("Support the decision", O("A graduation of sorts. We marked it with a handshake. She wrote a year later: fine.", {"karma": 4, "happiness": 4}), O("She relapsed within a month. I felt I'd failed her.", {"karma": 2, "stress": 7})),
  C("Suggest a taper", O("We ended slowly. It worked.", {"job_perf": 4, "karma": 3}), O("She was cross. She came back anyway.", {"stress": 3})),
  C("Push to continue", O("She stayed. I kept her dependent, and I knew it.", {"karma": -4, "money": 40}), O("She left, offended. A fair reaction.", {"karma": -1, "stress": 3})))
J("lab_tech", 1, "🧫", "The contaminated plate",
  "Six weeks of cell culture ruined by a single fuzzy spot in the corner. The professor is coming for his Monday update.",
  C("Tell him straight", O("He grunted and said 'it happens'. He ordered a restart. I loved him a little for it.", {"karma": 3, "job_perf": 3}), O("He sighed, and lost his temper, then apologised. Awkward.", {"stress": 5})),
  C("Blame the incubator", O("He bought it. It was later found to be faulty, to my relief.", {"karma": -2, "stress": 3}), O("The facilities team checked the incubator and found nothing. I was caught.", {"karma": -4, "job_perf": -5, "stress": 6})),
  C("Quietly restart and hope", O("I caught up in four weeks. He never knew.", {"stress": 6, "health": -2}), O("He noticed the date mismatch. I explained, and it went fine.", {"stress": 4, "job_perf": -1})))
J("lab_tech", 2, "🧪", "An odd result",
  "A routine sample comes back showing something that shouldn't be there at all. Not a mistake, you think. Not a mistake.",
  C("Tell the lead scientist", O("She went very quiet and then very excited. It became a paper, and my name was in the acknowledgements.", {"job_perf": 7, "smarts": 2, "happiness": 4}), O("She dismissed it. A year later someone else published it.", {"stress": 5, "job_perf": -2})),
  C("Rerun the test", O("It repeated. The odd result was real.", {"smarts": 1, "job_perf": 4}), O("It didn't repeat. A relief, and a letdown.", {"stress": 2})),
  C("Bury the data", O("I will never know what that was.", {"stress": 4, "smarts": -1}), O("It haunted me every time I saw that sample number.", {"stress": 6})))
J("chef", 1, "👨‍🍳", "Inspection day",
  "An environmental health officer arrives unannounced at the lunch rush and starts opening fridge doors with a torch. In the third is last Tuesday's stock.",
  C("Own up and bin it", O("She noted it and moved on. We got a four-star rating. The staff cheered.", {"job_perf": 4, "karma": 2}), O("She wrote it up and we got a two. The owner was furious.", {"job_perf": -3, "stress": 7})),
  C("Distract her", O("A tour of the pastry section did it. Deeply unprofessional, deeply effective.", {"stress": 3, "karma": -2}), O("She saw right through me. A fine followed.", {"money": -300, "stress": 8, "karma": -2})),
  C("Blame the sous chef", O("She took the blame. We didn't speak after.", {"karma": -6, "stress": 4}), O("The sous chef quit. So did half the team.", {"karma": -6, "job_perf": -4})))
J("chef", 2, "🍽️", "The critic's table",
  "The waiter whispers: the woman at table six is writing the review that will make or break the season. Her fish has just come back with a request for 'a little less salt'.",
  C("Recook it with full attention", O("She cleaned the plate. Her review used the word 'precise'.", {"job_perf": 8, "happiness": 4}), O("She sent the second one back too. Four stars, 'a stumble'.", {"job_perf": 2, "stress": 5})),
  C("Send it back with a smile", O("She noticed the cheek and loved it.", {"job_perf": 5}), O("She found it condescending. The review stung.", {"job_perf": -3})),
  C("Take it personally", O("I stormed into the walk-in. I was fine. The fish was fine.", {"stress": 4}), O("I yelled at the commis. I regret it.", {"karma": -2, "stress": 5})))
J("music_teacher", 1, "🎻", "Recital night",
  "Your most talented student freezes on stage. Fifty parents hold their breath. Fourteen bars of nothing.",
  C("Walk on and sit beside her", O("I played the left hand, gently. She found her place. The room clapped for a long time.", {"karma": 5, "happiness": 5}), O("She cried, but she finished. I held her afterwards.", {"karma": 4, "happiness": 2})),
  C("Nod from the wings", O("She breathed, and started again. Perfect.", {"job_perf": 4}), O("She never played again. A hard one.", {"stress": 6, "karma": -1})),
  C("Let it play out", O("She found her way. It took a minute. She was stronger for it.", {"job_perf": 2}), O("She walked off. Her parents were furious with me.", {"stress": 6, "job_perf": -3})))
J("music_teacher", 2, "🎹", "The prodigy",
  "A new student, nine years old, sits down at the piano and plays a Bach prelude from memory, and then asks, 'Is that right?'",
  C("Teach her properly", O("She became my favourite student. I never felt prouder.", {"happiness": 5, "job_perf": 5}), O("She outgrew me in a year. I passed her to a conservatoire, proud and a little hollow.", {"happiness": 2, "karma": 3})),
  C("Refer her to someone better", O("A hard thing to do, and the right one.", {"karma": 4}), O("She never forgave her parents for moving her.", {"karma": 1})),
  C("Keep her to yourself", O("I held her back. I know it.", {"karma": -3}), O("She quit music at fifteen. I'll never know why.", {"karma": -3, "stress": 4})))
J("paralegal", 1, "📑", "The missing exhibit",
  "At 11 p.m. the night before the hearing, you notice exhibit F is missing from the bundle, and exhibit F is the whole case.",
  C("Call the partner", O("She cursed, laughed, and drove in. We rebuilt it by dawn.", {"job_perf": 6, "stress": 6}), O("She was furious. We found it in a different folder. I almost cried.", {"stress": 8, "job_perf": 0})),
  C("Search the archive alone", O("I found it at 3 a.m. under a coffee ring. I didn't tell anyone how close it was.", {"job_perf": 7, "stress": 6}), O("It was gone. I recreated it from emails and prayer.", {"job_perf": 3, "stress": 9})),
  C("Hope no one notices", O("The judge noticed. I was named in court.", {"job_perf": -8, "stress": 10}), O("No one did. I'll never be that lucky again.", {"stress": 4, "karma": -1})))
J("paralegal", 2, "⚖️", "A client in the corridor",
  "A man corners you in the corridor of the court and says, quietly, 'I didn't do it. Please tell them.' You're not supposed to talk to him at all.",
  C("Tell the barrister", O("He listened. It changed his cross-examination. The client was acquitted.", {"karma": 5, "job_perf": 7}), O("He said it was irrelevant. The client was convicted.", {"stress": 8, "karma": 1})),
  C("Say nothing", O("The case went as it went. I think about him sometimes.", {"stress": 4, "karma": -2}), O("He looked at me like I'd forgotten a promise.", {"stress": 6})),
  C("Tell him to speak to his lawyer", O("Correct, professional, and a little cold.", {"job_perf": 2}), O("He nodded, hollow-eyed, and did.", {"stress": 3})))
J("probation", 1, "📎", "A missed check-in",
  "A young man on your caseload hasn't turned up for two appointments. Breaching him is the rule. His mother has just called, in tears.",
  C("Visit him at home", O("He'd lost his job and was ashamed. We put a plan together. He kept every meeting after that.", {"karma": 6, "job_perf": 6}), O("He was drunk and angry. I stayed calm. It was a long hour.", {"stress": 7, "karma": 2})),
  C("File the breach", O("By the book. The court sent him back to prison. His mother never forgave me.", {"karma": -4, "stress": 6}), O("He was taken. A year later he told me it saved him.", {"karma": 2, "stress": 4})),
  C("Extend another chance", O("He took it, and didn't waste it.", {"karma": 5, "job_perf": 4}), O("He wasted it. My supervisor reminded me about the rules.", {"stress": 7, "job_perf": -3})))
J("probation", 2, "🔑", "The good news",
  "A woman you've supervised for three years walks in with a job offer letter, shaking, holding it out like it might break.",
  C("Celebrate with her", O("We both laughed, then cried a little. A day I'll remember.", {"happiness": 8, "karma": 4}), O("She went and told her kids. I closed the office and cried, privately.", {"happiness": 6, "karma": 3})),
  C("Remain professional", O("I shook her hand. She'd have liked more, but she understood.", {"happiness": 2}), O("I regretted it for a long while.", {"happiness": -1})),
  C("Check the employer is safe", O("A sensible step. It was a good place.", {"job_perf": 3, "karma": 2}), O("It wasn't. I got her out before she signed.", {"karma": 5, "job_perf": 5})))
J("civil_servant", 1, "🗂️", "Form 27-B",
  "A citizen has filled in Form 27-B, but the box that needs ticking only exists on Form 27-C. Both forms have been withdrawn.",
  C("Bend the rule and tick it", O("The citizen's problem went away. Mine began a week later in a staff meeting.", {"karma": 3, "stress": 4, "job_perf": -2}), O("It was a small kindness that slipped through. I'll never know if it mattered.", {"karma": 3, "happiness": 2})),
  C("Escalate to a supervisor", O("It took six weeks. The citizen wrote a thank-you note and I cried.", {"job_perf": 3, "stress": 3}), O("The supervisor found a loophole in an hour. I felt silly.", {"job_perf": 2, "stress": 1})),
  C("Send them away", O("A regrettable day. The queue grew.", {"karma": -3, "stress": 3}), O("The citizen wept. I felt it for a week.", {"karma": -4, "stress": 5})))
J("civil_servant", 2, "🏢", "The reorganisation",
  "A memo arrives announcing a 'transformation programme'. Your department will be 'streamlined' by Christmas. Nobody will say what that means.",
  C("Volunteer for the project team", O("I joined the team and shaped the plan. My job was safe, and it was the right call.", {"job_perf": 6, "stress": 5}), O("I became the face of the cuts. I was not liked.", {"stress": 8, "karma": -2})),
  C("Quietly look elsewhere", O("I found a better role at another department. I left on good terms.", {"stress": 2, "happiness": 3}), O("The market was dry. I stayed, uneasy.", {"stress": 6})),
  C("Wait and see", O("My role survived. Half my floor didn't.", {"stress": 6, "karma": -1}), O("I was moved to a job I hated.", {"stress": 8, "job_perf": -3})))
J("lawyer", 1, "👩‍⚖️", "The settlement offer",
  "The other side has offered a settlement. It's good, but not great. Your client wants to take it. You think you can win.",
  C("Advise acceptance", O("A safe, reasonable resolution. The client wept with relief.", {"job_perf": 5, "karma": 3}), O("I regretted it when I saw the verdict in a similar case, a month later.", {"job_perf": 1, "stress": 3})),
  C("Advise going to trial", O("We won, handsomely. The client was thrilled, and I felt invincible.", {"job_perf": 10, "money": 400, "stress": 8}), O("We lost. The client lost everything. I live with that.", {"job_perf": -8, "karma": -2, "stress": 12})),
  C("Let the client decide", O("They took the offer. It was their right. I stood by them.", {"karma": 3, "job_perf": 3}), O("They went to trial. It was their right. It went wrong.", {"stress": 8, "job_perf": -2})))
J("lawyer", 2, "🧾", "The inconvenient email",
  "While preparing disclosure, you find an email from your own client that could sink his case. The rules say it must be disclosed.",
  C("Disclose it", O("The client was furious, then relieved. Honesty won the judge, and the case.", {"karma": 6, "job_perf": 7}), O("We lost, and the client fired me. My name is clean.", {"karma": 6, "stress": 8, "job_perf": -3})),
  C("Tell the client to withdraw", O("He did. The matter settled quietly.", {"karma": 2, "stress": 4}), O("He refused, and I withdrew from the case.", {"stress": 6, "karma": 3})),
  C("Overlook it", O("It came out at trial. I was reported to the regulator.", {"karma": -8, "job_perf": -9, "stress": 12}), O("No one ever found it. I know it's there, in a box.", {"karma": -6, "stress": 6})))
J("doctor", 1, "🥼", "Bad news at 5 p.m.",
  "A test result has come back, and it's the kind you'd never wish on a person. The patient is in the waiting room, smiling at her phone.",
  C("Tell her in person, now", O("I sat down and said it plainly and kindly. She was quiet, then asked three good questions. I felt I'd done it right.", {"karma": 5, "job_perf": 6, "stress": 7}), O("She cried in the room and thanked me. It took a long time to go home.", {"karma": 4, "stress": 9})),
  C("Ask her to come back tomorrow", O("A restless night for both of us, but it gave me time to plan the conversation.", {"stress": 6, "job_perf": 2}), O("She read it online first. I'll never forgive myself.", {"stress": 10, "karma": -3})),
  C("Delegate to a colleague", O("It was handled kindly. It was not mine to handle, and I knew it.", {"stress": 4, "karma": -1}), O("My colleague did it badly. The patient complained.", {"stress": 6, "job_perf": -4})))
J("doctor", 2, "🚑", "The 3 a.m. page",
  "You've been awake for twenty-two hours when the page goes. A young man in the ER with a fever and a rash that you've only read about.",
  C("Order the full workup", O("It was meningitis, caught in time. He walked out a week later. I slept for a day.", {"job_perf": 9, "karma": 6, "stress": 6}), O("It was nothing; a rash from a new detergent. An expensive night, but safe.", {"job_perf": 2, "stress": 3})),
  C("Observe and wait", O("He got worse. We caught up, barely.", {"stress": 10, "job_perf": -3}), O("He got better. Judgment calls are the job.", {"stress": 3, "job_perf": 3})),
  C("Ask a colleague for a second look", O("She saw it in a second. I swallowed my pride.", {"job_perf": 3, "smarts": 1}), O("She was asleep. I woke her. She was gracious, and right.", {"job_perf": 3, "stress": 2})))
J("dentist", 1, "🦷", "The terrified patient",
  "A grown man has gripped the arms of the chair so hard his knuckles are white. He needs a root canal, and he has not had a check-up in fifteen years.",
  C("Talk him through every step", O("He relaxed gradually. Afterwards he said it was 'not that bad'. He booked a check-up.", {"karma": 3, "job_perf": 5}), O("He gasped at every sound. We finished. He wrote a nice review.", {"job_perf": 3, "stress": 3})),
  C("Offer sedation", O("A safe, sleepy hour. He was grateful, and chatty afterwards.", {"job_perf": 4}), O("It worked too well. He said some funny things about his mother.", {"happiness": 3})),
  C("Just do it quickly", O("It was fast. He vowed never to return.", {"job_perf": -2, "karma": -1}), O("He fainted. We laughed about it later.", {"stress": 4})))
J("dentist", 2, "😁", "The upsell",
  "The practice manager hands you a target: whitening packages, up 20% this quarter. A patient with perfectly good teeth sits waiting.",
  C("Recommend what she needs", O("I told her to save her money. She thanked me and referred three friends.", {"karma": 4, "job_perf": 3}), O("The manager frowned. The patient came back anyway.", {"karma": 3, "job_perf": -1})),
  C("Push the package", O("She bought it. It looked nice. I felt cheap.", {"money": 200, "karma": -4}), O("She sensed it. She didn't return.", {"karma": -3, "job_perf": -2})),
  C("Offer a cheap alternative", O("She agreed. A fair compromise.", {"karma": 1, "job_perf": 2}), O("She declined. We parted friends.", {"karma": 1})))
J("pharmacist", 1, "💊", "The prescription that looks wrong",
  "A dose on a prescription is ten times what it should be. The doctor's number goes to voicemail and the patient is shifting from foot to foot.",
  C("Refuse to dispense and keep trying the doctor", O("I reached her after twenty minutes. A misplaced decimal. She thanked me, and meant it.", {"karma": 6, "job_perf": 8}), O("The patient was furious about the wait. It didn't matter. It was right.", {"karma": 5, "stress": 5})),
  C("Dispense anyway", O("It was right. I'd misread it. I felt dumb.", {"stress": 5}), O("It wasn't right. A patient was hospitalised.", {"karma": -8, "stress": 12, "job_perf": -9})),
  C("Dispense a lower dose", O("It worked, and nobody was harmed. It was against the rules.", {"stress": 4, "karma": 0}), O("It didn't treat the illness. The patient returned in a worse state.", {"stress": 7, "job_perf": -3})))
J("pharmacist", 2, "🧴", "The regular who asks too much",
  "An older man asks about his tablets for the fourth time this month. You realise he isn't confused, he is lonely.",
  C("Make time for a chat", O("We talked about his garden. He bought a small thing for his cough, and left lighter.", {"karma": 4, "happiness": 4}), O("He kept me twenty minutes. The queue grew. He apologised and I said it was fine.", {"karma": 3, "stress": 3})),
  C("Answer briefly and move on", O("I answered. I didn't forget his face.", {"karma": 0}), O("He stopped coming. I wondered about that.", {"karma": -1, "stress": 3})),
  C("Suggest a community group", O("He joined a choir. He came in to tell me.", {"karma": 5, "happiness": 4}), O("He politely refused. I left it there.", {"karma": 1})))
J("vet", 1, "🐶", "The choice no one wants",
  "A family brings in a fourteen-year-old dog, failing fast. The cost of treatment is huge, the outlook poor. The children are in the corner, silent.",
  C("Be honest and gentle", O("We said goodbye together. The kids sat on the floor with her. I cried in the car.", {"karma": 6, "stress": 8}), O("They chose treatment. She had three more good months.", {"karma": 4, "happiness": 3})),
  C("Offer every option", O("They spent everything they had. It worked, for a while.", {"money": 400, "stress": 5}), O("It didn't work. They were bankrupted and bitter.", {"karma": -3, "stress": 7})),
  C("Recommend euthanasia", O("A gentle ending. They thanked me, quietly.", {"karma": 3, "stress": 6}), O("They went elsewhere. The dog died there a week later.", {"stress": 6, "karma": 0})))
J("vet", 2, "🐴", "Farm call at dawn",
  "A farmer rings at five: a mare in labour for three hours with no progress. The road is ice. You pull on your boots in the dark.",
  C("Go straight out", O("A breech foal. It took an hour. Both lived. The farmer made me tea and I could have wept.", {"karma": 6, "job_perf": 8}), O("The mare died. The foal lived. I had to hand-feed it for a week.", {"karma": 5, "stress": 9})),
  C("Give instructions over the phone", O("It sorted itself. A lucky pass.", {"stress": 3}), O("It went wrong. I should have gone.", {"karma": -3, "stress": 9, "job_perf": -5})),
  C("Send a colleague", O("She went and did well. I envied her for it.", {"stress": 2}), O("She was out of her depth. I drove out after.", {"stress": 5})))
J("executive", 1, "📈", "The board wants blood",
  "The quarter is bad, the board is restless, and the chair has suggested 'efficiencies'. A list of four hundred names is on your desk.",
  C("Cut the list in half and cut your own pay", O("The board grumbled. The staff noticed. Morale, remarkably, held.", {"karma": 6, "job_perf": 5, "money": -200}), O("It wasn't enough. The next quarter I cut the rest.", {"stress": 8, "karma": 1})),
  C("Sign the full list", O("Cold, quick, defensible. I couldn't look at the car park for a month.", {"karma": -6, "stress": 7, "money": 300}), O("A newspaper got hold of the list. I was the villain.", {"karma": -6, "stress": 10, "fame": 1})),
  C("Resist and find another way", O("I proposed a pay cut across the board. It was a bold move and it worked.", {"job_perf": 8, "karma": 5}), O("The board replaced me. I was out in a month.", {"stress": 10, "karma": 4}, fired=True)))
J("executive", 2, "🥂", "The offer from the rival",
  "A rival's CEO takes you to dinner. Across the tablecloth he slides a figure: 40% more, and a bigger title. 'You're wasted where you are.'",
  C("Accept", O("A new chapter. I took my best people with me and felt like a pirate.", {"money": 400, "job_perf": 4, "stress": 5}), O("The new firm was a mess. I'd made a mistake.", {"stress": 9, "happiness": -4})),
  C("Use it to renegotiate", O("My own board matched it in a day. A bit humiliating, a lot profitable.", {"money": 250, "job_perf": 3}), O("They called my bluff. I had to take it.", {"stress": 6})),
  C("Decline", O("Loyalty paid off. Within a year I was promoted.", {"karma": 3, "job_perf": 5}), O("A year later he was my boss. Awkward.", {"stress": 4})))
J("professor", 1, "🎓", "The peer review",
  "Reviewer Two has written a savage critique of your paper, which includes the line 'The authors appear unaware of the literature'. They are quoting a paper they have written.",
  C("Respond politely and thoroughly", O("The editor sided with me. The paper was published.", {"job_perf": 6, "smarts": 1}), O("It took a year. The paper came out, but I aged.", {"stress": 7, "job_perf": 3})),
  C("Rage-write a rebuttal", O("It felt wonderful. I deleted it before sending.", {"stress": -1}), O("I sent it. The editor remembered it for a decade.", {"job_perf": -5, "stress": 6})),
  C("Cite their paper", O("They became my biggest supporter. Academia is petty and generous.", {"job_perf": 5, "happiness": 3}), O("They didn't notice. I did.", {"stress": 2})))
J("professor", 2, "🧑‍🏫", "The student who wants a letter",
  "A student who has missed half your lectures asks for a letter of recommendation for a funded programme. 'I'm just more of an independent learner,' he says.",
  C("Decline honestly", O("He was shocked, and a little ashamed. He came to the next lecture.", {"karma": 3, "job_perf": 2}), O("He complained to the dean. The dean backed me.", {"stress": 4, "karma": 2})),
  C("Write a measured letter", O("He got in. He worked harder than he ever had.", {"karma": 3}), O("The programme wrote back asking questions. I was careful.", {"stress": 3})),
  C("Write a glowing letter", O("He got in, and wasted it.", {"karma": -4}), O("He got in, and called me from there. He'd changed.", {"karma": 2, "happiness": 3})))
J("scientist", 1, "🔭", "The result that breaks the model",
  "Your data contradicts the theory your whole group has spent a decade building. The professor wants a clean paper by spring.",
  C("Publish the real result", O("It was controversial, then confirmed. A career-defining moment.", {"job_perf": 10, "smarts": 2, "happiness": 5}), O("It cost me my funding and my mentor. I still believe it was right.", {"karma": 6, "stress": 9, "job_perf": -4})),
  C("Rerun everything", O("Same result. A restful certainty.", {"smarts": 2, "stress": 3}), O("A different result. I'd made a mistake; a relief and a shame.", {"stress": 2, "smarts": 1})),
  C("Quietly drop the outlier", O("The paper sailed through. I hated the paper.", {"karma": -8, "stress": 7}), O("A reviewer asked about the missing data. I was found out.", {"karma": -8, "job_perf": -10, "stress": 12})))
J("scientist", 2, "🌌", "Observation time",
  "A rare slot on the telescope opens: eight hours of sky, after a three-year wait. The weather forecast says clouds.",
  C("Go anyway", O("A clear patch opened at midnight. The data was gorgeous.", {"job_perf": 8, "happiness": 6}), O("Clouds all night. I stood outside and just looked up.", {"stress": 3, "happiness": 2})),
  C("Swap with a colleague", O("She got her data. I got a favour owed.", {"karma": 4}), O("Her night was clear. Mine would have been.", {"stress": 4})),
  C("Cancel", O("The next slot was a year away.", {"stress": 4, "job_perf": -2}), O("It rained. I was relieved.", {"stress": -2})))
J("army", 1, "🪖", "The forced march",
  "Thirty kilometres in full kit, in rain, on four hours' sleep. At kilometre twenty-two the soldier next to you says, quietly, 'I can't.'",
  C("Take half his pack", O("We both made it. He's been my friend ever since.", {"karma": 5, "health": -3, "job_perf": 5}), O("I hit the wall at twenty-eight. We crossed the line together, limping.", {"karma": 4, "health": -5, "stress": 4})),
  C("Encourage him to keep going", O("He gritted his teeth and finished. He thanked me, wordlessly.", {"karma": 3, "job_perf": 3}), O("He dropped out. He took it hard.", {"stress": 4})),
  C("Focus on your own pace", O("I finished well. He did not. I thought about it.", {"karma": -3, "job_perf": 3}), O("He was picked up by the truck. I was awarded something I didn't want.", {"karma": -3, "stress": 3})))
J("army", 2, "🎖️", "The order that feels wrong",
  "Your sergeant gives an order that violates the written rules of engagement, quietly and with confidence. Everyone else is already moving.",
  C("Refuse and say why", O("It cost me a promotion. A year later, an inquiry vindicated me.", {"karma": 8, "job_perf": -3, "stress": 8}), O("The sergeant yelled. The lieutenant changed the order.", {"karma": 6, "stress": 7})),
  C("Comply and report afterwards", O("I wrote the report. It went nowhere. I didn't forget.", {"karma": -2, "stress": 8}), O("Nothing happened. That's not the point.", {"karma": -3, "stress": 6})),
  C("Comply", O("I did what I was told. I live with it.", {"karma": -8, "stress": 10}), O("It was fine. I'll never know if that's lucky or terrible.", {"karma": -5, "stress": 7})))
J("navy", 1, "⚓", "Heavy weather",
  "Day nine of a storm at sea. The deck moves like a living thing. A rope has parted and a crate is sliding toward a sailor at the rail.",
  C("Lunge for the crate", O("I held it long enough for him to clear. I broke two ribs.", {"karma": 6, "health": -6, "job_perf": 6}), O("It missed him by a hair. I was told off for the risk.", {"karma": 3, "stress": 5})),
  C("Shout a warning", O("He ducked. The crate hit the rail and splintered.", {"job_perf": 3}), O("He didn't hear me.", {"stress": 8, "karma": -1})),
  C("Raise the alarm", O("A team arrived in thirty seconds. Everybody was fine.", {"job_perf": 4}), O("It took too long. Someone was injured.", {"stress": 8, "job_perf": -3})))
J("navy", 2, "🌊", "Shore leave",
  "Port at last, after seven weeks at sea. A free evening, the town's neon on the water, and a message from home that you haven't answered.",
  C("Call home", O("It was the best hour of the trip. They told me I sounded like myself.", {"happiness": 6, "stress": -4}), O("The call was bad news. I sat on the dock a long time.", {"stress": 7, "happiness": -3})),
  C("Go out with the crew", O("A loud, warm, brilliant night. I remember maybe half of it.", {"happiness": 6, "money": -80, "health": -1}), O("A fight started and I got involved. I spent the next day on report.", {"stress": 6, "job_perf": -4, "money": -60})),
  C("Sleep", O("Eleven hours. The best investment of the trip.", {"health": 3, "stress": -4}), O("I woke up with the world's worst crick in my neck.", {"health": -1})))
J("air_force", 1, "🛩️", "The pre-flight check",
  "A tech has signed off an aircraft, but a gauge you glance at on the walk-round isn't reading right. The brief is in ten minutes and the schedule is tight.",
  C("Ground the aircraft", O("It had a fault that would have killed someone. I got a quiet commendation.", {"karma": 6, "job_perf": 9}), O("It was a loose connection. The squadron lost an hour and I lost some patience.", {"job_perf": 1, "stress": 3})),
  C("Fly it, watching the gauge", O("It held. A very long flight.", {"stress": 8}), O("It failed in the air. I got down by the skin of my teeth.", {"stress": 12, "health": -2, "job_perf": -3})),
  C("Let the tech re-check", O("The tech found it. We both learned something.", {"job_perf": 4}), O("He was offended. It took a month to smooth over.", {"stress": 3})))
J("air_force", 2, "🧭", "The long deployment",
  "Eight months away. In the last video call, your kid held up a drawing and said, 'This is you,' and it was a stick figure on a screen.",
  C("Write every week", O("The letters became a book on the family shelf.", {"happiness": 4, "karma": 3}), O("The mail was slow, but it arrived. They kept every one.", {"happiness": 3})),
  C("Bury yourself in the work", O("Efficient, hollow, effective. I came home a stranger.", {"job_perf": 5, "happiness": -4}), O("I was promoted. My family wasn't impressed.", {"job_perf": 6, "stress": 5})),
  C("Ask about early leave", O("They approved it. I was home for the birthday.", {"happiness": 7}), O("They refused. I made peace with it.", {"stress": 4})))
J("pilot", 1, "👨‍✈️", "A warning light at cruise",
  "At thirty-eight thousand feet, an amber light blinks on. The co-pilot says 'sensor?' in the voice of a man hoping to be right.",
  C("Run the checklist", O("A faulty sensor, as we'd hoped. We landed on time. The passengers never knew.", {"job_perf": 5, "stress": 4}), O("A real fault, minor. We diverted. Everyone cheered when we touched down.", {"job_perf": 7, "stress": 8})),
  C("Ignore and monitor", O("It cleared. I felt an old man's relief.", {"stress": 4}), O("It didn't clear. I was lucky.", {"stress": 9, "job_perf": -4})),
  C("Declare an emergency", O("Fire trucks lined the runway. It was nothing. The airline was grateful I'd erred on the side of caution.", {"job_perf": 3, "stress": 6}), O("Fire trucks lined the runway. It was nothing. The airline was less grateful.", {"job_perf": -2, "stress": 6})))
J("pilot", 2, "🌫️", "Fog at the destination",
  "The destination is closed in fog, the alternate is an hour away, and fuel is adequate but not generous. The passengers don't know.",
  C("Divert early", O("The sensible, boring choice. We landed with a comfortable margin.", {"job_perf": 5}), O("The airline wasn't pleased. Safety isn't cheap.", {"stress": 4, "job_perf": 0})),
  C("Hold and wait for a gap", O("The fog lifted. We landed. I let out a breath I'd held for an hour.", {"job_perf": 6, "stress": 7}), O("It didn't lift. We had to divert with less fuel than I liked.", {"stress": 11, "job_perf": -2})),
  C("Attempt the approach", O("A low, beautiful, nerve-shredding landing. Passengers applauded.", {"job_perf": 8, "stress": 9}), O("Missed approach. A go-around. My heart took a week to settle.", {"stress": 12})))
save("jobs_c.json")

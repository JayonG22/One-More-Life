#!/usr/bin/env python3
"""Generates data/events/echoes.json: delayed follow-ups ("echoes") and wires them
into their source events with `schedule` on every outcome of the source.

Each echo is role-free (so it can follow any of its sources), has three choices
and every choice has at least two outcomes."""
import json, glob, os
ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
FU = []
WIRE = []   # (echo id, years, [source ids])

def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    return o

def C(label, *outs):
    assert len(outs) >= 2, label
    return {"label": label, "outcomes": list(outs)}

def F(id, icon, title, text, years, sources, *choices):
    assert len(choices) == 3, id
    FU.append({"id": id, "icon": icon, "title": title, "text": text, "conditions": {}, "choices": list(choices), "weight": 1, "followup_only": True})
    WIRE.append((id, years, sources))

# ------------------------------------------------------------ money
F("echo.windfall", "💸", "Where did it go?", "{~Looking back|Doing the accounts one evening|A friend asks, innocently}, you try to work out where that sudden money went. {~There is a pattern, and it isn't flattering.|It's both better and worse than you thought.}", [2, 5],
  ["adult.windfall", "adult.lucky_day", "money.hot_tip"],
  C("Go through it line by line", O("The honest accounting hurt for an evening. I came out of it a more careful person.", {"smarts": 2, "stress": 2, "money": 600}), O("I found a subscription I'd forgotten for three years. The ledger was a bruise.", {"smarts": 1, "stress": 3, "money": 400})),
  C("Decide it was worth it", O("Some money is for living. I raised a glass to the afternoon it bought me.", {"happiness": 5}), O("Telling myself it was worth it worked for a week.", {"happiness": 1, "stress": 2})),
  C("Resolve to save the next one", O("I opened a savings account the next morning and fed it a little every month.", {"money": 800, "stress": -3}), O("I resolved. Then the next windfall came and went the same way.", {"happiness": -1, "money": -300})))

F("echo.tip", "📉", "About that tip", "{~A newspaper article|A podcast|Your own bank statement} reminds you of the tip you {~took|passed on|half-listened to} {~a few|some} years ago.", [1, 4],
  ["money.invest_tip", "money.crypto_friend", "world.crypto_tip"],
  C("Check what it would have been", O("It would have been a lot. I looked at the number for a long minute and closed the tab.", {"happiness": -3, "stress": 2}), O("It would have been worth nothing. I felt briefly clever and then very lucky.", {"happiness": 3})),
  C("Message the person who gave it", O("We laughed about it. They'd lost money too, and had been too embarrassed to tell me.", {"happiness": 3, "karma": 1}), O("They'd moved on and didn't remember the tip at all.", {"happiness": -1})),
  C("Let it go", O("There's no use in the fortune you didn't make. I let it go like a train.", {"stress": -2}), O("I let it go, and it let go of me about a year later.", {"happiness": 1})))

F("echo.tenant", "🔑", "Your name in the building", "{~A former tenant|Someone in the building|A new tenant} mentions what they've heard about you as a landlord. {~It isn't what you expected.|It's been going round for a while.}", [2, 5],
  ["money.tenant_late", "money.tenant_damage", "money.great_tenant"],
  C("Listen and take it in", O("It was fairer than I'd feared, and more specific than I'd like. I changed one habit.", {"karma": 3, "stress": 2}), O("It was unfair, and partly true, which is the worst combination.", {"stress": 4, "happiness": -2})),
  C("Set the record straight", O("I wrote a note to the building. People remembered it kindly.", {"karma": 2, "happiness": 2}), O("Setting the record straight made it a bigger story than it had been.", {"stress": 3, "happiness": -2})),
  C("Make a gesture", O("I fixed the thing they'd complained about before they asked. It paid off over several years.", {"money": -400, "karma": 4}), O("The gesture was misread as guilt, and a little was taken advantage of.", {"money": -700, "stress": 2})))

F("echo.paperwork", "📄", "The envelope", "A brown envelope arrives. {~It's about the thing from a couple of years ago.|You'd forgotten all about it.|You open it with your thumb under the flap and your heart under your tongue.}", [1, 3],
  ["money.tax_audit", "money.bill_shock", "adult.scam_call"],
  C("Deal with it at once", O("It took an afternoon and a phone call. It was nothing, and I felt like an adult.", {"stress": -3, "smarts": 1}), O("It took an afternoon, and it was something. I paid it and felt slightly sick.", {"money": -500, "stress": 3})),
  C("Put it in the drawer", O("The drawer got fuller. In the end it never mattered.", {"stress": 2, "happiness": 1}), O("The drawer got fuller. In the end it very much mattered.", {"money": -900, "stress": 6})),
  C("Ask a friend to read it", O("They read it in twenty seconds and said 'ignore that one'. I could have kissed them.", {"stress": -4, "happiness": 3}), O("They read it and went quiet. Then they helped me fix it.", {"money": -300, "karma": 1, "stress": 2})))

F("echo.loan", "🤝", "The money question again", "{~It comes up at dinner|It's mentioned in passing|Someone asks, casually}: the loan, or the gift, from a while back. Everyone is suddenly very interested in their glass.", [2, 6],
  ["adult.money_friend", "family.parent_bills", "agency.money_help"],
  C("Bring it up yourself", O("I said it plainly. The air cleared and we both felt better.", {"karma": 3, "stress": -3}), O("Saying it plainly made it a Thing. We didn't speak for a month.", {"stress": 5, "happiness": -3})),
  C("Forgive it, in so many words", O("I said 'forget it'. They cried a little. It's the best money I've ever lost.", {"karma": 6, "happiness": 4, "money": -300}), O("I said 'forget it', and meant it for about a year.", {"karma": 3, "stress": 2})),
  C("Change the subject", O("I changed the subject and nobody noticed.", {"stress": 1}), O("I changed the subject and everybody noticed.", {"stress": 3, "happiness": -2})))

F("echo.party", "🎉", "The night people still mention", "{~Someone at a gathering|An old photo|A message out of nowhere} brings up that night. {~It's become a story.|They remember it better than you do.}", [2, 6],
  ["money.island_party", "money.appraisal", "money.lottery_friend"],
  C("Tell the story properly", O("I told it with the gestures. It's improved with the years, as these things do.", {"happiness": 5}), O("I told it and got a detail wrong. Someone corrected me, gently.", {"happiness": 2, "stress": 1})),
  C("Play it down", O("Modesty went over well. I was told I was 'refreshing'.", {"karma": 2, "happiness": 2}), O("Modesty didn't land. People thought I was hiding something.", {"stress": 3})),
  C("Plan another one", O("We did it again, smaller and better. It's now a tradition.", {"happiness": 7, "money": -400}), O("We tried to repeat it, and the magic stayed in the first one.", {"happiness": -1, "money": -600})))

# ------------------------------------------------------------ home
F("echo.neighbour", "🏘️", "Next door, a year on", "The {~noise|argument|barbecue} with the neighbour is ancient history now. {~Or it was, until this morning.|They've just knocked on the door.}", [1, 3],
  ["adult.noisy_neighbor", "adult.neighbor_feud", "adult.neighbor_bbq"],
  C("Answer warmly", O("They'd come about a parcel. We talked for twenty minutes on the step and it was lovely.", {"happiness": 4, "karma": 2}), O("They'd come to complain again. I answered warmly and it didn't help.", {"stress": 4})),
  C("Answer coolly", O("Coolly was enough. They went away and something resolved itself.", {"stress": 1}), O("Coolly started the feud again, with fresh enthusiasm.", {"stress": 6, "happiness": -3})),
  C("Don't answer", O("I let it ring. They left a note, which was kind.", {"stress": -1}), O("I let it ring. They left a note, which was not kind.", {"stress": 4, "happiness": -2})))

F("echo.repair", "🔧", "What the repair taught", "The {~boiler|wall|roof} is still fine. You catch yourself {~knowing exactly what to do when something small goes wrong|explaining it to a friend with startling authority}.", [1, 4],
  ["adult.home_repair", "real.damp_patch", "real.boiler_dead"],
  C("Share what you learned", O("A friend borrowed my know-how and saved a fortune. They sent a bottle.", {"karma": 3, "happiness": 3}), O("A friend ignored my advice and flooded their bathroom. I was kind about it.", {"karma": 1, "happiness": 1})),
  C("Take on a bigger project", O("I did the whole bathroom myself. It's slightly crooked and I adore it.", {"happiness": 6, "money": -300, "smarts": 1}), O("The bigger project ate a whole summer. Someone had to finish it for me.", {"money": -900, "stress": 4})),
  C("Pay for peace of mind", O("A service contract, a yearly check, and sleep. Priceless.", {"money": -250, "stress": -4}), O("The service contract turned out to cover nothing I needed.", {"money": -250, "stress": 2})))

F("echo.landlord", "✉️", "A letter from the landlord", "A letter from {~the agency|your landlord} arrives. {~It uses the word 'regarding'.|It's the third this year.}", [1, 3],
  ["real.rent_rise", "real.lease_renewal", "real.deposit_dispute"],
  C("Read it carefully", O("I read it twice. A small clause was in my favour and I used it.", {"money": 200, "smarts": 1}), O("I read it twice. It was exactly as bad as I thought.", {"stress": 4, "money": -300})),
  C("Ask a tenants' group", O("A group of tenants told me it was illegal. It stopped.", {"happiness": 4, "stress": -3}), O("The group said it was legal and annoying. I felt less alone.", {"stress": -1, "happiness": 1})),
  C("Think about moving", O("I looked at four places and found one that made me feel hopeful.", {"happiness": 3, "stress": 3}), O("I looked at four places and came home grateful for the one I had.", {"happiness": 2})))

F("echo.flatmate", "🧑‍🤝‍🧑", "Whatever happened to your flatmate", "{~A friend sends you a link|You see them across a street|A mutual friend tells you} about the person who shared your flat. {~Their life is nothing like you'd expect.|They are exactly who you thought they'd be.}", [2, 6],
  ["real.flatmate_rent", "real.flatmate_party", "adult.roommate"],
  C("Get in touch", O("We had a drink. The old arguments were funny from this distance.", {"happiness": 5, "karma": 1}), O("We had a drink. We agreed that some people are meant for one flat.", {"happiness": 1})),
  C("Wish them well from afar", O("I sent a thumbs-up and felt a clean, small kind of affection.", {"happiness": 2}), O("I wished them well and thought of the dishes.", {"happiness": 1})),
  C("Tell the story of the flat", O("The story of the flat got the loudest laugh of the dinner.", {"happiness": 4}), O("The story of the flat was funnier to me than to them.", {"happiness": 0})))

F("echo.carstory", "🚗", "The car story", "At {~a dinner|a wedding|a pub} you tell the story of {~the car|the crash|the breakdown}. {~It's improved with the telling.|It's got a punchline now.}", [3, 8],
  ["real.first_crash", "adult.flat_tire", "adult.car_trouble"],
  C("Tell it straight", O("Straight is funnier than I'd have thought. People laughed in the right places.", {"happiness": 5}), O("Straight was dull. I cut it short.", {"happiness": -1})),
  C("Embellish a little", O("A little became a lot, and the story acquired a goat.", {"happiness": 5, "karma": -1}), O("Someone who was there corrected the goat.", {"happiness": 2, "stress": 1})),
  C("Let someone else tell it", O("Someone else told it, wrongly and brilliantly.", {"happiness": 4}), O("Someone else told it and got my part completely wrong.", {"happiness": -1, "stress": 1})))

# ------------------------------------------------------------ work
F("echo.rival", "🥊", "Your old rival", "{~On a professional network|At a conference|In the queue for coffee}, you meet the person you once competed with. {~They look well.|They look, to your surprise, tired.}", [2, 6],
  ["wb.office_rival", "work.promotion_rival", "work.coworker_credit"],
  C("Congratulate them", O("It was the grown-up thing. They were visibly thrown, then touched.", {"karma": 4, "happiness": 3}), O("It was the grown-up thing. They were suspicious.", {"karma": 2, "stress": 1})),
  C("Be coolly polite", O("Polite, brief, civil. We'll never be friends and nothing else needs saying.", {"stress": 0}), O("Polite, brief, civil, and someone nearby clearly noticed it was loaded.", {"stress": 2})),
  C("Ask them for a favour", O("They did it, with an air of relief. Some rivalries are one favour from friendship.", {"karma": 2, "happiness": 4}), O("They refused, with an air of triumph.", {"stress": 4, "happiness": -3})))

F("echo.oldboss", "👔", "Your old boss", "Your old boss {~sends a message|appears at an event|is mentioned in the news}. {~You haven't thought of them in years.|Everything about them comes back at once.}", [3, 8],
  ["wb.micromanager", "wb.brilliant_boss", "work.weekend"],
  C("Reply warmly", O("They remembered one thing I'd done that I'd forgotten. It was a kindness I hadn't known they'd noticed.", {"happiness": 5, "karma": 2}), O("They wanted a favour. I did it, because I'm that kind of person.", {"stress": 2, "karma": 2})),
  C("Reply briefly", O("A short reply was enough. They never wrote again.", {"stress": -1}), O("A short reply was read as a snub, and that got around.", {"stress": 2})),
  C("Don't reply", O("I let it lie. It felt like cutting a thread.", {"happiness": 1}), O("I let it lie, and wondered for a long time what it was about.", {"stress": 2})))

F("echo.company", "🏢", "The company you left", "{~The company you used to work for|Your old employer} is in the news. {~It isn't going well.|It's being bought.|It's doing better than it ever did with you.}", [2, 5],
  ["adult.layoff_rumor", "wb.restructure", "work.layoffs"],
  C("Feel quietly relieved", O("I felt the relief of someone who left a sinking ship, and the guilt of one who left others on it.", {"happiness": 2, "karma": -1}), O("I felt relief. It was a small, mean pleasure and I enjoyed it.", {"happiness": 3, "karma": -2})),
  C("Reach out to former colleagues", O("Three of them were glad to hear from me. One needed a job.", {"karma": 4, "happiness": 3}), O("Nobody answered. They were all busy being scared.", {"happiness": -2})),
  C("Mention it nowhere", O("I decided it wasn't my business, and it wasn't.", {"stress": -1}), O("I decided it wasn't my business, and read about it every day for a week.", {"stress": 2})))

F("echo.mentor", "🎓", "What they told you", "{~A line|A piece of advice|A habit} you picked up from {~a mentor|someone senior} turns out to be the thing that gets you through today.", [3, 8],
  ["wb.mentor", "v08.work.mentor", "web.teacher_tutor"],
  C("Pass it on to someone junior", O("They looked at me as if I'd given them a map. I remembered exactly how that felt.", {"karma": 5, "happiness": 5}), O("They nodded politely and forgot it. Perhaps it takes ten years.", {"karma": 2, "happiness": 1})),
  C("Write to the mentor", O("They wrote back at once. They remembered me, which was the best part.", {"happiness": 6, "karma": 3}), O("The letter came back. They had moved, or worse.", {"happiness": -3, "stress": 2})),
  C("Keep it to yourself", O("It stayed a private advantage, and a quiet one.", {"job_perf": 2}), O("It stayed private, and I thought about that selfishness at night.", {"karma": -2, "stress": 2})))

F("echo.recruiter", "📞", "A second call", "{~The same recruiter|Another recruiter|An unexpected name on the screen} rings again, {~two years after the first time|with a different job and the same smile}.", [2, 5],
  ["wb.recruiter", "wb.job_hunt_low", "work.relocation"],
  C("Listen properly this time", O("The offer was better than the last. I negotiated, and it was easier than I remembered.", {"money": 4000, "happiness": 4}), O("The offer was the same, with a better title and a worse commute.", {"stress": 2})),
  C("Decline again", O("I declined again. The recruiter, for once, said 'good for you'.", {"happiness": 2}), O("I declined again, and a month later regretted it.", {"happiness": -3})),
  C("Pass it to a friend", O("A friend got the job and cried. It was the best thing I did all year.", {"karma": 6, "happiness": 6}), O("A friend got the job, and it didn't suit them. We still laugh about it.", {"karma": 2, "happiness": 1})))

F("echo.stagecareer", "🎭", "The part you turned down", "You hear that the {~role|record deal|contract} you passed on has gone to someone else. {~They're very good in it.|It did well.|It flopped, gloriously.}", [2, 6],
  ["actor.typecast", "music.writers_block", "music.label_contract"],
  C("Go and see it", O("They were good. I sat in the dark and clapped for someone else's version of my life.", {"happiness": 2, "karma": 2}), O("They were bad. I was ashamed of how pleased I was.", {"happiness": 3, "karma": -2})),
  C("Don't go", O("I stayed home and learned the lines of something else.", {"skill": 2}), O("I stayed home and thought about it all night.", {"stress": 3})),
  C("Write to them", O("They wrote back warmly. It turned into a long correspondence.", {"happiness": 4, "karma": 2}), O("They didn't reply, and I understood.", {"happiness": -1})))

F("echo.famecost", "📸", "What being known costs", "A stranger {~recognises you in a very private moment|knows something about you they shouldn't|says a thing that tells you how you look from outside}. {~You pretend not to mind.|It stays with you for days.}", [2, 6],
  ["fame.paparazzi", "fame.cancel", "fame.memoir"],
  C("Take a break from the public", O("A season in the country, a phone in a drawer. I returned a little more myself.", {"happiness": 6, "fame": -3, "stress": -6}), O("The break was read as a retreat, and the commentary was unkind.", {"fame": -2, "happiness": 2, "stress": -2})),
  C("Lean into it", O("I made it into a joke on my terms. They loved it.", {"fame": 4, "happiness": 3}), O("I tried to make it a joke. It wasn't, and I'd shown that.", {"fame": 1, "stress": 4})),
  C("Say nothing", O("Silence cooled it. The next story took over.", {"stress": -1}), O("Silence was read as guilt, and the story grew.", {"stress": 4, "fame": 1})))

F("echo.sportlegacy", "🏟️", "A young player asks", "A young player {~at a clinic|after a match|in the car park} asks you what it was like. {~They're nervous.|They've watched your tapes.}", [3, 9],
  ["sport.rival_player", "sport.trade", "sport.coach_offer"],
  C("Tell them the truth", O("I told them about the injuries and the loneliness and the joy. They listened like it was scripture.", {"karma": 5, "happiness": 5}), O("I told them the truth, and saw their face fall. I tried to rescue it.", {"karma": 2, "stress": 2})),
  C("Tell them the highlights", O("The highlights were exactly what they wanted. We both had a lovely afternoon.", {"happiness": 4, "fame": 1}), O("The highlights rang hollow, and they could tell.", {"happiness": -1})),
  C("Offer them a place to train", O("They trained with me for a year and went on to great things. They still send photos.", {"karma": 6, "happiness": 7}), O("They trained for a month and left. Not everyone sticks.", {"karma": 2, "happiness": 1})))

F("echo.politicalmemory", "🗳️", "The voter remembers", "At {~a fundraiser|a supermarket|a school event}, someone {~thanks|challenges|quotes} you on something you said {~at a debate|about a bill|about a donor}.", [2, 7],
  ["politics.debate", "politics.lobbyist", "politics.opponent_dirt"],
  C("Own what you said", O("Owning it won more respect than the original statement had.", {"approval": 5, "karma": 3}), O("Owning it cost me a donor and bought me a crowd.", {"approval": 2, "money": -4000})),
  C("Explain what you meant", O("I explained. They nodded slowly, and changed their mind.", {"approval": 4, "smarts": 1}), O("I explained. They filmed it. The clip was not generous.", {"approval": -4, "stress": 4})),
  C("Change the subject smoothly", O("I'm good at smoothly. They never noticed.", {"approval": 1}), O("I'm not as good at smoothly as I thought.", {"approval": -2, "stress": 2})))

F("echo.underworld", "🕶️", "A debt that isn't money", "A name from the old days {~turns up|calls|appears at a table}. They remember what you did, and what you didn't.", [2, 6],
  ["mafia.loyalty_test", "mafia.informant", "hustle.big_score"],
  C("Meet them, in public", O("A bright cafe, a long coffee. We talked around the point until it dissolved.", {"stress": 4, "respect": 3}), O("A bright cafe, and they weren't alone. I paid for everyone's coffee.", {"stress": 8, "money": -80})),
  C("Pay what you owe", O("I paid it and it wasn't about the money. They nodded and the matter was closed.", {"money": -3000, "stress": -4, "respect": 2}), O("I paid. It wasn't enough, and I learned how much would be.", {"money": -8000, "stress": 6})),
  C("Disappear for a while", O("I took a long trip and came back to a different set of problems. It worked.", {"stress": -2, "money": -1200}), O("I took a trip and they were waiting at the other end.", {"stress": 12, "heat": 4})))

F("echo.studio", "🎬", "The studio comes back", "{~The studio|A producer|Your agent} rings again, years after the last argument. {~They want something.|They sound almost humble.}", [2, 6],
  ["director.studio_notes", "director.diva", "model.brand_collab"],
  C("Take the meeting", O("The meeting was a revelation: they wanted me on my terms. I was smug for a week.", {"money": 20000, "skill": 2, "happiness": 4}), O("The meeting was the same argument in a better suit.", {"stress": 4})),
  C("Make them wait", O("I made them wait a month. They improved the offer by a third.", {"money": 14000, "happiness": 3}), O("I made them wait a month. They called someone else.", {"happiness": -3, "stress": 2})),
  C("Pass the opportunity to a friend", O("A friend got a break and never forgot it.", {"karma": 5, "happiness": 4}), O("A friend got a break and wasted it. I was surprised how much that stung.", {"karma": 1, "stress": 2})))

F("echo.spy", "🕵️", "A face from the service", "Someone you worked with {~appears in a crowd|sits down at your table|sends a postcard with no name}. {~You both know what you used to do.|Neither of you says a word at first.}", [3, 9],
  ["agent.honeytrap", "agent.mole", "agent.cover_blown"],
  C("Greet them as an old friend", O("We sat for an hour discussing nothing. It was the most intimate conversation I've had in years.", {"happiness": 5, "stress": -3}), O("We greeted each other as old friends. Someone watched us do it.", {"stress": 6})),
  C("Walk on", O("Walking on felt like leaving a coat in a cold room.", {"happiness": -2, "stress": -1}), O("Walking on, I noticed I was being followed, and was cheered by it.", {"stress": 3, "skill": 1})),
  C("Pass a message", O("I passed it. It was received. We never learned what it did.", {"skill": 2, "stress": 4}), O("I passed it, and it went to the wrong person.", {"stress": 8, "heat": 3})))

F("echo.space", "🚀", "Looking up", "On a clear night, {~you stand in a garden|you're on a roof|you walk home}, looking up at where you used to {~work|train|live}.", [3, 9],
  ["astro.spacewalk", "astro.anomaly", "astro.memoir"],
  C("Take someone with you to look", O("They looked up at a dot and I told them all of it. It was the best conversation of the month.", {"happiness": 6, "karma": 1}), O("They looked up, and then at their phone. I forgave them.", {"happiness": 1})),
  C("Stand alone and remember", O("The memories came in a quiet line. I was lucky, and I knew it.", {"happiness": 5, "stress": -3}), O("The memories came in a loud rush. I went indoors.", {"happiness": -1, "stress": 3})),
  C("Start planning your next trip", O("I booked something small and real. It cured the ache.", {"happiness": 4, "money": -600}), O("I planned a trip and never booked it. The plan was enough.", {"happiness": 2})))

# ------------------------------------------------------------ people
F("echo.sibling", "👫", "Brother, sister, years on", "Your {~brother|sister|sibling} {~calls out of the blue|appears on the doorstep|writes a long email}. {~You haven't spoken properly in a while.|It's about something small, which is how you know it isn't.}", [2, 7],
  ["fam.sibling_secret", "fam.sibling_rivalry", "teen.sibling_hoodie"],
  C("Make time, properly", O("We sat up all night in the kitchen. By morning we'd said everything.", {"happiness": 8, "stress": -4}), O("We sat up all night and said only half of it. It was a start.", {"happiness": 4})),
  C("Keep it short", O("Short was enough. We'll finish it at Christmas.", {"happiness": 1}), O("Short was too short. I felt it afterwards.", {"happiness": -3})),
  C("Bring up the old thing", O("I brought it up and we both laughed. It had been too small to hold for so long.", {"happiness": 7, "karma": 2}), O("I brought it up and we argued for an hour. We were better afterwards.", {"stress": 4, "happiness": 2})))

F("echo.parent", "👵", "The phone call", "Your {~mother|father|parent} rings, {~as they always do on a Sunday|at an odd hour|with nothing in particular to say}.", [2, 7],
  ["fam.parent_call", "fam.dad_advice", "life.parent_retire"],
  C("Stay on the line", O("An hour about nothing. I learned a story I'd never heard about their youth.", {"happiness": 6, "karma": 2}), O("An hour about nothing. They seemed lonelier than they sounded.", {"happiness": 2, "stress": 3})),
  C("Plan a visit", O("I went the next weekend. We fixed a gate and ate too much.", {"happiness": 7, "money": -120}), O("I planned a visit and cancelled it. They said they understood.", {"happiness": -3, "stress": 3})),
  C("Let it go to voicemail", O("It went to voicemail. The message was warm, and made me feel worse.", {"happiness": -2, "stress": 2}), O("It went to voicemail, and I called back that night. We talked for hours.", {"happiness": 5})))

F("echo.grownkid", "🧒", "The child is grown", "Your child {~says something that stops you|does something you didn't teach them|treats you, for a moment, like an equal}. {~You're startled by how much of you is in it.|You're startled by how little.}", [3, 9],
  ["fam.kid_trouble", "fam.kid_teen_mood", "family.kid_trouble"],
  C("Tell them you're proud", O("They said 'I know', then 'thanks'. I heard everything under it.", {"happiness": 8, "karma": 2}), O("They said 'Mum, stop.' They smiled anyway.", {"happiness": 5})),
  C("Ask for their advice", O("They gave me an answer I'd not thought of. The student had become a teacher.", {"happiness": 6, "smarts": 1}), O("They gave advice I didn't want to follow. I thought about it for a week.", {"happiness": 2, "stress": 1})),
  C("Say nothing and watch", O("Watching them was the best part. They're their own person.", {"happiness": 7}), O("Watching them, I wished I could say it. I never did.", {"happiness": 1, "stress": 1})))

F("echo.partner", "💞", "A conversation you've been avoiding", "{~Late at night|On a long drive|Over the washing-up}, the subject of {~what you each want|the big decision|the thing you never discuss} finally comes up.", [2, 6],
  ["fam.anniversary_forgot", "fam.partner_job", "love.jealous", "love.meet_cute", "love.ex_returns", "love.anniversary_trip"],
  C("Say what you actually think", O("It was frightening. It was also, by morning, a relief.", {"happiness": 6, "stress": -3}), O("It came out wrong, and we spent three days recovering.", {"stress": 6, "happiness": -3})),
  C("Listen first", O("Listening revealed that we'd been afraid of the same thing.", {"happiness": 7, "karma": 2}), O("Listening revealed a gap I hadn't known was there.", {"stress": 5, "happiness": -2})),
  C("Postpone it, kindly", O("We agreed to talk on Sunday. On Sunday it was easier.", {"happiness": 3, "stress": -1}), O("We agreed to talk on Sunday, then didn't. It sat between us.", {"stress": 4, "happiness": -2})))

F("echo.friends", "🥂", "The old crowd", "Someone {~organises|suggests|just starts} a get-together with the old crowd. {~Half of them will turn up.|It's been far too long.}", [1, 5],
  ["fam.friend_breakup", "adult.reunion", "life.class_reunion", "family.reunion"],
  C("Go, whatever it takes", O("It took a train and a babysitter. It was worth every penny.", {"happiness": 8, "money": -100}), O("It took a train and a babysitter, and the evening was awkward. I'm glad I went.", {"happiness": 3, "money": -100})),
  C("Go for an hour", O("An hour was enough to remember why we were friends.", {"happiness": 5}), O("An hour was the right length for how things are now.", {"happiness": 1})),
  C("Send a gift instead", O("The gift was passed round the table and I was toasted in absentia.", {"happiness": 3, "money": -60}), O("The gift arrived late and was a bit of an apology.", {"happiness": -1, "money": -60})))

F("echo.wedding", "💍", "Wedding photos", "Someone finds the {~wedding photos|album|video}. {~Everyone looks so young.|One of the guests isn't in the story any more.}", [3, 9],
  ["adult.wedding_guest", "adult.wedding_invite", "love.wedding_planning"],
  C("Look through them together", O("We laughed at the hair. Somebody cried at the speeches.", {"happiness": 7}), O("We looked through them, and a few missing faces made it quiet.", {"happiness": 2, "stress": 1})),
  C("Put them away", O("I put them away for another time. It's a kindness to the day.", {"happiness": 0}), O("I put them away, and thought of them for a week.", {"happiness": -2})),
  C("Send copies to the guests", O("Three people wrote back, moved. One had lost the original.", {"karma": 4, "happiness": 5}), O("Nobody replied, but I know they were opened.", {"karma": 2, "happiness": 1})))

F("echo.elders", "📖", "Their stories", "A story from {~a grandparent|an elder|a relative} comes back to you, {~word for word|in their voice|at an odd moment}. {~You realise you're the only one who still has it.|You wonder who else remembers.}", [3, 12],
  ["family.grandparent_stories", "elder.memoir", "fam.grandkid_visit"],
  C("Write it down", O("It filled four pages. I put them in the family box.", {"smarts": 1, "karma": 3, "happiness": 4}), O("It filled four pages and I lost them. I remember it, mostly.", {"karma": 1, "happiness": 1})),
  C("Tell it to a child", O("The child listened with their whole face. The story lives on.", {"happiness": 7, "karma": 3}), O("The child asked if there was a screen version. I laughed until I wept.", {"happiness": 4})),
  C("Keep it to yourself", O("It's mine, and I like having it.", {"happiness": 2}), O("It's mine. When I go, it goes. I think about that more than I admit.", {"happiness": -1, "stress": 1})))

F("echo.pet", "🐾", "The animal knows", "Your {~pet|animal|stray-turned-resident} does something that {~makes you laugh until you cry|makes your heart stop|tells you they've been listening all along}.", [1, 5],
  ["fam.pet_sick", "adult.adopt_stray", "pet.chewed", "pet.show", "v08.pet.vetbill"],
  C("Take a photograph", O("The photograph is on the fridge. It's the best thing in the flat.", {"happiness": 6}), O("The photograph is blurred. The memory is perfect.", {"happiness": 4})),
  C("Spoil them rotten", O("A new bed, a long walk, and a snack. They have regard for me now.", {"happiness": 5, "money": -60}), O("A new bed, ignored in favour of the box it came in.", {"happiness": 3, "money": -60})),
  C("Tell everyone", O("Everyone has a pet story. We traded them all evening.", {"happiness": 5, "karma": 1}), O("Nobody wanted another pet story. I kept going.", {"happiness": 2})))

# ------------------------------------------------------------ youth
F("echo.classmate", "🏫", "Whatever happened to them", "{~Out of nowhere|On a feed|At a funeral} you hear about someone from school. {~You haven't thought about them in years.|They were the one you'd never have guessed.}", [4, 15],
  ["child.new_kid", "kid.sleepover", "kid.bully", "kid.camp"],
  C("Look them up", O("Their life was a surprise, a good one. I smiled for the rest of the day.", {"happiness": 5}), O("Their life was a surprise, a hard one. I sat quietly.", {"happiness": -2, "karma": 1})),
  C("Get in touch", O("They replied in minutes. It was as if no time had passed.", {"happiness": 6, "karma": 1}), O("They replied in a week, politely. That was all.", {"happiness": 0})),
  C("Leave it in the past", O("Some things are better as a warm blur.", {"happiness": 1}), O("I left it, and thought about them on and off for a week.", {"happiness": -1})))

F("echo.gift", "🎨", "The thing you were good at", "You come across {~a drawing|a trophy|an old project} from {~childhood|school|years ago} that shows the thing you once were good at. {~It was never a career.|You'd forgotten how much you loved it.}", [5, 20],
  ["kid.talent", "kid.art_contest", "kid.science_fair"],
  C("Pick it back up", O("It was rusty. By the third evening it was a joy.", {"happiness": 7, "skill": 2}), O("It was rusty. I stopped after a week, with a bruised ego.", {"happiness": -1})),
  C("Teach it to a child", O("The child had a gift too. We spent a summer of evenings on it.", {"karma": 4, "happiness": 7}), O("The child was bored in ten minutes. I laughed.", {"happiness": 2})),
  C("Frame it", O("It hangs in the hall. People ask about it and I tell them.", {"happiness": 3}), O("It hangs in the hall, and the frame outshines it.", {"happiness": 1})))

F("echo.firstjob", "🧢", "Your first job, remembered", "{~The smell of a kitchen|A uniform in a shop window|A phrase from a customer} takes you back to your first job. {~You were so young.|You were so tired, and so proud.}", [5, 25],
  ["teen.job_first", "teen.part_time_boss", "teen.summer_job_offer"],
  C("Tell a young person about it", O("They listened, shocked at the wages. I felt about a hundred years old.", {"happiness": 4, "karma": 1}), O("They told me the minimum wage was a human right. They're right.", {"happiness": 2, "smarts": 1})),
  C("Go back and visit", O("It was still there, smaller. The manager remembered my name.", {"happiness": 6}), O("It was a phone shop now. I stood outside, grinning.", {"happiness": 2})),
  C("Tip generously, wherever you go", O("A habit for life: I tip generously and mean it.", {"karma": 4, "money": -50}), O("It was noticed, and returned in small ways.", {"karma": 3, "happiness": 3, "money": -50})))

F("echo.teensecret", "🔒", "The thing nobody knew", "Something from your teens — {~the party|the dare|what your parents found} — {~comes up in conversation|surfaces in a photo|is told by someone else}. {~You thought it was forgotten.|You'd made your peace with it.}", [3, 15],
  ["teen.caught", "teen.party", "teen.dare"],
  C("Laugh about it", O("Laughing was right. It was hilarious, from where I stand now.", {"happiness": 6}), O("Laughing was awkward. Not everyone found it funny.", {"stress": 2, "happiness": 1})),
  C("Tell it properly", O("I told the whole of it, including the part that wasn't flattering. People loved it.", {"happiness": 5, "karma": 2}), O("I told it. I'd forgotten an important detail and was corrected.", {"happiness": 1, "stress": 1})),
  C("Change the subject", O("A seamless change of subject. I've still got it.", {"stress": 0}), O("A clumsy change of subject. Everyone noticed.", {"stress": 3, "happiness": -1})))

F("echo.exam", "📝", "A test of a different kind", "Years after the exam, you find yourself {~in a situation where it would have helped|explaining something you learned for it|dreaming that you're sitting it again}.", [5, 20],
  ["teen.exam", "school.exam", "school.group_project"],
  C("Enrol in a course", O("A short evening course, and I was a student again. I loved it.", {"smarts": 3, "happiness": 5, "money": -400}), O("A short evening course, and I fell behind. It was a brave attempt.", {"smarts": 1, "stress": 3, "money": -400})),
  C("Teach someone else", O("Teaching was the best way to learn it again.", {"smarts": 2, "karma": 3}), O("Teaching revealed how much I'd forgotten.", {"smarts": 1, "stress": 2})),
  C("Just laugh at the dream", O("The dream faded in the morning, as dreams do.", {"stress": -1}), O("The dream came back the next night.", {"stress": 2})))

F("echo.college", "🎓", "The road not taken", "{~A university brochure|A colleague's stories|An old friend's photos} makes you wonder about the {~course|city|year abroad} you could have done.", [3, 15],
  ["teen.college_visit", "uni.study_abroad", "uni.roommate"],
  C("Take a course now", O("It was never too late. I'm now the oldest in the room and the happiest.", {"happiness": 7, "smarts": 2, "money": -800}), O("It was nearly too late. I got through it on stubbornness.", {"happiness": 2, "smarts": 1, "stress": 3, "money": -800})),
  C("Visit the place", O("A weekend there was enough to make peace with the choice.", {"happiness": 5, "money": -400}), O("A weekend there made me wonder even more.", {"happiness": -2, "money": -400})),
  C("Let the what-if sit", O("Every life has its rooms we don't enter. This one's mine.", {"happiness": 1}), O("The what-if sits with me still. I've learned to have tea with it.", {"happiness": 0})))

# ------------------------------------------------------------ health
F("echo.scare", "🩺", "A year on from the scare", "It has been a year since {~the tests|the symptoms|the worry}. You're {~fine|better|learning to live with it}, and the follow-up appointment is in the diary.", [1, 3],
  ["wb.gp_dismissed", "life.health_scare", "v07.health.symptoms_return"],
  C("Go, and ask every question", O("I asked everything. The doctor answered patiently. I left with a plan.", {"stress": -5, "health": 2}), O("I asked everything. The answers raised more questions, and I took them home.", {"stress": 2, "smarts": 1})),
  C("Go, but say little", O("I said little and heard little. It was fine, which is all I'd wanted.", {"stress": -2}), O("I said little. Something I didn't say turned out to matter.", {"health": -2, "stress": 3})),
  C("Cancel it", O("I cancelled, and my body forgave me.", {"stress": -1}), O("I cancelled, and my body didn't.", {"health": -3, "stress": 4})))

F("echo.habit", "🏃", "The habit that stuck", "{~Without noticing|One ordinary Tuesday|After a bad week}, you realise {~you've been exercising for months|the routine you started is simply part of you now|you hardly think about it}.", [1, 5],
  ["wb.fitness_wake", "adult.gym_membership", "adult.marathon"],
  C("Increase it, a little", O("A little more, and the results compounded in the way they do.", {"health": 3, "happiness": 4}), O("A little more, and a niggle in the knee. I eased off.", {"health": -1, "stress": 1})),
  C("Introduce a friend", O("My friend started with me. Two people keep each other going.", {"health": 2, "happiness": 5, "karma": 1}), O("My friend lasted three weeks. I carried on.", {"health": 1, "happiness": 2})),
  C("Reward yourself", O("A good dinner, with no guilt. I'd earned it.", {"happiness": 5, "money": -80}), O("A good dinner, then another. The habit felt a little less pure.", {"health": -1, "happiness": 3, "money": -120})))

F("echo.rest", "🌙", "What your body said", "{~After a bad stretch|In a quiet moment|At the end of a long week}, your body {~says plainly|insists|whispers} that you need to {~stop|slow down|sleep}.", [1, 4],
  ["wb.sleepless", "v07.mental.burnout", "wb.pill_fatigue"],
  C("Take a real break", O("A week of nothing. I came out of it a different person.", {"stress": -8, "health": 2, "happiness": 4}), O("A week of nothing, interrupted by emails. I learned I couldn't switch off.", {"stress": -2, "health": 0})),
  C("Ask for help", O("I said I was struggling. The relief of being believed was immense.", {"stress": -6, "karma": 2}), O("I said I was struggling. It was awkward, then it wasn't.", {"stress": -3, "happiness": 2})),
  C("Push on", O("I pushed on, and was fine. Until I wasn't.", {"stress": 4, "health": -2}), O("I pushed on and got away with it. That's the dangerous kind of luck.", {"stress": 2, "job_perf": 2})))

# ------------------------------------------------------------ community and the world
F("echo.goodturn", "🌱", "Someone remembers", "{~A stranger|Someone you barely know|A person in a shop} says, 'You're the one who...' and tells a story about a small thing you did. {~You'd completely forgotten it.|You remember it differently.}", [2, 9],
  ["adult.good_samaritan", "life.lost_kid", "life.random_kindness"],
  C("Say it was nothing", O("Modesty was the right note. They told me the story again, better.", {"karma": 3, "happiness": 5}), O("Modesty was taken at face value. They moved on.", {"karma": 1, "happiness": 2})),
  C("Ask them to tell you more", O("Their version had a hero in it. It was me. I was moved.", {"happiness": 7, "karma": 2}), O("Their version had a mistake. I corrected it, and regretted it.", {"happiness": 1})),
  C("Pay it forward that same day", O("I did something small for a stranger before bedtime. It felt like wearing a clean shirt.", {"karma": 5, "happiness": 4}), O("I tried to pay it forward and nobody wanted help. I felt faintly ridiculous.", {"karma": 1, "happiness": 1})))

F("echo.record", "⚖️", "The system remembers", "A letter, a form, or a polite phone call reminds you that the {~ticket|statement|court date} from before hasn't gone away.", [1, 5],
  ["law.speeding", "law.witness", "law.jury_bribe"],
  C("Sort it out in person", O("An hour in a queue and a signature. It was over, and I felt silly for dreading it.", {"stress": -4, "money": -80}), O("An hour in a queue, then a second one. The second was a surprise.", {"stress": 4, "money": -200})),
  C("Pay it online", O("A click, a receipt, a weight lifted.", {"stress": -3, "money": -150}), O("A click, and the website crashed. I didn't know if it had worked until a month later.", {"stress": 4, "money": -150})),
  C("Ask a lawyer first", O("The lawyer said 'don't worry', for a modest fee. I worried less.", {"stress": -3, "money": -200}), O("The lawyer found a complication. It cost more than the original.", {"stress": 3, "money": -600})))

F("echo.trip", "🧳", "The story of the trip", "Years later, the {~trip|journey|holiday} is still a family legend. {~Nobody remembers it the same way.|Everyone has a different favourite part.}", [3, 10],
  ["out.family_trip", "elder.cruise", "adult.lost_luggage"],
  C("Plan another one", O("We booked something for next summer. The legend deepens.", {"happiness": 7, "money": -900}), O("We planned another one and cancelled it. We still talk about the first.", {"happiness": 1})),
  C("Make a photo book", O("The book took a month. It sits on every coffee table we own.", {"happiness": 6, "money": -60}), O("The book took a month and had three typos. We love it anyway.", {"happiness": 5, "money": -60})),
  C("Just retell it", O("Retelling is half the pleasure of a trip.", {"happiness": 4}), O("Retelling it, I realised the details were slipping.", {"happiness": 0})))

F("echo.history", "🌍", "When the news was everything", "Years later, a {~documentary|anniversary|child's question} brings it back: the {~shortages|lockdown|war|crisis} you lived through. {~Younger people can't imagine it.|You find you can't quite explain it.}", [4, 15],
  ["world.war_rationing", "world.pandemic_lockdown", "world.housing_bid"],
  C("Tell it honestly", O("I told it without drama. They listened and asked quiet questions.", {"happiness": 4, "karma": 2}), O("I told it honestly, and it got to me a little.", {"happiness": 1, "stress": 3})),
  C("Tell the funny parts", O("There were funny parts, as there always are. We laughed until it hurt.", {"happiness": 6}), O("I told the funny parts, and then the others came.", {"happiness": 2, "stress": 2})),
  C("Let them find their own", O("They'll learn it from the world, as we did.", {"happiness": 0}), O("They did, and called me to say so.", {"happiness": 3, "karma": 1})))

# ------------------------------------------------------------ write and wire
json.dump(FU, open(os.path.join(ROOT, 'data/events/echoes.json'), 'w'), indent=1, ensure_ascii=False)
open(os.path.join(ROOT, 'data/events/echoes.json'), 'a').write('\n')

by_id = {}
files = {}
for f in glob.glob(os.path.join(ROOT, 'data/events/*.json')):
    if f.endswith('echoes.json'): continue
    data = json.load(open(f)); files[f] = data
    for e in data: by_id[e['id']] = e
wired = 0; missing = []
for eid, years, sources in WIRE:
    for s in sources:
        e = by_id.get(s)
        if not e: missing.append(s); continue
        for c in e.get('choices', []):
            for o in c['outcomes']:
                if 'schedule' not in o and 'play' not in o:
                    o['schedule'] = {'event': eid, 'years': years}
        wired += 1
for f, d in files.items():
    json.dump(d, open(f, 'w'), indent=1, ensure_ascii=False); open(f, 'a').write('\n')
print(len(FU), 'echo events;', wired, 'sources wired; missing:', missing)

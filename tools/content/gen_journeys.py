#!/usr/bin/env python3
"""Generates data/events/journeys.json — events where distance matters (v1.4).
A choice with `travel` ("near" | "far" | "trip") has its good outcomes made likelier or
unlikelier by how the player can actually get there (Transit.reach): on foot a far
journey rarely works out; a bike helps; a train or a car does the job. The decision
screen says so. Outcomes marked good:true/false are the ones the multiplier moves."""
import json, os
EV = []
def O(text, fx=None, good=None, **extra):
    o = {"text": text, "weight": 1, "effects": fx or {}}
    if good is not None: o["good"] = good
    o.update(extra)
    return o
def C(label, outs, travel=None):
    assert len(outs) >= 2
    c = {"label": label, "outcomes": outs}
    if travel: c["travel"] = travel
    return c
def E(id, icon, title, text, cond, *choices, cooldown=12, once=False):
    assert len(choices) >= 3
    c = {"age": [14, 90]}; c.update(cond)
    d = {"id": "jn." + id, "icon": icon, "title": title, "text": text, "conditions": c, "choices": list(choices), "weight": 1.0, "cooldown": cooldown}
    if once: d["once"] = True
    EV.append(d)

E("concert", "🎤", "The concert",
  "The band you have loved since school are playing, but the venue is on the other side of the region. Tickets are still on sale.",
  {"age": [15, 55]},
  C("Go, whatever it takes", [
      O("I got there with minutes to spare, pushed to the front and sang every word. I will remember it when I am old.", {"happiness": 14, "stress": -6}, True),
      O("I missed the first half and arrived hoarse, sweaty and furious, and caught the last three songs.", {"happiness": 3, "stress": 6, "money": -60}, False),
      O("I never made it. I stood on a platform at eleven at night looking at a departure board that had no more trains on it.", {"happiness": -8, "stress": 8, "money": -60}, False)], "far"),
  C("Go with friends and share a lift", [
      O("Four of us in one car, the radio loud. It was half the night, and the best half.", {"happiness": 12, "money": -40}, True),
      O("The car overheated an hour out. We watched the encore on someone's phone in a lay-by.", {"happiness": 2, "money": -40}, False)], "far"),
  C("Skip it and watch the stream", [
      O("The stream was fine. It was not the same, but I was in bed by eleven.", {"happiness": 2}),
      O("The stream kept buffering. I gave up and read a book.", {"happiness": -2})]))

E("interview_far", "💼", "The interview in another city",
  "A company two hours away has asked you to interview in person, tomorrow at nine. It is the job you have been waiting for.",
  {"age": [18, 60]},
  C("Get there early", [
      O("I arrived with time to find the building and breathe. They could see I had prepared. They made an offer on the spot.", {"happiness": 12, "stress": -4}, True),
      O("I arrived on time and tired. It went decently. They said they would be in touch.", {"happiness": 2, "stress": 4}, None),
      O("The journey went wrong and I arrived flustered. It showed.", {"happiness": -6, "stress": 8}, False)], "far"),
  C("Ask for a video call instead", [
      O("They agreed. It went fine, and they said so. A video call is a video call, though.", {"happiness": 3}),
      O("They said in-person mattered for this role. I lost the day, and the post.", {"happiness": -6, "stress": 4})]),
  C("Decline", [
      O("I stayed in my job. I thought about it on the train I was not on.", {"happiness": -3}),
      O("I turned it down. A year later someone I know got the role.", {"happiness": -4})]))

E("sick_relative", "🏥", "She is in hospital",
  "A relative who raised you has been taken to hospital in her home town, six hours away. The nurse says she is asking for you.",
  {"age": [18, 90]},
  C("Go now", [
      O("I got there before visiting hours ended. She held my hand and said my name. I did not leave until she slept.", {"happiness": 6, "stress": 4, "karma": 6}, True),
      O("I got there too late for the conversation. I sat by the bed while she slept, and that was all, and that was something.", {"happiness": -4, "stress": 6, "karma": 3}, False),
      O("By the time I arrived she had gone. I stood in a corridor with a plastic bag of her things.", {"happiness": -14, "stress": 10}, False)], "trip"),
  C("Go at the weekend", [
      O("She was still there at the weekend, better, embarrassed to have caused a fuss. We laughed.", {"happiness": 5, "karma": 3}, True),
      O("The weekend was too late.", {"happiness": -12, "stress": 8}, False)], "trip"),
  C("Phone, and send flowers", [
      O("She said she understood. I did not believe that she did.", {"happiness": -4, "karma": -2}),
      O("The call went to voicemail. The flowers got there. I did not.", {"happiness": -5, "karma": -3})]), cooldown=20)

E("wedding_away", "💒", "A wedding far away",
  "An old friend is getting married in a town you would have to cross the country to reach. Your name is on the list.",
  {"age": [18, 80]},
  C("Make the journey", [
      O("I danced until the shoes came off. The speeches made me cry. It was worth every mile.", {"happiness": 12, "stress": -4, "money": -140}, True),
      O("I got in just as the cake was cut, grey with travel, and was hugged anyway.", {"happiness": 5, "stress": 5, "money": -140}, False),
      O("I missed it. The train was cancelled, then the replacement bus. I watched the photographs the next morning.", {"happiness": -7, "stress": 6, "money": -80}, False)], "trip"),
  C("Send a generous gift", [
      O("They sent a thank-you card with a lovely photograph. I framed it.", {"happiness": 2, "money": -100}),
      O("The gift arrived. The card said they missed me. I felt it.", {"happiness": 0, "money": -100})]),
  C("Send apologies", [
      O("They understood. We would catch up later, we said, as one does.", {"happiness": -2}),
      O("It was the sort of thing that is forgotten. Mostly.", {"happiness": -3})]))

E("market_run", "🛒", "The farmers' market",
  "There is a large market across town this weekend: good food, odd furniture, and a stall that sells the one thing you have been looking for.",
  {"age": [14, 85]},
  C("Make a day of it", [
      O("I filled a bag with bargains and stopped for a coffee I did not need. It was the best Saturday I had had in months.", {"happiness": 8, "stress": -4, "money": -40}, True),
      O("By the time I got there the best stalls were packing up. I came home with half a bag and a sunburn.", {"happiness": 1, "money": -20}, False)], "far"),
  C("Send a friend with a list", [
      O("They came back with most of it and some things I had not asked for. Fair enough.", {"happiness": 3, "money": -30}),
      O("They forgot half. The other half was the wrong brand.", {"happiness": -1, "money": -30})]),
  C("Order it online", [
      O("It came on Tuesday. It was fine.", {"happiness": 1, "money": -45}),
      O("It came on Thursday, dented.", {"happiness": -2, "money": -45})]))

E("college_open", "🎓", "Open day",
  "A university you have been thinking about is holding an open day on the far side of the county. There are talks, a tour and a chance to ask the questions you have not dared to ask.",
  {"age": [15, 24]},
  C("Go and see for yourself", [
      O("I walked the campus, asked a lecturer a clumsy question and left knowing something I could not have known at home.", {"happiness": 8, "smarts": 2}, True),
      O("I got there for the last tour. It was enough to give me a feeling.", {"happiness": 3, "smarts": 1}, False),
      O("I never made it. The last bus had left before I had worked out where to catch it.", {"happiness": -6, "stress": 4}, False)], "far"),
  C("Go with a parent who has a car", [
      O("It was the only time we talked properly all year. I picked up a prospectus and a plan.", {"happiness": 8, "smarts": 2}, True),
      O("We got lost twice and argued about it. We arrived late, but we arrived.", {"happiness": 3}, False)], "far"),
  C("Read the website", [
      O("The website was glossy and told me nothing.", {"happiness": -1}),
      O("The website was good. I made a list of questions I would never ask.", {"happiness": 1})]), once=True)

E("emergency_ride", "🚨", "A call at night",
  "A close friend rings at midnight from the other side of the city. They have been stranded, shaken and can't say why. They ask whether you can come.",
  {"age": [16, 80]},
  C("Go and get them", [
      O("I got there in time. They did not say much, but I did not need them to. We sat in the car until dawn.", {"happiness": 6, "stress": 3, "karma": 8}, True),
      O("I arrived an hour later than I wanted. They had found their own way. They hugged me anyway.", {"happiness": 3, "stress": 4, "karma": 3}, False),
      O("There were no buses and no taxis. I set off on foot, and by the time I got there they had left. I will always wonder.", {"happiness": -7, "stress": 8, "karma": -1}, False)], "far"),
  C("Talk them through it on the phone", [
      O("Two hours on the phone. They made it home. It was enough.", {"happiness": 3, "stress": 4, "karma": 4}),
      O("The line dropped three times. I never knew if they were safe until the morning.", {"happiness": -4, "stress": 7})]),
  C("Call someone nearer to them", [
      O("A mutual friend lived round the corner. They were there in ten minutes. I felt relieved and useless.", {"happiness": 1, "stress": 3, "karma": 3}),
      O("Nobody picked up. I had put the problem in a queue.", {"happiness": -3, "stress": 5})]))

E("rescue_far", "🐕", "The lost dog report",
  "A friend has posted that their dog has been found, tired and muddy, at a farm twenty miles away. The farmer will hold it until tonight.",
  {"age": [14, 80]},
  C("Fetch the dog", [
      O("I collected a filthy, delighted dog and drove it home to its people. I was a hero for a week.", {"happiness": 10, "karma": 8}, True),
      O("I got there as the farmer was shutting up. He handed it over, grumbling. We made it home at midnight.", {"happiness": 5, "karma": 5}, False),
      O("I never got there. By the time I had found a way, the farmer's phone was off. The dog was fine, in the end, but not because of me.", {"happiness": -5, "karma": -1}, False)], "far"),
  C("Send a message offering a lift to someone else", [
      O("A neighbour went. The dog was home before supper.", {"happiness": 3, "karma": 3}),
      O("It took them a day to organise. The dog was fine and so was the farmer.", {"happiness": 1})]),
  C("Leave it to the owners", [
      O("They sorted it out. I did not hear about it until later.", {"happiness": 0}),
      O("They got it back. Without me. I was not needed.", {"happiness": -1})]))

E("reunion", "🎉", "The reunion",
  "Twenty years since school, and a message from someone you had half forgotten says the reunion is at the old place, a long way from where you live now.",
  {"age": [32, 70]},
  C("Go", [
      O("People I thought I had outgrown turned out to be good company. One of them offered me a job lead I could not have found at home.", {"happiness": 10, "money": -90}, True),
      O("I arrived as the last speech was ending. I found the three people who had stayed behind for me.", {"happiness": 4, "money": -90}, False),
      O("I never got there. The journey fell apart, and I told myself it was for the best.", {"happiness": -4, "money": -50}, False)], "trip"),
  C("Send a message and a photo", [
      O("They all replied. It was sweeter than I had thought.", {"happiness": 2}),
      O("A few people said they would catch up. We did not.", {"happiness": -1})]),
  C("Ignore it", [
      O("I ignored it. I wonder who went.", {"happiness": -1}),
      O("I forgot it by the evening.", {"happiness": 0})]), once=True)

E("flat_viewing", "🏠", "A flat in another town",
  "There is a flat for rent in a town forty minutes away, cheap, bright and snapping up applications. The agent says viewings are today only.",
  {"age": [18, 50]},
  C("Go and view it", [
      O("I walked in, loved it and put down the deposit that afternoon. It changed my life.", {"happiness": 10, "stress": -3, "money": -300}, True),
      O("By the time I arrived, it had gone. I saw the SOLD sign for a month.", {"happiness": -4, "stress": 4}, False)], "far"),
  C("Ask someone to view it for you", [
      O("A friend went. They said it was fine. It was fine.", {"happiness": 2}),
      O("They took photographs. It looked smaller in real life.", {"happiness": -1})]),
  C("Keep looking nearer", [
      O("The nearer flats were more expensive and less bright. I took one anyway.", {"happiness": 1, "money": -80}),
      O("It took months. I found something decent in the end.", {"happiness": 2})]), cooldown=15)

E("festival", "🎪", "The festival",
  "A festival of music, food and tents is happening in a field a long way out of town, and half your friends are going.",
  {"age": [16, 45]},
  C("Go", [
      O("Three days of mud and sunsets and strangers sharing sausages. I came back a different shape.", {"happiness": 14, "stress": -8, "money": -150}, True),
      O("I got there late, carried a tent for three miles and slept badly. I enjoyed all of it, eventually.", {"happiness": 5, "stress": 3, "money": -150}, False),
      O("I never found the right field. I spent two days in a town twenty miles away and came home early.", {"happiness": -6, "stress": 5, "money": -100}, False)], "trip"),
  C("Go for a day", [
      O("A single bright day, an excellent band and a lift home. Perfect.", {"happiness": 8, "money": -60}, True),
      O("The day ticket was sold out by the time I arrived.", {"happiness": -3, "money": -20}, False)], "far"),
  C("Stay home", [
      O("I watched their photographs and felt fine about it.", {"happiness": 0}),
      O("I had a quiet weekend. It was exactly what I needed.", {"happiness": 2, "stress": -3})]))

E("funeral_far", "⚰️", "A funeral abroad",
  "Someone close to the family has died, and the funeral is a long journey away. There will be the whole extended family and a lot of things that have not been said.",
  {"age": [18, 90]},
  C("Go", [
      O("I stood with the family. Strangers told me stories I had never heard. I came home with a lighter and heavier heart.", {"happiness": -2, "stress": 4, "karma": 6}, True),
      O("I got there for the burial, only just, and wept in a car park.", {"happiness": -6, "stress": 7, "karma": 3}, False),
      O("I did not make it. I watched it over a bad connection, alone in my kitchen.", {"happiness": -10, "stress": 8, "karma": -2}, False)], "trip"),
  C("Send flowers and a letter", [
      O("Someone read my letter aloud. I was told it helped.", {"happiness": -3, "karma": 1}),
      O("They were kind about it. I still wish I had gone.", {"happiness": -5})]),
  C("Hold a small service at home", [
      O("A candle, a photograph, and two friends who knew them. It was right.", {"happiness": -1, "karma": 3}),
      O("I held a quiet moment on my own, and then I made tea.", {"happiness": -2})]), cooldown=25)

out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "journeys.json")
json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
print("journeys.json: %d events" % len(EV))

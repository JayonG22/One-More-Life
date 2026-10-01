#!/usr/bin/env python3
"""School, dating and gift events (v0.25)."""
from dsl import *
def S(id, icon, title, text, cond, *ch, **kw):
    c = {"in_school": True}; c.update(cond)
    E(id, icon, title, text, c, *ch, prefix="sch.", **kw)
def D(id, icon, title, text, cond, *ch, **kw):
    c = {"age": [16, 75]}; c.update(cond)
    E(id, icon, title, text, c, *ch, prefix="date.", **kw)
def G(id, icon, title, text, cond, *ch, **kw):
    E(id, icon, title, text, cond, *ch, prefix="gift.", **kw)
FR = {"f": {"new": "friend", "age": "same"}}
CRUSH = {"c": {"new": "friend", "age": "same", "closeness": 25}}

# ------------------------------------------------------------------ SCHOOL
S("lunch_table", "🍱", "The lunch table", "It's the third week at the new school and you're standing with a tray, scanning the room. Every table looks like a country with its own border.", {"age": [6, 17]},
  C("Sit with the kids who look lost", O("There were three of them, and by Friday we were a country of our own. One became a friend for life.", {"happiness": 5, "karma": 2}), O("It was quiet and awkward, but nobody was mean. I kept going back.", {"happiness": 2})),
  C("Try the popular table", O("They let me stay. It felt like winning something and losing something.", {"happiness": 3, "looks": 1, "karma": -1}), O("They looked up, then looked at each other, then back at me. I found a different seat.", {"happiness": -4, "stress": 4})),
  C("Eat in the library", O("I read my way through half a shelf. Not a bad plan.", {"smarts": 2, "happiness": -1}), O("The librarian caught me and gave me a stack of books. It saved my year.", {"smarts": 2, "happiness": 2})))
S("bully", "👊", "The corridor", "A bigger kid has started waiting by your locker. Today he doesn't say anything. He just holds out his hand, palm up.", {"age": [8, 17]},
  C("Walk away", O("It cost me nothing today. It cost me something tomorrow.", {"stress": 5, "happiness": -3}), O("He let me go. Then he found someone else. I felt it.", {"stress": 4, "karma": -1})),
  C("Tell a teacher", O("It was handled. He was suspended. He never forgave me, but he left me alone.", {"stress": 3, "karma": 1, "happiness": 2}), O("They told me to 'work it out'. I felt abandoned.", {"stress": 7, "happiness": -4})),
  C("Stand your ground", O("He backed down, shocked. It was the biggest thing I'd ever done.", {"happiness": 6, "health": -1, "karma": 0}), O("He hit me. I hit back. We both got detention, and a strange respect.", {"health": -4, "stress": 5, "happiness": 2})))
S("cheating", "📝", "Eyes on the paper", "The kid beside you has left his answers completely uncovered, and you've blanked on question six. Time ticks down.", {"age": [10, 25]},
  C("Copy one answer", O("I got it right and felt sick all afternoon.", {"school": 2, "karma": -3, "stress": 4}), O("The teacher saw. She said nothing, but wrote something on her clipboard.", {"school": -3, "karma": -3, "stress": 6})),
  C("Leave it blank", O("I got zero for that one. I slept fine.", {"school": -1, "karma": 2}), O("I left it blank, and then I remembered the answer at lunchtime. Typical.", {"stress": 2})),
  C("Guess", O("A lucky guess. I felt like a gambler who'd won.", {"school": 1, "happiness": 2}), O("An unlucky guess. At least it was honest.", {"school": -1})))
S("science_fair", "🧪", "The science fair", "Your volcano has to be ready by Thursday. You have a bottle, a box of baking soda, and a rumour that someone else is building a rocket.", {"age": [8, 15]},
  C("Build something ambitious", O("It erupted gloriously, to a gasp from the judges. First place.", {"smarts": 3, "happiness": 6, "school": 3}), O("It exploded early, painting the gym ceiling. A legend of a failure.", {"happiness": 3, "school": -1, "karma": -1})),
  C("Do the simple volcano", O("Neat, tidy, and unremarkable. A ribbon for participation.", {"happiness": 1, "school": 1}), O("Four other kids did the same. We got to compare.", {"happiness": 1})),
  C("Skip it", O("I took a 'sick day'. It was fine until my mother found out.", {"happiness": -1, "school": -2}), O("The teacher gave me a make-up project. It was harder.", {"school": -1, "stress": 3})))
S("crush", "💘", "Note passed in class", "A folded square of paper lands on your desk. It's from the person you've been thinking about for weeks. Inside is one line: 'Do you like me?'", {"age": [11, 17]},
  C("Write 'yes'", O("We've been inseparable since. It's the kind of thing you remember for fifty years.", {"happiness": 8}), O("They showed it to their friends. I wanted to disappear.", {"happiness": -6, "stress": 5})),
  C("Write 'maybe'", O("They laughed. It became a thing. We became a thing.", {"happiness": 4}), O("They lost interest. I never knew.", {"happiness": -2})),
  C("Ignore it", O("I regretted it for a while.", {"happiness": -3}), O("It was probably a joke anyway. Probably.", {"happiness": 0})))
S("detention", "⏰", "Detention", "You've been given detention for something that was, frankly, partly your fault. You sit in the classroom with a clock that ticks like a metronome.", {"age": [9, 17]},
  C("Do your homework", O("An hour of silence and I finished everything. A productive punishment.", {"school": 3, "smarts": 1}), O("The teacher was impressed. She cut my time short.", {"school": 3, "happiness": 2})),
  C("Doodle", O("I drew a comic. Someone saw it. It circulated for weeks.", {"happiness": 4, "looks": 0}), O("My doodle was confiscated. It was framed on a staff room wall.", {"happiness": 2, "stress": 2})),
  C("Make a friend in the next seat", O("Another troublemaker. We became partners in crime.", {"happiness": 4, "karma": -1}), O("She talked the whole hour. I came away exhausted.", {"stress": 3})))
S("sports_try", "🏀", "Team trials", "The coach is running trials on Friday. You've never been very athletic. You've also never tried.", {"age": [9, 18]},
  C("Go and give it everything", O("I made the second team. I've never been so proud of a bench.", {"health": 2, "happiness": 6}), O("I came last in the run, and the coach clapped for me anyway.", {"happiness": 3, "health": 1})),
  C("Go and have fun", O("I made a friend in the queue. I missed the team but gained a mate.", {"happiness": 4}), O("The coach said the spirit was great, the skill 'developing'.", {"happiness": 2})),
  C("Don't go", O("I watched through the fence, wishing.", {"happiness": -3}), O("I read in the library. Fine, but I thought about it.", {"smarts": 1, "happiness": -1})))
S("exam_panic", "😰", "Exam eve", "It's midnight and the exam is at nine. You've covered two out of seven chapters and the others look like another language.", {"age": [13, 25]},
  C("Pull an all-nighter", O("I scraped a pass and a headache. Never again, I said.", {"school": 3, "health": -3, "stress": 6}), O("I fell asleep on the textbook at 4 and woke up late. A disaster.", {"school": -4, "stress": 9})),
  C("Cover the big topics and sleep", O("The right trade-off. I did fine.", {"school": 2, "stress": 2}), O("The questions were on the chapters I missed.", {"school": -2, "stress": 5})),
  C("Ask a friend for notes", O("She sent photos of hers. I owed her a pizza forever.", {"school": 3, "karma": 1, "money": -15}), O("Her handwriting was illegible. I tried.", {"school": 0, "stress": 4})))
S("teacher_mentor", "🍎", "The teacher who noticed", "A teacher stops you after class. 'You're better than the work you hand in,' she says. 'I'd like to know why.'", {"age": [11, 22]},
  C("Tell her the truth", O("I told her about home. She listened. She became a lifeline.", {"happiness": 6, "karma": 2, "school": 3}), O("She nodded and offered help. I didn't take it, but I knew it was there.", {"happiness": 3})),
  C("Shrug it off", O("She let it drop, but kept an eye on me.", {"stress": 2}), O("She gave up on me. I felt it.", {"happiness": -2})),
  C("Rise to the challenge", O("I put in the work. My grades went up. She was thrilled.", {"school": 5, "smarts": 2, "happiness": 4}), O("It was exhausting. But something shifted.", {"school": 3, "stress": 4})))
S("school_play", "🎭", "The school play", "The drama teacher is casting. You can go for a lead role, a small part, or the lighting desk, which has a lovely quiet corner.", {"age": [8, 18]},
  C("Audition for the lead", O("I got it. Opening night was a blur of light and applause.", {"happiness": 8, "fame": 1}), O("I forgot my first line and improvised. The audience loved it.", {"happiness": 6, "stress": 5})),
  C("Take a small part", O("I stole one scene. People still remember it.", {"happiness": 4}), O("I was a tree. A very good tree.", {"happiness": 2})),
  C("Run the lights", O("I loved the dark and the power. I found my place.", {"happiness": 4, "smarts": 1}), O("A cue went wrong. The show survived.", {"stress": 4, "happiness": 1})))
S("prom", "💃", "Prom night", "Everyone has a plan and a date. You have a suit, a ticket and a decision to make.", {"age": [16, 19]},
  C("Ask the person you actually like", O("They said yes. It was the best night of my teenage life.", {"happiness": 10}), O("They said no, kindly. I went with friends and had a wonderful time anyway.", {"happiness": 4, "stress": 2})),
  C("Go with friends", O("We danced badly and loudly. Photos still make me smile.", {"happiness": 6, "money": -60}), O("We argued about the music. We left early.", {"happiness": 1, "money": -50})),
  C("Skip it", O("I stayed home. I regretted it by midnight.", {"happiness": -3}), O("I read on the roof. It was a nice night.", {"happiness": 1})))
S("student_loan", "🎓", "Offer letter", "The university offer is in your hand. The fees underneath are in a font that looks like it's whispering.", {"age": [17, 22], "in_school": False},
  C("Take the loan", O("Debt as a doorway. It was worth it, I think.", {"money": -3000, "smarts": 2, "happiness": 4}), O("I'd be paying for years. I tried to focus on the first lecture.", {"money": -3000, "stress": 5})),
  C("Defer and work", O("A year of earning. I came back clearer.", {"money": 4000, "smarts": 1}), O("I never went back. I'll never know.", {"money": 4000, "happiness": -2})),
  C("Pick a cheaper course", O("Local, practical, affordable. A sensible choice.", {"money": -800, "stress": -2}), O("The course was dull. But I finished.", {"money": -800, "happiness": -2})))
S("study_group", "📚", "Study group", "Three classmates invite you to a study group. One is brilliant, one is funny and one has a reputation for taking over.", {"age": [14, 25]},
  C("Join", O("We all passed. One of them became a friend for life.", {"school": 4, "happiness": 4}), O("The takeover one took over. I learned fast, and not just the material.", {"school": 3, "stress": 4})),
  C("Study alone", O("Quiet and efficient. I did fine.", {"school": 2}), O("I missed some things only a group would've caught.", {"school": 0, "stress": 3})),
  C("Start your own group", O("It took off. Twelve people. I became a minor celebrity.", {"school": 3, "happiness": 5, "fame": 1}), O("Four people turned up. Two left. It was fine.", {"happiness": 1})))
S("field_trip", "🚌", "Field trip", "The coach is loud, the museum is sleepy, and your best friend has just whispered a plan to 'get lost' in the gift shop.", {"age": [7, 15]},
  C("Go along", O("We bought rubber snakes and put one in the teacher's bag. Detention for a week, and worth it.", {"happiness": 6, "karma": -1}), O("We got caught immediately. The teacher laughed in spite of herself.", {"happiness": 3})),
  C("Stay with the group", O("I actually learned something about the Romans. It was irritating.", {"smarts": 2}), O("My friend went alone and got in trouble. I felt like a coward.", {"stress": 3})),
  C("Ask the guide a question", O("The guide lit up. I got a private tour of the back rooms.", {"smarts": 3, "happiness": 4}), O("The question was silly. The class laughed. The guide laughed hardest.", {"happiness": 1, "stress": 2})))
S("school_exchange", "✈️", "Exchange offer", "A flyer on the noticeboard: a year abroad, host family provided. It's a long way from home.", {"age": [14, 19]},
  C("Apply", O("I got in. A year that changed me.", {"smarts": 3, "happiness": 6, "money": -600}), O("I got in, and was horribly homesick. I came back changed anyway.", {"smarts": 2, "stress": 6, "money": -600})),
  C("Think about it", O("The deadline passed. I wondered for years.", {"happiness": -2}), O("I applied a year late and went anyway.", {"happiness": 3, "smarts": 2})),
  C("Pass", O("I stayed. I made a good year of it.", {"happiness": 1}), O("My best friend went instead. I missed her.", {"happiness": -2})))
S("uni_party", "🍻", "Freshers' week", "Everyone around you is shouting and laughing and holding a plastic cup, and you don't know anyone yet.", {"age": [18, 24], "university": True},
  C("Throw yourself in", O("Chaos, friendship, and a bad morning. A classic start.", {"happiness": 6, "health": -2, "money": -40}, habit={"drinking": 3}), O("I over-did it. Someone put me in the recovery position. I met my best friend that way.", {"happiness": 3, "health": -4, "stress": 3}, habit={"drinking": 5})),
  C("Stay for an hour", O("Enough to know a few names. Exactly right.", {"happiness": 3}), O("I left feeling like an outsider, but the next day was better.", {"happiness": 1})),
  C("Skip it", O("I called my mother. A different kind of start.", {"happiness": -1}), O("I used the quiet to settle in. By the time everyone was hungover, I knew where everything was.", {"school": 2, "happiness": 1})))
S("thesis", "📖", "The thesis wall", "It's three weeks before the deadline and your dissertation is eight thousand words short, and your supervisor is on holiday.", {"age": [20, 30], "university": True},
  C("Write through the night", O("Fourteen thousand words in a fortnight. I handed it in dazed, with eyes like stones.", {"school": 5, "health": -4, "stress": 9}), O("I wrote nonsense for half of it. A lower grade, but done.", {"school": 1, "stress": 8})),
  C("Ask for an extension", O("Granted. A gift.", {"stress": -3, "school": 1}), O("Refused. The panic came back.", {"stress": 6})),
  C("Cut the scope", O("A tighter paper, better argued. The examiner appreciated the focus.", {"school": 4, "smarts": 1}), O("I cut too much. It was thin.", {"school": -1})))
S("graduation", "🎓", "Graduation day", "The gown is too long, the hat is too small, and your name is next. Somewhere in the crowd, someone is holding a camera.", {"age": [18, 35]},
  C("Cross the stage with a big grin", O("They cheered. I cried a bit, in the good way.", {"happiness": 8}), O("I tripped on my gown. The video of that went around the family.", {"happiness": 4, "stress": 2})),
  C("Make a joke", O("The dean laughed. The crowd laughed. It was my finest moment.", {"happiness": 7}), O("Nobody laughed. A pure silence. I would live.", {"happiness": 1, "stress": 3})),
  C("Skip it and have the certificate posted", O("Quiet and cheap. I never regretted it.", {"money": 100, "happiness": 1}), O("I regretted it every time I saw other people's photos.", {"happiness": -3})))

# ------------------------------------------------------------------ DATING
NOPART = {"has_partner": False}
D("coffee_shop", "☕", "The regular at the counter", "There's someone in your coffee shop who is always there at the same time, with the same book, and who has started saying 'hi' in a way that sounds practised.", NOPART,
  C("Say something about the book", O("It was a book I loved. We talked for an hour and swapped numbers.", {"happiness": 6}, new_partner="f", keep_role="f"), O("They hadn't read it, they said. They were just holding it. We laughed.", {"happiness": 3})),
  C("Smile and carry on", O("They smiled back. Nothing came of it, but the coffee tasted better.", {"happiness": 2}), O("They stopped coming. I'll never know.", {"happiness": -2})),
  C("Leave a note on the cup", O("They found it. A reply came the next day. It was a good one.", {"happiness": 6}, new_partner="f", keep_role="f"), O("They didn't reply, but they didn't stop coming either.", {"stress": 2, "happiness": 1})),
  roles=FR)
D("app_match", "📱", "A match at midnight", "A match you swiped on has sent: 'You look like someone who has opinions about pizza.' Your thumbs hover.", NOPART,
  C("Reply with something good", O("It was an excellent conversation. We met the next week. It went somewhere.", {"happiness": 6}, new_partner="f", keep_role="f"), O("They stopped replying after four messages. Fine.", {"happiness": -1})),
  C("Wait until morning", O("By morning, they'd moved on. I learned about timing.", {"happiness": -2}), O("Morning came and they were still there. A good sign.", {"happiness": 3})),
  C("Unmatch", O("It didn't feel right. I put the phone down.", {"stress": -1}), O("I kept swiping. Nothing felt right.", {"stress": 2, "happiness": -1})),
  roles=FR)
D("blind_date", "🍝", "Set up by a friend", "A friend swears they've found 'the one'. You are not convinced, but there's a table booked for Thursday at 7:30.", NOPART,
  C("Go and be open", O("They turned up in the wrong shirt and made me laugh until I cried. We saw each other again.", {"happiness": 7}, new_partner="f", keep_role="f"), O("It was pleasant, and I knew in ten minutes it wouldn't go further.", {"happiness": 1})),
  C("Go and be guarded", O("I closed up. They noticed. It was polite and cold.", {"happiness": -1}), O("Eventually I relaxed. Too late, but still.", {"happiness": 2})),
  C("Cancel last minute", O("My friend was furious. I never got a second set-up.", {"happiness": -2, "stress": 3}), O("I stayed in with a film and felt guilty about it.", {"happiness": 0})),
  roles=FR)
D("first_kiss", "💋", "The doorstep", "The date has been lovely. You've reached the door, and neither of you has said goodnight. The porch light hums.", NOPART,
  C("Lean in", O("It was soft and brief and perfect. We both laughed.", {"happiness": 8}), O("Our noses collided. We laughed until it hurt.", {"happiness": 6})),
  C("Wait for them", O("They did. It was worth the wait.", {"happiness": 7}), O("They said 'good night', cheerfully, and went in. Mystery.", {"happiness": 0})),
  C("Say goodnight", O("They smiled. I replayed it all evening.", {"happiness": 3}), O("It was probably the right call. Probably.", {"happiness": 1})))
D("ghosted", "👻", "Gone quiet", "You had a fantastic third date. You've sent two messages. Four days of silence later, you can see they've read both.", {"has_partner": False},
  C("Send a third message", O("A reply came an hour later: 'sorry, work!' It was true. We met up.", {"happiness": 4}), O("Nothing. I was embarrassed.", {"happiness": -4, "stress": 3})),
  C("Let it go", O("I forgot them within a week. Lesson learned.", {"happiness": -1}), O("It stung more than I expected.", {"happiness": -3})),
  C("Call", O("They picked up. 'I'm seeing someone else.' Quick, clean, brutal.", {"happiness": -3, "stress": 2}), O("They picked up and said they'd been unwell. We talked for an hour.", {"happiness": 5})))
D("meet_parents", "🏡", "Meeting the parents", "You're in the hallway of their parents' house, holding a bunch of supermarket flowers. Somewhere inside, a dog is barking. Someone is saying 'they're here!'", {"has_partner": True},
  C("Be charming", O("Their mother loved me. Their father said 'good lad' or 'good lass' and meant it.", {"happiness": 6}), O("I said one thing too many. They laughed, politely.", {"happiness": 2, "stress": 3})),
  C("Be nervous and honest", O("I admitted I was terrified. They relaxed. The evening was warm.", {"happiness": 5}), O("I spilled the gravy. Everyone reassured me. It stuck.", {"happiness": 2})),
  C("Make an excuse", O("I cancelled with a fake cold. My partner saw through it.", {"happiness": -3}, ), O("I cancelled. My partner said 'okay'. Which meant not okay.", {"happiness": -4, "stress": 3})))
D("jealous", "😒", "The message", "Your partner's phone buzzes on the table. Name on the screen: someone you've never heard of. They flip it face-down, quickly.", {"has_partner": True},
  C("Ask calmly", O("It was a surprise party plan. I felt like an idiot, and loved.", {"happiness": 4}), O("It was an old flame. We talked it through. It was healthy.", {"stress": 3, "happiness": 2})),
  C("Look at the phone", O("It was nothing. I'd broken their trust for no reason.", {"happiness": -4, "stress": 5, "karma": -2}), O("It was something. I wish I hadn't looked.", {"happiness": -8, "stress": 8})),
  C("Let it go", O("It sat in my chest for a week, then dissolved.", {"stress": 3}), O("It never went away.", {"stress": 6, "happiness": -3})))
D("anniversary", "🥂", "Anniversary dinner", "The restaurant is booked. The gift is wrapped. The thing you forgot, you realise at the table, is the card.", {"has_partner": True},
  C("Confess and make it up", O("They laughed. The dessert was on me.", {"happiness": 5}), O("They were quiet. It took a week to be forgiven.", {"happiness": -2, "stress": 3})),
  C("Write one on a napkin", O("It was the best card I've ever written. They kept the napkin.", {"happiness": 7}), O("It was awkward, but they were touched.", {"happiness": 4})),
  C("Say nothing", O("They didn't notice, or pretended not to.", {"happiness": 1}), O("They noticed. It turned into an argument.", {"happiness": -5, "stress": 5})))
D("long_distance", "🛫", "Seven hundred miles", "Your partner has taken a job in another country. They've offered a move, and also, gently, the option to end things kindly.", {"has_partner": True},
  C("Move with them", O("A new place and a new start. It was hard, and ours.", {"happiness": 5, "stress": 5, "money": -500}), O("I moved and hated it. They noticed. We drifted.", {"happiness": -6, "money": -500, "stress": 8})),
  C("Try long distance", O("Video calls, visits, a countdown calendar. It held for a long time.", {"happiness": 2, "stress": 4}), O("It frayed by the third month.", {"happiness": -5, "stress": 5})),
  C("End it kindly", O("We cried, hugged, and stayed friends. It was grown-up.", {"happiness": -4}), O("We didn't speak for a year. Then we did.", {"happiness": -5, "stress": 3})))
D("proposal", "💍", "The ring", "The ring box has been in your jacket for eleven days. Tonight is the night, if you can stop your hands from shaking.", {"has_partner": True, "age": [19, 70]},
  C("Ask on the beach", O("Yes. They were already crying before I finished the sentence.", {"happiness": 12}), O("They said 'ask me again in a year'. That was fair.", {"happiness": -2, "stress": 4})),
  C("Ask at home", O("Quiet and honest. Yes.", {"happiness": 9}), O("Surprised and tender. They said they were scared too.", {"happiness": 5})),
  C("Wait", O("I waited another year. In hindsight, it was fine.", {"happiness": 1}), O("The moment passed. It took ages to come back.", {"happiness": -2})))
D("wedding_chaos", "👰", "The wedding", "Three hours before the ceremony, the florist has called to say the flowers are in a different city, and your best man has lost the rings.", {"has_partner": True, "married": False, "age": [20, 75]},
  C("Improvise", O("We picked flowers from the garden. The rings turned up in his sock. It was perfect.", {"happiness": 10}), O("It was chaotic and wonderful. Everyone said so.", {"happiness": 8, "stress": 5})),
  C("Delay", O("An hour late and nobody minded. Photos came out gorgeous.", {"happiness": 6, "stress": 4}), O("The venue was booked for another event. We rushed.", {"happiness": 3, "stress": 7})),
  C("Panic", O("My partner laughed and said 'we're still getting married'. I calmed down.", {"happiness": 7}), O("I cried through the vows. People said it was moving.", {"happiness": 5})))
D("breakup_text", "📵", "The message you didn't want", "It's a Sunday afternoon. Your partner's text says: 'We need to talk.' Six words that make the room go very quiet.", {"has_partner": True},
  C("Call straight away", O("They said they were unhappy. I was shocked, but it was honest.", {"happiness": -6, "stress": 7}), O("They wanted to move in together. I'd been bracing for the wrong thing.", {"happiness": 5})),
  C("Wait and prepare", O("I overthought everything for two days. It was about their job.", {"stress": 4}), O("I'd been right to be nervous. It was over.", {"happiness": -8, "stress": 8})),
  C("Ignore it", O("It never got better by ignoring.", {"stress": 6}), O("They came round, in person. It was worse and better.", {"stress": 5, "happiness": -3})))
D("rebound", "🥀", "After the split", "You're newly single, eating cereal for dinner. A friend has just invited you out with the words 'it'll do you good'.", {"has_partner": False, "age": [18, 60]},
  C("Go out", O("It was just what I needed. I laughed for the first time in weeks.", {"happiness": 5, "stress": -3, "money": -35}), O("I drank too much and cried in a taxi. The driver was kind.", {"happiness": -2, "money": -50}, habit={"drinking": 3})),
  C("Stay home and heal", O("A weekend in pyjamas, and a long walk after. Slow and right.", {"happiness": 2, "stress": -3}), O("I stayed home and spiralled. It lasted a month.", {"happiness": -5, "stress": 5})),
  C("Text the ex", O("A mistake. They didn't reply. I felt humiliated.", {"happiness": -6, "stress": 5}), O("They replied kindly. It helped, and then it didn't.", {"happiness": -1, "stress": 3})))
D("older_flame", "🔥", "An old flame", "At a wedding you spot someone you dated decades ago. They are standing alone with a glass, looking right at you.", {"age": [30, 80]},
  C("Go over", O("We talked for hours. Time had been kind. It was a lovely, bittersweet evening.", {"happiness": 6}), O("We talked, and I realised why we'd ended. A relief of a kind.", {"happiness": 2})),
  C("Wave and stay put", O("I regretted it for a week.", {"happiness": -2}), O("It was right. Some doors stay closed.", {"happiness": 1})),
  C("Leave early", O("I went home and wondered.", {"stress": 2}), O("I told my partner. They laughed. It was fine.", {"happiness": 1})))
D("dating_class", "🎨", "The pottery class", "A friend dragged you to a Thursday-night class. The person next to you has clay up to their elbows and is laughing at their own mistakes.", {"has_partner": False, "age": [18, 70]},
  C("Ask for a cup of tea afterwards", O("We drank tea and talked about nothing and everything. It began there.", {"happiness": 7}, new_partner="f", keep_role="f"), O("They already had plans. They said 'next week?'. I took it.", {"happiness": 3})),
  C("Compliment their pot", O("They blushed and said it was a plate. We became friends.", {"happiness": 3}), O("It was upside down, they said. We laughed.", {"happiness": 2})),
  C("Focus on your own clay", O("I made a lopsided mug that I love.", {"happiness": 2}), O("My pot collapsed, which was embarrassing.", {"happiness": -1})),
  roles=FR)
D("holiday_romance", "🌴", "Holiday romance", "Four days into the trip, you meet someone on the beach. They're funny, you're tanned, and the flight home is in nine days.", {"has_partner": False, "age": [18, 60]},
  C("Make the most of it", O("Nine perfect days. I cried at the airport. It's a good memory.", {"happiness": 9, "money": -200}), O("We kept in touch. It turned into something real.", {"happiness": 8, "money": -200}, new_partner="f", keep_role="f")),
  C("Keep it light", O("A few evenings, a few laughs, a postcard.", {"happiness": 4}), O("They were serious. I wasn't. It got awkward.", {"stress": 3})),
  C("Avoid it", O("I read three books. They were good.", {"smarts": 1}), O("I regretted it on the plane.", {"happiness": -3})),
  roles=FR)
D("couples_therapy", "🛋️", "The counsellor's sofa", "You and your partner have been arguing about the dishes, but it's about something else, and you both know it. A counsellor has an opening on Tuesday.", {"has_partner": True},
  C("Book it", O("Six sessions in, we could talk again. It saved us.", {"happiness": 7, "money": -400}), O("It showed us we wanted different things. We parted kindly.", {"happiness": -3, "money": -400, "stress": 4})),
  C("Try on your own", O("We had a talk on the balcony. It helped, for a while.", {"happiness": 3}), O("We didn't. The dishes piled up.", {"happiness": -4})),
  C("Avoid it", O("The tension eased by itself, in the way those things do.", {"stress": 2}), O("It didn't. It festered.", {"happiness": -6, "stress": 6})))
D("friend_zone", "🧱", "Just friends", "Your closest friend has just said, over dinner, 'I think of you as family.' You've been hoping for something else for two years.", {"has_partner": False},
  C("Tell them how you feel", O("They were quiet, then said, 'I've wondered, too.' We tried it, nervously.", {"happiness": 8}, new_partner="f", keep_role="f"), O("They were kind. It was clear. We stayed friends, with effort.", {"happiness": -4, "stress": 4})),
  C("Say nothing", O("I swallowed it. I got over it, slowly.", {"stress": 3, "happiness": -2}), O("I swallowed it. I never did, entirely.", {"stress": 5, "happiness": -4})),
  C("Pull back from the friendship", O("A painful distance. It healed, in time.", {"happiness": -3}), O("They noticed and asked why. I lied.", {"stress": 4, "karma": -1})),
  roles=FR)
D("catfish", "🎭", "Not who they said", "The person you've been messaging for three months has turned up at the restaurant, and it is quite plainly not the person in the photos.", {"has_partner": False, "age": [18, 70]},
  C("Stay for dinner", O("They were nervous and sweet. We ended up friends.", {"happiness": 3}), O("They asked for money by dessert. I left.", {"money": -30, "stress": 5, "karma": 0})),
  C("Leave", O("I walked out. I felt bad and also fine.", {"stress": 3}), O("I cried in the car. It had been so real.", {"happiness": -5})),
  C("Call it out", O("They apologised and sobbed. It was awful.", {"stress": 6}), O("They snapped and left. I felt a bit better.", {"stress": 3})))
D("midlife_crush", "💭", "A crush at the school gates", "You're married, and busy, and you have just noticed that you look forward to Thursday pick-up for a very specific reason.", {"married": True, "age": [28, 60]},
  C("Admit it to yourself and step back", O("I stopped going to the gate. It passed. I loved my spouse more for it.", {"karma": 3, "stress": 3}), O("It took months to fade. I said nothing.", {"stress": 5})),
  C("Tell your spouse", O("A frank, brave conversation. It brought us closer.", {"happiness": 3, "stress": 4}), O("They were hurt. We worked on it.", {"happiness": -3, "stress": 6})),
  C("Pursue it", O("It ended badly for everyone.", {"karma": -8, "happiness": -8, "stress": 12}), O("It stayed a secret. The secret rotted me.", {"karma": -6, "stress": 8})))

# ------------------------------------------------------------------ GIFTS
G("birthday_surprise", "🎁", "A parcel on your birthday", "There's a heavy parcel on the doormat, addressed in familiar handwriting. It's from {m.first}, and it rattles.", {"age": [6, 90], "chance": 0.3},
  C("Open it right away", O("It was something I'd mentioned once, years ago. I was speechless.", {"happiness": 7}, relationship={"m": 5}), O("It was a jumper. A bit loud, but lovingly chosen.", {"happiness": 3}, relationship={"m": 3})),
  C("Save it for later", O("I opened it with a cup of tea at night. A lovely, quiet pleasure.", {"happiness": 4}, relationship={"m": 2}), O("I forgot about it for a week. I felt awful.", {"happiness": -1}, relationship={"m": -2})),
  C("Phone to say thank you", O("They were thrilled, we talked for an hour.", {"happiness": 5}, relationship={"m": 6}), O("They were out. I left a message and felt silly.", {"happiness": 1})),
  roles={"m": {"relation": "mother"}})
G("wrong_gift", "🧦", "The wrong gift", "Your {m.rel} has given you a present with enormous pride. It is an extremely ugly lamp, and they're watching your face.", {"age": [10, 90]},
  C("Gush", O("They glowed. I put the lamp in the spare room and told no one.", {"happiness": 2, "karma": 1}, relationship={"m": 4}), O("They wanted to see it in my house. Next visit, I had to prop it up.", {"stress": 3}, relationship={"m": 5})),
  C("Be honest", O("They laughed and said they hated it too. It was from a church sale.", {"happiness": 4}, relationship={"m": 3}), O("They were hurt. It took a while.", {"stress": 4}, relationship={"m": -6})),
  C("Re-gift it", O("It went to a charity shop. Someone, somewhere, loves it.", {"karma": 1}), O("It went to my cousin, who gave it back to my mother. A full circle.", {"happiness": 2, "stress": 3})),
  roles={"m": {"relation": "mother"}})
G("surprise_party", "🎉", "Surprise!", "You open the door and thirty people jump out and shout. The balloon string is wrapped around your head.", {"age": [16, 80], "chance": 0.25},
  C("Cry happy tears", O("The best night in years. I won't forget the faces.", {"happiness": 10}), O("It was overwhelming and wonderful.", {"happiness": 8, "stress": 2})),
  C("Pretend you knew", O("Nobody believed me. They roared.", {"happiness": 6}), O("They wanted details. I made them up.", {"happiness": 4})),
  C("Hide in the bathroom for five minutes", O("I came out calmer. The party started again.", {"happiness": 5}), O("I stayed an hour. They sent a search party.", {"happiness": 1, "stress": 3})))
G("expensive_gift", "💎", "Too much", "Your partner hands you a small box that is obviously from a jeweller you can't afford. 'It's nothing,' they say. It is very much something.", {"has_partner": True, "min_money": 0},
  C("Accept warmly", O("I wore it that night. It meant more than it cost.", {"happiness": 8}), O("I felt guilty about the price. It faded.", {"happiness": 4, "stress": 2})),
  C("Say it's too much", O("They insisted. I gave in.", {"happiness": 3}), O("They were hurt. We had a real talk.", {"happiness": -2, "stress": 4})),
  C("Give something back", O("A handwritten letter. It was my best present.", {"happiness": 6}), O("A cheap gift. I felt awkward.", {"happiness": -1, "stress": 3})))
G("handmade", "🧶", "Handmade", "A child has pressed something into your hands: a card made of glue, glitter, and the world's most heartfelt spelling mistakes.", {"has_children": True, "age": [24, 90]},
  C("Put it on the fridge", O("It stayed there for years. Every glance was a small joy.", {"happiness": 6}), O("It fell down, was found years later, and made me cry.", {"happiness": 4})),
  C("Frame it", O("A little too much. They loved it.", {"happiness": 5}), O("It's on my desk at work. People ask.", {"happiness": 4})),
  C("Say thank you and move on", O("They nodded. I felt I'd missed a moment.", {"happiness": 1}), O("They were quiet at dinner. I noticed.", {"happiness": -1, "stress": 2})))
G("secret_santa", "🎅", "Secret Santa", "The office draw gave you the person you know least, with a twenty-dollar limit and no hints.", {"employed": True},
  C("Research them", O("Their desk had a tiny cactus. I bought another. They cried.", {"happiness": 4, "job_perf": 2, "money": -20}), O("I guessed wrong. It was a gift voucher for a shop they hate.", {"money": -20, "stress": 2})),
  C("Buy chocolate", O("Nobody dislikes chocolate. Safe and kind.", {"money": -15}), O("They were allergic. We both felt dreadful.", {"money": -15, "stress": 3})),
  C("Go wild", O("A ridiculous gift. The whole office loved it.", {"happiness": 5, "money": -30, "job_perf": 3}), O("It was too much. HR got involved.", {"money": -30, "job_perf": -3, "stress": 5})))
G("inherited_watch", "⌚", "The old watch", "Your grandparent presses a heavy box into your hand. 'I want you to have this while I can still see your face.' Inside, a watch with a worn leather strap.", {"age": [16, 70]},
  C("Wear it every day", O("It kept time like a heartbeat. I thought of them every hour.", {"happiness": 5, "karma": 2}), O("It broke a year later. I had it repaired, at some cost, and wore it more carefully.", {"happiness": 2, "money": -150})),
  C("Put it in a drawer", O("It's still there. I look at it sometimes.", {"happiness": 1}), O("It was stolen in a burglary. The loss was larger than the watch.", {"happiness": -5, "stress": 4})),
  C("Ask about its story", O("They told me everything. We spent the afternoon together.", {"happiness": 8, "karma": 2}), O("It was shorter than I'd hoped, but sweet.", {"happiness": 4})))
G("flowers_apology", "💐", "Flowers", "A bunch of flowers arrives at your door with no card. The delivery driver shrugs. 'No name.'", {"age": [16, 90], "chance": 0.4},
  C("Find out who sent them", O("It was a friend I'd lost touch with. We began to talk again.", {"happiness": 6}), O("It was a neighbour with a crush. Awkward, but sweet.", {"happiness": 2, "stress": 2})),
  C("Enjoy them", O("They lasted a week and made the room smell wonderful.", {"happiness": 3}), O("They died fast. Mystery remained.", {"happiness": 1})),
  C("Throw them out", O("A bit rude. But I wasn't in the mood.", {"karma": -1}), O("I felt bad about it all day.", {"karma": -1, "happiness": -1})))
G("bribe_gift", "🍾", "A gift with strings", "A supplier sends a case of excellent wine to your office, with a note: 'Looking forward to continuing our work together.'", {"employed": True, "age": [24, 70]},
  C("Send it back", O("My boss was impressed by the ethics. The supplier was not.", {"karma": 4, "job_perf": 2}), O("The supplier took offence and went elsewhere.", {"karma": 3, "job_perf": -2})),
  C("Share it with the team", O("A joyful Friday. Nobody talked about the supplier.", {"happiness": 4, "karma": 0}, habit={"drinking": 2}), O("Compliance heard about it and called me in.", {"stress": 6, "job_perf": -3})),
  C("Keep it", O("It was delicious. It also made me a little complicit.", {"happiness": 2, "karma": -3}), O("It came back to bite me during an audit.", {"karma": -4, "job_perf": -6, "stress": 8})))
G("generosity_stranger", "🤲", "Kindness of a stranger", "At the till you've realised your card has declined. Behind you, a man in a hi-vis jacket says, 'I've got this one,' and taps his card.", {"age": [16, 90], "chance": 0.4},
  C("Accept", O("I thanked him. I paid it forward the next week.", {"happiness": 5, "karma": 2}), O("I accepted and went red. I've told that story ever since.", {"happiness": 3})),
  C("Refuse politely", O("I put things back. It was my pride talking.", {"stress": 3}), O("He insisted. I gave in.", {"happiness": 3})),
  C("Offer to pay back", O("He gave me his number. We never spoke again.", {"karma": 1}), O("He waved it away with a smile.", {"happiness": 3})))
G("lottery_gift", "🎟️", "A scratch card", "Your {m.rel} presses a scratch card into your palm. 'Just for luck,' they say. You scratch it in the car park with a coin.", {"age": [18, 90]},
  C("Scratch it now", O("Fifty dollars! A tiny, joyous jolt.", {"money": 50, "happiness": 5}), O("Nothing. A delicious little nothing.", {"happiness": 0})),
  C("Save it", O("I forgot it in a coat pocket. It had expired.", {"happiness": -1}), O("I scratched it at New Year. Twenty dollars.", {"money": 20, "happiness": 2})),
  C("Give it back", O("They laughed and gave it to someone else. That someone won a hundred dollars.", {"happiness": 1}), O("They insisted I keep it.", {"happiness": 1})),
  roles={"m": {"relation": "father"}})
G("friendship_gift", "🎒", "Packed for you", "A friend has turned up at your door, out of breath, with a rucksack. 'You said you were stressed. I booked us a weekend. Pack.'", {"age": [18, 80]},
  C("Go", O("Two days of hills, fish and chips, and nobody asking anything of me. It fixed something.", {"happiness": 8, "stress": -8, "money": -60}), O("It rained the whole time. We laughed, soaked. A glorious mess.", {"happiness": 6, "stress": -5, "money": -60})),
  C("Say you can't", O("They understood. I felt guilty.", {"happiness": -1}), O("They went with someone else. I felt the gap.", {"happiness": -3})),
  C("Say yes, then cancel", O("They were gutted. We both knew it.", {"karma": -3, "happiness": -3}), O("I felt terrible for weeks.", {"karma": -3, "stress": 4})))
G("pet_gift", "🐶", "A gift with a pulse", "A neighbour has turned up with a cardboard box and an apologetic face. Inside, a puppy that looks like it's already decided to live with you.", {"age": [18, 80], "has_pet": False},
  C("Take the puppy", O("Chewed shoes, 5 a.m. walks, and the best decision I made that year.", {"happiness": 8, "stress": 3, "money": -150}, gain_pet="dog"), O("It was tough at first. It became my shadow.", {"happiness": 6, "stress": 5, "money": -150}, gain_pet="dog")),
  C("Say no", O("She understood and found it a home.", {"karma": 0}), O("I felt sad about it for days.", {"happiness": -1})),
  C("Think about it", O("She waited two days. I said yes.", {"happiness": 6, "money": -150}, gain_pet="dog"), O("She gave it to someone else. I saw it in the park. I smiled and hurt.", {"happiness": -1})))
G("gifted_trip", "🧳", "A ticket", "An envelope on the table contains two flight tickets and a handwritten note from a relative who rarely speaks of feelings: 'Go. Take someone who matters.'", {"age": [20, 90], "chance": 0.3},
  C("Take your partner", O("A week of sun and not much else. Perfect.", {"happiness": 9, "stress": -6}), O("We argued about luggage and then forgot why. A lovely memory.", {"happiness": 6, "stress": -3})),
  C("Take a friend", O("A trip we still talk about.", {"happiness": 8}), O("A trip we still argue about.", {"happiness": 4, "stress": 2})),
  C("Sell the tickets", O("A practical choice. I felt a tiny bit grubby.", {"money": 400, "karma": -2}), O("The relative found out. It stung.", {"money": 400, "karma": -5, "stress": 4})))
save("life_a.json")

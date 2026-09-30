#!/usr/bin/env python3
"""Rewrites the opening text of high-traffic events with inline alternatives
({~a|b|c}, optionally {~poor=..|rich=..|..}) and named places ({fx.pub}).
Idempotent: safe to re-run. A list value replaces a text array wholesale."""
import json, glob, os

V = {
 "tod.park": "The big-kid slide at {fx.park} is SO tall. {~Everyone else is already at the top.|A boy at the bottom is watching you.|The ladder has more rungs than you've ever climbed.}",
 "tod.dog": "A dog the size of a pony {~walks up to|wanders up to|lumbers towards} your stroller {~outside {fx.shop}|on {fx.street}|in {fx.park}}.",
 "tod.daycare": ["It's your first day at daycare. {~Someone's crying, and it might be you.|The room smells of paint and orange squash.|Every tiny human here is looking at you.}", "Someone dropped you off in a room full of other tiny humans, and there is a box of {~wooden blocks|crayons with no paper|a rocking horse with one ear}."],
 "kid.tooth_fairy": "Your tooth has been wiggling for a week. {~You can't stop touching it with your tongue.|Your dad has offered to 'help' with a piece of string.|It's hanging by a thread during lunch at {fx.primary}.}",
 "kid.recess": ["It's recess at {fx.primary}. {~The whole playground is yours.|Somebody has already claimed the good swing.|The football game has started without you.}", "The bell rang for recess. {~Everyone ran.|The rain had stopped, which nobody believed.|The teacher on duty has a whistle and a grudge.}"],
 "kid.snow": "School's canceled. {~It snowed overnight|The roads are closed|The whole of {fx.street} is white} and {~your mother is already looking for your other glove|somebody has a sledge|the sky is the colour of a blank page}.",
 "kid.camp": "Your parents signed you up for summer camp. Two whole weeks. {~The brochure shows a lake and far too many smiling children.|Your bag is packed, and there's a label in every sock.|You're not sure whether to be thrilled or terrified.}",
 "kid.art_contest": "The town is holding a kids' art contest at {fx.library}. {~First prize is a box of 96 crayons.|Your teacher looked straight at you when she said it.|The judge is rumoured to be the mayor's wife.}",
 "kid.first_phone": "Your parents are finally talking about getting you a {~phone|{era.phone}}. {~Everyone else in your class already has one.|There are a lot of rules attached, and one of them is about dinner.|You have been hinting for months.}",
 "kid.nightlight": "You're sure there's something under your bed. {~It breathes when the house is quiet.|It was there last night too.|The wardrobe door opened by itself.}",
 "kid.pet_fish": "It's your turn to take the class goldfish home for the weekend. {~He's called Gerald.|The teacher reminded you three times.|You've already named him something else.}",
 "teen.job_first": "{fx.shop} down the street is hiring teens. {~The sign has been in the window for weeks.|A friend said the manager is a lunatic.|It pays just enough to matter.}",
 "teen.permit": "You're finally old enough to learn to drive. {~The form is three pages long.|Your dad is pretending to be calm about it.|Everyone you know has a story about their first lesson.}",
 "teen.band": "{f.first} wants to start a band in the garage. {~You've never played an instrument.|They already have a name and a logo and no songs.|The neighbours have not yet been told.}",
 "teen.college_visit": "Your parents want to take you to visit a college. {~It is four hours away and there will be a sandwich in the car.|The brochure is glossy; the dorm, the tour guide says, is 'cosy'.|You suspect they want you to be impressed.}",
 "teen.homecoming": ["It's homecoming week at {fx.secondary}. {~The whole school is buzzing.|Every corridor is covered in crepe paper.|There's a rumour about who's winning king.}", "The homecoming game is Friday. {~The marching band has been practising since August.|Half of {fx.secondary} will be in face paint.|Someone has hung a banner across the gym.}"],
 "adult.dmv": "You have to renew your ID. The line at the office is {~out the door|longer than last time|stuck on a number that hasn't changed in an hour}. {~You brought a book.|You forgot one of the forms.|The woman in front of you has brought a folding chair.}",
 "adult.flat_tire": ["You got a flat tire {~on the highway|on {fx.street}|outside {fx.shop}}. {~It's raining.|It's exactly the wrong moment.|The spare is underneath everything you own.}", "Your car shudders and pulls to the right. Flat tire. {~You don't remember how the jack works.|You had an appointment in twenty minutes.|Somebody slows to watch and keeps going.}"],
 "adult.gym_membership": "It's January. {~Everyone is joining {fx.gym}.|{fx.gym} has a queue at the door.|You can't find a parking space at {fx.gym}, and you haven't even signed up.} {~The membership is cheaper if you sign for a year.|The salesman has very white teeth.|You tell yourself you'll actually go.}",
 "adult.roommate": ["Your {~roommate|flatmate} keeps eating your food. {~There's a name on the milk, and it isn't theirs.|Yesterday it was the last of the cheese.|The fridge contains a note in the other person's handwriting.}", "Your {~roommate|flatmate} has a new partner who basically lives with you now. {~There are two toothbrushes and a third pair of shoes.|You've seen them more than the post.|They have opinions about your sofa.}"],
 "adult.neighbor_feud": ["Your neighbor says your tree is ruining their gutters. {~There's a letter, and a photograph of the gutter.|They've brought a ladder to make their point.|Their tone on {fx.street} is surprisingly polite.}", "Your neighbor's dog keeps using your lawn as a bathroom. {~You've started counting.|They say 'he's very sensitive'.|The grass is taking it personally.}"],
 "adult.hobby": ["You need a hobby. Your friends say you work too much. {~The last book you read was a manual.|You can't remember the last time you did something for fun.|You haven't touched the guitar since 2009.}", "You have free weekends for the first time in ages. {~It feels suspicious.|You spend Saturday morning staring at a wall.|Every idea is a little too much effort.}"],
 "adult.reunion": "Your high school is having a {n}-year reunion at {fx.secondary}. {~You still have the yearbook.|You're not sure who'll remember you.|Half the people who'll be there you haven't thought about since.}",
 "adult.promotion_party": ["It's the office holiday party at {fx.pub}. {~There's an open bar, and everyone is aware of it.|The HR department has sent a reminder about conduct.|A colleague has already started the karaoke.}", "{fx.work} is throwing a party. Attendance is 'optional'. {~Nobody believes that.|The CEO's speech has been rehearsed in a mirror.|Someone's brought a cake shaped like a spreadsheet.}"],
 "adult.layoff_rumor": "Word around {fx.work} is that layoffs are coming. {~Someone saw a consultant in the lift.|The HR door has been closed all week.|The coffee machine is where people whisper.} {~You have started checking the job sites.|Nobody is meeting your eye.|You can't tell if you're safe.}",
 "adult.money_friend": ["{f.first} asks to borrow $500 until payday. {~Their voice doesn't sound right.|It's the third time this year.|They're not asking for anything they can't explain.}", "{f.first} is behind on rent and asks if you can help. {~They look exhausted.|They've already sold a few things.|You know what they'd say if it was you.}"],
 "adult.home_repair": ["The water heater exploded. {~There's a river in the basement.|You can hear it on the stairs.|You're standing in it.}", "The roof is leaking into the living room. {~It's raining in the kitchen too.|You've placed seven buckets.|There's a patch on the ceiling shaped like Australia.}", "The fridge died, with all the food in it. {~You can smell it from the stairs.|A week's shopping is now a science experiment.|The freezer door swung open like a mouth.}"],
 "adult.food_poison": ["The gas station sushi was a mistake. {~You knew it at the time.|You're reading the label with new interest.|You are on the bathroom floor, reconsidering.}", "Something you ate last night is fighting back. {~You cannot sit or stand.|The toilet seat is your only friend.|You are grey.}"],
 "adult.adopt_stray": ["A stray cat has been sleeping on your doorstep. {~It looks at you like you owe it money.|It has brought you a dead mouse as a gift.|It shows up at seven sharp.}", "A scruffy dog followed you home from {fx.park}. {~It is wearing a collar with no tag.|It has already decided this is its house.|It is now lying on your foot.}"],
 "adult.parking_ticket": ["There's a ticket on your windshield. {~You only parked for five minutes.|The sign was behind a tree.|The warden is still in sight.}", "You parked for five minutes outside {fx.shop}. The ticket says otherwise. {~It is slightly damp.|It has the word 'unfortunately' on it.|The warden is writing another one two cars down.}"],
 "adult.surprise_party": "Your friends threw you a surprise party. {~You walked in on the lights going on.|You'd known for a week and pretended.|You were convinced they'd forgotten.}",
 "adult.book_club": "{f.first} invited you to a book club at {fx.cafe}. {~The book is seven hundred pages.|You know none of the members.|There's wine, and some of the members have read the book.}",
 "adult.inheritance_small": "You're clearing out an old attic and find a box of someone's things. {~It smells of camphor and sadness.|The writing on the lid is faded.|There's a photo on top of a face you almost recognise.}",
 "fam.parent_call": ["{m.first} is calling for the third time this week. {~She has news, and it's about the neighbour.|She wants to know if you've eaten.|It's 8 a.m. and she's already been up for hours.}", "{m.first} wants to video chat. {~She's figured out the camera.|You can see the ceiling.|She holds the phone like a sandwich.}"],
 "fam.dad_advice": "{d.first} wants to teach you how to {task}. {~He's already laid out the tools.|He has a video about it from 2006.|He clears his throat before he starts.}",
 "fam.kid_first_steps": "{k.first} is holding onto the coffee table and wobbling. {~You are holding your phone to film it.|Your partner has dropped everything.|The dog is watching.}",
 "fam.partner_job": "{p.first} got a dream job offer in another city. {~They haven't said yes yet.|There's a contract and a spreadsheet on the kitchen table.|They look both thrilled and guilty.}",
 "fam.partner_snore": "{p.first}'s snoring has reached jet-engine levels. {~You've started sleeping on the sofa.|The walls shake.|The neighbour banged on the wall last night.}",
 "fam.in_laws": "{p.first}'s family wants you over for dinner. {~Everyone will be there.|There's a question about when you're going to do something about something.|Someone is bringing a casserole.}",
 "fam.pet_sick": "{pet.first} isn't eating and hasn't left the bed all day. {~You phone {fx.surgery}'s emergency line.|You keep checking on them.|They don't even lift an ear when you rattle the bag.}",
 "fam.pet_trick": "{pet.first} has learned to open the fridge. {~You found the evidence at 3 a.m.|There is a trail of wrappers.|They're looking very pleased with themselves.}",
 "elder.bingo": "It's bingo night at {fx.church}. {~The prizes are better than they sound.|The caller has a voice like warm toast.|Doris from number 12 takes it very seriously.}",
 "elder.memoir": "Your family keeps asking you to write down your life story. {~Your granddaughter has bought you a notebook.|Somebody's offered to record it on a phone.|You keep saying tomorrow.}",
 "elder.garden": "The county fair has a tomato contest. Your tomatoes are enormous. {~The man from number six is nervous.|A judge came by the allotment.|You've been guarding them since June.}",
 "place.local_festival": ["{city} is holding its big annual festival this weekend. {~The stalls on {fx.street} open at ten.|Bunting has gone up overnight.|Even the pigeons look excited.}", "The whole of {city} is out for the summer festival. {~{fx.market} is wall-to-wall.|Someone's roasting a pig outside {fx.pub}.|The brass band is in tune, mostly.}"],
 "money.bill_shock": ["The electricity bill arrived. It's twice what it should be. {~You've been heating the whole house.|You suspect a fault.|You open it on the doorstep and sit down.}", "Your {era.phone} bill says you used 40 gigabytes of roaming. You didn't leave town. {~You've been on hold for forty minutes.|You suspect the teenager.|The woman at {fx.shop} says it happens all the time.}"],
 "money.side_hustle": ["A friend says you could make good money on the side. {~They have a spreadsheet.|They've already printed the flyers.|It sounds almost legal.}", "You've got a skill people would pay for. {~You hadn't noticed until someone asked.|Someone at {fx.pub} said it out loud.|It's the thing you do without thinking.}"],
}

changed = 0
for f in glob.glob('data/events/*.json'):
    data = json.load(open(f))
    dirty = False
    for e in data:
        if e['id'] in V:
            new = V[e['id']]
            if e['text'] != new:
                if isinstance(new, list) and not isinstance(e['text'], list):
                    new = new[0]
                if isinstance(new, str) and isinstance(e['text'], list):
                    new = [new] + e['text'][1:]
                if isinstance(new, list) and isinstance(e['text'], list) and len(new) != len(e['text']):
                    new = (new + e['text'][len(new):])[:len(e['text'])] if len(new) < len(e['text']) else new
                e['text'] = new
                dirty = True; changed += 1
    if dirty:
        json.dump(data, open(f, 'w'), indent=1, ensure_ascii=False)
        open(f, 'a').write('\n')
print('rewrote', changed, 'of', len(V), 'event openings')

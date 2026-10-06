extends Node

const ACTIVITY_GROUPS := [
	{"id": "mind", "name": "Mind & Body", "icon": "💪", "sub": "Gym, martial arts, diet, meditation", "items": [
		{"id": "gym", "name": "Gym", "icon": "🏋️", "min": 12, "sub": "Health and looks"},
		{"id": "martial", "name": "Martial arts", "icon": "🥋", "min": 6, "sub": "Belts, and a better right hook", "menu": "daily:martial"},
		{"id": "diet", "name": "Diet", "icon": "🥗", "min": 12, "sub": "What you eat, every year", "menu": "daily:diet"},
		{"id": "meditate", "name": "Meditate", "icon": "🧘", "min": 8, "sub": "Lower stress"},
		{"id": "walk", "name": "Go for a walk", "icon": "🚶", "min": 5, "sub": "Clear your head"},
		{"id": "yoga", "name": "Yoga class", "icon": "🤸", "min": 12, "sub": "$40 · body and mind"},
		{"id": "garden", "name": "Gardening", "icon": "🌻", "min": 6, "sub": "Dirt under your nails", "act": "daily:garden"},
		{"id": "memory", "name": "Memory test", "icon": "🧠", "min": 6, "sub": "How sharp are you?", "act": "daily:memory"},
		{"id": "pray", "name": "Pray", "icon": "🙏", "min": 4, "sub": "Ask for a little help", "act": "daily:pray"},
		{"id": "threads", "name": "Life Threads", "icon": "🧵", "min": 10, "sub": "Memories that can return years later", "menu": "threads:root"},
	]},
	{"id": "fun", "name": "Entertainment", "icon": "🎮", "sub": "Movies, outings, games, books", "items": [
		{"id": "movie", "name": "Movie theater", "icon": "🎬", "min": 4, "sub": "Pick a movie", "menu": "daily:movies"},
		{"id": "outings", "name": "Go out", "icon": "🎟️", "min": 4, "sub": "Bowling, theme parks, zoo, escape rooms…", "menu": "daily:outings"},
		{"id": "games", "name": "Play video games", "icon": "🎮", "min": 5, "sub": "Pure fun"},
		{"id": "read", "name": "Read a book", "icon": "📖", "min": 6, "sub": "Smarts"},
		{"id": "concert", "name": "Concert", "icon": "🎤", "min": 14, "sub": "$90"},
	]},
	{"id": "social", "name": "Social", "icon": "👥", "sub": "Nightlife, social media, parties", "items": [
		{"id": "nightlife", "name": "Nightlife", "icon": "🪩", "min": 18, "sub": "Clubs, lounges, bar crawls", "menu": "daily:nightlife"},
		{"id": "social_media", "name": "Social media", "icon": "📱", "min": 13, "sub": "Snapgram, Clipz, TubeHub, Streamr, Chirp", "menu": "social:root"},
		{"id": "party", "name": "Throw a party", "icon": "🎉", "min": 16, "sub": "$300"},
		{"id": "volunteer", "name": "Volunteer", "icon": "🤝", "min": 12, "sub": "Karma and happiness"},
		{"id": "make_friend", "name": "Make a friend", "icon": "🙋", "min": 6, "sub": "Meet someone new"},
		{"id": "cult", "name": "Cult", "icon": "🛐", "min": 21, "sub": "Start a movement", "panel": true},
	]},
	{"id": "edu", "name": "Education", "icon": "🎓", "sub": "Library, courses, lessons", "items": [
		{"id": "library", "name": "Library", "icon": "📚", "min": 5, "sub": "Study and smarts"},
		{"id": "course", "name": "Practical courses", "icon": "💻", "min": 16, "sub": "$200 · skills for your chosen field", "menu": "market:training"},
		{"id": "instrument", "name": "Music lessons", "icon": "🎸", "min": 6, "sub": "$120 · happiness"},
		{"id": "voice", "name": "Voice lessons", "icon": "🎙️", "min": 8, "sub": "$80 · singers and actors", "act": "daily:voice"},
		{"id": "acting", "name": "Acting lessons", "icon": "🎭", "min": 8, "sub": "$80 · for the stage and screen", "act": "daily:acting"},
	]},
	{"id": "love", "name": "Love & Family", "icon": "❤️", "sub": "Dating, fertility, adoption", "items": [
		{"id": "dating", "name": "Find love", "icon": "💘", "min": 14, "sub": "Apps, speed dating, celebrities", "menu": "daily:dating"},
		{"id": "fertility", "name": "Fertility", "icon": "🧬", "min": 18, "sub": "IVF, insemination, surrogacy", "menu": "daily:fertility"},
		{"id": "adoption", "name": "Adoption", "icon": "🏠", "min": 21, "sub": "Give a child a home", "menu": "daily:adoption"},
	]},
	{"id": "shopping", "name": "Shopping", "icon": "🛍️", "sub": "Jewelers, electronics, boats, novelties", "items": [
		{"id": "shop", "name": "Go shopping", "icon": "🛍️", "min": 8, "sub": "Stores, models, homes, transport and animals", "menu": "shop:root"},
		{"id": "animals", "name": "Animals", "icon": "🐾", "min": 8, "sub": "Shelter, pet shop, breeder", "menu": "comp:root"},
		{"id": "mystuff", "name": "Your stuff", "icon": "🎒", "min": 0, "sub": "What you own and what it does", "menu": "shop:mine"},
	]},
	{"id": "crime", "name": "Crime", "icon": "🥷", "sub": "Shoplift, steal, rob", "items": [
		{"id":"murder","name":"Murder","icon":"🥷","min":18,"sub":"Non-graphic · lasting death and legal consequences","panel":true},
		{"id": "shoplift", "name": "Shoplift", "icon": "🛍️", "min": 12, "sub": "Low risk, low reward"},
		{"id": "pickpocket", "name": "Pickpocket", "icon": "👛", "min": 14, "sub": "Quick hands"},
		{"id": "burglary", "name": "Burglary", "icon": "🏠", "min": 16, "sub": "Minigame · break into a house"},
		{"id": "car_theft", "name": "Steal a car", "icon": "🚗", "min": 16, "sub": "Grand theft auto"},
		{"id": "bank_robbery", "name": "Rob a bank", "icon": "🏦", "min": 18, "sub": "High risk, high reward"},
		{"id": "dealing", "name": "The street game", "icon": "🌃", "min": 16, "sub": "Supply, turf, crews, dirty money", "menu": "dealer:root"},
		{"id": "black_market", "name": "Black Market", "icon": "🕶️", "min": 16, "sub": "Fence, forge, smuggle", "panel": true},
		{"id": "lay_low", "name": "Lay low", "icon": "🤫", "min": 12, "sub": "Cool off your heat (2 time)"},
	]},
	{"id": "legal", "name": "Legal", "icon": "⚖️", "sub": "Licenses, lawsuits, identity, your will", "items": [
		{"id": "licenses", "name": "Licenses", "icon": "🪪", "min": 12, "sub": "Driving, boating, pilot, firearms, fishing, hunting, scuba", "panel": true},
		{"id": "lawsuit", "name": "Lawsuit", "icon": "⚖️", "min": 18, "sub": "Sue someone", "panel": true},
		{"id": "justice_record", "name": "Justice & Reentry", "icon": "🏛️", "min": 18, "sub": "Court history, appeals, probation and parole", "menu": "amb:justice"},
		{"id": "identity", "name": "Identity", "icon": "🪪", "min": 16, "sub": "Name and gender", "menu": "daily:identity"},
		{"id": "will", "name": "Will & testament", "icon": "📜", "min": 18, "sub": "Who gets what", "menu": "daily:will"},
		{"id": "loans", "name": "Borrow money", "icon": "🏦", "min": 18, "sub": "Four lenders, and what each one will lend you", "panel": true},
	]},
	{"id": "health", "name": "Health & Looks", "icon": "🏥", "sub": "Doctors, salon, surgery, therapy", "items": [
		{"id": "doctors", "name": "Health & support", "icon": "🩺", "min": 0, "sub": "Appointments, care plans and family help", "menu": "journey:wellbeing"},
		{"id": "care_pathway", "name": "Getting care", "icon": "@hospital", "min": 6, "sub": "GP, referrals, waiting lists, medication, eyes and teeth", "menu": "real:care"},
		{"id": "body_years", "name": "Your body over time", "icon": "@pulse", "min": 6, "sub": "Movement, sleep, diet and what the years add up to", "menu": "real:body"},
		{"id": "medical_record", "name": "Medical record", "icon": "🫀", "min": 0, "sub": "Symptoms, diagnoses, injuries and chronic care", "menu": "exp:medical"},
		{"id": "mental_health", "name": "Mental health", "icon": "🧠", "min": 10, "sub": "Therapy, support, psychiatry and recovery", "menu": "exp:mental"},
		{"id": "salon", "name": "Salon & Spa", "icon": "💇", "min": 10, "sub": "Hair, nails, tattoos, massages", "menu": "daily:salon"},
		{"id": "surgeries", "name": "Plastic surgery", "icon": "💉", "min": 18, "sub": "Nose, face, lipo, veneers…", "menu": "daily:surgery"},
		{"id": "therapy", "name": "Therapy", "icon": "🛋️", "min": 10, "sub": "$120 · stress"},
		{"id": "treat", "name": "Treat an old injury", "icon": "🩼", "min": 16, "sub": "$15,000 · surgery or long therapy for a scar"},
		{"id": "rehab", "name": "Recovery & support", "icon": "🌱", "min": 14, "sub": "Plans, sessions, aftercare" , "menu": "journey:resilience"},
	]},
	{"id": "outdoors", "name": "Outdoors", "icon": "🌲", "sub": "Camping, hiking, fishing, caves", "items": [
		{"id": "camp", "name": "Camping", "icon": "🏕️", "min": 6, "sub": "Bring someone along", "panel": true},
		{"id": "hike", "name": "Hiking", "icon": "🥾", "min": 8, "sub": "Wildlife, finds, fresh air"},
		{"id": "fish", "name": "Fishing", "icon": "🎣", "min": 6, "sub": "Minigame · a rod helps"},
		{"id": "sea_fish", "name": "Deep-sea fishing", "icon": "🚤", "min": 16, "sub": "Minigame · boating license or your own boat"},
		{"id": "dirtbike", "name": "Dirt biking", "icon": "🏍️", "min": 16, "sub": "Motorcycle license · $150"},
		{"id": "cave", "name": "Cave diving", "icon": "🤿", "min": 18, "sub": "$400 · scuba certification · treasure and danger"},
		{"id": "hunt", "name": "Hunting", "icon": "🦌", "min": 16, "sub": "Hunting license and a bow or rifle · two tags a season"},
		{"id": "journal", "name": "Wildlife journal", "icon": "📓", "min": 6, "sub": "Everything you've spotted", "panel": true},
		{"id": "museum", "name": "Museum", "icon": "🏛️", "min": 10, "sub": "Donate finds and heirlooms", "panel": true},
	]},
	{"id": "become", "name": "Become a…", "icon": "✨", "sub": "Vampire, witch, royal, director, agent, casino, cult, zoo and more", "items": [
		{"id": "become_list", "name": "Become a…", "icon": "✨", "min": 14, "sub": "Everything you can set out to be, and what each one needs", "panel": true},
	]},
	{"id": "misc", "name": "Travel & Luck", "icon": "✈️", "sub": "Vacations, pets, casino, lottery, moving", "items": [
		{"id": "vacation", "name": "Vacation", "icon": "🏖️", "min": 18, "sub": "Nine kinds of trip", "menu": "daily:vacation"},
		{"id": "pet", "name": "Adopt a pet", "icon": "🐶", "min": 8, "sub": "A friend for life"},
		{"id": "pet_life", "name": "Pet life", "icon": "🐾", "min": 8, "sub": "Training, shows, health, breeding and pet business", "menu": "amb:pets"},
		{"id": "casino", "name": "Casino", "icon": "🎰", "min": 18, "sub": "Blackjack, roulette, slots, horses", "menu": "daily:casino"},
		{"id": "fight_bets", "name": "Fight night bets", "icon": "🥊", "min": 18, "sub": "Bet on the card, or take the fight yourself", "panel": true},
		{"id": "lottery", "name": "Lottery", "icon": "🎟️", "min": 18, "sub": "See the jackpot and your odds", "menu": "daily:lottery"},
		{"id": "emigrate", "name": "Emigrate", "icon": "🌍", "min": 18, "sub": "Start over abroad"},
		{"id": "relocate", "name": "Move to another city", "icon": "🚚", "min": 18, "sub": "Same country, new life", "panel": true},
	]},
]

const PRISON_ACTIONS := [
	{"id": "p_workout", "name": "Work out in the yard", "icon": "🏋️", "sub": "Health"},
	{"id": "p_read", "name": "Prison library", "icon": "📚", "sub": "Smarts"},
	{"id": "p_behave", "name": "Good behavior", "icon": "😇", "sub": "Chance of early release"},
	{"id": "p_appeal", "name": "Appeal your sentence", "icon": "⚖️", "sub": "$2,000 lawyer"},
	{"id": "p_job", "name": "Prison job", "icon": "🧺", "sub": "Laundry, kitchen, license plates · a little money, better parole odds"},
	{"id": "p_fight", "name": "Pick a fight", "icon": "🥊", "sub": "Minigame · earn respect or a trip to the infirmary"},
	{"id": "p_gang", "name": "Prison gang", "icon": "🦂", "sub": "Protection, respect, contraband"},
	{"id": "p_gamble", "name": "Card game with inmates", "icon": "🃏", "sub": "Bet commissary money"},
	{"id": "p_snitch", "name": "Snitch to the warden", "icon": "🐀", "sub": "Could shorten your sentence. Snitches get stitches."},
	{"id": "p_visit", "name": "Request a visit", "icon": "🫂", "sub": "See family or friends"},
	{"id": "p_escape", "name": "Attempt an escape", "icon": "🔓", "sub": "Minigame · outsmart the guards"},
	{"id": "p_riot", "name": "Start a riot", "icon": "🔥", "sub": "Chaos. Bad idea."},
	{"id": "p_card", "name": "Use Get Out of Jail Card", "icon": "🃏", "sub": "Life Modifier", "mod": "jail_card"},
]


func _cost(amount: int) -> int:
	return int(amount * float(ContentDB.country(GameState.player["country"]).get("cost", 1.0)) * Places.cost_mult() * World.cost_mult() * Expansion.era_cost_mult())


## How long you spend on something. Longer gives more, but never proportionally
## more - the fourth hour of a walk is worth less than the first - and it costs
## time points you cannot spend elsewhere that year. That trade is the point.
const DURATIONS := {
	"walk":     [["A quick loop", 1, 0.55, 0.0], ["An hour out", 1, 1.0, 0.0], ["Half the afternoon", 2, 1.7, 0.10], ["All day, miles of it", 3, 2.3, 0.28]],
	"gym":      [["A light session", 1, 0.6, 0.02], ["A full workout", 1, 1.0, 0.08], ["A long double session", 2, 1.65, 0.22], ["Train until I'm shaking", 3, 2.1, 0.42]],
	"meditate": [["Ten minutes", 1, 0.5, 0.0], ["A proper sit", 1, 1.0, 0.0], ["A half-day retreat", 2, 1.8, 0.0], ["A silent weekend", 3, 2.4, 0.12]],
	"library":  [["An hour skimming", 1, 0.5, 0.0], ["An afternoon", 1, 1.0, 0.05], ["Every evening this month", 2, 1.75, 0.20], ["Until closing, all term", 3, 2.3, 0.40]],
	"yoga":     [["A drop-in class", 1, 0.7, 0.0], ["A full course", 1, 1.0, 0.0], ["Intensive weekends", 2, 1.7, 0.10]],
	"games":    [["An hour", 1, 0.6, 0.0], ["An evening", 1, 1.0, 0.05], ["The entire weekend", 2, 1.6, 0.30]],
	"read":     [["A chapter", 1, 0.5, 0.0], ["A book", 1, 1.0, 0.0], ["A stack of them", 2, 1.8, 0.10]],
}

## Set for the duration of one activity call, then cleared.
var dur_mult := 1.0
var dur_time := 1
var dur_risk := 0.0
var dur_label := ""


## Which routine each activity can become, so the toggle lives inside the
## activity rather than beside it.
const ROUTINE_FOR := {"gym": "gym", "library": "study", "meditate": "meditate", "walk": "walk"}


func duration_choices(id: String) -> Array:
	return DURATIONS.get(id, [])


## Scale an authored effect set by how long the player committed. Costs (money)
## are scaled too - a longer gym block is a bigger bill.
func _dur(effects: Dictionary) -> Dictionary:
	if is_equal_approx(dur_mult, 1.0):
		return effects
	var out := {}
	for k in effects.keys():
		var v := float(effects[k])
		out[k] = int(round(v * dur_mult)) if k == "money" else v * dur_mult
	return out


func _dur_note() -> String:
	return "" if dur_label == "" else " (%s)" % dur_label.to_lower()


func _clear_dur() -> void:
	dur_mult = 1.0
	dur_time = 1
	dur_risk = 0.0
	dur_label = ""


## A read-only check: would this many time points fit, without spending them.
## Used by menus that want to grey a row out rather than fail on the click.
func _out_of_time_soft(cost: int) -> bool:
	return int(GameState.player.get("time_left", 0)) < cost


func _out_of_time() -> bool:
	if GameState.spend_time(dur_time):
		return false
	EventEngine.push_info("⏳", "Out of time", "That would take %d of your %d remaining time points this year.\nPress Age to move on, or pick a shorter option." % [dur_time, int(GameState.player["time_left"])])
	return true


func _done(icon: String, title: String, text: String, effects: Dictionary = {}, log_it: bool = true) -> void:
	var eff := _dur(effects)
	# Pushing far past a sensible length is its own consequence.
	if dur_risk > 0.0 and randf() < dur_risk:
		eff["stress"] = float(eff.get("stress", 0.0)) + 6.0
		eff["health"] = float(eff.get("health", 0.0)) - 3.0
		text += " I overdid it, and felt it for days afterwards."
	elif dur_label != "":
		text += _dur_note()
	var changes := GameState.apply_effects(Careers.scale_effects(eff))
	text += Careers.rep_note
	if log_it:
		GameState.add_log(text)
	EventEngine.push_info(icon, title, text, changes)


func _can_pay(amount: int, title: String) -> bool:
	if int(GameState.player["money"]) >= amount:
		return true
	EventEngine.push_info("💸", title, "You can't afford that. It costs %s." % GameState.fmt_money(amount))
	return false


# ---------------------------------------------------------------- activities

## Why a visit is justified right now, or "" if it is not. Also used by the menu
## so the row can explain itself instead of silently failing.
func doctor_reason() -> String:
	var p := GameState.player
	if p.is_empty():
		return ""
	if str(p.get("illness", "")) != "":
		return "I am ill"
	if GameState.stat("health") < 55.0:
		return "my health is poor"
	if not Expansion.symptoms().is_empty():
		return "I have symptoms I cannot explain"
	if Expansion.any_condition() or Expansion.any_injury():
		return "I have something ongoing to manage"
	if bool(p.get("expecting", false)):
		return "I am expecting"
	var last := int(p.get("last_checkup_age", -99))
	if int(p["age"]) - last >= 4:
		return "I am overdue a checkup"
	return ""


## Convenience has to be earned, and the hardest difficulty takes it away again.
## The point is that a shortcut should feel like something you unlocked by
## actually living, not a button that was always sitting there.
func batch_state() -> Dictionary:
	var p := GameState.player
	if p.is_empty():
		return {"ok": false, "why": "No life in progress."}
	if str(p.get("difficulty", "real")) == "gritty":
		return {"ok": false, "why": "Not on Gritty. Nothing here is convenient, including this."}
	var people := _batch_people()
	if people.size() < 4:
		return {"ok": false, "why": "You need at least four close people in your life. You have %d." % people.size()}
	var practice := GameState.get_counter("spend_time")
	if practice < 10:
		return {"ok": false, "why": "Unlocks after you have spent real time with people %d more times. (%d of 10)" % [10 - practice, practice]}
	return {"ok": true, "why": "%d people · costs %d time points" % [people.size(), _batch_cost(people.size())]}


func _batch_people() -> Array:
	var out: Array = []
	for rel in ["mother", "father", "sibling", "child", "partner", "best_friend", "friend", "grandparent", "grandchild"]:
		for id in GameState.npcs_with(rel):
			var n := GameState.npc(id)
			if int(n.get("closeness", 0)) >= 25 and n.get("species", "human") == "human":
				out.append(id)
	return out


func _batch_cost(n: int) -> int:
	return clampi(int(ceil(n / 3.0)), 1, 4)


## Spend an afternoon with everyone at once. Cheaper in time than doing it one by
## one, and worth less per person, because that is what a group visit is.
func hang_out_with_all() -> void:
	var st := batch_state()
	if not st["ok"]:
		EventEngine.push_info("👪", "Not available", str(st["why"]))
		return
	var people := _batch_people()
	var cost := _batch_cost(people.size())
	_clear_dur()
	dur_time = cost
	if _out_of_time():
		_clear_dur()
		return
	_clear_dur()
	var names: Array = []
	Lifestyle.note("social")
	for id in people:
		GameState.change_closeness(id, randi_range(3, 7))
		if names.size() < 4:
			names.append(GameState.npc(id)["first"])
	GameState.counter("group_gatherings")
	var who := ", ".join(names)
	if people.size() > names.size():
		who += " and %d others" % (people.size() - names.size())
	_done("👪", "Everyone in one room", "I got %s together in the same place. Nobody got my full attention, and everybody got some of it." % who, {"happiness": 6, "stress": 3})


func activity_available(item: Dictionary) -> bool:
	if int(GameState.player["age"]) < int(item.get("min", 0)):
		return false
	return Expansion.era_activity_block(str(item.get("id", ""))) == ""


const REPEAT := {
	"gym": [2, {"health": -3, "stress": 4}, "I pushed too hard at the gym and tweaked my back."],
	"meditate": [3, {}, ""],
	"walk": [3, {}, ""],
	"yoga": [2, {"stress": 2}, ""],
	"games": [2, {"health": -2, "smarts": -1, "stress": 3}, "Another all-nighter of games. My eyes hurt and I feel worse, not better."],
	"movie": [2, {"happiness": -1}, "I've seen everything worth seeing this year."],
	"read": [3, {"stress": 3}, ""],
	"concert": [2, {"health": -2}, ""],
	"nightlife": [2, {"health": -4, "looks": -1}, "Another late night. I'm starting to look like it."],
	"party": [1, {"happiness": -2}, "Another party? Half my friends made excuses. The other half left early."],
	"volunteer": [3, {}, ""],
	"make_friend": [2, {}, ""],
	"library": [2, {"stress": 6, "happiness": -3}, "I crammed until the words swam on the page. It mostly just stressed me out."],
	"course": [2, {"stress": 5}, "Too many courses at once. I'm retaining nothing."],
	"instrument": [2, {"stress": 3}, ""],
	"dentist": [1, {"money": -80}, "The dentist said my teeth are fine. The bill said otherwise."],
	"therapy": [3, {}, ""],
	"spa": [2, {"looks": -1, "money": -40}, "My skin is irritated from all the treatments."],
	"surgery": [1, {"health": -8, "looks": -6}, "The surgeon warned me against another procedure so soon. I didn't listen."],
	"doctor": [3, {}, ""],
	"hike": [3, {"health": -2, "stress": 2}, "My legs are done. I need a rest, not another trail."],
	"fish": [3, {}, ""],
	"sea_fish": [2, {"money": -200}, ""],
	"dirtbike": [2, {"health": -3}, ""],
	"cave": [2, {"health": -4, "stress": 5}, "One dive too many. I came up shaking."],
}
const HARD_CAP := {"party": 3, "surgery": 2, "dentist": 2}


## Entry point from the menus. If the activity supports a length, the player is
## asked how long before anything happens; the answer comes back through
## do_activity_for().
func do_activity(id: String) -> void:
	if DURATIONS.has(id) and not GameState.in_prison():
		var previous: Dictionary = GameState.player.get("activity_lengths",{})
		if not GameState.settings.get("ask_activity_length",true) and previous.has(id):
			do_activity_for(id,int(previous[id]))
			return
		_ask_duration(id)
		return
	_clear_dur()
	do_activity_for(id)


func _ask_duration(id: String) -> void:
	var opts: Array = DURATIONS[id]
	var choices: Array = []
	for i in range(opts.size()):
		var o: Array = opts[i]
		var cost := int(o[1])
		var sub := "%d time point%s" % [cost, "" if cost == 1 else "s"]
		if float(o[3]) >= 0.2:
			sub += " · you will probably overdo it"
		elif float(o[3]) > 0.0:
			sub += " · a chance of overdoing it"
		choices.append({
			"label": "%s  —  %s" % [str(o[0]), sub],
			"outcomes": [{"text": "", "no_friction": true, "activity_for": {"id": id, "index": i}}],
		})
	# The routine toggle belongs in the action's own flow, not as a row cluttering
	# the category list next to it.
	if ROUTINE_FOR.has(id):
		var rkey: String = ROUTINE_FOR[id]
		var on: bool = GameState.player["routines"].get(rkey, false)
		choices.append({
			"label": ("🔁  Stop doing this automatically every year" if on else "🔁  Make this a yearly routine") + "  —  1 time point a year",
			"outcomes": [{"text": "", "no_friction": true, "routine_toggle": rkey}],
		})
	choices.append({"label": "Never mind", "outcomes": [{"text": "", "no_friction": true}]})
	EventEngine.push_decision({
		"id": "_duration_" + id,
		"icon": "⏳",
		"title": "How long?",
		"text": "Longer gives you more, but never twice as much for twice the time - and the hours come out of the same year as everything else.",
		"no_friction": true,
		"choices": choices,
	})


func do_activity_for(id: String, index: int = -1) -> void:
	if not Lives.separate() and id in ["doctor","dentist","therapy"]:
		_clear_dur()
		if id=="doctor": Care.gp_visit()
		elif id=="dentist": Care.dentist()
		else: Expansion.mental_action("therapy")
		return
	if index >= 0 and DURATIONS.has(id):
		if not GameState.player.has("activity_lengths"): GameState.player["activity_lengths"]={}
		GameState.player["activity_lengths"][id]=clampi(index,0,(DURATIONS[id] as Array).size()-1)
		var o: Array = DURATIONS[id][clampi(index, 0, (DURATIONS[id] as Array).size() - 1)]
		dur_label = str(o[0])
		dur_time = int(o[1])
		dur_mult = float(o[2])
		dur_risk = float(o[3])
	var p := GameState.player
	if HARD_CAP.has(id) and int(p.get("act_year", {}).get(id, 0)) >= int(HARD_CAP[id]):
		EventEngine.push_info("🔁", "Not this year", {"party": "Nobody wants to come to another party of yours this year.", "surgery": "No reputable surgeon will operate on you again this year.", "dentist": "The dentist's office has stopped taking your calls this year."}[id])
		return
	var wb := World.blocked(id)
	if wb != "":
		EventEngine.push_info("🌍", "Not possible right now", wb)
		return
	var tl0 := int(p["time_left"])
	var log_before := int(GameState.log_years[-1]["lines"].size()) if not GameState.log_years.is_empty() else 0
	if REPEAT.has(id):
		var r: Array = REPEAT[id]
		Careers.rep_begin(id, int(r[0]), r[1], ("\n\n" + r[2]) if r[2] != "" else "")
	_do_activity(id)
	if int(p["time_left"]) != tl0:
		if not GameState.log_years.is_empty() and GameState.log_years[-1]["lines"].size()>log_before: Lifestyle.note(id)
		Destiny.on_activity(id)
		# Counted, so "spent enough time on this" can be a real prerequisite in
		# the Become a... menu rather than a flag set by one visit.
		Become.note_activity(id)
	if REPEAT.has(id) and int(p["time_left"]) == tl0 and p.has("act_year"):
		p["act_year"][id] = maxi(0, int(p["act_year"].get(id, 1)) - 1)
	Careers.rep_end()
	_clear_dur()


func _do_activity(id: String) -> void:
	var p := GameState.player
	if GameState.in_prison() and not id.begins_with("p_"):
		EventEngine.push_info("⛓️", "Not now", "You're in prison.")
		return
	if id in ["hike", "fish", "sea_fish", "dirtbike", "cave", "hunt"]:
		Empires.outdoor(id)
		return
	if id == "lay_low":
		Empires.lay_low()
		return
	match id:
		"gym":
			if _out_of_time(): return
			var roll := randf()
			if roll < 0.08:
				_done("🏋️", "Gym", "I pulled a muscle at the gym.", {"health": -4, "happiness": -2})
			else:
				_done("🏋️", "Gym", "I had a great workout at the gym.", {"health": 4, "looks": 2, "stress": -4, "happiness": 2})
		"meditate":
			if _out_of_time(): return
			_done("🧘", "Meditation", "I meditated and felt calmer.", {"stress": -8, "happiness": 3})
		"walk":
			if _out_of_time(): return
			var lines := ["I went for a long walk through the park.", "I took a walk and watched the sunset.", "I walked around the neighborhood and waved at the neighbors."]
			_done("🚶", "Walk", lines[randi() % lines.size()], {"health": 2, "happiness": 3, "stress": -3})
		"yoga":
			if _out_of_time(): return
			if not _can_pay(_cost(40), "Yoga"): return
			_done("🤸", "Yoga", "I went to a yoga class and felt limber.", {"money": -_cost(40), "health": 3, "stress": -6, "looks": 1})
		"games":
			if _out_of_time(): return
			_done("🎮", "Video games", "I lost a whole afternoon to video games.", {"happiness": 5, "stress": -3, "health": -1})
		"movie":
			if _out_of_time(): return
			if not _can_pay(_cost(15), "Movies"): return
			var genres := ["a horror movie", "a romantic comedy", "an action blockbuster", "an animated film", "a slow art-house drama"]
			_done("🎬", "Movie theater", "I watched %s at the theater." % genres[randi() % genres.size()], {"money": -_cost(15), "happiness": 4})
		"read":
			if _out_of_time(): return
			_done("📖", "Reading", "I read a book cover to cover.", {"smarts": 3, "happiness": 2, "stress": -2})
		"concert":
			if _out_of_time(): return
			if not _can_pay(_cost(90), "Concert"): return
			_done("🎤", "Concert", "I went to a concert and sang until my voice gave out.", {"money": -_cost(90), "happiness": 8, "stress": -4})
		"nightlife":
			if int(p["age"]) < int(Places.law("drink")):
				EventEngine.push_info("🪩", "ID check", "Clubs in %s won't let you in until %d." % [Places.region()["city"], int(Places.law("drink"))])
				return
			if _out_of_time(): return
			if not _can_pay(_cost(60), "Nightlife"): return
			Grit.habit("partying", 8)
			if randf() < 0.35:
				var fid := GameState.create_npc("friend", {"age": p["age"] + randi_range(-3, 3), "closeness": 50})
				_done("🪩", "Nightlife", "I went clubbing and made a new friend, %s." % GameState.npcs[fid]["first"], {"money": -_cost(60), "happiness": 6, "health": -1})
			elif randf() < 0.15:
				_done("🪩", "Nightlife", "I had one too many and woke up with a brutal hangover.", {"money": -_cost(60), "health": -4, "happiness": -2})
			else:
				_done("🪩", "Nightlife", "I danced all night.", {"money": -_cost(60), "happiness": 6, "stress": -4})
		"party":
			if _out_of_time(): return
			if not _can_pay(_cost(300), "Party"): return
			Grit.habit("partying", 6)
			for rel in ["friend", "best_friend"]:
				for fid in GameState.npcs_with(rel):
					GameState.change_closeness(fid, 8)
			if randf() < 0.2:
				_done("🎉", "Party", "My party got loud and the neighbors called the police.", {"money": -_cost(300), "happiness": 3, "stress": 4})
			else:
				_done("🎉", "Party", "I threw a party. Everyone is still talking about it.", {"money": -_cost(300), "happiness": 9})
		"volunteer":
			if _out_of_time(): return
			var places := ["an animal shelter", "a soup kitchen", "a retirement home", "a beach cleanup"]
			_done("🤝", "Volunteering", "I volunteered at %s." % places[randi() % places.size()], {"happiness": 5, "karma": 6, "stress": -2})
		"make_friend":
			if _out_of_time(): return
			if randf() < 0.65:
				var fid := GameState.create_npc("friend", {"age": maxi(5, p["age"] + randi_range(-2, 2)), "closeness": 55})
				_done("🙋", "New friend", "I made a new friend: %s." % GameState.npcs[fid]["first"], {"happiness": 5})
			else:
				_done("🙋", "New friend", "I tried to make friends, but it was awkward.", {"happiness": -2})
		"library":
			if _out_of_time(): return
			if GameState.in_school() or GameState.in_university():
				p["education"]["studied"] = true
				_done("📚", "Library", "I studied hard at the library.", {"smarts": 2, "school": 6, "stress": 2})
			else:
				_done("📚", "Library", "I spent the day reading at the library.", {"smarts": 3, "happiness": 1})
		"course":
			if _out_of_time(): return
			if not _can_pay(_cost(200), "Online course"): return
			var topics := ["coding", "personal finance", "photography", "a new language", "public speaking"]
			_done("💻", "Online course", "I finished an online course in %s." % topics[randi() % topics.size()], {"money": -_cost(200), "smarts": 5, "job_perf": 4})
		"instrument":
			if _out_of_time(): return
			if not _can_pay(_cost(120), "Music lessons"): return
			GameState.counter("music")
			var inst := ["guitar", "piano", "drums", "violin", "saxophone"]
			_done("🎸", "Music lessons", "I took %s lessons." % inst[randi() % inst.size()], {"money": -_cost(120), "happiness": 4, "smarts": 1})
		"date", "dating_app":
			if int(p["age"]) < 18 and id == "dating_app": return
			if _out_of_time(): return
			_find_date(id == "dating_app")
		"shoplift": _crime("shoplift", "shoplifted", 0.75, [20, 150], [0, 0], 300)
		"pickpocket": _crime("pickpocket", "pickpocketed a stranger", 0.65, [40, 400], [0, 1], 500)
		"burglary":
			if _out_of_time(): return
			GameState.counter("crimes")
			var gear := {"lockpick": Shop.has_tag("lockpick"), "nightvision": Shop.has_tag("nightvision"), "disguise": Shop.has_tag("disguise")}
			var diff := 0.75 if Lives.has_power("invisibility") else 1.0
			Minigames.play("burglary", {"skill": 35 + GameState.stat("smarts") * 0.2 + (15 if gear["lockpick"] else 0) + (10 if gear["nightvision"] else 0), "difficulty": diff, "gear": gear}, Callable(self, "_burgle_done").bind(gear))
		"car_theft": _crime("grand theft auto", "stole a car", 0.5, [3000, 15000], [2, 5], 0)
		"bank_robbery": _crime("armed robbery", "robbed a bank", 0.3, [40000, 400000], [8, 20], 0)
		"doctor":
			# You need a reason to be there. A clinic is not a stat vending machine,
			# and "I felt fine and went anyway" is how the old version let players
			# top up health every single year for the price of a click.
			var why := doctor_reason()
			if why == "":
				EventEngine.push_info("🩺", "No reason to go", "I am not ill, not injured, and I had a checkup recently. The receptionist offered me an appointment in four months and I took the card.\n\nCome back when something is actually wrong, or when a few years have passed.")
				return
			if _out_of_time(): return
			p["last_checkup_age"] = int(p["age"])
			var fee := int(_cost(150) * Places.healthcare_mult())
			var doc := Web.contact(["doctor", "nurse"], 50)
			if doc != "":
				fee = 0
				GameState.change_closeness(doc, 3)
			if not _can_pay(fee, "Doctor"): return
			if p["illness"] != "":
				var cure := (0.9 if doc != "" else 0.75) * (0.3 if p["illness"] == "cancer" else 1.0)
				if randf() < cure:
					var what: String = p["illness"]
					p["illness"] = ""
					_done("🩺", "Doctor", "The doctor treated my %s. I'm feeling much better." % what, {"money": -fee, "health": 10, "happiness": 4})
				else:
					_done("🩺", "Doctor", "The doctor tried a treatment for %s, but it didn't help yet." % p["illness"], {"money": -fee, "health": 2})
			else:
				_done("🩺", "Doctor", ("%s gave me a free checkup. " % GameState.npc(doc)["first"] if doc != "" else "I got a checkup. ") + "I'm in decent shape.", {"money": -fee, "health": 3})
		"dentist":
			if _out_of_time(): return
			if not _can_pay(_cost(120), "Dentist"): return
			_done("🦷", "Dentist", "I had my teeth cleaned. Sparkling.", {"money": -_cost(120), "looks": 2, "health": 1})
		"rehab":
			Grit.rehab()
		"treat":
			Grit.treat_scar()
		"therapy":
			if _out_of_time(): return
			if not _can_pay(_cost(120), "Therapy"): return
			Grit.therapy_helps()
			_done("🛋️", "Therapy", "I talked through what's been weighing on me with a therapist.", {"money": -_cost(120), "stress": -15, "happiness": 5})
		"spa":
			if _out_of_time(): return
			if not _can_pay(_cost(80), "Salon & Spa"): return
			_done("💅", "Salon & Spa", "I got pampered at the salon and spa.", {"money": -_cost(80), "looks": 3, "stress": -4})
		"surgery":
			if _out_of_time(): return
			var price := _cost(6000)
			if not _can_pay(price, "Plastic surgery"): return
			if randf() < 0.78:
				_done("💉", "Plastic surgery", "The surgery went perfectly. I barely recognize myself.", {"money": -price, "looks": 15, "happiness": 6})
			else:
				_done("💉", "Plastic surgery", "The surgery was botched. I look worse than before.", {"money": -price, "looks": -15, "happiness": -10, "health": -5})
		"vacation":
			_vacation()
		"pet":
			_adopt_pet()
		"casino":
			_casino()
		"lottery":
			if _out_of_time(): return
			if not _can_pay(10, "Lottery"): return
			GameState.counter("gambles")
			Grit.habit("gambling", 3)
			var r := randf()
			if r < 0.00005:
				_done("🎟️", "JACKPOT", "I WON THE LOTTERY JACKPOT: $25,000,000!", {"money": 25000000 - 10, "happiness": 30})
				GameState.add_milestone(p["age"], "won the lottery jackpot")
			elif r < 0.06:
				var prize: int = [20, 50, 100, 500, 1000][randi() % 5]
				_done("🎟️", "Lottery", "I won %s on a lottery ticket!" % GameState.fmt_money(prize), {"money": prize - 10, "happiness": 3})
			else:
				_done("🎟️", "Lottery", "My lottery ticket was a dud.", {"money": -10}, false)
		"emigrate":
			_emigrate()
		"p_workout":
			if _out_of_time(): return
			_done("🏋️", "Prison yard", "I lifted weights in the yard.", {"health": 4, "looks": 1, "stress": -3})
		"p_read":
			if _out_of_time(): return
			_done("📚", "Prison library", "I read everything the prison library had.", {"smarts": 3, "stress": -2})
		"p_behave":
			if _out_of_time(): return
			if randf() < 0.12 and int(p["prison"]) > 1:
				p["prison"] = 1
				_done("😇", "Good behavior", "The parole board noticed my behavior. I'll be out next year.", {"happiness": 10})
			else:
				_done("😇", "Good behavior", "I kept my head down and followed the rules.", {"karma": 2})
		"p_appeal":
			if _out_of_time(): return
			if not _can_pay(2000, "Appeal"): return
			if randf() < 0.18:
				p["prison"] = 0
				GameState.add_milestone(p["age"], "won an appeal and walked free")
				_done("⚖️", "Appeal", "My appeal succeeded. I'm free!", {"money": -2000, "happiness": 25})
			else:
				_done("⚖️", "Appeal", "My appeal was denied.", {"money": -2000, "happiness": -4})
		"p_card":
			if not Meta.has_mod("jail_card"):
				return
			if int(p.get("jail_card_year", -1)) == GameState.year_now():
				EventEngine.push_info("🃏", "Get Out of Jail Card", "You already used it this year.")
				return
			Law.use_jail_card()
			GameState.add_milestone(p["age"], "walked out of prison with a Get Out of Jail Card")
			_done("🃏", "Free!", "I played my Get Out of Jail Card. I'm free and my record is clean.", {"happiness": 20})
		"p_job", "p_fight", "p_gang", "p_gamble", "p_snitch", "p_visit", "p_escape":
			_prison_act(id)
		"p_riot":
			if _out_of_time(): return
			if randf() < 0.5:
				p["prison"] = int(p["prison"]) + 2
				_done("🔥", "Riot", "The riot failed. Two more years were added to my sentence.", {"health": -6, "karma": -5})
			else:
				_done("🔥", "Riot", "The riot fizzled out. Nobody knows I started it.", {"stress": 4, "karma": -3})


func _crime(crime: String, verb: String, success: float, loot: Array, jail: Array, fine: int) -> void:
	if _out_of_time(): return
	var p := GameState.player
	GameState.counter("crimes")
	var chance := success
	if GameState.has_trait("Athletic"):
		chance += 0.05
	if Lives.has_power("invisibility"):
		chance += 0.25
	if randf() < chance:
		var amount := randi_range(int(loot[0]), int(loot[1]))
		# Getting away with it still counts. Stars track what you did, not what
		# you were convicted of.
		Wanted.commit(crime, false)
		_done("🥷", "Crime", "I %s and got away with %s." % [verb, GameState.fmt_money(amount)], {"money": amount, "karma": -6, "stress": 4, "happiness": 2, "heat": 6 + int(jail[1]) * 2})
		return
	Wanted.commit(crime, true)
	p["record"].append(crime)
	if int(jail[1]) == 0 or randf() < 0.3:
		var f := _cost(fine if fine > 0 else 1000)
		_done("🚓", "Busted", "I got caught trying to %s. I was fined %s." % [crime, GameState.fmt_money(f)], {"money": -f, "karma": -4, "happiness": -6})
		return
	var lo := maxi(1, int(jail[0]))
	var hi := int(jail[1])
	if int(p["age"]) < 18:
		hi = mini(hi, 2)
		lo = mini(lo, hi)
	GameState.add_log("I was arrested for %s." % crime)
	Law.trial(crime, lo, hi)


func _prison_act(id: String) -> void:
	var p := GameState.player
	if _out_of_time(): return
	var rep := int(p.get("prison_rep", 20))
	match id:
		"p_job":
			var jobs := [["🧺", "the laundry"], ["🍲", "the kitchen"], ["🚗", "the license plate shop"], ["📚", "the library cart"], ["🌱", "the prison garden"]]
			var j: Array = jobs[randi() % jobs.size()]
			var pay := randi_range(120, 400)
			p["prison_job_years"] = int(p.get("prison_job_years", 0)) + 1
			_done(j[0], "Prison job", "I worked a shift in %s. It pays %s a year, but it breaks up the days." % [j[1], GameState.fmt_money(pay)], {"money": pay, "stress": -3, "karma": 1})
		"p_fight":
			var opp: String = ["Tiny", "Knuckles", "Big Sal", "Razor", "Moose", "Deacon", "Ghost", "Brick"][randi() % 8]
			Minigames.play("fight", {"skill": 30 + GameState.stat("health") * 0.3 + Daily.fight_bonus() * 100.0, "difficulty": 1.0, "opponent": opp}, func(s: float, _d: Dictionary) -> void:
				if s >= 0.5:
					p["prison_rep"] = mini(100, rep + 15)
					GameState.counter("fights_won")
					_done("🥊", "Yard fight", "I knocked out %s in the yard. Nobody's going to test me now." % opp, {"health": -4, "karma": -3, "stress": -4})
				else:
					p["prison_rep"] = maxi(0, rep - 8)
					_done("🤕", "Yard fight", "%s beat me senseless. I spent a week in the infirmary." % opp, {"health": -14, "happiness": -6})
				if randf() < 0.25:
					p["prison"] = int(p["prison"]) + 1
					GameState.add_log("The guards saw the fight. A year was added to my sentence."))
		"p_gang":
			var gang: String = str(p.get("prison_gang", ""))
			if gang == "":
				var gangs := ["the Iron Serpents", "the Northside Kings", "the Brotherhood of Ash", "Los Cuervos", "the Ninth Street Saints"]
				var g: String = gangs[randi() % gangs.size()]
				if rep < 25 and randf() < 0.5:
					_done("🦂", "Prison gang", "%s told me to come back when I'd earned some respect." % g.capitalize(), {"happiness": -3})
					return
				p["prison_gang"] = g
				GameState.add_milestone(p["age"], "joined a prison gang")
				_done("🦂", "Prison gang", "I'm with %s now. They've got my back, and I've got theirs." % g, {"karma": -6, "stress": -6})
			else:
				if randf() < 0.3:
					p["prison"] = int(p["prison"]) + 2
					_done("🚨", "Contraband", "The guards found the contraband %s had me holding. Two more years." % gang, {"happiness": -10})
				else:
					var cut := randi_range(300, 2500)
					p["prison_rep"] = mini(100, rep + 6)
					_done("📦", "Gang business", "I moved contraband for %s. My cut: %s." % [gang, GameState.fmt_money(cut)], {"money": cut, "karma": -4})
		"p_gamble":
			var stake := randi_range(20, 120)
			var win := randf() < 0.45 * Shop.luck()
			Grit.habit("gambling", 4)
			if win:
				_done("🃏", "Cell block poker", "I cleaned out the table and won %s in commissary money." % GameState.fmt_money(stake * 2), {"money": stake * 2, "happiness": 4})
			elif randf() < 0.2:
				p["prison_rep"] = maxi(0, rep - 5)
				_done("🃏", "Cell block poker", "I lost %s and then accused a guy of cheating. Bad idea." % GameState.fmt_money(stake), {"money": -stake, "health": -8})
			else:
				_done("🃏", "Cell block poker", "I lost %s at cards." % GameState.fmt_money(stake), {"money": -stake, "happiness": -2})
		"p_snitch":
			if randf() < 0.35 and int(p["prison"]) > 1:
				p["prison"] = int(p["prison"]) - 1
				_done("🐀", "Snitch", "The warden took a year off my sentence for the tip.", {"karma": -3})
			else:
				_done("🐀", "Snitch", "The warden took my tip and gave me nothing.", {"karma": -2})
			if randf() < (0.6 if str(p.get("prison_gang", "")) != "" else 0.3):
				p["prison_gang"] = ""
				p["prison_rep"] = 0
				GameState.apply_effects({"health": -18})
				GameState.add_log("Word got out that I talked. I was jumped in the shower.")
		"p_visit":
			var fam: Array = []
			for rel in ["mother", "father", "partner", "child", "sibling", "best_friend", "friend"]:
				for nid in GameState.npcs_with(rel):
					if int(GameState.npcs[nid]["closeness"]) >= 25:
						fam.append(nid)
			if fam.is_empty():
				_done("🫂", "Visiting hours", "Nobody came. I sat in the visiting room for an hour anyway.", {"happiness": -8})
				return
			var who: String = fam[randi() % fam.size()]
			GameState.change_closeness(who, 6)
			_done("🫂", "Visiting hours", "%s came to see me. We talked through the glass until the guard called time." % GameState.full_name(who), {"happiness": 8, "stress": -5})
		"p_escape":
			var diff := 1.0 + clampf(float(p["prison"]) / 20.0, 0.0, 0.4)
			Minigames.play("escape", {"skill": 30 + GameState.stat("smarts") * 0.3, "difficulty": diff}, Callable(self, "_escape_done"))


func _escape_done(score: float, detail: Dictionary) -> void:
	var p := GameState.player
	var ok: bool = detail.get("success", false) if not detail.get("auto", false) else score >= 0.62
	if ok:
		p["escaped_years"] = int(p["prison"])
		p["prison"] = 0
		GameState.set_flag("fugitive")
		GameState.counter("escapes")
		GameState.add_milestone(p["age"], "escaped from prison")
		_done("🔓", "Escape!", "I made it over the fence and into the woods. I'm a fugitive now. Every siren makes my heart stop.", {"happiness": 20, "heat": 60, "stress": 15})
	else:
		p["prison"] = int(p["prison"]) + 3
		p["prison_rep"] = mini(100, int(p.get("prison_rep", 20)) + 5)
		_done("🚨", "Escape failed", "They caught me before I reached the fence. Three more years, and a month in solitary.", {"happiness": -12, "health": -4})


func fugitive_yearly() -> void:
	var p := GameState.player
	if not GameState.has_flag("fugitive") or GameState.in_prison():
		return
	var chance := 0.12 + float(p.get("heat", 0.0)) / 400.0
	if Shop.has_tag("disguise"):
		chance *= 0.6
	if randf() < chance:
		GameState.flags.erase("fugitive")
		var yrs := int(p.get("escaped_years", 2)) + 3
		GameState.add_log("The marshals found me. I'm going back to prison.")
		GameState.add_milestone(p["age"], "was recaptured after escaping")
		go_to_prison(yrs, "escape")


func _burgle_done(score: float, detail: Dictionary, gear: Dictionary) -> void:
	var p := GameState.player
	if detail.get("auto", false):
		var ok := score >= 0.4
		detail = {"caught": not ok, "woke": score < 0.55, "items": []}
		if ok:
			var picks := [["💵", "Cash", randi_range(300, 2500), true], ["💍", "Ring", randi_range(1500, 6000), false], ["💻", "Laptop", randi_range(500, 1400), true], ["🖼️", "Painting", randi_range(1000, 9000), false], ["⌚", "Watch", randi_range(900, 4000), false]]
			picks.shuffle()
			detail["items"] = picks.slice(0, 1 + int(score * 3))
	if detail.get("caught", false):
		if gear.get("disguise", false) and randf() < 0.4:
			_done("🥸", "Burglary", "They caught me in the hallway, but in the fake mustache they'll never pick me out of a lineup. I ran.", {"karma": -4, "stress": 10, "heat": 6})
			return
		p["record"].append("burglary")
		GameState.add_log("I was arrested for burglary.")
		Law.trial("burglary", 1, 4)
		return
	var cash := 0
	var goods: Array = []
	for it in detail.get("items", []):
		if bool(it[3]):
			cash += int(it[2]) if it[1] == "Cash" else int(int(it[2]) * 0.5)
		else:
			goods.append(it)
			p["possessions"].append({"name": "Stolen " + str(it[1]).to_lower(), "icon": it[0], "cat": "Stolen", "value": int(it[2]), "vol": 0.1, "bought": 0, "heirloom": false, "stolen": true})
	if cash == 0 and goods.is_empty():
		_done("🥷", "Burglary", "I broke in and left empty-handed. At least nobody saw me.", {"karma": -2, "stress": 4})
		return
	var txt := "I broke into a house"
	if cash > 0:
		txt += " and walked away with %s in cash and quick-sale electronics" % GameState.fmt_money(cash)
	if not goods.is_empty():
		var names: Array = []
		for g in goods:
			names.append(str(g[1]).to_lower())
		txt += "%s took a %s. I'll need a fence for that: the Black Market" % [". I also" if cash > 0 else " and", ", ".join(names)]
	GameState.counter("burglaries")
	_done("🥷", "Burglary", txt + ".", {"money": cash, "karma": -6, "heat": 14 if detail.get("woke", false) else 8, "stress": 6 if detail.get("woke", false) else 3, "happiness": 2})


func _burgle_item() -> void:
	if _out_of_time(): return
	var p := GameState.player
	GameState.counter("crimes")
	if randf() < 0.55:
		var loot := [["🖼️", "Stolen painting", 8000], ["💎", "Stolen necklace", 12000], ["⌚", "Stolen watch", 5000], ["🪙", "Stolen coin collection", 3500], ["🎸", "Stolen vintage guitar", 9000]]
		var it: Array = loot[randi() % loot.size()]
		p["possessions"].append({"name": it[1], "icon": it[0], "cat": "Stolen", "value": int(it[2] * randf_range(0.6, 1.4)), "vol": 0.1, "bought": 0, "heirloom": false, "stolen": true})
		_done("🦹", "Burglary", "I broke into a house and took a %s. I'll need a fence to sell it: the Black Market." % it[1].to_lower().replace("stolen ", ""), {"karma": -6, "heat": 10, "stress": 4})
	else:
		p["record"].append("burglary")
		GameState.add_log("I was arrested for burglary.")
		Law.trial("burglary", 1, 4)


func go_to_prison(years: int, crime: String) -> void:
	var p := GameState.player
	if years > 0:
		years = maxi(1, int(round(years * Grit.d("sentence") * float(Places.law("police")) * Wanted.sentence_mult())))
	if Grit.has_boon("clean_slate") and not GameState.has_flag("clean_slate_used"):
		GameState.set_flag("clean_slate_used")
		years = 0
	if years <= 0:
		if not p["record"].has(crime):
			p["record"].append(crime)
		p["money"] = int(p["money"]) - 1000
		GameState.add_log("I got off with probation and a $1,000 fine for %s." % crime)
		return
	if GameState.has_job():
		lose_job("prison")
	if not p.get("career", {}).is_empty():
		Careers.quit("prison")
	p["prison"] = int(p["prison"]) + years
	if not p["record"].has(crime):
		p["record"].append(crime)
	GameState.add_log("I was sentenced to %d year%s in prison for %s." % [years, "" if years == 1 else "s", crime])
	GameState.add_milestone(p["age"], "was sentenced to %d years in prison for %s" % [years, crime])
	Wanted.serve_time(years)
	GameState.apply_effects({"happiness": -20, "stress": 15})
	Grit.change_credit(-60)
	if p["partner"] != "":
		GameState.change_closeness(p["partner"], -15)
	if p["education"]["uni"].size() > 0:
		p["education"]["uni"] = {}
		GameState.add_log("I was expelled from university.")
	GameState.emit_changed()


func _find_date(app: bool) -> void:
	var p := GameState.player
	var want: String = "female" if p["gender"] == "male" else ("male" if p["gender"] == "female" else ("male" if randf() < 0.5 else "female"))
	if randf() < 0.15:
		want = p["gender"] if p["gender"] != "nonbinary" else "nonbinary"
	var age: int = p["age"]
	var lo := maxi(14, age - 4) if age < 18 else maxi(18, age - 8)
	var hi := mini(17, age + 2) if age < 18 else age + 8
	var cid := GameState.create_npc("crush", {"gender": want, "age": randi_range(lo, maxi(lo, hi)), "closeness": 30})
	var c: Dictionary = GameState.npcs[cid]
	var chance := 0.35 + (GameState.stat("looks") - 50.0) / 150.0 + (0.1 if GameState.has_trait("Charmer") else 0.0)
	if app:
		chance += 0.1
	var choices: Array = [
		{"label": "Ask them out", "outcomes": [
			{"weight": chance, "text": "%s said yes! We're dating now." % c["first"], "new_partner": "them", "keep_role": "them", "effects": {"happiness": 8}},
			{"weight": 1.0 - chance, "text": "%s turned me down." % c["first"], "effects": {"happiness": -4}},
		]},
		{"label": "Not my type", "outcomes": [{"text": "I decided %s wasn't for me." % c["first"]}]},
	]
	var where: String = "on a dating app" if app else ["at a coffee shop", "at a friend's party", "at the gym", "in a bookstore"][randi() % 4]
	var body := "You met %s (%d) %s.\nLooks: %d%%  ·  Trait: %s" % [GameState.full_name(cid), int(c["age"]), where, int(c["looks"]), c["trait"]]
	if p["partner"] != "":
		body += "\n\nYou're already with %s. Dating someone else would be cheating." % GameState.npcs[p["partner"]]["first"]
	EventEngine.push_decision({"id": "_date", "icon": "💘", "title": "A potential match", "text": body, "choices": choices, "discard_unkept": true}, {"them": cid})


func start_dating(id: String, announce: bool = true) -> void:
	var p := GameState.player
	if not GameState.npcs.has(id):
		return
	if p["partner"] != "" and p["partner"] != id and GameState.npcs.has(p["partner"]):
		var old: Dictionary = GameState.npcs[p["partner"]]
		old["relation"] = "ex"
		old["closeness"] = 5
		GameState.add_log("%s found out I was seeing someone else and dumped me." % old["first"])
		GameState.apply_effects({"karma": -8, "happiness": -5})
	var n: Dictionary = GameState.npcs[id]
	var came_from := str(n.get("relation", ""))
	n["relation"] = "partner"
	n["closeness"] = maxi(int(n["closeness"]), 62)
	p["partner"] = id
	p["partner_status"] = "dating"
	GameState.counter("partners")
	# The relationship itself now has a life: a start date, a stage, and beats.
	Romance.began(id, came_from)
	if announce:
		GameState.add_log("I started dating %s." % n["first"])
	GameState.emit_changed()


func _underground_casino() -> void:
	if _out_of_time(): return
	var p := GameState.player
	EventEngine.push_decision({"id": "_underground", "icon": "🎲", "title": "Underground casino", "text": "Gambling is illegal in %s. A man in a leather jacket knows a back room." % Places.region()["city"], "choices": [
		{"label": "Bet $1,000", "requires": {"money": 1000}, "outcomes": [
			{"weight": 40, "text": "I won $1,000 at a back-room card table.", "effects": {"money": 1000, "heat": 4}, "counter": {"gambles": 1}, "habit": ["gambling", 9]},
			{"weight": 45, "text": "I lost $1,000. Nobody here gives refunds.", "effects": {"money": -1000, "heat": 4}, "counter": {"gambles": 1}, "habit": ["gambling", 9]},
			{"weight": 15, "text": "Police raided the room. I was arrested with everyone else.", "effects": {"money": -1000}, "trial": ["illegal gambling", 1, 1]}]},
		{"label": "Walk away", "outcomes": [{"text": ""}]},
	]})


func _vacation() -> void:
	var trips := [
		{"label": "Beach resort ($3,000)", "cost": 3000, "place": "a beach resort"},
		{"label": "City break ($1,800)", "cost": 1800, "place": "a big-city getaway"},
		{"label": "Mountain cabin ($1,200)", "cost": 1200, "place": "a cabin in the mountains"},
		{"label": "Backpacking ($700)", "cost": 700, "place": "a backpacking trip"},
	]
	if _out_of_time(): return
	var choices: Array = []
	for t in trips:
		var c := _cost(int(t["cost"]))
		choices.append({"label": t["label"].replace(GameState.fmt_money(int(t["cost"])), GameState.fmt_money(c)), "requires": {"money": c}, "outcomes": [
			{"weight": 7, "text": "I had an amazing time on %s." % t["place"], "effects": {"money": -c, "happiness": 12, "stress": -12}, "counter": {"vacations": 1}},
			{"weight": 2, "text": "My luggage got lost on %s, but I still had fun." % t["place"], "effects": {"money": -c, "happiness": 5, "stress": -5}, "counter": {"vacations": 1}},
			{"weight": 1, "text": "I got food poisoning on %s." % t["place"], "effects": {"money": -c, "health": -6, "happiness": -3}, "counter": {"vacations": 1}},
		]})
	if Lives.is_type("super") and Lives.has_power("flight"):
		choices.push_front({"label": "Fly there yourself (free)", "outcomes": [
			{"weight": 4, "text": "I flew to the other side of the world under my own power and was home by breakfast.", "effects": {"happiness": 14, "stress": -14}, "counter": {"vacations": 1}, "suspicion": 3},
			{"weight": 1, "text": "An airline pilot reported a person flying beside his plane. The news had fun with it.", "effects": {"happiness": 8, "stress": -6}, "counter": {"vacations": 1}, "suspicion": 12}]})
	choices.append({"label": "Stay home", "outcomes": [{"text": ""}]})
	EventEngine.push_decision({"id": "_vacation", "icon": "🏖️", "title": "Vacation", "text": "Where do you want to go?", "choices": choices})


func _adopt_pet() -> void:
	if _out_of_time(): return
	var opts := [["dog", 250], ["cat", 150], ["rabbit", 80], ["parrot", 400]]
	var choices: Array = []
	for o in opts:
		var price := _cost(int(o[1]))
		choices.append({"label": "Adopt a %s (%s)" % [o[0], GameState.fmt_money(price)], "requires": {"money": price}, "outcomes": [
			{"text": "I adopted a %s named {pet_%s.first}!" % [o[0], o[0]], "effects": {"money": -price, "happiness": 10, "stress": -3}, "keep_role": "pet_" + o[0]}
		]})
	choices.append({"label": "Just looking", "outcomes": [{"text": ""}]})
	var roles := {}
	for o in opts:
		var id := GameState.create_npc("pet", {"species": o[0], "first": ContentDB.random_pet_name(), "last": "", "age": randi_range(0, 3), "closeness": 70})
		roles["pet_" + o[0]] = id
	EventEngine.push_decision({"id": "_pet", "icon": "🐶", "title": "Animal shelter", "text": "Which pet do you want to bring home?", "choices": choices, "discard_unkept": true}, roles)


func _casino() -> void:
	var gl := str(Places.law("gambling"))
	if gl == "banned":
		_underground_casino()
		return
	if _out_of_time(): return
	var gam := GameState.has_trait("Gambler")
	var choices: Array = []
	for bet in [100, 1000, 10000]:
		choices.append({"label": "Bet %s" % GameState.fmt_money(bet), "requires": {"money": bet}, "outcomes": [
			{"weight": 46 if gam else 42, "text": "I won %s at blackjack!" % GameState.fmt_money(bet), "effects": {"money": bet, "happiness": 6}, "counter": {"gambles": 1}, "habit": ["gambling", 9]},
			{"weight": 54 if gam else 58, "text": "I lost %s at the tables." % GameState.fmt_money(bet), "effects": {"money": -bet, "happiness": -4, "stress": 3}, "counter": {"gambles": 1}, "habit": ["gambling", 9]},
			{"weight": 2, "text": "Jackpot on the slots! I won %s!" % GameState.fmt_money(bet * 20), "effects": {"money": bet * 20, "happiness": 12}, "counter": {"gambles": 1}, "habit": ["gambling", 9]},
		]})
	choices.append({"label": "Walk away", "outcomes": [{"text": ""}]})
	EventEngine.push_decision({"id": "_casino", "icon": "🎰", "title": "Casino", "text": "The tables are hot tonight. How much do you bet?", "choices": choices})


func _emigrate() -> void:
	var p := GameState.player
	if _out_of_time(): return
	var choices: Array = []
	for c in ContentDB.countries:
		if c["id"] == p["country"]:
			continue
		var fee := 0 if Meta.has_mod("golden_passport") else 2500
		var ok := clampf((0.85 if p["record"].is_empty() else 0.35) - Wanted.hiring_penalty()+Journey.modules["places"].migration_bonus(str(c["id"])),0.05,0.95)
		if Meta.has_mod("golden_passport"):
			ok = 1.0
		choices.append({"label": "%s %s" % [c.get("flag", ""), c["name"]], "requires": {"money": fee}, "outcomes": [
			{"weight": ok, "text": "I moved to %s." % c["name"], "effects": {"money": -fee, "happiness": 6, "stress": 5}, "emigrate": c["id"], "milestone": "emigrated to %s" % c["name"]},
			{"weight": 1.0 - ok, "text": "My visa application for %s was rejected." % c["name"], "effects": {"money": -fee / 5, "happiness": -5}},
		]})
	choices.append({"label": "Stay", "outcomes": [{"text": ""}]})
	EventEngine.push_decision({"id": "_emigrate", "icon": "🌍", "title": "Emigrate", "text": "Where do you want to start a new life? Visa fees cost $2,500.", "choices": choices})


func finish_emigration(country_id: String) -> void:
	var p := GameState.player
	# A warrant is a wall. You do not get to walk through passport control with
	# your photograph on somebody's list.
	if not Wanted.can_leave_country():
		GameState.add_log("They stopped me at the desk. My name came up, and I did not board.")
		Wanted.commit("attempted flight", true)
		Law.trial("attempting to flee the country", 1, 4)
		return
	p["country"] = country_id
	Journey.modules["places"].arrived(country_id)
	p["region"] = Places.random_region(country_id)
	var kept: Array = []
	var lost: Array = []
	for lic in p.get("licenses", []):
		if randf() < 0.55:
			kept.append(lic)
		else:
			lost.append(Law.LICENSES.get(lic, {}).get("name", lic))
	p["licenses"] = kept
	if not kept.has("driver"):
		GameState.clear_flag("drivers_license")
	if not lost.is_empty():
		GameState.add_log("These licenses aren't valid here and need converting: %s." % ", ".join(lost))
	GameState.counter("emigrated")
	if GameState.has_job():
		lose_job("moved")
	if p["housing"] == "house":
		p["money"] = int(p["money"]) + int(p["house_value"]) - int(p["mortgage"])
		p["house_value"] = 0
		p["mortgage"] = 0
		p["mortgage_payment"] = 0
	p.erase("house_uid")
	p["house_model"]=""
	p["housing"] = "apartment"
	GameState.job_listings.clear()


# ---------------------------------------------------------------- relationships

func person_actions(id: String) -> Array:
	var n := GameState.npc(id)
	var p := GameState.player
	var out: Array = []
	if n.is_empty() or not n["alive"]:
		return out
	var rel: String = n["relation"]
	var age: int = p["age"]
	if n.get("species", "human") != "human":
		out.append({"id": "pet_play", "name": "Play", "icon": "🎾"})
		out.append({"id": "pet_vet", "name": "Take to the vet ($200)", "icon": "🩺"})
		return out
	out.append({"id": "spend_time", "name": "Spend time", "icon": "🕒"})
	out.append({"id": "conversation", "name": "Have a conversation", "icon": "💬"})
	if age >= 4:
		out.append({"id": "compliment", "name": "Compliment", "icon": "🌟"})
	if age >= 10:
		out.append({"id": "gift", "name": "Give a gift ($100)", "icon": "🎁"})
	if rel in ["mother", "father", "grandparent"] and age >= 6:
		out.append({"id": "ask_money", "name": "Ask for money", "icon": "💵"})
	if rel == "partner":
		out.append({"id": "date_night", "name": "Date night ($150)", "icon": "🍷"})
		if p["partner_status"] == "dating" and age >= 18:
			out.append({"id": "propose", "name": "Propose", "icon": "💍"})
		if p["partner_status"] == "engaged":
			out.append({"id": "wedding", "name": "Plan the wedding", "icon": "💒"})
		if age >= 18 and age <= 52 and not p.get("expecting", false):
			out.append({"id": "baby", "name": "Try for a baby", "icon": "👶"})
		out.append({"id": "breakup", "name": "Divorce" if p["partner_status"] == "married" else "Break up", "icon": "💔"})
	if rel in ["rival", "ex", "enemy"]:
		out.append({"id": "make_peace", "name": "Make peace", "icon": "🕊️"})
	if rel in ["ex", "crush", "friend", "best_friend", "classmate", "coworker", "neighbor"] and age >= 14 and p["partner"] == "":
		out.append({"id": "ask_out", "name": "Ask out", "icon": "💘"})
	if rel == "friend" and int(n["closeness"]) >= 80:
		out.append({"id": "best_friend", "name": "Ask to be best friends", "icon": "🤞"})
	out.append({"id": "argue", "name": "Argue", "icon": "😤"})
	out.append({"id": "insult", "name": "Insult", "icon": "🗯️"})
	if age >= 10:
		out.append({"id": "fight", "name": "Start a fight", "icon": "👊"})
	if age >= 18:
		out.append({"id": "sue", "name": "Sue them", "icon": "⚖️"})
	return out


func interact(id: String, action: String) -> void:
	var n := GameState.npc(id)
	var p := GameState.player
	if n.is_empty():
		return
	if not GameState.can_interact(id, action):
		EventEngine.push_info("🕒", n["first"], "You've already done that with %s this year." % n["first"])
		return
	GameState.mark_interacted(id, action)
	var nm: String = n["first"]
	var close: int = n["closeness"]
	match action:
		"spend_time":
			var lines := ["We watched a movie together.", "We went out for lunch.", "We took a long walk and talked.", "We played board games all evening."]
			_rel_done(id, "🕒", "I spent time with %s. %s" % [nm, lines[randi() % lines.size()]], 8, {"happiness": 3})
		"conversation":
			var topics := ["the weather", "old memories", "politics (it got heated)", "their plans for the future", "a TV show we both love"]
			_rel_done(id, "💬", "I talked with %s about %s." % [nm, topics[randi() % topics.size()]], 4, {"happiness": 1})
		"compliment":
			if randf() < 0.85:
				_rel_done(id, "🌟", "I complimented %s. %s smiled." % [nm, GameState.pron(n["gender"], "he").capitalize()], 5, {})
			else:
				_rel_done(id, "🌟", "I complimented %s, who thought I was being sarcastic." % nm, -3, {})
		"gift":
			if not _can_pay(100, "Gift"): return
			_rel_done(id, "🎁", "I gave %s a gift. %s loved it." % [nm, GameState.pron(n["gender"], "he").capitalize()], 10, {"money": -100})
		"ask_money":
			if close >= 55 and randf() < 0.6:
				var amt := randi_range(20, 60) * (10 if p["age"] >= 18 else 1)
				_rel_done(id, "💵", "I asked %s for money and got %s." % [nm, GameState.fmt_money(amt)], -2, {"money": amt})
			else:
				_rel_done(id, "💵", "I asked %s for money. The answer was no." % nm, -4, {"happiness": -2})
		"date_night":
			if not _can_pay(150, "Date night"): return
			_rel_done(id, "🍷", "%s and I had a wonderful date night." % nm, 10, {"money": -150, "happiness": 5, "stress": -3})
		"propose":
			var chance := clampf((close - 40) / 50.0, 0.1, 0.95)
			if randf() < chance:
				p["partner_status"] = "engaged"
				GameState.add_milestone(p["age"], "got engaged to %s" % nm)
				_rel_done(id, "💍", "I proposed to %s and %s said YES!" % [nm, GameState.pron(n["gender"], "he")], 12, {"happiness": 12})
			else:
				_rel_done(id, "💍", "I proposed to %s, who said %s isn't ready." % [nm, GameState.pron(n["gender"], "he")], -12, {"happiness": -10})
		"wedding":
			_wedding(id)
		"baby":
			if randf() < 0.45:
				p["expecting"] = true
				_rel_done(id, "👶", "%s and I are expecting a baby!" % nm, 6, {"happiness": 8})
			else:
				_rel_done(id, "👶", "%s and I tried for a baby. No luck this year." % nm, 2, {})
		"breakup":
			if p["partner_status"] == "married":
				var loss := int(maxi(0, int(p["money"])) * 0.4)
				p["money"] = int(p["money"]) - loss
				GameState.add_milestone(p["age"], "divorced %s" % nm)
				_rel_done(id, "💔", "I divorced %s. The settlement cost me %s." % [nm, GameState.fmt_money(loss)], -40, {"happiness": -10, "stress": 10})
			else:
				_rel_done(id, "💔", "I broke up with %s." % nm, -30, {"happiness": -5})
			n["relation"] = "ex"
			p["partner"] = ""
			p["partner_status"] = ""
		"make_peace":
			if randf() < 0.5 + GameState.player["karma"] / 200.0:
				n["relation"] = "friend"
				_rel_done(id, "🕊️", "%s and I buried the hatchet. We're friends now." % nm, 25, {"karma": 5})
			else:
				_rel_done(id, "🕊️", "I tried to make peace with %s. It didn't take." % nm, -5, {})
		"ask_out":
			var chance := clampf(0.2 + close / 150.0 + (GameState.stat("looks") - 50) / 200.0, 0.05, 0.9)
			if randf() < chance:
				start_dating(id, false)
				_rel_done(id, "💘", "I asked %s out and %s said yes!" % [nm, GameState.pron(n["gender"], "he")], 10, {"happiness": 8})
			else:
				_rel_done(id, "💘", "I asked %s out. It was a no." % nm, -8, {"happiness": -5})
		"best_friend":
			n["relation"] = "best_friend"
			_rel_done(id, "🤞", "%s and I are officially best friends." % nm, 5, {"happiness": 5})
		"argue":
			_rel_done(id, "😤", "I got into a heated argument with %s." % nm, -15, {"stress": 5, "happiness": -3})
		"insult":
			var insults := ["called them a clown", "made fun of their haircut", "told them their cooking is terrible", "called them boring"]
			_rel_done(id, "🗯️", "I %s. %s was hurt." % [insults[randi() % insults.size()].replace("them", nm).replace("their", nm + "'s"), nm], -20, {"karma": -3})
		"fight":
			var win := 0.35 + (GameState.stat("health") - 50) / 200.0 + (0.15 if GameState.has_trait("Athletic") else 0.0) + (0.1 if GameState.has_trait("Hothead") else 0.0)
			if Meta.has_mod("brass_knuckles"):
				win = 1.0
			if randf() < win:
				_rel_done(id, "👊", "I got into a fistfight with %s and won." % nm, -35, {"happiness": 3, "karma": -5})
			else:
				_rel_done(id, "🤕", "I picked a fight with %s and lost badly." % nm, -25, {"health": -12, "happiness": -6})
			if randf() < 0.15:
				GameState.player["record"].append("assault")
				GameState.player["money"] = int(GameState.player["money"]) - 500
				GameState.add_log("The police charged me with assault. I paid a $500 fine.")
		"sue":
			Law.sue(id)
		"pet_play":
			_rel_done(id, "🎾", "I played with %s. Best part of my day." % nm, 10, {"happiness": 5, "stress": -4})
		"pet_vet":
			var vet := Web.contact(["vet"], 45)
			if vet != "":
				n["age"] = maxi(0, int(n["age"]) - 1)
				_rel_done(id, "🩺", "%s checked on %s for free." % [GameState.npc(vet)["first"], nm], 5, {})
				return
			if not _can_pay(200, "Vet"): return
			n["age"] = maxi(0, int(n["age"]) - 1)
			_rel_done(id, "🩺", "I took %s to the vet for a checkup." % nm, 5, {"money": -200})


func _rel_done(id: String, icon: String, text: String, closeness: int, effects: Dictionary) -> void:
	GameState.change_closeness(id, closeness)
	_done(icon, GameState.npc(id).get("first", ""), text, effects)


func _wedding(id: String) -> void:
	var small := _cost(3000)
	var big := _cost(30000)
	var nm: String = GameState.npc(id)["first"]
	var ok := {"text": "I married %s!" % nm, "effects": {"happiness": 15}, "milestone": "married %s" % GameState.full_name(id), "marry": true}
	var choices := [
		{"label": "Courthouse wedding ($150)", "requires": {"money": 150}, "outcomes": [ok.merged({"effects": {"happiness": 12, "money": -150}}, true)]},
		{"label": "Small wedding (%s)" % GameState.fmt_money(small), "requires": {"money": small}, "outcomes": [ok.merged({"effects": {"happiness": 15, "money": -small}}, true)]},
		{"label": "Lavish wedding (%s)" % GameState.fmt_money(big), "requires": {"money": big}, "outcomes": [ok.merged({"effects": {"happiness": 22, "money": -big}}, true)]},
		{"label": "Not yet", "outcomes": [{"text": ""}]},
	]
	EventEngine.push_decision({"id": "_wedding", "icon": "💒", "title": "Wedding", "text": "What kind of wedding do you and %s want?" % nm, "choices": choices}, {"them": id})


func mark_married() -> void:
	GameState.player["partner_status"] = "married"
	GameState.player["married_at"] = int(GameState.player["age"])
	if GameState.has_flag("prenup_signed"):
		GameState.player["prenup"] = true
	if GameState.player["partner"] != "" and GameState.npcs.has(GameState.player["partner"]):
		GameState.npcs[GameState.player["partner"]]["living_together"] = true
	GameState.set_flag("married_once")
	GameState.counter("marriages")
	if GameState.player["partner"] != "":
		GameState.change_closeness(GameState.player["partner"], 15)


# ---------------------------------------------------------------- school

func study_harder() -> void:
	var subjects: Array=Journey.modules["campus"].subjects()
	if not subjects.is_empty(): Journey.modules["campus"].class_work(str(subjects[0]["subject"]),true)


func skip_class() -> void:
	if not GameState.in_school() or _out_of_time(): return
	Journey.modules["campus"].st()["attendance"]=maxf(0,float(Journey.modules["campus"].st()["attendance"])-8)
	if randf() < 0.3:
		_done("🏃", "Skipping class", "I skipped class and got caught. Detention.", {"school": -8, "happiness": -3})
	else:
		_done("🏃", "Skipping class", "I skipped class and hung out instead.", {"school": -6, "happiness": 4, "stress": -2})


func can_enroll(level: String) -> String:
	var e: Dictionary = GameState.player["education"]
	if GameState.in_university():
		return "You're already enrolled."
	if GameState.in_prison():
		return "You're in prison."
	if int(GameState.player["age"]) < 18:
		return "You need to finish high school first."
	if Meta.has_mod("golden_diploma"):
		return ""
	if level == "bachelor" and not e["hs_graduated"]:
		return "You need a high school diploma."
	if level == "graduate" and GameState.edu_level() not in ["bachelor","graduate"]:
		return "You need a bachelor's degree first."
	return ""


func enrollment_chance(major_id: String) -> float:
	var m := ContentDB.major(major_id)
	if m.is_empty(): return 0.0
	if Meta.has_mod("golden_diploma"): return 1.0
	var chance := 0.9
	if str(m.get("level", "")) == "bachelor":
		var g := GameState.gpa()
		if g < 1.5: chance = 0.25
		elif g < 2.5: chance = 0.55
		elif g < 3.2: chance = 0.8
		var school_bonus := 0.0
		for field in Market.MAJOR_FIELDS.get(major_id, []):
			school_bonus = maxf(school_bonus, Journey.modules["school"].career_bonus(str(field)))
		chance = minf(0.97, chance + Daily.extracurricular_bonus() + school_bonus)
	else:
		chance = clampf(GameState.stat("smarts") / 100.0 + 0.15, 0.1, 0.95)
	return chance


func enroll(major_id: String) -> void:
	var m := ContentDB.major(major_id)
	var p := GameState.player
	var why := can_enroll(m["level"])
	if why != "":
		EventEngine.push_info("🎓", "University", why)
		return
	var g := GameState.gpa()
	var chance := enrollment_chance(major_id)
	if randf() > chance:
		_done("📭", "Application", "My application to study %s was rejected." % m["name"], {"happiness": -6})
		return
	var sch := 0.0
	if m["level"] == "bachelor":
		if g >= 3.6: sch = 1.0
		elif g >= 3.1: sch = 0.5
		if sch < 1.0 and Daily._ss()["captain"] and randf() < 0.5:
			sch = minf(1.0, sch + 0.5)
	p["education"]["uni"] = {"major": major_id, "level": m["level"], "years": int(m["years"]), "year": 0, "performance": 55.0, "scholarship": sch}
	if m["level"]=="bachelor":
		var credit := college_credit(major_id)
		p["education"]["uni"]["year"]=credit
		p["education"]["uni"]["college_credit"]=credit
	if p["housing"] == "parents" and m["level"] == "bachelor":
		p["housing"] = "dorm"
	var extra := ""
	if int(p["education"]["uni"].get("college_credit",0))>0: extra=" College study credited %d year(s)." % p["education"]["uni"]["college_credit"]
	if sch >= 1.0: extra += " I got a full scholarship!"
	elif sch > 0.0: extra += " I got a half scholarship."
	GameState.add_milestone(p["age"], "started studying %s" % m["name"])
	_done("🎓", "Accepted!", "I was accepted to study %s.%s" % [m["name"], extra], {"happiness": 10})


func college_credit(major_id: String) -> int:
	var target := ContentDB.major(major_id)
	if target.get("level","")!="bachelor": return 0
	var credit := 0
	for diploma in GameState.player.get("education",{}).get("degrees",[]):
		if diploma.get("level","")!="associate": continue
		# Recognition is explicit: this regional route does not silently confer
		# transferable regulated qualifications in every country or era.
		if str(diploma.get("country",""))!=str(GameState.player["country"]) and not diploma.get("recognized_countries",[]).has(str(GameState.player["country"])): continue
		var related: bool=Market.MAJOR_FIELDS.get(major_id,[]).has(str(diploma.get("field","")))
		credit=maxi(credit,2 if related else 1)
	return mini(credit,maxi(0,int(target["years"])-1))


func major_change_preview(major_id: String) -> Dictionary:
	var target := ContentDB.major(major_id)
	var uni: Dictionary=GameState.player.get("education",{}).get("uni",{})
	if uni.is_empty() or target.is_empty() or target.get("level","")!="bachelor" or uni.get("level","")!="bachelor" or str(uni["major"])==major_id: return {}
	var old_fields: Array=Market.MAJOR_FIELDS.get(str(uni["major"]),[])
	var new_fields: Array=Market.MAJOR_FIELDS.get(major_id,[])
	var related: bool=old_fields.any(func(field): return new_fields.has(field))
	var completed := maxi(0,int(uni.get("year",0)))
	# General study transfers at most one year. Related subjects also retain
	# some specialist study, but a new degree always requires further work.
	var credit := int(floor(completed*0.75)) if related else mini(1,completed)
	credit=clampi(credit,0,maxi(0,int(target["years"])-1))
	return {"major":major_id,"credit":credit,"lost":maxi(0,completed-credit),"remaining":int(target["years"])-credit,"fee":_cost(500),"related":related}


func change_major(major_id: String) -> void:
	var preview := major_change_preview(major_id)
	if preview.is_empty() or not Journey.pay("major_change",1,int(preview["fee"]),18): return
	var e: Dictionary=GameState.player["education"]
	var old: Dictionary=e["uni"].duplicate(true)
	if not e.has("study_changes"): e["study_changes"]=[]
	e["study_changes"].push_front({"year":GameState.year_now(),"from":old["major"],"to":major_id,"completed":old["year"],"credit":preview["credit"],"fee":preview["fee"]})
	if e["study_changes"].size()>32: e["study_changes"].resize(32)
	var target := ContentDB.major(major_id)
	e["uni"]["major"]=major_id; e["uni"]["years"]=int(target["years"]); e["uni"]["year"]=int(preview["credit"])
	# Performance, scholarship, already-paid tuition and outstanding loans
	# belong to the same student. Changing subject neither refunds nor clears them.
	Employment.record_expense("Change of major",int(preview["fee"]))
	GameState.add_milestone(GameState.player["age"],"changed major to "+str(target["name"]))
	_done("🎓","New study direction","%s · %d year(s) credited · %d remaining. Existing tuition debt stays due." % [target["name"],preview["credit"],preview["remaining"]],{"stress":2})


func drop_out() -> void:
	var p := GameState.player
	if not GameState.in_university() or Journey.blocked(18)!="":
		return
	var m := ContentDB.major(p["education"]["uni"]["major"])
	var e: Dictionary=p["education"]
	if not e.has("interrupted_study"): e["interrupted_study"]=[]
	e["interrupted_study"].push_front({"left":GameState.year_now(),"state":"open","course":e["uni"].duplicate(true)})
	if e["interrupted_study"].size()>32: e["interrupted_study"].resize(32)
	p["education"]["uni"] = {}
	if p["housing"] == "dorm":
		p["housing"] = "parents"
	GameState.add_milestone(p["age"], "dropped out of %s" % m.get("name", "university"))
	_done("🚪", "Study interrupted", "I left %s. Completed years stay in my study record; I can apply to return later. Existing loans remain due." % m.get("name", "university"), {"happiness": -3, "stress": -8})


func study_return_reason(index: int) -> String:
	var records: Array=GameState.player.get("education",{}).get("interrupted_study",[])
	if index<0 or index>=records.size() or records[index].get("state","")!="open": return "No interrupted course"
	var course: Dictionary=records[index].get("course",{})
	if course.is_empty() or ContentDB.major(str(course.get("major",""))).is_empty(): return "Course unavailable"
	if GameState.year_now()<=int(records[index]["left"]): return "Return from next year"
	var why := can_enroll(str(course["level"]))
	if why!="": return why
	why=Journey.blocked(18)
	if why!="": return why
	if Journey.used("study_return"): return "One return per year"
	if int(GameState.player["money"])<_cost(300): return "Needs "+GameState.fmt_money(_cost(300))
	if int(GameState.player["time_left"])<1: return "Needs 1 time"
	return ""


func return_to_study(index: int) -> void:
	if study_return_reason(index)!="" or not Journey.pay("study_return",1,_cost(300),18): return
	var e: Dictionary=GameState.player["education"]
	var record: Dictionary=e["interrupted_study"][index]
	e["uni"]=record["course"].duplicate(true)
	# A scholarship from an interrupted course is not a promise of fresh funding.
	e["uni"]["scholarship"]=0.0
	record["state"]="returned"; record["returned"]=GameState.year_now()
	Employment.record_expense("Return to study",_cost(300))
	var major := ContentDB.major(str(e["uni"]["major"]))
	_done("🎓","Back to study","%s · %d completed year(s) retained. Grades and loans remain. The former scholarship has ended." % [major["name"],e["uni"]["year"]])


# ---------------------------------------------------------------- jobs

func job_requirement(jd: Dictionary) -> String:
	if jd.get("mature",false) and not GameState.settings.get("mature_arcs",true): return "Enable mature career content in Settings"
	var era_why := Expansion.era_job_block(jd)
	if era_why != "":
		return era_why
	var p := GameState.player
	var age: int = p["age"]
	if age < int(jd.get("min_age", 18)):
		return "Age %d+" % int(jd.get("min_age", 18))
	if jd.get("part_time", false) and age >= 18 and false:
		return ""
	if jd.has("license") and not Law.has_license(jd["license"]):
		return Law.LICENSES[jd["license"]]["name"]
	var order := ["none", "high_school", "associate", "bachelor", "graduate"]
	var need: String = jd.get("edu", "none")
	if Meta.has_mod("golden_diploma"):
		need = "none"
		if not p["record"].is_empty() and jd.get("clean_record", false):
			return "Clean criminal record"
		return ""
	var vocational := bool(jd.get("vocational_entry",false)) and need in ["none","high_school"] and Employment.has_certificate(str(jd.get("field","")))
	if not vocational and order.find(GameState.edu_level()) < order.find(need):
		return {"high_school": "High school diploma", "associate":"Associate diploma", "bachelor": "Bachelor's degree", "graduate": "Graduate degree"}[need]
	var majors: Array = jd.get("majors", [])
	if not majors.is_empty():
		var ok := false
		for d in p["education"]["degrees"]:
			if majors.has(d["major"]):
				ok = true
		if not ok:
			var names: Array = majors.map(func(mid): return ContentDB.major(mid).get("name", mid))
			return "Degree in " + " or ".join(names)
	if jd.has("min_smarts") and GameState.stat("smarts") < float(jd["min_smarts"]):
		return "Smarts %d+" % int(jd["min_smarts"])
	if not p["record"].is_empty() and jd.get("clean_record", false):
		return "Clean criminal record"
	return ""


func listings(kind: String) -> Array:
	var p := GameState.player
	var key := "%s_%d_%s_%s" % [kind, int(p["age"]), str(p["country"]), str(p.get("region", ""))]
	if GameState.job_listings.has(key):
		return GameState.job_listings[key]
	var eligible: Array = []
	var locked: Array = []
	for jd in ContentDB.jobs:
		if jd.get("inherited_only", false): continue
		var field: String = jd.get("field", "")
		if kind == "part" and not jd.get("part_time", false):
			continue
		if kind == "full" and (jd.get("part_time", false) or field == "Military"):
			continue
		if kind == "military" and field != "Military":
			continue
		if jd.get("rank_start", 0) > 0:
			continue
		var why := job_requirement(jd)
		if why == "":
			eligible.append(jd["id"])
		elif int(p["age"]) >= int(jd.get("min_age", 18)) - 2:
			locked.append(jd["id"])
	var slots := int(round((9 if kind == "full" else 6) * clampf(1.25 - Places.unemployment() * 4.0, 0.35, 1.2)))
	var out: Array = []
	for group in [eligible, locked]:
		var pool: Array = []
		for jid in group: pool.append({"id": jid, "weight": Market.listing_weight(ContentDB.job(str(jid)))})
		var count := maxi(2, slots) if group == eligible else 3
		for _i in range(mini(count, pool.size())):
			var pick := EventEngine._weighted_pick(pool, "weight")
			pool.erase(pick)
			out.append(pick["id"])
	GameState.job_listings[key] = out
	return out


func job_salary(jd: Dictionary) -> int:
	var wage: float = ContentDB.country(GameState.player["country"]).get("wage", 1.0)
	return int(int(jd["salary"]) * wage * Places.pay_mult() * World.pay_mult(str(jd.get("field", ""))) * Expansion.era_pay_mult())


func apply_job(job_id: String) -> void:
	var jd := ContentDB.job(job_id)
	var why := job_requirement(jd)
	if why != "":
		EventEngine.push_info("🔒", jd["ranks"][0], "Requirement: %s." % why)
		return
	if GameState.has_job() and not jd.get("part_time", false):
		pass
	if _out_of_time(): return
	var q: Dictionary = ContentDB.interviews[randi() % ContentDB.interviews.size()]
	var base := 0.42 + (GameState.stat("smarts") - 50.0) / 220.0 + (GameState.stat("looks") - 50.0) / 320.0 + GameState.gpa() / 20.0
	if GameState.has_trait("Charmer"):
		base += 0.08
	if GameState.has_trait("Anxious"):
		base -= 0.06
	if Shop.has_any(["suit", "designer"]):
		base += 0.07
	if Shop.has_tag("punctual"):
		base += 0.03
	var choices: Array = []
	for a in q["answers"]:
		var c := clampf(base + float(a.get("score", 0.0)), 0.05, 0.95)
		var ch := {"label": a["text"], "outcomes": [
			{"weight": c, "text": "They called back: I got the job as %s!" % jd["ranks"][0], "hire": job_id},
			{"weight": 1.0 - c, "text": "They went with another candidate for %s." % jd["ranks"][0], "effects": {"happiness": -3}},
		]}
		if a.has("trait"):
			ch["requires"] = {"trait": a["trait"]}
		choices.append(ch)
	EventEngine.push_decision({"id": "_interview", "icon": "💼", "title": "Interview: %s" % jd["ranks"][0], "text": "The interviewer leans in and asks:\n\n“%s”" % q["question"], "choices": choices})


func hire(job_id: String) -> void:
	Destiny.on_job(job_id)
	var p := GameState.player
	var jd := ContentDB.job(job_id)
	if jd.is_empty():
		return
	GameState.counter("hired")
	if GameState.has_job():
		lose_job("switch")
	var age: int = p["age"]
	var boss := GameState.create_npc("boss", {"age": randi_range(maxi(age + 5, 30), maxi(age + 10, 60)), "closeness": 45})
	var cw1 := GameState.create_npc("coworker", {"age": maxi(16, age + randi_range(-6, 12)), "closeness": 45})
	p["job"] = {
		"id": job_id,
		"title": jd["ranks"][0],
		"field": jd.get("field", ""),
		"rank": 0,
		"salary": int(job_salary(jd) * randf_range(0.92, 1.1)),
		"perf": 55.0,
		"years": 0,
		"years_in_rank": 0,
		"boss": boss,
		"coworkers": [cw1],
		"part_time": jd.get("part_time", false),
		"worked_hard": false,
	}
	Employment.on_hire()
	Workplace.begin({"boss":Market.BOSSES.keys().pick_random(),"culture":Market.CULTURES.keys().pick_random(),"health":0.7})
	GameState.job_listings.clear()
	if not jd.get("part_time", false) and GameState.get_counter("full_jobs") == 0:
		GameState.add_milestone(age, "started working as %s" % jd["ranks"][0])
	if not jd.get("part_time", false):
		GameState.counter("full_jobs")
	GameState.emit_changed()


func lose_job(reason: String) -> void:
	var p := GameState.player
	if not GameState.has_job():
		return
	var j: Dictionary = p["job"]
	p["job_history"].append(j["title"])
	Employment.on_leave(reason)
	Workforce.on_leave(reason, int(j.get("salary", 0)), int(j.get("years", 0)))
	var title: String = j["title"]
	for id in [j.get("boss", "")] + Array(j.get("coworkers", [])):
		if GameState.npcs.has(id) and GameState.npcs[id]["relation"] in ["boss", "coworker"]:
			GameState.npcs[id]["relation"] = "former_coworker"
	p["job"] = {}
	match reason:
		"fired":
			GameState.add_log("I was fired from my job as %s." % title)
			GameState.apply_effects({"happiness": -12, "stress": 10})
		"quit":
			GameState.add_log("I quit my job as %s." % title)
		"prison":
			GameState.add_log("I lost my job as %s." % title)
		"moved":
			GameState.add_log("I left my job as %s when I moved." % title)
		"retire":
			GameState.add_log("I retired from my job as %s." % title)
	GameState.emit_changed()


func quit_job() -> void:
	lose_job("quit")
	EventEngine.push_info("🚪", "Quit", "I quit my job.")


func retire() -> void:
	var p := GameState.player
	if not GameState.has_job():
		return
	var pension := int(int(p["job"]["salary"]) * 0.45)
	lose_job("retire")
	p["retired"] = true
	p["pension"] = pension
	GameState.add_milestone(p["age"], "retired")
	_done("🏖️", "Retirement", "I retired. My pension is %s a year." % GameState.fmt_money(pension), {"happiness": 10, "stress": -15}, false)


func work_harder() -> void:
	if not GameState.has_job(): return
	if _out_of_time(): return
	GameState.player["job"]["worked_hard"] = true
	Grit.habit("workaholic", 14)
	_done("💼", "Work", "I put in extra hours at work.", {"job_perf": 10, "stress": 5, "happiness": -1})


func deploy() -> void:
	if not GameState.has_job(): return
	if not GameState.mark_interacted("job", "deploy"): return
	if _out_of_time(): return
	var rank := int(GameState.player["job"].get("rank", 0))
	Minigames.play("minefield", {"skill": 35 + rank * 8, "difficulty": 0.9 + minf(0.5, rank * 0.08) + (0.2 if World.active("war") else 0.0)}, Callable(self, "_deploy_done"))


func _deploy_done(score: float, detail: Dictionary) -> void:
	var p := GameState.player
	var ok: bool = detail.get("success", false) if not detail.get("auto", false) else score >= 0.42
	var boom: bool = detail.get("boom", false) or (detail.get("auto", false) and score < 0.3)
	if ok:
		GameState.counter("deployments")
		var bonus := _cost(randi_range(1500, 6000))
		if (score >= 0.85 and randf() < 0.5) or (detail.get("auto", false) and score >= 0.5 and randf() < 0.4):
			GameState.counter("medals")
			GameState.add_milestone(p["age"], "was awarded a medal for bravery")
			_done("🎖️", "Deployment", "I led my squad through the minefield without a scratch. They pinned a medal on me.", {"job_perf": 20, "money": bonus, "happiness": 10})
		else:
			_done("🪖", "Deployment", "We cleared the route and made it through. Hazard pay: %s." % GameState.fmt_money(bonus), {"job_perf": 12, "money": bonus, "stress": 8})
	elif boom:
		var sc := Grit.add_scar(["limp", "hearing", "missing_finger", "haunted"][randi() % 4], true)
		GameState.add_milestone(p["age"], "was wounded in action")
		_done("💥", "Wounded", "A mine went off. I woke up in a field hospital." + sc, {"health": -35, "happiness": -12, "stress": 20, "job_perf": 5})
	else:
		_done("📻", "Deployment", "We ran out of daylight and pulled back. The mission was scrubbed.", {"job_perf": -6, "stress": 6})


func dress_up() -> void:
	if not GameState.has_job(): return
	if _out_of_time(): return
	GameState.player["job"]["suited"] = true
	_done("👔", "Dress to impress", "I wore the tailored suit to work all week. People took me more seriously.", {"job_perf": 8, "looks": 1})


func ask_raise() -> void:
	var p := GameState.player
	if not GameState.has_job(): return
	if _out_of_time(): return
	var perf := float(p["job"]["perf"])
	if randf() < perf / 130.0:
		var old: int = p["job"]["salary"]
		p["job"]["salary"] = int(old * 1.08)
		_done("💰", "Raise", "My boss approved a raise to %s a year!" % GameState.fmt_money(p["job"]["salary"]), {"happiness": 6})
	else:
		_done("💰", "Raise", "I asked for a raise and was turned down.", {"happiness": -3, "job_perf": -4})


func freelance() -> void:
	if int(GameState.player["age"]) < 14: return
	if _out_of_time(): return
	var gigs := ["designed a logo", "walked dogs", "fixed a website", "tutored a student", "delivered groceries", "edited a video", "assembled furniture"]
	var pay := int(randi_range(150, 1200) * (0.6 + GameState.stat("smarts") / 100.0))
	GameState.counter("gigs")
	_done("🧾", "Freelance", "I %s for a client and earned %s." % [gigs[randi() % gigs.size()], GameState.fmt_money(pay)], {"money": pay, "stress": 2})


# ---------------------------------------------------------------- assets

func move_out() -> void:
	var p := GameState.player
	if int(p["age"]) < 18:
		EventEngine.push_info("🏠", "Moving out", "You're too young to move out.")
		return
	p["housing"] = "apartment"
	GameState.add_milestone(p["age"], "moved into a place of %s own" % GameState.pron(p["gender"], "his"))
	_done("🏢", "Moving out", "I moved into a rented apartment.", {"happiness": 5, "stress": 3})


func move_home() -> void:
	var p := GameState.player
	if GameState.first_of("mother") == "" and GameState.first_of("father") == "":
		EventEngine.push_info("🏠", "Moving home", "There's no family home to move back to.")
		return
	if p["housing"] == "house":
		EventEngine.push_info("🏠", "Moving home", "Sell your house first.")
		return
	p["housing"] = "parents"
	_done("🏠", "Moving home", "I moved back in with my family.", {"happiness": -3, "stress": -3})


const HOME_MODELS := {
	"studio": {"name": "Pocket studio", "multiplier": 0.45, "icon": "flat_small", "sub": "Compact city base"},
	"terrace": {"name": "Brick terrace", "multiplier": 0.8, "icon": "terrace", "sub": "Connected streets, modest footprint"},
	"bungalow": {"name": "Garden bungalow", "multiplier": 1.0, "icon": "bungalow", "sub": "Single floor, small garden"},
	"family": {"name": "Family detached", "multiplier": 1.4, "icon": "house_large", "sub": "Room for a growing household"},
	"villa": {"name": "Coastal villa", "multiplier": 3.2, "icon": "villa", "sub": "Space and a sea-view premium"},
	"mansion": {"name": "Hilltop mansion", "multiplier": 10.0, "icon": "mansion", "sub": "A substantial long-term commitment"},
	"estate": {"name": "Country estate", "multiplier": 32.0, "icon": "estate", "sub": "Grounds, wings and a considerable mortgage"},
}

func house_price(model: String = "") -> int:
	return _cost(int(GameState.HOUSE_PRICE*float(HOME_MODELS.get(model,{"multiplier":1.0})["multiplier"])))

func house_purchase_reason(model: String) -> String:
	if model!="" and not HOME_MODELS.has(model): return "Home unavailable"
	var p := GameState.player
	var price := house_price(model)
	var down := int(price*0.2)
	if int(p["age"])<18: return "Age 18+"
	if p["housing"]=="house": return "Sell your current home first"
	if int(p["money"])<down: return "Needs %s down" % GameState.fmt_money(down)
	if not GameState.has_job() and not p["retired"] and int(p["money"])<price: return "Needs income for a mortgage"
	if not Grit.credit_ok() and int(p["money"])<price: return "Mortgage needs credit %d+" % int(Grit.d("credit_min"))
	return ""


func buy_house(model: String = "") -> void:
	var p := GameState.player
	var why := house_purchase_reason(model)
	if why!="":
		EventEngine.push_info("🏡","Home",why+".")
		return
	var price := house_price(model)
	var down := int(price * 0.2)
	if not _can_pay(down, "Buy a house"): return
	p["money"] = int(p["money"]) - down
	var owed := int((price - down) * 1.35)
	p["mortgage"] = owed
	p["mortgage_payment"] = int(owed / float(GameState.MORTGAGE_YEARS))
	p["house_value"] = price
	p["house_model"] = model
	p["house_uid"] = Journey.uid()+":"+str(Time.get_ticks_usec())
	p["home"]={}
	p["housing"] = "house"
	GameState.add_milestone(p["age"], "bought a house")
	_done("🏡", "New home", "I bought a house for %s with a %s down payment." % [GameState.fmt_money(price), GameState.fmt_money(down)], {"happiness": 12, "stress": 4})


func sell_house() -> void:
	var p := GameState.player
	if p["housing"] != "house":
		return
	var value := int(int(p["house_value"]) * randf_range(0.9, 1.25))
	var net := value - int(p["mortgage"])
	p["money"] = int(p["money"]) + net
	p["house_value"] = 0
	p.erase("house_model")
	p.erase("house_uid")
	p["mortgage"] = 0
	p["mortgage_payment"] = 0
	p["housing"] = "apartment"
	_done("🏡", "Sold", "I sold my house for %s and walked away with %s." % [GameState.fmt_money(value), GameState.fmt_money(net)], {"happiness": 2})


func buy_car(kind: String) -> void:
	var p := GameState.player
	if int(p["age"]) < 16:
		EventEngine.push_info("🚗", "Cars", "You're too young to drive.")
		return
	if not GameState.CARS.has(kind): return
	if str(p.get("car",""))==kind:
		EventEngine.push_info("🚗","Cars","You already own this model.")
		return
	var c: Dictionary = GameState.CARS[kind]
	var price := _cost(int(c["price"]))
	var trade := Holdings.resale() if str(p.get("car",""))!="" else 0
	var net_due := price-trade
	var due := maxi(0,net_due)
	if not Law.has_license("driver"):
		EventEngine.push_info("🚗", "Cars", "You need a driver's license first. Get one under Activities → Legal → Licenses.")
		return
	if int(p["money"])<net_due:
		EventEngine.push_info("💸","Buy a car","After the trade-in, you need "+GameState.fmt_money(due)+" in cash.")
		return
	if trade>0: p["money"] = int(p["money"]) + trade
	p["car"] = kind
	Holdings.new_car(kind,price)
	var detail := "Listed %s · trade-in %s · paid %s" % [GameState.fmt_money(price),GameState.fmt_money(trade),GameState.fmt_money(due)]
	if net_due<0: detail+=" · cash back "+GameState.fmt_money(-net_due)
	_done("🚗", "New wheels", "I bought a %s. %s." % [c["name"].to_lower(),detail], {"money": -price, "happiness": int(c["happiness"])})


func sell_car() -> void:
	var p := GameState.player
	if p["car"] == "":
		return
	var value := Holdings.resale()
	p["car"] = ""
	p.erase("car_record")
	_done("🚗", "Sold", "I sold my car for %s." % GameState.fmt_money(value), {"money": value})

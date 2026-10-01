extends Node

## Relationships, friendships and family: what you can do with each person,
## how they react (closeness, their craziness, their memory of you), and the
## lives they lead on their own every year.

const UP := ["mother", "father", "stepparent", "grandparent", "auntuncle"]
const SIDE := ["sibling", "stepsibling", "cousin"]
const DOWN := ["child", "stepchild", "grandchild", "niece_nephew"]
const FAMILY := ["mother", "father", "stepparent", "grandparent", "auntuncle", "sibling", "stepsibling", "cousin", "child", "stepchild", "grandchild", "niece_nephew"]
const FRIENDS := ["friend", "best_friend"]
const WORK := ["coworker", "boss", "former_coworker"]
const LIKES := {
	"tech": ["🎧", "gadgets"], "books": ["📚", "books"], "sports": ["⚽", "sports gear"], "fashion": ["👗", "clothes"],
	"art": ["🎨", "art supplies"], "food": ["🍫", "fancy food"], "games": ["🎮", "games"], "jewelry": ["💍", "jewelry"],
	"music": ["🎵", "music"], "outdoors": ["🏕️", "outdoor gear"],
}
const TOPICS := ["the weather", "old family stories", "politics, which got heated", "their plans for the future", "a show we're both watching",
	"what's going on at their work", "an embarrassing memory", "their love life", "conspiracy theories (theirs)", "money worries", "a book they just finished",
	"the neighbors", "their health", "the best pizza in town", "whether aliens exist", "what we'd do if we won the lottery"]
const HANGOUTS := [
	["park", "🌳", "Go to the park", 0, 0, 0],
	["movies", "🎬", "See a movie", 15, 5, 0],
	["dinner", "🍝", "Go out to eat", 40, 12, 0],
	["shopping", "🛍️", "Go shopping", 60, 12, 0],
	["gym", "🏋️", "Work out together", 10, 12, 0],
	["games", "🎮", "Play video games", 0, 6, 0],
	["concert", "🎤", "Go to a concert", 90, 14, 0],
	["sports", "🏟️", "Watch a game at the stadium", 70, 8, 0],
	["karaoke", "🎙️", "Karaoke night", 30, 16, 0],
	["museum", "🏛️", "Visit a museum", 20, 8, 0],
	["bar", "🍻", "Grab drinks", 35, -1, 0],
	["cook", "🍳", "Cook a meal together", 20, 10, 0],
	["roadtrip", "🚗", "Road trip (2 time)", 300, 18, 1],
]


func _p() -> Dictionary:
	return GameState.player


func ensure(id: String) -> Dictionary:
	var n := GameState.npc(id)
	if n.is_empty():
		return n
	if not n.has("craziness"):
		n["craziness"] = clampi(int(round(randfn(35.0, 22.0))), 0, 100)
		n["smarts"] = clampi(int(round(randfn(52.0, 18.0))), 5, 100)
		n["generosity"] = clampi(int(round(randfn(50.0, 20.0))), 0, 100)
		n["likes"] = LIKES.keys()[randi() % LIKES.size()]
		n["memory"] = []
	return n


func remember(id: String, text: String, good: bool, own: bool = false) -> void:
	var n := ensure(id)
	if n.is_empty():
		return
	var mem: Array = n.get("memory", [])
	mem.push_front({"age": int(_p()["age"]), "text": text, "good": good, "own": own})
	if mem.size() > 8:
		mem.resize(8)
	n["memory"] = mem


func memories(id: String) -> Array:
	return ensure(id).get("memory", [])


func _roll(n: Dictionary, base: float) -> bool:
	var c := float(n.get("closeness", 50))
	var cz := float(n.get("craziness", 35))
	return randf() < clampf(base + (c - 50.0) / 120.0 - (cz - 40.0) / 260.0, 0.04, 0.97)


func _pick(a: Array) -> String:
	return str(a[randi() % a.size()])


func _he(n: Dictionary) -> String:
	return GameState.pron(n["gender"], "he")


func _him(n: Dictionary) -> String:
	return GameState.pron(n["gender"], "him")


func _his(n: Dictionary) -> String:
	return GameState.pron(n["gender"], "his")


func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


func _res(id: String, icon: String, text: String, delta: int, effects: Dictionary = {}, mem: String = "") -> void:
	GameState.change_closeness(id, delta)
	if mem != "":
		remember(id, mem, delta >= 0)
	Actions._done(icon, GameState.npc(id).get("first", ""), text, effects)


func _once(id: String, aid: String) -> bool:
	if not GameState.can_interact(id, aid):
		EventEngine.push_info("🕒", GameState.npc(id).get("first", ""), "You've already done that with %s this year." % GameState.npc(id).get("first", "them"))
		return false
	GameState.mark_interacted(id, aid)
	return true


func is_minor(n: Dictionary) -> bool:
	return int(n.get("age", 30)) < 18


func lives_with_ex(n: Dictionary) -> bool:
	return str(n.get("custody", "")) == "ex"


# ================================================================ menus

func menu(key: String) -> Dictionary:
	var parts := key.split(":")
	var id: String = parts[0]
	var grp: String = parts[1] if parts.size() > 1 else ""
	var n := ensure(id)
	if n.is_empty() or not n["alive"]:
		return {"icon": "🕯️", "title": "Gone", "rows": []}
	if n.get("species", "human") != "human":
		return _pet_menu(id, n)
	match grp:
		"":
			return _root(id, n)
		"time":
			return _time_menu(id, n)
		"gift":
			return _gift_menu(id, n)
		"family":
			return _family_menu(id, n)
		"romance":
			return _romance_menu(id, n)
		"friend":
			return _friend_menu(id, n)
		"conflict":
			return _conflict_menu(id, n)
		"discipline":
			return {"icon": "🧑‍🏫", "title": "Discipline " + n["first"], "rows": [
				_r(id, "disc_talk", "🗣️", "Have a calm talk", "Explain why it matters"),
				_r(id, "disc_ground", "🚫", "Ground them", "No phone, no friends for a month"),
				_r(id, "disc_yell", "📢", "Yell at them", "It works, for now"),
				_r(id, "disc_ignore", "🤷", "Let it slide", "Kids will be kids"),
			]}
		"propose":
			return _propose_menu(id, n)
		"divorce":
			return _divorce_menu(id, n)
		"money":
			return _money_menu(id, n)
	return _root(id, n)


func _r(id: String, aid: String, icon: String, name: String, sub: String = "", arg = null, on: bool = true) -> Dictionary:
	var done := not GameState.can_interact(id, aid)
	return {"icon": icon, "name": name, "sub": "Done this year" if done and sub != "" else ("Done this year" if done else sub), "act": "bond:%s:%s" % [id, aid], "arg": arg, "on": on and not done}


func _g(id: String, grp: String, icon: String, name: String, sub: String, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "menu": "bond:%s:%s" % [id, grp], "on": on}


func _root(id: String, n: Dictionary) -> Dictionary:
	var p := _p()
	var rel: String = n["relation"]
	var age: int = p["age"]
	var rows: Array = []
	var far := lives_with_ex(n)
	rows.append(_r(id, "conversation", "💬", "Conversation", "Small talk"))
	if age >= 4:
		rows.append(_r(id, "compliment", "🌟", "Compliment", "Say something nice"))
	if age >= 8 and int(n["closeness"]) >= 35:
		rows.append(_r(id, "deep_talk", "🫂", "Have a deep talk", "Get to know them better"))
	if age >= 6:
		rows.append(_g(id, "time", "🕒", "Spend time together", "Movies, dinner, games, trips…" if not far else "Only on your visiting weekends"))
	if age >= 6:
		rows.append(_g(id, "gift", "🎁", "Give a gift", "They like %s" % LIKES[n["likes"]][1] if n.get("likes_known", false) else "Find out what they like"))
	if age >= 10 or rel in UP:
		rows.append(_g(id, "money", "💵", "Money", "Ask, lend, give"))
	if rel in FAMILY:
		rows.append(_g(id, "family", "👪", "Family", _family_sub(n)))
	if rel == "partner" or rel == "lover":
		rows.append(_g(id, "romance", "💞", "Romance", _romance_sub()))
	if rel in FRIENDS or rel in ["classmate", "coworker", "neighbor", "crush", "ex", "teacher", "boss", "mentor", "former_coworker"]:
		rows.append(_g(id, "friend", "🤝", _social_title(rel), _social_sub(rel)))
	if age >= 4:
		rows.append(_g(id, "conflict", "😤", "Conflict", "Argue, insult, prank, rumors, fights"))
	for extra in earned_rows(id, n):
		rows.append(extra)
	return {"icon": U_face(n), "title": n["first"], "rows": rows, "person": id}


## Things you can only do because of what this relationship has become. They are
## not on the menu by default and they are not unlocked by age or money - they
## exist because of how you have treated this person for years. Two runs with the
## same family can have completely different options on this screen.
func earned_rows(id: String, n: Dictionary) -> Array:
	var out: Array = []
	var p := _p()
	var age: int = p["age"]
	if age < 12 or n.get("species", "human") != "human":
		return out
	var trust := BondStats.get_stat(id, "trust")
	var respect := BondStats.get_stat(id, "respect")
	var affection := BondStats.get_stat(id, "affection")
	var resent := BondStats.get_stat(id, "resentment")
	var owed := BondStats.get_stat(id, "obligation")

	if trust >= 78.0 and BondStats.has_stat(id, "trust"):
		out.append(_r(id, "confide", "🔐", "Tell them something true", "Only because they have never repeated anything"))
	if owed >= 45.0:
		out.append(_r(id, "call_in", "📒", "Call in what they owe me", "They know the number as well as I do"))
	if respect >= 80.0 and age >= 18:
		out.append(_r(id, "vouch", "🖋️", "Ask them to vouch for me", "Their word carries where mine does not"))
	if resent >= 55.0:
		out.append(_r(id, "clear_air", "🕊️", "Try to clear the air", "This has been sitting between us for years"))
	if affection >= 82.0 and trust >= 60.0 and age >= 25:
		out.append(_r(id, "lean", "🫂", "Lean on them properly", "The kind of asking you only get to do a few times"))
	if respect <= 18.0 and affection >= 55.0:
		out.append(_r(id, "prove", "💪", "Prove them wrong about me", "They love me and do not rate me"))
	return out


func U_face(n: Dictionary) -> String:
	return preload("res://scenes/ui_kit.gd").npc_face(n)


func _family_sub(n: Dictionary) -> String:
	var rel: String = n["relation"]
	if rel in ["child", "stepchild"]:
		return "Parenting, school, allowance, college" if is_minor(n) else "Advice, money, their family"
	if rel in UP:
		return "Advice, money, caring for them"
	return "Squabbles, favors, family things"


func _romance_sub() -> String:
	match str(_p().get("partner_status", "")):
		"married": return "Dates, getaways, babies, vows"
		"engaged": return "Dates, the wedding"
		_: return "Dates, moving in, proposing"


func _social_title(rel: String) -> String:
	match rel:
		"coworker", "boss", "former_coworker": return "Work"
		"classmate", "teacher": return "School"
		"neighbor": return "Neighbors"
		"ex": return "Exes"
		_: return "Friendship"


func _social_sub(rel: String) -> String:
	match rel:
		"boss": return "Suck up, ask for a raise, complain"
		"coworker", "former_coworker": return "Lunch, gossip, cover a shift"
		"teacher": return "Suck up, ask for help, act up"
		"classmate": return "Study together, sit together, ask out"
		"neighbor": return "Borrow, barbecue, complain"
		"ex": return "Call, rekindle, move on"
		_: return "Parties, favors, best friends, set-ups"


func _time_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = []
	var age: int = _p()["age"]
	var drink := int(Places.law("drink"))
	for h in HANGOUTS:
		var min_age: int = h[4]
		if min_age < 0:
			min_age = drink
		if age < min_age or int(n["age"]) < min_age:
			continue
		if h[0] == "roadtrip" and (is_minor(n) and n["relation"] not in DOWN):
			continue
		var cost := Actions._cost(int(h[3]))
		rows.append({"icon": h[1], "name": h[2], "sub": ("Free" if cost == 0 else GameState.fmt_money(cost)) + " · 1 time" + (" more" if int(h[5]) > 0 else ""), "act": "bond:%s:hang" % id, "arg": h[0], "on": GameState.can_interact(id, "hang")})
	if age >= 18 and not is_minor(n):
		rows.append({"icon": "✈️", "name": "Take %s on vacation" % _him(n), "sub": "Pick a trip together", "menu": "daily:vacation:" + id, "on": true})
	return {"icon": "🕒", "title": "Time with " + n["first"], "rows": rows}


func _gift_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = []
	var known: bool = n.get("likes_known", false)
	rows.append({"icon": "💐", "name": "Flowers or a card", "sub": GameState.fmt_money(Actions._cost(20)), "act": "bond:%s:gift" % id, "arg": "cheap", "on": GameState.can_interact(id, "gift")})
	for k in LIKES.keys():
		var price := Actions._cost(120 if k != "jewelry" else 600)
		rows.append({"icon": LIKES[k][0], "name": "Something %s: %s" % ["they'd love" if known and k == n["likes"] else "nice", LIKES[k][1]], "sub": GameState.fmt_money(price) + (" · their favorite" if known and k == n["likes"] else ""), "act": "bond:%s:gift" % id, "arg": k, "on": GameState.can_interact(id, "gift")})
	var p := _p()
	for i in range(p.get("possessions", []).size()):
		var it: Dictionary = p["possessions"][i]
		rows.append({"icon": it.get("icon", "📦"), "name": "Give away your " + str(it["name"]).to_lower(), "sub": "Worth %s" % GameState.fmt_money(int(it.get("value", 0))), "act": "bond:%s:give_item" % id, "arg": i, "on": GameState.can_interact(id, "gift")})
	return {"icon": "🎁", "title": "A gift for " + n["first"], "rows": rows}


func _money_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = []
	var p := _p()
	rows.append(_r(id, "ask_money", "🙏", "Ask for money", "Depends on how much they have and like you"))
	if int(p["age"]) >= 16:
		for amt in [100, 1000, 10000, 100000]:
			if int(p["money"]) >= amt:
				rows.append({"icon": "💸", "name": "Give %s" % GameState.fmt_money(amt), "sub": "No strings attached", "act": "bond:%s:give_money" % id, "arg": amt, "on": GameState.can_interact(id, "give_money")})
	if int(p["age"]) >= 18 and not is_minor(n):
		rows.append(_r(id, "lend", "🤝", "Lend them money", "Will they pay you back?"))
		if int(n.get("owes", 0)) > 0:
			rows.append(_r(id, "collect", "📒", "Ask for your %s back" % GameState.fmt_money(int(n["owes"])), "They owe you"))
	return {"icon": "💵", "title": "Money · " + n["first"], "rows": rows}


func _family_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = []
	var p := _p()
	var rel: String = n["relation"]
	var age: int = p["age"]
	var na: int = n["age"]
	if rel in UP:
		rows.append(_r(id, "advice", "🧓", "Ask for advice", "They've lived it"))
		if rel in ["mother", "father", "stepparent"]:
			if GameState.in_university() or (age >= 17 and age <= 25 and not p["education"].get("uni", {}).is_empty()):
				rows.append(_r(id, "ask_tuition", "🎓", "Ask them to help with tuition", "College is expensive"))
			if age >= 18 and p["housing"] != "parents":
				rows.append(_r(id, "move_back", "🏠", "Ask to move back home", "Cheaper, but you're back under their roof"))
			if age < 18:
				rows.append(_r(id, "ask_pet", "🐶", "Beg for a pet", "Please please please"))
				rows.append(_r(id, "ask_later", "🌙", "Ask to stay out later", "Everyone else's parents said yes"))
		if age >= 18:
			rows.append(_r(id, "party_for", "🎂", "Throw them a birthday party", GameState.fmt_money(Actions._cost(250))))
		if na >= 70 and age >= 18:
			rows.append(_r(id, "care", "🏡", "Take care of them", "Move them in, pay for a home, or visit"))
		if age >= 16:
			rows.append(_r(id, "cut_off", "✂️", "Cut them out of your life", "No more calls, no more visits"))
	if rel in SIDE:
		rows.append(_r(id, "squabble", "🙄", "Squabble", "Sibling stuff"))
		if (na < 18) == (age < 18):
			rows.append(_r(id, "rumble", "🤼", "Rumble", "Settle it on the living room floor"))
		rows.append(_r(id, "prank", "🎭", "Prank them", "Classic"))
		if age >= 18 and na >= 18:
			rows.append(_r(id, "favor", "🙌", "Ask for a favor", "Help moving, a ride, a place to crash"))
		if int(n.get("kids", 0)) > 0 and age >= 16:
			rows.append(_r(id, "babysit", "🧸", "Babysit their kids", "Your nieces and nephews"))
	if rel in ["child", "stepchild"]:
		if lives_with_ex(n):
			rows.append(_r(id, "visit", "🚪", "Visitation weekend", "You only see them sometimes"))
			rows.append(_r(id, "custody_fight", "⚖️", "Go back to court for custody", GameState.fmt_money(Actions._cost(12000)) + " in legal fees"))
		if na <= 10:
			rows.append(_r(id, "play", "🧸", "Play together", "Blocks, dolls, tag, pretend"))
		if na <= 9:
			rows.append(_r(id, "story", "📖", "Read a bedtime story", "Every night, if you can"))
		if na >= 5 and na <= 8:
			rows.append(_r(id, "teach_bike", "🚲", "Teach them to ride a bike", "Scraped knees included"))
		if na >= 6 and na <= 18 and not lives_with_ex(n):
			rows.append(_r(id, "homework", "✏️", "Help with homework", "School %d%%" % int(n.get("school", 50))))
		if na >= 8 and na <= 17:
			rows.append(_g(id, "discipline", "🧑‍🏫", "Discipline", "When they act out", true))
			rows.append(_r(id, "allowance", "🪙", "Give an allowance", GameState.fmt_money(Actions._cost(300)) + " a year"))
		if na >= 15 and na <= 18 and Law.has_license("driver"):
			rows.append(_r(id, "teach_drive", "🚗", "Teach them to drive", "Nerves of steel required"))
		if na >= 10 and na <= 18:
			rows.append(_r(id, "talk_life", "💡", "Talk about life", "Friends, dating, peer pressure"))
		if na < 18:
			rows.append(_r(id, "fund", "🏦", "Add to their college fund", "%s saved · adds %s" % [GameState.fmt_money(int(n.get("fund", 0))), GameState.fmt_money(Actions._cost(5000))]))
		if na >= 17 and na <= 24 and not n.get("tuition_paid", false):
			rows.append(_r(id, "pay_tuition", "🎓", "Pay for their college", GameState.fmt_money(Actions._cost(40000)) + " (their fund covers %s)" % GameState.fmt_money(int(n.get("fund", 0)))))
		if na >= 18:
			rows.append(_r(id, "advice_give", "🗝️", "Give them life advice", "They might even listen"))
			if int(n.get("kids", 0)) > 0:
				rows.append(_r(id, "babysit", "🧸", "Babysit the grandkids", "Spoil them rotten"))
		if na >= 16:
			rows.append(_r(id, "disown", "✂️", "Disown them", "There's no coming back from this"))
	if rel in ["grandchild", "niece_nephew"]:
		if na <= 12:
			rows.append(_r(id, "play", "🧸", "Play together", "Hide and seek"))
			rows.append(_r(id, "story", "📖", "Tell them a story", "About when you were young"))
		rows.append(_r(id, "spoil", "🍭", "Spoil them", GameState.fmt_money(Actions._cost(150))))
		if na < 18:
			rows.append(_r(id, "fund", "🏦", "Put money toward their future", GameState.fmt_money(Actions._cost(5000))))
	return {"icon": "👪", "title": "Family · " + n["first"], "rows": rows}


func _romance_menu(id: String, n: Dictionary) -> Dictionary:
	var p := _p()
	var st: String = p.get("partner_status", "dating")
	var rows: Array = []
	var age: int = p["age"]
	rows.append({"icon": "🍷", "name": "Date night", "sub": "Pick a place", "menu": "daily:date_venues:" + id, "on": GameState.can_interact(id, "date")})
	rows.append(_r(id, "romantic", "🕯️", "A romantic evening at home", "Candles, music, the two of you"))
	rows.append(_r(id, "love_note", "💌", "Leave a love note", "Small things count"))
	if st == "dating" and age >= 18 and not n.get("living_together", false):
		rows.append(_r(id, "move_in", "📦", "Ask to move in together", "Share the rent, share the bathroom"))
	if st == "dating" and age >= 18:
		rows.append(_g(id, "propose", "💍", "Propose", "Ring and place matter"))
	if st == "engaged":
		rows.append(_r(id, "wedding", "💒", "Plan the wedding", "Courthouse to castle, prenup, honeymoon"))
		rows.append(_r(id, "call_off", "🥀", "Call off the engagement", "Cold feet"))
	if st == "married":
		rows.append(_r(id, "anniversary", "🥂", "Celebrate your anniversary", "%d years together" % maxi(0, age - int(p.get("married_at", age)))))
		rows.append(_r(id, "renew_vows", "💐", "Renew your vows", GameState.fmt_money(Actions._cost(5000))))
	if int(n["closeness"]) < 60:
		rows.append(_r(id, "counseling", "🛋️", "Couples counseling", GameState.fmt_money(Actions._cost(400))))
	if age >= 18 and age <= 55:
		rows.append(_r(id, "baby", "👶", "Try for a baby", "Or start the conversation"))
		rows.append({"icon": "🧬", "name": "Fertility options", "sub": "IVF, surrogacy, adoption", "menu": "daily:fertility", "on": true})
	if st == "married":
		rows.append(_g(id, "divorce", "💔", "Divorce", "Prenup, assets, custody"))
	else:
		rows.append(_r(id, "breakup", "💔", "Break up", "It's over"))
	return {"icon": "💞", "title": "Romance · " + n["first"], "rows": rows}


func _propose_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = []
	var ring := best_ring()
	var rtxt := "No ring (buy one at the jeweler first)" if ring.is_empty() else "Using your %s" % str(ring["name"]).to_lower()
	for v in [["home", "🏠", "At home, just the two of us", 0], ["restaurant", "🍽️", "At a fancy restaurant", 300], ["beach", "🏖️", "On a beach at sunset", 900], ["public", "🎆", "In front of a crowd", 150], ["family", "👪", "At a family dinner", 80]]:
		rows.append({"icon": v[1], "name": v[2], "sub": rtxt + (" · " + GameState.fmt_money(Actions._cost(int(v[3]))) if int(v[3]) > 0 else ""), "act": "bond:%s:propose" % id, "arg": v[0], "on": GameState.can_interact(id, "propose")})
	return {"icon": "💍", "title": "Propose to " + n["first"], "rows": rows}


func _divorce_menu(id: String, n: Dictionary) -> Dictionary:
	var p := _p()
	var kids := minor_children()
	var pre := "You signed a prenup: you each keep what's yours." if p.get("prenup", false) else "No prenup: they can take up to half of everything."
	var rows: Array = [
		{"icon": "🤝", "name": "Amicable divorce", "sub": pre + (" · shared custody" if not kids.is_empty() else ""), "act": "bond:%s:divorce" % id, "arg": "amicable", "on": true},
		{"icon": "⚖️", "name": "Fight it out in court", "sub": GameState.fmt_money(Actions._cost(25000)) + " in lawyers · win more, or lose more" + (" · fight for full custody" if not kids.is_empty() else ""), "act": "bond:%s:divorce" % id, "arg": "court", "on": true},
	]
	if not kids.is_empty():
		rows.append({"icon": "🧳", "name": "Let them have the kids", "sub": "A cheaper, quieter divorce. You'll see the kids on weekends.", "act": "bond:%s:divorce" % id, "arg": "give_custody", "on": true})
	return {"icon": "💔", "title": "Divorce " + n["first"], "rows": rows}


func _friend_menu(id: String, n: Dictionary) -> Dictionary:
	var rel: String = n["relation"]
	var p := _p()
	var age: int = p["age"]
	var rows: Array = []
	match rel:
		"boss":
			rows.append(_r(id, "suck_up", "🍎", "Suck up", "Coworkers will notice"))
			rows.append(_r(id, "boss_lunch", "🥪", "Invite them to lunch", "Talk shop"))
			rows.append(_r(id, "complain", "📝", "Complain about your workload", "Risky"))
		"coworker", "former_coworker":
			rows.append(_r(id, "lunch", "🥪", "Get lunch together", "Talk about anything but work"))
			rows.append(_r(id, "gossip", "🤫", "Gossip about the office", "Who's dating who"))
			rows.append(_r(id, "cover", "🔁", "Cover their shift", "They'll owe you"))
			rows.append(_r(id, "report", "🧑‍💼", "Report them to HR", "Nuclear option"))
		"teacher":
			rows.append(_r(id, "suck_up", "🍎", "Suck up", "Teacher's pet"))
			rows.append(_r(id, "extra_help", "📐", "Ask for extra help", "After class"))
			rows.append(_r(id, "act_up", "🤪", "Act up in class", "Get a laugh"))
		"classmate":
			rows.append(_r(id, "study", "📚", "Study together", "Two brains"))
			rows.append(_r(id, "sit_with", "🍱", "Sit with them at lunch", "Social points"))
			rows.append(_r(id, "copy", "📄", "Copy their homework", "Don't get caught"))
		"neighbor":
			rows.append(_r(id, "borrow", "🥣", "Borrow something", "A cup of sugar, a ladder"))
			rows.append(_r(id, "bbq", "🍖", "Invite them to a barbecue", GameState.fmt_money(Actions._cost(80))))
			rows.append(_r(id, "noise", "📣", "Complain about the noise", "At 2 a.m., every night"))
		"ex":
			rows.append(_r(id, "call", "📞", "Call them", "Just to talk"))
			if int(n["closeness"]) >= 60 and p["partner"] == "":
				rows.append(_r(id, "rekindle", "🔥", "Try to rekindle things", "Second chances"))
			rows.append(_r(id, "move_on", "🚪", "Move on for good", "Lose their number"))
	if rel in FRIENDS or rel in ["classmate", "crush", "neighbor", "coworker"]:
		if age >= 13:
			rows.append(_r(id, "party", "🎉", "Go to a party together", "Who knows who'll be there"))
		if age >= 16 and int(n["age"]) >= 16:
			rows.append(_r(id, "set_up", "💘", "Ask them to set you up", "They know someone") if p["partner"] == "" else _r(id, "double", "👫", "Go on a double date", "Bring your partner"))
		if age >= 18 and int(n["age"]) >= 18:
			rows.append(_r(id, "favor", "🙌", "Ask for a favor", "Help moving, a ride, a place to crash"))
		if rel == "friend" and int(n["closeness"]) >= 75:
			rows.append(_r(id, "best_friend", "🤞", "Ask to be best friends", "You can only have one"))
		if rel in ["classmate", "crush", "coworker", "neighbor"] and int(n["closeness"]) >= 40:
			rows.append(_r(id, "befriend", "🙋", "Ask to be friends", "Make it official"))
		if age >= 14 and p["partner"] == "" and (int(n["age"]) >= 18) == (age >= 18):
			rows.append(_r(id, "ask_out", "💘", "Ask them out", "Heart in your throat"))
		if rel in FRIENDS:
			rows.append(_r(id, "unfriend", "🚫", "End the friendship", "Drift apart on purpose"))
	return {"icon": "🤝", "title": _social_title(rel) + " · " + n["first"], "rows": rows}


func _conflict_menu(id: String, n: Dictionary) -> Dictionary:
	var age: int = _p()["age"]
	var rows: Array = [
		_r(id, "argue", "😤", "Argue", "Get it off your chest"),
		_r(id, "insult", "🗯️", "Insult them", "Words can hurt"),
	]
	if age >= 8:
		rows.append(_r(id, "prank", "🎭", "Prank them", "Might be funny"))
	if age >= 12:
		rows.append(_r(id, "rumor", "🗣️", "Spread a rumor", "They'll find out who started it"))
	if age >= 10:
		rows.append(_r(id, "fight", "👊", "Start a fight", "Assault is a crime"))
	if age >= 18:
		rows.append({"icon": "⚖️", "name": "Sue them", "sub": "Lawyer up", "act": "bond:%s:sue" % id, "arg": null, "on": true})
	if int(n.get("grudge", 0)) >= 20:
		rows.append({"icon": "🕊️", "name": "Make amends", "sub": "Apologize properly · 1 time", "act": "bond:%s:amends" % id, "arg": null, "on": true})
	elif int(n["closeness"]) < 40:
		rows.append(_r(id, "apologize", "🙇", "Apologize", "For whatever it was"))
	if n["relation"] in ["rival", "enemy", "ex"]:
		rows.append(_r(id, "make_peace", "🕊️", "Make peace", "Bury the hatchet"))
	return {"icon": "😤", "title": "Conflict · " + n["first"], "rows": rows}


func _pet_menu(id: String, n: Dictionary) -> Dictionary:
	var rows: Array = [
		_r(id, "pet_play", "🎾", "Play", "Best part of the day"),
		_r(id, "pet_walk", "🦮", "Go for a walk", "Fresh air for both of you"),
		_r(id, "pet_train", "🦴", "Train them", "Sit, stay, don't eat the couch"),
		_r(id, "pet_bathe", "🛁", "Give them a bath", "They'll hate it"),
		_r(id, "pet_feed", "🥣", "Feed them properly", "A real meal. Fed and bond up"),
		_r(id, "pet_treat", "🍖", "Give a treat", "Good boy, good girl"),
		_r(id, "pet_vet", "🩺", "Take to the vet", GameState.fmt_money(Actions._cost(200))),
		_r(id, "pet_rehome", "🏠", "Give them away", "Find them a new home"),
	]
	return {"icon": U_face(n), "title": n["first"], "rows": rows, "person": id}


func best_ring() -> Dictionary:
	var best := {}
	for it in _p().get("possessions", []):
		if str(it.get("tag", "")) in ["ring", "fake_ring"] or str(it.get("name", "")).to_lower().contains("ring"):
			if best.is_empty() or int(it.get("value", 0)) > int(best.get("value", 0)):
				best = it
	return best


func minor_children() -> Array:
	return GameState.npcs_with("child").filter(func(c): return int(GameState.npcs[c]["age"]) < 18)


# ================================================================ actions


## What each interaction actually moves, over and above general warmth.
##
## The point of splitting bonds apart is that different acts buy different
## things. Money bought affection in the old model; here it buys obligation,
## which is a debt somebody may resent. Keeping your word buys trust, which is
## the only thing that makes anyone believe you later. Winning an argument buys
## nothing at all except resentment.
const ACTION_BONDS := {
	# warmth
	"gift": {"affection": 4.0}, "give_item": {"affection": 6.0, "obligation": 6.0},
	"compliment": {"affection": 2.0}, "love_note": {"affection": 3.0, "romance": 5.0},
	"deep_talk": {"trust": 6.0, "affection": 3.0}, "talk_life": {"trust": 5.0},
	"sit_with": {"affection": 5.0, "trust": 3.0}, "care": {"affection": 6.0, "trust": 5.0},
	"call": {"affection": 2.0}, "visit": {"affection": 3.0},
	# trust is earned by doing what you said you would
	"advice": {"trust": 3.0, "respect": 2.0}, "advice_give": {"trust": 4.0, "respect": 3.0},
	"homework": {"trust": 3.0, "respect": 3.0}, "extra_help": {"trust": 4.0},
	"teach_bike": {"trust": 5.0, "respect": 4.0}, "teach_drive": {"trust": 5.0, "respect": 4.0},
	"study": {"respect": 3.0}, "cover": {"trust": 6.0, "obligation": 9.0},
	"favor": {"obligation": 10.0, "trust": 3.0}, "babysit": {"trust": 5.0, "obligation": 8.0},
	"amends": {"trust": 7.0, "resentment": -18.0}, "apologize": {"trust": 4.0, "resentment": -14.0},
	"make_peace": {"resentment": -25.0, "trust": 5.0},
	# money creates debt, not love
	"give_money": {"obligation": 14.0, "affection": 2.0},
	"lend": {"obligation": 20.0, "trust": 2.0},
	"collect": {"obligation": -22.0, "resentment": 5.0},
	"ask_money": {"respect": -4.0, "obligation": -6.0},
	"borrow": {"respect": -3.0}, "allowance": {"obligation": 5.0},
	"fund": {"obligation": 10.0, "respect": 4.0}, "pay_tuition": {"obligation": 14.0, "respect": 5.0},
	"ask_tuition": {"respect": -5.0}, "spoil": {"affection": 4.0, "respect": -3.0},
	# status and standing
	"suck_up": {"respect": -4.0, "trust": -2.0}, "boss_lunch": {"respect": 3.0},
	"act_up": {"respect": -6.0}, "copy": {"respect": -5.0, "trust": -4.0},
	"party_for": {"affection": 6.0, "respect": 3.0},
	# damage
	"insult": {"resentment": 14.0, "affection": -8.0, "respect": -4.0},
	"argue": {"resentment": 9.0, "affection": -5.0},
	"squabble": {"resentment": 5.0}, "prank": {"resentment": 6.0, "respect": -3.0},
	"rumor": {"resentment": 16.0, "trust": -14.0}, "gossip": {"trust": -6.0},
	"fight": {"resentment": 26.0, "affection": -18.0}, "rumble": {"resentment": 22.0},
	"report": {"resentment": 20.0, "trust": -16.0}, "complain": {"resentment": 8.0},
	"sue": {"resentment": 32.0, "trust": -22.0}, "noise": {"resentment": 7.0},
	"disown": {"resentment": 45.0, "affection": -45.0}, "cut_off": {"resentment": 30.0, "affection": -30.0},
	"unfriend": {"resentment": 12.0, "affection": -25.0},
	"custody_fight": {"resentment": 26.0, "trust": -12.0},
	"give_custody": {"resentment": -8.0, "respect": -6.0},
	"disc_yell": {"resentment": 9.0, "trust": -5.0}, "disc_ground": {"resentment": 5.0, "respect": 3.0},
	"disc_talk": {"trust": 5.0, "respect": 4.0}, "disc_ignore": {"respect": -6.0, "trust": -3.0},
	# romance is its own track
	"romance": {"romance": 9.0}, "romantic": {"romance": 10.0, "affection": 4.0},
	"ask_out": {"romance": 8.0}, "propose": {"romance": 12.0, "trust": 8.0},
	"engaged": {"romance": 10.0, "trust": 6.0}, "wedding": {"romance": 12.0, "trust": 10.0},
	"married": {"romance": 8.0, "trust": 8.0}, "anniversary": {"romance": 9.0, "affection": 5.0},
	"renew_vows": {"romance": 14.0, "trust": 8.0, "resentment": -10.0},
	"counseling": {"trust": 8.0, "resentment": -14.0, "romance": 3.0},
	"rekindle": {"romance": 16.0, "affection": 6.0},
	"breakup": {"romance": -45.0, "resentment": 12.0}, "divorce": {"romance": -60.0, "resentment": 20.0},
	"amicable": {"resentment": -12.0}, "move_on": {"romance": -30.0},
	"double": {"romance": 4.0, "affection": 3.0}, "set_up": {"obligation": 6.0},
	# animals keep it simple
	"pet_play": {"affection": 4.0}, "pet_walk": {"affection": 3.0}, "pet_train": {"trust": 6.0},
	"pet_treat": {"affection": 4.0}, "pet_bathe": {"trust": 2.0}, "pet_vet": {"trust": 5.0},
}

## Public entry point. Runs the interaction, then applies what that particular
## act buys in the bond - but only if the act actually happened, since most
## handlers can bail on time, money or having already done it this year.
func act(key: String, arg = null) -> void:
	var parts := key.split(":")
	if parts.size() < 2:
		_act(key, arg)
		return
	var id: String = parts[0]
	var aid: String = parts[1]
	var before_close := int(GameState.npc(id).get("closeness", -1))
	var before_free := GameState.can_interact(id, aid)
	_act(key, arg)
	if aid.begins_with("pet_") and GameState.npcs.has(id):
		Companions.tend(id, 25.0 if aid == "pet_feed" else (10.0 if aid == "pet_treat" else 0.0))
		if aid == "pet_vet":
			Companions.cure(id)
	if not GameState.npcs.has(id):
		return
	var ran := (before_free and not GameState.can_interact(id, aid)) or int(GameState.npc(id).get("closeness", -1)) != before_close
	if ran and ACTION_BONDS.has(aid):
		BondStats.apply(id, ACTION_BONDS[aid])


func _act(key: String, arg = null) -> void:
	var parts := key.split(":")
	if parts.size() < 2:
		return
	var id: String = parts[0]
	var aid: String = parts[1]
	var n := ensure(id)
	if n.is_empty() or not n["alive"]:
		return
	var p := _p()
	var nm: String = n["first"]
	var he := _he(n)
	if aid in ["ask_money", "ask_tuition", "move_back"]:
		GameState.counter("mooch")
	elif aid in ["give_money", "gift", "lend", "pay_tuition", "fund", "spoil", "give_item"]:
		GameState.counter("generous")
	match aid:
		"conversation":
			if not _once(id, aid): return
			var t := _pick(TOPICS)
			if int(n["craziness"]) > 70 and randf() < 0.3:
				_res(id, "💬", "I tried to chat with %s about %s. %s started ranting about the government putting chips in bananas." % [nm, t, _cap(he)], 1, {"stress": 2})
			elif _roll(n, 0.75):
				var extra := ""
				if randf() < 0.25 and not n.get("likes_known", false):
					n["likes_known"] = true
					extra = " I found out %s's really into %s." % [he, LIKES[n["likes"]][1]]
				_res(id, "💬", "I talked with %s about %s.%s" % [nm, t, extra], 5, {"happiness": 1})
			else:
				_res(id, "💬", "I talked with %s about %s. It turned into an argument." % [nm, t], -6, {"stress": 3}, "argued with me about %s" % t)
		"compliment":
			if not _once(id, aid): return
			var what := _pick(["%s cooking" % _his(n), "%s taste in music" % _his(n), "how %s handled a hard year" % he, "%s laugh" % _his(n), "%s new haircut" % _his(n), "how good %s looks" % he])
			if _roll(n, 0.8):
				_res(id, "🌟", "I complimented %s on %s. %s lit up." % [nm, what, _cap(he)], 6)
			else:
				_res(id, "🌟", "I complimented %s on %s. %s thought I was being sarcastic." % [nm, what, _cap(he)], -3)
		"deep_talk":
			if not _once(id, aid): return
			n["likes_known"] = true
			var revel := _pick(["a secret dream of opening a bakery", "how lonely %s's been" % he, "a regret %s's carried for years" % he, "that %s's scared of getting old" % he, "a story about %s childhood I'd never heard" % _his(n), "how proud of me %s is" % he])
			if _roll(n, 0.7):
				_res(id, "🫂", "%s and I talked until late. %s told me about %s. We're closer than ever." % [nm, _cap(he), revel], 12, {"happiness": 4, "stress": -3}, "opened up to me")
			else:
				_res(id, "🫂", "I tried to have a real conversation with %s, but %s kept changing the subject." % [nm, he], 1)
		"hang":
			_hang(id, n, str(arg))
		"confide":
			if not _once(id, aid): return
			if not Actions._out_of_time():
				var burden := randf() < 0.22
				if burden:
					BondStats.apply(id, {"trust": -6.0, "resentment": 8.0})
					_res(id, "🔐", "I told %s something I had never said out loud. %s went quiet, and I watched them file it away somewhere." % [nm, _cap(he)], -2, {"stress": 4}, "heard the worst of me")
				else:
					BondStats.apply(id, {"trust": 9.0, "affection": 7.0})
					_res(id, "🔐", "I told %s the truth about something. %s did not flinch, and did not bring it up again." % [nm, _cap(he)], 8, {"stress": -10, "happiness": 6}, "kept the thing I told them")
		"call_in":
			if not _once(id, aid): return
			var debt := BondStats.get_stat(id, "obligation")
			var willing := debt / 100.0 + float(n.get("generosity", 50)) / 220.0
			if randf() < willing:
				var worth := Actions._cost(int(debt * randf_range(60.0, 260.0)))
				p["money"] = int(p["money"]) + worth
				BondStats.apply(id, {"obligation": -debt, "resentment": 6.0})
				_res(id, "📒", "I reminded %s what %s owed me. %s paid it, and something small went out of the room with it." % [nm, he, _cap(he)], -3, {"money": worth}, "was made to settle up")
			else:
				BondStats.apply(id, {"obligation": -debt * 0.4, "resentment": 18.0})
				_res(id, "📒", "I asked %s to make good on it. %s said %s did not remember it that way." % [nm, _cap(he), he], -10, {"stress": 6}, "was asked to pay up and refused")
		"vouch":
			if not _once(id, aid): return
			if not Actions._out_of_time():
				var weight := BondStats.get_stat(id, "respect") / 100.0
				if randf() < weight:
					GameState.set_flag("vouched_for")
					BondStats.apply(id, {"obligation": 22.0})
					_res(id, "🖋️", "%s put their name behind mine. That is not a small thing to ask, and it is not a small thing to give." % _cap(nm), 4, {"happiness": 6}, "vouched for me")
				else:
					BondStats.apply(id, {"respect": -4.0})
					_res(id, "🖋️", "%s said %s would rather not, and could not quite look at me while saying it." % [_cap(nm), he], -6, {"happiness": -6, "stress": 5})
		"clear_air":
			if not _once(id, aid): return
			if not Actions._out_of_time():
				var held := BondStats.get_stat(id, "resentment")
				var honest := randf() < clampf(0.32 + BondStats.get_stat(id, "affection") / 180.0 + GameState.stat("smarts") / 400.0, 0.2, 0.85)
				if honest:
					BondStats.apply(id, {"resentment": -held * 0.65, "trust": 8.0, "affection": 5.0})
					_res(id, "🕊️", "We finally said the thing out loud. It was not a good afternoon, and it was the right one." % [], 6, {"stress": -12, "happiness": 7}, "talked it out with me properly")
				else:
					BondStats.apply(id, {"resentment": 10.0})
					_res(id, "🕊️", "I tried to raise it with %s. We got about four sentences in before it became the same argument again." % nm, -5, {"stress": 8})
		"lean":
			if not _once(id, aid): return
			if not Actions._out_of_time():
				BondStats.apply(id, {"obligation": -18.0, "affection": 4.0})
				_res(id, "🫂", "I asked %s for more than I usually would. %s just said yes, and then asked what else." % [nm, _cap(he)], 5, {"stress": -16, "happiness": 9}, "carried me through something")
		"prove":
			if not _once(id, aid): return
			if not Actions._out_of_time():
				var shot := clampf(GameState.stat("smarts") / 220.0 + float(p["job"].get("perf", 50)) / 260.0 + 0.16, 0.15, 0.8)
				if randf() < shot:
					BondStats.apply(id, {"respect": 22.0})
					_res(id, "💪", "I did the thing %s never thought I would. %s did not say much, but %s looked at me differently afterwards." % [nm, _cap(he), he], 3, {"happiness": 8}, "was proved wrong about me")
				else:
					BondStats.apply(id, {"respect": -5.0})
					_res(id, "💪", "I tried to show %s what I could do. It did not go the way I had pictured it on the way over." % nm, -3, {"happiness": -7, "stress": 7})
		"gift":
			_gift(id, n, str(arg))
		"give_item":
			if not _once(id, "gift"): return
			var idx := int(arg)
			if idx < 0 or idx >= p["possessions"].size(): return
			var it: Dictionary = p["possessions"][idx]
			p["possessions"].remove_at(idx)
			n["gifted"] = n.get("gifted", []) + [it]
			var val := int(it.get("value", 0))
			var d := clampi(6 + val / 1500, 6, 35)
			var mm := "gave me their %s" % str(it["name"]).to_lower()
			if it.get("heirloom", false):
				d += 10
				mm = "gave me a family heirloom"
			_res(id, it.get("icon", "🎁"), "I gave %s my %s. %s couldn't believe it." % [nm, str(it["name"]).to_lower(), _cap(he)], d, {"karma": 2}, mm)
		"ask_money":
			if not _once(id, aid): return
			var wealth := int(n.get("money", 5000))
			var gen := float(n.get("generosity", 50))
			if int(n["closeness"]) >= 45 and randf() < 0.3 + gen / 200.0:
				var amt := clampi(int(wealth * randf_range(0.01, 0.06)), 10 if int(p["age"]) < 16 else 50, 200000)
				n["money"] = maxi(0, wealth - amt)
				_res(id, "💵", "I asked %s for money. %s handed me %s%s." % [nm, _cap(he), GameState.fmt_money(amt), "" if int(p["age"]) < 18 else " and a look"], -3, {"money": amt})
			else:
				_res(id, "💵", _pick(["%s laughed and said money doesn't grow on trees." % nm, "%s said no, and asked what I'd done with the last lot." % nm, "%s said %s's broke too." % [nm, he]]), -5, {"happiness": -2})
		"give_money":
			if not _once(id, "give_money"): return
			var amt2 := int(arg)
			if int(p["money"]) < amt2: return
			n["money"] = int(n.get("money", 0)) + amt2
			var d2 := clampi(4 + int(log(float(amt2)) / log(10.0) * 4.0), 4, 26)
			_res(id, "💸", "I gave %s %s. %s" % [nm, GameState.fmt_money(amt2), _pick(["%s hugged me." % _cap(he), "%s tried to refuse, then took it." % _cap(he), "%s cried a little." % _cap(he)])], d2, {"money": -amt2, "karma": 2}, "gave me money when I needed it")
		"lend":
			if not _once(id, aid): return
			var amt3 := Actions._cost(2000)
			if not Actions._can_pay(amt3, "Loan"): return
			n["owes"] = int(n.get("owes", 0)) + amt3
			n["money"] = int(n.get("money", 0)) + amt3
			_res(id, "🤝", "I lent %s %s. %s promised to pay me back." % [nm, GameState.fmt_money(amt3), _cap(he)], 6, {"money": -amt3})
		"collect":
			if not _once(id, aid): return
			var owed := int(n.get("owes", 0))
			if _roll(n, 0.55) and int(n.get("money", 0)) >= owed / 2:
				n["owes"] = 0
				_res(id, "📒", "%s paid me back the %s. Every cent." % [nm, GameState.fmt_money(owed)], 3, {"money": owed})
			else:
				_res(id, "📒", "%s said %s'd pay me back \"soon\". %s's been saying that for a while." % [nm, he, _cap(he)], -6, {"stress": 3}, "still owes me money")
		"advice":
			if not _once(id, aid): return
			var good := float(n["smarts"]) / 100.0
			if randf() < good:
				_res(id, "🧓", "I asked %s for advice. %s" % [nm, _pick(["\"Never sign anything you haven't read.\" Wise.", "\"Buy the good mattress.\" I did.", "\"Don't marry someone who's rude to waiters.\" Noted.", "\"The job will never love you back.\" That one stuck."])], 6, {"smarts": 2, "stress": -3})
			else:
				_res(id, "🧓", "I asked %s for advice. %s" % [nm, _pick(["\"Put it all in lottery tickets.\" I did not.", "%s told me to just walk in and demand a promotion. I didn't." % _cap(he), "The advice was about 1978 and not very useful."])], 3, {})
		"ask_tuition":
			if not _once(id, aid): return
			var uni: Dictionary = p["education"].get("uni", {})
			var paid := int(n.get("money", 0)) >= 20000 and _roll(n, 0.5)
			if paid:
				var amt4 := mini(int(p.get("loan", 0)) + Actions._cost(15000), int(int(n["money"]) * 0.4))
				n["money"] = int(n["money"]) - amt4
				p["loan"] = maxi(0, int(p.get("loan", 0)) - amt4)
				_res(id, "🎓", "%s agreed to help with college. %s off my loans and tuition." % [nm, GameState.fmt_money(amt4)], 4, {"happiness": 8})
			else:
				_res(id, "🎓", "%s said %s can't afford to help with college%s." % [nm, he, "" if uni.is_empty() else ""], -2, {"stress": 3})
		"move_back":
			if not _once(id, aid): return
			if _roll(n, 0.6):
				p["housing"] = "parents"
				_res(id, "🏠", "%s said I can move back home. My old bedroom still has the posters." % nm, 4, {"happiness": -2, "stress": -4})
			else:
				_res(id, "🏠", "%s said no. \"You're an adult now.\"" % nm, -4, {"happiness": -3})
		"ask_pet":
			if not _once(id, aid): return
			if _roll(n, 0.35):
				var species: String = ["dog", "cat", "rabbit"][randi() % 3]
				var pid := GameState.create_npc("pet", {"species": species, "first": ContentDB.random_pet_name(), "last": "", "age": randi_range(0, 2), "closeness": 75})
				_res(id, "🐶", "I begged for weeks and %s finally caved. Meet %s, our new %s!" % [nm, GameState.npcs[pid]["first"], species], 3, {"happiness": 10})
			else:
				_res(id, "🐶", "\"Who's going to walk it? Not you.\" The answer was no.", -1, {"happiness": -3})
		"ask_later":
			if not _once(id, aid): return
			if _roll(n, 0.4):
				_res(id, "🌙", "%s agreed to push my curfew back an hour. Freedom." % nm, 2, {"happiness": 4})
			else:
				_res(id, "🌙", "\"Not under my roof.\"", -2, {"happiness": -2})
		"party_for":
			if not _once(id, aid): return
			var c1 := Actions._cost(250)
			if not Actions._can_pay(c1, "Party"): return
			_res(id, "🎂", "I threw %s a surprise birthday party. %s pretended not to cry." % [nm, _cap(he)], 14, {"money": -c1, "happiness": 5}, "threw me a surprise party")
		"care":
			if not _once(id, aid): return
			_care(id, n)
		"cut_off":
			n["cut_off"] = true
			n["closeness"] = 0
			remember(id, "cut me out of their life", false)
			Grit.grudge(id, 30)
			Actions._done("✂️", nm, "I told %s I was done. I blocked %s number." % [nm, _his(n)], {"stress": -3, "happiness": -4})
		"squabble":
			if not _once(id, aid): return
			var about := _pick(["the TV remote", "who got the bigger slice", "whose turn it is to do the dishes", "a borrowed sweater that was never returned", "who Mom loves more"])
			_res(id, "🙄", "%s and I squabbled about %s." % [nm, about], -5 if randf() < 0.6 else 2, {"stress": 2})
		"rumble":
			if not _once(id, aid): return
			var win := randf() < 0.45 + (GameState.stat("health") - 50.0) / 200.0 + (0.1 if int(p["age"]) > int(n["age"]) else -0.1)
			_res(id, "🤼", ("I pinned %s on the living room floor. Victory." % nm) if win else ("%s put me in a headlock until I said uncle." % nm), -8, {"health": -2 if win else -5, "happiness": 3 if win else -3})
		"prank":
			if not _once(id, aid): return
			var pr := _pick(["put salt in %s coffee" % _his(n), "hid %s shoes" % _his(n), "set every alarm in %s room to 3 a.m." % _his(n), "wrapped %s car in plastic wrap" % _his(n), "replaced %s shampoo with mayonnaise" % _his(n)])
			if randf() < 0.55 - float(n["craziness"]) / 300.0:
				_res(id, "🎭", "I %s. %s laughed eventually." % [pr, nm], 3, {"happiness": 5})
			elif randf() < 0.5:
				_res(id, "🎭", "I %s. %s was not amused." % [pr, nm], -10, {}, "pranked me")
			else:
				_res(id, "🎭", "I %s. A week later %s got me back, twice as hard." % [pr, nm], -4, {"happiness": -4, "stress": 3})
		"favor":
			if not _once(id, aid): return
			if _roll(n, 0.6):
				_res(id, "🙌", "%s %s. I owe %s one." % [nm, _pick(["helped me move a couch up four flights of stairs", "drove me to the airport at 5 a.m.", "let me crash on %s couch for a week" % _his(n), "fixed my leaky sink"]), _him(n)], 2, {"stress": -5, "money": Actions._cost(150)})
			else:
				_res(id, "🙌", "%s was \"busy\". Again." % nm, -4, {"stress": 2})
		"babysit":
			if not _once(id, aid): return
			for kid in GameState.npcs.keys():
				var kn: Dictionary = GameState.npcs[kid]
				if kn["alive"] and str(kn.get("parent_id", "")) == id:
					GameState.change_closeness(kid, 10)
			_res(id, "🧸", "I babysat %s's kids for the weekend. Nobody went to the hospital. %s owes me." % [nm, _cap(he)], 8, {"stress": 4, "happiness": 4}, "babysat my kids")
		"play":
			if not _once(id, aid): return
			_res(id, "🧸", "I played %s with %s. %s" % [_pick(["hide and seek", "tag in the yard", "with building blocks", "tea party", "pirates", "a very long game of pretend"]), nm, _pick(["Best afternoon in ages.", "I was the dragon. I'm always the dragon.", "I let %s win. Mostly." % _him(n)])], 10, {"happiness": 5, "stress": -3})
		"story":
			if not _once(id, aid): return
			n["smarts"] = mini(100, int(n["smarts"]) + 2)
			_res(id, "📖", "I read %s %s. %s asleep before the end." % [nm, _pick(["a story about a dragon who's afraid of the dark", "the same book for the fortieth time", "a chapter of a book about a wizard school", "a story I made up about a flying pig"]), _cap(he) + " was"], 8, {"happiness": 4})
		"teach_bike":
			if not _once(id, aid): return
			if randf() < 0.7:
				_res(id, "🚲", "I ran behind %s holding the seat, then let go. %s didn't even notice. %s can ride!" % [nm, _cap(he), _cap(he)], 12, {"happiness": 6}, "taught me to ride a bike")
			else:
				_res(id, "🚲", "%s fell off, skinned both knees and refused to try again. Next year." % nm, 2, {"stress": 2})
		"homework":
			if not _once(id, aid): return
			var boost := 4 + int(GameState.stat("smarts") / 20.0)
			n["school"] = clampi(int(n.get("school", 50)) + boost, 0, 100)
			_res(id, "✏️", "I helped %s with %s homework. %s" % [nm, _his(n), _pick(["Turns out I don't remember long division.", "We figured out the science project together.", "Fractions finally clicked for %s." % _him(n)])], 6, {"stress": 2})
		"disc_talk", "disc_ground", "disc_yell", "disc_ignore":
			if not _once(id, "discipline"): return
			_discipline(id, n, aid)
		"allowance":
			if not _once(id, aid): return
			var c2 := Actions._cost(300)
			if not Actions._can_pay(c2, "Allowance"): return
			n["money"] = int(n.get("money", 0)) + c2
			_res(id, "🪙", "I gave %s an allowance this year. %s spent it all on %s." % [nm, _cap(he), _pick(["candy", "trading cards", "a video game", "slime supplies", "stickers"])], 6, {"money": -c2})
		"teach_drive":
			if not _once(id, aid): return
			if randf() < 0.75:
				n["can_drive"] = true
				_res(id, "🚗", "I taught %s to drive. We only mounted the curb twice. %s passed %s test." % [nm, _cap(he), _his(n)], 10, {"stress": 6}, "taught me to drive")
			else:
				_res(id, "🚗", "%s backed my car into a mailbox. Lesson over." % nm, 2, {"stress": 8, "money": -Actions._cost(600)})
		"talk_life":
			if not _once(id, aid): return
			n["guided"] = int(n.get("guided", 0)) + 1
			_res(id, "💡", "I talked with %s about %s. %s actually listened." % [nm, _pick(["peer pressure", "dating", "why grades matter", "social media", "standing up to bullies", "what %s wants to be" % he]), _cap(he)], 8, {})
		"fund":
			if not _once(id, aid): return
			var c3 := Actions._cost(5000)
			if not Actions._can_pay(c3, "College fund"): return
			n["fund"] = int(n.get("fund", 0)) + c3
			_res(id, "🏦", "I put %s into %s's college fund. %s saved so far." % [GameState.fmt_money(c3), nm, GameState.fmt_money(int(n["fund"]))], 3, {"money": -c3})
		"pay_tuition":
			if not _once(id, aid): return
			var tot := Actions._cost(40000)
			var need := maxi(0, tot - int(n.get("fund", 0)))
			if not Actions._can_pay(need, "Tuition"): return
			n["fund"] = 0
			n["tuition_paid"] = true
			n["degree"] = true
			_res(id, "🎓", "I paid for %s's college%s. %s hugged me at the gate." % [nm, "" if need == 0 else " (%s out of pocket)" % GameState.fmt_money(need), _cap(he)], 18, {"money": -need, "happiness": 6}, "paid for my college")
		"advice_give":
			if not _once(id, aid): return
			_res(id, "🗝️", "I told %s %s. %s" % [nm, _pick(["to save 10% of every paycheck", "that nobody has it figured out", "to call %s mother more" % _his(n) if p["gender"] != "female" else "to call me more", "to never lend money %s can't lose" % he]), _pick(["%s rolled %s eyes, then wrote it down." % [_cap(he), _his(n)], "%s said I sound like Grandpa." % _cap(he), "%s thanked me." % _cap(he)])], 5, {})
		"spoil":
			if not _once(id, aid): return
			var c4 := Actions._cost(150)
			if not Actions._can_pay(c4, "Spoil"): return
			_res(id, "🍭", "I spoiled %s rotten: %s." % [nm, _pick(["ice cream before dinner", "the biggest stuffed bear in the store", "a day at the arcade", "a puppy-shaped cake"])], 12, {"money": -c4, "happiness": 5})
		"visit":
			if not _once(id, aid): return
			_res(id, "🚪", "I had %s for the weekend. %s" % [nm, _pick(["We built a fort out of every blanket I own.", "%s was quiet at first, then wouldn't stop talking." % _cap(he), "Dropping %s off again was the hard part." % _him(n)])], 12, {"happiness": 5, "stress": 2})
		"custody_fight":
			if not _once(id, aid): return
			var fee := Actions._cost(12000)
			if not Actions._can_pay(fee, "Custody"): return
			var odds := 0.35 + (GameState.stat("smarts") - 50.0) / 250.0 + (0.1 if p["record"].is_empty() else -0.2) + (0.1 if int(p["money"]) > 100000 else 0.0)
			if randf() < odds:
				for c in minor_children():
					GameState.npcs[c].erase("custody")
				_res(id, "⚖️", "The judge gave me full custody. %s is coming home." % nm, 15, {"money": -fee, "happiness": 15}, "fought for me in court")
			else:
				_res(id, "⚖️", "The judge ruled against me. Weekends only.", 0, {"money": -fee, "happiness": -12, "stress": 10})
		"disown":
			n["disowned"] = true
			n["closeness"] = 0
			remember(id, "disowned me", false)
			Grit.grudge(id, 55)
			GameState.add_milestone(p["age"], "disowned %s" % GameState.full_name(id))
			Actions._done("✂️", nm, "I disowned %s. %s won't inherit a thing." % [nm, _cap(he)], {"karma": -15, "happiness": -8})
		"romantic":
			if not _once(id, aid): return
			var trying: bool = p.get("trying_baby", false)
			if trying and not p.get("expecting", false) and randf() < fertility_chance(n):
				p["expecting"] = true
				p["trying_baby"] = false
				_res(id, "🕯️", "A quiet evening with %s, and a few weeks later: two pink lines. We're expecting!" % nm, 10, {"happiness": 12})
			else:
				_res(id, "🕯️", "%s and I had a romantic evening at home. %s" % [nm, _pick(["We slow-danced in the kitchen.", "We watched the movie from our first date.", "We ordered too much takeout and talked for hours."])], 9, {"happiness": 5, "stress": -5})
		"love_note":
			if not _once(id, aid): return
			_res(id, "💌", "I left a note in %s's %s. %s kept it." % [nm, _pick(["coat pocket", "lunch bag", "car", "book"]), _cap(he)], 5, {})
		"move_in":
			if not _once(id, aid): return
			if _roll(n, 0.6):
				n["living_together"] = true
				if p["housing"] == "parents" and int(p["age"]) >= 18:
					p["housing"] = "apartment"
				_res(id, "📦", "%s said yes! We moved in together. %s has a lot of shoes." % [nm, _cap(he)], 10, {"happiness": 8})
			else:
				_res(id, "📦", "%s said %s isn't ready to live together." % [nm, he], -6, {"happiness": -4})
		"propose":
			if not _once(id, "propose"): return
			_propose(id, n, str(arg))
		"wedding":
			if not _once(id, aid): return
			_wedding(id, n)
		"call_off":
			p["partner_status"] = "dating"
			_res(id, "🥀", "I called off the engagement. %s gave the ring back without a word." % nm, -30, {"happiness": -8}, "called off our engagement")
		"anniversary":
			if not _once(id, aid): return
			var c5 := Actions._cost(200)
			if int(p["money"]) < c5: c5 = 0
			_res(id, "🥂", "%s and I celebrated our anniversary%s." % [nm, " with dinner at the place we first met" if c5 > 0 else " with a picnic in the park"], 12, {"money": -c5, "happiness": 6}, "never forgets our anniversary")
		"renew_vows":
			if not _once(id, aid): return
			var c6 := Actions._cost(5000)
			if not Actions._can_pay(c6, "Vow renewal"): return
			if _roll(n, 0.7):
				_res(id, "💐", "%s and I renewed our vows in front of everyone we love." % nm, 18, {"money": -c6, "happiness": 12})
				GameState.add_milestone(p["age"], "renewed their vows with %s" % nm)
			else:
				_res(id, "💐", "%s said we don't need a ceremony to prove anything. Money saved, feelings hurt." % nm, -3, {})
		"counseling":
			if not _once(id, aid): return
			var c7 := Actions._cost(400)
			if not Actions._can_pay(c7, "Counseling"): return
			if randf() < 0.65:
				GameState.npcs[id]["grudge"] = 0
				_res(id, "🛋️", "Couples counseling helped. We're actually talking again, %s and I." % nm, 20, {"money": -c7, "stress": -6})
			else:
				_res(id, "🛋️", "Counseling ended with %s storming out halfway through." % nm, -5, {"money": -c7, "stress": 6})
		"baby":
			if not _once(id, aid): return
			if p.get("expecting", false):
				Actions._done("👶", "Baby", "We're already expecting!", {})
				return
			if not _roll(n, 0.6):
				_res(id, "👶", "I brought up having a baby. %s said %s isn't ready." % [nm, he], -4, {"stress": 3})
				return
			p["trying_baby"] = true
			if randf() < fertility_chance(n):
				p["expecting"] = true
				p["trying_baby"] = false
				_res(id, "👶", "%s and I decided to try for a baby, and it happened fast. We're expecting!" % nm, 8, {"happiness": 10})
			else:
				_res(id, "👶", "%s and I are trying for a baby. Nothing yet. (Romantic evenings help.)" % nm, 5, {})
		"divorce":
			_divorce(id, n, str(arg))
		"breakup":
			_res(id, "💔", _pick(["I broke up with %s over dinner. %s threw a breadstick at me." % [nm, _cap(he)], "I broke up with %s. We both cried." % nm, "I ended things with %s by text. Not my finest moment." % nm]), -30, {"happiness": -5}, "broke up with me")
			n["relation"] = "ex"
			n.erase("living_together")
			p["partner"] = ""
			p["partner_status"] = ""
		"suck_up":
			if not _once(id, aid): return
			if n["relation"] == "teacher":
				_res(id, "🍎", "I brought %s an apple and agreed with everything. Teacher's pet." % nm, 8, {"school": 4})
			else:
				for cw in GameState.npcs_with("coworker"):
					GameState.change_closeness(cw, -3)
				_res(id, "🍎", "I laughed at every one of %s's jokes. My coworkers rolled their eyes." % nm, 8, {"job_perf": 4})
		"boss_lunch":
			if not _once(id, aid): return
			_res(id, "🥪", "Lunch with %s went well. %s mentioned a project I might lead." % [nm, _cap(he)], 7, {"job_perf": 3, "money": -Actions._cost(25)})
		"complain":
			if not _once(id, aid): return
			if _roll(n, 0.45):
				_res(id, "📝", "%s actually listened and took a project off my plate." % nm, 2, {"stress": -8})
			else:
				_res(id, "📝", "%s said if I can't handle it, there's a line of people who can." % nm, -8, {"stress": 6, "job_perf": -3}, "complained about the workload")
		"lunch":
			if not _once(id, aid): return
			_res(id, "🥪", "I got lunch with %s. We complained about the printer for 40 minutes." % nm, 7, {"happiness": 2, "money": -Actions._cost(15)})
		"gossip":
			if not _once(id, aid): return
			if randf() < 0.8:
				_res(id, "🤫", "%s told me %s. I'll never unhear it." % [nm, _pick(["the manager is dating someone in accounting", "there are layoffs coming", "the new hire is the CEO's nephew", "who keeps stealing yogurts from the fridge"])], 6, {"happiness": 2})
			else:
				_res(id, "🤫", "Someone overheard us gossiping. Now I'm the story.", -2, {"job_perf": -4, "stress": 4})
		"cover":
			if not _once(id, aid): return
			n["owes_favor"] = true
			_res(id, "🔁", "I covered %s's shift. %s swore %s'd return the favor." % [nm, _cap(he), he], 10, {"stress": 3})
		"report":
			if not _once(id, aid): return
			if randf() < 0.55:
				n["relation"] = "former_coworker"
				_res(id, "🧑‍💼", "HR investigated %s and let %s go." % [nm, _him(n)], -40, {"karma": -4}, "got me fired")
				Grit.grudge(id, 40)
			else:
				_res(id, "🧑‍💼", "HR found nothing. Now everyone knows I went to HR.", -20, {"job_perf": -4, "stress": 6}, "reported me to HR")
		"extra_help":
			if not _once(id, aid): return
			_res(id, "📐", "%s stayed after class to go over the material with me." % nm, 5, {"school": 6, "smarts": 1})
		"act_up":
			if not _once(id, aid): return
			if randf() < 0.5:
				_res(id, "🤪", "I did an impression of %s in class. Everyone laughed. %s gave me detention." % [nm, _cap(he)], -10, {"happiness": 4, "school": -4, "popularity": 6})
			else:
				_res(id, "🤪", "I acted up and got sent to the principal's office.", -8, {"school": -6, "happiness": -2})
		"study":
			if not _once(id, aid): return
			_res(id, "📚", "%s and I studied together. We got more done than I thought we would." % nm, 6, {"school": 5, "smarts": 1})
		"sit_with":
			if not _once(id, aid): return
			_res(id, "🍱", "I sat with %s at lunch. %s traded me %s." % [nm, _cap(he), _pick(["a cookie for my apple", "gossip for gossip", "half a sandwich"])], 7, {"popularity": 2})
		"copy":
			if not _once(id, aid): return
			if randf() < 0.7:
				_res(id, "📄", "I copied %s's homework. Easy A." % nm, -2, {"school": 3})
			else:
				_res(id, "📄", "The teacher noticed our homework had the same mistakes. We both got zeros.", -12, {"school": -8}, "got me in trouble")
		"borrow":
			if not _once(id, aid): return
			_res(id, "🥣", "I borrowed %s from %s. I will definitely return it." % [_pick(["a ladder", "a cup of sugar", "a drill", "their lawnmower"]), nm], 3, {"money": Actions._cost(30)})
		"bbq":
			if not _once(id, aid): return
			var c8 := Actions._cost(80)
			if not Actions._can_pay(c8, "Barbecue"): return
			for nb in GameState.npcs_with("neighbor"):
				GameState.change_closeness(nb, 5)
			_res(id, "🍖", "I had %s and the other neighbors over for a barbecue. %s brought a questionable potato salad." % [nm, _cap(he)], 10, {"money": -c8, "happiness": 5})
		"noise":
			if not _once(id, aid): return
			if _roll(n, 0.5):
				_res(id, "📣", "%s apologized and bought a rug. Peace at last." % nm, -2, {"stress": -6})
			else:
				_res(id, "📣", "%s turned the music up louder." % nm, -12, {"stress": 6}, "complained about my music")
		"call":
			if not _once(id, aid): return
			_res(id, "📞", "I called %s. We talked about %s." % [nm, _pick(["old times", "nothing in particular for two hours", "why it didn't work out", "our new lives"])], 5, {})
		"rekindle":
			if not _once(id, aid): return
			if _roll(n, 0.45):
				Actions.start_dating(id, false)
				_res(id, "🔥", "%s and I are giving it another shot." % nm, 10, {"happiness": 8})
			else:
				_res(id, "🔥", "%s said some doors are closed for a reason." % nm, -10, {"happiness": -5})
		"move_on":
			n["alive_in_list"] = false
			n["relation"] = "former_ex"
			Actions._done("🚪", nm, "I deleted every photo of %s. Onward." % nm, {"happiness": 3, "stress": -3})
		"party":
			if not _once(id, aid): return
			_party(id, n)
		"set_up":
			if not _once(id, aid): return
			var did := GameState.create_npc("crush", {"age": maxi(16, int(p["age"]) + randi_range(-3, 3)), "closeness": 45})
			var dn: Dictionary = GameState.npcs[did]
			_res(id, "💘", "%s set me up with %s, a friend of a friend. %s" % [nm, dn["first"], _pick(["We have a second date next week.", "Dinner was nice. Chemistry, maybe.", "There was a spark. I'll call."])], 4, {"happiness": 4})
		"double":
			if not _once(id, aid): return
			if p["partner"] != "":
				GameState.change_closeness(p["partner"], 5)
			_res(id, "👫", "We went on a double date with %s. %s" % [nm, _pick(["Bowling, pizza, and a lot of laughing.", "Mini golf got competitive.", "The restaurant lost our booking, so we ate tacos on a curb."])], 8, {"happiness": 5})
		"best_friend":
			if not _once(id, aid): return
			if _roll(n, 0.65):
				for bf in GameState.npcs_with("best_friend"):
					GameState.npcs[bf]["relation"] = "friend"
					GameState.change_closeness(bf, -15)
					remember(bf, "replaced me as best friend", false)
				n["relation"] = "best_friend"
				_res(id, "🤞", "%s said yes. Best friends, officially." % nm, 8, {"happiness": 6}, "asked me to be best friends")
			else:
				_res(id, "🤞", "%s said %s doesn't do \"best\" friends. Ouch." % [nm, he], -4, {"happiness": -3})
		"befriend":
			if not _once(id, aid): return
			if _roll(n, 0.7):
				n["relation"] = "friend"
				_res(id, "🙋", "%s and I are friends now." % nm, 6, {"happiness": 3})
			else:
				_res(id, "🙋", "%s gave me a weird look and walked away." % nm, -4, {"happiness": -2})
		"ask_out":
			if not _once(id, aid): return
			var chance := clampf(0.2 + float(n["closeness"]) / 150.0 + (GameState.stat("looks") - float(n.get("looks", 50))) / 180.0, 0.05, 0.9)
			if randf() < chance:
				Actions.start_dating(id, false)
				_res(id, "💘", "I asked %s out and %s said yes!" % [nm, he], 10, {"happiness": 8})
			else:
				_res(id, "💘", _pick(["I asked %s out. %s said %s just sees me as a friend." % [nm, _cap(he), he], "I asked %s out. %s laughed, then realized I was serious." % [nm, _cap(he)]]), -8, {"happiness": -5})
		"unfriend":
			n["relation"] = "former_friend"
			remember(id, "ended our friendship", false)
			Actions._done("🚫", nm, "%s and I aren't friends anymore." % nm, {"happiness": -2})
		"argue":
			if not _once(id, aid): return
			_res(id, "😤", "I argued with %s about %s." % [nm, _pick(["money", "something %s said years ago" % he, "politics", "how %s treats me" % he, "nothing, really"])], -14, {"stress": 5, "happiness": -3}, "argued with me")
		"insult":
			if not _once(id, aid): return
			var ins := _pick(["called %s a clown" % _him(n), "made fun of %s haircut" % _his(n), "said %s cooking is inedible" % _his(n), "called %s boring to %s face" % [_him(n), _his(n)], "said %s peaked in high school" % he])
			if int(n["craziness"]) > 65 and randf() < 0.4:
				_res(id, "🗯️", "I %s. %s threw a drink in my face." % [ins, nm], -22, {"karma": -3, "happiness": -3}, "insulted me")
			else:
				_res(id, "🗯️", "I %s. %s was hurt." % [ins, nm], -18, {"karma": -3}, "insulted me")
		"rumor":
			if not _once(id, aid): return
			var rum := _pick(["%s cheats at board games" % he, "%s has a secret second family" % he, "%s was banned from a Waffle House" % he, "%s can't read" % he])
			if randf() < 0.5:
				_res(id, "🗣️", "I spread a rumor that %s. %s found out it was me." % [rum, nm], -25, {"karma": -6}, "spread lies about me")
				Grit.grudge(id, 20)
			else:
				_res(id, "🗣️", "I spread a rumor that %s. People believe it." % rum, -8, {"karma": -6, "happiness": 2})
		"fight":
			if not _once(id, aid): return
			var winf := 0.35 + (GameState.stat("health") - 50) / 200.0 + (0.15 if GameState.has_trait("Athletic") else 0.0) + Daily.fight_bonus()
			if Meta.has_mod("brass_knuckles"):
				winf = 1.0
			if randf() < winf:
				GameState.counter("fights_won")
				_res(id, "👊", "I got into a fistfight with %s and won." % nm, -35, {"happiness": 3, "karma": -5}, "beat me up")
			else:
				_res(id, "🤕", "I picked a fight with %s and lost badly." % nm, -25, {"health": -12, "happiness": -6}, "fought me")
			Grit.grudge(id, 25)
			if randf() < 0.15:
				p["record"].append("assault")
				p["money"] = int(p["money"]) - Actions._cost(500)
				GameState.add_log("The police charged me with assault. I paid a fine.")
		"sue":
			Law.sue(id)
		"amends":
			Grit.make_amends(id)
		"apologize":
			if not _once(id, aid): return
			if _roll(n, 0.6):
				_res(id, "🙇", "I apologized to %s. %s accepted, slowly." % [nm, _cap(he)], 12, {"karma": 2}, "apologized to me")
			else:
				_res(id, "🙇", "I apologized. %s said sorry doesn't cut it." % nm, 2, {})
		"make_peace":
			if not _once(id, aid): return
			if randf() < 0.45 + float(p["karma"]) / 200.0:
				n["relation"] = "friend"
				_res(id, "🕊️", "%s and I buried the hatchet. Friends, even." % nm, 25, {"karma": 5}, "made peace with me")
			else:
				_res(id, "🕊️", "I tried to make peace with %s. It didn't take." % nm, -5, {})
		"pet_play":
			if not _once(id, aid): return
			_res(id, "🎾", "I played %s with %s. %s" % [_pick(["fetch", "tug of war", "with a laser pointer", "hide and seek"]), nm, _pick(["Pure joy.", "We both needed that.", "Tail wagging, zero regrets."])], 10, {"happiness": 5, "stress": -4})
		"pet_walk":
			if not _once(id, aid): return
			_res(id, "🦮", "I took %s for a long walk. %s sniffed every single tree." % [nm, nm], 8, {"health": 2, "stress": -3})
		"pet_train":
			if not _once(id, aid): return
			n["trained"] = int(n.get("trained", 0)) + 1
			if randf() < 0.6:
				_res(id, "🦴", "%s learned to %s!" % [nm, _pick(["sit", "roll over", "shake hands", "come when called", "stop stealing socks"])], 6, {"happiness": 4})
			else:
				_res(id, "🦴", "Training %s did not go well. %s ate the treat bag." % [nm, nm], 1, {"stress": 2})
		"pet_bathe":
			if not _once(id, aid): return
			if randf() < 0.3:
				_res(id, "🛁", "%s did not want a bath. I have scratches to prove it." % nm, -5, {"health": -2})
			else:
				_res(id, "🛁", "%s is clean and fluffy and furious about it." % nm, 3, {})
		"pet_feed":
			if not _once(id, aid): return
			var fc := Actions._cost(25)
			if not Actions._can_pay(fc, "Pet food"): return
			_res(id, "🥣", "I made %s a proper meal instead of the usual scoop. %s cleaned the bowl and looked up for more." % [nm, nm], 5, {"money": -fc, "happiness": 2})
		"pet_treat":
			if not _once(id, aid): return
			_res(id, "🍖", "I gave %s a treat. Best friend for life." % nm, 6, {"happiness": 2, "money": -Actions._cost(5)})
		"pet_vet":
			if not _once(id, aid): return
			var fee2 := Actions._cost(200)
			var vet := Web.contact(["vet"], 45)
			if vet != "":
				fee2 = 0
			if not Actions._can_pay(fee2, "Vet"): return
			n["age"] = maxi(0, int(n["age"]) - 1)
			_res(id, "🩺", "%s got a clean bill of health%s." % [nm, " (free, thanks to %s)" % GameState.npc(vet)["first"] if vet != "" else ""], 5, {"money": -fee2})
		"pet_rehome":
			n["alive"] = false
			n["rehomed"] = true
			Actions._done("🏠", nm, "I found %s a new home with a family who has a big yard. I cried the whole drive back." % nm, {"happiness": -8, "karma": -2})


func fertility_chance(n: Dictionary) -> float:
	var a := int(_p()["age"])
	var b := int(n.get("age", a))
	var c := 0.5
	var older := maxi(a, b) if _p()["gender"] == n.get("gender", "") else (a if _p()["gender"] == "female" else b)
	if older > 35:
		c -= (older - 35) * 0.04
	if older > 45:
		c = 0.03
	c *= lerpf(0.5, 1.5, GameState.hidden("fertility") / 100.0)
	return clampf(c, 0.02, 0.7)


# ---------------------------------------------------------------- details

func _hang(id: String, n: Dictionary, what: String) -> void:
	var h: Array = []
	for x in HANGOUTS:
		if x[0] == what:
			h = x
	if h.is_empty():
		return
	if not _once(id, "hang"): return
	GameState.counter("spend_time")
	if Actions._out_of_time(): return
	if int(h[5]) > 0 and not GameState.spend_time(int(h[5])):
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1
		EventEngine.push_info("⏳", "Not enough time", "A road trip takes 2 time.")
		return
	var cost := Actions._cost(int(h[3]))
	if cost > 0 and not Actions._can_pay(cost, str(h[2])):
		GameState.player["time_left"] = int(GameState.player["time_left"]) + 1 + int(h[5])
		return
	var nm: String = n["first"]
	var fx := {"money": -cost, "happiness": 4, "stress": -3}
	var d := 10
	var line := ""
	var liked: bool = (what == "shopping" and n["likes"] == "fashion") or (what == "games" and n["likes"] == "games") or (what == "sports" and n["likes"] == "sports") or (what == "concert" and n["likes"] == "music") or (what == "museum" and n["likes"] == "art") or (what in ["dinner", "cook"] and n["likes"] == "food")
	match what:
		"park": line = _pick(["We fed the ducks and people-watched.", "We walked the whole loop twice, talking the entire time.", "We lay in the grass and made fun of clouds."])
		"movies": line = _pick(["We saw a horror movie. %s screamed. I screamed louder." % nm, "The movie was bad. Making fun of it after was great.", "We shared a bucket of popcorn the size of a toddler."])
		"dinner": line = _pick(["We found a tiny place with the best pasta in town.", "Dinner turned into dessert turned into closing time.", "The waiter was rude, so we tipped with a very pointed smiley face."])
		"shopping":
			line = _pick(["We tried on the ugliest clothes in the store.", "I came home with things I don't need. Worth it."])
			fx["looks"] = 1
		"gym":
			line = _pick(["We spotted each other and pretended not to be dying.", "%s beat me on the rowing machine and hasn't shut up about it." % nm])
			fx["health"] = 3
		"games": line = _pick(["We played co-op until 3 a.m.", "I lost every round of the fighting game and demanded rematches."])
		"concert": line = _pick(["We screamed every lyric.", "We got pushed right up to the front. Unreal."])
		"sports": line = _pick(["Our team won in overtime. We hugged strangers.", "We lost, but the hot dogs were excellent."])
		"karaoke": line = _pick(["%s murdered a power ballad. The crowd loved it." % nm, "We did a duet. We will not be doing a duet again."])
		"museum":
			line = _pick(["We spent an hour in front of one painting arguing about what it meant.", "The dinosaur hall was the highlight. We're adults."])
			fx["smarts"] = 1
		"bar":
			line = _pick(["One drink became four.", "We ended up playing darts with a bachelorette party."])
			Grit.habit("partying", 3)
		"cook": line = _pick(["We made homemade pizza. The kitchen will never recover.", "We followed a recipe. It did not look like the picture."])
		"roadtrip":
			line = _pick(["We drove to the coast with no plan and the windows down.", "The car broke down in the middle of nowhere. Best trip ever.", "We found a diner that serves pie the size of a tire."])
			fx["happiness"] = 10
			fx["stress"] = -10
			d = 18
	if liked:
		d += 8
		line += " %s loved it." % nm
	if int(n["craziness"]) > 75 and randf() < 0.2:
		line += " Then %s got us kicked out for arguing with a stranger." % nm
		d -= 8
	_res(id, str(h[1]), "%s with %s. %s" % [str(h[2]).replace(" (2 time)", ""), nm, line], d, fx, ("went on a road trip with me" if what == "roadtrip" else ""))


func _gift(id: String, n: Dictionary, kind: String) -> void:
	if not _once(id, "gift"): return
	var price := Actions._cost(20 if kind == "cheap" else (600 if kind == "jewelry" else 120))
	if not Actions._can_pay(price, "Gift"): return
	var nm: String = n["first"]
	var he := _he(n)
	if kind == "cheap":
		_res(id, "💐", "I gave %s %s. %s" % [nm, _pick(["flowers", "a card I wrote myself", "a box of chocolates"]), _pick(["%s put it on the fridge." % _cap(he), "Sweet and simple."])], 5, {"money": -price})
		return
	var d := 6
	var txt := ""
	if kind == n["likes"]:
		n["likes_known"] = true
		d = 18
		txt = "%s absolutely loved it." % _cap(he)
		remember(id, "gave me the perfect gift", true)
	elif int(n["craziness"]) > 60 and randf() < 0.4:
		d = -5
		txt = "%s asked if I'd kept the receipt." % _cap(he)
	else:
		txt = _pick(["%s said thanks. Politely." % _cap(he), "%s seemed to like it." % _cap(he), "%s smiled and put it somewhere I'll never see it again." % _cap(he)])
	_res(id, LIKES[kind][0], "I gave %s some %s. %s" % [nm, LIKES[kind][1], txt], d, {"money": -price})


func _discipline(id: String, n: Dictionary, aid: String) -> void:
	var nm: String = n["first"]
	var he := _he(n)
	var what := _pick(["drew on the walls with permanent marker", "was caught sneaking out", "failed a test and hid it", "said a very bad word at dinner", "got into a fight at school", "used my card to buy game credits"])
	match aid:
		"disc_talk":
			n["guided"] = int(n.get("guided", 0)) + 1
			if _roll(n, 0.6):
				_res(id, "🗣️", "%s %s. We talked it through calmly. %s apologized." % [nm, what, _cap(he)], 6, {})
			else:
				_res(id, "🗣️", "%s %s. I tried to talk it through. %s put headphones in." % [nm, what, _cap(he)], -2, {"stress": 3})
		"disc_ground":
			n["school"] = clampi(int(n.get("school", 50)) + 4, 0, 100)
			_res(id, "🚫", "%s %s. %s's grounded for a month. %s's not speaking to me." % [nm, what, _cap(he), _cap(he)], -8, {"stress": 2})
		"disc_yell":
			_res(id, "📢", "%s %s. I yelled. %s cried. I felt terrible." % [nm, what, _cap(he)], -14, {"stress": 5}, "yelled at me when I was little")
		"disc_ignore":
			n["spoiled"] = int(n.get("spoiled", 0)) + 1
			_res(id, "🤷", "%s %s. I let it go. %s seemed surprised, then did it again." % [nm, what, _cap(he)], 2, {})


func _care(id: String, n: Dictionary) -> void:
	var nm: String = n["first"]
	var p := _p()
	var choices: Array = [
		{"label": "Move %s in with you" % _him(n), "outcomes": [{"weight": 2, "text": "%s moved into the spare room. Dinner is louder now, and better." % nm, "effects": {"stress": 6, "happiness": 4}, "relationship": {"them": 20}}, {"weight": 1, "text": "%s moved in. We're driving each other up the wall." % nm, "effects": {"stress": 12}, "relationship": {"them": 5}}]},
		{"label": "Pay for a good care home (%s a year)" % GameState.fmt_money(Actions._cost(30000)), "requires": {"money": Actions._cost(30000)}, "outcomes": [{"text": "I found %s a place with a garden and a nurse who laughs at %s jokes." % [nm, _his(n)], "effects": {"money": -Actions._cost(30000)}, "relationship": {"them": 10}}]},
		{"label": "Visit more often", "outcomes": [{"text": "I started visiting %s every Sunday." % nm, "effects": {"happiness": 3}, "relationship": {"them": 12}}]},
		{"label": "It's not my job", "outcomes": [{"text": "I told %s to figure it out. The silence on the phone said everything." % nm, "effects": {"karma": -10}, "relationship": {"them": -25}}]},
	]
	EventEngine.push_decision({"id": "_care", "icon": "🏡", "title": "Taking care of " + nm, "text": "%s is %d and slowing down. What do you do?" % [nm, int(n["age"])], "choices": choices}, {"them": id})


func _party(id: String, n: Dictionary) -> void:
	var nm: String = n["first"]
	var roll := randf()
	if roll < 0.15:
		var cid := GameState.create_npc("crush", {"age": maxi(13, int(_p()["age"]) + randi_range(-2, 2)), "closeness": 50})
		_res(id, "🎉", "At the party %s dragged me to, I met %s. We talked all night." % [nm, GameState.npcs[cid]["first"]], 8, {"happiness": 6})
	elif roll < 0.3:
		var fid := GameState.create_npc("friend", {"age": maxi(10, int(_p()["age"]) + randi_range(-2, 2)), "closeness": 50})
		_res(id, "🎉", "I went to a party with %s and made a new friend, %s." % [nm, GameState.npcs[fid]["first"]], 8, {"happiness": 6})
	elif roll < 0.4 and int(_p()["age"]) < 18:
		_res(id, "🚓", "The party %s took me to got busted. My parents picked me up from the police station." % nm, -4, {"happiness": -6, "stress": 8})
		for par in GameState.npcs_with("mother") + GameState.npcs_with("father"):
			GameState.change_closeness(par, -8)
	else:
		_res(id, "🎉", "%s and I went to a party. %s" % [nm, _pick(["We danced on a table.", "The playlist was questionable, the snacks were not.", "We left early for fries. Classic."])], 8, {"happiness": 5, "popularity": 3})


func _propose(id: String, n: Dictionary, where: String) -> void:
	var p := _p()
	var nm: String = n["first"]
	var ring := best_ring()
	var cost := Actions._cost({"home": 0, "restaurant": 300, "beach": 900, "public": 150, "family": 80}.get(where, 0))
	if not Actions._can_pay(cost, "Proposal"): return
	var chance := clampf((float(n["closeness"]) - 40.0) / 50.0, 0.08, 0.92)
	if ring.is_empty():
		chance *= 0.35
	elif str(ring.get("tag", "")) == "fake_ring":
		chance *= 0.55
	else:
		chance += clampf(float(ring.get("value", 0)) / 40000.0, 0.0, 0.2)
	if where == "public" and int(n["craziness"]) < 40:
		chance -= 0.15
	if where == "beach":
		chance += 0.08
	var fx := {"money": -cost}
	if randf() < chance:
		p["partner_status"] = "engaged"
		GameState.add_milestone(p["age"], "got engaged to %s" % nm)
		fx["happiness"] = 12
		_res(id, "💍", "I got down on one knee %s%s. %s said YES!" % [{"home": "in our living room", "restaurant": "at a candlelit restaurant", "beach": "on the beach at sunset", "public": "in front of a cheering crowd", "family": "at family dinner"}.get(where, ""), "" if ring.is_empty() else " with a %s" % str(ring["name"]).to_lower(), _cap(_he(n))], 12, fx, "said yes to my proposal")
	else:
		fx["happiness"] = -12
		var why := "said %s isn't ready." % _he(n)
		if ring.is_empty():
			why = "asked where the ring was."
		elif str(ring.get("tag", "")) == "fake_ring":
			why = "noticed the ring was fake."
		elif where == "public":
			why = "froze in front of everyone, then walked out."
		_res(id, "💍", "I proposed to %s, who %s" % [nm, why], -12, fx, "turned down my proposal")


func _wedding(id: String, n: Dictionary) -> void:
	var nm: String = n["first"]
	var small := Actions._cost(8000)
	var big := Actions._cost(40000)
	var dest := Actions._cost(25000)
	var base := {"text": "I married %s!" % nm, "milestone": "married %s" % GameState.full_name(id), "marry": true}
	var choices: Array = [
		{"label": "Courthouse (%s)" % GameState.fmt_money(Actions._cost(150)), "requires": {"money": Actions._cost(150)}, "outcomes": [base.merged({"effects": {"happiness": 10, "money": -Actions._cost(150)}}, true)]},
		{"label": "Small wedding (%s)" % GameState.fmt_money(small), "requires": {"money": small}, "outcomes": [base.merged({"effects": {"happiness": 15, "money": -small}}, true)]},
		{"label": "Big wedding (%s)" % GameState.fmt_money(big), "requires": {"money": big}, "outcomes": [base.merged({"weight": 4, "effects": {"happiness": 22, "money": -big}}, true), base.merged({"weight": 1, "text": "I married %s. My uncle gave a speech nobody will forget, for the wrong reasons." % nm, "effects": {"happiness": 14, "money": -big}}, true)]},
		{"label": "Destination wedding (%s)" % GameState.fmt_money(dest), "requires": {"money": dest}, "outcomes": [base.merged({"text": "I married %s on a cliff above the sea. Half the guests got sunburned." % nm, "effects": {"happiness": 20, "money": -dest}}, true)]},
		{"label": "Elope", "outcomes": [base.merged({"text": "We eloped! Just the two of us and a very confused officiant. Our families are furious.", "effects": {"happiness": 14}, "family_upset": true}, true)]},
		{"label": "Not yet", "outcomes": [{"text": ""}]},
	]
	var ask_prenup: bool = int(_p()["money"]) > 50000 or int(n.get("money", 0)) > 50000
	var txt := "How do you and %s want to get married?" % nm
	if ask_prenup:
		txt += "\n\nOne of you has money. Afterwards, you'll be asked about a prenup."
	EventEngine.push_decision({"id": "_wedding", "icon": "💒", "title": "The wedding", "text": txt, "choices": choices}, {"them": id})
	if ask_prenup:
		EventEngine.push_decision({"id": "_prenup", "icon": "📜", "title": "A prenup?", "text": "Do you ask %s to sign a prenup?" % nm, "choices": [
			{"label": "Ask for a prenup", "outcomes": [{"weight": 2, "text": "%s signed the prenup without a fuss." % nm, "flags": ["prenup_signed"]}, {"weight": 1, "text": "%s signed it, but asked what I think is going to happen." % nm, "flags": ["prenup_signed"], "relationship": {"them": -10}}]},
			{"label": "Trust each other", "outcomes": [{"text": "No prenup. We're all in.", "relationship": {"them": 4}}]},
		]}, {"them": id})


func _divorce(id: String, n: Dictionary, how: String) -> void:
	var p := _p()
	var nm: String = n["first"]
	var kids := minor_children()
	var pre: bool = p.get("prenup", false) or GameState.has_flag("prenup_signed")
	var worth: int = maxi(0, int(p["money"]))
	var share := 0.0 if pre else 0.4
	var fee := 0
	var custody := "shared"
	var text := ""
	match how:
		"amicable":
			share = 0.0 if pre else 0.3
			text = "%s and I divorced amicably." % nm
		"court":
			fee = Actions._cost(25000)
			var win := randf() < 0.45 + (GameState.stat("smarts") - 50.0) / 250.0
			share = (0.0 if pre else 0.15) if win else (0.1 if pre else 0.5)
			custody = "me" if win else "ex"
			text = "The divorce went to court. " + ("My lawyers won." if win else "%s's lawyers ate mine alive." % nm)
		"give_custody":
			share = 0.0 if pre else 0.2
			custody = "ex"
			text = "%s and I divorced. %s took the kids; I get weekends." % [nm, _cap(_he(n))]
	var loss := int(worth * share) + fee
	p["money"] = int(p["money"]) - loss
	if loss > 0:
		text += " It cost me %s." % GameState.fmt_money(loss)
	if pre and share < 0.2:
		text += " The prenup held."
	for c in kids:
		if custody == "ex":
			GameState.npcs[c]["custody"] = "ex"
			GameState.change_closeness(c, -10)
		elif custody == "shared":
			GameState.change_closeness(c, -4)
	GameState.add_milestone(p["age"], "divorced %s" % nm)
	GameState.counter("divorces")
	n["relation"] = "ex"
	n.erase("living_together")
	p["partner"] = ""
	p["partner_status"] = ""
	p["prenup"] = false
	GameState.clear_flag("prenup_signed")
	remember(id, "divorced me", false)
	_res(id, "💔", text, -40, {"happiness": -10, "stress": 12})


# ================================================================ yearly: living NPCs

func yearly() -> void:
	BondStats.yearly()
	var p := _p()
	var ids: Array = GameState.npcs.keys()
	var told := 0
	for id in ids:
		if not GameState.npcs.has(id):
			continue
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human":
			continue
		var rel: String = n["relation"]
		if not (rel in FAMILY or rel in FRIENDS or rel == "partner"):
			continue
		ensure(id)
		if lives_with_ex(n):
			GameState.change_closeness(id, -2)
		if rel in ["child", "stepchild"] and int(n["age"]) >= 6 and int(n["age"]) <= 18:
			_kid_school(id, n)
		if told < 3 and _npc_life(id, n):
			told += 1
	_parents_marriage()
	_holiday()
	_recall()


## Someone brings up something you did, or something they did, from years ago.
## Memories used to be written and never read; this is where they come back.
func _recall() -> void:
	var p := _p()
	if int(p["age"]) < 14 or randf() > 0.16:
		return
	var pool: Array = []
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or n.get("species", "human") != "human" or int(n.get("age", 0)) < 8:
			continue
		for m in n.get("memory", []):
			if not m.get("told", false) and int(p["age"]) - int(m["age"]) >= 3:
				pool.append([id, m])
	if pool.is_empty():
		return
	var pick: Array = pool[randi() % pool.size()]
	var id: String = pick[0]
	var m: Dictionary = pick[1]
	m["told"] = true
	var n: Dictionary = GameState.npcs[id]
	var nm: String = n["first"]
	var what := str(m["text"]).trim_suffix(".")
	what = what.substr(0, 1).to_lower() + what.substr(1)
	var yrs := int(p["age"]) - int(m["age"])
	if m.get("own", false):
		what = "“%s”" % str(m["text"])
	if m["good"]:
		EventEngine.push_decision({"id": "_recall_good", "icon": "💭", "title": "%s remembers" % nm, "text": "%d years on, %s still talks about it: %s." % [yrs, nm, what if m.get("own", false) else "%s %s" % [nm, what]], "choices": [
			{"label": "Say it meant a lot to you too", "outcomes": [{"text": "%s and I sat a while, remembering. It was nice to be reminded." % nm, "effects": {"happiness": 4}, "relationship": {"them": 8}}, {"text": "We laughed about it. %s remembered it better than I did." % nm, "effects": {"happiness": 3}, "relationship": {"them": 5}}]},
			{"label": "Do something to match it", "outcomes": [{"text": "I made a point of doing something for %s. It landed." % nm, "effects": {"happiness": 3, "money": -Actions._cost(80)}, "relationship": {"them": 12}}, {"text": "I tried to do something for %s; it was awkward but it was meant." % nm, "effects": {"happiness": 1}, "relationship": {"them": 6}}]},
			{"label": "Let it pass", "outcomes": [{"text": "I smiled and changed the subject. %s noticed." % nm, "effects": {}, "relationship": {"them": -2}}, {"text": "I let it pass. Some things are better left in the past.", "effects": {"stress": -1}, "relationship": {"them": 0}}]},
		]}, {"them": id})
	else:
		EventEngine.push_decision({"id": "_recall_bad", "icon": "💭", "title": "%s hasn't forgotten" % nm, "text": "%d years on, it comes up again over dinner. %s hasn't forgotten: %s." % [yrs, nm, what if m.get("own", false) else "%s %s" % [nm, what]], "choices": [
			{"label": "Take it seriously and apologise", "outcomes": [{"text": "I said sorry properly this time. %s listened." % nm, "effects": {"stress": 3, "karma": 3}, "relationship": {"them": 9}}, {"text": "I apologised. It didn't fix it, but %s nodded." % nm, "effects": {"stress": 4}, "relationship": {"them": 4}}]},
			{"label": "Say it was a long time ago", "outcomes": [{"text": "%s didn't push it. The silence was louder than the argument would have been." % nm, "effects": {"stress": 4}, "relationship": {"them": -3}}, {"text": "We both pretended it was funny. It wasn't, quite.", "effects": {}, "relationship": {"them": 1}}]},
			{"label": "Argue your side", "outcomes": [{"text": "It turned into a proper row. %s left early." % nm, "effects": {"stress": 8, "happiness": -4}, "relationship": {"them": -10}}, {"text": "I put my case. %s heard it, to my surprise, and conceded a point." % nm, "effects": {"stress": 3}, "relationship": {"them": 3}}]},
		]}, {"them": id})


func _kid_school(id: String, n: Dictionary) -> void:
	var s := int(n.get("school", 45 + int(n["smarts"]) / 5))
	s += int((float(n["smarts"]) - 50.0) / 25.0) + randi_range(-4, 4) + mini(3, int(n.get("guided", 0))) - int(n.get("spoiled", 0))
	n["school"] = clampi(s, 0, 100)
	if int(n["age"]) == 18:
		var g := int(n["school"])
		var nm: String = n["first"]
		if g >= 75:
			n["degree"] = true
			GameState.add_log("%s graduated high school with honors%s." % [nm, " and is off to college" if n.get("tuition_paid", false) or int(n.get("fund", 0)) > 0 else ""])
			GameState.apply_effects({"happiness": 6})
		elif g >= 45:
			GameState.add_log("%s graduated high school." % nm)
		else:
			GameState.add_log("%s dropped out of high school." % nm)
			GameState.apply_effects({"happiness": -4})


func _npc_life(id: String, n: Dictionary) -> bool:
	var p := _p()
	var age: int = n["age"]
	var rel: String = n["relation"]
	var nm: String = n["first"]
	var label := GameState.relation_label(id)
	var who := "My %s %s" % [label.to_lower(), nm] if rel in FAMILY else ("My friend " + nm if rel in FRIENDS else nm)
	if rel == "partner":
		return false
	if age >= 22 and age <= 50 and not Origins.is_spoken_for(id) and randf() < 0.07:
		n["married"] = true
		var sg := "female" if n["gender"] == "male" else "male"
		if randf() < 0.1:
			sg = n["gender"]
		n["spouse"] = "%s %s" % [ContentDB.random_first(sg, p["country"]), ContentDB.random_last(p["country"])]
		n["spouse_gender"] = sg
		if rel in ["child", "stepchild"] and int(n["closeness"]) >= 30:
			var cost := Actions._cost(20000)
			EventEngine.push_decision({"id": "_kid_wedding", "icon": "💒", "title": "%s is getting married" % nm, "text": "%s is marrying %s. They'd love your help paying for the wedding." % [nm, n["spouse"]], "choices": [
				{"label": "Pay for the wedding (%s)" % GameState.fmt_money(cost), "requires": {"money": cost}, "outcomes": [{"text": "I paid for %s's wedding and cried through the whole ceremony." % nm, "effects": {"money": -cost, "happiness": 10}, "relationship": {"them": 20}}]},
				{"label": "Just be there", "outcomes": [{"text": "I danced with %s at the reception." % nm, "effects": {"happiness": 6}, "relationship": {"them": 6}}]},
				{"label": "Skip it", "outcomes": [{"text": "I didn't go to %s's wedding. %s won't forget that." % [nm, _cap(_he(n))], "effects": {"karma": -8}, "relationship": {"them": -30}}]},
			]}, {"them": id})
			remember(id, "was there on my wedding day", true)
		else:
			GameState.add_log("%s married %s." % [who, n["spouse"]])
		return true
	if n.get("married", false) and age >= 22 and age <= 44 and int(n.get("kids", 0)) < 4 and randf() < 0.1:
		n["kids"] = int(n.get("kids", 0)) + 1
		var krel := ""
		if rel in ["child", "stepchild"]:
			krel = "grandchild"
		elif rel in ["sibling", "stepsibling"]:
			krel = "niece_nephew"
		if krel != "":
			var kid := GameState.create_npc(krel, {"age": 0, "last": n["last"], "closeness": 55 + int(n["closeness"]) / 4})
			GameState.npcs[kid]["parent_id"] = id
			var kn: Dictionary = GameState.npcs[kid]
			GameState.add_log("%s had a baby: %s." % [who, kn["first"]])
			if krel == "grandchild":
				GameState.counter("grandchildren")
				if not GameState.has_flag("grandparent"):
					GameState.set_flag("grandparent")
					GameState.add_milestone(int(p["age"]), "became a grandparent")
				GameState.apply_effects({"happiness": 8})
		else:
			GameState.add_log("%s had a baby." % who)
		return true
	if n.get("married", false) and randf() < 0.02:
		var spouse_name := str(n.get("spouse", "their spouse"))
		var linked := str(n.get("spouse_id", ""))
		Origins.part(id)
		GameState.add_log("%s is getting divorced from %s." % [who, spouse_name])
		# If the two of them were your parents, that is your family splitting up,
		# not a line in somebody else's life.
		if linked != "" and rel in ["mother", "father"] and int(p["age"]) < 25:
			GameState.apply_effects({"happiness": -12, "stress": 8})
			GameState.add_milestone(int(p["age"]), "watched their parents separate")
		if rel in FAMILY and int(n["closeness"]) >= 50:
			GameState.apply_effects({"stress": 2})
		return true
	if age >= 18 and age <= 64 and randf() < 0.035:
		var good := randf() < 0.6
		var line := ""
		if good:
			line = _pick(["got a big promotion", "started a small business", "won an award at work", "finished a degree at night school", "ran a marathon", "paid off their mortgage", "got a book published"]).replace("their", _his(n))
			n["money"] = int(n.get("money", 0)) + randi_range(2000, 20000)
		else:
			line = _pick(["lost their job", "got arrested for a bar fight", "was in a car accident", "lost a lot of money on crypto", "had a health scare", "had their identity stolen"]).replace("their", _his(n))
			n["money"] = maxi(0, int(n.get("money", 0)) - randi_range(1000, 15000))
			if rel in FAMILY and int(n["closeness"]) >= 40 and int(p["age"]) >= 18 and randf() < 0.5:
				_ask_help(id, n, line)
				return true
		GameState.add_log("%s %s." % [who, line])
		return true
	if age >= 18 and rel in ["sibling", "cousin", "friend", "best_friend"] and randf() < 0.01:
		var c: Dictionary = ContentDB.countries[randi() % ContentDB.countries.size()]
		if c["id"] != p["country"]:
			n["abroad"] = c["name"]
			GameState.add_log("%s moved to %s." % [who, c["name"]])
			return true
	return false


func _ask_help(id: String, n: Dictionary, what: String) -> void:
	var nm: String = n["first"]
	var amt := Actions._cost(randi_range(2, 12) * 1000)
	EventEngine.push_decision({"id": "_help", "icon": "🆘", "title": "%s needs help" % nm, "text": "%s %s and is asking if you can help out with %s." % [nm, what, GameState.fmt_money(amt)], "choices": [
		{"label": "Give it (%s)" % GameState.fmt_money(amt), "requires": {"money": amt}, "outcomes": [{"text": "I helped %s out. %s called me a lifesaver." % [nm, _cap(_he(n))], "effects": {"money": -amt, "karma": 5}, "relationship": {"them": 18}}]},
		{"label": "Lend it", "requires": {"money": amt}, "outcomes": [{"text": "I lent %s the money. We'll see." % nm, "effects": {"money": -amt}, "relationship": {"them": 8}, "npc_owes": amt}]},
		{"label": "Say no", "outcomes": [{"text": "I told %s I couldn't help. %s went quiet." % [nm, _cap(_he(n))], "relationship": {"them": -15}}]},
	]}, {"them": id})


func _parents_marriage() -> void:
	var p := _p()
	var mom := GameState.first_of("mother")
	var dad := GameState.first_of("father")
	if mom == "" or dad == "" or GameState.has_flag("parents_divorced"):
		if GameState.has_flag("parents_divorced") and not GameState.has_flag("stepparent") and int(p["age"]) < 25 and randf() < 0.12:
			var alive_p := mom if mom != "" else dad
			if alive_p == "":
				return
			var pa: Dictionary = GameState.npcs[alive_p]
			var sg := "male" if pa["gender"] == "female" else "female"
			var sid := GameState.create_npc("stepparent", {"gender": sg, "age": int(pa["age"]) + randi_range(-5, 5), "closeness": randi_range(20, 60)})
			GameState.set_flag("stepparent")
			var sn: Dictionary = GameState.npcs[sid]
			EventEngine.push_decision({"id": "_stepparent", "icon": "💍", "title": "A new stepparent", "text": "%s married %s %s. What will you call %s?" % [pa["first"], sn["first"], sn["last"], GameState.pron(sg, "him")], "choices": [
				{"label": "By their first name", "outcomes": [{"text": "I call my stepparent %s. It works." % sn["first"], "relationship": {"s": 5}}]},
				{"label": "Mom or Dad", "outcomes": [{"weight": 2, "text": "%s teared up when I called %s that." % [sn["first"], GameState.pron(sg, "him")], "relationship": {"s": 25}}, {"weight": 1, "text": "It felt weird. For both of us.", "relationship": {"s": 5}}]},
				{"label": "Something rude", "outcomes": [{"text": "I call %s \"the replacement\". Dinner is tense." % sn["first"], "relationship": {"s": -25}, "effects": {"karma": -3}}]},
			]}, {"s": sid})
			if randf() < 0.5:
				var ss := GameState.create_npc("stepsibling", {"age": maxi(0, int(p["age"]) + randi_range(-4, 4)), "last": sn["last"], "closeness": randi_range(15, 45)})
				GameState.add_log("I got a stepsibling, %s, who is not happy about any of this." % GameState.npcs[ss]["first"])
		return
	if int(p["age"]) >= 3 and int(p["age"]) < 20 and randf() < 0.025:
		GameState.set_flag("parents_divorced")
		GameState.add_milestone(p["age"], "saw their parents divorce")
		EventEngine.push_decision({"id": "_parents_divorce", "icon": "💔", "title": "Your parents are splitting up", "text": "%s and %s sat you down at the kitchen table. They're getting divorced." % [GameState.npc(mom)["first"], GameState.npc(dad)["first"]], "choices": [
			{"label": "Cry", "outcomes": [{"text": "I cried until I fell asleep. They both came in to check on me.", "effects": {"happiness": -12}}]},
			{"label": "Blame %s" % GameState.npc(dad)["first"], "outcomes": [{"text": "I blamed Dad. He took it quietly.", "effects": {"happiness": -8}, "relationship": {"d": -20, "m": 5}}]},
			{"label": "Blame %s" % GameState.npc(mom)["first"], "outcomes": [{"text": "I blamed Mom. She took it quietly.", "effects": {"happiness": -8}, "relationship": {"m": -20, "d": 5}}]},
			{"label": "Say you understand", "outcomes": [{"text": "I told them I understood. I didn't, really.", "effects": {"happiness": -6, "smarts": 1}, "relationship": {"m": 8, "d": 8}}]},
		]}, {"m": mom, "d": dad})


func _holiday() -> void:
	var p := _p()
	if int(p["age"]) < 6 or randf() > 0.22 or GameState.in_prison():
		return
	var fam: Array = []
	for rel in ["mother", "father", "sibling", "child", "grandparent", "auntuncle", "cousin", "stepparent", "grandchild"]:
		fam += GameState.npcs_with(rel)
	if fam.size() < 2:
		return
	var host := int(p["age"]) >= 25
	var worst := ""
	var low := 101
	for f in fam:
		if int(GameState.npcs[f]["closeness"]) < low:
			low = int(GameState.npcs[f]["closeness"])
			worst = f
	var wn: Dictionary = GameState.npcs[worst]
	var holiday := _pick(["Thanksgiving", "the holidays", "New Year's", "a family reunion", "Grandma's birthday dinner"]) if p["country"] == "us" else _pick(["the holidays", "New Year's", "a family reunion", "a big family birthday"])
	var choices: Array = []
	if host:
		choices.append({"label": "Host everyone (%s)" % GameState.fmt_money(Actions._cost(400)), "requires": {"money": Actions._cost(400)}, "outcomes": [
			{"weight": 3, "text": "I hosted %s. The food was great and nobody fought. A miracle." % holiday, "effects": {"money": -Actions._cost(400), "happiness": 8}, "family_bonus": 6},
			{"weight": 1, "text": "I hosted %s. %s and I got into it over dessert." % [holiday, wn["first"]], "effects": {"money": -Actions._cost(400), "stress": 8}, "relationship": {"w": -12}, "family_bonus": 3}]})
	choices.append({"label": "Go", "outcomes": [
		{"weight": 3, "text": "%s with the family was warm and loud." % _cap(holiday), "effects": {"happiness": 5}, "family_bonus": 4},
		{"weight": 1, "text": "At %s, %s brought up an old fight in front of everyone." % [holiday, wn["first"]], "effects": {"stress": 6}, "relationship": {"w": -8}, "family_bonus": 1}]})
	choices.append({"label": "Skip it this year", "outcomes": [{"text": "I skipped %s. Somebody noticed." % holiday, "effects": {"stress": -3}, "family_bonus": -5}]})
	EventEngine.push_decision({"id": "_holiday", "icon": "🦃" if holiday == "Thanksgiving" else "🎄", "title": _cap(holiday), "text": "The whole family is getting together for %s. %s will be there." % [holiday, wn["first"]], "choices": choices}, {"w": worst})


func family_bonus(amount: int) -> void:
	for rel in ["mother", "father", "sibling", "child", "grandparent", "auntuncle", "cousin", "stepparent", "grandchild", "niece_nephew"]:
		for id in GameState.npcs_with(rel):
			GameState.change_closeness(id, amount)


# ================================================================ start of life

func starting_family() -> void:
	var p := _p()
	var sides := ["mother", "father"]
	if GameState.first_of("mother") == "" and GameState.first_of("father") == "":
		# Nobody is raising you from the generation above; the wider family, if
		# there is one, hangs off whoever is.
		sides = ["grandparent"]
	for side in sides:
		var par := GameState.first_of(side)
		if par == "":
			continue
		var pa: Dictionary = GameState.npcs[par]
		for i in range(randi_range(0, 2)):
			var aage := int(pa["age"]) + randi_range(-8, 8)
			var alast: String = pa["last"] if side != "mother" else ContentDB.random_last(p["country"])
			var au := GameState.create_npc("auntuncle", {"age": clampi(aage, 18, 70), "last": alast, "closeness": randi_range(35, 75)})
			GameState.npcs[au]["side"] = side
			if int(GameState.npcs[au]["age"]) >= 26 and randf() < 0.55:
				GameState.npcs[au]["married"] = true
				for k in range(randi_range(1, 2)):
					var cage := randi_range(maxi(0, int(GameState.npcs[au]["age"]) - 40), int(GameState.npcs[au]["age"]) - 20)
					if cage < 0:
						continue
					var cz := GameState.create_npc("cousin", {"age": cage, "last": alast, "closeness": randi_range(35, 70)})
					GameState.npcs[cz]["parent_id"] = au
				GameState.npcs[au]["kids"] = 1


func relation_name(rel: String, g: String) -> String:
	match rel:
		"stepparent": return "Stepfather" if g == "male" else ("Stepmother" if g == "female" else "Stepparent")
		"stepsibling": return "Stepbrother" if g == "male" else ("Stepsister" if g == "female" else "Stepsibling")
		"stepchild": return "Stepson" if g == "male" else ("Stepdaughter" if g == "female" else "Stepchild")
		"cousin": return "Cousin"
		"niece_nephew": return "Nephew" if g == "male" else ("Niece" if g == "female" else "Nibling")
		"grandchild": return "Grandson" if g == "male" else ("Granddaughter" if g == "female" else "Grandchild")
		"lover": return "Lover"
		"enemy": return "Enemy"
		"former_friend": return "Former friend"
		"former_ex": return "Ex (moved on)"
	return ""


## Their four stats, written the way the player's own are. Pets get a shorter
## version because "smarts 61" on a labrador is not information.
func stat_line(id: String) -> String:
	var n := ensure(id)
	if n.get("species", "human") != "human":
		return "❤️ %d" % int(n.get("health", 70))
	return "😊 %d   ❤️ %d   🧠 %d   ✨ %d" % [
		int(n.get("happiness", 60)), int(n.get("health", 70)),
		int(n.get("smarts", 50)), int(n.get("looks", 55))]


func status_line(id: String) -> String:
	var n := ensure(id)
	var bits: Array = []
	if n.get("married", false):
		bits.append("💍 married to " + str(n.get("spouse", "someone")))
	if int(n.get("kids", 0)) > 0:
		bits.append("👶 %d kid%s" % [int(n["kids"]), "" if int(n["kids"]) == 1 else "s"])
	if n.has("abroad"):
		bits.append("✈️ lives in " + str(n["abroad"]))
	if lives_with_ex(n):
		bits.append("🏠 lives with your ex")
	if int(n.get("owes", 0)) > 0:
		bits.append("📒 owes you " + GameState.fmt_money(int(n["owes"])))
	if n["relation"] in ["child", "stepchild"] and int(n["age"]) >= 6 and int(n["age"]) <= 18:
		bits.append("🎒 school %d%%" % int(n.get("school", 50)))
	if int(n.get("fund", 0)) > 0:
		bits.append("🏦 college fund " + GameState.fmt_money(int(n["fund"])))
	return "  ·  ".join(bits)


func trait_line(id: String) -> String:
	var n := ensure(id)
	var cz := int(n["craziness"])
	var mood := "Level-headed" if cz < 30 else ("A bit unpredictable" if cz < 60 else "Wildly unpredictable")
	var smart := "Sharp" if int(n["smarts"]) >= 70 else ("Average smarts" if int(n["smarts"]) >= 40 else "Not the sharpest")
	var gen := "Generous" if int(n["generosity"]) >= 65 else ("Tight with money" if int(n["generosity"]) < 35 else "")
	var likes := ("Loves %s" % LIKES[n["likes"]][1]) if n.get("likes_known", false) else "Likes: ??? (talk more)"
	return "  ·  ".join([mood, smart] + ([gen] if gen != "" else []) + [likes])

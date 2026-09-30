extends Node

## KEEPING UP — the maintenance of a life among other people.
##
## Friendships do not end; they lapse. Nobody announces it. The invitations are
## what pull against that: a wedding three hundred miles away, a birthday you can
## make if you leave work early, a funeral you cannot skip and would rather.
## Each arrives with a cost in money and time, and answering it, or not, is how
## a web of people is either kept or quietly let go.
##
## The same file holds the smaller upkeep of ordinary days: what you eat, and
## what a phone and a connection cost in whichever decade you happen to be in.

const DIETS := {
	"cook": {"name": "Cook at home", "icon": "🍲", "cost": -700, "health": 1.0, "happy": 0.0, "sub": "Cheaper and kinder to you, and it takes an evening a week"},
	"mixed": {"name": "A bit of everything", "icon": "🥗", "cost": 0, "health": 0.0, "happy": 0.0, "sub": "Some cooking, some takeaway, no guilt"},
	"takeaway": {"name": "Mostly takeaway", "icon": "🍕", "cost": 1600, "health": -1.6, "happy": 0.8, "sub": "Fast and nice and expensive and not good for you"},
}
const PLANS := {
	"basic": {"name": "Basic plan", "mult": 0.6, "sub": "Cheap. You are harder to reach and you feel it"},
	"standard": {"name": "Standard plan", "mult": 1.0, "sub": "What most people have"},
	"unlimited": {"name": "Unlimited", "mult": 1.7, "sub": "Always on. Always reachable. Never quite off"},
}
const INVITE_KINDS := {
	"wedding": {"icon": "💒", "name": "Wedding", "time": 2, "gift": 150},
	"birthday": {"icon": "🎂", "name": "Birthday party", "time": 0, "gift": 50},
	"funeral": {"icon": "⚱️", "name": "Funeral", "time": 2, "gift": 120},
	"baby": {"icon": "🍼", "name": "Baby shower", "time": 1, "gift": 70},
	"reunion": {"icon": "🥂", "name": "Reunion", "time": 1, "gift": 40},
}


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("keeping") or not (p["keeping"] is Dictionary):
		p["keeping"] = {"invites": [], "diet": "mixed", "plan": "standard", "attended": 0, "missed": 0, "sent": 0, "lapsed": 0}
	return p["keeping"]


# ------------------------------------------------------------ money and the era

func phone_cost() -> int:
	if _p().is_empty() or int(_p().get("age", 0)) < 14:
		return 0
	var lvl := Phrases.tech_level()
	var base: int = [300, 550, 800, 1500][lvl]
	return int(float(base) * float(PLANS[str(st().get("plan", "standard"))]["mult"]))


func costs() -> int:
	if _p().is_empty() or int(_p().get("age", 0)) < 18:
		return 0
	return phone_cost() + int(DIETS[str(st().get("diet", "mixed"))]["cost"])


# ------------------------------------------------------------ invitations

func invites() -> Array:
	return st().get("invites", [])


func _candidates(rels: Array) -> Array:
	var out: Array = []
	for r in rels:
		for id in GameState.npcs_with(r):
			if int(GameState.npcs[id]["closeness"]) >= 25:
				out.append(id)
	return out


func _add_invite(kind: String, id: String, far: bool) -> void:
	var s := st()
	for iv in s["invites"]:
		if str(iv["who"]) == id and str(iv["kind"]) == kind:
			return
	var d: Dictionary = INVITE_KINDS[kind]
	var travel := Actions._cost(randi_range(300, 1400)) if far else 0
	s["invites"].append({"kind": kind, "who": id, "far": far, "travel": travel, "made": int(_p().get("age", 0))})
	GameState.add_log("%s invited me to a %s%s." % [GameState.npcs[id]["first"], str(d["name"]).to_lower(), " — a long way away" if far else ""])


## A person who mattered has died. The funeral is an invitation nobody sends.
func on_death(id: String) -> void:
	if not GameState.npcs.has(id) or _p().is_empty():
		return
	var n: Dictionary = GameState.npcs[id]
	if int(n["closeness"]) < 30:
		return
	if not n["relation"] in ["mother", "father", "sibling", "grandparent", "auntuncle", "best_friend", "friend", "child", "partner", "coworker"]:
		return
	st()["invites"].append({"kind": "funeral", "who": id, "far": randf() < 0.4, "travel": Actions._cost(randi_range(300, 1200)) if randf() < 0.4 else 0, "made": int(_p()["age"])})


func yearly() -> void:
	var s := st()
	if s.is_empty() or GameState.in_prison():
		return
	var age := int(_p()["age"])
	# unanswered invitations lapse, with the consequences that implies
	for iv in s["invites"].duplicate():
		var id := str(iv["who"])
		if GameState.npcs.has(id):
			if str(iv["kind"]) == "funeral":
				s["missed"] = int(s["missed"]) + 1
				GameState.set_flag("missed_a_funeral")
				GameState.apply_effects({"stress": 5, "happiness": -4})
				GameState.add_log("I didn't go to %s's funeral. I have had a year to think about that." % GameState.npcs[id]["first"])
			else:
				GameState.change_closeness(id, -6)
				s["missed"] = int(s["missed"]) + 1
	s["invites"] = []
	if age < 14:
		return
	# the invitations this year
	var kin := _candidates(["friend", "best_friend", "sibling", "auntuncle", "cousin"])
	if not kin.is_empty() and randf() < 0.45:
		var id2: String = kin[randi() % kin.size()]
		_add_invite("birthday", id2, false)
	var marriers := _candidates(["friend", "best_friend", "sibling", "coworker"])
	marriers = marriers.filter(func(i): return int(GameState.npcs[i]["age"]) >= 22 and int(GameState.npcs[i]["age"]) <= 45)
	if not marriers.is_empty() and age >= 20 and randf() < 0.22:
		_add_invite("wedding", marriers[randi() % marriers.size()], randf() < 0.45)
	if age >= 24 and age <= 45 and not kin.is_empty() and randf() < 0.12:
		_add_invite("baby", kin[randi() % kin.size()], false)
	if age >= 30 and age % 10 == 0 and randf() < 0.5 and not kin.is_empty():
		_add_invite("reunion", kin[randi() % kin.size()], randf() < 0.3)
	# friendships lapse when nobody tends them
	for fid in GameState.npcs_with("friend") + GameState.npcs_with("best_friend"):
		var n: Dictionary = GameState.npcs[fid]
		if int(n["closeness"]) < 22 and not bool(n.get("lapsed", false)):
			n["lapsed"] = true
			s["lapsed"] = int(s["lapsed"]) + 1
			GameState.add_log("I realised I hadn't spoken to %s in years. Neither of us had decided that." % n["first"])
		elif int(n["closeness"]) >= 40 and bool(n.get("lapsed", false)):
			n["lapsed"] = false
	# food and the phone
	var d: Dictionary = DIETS[str(s["diet"])]
	if age >= 14 and (d["health"] != 0.0 or d["happy"] != 0.0):
		GameState.apply_effects({"health": d["health"], "happiness": d["happy"]})
	if str(s["diet"]) == "cook" and age >= 18:
		GameState.spend_time(1)
	var lvl := Phrases.tech_level()
	var plan := str(s["plan"])
	if lvl >= 3 and plan == "unlimited":
		GameState.apply_effects({"stress": 1.2, "happiness": 0.6})
	elif lvl >= 2 and plan == "basic":
		for fid2 in GameState.npcs_with("friend"):
			GameState.change_closeness(fid2, -1)


func lapsed_friends() -> Array:
	var out: Array = []
	for fid in GameState.npcs_with("friend") + GameState.npcs_with("best_friend"):
		if bool(GameState.npcs[fid].get("lapsed", false)):
			out.append(fid)
	return out


# ------------------------------------------------------------ menu

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "real:" + act, "arg": arg, "on": on}


func menu() -> Dictionary:
	var s := st()
	var rows: Array = []
	var info: Array = []
	info.append("Invitations answered: %d  ·  missed: %d  ·  friendships lapsed: %d" % [int(s["attended"]) + int(s["sent"]), int(s["missed"]), int(s["lapsed"])])
	var pending: Array = invites()
	if pending.is_empty():
		info.append("Nothing is waiting for an answer.")
	for i in range(pending.size()):
		var iv: Dictionary = pending[i]
		var d: Dictionary = INVITE_KINDS[str(iv["kind"])]
		var who: String = GameState.npcs[str(iv["who"])]["first"] if GameState.npcs.has(str(iv["who"])) else "someone"
		var cost := Actions._cost(int(d["gift"])) + int(iv["travel"])
		var sub := "%s%s · %d time" % [GameState.fmt_money(cost), " (travel included)" if int(iv["travel"]) > 0 else "", int(d["time"])]
		rows.append(_row(str(d["icon"]), "Go to %s's %s" % [who, str(d["name"]).to_lower()], sub, "attend", i))
		rows.append(_row("💌", "Send regards instead", "A card, a gift or flowers — %s" % GameState.fmt_money(Actions._cost(int(d["gift"]) / 2)), "send", i))
	if not lapsed_friends().is_empty():
		rows.append(_row("📞", "Call someone you've lost touch with", "%d friendship%s have gone quiet" % [lapsed_friends().size(), "" if lapsed_friends().size() == 1 else "s"], "reach"))
	rows.append(_row("📱", "Phone & internet: %s" % str(PLANS[str(s["plan"])]["name"]), "%s a year" % GameState.fmt_money(phone_cost()), "plan", null, true))
	for k in DIETS.keys():
		var cur: bool = str(s["diet"]) == str(k)
		rows.append(_row(str(DIETS[k]["icon"]), "%s%s" % [str(DIETS[k]["name"]), "  ✓" if cur else ""], str(DIETS[k]["sub"]), "diet", str(k), not cur))
	return {"icon": "💌", "title": "Keeping up", "rows": rows, "info": info}


func act(key: String, arg) -> void:
	var s := st()
	match key:
		"attend":
			var i := int(arg)
			if i < 0 or i >= s["invites"].size():
				return
			var iv: Dictionary = s["invites"][i]
			var d: Dictionary = INVITE_KINDS[str(iv["kind"])]
			var cost := Actions._cost(int(d["gift"])) + int(iv["travel"])
			if not Actions._can_pay(cost, str(d["name"])) or (int(d["time"]) > 0 and not GameState.spend_time(int(d["time"]))):
				return
			var id := str(iv["who"])
			_p()["money"] = int(_p()["money"]) - cost
			s["invites"].remove_at(i)
			s["attended"] = int(s["attended"]) + 1
			_resolve_attend(str(iv["kind"]), id)
		"send":
			var i2 := int(arg)
			if i2 < 0 or i2 >= s["invites"].size():
				return
			var iv2: Dictionary = s["invites"][i2]
			var d2: Dictionary = INVITE_KINDS[str(iv2["kind"])]
			var cost2 := Actions._cost(int(d2["gift"]) / 2)
			if not Actions._can_pay(cost2, "Regards"):
				return
			_p()["money"] = int(_p()["money"]) - cost2
			var id2 := str(iv2["who"])
			s["invites"].remove_at(i2)
			s["sent"] = int(s["sent"]) + 1
			if GameState.npcs.has(id2):
				GameState.change_closeness(id2, 2 if str(iv2["kind"]) != "funeral" else 0)
			EventEngine.push_info("💌", "Sent regards", "I couldn't be there, and I said so in writing. It was less than being there and more than nothing.", {"stress": 2})
		"reach":
			var lf := lapsed_friends()
			if lf.is_empty() or not GameState.spend_time(1):
				return
			var fid: String = lf[randi() % lf.size()]
			var n: Dictionary = GameState.npcs[fid]
			if randf() < 0.72:
				GameState.change_closeness(fid, 20)
				n["lapsed"] = false
				EventEngine.push_info("📞", "Back in touch", "%s picked up on the second ring. We talked for two hours, and neither of us mentioned the gap." % n["first"], {"happiness": 6})
			else:
				GameState.change_closeness(fid, 3)
				EventEngine.push_info("📞", "Voicemail", "%s's phone rang out. I left a message and felt braver than I had any right to." % n["first"], {"happiness": 1, "stress": 2})
		"plan":
			var order := ["basic", "standard", "unlimited"]
			s["plan"] = order[(order.find(str(s["plan"])) + 1) % 3]
		"diet":
			s["diet"] = str(arg)


func _resolve_attend(kind: String, id: String) -> void:
	var n: Dictionary = GameState.npcs.get(id, {})
	var who: String = str(n.get("first", "them"))
	match kind:
		"wedding":
			if not n.is_empty():
				GameState.change_closeness(id, 8)
			var r := randf()
			if r < 0.25:
				EventEngine.push_info("💒", "The wedding", "The speeches ran long and the DJ was the groom's cousin. I danced anyway and ended up in the photographs.", {"happiness": 8, "karma": 1})
				GameState.apply_effects({"happiness": 8})
			elif r < 0.5:
				EventEngine.push_info("💒", "The wedding", "I was put on the table with the people nobody knew where else to seat. One of them is now a friend.", {"happiness": 5})
				GameState.apply_effects({"happiness": 5})
			else:
				EventEngine.push_info("💒", "The wedding", "It rained, the marquee leaked and everyone said it was charming. I cried during the vows and pretended it was hay fever.", {"happiness": 6, "stress": 1})
				GameState.apply_effects({"happiness": 6, "stress": 1})
		"birthday":
			if not n.is_empty():
				GameState.change_closeness(id, 6)
			EventEngine.push_info("🎂", "The party", "%s was delighted I came. I stayed longer than I meant to and left with cake in a napkin." % who, {"happiness": 4})
			GameState.apply_effects({"happiness": 4})
		"funeral":
			for kid in GameState.npcs_with("sibling") + GameState.npcs_with("mother") + GameState.npcs_with("father"):
				GameState.change_closeness(kid, 4)
			GameState.apply_effects({"stress": 4, "happiness": -2, "karma": 2})
			GameState.add_log("I went to %s's funeral. I stood at the back, then I didn't." % who)
			EventEngine.push_info("⚱️", "The funeral", "There were more people than I expected, and each of them had a story I had not heard. I left feeling that it had been the right place to be.", {"stress": 4, "happiness": -2})
			LifeThreads.remember("grief", "Saying goodbye to %s" % who, "I was in the room, and I am glad I was.", id, 55, ["loss", "funeral"])
		"baby":
			if not n.is_empty():
				GameState.change_closeness(id, 5)
			EventEngine.push_info("🍼", "Baby shower", "There were cupcakes, a game involving nappies and a great many opinions about names. %s looked happier than I had ever seen them." % who, {"happiness": 4})
			GameState.apply_effects({"happiness": 4})
		"reunion":
			if not n.is_empty():
				GameState.change_closeness(id, 10)
			EventEngine.push_info("🥂", "The reunion", "Everyone had changed, and in exactly the ways their teenage selves would have hated. We talked until they turned the lights up.", {"happiness": 5})
			GameState.apply_effects({"happiness": 5})


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	match t:
		"invite": return not s["invites"].is_empty()
		"lapsed_friend": return not lapsed_friends().is_empty()
		"missed_funeral": return GameState.has_flag("missed_a_funeral")
		"diet:takeaway": return str(s["diet"]) == "takeaway"
		"diet:cook": return str(s["diet"]) == "cook"
		"plan:unlimited": return str(s["plan"]) == "unlimited"
	if t.begins_with("tech:"):
		return Phrases.tech_level() >= int(t.substr(5))
	if t.begins_with("pretech:"):
		return Phrases.tech_level() < int(t.substr(8))
	return false

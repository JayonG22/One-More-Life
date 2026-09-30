extends Node

## The street game: a supplier, a product you can stretch or keep pure, turf
## zones with rivals and police, a crew, dirty money and how you clean it.
## All names are fictional and the mechanics are abstract.

const PRODUCTS := {
	"comet": ["☄️", "Blue Comet", 40],
	"pixie": ["🧚", "Pixie Dust", 25],
	"static": ["⚡", "Static", 60],
	"moon": ["🌕", "Moonrock", 90],
}
const ZONES := [
	["corner", "🚦", "Fifth & Main corner", 1.0, 1.0, 0.8],
	["projects", "🏚️", "The Eastside projects", 1.2, 0.8, 0.6],
	["campus", "🎓", "University campus", 0.9, 1.3, 1.1],
	["clubs", "🪩", "Nightclub district", 1.4, 1.5, 1.2],
	["suburbs", "🏡", "The quiet suburbs", 0.7, 1.7, 1.4],
]
const RIVALS := ["the Vipers", "Los Cuervos", "the Dock Street Boys", "the Kowalski crew", "the Jade Tigers", "Big Earl's people"]
const CUTS := [["pure", "💎", "Keep it pure", 1.0, 1.0], ["light", "🥄", "Step on it a little", 1.35, 0.8], ["heavy", "🧂", "Stretch it hard", 1.9, 0.55]]


func _p() -> Dictionary:
	return GameState.player


func d() -> Dictionary:
	var p := _p()
	if not p.has("dealer") or not (p["dealer"] is Dictionary):
		p["dealer"] = {}
	return p["dealer"]


func active() -> bool:
	return d().get("on", false)


func _start() -> void:
	var dd := d()
	dd["on"] = true
	dd["rep"] = 5
	dd["stash"] = 0
	dd["units"] = 0
	dd["purity"] = 0.0
	dd["product"] = ""
	dd["turf"] = {}
	dd["crew"] = []
	dd["rivals"] = {}
	for z in ZONES:
		dd["turf"][z[0]] = 0
		dd["rivals"][z[0]] = RIVALS[randi() % RIVALS.size()]
	dd["laundered"] = 0


# ================================================================ menus

func menu(key: String) -> Dictionary:
	var p := _p()
	if key.begins_with("buy"):
		return _buy_menu()
	if key.begins_with("sell"):
		return _sell_menu()
	if key.begins_with("zone:"):
		return _zone_menu(key.substr(5))
	if not active():
		return {"icon": "🌃", "title": "The street", "rows": [{"icon": "🤝", "name": "Get into dealing", "sub": "Age 16+ · a friend of a friend knows a supplier", "act": "dealer:start", "on": int(p["age"]) >= 16 and not GameState.in_prison()}], "info": ["Money comes fast. So do the police, rival crews, and people you'll hurt along the way."]}
	var dd := d()
	var rows: Array = []
	var prod := "nothing" if dd["product"] == "" else "%d units of %s (%d%% pure)" % [int(dd["units"]), PRODUCTS[dd["product"]][1], int(float(dd["purity"]) * 100)]
	rows.append({"icon": "📦", "name": "Buy from the supplier", "sub": "Holding " + prod, "menu": "dealer:buy", "on": true})
	rows.append({"icon": "💵", "name": "Sell on your turf", "sub": "Pick a zone", "menu": "dealer:sell", "on": int(dd["units"]) > 0})
	for z in ZONES:
		rows.append({"icon": z[1], "name": z[2], "sub": "You control %d%% · %s run the rest" % [int(dd["turf"][z[0]]), dd["rivals"][z[0]]], "menu": "dealer:zone:" + z[0], "on": true})
	rows.append({"icon": "🧑‍🤝‍🧑", "name": "Recruit a corner kid", "sub": "%d in your crew · they sell for a cut" % dd["crew"].size(), "act": "dealer:recruit", "on": dd["crew"].size() < 6})
	if dd["crew"].size() > 0:
		rows.append({"icon": "💰", "name": "Pay your crew well this year", "sub": "%s · loyalty up, fewer snitches" % GameState.fmt_money(Actions._cost(2000 * dd["crew"].size())), "act": "dealer:pay", "on": true})
	rows.append({"icon": "🧼", "name": "Launder your stash", "sub": "%s dirty · %s" % [GameState.fmt_money(int(dd["stash"])), "through your business (85%)" if not p["business"].is_empty() else "through a car wash front (70%)"], "act": "dealer:launder", "on": int(dd["stash"]) > 0})
	rows.append({"icon": "🤫", "name": "Lie low", "sub": "Heat down, product sits", "act": "dealer:lowkey", "on": true})
	rows.append({"icon": "🚪", "name": "Get out of the game", "sub": "Walk away. Some people won't let you", "act": "dealer:quit", "on": true})
	var info: Array = ["Street rep %d · dirty cash %s · heat %d%%" % [int(dd["rep"]), GameState.fmt_money(int(dd["stash"])), int(p.get("heat", 0))]]
	return {"icon": "🌃", "title": "The street", "rows": rows, "info": info}


func _buy_menu() -> Dictionary:
	var rows: Array = []
	for k in PRODUCTS.keys():
		var pr: Array = PRODUCTS[k]
		for n in [10, 50, 200]:
			var cost := Actions._cost(int(pr[2]) * n / 2)
			rows.append({"icon": pr[0], "name": "%d units of %s" % [n, pr[1]], "sub": "%s wholesale · street value about %s" % [GameState.fmt_money(cost), GameState.fmt_money(Actions._cost(int(pr[2]) * n))], "act": "dealer:buy", "arg": [k, n], "on": int(_p()["money"]) + int(d().get("stash", 0)) >= cost})
	return {"icon": "📦", "title": "The supplier", "rows": rows, "info": ["Pay from your clean money or your dirty stash. Buying a new product replaces what you're holding."]}


func _sell_menu() -> Dictionary:
	var rows: Array = []
	var dd := d()
	for z in ZONES:
		for c in CUTS:
			rows.append({"icon": c[1], "name": "%s · %s" % [z[2], c[2]], "sub": "Demand ×%.1f · police ×%.1f · %s units" % [float(z[3]), float(z[5]), str(int(int(dd["units"]) * float(c[3])))], "act": "dealer:sell", "arg": [z[0], c[0]], "on": int(dd["units"]) > 0})
	return {"icon": "💵", "title": "Sell", "rows": rows, "info": ["Stretching the product makes more to sell, but customers pay less, complain, and get hurt more often. Pure product builds rep."]}


func _zone_menu(zid: String) -> Dictionary:
	var dd := d()
	var z := _zone(zid)
	var rows: Array = [
		{"icon": "👊", "name": "Push %s out" % dd["rivals"][zid], "sub": "A fight · win turf, risk your health", "act": "dealer:war", "arg": zid, "on": true},
		{"icon": "🤝", "name": "Make a deal with %s" % dd["rivals"][zid], "sub": "Split the zone peacefully · costs rep", "act": "dealer:truce", "arg": zid, "on": int(dd["turf"][zid]) < 50},
		{"icon": "🎁", "name": "Win over the neighborhood", "sub": "%s · block parties, groceries, favors" % GameState.fmt_money(Actions._cost(5000)), "act": "dealer:hearts", "arg": zid, "on": true},
	]
	return {"icon": z[1], "title": z[2], "rows": rows, "info": ["You control %d%% of %s." % [int(dd["turf"][zid]), z[2]]]}


func _zone(zid: String) -> Array:
	for z in ZONES:
		if z[0] == zid:
			return z
	return ZONES[0]


# ================================================================ actions

func act(key: String, arg = null) -> void:
	var p := _p()
	var dd := d()
	match key:
		"start":
			if Actions._out_of_time(): return
			_start()
			GameState.add_milestone(p["age"], "started dealing")
			Actions._done("🌃", "The street", "A friend introduced me to a guy who introduced me to a supplier. I'm in.", {"karma": -8, "stress": 5})
		"buy":
			var k: String = arg[0]
			var n := int(arg[1])
			var cost := Actions._cost(int(PRODUCTS[k][2]) * n / 2)
			if Actions._out_of_time(): return
			var from_stash := mini(int(dd["stash"]), cost)
			if int(p["money"]) + from_stash < cost:
				return
			dd["stash"] = int(dd["stash"]) - from_stash
			p["money"] = int(p["money"]) - (cost - from_stash)
			if dd["product"] != k:
				dd["units"] = 0
			dd["product"] = k
			dd["units"] = int(dd["units"]) + n
			dd["purity"] = randf_range(0.82, 0.97)
			var txt := "I picked up %d units of %s for %s." % [n, PRODUCTS[k][1], GameState.fmt_money(cost)]
			if randf() < 0.06:
				dd["units"] = int(int(dd["units"]) * 0.5)
				txt += " Half of it was junk. The supplier shrugged."
			Actions._done(PRODUCTS[k][0], "Supplier", txt, {"heat": 3})
		"sell":
			_sell(str(arg[0]), str(arg[1]))
		"war":
			if Actions._out_of_time(): return
			var zid: String = arg
			Minigames.play("fight", {"skill": 40 + int(dd["rep"]) / 2 + int(Daily.fight_bonus() * 100), "difficulty": 1.0, "opponent": str(dd["rivals"][zid]).capitalize()}, Callable(self, "_war_done").bind(zid))
		"truce":
			var zid2: String = arg
			if Actions._out_of_time(): return
			dd["turf"][zid2] = maxi(int(dd["turf"][zid2]), 50)
			dd["rep"] = maxi(0, int(dd["rep"]) - 5)
			Actions._done("🤝", "Truce", "I sat down with %s. We split %s down the middle." % [dd["rivals"][zid2], _zone(zid2)[2]], {"stress": -4})
		"hearts":
			var zid3: String = arg
			var cost2 := Actions._cost(5000)
			if Actions._out_of_time(): return
			if not Actions._can_pay(cost2, "Neighborhood"): return
			dd["turf"][zid3] = mini(100, int(dd["turf"][zid3]) + 10)
			dd["hearts_" + zid3] = true
			Actions._done("🎁", "The neighborhood", "I paid for a block party and groceries for a few families on %s. Nobody talks to the cops about me now." % _zone(zid3)[2], {"money": -cost2, "heat": -8})
		"recruit":
			if Actions._out_of_time(): return
			var fid := GameState.create_npc("friend", {"age": randi_range(16, 24), "closeness": 50})
			var fn: Dictionary = GameState.npcs[fid]
			fn["title"] = "Corner kid"
			fn["loyalty"] = randi_range(40, 80)
			dd["crew"].append(fid)
			Actions._done("🧑‍🤝‍🧑", "New crew", "%s started working a corner for me." % fn["first"], {"karma": -3})
		"pay":
			var cost3 := Actions._cost(2000 * dd["crew"].size())
			if not Actions._can_pay(cost3, "Crew"): return
			p["money"] = int(p["money"]) - cost3
			for cid in dd["crew"]:
				if GameState.npcs.has(cid):
					GameState.npcs[cid]["loyalty"] = mini(100, int(GameState.npcs[cid].get("loyalty", 50)) + 20)
			Actions._done("💰", "Crew", "I took care of my people this year.", {})
		"launder":
			if Actions._out_of_time(): return
			var rate := 0.85 if not p["business"].is_empty() else 0.7
			var amt := int(dd["stash"])
			var clean := int(amt * rate)
			dd["stash"] = 0
			dd["laundered"] = int(dd.get("laundered", 0)) + clean
			p["money"] = int(p["money"]) + clean
			if not p["business"].is_empty():
				p["business"]["cooked"] = true
			Actions._done("🧼", "Laundering", "I ran %s through %s and got %s back clean." % [GameState.fmt_money(amt), "the books at " + str(p["business"]["name"]) if not p["business"].is_empty() else "a car wash that washes very few cars", GameState.fmt_money(clean)], {"heat": 4})
		"lowkey":
			if Actions._out_of_time(): return
			GameState.apply_effects({"heat": -15})
			Actions._done("🤫", "Lying low", "I stayed off the street for a while.", {"stress": -3})
		"quit":
			dd["on"] = false
			GameState.add_milestone(p["age"], "got out of dealing")
			if int(dd["rep"]) > 40 and randf() < 0.3:
				EventEngine.push_info("🔫", "Nobody just leaves", "Someone I used to work with left a message on my car window: \"We'll be in touch.\"", GameState.apply_effects({"stress": 15}))
			else:
				Actions._done("🚪", "Out", "I flushed what I had and walked away from the street.", {"karma": 6, "stress": -8})


func _sell(zid: String, cut: String) -> void:
	var p := _p()
	var dd := d()
	if int(dd["units"]) <= 0: return
	if Actions._out_of_time(): return
	var z := _zone(zid)
	var c: Array = CUTS[0]
	for x in CUTS:
		if x[0] == cut:
			c = x
	var prod: Array = PRODUCTS[dd["product"]]
	var units := int(int(dd["units"]) * float(c[3]))
	var control := float(dd["turf"][zid]) / 100.0
	var sold := int(units * clampf(0.3 + control * 0.6 + float(dd["rep"]) / 250.0, 0.2, 1.0) * float(z[3]) / 1.2)
	sold = clampi(sold, 1, units)
	var quality := float(dd["purity"]) * float(c[4])
	var price := int(prod[2]) * float(z[4]) * (0.6 + quality * 0.6)
	var cash := Actions._cost(int(sold * price))
	var left := int((units - sold) / float(c[3]))
	dd["units"] = left
	dd["stash"] = int(dd["stash"]) + cash
	dd["rep"] = clampi(int(dd["rep"]) + (3 if cut == "pure" else (1 if cut == "light" else -2)), 0, 100)
	GameState.counter("deals")
	var heat := int(6 * float(z[5]) * (1.0 - control * 0.4) * (0.6 if dd.get("hearts_" + zid, false) else 1.0))
	var fx := {"heat": heat, "karma": -3}
	var txt := "I moved %d units of %s at %s and made %s in dirty cash." % [sold, prod[1], z[2], GameState.fmt_money(cash)]
	var harm := 0.02 if cut == "pure" else (0.05 if cut == "light" else 0.12)
	if randf() < harm:
		fx["karma"] = -15
		fx["heat"] = heat + 15
		txt += " Later I heard someone who bought from me ended up in the ER."
		GameState.counter("dealer_harm")
	if randf() < 0.08 * float(z[5]) * (1.0 + float(p.get("heat", 0)) / 100.0):
		_sting(cash)
	Actions._done(prod[0], "Dealing", txt, fx)


func _sting(cash: int) -> void:
	var tells := ["asks way too many questions about where it comes from", "is a new face nobody vouches for", "keeps checking the parked van across the street", "wants a much bigger amount than normal"]
	var tell: String = tells[randi() % tells.size()]
	EventEngine.push_decision({"id": "_sting", "icon": "🚓", "title": "A new buyer", "text": "A new buyer wants to meet. They %s." % tell, "choices": [
		{"label": "Sell to them", "outcomes": [
			{"weight": 2, "text": "Undercover cop. They were waiting for me.", "trial": ["drug dealing", 2, 8]},
			{"weight": 1, "text": "Just a nervous customer. Easy money.", "effects": {"money": int(cash * 0.2)}}]},
		{"label": "Walk away", "outcomes": [{"text": "I walked. A week later, three other dealers got picked up in a sting.", "effects": {"stress": 3}}]},
		{"label": "Send a crew member", "outcomes": [
			{"weight": 1, "text": "My runner got arrested. He didn't say my name. This time.", "effects": {"heat": 10}},
			{"weight": 1, "text": "My runner got arrested and gave them my name.", "trial": ["drug dealing", 2, 6]}]},
	]})


func _war_done(score: float, detail: Dictionary, zid: String) -> void:
	var dd := d()
	var won: bool = detail.get("won", score >= 0.5)
	if won:
		var gain := randi_range(15, 35)
		var was_full := int(dd["turf"][zid]) >= 100
		dd["turf"][zid] = mini(100, int(dd["turf"][zid]) + gain)
		dd["rep"] = mini(100, int(dd["rep"]) + 6)
		GameState.counter("turf_wars")
		var txt := "I ran %s off %s. I control %d%% now." % [dd["rivals"][zid], _zone(zid)[2], int(dd["turf"][zid])]
		if int(dd["turf"][zid]) >= 100 and not was_full:
			txt += " The whole zone is mine."
			GameState.counter("zones_owned")
		Actions._done("👊", "Turf war", txt, {"heat": 10, "karma": -6})
	else:
		dd["turf"][zid] = maxi(0, int(dd["turf"][zid]) - 10)
		Actions._done("🤕", "Turf war", "%s put me in the hospital." % str(dd["rivals"][zid]).capitalize(), {"health": -20, "heat": 6, "money": -Actions._cost(3000)})


# ================================================================ yearly

func yearly() -> void:
	if not active() or GameState.in_prison():
		return
	var p := _p()
	var dd := d()
	var crew_cash := 0
	for cid in dd["crew"].duplicate():
		if not GameState.npcs.has(cid) or not GameState.npcs[cid]["alive"]:
			dd["crew"].erase(cid)
			continue
		var cn: Dictionary = GameState.npcs[cid]
		crew_cash += Actions._cost(randi_range(2000, 9000))
		cn["loyalty"] = maxi(0, int(cn.get("loyalty", 50)) - randi_range(3, 10))
		if int(cn["loyalty"]) < 25 and randf() < 0.25:
			dd["crew"].erase(cid)
			EventEngine.push_decision({"id": "_snitch", "icon": "🐀", "title": "A rat", "text": "Word is %s has been talking to the police." % cn["first"], "choices": [
				{"label": "Cut them loose and lie low", "outcomes": [{"text": "I cut %s off and went quiet for a while." % cn["first"], "effects": {"heat": 10}}]},
				{"label": "Confront them", "outcomes": [
					{"weight": 1, "text": "%s swore it wasn't true, then left town." % cn["first"], "effects": {"stress": 5}},
					{"weight": 1, "text": "%s was wearing a wire." % cn["first"], "trial": ["drug trafficking", 3, 10]}]},
			]})
	if crew_cash > 0:
		dd["stash"] = int(dd["stash"]) + crew_cash
		GameState.add_log("My crew brought in %s this year." % GameState.fmt_money(crew_cash))
		GameState.apply_effects({"heat": 3 * dd["crew"].size()})
	for z in ZONES:
		var zid: String = z[0]
		if int(dd["turf"][zid]) > 0 and randf() < 0.15:
			dd["turf"][zid] = maxi(0, int(dd["turf"][zid]) - randi_range(5, 20))
			if randf() < 0.3:
				GameState.add_log("%s shot up one of my corners on %s." % [str(dd["rivals"][zid]).capitalize(), z[2]])
				GameState.apply_effects({"stress": 8})
				if randf() < 0.2:
					GameState.apply_effects({"health": -15})
					GameState.add_log("I was grazed by a bullet.")
	if float(p.get("heat", 0)) >= 80 and randf() < 0.3:
		var seized := int(dd["stash"])
		dd["stash"] = 0
		dd["units"] = 0
		EventEngine.push_decision({"id": "_raid", "icon": "🚔", "title": "Raid", "text": "The police kicked in the door at dawn.", "choices": [
			{"label": "Go quietly", "outcomes": [{"text": "They took the stash (%s) and me." % GameState.fmt_money(seized), "trial": ["drug trafficking", 3, 12]}]},
			{"label": "Run", "outcomes": [
				{"weight": 1, "text": "I went out the back window and didn't stop running. They took everything I had there.", "effects": {"heat": 20}},
				{"weight": 2, "text": "They caught me in the alley.", "trial": ["drug trafficking and resisting arrest", 4, 14]}]},
		]})

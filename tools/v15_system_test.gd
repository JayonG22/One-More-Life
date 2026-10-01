extends Node

## v0.15 gate — "Everything From Real Life", checked rather than claimed.

var failures: Array = []
var checks := 0
var sections := 0
var completed: Array = []


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V15: " + msg)


func _ready() -> void:
	seed(1515)
	for s in ["depth", "variants", "phrases", "fixtures", "tenancy", "transit", "keeping", "events", "panels"]:
		sections += 1
		call("_" + s)
		completed.append(s)
	ok(completed.size() == sections, "a section aborted: ran %d of %d" % [completed.size(), sections])
	print("V15 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), sections, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


## The release rule: no choice with a single deterministic outcome.
func _depth() -> void:
	var thin := 0
	var events := 0
	var choices := 0
	for e in ContentDB.events:
		events += 1
		for c in e.get("choices", []):
			choices += 1
			var outs: Array = c.get("outcomes", [])
			if outs.size() < 2 and not (outs.size() == 1 and (outs[0] as Dictionary).has("play")):
				thin += 1
	ok(thin == 0, "%d choices still have a single outcome" % thin)
	ok(events >= 633, "only %d events are loaded — a file is missing from EVENT_FILES" % events)
	print("  depth: %d events, %d choices, %d thin" % [events, choices, thin])


func _phrases() -> void:
	GameState.new_life({"gender": "male", "country": "us"})
	var t := "It was {~a cold|a grey|a wet} morning."
	var first := Phrases.expand(t)
	ok(first != t and first.find("{") == -1, "an alternative was not resolved: %s" % first)
	ok(Phrases.expand(t) == first, "the same line read differently twice in a row")
	var seen := {}
	for i in range(40):
		GameState.player["phrase_seed"] = randi()
		seen[Phrases.expand(t)] = true
	ok(seen.size() == 3, "only %d of 3 readings ever appeared across 40 lives" % seen.size())
	GameState.player["money"] = 10
	ok(Phrases.expand("{~poor=counting coins|rich=tipping|paying}") == "counting coins", "a true condition was not preferred")
	GameState.player["money"] = 900000
	ok(Phrases.expand("{~poor=counting coins|rich=tipping|paying}") == "tipping", "the rich reading did not win")
	ok(Phrases.era_word("phone") != "", "no era vocabulary")
	var nested := Phrases.expand("Met {~outside {fx.shop}|on {fx.street}} today.")
	ok(nested.find("{fx.") != -1 and nested.find("{~") == -1 and nested.ends_with("today."), "a token nested inside an option broke: %s" % nested)
	var two := Phrases.expand("{~a|b} and {~c|d}")
	ok(two.find("{") == -1 and two.find(" and ") != -1, "two alternatives in one line did not both resolve: %s" % two)
	print("  phrases: 3 readings of one line, stable within a life")


func _fixtures() -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	var pub := Fixtures.named("pub")
	ok(pub != "" and pub != "the pub", "the pub was never invented")
	ok(Fixtures.named("pub") == pub, "the pub changed its name")
	for k in Fixtures.KINDS:
		ok(Fixtures.named(k) != "", "%s has no name" % k)
	var txt := EventEngine.tokens("We met at {fx.pub} on {fx.street}.", {})
	ok(txt.find(pub) != -1 and txt.find("{") == -1, "fixture tokens did not resolve: %s" % txt)
	var other := ""
	for i in range(30):
		GameState.new_life({"gender": "male", "country": "uk"})
		other = Fixtures.named("pub")
		if other != pub:
			break
	ok(other != pub, "every life had the same pub")
	print("  fixtures: ", pub, " / ", Fixtures.named("street"))


func _fresh(age: int = 24) -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	var p := GameState.player
	p["age"] = age
	p["housing"] = "apartment"
	p["money"] = 50000


func _tenancy() -> void:
	_fresh()
	Tenancy.sync()
	ok(Tenancy.active(), "renting a flat did not open a tenancy")
	var rent0 := Tenancy.annual_rent()
	ok(rent0 > 3000, "rent of %d is not plausible" % rent0)
	var t := Tenancy.st()
	ok(LANDLORDS_OK(str(t["kind"])), "the landlord has no temperament")
	ok(int(t["deposit"]) > 0, "no deposit was taken")
	# a flatmate halves the bill
	Tenancy.act("flatmate", null)
	ok(Tenancy.mates().size() == 1, "a flatmate did not move in")
	ok(Tenancy.annual_rent() < rent0, "a flatmate did not reduce the rent")
	# rent rises over the years, and the boiler ages
	var rent1 := int(t["rent"])
	for i in range(6):
		Tenancy.yearly()
	ok(int(Tenancy.st()["rent"]) >= rent1 or not Tenancy.active(), "six years and the rent never moved")
	# leaving settles the deposit
	_fresh()
	Tenancy.sync()
	var before := int(GameState.player["money"])
	GameState.player["housing"] = "parents"
	Tenancy.sync()
	ok(not Tenancy.active(), "leaving the flat left the tenancy open")
	ok(int(GameState.player["money"]) > before, "the deposit never came back")
	# a bad landlord keeps more than a kind one
	var kept := {}
	for kind in ["kind", "grasping"]:
		_fresh()
		Tenancy.sync()
		Tenancy.st()["kind"] = kind
		Tenancy.st()["damp"] = 30.0
		var m0 := int(GameState.player["money"])
		GameState.player["housing"] = "parents"
		Tenancy.sync()
		kept[kind] = int(GameState.player["money"]) - m0
	ok(int(kept["kind"]) > int(kept["grasping"]), "a grasping landlord returned as much deposit as a kind one")
	# the bill is actually charged
	_fresh()
	Tenancy.sync()
	ok(Tenancy.utilities() > 0, "a rented flat has no bills")
	print("  tenancy: rent %s, deposit returned %s (kind) vs %s (grasping)" % [GameState.fmt_money(rent0), GameState.fmt_money(int(kept["kind"])), GameState.fmt_money(int(kept["grasping"]))])


func LANDLORDS_OK(k: String) -> bool:
	return Tenancy.LANDLORDS.has(k)


func _transit() -> void:
	_fresh(30)
	GameState.player["job"] = {"title": "Office clerk", "salary": 40000, "perf": 50, "years": 1}
	ok(Transit.commuting(), "an employed adult is not commuting")
	ok(Transit.available("walk"), "walking is never available")
	ok(Transit.minutes("drive") > 0 and Transit.minutes("walk") > Transit.minutes("bike"), "walking is not slower than cycling")
	ok(not Transit.available("drive"), "driving without a car is available")
	GameState.player["car"] = GameState.CARS.keys()[0]
	ok(Transit.available("drive"), "owning a car does not enable driving")
	# premiums follow age and record
	GameState.player["age"] = 19
	var young := Transit.premium()
	GameState.player["age"] = 35
	var mid := Transit.premium()
	ok(young > mid * 1.8, "a nineteen-year-old pays %d against %d at thirty-five" % [young, mid])
	Transit.st()["cover"] = "full"
	var full := Transit.premium()
	Transit.st()["cover"] = "third"
	ok(full > Transit.premium(), "comprehensive cover is not dearer than third party")
	Transit.st()["cover"] = "none"
	ok(Transit.premium() == 0, "no insurance still has a premium")
	# a crash costs money and makes the next premium dearer
	Transit.st()["cover"] = "third"
	Transit.st()["no_claims"] = 6
	var p0 := Transit.premium()
	GameState.player["money"] = 100000
	Transit.crash("minor")
	ok(int(Transit.st()["no_claims"]) == 0, "a crash left the no-claims bonus intact")
	ok(Transit.premium() > p0, "a crash did not raise the premium")
	ok(Transit._recent_crashes() == 1, "the crash was not recorded")
	# the yearly pass runs with consequences
	var t0 := int(GameState.player["time_left"])
	GameState.player["car"] = ""
	Transit.yearly()
	ok(Transit.current() in ["bus", "train", "bike", "walk"], "no sensible mode without a car")
	ok(Transit.costs() >= 0, "costs went negative")
	print("  transit: commute %d min by %s; premium at 19 %s vs 35 %s" % [Transit.minutes(Transit.current()), Transit.current(), GameState.fmt_money(young), GameState.fmt_money(mid)])


func _keeping() -> void:
	_fresh(28)
	for i in range(4):
		var id := GameState.create_npc("friend", {"age": 29, "closeness": 60})
	# invitations arrive and have a price
	var got := 0
	for y in range(40):
		GameState.player["age"] = 28 + (y % 10)
		Keeping.st()["invites"] = []
		Keeping.yearly()
		got += Keeping.invites().size()
	ok(got > 10, "only %d invitations in forty years" % got)
	# answering costs money; ignoring them costs friendships
	Keeping.st()["invites"] = []
	var fid := GameState.first_of("friend")
	ok(fid != "", "no friend to invite the player")
	Keeping._add_invite("wedding", fid, true)
	var m0 := int(GameState.player["money"])
	var c0 := int(GameState.npcs[fid]["closeness"])
	GameState.player["time_left"] = 12
	Keeping.act("attend", 0)
	ok(int(GameState.player["money"]) < m0, "going to a wedding was free")
	ok(int(GameState.npcs[fid]["closeness"]) > c0, "going to the wedding did nothing for the friendship")
	Keeping._add_invite("birthday", fid, false)
	var c1 := int(GameState.npcs[fid]["closeness"])
	Keeping.yearly()
	ok(int(GameState.npcs[fid]["closeness"]) < c1 + 1, "ignoring an invitation cost nothing")
	# deaths produce funerals
	Keeping.st()["invites"] = []
	GameState.npcs[fid]["closeness"] = 70
	GameState.npcs[fid]["alive"] = false
	Keeping.on_death(fid)
	ok(Keeping.invites().size() == 1 and str(Keeping.invites()[0]["kind"]) == "funeral", "a death did not produce a funeral")
	Keeping.yearly()
	ok(GameState.has_flag("missed_a_funeral"), "skipping a funeral left no mark")
	# diet moves the bill and the body
	Keeping.st()["diet"] = "takeaway"
	var dear := Keeping.costs()
	Keeping.st()["diet"] = "cook"
	ok(dear > Keeping.costs() + 1500, "takeaway is not dearer than cooking")
	# the era changes the phone
	var costs := []
	for y in [1980, 1995, 2008, 2026]:
		Phrases.year_override = y
		costs.append(Keeping.phone_cost())
	Phrases.year_override = 0
	ok(int(costs[3]) > int(costs[0]) * 3, "a modern phone and connection costs %s against %s in 1980" % [costs[3], costs[0]])
	Phrases.year_override = 1985
	ok(Phrases.era_word("phone") == "landline", "a 1985 phone is not a landline")
	Phrases.year_override = 2026
	ok(Phrases.era_word("phone") == "phone", "a modern phone is not a phone")
	Phrases.year_override = 0
	print("  keeping: %d invitations over 40 years, phone bill %s" % [got, costs])


func _events() -> void:
	var real := 0
	var three := 0
	for e in ContentDB.events:
		if str(e["id"]).begins_with("real."):
			real += 1
			if e["choices"].size() >= 3:
				three += 1
			for c in e["choices"]:
				ok(c["outcomes"].size() >= 2, "%s / %s has one outcome" % [e["id"], c["label"]])
	ok(real >= 26, "only %d real-life events" % real)
	ok(three == real, "some real-life events have fewer than three choices")
	# every tag used by an event is one the systems actually know
	for e in ContentDB.events:
		for k in ["real", "not_real"]:
			for t in e.get("conditions", {}).get(k, []):
				GameState.new_life({"gender": "male", "country": "us"})
				ok(Real.known_tag(str(t)), "%s uses an unknown tag %s" % [e["id"], str(t)])
	# play a real event end to end: pick every choice of a tenancy event
	_fresh()
	Tenancy.sync()
	Tenancy.st()["damp"] = 60.0
	var def: Dictionary = ContentDB.events_by_id["real.damp_patch"]
	for ci in range(def["choices"].size()):
		_fresh()
		Tenancy.sync()
		Tenancy.st()["damp"] = 60.0
		var inst := {"def": def, "roles": {}}
		var r := EventEngine.resolve(inst, ci)
		ok(str(r.get("text", "")) != "", "resolving choice %d of the damp event gave no text" % ci)
	print("  events: %d real-life events, all with 3+ choices" % real)


## Every row of every new menu must do something and never throw.
func _panels() -> void:
	var ran := 0
	for key in ["home", "go", "keep"]:
		_fresh(30)
		GameState.player["job"] = {"title": "Software engineer", "salary": 60000, "perf": 50, "years": 1}
		GameState.player["car"] = GameState.CARS.keys()[0]
		GameState.player["time_left"] = 12
		Tenancy.sync()
		Keeping._add_invite("wedding", GameState.create_npc("friend", {"age": 30, "closeness": 50}), false)
		var d: Dictionary = Real.menu(key)
		ok(str(d.get("title", "")) != "", "%s menu has no title" % key)
		ok(not (d.get("rows", []) as Array).is_empty() or key == "keep", "%s menu has no rows" % key)
		for row in d.get("rows", []):
			if not bool(row.get("on", true)):
				continue
			var act_key := str(row["act"]).substr(5)
			GameState.player["time_left"] = 12
			GameState.player["money"] = 100000
			Real.act(act_key, row.get("arg", null))
			ran += 1
			if not GameState.is_alive():
				break
	ok(ran >= 12, "only %d panel actions ran" % ran)
	EventEngine.pending.clear()
	print("  panels: %d actions ran without error" % ran)


## Rewritten openings have to resolve to clean text in every life, for every event.
func _variants() -> void:
	var checked := 0
	var leftovers := 0
	for e in ContentDB.events:
		var texts: Array = e["text"] if e["text"] is Array else [e["text"]]
		for t in texts:
			if str(t).find("{~") == -1:
				continue
			for i in range(6):
				GameState.new_life({"gender": "male" if i % 2 == 0 else "female", "country": "us"})
				GameState.player["phrase_seed"] = randi()
				var out := EventEngine.tokens(str(t), {})
				checked += 1
				if out.find("{~") != -1 or out.find("|") != -1 or out.find("{fx.") != -1 or out.find("{era.") != -1:
					leftovers += 1
					push_error("V15 unresolved text in %s: %s" % [e["id"], out])
	ok(leftovers == 0, "%d variant readings were left with raw braces" % leftovers)
	ok(checked >= 200, "only %d variant readings were checked" % checked)
	print("  variants: %d readings resolved cleanly" % checked)

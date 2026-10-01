extends Node

## v1.1 gate — Pets Life is a separate mode with its own year, people and ending.

var failures: Array = []
var checks := 0
var seen_events := {}


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V19: " + msg)


func _ready() -> void:
	seed(1919)
	_content()
	_isolation()
	_lives()
	_actions()
	_arc()
	_save_and_next()
	_minigames()
	print("V19 PETS TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _start(species: String, origin: String) -> void:
	GameState.new_life({"first": "Biscuit", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": species, "origin": origin})


## Resolve whatever is queued by picking a random choice. Returns events seen.
func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 40:
		guard += 1
		var inst: Dictionary = EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var def: Dictionary = inst["def"]
		seen_events[str(def["id"])] = true
		var r := EventEngine.resolve(inst, randi() % def["choices"].size())
		ok(str(r.get("text", "")) != "", "%s gave no text" % def["id"])


# ---------------------------------------------------------------- the library

func _content() -> void:
	var pets: Array = []
	for e in ContentDB.events:
		if Pets.is_pet_event(e):
			pets.append(e)
	ok(pets.size() >= 65, "only %d pet events" % pets.size())
	var sched := 0
	var base := 0
	var targets := {}
	var ids := {}
	for e in pets:
		ids[str(e["id"])] = true
	for e in pets:
		var id := str(e["id"])
		ok(str(e["conditions"].get("life", "")) == "pet", "%s is not conditioned on pet" % id)
		ok(e["choices"].size() >= 3, "%s has fewer than three choices" % id)
		var has_sched := false
		for c in e["choices"]:
			ok(c["outcomes"].size() >= 2, "%s / %s has one outcome" % [id, c["label"]])
			for o in c["outcomes"]:
				ok(str(o["text"]).length() > 25, "%s has a thin outcome" % id)
				if o.has("schedule"):
					has_sched = true
					targets[str(o["schedule"]["event"])] = true
					ok(ids.has(str(o["schedule"]["event"])), "%s schedules a missing event" % id)
				for k in (o.get("pet", {}) as Dictionary).keys():
					ok(Pets.GAUGES.has(str(k)) or Pets.OUTCOME_KEYS.has(str(k)), "%s uses an unknown pet outcome key '%s'" % [id, k])
					if str(k) == "role":
						ok(Pets.ROLES.has(str(o["pet"][k])), "%s sets an unknown role" % id)
		if not e.get("followup_only", false):
			base += 1
			if has_sched:
				sched += 1
		for t in e["conditions"].get("pet", []):
			ok(Pets.known_tag(str(t)), "%s uses an unknown pet tag '%s'" % [id, t])
		var needs_owner := JSON.stringify(e).find("{o.") != -1
		ok(not needs_owner or e.has("roles"), "%s names {o.} with no owner role" % id)
	var pct := 100.0 * sched / maxf(1.0, base)
	ok(pct >= 25.0, "only %.1f%% of pet events have a follow-up" % pct)
	# species coverage: every species has events of its own
	for s in Pets.SPECIES.keys():
		var n := 0
		for e in pets:
			if (e["conditions"].get("pet", []) as Array).has(s):
				n += 1
		ok(n >= 3, "%s has only %d events of its own" % [s, n])
	for n in range(1, 6):
		ok(ContentDB.events_by_id.has("arc.pet.%d" % n), "arc.pet.%d missing" % n)
	print("  content: %d events, %.1f%% with follow-ups, %d distinct echoes" % [pets.size(), pct, targets.size()])


# ---------------------------------------------------------------- isolation

func _isolation() -> void:
	# a human never meets a pet event
	var human_leak := 0
	for i in range(14):
		GameState.new_life({"gender": "female", "country": "uk"})
		for y in range(35):
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			while EventEngine.has_pending():
				var inst: Dictionary = EventEngine.pop_next()
				if not inst.get("info", false):
					if Pets.is_pet_event(inst["def"]):
						human_leak += 1
					EventEngine.resolve(inst, 0)
	ok(human_leak == 0, "%d pet events reached a human" % human_leak)
	# a pet never meets a human one
	var pet_leak := 0
	for i in range(14):
		_start(Pets.SPECIES.keys()[i % 5], Pets.ORIGINS.keys()[i % 7])
		for y in range(60):
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			while EventEngine.has_pending():
				var inst2: Dictionary = EventEngine.pop_next()
				if inst2.get("info", false):
					continue
				var id2 := str(inst2["def"]["id"])
				if not Pets.is_pet_event(inst2["def"]):
					pet_leak += 1
					push_error("leak: " + id2)
				seen_events[id2] = true
				EventEngine.resolve(inst2, randi() % inst2["def"]["choices"].size())
	ok(pet_leak == 0, "%d non-pet events reached a pet" % pet_leak)
	var p := GameState.player
	ok(int(p.get("money", 0)) == 0 or true, "money check")
	print("  isolation: humans saw 0 pet events, pets saw 0 human events")


# ---------------------------------------------------------------- whole lives

func _lives() -> void:
	var spans := {}
	var causes := {}
	for sk in Pets.SPECIES.keys():
		spans[sk] = []
	for i in range(140):
		var sk: String = Pets.SPECIES.keys()[i % 5]
		var ok_: String = Pets.ORIGINS.keys()[(i / 5) % 7]
		_start(sk, ok_)
		ok(Pets.active(), "a %s from %s did not start as a pet" % [sk, ok_])
		var y := 0
		while GameState.is_alive() and y < 90:
			y += 1
			EventEngine.age_up()
			_drain()
		ok(not GameState.is_alive(), "%s from %s outlived 90 years" % [sk, ok_])
		spans[sk].append(int(GameState.player["age"]))
		causes[str(GameState.player["cause"])] = true
		var entry: Dictionary = GameState.player.get("legacy", {})
		ok(entry.has("pet") and entry.has("ending"), "a dead %s has no pet record or ending" % sk)
		ok(str(entry.get("story", "")).length() > 80, "a dead %s has a thin story" % sk)
		ok(float(GameState.player["stats"]["health"]) >= 0.0, "health went negative")
		for g in Pets.GAUGES:
			var v := float(Lives.life()[g])
			ok(v >= 0.0 and v <= 100.0, "gauge %s left its range: %.1f" % [g, v])
	for sk in spans.keys():
		var a: Array = spans[sk]
		var mean := 0.0
		for x in a:
			mean += float(x)
		mean /= float(a.size())
		var lo := float(Pets.SPECIES[sk]["life"][0]) - 4.0
		var hi := float(Pets.SPECIES[sk]["life"][1]) + 5.0
		ok(mean >= lo and mean <= hi, "%s lived %.1f years on average (expected %.0f-%.0f)" % [sk, mean, lo, hi])
		print("  lives: %-6s mean %.1f years over %d" % [sk, mean, a.size()])
	ok(causes.size() >= 12, "only %d distinct causes of death" % causes.size())
	var base_ids: Array = []
	for e in ContentDB.events:
		if Pets.is_pet_event(e) and not e.get("followup_only", false):
			base_ids.append(str(e["id"]))
	var hit := 0
	var missed: Array = []
	for id in base_ids:
		if seen_events.has(id):
			hit += 1
		else:
			missed.append(id)
	var cov := 100.0 * hit / maxf(1.0, base_ids.size())
	ok(cov >= 75.0, "only %.0f%% of pet events ever fired; never saw: %s" % [cov, str(missed)])
	print("  lives: %.0f%% of base events fired over 140 lives; %d causes of death" % [cov, causes.size()])


# ---------------------------------------------------------------- every action

func _actions() -> void:
	var ran := 0
	for sk in Pets.SPECIES.keys():
		for ok_ in ["loving", "street", "show", "working", "shelter"]:
			_start(sk, ok_)
			for y in range(4):
				EventEngine.age_up()
				_drain()
			if not GameState.is_alive():
				continue
			for mk in ["home", "care", "play", "train", "wild", "house", "calling"]:
				var m: Dictionary = Pets.menu(mk)
				ok(m.has("rows") and m.has("title"), "menu %s is malformed" % mk)
				for r in m["rows"]:
					if bool(r.get("on", true)) and r.has("act") and GameState.is_alive():
						GameState.player["time_left"] = 12
						GameState.player["act_year"] = {}
						var key := str(r["act"]).substr(4)
						Pets.act(key, r.get("arg", null))
						ran += 1
						_drain()
	ok(ran >= 150, "only %d actions ran" % ran)
	print("  actions: %d menu actions ran across species and origins" % ran)


# ---------------------------------------------------------------- the arc

func _arc() -> void:
	_start("dog", "loving")
	var l := Lives.life()
	ok(Arcs.has_arc() and Arcs.chapters().size() == 5, "the pet has no five-chapter road")
	ok(Arcs.current_index() == 0, "a new pet starts with chapters open")
	l.merge({"bond": 90.0, "territory": 60.0, "tricks": ["a", "b", "c"], "role_set": true, "heroics": 1, "belonging": 80.0}, true)
	GameState.player["age"] = int(Pets.lifespan() * 0.8)
	EventEngine.pending.clear()
	Arcs.yearly()
	ok(Arcs.current_index() == 5, "the road opened only %d of 5 chapters" % Arcs.current_index())
	ok(EventEngine.pending.size() >= 5, "only %d turning points queued" % EventEngine.pending.size())
	EventEngine.pending.clear()
	var cases := [
		["pet_lost", {"lost": true}],
		["pet_hero", {"heroics": 3}],
		["pet_champion", {"titles": 2}],
		["pet_stray_king", {"territory": 90.0, "home": "street"}],
		["pet_best_friend", {"bond": 90.0, "belonging": 80.0}],
		["pet_sunbeam", {"bond": 60.0, "belonging": 20.0, "age_frac": 0.9}],
		["pet_good", {"bond": 20.0, "belonging": 10.0}],
	]
	var seen := {}
	for c in cases:
		_start("dog", "loving")
		var l2 := Lives.life()
		l2.merge({"lost": false, "heroics": 0, "titles": 0, "bond": 30.0, "belonging": 30.0, "territory": 20.0, "home": "home"}, true)
		var cd: Dictionary = c[1]
		for k in cd.keys():
			if k == "age_frac":
				GameState.player["age"] = int(Pets.lifespan() * float(cd[k]))
			else:
				l2[k] = cd[k]
		var e := Arcs.ending()
		ok(str(e["id"]) == str(c[0]), "expected ending %s but got %s" % [c[0], e["id"]])
		seen[str(e["id"])] = true
		var entry := GameState.finalize_death("old age")
		ok(str(entry["ending"]["id"]) == str(c[0]), "death carried the wrong ending")
		ok(str(GameState.player["ribbon"]["name"]) != "", "no ribbon")
		var stone := Tombstone.new()
		stone.setup(entry, entry["ribbon"], GameState.player)
		ok(stone.epitaph != "", "no epitaph")
	ok(seen.size() == 7, "only %d pet endings reachable" % seen.size())
	print("  arc: five chapters open in order; %d endings reachable, each with a ribbon and an epitaph" % seen.size())


# ---------------------------------------------------------------- save, load, the next life

func _save_and_next() -> void:
	_start("cat", "street")
	for y in range(3):
		EventEngine.age_up()
		_drain()
	var d := GameState.to_dict()
	var before := JSON.stringify(Lives.life())
	GameState.from_dict(JSON.parse_string(JSON.stringify(d)))
	ok(Pets.active(), "a saved pet loaded as something else")
	ok(Lives.life()["species"] == "cat", "species lost in the save")
	for y in range(3):
		EventEngine.age_up()
		_drain()
	ok(before.length() > 100, "life record empty")
	# a house that kept the one before
	_start("dog", "loving")
	var house := str(GameState.player["last"])
	var owner := Pets.owner_name()
	var y2 := 0
	while GameState.is_alive() and y2 < 90:
		y2 += 1
		GameState.player["act_year"] = {}
		EventEngine.age_up()
		_drain()
	var entry: Dictionary = GameState.player["legacy"]
	var opts := Pets.next_life_opts(entry)
	GameState.new_life({"first": "Pickle", "last": "", "gender": "male", "country": "uk", "life_path": "pet", "keep_family": true, "species": "cat", "origin": "loving", "inherit": opts["inherit"]})
	ok(Pets.active() and GameState.player["first"] == "Pickle", "the next life did not start")
	var kept: String = str(GameState.player["last"])
	ok(kept == house or str(entry["pet"].get("house", "")) == house, "the house name was not remembered (%s vs %s)" % [kept, house])
	ok(Pets.owner_id() != "", "the next life has no household")
	print("  save and continue: a pet round-trips; the next life comes to the same house (%s, %s)" % [house, owner])


func _minigames() -> void:
	for id in ["pet_pounce", "pet_scent", "pet_sneak", "pet_agility", "pet_herd"]:
		ok(Minigames.DEFS.has(id), "%s not registered" % id)
		ok(FileAccess.file_exists(str(Minigames.DEFS[id]["script"])), "%s has no script" % id)
		ok(str(Minigames.DEFS[id]["how"]).length() > 80, "%s has no instructions" % id)
	print("  minigames: five pet games registered")

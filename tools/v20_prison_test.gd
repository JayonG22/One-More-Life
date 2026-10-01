extends Node

## v1.2 gate — Prison Life: two roles, one building, its own events and endings.

var failures: Array = []
var checks := 0
var seen := {}


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V20: " + msg)


func _ready() -> void:
	seed(2020)
	_content()
	_roles()
	_isolation()
	_lives()
	_arcs()
	_break()
	_switch()
	_save()
	_minigames()
	print("V20 PRISON TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _start(role: String, story: String) -> void:
	GameState.new_life({"first": "Test", "last": "Person", "gender": "male", "country": "us", "life_path": role, "keep_family": true, "story": story})


func is_prison_event(def: Dictionary) -> bool:
	var lt = def.get("conditions", {}).get("life", null)
	if lt is Array:
		return Array(lt).has("prisoner") or Array(lt).has("guard")
	return str(lt) == "prisoner" or str(lt) == "guard"


func _drain(pick_first: bool = false) -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 60:
		guard += 1
		var inst: Dictionary = EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var def: Dictionary = inst["def"]
		seen[str(def["id"])] = true
		var r := EventEngine.resolve(inst, 0 if pick_first else randi() % def["choices"].size())
		ok(str(r.get("text", "")) != "", "%s gave no text" % def["id"])


# ---------------------------------------------------------------- library

func _content() -> void:
	var evs: Array = []
	for e in ContentDB.events:
		if is_prison_event(e):
			evs.append(e)
	ok(evs.size() >= 110, "only %d prison events" % evs.size())
	var ids := {}
	for e in evs:
		ids[str(e["id"])] = true
	var sched := 0
	var targets := {}
	var base := 0
	for e in evs:
		var id := str(e["id"])
		ok(e["choices"].size() >= 3, "%s has fewer than three choices" % id)
		var has_s := false
		for c in e["choices"]:
			ok(c["outcomes"].size() >= 2 or c.get("outcomes", []).size() >= 1 and false, "%s / %s has one outcome" % [id, c["label"]])
			for o in c["outcomes"]:
				ok(str(o["text"]).length() > 20, "%s has a thin outcome" % id)
				if o.has("schedule"):
					has_s = true
					targets[str(o["schedule"]["event"])] = true
					ok(ids.has(str(o["schedule"]["event"])), "%s schedules a missing event" % id)
				for k in (o.get("pr", {}) as Dictionary).keys():
					ok(Prison.OUTCOME_KEYS.has(str(k)) or Prison.NUM_FIELDS.has(str(k)), "%s uses an unknown pr key '%s'" % [id, k])
				if (o.get("pr", {}) as Dictionary).has("then"):
					ok(ids.has(str(o["pr"]["then"])), "%s chains to a missing event %s" % [id, o["pr"]["then"]])
				if o.has("play"):
					var pl: Dictionary = o["play"]
					ok(Minigames.DEFS.has(str(pl["id"])), "%s plays an unknown minigame" % id)
					ok(pl.has("win") and pl.has("lose") and Prison.handles(str(pl.get("kind", ""))), "%s has a malformed branch" % id)
		if not e.get("followup_only", false):
			base += 1
		if has_s:
			sched += 1
		for t in e["conditions"].get("pr", []):
			ok(Prison.known_tag(str(t)), "%s uses an unknown tag '%s'" % [id, t])
		for t2 in e["conditions"].get("not_pr", []):
			ok(Prison.known_tag(str(t2)), "%s uses an unknown not-tag '%s'" % [id, t2])
		var txt := JSON.stringify(e)
		for tok in ["{c.", "{off.", "{i.", "{law.", "{sup.", "{co."]:
			if txt.find(tok) != -1:
				var rolename: String = tok.substr(1, tok.length() - 2)
				ok(e.has("roles") and (e["roles"] as Dictionary).has(rolename), "%s names %s... with no such role" % [id, tok])
	var pct := 100.0 * sched / maxf(1.0, evs.size())
	ok(pct >= 22.0, "only %.1f%% of prison events lead to a follow-up" % pct)
	for role in ["prisoner", "guard"]:
		var n := 0
		for e in evs:
			var lt = e["conditions"]["life"]
			if str(lt) == role or (lt is Array and Array(lt).has(role)):
				n += 1
		ok(n >= 40, "%s has only %d events" % [role, n])
		for k in range(1, 6):
			ok(ContentDB.events_by_id.has("arc.%s.%d" % [role, k]), "arc.%s.%d missing" % [role, k])
	print("  content: %d events, %.1f%% with follow-ups" % [evs.size(), pct])


## Every role an event asks for must exist for the role it is written for.
func _roles() -> void:
	var bad := 0
	for role in ["prisoner", "guard"]:
		_start(role, "first" if role == "prisoner" else "career")
		for e in ContentDB.events:
			if not is_prison_event(e) or not e.has("roles"):
				continue
			var lt = e["conditions"]["life"]
			var applies: bool = str(lt) == role or (lt is Array and Array(lt).has(role))
			if not applies:
				continue
			var r := EventEngine._build_roles(e, {})
			if r.has("__fail"):
				bad += 1
				push_error("V20: %s cannot build its roles for a %s" % [e["id"], role])
	ok(bad == 0, "%d events ask for people the mode never creates" % bad)
	print("  roles: every event's people exist for its role")


# ---------------------------------------------------------------- isolation

func _isolation() -> void:
	var leaks := 0
	for i in range(10):
		GameState.new_life({"gender": "female", "country": "uk"})
		for y in range(35):
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			while EventEngine.has_pending():
				var inst: Dictionary = EventEngine.pop_next()
				if not inst.get("info", false):
					if is_prison_event(inst["def"]):
						leaks += 1
					EventEngine.resolve(inst, 0)
	ok(leaks == 0, "%d prison events reached a human" % leaks)
	var pet_leaks := 0
	for i in range(6):
		GameState.new_life({"first": "Biscuit", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": "dog", "origin": "loving"})
		for y in range(20):
			if not GameState.is_alive():
				break
			EventEngine.age_up()
			while EventEngine.has_pending():
				var inst2: Dictionary = EventEngine.pop_next()
				if not inst2.get("info", false):
					if is_prison_event(inst2["def"]):
						pet_leaks += 1
					EventEngine.resolve(inst2, 0)
	ok(pet_leaks == 0, "%d prison events reached a pet" % pet_leaks)
	# a prisoner meets only prisoner events; a guard only guard events
	var cross := 0
	for role in ["prisoner", "guard"]:
		for i in range(8):
			_start(role, "first" if role == "prisoner" else "career")
			for y in range(30):
				if not GameState.is_alive():
					break
				EventEngine.age_up()
				while EventEngine.has_pending():
					var inst3: Dictionary = EventEngine.pop_next()
					if inst3.get("info", false):
						continue
					var d3: Dictionary = inst3["def"]
					var lt = d3["conditions"].get("life", "")
					var mine: bool = str(lt) == Lives.kind() or (lt is Array and Array(lt).has(Lives.kind()))
					if not mine:
						cross += 1
						push_error("V20 cross: %s in a %s" % [d3["id"], Lives.kind()])
					seen[str(d3["id"])] = true
					EventEngine.resolve(inst3, randi() % d3["choices"].size())
	ok(cross == 0, "%d events reached the wrong role" % cross)
	print("  isolation: humans, pets, prisoners and guards each see only their own events")


# ---------------------------------------------------------------- whole lives

func _lives() -> void:
	var outcomes := {}
	var ends := {}
	var runs := 0
	for role in ["prisoner", "guard"]:
		var stories: Array = Prison.PRISONER_STORIES.keys() if role == "prisoner" else Prison.GUARD_STORIES.keys()
		for rep in range(6):
			for sk in stories:
				_start(role, sk)
				ok(Prison.active() and Lives.kind() == role, "a %s/%s did not start" % [role, sk])
				var y := 0
				while GameState.is_alive() and y < 80:
					y += 1
					EventEngine.age_up()
					_drain()
					if y % 3 == 0 and GameState.is_alive():
						_actions()
				ok(not GameState.is_alive(), "%s/%s never ended" % [role, sk])
				runs += 1
				var entry: Dictionary = GameState.player.get("legacy", {})
				ok(entry.has("mode") and entry.has("ending"), "a finished %s has no mode record or ending" % role)
				ok(str(entry.get("story", "")).length() > 80, "a finished %s has a thin story" % role)
				outcomes[str(Lives.life().get("outcome", "died"))] = true
				ends[str(entry.get("ending", {}).get("id", "?"))] = true
				for gk in ["respect", "heat", "conduct", "support", "merit", "integrity", "control"]:
					if Lives.life().has(gk):
						var v := float(Lives.life()[gk])
						ok(v >= 0.0 and v <= 100.0, "gauge %s out of range: %.1f" % [gk, v])
	ok(outcomes.size() >= 4, "only %d distinct outcomes in %d lives: %s" % [outcomes.size(), runs, str(outcomes.keys())])
	ok(ends.size() >= 5, "only %d distinct endings in %d lives: %s" % [ends.size(), runs, str(ends.keys())])
	var base_ids: Array = []
	for e in ContentDB.events:
		if is_prison_event(e) and not e.get("followup_only", false):
			base_ids.append(str(e["id"]))
	var hit := 0
	var missed: Array = []
	for id in base_ids:
		if seen.has(id):
			hit += 1
		else:
			missed.append(id)
	var cov := 100.0 * hit / maxf(1.0, base_ids.size())
	ok(cov >= 65.0, "only %.0f%% of base prison events ever fired; never saw: %s" % [cov, str(missed)])
	print("  lives: %d lives, outcomes %s, %d endings, %.0f%% of base events fired" % [runs, str(outcomes.keys()), ends.size(), cov])


## Run a couple of menu actions so the year is not just waiting.
func _actions() -> void:
	for mk in ["routine", "hustle", "people", "case", "post", "block", "career", "integrity", "plan", "gang"]:
		var m: Dictionary = Prison.menu(mk)
		var done := 0
		for r in m["rows"]:
			if bool(r.get("on", true)) and r.has("act") and GameState.is_alive() and done < 2:
				GameState.player["time_left"] = 12
				GameState.player["act_year"] = {}
				Prison.act(str(r["act"]).substr(3), r.get("arg", null))
				_drain()
				done += 1


# ---------------------------------------------------------------- the road

func _arcs() -> void:
	for role in ["prisoner", "guard"]:
		_start(role, "first" if role == "prisoner" else "career")
		ok(Arcs.has_arc() and Arcs.chapters().size() == 5, "%s has no five-chapter road" % role)
		ok(Arcs.current_index() == 0, "a new %s starts with chapters open" % role)
	_start("prisoner", "first")
	var l := Lives.life()
	l.merge({"served": 3, "gang_rank": 2, "respect": 50.0, "programs": ["ged"], "riots": 1, "hearings": 1}, true)
	EventEngine.pending.clear()
	Arcs.yearly()
	ok(Arcs.current_index() == 5, "the prisoner's road opened only %d of 5" % Arcs.current_index())
	ok(EventEngine.pending.size() >= 5, "only %d prisoner turning points queued" % EventEngine.pending.size())
	EventEngine.pending.clear()
	_start("guard", "career")
	var g := Lives.life()
	g.merge({"served": 16, "incidents": 2, "commend": 1, "rank": 5}, true)
	Arcs.yearly()
	ok(Arcs.current_index() == 5, "the guard's road opened only %d of 5" % Arcs.current_index())
	EventEngine.pending.clear()
	var cases := [
		["prisoner", "pr_exonerated", {"exonerated": true}],
		["prisoner", "pr_ghost", {"escaped": true}],
		["prisoner", "pr_fallen", {"ex_guard": true}],
		["prisoner", "pr_paroled", {"outcome": "paroled"}],
		["prisoner", "pr_served", {"outcome": "served"}],
		["prisoner", "pr_legend", {"respect": 90.0}],
		["prisoner", "pr_died", {}],
		["guard", "gd_warden", {"outcome": "warden"}],
		["guard", "gd_whistle", {"whistle": true}],
		["guard", "gd_kingpin", {"corruption": 6}],
		["guard", "gd_hero", {"commend": 3}],
		["guard", "gd_fired", {"outcome": "fired"}],
		["guard", "gd_burned", {"trauma": 90.0}],
		["guard", "gd_retired", {"outcome": "retired"}],
		["guard", "gd_duty", {}],
	]
	var got := {}
	for c in cases:
		_start(str(c[0]), "first" if str(c[0]) == "prisoner" else "career")
		var l2 := Lives.life()
		l2.merge({"exonerated": false, "escaped": false, "ex_guard": false, "outcome": "", "respect": 10.0, "whistle": false, "corruption": 0, "commend": 0, "trauma": 5.0}, true)
		l2.merge(c[2], true)
		var e := Arcs.ending()
		ok(str(e["id"]) == str(c[1]), "expected %s, got %s" % [c[1], e["id"]])
		got[str(e["id"])] = true
		var entry := GameState.finalize_death("old age")
		ok(str(entry.get("ending", {}).get("id", "")) == str(c[1]), "death carried the wrong ending")
		ok(str(GameState.player["ribbon"]["name"]) != "", "no ribbon")
		var stone := Tombstone.new()
		stone.setup(entry, entry["ribbon"], GameState.player)
		ok(stone.epitaph != "", "no epitaph")
	ok(got.size() == 15, "only %d prison endings reachable" % got.size())
	print("  arcs: two roads of five chapters; %d endings reachable" % got.size())


# ---------------------------------------------------------------- the break

func _break() -> void:
	var escaped := 0
	var caught := 0
	var ghosts := 0
	for i in range(40):
		_start("prisoner", "career")
		var l := Lives.life()
		l["escape"] = 5
		l["crew"] = []
		GameState.player["time_left"] = 12
		Prison.act("breakout", null)
		_drain()
		if bool(l.get("fugitive", false)):
			escaped += 1
			ok(float(l["heat"]) > 50.0, "a fugitive starts without heat")
			var y := 0
			while GameState.is_alive() and bool(Lives.life().get("fugitive", false)) and y < 12:
				y += 1
				EventEngine.age_up()
				_drain()
			if not GameState.is_alive() and bool(Lives.life().get("escaped", false)):
				ghosts += 1
			elif bool(Lives.life().get("caught", false)):
				caught += 1
		else:
			ok(int(l.get("sentence", 0)) > 0, "a failed break lost the sentence")
	ok(escaped > 0, "no break ever got out in 40 tries")
	ok(ghosts > 0 or caught > 0, "no manhunt ever resolved")
	print("  the break: %d of 40 got out; %d lived as ghosts, %d were brought back" % [escaped, ghosts, caught])


func _switch() -> void:
	_start("guard", "desperate")
	var l := Lives.life()
	l["corruption"] = 4
	Prison.switch_to_prisoner("convicted")
	ok(Lives.kind() == "prisoner" and bool(Lives.life().get("ex_guard", false)), "a convicted guard did not become an ex-guard prisoner")
	ok(Prison.is_prisoner() and Prison.remaining() > 0, "the fallen guard has no sentence")
	for gk in Prison.GANGS.keys():
		ok(float(Lives.life()["rep"].get(gk, 0)) < 0.0, "a fallen guard is not hated by %s" % gk)
	EventEngine.pending.clear()
	for y in range(12):
		if not GameState.is_alive():
			break
		EventEngine.age_up()
		_drain()
	print("  switch: the guard who became a prisoner plays out")


func _save() -> void:
	for role in ["prisoner", "guard"]:
		_start(role, "gang" if role == "prisoner" else "military")
		for y in range(4):
			EventEngine.age_up()
			_drain()
		var card := SaveManager._card_from(GameState.to_dict())
		ok(card.has("portrait") and card.get("hide_money", false) and str(card.get("place", "")) != "" and str(card.get("occupation", "")) != "", "the %s save card is still a human one: %s" % [role, str(card)])
		var before := str(Lives.life()["fac"]["name"]) + str(int(Lives.life()["fac"]["tension"]))
		var d := GameState.to_dict()
		GameState.from_dict(JSON.parse_string(JSON.stringify(d)))
		ok(Prison.active() and Lives.kind() == role, "a saved %s loaded as something else" % role)
		ok(str(Lives.life()["fac"]["name"]) + str(int(Lives.life()["fac"]["tension"])) == before, "the facility changed in the save")
		for y in range(3):
			if GameState.is_alive():
				EventEngine.age_up()
				_drain()
	print("  save: prisoner and guard round-trip")


func _minigames() -> void:
	for id in ["pr_parole", "pr_shakedown", "pr_standoff"]:
		ok(Minigames.DEFS.has(id), "%s not registered" % id)
		ok(FileAccess.file_exists(str(Minigames.DEFS[id]["script"])), "%s has no script" % id)
		ok(str(Minigames.DEFS[id]["how"]).length() > 80, "%s has no instructions" % id)
	print("  minigames: three prison games registered")

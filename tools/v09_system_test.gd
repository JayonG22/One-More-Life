extends Node

## v0.9 gate. Proves each new system does something observable, not that its
## menu opens. Same standard as the v0.8 echo test.
## godot --headless --path . res://tools/v09_system_test.tscn

var failures: Array = []
var checks := 0
var completed: Array = []


func fail(msg: String) -> void:
	failures.append(msg)
	push_error("V09: " + msg)


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fail(msg)


func life(country: String = "us", age: int = 30) -> void:
	GameState.new_life({"country": country})
	GameState.player["age"] = age
	GameState.player["money"] = 250000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	Expansion.ensure()
	LifeThreads.ensure()
	Ambition.ensure()


# ------------------------------------------------------------- friction
func test_friction_responds_to_the_person() -> void:
	var choice := {"outcomes": [{"text": "x"}]}
	var outcome := {"text": "x", "effects": {"happiness": 6, "money": 400}}
	var rates := {}
	for label in ["capable", "struggling"]:
		life()
		if label == "capable":
			GameState.player["stats"] = {"health": 90.0, "smarts": 90.0, "looks": 70.0, "happiness": 85.0, "stress": 8.0}
			GameState.player["karma"] = 50
		else:
			GameState.player["stats"] = {"health": 28.0, "smarts": 30.0, "looks": 35.0, "happiness": 18.0, "stress": 85.0}
			GameState.player["karma"] = -50
		var clean := 0
		for i in range(1500):
			if Friction.roll(choice, outcome, {}) == "clean":
				clean += 1
		rates[label] = float(clean) / 1500.0
	ok(rates["capable"] > rates["struggling"] + 0.3, "who the character is barely changed how often things land (%.2f vs %.2f)" % [rates["capable"], rates["struggling"]])
	ok(rates["capable"] > 0.75, "a capable, calm, well-liked character should mostly succeed (got %.2f)" % rates["capable"])
	ok(rates["struggling"] < 0.45, "a character in crisis should not breeze through (got %.2f)" % rates["struggling"])
	completed.append("friction_person")


func test_friction_scales_with_difficulty() -> void:
	var out := {}
	for diff in ["classic", "real", "gritty"]:
		life()
		GameState.player["difficulty"] = diff
		GameState.player["stats"] = {"health": 60.0, "smarts": 55.0, "looks": 55.0, "happiness": 60.0, "stress": 25.0}
		var clean := 0
		for i in range(1500):
			if Friction.roll({"outcomes": [{"text": "x"}]}, {"text": "x", "effects": {"happiness": 6}}, {}) == "clean":
				clean += 1
		out[diff] = float(clean) / 1500.0
	ok(out["classic"] > out["real"] and out["real"] > out["gritty"], "difficulty did not order the outcomes (%.2f / %.2f / %.2f)" % [out["classic"], out["real"], out["gritty"]])
	completed.append("friction_difficulty")


func test_friction_never_punishes_an_already_bad_outcome() -> void:
	life()
	var bad := {"text": "x", "effects": {"happiness": -10, "stress": 12}}
	ok(not Friction.applies({"outcomes": [bad]}, bad, {}), "friction piled onto an outcome the author already made bad")
	var nothing := {"text": "Shadow is family now.", "effects": {}}
	ok(not Friction.applies({"outcomes": [nothing]}, nothing, {}), "friction fired on an outcome with no gain to take away")
	completed.append("friction_guards")


# ------------------------------------------------------------- currency & units
func test_currency_follows_the_country() -> void:
	var seen := {}
	for c in ["us", "jp", "ng", "de"]:
		life(c)
		var cur := GameState.currency()
		seen[c] = GameState.fmt_money(52000)
		ok(str(cur["code"]) != "", "no currency code for %s" % c)
	ok(seen["us"] != seen["jp"] and seen["jp"] != seen["ng"], "different countries produced the same money string")
	ok(str(seen["de"]).ends_with("€"), "Germany should write the symbol after the number, got %s" % seen["de"])
	life("us")
	ok(GameState.fmt_money(-500).begins_with("-"), "negative money lost its sign")
	completed.append("currency")


func test_units_toggle() -> void:
	GameState.settings["units"] = "metric"
	var m := Units.temperature(30.0)
	var mw := Units.weight(80.0)
	GameState.settings["units"] = "imperial"
	var i := Units.temperature(30.0)
	var iw := Units.weight(80.0)
	GameState.settings["units"] = "metric"
	ok(m != i and m.ends_with("C") and i.ends_with("F"), "temperature did not follow the unit setting (%s / %s)" % [m, i])
	ok(mw != iw, "weight did not follow the unit setting (%s / %s)" % [mw, iw])
	completed.append("units")


func test_every_country_has_names_and_currency() -> void:
	for c in ContentDB.countries:
		var cid: String = c["id"]
		ok(ContentDB.names["buckets"].has(str(c["bucket"])), "country %s points at name bucket '%s' which does not exist" % [cid, c["bucket"]])
		ok(str(c.get("currency", "")) != "" and float(c.get("rate", 0.0)) > 0.0, "country %s has no usable currency" % cid)
	completed.append("country_data")


# ------------------------------------------------------------- licences
func test_licence_banks() -> void:
	ok(not ContentDB.licenses.is_empty(), "no licence question banks loaded")
	for key in ContentDB.licenses.keys():
		var spec: Dictionary = ContentDB.licenses[key]
		var bank: Array = spec.get("bank", [])
		ok(bank.size() >= int(spec.get("needed", 5)), "licence '%s' asks more questions than it has" % key)
		for q in bank:
			var opts: Array = q.get("a", [])
			ok(opts.size() >= 2, "a '%s' question has fewer than two options" % key)
			ok(int(q.get("correct", -1)) >= 0 and int(q["correct"]) < opts.size(), "a '%s' question has an out-of-range answer" % key)
			ok(str(q.get("why", "")) != "", "a '%s' question has no explanation, so it teaches nothing" % key)
	completed.append("licence_banks")


func test_licence_is_obtainable_without_minigames() -> void:
	var got := 0
	for attempt in range(40):
		life("us", 18)
		GameState.player["stats"]["smarts"] = 85.0
		Law.take_test("driver")
		if Law.has_license("driver"):
			got += 1
	ok(got > 10, "a smart character could almost never get a licence with minigames off (%d of 40)" % got)
	completed.append("licence_auto")


# ------------------------------------------------------------- gating
func test_doctor_needs_a_reason() -> void:
	life()
	GameState.player["stats"]["health"] = 95.0
	GameState.player["last_checkup_age"] = 29
	ok(Actions.doctor_reason() == "", "a healthy character with a recent checkup still had a reason to see a doctor")
	GameState.player["illness"] = "flu"
	ok(Actions.doctor_reason() != "", "being ill was not a reason to see a doctor")
	GameState.player["illness"] = ""
	GameState.player["last_checkup_age"] = 10
	ok(Actions.doctor_reason() != "", "being years overdue was not a reason to see a doctor")
	completed.append("doctor_gate")


func test_durations_trade_time_for_reward() -> void:
	for id in ["walk", "gym", "library"]:
		var opts: Array = Actions.duration_choices(id)
		ok(opts.size() >= 3, "'%s' has fewer than three lengths to choose from" % id)
		var prev_time := 0
		var prev_mult := 0.0
		for o in opts:
			ok(int(o[1]) >= prev_time, "'%s' lengths are not ordered by time cost" % id)
			ok(float(o[2]) > prev_mult, "'%s' lengths do not increase in reward" % id)
			prev_time = int(o[1])
			prev_mult = float(o[2])
		# The longest option must not be a straight multiple of the shortest.
		var first: Array = opts[0]
		var last: Array = opts[-1]
		var time_ratio := float(last[1]) / maxf(1.0, float(first[1]))
		var reward_ratio := float(last[2]) / maxf(0.01, float(first[2]))
		ok(reward_ratio < time_ratio * 1.6, "'%s' gives near-linear returns, so length is a free win" % id)
	completed.append("durations")


func test_convenience_must_be_earned() -> void:
	life("us", 35)
	ok(not bool(Actions.batch_state()["ok"]), "the batch action was available from the very start")
	for i in range(6):
		GameState.create_npc("friend", {"age": 35, "closeness": 60})
	for i in range(10):
		GameState.counter("spend_time")
	ok(bool(Actions.batch_state()["ok"]), "the batch action never unlocked despite meeting every condition")
	GameState.player["difficulty"] = "gritty"
	ok(not bool(Actions.batch_state()["ok"]), "Gritty did not strip the convenience away")
	completed.append("earned_convenience")


# ------------------------------------------------------------- climate
func test_every_region_has_a_climate() -> void:
	var n := 0
	for c in ContentDB.countries:
		for r in Places.regions(str(c["id"])):
			n += 1
			ok(Climate.REGION_CLIMATE.has(str(r["id"])), "region '%s' has no climate, so its weather is a guess" % r["id"])
	ok(n >= 40, "only %d regions exist; place is supposed to matter" % n)
	completed.append("climate_coverage")


func test_climate_differs_by_place() -> void:
	life("us")
	GameState.player["region"] = "nv"
	var desert := Climate.climate_id()
	life("jp")
	GameState.player["region"] = "hok"
	var snow := Climate.climate_id()
	ok(desert != snow, "a desert and a snow city resolved to the same climate")
	ok(float(Climate.CLIMATES[desert]["summer"]) > float(Climate.CLIMATES[snow]["summer"]), "the desert was not hotter in summer than Hokkaido")
	ok(float(Climate.CLIMATES[snow]["winter"]) < 0.0, "Hokkaido winters were not below freezing")
	completed.append("climate_place")


func test_climate_costs_money() -> void:
	life("ca", 40)
	GameState.player["region"] = "ab"
	var before := int(GameState.player["money"])
	for y in range(12):
		Climate.yearly()
	ok(int(GameState.player["money"]) < before, "twelve years in a cold-continental climate cost nothing")
	completed.append("climate_cost")


# ------------------------------------------------------------- NPCs & deeds
func test_npcs_have_stats() -> void:
	life()
	var id := GameState.create_npc("friend", {"age": 22, "closeness": 60})
	var n := GameState.npc(id)
	for k in ["health", "smarts", "happiness", "looks"]:
		ok(n.has(k), "a new NPC has no '%s'" % k)
	var h0 := int(n["health"])
	for y in range(50):
		n["age"] = int(n["age"]) + 1
		EventEngine._npc_stats_drift(n)
	ok(int(n["health"]) < h0, "an NPC aged fifty years without their health moving")
	ok(Bonds.stat_line(id) != "", "an NPC's stats do not render anywhere")
	completed.append("npc_stats")


func test_deeds_change_the_world_not_just_stats() -> void:
	life("us", 25)
	GameState.player["karma"] = 85
	GameState.player["possessions"] = []
	var money0 := int(GameState.player["money"])
	for y in range(30):
		GameState.player["age"] = 25 + y
		GameState.player["karma"] = 85
		Deeds.yearly()
	var good_items: int = (GameState.player["possessions"] as Array).size()

	life("us", 25)
	GameState.player["karma"] = -85
	GameState.player["possessions"] = [{"name": "A clock", "value": 500, "bought": 500, "icon": "🕰️", "cat": "x"}, {"name": "A bike", "value": 300, "bought": 300, "icon": "🚲", "cat": "x"}]
	for y in range(30):
		GameState.player["age"] = 25 + y
		GameState.player["karma"] = -85
		Deeds.yearly()
	var bad_items: int = (GameState.player["possessions"] as Array).size()
	ok(good_items > 0, "thirty years of kindness produced nothing you could hold")
	ok(bad_items <= 2, "thirty years of cruelty cost nothing material")
	completed.append("deeds")


# ------------------------------------------------------------- shopping
func test_brands_change_price_and_durability() -> void:
	life("us", 30)
	GameState.player["money"] = 5000000
	GameState.player["possessions"] = []
	Shop.act("buy_version", ["jeweler", 6, "solid", 0])
	Shop.act("buy_version", ["jeweler", 6, "bespoke", 1])
	var items: Array = GameState.player["possessions"]
	ok(items.size() == 2, "the two purchases did not both land")
	var cheap: Dictionary = items[0]
	var dear: Dictionary = items[1]
	ok(int(dear["bought"]) > int(cheap["bought"]) * 3, "the bespoke house was not meaningfully dearer")
	ok(str(dear["name"]) != str(cheap["name"]), "both versions came out with the same name")
	ok(int(dear.get("run", 0)) > 0 and int(dear.get("serial", 0)) > 0, "the numbered edition has no production run or serial")
	ok(str(dear.get("story", "")) != "", "a heritage purchase carries no provenance")
	completed.append("brands")


func _ready() -> void:
	seed(9090)
	test_friction_responds_to_the_person()
	test_friction_scales_with_difficulty()
	test_friction_never_punishes_an_already_bad_outcome()
	test_currency_follows_the_country()
	test_units_toggle()
	test_every_country_has_names_and_currency()
	test_licence_banks()
	test_licence_is_obtainable_without_minigames()
	test_doctor_needs_a_reason()
	test_durations_trade_time_for_reward()
	test_convenience_must_be_earned()
	test_every_region_has_a_climate()
	test_climate_differs_by_place()
	test_climate_costs_money()
	test_npcs_have_stats()
	test_deeds_change_the_world_not_just_stats()
	test_brands_change_price_and_durability()
	var expected := ["friction_person", "friction_difficulty", "friction_guards", "currency", "units",
		"country_data", "licence_banks", "licence_auto", "doctor_gate", "durations", "earned_convenience",
		"climate_coverage", "climate_place", "climate_cost", "npc_stats", "deeds", "brands"]
	for name in expected:
		if not completed.has(name):
			fail("section '%s' aborted before finishing (runtime error above)" % name)
	print("V09 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), expected.size(), failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

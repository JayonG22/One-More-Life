extends Node

## v0.11 gate — the deepened vampire and undead lives.
## godot --headless --path . res://tools/v11_system_test.tscn

var failures: Array = []
var checks := 0
var completed: Array = []


func fail(msg: String) -> void:
	failures.append(msg)
	push_error("V11: " + msg)


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fail(msg)


func vamp(age: int = 30) -> Dictionary:
	GameState.new_life({"country": "us"})
	GameState.player["age"] = age
	GameState.player["money"] = 500000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	Lives.become("vampire")
	return Undeath.ensure_vampire()


func rev(age: int = 35) -> Dictionary:
	GameState.new_life({"country": "us"})
	GameState.player["age"] = age
	GameState.player["money"] = 500000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	# The undead life begins by rising after death, not by picking it.
	GameState.player["alive"] = false
	Lives.rise()
	return Undeath.ensure_revenant()


func reset_time() -> void:
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	GameState.interacted.clear()


# ---------------------------------------------------------------- vampire
func test_vampire_has_things_to_do() -> void:
	vamp()
	var base := Lives.vampire_actions().size()
	var total := Lives.actions().size()
	ok(total > base, "the deepened vampire actions are not reaching the menu")
	ok(total >= 11, "a vampire still has only %d things to do" % total)
	completed.append("vamp_actions")


func test_clans_are_real_choices() -> void:
	ok(Undeath.CLANS.size() >= 4, "fewer than four clans")
	for key in Undeath.CLANS.keys():
		var c: Dictionary = Undeath.CLANS[key]
		ok(str(c.get("creed", "")) != "" and str(c.get("boon", "")) != "" and str(c.get("cost", "")) != "",
			"clan '%s' has no creed, upside or cost, so it is a label" % key)
	# The clan must change how the life plays, not just what it is called.
	var l := vamp()
	Undeath.outcome({"kind": "join_clan", "clan": "veil"})
	ok(str(l["clan"]) == "veil", "joining a clan did not stick")
	ok(float(l["standing"]) > 10.0, "joining a clan gave no standing")
	completed.append("clans")


func test_rank_is_earned_over_decades() -> void:
	var l := vamp(25)
	ok(Undeath.rank_name() == "Fledgling", "a new vampire did not start as a Fledgling")
	l["standing"] = 100.0
	Undeath._check_rise()
	ok(Undeath.rank_name() == "Fledgling", "standing alone promoted a vampire with no years behind them")
	GameState.player["age"] = 25 + 50
	Undeath._check_rise()
	ok(Undeath.rank_name() != "Fledgling", "fifty years and full standing produced no rise")
	GameState.player["age"] = 25 + 200
	Undeath._check_rise()
	Undeath._check_rise()
	ok(Undeath.rank_name() == "Lord", "two centuries at full standing never reached Lord (got %s)" % Undeath.rank_name())
	completed.append("rank")


func test_sire_exists_and_judges_you() -> void:
	vamp()
	var sid := Undeath.sire_id()
	ok(sid != "" and GameState.npcs.has(sid), "a vampire has no sire")
	ok(bool(GameState.npc(sid).get("vampire", false)), "the sire is not marked as a vampire")
	ok(Undeath.sire_id() == sid, "asking twice produced two different sires")
	completed.append("sire")


func test_hunter_builds_a_case() -> void:
	var l := vamp(30)
	Undeath._hunter_start()
	var h := Undeath.hunter()
	ok(not h.is_empty() and GameState.npcs.has(str(h["id"])), "the hunter was not created as a real person")
	var e0 := float(h["evidence"])
	for y in range(6):
		GameState.player["age"] = 30 + y
		Undeath._hunter_yearly()
	ok(float(Undeath.hunter().get("evidence", 0.0)) > e0, "six years passed and the hunter learned nothing")
	# Discipline has to be able to push the case back.
	var before := float(Undeath.hunter()["evidence"])
	l["discipline"] = 100.0
	reset_time()
	Undeath.vampire_extra("vx_cover")
	ok(float(Undeath.hunter()["evidence"]) < before, "covering your tracks did not weaken the case")
	completed.append("hunter")


func test_clan_changes_how_fast_you_are_found() -> void:
	var rates := {}
	for clan in ["veil", "crimson"]:
		var l := vamp(30)
		l["clan"] = clan
		Undeath._hunter_start()
		for y in range(8):
			GameState.player["age"] = 30 + y
			Undeath._hunter_yearly()
		rates[clan] = float(Undeath.hunter().get("evidence", 100.0))
	ok(rates["veil"] < rates["crimson"], "the Veil is not harder to catch than the Crimson Court (%.0f vs %.0f)" % [rates["veil"], rates["crimson"]])
	completed.append("clan_effect")


func test_hunter_can_end_several_ways() -> void:
	vamp()
	Undeath._hunter_start()
	var hid := str(Undeath.hunter()["id"])
	Undeath.outcome({"kind": "hunter_truce"})
	ok(Undeath.hunter().is_empty(), "a truce did not close out the hunt")
	ok(GameState.npc(hid).get("relation", "") == "friend", "the hunter who stopped is not a person in your life afterwards")

	vamp()
	Undeath._hunter_start()
	var hid2 := str(Undeath.hunter()["id"])
	Undeath.outcome({"kind": "hunter_killed"})
	ok(not GameState.npc(hid2).get("alive", true), "killing the hunter left them alive")
	ok(Undeath.hunter().is_empty(), "killing the hunter did not close the hunt")
	completed.append("hunter_ends")


# ---------------------------------------------------------------- undead
func test_undead_has_things_to_do() -> void:
	rev()
	var base := Lives.revenant_actions().size()
	var total := Lives.actions().size()
	ok(total > base, "the deepened undead actions are not reaching the menu")
	ok(total >= 6, "an undead still has only %d things to do" % total)
	completed.append("rev_actions")


func test_parts_fall_off_and_can_be_replaced() -> void:
	var l := rev()
	ok(Undeath.lost_parts().is_empty(), "a fresh revenant is already missing pieces")
	Undeath._lose_part()
	ok(Undeath.lost_parts().size() == 1, "losing a part did not register")
	var key: String = Undeath.lost_parts()[0]
	ok(Undeath.PARTS.has(key), "an unknown body part was lost")
	GameState.player["money"] = 500000
	reset_time()
	Undeath.revenant_extra("rx_parts")
	ok(Undeath.lost_parts().is_empty(), "paying for a replacement did not restore the part")
	completed.append("parts")


func test_crypt_slows_the_rot() -> void:
	var fast := rev()
	fast["crypt"] = 0
	fast["disguise"] = 100.0
	for y in range(6):
		GameState.player["age"] = 35 + y
		Undeath.yearly()
	var cheap := float(fast["disguise"])

	var slow := rev()
	slow["crypt"] = 3
	slow["disguise"] = 100.0
	for y in range(6):
		GameState.player["age"] = 35 + y
		Undeath.yearly()
	var vault := float(slow["disguise"])
	ok(vault > cheap, "a private vault preserved you no better than a culvert (%.0f vs %.0f)" % [vault, cheap])
	ok(Undeath.CRYPT.size() >= 4, "fewer than four places to sleep")
	completed.append("crypt")


func test_necromancer_binds_and_can_be_broken() -> void:
	var l := rev()
	var mid := Undeath.master_id()
	ok(mid != "" and GameState.npcs.has(mid), "an undead has no necromancer")
	var b0 := float(l["bound"])
	Undeath.outcome({"kind": "order_done", "value": 8.0})
	ok(float(l["bound"]) > b0, "obeying an order did not tighten the binding")
	for i in range(12):
		Undeath.outcome({"kind": "order_refused"})
	ok(float(l["bound"]) < b0, "refusing twelve orders did not loosen the binding")

	l["bound"] = 0.0
	l["crypt"] = 3
	var freed := false
	for attempt in range(40):
		var l2 := rev()
		l2["bound"] = 0.0
		l2["crypt"] = 3
		Undeath.master_id()
		reset_time()
		Undeath.revenant_extra("rx_free")
		if bool(l2.get("free", false)):
			freed = true
			break
	ok(freed, "breaking the binding never succeeded in forty attempts at the best odds")
	completed.append("necromancer")


func test_both_lives_report_their_state() -> void:
	vamp()
	ok(not Undeath.status_lines().is_empty(), "a vampire's state is invisible in the info panel")
	ok(not Lives.status_lines().is_empty(), "the vampire lines never reach Lives.status_lines()")
	rev()
	ok(not Undeath.status_lines().is_empty(), "an undead's state is invisible in the info panel")
	completed.append("status")


func test_no_crosstalk_between_lives() -> void:
	GameState.new_life({"country": "us"})
	GameState.player["age"] = 30
	ok(Undeath.ensure_vampire().is_empty(), "an ordinary human got vampire state")
	ok(Undeath.ensure_revenant().is_empty(), "an ordinary human got revenant state")
	ok(Undeath.vampire_extra_actions().is_empty(), "an ordinary human was offered vampire actions")
	ok(Undeath.revenant_extra_actions().is_empty(), "an ordinary human was offered undead actions")
	ok(Undeath.status_lines().is_empty(), "an ordinary human shows undead status lines")
	completed.append("isolation")


# ---------------------------------------------------------------- destiny
func test_the_picker_is_gone() -> void:
	var src := FileAccess.get_file_as_string("res://scenes/main.gd")
	ok(src.find("nl[\"path\"] = lkeys[idx]") < 0, "the new-life screen still lets you pick a life path")
	ok(src.find("Everyone starts ordinary") >= 0, "the new-life screen does not explain that paths are found, not chosen")
	completed.append("no_picker")


func test_an_ordinary_life_stays_ordinary() -> void:
	var drifted := 0
	for run in range(25):
		GameState.new_life({"country": "us"})
		for y in range(70):
			GameState.player["age"] = y
			Destiny.yearly()
		if Lives.kind() != "human":
			drifted += 1
	ok(drifted == 0, "%d of 25 lives that did nothing unusual still became something supernatural" % drifted)
	completed.append("ordinary_stays")


func test_behaviour_leads_somewhere() -> void:
	var reached := 0
	for run in range(25):
		GameState.new_life({"country": "us"})
		for y in range(70):
			GameState.player["age"] = y
			if y >= 18:
				Destiny.on_activity("nightlife")
				Destiny.on_activity("library")
			Destiny.yearly()
			while EventEngine.has_pending():
				var inst := EventEngine.pop_next()
				if inst.get("info", false):
					continue
				if not (inst["def"].get("choices", []) as Array).is_empty():
					EventEngine.resolve(inst, 0)
			if Lives.kind() != "human":
				reached += 1
				break
	ok(reached >= 12, "only %d of 25 lives spent in bars and the occult section found anything" % reached)
	completed.append("leads_work")


func test_declining_is_final() -> void:
	GameState.new_life({"country": "us"})
	GameState.player["age"] = 30
	Destiny.outcome({"decline": "vampire"})
	for y in range(40):
		GameState.player["age"] = 30 + y
		Destiny.add("vampire", 5)
		Destiny.yearly()
	ok(Lives.kind() == "human", "a path that was turned down came back anyway")
	ok(Destiny.lead("vampire") == 0, "declining did not clear the lead")
	completed.append("decline")


func test_every_path_can_be_entered() -> void:
	for path in Destiny.PATHS.keys():
		ok(Destiny.OFFERS.has(path), "path '%s' has no written offer, so it can never be reached" % path)
		var d: Array = Destiny.OFFERS[path]
		ok(str(d[2]) != "" and str(d[3]) != "" and str(d[4]) != "", "path '%s' has an incomplete offer" % path)
	ok(Destiny.PATHS.size() >= 8, "fewer than eight reachable life paths")
	# Taking each one must actually change the life.
	for path in ["vampire", "witch", "super", "royal", "pirate", "colonist", "traveler"]:
		GameState.new_life({"country": "us"})
		GameState.player["age"] = 30
		Destiny.outcome({"take": path})
		ok(Lives.kind() != "human", "taking '%s' left the character an ordinary human" % path)
	completed.append("all_paths")


func _ready() -> void:
	seed(1111)
	test_the_picker_is_gone()
	test_an_ordinary_life_stays_ordinary()
	test_behaviour_leads_somewhere()
	test_declining_is_final()
	test_every_path_can_be_entered()
	test_vampire_has_things_to_do()
	test_clans_are_real_choices()
	test_rank_is_earned_over_decades()
	test_sire_exists_and_judges_you()
	test_hunter_builds_a_case()
	test_clan_changes_how_fast_you_are_found()
	test_hunter_can_end_several_ways()
	test_undead_has_things_to_do()
	test_parts_fall_off_and_can_be_replaced()
	test_crypt_slows_the_rot()
	test_necromancer_binds_and_can_be_broken()
	test_both_lives_report_their_state()
	test_no_crosstalk_between_lives()
	var expected := ["vamp_actions", "clans", "rank", "sire", "hunter", "clan_effect", "hunter_ends",
		"rev_actions", "parts", "crypt", "necromancer", "status", "isolation",
		"no_picker", "ordinary_stays", "leads_work", "decline", "all_paths"]
	for name in expected:
		if not completed.has(name):
			fail("section '%s' aborted before finishing (runtime error above)" % name)
	print("V11 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), expected.size(), failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

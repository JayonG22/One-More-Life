extends Node

## v0.10 gate — the bond model.
## godot --headless --path . res://tools/v10_system_test.tscn

var failures: Array = []
var checks := 0
var completed: Array = []


func fail(msg: String) -> void:
	failures.append(msg)
	push_error("V10: " + msg)


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fail(msg)


func life(age: int = 30) -> void:
	GameState.new_life({"country": "us"})
	GameState.player["age"] = age
	GameState.player["money"] = 200000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR


func test_bond_exists_and_seeds_from_closeness() -> void:
	life()
	var warm := GameState.create_npc("friend", {"age": 30, "closeness": 90})
	var cold := GameState.create_npc("friend", {"age": 30, "closeness": 10})
	ok(BondStats.get_stat(warm, "affection") > BondStats.get_stat(cold, "affection"), "a warm bond did not seed higher affection than a cold one")
	ok(not BondStats.ensure(warm).is_empty(), "no bond record was created")
	completed.append("seed")


func test_profiles_differ_by_relation() -> void:
	life()
	var partner := GameState.create_npc("partner", {"age": 30, "closeness": 70})
	var boss := GameState.create_npc("boss", {"age": 50, "closeness": 50})
	var pet := GameState.create_npc("pet", {"species": "dog", "age": 3, "closeness": 80})
	ok(BondStats.has_stat(partner, "romance"), "a partner has no romance track")
	ok(not BondStats.has_stat(boss, "romance"), "a boss has a romance track")
	ok(not BondStats.has_stat(boss, "affection"), "a work bond is tracking affection")
	ok(not BondStats.has_stat(pet, "respect"), "a dog is being judged on respect")
	completed.append("profiles")


func test_stats_are_independent() -> void:
	life()
	var id := GameState.create_npc("friend", {"age": 30, "closeness": 50})
	BondStats.apply(id, {"affection": 45.0, "trust": -45.0})
	ok(BondStats.get_stat(id, "affection") > 80.0, "affection did not rise")
	ok(BondStats.get_stat(id, "trust") < 20.0, "trust did not fall")
	ok(BondStats.get_stat(id, "affection") - BondStats.get_stat(id, "trust") > 55.0, "adored-but-not-trusted is not representable")
	completed.append("independent")


func test_closeness_is_derived_and_still_works() -> void:
	life()
	var id := GameState.create_npc("friend", {"age": 30, "closeness": 50})
	var before := int(GameState.npc(id)["closeness"])
	GameState.change_closeness(id, 20)
	ok(int(GameState.npc(id)["closeness"]) > before, "legacy change_closeness no longer raises closeness")
	var hated := GameState.create_npc("enemy", {"age": 30, "closeness": 50})
	BondStats.apply(hated, {"resentment": 90.0})
	ok(int(GameState.npc(hated)["closeness"]) < 25, "heavy resentment did not drag closeness down")
	completed.append("derived")


func test_trust_outlasts_affection() -> void:
	life()
	var id := GameState.create_npc("friend", {"age": 30, "closeness": 80})
	BondStats.apply(id, {"affection": 30.0, "trust": 30.0, "respect": 30.0})
	var a0 := BondStats.get_stat(id, "affection")
	var t0 := BondStats.get_stat(id, "trust")
	for y in range(20):
		BondStats.yearly()
	var a1 := BondStats.get_stat(id, "affection")
	var t1 := BondStats.get_stat(id, "trust")
	ok(a0 - a1 > 25.0, "twenty years of no contact barely touched affection")
	ok(t0 - t1 < 20.0, "trust decayed as fast as affection; an old friend should still think well of you")
	ok((a0 - a1) > (t0 - t1) * 2.0, "affection does not fade meaningfully faster than trust")
	completed.append("decay")


func test_family_ties_boon_slows_family_decay() -> void:
	life()
	var id := GameState.create_npc("mother", {"age": 60, "closeness": 80})
	BondStats.apply(id, {"affection": 20.0})
	var start := BondStats.get_stat(id, "affection")
	GameState.player["boons"] = []
	for y in range(10):
		BondStats.yearly()
	var normal := start - BondStats.get_stat(id, "affection")

	life()
	var id2 := GameState.create_npc("mother", {"age": 60, "closeness": 80})
	BondStats.apply(id2, {"affection": 20.0})
	var start2 := BondStats.get_stat(id2, "affection")
	GameState.player["boons"] = ["family_ties"]
	for y in range(10):
		BondStats.yearly()
	var slowed := start2 - BondStats.get_stat(id2, "affection")
	GameState.player["boons"] = []
	ok(slowed < normal, "the family-ties boon did not slow family decay (%.1f vs %.1f)" % [slowed, normal])
	completed.append("boon")


func test_actions_buy_different_things() -> void:
	life()
	var a := GameState.create_npc("friend", {"age": 30, "closeness": 50})
	var b := GameState.create_npc("friend", {"age": 30, "closeness": 50})
	ok(Bonds.ACTION_BONDS.has("lend"), "lending money is not routed to a bond stat")
	ok(float(Bonds.ACTION_BONDS["lend"].get("obligation", 0.0)) > 0.0, "lending money creates no obligation")
	ok(float(Bonds.ACTION_BONDS["insult"].get("resentment", 0.0)) > 0.0, "insulting somebody creates no resentment")
	ok(float(Bonds.ACTION_BONDS["deep_talk"].get("trust", 0.0)) > 0.0, "a deep talk builds no trust")
	ok(float(Bonds.ACTION_BONDS["rumor"].get("trust", 0.0)) < 0.0, "spreading a rumour costs no trust")
	ok(not Bonds.ACTION_BONDS["give_money"].has("romance"), "giving money is buying romance")
	# Money must not be a shortcut to being loved.
	var money_love := float(Bonds.ACTION_BONDS["give_money"].get("affection", 0.0))
	var talk_love := float(Bonds.ACTION_BONDS["deep_talk"].get("affection", 0.0))
	ok(money_love < talk_love, "cash buys more affection than actually talking to somebody")
	completed.append("routing")


func test_options_are_earned_not_given() -> void:
	life(35)
	var id := GameState.create_npc("friend", {"age": 35, "closeness": 50})
	ok(Bonds.earned_rows(id, GameState.npc(id)).is_empty(), "earned options were available from the start")
	BondStats.apply(id, {"trust": 40.0})
	var names: Array = []
	for r in Bonds.earned_rows(id, GameState.npc(id)):
		names.append(str(r["name"]))
	ok(not names.is_empty(), "years of built trust unlocked nothing")
	BondStats.apply(id, {"obligation": 60.0})
	var names2: Array = []
	for r in Bonds.earned_rows(id, GameState.npc(id)):
		names2.append(str(r["name"]))
	ok(names2.size() > names.size(), "being owed a great deal unlocked nothing extra")

	# A different history should produce a different menu, not a longer one.
	var m := GameState.create_npc("mother", {"age": 62, "closeness": 50})
	BondStats.apply(m, {"affection": 100.0, "respect": -100.0})
	var mnames: Array = []
	for r in Bonds.earned_rows(m, GameState.npc(m)):
		mnames.append(str(r["name"]))
	ok(not mnames.is_empty(), "loved-but-not-respected unlocked nothing")
	ok(mnames != names2, "two completely different relationship histories produced the same options")
	completed.append("earned")


func test_a_dead_marriage_says_so() -> void:
	life()
	var id := GameState.create_npc("partner", {"age": 31, "closeness": 70})
	BondStats.apply(id, {"affection": 25.0, "trust": 20.0, "romance": -100.0})
	var line := BondStats.summary(id)
	ok(line.find("nothing left of it") >= 0, "a marriage with no romance left does not say so: '%s'" % line)
	ok(line.find("devoted") >= 0 or line.find("fond") >= 0, "the affection that is still there is not mentioned: '%s'" % line)
	completed.append("marriage")


func test_npc_own_stats_stay_theirs() -> void:
	life()
	var id := GameState.create_npc("friend", {"age": 30, "closeness": 50})
	var n := GameState.npc(id)
	var h0 := int(n["health"])
	# Nothing the player does to the bond should touch the other person's body.
	BondStats.apply(id, {"affection": 50.0, "trust": 50.0, "respect": 50.0})
	ok(int(n["health"]) == h0, "changing the bond changed the other person's health")
	for k in ["health", "smarts", "happiness", "looks"]:
		ok(n.has(k), "NPC lost their own '%s' stat" % k)
	ok(not BondStats.ensure(id).has("health"), "the bond record is storing the NPC's own health")
	completed.append("separation")


func _ready() -> void:
	seed(1010)
	test_bond_exists_and_seeds_from_closeness()
	test_profiles_differ_by_relation()
	test_stats_are_independent()
	test_closeness_is_derived_and_still_works()
	test_trust_outlasts_affection()
	test_family_ties_boon_slows_family_decay()
	test_actions_buy_different_things()
	test_options_are_earned_not_given()
	test_a_dead_marriage_says_so()
	test_npc_own_stats_stay_theirs()
	var expected := ["seed", "profiles", "independent", "derived", "decay", "boon", "routing", "earned", "marriage", "separation"]
	for name in expected:
		if not completed.has(name):
			fail("section '%s' aborted before finishing (runtime error above)" % name)
	print("V10 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), expected.size(), failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

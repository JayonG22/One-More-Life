extends Node

## v0.8 cross-system echo test.
## godot --headless --path . res://tools/v08_echo_test.tscn
##
## The v0.8 gate proves the systems RUN. This proves they REACH: every v0.8
## career has to change relationships, money, standing, law or memory, not just
## its own block of player["job"]. A system that passes the smoke test and fails
## this one is the "just another screen" failure the design doc warns about.

var failures: Array = []
var checks := 0
var completed: Array = []


func fail(msg: String) -> void:
	failures.append(msg)
	push_error("ECHO: " + msg)


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		fail(msg)


func life(age: int = 34) -> void:
	GameState.new_life({"country":"us","gender":"female","stats":{"health":90,"smarts":70,"looks":60},"traits":["Charmer","Loyal"]})
	GameState.player["age"] = age
	GameState.player["money"] = 5000000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	Ambition.ensure()
	Expansion.ensure()
	LifeThreads.ensure()


func reset_time() -> void:
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	GameState.interacted.clear()


func threads_of(kind: String) -> int:
	var n := 0
	for id in GameState.player.get("threads",{}).get("items",{}).keys():
		if str(GameState.player["threads"]["items"][id].get("kind","")) == kind:
			n += 1
	return n


func total_grudge() -> int:
	var g := 0
	for id in GameState.npcs.keys():
		g += int(GameState.npcs[id].get("grudge",0))
	return g


func become_cop() -> void:
	Actions.hire("police")
	GameState.player["job"]["rank"] = 2
	GameState.player["job"]["title"] = "Detective"
	Ambition.ensure()


# --------------------------------------------------------------- police
func test_wrongful_arrest() -> void:
	for attempt in range(24):
		life()
		become_cop()
		reset_time(); Ambition.police_new_case()
		var d: Dictionary = GameState.player["job"]["police"]
		if d["current"].is_empty():
			continue
		d["current"]["evidence"] = 2.0
		var credit_before := Grit.credit()
		var money_before := int(GameState.player["money"])
		reset_time(); Ambition.police_arrest()
		if threads_of("regret") > 0:
			ok(total_grudge() > 0, "wrongful arrest left nobody holding a grudge")
			ok(int(GameState.player["money"]) < money_before, "wrongful arrest cost no settlement money")
			ok(Grit.credit() < credit_before, "wrongful arrest did not touch credit")
			completed.append("wrongful_arrest")
			return
	fail("could not produce a wrongful arrest in 24 attempts")


func test_conviction_echo() -> void:
	for attempt in range(24):
		life()
		become_cop()
		reset_time(); Ambition.police_new_case()
		var d: Dictionary = GameState.player["job"]["police"]
		if d["current"].is_empty():
			continue
		d["current"]["evidence"] = 100.0
		d["current"]["confession"] = true
		d["current"]["warrant"] = true
		reset_time(); Ambition.police_arrest()
		if int(d["cases_solved"]) > 0:
			ok(threads_of("career") > 0, "a conviction created no career thread")
			ok(total_grudge() > 0, "a conviction left nobody resenting me")
			completed.append("conviction")
			return
	fail("could not produce a conviction in 24 attempts")


# --------------------------------------------------------------- medicine
func test_malpractice_pattern() -> void:
	life(40)
	GameState.player["education"]["degrees"].append({"major":"medicine","level":"medical","name":"t"})
	Actions.hire("doctor")
	GameState.player["job"]["rank"] = 3
	Ambition.ensure()
	var m: Dictionary = GameState.player["job"]["medicine"]
	m["reputation"] = 0.0
	GameState.player["stats"]["smarts"] = 5.0
	var credit_before := Grit.credit()
	for i in range(8):
		Ambition.medical_malpractice("test claim")
	ok(Grit.credit() < credit_before, "repeated malpractice never touched credit")
	ok(GameState.get_counter("medical_board_reviews") > 0, "a pattern of malpractice never reached a board review")
	ok(threads_of("regret") > 0, "malpractice created no regret thread")
	completed.append("malpractice")


# --------------------------------------------------------------- pets
func test_pet_death() -> void:
	life(45)
	var pid := GameState.create_npc("pet", {"species":"dog","first":"Mochi","last":"","age":15,"closeness":90})
	Ambition.ensure_pet(pid)
	GameState.npc(pid)["pet_profile"]["health"] = 0.0
	GameState.clear_flag("lost_close_person")
	Ambition._pets_yearly()
	ok(not GameState.npc(pid)["alive"], "a pet at zero health did not die")
	ok(GameState.has_flag("lost_close_person"), "losing a pet did not register as a loss for the mental-health system")
	ok(threads_of("grief") > 0, "losing a pet created no grief thread")
	completed.append("pet_death")


func test_support_animal_reads_mental_health() -> void:
	life(40)
	var pid := GameState.create_npc("pet", {"species":"dog","first":"Bean","last":"","age":3,"closeness":80})
	Ambition.ensure_pet(pid)
	reset_time()
	# Start well clear of the 0 floor, or both paths clamp and look identical.
	var stress_before := 60.0
	GameState.player["stats"]["stress"] = stress_before
	Ambition.pet_therapy(pid)
	var plain := stress_before - GameState.stat("stress")

	life(40)
	var pid2 := GameState.create_npc("pet", {"species":"dog","first":"Bean","last":"","age":3,"closeness":80})
	Ambition.ensure_pet(pid2)
	Expansion._add_mental("anxiety")
	GameState.player["stats"]["stress"] = stress_before
	reset_time()
	Ambition.pet_therapy(pid2)
	var carrying := stress_before - GameState.stat("stress")
	ok(carrying > plain, "a support animal helped no more when the player was actually struggling")
	completed.append("support_animal")


# --------------------------------------------------------------- sports
func test_championship_echo() -> void:
	for attempt in range(60):
		life(24)
		var c := {"id":"athlete"}
		Ambition.ensure_sports(c)
		c["sport"] = "basketball"
		c["team"] = "Riverport Hawks"
		c["contract"] = 2000000
		c["contract_years"] = 3
		var fame_before := float(GameState.player["fame"])
		var money_before := int(GameState.player["money"])
		Ambition.sports_yearly(c, GameState.player, 99.0)
		if int(c["league_titles"]) > 0:
			ok(float(GameState.player["fame"]) > fame_before, "a championship produced no fame")
			ok(int(GameState.player["money"]) > money_before, "a championship produced no money")
			ok(threads_of("career") > 0, "a championship created no career thread")
			completed.append("championship")
			return
	fail("could not win a championship in 60 seasons at peak performance")


# --------------------------------------------------------------- enterprise
func test_bankruptcy_echo() -> void:
	for attempt in range(40):
		life(45)
		Ambition.ensure()
		var e: Dictionary = GameState.player["ambition"]["enterprise"]
		var ceo := GameState.create_npc("coworker", {"age":50,"closeness":50})
		e["portfolio"].append({"ind":"tech","industry":"Tech","icon":"💻","name":"Testco","value":10000,"profit":-5000,"quality":20.0,"staff":4,"debt":900000,"stake":1.0,"ceo":ceo,"years":3,"public":false})
		var credit_before := Grit.credit()
		Ambition._enterprise_yearly()
		if int(e["bankruptcies"]) > 0:
			ok(Grit.credit() < credit_before, "a bankruptcy did not touch credit")
			ok(threads_of("money") > 0, "a bankruptcy created no money thread")
			completed.append("bankruptcy")
			return
	fail("could not force a bankruptcy in 40 attempts")


# --------------------------------------------------------------- justice
func test_conviction_record() -> void:
	life(30)
	var mum := GameState.create_npc("mother", {"age":60,"closeness":80})
	var partner := GameState.create_npc("partner", {"age":31,"closeness":80})
	GameState.player["partner"] = partner
	GameState.player["partner_status"] = "married"
	var credit_before := Grit.credit()
	var mum_before := int(GameState.npc(mum)["closeness"])
	var partner_before := int(GameState.npc(partner)["closeness"])
	Ambition.record_case("fraud", "convicted", 3, 60.0, 1)
	ok(Grit.credit() < credit_before, "a conviction did not touch credit")
	ok(int(GameState.npc(mum)["closeness"]) < mum_before, "a conviction did not reach my parents")
	ok(int(GameState.npc(partner)["closeness"]) < partner_before, "a conviction did not reach my marriage")
	ok(threads_of("justice") > 0, "a conviction created no justice thread")
	completed.append("conviction_record")


func test_thread_kinds_are_real() -> void:
	for k in ["career","regret","money","justice"]:
		ok(LifeThreads.KINDS.has(k), "thread kind '%s' is not registered and would collapse into 'relationship'" % k)
	completed.append("thread_kinds")


func _ready() -> void:
	seed(4242)
	test_thread_kinds_are_real()
	test_wrongful_arrest()
	test_conviction_echo()
	test_malpractice_pattern()
	test_pet_death()
	test_support_animal_reads_mental_health()
	test_championship_echo()
	test_bankruptcy_echo()
	test_conviction_record()
	var expected := ["thread_kinds","wrongful_arrest","conviction","malpractice","pet_death","support_animal","championship","bankruptcy","conviction_record"]
	for name in expected:
		if not completed.has(name):
			fail("section '%s' aborted before finishing (runtime error above)" % name)
	print("V08 ECHO TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), expected.size(), failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

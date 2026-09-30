extends Node

## v0.8 headless/runtime smoke test. Run with:
## godot --headless --path . res://tools/v08_system_test.tscn
## Minigames auto-resolve in headless mode, so this exercises their callbacks too.

var failures: Array = []
var actions_run := 0
var completed: Array = []

func fail(msg: String) -> void:
	failures.append(msg)
	push_error("V08: " + msg)

func drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 80 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var choices: Array = inst["def"].get("choices", [])
		for i in range(choices.size()):
			var st := EventEngine.choice_state(choices[i], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				EventEngine.resolve(inst, i)
				break

func setup_life(age: int = 32) -> void:
	GameState.new_life({"country":"us","gender":"female","stats":{"health":92,"smarts":88,"looks":75},"traits":["Charmer","Bookworm"]})
	GameState.player["age"] = age
	GameState.player["money"] = 12000000
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	GameState.player["education"]["hs_graduated"] = true
	GameState.player["education"]["degrees"].append({"major":"criminal_justice","level":"bachelor","name":"test"})
	GameState.create_npc("child", {"age":8,"closeness":75})
	GameState.create_npc("pet", {"species":"dog","first":"Mochi","last":"","age":3,"closeness":85})
	Ambition.ensure()

func reset_time() -> void:
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	GameState.interacted.clear()

func run_action(id: String, arg = null) -> void:
	reset_time()
	Ambition.act(id,arg)
	actions_run += 1
	drain()

func test_police() -> void:
	setup_life()
	Actions.hire("police")
	GameState.player["job"]["rank"] = 2
	GameState.player["job"]["title"] = "Detective"
	Ambition.ensure()
	for id in ["career_project","career_network","career_mentor","career_rival","career_train","patrol","new_case"]:
		run_action(id)
	if GameState.player["job"]["police"]["current"].is_empty():
		fail("police case was not created")
	else:
		for id in ["scene","evidence","witness","interrogate","warrant","arrest"]:
			run_action(id)
	if not Ambition.menu("police").has("rows"):
		fail("police menu malformed")
	completed.append("police")

func test_medicine() -> void:
	setup_life(35)
	GameState.player["education"]["degrees"].append({"major":"medicine","level":"medical","name":"test"})
	Actions.hire("doctor")
	GameState.player["job"]["rank"] = 3
	GameState.player["job"]["title"] = "Attending Physician"
	Ambition.ensure()
	run_action("specialty","surgery")
	for id in ["rounds","new_patient","diagnose","second_opinion","treat_patient"]:
		run_action(id)
	# Ensure there is a severe patient so the operating-room callback is tested.
	var m: Dictionary = GameState.player["job"]["medicine"]
	if m["current"].is_empty():
		run_action("new_patient")
	if not m["current"].is_empty():
		m["current"]["condition"] = "heart"
		m["current"]["diagnosed"] = true
		run_action("surgery")
	for id in ["research","mentor"]:
		run_action(id)
	if not Ambition.menu("medicine").has("rows"):
		fail("medicine menu malformed")
	completed.append("medicine")

func test_pets_enterprise_justice() -> void:
	setup_life(40)
	var pets := GameState.npcs_with("pet")
	if pets.is_empty():
		fail("pet setup missing")
		return
	var pid: String = pets[0]
	Ambition.ensure_pet(pid)
	GameState.npc(pid)["pet_profile"]["training"] = 80.0
	for id in ["pet_train","pet_show","pet_vet","pet_groom","pet_therapy"]:
		run_action(id,pid)
	run_action("petbiz_start","training")
	for id in ["petbiz_market","petbiz_expand","petbiz_feature"]:
		run_action(id)
	run_action("enterprise_start","tech")
	run_action("enterprise_dividend")
	run_action("enterprise_succession")
	Ambition.record_case("test offense","convicted",1,42.0,1)
	run_action("appeal")
	if not Ambition.menu("enterprise").has("rows") or not Ambition.menu("justice").has("rows"):
		fail("enterprise or justice menu malformed")
	completed.append("pets_enterprise_justice")

func test_sports() -> void:
	setup_life(22)
	GameState.player["stats"]["health"] = 95.0
	GameState.player["stats"]["looks"] = 80.0
	Careers.join("athlete")
	drain()
	if not Careers.has_career("athlete"):
		fail("athlete career did not start in headless smoke")
		return
	var c: Dictionary = Careers.career()
	Ambition.ensure_sports(c)
	if c.get("sport","") == "": c["sport"] = "basketball"
	if c.get("team","") == "": c["team"] = "Riverport Hawks"
	c["contract"] = maxi(100000,int(c.get("contract",0)))
	c["contract_years"] = 2
	for aid in ["v8_agent","v8_media","v8_team"]:
		reset_time(); Ambition.sports_action(aid,c); actions_run += 1; drain()
	Ambition.sports_yearly(c,GameState.player,78.0)
	if int(c.get("season",0)) < 1:
		fail("sports season state did not advance")
	completed.append("sports")

func _ready() -> void:
	seed(80808)
	test_police()
	test_medicine()
	test_pets_enterprise_justice()
	test_sports()
	for name in ["police","medicine","pets_enterprise_justice","sports"]:
		if not completed.has(name):
			fail("section '%s' aborted before finishing (runtime error above)" % name)
	print("V08 SYSTEM TEST actions=%d sections=%d/4 failures=%d" % [actions_run,completed.size(),failures.size()])
	if not failures.is_empty():
		for f in failures: print("FAIL: ",f)
	get_tree().quit(1 if not failures.is_empty() else 0)

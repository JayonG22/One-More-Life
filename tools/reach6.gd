extends Node

## Focused v0.6 playthroughs: one long life per theme, re-running the new menus
## every year, to prove each v0.6 achievement can be earned.

var acts := 0
var menus := 0
var seen := {}


func _ready() -> void:
	seed(6060)
	_school_life()
	_adult_life()
	_family_life()
	Goals.check()
	var miss: Array = []
	for a in Goals.achievements:
		if int(a.get("v", 0)) == 6 and not Goals.has(a["id"]):
			miss.append(a["id"])
	print("REACH6 acts=%d  LOCKED: %s" % [acts, str(miss)])
	get_tree().quit()


func _year(roots: Array) -> void:
	seen.clear()
	for r in roots:
		_crawl(r, 0)
	Goals.check()
	EventEngine.age_up()
	_drain()


func _school_life() -> void:
	GameState.new_life({"country": "us", "gender": "male"})
	for i in range(13):
		EventEngine.age_up()
		_drain()
	for y in range(5):
		GameState.player["stats"]["health"] = 90.0
		for k in range(3):
			_run("daily:sport", "soccer")
		for k in range(3):
			_run("daily:voice", null)
		_run("daily:club_join", ["chess", "drama", "robotics", "debate"][y % 4])
		_run("daily:club_join", ["chess", "drama", "robotics", "debate"][(y + 1) % 4])
		_year(["daily:school", "daily:clubs", "daily:martial", "daily:sports"])
		var ss: Dictionary = Daily._ss()
		ss["clubs"].clear()


func _adult_life() -> void:
	GameState.new_life({"country": "us", "gender": "female"})
	for i in range(22):
		EventEngine.age_up()
		_drain()
	var p := GameState.player
	p["housing"] = "house"
	p["last_income"] = 200000
	Actions.hire("army")
	_run("dealer:start", null)
	p["money"] = 50000000
	for it in [["electronics", "Flagship smartphone"], ["electronics", "Pro camera"], ["electronics", "Laptop"], ["electronics", "Webcam & microphone"], ["electronics", "Gaming PC"]]:
		for i in range(Shop.ITEMS[it[0]].size()):
			if Shop.ITEMS[it[0]][i][0] == it[1]:
				_run("shop:buy", [it[0], i])
	for pid in Social.PLATFORMS.keys():
		_run("social:join", pid)
	for y in range(28):
		if not GameState.is_alive():
			break
		p["money"] = 50000000
		p["stats"]["health"] = 90.0
		p["record"].clear()
		if p["partner"] == "" or not GameState.npcs.has(p["partner"]):
			var pid2 := GameState.create_npc("partner", {"age": int(p["age"]), "closeness": 90})
			Actions.start_dating(pid2, false)
		var cur: String = p["partner"]
		if p["partner_status"] == "married":
			_run("bond:%s:divorce" % cur, "amicable")
		else:
			GameState.npcs[cur]["closeness"] = 95
			_run("bond:%s:propose" % cur, "beach")
			_run("bond:%s:wedding" % cur, null)
			_crawl("bond:" + cur, 0)
		for i in range(6):
			GameState.player["time_left"] = GameState.TIME_PER_YEAR
			Actions.do_activity("burglary")
			_drain()
		if not GameState.has_job():
			Actions.hire("army")
		GameState.interacted.clear()
		GameState.player["time_left"] = GameState.TIME_PER_YEAR
		Actions.deploy()
		_drain()
		if y == 5:
			p["prison"] = 4
			for i in range(8):
				if GameState.in_prison():
					Actions.do_activity("p_escape")
					Actions.do_activity("p_fight")
					_drain()
		for i in range(4):
			var e := GameState.create_npc("enemy", {"age": int(p["age"]), "closeness": 5})
			_run("bond:%s:fight" % e, null)
		for pid in Social.PLATFORMS.keys():
			for i in range(6):
				_run("social:post", [pid, Social.CONTENT[pid][i % Social.CONTENT[pid].size()][0]])
		_year(["social:root", "dealer:root", "daily:foster", "daily:martial", "daily:lottery", "shop:root", "daily:casino", "daily:surgery"])


func _family_life() -> void:
	GameState.new_life({"country": "uk", "gender": "male"})
	var p := GameState.player
	p["age"] = 45
	p["money"] = 5000000
	for i in range(5):
		GameState.create_npc("child", {"age": 22 + i, "last": p["last"], "closeness": 80})
	for y in range(25):
		if not GameState.is_alive():
			break
		p["stats"]["health"] = 90.0
		EventEngine.age_up()
		_drain()
	Goals.check()


func _crawl(key: String, depth: int) -> void:
	if depth > 3 or not GameState.is_alive():
		return
	var mod = _mod(key)
	if mod == null:
		return
	var d: Dictionary = mod.menu(_rest(key))
	menus += 1
	for r in d.get("rows", []):
		if not GameState.is_alive():
			return
		GameState.player["time_left"] = GameState.TIME_PER_YEAR
		GameState.interacted.clear()
		if r.has("menu"):
			var mk: String = r["menu"]
			if not seen.has(mk + str(GameState.player["age"])):
				seen[mk + str(GameState.player["age"])] = true
				_crawl(mk, depth + 1)
		elif r.has("act") and r.get("on", true):
			var ak: String = r["act"]
			if ak.ends_with(":quit") or ak.ends_with(":breakup") or ak.ends_with(":delete") or ak.ends_with(":disown") or ak.ends_with(":cut_off") or ak.ends_with(":pet_rehome"):
				continue
			_run(ak, r.get("arg", null))


func _run(ak: String, arg) -> void:
	var mod = _mod(ak)
	if mod == null:
		return
	GameState.player["time_left"] = GameState.TIME_PER_YEAR
	GameState.player["money"] = maxi(int(GameState.player["money"]), 2000000)
	mod.act(_rest(ak), arg)
	acts += 1
	_drain()


func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 30 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var choices: Array = inst["def"].get("choices", [])
		var opts: Array = []
		for ci in range(choices.size()):
			var st := EventEngine.choice_state(choices[ci], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				opts.append(ci)
		if not opts.is_empty():
			EventEngine.resolve(inst, opts[randi() % opts.size()])


func _mod(key: String):
	match key.get_slice(":", 0):
		"bond": return Bonds
		"daily": return Daily
		"shop": return Shop
		"social": return Social
		"dealer": return Dealer
	return null


func _rest(key: String) -> String:
	var i := key.find(":")
	return "" if i < 0 else key.substr(i + 1)

extends Node

## Opens every data-driven menu (Bonds, Daily, Shop, Social) at several ages and
## runs every action once, resolving any popups, to catch runtime errors.

var acts := 0
var menus := 0
var seen := {}


func _ready() -> void:
	seed(606)
	for age in [7, 12, 16, 22, 34, 48, 72]:
		_setup(age)
		for root in ["daily:martial", "daily:diet", "daily:salon", "daily:surgery", "daily:doctor", "daily:nightlife", "daily:outings", "daily:movies", "daily:vacation", "daily:casino", "daily:horses", "daily:lottery", "daily:fertility", "daily:adoption", "daily:foster", "daily:identity", "daily:will", "daily:school", "daily:dating", "shop:root", "shop:mine", "social:root", "dealer:root"]:
			_crawl(root, 0)
		if age >= 16:
			_run("dealer:start", null)
			_crawl("dealer:root", 0)
		for mk in ["daily:garden", "daily:memory", "daily:pray", "daily:voice", "daily:acting"]:
			_run(mk, null)
		for id in GameState.npcs.keys():
			if GameState.npcs.has(id) and GameState.npcs[id]["alive"]:
				_crawl("bond:" + id, 0)
		for y in range(3):
			EventEngine.age_up()
			_drain()
	Goals.check()
	var miss: Array = []
	for a in Goals.achievements:
		if int(a.get("v", 0)) == 6 and not Goals.has(a["id"]):
			miss.append(a["id"])
	print("V6 LOCKED: ", miss)
	print("CRAWL DONE menus=%d acts=%d" % [menus, acts])
	get_tree().quit()


func _setup(age: int) -> void:
	GameState.new_life({"country": ["us", "uk", "jp", "br"][age % 4], "gender": "female" if age % 2 == 0 else "male"})
	var p := GameState.player
	for i in range(age):
		EventEngine.age_up()
		_drain()
		if not GameState.is_alive():
			GameState.new_life({"country": "us"})
			p = GameState.player
	p["money"] = 5000000
	p["age"] = age
	if age >= 18:
		p["housing"] = "apartment"
		for lic in ["driver", "boating", "pilot", "fishing", "firearms", "motorcycle"]:
			if not p["licenses"].has(lic):
				p["licenses"].append(lic)
		var pid := GameState.create_npc("partner", {"age": age, "closeness": 70})
		Actions.start_dating(pid, false)
		if age >= 30:
			p["partner_status"] = "married"
			var kid := GameState.create_npc("child", {"age": maxi(0, age - 28), "last": p["last"], "closeness": 70})
		GameState.create_npc("friend", {"age": age, "closeness": 80})
		GameState.create_npc("coworker", {"age": age, "closeness": 50})
		GameState.create_npc("neighbor", {"age": age + 5, "closeness": 50})
		GameState.create_npc("ex", {"age": age, "closeness": 70})
	if age >= 13:
		GameState.create_npc("classmate", {"age": age, "closeness": 50})
		GameState.create_npc("teacher", {"age": 40, "closeness": 50})
	GameState.create_npc("pet", {"species": "dog", "first": "Rex", "last": "", "age": 3, "closeness": 60})


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
			if ak.ends_with(":delete") or ak.ends_with(":disown") or ak.ends_with(":cut_off") or ak.ends_with(":pet_rehome"):
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

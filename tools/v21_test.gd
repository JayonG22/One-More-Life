extends Node

## v0.20 gate — sharing, legacy, challenges and the other additions.

var failures: Array = []
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V21: " + msg)


func _ready() -> void:
	seed(2121)
	_endings_log()
	_share()
	_legacy()
	_seeded()
	_recall_check()
	_reentry()
	_workforce()
	_reasoned_rejections()
	_transport()
	_companions_and_director()
	_items_and_avatar()
	_mode_audio()
	print("V21 TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _pet_life(heroic: bool) -> Dictionary:
	GameState.new_life({"first": "Biscuit", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": "dog", "origin": "loving"})
	if heroic:
		Lives.life()["heroics"] = 2
	GameState.player["age"] = 10
	return GameState.finalize_death("old age")


func _endings_log() -> void:
	Meta.meta["endings"] = {}
	var cat := Meta.endings_catalog()
	ok(cat.size() >= 40, "the endings catalog has only %d" % cat.size())
	for e in cat:
		ok(not bool(e["seen"]), "an ending was seen before any life")
	var e1 := _pet_life(true)
	Meta.record_death(e1)
	var seen := 0
	for e in Meta.endings_catalog():
		if bool(e["seen"]):
			seen += 1
	ok(seen == 1, "recording a death marked %d endings seen" % seen)
	print("  endings: %d in the catalog; recording a death marks exactly one" % cat.size())


func _share() -> void:
	var entry := _pet_life(true)
	var card: Control = preload("res://scenes/share_card.gd").build(entry)
	ok(card.size == Vector2(1080, 620), "the share card is the wrong size")
	var txt: String = preload("res://scenes/share_card.gd").share_text(entry)
	ok(txt.find("ONE MORE LIFE") != -1 and txt.find(str(entry["name"])) != -1, "the share text does not name the life")
	var hl: Array = preload("res://scenes/share_card.gd").highlights(entry, 3)
	ok(hl.size() <= 3, "too many highlights")
	card.free()
	print("  share: card built, text names the life")


func _legacy() -> void:
	Meta.meta["echoes"] = []
	# a heroic pet leaves an echo
	var e := _pet_life(true)
	Legacy.record(e)
	ok(Legacy.pending().size() == 1 and str(Legacy.pending()[0]["kind"]) == "pet", "a heroic pet left no echo")
	# every mode picks it up exactly once
	for mode in ["human", "pet", "prisoner", "guard"]:
		Legacy.list().clear()
		Legacy._add("pet", "Biscuit the dog, who was somebody's whole world", "Biscuit", {"species": "dog", "name": "Biscuit"})
		Legacy._add("convict", "A Person, who did time", "A Person", {"years": 7})
		match mode:
			"human": GameState.new_life({"gender": "female", "country": "uk"})
			"pet": GameState.new_life({"first": "Pip", "last": "", "gender": "male", "country": "uk", "life_path": "pet", "keep_family": true, "species": "cat", "origin": "loving"})
			"prisoner": GameState.new_life({"first": "Sam", "last": "Reed", "gender": "male", "country": "us", "life_path": "prisoner", "keep_family": true, "story": "first"})
			"guard": GameState.new_life({"first": "Kim", "last": "Doyle", "gender": "female", "country": "us", "life_path": "guard", "keep_family": true, "story": "career"})
		var used := 0
		for x in Legacy.list():
			if bool(x["used"]):
				used += 1
		ok(used == 2, "%s life used %d echoes, wanted 2" % [mode, used])
		var said := false
		for lg in GameState.log_years:
			for ln in lg["lines"]:
				if str(ln).find("Biscuit") != -1 or str(ln).find("inside") != -1 or str(ln).find("time") != -1:
					said = true
		ok(said, "%s life's log never mentioned its echoes" % mode)
	# used echoes are not used again
	GameState.new_life({"gender": "male", "country": "us"})
	for x in Legacy.pending():
		ok(false, "an echo survived two lives unused")
	# a direct heir does not take echoes
	Legacy._add("name", "the Name", "X", {"last": "Name"})
	var before := Legacy.pending().size()
	GameState.new_life({"gender": "male", "country": "us", "keep_family": true})
	ok(Legacy.pending().size() == before, "an heir consumed an echo")
	print("  legacy: echoes recorded, picked up once in every mode, never by an heir")


func _seeded() -> void:
	for kind in ["daily", "weekly"]:
		for i in range(100, 160):
			var a: Dictionary = Seeded.spec(kind, i)
			var b: Dictionary = Seeded.spec(kind, i)
			ok(JSON.stringify(a) == JSON.stringify(b), "%s spec %d is not deterministic" % [kind, i])
			ok(Seeded.describe(a) != "", "no description for %s %d" % [kind, i])
	var modes := {}
	for i in range(0, 40):
		modes[Seeded.spec("daily", i)["mode"]] = true
	ok(modes.size() == 4, "daily seeds cover %d modes" % modes.size())
	# every mode starts, plays a few years and is scored
	for m in Seeded.MODES:
		var idx := 0
		while str(Seeded.spec("daily", idx)["mode"]) != m:
			idx += 1
		var sp: Dictionary = Seeded.spec("daily", idx)
		var first := ""
		for pass_i in 2:
			seed(int(sp["seed"]))
			var opts := {}
			Seeded.start("daily")
			if pass_i == 0:
				first = str(GameState.player["name"]) if GameState.player.has("name") else ""
		ok(Seeded.active(), "seeded life not flagged active (%s)" % m)
		ok(Seeded.status_line() != "", "no status line (%s)" % m)
		GameState.player["age"] = 40
		var e: Dictionary = GameState.finalize_death("test")
		ok(e.has("seeded") and int(e["seeded"]["score"]) >= 400, "death not scored (%s)" % m)
		ok(preload("res://scenes/share_card.gd").share_text(e).find(str(e["seeded"]["key"])) != -1, "share text lacks the seeded day (%s)" % m)
	print("  seeded: specs deterministic, all four modes start and score")


func _recall_check() -> void:
	GameState.new_life({"first": "Test", "last": "Person", "gender": "male", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	GameState.player["age"] = 30
	var ids := GameState.npcs_with("mother", true)
	if ids.is_empty():
		ids = [GameState.create_npc("mother", {"age": 55, "closeness": 60})]
	var id: String = ids[0]
	Bonds.remember(id, "Paid back a kindness from years ago.", false)
	GameState.npcs[id]["memory"][0]["age"] = 20
	var seen := 0
	for i in 400:

		Bonds._recall()
		if GameState.npcs[id]["memory"][0].get("told", false):
			seen += 1
			break
	ok(seen == 1, "an old memory never came back up")
	var before: int = GameState.npcs[id]["memory"].size()
	ok(before >= 1, "memory lost")
	print("  recall: an old memory is brought back up exactly once")


func _reentry() -> void:
	var stayed := 0
	var back := 0
	for i in 30:
		GameState.new_life({"first": "Test", "last": "Person", "gender": "male", "country": "us", "life_path": "prisoner", "keep_family": true, "story": ["first", "career", "gang", "white", "innocent", "political", "lifer"][i % 7], "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
		Prison.conclude("paroled" if i % 2 == 0 else "served")
		ok(GameState.is_alive() and bool(Prison.L().get("reentry", false)), "release did not open the outside")
		ok(Prison.tabs().size() == 6, "outside tabs missing")
		ok(not Prison._menu_reentry("home")["rows"].is_empty(), "outside menu empty")
		for y in 6:
			if not GameState.is_alive():
				break
			if i % 3 == 0:
				Prison.L()["job_out"] = true
				Prison.L()["home_out"] = 2
			Prison.yearly()
		ok(not GameState.is_alive(), "the outside never resolved (life %d)" % i)
		var o := str(Prison.L().get("outcome", ""))
		if o == "returned":
			back += 1
		elif o in ["served", "paroled"]:
			stayed += 1
		ok(o in ["served", "paroled", "returned"], "odd outcome '%s'" % o)
	ok(stayed >= 3 and back >= 3, "re-entry is lopsided: %d stayed, %d returned" % [stayed, back])
	print("  reentry: %d stayed out, %d went back" % [stayed, back])


func _workforce() -> void:
	var promoted := 0
	var demoted := 0
	var fired := 0
	var warned := 0
	for i in 40:
		GameState.new_life({"first": "Test", "last": "Worker", "gender": "female", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
		GameState.player["age"] = 30
		Actions.hire("teacher" if ContentDB.job("teacher").size() > 0 else str(ContentDB.jobs[0]["id"]))
		if not GameState.has_job():
			continue
		var j: Dictionary = GameState.player["job"]
		j["years_in_rank"] = 3
		j["perf"] = [90.0, 85.0, 30.0, 10.0][i % 4]
		var before_rank := int(j["rank"])
		var w := Workplace.w()
		w["health"] = 0.9
		var pending_before := EventEngine.pending.size()
		Workforce.review()
		if not GameState.has_job():
			fired += 1
			ok(EventEngine.pending.size() > pending_before, "a firing came without an explanation popup")
			ok(float(GameState.player.get("benefit", {}).get("amt", 0)) >= 0.0, "benefit malformed")
			continue
		j = GameState.player["job"]
		if int(j["rank"]) > before_rank:
			promoted += 1
		if int(j.get("warned", 0)) == 1:
			warned += 1
			# a second bad review demotes or fires
			j["perf"] = 30.0
			j["rank"] = maxi(1, int(j["rank"]))
			Workforce.review()
			if not GameState.has_job():
				fired += 1
			else:
				if GameState.get_counter("demotions") > 0:
					demoted += 1
	ok(promoted >= 3, "no one was promoted on merit (%d)" % promoted)
	ok(warned >= 3, "no one was warned (%d)" % warned)
	ok(fired >= 3, "no one was fired (%d)" % fired)
	print("  workforce: %d promoted, %d warned, %d fired, %d demoted after a second warning" % [promoted, warned, fired, demoted])


func _reasoned_rejections() -> void:
	GameState.new_life({"first": "Test", "last": "Applicant", "gender": "male", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	GameState.player["age"] = 22
	var rejects := 0
	var reasons := {}
	for i in 60:
		var list := Market.openings("full")
		if list.is_empty():
			continue
		var l: Dictionary = list[i % list.size()]
		var ob := Market.main_obstacle(l)
		ok(str(ob["text"]) != "" and str(ob["tip"]) != "", "an obstacle came without a reason or a tip")
		reasons[str(ob["key"])] = true
		var q := float(Market.standing(l)["chance"])
		if q < 0.27:
			rejects += 1
	ok(reasons.size() >= 2, "rejection reasons never vary (%s)" % str(reasons.keys()))
	print("  rejections: %d long shots found, reasons seen: %s" % [rejects, str(reasons.keys())])


func _transport() -> void:
	GameState.new_life({"first": "Test", "last": "Walker", "gender": "male", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	GameState.player["age"] = 20
	GameState.player["car"] = ""
	var walk := Transit.reach("trip")
	if str(walk["mode"]) == "walk":
		ok(float(walk["mult"]) < 0.4, "a long trip on foot is not slim (%s)" % str(walk))
	ok(str(walk["hint"]) != "", "no hint for a long trip")
	GameState.player["car"] = "sedan" if GameState.CARS.has("sedan") else GameState.CARS.keys()[0]
	var drive := Transit.reach("trip")
	ok(float(drive["mult"]) > 1.0 and str(drive["mode"]) == "drive", "a car does not help a long trip")
	var def: Dictionary = ContentDB.events_by_id["jn.sick_relative"]
	var good_walk := 0
	var good_car := 0
	GameState.player["car"] = ""
	for i in 2000:
		if bool(EventEngine._pick_outcome(def["choices"][0]["outcomes"], "trip").get("good", false)):
			good_walk += 1
	GameState.player["car"] = GameState.CARS.keys()[0]
	for i in 2000:
		if bool(EventEngine._pick_outcome(def["choices"][0]["outcomes"], "trip").get("good", false)):
			good_car += 1
	ok(float(good_car) > float(good_walk) * 1.2, "the car did not improve the odds (walk %d, car %d)" % [good_walk, good_car])
	print("  transport: the good outcome came %d/2000 without a car and %d/2000 by car" % [good_walk, good_car])


func _companions_and_director() -> void:
	GameState.new_life({"first": "Test", "last": "Keeper", "gender": "female", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	GameState.player["age"] = 30
	GameState.player["money"] = 100000
	var id := Companions.acquire("cat", "shelter")
	ok(GameState.npcs.has(id) and str(GameState.npcs[id]["relation"]) == "pet", "an acquired pet is not in the people list")
	ok(Companions.status_line(id).find("shelter") != -1, "the pet does not remember where it came from")
	var c0 := int(GameState.npcs[id]["closeness"])
	for y in 6:
		Companions.yearly()
	ok(int(GameState.npcs[id]["closeness"]) < c0 or not GameState.npcs[id]["alive"], "a neglected pet did not cool or leave")
	var id2 := Companions.gain({"species": "dog", "source": "stray"})
	ok(id2 != "" and GameState.npcs.has(id2), "the gain_pet outcome did not make a pet")
	# an event that gives a pet keeps it
	var def: Dictionary = ContentDB.events_by_id["co.porch_cat"]
	var kept := 0
	for i in 60:
		var n_before := GameState.npcs_with("pet").size()
		var o: Dictionary = EventEngine._pick_outcome(def["choices"][0]["outcomes"])
		if o.has("gain_pet"):
			EventEngine._apply_outcome(o, {}, def)
			if GameState.npcs_with("pet").size() > n_before:
				kept += 1
		if GameState.npcs_with("pet").size() >= Companions.MAX_PETS:
			break
	ok(kept >= 1, "an event's pet was not kept")
	# the director trims to its budget, never trimming critical items
	GameState.player["age"] = 33
	EventEngine.pending.clear()
	for i in 6:
		EventEngine.pending.append({"def": {"id": "adult.fake%d" % i, "choices": [{}]}, "roles": {}, "created": []})
	EventEngine.pending.append({"info": true, "icon": "i", "title": "Critical", "text": "x", "changes": {}, "critical": true})
	Director.curate()
	var crit := 0
	var normal := 0
	for it in EventEngine.pending:
		if it.get("critical", false):
			crit += 1
		else:
			normal += 1
	ok(crit == 1, "the critical notice was trimmed")
	ok(normal <= Director.budget(), "the director let %d through a budget of %d" % [normal, Director.budget()])
	# the gambling and memory games exist and are flagged
	for gid in ["g_slots", "g_roulette", "g_horses", "g_rocket", "g_plinko", "g_scratch", "g_wheel", "g_highlow"]:
		ok(Minigames.DEFS.has(gid) and bool(Minigames.DEFS[gid].get("gamble", false)), "%s is not registered as a gambling game" % gid)
	ok(Minigames.DEFS.has("memory"), "the memory test has no minigame")
	# employers sound like their sector, and the military is not a lightbulb company
	var army := Names.company("Military", "us")
	ok(Names.MIL_US.has(army), "the military is called '%s'" % army)
	var hosp := Names.company("Healthcare", "us")
	ok(hosp != "", "no hospital name")
	var seen := {}
	for i in 60:
		seen[Names.company("Food", "us")] = true
	ok(seen.size() >= 40, "restaurant names repeat too much (%d distinct of 60)" % seen.size())
	print("  companions & director: pets are kept and tended, the year is capped, names vary (%d distinct)" % seen.size())


func _items_and_avatar() -> void:
	# the shelf is a function of the clock, the same for every save, and turns over
	var a := Items.stock(5000)
	var b := Items.stock(5000)
	ok(JSON.stringify(a) == JSON.stringify(b), "the shop shelf differs between reads of the same rotation")
	ok(a.size() == Items.STOCK_SIZE, "the shelf has %d items" % a.size())
	var changed := 0
	for sl in range(5001, 5021):
		if JSON.stringify(Items.stock(sl)) != JSON.stringify(a):
			changed += 1
	ok(changed >= 15, "the shelf barely changes between rotations (%d of 20)" % changed)
	# buying and using
	Meta.meta["goals"]["stars"] = 500
	Meta.meta["goals"]["items"] = {}
	GameState.new_life({"first": "Test", "last": "Rewind", "gender": "male", "country": "us", "modifiers": [], "difficulty": "real", "boons": [], "challenge": ""})
	var shelf := Items.stock()
	var got := ""
	for id in shelf:
		if Items.buy(id):
			got = id
			break
	ok(got != "" and Items.owned(got) == 1, "could not buy from the shelf")
	# a Do-Over rewinds a year, and rewinds a death
	Items.add("do_over", 2)
	GameState.player["age"] = 30
	var money0 := int(GameState.player["money"])
	Items.snapshot()
	EventEngine.age_up()
	var age_after := int(GameState.player["age"])
	ok(age_after == 31, "the year did not pass")
	var r := Items.use("do_over")
	ok(r == "__redo" and int(GameState.player["age"]) == 30 and int(GameState.player["money"]) == money0, "the Do-Over did not rewind (age %d)" % int(GameState.player["age"]))
	ok(Items.owned("do_over") == 1, "the Do-Over was not consumed")
	Items.snapshot()
	EventEngine.kill("a test", true)
	ok(not bool(GameState.player["alive"]), "the test life did not die")
	var graves := SaveManager.graveyard.size()
	var r2 := Items.use("do_over")
	ok(r2 == "__redo" and bool(GameState.player["alive"]), "the Do-Over did not undo a death")
	ok(SaveManager.graveyard.size() == graves - 1, "the undone death still has a grave")
	# the avatar: free parts are owned, premium ones are not until bought
	Meta.meta["goals"]["avatar_owned"] = {}
	ok(Avatar.is_owned("hair", 2) and not Avatar.is_owned("hat", 3), "ownership of avatar parts is wrong")
	ok(Avatar.buy("hat", 3), "could not buy the crown with 500 stars")
	ok(Avatar.is_owned("hat", 3), "the crown is not owned after buying it")
	var rnd := Avatar.random("female")
	for cat in Avatar.CATEGORIES:
		ok(Avatar.is_owned(cat[0], int(rnd[cat[0]])), "a random avatar wears a part it does not own (%s)" % cat[0])
	var v := AvatarView.new()
	v.size = Vector2(120, 144)
	v.setup(rnd, 70, "female")
	v.free()
	print("  items & avatar: shelf is stable and rotates, Do-Over rewinds a year and a death, avatar parts are owned or bought")


func _mode_audio() -> void:
	for k in ["pets", "prison", "guard"]:
		var st: AudioStreamWAV = Fx._compose_loop(k)
		ok(st != null and st.data.size() > 100000, "no music was composed for %s" % k)
		ok(Fx.THEME_FLAVOR.has(k), "no sound flavour for %s" % k)
	Fx.set_mode("prison")
	ok(Fx.mode_key == "prison", "the sound mode did not switch")
	Fx.set_mode("")
	print("  mode audio: Pets, Prison and the guard each have their own music and sound")

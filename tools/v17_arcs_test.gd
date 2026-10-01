extends Node

## v1.0 gate — the six life paths have a road and an end.

var failures: Array = []
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V17: " + msg)


func _ready() -> void:
	seed(1717)
	_structure()
	_progress()
	_endings()
	_death()
	_events()
	print("V17 ARCS TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _life(path: String) -> void:
	var opts := {"gender": "female", "country": "uk", "life_path": path, "era": 1970}
	GameState.new_life(opts)
	var p := GameState.player
	p["age"] = 40
	p["money"] = 200000
	if path == "witch" or path == "super":
		# these wake at 13; the test wakes them directly
		Lives.become(path, {"side": "hero"})
	if path == "royal":
		Lives.life()["crowned"] = false


func _structure() -> void:
	ok(Arcs.ARCS.size() == 6, "expected six arcs, found %d" % Arcs.ARCS.size())
	for path in Arcs.ARCS.keys():
		var a: Dictionary = Arcs.ARCS[path]
		ok(a["chapters"].size() == 5, "%s has %d chapters" % [path, a["chapters"].size()])
		ok(a["endings"].size() >= 4, "%s has only %d endings" % [path, a["endings"].size()])
		ok((a["endings"][-1]["need"] as Array).is_empty(), "%s has no fallback ending" % path)
		var ids := {}
		for e in a["endings"]:
			ok(not ids.has(e["id"]), "%s repeats ending %s" % [path, e["id"]])
			ids[e["id"]] = true
			ok(str(e["text"]).length() > 60, "%s / %s has a thin ending" % [path, e["id"]])
			ok(str(e["epitaph"]) != "", "%s / %s has no epitaph" % [path, e["id"]])
		for i in range(a["chapters"].size()):
			var eid := "arc.%s.%d" % [path, i + 1]
			ok(ContentDB.events_by_id.has(eid), "%s has no turning-point event" % eid)
			if ContentDB.events_by_id.has(eid):
				var def: Dictionary = ContentDB.events_by_id[eid]
				ok(def["choices"].size() >= 3, "%s has fewer than three choices" % eid)
				for c in def["choices"]:
					ok(c["outcomes"].size() >= 2, "%s / %s has one outcome" % [eid, c["label"]])


## The needs of each chapter must be things a life of that path really has.
func _progress() -> void:
	for path in Arcs.ARCS.keys():
		_life(path)
		var l := Lives.life()
		ok(Lives.kind() == path, "could not start a %s life (got %s)" % [path, Lives.kind()])
		var opened := 0
		for ch in Arcs.chapters():
			var needs: Array = ch.get("need", ch.get("need_any", []))
			for n in needs:
				var f := str(n[0])
				if f in ["coven_n", "saves_heists", "has_nemesis", "overthrown"] or f.begins_with("c:") or f.begins_with("p:"):
					continue
				ok(l.has(f) or f in ["crowned", "revealed", "abdicated"], "%s chapter '%s' needs a field %s that the path never has" % [path, ch["title"], f])
		# push the life along and every chapter opens, in order
		match path:
			"pirate": l.merge({"raids": 3, "bounty": 40, "maps": 3, "rank": 4, "treasure": 90000}, true)
			"colonist": l.merge({"missions": 2, "discoveries": 3, "influence": 50, "contact": 70, "rank": 4}, true)
			"traveler": l.merge({"cover": 80, "jumps": 6, "artifacts": 4, "paradox": 55}, true)
			"royal": l.merge({"respect": 80, "decrees": 2, "crowned": true, "reign": 30}, true)
			"witch": l.merge({"spells": 70, "coven": ["a", "b", "c", "d"], "exposure": 55}, true)
			"super": l.merge({"saves": 2, "rep": 75, "nemesis": "X", "power": 70}, true)
		EventEngine.pending.clear()
		Arcs.yearly()
		ok(Arcs.current_index() == 5, "%s opened only %d of 5 chapters" % [path, Arcs.current_index()])
		ok(EventEngine.pending.size() >= 5, "%s queued only %d turning points" % [path, EventEngine.pending.size()])
		ok(GameState.get_counter("arc_" + path) == 5, "%s counted %d chapters" % [path, GameState.get_counter("arc_" + path)])
		ok(not Arcs.status_line().is_empty(), "%s has no status line" % path)
		ok(not (Arcs.menu()["info"] as Array).is_empty(), "%s has no road menu" % path)
		# they do not open twice
		EventEngine.pending.clear()
		Arcs.yearly()
		ok(EventEngine.pending.is_empty(), "%s reopened a chapter" % path)
	# a fresh life has not opened anything
	_life("pirate")
	Arcs.yearly()
	ok(Arcs.current_index() == 0, "a brand new pirate has already opened %d chapters" % Arcs.current_index())
	print("  progress: all six roads open in order")


func _endings() -> void:
	var seen := {}
	var cases := {
		"pirate": [["sea_legend", {"rank": 4}], ["hanged", {"bounty": 90}], ["mutiny", {"mutinies": 3}], ["retired_rich", {"treasure": 200000}], ["sea_grave", {}]],
		"colonist": [["contact", {"contact": 100}], ["founder", {"rank": 4}], ["lost_colony", {"oxygen": 5}], ["elder", {"influence": 80}], ["dome_grave", {"oxygen": 80}]],
		"traveler": [["erased", {"paradox": 100}], ["historian", {"artifacts": 9}], ["stranded", {"charge": 4}], ["wanderer", {"charge": 90}]],
		"royal": [["beloved", {"reign": 30, "respect": 80, "crowned": true}], ["deposed", {"overthrown": true}], ["abdicated", {"abdicated": true}], ["brief", {"crowned": true, "reign": 3, "respect": 40}], ["uncrowned", {}]],
		"witch": [["burned", {"exposure": 99}], ["ascended", {"spells": 130}], ["matriarch", {"coven": ["a", "b", "c", "d"]}], ["hedge", {}]],
		"super": [["icon", {"side": "hero", "rep": 80}], ["infamous", {"side": "villain", "rep": 80}], ["unmasked_fall", {"revealed": true, "rep": 10}], ["quiet", {"rep": 10}]],
	}
	for path in cases.keys():
		for case in cases[path]:
			_life(path)
			var l := Lives.life()
			# neutral baseline so a case only trips the ending it names
			l.merge({"exposure": 0, "spells": 0, "coven": [], "paradox": 0, "artifacts": 0, "charge": 90, "oxygen": 80, "contact": 0, "influence": 0, "rank": 0, "bounty": 0, "treasure": 0, "mutinies": 0, "rep": 0, "side": "hero", "revealed": false, "reign": 0, "respect": 50, "crowned": false, "abdicated": false}, true)
			l.merge(case[1], true)
			var e := Arcs.ending()
			ok(str(e["id"]) == str(case[0]), "%s: expected '%s' but got '%s'" % [path, case[0], e["id"]])
			seen[str(e["id"])] = true
	ok(seen.size() >= 22, "only %d distinct endings were reachable" % seen.size())
	print("  endings: %d distinct endings reachable" % seen.size())


func _death() -> void:
	_life("pirate")
	var l := Lives.life()
	l.merge({"rank": 4, "treasure": 80000}, true)
	GameState.player["age"] = 71
	var entry := GameState.finalize_death("old age")
	var end: Dictionary = entry.get("ending", {})
	ok(str(end.get("id", "")) == "sea_legend", "a legend's death carried ending '%s'" % end.get("id", ""))
	ok(str(entry["story"]).find(str(end.get("text", "?"))) != -1, "the ending is not in the life story")
	var stone := Tombstone.new()
	stone.setup(entry, entry["ribbon"], GameState.player)
	ok(stone.epitaph == str(end["epitaph"]), "the tombstone ignores the ending: '%s'" % stone.epitaph)
	ok(GameState.get_counter("ending_sea_legend") == 1, "the ending was not counted for achievements")
	# an overthrown monarch keeps the ending even after the crown is gone
	_life("royal")
	var rl := Lives.life()
	rl.merge({"crowned": true, "reign": 6, "respect": 20}, true)
	Arcs.freeze("overthrown")
	GameState.player["life"] = {"type": "human", "exroyal": true}
	GameState.player["age"] = 66
	var e2 := GameState.finalize_death("old age")
	ok(str(e2.get("ending", {}).get("id", "")) == "deposed", "an overthrown monarch did not get the Deposed ending: %s" % e2.get("ending", {}))
	# an ordinary life has none
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 80
	var e3 := GameState.finalize_death("old age")
	ok(not e3.has("ending"), "an ordinary life was given a path ending")
	print("  death: ending carried into the story, tombstone and counters")


func _events() -> void:
	# play every chapter event, every choice, on a life of its path
	var played := 0
	for path in Arcs.ARCS.keys():
		for n in range(1, 6):
			var def: Dictionary = ContentDB.events_by_id["arc.%s.%d" % [path, n]]
			for ci in range(def["choices"].size()):
				_life(path)
				var l := Lives.life()
				var before := l.duplicate(true)
				var r := EventEngine.resolve({"def": def, "roles": {}}, ci)
				ok(str(r.get("text", "")) != "", "%s choice %d gave no text" % [def["id"], ci])
				ok(GameState.is_alive(), "%s choice %d killed the player" % [def["id"], ci])
				played += 1
				EventEngine.pending.clear()
	ok(played == 90, "played %d of 90 chapter choices" % played)
	# arc operations really move the life record and stay in range
	_life("colonist")
	Lives.life()["oxygen"] = 90
	Arcs.apply({"oxygen": 50})
	ok(int(Lives.life()["oxygen"]) == 100, "a gauge went past 100: %d" % int(Lives.life()["oxygen"]))
	Arcs.apply({"oxygen": -400})
	ok(int(Lives.life()["oxygen"]) == 0, "a gauge went below 0")
	print("  events: %d chapter choices resolved" % played)

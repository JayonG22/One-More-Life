extends Node

## v0.12 gate — content depth and the tombstone.

var failures: Array = []
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V12: " + msg)


func _ready() -> void:
	seed(1212)
	# ---- everyday.json must fully meet the design rule
	var raw := FileAccess.get_file_as_string("res://data/events/everyday.json")
	var evs = JSON.parse_string(raw)
	ok(evs is Array and (evs as Array).size() == 100, "everyday.json did not load as 100 events")
	var single := 0
	var thin := 0
	var outs := 0
	var chs := 0
	for ev in evs:
		var cs: Array = ev.get("choices", [])
		if cs.size() < 3:
			thin += 1
		for ch in cs:
			chs += 1
			var o: Array = ch.get("outcomes", [])
			outs += o.size()
			if o.size() <= 1:
				single += 1
			for oc in o:
				ok(str(oc.get("text", "")) != "", "an outcome in %s has no text" % ev.get("id", "?"))
	ok(single == 0, "%d choices in everyday.json still have exactly one outcome" % single)
	ok(thin == 0, "%d events in everyday.json still have fewer than 3 choices" % thin)
	ok(chs >= 300, "everyday.json has only %d choices" % chs)
	ok(outs >= 600, "everyday.json has only %d outcomes" % outs)

	# ---- whole-library direction of travel
	var total := 0
	var det := 0
	for f in ["childhood", "teen", "adult", "elder", "life", "more", "everyday", "family", "work", "school", "money", "law", "careers", "careers2", "connections", "empires", "lives", "twists", "fame", "prison", "v07", "v08"]:
		var txt := FileAccess.get_file_as_string("res://data/events/%s.json" % f)
		if txt == "":
			continue
		var list = JSON.parse_string(txt)
		if not (list is Array):
			continue
		for ev in list:
			for ch in ev.get("choices", []):
				total += 1
				if (ch.get("outcomes", []) as Array).size() <= 1:
					det += 1
	var pct := 100.0 * float(det) / maxf(1.0, float(total))
	ok(pct < 50.0, "the library is still %.1f%% deterministic; it was 55.9%%" % pct)
	print("  library: %d choices, %d deterministic (%.1f%%)" % [total, det, pct])

	# ---- the tombstone must differ by life
	var seen := {}
	var cases := [
		[9, 2000, 10, 0.0, "human", []], [61, 300, -5, 0.0, "human", []],
		[78, 9000000, 20, 40.0, "human", []], [52, 9000, -70, 5.0, "human", ["fraud"]],
		[340, 900000, -20, 10.0, "vampire", []], [84, 40000000, 30, 95.0, "royal", []],
		[97, 60000, 40, 0.0, "human", []],
	]
	for c in cases:
		GameState.new_life({"country": "us"})
		var p := GameState.player
		p["age"] = int(c[0])
		p["money"] = int(c[1])
		p["karma"] = int(c[2])
		p["fame"] = float(c[3])
		p["life"] = {"type": str(c[4])}
		p["record"] = c[5]
		p["legacy"] = {"net": int(c[1])}
		var st := Tombstone.new()
		st.setup({"name": "A", "born": 1900, "died": 1900 + int(c[0]), "age": int(c[0]), "cause": "x"}, {"icon": "", "name": ""}, p)
		seen[st.shape] = true
		ok(st.epitaph != "", "a life produced no epitaph")
		ok(st.ornament != "", "a life produced no ornament")
		st.free()
	ok(seen.size() >= 5, "only %d different stone shapes across seven very different lives" % seen.size())
	print("  stone shapes seen: ", seen.keys())

	print("V12 CONTENT TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

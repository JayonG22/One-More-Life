extends Node
## Measures how many popups a year produces, and where they come from.
var by_src := {}
var per_year := []
func _ready() -> void:
	seed(77)
	Meta.meta["recent"] = {}
	var total := 0
	var lives := int(OS.get_environment("LIVES")) if OS.get_environment("LIVES") != "" else 6
	for L in lives:
		SaveManager.begin_new_life()
		GameState.new_life({"gender": "female" if L % 2 == 0 else "male", "country": ["us", "uk", "ca"][L % 3]})
		var yrs := 0
		while GameState.is_alive() and yrs < 90:
			yrs += 1
			EventEngine.age_up()
			var n := EventEngine.pending.size()
			if n > 0 and per_year.size() < 3: print('year ', yrs, ' pending ', n)
			per_year.append(n)
			for it in EventEngine.pending:
				if not it.has("def"):
					continue
				var id := str(it["def"]["id"])
				var src := id.get_slice(".", 0) if "." in id else ("_sys" if id.begins_with("_") else id)
				by_src[src] = int(by_src.get(src, 0)) + 1
			total += n
			# resolve: first choice
			var guard := 0
			while EventEngine.has_pending() and guard < 40 and GameState.is_alive():
				guard += 1
				var inst := EventEngine.pop_next()
				if inst.get("info", false):
					continue
				var chs: Array = inst["def"].get("choices", [])
				for ci in range(chs.size()):
					var st := EventEngine.choice_state(chs[ci], inst.get("roles", {}))
					if st["visible"] and st["enabled"]:
						EventEngine.resolve(inst, ci)
						break
	per_year.sort()
	var keys := by_src.keys()
	keys.sort_custom(func(a, b): return by_src[a] > by_src[b])
	var top := []
	for k in keys.slice(0, 18):
		top.append("%s=%d" % [k, by_src[k]])
	print("PROBE years=%d popups=%d avg=%.2f p50=%d p90=%d max=%d" % [per_year.size(), total, float(total) / per_year.size(), per_year[per_year.size() / 2], per_year[int(per_year.size() * 0.9)], per_year[-1]])
	print("PROBE sources: ", ", ".join(top))
	get_tree().quit()

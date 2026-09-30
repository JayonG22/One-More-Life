extends Node

## Turning Points: rare events that rewrite a run. Each can happen once per life.

func yearly() -> void:
	var p := GameState.player
	var age: int = p["age"]
	if age < 6 or not GameState.is_alive():
		return
	var base := 0.012 if age < 12 else (0.025 if age < 18 else (0.045 if age < 70 else 0.03))
	if GameState.get_counter("twists") == 0 and age >= 25:
		base *= 2.0
	if randf() >= base * Grit.d("twist"):
		return
	fire()


func fire(force_id: String = "") -> bool:
	var pool: Array = []
	for def in ContentDB.events:
		if not def.get("twist", false) or (def.get("followup_only", false) and force_id == ""):
			continue
		if force_id != "" and def["id"] != force_id:
			continue
		if GameState.event_history.has(def["id"]) and force_id == "":
			continue
		if EventEngine._eligible(def, force_id != ""):
			pool.append(def)
	var guard := 0
	while not pool.is_empty() and guard < 12:
		guard += 1
		var def := EventEngine._weighted_pick(pool, "weight")
		pool.erase(def)
		var before: int = EventEngine.pending.size()
		if EventEngine._enqueue(def, {}):
			if EventEngine.pending.size() > before:
				var inst = EventEngine.pending.pop_back()
				EventEngine.pending.push_front(inst)
			GameState.counter("twists")
			return true
	return false

extends Node

var callback_library: Dictionary = {}

func _ready() -> void:
	callback_library = ContentDB._load_json("res://data/choice_callbacks.json",{})

func state() -> Dictionary:
	if not GameState.player.has("insight"): GameState.player["insight"] = {"history":[], "callbacks":[], "seen":{}}
	return GameState.player["insight"]

func snapshot(people: Array = []) -> Dictionary:
	var p := GameState.player
	var stats := {}
	for key in GameState.STAT_KEYS: stats[key] = GameState.stat(key)
	var bonds := {}
	var bond_values := {}
	for id in GameState.npcs:
		bonds[id] = int(GameState.npcs[id].get("closeness",0))
		bond_values[id] = GameState.npcs[id].get("bond",{}).duplicate(true)
	var people_stats := {}
	for person_id0 in people:
		var person_id := str(person_id0)
		if not GameState.npcs.has(person_id): continue
		var person: Dictionary = GameState.npcs[person_id]
		var tracked := {}
		for key in ["happiness", "stress", "health", "smarts"]:
			if person.has(key): tracked[key] = float(person[key])
		if not tracked.is_empty():
			people_stats[person_id] = {"name":GameState.full_name(person_id), "stats":tracked}
	return {"owner":FamilyChronicle.identity(p), "money":int(p["money"]), "time":int(p["time_left"]), "stats":stats, "bonds":bonds, "bond_values":bond_values, "people":people_stats, "job":GameState.occupation_label(), "school":float(p["education"].get("performance",0)), "work":float(p.get("job",{}).get("perf",0)), "followups":GameState.followups.size()}

func deltas(before: Dictionary) -> Array:
	if before.is_empty() or not GameState.has_life(): return []
	var after := snapshot(Array(before.get("people", {}).keys()))
	if after["owner"] != before["owner"]: return []
	var lines: Array = []
	if after["money"] != before["money"]: lines.append("Cash %s" % GameState.fmt_money(int(after["money"])-int(before["money"])))
	if after["time"] != before["time"]: lines.append("Time %+.0f" % (int(after["time"])-int(before["time"])))
	for key in GameState.STAT_KEYS:
		var delta := float(after["stats"][key])-float(before["stats"][key])
		if absf(delta) >= 0.05: lines.append("%s %+.1f" % [str(key).capitalize(),delta])
	for id in before["bonds"]:
		if after["bonds"].has(id) and after["bonds"][id] != before["bonds"][id]: lines.append("%s · closeness %+d" % [GameState.full_name(id), int(after["bonds"][id])-int(before["bonds"][id])])
		for key in before["bond_values"].get(id,{}):
			if not after["bond_values"].get(id,{}).has(key): continue
			var delta := float(after["bond_values"][id][key])-float(before["bond_values"][id][key])
			if absf(delta)>=0.05: lines.append("%s · %s %+.1f" % [GameState.full_name(id),str(key).capitalize(),delta])
	for id in before.get("people", {}):
		if not after.get("people", {}).has(id): continue
		var person_before: Dictionary = before["people"][id]
		var person_after: Dictionary = after["people"][id]
		for key in person_before.get("stats", {}):
			if not person_after.get("stats", {}).has(key): continue
			var person_delta := float(person_after["stats"][key])-float(person_before["stats"][key])
			if absf(person_delta)>=0.05: lines.append("%s · %s %+.1f" % [str(person_before.get("name", "Someone")),str(key).capitalize(),person_delta])
	if after["job"] != before["job"]: lines.append("Occupation: " + str(after["job"]))
	for key in ["school","work"]:
		var delta := float(after[key])-float(before[key])
		if absf(delta) >= 0.05: lines.append("%s performance %+.1f" % [key.capitalize(),delta])
	if int(after["followups"]) > int(before["followups"]): lines.append("A later consequence was scheduled.")
	return lines

func record(before: Dictionary, title: String, reason: String = "", targets: Array = []) -> void:
	if before.is_empty() or not GameState.has_life() or snapshot()["owner"]!=before["owner"]: return
	var lines := deltas(before)
	if lines.is_empty() and reason == "": return
	var history: Array = state()["history"]
	var months := int(LifeCourse.state()["months"])
	var people: Array = []
	for target in targets:
		var person_id := str(target)
		if not person_id.is_empty() and GameState.npcs.has(person_id) and not people.has(person_id):
			people.append(person_id)
	history.append({"age":maxi(int(GameState.player["age"]),months/12),"month":months%12,"title":title,"changes":lines,"reason":reason,"targets":people})
	state()["history"] = history.slice(-80)

func remember_choice(def: Dictionary, index: int) -> void:
	var id := str(def.get("id",""))
	var all := callback_library
	if not all.has(id) or state()["seen"].has(id): return
	state()["seen"][id] = true
	var branch: Dictionary = all[id][index]
	state()["callbacks"].append({"source":str(def["title"]),"choice":str(def["choices"][index]["label"]),"age":int(GameState.player["age"])+2,"branch":branch,"id":id})

func yearly() -> void:
	if Lives.separate() or Lives.is_type("tv"): return
	var keep: Array = []
	var offered := false
	for entry in state()["callbacks"]:
		if int(entry["age"]) > int(GameState.player["age"]) or offered:
			keep.append(entry)
			continue
		var branch: Dictionary = entry["branch"]
		EventEngine.push_decision({"id":"_remembered_"+str(entry["id"]),"icon":"🧭","title":branch["title"],"text":"Earlier, during %s, you chose: %s.\n\n%s" % [entry["source"],entry["choice"],branch["text"]],"choices":branch["choices"],"no_friction":true})
		offered = true
	state()["callbacks"] = keep

func upcoming() -> Array:
	var lines: Array = []
	for entry in state()["callbacks"]: lines.append("Around age %d · follow-up to %s: %s" % [int(entry["age"]),entry["source"],entry["choice"]])
	for entry in GameState.followups:
		var def: Dictionary = ContentDB.events_by_id.get(entry.get("event",""),{})
		lines.append("Age %d or later · %s" % [int(entry.get("age",0)),str(def.get("title","An earlier decision"))])
	return lines

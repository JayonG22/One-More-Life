extends Node

## Authored context is a filter, not a promise that an event will fire.
## Seasons describe the part of the simulated year that stood out, never today's date.
const KEYS := ["country", "region", "climate", "season", "weather", "field", "major", "current_major", "timeline", "lifestyle_any", "lifestyle_all"]
const LIFESTYLES := ["active", "studious", "family", "social", "gambling", "working", "job_seeking", "retired", "university", "frail", "stressed", "wealthy", "struggling", "caregiver"]


func lifestyles() -> Array:
	var p := GameState.player
	var out: Array = []
	var r: Dictionary = p.get("routines", {})
	if r.get("gym", false) or r.get("walk", false) or GameState.has_trait("Athletic"): out.append("active")
	if r.get("study", false) or GameState.in_university(): out.append("studious")
	if r.get("family", false) or not GameState.npcs_with("child").is_empty(): out.append("family")
	if GameState.has_trait("Charmer") or GameState.npcs_with("friend").size() >= 3: out.append("social")
	if Grit.active_habits().has("gambling"): out.append("gambling")
	if GameState.has_job(): out.append("working")
	elif int(p.get("age", 0)) >= 18 and not GameState.in_university() and not p.get("retired", false) and not Lives.separate(): out.append("job_seeking")
	if p.get("retired", false): out.append("retired")
	if GameState.in_university(): out.append("university")
	if GameState.stat("health") < 40.0: out.append("frail")
	if GameState.stat("stress") > 70.0: out.append("stressed")
	if GameState.net_worth() >= 1000000: out.append("wealthy")
	if int(p.get("money", 0)) < 500: out.append("struggling")
	for id in GameState.npcs_with("child"):
		if int(GameState.npc(str(id)).get("age", 18)) < 6:
			out.append("caregiver")
			break
	return out


func matches(c: Dictionary) -> bool:
	if c.is_empty(): return true
	var p := GameState.player
	var weather := Climate.snapshot()
	var majors: Array = []
	for d in p.get("education", {}).get("degrees", []): majors.append(str(d["major"]))
	var uni: Dictionary = p.get("education", {}).get("uni", {})
	if not uni.is_empty(): majors.append(str(uni.get("major", "")))
	var values := {"current_major": str(uni.get("major", "")), "timeline": str(Lives.life().get("era", "")), "country": str(p.get("country", "")), "region": str(p.get("region", "")), "climate": Climate.climate_id(),
		"season": str(weather.get("season", "")), "weather": str(weather.get("weather", "")), "field": str(p.get("job", {}).get("field", ""))}
	var tags := lifestyles()
	for key in c.keys():
		var wants: Array = c[key] if c[key] is Array else [c[key]]
		if not KEYS.has(key) or wants.is_empty(): return false
		match str(key):
			"major":
				if not wants.any(func(v): return majors.has(str(v))): return false
			"lifestyle_any":
				if not wants.any(func(v): return tags.has(str(v))): return false
			"lifestyle_all":
				if not wants.all(func(v): return tags.has(str(v))): return false
			_:
				if not wants.has(values[key]): return false
	return true


## Explicit event metadata keeps incompatible settings out of the pool.
## Human relationships remain possible for supernatural lives, but terrestrial
## commuter scenes do not follow a pirate onto a ship or a colonist to Mars.
func world_matches(def: Dictionary) -> bool:
	var c: Dictionary = def.get("conditions", {})
	var path := Lives.kind()
	if path in ["pirate", "colonist"] and not c.has("life"):
		return false
	if path == "traveler":
		if def.has("available_from") and Expansion.era_year() < int(def["available_from"]): return false
		if def.has("available_until") and Expansion.era_year() > int(def["available_until"]): return false
	return true


func focus(def: Dictionary) -> bool:
	var c: Dictionary = def.get("conditions", {})
	if Lives.kind() != "human" and c.has("life"):
		var ls: Array = c["life"] if c["life"] is Array else [c["life"]]
		if ls.has(Lives.kind()): return true
	if not GameState.player.get("career", {}).is_empty() and c.has("career"): return true
	if GameState.has_job() and (c.has("job") or c.has("job_id") or c.get("context", {}).has("field")): return true
	return false

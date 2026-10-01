extends Node

func _ready() -> void:
	seed(2020)
	for role in ["prisoner", "guard"]:
		for sk in (Prison.PRISONER_STORIES.keys() if role == "prisoner" else Prison.GUARD_STORIES.keys()):
			GameState.new_life({"first": "Test", "last": "Person", "gender": "male", "country": "us", "life_path": role, "keep_family": true, "story": sk})
			var n := 0
			while GameState.is_alive() and n < 60:
				n += 1
				for mk in ["home", "routine", "jobs", "programs", "hustle", "people", "gang", "case", "plan", "post", "block", "career", "integrity"]:
					var m: Dictionary = Prison.menu(mk)
					for r in m["rows"]:
						if bool(r.get("on", true)) and r.has("act") and GameState.is_alive():
							GameState.player["time_left"] = 12
							GameState.player["act_year"] = {}
							Prison.act(str(r["act"]).substr(3), r.get("arg", null))
							while EventEngine.has_pending():
								var inst: Dictionary = EventEngine.pop_next()
								if not inst.get("info", false):
									EventEngine.resolve(inst, 0)
				EventEngine.age_up()
				while EventEngine.has_pending():
					var inst2: Dictionary = EventEngine.pop_next()
					if not inst2.get("info", false):
						EventEngine.resolve(inst2, randi() % inst2["def"]["choices"].size())
			print("%s/%s: ended at %d after %d turns: %s | %s" % [role, sk, GameState.player["age"], n, GameState.player["cause"], str(Arcs.ending().get("title", "?"))])
	print("SMOKE DONE")
	get_tree().quit()

extends Node
## The v0.25 event batch: every outcome of every new event applies cleanly and reads clean,
## and each job event is eligible for someone doing that job.
const FILES := ["jobs_a.json", "jobs_b.json", "jobs_c.json", "life_a.json", "life_b.json", "contextual.json", "contextual_echoes.json"]
var checks := 0
var failures: Array = []


func ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		failures.append(m)


func _fresh() -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	var p := GameState.player
	p["age"] = 34
	p["money"] = 500000
	p["time_left"] = 12
	for k in ["happiness", "health", "smarts", "looks"]:
		p["stats"][k] = 70.0
	p["stats"]["stress"] = 20.0


func _ready() -> void:
	seed(2525)
	var defs: Array = []
	for f in FILES:
		defs.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://data/events/" + f)))
	var jobs: Dictionary = {}
	for j in JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs.json")):
		jobs[j["id"]] = j
	var by_job := {}
	var applied := 0
	for def in defs:
		_fresh()
		var cond: Dictionary = def["conditions"]
		if cond.has("job"):
			var jb: Dictionary = jobs[cond["job"]]
			GameState.player["job"] = {"id": jb["id"], "title": jb["ranks"][0], "field": jb["field"], "salary": jb["salary"], "perf": 55.0, "years": 3, "boss": "", "coworkers": []}
			by_job[cond["job"]] = int(by_job.get(cond["job"], 0)) + 1
			ok(EventEngine._eligible(def, false), "%s is not eligible for someone doing that job" % def["id"])
		var roles: Dictionary = EventEngine._build_roles(def, {})
		for ch in def["choices"]:
			for o in ch["outcomes"]:
				_fresh()
				if cond.has("job"):
					var jb2: Dictionary = jobs[cond["job"]]
					GameState.player["job"] = {"id": jb2["id"], "title": jb2["ranks"][0], "field": jb2["field"], "salary": jb2["salary"], "perf": 55.0, "years": 3, "boss": "", "coworkers": []}
				var r: Dictionary = EventEngine._apply_outcome(o, roles, def)
				applied += 1
				var txt := str(r.get("text", ""))
				ok(txt != "" and txt.find("{") == -1 and txt.find("}") == -1, "%s has an unfilled token: %s" % [def["id"], txt.substr(0, 80)])
	for jid in jobs.keys():
		# Recorded NPC occupations are imported on viewpoint transfer; they are
		# not advertised careers and use the existing general workplace events.
		if jobs[jid].get("inherited_only", false): continue
		ok(int(by_job.get(jid, 0)) >= 2, "job %s has fewer than two events" % jid)
	print("V25 EVENTS TEST defs=%d outcomes=%d checks=%d failures=%d" % [defs.size(), applied, checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

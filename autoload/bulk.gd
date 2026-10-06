extends Node

# Bundles run existing actions, including their penalties and earned rewards.
const PACKS := {
	"fitness":{"group":"mind","name":"Fitness","items":["gym","yoga","walk"],"min":12,"fee":160,"extras":40,"time":3},
	"calm":{"group":"mind","name":"Walk & unwind","items":["walk","meditate"],"min":8,"fee":100,"extras":0,"time":2},
	"fun":{"group":"fun","name":"Movie & games","items":["movie","games"],"min":5,"fee":80,"extras":15,"time":2},
	"learning":{"group":"education","name":"Study","items":["read","meditate"],"min":8,"fee":150,"extras":0,"time":3,"quiz":true},
	"reading":{"group":"education","name":"Read & library","items":["read","library"],"min":6,"fee":100,"extras":0,"time":2},
	"care":{"group":"health","name":"Therapy & salon","items":["therapy","spa"],"min":18,"fee":180,"extras":200,"time":2},
	"work":{"group":"work","name":"Work prep","items":["read","meditate"],"min":13,"fee":250,"extras":0,"time":3},
	"home":{"group":"home","name":"Chores & rest","items":[],"min":18,"fee":150,"extras":0,"time":3},
}

func price(id: String) -> int:
	if not PACKS.has(id): return 0
	return Actions._cost(int(PACKS[id]["fee"]))+Actions._cost(int(PACKS[id]["extras"]))

func reason(id: String) -> String:
	if not PACKS.has(id): return "Unknown bundle"
	var p := GameState.player
	var d: Dictionary = PACKS[id]
	if not GameState.is_alive() or Lives.separate() or Lives.is_type("tv"): return "Available in an active human life"
	if GameState.in_prison(): return "Not available in custody"
	if int(p["age"])<int(d["min"]): return "Age %d+" % int(d["min"])
	if int(p.get("bulk_used",{}).get(id,-1))==GameState.year_now(): return "Done this year"
	if not Depth.state()["active"].is_empty(): return "Finish your current challenge first"
	if EventEngine.has_pending() or EventEngine.displayed.has("def"): return "Finish your current event first"
	if id=="work" and (not GameState.has_job() or bool(p["job"].get("worked_hard",false))): return "Get a job; Work harder must be unused"
	if d.get("quiz",false):
		if not GameState.in_school() and not GameState.in_university(): return "Enrol in school first"
		var subjects: Array=Journey.modules["campus"].subjects()
		if subjects.is_empty(): return "No current class"
		var subject := str(subjects[0]["subject"])
		if Journey.used("class:"+Journey.modules["campus"].level()+":"+subject+"true"): return "Assessment used this year"
		if not subjects[0]["questions"].any(func(q): return Novelty.eligible(q)): return "Assessment questions complete; class practice remains"
	if id=="home":
		var h := Household.state()
		if int(h["completed_year"])==GameState.year_now()+1 or int(h.get("rest_year",-1))==GameState.year_now(): return "Chores or rest already used this year"
	for activity in d["items"]:
		for group in Actions.ACTIVITY_GROUPS:
			for item in group["items"]:
				if item["id"]==activity and not Actions.activity_available(item): return "One included activity is unavailable in this era"
		var blocked := World.blocked(str(activity))
		if blocked!="": return blocked
	if int(p["time_left"])<int(d["time"]): return "Needs %d time; you have %d" % [int(d["time"]),int(p["time_left"])]
	if int(p["money"])<price(id): return "Needs "+GameState.fmt_money(price(id))
	return ""

func menu(group: String) -> Dictionary:
	if group=="edu": group="education"
	var rows: Array = []
	for id in PACKS:
		var d: Dictionary = PACKS[id]
		if d["group"]!=group: continue
		var why := reason(id)
		var components := ", ".join(d["items"])
		if id=="home": components="chores + rest"
		if id=="work": components+=" + work harder"
		if d.get("quiz",false): components+=" + current-stage assessment"
		rows.append({"icon":"🧺","name":d["name"],"sub":"%s\n%d time · %s incl. fee · Once a year%s" % [components,int(d["time"]),GameState.fmt_money(price(id)),("\n"+why) if why!="" else ""],"act":"bulk:run","arg":id,"on":why==""})
	return {"rows":rows}

func act(key: String, arg = null) -> void:
	if key!="run": return
	var id := str(arg)
	var why := reason(id)
	if why!="":
		EventEngine.push_info("🧺","Bundle unavailable",why)
		return
	var d: Dictionary = PACKS[id]
	var p := GameState.player
	var before := Insight.snapshot()
	if not p.has("bulk_used"): p["bulk_used"]={}
	p["bulk_used"][id]=GameState.year_now()
	GameState.apply_effects({"money":-Actions._cost(int(d["fee"]))})
	var preferences: Dictionary = p.get("activity_lengths",{}).duplicate(true)
	var previously_blocked := EventEngine.is_blocking_signals()
	EventEngine.set_block_signals(true)
	for activity in d["items"]: Actions.do_activity_for(str(activity),1 if Actions.DURATIONS.has(activity) else -1)
	p["activity_lengths"]=preferences
	if id=="home":
		Household.act("complete")
		Household.act("rest")
	if id=="work": Actions.work_harder()
	var reports: Array = []
	# Preflight ensures the queue is ours; never discard another pending decision.
	while not EventEngine.pending.is_empty() and EventEngine.pending[0].has("info"):
		var result: Dictionary = EventEngine.pending.pop_front()
		reports.append(str(result.get("text","")))
	reports.reverse()
	EventEngine.set_block_signals(previously_blocked)
	var changes := Insight.deltas(before)
	var summary := "Completed %s. Total cost: %s; %d time.\n\n%s" % [d["name"],GameState.fmt_money(price(id)),int(d["time"]),"\n\n".join(reports)]
	# The quiz is played normally; no score or mastery is invented by the bundle.
	if d.get("quiz",false): Actions.study_harder()
	if d.get("quiz",false): summary+="\nReading and concentration preparation are complete. Your quiz reward still depends on your answers."
	GameState.add_log("I completed "+str(d["name"])+" as a paid bundle.")
	EventEngine.push_info("🧺",d["name"],summary+"\n\n"+" · ".join(changes))
	GameState.emit_changed()
	SaveManager.save_game()

extends RefCounted
## Paid workplace choices retain their person, post, roll and review date.
var h
var scenes: Array = []

func _init(employment):
	h = employment
	scenes = ContentDB._load_json("res://data/career_growth.json", [])

func st() -> Dictionary:
	var s: Dictionary = h.st()
	if not s.has("growth"): s["growth"] = {"active":{}, "history":[], "seen":[]}
	return s["growth"]

func reason() -> String:
	var why: String = h.blocked()
	if why != "": return why
	if not GameState.has_job(): return "Get a job first"
	if not st()["active"].is_empty(): return "Review pending"
	if h.used("growth"): return "One decision per year"
	if int(GameState.player["time_left"]) < 2: return "Needs 2 time"
	var field: String = str(GameState.player["job"]["field"])
	if str(h.st()["specialties"].get(field, "")) == "": return "Choose a speciality first"
	if Workplace.crew().is_empty(): return "Needs an available colleague"
	if pool().is_empty(): return "All current cases encountered"
	return ""

func pool() -> Array:
	var result: Array = []
	if not GameState.has_job(): return result
	var route: String = str(h.st()["specialties"].get(str(GameState.player["job"]["field"]), ""))
	for scene in scenes:
		if scene["route"] == route and not str(scene["id"]) in st()["seen"] and Novelty.eligible(scene): result.append(scene)
	return result

func start() -> void:
	if reason() != "": return
	var scene: Dictionary = Novelty.pick(pool())
	if scene.is_empty() or not GameState.spend_time(2): return
	var crew: Array = Workplace.crew()
	var person: String = str(crew[randi() % crew.size()])
	var field: String = str(GameState.player["job"]["field"])
	var token: int = h.serial()
	var case: Dictionary = {"scene":scene.duplicate(true), "session":h.job_session(), "field":field, "person":FamilyChronicle.identity(GameState.npc(person)), "name":GameState.full_name(person), "due":GameState.year_now()+1, "roll":randf(), "token":token, "answer":-1, "started":GameState.year_now()}
	st()["active"] = case
	st()["seen"].append(str(scene["id"]))
	h.mark("growth")
	Novelty.note(scene)
	var choices: Array = []
	for i in range(3):
		var option: Dictionary = scene["options"][i]
		choices.append(h.choice(str(option["label"])+" · %d%%" % int(chance(case, option)*100), "growth", token, 0, i))
	h.push_prompt("growth", token, 0, str(scene["title"]), str(case["name"])+": "+str(scene["text"])+"\n2 time spent · review next year · chance uses readiness and skill.", choices)

func chance(case: Dictionary, option: Dictionary) -> float:
	return Aptitude.chance(float(option["chance"])+Market.skill(str(case["field"]))*0.02, "work")

func valid(case: Dictionary) -> bool:
	var person: String = Journey.person(str(case["person"]))
	return GameState.has_job() and not GameState.in_prison() and h.job_session()==int(case["session"]) and person!="" and GameState.npc(person).get("alive",false) and person in Workplace.crew()

func resolve(prompt: Dictionary, answer: int) -> void:
	var case: Dictionary = st()["active"]
	if case.is_empty() or int(case["token"]) != int(prompt["token"]) or int(case["answer"]) != -1: return
	if not valid(case): close("Work or colleague changed; no award."); return
	var option: Dictionary = case["scene"]["options"][answer]
	case["answer"] = answer
	case["chance"] = chance(case, option)
	var person: String = Journey.person(str(case["person"]))
	BondStats.apply(person, {"trust":option["trust"], "respect":option["respect"]})
	var n: Dictionary = GameState.npc(person)
	n["stress"] = clampf(float(n.get("stress",0))+float(option["npc_stress"]),0,100)
	GameState.apply_effects({"stress":option["stress"], "job_perf":option["perf"]})
	FamilyChronicle.remember(person, str(case["scene"]["title"])+": "+str(option["label"]), "good" if int(option["trust"])>0 else "neutral")
	EventEngine.push_info("🧭", "Plan recorded", str(option["now"])+"\nReview in "+str(case["due"])+". No skill or reputation awarded yet.")

func yearly() -> void:
	var case: Dictionary = st()["active"]
	if case.is_empty(): return
	if not valid(case): close("Work or colleague changed; no award."); return
	if GameState.year_now() < int(case["due"]): return
	if int(case["answer"])<0: close("No plan chosen; no award."); return
	var option: Dictionary = case["scene"]["options"][int(case["answer"])]
	var success: bool = float(case["roll"]) < float(case["chance"])
	var person: String = Journey.person(str(case["person"]))
	var result: String = str(option["success"] if success else option["failure"])
	GameState.apply_effects({"job_perf":3 if success else -2, "stress":-2 if success else 3})
	var record: Dictionary = h.record(str(case["field"]))
	record["reputation"] = clampf(float(record["reputation"])+(3 if success else -2),0,100)
	if success: Market.learn(str(case["field"]),1)
	BondStats.apply(person, {"respect":3 if success else -2})
	FamilyChronicle.remember(person, result, "good" if success else "bad")
	GameState.add_log(str(case["scene"]["title"])+" · "+str(case["name"])+": "+result)
	close(result)

func close(result: String) -> void:
	var case: Dictionary = st()["active"]
	if case.is_empty(): return
	case["result"] = result
	case["closed"] = GameState.year_now()
	st()["history"].push_front(case)
	while st()["history"].size()>36: st()["history"].pop_back()
	st()["active"] = {}
	if str(h.st()["prompt"].get("kind",""))=="growth": h.st()["prompt"]={}

func menu() -> Dictionary:
	var info: Array = ["Speciality choices · 2 time · one per year", "Named colleague, lasting trust and next-year review."]
	var rows: Array = []
	var case: Dictionary = st()["active"]
	if not case.is_empty():
		info.append(str(case["scene"]["title"])+" · "+str(case["name"])+" · review "+str(case["due"]))
		var person: String = Journey.person(str(case["person"]))
		if person!="": rows.append({"icon":Bonds.U_face(GameState.npc(person)), "name":str(case["name"]), "sub":Bonds.quick_line(person), "menu":"bond:"+person})
	var why: String = reason()
	rows.append(h.row("Speciality decision", why if why!="" else "2 time · three approaches", "growth", null, why=="", "🧭"))
	for entry in st()["history"].slice(0,6):
		info.append(str(entry["scene"]["title"])+": "+str(entry["result"]))
	return {"icon":"🧭", "title":"Speciality decisions", "info":info, "rows":rows}

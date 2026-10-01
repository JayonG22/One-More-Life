extends Node

## PRISON LIFE — v1.2. Two doors into one building.
##
## You are either serving a sentence or working the walls, and the building is the
## same either way: one facility with a tension that rises and falls, four gangs
## that want things, a warden who wants something else, and a count at four
## o'clock that must come out right. A riot is a riot from both sides of the door.
## What it is *for* you depends on which side you are on.
##
## Both roles are the person who walked in, with a family outside it that goes on
## without them. Nothing here is a reskin of a human system: there is no job
## market, no mortgage, no ladder to a career. There is standing, protection,
## conduct, an appeal, a plan, a rank, a price, and a number of years.
##
## Life kinds: "prisoner" and "guard". A guard who is caught taking money becomes
## a prisoner in the same building, which is the oldest story the place has.

const PRISONER_STORIES := {
	"first": {"name": "A first offence", "icon": "🔑", "desc": "A burglary that went wrong. Four years, a minimum-security dorm, and no idea how any of this works.", "crime": "burglary", "years": [3, 5], "security": "medium", "age": [19, 32], "respect": 10, "innocent": false, "eligible": 0.5},
	"career": {"name": "A career criminal", "icon": "🃏", "desc": "Armed robbery, and a record that was a warning. Twelve years. You know how it works; it knows you.", "crime": "armed robbery", "years": [9, 14], "security": "medium", "age": [26, 45], "respect": 30, "innocent": false, "eligible": 0.6},
	"gang": {"name": "A gang member", "icon": "🔗", "desc": "Conspiracy and a name that carries. You arrive with friends, and with enemies you did not choose.", "crime": "conspiracy to supply", "years": [8, 12], "security": "maximum", "age": [20, 38], "respect": 35, "innocent": false, "eligible": 0.65, "gang": true},
	"white": {"name": "White collar", "icon": "💼", "desc": "Fraud, a lawyer who wasn't enough, and seven years in a place with no cars. Money still talks, but quietly.", "crime": "fraud", "years": [5, 8], "security": "minimum", "age": [32, 58], "respect": 5, "innocent": false, "eligible": 0.4, "money": 90000},
	"innocent": {"name": "Wrongly convicted", "icon": "⚖️", "desc": "You did not do it. Eighteen years, a lawyer who stopped returning calls, and a file only you believe.", "crime": "murder", "years": [16, 22], "security": "maximum", "age": [20, 40], "respect": 15, "innocent": true, "eligible": 0.7},
	"political": {"name": "A political prisoner", "icon": "📣", "desc": "A protest that became a charge. Three years, people outside who are loud about it, and a warden who would like it to stop.", "crime": "public order offences", "years": [2, 4], "security": "medium", "age": [21, 50], "respect": 20, "innocent": false, "eligible": 0.5, "support": 70},
	"lifer": {"name": "A lifer", "icon": "🕳️", "desc": "Murder, and a number of years so large it stops being a number. Parole is a word other people use.", "crime": "murder", "years": [28, 38], "security": "maximum", "age": [19, 34], "respect": 25, "innocent": false, "eligible": 0.75},
}

const GUARD_STORIES := {
	"career": {"name": "A steady career", "icon": "🪪", "desc": "A good pension, a union card and a family that is glad of both. You do not plan to be a hero.", "integrity": 60, "debt": 0, "age": [23, 30], "pay": 1.0},
	"military": {"name": "Ex-military", "icon": "🎖️", "desc": "Discipline, a stare and a habit of sleeping badly. The routine suits you more than you like to say.", "integrity": 65, "debt": 0, "age": [26, 34], "pay": 1.05, "trauma": 20},
	"desperate": {"name": "Needed the job", "icon": "💸", "desc": "Debts, a child, no other offers. Everyone in the building can smell that you need the money.", "integrity": 45, "debt": 30000, "age": [22, 40], "pay": 0.95},
	"idealist": {"name": "An idealist", "icon": "🕊️", "desc": "You believe people can change, and you believe you can help. The building is going to have views.", "integrity": 78, "debt": 0, "age": [22, 32], "pay": 1.0},
	"legacy": {"name": "A prison family", "icon": "🏛️", "desc": "Your father was a captain here. His name opens doors, and closes some others.", "integrity": 55, "debt": 0, "age": [22, 28], "pay": 1.0, "merit": 12},
	"local": {"name": "From the neighbourhood", "icon": "🏘️", "desc": "Half the inmates grew up on your street. Some of them still call you by your first name.", "integrity": 52, "debt": 8000, "age": [22, 32], "pay": 0.98},
}

const GANGS := {
	"brickhouse": {"name": "The Brickhouse Boys", "icon": "🧱", "desc": "The biggest, and the loudest. Muscle, tattoos, and a code that is mostly about not being seen to back down."},
	"cuervos": {"name": "Los Cuervos", "icon": "🪶", "desc": "Organised and patient. They run the commissary economy and remember every debt."},
	"quiet": {"name": "The Quiet Men", "icon": "🤫", "desc": "Few, old and careful. They never raise their voice. They are somehow always in the room when it matters."},
	"congregation": {"name": "The Congregation", "icon": "🕯️", "desc": "Faith, protection and an unlisted list of favours. They take in the frightened. They do not take in everyone."},
}

const RANK_P := [[0, "Fresh fish"], [20, "Regular"], [45, "Respected"], [70, "Shot-caller"], [90, "Old head"]]
const GANG_RANK := ["Outsider", "Prospect", "Soldier", "Lieutenant", "Shot-caller"]
const RANK_G := ["Recruit", "Correctional Officer", "Senior Officer", "Sergeant", "Lieutenant", "Captain", "Deputy Warden", "Warden"]
const RANK_NEED := [0, 0, 8, 22, 38, 56, 74, 90]     # merit needed to be promoted into each rank
const RANK_PAY := [30000, 42000, 50000, 62000, 74000, 88000, 105000, 130000]

const FAC_NAMES := ["Blackwater Correctional Facility", "Redhill State Penitentiary", "Stonebridge Correctional Centre", "Ashgrove Secure Unit", "Harrow Fell Prison", "Ironside Penitentiary", "Calder Moor Correctional", "Saint Brannoc Detention Centre", "Thornfield Maximum Security", "Lowmoor Correctional Institution"]
const BLOCKS := ["A", "B", "C", "D", "E"]
const SECURITY := {"minimum": "Minimum security", "medium": "Medium security", "maximum": "Maximum security"}

const JOBS := {
	"none": {"name": "No job", "icon": "🛏️", "pay": 0, "conduct": 0, "desc": "Unemployed. Plenty of time, and none of it is good for you."},
	"kitchen": {"name": "Kitchen", "icon": "🍳", "pay": 1, "conduct": 2, "desc": "Early shifts, extra food, and the knives are counted twice."},
	"laundry": {"name": "Laundry", "icon": "🧺", "pay": 1, "conduct": 2, "desc": "Hot, loud and everyone's business passes through it."},
	"library": {"name": "Library", "icon": "📚", "pay": 1, "conduct": 3, "desc": "Quiet. The law books are in there."},
	"workshop": {"name": "Workshop", "icon": "🔧", "pay": 2, "conduct": 2, "desc": "Tools, and a trade. The tools are counted three times."},
	"yard": {"name": "Yard crew", "icon": "🌳", "pay": 1, "conduct": 1, "desc": "Outdoors. Also, edges and fences."},
	"infirmary": {"name": "Infirmary orderly", "icon": "🩺", "pay": 1, "conduct": 3, "desc": "Clean sheets, a trusted position and a lot of secrets."},
	"barber": {"name": "Barber", "icon": "💈", "pay": 2, "conduct": 1, "desc": "A chair, scissors and conversation."},
}

const PROGRAMS := {
	"ged": {"name": "High-school diploma", "icon": "🎓", "desc": "Finish what you didn't.", "wit": 3},
	"college": {"name": "Correspondence degree", "icon": "📜", "desc": "A long road, and the board reads it.", "wit": 6},
	"trade": {"name": "Trade certificate", "icon": "🔩", "desc": "Plumbing, welding, carpentry. A job on the outside.", "wit": 2},
	"therapy": {"name": "Counselling", "icon": "🛋️", "desc": "Sit in a circle and say things.", "wit": 1},
	"faith": {"name": "Faith group", "icon": "🕯️", "desc": "A chapel, some company and a few friends.", "wit": 0},
	"rehab": {"name": "Substance programme", "icon": "💊", "desc": "Hard, slow and respected by every board.", "wit": 1},
	"anger": {"name": "Anger management", "icon": "🧊", "desc": "The classic. People laugh at it and it works anyway.", "wit": 1},
}

const CONTRABAND := {
	"cigs": {"name": "Cigarettes", "icon": "🚬", "value": 1},
	"phone": {"name": "A phone", "icon": "📱", "value": 8},
	"drugs": {"name": "Drugs", "icon": "💊", "value": 6},
	"shiv": {"name": "A blade", "icon": "🔪", "value": 3},
	"food": {"name": "Food and sugar", "icon": "🍫", "value": 1},
	"tools": {"name": "Tools for a plan", "icon": "🪛", "value": 5},
}

const SIDE_P := {"happiness": ["😐", "Morale"], "health": ["❤️", "Health"], "smarts": ["🧠", "Wits"], "looks": ["💪", "Presence"], "stress": ["☁️", "Strain"]}
const SIDE_G := {"happiness": ["😐", "Morale"], "health": ["❤️", "Health"], "smarts": ["🧠", "Wits"], "looks": ["🎖️", "Bearing"], "stress": ["☁️", "Strain"]}

const GAUGES_P := ["respect", "heat", "conduct", "support", "appeal", "dues"]
const GAUGES_G := ["merit", "integrity", "control", "ia_heat", "trauma", "union", "standing"]
const PLAN_STAGES := ["No plan", "Listening", "Tools", "A crew", "Inside help", "Ready"]

const OUTCOME_KEYS := ["respect", "heat", "conduct", "support", "appeal", "dues", "tension", "order", "budget", "gang", "gang_rank", "rep", "job", "program", "stash", "intel", "escape", "crew", "solitary", "attack", "riot",
	"hearing", "parole_mood", "exonerate", "merit", "integrity", "control", "ia_heat", "trauma", "union", "standing", "corruption", "commend", "incident", "whistle", "switch", "promote", "bribe", "flag", "then", "caught", "free", "kill", "debt", "pay", "inmate", "friend", "enemy", "transfer", "sentence"]

const OPENERS := {
	"prisoner": ["The van had no windows. I counted the turns and lost count at eleven.", "They took my belt, my shoelaces and my name, in that order, and gave me a number I would come to say in my sleep.", "The gate closed behind me with a sound I have heard in my head ever since. It was smaller than I expected, and final."],
	"guard": ["The training officer shook my hand for slightly too long and said the first rule was that the second rule was always the first.", "The keys were heavier than I had thought. Everybody says that, and I thought they were exaggerating.", "I walked on to the wing on my first morning and every head turned. It was not hostile. It was assessment."],
}


func _p() -> Dictionary:
	return GameState.player


func active() -> bool:
	return not GameState.player.is_empty() and (Lives.is_type("prisoner") or Lives.is_type("guard"))


func is_guard() -> bool:
	return Lives.is_type("guard")


func is_prisoner() -> bool:
	return Lives.is_type("prisoner")


func L() -> Dictionary:
	return Lives.life()


func F() -> Dictionary:
	var l := L()
	if not l.has("fac") or not (l["fac"] is Dictionary):
		l["fac"] = {"name": "Blackwater Correctional Facility", "security": "medium", "tension": 35.0, "order": 55.0, "budget": 55.0, "crowding": 60.0, "warden": "", "gangs": {}, "block": "C", "riots": 0, "lockdown": 0, "years": 0}
	return l["fac"]


func pick(arr: Array) -> String:
	return str(arr[randi() % arr.size()])


func did(key: String) -> int:
	return int(_p().get("act_year", {}).get(key, 0))


func note(key: String) -> void:
	if not _p().has("act_year"):
		_p()["act_year"] = {}
	_p()["act_year"][key] = did(key) + 1


func clampg(l: Dictionary, k: String, d: float, lo: float = 0.0, hi: float = 100.0) -> void:
	l[k] = clampf(float(l.get(k, 0)) + d, lo, hi)


func prisoner_rank() -> String:
	var r := float(L().get("respect", 0))
	var out: String = str(RANK_P[0][1])
	for e in RANK_P:
		if r >= float(e[0]):
			out = str(e[1])
	return out


func rank_name() -> String:
	if is_guard():
		return str(RANK_G[clampi(int(L().get("rank", 1)), 0, RANK_G.size() - 1)])
	return prisoner_rank()


func title() -> String:
	if is_guard():
		return rank_name()
	return "Inmate"


func number_label() -> String:
	var l := L()
	return "#%s" % str(l.get("number", "0000"))


func remaining() -> int:
	var l := L()
	return maxi(0, int(l.get("sentence", 0)) - int(l.get("served", 0)))


func served() -> int:
	return int(L().get("served", 0))


func warden_name() -> String:
	var w := str(F().get("warden", ""))
	if w != "" and GameState.npcs.has(w):
		return "Warden %s" % str(GameState.npcs[w]["last"])
	return "the warden"


func gang_name(id: String) -> String:
	return str(GANGS.get(id, {}).get("name", "no one"))


func my_gang() -> String:
	return str(L().get("gang", ""))


func programs_n() -> int:
	return Array(L().get("programs", [])).size()


func plan_stage() -> int:
	return int(L().get("escape", 0))


func intel_n() -> int:
	return Array(L().get("intel", [])).size()


func has_intel(kind: String) -> bool:
	for i in L().get("intel", []):
		if str(i.get("kind", "")) == kind:
			return true
	return false


func add_intel(kind: String, text: String, value: int = 1) -> void:
	var l := L()
	if not l.has("intel"):
		l["intel"] = []
	for i in l["intel"]:
		if str(i.get("kind", "")) == kind and str(i.get("text", "")) == text:
			return
	l["intel"].append({"kind": kind, "text": text, "value": value, "age": int(_p().get("age", 0))})
	GameState.counter("pr_intel")


# ================================================================ start

func setup(opts: Dictionary) -> void:
	var p := _p()
	var role := "guard" if str(opts.get("life_path", "")) == "guard" else "prisoner"
	var sk := str(opts.get("story", "first"))
	var story: Dictionary = (GUARD_STORIES if role == "guard" else PRISONER_STORIES).get(sk, {})
	if story.is_empty():
		sk = "career" if role == "guard" else "first"
		story = (GUARD_STORIES if role == "guard" else PRISONER_STORIES)[sk]
	var age := randi_range(int(story["age"][0]), int(story["age"][1]))
	p["age"] = age
	p["born_year"] = GameState.START_YEAR - age
	p["housing"] = "apartment"
	p["education"]["stage"] = "done"
	GameState.npcs.clear()
	GameState.next_npc_id = 1
	var fac_name := pick(FAC_NAMES)
	var sec := str(story.get("security", "medium")) if role == "prisoner" else pick(["medium", "medium", "maximum", "minimum"])
	var gangs := {}
	for gk in GANGS.keys():
		gangs[gk] = {"power": float(randi_range(25, 70)), "mood": float(randi_range(30, 60))}
	p["life"] = {"type": role, "role": role, "story": sk, "served": 0, "number": "%02d-%04d" % [randi_range(10, 99), randi_range(1000, 9999)], "block": pick(BLOCKS), "inherit": opts.get("inherit", {})}
	var l := L()
	l["fac"] = {"name": fac_name, "security": sec, "tension": float(randi_range(28, 50)), "order": float(randi_range(48, 70)), "budget": float(randi_range(40, 70)), "crowding": float(randi_range(50, 88)), "warden": "", "gangs": gangs, "block": l["block"], "riots": 0, "lockdown": 0, "years": 0}
	if role == "prisoner":
		_setup_prisoner(story, sk)
	else:
		_setup_guard(story, sk)
	_make_outside(role)
	_make_building(role)
	GameState.log_years.clear()
	GameState.milestones.clear()
	GameState.log_years.append({"age": age, "lines": []})
	GameState.add_log(pick(OPENERS[role]))
	if role == "prisoner":
		GameState.add_log("%s: %s. %d years at %s, %s. %s" % [str(story["name"]), str(story["crime"]), int(l["sentence"]), fac_name, str(SECURITY[sec]).to_lower(), "I did not do it, and nobody in the building has the slightest interest." if bool(l["innocent"]) else "I knew what it would cost. I did not know what it would feel like."])
		GameState.add_milestone(age, "was sentenced to %d years for %s" % [int(l["sentence"]), str(story["crime"])])
	else:
		GameState.add_log("%s. I started at %s as a recruit, aged %d." % [str(story["name"]), fac_name, age])
		GameState.add_milestone(age, "joined the staff at %s" % fac_name)
	var inh: Dictionary = l.get("inherit", {})
	if not inh.is_empty():
		GameState.add_log("It was a different life, and the building did not remember it. Someone in the next cell said the name of the last one who had my number. I did not ask.")
	GameState.counter("life_" + role)
	GameState.counter("prison_lives")
	var ms: Dictionary = Meta.meta.get("prison_roles", {})
	ms[role] = true
	Meta.meta["prison_roles"] = ms


func _setup_prisoner(story: Dictionary, sk: String) -> void:
	var l := L()
	var p := _p()
	var n := randi_range(int(story["years"][0]), int(story["years"][1]))
	l.merge({"crime": str(story["crime"]), "sentence": n, "eligible": int(ceil(float(n) * float(story["eligible"]))), "innocent": bool(story["innocent"]),
		"respect": float(story["respect"]), "heat": 10.0, "conduct": 50.0, "support": float(story.get("support", 60)), "appeal": 12.0 if bool(story["innocent"]) else 0.0, "lawyer": float(randi_range(25, 60)), "dues": 0.0,
		"gang": "", "gang_rank": 0, "rep": {}, "job": "none", "programs": [], "stash": 0, "intel": [], "escape": 0, "crew": [], "plan_age": -1,
		"riots": 0, "attacks": 0, "solitary_years": 0, "hearings": 0, "denied": 0, "parole_mood": 0.0, "exonerated": false, "paroled": false, "escaped": false, "caught": false,
		"ex_guard": false, "visits": 0, "fugitive_years": 0, "flags": {}, "snitched": 0, "debt_cigs": 0}, true)
	p["money"] = int(story.get("money", randi_range(60, 240)))
	for st in ["happiness", "health"]:
		p["stats"][st] = float(clampi(int(p["stats"][st]), 40, 90))
	p["stats"]["stress"] = 35.0
	if bool(story.get("gang", false)):
		var gk: String = GANGS.keys()[randi() % GANGS.size()]
		l["gang"] = gk
		l["gang_rank"] = 2
		l["rep"][gk] = 40.0
		for other in GANGS.keys():
			if other != gk:
				l["rep"][other] = float(randi_range(-45, -10))
	if sk == "innocent":
		l["lawyer"] = float(randi_range(15, 35))
	if sk == "white":
		l["heat"] = 5.0
	if sk == "political":
		p["fame"] = 18.0


func _setup_guard(story: Dictionary, sk: String) -> void:
	var l := L()
	var p := _p()
	l.merge({"rank": 1, "merit": float(story.get("merit", 0)), "integrity": float(story["integrity"]), "corruption": 0, "ia_heat": 0.0, "control": 35.0, "trauma": float(story.get("trauma", 5)),
		"union": 30.0, "standing": 50.0, "commend": 0, "incidents": 0, "whistle": false, "switched": false, "bribes": 0, "debt": int(story["debt"]), "retire_at": randi_range(55, 62), "intel": [], "flags": {},
		"fired": false, "convicted": false, "pension": 0, "assaults": 0, "lives_saved": 0, "force": 0, "force_bad": 0, "pay_mult": float(story["pay"]), "burnout": 0.0, "ring": 0.0}, true)
	p["money"] = 3000 + (4000 if sk == "legacy" else 0)
	p["stats"]["stress"] = 25.0
	if sk == "military":
		p["stats"]["health"] = 82.0


## The people outside, who go on without you.
func _make_outside(role: String) -> void:
	var p := _p()
	var age := int(p["age"])
	var last := str(p["last"])
	var g := str(p["gender"])
	# parents
	var mum := GameState.create_npc("mother", {"gender": "female", "last": last, "age": age + randi_range(22, 32), "closeness": randi_range(50, 90), "species": "human"})
	GameState.npcs[mum]["job"] = pick(["a cleaner", "a school secretary", "a care worker", "retired", "a shop assistant"])
	if randf() < 0.65:
		var dad := GameState.create_npc("father", {"gender": "male", "last": last, "age": age + randi_range(24, 36), "closeness": randi_range(35, 85), "species": "human"})
		GameState.npcs[dad]["job"] = pick(["a driver", "retired", "a mechanic", "a builder", "unemployed"])
	if randf() < 0.55:
		var sb := GameState.create_npc("sibling", {"last": last, "age": age + randi_range(-5, 5), "closeness": randi_range(35, 80), "species": "human"})
		GameState.npcs[sb]["job"] = pick(["a nurse", "a warehouse worker", "a student", "a plumber", "a teacher"])
	# a partner and children, more likely the older you are
	if randf() < (0.55 if age >= 24 else 0.3):
		var pg := "female" if g == "male" else ("male" if g == "female" else pick(["male", "female"]))
		var par := GameState.create_npc("partner", {"gender": pg, "age": age + randi_range(-4, 4), "closeness": randi_range(55, 90), "species": "human"})
		p["partner"] = par
		p["partner_status"] = "married" if randf() < 0.6 else "dating"
		GameState.npcs[par]["job"] = pick(["a nurse", "a bar manager", "a carer", "a driver", "an office worker"])
		if age >= 26 and randf() < 0.65:
			var kc := randi_range(1, 2)
			for _i in range(kc):
				var kid := GameState.create_npc("child", {"last": last, "age": randi_range(0, mini(12, maxi(1, age - 20))), "closeness": randi_range(55, 90), "species": "human"})
				GameState.npcs[kid]["job"] = ""
	GameState.create_npc("best_friend", {"age": age + randi_range(-3, 3), "closeness": randi_range(50, 85), "species": "human"})


## The building: staff, other inmates, the warden.
func _make_building(role: String) -> void:
	var l := L()
	var f := F()
	var w := GameState.create_npc("warden", {"age": randi_range(48, 64), "closeness": 10, "species": "human"})
	GameState.npcs[w]["job"] = "the warden"
	GameState.npcs[w]["style"] = pick(["strict", "political", "tired", "reformist", "absent"])
	f["warden"] = w
	if role == "prisoner":
		var cell := GameState.create_npc("cellmate", {"age": randi_range(22, 55), "closeness": randi_range(25, 55), "species": "human"})
		GameState.npcs[cell]["job"] = ""
		GameState.npcs[cell]["gang"] = pick(GANGS.keys()) if randf() < 0.6 else ""
		var off := GameState.create_npc("officer", {"age": randi_range(26, 55), "closeness": randi_range(10, 35), "species": "human"})
		GameState.npcs[off]["job"] = "a correctional officer"
		GameState.npcs[off]["mood"] = pick(["fair", "fair", "hard", "bent", "kind"])
		for _i in range(2):
			new_inmate("", randi_range(25, 60))
		GameState.create_npc("lawyer", {"age": randi_range(30, 58), "closeness": 25, "species": "human"})
		GameState.npcs[GameState.first_of("lawyer")]["job"] = "your lawyer"
	else:
		var sup := GameState.create_npc("supervisor", {"age": randi_range(34, 56), "closeness": randi_range(30, 55), "species": "human"})
		GameState.npcs[sup]["job"] = "your sergeant"
		for _j in range(2):
			var co := GameState.create_npc("co_guard", {"age": randi_range(24, 54), "closeness": randi_range(25, 60), "species": "human"})
			GameState.npcs[co]["job"] = "a correctional officer"
			GameState.npcs[co]["mood"] = pick(["fair", "fair", "hard", "bent", "kind"])
		for _k in range(4):
			new_inmate("", randi_range(23, 58))
	l["fac"] = f


func new_inmate(gang: String, age: int) -> String:
	var g := gang
	if g == "" and randf() < 0.5:
		g = pick(GANGS.keys())
	var id := GameState.create_npc("inmate", {"age": age, "closeness": randi_range(8, 35), "species": "human"})
	var n: Dictionary = GameState.npcs[id]
	n["gang"] = g
	n["job"] = ""
	n["crime"] = pick(["robbery", "assault", "drug offences", "burglary", "fraud", "arson", "manslaughter", "car theft"])
	n["trust"] = randi_range(10, 40)
	return id


func relation_name(rel: String, _g: String) -> String:
	match rel:
		"inmate": return "Inmate"
		"cellmate": return "Cellmate"
		"officer": return "Officer"
		"co_guard": return "Fellow officer"
		"supervisor": return "Your sergeant"
		"warden": return "The warden"
		"lawyer": return "Your lawyer"
		"crewmate": return "Crew"
		"snitch": return "Informant"
		"contact": return "Outside contact"
	return ""


# ================================================================ the year

func yearly() -> void:
	var l := L()
	l["served"] = int(l.get("served", 0)) + 1
	GameState.counter("prison_years")
	_facility_year()
	if is_guard():
		_guard_year()
	else:
		_prisoner_year()
	_outside_year()
	_incidents()


func _gang_state(id: String) -> Dictionary:
	return F()["gangs"].get(id, {"power": 40.0, "mood": 40.0})


func _facility_year() -> void:
	var f := F()
	f["years"] = int(f.get("years", 0)) + 1
	var d := (float(f["crowding"]) - 60.0) * 0.08 + (50.0 - float(f["budget"])) * 0.06 + (50.0 - float(f["order"])) * 0.07 + randf_range(-7.0, 7.0)
	var war := 0
	for gk in f["gangs"].keys():
		var g: Dictionary = f["gangs"][gk]
		g["power"] = clampf(float(g["power"]) + randf_range(-6.0, 6.0), 8.0, 95.0)
		g["mood"] = clampf(float(g["mood"]) + randf_range(-12.0, 12.0), 5.0, 95.0)
		if float(g["mood"]) < 22.0:
			war += 1
	if war >= 2:
		d += 8.0
		f["war"] = 2
	elif int(f.get("war", 0)) > 0:
		f["war"] = int(f["war"]) - 1
		d += 4.0
	if int(f.get("lockdown", 0)) > 0:
		d -= 9.0
		f["lockdown"] = int(f["lockdown"]) - 1
		if is_prisoner():
			GameState.apply_effects({"happiness": -4, "stress": 4})
			GameState.add_log("The lockdown ran on. Twenty-three hours a day in the cell, meals through the hatch, and the whole building listening to itself.")
	f["tension"] = clampf(float(f["tension"]) + d, 4.0, 100.0)
	f["order"] = clampf(float(f["order"]) + randf_range(-5.0, 5.0) + (2.0 if is_guard() and float(L().get("control", 0)) > 55.0 else 0.0), 15.0, 95.0)
	f["budget"] = clampf(float(f["budget"]) + randf_range(-6.0, 5.0), 10.0, 95.0)
	f["crowding"] = clampf(float(f["crowding"]) + randf_range(-4.0, 6.0), 30.0, 100.0)
	if randf() < 0.1:
		var w := str(f.get("warden", ""))
		if w != "" and GameState.npcs.has(w):
			GameState.npcs[w]["style"] = pick(["strict", "political", "tired", "reformist", "absent"])
			GameState.add_log(pick([
				"%s announced a review of the regime. Nobody could say in advance whether it meant more, or less." % warden_name(),
				"There was a new directive, then a second one that contradicted it, and then a notice on the wall about the first."]))
	var t := float(f["tension"])
	if t >= 70.0 and randf() < 0.55:
		GameState.add_log(pick([
			"The building felt wrong. It was in the noise, and in the way nobody was looking at anybody.",
			"Tension sat on the block like weather. The old hands were quieter than usual, which is always the worst sign.",
			"There was more shouting than usual, and a different quality to it. Everyone is waiting for the thing that is going to happen."]))
	elif t <= 25.0 and randf() < 0.3:
		GameState.add_log(pick(["It was a calm year. Nobody trusted it.", "Nothing happened for months, which is what the building does when it is gathering itself, or when it genuinely has nothing to say."]))


# ---------------------------------------------------------------- prisoner

func _prisoner_year() -> void:
	var l := L()
	var p := _p()
	var f := F()
	var sec := str(f["security"])
	# the money: a job, dues, the commissary
	var job: Dictionary = JOBS.get(str(l.get("job", "none")), JOBS["none"])
	p["money"] = int(p["money"]) + int(job["pay"]) * 220
	if my_gang() != "" and int(l.get("gang_rank", 0)) > 0:
		var dues := 40 + int(l["gang_rank"]) * 20
		if int(p["money"]) >= dues:
			p["money"] = int(p["money"]) - dues
		else:
			clampg(l, "dues", 15.0)
	if float(l.get("dues", 0)) > 0.0:
		clampg(l, "dues", 6.0)
	# conduct and heat
	var cd := 0.0
	cd += float(job["conduct"]) * 1.5
	cd += float(programs_n()) * 1.0
	cd -= float(l["heat"]) * 0.06
	cd -= 2.0 if int(l.get("stash", 0)) > 0 else 0.0
	cd += randf_range(-3.0, 3.0)
	clampg(l, "conduct", cd)
	l["heat"] = clampf(float(l["heat"]) + (10.0 - float(l["heat"])) * 0.25 + float(l.get("stash", 0)) * 2.0, 0.0, 100.0)
	# standing
	var rd := 0.0
	if int(l.get("gang_rank", 0)) > 0:
		rd += 1.5
	if int(l.get("served", 0)) > 5:
		rd += 0.5
	rd -= float(l.get("dues", 0)) * 0.05
	if float(l["respect"]) > 85.0:
		rd -= 1.0
	clampg(l, "respect", rd)
	# the body and the mind
	var base := {"minimum": 0.6, "medium": 1.0, "maximum": 1.8}.get(sec, 1.0)
	var hd := -base - float(f["tension"]) / 60.0 + (1.0 if l.get("job", "none") == "kitchen" else 0.0)
	if int(p["age"]) > 50:
		hd -= 0.8
	GameState.change_stat("health", hd * 0.8)
	GameState.apply_effects({"stress": 2 + int(base * 2.0) - (3 if programs_n() > 0 else 0)})
	if GameState.stat("stress") > 80.0:
		GameState.apply_effects({"happiness": -4, "health": -2})
		GameState.add_log("I stopped sleeping properly. The ceiling was the only thing I looked at for months.")
	# shakedowns
	if int(l.get("stash", 0)) > 0 and randf() < 0.18 + float(l["heat"]) / 220.0:
		_shakedown()
	# solitary
	if float(l["heat"]) > 85.0 and randf() < 0.4:
		_solitary("The paperwork piled up. One morning a pair of officers came for me.")
	# fights and violence
	var vio := 0.07 + float(f["tension"]) / 500.0 + float(l.get("dues", 0)) / 400.0 - float(l["respect"]) / 600.0
	if my_gang() != "":
		vio += 0.03
	if randf() < vio:
		_attacked()
	# a stretch of time is told
	var sv := served()
	if sv in [1, 5, 10, 15, 20, 25]:
		GameState.add_milestone(int(p["age"]), "reached %d year%s inside" % [sv, "" if sv == 1 else "s"])
		GameState.add_log("%d year%s. %s" % [sv, "" if sv == 1 else "s", pick([
			"A number that used to be a guess. I marked it on the wall and did not look at it for a week.",
			"Time here is counted three ways: the days, the years, and the number of things you have stopped wanting.",
			"People outside think of a sentence as a length. Inside, it has a texture, and I am learning the texture."])])
	# the case
	_case_year()
	# release
	if remaining() <= 0:
		conclude("served")


func _case_year() -> void:
	var l := L()
	var p := _p()
	# appeal
	if bool(l.get("innocent", false)) and not bool(l.get("exonerated", false)):
		var d := float(l["lawyer"]) / 45.0 + randf_range(-1.0, 2.0)
		if int(l.get("served", 0)) > 12:
			d *= 0.7
		clampg(l, "appeal", d)
		if float(l["appeal"]) >= 100.0:
			conclude("exonerated")
			return
	# parole
	if served() >= int(l.get("eligible", 99)) and not bool(l.get("paroled", false)):
		l["hearing_due"] = true
	# escape plan decay: people talk
	var crew: Array = l.get("crew", [])
	if plan_stage() > 0 and not crew.is_empty() and randf() < 0.05 * float(crew.size()):
		_plan_leaks()
	# visits
	var vv := 0
	if float(l["support"]) > 45.0 and randf() < float(l["support"]) / 100.0:
		vv = randi_range(1, 4)
		l["visits"] = int(l.get("visits", 0)) + vv
	if vv > 0:
		GameState.apply_effects({"happiness": 2 + vv})
		if randf() < 0.45:
			GameState.add_log(pick([
				"They came on the third Saturday, in the good coats. The glass was between us, but the voice on the phone was the same voice.",
				"Visiting hour is the best and worst hour of the month. It ends exactly as it starts: with a clock.",
				"I got a letter every week for most of the year. I read each one twice, and then a third time on the nights it was hard.",
				"A visit, and a small hand pressed flat on the glass on the other side. I put mine against it."]))
	else:
		GameState.apply_effects({"happiness": -3})
		if randf() < 0.4:
			GameState.add_log(pick([
				"The visiting room was empty on my side of the glass that month. It did not matter whose fault it was.",
				"No letter this year until the spring, and then only a card with a printed message.",
				"I watched the visitors file in through the door, and counted the people who were not mine."]))
	clampg(l, "support", -3.0 - (0.6 * served() if int(l.get("served", 0)) > 4 else 0.0) + float(vv) * 2.0)
	if p["partner"] != "" and GameState.npcs.has(p["partner"]):
		clampg(l, "support", 0.0)
	_unused(p)


func _unused(_x) -> void:
	pass


func _shakedown() -> void:
	var l := L()
	var lost := int(l.get("stash", 0))
	l["stash"] = 0
	clampg(l, "heat", 22.0)
	clampg(l, "conduct", -10.0)
	clampg(l, "respect", -3.0)
	GameState.counter("pr_shakedowns")
	GameState.add_log(pick([
		"They tossed the cell at six in the morning. Everything went on the floor, and the thing I had hidden for nine months was in the officer's gloved hand in under a minute.",
		"A shakedown, and a dog. I lost %d thing%s and an entire year of careful good behaviour." % [lost, "" if lost == 1 else "s"],
		"The door slammed open before the count. I stood against the wall while they turned the cell inside out. They knew where to look."]))
	GameState.apply_effects({"stress": 6})
	if randf() < 0.35:
		_solitary("They found enough to make a case of it.")


func _solitary(line: String) -> void:
	var l := L()
	l["solitary_years"] = int(l.get("solitary_years", 0)) + 1
	GameState.counter("pr_solitary")
	GameState.add_log("%s %s" % [line, pick([
		"The segregation unit is a concrete box with a slot and a light that never goes fully off. I counted the bricks, the seams and then the breaths.",
		"Months in the hole. The mind does odd things. At the end I could hear a conversation that wasn't there, and I answered it.",
		"I learned how long a day can be, and how little you need to be in it."])])
	GameState.apply_effects({"happiness": -9, "stress": 12, "health": -3})
	clampg(l, "conduct", -12.0)
	clampg(l, "heat", -20.0)
	l["escape"] = maxi(0, int(l.get("escape", 0)) - 1)
	GameState.add_milestone(int(_p()["age"]), "was put in solitary")


func _attacked() -> void:
	var l := L()
	l["attacks"] = int(l.get("attacks", 0)) + 1
	GameState.counter("pr_attacks")
	var win := float(l["respect"]) * 0.5 + GameState.stat("health") * 0.4 + float(GameState.stat("looks")) * 0.3 + randf() * 40.0 > 85.0
	if win:
		clampg(l, "respect", 6.0)
		GameState.add_log(pick([
			"Two of them came for me in the shower block. I do not remember deciding to fight. I remember the sound afterwards, and that nobody came for the rest of the year.",
			"A man I had never seen swung at me in the corridor. It was over quickly, and I was the one still standing.",
			"They tested me on the yard. I lost a tooth and a bit of face, and gained a name."]))
		GameState.apply_effects({"health": -4, "stress": 5})
		clampg(l, "heat", 14.0)
	else:
		clampg(l, "respect", -5.0)
		GameState.add_log(pick([
			"I woke up in the infirmary with a taste of iron and a light in my eyes. Somebody had cleaned me up, which I counted as mercy.",
			"They caught me on the stairs. A kick, and then the part I do not remember. I recovered, mostly.",
			"It was a blade, not a fist. The scar runs from my ribs to my hip, and no one has ever been charged."]))
		GameState.apply_effects({"health": -14, "stress": 10, "happiness": -5})
		if GameState.stat("health") < 1.0:
			GameState.player["stats"]["health"] = 3.0
	GameState.add_milestone(int(_p()["age"]), "was attacked inside")


func _plan_leaks() -> void:
	var l := L()
	l["escape"] = 0
	l["crew"] = []
	l["plan_age"] = -1
	GameState.counter("pr_plan_leaks")
	GameState.add_log("Somebody talked. It does not matter who. The officers knew a day before anything was ready, and everything I had built went into a box with a seal on it.")
	_solitary("They came for me and my crew on the same morning.")
	clampg(l, "respect", -10.0)
	GameState.add_milestone(int(_p()["age"]), "had a plan betrayed")


# ---------------------------------------------------------------- guard

func _guard_year() -> void:
	var l := L()
	var p := _p()
	var f := F()
	var rank := int(l["rank"])
	var t := float(f["tension"])
	# pay
	var pay := int(float(RANK_PAY[rank]) * float(l.get("pay_mult", 1.0)))
	p["money"] = int(p["money"]) + pay / 4
	if int(l.get("debt", 0)) > 0:
		var cut := mini(int(l["debt"]), 4000 + int(pay / 12))
		l["debt"] = int(l["debt"]) - cut
		p["money"] = int(p["money"]) - cut
	# the work: merit comes from control and from not being a problem
	var md := 2.0 + float(l["control"]) / 40.0 + float(l["integrity"]) / 60.0 - float(l["ia_heat"]) / 50.0 + randf_range(-1.0, 1.5)
	if rank >= 4:
		md += 0.5
	clampg(l, "merit", md)
	# strain
	var td := t / 30.0 + float(int(l.get("assaults", 0))) * 0.0
	if float(l["control"]) < 30.0:
		td += 2.0
	clampg(l, "trauma", td - (1.5 if float(l["union"]) > 60.0 else 0.0) - (1.0 if GameState.stat("happiness") > 65.0 else 0.0))
	GameState.apply_effects({"stress": 2 + int(t / 40.0)})
	if float(l["trauma"]) > 70.0:
		clampg(l, "burnout", 6.0)
		GameState.apply_effects({"happiness": -3, "health": -1})
		if randf() < 0.4:
			GameState.add_log(pick([
				"I sat in the car park for twenty minutes before every shift, and twenty minutes after. Nobody asked what I was doing.",
				"I had stopped hearing the noise on the wing. That worried me, once I noticed it.",
				"My wife said I did not laugh in the same way. She was right. I could not have told you when it changed."]))
	# the keys and what they cost
	clampg(l, "ia_heat", -4.0 - (4.0 if int(l.get("corruption", 0)) == 0 else 0.0) + float(l.get("ring", 0.0)) * 0.04)
	clampg(l, "integrity", -0.5 * float(int(l.get("corruption", 0)) > 0) + 0.3)
	if float(l["control"]) > 70.0:
		clampg(l, "control", -1.0)
	else:
		clampg(l, "control", 1.0)
	clampg(l, "union", -1.0 + (1.0 if float(f["budget"]) < 35.0 else 0.0))
	# promotion
	if rank < RANK_G.size() - 1 and float(l["merit"]) >= float(RANK_NEED[rank + 1]) and served() >= rank * 2:
		_promote()
	# an investigation can happen to anyone who has taken money
	if int(l.get("corruption", 0)) > 0 and float(l["ia_heat"]) > 55.0 and randf() < 0.5 + float(l["ia_heat"]) / 300.0:
		_investigation()
	# retirement
	if int(p["age"]) >= int(l["retire_at"]):
		conclude("retired")
	# overtime and the home
	GameState.apply_effects({"happiness": -1 if float(l["trauma"]) > 55.0 else 1})
	var sv := served()
	if sv in [1, 5, 10, 15, 20, 25, 30]:
		GameState.add_milestone(int(p["age"]), "completed %d year%s on the staff" % [sv, "" if sv == 1 else "s"])


func _promote() -> void:
	var l := L()
	l["rank"] = int(l["rank"]) + 1
	var nm := rank_name()
	GameState.counter("gd_promotions")
	GameState.add_milestone(int(_p()["age"]), "was promoted to %s" % nm)
	GameState.add_log("Promoted to %s. %s" % [nm, pick([
		"There was a handshake and a new set of stripes. The man who gave me the stripes was careful not to say anything he'd regret.",
		"A letter, a short ceremony, and a quiet word in the corridor about what it meant. It meant more hours.",
		"The pay went up by less than the work did, as it does."])])
	GameState.apply_effects({"happiness": 6, "stress": 3})
	clampg(l, "standing", 6.0)
	if int(l["rank"]) == RANK_G.size() - 1:
		var f := F()
		var w := str(f.get("warden", ""))
		if w != "" and GameState.npcs.has(w):
			GameState.npcs[w]["relation"] = "former_warden"


func _investigation() -> void:
	var l := L()
	GameState.counter("gd_investigations")
	var lawyered := float(l["union"]) / 100.0 + float(l["standing"]) / 300.0
	var chance_clear := 0.25 + lawyered - float(int(l["corruption"])) * 0.06
	if randf() < chance_clear:
		GameState.add_log("Internal Affairs interviewed me for six hours. They had a pattern but not a proof. The file was marked 'insufficient', and I was moved to nights.")
		clampg(l, "ia_heat", -25.0)
		clampg(l, "standing", -8.0)
		GameState.apply_effects({"stress": 10})
		return
	if int(l["corruption"]) >= 3 or randf() < 0.5:
		GameState.add_log("The charge was misconduct in a public office. There was a trial, a short one, and the evidence was a ledger in my own handwriting.")
		l["fired"] = true
		l["convicted"] = true
		switch_to_prisoner("convicted")
	else:
		GameState.add_log("I was dismissed after a hearing. I kept my freedom and lost everything else: the pension, the rank, the place at the table.")
		l["fired"] = true
		conclude("fired")


## The oldest story the building has.
func switch_to_prisoner(why: String) -> void:
	var p := _p()
	var old := L().duplicate(true)
	var f: Dictionary = old.get("fac", {}).duplicate(true)
	var sentence := randi_range(3, 7) + int(old.get("corruption", 0))
	p["life"] = {"type": "prisoner", "role": "prisoner", "story": "fallen", "served": 0, "number": "%02d-%04d" % [randi_range(10, 99), randi_range(1000, 9999)], "block": "A", "inherit": {}, "fac": f,
		"crime": "misconduct in public office", "sentence": sentence, "eligible": int(ceil(float(sentence) * 0.6)), "innocent": false,
		"respect": 5.0, "heat": 40.0, "conduct": 50.0, "support": 45.0, "appeal": 0.0, "lawyer": 35.0, "dues": 0.0, "gang": "", "gang_rank": 0, "rep": {}, "job": "none", "programs": [],
		"stash": 0, "intel": old.get("intel", []), "escape": 0, "crew": [], "plan_age": -1, "riots": 0, "attacks": 0, "solitary_years": 0, "hearings": 0, "denied": 0, "parole_mood": 0.0,
		"exonerated": false, "paroled": false, "escaped": false, "caught": false, "ex_guard": true, "visits": 0, "fugitive_years": 0, "flags": {}, "snitched": 0, "debt_cigs": 0}
	var l := L()
	for gk in GANGS.keys():
		l["rep"][gk] = float(randi_range(-60, -25))
	GameState.player["money"] = 200
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if str(n["relation"]) in ["co_guard", "supervisor"]:
			n["relation"] = "officer"
			n["closeness"] = 5
	GameState.counter("gd_fallen")
	GameState.add_milestone(int(p["age"]), "was sent to prison in the building where they had worked")
	GameState.add_log("They put me on Block A. A man on the next landing looked at me for a long time and said, quite softly, my old badge number.")
	GameState.apply_effects({"happiness": -25, "stress": 25})
	EventEngine.push_info("🔒", "The other side of the door", "You know every officer by name, every sound of the locks and the exact schedule of the count.\n\nSo does everyone else. They know your name, too.\n\nYou have %d years to serve in the building you used to guard." % sentence)

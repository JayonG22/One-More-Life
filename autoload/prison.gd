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
	"hearing", "parole_mood", "exonerate", "merit", "integrity", "control", "ia_heat", "trauma", "union", "standing", "corruption", "commend", "incident", "whistle", "switch", "promote", "bribe", "flag", "then", "caught", "free", "kill", "debt", "pay", "inmate", "friend", "enemy", "transfer", "sentence", "burnout", "ring", "lawyer", "force_bad", "lives_saved"]

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
	if bool(l.get("fugitive", false)):
		_fugitive_year()
		_outside_year()
		return
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
	var base: float = float({"minimum": 0.6, "medium": 1.0, "maximum": 1.8}.get(sec, 1.0))
	var hd: float = -base - float(f["tension"]) / 60.0 + (1.0 if l.get("job", "none") == "kitchen" else 0.0)
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
	p["money"] = int(p["money"]) + pay / 5
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


# ---------------------------------------------------------------- the people outside

func _outside_year() -> void:
	var p := _p()
	var l := L()
	var guard := is_guard()
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n["alive"] or str(n.get("species", "human")) != "human":
			continue
		var rel := str(n["relation"])
		if rel in ["mother", "father", "sibling", "partner", "child", "best_friend", "inmate", "cellmate", "officer", "co_guard", "supervisor", "warden", "lawyer", "former_warden", "ex"]:
			n["age"] = int(n["age"]) + 1
		if rel in ["mother", "father"] and int(n["age"]) > 68 and randf() < 0.025 + float(int(n["age"]) - 68) * 0.014:
			n["alive"] = false
			l["bereaved"] = int(l.get("bereaved", 0)) + 1
			GameState.add_milestone(int(p["age"]), "lost %s %s" % ["their" if true else "", rel])
			if guard:
				GameState.add_log("My %s died in the spring. I took the allowed three days and was back on the wing on the fourth, because the roster had a hole in it." % rel)
			else:
				GameState.add_log("A chaplain came to the cell with a form and a face. My %s was dead. There was a request for an escorted visit to the funeral, and the answer was a stamp." % rel if randf() < 0.5 else "The news came in a plain envelope. My %s had died, and the letter had taken eleven days to get to me." % rel)
				clampg(l, "support", -8.0)
			GameState.apply_effects({"happiness": -12, "stress": 10})
			continue
		if rel in ["inmate", "cellmate"] and int(n["age"]) > 65 and randf() < 0.1:
			n["alive"] = false
	# a partner decides what to do about the years
	var par := str(p.get("partner", ""))
	if par != "" and GameState.npcs.has(par) and GameState.npcs[par]["alive"]:
		var n2: Dictionary = GameState.npcs[par]
		var leave := 0.0
		if guard:
			leave = 0.02 + float(l.get("trauma", 0)) / 1400.0 + float(l.get("burnout", 0)) / 900.0
		else:
			leave = 0.035 + float(int(l.get("served", 0)) - 1) * 0.012 - float(l.get("support", 50)) / 1100.0
		if randf() < leave:
			n2["relation"] = "ex"
			p["partner"] = ""
			p["partner_status"] = ""
			clampg(l, "support", -14.0)
			GameState.apply_effects({"happiness": -14, "stress": 8})
			GameState.add_milestone(int(p["age"]), "was left by %s" % str(n2["first"]))
			GameState.add_log(pick([
				"%s said it kindly, on the phone, in the prescribed fifteen minutes. There was a second voice in the background, and a kettle." % str(n2["first"]),
				"The letter was two pages. I read it once, and then I folded it into the smallest square I could, and then I did not know what to do with my hands.",
				"%s stopped coming. Not with a row, not with a decision, but with a slow set of apologies that got further and further apart." % str(n2["first"])] if not guard else [
				"%s packed a bag on a Thursday. I had been on a double, and when I got in, the house was tidy and quiet in a way I recognised from the wing." % str(n2["first"]),
				"%s said I had brought the building home with me. I said that was not fair. We both knew that it was." % str(n2["first"])]))
	# the children grow up
	for cid in GameState.npcs_with("child"):
		var c: Dictionary = GameState.npcs[cid]
		if int(c["age"]) == 18 and not guard:
			if float(l.get("support", 50)) > 55.0:
				GameState.add_log("%s turned eighteen. A card came, with a photograph, and a sentence in a handwriting I had last seen as a scrawl." % str(c["first"]))
				GameState.apply_effects({"happiness": 4})
			else:
				GameState.add_log("%s turned eighteen. I only knew because the date was on a form the prison sent out about visitors. I did not get a card." % str(c["first"]))
				c["closeness"] = int(c["closeness"]) - 10
				GameState.apply_effects({"happiness": -6})
		elif not guard and int(l.get("served", 0)) > 3 and randf() < 0.1:
			c["closeness"] = maxi(0, int(c["closeness"]) - 6)


# ---------------------------------------------------------------- set pieces

func _incidents() -> void:
	if not GameState.is_alive() or bool(L().get("fugitive", false)):
		return
	var f := F()
	var t := float(f["tension"])
	var role := "gd" if is_guard() else "pr"
	# a riot is built over years and arrives in one night
	if t >= 78.0 and randf() < 0.45 + (t - 78.0) / 60.0:
		var id := "%s.riot.1" % role
		if ContentDB.events_by_id.has(id):
			f["tension"] = maxf(35.0, t - 30.0)
			f["riots"] = int(f.get("riots", 0)) + 1
			f["order"] = maxf(15.0, float(f["order"]) - 10.0)
			EventEngine._enqueue(ContentDB.events_by_id[id], {})
			return
	if t >= 68.0 and int(f.get("lockdown", 0)) == 0 and randf() < 0.2:
		f["lockdown"] = 1
		GameState.add_log(pick(["The alarm went and the building was sealed. Nothing was said for six hours.", "A lockdown: doors, doors and more doors, and the sound of the building holding its breath."]))
	if is_guard() and t >= 58.0 and randf() < 0.1:
		var hid := "gd.hostage.1"
		if ContentDB.events_by_id.has(hid):
			EventEngine._enqueue(ContentDB.events_by_id[hid], {})


# ================================================================ death and endings

func death_check() -> String:
	var l := L()
	if not GameState.is_alive():
		return ""
	var age := int(_p()["age"])
	var health := GameState.stat("health")
	if bool(l.get("fugitive", false)):
		if health <= 0.0:
			return "a hard winter on the run"
		return ""
	if health <= 0.0:
		if is_guard():
			return pick(["a heart attack on the wing", "injuries from an assault on duty", "a collapse at the end of a double shift"])
		if int(l.get("attacks", 0)) >= 1 and randf() < 0.6:
			return pick(["wounds from a fight on the yard", "a stabbing in the shower block", "a beating in the stairwell"])
		return pick(["illness in the infirmary", "a heart attack on the landing", "complications nobody treated in time"])
	if age >= 72 and randf() < 0.05 + float(age - 72) * 0.03:
		return "old age, " + ("in the infirmary wing" if is_prisoner() else "long after retirement")
	if is_prisoner() and randf() < 0.004 + float(l.get("dues", 0)) / 6000.0 and int(l.get("served", 0)) > 1:
		return "an attack nobody saw coming"
	return ""


## The end of the story, for any of the reasons a story here can end.
func conclude(kind: String) -> void:
	if not GameState.is_alive():
		return
	var l := L()
	var p := _p()
	l["outcome"] = kind
	var yrs := int(l.get("served", 0))
	var lbl: String = {
		"served": "Released, sentence served in full after %d years" % yrs,
		"paroled": "Paroled after %d years" % yrs,
		"exonerated": "Exonerated after %d years" % yrs,
		"escaped": "Escaped — never found",
		"retired": "Retired with a pension after %d years on the staff" % yrs,
		"fired": "Dismissed from the service after %d years" % yrs,
		"warden": "Retired as Warden after %d years on the staff" % yrs,
		"resigned": "Walked out of the gate for the last time",
	}.get(kind, "The story closes")
	match kind:
		"served":
			l["released"] = true
		"paroled":
			l["paroled"] = true
			l["released"] = true
		"exonerated":
			l["exonerated"] = true
			l["released"] = true
		"escaped":
			l["escaped"] = true
	if kind == "retired" and int(l.get("rank", 1)) >= RANK_G.size() - 1:
		l["outcome"] = "warden"
		lbl = "Retired as Warden after %d years on the staff" % yrs
	GameState.add_milestone(int(p["age"]), lbl.to_lower())
	GameState.add_log(epilogue(l["outcome"]))
	GameState.counter("pr_" + str(l["outcome"]))
	EventEngine.kill(lbl, true)


func epilogue(kind: String) -> String:
	var l := L()
	var nm := str(_p()["first"])
	var w := ""
	var par := str(_p().get("partner", ""))
	match kind:
		"served":
			w = "The gate opened at 7.40 on a Tuesday, with a clear plastic bag, a travel warrant and a form. %s waited on the other side for a long moment, unsure which direction to face." % nm
		"paroled":
			w = "The board's decision came in an envelope and was read aloud twice. There were conditions, a curfew, an officer to report to, and the first night of choosing what to eat."
		"exonerated":
			w = "The judge said it plainly, in front of people who had said the opposite. %s walked out into a corridor full of cameras, with a sum of money that could not be spent on the years." % nm
		"escaped":
			w = "A different name, a different town, and a window that looks out on a field. %s kept the habit of sitting facing the door for the rest of their life." % nm
		"retired":
			w = "A cake, a clock and a card signed by people who did not mean it equally. The keys went into a drawer. %s sleeps with the window open now." % nm
		"warden":
			w = "The office was bigger than it looked from outside, and quieter. %s signed the last order, and gave the keys, one at a time, to the officer who was ready for them." % nm
		"fired":
			w = "A box, a lanyard and a security escort to the car park. %s stood by the car for a long time, with the door open, and nothing at all to go back to." % nm
		_:
			w = "The story of %s closed, as stories here do, without any ceremony." % nm
	if par != "" and GameState.npcs.has(par) and str(GameState.npcs[par].get("relation", "")) == "partner" and kind in ["served", "paroled", "exonerated"]:
		w += " %s was there, in the good coat, and said nothing for a while." % str(GameState.npcs[par]["first"])
	if int(l.get("kids_out", 0)) > 0:
		w += " The children were taller."
	return w


func story() -> String:
	var p := _p()
	var l := L()
	var he := GameState.pron(str(p["gender"]), "he")
	var lines: Array = []
	var full := "%s %s" % [p["first"], p["last"]]
	if is_guard() or bool(l.get("ex_guard", false)):
		lines.append("%s joined the staff at %s in %d." % [full, str(F()["name"]), int(p["born_year"]) + 22])
	else:
		lines.append("%s was sentenced to %d years for %s, and sent to %s." % [full, int(l.get("sentence", 0)), str(l.get("crime", "a crime")), str(F()["name"])])
	var seen := false
	for m in GameState.milestones:
		if not seen and (str(m["text"]).begins_with("was sentenced") or str(m["text"]).begins_with("joined the staff")):
			seen = true
			continue
		lines.append("At %d, %s %s." % [int(m["age"]), he, str(m["text"])])
	lines.append(epilogue(str(l.get("outcome", "died"))) if str(l.get("outcome", "")) != "" else "%s died at %d of %s." % [he.capitalize(), int(p["age"]), str(p["cause"])])
	return "\n".join(lines)


func ribbon() -> Dictionary:
	var e := Arcs.ending()
	var id := str(e.get("id", ""))
	var table := {
		"pr_exonerated": {"name": "Exonerated", "icon": "⚖️", "desc": "The truth took eighteen years and arrived."},
		"pr_ghost": {"name": "A Ghost", "icon": "🌫️", "desc": "They stopped looking. You never stopped checking the door."},
		"pr_fallen": {"name": "The Other Side of the Door", "icon": "🔒", "desc": "You knew the building from both sides."},
		"pr_paroled": {"name": "Paroled", "icon": "🪪", "desc": "A board believed you. You went out and did not come back."},
		"pr_served": {"name": "Every Day of It", "icon": "📅", "desc": "Nobody gave you anything. You walked out on the last day."},
		"pr_legend": {"name": "Old Head", "icon": "👑", "desc": "The block is quieter without you, and it knows it."},
		"pr_died": {"name": "Never Out", "icon": "🕯️", "desc": "The building kept you."},
		"pr_inside": {"name": "Still Inside", "icon": "⛓️", "desc": "The sentence is longer than the story."},
		"gd_warden": {"name": "Warden", "icon": "🗝️", "desc": "You ran the building, and the building ran you."},
		"gd_whistle": {"name": "Whistleblower", "icon": "📣", "desc": "You told. It cost you everything it was supposed to."},
		"gd_hero": {"name": "Hero of the Wing", "icon": "🎖️", "desc": "You were there when it counted, and you did the right thing."},
		"gd_kingpin": {"name": "The Man With the Keys", "icon": "💰", "desc": "Nothing came in without you. Nothing came out without a price."},
		"gd_burned": {"name": "Burned Out", "icon": "🔥", "desc": "You did the time on the other side, in your head."},
		"gd_fired": {"name": "Dismissed", "icon": "📦", "desc": "A box and an escort to the car park."},
		"gd_retired": {"name": "Thirty Years", "icon": "⏰", "desc": "A clock, a pension and a habit of sitting facing the door."},
		"gd_duty": {"name": "In the Line of Duty", "icon": "🕯️", "desc": "Your name is on the wall in the hall."},
		"gd_fell": {"name": "On the Other Side", "icon": "🔒", "desc": "They sent you to the building you worked in."},
	}
	return table.get(id, table["gd_duty"] if is_guard() else table["pr_died"])


func entry_extra() -> Dictionary:
	var l := L()
	var f := F()
	var role := "guard" if is_guard() else "prisoner"
	var card: Array = []
	card.append(["Facility", str(f["name"])])
	if is_guard():
		card.append(["Final rank", rank_name()])
		card.append(["Years on staff", str(served())])
		card.append(["Integrity", "%d%%" % int(l.get("integrity", 0))])
		card.append(["Incidents", str(int(l.get("incidents", 0)))])
		card.append(["Commendations", str(int(l.get("commend", 0)))])
	else:
		card.append(["Convicted of", str(l.get("crime", ""))])
		card.append(["Sentence", "%d years" % int(l.get("sentence", 0))])
		card.append(["Served", "%d years" % served()])
		card.append(["Standing", prisoner_rank()])
		card.append(["Gang", gang_name(my_gang()) if my_gang() != "" else "None"])
	return {"role": role, "icon": "🗝️" if is_guard() else "⛓️", "card": card, "outcome": str(l.get("outcome", "died")), "facility": str(f["name"]), "title": "Case closed", "rank": rank_name()}


# ================================================================ conditions

const NUM_FIELDS := ["respect", "heat", "conduct", "support", "appeal", "dues", "merit", "integrity", "control", "ia_heat", "trauma", "union", "standing", "served", "remaining", "tension", "order", "budget", "crowding",
	"riots", "attacks", "solitary_years", "hearings", "denied", "commend", "incidents", "corruption", "rank", "age", "health", "happy", "stress", "escape", "intel", "programs", "stash", "sentence", "eligible", "lawyer", "crew", "bribes", "force_bad", "burnout", "visits", "lives_saved", "bereaved"]


func tag(t: String) -> bool:
	if not active():
		return false
	var l := L()
	var f := F()
	for op in [">=", "<=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			var have := _num(t.substr(0, i))
			var v := float(t.substr(i + op.length()))
			match op:
				">=": return have >= v
				"<=": return have <= v
				">": return have > v
				"<": return have < v
				_: return absf(have - v) < 0.001
	if t.begins_with("gang:"):
		return my_gang() == t.substr(5)
	if t.begins_with("job:"):
		return str(l.get("job", "")) == t.substr(4)
	if t.begins_with("program:"):
		return Array(l.get("programs", [])).has(t.substr(8))
	if t.begins_with("story:"):
		return str(l.get("story", "")) == t.substr(6)
	if t.begins_with("sec:"):
		return str(f.get("security", "")) == t.substr(4)
	if t.begins_with("flag:"):
		return Dictionary(l.get("flags", {})).has(t.substr(5))
	if t.begins_with("warden:"):
		var w := str(f.get("warden", ""))
		return w != "" and GameState.npcs.has(w) and str(GameState.npcs[w].get("style", "")) == t.substr(7)
	if t.begins_with("intel:"):
		return has_intel(t.substr(6))
	match t:
		"prisoner": return is_prisoner()
		"guard": return is_guard()
		"inno": return bool(l.get("innocent", false))
		"gang": return my_gang() != ""
		"loner": return my_gang() == ""
		"lead": return int(l.get("gang_rank", 0)) >= 3
		"job": return str(l.get("job", "none")) != "none"
		"stash": return int(l.get("stash", 0)) > 0
		"plan": return int(l.get("escape", 0)) >= 1
		"crew": return not Array(l.get("crew", [])).is_empty()
		"debt": return float(l.get("dues", 0)) > 0.0
		"hurt": return GameState.stat("health") < 40.0
		"fugitive": return bool(l.get("fugitive", false))
		"ex_guard": return bool(l.get("ex_guard", false))
		"hearing_due": return bool(l.get("hearing_due", false))
		"cellmate": return GameState.first_of("cellmate") != ""
		"partner": return str(_p().get("partner", "")) != "" and GameState.npcs.has(str(_p()["partner"]))
		"kids": return not GameState.npcs_with("child").is_empty()
		"lockdown": return int(f.get("lockdown", 0)) > 0
		"war": return int(f.get("war", 0)) > 0
		"newbie": return served() <= 1
		"veteran": return served() >= 8
		"bribed": return int(l.get("corruption", 0)) >= 1
		"solitary_before": return int(l.get("solitary_years", 0)) >= 1
		"unwell": return GameState.stat("health") < 55.0
		"snitched": return int(l.get("snitched", 0)) >= 1
		"whistle": return bool(l.get("whistle", false))
		"inherit": return not Dictionary(l.get("inherit", {})).is_empty()
	return false


func _num(f: String) -> float:
	var l := L()
	match f:
		"served": return float(served())
		"remaining": return float(remaining())
		"tension", "order", "budget", "crowding": return float(F().get(f, 0))
		"age": return float(_p().get("age", 0))
		"health": return GameState.stat("health")
		"happy": return GameState.stat("happiness")
		"stress": return GameState.stat("stress")
		"intel": return float(intel_n())
		"programs": return float(programs_n())
		"crew": return float(Array(l.get("crew", [])).size())
	return float(l.get(f, 0))


func known_tag(t: String) -> bool:
	for op in [">=", "<=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			return NUM_FIELDS.has(t.substr(0, i))
	for pre in ["gang:", "job:", "program:", "story:", "sec:", "flag:", "warden:", "intel:"]:
		if t.begins_with(pre):
			return true
	return ["prisoner", "guard", "inno", "gang", "loner", "lead", "job", "stash", "plan", "crew", "debt", "hurt", "fugitive", "ex_guard", "hearing_due", "cellmate", "partner", "kids", "lockdown", "war", "newbie", "veteran", "bribed", "solitary_before", "unwell", "snitched", "whistle", "inherit"].has(t)


# ================================================================ outcomes

func apply(ops: Dictionary) -> void:
	if not active():
		return
	var l := L()
	var f := F()
	for k in ops.keys():
		var v = ops[k]
		match str(k):
			"respect", "heat", "conduct", "support", "appeal", "dues", "merit", "integrity", "control", "ia_heat", "trauma", "union", "standing", "lawyer":
				clampg(l, str(k), float(v))
			"tension", "order", "budget":
				f[k] = clampf(float(f[k]) + float(v), 0.0, 100.0)
			"gang":
				l["gang"] = str(v)
				if str(v) != "":
					l["gang_rank"] = maxi(1, int(l.get("gang_rank", 0)))
					l["rep"][str(v)] = float(l["rep"].get(str(v), 0)) + 20.0
				else:
					l["gang_rank"] = 0
			"gang_rank":
				l["gang_rank"] = clampi(int(l.get("gang_rank", 0)) + int(v), 0, 4)
			"rep":
				for gk in Dictionary(v).keys():
					var key := my_gang() if str(gk) == "mine" else str(gk)
					if key != "":
						l["rep"][key] = clampf(float(l["rep"].get(key, 0)) + float(v[gk]), -100.0, 100.0)
			"job":
				l["job"] = str(v)
			"program":
				if not Array(l["programs"]).has(str(v)):
					l["programs"].append(str(v))
					GameState.counter("pr_programs")
			"stash":
				l["stash"] = maxi(0, int(l.get("stash", 0)) + int(v))
			"intel":
				if v is Array:
					add_intel(str(v[0]), str(v[1]), 1)
				else:
					add_intel("rumour", str(v))
			"escape":
				l["escape"] = clampi(int(l.get("escape", 0)) + int(v), 0, 5)
			"crew":
				for _i in range(int(v)):
					_recruit()
			"solitary":
				_solitary("It was written up and it was real.")
			"attack":
				_attacked()
			"riot":
				l["riots"] = int(l.get("riots", 0)) + int(v)
				GameState.counter("pr_riots", int(v))
			"hearing":
				l["hearing_due"] = true
			"parole_mood":
				l["parole_mood"] = clampf(float(l.get("parole_mood", 0)) + float(v), -50.0, 50.0)
			"exonerate":
				conclude("exonerated")
			"corruption":
				l["corruption"] = int(l.get("corruption", 0)) + int(v)
				GameState.counter("gd_corrupt", int(v))
			"bribe":
				_p()["money"] = int(_p()["money"]) + int(v)
				l["corruption"] = int(l.get("corruption", 0)) + 1
				l["bribes"] = int(l.get("bribes", 0)) + 1
				clampg(l, "ia_heat", 10.0)
				clampg(l, "integrity", -9.0)
				GameState.counter("gd_corrupt")
			"commend":
				l["commend"] = int(l.get("commend", 0)) + int(v)
				GameState.counter("gd_commend", int(v))
			"incident":
				l["incidents"] = int(l.get("incidents", 0)) + int(v)
				GameState.counter("gd_incidents", int(v))
			"whistle":
				l["whistle"] = true
				clampg(l, "ia_heat", -30.0)
				clampg(l, "standing", -25.0)
				clampg(l, "union", -30.0)
				GameState.counter("gd_whistle")
			"force_bad":
				l["force_bad"] = int(l.get("force_bad", 0)) + int(v)
			"lives_saved":
				l["lives_saved"] = int(l.get("lives_saved", 0)) + int(v)
				GameState.counter("gd_saved", int(v))
			"switch":
				if is_guard():
					switch_to_prisoner("ordered")
			"promote":
				if is_guard() and int(l["rank"]) < RANK_G.size() - 1:
					_promote()
			"flag":
				l["flags"][str(v)] = int(_p().get("age", 0))
			"caught":
				_recaptured()
			"free":
				conclude("escaped")
			"kill":
				EventEngine.kill(str(v))
			"debt":
				clampg(l, "dues", float(v))
			"pay":
				_p()["money"] = int(_p()["money"]) + int(v)
			"inmate":
				new_inmate(str(v), randi_range(24, 55))
			"friend":
				var fid := new_inmate("", randi_range(24, 55))
				GameState.npcs[fid]["closeness"] = 60
				GameState.npcs[fid]["trust"] = 60
			"enemy":
				var eid := new_inmate("", randi_range(24, 55))
				GameState.npcs[eid]["closeness"] = 2
				GameState.npcs[eid]["trust"] = 0
				GameState.npcs[eid]["grudge"] = 60
			"sentence":
				if is_prisoner():
					l["sentence"] = maxi(served() + 1, int(l.get("sentence", 0)) + int(v))
			"transfer":
				_transfer(str(v))
			"then":
				if ContentDB.events_by_id.has(str(v)):
					EventEngine._enqueue(ContentDB.events_by_id[str(v)], {})
			"burnout":
				clampg(l, "burnout", float(v))
			"ring":
				l["ring"] = float(l.get("ring", 0)) + float(v)
	GameState.emit_changed()


func _recruit() -> void:
	var l := L()
	var id := new_inmate("", randi_range(24, 50))
	GameState.npcs[id]["relation"] = "crewmate"
	GameState.npcs[id]["closeness"] = 55
	GameState.npcs[id]["trust"] = randi_range(35, 70)
	l["crew"].append(id)


func _transfer(kind: String) -> void:
	var l := L()
	var f := F()
	match kind:
		"worse":
			f["security"] = "maximum"
		"better":
			f["security"] = "minimum" if str(f["security"]) == "medium" else "medium"
		_:
			pass
	l["block"] = pick(BLOCKS)
	l["gang"] = ""
	l["gang_rank"] = 0
	l["escape"] = 0
	l["crew"] = []
	GameState.add_log("I was transferred, with a bag, to a building that was almost identical and entirely different. %s" % pick(["Everything I knew was a rumour here.", "Nobody knew my name, which was an advantage and a danger.", "I started again, from the bottom of a new ladder."]))
	l["respect"] = maxf(5.0, float(l["respect"]) * 0.4)
	GameState.apply_effects({"stress": 8})


# ================================================================ the case

## The board's decision. `score` is how the hearing went, 0..1.
func hearing_result(score: float) -> bool:
	var l := L()
	var base := float(l["conduct"]) / 100.0 * 0.32 + float(programs_n()) * 0.04 + float(l["support"]) / 100.0 * 0.08 + float(l.get("parole_mood", 0)) / 200.0
	var chance := 0.1 + base + score * 0.38 + float(int(l.get("denied", 0))) * 0.02 - float(l["heat"]) / 450.0
	if bool(l.get("innocent", false)):
		chance -= 0.12     # the board wants remorse; the innocent have none to give
	chance = clampf(chance, 0.04, 0.9)
	l["hearings"] = int(l.get("hearings", 0)) + 1
	l["hearing_due"] = false
	GameState.counter("pr_hearings")
	if randf() < chance:
		conclude("paroled")
		return true
	l["denied"] = int(l.get("denied", 0)) + 1
	GameState.apply_effects({"happiness": -10, "stress": 8})
	GameState.add_log(pick([
		"The board gave its reasons in a calm voice that made them worse: the nature of the offence, the need for further work, the interest of the public.",
		"Denied. They said it would be reviewed in a year. A year is a long time to be reviewed.",
		"The chair did not look at me when she read it. She looked at the papers, as though they had a better chance of making sense."]))
	return false


func _recaptured() -> void:
	var l := L()
	l["fugitive"] = false
	l["caught"] = true
	l["escaped"] = false
	l["escape"] = 0
	l["crew"] = []
	l["sentence"] = int(l.get("sentence", 0)) + randi_range(4, 8)
	l["eligible"] = int(l.get("eligible", 0)) + 6
	l["fugitive_years"] = 0
	GameState.counter("pr_recaptured")
	GameState.add_milestone(int(_p()["age"]), "was brought back in")
	GameState.add_log("They found me on a Tuesday. It was almost an anticlimax: two cars, a calm voice, and a pair of cuffs that felt familiar. I was returned to the building with a longer sentence and a name on a list.")
	GameState.apply_effects({"happiness": -20, "stress": 20})
	_solitary("They put me in the segregation unit before they had finished the paperwork.")
	l["respect"] = clampf(float(l["respect"]) + 8.0, 0.0, 100.0)


# ================================================================ menus

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "pr:" + act, "arg": arg, "on": on}


func _sub(icon: String, name: String, sub: String, key: String) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "menu": "pr:" + key}


func _left() -> int:
	return int(_p().get("time_left", 0))


func _bar(v: float) -> String:
	var n := int(clampf(v, 0.0, 100.0) / 10.0)
	return "█".repeat(n) + "░".repeat(10 - n)


func menu(key: String) -> Dictionary:
	return _menu_guard(key) if is_guard() else _menu_prisoner(key)


func _people_rows(rels: Array, act: String, icon: String, limit: int) -> Array:
	var rows: Array = []
	var n := 0
	for r in rels:
		for id in GameState.npcs_with(r):
			if n >= limit:
				return rows
			var c: Dictionary = GameState.npcs[id]
			rows.append(_row(icon, "%s %s" % [str(c["first"]), str(c["last"])], "%s · %d · trust %d%%" % [relation_name(str(c["relation"]), str(c.get("gender", "male"))) if relation_name(str(c["relation"]), "") != "" else GameState.relation_label(id), int(c["age"]), int(c.get("trust", c["closeness"]))], act, id, _left() >= 1 and did(act + "_" + id) < 1))
			n += 1
	return rows


func _menu_prisoner(key: String) -> Dictionary:
	var l := L()
	var f := F()
	var rows: Array = []
	var info: Array = []
	var money := int(_p()["money"])
	if bool(l.get("fugitive", false)):
		return _menu_run(key)
	match key:
		"home", "":
			info.append("%s · %s · %s, block %s" % [number_label(), prisoner_rank(), str(SECURITY[str(f["security"])]), str(l["block"])])
			info.append("%d year%s served, %d to go%s" % [served(), "" if served() == 1 else "s", remaining(), (" · parole board from year %d" % int(l["eligible"])) if not bool(l.get("paroled", false)) else ""])
			info.append("Conduct %s %d · Heat %s %d" % [_bar(float(l["conduct"])), int(l["conduct"]), _bar(float(l["heat"])), int(l["heat"])])
			info.append("The building: tension %d%% · %s" % [int(f["tension"]), "LOCKDOWN" if int(f.get("lockdown", 0)) > 0 else ("gang war" if int(f.get("war", 0)) > 0 else ("calm" if float(f["tension"]) < 35.0 else ("uneasy" if float(f["tension"]) < 65.0 else "about to go")))])
			if bool(l.get("hearing_due", false)):
				info.append("⚖️ A parole hearing is due this year. See Your case.")
			info.append("Time left this year: %d · commissary $%d" % [_left(), money])
			rows.append(_sub("🛏️", "Daily routine", "Work, gym, study, yard, faith, letters", "routine"))
			rows.append(_sub("🚬", "The economy", "Commissary, trade, cards, contraband, debts", "hustle"))
			rows.append(_sub("👥", "The building", "Cellmate, inmates, officers, informing", "people"))
			rows.append(_sub("🔗", "Gangs and protection", "Who has your back, and what it costs", "gang"))
			rows.append(_sub("⚖️", "Your case", "Parole, appeal, lawyer, programmes", "case"))
			rows.append(_sub("🕳️", "The plan", "Intel, tools, a crew and a night", "plan"))
			return {"icon": "⛓️", "title": "Inside", "rows": rows, "info": info}
		"routine":
			var job: Dictionary = JOBS[str(l.get("job", "none"))]
			rows.append(_sub("%s" % job["icon"], "Job: %s" % job["name"], str(job["desc"]), "jobs"))
			rows.append(_sub("🎓", "Programmes", "%d completed" % programs_n(), "programs"))
			rows.append(_row("🏋️", "Work out", "Health and presence; heat down a little", "gym", null, _left() >= 1 and did("gym") < 2))
			rows.append(_row("📖", "Study in the library", "Wits up" + ("; the law books help your appeal" if bool(l.get("innocent", false)) else ""), "study", null, _left() >= 1 and did("study") < 2))
			rows.append(_row("🌳", "Walk the yard", "Respect, rumours, and who is watching", "yard", null, _left() >= 1 and did("yard") < 2))
			rows.append(_row("🕯️", "Go to the chapel", "Strain down, conduct up", "faith", null, _left() >= 1 and did("faith") < 1))
			rows.append(_row("🤫", "Keep your head down", "Heat down; nothing happens, which is the point", "lowprofile", null, _left() >= 1 and did("low") < 1))
			rows.append(_row("✉️", "Write a letter", "Support from outside up", "letter", null, _left() >= 1 and did("letter") < 2))
			rows.append(_row("📞", "Make a phone call", "Costs $60. The clock runs on every call", "call", null, _left() >= 1 and money >= 60 and did("call") < 1))
			return {"icon": "🛏️", "title": "Daily routine", "rows": rows, "info": ["Conduct %d · Heat %d · Support from outside %d" % [int(l["conduct"]), int(l["heat"]), int(l["support"])]]}
		"jobs":
			for jk in JOBS.keys():
				var jd: Dictionary = JOBS[jk]
				var need := 55 if jk in ["library", "infirmary"] else (35 if jk != "none" else 0)
				rows.append(_row(str(jd["icon"]), str(jd["name"]), "%s · needs conduct %d" % [jd["desc"], need], "job", jk, str(l.get("job", "none")) != jk and float(l["conduct"]) >= float(need) and _left() >= 1))
			return {"icon": "🔧", "title": "Prison jobs", "rows": rows, "info": ["Pay is a few hundred a year. The real prize is the hours: a job fills the day, and a full day is hard to get into trouble in."]}
		"programs":
			for pk in PROGRAMS.keys():
				var pd: Dictionary = PROGRAMS[pk]
				var done := Array(l.get("programs", [])).has(pk)
				var okp: bool = not done and _left() >= 2 and float(l["conduct"]) >= 30.0 and (pk != "college" or Array(l.get("programs", [])).has("ged"))
				rows.append(_row(str(pd["icon"]), "%s%s" % [pd["name"], " ✓" if done else ""], str(pd["desc"]) + (" (needs the diploma first)" if pk == "college" else ""), "program", pk, okp))
			return {"icon": "🎓", "title": "Programmes", "rows": rows, "info": ["The parole board reads this list. Every one is a line in your file."]}
		"hustle":
			rows.append(_row("🛒", "Visit the commissary", "$80: strain down, morale up", "commissary", null, money >= 80 and _left() >= 1 and did("commissary") < 2))
			rows.append(_row("🃏", "Play cards", "Win a little or lose a lot; respect rides on it", "cards", null, _left() >= 1 and did("cards") < 2))
			rows.append(_row("🤝", "Trade what you have", "Sell contraband: a negotiation. %d in your stash" % int(l.get("stash", 0)), "trade", null, int(l.get("stash", 0)) > 0 and _left() >= 2 and did("trade") < 1))
			rows.append(_row("📦", "Get something in", "Through a visitor, an officer or the yard. Risky", "smuggle", null, _left() >= 1 and did("smuggle") < 2))
			rows.append(_row("💵", "Lend on interest", "Cigarettes become dollars become leverage", "loan", null, money >= 100 and _left() >= 1 and did("loan") < 1))
			rows.append(_row("🖋️", "Do ink and haircuts", "Money, and a reason for people to talk to you", "ink", null, _left() >= 1 and did("ink") < 1 and (str(l.get("job", "")) == "barber" or float(l["respect"]) > 20.0)))
			if float(l.get("dues", 0)) > 0.0:
				rows.append(_row("💸", "Pay what you owe", "Debt %d%% · $200 clears most of it" % int(l["dues"]), "paydues", null, money >= 200))
			info.append("Stash: %d · Debts: %s · Commissary $%d" % [int(l.get("stash", 0)), "%d%%" % int(l.get("dues", 0)) if float(l.get("dues", 0)) > 0.0 else "none", money])
			return {"icon": "🚬", "title": "The economy", "rows": rows, "info": info}
		"people":
			rows.append_array(_people_rows(["cellmate", "inmate", "crewmate"], "talk", "🧍", 6))
			rows.append_array(_people_rows(["officer", "lawyer"], "talk", "👮", 3))
			rows.append(_row("🐀", "Inform on someone", "Staff will like it. Nobody else will", "snitch", null, _left() >= 1 and did("snitch") < 1))
			rows.append(_row("🛡️", "Look out for a weaker inmate", "Respect, either way. A debt of gratitude", "protect", null, _left() >= 1 and did("protect") < 1))
			info.append("Everyone in here is reading you. Be careful what they read.")
			return {"icon": "👥", "title": "The building", "rows": rows, "info": info}
		"gang":
			if my_gang() == "":
				info.append("No one's. That is a position, and it has costs: nobody is behind you.")
				for gk in GANGS.keys():
					var gd: Dictionary = GANGS[gk]
					rows.append(_row(str(gd["icon"]), "Join %s" % str(gd["name"]), str(gd["desc"]), "join", gk, _left() >= 1 and float(l["respect"]) >= 15.0 and float(l["rep"].get(gk, 0)) > -40.0 and did("join") < 1))
				rows.append(_row("🏳️", "Ask for protective custody", "Safer, duller, and you will be known for it", "pc", null, _left() >= 1 and not bool(l.get("flags", {}).has("pc"))))
			else:
				var gd2: Dictionary = GANGS[my_gang()]
				info.append("%s %s · rank: %s" % [gd2["icon"], gd2["name"], gang_rank_name(int(l.get("gang_rank", 0)))])
				for gk2 in GANGS.keys():
					info.append("%s: standing %d" % [GANGS[gk2]["name"], int(l["rep"].get(gk2, 0))])
				rows.append(_row("🛠️", "Do a favour for the gang", "Rank and standing; a risk of heat", "favor", null, _left() >= 1 and did("favor") < 2))
				rows.append(_row("📈", "Press for promotion", "A fight or a task; they will test you", "rankup", null, _left() >= 2 and did("rankup") < 1 and int(l.get("gang_rank", 0)) < 4))
				rows.append(_row("🚪", "Leave the gang", "It costs. Possibly in blood", "leave", null, _left() >= 1))
			return {"icon": "🔗", "title": "Gangs and protection", "rows": rows, "info": info}
		"case":
			info.append("Sentence %d years · served %d · parole board from year %d · denied %d time%s" % [int(l["sentence"]), served(), int(l["eligible"]), int(l.get("denied", 0)), "" if int(l.get("denied", 0)) == 1 else "s"])
			if bool(l.get("innocent", false)):
				info.append("Appeal %s %d%%" % [_bar(float(l["appeal"])), int(l["appeal"])])
				info.append("Your lawyer: %d%% effective" % int(l["lawyer"]))
			rows.append(_row("⚖️", "Go before the parole board", "A hearing is due. A game of tone and truth. Takes 2", "hearing", null, bool(l.get("hearing_due", false)) and _left() >= 2))
			rows.append(_row("🔍", "Research your case", "Read the file, find the hole. Takes 2", "research", null, _left() >= 2 and did("research") < 1 and (bool(l.get("innocent", false)) or float(l["appeal"]) > 0.0 or true)))
			rows.append(_row("☎️", "Call your lawyer", "Takes 1", "lawyer", null, _left() >= 1 and did("lawyer") < 1))
			rows.append(_row("💼", "Pay for a better lawyer", "$5,000. Lawyer effectiveness up", "better_lawyer", null, money >= 5000 and did("better_lawyer") < 1))
			rows.append(_row("📰", "Write to the press", "Pressure from outside. Heat, and sometimes help", "press", null, _left() >= 1 and did("press") < 1))
			return {"icon": "⚖️", "title": "Your case", "rows": rows, "info": info}
		"plan":
			var st := plan_stage()
			info.append("Stage %d of 5: %s" % [st, PLAN_STAGES[st]])
			info.append("Intel: %d piece%s · tools: %d · crew: %d" % [intel_n(), "" if intel_n() == 1 else "s", int(l.get("tools", 0)), Array(l.get("crew", [])).size()])
			for i in l.get("intel", []):
				info.append("• %s" % str(i.get("text", "")))
			rows.append(_row("👀", "Watch and listen", "Learn the routines. A game of stealth. Takes 2", "recon", null, _left() >= 2 and did("recon") < 1))
			rows.append(_row("📝", "Commit to a plan", "Needs three pieces of intel", "commit", null, st == 0 and intel_n() >= 3 and _left() >= 1))
			rows.append(_row("🪛", "Gather tools", "Stage 2. Steal, trade or have them brought in. Takes 2", "tools", null, st == 1 and _left() >= 2 and did("tools") < 1))
			rows.append(_row("🫂", "Recruit a crew", "Stage 3. You need two. Every one is a way for it to go wrong", "recruit", null, st == 2 and _left() >= 2 and did("recruit") < 1))
			rows.append(_row("🗝️", "Buy an inside man", "Stage 4. A bent officer, or leverage on one", "inside", null, st == 3 and _left() >= 2 and did("inside") < 1))
			rows.append(_row("🌩️", "Wait for the right night", "Stage 5. Cover, a lockdown, a storm, a count that goes wrong", "wait", null, st == 4 and _left() >= 1))
			rows.append(_row("🚪", "GO TONIGHT", "The break. There is no way back from this one", "breakout", null, st >= 5 and _left() >= 1))
			return {"icon": "🕳️", "title": "The plan", "rows": rows, "info": info}
	return {"icon": "⛓️", "title": "Inside", "rows": rows, "info": info}


func gang_rank_name(i: int) -> String:
	return str(GANG_RANK[clampi(i, 0, GANG_RANK.size() - 1)])


func _menu_run(key: String) -> Dictionary:
	var l := L()
	var rows: Array = []
	var info: Array = []
	var money := int(_p()["money"])
	info.append("%d year%s on the run · heat %d%% · %s" % [int(l.get("fugitive_years", 0)), "" if int(l.get("fugitive_years", 0)) == 1 else "s", int(l["heat"]), "a new name" if bool(l.get("flags", {}).has("identity")) else "your own name"])
	info.append("Time left: %d · cash $%d" % [_left(), money])
	rows.append(_row("🌫️", "Lie low", "Heat down. Nothing happens, which is the point", "run_low", null, _left() >= 1))
	rows.append(_row("🪪", "Get a new identity", "$2,500. The best thing you can buy", "run_id", null, money >= 2500 and not bool(l.get("flags", {}).has("identity")) and _left() >= 2))
	rows.append(_row("🧰", "Find cash-in-hand work", "A little money; a small risk", "run_work", null, _left() >= 2 and did("run_work") < 1))
	rows.append(_row("📨", "Get a message to your family", "Support up. Heat up a lot", "run_family", null, _left() >= 1 and did("run_family") < 1))
	rows.append(_row("🛤️", "Move on", "A different town. Heat down, cash down", "run_move", null, money >= 300 and _left() >= 2 and did("run_move") < 1))
	rows.append(_row("🏳️", "Turn yourself in", "Ends the run. A shorter extra sentence", "run_surrender", null, true))
	return {"icon": "🌫️", "title": "On the run", "rows": rows, "info": info}


func _menu_guard(key: String) -> Dictionary:
	var l := L()
	var f := F()
	var rows: Array = []
	var info: Array = []
	var money := int(_p()["money"])
	match key:
		"home", "":
			var nxt := ""
			if int(l["rank"]) < RANK_G.size() - 1:
				nxt = " · merit %d / %d for %s" % [int(l["merit"]), RANK_NEED[int(l["rank"]) + 1], RANK_G[int(l["rank"]) + 1]]
			info.append("%s · %s · year %d on the staff%s" % [rank_name(), str(f["name"]), served() + 1, nxt])
			info.append("Control %s %d · Integrity %s %d" % [_bar(float(l["control"])), int(l["control"]), _bar(float(l["integrity"])), int(l["integrity"])])
			info.append("Internal Affairs interest: %d%% · trauma %d%%" % [int(l["ia_heat"]), int(l["trauma"])])
			info.append("The building: tension %d%% · %s" % [int(f["tension"]), "LOCKDOWN" if int(f.get("lockdown", 0)) > 0 else ("gang war" if int(f.get("war", 0)) > 0 else ("calm" if float(f["tension"]) < 35.0 else ("uneasy" if float(f["tension"]) < 65.0 else "about to go")))])
			info.append("Time left this year: %d · savings $%d%s" % [_left(), money, (" · debt $%d" % int(l["debt"])) if int(l.get("debt", 0)) > 0 else ""])
			rows.append(_sub("🚨", "On shift", "Rounds, searches, fights, paperwork, overtime", "post"))
			rows.append(_sub("🧍", "The wing", "Know the inmates. They know you", "block"))
			rows.append(_sub("📈", "Career", "Training, union, transfers, mentoring", "career"))
			rows.append(_sub("🗝️", "Integrity", "Favours, offers, and what you report", "integrity"))
			return {"icon": "🗝️", "title": "On the staff", "rows": rows, "info": info}
		"post":
			rows.append(_row("🚶", "Walk the rounds", "Control up. The wing sees you", "rounds", null, _left() >= 1 and did("rounds") < 2))
			rows.append(_row("🔦", "Search a cell", "Contraband: a game of clues. Merit; the inmates resent it. Takes 2", "search", null, _left() >= 2 and did("search") < 1))
			rows.append(_row("🥊", "Break up a fight", "A use-of-force decision. It follows you", "fight", null, _left() >= 1 and did("fightbreak") < 1))
			rows.append(_row("🗂️", "Do the paperwork", "Merit, slowly. The reports are what get read", "paper", null, _left() >= 1 and did("paper") < 2))
			rows.append(_row("⏱️", "Take overtime", "Money; strain up. Takes 2", "overtime", null, _left() >= 2 and did("overtime") < 1))
			rows.append(_row("🧘", "Take a proper break", "Trauma down. Takes 2", "break", null, _left() >= 2 and did("break") < 1))
			if int(l["rank"]) >= 3:
				rows.append(_row("🔒", "Order a lockdown", "Tension down fast; everyone hates it. Takes 1", "lockdown", null, _left() >= 1 and int(f.get("lockdown", 0)) == 0))
			return {"icon": "🚨", "title": "On shift", "rows": rows, "info": ["Control %d · tension %d%% · order %d%%" % [int(l["control"]), int(f["tension"]), int(f["order"])]]}
		"block":
			rows.append_array(_people_rows(["inmate"], "gtalk", "🧍", 6))
			rows.append(_row("💬", "Walk the landing and listen", "Rumours, a chance of intel", "listen", null, _left() >= 1 and did("listen") < 2))
			rows.append(_row("📋", "Write someone up", "Control up, tension up. Be sure", "writeup", null, _left() >= 1 and did("writeup") < 2))
			rows.append(_row("🎓", "Counsel an inmate", "Integrity and a debt of trust. Slow", "counsel", null, _left() >= 1 and did("counsel") < 1))
			return {"icon": "🧍", "title": "The wing", "rows": rows, "info": ["Inmates are not a crowd. They are the ones who will warn you, or won't, at the wrong moment."]}
		"career":
			rows.append(_row("🎓", "Take a training course", "Merit up. Takes 2", "train", null, _left() >= 2 and did("train") < 1))
			rows.append(_row("🤝", "Go to a union meeting", "Union up; a little protection", "union", null, _left() >= 1 and did("union") < 1))
			rows.append(_row("🧭", "Ask for a transfer", "A new block, a new set of problems", "transfer", null, _left() >= 1 and did("transfer") < 1))
			rows.append(_row("🧑‍🏫", "Mentor a recruit", "Standing up. Needs Senior Officer", "mentor", null, _left() >= 1 and int(l["rank"]) >= 2 and did("mentor") < 1))
			rows.append(_row("📣", "Lobby for the next rank", "Merit +, standing at risk", "lobby", null, _left() >= 1 and did("lobby") < 1 and int(l["rank"]) < RANK_G.size() - 1))
			return {"icon": "📈", "title": "Career", "rows": rows, "info": ["Merit %d · the next rank needs %s" % [int(l["merit"]), str(RANK_NEED[mini(int(l["rank"]) + 1, RANK_G.size() - 1)])]]}
		"integrity":
			rows.append(_row("📦", "Carry something in", "$600. Integrity down, IA interest up", "carry", null, _left() >= 1 and did("carry") < 1))
			rows.append(_row("🎁", "Accept a favour", "A small one. They always are", "favour", null, _left() >= 1 and did("favour") < 1))
			rows.append(_row("🙈", "Cover for a colleague", "Union up; integrity down", "cover", null, _left() >= 1 and did("cover") < 1))
			rows.append(_row("🧾", "Report what you've seen", "Integrity up; the wing notices", "report", null, _left() >= 1 and did("report") < 1))
			rows.append(_row("📣", "Blow the whistle", "Takes everything with it. Needs real evidence", "whistle", null, _left() >= 1 and int(l.get("corruption", 0)) + int(l.get("ring", 0)) > 0 or _left() >= 1 and has_intel("corruption")))
			return {"icon": "🗝️", "title": "Integrity", "rows": rows, "info": ["Integrity %d · times you've taken money: %d" % [int(l["integrity"]), int(l.get("corruption", 0))]]}
	return {"icon": "🗝️", "title": "On the staff", "rows": rows, "info": info}


# ================================================================ actions

func _done(icon: String, title: String, text: String, fx: Dictionary = {}) -> void:
	EventEngine.push_info(icon, title, text, fx)
	GameState.apply_effects(fx)


func act(key: String, arg) -> void:
	if is_guard():
		_act_guard(key, arg)
	else:
		_act_prisoner(key, arg)
	GameState.emit_changed()


func _talk_text(n: Dictionary) -> String:
	var nm := str(n["first"])
	return pick([
		"%s talked for an hour, about nothing that mattered and everything that did. By the end I knew which of the officers to trust, and which of the inmates to avoid." % nm,
		"%s was wary at first. Then I asked about a sister, and the whole conversation changed." % nm,
		"We played dominoes for most of the afternoon and said four sentences. It was the best conversation I had that year.",
		"%s told me something I probably should not have been told. I did not ask why." % nm])


func _act_prisoner(key: String, arg) -> void:
	var l := L()
	var p := _p()
	match key:
		"gym":
			if not GameState.spend_time(1): return
			note("gym")
			clampg(l, "heat", -3.0)
			clampg(l, "respect", 1.0)
			_done("🏋️", "Iron", pick(["The weights are rusted and bolted into a cage, and it is still the best hour of the day. You are somebody who lifts.", "I did the circuit at six, before the count, when the yard was empty and the light was grey. The body at least still answers."]), {"health": 3, "looks": 2, "stress": -4})
		"study":
			if not GameState.spend_time(1): return
			note("study")
			if bool(l.get("innocent", false)):
				clampg(l, "appeal", 3.0)
			_done("📖", "The library", pick(["The law books are in a locked bay at the back, on a trolley. I read case after case until my eyes stung.", "I read for hours. A man at the next table was copying out a dictionary by hand, and had been since 2003."]), {"smarts": 2, "stress": -2})
		"yard":
			if not GameState.spend_time(1): return
			note("yard")
			clampg(l, "respect", 2.0)
			var r := randf()
			if r < 0.3:
				add_intel(pick(["patrol", "count", "blindspot", "schedule"]), pick(["The south tower turns its back at the change of shift", "The count is slow on Sundays", "There is a stretch of fence the cameras do not cover", "Laundry goes out on Thursdays on an unmarked truck"]))
				_done("🌳", "Something worth knowing", "I walked the fence line three times with my hands in my pockets, as though I were thinking about something else. I noticed something I will not forget.", {"stress": -3})
			elif r < 0.45:
				_attacked()
			else:
				_done("🌳", "The yard", pick(["An hour of sky, with a wire across it. The groups were where they always are, and nobody crossed the lines.", "I walked, I watched and I was seen. Most of the yard is a conversation about who is watching whom."]), {"stress": -4, "happiness": 1})
		"faith":
			if not GameState.spend_time(1): return
			note("faith")
			clampg(l, "conduct", 3.0)
			_done("🕯️", "The chapel", pick(["Twelve of us, plastic chairs, a woman who played the keyboard with enormous courage. I cried at a hymn I had never heard.", "A volunteer read a psalm. A man next to me, who had killed someone, held the page for her. I looked away."]), {"stress": -6, "happiness": 3})
		"lowprofile":
			if not GameState.spend_time(1): return
			note("low")
			clampg(l, "heat", -12.0)
			_done("🤫", "A quiet stretch", "I did my job, ate my food, said nothing to anyone and was nobody's business. I have come to see this as a skill.", {"stress": -3})
		"letter":
			if not GameState.spend_time(1): return
			note("letter")
			clampg(l, "support", 8.0)
			_done("✉️", "A letter", pick(["Two pages. The first was easy. The second took three days and a lot of crossing out.", "I wrote to my mother and said I was fine. It was the most elaborate lie I told that year."]), {"happiness": 3})
		"call":
			if not GameState.spend_time(1): return
			note("call")
			p["money"] = int(p["money"]) - 60
			clampg(l, "support", 7.0)
			_done("📞", "Fifteen minutes", "A recorded voice says the call is from a correctional facility. They accept. For ten minutes there is the sound of someone's kitchen behind them, and then a voice says 'one minute remaining'.", {"happiness": 4, "stress": -2})
		"job":
			if not GameState.spend_time(1): return
			l["job"] = str(arg)
			_done(str(JOBS[str(arg)]["icon"]), str(JOBS[str(arg)]["name"]), "I put my name down, and a week later an officer with a clipboard told me where to be at six. %s" % str(JOBS[str(arg)]["desc"]), {"stress": -2})
		"program":
			if not GameState.spend_time(2): return
			var pk := str(arg)
			apply({"program": pk})
			clampg(l, "conduct", 5.0)
			if pk == "ged" or pk == "college":
				GameState.apply_effects({"smarts": int(PROGRAMS[pk]["wit"])})
			if pk == "college":
				clampg(l, "appeal", 4.0)
			l["parole_mood"] = float(l.get("parole_mood", 0)) + 4.0
			GameState.add_milestone(int(p["age"]), "completed %s" % str(PROGRAMS[pk]["name"]).to_lower())
			_done(str(PROGRAMS[pk]["icon"]), str(PROGRAMS[pk]["name"]), "It took the better part of a year. At the end, there was a certificate in a plastic sleeve and a handshake from a woman who was also, I think, trying to be somewhere else. It is a line in my file now.", {"happiness": 5, "stress": -3})
		"commissary":
			if not GameState.spend_time(1): return
			note("commissary")
			p["money"] = int(p["money"]) - 80
			_done("🛒", "The commissary", pick(["Noodles, instant coffee, a bar of proper soap and a packet of biscuits I rationed to the end of the month.", "I bought the small luxuries. A man in the queue asked what a fresh tomato tasted like. I could not remember."]), {"happiness": 4, "stress": -4})
		"cards":
			if not GameState.spend_time(1): return
			note("cards")
			if randf() < 0.45 + float(p["stats"]["smarts"]) / 400.0:
				p["money"] = int(p["money"]) + 90
				clampg(l, "respect", 3.0)
				_done("🃏", "A good night", "I read the table, kept my face still and left the game with the pot and, which mattered more, with their respect.", {"happiness": 3})
			else:
				p["money"] = int(p["money"]) - 90
				clampg(l, "dues", 6.0)
				_done("🃏", "A bad night", "I lost, and then I lost trying to win it back. The debt was small and the principle was not.", {"stress": 5})
		"trade":
			if not GameState.spend_time(2): return
			note("trade")
			var amt := int(l.get("stash", 0))
			Minigames.play("haggle", {"skill": float(p["stats"]["smarts"]), "difficulty": 1.0, "subject": "the price"}, func(score: float, _d: Dictionary) -> void:
				var cash := int(float(amt) * (120.0 + 380.0 * score))
				p["money"] = int(p["money"]) + cash
				l["stash"] = 0
				clampg(l, "respect", 2.0)
				clampg(l, "heat", 5.0)
				_done("🤝", "A deal", "The trade took place in a place with no camera, over about ninety seconds. %s I came away with $%d." % [pick(["He knew the going rate and so did I.", "He tried to push me down and I held."]), cash], {"happiness": 2}))
		"smuggle":
			if not GameState.spend_time(1): return
			note("smuggle")
			var good := false
			var route := "the yard"
			if float(l["support"]) > 45.0 and randf() < 0.4:
				route = "a visitor"
			elif GameState.first_of("officer") != "" and str(GameState.npcs[GameState.first_of("officer")].get("mood", "")) == "bent":
				route = "an officer"
			good = randf() < (0.55 if route != "the yard" else 0.4)
			if good:
				l["stash"] = int(l.get("stash", 0)) + 1
				_done("📦", "Something came in", "It came in through %s, in a place I will not describe. It was in my hand before the count, and under the mattress before the lights went out." % route, {"stress": 3})
			else:
				clampg(l, "heat", 20.0)
				clampg(l, "conduct", -8.0)
				_done("🚨", "Caught at it", "It was found on the way in. There was a report, and a long talk with a man who did not raise his voice. The visits were suspended for a season.", {"stress": 8, "happiness": -4})
		"loan":
			if not GameState.spend_time(1): return
			note("loan")
			p["money"] = int(p["money"]) - 100
			if randf() < 0.7:
				p["money"] = int(p["money"]) + 170
				clampg(l, "respect", 2.0)
				_done("💵", "Paid back", "He paid on the day, with the interest, and looked at me in a way that said we would do it again.", {"happiness": 1})
			else:
				clampg(l, "heat", 6.0)
				_done("💵", "Not paid", "He didn't pay, and the whole yard watched what I did about it. I did something. I am not proud of the something.", {"stress": 6})
		"ink":
			if not GameState.spend_time(1): return
			note("ink")
			p["money"] = int(p["money"]) + 120
			clampg(l, "heat", 6.0)
			clampg(l, "respect", 2.0)
			_done("🖋️", "Ink", "A needle made from a pen motor, ink from a melted comb, and a man who wanted his daughter's name on his arm. The job took four hours and a lookout.", {"happiness": 2})
		"paydues":
			p["money"] = int(p["money"]) - 200
			clampg(l, "dues", -70.0)
			_done("💸", "Square", "I paid what I owed in a place with no cameras. It was the lightest I had felt in a year.", {"stress": -8})
		"talk":
			var id := str(arg)
			if not GameState.npcs.has(id) or not GameState.spend_time(1): return
			note("talk_" + id)
			var n: Dictionary = GameState.npcs[id]
			GameState.change_closeness(id, 8)
			n["trust"] = int(n.get("trust", 20)) + 8
			if str(n["relation"]) == "officer":
				if str(n.get("mood", "fair")) == "hard":
					clampg(l, "heat", 4.0)
					_done("👮", "A hard officer", "I made conversation with %s. They answered in monosyllables and wrote something down afterwards." % str(n["first"]), {"stress": 3})
				else:
					clampg(l, "conduct", 2.0)
					_done("👮", "A word with an officer", "%s was off the clock in everything but the uniform. A few words about football and the weather, and, once, something about the shift pattern that was worth hearing." % str(n["first"]), {"stress": -2})
					if randf() < 0.3:
						add_intel("schedule", "%s mentioned the shift change is at 5.40, not 6" % str(n["first"]))
			elif str(n["relation"]) == "lawyer":
				clampg(l, "appeal", 2.0 if bool(l.get("innocent", false)) else 0.0)
				_done("⚖️", "Your lawyer", "Eleven minutes by the clock, in an interview room that smelled of cold coffee. Nothing was promised. Everything was noted.", {"stress": 2})
			else:
				if randf() < 0.2:
					add_intel(pick(["patrol", "count", "weakness", "rumour"]), "%s let slip that %s" % [str(n["first"]), pick(["the night officer sleeps at three", "one of the new guards is in debt", "the east door sticks and is not alarmed", "a transfer is coming for the whole of Block B"])])
				_done("🧍", "Time with %s" % str(n["first"]), _talk_text(n), {"happiness": 3, "stress": -3})
		"snitch":
			if not GameState.spend_time(1): return
			note("snitch")
			l["snitched"] = int(l.get("snitched", 0)) + 1
			clampg(l, "conduct", 8.0)
			clampg(l, "heat", -12.0)
			clampg(l, "respect", -14.0)
			l["parole_mood"] = float(l.get("parole_mood", 0)) + 3.0
			if my_gang() != "":
				apply({"rep": {"mine": -30}})
			GameState.counter("pr_snitch")
			_done("🐀", "A name for a favour", "I gave them a name in a room with no windows. The officer wrote it down and said nothing, which was worse than thanks. I was taken back along a corridor where I looked at nobody and nobody looked at me.", {"stress": 6, "happiness": -4})
			if randf() < 0.3:
				_attacked()
		"protect":
			if not GameState.spend_time(1): return
			note("protect")
			if randf() < 0.6:
				clampg(l, "respect", 6.0)
				var fid := new_inmate("", randi_range(19, 28))
				GameState.npcs[fid]["closeness"] = 55
				GameState.npcs[fid]["trust"] = 60
				_done("🛡️", "Somebody's debt", "A kid was being leaned on in the stairwell. I stood next to him, said nothing, and the others found they had somewhere else to be. He found me the next day and did not know how to say thank you.", {"happiness": 5, "karma": 4})
			else:
				clampg(l, "respect", -3.0)
				_attacked()
				_done("🛡️", "A mistake", "I stood between them and it turned out the boy owed the wrong people. I came away with a lesson and a fresh injury.", {"karma": 3})
		"join":
			if not GameState.spend_time(1): return
			note("join")
			var gk := str(arg)
			apply({"gang": gk})
			l["gang_rank"] = 1
			for other in GANGS.keys():
				if other != gk:
					l["rep"][other] = float(l["rep"].get(other, 0)) - 15.0
			GameState.counter("pr_joined")
			GameState.add_milestone(int(p["age"]), "joined %s" % gang_name(gk))
			_done(str(GANGS[gk]["icon"]), "Joined %s" % str(GANGS[gk]["name"]), "It was a handshake and a task. The task was small, the handshake was long. For the first time in months, I knew exactly where I was meant to stand when something kicked off. Everyone else, now, would know it too.", {"happiness": 3, "stress": -4})
		"pc":
			if not GameState.spend_time(1): return
			l["flags"]["pc"] = int(p["age"])
			clampg(l, "heat", -20.0)
			clampg(l, "respect", -15.0)
			F()["order"] = F()["order"]
			_done("🏳️", "Protective custody", "Seventeen hours in a cell and one in a small yard, with the men nobody else would stand next to. It was safe. I would be the one who asked for it, to everyone, for ever.", {"stress": -6, "happiness": -4})
		"favor":
			if not GameState.spend_time(1): return
			note("favor")
			clampg(l, "heat", 8.0)
			l["gang_rank"] = clampi(int(l.get("gang_rank", 1)) + (1 if randf() < 0.25 else 0), 0, 4)
			apply({"rep": {"mine": 8}})
			_done("🛠️", "A favour", pick(["A parcel passed from a hand to a hand, with no questions. It is how a thing like this works: nobody knows more than their part.", "I was asked to stand in a doorway for ten minutes. That is all I know about what happened behind it."]), {"stress": 4})
		"rankup":
			if not GameState.spend_time(2): return
			note("rankup")
			Minigames.play("fight", {"skill": float(p["stats"]["looks"]), "difficulty": 1.0, "opponent": "The man above you"}, func(score: float, _d: Dictionary) -> void:
				if score >= 0.5:
					l["gang_rank"] = clampi(int(l.get("gang_rank", 1)) + 1, 0, 4)
					clampg(l, "respect", 8.0)
					_done("📈", "Promoted", "I was tested, in a room with a locked door and no audience. When it was done they stood up. Rank here is just a set of people who agree about you.", {"happiness": 4})
				else:
					clampg(l, "respect", -4.0)
					GameState.apply_effects({"health": -6})
					_done("📉", "Not yet", "I lost, as honestly as I could. They told me I could try again when the bruises went. It was almost kind.", {"stress": 5}))
		"leave":
			if not GameState.spend_time(1): return
			var gk2 := my_gang()
			apply({"gang": ""})
			l["gang_rank"] = 0
			clampg(l, "respect", -10.0)
			l["rep"][gk2] = float(l["rep"].get(gk2, 0)) - 50.0
			_done("🚪", "Out", "It took one conversation, and one that came after it, in the shower block, which I won't describe. I walked out of it a person without a side.", {"health": -8, "stress": 8})
			if randf() < 0.6:
				_attacked()
		"hearing":
			if not GameState.spend_time(2): return
			var sc: float = 0.0
			Minigames.play("pr_parole", {"skill": float(p["stats"]["smarts"]), "difficulty": 1.0, "conduct": float(l["conduct"]), "programs": programs_n(), "denied": int(l.get("denied", 0)), "innocent": bool(l.get("innocent", false)), "crime": str(l.get("crime", "")), "support": float(l["support"])}, func(score: float, _d: Dictionary) -> void:
				sc = score
				if hearing_result(sc):
					pass
				else:
					EventEngine.push_info("⚖️", "The board decided", "Denied. They will hear me again next year.", {"happiness": -2}))
		"research":
			if not GameState.spend_time(2): return
			note("research")
			Minigames.play("evidence", {"skill": float(p["stats"]["smarts"]), "difficulty": 1.0}, func(score: float, _d: Dictionary) -> void:
				if bool(l.get("innocent", false)):
					clampg(l, "appeal", 4.0 + 10.0 * score)
				else:
					clampg(l, "appeal", 1.0 + 3.0 * score)
				if score >= 0.6:
					add_intel("case", "a gap in the timeline of the prosecution case")
				_done("🔍", "The file", "I read the file again, and found something I'd missed the last time: a date, a name, a form that had never been signed. %s" % pick(["It will not move a court by itself. It is a start.", "A week later I dreamt about it."]), {"smarts": 1}))
		"lawyer":
			if not GameState.spend_time(1): return
			note("lawyer")
			clampg(l, "appeal", 2.0 if bool(l.get("innocent", false)) else 0.0)
			clampg(l, "lawyer", 2.0)
			_done("☎️", "A call", "Her secretary put me through on the third try. She said she was 'looking into it' in the voice of someone doing nothing of the kind.", {"stress": 3})
		"better_lawyer":
			note("better_lawyer")
			p["money"] = int(p["money"]) - 5000
			clampg(l, "lawyer", 25.0)
			_done("💼", "A lawyer who answers", "She answered on the second ring. She had read the file. She had a list of questions I'd been wanting someone to ask for years.", {"happiness": 6})
		"press":
			if not GameState.spend_time(1): return
			note("press")
			clampg(l, "heat", 8.0)
			clampg(l, "support", 6.0)
			if bool(l.get("innocent", false)):
				clampg(l, "appeal", 6.0)
			_done("📰", "In print", "A journalist took the letter seriously. A story ran, two columns, on page nine. It was not much. It was the first time in years that someone outside had said my name aloud without it being a charge.", {"happiness": 5})
		"recon":
			if not GameState.spend_time(2): return
			note("recon")
			Minigames.play("infiltrate", {"skill": float(p["stats"]["smarts"]), "difficulty": 0.9}, func(score: float, _d: Dictionary) -> void:
				var n := 0
				if score >= 0.35: n = 1
				if score >= 0.7: n = 2
				for _i in range(n):
					add_intel(pick(["patrol", "blindspot", "count", "truck", "schedule"]), pick(["The east gate guard leaves for a cigarette at 3.10", "The laundry van is not searched on the way out", "The wire on the north side has a gap behind the boiler house", "The count is estimated, not made, on Friday evenings", "The new night officer does not know the codes"]))
				clampg(l, "heat", 4.0 if score < 0.35 else 1.0)
				_done("👀", "Looking at the building", "I spent weeks learning the timetable of the building from the inside. %s" % ("I came away with something." if n > 0 else "Nobody gave me anything, and someone noticed me looking."), {"stress": 3}))
		"commit":
			if not GameState.spend_time(1): return
			l["escape"] = 1
			l["plan_age"] = int(p["age"])
			GameState.add_milestone(int(p["age"]), "started to plan a way out")
			_done("📝", "A plan, in the head", "I wrote nothing down. I did the plan like a long walk, on the yard, in my head, until it stopped being a daydream and became a list.", {"stress": 4})
		"tools":
			if not GameState.spend_time(2): return
			note("tools")
			if randf() < 0.55 + (0.15 if str(l.get("job", "")) == "workshop" else 0.0):
				l["tools"] = int(l.get("tools", 0)) + 1
				if int(l["tools"]) >= 2:
					l["escape"] = 2
				_done("🪛", "Something useful", "A rope's worth of cable. A cutter no bigger than a finger. I put each away where nothing else is kept, and counted them every night.", {"stress": 3})
			else:
				clampg(l, "heat", 15.0)
				_done("🚨", "Nearly", "An officer stopped at my bunk a second longer than usual, then went on. I got rid of everything that night. It took a month to start again.", {"stress": 8})
		"recruit":
			if not GameState.spend_time(2): return
			note("recruit")
			if randf() < 0.5 + float(l["respect"]) / 250.0:
				_recruit()
				if Array(l["crew"]).size() >= 2:
					l["escape"] = 3
				_done("🫂", "One more", "He looked at me for a long time and then asked, 'When?' It's the answer you hope for and the one you dread, because now there are two people who could talk.", {"stress": 4})
			else:
				clampg(l, "respect", -4.0)
				clampg(l, "heat", 8.0)
				_done("🫂", "Not him", "He said no and said it quickly, and I watched his eyes go to the officer's station, and back. For a week I did not sleep.", {"stress": 8})
		"inside":
			if not GameState.spend_time(2): return
			note("inside")
			var cost := 3000
			var o := GameState.first_of("officer")
			var bent := o != "" and str(GameState.npcs[o].get("mood", "")) == "bent"
			if has_intel("weakness") or (int(p["money"]) >= cost and bent) or randf() < 0.18:
				if not has_intel("weakness"):
					p["money"] = int(p["money"]) - mini(cost, int(p["money"]))
				l["escape"] = 4
				_done("🗝️", "An inside man", "A conversation in the laundry, a number on a scrap of paper and an agreement that did not use any of the important words. On the right night, a door will not be locked.", {"stress": 6})
			else:
				clampg(l, "heat", 10.0)
				_done("🗝️", "No", "The officer listened to the end and then said that he hadn't heard it. He's not reported it. I believe, though I have no way of knowing, that he will remember it.", {"stress": 8})
		"wait":
			if not GameState.spend_time(1): return
			var f := F()
			if float(f["tension"]) >= 55.0 or int(f.get("lockdown", 0)) > 0 or randf() < 0.3:
				l["escape"] = 5
				_done("🌩️", "The night", "The weather turned, and the count was a mess, and the wing was louder than I have ever heard it. I looked at the others, and they looked at me. It was the night.", {"stress": 8})
			else:
				_done("🕰️", "Not yet", "Every night I lay awake and listened, and nothing was wrong enough to be right. I waited.", {"stress": 3})
		"breakout":
			_breakout()
		"run_low":
			if not GameState.spend_time(1): return
			clampg(l, "heat", -18.0)
			_done("🌫️", "Lying low", "A room above a shop, a name I do not use and a window I do not stand in front of. I counted the days instead of the years, which is an improvement.", {"stress": -3})
		"run_id":
			if not GameState.spend_time(2): return
			p["money"] = int(p["money"]) - 2500
			l["flags"]["identity"] = int(p["age"])
			clampg(l, "heat", -25.0)
			_done("🪪", "A new name", "The man who made it asked no questions and had a good eye. He said that the best forgery is a boring one. I became, on paper, a boring man.", {"stress": -4})
		"run_work":
			if not GameState.spend_time(2): return
			note("run_work")
			p["money"] = int(p["money"]) + 600
			clampg(l, "heat", 4.0)
			_done("🧰", "A wage", "A site, a foreman who didn't want a name, and cash on a Friday. I'd forgotten the pleasure of tired hands.", {"happiness": 3})
		"run_family":
			if not GameState.spend_time(1): return
			note("run_family")
			clampg(l, "support", 15.0)
			clampg(l, "heat", 22.0)
			_done("📨", "A message", "It was a call from a phone box, forty seconds long. My mother said my name and then said nothing at all. I hung up. The next day there was a car in the street.", {"happiness": 8, "stress": 6})
		"run_move":
			if not GameState.spend_time(2): return
			note("run_move")
			p["money"] = int(p["money"]) - 300
			clampg(l, "heat", -22.0)
			_done("🛤️", "Another town", "A long bus, a new smell, a different landlady and a street where nobody had ever seen my face. I felt it settle, and then I felt it start to leak.", {"stress": 2})
		"run_surrender":
			l["fugitive"] = false
			l["caught"] = true
			l["sentence"] = int(l.get("sentence", 0)) + 2
			l["escape"] = 0
			l["crew"] = []
			l["fugitive_years"] = 0
			GameState.add_log("I walked into a police station on a wet Tuesday and said my name. The man behind the desk looked at it, and at me, and picked up the phone.")
			_solitary("They took me back to where I began.")


# ---------------------------------------------------------------- the break

func _breakout() -> void:
	if not GameState.spend_time(1):
		return
	var l := L()
	var p := _p()
	var crew: Array = l.get("crew", [])
	var bonus := 0.05 * float(crew.size()) + (0.1 if int(l.get("escape", 0)) >= 4 else 0.0)
	GameState.add_log("It was the night. I lay on my back and listened to the building tick, and counted, for the last time, the things I would never see again from the inside.")
	GameState.counter("pr_breaks")
	_break_step(0, bonus)


func _break_step(step: int, bonus: float) -> void:
	var l := L()
	var p := _p()
	var steps := [
		["safecrack", "The cell door", "A door is only a puzzle that has been told it is a wall."],
		["infiltrate", "The yard", "Forty yards of floodlit concrete between you and the wire. Move when the light moves."],
		["escape", "The fence", "Two fences and a gap. Every guard moves twice for every step you take."],
	]
	if step >= steps.size():
		_break_out(bonus)
		return
	var s: Array = steps[step]
	# a man on the inside opens the first door for you
	if step == 0 and int(l.get("escape", 0)) >= 4:
		GameState.add_log("The lock turned without my touching it. Someone had kept his word.")
		_break_step(1, bonus)
		return
	Minigames.play(str(s[0]), {"skill": float(p["stats"]["smarts"]) + 12.0 * float(Array(l.get("crew", [])).size()), "difficulty": 1.0}, func(score: float, _d: Dictionary) -> void:
		if score + bonus >= 0.45:
			GameState.add_log("%s %s" % [str(s[1]) + ".", "Through." if step < 2 else "I was over."])
			_break_step(step + 1, bonus)
		else:
			GameState.add_log("%s: the alarm went before I was clear of it." % str(s[1]))
			_break_caught(str(s[1])))


func _break_caught(where: String) -> void:
	var l := L()
	GameState.add_log(pick([
		"Lights, a voice on a loudspeaker and the sound of boots. I lay down on the wet concrete with my hands where they could see them.",
		"The dogs reached me before the officers did. The officers reached the dogs before it got worse.",
		"%s was as far as I got. They were very calm, which I understood was the worst thing about them." % where]))
	GameState.apply_effects({"health": -6, "stress": 18, "happiness": -15})
	l["sentence"] = int(l.get("sentence", 0)) + randi_range(3, 6)
	l["eligible"] = int(l.get("eligible", 0)) + 5
	l["escape"] = 0
	var crew: Array = l.get("crew", [])
	l["crew"] = []
	for cid in crew:
		if GameState.npcs.has(cid):
			GameState.npcs[cid]["relation"] = "inmate"
	_solitary("They took us in separate vans.")
	clampg(l, "respect", 4.0)
	GameState.counter("pr_failed_breaks")


func _break_out(_bonus: float) -> void:
	var l := L()
	var p := _p()
	l["fugitive"] = true
	l["fugitive_years"] = 0
	l["heat"] = 75.0
	l["escape"] = 0
	var crew: Array = l.get("crew", [])
	var lost := 0
	for cid in crew:
		if GameState.npcs.has(cid) and randf() < 0.4:
			lost += 1
	l["crew"] = []
	GameState.counter("pr_escapes")
	GameState.add_milestone(int(p["age"]), "got over the wall")
	GameState.add_log("Then there was a hedge, and a ditch, and a road, and the sound of a car I did not recognise slowing down for me. %s" % ("I did not look back. Behind me, %d of the others did not make it." % lost if lost > 0 else "I did not look back. All of us were out."))
	GameState.apply_effects({"happiness": 15, "stress": 20})
	EventEngine.push_info("🌫️", "Out", "You are on the other side of the wall.\n\nThe building will count at six. By then you will need a different name, somewhere to be, and a reason that a police officer would look away.\n\nHeat is at 75%. It will fall if you let it.")


func _fugitive_year() -> void:
	var l := L()
	var p := _p()
	l["fugitive_years"] = int(l.get("fugitive_years", 0)) + 1
	l["heat"] = clampf(float(l["heat"]) - 14.0, 0.0, 100.0)
	GameState.counter("pr_fugitive_years")
	var catch_p := 0.1 + float(l["heat"]) / 220.0 - (0.07 if Dictionary(l.get("flags", {})).has("identity") else 0.0)
	if int(p["money"]) < 100:
		catch_p += 0.05
		p["money"] = int(p["money"]) + 180
	GameState.apply_effects({"stress": 4})
	if randf() < catch_p:
		_recaptured()
		return
	GameState.add_log(pick([
		"I listened to the radio with the volume low, and made myself unremarkable in forty small ways.",
		"A year of other people's rooms, a name I answered to a beat late and a habit of sitting where I could see the door.",
		"I saw my own photograph on a screen in a pub. It was an old one and the likeness was not great. Nobody looked twice."]))
	if int(l["fugitive_years"]) >= 5 and float(l["heat"]) < 45.0:
		conclude("escaped")


# ---------------------------------------------------------------- guard actions

func _act_guard(key: String, arg) -> void:
	var l := L()
	var p := _p()
	var f := F()
	match key:
		"rounds":
			if not GameState.spend_time(1): return
			note("rounds")
			clampg(l, "control", 4.0)
			clampg(l, "merit", 1.0)
			_done("🚶", "The rounds", pick(["Landing by landing, with the keys at my hip and my eyes on the hands. The wing watched me walk. I walked as though I had nowhere else to be.", "I did the hourly check on every cell, as written. In cell fourteen a man was awake, and said 'evening, boss', in a voice that had a good deal in it."]), {"stress": 2})
		"search":
			if not GameState.spend_time(2): return
			note("search")
			Minigames.play("pr_shakedown", {"skill": float(p["stats"]["smarts"]), "difficulty": 1.0}, func(score: float, _d: Dictionary) -> void:
				clampg(l, "merit", 2.0 + 4.0 * score)
				clampg(l, "control", 3.0 * score)
				f["tension"] = clampf(float(f["tension"]) + 3.0, 0.0, 100.0)
				if score >= 0.6:
					l["contraband_caught"] = int(l.get("contraband_caught", 0)) + 1
					GameState.counter("gd_contraband")
				_done("🔦", "A cell search", ("I found it: behind a tile, in a book, in a hollow in a hair brush. %s" % pick(["It went in a bag and onto a form.", "The inmate watched me do it with an expression I will not forget."])) if score >= 0.6 else "I turned a cell over and found nothing, and I knew I'd missed it. The inmate's courtesy was a form of contempt.", {"stress": 3}))
		"fight":
			if not GameState.spend_time(1): return
			note("fightbreak")
			if ContentDB.events_by_id.has("gd.force.1"):
				EventEngine.push_decision(ContentDB.events_by_id["gd.force.1"], {})
			else:
				l["incidents"] = int(l.get("incidents", 0)) + 1
		"paper":
			if not GameState.spend_time(1): return
			note("paper")
			clampg(l, "merit", 2.0)
			clampg(l, "ia_heat", -2.0)
			_done("🗂️", "The reports", "Eleven forms, in triplicate, in a language invented to protect someone. I wrote them carefully, and I wrote what happened, and learned which words to leave out.", {"stress": 2})
		"overtime":
			if not GameState.spend_time(2): return
			note("overtime")
			p["money"] = int(p["money"]) + 1200
			clampg(l, "trauma", 3.0)
			clampg(l, "merit", 1.0)
			_done("⏱️", "A double", "Sixteen hours. The wing at four in the morning has a sound of its own, a low, continuous one, like a refrigerator the size of a village. I went home and slept in my uniform.", {"stress": 6, "health": -1})
		"break":
			if not GameState.spend_time(2): return
			note("break")
			clampg(l, "trauma", -14.0)
			clampg(l, "burnout", -10.0)
			_done("🧘", "A proper break", "A week of not wearing a watch. The first three days I woke at 5.40 anyway. By the end of it I could hear the birds.", {"stress": -10, "happiness": 5})
		"lockdown":
			if not GameState.spend_time(1): return
			f["lockdown"] = 1
			f["tension"] = maxf(10.0, float(f["tension"]) - 15.0)
			clampg(l, "merit", 2.0)
			clampg(l, "standing", -2.0)
			_done("🔒", "A lockdown", "I gave the order, and the building shut like a fist. It prevented what I was afraid of. It also made every inmate in the place remember who had done it.", {"stress": 4})
		"gtalk":
			var id := str(arg)
			if not GameState.npcs.has(id) or not GameState.spend_time(1): return
			note("gtalk_" + id)
			var n: Dictionary = GameState.npcs[id]
			n["trust"] = int(n.get("trust", 20)) + 10
			GameState.change_closeness(id, 6)
			clampg(l, "integrity", 0.5)
			if randf() < 0.25:
				add_intel(pick(["rumour", "weakness", "plan"]), "%s hinted that something is being arranged on Block %s" % [str(n["first"]), str(l.get("block", "C"))])
			_done("🧍", "A word with %s" % str(n["first"]), pick(["%s asked about my children. I said they were fine. It was the first honest conversation I'd had that week." % str(n["first"]), "We talked about the weather, and the football, and a thing that was going on in the east wing that I decided I hadn't heard.", "%s trusted me with something small. That is how it begins, on both sides." % str(n["first"])]), {"stress": -1})
		"listen":
			if not GameState.spend_time(1): return
			note("listen")
			if randf() < 0.45:
				add_intel(pick(["plan", "rumour", "weakness", "corruption"]), pick(["Two men on Block C stopped talking when I passed. They had been speaking about the laundry", "There is a debt going round the wing which is bigger than it should be", "Someone is bringing something in on Thursdays", "A colleague has been seen where he should not have been"]))
				_done("💬", "I heard something", "I walked the landing at the slow pace of a man with nowhere to be. I came back with a piece of information I wasn't sure I wanted.", {"stress": 2})
			else:
				_done("💬", "Nothing", "A wing full of noise and none of it for me.", {"stress": 1})
		"writeup":
			if not GameState.spend_time(1): return
			note("writeup")
			clampg(l, "control", 5.0)
			clampg(l, "merit", 1.5)
			f["tension"] = clampf(float(f["tension"]) + 4.0, 0.0, 100.0)
			_done("📋", "Written up", "I did it by the book and he knew it, and he knew I knew he knew. It will cost him privileges for a month. It will cost me something that doesn't show up on a form.", {"stress": 3})
		"counsel":
			if not GameState.spend_time(1): return
			note("counsel")
			clampg(l, "integrity", 3.0)
			clampg(l, "standing", 1.0)
			f["tension"] = clampf(float(f["tension"]) - 2.0, 0.0, 100.0)
			var ids := GameState.npcs_with("inmate")
			if not ids.is_empty():
				GameState.npcs[ids[randi() % ids.size()]]["trust"] = 70
			_done("🎓", "A real conversation", "I sat down with a young man on his third sentence and asked what he wanted. He said 'a job', as though it were an embarrassing thing. I put his name on a list. It's a thin list.", {"happiness": 3, "karma": 3})
		"train":
			if not GameState.spend_time(2): return
			note("train")
			clampg(l, "merit", 4.0)
			clampg(l, "control", 2.0)
			_done("🎓", "A training course", "Three days in a hotel conference room with a laminated flip chart. One module, on de-escalation, was better than the rest, and I saw it work on the wing the following week.", {"smarts": 1})
		"union":
			if not GameState.spend_time(1): return
			note("union")
			clampg(l, "union", 10.0)
			_done("🤝", "A union meeting", "A function room above a pub. The talk was of staffing ratios and a safe working agreement, and the men and women who were there had faces I had seen at three in the morning.", {"stress": -2})
		"transfer":
			if not GameState.spend_time(1): return
			note("transfer")
			l["block"] = pick(BLOCKS)
			clampg(l, "control", -20.0)
			_done("🧭", "A new block", "Block %s. The same keys, different doors. For a month nobody on the landing trusted a word I said." % str(l["block"]), {"stress": 4})
		"mentor":
			if not GameState.spend_time(1): return
			note("mentor")
			clampg(l, "standing", 5.0)
			clampg(l, "merit", 1.5)
			_done("🧑‍🏫", "A recruit", "She was twenty-two and frightened, and she hid it well. I told her what I'd have wanted told: that nobody knows, that the keys are heavy, and that the second rule is always the first.", {"happiness": 4})
		"lobby":
			if not GameState.spend_time(1): return
			note("lobby")
			clampg(l, "merit", 4.0)
			clampg(l, "standing", -3.0)
			_done("📣", "A word upstairs", "I made my case to the deputy, who made a note, and the note, I hope, made its way up. It may have been better received if I hadn't cared quite so visibly.", {"stress": 3})
		"carry":
			if not GameState.spend_time(1): return
			note("carry")
			apply({"bribe": 600})
			l["ring"] = float(l.get("ring", 0)) + 3.0
			_done("📦", "A parcel", "It was small and light and I did not look in it. The envelope that came back was heavier than it ought to have been. I had crossed a line I'd thought I was a long way from.", {"stress": 6, "happiness": -2})
		"favour":
			if not GameState.spend_time(1): return
			note("favour")
			clampg(l, "integrity", -4.0)
			clampg(l, "ia_heat", 4.0)
			clampg(l, "standing", 2.0)
			l["corruption"] = int(l.get("corruption", 0)) + 1
			_done("🎁", "A small favour", "He asked for nothing, which is how you know. A phone call on my night off. A word with someone. A good coffee on the landing, afterwards, from a man I'd been told to keep my distance from.", {"stress": 3})
		"cover":
			if not GameState.spend_time(1): return
			note("cover")
			clampg(l, "union", 8.0)
			clampg(l, "integrity", -5.0)
			clampg(l, "ia_heat", 3.0)
			_done("🙈", "I said nothing", "An officer I'd worked with for six years had done something on the landing that a camera did not see. They asked me what I'd seen. I said I'd seen nothing, and he never forgot it, and neither did I.", {"stress": 5})
		"report":
			if not GameState.spend_time(1): return
			note("report")
			clampg(l, "integrity", 6.0)
			clampg(l, "union", -8.0)
			clampg(l, "standing", -4.0)
			_done("🧾", "A report", "I put it in writing. It was a short document, and it was entirely true, and by the end of the week the canteen conversation changed shape when I came in.", {"stress": 4})
		"whistle":
			if not GameState.spend_time(1): return
			apply({"whistle": true})
			l["merit"] = float(l["merit"]) * 0.6
			GameState.add_milestone(int(p["age"]), "blew the whistle")
			_done("📣", "The whistle", "I took the file to a lawyer, then the lawyer took it to a journalist, and on a Thursday it was in the paper. I was the only one who didn't call in sick that morning.", {"stress": 15, "happiness": -5})
			if randf() < 0.55 and int(l.get("corruption", 0)) > 0:
				l["fired"] = true


# ================================================================ the screen

func tabs() -> Array:
	if is_guard():
		return [["🚨", "Post", "pr:post"], ["🧍", "Wing", "pr:block"], ["📈", "Career", "pr:career"], ["🗝️", "Integrity", "pr:integrity"], ["🛤️", "Road", "real:arc"], ["⋯", "More", "more"]]
	if bool(L().get("fugitive", false)):
		return [["🌫️", "Run", "pr:home"], ["🌫️", "Run", "pr:home"], ["🌫️", "Run", "pr:home"], ["🌫️", "Run", "pr:home"], ["🛤️", "Road", "real:arc"], ["⋯", "More", "more"]]
	return [["⛓️", "Inside", "pr:home"], ["👥", "People", "pr:people"], ["🔗", "Gang", "pr:gang"], ["⚖️", "Case", "pr:case"], ["🛤️", "Road", "real:arc"], ["⋯", "More", "more"]]


func quick() -> Array:
	if is_guard():
		return [["🚶", "Rounds", "pr:post"], ["🗝️", "Keys", "pr:integrity"]]
	return [["🛏️", "Routine", "pr:routine"], ["🚬", "Hustle", "pr:hustle"]]


func side_labels() -> Dictionary:
	return SIDE_G if is_guard() else SIDE_P


func balance_label() -> String:
	return "Savings" if is_guard() else "Commissary"


func portrait() -> String:
	if not bool(_p().get("alive", true)):
		return "🕊️"
	if bool(L().get("fugitive", false)):
		return "🌫️"
	var g := str(_p().get("gender", "male"))
	if is_guard():
		return "👮‍♀️" if g == "female" else "👮"
	return "🧑‍🦲" if g != "female" else "👩‍🦰"


func header_occ() -> String:
	var l := L()
	if is_guard():
		return "🗝️ %s · %s" % [rank_name(), str(F()["name"]).get_slice(" ", 0)]
	if bool(l.get("fugitive", false)):
		return "🌫️ On the run · %s" % number_label()
	return "⛓️ %s · %s" % [prisoner_rank(), number_label()]


func header_sub() -> String:
	var l := L()
	var f := F()
	if is_guard():
		return "%s · year %d on the staff" % [str(f["name"]), served() + 1]
	if bool(l.get("fugitive", false)):
		return "Year %d on the run" % int(l.get("fugitive_years", 0))
	return "%s · %s · %d to go" % [str(f["name"]), str(SECURITY[str(f["security"])]).get_slice(" ", 0), remaining()]


func money_text() -> String:
	return "$%d" % int(_p().get("money", 0))


func money_state() -> int:
	return -1 if int(_p().get("money", 0)) < 0 else 0


func tracks() -> Array:
	var l := L()
	var f := F()
	if is_guard():
		return [["🗝️", "Control", float(l["control"])], ["🧭", "Integrity", float(l["integrity"])], ["📈", "Merit", minf(100.0, float(l["merit"]))], ["🕵️", "IA interest", float(l["ia_heat"])], ["🔥", "Tension", float(f["tension"])], ["🌑", "Trauma", float(l["trauma"])]]
	if bool(l.get("fugitive", false)):
		return [["🚨", "Heat", float(l["heat"])], ["👪", "Support", float(l["support"])]]
	var out: Array = [["👑", "Respect", float(l["respect"])], ["🚨", "Heat", float(l["heat"])], ["📋", "Conduct", float(l["conduct"])], ["👪", "Support", float(l["support"])], ["🔥", "Tension", float(f["tension"])]]
	if bool(l.get("innocent", false)):
		out.append(["⚖️", "Appeal", float(l["appeal"])])
	if plan_stage() > 0:
		out.append(["🕳️", "The plan", plan_stage() * 20.0])
	return out


func home_text() -> String:
	var out: Array = []
	var l := L()
	if is_guard():
		out.append("🗝️ %s" % rank_name())
		var sup := GameState.first_of("supervisor")
		if sup != "":
			out.append("Your sergeant: %s %s" % [str(GameState.npcs[sup]["first"]), str(GameState.npcs[sup]["last"])])
		out.append("Warden: %s" % warden_name())
	else:
		var cm := GameState.first_of("cellmate")
		if cm != "":
			out.append("🛏️ Cellmate: %s" % str(GameState.npcs[cm]["first"]))
		if my_gang() != "":
			out.append("%s %s (%s)" % [GANGS[my_gang()]["icon"], gang_name(my_gang()), gang_rank_name(int(l.get("gang_rank", 0)))])
		var par := str(_p().get("partner", ""))
		if par != "" and GameState.npcs.has(par):
			out.append("❤️ %s, outside" % str(GameState.npcs[par]["first"]))
		if str(l.get("job", "none")) != "none":
			out.append("%s %s" % [JOBS[str(l["job"])]["icon"], JOBS[str(l["job"])]["name"]])
	return "\n".join(out)


func fin_text() -> String:
	var f := F()
	var l := L()
	var lines: Array = []
	lines.append("%s" % ("LOCKDOWN" if int(f.get("lockdown", 0)) > 0 else ("A gang war is on." if int(f.get("war", 0)) > 0 else "The building is %s." % ("quiet" if float(f["tension"]) < 35.0 else ("tense" if float(f["tension"]) < 65.0 else "about to go")))))
	if is_prisoner() and not bool(l.get("fugitive", false)):
		lines.append("Warden: %s" % warden_name())
		if bool(l.get("hearing_due", false)):
			lines.append("⚖️ A parole hearing is due.")
	return "\n".join(lines)


func extra_text() -> String:
	var out := ""
	var arc: Array = Arcs.status_line()
	if not arc.is_empty():
		out += str(arc[0]) + "\n"
	var l := L()
	if is_prisoner() and plan_stage() > 0:
		out += "🕳️ Plan: %s\n" % PLAN_STAGES[plan_stage()]
	if is_prisoner() and Array(l.get("programs", [])).size() > 0:
		out += "🎓 " + ", ".join(Array(l["programs"]).map(func(x): return str(PROGRAMS[x]["name"]))) + "\n"
	return out.strip_edges()


func status_lines() -> Array:
	var out: Array = []
	var l := L()
	if is_guard():
		out.append(["🗝️ %s · %s" % [rank_name(), str(F()["name"])], ""])
		out.append(["Control", float(l["control"])])
		out.append(["Integrity", float(l["integrity"])])
	else:
		out.append(["⛓️ %s · %s" % [prisoner_rank(), number_label()], ""])
		out.append(["Respect", float(l["respect"])])
		out.append(["Conduct", float(l["conduct"])])
	return out


# ================================================================ events that play a minigame

func handles(kind: String) -> bool:
	return kind == "pr_branch"


## A branch event: win or lose a minigame, and each side has its own text and effects.
func resolve(_kind: String, score: float, _detail: Dictionary, pl: Dictionary) -> void:
	var win: bool = score >= float(pl.get("need", 0.5))
	var br: Dictionary = pl.get("win", {}) if win else pl.get("lose", {})
	if br.has("pr"):
		apply(br["pr"])
	var fx: Dictionary = br.get("effects", {})
	EventEngine.push_info(str(br.get("icon", "⛓️")), str(br.get("title", "")), str(br.get("text", "")), fx)
	GameState.apply_effects(fx)

extends Node

var scenes: Array = []

func _ready() -> void:
	scenes=ContentDB._load_json("res://data/life_course.json",[])

# Calendar ranges are game approximations informed by CDC milestones and ADA
# first-tooth guidance. They are not a developmental assessment of a real child.
const FIRSTS := {
	"smile":[2,3,"My first social smile","I smiled back at a familiar face. They acted as if I had invented joy."],
	"roll":[4,6,"Rolling over","I rolled from my tummy onto my back. The floor became a much larger country."],
	"sit":[7,9,"Sitting up","I sat without someone propping me up. The view improved immediately."],
	"tooth":[6,14,"My first tooth","My first tooth appeared. The family celebrated; my gums were less enthusiastic."],
	"stand":[10,12,"Pulling up to stand","I pulled myself up against the furniture. Everything interesting was suddenly closer."],
	"word":[12,15,"A first word","I used my first word for someone familiar. Everyone had a different theory about what I meant."],
	"walk":[15,18,"My first steps","I took a few steps on my own. An entire room held its breath, then cheered."],
}

func state() -> Dictionary:
	var p := GameState.player
	if not p.has("life_course"):
		var plan := {}
		var occupied: Array = []
		for key in FIRSTS:
			var spec: Array = FIRSTS[key]
			var candidates: Array = []
			for month in range(int(spec[0]),int(spec[1])+1):
				if not occupied.has(month): candidates.append(month)
			candidates.shuffle()
			var month := int(candidates[0])
			occupied.append(month)
			plan[key]=month
		p["life_course"]={"months":int(p["age"])*12,"cursor":int(p["age"])*12,"plan":plan,"firsts":{},"seen":{},"last_scene":"","year":-1}
	return p["life_course"]

func monthly_mode() -> bool:
	return not Lives.separate() and not Lives.is_type("tv") and int(GameState.player.get("age",0))<2

func age_label() -> String:
	if monthly_mode(): return "Age %d months" % int(state()["months"])
	return "Age %d" % int(GameState.player["age"])

func advance_month() -> bool:
	var s := state()
	s["months"]=maxi(int(s["months"]),int(GameState.player["age"])*12)+1
	Lifestyle.advance(true)
	if int(s["months"])%12==0: return false
	GameState.player["time_left"]=mini(12,int(GameState.player["time_left"])+1)
	_development(int(s["months"]))
	# Quiet months are intentional: firsts never arrive as a stack of popups.
	if not EventEngine.has_pending() and randf()<0.4: _scene(0)
	return true

func _development(months: int) -> void:
	var s := state()
	var due: Array = []
	for key in FIRSTS:
		var month := int(s["plan"][key])
		if not s["firsts"].has(key) and month>int(s["cursor"]) and month<=months: due.append([key,month])
	due.sort_custom(func(a,b): return int(a[1])<int(b[1]))
	for entry in due:
		var key: String = entry[0]
		s["firsts"][key]=entry[1]
		GameState.add_milestone(int(entry[1])/12,"At %d months: %s" % [int(entry[1]),str(FIRSTS[key][2]).to_lower()])
		GameState.add_log("Month %d · %s" % [int(entry[1]),FIRSTS[key][3]])
	if due.size()==1:
		var spec: Array = FIRSTS[due[0][0]]
		EventEngine.push_info("👶",spec[2],"Month %d\n\n%s" % [int(due[0][1]),spec[3]])
	s["cursor"]=months

func yearly() -> void:
	if Lives.separate() or Lives.is_type("tv"): return
	var s := state()
	var age := int(GameState.player["age"])
	if int(s["year"])>=GameState.year_now(): return
	s["year"]=GameState.year_now()
	s["months"]=age*12
	_development(age*12)
	if age>=2: _scene(age)

func _scene(age: int) -> void:
	var s := state()
	var pool: Array = []
	for scene in scenes:
		if age<int(scene["min"]) or age>int(scene["max"]): continue
		if bool(scene.get("prison",false))!=GameState.in_prison(): continue
		if not s["seen"].has(scene["id"]) and str(scene["id"])!=s["last_scene"]: pool.append(scene)
	var d := Novelty.pick(pool)
	if d.is_empty(): return
	EventEngine.push_decision(d)

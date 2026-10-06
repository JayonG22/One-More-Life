extends Node
var checks := 0
var failures: Array = []
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func fresh(country: String = "us", gender: String = "female") -> void:
	EventEngine.pending.clear()
	GameState.new_life({"country":country,"gender":gender,"random_royalty":false,"origin":"together"})
func level(value: float) -> void:
	for stat in ["smarts","health","happiness","looks"]: GameState.player["stats"][stat]=value
	GameState.player["stats"]["stress"]=100-value
func _ready() -> void:
	seed(3030)
	fresh()
	var plan: Dictionary = LifeCourse.state()["plan"]
	var months: Array = []
	for key in LifeCourse.FIRSTS:
		var at := int(plan[key])
		ok(at>=int(LifeCourse.FIRSTS[key][0]) and at<=int(LifeCourse.FIRSTS[key][1]),"milestone outside age range "+key)
		ok(not months.has(at),"milestones stacked in same month")
		months.append(at)
	for month in range(1,25):
		EventEngine.pending.clear()
		var before: int = LifeCourse.state()["firsts"].size()
		EventEngine.progress()
		ok(int(GameState.player["age"])==month/12,"monthly age mismatch")
		ok(int(LifeCourse.state()["months"])==month,"calendar mismatch")
		ok(LifeCourse.state()["firsts"].size()-before<=1,"firsts piled up")
	ok(LifeCourse.state()["firsts"].size()==7,"missing infant milestones")
	for key in LifeCourse.FIRSTS: ok(Goals.has("development_"+key),"development trophy missing "+key)
	var saved := JSON.parse_string(JSON.stringify(GameState.to_dict())) as Dictionary
	GameState.from_dict(saved)
	for key in plan: ok(int(LifeCourse.state()["plan"][key])==int(plan[key]),"milestone schedule rerolled on load "+key)
	EventEngine.pending.clear()
	EventEngine.progress()
	ok(int(GameState.player["age"])==3,"yearly progression did not resume")
	ok(LifeCourse.state()["firsts"].size()==7,"first tooth or milestone repeated")
	fresh()
	GameState.player["age"]=40
	GameState.player.erase("life_course")
	LifeCourse.yearly()
	ok(LifeCourse.state()["firsts"].is_empty(),"legacy adult falsely awarded infancy")
	var ids := {}
	for scene in LifeCourse.scenes:
		ok(not ids.has(scene["id"]) and scene["choices"].size()==2,"invalid or duplicate scene")
		ids[scene["id"]]=true
	for age in range(0,131):
		ok(not LifeCourse.scenes.filter(func(s): return age>=int(s["min"]) and age<=int(s["max"]) and not s.get("prison",false)).is_empty(),"age has no authored scenes: "+str(age))
	GameState.player["age"]=25
	var previous := ""
	var used := {}
	for i in range(10):
		EventEngine.pending.clear()
		LifeCourse._scene(25)
		var current: String = LifeCourse.state()["last_scene"]
		ok(current!=previous and not used.has(current),"scene repeats before age-band pool exhausted")
		used[current]=true
		previous=current
	for context in Aptitude.WEIGHTS:
		var previous_score := -1.0
		var previous_chance := -1.0
		var previous_reward := -1.0
		for v in range(0,101,5):
			level(v)
			var score := Aptitude.score(context)
			var chance := Aptitude.chance(0.5,context)
			var reward := Aptitude.reward(context)
			ok(score>previous_score and chance>previous_chance and reward>previous_reward,"stat outcome is not monotonic "+context)
			previous_score=score;previous_chance=chance;previous_reward=reward
	level(0)
	seed(123)
	var low := {"performance":50.0}
	EventEngine._update_performance(low,"performance")
	level(100)
	seed(123)
	var high := {"performance":50.0}
	EventEngine._update_performance(high,"performance")
	ok(float(high["performance"])>float(low["performance"])+15,"school not affected by whole wellbeing")
	fresh()
	GameState.player["age"]=20
	var major: String = ContentDB.majors[0]["id"]
	var e: Dictionary = GameState.player["education"]
	e["stage"]="graduated"
	e["uni"]={"level":"undergraduate","major":major,"year":3,"years":4,"performance":42.0}
	level(0)
	seed(123)
	EventEngine._yearly_school()
	ok(e["degrees"].is_empty(),"failing final grades awarded qualification")
	level(100)
	e["uni"]={"level":"undergraduate","major":major,"year":3,"years":4,"performance":80.0}
	seed(123)
	EventEngine._yearly_school()
	ok(e["degrees"].size()==1,"passing final grades did not graduate")
	var legacy := {"skin":3,"style":17,"bg":5}
	var avatar := Avatar.sanitize(legacy)
	ok(avatar["style"]==17 and avatar["badge"]==0 and avatar["frame"]==0,"old avatar changed")
	ok(Avatar.STYLE.size()==38 and Avatar.BG_COL.size()==24,"avatar option count")
	for style in range(38): ok(Avatar.face_emoji({"style":style},25,"female")!="","empty avatar style")
	avatar["badge"]=8;avatar["frame"]=7
	Avatar.set_current(avatar)
	saved=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	ok(Avatar.for_player()["badge"]==8 and Avatar.for_player()["frame"]==7,"cosmetics not saved")
	ok(Lives.ROYAL_BIRTH_CHANCE.get("us",0)==0 and float(Lives.ROYAL_BIRTH_CHANCE["uk"])>0 and float(Lives.ROYAL_BIRTH_CHANCE["jp"])>0,"royal geography")
	fresh("uk","male")
	GameState.npcs.clear()
	GameState.create_npc("mother",{"age":35,"gender":"female"})
	var elder := GameState.create_npc("sibling",{"age":5,"gender":"female"})
	GameState.player["royal_rule_override"]="male_preference"
	Lives.setup_royal(true)
	ok(Lives.life()["line"]==1 and GameState.npcs[elder]["line"]==2,"traditional elder daughter displaces male heir")
	GameState.player["royal_rule_override"]="eldest_child"
	Lives.setup_royal(true)
	ok(GameState.npcs[elder]["line"]==1 and Lives.life()["line"]==2,"modern birth order wrong")
	GameState.player["gender"]="female"
	GameState.player["royal_rule_override"]="male_only"
	Lives.setup_royal(true)
	ok(Lives.life()["line"]==999,"ineligible member entered succession")
	GameState.player["royal_birth_kind"]="noble"
	Lives.setup_royal(true)
	GameState.player["age"]=20
	Lives._royal_yearly()
	ok(not Lives.life()["crowned"] and Lives.life()["noble"],"noble crowned automatically")
	fresh("uk","male")
	Lives.setup_royal(true)
	GameState.player["age"]=40
	Lives.life()["crowned"]=true
	var child := GameState.create_npc("child",{"age":20,"gender":"female","money":500})
	Lives._royal_yearly()
	ok(Dynasty.switch_to(child),"royal child switch failed")
	ok(Lives.is_type("royal") and not Lives.life()["crowned"] and GameState.player["money"]==500,"living transfer lost royal status or inherited crown/cash")
	fresh()
	ok(GameState.npcs_with("auntuncle",false).is_empty() and GameState.npcs_with("cousin",false).is_empty(),"extended family still spawned")
	GameState.player["origin"]="grandparent"
	saved=JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	ok(GameState.player["origin"]=="grandparent","origin corrupted on save/load")
	print("V30 TEST checks=%d failures=%d" % [checks,failures.size()])
	for reason in failures: print("FAIL: "+str(reason))
	get_tree().quit(0 if failures.is_empty() else 1)

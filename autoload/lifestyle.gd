extends Node

func state() -> Dictionary:
	var p := GameState.player
	if not p.has("lifestyle"): p["lifestyle"]={"activities":{},"last_year":-1,"last_month":-1,"report":""}
	return p["lifestyle"]

func note(activity: String) -> void:
	if Lives.separate() or Lives.is_type("tv"): return
	var habits: Dictionary = state()["activities"]
	habits[activity]=mini(6,int(habits.get(activity,0))+1)

func amount(keys: Array) -> float:
	var total := 0.0
	for key in keys: total+=float(state()["activities"].get(key,0))
	return minf(6,total)

# Targets are game balance, not clinical predictions. Time scales the change;
# a month never applies an entire year's decline, and birthdays cannot double it.
func advance(monthly: bool) -> void:
	if not GameState.is_alive() or Lives.separate() or Lives.is_type("tv"): return
	var p := GameState.player
	var s := state()
	var age := int(p["age"])
	if monthly:
		var month := int(LifeCourse.state()["months"])
		if age>=2 or int(s["last_month"])>=month: return
		s["last_month"]=month
	else:
		if age<=2 or int(s["last_year"])>=GameState.year_now(): return
		s["last_year"]=GameState.year_now()
	var movement := amount(["gym","walk","yoga"])
	var learning := amount(["read","library","course","instrument"])
	var calm := amount(["meditate","yoga","therapy"])
	var pleasure := amount(["games","movie","concert","social","volunteer"])
	var grooming := amount(["spa","dentist"])
	var pressure := maxf(0,GameState.stat("stress")-55)/10.0
	var illness := 1.0 if str(p["illness"])!="" else 0.0
	var older := maxf(0,age-45)/20.0 if not Lives.ageless() else 0.0
	var targets := {
		"health":68.0+movement*4.0-pressure*4.0-illness*16.0-older*5.0,
		"smarts":50.0+learning*5.0-pressure*2.0-maxf(0,age-75)*0.2,
		"looks":60.0+movement*2.0+grooming*5.0-illness*8.0-older*4.0,
		"happiness":58.0+pleasure*4.0+calm*2.0-pressure*4.0-illness*8.0,
		"stress":25.0+pressure*2.0-calm*4.0-pleasure*2.0,
	}
	if not monthly and age>=6:
		var body := Body.st()
		# Existing long-term accounts still matter alongside this year's actions.
		targets["health"]+=(float(body["fitness"])-55)*0.12+(float(body["sleep"])-70)*0.12+(float(body["diet"])-55)*0.12-float(body["drink"])*0.08
		targets["smarts"]+=(float(body["sleep"])-70)*0.08
		targets["happiness"]+=(float(body["sleep"])-70)*0.12
		targets["health"]+=float(Daily.DIETS.get(str(p.get("diet","")),["","","",{}])[3].get("health",0))*2.0
	if monthly:
		var closeness := 0.0
		var parents := 0
		for id in GameState.npcs:
			var n: Dictionary = GameState.npcs[id]
			if n.get("alive",false) and n.get("relation","") in ["mother","father","stepparent"]:
				closeness+=float(n.get("closeness",50)); parents+=1
		var care := closeness/parents if parents>0 else 35.0
		targets["health"]=70.0+care*0.15-illness*16.0
		targets["happiness"]=45.0+care*0.4-illness*8.0
		targets["smarts"]=50.0+care*0.2
		targets["looks"]=60.0-illness*8.0
		targets["stress"]=35.0-care*0.25
	if p["housing"]=="homeless":
		targets["health"]-=15; targets["happiness"]-=15; targets["stress"]+=15
	var bounds := {"health":[-10.0,6.0],"smarts":[-5.0,4.0],"looks":[-6.0,4.0],"happiness":[-12.0,8.0],"stress":[-10.0,12.0]}
	var before := Insight.snapshot()
	for key in targets:
		var change := clampf((clampf(float(targets[key]),0,100)-GameState.stat(key))*0.18,float(bounds[key][0]),float(bounds[key][1]))
		GameState.change_stat(key,change/12.0 if monthly else change)
	var explanation := "Infant care, home conditions and health shaped this month." if monthly else "Movement %d · learning %d · relaxation %d · enjoyment %d · grooming %d. Age, current stress, illness and housing also affect the result." % [int(movement),int(learning),int(calm),int(pleasure),int(grooming)]
	s["report"]=explanation
	Insight.record(before,"Monthly lifestyle" if monthly else "Yearly lifestyle",explanation)
	if not monthly:
		GameState.add_log("Lifestyle this year: "+explanation+" "+" · ".join(Insight.deltas(before)))
		s["activities"]={}

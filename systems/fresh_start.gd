extends RefCounted
var h
const SCENARIOS := {
	"first_keys":["First keys","Age 18 · a first apartment, a thin cushion and plenty to learn",18,9000,"budget"],
	"second_act":["Second act","Age 32 · restart your work life without erasing your people",32,14000,"learning"],
	"small_world":["A bigger small world","Age 45 · build belonging and a sustainable ordinary life",45,18000,"people"]
}
var scenes: Dictionary={}
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/fresh_start.json",{})
func st() -> Dictionary: return h.section("fresh",{"scenario":"","stage":0,"steady":0,"last_year":-1,"completed":false,"history":[],"choices":[],"person":""})
func start(key: String) -> void:
	if not SCENARIOS.has(key): return
	var spec: Array=SCENARIOS[key]
	GameState.new_life({"country":"us","gender":["female","male","nonbinary"].pick_random(),"born_year":GameState.START_YEAR-int(spec[2]),"random_royalty":false})
	GameState.player["age"]=int(spec[2]); GameState.player["money"]=Actions._cost(int(spec[3]))
	GameState.player["housing"]="apartment"; GameState.player["time_left"]=GameState.TIME_PER_YEAR
	GameState.player["education"]["stage"]="graduated"; GameState.player["education"]["hs_graduated"]=true
	GameState.player["education"]["performance"]=clampf(GameState.stat("smarts")*0.65+25,35,90)
	for n in GameState.npcs.values():
		n["age"]=int(n["age"])+int(spec[2])
		if int(n["age"])>100: n["alive"]=false
	var person := GameState.create_npc("friend",{"age":int(spec[2])+2,"closeness":48})
	st()["scenario"]=key; st()["person"]=FamilyChronicle.identity(GameState.npc(person))
	Tenancy.sync(); FamilyChronicle.sync(); EventEngine.pending.clear(); EventEngine.displayed.clear()
	GameState.log_years=[{"age":int(spec[2]),"lines":[]}]
	GameState.add_log("Fresh Start · "+str(spec[0])+". I have finished secondary school and moved into a rented apartment. My deposit came from my savings.")
	h.note("A new beginning","Four personal chapters and three steady years. I can build this life at my own pace and keep living it after the scenario.")
func review() -> Dictionary:
	var p := GameState.player
	var buffer: int=int(p["money"])+int(p.get("savings",0))+int(h.modules["funds"].value(h.uid()))
	var target := maxi(Actions._cost(1500),int(p.get("last_expenses",0))/4)
	var close: bool=(GameState.npcs_with("friend")+GameState.npcs_with("best_friend")).any(func(id): return GameState.npc(id).get("alive",false) and float(GameState.npc(id).get("closeness",0))>=60)
	var route := str(SCENARIOS[st()["scenario"]][4])
	var trained: bool=not h.modules["learning"].st()["completed"].is_empty() or not Employment.st()["certificates"].is_empty()
	var progress: bool= buffer>=target if route=="budget" else trained if route=="learning" else close
	return {"income":int(p.get("last_income",0))>0,"health":GameState.stat("health")>=45,"happiness":GameState.stat("happiness")>=45,"priority":progress,"buffer":buffer,"target":target}
func yearly() -> void:
	pass
func after_finances() -> void:
	var s := st()
	if s["scenario"]=="" or s["completed"] or not GameState.is_alive() or Lives.separate() or int(s["last_year"])==GameState.year_now(): return
	s["last_year"]=GameState.year_now()
	var r := review(); var stable: bool= r["income"] and r["health"] and r["happiness"] and r["priority"]
	s["steady"]=int(s["steady"])+1 if stable else 0
	s["history"].push_front({"year":GameState.year_now(),"review":r.duplicate(true),"steady":s["steady"]})
	if s["history"].size()>16: s["history"].resize(16)
	if int(s["steady"])>=3 and int(s["stage"])>=4:
		s["completed"]=true; GameState.add_milestone(int(GameState.player["age"]),"finished Fresh Start: "+str(SCENARIOS[s["scenario"]][0]))
		h.note("A life of my own","I finished my Fresh Start. I can keep building the work, home and relationships I have made.")
func chapter() -> void:
	var s := st()
	if s["scenario"]=="" or s["completed"] or int(s["stage"])>=4 or not h.pay("fresh_chapter",1,0,18): return
	var scene: Dictionary=scenes[s["scenario"]][int(s["stage"])]
	var options: Array=[]
	for choice in scene["choices"]:
		var fee := Actions._cost(int(choice.get("cost",0)))
		var option := {"label":str(choice["label"])+( " · "+GameState.fmt_money(fee) if fee>0 else "")}
		if fee>0: option["requires"]={"money":fee}
		options.append(option)
	h.decision("fresh","chapter",{"scenario":s["scenario"],"stage":s["stage"]},scene["title"],scene["text"],options)
func resolve(op: String, args: Dictionary, answer: int) -> void:
	var s := st()
	if op!="chapter" or s["scenario"]!=args["scenario"] or int(s["stage"])!=int(args["stage"]): return
	var scene: Dictionary=scenes[s["scenario"]][int(s["stage"])]
	var choice: Dictionary=scene["choices"][answer]; var fee := Actions._cost(int(choice.get("cost",0)))
	if int(GameState.player["money"])<fee and fee>0:
		h.done("🌱","Keep the plan","The paid option is no longer affordable. The chapter remains unfinished; choose an affordable route in a later year."); return
	GameState.player["money"]-=fee; GameState.apply_effects(choice.get("effects",{}))
	if choice.has("skill"): Market.learn(str(choice["skill"]),1)
	var id: String=h.person(str(s["person"]))
	if id!="" and GameState.npc(id).get("alive",false):
		BondStats.apply(id,{"affection":int(choice.get("bond",0)),"trust":int(choice.get("trust",0))})
		FamilyChronicle.remember(id,str(scene["title"])+": "+str(choice["label"]))
	s["choices"].append({"year":GameState.year_now(),"chapter":scene["title"],"choice":choice["label"],"cost":fee}); s["stage"]+=1
	var result := str(choice["result"])
	if fee>0: result+=" I spent "+GameState.fmt_money(fee)+"."
	if choice.has("skill"): result+=" My "+str(choice["skill"])+" skill grew."
	if id!="" and GameState.npc(id).get("alive",false) and int(choice.get("bond",0))>0: result+=" "+str(GameState.npc(id)["first"])+" and I felt a little closer."
	h.done("🌱",scene["title"],result+" Chapter %d of 4." % s["stage"])
func menu(_key: String) -> Dictionary:
	var s := st(); var rows: Array=[]; var info: Array=[]
	if s["scenario"]=="": info.append("Start a Fresh Start scenario from the main menu. Existing lives stay in their own save slots.")
	else:
		var r := review()
		info.append(str(SCENARIOS[s["scenario"]][0])+" · "+("Completed; your life continues" if s["completed"] else "%d/4 chapters · %d/3 consecutive steady years" % [s["stage"],s["steady"]]))
		info.append("A steady year needs income, health and happiness at 45+, plus "+{"budget":"three months' bills saved, with a minimum cushion of "+GameState.fmt_money(Actions._cost(1500)),"learning":"a completed practical course or work-training certificate","people":"a living friend at 60+ closeness"}[SCENARIOS[s["scenario"]][4]]+". Checked after each year.")
		info.append("Income %s · health %s · happiness %s · personal priority %s" % ["✓" if r["income"] else "—","✓" if r["health"] else "—","✓" if r["happiness"] else "—","✓" if r["priority"] else "—"])
		if int(s["stage"])<4: rows.append(h.row("fresh","Continue my chapter","1 time · once per year · free options available","chapter",null,not h.used("fresh_chapter")))
	rows.append(h.nav("learning","Learning & placements","Earn skills at a sustainable pace"))
	rows.append(h.nav("people","People & commitments","The relationships behind a life"))
	return {"icon":"🌱","title":"Fresh Start","info":info,"rows":rows}
func act(key: String, _arg: Variant) -> void:
	if key=="chapter": chapter()

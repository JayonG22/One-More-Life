extends RefCounted
var h
var scenes: Array=[]
const STYLES := {"karate":["Measured counter",1],"judo":["Balance and control",1],"taekwondo":["Keep the distance",2],"krav":["Change the angle",2],"bjj":["Patient defence",2],"boxing":["Footwork and guard",1]}
const OPPONENTS := ["pressing","patient","wide"]
const PLANS := ["Control the pace","Use the available space","Draw them forward"]
func _init(hub):
	h=hub; scenes=ContentDB._load_json("res://data/fixture_scenes.json",[])
func st() -> Dictionary: return h.section("seasons",{"season":{},"history":[],"training":0,"style":"","last_year":-1,"pace":"balanced"})
func school() -> bool: return GameState.in_school() and int(GameState.player["age"])<18
func start() -> void:
	if not st()["season"].is_empty(): return
	var sport := str(Daily._ss()["sport"]) if school() else "amateur league"
	if school() and sport=="": return
	if not h.pay("season_start",1,Actions._cost(0 if school() else 80),6): return
	var readiness := Aptitude.score("physical")+Market.skill("Sports")*2+mini(10,int(st()["training"])*2)
	var chance := clampf(0.30+readiness/200.0,0.1,0.9)
	if school() and randf()>chance:
		h.done("🏅","Selection feedback","I did not make the team this year. Training and fitness improve the next selection; joining a sport alone does not guarantee a place.")
		return
	var fixtures: Array=[]
	for i in range(3): fixtures.append({"opponent":OPPONENTS.pick_random(),"rating":randi_range(40,85),"roll":randf(),"injury_roll":randf(),"done":false})
	var peers := GameState.npcs_with("classmate") if school() else GameState.npcs_with("friend")
	var id := str(peers.pick_random()) if not peers.is_empty() else GameState.create_npc("friend",{"age":maxi(6,int(GameState.player["age"])),"closeness":40})
	st()["season"]={"year":GameState.year_now(),"sport":sport,"school":school(),"fixtures":fixtures,"stage":0,"wins":0,"stamina":100,"peer":FamilyChronicle.identity(GameState.npc(id)),"owner":h.uid()}
	h.done("🏅","A place on the team","Three fixtures are ready. Each costs 1 time. Opponents, ratings and luck are saved; preparation and tactics change the result. The season closes at the next age-up.")
func train() -> void:
	if not h.pay("season_train",1,Actions._cost(20),6): return
	st()["training"]=mini(5,int(st()["training"])+1)
	var s: Dictionary=st()["season"]
	if not s.is_empty(): s["stamina"]=mini(100,int(s["stamina"])+15)
	GameState.change_stat("health",0.5)
	h.done("🎯","Practice feedback","Preparation %d/5. Consistent practice helps selection and fixtures; rest and health still matter." % st()["training"])
func fixture() -> void:
	var s: Dictionary=st()["season"]
	if s.is_empty() or int(s["year"])!=GameState.year_now() or int(s["stage"])>=3: return
	if not h.pay("fixture:"+str(s["stage"]),1,0,6): return
	var f: Dictionary=s["fixtures"][int(s["stage"])]
	f["pace"]=st()["pace"]
	if not f.has("cue"):
		var scene := Novelty.pick(scenes.filter(func(c): return c["opponent"]==f["opponent"]))
		if not scene.is_empty(): f["cue"]=scene["text"]; Novelty.note(scene)
	var cue: String=str(f.get("cue",{"pressing":"They press high and leave room behind them.","patient":"They hold position and wait for a rushed move.","wide":"They spread out, leaving the middle less protected."}[f["opponent"]]))
	h.decision("seasons","fixture",{"stage":s["stage"]},"The final minute",cue+" Rating %d · stamina %d · pace %s." % [f["rating"],s["stamina"],f["pace"]],PLANS)
func pace(kind: String) -> void:
	if kind not in ["safe","balanced","push"] or h.blocked(6)!="": return
	st()["pace"]=kind
	h.note("Competition pace",kind.capitalize()+" chosen. Safe preserves stamina; pushing adds chance and strain. Injuries still affect readiness.")
func rest() -> void:
	var s: Dictionary=st()["season"]
	if s.is_empty() or not h.pay("season_rest",1,0,6): return
	s["stamina"]=mini(100,int(s["stamina"])+25)
	h.done("🫖","Recovery time","Stamina restored by up to 25. Rest does not erase a medical injury.",{"stress":-2})
func style(discipline: String) -> void:
	if not STYLES.has(discipline) or int(GameState.player.get("martial",{}).get(discipline,{}).get("belt",0))<int(STYLES[discipline][1]): return
	if h.blocked(6)!="": return
	st()["style"]=discipline
	h.note("Martial approach",str(STYLES[discipline][0])+" selected. It improves the matching counter in tactical sparring; it does not unlock an unearned belt.")
func resolve(op: String, args: Dictionary, answer: int) -> void:
	if op!="fixture": return
	var s: Dictionary=st()["season"]
	if s.is_empty() or int(s["stage"])!=int(args["stage"]) or s["owner"]!=h.uid(): return
	var f: Dictionary=s["fixtures"][int(s["stage"])]
	if f["done"]: return
	var good: bool = answer=={"pressing":1,"patient":2,"wide":0}[f["opponent"]]
	var readiness := Aptitude.score("physical")+Market.skill("Sports")*2+int(st()["training"])*2
	var pace: String=str(f.get("pace","balanced"))
	var injured: bool=not GameState.player.get("medical",{}).get("injuries",{}).is_empty()
	var strain: float=clampf((0.04 if pace=="push" else 0.005 if pace=="safe" else 0.015)+(0.10 if injured else 0.0)+maxf(0,45-GameState.stat("health"))/400.0,0,0.30)
	f["entered_injured"]=injured
	var chance := clampf((0.05 if pace=="push" else -0.03 if pace=="safe" else 0.0)+(-0.10 if injured else 0.0)+0.48+(readiness-float(f["rating"]))/180.0+(0.16 if good else -0.08)+(int(s["stamina"])-70)/400.0,0.08,0.92)
	var won := float(f["roll"])<chance
	f["done"]=true; f["plan"]=answer; f["chance"]=chance; f["won"]=won
	s["stage"]=int(s["stage"])+1; s["wins"]=int(s["wins"])+(1 if won else 0); s["stamina"]=maxi(0,int(s["stamina"])-(12 if pace=="safe" else 32 if pace=="push" else 20 if good else 30))
	f["injury_chance"]=strain
	f["injured"]=float(f.get("injury_roll",1.0))<strain
	if f["injured"] and not injured: Expansion.add_injury("sprain","a league fixture")
	f["pace_note"]="Pushed: extra strain and stamina used." if pace=="push" else "Safe pace conserved stamina." if pace=="safe" else "Balanced effort."
	if s["school"]: Depth.school_record("sport",0.8 if won else 0.35)
	var id: String=h.person(str(s["peer"]))
	if id!="" and GameState.npc(id).get("alive",false): BondStats.apply(id,{"respect":2 if good else 0,"affection":1}); FamilyChronicle.remember(id,"Shared a league fixture and its result.")
	h.done("🏅","Fixture result","%s · %d%% chance. %s %s Strain risk %d%%. Fitness and the saved rolls mattered." % ["Won" if won else "Lost",int(chance*100),"The plan answered their shape." if good else "The plan played into their shape.",f["pace_note"],strain*100],{"happiness":3 if won else 1,"stress":1})
	if int(s["stage"])==3: close("Completed")
func close(reason: String) -> void:
	var s: Dictionary=st()["season"]
	if s.is_empty(): return
	s["result"]=reason
	if int(s["stage"])==3:
		Market.learn("Sports",1)
		if int(s["wins"])==3 and s["school"]: GameState.counter("school_titles")
		GameState.add_milestone(int(GameState.player["age"]),"finished a "+str(s["sport"])+" season")
	st()["history"].push_front(s.duplicate(true)); st()["season"]={}
	if st()["history"].size()>16: st()["history"].resize(16)
	h.note("Season closed",str(s["sport"])+" · "+reason+" · %d/3 played, %d wins. Only completed seasons earn the skill point." % [s["stage"],s["wins"]])
func yearly() -> void:
	if Lives.separate(): return
	var s: Dictionary=st()["season"]
	if not s.is_empty() and int(s["year"])<GameState.year_now(): close("Unfinished at year end")
func menu(_page: String) -> Dictionary:
	var rows: Array=[]; var s: Dictionary=st()["season"]
	for kind in ["safe","balanced","push"]: rows.append(h.row("seasons",kind.capitalize()+" pace"+(" ✓" if st()["pace"]==kind else ""),{"safe":"Conserve stamina · less chance and strain","balanced":"Normal stamina, chance and strain","push":"Chance +5 points · more stamina and strain"}[kind],"pace",kind,st()["pace"]!=kind))
	var info: Array=["Active injuries lower match chance and raise strain. Rest supports stamina; Medical care treats injuries.","Preparation %d/5. School selection and adult amateur competition share tactics, but only school fixtures add school evidence. No cash prize." % st()["training"]]
	if s.is_empty(): rows.append(h.row("seasons","Try for the school team" if school() else "Join an amateur season","1 time · free at school, otherwise "+GameState.fmt_money(Actions._cost(80)),"start",null,not h.used("season_start") and (not school() or str(Daily._ss()["sport"])!="")))
	else:
		info.append(str(s["sport"])+" · %d/3 played · %d wins · stamina %d" % [s["stage"],s["wins"],s["stamina"]])
		rows.append(h.row("seasons","Play the next fixture","1 time · read the opponent and choose a plan","fixture"))
		rows.append(h.row("seasons","Take recovery time","1 time · stamina +25 · once a year","rest",null,not h.used("season_rest") and int(s["stamina"])<100))
		rows.append(h.row("seasons","Leave this season","Keep participation; no completion reward","leave"))
	rows.append(h.row("seasons","Team practice","1 time · "+GameState.fmt_money(Actions._cost(20))+" · once a year","train",null,not h.used("season_train")))
	for d in STYLES:
		if int(GameState.player.get("martial",{}).get(d,{}).get("belt",0))>=int(STYLES[d][1]): rows.append(h.row("seasons",str(STYLES[d][0]),"Use an earned martial style in tactical sparring","style",d))
	for record in st()["history"]: info.append("%d · %s · %s · %d wins" % [record["year"],record["sport"],record["result"],record["wins"]])
	return {"title":"Teams & seasons","icon":"🏅","info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"start": start()
		"train": train()
		"fixture": fixture()
		"style": style(str(arg))
		"pace": pace(str(arg))
		"rest": rest()
		"leave": if h.blocked(6)=="": close("Left by choice")

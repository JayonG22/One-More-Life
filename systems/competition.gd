extends RefCounted
var h
const GAMES := {"repair":["Practical repair","Trades"],"budget":["Household budgeting","Finance"],"negotiation":["Contract negotiation","Business"],"cooking":["Kitchen service","Food"],"care":["Care coordination","Care"],"music":["Music practice","Arts"],"logistics":["Delivery planning","Logistics"],"interview":["Interview evidence","General"],"tactics":["Tactical sparring","Sports"]}
const RELATED_FIELDS := {"repair":["Trades","Engineering","Facilities","Energy"],"care":["Care","Healthcare"],"cooking":["Food","Hospitality"],"negotiation":["Business","Retail","Legal","Government","Office"],"logistics":["Logistics","Transport","Retail"],"music":["Arts","Media"],"budget":["Finance"],"tactics":["Sports"],"interview":[]}
func _init(hub): h=hub
func st() -> Dictionary: return h.section("skills",{"active":{},"records":{},"opponents":{},"assist":false,"feedback":[],"serial":0})
func reward_field(kind: String) -> String:
	var field := str(GameState.player.get("job",{}).get("field",""))
	return field if GameState.has_job() and RELATED_FIELDS.get(kind,[]).has(field) else str(GAMES[kind][1])
func start(kind: String, practice: bool) -> void:
	if not GAMES.has(kind) or not st()["active"].is_empty() or h.blocked(6)!="": return
	if kind in ["repair","negotiation","care","interview"] and int(GameState.player["age"])<16 and not practice: return
	if kind=="tactics" and GameState.player.get("martial",{}).is_empty(): return
	if not practice and not h.pay("challenge:"+kind,1,Actions._cost(25),6): return
	st()["serial"]=int(st()["serial"])+1
	st()["active"]={"kind":kind,"practice":practice,"token":int(st()["serial"]),"owner":h.uid(),"format":"hands_on" if kind in ["repair","music","negotiation"] else "workshop","board_seed":randi()}
	st()["active"]["field"]=reward_field(kind)
	st()["active"]["work_session"]=Employment.job_session() if GameState.has_job() else -1
	if kind=="tactics":
		st()["active"]["style"]=["patient","aggressive","countering"].pick_random()
		st()["active"]["tells"]=[]
		for i in range(5): st()["active"]["tells"].append(randi_range(0,4))
	run()
func run() -> void:
	var a: Dictionary=st()["active"]
	if a.is_empty() or a["owner"]!=h.uid(): return
	var kind := str(a["kind"]); var field := str(a.get("field",GAMES[kind][1])); var skill := Aptitude.score("physical" if kind=="tactics" else "creative" if kind=="music" else "work")+Market.skill(field)*2
	var params := {"kind":kind,"title":GAMES[kind][0],"skill":skill,"practice":a["practice"],"rounds":3 if a["practice"] else 5,"difficulty":1.0,"assisted":st()["assist"],"progress":a.get("progress",{}).duplicate(true),"board_seed":a.get("board_seed",12345),"progress_token":a["token"],"progress_owner":a["owner"]}
	if kind=="tactics":
		var trained: Dictionary=GameState.player.get("martial",{})
		var best := 0
		for d in trained: best=maxi(best,int(trained[d].get("belt",0)))
		params["belt"]=best; params["martial_style"]=h.modules["seasons"].st()["style"]; params["opponent_style"]=a.get("style","patient"); params["tells"]=a.get("tells",[0,1,2,3,4])
	if st()["assist"]:
		result(Minigames.auto_score(skill),{"auto":true,"assisted":true},int(a["token"]),str(a["owner"])); return
	Minigames.play(("hands_" if a.get("format","workshop")=="hands_on" else "workshop_")+kind,params,Callable(self,"result").bind(int(a["token"]),str(a["owner"])))
func checkpoint(progress: Dictionary, token: int, owner: String) -> void:
	var a: Dictionary=st()["active"]
	if a.is_empty() or int(a["token"])!=token or a["owner"]!=owner or owner!=h.uid(): return
	a["progress"]=progress.duplicate(true)
	if SaveManager.current_slot>0: SaveManager.save_game()
func result(score: float, detail: Dictionary, token: int, owner: String) -> void:
	var a: Dictionary=st()["active"]
	if a.is_empty() or int(a["token"])!=token or owner!=h.uid() or a["owner"]!=owner: return
	score=clampf(score,0,1)
	st()["active"]={}
	var kind := str(a["kind"]); var practice := bool(a["practice"])
	var field := str(a.get("field",GAMES[kind][1]))
	var r: Dictionary=st()["records"].get(kind,{"attempts":0,"best":0.0,"last":0.0})
	if not practice:
		r["attempts"]=int(r["attempts"])+1; r["last"]=score; r["best"]=maxf(float(r["best"]),score); st()["records"][kind]=r
		if score>=0.60:
			Market.learn(field,1)
			if kind=="interview": Market.st()["interview_xp"]=minf(0.15,float(Market.st()["interview_xp"])+0.015)
		if GameState.has_job() and str(GameState.player["job"]["field"])==field and int(a.get("work_session",Employment.job_session()))==Employment.job_session(): GameState.apply_effects({"job_perf":2 if score>=0.6 else -1,"stress":1})
		if GameState.in_school(): Depth.school_record("practical:"+kind,score)
		GameState.change_stat("happiness",2 if score>=0.6 else 0)
	var text := "%d%% · %s. %s" % [score*100,"assisted result" if detail.get("auto",false) else "strategy and execution", "Practice changes no stats, portfolio or rewards. Earned martial styles preserve stamina on matching counters." if practice else "Skill/evidence gains need 60%+. One scored attempt per year; no cash prize."]
	if detail.has("feedback"): text+="\n"+str(detail["feedback"])
	st()["feedback"].push_front({"kind":kind,"score":score,"practice":practice,"year":GameState.year_now(),"text":text})
	if st()["feedback"].size()>20: st()["feedback"].resize(20)
	var notes: Array=[]
	for line in str(detail.get("feedback","")).split("\n"):
		var note: String=line.substr(line.find(": ")+2) if line.begins_with("Round ") and line.contains(": ") else line
		if note!="" and not notes.has(note): notes.append(note)
	var brief := "%d%% · %s. %s" % [score*100,"assisted" if detail.get("auto",false) else "completed","Practice: no rewards." if practice else "60%+ earns relevant skill/evidence; no cash prize."]
	if not practice: brief+="\n"+field+" skill · "+str(Market.skill(field))+"/10."
	if not notes.is_empty(): brief+="\n"+"\n".join(notes.slice(0,2))
	if notes.size()>2: brief+="\nFull feedback stays with practice history."
	h.done("🎯","Challenge feedback",brief)
func yearly() -> void: pass
func resolve(_op: String, _args: Dictionary, _answer: int) -> void: pass
func game_rows(rows: Array, kinds: Array) -> void:
	for kind in kinds:
		rows.append(h.row("skills",GAMES[kind][0],"1 time · "+GameState.fmt_money(Actions._cost(25))+" · "+reward_field(str(kind)),"start",[kind,false],not h.used("challenge:"+kind)))
		rows.append(h.row("skills","Practice "+str(GAMES[kind][0]).to_lower(),"Free · no rewards","start",[kind,true]))
func feedback(info: Array, kinds: Array) -> void:
	for kind in kinds:
		var record: Dictionary=st()["records"].get(kind,{})
		if not record.is_empty(): info.append(str(GAMES[kind][0])+" · best %d%% · %d scored attempts" % [int(float(record["best"])*100),int(record["attempts"])])
	for f in st()["feedback"].slice(0,4):
		if kinds.has(str(f["kind"])): info.append(str(GAMES[f["kind"]][0])+" · "+str(f["score"]*100)+"% · "+("practice" if f["practice"] else "scored"))
func menu(key: String) -> Dictionary:
	var rows: Array=[]; var info: Array=[]
	if key in ["","root","work"]:
		rows=[h.nav("skills","Trade & planning","Repair and logistics","trade"),h.nav("skills","People & interviews","Negotiation and interview practice","people"),h.nav("skills","Service work","Cooking and care","service")]
		rows.append(h.row("skills","Assisted challenges: "+("ON" if st()["assist"] else "OFF"),"Resolve scored practice using relevant skill","assist"))
		if not st()["active"].is_empty(): rows.append(h.row("skills","Resume saved challenge","The original cost stays paid; one result can apply","resume"))
		info=["Short, contextual practice. Scored runs cost time and a small fee; practice has no rewards."]
		feedback(info,["repair","logistics","negotiation","interview","cooking","care"])
		return {"icon":"🧰","title":"Work practice","info":info,"rows":rows}
	var kinds: Array=[]; var title := "Practice"
	match key:
		"trade": kinds=["repair","logistics"]; title="Trade & planning"
		"people": kinds=["negotiation","interview"]; title="People & interviews"
		"service": kinds=["cooking","care"]; title="Service work"
		"budget": kinds=["budget"]; title="Household budget"
		"creative": kinds=["music"]; title="Studio practice"
		"martial": kinds=["tactics"]; title="Tactical sparring"
		_: return {"icon":"🧰","title":"Work practice","info":[],"rows":[]}
	info=["Scored run · 1 time · "+GameState.fmt_money(Actions._cost(25))+". Practice is free and has no rewards."]
	game_rows(rows,kinds); feedback(info,kinds)
	rows.push_front(h.row("skills","Assisted challenges: "+("ON" if st()["assist"] else "OFF"),"Resolve scored runs using relevant skill","assist"))
	if not st()["active"].is_empty() and kinds.has(str(st()["active"]["kind"])): rows.push_front(h.row("skills","Resume saved challenge","Continue from your saved round","resume"))
	return {"icon":"🧰","title":title,"info":info,"rows":rows}
func act(key: String, arg: Variant) -> void:
	match key:
		"start": start(str(arg[0]),bool(arg[1]))
		"resume": if h.state()["prompt"].is_empty(): run()
		"assist": if st()["active"].is_empty() and h.blocked(6)=="": st()["assist"]=not st()["assist"]

extends Node

## Player-led challenges persist in the save and cannot pay out twice.
var jobs: Dictionary = {}
var lessons: Dictionary = {}
var career_cases: Array = []
var club_work
var clique_life
const CLAIMS := {
	"debt": ["Unpaid debt", "A signed loan receipt", "The defendant says the money was a gift."],
	"contract": ["Broken contract", "The agreed work and the missed deadline", "The defendant disputes what was promised."],
	"property": ["Property damage", "Dated photographs and a repair estimate", "The defendant disputes who caused the damage."],
	"defamation": ["False public allegation", "The original publication and evidence it was false", "The defendant disputes the statement and the loss."],
	"injury": ["Injury claim", "The incident report and recorded expenses", "The defendant disputes responsibility for the injury."]
}
const MOVES := {
	"karate": ["Straight punch", "Body kick", "Counter combination", "Distance control"],
	"judo": ["Grip control", "Foot sweep", "Hip throw", "Transition to a pin"],
	"boxing": ["Jab", "Body combination", "Slip and counter", "Angle out"],
	"taekwondo": ["Front kick", "Round kick", "Turning combination", "Range trap"],
	"krav": ["Guard and retreat", "Break contact", "Defensive counter", "Exit under pressure"],
	"bjj": ["Frame and escape", "Guard recovery", "Sweep", "Positional control"]
}
const SPORT_MOMENTS := [
	["A tired defender overcommits with seconds left.", "Use the opening and keep a safe outlet", "Force a highlight through traffic", "Stop and complain", 0],
	["You are ahead late, and an opponent wants you to rush.", "Protect possession and use the clock", "Take the first risky chance", "Ignore the clock", 0],
	["You are behind late; your usual route is covered.", "Use the prepared second option", "Repeat the blocked play", "Give up the possession", 0],
	["A teammate has a better opening than you.", "Set up the teammate", "Chase your own highlight", "Wait until the opening closes", 0],
	["The official pauses play after a disputed call.", "Reset and follow the restart", "Argue until the restart happens", "Switch off and wait", 0],
	["A strain flares just before the decisive play.", "Tell the coach and adjust the role", "Hide it and force maximum effort", "Abandon the plan silently", 0]
]

func _ready() -> void:
	club_work=preload("res://systems/club_work.gd").new(self)
	clique_life=preload("res://systems/clique_life.gd").new(self)
	career_cases=ContentDB._load_json("res://data/career_cases.json",[])
	jobs = JSON.parse_string(FileAccess.get_file_as_string("res://data/job_tasks.json"))
	# Kept for the standalone quiz/debug harness; live grade assessments use Campus.
	lessons = JSON.parse_string(FileAccess.get_file_as_string("res://data/lessons.json"))

func state() -> Dictionary:
	var p := GameState.player
	if not p.has("depth") or not p["depth"] is Dictionary:
		p["depth"] = {"used": {}, "subjects": {}, "active": {}, "serial": 0, "sport_seen": [], "claims": []}
	return p["depth"]

func available(key: String, limit: int = 1) -> bool:
	var used: Dictionary = state()["used"]
	var stamp := "%d:%s" % [GameState.year_now(), key]
	return int(used.get(stamp, 0)) < limit and (state()["active"] as Dictionary).is_empty()

func _begin(key: String, kind: String, data: Dictionary, time: int = 1) -> bool:
	if not GameState.is_alive() or not available(key) or not EventEngine.pending.is_empty(): return false
	if not GameState.spend_time(time):
		EventEngine.push_info("⏳", "No time left", "This takes %d time point(s)." % time)
		return false
	var st := state()
	var stamp := "%d:%s" % [GameState.year_now(), key]
	st["used"][stamp] = int(st["used"].get(stamp, 0)) + 1
	# Keep at most a few recent years of activity counters.
	for old in st["used"].keys():
		if int(str(old).get_slice(":",0)) < GameState.year_now()-2: st["used"].erase(old)
	st["serial"] = int(st["serial"]) + 1
	st["active"] = data.duplicate(true)
	st["active"].merge({"kind":kind,"token":st["serial"],"round":0,"step":0,"points":0},true)
	return true

func _choice(label: String, op: String, value: Variant) -> Dictionary:
	return {"label":label,"outcomes":[{"text":"","depth":{"op":op,"value":value,"token":int(state()["active"].get("token",-1)),"round":int(state()["active"].get("step",0))}}]}

func _push(title: String, text: String, choices: Array, icon: String="🎯") -> void:
	var prompt := {"id":"_depth","icon":icon,"title":title,"text":text,"choices":choices,"no_friction":true}
	state()["active"]["prompt"]=prompt.duplicate(true)
	EventEngine.push_decision(prompt)

func restore() -> void:
	var active: Dictionary = state()["active"]
	if active.is_empty(): return
	if active.has("prompt"):
		EventEngine.push_decision(active["prompt"])
	else:
		state()["active"]={}
		GameState.add_log("An interrupted challenge ended without a reward. Time and costs already spent remained spent.")

## Legacy standalone quiz entry point. Player-facing grade work lives in Campus.
func school(subject: String, practical: bool = false) -> void:
	if not GameState.in_school() and not GameState.in_university(): return
	if not lessons.has(subject): return
	var fresh_bank: Array=[]
	if not practical:
		for i in range(lessons[subject].size()):
			var q: Dictionary=lessons[subject][i].duplicate(true)
			q["id"]="quiz."+subject+"."+str(i); q["family"]="quiz."+subject
			if int(GameState.player["age"])>=int(q.get("min_age",5)) and Novelty.eligible(q): fresh_bank.append(q)
		if fresh_bank.size()<3:
			EventEngine.push_info("📚","Quiz pool complete","No fresh three-question assessment is available for this subject. Practical exercises remain available; no time was spent.")
			return
	if not _begin("school:"+subject+str(practical),"school",{"subject":subject,"practical":practical}): return
	GameState.player["education"]["studied"] = true
	if practical:
		var game := "memory" if subject=="Memory" else "evidence"
		Minigames.play(game,{"skill":Aptitude.score("education"),"title":subject+" practice","cases":_practice_cases(subject)},Callable(self,"_school_result").bind(subject))
	else:
		var bank: Array=[]
		while bank.size()<3:
			var q: Dictionary=Novelty.prefer(fresh_bank).pick_random()
			fresh_bank.erase(q); bank.append(q)
			Novelty.note(q)
		for q in bank:
			var right: String = str(q["a"][int(q["correct"])])
			q["a"].shuffle()
			q["correct"]=q["a"].find(right)
		Minigames.play("school_quiz",{"skill":Aptitude.score("education"),"bank":bank,"needed":3,"title":subject+" quiz","graded":true},Callable(self,"_school_result").bind(subject))

func _school_result(score: float, _detail: Dictionary, subject: String) -> void:
	if str(state()["active"].get("kind",""))!="school" or str(state()["active"].get("subject",""))!=subject: return
	Lifestyle.note("library")
	state()["active"]={}
	var mastery: float = float(state()["subjects"].get(subject,0))
	var gain := clampf(score,0,1)*4.0*(1.0-mastery/160.0)
	state()["subjects"][subject]=clampf(mastery+gain,0,100)
	GameState.apply_effects({"school":gain,"smarts":score*0.5,"stress":2,"happiness":2 if score>=0.7 else -1})
	GameState.add_log("I completed %s practice: %d%%. My grade improved by %.1f points." % [subject,int(score*100),gain])
	EventEngine.push_info("📚",subject+" results","%d%% · grade +%.1f · subject mastery %.1f. Practice helps; it does not replace the annual assessment." % [int(score*100),gain,float(state()["subjects"][subject])])
	GameState.emit_changed()

func job_tasks() -> Array:
	return jobs.get(str(GameState.player.get("job",{}).get("id","")),[])

func job_pool() -> Array:
	var jid := str(GameState.player.get("job",{}).get("id",""))
	var field := str(GameState.player.get("job",{}).get("field",""))
	var pool: Array=career_cases.filter(func(c): return str(c["job"])==jid or (str(c["job"])=="*" and str(c.get("field",""))==field))
	var tasks := job_tasks()
	for i in range(tasks.size()):
		var task: Dictionary=tasks[i].duplicate(true)
		task["id"]="jobtask."+jid+"."+str(i); task["family"]="jobtask."+jid
		pool.append(task)
	return pool

func unused_job_scenes() -> int:
	var count := 0
	for scene in job_pool():
		if Novelty.eligible(scene): count+=1
	return count

func job_task(index: int) -> void:
	if index<0 or index>1 or not GameState.has_job(): return
	var jid := str(GameState.player["job"]["id"])
	if not available("job:"+jid+str(index)) or not EventEngine.pending.is_empty() or EventEngine.displayed.has("def") or Journey.busy(): return
	var task := Novelty.pick(job_pool())
	if task.is_empty():
		EventEngine.push_info("💼","A routine shift","No new workplace encounter is available for this occupation. Work effort, projects and training remain available; no time was spent.")
		return
	if not _begin("job:"+jid+str(index),"job",{"job":jid,"session":Employment.job_session(),"task":task}): return
	state()["active"]["execution_roll"]=randf()
	var crew := Workplace.crew()
	state()["active"]["colleague"]=FamilyChronicle.identity(GameState.npc(str(crew[0]))) if not crew.is_empty() else ""
	Novelty.note(task)
	var choices: Array = []
	var order: Array = [0,1,2]
	order.shuffle()
	for i in order:
		var label := str(task["answers"][i])
		if task.has("approaches"):
			label += [" · more effort"," · use team support"," · accept a compromise"][i]
		choices.append(_choice(label,"job",i))
	var colleague: String=Journey.person(str(state()["active"]["colleague"]))
	_push(str(task["name"]),str(task["question"])+("\nWith "+GameState.full_name(colleague)+" · "+Bonds.quick_line(colleague) if colleague!="" else "")+"\nReadiness, skills and hours affect execution.",choices)

func routine_duty(index: int) -> void:
	var tasks := job_tasks()
	if index<0 or index>=tasks.size() or not GameState.has_job() or Employment.blocked()!="": return
	var key := "duty:"+str(Employment.job_session())+":"+str(index)
	if Employment.used(key) or not GameState.spend_time(1): return
	Employment.mark(key)
	var coaching_gain := Employment.complete_coaching(index)
	var gain := 0.4+Aptitude.score("work")/65.0+coaching_gain
	GameState.apply_effects({"job_perf":gain,"stress":2})
	var crew := Workplace.crew(); var who := str(crew[index%crew.size()]) if not crew.is_empty() else ""
	if who!="":
		BondStats.apply(who,{"respect":1}); GameState.npc(who)["happiness"]=minf(100,float(GameState.npc(who).get("happiness",60))+1)
		FamilyChronicle.remember(who,"Worked together on "+str(tasks[index]["name"])+".")
	Journey.note(str(tasks[index]["name"]),"Routine duty with "+(GameState.full_name(who) if who!="" else "the workplace")+". Performance +%.1f." % gain)
	EventEngine.push_info("🧰",str(tasks[index]["name"]),"Performance +%.1f · stress +2. No extra salary.%s" % [gain," Coaching completed: field skill +1." if coaching_gain>0.0 else ""])

func contact_outcome(active: Dictionary,answer: int,tradeoff: bool=false) -> void:
	var who: String=Journey.person(str(active.get("colleague","")))
	if who=="" or not GameState.npc(who).get("alive",false): return
	var n := GameState.npc(who)
	n["happiness"]=clampf(float(n.get("happiness",60))+(2 if tradeoff or answer==0 else -4 if answer==2 else 0),0,100)
	n["stress"]=clampf(float(n.get("stress",20))+(1 if tradeoff and answer==1 else -1 if answer==0 else 3 if answer==2 else 1),0,100)
	if not tradeoff: BondStats.apply(who,{"trust":2 if answer==0 else -3 if answer==2 else 0})
	FamilyChronicle.remember(who,str(active["task"]["name"])+": "+str(active["task"]["answers"][answer])+".","bad" if not tradeoff and answer==2 else "good")

func resolve_career_case(active: Dictionary, answer: int) -> void:
	var task: Dictionary=active["task"]
	if answer<0 or answer>=task["approaches"].size(): return
	var plan: Dictionary=task["approaches"][answer]
	var field := str(GameState.player["job"]["field"])
	var rec := Employment.record(field)
	var reputation := float(rec["reputation"])
	var chance := clampf(float(plan["chance"])+(Aptitude.score("work")-50)/200.0+mini(10,Market.skill(field))*0.008+Journey.modules["school"].career_bonus(field),0.10,0.93)
	if answer==1: chance=clampf(chance+(reputation-60)/180.0,0.10,0.93)
	if GameState.player["job"].get("work_schedule","regular")=="overtime": chance=maxf(0.10,chance-0.07)
	var success := float(active.get("execution_roll",randf()))<chance
	var perf := float(plan["performance"])*(1.0 if success else 0.2)*Aptitude.reward("work")
	var stress := float(plan["stress"])+(2 if not success else 0)
	# Team help is a professional favor, not an employee personally paying wages.
	if answer==1:
		rec["reputation"]=maxf(0,reputation-2)
		var colleague: String=Journey.person(str(active.get("colleague","")))
		if colleague!="" and GameState.npc(colleague).get("alive",false): BondStats.apply(colleague,{"trust":-2})
	GameState.apply_effects({"job_perf":perf,"stress":stress,"health":-1 if answer==0 else 0,"happiness":1 if success else -1})
	contact_outcome(active,answer,true)
	Employment.note_task(field,success)
	var review := {"id":task["id"],"name":task["name"],"choice":task["answers"][answer],"field":field,"session":active["session"],"job":active["job"],"due":GameState.year_now()+1,"success":success,"closed":false,"closure":task["closure"]}
	review["colleague"]=active.get("colleague","")
	if not state().has("work_reviews"): state()["work_reviews"]=[]
	state()["work_reviews"].append(review)
	Journey.note(str(task["name"]),str(task["answers"][answer])+". "+str(plan["success"] if success else plan["partial"]))
	EventEngine.push_info("💼",str(task["name"]),str(plan["success"] if success else plan["partial"])+"\nPerformance %+.1f · stress %+.0f. %s A review follows next year." % [perf,stress,"Extra effort cost 1 health." if answer==0 else ("Team support used 2 reputation." if answer==1 else "The compromise limited the performance gain.")])

func settle_work_reviews() -> void:
	for review in state().get("work_reviews",[]):
		if review["closed"] or GameState.year_now()<int(review["due"]): continue
		review["closed"]=true
		var rec := Employment.record(str(review["field"]))
		var change := 3.0 if review["success"] else -1.0
		rec["reputation"]=clampf(float(rec["reputation"])+change,0,100)
		var colleague: String=Journey.person(str(review.get("colleague","")))
		if colleague!="" and GameState.npc(colleague).get("alive",false): BondStats.apply(colleague,{"respect":2 if review["success"] else -1,"trust":2 if review["success"] else 0})
		var same := GameState.has_job() and str(GameState.player["job"]["id"])==str(review["job"]) and Employment.job_session()==int(review["session"])
		if same: GameState.apply_effects({"job_perf":2 if review["success"] else -1})
		Journey.note("Work review closed",str(review["name"])+" · "+str(review["choice"])+". "+str(review["closure"])+" Reputation %+.0f.%s" % [change," The experience remains in your record after leaving that job." if not same else ""])
	var reviews: Array=state().get("work_reviews",[])
	# Keep open reviews; cap only the archive.
	var closed: Array=reviews.filter(func(r): return r["closed"])
	if closed.size()>40:
		var discard := closed.slice(0,closed.size()-40)
		state()["work_reviews"]=reviews.filter(func(r): return not discard.has(r))

func martial(discipline: String, spar: bool = true) -> void:
	if not MOVES.has(discipline) or int(GameState.player.get("age",0))<6: return
	var trained: Dictionary = GameState.player.get("martial",{}).get(discipline,{})
	if trained.is_empty(): return
	if not spar and (int(trained.get("prog",0))<100 or int(trained.get("belt",0))>=Daily.BELTS.size()-1): return
	if not _begin("martial:"+discipline+str(spar),"martial",{"discipline":discipline,"spar":spar,"belt":int(trained.get("belt",0))}): return
	var belt := int(trained.get("belt",0))
	var choices: Array = []
	for i in range(mini(4,1+belt/2)):
		choices.append(_choice(str(MOVES[discipline][i]),"martial",i))
	_push("Supervised sparring" if spar else "Belt assessment","%s · %s belt. Your partner presses forward, leaving an opening but little room. Pick your trained response. This is a controlled practice bout." % [Daily.MARTIAL[discipline][1],Daily.BELTS[mini(belt,Daily.BELTS.size()-1)]],choices)

func sport() -> void:
	var career := Careers.career()
	if str(career.get("id",""))!="athlete" or str(career.get("team",""))=="" or int(career.get("injured",0))>0: return
	if not _begin("sport","sport",{"sport":career["sport"],"skill":float(career["skill"])}): return
	career["big_game_year"]=GameState.year_now()
	var seen: Array = state()["sport_seen"]
	var pool: Array = []
	for i in range(SPORT_MOMENTS.size()):
		if not seen.has(i): pool.append(i)
	if pool.is_empty():
		pool=range(SPORT_MOMENTS.size())
		pool.erase(int(seen.back()))
		seen.clear()
	var selected: int = pool.pick_random()
	seen.append(selected)
	state()["active"]["moment"]=selected
	var question: Array = SPORT_MOMENTS[selected]
	var order: Array = [0,1,2]
	order.shuffle()
	var choices: Array = []
	for i in order: choices.append(_choice(str(question[i+1]),"sport",i))
	_push("The decisive moment",str(Careers.SPORTS[career["sport"]][1])+" · "+str(question[0])+"\nChoose the plan, then execute it in the clutch challenge.",choices)

func start_claim(npc_id: String) -> void:
	var npc := GameState.npc(npc_id)
	if npc.is_empty() or not bool(npc.get("alive",false)) or int(GameState.player.get("age",0))<18: return
	if not _begin("claim:"+npc_id,"court",{"npc":npc_id,"strength":0,"cost":0},2): return
	var choices: Array = []
	for key in CLAIMS: choices.append(_choice(str(CLAIMS[key][0]),"claim_reason",key))
	choices.append(_choice("Withdraw the claim","withdraw",0))
	_push("Grounds for a civil claim","Choose the reason for your claim against %s. This creates a fictional disputed case; you must establish facts and loss, rather than collect a guaranteed payout." % GameState.full_name(npc_id),choices)

func _court_round() -> void:
	var active: Dictionary = state()["active"]
	var round_no := int(active["round"])
	var reason: Array = CLAIMS[str(active["reason"])]
	var question: Array
	if round_no==0:
		question=["Disclosure: what do you submit?",str(reason[1]),"A rumour about their character","An edited record with missing context"]
	elif round_no==1:
		question=["Cross-examination: "+str(reason[2]),"Explain what the records show and acknowledge their limits","Attack their personality","Invent a witness"]
	else:
		question=["Closing argument: how do you justify damages?","Connect the proven loss to the requested compensation","Demand their entire fortune","Repeat how angry you feel"]
	var order: Array = [0,1,2]
	order.shuffle()
	var choices: Array = []
	for i in order: choices.append(_choice(str(question[i+1]),"court_answer",i))
	choices.append(_choice("Withdraw; costs already spent remain paid","withdraw",0))
	_push("Civil trial · stage %d / 3" % [round_no+1],str(question[0])+"\nCase strength %d · evidence is disputed, and the outcome is uncertain." % int(active["strength"]),choices)

func outcome(data: Dictionary) -> void:
	var active: Dictionary = state()["active"]
	if active.is_empty() or int(data.get("token",-1))!=int(active["token"]) or int(data.get("round",-1))!=int(active["step"]): return
	var op := str(data.get("op",""))
	var value: Variant = data.get("value",0)
	active.erase("prompt")
	active["step"]=int(active["step"])+1
	active["round"]=int(active["round"])+1
	match op:
		"murder": _murder_outcome(int(value),str(active.get("npc","")))
		"school_choice", "platform", "council_budget", "club_plan", "clique_plan": school_outcome(op,int(value))
		"withdraw":
			state()["active"]={}
			GameState.add_log("I withdrew my civil claim. Costs already paid were not refunded.")
		"job":
			var jid := str(active["job"])
			state()["active"]={}
			if str(GameState.player.get("job",{}).get("id",""))!=jid: return
			if int(active.get("session",Employment.job_session()))!=Employment.job_session(): return
			if active["task"].has("approaches"):
				resolve_career_case(active,int(value))
				return
			var readiness := Aptitude.score("work")
			var correct := int(value)==0
			Employment.note_task(str(GameState.player["job"]["field"]),correct)
			var gain := (2.0+readiness/25.0) if correct else (-4.0 if int(value)==2 else 0.5)
			GameState.apply_effects({"job_perf":gain,"stress":2,"happiness":2 if correct else -2})
			contact_outcome(active,int(value))
			var task: Dictionary = active["task"]
			GameState.add_log("At work I completed %s. %s" % [task["name"],task["feedback"]])
			EventEngine.push_info("💼",str(task["name"]),str(task["feedback"])+"\nWork performance %+.1f. Salary and promotion still follow your employment terms." % gain)
		"martial":
			var discipline := str(active["discipline"])
			var belt := int(active["belt"])
			var skill := clampf(25+float(belt)*6+Aptitude.score("physical")*0.25+(8 if int(value)>=2 else 0),0,100)
			Minigames.play("fight",{"skill":skill,"difficulty":1.15,"style":discipline,"move":int(value),"title":"%s · %s" % [Daily.MARTIAL[discipline][1],MOVES[discipline][int(value)]]},Callable(self,"_martial_result").bind(discipline,bool(active["spar"])))
		"sport":
			active["strategy"]=int(value)
			var skill := float(active["skill"])+(12 if int(value)==0 else (-15 if int(value)==2 else -4))
			Minigames.play("clutch",{"skill":skill,"sport":active["sport"],"difficulty":1.05,"title":"Execute your late-game plan"},Callable(self,"_sport_result"))
		"claim_reason":
			if not CLAIMS.has(str(value)): return
			active["reason"]=str(value)
			active["round"]=0
			active["strength"]=randi_range(12,28)
			var choices: Array = []
			for tier in range(3):
				var fee := 0 if tier==0 else Law._lawyer_cost(tier)/2
				var choice := _choice(["Represent yourself","Retain a lawyer","Retain a specialist firm"][tier]+" · "+GameState.fmt_money(fee),"claim_lawyer",tier)
				choice["requires"]={"money":fee}
				choices.append(choice)
			choices.append(_choice("Withdraw","withdraw",0))
			_push("Choose representation","Your claim concerns %s. Lawyers help organise a case; they do not replace evidence." % CLAIMS[str(value)][0],choices)
		"claim_lawyer":
			var tier := clampi(int(value),0,2)
			var fee := 0 if tier==0 else Law._lawyer_cost(tier)/2
			if int(GameState.player["money"])<fee: return
			GameState.player["money"]-=fee
			active["cost"]=fee
			active["strength"]=int(active["strength"])+tier*8
			active["round"]=0
			_court_round()
		"court_answer":
			active["strength"]=int(active["strength"])+(18 if int(value)==0 else (-14 if int(value)==2 else -5))
			if int(active["round"])<3: _court_round()
			else: _court_verdict()

func _martial_result(score: float, _detail: Dictionary, discipline: String, spar: bool) -> void:
	if str(state()["active"].get("kind",""))!="martial": return
	Lifestyle.note("gym")
	state()["active"]={}
	var trained: Dictionary = GameState.player.get("martial",{}).get(discipline,{})
	if trained.is_empty(): return
	var progress := int(trained.get("prog",0))
	if spar:
		trained["prog"]=mini(100,progress+int(score*12))
	elif progress>=100 and score>=0.65 and int(trained.get("belt",0))<Daily.BELTS.size()-1:
		trained["belt"]=int(trained["belt"])+1
		trained["prog"]=0
		GameState.counter("belts_earned")
		if int(trained["belt"])==7: GameState.add_milestone(int(GameState.player["age"]),"earned a black belt in "+str(Daily.MARTIAL[discipline][1]))
	GameState.apply_effects({"health":-2 if score<0.35 else 1,"stress":-2,"happiness":3 if score>=0.65 else -1})
	EventEngine.push_info("🥋","Practice result","%d%% · %s belt · %d%% ready for assessment. Belts require a passing assessment after training." % [int(score*100),Daily.BELTS[int(trained["belt"])],int(trained["prog"])])
	GameState.emit_changed()

func _sport_result(score: float, detail: Dictionary) -> void:
	if str(state()["active"].get("kind",""))!="sport": return
	var strategy := int(state()["active"].get("strategy",1))
	state()["active"]={}
	# Execution dominates; strategy, preparation, fatigue and variance also count.
	var career := Careers.career()
	if str(career.get("id",""))!="athlete": return
	Lifestyle.note("gym")
	var result := clampf(score*0.65+float(career["skill"])*0.0015+Aptitude.score("physical")*0.001+(0.08 if strategy==0 else -0.05)+randf_range(-0.05,0.05),0,1)
	Careers.resolve_play(result,detail,{"kind":"big_game"})

func _court_verdict() -> void:
	var active: Dictionary = state()["active"].duplicate(true)
	state()["active"]={}
	var npc_id := str(active["npc"])
	var npc := GameState.npc(npc_id)
	if npc.is_empty(): return
	var chance := clampf(float(active["strength"])/110.0+(Aptitude.score("technical")-50)/500.0,0.05,0.9)
	var won := randf()<chance
	var damages := clampi(int(npc.get("money",5000)*0.20),500,50000)
	var cash := damages if won else -mini(1500,maxi(0,int(GameState.player["money"])))
	GameState.apply_effects({"money":cash,"happiness":6 if won else -5,"stress":4})
	npc["closeness"]=maxf(0,float(npc.get("closeness",50))-30)
	var record := {"reason":active["reason"],"npc":npc_id,"won":won,"age":GameState.player["age"],"strength":active["strength"],"cost":active["cost"],"damages":damages if won else 0}
	(state()["claims"] as Array).append(record)
	GameState.add_log("My civil claim for %s was %s. Net result after representation: %s." % [CLAIMS[str(active["reason"])][0],"upheld" if won else "dismissed",GameState.fmt_money(cash-int(active["cost"]))])
	EventEngine.push_info("⚖️","Civil verdict","%s · final case strength %d · %d%% chance. %s\nRepresentation already cost %s. The trial outcome and costs are saved in your case history." % ["Claim upheld" if won else "Claim dismissed",int(active["strength"]),int(chance*100),"Award "+GameState.fmt_money(damages) if won else "Court costs "+GameState.fmt_money(abs(cash)),GameState.fmt_money(int(active["cost"]))])
	GameState.emit_changed()

func expression() -> Dictionary:
	if GameState.player.is_empty(): return {"glyph":"","label":""}
	if not GameState.is_alive(): return {"glyph":"🕯️","label":"Remembered"}
	if str(GameState.player.get("illness",""))!="" or GameState.stat("health")<30: return {"glyph":"🤒","label":"Feeling unwell"}
	if GameState.stat("stress")>=75: return {"glyph":"😰","label":"Under strain"}
	if GameState.stat("happiness")<30: return {"glyph":"😔","label":"Feeling low"}
	if GameState.stat("health")<55: return {"glyph":"😴","label":"Worn out"}
	if GameState.stat("happiness")>=80: return {"glyph":"😊","label":"In good spirits"}
	return {"glyph":"😌","label":"Steady"}

func remember(def: Dictionary, index: int, roles: Dictionary = {}) -> void:
	var st := state()
	if not st.has("decisions"): st["decisions"]={}
	var key := str(def.get("id",""))+":"+str(hash(str(def.get("text",""))))+":"+str(index)
	var history: Dictionary = st["decisions"]
	var entry: Dictionary = history.get(key,{"event":EventEngine.tokens(str(def.get("title","")),roles),"choice":EventEngine.tokens(str(def["choices"][index].get("label","")),roles),"first_age":GameState.player.get("age",0),"count":0})
	entry["count"]=int(entry["count"])+1
	entry["last_age"]=GameState.player.get("age",0)
	history[key]=entry

func school_record(key: String, score: float) -> void:
	var st := state()
	if not st.has("school_history"): st["school_history"]={}
	var record: Dictionary = st["school_history"].get(key,{"attempts":0,"best":0.0,"progress":0.0,"first_age":GameState.player["age"]})
	record["attempts"]=int(record["attempts"])+1
	record["best"]=maxf(float(record["best"]),score)
	record["progress"]=minf(100,float(record["progress"])+score*10)
	record["last_age"]=GameState.player["age"]
	st["school_history"][key]=record

func school_bonus(career: String) -> float:
	var keys: Array = {"politician":["president","club:council","club:debate"],"athlete":["sport"],"musician":["talent:music","club:band"],"actor":["talent:acting","club:drama"],"director":["club:art","club:yearbook"],"astronaut":["club:science","club:robotics"]}.get(career,[])
	var score := 0.0
	for key in keys: score+=float(state().get("school_history",{}).get(key,{}).get("progress",0))*0.1
	return minf(12,score)

func work_portfolio_bonus() -> float:
	var progress := 0.0
	for entry in state().get("school_history",{}).values(): progress+=float(entry.get("progress",0))
	return minf(0.05,progress/2000.0)

func school_menu() -> Dictionary:
	var rows: Array = []
	var ss := Daily._ss()
	rows.append(Journey.nav("seasons","Teams & seasons","Selection, three fixtures and preparation"))
	rows.append(Journey.nav("school","Club work record","Named collaborators and decisions","clubs"))
	var enabled := GameState.in_school() or GameState.in_university()
	rows.append({"icon":"📚","name":"School portfolio","sub":"Participation builds future skills; joining alone gives no career bonus.","on":false})
	if str(ss["clique"])!="":
		rows.append(_school_row("👥","Clique gathering","Choose how to handle peer pressure and belonging","clique",str(ss["clique"]),enabled))
	for club in ss["clubs"]:
		rows.append(_school_row("🏫",Daily._club_name(str(club))+" project","Play a challenge and build a contribution record","club",str(club),enabled))
	if str(ss["sport"])!="":
		rows.append(_school_row("🏆","School team fixture","Choose the tactic, then play the decisive moment","school_sport",str(ss["sport"]),enabled))
	for talent in [["music","🎸","Music · rhythm"],["acting","🎭","Acting · audition"],["dance","💃","Dance · sequence"]]:
		rows.append(_school_row(talent[1],"Talent show: "+talent[2],"One entry per year; preparation and execution affect your result","talent",talent[0],enabled))
	rows.append(_school_row("🗳️","Campaign for class president","Platform, debate, election and a school budget","president","",enabled and int(GameState.player["age"])>=13))
	if int(state().get("president_year",-1))==GameState.year_now():
		rows.append(_school_row("🏛️","Chair the student council","Fund a project and account for its outcome","council","",enabled))
	for key in state().get("school_history",{}):
		var h: Dictionary = state()["school_history"][key]
		rows.append({"icon":"📁","name":str(key).replace(":"," · ").capitalize(),"sub":"%d activities · progress %d · best result %d%%" % [int(h["attempts"]),int(h["progress"]),int(float(h["best"])*100)],"on":false})
	return {"icon":"🏫","title":"School challenges & portfolio","rows":rows}

func _school_row(icon: String, title: String, sub: String, mode: String, id: String, enabled: bool) -> Dictionary:
	var key := "school_activity:"+mode if mode in ["president","talent"] else "school_activity:"+mode+id
	return {"icon":icon,"name":title,"sub":sub+" · 1 time","act":"daily:depth","arg":[mode,id],"on":enabled and available(key)}

func school_activity(mode: String, id: String) -> void:
	if not GameState.in_school() and not GameState.in_university(): return
	if mode not in ["club","clique","school_sport","president","council","talent"]: return
	if mode=="club" and not club_work.GAMES.has(id): return
	if mode=="club" and int(GameState.player["age"])<Daily.club_age(id): return
	if mode=="clique" and not Daily.CLIQUES.has(id): return
	var ss := Daily._ss()
	if mode=="club" and not ss["clubs"].has(id): return
	if mode=="clique" and str(ss["clique"])!=id: return
	if mode=="school_sport" and str(ss["sport"])!=id: return
	if mode=="president" and (int(GameState.player["age"])<13 or not GameState.in_school()): return
	if mode=="council" and int(state().get("president_year",-1))!=GameState.year_now(): return
	var key := "school_activity:"+mode if mode in ["president","talent"] else "school_activity:"+mode+id
	if not _begin(key,"school_activity",{"mode":mode,"id":id}): return
	if mode=="clique":
		clique_life.start(id)
	elif mode=="president":
		state()["active"]["priority"]=randi_range(0,2)
		_push("Class election · choose your platform","The student survey prioritises "+["fair access to clubs","a better study space","a well-run school event"][int(state()["active"]["priority"])]+". Pick a promise you can deliver with the limited budget.",[_choice("Make clubs more accessible","platform",0),_choice("Improve the study space","platform",1),_choice("Organise a school event","platform",2),_choice("Promise all three without a cost plan","platform",3)])
	elif mode=="council":
		_push("Council meeting · 100 budget points","You can afford one complete project this term. Your campaign promise was "+["club access","study space","a school event","everything"][int(state().get("platform",0))]+". Which project receives the budget?",[_choice("Club access · 100 points","council_budget",0),_choice("Study space · 100 points","council_budget",1),_choice("School event · 100 points","council_budget",2),_choice("Spread it so thin that nothing is completed","council_budget",3)])
	elif mode=="school_sport":
		_push("School fixture · the final moment","Your team is tiring, but a prepared second option is available. Choose a plan before the decisive challenge.",[_choice("Use the prepared team option","school_choice",0),_choice("Force a personal highlight","school_choice",1),_choice("Ignore the team's call","school_choice",2)])
	elif mode=="club": club_work.start(id)
	else:
		var game: String = {"chess":"evidence","drama":"audition","robotics":"docking","debate":"debate","art":"onset","band":"rhythm","council":"debate","yearbook":"onset","science":"evidence","volunteer":"debate","music":"rhythm","acting":"audition","dance":"memory"}.get(id,"evidence")
		Minigames.play(game,{"skill":Aptitude.score("creative" if mode=="talent" else "education")+float(GameState.player.get("talent_voice",0))*2,"title":Daily._club_name(id)+" project" if mode=="club" else "School talent show","cases":_practice_cases("Chess" if id=="chess" else "Science")},Callable(self,"_school_activity_result"))

func school_outcome(op: String, value: int) -> void:
	var active: Dictionary = state()["active"]
	if active.get("kind","")!="school_activity": return
	var mode := str(active.get("mode",""))
	if op=="club_plan": club_work.plan(value)
	elif op=="clique_plan": clique_life.finish(value)
	elif op=="platform":
		active["platform"]=value
		active["strategy"]=1 if value==3 else (0 if value==int(active["priority"]) else 2)
		Minigames.play("debate",{"skill":Aptitude.score("social")+(10 if int(active["strategy"])==0 else -10),"title":"Class election debate"},Callable(self,"_school_activity_result"))
	elif op=="council_budget":
		var kept := value<3 and value==int(state().get("platform",0))
		state()["active"]={}
		school_record("president",1.0 if kept else 0.3)
		Daily._ss()["popularity"]=clampf(float(Daily._ss()["popularity"])+(6 if kept else -5),0,100)
		GameState.apply_effects({"smarts":1,"happiness":3 if kept else -2,"stress":2})
		EventEngine.push_info("🏛️","Council accountability","Your funded project was completed and recorded." if value<3 else "No complete project was delivered. Your classmates noticed the gap between promises and results.")
	elif mode=="clique":
		var id := str(active["id"])
		state()["active"]={}
		school_record("clique:"+id,1.0 if value==0 else (0.3 if value==1 else 0.1))
		Daily._ss()["popularity"]=clampf(float(Daily._ss()["popularity"])+(3 if value==0 else -2),0,100)
		GameState.apply_effects({"happiness":3 if value==0 else -2,"karma":2 if value==0 else -3})
		if value==0 and GameState.npcs_with("classmate").size()>0: GameState.change_closeness(str(GameState.npcs_with("classmate").pick_random()),5)
		EventEngine.push_info("👥","Clique gathering","Your approach changed belonging and was recorded in your school history.")
	elif mode=="school_sport":
		active["strategy"]=value
		Minigames.play("clutch",{"skill":Aptitude.score("physical")+(10 if value==0 else -8),"sport":active["id"],"title":"School fixture"},Callable(self,"_school_activity_result"))

func _school_activity_result(score: float, _detail: Dictionary) -> void:
	var active: Dictionary = state()["active"].duplicate(true)
	if str(active.get("kind",""))!="school_activity": return
	state()["active"]={}
	var mode := str(active["mode"])
	var id := str(active["id"])
	var ss := Daily._ss()
	if mode=="president":
		var result := clampf(score*0.5+float(ss["popularity"])/250.0+(0.15 if int(active["strategy"])==0 else -0.05)+randf_range(-0.05,0.05),0,1)
		var won := result>=0.6
		school_record("president",result)
		if won:
			state()["president_year"]=GameState.year_now()
			state()["platform"]=int(active["platform"])
			GameState.set_flag("class_president")
			GameState.add_milestone(int(GameState.player["age"]),"was elected class president")
		EventEngine.push_info("🗳️","Class election","You won. Chair the student council to put your platform into practice." if won else "You lost. Your debate and campaign experience still contribute to future political preparation.")
	else:
		if mode=="club": score=club_work.finish(active,score)
		var history_key := "sport" if mode=="school_sport" else mode+":"+id
		school_record(history_key,score)
		ss["popularity"]=clampf(float(ss["popularity"])+(4 if score>=0.7 else -1),0,100)
		GameState.apply_effects({"happiness":5 if score>=0.7 else 1,"stress":2,"school":score if mode=="club" else 0})
		if mode=="talent" and score>=0.85: GameState.counter("talent_wins")
		if mode=="school_sport" and score>=0.85: GameState.counter("school_titles")
		if mode=="school_sport" and float(state()["school_history"]["sport"]["progress"])>=35 and float(ss["popularity"])>=60 and not ss["captain"]:
			ss["captain"]=true
			GameState.counter("captain")
		EventEngine.push_info("🏫","School challenge","%d%% · saved in your school portfolio. " % int(score*100)+str(active.get("club_summary","These skills can help a relevant career later.")))
	GameState.emit_changed()

func yearly() -> void:
	var st := state()
	if int(GameState.player.get("age",0))<18 or st.get("school_echo",false): return
	st["school_echo"]=true
	var history: Dictionary = st.get("school_history",{})
	if history.is_empty(): return
	var choices: Array = []
	if school_bonus("politician")>0: choices.append({"label":"Use my council experience in a community campaign","outcomes":[{"text":"My school campaign experience helped me take a first step into community work.","effects":{"smarts":1,"karma":2},"flags":["school_community_contact"]}]})
	if school_bonus("athlete")>0: choices.append({"label":"Ask my former coach about adult training","outcomes":[{"text":"My school team history opened a conversation with a coach.","effects":{"health":2},"flags":["school_coach_contact"]}]})
	choices.append({"label":"Keep the portfolio and explore other paths","outcomes":[{"text":"My school history stayed with me, without deciding my whole future.","effects":{"happiness":2}}]})
	EventEngine.push_decision({"id":"_school_portfolio","icon":"📁","title":"What school left me","text":"Your earlier participation gives you these follow-up choices. Relevant careers also read your accumulated practice; a missed club never locks out an entire adult career.","choices":choices})

func murder(npc_id: String) -> void:
	var npc := GameState.npc(npc_id)
	if npc.is_empty() or not bool(npc.get("alive",false)) or str(npc.get("species","human"))!="human" or int(npc.get("age",0))<18 or int(GameState.player.get("age",0))<18 or GameState.in_prison(): return
	if not _begin("murder","crime",{"npc":npc_id},2): return
	_push("A fatal decision","This fictional action attempts to murder %s. It can cause a death, grief, arrest and a long prison sentence. It offers no money or special reward. No method is depicted." % GameState.full_name(npc_id),[_choice("Walk away","murder",0),_choice("Attempt the crime","murder",1)])

func _murder_outcome(value: int, npc_id: String) -> void:
	state()["active"]={}
	if value!=1:
		GameState.add_log("I walked away from a fatal decision.")
		return
	var npc := GameState.npc(npc_id)
	if npc.is_empty() or not bool(npc.get("alive",false)): return
	GameState.counter("crimes")
	GameState.apply_effects({"karma":-40,"heat":45,"stress":20,"happiness":-10})
	var fatal := randf()<0.55
	if fatal:
		var before := int(GameState.player["money"])
		EventEngine._npc_died(npc_id)
		GameState.player["money"]=before
		npc["death_cause"]="murder"
		GameState.add_log("My crime caused %s's death. The absence and consequences remain." % str(npc["first"]))
	else:
		GameState.change_closeness(npc_id,-70)
		GameState.add_log("My attempted crime failed. The relationship was shattered.")
	if randf()<0.8: Law.trial("murder" if fatal else "attempted murder",15 if fatal else 7,35 if fatal else 20)
	else: EventEngine.push_info("🥷","Crime aftermath","No immediate arrest. Heat and the consequences of the attempt remain.")
	GameState.emit_changed()

func _practice_cases(subject: String) -> Array:
	if subject=="Chess": return [
		["Which piece can move in an L shape?",["Knight","Bishop","Rook"],0],
		["Your king is in check. What must your next move accomplish?",["Remove the check","Capture any pawn","Make a random attack"],0],
		["Why develop pieces early?",["To improve activity and options","To move the queen every turn","To ignore king safety"],0],
		["A piece is undefended and attacked. What should you assess?",["Whether it can be protected or moved safely","Only the prettiest square","Whether the clock looks nice"],0],
		["Why check the opponent's reply before a move?",["They can have threats and counterplay","They cannot respond","Your first plan is always best"],0],
		["Which piece normally moves diagonally?",["Bishop","Rook","Knight"],0],
		["What is checkmate?",["A checked king with no legal escape","Any captured pawn","A draw by agreement"],0]]
	var rows: Array = []
	for q in lessons.get(subject,lessons["Science"]): rows.append([q["q"],q["a"].slice(0,3),q["correct"]])
	return rows

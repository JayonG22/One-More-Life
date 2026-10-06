extends Node

## Optional authored encounters are consumed once per person. Shared local
## history prioritizes unseen stories across lives without changing a saved prompt.
const SHARED_RECENT_LIMIT := 64
const SHARED_EVENT_COOLDOWN := 18
const SHARED_FAMILY_COOLDOWN := 4


func _shared_history() -> Dictionary:
	var raw = Meta.meta.get("scene_history", {})
	if not (raw is Dictionary):
		raw = {}
		Meta.meta["scene_history"] = raw
	var shared: Dictionary = raw
	Meta.meta["scene_history"] = shared
	# Check the stored value, not a default: shared.get(key, {}) hands back the
	# default for a missing key, which passes the type test, so the key was never
	# actually created and every later shared["texts"] / ["recent"] read failed.
	for key in ["texts", "families"]:
		if not (shared.get(key) is Dictionary):
			shared[key] = {}
	if not (shared.get("recent") is Array):
		shared["recent"] = []
	return shared


func state() -> Dictionary:
	var p := GameState.player
	if not p.has("novelty") or not p["novelty"] is Dictionary:
		p["novelty"]={"ids":{},"texts":{},"families":{}}
	for key in ["ids","texts","families"]:
		if not p["novelty"].has(key): p["novelty"][key]={}
	return p["novelty"]

func fingerprint(scene: Dictionary) -> String:
	var text := str(scene.get("text",scene.get("question",scene.get("q","")))).strip_edges().to_lower()
	if text == "":
		text = str(scene.get("title", scene.get("name", scene.get("id", "")))).strip_edges().to_lower()
	return text.sha256_text()

func eligible(scene: Dictionary) -> bool:
	var id := str(scene.get("id",""))
	if id=="": return false
	var s := state()
	if s["ids"].has(id) or s["texts"].has(fingerprint(scene)): return false
	# Existing saves already carry shown-event counts and life-course history.
	if GameState.player.get("director",{}).get("seen",{}).has(id): return false
	if GameState.player.get("life_course",{}).get("seen",{}).has(id): return false
	return true

func familiarity(scene: Dictionary) -> int:
	var global := _shared_history()
	var texts: Dictionary = global["texts"]
	var families: Dictionary = global["families"]
	return int(texts.get(fingerprint(scene),0))*100+int(families.get(str(scene.get("family",scene.get("id",""))),0))


func _in_recent_window(scene: Dictionary, recent: Array, count: int, include_family: bool) -> bool:
	var start := maxi(0, recent.size() - count)
	var id := str(scene.get("id", ""))
	var text := fingerprint(scene)
	var family := str(scene.get("family", id))
	for i in range(start, recent.size()):
		var prior = recent[i]
		if not (prior is Dictionary):
			continue
		if (id != "" and str(prior.get("id", "")) == id) or str(prior.get("text", "")) == text:
			return true
		if include_family and family != "" and str(prior.get("family", "")) == family:
			return true
	return false


func _recent_candidate(scene: Dictionary, recent: Array) -> bool:
	var scene_recent := _in_recent_window(scene, recent, SHARED_EVENT_COOLDOWN, false)
	var family_recent := _in_recent_window(scene, recent, SHARED_FAMILY_COOLDOWN, true)
	return not scene_recent and not family_recent


func prefer(pool: Array) -> Array:
	if pool.is_empty(): return []
	# A new save slot shares a small rolling cooldown with other lives. Prefer
	# fresh authored scenes where possible; when a pool is exhausted, fall back
	# gracefully instead of hiding required content or showing an empty card.
	var recent: Array = _shared_history()["recent"]
	var fresh: Array = pool.filter(func(scene): return _recent_candidate(scene, recent))
	if not fresh.is_empty():
		pool = fresh
	else:
		var unseen_text: Array = pool.filter(func(scene): return not _in_recent_window(scene, recent, SHARED_EVENT_COOLDOWN, false))
		if not unseen_text.is_empty():
			pool = unseen_text
	var lowest := 2147483647
	for scene in pool: lowest=mini(lowest,familiarity(scene))
	return pool.filter(func(scene): return familiarity(scene)==lowest)

func pick(pool: Array) -> Dictionary:
	var fresh := prefer(pool.filter(func(scene): return eligible(scene)))
	return {} if fresh.is_empty() else fresh.pick_random().duplicate(true)

func note(scene: Dictionary) -> void:
	var id := str(scene.get("id",""))
	if id=="": return
	var s := state()
	if s["ids"].has(id): return
	var text := fingerprint(scene)
	var family := str(scene.get("family",id))
	s["ids"][id]=true; s["texts"][text]=true
	s["families"][family]=int(s["families"].get(family,0))+1
	var shared := _shared_history()
	shared["texts"][text]=int(shared["texts"].get(text,0))+1
	shared["families"][family]=int(shared["families"].get(family,0))+1
	var recent: Array = shared["recent"]
	recent.append({"id":id,"text":text,"family":family})
	while recent.size() > SHARED_RECENT_LIMIT:
		recent.remove_at(0)
	Meta.save()

func optional(def: Dictionary) -> bool:
	var id := str(def.get("id",""))
	return id!="" and not id.begins_with("_") and not id.begins_with("arc.") and not def.get("followup_only",false) and not def.get("critical",false) and not def.get("twist",false)


func story_outcome(spec: Dictionary) -> void:
	var s := state()
	if not s.has("stories"): s["stories"]={}
	var id := str(spec["id"])
	var prior: Dictionary=s["stories"].get(id,{})
	if prior.get("state","")=="closed": return
	if spec["state"]=="open":
		if not prior.is_empty(): return
		var record: Dictionary=spec.duplicate(true)
		record["due"]=GameState.year_now()+int(spec["due"])
		record["started"]=GameState.year_now()
		s["stories"][id]=record
		Journey.note(str(spec["title"]),str(spec["choice"])+". A conclusion is due next year.")
	else:
		if prior.is_empty(): return
		prior["state"]="closed"; prior["ended"]=GameState.year_now()
		GameState.apply_effects(spec.get("effects",{}))
		if str(spec.get("field","General"))!="General": Market.learn(str(spec["field"]),1)
		Journey.note(str(spec["title"])+" · concluded",str(spec["ending"])+" Choice: "+str(spec["choice"]))

func story_journal() -> Array:
	var out: Array=[]
	for record in state().get("stories",{}).values():
		out.append(str(record["title"])+" · "+str(record["state"])+" · "+str(record["choice"])+(" · "+str(record["ending"]) if record["state"]=="closed" else " · conclusion due "+str(record["due"])))
	return out

func background(npc: Dictionary, year: int) -> void:
	var saved: Dictionary=npc.get("playable_player",{})
	if saved.is_empty() or not npc.get("alive",false): return
	for record in saved.get("novelty",{}).get("stories",{}).values():
		if record["state"]!="open" or year<int(record["due"]): continue
		record["state"]="closed"; record["ended"]=year
		for key in record["effects"]:
			var delta := float(record["effects"][key])
			if saved.get("stats",{}).has(key):
				saved["stats"][key]=clampf(float(saved["stats"][key])+delta,0,100)
				if npc.has(key): npc[key]=saved["stats"][key]
			elif key=="money":
				npc["money"]=int(npc.get("money",0))+int(delta); saved["money"]=npc["money"]
			elif key=="school":
				saved["education"]["performance"]=clampf(float(saved["education"]["performance"])+delta,0,100)
				npc["education"]=saved["education"].duplicate(true)
		var field := str(record["field"])
		if field!="General":
			if not saved.has("professional_skills"): saved["professional_skills"]={}
			saved["professional_skills"][field]=mini(10,int(saved["professional_skills"].get(field,0))+1)
			npc["professional_skills"]=saved["professional_skills"].duplicate(true)
		var journal: Array=saved.get("journey",{}).get("journal",[])
		journal.push_front({"year":year,"title":str(record["title"])+" · concluded","text":str(record["ending"])+" Choice: "+str(record["choice"])})
		if journal.size()>80: journal.resize(80)
		if saved.has("journey"): saved["journey"]["journal"]=journal
		var story: Dictionary=npc.get("personal_story",{})
		story["followups"]=story.get("followups",[]).filter(func(f): return not str(f["event"]).begins_with(str(record["id"])+".end."))
	for history in saved.get("employment",{}).get("history",[]):
		if int(history.get("audit_due",-1))<=0 or history.get("audited",false) or year<int(history["audit_due"]): continue
		history["audited"]=true
		npc["money"]=int(npc.get("money",0))-int(history["bonus"]); saved["money"]=npc["money"]
		var professional: Dictionary=saved.get("employment",{}).get("records",{}).get(str(history["field"]),{})
		if not professional.is_empty(): professional["reputation"]=maxf(0,float(professional["reputation"])-10)
		var post: Dictionary=saved.get("job",{})
		if str(post.get("id",""))==str(history.get("job","")) and int(post.get("work_session",-2))==int(history.get("session",-1)):
			post["perf"]=maxf(0,float(post.get("perf",50))-8)
			if npc.has("job"): npc["job"]["perf"]=post["perf"]
	for review in saved.get("depth",{}).get("work_reviews",[]):
		if review["closed"] or year<int(review["due"]): continue
		review["closed"]=true
		var rec: Dictionary=saved.get("employment",{}).get("records",{}).get(str(review["field"]),{})
		if not rec.is_empty(): rec["reputation"]=clampf(float(rec["reputation"])+(3 if review["success"] else -1),0,100)
		var work: Dictionary=saved.get("job",{})
		if str(work.get("id",""))==str(review["job"]) and int(work.get("work_session",-1))==int(review["session"]):
			work["perf"]=clampf(float(work.get("perf",50))+(2 if review["success"] else -1),0,100)
			npc["job"]["perf"]=work["perf"]

func close_person(p: Dictionary, reason: String) -> void:
	for record in p.get("novelty",{}).get("stories",{}).values():
		if record["state"]!="open": continue
		record["state"]="closed"; record["ended"]=GameState.year_now()
		record["ending"]="The planned conclusion did not occur: "+reason+". No completion reward was awarded."
	for review in p.get("depth",{}).get("work_reviews",[]):
		if not review["closed"]: review["closed"]=true; review["closure"]=reason

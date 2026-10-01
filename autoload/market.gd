extends Node

## JOB MARKET — openings that are somebody's openings.
##
## The old list was a shuffled sample of job templates: "Mechanic", "Teacher",
## one salary each, and an interview that was the same coin-flip with different
## wording. Nobody was hiring you; a category was.
##
## Now each year's openings are specific — a named employer, a salary somewhere
## inside a band, a number of other applicants, a number of years of experience
## they want, a boss and a culture you will find out about once you are in the
## building. Getting hired takes a screening, an interview and an offer you can
## negotiate, and every rejection teaches you a little about the next one.

const CO_A := ["Halden", "Brightwell", "Corvin", "Ashby", "Northfield", "Lumen", "Kestrel", "Marlow", "Pryor", "Tandem", "Greaves", "Fairlight", "Oakhurst", "Vantage", "Penrose", "Holloway", "Sterling", "Quill", "Redgrave", "Meridian", "Thornton", "Cobalt", "Alder"]
const CO_B := ["& Sons", "Partners", "Group", "Holdings", "Systems", "Services", "Co.", "Logistics", "Works", "Associates", "Foods", "Health", "Labs", "Media", "Motors", "Supply"]
const BOSSES := {
	"supportive": {"name": "Supportive", "desc": "Remembers your birthday and your targets."},
	"micromanager": {"name": "Micromanager", "desc": "Wants to be copied in on the thing you are already doing."},
	"absent": {"name": "Hands-off", "desc": "Hard to find, which is both a freedom and a risk."},
	"brilliant": {"name": "Brilliant", "desc": "You will learn a lot and feel stupid while you do."},
	"political": {"name": "Political", "desc": "Plays favourites, and you can tell who they are."},
}
const CULTURES := {
	"friendly": {"name": "Friendly", "desc": "Lunch together, gossip, and a card for every occasion."},
	"cutthroat": {"name": "Cutthroat", "desc": "Results, rankings and a leaderboard in the kitchen."},
	"sleepy": {"name": "Sleepy", "desc": "Nothing has changed since 1998, including the carpet."},
	"chaotic": {"name": "Chaotic", "desc": "Every week is a reorganisation and every reorganisation is urgent."},
}
const PERKS := ["a pension match", "free lunches", "a company car", "a cycle-to-work scheme", "extra holiday", "private health cover", "flexible hours", "a gym on the ground floor", "a generous bonus", "a four-day week trial", "a training budget"]
const REJECTIONS := [
	"They said I was 'a strong candidate' and then picked somebody else. It was the phrase that stung.",
	"They wanted more experience than the advert had admitted.",
	"An internal candidate got it. The job had been theirs since before it was posted.",
	"They loved me and could not meet my salary expectations, which I had not stated.",
	"No reply. A month later the job was reposted.",
	"The feedback was: 'lacked a spark.' I am still trying to find mine.",
	"The hiring manager left the company the week I applied, and the role was frozen.",
]


func _p() -> Dictionary:
	return GameState.player


func st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("market") or not (p["market"] is Dictionary):
		p["market"] = {"open": {}, "exp": {}, "rejections": 0, "interview_xp": 0.0, "refs": [], "gap": 0, "applied": {}, "offers": 0, "hired": 0}
	return p["market"]


func experience(field: String) -> int:
	return int(st().get("exp", {}).get(field, 0))


func add_experience(field: String, years: int = 1) -> void:
	var s := st()
	if s.is_empty() or field == "":
		return
	s["exp"][field] = int(s["exp"].get(field, 0)) + years


func _company(field: String = "") -> String:
	return Names.company(field, str(_p().get("country", "")))


## The year's openings for one kind of job ("part", "full", "military").
func openings(kind: String) -> Array:
	var s := st()
	if s.is_empty():
		return []
	var key := "%s_%d" % [kind, int(_p()["age"])]
	if s["open"].has(key):
		return s["open"][key]
	var out: Array = []
	var ids: Array = Actions.listings(kind)
	var i := 0
	for jid in ids:
		var jd := ContentDB.job(jid)
		if jd.is_empty():
			continue
		var base := Actions.job_salary(jd)
		var sal := int(round(float(base) * randf_range(0.86, 1.18) / 100.0)) * 100
		var exp_req := 0
		if int(jd.get("salary", 0)) >= 60000: exp_req = randi_range(2, 5)
		elif int(jd.get("salary", 0)) >= 35000: exp_req = randi_range(0, 3)
		elif int(jd.get("salary", 0)) >= 20000: exp_req = randi_range(0, 1)
		var prestige := clampf(float(jd.get("salary", 20000)) / 90000.0, 0.1, 1.0)
		var apps := int(round((8.0 + 130.0 * prestige * randf_range(0.5, 1.3)) * (1.0 + Places.unemployment() * 6.0)))
		var bk: Array = BOSSES.keys()
		var ck: Array = CULTURES.keys()
		out.append({
			"id": "%s_%d" % [key, i], "job": jid, "company": _company(str(jd.get("field", ""))), "salary": sal,
			"apps": apps, "exp": exp_req, "remote": randf() < (0.25 if Phrases.tech_level() >= 2 else 0.04),
			"perk": PERKS[randi() % PERKS.size()] if randf() < 0.55 else "",
			"boss": bk[randi() % bk.size()], "culture": ck[randi() % ck.size()], "health": randf_range(0.3, 1.0),
			"locked": Actions.job_requirement(jd),
		})
		i += 1
	s["open"].clear()
	s["open"][key] = out
	return out


func find(id: String) -> Dictionary:
	for k in st().get("open", {}).keys():
		for l in st()["open"][k]:
			if str(l["id"]) == id:
				return l
	return {}


## Your standing for one opening: a number with the reasons behind it.
func standing(l: Dictionary) -> Dictionary:
	var jd := ContentDB.job(str(l["job"]))
	var s := st()
	var lines: Array = []
	var q := 0.0
	var sm := (GameState.stat("smarts") - 50.0) / 220.0
	q += sm
	lines.append(["Smarts", sm])
	var have := experience(str(jd.get("field", "")))
	var ex := clampf(float(have - int(l["exp"])) * 0.06, -0.3, 0.15)
	q += ex
	if int(l["exp"]) > 0:
		lines.append(["Experience: %d of %d years wanted" % [have, int(l["exp"])], ex])
	var xp := minf(float(s.get("interview_xp", 0.0)), 0.12)
	q += xp
	if xp > 0.0:
		lines.append(["Interview practice", xp])
	var best_ref := 0.0
	for r in s.get("refs", []):
		best_ref = maxf(best_ref, float(r["strength"]))
	q += best_ref * 0.14
	if best_ref > 0.0:
		lines.append(["A reference you can use", best_ref * 0.14])
	var gap := clampf(float(int(s.get("gap", 0))) * 0.035, 0.0, 0.14)
	if gap > 0.0:
		q -= gap
		lines.append(["A gap of %d year%s on your CV" % [int(s["gap"]), "" if int(s["gap"]) == 1 else "s"], -gap])
	var stars := float(Wanted.stars()) * 0.07
	if stars > 0.0:
		q -= stars
		lines.append(["Your record", -stars])
	var comp := 1.0 / (1.0 + float(l["apps"]) / 45.0)
	var chance := clampf((0.50 + q) * (0.45 + 0.75 * comp), 0.03, 0.90)
	return {"chance": chance, "q": q, "lines": lines, "comp": comp}


## A plain-language reading of where you stand for one opening, and what is holding you back.
func fit_label(chance: float) -> String:
	if chance >= 0.55: return "Strong fit"
	if chance >= 0.38: return "Possible"
	if chance >= 0.24: return "Long shot"
	return "Unlikely"


## The biggest thing counting against you, as a sentence an employer would actually say.
func main_obstacle(l: Dictionary) -> Dictionary:
	var st_ := standing(l)
	var jd := ContentDB.job(str(l["job"]))
	var worst := 0.0
	var key := ""
	for ln in st_["lines"]:
		if float(ln[1]) < worst:
			worst = float(ln[1])
			key = str(ln[0])
	if key.begins_with("Experience"):
		var field := str(jd.get("field", "this field")).to_lower()
		return {"key": "exp", "short": "short on experience", "text": "They wanted %d years in %s and you have %d." % [int(l["exp"]), field, experience(str(jd.get("field", "")))], "tip": "Take a junior or part-time role in the field to build the years."}
	if key.begins_with("A gap"):
		return {"key": "gap", "short": "a gap on your CV", "text": "The gap on your CV worried them. Nobody could explain it to their satisfaction.", "tip": "Work, study or volunteer, so the next CV has no hole in it."}
	if key == "Your record":
		return {"key": "record", "short": "your record", "text": "The background check turned up your record, and that was the end of it.", "tip": "Clear your record, or look for employers who hire people with one."}
	if key == "Smarts":
		return {"key": "skills", "short": "thin skills", "text": "Your application did not show the skills they were after. Another candidate's did.", "tip": "Study, take a course, or build the skills somewhere cheaper first."}
	if int(l["apps"]) >= 120:
		return {"key": "crowd", "short": "huge competition", "text": "They had %d applicants for one post. Yours was fine; it was not the best." % int(l["apps"]), "tip": "Apply to smaller employers, or get a reference from the field."}
	if int(l["apps"]) >= 50:
		return {"key": "crowd", "short": "stiff competition", "text": "%d people applied. A candidate with direct experience got it." % int(l["apps"]), "tip": "A reference or a few more years in the field would move you up the pile."}
	return {"key": "luck", "short": "", "text": "It went to an internal candidate. The role had been theirs since before it was posted.", "tip": "Some doors were never open. Keep applying."}


func apply(id: String) -> void:
	var l := find(id)
	if l.is_empty():
		return
	var jd := ContentDB.job(str(l["job"]))
	if str(l["locked"]) != "":
		EventEngine.push_info("🔒", jd["ranks"][0], "Requirement: %s." % str(l["locked"]))
		return
	var s := st()
	if s["applied"].has(id):
		EventEngine.push_info("📨", jd["ranks"][0], "You have already applied to %s for this role." % str(l["company"]))
		return
	if Actions._out_of_time():
		return
	s["applied"][id] = true
	if bool(_p().get("golden_ticket", false)):
		_p()["golden_ticket"] = false
		GameState.add_log("I showed the golden ticket. The interview was a formality.")
		offer(id)
		return
	var st_ := standing(l)
	# screening: the CV is read against the post. A noise term stands for the reader's mood,
	# but a weak fit is a rejection, and the reason given is the real one.
	var read := float(st_["chance"]) + randf_range(-0.07, 0.07)
	if read < 0.27:
		_rejected(l, true)
		return
	_interview(l, float(st_["chance"]))


func _interview(l: Dictionary, chance: float) -> void:
	var jd := ContentDB.job(str(l["job"]))
	var q: Dictionary = ContentDB.interviews[randi() % ContentDB.interviews.size()]
	var base := clampf(chance * 1.35, 0.18, 0.85)
	if GameState.has_trait("Charmer"): base += 0.08
	if GameState.has_trait("Anxious"): base -= 0.06
	if Shop.has_any(["suit", "designer"]): base += 0.07
	var choices: Array = []
	var bar := 0.50 + randf_range(-0.07, 0.07)       # what this interviewer needs to hear
	for a in q["answers"]:
		var c := clampf(base + float(a.get("score", 0.0)), 0.05, 0.95)
		var good := c >= bar
		var why_not := "I answered “%s”, and I could see it was not what they were hoping for." % str(a["text"]).substr(0, 70)
		var ch := {"label": a["text"], "outcomes": [
			{"weight": 0.96 if good else 0.04, "text": "They asked me to come back the next day. I had the feeling it was going well.", "market": {"offer": str(l["id"])}},
			{"weight": 0.04 if good else 0.96, "text": "The interview ended a few minutes early. " + why_not, "market": {"reject": str(l["id"]), "why": why_not}},
		]}
		if a.has("trait"):
			ch["requires"] = {"trait": a["trait"]}
		choices.append(ch)
	EventEngine.push_decision({"id": "_interview", "icon": "💼", "title": "Interview at %s" % str(l["company"]), "text": "For the %s role. The interviewer leans in and asks:\n\n“%s”" % [str(jd["ranks"][0]).to_lower(), q["question"]], "choices": choices})


func outcome(ops: Dictionary) -> void:
	if ops.has("offer"):
		offer(str(ops["offer"]))
	if ops.has("reject"):
		var l := find(str(ops["reject"]))
		if not l.is_empty():
			_rejected(l, false, str(ops.get("why", "")))
	if ops.has("negotiate"):
		var nid := str(ops["negotiate"])
		var nl := find(nid)
		Minigames.play("haggle", {"subject": "your salary", "skill": GameState.stat("smarts") * 0.5 + (15.0 if GameState.has_trait("Charmer") else 0.0) + 25.0, "difficulty": 1.0},
			func(score: float, detail: Dictionary) -> void: _negotiated(nid, score, detail))
	if ops.has("hire"):
		hire(str(ops["hire"]), float(ops.get("bump", 0.0)))
	if ops.has("withdrawn"):
		GameState.add_log("The offer was withdrawn. I had pushed too hard, or they had found someone cheaper.")
		GameState.apply_effects({"happiness": -5, "stress": 4})


## The haggle is over. A good one earns a real raise; walking out loses the job
## about half the time, and the other half they hold the first offer.
func _negotiated(id: String, score: float, detail: Dictionary) -> void:
	var walked: bool = bool(detail.get("walked", false))
	if walked and not detail.get("auto", false):
		if randf() < 0.5:
			outcome({"withdrawn": true})
		else:
			GameState.add_log("I pushed too far, and they held at the first offer. I took it.")
			hire(id, 0.0)
		return
	var bump := 0.02 + 0.12 * clampf(score, 0.0, 1.0)
	if detail.get("auto", false):
		bump = 0.0 if randf() < 0.45 else randf_range(0.04, 0.10)
	hire(id, bump)


func _rejected(l: Dictionary, at_screening: bool, why: String = "") -> void:
	var s := st()
	s["rejections"] = int(s["rejections"]) + 1
	s["interview_xp"] = minf(float(s["interview_xp"]) + 0.02, 0.15)
	var jd := ContentDB.job(str(l["job"]))
	var ob := main_obstacle(l)
	var reason := why if why != "" else str(ob["text"])
	var stage := "Your CV was read, and that was as far as it went." if at_screening else "You got as far as the interview."
	var tip: String = str(ob["tip"]) if why == "" else "Think about what that question was really asking, and practise the answer."
	GameState.add_log("%s turned me down for %s. %s" % [str(l["company"]), str(jd["ranks"][0]).to_lower(), reason])
	if not s.has("history"):
		s["history"] = []
	s["history"].push_front({"age": int(_p().get("age", 0)), "co": str(l["company"]), "role": str(jd["ranks"][0]), "result": "turned down", "why": reason})
	if s["history"].size() > 14:
		s["history"].resize(14)
	EventEngine.push_info("📭", "Not this time", "%s — %s\n\n%s\n\n%s\n\n💡 %s" % [str(jd["ranks"][0]), str(l["company"]), stage, reason, tip], {"happiness": -3, "stress": 2})
	GameState.apply_effects({"happiness": -3, "stress": 2})


func offer(id: String) -> void:
	var l := find(id)
	if l.is_empty():
		return
	var jd := ContentDB.job(str(l["job"]))
	var s := st()
	s["offers"] = int(s["offers"]) + 1
	var sal := int(l["salary"])
	var hit := clampf(0.45 + GameState.stat("smarts") / 400.0 + (0.1 if GameState.has_trait("Charmer") else 0.0) - float(l["apps"]) / 600.0, 0.15, 0.8)
	var text := "%s have offered me the %s job at %s a year.%s The manager seems %s and the culture %s." % [
		str(l["company"]), str(jd["ranks"][0]).to_lower(), GameState.fmt_money(sal),
		" They throw in %s." % str(l["perk"]) if str(l["perk"]) != "" else "", str(BOSSES[str(l["boss"])]["name"]).to_lower(), str(CULTURES[str(l["culture"])]["name"]).to_lower()]
	var choices := [
		{"label": "Accept", "outcomes": [
			{"weight": 1.0, "text": "I signed. It was real.", "market": {"hire": id}}]},
		{"label": "Negotiate the salary", "outcomes": [
			{"weight": 1.0, "text": "I sat down across the table and we began.", "market": {"negotiate": id}}]},
		{"label": "Decline", "outcomes": [
			{"weight": 0.6, "text": "I thanked them and said no. It felt strange to have a choice.", "effects": {"stress": -1}},
			{"weight": 0.4, "text": "I said no, and spent the evening wondering whether I'd been mad.", "effects": {"stress": 3}}]},
	]
	EventEngine.push_decision({"id": "_offer", "icon": "🤝", "title": "An offer", "text": text, "choices": choices})


func hire(id: String, bump: float = 0.0) -> void:
	var l := find(id)
	if l.is_empty():
		return
	Actions.hire(str(l["job"]))
	var p := _p()
	if not GameState.has_job():
		return
	var j: Dictionary = p["job"]
	j["salary"] = int(round(float(l["salary"]) * (1.0 + bump) / 100.0)) * 100
	j["employer_name"] = str(l["company"])
	j["remote"] = bool(l["remote"])
	Workplace.begin(l)
	var s := st()
	s["hired"] = int(s["hired"]) + 1
	s["gap"] = 0
	s["interview_xp"] = maxf(0.0, float(s["interview_xp"]) - 0.03)
	GameState.add_log("I started at %s as %s. My boss, %s, was %s." % [str(l["company"]), str(j["title"]).to_lower(), GameState.full_name(str(j.get("boss", ""))) if GameState.npcs.has(str(j.get("boss", ""))) else "someone", str(BOSSES[str(l["boss"])]["name"]).to_lower()])


func yearly() -> void:
	var s := st()
	if s.is_empty():
		return
	var p := _p()
	var age := int(p["age"])
	if GameState.has_job():
		add_experience(str(p["job"].get("field", "")), 1)
		s["gap"] = 0
	elif age >= 20 and age < 65 and not GameState.in_school() and not GameState.in_university() and not bool(p.get("retired", false)) and not GameState.in_prison():
		s["gap"] = mini(int(s["gap"]) + 1, 8)
	# the oldest openings fall away
	for k in s["open"].keys():
		if int(str(k).get_slice("_", 1)) < age - 1:
			s["open"].erase(k)
	s["interview_xp"] = maxf(0.0, float(s["interview_xp"]) - 0.005)
	# references fade
	var keep: Array = []
	for r in s["refs"]:
		r["strength"] = float(r["strength"]) - 0.06
		if float(r["strength"]) > 0.1:
			keep.append(r)
	s["refs"] = keep


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	match t:
		"recently_rejected": return int(s.get("rejections", 0)) > 0 and int(s.get("interview_xp", 0.0) * 100.0) > 0
		"has_reference": return not s.get("refs", []).is_empty()
		"cv_gap": return int(s.get("gap", 0)) >= 2
		"job_seeking": return not GameState.has_job() and int(_p().get("age", 0)) >= 18
	return false

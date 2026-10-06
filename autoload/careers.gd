extends Node

const CAREERS := {
	"actor": {"name": "Actor", "icon": "🎬", "min_age": 6, "full_time": true, "desc": "Auditions, roles, awards, sequels",
		"ranks": ["Extra", "Background Actor", "Supporting Actor", "Lead Actor", "A-List Star", "Hollywood Legend"],
		"thresholds": [0, 15, 30, 50, 72, 90], "skill": "Acting"},
	"musician": {"name": "Musician", "icon": "🎸", "min_age": 10, "full_time": true, "desc": "Songs, albums, tours, records",
		"ranks": ["Bedroom Musician", "Local Act", "Signed Artist", "Chart Topper", "Superstar", "Music Icon"],
		"thresholds": [0, 15, 30, 50, 72, 90], "skill": "Musicianship"},
	"athlete": {"name": "Pro Athlete", "icon": "🏆", "min_age": 16, "max_start": 26, "full_time": true, "desc": "Draft, contracts, championships",
		"ranks": ["Prospect", "Rookie", "Starter", "All-Star", "MVP", "Hall of Famer"],
		"thresholds": [0, 0, 45, 62, 80, 92], "skill": "Athletics"},
	"politician": {"name": "Politician", "icon": "🏛️", "min_age": 18, "full_time": true, "desc": "Campaigns, office, approval",
		"ranks": ["Candidate", "City Council Member", "Mayor", "State Legislator", "Governor", "Senator", "President"],
		"thresholds": [], "skill": "Charisma"},
	"mafia": {"name": "Mafia", "icon": "🕴️", "min_age": 18, "full_time": false, "desc": "Loyalty, jobs, rise to Godfather",
		"ranks": ["Associate", "Soldier", "Capo", "Underboss", "Consigliere", "Godfather"],
		"thresholds": [0, 20, 40, 60, 78, 94], "skill": "Respect"},
	"hustler": {"name": "Street Hustler", "icon": "🎲", "min_age": 14, "full_time": false, "desc": "Scams, busking, street territory",
		"ranks": ["Newbie", "Hustler", "Block Boss", "Street Legend"],
		"thresholds": [0, 25, 50, 80], "skill": "Street Cred"},
	"astronaut": {"name": "Astronaut", "icon": "🚀", "min_age": 22, "full_time": true, "desc": "Training, missions, spacewalks",
		"ranks": ["Astronaut Candidate", "Astronaut", "Mission Specialist", "Mission Commander", "Chief Astronaut"],
		"thresholds": [0, 25, 50, 72, 90], "skill": "Flight"},
	"model": {"name": "Model", "icon": "💃", "min_age": 16, "max_start": 30, "full_time": true, "desc": "Shoots, runways, campaigns",
		"ranks": ["Newcomer", "Catalog Model", "Runway Model", "Top Model", "Supermodel"],
		"thresholds": [0, 20, 40, 65, 88], "skill": "Presence"},
	"fighter": {"name": "Fighter", "icon": "🥊", "min_age": 18, "max_start": 32, "full_time": true, "desc": "Fight camp, bouts, title belts",
		"ranks": ["Amateur", "Pro Debut", "Contender", "Ranked Fighter", "Champion", "Legend"],
		"thresholds": [0, 15, 35, 55, 78, 93], "skill": "Fighting"},
	"director": {"name": "Director", "icon": "🎬", "min_age": 18, "full_time": true, "desc": "Scripts, casting, shoots, premieres",
		"ranks": ["Student Filmmaker", "Indie Director", "Studio Director", "Acclaimed Director", "Auteur"],
		"thresholds": [0, 20, 42, 68, 88], "skill": "Directing"},
	"agent": {"name": "Secret Agent", "icon": "🕵️", "min_age": 21, "full_time": true, "desc": "Missions, assets, a cover story",
		"ranks": ["Recruit", "Field Agent", "Senior Agent", "Station Chief", "Director of Operations"],
		"thresholds": [0, 22, 45, 70, 90], "skill": "Tradecraft"},
}

const NEW_CAREERS := ["astronaut", "model", "fighter", "director", "agent"]

const SPORTS := {
	"soccer": ["⚽", "Soccer", 900000], "basketball": ["🏀", "Basketball", 2500000], "football": ["🏈", "Football", 1800000],
	"baseball": ["⚾", "Baseball", 1600000], "hockey": ["🏒", "Hockey", 1200000], "tennis": ["🎾", "Tennis", 800000],
	"boxing": ["🥊", "Boxing", 700000], "golf": ["⛳", "Golf", 900000],
}
const TEAM_CITIES := ["Riverport", "Northfield", "Bay City", "Kingsbridge", "Sunvale", "Ironwood", "Lakeshore", "Redcliff", "Harborview", "Pinecrest"]
const TEAM_NAMES := ["Hawks", "Titans", "Comets", "Wolves", "Stingers", "Mariners", "Lions", "Rockets", "Foxes", "Vipers"]
const FAMILIES := ["the Valenti family", "the Ferraro family", "the Okuma-gumi", "the Blackwater Crew", "the Moretti clan"]
const OFFICE_SALARY := [0, 30000, 90000, 70000, 150000, 175000, 400000]
const OFFICE_COST := [0, 5000, 40000, 60000, 400000, 1500000, 20000000]
const BAND_WORDS_A := ["Velvet", "Neon", "Paper", "Midnight", "Electric", "Broken", "Golden", "Wild", "Hollow", "Crimson"]
const BAND_WORDS_B := ["Foxes", "Satellites", "Kings", "Echoes", "Hearts", "Machines", "Tigers", "Ghosts", "Harbors", "Arrows"]
const TITLE_A := ["The Last", "Midnight", "Broken", "Endless", "Silent", "Burning", "Hidden", "Crimson", "Lost", "Paper"]
const TITLE_B := ["Summer", "Kingdom", "Hearts", "Horizon", "Promise", "City", "Road", "Signal", "Empire", "Tide"]


func career() -> Dictionary:
	return GameState.player.get("career", {})


func has_career(id: String = "") -> bool:
	var c := career()
	if c.is_empty():
		return false
	return id == "" or c["id"] == id


func def() -> Dictionary:
	return CAREERS.get(career().get("id", ""), {})


func title() -> String:
	var c := career()
	if c.is_empty():
		return ""
	var d: Dictionary = CAREERS[c["id"]]
	var r: String = d["ranks"][clampi(int(c["rank"]), 0, d["ranks"].size() - 1)]
	if c["id"] == "athlete":
		return "%s (%s)" % [r, SPORTS[c["sport"]][1]]
	if c["id"] == "politician" and not c.get("in_office", false):
		return "Political Candidate"
	return r


func past(id: String) -> bool:
	return GameState.player.get("past_careers", []).has(id)


func skill() -> float:
	return float(career().get("skill", 0.0))


func random_title() -> String:
	return "%s %s" % [TITLE_A[randi() % TITLE_A.size()], TITLE_B[randi() % TITLE_B.size()]]


func _modifier(m: String) -> bool:
	return GameState.player.get("modifiers", []).has(m)


# ---------------------------------------------------------------- joining

func join_requirement(id: String) -> String:
	var p := GameState.player
	var d: Dictionary = CAREERS[id]
	var age: int = p["age"]
	if has_career():
		return "You already have a special career."
	if GameState.in_prison():
		return "You're in prison."
	if age < int(d["min_age"]):
		return "Age %d+" % int(d["min_age"])
	match id:
		"athlete":
			if age > int(d["max_start"]):
				return "Too old to go pro (start by 26)"
			if GameState.stat("health") < 60:
				return "Needs Health 60+"
		"politician":
			if not p["record"].is_empty() and p["record"].size() > 2:
				return "Your criminal record is too long"
		"mafia":
			if p["record"].is_empty() and int(p["karma"]) > -10 and not GameState.has_flag("mafia_invited") and not past("hustler"):
				return "They don't trust you. Get your hands dirty first."
	if NEW_CAREERS.has(id):
		return NewCareers.requirement(id)
	return ""


func join(id: String) -> void:
	var why := join_requirement(id)
	if why != "":
		EventEngine.push_info(CAREERS[id]["icon"], CAREERS[id]["name"], why)
		return
	match id:
		"musician":
			EventEngine.push_decision({"id": "_join_music", "icon": "🎸", "title": "Your sound", "text": "How do you want to make music?", "choices": [
				{"label": "Go solo as a singer", "outcomes": [{"text": "", "career_start": "musician", "career_mode": "solo"}]},
				{"label": "Start a band", "outcomes": [{"text": "", "career_start": "musician", "career_mode": "band"}]},
				{"label": "Never mind", "outcomes": [{"text": ""}]}]})
		"athlete":
			var choices: Array = []
			for s in SPORTS.keys():
				choices.append({"label": "%s  %s" % [SPORTS[s][0], SPORTS[s][1]], "outcomes": [{"text": "", "career_start": "athlete", "career_mode": s}]})
			choices.append({"label": "Never mind", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_join_sport", "icon": "🏆", "title": "Pick your sport", "text": "Which sport will you go pro in?", "choices": choices})
		"mafia":
			var choices2: Array = []
			var fams := FAMILIES.duplicate()
			fams.shuffle()
			for f in fams.slice(0, 3):
				choices2.append({"label": "Join %s" % f, "outcomes": [{"text": "", "career_start": "mafia", "career_mode": f}]})
			choices2.append({"label": "Walk away", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_join_mafia", "icon": "🕴️", "title": "Family business", "text": "A man in a sharp suit says three families could use someone like you.", "choices": choices2})
		_:
			start(id, "")


func start(id: String, mode: String) -> void:
	var p := GameState.player
	var d: Dictionary = CAREERS[id]
	if d["full_time"] and GameState.has_job():
		Actions.lose_job("quit")
	var c := {"id": id, "rank": 0, "skill": 20.0, "years": 0, "income_last": 0, "mode": mode}
	var line := ""
	if NEW_CAREERS.has(id):
		line = NewCareers.start(id, c, mode)
	match id:
		"actor":
			c["skill"] = 10.0 + GameState.stat("looks") * 0.1 + (15.0 if past("model") else 0.0) + (10.0 if past("director") else 0.0)
			c["agent"] = 0 if Web.contact(["agent"], 55) == "" else 1
			c["roles"] = []
			c["awards"] = 0
			line = "I decided to become an actor."
		"musician":
			c["skill"] = 10.0 + GameState.get_counter("music") * 4.0
			c["songs"] = 0
			c["song_quality"] = 0.0
			c["albums"] = []
			c["label"] = false
			if mode == "band":
				c["band"] = "%s %s" % [BAND_WORDS_A[randi() % BAND_WORDS_A.size()], BAND_WORDS_B[randi() % BAND_WORDS_B.size()]]
				c["bandmates"] = []
				for i in range(2):
					c["bandmates"].append(GameState.create_npc("bandmate", {"age": maxi(10, int(p["age"]) + randi_range(-3, 3)), "closeness": 60}))
				line = "I started a band called %s." % c["band"]
			else:
				line = "I started my career as a solo singer."
		"athlete":
			c["sport"] = mode
			c["skill"] = 25.0 + GameState.stat("health") * 0.2 + (10.0 if GameState.has_trait("Athletic") else 0.0)
			c["team"] = ""
			c["contract"] = 0
			c["injured"] = 0
			c["titles"] = 0
			line = "I committed to a career in %s." % SPORTS[mode][1].to_lower()
		"politician":
			c["skill"] = 20.0 + (15.0 if GameState.has_trait("Charmer") else 0.0)
			c["approval"] = 50.0 + (12.0 if past("astronaut") else 0.0) + (8.0 if past("athlete") or past("fighter") else 0.0) + float(p["fame"]) * 0.1
			c["in_office"] = false
			c["term_left"] = 0
			c["terms"] = 0
			line = "I got into politics."
		"mafia":
			c["family"] = mode
			c["skill"] = 5.0
			GameState.player["heat"] = float(GameState.player.get("heat", 0.0)) + 10.0
			c["boss"] = GameState.create_npc("mafia_boss", {"age": randi_range(50, 72), "gender": "male", "closeness": 40})
			line = "I was made an associate of %s." % mode
		"hustler":
			c["skill"] = 5.0 + (10.0 if past("fighter") else 0.0)
			line = "I started hustling on the streets."
	c["skill"]=clampf(float(c.get("skill",0))+Depth.school_bonus(id),0,100)
	p["career"] = c
	var bonus := carryover_line(id)
	GameState.add_log(line)
	if bonus != "":
		GameState.add_log(bonus)
		line += "\n\n" + bonus
	GameState.add_milestone(p["age"], line.trim_prefix("I ").trim_suffix(".").replace("my ", GameState.pron(p["gender"], "his") + " "))
	EventEngine.push_info(d["icon"], d["name"], line + "\n\nOpen Occupation → Special Careers to work your way up.")
	GameState.emit_changed()


func carryover_line(id: String) -> String:
	match id:
		"actor":
			if past("model"):
				return "My years in front of the camera as a model gave me a head start."
			if past("director"):
				return "Knowing how a set works from the director's chair helps."
		"director":
			if past("actor"):
				return "I can cast myself in my own films."
		"hustler":
			if past("fighter"):
				return "Nobody tests an ex-fighter's corner."
		"politician":
			if past("astronaut"):
				return "Voters love an astronaut. My approval starts high."
			if past("athlete") or past("fighter"):
				return "My sports fame follows me onto the campaign trail."
		"mafia":
			if past("hustler"):
				return "The family already knows my name from the streets."
		"fighter":
			if past("athlete"):
				return "My athletic background gives me an edge in the gym."
	return ""


func quit(reason: String = "quit") -> void:
	var c := career()
	if c.is_empty():
		return
	if not GameState.player["past_careers"].has(c["id"]):
		GameState.player["past_careers"].append(c["id"])
	if not GameState.player.has("career_best"):
		GameState.player["career_best"] = {}
	GameState.player["career_best"][c["id"]] = maxi(int(GameState.player["career_best"].get(c["id"], -1)), int(c.get("rank", 0)))
	var t := title()
	GameState.player["job_history"].append(t)
	GameState.player["career"] = {}
	match reason:
		"quit": GameState.add_log("I walked away from my career as %s." % t)
		"retire":
			GameState.add_log("I retired from my career as %s." % t)
			GameState.add_milestone(GameState.player["age"], "retired as %s" % t)
		"prison": GameState.add_log("My career as %s ended when I went to prison." % t)
	GameState.emit_changed()


# ---------------------------------------------------------------- actions list

func actions() -> Array:
	var c := career()
	if c.is_empty():
		return []
	var out: Array = []
	match c["id"]:
		"actor":
			out.append({"id": "audition", "name": "Audition for a role", "icon": "🎭", "sub": "🎮 Minigame · uses 1 time point"})
			out.append({"id": "class", "name": "Acting class ($300)", "icon": "📚", "sub": "Acting skill"})
			out.append({"id": "agent", "name": ["Hire a talent agent", "Upgrade to a top agent", "Top agent signed"][int(c["agent"])], "icon": "🤝", "sub": "Better roles, 10% cut", "off": int(c["agent"]) >= 2})
			out.append({"id": "red_carpet", "name": "Walk a red carpet", "icon": "📸", "sub": "Fame", "off": int(c["rank"]) < 2})
		"musician":
			out.append({"id": "practice", "name": "Practice", "icon": "🎼", "sub": "Musicianship"})
			out.append({"id": "write", "name": "Write a song", "icon": "✍️", "sub": "%d songs ready" % int(c["songs"])})
			out.append({"id": "single", "name": "Release a single", "icon": "💿", "sub": "Needs 1 song", "off": int(c["songs"]) < 1})
			out.append({"id": "album", "name": "Release an album", "icon": "📀", "sub": "Needs 8 songs", "off": int(c["songs"]) < 8})
			out.append({"id": "gig", "name": "Play a live show", "icon": "🎤", "sub": "🎮 Minigame · money, fans, skill"})
			out.append({"id": "tour", "name": "Go on tour", "icon": "🚌", "sub": "🎮 Minigame · needs fame 12+", "off": float(GameState.player["fame"]) < 12})
			out.append({"id": "busk", "name": "Busk on the street", "icon": "🪕", "sub": "Tips and practice"})
			out.append({"id": "label", "name": "Pitch a record label", "icon": "🏷️", "sub": "Signed" if c["label"] else "Advance money and promotion", "off": c["label"]})
		"athlete":
			out.append({"id": "big_game", "name": "Play the big game", "icon": "🔥", "sub": "🎮 Minigame · boosts your season", "off": c["team"] == "" or int(c["injured"]) > 0 or c.get("big_game_year", -1) == GameState.year_now()})
			out.append({"id": "train", "name": "Train hard", "icon": "🏋️", "sub": "Athletics, small injury risk"})
			out.append({"id": "rehab", "name": "Rehab your injury", "icon": "🩹", "sub": "Recover faster", "off": int(c["injured"]) <= 0})
			out.append({"id": "negotiate", "name": "Negotiate your contract", "icon": "📝", "sub": "Current: %s/yr" % GameState.fmt_money(int(c["contract"])), "off": c["team"] == ""})
			out.append({"id": "endorse", "name": "Sign an endorsement deal", "icon": "👟", "sub": "Needs Fame 25+", "off": float(GameState.player["fame"]) < 25})
			out.append_array(Ambition.sports_actions(c))
		"politician":
			if not c["in_office"]:
				out.append({"id": "run", "name": "Run for %s" % CAREERS["politician"]["ranks"][int(c["rank"]) + 1], "icon": "🗳️", "sub": "Campaign costs about %s" % GameState.fmt_money(OFFICE_COST[int(c["rank"]) + 1])})
			else:
				out.append({"id": "bill", "name": "Propose a bill", "icon": "📜", "sub": "Approval can swing"})
				out.append({"id": "speech", "name": "Give a speech", "icon": "🎤", "sub": "Charisma and approval"})
				out.append({"id": "tv_debate", "name": "Televised debate", "icon": "🎙️", "sub": "🎮 Minigame · approval swings"})
				out.append({"id": "presser", "name": "Hold a press conference", "icon": "📰", "sub": "Fame, risky"})
				out.append({"id": "bribe", "name": "Accept a donor's \"gift\"", "icon": "💼", "sub": "Money now, scandal later"})
				if int(c["rank"]) < 6:
					out.append({"id": "run", "name": "Run for %s" % CAREERS["politician"]["ranks"][int(c["rank"]) + 1], "icon": "🗳️", "sub": "Campaign costs about %s" % GameState.fmt_money(OFFICE_COST[int(c["rank"]) + 1])})
			out.append({"id": "donors", "name": "Fundraise", "icon": "💰", "sub": "Raise campaign money"})
		"mafia":
			out.append({"id": "job", "name": "Do a job for the boss", "icon": "💼", "sub": "Money and respect, raises heat"})
			out.append({"id": "vault", "name": "Crack a vault", "icon": "🔐", "sub": "🎮 Minigame · big score, big heat"})
			out.append({"id": "tribute", "name": "Pay tribute", "icon": "💵", "sub": "Loyalty to the family"})
			out.append({"id": "hit", "name": "Take out a rival", "icon": "🔫", "sub": "Big respect, big risk", "off": int(c["rank"]) < 1})
			out.append({"id": "lay_low", "name": "Lay low", "icon": "🕶️", "sub": "Lower heat (%d)" % int(GameState.player["heat"])})
			out.append({"id": "rat", "name": "Cooperate with the feds", "icon": "🐀", "sub": "Leave the family forever"})
		"hustler":
			out.append({"id": "monte", "name": "Run three-card monte", "icon": "🃏", "sub": "Cash and cred"})
			out.append({"id": "knockoffs", "name": "Sell knockoff watches", "icon": "⌚", "sub": "Cash, risk of heat"})
			out.append({"id": "pickpocket", "name": "Pickpocket tourists", "icon": "👛", "sub": "🎮 Minigame · quick cash"})
			out.append({"id": "busk", "name": "Busk", "icon": "🪕", "sub": "Honest money"})
			out.append({"id": "corner", "name": "Claim a corner", "icon": "🚩", "sub": "Territory and cred"})
			out.append({"id": "lay_low", "name": "Lay low", "icon": "🕶️", "sub": "Lower heat (%d)" % int(GameState.player["heat"])})
	if NEW_CAREERS.has(c["id"]):
		out.append_array(NewCareers.actions(c))
	out.append({"id": "retire", "name": "Retire from this career", "icon": "🚪", "sub": ""})
	return out


func _t() -> bool:
	if GameState.spend_time():
		return false
	EventEngine.push_info("⏳", "Out of time", "You've used all your time this year.\nPress Age to move on.")
	return true


var rep_mult := 1.0
var rep_over: Dictionary = {}
var rep_note := ""


## Starts a repeat-tracked action. The first `free` uses per year pay in full;
## after that, gains shrink and `over` costs are added on top.
func rep_begin(key: String, free: int = 2, over: Dictionary = {"stress": 4}, over_text: String = "") -> void:
	var p := GameState.player
	if not p.has("act_year"):
		p["act_year"] = {}
	var n := int(p["act_year"].get(key, 0))
	p["act_year"][key] = n + 1
	if n < free:
		rep_mult = 1.0
		rep_over = {}
		rep_note = ""
		return
	rep_mult = maxf(0.1, pow(0.5, n - free + 1))
	rep_over = over
	rep_note = over_text if over_text != "" else "\n\n(%s time this year. It barely helps any more, and it's wearing on me.)" % _ordinal_times(n + 1)


func _ordinal_times(n: int) -> String:
	match n:
		3: return "Third"
		4: return "Fourth"
		5: return "Fifth"
	return "%dth" % n


func rep_end() -> void:
	rep_mult = 1.0
	rep_over = {}
	rep_note = ""


func scale_effects(effects: Dictionary) -> Dictionary:
	if rep_mult >= 1.0 and rep_over.is_empty():
		return effects
	var out := {}
	for k in effects.keys():
		var v = effects[k]
		var good := false
		if k in ["happiness", "health", "smarts", "looks", "karma", "skill", "fame", "approval", "respect", "cred", "job_perf", "school"]:
			good = float(v) > 0
		elif k == "stress":
			good = float(v) < 0
		out[k] = (float(v) * rep_mult) if good else v
	for k in rep_over.keys():
		out[k] = float(out.get(k, 0)) + float(rep_over[k])
	return out


func _done(icon: String, title_txt: String, text: String, effects: Dictionary = {}) -> void:
	effects=effects.duplicate(true)
	if float(effects.get("money",0))>0: effects["money"]=int(float(effects["money"])*Aptitude.reward(Aptitude.career_context(str(career().get("id","work")))))
	var changes := GameState.apply_effects(scale_effects(effects))
	text += rep_note
	GameState.add_log(text)
	EventEngine.push_info(icon, title_txt, text, changes)


func do_action(aid: String) -> void:
	var c := career()
	var p := GameState.player
	if c.is_empty():
		return
	Grit.habit("workaholic", 2)
	var tl0 := int(p["time_left"])
	rep_begin("c_" + aid, 2, {"stress": 5, "health": -2})
	_do_career_action(aid, c, p)
	if int(p["time_left"]) == tl0 and p.has("act_year"):
		p["act_year"]["c_" + aid] = maxi(0, int(p["act_year"].get("c_" + aid, 1)) - 1)
	rep_end()


func _do_career_action(aid: String, c: Dictionary, p: Dictionary) -> void:
	if aid == "retire":
		quit("retire")
		EventEngine.push_info("🚪", "Retired", "I retired from my special career.")
		return
	if aid.begins_with("v8_") and c["id"] == "athlete":
		Ambition.sports_action(aid, c)
		return
	match c["id"]:
		"actor": _actor(aid, c, p)
		"musician": _musician(aid, c, p)
		"athlete": _athlete(aid, c, p)
		"politician": _politician(aid, c, p)
		"mafia": _mafia(aid, c, p)
		"hustler": _hustler(aid, c, p)
		_:
			if NEW_CAREERS.has(c["id"]):
				NewCareers.do_action(aid, c, p)
	_update_rank()


# ---------------------------------------------------------------- actor

func _actor(aid: String, c: Dictionary, p: Dictionary) -> void:
	match aid:
		"audition":
			if _t(): return
			var tiers := [
				["Commercial", 0.75, 3000, 1, 0], ["TV guest role", 0.55, 12000, 2, 1], ["Indie film", 0.45, 40000, 3, 1],
				["TV series regular", 0.35, 90000, 4, 2], ["Studio blockbuster", 0.22, 600000, 8, 3],
			]
			var choices: Array = []
			for t in tiers:
				if int(c["rank"]) < int(t[4]):
					continue
				var chance := float(t[1]) + float(c["skill"]) / 300.0 + GameState.stat("looks") / 500.0 + float(p["fame"]) / 300.0 + int(c["agent"]) * 0.06
				if Web.contact(["agent", "producer"], 60) != "":
					chance += 0.08
				var pay := int(int(t[2]) * (1.0 + float(p["fame"]) / 40.0))
				choices.append({"label": "%s (pays %s)" % [t[0], GameState.fmt_money(pay)], "outcomes": [
					{"text": "", "play": {"id": "audition", "kind": "actor_audition", "params": {"skill": float(c["skill"]), "difficulty": 0.8 + int(t[4]) * 0.15}, "tier": t[0], "chance": chance, "pay": pay, "fame": int(t[3])}}]})
			choices.append({"label": "Not today", "outcomes": [{"text": ""}]})
			var hint := ""
			var ag := Web.contact(["agent", "producer"], 60)
			if ag != "":
				hint = "\n\n%s put in a good word for you." % Web.contact_line(ag)
			EventEngine.push_decision({"id": "_audition", "icon": "🎭", "title": "Auditions", "text": "Your agent has a few auditions lined up. Pick one, then nail the read." + hint, "choices": choices})
		"class":
			if _t(): return
			if int(p["money"]) < 300:
				EventEngine.push_info("💸", "Acting class", "Acting classes cost $300.")
				return
			_done("📚", "Acting class", "I took an acting class and learned to cry on cue.", {"money": -300, "skill": 5})
		"agent":
			if _t(): return
			if int(c["agent"]) == 0:
				c["agent"] = 1
				_done("🤝", "Agent", "I signed with a small talent agency. They take 10%.", {"happiness": 3})
			elif float(p["fame"]) >= 35 or float(c["skill"]) >= 70:
				c["agent"] = 2
				_done("🤝", "Top agent", "One of the biggest agents in the business signed me.", {"happiness": 6, "fame": 2})
			else:
				_done("🤝", "Top agent", "The top agencies passed. They want someone more famous.", {"happiness": -3})
		"red_carpet":
			if _t(): return
			var looks := ["a velvet suit", "a daring gown", "sneakers and a tux", "a vintage outfit", "head-to-toe sequins"]
			_done("📸", "Red carpet", "I walked the red carpet in %s. The photographers went wild." % looks[randi() % looks.size()], {"fame": 3, "happiness": 4})


# ---------------------------------------------------------------- musician

func _musician(aid: String, c: Dictionary, p: Dictionary) -> void:
	var name_str: String = c.get("band", "")
	var who: String = name_str if name_str != "" else "I"
	match aid:
		"practice":
			if _t(): return
			_done("🎼", "Practice", "I practiced until my fingers hurt." if name_str == "" else "%s rehearsed all week in the garage." % name_str, {"skill": 4, "stress": -1})
		"write":
			if _t(): return
			var q := clampf(float(c["skill"]) * 0.7 + GameState.stat("smarts") * 0.2 + randf_range(-10, 20), 0, 100)
			c["song_quality"] = (float(c["song_quality"]) * int(c["songs"]) + q) / float(int(c["songs"]) + 1)
			c["songs"] = int(c["songs"]) + 1
			var verdict := "a masterpiece" if q > 80 else ("pretty good" if q > 55 else "okay, I guess")
			_done("✍️", "Songwriting", "I wrote a new song called \"%s\". It's %s." % [random_title(), verdict], {"skill": 1, "happiness": 2})
		"single":
			if _t(): return
			var q := float(c["song_quality"])
			c["songs"] = int(c["songs"]) - 1
			var streams := int(pow(maxf(1.0, q + float(p["fame"]) * 1.5), 2.2) * randf_range(20, 80) * (2.0 if c["label"] else 1.0))
			var pay := int(streams * 0.004)
			var t := random_title()
			var fame_gain := clampi(int(streams / 400000.0), 0, 12)
			var chart := ""
			if streams > 3000000:
				chart = " It hit #%d on the charts!" % randi_range(1, 20)
				fame_gain += 4
			_done("💿", "New single", "%s released the single \"%s\". It got %s streams and made %s.%s" % [who if who != "I" else "I", t, _fmt_big(streams), GameState.fmt_money(pay), chart], {"money": pay, "fame": fame_gain, "happiness": 4})
		"album":
			if _t(): return
			var q := float(c["song_quality"])
			c["songs"] = int(c["songs"]) - 8
			var t := random_title()
			var sales := int(pow(maxf(1.0, q * 0.8 + float(p["fame"]) * 1.8), 2.5) * randf_range(3, 12) * (2.5 if c["label"] else 1.0))
			var pay := int(sales * 1.5)
			var cert := ""
			if sales >= 10000000:
				cert = "Diamond"
				GameState.counter("diamond")
			elif sales >= 1000000:
				cert = "Platinum"
			elif sales >= 500000:
				cert = "Gold"
			c["albums"].append({"title": t, "sales": sales, "cert": cert, "year": GameState.year_now()})
			var fame_gain := clampi(int(sales / 150000.0), 1, 20)
			var ctext := " It went %s!" % cert if cert != "" else ""
			if cert != "":
				GameState.add_milestone(p["age"], "released the %s album \"%s\"" % [cert.to_lower(), t])
			_done("📀", "New album", "%s released the album \"%s\" and sold %s copies.%s" % ["I" if who == "I" else who, t, _fmt_big(sales), ctext], {"money": pay, "fame": fame_gain, "happiness": 8})
		"gig":
			if _t(): return
			Minigames.play("rhythm", {"skill": float(c["skill"]), "difficulty": 0.85 + int(c["rank"]) * 0.08}, Callable(self, "resolve_play").bind({"kind": "music_gig"}))
		"tour":
			if _t(): return
			Minigames.play("rhythm", {"skill": float(c["skill"]), "difficulty": 1.0 + int(c["rank"]) * 0.08}, Callable(self, "resolve_play").bind({"kind": "music_tour"}))
		"busk":
			if _t(): return
			var tips := randi_range(15, 180)
			_done("🪕", "Busking", "I played on the street corner and made %s in tips." % GameState.fmt_money(tips), {"money": tips, "skill": 2, "fame": 0.5})
		"label":
			if _t(): return
			var chance := float(p["fame"]) / 60.0 + float(c["skill"]) / 250.0
			if _modifier("star_power"):
				chance = 1.0
			if randf() < Aptitude.chance(chance,Aptitude.career_context(str(career().get("id","work")))):
				c["label"] = true
				var adv := int(20000 + float(p["fame"]) * 3000)
				GameState.add_milestone(p["age"], "signed a record deal")
				_done("🏷️", "Record deal", "A record label signed me with a %s advance!" % GameState.fmt_money(adv), {"money": adv, "happiness": 12, "fame": 3})
			else:
				_done("🏷️", "Record deal", "The label said my sound \"isn't commercial enough\".", {"happiness": -5})


static func _fmt_big(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)


# ---------------------------------------------------------------- athlete

func _athlete(aid: String, c: Dictionary, p: Dictionary) -> void:
	match aid:
		"big_game":
			Depth.sport()
		"train":
			if _t(): return
			if randf() < 0.05:
				c["injured"] = randi_range(1, 2)
				_done("🤕", "Training", "I tore a muscle in training. I'll be out for a while." + Grit.scar_chance("bad_knee", 0.25), {"health": -8, "happiness": -6})
			else:
				_done("🏋️", "Training", "I trained like a machine.", {"skill": 4, "health": 2, "stress": 2})
		"rehab":
			if _t(): return
			c["injured"] = maxi(0, int(c["injured"]) - 1)
			_done("🩹", "Rehab", "Rehab is boring, but my body is healing.", {"health": 5})
		"negotiate":
			if _t(): return
			var chance := 0.25 + float(c["skill"]) / 200.0 + float(p["fame"]) / 300.0 + (0.1 if GameState.has_trait("Charmer") else 0.0)
			if randf() < Aptitude.chance(chance,Aptitude.career_context(str(career().get("id","work")))):
				c["contract"] = int(int(c["contract"]) * 1.35)
				_done("📝", "Contract", "My agent squeezed out a raise. New contract: %s a year." % GameState.fmt_money(int(c["contract"])), {"happiness": 6})
			else:
				_done("📝", "Contract", "The team refused to renegotiate. The fans heard about it.", {"fame": -1, "happiness": -3})
		"endorse":
			if _t(): return
			var pay := int(float(p["fame"]) * 4000 * randf_range(0.7, 1.4))
			var brands := ["a sneaker brand", "a sports drink", "a watch company", "a car maker", "a video game"]
			_done("👟", "Endorsement", "I signed an endorsement deal with %s worth %s." % [brands[randi() % brands.size()], GameState.fmt_money(pay)], {"money": pay, "fame": 2})


# ---------------------------------------------------------------- politician

func _politician(aid: String, c: Dictionary, p: Dictionary) -> void:
	match aid:
		"run":
			if _t(): return
			var target := int(c["rank"]) + 1
			var office: String = CAREERS["politician"]["ranks"][target]
			var need_age: int = [18, 18, 21, 21, 30, 30, 35][target]
			if int(p["age"]) < need_age:
				EventEngine.push_info("🗳️", office, "You must be %d to run for %s." % [need_age, office])
				return
			if target >= 3 and int(c["rank"]) < target - 1 and not c["in_office"]:
				pass
			var cost: int = OFFICE_COST[target]
			var base := 0.35 + (float(c.get("approval", 50)) - 50.0) / 150.0 + float(c["skill"]) / 250.0 + float(p["fame"]) / 250.0 - float(p["record"].size()) * 0.08
			if not c["in_office"] and target > 1:
				base -= 0.08 * (target - 1)
			var choices: Array = []
			for tier in [["Grassroots campaign", 0.25, 0.0], ["Standard campaign", 1.0, 0.12], ["Blitz campaign", 3.0, 0.22]]:
				var spend := int(cost * float(tier[1]))
				var ch := clampf(base + float(tier[2]), 0.05, 0.92)
				choices.append({"label": "%s (%s)" % [tier[0], GameState.fmt_money(spend)], "requires": {"money": spend}, "outcomes": [
					{"text": "", "play": {"id": "debate", "kind": "campaign", "params": {"skill": float(c["skill"]), "difficulty": 0.8 + target * 0.1}, "chance": ch, "spend": spend, "target": target, "office": office}}]})
			choices.append({"label": "Drop out", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_campaign", "icon": "🗳️", "title": "Run for %s" % office, "text": "Election season. How hard do you campaign?\nThen win the big debate. Your odds depend on approval, charisma, fame, your record and how the debate goes.", "choices": choices})
		"tv_debate":
			if _t(): return
			Minigames.play("debate", {"skill": float(c["skill"]), "difficulty": 0.9 + int(c["rank"]) * 0.08}, Callable(self, "resolve_play").bind({"kind": "tv_debate"}))
		"bill":
			if _t(): return
			var choices2 := [
				{"label": "Fix the potholes (popular)", "outcomes": [{"weight": 3, "text": "The pothole bill passed. People noticed.", "effects": {"approval": 6, "skill": 1}}, {"weight": 1, "text": "The bill stalled in committee.", "effects": {"approval": -2}}]},
				{"label": "Raise taxes to fund schools", "outcomes": [{"weight": 1, "text": "The school bill passed. Half the voters love me, half hate me.", "effects": {"approval": 2, "karma": 3}}, {"weight": 1, "text": "The tax bill backfired.", "effects": {"approval": -8}}]},
				{"label": "Name a holiday after yourself", "outcomes": [{"weight": 1, "text": "It passed as a joke. The internet did not find it funny.", "effects": {"approval": -10, "fame": 3}}]},
			]
			EventEngine.push_decision({"id": "_bill", "icon": "📜", "title": "New bill", "text": "What bill will you put your name on?", "choices": choices2})
		"speech":
			if _t(): return
			var ch := 0.5 + float(c["skill"]) / 200.0
			if randf() < Aptitude.chance(ch,Aptitude.career_context(str(career().get("id","work")))):
				_done("🎤", "Speech", "My speech got a standing ovation.", {"approval": randi_range(3, 7), "skill": 3})
			else:
				_done("🎤", "Speech", "I mispronounced the town's name. Twice.", {"approval": -4, "skill": 1})
		"presser":
			if _t(): return
			if randf() < 0.6:
				_done("📰", "Press conference", "I handled the reporters like a pro.", {"approval": 3, "fame": 2})
			else:
				_done("📰", "Press conference", "A reporter's question rattled me on live TV.", {"approval": -5, "fame": 2})
		"bribe":
			if _t(): return
			var amt := int(OFFICE_SALARY[int(c["rank"])] * randf_range(0.3, 1.2)) + 5000
			GameState.set_flag("took_bribe")
			GameState.followups.append({"event": "politics.bribe_scandal", "age": int(p["age"]) + randi_range(1, 5), "roles": {}, "retries": 0})
			_done("💼", "A generous donor", "A donor handed me an envelope with %s. For my \"campaign\"." % GameState.fmt_money(amt), {"money": amt, "karma": -8})
		"donors":
			if _t(): return
			var raised := int((1000 + float(c["skill"]) * 300 + float(p["fame"]) * 800) * (1 + int(c["rank"])) * randf_range(0.6, 1.4))
			_done("💰", "Fundraiser", "I held a fundraising dinner and raised %s." % GameState.fmt_money(raised), {"money": raised, "stress": 2})


func take_office(target: int) -> void:
	var c := career()
	var p := GameState.player
	c["rank"] = target
	c["in_office"] = true
	c["term_left"] = 4
	c["terms"] = 1
	var office: String = CAREERS["politician"]["ranks"][target]
	GameState.add_milestone(p["age"], "was elected %s" % office)
	if target == 6:
		GameState.counter("president")


# ---------------------------------------------------------------- mafia

func _mafia(aid: String, c: Dictionary, p: Dictionary) -> void:
	match aid:
		"job":
			if _t(): return
			var jobs := [["collect a debt", 0.8, [2000, 8000]], ["shake down a restaurant", 0.7, [5000, 15000]], ["hijack a truck", 0.55, [15000, 60000]], ["rob a jewelry store", 0.45, [40000, 150000]]]
			var choices: Array = []
			for j in jobs:
				var ch := clampf(float(j[1]) + float(c["skill"]) / 300.0 - float(GameState.player["heat"]) / 300.0, 0.1, 0.95)
				var lo := int(j[2][0])
				var hi := int(j[2][1])
				var amt := randi_range(lo, hi)
				choices.append({"label": "%s" % j[0].capitalize(), "outcomes": [
					{"weight": ch, "text": "I %s for the boss. My cut: %s." % [j[0], GameState.fmt_money(amt)], "effects": {"money": amt, "respect": 5, "heat": 8, "karma": -5}},
					{"weight": (1.0 - ch) * 0.6, "text": "The job went sideways. I got out, but the boss is not happy.", "effects": {"respect": -6, "heat": 10}},
					{"weight": (1.0 - ch) * 0.4, "text": "The cops were waiting. I was arrested.", "effects": {"heat": 15}, "trial": ["organized crime", 3, 10]},
				]})
			choices.append({"label": "Not today", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_mafia_job", "icon": "💼", "title": "A job for the family", "text": "The boss has work for you. Pick your job.", "choices": choices})
		"vault":
			if _t(): return
			Minigames.play("safecrack", {"skill": float(c["skill"]), "difficulty": 0.85 + int(c["rank"]) * 0.07}, Callable(self, "resolve_play").bind({"kind": "vault"}))
		"tribute":
			if _t(): return
			var amt := maxi(1000, int(int(p["money"]) * 0.1))
			if int(p["money"]) < amt:
				EventEngine.push_info("💸", "Tribute", "You don't have enough to pay tribute.")
				return
			_done("💵", "Tribute", "I paid %s in tribute to %s." % [GameState.fmt_money(amt), c["family"]], {"money": -amt, "respect": 4})
		"hit":
			if _t(): return
			var ch := 0.45 + float(c["skill"]) / 300.0
			EventEngine.push_decision({"id": "_hit", "icon": "🔫", "title": "The rival", "text": "A rival capo has been muscling in on your family's territory. The boss wants it handled.", "choices": [
				{"label": "Do it", "outcomes": [
					{"weight": ch, "text": "It's done. Nobody talks about the rival anymore.", "effects": {"respect": 14, "heat": 20, "karma": -25}, "counter": {"crimes": 1}},
					{"weight": (1.0 - ch) * 0.7, "text": "It failed. The rival knows it was me.", "effects": {"respect": -8, "heat": 15, "health": -10}},
					{"weight": (1.0 - ch) * 0.3, "text": "The feds had a wire. I was arrested on the spot.", "trial": ["murder conspiracy", 15, 30]}]},
				{"label": "Refuse", "outcomes": [{"text": "I told the boss I wouldn't do it. He'll remember that.", "effects": {"respect": -12, "karma": 5}}]}]})
		"lay_low":
			if _t(): return
			_done("🕶️", "Laying low", "I kept my head down and stayed away from the family business.", {"heat": -18, "respect": -2})
		"rat":
			quit("quit")
			GameState.set_flag("witness_protection")
			var new_last := ContentDB.random_last(p["country"])
			GameState.add_milestone(p["age"], "entered witness protection")
			p["last"] = new_last
			_done("🐀", "Witness protection", "I testified against the family and entered witness protection. My new name is %s %s." % [p["first"], new_last], {"karma": 10, "stress": 20, "happiness": -10})


# ---------------------------------------------------------------- hustler

func _hustler(aid: String, c: Dictionary, p: Dictionary) -> void:
	var caught := func(fine: int, heat_gain: float) -> bool:
		if randf() < float(GameState.player["heat"]) / 400.0 + 0.04:
			GameState.player["heat"] = float(GameState.player["heat"]) + heat_gain
			GameState.player["record"].append("petty theft")
			_done("🚓", "Busted", "A cop caught me in the act. I paid a %s fine." % GameState.fmt_money(fine), {"money": -fine, "cred": -3})
			return true
		return false
	match aid:
		"monte":
			if _t(): return
			if caught.call(400, 10): return
			var amt := randi_range(40, 400) + int(float(c["skill"]) * 8)
			_done("🃏", "Three-card monte", "I ran three-card monte on the corner and cleaned out %s." % GameState.fmt_money(amt), {"money": amt, "cred": 3, "heat": 5, "karma": -2})
		"knockoffs":
			if _t(): return
			if caught.call(900, 14): return
			var amt := randi_range(200, 1500) + int(float(c["skill"]) * 20)
			_done("⌚", "Knockoffs", "I sold a suitcase of \"designer\" watches for %s." % GameState.fmt_money(amt), {"money": amt, "cred": 4, "heat": 8, "karma": -3})
		"pickpocket":
			if _t(): return
			Minigames.play("pickpocket", {"skill": float(c["skill"]), "difficulty": 0.85 + int(c["rank"]) * 0.1}, Callable(self, "resolve_play").bind({"kind": "pickpocket"}))
		"busk":
			if _t(): return
			var tips := randi_range(20, 220)
			_done("🪕", "Busking", "I played for the crowds and made %s in tips." % GameState.fmt_money(tips), {"money": tips, "cred": 1, "happiness": 3})
		"corner":
			if _t(): return
			var ch := 0.4 + float(c["skill"]) / 150.0 + (0.15 if GameState.has_trait("Hothead") else 0.0)
			if randf() < Aptitude.chance(ch,Aptitude.career_context(str(career().get("id","work")))):
				_done("🚩", "Territory", "I claimed a new corner. The other hustlers know whose block it is now.", {"cred": 8, "heat": 4})
			else:
				_done("🚩", "Territory", "The corner was taken, and the guy holding it made that very clear.", {"health": -8, "cred": -2})
		"lay_low":
			if _t(): return
			_done("🕶️", "Laying low", "I stayed off the streets for a while.", {"heat": -20})


# ---------------------------------------------------------------- yearly

func yearly() -> void:
	var p := GameState.player
	_fame_yearly()
	var c := career()
	if c.is_empty():
		return
	if GameState.in_prison():
		quit("prison")
		return
	c["years"] = int(c["years"]) + 1
	var income := 0
	match c["id"]:
		"actor":
			var cut: float = [1.0, 0.9, 0.9][int(c["agent"])]
			for r in c["roles"]:
				if not r.has("reception"):
					var score := float(c["skill"]) * 0.5 + float(r.get("perf", 0.5)) * 30.0 + randf_range(0, 45)+(Aptitude.score("creative")-50)*0.15
					var rec := "flop" if score < 35 else ("solid" if score < 60 else ("hit" if score < 80 else "masterpiece"))
					r["reception"] = rec
					match rec:
						"flop":
							GameState.add_log("\"%s\" flopped. The critics were brutal." % r["title"])
							GameState.apply_effects({"fame": -1, "happiness": -4})
						"solid":
							GameState.add_log("\"%s\" came out to solid reviews." % r["title"])
							GameState.apply_effects({"fame": 1})
						"hit":
							GameState.add_log("\"%s\" was a hit!" % r["title"])
							GameState.apply_effects({"fame": 5, "happiness": 5})
							income += int(int(r["pay"]) * 0.3)
							if r["tier"] in ["Indie film", "Studio blockbuster"]:
								GameState.followups.append({"event": "actor.sequel_offer", "age": int(p["age"]) + randi_range(2, 4), "roles": {}, "retries": 0})
						"masterpiece":
							GameState.add_log("Critics are calling \"%s\" a masterpiece." % r["title"])
							GameState.apply_effects({"fame": 8, "happiness": 8})
							income += int(int(r["pay"]) * 0.5)
							if randf() < 0.45:
								c["awards"] = int(c["awards"]) + 1
								GameState.counter("awards")
								GameState.add_log("I won a Golden Statue for my role in \"%s\"!" % r["title"])
								GameState.add_milestone(p["age"], "won a Golden Statue for \"%s\"" % r["title"])
								GameState.apply_effects({"fame": 10, "happiness": 15})
			income = int(income * cut)
		"musician":
			for a in c["albums"]:
				income += int(int(a["sales"]) * 0.15 / maxf(1.0, float(GameState.year_now() - int(a["year"]))))
			var gigs := int((300 + float(c["skill"]) * 60 + float(p["fame"]) * 900) * randf_range(0.7, 1.3))
			if c["label"]:
				gigs = int(gigs * 1.5)
			income += int(gigs*Aptitude.reward("creative"))
			if int(c["songs"]) == 0 and randf() < 0.5:
				c["songs"] = 1
				c["song_quality"] = maxf(float(c["song_quality"]), float(c["skill"]) * 0.6)
				GameState.add_log("I wrote a new song between shows.")
			if c.get("band", "") != "" and randf() < 0.05 and int(c["years"]) > 3:
				GameState.add_log("%s broke up after a fight about creative differences." % c["band"])
				GameState.set_flag("band_broke_up")
				GameState.followups.append({"event": "music.reunion", "age": int(p["age"]) + randi_range(5, 15), "roles": {}, "retries": 0})
				c["band"] = ""
		"athlete":
			income = _athlete_season(c, p)
		"politician":
			if c["in_office"]:
				income = OFFICE_SALARY[int(c["rank"])]
				c["approval"] = clampf(float(c["approval"]) + (50.0 - float(c["approval"])) * 0.1 + randf_range(-5, 5), 0, 100)
				c["term_left"] = int(c["term_left"]) - 1
				if int(c["term_left"]) <= 0:
					_reelection(c, p)
		"mafia":
			income = [5000, 15000, 40000, 90000, 180000, 500000][int(c["rank"])]
			if randf() < float(GameState.player["heat"]) / 220.0:
				GameState.add_log("The feds raided a family warehouse and came for me.")
				GameState.player["heat"] = 0.0
				Law.trial("racketeering", 3, 12)
		"hustler":
			income = int(float(c["skill"]) * 120 * randf_range(0.6, 1.3)*Aptitude.reward("social"))
		_:
			if NEW_CAREERS.has(c["id"]):
				income = NewCareers.yearly(c, p)
				if career().is_empty():
					if income != 0:
						GameState.player["money"] = int(GameState.player["money"]) + income
					return
	if income != 0:
		GameState.player["money"] = int(GameState.player["money"]) + income
		c["income_last"] = income
		GameState.add_log("My career as %s earned me %s this year." % [title(), GameState.fmt_money(income)])
	_update_rank()


func _athlete_season(c: Dictionary, p: Dictionary) -> int:
	var age: int = p["age"]
	var sport: Array = SPORTS[c["sport"]]
	if age >= 30:
		c["skill"] = maxf(0.0, float(c["skill"]) - randf_range(2.0, 6.0))
	if c["team"] == "":
		if age >= 18 and (float(c["skill"]) >= 45 or _modifier("star_power") or randf() < float(c["skill"]) / 120.0):
			var team := "%s %s" % [TEAM_CITIES[randi() % TEAM_CITIES.size()], TEAM_NAMES[randi() % TEAM_NAMES.size()]]
			c["team"] = team
			c["rank"] = 1
			c["contract"] = int(float(sport[2]) * pow(float(c["skill"]) / 60.0, 2.0) * 0.4)
			c["contract_years"] = randi_range(2, 4)
			GameState.add_log("I was drafted by the %s! Contract: %s a year." % [team, GameState.fmt_money(int(c["contract"]))])
			GameState.add_milestone(age, "was drafted by the %s" % team)
			GameState.apply_effects({"happiness": 15, "fame": 6})
		elif age >= 18:
			GameState.add_log("No team drafted me this year. I need to train harder.")
		return 0
	if int(c["injured"]) > 0:
		c["injured"] = int(c["injured"]) - 1
		GameState.add_log("I spent the season recovering from injury.")
		Ambition.sports_yearly(c, p, 25.0)
		return int(c["contract"])
	var perf := float(c["skill"]) + randf_range(-20, 20) + (float(c.get("clutch", 0.5)) - 0.5) * 30.0
	c["clutch"] = 0.5
	if perf > 85:
		GameState.add_log("I had a monster season. The fans chant my name.")
		GameState.apply_effects({"fame": 5, "happiness": 6})
	elif perf < 35:
		GameState.add_log("I had a rough season and the fans let me know it.")
		GameState.apply_effects({"fame": -2, "happiness": -5})
	else:
		GameState.add_log("I had a solid season with the %s." % c["team"])
		GameState.apply_effects({"fame": 1})
	if randf() < 0.08:
		c["injured"] = randi_range(1, 2)
		GameState.add_log("I suffered a serious injury late in the season.")
		GameState.apply_effects({"health": -10})
	if randf() < clampf((float(c["skill"]) - 40) / 200.0, 0.01, 0.35):
		c["titles"] = int(c["titles"]) + 1
		GameState.counter("titles")
		GameState.add_log("WE WON THE CHAMPIONSHIP!")
		GameState.add_milestone(age, "won a %s championship with the %s" % [sport[1].to_lower(), c["team"]])
		GameState.apply_effects({"fame": 10, "happiness": 20})
	Ambition.sports_yearly(c, p, perf)
	c["contract"] = maxi(int(c["contract"]), int(float(sport[2]) * pow(float(c["skill"]) / 60.0, 2.0) * 0.5))
	if age >= 36 or (age >= 30 and float(c["skill"]) < 30):
		GameState.add_log("My body is telling me it's time to retire from %s." % sport[1].to_lower())
		quit("retire")
	return int(c["contract"])


func _reelection(c: Dictionary, p: Dictionary) -> void:
	var office: String = CAREERS["politician"]["ranks"][int(c["rank"])]
	var limit := 2 if int(c["rank"]) == 6 else 99
	if int(c["terms"]) >= limit:
		GameState.add_log("I served my final term as %s." % office)
		c["in_office"] = false
		c["rank"] = maxi(0, int(c["rank"]) - 1)
		return
	var ch := clampf(float(c["approval"]) / 100.0 + 0.1, 0.05, 0.95)
	if randf() < Aptitude.chance(ch,Aptitude.career_context(str(career().get("id","work")))):
		c["term_left"] = 4
		c["terms"] = int(c["terms"]) + 1
		GameState.add_log("I was re-elected as %s with %d%% approval." % [office, int(c["approval"])])
		GameState.apply_effects({"happiness": 8})
	else:
		GameState.add_log("I lost my re-election campaign for %s." % office)
		GameState.add_milestone(p["age"], "lost re-election as %s" % office)
		c["in_office"] = false
		c["rank"] = maxi(0, int(c["rank"]) - 1)
		GameState.apply_effects({"happiness": -10})


func _update_rank() -> void:
	var c := career()
	if c.is_empty() or c["id"] == "politician":
		return
	var d: Dictionary = CAREERS[c["id"]]
	var score := float(c["skill"])
	if c["id"] in ["actor", "musician", "model"]:
		score = float(c["skill"]) * 0.4 + float(GameState.player["fame"]) * 0.6
	if c["id"] == "director":
		score = float(c["skill"]) * 0.55 + float(GameState.player["fame"]) * 0.45
	if c["id"] == "athlete":
		if c["team"] == "":
			return
		score = float(c["skill"])
	var th: Array = d["thresholds"]
	var new_rank := 0
	for i in range(th.size()):
		if score >= float(th[i]):
			new_rank = i
	if c["id"] == "athlete":
		new_rank = maxi(1, new_rank)
	if new_rank > int(c["rank"]):
		c["rank"] = new_rank
		var t := title()
		GameState.add_log("I rose to %s!" % t)
		if new_rank == th.size() - 1:
			GameState.add_milestone(GameState.player["age"], "became %s" % t)
		GameState.apply_effects({"happiness": 6})
	elif c["id"] == "mafia" and new_rank < int(c["rank"]):
		c["rank"] = new_rank
		GameState.add_log("The family demoted me to %s." % title())


# ---------------------------------------------------------------- fame & social media

func followers() -> int:
	return int(pow(float(GameState.player.get("fame", 0)), 2.4) * 60) + int(GameState.player.get("followers", 0))


func _fame_yearly() -> void:
	var p := GameState.player
	var f := float(p["fame"])
	if f <= 0:
		return
	if career().is_empty():
		p["fame"] = maxf(0.0, f - 2.0)
	if f >= 88 and not p["celebrity"]:
		p["celebrity"] = true
		GameState.add_log("I'm officially a celebrity. Strangers recognize me everywhere.")
		GameState.add_milestone(p["age"], "became a household name")
		GameState.apply_effects({"happiness": 8, "stress": 6})
	elif f < 60 and p["celebrity"]:
		p["celebrity"] = false
		GameState.add_log("The spotlight has moved on. People don't recognize me as often.")


func social_action(aid: String) -> void:
	var p := GameState.player
	if int(p["age"]) < 13:
		EventEngine.push_info("📱", "Social media", "You need to be 13 to have an account.")
		return
	if _t(): return
	match aid:
		"photo":
			var gain := randi_range(5, 60) + int(GameState.stat("looks"))
			p["followers"] = int(p["followers"]) + gain
			var shots := ["a sunset selfie", "my breakfast", "a gym mirror photo", "my pet in a hat", "a vacation throwback"]
			_done("📷", "Posted", "I posted %s and gained %s followers." % [shots[randi() % shots.size()], _fmt_big(gain)], {"happiness": 2})
		"video":
			var ch := 0.08 + GameState.stat("looks") / 500.0 + (0.12 if GameState.has_trait("Funny") else 0.0)
			if randf() < Aptitude.chance(ch,Aptitude.career_context(str(career().get("id","work")))):
				var gain2 := randi_range(20000, 400000)
				p["followers"] = int(p["followers"]) + gain2
				GameState.counter("viral")
				_done("🔥", "Viral!", "My video went viral! %s new followers overnight." % _fmt_big(gain2), {"fame": randi_range(4, 12), "happiness": 10})
			else:
				var g := randi_range(10, 300)
				p["followers"] = int(p["followers"]) + g
				_done("🎥", "Posted", "I posted a video. %d people watched it, mostly my family." % (g * 3), {"happiness": 1})
		"live":
			var viewers := int(followers() * randf_range(0.01, 0.05)) + randi_range(1, 30)
			var tips := int(viewers * randf_range(0.02, 0.2))
			_done("🔴", "Live stream", "I went live for three hours. %s viewers peaked, and chat tipped %s." % [_fmt_big(viewers), GameState.fmt_money(tips)], {"money": tips, "fame": 1 if viewers > 1000 else 0, "stress": 2})
		"brand":
			if float(p["fame"]) < 30:
				_done("🤝", "Brand deal", "No brands are interested yet. Grow your following first.", {})
				return
			var pay := int(float(p["fame"]) * 2500 * randf_range(0.6, 1.5))
			var brands := ["an energy drink", "a phone case company", "a meal kit service", "a skincare line", "a mobile game"]
			_done("🤝", "Brand deal", "I posted a sponsored ad for %s and made %s." % [brands[randi() % brands.size()], GameState.fmt_money(pay)], {"money": pay, "fame": -1})


# ---------------------------------------------------------------- minigame results

func resolve_play(score: float, detail: Dictionary, pl: Dictionary) -> void:
	var p := GameState.player
	var c := career()
	if not c.is_empty(): score=clampf(score+(Aptitude.score(Aptitude.career_context(str(c["id"]))) - 50)*0.002,0,1)
	var grade := Minigames.grade(score)
	var kind: String = pl.get("kind", "")
	if NewCareers.handles(kind):
		NewCareers.resolve(kind, score, detail, pl)
		_update_rank()
		GameState.emit_changed()
		return
	if Empires.handles(kind):
		Empires.resolve(kind, score, detail, pl)
		GameState.emit_changed()
		return
	if Lives.handles(kind):
		Lives.resolve(kind, score, detail, pl)
		return
	if Prison.handles(kind):
		Prison.resolve(kind, score, detail, pl)
		return
	match kind:
		"actor_audition":
			if c.is_empty():
				return
			var chance := clampf(float(pl["chance"]) * (0.35 + score * 1.1), 0.02, 0.97)
			if _modifier("star_power"):
				chance = 1.0
			if randf() < Aptitude.chance(chance,Aptitude.career_context(str(career().get("id","work")))):
				var role := random_title()
				var pay := int(int(pl["pay"]) * (0.8 + 0.4 * score))
				c["roles"].append({"title": role, "tier": pl["tier"], "pay": pay, "perf": score})
				_done("🎭", "You got the part!", "Audition: %s. I landed a part in the %s \"%s\"!" % [grade, str(pl["tier"]).to_lower(), role], {"money": pay, "fame": int(pl["fame"]), "skill": 2 + int(score * 3), "happiness": 6})
			else:
				var why := "They said I wasn't right for it." if score >= 0.5 else "I flubbed the read."
				_done("🎭", "No callback", "Audition: %s. %s" % [grade, why], {"happiness": -4, "skill": 1})
		"music_gig", "music_tour":
			if c.is_empty():
				return
			var tour := kind == "music_tour"
			var base := pow(maxf(float(p["fame"]), 4.0), 2.0) * (500.0 if tour else 25.0) + (0.0 if tour else 150.0)
			var gross := int(base * (0.3 + score * 1.2))
			var fame_gain := (2 + int(score * 4)) if tour else (1 if score >= 0.6 else 0)
			var who: String = c.get("band", "") if c.get("band", "") != "" else "I"
			var text := ""
			if score >= 0.85:
				text = "%s played the show of a lifetime. The crowd screamed every word." % who
			elif score >= 0.5:
				text = "%s played a tight set. The crowd was happy." % who
			else:
				text = "%s had a rough night on stage. Some people left early." % who
			if tour:
				text = text.replace("the show of a lifetime", "a legendary tour").replace("a tight set", "a solid tour").replace("a rough night on stage", "a rough tour")
			text += " We made %s." % GameState.fmt_money(gross)
			var fx := {"money": gross, "fame": fame_gain, "skill": 1 + int(score * 3), "stress": 6 if tour else 2}
			if tour:
				fx["health"] = -2
			if score < 0.35:
				fx["fame"] = -1
			_done("🎤" if not tour else "🚌", "Live Set: " + grade, text, fx)
		"big_game":
			if c.is_empty():
				return
			c["clutch"] = score
			var sport: Array = SPORTS[c["sport"]]
			if score >= 0.85:
				GameState.counter("clutch_heroics")
				_done(sport[0], "Clutch!", "I took over the big game and won it at the buzzer. The highlight is everywhere.", {"fame": 6, "skill": 3, "happiness": 10})
			elif score >= 0.5:
				_done(sport[0], "Big game: " + grade, "I played well in the big game and we won.", {"fame": 2, "skill": 2, "happiness": 4})
			else:
				_done(sport[0], "Big game: " + grade, "I choked in the big game. The fans won't forget it soon.", {"fame": -3, "happiness": -6, "stress": 6})
		"campaign":
			if c.is_empty():
				return
			var ch := clampf(float(pl["chance"]) + (score - 0.5) * 0.5, 0.03, 0.96)
			var spend := int(pl["spend"])
			var office: String = pl["office"]
			GameState.apply_effects({"money": -spend})
			if randf() < Aptitude.chance(ch,Aptitude.career_context(str(career().get("id","work")))):
				take_office(int(pl["target"]))
				_done("🗳️", "Victory!", "Debate: %s. I won the race for %s!" % [grade, office], {"happiness": 15, "fame": 2 + int(pl["target"]) * 2, "approval": 5})
			else:
				_done("🗳️", "Defeat", "Debate: %s. I lost the race for %s." % [grade, office], {"happiness": -10, "stress": 6})
		"tv_debate":
			if c.is_empty():
				return
			var swing := int((score - 0.5) * 24)
			_done("🎙️", "Debate: " + grade, "The televised debate %s. Approval %s%d." % ["went brilliantly" if score >= 0.7 else ("was a draw" if score >= 0.45 else "was a disaster"), "+" if swing >= 0 else "", swing], {"approval": swing, "fame": 2, "skill": 2})
		"vault":
			if c.is_empty():
				return
			if detail.get("found", 3 if score >= 0.7 else 0) >= 3 or score >= 0.7:
				var amt := int((40000 + float(c["skill"]) * 2500) * (0.6 + score))
				_done("🔐", "The vault is open", "Safecracking: %s. I cracked the vault. My cut: %s." % [grade, GameState.fmt_money(amt)], {"money": amt, "respect": 8, "heat": 12, "karma": -6})
			elif detail.get("tripped", false) or score < 0.25:
				GameState.apply_effects({"heat": 20})
				GameState.add_log("The vault alarm went off. The cops were there in minutes.")
				Law.trial("burglary", 2, 8)
			else:
				_done("🔐", "Empty-handed", "Safecracking: %s. We ran out of time and got out with nothing." % grade, {"respect": -5, "heat": 6})
		"pickpocket":
			if c.is_empty():
				return
			var lifted := int(detail.get("lifted", int(round(score * 3))))
			var caught_n := int(detail.get("caught", 1 if score < 0.2 else 0))
			var amt := lifted * randi_range(60, 260) + int(float(c["skill"]) * 4 * lifted)
			if caught_n > 0 and randf() < 0.5:
				p["record"].append("petty theft")
				_done("🚓", "Busted", "I got %d wallet%s, but a mark called the police. I paid a $600 fine." % [lifted, "" if lifted == 1 else "s"], {"money": amt - 600, "cred": -2, "heat": 12})
			else:
				_done("👛", "Pickpocket: " + grade, "I lifted %d wallet%s worth %s." % [lifted, "" if lifted == 1 else "s", GameState.fmt_money(amt)], {"money": amt, "cred": 2 + lifted, "heat": 3 + lifted * 2, "karma": -2 * lifted})
	_update_rank()
	GameState.emit_changed()

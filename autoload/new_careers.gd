extends Node

## Astronaut, Model, Fighter, Director and Secret Agent. The registry entries
## live in Careers.CAREERS; this file holds their rules.

const KINDS := ["docking", "runway", "fight", "director_budget", "director_cast", "onset", "infiltrate", "agent_asset"]
const WEIGHT_CLASSES := ["Flyweight", "Lightweight", "Welterweight", "Middleweight", "Heavyweight"]
const FIGHTER_NICKS := ["\"The Hammer\"", "\"Lightning\"", "\"The Wall\"", "\"Iron Jaw\"", "\"Silk\"", "\"The Surgeon\"", "\"Bulldozer\"", "\"Ghost\""]
const MISSIONS := ["resupply the orbital station", "repair a failing satellite", "deliver a new lab module", "rescue a stranded crew", "test a lunar lander"]
const AGENT_OPS := ["steal a weapons blueprint", "extract a defector", "plant a tracker in an embassy", "recover stolen codes", "photograph a smuggler's ledger"]
const SCIENCE_MAJORS := ["engineering", "computer_science", "biology", "phd", "medicine"]
const SPY_MAJORS := ["criminal_justice", "political_science", "computer_science", "economics"]
const MEDIA_MAJORS := ["communications", "english", "graphic_design", "music"]


func handles(kind: String) -> bool:
	return KINDS.has(kind)


func _has_major(list: Array) -> bool:
	for d in GameState.player["education"]["degrees"]:
		if list.has(d["major"]):
			return true
	return false


func _was_military_or_police() -> bool:
	var p := GameState.player
	var hist: Array = p["job_history"]
	var mil := ["Private", "Corporal", "Sergeant", "Lieutenant", "Captain", "Major", "Colonel", "General", "Seaman", "Petty Officer", "Airman", "Police Officer", "Detective", "Police Chief"]
	for h in hist:
		for m in mil:
			if str(h).find(m) != -1:
				return true
	if GameState.has_job() and p["job"]["field"] in ["Military", "Public Safety"]:
		return true
	return false


func requirement(id: String) -> String:
	var p := GameState.player
	var age: int = p["age"]
	var d: Dictionary = Careers.CAREERS[id]
	if d.has("max_start") and age > int(d["max_start"]):
		return "Too old to start (by %d)" % int(d["max_start"])
	match id:
		"astronaut":
			if not p["record"].is_empty():
				return "Needs a clean record"
			if not (_has_major(SCIENCE_MAJORS) or _was_military_or_police() or Meta.has_mod("golden_diploma")):
				return "Needs a science/engineering degree or a military background"
			if GameState.stat("smarts") < 65:
				return "Needs Smarts 65+"
			if GameState.stat("health") < 70:
				return "Needs Health 70+"
		"model":
			var need := 55.0 if GameState.has_trait("Charmer") else 65.0
			if GameState.stat("looks") < need:
				return "Needs Looks %d+" % int(need)
		"fighter":
			if GameState.stat("health") < 65:
				return "Needs Health 65+"
		"director":
			if not (Careers.past("actor") or _has_major(MEDIA_MAJORS) or float(p["fame"]) >= 40 or Web.contact(["producer"], 60) != "" or Meta.has_mod("golden_diploma")):
				return "Needs acting experience, a media degree, fame 40+ or a producer friend"
		"agent":
			if not p["record"].is_empty() or int(p["prison_total"]) > 0:
				return "Needs a spotless record"
			if not (_has_major(SPY_MAJORS) or _was_military_or_police() or Meta.has_mod("golden_diploma")):
				return "Needs a relevant degree or a military/police background"
			if GameState.stat("smarts") < 60:
				return "Needs Smarts 60+"
	return ""


func start(id: String, c: Dictionary, _mode: String) -> String:
	var p := GameState.player
	match id:
		"astronaut":
			c["skill"] = 12.0 + GameState.stat("smarts") * 0.12 + (10.0 if _was_military_or_police() else 0.0)
			c["missions"] = 0
			c["mission_year"] = -1
			return "I was selected for the astronaut training program."
		"model":
			c["skill"] = 10.0 + GameState.stat("looks") * 0.15
			c["agency"] = false
			c["shows"] = 0
			return "I signed up with a modeling scout and started building my portfolio."
		"fighter":
			c["skill"] = 12.0 + GameState.stat("health") * 0.1 + (10.0 if GameState.has_trait("Athletic") else 0.0) + (10.0 if Careers.past("athlete") else 0.0) + (8.0 if Careers.past("hustler") else 0.0)
			c["wins"] = 0
			c["losses"] = 0
			c["belts"] = 0
			c["camp"] = false
			c["class"] = WEIGHT_CLASSES[randi() % WEIGHT_CLASSES.size()]
			c["nick"] = FIGHTER_NICKS[randi() % FIGHTER_NICKS.size()]
			return "I started training as a %s fighter. They call me %s." % [str(c["class"]).to_lower(), c["nick"]]
		"director":
			c["skill"] = 15.0 + (15.0 if Careers.past("actor") else 0.0) + GameState.stat("smarts") * 0.05
			c["films"] = []
			c["project"] = {}
			c["awards"] = 0
			return "I picked up a camera and decided to become a director."
		"agent":
			c["skill"] = 18.0 + GameState.stat("smarts") * 0.1 + (8.0 if _was_military_or_police() else 0.0)
			c["cover"] = ["an insurance consultant", "a travel writer", "an IT contractor", "a wine importer"][randi() % 4]
			c["suspicion"] = 0.0
			c["assets"] = []
			c["ops"] = 0
			return "I was recruited by the intelligence service. My cover: I'm %s." % c["cover"]
	return ""


# ---------------------------------------------------------------- actions

func actions(c: Dictionary) -> Array:
	var p := GameState.player
	var out: Array = []
	var yr := GameState.year_now()
	match c["id"]:
		"astronaut":
			out.append({"id": "a_train", "name": "Centrifuge & flight training", "icon": "🌀", "sub": "Flight skill"})
			out.append({"id": "a_mission", "name": "Fly a mission", "icon": "🚀", "sub": "🎮 Minigame · once a year · needs rank Astronaut", "off": int(c["rank"]) < 1 or int(c["mission_year"]) == yr})
			out.append({"id": "a_research", "name": "Publish research", "icon": "🔬", "sub": "Smarts and a little fame"})
			out.append({"id": "a_outreach", "name": "Visit a school", "icon": "🏫", "sub": "Karma and fame"})
		"model":
			out.append({"id": "m_shoot", "name": "Photoshoot", "icon": "📸", "sub": "Money and presence"})
			out.append({"id": "m_runway", "name": "Walk a runway show", "icon": "💃", "sub": "🎮 Minigame · fame"})
			out.append({"id": "m_portfolio", "name": "Build your portfolio ($500)", "icon": "🗂️", "sub": "Presence"})
			out.append({"id": "m_agency", "name": "Sign with a top agency", "icon": "🏷️", "sub": "Signed" if c["agency"] else "Better bookings", "off": c["agency"]})
			out.append({"id": "m_campaign", "name": "Land a brand campaign", "icon": "👜", "sub": "Needs fame 20+", "off": float(p["fame"]) < 20})
		"fighter":
			out.append({"id": "f_fight", "name": "Take a fight", "icon": "🥊", "sub": "🎮 Minigame · record %d-%d" % [int(c["wins"]), int(c["losses"])]})
			out.append({"id": "f_gym", "name": "Train at the gym", "icon": "🏋️", "sub": "Fighting skill"})
			out.append({"id": "f_camp", "name": "Go to fight camp ($3,000)", "icon": "⛺", "sub": "Big bonus for your next fight", "off": c["camp"]})
			out.append({"id": "f_talk", "name": "Trash talk your next opponent", "icon": "🗯️", "sub": "Fame, makes a rival"})
			out.append({"id": "f_rest", "name": "Rest and recover", "icon": "🛌", "sub": "Health"})
		"director":
			var pr: Dictionary = c["project"]
			if pr.is_empty():
				out.append({"id": "d_develop", "name": "Develop a new film", "icon": "📝", "sub": "Pick a budget and write the script"})
			elif not pr.has("lead"):
				out.append({"id": "d_cast", "name": "Cast the lead for \"%s\"" % pr["title"], "icon": "🎭", "sub": "Yourself, someone you know, or a star"})
			elif not pr.has("shot"):
				out.append({"id": "d_shoot", "name": "Shoot \"%s\"" % pr["title"], "icon": "🎬", "sub": "🎮 Minigame · sets the film's quality"})
			else:
				out.append({"id": "d_wait", "name": "\"%s\" premieres next year" % pr["title"], "icon": "🍿", "sub": "In post-production", "off": true})
			out.append({"id": "d_festival", "name": "Screen at a film festival", "icon": "🎞️", "sub": "Directing skill and fame", "off": c["films"].is_empty()})
			out.append({"id": "d_class", "name": "Study the classics", "icon": "📚", "sub": "Directing skill"})
		"agent":
			out.append({"id": "s_mission", "name": "Go on a mission", "icon": "🕵️", "sub": "🎮 Minigame · pay and rank"})
			out.append({"id": "s_asset", "name": "Recruit an asset", "icon": "🤝", "sub": "Turn someone you know into an informant"})
			out.append({"id": "s_gadget", "name": "Train in the gadget lab", "icon": "🔧", "sub": "Tradecraft"})
			out.append({"id": "s_cover", "name": "Shore up your cover story", "icon": "🎭", "sub": "Family suspicion %d%%" % int(c["suspicion"])})
			if p["partner"] != "":
				out.append({"id": "s_confess", "name": "Tell %s the truth" % GameState.npc(p["partner"]).get("first", "your partner"), "icon": "🤫", "sub": "Risky"})
	return out


func _t() -> bool:
	return Careers._t()


func _done(icon: String, title_txt: String, text: String, effects: Dictionary = {}) -> void:
	Careers._done(icon, title_txt, text, effects)


func _play(id: String, c: Dictionary, extra: Dictionary) -> void:
	var params := {"skill": float(c["skill"]), "difficulty": 0.8 + int(c["rank"]) * 0.1}
	params.merge(extra.get("params", {}), true)
	var pl := extra.duplicate(true)
	pl.erase("params")
	Minigames.play(id, params, Callable(Careers, "resolve_play").bind(pl))


func do_action(aid: String, c: Dictionary, p: Dictionary) -> void:
	match aid:
		# ---- astronaut
		"a_train":
			if _t(): return
			if randf() < 0.06:
				_done("🌀", "Training", "I blacked out in the centrifuge. The flight surgeon benched me for a month.", {"health": -5, "stress": 5, "skill": 1})
			else:
				_done("🌀", "Training", "I aced my flight and survival training.", {"skill": 5, "health": 2, "stress": 3})
		"a_mission":
			if _t(): return
			c["mission_year"] = GameState.year_now()
			var m: String = MISSIONS[randi() % MISSIONS.size()]
			_play("docking", c, {"kind": "docking", "mission": m})
		"a_research":
			if _t(): return
			_done("🔬", "Research", "I published a paper on %s." % ["bone loss in microgravity", "growing lettuce in orbit", "cosmic ray shielding", "sleep in space"][randi() % 4], {"smarts": 3, "fame": 1, "skill": 2})
		"a_outreach":
			if _t(): return
			_done("🏫", "School visit", "I told a gym full of kids what Earth looks like from orbit. One of them cried.", {"karma": 4, "fame": 2, "happiness": 5})
		# ---- model
		"m_shoot":
			if _t(): return
			var pay := int((600 + float(c["skill"]) * 60 + float(p["fame"]) * 400) * (1.5 if c["agency"] else 1.0) * randf_range(0.7, 1.3))
			_done("📸", "Photoshoot", "I shot a %s spread and made %s." % [["swimwear", "streetwear", "perfume", "catalog", "magazine"][randi() % 5], GameState.fmt_money(pay)], {"money": pay, "skill": 2, "looks": 1})
		"m_runway":
			if _t(): return
			_play("runway", c, {"kind": "runway", "params": {"difficulty": 0.8 + int(c["rank"]) * 0.12}})
		"m_portfolio":
			if _t(): return
			if int(p["money"]) < 500:
				EventEngine.push_info("💸", "Portfolio", "A good photographer costs $500.")
				return
			_done("🗂️", "Portfolio", "I paid a top photographer to build my portfolio.", {"money": -500, "skill": 6})
		"m_agency":
			if _t(): return
			if float(c["skill"]) + GameState.stat("looks") * 0.4 + float(p["fame"]) > 70 or Meta.has_mod("star_power"):
				c["agency"] = true
				GameState.add_milestone(p["age"], "signed with a top modeling agency")
				_done("🏷️", "Signed!", "A top modeling agency signed me.", {"happiness": 8, "fame": 2})
			else:
				_done("🏷️", "Not yet", "The agency said to come back when I have more experience.", {"happiness": -3})
		"m_campaign":
			if _t(): return
			var pay2 := int(float(p["fame"]) * 3500 * randf_range(0.6, 1.4))
			var brand: String = ["a luxury perfume", "a sneaker giant", "a jewelry house", "a phone maker"][randi() % 4]
			_done("👜", "Campaign", "I became the face of %s for %s." % [brand, GameState.fmt_money(pay2)], {"money": pay2, "fame": 3})
		# ---- fighter
		"f_fight":
			if _t(): return
			var opp := GameState.create_npc("rival", {"age": int(p["age"]) + randi_range(-4, 4), "gender": p["gender"] if p["gender"] != "nonbinary" else "male", "closeness": 25})
			var on: String = GameState.full_name(opp)
			if Meta.has_mod("brass_knuckles"):
				Careers.resolve_play(1.0, {"won": true, "ko": true}, {"kind": "fight", "opp": opp})
				return
			var bonus := 0.15 if c["camp"] else 0.0
			c["camp"] = false
			_play("fight", c, {"kind": "fight", "opp": opp, "params": {"opponent": on, "difficulty": clampf(0.85 + int(c["rank"]) * 0.1 - bonus, 0.6, 1.5)}})
		"f_gym":
			if _t(): return
			if randf() < 0.07:
				_done("🤕", "Sparring", "I got rocked in sparring and needed stitches.", {"health": -8, "skill": 2})
			else:
				_done("🏋️", "Training", "I sparred hard and hit the bag for hours.", {"skill": 4, "health": 2, "stress": -2})
		"f_camp":
			if _t(): return
			if int(p["money"]) < 3000:
				EventEngine.push_info("💸", "Fight camp", "Fight camp costs $3,000.")
				return
			c["camp"] = true
			_done("⛺", "Fight camp", "I spent six weeks at a mountain fight camp. I've never been sharper.", {"money": -3000, "skill": 3, "health": 3})
		"f_talk":
			if _t(): return
			var rv := GameState.create_npc("rival", {"age": int(p["age"]) + randi_range(-3, 3), "closeness": 10})
			_done("🗯️", "Trash talk", "I called %s a \"paper champion\" at the press conference. The internet exploded." % GameState.full_name(rv), {"fame": 3, "karma": -2})
		"f_rest":
			if _t(): return
			_done("🛌", "Recovery", "I took time off to let my body heal.", {"health": 8, "stress": -6})
		# ---- director
		"d_develop":
			if _t(): return
			var choices: Array = []
			var tiers := [["Micro-budget indie", 20000, 0, "self"], ["Indie feature", 250000, 1, "self"], ["Studio film", 12000000, 2, "studio"], ["Blockbuster", 90000000, 3, "studio"]]
			for t in tiers:
				if int(c["rank"]) < int(t[2]):
					continue
				var who_pays := "you pay %s" % GameState.fmt_money(int(t[1])) if t[3] == "self" else "the studio pays"
				var ch := {"label": "%s (%s)" % [t[0], who_pays], "outcomes": [{"text": "", "play": {"id": "choice", "kind": "director_budget", "tier": t[0], "budget": int(t[1]), "self_funded": t[3] == "self"}}]}
				if t[3] == "self":
					ch["requires"] = {"money": int(t[1])}
				choices.append(ch)
			choices.append({"label": "Not now", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_film_budget", "icon": "📝", "title": "A new film", "text": "What kind of film are you making?", "choices": choices})
		"d_cast":
			if _t(): return
			_cast_menu(c)
		"d_shoot":
			if _t(): return
			_play("onset", c, {"kind": "onset", "params": {"difficulty": 0.8 + int(c["rank"]) * 0.1}})
		"d_festival":
			if _t(): return
			if randf() < 0.3 + float(c["skill"]) / 250.0:
				_done("🎞️", "Festival", "My film won the audience award at a film festival!", {"fame": 5, "skill": 4, "happiness": 8})
			else:
				_done("🎞️", "Festival", "My film screened at a festival to polite applause.", {"fame": 1, "skill": 2})
		"d_class":
			if _t(): return
			_done("📚", "Film study", "I watched a hundred classic films and took notes on every shot.", {"skill": 4, "smarts": 1})
		# ---- agent
		"s_mission":
			if _t(): return
			var op: String = AGENT_OPS[randi() % AGENT_OPS.size()]
			var target := ""
			if Careers.past("mafia") and randf() < 0.4:
				op = "take down the crime family you used to run with"
				target = "old_family"
			_play("infiltrate", c, {"kind": "infiltrate", "op": op, "target": target, "params": {"map": randi() % 3, "difficulty": 0.8 + int(c["rank"]) * 0.12}})
		"s_asset":
			if _t(): return
			var choices2: Array = []
			var roles := {}
			var n := 0
			for id in GameState.npcs.keys():
				var nn: Dictionary = GameState.npcs[id]
				if not nn["alive"] or nn.get("species", "human") != "human" or c["assets"].has(id) or int(nn["age"]) < 18:
					continue
				if nn["relation"] in ["friend", "best_friend", "coworker", "neighbor", "ex", "former_coworker", "tenant", "classmate", "rival", "sibling", "auntuncle"]:
					n += 1
					roles["r%d" % n] = id
					choices2.append({"label": "%s (%s, %s)" % [GameState.full_name(id), GameState.relation_label(id), Web.job_title(id).to_lower() if Web.job_title(id) != "" else "?"], "outcomes": [{"text": "", "play": {"id": "choice", "kind": "agent_asset", "npc": id}}]})
					if n >= 6:
						break
			if choices2.is_empty():
				EventEngine.push_info("🤝", "Assets", "You don't know anyone useful to recruit yet.")
				return
			choices2.append({"label": "Never mind", "outcomes": [{"text": ""}]})
			EventEngine.push_decision({"id": "_asset", "icon": "🤝", "title": "Recruit an asset", "text": "An informant inside someone's life is worth a dozen gadgets. Who do you approach?", "choices": choices2}, roles)
		"s_gadget":
			if _t(): return
			_done("🔧", "Gadget lab", "I learned to use a %s." % ["pen that's also a lockpick", "watch with a hidden camera", "shoe with a GPS tracker", "lipstick that jams radios"][randi() % 4], {"skill": 4})
		"s_cover":
			if _t(): return
			c["suspicion"] = maxf(0.0, float(c["suspicion"]) - 25.0)
			_done("🎭", "Cover story", "I invited the family to a boring \"work\" dinner. Nobody suspects a thing.", {"stress": -2})
		"s_confess":
			if _t(): return
			var pid: String = p["partner"]
			if int(GameState.npcs[pid]["closeness"]) >= 70 and randf() < 0.7:
				c["suspicion"] = 0.0
				GameState.change_closeness(pid, 10)
				_done("🤫", "The truth", "I told %s I'm a spy. After a long silence: \"...That explains SO much.\"" % GameState.npcs[pid]["first"], {"happiness": 6, "stress": -8})
			else:
				GameState.change_closeness(pid, -25)
				c["suspicion"] = 0.0
				_done("🤫", "The truth", "I told %s I'm a spy. They thought I was lying to cover an affair." % GameState.npcs[pid]["first"], {"happiness": -8, "stress": 6})


func _cast_menu(c: Dictionary) -> void:
	var pr: Dictionary = c["project"]
	var choices: Array = []
	var roles := {}
	if Careers.past("actor"):
		choices.append({"label": "Cast yourself (you used to act)", "outcomes": [{"text": "", "play": {"id": "choice", "kind": "director_cast", "lead": "self", "power": 0.55 + float(GameState.player["fame"]) / 200.0}}]})
	var n := 0
	for id in GameState.npcs.keys():
		var nn: Dictionary = GameState.npcs[id]
		if not nn["alive"] or nn.get("species", "human") != "human" or int(nn["age"]) < 8:
			continue
		if int(nn["closeness"]) < 40 and not (nn["relation"] in ["ex", "rival"]):
			continue
		var talent := 0.35 + float(nn.get("looks", 50)) / 250.0
		if Web.job_of(id) in ["artist", "agent", "producer"] or nn["relation"] == "coworker":
			talent += 0.15
		n += 1
		roles["c%d" % n] = id
		choices.append({"label": "%s (%s)" % [GameState.full_name(id), GameState.relation_label(id)], "outcomes": [{"text": "", "play": {"id": "choice", "kind": "director_cast", "lead": id, "power": talent}}]})
		if n >= 5:
			break
	var star_fee := int(int(pr["budget"]) * 0.15) + 150000
	choices.append({"label": "Hire a movie star (%s)" % GameState.fmt_money(star_fee), "requires": {"money": star_fee if pr.get("self_funded", true) else 0}, "outcomes": [{"text": "", "play": {"id": "choice", "kind": "director_cast", "lead": "star", "power": 0.9, "fee": star_fee if pr.get("self_funded", true) else 0}}]})
	EventEngine.push_decision({"id": "_film_cast", "icon": "🎭", "title": "Casting \"%s\"" % pr["title"], "text": "Who plays the lead? People you know work cheap and will remember it. Stars sell tickets.", "choices": choices}, roles)


# ---------------------------------------------------------------- results

func resolve(kind: String, score: float, detail: Dictionary, pl: Dictionary) -> void:
	var p := GameState.player
	var c := Careers.career()
	var grade := Minigames.grade(score)
	if c.is_empty():
		return
	match kind:
		"docking":
			if detail.get("crash", false) or score < 0.25:
				if randf() < 0.04:
					GameState.add_log("My capsule hit the station at speed while trying to %s." % pl.get("mission", "dock"))
					EventEngine.kill("a spacecraft accident")
					return
				_done("💥", "Mission failed", "Docking: %s. I botched the docking on a mission to %s. The capsule was damaged and I was injured." % [grade, pl.get("mission", "dock")], {"health": -15, "stress": 15, "fame": -2, "skill": 2})
			else:
				c["missions"] = int(c["missions"]) + 1
				GameState.set_flag("been_to_space")
				if int(c["missions"]) == 1:
					GameState.add_milestone(p["age"], "went to space")
				var bonus := int(25000 * (0.5 + score))
				_done("🚀", "Mission success", "Docking: %s. We launched to %s and I docked perfectly. I've now flown %d mission%s." % [grade, pl.get("mission", "the station"), int(c["missions"]), "" if int(c["missions"]) == 1 else "s"], {"money": bonus, "fame": 4 + int(score * 4), "skill": 5 + int(score * 4), "happiness": 12})
		"runway":
			c["shows"] = int(c["shows"]) + 1
			var show: String = ["a local boutique show", "a department store show", "a big-city fashion week", "the Paris shows", "the season's most exclusive show"][clampi(int(c["rank"]), 0, 4)]
			var pay := int((1500 + int(c["rank"]) * 9000) * (0.4 + score))
			if score >= 0.85:
				_done("💃", "Runway: " + grade, "I owned %s. Every photographer got my walk." % show, {"money": pay, "fame": 5, "skill": 5, "happiness": 8})
			elif score >= 0.45:
				_done("💃", "Runway: " + grade, "I walked %s without a hitch." % show, {"money": pay, "fame": 2, "skill": 3})
			else:
				_done("💃", "Runway: " + grade, "I stumbled at %s. It went viral for the wrong reasons." % show, {"money": pay / 2, "fame": 1, "happiness": -6, "stress": 5})
		"fight":
			var opp: String = pl.get("opp", "")
			var won: bool = detail.get("won", score >= 0.5)
			var on := GameState.full_name(opp) if opp != "" else "my opponent"
			var purse := int((2000 + int(c["rank"]) * 30000 + float(p["fame"]) * 1200) * (1.3 if won else 0.6))
			if won:
				c["wins"] = int(c["wins"]) + 1
				var title_fight := int(c["rank"]) >= 3 and randf() < 0.35
				var text := "Fight Night: %s. I beat %s%s. Record: %d-%d." % [grade, on, " by knockout" if detail.get("ko", false) else " on the judges' cards", int(c["wins"]), int(c["losses"])]
				var fx := {"money": purse, "fame": 3 + int(score * 3), "skill": 4, "happiness": 10, "health": -3}
				if title_fight:
					c["belts"] = int(c["belts"]) + 1
					GameState.counter("titles")
					GameState.add_milestone(p["age"], "won a %s title belt" % str(c["class"]).to_lower())
					text += "\n\nIt was a title fight. I'M THE CHAMPION!"
					fx["fame"] = int(fx["fame"]) + 8
				_done("🏆" if title_fight else "🥊", "Victory!" if not title_fight else "CHAMPION!", text, fx)
				if opp != "":
					GameState.change_closeness(opp, -10)
			else:
				c["losses"] = int(c["losses"]) + 1
				var ko: bool = detail.get("ko", false)
				_done("🤕", "Defeat", "Fight Night: %s. %s beat me%s. Record: %d-%d." % [grade, on, " by knockout" if ko else "", int(c["wins"]), int(c["losses"])] + (Grit.scar_chance("concussions", 0.3) if ko else Grit.scar_chance("facial_scar", 0.06)), {"money": purse, "health": -15 if ko else -7, "happiness": -8, "skill": 2, "fame": -1})
		"director_budget":
			var budget := int(pl["budget"])
			if pl.get("self_funded", true):
				GameState.apply_effects({"money": -budget})
			var genre: String = ["drama", "comedy", "thriller", "horror", "sci-fi epic", "romance", "action movie"][randi() % 7]
			var script_q := clampf(float(c["skill"]) * 0.5 + GameState.stat("smarts") * 0.3 + randf_range(-10, 25), 5, 100)
			c["project"] = {"title": Careers.random_title(), "tier": pl["tier"], "budget": budget, "self_funded": pl.get("self_funded", true), "genre": genre, "script": script_q}
			_done("📝", "Script ready", "I wrote a %s called \"%s\". The script is %s.\n\nNext: cast the lead." % [genre, c["project"]["title"], "brilliant" if script_q > 75 else ("solid" if script_q > 50 else "rough")], {"skill": 2})
		"director_cast":
			var pr: Dictionary = c["project"]
			var lead: String = pl["lead"]
			pr["lead"] = lead
			pr["power"] = float(pl["power"])
			var fee := int(pl.get("fee", 0))
			if fee > 0:
				GameState.apply_effects({"money": -fee})
			var who := "myself" if lead == "self" else ("a famous movie star" if lead == "star" else GameState.full_name(lead))
			if lead != "self" and lead != "star" and GameState.npcs.has(lead):
				GameState.change_closeness(lead, 20)
				pr["lead_name"] = GameState.full_name(lead)
			_done("🎭", "Cast", "I cast %s as the lead in \"%s\".\n\nNext: shoot the film." % [who, pr["title"]], {})
		"onset":
			var pr2: Dictionary = c["project"]
			pr2["shot"] = score
			_done("🎬", "That's a wrap: " + grade, "We wrapped \"%s\". %s It premieres next year." % [pr2["title"], "The dailies look incredible." if score >= 0.7 else ("It came together." if score >= 0.4 else "The shoot was chaos. We'll fix it in post... hopefully.")], {"skill": 3 + int(score * 4), "stress": 6})
		"infiltrate":
			if detail.get("success", score >= 0.6):
				c["ops"] = int(c["ops"]) + 1
				var pay2 := int((8000 + int(c["rank"]) * 15000) * (0.6 + score))
				var txt := "Infiltration: %s. I got in, managed to %s, and got out without a trace." % [grade, pl.get("op", "complete the op")]
				if pl.get("target", "") == "old_family":
					txt += "\n\nMy old crime family is in handcuffs. Some of them know my face."
					GameState.set_flag("betrayed_family")
					GameState.followups.append({"event": "agent.revenge", "age": int(p["age"]) + randi_range(2, 6), "roles": {}, "retries": 0})
				if int(c["ops"]) == 5:
					GameState.add_milestone(p["age"], "completed five classified missions")
				_done("🕵️", "Mission accomplished", txt, {"money": pay2, "skill": 5 + int(score * 4), "happiness": 8, "stress": 6})
			elif detail.get("intel", false):
				_done("🕵️", "Partial success", "Infiltration: %s. I got the intel but was spotted on the way out. I had to fight my way clear." % grade, {"skill": 3, "health": -10, "stress": 12})
			else:
				c["suspicion"] = float(c["suspicion"]) + 10.0
				_done("🚨", "Blown", "Infiltration: %s. I was spotted before I reached the intel. The op was scrubbed and I barely escaped." % grade, {"health": -12, "stress": 15, "skill": 1})
		"agent_asset":
			var id: String = pl["npc"]
			if not GameState.npcs.has(id):
				return
			var nn: Dictionary = GameState.npcs[id]
			var ch := 0.3 + int(nn["closeness"]) / 200.0 + (0.1 if GameState.has_trait("Charmer") else 0.0)
			if randf() < ch:
				c["assets"].append(id)
				GameState.change_closeness(id, -5)
				_done("🤝", "New asset", "%s agreed to pass me information. Their job as %s will be useful." % [nn["first"], Web.job_title(id).to_lower() if Web.job_title(id) != "" else "whatever they do"], {"skill": 4, "karma": -2})
			else:
				GameState.change_closeness(id, -20)
				c["suspicion"] = float(c["suspicion"]) + 15.0
				_done("🤝", "Refused", "%s looked at me like I'd grown a second head. They're telling people I'm acting strange." % nn["first"], {"stress": 5})


# ---------------------------------------------------------------- yearly

func yearly(c: Dictionary, p: Dictionary) -> int:
	var age: int = p["age"]
	var income := 0
	match c["id"]:
		"astronaut":
			income = [65000, 90000, 115000, 145000, 180000][int(c["rank"])]
			if age >= 58:
				GameState.add_log("I hung up my flight suit after %d missions." % int(c["missions"]))
				Careers.quit("retire")
				if int(c["missions"]) >= 3:
					GameState.followups.append({"event": "astro.memoir", "age": age + 1, "roles": {}, "retries": 0})
		"model":
			income = int((4000 + float(c["skill"]) * 350 + float(p["fame"]) * 900) * (1.4 if c["agency"] else 1.0))
			if age >= 32:
				c["skill"] = maxf(0.0, float(c["skill"]) - randf_range(2.0, 5.0))
				GameState.change_stat("looks", -1.0)
			if age >= 38 or GameState.stat("looks") < 45:
				GameState.add_log("The bookings dried up. My modeling days are over.")
				Careers.quit("retire")
				EventEngine.push_info("💃", "Next chapter", "My modeling career has ended.\n\nFormer models get a head start as actors. Special Careers → Actor.")
		"fighter":
			income = int(float(p["fame"]) * 1500)
			if age >= 33:
				c["skill"] = maxf(0.0, float(c["skill"]) - randf_range(2.0, 6.0))
			if age >= 39 or (int(c["losses"]) >= 8 and int(c["losses"]) > int(c["wins"])):
				GameState.add_log("I retired from fighting with a %d-%d record and %d belt%s." % [int(c["wins"]), int(c["losses"]), int(c["belts"]), "" if int(c["belts"]) == 1 else "s"])
				Careers.quit("retire")
		"director":
			var pr: Dictionary = c["project"]
			if pr.has("shot"):
				income = _release(c, pr, p)
				c["project"] = {}
			income += int(float(c["skill"]) * 400)
		"agent":
			income = [55000, 80000, 110000, 150000, 210000][int(c["rank"])]
			c["suspicion"] = minf(100.0, float(c["suspicion"]) + randf_range(4.0, 12.0))
			if float(c["suspicion"]) >= 60 and p["partner"] != "" and randf() < 0.5:
				GameState.change_closeness(p["partner"], -15)
				GameState.add_log("%s asked where I really go on my \"business trips\". I lied again." % GameState.npc(p["partner"]).get("first", "My partner"))
				GameState.apply_effects({"stress": 6})
			for aid in c["assets"]:
				if GameState.npcs.has(aid) and GameState.npcs[aid]["alive"]:
					c["skill"] = minf(100.0, float(c["skill"]) + 1.0)
			if age >= 60:
				Careers.quit("retire")
	return income


func _release(c: Dictionary, pr: Dictionary, p: Dictionary) -> int:
	var quality := clampf(float(pr["script"]) * 0.35 + float(pr["shot"]) * 100.0 * 0.4 + float(pr.get("power", 0.5)) * 100.0 * 0.25 + randf_range(-12, 12), 0, 100)
	var budget := int(pr["budget"])
	var mult := 0.2 + pow(quality / 60.0, 2.2) * (1.0 + float(p["fame"]) / 80.0)
	var gross := int(budget * mult * randf_range(0.7, 1.3)) + int(randi_range(5000, 40000) * (quality / 50.0))
	var profit := gross - budget
	var share := 0
	if pr.get("self_funded", true):
		share = gross
	else:
		share = int(maxf(0.0, profit) * 0.08) + int(budget * 0.02)
	var verdict := "a flop"
	if quality >= 82:
		verdict = "a masterpiece"
	elif quality >= 65:
		verdict = "a hit"
	elif quality >= 45:
		verdict = "a modest success"
	c["films"].append({"title": pr["title"], "genre": pr["genre"], "gross": gross, "quality": int(quality), "year": GameState.year_now()})
	var who := ""
	if pr.get("lead", "") == "self":
		who = " I starred in it myself."
		GameState.apply_effects({"fame": 3})
	elif pr.has("lead_name"):
		who = " %s's performance in the lead turned heads." % pr["lead_name"]
		if GameState.npcs.has(pr["lead"]):
			GameState.change_closeness(pr["lead"], 10 if quality >= 50 else -10)
	GameState.add_log("My %s \"%s\" premiered: %s, grossing %s.%s" % [pr["genre"], pr["title"], verdict, GameState.fmt_money(gross), who])
	var fx := {"skill": 3, "fame": 1}
	if quality >= 65:
		fx["fame"] = 6
		fx["happiness"] = 8
	elif quality < 45:
		fx["fame"] = -2
		fx["happiness"] = -8
	GameState.apply_effects(fx)
	if quality >= 82 and randf() < 0.5:
		c["awards"] = int(c["awards"]) + 1
		GameState.counter("awards")
		GameState.add_log("\"%s\" won Best Picture! I thanked everyone I've ever met." % pr["title"])
		GameState.add_milestone(p["age"], "won Best Picture for \"%s\"" % pr["title"])
		GameState.apply_effects({"fame": 10, "happiness": 15})
	return share

extends Node

## DECLINE — what happens when a stat is genuinely failing, and what you lose
## by not keeping it up.
##
## Two things were missing and they are the same thing.
##
## Smarts only ever went up. Study raised it, nothing lowered it before 75, so
## a life that never opened a book kept whatever it was born with forever. That
## made education optional in the only sense that matters.
##
## And nothing escalated. Health at 8% read exactly like health at 80%: the
## same random events, no warning, and then one year the death roll came up and
## it was over with no run-up. A life should tell you it is ending.

## How fast an unused stat slides, per year, at full effect.
const DRIFT := {
	"smarts": 0.9,
	"looks": 0.7,
	"health": 0.0,   # health already has its own age curve in _yearly_body
}

## Which routine or activity counts as keeping a stat up.
const KEPT_BY := {
	"smarts": ["study", "read"],
	"looks": ["gym", "walk"],
}


func _p() -> Dictionary:
	return GameState.player


# ---------------------------------------------------------------- disuse

## Smarts decay. In school it is slower, because school is doing some of the
## work whether you pay attention or not. After education ends, nothing is.
func _disuse() -> void:
	var p := _p()
	var age := int(p.get("age", 0))
	if age < 6:
		return
	var routines: Dictionary = p.get("routines", {})
	var in_school := str(p.get("education", {}).get("stage", "none")) not in ["none", "done"]

	# --- smarts
	var kept := bool(routines.get("study", false))
	if not kept and not p.get("studied", false):
		var rate := DRIFT["smarts"]
		if in_school:
			rate *= 0.35
		if age >= 70:
			rate *= 1.6
		# A high-smarts life has further to fall and notices it more.
		var sm := GameState.stat("smarts")
		rate *= 0.6 + sm / 100.0
		var job: Dictionary = p.get("job", {})
		if not job.is_empty() and bool(job.get("thinking", false)):
			rate *= 0.5
		GameState.change_stat("smarts", -rate * randf_range(0.6, 1.25))
		var st := _state()
		st["smarts_unused"] = int(st.get("smarts_unused", 0)) + 1
		# Told, but not every single year — a nag is not information.
		if int(st["smarts_unused"]) in [6, 14, 26] and sm > 20.0:
			GameState.add_log("I have not read anything that was not a screen in a very long time.")
	else:
		_state()["smarts_unused"] = 0

	# --- looks, which the game was already letting slide after 35 but only then
	if age >= 18 and age < 35 and not bool(routines.get("gym", false)) and not bool(routines.get("walk", false)):
		if randf() < 0.45:
			GameState.change_stat("looks", -randf_range(0.0, DRIFT["looks"]))


func _state() -> Dictionary:
	var p := _p()
	if not p.has("decline") or not (p["decline"] is Dictionary):
		p["decline"] = {"smarts_unused": 0, "warned": {}, "last_warning_age": -99}
	return p["decline"]


# ---------------------------------------------------------------- the run-up

## Below this, a stat is not low — it is failing, and the world should say so.
const CRITICAL := 15.0
const POOR := 30.0

## One warning beat per stat per band, so it escalates rather than repeats.
const WARNINGS := {
	"health": [
		"I get out of breath on the stairs now. I used to run up them.",
		"The doctor stopped talking about lifestyle and started talking about time.",
		"I can feel it. Something inside me is not working any more.",
	],
	"happiness": [
		"I have stopped looking forward to things. Any things.",
		"I sat in the car outside the house for an hour because going in seemed like a lot.",
		"I do not think I am well. I have not thought so for a while.",
	],
	"smarts": [
		"I read the same paragraph four times and could not hold it.",
		"I lost a word I have used my whole life, in the middle of a sentence.",
		"Somebody explained something simple to me twice and I still did not have it.",
	],
	"looks": [
		"I have stopped catching my own eye in windows.",
		"Somebody guessed my age fifteen years high and was not being unkind.",
	],
}

## Events that only appear when something is genuinely failing. They are not
## random flavour — every one of them leads somewhere.
const CRISES := {
	"health": [
		{"icon": "🫀", "title": "Something is wrong",
		 "text": "You wake up with your heart going far too fast and no reason for it. It settles after twenty minutes. It has happened three times this month.",
		 "choices": [
			{"label": "Go to a hospital tonight",
			 "outcomes": [
				{"text": "They kept me in. They found it in time, and they were clear that another month would have been too late.", "weight": 2, "effects": {"money": -9000, "health": 18, "stress": -10}},
				{"text": "They kept me in for four days, ran everything, and sent me home saying they could not find a cause.", "weight": 1, "effects": {"money": -9000, "stress": 12}}]},
			{"label": "See a doctor in the week",
			 "outcomes": [
				{"text": "The appointment was eleven days out. I went, and the treatment started late but it started.", "weight": 2, "effects": {"money": -1200, "health": 8}},
				{"text": "I waited for the appointment and was in an ambulance before it came round.", "weight": 1, "effects": {"health": -22, "stress": 25, "money": -4000}}]},
			{"label": "Ignore it",
			 "outcomes": [
				{"text": "I ignored it. It stopped on its own, which I have decided to treat as an answer.", "weight": 1, "effects": {"stress": 8}},
				{"text": "I ignored it until it did not stop.", "weight": 2, "effects": {"health": -28, "stress": 25}}]}]},
		{"icon": "🏥", "title": "The conversation",
		 "text": "A doctor you have seen twice before asks you to sit down, and asks whether there is anybody you would like to have here for this.",
		 "choices": [
			{"label": "Ask her to say it plainly",
			 "outcomes": [
				{"text": "She said it plainly. I have some time, and now I know roughly how much.", "weight": 2, "effects": {"stress": 18, "happiness": -14}},
				{"text": "She said it plainly, and then said the newest treatment had changed those numbers considerably.", "weight": 1, "effects": {"health": 14, "stress": 8, "money": -25000}}]},
			{"label": "Ask what the options are",
			 "outcomes": [
				{"text": "There were three. Two of them were about comfort. I chose the one that was not.", "weight": 2, "effects": {"health": 12, "money": -40000, "stress": 15}},
				{"text": "There were no real options left, and she was kind about saying so.", "weight": 1, "effects": {"happiness": -18, "stress": 20}}]},
			{"label": "Say you do not want to know",
			 "outcomes": [
				{"text": "I told her I did not want the numbers. She wrote it in the file and respected it.", "weight": 2, "effects": {"stress": -6, "happiness": -8}},
				{"text": "I said I did not want to know, and then could not stop working it out from what everyone else stopped saying.", "weight": 1, "effects": {"stress": 22, "happiness": -12}}]}]},
	],
	"happiness": [
		{"icon": "🌑", "title": "Somebody noticed",
		 "text": "Somebody who has known you a long time asks, in a car park, not casually, whether you are all right.",
		 "choices": [
			{"label": "Tell them the truth",
			 "outcomes": [
				{"text": "I told them. They did not try to fix it, they just stayed, and something moved.", "weight": 2, "effects": {"happiness": 18, "stress": -14}},
				{"text": "I told them and they did not know what to do with it, and we have both been slightly careful since.", "weight": 1, "effects": {"happiness": 4, "stress": -4}}]},
			{"label": "Say you are fine",
			 "outcomes": [
				{"text": "I said I was fine. They let it go, which was what I had asked for and not what I wanted.", "weight": 2, "effects": {"happiness": -8, "stress": 8}},
				{"text": "I said I was fine and they said they did not believe me, and asked again the following week.", "weight": 1, "effects": {"happiness": 10, "stress": -6}}]},
			{"label": "Ask them to help you find someone to talk to",
			 "outcomes": [
				{"text": "They made the call for me while I sat there, because I could not have made it myself.", "weight": 2, "effects": {"happiness": 22, "stress": -18, "money": -600}},
				{"text": "They helped me find somebody, and the first two were not right, and the third one was.", "weight": 1, "effects": {"happiness": 16, "stress": -12, "money": -2400}}]}]},
	],
	"smarts": [
		{"icon": "🧩", "title": "The appointment you did not make",
		 "text": "Somebody in your family has quietly booked you a memory assessment, and told you about it afterwards.",
		 "choices": [
			{"label": "Go",
			 "outcomes": [
				{"text": "I went. It was a bad hour and the answer was manageable and early, which is the best version of it.", "weight": 2, "effects": {"smarts": 6, "stress": 10, "money": -800}},
				{"text": "I went, and they want to see me again in six months, and would not say more than that.", "weight": 1, "effects": {"stress": 18}}]},
			{"label": "Go, and take somebody with you",
			 "outcomes": [
				{"text": "I did not go alone. Half of what they said I have forgotten; she has all of it written down.", "weight": 2, "effects": {"smarts": 4, "stress": 4, "happiness": 6, "money": -800}},
				{"text": "Having her there meant hearing it and watching her hear it at the same time.", "weight": 1, "effects": {"stress": 16, "happiness": -8, "money": -800}}]},
			{"label": "Cancel it",
			 "outcomes": [
				{"text": "I cancelled it. They were furious and then they were frightened and then they stopped mentioning it.", "weight": 2, "effects": {"stress": 12, "happiness": -8}},
				{"text": "I cancelled it and rebooked it myself a year later, on my own terms, which mattered to me.", "weight": 1, "effects": {"smarts": 3, "happiness": 5}}]}]},
	],
}


func yearly() -> void:
	var p := _p()
	if p.is_empty() or not GameState.is_alive():
		return
	_disuse()
	_warn()


func _warn() -> void:
	var p := _p()
	var st := _state()
	var warned: Dictionary = st["warned"]
	var age := int(p.get("age", 0))
	if age < 10:
		return
	# Only one of these a year. A life that is failing in three ways at once
	# should not read like a list.
	var worst := ""
	var worst_v := 999.0
	for k in ["health", "happiness", "smarts", "looks"]:
		var v := GameState.stat(k)
		if v < POOR and v < worst_v:
			worst = k
			worst_v = v
	if worst == "":
		return

	var band := 2 if worst_v < CRITICAL * 0.5 else (1 if worst_v < CRITICAL else 0)
	var key := "%s_%d" % [worst, band]
	var lines: Array = WARNINGS.get(worst, [])
	if not warned.has(key) and band < lines.size():
		warned[key] = true
		GameState.add_log(str(lines[band]))
		if Moments.ready_to_play():
			Moments.fire("stat_loss", 0.5 + 0.25 * float(band))

	# Below critical, the world starts handing you the chance to do something
	# about it. Refusing is allowed; not being asked was the problem.
	if worst_v >= CRITICAL:
		return
	if age - int(st.get("last_warning_age", -99)) < 3:
		return
	var pool: Array = CRISES.get(worst, [])
	if pool.is_empty():
		return
	if randf() > (0.55 if worst_v < CRITICAL * 0.5 else 0.35):
		return
	st["last_warning_age"] = age
	var ev: Dictionary = (pool[randi() % pool.size()] as Dictionary).duplicate(true)
	ev["id"] = "_decline_%s" % worst
	ev["twist"] = true
	EventEngine.push_decision(ev, {})


## For the death screen and the info panel: how close it was.
func failing() -> Array:
	var out: Array = []
	for k in ["health", "happiness", "smarts", "looks"]:
		var v := GameState.stat(k)
		if v < CRITICAL:
			out.append(k)
	return out

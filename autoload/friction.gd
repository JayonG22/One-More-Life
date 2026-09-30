extends Node

## FRICTION — the uncertainty layer.
##
## The problem this solves: 56% of the choices in this game had exactly one
## outcome. You picked the sensible option and the sensible thing happened, every
## time, for a whole life. That is why a run felt like a menu instead of a life.
##
## This does not make the game random. It makes the game answer a question it was
## never asking: given who this person actually is right now — how steady, how
## rested, how liked, how lucky — does the thing they chose actually land?
##
## A choice resolves into one of three bands:
##   clean     it goes the way you meant it to
##   snag      it still works, but it costs something you did not plan for
##   backfire  it does not work, and you carry the difference
##
## Competence is earned, so a capable, calm, well-liked character lands clean most
## of the time and a reckless exhausted one does not. Difficulty scales the whole
## curve, which is what makes Gritty feel different rather than just meaner.

const BANDS := {"clean": 0, "snag": 1, "backfire": 2}

## Which stat carries which kind of act. Used to decide what "competent" means
## for this particular choice rather than applying one global skill check.
const EFFECT_STAT := {
	"smarts": "smarts", "school": "smarts", "job_perf": "smarts",
	"health": "health", "looks": "looks",
	"happiness": "happiness", "money": "smarts", "fame": "looks",
	"heat": "smarts", "karma": "happiness",
}

var last_band := "clean"
var last_note := ""


func _p() -> Dictionary:
	return GameState.player


# ---------------------------------------------------------------- the roll

## What this character can reasonably pull off right now, 0..1.
func competence(outcome: Dictionary, def: Dictionary) -> float:
	var p := _p()
	if p.is_empty():
		return 1.0
	var effects: Dictionary = outcome.get("effects", {})

	# Pick the stat that actually governs this act.
	var stat_key := "smarts"
	var best := 0.0
	for k in effects.keys():
		if not EFFECT_STAT.has(k):
			continue
		var weight := absf(float(effects[k]))
		if weight > best:
			best = weight
			stat_key = EFFECT_STAT[k]
	# Baseline competence: an ordinary adult doing an ordinary thing mostly manages
	# it. The stat decides how far above or below ordinary they sit.
	var base := 0.12 + GameState.stat(stat_key) / 100.0

	# Being young or very old is not incompetence, but it is less control.
	var age := int(p.get("age", 30))
	if age < 12:
		base *= 0.82
	elif age < 16:
		base *= 0.92
	elif age > 74:
		base *= 0.90

	# State of the person, not the plan.
	base -= GameState.stat("stress") / 320.0
	if GameState.stat("health") < 35.0:
		base -= 0.08
	if GameState.stat("happiness") < 25.0:
		base -= 0.06

	# Karma is the game's thumb on the scale. Good deeds should be felt here.
	base += float(p.get("karma", 0)) / 520.0

	# Who you are changes what goes wrong.
	var social: bool = not outcome.get("relationship", {}).is_empty()
	if GameState.has_trait("Hothead"):
		base -= 0.05
	if GameState.has_trait("Gambler"):
		base -= 0.03
	if GameState.has_trait("Lazy"):
		base -= 0.05
	if GameState.has_trait("Anxious"):
		base -= 0.04
	if GameState.has_trait("Ambitious"):
		base += 0.05 if effects.has("job_perf") or effects.has("money") else 0.0
	if GameState.has_trait("Athletic") and stat_key == "health":
		base += 0.07
	if GameState.has_trait("Bookworm") and stat_key == "smarts":
		base += 0.05
	if social:
		if GameState.has_trait("Charmer"):
			base += 0.06
		if GameState.has_trait("Loyal"):
			base += 0.05
		if GameState.has_trait("Funny"):
			base += 0.04
		if GameState.has_trait("Kind"):
			base += 0.04
	if GameState.has_trait("Rebel"):
		base += 0.05 if def.get("tags", []).has("risky") else -0.04

	# Things you are carrying make everything slightly harder.
	for h in Grit.active_habits():
		base -= 0.035
	if Grit.has_boon("lucky_star"):
		base += 0.06

	# Tags let an event opt into being genuinely hard.
	var tags: Array = def.get("tags", [])
	if tags.has("risky"):
		base -= 0.12
	if tags.has("routine"):
		base += 0.14

	return clampf(base, 0.12, 0.975)


## Does this choice deserve a roll at all? Not everything should.
func applies(choice: Dictionary, outcome: Dictionary, def: Dictionary) -> bool:
	if _p().is_empty() or not GameState.is_alive():
		return false
	if def.get("info", false) or def.get("no_friction", false):
		return false
	if outcome.get("no_friction", false):
		return false
	# Never pile onto an outcome that already went badly. The author meant that.
	if _tone(outcome) < 0:
		return false
	# Friction reduces a gain. With no gain to reduce there is nothing to say, and
	# appending a cost line to a pure statement of fact ("Shadow is family now")
	# only produces nonsense.
	if not _has_gain(outcome):
		return false
	# Death, births and scripted turning points keep their authored shape.
	for key in ["death", "kill", "new_partner", "career_start", "life_path"]:
		if outcome.has(key):
			return false
	return true


## Is there something here the player was promised that friction could take away?
func _has_gain(outcome: Dictionary) -> bool:
	var e: Dictionary = outcome.get("effects", {})
	for k in e.keys():
		var v := float(e[k])
		if k == "stress":
			if v <= -2.0:
				return true
		elif k == "money":
			if v >= 150.0:
				return true
		elif k in ["happiness", "health", "smarts", "looks", "fame", "job_perf", "school", "karma"]:
			if v >= 2.0:
				return true
	for r in outcome.get("relationship", {}).keys():
		if float(outcome["relationship"][r]) >= 5.0:
			return true
	return false


func _tone(outcome: Dictionary) -> int:
	var e: Dictionary = outcome.get("effects", {})
	var s := 0.0
	for k in e.keys():
		var v := float(e[k])
		if k == "stress":
			s -= v
		elif k == "money":
			s += (1.0 if v > 0 else -1.0) * minf(absf(v) / 800.0, 4.0)
		elif k in ["happiness", "health", "smarts", "looks", "fame", "karma", "job_perf", "school"]:
			s += v
	for r in outcome.get("relationship", {}).keys():
		s += float(outcome["relationship"][r]) / 8.0
	if s > 0.5:
		return 1
	if s < -0.5:
		return -1
	return 0


## Roll the band. Single-outcome choices carry the full weight, because those are
## the ones that were previously guaranteed. Where an author already wrote real
## alternatives, friction only nudges.
func roll(choice: Dictionary, outcome: Dictionary, def: Dictionary) -> String:
	var authored: bool = choice.get("outcomes", []).size() > 1
	var c := competence(outcome, def)
	var harsh := Grit.d("harsh")

	var backfire := (1.0 - c) * 0.30 * harsh
	var snag := (1.0 - c) * 0.55 * harsh
	if authored:
		backfire *= 0.35
		snag *= 0.45

	# A choice that promises a lot should be harder to land cleanly.
	var reach := float(_tone(outcome))
	if reach > 0:
		var e: Dictionary = outcome.get("effects", {})
		var big := 0.0
		for k in e.keys():
			if k == "money":
				big = maxf(big, minf(absf(float(e[k])) / 20000.0, 1.0))
			else:
				big = maxf(big, minf(absf(float(e[k])) / 25.0, 1.0))
		backfire += big * 0.10 * harsh
		snag += big * 0.12 * harsh

	var r := randf()
	if r < backfire:
		return "backfire"
	if r < backfire + snag:
		return "snag"
	return "clean"


# ---------------------------------------------------------------- consequences

## Soften or sour the authored effects, and return the cost to apply on top.
func adjust(outcome: Dictionary, band: String) -> Dictionary:
	var out := {"effects": {}, "scale": 1.0}
	if band == "clean":
		return out
	var e: Dictionary = outcome.get("effects", {})
	var extra := {}
	if band == "snag":
		out["scale"] = 0.65
		extra["stress"] = 4
	else:
		out["scale"] = 0.0
		extra["stress"] = 8
		extra["happiness"] = -4
	# A backfire on something you spent money reaching for still costs the money.
	if e.has("money") and float(e["money"]) > 0 and band == "backfire":
		extra["money"] = -int(absf(float(e["money"])) * 0.15)
	out["effects"] = extra
	return out


## Categories are only used when the gain clearly belongs to one. Anything
## ambiguous falls through to "general", whose lines fit almost any sentence.
func category(outcome: Dictionary, def: Dictionary) -> String:
	var e: Dictionary = outcome.get("effects", {})
	for r in outcome.get("relationship", {}).keys():
		if float(outcome["relationship"][r]) >= 5.0:
			return "social"
	if float(e.get("job_perf", 0.0)) >= 3.0:
		return "work"
	if float(e.get("school", 0.0)) >= 3.0:
		return "school"
	# Only a real windfall reads as a money story. Spending money does not.
	if float(e.get("money", 0.0)) >= 500.0:
		return "money"
	if float(e.get("health", 0.0)) >= 3.0 and e.size() <= 2:
		return "body"
	return "general"


## The rule these pools obey: a friction line never claims the thing failed.
## It is always about what it COST or what FOLLOWED. That is the only way a line
## can be appended to arbitrary authored text without contradicting it — "Shadow
## is family now. It took more out of me than I expected." reads; "Shadow is
## family now. It came apart in front of me." does not.
##
## The failure itself is carried mechanically: the gain you were promised is cut
## or erased, and the player sees the numbers fall short of the sentence.

const SNAGS := {
	"social": [
		"It cost me more than I meant to spend on it.",
		"There was a pause in the middle of it I am still thinking about.",
		"It took more out of me than a thing that size should.",
		"I spent the rest of the evening rereading my own sentences.",
	],
	"money": [
		"There were fees nobody mentioned until they were already gone.",
		"It took three more calls than it should have, and a week of evenings.",
		"The paperwork ate the part I was looking forward to.",
		"It arrived smaller than the number I had in my head.",
	],
	"work": [
		"Somebody else's name ended up on the part that went well.",
		"It burned a favour I had been saving for something bigger.",
		"The week it took is not one I would volunteer to repeat.",
		"The scrutiny afterwards was the part nobody warned me about.",
	],
	"school": [
		"I know exactly which parts I still do not actually understand.",
		"The margin was thinner than anyone watching would have guessed.",
		"It cost me a night I would not honestly describe as studying.",
	],
	"body": [
		"I felt it the next morning in a way I had not planned for.",
		"It took longer to come back from than it should have.",
		"I overdid it slightly, the way I always do.",
	],
	"general": [
		"It cost more than I had budgeted for it, in every sense.",
		"There was an edge to it I had not planned for.",
		"It took something out of the week I do not get back.",
		"The tidy version is the one I tell people.",
	],
}

const BACKFIRES := {
	"social": [
		"Whatever I thought I had built there, it did not hold. I found that out slowly, and then all at once.",
		"It cost me something with them that I could not name at the time and cannot get back now.",
		"They heard a different sentence than the one I said, and I have been paying for the difference since.",
		"I will be explaining my side of this one for a long time.",
	],
	"money": [
		"Every bit of it went back out again, and then some, before the year was done.",
		"The costs of getting there outlived whatever I got for it.",
		"I found out from a form letter what it had actually been worth.",
		"The numbers did not survive contact with the actual paperwork.",
	],
	"work": [
		"It came apart afterwards, in the room where it mattered most.",
		"Whatever credit I earned evaporated in the telling.",
		"It became the thing people remembered about me that year, and not kindly.",
	],
	"school": [
		"The result, when it came in writing, said what I already knew.",
		"It caught up with me by the end of term and took the rest with it.",
	],
	"body": [
		"My body sent the bill later, with interest.",
		"I pushed past something I should have listened to, and it did not forget.",
	],
	"general": [
		"It unravelled afterwards, and I was standing closest to it.",
		"Whatever I gained, something else gave way before the year was out.",
		"It cost me the thing I was actually trying to protect.",
		"I am still not entirely sure which part I got wrong.",
	],
}


func note(band: String, outcome: Dictionary, def: Dictionary) -> String:
	if band == "clean":
		return ""
	var cat := category(outcome, def)
	var pool: Array = (SNAGS if band == "snag" else BACKFIRES).get(cat, [])
	if pool.is_empty():
		pool = (SNAGS if band == "snag" else BACKFIRES)["general"]
	return str(pool[randi() % pool.size()])


## Entry point used by EventEngine. Returns the band and stores the note.
func apply(choice: Dictionary, outcome: Dictionary, def: Dictionary) -> Dictionary:
	last_band = "clean"
	last_note = ""
	if not applies(choice, outcome, def):
		return {"band": "clean", "note": "", "scale": 1.0, "effects": {}}
	var band := roll(choice, outcome, def)
	var adj := adjust(outcome, band)
	last_band = band
	last_note = note(band, outcome, def)
	if band != "clean":
		GameState.counter("friction_" + band)
	return {"band": band, "note": last_note, "scale": float(adj["scale"]), "effects": adj["effects"]}


## Scale an authored effect set by the band, so a snag gives you less of what you
## wanted and a backfire gives you none of it. Costs are never scaled away.
func scale_effects(effects: Dictionary, scale: float) -> Dictionary:
	if is_equal_approx(scale, 1.0):
		return effects
	var out := {}
	for k in effects.keys():
		var v := float(effects[k])
		var good := (v < 0.0) if k == "stress" else (v > 0.0)
		if good:
			var nv := v * scale
			if k == "money":
				out[k] = int(nv)
			elif absf(nv) < 1.0 and absf(v) >= 1.0:
				out[k] = 1.0 * signf(v) if scale > 0.0 else 0.0
			else:
				out[k] = nv
		else:
			out[k] = v
	return out

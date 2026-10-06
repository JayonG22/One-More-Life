extends Node

## BONDS — the stats that belong to the relationship, not to either person.
##
## Before this, one number did every job: `closeness`, 0–100, in about two
## hundred places. Whether your mother trusted you, whether your rival respected
## you and whether your wife still wanted you were all the same bar, moved by the
## same actions, meaning nothing in particular.
##
## The split this makes:
##
##   * An NPC's OWN stats — happiness, health, smarts, looks — are theirs. They
##     drift on their own and you do not maintain them.
##   * A BOND's stats are the thing between you, and they are what you actually
##     play. You can be adored and not trusted. You can be respected by someone
##     who cannot stand you. Your marriage can have affection with the romance
##     long gone, which is a specific and very real way for a marriage to be.
##
## `closeness` still exists and still means what it meant, but it is now DERIVED
## from the bond. Every old call site keeps working and starts telling the truth
## about a richer model underneath.

## Each stat: [label, icon, default, decays_toward]
const STATS := {
	"affection":  ["Affection", "💗", 50.0, 38.0],
	"trust":      ["Trust", "🤝", 50.0, 45.0],
	"respect":    ["Respect", "🎖️", 50.0, 45.0],
	"romance":    ["Romance", "🔥", 0.0, 0.0],
	"resentment": ["Resentment", "💢", 0.0, 0.0],
	"obligation": ["Obligation", "📒", 0.0, 0.0],
}

## Which stats a given relation actually has. A boss has no romance track; a
## newborn has no respect track worth speaking of.
const PROFILES := {
	"romantic": ["affection", "trust", "respect", "romance", "resentment", "obligation"],
	"family":   ["affection", "trust", "respect", "resentment", "obligation"],
	"social":   ["affection", "trust", "respect", "resentment", "obligation"],
	"work":     ["trust", "respect", "resentment", "obligation"],
	"hostile":  ["trust", "respect", "resentment", "obligation"],
	"animal":   ["affection", "trust"],
}

const RELATION_PROFILE := {
	"principal":"work", "school_nurse":"social", "former_teacher":"work", "former_classmate":"social",
	"partner": "romantic", "lover": "romantic", "crush": "romantic", "ex": "romantic",
	"mother": "family", "father": "family", "stepparent": "family", "sibling": "family",
	"stepsibling": "family", "child": "family", "stepchild": "family", "grandparent": "family",
	"grandchild": "family", "auntuncle": "family", "cousin": "family", "niece_nephew": "family",
	"friend": "social", "best_friend": "social", "neighbor": "social", "classmate": "social",
	"former_friend": "social", "mentor": "social",
	"boss": "work", "coworker": "work", "former_coworker": "work", "teacher": "work",
	"crewmate": "work", "suspect": "work", "witness": "work", "patient": "work", "tenant": "work",
	"enemy": "hostile", "rival": "hostile", "nemesis": "hostile", "cellmate": "hostile",
	"pet": "animal",
}

## How much each stat pulls the single closeness number people already read.
const CLOSENESS_WEIGHT := {
	"affection": 0.44, "trust": 0.26, "respect": 0.18, "romance": 0.12, "resentment": -0.55,
}


func profile_for(relation: String) -> String:
	return str(RELATION_PROFILE.get(relation, "social"))


func stats_for(id: String) -> Array:
	var n := GameState.npc(id)
	if n.is_empty():
		return []
	return PROFILES[profile_for(str(n.get("relation", "friend")))]


## Create the bond record, seeding it so it agrees with whatever closeness the
## NPC was created with. An old save loads straight into the new model.
func ensure(id: String) -> Dictionary:
	var n := GameState.npc(id)
	if n.is_empty():
		return {}
	if n.has("bond") and n["bond"] is Dictionary:
		if profile_for(str(n.get("relation","")))=="hostile" and not n["bond"].has("trust"): n["bond"]["trust"]=minf(25,float(n["bond"].get("respect",0))*0.5)
		return n["bond"]
	var seed_close := float(n.get("closeness", 50))
	var b := {}
	for key in stats_for(id):
		var d: Array = STATS[key]
		match key:
			"affection":
				b[key] = clampf(seed_close + randf_range(-8.0, 8.0), 0.0, 100.0)
			"trust", "respect":
				b[key] = clampf(seed_close * 0.75 + 15.0 + randf_range(-12.0, 12.0), 0.0, 100.0)
			"romance":
				b[key] = clampf(seed_close * 0.8, 0.0, 100.0) if str(n.get("relation", "")) in ["partner", "lover", "crush"] else 0.0
			"resentment":
				b[key] = float(n.get("grudge", 0))
			"obligation":
				b[key] = 0.0
			_:
				b[key] = float(d[2])
	n["bond"] = b
	return b


func get_stat(id: String, key: String) -> float:
	var b := ensure(id)
	return float(b.get(key, 0.0))


func has_stat(id: String, key: String) -> bool:
	return ensure(id).has(key)


## Move one bond stat. This is the real verb now; change_closeness became a
## convenience that routes here.
func nudge(id: String, key: String, delta: float) -> void:
	var b := ensure(id)
	if b.is_empty() or not b.has(key):
		return
	b[key] = clampf(float(b[key]) + delta, 0.0, 100.0)
	_sync(id)


## Move several at once, which is what most real interactions actually do.
func apply(id: String, deltas: Dictionary) -> void:
	var b := ensure(id)
	if b.is_empty():
		return
	for key in deltas.keys():
		if b.has(key):
			b[key] = clampf(float(b[key]) + float(deltas[key]), 0.0, 100.0)
	_sync(id)


## Recompute the headline number every existing system already reads.
func _sync(id: String) -> void:
	var n := GameState.npc(id)
	var b := ensure(id)
	if n.is_empty() or b.is_empty():
		return
	var total := 0.0
	var weight := 0.0
	for key in b.keys():
		if not CLOSENESS_WEIGHT.has(key):
			continue
		var w := float(CLOSENESS_WEIGHT[key])
		if w > 0.0:
			total += float(b[key]) * w
			weight += w
		else:
			total += float(b[key]) * w
	var value := (total / maxf(weight, 0.01)) if weight > 0.0 else 50.0
	n["closeness"] = clampi(int(round(value)), 0, 100)
	# Resentment and the older grudge system are the same feeling; keep them level.
	if b.has("resentment"):
		n["grudge"] = int(round(float(b["resentment"])))


## Absorb a raw closeness change from older code into the bond. Most legacy calls
## mean "we got on better / worse", which is affection with a little trust.
func absorb_closeness(id: String, delta: int) -> void:
	if delta == 0:
		return
	var b := ensure(id)
	if b.is_empty():
		return
	var d := float(delta)
	var moves := {}
	if b.has("affection"):
		moves["affection"] = d * 0.75
	if b.has("trust"):
		moves["trust"] = d * 0.3
	if b.has("respect"):
		moves["respect"] = d * 0.15
	if d < 0.0 and b.has("resentment"):
		moves["resentment"] = -d * 0.28
	elif d > 0.0 and b.has("resentment"):
		moves["resentment"] = -d * 0.12
	apply(id, moves)


# ---------------------------------------------------------------- the year

## Bonds decay toward what they naturally settle at when nobody tends them.
## Trust and respect hold far better than affection does, which is why an old
## friend you never call still thinks well of you and no longer feels close.
func yearly() -> void:
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if not n.get("alive", true) or not n.has("bond"):
			continue
		var b: Dictionary = n["bond"]
		var fam := profile_for(str(n.get("relation", "friend"))) == "family"
		var slow := 0.45 if Grit.has_boon("family_ties") and fam else 1.0
		for key in b.keys():
			var d: Array = STATS.get(key, ["", "", 50.0, 50.0])
			var target := float(d[3])
			var rate := 0.0
			match key:
				"affection":
					rate = 2.6
				"trust", "respect":
					rate = 0.7
				"romance":
					rate = 2.2
				"resentment":
					rate = 1.1
				"obligation":
					rate = 1.6
			var cur := float(b[key])
			b[key] = clampf(move_toward(cur, target, rate * slow), 0.0, 100.0)
		_sync(id)


# ---------------------------------------------------------------- reading

func word(key: String, v: float) -> String:
	match key:
		"affection":
			if v >= 85.0: return "devoted to me"
			if v >= 65.0: return "fond of me"
			if v >= 40.0: return "warm enough"
			if v >= 20.0: return "cooling off"
			return "barely there"
		"trust":
			if v >= 85.0: return "would take my word on anything"
			if v >= 65.0: return "trusts me"
			if v >= 40.0: return "trusts me with small things"
			if v >= 20.0: return "checks what I tell them"
			return "does not believe me"
		"respect":
			if v >= 85.0: return "looks up to me"
			if v >= 65.0: return "respects me"
			if v >= 40.0: return "takes me seriously enough"
			if v >= 20.0: return "is not impressed"
			return "thinks very little of me"
		"romance":
			if v >= 85.0: return "still in love with me"
			if v >= 60.0: return "still wants me"
			if v >= 35.0: return "comfortable, not burning"
			if v >= 12.0: return "the spark is nearly out"
			return "nothing left of it"
		"resentment":
			if v >= 80.0: return "will not forgive this"
			if v >= 55.0: return "holds it against me"
			if v >= 30.0: return "has not let it go"
			if v >= 10.0: return "a little sore"
			return "nothing held against me"
		"obligation":
			if v >= 70.0: return "owes me, and knows it"
			if v >= 35.0: return "owes me a favour"
			if v >= 12.0: return "a small debt between us"
			return "we are square"
	return ""


## The one line that says what this relationship actually is right now.
func summary(id: String) -> String:
	var b := ensure(id)
	if b.is_empty():
		return ""
	var bits: Array = []
	for key in ["romance", "affection", "trust", "respect", "resentment", "obligation"]:
		if not b.has(key):
			continue
		var v := float(b[key])
		# Only say the notable things, or every person reads like a spreadsheet.
		var notable := v >= 65.0 or v <= 22.0
		if key in ["resentment", "obligation"]:
			notable = v >= 25.0
		# A marriage with nothing left in it is the most important thing that
		# screen can tell you, so romance at zero is never silently omitted.
		if key == "romance":
			notable = v >= 60.0 or v <= 35.0
		if notable:
			bits.append("%s %s" % [STATS[key][1], word(key, v)])
	return "  ·  ".join(bits)


func detail_lines(id: String) -> Array:
	var b := ensure(id)
	var out: Array = []
	for key in ["affection", "trust", "respect", "romance", "resentment", "obligation"]:
		if not b.has(key):
			continue
		# Romance always shows for a bond that has a romance track at all -
		# "nothing left of it" is information, not an empty row.
		if key in ["resentment", "obligation"] and float(b[key]) <= 1.0:
			continue
		out.append([STATS[key][1], str(STATS[key][0]), float(b[key]), word(key, float(b[key]))])
	return out

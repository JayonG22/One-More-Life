extends Node

## ORIGINS — the circumstances you are born into.
##
## Every life used to start the same way: one mother, one father, nought to two
## siblings, everybody present and alive. That is not how people are born, and
## it also hid a real bug. Because nobody recorded that your mother and father
## were married TO EACH OTHER, the yearly NPC life pass saw two unmarried adults
## aged 22-50 and married your father off to a stranger while he was still
## living with your mother.
##
## So this file does two jobs at once. It records who is married to whom, with
## an actual link between the two people, which means nobody can be married
## twice. And it rolls what kind of family you arrive into, which is the far
## more interesting half.
##
## Nothing here is a setting. You do not pick it, the same way nobody picks it.

## id -> [weight, name, what it means]
const ORIGINS := {
	"together":    [46, "Both parents", "Two parents, together, under one roof."],
	"separated":   [14, "Parents apart", "Two parents who are not together, and two houses."],
	"single_mum":  [11, "Raised by mother", "One parent, doing the work of two."],
	"single_dad":  [5, "Raised by father", "One parent, doing the work of two."],
	"widowed":     [4, "A parent who died", "One parent, and a photograph of the other."],
	"grandparent": [6, "Raised by grandparents", "The generation above the one that should have."],
	"adopted":     [8, "Adopted", "A family that chose you, and a story nobody has told you yet."],
	"care":        [4, "The care system", "No family. A building, and a rota of adults."],
	"teen_parent": [2, "A very young mother", "A mother barely older than a sibling."],
}

## Whether an origin starts you with a mother, a father, or neither.
const HAS := {
	"together":    {"mother": true, "father": true},
	"separated":   {"mother": true, "father": true},
	"single_mum":  {"mother": true, "father": false},
	"single_dad":  {"mother": false, "father": true},
	"widowed":     {"mother": true, "father": false},
	"grandparent": {"mother": false, "father": false},
	"adopted":     {"mother": true, "father": true},
	"care":        {"mother": false, "father": false},
	"teen_parent": {"mother": true, "father": false},
}


func roll() -> String:
	var total := 0
	for k in ORIGINS.keys():
		total += int(ORIGINS[k][0])
	var r := randi() % total
	for k in ORIGINS.keys():
		r -= int(ORIGINS[k][0])
		if r < 0:
			return str(k)
	return "together"


func kind() -> String:
	return str(GameState.player.get("origin", "together"))


func name_of(id: String = "") -> String:
	var k := id if id != "" else kind()
	return str(ORIGINS.get(k, ORIGINS["together"])[1])


func blurb(id: String = "") -> String:
	var k := id if id != "" else kind()
	return str(ORIGINS.get(k, ORIGINS["together"])[2])


func only_child() -> bool:
	return GameState.npcs_with("sibling", false).is_empty() and GameState.npcs_with("stepsibling", false).is_empty()


# ---------------------------------------------------------------- marriage links

## Marry two NPCs to each other, with a link in both directions so neither of
## them can ever be married off again by the yearly pass. This is the fix for
## a father who was already married acquiring a second wife.
func wed(a: String, b: String) -> void:
	if a == "" or b == "" or a == b:
		return
	if not GameState.npcs.has(a) or not GameState.npcs.has(b):
		return
	var na: Dictionary = GameState.npcs[a]
	var nb: Dictionary = GameState.npcs[b]
	na["married"] = true
	nb["married"] = true
	na["spouse_id"] = b
	nb["spouse_id"] = a
	na["spouse"] = "%s %s" % [nb.get("first", ""), nb.get("last", "")]
	nb["spouse"] = "%s %s" % [na.get("first", ""), na.get("last", "")]
	na["spouse_gender"] = str(nb.get("gender", "female"))
	nb["spouse_gender"] = str(na.get("gender", "male"))


## Undo it from both sides, so a divorce does not leave a ghost spouse behind.
func part(a: String) -> void:
	if not GameState.npcs.has(a):
		return
	var na: Dictionary = GameState.npcs[a]
	var other := str(na.get("spouse_id", ""))
	na["married"] = false
	na.erase("spouse")
	na.erase("spouse_id")
	if other != "" and GameState.npcs.has(other):
		var nb: Dictionary = GameState.npcs[other]
		nb["married"] = false
		nb.erase("spouse")
		nb.erase("spouse_id")


## Somebody who is already married, to anyone, is not available to be married.
func is_spoken_for(id: String) -> bool:
	if not GameState.npcs.has(id):
		return true
	var n: Dictionary = GameState.npcs[id]
	if bool(n.get("married", false)):
		return true
	return str(n.get("spouse_id", "")) != ""


# ---------------------------------------------------------------- building it

## Called from GameState._generate_family(). Builds the household and returns
## the origin id so the rest of the game can read it.
func build(last: String) -> String:
	var p := GameState.player
	var origin := roll()
	p["origin"] = origin
	var has: Dictionary = HAS[origin]

	var mom_age := randi_range(19, 40)
	if origin == "teen_parent":
		mom_age = randi_range(14, 18)
	var dad_age := clampi(mom_age + randi_range(-3, 6), 19, 50)

	var mum := ""
	var dad := ""
	if bool(has.get("mother", false)):
		mum = GameState.create_npc("mother", {"gender": "female", "age": mom_age, "last": last,
			"closeness": randi_range(70, 95)})
	if bool(has.get("father", false)):
		dad = GameState.create_npc("father", {"gender": "male", "age": dad_age, "last": last,
			"closeness": randi_range(60, 95)})

	match origin:
		"together", "adopted":
			wed(mum, dad)
		"separated":
			# Both present, neither available: they have each other's history and
			# an arrangement, which is not the same as being free.
			if mum != "" and dad != "":
				GameState.npcs[mum]["ex_spouse_id"] = dad
				GameState.npcs[dad]["ex_spouse_id"] = mum
				GameState.npcs[mum]["closeness"] = maxi(40, int(GameState.npcs[mum]["closeness"]) - 10)
				GameState.npcs[dad]["closeness"] = maxi(25, int(GameState.npcs[dad]["closeness"]) - 25)
		"widowed":
			p["lost_parent"] = "father"
		"grandparent":
			var g1 := GameState.create_npc("grandparent", {"gender": "female",
				"age": randi_range(52, 74), "last": last, "closeness": randi_range(70, 95)})
			if randf() < 0.65:
				var g2 := GameState.create_npc("grandparent", {"gender": "male",
					"age": randi_range(54, 78), "last": last, "closeness": randi_range(60, 90)})
				wed(g1, g2)
		"care":
			pass

	# Siblings. An only child is a real outcome, not a rounding error.
	var sibs := 0
	var r := randf()
	if origin == "care":
		sibs = 1 if randf() < 0.25 else 0
	elif origin == "teen_parent":
		sibs = 0
	elif r < 0.30:
		sibs = 0
	elif r < 0.70:
		sibs = 1
	elif r < 0.92:
		sibs = 2
	else:
		sibs = 3
	for i in range(sibs):
		if mom_age - 16 > 1:
			GameState.create_npc("sibling", {"age": randi_range(1, mini(14, maxi(2, mom_age - 16))),
				"last": last, "closeness": randi_range(50, 90)})

	_opening_effects(origin)
	return origin


func _opening_effects(origin: String) -> void:
	var p := GameState.player
	match origin:
		"separated":
			GameState.change_stat("happiness", -6.0)
		"single_mum", "single_dad":
			GameState.change_stat("happiness", -4.0)
			p["money"] = int(p["money"]) - 0
		"widowed":
			GameState.change_stat("happiness", -10.0)
			GameState.change_stat("stress", 6.0)
		"grandparent":
			GameState.change_stat("happiness", -5.0)
			GameState.change_stat("health", 3.0)
		"adopted":
			GameState.set_flag("adopted")
		"care":
			GameState.change_stat("happiness", -14.0)
			GameState.change_stat("stress", 10.0)
			GameState.change_stat("smarts", -4.0)
		"teen_parent":
			GameState.change_stat("happiness", -5.0)
			GameState.change_stat("stress", 5.0)


## The line the player reads on their very first year, so the circumstance is
## something they are told rather than something they have to infer.
func opening_line() -> String:
	var p := GameState.player
	match kind():
		"together":
			return "I was born to two parents who were, as far as I ever knew, glad about it."
		"separated":
			return "My parents were not together. I had two houses and two sets of rules before I could read."
		"single_mum":
			return "My mother did it on her own. I did not know that was unusual until somebody told me."
		"single_dad":
			return "My father did it on his own. He was not good at plaits and he never once said so."
		"widowed":
			return "My father died before I could remember him. There is one photograph and everybody says I have his hands."
		"grandparent":
			return "My grandmother raised me. Nobody sat me down and explained why, and I learned not to ask."
		"adopted":
			return "I was adopted as a baby. They told me early, which I have since been told was the kind thing to do."
		"care":
			return "I grew up in the care system. There were adults, and they changed, and none of them were mine."
		"teen_parent":
			return "My mother was sixteen when she had me. People assumed she was my sister for years and she let them."
	return ""


## Shown in the info panel, so the player can always see where they started.
func summary_lines() -> Array:
	var out: Array = []
	var k := kind()
	out.append(["🌱 " + name_of(k), blurb(k)])
	if only_child():
		out.append(["👤 Only child", "No brothers or sisters."])
	return out

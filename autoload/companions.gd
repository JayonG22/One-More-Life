extends Node

## COMPANIONS — the animals in a human's life.
##
## A pet is not a list entry. It eats, it gets ill, it gets old, it notices when
## you are gone, and it can be lost. Where it came from (a shelter, a stray, a
## gift, a shop, a litter) is remembered. Every pet appears on the People tab with
## its bond, its health and how well fed it is, whether it came from an event, a
## shop or the shelter.
##
## The tending state sits on the animal's NPC record under `care`, beside the
## older `pet_profile` (training, temperament, shows) kept by Ambition.

const KINDS := {
	"dog": {"name": "Dog", "icon": "🐕", "adopt": 250, "buy": 1400, "upkeep": 900, "life": [11, 15], "blurb": "Walks, loyalty, hair on everything."},
	"cat": {"name": "Cat", "icon": "🐈", "adopt": 150, "buy": 900, "upkeep": 600, "life": [13, 18], "blurb": "Opinions, a window seat, 3 a.m. zoomies."},
	"rabbit": {"name": "Rabbit", "icon": "🐇", "adopt": 80, "buy": 120, "upkeep": 380, "life": [8, 11], "blurb": "Quiet, clever, chews cables."},
	"parrot": {"name": "Parrot", "icon": "🦜", "adopt": 400, "buy": 1800, "upkeep": 500, "life": [30, 50], "blurb": "Will outlive your furniture and repeat your arguments."},
	"hamster": {"name": "Hamster", "icon": "🐹", "adopt": 15, "buy": 25, "upkeep": 120, "life": [2, 3], "blurb": "Small, nocturnal, tragically short."},
	"guinea_pig": {"name": "Guinea pig", "icon": "🐹", "adopt": 40, "buy": 60, "upkeep": 250, "life": [5, 8], "blurb": "Wheeks when the fridge opens."},
	"goldfish": {"name": "Goldfish", "icon": "🐠", "adopt": 5, "buy": 10, "upkeep": 80, "life": [6, 12], "blurb": "A bowl, a name, a long stare."},
	"turtle": {"name": "Turtle", "icon": "🐢", "adopt": 60, "buy": 150, "upkeep": 200, "life": [25, 40], "blurb": "Slow, patient, probably will outlive you."},
	"ferret": {"name": "Ferret", "icon": "🦦", "adopt": 120, "buy": 350, "upkeep": 450, "life": [6, 9], "blurb": "A noodle with a criminal record."},
	"lizard": {"name": "Lizard", "icon": "🦎", "adopt": 60, "buy": 200, "upkeep": 220, "life": [8, 15], "blurb": "A heat lamp and a stare."},
	"snake": {"name": "Snake", "icon": "🐍", "adopt": 80, "buy": 250, "upkeep": 200, "life": [15, 25], "blurb": "Quiet. Some guests will leave."},
	"horse": {"name": "Horse", "icon": "🐴", "adopt": 1500, "buy": 8000, "upkeep": 5200, "life": [25, 32], "blurb": "A field, a farrier and a lot of hay.", "min_age": 18},
}
const SOURCES := {
	"shelter": "adopted from a shelter", "shop": "bought from a pet shop", "breeder": "bought from a breeder",
	"stray": "found as a stray", "gift": "given as a gift", "inherit": "inherited", "event": "came into your life",
	"litter": "born in your house", "rescue": "rescued", "friend": "taken from a friend",
}
const MAX_PETS := 6


func icon(species: String) -> String:
	return str(KINDS.get(species, {"icon": "🐾"})["icon"])


func _p() -> Dictionary:
	return GameState.player


func pets() -> Array:
	return GameState.npcs_with("pet")


## Gives the animal a care record if it does not have one (old saves, event pets).
func ensure(id: String) -> Dictionary:
	var n := GameState.npc(id)
	if n.is_empty():
		return n
	if not n.has("care") or not (n["care"] is Dictionary):
		n["care"] = {"fed": 75.0, "tended": true, "source": "event", "since": int(_p().get("age", 0)), "ill": "", "walks": 0}
	Ambition.ensure_pet(id)
	return n


## Brings an animal home. Returns its id. `source` is any key of SOURCES.
func acquire(species: String, source: String = "event", name: String = "", age: int = -1) -> String:
	var kind: Dictionary = KINDS.get(species, KINDS["dog"])
	var a := age if age >= 0 else randi_range(0, 3)
	var id := GameState.create_npc("pet", {"species": species, "first": name if name != "" else ContentDB.random_pet_name(), "last": "", "age": a, "closeness": 60 if source in ["shop", "breeder"] else 55})
	var n := ensure(id)
	n["care"]["source"] = source
	n["care"]["since"] = int(_p().get("age", 0))
	GameState.add_milestone(int(_p().get("age", 0)), "%s %s the %s" % [str(SOURCES.get(source, "took in")), str(n["first"]), str(kind["name"]).to_lower()])
	GameState.counter("pets_kept")
	return id


## Outcome op from authored events: {"species": "cat"|"any", "source": "stray"}.
func gain(spec) -> String:
	var species := "any"
	var source := "event"
	if spec is Dictionary:
		species = str(spec.get("species", "any"))
		source = str(spec.get("source", "event"))
	elif spec is String:
		species = str(spec)
	if pets().size() >= MAX_PETS:
		GameState.add_log("There was no more room in the house for another animal.")
		return ""
	if species == "any":
		species = str(["dog", "cat", "cat", "dog", "rabbit", "hamster", "guinea_pig", "goldfish", "turtle", "ferret"][randi() % 10])
	var id := acquire(species, source)
	GameState.add_log("%s the %s came to live with me." % [str(GameState.npc(id)["first"]), str(KINDS[species]["name"]).to_lower() if KINDS.has(species) else species])
	return id


func yearly() -> void:
	var p := _p()
	var living := 0
	for id in pets():
		var n := ensure(id)
		if not n["alive"]:
			continue
		living += 1
		var c: Dictionary = n["care"]
		var pp: Dictionary = n["pet_profile"]
		var sp := str(n.get("species", "dog"))
		var kind: Dictionary = KINDS.get(sp, KINDS["dog"])
		# feeding: the household pays for the animal without being asked
		var cost := Actions._cost(int(kind["upkeep"]))
		if int(p["money"]) >= cost or int(p["age"]) < 18:
			if int(p["age"]) >= 18:
				p["money"] = int(p["money"]) - cost
			c["fed"] = minf(100.0, float(c["fed"]) + 40.0)
		else:
			c["fed"] = maxf(0.0, float(c["fed"]) - 45.0)
			GameState.add_log("I could not afford proper food for %s this year." % n["first"])
		c["fed"] = maxf(0.0, float(c["fed"]) - 22.0)
		# the animal's bond rises with attention and cools without it
		if bool(c.get("tended", false)):
			n["closeness"] = mini(100, int(n["closeness"]) + 3)
		else:
			n["closeness"] = maxi(0, int(n["closeness"]) - 6)
			if int(n["closeness"]) < 25 and randf() < 0.5:
				GameState.add_log("%s spent most of the year waiting by the door." % n["first"])
		c["tended"] = false
		c["walks"] = 0
		# health follows food, bond and age
		var h := float(pp["health"])
		if float(c["fed"]) < 30.0:
			h -= randf_range(6.0, 14.0)
			GameState.add_log("%s looks thin." % n["first"])
		elif float(c["fed"]) > 60.0:
			h += 2.0
		if int(n["closeness"]) < 20:
			h -= 3.0
		h = clampf(h, 0.0, 100.0)
		pp["health"] = h
		# illness: a bill and a choice
		if str(c.get("ill", "")) != "":
			pp["health"] = maxf(0.0, float(pp["health"]) - 12.0)
		elif randf() < 0.05 + (0.05 if int(n["age"]) > int(kind["life"][0]) * 0.6 else 0.0):
			c["ill"] = str(["a limp", "a cough", "stomach trouble", "an ear infection", "a swollen paw", "something nobody could name"][randi() % 6])
			var fee := Actions._cost(int(150 + int(kind["upkeep"]) * 0.4))
			EventEngine.push_decision({"id": "_pet_ill", "icon": "🩺", "title": "%s is unwell" % n["first"], "text": "%s has %s. The vet can see %s this week for %s." % [n["first"], c["ill"], "them", GameState.fmt_money(fee)], "choices": [
				{"label": "Take %s to the vet (%s)" % [n["first"], GameState.fmt_money(fee)], "outcomes": [{"text": "The vet sorted it. %s was back to normal within days." % n["first"], "effects": {"money": -fee, "happiness": 3}, "pet_cure": id}, {"text": "A long week, but %s pulled through." % n["first"], "effects": {"money": -fee, "stress": 3}, "pet_cure": id}]},
				{"label": "Wait and see", "outcomes": [{"text": "It passed, in the end. I felt guilty for days.", "effects": {"stress": 4, "happiness": -2}}, {"text": "%s got worse before it got better." % n["first"], "effects": {"stress": 6, "happiness": -4}, "pet_harm": [id, 18]}]},
				{"label": "Try a home remedy", "outcomes": [{"text": "Warm blankets and patience. It worked, mostly.", "effects": {"stress": 2}, "pet_cure": id}, {"text": "It did not work, and the vet bill came later, bigger.", "effects": {"money": -int(fee * 1.6), "stress": 5}, "pet_cure": id}]},
			]})
		# old age
		var life := randi_range(int(kind["life"][0]), int(kind["life"][1]))
		if float(pp["health"]) <= 0.0 or (int(n["age"]) >= int(kind["life"][0]) and randf() < clampf((float(n["age"]) - float(kind["life"][0]) + 1.0) / float(maxi(1, life - int(kind["life"][0]) + 3)) * 0.35, 0.02, 0.6)):
			_die(id)
		# run away
		elif int(n["closeness"]) < 8 and float(c["fed"]) < 40.0 and randf() < 0.4:
			n["alive"] = false
			n["rehomed"] = true
			GameState.add_log("%s did not come back. The bowl by the door stayed full for a week." % n["first"])
			GameState.apply_effects({"happiness": -8, "stress": 6})
	if living >= 2 and randf() < 0.12:
		var live: Array = []
		for id2 in pets():
			if GameState.npc(id2)["alive"]:
				live.append(id2)
		if live.size() >= 2:
			GameState.add_log(["%s and %s have worked out a truce over the best chair." % [GameState.npc(live[0])["first"], GameState.npc(live[1])["first"]], "%s and %s curled up together today, as if nothing had ever been said." % [GameState.npc(live[0])["first"], GameState.npc(live[1])["first"]]][randi() % 2])
			GameState.apply_effects({"happiness": 2})


func _die(id: String) -> void:
	var n := GameState.npc(id)
	n["alive"] = false
	GameState.counter("pets_lost")
	var yrs := int(_p().get("age", 0)) - int(n.get("care", {}).get("since", 0))
	Ambition._bereave("%s died. %d years. The house was the wrong kind of quiet afterwards." % [n["first"], maxi(1, yrs)])
	GameState.add_milestone(int(_p().get("age", 0)), "lost %s" % n["first"])
	LifeThreads.remember("grief", "Losing %s" % n["first"], "%s was with me for %d years. I still reach for the lead." % [n["first"], maxi(1, yrs)], id, 60, ["pet", "grief"])


func cure(id: String) -> void:
	var n := GameState.npc(id)
	if n.is_empty():
		return
	ensure(id)
	n["care"]["ill"] = ""
	n["pet_profile"]["health"] = minf(100.0, float(n["pet_profile"]["health"]) + 15.0)


func harm(id: String, amount: float) -> void:
	var n := GameState.npc(id)
	if n.is_empty():
		return
	ensure(id)
	n["pet_profile"]["health"] = maxf(0.0, float(n["pet_profile"]["health"]) - amount)


## Called by the People menu when something is done for the animal.
func tend(id: String, fed_bonus: float = 0.0) -> void:
	var n := ensure(id)
	if n.is_empty():
		return
	n["care"]["tended"] = true
	n["care"]["fed"] = minf(100.0, float(n["care"]["fed"]) + fed_bonus)


## One line for the pet's panel: how it is doing.
func status_line(id: String) -> String:
	var n := ensure(id)
	if n.is_empty():
		return ""
	var c: Dictionary = n["care"]
	var bits: Array = []
	var src := str(SOURCES.get(str(c.get("source", "event")), "came into your life"))
	bits.append(src.substr(0, 1).to_upper() + src.substr(1) + " at %d" % int(c.get("since", 0)))
	if str(c.get("ill", "")) != "":
		bits.append("unwell: " + str(c["ill"]))
	return " · ".join(bits)


# ================================================================ menus (comp:)

func menu(key: String) -> Dictionary:
	var rows: Array = []
	var money := int(_p().get("money", 0))
	var age := int(_p().get("age", 0))
	match key:
		"", "root":
			rows.append({"icon": "🏠", "name": "Animal shelter", "sub": "Adopt. Cheaper, and someone needs you", "menu": "comp:shelter", "on": age >= 8})
			rows.append({"icon": "🛍️", "name": "Pet shop", "sub": "Buy a young animal, supplies, treats", "menu": "comp:shop", "on": age >= 8})
			rows.append({"icon": "🧬", "name": "A breeder", "sub": "Pedigree animals, at a price", "menu": "comp:breeder", "on": age >= 18})
			var mine: Array = []
			for id in pets():
				if GameState.npc(id)["alive"]:
					mine.append(str(GameState.npc(id)["first"]))
			return {"icon": "🐾", "title": "Animals", "rows": rows, "info": ["Your animals: " + (", ".join(mine) if not mine.is_empty() else "none yet")] }
		"shelter", "shop", "breeder":
			var field := "adopt" if key == "shelter" else "buy"
			var order: Array = KINDS.keys()
			for sp in order:
				var k: Dictionary = KINDS[sp]
				if key == "shelter" and sp in ["goldfish", "snake", "lizard", "ferret"] and randi() % 2 == 0:
					pass
				if key == "breeder" and sp in ["hamster", "goldfish", "turtle", "lizard", "snake", "guinea_pig", "rabbit"]:
					continue
				var price := Actions._cost(int(k[field]) * (2 if key == "breeder" else 1))
				var min_age := int(k.get("min_age", 8))
				var why := ""
				if age < min_age:
					why = " · %d+" % min_age
				elif pets().size() >= MAX_PETS:
					why = " · no room"
				rows.append({"icon": str(k["icon"]), "name": "%s (%s)" % [str(k["name"]), GameState.fmt_money(price)], "sub": str(k["blurb"]) + why, "act": "comp:get", "arg": [sp, key, price], "on": money >= price and why == ""})
			if key == "shop":
				rows.append({"icon": "🍖", "name": "Treats and toys", "sub": GameState.fmt_money(Actions._cost(30)), "act": "comp:treats", "arg": null, "on": money >= Actions._cost(30) and not pets().is_empty()})
			return {"icon": {"shelter": "🏠", "shop": "🛍️", "breeder": "🧬"}[key], "title": {"shelter": "Animal shelter", "shop": "Pet shop", "breeder": "Breeder"}[key], "rows": rows, "info": ["Food costs money every year, and an animal that is not fed, walked and visited gets thin and sad."]}
	return {"icon": "🐾", "title": "Animals", "rows": []}


func act(key: String, arg) -> void:
	match key:
		"get":
			var spec: Array = arg
			var sp := str(spec[0])
			var price := int(spec[2])
			if int(_p()["money"]) < price:
				return
			var src: String = str(spec[1])
			_p()["money"] = int(_p()["money"]) - price
			var id := acquire(sp, src)
			var n := GameState.npc(id)
			if src == "breeder":
				n["pet_profile"]["pedigree"] = randi_range(65, 98)
			EventEngine.push_info(icon(sp), "Welcome home, %s" % n["first"], "%s the %s is yours. %s" % [n["first"], str(KINDS[sp]["name"]).to_lower(), str(KINDS[sp]["blurb"])], {"happiness": 8})
			GameState.apply_effects({"happiness": 8})
		"treats":
			var c := Actions._cost(30)
			if int(_p()["money"]) < c:
				return
			_p()["money"] = int(_p()["money"]) - c
			for id in pets():
				if GameState.npc(id)["alive"]:
					tend(id, 10.0)
					GameState.change_closeness(id, 4)
			EventEngine.push_info("🍖", "Treats and toys", "Everyone got something. The house smelled of liver for a day.", {"happiness": 2})

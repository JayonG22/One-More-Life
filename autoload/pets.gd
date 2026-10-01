extends Node

## PETS LIFE — v1.1. A separate way to play: you are the animal.
##
## Nothing in this mode is a reskin of a human system. A pet has no money, no job
## and no calendar of its own; it has a belly, a nose, a person (or several), a
## place it is allowed to be, and a number of years that is not long enough.
## Everything that happens to it happens through the household — somebody loses a
## job, a baby arrives, a marriage ends, the lease runs out — and it has to be
## read from the floor, without being told why.
##
## The life record (player.life) is the whole state. Gauges run 0-100:
##   bond        how much your main person is yours
##   obedience   how reliably you do what you are asked (and how much you choose to)
##   instinct    street sense: noses, doors, weather, who not to trust
##   hunger      how full the bowl has been lately (100 is a very round animal)
##   territory   how much of the world is known and marked as yours
##   belonging   how sure you are that this is your home
##   fitness     the body's slow account
## and the household (life.house) has means (can it afford a vet?) and mood.

const SPECIES := {
	"dog": {"name": "Dog", "icon": "🐕", "baby": "🐶", "old": "🦮", "life": [11, 16], "sound": "woof",
		"stages": ["Puppy", "Adolescent", "Adult", "Senior"], "prey": "squirrel", "noun": "dog",
		"breeds": ["Labrador mix", "Beagle", "Border collie", "Terrier mix", "Greyhound", "Spaniel", "Shepherd cross", "Whippet", "Corgi", "Staffie", "Poodle cross", "Mongrel of great distinction"],
		"tricks": ["Sit", "Shake a paw", "Stay", "Roll over", "Fetch the paper", "Play dead", "Speak on command", "Weave through legs", "Open the back door", "Carry the shopping"],
		"play": "Play fetch", "play_sub": "Fitness and mood", "tame": "walk"},
	"cat": {"name": "Cat", "icon": "🐈", "baby": "🐱", "old": "😺", "life": [13, 20], "sound": "mrrp",
		"stages": ["Kitten", "Adolescent", "Adult", "Senior"], "prey": "mouse", "noun": "cat",
		"breeds": ["Tabby", "Ginger tom", "Tuxedo", "Calico", "Siamese cross", "Grey shorthair", "Tortoiseshell", "Maine Coon cross", "Black cat of ill repute", "Ragdoll"],
		"tricks": ["Come when called", "High-five", "Sit on command", "Fetch a toy mouse", "Use the cat flap on cue", "Wait for the tin opener", "Walk on a lead", "Jump through a hoop"],
		"play": "Chase the string", "play_sub": "Fitness and mood", "tame": "sunbeam"},
	"rabbit": {"name": "Rabbit", "icon": "🐇", "baby": "🐰", "old": "🐇", "life": [7, 11], "sound": "thump",
		"stages": ["Kit", "Adolescent", "Adult", "Senior"], "prey": "dandelion", "noun": "rabbit",
		"breeds": ["Lop-eared", "Dutch", "Netherland dwarf", "Lionhead", "Rex", "Flemish giant", "Mini lop", "Mixed-up grey"],
		"tricks": ["Come when called", "Use the litter tray", "Jump through a hoop", "Spin on command", "Stand tall", "Nudge the food bowl"],
		"play": "Binky around the room", "play_sub": "Fitness and mood", "tame": "hutch"},
	"parrot": {"name": "Parrot", "icon": "🦜", "baby": "🐣", "old": "🦜", "life": [30, 55], "sound": "squawk",
		"stages": ["Chick", "Fledgling", "Adult", "Elder"], "prey": "seed", "noun": "bird",
		"breeds": ["African grey", "Budgerigar", "Cockatiel", "Macaw", "Amazon", "Lovebird", "Cockatoo", "Conure"],
		"tricks": ["Wave", "Whistle a tune", "Say hello", "Imitate the phone", "Say the kettle's on", "Say a name", "Say good morning", "Imitate the microwave"],
		"play": "Ring the bell", "play_sub": "Mood and smarts", "tame": "perch"},
	"horse": {"name": "Horse", "icon": "🐎", "baby": "🐴", "old": "🐎", "life": [24, 32], "sound": "whinny",
		"stages": ["Foal", "Yearling", "Adult", "Veteran"], "prey": "oats", "noun": "horse",
		"breeds": ["Welsh cob", "Thoroughbred", "Quarter horse", "Shire cross", "Arab", "Connemara", "Appaloosa", "Highland pony", "Cold-blooded mystery"],
		"tricks": ["Lead on a rope", "Stand for the farrier", "Accept the saddle", "Walk, trot, canter", "Jump a low fence", "Load into the trailer", "Come to the gate", "Bow"],
		"play": "Gallop the paddock", "play_sub": "Fitness and mood", "tame": "stable"},
}

const ORIGINS := {
	"loving": {"name": "A loving house", "icon": "🏡", "desc": "Born into, or brought straight to, a warm home. The easy start. Complications arrive later.", "life_mod": 1, "home": "home", "bond": 30, "belonging": 70, "instinct": 25, "hunger": 62, "role": "companion"},
	"barn": {"name": "A farm litter", "icon": "🌾", "desc": "Born in straw, used to weather and work. Self-reliant and a little feral about the edges.", "life_mod": 0, "home": "farm", "bond": 24, "belonging": 55, "instinct": 55, "hunger": 52, "role": "companion"},
	"mill": {"name": "A mill", "icon": "⛓️", "desc": "Born in a breeding operation. Underfed, undersocialised and then, if you are lucky, rescued.", "life_mod": -2, "home": "mill", "bond": 8, "belonging": 15, "instinct": 18, "hunger": 28, "role": "companion"},
	"shelter": {"name": "A shelter", "icon": "🏢", "desc": "Born into or arrived in a shelter. A queue of kennels and a lot of people walking past.", "life_mod": 0, "home": "shelter", "bond": 16, "belonging": 25, "instinct": 35, "hunger": 50, "role": "companion"},
	"street": {"name": "The street", "icon": "🌃", "desc": "Born outside. Nobody's, and therefore, in a way, your own. Hard, free and short.", "life_mod": -3, "home": "street", "bond": 6, "belonging": 20, "instinct": 70, "hunger": 34, "role": "stray"},
	"working": {"name": "A working line", "icon": "🐾", "desc": "Bred for a job: herding, rescue or the force. Training begins before you can see properly.", "life_mod": 1, "home": "kennel", "bond": 28, "belonging": 50, "instinct": 55, "hunger": 60, "role": "working"},
	"show": {"name": "A show line", "icon": "🏆", "desc": "Born to a pedigree and a standard. Expensive, groomed, watched, and expected.", "life_mod": 0, "home": "show", "bond": 30, "belonging": 55, "instinct": 20, "hunger": 66, "role": "show"},
}

const ROLES := {
	"companion": {"name": "Companion", "icon": "🛋️", "desc": "Be someone's favourite. Be there when they come home."},
	"watch": {"name": "Guardian", "icon": "🛡️", "desc": "The house and everyone in it is yours to keep safe."},
	"working": {"name": "Working animal", "icon": "🪢", "desc": "Herd, haul or search. Be useful, and be proud of it."},
	"show": {"name": "Show animal", "icon": "🏆", "desc": "The ring, the ribbon, the judges' hands."},
	"therapy": {"name": "Therapy animal", "icon": "💞", "desc": "Visit the people who most need something warm to lean on."},
	"stray": {"name": "Street animal", "icon": "🌃", "desc": "Nobody's, and good at it. Territory, bins and nine routes home."},
	"mouser": {"name": "Barn keeper", "icon": "🏚️", "desc": "Hunt, patrol and keep the place clear of what shouldn't be in it."},
	"racer": {"name": "Racer", "icon": "🏁", "desc": "Speed is a job, if you are good at it."},
}

const PET_TRAITS := ["Curious", "Loyal", "Skittish", "Greedy", "Playful", "Stubborn", "Gentle", "Brave", "Lazy", "Vocal", "Clever", "Clingy"]

const TRAIT_INFO := {
	"Curious": ["🧐", "Gets into things. Finds things. Is occasionally in a cupboard."],
	"Loyal": ["💞", "Bonds deeply and stays. Harder to give up on you."],
	"Skittish": ["🙀", "Startles at the postie, the hoover and the sky."],
	"Greedy": ["🍗", "Food is the most interesting subject there is."],
	"Playful": ["🎾", "Everything is a game, including the things that are not."],
	"Stubborn": ["🪨", "Will do it when it is ready, and not before."],
	"Gentle": ["🕊️", "Soft with small children and old people."],
	"Brave": ["🦁", "Stands between the house and whatever is out there."],
	"Lazy": ["🛋️", "A professional at the sofa."],
	"Vocal": ["📣", "Has views, and shares them."],
	"Clever": ["🧠", "Works out the latch. Works out you."],
	"Clingy": ["🧲", "Cannot see why a door should ever close."],
}

const GAUGES := ["bond", "obedience", "instinct", "hunger", "territory", "belonging", "fitness"]
const SIDE_LABELS := {"happiness": ["😊", "Mood"], "health": ["❤️", "Health"], "smarts": ["🧠", "Wits"], "looks": ["✨", "Coat"], "stress": ["☁️", "Stress"]}

const HOUSEHOLDS := {
	"single": {"name": "a single person", "adults": 1, "kids": 0},
	"couple": {"name": "a couple", "adults": 2, "kids": 0},
	"family": {"name": "a family with children", "adults": 2, "kids": 2},
	"elder": {"name": "an older person living alone", "adults": 1, "kids": 0, "elder": true},
	"students": {"name": "two students sharing a flat", "adults": 2, "kids": 0, "young": true},
	"farm": {"name": "a farming family", "adults": 2, "kids": 1},
}

const JOBS := ["a nurse", "a teacher", "a mechanic", "an accountant", "a delivery driver", "a barista", "a builder", "a carer", "a software developer", "a shopkeeper", "a bus driver", "a cleaner", "a chef", "a postie", "a retired engineer", "a student", "a plumber", "a call-centre worker", "an electrician", "a nursery worker"]

const SENIOR_AT := 0.7


func _p() -> Dictionary:
	return GameState.player


func active() -> bool:
	return not GameState.player.is_empty() and Lives.is_type("pet")


func L() -> Dictionary:
	return Lives.life()


func H() -> Dictionary:
	var l := L()
	if not l.has("house") or not (l["house"] is Dictionary):
		l["house"] = {"type": "single", "means": 55.0, "mood": 60.0, "flags": {}, "baby_years": 0}
	return l["house"]


func sp() -> Dictionary:
	return SPECIES.get(str(L().get("species", "dog")), SPECIES["dog"])


func species() -> String:
	return str(L().get("species", "dog"))


func pick(arr: Array) -> String:
	return str(arr[randi() % arr.size()])


func did(key: String) -> int:
	return int(_p().get("act_year", {}).get(key, 0))


func note(key: String) -> void:
	if not _p().has("act_year"):
		_p()["act_year"] = {}
	_p()["act_year"][key] = did(key) + 1


# ================================================================ names, stages

func title() -> String:
	var l := L()
	return "%s %s" % [str(l.get("breed", "")), str(sp().get("noun", "pet"))]


func lifespan() -> int:
	return int(L().get("lifespan", 14))


func stage_index() -> int:
	var f := float(_p().get("age", 0)) / maxf(1.0, float(lifespan()))
	var young := 1.0 / maxf(1.0, float(lifespan())) * 1.5
	if species() == "horse":
		young = 3.0 / float(lifespan())
	elif species() == "parrot":
		young = 3.0 / float(lifespan())
	if f < young:
		return 0
	if f < 0.25:
		return 1
	if f < SENIOR_AT:
		return 2
	return 3


func stage_name() -> String:
	return str(sp()["stages"][stage_index()])


func is_senior() -> bool:
	return stage_index() >= 3


func portrait() -> String:
	if not bool(_p().get("alive", true)):
		return "😇"
	match stage_index():
		0: return str(sp()["baby"])
		3: return str(sp()["old"])
	return str(sp()["icon"])


func owner_id() -> String:
	var o := GameState.first_of("owner")
	return o


func owner_name(fallback: String = "my human") -> String:
	var o := owner_id()
	if o == "":
		return fallback
	return str(GameState.npc(o).get("first", fallback))


func relation_name(rel: String, _g: String) -> String:
	match rel:
		"owner", "owner2": return "Your human"
		"owner_kid": return "The little human"
		"former_owner": return "Your old human"
		"pet_friend": return "Friend"
		"rival_pet": return "Rival"
		"vet": return "The vet"
		"littermate": return "Littermate"
	return ""


func relation_flavour(id: String) -> String:
	var n := GameState.npc(id)
	var rel := str(n.get("relation", ""))
	var job := str(n.get("job", ""))
	match rel:
		"owner", "owner2":
			return "%s, %d%s" % [str(n.get("title", "")) if str(n.get("title", "")) != "" else "human", int(n.get("age", 30)), (" · " + job) if job != "" else ""]
		"owner_kid":
			return "small human, %d" % int(n.get("age", 6))
		"pet_friend", "rival_pet":
			return "%s, %d" % [str(n.get("species", "dog")), int(n.get("age", 4))]
	return ""


# ================================================================ start

func setup(opts: Dictionary) -> void:
	var p := _p()
	var spk := str(opts.get("species", "dog"))
	if not SPECIES.has(spk):
		spk = "dog"
	var ok := str(opts.get("origin", "loving"))
	if not ORIGINS.has(ok):
		ok = "loving"
	var sd: Dictionary = SPECIES[spk]
	var od: Dictionary = ORIGINS[ok]
	var span := randi_range(int(sd["life"][0]), int(sd["life"][1])) + int(od["life_mod"])
	span = maxi(span, int(int(sd["life"][0]) * 0.6))
	var traits: Array = PET_TRAITS.duplicate()
	traits.shuffle()
	p["traits"] = traits.slice(0, 2)
	p["life"] = {
		"type": "pet", "species": spk, "breed": str(opts.get("breed", pick(sd["breeds"]))), "origin": ok,
		"lifespan": span, "home": str(od["home"]), "role": str(od["role"]), "role_set": false,
		"bond": float(od["bond"]), "obedience": 12.0, "instinct": float(od["instinct"]), "hunger": float(od["hunger"]),
		"territory": 10.0, "belonging": float(od["belonging"]), "fitness": 55.0,
		"tricks": [], "vocab": [], "heroics": 0, "titles": 0, "escapes": 0, "litters": 0, "rescues": 0, "lost": false,
		"lost_years": 0, "shelter_years": 0, "street_years": 0, "illness": "", "vaccinated": ok != "street" and ok != "mill",
		"shows": 0, "shifts": 0, "visits": 0, "rehomed": 0, "years_with": 0, "stage_seen": 0,
		"mischief": 0, "friends_made": 0, "trusted": [], "inherit": opts.get("inherit", {}),
	}
	var st: Dictionary = p["stats"]
	st["happiness"] = 70.0 if ok in ["loving", "show"] else 55.0
	st["health"] = {"loving": 90.0, "barn": 86.0, "mill": 62.0, "shelter": 78.0, "street": 70.0, "working": 90.0, "show": 92.0}[ok]
	st["smarts"] = float(randi_range(35, 75))
	st["looks"] = float(randi_range(40, 80)) + (12.0 if ok == "show" else 0.0)
	st["stress"] = {"mill": 55.0, "shelter": 40.0, "street": 45.0}.get(ok, 15.0)
	p["housing"] = "parents"
	p["money"] = 0
	p["country"] = str(opts.get("country", p.get("country", "us")))
	p["born_year"] = int(opts.get("born_year", p.get("born_year", GameState.START_YEAR)))
	GameState.npcs.clear()
	GameState.next_npc_id = 1
	_start_household(ok)
	GameState.log_years.clear()
	GameState.milestones.clear()
	GameState.log_years.append({"age": 0, "lines": []})
	_birth_story(ok)
	GameState.counter("life_pet")
	GameState.counter("pet_" + spk)
	var ms: Dictionary = Meta.meta.get("pets_species", {})
	ms[spk] = true
	Meta.meta["pets_species"] = ms


func _birth_story(ok: String) -> void:
	var l := L()
	var nm := str(_p()["first"])
	var sd := sp()
	var inh: Dictionary = l.get("inherit", {})
	var lines := {
		"loving": ["I was born in a basket in the corner of a kitchen, and the first thing I knew was the sound of people deciding what to call me.", "The first thing I saw was a large, kind face and a ceiling. They called me %s. It stuck." % nm],
		"barn": ["I was born in straw, with the smell of animals and rain on the roof. Someone had left a radio on for us.", "The barn was loud, warm and full of elbows. I had siblings, and then, gradually, I had fewer."],
		"mill": ["I was born in a metal pen under a strip light, in a row of other pens. I did not know there was a different kind of world.", "The first sound I knew was a fan. The first hands I knew were in gloves."],
		"shelter": ["I was born, or arrived, in a kennel with a card on the door. People came and read it. Some of them said my name aloud, which was a good sign.", "The shelter smelled of bleach and hope. Every day a door opened somewhere, and everyone turned to look."],
		"street": ["I was born in the lee of a wall behind a restaurant, under a pallet. My mother kept us alive by being cleverer than the bins.", "The first world I knew was the alley: wet, loud, full of exits. I learned the doors before I learned my name."],
		"working": ["I was born into a line that had done a job for generations, and everyone around me behaved as though it were already decided.", "The first thing I learned was the word 'good'. The second was that there is a version of it you have to earn."],
		"show": ["I was born into a whelping box lined with clean towels, with a person writing down my weight like it mattered. It did. It was a question of the standard.", "The breeder looked at me and then at a chart, and I was, apparently, promising."],
	}
	GameState.add_log(pick(lines[ok]))
	GameState.add_milestone(0, "was born as %s %s %s" % ["an" if str(sd["noun"]).begins_with("a") else "a", str(l["breed"]).to_lower(), str(sd["noun"])])
	if not inh.is_empty():
		GameState.add_log("The house still smelled, faintly, of the one who had been here before. %s had kept the old collar on the hook by the door." % owner_name("The household"))
		GameState.add_milestone(0, "came to a house that remembered %s" % str(inh.get("name", "another one")))
	if ok in ["loving", "barn", "working", "show"]:
		l["years_with"] = 0


# ================================================================ households

func _surname() -> String:
	return str(_p().get("last", "Moreno"))


func _start_household(ok: String) -> void:
	var kind := "single"
	match ok:
		"loving": kind = ["single", "couple", "family", "family", "elder", "students"][randi() % 6]
		"barn": kind = "farm"
		"working": kind = "single"
		"show": kind = "couple"
		_: kind = ""
	var h := H()
	h["means"] = float({"loving": randi_range(40, 78), "barn": randi_range(30, 55), "working": randi_range(45, 65), "show": randi_range(70, 90)}.get(ok, 25))
	h["mood"] = 60.0
	h["type"] = kind if kind != "" else "none"
	if kind != "":
		_make_household(kind, ok)
		L()["adopted_at"] = 0
		_remember_house()
	else:
		_p()["last"] = "of the %s" % {"mill": "Mill", "shelter": "Shelter", "street": "Alley"}[ok]


## The house that kept the one before keeps the same names, and has aged.
func _remember_house() -> void:
	var inh: Dictionary = L().get("inherit", {})
	if inh.is_empty() or str(inh.get("house", "")) == "":
		return
	_p()["last"] = str(inh["house"])
	for id in _owners():
		var n: Dictionary = GameState.npcs[id]
		n["last"] = str(inh["house"])
		n["age"] = int(n["age"]) + int(inh.get("years", 10))
		if str(n["relation"]) == "owner" and str(inh.get("owner", "")) != "":
			n["first"] = str(inh["owner"])


func _make_household(kind: String, via: String = "") -> void:
	var def: Dictionary = HOUSEHOLDS[kind]
	var sn: String = ContentDB.random_last(str(_p().get("country", "us")))
	var h := H()
	h["type"] = kind
	for id in GameState.npcs.keys():
		var n: Dictionary = GameState.npcs[id]
		if str(n.get("relation", "")) in ["owner", "owner2", "owner_kid"]:
			n["relation"] = "former_owner"
	var base_age := randi_range(24, 52)
	if def.get("elder", false):
		base_age = randi_range(66, 84)
	elif def.get("young", false):
		base_age = randi_range(19, 25)
	for i in range(int(def["adults"])):
		var g := "male" if randf() < 0.5 else "female"
		var role := "owner" if i == 0 else "owner2"
		var id := GameState.create_npc(role, {"gender": g, "last": sn, "age": base_age + randi_range(-4, 4), "closeness": 20, "species": "human"})
		GameState.npcs[id]["job"] = "" if def.get("elder", false) else pick(JOBS)
		if via == "handler" or (via == "working" and i == 0):
			GameState.npcs[id]["title"] = "Handler"
	var kids := int(def["kids"])
	if kids > 0:
		kids = randi_range(1, kids)
	for k in range(kids):
		var kid := GameState.create_npc("owner_kid", {"age": randi_range(2, 14), "last": sn, "closeness": 20, "species": "human"})
		GameState.npcs[kid]["job"] = ""
	_p()["last"] = sn
	var o := owner_id()
	if o != "":
		GameState.npcs[o]["closeness"] = int(float(L().get("bond", 20)))
	L()["home"] = "home" if via not in ["working", "show", "barn"] else str(L()["home"])


func _adopt(reason: String) -> void:
	var l := L()
	var kind: String = ["single", "couple", "family", "family", "elder", "students"][randi() % 6]
	var was := str(l.get("home", ""))
	_make_household(kind)
	l["home"] = "home"
	l["adopted_at"] = int(_p()["age"])
	l["belonging"] = maxf(float(l["belonging"]), 45.0)
	l["shelter_years"] = 0
	l["street_years"] = 0
	var h := H()
	h["means"] = float(randi_range(35, 80))
	var who := owner_name()
	var line := reason
	if line == "":
		line = "Someone came to the kennel and stopped."
	GameState.add_log("%s It was %s, and %s. %s would take me home." % [line, who, HOUSEHOLDS[kind]["name"], who])
	GameState.add_milestone(int(_p()["age"]), "was taken home by %s" % who)
	GameState.counter("pet_adopted")
	if was == "street":
		L()["rescues"] = int(L().get("rescues", 0)) + 1
	_p()["stats"]["stress"] = maxf(0.0, GameState.stat("stress") - 15.0)


func _owners() -> Array:
	var out: Array = []
	for r in ["owner", "owner2", "owner_kid"]:
		out.append_array(GameState.npcs_with(r))
	return out


func _lose_household(why: String) -> void:
	var l := L()
	for id in _owners():
		GameState.npcs[id]["relation"] = "former_owner"
	l["rehomed"] = int(l.get("rehomed", 0)) + 1
	GameState.add_milestone(int(_p()["age"]), why)


# ================================================================ the year

func yearly() -> void:
	var l := L()
	var p := _p()
	var age := int(p["age"])
	var h := H()
	l["years_with"] = int(l.get("years_with", 0)) + 1
	GameState.counter("pet_years")
	# stage changes are told, once
	var si := stage_index()
	if si > int(l.get("stage_seen", 0)):
		l["stage_seen"] = si
		_stage_line(si)
	# the place and the people
	match str(l["home"]):
		"home", "farm", "kennel", "show": _household_year()
		"shelter": _shelter_year()
		"street": _street_year()
		"mill": _mill_year()
	if bool(l.get("lost", false)):
		_lost_year()
	_body_year()
	_bond_year()
	_role_year()
	_flavour_year()
	# gauges that fade without use
	l["obedience"] = clampf(float(l["obedience"]) - 2.5, 0.0, 100.0)
	l["territory"] = clampf(float(l["territory"]) - 3.0, 0.0, 100.0)
	h["mood"] = clampf(float(h["mood"]) + (60.0 - float(h["mood"])) * 0.25, 0.0, 100.0)
	GameState.apply_effects({"stress": -4})
	# regress mood
	var hp := GameState.stat("happiness")
	GameState.change_stat("happiness", (62.0 - hp) * 0.1)
	if age >= 1 and age == int(l.get("adopted_at", -9)):
		pass


func _stage_line(si: int) -> void:
	var nm := species()
	var lines := {
		1: {"dog": ["My legs and my feet stopped agreeing and then, one morning, agreed. I could run, and I did, mostly into things.", "I chewed a shoe, a remote, a corner of the sofa and part of the door, in that order, with a sort of scientific commitment."],
			"cat": ["I discovered that I could reach the top of the fridge, and that there is no good reason to come down.", "The world got a third dimension and I have been using all of it."],
			"rabbit": ["I found out that I could jump, which was alarming, and then that I could jump and twist, which was not alarming at all.", "The first binky was an accident. The second was on purpose."],
			"parrot": ["I learned that when I make a noise, someone makes one back, and that this is a conversation.", "My feathers came in all at once, like an opinion."],
			"horse": ["My legs finally belonged to me. I celebrated by running in a straight line until the fence told me to stop.", "I learned that a halter is not a threat, only an opinion with a strap."]},
		2: {"dog": ["Adulthood came without warning: one day I noticed that I could sit still, and wanted to.", "I stopped being surprised by the post and started being right about it."],
			"cat": ["I settled into the house like it had been drawn around me. There is a chair that is mine. Everyone has agreed.", "I became, officially, the one who decides."],
			"rabbit": ["I found my corner, and my schedule, and the people learned both.", "I grew into my ears."],
			"parrot": ["I came into my full colour and with it, apparently, my full personality. The household has been adjusting since.", "I know exactly forty-one sounds now, and I use them for effect."],
			"horse": ["I filled out. I stopped being all neck and legs and became, according to the vet, a horse.", "A horse is not finished at four, but I'm mostly the horse I am going to be."]},
		3: {"dog": ["There is grey on my muzzle. I noticed it in the reflection of the oven door, and then so did everyone else.", "Stairs have become a discussion. I lose it sometimes and I'm allowed to, now."],
			"cat": ["The jumps got a bit shorter. Nobody has said anything. I have simply started taking the long way to the high places.", "I sleep for most of the day and it's the best part of the day, and I'd like that noted."],
			"rabbit": ["I move slower now and the humans carry me up the step. I let them. It's a good way to be carried.", "I don't binky much any more, but I still decide what happens in this room."],
			"parrot": ["I know this house the way a river knows its bed. Everyone who lives here has changed around me.", "People tell me I'm old now. I tell them what I said earlier, in their own voice."],
			"horse": ["The winter takes longer to leave my joints. The vet has a new word for it, and a new supplement.", "I know every post on the fence and most of the people who built them."]},
	}
	var set: Dictionary = lines.get(si, {})
	var ls: Array = set.get(nm, [])
	if not ls.is_empty():
		GameState.add_log(pick(ls))
	GameState.add_milestone(int(_p()["age"]), "became a%s %s" % ["n" if stage_name().begins_with("A") or stage_name().begins_with("E") else "", stage_name().to_lower()])


# ---------------------------------------------------------------- the household

func _household_year() -> void:
	var l := L()
	var h := H()
	var flags: Dictionary = h["flags"]
	for k in flags.keys():
		flags[k] = int(flags[k]) - 1
		if int(flags[k]) <= 0:
			flags.erase(k)
	# everybody is a year older
	for id in _owners():
		var n: Dictionary = GameState.npcs[id]
		n["age"] = int(n["age"]) + 1
		if str(n["relation"]) == "owner_kid" and int(n["age"]) >= 18:
			n["relation"] = "former_owner"
			GameState.add_log("%s left for university, with a suitcase, a lanyard and a long goodbye with me on the step. The house got quieter, and bigger." % str(n["first"]))
			h["mood"] = float(h["mood"]) - 6.0
	var owners := GameState.npcs_with("owner")
	var o := owner_id()
	h["means"] = clampf(float(h["means"]) + float(randi_range(-6, 5)), 6.0, 96.0)
	if o == "":
		_orphaned()
		return
	var on: Dictionary = GameState.npcs[o]
	var oage := int(on["age"])
	var r := randf()
	var cum := 0.0
	var kind := str(h.get("type", "single"))
	# job loss
	cum += 0.055
	if r < cum and oage < 66 and kind != "elder":
		h["means"] = clampf(float(h["means"]) - 24.0, 6.0, 96.0)
		h["mood"] = float(h["mood"]) - 14.0
		flags["tight"] = 3
		GameState.add_log(pick([
			"%s lost the job. For a week there was a lot of the afternoon sofa and very little of the walk, and I was careful not to ask for either." % owner_name(),
			"There were letters on the mat and a new, quiet kind of carefulness in the house. The good tins stopped. Nobody said why.",
			"%s came home early with a cardboard box and put it down very gently. I stayed pressed against their leg for the whole evening." % owner_name()]))
		L()["hunger"] = float(l["hunger"]) - 6.0
		GameState.apply_effects({"stress": 5})
		return
	cum += 0.055
	if r < cum and oage < 66:
		h["means"] = clampf(float(h["means"]) + 20.0, 6.0, 96.0)
		h["mood"] = float(h["mood"]) + 8.0
		GameState.add_log(pick([
			"%s got a better job. The food got better, there were new toys in a bag and, once, a whole cooked chicken." % owner_name(),
			"Something good had happened at work. The whole house smelled of celebration and someone's dropped cake.",
			"There was a new sofa. Not a better sofa, a different one, which meant starting the whole business of the arm again."]))
		return
	cum += 0.07
	if r < cum and oage < 44 and (kind in ["couple", "family", "farm"]) and int(h.get("baby_years", 0)) <= 0:
		var kid := GameState.create_npc("owner_kid", {"age": 0, "last": str(_p()["last"]), "closeness": 20, "species": "human"})
		GameState.npcs[kid]["job"] = ""
		h["baby_years"] = 3
		flags["baby"] = 3
		h["mood"] = float(h["mood"]) + 6.0
		GameState.add_log(pick([
			"There is a new human. It is small, wet, loud and entirely unprepared, and everyone has stopped looking at me.",
			"A tiny human arrived in a car seat. The house now smells of milk and powder, and my bowl is sometimes late.",
			"They brought a baby home. I was shown it, sniffed it, and was told 'gently' about forty times."]))
		GameState.add_milestone(int(_p()["age"]), "met the new baby, %s" % str(GameState.npcs[kid]["first"]))
		l["bond"] = float(l["bond"]) - 4.0
		GameState.apply_effects({"stress": 6, "happiness": -3})
		return
	cum += 0.05
	if r < cum:
		_move_house()
		return
	cum += 0.04
	if r < cum and kind in ["couple", "family"] and not GameState.npcs_with("owner2").is_empty():
		_breakup()
		return
	cum += 0.05
	if r < cum and kind in ["single", "elder"] and GameState.npcs_with("owner2").is_empty() and oage < 70:
		var g := "male" if randf() < 0.5 else "female"
		var id2 := GameState.create_npc("owner2", {"gender": g, "age": oage + randi_range(-6, 6), "last": str(_p()["last"]), "closeness": 8, "species": "human"})
		GameState.npcs[id2]["job"] = pick(JOBS)
		h["type"] = "couple"
		h["mood"] = float(h["mood"]) + 8.0
		GameState.add_log(pick([
			"%s started coming round, and then staying. Their shoes appeared in the hall, then their toothbrush, then their opinions about where I sleep." % str(GameState.npcs[id2]["first"]),
			"A new person smelled of someone else's house and my person's good aftershave. I withheld judgement and then, around Thursday, ate their sandwich.",
			"There is a second human now. They are nervous around me, which I have decided to take as respect."]))
		return
	cum += 0.03
	if r < cum and oage < 70:
		h["mood"] = float(h["mood"]) - 20.0
		flags["unwell"] = 2
		GameState.add_log(pick([
			"%s was ill for a long while. I lay on the bed and kept watch, which is a thing I'm good at. It's not complicated: I stay." % owner_name(),
			"%s went to the hospital for a week. A neighbour fed me. I sat at the door and waited for the sound of the particular key." % owner_name()]))
		l["bond"] = float(l["bond"]) + 3.0 if randf() < 0.6 else float(l["bond"])
		GameState.apply_effects({"stress": 6})
		return
	if oage >= 74 and randf() < 0.03 + (oage - 74) * 0.013:
		_owner_dies(o)
		return
	if float(h["means"]) < 22.0 and randf() < 0.14:
		_rehome_attempt("The money ran out in the way it does: a little each month, until a conversation happened in the kitchen that I wasn't supposed to hear.")
		return
	if float(l["belonging"]) < 22.0 and float(l["bond"]) < 25.0 and randf() < 0.18:
		_rehome_attempt("I wasn't the pet they'd thought I'd be. Nobody was cruel about it. That was almost worse.")
		return
	# a quiet year
	if randf() < 0.55:
		GameState.add_log(_quiet_line())
	owners.clear()


func _quiet_line() -> String:
	var o := owner_name()
	var s := species()
	var pool: Array = [
		"A quiet year, the good kind: the same walk, the same sofa, the same song %s hums while the kettle boils." % o,
		"Nothing happened this year in the way that matters most. %s was home, and so was I." % o,
		"%s sat on the back step in the evenings with a mug and said things aloud, as if to me. I think they were important." % o,
		"We found a rhythm: the morning, the bowl, the door, the evening, the sofa. It's a good rhythm. I would have chosen it.",
		"%s talked to me on the phone, which I know isn't the same, but also is." % o,
	]
	match s:
		"dog": pool.append("The mat by the door is now the shape of me. I check it every day.")
		"cat": pool.append("%s bought a different brand of food and I let them know exactly what I thought of it, for eleven days." % o)
		"rabbit": pool.append("I found a new corner of the house where nobody could see me, and for a while this was the entire game.")
		"parrot": pool.append("I learned the sound of %s's car and announced it, every evening, to an empty room." % o)
		"horse": pool.append("The seasons went round the field. Grass, mud, frost, grass. I know where the sun lands at every hour.")
	return pick(pool)


func _move_house() -> void:
	var l := L()
	var h := H()
	l["territory"] = float(l["territory"]) * 0.3
	h["flags"]["moved"] = 2
	GameState.add_log(pick([
		"The boxes came out. Everything I knew was wrapped in newspaper, and then there was a car, and then a different smell. I walked every room twice and then lay down in the one that held the most of %s." % owner_name(),
		"We moved. The new place had a garden, or a balcony, or a long corridor. I learned it by morning and decided it was acceptable.",
		"They packed the house into a van. I sat in the one empty room and watched everything leave, and then they carried me out as well."]))
	GameState.add_milestone(int(_p()["age"]), "moved to a new home")
	GameState.apply_effects({"stress": 8, "happiness": -2})
	l["belonging"] = float(l["belonging"]) - 8.0
	h["mood"] = float(h["mood"]) - 6.0


func _breakup() -> void:
	var l := L()
	var h := H()
	var leaver := "owner2" if randf() < 0.6 else "owner"
	var id := GameState.first_of(leaver)
	if id == "":
		return
	var n: Dictionary = GameState.npcs[id]
	n["relation"] = "former_owner"
	h["mood"] = float(h["mood"]) - 22.0
	h["flags"]["split"] = 3
	h["type"] = "single"
	GameState.add_milestone(int(_p()["age"]), "watched the household split")
	if leaver == "owner":
		# the first owner left; promote the other
		var rest := GameState.first_of("owner2")
		if rest != "":
			GameState.npcs[rest]["relation"] = "owner"
	if randf() < 0.28:
		var took := str(n["first"])
		GameState.add_log("%s left, and the question of who got me was raised and discussed, behind a door, at length. In the end I went with %s. I was never asked." % [took, took])
		var keep := GameState.first_of("owner")
		if keep != "":
			GameState.npcs[keep]["relation"] = "former_owner"
		n["relation"] = "owner"
		n["closeness"] = int(l["bond"]) - 6
		l["territory"] = float(l["territory"]) * 0.4
		l["bond"] = float(l["bond"]) - 8.0
	else:
		GameState.add_log(pick([
			"%s left with two bags and a final scratch behind my ears, and the house had the stunned feel of a place after a thunderclap. I stayed with %s." % [str(n["first"]), owner_name()],
			"There were doors, and voices behind them, and then there was one fewer pair of shoes in the hall. %s sat on the floor and I put my head in their lap." % owner_name()]))
	GameState.apply_effects({"stress": 8, "happiness": -4})


func _owner_dies(id: String) -> void:
	var l := L()
	var n: Dictionary = GameState.npcs[id]
	n["alive"] = false
	var nm := str(n["first"])
	GameState.add_milestone(int(_p()["age"]), "lost %s" % nm)
	GameState.add_log(pick([
		"%s did not get up one morning. I stayed beside them until the door opened and the noise began. I have never been so sure of a thing I was not able to say." % nm,
		"%s died in the night. I knew before anybody told me, and I lay across their shoes until someone came." % nm,
		"A long day of strangers in the house, quiet voices and a lot of tea. %s was gone, and nobody could explain it to me, and I understood it anyway." % nm]))
	GameState.apply_effects({"happiness": -14, "stress": 12})
	l["bond"] = float(l["bond"]) * 0.7
	var kin := GameState.first_of("owner2")
	if kin != "" and kin != id:
		GameState.npcs[kin]["relation"] = "owner"
		GameState.add_log("%s kept me. We kept each other." % str(GameState.npcs[kin]["first"]))
		return
	if randf() < 0.55:
		var kid := GameState.first_of("owner_kid")
		if kid != "" and int(GameState.npcs[kid]["age"]) >= 12:
			GameState.npcs[kid]["relation"] = "owner"
			GameState.add_log("%s, who was young but not that young, said I'd be coming home with them. They held the lead as though it were the whole of the estate." % str(GameState.npcs[kid]["first"]))
			return
		_adopt("A niece I had met twice took me in a taxi to a flat that smelled of cooking.")
		H()["flags"]["grief"] = 3
		return
	_rehome_attempt("Nobody else could keep me. It was said kindly, over and over.")


func _rehome_attempt(line: String) -> void:
	var l := L()
	GameState.add_log(line)
	_lose_household("was given up")
	l["home"] = "shelter"
	l["belonging"] = 18.0
	l["bond"] = float(l["bond"]) * 0.3
	l["shelter_years"] = 0
	GameState.add_log(pick([
		"They took me to a building with a lot of kennels and a lot of other animals making the noise I wanted to make. A woman said, 'It's not your fault.' I wasn't sure what she meant.",
		"A stranger took me out of the car and walked me down a corridor of barking. I was given a blanket that smelled of other animals' fear.",
		"I was left with a bag of my things, my bowl and a note. I didn't know what the note said but I knew it was kind, and I knew it wasn't enough."]))
	GameState.apply_effects({"happiness": -12, "stress": 15})
	GameState.counter("pet_rehomed")


func _orphaned() -> void:
	var l := L()
	if str(l["home"]) == "home":
		_rehome_attempt("There was nobody left in the house, and a man in a vest came with a clipboard and a kind voice.")


# ---------------------------------------------------------------- shelter, street, mill

func _shelter_year() -> void:
	var l := L()
	l["shelter_years"] = int(l.get("shelter_years", 0)) + 1
	var chance := 0.34 + float(GameState.stat("looks")) / 280.0 + float(l["bond"]) / 400.0 + (0.12 if float(l["obedience"]) > 40.0 else 0.0)
	chance -= 0.04 * float(int(l["shelter_years"]) - 1)
	if int(_p()["age"]) > 7:
		chance -= 0.12
	if randf() < clampf(chance, 0.08, 0.85):
		_adopt(pick([
			"A woman stopped at my kennel, and then stayed there after the others had gone, reading my card a second time.",
			"A family came through with a child holding both parents' hands. The child stopped at my door. Nobody could move them.",
			"A man in a work jacket asked to see the 'one nobody picks'. The volunteer looked at me, and then at him. It turned out that was me."]))
		return
	GameState.apply_effects({"happiness": -3, "stress": 3})
	l["hunger"] = clampf(float(l["hunger"]) + (55.0 - float(l["hunger"])) * 0.4, 0.0, 100.0)
	GameState.add_log(pick([
		"Another year in the kennel. The volunteers learned my name, and then the new ones learned it, and the new ones are always more tender than the old.",
		"People came and went past the bars. I got very good at the posture that says 'choose me' without seeming to ask.",
		"The shelter was full that year. They put a second blanket in with me and a different animal in the next kennel every month.",
		"A volunteer named %s walked me round the yard every Tuesday for the whole year. It was the best thing in the week and, I think, in theirs." % ContentDB.random_first("female", "us")]))
	if int(l["shelter_years"]) >= 4 and randf() < 0.3:
		_street_exit("The shelter closed its doors that winter, and transferred some of us across the county. I wasn't on a list.")


func _street_exit(line: String) -> void:
	var l := L()
	GameState.add_log(line)
	l["home"] = "street"
	l["belonging"] = 20.0
	GameState.add_milestone(int(_p()["age"]), "ended up on the street")


func _mill_year() -> void:
	var l := L()
	GameState.apply_effects({"health": -2, "stress": 4})
	if int(_p()["age"]) >= 1 and randf() < 0.85:
		GameState.add_log("One morning there was a different noise: not the fan, but doors, boots and people saying 'oh my God' in the wrong key. A woman picked me up and I didn't know what to do with my own legs.")
		GameState.add_milestone(int(_p()["age"]), "was rescued from a mill")
		l["rescues"] = int(l.get("rescues", 0)) + 1
		l["home"] = "shelter"
		l["belonging"] = 28.0
		l["hunger"] = 55.0
		GameState.counter("pet_rescued")
		GameState.apply_effects({"happiness": 8, "stress": -10, "health": 6})
		return
	GameState.add_log("Another season in the pen. There is a patch of floor that is the whole of the world, and I know it as exactly as you know a coin.")


func _street_year() -> void:
	var l := L()
	l["street_years"] = int(l.get("street_years", 0)) + 1
	var instinct := float(l["instinct"])
	var terr := float(l["territory"])
	var forage := 22.0 + instinct * 0.42 + terr * 0.2
	l["hunger"] = clampf(float(l["hunger"]) + (forage - float(l["hunger"])) * 0.45, 5.0, 100.0)
	if float(l["hunger"]) < 28.0:
		GameState.apply_effects({"health": -5, "happiness": -3})
		GameState.add_log("A hungry winter. I ate what the bins allowed and what the pigeons left, and I learned which back doors had a person behind them who didn't look away.")
	var cars := 0.05 - instinct / 3000.0
	if randf() < cars:
		GameState.apply_effects({"health": -22, "stress": 10})
		GameState.add_log("A car on the wet road, and a long minute in which my body didn't belong to me. I crawled under a skip and waited to find out what I was.")
	var winter := randf() < 0.3
	if winter:
		GameState.apply_effects({"health": -3, "stress": 4})
		GameState.add_log(pick([
			"The cold came early. I slept in a stairwell with my nose in my tail, and a woman on the third floor left the door on the latch without ever coming down to see.",
			"A hard frost. I curled behind the extractor fan at the back of a restaurant and thought about nothing, which is the best skill I have.",
			"Rain for nine days. I became an expert in the dry ground beneath things."]))
	var adopt := 0.11 + float(GameState.stat("looks")) / 600.0 + (float(l["bond"]) / 600.0)
	if int(_p()["age"]) > 8:
		adopt -= 0.06
	if randf() < adopt:
		_adopt(pick([
			"A woman sat on the kerb with a sausage roll for four evenings running, and on the fifth she opened the car door.",
			"A man put down a bowl, backed away, and stayed. It took him a month. I was patient. I was also hungry.",
			"A child said 'that one is mine', a parent said 'absolutely not', and then, three days later, the parent was the one carrying the lead."]))
		return
	if randf() < 0.45:
		GameState.add_log(pick([
			"The street went on being the street. I knew its doors, its habits and its weather, and I had a corner of it that smelled of me.",
			"I patrolled my three streets at dusk. They were mine in the sense that nobody else had bothered to argue.",
			"A year out here teaches you who is kind, which is mostly not who looks it."]))


func _lost_year() -> void:
	var l := L()
	l["lost_years"] = int(l.get("lost_years", 0)) + 1
	var find := 0.45 + float(l["bond"]) / 220.0
	if randf() < find and GameState.first_of("owner") != "":
		l["lost"] = false
		l["home"] = "home"
		l["lost_years"] = 0
		GameState.add_log("There was a chip, a poster on a lamp post and a stranger with a scanner, and then a sound I'd have known in a thousand: %s calling my name. I ran the last forty yards without deciding to." % owner_name())
		GameState.add_milestone(int(_p()["age"]), "found their way home")
		GameState.apply_effects({"happiness": 18, "stress": -12})
		l["bond"] = float(l["bond"]) + 8.0
		GameState.counter("pet_found")
	else:
		l["home"] = "street"
		GameState.add_log("I walked and I walked, and the smell of home thinned out into the smell of everywhere. I'm not sure when I decided to stop looking.")
		if int(l["lost_years"]) >= 2:
			l["lost"] = true


# ---------------------------------------------------------------- body, bond, role

func _body_year() -> void:
	var l := L()
	var home := str(l["home"])
	var h := H()
	var target := 50.0
	match home:
		"home", "farm": target = 46.0 + float(h["means"]) * 0.42
		"kennel", "show": target = 62.0
		"shelter": target = 50.0
		"mill": target = 28.0
		"street": target = 30.0
	if bool(h["flags"].has("tight")):
		target -= 10.0
	l["hunger"] = clampf(float(l["hunger"]) + (target - float(l["hunger"])) * 0.4, 3.0, 100.0)
	var hun := float(l["hunger"])
	if hun < 25.0:
		GameState.apply_effects({"health": -4, "happiness": -3})
		GameState.add_log("I was hungry in the way that makes the whole world into a smell. My ribs became a thing I could count.")
	elif hun > 88.0 and float(l["fitness"]) < 45.0:
		GameState.apply_effects({"health": -3, "looks": -2})
		GameState.add_log("I got round. The vet used a word that wasn't unkind, and a chart with a picture of a sleek animal I did not recognise.")
	# fitness account
	var fit := float(l["fitness"]) - (3.0 if stage_index() < 3 else 5.0)
	l["fitness"] = clampf(fit, 5.0, 100.0)
	# age takes its due
	var f := float(_p()["age"]) / maxf(1.0, float(lifespan()))
	var net := 1.5 - maxf(0.0, f - 0.55) * 8.0
	if f < 0.2:
		net += 1.0
	if float(l["fitness"]) > 65.0:
		net += 1.0
	if hun < 25.0 or hun > 90.0:
		net -= 2.0
	if str(l.get("illness", "")) != "":
		net -= 2.0
	GameState.change_stat("health", net)
	# illness
	var ill := str(l.get("illness", ""))
	if ill != "":
		var care := float(h["means"]) / 100.0 + (0.2 if bool(l.get("vaccinated", false)) else 0.0)
		if randf() < 0.35 + care * 0.3:
			GameState.add_log("I got over the %s. I was not told I would, which is the whole thing about being ill." % ill)
			l["illness"] = ""
		else:
			GameState.apply_effects({"health": -4, "happiness": -3})
			GameState.add_log("The %s hung on. Everything was heavier." % ill)
	else:
		var scale := 14.0 / maxf(14.0, float(lifespan()))
		var chance := (0.05 + (0.05 if not bool(l.get("vaccinated", false)) else 0.0) + (0.04 if home in ["street", "mill"] else 0.0)) * scale + f * 0.12
		if randf() < chance:
			var pool := ["a cough that wouldn't go", "a bad stomach", "an ear infection", "a limp", "fleas and a rash", "a swollen paw"]
			match species():
				"cat": pool.append_array(["a cold in the nose", "a bladder complaint"])
				"rabbit": pool.append_array(["sore hocks", "a gut slowdown", "overgrown teeth"])
				"parrot": pool.append_array(["feather-plucking", "a respiratory rattle"])
				"horse": pool.append_array(["laminitis", "colic", "a hoof abscess"])
				"dog": pool.append_array(["kennel cough", "a hot spot", "bad hips"])
			l["illness"] = pick(pool)
			GameState.apply_effects({"health": -5, "happiness": -3})
			GameState.add_log("I came down with %s." % str(l["illness"]))
			if float(h["means"]) < 30.0 and home == "home":
				GameState.add_log("I heard the word 'afford' in the kitchen, and I understood that it was about me.")
				l["bond"] = float(l["bond"]) - 2.0
	if str(l.get("home", "")) == "home" and not did("vet_year") > 0 and stage_index() == 0:
		pass


func _bond_year() -> void:
	var l := L()
	var o := owner_id()
	if o == "" or str(l["home"]) not in ["home", "farm", "kennel", "show"]:
		return
	var h := H()
	var d := 1.2
	if float(h["mood"]) < 35.0:
		d -= 1.0
	if h["flags"].has("baby"):
		d -= 2.0
	if float(l["hunger"]) < 30.0:
		d -= 1.5
	if GameState.stat("happiness") > 70.0:
		d += 1.0
	if float(_p()["stats"]["stress"]) > 70.0:
		d -= 1.0
	l["bond"] = clampf(float(l["bond"]) + d, 0.0, 100.0)
	l["belonging"] = clampf(float(l["belonging"]) + 0.07 * float(l["bond"]) - 1.5 + (1.0 if float(h["mood"]) > 55.0 else -1.0), 0.0, 100.0)
	var on: Dictionary = GameState.npcs[o]
	on["closeness"] = int(l["bond"])


func _role_year() -> void:
	var l := L()
	var role := str(l.get("role", "companion"))
	match role:
		"working":
			if str(l["home"]) in ["home", "farm", "kennel"] and float(l["obedience"]) > 35.0:
				GameState.apply_effects({"happiness": 2, "stress": 2})
				l["shifts"] = int(l.get("shifts", 0)) + 1
		"show":
			if float(l["obedience"]) > 45.0 and float(GameState.stat("looks")) > 55.0 and randf() < 0.35:
				pass
		"stray":
			pass
	if bool(l.get("lost", false)) or str(l["home"]) != "home":
		return
	if role == "watch" and randf() < 0.1:
		GameState.add_log(pick(["A shape came up the drive at night, and I told it everything I thought of it. It left. The house slept.", "I stood at the window until the thing in the hedge became a fox and went away."]))


func _flavour_year() -> void:
	var l := L()
	if randf() > 0.4 or str(l["home"]) not in ["home", "farm", "kennel", "show"]:
		return
	var s := species()
	var pools := {
		"dog": ["I learned the rattle of the lead from two rooms away, and have never been wrong.", "A boy next door dropped a sandwich over the fence for me, regularly, for nine months. We have not spoken of it.", "I found the exact spot on the carpet where the sun lands at four. I'm there at 3:55."],
		"cat": ["I knocked a glass off the table while maintaining eye contact. It's the most satisfying sound there is.", "A moth. A whole summer's work. I will not be talking about what happened to the curtain.", "There's a box. I'm in it. It is not the right size and that's the point."],
		"rabbit": ["I dug up a section of the carpet, for reasons that the humans find very difficult to respect.", "A cucumber was produced from somewhere. I have not stopped thinking about it.", "The thump is the loudest thing I can do, and it works every time."],
		"parrot": ["I said a word from the telly in exactly the voice of the newsreader. The whole house stopped. I've been using it ever since.", "I learned to imitate the smoke alarm. I do it when I'm bored, which is when I'm alone.", "A visitor was told, in my best voice, 'You're late.' They were."],
		"horse": ["A cold, bright morning with the grass crunching, and nothing at all to do but eat. I'd call that a very good morning.", "A child I didn't know came and stood at the gate for an hour, without speaking. I stood at it from my side.", "A storm came in from the west and I watched the whole sky arrive."],
	}
	GameState.add_log(pick(pools[s]))


# ================================================================ death

func death_check() -> String:
	var l := L()
	var age := int(_p()["age"])
	var span := lifespan()
	var health := GameState.stat("health")
	var home := str(l["home"])
	var ill := str(l.get("illness", ""))
	if health <= 0.0:
		if ill != "":
			return ill
		return pick(["failing health", "a slow decline", "a sudden turn in the night"])
	if age >= span:
		var chance := 0.25 + float(age - span) * 0.25 + (0.15 if health < 50.0 else 0.0)
		if randf() < chance:
			return _old_age_cause()
	elif age >= int(span * 0.75):
		var c2 := 0.025 * float(age - int(span * 0.75) + 1) * lerpf(2.0, 0.6, health / 100.0)
		if randf() < c2:
			return _old_age_cause()
	var acc := 0.0
	match home:
		"street": acc = 0.05 - float(l["instinct"]) / 3500.0
		"mill": acc = 0.04
		"home", "farm", "kennel", "show": acc = 0.006
		"shelter": acc = 0.012
	if bool(l.get("lost", false)):
		acc += 0.06
	acc *= 14.0 / maxf(14.0, float(span))
	if randf() < acc and age >= 1:
		return _accident_cause()
	if ill != "" and health < 28.0 and randf() < 0.3:
		return ill
	return ""


func _old_age_cause() -> String:
	var o := owner_name("my person")
	if str(L().get("home", "")) == "street":
		return pick(["old age, curled in a doorway", "old age, under a shop awning, in the rain"])
	if H()["flags"].has("grief") or owner_id() == "":
		return "old age, in a stranger's kind hands"
	return pick(["old age, asleep in the sun", "a last visit to the vet, with %s beside me" % o, "old age, on the warm side of the sofa", "old age, with my head in %s's lap" % o, "a quiet night, and %s sitting up with me" % o])


func _accident_cause() -> String:
	var home := str(L().get("home", ""))
	var s := species()
	if home == "street" or bool(L().get("lost", false)):
		return pick(["a car on the wet road", "the winter", "a fight in an alley", "poisoned bait"])
	match s:
		"dog": return pick(["a car at the gate", "a swallowed corn cob", "an adder in the long grass", "a fall from the garden wall"])
		"cat": return pick(["a car on the main road", "a fall from the balcony", "a fox", "a swallowed length of string"])
		"rabbit": return pick(["a hawk in the garden", "a gut stasis that wasn't caught in time", "a fox at the hutch"])
		"parrot": return pick(["an open window", "a cloud of fumes from a non-stick pan", "a cat that wasn't meant to be there"])
		"horse": return pick(["colic", "a fall at a fence", "a kick in the field", "a storm and a broken fence"])
	return "an accident"


# ================================================================ conditions

func tag(t: String) -> bool:
	if not active():
		return false
	var l := L()
	var h := H()
	for op in [">=", "<=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			var f := t.substr(0, i)
			var v := float(t.substr(i + op.length()))
			var have := _num(f)
			match op:
				">=": return have >= v
				"<=": return have <= v
				">": return have > v
				"<": return have < v
				_: return absf(have - v) < 0.001
	if t.begins_with("origin:"):
		return str(l.get("origin", "")) == t.substr(7)
	if t.begins_with("home:"):
		return str(l.get("home", "")) == t.substr(5)
	if t.begins_with("role:"):
		return str(l.get("role", "")) == t.substr(5)
	if t.begins_with("household:"):
		return str(h.get("type", "")) == t.substr(10)
	if t.begins_with("flag:"):
		return h["flags"].has(t.substr(5))
	if t.begins_with("trait:"):
		return GameState.has_trait(t.substr(6))
	if t.begins_with("sp:"):
		return species() == t.substr(3)
	if t.begins_with("trick:"):
		return Array(l.get("tricks", [])).has(t.substr(6))
	match t:
		"dog", "cat", "rabbit", "parrot", "horse": return species() == t
		"young": return stage_index() <= 1
		"baby": return stage_index() == 0
		"adult": return stage_index() == 2
		"senior": return stage_index() >= 3
		"has_home": return str(l.get("home", "")) in ["home", "farm", "kennel", "show"]
		"homeless": return str(l.get("home", "")) == "street"
		"in_shelter": return str(l.get("home", "")) == "shelter"
		"lost": return bool(l.get("lost", false))
		"ill": return str(l.get("illness", "")) != ""
		"hungry": return float(l.get("hunger", 50)) < 32.0
		"owner": return owner_id() != ""
		"partnered": return GameState.first_of("owner2") != ""
		"kids": return GameState.first_of("owner_kid") != ""
		"baby_in_house": return h["flags"].has("baby")
		"tight": return h["flags"].has("tight")
		"flush": return float(h["means"]) > 65.0
		"broke": return float(h["means"]) < 30.0
		"has_friend": return GameState.first_of("pet_friend") != ""
		"has_rival": return GameState.first_of("rival_pet") != ""
		"role_set": return bool(l.get("role_set", false))
		"inherit": return not Dictionary(l.get("inherit", {})).is_empty()
	return false


func _num(f: String) -> float:
	var l := L()
	match f:
		"age": return float(_p().get("age", 0))
		"means": return float(H()["means"])
		"mood": return float(H()["mood"])
		"tricks": return float(Array(l.get("tricks", [])).size())
		"vocab": return float(Array(l.get("vocab", [])).size())
		"health": return GameState.stat("health")
		"happy": return GameState.stat("happiness")
		"stress": return GameState.stat("stress")
		"wits": return GameState.stat("smarts")
		"coat": return GameState.stat("looks")
	return float(l.get(f, 0))


# ================================================================ outcomes

## Outcome operations from authored events: {"bond": 5, "hunger": -10, "role": "watch"}.
func apply(ops: Dictionary) -> void:
	if not active():
		return
	var l := L()
	var h := H()
	for k in ops.keys():
		var v = ops[k]
		match str(k):
			"means": h["means"] = clampf(float(h["means"]) + float(v), 3.0, 98.0)
			"mood": h["mood"] = clampf(float(h["mood"]) + float(v), 0.0, 100.0)
			"flag": h["flags"][str(v)] = 3
			"role":
				l["role"] = str(v)
				l["role_set"] = true
				GameState.add_milestone(int(_p()["age"]), "took on a calling: %s" % str(ROLES[str(v)]["name"]).to_lower())
			"lost":
				l["lost"] = bool(v)
				if bool(v):
					l["home"] = "street"
					l["lost_years"] = 0
			"home":
				l["home"] = str(v)
			"adopt":
				_adopt(str(v))
			"rehome":
				_rehome_attempt(str(v))
			"illness":
				l["illness"] = str(v)
			"found":
				l["lost"] = false
				l["lost_years"] = 0
				if owner_id() != "":
					l["home"] = "home"
				else:
					_adopt("A kind stranger took me in.")
			"learn":
				_learn(str(v))
			"trick":
				_learn_trick()
			"befriend":
				befriend(str(v))
			"rival":
				make_rival()
			"heroics":
				l["heroics"] = int(l.get("heroics", 0)) + int(v)
				GameState.counter("pet_heroics", int(v))
			"titles":
				l["titles"] = int(l.get("titles", 0)) + int(v)
				GameState.counter("pet_titles", int(v))
			"rescues": l["rescues"] = int(l.get("rescues", 0)) + int(v)
			"escapes": l["escapes"] = int(l.get("escapes", 0)) + int(v)
			"litters": l["litters"] = int(l.get("litters", 0)) + int(v)
			"mischief": l["mischief"] = int(l.get("mischief", 0)) + int(v)
			"vaccinated": l["vaccinated"] = bool(v)
			_:
				if GAUGES.has(str(k)):
					l[k] = clampf(float(l.get(k, 0)) + float(v), 0.0, 100.0)
	GameState.emit_changed()


func _learn_trick() -> String:
	var l := L()
	var have: Array = l["tricks"]
	var pool: Array = []
	for t in sp()["tricks"]:
		if not have.has(t):
			pool.append(t)
	if pool.is_empty():
		return ""
	var t2 := pick(pool)
	_learn(t2)
	return t2


func _learn(t: String) -> void:
	var l := L()
	if species() == "parrot" and (t.begins_with("Say") or t.begins_with("Imitate")):
		if not Array(l["vocab"]).has(t):
			l["vocab"].append(t)
	if not Array(l["tricks"]).has(t):
		l["tricks"].append(t)
		GameState.counter("pet_tricks")
		GameState.add_milestone(int(_p()["age"]), "learned to %s" % t.to_lower())


func befriend(kind: String = "") -> String:
	var l := L()
	var spc := kind
	if spc == "":
		spc = pick(["dog", "cat", "dog", "cat", "rabbit", "parrot", "horse"]) if species() == "dog" else species()
		if randf() < 0.4:
			spc = pick(["dog", "cat"])
	var id := GameState.create_npc("pet_friend", {"species": spc, "first": ContentDB.random_pet_name(), "last": "", "age": maxi(0, int(_p()["age"]) + randi_range(-2, 3)), "closeness": 45})
	l["friends_made"] = int(l.get("friends_made", 0)) + 1
	GameState.counter("pet_friends")
	return id


func make_rival() -> String:
	var spc := species()
	if randf() < 0.3:
		spc = pick(["dog", "cat"])
	var id := GameState.create_npc("rival_pet", {"species": spc, "first": ContentDB.random_pet_name(), "last": "", "age": maxi(0, int(_p()["age"]) + randi_range(-1, 4)), "closeness": 12})
	return id


# ================================================================ UI side

func side_labels() -> Dictionary:
	return SIDE_LABELS


func header_occ() -> String:
	var l := L()
	return "%s %s · %s" % [str(sp()["icon"]), title().capitalize(), stage_name()]


func header_sub() -> String:
	var l := L()
	var home := str(l["home"])
	var hm := {"home": "🏠 Home with the %s family" % _surname(), "farm": "🌾 On the farm", "kennel": "🐾 In the working kennel", "show": "🏆 In the breeder's show kennel", "shelter": "🏢 In the shelter", "street": "🌃 On the street", "mill": "⛓️ In the mill"}
	return "%s  ·  Gen %d" % [str(hm.get(home, "")), int(_p().get("generation", 1))]


func home_text() -> String:
	var l := L()
	var out: Array = []
	var home := str(l["home"])
	if home in ["home", "farm", "kennel", "show"]:
		var names: Array = []
		for id in _owners():
			names.append(str(GameState.npcs[id]["first"]))
		if not names.is_empty():
			out.append("🏠 Lives with " + ", ".join(names))
	for id in GameState.npcs_with("pet_friend"):
		out.append("🐾 %s (%s)" % [str(GameState.npcs[id]["first"]), str(GameState.npcs[id].get("species", "dog"))])
		break
	if str(l.get("illness", "")) != "":
		out.append("🤒 %s" % str(l["illness"]).capitalize())
	return "\n".join(out)


func fin_text() -> String:
	var h := H()
	var l := L()
	var home := str(l["home"])
	var lines: Array = []
	if home in ["home", "farm", "kennel", "show"]:
		var m := float(h["means"])
		lines.append("The household feels %s." % ("comfortable" if m > 65.0 else ("careful" if m > 35.0 else "stretched thin")))
		var mood := float(h["mood"])
		lines.append("Mood in the house: %s." % ("warm" if mood > 65.0 else ("ordinary" if mood > 38.0 else "tense")))
	lines.append("Lifespan guess: %d–%d years for a %s." % [int(sp()["life"][0]), int(sp()["life"][1]), str(sp()["noun"])])
	return "\n".join(lines)


func status_lines() -> Array:
	var l := L()
	var out: Array = []
	out.append(["%s %s · %s" % [str(ROLES[str(l["role"])]["icon"]), str(ROLES[str(l["role"])]["name"]), str(ORIGINS[str(l["origin"])]["name"])], ""])
	out.append(["Bond with %s" % owner_name("a human"), float(l["bond"])])
	out.append(["Territory", float(l["territory"])])
	out.append(["Belly", float(l["hunger"])])
	if not Array(l.get("tricks", [])).is_empty():
		out.append(["%d trick%s learned" % [Array(l["tricks"]).size(), "" if Array(l["tricks"]).size() == 1 else "s"], ""])
	return out


func continue_info() -> Dictionary:
	var l := L()
	return {"name": str(_p()["first"]), "species": species(), "house": str(_p().get("last", "")), "home": str(l.get("home", "")), "age": int(_p().get("age", 0))}


## The pet's life, as the death screen and the graveyard want to describe it.
func entry_extra() -> Dictionary:
	var l := L()
	return {"species": species(), "icon": str(sp()["icon"]), "breed": str(l.get("breed", "")), "origin": str(ORIGINS[str(l["origin"])]["name"]),
		"bond": int(l.get("bond", 0)), "tricks": Array(l.get("tricks", [])).size(), "role": str(ROLES[str(l.get("role", "companion"))]["name"]),
		"heroics": int(l.get("heroics", 0)), "titles": int(l.get("titles", 0)), "friends": int(l.get("friends_made", 0)),
		"owner": owner_name(""), "house": str(_p().get("last", ""))}


# ---------------------------------------------------------------- next life

# ================================================================ menus

func _row(icon: String, name: String, sub: String, act: String, arg = null, on: bool = true) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "act": "pet:" + act, "arg": arg, "on": on}


func _sub(icon: String, name: String, sub: String, key: String) -> Dictionary:
	return {"icon": icon, "name": name, "sub": sub, "menu": "pet:" + key}


func _left() -> int:
	return int(_p().get("time_left", 0))


func _belly_note() -> String:
	var hun := float(L()["hunger"])
	if hun < 25.0:
		return "🥣 Belly nearly empty. Everything smells like food."
	if hun < 45.0:
		return "🥣 A bit peckish."
	if hun > 88.0:
		return "🥣 Very round. The vet has opinions."
	return "🥣 Belly comfortable."


func menu(key: String) -> Dictionary:
	var l := L()
	var rows: Array = []
	var info: Array = []
	var o := owner_name("a person")
	match key:
		"home", "":
			info.append("%s %s, %s. %s" % [str(sp()["icon"]), str(_p()["first"]), title(), stage_name()])
			info.append(_belly_note())
			var h := H()
			if str(l["home"]) in ["home", "farm", "kennel", "show"]:
				if float(h["mood"]) < 40.0:
					info.append("The house feels tense. %s needs someone." % o)
				if h["flags"].has("baby"):
					info.append("There's a baby in the house. Everyone is tired and smells of milk.")
				if h["flags"].has("tight"):
					info.append("Money is short. The good tins are gone.")
			info.append("Time left this year: %d" % _left())
			rows.append(_sub("🥣", "Care and comfort", "Food, sleep, the vet, being held", "care"))
			rows.append(_sub("🎾", "Play", "Fitness, mood and mischief", "play"))
			rows.append(_sub("🎓", "Learn", "Tricks, scent work, agility and obedience", "train"))
			rows.append(_sub("🌳", "The wider world", "Explore, mark, escape, forage and hunt", "wild"))
			rows.append(_sub("🏠", "The people", "Everyone in this household", "house"))
			rows.append(_sub("🏅", "A calling", "What you are for. Or choose not to be for anything", "calling"))
			return {"icon": "🐾", "title": "A day in the life", "rows": rows, "info": info}
		"care":
			var hun2 := float(l["hunger"])
			rows.append(_row("🥣", "Beg for a better meal", "Belly +; may be scolded", "beg", null, _left() >= 1 and str(l["home"]) != "street"))
			rows.append(_row("☀️", "Find the warm spot and sleep", "Stress down, health up a little", "nap", null, _left() >= 1))
			rows.append(_row("💞", "Climb into %s's lap" % o, "Bond up, mood up", "cuddle", null, _left() >= 1 and owner_id() != "" and did("cuddle") < 2))
			rows.append(_row("🪮", "Be groomed" if species() != "cat" and species() != "parrot" else "Groom yourself", "Coat up", "groom", null, _left() >= 1 and did("groom") < 1))
			rows.append(_row("🩺", "Go to the vet", "Health up; the household pays. Takes 2", "vet", null, _left() >= 2 and str(l["home"]) in ["home", "farm", "kennel", "show"] and did("vet") < 1))
			rows.append(_row("🫂", "Comfort %s" % o, "Only when the house is low. Bond up", "comfort", null, _left() >= 1 and owner_id() != "" and float(H()["mood"]) < 55.0))
			info.append(_belly_note())
			if hun2 < 25.0 and str(l["home"]) == "street":
				info.append("The bins are the only restaurant in the neighbourhood. Try 'Raid the bins' under the wider world.")
			return {"icon": "🥣", "title": "Care and comfort", "rows": rows, "info": info}
		"play":
			rows.append(_row("🎾", str(sp()["play"]), str(sp()["play_sub"]) + ". Costs 1", "play", null, _left() >= 1 and did("play") < 3))
			rows.append(_row("🐭", "Stalk and pounce", "A game of timing. Instinct and belly", "game", "pounce", _left() >= 2 and did("pounce") < 1))
			rows.append(_row("🤝", "Make friends with a neighbour's %s" % ("pet" if species() != "parrot" else "bird"), "A friend of your own", "friend", null, _left() >= 1 and did("friend") < 1 and str(l["home"]) in ["home", "farm", "kennel", "show"]))
			rows.append(_row("😈", "Cause some mischief", "Fun or fury. Instinct up", "mischief", null, _left() >= 1 and did("mischief") < 2))
			return {"icon": "🎾", "title": "Play", "rows": rows, "info": ["Play is how a body stays a body, and how a house stays a house."]}
		"train":
			var ts := "Learn a word or sound" if species() == "parrot" else "Learn a trick"
			rows.append(_row("🎓", ts, "Obedience up. Takes 2", "trick", null, _left() >= 2 and did("trick") < 2 and Array(l.get("tricks", [])).size() < sp()["tricks"].size() and str(l["home"]) in ["home", "farm", "kennel", "show"]))
			rows.append(_row("📣", "Practise coming when called", "Obedience up a little", "recall", null, _left() >= 1 and did("recall") < 2 and str(l["home"]) in ["home", "farm", "kennel", "show"]))
			rows.append(_row("🏫", "Obedience class", "Obedience +10. The household pays. Takes 2", "class", null, _left() >= 2 and did("class") < 1 and float(H()["means"]) >= 38.0 and str(l["home"]) in ["home", "farm", "kennel", "show"]))
			rows.append(_row("👃", "Scent work", "Follow the trail. Instinct. Takes 2", "game", "scent", _left() >= 2 and did("scent") < 1))
			rows.append(_row("🏃", "Agility course", "Fitness and obedience. Takes 2", "game", "agility", _left() >= 2 and did("agility") < 1 and str(l["home"]) in ["home", "farm", "kennel", "show"]))
			var tl: Array = l.get("tricks", [])
			info.append("Tricks: " + (", ".join(tl) if not tl.is_empty() else "none yet"))
			info.append("Obedience %d · Instinct %d" % [int(l["obedience"]), int(l["instinct"])])
			return {"icon": "🎓", "title": "Learn", "rows": rows, "info": info}
		"wild":
			rows.append(_row("🧭", "Explore beyond the garden", "Territory and instinct. Risk of getting lost. Takes 2", "explore", null, _left() >= 2 and did("explore") < 2 and not bool(l.get("lost", false))))
			rows.append(_row("📍", "Mark the borders", "Territory up", "mark", null, _left() >= 1 and did("mark") < 2))
			rows.append(_row("📣", "%s at the postie" % str(sp()["sound"]).capitalize(), "Instinct up, stress down. Someone may be annoyed", "bark", null, _left() >= 1 and did("bark") < 2 and species() != "rabbit"))
			rows.append(_row("🗑️", "Raid the bins", "Belly up. A game of stealth. Takes 2", "game", "sneak", _left() >= 2 and did("sneak") < 1))
			rows.append(_row("🚪", "Slip out when the door is open", "Big territory, big risk", "escape", null, _left() >= 1 and did("escape") < 1 and str(l["home"]) in ["home", "farm", "show", "kennel"]))
			rows.append(_row("🥫", "Forage and hunt for your supper", "Belly up. Instinct. Takes 2", "forage", null, _left() >= 2 and did("forage") < 1))
			return {"icon": "🌳", "title": "The wider world", "rows": rows, "info": ["Territory %d%% · Instinct %d%%" % [int(l["territory"]), int(l["instinct"])], "The world is bigger than the garden, and it knows you're coming."]}
		"house":
			for id in _owners():
				var n: Dictionary = GameState.npcs[id]
				rows.append(_row("🧑" if str(n["relation"]) != "owner_kid" else "🧒", "%s" % str(n["first"]), relation_flavour(id) + " · closeness %d%%" % int(n["closeness"]), "visit", id, _left() >= 1 and did("visit_" + id) < 1))
			for id2 in GameState.npcs_with("pet_friend"):
				var n2: Dictionary = GameState.npcs[id2]
				rows.append(_row("🐾", str(n2["first"]), relation_flavour(id2) + " · friend", "pal", id2, _left() >= 1 and did("pal_" + id2) < 1))
			for id3 in GameState.npcs_with("rival_pet"):
				var n3: Dictionary = GameState.npcs[id3]
				rows.append(_row("😾", str(n3["first"]), relation_flavour(id3) + " · rival", "rival", id3, _left() >= 1 and did("rival_" + id3) < 1))
			var h2 := H()
			info.append("A household of %s." % str(HOUSEHOLDS.get(str(h2.get("type", "single")), {"name": "people"})["name"]))
			if str(l["home"]) not in ["home", "farm", "kennel", "show"]:
				info.append("You don't have a household at the moment.")
			return {"icon": "🏠", "title": "The people", "rows": rows, "info": info}
		"calling":
			info.append("Current: %s %s" % [str(ROLES[str(l["role"])]["icon"]), str(ROLES[str(l["role"])]["name"])])
			info.append(str(ROLES[str(l["role"])]["desc"]))
			for rk in role_options():
				var rd: Dictionary = ROLES[rk]
				rows.append(_row(str(rd["icon"]), ("Be a " if rk != "companion" else "Be a ") + str(rd["name"]).to_lower(), str(rd["desc"]), "role", rk, str(l["role"]) != rk and _left() >= 1))
			rows.append(_row("🛠️", "Work a shift", "Do the job you've chosen. Takes 2", "shift", null, _left() >= 2 and did("shift") < 1 and str(l["role"]) in ["working", "mouser", "watch", "racer"] and str(l["home"]) != "street"))
			rows.append(_row("🏆", "Enter a show", "Needs obedience 50 and a good coat. Takes 2", "show", null, _left() >= 2 and did("show") < 1 and str(l["role"]) == "show" and float(l["obedience"]) >= 50.0))
			rows.append(_row("💞", "Visit someone who needs you", "Needs obedience 45, bond 45. Takes 2", "visit", "therapy", _left() >= 2 and did("therapy") < 1 and str(l["role"]) == "therapy" and float(l["obedience"]) >= 45.0 and float(l["bond"]) >= 45.0))
			return {"icon": "🏅", "title": "A calling", "rows": rows, "info": info}
	return {"icon": "🐾", "title": "A day in the life", "rows": rows, "info": info}


func role_options() -> Array:
	var l := L()
	var out: Array = ["companion", "watch"]
	var s := species()
	if s in ["dog", "horse"]:
		out.append("working")
	if s in ["dog", "cat", "horse", "rabbit", "parrot"]:
		out.append("show")
	if s in ["dog", "cat", "rabbit"]:
		out.append("therapy")
	if s in ["cat", "dog"]:
		out.append("mouser")
	if s == "horse" or (s == "dog" and str(l["origin"]) == "working"):
		out.append("racer")
	if str(l["home"]) == "street" or str(l["origin"]) == "street":
		out.append("stray")
	return out


# ================================================================ actions

func _done(icon: String, title: String, text: String, fx: Dictionary = {}) -> void:
	EventEngine.push_info(icon, title, text, fx)
	GameState.apply_effects(fx)


func act(key: String, arg) -> void:
	var l := L()
	var o := owner_name("someone")
	match key:
		"beg":
			if not GameState.spend_time(1): return
			note("beg")
			var means := float(H()["means"])
			if randf() < 0.45 + means / 200.0:
				l["hunger"] = clampf(float(l["hunger"]) + 14.0, 0.0, 100.0)
				_done("🥣", "It worked", pick(["I sat very straight, and I looked at %s in the way that has never once failed. A piece of something warm came down from above." % o, "I did the face. The face works. A good bit of the chicken fell my way, as if by accident, which is how it always works.", "%s said 'you've just had your dinner', and gave me some more." % o]), {"happiness": 3})
			else:
				l["bond"] = float(l["bond"]) - 1.0
				_done("🙄", "Not today", pick(["%s looked at me, looked at the clock, and said 'nice try'. I withdrew with dignity." % o, "The bowl stayed as it was. The look I was given said that this was a decision made in advance."]), {"stress": 2})
		"nap":
			if not GameState.spend_time(1): return
			_done("☀️", "A good sleep", pick(["I found the rectangle of sun on the floor and followed it round the room for the whole of the afternoon, and I don't regret a minute.", "A warm blanket, a house sound and nothing to do. Sleep is the thing I do best.", "I was out in about four seconds, and the dream was about running."]), {"stress": -8, "health": 1, "happiness": 2})
		"cuddle":
			if not GameState.spend_time(1): return
			note("cuddle")
			l["bond"] = clampf(float(l["bond"]) + 4.0, 0.0, 100.0)
			var oid := owner_id()
			if oid != "":
				GameState.change_closeness(oid, 3)
			_done("💞", "A lap", pick(["I climbed up without asking. %s lifted a book to make room and didn't say anything, which is the best thing anyone can say." % o, "%s put a hand on me and, for a long time, neither of us did anything. It's a thing we're good at." % o, "The weight of a hand on my side. That's the whole of what I wanted. It's what I wanted all year."]), {"happiness": 4, "stress": -4})
		"groom":
			if not GameState.spend_time(1): return
			note("groom")
			_done("🪮", "Looking good", pick(["A long brush, a damp cloth and a lot of patience. I came out with a coat like silk and a feeling of being cared for, which is the better part.", "I washed, thoroughly, for forty minutes, and then slept. That's what a coat takes."]), {"looks": 3, "happiness": 2})
			l["bond"] = clampf(float(l["bond"]) + 1.0, 0.0, 100.0)
		"vet":
			if not GameState.spend_time(2): return
			note("vet")
			var ill := str(l.get("illness", ""))
			var h := H()
			h["means"] = clampf(float(h["means"]) - 4.0, 3.0, 98.0)
			var txt := pick(["A room that smelled of fear and disinfectant, a cold table, a thermometer I'll never forgive. %s held me and said it was fine, which was a lie that I appreciated." % o, "The vet had cold hands and a warm voice, and found nothing that couldn't be fixed. I gave nothing away."])
			if ill != "" and randf() < 0.75:
				txt += "\n\nThe vet found the %s and dealt with it. I'm to take a little pill in cheese." % ill
				l["illness"] = ""
			l["vaccinated"] = true
			_done("🩺", "A visit to the vet", txt, {"health": 8, "stress": 5})
		"comfort":
			if not GameState.spend_time(1): return
			var h2 := H()
			h2["mood"] = clampf(float(h2["mood"]) + 12.0, 0.0, 100.0)
			l["bond"] = clampf(float(l["bond"]) + 6.0, 0.0, 100.0)
			_done("🫂", "I stayed", pick(["%s was sitting very still in the kitchen, which they never do. I put my chin on their knee and we stayed like that until the light changed." % o, "%s was crying quietly, the way people do when they believe nobody can see. I'm nobody, and I leaned on them until it stopped." % o]), {"happiness": 3, "stress": -3})
		"play":
			if not GameState.spend_time(1): return
			note("play")
			l["fitness"] = clampf(float(l["fitness"]) + 6.0, 0.0, 100.0)
			_done("🎾", str(sp()["play"]), _play_text(), {"happiness": 5, "stress": -5, "health": 1})
		"mischief":
			if not GameState.spend_time(1): return
			note("mischief")
			l["mischief"] = int(l.get("mischief", 0)) + 1
			l["instinct"] = clampf(float(l["instinct"]) + 2.0, 0.0, 100.0)
			if randf() < 0.5:
				_done("😈", "Nobody saw", _mischief_text(true), {"happiness": 5, "stress": -3})
			else:
				l["bond"] = float(l["bond"]) - 3.0
				H()["mood"] = float(H()["mood"]) - 4.0
				_done("😬", "Caught", _mischief_text(false), {"happiness": 1, "stress": 3})
		"friend":
			if not GameState.spend_time(1): return
			note("friend")
			var id := befriend()
			var n := GameState.npc(id)
			_done("🤝", "A friend", "Over the fence there was a %s called %s, who I'd been listening to for weeks. We circled each other, as you do, and then I just went over and said hello in the only way I can. It went well." % [str(n.get("species", "dog")), str(n.get("first", ""))], {"happiness": 6, "stress": -4})
		"trick":
			if not GameState.spend_time(2): return
			note("trick")
			var skill := (GameState.stat("smarts") + float(l["obedience"])) / 2.0 + float(l["bond"]) * 0.2
			if randf() < clampf(0.35 + skill / 140.0, 0.25, 0.9):
				var t := _learn_trick()
				l["obedience"] = clampf(float(l["obedience"]) + 7.0, 0.0, 100.0)
				_done("🎓", "A new thing: %s" % t, pick(["It took forty repetitions and a very small piece of cheese. Then, all at once, I understood: it's a game, and I'm winning. %s laughed out loud." % o, "I learned to %s. I did it right on the sixth go, and then I did it nine times in a row to be sure." % t.to_lower()]), {"happiness": 5, "smarts": 2})
			else:
				l["obedience"] = clampf(float(l["obedience"]) + 2.0, 0.0, 100.0)
				_done("🎓", "Not yet", "I could see the shape of what they wanted and I couldn't quite make my body do it. We tried again, with less cheese and more patience. Tomorrow, probably.", {"stress": 2})
		"recall":
			if not GameState.spend_time(1): return
			note("recall")
			l["obedience"] = clampf(float(l["obedience"]) + 4.0, 0.0, 100.0)
			_done("📣", "Coming when called", pick(["The thing about coming when called is that you have to decide to. I decided, a lot of times, in a row, and was given cheese for each.", "I came back across the whole field, ears going, and %s knelt down in the grass as though I'd been missing for a year." % o]), {"happiness": 3})
		"class":
			if not GameState.spend_time(2): return
			note("class")
			H()["means"] = clampf(float(H()["means"]) - 3.0, 3.0, 98.0)
			l["obedience"] = clampf(float(l["obedience"]) + 10.0, 0.0, 100.0)
			var nid := befriend() if randf() < 0.4 else ""
			var extra := ""
			if nid != "":
				extra = "\n\nI also met %s, who was in the next row and ate a whole biscuit from the floor without being asked." % str(GameState.npc(nid).get("first", ""))
			_done("🏫", "Obedience class", "A church hall, a very patient woman with a clicker, and eleven other animals each pretending not to look at the others. I learned what 'heel' means, or learned to behave as though I did." + extra, {"smarts": 2, "stress": 3})
		"explore":
			if not GameState.spend_time(2): return
			note("explore")
			l["territory"] = clampf(float(l["territory"]) + 9.0, 0.0, 100.0)
			l["instinct"] = clampf(float(l["instinct"]) + 4.0, 0.0, 100.0)
			var risk := 0.07 - float(l["instinct"]) / 1800.0
			if randf() < risk:
				l["escapes"] = int(l.get("escapes", 0)) + 1
				apply({"lost": true})
				_done("😶‍🌫️", "I went too far", "I followed a smell across a road, then another road, then a bridge. By the time I looked up, I couldn't smell home at all. I sat down, which is what you do, and waited for someone to come, and then I kept waiting.", {"stress": 15, "happiness": -6})
			else:
				_done("🧭", "The wider world", _explore_text(), {"happiness": 4, "stress": -2})
		"mark":
			if not GameState.spend_time(1): return
			note("mark")
			l["territory"] = clampf(float(l["territory"]) + 5.0, 0.0, 100.0)
			_done("📍", "Mine", pick(["Every post, every corner, every wheelie bin. I did a whole street before lunch. Nobody will be confused about whose it is.", "A territory is a story told with the nose. I added a chapter."]), {"happiness": 2, "stress": -2})
		"bark":
			if not GameState.spend_time(1): return
			note("bark")
			l["instinct"] = clampf(float(l["instinct"]) + 3.0, 0.0, 100.0)
			var annoyed := randf() < 0.3
			if annoyed:
				l["bond"] = float(l["bond"]) - 2.0
				_done("🙉", "Too loud", "I told the postie in no uncertain terms. %s told me, in uncertain ones, to stop. We are a team and the team has a disagreement." % o, {"stress": -2})
			else:
				_done("📣", "Defended the door", "The postie came and the postie went, and I made absolutely sure that was the arrangement. I'm good at my job.", {"stress": -5, "happiness": 3})
		"escape":
			if not GameState.spend_time(1): return
			note("escape")
			l["escapes"] = int(l.get("escapes", 0)) + 1
			l["territory"] = clampf(float(l["territory"]) + 14.0, 0.0, 100.0)
			l["instinct"] = clampf(float(l["instinct"]) + 5.0, 0.0, 100.0)
			var r := randf()
			if r < 0.18:
				apply({"lost": true})
				_done("🚪", "Too good an escape", "The door was open and the world was out there and I was out in it, and it was glorious, and then it was getting dark and I couldn't smell the way back.", {"stress": 14, "happiness": -5})
			elif r < 0.28:
				l["bond"] = float(l["bond"]) - 4.0
				_done("🚪", "Brought back", "I got as far as the end of the road. A stranger carried me home like a parcel, and %s was standing in the hall with both hands over their face." % o, {"stress": 8, "health": -4})
			else:
				_done("🚪", "A morning of freedom", "I was out for four hours and I smelled a dozen new things and was back on the step before anyone knew. I'm not sorry.", {"happiness": 7, "stress": -4})
		"forage":
			if not GameState.spend_time(2): return
			note("forage")
			var got := 8.0 + float(l["instinct"]) * 0.18
			l["hunger"] = clampf(float(l["hunger"]) + got, 0.0, 100.0)
			l["instinct"] = clampf(float(l["instinct"]) + 3.0, 0.0, 100.0)
			_done("🥫", "Supper, sourced", _forage_text(), {"happiness": 2, "stress": -2})
		"visit":
			if str(arg) == "therapy":
				_therapy()
				return
			var id2 := str(arg)
			if not GameState.npcs.has(id2): return
			if not GameState.spend_time(1): return
			note("visit_" + id2)
			GameState.change_closeness(id2, 6)
			var n2: Dictionary = GameState.npcs[id2]
			if str(n2["relation"]) == "owner":
				l["bond"] = clampf(float(l["bond"]) + 3.0, 0.0, 100.0)
			_done("💞", "Time with %s" % str(n2["first"]), _person_text(n2), {"happiness": 3})
		"pal":
			var id3 := str(arg)
			if not GameState.npcs.has(id3) or not GameState.spend_time(1): return
			note("pal_" + id3)
			GameState.change_closeness(id3, 7)
			l["territory"] = clampf(float(l["territory"]) + 2.0, 0.0, 100.0)
			_done("🐾", "Time with %s" % str(GameState.npcs[id3]["first"]), pick(["We spent the whole afternoon doing absolutely nothing in each other's company, which is the whole point of a friend.", "We shared a patch of sun and a long silence. Some friends you don't have to say anything to."]), {"happiness": 5, "stress": -4})
		"rival":
			var id4 := str(arg)
			if not GameState.npcs.has(id4) or not GameState.spend_time(1): return
			note("rival_" + id4)
			var win := float(l["instinct"]) + float(l["fitness"]) * 0.4 + randf() * 40.0 > 85.0
			if win:
				l["territory"] = clampf(float(l["territory"]) + 8.0, 0.0, 100.0)
				GameState.change_closeness(id4, -4)
				_done("😾", "Stood my ground", "I walked straight at %s, and %s blinked first. I won a fence, a corner and my own good opinion." % [str(GameState.npcs[id4]["first"]), "they"], {"happiness": 4})
			else:
				GameState.change_closeness(id4, 2)
				_done("😾", "Came off worse", "%s had the edge. I took the long way home, with my tail low, and a little of my pride in my mouth." % str(GameState.npcs[id4]["first"]), {"stress": 5, "health": -3})
		"role":
			if not GameState.spend_time(1): return
			var rk := str(arg)
			l["role"] = rk
			l["role_set"] = true
			GameState.add_milestone(int(_p()["age"]), "took on a calling: %s" % str(ROLES[rk]["name"]).to_lower())
			_done(str(ROLES[rk]["icon"]), "A calling", "I decided what I was for. Or, more precisely, I noticed what I'd been doing all along and let it have a name. %s" % str(ROLES[rk]["desc"]), {"happiness": 3})
		"shift":
			_shift()
		"show":
			_show()
		"game":
			_game(str(arg))


func _play_text() -> String:
	var o := owner_name("my human")
	match species():
		"dog": return pick(["The ball went further than I'd ever seen, and I went further than the ball. I brought it back, and again, and again, until it was dark and neither of us could feel our arms.", "%s threw it. I caught it. This is the oldest agreement there is." % o])
		"cat": return pick(["A string, a feather and a very long afternoon. I stalked it from behind the sofa and defeated it entirely.", "The red dot. I know it's not real. I will never be able to stop."])
		"rabbit": return pick(["I ran the length of the room and leapt, and twisted at the top, and landed backwards. Nobody has ever been more surprised than I was.", "A cardboard tunnel, a lot of enthusiasm and a very serious chase round the sofa."])
		"parrot": return pick(["I rang the bell until %s put in earplugs. It's called commitment." % o, "A mirror, a bell and a toy that rattles. I told the bird in the mirror a great deal."])
		"horse": return pick(["I ran. There isn't more to it than that: the long field, the grass and the whole body doing exactly what a body is for.", "A fast, muddy, joyous gallop along the headland. %s watched from the gate with the particular look people get." % o])
	return "We played."


func _mischief_text(clean: bool) -> String:
	var s := species()
	var pools := {
		"dog": [["I got into the bin and learned a great deal. I was back on the mat before anyone came in.", "The cushion became a snowstorm. I was gone by the time the stuffing settled."], ["There was a shoe. There was a gap in the door. It was a thorough destruction and an unambiguous one.", "I stole a whole roast chicken off the counter. I'd say I'm not sorry, but the way %s looked at me was a lot." % owner_name()]],
		"cat": [["I knocked the pen off the desk. Then the other one. By the end of it the desk was a clean, clear plane.", "I got inside the cupboard and stayed there, silent, for two hours, while they searched. It was the finest thing I've done."], ["A plant. A table. A great deal of soil. The sound %s made was one I'll keep." % owner_name(), "I used the curtains as a ladder. The curtains didn't survive."]],
		"rabbit": [["I chewed one tiny corner of the skirting board. Only one. Nobody noticed.", "I dug the carpet, in a very discreet corner, and made a very satisfying hollow."], ["I had the wire out of the wall, and had half of it eaten, before anyone was in the room.", "I got the sofa cushion off and went to live under it. It took them a day to find me."]],
		"parrot": [["I said a word I'd learned from the telly, exactly when the vicar visited.", "I took the screw out of the cage and put it somewhere that would be hard to find."], ["I unlocked the cage. Twice. And went to the top of the bookcase and told everybody about it.", "I ate a piece of the wallpaper and then the rest of the picture frame."]],
		"horse": [["I opened the gate with my lips, one latch at a time, and went to visit a neighbour.", "I took one long, hard look at the new feed bin and decided that I was going to be in it."], ["I leaned on the fence until the whole length came down, quite gently. I stood there looking surprised.", "I got into the feed shed and ate until I felt really quite poorly."]],
	}
	var arr: Array = pools[s][0 if clean else 1]
	return pick(arr)


func _explore_text() -> String:
	return pick([
		"I followed a smell as far as the canal, learned that ducks are not as friendly as they look, and came back by the long way, with burrs in my coat and a head full of information.",
		"Past the garden wall there's a lane, and past the lane a hill, and from the hill you can see how small the house is. I stood there for a long time.",
		"I found a whole corner of the world nobody had told me about: a back yard with a cold step and a bowl of milk. Someone is kind there. I've made a note.",
		"I found a gap in a hedge, and behind it, a field of long grass. I've never felt more like an animal.",
		"I came upon a fox in the road. We looked at each other for a very long time, and agreed on a policy of not discussing it.",
		"There is a woman in the next street who talks to every animal that passes. I've been included."])


func _forage_text() -> String:
	var s := species()
	var pool: Array = [
		"I found the back door of the baker's at the exact minute the bins were put out. Three rolls and a pie crust. It was a very good day.",
		"A man eating a sandwich on a bench looked at me, looked at the sandwich, and then did something very decent with the crust.",
		"I found a dropped chip, then another, then a whole carton in a doorway. By the end of the evening, I was almost full.",
	]
	match s:
		"cat": pool.append("A mouse. A quick, clean thing under the shed. I presented it to the doormat, as is proper.")
		"dog": pool.append("A squirrel, not caught but considered. I ate the nuts it'd left behind, in a spirit of reasonable compromise.")
		"rabbit": pool.append("The long grass by the wall was a banquet. I ate until I could not eat any more, and then I ate some more.")
		"parrot": pool.append("I took the seed from the feeder in the garden next door and brought a good handful back for later.")
		"horse": pool.append("The hedgerow was full of hawthorn and brambles. It's a better dinner than the bucket, and I'll deny I said so.")
	return pick(pool)


func _person_text(n: Dictionary) -> String:
	var kid := str(n.get("relation", "")) == "owner_kid"
	var name := str(n["first"])
	if kid:
		return pick(["%s told me, in a very low voice and for twenty minutes, about something that had happened at school. I'm the only one who knows." % name, "%s dressed me in a hat. It was a bad hat. I wore it for exactly as long as it took to be admired." % name, "%s fell asleep with their head on my side, and I did not move for three hours." % name])
	return pick(["%s sat on the floor with me for no reason at all, and we looked out of the window together." % name, "%s talked about their day. I don't know what a 'quarterly review' is, but they felt better by the end." % name, "%s scratched exactly the right place, at exactly the right pressure, for exactly as long as it takes." % name])


func _therapy() -> void:
	if not GameState.spend_time(2): return
	var l := L()
	note("therapy")
	l["visits"] = int(l.get("visits", 0)) + 1
	GameState.counter("pet_visits")
	_done("💞", "A visit", pick(["A hospital ward, a lanyard with my name on it and a woman who hadn't spoken to anyone in three days put her hand on my head and said my name. I was in no hurry.", "I sat very still while a boy read me a book, badly, with great courage. I'm not sure who the visit was for. It was for both of us.", "A care home. A man in a chair said I looked just like a dog he had in 1962. He told me all about it. I listened for an hour."]), {"happiness": 6, "karma": 3})
	l["bond"] = clampf(float(l["bond"]) + 3.0, 0.0, 100.0)
	if int(l["visits"]) >= 3 and randf() < 0.3:
		l["heroics"] = int(l.get("heroics", 0)) + 1


func _shift() -> void:
	var l := L()
	var role := str(l["role"])
	if role == "working" and species() in ["dog", "horse"]:
		_game("herd")
		return
	if not GameState.spend_time(2): return
	note("shift")
	l["shifts"] = int(l.get("shifts", 0)) + 1
	GameState.counter("pet_shifts")
	match role:
		"mouser":
			l["hunger"] = clampf(float(l["hunger"]) + 8.0, 0.0, 100.0)
			_done("🏚️", "A night's work", "Barn, yard, feed store: I did my rounds. Four rats and a shrew, laid in a neat row on the step by morning. Nobody thanked me, but there was cream.", {"happiness": 4})
		"racer":
			l["fitness"] = clampf(float(l["fitness"]) + 5.0, 0.0, 100.0)
			_done("🏁", "A good run", "The gate went and there was nothing in the world but the next four hundred yards. I wasn't first. I was not last, and it felt like being the whole of the weather.", {"happiness": 5, "health": 1})
		_:
			l["instinct"] = clampf(float(l["instinct"]) + 3.0, 0.0, 100.0)
			_done("🛡️", "On watch", "I took up my post by the window at dusk. Three people walked past, and one cat. Everyone was informed of my position.", {"happiness": 3, "stress": -3})


func _show() -> void:
	_game("agility", {"show": true})


# ================================================================ minigames

func _game(id: String, extra: Dictionary = {}) -> void:
	var l := L()
	var cost := 2
	if not GameState.spend_time(cost): return
	note(id)
	var params := {"difficulty": 1.0, "skill": float(l["instinct"]) * 0.5 + float(l["obedience"]) * 0.4 + float(l["fitness"]) * 0.2, "species": species(), "pet": str(_p()["first"])}
	params.merge(extra)
	var show: bool = extra.get("show", false)
	var cb := func(score: float, detail: Dictionary) -> void:
		_game_result(id, score, detail, show)
	Minigames.play("pet_" + id, params, cb)


func _game_result(id: String, score: float, detail: Dictionary, show: bool) -> void:
	var l := L()
	var t := Minigames.tier(score)
	var fx := {}
	var txt := ""
	match id:
		"pounce":
			l["hunger"] = clampf(float(l["hunger"]) + 4.0 + 8.0 * score, 0.0, 100.0)
			l["instinct"] = clampf(float(l["instinct"]) + 2.0 + 5.0 * score, 0.0, 100.0)
			l["fitness"] = clampf(float(l["fitness"]) + 3.0, 0.0, 100.0)
			fx = {"happiness": 2 + t * 2, "stress": -3}
			txt = ["The %s got away and left me with a very strong feeling that I'd been outthought.", "A near miss, a decent chase, and a very undignified fall into a hedge.", "I caught it. I held it, and was very proud, and then I let it go, because it was a little bit too real.", "I was a hunter from the first bound to the last, and the whole yard knows it."][t]
			txt = txt.replace("%s", str(sp()["prey"]))
		"scent":
			l["instinct"] = clampf(float(l["instinct"]) + 4.0 + 8.0 * score, 0.0, 100.0)
			l["territory"] = clampf(float(l["territory"]) + 2.0 + 4.0 * score, 0.0, 100.0)
			fx = {"happiness": 2 + t, "smarts": 1 + t / 2}
			txt = ["I lost the trail at the second turning and came back with a lot of pride and nothing else.", "I followed it most of the way, with a few overshoots, and found a thing that was worth finding.", "Nose down, tail up, and the whole map unrolled. There was a person at the end, in a field, with a biscuit.", "I tracked it from the gate to the very end without once looking up. A professional."][t]
		"sneak":
			var base := 6.0 + 18.0 * score
			l["hunger"] = clampf(float(l["hunger"]) + base, 0.0, 100.0)
			l["instinct"] = clampf(float(l["instinct"]) + 3.0, 0.0, 100.0)
			if score < 0.2:
				GameState.apply_effects({"health": -3})
				fx = {"stress": 8, "happiness": -3}
				txt = "I was caught with my head in the bin, and I was chased from the alley by a shout, a broom and a very ugly word."
				if str(l["home"]) in ["home", "farm", "show", "kennel"]:
					l["bond"] = float(l["bond"]) - 3.0
					txt = "I was caught at the counter with an entire loaf, and %s's expression was an essay." % owner_name()
			else:
				fx = {"happiness": 3 + t, "stress": -2}
				txt = ["I got a little, and most of it was lettuce.", "I got a good half of the chicken before the light went on.", "I made off with an entire pie, and no human was any the wiser until the morning.", "Perfect. A silent, clean getaway with the best of the lot, and a lift-off over the fence."][t]
		"agility":
			l["fitness"] = clampf(float(l["fitness"]) + 3.0 + 6.0 * score, 0.0, 100.0)
			l["obedience"] = clampf(float(l["obedience"]) + 3.0 + 6.0 * score, 0.0, 100.0)
			fx = {"happiness": 2 + t, "health": 1}
			if show:
				l["shows"] = int(l.get("shows", 0)) + 1
				GameState.counter("pet_shows")
				if score >= 0.78:
					l["titles"] = int(l.get("titles", 0)) + 1
					GameState.counter("pet_titles")
					GameState.add_milestone(int(_p()["age"]), "won best in class")
					fx = {"happiness": 10, "stress": 3}
					txt = "The ribbon went on me in front of a tent full of strangers and the sound was a kind of rain. I understood that I'd done something that mattered a lot to someone and, for once, to me too."
				elif score >= 0.45:
					txt = "A clear round and a rosette. Not the top, but near it. %s said 'next time' in a voice that sounded like a promise." % owner_name()
				else:
					fx["stress"] = 6
					txt = "I knocked the second bar and lost the plot at the weave. We left with a handshake from a judge and a very quiet car journey."
				l["bond"] = clampf(float(l["bond"]) + 2.0, 0.0, 100.0)
			else:
				txt = ["I missed two jumps and fell off the see-saw. It was a long, undignified afternoon.", "A decent course. I took the tunnel the wrong way once, but nobody will talk about that.", "A neat, quick round, and every jump cleared. %s whooped." % owner_name(), "Perfect, from the first gate to the last, and everybody clapped, including the ones who didn't know me."][t]
		"herd":
			l["shifts"] = int(l.get("shifts", 0)) + 1
			GameState.counter("pet_shifts")
			l["fitness"] = clampf(float(l["fitness"]) + 4.0, 0.0, 100.0)
			l["obedience"] = clampf(float(l["obedience"]) + 3.0 + 4.0 * score, 0.0, 100.0)
			fx = {"happiness": 2 + t, "stress": -2}
			txt = ["The sheep decided it was a good day to be in every field but the right one.", "I got most of them in, eventually, with a lot of shouting from the man at the gate.", "A clean gather. I kept the line, I held the corner, and every one of them was in the pen before dark.", "The whole flock moved like water. The farmer took off his hat, which I'm told is what a farmer does."][t]
			if score >= 0.8 and randf() < 0.3:
				l["heroics"] = int(l.get("heroics", 0)) + 1
	_done(str(Minigames.DEFS.get("pet_" + id, {}).get("icon", "🐾")), str(Minigames.DEFS.get("pet_" + id, {}).get("name", "A game")), txt, fx)
	GameState.emit_changed()


# ================================================================ keeping the game safe

func is_pet_event(def: Dictionary) -> bool:
	var lt = def.get("conditions", {}).get("life", null)
	if lt is Array:
		return Array(lt).has("pet")
	return str(lt) == "pet"


# ================================================================ the end of a life

func story() -> String:
	var p := _p()
	var l := L()
	var sd := sp()
	var he := GameState.pron(str(p["gender"]), "he")
	var lines: Array = []
	var nm := str(p["first"])
	lines.append("%s was %s %s %s, born in %d into %s." % [nm, "an" if str(l["breed"]).to_lower()[0] in "aeiou" else "a", str(l["breed"]).to_lower(), str(sd["noun"]), int(p["born_year"]), str(ORIGINS[str(l["origin"])]["name"]).to_lower()])
	var seen_birth := false
	for m in GameState.milestones:
		if not seen_birth and str(m["text"]).begins_with("was born"):
			seen_birth = true
			continue
		lines.append("At %d, %s %s." % [int(m["age"]), he, str(m["text"])])
	var tricks: Array = l.get("tricks", [])
	if not tricks.is_empty():
		lines.append("%s knew %d thing%s on command, and chose to do about half of them." % [he.capitalize(), tricks.size(), "" if tricks.size() == 1 else "s"])
	lines.append("%s died at %d of %s." % [he.capitalize(), int(p["age"]), str(p["cause"])])
	return "\n".join(lines)


func ribbon() -> Dictionary:
	var e := Arcs.ending()
	var id := str(e.get("id", ""))
	var table := {
		"pet_best_friend": {"name": "Best Friend", "icon": "💞", "desc": "Somebody's whole world, and you knew it."},
		"pet_hero": {"name": "Hero", "icon": "🎖️", "desc": "You did the brave thing when it counted."},
		"pet_champion": {"name": "Champion", "icon": "🏆", "desc": "Best in show, and you made it look easy."},
		"pet_stray_king": {"name": "Lord of the Alley", "icon": "👑", "desc": "Nobody's, and the master of everything you could see."},
		"pet_lost": {"name": "Never Came Home", "icon": "🧭", "desc": "The road was longer than the way back."},
		"pet_sunbeam": {"name": "A Long, Warm Life", "icon": "☀️", "desc": "Old, loved and exactly where you wanted to be."},
		"pet_good": {"name": "A Good Life", "icon": "🐾", "desc": "Short, as they all are, and good."},
	}
	return table.get(id, table["pet_good"])


## Another life in the same house. The household keeps what it remembers of the one before.
func next_life_opts(entry: Dictionary) -> Dictionary:
	var pe: Dictionary = entry.get("pet", {})
	return {"inherit": {"name": str(entry.get("name", "")).get_slice(" ", 0), "house": str(pe.get("house", "")), "owner": str(pe.get("owner", "")), "icon": str(pe.get("icon", "🐾")), "years": int(entry.get("age", 10))}}


## Used by the content gate: is this a tag the game understands?
func known_tag(t: String) -> bool:
	for op in [">=", "<=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			var f := t.substr(0, i)
			return GAUGES.has(f) or ["age", "means", "mood", "tricks", "vocab", "health", "happy", "stress", "wits", "coat", "heroics", "titles", "escapes", "litters", "rescues", "lost_years", "shelter_years", "street_years", "years_with", "shows", "shifts", "visits", "friends_made", "mischief"].has(f)
	for pre in ["origin:", "home:", "role:", "household:", "flag:", "trait:", "sp:", "trick:"]:
		if t.begins_with(pre):
			return true
	return ["dog", "cat", "rabbit", "parrot", "horse", "young", "baby", "adult", "senior", "has_home", "homeless", "in_shelter", "lost", "ill", "hungry", "owner", "partnered", "kids", "baby_in_house", "tight", "flush", "broke", "has_friend", "has_rival", "role_set", "inherit"].has(t)


const OUTCOME_KEYS := ["means", "mood", "flag", "role", "lost", "home", "adopt", "rehome", "illness", "found", "learn", "trick", "befriend", "rival", "heroics", "titles", "rescues", "escapes", "litters", "mischief", "vaccinated"]

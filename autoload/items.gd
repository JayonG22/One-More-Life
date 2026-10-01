extends Node

## STAR ITEMS — the things the Star Shop sells.
##
## The shop does not sell titles any more (those are earned by achievements). It sells
## useful odds and ends that suit any style of play: a rewind, a good meal for the
## body, a favour, a reference, a lucky afternoon. The stock is the same for every
## save, because it comes from the clock and not from the player, and it turns over
## every half hour. What you buy is yours in every life.

const SLOT_SEC := 1800
const STOCK_SIZE := 6

## id: [name, icon, star cost, rarity weight, description, max per rotation]
const CATALOG := {
	"do_over": ["Do-Over", "🔄", 35, 3, "Rewind to the start of this year and live it again, differently. Works on a death.", 1],
	"health_pack": ["First-aid kit", "🩹", 8, 10, "Health +25 and a cold or two cured.", 3],
	"spa_day": ["Spa voucher", "💆", 8, 10, "Stress -30, happiness +5.", 3],
	"study_guide": ["Study guide", "📚", 10, 8, "Smarts +3.", 3],
	"elixir": ["Elixir of youth", "🧪", 18, 5, "Looks +8 and health +8.", 2],
	"fine_wine": ["Bottle of fine wine", "🍷", 6, 10, "Happiness +10 and stress -5.", 3],
	"bonus_time": ["Spare hours", "⏳", 14, 6, "Three extra time points this year.", 2],
	"cash_envelope": ["Cash envelope", "💵", 12, 8, "A sealed envelope of $2,500.", 3],
	"favour": ["Favour card", "🤝", 10, 8, "Mends the relationship that is slipping the most (+25).", 3],
	"pardon": ["Pardon letter", "📜", 30, 2, "Clears your criminal record and all the stars on you.", 1],
	"golden_ticket": ["Golden ticket", "🎫", 25, 3, "Your next job application sails through: screening and interview.", 1],
	"reference": ["Glowing reference", "✉️", 15, 5, "A reference from someone the whole industry trusts, for every application to come.", 2],
	"resume_polish": ["Résumé polish", "📄", 10, 7, "Interviews go better from now on.", 3],
	"tonic": ["Cure-all tonic", "🍶", 12, 6, "Cures whatever you have and restores 15 health.", 2],
	"pet_bundle": ["Pet care bundle", "🐾", 12, 6, "Every animal you have is fed, seen by a vet and happier.", 2],
	"travel_pass": ["Travel pass", "🎟️", 8, 7, "This year you can get anywhere as if you had a car.", 3],
	"lucky_charm": ["Lucky charm", "🍀", 15, 5, "This year luck leans your way: gambling, lotteries and the odds in general.", 2],
	"makeover": ["Makeover", "💇", 14, 6, "Looks +12 and a day's confidence.", 2],
}


func _g() -> Dictionary:
	return Goals._g()


func inv() -> Dictionary:
	var g := _g()
	if not g.has("items") or not (g["items"] is Dictionary):
		g["items"] = {}
	return g["items"]


func owned(id: String) -> int:
	return int(inv().get(id, 0))


func add(id: String, n: int = 1) -> void:
	inv()[id] = owned(id) + n
	Meta.save()


# ---------------------------------------------------------------- the clock

func slot() -> int:
	return int(Time.get_unix_time_from_system() / float(SLOT_SEC))


func seconds_left() -> int:
	return SLOT_SEC - int(Time.get_unix_time_from_system()) % SLOT_SEC


## What the shop has in this rotation. A function of the clock alone: every save sees
## the same shelf at the same moment.
func stock(at_slot: int = -1) -> Array:
	var sl := slot() if at_slot < 0 else at_slot
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("star-shop-%d" % sl)
	var ids: Array = CATALOG.keys()
	ids.sort()
	var pool: Array = ids.duplicate()
	var out: Array = []
	while out.size() < STOCK_SIZE and not pool.is_empty():
		var tot := 0.0
		for id in pool:
			tot += float(CATALOG[id][3])
		var r := rng.randf() * tot
		var pick := str(pool[0])
		for id2 in pool:
			r -= float(CATALOG[id2][3])
			if r <= 0.0:
				pick = str(id2)
				break
		pool.erase(pick)
		out.append(pick)
	return out


func bought_this_rotation(id: String) -> int:
	var g := _g()
	if not g.has("shop_bought"):
		g["shop_bought"] = {}
	var cur := str(slot())
	for k in g["shop_bought"].keys():
		if str(k) != cur:
			g["shop_bought"].erase(k)
	return int(g["shop_bought"].get(cur, {}).get(id, 0))


func left_in_stock(id: String) -> int:
	return int(CATALOG[id][5]) - bought_this_rotation(id)


func buy(id: String) -> bool:
	if not CATALOG.has(id) or not stock().has(id) or left_in_stock(id) <= 0:
		return false
	var cost := int(CATALOG[id][2])
	if Goals.stars() < cost:
		return false
	var g := _g()
	g["stars"] = Goals.stars() - cost
	var cur := str(slot())
	if not g["shop_bought"].has(cur):
		g["shop_bought"][cur] = {}
	g["shop_bought"][cur][id] = bought_this_rotation(id) + 1
	add(id)
	return true


# ---------------------------------------------------------------- using them

func can_use(id: String) -> String:
	if owned(id) <= 0:
		return "You have none"
	if not GameState.has_life():
		return "Start a life first"
	var p := GameState.player
	if id == "do_over":
		if not has_snapshot():
			return "Nothing to rewind to yet"
		return ""
	if not bool(p.get("alive", true)):
		return "Only while you are living"
	if id == "pet_bundle" and GameState.npcs_with("pet").is_empty():
		return "You have no animals"
	if id == "tonic" and str(p.get("illness", "")) == "" and GameState.stat("health") >= 99.0:
		return "You are fine"
	if id == "pardon" and p.get("record", []).is_empty() and Wanted.stars() == 0:
		return "You have no record"
	return ""


## Returns a line describing what happened, or "" if it could not be used. A Do-Over
## returns "__redo" so the screen knows to rebuild itself.
func use(id: String) -> String:
	if can_use(id) != "":
		return ""
	var p := GameState.player
	var msg := ""
	match id:
		"do_over":
			if not restore():
				return ""
			inv()[id] = owned(id) - 1
			Meta.save()
			return "__redo"
		"health_pack":
			GameState.apply_effects({"health": 25})
			if str(p.get("illness", "")) in ["the flu", "bronchitis", "a stomach bug", "chickenpox", "an ear infection", "migraines", "back pain", "insomnia"]:
				p["illness"] = ""
			msg = "I used the first-aid kit. It helped more than I expected."
		"spa_day":
			GameState.apply_effects({"stress": -30, "happiness": 5})
			msg = "A day of steam, silence and someone else making the tea."
		"study_guide":
			GameState.apply_effects({"smarts": 3})
			msg = "I worked through the study guide in a week. Things fell into place."
		"elixir":
			GameState.apply_effects({"looks": 8, "health": 8})
			msg = "The elixir tasted of pears and money. I felt a decade lighter."
		"fine_wine":
			GameState.apply_effects({"happiness": 10, "stress": -5})
			msg = "I opened the good bottle for no reason at all. That was the reason."
		"bonus_time":
			p["time_left"] = int(p["time_left"]) + 3
			msg = "The year gave me three more hours than it was meant to."
		"cash_envelope":
			p["money"] = int(p["money"]) + Actions._cost(2500)
			msg = "A plain envelope, and no note. I will not ask who."
		"favour":
			var worst := ""
			var low := 101
			for id2 in GameState.npcs.keys():
				var n: Dictionary = GameState.npcs[id2]
				if not n["alive"] or Bonds.is_past(n) or str(n.get("species", "human")) != "human":
					continue
				if str(n["relation"]) in ["mother", "father", "partner", "best_friend", "child", "sibling", "friend", "grandparent"] and int(n["closeness"]) < low:
					low = int(n["closeness"])
					worst = id2
			if worst == "":
				return ""
			GameState.change_closeness(worst, 25)
			msg = "I called in a favour on behalf of %s, and it landed." % GameState.npcs[worst]["first"]
		"pardon":
			p["record"] = []
			Wanted.clear_all("pardoned")
			msg = "A signed letter arrived. The record was wiped, and the stars with it."
		"golden_ticket":
			p["golden_ticket"] = true
			msg = "The golden ticket is in my coat pocket. The next application will go through."
		"reference":
			var s := Market.st()
			s["refs"].append({"who": "", "strength": 1.0, "co": "a glowing reference"})
			msg = "A letter on thick paper, from someone whose name opens doors."
		"resume_polish":
			var s2 := Market.st()
			s2["interview_xp"] = minf(float(s2["interview_xp"]) + 0.08, 0.15)
			msg = "A professional cut my CV in half and it read twice as well."
		"tonic":
			p["illness"] = ""
			GameState.apply_effects({"health": 15})
			msg = "The tonic was disgusting. It also worked."
		"pet_bundle":
			for pid in GameState.npcs_with("pet"):
				Companions.tend(pid, 100.0)
				Companions.cure(pid)
				GameState.change_closeness(pid, 8)
			msg = "Every animal in the house had a feast, a check-up and a new toy."
		"travel_pass":
			p["travel_pass"] = int(p["age"])
			msg = "A travel pass, good for the year. Distance stopped being a problem."
		"lucky_charm":
			p["lucky_year"] = int(p["age"])
			msg = "A lucky charm on a chain. I do not believe in it. I have not taken it off."
		"makeover":
			GameState.apply_effects({"looks": 12, "happiness": 3})
			msg = "New hair, new clothes, new walk."
	inv()[id] = owned(id) - 1
	Meta.save()
	GameState.add_log(msg)
	GameState.emit_changed()
	return msg


# ---------------------------------------------------------------- Do-Over snapshots

var _snap := ""


func _snap_path() -> String:
	return SaveManager.slot_path(SaveManager.current_slot) + ".undo" if SaveManager.current_slot >= 0 else ""


## Taken at the start of every year, so a Do-Over can rewind exactly that far.
func snapshot() -> void:
	if not GameState.has_life():
		return
	_snap = JSON.stringify(GameState.to_dict())
	var pth := _snap_path()
	if pth != "":
		var f := FileAccess.open(pth, FileAccess.WRITE)
		if f:
			f.store_string(_snap)
			f.close()


func has_snapshot() -> bool:
	if _snap != "":
		return true
	var pth := _snap_path()
	return pth != "" and FileAccess.file_exists(pth)


func restore() -> bool:
	var raw := _snap
	if raw == "":
		var pth := _snap_path()
		if pth != "" and FileAccess.file_exists(pth):
			raw = FileAccess.get_file_as_string(pth)
	if raw == "":
		return false
	var d = JSON.parse_string(raw)
	if not (d is Dictionary) or not d.has("player"):
		return false
	# undoing a death un-records it: no grave, no ribbon, no ending, no echo
	var cur := GameState.player
	if not bool(cur.get("alive", true)) and cur.has("legacy"):
		var ent: Dictionary = cur["legacy"]
		var nm := str(ent.get("name", ""))
		if not SaveManager.graveyard.is_empty() and str(SaveManager.graveyard[-1].get("name", "")) == nm:
			SaveManager.graveyard.pop_back()
			SaveManager._write(SaveManager.GRAVE_PATH, SaveManager.graveyard)
		var rn := str(ent.get("ribbon", {}).get("name", ""))
		for key in ["ribbons", "ribbons_modified"]:
			if Meta.meta.has(key) and Meta.meta[key].has(rn):
				Meta.meta[key][rn] = maxi(0, int(Meta.meta[key][rn]) - 1)
		var endid := str(ent.get("ending", {}).get("id", ""))
		if endid != "" and Meta.meta.get("endings", {}).has(endid):
			var rec: Dictionary = Meta.meta["endings"][endid]
			rec["n"] = int(rec.get("n", 1)) - 1
			if int(rec["n"]) <= 0:
				Meta.meta["endings"].erase(endid)
		Legacy.forget(nm)
		Meta.save()
	var used := int(GameState.player.get("do_overs", 0)) + 1
	var carry_flag: Variant = GameState.player.get("legacy", null)
	GameState.from_dict(d)
	GameState.player["do_overs"] = used
	GameState.player["alive"] = true
	GameState.player.erase("legacy")
	GameState.counter("do_overs")
	GameState.add_log("I rewound the year and lived it again.")
	_snap = ""
	var pth2 := _snap_path()
	if pth2 != "" and FileAccess.file_exists(pth2):
		DirAccess.remove_absolute(pth2)
	randomize()
	SaveManager.save_game()
	return carry_flag == null or true

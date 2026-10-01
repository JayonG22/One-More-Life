extends Node

## ARCS — a life path is a road with chapters and an end, not a set of buttons.
##
## Vampire and the undead got this in v0.11: a shape to the life, and a death
## that meant something. The other six paths — Royal, Witch, Gifted, Pirate,
## Colonist and Time Traveler — had entry routes and a handful of actions, and
## then nothing, so one pirate life ended exactly like another.
##
## Each path now has five chapters that open on what the player has actually
## done (not on the calendar), a turning-point event for each, and a set of
## endings that is picked at death from the life as it ended. The ending is
## written into the life story, the tombstone, and the achievements.
##
## A need is [field, op, value]. A bare field is read from the path's life
## record; "c:name" is a lifetime counter; "p:name" is a player field.

const ARCS := {
	"pirate": {
		"title": "The Pirate's Road", "icon": "🏴‍☠️",
		"chapters": [
			{"id": "first_blood", "title": "First blood on the water", "blurb": "Raid your first ship.", "need": [["raids", ">=", 1]]},
			{"id": "price", "title": "A price on your head", "blurb": "Let the bounty climb to 30.", "need": [["bounty", ">=", 30]]},
			{"id": "the_map", "title": "The map that was real", "blurb": "Follow two treasure maps to the end.", "need": [["maps", ">=", 2]]},
			{"id": "fleet", "title": "Captain", "blurb": "Rise to Captain.", "need": [["rank", ">=", 3]]},
			{"id": "legend", "title": "A name the harbours sing", "blurb": "Become a Sea Legend with a hold worth the name.", "need": [["rank", ">=", 4], ["treasure", ">=", 60000]]},
		],
		"endings": [
			{"id": "sea_legend", "title": "Sea Legend", "need": [["rank", ">=", 4]], "epitaph": "The harbours still sing it wrong.", "text": "They made a song of the ship and got the name wrong in the second verse. Everyone who sailed with them sings it the right way, and quietly."},
			{"id": "hanged", "title": "The Gallows", "need": [["bounty", ">=", 85]], "epitaph": "Hanged at the dock, to a good crowd.", "text": "The price on the head was finally collected. A crowd came to the dock, as they always do, and some of them wept."},
			{"id": "mutiny", "title": "Mutinied Off", "need": [["mutinies", ">=", 2]], "epitaph": "Betrayed by those they fed.", "text": "A captain who loses the crew twice has not lost a ship. They have lost the argument about what a ship is for."},
			{"id": "retired_rich", "title": "Retired with the Hold", "need": [["treasure", ">=", 120000]], "epitaph": "Got out with the gold and the knees.", "text": "A cottage above a harbour, a boat for fishing and no one asking where the money came from. They told the neighbours they'd been in shipping."},
			{"id": "sea_grave", "title": "The Sea Has the Rest", "need": [], "epitaph": "The sea has the rest.", "text": "No stone, no grave, and no one quite sure where. The charts have a small gap."},
		],
	},
	"colonist": {
		"title": "Under Glass", "icon": "🪐",
		"chapters": [
			{"id": "first_winter", "title": "The first year under the dome", "blurb": "Complete a mission for the colony.", "need": [["missions", ">=", 1]]},
			{"id": "out_there", "title": "Something out there", "blurb": "Make two discoveries on the surface.", "need": [["discoveries", ">=", 2]]},
			{"id": "council", "title": "A voice on the council", "blurb": "Reach 40 influence.", "need": [["influence", ">=", 40]]},
			{"id": "signal", "title": "The signal answers", "blurb": "Raise the signal analysis to 60%.", "need": [["contact", ">=", 60]]},
			{"id": "founder", "title": "A name on the founders' wall", "blurb": "Become Colony Founder.", "need": [["rank", ">=", 4]]},
		],
		"endings": [
			{"id": "contact", "title": "First Contact", "need": [["contact", ">=", 100]], "epitaph": "Heard it first, and answered.", "text": "History will argue about who understood the signal first. The colony records say one name, and it is on this stone."},
			{"id": "founder", "title": "Founder of Ares Haven", "need": [["rank", ">=", 4]], "epitaph": "The dome is their monument.", "text": "The dome was extended twice in their lifetime, and a third time in their name. The children born there do not know it was ever small."},
			{"id": "lost_colony", "title": "The Dome Failed", "need": [["oxygen", "<=", 12]], "epitaph": "Held the door until the air ran out.", "text": "The seals failed in the night, and what mattered after that was who stayed. They stayed."},
			{"id": "elder", "title": "Council Elder", "need": [["influence", ">=", 70]], "epitaph": "Voted, and was heard.", "text": "A generation grew up taking the council for granted, because someone had once built it carefully."},
			{"id": "dome_grave", "title": "Buried Under Another Sky", "need": [], "epitaph": "Buried under a different sky.", "text": "Red dust, a small marker and a view of a very small sun. It was a life on the edge of the possible, and it was theirs."},
		],
	},
	"traveler": {
		"title": "Borrowed Time", "icon": "⌛",
		"chapters": [
			{"id": "fitting_in", "title": "Fitting in", "blurb": "Raise your cover to 70.", "need": [["cover", ">=", 70]]},
			{"id": "first_jump", "title": "The first jump", "blurb": "Travel through time once.", "need": [["jumps", ">=", 1]]},
			{"id": "collector", "title": "A collector of what was", "blurb": "Document three artifacts.", "need": [["artifacts", ">=", 3]]},
			{"id": "edge", "title": "Close to the edge", "blurb": "Let paradox reach 50.", "need": [["paradox", ">=", 50]]},
			{"id": "which_home", "title": "Which year is home?", "blurb": "Jump five times.", "need": [["jumps", ">=", 5]]},
		],
		"endings": [
			{"id": "erased", "title": "Erased", "need": [["paradox", ">=", 100]], "epitaph": "No longer on the records.", "text": "The timeline closed over the gap. People who loved them remember a vague, pleasant person who was hard to picture."},
			{"id": "historian", "title": "The Quiet Historian", "need": [["artifacts", ">=", 8]], "epitaph": "Kept what was, carefully.", "text": "A collection that did not belong to any year, catalogued in a hand that did not belong to any of them either. It was left, with no note, to a library."},
			{"id": "stranded", "title": "Stranded", "need": [["charge", "<=", 10]], "epitaph": "Chose a year and stayed.", "text": "The device ran down in a year that was perfectly pleasant. They did not try very hard to find a way back."},
			{"id": "wanderer", "title": "Out of Step", "need": [], "epitaph": "Born later than this stone admits.", "text": "They were never quite in step with the year they were in. Nobody could ever say why."},
		],
	},
	"royal": {
		"title": "The Crown", "icon": "👑",
		"chapters": [
			{"id": "line", "title": "A place in the line", "blurb": "Keep your respect above 55.", "need": [["respect", ">=", 55]]},
			{"id": "decree", "title": "The first decree", "blurb": "Issue a decree.", "need": [["decrees", ">=", 1]]},
			{"id": "crown", "title": "The crown", "blurb": "Be crowned.", "need": [["crowned", "==", true]]},
			{"id": "ten", "title": "Ten years on the throne", "blurb": "Reign for a decade.", "need": [["reign", ">=", 10]]},
			{"id": "remembered", "title": "A reign remembered", "blurb": "Reign for 25 years with respect above 70.", "need": [["reign", ">=", 25], ["respect", ">=", 70]]},
		],
		"endings": [
			{"id": "beloved", "title": "A Reign Remembered", "need": [["reign", ">=", 25], ["respect", ">=", 70]], "epitaph": "Wore it, and was worth it.", "text": "The people lined the road for four miles. Several said they had expected to feel nothing, and had been wrong."},
			{"id": "deposed", "title": "Deposed", "need": [["overthrown", "==", true]], "epitaph": "The crown outlasted them.", "text": "They were removed on a cold morning by people who had once bowed. History has been unkind, and may yet be corrected."},
			{"id": "abdicated", "title": "Abdicated", "need": [["abdicated", "==", true]], "epitaph": "Put it down, and lived.", "text": "They took off the crown on their own terms and handed it to someone who wanted it more. It was the bravest thing in a very public life."},
			{"id": "brief", "title": "A Short Reign", "need": [["crowned", "==", true]], "epitaph": "Wore it, for a while.", "text": "The reign was short and the funeral was long. Historians call it a transition."},
			{"id": "uncrowned", "title": "Never Crowned", "need": [], "epitaph": "Born near it. Never wore it.", "text": "A life lived within sight of the throne, and a hundred small decisions about whether to reach for it."},
		],
	},
	"witch": {
		"title": "The Craft", "icon": "🧙",
		"chapters": [
			{"id": "first_spell", "title": "The first spell", "blurb": "Cast a spell.", "need": [["spells", ">=", 1]]},
			{"id": "circle", "title": "A circle of your own", "blurb": "Gather a coven of two or more.", "need": [["coven_n", ">=", 2]]},
			{"id": "grimoire", "title": "The working grimoire", "blurb": "Cast twenty spells.", "need": [["spells", ">=", 20]]},
			{"id": "almost", "title": "Almost found out", "blurb": "Let exposure reach 50.", "need": [["exposure", ">=", 50]]},
			{"id": "mother", "title": "Mother of the coven", "blurb": "Lead a coven of four, and cast sixty spells.", "need": [["coven_n", ">=", 4], ["spells", ">=", 60]]},
		],
		"endings": [
			{"id": "burned", "title": "Found Out", "need": [["exposure", ">=", 95]], "epitaph": "They had the right name, eventually.", "text": "The town came for them with lanterns. The coven scattered. The garden went on blooming for years in the places they had touched."},
			{"id": "ascended", "title": "Ascended", "need": [["spells", ">=", 120]], "epitaph": "Left the room and the weather changed.", "text": "People who were there describe a stillness. The candles did not gutter. The kettle on the stove began to sing a note nobody had heard it sing before."},
			{"id": "matriarch", "title": "Matriarch of the Coven", "need": [["coven_n", ">=", 4]], "epitaph": "Taught what they knew.", "text": "The coven met at the kitchen table for decades, and at the funeral they set a place for her. The tea went cold, then was drunk."},
			{"id": "hedge", "title": "A Hedge Witch", "need": [], "epitaph": "Mended what they could.", "text": "A cottage, a garden, and a long list of people who had come to the door with a problem and gone away with something in a jar."},
		],
	},
	"super": {
		"title": "The Mask", "icon": "🦸",
		"chapters": [
			{"id": "first", "title": "The first night out", "blurb": "Make a save or a heist.", "need": [["saves_heists", ">=", 1]]},
			{"id": "alias", "title": "An alias that sticks", "blurb": "Raise your reputation to 20.", "need": [["rep", ">=", 20]]},
			{"id": "nemesis", "title": "A nemesis", "blurb": "Draw an enemy of your own.", "need": [["has_nemesis", "==", true]]},
			{"id": "unmasked", "title": "Unmasked or untouchable", "blurb": "Be revealed, or reach power 60.", "need_any": [["revealed", "==", true], ["power", ">=", 60]]},
			{"id": "legend", "title": "A legend in the city", "blurb": "Reach reputation 70.", "need": [["rep", ">=", 70]]},
		],
		"endings": [
			{"id": "icon", "title": "An Icon", "need": [["side", "==", "hero"], ["rep", ">=", 70]], "epitaph": "The city kept the cape.", "text": "A mural went up before the funeral. It was repainted twice, by different hands, and nobody complained about the differences."},
			{"id": "infamous", "title": "Infamous", "need": [["side", "==", "villain"], ["rep", ">=", 70]], "epitaph": "Feared, which is a kind of remembered.", "text": "Parents used the alias to frighten children for forty years. Then somebody made a documentary and it became fashionable to be fond of it."},
			{"id": "unmasked_fall", "title": "Unmasked", "need": [["revealed", "==", true]], "epitaph": "The mask came off. The person stayed.", "text": "The day the face was shown was the day the city had to decide what it thought. It took a decade."},
			{"id": "quiet", "title": "A Quiet Hero", "need": [], "epitaph": "Did it, mostly without being seen.", "text": "A handful of people knew. They kept the secret, and each of them told the story to somebody they trusted, and so on."},
		],
	},
}


## Gauges that live between 0 and 100.
const CLAMPED := ["oxygen", "rations", "morale", "hull", "charge", "cover", "paradox", "suspicion", "mana", "exposure", "respect", "power", "bounty", "contact", "influence"]


func _p() -> Dictionary:
	return GameState.player


func kind() -> String:
	return Lives.kind()


func has_arc() -> bool:
	return ARCS.has(kind())


func st() -> Dictionary:
	var l := Lives.life()
	if l.is_empty() or not ARCS.has(kind()):
		return {}
	if not l.has("arc") or not (l["arc"] is Dictionary):
		l["arc"] = {"chapter": 0, "reached": []}
	return l["arc"]


## One value out of the life record, with a few derived fields.
func _val(field: String):
	var l := Lives.life()
	if field.begins_with("c:"):
		return GameState.get_counter(field.substr(2))
	if field.begins_with("p:"):
		return _p().get(field.substr(2), 0)
	match field:
		"coven_n": return Array(l.get("coven", [])).size()
		"saves_heists": return int(l.get("saves", 0)) + int(l.get("heists", 0))
		"has_nemesis": return str(l.get("nemesis", "")) != ""
		"overthrown": return bool(l.get("overthrown", false)) or GameState.has_flag("overthrown")
	return l.get(field, 0)


func _met(needs: Array) -> bool:
	for n in needs:
		var have = _val(str(n[0]))
		var want = n[2]
		match str(n[1]):
			">=": if not (float(have) >= float(want)): return false
			"<=": if not (float(have) <= float(want)): return false
			"==":
				if want is bool:
					if bool(have) != bool(want): return false
				elif str(have) != str(want):
					return false
	return true


func _chapter_met(ch: Dictionary) -> bool:
	if ch.has("need_any"):
		for n in ch["need_any"]:
			if _met([n]):
				return true
		return false
	return _met(ch.get("need", []))


func chapters() -> Array:
	return ARCS.get(kind(), {}).get("chapters", [])


func current_index() -> int:
	return int(st().get("chapter", 0))


## Called each year after the path's own yearly pass. Opens every chapter whose
## needs are met, in order, and queues the turning-point event for each.
func yearly() -> void:
	var s := st()
	if s.is_empty():
		return
	var chs := chapters()
	var guard := 0
	while int(s["chapter"]) < chs.size() and guard < 5:
		guard += 1
		var ch: Dictionary = chs[int(s["chapter"])]
		if not _chapter_met(ch):
			break
		_open(ch)


func _open(ch: Dictionary) -> void:
	var s := st()
	var idx := int(s["chapter"])
	s["chapter"] = idx + 1
	s["reached"].append(str(ch["id"]))
	GameState.counter("arc_" + kind())
	var n := idx + 1
	GameState.add_milestone(int(_p()["age"]), "reached chapter %d of %s: %s" % [n, str(ARCS[kind()]["title"]), str(ch["title"])])
	GameState.add_log("%s Chapter %d — %s." % [str(ARCS[kind()]["icon"]), n, str(ch["title"])])
	LifeThreads.remember(kind(), str(ch["title"]), str(ch["blurb"]), "", 55 + n * 6, [kind(), "chapter"])
	GameState.apply_effects({"happiness": 3 + n})
	var eid := "arc.%s.%d" % [kind(), n]
	if ContentDB.events_by_id.has(eid):
		EventEngine._enqueue(ContentDB.events_by_id[eid], {})


func status_line() -> Array:
	var s := st()
	if s.is_empty():
		return []
	var chs := chapters()
	var idx := int(s["chapter"])
	if idx >= chs.size():
		return ["%s The road is walked. What's left is how it ends." % str(ARCS[kind()]["icon"]), ""]
	var ch: Dictionary = chs[idx]
	return ["%s Chapter %d of %d — %s: %s" % [str(ARCS[kind()]["icon"]), idx + 1, chs.size(), str(ch["title"]), str(ch["blurb"])], ""]


func menu() -> Dictionary:
	var s := st()
	var rows: Array = []
	var info: Array = []
	if s.is_empty():
		return {"icon": "🛤️", "title": "Your road", "rows": rows, "info": ["Nothing in this life has a road yet."]}
	var a: Dictionary = ARCS[kind()]
	var chs := chapters()
	info.append("%s %s" % [str(a["icon"]), str(a["title"])])
	for i in range(chs.size()):
		var ch: Dictionary = chs[i]
		var done: bool = i < int(s["chapter"])
		var now: bool = i == int(s["chapter"])
		info.append("%s %d. %s — %s" % ["✓" if done else ("→" if now else "·"), i + 1, str(ch["title"]), str(ch["blurb"])])
	var e := ending()
	info.append("")
	info.append("If it ended today: %s." % str(e["title"]))
	return {"icon": str(a["icon"]), "title": "Your road", "rows": rows, "info": info}


# ------------------------------------------------------------------ the end

func ending() -> Dictionary:
	if not ARCS.has(kind()):
		return {}
	for e in ARCS[kind()]["endings"]:
		if _met(e.get("need", [])):
			return e
	return ARCS[kind()]["endings"][-1]


## A path that ends before the life does (an overthrown monarch, say) still
## gets its ending: it is written down at the moment the path is lost.
func freeze(reason: String) -> void:
	if not has_arc():
		return
	var l := Lives.life()
	if reason == "overthrown":
		l["overthrown"] = true
	elif reason == "abdicated":
		l["abdicated"] = true
	var e := ending()
	_p()["arc_frozen"] = {"id": str(e["id"]), "title": str(e["title"]), "text": str(e["text"]), "epitaph": str(e["epitaph"]), "path": kind(), "chapters": int(st().get("chapter", 0))}
	GameState.counter("ending_" + str(e["id"]))


## What goes into the legacy entry when the life is over.
func ending_entry() -> Dictionary:
	if _p().has("arc_frozen") and not has_arc():
		return _p()["arc_frozen"]
	if not has_arc():
		return {}
	var e := ending()
	if e.is_empty():
		return {}
	GameState.counter("ending_" + str(e["id"]))
	return {"id": str(e["id"]), "title": str(e["title"]), "text": str(e["text"]), "epitaph": str(e["epitaph"]), "path": kind(), "chapters": int(st().get("chapter", 0))}


## Outcome operations from authored events: {"bounty": 10, "morale": -5}.
func apply(ops: Dictionary) -> void:
	var l := Lives.life()
	if l.is_empty():
		return
	for k in ops.keys():
		var v = ops[k]
		if v is bool:
			l[k] = v
		elif v is String:
			l[k] = v
		else:
			l[k] = float(l.get(k, 0)) + float(v) if l.get(k, 0) is float else int(l.get(k, 0)) + int(v)
		if CLAMPED.has(k):
			l[k] = clampi(int(l[k]), 0, 100)


func tag(t: String) -> bool:
	var s := st()
	if s.is_empty():
		return false
	if t.begins_with("chapter:"):
		return int(s["chapter"]) >= int(t.substr(8))
	if t == "road_walked":
		return int(s["chapter"]) >= chapters().size()
	return false

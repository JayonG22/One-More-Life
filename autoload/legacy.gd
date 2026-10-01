extends Node

## LEGACY — what a life leaves for the next one, in any mode.
##
## Every finished life can leave up to three echoes: a surname that means
## something, a feud nobody finished, a dog that is somebody's grandmother's
## story, a relative who did time, a relative who wore the uniform. The next life
## — human, pet, prisoner or guard — picks up to two of them when it begins, and
## they show up in its first pages as a log line, a small stat, or a person.
##
## An echo is used once. They are kept in the meta file, so they survive
## closing the game.

const MAX_KEPT := 10
const PER_LIFE := 2


func _store() -> Array:
	if not Meta.meta.has("echoes"):
		Meta.meta["echoes"] = []
	return Meta.meta["echoes"]


func list() -> Array:
	return _store()


func pending() -> Array:
	return _store().filter(func(e): return not bool(e.get("used", false)))


## A death that is undone leaves no echo.
func forget(who: String) -> void:
	var st := _store()
	for i in range(st.size() - 1, -1, -1):
		if str(st[i].get("who", "")) == who and not bool(st[i].get("used", false)) and int(Time.get_unix_time_from_system()) - int(st[i].get("made", 0)) < 3600:
			st.remove_at(i)


func _add(kind: String, text: String, who: String, extra: Dictionary = {}) -> void:
	var st := _store()
	var e := {"kind": kind, "text": text, "who": who, "used": false, "made": int(Time.get_unix_time_from_system())}
	e.merge(extra)
	st.append(e)
	while st.size() > MAX_KEPT:
		# forget the oldest that was already used, else the oldest
		var drop := 0
		for i in range(st.size()):
			if bool(st[i].get("used", false)):
				drop = i
				break
		st.remove_at(drop)


## Called when a life ends. Reads the finished life from the player record.
func record(entry: Dictionary) -> void:
	var p := GameState.player
	if p.is_empty():
		return
	var name_ := str(entry.get("name", ""))
	var last := str(p.get("last", ""))
	var made := 0
	var mode: Dictionary = entry.get("mode", {})
	if Pets.active():
		var l := Pets.L()
		var pn := str(p.get("first", ""))
		if int(l.get("heroics", 0)) >= 1 or int(l.get("titles", 0)) >= 1 or float(l.get("bond", 0)) >= 85.0:
			_add("pet", "%s the %s, who was somebody's whole world" % [pn, Pets.species()], pn, {"species": Pets.species(), "name": pn})
			made += 1
	elif Prison.active():
		var l2 := Prison.L()
		if bool(l2.get("ex_guard", false)) or str(l2.get("outcome", "")) in ["served", "paroled", "escaped"] or Prison.served() >= 6:
			_add("convict", "%s, who did time" % name_, name_, {"years": Prison.served()})
			made += 1
		if Prison.is_guard() and (bool(l2.get("whistle", false)) or int(l2.get("rank", 1)) >= 4 or int(l2.get("commend", 0)) >= 1):
			_add("badge", "%s, who wore the uniform" % name_, name_, {"rank": Prison.rank_name(), "whistle": bool(l2.get("whistle", false))})
			made += 1
		if bool(l2.get("exonerated", false)):
			_add("name", "the %s who was cleared after all those years" % last, name_, {"last": last})
			made += 1
	else:
		if float(p.get("fame", 0)) >= 45.0 or int(p.get("net_worth_peak", 0)) >= 5000000:
			_add("name", "the %s name, which opened doors" % last, name_, {"last": last})
			made += 1
		var holders := Grit.grudge_holders(60)
		if not holders.is_empty():
			var f: Dictionary = GameState.npcs[holders[0]]
			_add("feud", "a quarrel with %s %s that nobody finished" % [str(f["first"]), str(f["last"])], name_, {"first": str(f["first"]), "last": str(f["last"])})
			made += 1
		for pid in GameState.npcs_with("pet"):
			var pet: Dictionary = GameState.npcs[pid]
			if int(pet.get("closeness", 0)) >= 60:
				_add("pet", "%s the %s, whom everyone remembered" % [str(pet["first"]), str(pet.get("species", "dog"))], name_, {"species": str(pet.get("species", "dog")), "name": str(pet["first"])})
				made += 1
				break
		if int(p.get("prison_total", 0)) >= 3:
			_add("convict", "%s, who went to prison" % name_, name_, {"years": int(p["prison_total"])})
			made += 1
	if made > 0:
		Meta.save()
	_unused(mode)


func _unused(_x) -> void:
	pass


## Called when a new life has just been made (not for a direct heir).
func on_new_life() -> void:
	var avail := pending()
	if avail.is_empty():
		return
	avail.shuffle()
	var n := 0
	for e in avail:
		if n >= PER_LIFE:
			break
		if _apply(e):
			e["used"] = true
			n += 1
	if n > 0:
		Meta.save()


func _pick(arr: Array) -> String:
	return str(arr[randi() % arr.size()])


func _apply(e: Dictionary) -> bool:
	var kind := str(e.get("kind", ""))
	var p := GameState.player
	var k := Lives.kind()
	var who := str(e.get("who", "someone"))
	var line := ""
	match kind:
		"name":
			var last := str(e.get("last", ""))
			match k:
				"pet":
					line = "The house still had a framed photograph of %s on the stairs. People mentioned the name in the voice they use for a good thing." % str(e.get("text", "somebody"))
					Pets.apply({"belonging": 4})
				"prisoner":
					line = "The name %s meant something to somebody on my landing: %s. It bought me one conversation before it ran out." % [last, str(e.get("text", ""))]
					Prison.apply({"respect": 5})
				"guard":
					line = "My colleagues knew the family name: %s. It didn't make anyone like me. It did make them listen." % str(e.get("text", ""))
					Prison.apply({"merit": 4})
				_:
					line = "People knew the name. %s: someone in the family had made it mean something, and I was handed it, whole." % str(e.get("text", "")).capitalize()
					p["fame"] = minf(100.0, float(p.get("fame", 0)) + 8.0)
					GameState.apply_effects({"happiness": 2})
		"feud":
			var f := str(e.get("first", "")) + " " + str(e.get("last", ""))
			match k:
				"prisoner":
					line = "Somebody on the east landing had a quarrel with my family, an old one, something about %s. I did not know whose side I was on." % f
					Prison.apply({"enemy": 1, "heat": 4})
				"guard":
					line = "An old quarrel with %s's family followed my name onto the wing. One inmate in particular remembered it." % f
					Prison.apply({"enemy": 1})
				"pet":
					line = "There was a tension in the house about someone named %s, which the people never explained to me, and which I smelled on their coats." % f
					Pets.apply({"mood": -4})
				_:
					line = "A quarrel nobody had finished came with the name: %s." % f
					var id := GameState.create_npc("rival", {"first": str(e.get("first", "Sam")), "last": str(e.get("last", "")), "age": randi_range(30, 70), "closeness": 8})
					GameState.npcs[id]["grudge"] = 55
		"pet":
			var pn := str(e.get("name", "a dog"))
			var sp_ := str(e.get("species", "dog"))
			match k:
				"pet":
					line = "There was a story in the house about %s, a %s who had been here before. People looked at me, sometimes, as though comparing. I tried to be as good." % [pn, sp_]
					Pets.apply({"bond": 5})
				"prisoner":
					line = "In the visiting room a child told me about the family's old %s, %s, the one everyone still talks about. For a moment I was not an inmate." % [sp_, pn]
					Prison.apply({"support": 6})
				"guard":
					line = "My grandmother kept a photograph of %s the %s by the kettle. I think of it when I'm tired on a night shift." % [pn, sp_]
					GameState.apply_effects({"happiness": 2})
				_:
					line = "The family had a story about %s the %s, and a descendant of the same line turned up in our garden." % [pn, sp_]
					GameState.create_npc("pet", {"species": sp_, "first": ContentDB.random_pet_name(), "last": "", "age": 0, "closeness": 70})
		"convict":
			match k:
				"prisoner":
					line = "I was not the first of the family to be inside. A man on the landing remembered the other one, and the way he carried himself. It was both a weight and a handrail."
					Prison.apply({"respect": 6, "heat": 3})
				"guard":
					line = "There had been someone in the family inside, once, and it was never mentioned. I thought of them every time I locked a door."
					Prison.apply({"integrity": 4, "trauma": 2})
				"pet":
					line = "Somewhere in the house's past there was a person who went away for a long time. The people did not talk about it, and the mat by the door stayed unmoved."
				_:
					line = "There was a family story nobody told properly: %s." % str(e.get("text", "someone did time"))
					GameState.apply_effects({"stress": 3})
					p["karma"] = clampi(int(p.get("karma", 0)) - 2, -100, 100)
		"badge":
			match k:
				"prisoner":
					line = "A cousin in the service had once been a name that men used in a certain voice. It put a very particular kind of eye on me."
					Prison.apply({"heat": -4, "respect": -3})
				"guard":
					line = "The uniform ran in the family: %s. They handed me the keys with that in mind." % str(e.get("text", ""))
					Prison.apply({"merit": 6, "integrity": 4})
				"pet":
					line = "A smell of polish and keys hung about the oldest coat in the cupboard, from a relative who had worn it. I slept on it."
				_:
					line = "Someone in the family had worn a uniform in a hard place: %s. It came down as a way of standing." % str(e.get("text", ""))
					GameState.apply_effects({"smarts": 1, "stress": -2})
		_:
			return false
	if line == "":
		return false
	GameState.add_log(line)
	GameState.add_milestone(int(p.get("age", 0)), "carried an echo of %s" % who)
	GameState.counter("echoes_used")
	return true


func menu_lines() -> Array:
	var out: Array = []
	for e in _store():
		out.append("%s %s" % ["✓" if bool(e.get("used", false)) else "•", str(e.get("text", ""))])
	return out

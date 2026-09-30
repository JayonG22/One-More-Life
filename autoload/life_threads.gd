extends Node

## Life Threads are durable memories that can return years later.
## A thread is not a quest marker. It is a piece of a life: a person, place,
## loss, victory, mistake or secret that can echo into future events.

const KINDS := {
	"relationship": {"icon":"🧵", "name":"A relationship that stayed with me"},
	"grief": {"icon":"🕯️", "name":"Someone I still carry with me"},
	"gambling": {"icon":"🎰", "name":"The night luck changed the room"},
	"illness": {"icon":"❤️‍🩹", "name":"A health chapter I remember"},
	"injury": {"icon":"🩹", "name":"An injury that changed my pace"},
	"recovery": {"icon":"🌱", "name":"A recovery I worked for"},
	"home": {"icon":"🏡", "name":"A place that became part of the family"},
	"neighbor": {"icon":"🏘️", "name":"A neighbor story that never quite ended"},
	"pirate": {"icon":"🏴‍☠️", "name":"A name from the sea"},
	"colonist": {"icon":"🪐", "name":"A memory under another sky"},
	"traveler": {"icon":"⏳", "name":"A secret that does not belong to this time"},
	"family": {"icon":"🌳", "name":"A family story still unfolding"},
	"career": {"icon":"💼", "name":"A working life that left marks"},
	"regret": {"icon":"🪞", "name":"A decision I would take back"},
	"money": {"icon":"📉", "name":"A number that changed everything"},
	"justice": {"icon":"⚖️", "name":"A day in front of a judge"},
}


func _p() -> Dictionary:
	return GameState.player


func ensure() -> void:
	if _p().is_empty():
		return
	if not _p().has("threads") or not (_p()["threads"] is Dictionary):
		_p()["threads"] = {"next": 1, "items": {}, "history": []}
	var root: Dictionary = _p()["threads"]
	if not root.has("next"): root["next"] = 1
	if not root.has("items") or not (root["items"] is Dictionary): root["items"] = {}
	if not root.has("history") or not (root["history"] is Array): root["history"] = []


func remember(kind: String, title: String, memory: String, npc: String = "", strength: int = 55, tags: Array = []) -> String:
	ensure()
	if not KINDS.has(kind):
		kind = "relationship"
	# Repeated moments with the same person/kind deepen an existing thread instead
	# of filling the save with duplicates.
	for id in _p()["threads"]["items"].keys():
		var old: Dictionary = _p()["threads"]["items"][id]
		if old.get("state", "active") == "active" and old.get("kind", "") == kind and str(old.get("npc", "")) == npc and npc != "":
			old["strength"] = mini(100, int(old.get("strength", 50)) + maxi(4, strength / 5))
			old["memory"] = memory
			old["last_touched"] = int(_p()["age"])
			for tag in tags:
				if not old["tags"].has(tag): old["tags"].append(tag)
			return str(id)
	var n := int(_p()["threads"]["next"])
	_p()["threads"]["next"] = n + 1
	var id := "t%d" % n
	_p()["threads"]["items"][id] = {
		"id": id, "kind": kind, "title": title, "memory": memory,
		"npc": npc, "created_age": int(_p()["age"]), "last_echo": int(_p()["age"]),
		"last_touched": int(_p()["age"]), "strength": clampi(strength, 10, 100),
		"echoes": 0, "state": "active", "tags": tags.duplicate(),
	}
	GameState.counter("life_threads")
	return id


func from_outcome(spec: Dictionary, roles: Dictionary) -> void:
	var npc := ""
	var role := str(spec.get("role", ""))
	if role != "" and roles.has(role): npc = str(roles[role])
	remember(str(spec.get("kind", "relationship")), str(spec.get("title", "A moment that stayed with me")), str(spec.get("memory", "I knew I would remember this.")), npc, int(spec.get("strength", 55)), Array(spec.get("tags", [])))


func outcome(spec: Dictionary) -> void:
	ensure()
	var id := str(spec.get("id", ""))
	if not _p()["threads"]["items"].has(id):
		return
	var t: Dictionary = _p()["threads"]["items"][id]
	t["strength"] = clampi(int(t.get("strength", 50)) + int(spec.get("strength", 0)), 0, 100)
	t["last_touched"] = int(_p()["age"])
	if spec.get("resolve", false) or int(t["strength"]) <= 0:
		resolve(id, str(spec.get("note", "I let that chapter settle into the past.")))


func resolve(id: String, note: String = "") -> void:
	ensure()
	if not _p()["threads"]["items"].has(id): return
	var t: Dictionary = _p()["threads"]["items"][id]
	t["state"] = "resolved"
	t["resolved_age"] = int(_p()["age"])
	if note != "": t["resolution"] = note
	_p()["threads"]["history"].append(t.duplicate(true))
	_p()["threads"]["items"].erase(id)
	GameState.counter("threads_resolved")


func active_count() -> int:
	ensure()
	return _p()["threads"]["items"].size()


func menu(key: String) -> Dictionary:
	ensure()
	if key == "" or key == "root":
		var rows: Array = []
		var ids: Array = _p()["threads"]["items"].keys()
		ids.sort_custom(func(a,b): return int(_p()["threads"]["items"][a].get("strength",0)) > int(_p()["threads"]["items"][b].get("strength",0)))
		for id in ids:
			var t: Dictionary = _p()["threads"]["items"][id]
			var kd: Dictionary = KINDS.get(t["kind"], KINDS["relationship"])
			var age_gap := int(_p()["age"]) - int(t["created_age"])
			rows.append({"icon":kd["icon"], "name":t["title"], "sub":"Started age %d · %d year%s ago · %d echo%s" % [int(t["created_age"]), age_gap, "" if age_gap == 1 else "s", int(t["echoes"]), "" if int(t["echoes"]) == 1 else "es"], "menu":"threads:view:"+id, "on":true})
		if rows.is_empty():
			rows.append({"icon":"🧶", "name":"No active threads yet", "sub":"Important people, losses, victories, places and secrets can become threads.", "on":false})
		return {"icon":"🧵", "title":"Life Threads", "rows":rows, "info":["Threads are memories the simulation is allowed to bring back years later.", "%d resolved thread%s are part of this life history." % [_p()["threads"]["history"].size(), "" if _p()["threads"]["history"].size() == 1 else "s"]]}
	if key.begins_with("view:"):
		var id2 := key.substr(5)
		if not _p()["threads"]["items"].has(id2): return menu("root")
		var t2: Dictionary = _p()["threads"]["items"][id2]
		var kd2: Dictionary = KINDS.get(t2["kind"], KINDS["relationship"])
		var rows2: Array = [
			{"icon":"🪞", "name":"Reflect on it", "sub":"1 time · can lower stress and soften the thread", "act":"threads:reflect", "arg":id2, "on":true},
		]
		var nid := str(t2.get("npc", ""))
		if nid != "" and GameState.npcs.has(nid) and GameState.npcs[nid].get("alive", false):
			rows2.append({"icon":"📞", "name":"Reach out to %s" % GameState.npcs[nid]["first"], "sub":"1 time · reconnect with the person tied to this thread", "act":"threads:reach", "arg":id2, "on":true})
		if int(t2.get("echoes",0)) > 0 or int(_p()["age"]) - int(t2["created_age"]) >= 5:
			rows2.append({"icon":"📕", "name":"Let this chapter rest", "sub":"Archive it; it stops generating future echoes", "act":"threads:resolve", "arg":id2, "on":true})
		return {"icon":kd2["icon"], "title":t2["title"], "rows":rows2, "info":[str(t2["memory"]), "Strength %d/100 · %d echo%s so far" % [int(t2["strength"]), int(t2["echoes"]), "" if int(t2["echoes"]) == 1 else "es"]]}
	return menu("root")


func act(key: String, arg) -> void:
	ensure()
	var id := str(arg)
	if not _p()["threads"]["items"].has(id): return
	var t: Dictionary = _p()["threads"]["items"][id]
	match key:
		"reflect":
			if Actions._out_of_time(): return
			t["strength"] = maxi(10, int(t["strength"]) - randi_range(3,8))
			Actions._done("🪞", "Reflection", "I gave myself enough quiet to think about it without pretending it never happened.", {"stress":-5, "happiness":2})
		"reach":
			var nid := str(t.get("npc", ""))
			if nid == "" or not GameState.npcs.has(nid) or not GameState.npcs[nid].get("alive", false): return
			if Actions._out_of_time(): return
			GameState.change_closeness(nid, 7)
			t["strength"] = maxi(10, int(t["strength"]) - 4)
			Actions._done("📞", "Reached out", "I called %s. We did not solve an entire history in one conversation, but we talked." % GameState.npcs[nid]["first"], {"happiness":4, "stress":-3})
		"resolve":
			resolve(id, "I stopped needing this memory to knock on the door by itself.")
			EventEngine.push_info("📕", "A chapter rests", "The memory is still part of the life. It simply will not keep returning as an active thread.")


func yearly() -> void:
	ensure()
	_seed_from_state()
	if _p()["threads"]["items"].is_empty() or GameState.in_prison() and randf() < 0.5:
		return
	var candidates: Array = []
	for id in _p()["threads"]["items"].keys():
		var t: Dictionary = _p()["threads"]["items"][id]
		var years := int(_p()["age"]) - int(t.get("last_echo", t["created_age"]))
		if years < 2: continue
		var age_of_thread := int(_p()["age"]) - int(t["created_age"])
		if age_of_thread < 2: continue
		var w := float(t.get("strength",50)) / 100.0
		w *= minf(1.6, 0.45 + years * 0.18)
		w *= 1.0 + minf(0.6, GameState.stat("stress") / 180.0)
		if int(t.get("echoes",0)) >= 3: w *= 0.45
		if w > 0.15: candidates.append({"id":id, "w":w})
	if candidates.is_empty() or randf() > 0.34 * Grit.d("twist"):
		return
	var total := 0.0
	for c in candidates: total += float(c["w"])
	var roll := randf() * total
	var pick := str(candidates[0]["id"])
	for c in candidates:
		roll -= float(c["w"])
		if roll <= 0.0:
			pick = str(c["id"])
			break
	_push_echo(pick)


func _seed_from_state() -> void:
	# These are fallback bridges for v0.6 saves. New v0.7 systems call remember()
	# at the moment the event happens, but old saves may already contain history.
	if GameState.has_flag("widowed") and not GameState.has_flag("thread_widowed"):
		GameState.set_flag("thread_widowed")
		remember("grief", "The person I lost", "Widowhood changed the shape of ordinary days.", "", 70, ["legacy"])
	if GameState.get_counter("gamble_wins") >= 4 and not GameState.has_flag("thread_gambling_seed"):
		GameState.set_flag("thread_gambling_seed")
		remember("gambling", "The tables remember me", "Winning made the casino feel less like chance and more like a place where something might happen again.", "", 52, ["gambling"])
	if GameState.get_counter("scars") > 0 and not GameState.has_flag("thread_scar_seed"):
		GameState.set_flag("thread_scar_seed")
		remember("injury", "What my body remembers", "An old injury became part of how I plan my days.", "", 48, ["health"])


func _push_echo(id: String) -> void:
	if not _p()["threads"]["items"].has(id): return
	var t: Dictionary = _p()["threads"]["items"][id]
	t["last_echo"] = int(_p()["age"])
	t["echoes"] = int(t.get("echoes",0)) + 1
	var def := _echo_def(id, t)
	var roles := {}
	var nid := str(t.get("npc", ""))
	if nid != "" and GameState.npcs.has(nid) and GameState.npcs[nid].get("alive", false): roles["thread_person"] = nid
	EventEngine.push_decision(def, roles)
	GameState.counter("thread_echoes")


func _echo_def(id: String, t: Dictionary) -> Dictionary:
	var kind := str(t.get("kind", "relationship"))
	var kd: Dictionary = KINDS.get(kind, KINDS["relationship"])
	var base := {"id":"_thread_%s_%d" % [id, int(t.get("echoes",0))], "icon":kd["icon"], "title":"Life Thread", "text":"", "choices":[]}
	match kind:
		"grief":
			base["text"] = "Something ordinary brings the loss back with surprising force: a song, a smell, a date on the calendar. %s" % t["memory"]
			base["choices"] = [
				_ch("Make room for the feeling", id, [{"weight":2,"text":"I let the memory hurt without making the whole day a punishment.","effects":{"stress":-5,"happiness":1},"strength":-6},{"weight":1,"text":"I tried. It was a heavier day than I expected, but I stayed with it.","effects":{"stress":2},"strength":-2}]),
				_ch("Call someone who knew them", id, [{"weight":2,"text":"We traded stories until the grief felt shared instead of private.","effects":{"happiness":5,"stress":-4},"strength":-7},{"weight":1,"text":"The call was awkward, but hearing their name out loud still helped.","effects":{"happiness":2},"strength":-3}]),
				_ch("Keep busy and move on", id, [{"weight":1,"text":"I filled every hour. The memory waited until bedtime.","effects":{"stress":4},"strength":5},{"weight":1,"text":"The distraction gave me enough distance to get through the day.","effects":{"stress":-2},"strength":1}]),
			]
		"gambling":
			base["text"] = "A casino promotion arrives with my name printed in gold. It reminds me how quickly luck can turn into a plan. %s" % t["memory"]
			base["choices"] = [
				_ch("Ignore the invitation", id, [{"weight":2,"text":"I deleted it. The urge passed faster than the marketing department hoped.","effects":{"stress":-3},"strength":-7},{"weight":1,"text":"I deleted it, then thought about it for the rest of the evening.","effects":{"stress":2},"strength":-2}]),
				_ch("Go shopping instead", id, [{"weight":1,"text":"I bought something useful and still had money left. That felt strangely satisfying.","effects":{"happiness":3,"money":-120},"strength":-4},{"weight":1,"text":"I replaced one impulse with another and spent more than planned.","effects":{"happiness":2,"money":-600,"stress":2},"strength":2}]),
				_ch("Tell myself I can handle one visit", id, [{"weight":1,"text":"I walked through the casino and left without betting. That mattered.","effects":{"happiness":2,"stress":-2},"strength":-5},{"weight":2,"text":"The lights did exactly what they were designed to do. I left wanting another night there.","effects":{"stress":3},"strength":8}]),
			]
		"illness", "injury", "recovery":
			base["text"] = "A small body sensation pulls me back to an older health chapter. %s" % t["memory"]
			base["choices"] = [
				_ch("Book a checkup", id, [{"weight":2,"text":"The appointment gave me useful information instead of an afternoon of guessing.","effects":{"health":2,"stress":-5,"money":-180},"strength":-6},{"weight":1,"text":"Nothing urgent showed up, but the visit reminded me to keep taking care of myself.","effects":{"stress":-2,"money":-180},"strength":-3}]),
				_ch("Use what recovery taught me", id, [{"weight":2,"text":"I slowed down, slept, ate properly and did the boring things that actually help.","effects":{"health":2,"stress":-4},"strength":-6},{"weight":1,"text":"I tried to follow the old plan, but the fear took longer to settle than the symptom.","effects":{"stress":2},"strength":-2}]),
				_ch("Pretend I never worry about it", id, [{"weight":1,"text":"The bravado worked for a day. The worry came back quieter.","effects":{"happiness":1},"strength":2},{"weight":1,"text":"Ignoring it turned a small concern into a week of stress.","effects":{"stress":6},"strength":6}]),
			]
		"home", "neighbor":
			base["text"] = "The house gives me one of those moments where a room suddenly contains several years at once. %s" % t["memory"]
			base["choices"] = [
				_ch("Preserve the memory", id, [{"weight":2,"text":"I kept one small reminder instead of turning the whole place into a museum.","effects":{"happiness":5},"strength":-4},{"weight":1,"text":"I got sentimental and lost an afternoon to old boxes. Worth it.","effects":{"happiness":4,"stress":1},"strength":-1}]),
				_ch("Invite people over", id, [{"weight":2,"text":"The rooms filled with new noise. The old memory did not disappear; it simply got company.","effects":{"happiness":7,"stress":-3,"money":-180},"strength":-6},{"weight":1,"text":"Half the guests canceled, but the people who came stayed late.","effects":{"happiness":4,"money":-120},"strength":-3}]),
				_ch("Change the room completely", id, [{"weight":1,"text":"Moving everything around made the house feel like mine again.","effects":{"happiness":4,"money":-500},"strength":-5},{"weight":1,"text":"I spent money trying to outrun a feeling. The couch is nicer, at least.","effects":{"money":-1400,"stress":2},"strength":2}]),
			]
		"pirate":
			base["text"] = "A sailor in port repeats a story from years ago, and I recognize my own life in the version everyone else tells. %s" % t["memory"]
			base["choices"] = [
				_ch("Correct the story", id, [{"weight":1,"text":"I told them what actually happened. Nobody believed the less dramatic version.","effects":{"happiness":2},"strength":-2},{"weight":1,"text":"The truth impressed the crew more than the legend did.","effects":{"happiness":5},"strength":-5}]),
				_ch("Let the legend grow", id, [{"weight":2,"text":"By sunset I had apparently fought forty men and a sea monster. Reputation is efficient that way.","effects":{"happiness":5,"karma":-1},"strength":5},{"weight":1,"text":"The story drew trouble from someone eager to test it.","effects":{"stress":6},"strength":8}]),
				_ch("Buy the storyteller a drink", id, [{"weight":2,"text":"We laughed at how memory edits a life.","effects":{"happiness":5,"money":-40},"strength":-5},{"weight":1,"text":"They knew details I never told anyone. I left the tavern watching the door.","effects":{"stress":5,"money":-40},"strength":4}]),
			]
		"colonist":
			base["text"] = "A younger colonist asks about the early days as if they were ancient history. %s" % t["memory"]
			base["choices"] = [
				_ch("Tell the frightening version", id, [{"weight":1,"text":"They listened carefully. Fear is useful when it teaches respect instead of panic.","effects":{"smarts":1,"stress":-2},"strength":-4},{"weight":1,"text":"I heard how close we came to disaster all over again.","effects":{"stress":4},"strength":1}]),
				_ch("Tell the hopeful version", id, [{"weight":2,"text":"By the end, the story was less about surviving Mars and more about people choosing to stay.","effects":{"happiness":6},"strength":-6},{"weight":1,"text":"I made it sound cleaner than it was. Maybe every generation does that.","effects":{"happiness":3},"strength":-2}]),
				_ch("Show them the old records", id, [{"weight":2,"text":"Data, photos and repair logs said more than any speech could.","effects":{"smarts":2,"happiness":3},"strength":-5},{"weight":1,"text":"One file contained a detail I had forgotten. I did not sleep much that night.","effects":{"stress":5},"strength":3}]),
			]
		"traveler":
			base["text"] = "Something is wrong with an ordinary detail: a date, a brand name, a memory I am sure used to be different. %s" % t["memory"]
			base["choices"] = [
				_ch("Write down both versions", id, [{"weight":2,"text":"Putting both memories on paper made the contradiction feel containable.","effects":{"smarts":2,"stress":-3},"strength":-4},{"weight":1,"text":"The notes disagreed with an older page in my own handwriting.","effects":{"stress":6},"strength":5}]),
				_ch("Protect my cover and say nothing", id, [{"weight":2,"text":"I swallowed the question and kept acting like I belonged here.","effects":{"stress":2},"strength":-2},{"weight":1,"text":"Silence kept the secret safe, but loneliness made it heavier.","effects":{"happiness":-3,"stress":4},"strength":3}]),
				_ch("Test the timeline", id, [{"weight":1,"text":"I made a tiny prediction. It came true exactly when I remembered.","effects":{"smarts":2,"happiness":3},"strength":5},{"weight":1,"text":"The prediction failed. Either my memory is wrong or history moved.","effects":{"stress":8},"strength":9}]),
			]
		"career":
			base["text"] = "Someone brings up the work I did back then as if it were the only thing I ever was. %s" % t["memory"]
			base["choices"] = [
				_ch("Own the whole record", id, [{"weight":2,"text":"I described the wins and the cost of them in the same breath. People listened differently after that.","effects":{"happiness":4,"stress":-3},"strength":-6},{"weight":1,"text":"Saying it plainly was harder than I expected, and more useful.","effects":{"stress":2,"smarts":1},"strength":-3}]),
				_ch("Pass it to someone starting out", id, [{"weight":2,"text":"I told a younger version of me what nobody told me. That was worth more than the story.","effects":{"happiness":6,"karma":2},"strength":-7},{"weight":1,"text":"They nodded politely and will learn it the slow way anyway.","effects":{"happiness":1},"strength":-2}]),
				_ch("Change the subject", id, [{"weight":1,"text":"I steered away from it. Not every room has earned that part of me.","effects":{"stress":-2},"strength":1},{"weight":1,"text":"Dodging it made the memory louder for the rest of the night.","effects":{"stress":5},"strength":5}]),
			]
		"regret":
			base["text"] = "The thing I did wrong surfaces without warning, in full detail, as if it happened this morning. %s" % t["memory"]
			base["choices"] = [
				_ch("Make it right if I still can", id, [{"weight":2,"text":"I made the call I should have made years ago. It did not undo anything, but it was no longer sitting there untouched.","effects":{"happiness":7,"stress":-6,"karma":4},"strength":-9},{"weight":1,"text":"They did not want to hear from me. I understood, said so, and left it.","effects":{"stress":3,"karma":2},"strength":-3}]),
				_ch("Take the lesson and stop paying for it", id, [{"weight":2,"text":"I stopped treating the memory as a debt I could never finish repaying.","effects":{"stress":-6,"happiness":3},"strength":-7},{"weight":1,"text":"I told myself it was finished. Some nights disagree.","effects":{"stress":2},"strength":-2}]),
				_ch("Defend what I did", id, [{"weight":1,"text":"I built the case for myself again. It held up, mostly.","effects":{"stress":-1},"strength":3},{"weight":2,"text":"The defense sounded thinner out loud than it does in my head.","effects":{"happiness":-4,"stress":6},"strength":7}]),
			]
		"money":
			base["text"] = "A statement, a letter or an old contract turns up and puts a number back in front of me. %s" % t["memory"]
			base["choices"] = [
				_ch("Look at the real figures", id, [{"weight":2,"text":"I went through all of it properly. Knowing the number was less frightening than avoiding it.","effects":{"smarts":2,"stress":-5},"strength":-6},{"weight":1,"text":"The arithmetic was worse than I hoped and clearer than before.","effects":{"stress":4,"smarts":1},"strength":-2}]),
				_ch("Rebuild carefully", id, [{"weight":2,"text":"I started again in smaller, duller, more survivable steps.","effects":{"happiness":4,"stress":-3},"strength":-7},{"weight":1,"text":"The plan was sound. Patience was the part I had to relearn.","effects":{"stress":1},"strength":-3}]),
				_ch("Chase it back in one move", id, [{"weight":1,"text":"The gamble worked. I know exactly how close it was.","effects":{"happiness":6,"stress":3},"strength":4},{"weight":2,"text":"I tried to win it back quickly and repeated the original mistake with more experience.","effects":{"money":-2500,"stress":9,"happiness":-5},"strength":9}]),
			]
		"justice":
			base["text"] = "A form, a background check or a question from a stranger reaches back into the court record. %s" % t["memory"]
			base["choices"] = [
				_ch("Say it before they find it", id, [{"weight":2,"text":"I put it on the table myself. Telling it first changed whose story it was.","effects":{"happiness":5,"stress":-5},"strength":-7},{"weight":1,"text":"Honesty cost me the opportunity, and I would still rather have told them.","effects":{"stress":4,"karma":2},"strength":-3}]),
				_ch("Let the paperwork speak", id, [{"weight":2,"text":"The record was accurate and old, and this time that was enough.","effects":{"stress":-3},"strength":-5},{"weight":1,"text":"A clerk read one line and stopped reading. The decision was already made.","effects":{"happiness":-5,"stress":6},"strength":4}]),
				_ch("Hide it and hope", id, [{"weight":1,"text":"Nobody checked. I spent the year waiting for someone to.","effects":{"stress":7},"strength":6},{"weight":1,"text":"It surfaced later, and the hiding was worse than the record.","effects":{"happiness":-7,"stress":10},"strength":10}]),
			]
		_:
			base["text"] = "A detail from years ago comes back into the present. %s" % t["memory"]
			base["choices"] = [
				_ch("Talk about it", id, [{"weight":2,"text":"Saying it out loud made the memory smaller and more precise.","effects":{"stress":-4,"happiness":2},"strength":-5},{"weight":1,"text":"The conversation opened an old argument I thought was finished.","effects":{"stress":4},"strength":3}]),
				_ch("Do something different this time", id, [{"weight":2,"text":"I noticed the old pattern and chose another route.","effects":{"happiness":5},"strength":-7},{"weight":1,"text":"I meant to change the pattern. Habit got there first.","effects":{"happiness":-2,"stress":3},"strength":2}]),
				_ch("Leave it alone", id, [{"weight":1,"text":"Some memories do not need a verdict.","effects":{"stress":-2},"strength":-3},{"weight":1,"text":"I called it resolved. My brain disagreed at three in the morning.","effects":{"stress":5},"strength":4}]),
			]
	return base


func _ch(label: String, id: String, outcomes: Array) -> Dictionary:
	var out: Array = []
	for src in outcomes:
		var o: Dictionary = src.duplicate(true)
		var delta := int(o.get("strength", 0))
		o.erase("strength")
		o["thread_effect"] = {"id":id, "strength":delta}
		out.append(o)
	return {"label":label, "outcomes":out}

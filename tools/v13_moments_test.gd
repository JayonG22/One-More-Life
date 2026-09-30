extends Node

## v0.13 gate — the named beat vocabulary.
##
## The point of Moments is that presentation follows what HAPPENED. So this
## gate does not check that the file loads; it checks that a crime sounds like
## a crime even when the sentence never says so, and that a sentence about a
## crime in a daydream does not set off the sirens.

var failures: Array = []
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V13: " + msg)


func _ready() -> void:
	seed(1313)
	_vocabulary()
	_wiring()
	_structural()
	_intensity()
	_loudness()
	_fallback()
	_engine_signals()
	_content()
	print("V13 MOMENTS TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


# ---- 1. every beat is playable: a typo in a sound id is silence, not a crash,
#         so nothing else would ever catch it.
func _vocabulary() -> void:
	var named := ["money_gain", "money_loss", "stat_gain", "stat_loss", "danger",
		"success", "failure", "achievement", "death", "relationship_gain",
		"relationship_break", "jackpot", "crime_heat", "diagnosis"]
	for n in named:
		ok(Moments.BEATS.has(n), "the design doc names '%s' and it is not in the vocabulary" % n)
	var burst_kinds := ["hearts", "coins", "sparks", "magic", "blood", "royal", "grief", "confetti"]
	for beat in Moments.BEATS.keys():
		var b: Dictionary = Moments.BEATS[beat]
		var snd := str(b.get("sound", ""))
		ok(snd != "", "%s has no sound" % beat)
		ok(Fx._build(snd) != null, "%s plays a sound Fx cannot build" % beat)
		ok(Fx._build(snd).data.size() > 400, "%s plays '%s', which renders as near-silence" % [beat, snd])
		for key in ["burst", "rise"]:
			var arr: Array = b.get(key, ["", 0])
			if str(arr[0]) != "":
				ok(burst_kinds.has(str(arr[0])), "%s uses unknown particle kind '%s'" % [beat, arr[0]])
		ok(Moments.LOUDNESS.has(beat), "%s has no loudness, so it can never win the screen" % beat)


# ---- 2. it is actually wired in: main hands over its layers, and firing
#         without them must not explode (headless, scheduled, minigame open).
func _wiring() -> void:
	ok(not Moments.ready_to_play(), "Moments thinks it has a layer before main binds one")
	Moments.fire("jackpot")
	Moments.fire("nonsense_beat")
	Moments.play_set({})
	checks += 1  # reaching here without a crash is the check
	var src := FileAccess.get_file_as_string("res://scenes/main.gd")
	ok(src.find("Moments.bind(") != -1, "main.gd never binds its effects layer to Moments")
	ok(src.find("Moments.react(") != -1, "main.gd does not route event reactions through Moments")
	ok(src.find("var celebrate := [") == -1, "the old keyword-sniffing reaction table is still in main.gd")


# ---- 3. the whole point: beats come from what happened.
func _structural() -> void:
	GameState.new_life({"first": "Test", "last": "Case", "gender": "female"})

	var jailed := Moments.beats_for(["jail", "crime"], {})
	ok(jailed.has("verdict"), "going to prison did not produce a verdict beat")
	ok(jailed.has("crime_heat"), "a crime did not produce crime heat")

	var sick := Moments.beats_for(["illness"], {"health": -12.0})
	ok(sick.has("diagnosis"), "being diagnosed did not produce the diagnosis beat")

	var wed := Moments.beats_for(["marry"], {"happiness": 14.0})
	ok(wed.has("wedding"), "getting married did not produce a wedding beat")

	var born := Moments.beats_for(["baby"], {})
	ok(born.has("birth"), "a child being born did not produce a birth beat")

	var split := Moments.beats_for(["partner_lost"], {"happiness": -20.0})
	ok(split.has("relationship_break"), "losing a partner did not produce a break beat")

	var freed := Moments.beats_for(["cleared"], {})
	ok(freed.has("freedom"), "a cleared record did not produce the freedom beat")

	# and the inverse, which is the failure the old code actually had:
	# a sentence that talks about prison while nothing happened stays quiet.
	var daydream := Moments.beats_for([], {})
	ok(daydream.is_empty(), "an outcome that did nothing still produced %s" % str(daydream.keys()))
	var reacted := Moments.beats_from_text("A bad dream", "I dreamed I was arrested and sent to prison.", )
	ok(not reacted.has("crime_heat"), "a daydream about prison set off the sirens")


# ---- 4. intensity: the same beat has to read differently at different sizes.
func _intensity() -> void:
	GameState.player["money"] = 4000
	var small := Moments.beats_for([], {"money": 300})
	var big := Moments.beats_for([], {"money": 3500})
	ok(small.has("money_gain") and big.has("money_gain"), "money changes did not produce money beats")
	ok(float(big["money_gain"]) > float(small["money_gain"]),
		"a windfall and pocket change played at the same volume (%.2f vs %.2f)" % [big.get("money_gain", 0.0), small.get("money_gain", 0.0)])

	var tiny := Moments.beats_for([], {"money": 40})
	ok(not tiny.has("money_gain"), "forty in change set off the coin shower")

	var huge := Moments.beats_for([], {"money": 900000})
	ok(huge.has("jackpot"), "nine hundred thousand did not register as a jackpot")
	ok(not huge.has("money_gain"), "a jackpot also fired the ordinary money beat")

	var hurt := Moments.beats_for([], {"health": -30.0})
	ok(hurt.has("danger"), "losing thirty health was not treated as danger")
	var scratch := Moments.beats_for([], {"health": -4.0})
	ok(not scratch.has("danger"), "a four-point scratch was treated as danger")

	# a mixed result is not a triumph
	var mixed := Moments.beats_for([], {"happiness": 14.0, "health": -13.0, "stress": 10.0})
	ok(not mixed.has("stat_gain"), "a result that cost health and calm still read as a gain")

	# floors: a beat with a floor is never whispered
	ok(Moments.BEATS["death"].get("floor", 0.0) >= 1.0, "death can be played quietly")
	ok(Moments.BEATS["jackpot"].get("floor", 0.0) >= 0.8, "a jackpot can be played quietly")


# ---- 5. when several things happen at once, the big one wins.
func _loudness() -> void:
	var lots := {"money_gain": 1.0, "death": 1.0, "stat_gain": 1.0, "success": 1.0}
	var order: Array = lots.keys()
	order.sort_custom(func(a, b): return int(Moments.LOUDNESS.get(a, 0)) > int(Moments.LOUDNESS.get(b, 0)))
	ok(str(order[0]) == "death", "death did not outrank a coin sound")
	ok(int(Moments.LOUDNESS["diagnosis"]) > int(Moments.LOUDNESS["money_gain"]),
		"a diagnosis is quieter than finding money")
	ok(int(Moments.LOUDNESS["turn_vampire"]) > int(Moments.LOUDNESS["achievement"]),
		"being turned into a vampire is quieter than an achievement")
	# every beat has a distinct loudness within its tier, or ties decide arbitrarily
	ok(Moments.LOUDNESS.size() == Moments.BEATS.size(), "loudness table and beat table disagree in size")


# ---- 6. text is the fallback, and it still has to work for pure story events.
func _fallback() -> void:
	var grad := Moments.beats_from_text("Graduation", "I graduated with honours.")
	ok(grad.has("milestone"), "a graduation with no stat change produced nothing at all")
	var nothing := Moments.beats_from_text("A quiet year", "Not much happened.")
	ok(nothing.is_empty(), "a quiet year produced a beat anyway")


# ---- 7. the engine has to actually report what it did.
func _engine_signals() -> void:
	GameState.new_life({"first": "Sig", "last": "Nal", "gender": "male"})
	GameState.player["age"] = 30
	var before: Dictionary = EventEngine._snapshot()
	ok(before.has("kids") and before.has("record") and before.has("illness"),
		"the engine's before-picture is missing fields the beats depend on")

	# an outcome that quietly gives you an illness, with prose that never says so
	var res := EventEngine._apply_outcome(
		{"text": "It was a long week.", "illness": "flu"}, {}, {"id": "_t", "choices": []})
	ok(res.has("signals"), "resolve did not report what the outcome did")
	ok((res["signals"] as Array).has("illness"),
		"an outcome that set an illness did not report it")
	var beats := Moments.beats_for(res["signals"], res.get("changes", {}))
	ok(beats.has("diagnosis"), "a silent diagnosis produced no diagnosis beat")

	# and a fine is money leaving, reported as heat
	GameState.player["money"] = 20000
	var res2 := EventEngine._apply_outcome(
		{"text": "Paid it and said nothing.", "fine": 800}, {}, {"id": "_t2", "choices": []})
	ok((res2["signals"] as Array).has("fine"), "a fine was not reported")
	var b2 := Moments.beats_for(res2["signals"], res2.get("changes", {}))
	ok(b2.has("crime_heat"), "a fine produced no crime heat")
	ok(b2.has("money_loss"), "a fine that took money produced no money-loss beat")


# ---- 8. the content pass. Five files are now fully compliant with the design
#         rule; the gate is what stops them sliding back.
func _content() -> void:
	var files := {
		"twists": 58, "lives": 53, "more": 46, "connections": 37, "empires": 34,
	}
	var lib_ch := 0
	var lib_det := 0
	for name in files.keys():
		var raw := FileAccess.get_file_as_string("res://data/events/%s.json" % name)
		var evs = JSON.parse_string(raw)
		ok(evs is Array, "%s.json did not parse" % name)
		if not (evs is Array):
			continue
		ok((evs as Array).size() >= int(files[name]),
			"%s.json lost events (%d, expected at least %d)" % [name, (evs as Array).size(), files[name]])
		var det := 0
		var thin := 0
		var outs := 0
		var chs := 0
		for ev in evs:
			var cs: Array = ev.get("choices", [])
			if cs.size() < 3:
				thin += 1
			for ch in cs:
				chs += 1
				var n: int = (ch.get("outcomes", []) as Array).size()
				outs += n
				if n < 2:
					det += 1
		ok(det == 0, "%s.json has %d choices with only one outcome" % [name, det])
		ok(thin == 0, "%s.json has %d events with fewer than three choices" % [name, thin])
		ok(outs >= chs * 2, "%s.json: %d outcomes across %d choices" % [name, outs, chs])
		print("  %s.json: %d events, %d choices, %d outcomes" % [name, (evs as Array).size(), chs, outs])

	# and the library as a whole has to keep moving in the right direction
	var dir := DirAccess.open("res://data/events")
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var evs2 = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/" + f))
		if not (evs2 is Array):
			continue
		for ev in evs2:
			for ch in ev.get("choices", []):
				lib_ch += 1
				if (ch.get("outcomes", []) as Array).size() < 2:
					lib_det += 1
	var pct := 100.0 * float(lib_det) / maxf(1.0, float(lib_ch))
	print("  library: %d choices, %d deterministic (%.1f%%)" % [lib_ch, lib_det, pct])
	ok(pct <= 17.0, "library deterministic share climbed back to %.1f%%" % pct)

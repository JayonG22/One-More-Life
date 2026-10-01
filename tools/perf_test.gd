extends Node

## Long-life stress: an ageless life run for centuries. The cost of a year must
## not grow with the length of the life, and the save must stay a sane size.

const YEARS := 300
var failures: Array = []


func _drain() -> void:
	var guard := 0
	while EventEngine.has_pending() and guard < 25 and GameState.is_alive():
		guard += 1
		var inst := EventEngine.pop_next()
		if inst.get("info", false):
			continue
		var choices: Array = inst["def"].get("choices", [])
		var opts: Array = []
		for ci in range(choices.size()):
			var st := EventEngine.choice_state(choices[ci], inst.get("roles", {}))
			if st["visible"] and st["enabled"]:
				opts.append(ci)
		if opts.is_empty():
			continue
		var res := EventEngine.resolve(inst, opts[randi() % opts.size()])
		if res.get("died", false):
			return


func _ready() -> void:
	seed(3032)
	# the gate shares one save folder between checks; what earlier checks left in the
	# meta (which events were seen lately) must not decide how this life goes
	Meta.meta["recent"] = {}
	SaveManager.begin_new_life()
	GameState.new_life({"gender": "female", "country": "us", "life_path": "vampire"})
	var first_ms := 0.0
	var last_ms := 0.0
	var total_ms := 0.0
	var years := 0
	var worst := 0.0
	while GameState.is_alive() and years < YEARS:
		years += 1
		GameState.player["money"] = maxi(int(GameState.player["money"]), 50000)
		GameState.player["stats"]["health"] = 100.0
		if Lives.kind() == "vampire":
			Lives.life()["thirst"] = 0
			Lives.life()["starve"] = 0
		var t0 := Time.get_ticks_usec()
		EventEngine.age_up()
		_drain()
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		total_ms += ms
		worst = maxf(worst, ms)
		if years <= 30:
			first_ms += ms / 30.0
		if years > YEARS - 30:
			last_ms += ms / 30.0
	var t1 := Time.get_ticks_usec()
	SaveManager.save_game()
	var save_ms := float(Time.get_ticks_usec() - t1) / 1000.0
	var size := FileAccess.get_file_as_string(SaveManager.slot_path(SaveManager.current_slot)).length()
	var t2 := Time.get_ticks_usec()
	var loaded := SaveManager.load_slot(SaveManager.current_slot)
	var load_ms := float(Time.get_ticks_usec() - t2) / 1000.0
	if years < 150:
		failures.append("the ageless life ended after only %d years (%s)" % [years, str(GameState.player.get("cause", ""))])
	if first_ms > 0.0 and last_ms > first_ms * 4.0 + 20.0:
		failures.append("a year costs %.0f ms at the end against %.0f ms at the start" % [last_ms, first_ms])
	if total_ms / float(maxi(1, years)) > 250.0:
		failures.append("the average year takes %.0f ms" % (total_ms / float(years)))
	if size > 12 * 1024 * 1024:
		failures.append("the save is %.1f MB" % (size / 1048576.0))
	if save_ms > 1500.0 or load_ms > 1500.0:
		failures.append("saving takes %.0f ms and loading %.0f ms" % [save_ms, load_ms])
	if not loaded:
		failures.append("the long life would not reload")
	print("PERF TEST %d years  avg %.0f ms/yr (first 30: %.0f, last 30: %.0f, worst %.0f)  save %.2f MB (%.0f ms) load %.0f ms  npcs=%d  failures=%d" % [years, total_ms / float(maxi(1, years)), first_ms, last_ms, worst, size / 1048576.0, save_ms, load_ms, GameState.npcs.size(), failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)

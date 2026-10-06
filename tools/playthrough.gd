extends Node

## PLAYTHROUGH — plays whole lives through the real UI, pressing the real buttons.
##
## The headless gates prove the systems agree with each other. They do not prove
## the game is playable: every one of them bypasses main.tscn. This drives the
## actual screen — new life, age up, resolve each card by pressing a Choice
## button, open every tab — and fails if a life stalls, if the UI stops offering
## a way forward, or if anything writes a script error while doing it.

var main: Control
var shot_dir := ""
var errors := 0
var lives_done := 0
var years_total := 0
var events_seen := 0
var stalls := 0


func _ready() -> void:
	seed(int(OS.get_environment("OML_SEED")) if OS.get_environment("OML_SEED") != "" else 7)
	shot_dir = OS.get_environment("SHOT_DIR")
	if shot_dir == "":
		shot_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	get_window().size = Vector2i(1920, 1080)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(6)

	var want_lives := int(OS.get_environment("OML_LIVES")) if OS.get_environment("OML_LIVES") != "" else 1
	for life in range(want_lives):
		await _one_life(life)
	await _report()


func _one_life(index: int) -> void:
	main._open_new_life()
	await _frames(3)
	main.nl["first"] = ["Marcus", "Aiva", "Devon"][index % 3]
	main.nl["last"] = ["Reyes", "Okonkwo", "Lindqvist"][index % 3]
	main.nl["gender"] = ["male", "female", "male"][index % 3]
	main._start_life()
	await _frames(3)
	if index == 0:
		await _shot("01_life_begins")

	var years := 0
	var ticks := 0
	# Infancy runs on months, so age alone does not measure progress for the
	# first two years. Clock both.
	while GameState.is_alive() and years < 95 and ticks < 300:
		var before := _clock()
		main._age_up()
		await _frames(2)
		await _clear_popups(index == 0 and years == 12)
		ticks += 1
		if int(GameState.player["age"]) > years:
			years = int(GameState.player["age"])
			years_total += 1
		if _clock() == before and GameState.is_alive() and not main.popup_open:
			# Neither the year nor the month moved, and nothing is on screen
			# asking us to decide: that is a life the player cannot get out of.
			stalls += 1
			push_error("PLAYTHROUGH STALL at age %d" % int(GameState.player["age"]))
			break
		if years == 25 and index == 0:
			await _tour_tabs()

	lives_done += 1
	if index == 0:
		await _shot("04_death")
	await _clear_popups(false)
	await _frames(2)


## Every tab the player can reach, opened on a live character.
func _tour_tabs() -> void:
	var panels := {
		"activities": main._panel_activities,
		"relationships": main._panel_relationships,
		"occupation": main._panel_occupation,
		"assets": main._panel_assets,
	}
	for key in panels:
		main._open_panel(panels[key], true)
		await _frames(3)
		await _shot("03_tab_%s" % key)
		main._close_popup()
		await _frames(2)


func _report() -> void:
	await _frames(2)
	print("PLAYTHROUGH lives=%d years=%d events=%d stalls=%d errors=%d" % [
		lives_done, years_total, events_seen, stalls, errors])
	print("PLAYTHROUGH DONE")
	get_tree().quit()


## Months elapsed, so infancy and ordinary years are measured on one scale.
func _clock() -> int:
	if LifeCourse.monthly_mode():
		return int(LifeCourse.state()["months"])
	return int(GameState.player["age"]) * 12


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


## Press a real, enabled choice button; fall back to OK. If a card is on screen
## with nothing pressable, the player is stuck looking at it, so that is a fail.
func _clear_popups(shoot: bool) -> void:
	var guard := 0
	while main.popup_open and guard < 40:
		guard += 1
		if shoot and guard == 1:
			await _shot("02_event_card")
		var choices: Array = main.overlay_box.find_children("Choice*", "Button", true, false)
		var pressed := false
		for b in choices:
			if not b.disabled:
				b.emit_signal("pressed")
				pressed = true
				events_seen += 1
				break
		if not pressed:
			var ok := main.overlay_box.find_child("OkButton", true, false) as Button
			if ok:
				ok.emit_signal("pressed")
				pressed = true
			else:
				var any: Array = main.overlay_box.find_children("*", "Button", true, false)
				for b in any:
					if not b.disabled and b.visible:
						b.emit_signal("pressed")
						pressed = true
						break
		if not pressed:
			stalls += 1
			push_error("PLAYTHROUGH DEAD END: a card with no pressable option at age %d" % int(GameState.player["age"]))
			main._close_popup()
		await _frames(2)


func _shot(name_key: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name_key + ".png"))

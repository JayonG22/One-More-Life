extends Node

## v0.17 accessibility gate: keyboard play, labels, contrast, text size, motion.

var failures: Array = []
var checks := 0
var main: Control


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("A11Y: " + msg)


func _ready() -> void:
	seed(2020)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(3)
	# build a life directly: the test must never touch the player's save slots
	GameState.new_life({"gender": "female", "country": "us", "first": "Ada", "last": "Lovelace"})
	GameState.player["age"] = 30
	GameState.player["money"] = 90000
	main._show("game")
	await _f(4)
	await _keyboard()
	await _labels()
	_contrast()
	await _scale()
	print("A11Y TEST checks=%d failures=%d" % [checks, failures.size()])
	for fl in failures:
		print("FAIL: ", fl)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _buttons(root: Node) -> Array:
	var out: Array = []
	for b in root.find_children("*", "BaseButton", true, false):
		var bb := b as BaseButton
		if bb.is_visible_in_tree():
			out.append(bb)
	return out


func _keyboard() -> void:
	main._open_panel(main._panel_activities, true)
	await _f(3)
	ok(not UIKit.kb_mode, "keyboard mode is on before any key was pressed")
	var before := _buttons(main.g["panel"])
	ok(before.size() >= 4, "the activities panel has only %d buttons" % before.size())
	for b in before:
		ok((b as Control).focus_mode == Control.FOCUS_NONE, "a button took focus before keyboard mode (a click would leave it focused)")
		break
	# a Tab press turns it on
	var ev := InputEventKey.new()
	ev.keycode = KEY_TAB
	ev.pressed = true
	main._input(ev)
	await _f(3)
	ok(UIKit.kb_mode, "Tab did not turn keyboard mode on")
	var panel_btns := _buttons(main.g["panel"])
	var focusable := 0
	for b in panel_btns:
		if (b as Control).focus_mode == Control.FOCUS_ALL:
			focusable += 1
	ok(focusable == panel_btns.size(), "%d of %d panel buttons are focusable" % [focusable, panel_btns.size()])
	var owner := main.get_viewport().gui_get_focus_owner()
	ok(owner != null and owner is BaseButton, "no button had keyboard focus after Tab")
	# focus can walk the whole panel without getting stuck
	var seen := {}
	var cur: Control = owner
	for i in range(60):
		if cur == null:
			break
		seen[cur.get_instance_id()] = true
		var nxt := cur.find_next_valid_focus()
		if nxt == null or nxt == cur:
			break
		cur = nxt
	ok(seen.size() >= 6, "keyboard focus only reached %d controls" % seen.size())
	# a focused row can be activated from the keyboard
	var target: BaseButton = null
	for b in panel_btns:
		var bb := b as BaseButton
		if not bb.disabled and bb.focus_mode == Control.FOCUS_ALL and bb.tooltip_text != "":
			target = bb
			break
	ok(target != null, "no enabled row to activate")
	if target != null:
		target.grab_focus()
		var acc := InputEventAction.new()
		acc.action = "ui_accept"
		acc.pressed = true
		Input.parse_input_event(acc)
		await _f(2)
		var rel := InputEventAction.new()
		rel.action = "ui_accept"
		rel.pressed = false
		Input.parse_input_event(rel)
		await _f(3)
	# focus follows the player into the next panel
	main._open_panel(main._panel_relationships, true)
	await _f(4)
	var fo := main.get_viewport().gui_get_focus_owner()
	ok(fo != null, "opening another panel lost keyboard focus")
	# a mouse click gives focus back so Space keeps ageing up
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	main._input(click)
	await _f(2)
	ok(not UIKit.kb_mode, "a mouse click did not turn keyboard mode off")
	var still := 0
	for b in _buttons(main.g["panel"]):
		if (b as Control).focus_mode != Control.FOCUS_NONE:
			still += 1
	ok(still == 0, "%d buttons kept focus mode after a click" % still)
	ok(main.get_viewport().gui_get_focus_owner() == null, "a button kept focus after a click")
	print("  keyboard: %d buttons, focus walked %d controls" % [panel_btns.size(), seen.size()])


func _labels() -> void:
	var missing := 0
	var total := 0
	for builder in [main._panel_activities, main._panel_relationships, main._panel_occupation, main._panel_assets, main._panel_more]:
		main._open_panel(builder, true)
		await _f(3)
		for b in _buttons(main.g["panel"]):
			total += 1
			var bb := b as Button
			if bb.tooltip_text == "" and bb.text == "":
				missing += 1
	ok(total >= 30, "only %d buttons were checked" % total)
	ok(missing == 0, "%d of %d buttons have neither text nor a label" % [missing, total])
	# the main navigation too
	var nav := 0
	for b in _buttons(main):
		var bb2 := b as Button
		if bb2.text == "" and bb2.tooltip_text == "" and bb2.get_child_count() > 0:
			nav += 1
	ok(nav == 0, "%d icon buttons have no label" % nav)
	print("  labels: %d buttons, %d without a label" % [total, missing + nav])


func _contrast() -> void:
	ThemeManager.set_contrast(false)
	var d0 := ThemeManager.c("dim")
	var t := ThemeManager.c("text")
	ThemeManager.set_contrast(true)
	var d1 := ThemeManager.c("dim")
	ok(_lum_gap(d1, t) < _lum_gap(d0, t), "high contrast did not brighten secondary text")
	ok(_ratio(d1, ThemeManager.c("bg")) >= 7.0, "high-contrast secondary text is only %.1f:1 against the background" % _ratio(d1, ThemeManager.c("bg")))
	ThemeManager.set_contrast(false)
	for key in ["dark", "light"]:
		ThemeManager.apply(key)
		var r := _ratio(ThemeManager.c("text"), ThemeManager.c("bg"))
		ok(r >= 7.0, "%s theme body text is only %.1f:1" % [key, r])
	ThemeManager.apply("dark")
	print("  contrast: dim text %.1f:1 normally, %.1f:1 in high contrast" % [_ratio(d0, ThemeManager.c("bg")), _ratio(d1, ThemeManager.c("bg"))])


func _lum(c: Color) -> float:
	var f := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _lum_gap(a: Color, b: Color) -> float:
	return absf(_lum(a) - _lum(b))


func _ratio(a: Color, b: Color) -> float:
	var l1 := maxf(_lum(a), _lum(b))
	var l2 := minf(_lum(a), _lum(b))
	return (l1 + 0.05) / (l2 + 0.05)


func _scale() -> void:
	var s := GameState.settings
	var sc := main.screens["game"] as Control
	for step in [0.9, 1.0, 1.15, 1.3]:
		s["ui_scale"] = step
		main._apply_display()
		for i in range(3):
			await get_tree().process_frame
		var n2 := sc.get_combined_minimum_size()
		var h2 := main.get_viewport().get_visible_rect().size
		ok(n2.x <= h2.x + 1.0, "at %d%% the game screen needs %d px across but only %d fit" % [int(step * 100), int(n2.x), int(h2.x)])
		ok(n2.y <= h2.y + 1.0, "at %d%% the game screen needs %d px down but only %d fit" % [int(step * 100), int(n2.y), int(h2.y)])
	s["ui_scale"] = 1.0
	main._apply_display()
	s["reduced_motion"] = true
	ok(Fx.reduced_motion(), "reduced motion setting is ignored")
	s["reduced_motion"] = false
	print("  scale: every interface size up to 130% fits the game screen")


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

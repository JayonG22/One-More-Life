class_name UIKit
extends RefCounted

const STAT_ICONS := {"happiness": "😊", "health": "❤️", "smarts": "🧠", "looks": "✨", "stress": "☁️"}
const STAT_NAMES := {"happiness": "Happiness", "health": "Health", "smarts": "Smarts", "looks": "Looks", "stress": "Stress"}


static func lbl(text: String, variation: String = "", size: int = 0, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func btn(text: String, cb: Callable, variation: String = "", sound: String = "tap") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): UIKit._click(b, sound))
	b.pressed.connect(cb)
	return b


static func icon_btn(icon: String, text: String, cb: Callable, variation: String = "Row", vertical: bool = true, icon_size: int = 28, text_size: int = 16, sound: String = "tap") -> Button:
	var b := Button.new()
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.add_theme_constant_override("separation", sp(4) if vertical else sp(12))
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_child(box)
	var il := lbl(icon, "Emoji", icon_size)
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	il.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(il)
	var tl := lbl(text, "Bold", text_size)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if vertical else HORIZONTAL_ALIGNMENT_LEFT
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(tl)
	b.add_child(m)
	b.set_meta("icon", il)
	b.set_meta("label", tl)
	_ignore_all(b)
	b.pressed.connect(func(): UIKit._click(b, sound))
	b.pressed.connect(cb)
	return b


static func _click(b: Button, sound: String = "tap") -> void:
	if sound != "":
		Fx.play(sound)
	VFX.squish(b)


## ---------------------------------------------------------------- spacing
##
## Every gap in the game used to be whatever number was typed that afternoon:
## a census of the call sites found fifteen different separations (1, 2, 6, 10,
## 14, 18, 22...) and seventy-two different minimum sizes. Nothing was wrong
## with any single one of them, and together they meant the UI had no rhythm.
##
## One scale, on a 4px grid. Anything asking for a gap is snapped to the nearest
## step, so every existing call site lands on the scale without being rewritten,
## and anything new is on it by default.
const SP := [0, 4, 8, 12, 16, 24, 32, 48, 64]

## Row and control heights, also from the grid.
const ROW_H := 72
const ROW_H_TIGHT := 56
const BTN_H := 48
const BTN_H_BIG := 56
const GUTTER := 16
const TAP_MIN := 32


## Snap any gap to the scale. Ties round up, because cramped reads worse than airy.
static func sp(v: int) -> int:
	if v <= 0:
		return 0
	if v <= 4:
		return 4          # a 1px or 2px gap is a gap; it should not collapse
	if v >= 64:
		return v          # a deliberate large gap is a layout decision, left alone
	var best: int = SP[1]
	var best_d: int = 99999
	for step in SP:
		var d: int = absi(int(step) - v)
		if d < best_d or (d == best_d and int(step) > best):
			best = int(step)
			best_d = d
	return best


static func vb(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sp(sep))
	return v


static func hb(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sp(sep))
	return h


static func card(variation: String = "Card") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


static func spacer(vertical: bool = false) -> Control:
	var c := Control.new()
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func clear(node: Node) -> void:
	for ch in node.get_children():
		node.remove_child(ch)
		ch.queue_free()


static func bar(value: float, color: Color, height: int = 10, width: int = 0) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(width, height)
	if width == 0:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_bar_color(b, color)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Bars are a gradient rather than a flat block: darker at the base, brighter
## along the top, with a lighter lip. A flat rectangle reads as a placeholder.
static func set_bar_color(b: ProgressBar, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(8)
	s.bg_color = color.darkened(0.12)
	s.border_color = color.lightened(0.35)
	s.border_width_top = 2
	s.set_corner_radius_all(8)
	s.shadow_color = Color(color.r, color.g, color.b, 0.35)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 1)
	b.add_theme_stylebox_override("fill", s)


static func _ignore_all(n: Node) -> void:
	for ch in n.get_children():
		if ch is Control:
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_all(ch)


static func row(icon: String, title: String, sub: String, cb: Callable, enabled: bool = true, chevron: bool = true, extra: Control = null) -> Button:
	var b := Button.new()
	b.theme_type_variation = "Row"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 74 if sub != "" or extra != null else 58)
	b.disabled = not enabled
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	var h := hb(14)
	m.add_child(h)
	# An icon string prefixed with "@" is a drawn vector icon rather than an
	# emoji, so "@mansion" gets a mansion that looks like one.
	if icon.begins_with("@") and Icons.has(icon.substr(1)):
		var di := Icons.make(icon.substr(1), 38.0)
		var wrap := CenterContainer.new()
		wrap.custom_minimum_size = Vector2(44, 0)
		wrap.add_child(di)
		h.add_child(wrap)
	else:
		var ic := lbl(icon, "Emoji", 30)
		ic.custom_minimum_size = Vector2(44, 0)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(ic)
	var v := vb(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := lbl(title, "Bold", 19)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	if sub != "":
		var s := lbl(sub, "Dim")
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	if extra != null:
		v.add_child(extra)
	h.add_child(v)
	if chevron:
		var cv := lbl("›", "Dim", 30)
		cv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(cv)
	b.add_child(m)
	_ignore_all(b)
	if enabled:
		b.pressed.connect(func(): UIKit._click(b, "tap"))
		b.pressed.connect(cb)
	if not enabled:
		b.modulate = Color(1, 1, 1, 0.55)
	return b


static func section(text: String) -> Label:
	var l := lbl("▸ " + text, "Bold", 16)
	l.add_theme_color_override("font_color", ThemeManager.c("dim"))
	return l


static func face(gender: String, age: int, idx: int) -> String:
	if age < 3:
		return "👶"
	var tones := ["", "🏻", "🏽", "🏾", "🏿"]
	var t: String = tones[clampi(idx, 0, tones.size() - 1)]
	if age < 13:
		match gender:
			"male": return "👦" + t
			"female": return "👧" + t
			_: return "🧒" + t
	if age >= 65:
		match gender:
			"male": return "👴" + t
			"female": return "👵" + t
			_: return "🧓" + t
	match gender:
		"male": return "👨" + t
		"female": return "👩" + t
	return "🧑" + t


static func npc_face(n: Dictionary) -> String:
	match n.get("species", "human"):
		"dog": return "🐶"
		"cat": return "🐱"
		"rabbit": return "🐰"
		"parrot": return "🦜"
	if not n.get("alive", true):
		return "😇"
	return face(n.get("gender", "male"), int(n.get("age", 30)), int(n.get("face", 0)))


static func changes_bbcode(changes: Dictionary) -> String:
	var parts: Array = []
	var good := ThemeManager.c("good").to_html(false)
	var bad := ThemeManager.c("bad").to_html(false)
	for k in ["happiness", "health", "smarts", "looks", "stress", "money"]:
		if not changes.has(k):
			continue
		var v: int = int(changes[k])
		if v == 0:
			continue
		var positive := v > 0
		if k == "stress":
			positive = not positive
		var col := good if positive else bad
		var txt := ""
		if k == "money":
			txt = "💵 Money %s%s" % ["+" if v > 0 else "", GameState.fmt_money(v)]
		else:
			txt = "%s %s %s%d" % [STAT_ICONS[k], STAT_NAMES[k], "+" if v > 0 else "", v]
		parts.append("[color=#%s]%s[/color]" % [col, txt])
	return "    ".join(parts)


## A labelled progress track: icon, name, bar, and the number, in one row. Used
## for anything the player is working through — fame, a career skill, a rank —
## so progress is visible on the main screen instead of inside a sub-menu.
static func track(icon: String, name: String, value: float, of: float, color: Color, right: String = "") -> HBoxContainer:
	var r := hb(8)
	var ic := lbl(icon, "Emoji", 18)
	ic.custom_minimum_size = Vector2(26, 0)
	r.add_child(ic)
	var l := lbl(name, "Dim", 15)
	l.custom_minimum_size = Vector2(104, 0)
	r.add_child(l)
	var pb := bar(clampf(value / maxf(1.0, of) * 100.0, 0.0, 100.0), color, 14)
	r.add_child(pb)
	var rl := lbl(right if right != "" else "%d" % int(round(value)), "Bold", 14)
	rl.custom_minimum_size = Vector2(62, 0)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r.add_child(rl)
	return r

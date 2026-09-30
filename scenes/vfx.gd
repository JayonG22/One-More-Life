class_name VFX
extends Node

## Visual effects drawn with code: particles, shakes, flashes, floating numbers.

const CONFETTI := ["🎉", "🎊", "✨", "⭐", "🎈"]
const HEARTS := ["❤️", "💕", "💖", "💘"]
const COINS := ["💵", "💰", "🪙", "💸"]
const SPARKS := ["⭐", "✨", "🌟", "💫"]
const GRIEF := ["🕯️", "🥀", "🤍"]
const MAGIC := ["🔮", "✨", "🌙", "⭐", "🪄"]
const BLOOD := ["🩸", "🦇", "🥀"]
const ROYAL := ["👑", "💎", "✨", "🌹"]


static func _on() -> bool:
	return Fx.effects_on()


static func _motion() -> bool:
	return not Fx.reduced_motion()


## Springy pop-in for cards and popups.
static func pop_in(node: Control, scale_from: float = 0.86, time: float = 0.28) -> void:
	if not is_instance_valid(node) or not _motion():
		return
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(scale_from, scale_from)
	node.modulate.a = 0.0
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "scale", Vector2.ONE, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "modulate:a", 1.0, time * 0.6)


## Quick squish when a button is pressed.
static func squish(node: Control) -> void:
	if not is_instance_valid(node) or not _motion():
		return
	node.pivot_offset = node.size / 2.0
	var t := node.create_tween()
	t.tween_property(node, "scale", Vector2(0.95, 0.94), 0.06).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Slide a row in from the side.
static func slide_in(node: Control, delay: float = 0.0, from_x: float = 26.0) -> void:
	if not is_instance_valid(node) or not _motion():
		return
	node.modulate.a = 0.0
	node.position.x += from_x
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, 0.22).set_delay(delay)
	t.tween_property(node, "position:x", node.position.x - from_x, 0.26).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func fade_in(node: Control, delay: float = 0.0) -> void:
	if not is_instance_valid(node) or not _motion():
		return
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, 0.25).set_delay(delay)


## Gentle looping pulse, used on the Age button when events are waiting.
static func pulse(node: Control, on: bool) -> void:
	if not is_instance_valid(node):
		return
	if node.has_meta("pulse_tween"):
		var old = node.get_meta("pulse_tween")
		if old is Tween and old.is_valid():
			old.kill()
		node.remove_meta("pulse_tween")
		node.scale = Vector2.ONE
	if not on or not _motion():
		return
	node.pivot_offset = node.size / 2.0
	var t := node.create_tween().set_loops()
	t.tween_property(node, "scale", Vector2(1.045, 1.045), 0.75).set_trans(Tween.TRANS_SINE)
	t.tween_property(node, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE)
	node.set_meta("pulse_tween", t)


## Animate a progress bar to a new value and flash its fill.
static func bar_to(bar: ProgressBar, value: float, color: Color, flash: bool) -> void:
	if not is_instance_valid(bar):
		return
	if not _motion():
		bar.value = value
		UIKit.set_bar_color(bar, color)
		return
	bar.create_tween().tween_property(bar, "value", value, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if flash:
		UIKit.set_bar_color(bar, color.lightened(0.45))
		var t := bar.create_tween()
		t.tween_interval(0.18)
		t.tween_callback(func(): UIKit.set_bar_color(bar, color))
	else:
		UIKit.set_bar_color(bar, color)


## A "+6" / "-4" that floats up and fades.
static func float_number(parent: Control, anchor: Control, text: String, color: Color) -> void:
	if not is_instance_valid(parent) or not is_instance_valid(anchor) or not _on():
		return
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", ThemeManager.font_bold)
	l.add_theme_font_size_override("font_size", 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 90
	parent.add_child(l)
	var gp := anchor.get_global_rect()
	var x: float = gp.end.x + 8.0
	if x > parent.size.x - 90.0:
		x = gp.position.x - 74.0
	l.global_position = Vector2(maxf(4.0, x), gp.position.y + 2.0)
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l, "global_position:y", l.global_position.y - 34, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.85)
	t.chain().tween_callback(l.queue_free)


## Count a money label up or down.
static func roll_money(label: Label, from_v: int, to_v: int) -> void:
	if not is_instance_valid(label):
		return
	if not _motion() or from_v == to_v:
		label.text = GameState.fmt_money(to_v)
		return
	var t := label.create_tween()
	t.tween_method(func(v: float): label.text = GameState.fmt_money(int(v)), float(from_v), float(to_v), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Emoji burst from the top of the screen or a point.
static func burst(layer: Control, kind: String, amount: int = 18) -> void:
	if not is_instance_valid(layer) or not _on() or not _motion():
		return
	var set_list: Array = CONFETTI
	match kind:
		"hearts": set_list = HEARTS
		"coins": set_list = COINS
		"sparks": set_list = SPARKS
		"magic": set_list = MAGIC
		"blood": set_list = BLOOD
		"royal": set_list = ROYAL
		"grief": set_list = GRIEF
	var w := layer.size.x
	for i in range(amount):
		var l := Label.new()
		l.text = set_list[randi() % set_list.size()]
		l.add_theme_font_size_override("font_size", randi_range(20, 40))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.z_index = 95
		layer.add_child(l)
		var start := Vector2(randf_range(w * 0.1, w * 0.9), randf_range(-80.0, -10.0))
		l.position = start
		var drift := randf_range(-90.0, 90.0)
		var dur := randf_range(1.4, 2.6)
		var t := l.create_tween().set_parallel(true)
		t.tween_property(l, "position:y", layer.size.y + 60, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(l, "position:x", start.x + drift, dur)
		t.tween_property(l, "rotation", randf_range(-4.0, 4.0), dur)
		t.tween_property(l, "modulate:a", 0.0, dur).set_delay(dur * 0.55)
		t.chain().tween_callback(l.queue_free)


## Emoji that rise from the bottom (hearts, sparks).
static func rise(layer: Control, kind: String, amount: int = 12) -> void:
	if not is_instance_valid(layer) or not _on() or not _motion():
		return
	var set_list: Array = HEARTS if kind == "hearts" else SPARKS
	for i in range(amount):
		var l := Label.new()
		l.text = set_list[randi() % set_list.size()]
		l.add_theme_font_size_override("font_size", randi_range(18, 34))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.z_index = 95
		layer.add_child(l)
		var start := Vector2(randf_range(layer.size.x * 0.2, layer.size.x * 0.8), layer.size.y + 20)
		l.position = start
		var dur := randf_range(1.6, 2.6)
		var t := l.create_tween().set_parallel(true)
		t.tween_property(l, "position:y", -60.0, dur).set_trans(Tween.TRANS_SINE)
		t.tween_property(l, "position:x", start.x + randf_range(-60, 60), dur)
		t.tween_property(l, "modulate:a", 0.0, dur).set_delay(dur * 0.5)
		t.chain().tween_callback(l.queue_free)


## Full-screen color flash.
static func flash(layer: Control, color: Color, strength: float = 0.35, time: float = 0.45) -> void:
	if not is_instance_valid(layer) or not Fx.flashes_on():
		return
	var r := ColorRect.new()
	r.color = Color(color, strength)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.z_index = 80
	layer.add_child(r)
	var t := r.create_tween()
	t.tween_property(r, "color:a", 0.0, time).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(r.queue_free)


## Shake the whole screen.
static func shake(root: Control, strength: float = 10.0, time: float = 0.35) -> void:
	if not is_instance_valid(root) or not Fx.shake_on() or not _motion():
		return
	var base := root.position
	var t := root.create_tween()
	var steps := int(time / 0.04)
	for i in range(steps):
		var falloff := 1.0 - float(i) / float(steps)
		t.tween_property(root, "position", base + Vector2(randf_range(-strength, strength), randf_range(-strength, strength)) * falloff, 0.04)
	t.tween_property(root, "position", base, 0.05)


## Slow desaturating fade used on death.
static func death_fade(layer: Control) -> void:
	if not is_instance_valid(layer) or not _on():
		return
	var r := ColorRect.new()
	r.color = Color(0.05, 0.05, 0.07, 0.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.z_index = 85
	layer.add_child(r)
	var t := r.create_tween()
	t.tween_property(r, "color:a", 0.75, 0.9)
	t.tween_property(r, "color:a", 0.0, 0.7)
	t.tween_callback(r.queue_free)

## The age button. A year passing is the single most repeated action in the game,
## so it gets a real beat: the button dips, springs past its own size, and a ring
## expands out of it.
static func age_press(btn: Control, layer: Control) -> void:
	if not is_instance_valid(btn) or not _on():
		return
	if not _motion():
		return
	btn.pivot_offset = btn.size * 0.5
	var t := btn.create_tween()
	t.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.07).set_trans(Tween.TRANS_QUAD)
	t.tween_property(btn, "scale", Vector2(1.10, 1.10), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if not is_instance_valid(layer):
		return
	var ring := _Ring.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 90
	ring.col = ThemeManager.c("accent")
	layer.add_child(ring)
	ring.position = btn.get_global_rect().get_center() - layer.get_global_rect().position
	var rt := ring.create_tween().set_parallel(true)
	rt.tween_property(ring, "r", 150.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring, "modulate:a", 0.0, 0.55)
	rt.chain().tween_callback(ring.queue_free)


## A ring drawn rather than faked with a texture, so it scales cleanly.
class _Ring extends Control:
	var r := 20.0
	var col := Color.WHITE

	func _init() -> void:
		size = Vector2.ZERO

	func _draw() -> void:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col, 0.55), maxf(1.5, 7.0 - r / 30.0), true)

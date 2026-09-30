class_name Minigame
extends Control

## Base class for every career minigame. Subclasses build their UI in build()
## and call finish(score) exactly once, with score between 0 and 1.

signal finished(score: float, detail: Dictionary)

const W := 1000.0
const H := 540.0

var params: Dictionary = {}
var difficulty := 1.0
var done := false
var elapsed := 0.0
var status: Label


## How hard the timing windows are, independent of how hard the CONTENT is.
## Minigames should be a break in the reading, not a stress test, so the default
## is the relaxed pace and the player can tighten it if they want the pressure.
const PACE := {
	"relaxed": {"name": "Relaxed", "icon": "🌊", "desc": "Wider timing windows. The default.", "mult": 0.72},
	"standard": {"name": "Standard", "icon": "⏱️", "desc": "The original pacing.", "mult": 1.0},
	"brisk": {"name": "Brisk", "icon": "⚡", "desc": "Tighter windows for a real test.", "mult": 1.22},
}


static func pace_mult() -> float:
	var key := str(GameState.settings.get("mg_pace", "relaxed"))
	return float(PACE.get(key, PACE["relaxed"])["mult"])


func setup(p: Dictionary) -> void:
	params = p
	difficulty = clampf(float(p.get("difficulty", 1.0)) * pace_mult(), 0.45, 1.6)


func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	build()
	grab_focus()


func build() -> void:
	pass


func finish(score: float, detail: Dictionary = {}) -> void:
	if done:
		return
	done = true
	set_process(false)
	finished.emit(clampf(score, 0.0, 1.0), detail)


func key_pressed(event: InputEvent, keys: Array) -> bool:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	return keys.has(event.keycode)


func key_released(event: InputEvent, keys: Array) -> bool:
	if not (event is InputEventKey) or event.pressed:
		return false
	return keys.has(event.keycode)


func col(key: String) -> Color:
	return ThemeManager.c(key)


func label(text: String, size_px: int = 18, bold: bool = false, color: Color = Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	if bold:
		l.add_theme_font_override("font", ThemeManager.font_bold)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func place(node: Control, pos: Vector2, sz: Vector2 = Vector2.ZERO) -> Control:
	add_child(node)
	node.position = pos
	if sz != Vector2.ZERO:
		node.size = sz
		node.custom_minimum_size = sz
	return node


func button(text: String, cb: Callable, variation: String = "Primary") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func make_status(pos: Vector2 = Vector2(0, 8)) -> void:
	status = label("", 20, true)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(status, pos, Vector2(W, 30))


func bar_rect(rect: Rect2, value: float, fill: Color, bg: Color) -> void:
	draw_rect(rect, bg)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0, 1), rect.size.y)), fill)


func flash_text(text: String, color: Color, pos: Vector2, size_px: int = 34) -> void:
	var l := label(text, size_px, true, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(l, pos - Vector2(200, 0), Vector2(400, 50))
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 40, 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7)
	t.chain().tween_callback(l.queue_free)

class_name AvatarView
extends Control

## The player's portrait: the age-and-gender emoji the game has always used, on a coloured
## backdrop, with the optional parts (hair, headwear, eyewear, an extra) laid over it.
## Leave every option on its first setting and you get the plain template.

var av: Dictionary = {}
var age := 25
var gender := "male"
var _face: Label
var _hat: Label
var _eyes: Label
var _extra: Label


func setup(a: Dictionary, years: int, gen: String) -> void:
	av = a
	age = years
	gender = gen
	_build()
	_layout()
	queue_redraw()


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 144)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	resized.connect(_layout)


func _mk() -> Label:
	var l := Label.new()
	l.theme_type_variation = "Emoji"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _build() -> void:
	if _face == null:
		_face = _mk()
		_eyes = _mk()
		_hat = _mk()
		_extra = _mk()
	if av.is_empty():
		return
	_face.text = Avatar.face_emoji(av, age, gender)
	var baby := age < 3
	_hat.text = "" if baby else Avatar.glyph_of("hat", int(av.get("hat", 0)))
	_eyes.text = "" if baby or age < 3 else Avatar.glyph_of("glasses", int(av.get("glasses", 0)))
	_extra.text = Avatar.glyph_of("extra", int(av.get("extra", 0)))


func _place(l: Label, fs: int, cx: float, cy: float, s: float) -> void:
	l.add_theme_font_size_override("font_size", fs)
	l.size = Vector2(s, s)
	l.position = Vector2(cx - s / 2.0, cy - s / 2.0)


func _layout() -> void:
	if _face == null:
		return
	var s := minf(size.x, size.y * 0.95)
	var cx := size.x / 2.0
	var cy := size.y * 0.55
	_place(_face, int(s * 0.58), cx, cy, s)
	# a child's face sits a little smaller than an adult's
	if age < 13:
		_face.add_theme_font_size_override("font_size", int(s * (0.5 if age >= 3 else 0.46)))
	_place(_hat, int(s * 0.34), cx, cy - s * 0.30, s * 0.5)
	_place(_eyes, int(s * 0.27), cx, cy - s * 0.02, s * 0.5)
	_place(_extra, int(s * 0.27), cx + s * 0.30, cy + s * 0.30, s * 0.4)


func _draw() -> void:
	if av.is_empty():
		return
	var col := Avatar.color_of("bg", int(av.get("bg", 0)))
	var r := minf(size.x, size.y) * 0.5
	var c := Vector2(size.x / 2.0, size.y * 0.55)
	r = minf(r * 0.98, minf(c.y, size.y - c.y) + r * 0.2)
	draw_circle(c, r, col)
	draw_arc(c, r, 0.0, TAU, 48, col.lightened(0.35), maxf(2.0, r * 0.04), true)

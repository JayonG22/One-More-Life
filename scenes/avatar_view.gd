class_name AvatarView
extends Control

## The player's portrait: one real emoji (the age-and-gender face the game has always
## used, or the look the player picked) on a coloured round backdrop.

var av: Dictionary = {}
var age := 25
var gender := "male"
var _face: Label


func setup(a: Dictionary, years: int, gen: String) -> void:
	av = a
	age = years
	gender = gen
	_build()
	queue_redraw()


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	resized.connect(_fit)


func _build() -> void:
	if _face == null:
		_face = Label.new()
		_face.theme_type_variation = "Emoji"
		_face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_face)
	var t := Avatar.face_emoji(av, age, gender) if not av.is_empty() else UIKit.face(gender, age, 0)
	_face.text = t if t != "" else UIKit.face(gender, age, 0)
	_fit()


func _fit() -> void:
	if _face == null:
		return
	var d := minf(size.x, size.y)
	if d <= 1.0:
		d = minf(custom_minimum_size.x, custom_minimum_size.y)
	_face.add_theme_font_size_override("font_size", maxi(12, int(d * 0.56)))
	queue_redraw()


func _draw() -> void:
	var col := Avatar.color_of("bg", int(av.get("bg", 0))) if not av.is_empty() else Color("#27324a")
	var d := minf(size.x, size.y)
	var c := size / 2.0
	draw_circle(c, d * 0.49, col)
	draw_arc(c, d * 0.49, 0.0, TAU, 48, col.lightened(0.35), maxf(2.0, d * 0.035), true)

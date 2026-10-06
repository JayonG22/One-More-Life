class_name AvatarView
extends Control
const OriginalArt=preload("res://scenes/original_portraits.gd")
var av: Dictionary={}
var age := 25
var gender := "male"
var living := false
var person: Dictionary={}
var expression := "steady"
var _badge: Label
var _face: Label
var _features: TextureRect
func setup(a: Dictionary, years: int, gen: String, life_status: bool = false, subject: Dictionary = {}) -> void:
	av=Avatar.sanitize(a); age=years; gender=gen; living=life_status; person=subject
	refresh_expression(); _build(); queue_redraw()
func refresh_expression() -> void:
	expression=Avatar.face_state(person) if not person.is_empty() else Avatar.face_state(GameState.player) if living else "steady"
	if living and person.is_empty() and Journey.modules["identity"].st()["pose"]=="neutral": expression="neutral"
	tooltip_text={"unwell":"Feeling unwell","strain":"Under strain","low":"Feeling low","tired":"Worn out","happy":"In good spirits","steady":"Steady","neutral":"Neutral","remembered":"Remembered"}[expression]
	if _face!=null: _update_features()
func _ready() -> void:
	if custom_minimum_size==Vector2.ZERO: custom_minimum_size=Vector2(120,120)
	mouse_filter=Control.MOUSE_FILTER_PASS
	_build(); resized.connect(_fit)
func _build() -> void:
	if _face==null:
		_face=Label.new(); _face.name="OriginalFace"; _face.theme_type_variation="Emoji"
		_face.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; _face.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		_face.mouse_filter=Control.MOUSE_FILTER_IGNORE; _face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(_face)
	_face.text=Avatar.face_emoji(av,age,gender)
	if _features==null:
		_features=TextureRect.new(); _features.name="OriginalFeatures"
		_features.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_features.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		_features.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; add_child(_features)
	_update_features()
	if _badge==null:
		_badge=Label.new(); _badge.theme_type_variation="Emoji"; _badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; _badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; add_child(_badge)
	_badge.text=Avatar.glyph_of("badge",int(av.get("badge",0)))
	_fit()
func _update_features() -> void:
	if _features==null: return
	_features.texture=OriginalArt.texture(av,age,gender,expression)
	_features.visible=_features.texture!=null; _face.visible=not _features.visible
func _fit() -> void:
	var d := minf(size.x,size.y)
	if d<=1: d=minf(custom_minimum_size.x,custom_minimum_size.y)
	if _face!=null: _face.add_theme_font_size_override("font_size",maxi(12,int(d*0.56)))
	if _features!=null:
		# Match the visible glyph bounds and its font baseline, not the SVG canvas.
		_features.size=Vector2.ONE*d*0.64
		_features.position=(size-_features.size)/2.0-Vector2(0,d*0.035)
	if _badge!=null:
		_badge.position=Vector2(size.x*0.65,size.y*0.66); _badge.size=Vector2(d*0.29,d*0.29)
		_badge.add_theme_font_size_override("font_size",maxi(10,int(d*0.18)))
	queue_redraw()
func _draw() -> void:
	var d := minf(size.x,size.y); var center := size/2.0
	draw_circle(center,d*0.49,Avatar.color_of("bg",int(av.get("bg",0))))
	draw_arc(center,d*0.49,0,TAU,48,Avatar.color_of("frame",int(av.get("frame",0))) if int(av.get("frame",0))>0 else ThemeManager.c("border"),maxf(2,d*0.035),true)

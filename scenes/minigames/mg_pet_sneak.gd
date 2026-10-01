extends Minigame

## STEALTH. Creep to the food while the human is looking the other way. Hold
## Space to creep; let go to freeze. When the human starts to turn there is a
## warning beat (a ❓) before they look. Be still by then, and they see nothing.
## Three slips and you are caught.

const GOAL := 100.0
const LIVES := 3
const TIME := 38.0

var progress := 0.0
var creeping := false
var looking := false
var warn := false
var phase_t := 2.0
var lives_left := LIVES
var time_left := TIME
var watcher_l: Label
var pet_l: Label
var food_l: Label
var hint_l: Label
var sp_icon := "🐕"
var grace := 0.0


func build() -> void:
	sp_icon = str(Pets.SPECIES.get(str(params.get("species", "dog")), Pets.SPECIES["dog"])["icon"])
	make_status()
	watcher_l = label("🧑", 100)
	watcher_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(watcher_l, Vector2(W - 260, 100), Vector2(200, 120))
	food_l = label(str(params.get("food", "🍗")), 70)
	place(food_l, Vector2(W - 140, 360), Vector2(90, 90))
	pet_l = label(sp_icon, 64)
	place(pet_l, Vector2(80, 360), Vector2(90, 80))
	hint_l = label("", 21, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(40, 46), Vector2(W - 80, 60))
	var b := button("Hold to creep  [Space]", func(): pass, "Accent")
	b.button_down.connect(func(): creeping = true)
	b.button_up.connect(func(): creeping = false)
	place(b, Vector2(W / 2 - 190, 462), Vector2(380, 62))
	var legend := label("Hold Space to creep, let go to freeze. When ❓ appears, freeze. When the eyes are open (👀), stay frozen.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 520), Vector2(W, 20))
	_turn_away()


func _turn_away() -> void:
	looking = false
	warn = false
	phase_t = randf_range(1.8, 3.2) / difficulty
	watcher_l.text = "🧑‍🍳"
	hint_l.text = "They're busy. Creep!"


func _warning() -> void:
	warn = true
	phase_t = 0.75 / difficulty
	watcher_l.text = "❓"
	hint_l.text = "FREEZE. They're about to turn."


func _look() -> void:
	looking = true
	warn = false
	phase_t = randf_range(1.2, 2.0)
	watcher_l.text = "👀"
	hint_l.text = "They're looking. Don't move."


func _slip() -> void:
	lives_left -= 1
	grace = 1.0
	Fx.play("bad")
	flash_text("Spotted!", col("bad"), Vector2(W / 2, 200), 40)
	progress = maxf(0.0, progress - 14.0)
	if lives_left <= 0:
		finish(0.15 * progress / GOAL, {"caught": true})


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	grace = maxf(0.0, grace - delta)
	phase_t -= delta
	if phase_t <= 0.0:
		if looking:
			_turn_away()
		elif warn:
			_look()
		else:
			_warning()
	if creeping:
		if looking and grace <= 0.0:
			_slip()
		else:
			progress = minf(GOAL, progress + 20.0 * delta * (0.8 if warn else 1.0))
	pet_l.position.x = 80.0 + (W - 300.0) * progress / GOAL
	status.text = "Lives %s  ·  %d s" % ["❤️".repeat(maxi(0, lives_left)) + "🤍".repeat(LIVES - maxi(0, lives_left)), int(maxf(0.0, time_left))]
	if progress >= GOAL:
		finish(0.62 + 0.38 * float(lives_left) / float(LIVES), {"caught": false, "lives": lives_left})
	elif time_left <= 0.0:
		finish(0.5 * progress / GOAL, {"out_of_time": true})
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(80, 300, W - 160, 8), col("track"))
	bar_rect(Rect2(80, 300, W - 160, 8), progress / GOAL, col("good"), col("track"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and [KEY_SPACE, KEY_W, KEY_UP, KEY_D, KEY_RIGHT].has(event.keycode):
		creeping = event.pressed
		get_viewport().set_input_as_handled()

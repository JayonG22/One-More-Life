extends Minigame

## HERDING. Five sheep, one pen. Sheep step away from you when you get close, so
## the trick is to stand on the far side of a sheep and let it walk to the pen.
## Move with the arrow keys or WASD. A sheep that reaches the pen stays there.

const SHEEP := 5
const TIME := 42.0
const PEN := Rect2(790, 170, 170, 200)
const SPEED := 280.0

var dog := Vector2(120, 270)
var sheep: Array = []
var time_left := TIME
var dog_l: Label
var hint_l: Label
var sp_icon := "🐕"
var bot_move := Vector2.ZERO     # the test bot steers through this


func build() -> void:
	sp_icon = str(Pets.SPECIES.get(str(params.get("species", "dog")), Pets.SPECIES["dog"])["icon"])
	make_status()
	hint_l = label("Get behind a sheep, so it runs toward the pen on the right.", 20, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(0, 46), Vector2(W, 30))
	for i in range(SHEEP):
		var l := label("🐑", 44)
		place(l, Vector2(0, 0), Vector2(56, 56))
		sheep.append({"p": Vector2(randf_range(300, 640), randf_range(130, 440)), "penned": false, "n": l, "w": randf() * 6.0})
	dog_l = label(sp_icon, 52)
	place(dog_l, Vector2(0, 0), Vector2(60, 60))
	var legend := label("Arrow keys / WASD to move. Sheep step away from you: stand on the side away from the pen.", 15, true)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend, Vector2(0, 514), Vector2(W, 22))


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): v.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): v.y += 1
	if bot_move != Vector2.ZERO:
		v = bot_move
	if v != Vector2.ZERO:
		dog += v.normalized() * SPEED * delta
	dog.x = clampf(dog.x, 20.0, W - 40.0)
	dog.y = clampf(dog.y, 100.0, H - 60.0)
	dog_l.position = dog - Vector2(30, 30)
	var in_pen := 0
	for s in sheep:
		if s["penned"]:
			in_pen += 1
			continue
		var p: Vector2 = s["p"]
		var d := p - dog
		var dist := d.length()
		if dist < 150.0 and dist > 0.1:
			p += d.normalized() * (150.0 - dist) * 1.7 * delta + d.normalized() * 30.0 * delta
		else:
			s["w"] = float(s["w"]) + delta
			p += Vector2(cos(float(s["w"]) * 0.8), sin(float(s["w"]) * 1.1)) * 12.0 * delta
		# sheep do not like to be pinned in a corner: they drift back into the open
		if p.x < 110.0: p.x += 70.0 * delta
		if p.y < 150.0: p.y += 70.0 * delta
		if p.y > H - 120.0: p.y -= 70.0 * delta
		p.x = clampf(p.x, 40.0, W - 70.0)
		p.y = clampf(p.y, 100.0, H - 70.0)
		s["p"] = p
		if PEN.has_point(p):
			s["penned"] = true
			in_pen += 1
			Fx.play("tap")
		(s["n"] as Label).position = p - Vector2(28, 28)
	status.text = "Penned %d of %d  ·  %d s" % [in_pen, SHEEP, int(maxf(0.0, time_left))]
	if in_pen >= SHEEP:
		finish(0.65 + 0.35 * clampf(time_left / TIME, 0.0, 1.0), {"penned": in_pen})
	elif time_left <= 0.0:
		finish(0.6 * float(in_pen) / float(SHEEP), {"penned": in_pen, "out_of_time": true})
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 90, W, H - 90), Color(col("good"), 0.07))
	draw_rect(PEN, Color(col("warn"), 0.12))
	draw_rect(PEN, col("warn"), false, 3.0)
	draw_string(ThemeManager.font_bold, Vector2(PEN.position.x + 56, PEN.position.y - 8), "PEN", HORIZONTAL_ALIGNMENT_LEFT, 80, 22, col("warn"))

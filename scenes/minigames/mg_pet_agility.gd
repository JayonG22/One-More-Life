extends Minigame

## AGILITY. Ten obstacles come down the course. A hurdle needs a jump (↑ / W /
## Space); a tunnel needs a duck (↓ / S). Each obstacle is labelled with its key.
## Press while it is inside the glowing box. The box is wide: this is a game of
## reading, not of twitching.

const COUNT := 10
const SPEED := 230.0
const DOG_X := 220.0
const WINDOW := 80.0

var obs: Array = []
var spawned := 0
var clock := 0.0
var cleared := 0
var faults := 0
var dog_l: Label
var hint_l: Label
var jump_t := 0.0
var duck_t := 0.0
var show_mode := false


func build() -> void:
	show_mode = bool(params.get("show", false))
	make_status()
	dog_l = label(str(Pets.SPECIES.get(str(params.get("species", "dog")), Pets.SPECIES["dog"])["icon"]), 70)
	place(dog_l, Vector2(DOG_X - 36, 300), Vector2(90, 80))
	hint_l = label("↑ / W / Space: jump the hurdle    ↓ / S: duck through the tunnel", 20, true)
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(hint_l, Vector2(0, 52), Vector2(W, 30))
	var bj := button("⤴ Jump  [W]", _act.bind("jump"), "Primary")
	place(bj, Vector2(W / 2 - 260, 450), Vector2(240, 62))
	var bd := button("⤵ Duck  [S]", _act.bind("duck"), "Primary")
	place(bd, Vector2(W / 2 + 20, 450), Vector2(240, 62))
	for i in range(COUNT):
		var jump := randf() < 0.55
		obs.append({"x": W + 140.0 + i * (330.0 / difficulty), "kind": "jump" if jump else "duck", "done": false})


func _act(kind: String) -> void:
	if done:
		return
	if kind == "jump":
		jump_t = 0.35
	else:
		duck_t = 0.35
	for o in obs:
		if o["done"]:
			continue
		if absf(float(o["x"]) - DOG_X) <= WINDOW * (1.0 / difficulty * 0.9):
			o["done"] = true
			if o["kind"] == kind:
				cleared += 1
				Fx.play("tap")
				flash_text("Clear!", col("good"), Vector2(DOG_X + 120, 240), 28)
			else:
				faults += 1
				Fx.play("bad", 0.05)
				flash_text("Wrong move", col("bad"), Vector2(DOG_X + 120, 240), 26)
			return


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	jump_t = maxf(0.0, jump_t - delta)
	duck_t = maxf(0.0, duck_t - delta)
	dog_l.position.y = 300.0 - (90.0 if jump_t > 0.0 else 0.0) + (30.0 if duck_t > 0.0 else 0.0)
	var live := 0
	for o in obs:
		o["x"] = float(o["x"]) - SPEED * delta
		if not o["done"] and float(o["x"]) < DOG_X - WINDOW * 1.2:
			o["done"] = true
			faults += 1
			flash_text("Missed", col("warn"), Vector2(DOG_X + 120, 240), 26)
			Fx.play("bad", 0.05)
		if not o["done"]:
			live += 1
	var all_done := true
	for o2 in obs:
		if float(o2["x"]) > DOG_X - WINDOW * 1.2 and not o2["done"]:
			all_done = false
	status.text = "Cleared %d of %d  ·  faults %d" % [cleared, COUNT, faults]
	var pending := 0
	for o3 in obs:
		if not o3["done"]:
			pending += 1
	if pending == 0:
		finish(clampf(float(cleared) / float(COUNT) - 0.02 * faults, 0.0, 1.0), {"cleared": cleared, "faults": faults, "show": show_mode})
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 380, W, 4), col("border"))
	draw_rect(Rect2(DOG_X - WINDOW, 150, WINDOW * 2.0, 240), Color(col("good"), 0.15))
	draw_rect(Rect2(DOG_X - WINDOW, 150, WINDOW * 2.0, 240), col("good"), false, 2.0)
	var f: Font = ThemeManager.font_bold
	for o in obs:
		if o["done"] or float(o["x"]) > W + 40.0:
			continue
		var x := float(o["x"])
		if o["kind"] == "jump":
			draw_rect(Rect2(x - 28, 330, 8, 54), col("text"))
			draw_rect(Rect2(x + 20, 330, 8, 54), col("text"))
			draw_rect(Rect2(x - 28, 330, 56, 8), col("warn"))
			draw_string(f, Vector2(x - 28, 310), "JUMP ↑", HORIZONTAL_ALIGNMENT_LEFT, 80, 20, col("warn"))
		else:
			draw_rect(Rect2(x - 36, 320, 72, 64), col("primary"))
			draw_rect(Rect2(x - 20, 340, 40, 44), col("bg") if ThemeManager.has_method("c") else Color.BLACK)
			draw_string(f, Vector2(x - 36, 308), "DUCK ↓", HORIZONTAL_ALIGNMENT_LEFT, 90, 20, col("primary"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_W, KEY_UP, KEY_SPACE]):
		_act("jump")
		get_viewport().set_input_as_handled()
	elif key_pressed(event, [KEY_S, KEY_DOWN]):
		_act("duck")
		get_viewport().set_input_as_handled()

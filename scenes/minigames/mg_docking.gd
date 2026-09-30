extends Minigame

const LIMIT := 40.0
const SAFE := 45.0
const ACCEL := 70.0
const PORT := Rect2(860, 235, 70, 70)

var p := Vector2(120, 270)
var v := Vector2.ZERO
var fuel := 100.0
var time_left := LIMIT
var thrust := Vector2.ZERO
var held := {}
var ship: Label
var stars: Array = []


func build() -> void:
	make_status()
	for i in range(70):
		stars.append(Vector2(randf() * W, randf() * H))
	v = Vector2(randf_range(10, 30), randf_range(-25, 25)) * difficulty
	p.y = randf_range(120, 420)
	ship = label("🛰️", 42)
	place(ship, p - Vector2(24, 26), Vector2(50, 50))
	var names := [["⬆", Vector2(0, -1)], ["⬅", Vector2(-1, 0)], ["⬇", Vector2(0, 1)], ["➡", Vector2(1, 0)]]
	var spots := [Vector2(90, 410), Vector2(20, 470), Vector2(90, 470), Vector2(160, 470)]
	for i in range(4):
		var b := button(names[i][0], func(): pass, "Row")
		var dir: Vector2 = names[i][1]
		b.button_down.connect(func(): held[str(dir)] = dir)
		b.button_up.connect(func(): held.erase(str(dir)))
		place(b, spots[i], Vector2(60, 50))


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	var t := Vector2.ZERO
	for d in held.values():
		t += d
	if t != Vector2.ZERO and fuel > 0:
		v += t.normalized() * ACCEL * delta
		fuel = maxf(0.0, fuel - 14.0 * delta)
	thrust = t
	p += v * delta
	ship.position = p - Vector2(24, 26)
	var speed := v.length()
	status.text = "Speed %d   ·   Fuel %d%%   ·   %.0fs" % [int(speed), int(fuel), maxf(0.0, time_left)]
	status.add_theme_color_override("font_color", col("good") if speed < SAFE else col("warn"))
	queue_redraw()
	if PORT.grow(6).has_point(p):
		if speed < SAFE:
			Fx.play("fanfare")
			flash_text("✅ Docked!", col("good"), Vector2(W / 2, 200))
			finish(0.55 + 0.25 * fuel / 100.0 + 0.2 * clampf(time_left / LIMIT, 0, 1), {"docked": true, "fuel": fuel})
		else:
			Fx.play("bad")
			flash_text("💥 Too fast!", col("bad"), Vector2(W / 2, 200))
			finish(0.2, {"docked": false, "crash": true})
		return
	if p.x < -30 or p.x > W + 30 or p.y < -30 or p.y > H + 30:
		Fx.play("bad")
		finish(0.08, {"docked": false, "lost": true})
		return
	if time_left <= 0:
		var dist := p.distance_to(PORT.get_center())
		finish(clampf(0.3 - dist / 3000.0, 0.02, 0.3), {"docked": false, "timeout": true})


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#05070f"))
	for s in stars:
		draw_circle(s, 1.3, Color(1, 1, 1, 0.7))
	draw_rect(Rect2(930, 120, 70, 300), Color("#8892a6"))
	draw_rect(Rect2(PORT.position.x + 40, PORT.position.y - 20, 30, PORT.size.y + 40), Color("#6c768a"))
	draw_rect(PORT, Color(col("good"), 0.35))
	draw_rect(PORT, col("good"), false, 3.0)
	for i in range(6):
		var y := PORT.get_center().y
		draw_line(Vector2(PORT.position.x - 40 - i * 60, y - 50 - i * 10), Vector2(PORT.position.x - 70 - i * 60, y - 60 - i * 12), Color(col("good"), 0.4), 2.0)
		draw_line(Vector2(PORT.position.x - 40 - i * 60, y + 50 + i * 10), Vector2(PORT.position.x - 70 - i * 60, y + 60 + i * 12), Color(col("good"), 0.4), 2.0)
	if thrust != Vector2.ZERO and fuel > 0:
		draw_circle(p - thrust.normalized() * 28, 8, Color("#ffb347"))
	draw_line(p, p + v * 0.6, Color(col("warn"), 0.8), 2.0)
	bar_rect(Rect2(240, 505, 520, 12), fuel / 100.0, col("primary"), Color("#20283a"))


func _unhandled_input(event: InputEvent) -> void:
	var map := {KEY_UP: Vector2(0, -1), KEY_W: Vector2(0, -1), KEY_DOWN: Vector2(0, 1), KEY_S: Vector2(0, 1), KEY_LEFT: Vector2(-1, 0), KEY_A: Vector2(-1, 0), KEY_RIGHT: Vector2(1, 0), KEY_D: Vector2(1, 0)}
	if event is InputEventKey and not event.echo and map.has(event.keycode):
		var d: Vector2 = map[event.keycode]
		if event.pressed:
			held[str(d)] = d
		else:
			held.erase(str(d))
		get_viewport().set_input_as_handled()

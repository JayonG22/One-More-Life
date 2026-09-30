extends Minigame

const LIMIT := 30.0
const LOW := 0.25
const HIGH := 0.8

var tension := 0.4
var distance := 1.0
var fish_pull := 0.0
var retarget := 0.0
var slack_t := 0.0
var holding := false
var t := 0.0
var fish_l: Label
var rod_l: Label
var reel_b: Button


func build() -> void:
	make_status()
	rod_l = label("🎣", 70)
	place(rod_l, Vector2(80, 140), Vector2(100, 100))
	fish_l = label("🐟", 50)
	place(fish_l, Vector2(800, 330), Vector2(70, 60))
	reel_b = button("🌀 Hold to reel  [Space]", func(): pass, "Accent")
	reel_b.button_down.connect(func(): holding = true)
	reel_b.button_up.connect(func(): holding = false)
	place(reel_b, Vector2(W / 2 - 170, 460), Vector2(340, 60))


func _process(delta: float) -> void:
	if done:
		return
	t += delta
	retarget -= delta
	if retarget <= 0:
		retarget = randf_range(0.4, 1.3)
		fish_pull = randf_range(0.0, 0.55) * difficulty
		if randf() < 0.22:
			fish_pull = randf_range(0.7, 1.0) * difficulty
	var target := fish_pull + (0.55 if holding else 0.0)
	tension = move_toward(tension, target, delta * 1.3)
	if holding and tension < HIGH:
		distance = maxf(0.0, distance - delta * 0.14 * (1.2 - fish_pull))
	elif not holding:
		distance = minf(1.0, distance + delta * 0.03 * fish_pull)
	if tension < LOW:
		slack_t += delta
	else:
		slack_t = maxf(0.0, slack_t - delta)
	fish_l.position = Vector2(200 + distance * 620, 330 + sin(t * 6.0) * 10)
	status.text = "%.0fs   ·   Distance %d m" % [maxf(0.0, LIMIT - t), int(distance * 40)]
	queue_redraw()
	if tension >= 1.0:
		Fx.play("bad")
		flash_text("💥 SNAP! The line broke.", col("bad"), Vector2(W / 2, 200))
		finish(0.1 + (1.0 - distance) * 0.2, {"caught": false, "snapped": true})
	elif slack_t > 2.2:
		Fx.play("bad")
		flash_text("🐟 It got away...", col("bad"), Vector2(W / 2, 200))
		finish(0.1 + (1.0 - distance) * 0.2, {"caught": false})
	elif distance <= 0.0:
		Fx.play("fanfare")
		flash_text("🎉 Caught it!", col("good"), Vector2(W / 2, 200))
		finish(0.55 + 0.45 * clampf(1.0 - t / LIMIT, 0.0, 1.0), {"caught": true})
	elif t >= LIMIT:
		finish(0.15 + (1.0 - distance) * 0.25, {"caught": false, "timeout": true})


func _draw() -> void:
	draw_rect(Rect2(0, 300, W, 150), Color(col("primary"), 0.25))
	draw_line(Vector2(160, 160), fish_l.position + Vector2(20, 20), col("text"), 1.5)
	var r := Rect2(300, 90, 400, 26)
	draw_rect(r, col("track"))
	draw_rect(Rect2(r.position.x + r.size.x * LOW, r.position.y, r.size.x * (HIGH - LOW), r.size.y), Color(col("good"), 0.45))
	draw_rect(Rect2(r.position.x + r.size.x * HIGH, r.position.y, r.size.x * (1 - HIGH), r.size.y), Color(col("bad"), 0.35))
	draw_rect(Rect2(r.position.x + r.size.x * clampf(tension, 0, 1) - 4, r.position.y - 8, 8, r.size.y + 16), col("text"))
	draw_string(ThemeManager.font_bold, Vector2(300, 80), "Line tension", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col("dim"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE]):
		holding = true
		get_viewport().set_input_as_handled()
	elif key_released(event, [KEY_SPACE]):
		holding = false

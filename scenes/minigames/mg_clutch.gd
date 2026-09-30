extends Minigame

const SHOTS := {
	"soccer": ["⚽", "Penalty kick", true], "hockey": ["🏒", "Shootout", true], "basketball": ["🏀", "Free throw", false],
	"football": ["🏈", "Field goal", false], "baseball": ["⚾", "Swing", false], "tennis": ["🎾", "Serve", false],
	"boxing": ["🥊", "Knockout punch", false], "golf": ["⛳", "Putt", false], "hunt": ["🦌", "Steady your aim", false],
}
const ATTEMPTS := 5

var sport := "basketball"
var attempt := 0
var pos := 0.0
var dir := 1.0
var speed := 0.9
var zone_c := 0.5
var zone_w := 0.24
var locked := false
var results: Array = []
var aim := -1
var keeper := -1
var needs_aim := false
var info: Label
var icon_l: Label
var shoot_b: Button
var aim_btns: Array[Button] = []


func build() -> void:
	sport = str(params.get("sport", "basketball"))
	if not SHOTS.has(sport):
		sport = "basketball"
	needs_aim = SHOTS[sport][2]
	make_status()
	icon_l = label(SHOTS[sport][0], 70)
	icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(icon_l, Vector2(0, 60), Vector2(W, 90))
	info = label("", 22, true)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(info, Vector2(0, 160), Vector2(W, 32))
	shoot_b = button("Shoot!  [Space]", _shoot, "Accent")
	place(shoot_b, Vector2(W / 2 - 150, 440), Vector2(300, 64))
	if needs_aim:
		var names := ["⬅ Left [A]", "⬆ Center [S]", "➡ Right [D]"]
		for i in range(3):
			var b := button(names[i], _set_aim.bind(i), "Toggle")
			b.toggle_mode = true
			place(b, Vector2(W / 2 - 330 + i * 225, 370), Vector2(210, 52))
			aim_btns.append(b)
	_next()


func _next() -> void:
	if attempt >= ATTEMPTS:
		var sc := 0.0
		for r in results:
			sc += float(r)
		finish(sc / ATTEMPTS, {"made": results.filter(func(r): return float(r) > 0.0).size()})
		return
	attempt += 1
	locked = false
	zone_w = maxf(0.08, 0.26 - (attempt - 1) * 0.04 * difficulty)
	zone_c = randf_range(0.15 + zone_w / 2, 0.85 - zone_w / 2)
	speed = (0.8 + attempt * 0.18) * difficulty
	pos = randf()
	aim = -1
	for b in aim_btns:
		b.button_pressed = false
	info.text = "%s  %d of %d%s" % [SHOTS[sport][1], attempt, ATTEMPTS, "  ·  pick a corner, then shoot" if needs_aim else ""]
	shoot_b.disabled = false


func _set_aim(i: int) -> void:
	if locked:
		return
	aim = i
	for j in range(aim_btns.size()):
		aim_btns[j].button_pressed = j == i


func _shoot() -> void:
	if locked or done:
		return
	if needs_aim and aim < 0:
		aim = randi() % 3
	locked = true
	shoot_b.disabled = true
	var acc := 1.0 - absf(pos - zone_c) / (zone_w / 2.0)
	var result := 0.0
	var msg := ""
	if acc >= 0.0:
		result = 0.6 + 0.4 * acc
		msg = "Swish!" if acc > 0.8 else "Good!"
	if needs_aim and result > 0:
		keeper = randi() % 3
		if keeper == aim and acc < 0.85:
			result = 0.0
			msg = "Saved by the keeper!"
	if result > 0:
		Fx.play("good")
		flash_text("✅ " + msg, col("good"), Vector2(W / 2, 250))
	else:
		Fx.play("bad")
		flash_text("❌ " + (msg if msg != "" else "Missed!"), col("bad"), Vector2(W / 2, 250))
	results.append(result)
	get_tree().create_timer(0.9).timeout.connect(_next)


func _process(delta: float) -> void:
	if done:
		return
	if not locked:
		pos += dir * speed * delta
		if pos > 1.0:
			pos = 1.0
			dir = -1.0
		elif pos < 0.0:
			pos = 0.0
			dir = 1.0
	var made := results.filter(func(r): return float(r) > 0.0).size()
	status.text = "Made %d of %d" % [made, results.size()]
	queue_redraw()


func _draw() -> void:
	var r := Rect2(120, 300, 760, 44)
	draw_rect(r, col("track"))
	draw_rect(Rect2(r.position.x + (zone_c - zone_w / 2) * r.size.x, r.position.y, zone_w * r.size.x, r.size.y), col("good"))
	draw_rect(Rect2(r.position.x + (zone_c - zone_w / 8) * r.size.x, r.position.y, zone_w / 4 * r.size.x, r.size.y), col("good").lightened(0.35))
	var nx := r.position.x + pos * r.size.x
	draw_rect(Rect2(nx - 4, r.position.y - 12, 8, r.size.y + 24), col("text"))
	for i in range(ATTEMPTS):
		var cc := col("track")
		if i < results.size():
			cc = col("good") if float(results[i]) > 0 else col("bad")
		draw_circle(Vector2(W / 2 - 80 + i * 40, 225), 10, cc)


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		_shoot()
		get_viewport().set_input_as_handled()
	elif needs_aim:
		var keys := [KEY_A, KEY_S, KEY_D]
		for i in range(3):
			if key_pressed(event, [keys[i]]):
				_set_aim(i)
				get_viewport().set_input_as_handled()

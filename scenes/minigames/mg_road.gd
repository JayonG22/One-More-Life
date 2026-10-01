extends Minigame

## ROAD TEST. A short route in three lanes. Switch lane with ← → (A / D); hold
## Space to brake. Cones are avoided, pedestrians are waited for, and a red
## light is a stop line. Four faults fail the test; a clean run is perfect.
##
## It runs at the relaxed pace by default, there is no fuel or clock to beat,
## and every hazard is announced well before you reach it.

const LANES := 3
const ROUTE_LEN := 3600.0
const CAR_Y := 430.0
const LANE_W := 150.0

var lane := 1
var dist := 0.0
var speed := 0.0
var braking := false
var faults := 0
var hazards: Array = []   # {kind, lane, y (distance), cleared, hit}
var fault_l: Label
var tip_l: Label
var light_red_until := 0.0
var clock := 0.0
var last_fault_clock := -9.0


func build() -> void:
	make_status()
	fault_l = label("", 22, true)
	place(fault_l, Vector2(30, 8), Vector2(300, 30))
	tip_l = label("", 20, true, col("warn"))
	tip_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(tip_l, Vector2(W / 2 + 120, 120), Vector2(380, 120))
	tip_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var l := button("◀", func(): _move(-1), "Row")
	place(l, Vector2(W / 2 + 110, 400), Vector2(90, 70))
	var br := button("Brake  [Space]", func(): pass, "Accent")
	br.button_down.connect(func(): braking = true)
	br.button_up.connect(func(): braking = false)
	place(br, Vector2(W / 2 + 210, 400), Vector2(180, 70))
	var r := button("▶", func(): _move(1), "Row")
	place(r, Vector2(W / 2 + 400, 400), Vector2(90, 70))
	var hint := label("← → change lane  ·  hold Space to brake", 15, false, col("dim"))
	place(hint, Vector2(W / 2 + 110, 480), Vector2(380, 24))
	# the route: cones, crossings and lights, spaced so each can be read in time
	var d := 500.0
	var kinds := ["cone", "cone", "ped", "cone", "light", "cone", "ped", "cone", "light", "cone"]
	for k in kinds:
		hazards.append({"kind": k, "lane": randi() % LANES, "y": d, "cleared": false, "hit": false, "ped_until": 0.0})
		d += randf_range(270.0, 330.0)
	speed = 0.0


func _move(d: int) -> void:
	if done:
		return
	lane = clampi(lane + d, 0, LANES - 1)
	Fx.play("tap", 0.05)


func _fault(n: int, why: String) -> void:
	if clock - last_fault_clock < 1.0:
		return
	last_fault_clock = clock
	faults += n
	Fx.play("error")
	flash_text("Fault: " + why, col("bad"), Vector2(W / 2 - 140, 90), 26)
	if faults >= 4:
		finish(clampf(0.35 * dist / ROUTE_LEN, 0.0, 0.35), {"passed": false, "faults": faults, "why": why})


func _process(delta: float) -> void:
	if done:
		return
	clock += delta
	var target := 0.0 if braking else 230.0 * clampf(difficulty, 0.6, 1.3)
	speed = move_toward(speed, target, 420.0 * delta)
	dist += speed * delta
	var tip := "Clear road."
	for h in hazards:
		if h["cleared"]:
			continue
		var ahead: float = float(h["y"]) - dist
		if ahead < -60.0:
			h["cleared"] = true
			continue
		match h["kind"]:
			"cone":
				if ahead < 190.0 and int(h["lane"]) == lane:
					tip = "Cone in your lane — change lane."
				if absf(ahead) < 26.0 and int(h["lane"]) == lane and not h["hit"]:
					h["hit"] = true
					_fault(1, "hit a cone")
			"ped":
				if h["ped_until"] == 0.0 and ahead < 260.0:
					h["ped_until"] = clock + 2.6
				if ahead < 260.0 and clock < float(h["ped_until"]):
					tip = "Pedestrian crossing — brake and wait."
				if ahead < 30.0 and ahead > -30.0 and clock < float(h["ped_until"]) and speed > 40.0:
					h["ped_until"] = clock
					_fault(2, "did not stop for a pedestrian")
			"light":
				if h["ped_until"] == 0.0 and ahead < 300.0:
					h["ped_until"] = clock + 3.0
				if ahead < 300.0 and ahead > 0.0 and clock < float(h["ped_until"]):
					tip = "Red light — stop at the line."
				if ahead < 24.0 and ahead > -24.0 and clock < float(h["ped_until"]) and speed > 40.0:
					h["ped_until"] = clock
					_fault(2, "ran a red light")
	tip_l.text = tip
	fault_l.text = "Faults: %d / 4" % faults
	status.text = "%d%% of the route" % int(100.0 * dist / ROUTE_LEN)
	if dist >= ROUTE_LEN:
		var score := clampf(1.0 - faults * 0.2, 0.4, 1.0)
		Fx.play("fanfare")
		finish(score, {"passed": true, "faults": faults})
	queue_redraw()


func _draw() -> void:
	var rx := 40.0
	draw_rect(Rect2(rx, 40, LANE_W * LANES, 480), col("track"))
	for i in range(LANES + 1):
		draw_rect(Rect2(rx + i * LANE_W - 2, 40, 4, 480), col("border"))
	# dashes scroll with distance
	for i in range(LANES - 1):
		for j in range(-1, 12):
			var yy := 40.0 + fposmod(j * 60.0 + dist, 720.0) - 60.0
			draw_rect(Rect2(rx + (i + 1) * LANE_W - 3, yy, 6, 30), Color(col("dim"), 0.45))
	for h in hazards:
		var ahead: float = float(h["y"]) - dist
		var y := CAR_Y - ahead
		if y < 30.0 or y > 540.0:
			continue
		var hx := rx + int(h["lane"]) * LANE_W
		match h["kind"]:
			"cone":
				draw_colored_polygon(PackedVector2Array([Vector2(hx + LANE_W / 2 - 14, y + 24), Vector2(hx + LANE_W / 2 + 14, y + 24), Vector2(hx + LANE_W / 2, y - 10)]), Color("#ff8a2a"))
			"ped":
				var live := clock < float(h["ped_until"])
				draw_rect(Rect2(rx, y - 14, LANE_W * LANES, 28), Color(col("dim"), 0.35))
				if live:
					draw_circle(Vector2(rx + fposmod(clock * 90.0, LANE_W * LANES), y), 12, col("warn"))
			"light":
				var red := clock < float(h["ped_until"])
				draw_rect(Rect2(rx, y - 3, LANE_W * LANES, 6), col("bad") if red else col("good"))
	# the car
	var cx := rx + lane * LANE_W + LANE_W / 2
	draw_rect(Rect2(cx - 22, CAR_Y - 10, 44, 80), col("primary"))
	draw_rect(Rect2(cx - 16, CAR_Y + 4, 32, 22), Color(0.1, 0.15, 0.25))
	if braking:
		draw_rect(Rect2(cx - 22, CAR_Y + 62, 12, 8), col("bad"))
		draw_rect(Rect2(cx + 10, CAR_Y + 62, 12, 8), col("bad"))


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_LEFT, KEY_A]):
		_move(-1)
	elif key_pressed(event, [KEY_RIGHT, KEY_D]):
		_move(1)
	elif event is InputEventKey and (event as InputEventKey).keycode == KEY_SPACE and not (event as InputEventKey).echo:
		braking = (event as InputEventKey).pressed
	else:
		return
	get_viewport().set_input_as_handled()

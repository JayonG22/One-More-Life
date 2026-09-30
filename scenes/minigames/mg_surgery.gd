extends Minigame

## Surgery: keep three vitals in a safe band while completing prompted steps.
## It is intentionally about prioritization rather than graphic detail.

const DURATION := 38.0
const STEPS := [
	["Prep the field", "Sterile drape", 0],
	["Control the first bleed", "Cautery", 1],
	["Expose the operative site", "Retractor", 2],
	["Repair the problem", "Suture", 3],
	["Close carefully", "Suture", 3],
]

var oxygen := 0.72
var pressure := 0.58
var bleeding := 0.22
var time_left := DURATION
var stable_time := 0.0
var step_i := 0
var steps_ok := 0
var mistakes := 0
var prompt: Label
var tool_buttons: Array[Button] = []


func build() -> void:
	make_status()
	var title := label("🔪  OPERATING ROOM", 30, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(title, Vector2(0, 42), Vector2(W, 44))
	var info := label("Keep oxygen and pressure in the safe band, control bleeding, and answer the procedure prompt. Keys 1–4.", 16)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(info, Vector2(50, 88), Vector2(900, 30))
	prompt = label("", 22, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(prompt, Vector2(100, 310), Vector2(800, 42))
	var tools := ["1 · Sterile drape", "2 · Cautery", "3 · Retractor", "4 · Suture"]
	for i in range(4):
		var b := button(tools[i], _tool.bind(i), "Primary")
		place(b, Vector2(80 + (i % 2) * 440, 370 + int(i / 2) * 62), Vector2(400, 50))
		tool_buttons.append(b)
	_update_prompt()


func _update_prompt() -> void:
	if step_i >= STEPS.size():
		prompt.text = "✓ Procedure complete — keep the patient stable through handoff."
		return
	prompt.text = "Next: %s   ·   choose %s" % [STEPS[step_i][0], STEPS[step_i][1]]


func _tool(i: int) -> void:
	if done:
		return
	# Tools also have real physiologic effects, so mashing the right-looking
	# button is not always the right priority.
	match i:
		0:
			bleeding = minf(1.0, bleeding + 0.025)
		1:
			bleeding = maxf(0.0, bleeding - 0.18)
			pressure = maxf(0.0, pressure - 0.035)
		2:
			oxygen = maxf(0.0, oxygen - 0.025)
			pressure = minf(1.0, pressure + 0.025)
		3:
			bleeding = maxf(0.0, bleeding - 0.08)
			pressure = minf(1.0, pressure + 0.02)
	if step_i < STEPS.size():
		if i == int(STEPS[step_i][2]):
			steps_ok += 1
			step_i += 1
			Fx.play("good")
			flash_text("✓ correct step", col("good"), Vector2(W/2, 292), 25)
			_update_prompt()
		else:
			mistakes += 1
			bleeding = minf(1.0, bleeding + 0.05)
			Fx.play("bad")
			flash_text("× wrong instrument", col("bad"), Vector2(W/2, 292), 25)


func _process(delta: float) -> void:
	if done:
		return
	time_left -= delta
	# The patient drifts continuously. Difficulty increases drift without
	# turning it into a twitch game.
	var d := delta * difficulty
	oxygen = clampf(oxygen - 0.010 * d + randf_range(-0.004,0.004) * d, 0, 1)
	pressure = clampf(pressure - (bleeding * 0.020 + 0.003) * d + randf_range(-0.003,0.003) * d, 0, 1)
	bleeding = clampf(bleeding + 0.008 * d, 0, 1)
	# Automatic anesthetic support: the player is the surgeon, not every member
	# of the OR. It prevents impossible spirals while preserving pressure.
	if oxygen < 0.48:
		oxygen = minf(1.0, oxygen + 0.035 * d)
	if pressure < 0.35:
		pressure = minf(1.0, pressure + 0.025 * d)
	var stable := oxygen >= 0.48 and oxygen <= 0.94 and pressure >= 0.38 and pressure <= 0.86 and bleeding <= 0.52
	if stable:
		stable_time += delta
	status.text = "Time %.0fs   ·   Steps %d/%d   ·   Mistakes %d" % [maxf(0,time_left), steps_ok, STEPS.size(), mistakes]
	queue_redraw()
	if oxygen <= 0.08 or pressure <= 0.08 or bleeding >= 0.95:
		finish(0.05, {"steps":steps_ok,"mistakes":mistakes,"crisis":true})
	elif time_left <= 0.0:
		var stability_score := stable_time / DURATION
		var step_score := float(steps_ok) / float(STEPS.size())
		var penalty := float(mistakes) * 0.035
		finish(clampf(stability_score * 0.55 + step_score * 0.45 - penalty, 0.0, 1.0), {"steps":steps_ok,"mistakes":mistakes,"stable_seconds":stable_time})


func _draw() -> void:
	var labels := [["Oxygen",oxygen],["Pressure",pressure],["Bleeding",bleeding]]
	for i in range(3):
		var y := 150.0 + i * 48.0
		draw_string(ThemeManager.font_regular, Vector2(105,y+18), labels[i][0], HORIZONTAL_ALIGNMENT_LEFT, 110, 17, col("text"))
		var r := Rect2(225,y,650,24)
		draw_rect(r,col("track"))
		var value: float = float(labels[i][1])
		var c := col("bad") if (i == 2 and value > 0.52) or (i < 2 and (value < 0.38 or value > 0.94)) else col("good")
		draw_rect(Rect2(r.position,Vector2(r.size.x*value,r.size.y)),c)
		# safe band marker
		if i < 2:
			draw_line(Vector2(r.position.x+r.size.x*0.38,y-3),Vector2(r.position.x+r.size.x*0.38,y+27),col("text"),1)
			draw_line(Vector2(r.position.x+r.size.x*(0.94 if i==0 else 0.86),y-3),Vector2(r.position.x+r.size.x*(0.94 if i==0 else 0.86),y+27),col("text"),1)
		else:
			draw_line(Vector2(r.position.x+r.size.x*0.52,y-3),Vector2(r.position.x+r.size.x*0.52,y+27),col("text"),1)


func _unhandled_input(event: InputEvent) -> void:
	var keys := [KEY_1,KEY_2,KEY_3,KEY_4]
	for i in range(4):
		if key_pressed(event,[keys[i]]):
			_tool(i)
			get_viewport().set_input_as_handled()
			return

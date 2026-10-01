extends MinigameGamble

## HORSE RACE. Six horses down six lanes with their own pace and a final sprint.
## The winner was drawn from the posted odds before the gates opened; the race is
## the telling of it. Cheer with Space to fill the crowd meter.

const FIN := 840.0

var horses: Array = []
var pick := 0
var order: Array = []          # finishing order, indices
var times: Array = []
var pos: Array = []
var sprites: Array = []
var t := 0.0
var running := false
var crowd := 0.0
var msg_l: Label
var go_btn: Button
var crowd_l: Label
var last_leader := -1


func build() -> void:
	horses = params.get("horses", [])
	pick = int(params.get("pick", 0))
	if horses.is_empty():
		for i in range(6):
			horses.append({"name": "Horse %d" % (i + 1), "prob": 1.0 / 6.0, "odds": 5.5})
	header("🏇  The Races")
	msg_l = label("You're on  %s  at %.1f to 1" % [str(horses[pick]["name"]), float(horses[pick]["odds"]) - 1.0], 20, true)
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(msg_l, Vector2(0, 44), Vector2(W, 30))
	for i in range(horses.size()):
		var lane := ColorRect.new()
		lane.color = Color(0.15, 0.32, 0.14) if i % 2 == 0 else Color(0.18, 0.37, 0.17)
		place(lane, Vector2(60, 90 + i * 56), Vector2(880, 54))
		var nm := label(("★ " if i == pick else "") + str(horses[i]["name"]), 14, i == pick, Color(1, 1, 1, 0.8))
		place(nm, Vector2(66, 94 + i * 56), Vector2(240, 20))
		var h := label("🏇", 40)
		place(h, Vector2(66, 100 + i * 56), Vector2(60, 50))
		sprites.append(h)
		pos.append(0.0)
	var fin := ColorRect.new()
	fin.color = Color(1, 1, 1, 0.8)
	place(fin, Vector2(930, 90), Vector2(6, 336))
	go_btn = button("AND THEY'RE OFF  [Space]", _go, "Primary")
	place(go_btn, Vector2(W / 2.0 - 170, 446), Vector2(340, 60))
	crowd_l = label("", 18, true)
	crowd_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(crowd_l, Vector2(0, 512), Vector2(W, 24))


func _go() -> void:
	if running or done:
		return
	running = true
	go_btn.visible = false
	# draw the winner from the odds, then the rest by the same weights
	var weights: Array = []
	for h in horses:
		weights.append(float(h["prob"]))
	if randf() < (luck - 1.0) * 0.05:
		weights[pick] = float(weights[pick]) * 3.0
	order = []
	var pool: Array = range(horses.size())
	while not pool.is_empty():
		var tot := 0.0
		for i in pool:
			tot += float(weights[i])
		var r := randf() * tot
		var acc := 0.0
		var chosen: int = int(pool[0])
		for i in pool:
			acc += float(weights[i])
			if r <= acc:
				chosen = int(i)
				break
		order.append(chosen)
		pool.erase(chosen)
	times = []
	times.resize(horses.size())
	for rank in range(order.size()):
		times[order[rank]] = 9.0 + float(rank) * 0.35 + randf_range(0.0, 0.2)
	t = 0.0
	Fx.play("whoosh")
	msg_l.text = "They're off!"


func _progress(i: int, tt: float) -> float:
	var T: float = times[i]
	var k := clampf(tt / T, 0.0, 1.0)
	# a personal rhythm: a quick start, a middle drift, a closing kick
	var ph := float(i) * 1.7
	var wob := sin(tt * 1.6 + ph) * 0.035 + sin(tt * 3.1 + ph * 2.0) * 0.015
	var kick := pow(k, 1.0 + 0.5 * sin(ph))
	return clampf(kick + wob * (1.0 - k) * 1.0, 0.0, 1.0)


func _process(delta: float) -> void:
	if done or not running:
		return
	t += delta
	crowd = maxf(0.0, crowd - delta * 0.3)
	var lead := 0
	var best := -1.0
	var finished := 0
	for i in range(horses.size()):
		var pr := _progress(i, t)
		if t >= float(times[i]):
			pr = 1.0
			finished += 1
		pos[i] = pr
		(sprites[i] as Label).position.x = 66 + pr * FIN
		(sprites[i] as Label).rotation = sin(t * 14.0 + float(i)) * 0.06 * (1.0 - pr * 0.3)
		if pr > best:
			best = pr
			lead = i
	if lead != last_leader and t > 1.5:
		last_leader = lead
		msg_l.text = "%s takes the lead!" % str(horses[lead]["name"])
		if lead == pick:
			Fx.play("good")
	crowd_l.text = "Crowd  %s" % "█".repeat(int(crowd * 10.0)).rpad(10, "░") if crowd > 0.0 else "Cheer with Space"
	if finished >= horses.size() or t >= float(times[order[order.size() - 1]]) + 0.4:
		running = false
		var winner: int = order[0]
		var win := winner == pick
		msg_l.text = "%s wins!" % str(horses[winner]["name"])
		var odds := float(horses[pick]["odds"])
		settle(int(bet * odds) if win else 0, "I bet on %s at %.1f to 1. %s %s." % [str(horses[pick]["name"]), odds - 1.0, str(horses[pick]["name"]), "won" if win else "finished behind %s" % str(horses[winner]["name"])])


func _unhandled_input(event: InputEvent) -> void:
	if key_pressed(event, [KEY_SPACE, KEY_ENTER]):
		if not running:
			_go()
		else:
			crowd = minf(1.0, crowd + 0.15)
			Fx.play("tap", 0.1)
		get_viewport().set_input_as_handled()

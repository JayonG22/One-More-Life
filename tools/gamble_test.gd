extends Node
## A casino visit is a session: play again until cash out / give up, one report at the end.
var fails := 0
var got: Dictionary = {}
var cur: MinigameGamble


func ok(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: ", m)


func _hook(g: MinigameGamble) -> void:
	cur = g
	g.finished.connect(func(_s: float, d: Dictionary): got = d)
	g.restarted.connect(_hook)


func _ready() -> void:
	var host := Control.new()
	add_child(host)
	var g: MinigameGamble = load("res://scenes/minigames/mg_g_wheel.gd").new()
	g.setup({"bet": 100, "luck": 1.0, "money": 250, "skill": 50, "difficulty": 1.0})
	host.add_child(g)
	_hook(g)
	await get_tree().process_frame
	cur.settle(200, "won")
	await get_tree().create_timer(2.2).timeout
	ok(cur.panel != null and cur.rounds == 1, "no end-of-round panel after round 1")
	ok(cur.cash_now() == 350, "cash after a 200 win on a 100 bet from 250 should be 350, was %d" % cur.cash_now())
	cur._again(50)
	await get_tree().process_frame
	ok(cur.rounds == 1 and cur.total_won == 200 and cur.total_stake == 100, "the session totals were lost on play-again")
	ok(cur.bet == 50, "the bet did not change to 50")
	cur.settle(0, "lost")
	await get_tree().create_timer(2.2).timeout
	ok(cur.rounds == 2 and cur.cash_now() == 300, "cash after round 2 should be 300, was %d" % cur.cash_now())
	cur.finish(0.5, cur._session_detail("out"))
	ok(int(got.get("won", -1)) == 200 and int(got.get("extra", -1)) == 50, "the one report to the casino is wrong: %s" % str(got))
	# leaving mid-round loses the stake in play
	got = {}
	var h2: MinigameGamble = load("res://scenes/minigames/mg_g_slots.gd").new()
	h2.setup({"bet": 100, "luck": 1.0, "money": 1000, "skill": 50, "difficulty": 1.0})
	host.add_child(h2)
	_hook(h2)
	await get_tree().process_frame
	h2.finish(0.05, {"quit": true})
	ok(int(got.get("won", -1)) == 0 and int(got.get("extra", -99)) == 0, "walking out mid-round should cost the stake: %s" % str(got))
	print("GAMBLE TEST failures=%d" % fails)
	get_tree().quit()

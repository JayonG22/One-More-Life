extends Node

## DEEDS — what you are eventually shows up in your life, not just your stats.
##
## Karma used to be a hidden number that quietly nudged event odds and did
## nothing you could ever point at. That is not a consequence, it is a rounding
## error with good PR.
##
## This watches the extremes — of karma, and of the four stats — and when a life
## sits at one of them long enough, the world acts on it. Somebody returns a
## kindness years later. Something you owned goes missing. A door opens that was
## never advertised, or closes without explaining itself.
##
## The rule is that every one of these changes something you can SEE: an item in
## your possessions, money, a person's opinion, an opportunity. Never a silent
## stat tick.

## How many consecutive years at an extreme before the world notices.
const PATIENCE := 3


func _p() -> Dictionary:
	return GameState.player


func _state() -> Dictionary:
	var p := _p()
	if not p.has("deeds") or not (p["deeds"] is Dictionary):
		p["deeds"] = {"good_years": 0, "bad_years": 0, "streak": "", "last_age": -99, "given": [], "last_stat": ""}
	return p["deeds"]


func _give_item(name: String, value: int, note: String) -> void:
	var p := _p()
	if not p.has("possessions"):
		p["possessions"] = []
	p["possessions"].append({"name": name, "value": maxi(1, value), "kind": "gift", "note": note})


func _lose_item() -> String:
	var p := _p()
	var items: Array = p.get("possessions", [])
	if items.is_empty():
		return ""
	var idx := randi() % items.size()
	var nm := str(items[idx].get("name", "something"))
	items.remove_at(idx)
	return nm


# ---------------------------------------------------------------- the year

func yearly() -> void:
	var p := _p()
	if p.is_empty() or not GameState.is_alive() or int(p["age"]) < 8:
		return
	var st := _state()
	var karma := int(p.get("karma", 0))

	if karma >= 35:
		st["good_years"] = int(st["good_years"]) + 1
		st["bad_years"] = 0
	elif karma <= -35:
		st["bad_years"] = int(st["bad_years"]) + 1
		st["good_years"] = 0
	else:
		st["good_years"] = maxi(0, int(st["good_years"]) - 1)
		st["bad_years"] = maxi(0, int(st["bad_years"]) - 1)

	# Only one of these a year, and never two years running.
	if int(p["age"]) - int(st["last_age"]) < 2:
		return

	if int(st["good_years"]) >= PATIENCE and randf() < 0.4:
		st["last_age"] = int(p["age"])
		_good_turn()
		return
	if int(st["bad_years"]) >= PATIENCE and randf() < 0.42:
		st["last_age"] = int(p["age"])
		_bad_turn()
		return
	if randf() < 0.22:
		st["last_age"] = int(p["age"])
		_extreme_stat_turn()


# ---------------------------------------------------------------- good karma

func _good_turn() -> void:
	var p := _p()
	match randi() % 5:
		0:
			# Someone you were decent to, years ago, turns out to have remembered.
			var pool := GameState.npcs_with("friend") + GameState.npcs_with("coworker") + GameState.npcs_with("neighbor")
			if pool.is_empty():
				_good_item()
				return
			var id: String = pool[randi() % pool.size()]
			var gift := Actions._cost(randi_range(400, 3500))
			p["money"] = int(p["money"]) + gift
			GameState.change_closeness(id, 8)
			Bonds.remember(id, "Paid back a kindness from years ago.", true)
			GameState.add_log("%s turned up out of nowhere to repay something I had long stopped counting: %s." % [GameState.full_name(id), GameState.fmt_money(gift)])
			LifeThreads.remember("relationship", "The kindness that came back", "%s remembered something I had forgotten doing, and made it matter." % GameState.full_name(id), id, 62, ["karma", "kindness"])
		1:
			_good_item()
		2:
			var helper := GameState.create_npc("friend", {"age": maxi(18, int(p["age"]) + randi_range(-15, 15)), "closeness": 58})
			GameState.add_log("%s introduced themselves because of something they had heard about me. People talk, and this time it helped." % GameState.full_name(helper))
			GameState.apply_effects({"happiness": 5})
		3:
			if GameState.has_job():
				GameState.apply_effects({"job_perf": 8, "happiness": 4})
				GameState.add_log("Someone spoke up for me at work without being asked. I only found out afterwards.")
			else:
				_good_item()
		4:
			GameState.apply_effects({"happiness": 7, "stress": -8})
			GameState.add_log("A stranger went out of their way for me this year. It did not fix anything, and it changed the whole month.")


func _good_item() -> void:
	var picks := [
		["A hand-written recipe book", 120, "Left to me by someone who thought I would use it."],
		["A worn silver pocket watch", 900, "Given to me by someone who said I had earned it."],
		["A signed first edition", 1400, "A thank-you from someone I helped."],
		["A carved wooden box", 260, "Made by hand, by somebody grateful."],
		["A small landscape painting", 2200, "It hung in their hallway for forty years before it hung in mine."],
	]
	var it: Array = picks[randi() % picks.size()]
	var value := Actions._cost(int(it[1]))
	_give_item(str(it[0]), value, str(it[2]))
	GameState.apply_effects({"happiness": 6})
	GameState.add_log("Someone gave me %s. %s It is worth about %s, which is not the point." % [str(it[0]).to_lower(), str(it[2]), GameState.fmt_money(value)])


# ---------------------------------------------------------------- bad karma

func _bad_turn() -> void:
	var p := _p()
	match randi() % 5:
		0:
			var lost := _lose_item()
			if lost == "":
				var stolen := mini(int(p["money"]), Actions._cost(randi_range(300, 4000)))
				p["money"] = int(p["money"]) - stolen
				GameState.add_log("Money went missing this year: %s. I have a shortlist of who, and no proof." % GameState.fmt_money(stolen))
			else:
				GameState.apply_effects({"happiness": -6, "stress": 6})
				GameState.add_log("%s disappeared from my home. Nobody I asked seemed surprised." % lost)
		1:
			var pool := GameState.npcs_with("friend") + GameState.npcs_with("coworker")
			if pool.is_empty():
				GameState.apply_effects({"happiness": -5, "stress": 6})
				GameState.add_log("An invitation did not come this year. Then another one did not.")
				return
			var id: String = pool[randi() % pool.size()]
			GameState.change_closeness(id, -22)
			Grit.grudge(id, 30)
			Bonds.remember(id, "Heard what I am actually like.", false)
			GameState.add_log("%s heard a version of who I am that I could not really argue with, and stopped calling." % GameState.full_name(id))
		2:
			if GameState.has_job():
				GameState.apply_effects({"job_perf": -10, "stress": 8})
				GameState.add_log("Something I did years ago got repeated to the wrong person at work.")
			else:
				GameState.apply_effects({"happiness": -6, "stress": 7})
				GameState.add_log("A door I expected to be open was not, and nobody would tell me why.")
		3:
			var enemy := GameState.create_npc("enemy", {"age": maxi(18, int(p["age"]) + randi_range(-12, 12)), "closeness": 5})
			Grit.grudge(enemy, 55)
			GameState.add_log("%s has decided I am the reason something in their life went wrong. They may even be right." % GameState.full_name(enemy))
			LifeThreads.remember("regret", "Someone who blames me", "%s holds me responsible for something, and I have stopped being sure they are wrong." % GameState.full_name(enemy), enemy, 64, ["karma"])
		4:
			GameState.apply_effects({"happiness": -7, "stress": 9, "money": -Actions._cost(randi_range(200, 2500))})
			GameState.add_log("It was an expensive year to be me, in a way that felt less like luck than arithmetic.")


# ---------------------------------------------------------------- extremes

## Living at the top or bottom of a stat should change what happens to you, not
## only what the bar looks like.
func _extreme_stat_turn() -> void:
	var p := _p()
	var checks := [
		["looks", 88.0, true], ["looks", 18.0, false],
		["smarts", 90.0, true], ["smarts", 15.0, false],
		["health", 90.0, true], ["health", 22.0, false],
		["happiness", 90.0, true], ["happiness", 15.0, false],
	]
	checks.shuffle()
	for c in checks:
		var key: String = c[0]
		var v := GameState.stat(key)
		var high: bool = c[2]
		if (high and v < float(c[1])) or (not high and v > float(c[1])):
			continue
		# Do not tell the player the same thing about themselves twice running.
		var tag := "%s_%s" % [key, "hi" if high else "lo"]
		if tag == str(_state().get("last_stat", "")):
			continue
		_state()["last_stat"] = tag
		_stat_event(key, high)
		return


func _stat_event(key: String, high: bool) -> void:
	var p := _p()
	match key:
		"looks":
			if high:
				var fee := Actions._cost(randi_range(300, 2600))
				p["money"] = int(p["money"]) + fee
				GameState.add_log("I was asked to appear in something local, mostly for how I look. It paid %s and felt strange." % GameState.fmt_money(fee))
			else:
				GameState.apply_effects({"happiness": -4, "stress": 4})
				GameState.add_log("I watched somebody decide something about me before I had said a word.")
		"smarts":
			if high:
				_give_item("An award for something I wrote", Actions._cost(400), "For work nobody expected from me.")
				GameState.apply_effects({"happiness": 6})
				GameState.add_log("Something I worked out got noticed by people who knew enough to notice.")
			else:
				GameState.apply_effects({"money": -Actions._cost(randi_range(200, 1800)), "stress": 6})
				GameState.add_log("I signed something I did not fully read, and it cost me.")
		"health":
			if high:
				GameState.apply_effects({"happiness": 5, "stress": -5})
				GameState.add_log("My body did everything I asked of it this year. I noticed, for once, while it was happening.")
			else:
				GameState.apply_effects({"stress": 7, "money": -Actions._cost(randi_range(300, 2200))})
				GameState.add_log("My health made decisions for me this year, and most of them were expensive.")
		"happiness":
			if high:
				var pool := GameState.npcs_with("friend")
				if not pool.is_empty():
					var id: String = pool[randi() % pool.size()]
					GameState.change_closeness(id, 10)
					GameState.add_log("I was good company this year, and %s noticed before I did." % GameState.npc(id)["first"])
				else:
					GameState.apply_effects({"happiness": 3})
					GameState.add_log("It was, without anything in particular happening, a good year.")
			else:
				for id in GameState.npcs_with("friend"):
					GameState.change_closeness(id, -5)
				GameState.add_log("I was hard work to be around this year. People were patient for a while.")

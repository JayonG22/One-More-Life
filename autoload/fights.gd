extends Node

## FIGHTS — betting on a fight card, and getting on it.
##
## The casino covered cards, wheels and horses. Fight betting is different in one
## way that matters: you can be on the card yourself, and then it is not a wager,
## it is the boxing minigame with your own money and your own face at stake.
##
## The card is generated once a year and the odds are honest — they are computed
## from the fighters' actual ratings, with the bookmaker's cut taken out of the
## payout, which is exactly how a real book works and why betting is a slow way
## to lose money.

const NAMES_A := ["Dockyard", "Southside", "Ironworks", "Riverside", "Old Town", "Quarry", "Harbour", "Northgate"]
const NICKS := ["the Hammer", "Iron Jaw", "the Surgeon", "Two Rounds", "the Quiet Man", "Glass", "the Machine", "Nightshift", "the Pillar", "Bad News"]
const ICONS := ["🥊", "🤼", "🥋", "🦾"]

const CUT := 0.12   ## the bookmaker's margin


func _p() -> Dictionary:
	return GameState.player


func _st() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("fights") or not (p["fights"] is Dictionary):
		p["fights"] = {"card": [], "year": -1, "bets": [], "record": [0, 0], "purse": 0}
	return p["fights"]


## A fresh card each year, so betting is not a repeatable exploit on one bout.
func card() -> Array:
	var st := _st()
	if st.is_empty():
		return []
	var yr := GameState.year_now()
	if int(st.get("year", -1)) != yr or (st.get("card", []) as Array).is_empty():
		st["year"] = yr
		st["card"] = _build()
		st["bets"] = []
	return st["card"]


func _build() -> Array:
	var out: Array = []
	var used: Array = []
	for i in range(4):
		var ra := randf_range(35.0, 92.0)
		var rb := clampf(ra + randf_range(-28.0, 28.0), 30.0, 95.0)
		var na := _name(used)
		var nb := _name(used)
		# True chance from the ratings, then the payout is shortened by the cut.
		var pa := clampf(0.5 + (ra - rb) / 120.0, 0.08, 0.92)
		out.append({
			"id": "b%d" % i, "icon": ICONS[i % ICONS.size()],
			"a": na, "b": nb, "ra": ra, "rb": rb, "p_a": pa,
			"odds_a": maxf(1.05, (1.0 / pa) * (1.0 - CUT)),
			"odds_b": maxf(1.05, (1.0 / (1.0 - pa)) * (1.0 - CUT)),
			"done": false,
		})
	return out


func _name(used: Array) -> String:
	for i in range(30):
		var n := "%s %s" % [NAMES_A[randi() % NAMES_A.size()], NICKS[randi() % NICKS.size()]]
		if not used.has(n):
			used.append(n)
			return n
	return "The Challenger"


func bout(id: String) -> Dictionary:
	for b in card():
		if str(b["id"]) == id:
			return b
	return {}


## Place a bet. It settles when the year turns, not immediately, so you go into
## the age-up not knowing.
func bet(bout_id: String, side: String, stake: int) -> void:
	var st := _st()
	if st.is_empty():
		return
	var b := bout(bout_id)
	if b.is_empty():
		return
	var p := _p()
	if int(p["money"]) < stake or stake <= 0:
		return
	if not GameState.spend_time(1):
		EventEngine.push_info("⏳", "Out of time", "Going to the fights takes 1 time point.")
		return
	p["money"] = int(p["money"]) - stake
	(st["bets"] as Array).append({"bout": bout_id, "side": side, "stake": stake})
	GameState.add_log("I put %s on %s." % [GameState.fmt_money(stake), str(b[side])])
	Moments.fire("money_loss", 0.3)
	Become.note_activity("fight_bets")


## Whether you can get on the card yourself, and what it is worth.
func own_slot() -> Dictionary:
	var p := _p()
	var age := int(p.get("age", 0))
	var health := GameState.stat("health")
	var belt := 0
	for disc in (p.get("martial", {}) as Dictionary).keys():
		belt = maxi(belt, int((p["martial"][disc] as Dictionary).get("rank", -1)) + 1)
	var rating := 25.0 + health * 0.35 + float(belt) * 7.0 + (12.0 if GameState.has_trait("Athletic") else 0.0)
	var purse := int(round(600.0 + rating * 55.0))
	var reasons: Array = []
	if age < 18:
		reasons.append("18 or over")
	if age > 45:
		reasons.append("the commission will not licence you past 45")
	if health < 45.0:
		reasons.append("health of 45 or better")
	if not reasons.is_empty():
		return {"ok": false, "sub": "✗ Needs " + " and ".join(reasons), "blurb":
			"A slot on the undercard pays a purse. It also means a stranger is allowed to hit you.",
			"purse": 0, "rating": rating}
	var rec: Array = _st().get("record", [0, 0])
	return {"ok": true, "purse": purse, "rating": rating,
		"sub": "Purse %s  ·  your record %d–%d  ·  1 time" % [GameState.fmt_money(purse), int(rec[0]), int(rec[1])],
		"blurb": "Three rounds on the undercard. The purse is yours either way; what happens to you in the ring is not guaranteed."}


## Take the fight. This is the real boxing minigame, so the outcome is what you
## actually do in it rather than a dice roll on your stats.
func fight_yourself() -> void:
	var slot := own_slot()
	if not bool(slot["ok"]):
		return
	if not GameState.spend_time(1):
		EventEngine.push_info("⏳", "Out of time", "A fight takes 1 time point.")
		return
	var diff := clampf(1.3 - float(slot["rating"]) / 160.0, 0.7, 1.35)
	Minigames.play("fight", {
		"skill": float(slot["rating"]), "difficulty": diff,
		"opponent": _name([]), "title": "Undercard, three rounds",
	}, Callable(self, "_own_result").bind(int(slot["purse"])))


func _own_result(score: float, detail: Dictionary, purse: int) -> void:
	var st := _st()
	if st.is_empty():
		return
	var p := _p()
	var won: bool = bool(detail.get("won", score >= 0.5))
	var rec: Array = st["record"]
	var pay := purse if not won else int(round(float(purse) * 2.2))
	p["money"] = int(p["money"]) + pay
	var hurt := int(round((1.0 - clampf(score, 0.0, 1.0)) * 22.0))
	if won:
		rec[0] = int(rec[0]) + 1
		GameState.add_log("I won on the undercard. %s, and a bruise I will have for a month." % GameState.fmt_money(pay))
		GameState.apply_effects({"money": 0, "happiness": 12, "health": -maxi(3, hurt / 2), "fame": 2})
		GameState.counter("fights_won")
		if int(rec[0]) == 5:
			GameState.add_milestone(int(p["age"]), "went 5–%d on the local circuit" % int(rec[1]))
		Moments.fire("achievement", 0.8)
	else:
		rec[1] = int(rec[1]) + 1
		GameState.add_log("I lost. The purse was %s and I earned every bit of it." % GameState.fmt_money(pay))
		GameState.apply_effects({"money": 0, "happiness": -4, "health": -maxi(6, hurt)})
		if hurt >= 18 and randf() < 0.3:
			GameState.add_log(Grit.add_scar("facial_scar"))
		Moments.fire("failure", 0.7)
	st["purse"] = int(st.get("purse", 0)) + pay
	GameState.emit_changed()


## Bets settle at the turn of the year.
func yearly() -> void:
	var st := _st()
	if st.is_empty() or not GameState.is_alive():
		return
	var bets: Array = st.get("bets", [])
	if bets.is_empty():
		st["card"] = []
		return
	var won_total := 0
	var staked := 0
	var lines: Array = []
	for bt in bets:
		var b := bout(str(bt["bout"]))
		if b.is_empty():
			continue
		staked += int(bt["stake"])
		var a_wins := randf() < float(b["p_a"])
		var backed_a: bool = str(bt["side"]) == "a"
		var winner := str(b["a"]) if a_wins else str(b["b"])
		if backed_a == a_wins:
			var pay := int(round(float(bt["stake"]) * float(b["odds_a" if backed_a else "odds_b"])))
			won_total += pay
			lines.append("%s won. That is %s back." % [winner, GameState.fmt_money(pay)])
		else:
			lines.append("%s won. There goes %s." % [winner, GameState.fmt_money(int(bt["stake"]))])
	var p := _p()
	p["money"] = int(p["money"]) + won_total
	st["bets"] = []
	st["card"] = []
	if not lines.is_empty():
		var net := won_total - staked
		EventEngine.push_info("🥊", "Fight night results",
			"\n".join(lines) + "\n\n%s %s on the night." % [
				"Up" if net > 0 else ("Even" if net == 0 else "Down"),
				GameState.fmt_money(absi(net))],
			{"money": net})
		if net > 0:
			GameState.counter("fight_bets_won")


func summary_lines() -> Array:
	var st := _st()
	if st.is_empty():
		return []
	var rec: Array = st.get("record", [0, 0])
	if int(rec[0]) + int(rec[1]) == 0:
		return []
	return [["🥊 Ring record %d–%d" % [int(rec[0]), int(rec[1])],
		"%s in purses" % GameState.fmt_money(int(st.get("purse", 0)))]]

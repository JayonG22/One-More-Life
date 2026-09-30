extends Node

## v0.14 gate — the request list, checked rather than claimed.

var failures: Array = []
var checks := 0
var sections := 0
var completed: Array = []


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V14: " + msg)


func _ready() -> void:
	seed(1414)
	for s in ["origins", "marriage", "decline", "wanted", "become", "romance", "money", "npcs", "icons", "relevance", "ui"]:
		sections += 1
		call("_" + s)
		completed.append(s)
	ok(completed.size() == sections, "a section aborted: ran %d of %d" % [completed.size(), sections])
	print("V14 SYSTEM TEST checks=%d sections=%d/%d failures=%d" % [checks, completed.size(), sections, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


# ---- #10: who you are born to varies, and an only child is a real outcome
func _origins() -> void:
	var seen := {}
	var only := 0
	var no_parents := 0
	for i in range(300):
		GameState.new_life({"gender": "male", "country": "us"})
		var o := Origins.kind()
		seen[o] = int(seen.get(o, 0)) + 1
		if Origins.only_child():
			only += 1
		if GameState.first_of("mother") == "" and GameState.first_of("father") == "":
			no_parents += 1
	ok(seen.size() >= 7, "only %d different origins across 300 lives" % seen.size())
	ok(int(seen.get("together", 0)) > int(seen.get("care", 0)),
		"the ordinary case is not the most common one")
	ok(only >= 45, "only %d only children out of 300 — that should be common" % only)
	ok(no_parents >= 5, "no life ever started without a parent in the house")
	ok(Origins.opening_line() != "" or Origins.kind() == "together",
		"an origin produced no opening line")
	print("  origins: ", seen, "  only children: %d/300" % only)

	# every origin has to produce a coherent household and a readable line
	for k in Origins.ORIGINS.keys():
		GameState.new_life({"gender": "female", "country": "us"})
		GameState.player["origin"] = str(k)
		ok(Origins.name_of(str(k)) != "", "%s has no name" % k)
		ok(Origins.blurb(str(k)) != "", "%s has no description" % k)
		ok(Origins.opening_line() != "", "%s has no opening line" % k)


# ---- #3: the bug. A married person cannot be married again.
func _marriage() -> void:
	# links point both ways
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["origin"] = "together"
	var linked := 0
	var checked := 0
	for i in range(200):
		GameState.new_life({"gender": "male", "country": "us"})
		if Origins.kind() not in ["together", "adopted"]:
			continue
		var m := GameState.first_of("mother")
		var d := GameState.first_of("father")
		if m == "" or d == "":
			continue
		checked += 1
		if str(GameState.npcs[m].get("spouse_id", "")) == d and str(GameState.npcs[d].get("spouse_id", "")) == m:
			linked += 1
	ok(checked > 0, "no two-parent household was generated to check")
	ok(linked == checked, "%d of %d two-parent households had no spouse link" % [checked - linked, checked])

	# and the actual failure: a still-married NPC given a second spouse
	var violations := 0
	var years := 0
	for i in range(120):
		GameState.new_life({"gender": "female", "country": "us"})
		var dad := GameState.first_of("father")
		if dad == "" or not Origins.is_spoken_for(dad):
			continue
		for y in range(45):
			GameState.player["age"] = y
			var before_spouse := str(GameState.npcs[dad].get("spouse", ""))
			var was_married: bool = bool(GameState.npcs[dad].get("married", false))
			Bonds._npc_life(dad, GameState.npcs[dad])
			years += 1
			var after_spouse := str(GameState.npcs[dad].get("spouse", ""))
			var still: bool = bool(GameState.npcs[dad].get("married", false))
			# A new spouse while the previous marriage was never ended is the bug.
			if was_married and still and after_spouse != before_spouse:
				violations += 1
	ok(years > 500, "only ran %d NPC-years — not enough to prove anything" % years)
	ok(violations == 0, "%d married parents acquired a second spouse without a divorce" % violations)
	print("  marriage: %d NPC-years run, %d violations" % [years, violations])

	# a divorce clears both sides
	GameState.new_life({"gender": "male", "country": "us"})
	var a := GameState.create_npc("friend", {"age": 30})
	var b := GameState.create_npc("friend", {"age": 31})
	Origins.wed(a, b)
	ok(Origins.is_spoken_for(a) and Origins.is_spoken_for(b), "wed() did not mark both partners")
	Origins.part(a)
	ok(not Origins.is_spoken_for(a), "part() left the first partner married")
	ok(not Origins.is_spoken_for(b), "part() left the OTHER partner married — the ghost spouse bug")


# ---- #1 and #15
func _decline() -> void:
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 25
	GameState.player["stats"]["smarts"] = 80.0
	GameState.player["routines"]["study"] = false
	GameState.player["education"] = {"stage": "done", "performance": 50.0, "degrees": [], "uni": {}, "studied": false}
	var start := GameState.stat("smarts")
	for y in range(10):
		GameState.player["age"] = 25 + y
		Decline.yearly()
	var after := GameState.stat("smarts")
	ok(after < start - 3.0, "ten years without studying cost only %.1f smarts" % (start - after))
	print("  smarts with no studying: %.1f -> %.1f over 10 years" % [start, after])

	# studying holds the line
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 25
	GameState.player["stats"]["smarts"] = 80.0
	GameState.player["routines"]["study"] = true
	GameState.player["education"] = {"stage": "done", "performance": 50.0, "degrees": [], "uni": {}, "studied": false}
	var s2 := GameState.stat("smarts")
	for y in range(10):
		GameState.player["age"] = 25 + y
		Decline.yearly()
	ok(absf(GameState.stat("smarts") - s2) < 0.5,
		"studying every year still lost %.1f smarts" % (s2 - GameState.stat("smarts")))

	# a failing stat produces warnings and then crises, not silence
	GameState.new_life({"gender": "female", "country": "us"})
	GameState.player["age"] = 40
	GameState.player["stats"]["health"] = 9.0
	EventEngine.pending.clear()
	var warned := false
	var crisis := false
	for y in range(20):
		GameState.player["age"] = 40 + y
		GameState.player["stats"]["health"] = 9.0
		var logs_before := GameState.log_years.size()
		Decline.yearly()
		if not EventEngine.pending.is_empty():
			for inst in EventEngine.pending:
				if str(inst.get("def", {}).get("id", "")).begins_with("_decline_"):
					crisis = true
			EventEngine.pending.clear()
	ok(Decline._state()["warned"].size() > 0, "health at 9%% produced no warning at all")
	ok(crisis, "health at 9%% for twenty years never produced a single crisis event")
	ok(Decline.failing().has("health"), "failing() did not report a stat at 9%%")

	# every crisis event obeys the content rule
	for k in Decline.CRISES.keys():
		for ev in Decline.CRISES[k]:
			var cs: Array = ev["choices"]
			ok(cs.size() >= 3, "%s crisis '%s' has only %d choices" % [k, ev["title"], cs.size()])
			for ch in cs:
				ok((ch["outcomes"] as Array).size() >= 2,
					"%s crisis '%s' choice '%s' has one outcome" % [k, ev["title"], ch["label"]])


# ---- #17
func _wanted() -> void:
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 25
	ok(Wanted.stars() == 0, "a new life starts wanted")
	ok(Wanted.display() == "", "a clean life shows stars")
	for i in range(3):
		Wanted.commit("shoplifting", false)
	var petty := Wanted.stars()
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 25
	for i in range(3):
		Wanted.commit("murder", false)
	ok(Wanted.stars() > petty, "three murders rank no higher than three shopliftings (%d vs %d)" % [Wanted.stars(), petty])
	print("  3 shopliftings = %d stars, 3 murders = %d stars" % [petty, Wanted.stars()])

	# the consequences are real numbers, not decoration
	ok(Wanted.sentence_mult() > 1.2, "being hunted does not lengthen a sentence")
	ok(Wanted.trial_bias() > 10.0, "being hunted adds no evidence at trial")
	ok(not Wanted.can_leave_country(), "a most-wanted life can still walk through passport control")
	ok(Wanted.hiring_penalty() > 0.2, "being hunted does not affect hiring")
	ok(Wanted.crimes() == 3, "the crime count is wrong: %d" % Wanted.crimes())
	ok(Wanted.history_lines().size() == 1, "the breakdown by kind is missing")

	# going straight works, slowly
	var peak := Wanted.raw()
	for y in range(25):
		GameState.player["age"] = 25 + y
		Wanted.yearly()
	ok(Wanted.raw() < peak, "twenty-five clean years cooled nothing")
	ok(Wanted.crimes() == 3, "cooling off erased the history, which it should not")
	ok(Wanted.peak() >= 2, "peak was not remembered: %d" % Wanted.peak())
	print("  cooled from %.2f to %.2f over 25 clean years, peak kept at %d" % [peak, Wanted.raw(), Wanted.peak()])

	# serving time answers for it
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	for i in range(4):
		Wanted.commit("armed robbery", true)
	var before := Wanted.raw()
	Wanted.serve_time(4)
	ok(Wanted.raw() < before, "four years inside cooled nothing")


# ---- #5
func _become() -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	ok(Become.PATHS.size() >= 16, "only %d paths listed" % Become.PATHS.size())
	# every one of the modes the request named has to be here
	for want in ["vampire", "revenant", "director", "luxury", "outdoor", "casino", "black_market", "cult", "racer", "agent", "zoo"]:
		ok(Become.PATHS.has(want), "'%s' is not in the Become a... list" % want)
	# and every entry has to be complete enough to render
	for id in Become.PATHS.keys():
		var d: Dictionary = Become.PATHS[id]
		for key in ["kind", "icon", "name", "blurb", "how", "need", "odds", "yes", "no"]:
			ok(d.has(key), "%s is missing '%s'" % [id, key])
		ok(not (d["need"] as Dictionary).is_empty(), "%s has no prerequisites at all" % id)
		var res := Become.check(str(id))
		ok((res[1] as Array).size() >= (d["need"] as Dictionary).size(),
			"%s did not report every condition" % id)

	# a newborn qualifies for nothing
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 1
	var open_now := 0
	for r in Become.rows():
		if bool(r["met"]):
			open_now += 1
	ok(open_now == 0, "a one-year-old qualifies for %d paths" % open_now)

	# a life that has actually done the work qualifies
	GameState.new_life({"gender": "female", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["stats"]["smarts"] = 90.0
	GameState.player["money"] = 10000000
	for i in range(6):
		Become.note_activity("library")
	var wr := Become.check("witch")
	ok(bool(wr[0]), "a smart adult who has been to the library six times cannot try for witch: %s" % str(wr[1]))
	ok(Become.odds("witch") > 0.2, "witch odds are %.2f, which is not worth a button" % Become.odds("witch"))

	# refusing through Destiny is still final
	GameState.new_life({"gender": "female", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["stats"]["smarts"] = 90.0
	for i in range(6):
		Become.note_activity("library")
	var dst := Destiny.state()
	(dst["declined"] as Array).append("witch")
	ok(not bool(Become.check("witch")[0]), "a declined path came back through the front door")

	# applying actually applies
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["stats"]["smarts"] = 95.0
	GameState.player["money"] = 50000
	for i in range(8):
		Become.note_activity("library")
	EventEngine.pending.clear()
	var t0 := int(GameState.player["time_left"])
	Become.apply("witch")
	ok(not EventEngine.pending.is_empty(), "applying produced no event")
	ok(int(GameState.player["time_left"]) < t0, "applying cost no time")
	ok(Become.tried_count("witch") == 1, "the attempt was not recorded")
	ok(Become.cooling() > 0, "you can apply again the same year")
	# and the accept path really transforms
	Become.outcome({"id": "witch", "won": true})
	ok(Lives.kind() == "witch", "a successful application did not change the life: %s" % Lives.kind())

	# trying repeatedly gets harder
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["stats"]["smarts"] = 90.0
	for i in range(6):
		Become.note_activity("library")
	var o1 := Become.odds("witch")
	(Become._st()["tried"] as Dictionary)["witch"] = 3
	ok(Become.odds("witch") < o1, "asking four times is as easy as asking once")


# ---- #12, #13, #14, #18, #22: the UI work, checked in the source and the API
func _ui() -> void:
	var src := FileAccess.get_file_as_string("res://scenes/main.gd")
	ok(src.find("func _refresh_tracks") != -1, "no progression tracks in the status panel")
	ok(src.find("Wanted.display()") != -1, "wanted stars are not shown anywhere")
	ok(src.find("func _confirm_twist") != -1, "turning points do not ask for confirmation")
	ok(src.find("No, let me think") != -1, "the confirmation has no way back to the choices")
	ok(src.find("func _surprise") != -1, "there is no surprise me")
	ok(src.find("SurpriseButton") != -1, "the surprise button is not named for the tests")
	ok(src.find("func _ach_card") != -1, "achievements are still a plain toast")
	ok(src.find("VFX.age_press") != -1, "the age button has no animation")
	ok(src.find("Origins.summary_lines") != -1, "the info panel does not show where the life started")
	var vfx := FileAccess.get_file_as_string("res://scenes/vfx.gd")
	ok(vfx.find("static func age_press") != -1, "age_press was not written")
	var kit := FileAccess.get_file_as_string("res://scenes/ui_kit.gd")
	ok(kit.find("border_width_top") != -1, "bars are still a flat block with no gradient")
	ok(kit.find("static func track") != -1, "there is no labelled progress track helper")
	# the Become group is reachable from the activity menu
	var found := false
	for gr in Actions.ACTIVITY_GROUPS:
		if str(gr["id"]) == "become":
			found = true
	ok(found, "Become a... is not in the activity menu")


# ---- #4: a relationship has to go somewhere
func _romance() -> void:
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 22
	var who := GameState.create_npc("crush", {"age": 22, "closeness": 55})
	Actions.start_dating(who, false)
	ok(str(Romance.st()["partner"]) == who, "starting a relationship did not register with Romance")
	ok(bool(Romance.st()["was_crush"]), "getting together with a crush was not noticed as one")
	ok(Romance.stage() == "new", "a brand new relationship is not in the first stage")

	# beats arrive, are stage-appropriate, and do not repeat
	EventEngine.pending.clear()
	var fired: Array = []
	for y in range(40):
		GameState.player["age"] = 22 + y
		Romance.yearly()
		for inst in EventEngine.pending:
			var rid := str(inst.get("def", {}).get("id", ""))
			if rid.begins_with("r_"):
				ok(not fired.has(rid), "romance beat %s fired twice in one relationship" % rid)
				fired.append(rid)
		EventEngine.pending.clear()
	ok(fired.size() >= 4, "forty years together produced only %d relationship beats" % fired.size())
	ok(Romance.years() >= 35, "the relationship clock did not run: %d years" % Romance.years())
	ok(Romance.stage() == "lifelong", "forty years is not being treated as a lifetime: %s" % Romance.stage())
	print("  romance: %d beats over 40 years, ended in stage '%s'" % [fired.size(), Romance.stage()])

	# every beat obeys the content rule
	for b in Romance.BEATS:
		ok((b["choices"] as Array).size() >= 3, "romance beat %s has %d choices" % [b["id"], (b["choices"] as Array).size()])
		for ch in b["choices"]:
			ok((ch["outcomes"] as Array).size() >= 2, "romance beat %s choice '%s' has one outcome" % [b["id"], ch["label"]])
	# and the stages are covered rather than all bunched at the start
	var by_stage := {}
	for b in Romance.BEATS:
		for sg in b["stage"]:
			by_stage[sg] = int(by_stage.get(sg, 0)) + 1
	for sg in ["new", "settling", "steady", "long"]:
		ok(int(by_stage.get(sg, 0)) >= 2, "stage '%s' has only %d beats" % [sg, int(by_stage.get(sg, 0))])

	# a breakup stops the clock
	GameState.player["partner"] = ""
	Romance.yearly()
	ok(Romance.years() == 0, "the relationship clock kept running after a breakup")


# ---- #6
func _money() -> void:
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["last_income"] = 60000
	GameState.player["credit"] = 760
	var offers := Lending.offers()
	ok(offers.size() == 4, "expected four lenders, got %d" % offers.size())
	var open_count := 0
	for o in offers:
		if bool(o["ok"]):
			open_count += 1
	ok(open_count >= 3, "a good earner with excellent credit qualifies for only %d lenders" % open_count)

	# bad credit closes the good doors and leaves the bad one open
	GameState.player["credit"] = 480
	GameState.player["last_income"] = 2000
	var bank := Lending.offer("bank")
	var shark := Lending.offer("shark")
	ok(not bool(bank["ok"]), "a bank lent to a 480 credit score on a $2,000 income")
	ok(bool(shark["ok"]), "the man in the pub turned somebody down, which is not his role")
	ok(float(shark["rate"]) > float(Lending.LENDERS["bank"]["rate"]) * 3.0, "the shark's rate is not punishing")

	# borrowing, repaying and the cost of missing
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["last_income"] = 60000
	GameState.player["credit"] = 760
	GameState.player["money"] = 0
	Lending.borrow("bank", 20000)
	ok(int(GameState.player["money"]) == 20000, "the money did not arrive: %d" % int(GameState.player["money"]))
	ok(Lending.total_owed() > 20000, "a loan at 6%% over 10 years owes no interest")
	var owed0 := Lending.total_owed()
	GameState.player["money"] = 500000
	for y in range(12):
		GameState.player["age"] = 30 + y
		Lending.yearly()
	ok(Lending.total_owed() == 0, "twelve years of payments left %s outstanding" % GameState.fmt_money(Lending.total_owed()))
	print("  borrowed $20,000, repaid %s in total over the term" % GameState.fmt_money(owed0))

	# missing payments compounds and costs credit
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["last_income"] = 60000
	GameState.player["credit"] = 760
	Lending.borrow("bank", 20000)
	GameState.player["money"] = 0
	var before_owed := Lending.total_owed()
	var before_credit := Grit.credit()
	Lending.yearly()
	ok(Lending.total_owed() > before_owed, "missing a payment did not add interest")
	ok(Grit.credit() < before_credit, "missing a payment did not hurt the credit score")

	# net worth counts it
	ok(GameState.net_worth() < 0, "owing %s and holding nothing is not a negative net worth" % GameState.fmt_money(Lending.total_owed()))

	# --- fight betting
	GameState.new_life({"gender": "female", "country": "us"})
	GameState.player["age"] = 30
	GameState.player["money"] = 100000
	var cd := Fights.card()
	ok(cd.size() == 4, "the card has %d bouts" % cd.size())
	for b in cd:
		# odds have to be shortened by the book's cut, or betting is free money
		var fair_a := 1.0 / float(b["p_a"])
		ok(float(b["odds_a"]) < fair_a + 0.001, "%s pays better than fair odds" % b["a"])
		ok(float(b["odds_a"]) > 1.0 and float(b["odds_b"]) > 1.0, "a bout has odds of 1 or less")
	var m0 := int(GameState.player["money"])
	Fights.bet(str(cd[0]["id"]), "a", 1000)
	ok(int(GameState.player["money"]) == m0 - 1000, "the stake was not taken")
	ok((Fights._st()["bets"] as Array).size() == 1, "the bet was not recorded")
	EventEngine.pending.clear()
	Fights.yearly()
	ok((Fights._st()["bets"] as Array).is_empty(), "the bet did not settle at the turn of the year")
	ok(not EventEngine.pending.is_empty(), "settling a bet told the player nothing")
	# and you can be on the card yourself
	GameState.player["stats"]["health"] = 80.0
	var slot := Fights.own_slot()
	ok(bool(slot["ok"]), "a healthy 30-year-old cannot get on the undercard")
	ok(int(slot["purse"]) > 0, "the undercard pays nothing")
	GameState.player["age"] = 60
	ok(not bool(Fights.own_slot()["ok"]), "a 60-year-old was licensed to box")


# ---- #2
func _npcs() -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	GameState.player["age"] = 25
	for i in range(8):
		GameState.create_npc("friend", {"age": randi_range(20, 40), "closeness": randi_range(40, 60)})
	var made := 0
	for y in range(60):
		GameState.player["age"] = 25 + y
		EventEngine.pending.clear()
		NpcWorld.yearly()
		made = NpcWorld.links().size()
	ok(made >= 3, "sixty years among ten people produced only %d links between them" % made)
	var kinds := {}
	for l in NpcWorld.links():
		kinds[str(l["kind"])] = true
	ok(kinds.size() >= 2, "every link between NPCs came out the same kind")
	print("  npc links after 60 years: %d, kinds: %s" % [made, str(kinds.keys())])

	# they are visible on the person's page
	var some := str(NpcWorld.links()[0]["a"])
	ok(not NpcWorld.lines_for(some).is_empty(), "a link exists but does not show on the person")

	# the middle of the cast is no longer inert
	GameState.new_life({"gender": "male", "country": "us"})
	GameState.player["age"] = 30
	for i in range(5):
		GameState.create_npc("friend", {"age": 30, "closeness": 50})
	var beats := 0
	for i in range(40):
		if NpcWorld.neutral_beat():
			beats += 1
	ok(beats >= 30, "only %d of 40 attempts produced anything for a mid-closeness person" % beats)

	# and volatile people clash more than calm ones, which is the whole point of craziness
	var clashes_calm := 0
	var clashes_wild := 0
	for run in range(8):
		for pass_i in range(2):
			GameState.new_life({"gender": "male", "country": "us"})
			GameState.player["age"] = 30
			for i in range(6):
				var nid := GameState.create_npc("friend", {"age": 30, "closeness": 50})
				GameState.npcs[nid]["craziness"] = 5 if pass_i == 0 else 95
			for y in range(120):
				GameState.player["age"] = 30 + (y % 40)
				NpcWorld.yearly()
			for l in NpcWorld.links():
				if str(l["kind"]) in ["rivals", "fell_out"]:
					if pass_i == 0:
						clashes_calm += 1
					else:
						clashes_wild += 1
	ok(clashes_wild > int(float(clashes_calm) * 1.5), "volatile people (%d clashes) are not meaningfully more trouble than calm ones (%d)" % [clashes_wild, clashes_calm])
	print("  clashes among calm people: %d, among volatile people: %d" % [clashes_calm, clashes_wild])


# ---- #11
func _icons() -> void:
	ok(Icons.KINDS.size() >= 40, "only %d drawn icons" % Icons.KINDS.size())
	# a dwelling ladder that actually is one
	ok(Icons.for_housing("homeless", 0) == "tent", "no fixed address is not drawn as a tent")
	ok(Icons.for_housing("apartment", 0) == "flat_block", "a rented flat is not drawn as one")
	ok(Icons.for_housing("house", 100000) == "house", "an ordinary house is not drawn as a house")
	ok(Icons.for_housing("house", 3000000) == "mansion", "a three-million house is not drawn as a mansion")
	ok(Icons.for_housing("house", 12000000) == "estate", "a twelve-million house is not drawn as an estate")
	ok(Icons.for_property("Private island", 18000000) == "island", "a private island is not drawn as one")
	ok(Icons.for_property("Studio condo", 140000) == "flat_small", "a studio condo is not drawn small")
	ok(Icons.for_car("used") == "hatchback" and Icons.for_car("sports") == "sports", "cars do not map to their own shapes")
	# every mapping target has to exist, or the icon silently falls back to a plate
	for v in [0, 100000, 700000, 2500000, 8000000, 20000000]:
		ok(Icons.has(Icons.for_housing("house", v)), "for_housing(%d) returned an undrawn kind" % v)
		ok(Icons.has(Icons.for_property("Suburban house", v)), "for_property(%d) returned an undrawn kind" % v)
	# and they build without erroring
	for k in Icons.KINDS:
		var ic := Icons.make(str(k), 40.0)
		ok(ic != null, "%s could not be built" % k)
		ic.free()
	var kit := FileAccess.get_file_as_string("res://scenes/ui_kit.gd")
	ok(kit.find("Icons.has(icon.substr(1))") != -1, "rows cannot render a drawn icon")


# ---- #7 / #16: age-appropriate, non-repeating
func _relevance() -> void:
	var dir := DirAccess.open("res://data/events")
	var total := 0
	var aged := 0
	var loose: Array = []
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var evs = JSON.parse_string(FileAccess.get_file_as_string("res://data/events/" + f))
		if not (evs is Array):
			continue
		for ev in evs:
			total += 1
			var c: Dictionary = ev.get("conditions", {})
			if c.has("age"):
				aged += 1
			elif not bool(ev.get("followup_only", false)) and not bool(ev.get("twist", false)):
				loose.append(str(ev["id"]))
	ok(total > 500, "only %d events found" % total)
	ok(loose.is_empty(), "%d events can fire at any age and are not follow-ups: %s" % [loose.size(), str(loose)])
	print("  age gating: %d of %d events, %d unrestricted non-followups" % [aged, total, loose.size()])

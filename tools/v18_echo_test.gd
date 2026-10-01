extends Node

## v0.17 gate — the new systems are not islands. Each check changes something in
## one system and proves it moved something in another.

var failures: Array = []
var checks := 0


func ok(c: bool, m: String) -> void:
	checks += 1
	if not c:
		failures.append(m)
		push_error("V18: " + m)


func _ready() -> void:
	seed(1818)
	_money_to_everything()
	_body_to_health_system()
	_record_to_work_and_roads()
	_habits_to_body()
	_work_to_people()
	_paths_to_meta()
	print("V18 ECHO TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _fresh(age: int = 35) -> void:
	GameState.new_life({"gender": "female", "country": "us"})
	var p := GameState.player
	p["age"] = age
	p["money"] = 80000
	p["time_left"] = 12
	p["stats"]["smarts"] = 70.0


## Where you live and what you drive change what a year costs.
func _money_to_everything() -> void:
	_fresh()
	GameState.player["housing"] = "apartment"
	GameState.player["job"] = {"title": "Clerk", "field": "Office", "salary": 40000, "perf": 55.0, "years": 3, "boss": "", "coworkers": []}
	Tenancy.sync()
	var before := int(GameState.player["money"])
	var cheap := 0
	var dear := 0
	for kind in [0, 1]:
		_fresh()
		GameState.player["housing"] = "apartment"
		Tenancy.sync()
		Tenancy.st()["rent"] = 8000 if kind == 0 else 30000
		var m0 := int(GameState.player["money"])
		EventEngine._yearly_finances()
		if kind == 0:
			cheap = m0 - int(GameState.player["money"])
		else:
			dear = m0 - int(GameState.player["money"])
	ok(dear - cheap > 11000, "a $22,000 difference in rent moved the yearly bill by only $%d" % (dear - cheap))
	# a car adds insurance to the bill, and a young driver pays more than an older one
	var bills := {}
	for age in [19, 40]:
		_fresh(age)
		GameState.player["car"] = GameState.CARS.keys()[0]
		bills[age] = Transit.premium()
	ok(int(bills[19]) > int(bills[40]), "a nineteen-year-old pays no more for insurance than a forty-year-old")
	# location changes the commute
	var minutes := {}
	for region in ["ny", "tx"]:
		_fresh()
		GameState.player["region"] = region
		GameState.player["job"] = {"title": "Clerk", "field": "Office", "salary": 40000, "perf": 55.0, "years": 3, "boss": "", "coworkers": []}
		minutes[region] = Transit.base_minutes()
	ok(int(minutes["tx"]) > int(minutes["ny"]), "a city with trains and a county without have the same commute: %s" % minutes)
	print("  money: rent moves the bill by $%d; insurance at 19 $%d vs 40 $%d; commute %s" % [dear - cheap, int(bills[19]), int(bills[40]), minutes])


## How you live changes what your body can do, and the health system answers.
func _body_to_health_system() -> void:
	var cases := {}
	for kind in ["worn", "well"]:
		var hits := 0
		for i in range(600):
			_fresh(50)
			Expansion.ensure()
			var s := Body.st()
			s["fitness"] = 12.0 if kind == "worn" else 90.0
			s["sleep"] = 20.0 if kind == "worn" else 90.0
			s["diet"] = 15.0 if kind == "worn" else 90.0
			GameState.player["medical"]["pending"] = ""
			Expansion.medical_yearly()
			if str(GameState.player["medical"].get("pending", "")) != "":
				hits += 1
		cases[kind] = hits
	ok(int(cases["worn"]) > int(cases["well"]) * 1.3, "a worn body falls ill no more often than a well one: %s" % cases)
	# waiting for care costs health, and medication changes the money
	_fresh(60)
	Expansion.ensure()
	GameState.player["medical"]["conditions"]["hypertension"] = {"years": 3, "treated": 0, "controlled": false, "flares": 0}
	var m0 := int(GameState.player["money"])
	Care.st()["meds"]["hypertension"] = true
	Care.yearly()
	ok(int(GameState.player["money"]) < m0 or Care.system() == "free", "taking medication cost nothing")
	print("  body: illness onsets in 600 tries — worn %d, well %d" % [int(cases["worn"]), int(cases["well"])])


## What is on your record follows you to the job market and to the road.
func _record_to_work_and_roads() -> void:
	_fresh(30)
	var l := Market.openings("full")
	var target: Dictionary = {}
	for x in l:
		if str(x["locked"]) == "":
			target = x
			break
	var clean := float(Market.standing(target)["chance"])
	for i in range(4):
		Wanted.commit("burglary", true)
	var wanted := float(Market.standing(target)["chance"])
	ok(wanted < clean - 0.05, "a record made no difference to a job application: %.2f vs %.2f" % [clean, wanted])
	GameState.player["car"] = GameState.CARS.keys()[0]
	var with_stars := Transit.premium()
	Wanted.clear_all("")
	var without := Transit.premium()
	ok(with_stars > without, "being wanted does not raise insurance")
	# a gap on the CV, caused by not working, hurts the next application
	_fresh(30)
	var l2 := Market.openings("full")
	var t2: Dictionary = {}
	for x in l2:
		if str(x["locked"]) == "":
			t2 = x
			break
	var working := float(Market.standing(t2)["chance"])
	Market.st()["gap"] = 4
	ok(float(Market.standing(t2)["chance"]) < working, "years out of work did not hurt")
	print("  record: odds %.0f%% clean, %.0f%% wanted; insurance $%d vs $%d" % [clean * 100, wanted * 100, with_stars, without])


## Habits write to the body, the teeth and the wallet.
func _habits_to_body() -> void:
	var teeth := {}
	for diet in ["cook", "takeaway"]:
		_fresh(25)
		Keeping.st()["diet"] = diet
		Care.st()["dentist_age"] = 25
		for y in range(15):
			GameState.player["age"] = 25 + y
			Care.st()["dentist_age"] = 25 + y
			Care.yearly()
		teeth[diet] = float(Care.st()["teeth"])
	ok(float(teeth["cook"]) > float(teeth["takeaway"]) + 8.0, "diet did not reach the teeth: %s" % teeth)
	var food := {}
	for diet in ["cook", "takeaway"]:
		_fresh(25)
		Keeping.st()["diet"] = diet
		food[diet] = Keeping.costs()
	ok(int(food["takeaway"]) > int(food["cook"]) + 1500, "diet did not reach the wallet")
	_fresh(40)
	Keeping.st()["diet"] = "takeaway"
	for y in range(8):
		Body.yearly()
	var bad := float(Body.st()["diet"])
	_fresh(40)
	Keeping.st()["diet"] = "cook"
	for y in range(8):
		Body.yearly()
	ok(float(Body.st()["diet"]) > bad + 20.0, "diet did not reach the body account")
	print("  habits: teeth after 15 years — cooking %d, takeaway %d" % [int(teeth["cook"]), int(teeth["takeaway"])])


## The people at work are real people with the rest of your life attached.
func _work_to_people() -> void:
	_fresh(30)
	var before := GameState.npcs.size()
	Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
	ok(GameState.npcs.size() >= before + 3, "a new job brought only %d new people" % (GameState.npcs.size() - before))
	ok(Fixtures.employer() == str(GameState.player["job"]["employer_name"]), "the employer's name is not the same in the job and in the text")
	var txt := EventEngine.tokens("I work at {fx.work}.", {})
	ok(txt.find(Fixtures.employer()) != -1, "text does not know where you work: %s" % txt)
	# losing the job turns colleagues into former colleagues
	var crew := Workplace.crew()
	Actions.lose_job("quit")
	var former := 0
	for id in crew:
		if str(GameState.npcs[id]["relation"]) == "former_coworker":
			former += 1
	ok(former >= 1, "colleagues stayed colleagues after you left")
	# a union softens a redundancy
	var sev := {}
	for union in [false, true]:
		_fresh(40)
		Market.hire(str(Market.openings("full")[0]["id"]), 0.0)
		Workplace.w()["union"] = union
		GameState.player["job"]["years"] = 6
		GameState.player["job"]["salary"] = 60000
		var m0 := int(GameState.player["money"])
		Workplace._redundancy()
		sev[union] = int(GameState.player["money"]) - m0
	ok(int(sev[true]) > int(sev[false]) * 1.5, "a union did not improve the severance: %s" % sev)
	EventEngine.pending.clear()
	print("  work: a job brings people and a name; severance $%d without a union, $%d with" % [int(sev[false]), int(sev[true])])


## A road walked on a path is remembered by the whole game.
func _paths_to_meta() -> void:
	GameState.new_life({"gender": "female", "country": "uk", "life_path": "pirate"})
	GameState.player["age"] = 50
	Lives.life().merge({"rank": 4, "treasure": 90000}, true)
	var entry := GameState.finalize_death("old age")
	ok(GameState.get_counter("ending_sea_legend") == 1, "an ending left no counter")
	Goals.check(true)
	ok(Goals.has("end_sea_legend"), "the ending did not unlock its achievement")
	ok(str(entry["story"]).find("song of the ship") != -1, "the ending did not reach the life story")
	print("  paths: a Sea Legend ending unlocks its achievement and writes the story")

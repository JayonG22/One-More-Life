extends Node

## v1.3 gate — sharing, legacy, challenges and the other additions.

var failures: Array = []
var checks := 0


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)
		push_error("V21: " + msg)


func _ready() -> void:
	seed(2121)
	_endings_log()
	_share()
	_legacy()
	print("V21 TEST checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _pet_life(heroic: bool) -> Dictionary:
	GameState.new_life({"first": "Biscuit", "last": "", "gender": "female", "country": "uk", "life_path": "pet", "keep_family": true, "species": "dog", "origin": "loving"})
	if heroic:
		Lives.life()["heroics"] = 2
	GameState.player["age"] = 10
	return GameState.finalize_death("old age")


func _endings_log() -> void:
	Meta.meta["endings"] = {}
	var cat := Meta.endings_catalog()
	ok(cat.size() >= 40, "the endings catalog has only %d" % cat.size())
	for e in cat:
		ok(not bool(e["seen"]), "an ending was seen before any life")
	var e1 := _pet_life(true)
	Meta.record_death(e1)
	var seen := 0
	for e in Meta.endings_catalog():
		if bool(e["seen"]):
			seen += 1
	ok(seen == 1, "recording a death marked %d endings seen" % seen)
	print("  endings: %d in the catalog; recording a death marks exactly one" % cat.size())


func _share() -> void:
	var entry := _pet_life(true)
	var card: Control = preload("res://scenes/share_card.gd").build(entry)
	ok(card.size == Vector2(1080, 620), "the share card is the wrong size")
	var txt: String = preload("res://scenes/share_card.gd").share_text(entry)
	ok(txt.find("ONE MORE LIFE") != -1 and txt.find(str(entry["name"])) != -1, "the share text does not name the life")
	var hl: Array = preload("res://scenes/share_card.gd").highlights(entry, 3)
	ok(hl.size() <= 3, "too many highlights")
	card.free()
	print("  share: card built, text names the life")


func _legacy() -> void:
	Meta.meta["echoes"] = []
	# a heroic pet leaves an echo
	var e := _pet_life(true)
	Legacy.record(e)
	ok(Legacy.pending().size() == 1 and str(Legacy.pending()[0]["kind"]) == "pet", "a heroic pet left no echo")
	# every mode picks it up exactly once
	for mode in ["human", "pet", "prisoner", "guard"]:
		Legacy.list().clear()
		Legacy._add("pet", "Biscuit the dog, who was somebody's whole world", "Biscuit", {"species": "dog", "name": "Biscuit"})
		Legacy._add("convict", "A Person, who did time", "A Person", {"years": 7})
		match mode:
			"human": GameState.new_life({"gender": "female", "country": "uk"})
			"pet": GameState.new_life({"first": "Pip", "last": "", "gender": "male", "country": "uk", "life_path": "pet", "keep_family": true, "species": "cat", "origin": "loving"})
			"prisoner": GameState.new_life({"first": "Sam", "last": "Reed", "gender": "male", "country": "us", "life_path": "prisoner", "keep_family": true, "story": "first"})
			"guard": GameState.new_life({"first": "Kim", "last": "Doyle", "gender": "female", "country": "us", "life_path": "guard", "keep_family": true, "story": "career"})
		var used := 0
		for x in Legacy.list():
			if bool(x["used"]):
				used += 1
		ok(used == 2, "%s life used %d echoes, wanted 2" % [mode, used])
		var said := false
		for lg in GameState.log_years:
			for ln in lg["lines"]:
				if str(ln).find("Biscuit") != -1 or str(ln).find("inside") != -1 or str(ln).find("time") != -1:
					said = true
		ok(said, "%s life's log never mentioned its echoes" % mode)
	# used echoes are not used again
	GameState.new_life({"gender": "male", "country": "us"})
	for x in Legacy.pending():
		ok(false, "an echo survived two lives unused")
	# a direct heir does not take echoes
	Legacy._add("name", "the Name", "X", {"last": "Name"})
	var before := Legacy.pending().size()
	GameState.new_life({"gender": "male", "country": "us", "keep_family": true})
	ok(Legacy.pending().size() == before, "an heir consumed an echo")
	print("  legacy: echoes recorded, picked up once in every mode, never by an heir")

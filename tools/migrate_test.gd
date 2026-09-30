extends Node

func _ready() -> void:
	# Build a v0.1.0-shaped save: no career/fame/finance/meta fields, no world.
	GameState.new_life({"first": "Old", "last": "Save", "gender": "male", "country": "us"})
	for i in range(30):
		EventEngine.age_up()
		EventEngine.pending.clear()
	var d := GameState.to_dict()
	for k in ["career", "fame", "followers", "celebrity", "savings", "stocks", "crypto", "properties", "possessions", "licenses", "modifiers", "modified", "challenge", "badge", "jail_card_year", "hospitalized", "legacy", "life", "region", "billionaire", "act_year", "scars", "habits", "credit"]:
		d["player"].erase(k)
	d.erase("world")
	d["version"] = 1
	var f := FileAccess.open("user://save_current.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	# Load it with the new build.
	GameState.player = {}
	var ok := SaveManager.load_game()
	print("loaded old save: ", ok, " age ", GameState.player["age"])
	print("defaults filled: career=", GameState.player.get("career"), " fame=", GameState.player.get("fame"), " props=", GameState.player.get("properties"), " world_stocks=", GameState.world.get("stocks", {}).size())
	for i in range(20):
		EventEngine.age_up()
		EventEngine.pending.clear()
		if not GameState.is_alive():
			break
	print("played on to age ", GameState.player["age"], " net worth ", GameState.fmt_money(GameState.net_worth()))
	Careers.join("musician")
	Careers.start("musician", "solo")
	Finance.buy("stock", "NMB", 100)
	print("new systems on old save: career=", Careers.title(), " portfolio=", Finance.investments_value())
	print("v0.5 systems on old save: life=", Lives.kind(), " city=", Places.place_name(), " world=", World.active_list(), " card=", SaveManager.card(SaveManager.current_slot).get("name", "?"))
	SaveManager.save_game()
	print("resaved to slot ", SaveManager.current_slot, " cards ", SaveManager.cards().size())
	print("MIGRATION OK")
	get_tree().quit()

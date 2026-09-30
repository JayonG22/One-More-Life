extends Node

## Needs a real pre-v0.6 save sitting in user://saves/ to be meaningful. In a
## clean checkout there is nothing to load, so it reports that and stops rather
## than driving every menu with an empty player and printing a wall of errors.
func _ready() -> void:
	var ok := SaveManager.load_game()
	var p := GameState.player
	print("v0.5 save loaded: ", ok, "  age ", p.get("age"), "  npcs ", GameState.npcs.size())
	if not ok or p.is_empty():
		print("MIGRATION6 SKIPPED - no legacy save in user://saves/ to migrate")
		get_tree().quit(0)
		return
	print("social migrated: total=", Social.total(), " accounts=", Social.socials().keys())
	var menus := 0
	for id in GameState.npcs.keys():
		if GameState.npcs[id]["alive"]:
			var m: Dictionary = Bonds.menu(id)
			menus += 1 + m.get("rows", []).size()
	for root in ["root", "mine"]:
		menus += Shop.menu(root).get("rows", []).size()
	menus += Daily.menu("lottery").get("rows", []).size() + Social.menu("root").get("rows", []).size() + Dealer.menu("root").get("rows", []).size()
	print("new menus on old save: rows=", menus, "  lottery jackpot=", GameState.fmt_money(int(Daily.lottery()["jackpot"])))
	for i in range(20):
		EventEngine.age_up()
		EventEngine.pending.clear()
		if not GameState.is_alive():
			break
	print("played on to age ", GameState.player["age"], "  hidden=", GameState.player.get("hidden", {}).keys())
	SaveManager.save_game()
	var gp := 0
	for t in range(10):
		GameState.new_life({"country": ["us", "uk", "jp", "br", "ng"][t % 5]})
		gp += GameState.npcs_with("grandparent", false).size()
	print("grandparents across 10 fresh lives: ", gp)
	print("MIGRATION6 OK")
	get_tree().quit()

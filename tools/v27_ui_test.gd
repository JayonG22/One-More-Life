extends Node
var fails: Array = []
var main: Control
func ok(value: bool, message: String) -> void:
	if not value: fails.append(message)
func frames(n: int=6) -> void:
	for i in range(n): await get_tree().process_frame
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	var sections: TabContainer=main.screens["title"].find_child("TitleSections",true,false)
	ok(sections!=null and sections.get_tab_count()==3,"title categories missing")
	sections.current_tab=1
	await frames()
	ok(main.screens["title"].find_child("StarBtn",true,false).is_visible_in_tree(),"rewards route hidden on selected tab")
	GameState.settings["ui_scale"] = 1.75
	main._apply_display()
	await frames()
	ok(not main.screens["title"].find_child("TitleBrand",true,false).visible,"large-text title keeps the oversized brand column")
	var hub: Control = main.screens["title"].find_child("TitleHub",true,false)
	ok(hub.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x + 1,"large-text title overflows horizontally")
	GameState.settings["ui_scale"] = 1.0
	main._apply_display()
	await frames()
	main._open_tv_setup()
	await frames()
	main.tv_category="Anime"
	main._draw_tv_catalog()
	ok(main.tv_results.find_child("Story_lantern_league",true,false)!=null and main.tv_results.find_child("Story_stormpost",true,false)==null,"genre filter doesn't filter")
	main.tv_search="no such character"
	main._draw_tv_catalog()
	ok(main.tv_results.find_children("Story_*","Button",true,false).is_empty(),"empty search retains stale stories")
	main.tv_search="Pip"
	main.tv_category="All stories"
	main._draw_tv_catalog()
	ok(main.tv_results.find_child("Story_stormpost",true,false)!=null,"search can't find original character")
	main._close_popup()
	GameState.new_life({"gender":"female","country":"us"})
	GameState.player["age"]=30
	main._show("game")
	var child_id := GameState.create_npc("child",{"first":"Ari","age":20,"money":1234})
	EventEngine.pending.clear()
	main._open_live_child_switch()
	await frames()
	var child_button: Button = main.overlay_box.find_child("Child_"+child_id,true,false)
	ok(child_button != null,"child transfer has no selectable route")
	if child_button:
		child_button.emit_signal("pressed")
		await frames()
		var transfer_choices: Array = main.overlay_box.find_children("Choice*","Button",true,false)
		ok(transfer_choices.size()==2,"child transfer lacks confirmation")
		if transfer_choices.size()==2:
			transfer_choices[-1].emit_signal("pressed")
			await frames()
			ok(GameState.player["first"]=="Ari" and GameState.player["age"]==20 and GameState.player["money"]==1234 and not main.popup_open,"confirmed child transfer does not activate their current life")
			ok(SaveManager.card(SaveManager.current_slot).get("age",0)==20,"confirmed child transfer was not saved")
	main._confirm_end_life()
	ok(GameState.is_alive() and main.popup_open,"opening end-life confirmation ends the life")
	main._close_popup()
	var callback_count:= {"n":0}
	var done:=func(_s:float,_d:Dictionary): callback_count["n"]+=1
	main._on_minigame("fight",{"skill":50,"difficulty":1},done)
	main._mg_play("fight",{"skill":50,"difficulty":1},done)
	await frames()
	var help: Button=main.mg_box.find_child("MinigameHelp",true,false)
	help.emit_signal("pressed")
	await frames()
	ok(main.mg_game.process_mode==Node.PROCESS_MODE_DISABLED and not main.mg_holder.visible,"help doesn't pause and hide active board")
	help.emit_signal("pressed")
	ok(main.mg_game.process_mode==Node.PROCESS_MODE_INHERIT and main.mg_holder.visible,"resume doesn't restore the game")
	main._mg_finish(done,0.5,{})
	main._mg_finish(done,0.5,{})
	ok(callback_count["n"]==1,"minigame callback settles twice")
	var g: MinigameGamble=load("res://scenes/minigames/mg_g_wheel.gd").new()
	g.setup({"bet":100,"money":300,"single":true})
	add_child(g)
	await frames()
	g.settle(200,"first")
	g.settle(200,"duplicate")
	ok(g.total_stake==100 and g.total_won==200 and g.rounds==1,"casino settles a round twice")
	g.queue_free()
	var search_game=load("res://scenes/minigames/mg_pr_shakedown.gd").new()
	search_game.setup({})
	add_child(search_game)
	await frames()
	for key in [KEY_0,KEY_MINUS,KEY_EQUAL]:
		var event:=InputEventKey.new(); event.keycode=key; event.pressed=true
		search_game._unhandled_input(event)
	ok(search_game.picked.has(9) and search_game.picked.has(10) and search_game.picked.has(11),"last three search items inaccessible by keyboard")
	search_game.queue_free()
	main._confirm_end_life()
	var buttons: Array = main.overlay_box.find_children("Choice*", "Button", true, false)
	if buttons.size()>1:
		buttons[-1].emit_signal("pressed")
		await frames()
		ok(not GameState.is_alive() and GameState.player["cause"]=="suicide","confirmed end-life action does not close the life")
	else: ok(false,"end-life confirmation buttons missing")
	GameState.new_life({"life_path":"tv","character":"aang","gender":"male","country":"us"})
	ok(TVLife.menu("character")["title"]!=TVLife.menu("journal")["title"] and TVLife.menu("arc")["rows"].size()==10,"Story Life tabs still share one panel")
	print("V27 UI TEST failures=%d" % fails.size())
	for fail in fails: print("FAIL: ",fail)
	get_tree().quit(1 if not fails.is_empty() else 0)

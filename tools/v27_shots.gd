extends Node
var main: Control
var output := OS.get_environment("OML_SCREENSHOT_DIR").path_join("v27")
func shot(label: String) -> void:
	for i in range(15): await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(label+".png"))
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	get_window().size=Vector2i(1600,900)
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await shot("title")
	var sections: TabContainer=main.screens["title"].find_child("TitleSections",true,false)
	sections.current_tab=1
	await shot("rewards")
	main._open_tv_setup()
	await shot("stories")
	main._close_popup()
	for key in ["light","superhero","celebrity","royal"]:
		ThemeManager.apply(key)
		await shot("theme_"+key)
	ThemeManager.apply("ink")
	GameState.new_life({"gender":"female","country":"us","first":"Ada","last":"Quill"})
	GameState.player["age"]=40
	GameState.player["money"]=100000
	main._show("game")
	EventEngine.pending.clear()
	main._on_minigame("fight",{"skill":50,"difficulty":1},func(_s,_d):pass)
	main._mg_play("fight",{"skill":50,"difficulty":1},func(_s,_d):pass)
	await shot("fight")
	main.mg_box.find_child("MinigameHelp",true,false).emit_signal("pressed")
	await shot("minigame_help")
	main._mg_finish(func(_s,_d):pass,0.5,{})
	GameState.create_npc("child",{"first":"Ari","last":"Quill","age":22,"money":2300})
	GameState.create_npc("child",{"first":"Sam","last":"Quill","age":12,"money":45})
	main._open_live_child_switch()
	await shot("child_switch")
	main._close_popup()
	EventEngine._enqueue(ContentDB.events_by_id["mature.murder_offer"],{})
	main._pump()
	await shot("mature_decision")
	print("V27 SCREENSHOTS DONE")
	get_tree().quit()

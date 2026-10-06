extends Node
var main: Control
var failures: Array = []
var checks := 0
func frames(n: int = 8) -> void:
	for i in range(n): await get_tree().process_frame
func ok(value: bool, text: String) -> void:
	checks+=1
	if not value: failures.append(text)
func shot(name: String) -> void:
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/v29"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	GameState.new_life({"first":"Morgan","last":"Vale","gender":"female","country":"us"})
	GameState.player["age"]=40
	GameState.player["money"]=10000000
	GameState.player["time_left"]=100
	for kind in Ventures.TYPES: Ventures.acquire(kind)
	Ventures.act("room","cards")
	Ventures.act("exhibit","local")
	Ventures.act("recruit","agency")
	Ventures.start_luxury()
	Household.state()
	Creator.act("fan_open")
	EventEngine.pending.clear()
	main._show("game")
	GameState.player["possessions"].append({"name":"Old kindness gift","value":100,"kind":"gift","note":"A memory from an older save."})
	main._open_panel(main._panel_possessions,true)
	await frames(20)
	ok(main.g["panel_title"].text=="Possessions","legacy gift possessions panel failed")
	main._panel_back()
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		await frames()
		for key in ["venue:root","venue:casino","venue:museum","venue:agency","venue:luxury","creator:studio","creator:fans","home:root"]:
			main.MP.open(key)
			await frames(20)
			var panel: Control = main.g["panel"]
			var rect := panel.get_global_rect()
			ok(rect.position.x>=-1 and rect.end.x<=get_viewport().get_visible_rect().size.x+1,"panel outside viewport: "+key)
			var buttons := panel.find_children("*","Button",true,false)
			ok(buttons.size()>1,"empty panel: "+key)
			for button in buttons:
				if not button.is_visible_in_tree(): continue
				ok(button.size.x+2>=button.get_combined_minimum_size().x,"clipped button: "+key+" "+button.text)
			if scale==1.0 and key in ["venue:casino","creator:studio","home:root"]: await shot(key.replace(":","-"))
			main._panel_back()
	GameState.settings["ui_scale"]=1.0
	print("V29 UI TEST checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("FAIL: "+str(failure))
	get_tree().quit(0 if failures.is_empty() else 1)

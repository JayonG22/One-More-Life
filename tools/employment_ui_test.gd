extends Node
var main: Control
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func text(node: Node) -> String:
	var result := ""
	for label in node.find_children("*","Label",true,false): result+="\n"+label.text
	return result
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=100000
	Actions.hire("appliance_repair")
	EventEngine.pending.clear(); EventEngine.displayed.clear()
	main._show("game"); await frames()
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		main._open_panel(func(): main.MP.show("employment:root"),true); await frames()
		var first: Button=main.g["panel"].find_children("*","Button",true,false)[0]
		ok(first.theme_type_variation=="NavigationRow","career categories lack navigation design")
		first.pressed.emit(); await frames()
		ok(text(main.g["panel"]).contains("Ask your mentor"),"project category click failed")
		for key in ["progress","training","enrol:Trades","terms","money","history"]:
			main._open_panel(func(): main.MP.show("employment:"+key),true); await frames()
			ok(text(main.g["panel"])!="","career panel empty: "+key)
			var layout := true
			for button in main.g["panel"].find_children("*","Button",true,false):
				for label in button.find_children("*","Label",true,false):
					layout=layout and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(layout,"career text extends below button: "+key)
		if DisplayServer.get_name()!="headless":
			main._open_panel(func(): main.MP.show("employment:root"),true); await frames()
			await RenderingServer.frame_post_draw
			var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/employment"
			DirAccess.make_dir_recursive_absolute(directory)
			get_viewport().get_texture().get_image().save_png(directory+"/work-"+str(scale)+".png")
	for message in failures: print("FAIL: "+str(message))
	print("EMPLOYMENT UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

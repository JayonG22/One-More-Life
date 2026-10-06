extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=35; GameState.player["money"]=2000000; GameState.player["time_left"]=50
	Empires.start_business("restaurant"); EventEngine.pending.clear(); EventEngine.displayed.clear()
	GameState.create_npc("child",{"first":"Avery","age":19,"money":1000})
	Empires._business_yearly(); EventEngine.pending.clear(); EventEngine.displayed.clear()
	main._close_popup(); main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/operations"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		main._open_panel(func(): main.ep.business(),true); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Company operations"),"Operations not reachable inside actual Business panel")
		for page in ["","product","supplier","pricing","pay","scale","family","records","inventory","deliveries","facilities","research","cash"]:
			main._open_panel(func(): main.MP.show("journey:operations"+(":"+page if page!="" else "")),true); await frames()
			var buttons: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not buttons.is_empty(),"Empty company page: "+page)
			var fits := true
			for button in buttons:
				for label in button.find_children("*","Label",true,false): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(fits,"Button text clipped: "+page+" scale "+str(scale))
			if page=="": ok(buttons.size()<=17,"Root page flooded with settings")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+(page if page!="" else "overview")+"-"+str(scale)+".png")
	await frames(); main.queue_free(); await frames()
	print("OPERATIONS UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

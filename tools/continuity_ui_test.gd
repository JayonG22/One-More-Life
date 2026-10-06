extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func clear() -> void: EventEngine.pending.clear(); EventEngine.displayed.clear()
func fits(root: Control) -> bool:
	for button in root.find_children("*","Button",true,false):
		for label in button.find_children("*","Label",true,false):
			if label.get_global_rect().end.y>button.get_global_rect().end.y+1: return false
	return true
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/continuity"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.new_life({"country":"us","gender":"female","random_royalty":false})
		GameState.player["age"]=65; GameState.player["money"]=100000
		var heir := GameState.create_npc("child",{"first":"Ari","age":25,"money":321})
		Journey.modules["heritage"].st()["plan"]={"executor":FamilyChronicle.identity(GameState.npc(heir)),"discussed":true}
		var source := Journey.uid(); GameState.player["alive"]=false; GameState.continue_as(heir); clear()
		GameState.player["time_left"]=12; main._close_popup(); main._show("game")
		GameState.settings["ui_scale"]=scale; main._apply_display()
		main._open_panel(func(): main.MP.show("journey:heritage:estate:"+source),true); await frames()
		ok(main.g["panel_title"].text=="Estate receipt & duties" and fits(main.g["panel"]),"Estate account panel unavailable or clips")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/estate-"+str(scale)+".png")
		for stage in range(3):
			Journey.modules["heritage"].duties.start(source); await frames()
			ok(main.popup_open and fits(main.overlay_box),"Executor question is hidden or clips")
			var order: Array=Journey.state()["prompt"]["args"]["order"]
			var index: int=order.map(func(i): return int(i)).find(0)
			var button: Button=main.overlay_box.find_child("Choice"+str(index+1),true,false)
			ok(button!=null,"Executor answer button missing")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/executor-"+str(stage)+"-"+str(scale)+".png")
			if button: button.pressed.emit(); await frames()
			ok(Journey.modules["heritage"].duties.ensure(source)["stage"]==stage+1,"Actual executor button does not settle the step")
			main._close_popup(); clear()
		Journey.modules["learning"].st()["completed"]=[{"field":"Tech","route":"distance","units":3,"points":3,"year":GameState.year_now()-1}]
		GameState.player["education"]["hs_graduated"]=true
		main._open_panel(func(): main.MP.show("journey:learning:field:Tech"),true); await frames()
		ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="College upgrade"),"Prior learner has no college upgrade route")
		ok(fits(main.g["panel"]),"College upgrade preview clips")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/upgrade-"+str(scale)+".png")
		var learning=Journey.modules["learning"]
		main._close_popup(); clear(); learning.enrol("Tech","college"); main._close_popup(); clear()
		learning.internship(); main._close_popup(); clear()
		for step in range(2):
			learning.shift(); await frames()
			ok(main.popup_open and fits(main.overlay_box),"Field placement question is hidden or clips")
			ok(Journey.state()["prompt"]["args"]["scene"]==learning.placements["Tech"][step],"Rendered placement used a generic scenario")
			var button: Button=main.overlay_box.find_child("Choice1",true,false)
			ok(button!=null,"Field placement answer button missing")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/placement-"+str(step)+"-"+str(scale)+".png")
			if button: button.pressed.emit(); await frames()
			main._close_popup(); clear()
			GameState.player["age"]+=1; GameState.player["time_left"]=12
		main._open_panel(func(): main.MP.show("journey:learning:placements"),true); await frames()
		ok(main.g["panel_title"].text=="Placement record" and fits(main.g["panel"]),"Concluded placement record is hidden or clips")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/placement-record-"+str(scale)+".png")
	main.queue_free(); await frames()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("CONTINUITY UI checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)

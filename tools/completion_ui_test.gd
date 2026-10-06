extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(6): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30; GameState.player["money"]=100000; GameState.player["time_left"]=50
	GameState.player["job"]={"id":"doctor","field":"Healthcare","title":"Resident","salary":90000,"perf":50.0,"years":0,"rank":0}
	Employment.on_hire(); EventEngine.pending.clear(); EventEngine.displayed.clear()
	GameState.player["car"]=GameState.CARS.keys()[0]; Holdings.car()
	GameState.player["housing"]="house"; GameState.player["house_model"]="studio"
	var client := Employment.client_for("Healthcare",0); client["trust"]=80; client["completed"]=2
	Stewardship.accept(client["id"]); EventEngine.pending.clear(); EventEngine.displayed.clear()
	Household.state()["fatigue"]=60
	Journey.modules["collection"].st()["open"]=true
	Journey.modules["collection"].st()["items"]=[{"name":"A remarkably long title for an original painting about the harbour","value":10000}]
	main._close_popup(); main._show("game"); await frames()
	var person := GameState.create_npc("partner",{"age":30,"money":10000,"closeness":80})
	GameState.player["partner"]=person; GameState.player["living_together"]=true
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/completion"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		for panel in ["journey:seasons","journey:learning:field:Food","journey:people:person:"+person,"journey:heritage","journey:leisure","journey:funds","balance:root","recovery:root","home:root"]:
			main._open_panel(func(): main.MP.show(panel),true)
			await frames()
			var controls: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not main.g["panel"].find_children("*","Label",true,false).is_empty(),"Empty panel "+panel)
			var layout := true
			for button in controls:
				for label in button.find_children("*","Label",true,false): layout=layout and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(layout,"Text outside button "+panel+" scale "+str(scale))
			if panel=="balance:vehicles": ok(not main.g["panel"].find_children("*","Label",true,false).any(func(l): return l.text.begins_with("car:")),"Vehicle icon key rendered as text")
			if DisplayServer.get_name()!="headless" and true:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+panel.replace(":","-")+"-"+str(scale)+".png")
	GameState.settings["ui_scale"]=1.0; main._apply_display()
	for i in range(110): GameState.create_npc("friend",{"age":30,"closeness":45})
	var full: Dictionary=Journey.menu("people")
	var start := Time.get_ticks_usec()
	main._open_panel(func(): main.MP.rows_into(full),true); await frames()
	var original_ms := (Time.get_ticks_usec()-start)/1000.0
	start=Time.get_ticks_usec(); main._open_panel(func(): main.MP.show("journey:people"),true); await frames()
	var paged_ms := (Time.get_ticks_usec()-start)/1000.0
	ok(main.g["panel"].find_children("*","Button",true,false).size()<=55,"Long list creates every button at once")
	ok(main.g["panel"].find_children("*","Label",true,false).any(func(l): return l.text.contains("Page 1 of")),"Long list has no page indicator")
	main.MP.turn_page("journey:people",1); await frames()
	ok(main.MP.pages["journey:people"]==1 and main.g["panel"].find_children("*","Label",true,false).any(func(l): return l.text.contains("Page 2 of")),"Long list cannot reach later entries")
	print("LIST BENCHMARK rows=%d all_ms=%.2f paged_ms=%.2f" % [full["rows"].size(),original_ms,paged_ms])
	for message in failures: print("FAIL: "+str(message))
	print("COMPLETION UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

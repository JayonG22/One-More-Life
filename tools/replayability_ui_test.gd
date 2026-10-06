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
	main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/replayability"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		for panel in ["work","education","school","journal"]:
			if panel=="work": main._open_panel(main._panel_occupation,true)
			elif panel=="education": main._open_panel(func(): main._panel_majors("bachelor"),true)
			else: main._open_panel(func(): main.MP.show("journey:"+panel),true)
			await frames()
			var controls: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not main.g["panel"].find_children("*","Label",true,false).is_empty(),"Empty panel "+panel)
			var layout := true
			for button in controls:
				for label in button.find_children("*","Label",true,false): layout=layout and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(layout,"Text outside button "+panel+" scale "+str(scale))
			if DisplayServer.get_name()!="headless" and panel in ["work","education"]:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+panel+"-"+str(scale)+".png")
	main.visible=false
	GameState.settings["ui_scale"]=1.0; main._apply_display(); await frames()
	var canvas := Control.new(); canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(canvas)
	var background := ColorRect.new(); background.color=ThemeManager.c("bg"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(background)
	var entries: Array=[]
	for jd in ContentDB.jobs: entries.append([Icons.for_job(str(jd["id"])),str(jd["ranks"][0]),"job"])
	for major in ContentDB.majors: entries.append(["study:"+str(major["id"]),str(major["name"]),"study"])
	for id in GameState.CARS: entries.append([Icons.for_car(id),str(GameState.CARS[id]["name"]),"car"])
	var icons: Array=[]
	for i in range(entries.size()):
		var icon := Icons.make(entries[i][0],44)
		icon.position=Vector2(16+(i%13)*143,16+(i/13)*94); canvas.add_child(icon); icons.append(icon)
		var label := Label.new(); label.text=entries[i][1]; label.position=icon.position+Vector2(0,47); label.size=Vector2(139,36); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size",12); label.add_theme_color_override("font_color",ThemeManager.c("text")); canvas.add_child(label)
		label.max_lines_visible=2; label.clip_text=true
	await frames()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var screenshot := get_viewport().get_texture().get_image()
		screenshot.save_png(directory+"/occupation-education-vehicles.png")
		var hashes: Dictionary={}
		for i in range(entries.size()):
			var rect: Rect2=icons[i].get_global_rect()
			# Crop at the actual rendered scale rather than logical UI coordinates.
			var factor: Vector2=Vector2(screenshot.get_size())/get_viewport().get_visible_rect().size
			var image := screenshot.get_region(Rect2i(rect.position*factor,rect.size*factor))
			var digest := image.get_data().hex_encode().sha256_text()
			var key: String = str(entries[i][2])+digest
			ok(not hashes.has(key),"Identical rendered icons: "+str(entries[i][1])+" and "+str(hashes.get(key,"")))
			hashes[key]=entries[i][1]
	for message in failures: print("FAIL: "+str(message))
	print("REPLAYABILITY UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

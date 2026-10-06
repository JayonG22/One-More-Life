extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func clear() -> void:
	EventEngine.pending.clear(); EventEngine.displayed.clear()
func fits(root: Control) -> bool:
	for button in root.find_children("*","Button",true,false):
		for label in button.find_children("*","Label",true,false):
			if label.get_global_rect().end.y>button.get_global_rect().end.y+1: return false
	return true
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames()
	Goals.unlocked.disconnect(main._toast_ach); GameState.settings["effects"]=false
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/stories"
	DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display()
		main.tv_search=""; main.tv_category="All stories"; main._open_tv_setup(); await frames()
		ok(main.tv_results.find_children("Story_*","Button",true,false).size()==12,"Story library omits original campaigns")
		ok(fits(main.tv_results),"Story library buttons clip at "+str(scale))
		ok(main.overlay_box.find_children("*","ScrollContainer",true,false).size()==1,"Story library nests two scrolling panels")
		var scroll: ScrollContainer=main.overlay_box.get_node("PopupScroll")
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value); await frames()
		var last: Button=main.tv_results.find_children("Story_*","Button",true,false)[-1]
		ok(last.get_global_rect().end.y<=scroll.get_global_rect().end.y+1 and last.get_global_rect().position.y>=scroll.get_global_rect().position.y,"Last campaign is not reachable by scrolling")
		scroll.scroll_vertical=0; await frames()
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory+"/library-"+str(scale)+".png")
		for category in ["Original","Cartoon","Adult Animation","Anime","Crime / Action"]:
			main.tv_category=category; main._draw_tv_catalog(); await frames()
			var count: int=TVLife.catalog.filter(func(story): return story["category"]==category).size()
			ok(main.tv_results.find_children("Story_*","Button",true,false).size()==count,"Story genre route omits a campaign: "+category)
		main.tv_search="no such story"; main._draw_tv_catalog(); await frames()
		ok(main.tv_results.find_children("Story_*","Button",true,false).is_empty(),"No-result search retains stale stories")
		main.tv_category="All stories"
		for id in ["stormpost","moon_shift","lantern_league","last_receipt","missing_tuesday","detour_season"]:
			main.tv_search=TVLife.profile(id)["show"]; main._draw_tv_catalog(); await frames()
			ok(main.tv_results.find_children("Story_*","Button",true,false).size()==1 and main.tv_results.find_child("Story_"+id,true,false)!=null,"Search cannot find "+id)
		main._close_popup()
		for id in ["stormpost","last_receipt"]:
			GameState.new_life({"country":"us","life_path":"tv","character":id}); clear()
			main._show("game"); TVLife.advance(); await frames()
			ok(main.g["age"].text=="Scene 1","Story header mistakes character age for a scene number")
			ok(main.popup_open and main.overlay_box.find_children("Choice*","Button",true,false).size()==2,"Story choice panel is inaccessible: "+id)
			ok(fits(main.overlay_box),"Story choice text clips: "+id)
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(directory+"/"+id+"-"+str(scale)+".png")
			main._close_popup(); clear()
	main.queue_free(); await frames()
	for player in Fx.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream=null
	await get_tree().create_timer(0.2).timeout
	print("STORY LIBRARY UI checks=%d failures=%d %s" % [checks,failures.size(),str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)

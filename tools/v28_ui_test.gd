extends Node
var fails: Array = []
var main: Control
func ok(value:bool,message:String) -> void:
	if not value: fails.append(message)
func frames(n:int=6) -> void:
	for i in range(n): await get_tree().process_frame
func labels() -> String:
	return "\n".join(main.overlay_box.find_children("*","Label",true,false).map(func(l):return l.text))
func shot(name:String) -> void:
	await get_tree().create_timer(0.3).timeout
	var path := OS.get_environment("OML_SCREENSHOT_DIR")+"/v28"
	DirAccess.make_dir_recursive_absolute(path)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path+"/"+name+".png")
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	GameState.new_life({"first":"Morgan","last":"Vale","gender":"female","country":"us"})
	GameState.player["age"]=40
	var child := GameState.create_npc("child",{"first":"Ari","last":"Vale","age":20,"money":1234})
	GameState.npcs[child]["education"]={"stage":"graduated","hs_graduated":true,"degrees":[{"level":"bachelor","major":"english"}]}
	FamilyChronicle.remember(child,"We planned the move together.")
	var uid := FamilyChronicle.identity(GameState.npcs[child])
	main._show("game")
	main._show_family_tree()
	await frames()
	ok(main.overlay_box.find_children("*","Button",true,false).any(func(b):return b.text=="Family records"),"family tree has no records route")
	main._show_family_records()
	await frames()
	var search: LineEdit=main.overlay_box.find_child("FamilySearch",true,false)
	ok(search!=null and main.overlay_box.find_child("Family_"+uid,true,false)!=null,"family record missing")
	if search:
		search.text="No such person"
		search.emit_signal("text_changed",search.text)
		await frames()
		ok(main.overlay_box.find_children("Family_person_*","Button",true,false).is_empty() and labels().contains("No matching family record"),"search retains stale rows")
		search.text="Ari Vale"
		search.emit_signal("text_changed",search.text)
		await frames()
		var row: Button=main.overlay_box.find_child("Family_"+uid,true,false)
		ok(row!=null,"name search cannot find child")
		if row: row.emit_signal("pressed")
		await frames()
		ok(labels().contains("Ari Vale") and labels().contains("We planned the move together."),"record route opens wrong person or omits memory")
		ok(labels().contains("Bachelor · English"),"record hides recorded qualification")
	await shot("personal-record")
	main._close_popup()
	FamilyChronicle.before_year()
	GameState.player["money"]+=123
	main._show_year_summary()
	await frames()
	ok(labels().contains("123") and labels().contains("1 living children"),"year summary omits changes or family")
	await shot("annual-summary")
	main._show_family_records()
	await frames()
	await shot("family-records")
	main._close_popup()
	main._panel_person(child)
	ok(main.g["panel"].find_children("*","Button",true,false).any(func(b):return b.text.contains("Personal record")),"person screen has no record route")
	main._confirm_child_switch(child)
	await frames()
	ok(labels().contains("1234") or labels().contains("1,234"),"child transfer preview hides personal money")
	main._close_popup()
	GameState.settings["ui_scale"]=1.75
	main._apply_display()
	await frames()
	for method in ["_show_family_records","_show_year_summary"]:
		main.call(method)
		await frames(16)
		var rect: Rect2=main.overlay_frame.get_global_rect()
		ok(rect.position.x>=-1 and rect.end.x<=get_viewport().get_visible_rect().size.x+1,"large text popup overflows: "+method)
		main._close_popup()
	main._show_family_record(uid)
	await frames(16)
	var record_rect: Rect2=main.overlay_frame.get_global_rect()
	ok(record_rect.position.y>=-1 and record_rect.end.y<=get_viewport().get_visible_rect().size.y+1,"large text personal record overflows vertically")
	main._close_popup()
	GameState.settings["ui_scale"]=1.0
	main._apply_display()
	await frames()
	print("V28 UI TEST failures=%d" % fails.size())
	for fail in fails: print("FAIL: ",fail)
	get_tree().quit(1 if not fails.is_empty() else 0)

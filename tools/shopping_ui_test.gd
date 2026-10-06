extends Node
const U := preload("res://scenes/ui_kit.gd")
var main: Control
var checks := 0
var failures: Array=[]
func ok(value: bool, reason: String) -> void:
	checks+=1
	if not value: failures.append(reason)
func frames() -> void:
	for i in range(10): await get_tree().process_frame
func visible_text(node: Node) -> String:
	var result := ""
	for label in node.find_children("*","Label",true,false): result+="\n"+label.text
	return result
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/shopping"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
func _ready() -> void:
	main=load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	Goals.unlocked.disconnect(main._toast_ach)
	GameState.settings["effects"]=false
	GameState.new_life({"country":"us","gender":"female","random_royalty":false})
	GameState.player["age"]=30
	GameState.player["money"]=100000
	GameState.player["licenses"].append("driver")
	EventEngine.pending.clear()
	EventEngine.displayed.clear()
	main._show("game")
	await frames()
	for theme in ThemeManager.ORDER:
		ThemeManager.apply(theme)
		var themed: Theme=ThemeManager.build()
		for role in ["Row","NavigationRow","BulkRow"]:
			ok(themed.has_stylebox("normal",role),"missing button style in "+theme)
			var style: StyleBoxFlat=themed.get_stylebox("normal",role)
			ok(style.bg_color.get_luminance()<0.25,"overbright button in "+theme)
	ThemeManager.apply("ink")
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale
		main._apply_display()
		main._refresh_side()
		main._open_panel(main._panel_shop,true)
		await frames()
		var cash: int=GameState.player["money"]
		var first: Button=main.g["panel"].find_children("*","Button",true,false)[0]
		ok(first.theme_type_variation=="NavigationRow","category has action appearance")
		ok(visible_text(first).contains("OPEN"),"navigation lacks explicit marker")
		first.pressed.emit()
		await frames()
		ok(visible_text(main.g["panel"]).contains("Best Byte"),"category click failed")
		ok(GameState.player["money"]==cash,"browsing charged cash")
		main.MP.open("shop:samswoon")
		await frames()
		ok(visible_text(main.g["panel"]).contains("Pro camera"),"specialist inventory not rendered")
		ok(not visible_text(main.g["panel"]).contains("Game console"),"exclusive inventory not reflected in UI")
		for button in main.g["panel"].find_children("*","Button",true,false):
			ok(button.theme_type_variation=="Row","purchase row resembles navigation")
			for label in button.find_children("*","Label",true,false):
				if label.theme_type_variation in ["Bold","Dim"]:
					ok(label.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"row text cannot wrap")
					ok(label.size.y+1>=label.get_minimum_size().y,"row cuts off wrapped text")
					ok(label.get_global_rect().end.y<=button.get_global_rect().end.y+1,"text extends below button")
		await capture("electronics-"+str(scale))
		main._open_panel(func(): main.MP.show("shop:category:homes"),true)
		await frames()
		ok(visible_text(main.g["panel"]).contains("Pocket studio"),"home shopping missing")
		await capture("homes-"+str(scale))
		main._open_panel(func(): main.MP.show("comp:breeds:shop:dog"),true)
		await frames()
		ok(visible_text(main.g["panel"]).contains("Shiba Inu"),"breed chooser missing")
		await capture("breeds-"+str(scale))
		main._open_panel(func(): main._panel_activity_group("mind"),true)
		await frames()
		var bulk_seen := false
		for button in main.g["panel"].find_children("*","Button",true,false):
			if button.tooltip_text.begins_with("Gym."):
				ok(button.get_meta("interaction","")=="action","immediate gym action labelled as navigation")
				ok(not visible_text(button).contains("OPEN"),"immediate gym action has misleading OPEN marker")
			if button.get_meta("interaction","")=="bulk":
				bulk_seen=true
				ok(button.theme_type_variation=="BulkRow","bulk lacks distinct style")
				ok(visible_text(button).contains("BUNDLE"),"bulk lacks explicit marker")
		ok(bulk_seen,"bulk buttons not present in activity category")
		await capture("bundles-"+str(scale))
		main._open_panel(main._panel_housing,true)
		await frames()
		ok(not visible_text(main.g["panel"]).contains("Buy a house"),"Assets still has primary home purchase")
		main._open_panel(main._panel_vehicles,true)
		await frames()
		ok(not visible_text(main.g["panel"]).contains("New sedan"),"Assets still has vehicle store")
		main._open_panel(main._panel_assets,true)
		await frames()
		ok(visible_text(main.g["panel"]).contains("Finances"),"asset finance summary missing")
	print("SHOPPING UI TEST checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: print("FAIL: "+str(failure))
	get_tree().quit(0 if failures.is_empty() else 1)

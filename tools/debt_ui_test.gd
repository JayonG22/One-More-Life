extends Node
var checks := 0
var failures: Array=[]
func ok(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: "+message)
func frames() -> void:
	for i in range(8): await get_tree().process_frame
func _ready() -> void:
	GameState.settings["volume"]=0; GameState.settings["music_vol"]=0; GameState.settings["effects"]=false; GameState.settings["reduced_motion"]=true; Fx.apply_volumes()
	var main: Control=load("res://scenes/main.tscn").instantiate(); add_child(main); await frames(); Goals.unlocked.disconnect(main._toast_ach)
	GameState.new_life({"country":"us","gender":"female","random_royalty":false}); GameState.player["age"]=35; GameState.player["money"]=10000; GameState.player["time_left"]=50
	for lender in Lending.LENDERS:
		Lending.debts().append({"lender":lender,"principal":10000,"left":10000,"payment":2000,"rate":0.1,"term":5,"taken_age":35,"missed":0})
	Lending.state()
	for i in range(45): Lending.remember(GameState.player,Lending.debts()[0],"Recorded payment with its remaining balance",GameState.year_now()-i,100)
	EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup(); main._show("game"); await frames()
	var directory := OS.get_environment("OML_SCREENSHOT_DIR")+"/debt"; DirAccess.make_dir_recursive_absolute(directory)
	for scale in [1.0,1.75]:
		GameState.settings["ui_scale"]=scale; main._apply_display(); main._refresh_side()
		for page in ["employment:money","employment:loan_support","employment:loan_support:"+str(Lending.debts()[0]["uid"]),"employment:loan_history","employment:repay:0"]:
			main._open_panel(func(): main.MP.show(page),true); await frames()
			var buttons: Array=main.g["panel"].find_children("*","Button",true,false)
			ok(not buttons.is_empty(),"Empty finance page: "+page)
			var fits := true
			for button in buttons:
				for label in button.find_children("*","Label",true,false): fits=fits and label.get_global_rect().end.y<=button.get_global_rect().end.y+1
			ok(fits,"Finance button text clipped: "+page+" scale "+str(scale))
			if page=="employment:loan_history": ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return label.text=="Next page"),"Loan history lacks pagination")
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(directory+"/"+page.replace(":","-")+"-"+str(scale)+".png")
	# Use the real menu dispatcher, then restore the saved plan and render it.
	main._close_popup(); Employment.act("loan_support",{"uid":Lending.debts()[0]["uid"],"kind":"pause"})
	ok(Lending.debts()[0].get("support",{}).get("kind","")=="pause","Actual menu dispatcher cannot start a support plan")
	EventEngine.pending.clear(); EventEngine.displayed.clear(); main._close_popup(); await frames()
	main._open_panel(func(): main.MP.show("employment:loan_support:"+str(Lending.debts()[0]["uid"])),true); await frames()
	ok(main.g["panel"].find_children("*","Label",true,false).any(func(label): return "Arrangement already used" in label.text),"Used review has no visible reason")
	main.queue_free(); await frames()
	print("DEBT UI TEST checks=%d failures=%d" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

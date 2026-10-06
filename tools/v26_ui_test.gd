extends Node
var fails: Array = []
var main: Control
func ok(c: bool,m: String) -> void:
	if not c: fails.append(m)
func frames(n: int=5) -> void:
	for i in range(n): await get_tree().process_frame
func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	ok(not GameState.has_life(), "title preview creates a partial life")
	ok(main.screens["title"].find_child("TVLifeBtn",true,false)!=null,"fourth mode missing on title")
	main._open_tv_setup()
	await frames()
	ok(main.popup_open,"TVLife picker did not open")
	main.popup_open = false
	main.overlay.visible = false
	GameState.new_life({"gender":"female","country":"us"})
	GameState.settings["theme"]="ink"
	main._show("game")
	GameState.player["age"]=28
	GameState.player["prison"]=3
	main._refresh_side()
	await frames()
	ok(main.g["custody_banner"].visible,"normal-life imprisonment has no banner")
	ok(str(main.g["custody_label"].text).contains("3 years remaining"),"custody banner misses sentence")
	ok(ThemeManager.current=="custody","normal-life imprisonment did not change theme")
	GameState.player["prison"]=0
	main._refresh_side()
	await frames()
	ok(not main.g["custody_banner"].visible and ThemeManager.current=="ink","release did not restore preferred theme")
	for era in [1850,1920,1970]:
		GameState.new_life({"gender":"female","country":"us","life_path":"traveler","era":era})
		main._show("game")
		main._refresh_side()
		await frames()
		ok(main.g["setting_ribbon"].visible and str(main.g["setting_ribbon"].text).contains(str(era)),"timeline ribbon missing")
	GameState.new_life({"gender":"male","country":"us","life_path":"tv","character":"aang"})
	main._show("game")
	main._refresh_side()
	await frames()
	ok(main.g["age_btn"].text.contains("Next chapter"),"TVLife offers simulation year button")
	EventEngine.event_queued.disconnect(main._pump)
	EventEngine.pending.clear()
	for i in range(8):
		TVLife.advance()
		var inst := EventEngine.pop_next()
		EventEngine.resolve(inst,0)
	var e := GameState.finalize_death("the end of this story arc")
	main._fill_death(e)
	main._show("death")
	await frames()
	ok(not contains_label(main.screens["death"],"R.I.P.") and contains_label(main.screens["death"],"THE END"),"TVLife completion displays a grave")
	print("V26 UI TEST failures=%d" % fails.size())
	for f in fails: print("FAIL: ",f)
	get_tree().quit(1 if not fails.is_empty() else 0)
func contains_label(n: Node, s: String) -> bool:
	if n is Label and n.text==s: return true
	for c in n.get_children():
		if contains_label(c,s): return true
	return false

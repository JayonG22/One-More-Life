extends Node
var main: Control
var output := OS.get_environment("OML_SCREENSHOT_DIR")
func wait_frames(n: int = 12) -> void:
	for i in range(n): await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
func shot(label: String) -> void:
	await wait_frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(label + ".png"))
func fresh(opts: Dictionary = {}) -> void:
	main.popup_open = false
	main.overlay.visible = false
	EventEngine.pending.clear()
	main.panel_stack.clear()
	main.last_stats.clear()
	main.last_money = 0
	GameState.new_life({"gender":"female", "country":"us", "first":"Ada", "last":"Quill"}.merged(opts, true))
	if not Lives.is_type("tv"):
		GameState.player["age"] = 28
		GameState.player["money"] = 100000
	main._show("game")
func _ready() -> void:
	if output.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	get_window().size = Vector2i(1600,900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await shot("title")
	fresh()
	GameState.player["prison"] = 3
	main._refresh_side()
	main._render_top_panel()
	await shot("custody")
	GameState.player["prison"] = 0
	main._refresh_side()
	main._render_top_panel()
	await shot("release")
	fresh({"life_path":"traveler", "era":1850})
	await shot("timeline")
	fresh({"life_path":"tv", "character":"aang"})
	GameState.player["age"] = 0
	main._refresh_side()
	main._age_up()
	await shot("tv_chapter")
	fresh()
	for i in range(12):
		GameState.player["age"] += 1
		Finance._yearly_market()
	main._open_panel(main._panel_investments, true)
	await shot("investments")
	main.MP.open("daily:bet:rocket")
	await shot("custom_stake")
	main._close_popup()
	main._show_star_shop()
	main.star_tab = "avatar"
	main._show_star_shop()
	await shot("star_shop")
	print("V26 SCREENSHOTS DONE")
	get_tree().quit()

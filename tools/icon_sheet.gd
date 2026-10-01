extends Node

## A contact sheet of every drawn icon (run under xvfb).

func _ready() -> void:
	var dir := OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://icons"
	DirAccess.make_dir_recursive_absolute(dir)
	get_window().size = Vector2i(1400, 700)
	var bg := ColorRect.new()
	bg.color = ThemeManager.c("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 22)
	grid.position = Vector2(30, 24)
	add_child(grid)
	var first_new := Icons.KINDS.find("key")
	for i in range(first_new, Icons.KINDS.size()):
		var cell := VBoxContainer.new()
		cell.add_child(Icons.make(Icons.KINDS[i], 140.0))
		var l := Label.new()
		l.text = Icons.KINDS[i]
		l.add_theme_font_size_override("font_size", 14)
		cell.add_child(l)
		grid.add_child(cell)
	for j in range(4):
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/icons.png" % dir)
	print("ICON SHEET DONE")
	get_tree().quit()

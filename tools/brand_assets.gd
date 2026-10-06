extends SceneTree
func _init() -> void:
	var image := Image.new()
	var err := image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/brand/app-icon.svg"))
	if err!=OK: quit(1); return
	image.save_png("res://assets/brand/app-icon.png")
	quit()

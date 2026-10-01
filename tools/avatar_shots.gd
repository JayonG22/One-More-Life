extends Node
## Renders a sheet of avatars (run under xvfb).
func _ready() -> void:
	get_window().size = Vector2i(1500, 700)
	var bg := ColorRect.new()
	bg.color = Color("#10131c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	seed(11)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.position = Vector2(10, 10)
	add_child(grid)
	var ages := [2, 8, 16, 25, 40, 55, 70, 85]
	for i in range(30):
		var gender: String = ["male", "female", "nonbinary"][i % 3]
		var a := Avatar.random(gender)
		a["style"] = i % 15
		a["hair"] = (i * 2) % 6
		var v := AvatarView.new()
		v.custom_minimum_size = Vector2(140, 140)
		grid.add_child(v)
		v.setup(a, int(ages[i % ages.size()]), gender)
	for i in range(6): await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/gshots/avatars.png")
	print("AV DONE")
	get_tree().quit()

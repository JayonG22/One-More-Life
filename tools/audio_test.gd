extends Node

func _ready() -> void:
	var ids := ["tap", "choice", "back", "age", "good", "bad", "coin", "cash", "fanfare", "levelup", "death", "baby", "wedding", "siren", "crowd", "page", "error", "twist", "achieve"]
	var total := 0
	for t in ThemeManager.ORDER:
		ThemeManager.apply(t)
		for id in ids:
			var s: AudioStreamWAV = Fx._build(id)
			if s == null or s.data.size() < 100:
				push_error("bad sound %s/%s" % [t, id])
			else:
				total += s.data.size()
			Fx.play(id)
	print("AUDIO OK: %d sounds across %d themes, %.1f KB generated" % [ids.size() * ThemeManager.ORDER.size(), ThemeManager.ORDER.size(), total / 1024.0])
	get_tree().quit()

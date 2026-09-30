extends Node

## Measures the uncertainty layer across difficulties and across character types.
## godot --headless --path . res://tools/friction_probe.tscn

func _ready() -> void:
	seed(1234)
	print("=== band distribution by difficulty (identical average character) ===")
	for diff in ["classic", "real", "gritty"]:
		var tally := {"clean": 0, "snag": 0, "backfire": 0}
		for i in range(4000):
			GameState.new_life({"country":"us","stats":{"health":60,"smarts":55,"looks":55,"happiness":60,"stress":25}})
			GameState.player["difficulty"] = diff
			GameState.player["age"] = 30
			var choice := {"outcomes": [{"text":"x"}]}
			var outcome := {"text":"x","effects":{"happiness":6,"money":400}}
			var band: String = Friction.roll(choice, outcome, {})
			tally[band] = int(tally[band]) + 1
		var tot := 4000.0
		print("  %-8s clean %4.1f%%   snag %4.1f%%   backfire %4.1f%%" % [diff, tally["clean"]/tot*100.0, tally["snag"]/tot*100.0, tally["backfire"]/tot*100.0])

	print("\n=== who you are changes how often it lands (Real difficulty) ===")
	var people := [
		["capable & calm", {"health":85,"smarts":85,"looks":70,"happiness":80,"stress":10}, 40],
		["average", {"health":60,"smarts":55,"looks":55,"happiness":60,"stress":25}, 0],
		["struggling", {"health":30,"smarts":35,"looks":40,"happiness":20,"stress":80}, -40],
	]
	for person in people:
		var tally := {"clean": 0, "snag": 0, "backfire": 0}
		for i in range(4000):
			GameState.new_life({"country":"us","stats":person[1]})
			GameState.player["difficulty"] = "real"
			GameState.player["age"] = 30
			GameState.player["karma"] = int(person[2])
			var band: String = Friction.roll({"outcomes":[{"text":"x"}]}, {"text":"x","effects":{"happiness":6,"money":400}}, {})
			tally[band] = int(tally[band]) + 1
		var tot := 4000.0
		print("  %-16s clean %4.1f%%   snag %4.1f%%   backfire %4.1f%%" % [person[0], tally["clean"]/tot*100.0, tally["snag"]/tot*100.0, tally["backfire"]/tot*100.0])

	print("\n=== authored multi-outcome choices are nudged, not overridden ===")
	for label in ["single-outcome", "authored 2-outcome"]:
		var ch := {"outcomes":[{"text":"a"}]} if label == "single-outcome" else {"outcomes":[{"text":"a"},{"text":"b"}]}
		var tally := {"clean": 0, "snag": 0, "backfire": 0}
		for i in range(4000):
			GameState.new_life({"country":"us","stats":{"health":60,"smarts":55,"looks":55,"happiness":60,"stress":25}})
			GameState.player["difficulty"] = "real"
			GameState.player["age"] = 30
			var band: String = Friction.roll(ch, {"text":"x","effects":{"happiness":6}}, {})
			tally[band] = int(tally[band]) + 1
		var tot := 4000.0
		print("  %-20s clean %4.1f%%   snag %4.1f%%   backfire %4.1f%%" % [label, tally["clean"]/tot*100.0, tally["snag"]/tot*100.0, tally["backfire"]/tot*100.0])

	print("\n=== reaching further is harder to land (Real, average character) ===")
	for pair in [["small win", {"happiness":3}], ["big win", {"happiness":25}], ["fortune", {"money":40000}]]:
		var tally := {"clean": 0, "snag": 0, "backfire": 0}
		for i in range(4000):
			GameState.new_life({"country":"us","stats":{"health":60,"smarts":55,"looks":55,"happiness":60,"stress":25}})
			GameState.player["difficulty"] = "real"
			GameState.player["age"] = 30
			var band: String = Friction.roll({"outcomes":[{"text":"a"}]}, {"text":"x","effects":pair[1]}, {})
			tally[band] = int(tally[band]) + 1
		var tot := 4000.0
		print("  %-12s clean %4.1f%%   snag %4.1f%%   backfire %4.1f%%" % [pair[0], tally["clean"]/tot*100.0, tally["snag"]/tot*100.0, tally["backfire"]/tot*100.0])
	get_tree().quit(0)

@tool
extends EditorScript

## ONE MORE LIFE content validator.
## Run from the Godot editor before packaging a build. It validates JSON,
## duplicate ids, minimum choice/outcome depth, and scheduled-event references.

const EVENT_DIR := "res://data/events"

func _run() -> void:
	var files := DirAccess.get_files_at(EVENT_DIR)
	var ids := {}
	var schedules: Array = []
	var errors: Array = []
	var warnings: Array = []
	var event_count := 0
	var choice_count := 0
	var outcome_count := 0
	var scheduled_sources := {}
	for filename in files:
		if not filename.ends_with(".json"):
			continue
		var path := EVENT_DIR + "/" + filename
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed == null or not (parsed is Array):
			errors.append("%s: invalid JSON or root is not an array" % filename)
			continue
		for idx in range(parsed.size()):
			var e = parsed[idx]
			if not (e is Dictionary):
				errors.append("%s[%d]: event is not an object" % [filename, idx])
				continue
			var id := str(e.get("id", ""))
			if id == "":
				errors.append("%s[%d]: missing event id" % [filename, idx])
				continue
			if ids.has(id):
				errors.append("duplicate id %s (%s and %s)" % [id, ids[id], filename])
			else:
				ids[id] = filename
			event_count += 1
			var choices: Array = e.get("choices", [])
			if choices.size() < 3:
				warnings.append("%s: only %d choice(s)" % [id, choices.size()])
			choice_count += choices.size()
			for c in choices:
				if not (c is Dictionary):
					errors.append("%s: choice is not an object" % id)
					continue
				var outcomes: Array = c.get("outcomes", [])
				if outcomes.size() < 2:
					warnings.append("%s / %s: only %d outcome(s)" % [id, str(c.get("label", "?")), outcomes.size()])
				outcome_count += outcomes.size()
				for o in outcomes:
					if not (o is Dictionary):
						errors.append("%s: outcome is not an object" % id)
						continue
					if o.has("schedule"):
						var s = o["schedule"]
						if not (s is Dictionary) or str(s.get("event", "")) == "":
							errors.append("%s: malformed schedule" % id)
						else:
							schedules.append([id, str(s["event"])])
							scheduled_sources[id] = true
	for pair in schedules:
		if not ids.has(pair[1]):
			errors.append("%s schedules missing event %s" % [pair[0], pair[1]])
	var follow_pct := 0.0 if event_count == 0 else 100.0 * float(scheduled_sources.size()) / float(event_count)
	if follow_pct < 25.0:
		warnings.append("Only %.1f%% of events contain a scheduled follow-up; design target is >=25%%." % follow_pct)
	print("EVENT VALIDATOR: %d events · %d choices · %d outcomes · %.1f%% schedule follow-ups" % [event_count, choice_count, outcome_count, follow_pct])
	for w in warnings:
		push_warning(w)
	for err in errors:
		push_error(err)
	if errors.is_empty():
		print("EVENT VALIDATOR: PASS (%d warning%s)" % [warnings.size(), "" if warnings.size() == 1 else "s"])
	else:
		print("EVENT VALIDATOR: FAIL (%d error%s, %d warning%s)" % [errors.size(), "" if errors.size() == 1 else "s", warnings.size(), "" if warnings.size() == 1 else "s"])

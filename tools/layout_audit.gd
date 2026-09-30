extends Node

## LAYOUT AUDIT — measure the UI instead of looking at it.
##
## Screenshots tell you whether a thing looked wrong to one person on one run at
## one size. Geometry tells you whether it IS wrong, everywhere, every time.
##
## This walks the live scene tree after driving the game into each panel and
## checks the things a layout has to be true for:
##
##   1. nothing renders outside the window
##   2. nothing overflows its own container (except inside a scroller, which is
##      what a scroller is for)
##   3. no two siblings in a box overlap each other
##   4. nothing is squeezed below its own minimum size, which is what clips text
##   5. anything clickable is big enough to click
##   6. spacing comes from the 4px scale rather than from whatever number was
##      typed that afternoon
##
## Every failure prints the node path and the numbers, so it is a bug report
## rather than an opinion.

const GRID := 4.0             ## the base unit everything should sit on
const MIN_TAP := 32.0         ## smallest sensible height for something clickable
const EPS := 1.5              ## rounding slack, in pixels

var main: Control
var problems: Array = []
var checked := 0
var panels_done: Array = []


func _ready() -> void:
	seed(4242)
	get_window().size = Vector2i(1600, 900)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(5)
	_seed_life()
	await _f(4)

	await _audit("game", func(): pass)
	await _audit("activities", func(): main._open_panel(func(): main._panel_activity_group("become")))
	await _audit("become", func(): main._open_panel(main._panel_become))
	await _audit("loans", func(): main._open_panel(main._panel_loans))
	await _audit("fights", func(): main._open_panel(main._panel_fight_bets))
	await _audit("people", func(): main._open_panel(main._panel_relationships))
	await _audit("assets", func(): main._open_panel(main._panel_assets, true))
	await _audit("occupation", func(): main._open_panel(main._panel_occupation, true))

	# and at the sizes people actually run it at
	for res in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		get_window().size = res
		await _f(6)
		await _audit("become@%dx%d" % [res.x, res.y], func(): main._open_panel(main._panel_become))

	_report()


func _seed_life() -> void:
	# Drive it the way the game does, but do not depend on the new-life form
	# validating: what is being audited is the game screen and its panels.
	SaveManager.begin_new_life()
	GameState.new_life({"gender": "female", "country": "us", "first": "Nadia", "last": "Okonkwo"})
	main.panel_stack.clear()
	main._show("game")
	var p := GameState.player
	p["age"] = 34
	p["money"] = 3200000
	p["stats"]["smarts"] = 88.0
	p["stats"]["health"] = 74.0
	p["fame"] = 46.0
	p["housing"] = "house"
	p["house_value"] = 3100000
	p["car"] = "sports"
	p["last_income"] = 120000
	p["credit"] = 745
	for i in range(8):
		Become.note_activity("library")
	Wanted.commit("burglary", false)
	Wanted.commit("assault", true)
	var who := GameState.create_npc("crush", {"age": 33, "closeness": 66, "first": "Iris"})
	Actions.start_dating(who, false)
	Lending.borrow("bank", 40000)
	GameState.emit_changed()
	main._refresh_side()
	main._open_panel(main._panel_activities, true)
	main._render_top_panel()
	print("  setup: has_life=%s  g_keys=%d  panel_stack=%d  screen=%s" % [
		str(GameState.has_life()), main.g.size(), main.panel_stack.size(), main._current_screen()])


func _audit(label: String, open: Callable) -> void:
	open.call()
	await _f(6)
	var win := get_viewport().get_visible_rect().size
	var before := checked
	_walk(main, label, win, false)
	print("  [%s] %d controls" % [label, checked - before])
	panels_done.append(label)
	if label != "game":
		main._panel_back()
		await _f(3)


## Depth-first over every visible Control.
func _walk(node: Node, panel: String, win: Vector2, inside_scroll: bool) -> void:
	for child in node.get_children():
		if not (child is Control):
			_walk(child, panel, win, inside_scroll)
			continue
		var c: Control = child
		if not c.is_visible_in_tree():
			continue
		# The effects layer holds particles that are meant to be off-screen.
		if main != null and (c == main.fx_layer or c == main.mg_layer):
			continue
		var r := c.get_global_rect()
		var path := "%s/%s" % [panel, str(c.name)]
		var scroll_here := inside_scroll or (c is ScrollContainer)

		if r.size.x > 0.5 and r.size.y > 0.5:
			checked += 1

			# 1. nothing renders outside the window
			if not inside_scroll:
				if r.position.x < -EPS or r.position.y < -EPS or r.end.x > win.x + EPS or r.end.y > win.y + EPS:
					# a full-rect layer legitimately covers the window
					if not (absf(r.size.x - win.x) < 2.0 and absf(r.size.y - win.y) < 2.0):
						_flag(path, "outside the window: %s vs window %s" % [str(r), str(win)])

			# 2. nothing is smaller than the size it says it needs, which is what
			#    silently clips text and truncates buttons
			var need := c.get_combined_minimum_size()
			if need.x > r.size.x + EPS or need.y > r.size.y + EPS:
				_flag(path, "squeezed below its minimum: has %.0fx%.0f, needs %.0fx%.0f" % [
					r.size.x, r.size.y, need.x, need.y])

			# 3. clickable things have to be clickable
			if c is Button and not (c as Button).disabled:
				var short := minf(r.size.x, r.size.y)
				var area := r.size.x * r.size.y
				if short < 20.0 - EPS or area < MIN_TAP * MIN_TAP:
					_flag(path, "click target %.0fx%.0f is too small to hit" % [r.size.x, r.size.y])

		# 4. children of a box must not overlap each other
		if c is BoxContainer:
			_check_no_overlap(c, path)
			_check_separation(c, path)
			_check_rhythm(c, path)

		_walk(c, panel, win, scroll_here)


func _check_no_overlap(box: BoxContainer, path: String) -> void:
	var kids: Array = []
	for k in box.get_children():
		if k is Control and (k as Control).is_visible_in_tree():
			var kr := (k as Control).get_global_rect()
			if kr.size.x > 0.5 and kr.size.y > 0.5:
				kids.append([str(k.name), kr])
	for i in range(kids.size()):
		for j in range(i + 1, kids.size()):
			var a: Rect2 = kids[i][1]
			var b: Rect2 = kids[j][1]
			var ov := a.intersection(b)
			if ov.size.x > EPS and ov.size.y > EPS:
				_flag(path, "'%s' and '%s' overlap by %.0fx%.0f" % [kids[i][0], kids[j][0], ov.size.x, ov.size.y])


## Separation has to come from the 4px scale. A 13 or a 22 is somebody's
## afternoon rather than a decision.
func _check_separation(box: BoxContainer, path: String) -> void:
	var sep := box.get_theme_constant("separation")
	if sep <= 0:
		return
	if sep >= 64:
		return        # a deliberate large gap is a layout decision
	if not UIKit.SP.has(sep):
		_flag(path, "separation %d is not on the spacing scale %s" % [sep, str(UIKit.SP)])


## Distribution, not just fit. A list of rows should share a left edge and a
## height; a column of cards should share a width. Anything that does not is
## either a deliberate exception or the thing that makes a screen look untidy,
## and this cannot tell the difference, so it only flags a lone outlier among
## siblings that are otherwise uniform.
func _check_rhythm(box: BoxContainer, path: String) -> void:
	var rows: Array = []
	for k in box.get_children():
		if not (k is Control) or not (k as Control).is_visible_in_tree():
			continue
		var kr := (k as Control).get_global_rect()
		if kr.size.x < 2.0 or kr.size.y < 2.0:
			continue
		# separators and spacers are not part of the rhythm
		if k is HSeparator or k is VSeparator or (k is Control and (k as Control).get_child_count() == 0 and k.get_class() == "Control"):
			continue
		rows.append([str(k.name), kr])
	if rows.size() < 4:
		return
	var vertical := box is VBoxContainer
	# --- shared edge
	var edge_key := "left edge" if vertical else "top edge"
	var edges: Dictionary = {}
	for r in rows:
		var v: float = snappedf((r[1] as Rect2).position.x if vertical else (r[1] as Rect2).position.y, 1.0)
		edges[v] = int(edges.get(v, 0)) + 1
	_odd_one_out(edges, rows.size(), path, edge_key, vertical, true)
	# --- shared extent across the box
	var span_key := "width" if vertical else "height"
	var spans: Dictionary = {}
	for r in rows:
		var v2: float = snappedf((r[1] as Rect2).size.x if vertical else (r[1] as Rect2).size.y, 1.0)
		spans[v2] = int(spans.get(v2, 0)) + 1
	_odd_one_out(spans, rows.size(), path, span_key, vertical, false)


## If all but one of a set agree, the one is worth reporting. If they disagree
## generally, this is a mixed container and not a list, so say nothing.
func _odd_one_out(counts: Dictionary, total: int, path: String, what: String, vertical: bool, is_edge: bool) -> void:
	if counts.size() < 2:
		return
	var top_v := 0.0
	var top_n := 0
	for k in counts.keys():
		if int(counts[k]) > top_n:
			top_n = int(counts[k])
			top_v = float(k)
	if top_n < total - 1 or total - top_n != 1:
		return
	for k in counts.keys():
		if float(k) != top_v:
			_flag(path, "one child's %s is %.0f while the other %d share %.0f" % [what, float(k), top_n, top_v])


func _flag(path: String, msg: String) -> void:
	var line := "%s — %s" % [path, msg]
	if not problems.has(line):
		problems.append(line)


func _report() -> void:
	# group by kind so the output is a list of issues, not a wall
	var by_kind := {}
	for pr in problems:
		var s := str(pr)
		var kind := "other"
		for k in ["outside the window", "squeezed below", "overlap", "click target", "not on the"]:
			if s.find(k) != -1:
				kind = k
		by_kind[kind] = int(by_kind.get(kind, 0)) + 1
	print("LAYOUT AUDIT  viewport=%s  panels=%d  controls=%d  problems=%d" % [str(get_viewport().get_visible_rect().size), panels_done.size(), checked, problems.size()])
	for k in by_kind.keys():
		print("  %-22s %d" % [k, int(by_kind[k])])
	for pr in problems:
		print("  ! ", pr)
	get_tree().quit(1 if not problems.is_empty() else 0)


func _f(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame

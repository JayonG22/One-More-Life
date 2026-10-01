extends RefCounted

## Renders data-driven menus from Bonds, Daily, Shop and Social in the right panel.

const U := preload("res://scenes/ui_kit.gd")

var m


func _init(main_node) -> void:
	m = main_node


func _module(key: String):
	var pre := key.get_slice(":", 0)
	match pre:
		"bond": return Bonds
		"daily": return Daily
		"shop": return Shop
		"social": return Social
		"dealer": return Dealer
		"exp": return Expansion
		"threads": return LifeThreads
		"amb": return Ambition
		"real": return Real
		"pet": return Pets
		"pr": return Prison
	return null


func _rest(key: String) -> String:
	var i := key.find(":")
	return "" if i < 0 else key.substr(i + 1)


func open(key: String) -> void:
	m._open_panel(func(): show(key))


func show(key: String) -> void:
	var mod = _module(key)
	if mod == null:
		return
	var d: Dictionary = mod.menu(_rest(key))
	m._panel_header(str(d.get("icon", "")), str(d.get("title", "")))
	rows_into(d)


func rows_into(d: Dictionary) -> void:
	var info: Array = d.get("info", [])
	if not info.is_empty():
		var lines: Array = []
		for t in info:
			if str(t) != "":
				lines.append([str(t), "Dim", 15])
		if not lines.is_empty():
			m._add(m._info_card(lines))
	for r in d.get("rows", []):
		m._add(row(r))


func row(r: Dictionary) -> Button:
	var on: bool = r.get("on", true)
	if r.has("menu"):
		var mk: String = r["menu"]
		return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), func(): open(mk), on, true)
	if r.has("act"):
		var ak: String = r["act"]
		var arg = r.get("arg", null)
		return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), m._act(func(): run(ak, arg)), on, false)
	return U.row(str(r.get("icon", "")), str(r.get("name", "")), str(r.get("sub", "")), func(): pass, false, false)


func run(key: String, arg) -> void:
	var mod = _module(key)
	if mod != null:
		mod.act(_rest(key), arg)

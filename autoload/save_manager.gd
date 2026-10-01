extends Node

## Save slots with cards, backups and corruption recovery, plus the graveyard
## and settings.

const SLOTS := 12
## Tests set OML_USER_DIR so they write to a throwaway folder instead of using
## up the player's save slots.
var ROOT: String = OS.get_environment("OML_USER_DIR") if OS.get_environment("OML_USER_DIR") != "" else "user:/"
var DIR: String = ROOT + "/saves"
var INDEX_PATH: String = ROOT + "/saves/index.json"
var LEGACY_PATH: String = ROOT + "/save_current.json"
var GRAVE_PATH: String = ROOT + "/graveyard.json"
var SETTINGS_PATH: String = ROOT + "/settings.json"

var graveyard: Array = []
var current_slot := -1
var index: Dictionary = {}
var last_error := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	graveyard = _read(GRAVE_PATH, [])
	var s = _read(SETTINGS_PATH, {})
	if s is Dictionary:
		for k in s.keys():
			GameState.settings[k] = s[k]
	var idx = _read(INDEX_PATH, {})
	index = idx if idx is Dictionary else {}
	_migrate_legacy()


func _read(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed != null else fallback


func _write(path: String, data: Variant) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Could not write " + path)
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp)
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(abs_tmp, abs_path) == OK


func slot_path(i: int) -> String:
	return "%s/slot_%d.json" % [DIR, i]


func backup_path(i: int) -> String:
	return "%s/slot_%d.bak.json" % [DIR, i]


func _migrate_legacy() -> void:
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	var d = _read(LEGACY_PATH, {})
	if d is Dictionary and d.has("player"):
		var i := new_slot()
		if i < 0:
			return
		d["card"] = _card_from(d)
		if not _write(slot_path(i), d):
			return
		GameState.settings["last_slot"] = i
		save_settings()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_PATH))


func _save_index() -> void:
	_write(INDEX_PATH, index)


# ================================================================ slots

func slot_exists(i: int) -> bool:
	return FileAccess.file_exists(slot_path(i)) or FileAccess.file_exists(backup_path(i))


func new_slot() -> int:
	for i in range(1, SLOTS + 1):
		if not slot_exists(i):
			return i
	return -1


func card(i: int) -> Dictionary:
	var d = _read(slot_path(i), null)
	var recovered := false
	if not (d is Dictionary) or not d.has("player"):
		d = _read(backup_path(i), null)
		recovered = true
	if not (d is Dictionary):
		return {}
	var c: Dictionary = d.get("card", {})
	if c.is_empty() and d.has("player"):
		c = _card_from(d)
	c = c.duplicate()
	c["slot"] = i
	c["recovered"] = recovered and d.has("player")
	var meta: Dictionary = index.get(str(i), {})
	c["fav"] = meta.get("fav", false)
	c["label"] = meta.get("label", "")
	return c


func cards() -> Array:
	var out: Array = []
	for i in range(1, SLOTS + 1):
		if slot_exists(i):
			var c := card(i)
			if not c.is_empty():
				out.append(c)
	out.sort_custom(func(a, b):
		if bool(a["fav"]) != bool(b["fav"]):
			return bool(a["fav"])
		return float(a.get("updated", 0)) > float(b.get("updated", 0)))
	return out


func _card_from(d: Dictionary) -> Dictionary:
	var p: Dictionary = d.get("player", {})
	var lf: Dictionary = p.get("life", {"type": "human"})
	var kids := 0
	for n in d.get("npcs", {}).values():
		if n.get("relation", "") == "child":
			kids += 1
	var occ := ""
	if p.get("alive", true):
		occ = str(p.get("job", {}).get("title", "")) if not p.get("job", {}).is_empty() else ""
		if not p.get("career", {}).is_empty():
			occ = str(p["career"].get("id", "")).capitalize()
	var region := ""
	for r in Places.REGIONS.get(p.get("country", "us"), []):
		if r["id"] == p.get("region", ""):
			region = r["city"]
	var country: Dictionary = ContentDB.country(p.get("country", "us"))
	var lt := str(lf.get("type", "human"))
	var summary: Array = ["Gen %d" % int(p.get("generation", 1))]
	if lt != "human":
		summary.append(Lives.TYPES.get(lt, {}).get("icon", "") + " " + Lives.TYPES.get(lt, {}).get("name", ""))
	if occ != "":
		summary.append(occ)
	if kids > 0:
		summary.append("%d kid%s" % [kids, "" if kids == 1 else "s"])
	if p.get("business", {}).size() > 0:
		summary.append("owns " + str(p["business"].get("name", "a company")))
	var extra := {}
	if lt in ["pet", "prisoner", "guard"]:
		extra = _mode_card(lt, lf, p)
		if str(extra.get("occupation", "")) != "":
			occ = str(extra["occupation"])
	var card := {
		"name": "%s %s" % [p.get("first", "?"), p.get("last", "")],
		"age": int(p.get("age", 0)),
		"gender": p.get("gender", "male"),
		"face": int(p.get("face", 0)),
		"alive": bool(p.get("alive", true)),
		"country": country.get("name", ""),
		"flag": country.get("flag", ""),
		"city": region,
		"occupation": occ,
		"net_worth": int(d.get("card_net", 0)),
		"life": lt,
		"badge": p.get("badge", ""),
		"generation": int(p.get("generation", 1)),
		"difficulty": p.get("difficulty", "real"),
		"updated": Time.get_unix_time_from_system(),
		"summary": "  ·  ".join(summary),
		"cause": p.get("cause", ""),
	}
	card.merge(extra, true)
	card["occupation"] = occ
	return card


## How a pet, a prisoner or a guard is shown on a save card: no flag, no net worth.
func _mode_card(lt: String, lf: Dictionary, p: Dictionary) -> Dictionary:
	var out := {"hide_money": true}
	match lt:
		"pet":
			var sd: Dictionary = Pets.SPECIES.get(str(lf.get("species", "dog")), Pets.SPECIES["dog"])
			out["portrait"] = str(sd["icon"])
			out["place"] = "%s household" % str(p.get("last", "")).strip_edges() if str(lf.get("home", "")) in ["home", "farm", "kennel", "show"] else str(Pets.ORIGINS.get(str(lf.get("origin", "loving")), {}).get("name", ""))
			out["occupation"] = "%s %s" % [str(lf.get("breed", "")), str(sd["noun"])]
		"prisoner":
			out["portrait"] = "⛓️"
			out["place"] = str(lf.get("fac", {}).get("name", ""))
			out["occupation"] = "Inmate #%s" % str(lf.get("number", ""))
		"guard":
			out["portrait"] = "🗝️"
			out["place"] = str(lf.get("fac", {}).get("name", ""))
			out["occupation"] = str(Prison.RANK_G[clampi(int(lf.get("rank", 1)), 0, Prison.RANK_G.size() - 1)])
	return out


func has_save() -> bool:
	for c in cards():
		if c.get("alive", false):
			return true
	return false


func latest_slot() -> int:
	var last := int(GameState.settings.get("last_slot", -1))
	if last > 0 and slot_exists(last):
		return last
	var cs := cards()
	for c in cs:
		if c.get("alive", false):
			return int(c["slot"])
	return int(cs[0]["slot"]) if not cs.is_empty() else -1


func begin_new_life() -> bool:
	if current_slot > 0 and GameState.has_life() and not GameState.player.get("alive", true) and slot_exists(current_slot):
		GameState.settings["last_slot"] = current_slot
		save_settings()
		return true
	current_slot = new_slot()
	if current_slot < 0:
		last_error = "All %d save slots are full. Delete or overwrite one in Load Life first." % SLOTS
		return false
	GameState.settings["last_slot"] = current_slot
	save_settings()
	return true


func save_game() -> void:
	if not GameState.has_life():
		return
	if current_slot < 0:
		current_slot = new_slot()
		if current_slot < 0:
			return
	var d := GameState.to_dict()
	d["card_net"] = GameState.net_worth()
	d["card"] = _card_from(d)
	var path := slot_path(current_slot)
	if FileAccess.file_exists(path):
		var old := FileAccess.get_file_as_string(path)
		if JSON.parse_string(old) != null:
			var f := FileAccess.open(backup_path(current_slot), FileAccess.WRITE)
			if f:
				f.store_string(old)
				f.close()
	_write(path, d)
	GameState.settings["last_slot"] = current_slot
	save_settings()


func load_slot(i: int) -> bool:
	last_error = ""
	var d = _read(slot_path(i), null)
	if not (d is Dictionary) or not d.has("player"):
		d = _read(backup_path(i), null)
		if d is Dictionary and d.has("player"):
			last_error = "That save was damaged. Your previous save was restored instead."
		else:
			last_error = "That save is damaged and there's no backup to restore."
			return false
	GameState.from_dict(d)
	current_slot = i
	GameState.settings["last_slot"] = i
	save_settings()
	return true


func load_game() -> bool:
	_migrate_legacy()
	var i := latest_slot()
	return i > 0 and load_slot(i)


func delete_slot(i: int) -> void:
	for path in [slot_path(i), backup_path(i)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	index.erase(str(i))
	_save_index()
	if current_slot == i:
		current_slot = -1


func duplicate_slot(i: int) -> int:
	var j := new_slot()
	if j < 0:
		last_error = "No free slot to copy into."
		return -1
	var d = _read(slot_path(i), null)
	if not (d is Dictionary):
		return -1
	d["card"]["updated"] = Time.get_unix_time_from_system()
	_write(slot_path(j), d)
	var meta: Dictionary = index.get(str(i), {}).duplicate()
	meta["label"] = (str(meta.get("label", "")) if str(meta.get("label", "")) != "" else str(d["card"].get("name", ""))) + " (copy)"
	meta["fav"] = false
	index[str(j)] = meta
	_save_index()
	return j


func duplicate_current() -> int:
	save_game()
	return duplicate_slot(current_slot) if current_slot > 0 else -1


func set_label(i: int, label: String) -> void:
	var meta: Dictionary = index.get(str(i), {})
	meta["label"] = label.strip_edges().left(40)
	index[str(i)] = meta
	_save_index()


func toggle_fav(i: int) -> void:
	var meta: Dictionary = index.get(str(i), {})
	meta["fav"] = not meta.get("fav", false)
	index[str(i)] = meta
	_save_index()


func delete_save() -> void:
	if current_slot > 0:
		delete_slot(current_slot)


func add_to_graveyard(entry: Dictionary) -> void:
	graveyard.append(entry)
	_write(GRAVE_PATH, graveyard)


func save_settings() -> void:
	_write(SETTINGS_PATH, GameState.settings)

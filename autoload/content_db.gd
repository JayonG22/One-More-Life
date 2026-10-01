extends Node

const EVENT_FILES := [
	"childhood.json",
	"school.json",
	"teen.json",
	"adult.json",
	"work.json",
	"family.json",
	"elder.json",
	"prison.json",
	"followups.json",
	"everyday.json",
	"careers.json",
	"fame.json",
	"money.json",
	"law.json",
	"life.json",
	"more.json",
	"careers2.json",
	"empires.json",
	"connections.json",
	"twists.json",
	"lives.json",
	"v07.json",
	"v08.json",
	"real.json",
	"workbody.json",
	"arcs.json",
	"echoes.json",
	"pets.json",
	"prison_life.json",
]

var names: Dictionary = {}
var countries: Array = []
var majors: Array = []
var jobs: Array = []
var traits: Array = []
var interviews: Array = []
var licenses: Dictionary = {}
var events: Array = []
var events_by_id: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	names = _load_json("res://data/names.json", {})
	countries = _load_json("res://data/countries.json", [])
	majors = _load_json("res://data/majors.json", [])
	jobs = _load_json("res://data/jobs.json", [])
	traits = _load_json("res://data/traits.json", [])
	interviews = _load_json("res://data/interviews.json", [])
	licenses = _load_json("res://data/licenses.json", {})
	events.clear()
	events_by_id.clear()
	for f in EVENT_FILES:
		var list = _load_json("res://data/events/" + f, [])
		for e in list:
			if events_by_id.has(e["id"]):
				push_warning("Duplicate event id: " + e["id"])
			events.append(e)
			events_by_id[e["id"]] = e


func _load_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: " + path)
		return fallback
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Bad JSON in " + path)
		return fallback
	return parsed


func country(id: String) -> Dictionary:
	for c in countries:
		if c["id"] == id:
			return c
	return countries[0]


func job(id: String) -> Dictionary:
	for j in jobs:
		if j["id"] == id:
			return j
	return {}


func major(id: String) -> Dictionary:
	for m in majors:
		if m["id"] == id:
			return m
	return {}


func majors_of_level(level: String) -> Array:
	return majors.filter(func(m): return m["level"] == level)


func trait_info(trait_name: String) -> Dictionary:
	for t in traits:
		if t["name"] == trait_name:
			return t
	return {"name": trait_name, "icon": "•", "desc": ""}


func trait_names() -> Array:
	return traits.map(func(t): return t["name"])


func _bucket(country_id: String) -> Dictionary:
	var b: String = country(country_id).get("bucket", "en")
	return names["buckets"].get(b, names["buckets"]["en"])


func random_first(gender: String, country_id: String) -> String:
	var b := _bucket(country_id)
	var key := gender
	if gender != "male" and gender != "female":
		key = "male" if randf() < 0.5 else "female"
	var list: Array = b[key]
	return list[randi() % list.size()]


func random_last(country_id: String) -> String:
	var list: Array = _bucket(country_id)["last"]
	return list[randi() % list.size()]


func random_pet_name() -> String:
	var list: Array = names["pets"]
	return list[randi() % list.size()]

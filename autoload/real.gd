extends Node

## REAL — the front door to everyday life.
##
## Ties Tenancy, Transit and Keeping into the rest of the game: the yearly pass,
## the bill, the menus, the event conditions ("real") and the outcome operations
## ("real") that let authored events change a lease, a premium or an invitation.


func yearly() -> void:
	Tenancy.yearly()
	Transit.yearly()
	Keeping.yearly()
	Market.yearly()
	Workplace.yearly()
	Workplace.freelance_yearly()
	Care.yearly()
	Body.yearly()


## Extra yearly costs that these systems own (before the country multiplier).
func extra_costs() -> int:
	return Transit.costs() + Keeping.costs() + Tenancy.utilities() + Holdings.home_costs()


func menu(key: String) -> Dictionary:
	match key.get_slice(":", 0):
		"home": return Tenancy.menu()
		"go": return Transit.menu()
		"keep": return Keeping.menu()
		"work": return Workplace.menu()
		"care": return Care.menu()
		"body": return Body.menu()
		"arc": return Arcs.menu()
	return {"icon": "🏠", "title": "Everyday life", "rows": []}


func act(key: String, arg) -> void:
	match key:
		"repairs", "negotiate", "flatmate", "insulate", "insure", "move":
			Tenancy.act(key, arg)
		"mode", "cover", "service":
			Transit.act(key, arg)
		"union", "lunch", "politics", "resign", "retrain", "freelance", "pitch", "stop_freelance":
			Workplace.act(key, arg)
		"gp", "skip", "second", "meds", "physio", "eyes", "aid", "dentist", "crown", "dentures", "hearing":
			Care.act(key, arg)
		"routine", "rest":
			Body.act(key, arg)
		_:
			Keeping.act(key, arg)


func tag(t: String) -> bool:
	return Tenancy.tag(t) or Transit.tag(t) or Keeping.tag(t) or Market.tag(t) or Workplace.tag(t) or Care.tag(t) or Body.tag(t) or Arcs.tag(t)


func apply(ops: Dictionary) -> void:
	Tenancy.apply(ops)
	Transit.apply(ops)
	if ops.has("invite") and GameState.npcs.size() > 0:
		var ids: Array = Keeping._candidates(["friend", "best_friend", "sibling"])
		if not ids.is_empty():
			Keeping._add_invite(str(ops["invite"]), ids[randi() % ids.size()], randf() < 0.4)
	if ops.has("diet"):
		Keeping.st()["diet"] = str(ops["diet"])


## Every tag an event may name. The test walks the library against this list,
## so a typo in a condition fails loudly instead of making an event unreachable.
const KNOWN := ["renting", "flatmate", "no_flatmate", "damp", "boiler_old", "insured_home", "uninsured_home",
	"drives", "uninsured", "insured", "young_driver", "long_commute", "clean_record", "recent_crash",
	"invite", "lapsed_friend", "missed_funeral",
	"recently_rejected", "has_reference", "cv_gap", "job_seeking",
	"freelance", "union", "no_union", "company_shaky", "political_office",
	"waiting_list", "misdiagnosed", "on_meds", "poor_vision", "bad_teeth", "poor_hearing", "chronic", "symptoms",
	"unfit", "fit", "sleep_poor", "worn", "well_kept", "fallen", "road_walked"]
const PREFIXES := ["chapter:", "landlord:", "commute:", "tech:", "pretech:", "diet:", "plan:", "boss:", "culture:", "colleague:"]


func known_tag(t: String) -> bool:
	if KNOWN.has(t):
		return true
	for p in PREFIXES:
		if t.begins_with(p):
			return true
	return false

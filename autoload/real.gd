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


## Extra yearly costs that these systems own (before the country multiplier).
func extra_costs() -> int:
	return Transit.costs() + Keeping.costs() + Tenancy.utilities()


func menu(key: String) -> Dictionary:
	match key.get_slice(":", 0):
		"home": return Tenancy.menu()
		"go": return Transit.menu()
		"keep": return Keeping.menu()
	return {"icon": "🏠", "title": "Everyday life", "rows": []}


func act(key: String, arg) -> void:
	match key:
		"repairs", "negotiate", "flatmate", "insulate", "insure", "move":
			Tenancy.act(key, arg)
		"mode", "cover", "service":
			Transit.act(key, arg)
		_:
			Keeping.act(key, arg)


func tag(t: String) -> bool:
	return Tenancy.tag(t) or Transit.tag(t) or Keeping.tag(t)


func apply(ops: Dictionary) -> void:
	Tenancy.apply(ops)
	Transit.apply(ops)
	if ops.has("invite") and GameState.npcs.size() > 0:
		var ids: Array = Keeping._candidates(["friend", "best_friend", "sibling"])
		if not ids.is_empty():
			Keeping._add_invite(str(ops["invite"]), ids[randi() % ids.size()], randf() < 0.4)
	if ops.has("diet"):
		Keeping.st()["diet"] = str(ops["diet"])

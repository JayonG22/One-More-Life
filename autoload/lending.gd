extends Node

## LENDING — borrowing money, and what it costs to have borrowed it.
##
## The player had a `loan` field and a repayment schedule, but the only way to
## acquire debt was university tuition. You could not borrow to start a
## business, cover a hospital bill, or dig yourself deeper — which meant the
## credit score the game tracks had almost nothing to do.
##
## Four lenders, and which ones will talk to you depends entirely on your credit
## and your income. The last one will always say yes, which is the problem with it.

const LENDERS := {
	"bank": {
		"name": "High street bank", "icon": "🏦",
		"desc": "Sensible rates, a long form, and they will read your file properly.",
		"min_credit": 700, "rate": 0.06, "max_mult": 3.0, "min_income": 12000, "term": 10,
	},
	"credit_union": {
		"name": "Credit union", "icon": "🤝",
		"desc": "Smaller, kinder, and they want you to be a member for a year first.",
		"min_credit": 620, "rate": 0.09, "max_mult": 1.5, "min_income": 6000, "term": 8,
	},
	"online": {
		"name": "Online lender", "icon": "💻",
		"desc": "Approved in minutes. The rate is the reason it is that fast.",
		"min_credit": 540, "rate": 0.21, "max_mult": 1.0, "min_income": 3000, "term": 5,
	},
	"shark": {
		"name": "A man in a pub", "icon": "🦈",
		"desc": "No forms, no credit check, no paperwork of any kind. He will find you.",
		"min_credit": 0, "rate": 0.55, "max_mult": 0.8, "min_income": 0, "term": 3,
	},
}


func _p() -> Dictionary:
	return GameState.player


func state() -> Dictionary:
	var p := _p()
	if p.is_empty():
		return {}
	if not p.has("debts") or not (p["debts"] is Array):
		p["debts"] = []
	return {"list": p["debts"]}


func debts() -> Array:
	var st := state()
	return st.get("list", []) if not st.is_empty() else []


func total_owed() -> int:
	var t := 0
	for d in debts():
		t += int(d.get("left", 0))
	return t


## Yearly income the lender will look at.
func assessed_income() -> int:
	var p := _p()
	return maxi(int(p.get("last_income", 0)), 0)


## What each lender will lend, and why not if they will not.
func offer(id: String) -> Dictionary:
	var d: Dictionary = LENDERS.get(id, {})
	if d.is_empty():
		return {}
	var p := _p()
	var credit := Grit.credit()
	var income := assessed_income()
	var reasons: Array = []
	if int(p.get("age", 0)) < 18:
		reasons.append("You have to be 18")
	if credit < int(d["min_credit"]):
		reasons.append("Credit %d needed, yours is %d" % [int(d["min_credit"]), credit])
	if income < int(d["min_income"]):
		reasons.append("Income of %s needed, yours was %s" % [GameState.fmt_money(int(d["min_income"])), GameState.fmt_money(income)])
	if id == "credit_union" and int(p.get("age", 0)) - int(p.get("cu_member_since", 999)) < 1:
		pass
	if int(p.get("bankrupt_until", -1)) > int(p.get("age", 0)) and id != "shark":
		reasons.append("You are bankrupt until %d" % int(p["bankrupt_until"]))
	# Already borrowing from this lender is a reason on its own.
	for ex in debts():
		if str(ex.get("lender", "")) == id:
			reasons.append("You already owe them")
			break
	var cap := 0
	if id == "shark":
		cap = maxi(5000, int(float(maxi(income, 8000)) * float(d["max_mult"])))
	else:
		cap = int(float(income) * float(d["max_mult"]))
	cap = int(round(cap / 500.0)) * 500
	return {
		"id": id, "ok": reasons.is_empty() and cap >= 500,
		"reasons": reasons, "cap": cap,
		"rate": float(d["rate"]), "term": int(d["term"]),
	}


func offers() -> Array:
	var out: Array = []
	for id in LENDERS.keys():
		var o := offer(str(id))
		o["def"] = LENDERS[id]
		out.append(o)
	return out


## Borrow. The yearly payment is fixed at signing, which is what makes a bad rate
## something you live with rather than something you can wriggle out of.
func borrow(id: String, amount: int) -> void:
	var o := offer(id)
	if o.is_empty() or not bool(o["ok"]):
		return
	var amt := clampi(amount, 500, int(o["cap"]))
	var d: Dictionary = LENDERS[id]
	var term := int(o["term"])
	var rate := float(o["rate"])
	var total := int(round(float(amt) * (1.0 + rate * float(term))))
	var yearly_pay := int(ceil(float(total) / float(term)))
	var p := _p()
	p["money"] = int(p["money"]) + amt
	debts().append({
		"lender": id, "principal": amt, "left": total, "payment": yearly_pay,
		"rate": rate, "taken_age": int(p.get("age", 0)), "missed": 0,
	})
	GameState.counter("loans_taken")
	GameState.add_log("I borrowed %s from %s. %s a year for %d years." % [
		GameState.fmt_money(amt), str(d["name"]).to_lower(),
		GameState.fmt_money(yearly_pay), term])
	if id == "shark":
		GameState.change_stat("stress", 10.0)
		GameState.add_log("He did not write anything down, which is the part that worries me.")
	Grit.change_credit(-8)
	Moments.fire("money_gain", 0.6)


## Pay early, in full, if you can.
func settle(index: int) -> void:
	var list := debts()
	if index < 0 or index >= list.size():
		return
	var d: Dictionary = list[index]
	var owed := int(d["left"])
	var p := _p()
	if int(p["money"]) < owed:
		return
	p["money"] = int(p["money"]) - owed
	list.remove_at(index)
	GameState.add_log("I cleared the whole thing: %s, gone." % GameState.fmt_money(owed))
	Grit.change_credit(30)
	Moments.fire("success", 0.7)


func yearly() -> void:
	var st := state()
	if st.is_empty() or not GameState.is_alive():
		return
	var p := _p()
	var list: Array = st["list"]
	var i := list.size() - 1
	while i >= 0:
		var d: Dictionary = list[i]
		var pay := int(d["payment"])
		var left := int(d["left"])
		var due := mini(pay, left)
		if int(p["money"]) >= due:
			p["money"] = int(p["money"]) - due
			d["left"] = left - due
			d["missed"] = 0
			if int(d["left"]) <= 0:
				GameState.add_log("Last payment on the %s loan. That is finished." % str(LENDERS[str(d["lender"])]["name"]).to_lower())
				Grit.change_credit(25)
				list.remove_at(i)
				i -= 1
				continue
		else:
			d["missed"] = int(d.get("missed", 0)) + 1
			# Interest on a missed payment, and then the lender's own response.
			d["left"] = int(round(float(left) * (1.0 + float(d["rate"]) * 0.5)))
			Grit.change_credit(-22)
			GameState.change_stat("stress", 8.0)
			_missed(d, int(d["missed"]))
		i -= 1


func _missed(d: Dictionary, times: int) -> void:
	var id := str(d["lender"])
	var nm := str(LENDERS[id]["name"])
	if id == "shark":
		GameState.add_log("I could not pay him. He was very calm about it, which was worse.")
		if times >= 2:
			# The man in the pub does not send letters.
			EventEngine.push_decision({
				"id": "_loan_shark", "icon": "🦈", "title": "He came to the house",
				"text": "He is on the doorstep and he is not angry, and he has brought somebody with him who has not spoken.",
				"twist": true,
				"choices": [
					{"label": "Give him everything you have",
					 "outcomes": [
						{"text": "I emptied the account into his hands in the hallway. He counted it and said we were fine for now.", "weight": 2, "lose_money_pct": 0.9, "effects": {"stress": 20}},
						{"text": "I gave him everything and it was not enough to matter, and he told me what the interest was now.", "weight": 1, "lose_money_pct": 0.9, "effects": {"stress": 30, "happiness": -12}}]},
					{"label": "Tell him you need more time",
					 "outcomes": [
						{"text": "He gave me six months. He was extremely precise about the date.", "weight": 2, "effects": {"stress": 25}},
						{"text": "He did not give me more time.", "weight": 2, "effects": {"health": -25, "stress": 30}, "scar": "facial_scar"}]},
					{"label": "Go to the police",
					 "outcomes": [
						{"text": "I reported him. They knew exactly who he was and had been waiting for somebody to say so.", "weight": 1, "effects": {"karma": 10, "stress": 15}, "flags": ["shark_reported"]},
						{"text": "I reported him, and nothing happened for four months, and then something did.", "weight": 2, "effects": {"health": -20, "stress": 30}, "scar": "haunted"}]},
				]}, {})
	else:
		GameState.add_log("I missed the payment to %s. The letter used the word 'default'." % nm.to_lower())
		if times >= 3:
			GameState.add_log("%s has passed my file to a collections agency." % nm)
			Grit.change_credit(-40)


func summary_lines() -> Array:
	var out: Array = []
	for d in debts():
		var l: Dictionary = LENDERS[str(d["lender"])]
		out.append(["%s %s" % [str(l["icon"]), str(l["name"])],
			"%s left · %s a year%s" % [GameState.fmt_money(int(d["left"])),
				GameState.fmt_money(int(d["payment"])),
				"  ⚠️ %d missed" % int(d["missed"]) if int(d.get("missed", 0)) > 0 else ""]])
	return out

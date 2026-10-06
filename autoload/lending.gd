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
	ensure_record(p)
	return {"list": p["debts"]}

func ensure_record(p: Dictionary) -> void:
	if not p.get("debts",[]) is Array: p["debts"]=[]
	if not p.has("debts"): p["debts"]=[]
	for debt in p["debts"]:
		if str(debt.get("uid",""))=="":
			p["loan_serial"]=int(p.get("loan_serial",0))+1
			debt["uid"]=FamilyChronicle.identity(p)+":loan:"+str(p["loan_serial"])
		else:
			p["loan_serial"]=maxi(int(p.get("loan_serial",0)),int(str(debt["uid"]).get_slice(":loan:",1)))
		if not debt.has("due_year"): debt["due_year"]=int(p.get("born_year",GameState.year_now()-int(p.get("age",0))))+int(debt.get("taken_age",p.get("age",0)))+int(debt.get("term",1))
	if not p.has("loan_record"): p["loan_record"]=[]

func remember(p: Dictionary, debt: Dictionary, text: String, year: int, paid: int = 0) -> void:
	if not p.has("loan_record"): p["loan_record"]=[]
	p["loan_record"].push_front({"uid":debt["uid"],"lender":debt["lender"],"year":year,"text":text,"paid":paid,"balance":int(debt["left"])})
	if p["loan_record"].size()>60: p["loan_record"].resize(60)


func debts() -> Array:
	var st := state()
	return st.get("list", []) if not st.is_empty() else []


func total_owed(p: Dictionary = {}) -> int:
	var t := 0
	var list: Array=debts() if p.is_empty() else p.get("debts",[])
	for d in list:
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
	if not GameState.is_alive() or Lives.separate() or Childhood.supported() or GameState.in_prison(): reasons.append("Independent adult lending only")
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
func quote(id: String, amount: int, requested_term: int = 0) -> Dictionary:
	var offer_data := offer(id)
	if offer_data.is_empty() or not bool(offer_data["ok"]): return {}
	var term := int(offer_data["term"]) if requested_term==0 else requested_term
	if amount<500 or amount>int(offer_data["cap"]) or term<1 or term>int(offer_data["term"]): return {}
	var total := int(round(float(amount)*(1.0+float(offer_data["rate"])*term)))
	return {"principal":amount,"term":term,"rate":offer_data["rate"],"total":total,"payment":int(ceil(float(total)/term)),"interest":total-amount}

func fraction_amount(id: String, percent: float) -> int:
	var offer_data := offer(id)
	if offer_data.is_empty() or percent<=0 or percent>100: return 0
	return int(round(int(offer_data["cap"])*percent/100.0))

func borrow(id: String, amount: int, requested_term: int = 0) -> void:
	var o := offer(id)
	var terms := quote(id,amount,requested_term)
	if terms.is_empty():
		return
	var amt := amount
	var d: Dictionary = LENDERS[id]
	var term := int(terms["term"])
	var rate := float(o["rate"])
	var total := int(terms["total"])
	var yearly_pay := int(terms["payment"])
	var p := _p()
	p["money"] = int(p["money"]) + amt
	debts().append({
		"lender": id, "principal": amt, "left": total, "payment": yearly_pay,
		"rate": rate, "term":term,"taken_age": int(p.get("age", 0)), "missed": 0,"due_year":GameState.year_now()+term,
	})
	ensure_record(p)
	remember(p,debts().back(),"Loan signed",GameState.year_now())
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
	if not GameState.is_alive() or Childhood.supported() or Lives.separate(): return
	var list := debts()
	if index < 0 or index >= list.size():
		return
	var d: Dictionary = list[index]
	var owed := int(d["left"])
	var p := _p()
	if int(p["money"]) < owed:
		return
	p["money"] = int(p["money"]) - owed
	d["left"]=0
	Employment.record_expense("Early loan repayment",owed)
	remember(p,d,"Paid in full",GameState.year_now(),owed)
	list.remove_at(index)
	GameState.add_log("I cleared the whole thing: %s, gone." % GameState.fmt_money(owed))
	Grit.change_credit(30)
	Moments.fire("success", 0.7)


func support_reason(debt: Dictionary, kind: String) -> String:
	if kind not in ["reduced","pause","extend"]: return "Unknown arrangement"
	if Childhood.supported() or Lives.separate(): return "Independent adult lending only"
	var blocked := Journey.blocked(18)
	if blocked!="": return blocked
	if debt.is_empty() or int(debt.get("left",0))<=0: return "No outstanding loan"
	if debt["lender"]=="shark": return "This lender offers no hardship plans"
	if kind=="pause" and debt["lender"]=="online": return "This lender offers no pause"
	if debt.get("support",{}).get("used",false): return "Arrangement already used"
	if GameState.has_job() and int(_p()["money"])>=int(debt["payment"])*2 and GameState.stat("health")>=40: return "Hardship test not met"
	if int(_p().get("time_left",0))<1: return "Needs 1 time"
	return ""

func request_support(uid0: String, kind: String) -> void:
	var selected: Dictionary={}
	for debt in debts():
		if str(debt["uid"])==uid0: selected=debt; break
	var reason := support_reason(selected,kind)
	if reason!="": return
	if not Journey.pay("loan_support:"+uid0,1,0,18): return
	var fee := maxi(1,int(round(int(selected["left"])*0.02)))
	selected["left"]=int(selected["left"])+fee
	var year := GameState.year_now()
	selected["support"]={"used":true,"kind":kind,"starts":year+1,"through":year+(2 if kind=="reduced" else 1),"fee":fee,"reviewed":false,"original_payment":int(selected["payment"])}
	if kind=="extend":
		var years := maxi(1,int(selected["due_year"])-year)+3
		selected["payment"]=int(ceil(float(selected["left"])/years))
		selected["due_year"]=year+years
		selected["support"]["through"]=selected["due_year"]
	remember(_p(),selected,"Arrangement: "+kind+"; fee "+GameState.fmt_money(fee),year)
	GameState.add_log("Loan support agreed: "+kind+" · fee "+GameState.fmt_money(fee)+" added to this loan, not cash.")
	var terms := "New annual payment %s through %d" % [GameState.fmt_money(int(selected["payment"])),selected["due_year"]] if kind=="extend" else "%s payments in %d–%d; original payments then resume" % ["Half" if kind=="reduced" else "Paused",year+1,selected["support"]["through"]]
	EventEngine.push_info("🏦","Payment arrangement",terms+". Fee "+GameState.fmt_money(fee)+" added to the balance. Nothing was forgiven.")
func scheduled_payment(debt: Dictionary, year: int) -> int:
	var plan: Dictionary=debt.get("support",{})
	if not plan.is_empty() and plan.get("kind","") in ["reduced","pause"] and year>=int(plan.get("starts",0)) and year<=int(plan["through"]):
		return 0 if plan["kind"]=="pause" else mini(int(debt["left"]),maxi(1,int(debt["payment"])/2))
	return maxi(0,mini(int(debt["payment"]),int(debt["left"])))
func support_menu(uid0: String = "") -> Dictionary:
	var rows: Array=[]; var info: Array=["Review needs hardship. One plan per loan. Fee: 2% (minimum $1), added to the debt."]
	for debt in debts():
		if uid0=="":
			rows.append({"icon":LENDERS[debt["lender"]]["icon"],"name":LENDERS[debt["lender"]]["name"],"sub":"Owe "+GameState.fmt_money(int(debt["left"]))+" · next "+GameState.fmt_money(scheduled_payment(debt,GameState.year_now()+1)),"menu":"employment:loan_support:"+str(debt["uid"])})
			continue
		if str(debt["uid"])!=uid0: continue
		var plan: Dictionary=debt.get("support",{})
		info.append(str(LENDERS[debt["lender"]]["name"])+" · owe "+GameState.fmt_money(int(debt["left"]))+" · next payment "+GameState.fmt_money(scheduled_payment(debt,GameState.year_now()+1)))
		if not plan.is_empty(): info.append(str(plan["kind"])+" · "+str(plan.get("starts",GameState.year_now()))+"–"+str(plan["through"])+(" · new payment continues until cleared" if plan["kind"]=="extend" else " · original payments resume afterwards"))
		if debt["lender"]!="shark":
			for kind in ["reduced","pause","extend"]:
				var reason := support_reason(debt,kind)
				rows.append({"icon":"🏦","name":{"reduced":"Half payments","pause":"Pause payments","extend":"Longer term"}[kind],"sub":str(LENDERS[debt["lender"]]["name"])+" · "+(reason if reason!="" else "1 time · "+{"reduced":"2 years","pause":"1 year","extend":"3 extra years"}[kind]+" · 2% fee"),"act":"employment:loan_support","arg":{"uid":debt["uid"],"kind":kind},"on":reason==""})
		else: info.append("This lender offers no hardship plan. Extra repayments remain available.")
	rows.append({"icon":"📖","name":"Loan record","sub":"Agreements, payments and arrears","menu":"employment:loan_history"})
	if debts().is_empty(): info.append("No personal lender loan is on this life’s record.")
	return {"icon":"🏦","title":"Payment support","info":info,"rows":rows}
func history_menu() -> Dictionary:
	state()
	var info: Array=[]
	for entry in _p().get("loan_record",[]): info.append("%d · %s · %s · balance %s" % [entry["year"],LENDERS[entry["lender"]]["name"],entry["text"],GameState.fmt_money(int(entry["balance"]))])
	if info.is_empty(): info.append("No loan transactions recorded.")
	return {"title":"Loan record","icon":"📖","info":info,"rows":[]}

func yearly() -> void:
	if not GameState.is_alive() or Childhood.supported() or Lives.separate(): return
	service(_p(),GameState.year_now(),true)

func service(p: Dictionary, year: int, active: bool = false) -> int:
	if not p.get("alive",true) or int(p.get("age",0))<int(p.get("childhood_budget",{}).get("independence_age",18)) or int(p.get("lending_year",-1))>=year: return 0
	ensure_record(p)
	p["lending_year"]=year
	var paid := 0
	var list: Array = p["debts"]
	var i := list.size() - 1
	while i >= 0:
		var d: Dictionary = list[i]
		var left := int(d["left"])
		var due := scheduled_payment(d,year)
		var support: Dictionary=d.get("support",{})
		if not support.is_empty() and support.get("kind","")!="extend" and year>int(support["through"]) and not support.get("reviewed",false):
			support["reviewed"]=true
			remember(p,d,"Original payments resumed",year)
			if active: GameState.add_log("The loan arrangement ended. Original payments resume; the remaining balance is still due.")
		if due==0 or int(p["money"]) >= due:
			p["money"] = int(p["money"]) - due
			paid+=due
			d["left"] = left - due
			if due>0: d["missed"] = 0
			remember(p,d,"Payment made" if due>0 else "Agreed payment pause",year,due)
			if int(d["left"]) <= 0:
				if active: GameState.add_log("Last payment on the %s loan. That is finished." % str(LENDERS[str(d["lender"])]["name"]).to_lower())
				p["credit"]=clampi(int(p.get("credit",650))+25,300,850)
				list.remove_at(i)
				i -= 1
				continue
		else:
			d["missed"] = int(d.get("missed", 0)) + 1
			# Interest on a missed payment, and then the lender's own response.
			d["left"] = int(round(float(left) * (1.0 + float(d["rate"]) * 0.5)))
			p["credit"]=clampi(int(p.get("credit",650))-22-(40 if d["lender"]!="shark" and int(d["missed"])>=3 else 0),300,850)
			p["stats"]["stress"]=minf(100,float(p["stats"].get("stress",0))+8)
			remember(p,d,"Missed payment; interest added",year)
			if active: _missed(d, int(d["missed"]))
		i -= 1
	return paid


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


func summary_lines() -> Array:
	var out: Array = []
	for d in debts():
		var l: Dictionary = LENDERS[str(d["lender"])]
		out.append(["%s %s" % [str(l["icon"]), str(l["name"])],
			"%s left · next payment %s%s" % [GameState.fmt_money(int(d["left"])),
				GameState.fmt_money(scheduled_payment(d,GameState.year_now()+1)),
				"  ⚠️ %d missed" % int(d["missed"]) if int(d.get("missed", 0)) > 0 else ""]])
	return out

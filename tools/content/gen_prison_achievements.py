#!/usr/bin/env python3
"""Adds the Prison Life achievements to data/achievements.json (idempotent).
mode="prisoner" or "guard" (or both): judged only in that kind of life."""
import json, os
P = os.path.join(os.path.dirname(__file__), "..", "..", "data", "achievements.json")
a = json.load(open(P))
a = [x for x in a if not x["id"].startswith("prison_")]

def A(id, mode, tier, icon, name, desc, req, hidden=False, at_death=False, needs=None):
    d = {"id": "prison_" + id, "cat": "prison", "tier": tier, "icon": icon, "name": name, "desc": desc, "req": req, "mode": mode, "v": 20}
    if hidden: d["hidden"] = True
    if at_death: d["at_death"] = True
    if needs: d["needs"] = ["prison_" + n for n in needs]
    a.append(d)

# ---- prisoner
A("first", "prisoner", "bronze", "⛓️", "A Number, Not a Name", "Begin a sentence.", {"life_prisoner": 1})
A("y1", "prisoner", "bronze", "📅", "Fresh Fish No More", "Serve a full year inside.", {"prison_years": 1})
A("y5", "prisoner", "silver", "🗓️", "Five Inside", "Serve five years in one sentence.", {"prison_years": 5}, needs=["y1"])
A("y10", "prisoner", "gold", "⏳", "A Decade Inside", "Serve ten years in one sentence.", {"prison_years": 10}, needs=["y5"])
A("y20", "prisoner", "platinum", "🕰️", "Two Decades", "Serve twenty years in one sentence.", {"prison_years": 20}, needs=["y10"])
A("gang", "prisoner", "bronze", "🔗", "Colours", "Join a gang.", {"pr_joined": 1})
A("snitch", "prisoner", "bronze", "🐀", "A Name for a Favour", "Inform on someone.", {"pr_snitch": 1})
A("hole", "prisoner", "bronze", "🕳️", "The Hole", "Spend a year in segregation.", {"pr_solitary": 1})
A("hole3", "prisoner", "silver", "🧱", "A Regular in the Hole", "Be in segregation three times in one sentence.", {"pr_solitary": 3}, needs=["hole"])
A("programs", "prisoner", "silver", "🎓", "Model Prisoner", "Complete three programmes.", {"pr_programs": 3})
A("hearing", "prisoner", "bronze", "⚖️", "Before the Board", "Face a parole hearing.", {"pr_hearings": 1})
A("riot", "prisoner", "silver", "🔥", "In the Riot", "Live through a riot as an inmate.", {"pr_riots": 1})
A("attacked", "prisoner", "bronze", "🩹", "Scars", "Be attacked inside.", {"pr_attacks": 1})
A("intel", "prisoner", "silver", "🕵️", "Knows Things", "Gather eight pieces of intel.", {"pr_intel": 8})
A("break", "prisoner", "silver", "🚪", "The Night", "Attempt a break.", {"pr_breaks": 1})
A("out", "prisoner", "gold", "🌫️", "Over the Wall", "Get out of the building.", {"pr_escapes": 1}, needs=["break"])
A("back", "prisoner", "silver", "🚓", "Brought Back", "Be recaptured after a break.", {"pr_recaptured": 1})
A("end_exonerated", "prisoner", "platinum", "⚖️", "Exonerated", "Clear your name.", {"ending_pr_exonerated": 1}, True, True)
A("end_ghost", "prisoner", "gold", "🌫️", "A Ghost", "Escape and never be found.", {"ending_pr_ghost": 1}, True, True)
A("end_fallen", "prisoner", "gold", "🔒", "The Other Side of the Door", "End your days in the building you guarded.", {"ending_pr_fallen": 1}, True, True)
A("end_paroled", "prisoner", "silver", "🪪", "Paroled", "Be believed by the board.", {"ending_pr_paroled": 1}, True, True)
A("end_served", "prisoner", "silver", "📅", "Every Day of It", "Serve a sentence in full.", {"ending_pr_served": 1}, True, True)
A("end_legend", "prisoner", "gold", "👑", "Old Head", "Die inside with the building's respect.", {"ending_pr_legend": 1}, True, True)
A("end_died", "prisoner", "bronze", "🕯️", "Never Out", "Die inside.", {"ending_pr_died": 1}, True, True)
# ---- guard
A("g_first", "guard", "bronze", "🗝️", "Keys", "Join the staff.", {"life_guard": 1})
A("g_y5", "guard", "bronze", "📅", "Five on the Wing", "Serve five years on the staff.", {"prison_years": 5})
A("g_y15", "guard", "silver", "⏳", "Fifteen Years", "Serve fifteen years on the staff.", {"prison_years": 15}, needs=["g_y5"])
A("g_y30", "guard", "gold", "⏰", "Thirty Years", "Serve thirty years on the staff.", {"prison_years": 30}, needs=["g_y15"])
A("g_promo", "guard", "silver", "📈", "Up the Ladder", "Be promoted three times.", {"gd_promotions": 3})
A("g_commend", "guard", "silver", "🎖️", "Decorated", "Earn three commendations.", {"gd_commend": 3})
A("g_saved", "guard", "gold", "🕊️", "A Life Saved", "Save a life on the job.", {"gd_saved": 1})
A("g_incidents", "guard", "silver", "🚨", "Seen It All", "Handle five incidents.", {"gd_incidents": 5})
A("g_nose", "guard", "bronze", "🔦", "Good Nose", "Find contraband three times.", {"gd_contraband": 3})
A("g_crossed", "guard", "bronze", "💷", "Crossed the Line", "Take money for a favour.", {"gd_corrupt": 1}, True)
A("g_whistle", "guard", "gold", "📣", "Blew the Whistle", "Tell.", {"gd_whistle": 1})
A("g_inquiry", "guard", "silver", "🕵️", "Under Investigation", "Be investigated by Internal Affairs.", {"gd_investigations": 1})
A("g_end_warden", "guard", "platinum", "🗝️", "Warden", "Retire as Warden.", {"ending_gd_warden": 1}, True, True)
A("g_end_whistle", "guard", "gold", "📣", "Whistleblower", "End your career as the one who told.", {"ending_gd_whistle": 1}, True, True)
A("g_end_kingpin", "guard", "gold", "💰", "The Man With the Keys", "Take money for years and never be caught.", {"ending_gd_kingpin": 1}, True, True)
A("g_end_hero", "guard", "gold", "🎖️", "Hero of the Wing", "End your career a hero.", {"ending_gd_hero": 1}, True, True)
A("g_end_fired", "guard", "bronze", "📦", "Dismissed", "Lose the job.", {"ending_gd_fired": 1}, True, True)
A("g_end_burned", "guard", "silver", "🔥", "Burned Out", "Leave the service broken.", {"ending_gd_burned": 1}, True, True)
A("g_end_retired", "guard", "silver", "⏰", "Retired", "Retire with a pension.", {"ending_gd_retired": 1}, True, True)
A("g_end_duty", "guard", "silver", "🕯️", "In the Line of Duty", "Die on the staff.", {"ending_gd_duty": 1}, True, True)
# ---- both doors
A("both", ["prisoner", "guard"], "platinum", "🚪", "Both Sides of the Door", "Live a life as a prisoner and as a guard.", {"roles_lived": 2}, True)
json.dump(a, open(P, "w"), indent=1, ensure_ascii=False)
print("achievements:", len(a), "prison:", sum(1 for x in a if x["id"].startswith("prison_")))

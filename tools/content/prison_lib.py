"""Shared helpers for the Prison Life content generators (v1.2).
Every event is conditioned on life == prisoner / guard, so the human game and
Pets Life never see them. Each has three or more choices; every choice has two
or more outcomes. Outcome ops for the mode go under the `pr` key."""
import json, os

EV = []
FOLLOW = []

def O(text, fx=None, pr=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    if pr:
        o["pr"] = pr
    o.update(extra)
    return o

def C(label, *outs, requires=None):
    assert len(outs) >= 2, label
    c = {"label": label, "outcomes": list(outs)}
    if requires:
        c["requires"] = requires
    return c

def _conds(role, tags, not_tags, age):
    c = {"age": list(age), "life": role}
    t = list(tags or [])
    if role == "prisoner" or role == ["prisoner", "guard"]:
        pass
    if t:
        c["pr"] = t
    nt = list(not_tags or [])
    if role == "prisoner" and "fugitive" not in t:
        nt.append("fugitive")
    if role == "prisoner" and "reentry" not in t:
        nt.append("reentry")
    if nt:
        c["not_pr"] = nt
    return c

def E(id, icon, title, text, tags, *choices, role="prisoner", roles=None, not_tags=None, age=(16, 120), weight=1.0, cooldown=6, once=False):
    assert len(choices) >= 3, id
    d = {"id": id, "icon": icon, "title": title, "text": text, "conditions": _conds(role, tags, not_tags, age),
         "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if roles:
        d["roles"] = roles
    if once:
        d["once"] = True
    EV.append(d)

def F(id, icon, title, text, years, sources, tags, *choices, role="prisoner", roles=None):
    assert len(choices) >= 3, id
    d = {"id": id, "icon": icon, "title": title, "text": text, "conditions": _conds(role, tags, None, (0, 120)),
         "choices": list(choices), "weight": 1, "followup_only": True}
    if roles:
        d["roles"] = roles
    EV.append(d)
    FOLLOW.append((id, years, sources))

def T(id, icon, title, text, *choices, role="prisoner", roles=None, twist=False):
    """A step in a set piece: only reachable through `then`."""
    assert len(choices) >= 3, id
    d = {"id": id, "icon": icon, "title": title, "text": text, "conditions": {"age": [0, 120], "life": role},
         "choices": list(choices), "weight": 1, "followup_only": True}
    if roles:
        d["roles"] = roles
    EV.append(d)

def A(role, n, icon, title, text, *choices):
    assert len(choices) == 3
    EV.append({"id": "arc.%s.%d" % (role, n), "icon": icon, "title": title, "text": text,
               "conditions": {"age": [0, 130], "life": role}, "choices": list(choices), "weight": 1, "followup_only": True})

# role handles used by many events
CELL = {"c": {"relation": "cellmate"}}
OFF = {"off": {"relation": "officer"}}
INM = {"i": {"relation": "inmate"}}
LAW = {"law": {"relation": "lawyer"}}
SUP = {"sup": {"relation": "supervisor"}}
COG = {"co": {"relation": "co_guard"}}

def write():
    for (fid, years, sources) in FOLLOW:
        for e in EV:
            if e["id"] in sources:
                for ch in e["choices"]:
                    for o in ch["outcomes"]:
                        if "schedule" not in o and "then" not in o.get("pr", {}):
                            o["schedule"] = {"event": fid, "years": years}
    out = os.path.join(os.path.dirname(__file__), "..", "..", "data", "events", "prison_life.json")
    json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
    base = [e for e in EV if not e.get("followup_only")]
    print("prison_life.json: %d events (%d base), %d choices, %d outcomes, %d with follow-ups" % (
        len(EV), len(base), sum(len(e["choices"]) for e in EV),
        sum(len(c["outcomes"]) for e in EV for c in e["choices"]),
        sum(1 for e in EV if any("schedule" in o for c in e["choices"] for o in c["outcomes"]))))

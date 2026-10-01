"""Tiny helpers shared by the v0.25 event generators."""
import json, os
EV = []
def O(text, fx=None, w=1, **extra):
    o = {"text": text, "weight": w, "effects": fx or {}}
    o.update(extra)
    if isinstance(o.get("habit"), dict):          # the engine takes ["habit_id", amount]
        (k, v), = o["habit"].items()
        o["habit"] = [k, v]
    return o
def C(label, *outs, requires=None):
    assert len(outs) >= 2, label
    c = {"label": label, "outcomes": list(outs)}
    if requires: c["requires"] = requires
    return c
def E(id, icon, title, text, cond, *choices, roles=None, cooldown=12, once=False, weight=1.0, prefix="x."):
    assert len(choices) >= 3, id
    d = {"id": prefix + id, "icon": icon, "title": title, "text": text, "conditions": dict(cond), "choices": list(choices), "weight": weight, "cooldown": cooldown}
    if roles: d["roles"] = roles
    if once: d["once"] = True
    EV.append(d)
def save(name):
    ids = [e["id"] for e in EV]
    assert len(ids) == len(set(ids)), "duplicate ids"
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "..", "data", "events", name)
    json.dump(EV, open(out, "w"), indent=1, ensure_ascii=False)
    print(name, len(EV), "events")
BOSS = {"boss": {"relation": "boss"}}
COW = {"co": {"relation": "coworker"}}

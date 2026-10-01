#!/usr/bin/env python3
"""Adds the Pets Life achievements to data/achievements.json (idempotent).
They carry mode="pet" so they are only judged in a Pets Life, and human
achievements are only judged in a human one."""
import json, os
P = os.path.join(os.path.dirname(__file__), "..", "..", "data", "achievements.json")
a = json.load(open(P))
a = [x for x in a if not x["id"].startswith("pets_")]

def A(id, tier, icon, name, desc, req, hidden=False, at_death=False, needs=None):
    d = {"id": "pets_" + id, "cat": "pets", "tier": tier, "icon": icon, "name": name, "desc": desc, "req": req, "mode": "pet", "v": 19}
    if hidden: d["hidden"] = True
    if at_death: d["at_death"] = True
    if needs: d["needs"] = ["pets_" + n for n in needs]
    a.append(d)

A("first", "bronze", "🐾", "Four Legs, Two Wings or Both", "Start a Pets Life.", {"life_pet": 1})
A("dog", "bronze", "🐕", "Dog Years", "Live eight years as a dog.", {"pet_dog": 1, "pet_years": 8})
A("cat", "bronze", "🐈", "Nine Lives, Roughly", "Live nine years as a cat.", {"pet_cat": 1, "pet_years": 9})
A("rabbit", "bronze", "🐇", "Binky", "Live six years as a rabbit.", {"pet_rabbit": 1, "pet_years": 6})
A("parrot", "silver", "🦜", "Longer Than Anyone Expected", "Live twenty-five years as a parrot.", {"pet_parrot": 1, "pet_years": 25})
A("horse", "silver", "🐎", "Long in the Tooth", "Live twenty years as a horse.", {"pet_horse": 1, "pet_years": 20})
A("old", "silver", "🕰️", "A Very Old Friend", "Reach the age of 15.", {"age": 15})
A("adopted", "bronze", "🏠", "Chosen", "Be taken home by someone who wanted you.", {"pet_adopted": 1})
A("rescued", "bronze", "🩹", "Out of the Mill", "Be rescued from a breeding mill.", {"pet_rescued": 1})
A("found", "silver", "🧭", "Home by Dark", "Be found after being lost.", {"pet_found": 1})
A("rehomed", "silver", "💔", "Given Up, Not Given In", "Be rehomed, and still find a home again.", {"pet_rehomed": 1, "pet_adopted": 2})
A("heroics1", "bronze", "🎖️", "Good One", "Do something brave.", {"pet_heroics": 1})
A("heroics3", "gold", "🏅", "Local Hero", "Do three brave things in one life.", {"pet_heroics": 3}, needs=["heroics1"])
A("tricks5", "bronze", "🎓", "Smart Cookie", "Learn five tricks.", {"pet_tricks": 5})
A("tricks8", "silver", "🎩", "Showman", "Learn eight tricks.", {"pet_tricks": 8}, needs=["tricks5"])
A("titles1", "silver", "🏆", "Best in Class", "Win a show.", {"pet_titles": 1})
A("titles3", "gold", "🥇", "Champion of Champions", "Win three shows in one life.", {"pet_titles": 3}, needs=["titles1"])
A("friends", "bronze", "🐾", "Social Animal", "Make five friends of your own.", {"pet_friends": 5})
A("visits", "silver", "💞", "The Therapy Animal", "Make five therapy visits.", {"pet_visits": 5})
A("shifts", "silver", "🪢", "A Day's Work", "Work ten shifts.", {"pet_shifts": 10})
A("end_best_friend", "gold", "💞", "Best Friend", "End a life as somebody's whole world.", {"ending_pet_best_friend": 1}, True, True)
A("end_hero", "gold", "🎖️", "A Hero", "End a life as a hero.", {"ending_pet_hero": 1}, True, True)
A("end_champion", "gold", "🏆", "Best in Show", "End a life as a champion.", {"ending_pet_champion": 1}, True, True)
A("end_stray_king", "gold", "👑", "Lord of the Alley", "End a life as the king of the street.", {"ending_pet_stray_king": 1}, True, True)
A("end_sunbeam", "silver", "☀️", "A Long, Warm Life", "End a life old, loved and in the sun.", {"ending_pet_sunbeam": 1}, True, True)
A("end_lost", "silver", "🧭", "Never Came Home", "Be lost and never found.", {"ending_pet_lost": 1}, True, True)
A("end_good", "bronze", "🐾", "A Good Life", "Have a short, good life.", {"ending_pet_good": 1}, True, True)
A("all_species", "platinum", "🌈", "Every Kind", "Live a life as each of the five animals.", {"species_lived": 5}, True, False)
json.dump(a, open(P, "w"), indent=1, ensure_ascii=False)
print("achievements:", len(a))

#!/usr/bin/env python3
"""Generates data/events/prison_life.json (Prison Life, v1.2).
Run order: prison_lib.py is imported by the parts; they register their events
as they import; write() wires the follow-ups and emits the file."""
import prison_lib
import gen_prison_a, gen_prison_b, gen_prison_c, gen_prison_d, gen_prison_e, gen_prison_f, gen_prison_g
prison_lib.write()

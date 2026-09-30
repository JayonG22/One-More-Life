extends Node

## Procedural audio. Every sound and the ambient music are synthesized at
## runtime, so the project ships with no audio files. Three buses (Music, SFX,
## UI) with their own sliders; SFX gets a light reverb. Each theme (and so each
## Life Path) has its own sonic personality and its own music loop.

const RATE := 22050
const MUSIC_RATE := 22050
const UI_SOUNDS := ["tap", "choice", "back", "page", "error", "whoosh"]

const THEME_FLAVOR := {
	"light": {"pitch": 1.0, "wave": "sine", "bright": 1.0},
	"dark": {"pitch": 1.0, "wave": "sine", "bright": 0.95},
	"celebrity": {"pitch": 1.12, "wave": "sine", "bright": 1.3},
	"vampire": {"pitch": 0.78, "wave": "tri", "bright": 0.7},
	"undead": {"pitch": 0.72, "wave": "square", "bright": 0.6},
	"villain": {"pitch": 0.85, "wave": "saw", "bright": 0.8},
	"superhero": {"pitch": 1.06, "wave": "square", "bright": 1.2},
	"royal": {"pitch": 0.94, "wave": "tri", "bright": 1.1},
	"witch": {"pitch": 0.9, "wave": "tri", "bright": 0.85},
}

## Music: [root Hz, chords as semitone offsets, pad wave, arp wave, tempo (s per arp note), mood gain]
const MUSIC := {
	"light": [261.6, [[0, 4, 7], [-3, 0, 4], [-7, -3, 0], [-5, -1, 2]], "sine", "sine", 0.5, 1.0],
	"dark": [220.0, [[0, 3, 7], [-4, 0, 3], [-9, -5, -2], [-2, 2, 5]], "sine", "tri", 0.5, 0.9],
	"celebrity": [293.7, [[0, 4, 7], [7, 11, 14], [-3, 0, 4], [5, 9, 12]], "tri", "sine", 0.25, 1.0],
	"vampire": [146.8, [[0, 3, 7], [-4, 0, 3], [-7, -4, 0], [-5, -1, 2]], "tri", "tri", 0.75, 0.85],
	"undead": [110.0, [[0, 3, 7], [0, 3, 7], [-4, 0, 3], [-1, 3, 6]], "tri", "square", 1.0, 0.7],
	"villain": [130.8, [[0, 3, 7], [-4, 0, 3], [5, 8, 12], [7, 11, 14]], "saw", "tri", 0.375, 0.6],
	"superhero": [196.0, [[0, 4, 7], [7, 11, 14], [9, 12, 16], [5, 9, 12]], "tri", "square", 0.25, 0.75],
	"royal": [293.7, [[0, 4, 7], [5, 9, 12], [7, 11, 14], [0, 4, 7]], "tri", "sine", 0.5, 0.9],
	"witch": [220.0, [[0, 3, 7], [5, 8, 12], [7, 11, 14], [0, 3, 7]], "sine", "tri", 0.375, 0.9],
}

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _next_ui := 0
var _enabled := true
var _music: AudioStreamPlayer
var _music_cache: Dictionary = {}
var _music_theme := ""
var _thread: Thread
var _music_on := true


func _ready() -> void:
	_setup_buses()
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.bus = "UI"
		add_child(p)
		_ui_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music_on = DisplayServer.get_name() != "headless"
	apply_volumes()
	if is_instance_valid(ThemeManager):
		ThemeManager.theme_changed.connect(_on_theme)
	call_deferred("_on_theme")


func _setup_buses() -> void:
	for bus in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.35
		rv.damping = 0.6
		rv.wet = 0.12
		rv.dry = 1.0
		AudioServer.add_bus_effect(sfx, rv)
	var mus := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(mus) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 3200
		AudioServer.add_bus_effect(mus, lp)
		var rv2 := AudioEffectReverb.new()
		rv2.room_size = 0.7
		rv2.wet = 0.25
		AudioServer.add_bus_effect(mus, rv2)


func _vol(key: String, dflt: float) -> float:
	return clampf(float(GameState.settings.get(key, dflt)) / 100.0, 0.0, 1.0)


func volume() -> float:
	return _vol("volume", 70)


func apply_volumes() -> void:
	for pair in [["Master", "volume", 70], ["Music", "music_vol", 45], ["SFX", "sfx_vol", 80], ["UI", "ui_vol", 65]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx == -1:
			continue
		var v := _vol(pair[1], pair[2])
		AudioServer.set_bus_mute(idx, v <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


func effects_on() -> bool:
	return bool(GameState.settings.get("effects", true))


func flashes_on() -> bool:
	return effects_on() and bool(GameState.settings.get("flashes", true))


func shake_on() -> bool:
	return effects_on() and bool(GameState.settings.get("shake", true))


func reduced_motion() -> bool:
	return bool(GameState.settings.get("reduced_motion", false))


# ---------------------------------------------------------------- synthesis

func _wave(kind: String, phase: float) -> float:
	match kind:
		"square": return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		"saw": return fmod(phase, 1.0) * 2.0 - 1.0
		"tri":
			var t := fmod(phase, 1.0)
			return (t * 4.0 - 1.0) if t < 0.5 else (3.0 - t * 4.0)
		"noise": return randf_range(-1.0, 1.0)
		"bell": return sin(phase * TAU) * 0.7 + sin(phase * TAU * 2.76) * 0.3
	return sin(phase * TAU)


## notes: array of [freq, start_sec, len_sec, volume, wave, bend]
func _render(notes: Array, total: float, rate: int = RATE, pad: bool = false) -> AudioStreamWAV:
	var count := int(rate * total)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for n in notes:
		var freq: float = n[0]
		var start: int = int(float(n[1]) * rate)
		var length: int = int(float(n[2]) * rate)
		var amp: float = n[3]
		var kind: String = n[4] if n.size() > 4 else "sine"
		var bend: float = n[5] if n.size() > 5 else 1.0
		var phase := 0.0
		var phase2 := 0.0
		var lp := 0.0
		for i in range(length):
			var idx := posmod(start + i, count) if pad else start + i
			if idx >= count:
				break
			var t := float(i) / float(length)
			var env := 1.0
			if pad:
				env = minf(1.0, t / 0.3) * minf(1.0, (1.0 - t) / 0.35)
			elif t < 0.02:
				env = t / 0.02
			else:
				env = pow(1.0 - (t - 0.02) / 0.98, 1.6)
			var f: float = freq * lerpf(1.0, bend, t)
			phase += f / rate
			var s: float
			if kind == "noise":
				lp += (randf_range(-1.0, 1.0) - lp) * 0.35
				s = lp * 1.6
			else:
				s = _wave(kind, phase)
				if pad:
					phase2 += f * 1.005 / rate
					s = (s + _wave(kind, phase2)) * 0.5
			buf[idx] += s * amp * env
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var v: float = buf[i]
		v = v / (1.0 + absf(v) * 0.35)
		var s := int(clampf(v, -1.0, 1.0) * 32000.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	return st


func _build(id: String) -> AudioStreamWAV:
	var fl: Dictionary = THEME_FLAVOR.get(ThemeManager.current, THEME_FLAVOR["dark"])
	var p: float = fl["pitch"]
	var w: String = fl["wave"]
	var br: float = fl["bright"]
	match id:
		"tap":
			return _render([[620.0 * p, 0.0, 0.05, 0.16 * br, w, 1.15]], 0.06)
		"choice":
			return _render([[480.0 * p, 0.0, 0.06, 0.2 * br, w, 1.3], [720.0 * p, 0.03, 0.07, 0.15 * br, w]], 0.11)
		"back":
			return _render([[520.0 * p, 0.0, 0.06, 0.16 * br, w, 0.7]], 0.07)
		"whoosh":
			return _render([[0.0, 0.0, 0.26, 0.1, "noise"], [260.0 * p, 0.0, 0.24, 0.04, "sine", 2.2]], 0.27)
		"age":
			return _render([[330.0 * p, 0.0, 0.09, 0.26 * br, w], [494.0 * p, 0.07, 0.11, 0.24 * br, w], [659.0 * p, 0.15, 0.16, 0.2 * br, w], [659.0 * p * 2.0, 0.15, 0.3, 0.05, "bell"]], 0.45)
		"good":
			return _render([[784.0 * p, 0.0, 0.1, 0.24 * br, w], [1047.0 * p, 0.08, 0.16, 0.2 * br, w], [2093.0 * p, 0.08, 0.3, 0.04, "bell"]], 0.4)
		"bad":
			return _render([[180.0 * p, 0.0, 0.16, 0.3, w, 0.6], [90.0 * p, 0.02, 0.2, 0.22, "tri", 0.7]], 0.24)
		"coin":
			return _render([[1180.0 * p, 0.0, 0.05, 0.2 * br, "square"], [1560.0 * p, 0.04, 0.12, 0.17 * br, "square"]], 0.18)
		"cash":
			return _render([[880.0 * p, 0.0, 0.06, 0.2 * br, "square"], [1320.0 * p, 0.05, 0.07, 0.18 * br, "square"], [1760.0 * p, 0.1, 0.14, 0.15 * br, "square"], [0.0, 0.0, 0.08, 0.06, "noise"]], 0.26)
		"fanfare":
			return _render([[523.0 * p, 0.0, 0.11, 0.24 * br, w], [659.0 * p, 0.1, 0.11, 0.24 * br, w], [784.0 * p, 0.2, 0.12, 0.24 * br, w], [1047.0 * p, 0.3, 0.4, 0.26 * br, w], [261.5 * p, 0.3, 0.45, 0.14, "tri"]], 0.75)
		"levelup":
			return _render([[440.0 * p, 0.0, 0.08, 0.22 * br, w], [587.0 * p, 0.07, 0.08, 0.22 * br, w], [880.0 * p, 0.14, 0.22, 0.24 * br, w]], 0.38)
		"death":
			return _render([[110.0, 0.0, 1.2, 0.3, "sine"], [165.0, 0.0, 1.0, 0.16, "tri"], [82.0, 0.25, 1.1, 0.2, "sine"], [0.0, 0.0, 0.6, 0.04, "noise"]], 1.45)
		"baby":
			return _render([[880.0 * p, 0.0, 0.12, 0.2, "tri", 1.25], [990.0 * p, 0.12, 0.16, 0.18, "tri", 0.85]], 0.3)
		"wedding":
			return _render([[659.0 * p, 0.0, 0.18, 0.2 * br, "bell"], [880.0 * p, 0.12, 0.2, 0.2 * br, "bell"], [1047.0 * p, 0.26, 0.45, 0.22 * br, "bell"]], 0.75)
		"siren":
			return _render([[620.0, 0.0, 0.22, 0.16, "saw", 1.4], [620.0, 0.22, 0.22, 0.16, "saw", 1.4]], 0.46)
		"gavel":
			return _render([[155.0 * p, 0.0, 0.06, 0.38, "square", 0.82], [78.0 * p, 0.018, 0.14, 0.24, "tri", 0.68], [0.0, 0.0, 0.05, 0.10, "noise"]], 0.18)
		"monitor":
			return _render([[980.0 * p, 0.0, 0.055, 0.15 * br, "sine"], [980.0 * p, 0.17, 0.055, 0.13 * br, "sine"]], 0.26)
		"crowd":
			return _render([[0.0, 0.0, 0.5, 0.14, "noise"]], 0.5)
		"page":
			return _render([[0.0, 0.0, 0.08, 0.07, "noise"]], 0.09)
		"error":
			return _render([[240.0, 0.0, 0.1, 0.22, "square", 0.8]], 0.12)
		"twist":
			return _render([[55.0, 0.0, 0.9, 0.34, "sine", 0.8], [110.0 * p, 0.0, 0.7, 0.18, "saw", 0.7], [233.0 * p, 0.12, 0.5, 0.12, w, 1.06], [247.0 * p, 0.12, 0.5, 0.12, w, 0.95], [0.0, 0.0, 0.25, 0.1, "noise"]], 1.0)
		"achieve":
			return _render([[1319.0 * p, 0.0, 0.08, 0.16 * br, "sine"], [1568.0 * p, 0.06, 0.08, 0.16 * br, "sine"], [2093.0 * p, 0.12, 0.3, 0.18 * br, "bell"], [1047.0 * p, 0.0, 0.4, 0.08 * br, "tri"]], 0.45)
		"heirloom":
			return _render([[988.0 * p, 0.0, 0.3, 0.16, "bell"], [1319.0 * p, 0.1, 0.45, 0.14, "bell"]], 0.6)
		"legendary":
			return _render([[523.0, 0.0, 0.14, 0.22, "tri"], [659.0, 0.12, 0.14, 0.22, "tri"], [784.0, 0.24, 0.14, 0.22, "tri"], [1047.0, 0.36, 0.7, 0.24, "tri"], [2093.0, 0.4, 0.5, 0.08, "bell"], [2637.0, 0.5, 0.5, 0.07, "bell"], [3136.0, 0.6, 0.5, 0.06, "bell"], [131.0, 0.36, 0.8, 0.16, "sine"]], 1.2)
		"bubble":
			var f := randf_range(260.0, 420.0) * p
			return _render([[f, 0.0, 0.07, 0.16, "sine", 1.9]], 0.08)
		"pour":
			return _render([[0.0, 0.0, 0.35, 0.08, "noise"], [700.0, 0.0, 0.35, 0.03, "sine", 1.5]], 0.36)
		"explosion":
			return _render([[0.0, 0.0, 0.8, 0.4, "noise"], [70.0, 0.0, 0.7, 0.34, "sine", 0.45], [140.0, 0.0, 0.3, 0.16, "saw", 0.5]], 0.85)
		"magic":
			return _render([[1175.0 * p, 0.0, 0.25, 0.1, "bell"], [1480.0 * p, 0.06, 0.25, 0.1, "bell"], [1760.0 * p, 0.12, 0.25, 0.1, "bell"], [2349.0 * p, 0.18, 0.4, 0.1, "bell"], [587.0 * p, 0.0, 0.6, 0.07, "tri", 1.02]], 0.65)
		"bite":
			return _render([[0.0, 0.0, 0.08, 0.26, "noise"], [300.0, 0.02, 0.18, 0.2, "square", 0.4]], 0.22)
		"power":
			return _render([[110.0, 0.0, 0.5, 0.2, "saw", 3.0], [220.0, 0.0, 0.5, 0.12, "square", 3.0], [0.0, 0.3, 0.2, 0.1, "noise"]], 0.55)
		"crown":
			return _render([[392.0, 0.0, 0.12, 0.2, "square"], [392.0, 0.14, 0.08, 0.18, "square"], [523.0, 0.24, 0.5, 0.22, "square"], [196.0, 0.24, 0.5, 0.14, "tri"], [659.0, 0.24, 0.5, 0.1, "tri"]], 0.8)
		"rise":
			return _render([[45.0, 0.0, 1.2, 0.34, "sine", 1.5], [0.0, 0.0, 0.9, 0.12, "noise"], [110.0, 0.3, 0.9, 0.14, "saw", 1.06], [116.5, 0.3, 0.9, 0.14, "saw", 0.98]], 1.3)
		"news":
			return _render([[587.0, 0.0, 0.1, 0.18, "square"], [587.0, 0.12, 0.1, 0.18, "square"], [880.0, 0.24, 0.3, 0.2, "square"], [294.0, 0.24, 0.3, 0.1, "tri"]], 0.56)
	return _render([[500.0 * p, 0.0, 0.05, 0.15, w]], 0.06)


func play(id: String, pitch_var: float = 0.03) -> void:
	if not _enabled:
		return
	var key := id + "_" + ThemeManager.current
	if id == "bubble":
		key += str(randi() % 4)
	if not _cache.has(key):
		_cache[key] = _build(id)
	var pl: AudioStreamPlayer
	if id in UI_SOUNDS:
		pl = _ui_players[_next_ui]
		_next_ui = (_next_ui + 1) % _ui_players.size()
	else:
		pl = _players[_next_player]
		_next_player = (_next_player + 1) % _players.size()
	pl.stream = _cache[key]
	pl.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	pl.volume_db = 0.0
	pl.play()


## Picks a sound from a set of stat changes.
func play_for_changes(changes: Dictionary) -> void:
	if changes.is_empty():
		return
	if changes.has("money"):
		play("cash" if absi(int(changes["money"])) >= 5000 else "coin")
		return
	var sum := 0
	for k in changes.keys():
		var v := int(changes[k])
		sum += -v if k == "stress" else v
	if sum > 6:
		play("good")
	elif sum < -6:
		play("bad")
	else:
		play("tap")


# ---------------------------------------------------------------- music

func _on_theme() -> void:
	_cache.clear()
	if not _music_on:
		return
	var th: String = ThemeManager.current
	if th == _music_theme:
		return
	_music_theme = th
	if _music_cache.has(th):
		_start_music(_music_cache[th])
		return
	if _thread != null and _thread.is_alive():
		return
	if _thread != null:
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_compose.bind(th))


func _compose(th: String) -> void:
	var st := _compose_loop(th)
	call_deferred("_music_ready", th, st)


func _music_ready(th: String, st: AudioStreamWAV) -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	_music_cache[th] = st
	if ThemeManager.current == th:
		_start_music(st)
	elif ThemeManager.current != _music_theme:
		_music_theme = ""
		_on_theme()


func _start_music(st: AudioStreamWAV) -> void:
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, 0.6)
	t.tween_callback(func():
		_music.stream = st
		_music.volume_db = -40.0
		_music.play())
	t.tween_property(_music, "volume_db", 0.0, 1.4)


func _compose_loop(th: String) -> AudioStreamWAV:
	var md: Array = MUSIC.get(th, MUSIC["dark"])
	var root: float = md[0]
	var chords: Array = md[1]
	var pad_w: String = md[2]
	var arp_w: String = md[3]
	var step: float = md[4]
	var gain: float = md[5]
	var bar := 4.0
	var total := bar * chords.size()
	var pads: Array = []
	var hits: Array = []
	var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
	for ci in range(chords.size()):
		var ch: Array = chords[ci]
		var t0 := ci * bar
		for semi in ch:
			pads.append([root * pow(2.0, float(semi) / 12.0), t0 - 0.4, bar + 0.8, 0.07 * gain, pad_w, 1.0])
		pads.append([root * 0.5 * pow(2.0, float(ch[0]) / 12.0), t0, bar, 0.08 * gain, "sine", 1.0])
		var n := int(bar / step)
		for k in range(n):
			var semi: int = int(ch[pattern[k % pattern.size()]]) + (12 if k % 4 == 3 else 0)
			hits.append([root * 2.0 * pow(2.0, float(semi) / 12.0), t0 + k * step, minf(step * 1.8, 0.9), 0.035 * gain, arp_w, 1.0])
	var a := _render(pads, total, MUSIC_RATE, true)
	var b := _render(hits, total, MUSIC_RATE, false)
	var da := a.data
	var db := b.data
	for i in range(0, da.size(), 2):
		var va := (da[i] | (da[i + 1] << 8))
		if va >= 32768: va -= 65536
		var vb := (db[i] | (db[i + 1] << 8))
		if vb >= 32768: vb -= 65536
		var s := clampi(va + vb, -32000, 32000)
		if s < 0: s += 65536
		da[i] = s & 0xFF
		da[i + 1] = (s >> 8) & 0xFF
	a.data = da
	a.loop_mode = AudioStreamWAV.LOOP_FORWARD
	a.loop_begin = 0
	a.loop_end = int(total * MUSIC_RATE)
	return a


func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()

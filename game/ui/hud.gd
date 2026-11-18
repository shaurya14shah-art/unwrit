class_name Hud
extends Control
## The whole HUD, drawn by hand each frame in the Ledger's ink (see Ink):
## flat panels, hairlines, keycaps, spaced capitals. Vitality and spirit
## energy meet at a diamond that fills with spirit pressure.

const INK := Color(0.045, 0.045, 0.06)
const INK2 := Color(0.11, 0.11, 0.14)
const PALE := Color(0.9, 0.9, 0.93)
const DIM := Color(0.55, 0.56, 0.6)
const GOLD := Color(1.0, 0.82, 0.4)
const BLOOD := Color(0.86, 0.12, 0.16)

var place: Place
var title_font: Font
var body_font: Font
var hidden_ui: bool = false

var _toasts: Array = []
var _big: Dictionary = {}
var _hp_trail: float = 1.0
var _t: float = 0.0
var seen: Dictionary = {}
## The hotbar's memory: last frame's cooldowns, and a flash when one ends.
var _prev_cd: Array = [0.0, 0.0, 0.0, 0.0]
var _flash: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _prev_ev: float = 0.0
var _prev_crit: float = 0.0
var _was_full: bool = false
## Pickups gather here, one line per material, counts adding up.
var _loot: Array = []
## A level or grade: one banner at a time.
var _banner: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_font = load("res://assets/fonts/Cinzel.ttf") if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf") else ThemeDB.fallback_font
	body_font = load("res://assets/fonts/Inter.ttf") if ResourceLoader.exists("res://assets/fonts/Inter.ttf") else ThemeDB.fallback_font


func bind(p: Place) -> void:
	place = p
	if p != null and not p.message.is_connected(push):
		p.message.connect(push)


func push(text: String, kind: String = "toast") -> void:
	seen[kind] = text
	match kind:
		"toast", "hint", "gain":
			# the same line twice in a row counts up instead of stacking
			if not _toasts.is_empty():
				var last: Dictionary = _toasts[_toasts.size() - 1]
				if String(last["text"]) == text and float(last["t"]) < float(last["life"]) - 0.6:
					last["n"] = int(last.get("n", 1)) + 1
					last["t"] = minf(float(last["t"]), 0.25)
					return
			_toasts.append({"text": text, "kind": kind, "t": 0.0, "life": 5.5 if kind != "hint" else 4.0, "n": 1})
			while _toasts.size() > 4:
				_toasts.pop_front()
		"loot":
			var parts := text.split(":")
			var key := parts[0]
			var n := int(parts[1]) if parts.size() > 1 else 1
			for l: Variant in _loot:
				var d: Dictionary = l
				if String(d["key"]) == key and float(d["t"]) < float(d["life"]) - 0.5:
					d["n"] = int(d["n"]) + n
					d["t"] = minf(float(d["t"]), 0.2)
					d["bump"] = 0.0
					return
			_loot.append({"key": key, "n": n, "t": 0.0, "life": 4.0, "bump": 0.0})
			while _loot.size() > 5:
				_loot.pop_front()
		"drop":
			var parts := text.split("|")
			_loot.append({"key": "", "drop": parts, "t": 0.0, "life": 6.0, "bump": 0.0})
			while _loot.size() > 5:
				_loot.pop_front()
		"level":
			_banner = {"text": text, "t": 0.0, "life": 4.2}
		_:
			var life := 3.6
			if kind == "stele":
				life = 7.5
			elif kind == "talk":
				life = 2.0 + float(text.length()) / 22.0
			elif kind == "whisper":
				life = 5.0
			elif kind == "release":
				life = 2.8
			if kind == "boss" or kind == "region":
				_big.erase("boss")
				_big.erase("region")
			_big[kind] = {"text": text, "t": 0.0, "life": life}


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.05)
	_t += real
	for t: Variant in _toasts:
		t["t"] = float(t["t"]) + real
	_toasts = _toasts.filter(func(t: Dictionary) -> bool: return float(t["t"]) < float(t["life"]))
	for k: Variant in _big.keys():
		var b: Dictionary = _big[k]
		b["t"] = float(b["t"]) + real
		if float(b["t"]) >= float(b["life"]):
			_big.erase(k)
	for l: Variant in _loot:
		(l as Dictionary)["t"] = float((l as Dictionary)["t"]) + real
		(l as Dictionary)["bump"] = float((l as Dictionary)["bump"]) + real
	_loot = _loot.filter(func(l: Dictionary) -> bool: return float(l["t"]) < float(l["life"]))
	if not _banner.is_empty():
		_banner["t"] = float(_banner["t"]) + real
		if float(_banner["t"]) >= float(_banner["life"]):
			_banner = {}
	for i in range(7):
		_flash[i] = maxf(0.0, float(_flash[i]) - real)
	if place != null and is_instance_valid(place) and place.player != null:
		var pl := place.player
		var frac := pl.hp / maxf(pl.max_hp, 1.0)
		_hp_trail = maxf(frac, move_toward(_hp_trail, frac, real * 0.35))
		for i in range(4):
			if float(_prev_cd[i]) > 0.0 and pl.tech_cd[i] <= 0.0:
				_flash[i] = 0.45
			_prev_cd[i] = pl.tech_cd[i]
		if _prev_ev > 0.0 and pl.evasive_cd <= 0.0:
			_flash[5] = 0.45
		if _prev_crit > 0.0 and pl.crit_cd <= 0.0:
			_flash[6] = 0.45
		_prev_ev = pl.evasive_cd
		_prev_crit = pl.crit_cd
		if place.soul != null and not place.soul.release.is_empty():
			var full := pl.swell >= 100.0
			if full and not _was_full:
				_flash[4] = 0.6
			_was_full = full
	queue_redraw()


func _fade(t: float, life: float) -> float:
	return clampf(t / 0.25, 0.0, 1.0) * clampf((life - t) / 0.6, 0.0, 1.0)


func _text(font: Font, pos: Vector2, text: String, size: int, color: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT, _outline: int = 6) -> void:
	Ink.lifted(self, pos, text, size, color, width, align, font)


func _diamond(c: Vector2, r: float, color: Color, filled: bool = true, width: float = 2.0) -> void:
	Ink.diamond(self, c, r, color, filled, width)


func _draw() -> void:
	if place == null or not is_instance_valid(place) or place.player == null or hidden_ui:
		_draw_big()
		return
	var p := place.player
	var soul := place.soul
	var w := size.x
	var h := size.y
	var accent := p.current_color()
	_draw_world(p)
	var cx := w * 0.5
	# ---- vitality | diamond | spirit energy
	var by := h - 140.0
	var bw := 300.0
	var hp_frac := p.hp / maxf(p.max_hp, 1.0)
	var hp_col := Ink.LIFE if hp_frac > 0.3 else Ink.LIFE.lerp(Ink.SEAL, 0.5 + 0.3 * sin(_t * 7.0))
	Ink.bar(self, Rect2(cx - 30.0 - bw, by, bw, 12.0), hp_frac, hp_col, _hp_trail, true)
	var en_col := accent.lerp(Color(0.35, 0.75, 0.95), 0.45)
	Ink.bar(self, Rect2(cx + 30.0, by, bw, 12.0), p.anima / maxf(p.max_anima, 1.0), en_col)
	var caps := Ink.caps_font()
	var figs := Ink.figures_font()
	_text(caps, Vector2(cx - 30.0 - bw, by - 8.0), "VITALITY", 10, Ink.DIM)
	_text(figs, Vector2(cx - 30.0 - bw, by - 8.0), "%d / %d" % [int(ceil(p.hp)), int(p.max_hp)], 12, Ink.PAPER, bw, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(figs, Vector2(cx + 30.0, by - 8.0), "%d" % int(p.anima), 12, Ink.PAPER)
	_text(caps, Vector2(cx + 30.0, by - 8.0), "SPIRIT", 10, Ink.DIM, bw, HORIZONTAL_ALIGNMENT_RIGHT)
	# the diamond: an ink stone, a hairline inner edge, filling with pressure
	var dc := Vector2(cx, by + 6.0)
	_diamond(dc + Vector2(0, 3), 24.0, Color(0, 0, 0, 0.45))
	_diamond(dc, 24.0, Ink.INK)
	if not soul.release.is_empty():
		var sw := clampf(p.swell / 100.0, 0.0, 1.0)
		var rc := AbilityForge.color_of(soul.release)
		var pulse := 1.0
		if sw >= 1.0 or p.released:
			pulse = 0.78 + 0.22 * sin(_t * 8.0)
		_diamond(dc, 19.0 * sqrt(sw), Color(rc.r, rc.g, rc.b, pulse))
	_diamond(dc, 24.0, Ink.BONE, false, 1.5)
	_diamond(dc, 19.5, Color(accent.r, accent.g, accent.b, 0.55), false, 1.0)
	# stance: a thin line under it all, from the middle out
	var st := clampf(p.posture / maxf(p.posture_max, 1.0), 0.0, 1.0)
	if st > 0.01:
		var sc := Ink.BRASS.lerp(Ink.SEAL, st * st)
		draw_rect(Rect2(cx - 160.0, by + 22.0, 320.0, 3.0), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(cx - 160.0 * st, by + 22.0, 320.0 * st, 3.0), sc)
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2(cx + side * 160.0 - 1.0, by + 19.0, 2.0, 9.0), Ink.RULE)
	if not soul.release.is_empty():
		var label: String = "SPIRIT PRESSURE" if not p.released else ["FIRST RELEASE", "FIRST RELEASE", "FULL RELEASE", "LAST RELEASE"][clampi(int(soul.release.get("stage", 1)), 1, 3)]
		_text(caps, Vector2(cx - 120.0, by - 26.0), label, 10, Ink.DIM if not p.released else AbilityForge.color_of(soul.release).lerp(Color.WHITE, 0.3), 240.0, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_hotbar(p, soul, accent, h)
	# ---- who you are, on a strip of ink like the tracker's
	var id_h := 104.0 + (14.0 if soul.at_cap() else 0.0) + (26.0 if soul.marks > 0 else 0.0)
	draw_rect(Rect2(18, 14, 300, id_h), Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.5))
	draw_rect(Rect2(18, 14, 2, id_h), Color(accent.r, accent.g, accent.b, 0.85))
	var title := Quests.title(soul).to_upper()
	_text(caps, Vector2(28, 44), title, 22, Ink.PAPER)
	draw_rect(Rect2(28, 52, Ink.width_of(title, 22, caps), 1.0), Color(accent.r, accent.g, accent.b, 0.7))
	var lvl := "Level %d" % soul.level
	if soul.written():
		lvl += "   ·   Grade %d   ·   Standing %d" % [soul.grade, int(soul.standing)]
	_text(figs, Vector2(28, 72), lvl, 13, Ink.BONE)
	var xr := Rect2(28, 80, 220, 4)
	draw_rect(xr, Color(0, 0, 0, 0.55))
	draw_rect(Rect2(xr.position, Vector2(xr.size.x * clampf(soul.essence / soul.essence_needed(), 0.0, 1.0), xr.size.y)), Ink.BRASS if not soul.at_cap() else Ink.SEAL)
	if soul.at_cap():
		_text(Ink.body_font(), Vector2(28, 100), "Level cap. Seek promotion at your board.", 12, Ink.SEAL.lerp(Ink.PAPER, 0.3))
	var info_y := 118.0 if soul.at_cap() else 104.0
	Ink.diamond(self, Vector2(33, info_y - 4.0), 4.0, Ink.BRASS)
	_text(figs, Vector2(44, info_y), "%d shards" % soul.shards, 13, Ink.BRASS)
	var kx := 44.0 + Ink.width_of("%d shards" % soul.shards, 13, figs) + 18.0
	kx += Ink.keycap(self, Vector2(kx, info_y - 13.0), "I", true, 16.0) + 6.0
	_text(Ink.body_font(), Vector2(kx, info_y), "gear", 12, Ink.DIM)
	if soul.marks > 0:
		var mx := 28.0
		var my := info_y + 12.0
		mx += Ink.keycap(self, Vector2(mx, my), "K", true, 18.0) + 8.0
		_text(Ink.body_font(), Vector2(mx, my + 13.0), "%d skill point%s to spend" % [soul.marks, "" if soul.marks == 1 else "s"], 13, Ink.BRASS)
	# ---- a great enemy
	var boss := _boss()
	if boss != null:
		var bwid := minf(640.0, w * 0.46)
		var bx := cx - bwid * 0.5
		_text(caps, Vector2(bx, 96), boss.display_name.to_upper(), 16, Ink.PAPER)
		_text(figs, Vector2(bx, 96), "LV %d" % boss.level, 12, Ink.SEAL.lerp(Ink.PAPER, 0.25), bwid, HORIZONTAL_ALIGNMENT_RIGHT)
		Ink.bar(self, Rect2(bx, 104, bwid, 10), boss.hp / maxf(boss.max_hp, 1.0), Ink.SEAL, -1.0, false, 0.25)
		var bps := clampf(boss.posture / maxf(boss.posture_max, 1.0), 0.0, 1.0)
		draw_rect(Rect2(bx, 118, bwid, 2), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bx, 118, bwid * bps, 2), Ink.BRASS)
	if Player.shift_lock and p.lock_target == null and not p.scripted:
		var rc := Vector2(cx, h * 0.5)
		draw_arc(rc, 7.0, 0, TAU, 24, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, 0.75), 1.5)
		draw_circle(rc, 1.5, Ink.PAPER)
	_draw_compass(p)
	_draw_event()
	_draw_style(p)
	_draw_tracker(soul)
	_draw_erosion(soul)
	# ---- what E would do here
	var pt := place.prompt()
	if pt != "":
		var key := ""
		var rest := pt
		var parts := pt.split("  ", false, 1)
		if parts.size() == 2 and parts[0].length() <= 3:
			key = parts[0]
			rest = parts[1]
		var tw := Ink.width_of(rest, 15) + (40.0 if key != "" else 0.0) + 28.0
		var rr := Rect2(cx - tw * 0.5, h - 214.0, tw, 32.0)
		draw_rect(Rect2(rr.position + Vector2(0, 3), rr.size), Color(0, 0, 0, 0.35))
		draw_rect(rr, Ink.INK_SOFT)
		draw_rect(Rect2(rr.position, Vector2(2, rr.size.y)), Ink.BRASS)
		var px := rr.position.x + 14.0
		if key != "":
			px += Ink.keycap(self, Vector2(px, rr.position.y + 6.0), key, true, 20.0) + 10.0
		Ink.rich(self, Vector2(px, rr.position.y + 21.0), rest, 15, Ink.PAPER, tw)
	_draw_meditation()
	_draw_toasts()
	_draw_loot()
	_draw_banner()
	_draw_big()


## A ruler across the top: ticks every fifteen degrees, the cardinal points,
## and shapes for what you want. Boards brass squares, cairns pale diamonds,
## ways out triangles, great enemies red, what a notice wants white.
func _draw_compass(p: Player) -> void:
	var reg := place as Region
	if reg == null or place.cam == null:
		return
	var cx := size.x * 0.5
	var half_w := minf(300.0, size.x * 0.22)
	var y := 30.0
	var strip := Rect2(cx - half_w, y - 12.0, half_w * 2.0, 24.0)
	draw_rect(Rect2(strip.position + Vector2(0, 2), strip.size), Color(0, 0, 0, 0.3))
	draw_rect(strip, Ink.INK_SOFT)
	draw_rect(Rect2(strip.position.x, strip.end.y - 1.0, strip.size.x, 1.0), Ink.RULE)
	var yaw := place.cam.yaw
	var fov := deg_to_rad(110.0)
	var put := func(angle: float) -> float:
		var rel := wrapf(angle - yaw, -PI, PI)
		if absf(rel) > fov * 0.5:
			return -9999.0
		return cx - rel / (fov * 0.5) * half_w
	for k in range(24):
		var ang := TAU * float(k) / 24.0
		var x: float = put.call(ang)
		if x < -9000.0:
			continue
		var tall := 6.0 if k % 6 == 0 else (4.0 if k % 3 == 0 else 2.0)
		draw_rect(Rect2(x, strip.end.y - 1.0 - tall, 1.0, tall), Ink.RULE)
	var dirs: Array = [["N", 0.0], ["E", -PI * 0.5], ["S", PI], ["W", PI * 0.5]]
	for d: Variant in dirs:
		var dd: Array = d
		var x: float = put.call(float(dd[1]))
		if x > -9000.0:
			Ink.text(self, Vector2(x - 20.0, y + 3.0), String(dd[0]), 13, Ink.PAPER if String(dd[0]) == "N" else Ink.BONE, 40.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
	var labels: Array = []
	for m: Variant in reg.markers():
		var mm: Array = m
		var pos: Vector3 = mm[0]
		var to := pos - p.global_position
		var dist := Vector2(to.x, to.z).length()
		if dist < 2.0:
			continue
		var x: float = put.call(atan2(-to.x, -to.z))
		if x < -9000.0:
			continue
		var col: Color = mm[1]
		var kind := String(mm[2])
		var c := Vector2(x, y - 1.0)
		match kind:
			"board":
				draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Ink.BRASS)
				draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Color(0, 0, 0, 0.5), false, 1.0)
			"cairn":
				_diamond(c, 5.0, Color(0.75, 0.88, 0.95))
			"boss":
				_diamond(c, 7.0, Ink.SEAL)
				_diamond(c, 7.0, Ink.PAPER, false, 1.0)
			"sensed":
				draw_circle(c, 3.5, col)
				if mm.size() > 3:
					_text(Ink.figures_font(), Vector2(x - 20.0, y - 14.0), "%d" % int(mm[3]), 9, col, 40.0, HORIZONTAL_ALIGNMENT_CENTER)
			"event":
				_diamond(c, 8.0, Color(1.0, 0.25, 0.2), false, 2.0)
				_diamond(c, 3.0, Color(1.0, 0.25, 0.2))
			"giver":
				Ink.text(self, Vector2(c.x - 10.0, c.y + 6.0), "!", 15, Ink.BRASS, 20.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.title_font())
			"lost":
				draw_arc(c, 5.0, 0, TAU, 16, Color(0.8, 0.92, 1.0), 1.5)
				draw_circle(c, 1.8, Color(0.8, 0.92, 1.0))
			"chest":
				draw_rect(Rect2(c - Vector2(6, 3), Vector2(12, 8)), col)
				draw_rect(Rect2(c - Vector2(6, 3), Vector2(12, 8)), Ink.INK, false, 1.0)
				draw_line(c + Vector2(-6, 0), c + Vector2(6, 0), Ink.INK, 1.0)
			"orb":
				draw_circle(c, 3.5, col)
				draw_arc(c, 6.0, 0, TAU, 16, Color(col.r, col.g, col.b, 0.6), 1.0)
			"stone":
				draw_rect(Rect2(c - Vector2(2.5, 7), Vector2(5, 12)), Color(0.55, 0.55, 0.58))
				draw_rect(Rect2(c - Vector2(1.5, 4), Vector2(3, 3)), Ink.BRASS)
			"notice", "keepsake":
				_diamond(c, 5.0, col, false, 1.5)
				_diamond(c, 2.0, col)
			_:
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(5, 4), c + Vector2(-5, 4)]), Color(0.92, 0.45, 0.45))
		if kind == "notice" or kind == "boss" or kind == "keepsake" or kind == "lost" or kind == "event" or kind == "chest" or (kind == "orb" and reg.play != null and not reg.play.hint.is_empty()) or dist < 60.0:
			var crowded := false
			for lx: Variant in labels:
				if absf(float(lx) - x) < 46.0:
					crowded = true
			if not crowded:
				labels.append(x)
				_text(Ink.figures_font(), Vector2(x - 30.0, y + 26.0), "%d m" % int(dist), 10, Ink.BONE, 60.0, HORIZONTAL_ALIGNMENT_CENTER)
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, strip.position.y - 1), Vector2(cx + 5, strip.position.y - 1), Vector2(cx, strip.position.y + 5)]), Ink.BRASS)
	# the time of day, beside the strip: a sun or a moon, and its name
	if reg.daynight != null and reg.daynight.has_sky():
		var clk := reg.daynight.clock()
		var tc := Vector2(strip.end.x + 18.0, y)
		var nk := DayNight.night_k(clk)
		if nk > 0.5:
			draw_circle(tc, 6.0, Ink.BONE)
			draw_circle(tc + Vector2(2.5, -1.5), 5.0, Ink.INK)
		else:
			draw_circle(tc, 4.0, Ink.BRASS)
			for q in range(8):
				var qa := TAU * float(q) / 8.0
				draw_line(tc + Vector2(cos(qa), sin(qa)) * 6.0, tc + Vector2(cos(qa), sin(qa)) * 8.5, Ink.BRASS, 1.2)
		var sky_line := "%s  ·  %s" % [DayNight.phase_name(clk), DayNight.season_name(reg.soul)]
		if reg.weather != null and reg.weather.kind != "clear":
			sky_line += "  ·  " + reg.weather.label()
		Ink.lifted(self, Vector2(tc.x + 14.0, y + 4.0), sky_line.to_upper(), 10, Ink.BONE, -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())


## A world event under the compass: its name, what to do, time left.
func _draw_event() -> void:
	var reg := place as Region
	if reg == null:
		return
	var info: Dictionary = reg.events.info() if reg.events != null else {}
	if info.is_empty() and reg.play != null:
		info = reg.play.info()
	if info.is_empty():
		return
	var cx := size.x * 0.5
	var w := 400.0
	var r := Rect2(cx - w * 0.5, 60.0 if _boss() == null else 132.0, w, 52.0)
	var red := Color(0.9, 0.3, 0.25) if String(info["kind"]) != "storm" else Color(0.85, 0.35, 0.55)
	if String(info["kind"]) == "challenge":
		red = Ink.BRASS
	draw_rect(r, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.78))
	draw_rect(Rect2(r.position, Vector2(w, 1)), red)
	Ink.text(self, r.position + Vector2(14, 20), String(info["title"]).to_upper(), 12, red.lerp(Ink.PAPER, 0.2), -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
	var secs := int(info["seconds"])
	Ink.text(self, r.position + Vector2(0, 20), "%d:%02d" % [secs / 60, secs % 60], 12, Ink.BONE, w - 14.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	Ink.text(self, r.position + Vector2(14, 38), String(info["line"]), 12, Ink.PAPER, w - 28.0)
	draw_rect(Rect2(r.position.x, r.end.y - 2.0, w * clampf(float(info["left"]), 0.0, 1.0), 2.0), red)


## Top right: what the story wants, then the notices you carry, each with
## a box that fills when it is ready to hand in.
func _draw_tracker(soul: Soul) -> void:
	var reg := place as Region
	if reg == null:
		return
	var w := 340.0
	var x := size.x - w - 28.0
	var y := 26.0
	var obj := reg.objective()
	var lines_n := 0
	if obj != "":
		lines_n = mini(4, int(ceil(Ink.width_of(obj, 13) / (w - 28.0))) + 1)
	var quests: Array = Quests.active(soul)
	var hgt := 0.0
	if obj != "":
		hgt += 30.0 + 18.0 * float(lines_n)
	if not quests.is_empty():
		hgt += 26.0 + 22.0 * float(quests.size())
	if hgt <= 0.0:
		return
	var r := Rect2(x, y, w, hgt + 8.0)
	draw_rect(r, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.62))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Ink.BRASS)
	var cy := y + 22.0
	if obj != "":
		Ink.heading(self, Vector2(x + 14.0, cy), "Objective", w - 28.0, Ink.BRASS, 11)
		draw_multiline_string(Ink.body_font(), Vector2(x + 14.0, cy + 20.0), obj, HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 13, lines_n, Ink.PAPER)
		cy += 30.0 + 18.0 * float(lines_n)
	if not quests.is_empty():
		Ink.heading(self, Vector2(x + 14.0, cy), "Notices", w - 28.0, Ink.BONE, 11)
		cy += 22.0
		for id: String in quests:
			var ready := Quests.is_ready(soul, id)
			var box := Rect2(x + 14.0, cy - 10.0, 10.0, 10.0)
			if ready:
				draw_rect(box, Ink.BRASS)
			else:
				draw_rect(box, Ink.BONE, false, 1.0)
			var ln := Quests.line(soul, id)
			Ink.text(self, Vector2(x + 32.0, cy), ln, 13, Ink.BRASS if ready else Ink.PAPER, w - 46.0)
			cy += 22.0


const RANK_COLORS: Dictionary = {"D": Color(0.62, 0.6, 0.57), "C": Color(0.55, 0.78, 0.92), "B": Color(0.5, 0.82, 0.62), "A": Color(0.88, 0.72, 0.42), "S": Color(0.86, 0.36, 0.26), "SS": Color(0.9, 0.3, 0.55)}


func _draw_style(p: Player) -> void:
	var rank := p.style_rank()
	if rank == "":
		return
	var col: Color = RANK_COLORS[rank]
	var x := size.x - 210.0
	var y := size.y * 0.44
	var kick := 1.0 + 0.04 * sin(_t * 9.0)
	_text(Ink.title_font(), Vector2(x, y), rank, int(64.0 * kick), col, 180.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(Ink.caps_font(), Vector2(x, y + 22.0), "STYLE", 10, Ink.DIM, 180.0, HORIZONTAL_ALIGNMENT_RIGHT)
	if p.combo_hits > 1:
		_text(Ink.figures_font(), Vector2(x, y + 44.0), "%d hits" % p.combo_hits, 15, Ink.PAPER, 180.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var next := 0.0
	for r: Variant in p.STYLE_RANKS:
		if float((r as Array)[1]) > p.style_pts:
			next = float((r as Array)[1])
	var lo := 0.0
	for r: Variant in p.STYLE_RANKS:
		if String((r as Array)[0]) == rank:
			lo = float((r as Array)[1])
	var frac := 1.0 if next <= lo else clampf((p.style_pts - lo) / (next - lo), 0.0, 1.0)
	draw_rect(Rect2(x + 40.0, y + 52.0, 140.0, 3.0), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(x + 40.0 + 140.0 * (1.0 - frac), y + 52.0, 140.0 * frac, 3.0), col)


func _draw_erosion(soul: Soul) -> void:
	if int(soul.flags.get("training", 0)) != 1 or String(soul.flags.get("chapter", "")) != "training":
		return
	var e := clampf(float(soul.flags.get("erosion", 0.0)) / 100.0, 0.0, 1.0)
	var w := 400.0
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y - 182.0, w, 8.0)
	Ink.bar(self, r, e, Ink.SEAL.lerp(Color(1, 0.6, 0.2), 0.25 + 0.25 * sin(_t * 6.0)), -1.0, false, 0.1)
	_text(Ink.caps_font(), Vector2(r.position.x, r.position.y - 6.0), "HUNGER", 10, Ink.SEAL.lerp(Ink.PAPER, 0.3), w, HORIZONTAL_ALIGNMENT_CENTER)


func _boss() -> Enemy:
	for a in place.actors:
		if is_instance_valid(a) and a is Enemy and (a as Enemy).is_boss and (a as Enemy).aggro and a.alive and not a.yielded:
			return a
	return null


func _draw_world(p: Player) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for a in place.actors:
		if not is_instance_valid(a) or a == p or not a.alive or a.yielded:
			continue
		var e := a as Enemy
		if e == null or e.is_boss:
			continue
		if not e.aggro and e.hp >= e.max_hp:
			continue
		var wp := e.global_position + Vector3(0, e.rig.height + 0.35, 0)
		if cam.is_position_behind(wp) or wp.distance_to(cam.global_position) > 45.0:
			continue
		var sp := cam.unproject_position(wp)
		var bw := 64.0
		var rr := Rect2(sp.x - bw * 0.5, sp.y, bw, 5)
		draw_rect(rr.grow(1.0), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(rr.position, Vector2(bw * clampf(e.hp / e.max_hp, 0.0, 1.0), 5)), Ink.SEAL)
		var ps := clampf(e.posture / maxf(e.posture_max, 1.0), 0.0, 1.0)
		if ps > 0.01:
			draw_rect(Rect2(sp.x - bw * 0.5 * ps, sp.y + 7, bw * ps, 2), Ink.BRASS)
		_text(Ink.figures_font(), Vector2(sp.x - bw * 0.5 - 30.0, sp.y + 6.0), "%d" % e.level, 10, Ink.BONE, 26.0, HORIZONTAL_ALIGNMENT_RIGHT)
	if p.lock_target != null and is_instance_valid(p.lock_target):
		var c := p.lock_target.center()
		if not cam.is_position_behind(c):
			var sp := cam.unproject_position(c)
			var rr := 14.0 + sin(_t * 6.0) * 1.5
			for k in range(4):
				var a := TAU * float(k) / 4.0 + PI * 0.25
				var d := Vector2(cos(a), sin(a))
				draw_line(sp + d * rr, sp + d * (rr + 7.0), Ink.PAPER, 2.0)
			_diamond(sp, 2.5, Ink.PAPER)


func _draw_meditation() -> void:
	var reg := place as Region
	if reg == null or reg.meditation == null:
		return
	var m := reg.meditation
	var c := Vector2(size.x * 0.5, size.y * 0.36)
	draw_arc(c, 34.0, 0, TAU, 64, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.3), 1.5)
	draw_arc(c, 34.0 + 3.0 * 22.0, 0, TAU, 96, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.14), 1.0)
	if m.holding:
		draw_arc(c, 34.0 + minf(m.hold_t, 5.0) * 22.0, 0, TAU, 96, Ink.PAPER, 2.0)
	for i in range(Meditation.NEED):
		var dc := c + Vector2((float(i) - 2.0) * 22.0, 150.0)
		if i < m.breaths:
			_diamond(dc, 6.0, Ink.PAPER)
		else:
			_diamond(dc, 6.0, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.4), false, 1.0)


## The hotbar: one tray of ink holding four technique slots and the
## release. Each slot shows the technique's mark, its key, what it costs, a
## clock sweep while it returns, and a flash when it is back. Short names
## sit under the tray.
func _draw_hotbar(p: Player, soul: Soul, accent: Color, h: float) -> void:
	var cx := size.x * 0.5
	var sz := 56.0
	var gap := 8.0
	var rw := 64.0
	var spacer := 22.0
	var total := sz * 4.0 + gap * 3.0 + spacer + rw
	var x0 := cx - total * 0.5
	var y0 := h - 96.0
	var tray := Rect2(x0 - 12.0, y0 - 10.0, total + 24.0, sz + 38.0)
	_draw_side_slots(p, tray)
	_draw_race_slot(p, soul, tray)
	draw_rect(Rect2(tray.position + Vector2(0, 3), tray.size), Color(0, 0, 0, 0.3))
	draw_rect(tray, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.72))
	draw_rect(Rect2(tray.position.x, tray.position.y, tray.size.x, 1.0), Ink.RULE)
	Ink.ticks(self, tray, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.5), 8.0, 1.5)
	var figs := Ink.figures_font()
	var en_col := accent.lerp(Color(0.35, 0.75, 0.95), 0.45)
	for i in range(4):
		var r := Rect2(x0 + float(i) * (sz + gap), y0, sz, sz)
		var t := p.technique(i)
		var name_c := Ink.DIM
		if t.is_empty():
			draw_rect(r, Color(0, 0, 0, 0.25))
			Ink.dashed(self, r.grow(-3.0), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.22))
			Ink.keycap(self, r.position + Vector2(4, 4), str(i + 1), false, 15.0)
			continue
		var cd := p.tech_cd[i]
		var cd_max := maxf(float(t["cd"]) * float(p.stats.get("tech_cd", 1.0)), 0.01)
		var cost := float(t["cost"]) * float(p.stats.get("tech_cost", 1.0))
		var afford := p.anima >= cost
		var ready := cd <= 0.0 and afford
		draw_rect(r, Color(0.085, 0.078, 0.072, 0.95))
		draw_rect(Rect2(r.position, Vector2(sz, sz * 0.5)), Color(1, 1, 1, 0.025))
		var gcol := Ink.PAPER if ready else (Ink.BONE if cd <= 0.0 else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.45))
		if cd <= 0.0 and not afford:
			gcol = Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.4)
		Ink.glyph(self, String(t.get("kind", "")), r.get_center() + Vector2(0, -2), 14.0, gcol, 2.0)
		if cd > 0.0:
			Ink.sweep(self, r, clampf(cd / cd_max, 0.0, 1.0), Color(0, 0, 0, 0.62))
			var label := ("%.1f" % cd) if cd < 3.0 else ("%d" % int(ceil(cd)))
			Ink.lifted(self, Vector2(r.position.x, r.position.y + sz * 0.5 + 7.0), label, 17, Ink.PAPER, sz, HORIZONTAL_ALIGNMENT_CENTER, figs)
		# cost in the corner, red when you cannot pay it
		var cost_s := "%d" % int(round(cost))
		var cw := Ink.width_of(cost_s, 10, figs)
		Ink.diamond(self, Vector2(r.end.x - cw - 10.0, r.end.y - 8.0), 2.5, en_col if afford else Ink.SEAL)
		Ink.text(self, Vector2(r.end.x - cw - 4.0, r.end.y - 4.0), cost_s, 10, Ink.BONE if afford else Ink.SEAL.lerp(Ink.PAPER, 0.2), -1.0, HORIZONTAL_ALIGNMENT_LEFT, figs)
		# edge: quiet, brighter when ready, a flash when it comes back
		draw_rect(r, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.55 if ready else 0.2), false, 1.0)
		if ready:
			draw_rect(Rect2(r.position.x, r.end.y - 2.0, sz, 2.0), accent)
			name_c = Ink.PAPER
		var fl := float(_flash[i])
		if fl > 0.0:
			var k := fl / 0.45
			draw_rect(r.grow(1.0 + 4.0 * (1.0 - k)), Color(1, 1, 1, k * 0.8), false, 1.5)
		Ink.keycap(self, r.position + Vector2(4, 4), str(i + 1), ready, 15.0)
		var short := String(t["name"]).get_slice(" ", String(t["name"]).get_slice_count(" ") - 1)
		Ink.text(self, Vector2(r.position.x - 6.0, r.end.y + 16.0), short.to_upper(), 10, name_c, sz + 12.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
	# the release slot, set apart: a diamond that fills with spirit pressure
	var rr := Rect2(x0 + sz * 4.0 + gap * 3.0 + spacer, y0, rw, sz)
	draw_rect(Rect2(rr.position.x - spacer * 0.5 - 0.5, rr.position.y + 8.0, 1.0, sz - 16.0), Ink.RULE)
	var tone := accent
	var rname := "unnamed"
	var rready := false
	var frac := 0.0
	if not soul.release.is_empty():
		tone = AbilityForge.color_of(soul.release)
		rname = String(soul.release["spirit"]) if not p.released else String(soul.release["verb"])
		frac = clampf(p.swell / 100.0, 0.0, 1.0)
		rready = p.swell >= 100.0 or (p.released and p.swell >= float(soul.release["special"]["cost"]))
	draw_rect(rr, Color(0.085, 0.078, 0.072, 0.95))
	if frac > 0.0:
		draw_rect(Rect2(rr.position.x, rr.end.y - sz * frac, rw, sz * frac), Color(tone.r, tone.g, tone.b, 0.16))
		draw_rect(Rect2(rr.position.x, rr.end.y - sz * frac, rw, 1.0), Color(tone.r, tone.g, tone.b, 0.7))
	var dc := rr.get_center()
	if soul.release.is_empty():
		Ink.diamond(self, dc, 13.0, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.3), false, 1.5)
	else:
		var pulse := 1.0
		if rready:
			pulse = 0.75 + 0.25 * sin(_t * 7.0)
		Ink.diamond(self, dc, 13.0 * sqrt(frac), Color(tone.r, tone.g, tone.b, pulse))
		Ink.diamond(self, dc, 13.0, Ink.PAPER if rready else Ink.BONE, false, 1.5)
	draw_rect(rr, Color(tone.r, tone.g, tone.b, 0.85) if rready else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.25), false, 1.0)
	Ink.ticks(self, rr, Color(tone.r, tone.g, tone.b, 0.95 if rready else 0.45), 6.0, 1.5)
	if float(_flash[4]) > 0.0:
		var k := float(_flash[4]) / 0.6
		draw_rect(rr.grow(1.0 + 6.0 * (1.0 - k)), Color(tone.r, tone.g, tone.b, k), false, 2.0)
	Ink.keycap(self, rr.position + Vector2(4, 4), "R", rready, 15.0)
	if p.released:
		Ink.text(self, Vector2(rr.position.x, rr.end.y - 5.0), "%d%%" % int(p.swell), 9, Ink.BONE, rw - 5.0, HORIZONTAL_ALIGNMENT_RIGHT, figs)
	Ink.text(self, Vector2(rr.position.x - 10.0, rr.end.y + 16.0), rname.to_upper(), 10, Ink.PAPER if rready else Ink.DIM, rw + 20.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())


## Two small slots on the tray's left: the critical (T) and the evasive
## (Q, only while being hit). A sweep while they return, a flash when back.
func _draw_side_slots(p: Player, tray: Rect2) -> void:
	var s := 40.0
	var x := tray.position.x - s - 10.0
	var slots: Array = [
		["T", "CRIT", p.crit_cd, Player.CRIT_CD, 6, "crit"],
		["Q", "EVASIVE", p.evasive_cd, Player.EVASIVE_CD, 5, "evasive"],
	]
	for k in range(2):
		var sl: Array = slots[k]
		var r := Rect2(x, tray.position.y + 4.0 + float(k) * (s + 6.0), s, s)
		var cd := float(sl[2])
		var ready := cd <= 0.0
		draw_rect(Rect2(r.position + Vector2(0, 2), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, Color(0.085, 0.078, 0.072, 0.92))
		var gc := Ink.PAPER if ready else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.4)
		var c := r.get_center() + Vector2(4, 3)
		if not ready:
			pass
		elif String(sl[5]) == "crit":
			Ink.diamond(self, c, 8.0, Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, 0.9 if ready else 0.35), false, 1.5)
			draw_line(c + Vector2(0, -4), c + Vector2(0, 1.5), gc, 1.8)
			draw_circle(c + Vector2(0, 4), 1.1, gc)
		else:
			draw_arc(c, 4.5, 0, TAU, 16, gc, 1.4)
			for q in range(4):
				var a := TAU * float(q) / 4.0 + PI * 0.25
				draw_line(c + Vector2(cos(a), sin(a)) * 7.0, c + Vector2(cos(a), sin(a)) * 10.0, gc, 1.4)
		if not ready:
			Ink.sweep(self, r, clampf(cd / float(sl[3]), 0.0, 1.0), Color(0, 0, 0, 0.6))
			Ink.lifted(self, Vector2(r.position.x, r.position.y + 25.0), "%d" % int(ceil(cd)), 13, Ink.PAPER, s, HORIZONTAL_ALIGNMENT_CENTER, Ink.figures_font())
		draw_rect(r, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.5 if ready else 0.18), false, 1.0)
		var fl := float(_flash[int(sl[4])])
		if fl > 0.0:
			var kk := fl / 0.45
			draw_rect(r.grow(1.0 + 4.0 * (1.0 - kk)), Color(1, 1, 1, kk * 0.8), false, 1.5)
		Ink.keycap(self, r.position + Vector2(3, 3), String(sl[0]), ready, 14.0)
		Ink.lifted(self, Vector2(r.position.x - 70.0, r.position.y + s * 0.5 + 4.0), String(sl[1]), 9, Ink.PAPER if ready else Ink.BONE, 64.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.caps_font())


## The race's power, on the tray's right: its own mark, X, its cooldown.
func _draw_race_slot(p: Player, soul: Soul, tray: Rect2) -> void:
	var s := 46.0
	var r := Rect2(tray.end.x + 10.0, tray.position.y + 4.0, s, s)
	var woke := soul.written() and Player.RACE_ARTS.has(soul.primary)
	draw_rect(Rect2(r.position + Vector2(0, 2), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Color(0.085, 0.078, 0.072, 0.92 if woke else 0.5))
	if not woke:
		Ink.dashed(self, r.grow(-3.0), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.2))
		Ink.keycap(self, r.position + Vector2(3, 3), "X", false, 14.0)
		return
	var art := p.race_art()
	var ready := (p.race_cd <= 0.0 or (int(art["charges"]) > 1 and p.race_charges > 0)) and p.anima >= float(art["cost"])
	var col := Strains.color_of(soul.primary, "")
	var gc := Ink.PAPER if ready else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.4)
	var c := r.get_center() + Vector2(3, 3)
	if ready or p.race_cd <= 0.0:
		match soul.primary:
			"vigil":
				for k in range(5):
					var x := c.x - 8.0 + 4.0 * float(k)
					draw_line(Vector2(x, c.y - 9.0), Vector2(x, c.y + 9.0), gc, 1.5)
				draw_arc(c, 10.0, 0, TAU, 20, gc, 1.0)
			"maw":
				var pts := PackedVector2Array()
				for k in range(7):
					var a := TAU * float(k) / 6.0 + PI / 6.0
					pts.append(c + Vector2(cos(a), sin(a)) * 10.0)
				draw_polyline(pts, gc, 2.0)
				draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), gc, 1.5)
			"lumen":
				for k in range(3):
					var x2 := c.x - 8.0 + 6.0 * float(k)
					draw_polyline(PackedVector2Array([Vector2(x2, c.y - 6.0), Vector2(x2 + 5.0, c.y), Vector2(x2, c.y + 6.0)]), gc, 1.6)
			"relic":
				draw_arc(c + Vector2(-4, 0), 5.0, 0, TAU, 14, gc, 1.6)
				draw_arc(c + Vector2(4, 0), 5.0, 0, TAU, 14, gc, 1.6)
				draw_line(c + Vector2(9, -9), c + Vector2(13, -13), gc, 1.6)
	else:
		Ink.sweep(self, r, clampf(p.race_cd / float(art["cd"]), 0.0, 1.0), Color(0, 0, 0, 0.6))
		Ink.lifted(self, Vector2(r.position.x, r.position.y + 29.0), "%d" % int(ceil(p.race_cd)), 14, Ink.PAPER, s, HORIZONTAL_ALIGNMENT_CENTER, Ink.figures_font())
	draw_rect(r, Color(col.r, col.g, col.b, 0.85) if ready else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.2), false, 1.0)
	if p.hide_t > 0.0 or p.volley_t > 0.0:
		var left := p.hide_t / 6.0 if p.hide_t > 0.0 else p.volley_t / 2.5
		draw_rect(Rect2(r.position.x, r.end.y + 3.0, s * clampf(left, 0.0, 1.0), 2.0), col)
	if int(art["charges"]) > 1:
		for k in range(int(art["charges"])):
			Ink.diamond(self, Vector2(r.end.x - 7.0 - 8.0 * float(k), r.position.y + 7.0), 2.5, col if k < p.race_charges else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.3))
	if String(art["infusion"]) != "":
		var ic := Strains.color_of(String(art["infusion"]), "")
		draw_rect(Rect2(r.position.x, r.position.y, 3, r.size.y), ic)
	Ink.keycap(self, r.position + Vector2(3, 3), "X", ready, 14.0)
	Ink.lifted(self, Vector2(r.position.x - 10.0, r.end.y + 16.0), String(art["short"]), 9, Ink.PAPER if ready else Ink.BONE, s + 20.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())


## Messages down the left, newest last, each with a mark of its kind: a
## brass diamond for what you gained, a keycap frame for how to play, a
## short rule for what happens. Key names in the text become keycaps.
func _draw_toasts() -> void:
	var y := 168.0
	var place_soul: Soul = place.soul if place != null else null
	if place_soul != null and place_soul.marks > 0:
		y += 20.0
	if place_soul != null and place_soul.at_cap():
		y += 14.0
	for t: Variant in _toasts:
		var d: Dictionary = t
		var a := _fade(float(d["t"]), float(d["life"]))
		var slide := (1.0 - clampf(float(d["t"]) / 0.18, 0.0, 1.0)) * -12.0
		var kind := String(d["kind"])
		var text := String(d["text"])
		var wrap := 340.0
		var est := ceilf((Ink.width_of(text, 13) + 40.0) / wrap)
		var hh := maxf(1.0, est) * 22.0 + 12.0
		var r := Rect2(28.0 + slide, y, wrap + 76.0, hh)
		draw_rect(r, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.66 * a))
		var mc := Vector2(r.position.x + 14.0, r.position.y + 17.0)
		match kind:
			"gain":
				Ink.diamond(self, mc, 4.5, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
			"hint":
				draw_rect(Rect2(mc - Vector2(5, 5), Vector2(10, 10)), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.7 * a), false, 1.0)
			_:
				draw_rect(Rect2(mc - Vector2(5, 0.5), Vector2(10, 1)), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, a))
		var col := Ink.PAPER if kind != "hint" else Ink.BONE
		var used := Ink.rich(self, Vector2(r.position.x + 30.0, y + 21.0), text, 13, Color(col.r, col.g, col.b, a), wrap)
		var n := int(d.get("n", 1))
		if n > 1:
			Ink.text(self, Vector2(r.position.x, y + 21.0), "x%d" % n, 11, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a), r.size.x - 10.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
		r.size.y = maxf(r.size.y, used + 6.0)
		y += r.size.y + 6.0


## Pickups, bottom right: a swatch, the name, and a count that adds up
## while you keep walking over the same thing. A dropped charm or piece gets
## a taller card in its rarity's colour.
func _draw_loot() -> void:
	var x := size.x - 300.0
	var y := size.y - 120.0
	for i in range(_loot.size() - 1, -1, -1):
		var d: Dictionary = _loot[i]
		var a := _fade(float(d["t"]), float(d["life"]))
		var slide := (1.0 - clampf(float(d["t"]) / 0.18, 0.0, 1.0)) * 16.0
		if d.has("drop"):
			var parts: PackedStringArray = d["drop"]
			var rcol: Color = BoardUI.RARITY_COLORS.get(parts[0] if parts.size() > 0 else "Common", Ink.BONE)
			var r := Rect2(x + slide, y - 58.0, 272.0, 54.0)
			draw_rect(r, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.85 * a))
			draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(rcol.r, rcol.g, rcol.b, a))
			Ink.text(self, r.position + Vector2(14, 18), (parts[0] if parts.size() > 0 else "").to_upper(), 9, Color(rcol.r, rcol.g, rcol.b, a), -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
			Ink.text(self, r.position + Vector2(14, 34), parts[1] if parts.size() > 1 else "", 13, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a), 250.0)
			Ink.rich(self, r.position + Vector2(14, 47), parts[2] if parts.size() > 2 else "", 10, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.75 * a), 260.0)
			y -= 60.0
			continue
		var key := String(d["key"])
		var mat: Dictionary = Items.MATERIALS.get(key, {"name": key})
		var r := Rect2(x + slide, y - 26.0, 272.0, 24.0)
		draw_rect(r, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.66 * a))
		var mc: Color = Ink.MATERIAL_COLORS.get(key, Ink.BONE)
		Ink.swatch(self, r.position + Vector2(10, 7), Color(mc.r, mc.g, mc.b, a), 10.0)
		Ink.text(self, r.position + Vector2(28, 17), String(mat["name"]), 12, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a))
		var bump := 1.0 + 0.25 * maxf(0.0, 1.0 - float(d["bump"]) / 0.15)
		Ink.text(self, r.position + Vector2(0, 17), "+%d" % int(d["n"]), int(12.0 * bump), Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a), r.size.x - 10.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
		y -= 28.0


## A level or a grade: a short banner high in the middle, with what it
## gives you underneath.
func _draw_banner() -> void:
	if _banner.is_empty():
		return
	var t := float(_banner["t"])
	var a := _fade(t, float(_banner["life"]))
	var parts := String(_banner["text"]).split("|")
	var head := parts[0].to_upper()
	var sub := parts[1] if parts.size() > 1 else ""
	var w := size.x
	var y := size.y * 0.32
	var f := Ink.caps_font()
	var grow := clampf(t / 0.35, 0.0, 1.0)
	var tw := Ink.width_of(head, 30, f)
	var band := Rect2(w * 0.5 - (tw * 0.5 + 90.0) * grow, y - 40.0, (tw + 180.0) * grow, 72.0)
	draw_rect(band, Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.7 * a))
	draw_rect(Rect2(band.position.x, band.position.y, band.size.x, 1.0), Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
	draw_rect(Rect2(band.position.x, band.end.y - 1.0, band.size.x, 1.0), Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a * 0.5))
	Ink.text(self, Vector2(0, y), head, 30, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a), w, HORIZONTAL_ALIGNMENT_CENTER, f)
	if sub != "":
		var sw := Ink.width_of(sub, 13) + 40.0
		Ink.rich(self, Vector2(w * 0.5 - sw * 0.5 + 10.0, y + 22.0), sub, 13, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, a), sw + 20.0)


func _draw_big() -> void:
	var w := size.x
	var h := size.y
	for k: Variant in _big.keys():
		var b: Dictionary = _big[k]
		var a := _fade(float(b["t"]), float(b["life"]))
		var text := String(b["text"])
		match String(k):
			"boss", "region":
				var y := h * 0.22
				var f := Ink.caps_font()
				var sz := 38
				var up := text.to_upper()
				var tw := Ink.width_of(up, sz, f)
				var grow := clampf(float(b["t"]) / 0.6, 0.0, 1.0)
				Ink.lifted(self, Vector2(0, y), up, sz, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a), w, HORIZONTAL_ALIGNMENT_CENTER, f)
				var rule := 90.0 * grow
				for side: float in [-1.0, 1.0]:
					var x0 := w * 0.5 + side * (tw * 0.5 + 24.0)
					draw_rect(Rect2(x0 if side > 0.0 else x0 - rule, y - sz * 0.32, rule, 1.0), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, a * 0.8))
					_diamond(Vector2(x0 + side * (rule + 6.0), y - sz * 0.32), 3.0, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
			"release":
				var col := Ink.PAPER
				if place != null and is_instance_valid(place) and place.soul != null and not place.soul.release.is_empty():
					col = AbilityForge.color_of(place.soul.release).lerp(Color(1, 1, 1), 0.35)
				var grow := 1.0 + 0.18 * (1.0 - clampf(float(b["t"]) / 0.3, 0.0, 1.0))
				Ink.lifted(self, Vector2(0, h * 0.4), text, int(56.0 * grow), Color(col.r, col.g, col.b, a), w, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
			"death":
				draw_rect(Rect2(0, h * 0.42, w, 110.0), Color(0, 0, 0, 0.62 * a))
				draw_rect(Rect2(0, h * 0.42, w, 1.0), Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, a * 0.6))
				draw_rect(Rect2(0, h * 0.42 + 109.0, w, 1.0), Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, a * 0.6))
				Ink.text(self, Vector2(0, h * 0.42 + 68.0), text.to_upper(), 40, Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, a), w, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
			"whisper":
				var cw := minf(Ink.width_of(text, 17) + 60.0, w * 0.8)
				var lines := maxi(1, int(ceil((Ink.width_of(text, 17) + 60.0) / (w * 0.8))))
				var rr := Rect2(w * 0.5 - cw * 0.5, h * 0.66 - 26.0, cw, 22.0 * float(lines) + 18.0)
				draw_rect(rr, Color(0, 0, 0, 0.42 * a))
				draw_multiline_string(Ink.body_font(), Vector2(rr.position.x + 30.0, rr.position.y + 24.0), text, HORIZONTAL_ALIGNMENT_CENTER, cw - 60.0, 17, lines, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a))
			"talk":
				# the dialogue box: a name tab, the line typed out, a quiet rule
				var parts := text.split("|", true, 1)
				var who := parts[0] if parts.size() > 1 else ""
				var line := parts[1] if parts.size() > 1 else text
				var shown := line.substr(0, int(float(b["t"]) * 70.0))
				var cw := minf(720.0, w * 0.6)
				var n_lines := clampi(int(ceil(Ink.width_of(line, 16) / (cw - 48.0))), 1, 3)
				var bh := 34.0 + 24.0 * float(n_lines)
				var rr := Rect2(w * 0.5 - cw * 0.5, h - 258.0 - bh, cw, bh)
				var ink := Ink.INK
				ink.a = 0.9 * a
				draw_rect(Rect2(rr.position + Vector2(0, 4), rr.size), Color(0, 0, 0, 0.3 * a))
				draw_rect(rr, ink)
				draw_rect(Rect2(rr.position, Vector2(rr.size.x, 1)), Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
				if who != "":
					var nw := Ink.width_of(who.to_upper(), 12, Ink.caps_font()) + 28.0
					var tab := Rect2(rr.position + Vector2(18, -22), Vector2(nw, 22))
					draw_rect(tab, ink)
					draw_rect(Rect2(tab.position, Vector2(tab.size.x, 1)), Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
					Ink.text(self, tab.position + Vector2(14, 16), who.to_upper(), 12, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a), -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
				draw_multiline_string(Ink.body_font(), rr.position + Vector2(24, 34), shown, HORIZONTAL_ALIGNMENT_LEFT, cw - 48.0, 16, 3, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a))
			"stele":
				var cw := minf(780.0, w * 0.66)
				var rr := Rect2(w * 0.5 - cw * 0.5, h * 0.12, cw, 124.0)
				var ink := Ink.INK
				ink.a = 0.94 * a
				Ink.panel(self, rr, ink, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, a))
				Ink.diamond(self, Vector2(w * 0.5, rr.position.y + 22.0), 4.0, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, a))
				draw_multiline_string(Ink.caps_font(), rr.position + Vector2(30, 54), text, HORIZONTAL_ALIGNMENT_CENTER, cw - 60.0, 15, 3, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, a))

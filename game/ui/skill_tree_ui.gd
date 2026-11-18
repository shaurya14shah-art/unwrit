class_name SkillTreeUI
extends Control
## The skill tree, drawn as a chart. Your points sit in a seal at the
## centre; the four disciplines grow out of it toward the four corners, so
## the shape itself says the rules: neighbours sit side by side and lift
## each other, opposites face each other across the seal. Nodes are small
## engraved marks; only what you hold or can reach carries a name. Click a
## mark to inspect it on the right, E (or click Learn) to take it.

signal changed
signal closed

const ANGLE: Dictionary = {"blade": -2.36, "speed": -0.78, "body": 2.36, "spirit": 0.78}
const SWIRL: float = 0.22
const R0: float = 70.0
const STEP: float = 45.0

var soul: Soul
var hover: String = ""
var selected: String = ""
var _t: float = 0.0
var _hits: Array = []
var _tech_rows: Array = []
var _learn_rect: Rect2 = Rect2()
var _just: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(s: Soul) -> void:
	soul = s
	hover = ""
	if selected == "" or (not selected.ends_with(".m") and SkillTree.node(selected).is_empty()):
		selected = _first_open()
	visible = true
	Sfx.play("ui_open", -6.0)


func close() -> void:
	visible = false
	closed.emit()


func _first_open() -> String:
	for tier in range(1, SkillTree.TIERS + 1):
		for br: String in SkillTree.BRANCHES:
			for id: Variant in SkillTree.nodes_of(br, tier):
				if SkillTree.can_take(soul, String(id)):
					return String(id)
	return "blade.1"


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for k: Variant in _just.keys():
		_just[k] = float(_just[k]) - delta
		if float(_just[k]) <= 0.0:
			_just.erase(k)
	queue_redraw()


## Takes a skill (or a Mastery rank, "blade.m"). Returns true if it took.
func take(id: String) -> bool:
	var ok := false
	if id.ends_with(".m"):
		ok = SkillTree.master(soul, id.get_slice(".", 0))
	else:
		ok = SkillTree.take(soul, id)
	if ok:
		_just[id] = 0.7
		Sfx.play("levelup", -6.0, 1.25)
		changed.emit()
	else:
		Sfx.play("ui_tick", -6.0, 0.7)
	return ok


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		hover = _hit((e as InputEventMouseMotion).position)
	elif e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var at := (e as InputEventMouseButton).position
		if _learn_rect.has_point(at):
			take(selected)
			return
		var ti := _tech_at(at)
		if ti >= 0:
			soul.cycle_slot(ti)
			Sfx.play("ui_tick", -6.0)
			changed.emit()
			return
		var id := _hit(at)
		if id != "":
			if id == selected and (e as InputEventMouseButton).double_click:
				take(id)
			selected = id
			Sfx.play("ui_tick", -10.0, 1.3)


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).physical_keycode
		if k == KEY_E or k == KEY_ENTER or k == KEY_SPACE:
			take(selected)
			get_viewport().set_input_as_handled()


func _hit(at: Vector2) -> String:
	for h: Variant in _hits:
		if at.distance_to((h as Array)[0]) < 15.0:
			return String((h as Array)[1])
	return ""


func _tech_at(at: Vector2) -> int:
	for row: Variant in _tech_rows:
		if ((row as Array)[0] as Rect2).has_point(at):
			return int((row as Array)[1])
	return -1


# ----------------------------------------------------------------- layout

func _centre() -> Vector2:
	return Vector2((size.x - 450.0) * 0.5 + 10.0, size.y * 0.5 + 6.0)


## Where a tier sits on its discipline's arm; a fork side pushes it across.
func _pos(br: String, tier: float, side: float = 0.0) -> Vector2:
	var a := float(ANGLE[br]) + SWIRL * (tier / 9.0)
	var r := R0 + STEP * tier
	var p := _centre() + Vector2(cos(a), sin(a)) * r
	if side != 0.0:
		p += Vector2(-sin(a), cos(a)) * 25.0 * side
	return p


func _node_pos(id: String) -> Vector2:
	if id.ends_with(".m"):
		return _pos(id.get_slice(".", 0), 9.15)
	var d := SkillTree.node(id)
	var side := 0.0
	if id.ends_with("a"):
		side = -1.0
	elif id.ends_with("b"):
		side = 1.0
	return _pos(String(d["branch"]), float(d["tier"]), side)


# -------------------------------------------------------------------- draw

func _draw() -> void:
	if soul == null:
		return
	_hits.clear()
	_tech_rows.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Ink.INK)
	var c := _centre()
	# the chart's ground: faint tier rings, ruled like a seal's face
	for tier in range(1, SkillTree.TIERS + 2):
		draw_arc(c, R0 + STEP * float(tier), 0, TAU, 96, Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.035 if tier % 2 == 1 else 0.06), 1.0)
	for k in range(72):
		var a := TAU * float(k) / 72.0
		var r1 := R0 + STEP * 9.7
		draw_line(c + Vector2(cos(a), sin(a)) * r1, c + Vector2(cos(a), sin(a)) * (r1 + (8.0 if k % 6 == 0 else 3.0)), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.16), 1.0)
	# opposites across the seal: a dashed thread, red when both capstones are held
	for pair: Array in [["blade", "spirit"], ["speed", "body"]]:
		var both := SkillTree.opposed(soul, String(pair[0]))
		var a0 := _pos(String(pair[0]), 0.2)
		var a1 := _pos(String(pair[1]), 0.2)
		var col := Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, 0.85 if both else 0.18)
		for i in range(10):
			draw_line(a0.lerp(a1, float(i) / 10.0), a0.lerp(a1, float(i) / 10.0 + 0.05), col, 1.0)
	# neighbours: an arc between the roots, as thick as the harmony between
	for pair: Array in [["blade", "speed"], ["speed", "spirit"], ["spirit", "body"], ["body", "blade"]]:
		var low := mini(SkillTree.depth(soul, String(pair[0])), SkillTree.depth(soul, String(pair[1])))
		var a_from := float(ANGLE[pair[0]])
		var a_to := float(ANGLE[pair[1]])
		if a_to < a_from:
			a_to += TAU
		draw_arc(c, R0 - 14.0, a_from + 0.22, a_to - 0.22, 24, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, 0.15 + 0.12 * float(mini(low, 5))), 1.0 + 0.6 * float(mini(low, 5)))
	for br: String in SkillTree.BRANCHES:
		_draw_arm(br)
	_draw_seal(c)
	_draw_corners()
	_draw_panel()
	Ink.hints(self, Vector2(32, size.y - 24.0), [["Click", "inspect"], ["E", "learn"], ["K", "close"]])


## One discipline: the line it grows along, then its marks.
func _draw_arm(br: String) -> void:
	var col: Color = SkillTree.BRANCH[br]["color"]
	var faint := Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.12)
	var prev: Array = [_pos(br, 0.35)]
	var prev_taken := true
	for tier in range(1, SkillTree.TIERS + 1):
		var ids := SkillTree.nodes_of(br, tier)
		var here: Array = []
		for id: Variant in ids:
			here.append(_node_pos(String(id)))
		for k in range(ids.size()):
			var taken := soul.tree.has(String(ids[k]))
			for p: Variant in prev:
				var lit := taken and prev_taken
				draw_line(p, here[k], Color(col.r, col.g, col.b, 0.9) if lit else faint, 2.0 if lit else 1.0)
		prev = here
		prev_taken = SkillTree.tier_taken(soul, br, tier)
	var cap := soul.tree.has(br + ".8")
	var mp := _node_pos(br + ".m")
	var last: Vector2 = prev[0]
	for i in range(4):
		var t0 := float(i) / 4.0
		draw_line(last.lerp(mp, t0), last.lerp(mp, t0 + 0.12), Color(col.r, col.g, col.b, 0.7) if cap else faint, 1.0)
	for tier in range(1, SkillTree.TIERS + 1):
		for id: Variant in SkillTree.nodes_of(br, tier):
			_draw_mark(String(id), col)
	_draw_mastery(br, col)


## A mark: a ring of the discipline's colour, filled when held, an engraved
## glyph for what it is, and a name only if it is held or within reach.
func _draw_mark(id: String, col: Color) -> void:
	var d := SkillTree.node(id)
	var p := _node_pos(id)
	var taken := soul.tree.has(id)
	var sib := SkillTree.sibling(id)
	var closed_fork := sib != "" and soul.tree.has(sib)
	var open_now := SkillTree.can_take(soul, id)
	var cap := int(d["tier"]) == SkillTree.TIERS
	var rad := 15.0 if cap else 11.0
	var fill := Ink.INK
	var edge := Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.25)
	var ink := Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.35)
	if taken:
		fill = col.darkened(0.15)
		edge = col.lightened(0.25)
		ink = Ink.INK
	elif open_now:
		edge = Ink.BRASS
		ink = Ink.PAPER
	if closed_fork:
		edge = Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.1)
		ink = Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.15)
	if open_now:
		var breath := 0.5 + 0.5 * sin(_t * 3.0)
		draw_arc(p, rad + 4.0 + 2.0 * breath, 0, TAU, 32, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, 0.25 + 0.25 * breath), 1.0)
	if cap:
		var pts := PackedVector2Array()
		for k in range(6):
			var a := TAU * float(k) / 6.0 + PI / 6.0
			pts.append(p + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, edge, 1.5)
	else:
		draw_circle(p, rad, fill)
		draw_arc(p, rad, 0, TAU, 32, edge, 1.5)
	_draw_glyph(d, p, rad, ink)
	if closed_fork:
		draw_line(p + Vector2(-rad, rad), p + Vector2(rad, -rad), Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.25), 1.0)
	if id == selected:
		Ink.ticks(self, Rect2(p - Vector2(rad + 6.0, rad + 6.0), Vector2(rad + 6.0, rad + 6.0) * 2.0), Ink.PAPER, 5.0, 1.5)
	elif id == hover:
		draw_arc(p, rad + 5.0, 0, TAU, 32, Color(Ink.PAPER.r, Ink.PAPER.g, Ink.PAPER.b, 0.6), 1.0)
	if _just.has(id):
		var k := float(_just[id]) / 0.7
		draw_arc(p, rad + 4.0 + 22.0 * (1.0 - k), 0, TAU, 40, Color(col.r, col.g, col.b, k), 2.0)
	if id == selected or id == hover:
		_label(p, rad, String(d["name"]), Ink.PAPER)
	_hits.append([p, id])


## The engraving inside a mark says what kind of skill it is.
func _draw_glyph(d: Dictionary, p: Vector2, rad: float, ink: Color) -> void:
	var f: Array = (d["fx"] as Array)[0]
	match String(f[0]):
		"tech":
			Ink.glyph(self, String(f[1]), p, rad * 0.55, ink, 1.5)
		"stat":
			for k in range(3):
				draw_circle(p + Vector2(-4.0 + 4.0 * float(k), 0), 1.4, ink)
		"rite":
			draw_arc(p + Vector2(-2.5, 0), 3.6, 0, TAU, 16, ink, 1.2)
			draw_arc(p + Vector2(2.5, 0), 3.6, 0, TAU, 16, ink, 1.2)
		_:
			var trade := false
			for fx: Variant in d["fx"]:
				if String((fx as Array)[0]) == "pct" and float((fx as Array)[2]) < 0.0:
					trade = true
			draw_polyline(PackedVector2Array([p + Vector2(-4, 2), p + Vector2(0, -2.5), p + Vector2(4, 2)]), ink, 1.5)
			if trade:
				draw_line(p + Vector2(-4, 4.5), p + Vector2(4, 4.5), Color(Ink.SEAL.r, Ink.SEAL.g, Ink.SEAL.b, ink.a), 1.2)
	if int(d["tier"]) == SkillTree.TIERS:
		draw_arc(p, rad * 0.62, 0, TAU, 24, ink, 1.0)


func _label(p: Vector2, rad: float, text: String, col: Color) -> void:
	var left := p.x < _centre().x
	var w := Ink.width_of(text, 11)
	var x := p.x - rad - 12.0 - w if left else p.x + rad + 12.0
	draw_rect(Rect2(x - 6.0, p.y - 9.0, w + 12.0, 18.0), Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.92))
	draw_rect(Rect2(x - 6.0 if not left else x + w + 5.0, p.y - 9.0, 1.0, 18.0), Ink.BRASS)
	Ink.text(self, Vector2(x, p.y + 4.0), text, 11, col)


func _draw_mastery(br: String, col: Color) -> void:
	var id := br + ".m"
	var p := _node_pos(id)
	var cap := soul.tree.has(br + ".8")
	var ranks := int(soul.mastery.get(br, 0))
	var open_now := SkillTree.can_master(soul, br)
	for k in range(12):
		var a := TAU * float(k) / 12.0
		draw_arc(p, 10.0, a, a + TAU / 24.0, 3, Color(col.r, col.g, col.b, 0.8) if cap else Color(Ink.BONE.r, Ink.BONE.g, Ink.BONE.b, 0.18), 1.5)
	if ranks > 0:
		Ink.text(self, Vector2(p.x - 12.0, p.y + 4.0), "%d" % ranks, 10, Ink.PAPER, 24.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.figures_font())
	if open_now:
		draw_arc(p, 14.0 + sin(_t * 3.0), 0, TAU, 32, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, 0.5), 1.0)
	if id == selected:
		Ink.ticks(self, Rect2(p - Vector2(16, 16), Vector2(32, 32)), Ink.PAPER, 5.0, 1.5)
	if id == hover or id == selected:
		_label(p, 10.0, "Mastery %d" % ranks, Ink.PAPER)
	if _just.has(id):
		var k := float(_just[id]) / 0.7
		draw_arc(p, 14.0 + 20.0 * (1.0 - k), 0, TAU, 40, Color(col.r, col.g, col.b, k), 2.0)
	_hits.append([p, id])


## The seal at the centre: your unspent points.
func _draw_seal(c: Vector2) -> void:
	draw_circle(c, 44.0, Color(0.075, 0.068, 0.062))
	draw_arc(c, 44.0, 0, TAU, 64, Ink.RULE, 1.0)
	draw_arc(c, 38.0, 0, TAU, 64, Color(Ink.BRASS.r, Ink.BRASS.g, Ink.BRASS.b, 0.5 if soul.marks > 0 else 0.15), 1.0)
	for k in range(4):
		var a := PI * 0.25 + PI * 0.5 * float(k)
		Ink.diamond(self, c + Vector2(cos(a), sin(a)) * 44.0, 3.0, Ink.BRASS if soul.marks > 0 else Ink.DIM)
	Ink.text(self, Vector2(c.x - 40.0, c.y + 8.0), "%d" % soul.marks, 30, Ink.PAPER if soul.marks > 0 else Ink.DIM, 80.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.title_font())
	Ink.text(self, Vector2(c.x - 40.0, c.y + 24.0), "POINTS", 9, Ink.DIM, 80.0, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())


## Each discipline's name in its own corner, with how deep and how lifted.
func _draw_corners() -> void:
	var right := size.x - 470.0
	var spots := {"blade": [Vector2(36, 58), false], "speed": [Vector2(right, 58), true], "body": [Vector2(36, size.y - 104.0), false], "spirit": [Vector2(right, size.y - 104.0), true]}
	var base := Stats.base_totals(soul)
	for br: String in SkillTree.BRANCHES:
		var info: Dictionary = SkillTree.BRANCH[br]
		var col: Color = info["color"]
		var o: Vector2 = spots[br][0]
		var ra: bool = spots[br][1]
		var align := HORIZONTAL_ALIGNMENT_RIGHT if ra else HORIZONTAL_ALIGNMENT_LEFT
		var x := o.x - 300.0 if ra else o.x
		var title := String(info["title"]).to_upper()
		Ink.text(self, Vector2(x, o.y), title, 18, Ink.PAPER, 300.0, align, Ink.caps_font())
		draw_rect(Rect2((o.x - 32.0) if ra else o.x, o.y + 9.0, 32.0, 2.0), col)
		var dep := SkillTree.depth(soul, br)
		var h := SkillTree.harmony(soul, br)
		var line := "%s %d   ·   tier %d of 8" % [String(SkillTree.STAT_TITLE[info["stat"]]), int(base[info["stat"]]), dep]
		Ink.text(self, Vector2(x, o.y + 30.0), line, 12, Ink.BONE, 300.0, align, Ink.figures_font())
		var htxt := "harmony +%d%%" % int(round((h - 1.0) * 100.0)) if h > 1.001 else "no harmony yet"
		if SkillTree.opposed(soul, br):
			htxt += "   ·   opposed"
		Ink.text(self, Vector2(x, o.y + 48.0), htxt, 11, Ink.BRASS if h > 1.001 else Ink.DIM, 300.0, align)


# ------------------------------------------------------------------ panel

## The right side: what the selected mark is, what it does for you now,
## what it needs, and the Learn button. Then your numbers and techniques.
func _draw_panel() -> void:
	var px := size.x - 430.0
	var pw := 400.0
	var r := Rect2(px, 28.0, pw, size.y - 56.0)
	draw_rect(r, Color(0.07, 0.064, 0.058))
	draw_rect(Rect2(px, r.position.y, 1.0, r.size.y), Ink.RULE)
	var x := px + 28.0
	var w := pw - 56.0
	var y := r.position.y + 40.0
	var id := selected if selected != "" else hover
	_learn_rect = Rect2()
	if id.ends_with(".m"):
		y = _panel_mastery(id, x, y, w)
	elif id != "":
		y = _panel_skill(id, x, y, w)
	y = maxf(y + 26.0, size.y - 330.0)
	Ink.heading(self, Vector2(x, y), "Your numbers", w, Ink.BONE, 11)
	y += 24.0
	var st := Stats.compute(soul)
	var rows: Array = [
		["Vitality", "%d" % int(st["max_hp"])], ["Spirit energy", "%d" % int(st["max_anima"])],
		["Light cut", "%.1f" % float(st["light_dmg"])], ["Heavy cut", "%.1f" % float(st["heavy_dmg"])],
		["Techniques", "x%.2f" % float(st["tech_dmg"])], ["Parry", "%d ms" % int(float(st["parry_window"]) * 1000.0)],
		["Dash", "%.2f s" % float(st["dash_cd"])], ["Swing", "x%.2f" % float(st["attack_speed"])],
	]
	for i in range(rows.size()):
		var cx := x + float(i % 2) * (w * 0.5 + 8.0)
		var cy := y + 20.0 * float(i / 2)
		Ink.text(self, Vector2(cx, cy), String(rows[i][0]), 12, Ink.DIM)
		Ink.text(self, Vector2(cx, cy), String(rows[i][1]), 12, Ink.PAPER, w * 0.5 - 16.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	y += 20.0 * 4.0 + 22.0
	Ink.heading(self, Vector2(x, y), "Techniques   (click to move its key)", w, Ink.BONE, 11)
	y += 12.0
	if soul.techniques.is_empty():
		Ink.text(self, Vector2(x, y + 20.0), "None yet. Tier 4 of every discipline teaches one.", 12, Ink.DIM)
	for i in range(mini(4, soul.techniques.size())):
		var t: Dictionary = soul.techniques[i]
		var slot := soul.loadout.find(i)
		var on := slot >= 0 and slot < 4
		var rr := Rect2(x, y, w, 30.0)
		Ink.keycap(self, rr.position + Vector2(0, 6), str(slot + 1) if on else "-", on, 18.0)
		Ink.glyph(self, String(t.get("kind", "")), rr.position + Vector2(36, 15), 7.0, Ink.PAPER if on else Ink.DIM, 1.5)
		Ink.text(self, rr.position + Vector2(52, 19), String(t["name"]), 12, Ink.PAPER if on else Ink.DIM, w - 60.0)
		if bool(t.get("honed", false)):
			Ink.text(self, rr.position + Vector2(0, 19), "HONED", 10, Ink.BRASS, w, HORIZONTAL_ALIGNMENT_RIGHT, Ink.caps_font())
		_tech_rows.append([rr, i])
		y += 30.0


func _panel_skill(id: String, x: float, y: float, w: float) -> float:
	var d := SkillTree.node(id)
	var br := String(d["branch"])
	var info: Dictionary = SkillTree.BRANCH[br]
	var col: Color = info["color"]
	var taken := soul.tree.has(id)
	Ink.text(self, Vector2(x, y), String(info["title"]).to_upper(), 11, col, -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
	var kind := "tier %d" % int(d["tier"])
	if int(d["tier"]) == SkillTree.TIERS:
		kind += "  ·  capstone"
	elif SkillTree.sibling(id) != "":
		kind += "  ·  fork"
	Ink.text(self, Vector2(x, y), kind, 11, Ink.DIM, w, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	y += 34.0
	Ink.text(self, Vector2(x, y), String(d["name"]), 26, Ink.PAPER, w, HORIZONTAL_ALIGNMENT_LEFT, Ink.title_font())
	y += 30.0
	var f0: Array = (d["fx"] as Array)[0]
	if String(f0[0]) == "tech":
		var kind_t := String(f0[1])
		Ink.glyph(self, kind_t, Vector2(x + 18.0, y + 22.0), 14.0, Ink.PAPER, 2.0)
		draw_multiline_string(Ink.body_font(), Vector2(x + 48.0, y + 14.0), String(AbilityForge.TECH[kind_t]["line"]), HORIZONTAL_ALIGNMENT_LEFT, w - 48.0, 13, 3, Ink.BONE)
		y += 62.0
		var known := SkillTree.known_technique(soul, kind_t)
		if known >= 0 and not taken:
			Ink.text(self, Vector2(x, y), "You know it already. Learning this hones it:", 12, Ink.BRASS)
			y += 22.0
			y = _effect(x, y, w, "+12%", "damage", true)
			y = _effect(x, y, w, "-8%", "cooldown", true)
		else:
			var prev := AbilityForge.technique(kind_t, soul.seed, Stats.base_totals(soul), soul.profile, soul.techniques.size())
			var lift := float((Stats.compute(soul)["tech_kind"] as Dictionary).get(kind_t, 1.0))
			y = _effect(x, y, w, "%d" % int(float(prev["dmg"]) * lift), "damage", true)
			y = _effect(x, y, w, "%.1f s" % float(prev["cd"]), "cooldown", true)
			y = _effect(x, y, w, "%d" % int(float(prev["cost"])), "spirit energy", true)
			Ink.text(self, Vector2(x, y + 6.0), String(prev["quirk"]), 11, Ink.DIM, w)
			y += 24.0
	else:
		var k := SkillTree.shown_k(soul, id)
		var ck := SkillTree.cost_k(soul, id)
		for fx: Variant in d["fx"]:
			var f: Array = fx
			match String(f[0]):
				"stat":
					y = _effect(x, y, w, "+%d" % int(f[2]), String(SkillTree.STAT_TITLE[f[1]]), true)
				"pct":
					var amt := float(f[2]) * (k if float(f[2]) > 0.0 else ck)
					y = _effect(x, y, w, "%+.1f%%" % (amt * 100.0), String(SkillTree.TARGET_WORDS.get(f[1], f[1])), amt > 0.0)
				"rite":
					y = _effect(x, y, w, "+%.1f%%" % (float(f[3]) * k * 100.0), "%s per 10 %s" % [String(SkillTree.TARGET_WORDS.get(f[1], f[1])), String(SkillTree.STAT_TITLE[f[2]])], true)
		var has_gain := false
		for fx: Variant in d["fx"]:
			if String((fx as Array)[0]) in ["pct", "rite"] and float((fx as Array)[(fx as Array).size() - 1]) > 0.0:
				has_gain = true
		if has_gain:
			var hab := SkillTree.habit_k(soul, id) if not taken else float((soul.tree[id] as Dictionary).get("k", 1.0))
			Ink.text(self, Vector2(x, y + 10.0), "habit x%.2f   ·   harmony x%.2f" % [hab, SkillTree.harmony(soul, br)], 11, Ink.DIM, w, HORIZONTAL_ALIGNMENT_LEFT, Ink.figures_font())
			y += 26.0
	y += 10.0
	y = _needs(id, d, x, y, w)
	y += 14.0
	var br_rect := Rect2(x, y, w, 44.0)
	var why := SkillTree.why_not(soul, id)
	var live := why == ""
	draw_rect(br_rect, Color(0.12, 0.105, 0.085) if live else Color(0.09, 0.083, 0.076))
	draw_rect(br_rect, Ink.BRASS if live else Ink.FAINT, false, 1.0)
	if taken:
		Ink.text(self, Vector2(x, y + 28.0), "LEARNED", 13, col, w, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
	else:
		var label := "LEARN" if live else ("CLOSED" if why.begins_with("Closed") else "LOCKED")
		var kw := Ink.keycap(self, Vector2(x + 14.0, y + 12.0), "E", live, 20.0)
		Ink.text(self, Vector2(x + 24.0 + kw, y + 28.0), label, 14, Ink.PAPER if live else Ink.DIM, -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
		var cost_s := "%d" % int(d["cost"])
		var cw := Ink.width_of(cost_s, 15, Ink.figures_font())
		Ink.diamond(self, Vector2(br_rect.end.x - 26.0 - cw, y + 22.0), 4.0, Ink.BRASS if live else Ink.DIM)
		Ink.text(self, Vector2(x, y + 28.0), cost_s, 15, Ink.BRASS if live else Ink.DIM, w - 14.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
		if live:
			_learn_rect = br_rect
	return y + 44.0


## One effect line: the figure large, the words beside it.
func _effect(x: float, y: float, w: float, figure: String, words: String, good: bool) -> float:
	var fc := Ink.PAPER if good else Ink.SEAL.lerp(Ink.PAPER, 0.25)
	Ink.text(self, Vector2(x, y + 16.0), figure, 18, fc, 80.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	Ink.text(self, Vector2(x + 94.0, y + 15.0), words, 13, Ink.BONE, w - 94.0)
	return y + 26.0


func _tick(c: Vector2, ok_row: bool) -> void:
	if ok_row:
		draw_polyline(PackedVector2Array([c + Vector2(-4, 0), c + Vector2(-1, 3), c + Vector2(5, -4)]), Ink.JADE, 1.5)
	else:
		draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), Ink.SEAL, 1.5)
		draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), Ink.SEAL, 1.5)


## The requirements, each with a tick or a cross.
func _needs(id: String, d: Dictionary, x: float, y: float, w: float) -> float:
	var br := String(d["branch"])
	var tier := int(d["tier"])
	var rows: Array = []
	if tier > 1:
		rows.append([SkillTree.tier_taken(soul, br, tier - 1), "Tier %d of %s" % [tier - 1, String(SkillTree.BRANCH[br]["title"])]])
	var need := SkillTree.support_need(tier)
	if need > 0:
		var nbs: Array = SkillTree.NEIGHBOURS[br]
		rows.append([SkillTree.supported(soul, br, tier), "%s or %s at tier %d" % [String(SkillTree.BRANCH[nbs[0]]["title"]), String(SkillTree.BRANCH[nbs[1]]["title"]), need]])
	var sib := SkillTree.sibling(id)
	if sib != "":
		var free := not soul.tree.has(sib)
		rows.append([free, ("Closes %s for good" if free else "Closed: you took %s") % String(SkillTree.node(sib)["name"])])
	if tier == SkillTree.TIERS:
		var opp := String(SkillTree.OPPOSITE[br])
		rows.append([not soul.tree.has(opp + ".8"), "Costs double while %s's capstone is held" % String(SkillTree.BRANCH[opp]["title"])])
	if not soul.tree.has(id) and soul.marks < int(d["cost"]):
		rows.append([false, "%d skill point%s" % [int(d["cost"]), "" if int(d["cost"]) == 1 else "s"]])
	for row: Variant in rows:
		var ok_row := bool((row as Array)[0])
		_tick(Vector2(x + 5.0, y + 10.0), ok_row)
		Ink.text(self, Vector2(x + 20.0, y + 14.0), String((row as Array)[1]), 12, Ink.BONE if ok_row else Ink.PAPER, w - 20.0)
		y += 22.0
	return y


func _panel_mastery(id: String, x: float, y: float, w: float) -> float:
	var br := id.get_slice(".", 0)
	var info: Dictionary = SkillTree.BRANCH[br]
	Ink.text(self, Vector2(x, y), String(info["title"]).to_upper(), 11, info["color"], -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
	y += 34.0
	Ink.text(self, Vector2(x, y), "Mastery", 26, Ink.PAPER, w, HORIZONTAL_ALIGNMENT_LEFT, Ink.title_font())
	y += 34.0
	y = _effect(x, y, w, "+%d" % SkillTree.MASTERY_STAT, "%s each rank, without end" % String(SkillTree.STAT_TITLE[info["stat"]]), true)
	y = _effect(x, y, w, "%d" % int(soul.mastery.get(br, 0)), "ranks held", true)
	y += 10.0
	_tick(Vector2(x + 5.0, y + 10.0), soul.tree.has(br + ".8"))
	Ink.text(self, Vector2(x + 20.0, y + 14.0), "The capstone of %s" % String(info["title"]), 12, Ink.BONE)
	y += 36.0
	var live := SkillTree.can_master(soul, br)
	var br_rect := Rect2(x, y, w, 44.0)
	draw_rect(br_rect, Color(0.12, 0.105, 0.085) if live else Color(0.09, 0.083, 0.076))
	draw_rect(br_rect, Ink.BRASS if live else Ink.FAINT, false, 1.0)
	var kw := Ink.keycap(self, Vector2(x + 14.0, y + 12.0), "E", live, 20.0)
	Ink.text(self, Vector2(x + 24.0 + kw, y + 28.0), "TRAIN" if live else "LOCKED", 14, Ink.PAPER if live else Ink.DIM, -1.0, HORIZONTAL_ALIGNMENT_LEFT, Ink.caps_font())
	Ink.text(self, Vector2(x, y + 28.0), "%d" % SkillTree.MASTERY_COST, 15, Ink.BRASS if live else Ink.DIM, w - 14.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	if live:
		_learn_rect = br_rect
	return y + 44.0

class_name Menus
extends Control
## Title, pause and the soul sheet, in the Ledger's ink (see Ink): flat
## buttons with a rule under the focused one, spaced capitals.

signal chose(what: String)

const INK := Color(0.045, 0.045, 0.06)
const PALE := Color(0.9, 0.9, 0.93)
const DIM := Color(0.55, 0.56, 0.6)
const GOLD := Color(1.0, 0.82, 0.4)

var title_font: Font
var body_font: Font
var mode: String = ""
var soul: Soul
var _box: VBoxContainer
var _t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_font = load("res://assets/fonts/Cinzel.ttf") if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf") else ThemeDB.fallback_font
	body_font = load("res://assets/fonts/Inter.ttf") if ResourceLoader.exists("res://assets/fonts/Inter.ttf") else ThemeDB.fallback_font
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	visible = false


func _button(text: String, what: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(280, 46)
	b.add_theme_font_override("font", Ink.caps_font())
	b.add_theme_font_size_override("font_size", 15)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.86) if state == "normal" else (Color(0.12, 0.11, 0.1, 0.95) if state != "pressed" else Color(0.18, 0.16, 0.13))
		sb.border_color = Ink.BRASS if state != "normal" else Ink.RULE
		sb.border_width_left = 2 if state != "normal" else 1
		sb.border_width_top = 0 if state != "normal" else 1
		sb.border_width_right = 0 if state != "normal" else 1
		sb.border_width_bottom = 2 if state != "normal" else 1
		sb.content_margin_left = 22
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Ink.BRASS if primary else Ink.PAPER)
	b.add_theme_color_override("font_hover_color", Ink.PAPER)
	b.add_theme_color_override("font_focus_color", Ink.PAPER)
	b.add_theme_color_override("font_pressed_color", Ink.BRASS)
	b.pressed.connect(_pressed.bind(what))
	b.mouse_entered.connect(Sfx.play.bind("ui_tick", -14.0, 1.0, 0.05))
	_box.add_child(b)
	return b


func _pressed(what: String) -> void:
	Sfx.play("ui_open", -6.0)
	chose.emit(what)


func show_title(has_save: bool) -> void:
	mode = "title"
	_fill([["Continue", "continue", true]] if has_save else [])
	_button("New Soul", "new", not has_save)
	_button("Settings", "settings")
	_button("Quit", "quit")
	_place(Vector2(0.5, 0.62))


func show_pause(s: Soul, blur_label: String = "Motion blur") -> void:
	mode = "pause"
	soul = s
	var _b := blur_label
	_fill([["Return", "resume", true], ["Skill Tree", "lattice", false], ["Settings", "settings", false], ["Controls", "controls", false], ["Leave to Title", "title", false], ["Quit", "quit", false]])
	_place(Vector2(0.2, 0.5))


## One button per setting; pressing one steps it to its next value.
var back_to: String = "pause"

func show_settings(from: String) -> void:
	back_to = from
	mode = "settings"
	var items: Array = []
	for k: Variant in Settings.ORDER:
		items.append([Settings.label(String(k)), "set_" + String(k), false])
	items.append(["Controls", "controls", false])
	items.append(["Back", "back", true])
	_fill(items)
	_place(Vector2(0.2, 0.5))


func show_controls(from: String) -> void:
	back_to = from
	mode = "controls"
	_fill([["Back", "back", true]])
	_place(Vector2(0.2, 0.86))


func _fill(items: Array) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	for it: Variant in items:
		var d: Array = it
		_button(String(d[0]), String(d[1]), bool(d[2]))
	visible = true


func _place(anchor: Vector2) -> void:
	_box.reset_size()
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_box.position = Vector2(size.x * anchor.x - _box.size.x * 0.5, size.y * anchor.y - _box.size.y * 0.5)
	if _box.get_child_count() > 0:
		(_box.get_child(0) as Button).grab_focus()


func hide_all() -> void:
	visible = false
	mode = ""


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _line(pos: Vector2, text: String, s: int, col: Color, font: Font = null, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font if font != null else body_font, pos, text, align, width, s, col)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if mode == "title":
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.018, 0.016, 0.5))
		# a band of ink behind the name, ruled top and bottom
		var band := Rect2(0, h * 0.2, w, h * 0.24)
		draw_rect(band, Color(0.02, 0.018, 0.016, 0.55))
		draw_rect(Rect2(0, band.position.y, w, 1), Ink.RULE)
		draw_rect(Rect2(0, band.end.y, w, 1), Ink.RULE)
		var tf := FontVariation.new()
		tf.base_font = title_font
		tf.spacing_glyph = 18
		Ink.lifted(self, Vector2(0, h * 0.34), "UNWRIT", 120, Ink.PAPER, w, HORIZONTAL_ALIGNMENT_CENTER, tf)
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2(w * 0.5 + (40.0 if side > 0.0 else -200.0), h * 0.34 + 30, 160, 1), Ink.BONE)
		Ink.seal(self, Vector2(w * 0.5, h * 0.34 + 30), 12.0)
		Ink.text(self, Vector2(0, h * 0.34 + 66), "NO NAME   ·   NO STRAIN   ·   NOT YET", 13, Ink.BONE, w, HORIZONTAL_ALIGNMENT_CENTER, Ink.caps_font())
		Ink.text(self, Vector2(28, h - 26), "Calder Town, the Citadel, the Wastes, the Silver Reach, the Stacks, the Undermark.", 12, Ink.DIM)
	elif mode == "settings":
		draw_rect(Rect2(0, 0, w, h), Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.94))
		draw_rect(Rect2(w * 0.36, h * 0.08, 1, h * 0.84), Ink.RULE)
		Ink.screen_title(self, Vector2(w * 0.2 - 140.0, h * 0.5 - 250.0), "Settings", Ink.PAPER, 22)
		var tx := w * 0.42
		Ink.heading(self, Vector2(tx, h * 0.16), "How it works", 520.0)
		var lines: Array = [
			"Press a setting to step it to its next value. It is saved at once.",
			"Shift lock at start sets how the camera begins; CTRL still toggles it in play.",
			"Motion blur stays subtle on Low, by design.",
		]
		for i in range(lines.size()):
			Ink.text(self, Vector2(tx, h * 0.16 + 34.0 + 24.0 * float(i)), String(lines[i]), 14, Ink.BONE)
	elif mode == "controls":
		draw_rect(Rect2(0, 0, w, h), Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.96))
		Ink.screen_title(self, Vector2(w * 0.08, h * 0.1), "Controls", Ink.PAPER, 22)
		_draw_controls(Vector2(w * 0.08, h * 0.18), w)
	elif mode == "pause" and soul != null:
		draw_rect(Rect2(0, 0, w, h), Color(Ink.INK.r, Ink.INK.g, Ink.INK.b, 0.94))
		draw_rect(Rect2(w * 0.36, h * 0.08, 1, h * 0.84), Ink.RULE)
		Ink.screen_title(self, Vector2(w * 0.2 - 140.0, h * 0.5 - 170.0), "Paused", Ink.PAPER, 22)
		_draw_sheet(Vector2(w * 0.42, h * 0.12))


func _draw_sheet(o: Vector2) -> void:
	var y := o.y
	var col := Strains.color_of(soul.primary, soul.secondary)
	_line(Vector2(o.x, y + 30), soul.form_name().to_upper(), 40, Ink.PAPER, Ink.caps_font())
	draw_rect(Rect2(o.x, y + 42, 60, 2), col)
	_line(Vector2(o.x, y + 70), "Level %d   ·   %d skill points unspent   ·   %s played" % [soul.level, soul.marks, _clock(soul.playtime)], 14, Ink.BONE, Ink.figures_font())
	y += 112.0
	Ink.heading(self, Vector2(o.x, y), "What you lean toward", 560.0)
	y += 14.0
	var total := 1.0
	for s in Strains.ALL:
		total = maxf(total, float(soul.affinity[s]))
	for s in Strains.ALL:
		y += 26.0
		var c: Color = Strains.INFO[s]["color"]
		var tag := ""
		if s == soul.primary:
			tag = "  awakened"
		elif s == soul.secondary:
			tag = "  grafted"
		_line(Vector2(o.x, y), String(Strains.INFO[s]["title"]) + tag, 15, c)
		Ink.bar(self, Rect2(o.x + 160, y - 10, 300, 8), float(soul.affinity[s]) / total, c, -1.0, false, 0.0)
	y += 30.0
	if soul.written() and soul.secondary == "":
		var second := Strains.leading(soul.affinity, soul.primary)
		var have := float(soul.affinity[second])
		_line(Vector2(o.x, y), "A second strain can be grafted at a cairn once it reaches %d (%s is at %d)." % [int(Strains.GRAFT_THRESHOLD), String(Strains.INFO[second]["title"]), int(have)], 13, DIM)
	elif not soul.written():
		_line(Vector2(o.x, y), "Nothing is fixed yet. The strongest becomes yours at your Awakening, when your blade is named.", 13, DIM)
	y += 44.0
	Ink.heading(self, Vector2(o.x, y), "How you fight", 560.0)
	y += 12.0
	var traits := soul.profile.traits()
	var i := 0
	for t in Profile.TRAITS:
		var cx := o.x + float(i % 2) * 300.0
		var cy := y + 24.0 * float(i / 2 + 1)
		_line(Vector2(cx, cy), t.capitalize(), 14, DIM)
		Ink.bar(self, Rect2(cx + 100, cy - 9, 160, 6), float(traits[t]), Ink.BONE, -1.0, false, 0.0)
		i += 1
	y += 24.0 * 5.0 + 44.0
	# the record: what this soul has done
	var rec_y := y
	var beaten := 0
	for k: Variant in Quests.BOSS_NAMES.keys():
		if bool(soul.flags.get("beat_" + String(k), false)):
			beaten += 1
	var quests_done := 0
	for id: Variant in Quests.state(soul).keys():
		quests_done += int((Quests.state(soul)[id] as Dictionary).get("t", 0))
	var rec: Array = [["Kills", int(soul.profile.count("kills"))], ["Great enemies", beaten], ["Events won", int(soul.flags.get("events", 0))], ["Notices done", quests_done], ["Deaths", int(soul.flags.get("deaths", 0))], ["Badges", Badges.count(soul)], ["Chests opened", int(soul.flags.get("chests", 0))], ["Spirit orbs", int(soul.flags.get("orbs", 0))]]
	var rx := o.x + 620.0
	Ink.heading(self, Vector2(rx, rec_y - 268.0), "Record", 220.0)
	for ri in range(rec.size()):
		var ry := rec_y - 240.0 + 24.0 * float(ri)
		Ink.text(self, Vector2(rx, ry), String(rec[ri][0]), 13, Ink.DIM)
		Ink.text(self, Vector2(rx, ry), "%d" % int(rec[ri][1]), 13, Ink.PAPER, 220.0, HORIZONTAL_ALIGNMENT_RIGHT, Ink.figures_font())
	Ink.heading(self, Vector2(o.x, y), "Your blade", 560.0)
	y += 28.0
	if soul.release.is_empty():
		_line(Vector2(o.x, y), "It has no name. Fight, then sit at a cairn and breathe.", 15, DIM)
	else:
		var rc := AbilityForge.color_of(soul.release)
		_line(Vector2(o.x, y + 6), "%s, %s" % [String(soul.release["spirit"]), String(soul.release["title"])], 26, rc, title_font)
		y += 34.0
		_line(Vector2(o.x, y), "Aspect %s     Form %s     %s" % [String(soul.release["aspect"]), String(soul.release["form"]), "Full Release" if int(soul.release["stage"]) >= 2 else "First Release"], 14, PALE)
		y += 22.0
		_line(Vector2(o.x, y), String(soul.release["verb_line"]), 14, DIM)
		y += 22.0
		var b: Dictionary = soul.release["budget"]
		_line(Vector2(o.x, y), "Power %d   Reach %d   Speed %d   Craft %d   (every blade spends 100)" % [int(b["power"]), int(b["reach"]), int(b["speed"]), int(b["utility"])], 13, DIM)
		if String(soul.release.get("scar", "")) != "":
			y += 22.0
			_line(Vector2(o.x, y), "Scar: %s" % String(soul.release.get("scar_line", "")), 14, GOLD)


const CONTROL_GROUPS: Array = [
	["Moving", [["Z", "spirit sense (hold): feel enemies near"], ["W A S D", "move"], ["SHIFT", "run (hold)"], ["SPACE", "jump, twice in the air"], ["Q", "dash; while hit, evasive"], ["CTRL", "shift lock on or off"], ["TAB", "lock on to an enemy"]]],
	["Fighting", [["LMB", "cut, five in a string"], ["SPACE", "held on the fifth: launch"], ["RMB", "heavy cut; on a broken stance, execute"], ["F", "guard; tap as a blow lands to parry"], ["F", "during a heavy's wind-up: feint"], ["T", "critical (red, unguardable)"], ["X", "your race's power"], ["1 - 4", "techniques"], ["R", "release your blade"]]],
	["Bodies", [["B", "grip a knocked enemy"], ["V", "carry a body; LMB throws it"], ["E", "devour the fallen"], ["G", "send the fallen on"]]],
	["Everything else", [["E", "talk, read, use, rest at a cairn"], ["I", "gear, charms, materials"], ["K", "skill tree"], ["C", "soul sheet"], ["ESC", "pause"]]],
]


func _draw_controls(o: Vector2, w: float) -> void:
	var col_w := (w * 0.84) / 2.0
	var y0 := o.y
	for gi in range(CONTROL_GROUPS.size()):
		var grp: Array = CONTROL_GROUPS[gi]
		var x := o.x + float(gi % 2) * col_w
		var y := y0 + (0.0 if gi < 2 else 300.0)
		Ink.heading(self, Vector2(x, y), String(grp[0]), col_w - 40.0)
		y += 30.0
		for row: Variant in grp[1]:
			var r: Array = row
			var kx := x
			for key: String in String(r[0]).split(" ", false):
				if key == "-":
					Ink.text(self, Vector2(kx, y + 15.0), "to", 12, Ink.DIM)
					kx += 18.0
					continue
				kx += Ink.keycap(self, Vector2(kx, y), key, true, 20.0) + 4.0
			Ink.text(self, Vector2(x + 130.0, y + 15.0), String(r[1]), 14, Ink.PAPER)
			y += 28.0


func _clock(seconds: float) -> String:
	var m := int(seconds) / 60
	return "%dh %02dm" % [m / 60, m % 60]

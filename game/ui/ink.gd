class_name Ink
extends RefCounted
## The look of every screen: the Ledger's ink and paper. Warm black panels
## with a hairline rule and short corner ticks, bone text, brass for what
## you can act on, seal red for danger. Spaced small capitals for headings,
## keycaps for keys, figures that line up. No gradients, no glow, no
## rounded pills: flat ink, hard edges, careful spacing.

const INK := Color(0.055, 0.05, 0.047)
const INK_SOFT := Color(0.055, 0.05, 0.047, 0.82)
const PAPER := Color(0.91, 0.885, 0.84)
const BONE := Color(0.84, 0.81, 0.75)
const DIM := Color(0.55, 0.53, 0.5)
const FAINT := Color(0.84, 0.81, 0.75, 0.16)
const RULE := Color(0.84, 0.81, 0.75, 0.32)
const BRASS := Color(0.85, 0.69, 0.4)
const SEAL := Color(0.78, 0.22, 0.16)
const LIFE := Color(0.88, 0.86, 0.8)
const JADE := Color(0.45, 0.78, 0.66)

static var _title: Font
static var _caps: FontVariation
static var _body: Font
static var _figures: FontVariation


static func title_font() -> Font:
	if _title == null:
		_title = load("res://assets/fonts/Cinzel.ttf") if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf") else ThemeDB.fallback_font
	return _title


## Cinzel with air between the letters, for headings and labels.
static func caps_font() -> Font:
	if _caps == null:
		_caps = FontVariation.new()
		_caps.base_font = title_font()
		_caps.spacing_glyph = 2
	return _caps


static func body_font() -> Font:
	if _body == null:
		_body = load("res://assets/fonts/Inter.ttf") if ResourceLoader.exists("res://assets/fonts/Inter.ttf") else ThemeDB.fallback_font
	return _body


## Inter with lining, tabular figures, so numbers in a column line up.
static func figures_font() -> Font:
	if _figures == null:
		_figures = FontVariation.new()
		_figures.base_font = body_font()
		_figures.opentype_features = {"tnum": 1, "lnum": 1}
	return _figures


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT, font: Font = null) -> void:
	ci.draw_string(font if font != null else body_font(), pos, s, align, width, size, col)


## Text over a busy world: a soft dark shadow one pixel down, not an outline.
static func lifted(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT, font: Font = null) -> void:
	var f := font if font != null else body_font()
	ci.draw_string_outline(f, pos + Vector2(0, 1), s, align, width, size, 4, Color(0, 0, 0, col.a * 0.5))
	ci.draw_string(f, pos + Vector2(0, 1.5), s, align, width, size, Color(0, 0, 0, col.a * 0.6))
	ci.draw_string(f, pos, s, align, width, size, col)


static func width_of(s: String, size: int, font: Font = null) -> float:
	return (font if font != null else body_font()).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## A panel: flat ink, one hairline rule inside the edge, ticks at the corners.
static func panel(ci: CanvasItem, r: Rect2, fill: Color = INK, accent: Color = BONE) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 6), r.size), Color(0, 0, 0, 0.28 * fill.a))
	ci.draw_rect(r, fill)
	ci.draw_rect(r.grow(-5.0), RULE, false, 1.0)
	ticks(ci, r, accent, 12.0)


static func ticks(ci: CanvasItem, r: Rect2, col: Color, len: float = 10.0, w: float = 2.0) -> void:
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if c.x == r.position.x else -1.0
		var sy := 1.0 if c.y == r.position.y else -1.0
		ci.draw_rect(Rect2(Vector2(minf(c.x, c.x + sx * len), c.y - (w if sy < 0.0 else 0.0)), Vector2(len, w)), col)
		ci.draw_rect(Rect2(Vector2(c.x - (w if sx < 0.0 else 0.0), minf(c.y, c.y + sy * len)), Vector2(w, len)), col)


## A section heading: spaced capitals, then a hairline running to `width`.
static func heading(ci: CanvasItem, pos: Vector2, s: String, width: float, col: Color = BONE, size: int = 13) -> void:
	var f := caps_font()
	ci.draw_string(f, pos, s.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	var tw := f.get_string_size(s.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if width > tw + 16.0:
		ci.draw_rect(Rect2(pos.x + tw + 12.0, pos.y - size * 0.35, width - tw - 12.0, 1.0), RULE)


## A big title with a short rule beneath, the screen's name.
static func screen_title(ci: CanvasItem, pos: Vector2, s: String, col: Color = PAPER, size: int = 28) -> void:
	ci.draw_string(caps_font(), pos, s.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	ci.draw_rect(Rect2(pos.x, pos.y + 12.0, 48.0, 2.0), BRASS)


## A key, drawn as a small cap with an edge and a lip. Returns its width.
static func keycap(ci: CanvasItem, pos: Vector2, key: String, live: bool = true, h: float = 20.0) -> float:
	var f := figures_font()
	var size := 11 if key.length() <= 3 else 10
	var tw := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var w := maxf(h, tw + 10.0)
	var r := Rect2(pos, Vector2(w, h))
	var edge := BONE if live else DIM
	ci.draw_rect(Rect2(r.position + Vector2(0, 2), r.size), Color(0, 0, 0, 0.5))
	ci.draw_rect(r, Color(0.11, 0.1, 0.095))
	ci.draw_rect(r, Color(edge.r, edge.g, edge.b, 0.7 if live else 0.35), false, 1.0)
	ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 3, r.size.x - 2, 2), Color(edge.r, edge.g, edge.b, 0.18))
	ci.draw_string(f, Vector2(r.position.x, r.position.y + h * 0.5 + size * 0.36), key, HORIZONTAL_ALIGNMENT_CENTER, w, size, edge if live else DIM)
	return w


## A hint line: keycaps and words, e.g. [["1-9", "forge"], ["E", "close"]].
static func hints(ci: CanvasItem, pos: Vector2, pairs: Array, col: Color = DIM) -> void:
	var x := pos.x
	for p: Variant in pairs:
		var pr: Array = p
		x += keycap(ci, Vector2(x, pos.y - 14.0), String(pr[0]), true, 18.0) + 6.0
		text(ci, Vector2(x, pos.y), String(pr[1]), 12, col)
		x += width_of(String(pr[1]), 12) + 18.0


## A bar: dark trough, hairline edge, fill, a trailing chip, and ticks.
static func bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, trail: float = -1.0, from_right: bool = false, ticks_every: float = 0.1) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 2), r.size), Color(0, 0, 0, 0.45))
	ci.draw_rect(r, Color(0.04, 0.035, 0.035, 0.88))
	var inner := r.grow(-2.0)
	if trail > frac:
		var tw := inner.size.x * clampf(trail, 0.0, 1.0)
		ci.draw_rect(Rect2(Vector2(inner.end.x - tw if from_right else inner.position.x, inner.position.y), Vector2(tw, inner.size.y)), Color(SEAL.r, SEAL.g, SEAL.b, 0.85))
	var w := inner.size.x * clampf(frac, 0.0, 1.0)
	var fr := Rect2(Vector2(inner.end.x - w if from_right else inner.position.x, inner.position.y), Vector2(w, inner.size.y))
	ci.draw_rect(fr, col)
	ci.draw_rect(Rect2(fr.position, Vector2(fr.size.x, maxf(1.0, inner.size.y * 0.3))), Color(1, 1, 1, 0.12))
	if ticks_every > 0.0:
		var n := int(round(1.0 / ticks_every))
		for i in range(1, n):
			var x := inner.position.x + inner.size.x * float(i) / float(n)
			ci.draw_rect(Rect2(x, inner.position.y, 1.0, inner.size.y), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, RULE, false, 1.0)


## A row in a list: keycap, name, a figure on the right, a note beneath, and
## a hairline under it. Live rows are bright; others recede.
static func row(ci: CanvasItem, r: Rect2, key: String, left: String, right: String, live: bool, note: String = "", accent: Color = BRASS, marked: bool = false) -> void:
	if marked:
		ci.draw_rect(r, Color(accent.r, accent.g, accent.b, 0.08))
		ci.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), accent)
	var x := r.position.x + 10.0
	var top := r.position.y + (14.0 if note != "" else r.size.y * 0.5 - 6.0)
	if key != "":
		x += keycap(ci, Vector2(x, top - 2.0), key, live, 20.0) + 10.0
	text(ci, Vector2(x, top + 13.0), left, 14, PAPER if live else DIM)
	if right != "":
		text(ci, Vector2(r.position.x, top + 13.0), right, 12, BRASS if live else Color(DIM.r, DIM.g, DIM.b, 0.8), r.size.x - 10.0, HORIZONTAL_ALIGNMENT_RIGHT, figures_font())
	if note != "":
		text(ci, Vector2(x, top + 31.0), note, 11, Color(BONE.r, BONE.g, BONE.b, 0.62 if live else 0.4), r.position.x + r.size.x - x - 10.0)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1.0), FAINT)


## Tier as small filled squares out of five.
static func pips(ci: CanvasItem, pos: Vector2, n: int, of: int = 5, col: Color = BRASS) -> void:
	for i in range(of):
		var r := Rect2(pos + Vector2(8.0 * float(i), 0), Vector2(6, 6))
		if i < n:
			ci.draw_rect(r, col)
		else:
			ci.draw_rect(r, Color(col.r, col.g, col.b, 0.35), false, 1.0)


## A small square swatch of a material's colour, used beside its name.
static func swatch(ci: CanvasItem, pos: Vector2, col: Color, s: float = 10.0) -> void:
	ci.draw_rect(Rect2(pos, Vector2(s, s)), col)
	ci.draw_rect(Rect2(pos, Vector2(s, s)), Color(0, 0, 0, 0.5), false, 1.0)
	ci.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(s - 2.0, 2)), Color(1, 1, 1, 0.25))


static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color, filled: bool = true, w: float = 1.5) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	if filled:
		ci.draw_colored_polygon(pts, col)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, col, w)


## A seal: a red square with a white border, the Ledger's stamp.
static func seal(ci: CanvasItem, c: Vector2, s: float = 14.0) -> void:
	var r := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
	ci.draw_rect(r, SEAL)
	ci.draw_rect(r.grow(-2.0), Color(1, 0.92, 0.85, 0.7), false, 1.0)


## Material colours for swatches.
const MATERIAL_COLORS: Dictionary = {
	"ash_bone": Color(0.86, 0.84, 0.78), "mask_shard": Color(0.95, 0.95, 0.92), "lantern_glass": Color(0.55, 0.85, 1.0),
	"oath_steel": Color(0.62, 0.68, 0.8), "tall_eye": Color(0.3, 0.9, 0.85), "bell_bronze": Color(0.85, 0.6, 0.3),
	"dune_glass": Color(0.9, 0.88, 0.7), "brand_iron": Color(0.95, 0.42, 0.12), "gaoler_link": Color(0.45, 0.4, 0.36),
	"unwritten_ink": Color(0.2, 0.2, 0.3),
}


# ------------------------------------------------------------ rich lines

const KEY_WORDS: Array = ["LMB", "RMB", "MMB", "SHIFT", "TAB", "SPACE", "ESC", "CTRL", "ALT", "F", "E", "R", "K", "I", "Q", "P", "C", "W", "U", "L", "B", "V", "G", "T", "Z", "X"]


static func _is_key(word: String) -> String:
	var w := word.strip_edges().trim_suffix(",").trim_suffix(".").trim_suffix(":")
	if w.begins_with("[") and w.ends_with("]") and w.length() <= 7:
		return w.substr(1, w.length() - 2)
	if w.begins_with("(") and w.ends_with(")"):
		return ""
	if KEY_WORDS.has(w) and w == w.to_upper():
		return w
	return ""


## A line of words where key names (LMB, SHIFT, F, [K]) become keycaps.
## Wraps at `width`; returns the height used.
static func rich(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float) -> float:
	var f := body_font()
	var line_h := float(size) + 9.0
	var x := pos.x
	var y := pos.y
	var space := width_of(" ", size)
	for word: String in s.split(" ", false):
		var key := _is_key(word)
		var ww := 0.0
		if key != "":
			ww = maxf(16.0, width_of(key, 10, figures_font()) + 8.0)
		else:
			ww = f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if x + ww > pos.x + width and x > pos.x:
			x = pos.x
			y += line_h
		if key != "":
			keycap(ci, Vector2(x, y - 8.0 - float(size) * 0.45), key, true, 16.0)
		else:
			ci.draw_string(f, Vector2(x, y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += ww + space + (5.0 if key != "" else 0.0)
	return y - pos.y + line_h


# ---------------------------------------------------------------- glyphs

## A small engraved mark for a technique, drawn in single strokes so it
## sits with the rest of the ink: no fills but the odd dot, no glow.
static func glyph(ci: CanvasItem, kind: String, c: Vector2, r: float, col: Color, w: float = 2.0) -> void:
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * r
	match kind:
		"sever":
			ci.draw_line(p.call(-0.8, 0.8), p.call(0.8, -0.8), col, w)
			ci.draw_line(p.call(-0.2, -0.75), p.call(0.15, -0.4), col, w * 0.7)
			ci.draw_line(p.call(0.4, 0.15), p.call(0.75, 0.5), col, w * 0.7)
		"rise":
			for k in range(3):
				var yy := 0.55 - 0.45 * float(k)
				ci.draw_polyline(PackedVector2Array([p.call(-0.65, yy + 0.3), p.call(0.0, yy - 0.3), p.call(0.65, yy + 0.3)]), Color(col.r, col.g, col.b, col.a * (0.45 + 0.27 * float(k))), w)
		"lance":
			ci.draw_line(p.call(-0.85, 0.0), p.call(0.6, 0.0), col, w)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.9, 0.0), p.call(0.45, -0.3), p.call(0.45, 0.3)]), col)
			ci.draw_line(p.call(-0.85, -0.25), p.call(-0.85, 0.25), col, w * 0.7)
		"toll":
			ci.draw_polyline(PackedVector2Array([p.call(-0.6, 0.45), p.call(-0.45, -0.35), p.call(0.0, -0.7), p.call(0.45, -0.35), p.call(0.6, 0.45), p.call(-0.6, 0.45)]), col, w)
			ci.draw_circle(p.call(0.0, 0.7), r * 0.13, col)
			ci.draw_arc(c, r * 0.95, PI * 0.15, PI * 0.35, 6, Color(col.r, col.g, col.b, col.a * 0.5), w * 0.7)
			ci.draw_arc(c, r * 0.95, PI * 0.65, PI * 0.85, 6, Color(col.r, col.g, col.b, col.a * 0.5), w * 0.7)
		"guard":
			ci.draw_polyline(PackedVector2Array([p.call(-0.65, -0.65), p.call(0.65, -0.65), p.call(0.65, 0.05), p.call(0.0, 0.8), p.call(-0.65, 0.05), p.call(-0.65, -0.65)]), col, w)
			ci.draw_line(p.call(0.0, -0.4), p.call(0.0, 0.4), col, w * 0.7)
		"gnash":
			ci.draw_polyline(PackedVector2Array([p.call(-0.8, -0.35), p.call(-0.4, 0.05), p.call(0.0, -0.35), p.call(0.4, 0.05), p.call(0.8, -0.35)]), col, w)
			ci.draw_polyline(PackedVector2Array([p.call(-0.8, 0.45), p.call(-0.4, 0.05), p.call(0.0, 0.45), p.call(0.4, 0.05), p.call(0.8, 0.45)]), col, w)
		"grave":
			ci.draw_line(p.call(0.0, -0.85), p.call(0.0, 0.85), col, w)
			ci.draw_line(p.call(-0.45, -0.35), p.call(0.45, -0.35), col, w)
			ci.draw_line(p.call(-0.7, 0.85), p.call(0.7, 0.85), col, w * 0.7)
		"star":
			ci.draw_line(p.call(0.0, -0.9), p.call(0.0, 0.9), col, w)
			ci.draw_line(p.call(-0.9, 0.0), p.call(0.9, 0.0), col, w)
			ci.draw_line(p.call(-0.4, -0.4), p.call(0.4, 0.4), col, w * 0.6)
			ci.draw_line(p.call(-0.4, 0.4), p.call(0.4, -0.4), col, w * 0.6)
		"exhibit":
			ci.draw_rect(Rect2(p.call(-0.7, -0.7), Vector2(1.4, 1.4) * r), col, false, w)
			ci.draw_rect(Rect2(p.call(-0.3, -0.3), Vector2(0.6, 0.6) * r), col, false, w * 0.7)
		"blacksun":
			ci.draw_circle(c, r * 0.42, col)
			ci.draw_arc(c, r * 0.75, 0, TAU, 24, col, w * 0.7)
			for k in range(8):
				var a := TAU * float(k) / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.82, c + Vector2(cos(a), sin(a)) * r * 0.98, col, w * 0.6)
		"worship":
			for k in range(3):
				var xx := -0.5 + 0.5 * float(k)
				ci.draw_line(p.call(xx, 0.8), p.call(xx, -0.1 - 0.2 * (1.0 - absf(xx) * 2.0)), col, w)
			ci.draw_arc(p.call(0.0, -0.2), r * 0.75, PI * 1.15, PI * 1.85, 12, col, w * 0.7)
		"orbit":
			ci.draw_arc(c, r * 0.75, 0, TAU, 28, col, w * 0.8)
			ci.draw_circle(c, r * 0.18, col)
			ci.draw_circle(c + Vector2(r * 0.53, -r * 0.53), r * 0.14, col)
		_:
			diamond(ci, c, r * 0.6, col, false, w)


## A pie of a cooldown, from twelve o'clock clockwise, as a dark sweep.
static func sweep(ci: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	if frac <= 0.0:
		return
	var c := r.get_center()
	var rad := r.size.length() * 0.6
	var pts := PackedVector2Array([c])
	var steps := maxi(2, int(40.0 * frac))
	for i in range(steps + 1):
		var a := -PI * 0.5 + TAU * (1.0 - frac) + TAU * frac * float(i) / float(steps)
		var v := c + Vector2(cos(a), sin(a)) * rad
		v.x = clampf(v.x, r.position.x, r.end.x)
		v.y = clampf(v.y, r.position.y, r.end.y)
		pts.append(v)
	ci.draw_colored_polygon(pts, col)


## A dashed outline, for a slot with nothing in it.
static func dashed(ci: CanvasItem, r: Rect2, col: Color, dash: float = 4.0) -> void:
	for edge: Array in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		var length := a.distance_to(b)
		var n := int(length / (dash * 2.0))
		for i in range(n):
			var t0 := float(i) * dash * 2.0 / length
			var t1 := minf(1.0, t0 + dash / length)
			ci.draw_line(a.lerp(b, t0), a.lerp(b, t1), col, 1.0)

class_name BoardUI
extends Control
## Two panels drawn over the game: a quest board, and a choice between a few
## options (the fusion offer). Keys: 1 to 6 take a notice or pick an option,
## C hands in finished notices, P seeks promotion, E or ESC closes. Rows can
## also be clicked.

signal closed

const INK := Color(0.045, 0.045, 0.06)
const PALE := Color(0.9, 0.9, 0.93)
const DIM := Color(0.55, 0.56, 0.6)
const GOLD := Color(1.0, 0.82, 0.4)

var region: Region
var board_id: String = ""
var mode: String = ""
var choice_title: String = ""
var choice_text: String = ""
var choice_options: Array = []
var choice_done: Callable = Callable()
var title_font: Font
var body_font: Font
var _rows: Array = []
var _offered: Array = []
## The forge: which shelf of patterns is open, and the chosen temper.
var forge_tab: int = 0
var temper: Array = []
const FORGE_TABS: Array = [["weapon", "WEAPONS"], ["armour", "ARMOUR"], ["rune", "RUNES"], ["charm", "CHARMS"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_font = load("res://assets/fonts/Cinzel.ttf") if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf") else ThemeDB.fallback_font
	body_font = load("res://assets/fonts/Inter.ttf") if ResourceLoader.exists("res://assets/fonts/Inter.ttf") else ThemeDB.fallback_font
	visible = false


func open_board(r: Region, id: String) -> void:
	region = r
	board_id = id
	mode = "board"
	_open()
	Sfx.play("ui_open", -4.0)


func open_market(r: Region) -> void:
	region = r
	board_id = "exchange"
	mode = "market"
	_open()
	Sfx.play("ui_open", -4.0)


func open_forge(r: Region) -> void:
	region = r
	board_id = "forge"
	mode = "forge"
	temper.clear()
	_open()
	Sfx.play("ui_open", -4.0)


func open_inventory(r: Region) -> void:
	region = r
	mode = "inventory"
	_open()
	Sfx.play("ui_open", -4.0)


func open_choice(r: Region, title: String, text: String, options: Array, done: Callable) -> void:
	region = r
	mode = "choice"
	choice_title = title
	choice_text = text
	choice_options = options
	choice_done = done
	_open()
	Sfx.play("write", -6.0)


func _open() -> void:
	visible = true
	if region != null:
		region.paused_input = true
	if region != null and region.main != null:
		region.main.capture_mouse(false)
	queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	mode = ""
	if region != null and is_instance_valid(region):
		region.paused_input = false
		if region.main != null:
			region.main.capture_mouse(true)
	closed.emit()


func soul() -> Soul:
	return region.soul


# ----------------------------------------------------------------- actions

func take(index: int) -> bool:
	_offered = Quests.available(soul(), board_id)
	if index < 0 or index >= _offered.size():
		return false
	var ok := Quests.accept(soul(), String(_offered[index]))
	if ok:
		Sfx.play("levelup", -8.0, 1.3)
		region.say("Notice taken: %s" % String(Quests.def(String(_offered[index]))["title"]), "toast")
	else:
		Sfx.play("ui_tick", -4.0, 0.6)
		if Quests.active(soul()).size() >= Quests.MAX_ACTIVE:
			region.say("You can carry three notices at once.", "hint")
	queue_redraw()
	return ok


## Hands in every finished notice. Returns how many.
func claim_all() -> int:
	var n := 0
	for id: String in Quests.active(soul()):
		if not Quests.is_ready(soul(), id) or Quests.is_npc(String(Quests.def(id)["board"])):
			continue
		var reward := Quests.claim(soul(), id)
		if reward.is_empty():
			continue
		n += 1
		region.main.grant_essence(float(reward["essence"]))
		var line := "Handed in: %s.  +%d essence" % [String(Quests.def(id)["title"]), int(reward["essence"])]
		if float(reward["standing"]) > 0.0:
			line += "  +%d standing" % int(reward["standing"])
		region.say(line, "gain")
	if n > 0:
		Sfx.play("relic", -4.0)
		region.main.save()
	if board_id == "lingering" and Quests.prologue_done(soul()) and not bool(soul().flags.get("prologue_said", false)):
		soul().flags["prologue_said"] = true
		region.say("The board is done. Go to the shop on the main road: Ivo Marsh will train you.", "whisper")
	queue_redraw()
	return n


func promote() -> bool:
	var ok := region.promote()
	if not ok:
		region.say(Quests.promotion_gap(soul()), "hint")
		Sfx.play("ui_tick", -4.0, 0.6)
	queue_redraw()
	return ok


# ---- the inventory and the bench

func toggle_charm(i: int) -> bool:
	var ok := Items.toggle_equip(soul(), i)
	if ok:
		Sfx.play("ui_tick", -4.0, 1.2)
		if region.player != null:
			region.player.refresh_stats()
	else:
		region.say("Three charms at most. Take one off first.", "hint")
	queue_redraw()
	return ok


func craft(i: int) -> bool:
	var c := Items.craft(soul(), i)
	if c.is_empty():
		Sfx.play("ui_tick", -4.0, 0.6)
		region.say("Not enough for that.", "hint")
		return false
	Sfx.play("levelup", -6.0, 1.4)
	region.say("Crafted: %s %s. %s" % [String(c["rarity"]), String(c["name"]), Items.describe(c)], "gain")
	region.main.save()
	queue_redraw()
	return true


# ---- the forge

func forge_patterns() -> Array:
	return Forge.patterns_of(String(FORGE_TABS[forge_tab][0]))


func set_forge_tab(i: int) -> void:
	forge_tab = posmod(i, FORGE_TABS.size())
	if forge_tab == 2 or forge_tab == 3:
		temper.clear()
	Sfx.play("ui_tick", -6.0, 1.1)
	queue_redraw()


## Toggles a material as temper (weapons and armour only, two at most).
func toggle_temper(i: int) -> bool:
	var keys := temper_keys()
	if i < 0 or i >= keys.size() or forge_tab >= 2:
		return false
	var k := String(keys[i])
	if temper.has(k):
		temper.erase(k)
	elif temper.size() < Forge.MAX_TEMPER:
		temper.append(k)
	else:
		region.say("Two tempers at most.", "hint")
		return false
	Sfx.play("ui_tick", -4.0, 1.3)
	queue_redraw()
	return true


func temper_keys() -> Array:
	var keys: Array = Items.MATERIALS.keys()
	keys.sort()
	return keys


## Forges pattern i of the open shelf (or crafts charm recipe i).
func forge_pick(i: int) -> bool:
	if forge_tab == 3:
		return craft(i)
	var pats := forge_patterns()
	if i < 0 or i >= pats.size():
		return false
	var it := Forge.forge(soul(), String(pats[i]), temper)
	if it.is_empty():
		Sfx.play("ui_tick", -4.0, 0.6)
		region.say("Not enough for that.", "hint")
		return false
	Sfx.play("anvil", -3.0)
	Fx.screen_flash(Forge.color_of(it), 0.25)
	region.say("Forged: %s %s. %s" % [String(it["rarity"]), String(it["name"]), Forge.describe(it)], "gain")
	temper.clear()
	region.main.save()
	queue_redraw()
	return true


# ---- gear

## The inventory's number keys: wear a charm, wear a weapon or armour, or
## set a rune into the first free socket.
func use_item(i: int) -> bool:
	var s := soul()
	if i < 0 or i >= s.items.size():
		return false
	var t := String((s.items[i] as Dictionary).get("type", "charm"))
	if t == "charm":
		return toggle_charm(i)
	var ok := false
	if t == "rune":
		ok = Forge.socket(s, i) != ""
		if not ok:
			region.say("No free socket. Wear a weapon or armour with room for another rune.", "hint")
		else:
			Sfx.play("socket", -4.0)
	else:
		ok = Forge.wear(s, i)
		if ok:
			Sfx.play("guard", -6.0, 1.2)
	if ok:
		_refresh_player(t != "rune")
	queue_redraw()
	return ok


func take_off(slot: String) -> bool:
	var ok := Forge.take_off(soul(), slot)
	if ok:
		_refresh_player(true)
		Sfx.play("ui_tick", -4.0, 0.9)
	queue_redraw()
	return ok


func unsocket_all() -> int:
	var n := 0
	for slot: String in ["weapon", "armour"]:
		while Forge.unsocket(soul(), slot, 0):
			n += 1
	if n > 0:
		_refresh_player(false)
		Sfx.play("socket", -6.0, 0.8)
	queue_redraw()
	return n


func _refresh_player(look: bool) -> void:
	var pl := region.player
	if pl == null:
		return
	pl.refresh_stats()
	if look:
		pl.rebuild_body()
	region.main.save()


# ---- the Exchange

func market_buy(i: int) -> bool:
	var ok := Market.buy(soul(), i)
	if ok:
		Sfx.play("relic", -4.0, 1.3)
		var lg: Array = Market.state(soul())["log"]
		region.say(String(lg[lg.size() - 1]), "gain")
		region.main.save()
	else:
		Sfx.play("ui_tick", -4.0, 0.6)
		region.say("Not enough shards.", "hint")
	queue_redraw()
	return ok


func owned_materials() -> Array:
	var out: Array = []
	var keys: Array = soul().materials.keys()
	keys.sort()
	for k: Variant in keys:
		if int(soul().materials[k]) > 0:
			out.append(String(k))
	return out


func market_sell(i: int) -> int:
	var mats := owned_materials()
	if i < 0 or i >= mats.size():
		return 0
	var got := Market.sell_material(soul(), String(mats[i]))
	if got > 0:
		Sfx.play("ui_tick", -4.0, 1.5)
	queue_redraw()
	return got


func unequipped_charms() -> Array:
	var out: Array = []
	for i in range(soul().items.size()):
		if not soul().equipped.has(i):
			out.append(i)
	return out


## Lists a charm at a tenth over what it is worth now.
func market_list(i: int) -> bool:
	var free := unequipped_charms()
	if i < 0 or i >= free.size():
		return false
	var idx := int(free[i])
	var it: Dictionary = soul().items[idx]
	var ask := int(round(float(Market.price(soul(), "charm", String(it["key"]), it)) * 1.1))
	var ok := Market.list_item(soul(), idx, ask)
	if ok:
		region.say("Listed %s %s for %d shards." % [String(it["rarity"]), String(it["name"]), ask], "toast")
		Sfx.play("ui_tick", -4.0, 1.2)
	queue_redraw()
	return ok


func choose(index: int) -> void:
	if index < 0 or index >= choice_options.size():
		return
	var cb := choice_done
	close()
	if cb.is_valid():
		cb.call(index)


# ------------------------------------------------------------------- input

func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).physical_keycode
		if mode == "inventory":
			if k >= KEY_1 and k <= KEY_9:
				use_item(k - KEY_1)
			elif k == KEY_W:
				take_off("weapon")
			elif k == KEY_R:
				take_off("armour")
			elif k == KEY_U:
				unsocket_all()
			elif k == KEY_I or k == KEY_ESCAPE or k == KEY_E:
				close()
			get_viewport().set_input_as_handled()
			return
		if mode == "forge":
			if k >= KEY_1 and k <= KEY_9:
				forge_pick(k - KEY_1)
			elif k >= KEY_A and k <= KEY_J:
				toggle_temper(k - KEY_A)
			elif k == KEY_TAB or k == KEY_RIGHT:
				set_forge_tab(forge_tab + 1)
			elif k == KEY_LEFT:
				set_forge_tab(forge_tab - 1)
			elif k == KEY_ESCAPE or k == KEY_E:
				close()
			get_viewport().set_input_as_handled()
			return
		if mode == "market":
			if k >= KEY_1 and k <= KEY_8:
				market_buy(k - KEY_1)
			elif k >= KEY_A and k <= KEY_H:
				market_sell(k - KEY_A)
			elif (e as InputEventKey).shift_pressed and k >= KEY_1 and k <= KEY_8:
				market_list(k - KEY_1)
			elif k == KEY_ESCAPE or k == KEY_E:
				close()
			elif k == KEY_L:
				market_list(0)
			get_viewport().set_input_as_handled()
			return
		if k >= KEY_1 and k <= KEY_6:
			if mode == "board":
				take(k - KEY_1)
			else:
				choose(k - KEY_1)
		elif k == KEY_C and mode == "board":
			claim_all()
		elif k == KEY_P and mode == "board":
			promote()
		elif (k == KEY_E or k == KEY_ESCAPE) and mode == "board":
			close()
		get_viewport().set_input_as_handled()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var at := (e as InputEventMouseButton).position
		for row: Variant in _rows:
			var r: Array = row
			if (r[0] as Rect2).has_point(at):
				match String(r[1]):
					"charm": use_item(int(r[2]))
					"craft": craft(int(r[2]))
					"forge": forge_pick(int(r[2]))
					"temper": toggle_temper(int(r[2]))
					"tab": set_forge_tab(int(r[2]))
					"off_weapon": take_off("weapon")
					"off_armour": take_off("armour")
					"unsocket":
						var slot := "weapon" if int(r[2]) < 100 else "armour"
						if Forge.unsocket(soul(), slot, int(r[2]) % 100):
							_refresh_player(false)
						queue_redraw()
					"buy": market_buy(int(r[2]))
					"sell": market_sell(int(r[2]))
					"list": market_list(int(r[2]))
					"cancel":
						Market.cancel(soul(), int(r[2]))
						queue_redraw()
					"take": take(int(r[2]))
					"claim": claim_all()
					"promote": promote()
					"close": close()
					"choose": choose(int(r[2]))
				return


# -------------------------------------------------------------------- draw

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _text(pos: Vector2, text: String, size: int, col: Color, font: Font = null, width: float = -1.0, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font if font != null else body_font, pos, text, align, width, size, col)


## A foot button: a keycap and a word, underlined in brass when it can act.
func _button(rect: Rect2, label: String, action: String, arg: int, live: bool) -> void:
	var key := ""
	var word := label
	var parts := label.split("  ", false, 1)
	if parts.size() == 2 and parts[0].length() <= 3:
		key = parts[0]
		word = parts[1]
	draw_rect(rect, Color(0.09, 0.085, 0.08) if live else Color(0.07, 0.065, 0.06))
	draw_rect(rect, Ink.RULE if live else Ink.FAINT, false, 1.0)
	if live:
		draw_rect(Rect2(rect.position.x, rect.end.y - 2.0, rect.size.x, 2.0), Ink.BRASS)
	var x := rect.position.x + 12.0
	if key != "":
		x += Ink.keycap(self, Vector2(x, rect.position.y + rect.size.y * 0.5 - 10.0), key, live) + 10.0
	Ink.text(self, Vector2(x, rect.position.y + rect.size.y * 0.5 + 5.0), word, 14, Ink.PAPER if live else Ink.DIM)
	_rows.append([rect, action, arg])


func _draw() -> void:
	_rows.clear()
	if region == null or not is_instance_valid(region):
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.018, 0.016, 0.62))
	if mode == "choice":
		_draw_choice()
	elif mode == "board":
		_draw_board()
	elif mode == "inventory":
		_draw_inventory()
	elif mode == "forge":
		_draw_forge()
	elif mode == "market":
		_draw_market()


func _draw_choice() -> void:
	var w := minf(760.0, size.x - 80.0)
	var x := size.x * 0.5 - w * 0.5
	var y := size.y * 0.22
	var h := 230.0 + 52.0 * float(choice_options.size())
	Ink.panel(self, Rect2(x, y, w, h))
	Ink.diamond(self, Vector2(size.x * 0.5, y + 28.0), 4.0, Ink.BRASS)
	_text(Vector2(x, y + 70), choice_title.to_upper(), 28, Ink.PAPER, Ink.caps_font(), w, HORIZONTAL_ALIGNMENT_CENTER)
	draw_multiline_string(body_font, Vector2(x + 44, y + 112), choice_text, HORIZONTAL_ALIGNMENT_CENTER, w - 88.0, 16, 6, Ink.BONE)
	for i in range(choice_options.size()):
		_button(Rect2(x + 44, y + 200 + 52.0 * float(i), w - 88.0, 42), "%d  %s" % [i + 1, String(choice_options[i])], "choose", i, true)


func _draw_board() -> void:
	var s := soul()
	var info: Dictionary = Quests.BOARDS[board_id]
	var w := minf(940.0, size.x - 60.0)
	var x := size.x * 0.5 - w * 0.5
	var y := 56.0
	var h := size.y - 112.0
	Ink.panel(self, Rect2(x, y, w, h))
	Ink.screen_title(self, Vector2(x + 36, y + 54), String(info["title"]))
	var sub := "%s   ·   Grade %d   ·   Standing %d   ·   Level %d of %d" % [Quests.title(s), s.grade, int(s.standing), s.level, Quests.level_cap(s)]
	_text(Vector2(x + 36, y + 92), sub, 13, Ink.BONE, Ink.figures_font())
	var cy := y + 132.0
	if not Quests.board_accepts(s, board_id):
		draw_multiline_string(body_font, Vector2(x + 36, cy), "These notices are not meant for you. A board serves its own strain, or one you have taken in.", HORIZONTAL_ALIGNMENT_LEFT, w - 72.0, 16, 3, Ink.BONE)
		_button(Rect2(x + w - 176, y + h - 66, 140, 40), "E  Close", "close", 0, true)
		return
	Ink.heading(self, Vector2(x + 36, cy), "Carrying  %d / %d" % [Quests.active(s).size(), Quests.MAX_ACTIVE], w - 72.0)
	cy += 8.0
	var any_ready := false
	for id: String in Quests.active(s):
		cy += 26.0
		var ready := Quests.is_ready(s, id)
		any_ready = any_ready or ready
		var box := Rect2(x + 40, cy - 11.0, 11.0, 11.0)
		if ready:
			draw_rect(box, Ink.BRASS)
		else:
			draw_rect(box, Ink.BONE, false, 1.0)
		_text(Vector2(x + 62, cy), Quests.line(s, id), 14, Ink.BRASS if ready else Ink.PAPER)
	if Quests.active(s).is_empty():
		cy += 26.0
		_text(Vector2(x + 40, cy), "Nothing yet. Take a notice below.", 14, Ink.DIM)
	cy += 44.0
	Ink.heading(self, Vector2(x + 36, cy), "Notices", w - 72.0)
	_offered = Quests.available(s, board_id)
	cy += 10.0
	for i in range(mini(6, _offered.size())):
		var q := Quests.def(String(_offered[i]))
		var rect := Rect2(x + 30, cy, w - 60.0, 52.0)
		var live := Quests.active(s).size() < Quests.MAX_ACTIVE
		var reward := "+%d essence" % int(q["essence"])
		if int(q["standing"]) > 0:
			reward += "    +%d standing" % int(q["standing"])
		Ink.row(self, rect, str(i + 1), String(q["title"]), reward, live, String(q["text"]))
		_rows.append([rect, "take", i])
		cy += 54.0
	if _offered.is_empty():
		cy += 26.0
		_text(Vector2(x + 40, cy), "No new notices for your grade.", 14, Ink.DIM)
	# the foot: what promotion still wants, then the buttons
	var fy := y + h - 70.0
	draw_rect(Rect2(x + 30, fy - 40.0, w - 60.0, 1.0), Ink.FAINT)
	if s.written():
		var can := Quests.can_promote(s)
		if can:
			Ink.seal(self, Vector2(x + 44, fy - 19.0), 12.0)
		_text(Vector2(x + (60 if can else 36), fy - 14), Quests.promotion_gap(s), 12, Ink.BRASS if can else Ink.BONE, null, w - 100.0)
		_button(Rect2(x + 266, fy, 250, 40), "P  Seek promotion", "promote", 0, can)
	_button(Rect2(x + 30, fy, 220, 40), "C  Hand in finished", "claim", 0, any_ready)
	_button(Rect2(x + w - 170, fy, 140, 40), "E  Close", "close", 0, true)


func _panel() -> Rect2:
	var w := minf(1120.0, size.x - 60.0)
	return Rect2(size.x * 0.5 - w * 0.5, 46.0, w, size.y - 92.0)


## A list row for the gear, forge and Exchange screens (see Ink.row).
func _row(rect: Rect2, key: String, left: String, right: String, live: bool, action: String, arg: int, sub_text: String = "", marked: bool = false, accent: Color = Ink.BRASS) -> void:
	Ink.row(self, rect, key, left, right, live, sub_text, accent, marked)
	if action != "":
		_rows.append([rect, action, arg])


const RARITY_COLORS: Dictionary = {"Common": Color(0.75, 0.72, 0.66), "Fine": Color(0.5, 0.78, 0.62), "Rare": Color(0.5, 0.68, 0.92), "Mythic": Color(0.9, 0.55, 0.3), "Badge": Color(0.86, 0.7, 0.36)}


func _rarity_col(it: Dictionary) -> Color:
	return RARITY_COLORS.get(String(it.get("rarity", "Common")), Ink.BONE)


func _item_kind(it: Dictionary) -> String:
	var t := String(it.get("type", "charm"))
	match t:
		"weapon", "armour":
			return "%s, tier %d" % [t, int(it.get("tier", 0))]
		"rune":
			return "rune"
	return "charm"


func _draw_inventory() -> void:
	var s := soul()
	var p := _panel()
	Ink.panel(self, p)
	Ink.screen_title(self, p.position + Vector2(36, 54), "Gear, Charms, Materials")
	Ink.hints(self, p.position + Vector2(36, 96), [["1-9", "wear, take off or socket"], ["W", "take off weapon"], ["R", "take off armour"], ["U", "pull every rune"], ["I", "close"]])
	Ink.diamond(self, Vector2(p.end.x - 150.0, p.position.y + 50.0), 4.0, Ink.BRASS)
	_text(Vector2(p.end.x - 140.0, p.position.y + 55.0), "%d shards" % s.shards, 15, Ink.BRASS, Ink.figures_font())
	var col_w := (p.size.x - 96.0) * 0.5
	var x := p.position.x + 36.0
	var y := p.position.y + 140.0
	Ink.heading(self, Vector2(x, y), "Carried   %d / %d charms worn" % [s.equipped.size(), Items.SLOTS], col_w)
	y += 10.0
	if s.items.is_empty():
		_text(Vector2(x, y + 30.0), "Nothing yet. Forge gear at any forge; the Undermark's great enemies drop charms.", 13, Ink.DIM)
	for i in range(mini(9, s.items.size())):
		var it: Dictionary = s.items[i]
		var worn := s.equipped.has(i)
		var t := String(it.get("type", "charm"))
		var live := worn or t != "charm" or s.equipped.size() < Items.SLOTS
		var note := "%s%s   %s" % ["WORN   " if worn else "", _item_kind(it).to_upper(), Forge.describe(it)]
		var r := Rect2(x, y, col_w, 50.0)
		_row(r, str(i + 1), String(it["name"]), "%s   %d" % [String(it["rarity"]), int(Market.price(s, "charm", String(it["key"]), it))], live, "charm", i, note, worn, _rarity_col(it))
		if it.has("color"):
			Ink.swatch(self, Vector2(r.end.x - 12.0, r.position.y + 38.0), Forge.color_of(it), 8.0)
		y += 52.0
	if s.items.size() > 9:
		_text(Vector2(x, y + 22.0), "and %d more. Sell or list some at the Exchange." % (s.items.size() - 9), 12, Ink.DIM)
	# what is worn
	var x2 := x + col_w + 24.0
	var y2 := p.position.y + 140.0
	Ink.heading(self, Vector2(x2, y2), "Worn", col_w)
	y2 += 10.0
	for slot: String in ["weapon", "armour"]:
		var g: Dictionary = s.gear.get(slot, {})
		var r := Rect2(x2, y2, col_w, 50.0)
		if g.is_empty():
			_row(r, "W" if slot == "weapon" else "R", "No %s" % slot, "", false, "", 0, "Forge one at any forge.")
		else:
			_row(r, "W" if slot == "weapon" else "R", String(g["name"]), "click to take off", true, "off_" + slot, 0, Items.describe(g), true, Forge.color_of(g))
			Ink.pips(self, Vector2(r.end.x - 52.0, r.position.y + 36.0), int(g["tier"]))
			var runes: Array = g.get("runes", [])
			for si in range(int(g.get("sockets", 0))):
				y2 += 28.0
				var rr := Rect2(x2 + 34.0, y2 + 24.0, col_w - 34.0, 26.0)
				if si < runes.size():
					var rn: Dictionary = runes[si]
					Ink.diamond(self, Vector2(rr.position.x - 12.0, rr.get_center().y), 5.0, Forge.color_of(rn))
					_row(rr, "", String(rn["name"]), Forge.describe(rn).get_slice(",", 0), true, "unsocket", si + (0 if slot == "weapon" else 100))
				else:
					Ink.diamond(self, Vector2(rr.position.x - 12.0, rr.get_center().y), 5.0, Ink.DIM, false, 1.0)
					_row(rr, "", "empty socket", "", false, "", 0)
		y2 += 56.0
	var gap := Forge.gear_gap(s)
	y2 += 12.0
	if gap != "":
		_text(Vector2(x2, y2), "To leave this grade, " + gap + ".", 12, Ink.SEAL.lerp(Ink.PAPER, 0.35))
	else:
		Ink.seal(self, Vector2(x2 + 6.0, y2 - 4.0), 10.0)
		_text(Vector2(x2 + 20.0, y2), "Your gear meets this grade's bar.", 12, Ink.BRASS)
	y2 += 34.0
	Ink.heading(self, Vector2(x2, y2), "Materials", col_w)
	y2 += 22.0
	var mats := owned_materials()
	if mats.is_empty():
		_text(Vector2(x2, y2 + 4.0), "None yet.", 13, Ink.DIM)
	var mi := 0
	for m: String in mats:
		var mx := x2 + float(mi % 2) * (col_w * 0.5)
		var my := y2 + 22.0 * float(mi / 2)
		Ink.swatch(self, Vector2(mx, my - 10.0), Ink.MATERIAL_COLORS.get(m, Ink.BONE))
		_text(Vector2(mx + 18.0, my), String((Items.MATERIALS[m] as Dictionary)["name"]), 13, Ink.PAPER)
		_text(Vector2(mx, my), "%d" % int(s.materials[m]), 13, Ink.BRASS, Ink.figures_font(), col_w * 0.5 - 16.0, HORIZONTAL_ALIGNMENT_RIGHT)
		mi += 1
	var mods := Items.equipped_mods(s)
	var gm := Forge.gear_mods(s)
	for m: Variant in gm.keys():
		mods[m] = float(mods.get(m, 0.0)) + float(gm[m])
	if not mods.is_empty():
		draw_rect(Rect2(x, p.end.y - 62.0, p.size.x - 72.0, 1.0), Ink.FAINT)
		_text(Vector2(x, p.end.y - 40.0), "ALL WORN", 11, Ink.DIM, Ink.caps_font())
		draw_multiline_string(body_font, Vector2(x + 90.0, p.end.y - 40.0), Items.describe({"mods": mods}), HORIZONTAL_ALIGNMENT_LEFT, p.size.x - 170.0, 13, 2, Ink.BONE)


func _draw_forge() -> void:
	var s := soul()
	var p := _panel()
	var ember := Color(0.95, 0.55, 0.25)
	Ink.panel(self, p, Ink.INK, ember)
	Ink.screen_title(self, p.position + Vector2(36, 54), "The Forge", Ink.PAPER)
	var hand := s.profile.dominant()
	var mark := String((Forge.HAND.get(hand, ["Plain", {}]) as Array)[0])
	_text(Vector2(p.position.x + 36, p.position.y + 90), "Your hand marks your work:  %s" % mark, 13, Ink.BONE)
	Ink.diamond(self, Vector2(p.end.x - 150.0, p.position.y + 50.0), 4.0, Ink.BRASS)
	_text(Vector2(p.end.x - 140.0, p.position.y + 55.0), "%d shards" % s.shards, 15, Ink.BRASS, Ink.figures_font())
	Ink.hints(self, Vector2(p.position.x + 36, p.end.y - 26.0), [["Tab", "next shelf"], ["1-9", "forge"], ["A-J", "temper, two at most, %d each" % Forge.TEMPER_COST], ["E", "close"]])
	# shelves: words with a rule under the open one
	var tx := p.position.x + 36.0
	var ty := p.position.y + 128.0
	for i in range(FORGE_TABS.size()):
		var label := String(FORGE_TABS[i][1])
		var tw := Ink.width_of(label, 13, Ink.caps_font())
		var r := Rect2(tx - 6.0, ty - 18.0, tw + 12.0, 28.0)
		_text(Vector2(tx, ty), label, 13, Ink.PAPER if i == forge_tab else Ink.DIM, Ink.caps_font())
		if i == forge_tab:
			draw_rect(Rect2(tx, ty + 8.0, tw, 2.0), ember)
		_rows.append([r, "tab", i])
		tx += tw + 34.0
	draw_rect(Rect2(p.position.x + 30.0, ty + 12.0, p.size.x - 60.0, 1.0), Ink.FAINT)
	var col_w := (p.size.x - 96.0) * 0.6
	var x := p.position.x + 36.0
	var y := ty + 26.0
	if forge_tab == 3:
		for i in range(Items.RECIPES.size()):
			var rec: Dictionary = Items.RECIPES[i]
			var def: Dictionary = Items.CHARMS[rec["charm"]]
			var mod_words: Array = []
			for mm: Variant in (def["mods"] as Dictionary).keys():
				mod_words.append(String(Items.STAT_WORDS[mm]))
			_row(Rect2(x, y, col_w, 50.0), str(i + 1), String(def["name"]), "%d shards" % int(rec["shards"]), Items.can_craft(s, i), "craft", i, _needs_text(rec["needs"]) + "   ·   changes " + ", ".join(mod_words))
			y += 52.0
	else:
		var pats := forge_patterns()
		for i in range(mini(9, pats.size())):
			var key := String(pats[i])
			var pat: Dictionary = Forge.PATTERNS[key]
			var sub_text := ""
			var mod_words: Array = []
			for mm: Variant in (pat["mods"] as Dictionary).keys():
				var rr: Array = pat["mods"][mm]
				mod_words.append("%s %+d to %+d%%" % [String(Items.STAT_WORDS.get(mm, mm)), int(round(float(rr[0]) * 100.0)), int(round(float(rr[1]) * 100.0))])
			if pat.has("effect"):
				var e: Array = pat["effect"]
				if String(e[0]) != "haste":
					sub_text = "%s %d to %d%%   ·   " % [String(e[0]).capitalize(), int(round(float(e[1]) * 100.0)), int(round(float(e[2]) * 100.0))]
			sub_text += ", ".join(mod_words)
			var live := Forge.can_forge(s, key, temper)
			var r := Rect2(x, y, col_w, 50.0)
			_row(r, str(i + 1), String(pat["name"]), "%d shards" % int(pat["shards"]), live, "forge", i, sub_text, false, Forge.color_of({"color": [(pat["color"] as Color).r, (pat["color"] as Color).g, (pat["color"] as Color).b]}))
			Ink.pips(self, Vector2(r.position.x + 52.0 + Ink.width_of(String(pat["name"]), 14) + 12.0, r.position.y + 17.0), int(pat["tier"]))
			# what it costs, as swatches
			var nx := r.end.x - 10.0 - Ink.width_of("%d shards" % int(pat["shards"]), 12, Ink.figures_font()) - 14.0
			var needs: Dictionary = pat["needs"]
			var nkeys: Array = needs.keys()
			nkeys.reverse()
			for m: Variant in nkeys:
				var have := int(s.materials.get(m, 0))
				var label := "%d" % int(needs[m])
				var lw := Ink.width_of(label, 12, Ink.figures_font())
				nx -= lw
				_text(Vector2(nx, r.position.y + 27.0), label, 12, Ink.PAPER if have >= int(needs[m]) else Ink.SEAL.lerp(Ink.PAPER, 0.3), Ink.figures_font())
				nx -= 14.0
				Ink.swatch(self, Vector2(nx, r.position.y + 17.0), Ink.MATERIAL_COLORS.get(m, Ink.BONE))
				nx -= 12.0
			if pat.has("sockets"):
				for k in range(int(pat["sockets"])):
					Ink.diamond(self, Vector2(r.end.x - 14.0 - 12.0 * float(k), r.position.y + 39.0), 4.0, Ink.BONE, false, 1.0)
			y += 52.0
	# temper
	var x2 := x + col_w + 24.0
	var w2 := p.size.x - 96.0 - col_w
	var y2 := ty + 40.0
	Ink.heading(self, Vector2(x2, y2), "Temper" if forge_tab < 2 else "Temper (weapons, armour)", w2)
	y2 += 10.0
	var keys := temper_keys()
	for i in range(keys.size()):
		var m := String(keys[i])
		var tm: Dictionary = Forge.TEMPER[m]
		var stat := String(tm.keys()[0])
		var on := temper.has(m)
		var have := int(s.materials.get(m, 0))
		var live := on or (have >= Forge.TEMPER_COST and forge_tab < 2)
		var r := Rect2(x2, y2, w2, 30.0)
		_row(r, char(65 + i), String((Items.MATERIALS[m] as Dictionary)["name"]), "+" + String(Items.STAT_WORDS.get(stat, stat)), live, "temper", i, "", on, ember)
		Ink.swatch(self, Vector2(r.position.x + 36.0 + Ink.width_of(String((Items.MATERIALS[m] as Dictionary)["name"]), 14) + 14.0, r.position.y + 10.0), Ink.MATERIAL_COLORS.get(m, Ink.BONE), 9.0)
		_text(Vector2(r.position.x + 36.0 + Ink.width_of(String((Items.MATERIALS[m] as Dictionary)["name"]), 14) + 30.0, r.position.y + 19.0), "%d" % have, 11, Ink.DIM, Ink.figures_font())
		y2 += 31.0
	var gap := Forge.gear_gap(s)
	y2 += 22.0
	if gap != "":
		draw_multiline_string(body_font, Vector2(x2, y2), "This grade asks you to " + gap + ".", HORIZONTAL_ALIGNMENT_LEFT, w2, 12, 3, Ink.SEAL.lerp(Ink.PAPER, 0.35))
	else:
		Ink.seal(self, Vector2(x2 + 6.0, y2 - 4.0), 10.0)
		_text(Vector2(x2 + 20.0, y2), "Your gear meets this grade's bar.", 12, Ink.BRASS)


func _needs_text(needs: Dictionary) -> String:
	var parts: Array = []
	for m: Variant in needs.keys():
		parts.append("%d %s" % [int(needs[m]), String((Items.MATERIALS[m] as Dictionary)["name"])])
	return ", ".join(parts)


func _draw_market() -> void:
	var s := soul()
	var st := Market.state(s)
	var p := _panel()
	Ink.panel(self, p)
	Ink.screen_title(self, p.position + Vector2(36, 54), "The Exchange")
	_text(Vector2(p.position.x + 36, p.position.y + 90), "A tenth of every sale goes to the Exchange.", 13, Ink.BONE)
	Ink.diamond(self, Vector2(p.end.x - 150.0, p.position.y + 50.0), 4.0, Ink.BRASS)
	_text(Vector2(p.end.x - 140.0, p.position.y + 55.0), "%d shards" % s.shards, 15, Ink.BRASS, Ink.figures_font())
	Ink.hints(self, Vector2(p.position.x + 36, p.end.y - 26.0), [["1-8", "buy"], ["A-H", "sell one"], ["L", "list your first loose piece"], ["E", "close"]])
	var col_w := (p.size.x - 96.0) * 0.5
	var x := p.position.x + 36.0
	var y := p.position.y + 136.0
	Ink.heading(self, Vector2(x, y), "Other souls are selling", col_w)
	y += 10.0
	var ls: Array = st["listings"]
	if ls.is_empty():
		_text(Vector2(x, y + 30.0), "Nothing yet. Come back in a little while.", 13, Ink.DIM)
	for i in range(mini(8, ls.size())):
		var l: Dictionary = ls[i]
		var sub_text := String(l["seller"])
		var acc := Ink.BRASS
		if String(l["kind"]) == "charm":
			sub_text += "   ·   " + Forge.describe(l["item"])
			acc = _rarity_col(l["item"])
		_row(Rect2(x, y, col_w, 50.0), str(i + 1), Market.label(l), "%d" % int(l["price"]), s.shards >= int(l["price"]), "buy", i, sub_text, false, acc)
		y += 52.0
	var x2 := x + col_w + 24.0
	var y2 := p.position.y + 136.0
	Ink.heading(self, Vector2(x2, y2), "Sell to the Exchange", col_w)
	y2 += 8.0
	var mats := owned_materials()
	for i in range(mini(8, mats.size())):
		var m := String(mats[i])
		var got := int(floor(float(Market.price(s, "mat", m)) * (1.0 - Market.FEE)))
		var r := Rect2(x2, y2, col_w, 30.0)
		_row(r, char(65 + i), "%s" % String((Items.MATERIALS[m] as Dictionary)["name"]), "x%d    +%d each" % [int(s.materials[m]), got], true, "sell", i)
		Ink.swatch(self, Vector2(r.position.x + 36.0 + Ink.width_of(String((Items.MATERIALS[m] as Dictionary)["name"]), 14) + 14.0, r.position.y + 10.0), Ink.MATERIAL_COLORS.get(m, Ink.BONE), 9.0)
		y2 += 31.0
	y2 += 30.0
	Ink.heading(self, Vector2(x2, y2), "Your listings", col_w)
	y2 += 8.0
	var mine: Array = st["mine"]
	for i in range(mine.size()):
		var l: Dictionary = mine[i]
		_row(Rect2(x2, y2, col_w, 30.0), "", Market.label(l), "asking %d   ·   click to take back" % int(l["price"]), true, "cancel", i)
		y2 += 31.0
	if mine.is_empty():
		_text(Vector2(x2 + 10.0, y2 + 20.0), "None.", 13, Ink.DIM)
		y2 += 30.0
	var free := unequipped_charms()
	if not free.is_empty():
		y2 += 10.0
		var it: Dictionary = s.items[int(free[0])]
		_row(Rect2(x2, y2, col_w, 30.0), "L", "List %s" % String(it["name"]), "for %d" % int(round(float(Market.price(s, "charm", String(it["key"]), it)) * 1.1)), true, "list", 0)
	var lg: Array = st["log"]
	var ly := p.end.y - 54.0
	for i in range(mini(3, lg.size())):
		_text(Vector2(x2, ly - 18.0 * float(i)), String(lg[lg.size() - 1 - i]), 11, Ink.DIM)

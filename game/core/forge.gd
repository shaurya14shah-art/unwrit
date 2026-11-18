class_name Forge
extends RefCounted
## The forge, pure. Weapons, armour and runes are made from materials and
## shards. A pattern sets what a piece is and its tier; up to two temper
## materials push it toward something; and the hand that makes it, the
## soul's strongest habit, leaves a mark. Every piece also has a cost.
##
## Gear lives in soul.gear = {"weapon": item, "armour": item}; each item may
## hold runes in item["runes"]. Unworn pieces and runes sit in soul.items
## next to charms (item["type"] is "charm", "weapon", "armour" or "rune").

const MAX_TEMPER: int = 2
const TEMPER_COST: int = 3

const PATTERNS: Dictionary = {
	# weapons
	"w_bone": {"type": "weapon", "name": "Bone-Edge", "tier": 1, "needs": {"ash_bone": 12, "mask_shard": 4}, "shards": 80, "sockets": 1, "color": Color(0.9, 0.88, 0.8), "length": 1.0,
		"mods": {"dmg": [0.04, 0.08], "attack_speed": [-0.02, 0.0]}},
	"w_oath": {"type": "weapon", "name": "Oath Blade", "tier": 2, "needs": {"oath_steel": 10, "lantern_glass": 4}, "shards": 240, "sockets": 1, "color": Color(0.7, 0.78, 0.95), "length": 1.08,
		"mods": {"dmg": [0.08, 0.13], "attack_speed": [-0.04, -0.01]}},
	"w_glassfang": {"type": "weapon", "name": "Glassfang", "tier": 2, "needs": {"lantern_glass": 10, "mask_shard": 6}, "shards": 240, "sockets": 1, "color": Color(0.5, 0.95, 1.0), "length": 0.9,
		"mods": {"attack_speed": [0.05, 0.09], "dmg": [0.03, 0.06], "posture_dmg": [-0.1, -0.05]}},
	"w_bell": {"type": "weapon", "name": "Bellforged", "tier": 3, "needs": {"bell_bronze": 3, "tall_eye": 2, "oath_steel": 8}, "shards": 600, "sockets": 2, "color": Color(0.95, 0.72, 0.35), "length": 1.18,
		"mods": {"dmg": [0.13, 0.19], "posture_dmg": [0.06, 0.12], "attack_speed": [-0.06, -0.02]}},
	"w_brand": {"type": "weapon", "name": "Brandsteel", "tier": 4, "needs": {"brand_iron": 14, "gaoler_link": 4, "dune_glass": 2}, "shards": 1400, "sockets": 2, "color": Color(1.0, 0.45, 0.12), "length": 1.25,
		"mods": {"dmg": [0.19, 0.26], "heavy_dmg": [0.05, 0.1], "attack_speed": [-0.07, -0.03]}},
	"w_unwritten": {"type": "weapon", "name": "Unwritten Edge", "tier": 5, "needs": {"unwritten_ink": 2, "dune_glass": 4, "brand_iron": 10}, "shards": 3200, "sockets": 3, "color": Color(0.95, 0.95, 1.0), "length": 1.32,
		"mods": {"dmg": [0.26, 0.34], "swell_gain": [0.1, 0.16], "max_hp": [-0.07, -0.03]}},
	# armour
	"a_hide": {"type": "armour", "name": "Ash Hide", "tier": 1, "needs": {"ash_bone": 14}, "shards": 80, "sockets": 1, "color": Color(0.55, 0.45, 0.35), "look": "hide",
		"mods": {"max_hp": [0.05, 0.09], "move_speed": [-0.03, -0.01]}},
	"a_robe": {"type": "armour", "name": "Lantern Robe", "tier": 2, "needs": {"lantern_glass": 12, "ash_bone": 6}, "shards": 240, "sockets": 1, "color": Color(0.85, 0.92, 1.0), "look": "robe",
		"mods": {"anima_regen": [0.1, 0.16], "max_hp": [0.04, 0.07], "posture_max": [-0.07, -0.03]}},
	"a_oath": {"type": "armour", "name": "Oath Plate", "tier": 2, "needs": {"oath_steel": 12, "mask_shard": 8}, "shards": 240, "sockets": 1, "color": Color(0.7, 0.74, 0.82), "look": "plate",
		"mods": {"max_hp": [0.1, 0.15], "posture_max": [0.08, 0.14], "move_speed": [-0.06, -0.03]}},
	"a_carapace": {"type": "armour", "name": "Tall's Carapace", "tier": 3, "needs": {"tall_eye": 4, "mask_shard": 12, "oath_steel": 6}, "shards": 600, "sockets": 2, "color": Color(0.15, 0.15, 0.17), "look": "plate",
		"mods": {"max_hp": [0.15, 0.22], "posture_max": [0.12, 0.2], "move_speed": [-0.08, -0.04]}},
	"a_gaoler": {"type": "armour", "name": "Gaoler's Mail", "tier": 4, "needs": {"gaoler_link": 10, "brand_iron": 10, "dune_glass": 2}, "shards": 1400, "sockets": 2, "color": Color(0.4, 0.36, 0.32), "look": "plate",
		"mods": {"max_hp": [0.22, 0.3], "posture_max": [0.18, 0.26], "move_speed": [-0.1, -0.05]}},
	"a_pages": {"type": "armour", "name": "Robe of Blank Pages", "tier": 5, "needs": {"unwritten_ink": 2, "gaoler_link": 8, "lantern_glass": 12}, "shards": 3200, "sockets": 3, "color": Color(0.96, 0.96, 0.98), "look": "robe",
		"mods": {"max_hp": [0.25, 0.32], "swell_gain": [0.08, 0.13], "move_speed": [-0.05, -0.02]}},
	# runes: socketed into weapons and armour
	"r_ember": {"type": "rune", "name": "Ember Rune", "tier": 2, "needs": {"brand_iron": 3, "lantern_glass": 2}, "shards": 120, "color": Color(1.0, 0.45, 0.12),
		"effect": ["ember", 0.1, 0.16], "mods": {"anima_regen": [-0.05, -0.03]}},
	"r_frost": {"type": "rune", "name": "Frost Rune", "tier": 1, "needs": {"lantern_glass": 5, "mask_shard": 2}, "shards": 100, "color": Color(0.6, 0.9, 1.0),
		"effect": ["frost", 0.12, 0.2], "mods": {"attack_speed": [-0.03, -0.01]}},
	"r_leech": {"type": "rune", "name": "Leech Rune", "tier": 2, "needs": {"tall_eye": 1, "ash_bone": 6}, "shards": 160, "color": Color(1.0, 0.25, 0.35),
		"effect": ["leech", 0.03, 0.06], "mods": {"max_hp": [-0.04, -0.02]}},
	"r_storm": {"type": "rune", "name": "Storm Rune", "tier": 3, "needs": {"dune_glass": 1, "oath_steel": 4}, "shards": 220, "color": Color(0.75, 0.8, 1.0),
		"effect": ["storm", 0.12, 0.2], "mods": {"dmg": [-0.03, -0.01]}},
	"r_ward": {"type": "rune", "name": "Ward Rune", "tier": 2, "needs": {"gaoler_link": 2, "oath_steel": 4}, "shards": 180, "color": Color(0.85, 0.85, 0.7),
		"effect": ["ward", 0.05, 0.09], "mods": {"move_speed": [-0.04, -0.02]}},
	"r_haste": {"type": "rune", "name": "Haste Rune", "tier": 1, "needs": {"mask_shard": 6, "lantern_glass": 3}, "shards": 100, "color": Color(0.4, 1.0, 0.7),
		"effect": ["haste", 0.0, 0.0], "mods": {"attack_speed": [0.04, 0.07], "dmg": [-0.05, -0.03]}},
	"r_echo": {"type": "rune", "name": "Echo Rune", "tier": 3, "needs": {"bell_bronze": 1, "lantern_glass": 4}, "shards": 220, "color": Color(1.0, 0.85, 0.4),
		"effect": ["echo", 0.08, 0.14], "mods": {"tech_cost": [0.06, 0.1]}},
}

## What a temper material pushes a piece toward, per tier of the piece.
const TEMPER: Dictionary = {
	"ash_bone": {"max_hp": 0.012}, "mask_shard": {"posture_max": 0.018}, "lantern_glass": {"tech_dmg": 0.02},
	"oath_steel": {"parry_window": 0.003}, "tall_eye": {"heavy_dmg": 0.025}, "bell_bronze": {"swell_gain": 0.025},
	"dune_glass": {"attack_speed": 0.015}, "brand_iron": {"dmg": 0.015}, "gaoler_link": {"posture_dmg": 0.025},
	"unwritten_ink": {"tech_cost": -0.03},
}
## The maker's mark: the soul's strongest habit, and what it adds.
const HAND: Dictionary = {
	"aggression": ["Restless", {"attack_speed": 0.02}], "patience": ["Patient", {"parry_window": 0.004}],
	"mobility": ["Fleet", {"move_speed": 0.02}], "range": ["Farsighted", {"tech_dmg": 0.03}],
	"risk": ["Reckless", {"dmg": 0.03, "max_hp": -0.02}], "hunger": ["Hungry", {"heavy_dmg": 0.03}],
	"precision": ["Exact", {"posture_dmg": 0.03}], "weight": ["Heavy", {"heavy_dmg": 0.03}],
	"craft": ["Practised", {"tech_cost": -0.02}], "stillness": ["Quiet", {"anima_regen": 0.03}],
}


static func patterns_of(type: String) -> Array:
	var out: Array = []
	var keys: Array = PATTERNS.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ta := int(PATTERNS[a]["tier"])
		var tb := int(PATTERNS[b]["tier"])
		return ta < tb if ta != tb else String(a) < String(b))
	for k: Variant in keys:
		if type == "" or String(PATTERNS[k]["type"]) == type:
			out.append(String(k))
	return out


static func can_forge(soul: Soul, key: String, temper: Array = []) -> bool:
	if not PATTERNS.has(key) or temper.size() > MAX_TEMPER:
		return false
	var pat: Dictionary = PATTERNS[key]
	if soul.shards < int(pat["shards"]):
		return false
	var want := (pat["needs"] as Dictionary).duplicate()
	for t: Variant in temper:
		if String(pat["type"]) == "rune":
			return false
		want[t] = int(want.get(t, 0)) + TEMPER_COST
	for m: Variant in want.keys():
		if int(soul.materials.get(m, 0)) < int(want[m]):
			return false
	return true


## Makes a piece. Returns it (and puts it in soul.items), or {} if it cannot.
static func forge(soul: Soul, key: String, temper: Array = []) -> Dictionary:
	if not can_forge(soul, key, temper):
		return {}
	var pat: Dictionary = PATTERNS[key]
	soul.shards -= int(pat["shards"])
	var needs: Dictionary = pat["needs"]
	for m: Variant in needs.keys():
		soul.materials[m] = int(soul.materials[m]) - int(needs[m])
	for t: Variant in temper:
		soul.materials[t] = int(soul.materials[t]) - TEMPER_COST
	soul.flags["forged"] = int(soul.flags.get("forged", 0)) + 1
	var item := make(key, temper, soul.profile.dominant(), hash([soul.seed, "forge", int(soul.flags["forged"])]))
	soul.items.append(item)
	return item


## Rolls a piece from its pattern, its temper and the maker's hand.
static func make(key: String, temper: Array, hand: String, rng_seed: int) -> Dictionary:
	var pat: Dictionary = PATTERNS[key]
	var r := Rng.make([rng_seed, key, "forge"])
	var tier := int(pat["tier"])
	var mods := {}
	var quality := 0.0
	var defs: Dictionary = pat["mods"]
	var keys: Array = defs.keys()
	keys.sort()
	for m: Variant in keys:
		var rr: Array = defs[m]
		var q := r.randf()
		mods[m] = lerpf(float(rr[0]), float(rr[1]), q)
		var good_high := float(rr[1]) > 0.0 and String(m) != "tech_cost"
		quality += q if good_high else 1.0 - q
	quality /= maxf(1.0, float(keys.size()))
	var words: Array = []
	for t: Variant in temper:
		var tm: Dictionary = TEMPER[t]
		for m: Variant in tm.keys():
			mods[m] = float(mods.get(m, 0.0)) + float(tm[m]) * float(tier) * r.randf_range(0.8, 1.2)
		words.append(String((Items.MATERIALS[t] as Dictionary)["name"]))
	var mark := ""
	if String(pat["type"]) != "rune" and HAND.has(hand):
		var h: Array = HAND[hand]
		mark = String(h[0])
		var hm: Dictionary = h[1]
		for m: Variant in hm.keys():
			mods[m] = float(mods.get(m, 0.0)) + float(hm[m])
	var rarity := "Common"
	for rr: Variant in Items.RARITIES:
		if quality >= float((rr as Array)[1]):
			rarity = String((rr as Array)[0])
			break
	var name := String(pat["name"])
	if mark != "":
		name = "%s %s" % [mark, name]
	if not words.is_empty():
		name += " of " + " and ".join(words)
	var item := {"type": String(pat["type"]), "key": key, "name": name, "rarity": rarity, "quality": quality, "tier": tier,
		"mods": mods, "seed": rng_seed, "value": int(round(float(int(pat["shards"]) * 2 + 40 * tier * tier) * (0.7 + quality * 0.8)))}
	var c: Color = pat["color"]
	item["color"] = [c.r, c.g, c.b]
	if pat.has("length"):
		item["length"] = float(pat["length"])
	if pat.has("look"):
		item["look"] = String(pat["look"])
	if pat.has("sockets"):
		item["sockets"] = int(pat["sockets"])
		item["runes"] = []
	if pat.has("effect"):
		var e: Array = pat["effect"]
		item["effect"] = String(e[0])
		item["power"] = lerpf(float(e[1]), float(e[2]), r.randf())
	return item


static func color_of(item: Dictionary) -> Color:
	var c: Array = item.get("color", [1, 1, 1])
	return Color(float(c[0]), float(c[1]), float(c[2]))


# --------------------------------------------------------------- wearing

## Wears a weapon or armour from soul.items; what was worn goes back.
static func wear(soul: Soul, item_index: int) -> bool:
	if item_index < 0 or item_index >= soul.items.size():
		return false
	var it: Dictionary = soul.items[item_index]
	var slot := String(it.get("type", "charm"))
	if slot != "weapon" and slot != "armour":
		return false
	Items.take_item(soul, item_index)
	var old: Dictionary = soul.gear.get(slot, {})
	soul.gear[slot] = it
	if not old.is_empty():
		soul.items.append(old)
	return true


static func take_off(soul: Soul, slot: String) -> bool:
	var it: Dictionary = soul.gear.get(slot, {})
	if it.is_empty():
		return false
	soul.items.append(it)
	soul.gear[slot] = {}
	return true


## Sets a rune from soul.items into the first free socket: weapon, then armour.
static func socket(soul: Soul, item_index: int) -> String:
	if item_index < 0 or item_index >= soul.items.size():
		return ""
	var it: Dictionary = soul.items[item_index]
	if String(it.get("type", "")) != "rune":
		return ""
	for slot: String in ["weapon", "armour"]:
		var g: Dictionary = soul.gear.get(slot, {})
		if g.is_empty():
			continue
		var runes: Array = g.get("runes", [])
		if runes.size() < int(g.get("sockets", 0)):
			Items.take_item(soul, item_index)
			runes.append(it)
			g["runes"] = runes
			return slot
	return ""


static func unsocket(soul: Soul, slot: String, i: int) -> bool:
	var g: Dictionary = soul.gear.get(slot, {})
	var runes: Array = g.get("runes", [])
	if i < 0 or i >= runes.size():
		return false
	soul.items.append(runes[i])
	runes.remove_at(i)
	return true


static func tier_of(soul: Soul, slot: String) -> int:
	return int((soul.gear.get(slot, {}) as Dictionary).get("tier", 0))


static func rune_count(soul: Soul) -> int:
	var n := 0
	for slot: String in ["weapon", "armour"]:
		n += ((soul.gear.get(slot, {}) as Dictionary).get("runes", []) as Array).size()
	return n


## Every stat change from worn gear and its runes.
static func gear_mods(soul: Soul) -> Dictionary:
	var out := {}
	for slot: String in ["weapon", "armour"]:
		var g: Dictionary = soul.gear.get(slot, {})
		if g.is_empty():
			continue
		var parts: Array = [g]
		parts.append_array(g.get("runes", []))
		for p: Variant in parts:
			var mods: Dictionary = (p as Dictionary).get("mods", {})
			for m: Variant in mods.keys():
				out[m] = float(out.get(m, 0.0)) + float(mods[m])
	return out


## What the socketed runes do when you hit or are hit: {effect: power}.
static func rune_effects(soul: Soul) -> Dictionary:
	var out := {}
	for slot: String in ["weapon", "armour"]:
		for rn: Variant in ((soul.gear.get(slot, {}) as Dictionary).get("runes", []) as Array):
			var e := String((rn as Dictionary).get("effect", ""))
			if e != "" and e != "haste":
				out[e] = float(out.get(e, 0.0)) + float((rn as Dictionary).get("power", 0.0))
	return out


# ----------------------------------------------------------- requirements

## What each grade asks of a soul's gear before it may leave: worn weapon
## tier, worn armour tier, and runes set into them.
const REQUIRE: Dictionary = {
	5: {"weapon": 1, "armour": 0, "runes": 0},
	4: {"weapon": 2, "armour": 1, "runes": 0},
	3: {"weapon": 3, "armour": 2, "runes": 1},
	2: {"weapon": 3, "armour": 3, "runes": 2},
	1: {"weapon": 4, "armour": 4, "runes": 3},
}


static func gear_ok(soul: Soul) -> bool:
	return gear_gap(soul) == ""


static func gear_gap(soul: Soul) -> String:
	var req: Dictionary = REQUIRE.get(soul.grade, {})
	if req.is_empty():
		return ""
	var parts: Array = []
	if tier_of(soul, "weapon") < int(req["weapon"]):
		parts.append("wear a tier %d weapon" % int(req["weapon"]))
	if tier_of(soul, "armour") < int(req["armour"]):
		parts.append("wear tier %d armour" % int(req["armour"]))
	if rune_count(soul) < int(req["runes"]):
		parts.append("set %d rune%s" % [int(req["runes"]), "" if int(req["runes"]) == 1 else "s"])
	return ", ".join(parts)


static func describe(item: Dictionary) -> String:
	var line := Items.describe(item)
	if item.has("effect") and String(item["effect"]) != "haste":
		var words := {"ember": "chance to burn", "frost": "chance to slow", "leech": "of damage healed", "storm": "chance to arc to another", "ward": "less harm taken", "echo": "shorter technique cooldowns"}
		line = "%d%% %s, %s" % [int(round(float(item["power"]) * 100.0)), String(words.get(item["effect"], "")), line]
	if item.has("sockets"):
		line += "   [%d/%d runes]" % [(item.get("runes", []) as Array).size(), int(item["sockets"])]
	return line

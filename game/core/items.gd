class_name Items
extends RefCounted
## Loot, pure: shards (the currency), materials, and charms. Every charm has
## an upside and a downside rolled within its ranges, so two charms of the
## same name are rarely the same and none is simply better than having none.
## A soul keeps: soul.shards, soul.materials {id: count}, soul.items [charm
## dicts], soul.equipped [indexes into items, up to SLOTS].

const SLOTS: int = 3

const MATERIALS: Dictionary = {
	"ash_bone": {"name": "Ash Bone", "value": 4, "color": Color(0.85, 0.85, 0.8)},
	"mask_shard": {"name": "Mask Shard", "value": 7, "color": Color(0.95, 0.95, 0.92)},
	"lantern_glass": {"name": "Lantern Glass", "value": 10, "color": Color(0.5, 0.9, 1.0)},
	"oath_steel": {"name": "Oath Steel", "value": 12, "color": Color(0.7, 0.75, 0.85)},
	"tall_eye": {"name": "Eye of a Tall", "value": 60, "color": Color(1.0, 0.25, 0.25)},
	"bell_bronze": {"name": "Bell Bronze", "value": 80, "color": Color(0.9, 0.7, 0.35)},
	"dune_glass": {"name": "Dune Glass", "value": 110, "color": Color(1.0, 0.85, 0.4)},
	"brand_iron": {"name": "Brand Iron", "value": 28, "color": Color(1.0, 0.5, 0.15)},
	"gaoler_link": {"name": "Gaoler Link", "value": 45, "color": Color(0.55, 0.5, 0.45)},
	"unwritten_ink": {"name": "Unwritten Ink", "value": 300, "color": Color(0.1, 0.1, 0.12)},
}

## enemy kind -> [[material, chance]]
const DROPS: Dictionary = {
	"husk": [["ash_bone", 0.45]], "hound": [["ash_bone", 0.35], ["mask_shard", 0.15]],
	"gleaner": [["lantern_glass", 0.35]], "wraith": [["lantern_glass", 0.4]],
	"rogue": [["oath_steel", 0.4]], "sentinel": [["oath_steel", 0.7]],
	"stalker": [["mask_shard", 0.45]], "brute": [["ash_bone", 0.6], ["mask_shard", 0.4]],
	"giant": [["tall_eye", 1.0], ["mask_shard", 0.8]],
	"damned": [["brand_iron", 0.45]], "chainbound": [["gaoler_link", 0.3], ["brand_iron", 0.3]],
	"gaoler": [["gaoler_link", 0.8]], "cinder": [["brand_iron", 0.5]],
	"drill": [],
}
## great enemies: guaranteed materials
const BOSS_DROPS: Dictionary = {
	"gutter_king": [["mask_shard", 4]], "drowned_hound": [["lantern_glass", 4], ["mask_shard", 3]],
	"thane": [["oath_steel", 6]], "vael": [["oath_steel", 8], ["lantern_glass", 4]],
	"many_mouthed": [["tall_eye", 3]], "odrel": [["bell_bronze", 3]], "sereth": [["dune_glass", 3]],
	"ysolde": [["lantern_glass", 10]],
	"branded_king": [["brand_iron", 8]], "gaoler_prime": [["gaoler_link", 10]], "first_unwrit": [["unwritten_ink", 2]],
}

## Charm keys: what a charm changes. Fractions multiply the stat; parry_window adds.
const STAT_WORDS: Dictionary = {
	"dmg": "damage", "max_hp": "vitality", "posture_dmg": "stance damage", "posture_max": "stance",
	"move_speed": "move speed", "attack_speed": "swing speed", "swell_gain": "spirit pressure gained",
	"tech_cost": "technique cost", "tech_dmg": "technique damage", "anima_regen": "spirit energy return",
	"parry_window": "parry window", "dash_cd": "dash recovery time", "heavy_dmg": "heavy damage",
}

const CHARMS: Dictionary = {
	# the power bosses' charms: the strongest upsides, the sharpest costs
	"crown_of_brands": {"name": "Crown of Brands", "from": "branded_king", "value": 900, "mods": {"dmg": [0.12, 0.22], "max_hp": [-0.12, -0.07]}},
	"prime_link": {"name": "Prime Link", "from": "gaoler_prime", "value": 1300, "mods": {"posture_dmg": [0.28, 0.45], "move_speed": [-0.1, -0.05]}},
	"blank_page": {"name": "Blank Page", "from": "first_unwrit", "value": 2800, "mods": {"swell_gain": [0.22, 0.4], "tech_dmg": [0.1, 0.2], "tech_cost": [0.12, 0.2]}},
	# crafted at the shop's bench
	"bone_charm": {"name": "Bone Charm", "value": 90, "mods": {"max_hp": [0.06, 0.11], "attack_speed": [-0.06, -0.03]}},
	"mask_charm": {"name": "Mask Charm", "value": 140, "mods": {"posture_max": [0.1, 0.2], "anima_regen": [-0.1, -0.05]}},
	"glass_charm": {"name": "Glass Charm", "value": 170, "mods": {"tech_dmg": [0.1, 0.17], "max_hp": [-0.07, -0.04]}},
	"oath_charm": {"name": "Oath Charm", "value": 200, "mods": {"parry_window": [0.012, 0.024], "dmg": [-0.06, -0.03]}},
	"eye_charm": {"name": "Tall's Eye", "value": 420, "mods": {"heavy_dmg": [0.14, 0.24], "dash_cd": [0.08, 0.14]}},
	"bell_charm": {"name": "Bell Charm", "value": 520, "mods": {"swell_gain": [0.14, 0.24], "max_hp": [-0.06, -0.03]}},
	"brand_charm": {"name": "Brand Charm", "value": 480, "mods": {"dmg": [0.07, 0.12], "posture_max": [-0.12, -0.06]}},
}

const RECIPES: Array = [
	{"charm": "bone_charm", "needs": {"ash_bone": 10}, "shards": 60},
	{"charm": "mask_charm", "needs": {"mask_shard": 8}, "shards": 100},
	{"charm": "glass_charm", "needs": {"lantern_glass": 7}, "shards": 130},
	{"charm": "oath_charm", "needs": {"oath_steel": 7}, "shards": 160},
	{"charm": "eye_charm", "needs": {"tall_eye": 3, "mask_shard": 4}, "shards": 260},
	{"charm": "bell_charm", "needs": {"bell_bronze": 2, "lantern_glass": 4}, "shards": 320},
	{"charm": "brand_charm", "needs": {"brand_iron": 8, "gaoler_link": 2}, "shards": 300},
]

const RARITIES: Array = [["Mythic", 0.92], ["Rare", 0.72], ["Fine", 0.4], ["Common", 0.0]]


static func shards_for(level: int, elite: bool, boss: bool) -> int:
	var n := 2.0 + float(level) * 1.2
	if elite:
		n *= 2.5
	if boss:
		n *= 20.0
	return int(round(n))


## What a fallen enemy leaves. Repeatable from a seed: same enemy, same loot.
static func roll_drops(kind: String, level: int, elite: bool, rng_seed: int) -> Dictionary:
	var r := Rng.make([rng_seed, kind, "drops"])
	var boss := Bestiary.is_boss(kind)
	var out := {"shards": shards_for(level, elite, boss), "materials": {}, "charm": {}}
	var mats: Dictionary = out["materials"]
	for d: Variant in DROPS.get(kind, []):
		var dd: Array = d
		var chance := float(dd[1]) * (2.0 if elite else 1.0)
		if r.randf() < chance:
			mats[dd[0]] = int(mats.get(dd[0], 0)) + 1 + (1 if elite and r.randf() < 0.5 else 0)
	for d: Variant in BOSS_DROPS.get(kind, []):
		var dd: Array = d
		mats[dd[0]] = int(mats.get(dd[0], 0)) + int(dd[1])
	for key: Variant in CHARMS.keys():
		if String((CHARMS[key] as Dictionary).get("from", "")) == kind:
			out["charm"] = make_charm(String(key), rng_seed)
	return out


## Rolls a charm: each mod within its range, and a quality that names it.
static func make_charm(key: String, rng_seed: int) -> Dictionary:
	var def: Dictionary = CHARMS[key]
	var r := Rng.make([rng_seed, key, "charm"])
	var quality := 0.0
	var mods := {}
	var mod_defs: Dictionary = def["mods"]
	var keys: Array = mod_defs.keys()
	keys.sort()
	for m: Variant in keys:
		var rng: Array = mod_defs[m]
		var q := r.randf()
		var lo := float(rng[0])
		var hi := float(rng[1])
		# for a downside, the good roll is the smaller cost
		var good_is_high := hi > 0.0 and lo >= 0.0
		if String(m) == "tech_cost" or String(m) == "dash_cd":
			good_is_high = false
		mods[m] = lerpf(lo, hi, q)
		quality += q if good_is_high else 1.0 - q
	quality /= float(keys.size())
	var rarity := "Common"
	for rr: Variant in RARITIES:
		if quality >= float((rr as Array)[1]):
			rarity = String((rr as Array)[0])
			break
	return {"key": key, "name": String(def["name"]), "rarity": rarity, "quality": quality, "mods": mods,
		"value": int(round(float(def["value"]) * (0.7 + quality * 0.8))), "seed": rng_seed}


static func describe(charm: Dictionary) -> String:
	var parts: Array = []
	var mods: Dictionary = charm.get("mods", {})
	var keys: Array = mods.keys()
	keys.sort()
	for m: Variant in keys:
		var v := float(mods[m])
		if String(m) == "parry_window":
			parts.append("%+d ms %s" % [int(round(v * 1000.0)), String(STAT_WORDS[m])])
		else:
			parts.append("%+d%% %s" % [int(round(v * 100.0)), String(STAT_WORDS[m])])
	return ", ".join(parts)


static func has_downside(charm: Dictionary) -> bool:
	var mods: Dictionary = charm.get("mods", {})
	for m: Variant in mods.keys():
		var v := float(mods[m])
		if (String(m) == "tech_cost" or String(m) == "dash_cd") and v > 0.0:
			return true
		if String(m) != "tech_cost" and String(m) != "dash_cd" and v < 0.0:
			return true
	return false


# -------------------------------------------------------------- inventory

static func gain(soul: Soul, drops: Dictionary) -> void:
	soul.shards += int(drops.get("shards", 0))
	var mats: Dictionary = drops.get("materials", {})
	for m: Variant in mats.keys():
		soul.materials[m] = int(soul.materials.get(m, 0)) + int(mats[m])
	var charm: Dictionary = drops.get("charm", {})
	if not charm.is_empty():
		soul.items.append(charm)


static func can_craft(soul: Soul, i: int) -> bool:
	if i < 0 or i >= RECIPES.size():
		return false
	var rec: Dictionary = RECIPES[i]
	if soul.shards < int(rec["shards"]):
		return false
	var needs: Dictionary = rec["needs"]
	for m: Variant in needs.keys():
		if int(soul.materials.get(m, 0)) < int(needs[m]):
			return false
	return true


static func craft(soul: Soul, i: int) -> Dictionary:
	if not can_craft(soul, i):
		return {}
	var rec: Dictionary = RECIPES[i]
	soul.shards -= int(rec["shards"])
	var needs: Dictionary = rec["needs"]
	for m: Variant in needs.keys():
		soul.materials[m] = int(soul.materials[m]) - int(needs[m])
	soul.flags["crafted"] = int(soul.flags.get("crafted", 0)) + 1
	var charm := make_charm(String(rec["charm"]), hash([soul.seed, "craft", int(soul.flags["crafted"])]))
	soul.items.append(charm)
	return charm


static func toggle_equip(soul: Soul, item_index: int) -> bool:
	if item_index < 0 or item_index >= soul.items.size():
		return false
	if String((soul.items[item_index] as Dictionary).get("type", "charm")) != "charm":
		return false
	var at := soul.equipped.find(item_index)
	if at >= 0:
		soul.equipped.remove_at(at)
		return true
	if soul.equipped.size() >= SLOTS:
		return false
	soul.equipped.append(item_index)
	return true


## Removes an item and keeps the equipped indexes pointing at the right ones.
static func take_item(soul: Soul, item_index: int) -> Dictionary:
	if item_index < 0 or item_index >= soul.items.size():
		return {}
	var it: Dictionary = soul.items[item_index]
	soul.items.remove_at(item_index)
	var keep: Array = []
	for e: Variant in soul.equipped:
		var ei := int(e)
		if ei == item_index:
			continue
		keep.append(ei - 1 if ei > item_index else ei)
	soul.equipped = keep
	return it


## The sum of every equipped charm's mods.
static func equipped_mods(soul: Soul) -> Dictionary:
	var out := {}
	for e: Variant in soul.equipped:
		var ei := int(e)
		if ei < 0 or ei >= soul.items.size():
			continue
		if String((soul.items[ei] as Dictionary).get("type", "charm")) != "charm":
			continue
		var mods: Dictionary = (soul.items[ei] as Dictionary).get("mods", {})
		for m: Variant in mods.keys():
			out[m] = float(out.get(m, 0.0)) + float(mods[m])
	return out

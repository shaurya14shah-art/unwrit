class_name Stats
extends RefCounted
## Turns a soul into the numbers combat uses. Skill tree bonuses set from
## habits, and rites make one stat feed another, so two souls with the same
## skills do not hit the same.

static func base_totals(soul: Soul) -> Dictionary:
	var t := SkillTree.totals(soul)
	var add: Dictionary = t["stats"]
	var out := {}
	for s in SkillTree.STATS:
		out[s] = maxi(1, int(soul.base[s]) + int(add[s]))
	return out


const LEVEL_HP: float = 0.03
const LEVEL_DMG: float = 0.025


static func compute(soul: Soul) -> Dictionary:
	var t := SkillTree.totals(soul)
	var add: Dictionary = t["stats"]
	var b := {}
	for s in SkillTree.STATS:
		b[s] = float(maxi(1, int(soul.base[s]) + int(add[s])))
	var edge := float(b["edge"])
	var tempo := float(b["tempo"])
	var focus := float(b["focus"])
	var frame := float(b["frame"])
	var d := {
		"edge": edge, "tempo": tempo, "focus": focus, "frame": frame,
		"max_hp": 90.0 + frame * 6.0,
		"max_anima": 80.0 + focus * 4.0,
		"anima_regen": 3.0 + focus * 0.12,
		"light_dmg": 7.0 + edge * 0.8,
		"heavy_dmg": 16.0 + edge * 1.5,
		"tech_dmg": 1.0,
		"posture_dmg": 1.0,
		"posture_max": 50.0 + frame * 2.0,
		"parry_window": 0.17 + minf(focus, 80.0) * 0.0006,
		"dash_cd": maxf(0.3, 0.75 - tempo * 0.005),
		"move_speed": 7.2 + minf(tempo, 100.0) * 0.025,
		"attack_speed": 1.0 + minf(tempo, 150.0) * 0.003,
		"swell_gain": 1.0,
	}
	d["tech_kind"] = SkillTree.tech_mult(soul)
	# a soul grows a little with every level (balance pass, 2026-11-16)
	var lv := float(maxi(1, soul.level) - 1)
	d["max_hp"] = float(d["max_hp"]) * (1.0 + LEVEL_HP * lv)
	d["light_dmg"] = float(d["light_dmg"]) * (1.0 + LEVEL_DMG * lv)
	d["heavy_dmg"] = float(d["heavy_dmg"]) * (1.0 + LEVEL_DMG * lv)
	_stage(soul, d)
	_charms(soul, d)
	var pct: Dictionary = t["pct"]
	for target: Variant in pct.keys():
		var v := float(pct[target])
		if String(target) == "dash_cd":
			d["dash_cd"] = maxf(0.2, float(d["dash_cd"]) / maxf(0.2, 1.0 + v))
		elif d.has(String(target)):
			d[target] = float(d[target]) * maxf(0.1, 1.0 + v)
	var rites: Array = t["rites"]
	for rite: Variant in rites:
		var r: Dictionary = rite
		var steps := float(b[r["per"]]) / 10.0
		var bonus := float(r["amount"]) * steps
		var target := String(r["target"])
		if target == "dash_cd":
			d["dash_cd"] = maxf(0.2, float(d["dash_cd"]) / (1.0 + bonus))
		else:
			d[target] = float(d[target]) * (1.0 + bonus)
	return d


## Each race's quiet gift. A grafted second strain gives half of its own.
## (Regrowth, the Devourer's, works in play: Player._tick_regrowth.)
static func _race_passive(strain: String, k: float, soul: Soul, d: Dictionary) -> void:
	match strain:
		"vigil":
			d["parry_window"] = float(d["parry_window"]) * (1.0 + 0.15 * k)
		"lumen":
			d["anima_regen"] = float(d["anima_regen"]) * (1.0 + 0.4 * k)
		"relic":
			var mem := minf(0.15, 0.03 * soul.profile.count("relics")) * k
			d["light_dmg"] = float(d["light_dmg"]) * (1.0 + mem)
			d["heavy_dmg"] = float(d["heavy_dmg"]) * (1.0 + mem)


## What a soul's strain and grade do to its body. Every stage trades: none
## is simply bigger. A soul that refused its graft is a little sharper.
static func _stage(soul: Soul, d: Dictionary) -> void:
	var climbed := float(5 - clampi(soul.grade, 0, 5)) if soul.written() else 0.0
	d["max_hp"] = float(d["max_hp"]) * (1.0 + 0.05 * climbed)
	d["light_dmg"] = float(d["light_dmg"]) * (1.0 + 0.04 * climbed)
	d["heavy_dmg"] = float(d["heavy_dmg"]) * (1.0 + 0.04 * climbed)
	match soul.primary:
		"maw":
			if soul.grade == 4:
				d["max_hp"] = float(d["max_hp"]) * 1.3
				d["posture_max"] = float(d["posture_max"]) * 1.3
				d["move_speed"] = float(d["move_speed"]) * 0.9
				d["attack_speed"] = float(d["attack_speed"]) * 0.92
			elif soul.grade == 3:
				d["move_speed"] = float(d["move_speed"]) * 1.12
				d["attack_speed"] = float(d["attack_speed"]) * 1.1
				d["max_hp"] = float(d["max_hp"]) * 0.95
			elif soul.grade <= 2:
				d["swell_gain"] = float(d["swell_gain"]) * 1.2
				d["max_hp"] = float(d["max_hp"]) * 1.08
		"vigil":
			d["parry_window"] = float(d["parry_window"]) + 0.006 * climbed
			d["posture_dmg"] = float(d["posture_dmg"]) * (1.0 + 0.04 * climbed)
		"lumen":
			d["tech_dmg"] = float(d["tech_dmg"]) * (1.0 + 0.06 * climbed)
			d["max_hp"] = float(d["max_hp"]) * 0.95
		"relic":
			d["anima_regen"] = float(d["anima_regen"]) * (1.0 + 0.08 * climbed)
			d["max_anima"] = float(d["max_anima"]) * (1.0 + 0.04 * climbed)
	_race_passive(soul.primary, 1.0, soul, d)
	_race_passive(soul.secondary, 0.5, soul, d)
	if bool(soul.flags.get("pure", false)):
		d["light_dmg"] = float(d["light_dmg"]) * 1.08
		d["heavy_dmg"] = float(d["heavy_dmg"]) * 1.08
		d["swell_gain"] = float(d["swell_gain"]) * 1.15


## What equipped charms do. Fractions multiply; the parry window adds.
static func _charms(soul: Soul, d: Dictionary) -> void:
	var mods := Items.equipped_mods(soul)
	var gm := Forge.gear_mods(soul)
	for m: Variant in gm.keys():
		mods[m] = float(mods.get(m, 0.0)) + float(gm[m])
	d["tech_cost"] = 1.0
	d["tech_cd"] = 1.0 - float(Forge.rune_effects(soul).get("echo", 0.0))
	for m: Variant in mods.keys():
		var v := float(mods[m])
		match String(m):
			"dmg":
				d["light_dmg"] = float(d["light_dmg"]) * (1.0 + v)
				d["heavy_dmg"] = float(d["heavy_dmg"]) * (1.0 + v)
			"parry_window":
				d["parry_window"] = float(d["parry_window"]) + v
			"tech_cost":
				d["tech_cost"] = 1.0 + v
			_:
				if d.has(String(m)):
					d[String(m)] = float(d[String(m)]) * (1.0 + v)

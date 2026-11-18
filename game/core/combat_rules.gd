class_name CombatRules
extends RefCounted
## What happens when a blow reaches a body. Pure: no nodes, no time. The scene
## gathers the facts, this decides, the scene shows it. A server could own
## this file unchanged.

const CHIP: float = 0.12
const PARRY_POSTURE: float = 34.0

## attack: {dmg, posture, heavy, blockable, parryable, ranged}
## defender: {invulnerable, dash_age, blocking, block_age, facing, parry_window,
##            posture, posture_max, armored}
static func resolve(attack: Dictionary, defender: Dictionary) -> Dictionary:
	var dmg := float(attack.get("dmg", 0.0))
	var pdmg := float(attack.get("posture", 0.0))
	var out := {"outcome": "hit", "dmg": dmg, "posture": pdmg, "attacker_posture": 0.0,
		"stagger": false, "perfect": false, "reflect": false}
	if bool(defender.get("invulnerable", false)):
		out["outcome"] = "dodged"
		out["dmg"] = 0.0
		out["posture"] = 0.0
		out["perfect"] = float(defender.get("dash_age", 1.0)) <= 0.14
		return out
	var guarding := bool(defender.get("blocking", false)) and bool(defender.get("facing", true))
	if guarding and bool(attack.get("parryable", true)) \
			and float(defender.get("block_age", 9.0)) <= float(defender.get("parry_window", 0.17)):
		out["outcome"] = "parried"
		out["dmg"] = 0.0
		out["posture"] = 0.0
		out["attacker_posture"] = PARRY_POSTURE * (1.6 if bool(attack.get("heavy", false)) else 1.0)
		out["reflect"] = bool(attack.get("ranged", false))
		return out
	if guarding and bool(attack.get("blockable", true)):
		out["outcome"] = "blocked"
		out["dmg"] = dmg * CHIP
		out["posture"] = pdmg * 1.25
	var left := float(defender.get("posture", 0.0)) + float(out["posture"])
	if left >= float(defender.get("posture_max", 100.0)):
		out["stagger"] = true
		out["broke"] = true
	elif out["outcome"] == "hit" and not bool(defender.get("armored", false)):
		out["stagger"] = true
	return out

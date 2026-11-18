class_name SkillTree
extends RefCounted
## The skill tree, pure. Four disciplines, each one straight path of eight
## tiers. Two tiers in each path are forks: take one, and the other closes
## for good, so two souls who spend the same points still end up apart.
## Every skill exists exactly once in the whole tree: no repeats under other
## names. A skill's strength sets from the soul's habits when it is taken.
## Past the capstone, Mastery ranks go on forever.
##
## soul.tree = {node_id: {"k": habit factor}}, soul.mastery = {branch: ranks}
##
## The disciplines lean on one another. They sit on a square:
##     Swordsmanship -- Footwork
##          |               |
##     Hand-to-Hand  -- Spirit Arts
## Support: tiers 5 to 8 need a neighbour no more than three tiers behind.
## Harmony: a discipline's skills grow stronger, live, as BOTH neighbours
## climb (+6% per tier of the shallower one, up to +30%). Opposition: the
## two pairs across the square pull apart; holding both capstones of a pair
## doubles both their costs. Lopsided builds stall; balanced ones grow.

const STATS: Array[String] = ["edge", "tempo", "focus", "frame"]
const STAT_TITLE: Dictionary = {"edge": "Blade", "tempo": "Speed", "focus": "Spirit", "frame": "Body"}

const BRANCHES: Array[String] = ["blade", "body", "speed", "spirit"]
const BRANCH: Dictionary = {
	"blade": {"title": "Swordsmanship", "stat": "edge", "line": "The cut itself: harder, cleaner, and through a guard.", "color": Color(0.86, 0.42, 0.34)},
	"body": {"title": "Hand-to-Hand", "stat": "frame", "line": "Your body as the weapon: weight, toughness, standing your ground.", "color": Color(0.84, 0.64, 0.36)},
	"speed": {"title": "Footwork", "stat": "tempo", "line": "Moving first and moving often: dashes, tempo, momentum.", "color": Color(0.45, 0.78, 0.64)},
	"spirit": {"title": "Spirit Arts", "stat": "focus", "line": "Techniques and spirit energy: more of it, and more from it.", "color": Color(0.6, 0.64, 0.95)},
}

const NEIGHBOURS: Dictionary = {"blade": ["speed", "body"], "speed": ["blade", "spirit"], "spirit": ["speed", "body"], "body": ["blade", "spirit"]}
const OPPOSITE: Dictionary = {"blade": "spirit", "spirit": "blade", "speed": "body", "body": "speed"}
const SUPPORT_GAP: int = 3
const SUPPORT_FROM: int = 5
const HARMONY_STEP: float = 0.06
const HARMONY_MAX: float = 0.3

## The cost of a tier: cheap to start, dear at the top.
const TIER_COST: Array[int] = [0, 1, 1, 2, 2, 3, 3, 4, 5]
const TIERS: int = 8
const MASTERY_COST: int = 2
const MASTERY_STAT: int = 2

## Every node: id, branch, tier, name, a short line for the tree, and its
## effects. "pct" and "rite" effects with a positive amount set from habits.
## ["stat", stat, n] | ["pct", target, amount] | ["rite", target, per_stat, amount per 10] | ["tech", kind]
const NODES: Array = [
	# Swordsmanship
	{"id": "blade.1", "tier": 1, "name": "Grip", "fx": [["stat", "edge", 3]]},
	{"id": "blade.2", "tier": 2, "name": "Clean Cuts", "fx": [["pct", "light_dmg", 0.06]]},
	{"id": "blade.3a", "tier": 3, "name": "Heavy Hand", "fx": [["pct", "heavy_dmg", 0.1], ["pct", "attack_speed", -0.03]]},
	{"id": "blade.3b", "tier": 3, "name": "Quick Draw", "fx": [["pct", "attack_speed", 0.06], ["pct", "heavy_dmg", -0.04]]},
	{"id": "blade.4", "tier": 4, "name": "Rising Arc", "fx": [["tech", "rise"]]},
	{"id": "blade.5", "tier": 5, "name": "Edge Sense", "fx": [["rite", "posture_dmg", "edge", 0.03]]},
	{"id": "blade.6a", "tier": 6, "name": "Riposte", "fx": [["pct", "parry_window", 0.1]]},
	{"id": "blade.6b", "tier": 6, "name": "Sunder", "fx": [["pct", "posture_dmg", 0.12]]},
	{"id": "blade.7", "tier": 7, "name": "Sword Discipline", "fx": [["stat", "edge", 5]]},
	{"id": "blade.8", "tier": 8, "name": "One Cut", "fx": [["pct", "heavy_dmg", 0.25], ["pct", "light_dmg", 0.1], ["pct", "max_hp", -0.1]]},
	# Hand-to-Hand
	{"id": "body.1", "tier": 1, "name": "Conditioning", "fx": [["stat", "frame", 3]]},
	{"id": "body.2", "tier": 2, "name": "Iron Skin", "fx": [["pct", "max_hp", 0.06]]},
	{"id": "body.3a", "tier": 3, "name": "Rooted", "fx": [["pct", "posture_max", 0.12], ["pct", "move_speed", -0.03]]},
	{"id": "body.3b", "tier": 3, "name": "Brawler", "fx": [["pct", "heavy_dmg", 0.08], ["pct", "max_hp", -0.03]]},
	{"id": "body.4", "tier": 4, "name": "Gnash", "fx": [["tech", "gnash"]]},
	{"id": "body.5", "tier": 5, "name": "Second Wind", "fx": [["rite", "anima_regen", "frame", 0.04]]},
	{"id": "body.6a", "tier": 6, "name": "Still Guard", "fx": [["tech", "guard"]]},
	{"id": "body.6b", "tier": 6, "name": "Unbroken", "fx": [["pct", "max_hp", 0.1]]},
	{"id": "body.7", "tier": 7, "name": "Body Discipline", "fx": [["stat", "frame", 5]]},
	{"id": "body.8", "tier": 8, "name": "Mountain", "fx": [["pct", "max_hp", 0.2], ["pct", "posture_max", 0.15], ["pct", "move_speed", -0.08]]},
	# Footwork
	{"id": "speed.1", "tier": 1, "name": "Light Feet", "fx": [["stat", "tempo", 3]]},
	{"id": "speed.2", "tier": 2, "name": "Quick Recovery", "fx": [["pct", "dash_cd", 0.08]]},
	{"id": "speed.3a", "tier": 3, "name": "Momentum", "fx": [["rite", "light_dmg", "tempo", 0.02]]},
	{"id": "speed.3b", "tier": 3, "name": "Stride", "fx": [["pct", "move_speed", 0.06]]},
	{"id": "speed.4", "tier": 4, "name": "Sever Step", "fx": [["tech", "sever"]]},
	{"id": "speed.5", "tier": 5, "name": "Flurry", "fx": [["pct", "attack_speed", 0.05]]},
	{"id": "speed.6a", "tier": 6, "name": "Afterimage", "fx": [["pct", "dash_cd", 0.12], ["pct", "max_hp", -0.04]]},
	{"id": "speed.6b", "tier": 6, "name": "Pressure", "fx": [["pct", "swell_gain", 0.1]]},
	{"id": "speed.7", "tier": 7, "name": "Footwork Discipline", "fx": [["stat", "tempo", 5]]},
	{"id": "speed.8", "tier": 8, "name": "Blur", "fx": [["pct", "attack_speed", 0.12], ["pct", "move_speed", 0.08], ["pct", "max_hp", -0.12]]},
	# Spirit Arts
	{"id": "spirit.1", "tier": 1, "name": "Attunement", "fx": [["stat", "focus", 3]]},
	{"id": "spirit.2", "tier": 2, "name": "Deep Reserve", "fx": [["pct", "max_anima", 0.1]]},
	{"id": "spirit.3a", "tier": 3, "name": "Channel", "fx": [["pct", "tech_dmg", 0.08]]},
	{"id": "spirit.3b", "tier": 3, "name": "Wellspring", "fx": [["pct", "anima_regen", 0.12]]},
	{"id": "spirit.4", "tier": 4, "name": "Pale Lance", "fx": [["tech", "lance"]]},
	{"id": "spirit.5", "tier": 5, "name": "Resonance", "fx": [["rite", "tech_dmg", "focus", 0.03]]},
	{"id": "spirit.6a", "tier": 6, "name": "Low Toll", "fx": [["tech", "toll"]]},
	{"id": "spirit.6b", "tier": 6, "name": "Clear Mind", "fx": [["pct", "parry_window", 0.08], ["pct", "anima_regen", 0.05]]},
	{"id": "spirit.7", "tier": 7, "name": "Spirit Discipline", "fx": [["stat", "focus", 5]]},
	{"id": "spirit.8", "tier": 8, "name": "Overflow", "fx": [["pct", "tech_dmg", 0.25], ["pct", "swell_gain", 0.15], ["pct", "light_dmg", -0.1]]},
]

## What each effect is called, in words.
const TARGET_WORDS: Dictionary = {
	"light_dmg": "light cuts", "heavy_dmg": "heavy cuts", "tech_dmg": "technique damage",
	"posture_dmg": "stance damage", "max_hp": "vitality", "anima_regen": "spirit energy return",
	"max_anima": "spirit energy", "parry_window": "parry window", "dash_cd": "dash recovery",
	"swell_gain": "spirit pressure gained", "attack_speed": "swing speed", "move_speed": "move speed",
	"posture_max": "stance",
}

## Which habit strengthens which effect when it sets.
const HABIT: Dictionary = {
	"light_dmg": "aggression", "heavy_dmg": "weight", "tech_dmg": "craft", "posture_dmg": "patience",
	"max_hp": "risk", "anima_regen": "stillness", "max_anima": "stillness", "parry_window": "patience",
	"dash_cd": "mobility", "swell_gain": "precision", "attack_speed": "aggression", "move_speed": "mobility",
	"posture_max": "patience",
}

static var _by_id: Dictionary = {}


static func node(id: String) -> Dictionary:
	if _by_id.is_empty():
		for n: Variant in NODES:
			var d: Dictionary = (n as Dictionary).duplicate(true)
			d["branch"] = String(d["id"]).get_slice(".", 0)
			d["cost"] = TIER_COST[int(d["tier"])]
			_by_id[d["id"]] = d
	return _by_id.get(id, {})


static func nodes_of(branch: String, tier: int) -> Array:
	var out: Array = []
	for n: Variant in NODES:
		var d: Dictionary = n
		if String(d["id"]).begins_with(branch + ".") and int(d["tier"]) == tier:
			out.append(String(d["id"]))
	return out


## The other side of a fork, or "".
static func sibling(id: String) -> String:
	if not (id.ends_with("a") or id.ends_with("b")):
		return ""
	return id.substr(0, id.length() - 1) + ("b" if id.ends_with("a") else "a")


static func tier_taken(soul: Soul, branch: String, tier: int) -> bool:
	if tier <= 0:
		return true
	for id: Variant in nodes_of(branch, tier):
		if soul.tree.has(id):
			return true
	return false


static func spent_in(soul: Soul, branch: String) -> int:
	var n := 0
	for id: Variant in soul.tree.keys():
		var d := node(String(id))
		if String(d.get("branch", "")) == branch:
			n += int(d["cost"])
	return n + int(soul.mastery.get(branch, 0)) * MASTERY_COST


## How deep a soul has gone in a discipline: the highest tier taken.
static func depth(soul: Soul, branch: String) -> int:
	var n := 0
	for tier in range(1, TIERS + 1):
		if tier_taken(soul, branch, tier):
			n = tier
	return n


## The tier a neighbour must reach before this tier opens (0: none).
static func support_need(tier: int) -> int:
	return tier - SUPPORT_GAP if tier >= SUPPORT_FROM else 0


static func supported(soul: Soul, branch: String, tier: int) -> bool:
	var need := support_need(tier)
	if need <= 0:
		return true
	for nb: Variant in NEIGHBOURS[branch]:
		if depth(soul, String(nb)) >= need:
			return true
	return false


## How much a discipline's skills are lifted by its neighbours: 1.0 to 1.3.
static func harmony(soul: Soul, branch: String) -> float:
	var nbs: Array = NEIGHBOURS[branch]
	var low := mini(depth(soul, String(nbs[0])), depth(soul, String(nbs[1])))
	return 1.0 + minf(HARMONY_MAX, HARMONY_STEP * float(low))


## Both capstones of an opposed pair held: both their costs double.
static func opposed(soul: Soul, branch: String) -> bool:
	return soul.tree.has(branch + ".8") and soul.tree.has(String(OPPOSITE[branch]) + ".8")


## What a taken (or would-be) skill's gains are multiplied by right now.
static func shown_k(soul: Soul, id: String) -> float:
	var d := node(id)
	var k := float((soul.tree.get(id, {}) as Dictionary).get("k", habit_k(soul, id)))
	return k * harmony(soul, String(d.get("branch", "blade")))


## Techniques are lifted by the harmony of the discipline that taught them.
static func tech_mult(soul: Soul) -> Dictionary:
	var out := {}
	for n: Variant in NODES:
		var d: Dictionary = n
		for fx: Variant in d["fx"]:
			if String((fx as Array)[0]) == "tech":
				out[(fx as Array)[1]] = harmony(soul, String(d["id"]).get_slice(".", 0))
	return out


## Why a node cannot be taken now, or "" if it can.
static func why_not(soul: Soul, id: String) -> String:
	var d := node(id)
	if d.is_empty():
		return "No such skill."
	if soul.tree.has(id):
		return "Taken."
	var sib := sibling(id)
	if sib != "" and soul.tree.has(sib):
		return "Closed: you chose %s." % String(node(sib)["name"])
	if not tier_taken(soul, String(d["branch"]), int(d["tier"]) - 1):
		return "Take a tier %d skill in %s first." % [int(d["tier"]) - 1, String(BRANCH[d["branch"]]["title"])]
	if not supported(soul, String(d["branch"]), int(d["tier"])):
		var nbs: Array = NEIGHBOURS[d["branch"]]
		return "Needs support: %s or %s at tier %d." % [String(BRANCH[nbs[0]]["title"]), String(BRANCH[nbs[1]]["title"]), support_need(int(d["tier"]))]
	if soul.marks < int(d["cost"]):
		return "Needs %d skill point%s." % [int(d["cost"]), "" if int(d["cost"]) == 1 else "s"]
	return ""


static func can_take(soul: Soul, id: String) -> bool:
	return why_not(soul, id) == ""


## The habit factor a node would set to for this soul: 0.8 to 1.2.
static func habit_k(soul: Soul, id: String) -> float:
	var d := node(id)
	for fx: Variant in d.get("fx", []):
		var f: Array = fx
		if (String(f[0]) == "pct" or String(f[0]) == "rite") and float(f[f.size() - 1]) > 0.0:
			return 0.8 + 0.4 * soul.profile.trait_of(String(HABIT.get(f[1], "precision")))
	return 1.0


## Takes a skill. A technique you already know is honed instead of given twice.
static func take(soul: Soul, id: String) -> bool:
	if not can_take(soul, id):
		return false
	var d := node(id)
	soul.marks -= int(d["cost"])
	soul.tree[id] = {"k": habit_k(soul, id)}
	for fx: Variant in d["fx"]:
		var f: Array = fx
		if String(f[0]) == "tech":
			var kind := String(f[1])
			var known := known_technique(soul, kind)
			if known >= 0:
				var t: Dictionary = soul.techniques[known]
				t["dmg"] = float(t["dmg"]) * 1.12
				t["cd"] = float(t["cd"]) * 0.92
				t["honed"] = true
				soul.tree[id]["honed"] = true
			else:
				soul.techniques.append(AbilityForge.technique(kind, soul.seed, Stats.base_totals(soul), soul.profile, soul.techniques.size()))
				soul.slot_technique(soul.techniques.size() - 1)
	return true


static func known_technique(soul: Soul, kind: String) -> int:
	for i in range(soul.techniques.size()):
		if String((soul.techniques[i] as Dictionary).get("kind", "")) == kind:
			return i
	return -1


static func can_master(soul: Soul, branch: String) -> bool:
	return soul.tree.has(branch + ".8") and soul.marks >= MASTERY_COST


static func master(soul: Soul, branch: String) -> bool:
	if not can_master(soul, branch):
		return false
	soul.marks -= MASTERY_COST
	soul.mastery[branch] = int(soul.mastery.get(branch, 0)) + 1
	return true


## Flat stats, percentage bonuses and rites from everything taken.
static func totals(soul: Soul) -> Dictionary:
	var stats := {"edge": 0, "tempo": 0, "focus": 0, "frame": 0}
	var pct := {}
	var rites: Array = []
	var ids: Array = soul.tree.keys()
	ids.sort()
	var harm := {}
	for b: String in BRANCHES:
		harm[b] = harmony(soul, b)
	for id: Variant in ids:
		var d := node(String(id))
		if d.is_empty():
			continue
		var br := String(d["branch"])
		var k := float((soul.tree[id] as Dictionary).get("k", 1.0)) * float(harm[br])
		var cost_k := 2.0 if int(d["tier"]) == TIERS and opposed(soul, br) else 1.0
		for fx: Variant in d["fx"]:
			var f: Array = fx
			match String(f[0]):
				"stat":
					stats[f[1]] = int(stats[f[1]]) + int(f[2])
				"pct":
					var amt := float(f[2])
					pct[f[1]] = float(pct.get(f[1], 0.0)) + (amt * k if amt > 0.0 else amt * cost_k)
				"rite":
					rites.append({"target": String(f[1]), "per": String(f[2]), "amount": float(f[3]) * k})
	for b: Variant in soul.mastery.keys():
		var st := String(BRANCH[b]["stat"])
		stats[st] = int(stats[st]) + int(soul.mastery[b]) * MASTERY_STAT
	return {"stats": stats, "pct": pct, "rites": rites}


## One line for the tree card. `cost_k` scales the downsides.
static func short(id: String, k: float = 1.0, cost_k: float = 1.0) -> String:
	var d := node(id)
	var parts: Array = []
	for fx: Variant in d["fx"]:
		var f: Array = fx
		match String(f[0]):
			"stat":
				parts.append("+%d %s" % [int(f[2]), String(STAT_TITLE[f[1]])])
			"pct":
				var amt := float(f[2]) * (k if float(f[2]) > 0.0 else cost_k)
				parts.append("%+d%% %s" % [int(round(amt * 100.0)), String(TARGET_WORDS.get(f[1], f[1]))])
			"rite":
				parts.append("+%.1f%% %s per 10 %s" % [float(f[3]) * k * 100.0, String(TARGET_WORDS.get(f[1], f[1])), String(STAT_TITLE[f[2]])])
			"tech":
				parts.append("New technique")
	return ", ".join(parts)


## The full text for the detail card.
static func describe(soul: Soul, id: String) -> String:
	var d := node(id)
	for fx: Variant in d["fx"]:
		var f: Array = fx
		if String(f[0]) == "tech":
			var kind := String(f[1])
			var line := String(AbilityForge.TECH[kind]["line"])
			if known_technique(soul, kind) >= 0 and not soul.tree.has(id):
				return line + " You already know it, so taking this hones it instead: +12% damage, 8% shorter cooldown."
			return line + " It sets to your stats and habits when taken."
	var k := float((soul.tree.get(id, {}) as Dictionary).get("k", habit_k(soul, id)))
	var br := String(d["branch"])
	var h := harmony(soul, br)
	var text := short(id, k * h, cost_k(soul, id)) + "."
	for fx: Variant in d["fx"]:
		var f: Array = fx
		if (String(f[0]) == "pct" or String(f[0]) == "rite") and float(f[f.size() - 1]) > 0.0:
			text += " Habit: %s, %.2fx%s. Harmony from %s and %s: %.2fx." % [String(HABIT.get(f[1], "precision")), k, "" if soul.tree.has(id) else " if taken now", String(BRANCH[NEIGHBOURS[br][0]]["title"]), String(BRANCH[NEIGHBOURS[br][1]]["title"]), h]
			break
	if int(d["tier"]) == TIERS:
		text += " Opposed by %s: holding both capstones doubles both costs%s." % [String(BRANCH[OPPOSITE[br]]["title"]), " (doubled now)" if opposed(soul, br) else ""]
	if support_need(int(d["tier"])) > 0:
		text += " Needs %s or %s at tier %d." % [String(BRANCH[NEIGHBOURS[br][0]]["title"]), String(BRANCH[NEIGHBOURS[br][1]]["title"]), support_need(int(d["tier"]))]
	if sibling(id) != "":
		text += " A fork: taking this closes %s." % String(node(sibling(id))["name"])
	return text


static func cost_k(soul: Soul, id: String) -> float:
	var d := node(id)
	if int(d.get("tier", 0)) != TIERS:
		return 1.0
	var br := String(d["branch"])
	var both := soul.tree.has(String(OPPOSITE[br]) + ".8")
	return 2.0 if both else 1.0


## Points a soul spent in an old Lattice, to give back when a save from
## before the tree is loaded.
static func lattice_refund(old: Dictionary) -> int:
	var n := 0
	for id: Variant in old.keys():
		var ring := int(String(id).get_slice(".", 0))
		n += 1 + ring / 2
	return n

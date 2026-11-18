class_name Soul
extends RefCounted
## One save. A soul begins with a seed and nothing else: no race, no power,
## no name. Everything below is written by play.

const START_STAT: int = 5

var seed: int = 0
var level: int = 1
var essence: float = 0.0
var marks: int = 2
var base: Dictionary = {"edge": START_STAT, "tempo": START_STAT, "focus": START_STAT, "frame": START_STAT}
var affinity: Dictionary = Strains.blank()
var primary: String = ""
var secondary: String = ""
var profile: Profile = Profile.new()
var release: Dictionary = {}
var techniques: Array = []
var loadout: Array = [0, 1, 2, 3]
## The skill tree: taken skills {id: {"k": habit factor}}, and Mastery ranks.
var tree: Dictionary = {}
var mastery: Dictionary = {}
var flags: Dictionary = {}
var playtime: float = 0.0
var grade: int = 5
var standing: float = 0.0
var shards: int = 0
var materials: Dictionary = {}
var items: Array = []
var equipped: Array = []
var market: Dictionary = {}
var gear: Dictionary = {"weapon": {}, "armour": {}}


static func create(soul_seed: int) -> Soul:
	var s := Soul.new()
	s.seed = soul_seed
	return s


## Each level costs more than the last, and faster than linearly, so the
## early levels come quickly and the later ones have to be earned.
func essence_needed() -> float:
	return 60.0 + 22.0 * pow(float(level), 1.55)


func at_cap() -> bool:
	return level >= Quests.level_cap(self)


## Returns how many levels were gained. At the grade's cap essence stops
## piling up at one level's worth: the rest is lost until promotion.
func gain_essence(amount: float) -> int:
	essence += amount
	var ups := 0
	if at_cap():
		essence = minf(essence, essence_needed())
		return 0
	while essence >= essence_needed() and not at_cap():
		essence -= essence_needed()
		level += 1
		marks += 2
		ups += 1
	if at_cap():
		essence = minf(essence, essence_needed())
	return ups


## Puts a technique on the hotbar: an empty slot if there is one, else the
## fourth. Returns the slot used.
func slot_technique(index: int) -> int:
	for i in range(4):
		if int(loadout[i]) >= techniques.size() or int(loadout[i]) == index:
			loadout[i] = index
			return i
	loadout[3] = index
	return 3


## Moves a technique to the next slot round (1 to 4), swapping with what
## was there. Returns the new slot.
func cycle_slot(index: int) -> int:
	var cur := loadout.find(index)
	var to := 0 if cur < 0 else (cur + 1) % 4
	var other: int = int(loadout[to])
	loadout[to] = index
	if cur >= 0:
		loadout[cur] = other
	return to


func written() -> bool:
	return primary != ""


func form_name() -> String:
	return Strains.form_name(primary, secondary)


func second_strain() -> String:
	return Strains.leading(affinity, primary)


## A second strain can be let in once it is strong, the soul has reached
## Grade 3, and the soul has not already refused it.
func can_graft() -> bool:
	if primary == "" or secondary != "" or bool(flags.get("pure", false)):
		return false
	if grade > 3:
		return false
	var second := Strains.leading(affinity, primary)
	return float(affinity.get(second, 0.0)) >= Strains.GRAFT_THRESHOLD


func graft() -> String:
	if not can_graft():
		return ""
	secondary = Strains.leading(affinity, primary)
	return form_name()


## How this soul looks, read from the seed. Never chosen.
func look() -> Dictionary:
	var r := Rng.make([seed, "look"])
	var tone := 0.1 + r.randf() * 0.5
	return {
		"hair": int(r.randi() % 5),
		"hair_tone": tone,
		"hair_tint": int(r.randi() % 4),
		"coat": int(r.randi() % 3),
		"build": 0.94 + r.randf() * 0.12,
		"sash": int(r.randi() % 3),
		"skin": int(r.randi() % 5),
		"face": int(r.randi() % 4),
	}


func to_dict() -> Dictionary:
	return {
		"v": 1, "seed": seed, "level": level, "essence": essence, "marks": marks,
		"base": base.duplicate(), "affinity": affinity.duplicate(),
		"primary": primary, "secondary": secondary, "profile": profile.to_dict(),
		"release": release.duplicate(true), "techniques": techniques.duplicate(true),
		"loadout": loadout.duplicate(), "tree": tree.duplicate(true), "mastery": mastery.duplicate(),
		"flags": flags.duplicate(true), "playtime": playtime,
		"grade": grade, "standing": standing, "shards": shards, "materials": materials.duplicate(),
		"items": items.duplicate(true), "equipped": equipped.duplicate(), "market": market.duplicate(true), "gear": gear.duplicate(true),
	}


static func from_dict(d: Dictionary) -> Soul:
	var s := Soul.new()
	s.seed = int(d.get("seed", 0))
	s.level = int(d.get("level", 1))
	s.essence = float(d.get("essence", 0.0))
	s.marks = int(d.get("marks", 0))
	var b: Dictionary = d.get("base", {})
	for k: Variant in b.keys():
		s.base[String(k)] = int(b[k])
	var a: Dictionary = d.get("affinity", {})
	for k: Variant in a.keys():
		s.affinity[String(k)] = float(a[k])
	s.primary = String(d.get("primary", ""))
	s.secondary = String(d.get("secondary", ""))
	s.profile = Profile.from_dict(d.get("profile", {}))
	s.release = (d.get("release", {}) as Dictionary).duplicate(true)
	s.techniques = (d.get("techniques", []) as Array).duplicate(true)
	s.loadout = (d.get("loadout", [0, 1, 2, 3]) as Array).duplicate()
	for i in range(s.loadout.size()):
		s.loadout[i] = int(s.loadout[i])
	s.tree = (d.get("tree", {}) as Dictionary).duplicate(true)
	s.mastery = (d.get("mastery", {}) as Dictionary).duplicate()
	# a save from before the skill tree: give back what the Lattice took
	var old: Dictionary = d.get("lattice", {})
	if not d.has("tree") and not old.is_empty():
		s.marks += SkillTree.lattice_refund(old)
	s.flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	s.playtime = float(d.get("playtime", 0.0))
	s.grade = int(d.get("grade", 5))
	s.standing = float(d.get("standing", 0.0))
	s.shards = int(d.get("shards", 0))
	var mats: Dictionary = d.get("materials", {})
	for k: Variant in mats.keys():
		s.materials[String(k)] = int(mats[k])
	s.items = (d.get("items", []) as Array).duplicate(true)
	s.equipped = []
	for e: Variant in d.get("equipped", []):
		s.equipped.append(int(e))
	s.market = (d.get("market", {}) as Dictionary).duplicate(true)
	var g: Dictionary = d.get("gear", {})
	s.gear = {"weapon": (g.get("weapon", {}) as Dictionary).duplicate(true), "armour": (g.get("armour", {}) as Dictionary).duplicate(true)}
	# saves from before the story: an awakened soul goes to its realm
	if not s.flags.has("chapter"):
		s.flags["chapter"] = "hub" if s.primary != "" else "prologue"
	return s


func save_to(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true


static func load_from(path: String) -> Soul:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return Soul.from_dict(parsed)

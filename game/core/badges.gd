class_name Badges
extends RefCounted
## Badges: small marks for things a soul has done, each paying a few shards
## the moment it is earned. Kept in soul.flags["badges"] as {id: true}.
## Most are checked from the soul's own counts (`check`); a few are given
## straight from the world when they happen (`award`).

const ALL: Array = [
	# id, name, what earns it, shards
	["first_blood", "First Blood", "Put something down for good.", 15],
	["slayer", "Slayer", "100 kills.", 60],
	["reaper_of_many", "Reaper of Many", "500 kills.", 200],
	["deflector", "Deflector", "Parry 25 blows.", 40],
	["untouchable", "Untouchable", "Parry 200 blows.", 150],
	["crate_buster", "Crate Buster", "Break 30 crates, barrels or urns.", 30],
	["treasure_hunter", "Treasure Hunter", "Open a chest.", 20],
	["hoarder", "Hoarder", "Open 15 chests.", 120],
	["mimic_slayer", "Not a Chest", "Kill a mimic.", 60],
	["orb_seeker", "Orb Seeker", "Gather 25 spirit orbs.", 40],
	["lamplighter", "Lamplighter", "Gather every spirit orb in one realm.", 150],
	["every_light", "Every Light", "Gather every spirit orb in every realm.", 600],
	["familiar_face", "Familiar Face", "Talk to 10 different souls about town.", 30],
	["everyones_friend", "Everyone's Friend", "Talk to 25 different souls.", 100],
	["challenger", "Challenger", "Earn a medal at a challenge stone.", 30],
	["gold_standard", "Gold Standard", "Earn a gold medal at a challenge stone.", 80],
	["all_gold", "Golden", "Gold at every challenge stone.", 400],
	["straw_man", "Straw Man", "Land 200 blows on a training dummy.", 25],
	["heavy_hitter", "Heavy Hitter", "Deal 150 damage a second to a dummy.", 60],
	["lightning_rod", "Lightning Rod", "Stand where the lightning falls.", 10],
	["storm_caller", "Storm Caller", "Let lightning kill an enemy for you.", 50],
	["night_owl", "Night Owl", "25 kills by night.", 50],
	["streak", "Rampage", "Five kills, each within three seconds of the last.", 60],
	["awakened", "Awakened", "Wake as what you are.", 25],
	["graded", "Moving Up", "Earn a promotion.", 50],
	["captain", "Top of the Board", "Reach Grade 1.", 400],
	["wealthy", "Deep Pockets", "Hold 1,000 shards at once.", 0],
	["smith", "Smith", "Wear gear you forged.", 30],
	["wanderer", "Wanderer", "Set foot in four realms.", 60],
	["homecoming", "Homecoming", "Walk a lost soul home.", 40],
]


static func def(id: String) -> Array:
	for b: Variant in ALL:
		if String((b as Array)[0]) == id:
			return b
	return []


static func has(soul: Soul, id: String) -> bool:
	return (soul.flags.get("badges", {}) as Dictionary).has(id)


static func count(soul: Soul) -> int:
	return (soul.flags.get("badges", {}) as Dictionary).size()


## Gives a badge once. Returns its definition if it is new, else [].
static func award(soul: Soul, id: String) -> Array:
	var d := def(id)
	if d.is_empty() or has(soul, id):
		return []
	var got: Dictionary = soul.flags.get("badges", {})
	got[id] = true
	soul.flags["badges"] = got
	soul.shards += int(d[3])
	return d


static func tally(soul: Soul, key: String) -> int:
	return int(soul.flags.get(key, 0))


## Every badge the soul's counts have earned and it does not hold yet.
static func check(soul: Soul) -> Array:
	var out: Array = []
	var kills := int(soul.profile.count("kills"))
	var parries := int(soul.profile.count("parries"))
	var want := {
		"first_blood": kills >= 1, "slayer": kills >= 100, "reaper_of_many": kills >= 500,
		"deflector": parries >= 25, "untouchable": parries >= 200,
		"crate_buster": tally(soul, "crates") >= 30,
		"treasure_hunter": tally(soul, "chests") >= 1, "hoarder": tally(soul, "chests") >= 15,
		"orb_seeker": tally(soul, "orbs") >= 25,
		"familiar_face": (soul.flags.get("folk_met", {}) as Dictionary).size() >= 10,
		"everyones_friend": (soul.flags.get("folk_met", {}) as Dictionary).size() >= 25,
		"straw_man": tally(soul, "dummy_hits") >= 200,
		"night_owl": tally(soul, "night_kills") >= 25,
		"awakened": soul.written(),
		"graded": soul.written() and soul.grade <= 4,
		"captain": soul.written() and soul.grade <= 1,
		"wealthy": soul.shards >= 1000,
		"smith": not (soul.gear.get("weapon", {}) as Dictionary).is_empty(),
		"wanderer": (soul.flags.get("visited", {}) as Dictionary).size() >= 4,
		"homecoming": Quests.times_done(soul, "g_mira_brother") >= 1,
	}
	for id: Variant in want.keys():
		if bool(want[id]):
			var d := award(soul, String(id))
			if not d.is_empty():
				out.append(d)
	return out

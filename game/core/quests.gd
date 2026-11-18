class_name Quests
extends RefCounted
## Quest boards, grades and the climb. Pure: no nodes. A soul's quest state
## lives in soul.flags["quests"]; its rank in soul.grade (5 lowest, 0 top)
## and soul.standing (earned by quests, spent on promotion).
##
## A promotion needs two things: enough standing, and the grade's trial, a
## great enemy chosen by the soul's strain. Each grade also caps the level a
## soul can reach, so levelling alone never carries anyone far.

const MAX_ACTIVE: int = 3

## standing needed to seek promotion away from each grade
const STANDING_NEED: Dictionary = {5: 60, 4: 140, 3: 260, 2: 420, 1: 650}
## highest level each grade allows
const LEVEL_CAP: Dictionary = {5: 10, 4: 18, 3: 28, 2: 40, 1: 55, 0: 999}
const PROLOGUE_CAP: int = 6
const TRAINING_CAP: int = 8

const TITLES: Dictionary = {
	"vigil": {5: "Unseated Reaper", 4: "Seated Reaper", 3: "Reaper Officer", 2: "Reaper Lieutenant", 1: "Reaper Captain", 0: "Reaper Commander"},
	"maw": {5: "Husk", 4: "Colossus", 3: "Stalker", 2: "Sovereign", 1: "Crowned Sovereign", 0: "the Hunger Itself"},
	"lumen": {5: "Archer Initiate", 4: "Archer", 3: "Lantern Archer", 2: "Starbearer", 1: "Constellation", 0: "Polestar"},
	"relic": {5: "Touched", 4: "Binder", 3: "Keeper", 2: "Twin-Bound", 1: "Reliquary", 0: "the Remembered"},
}

## the great enemy each strain must beat to leave each grade. The Undermark's
## three (the Branded King, Gaoler Prime, the First Unwrit) are not trials:
## they are optional power bosses that drop charms.
const TRIALS: Dictionary = {
	"vigil": {5: "thane", 4: "many_mouthed", 3: "vael", 2: "odrel", 1: "sereth"},
	"maw": {5: "many_mouthed", 4: "odrel", 3: "sereth", 2: "thane", 1: "vael"},
	"lumen": {5: "drowned_hound", 4: "odrel", 3: "ysolde", 2: "vael", 1: "sereth"},
	"relic": {5: "drowned_hound", 4: "many_mouthed", 3: "odrel", 2: "sereth", 1: "vael"},
}

const BOSS_NAMES: Dictionary = {
	"gutter_king": "the Gutter King", "drowned_hound": "the Drowned Hound", "thane": "Thane, the Gate",
	"vael": "Vael Morrow, the Oathbreaker", "many_mouthed": "the Many-Mouthed", "odrel": "Odrel, the Bell-Eater",
	"sereth": "Sereth, Queen of Dunes", "ysolde": "Ysolde, the Last Lantern",
	"branded_king": "the Branded King", "gaoler_prime": "Gaoler Prime", "first_unwrit": "the First Unwrit",
}
const POWER_BOSSES: Array = ["branded_king", "gaoler_prime", "first_unwrit"]

const BOSS_WHERE: Dictionary = {
	"gutter_king": "the flats courtyard, Calder Town", "drowned_hound": "the river, west Calder Town",
	"thane": "the great gate of the Citadel", "vael": "the Spire, inner Citadel",
	"many_mouthed": "the Crystal Undergrowth, the Wastes", "odrel": "the Bell Court, the Wastes",
	"sereth": "the Sunken Throne, the Wastes", "ysolde": "the Lantern Spire, the Silver Reach",
	"branded_king": "the court of brands, the Undermark", "gaoler_prime": "the iron yard, the Undermark",
	"first_unwrit": "the island throne, the Undermark",
}

## Which board serves which strain. "lingering" is the prologue's.
const BOARDS: Dictionary = {
	"lingering": {"title": "The Lingering Board", "strain": ""},
	"lantern": {"title": "Lantern House Notices", "strain": "lumen"},
	"shop": {"title": "The Shop Ledger", "strain": "relic"},
	"citadel": {"title": "Citadel Duty Board", "strain": "vigil"},
	"hunt": {"title": "The Hunt Stone", "strain": "maw"},
	"exchange": {"title": "The Exchange", "strain": "*"},
	"forge": {"title": "The Forge", "strain": "*"},
	# people who ask: quest givers in the hubs, anyone may help them
	"g_mira": {"title": "Mira Okafor", "strain": "*", "npc": true},
	"g_pell": {"title": "Old Pell", "strain": "*", "npc": true},
	"g_hana": {"title": "Officer Hana Ves", "strain": "*", "npc": true},
	"g_kesh": {"title": "Kesh", "strain": "*", "npc": true},
	"g_odile": {"title": "Odile", "strain": "*", "npc": true},
	"g_quill": {"title": "Quill", "strain": "*", "npc": true},
}

## kind: kill | devour | send | relic | parry | tech | boss | deliver | escort
## deliver: target is a material, handed over when you talk to the giver.
## escort: target is a lost soul's id; "region" and "find" say where it waits.
## target: an enemy kind, "any", or "any@<region>"; for boss, the boss id
## rank: offered once soul.grade <= rank (5 = from the start)
const DEFS: Array = [
	{"id": "p_strays", "board": "lingering", "title": "Strays in the Street", "text": "The pale things that hunt the lingering dead. Put five of them down.", "kind": "kill", "target": "husk", "count": 5, "standing": 0, "essence": 60, "rank": 5},
	{"id": "p_keepsakes", "board": "lingering", "title": "What You Left", "text": "Things of yours are still lying around this town. Find two and remember.", "kind": "relic", "target": "any", "count": 2, "standing": 0, "essence": 60, "rank": 5},
	{"id": "p_king", "board": "lingering", "title": "The Gutter King", "text": "Something huge has made a nest in the flats courtyard. It eats the strays. Then it will eat you.", "kind": "boss", "target": "gutter_king", "count": 1, "standing": 0, "essence": 160, "rank": 5},

	{"id": "l_hounds", "board": "lantern", "title": "Dogs at the Bridges", "text": "Hounds run the river roads. Six of them.", "kind": "kill", "target": "hound", "count": 6, "standing": 24, "essence": 120, "rank": 5, "repeat": true},
	{"id": "l_wraiths", "board": "lantern", "title": "Lights Out", "text": "Wraiths drift through the flats after dark. Four of them.", "kind": "kill", "target": "wraith", "count": 4, "standing": 26, "essence": 130, "rank": 5, "repeat": true},
	{"id": "l_send", "board": "lantern", "title": "Lanterns for the Dead", "text": "Send six fallen souls on. Do not eat them.", "kind": "send", "target": "any", "count": 6, "standing": 22, "essence": 100, "rank": 5, "repeat": true},
	{"id": "l_parry", "board": "lantern", "title": "Turn It Back", "text": "Parry twelve blows. Bolts count.", "kind": "parry", "target": "any", "count": 12, "standing": 26, "essence": 120, "rank": 4, "repeat": true},
	{"id": "l_wastes", "board": "lantern", "title": "Below the Tear", "text": "Go down to the Wastes and put ten things down.", "kind": "kill", "target": "any@ashfall", "count": 10, "standing": 40, "essence": 260, "rank": 4, "repeat": true},
	{"id": "l_reach", "board": "lantern", "title": "Keep the Reach", "text": "Ten things in the Silver Reach. The lake must stay lit.", "kind": "kill", "target": "any@reach", "count": 10, "standing": 30, "essence": 200, "rank": 5, "repeat": true},
	{"id": "l_lights", "board": "lantern", "title": "Lost Lights", "text": "Lanterns of fallen Archers lie in the snow. Find two and remember them.", "kind": "relic", "target": "any", "count": 2, "standing": 30, "essence": 160, "rank": 5},
	{"id": "l_tall", "board": "lantern", "title": "Bring Down the Tall", "text": "A Tall walks the Undergrowth. Bring one down.", "kind": "kill", "target": "giant", "count": 1, "standing": 60, "essence": 420, "rank": 3, "repeat": true},

	{"id": "s_relics", "board": "shop", "title": "Things Remember", "text": "Three keepsakes, from anywhere. Hold them and listen.", "kind": "relic", "target": "any", "count": 3, "standing": 34, "essence": 140, "rank": 5},
	{"id": "s_tech", "board": "shop", "title": "Practice", "text": "Use your techniques twenty times on something that fights back.", "kind": "tech", "target": "any", "count": 20, "standing": 22, "essence": 110, "rank": 5, "repeat": true},
	{"id": "s_hounds", "board": "shop", "title": "Pest Control", "text": "Six hounds. The shop pays in standing.", "kind": "kill", "target": "hound", "count": 6, "standing": 24, "essence": 120, "rank": 5, "repeat": true},
	{"id": "s_brutes", "board": "shop", "title": "Heavy Lifting", "text": "Three gravebrutes in the Wastes.", "kind": "kill", "target": "brute", "count": 3, "standing": 44, "essence": 300, "rank": 4, "repeat": true},
	{"id": "s_rogues", "board": "shop", "title": "Debts in the Citadel", "text": "Five rogue reapers owe the shop. Collect.", "kind": "kill", "target": "rogue", "count": 5, "standing": 50, "essence": 360, "rank": 3, "repeat": true},

	{"id": "c_rogues", "board": "citadel", "title": "Deserters", "text": "Rogue reapers hide in the Lower Rings. Six of them.", "kind": "kill", "target": "rogue", "count": 6, "standing": 26, "essence": 140, "rank": 5, "repeat": true},
	{"id": "c_send", "board": "citadel", "title": "The Duty", "text": "A Reaper sends the dead on. Eight of them.", "kind": "send", "target": "any", "count": 8, "standing": 24, "essence": 120, "rank": 5, "repeat": true},
	{"id": "c_parry", "board": "citadel", "title": "Form Drills", "text": "Parry twelve blows in real fighting.", "kind": "parry", "target": "any", "count": 12, "standing": 24, "essence": 120, "rank": 5, "repeat": true},
	{"id": "c_sentinels", "board": "citadel", "title": "Broken Watch", "text": "Four sentinels have turned on the city. Break them.", "kind": "kill", "target": "sentinel", "count": 4, "standing": 40, "essence": 260, "rank": 4, "repeat": true},
	{"id": "c_breach", "board": "citadel", "title": "Through the Breach", "text": "Six stalkers in the Wastes. Go through the Breach.", "kind": "kill", "target": "stalker", "count": 6, "standing": 44, "essence": 320, "rank": 4, "repeat": true},
	{"id": "c_tall", "board": "citadel", "title": "The Tall", "text": "Two Talls. They are slow. They are not weak.", "kind": "kill", "target": "giant", "count": 2, "standing": 70, "essence": 520, "rank": 3, "repeat": true},

	{"id": "h_devour", "board": "hunt", "title": "Feed", "text": "Devour eight of the fallen.", "kind": "devour", "target": "any", "count": 8, "standing": 24, "essence": 130, "rank": 5, "repeat": true},
	{"id": "h_husks", "board": "hunt", "title": "Thin the Herd", "text": "Ten husks.", "kind": "kill", "target": "husk", "count": 10, "standing": 24, "essence": 120, "rank": 5, "repeat": true},
	{"id": "h_gleaners", "board": "hunt", "title": "Gleaners", "text": "Six gleaners. Turn their bolts on them.", "kind": "kill", "target": "gleaner", "count": 6, "standing": 28, "essence": 150, "rank": 5, "repeat": true},
	{"id": "h_stalkers", "board": "hunt", "title": "Rivals", "text": "Six stalkers. They want what you want.", "kind": "kill", "target": "stalker", "count": 6, "standing": 36, "essence": 240, "rank": 4, "repeat": true},
	{"id": "h_brutes", "board": "hunt", "title": "Bigger Meat", "text": "Three gravebrutes.", "kind": "kill", "target": "brute", "count": 3, "standing": 44, "essence": 300, "rank": 4, "repeat": true},
	{"id": "h_tall", "board": "hunt", "title": "Eat a Tall", "text": "Bring down a Tall. Then eat it.", "kind": "kill", "target": "giant", "count": 1, "standing": 60, "essence": 420, "rank": 3, "repeat": true},
	{"id": "c_deep", "board": "citadel", "title": "Below Everything", "text": "Break the seal in the Wastes and put twelve things down in the Undermark.", "kind": "kill", "target": "any@undermark", "count": 12, "standing": 90, "essence": 1200, "rank": 2, "repeat": true},
	{"id": "h_deep", "board": "hunt", "title": "The Deepest Meat", "text": "Twelve kills in the Undermark. They get up again; eat them before they do.", "kind": "kill", "target": "any@undermark", "count": 12, "standing": 90, "essence": 1200, "rank": 2, "repeat": true},
	{"id": "l_deep", "board": "lantern", "title": "Light Below", "text": "Carry your light into the Undermark. Twelve kills.", "kind": "kill", "target": "any@undermark", "count": 12, "standing": 90, "essence": 1200, "rank": 2, "repeat": true},
	{"id": "s_deep", "board": "shop", "title": "Deep Stock", "text": "Twelve kills in the Undermark. Bring back what you remember.", "kind": "kill", "target": "any@undermark", "count": 12, "standing": 90, "essence": 1200, "rank": 2, "repeat": true},
	{"id": "g_mira_brother", "board": "g_mira", "title": "Her Brother", "text": "My little brother died on the river road. He never came home. He is somewhere out past the warehouses, by the water. Find him and walk him back to me. Please.", "kind": "escort", "target": "town_brother", "region": "town", "find": [-150.0, -118.0], "count": 1, "standing": 10, "essence": 160, "shards": 60, "rank": 5},
	{"id": "g_pell_bone", "board": "g_pell", "title": "Bones for the Kiln", "text": "I fire charms in the kiln behind the shop. Bring me eight Ash Bone and I'll pay you for your trouble.", "kind": "deliver", "target": "ash_bone", "count": 8, "standing": 14, "essence": 90, "shards": 140, "rank": 5, "repeat": true},
	{"id": "g_pell_strays", "board": "g_pell", "title": "Strays at My Door", "text": "Strays keep sniffing round the shop. Six of them, and I'll sleep.", "kind": "kill", "target": "husk", "count": 6, "standing": 14, "essence": 100, "shards": 80, "rank": 5, "repeat": true},
	{"id": "g_hana_recruit", "board": "g_hana", "title": "The Lost Recruit", "text": "A new recruit ran from his first fight. He is hiding in the Outer Rings and too ashamed to come back. Bring him to me. No one has to know.", "kind": "escort", "target": "citadel_recruit", "region": "citadel", "find": [150.0, 170.0], "count": 1, "standing": 24, "essence": 240, "shards": 120, "rank": 5},
	{"id": "g_hana_steel", "board": "g_hana", "title": "Steel for the Gate", "text": "The gate's fittings need oath steel. Six of it.", "kind": "deliver", "target": "oath_steel", "count": 6, "standing": 22, "essence": 160, "shards": 200, "rank": 5, "repeat": true},
	{"id": "g_kesh_masks", "board": "g_kesh", "title": "Faces", "text": "I stopped eating. I collect faces instead. Bring me ten mask shards and I will not ask why you have them.", "kind": "deliver", "target": "mask_shard", "count": 10, "standing": 22, "essence": 170, "shards": 220, "rank": 5, "repeat": true},
	{"id": "g_kesh_lost", "board": "g_kesh", "title": "Not Yet Eaten", "text": "Someone fell through the world today and nothing has found her yet. She is west, among the dunes. Bring her here before something hungrier does.", "kind": "escort", "target": "wastes_lost", "region": "ashfall", "find": [-70.0, 240.0], "count": 1, "standing": 24, "essence": 240, "shards": 120, "rank": 5},
	{"id": "g_odile_glass", "board": "g_odile", "title": "Glass for the Lamps", "text": "Every lantern on the lake burns glass. Bring me eight lantern glass.", "kind": "deliver", "target": "lantern_glass", "count": 8, "standing": 20, "essence": 150, "shards": 200, "rank": 5, "repeat": true},
	{"id": "g_odile_child", "board": "g_odile", "title": "The Child on the Ice", "text": "A child wandered onto the frozen lake and will not come off it. She trusts no one with a bow. You, maybe. Bring her to me.", "kind": "escort", "target": "reach_child", "region": "reach", "find": [-40.0, 60.0], "count": 1, "standing": 24, "essence": 240, "shards": 120, "rank": 5},
	{"id": "g_quill_links", "board": "g_quill", "title": "Links for the Wheel", "text": "The Wheel's chains wear thin. Bring me four mask shards; I can make links of anything.", "kind": "deliver", "target": "mask_shard", "count": 4, "standing": 18, "essence": 140, "shards": 160, "rank": 5, "repeat": true},
	{"id": "g_quill_reader", "board": "g_quill", "title": "The Reader", "text": "A soul came down to read one book and never came back up. She is by the Wheel, still reading. Bring her to me before the shelves keep her.", "kind": "escort", "target": "stacks_reader", "region": "stacks", "find": [32.0, -28.0], "count": 1, "standing": 24, "essence": 220, "shards": 120, "rank": 5},
	{"id": "g_quill_bound", "board": "g_quill", "title": "Loose Chains", "text": "Chainbound wander the deep shelves. Five of them. Bring their chains down.", "kind": "kill", "target": "chainbound", "count": 5, "standing": 40, "essence": 380, "shards": 140, "rank": 4, "repeat": true},
	{"id": "s_stacks", "board": "shop", "title": "Dust the Shelves", "text": "Ten things in the Stacks that should not be moving.", "kind": "kill", "target": "any@stacks", "count": 10, "standing": 28, "essence": 190, "rank": 5, "repeat": true},
	{"id": "h_raid", "board": "hunt", "title": "Raid the Citadel", "text": "Through the Breach. Six rogue reapers.", "kind": "kill", "target": "rogue", "count": 6, "standing": 70, "essence": 520, "rank": 2, "repeat": true},
]


static func def(id: String) -> Dictionary:
	for d: Variant in DEFS:
		if String((d as Dictionary)["id"]) == id:
			return d
	return {}


static func state(soul: Soul) -> Dictionary:
	if not soul.flags.has("quests"):
		soul.flags["quests"] = {}
	return soul.flags["quests"]


static func active(soul: Soul) -> Array:
	var out: Array = []
	var st := state(soul)
	var ids: Array = st.keys()
	ids.sort()
	for id: Variant in ids:
		var q: Dictionary = st[id]
		if String(q.get("s", "")) == "active" or String(q.get("s", "")) == "ready":
			out.append(String(id))
	return out


static func progress(soul: Soul, id: String) -> int:
	return int((state(soul).get(id, {}) as Dictionary).get("n", 0))


static func is_ready(soul: Soul, id: String) -> bool:
	return String((state(soul).get(id, {}) as Dictionary).get("s", "")) == "ready"


static func times_done(soul: Soul, id: String) -> int:
	return int((state(soul).get(id, {}) as Dictionary).get("t", 0))


## The strains a soul may serve: its own, its graft, or none before Awakening.
static func board_accepts(soul: Soul, board: String) -> bool:
	var want := String((BOARDS.get(board, {}) as Dictionary).get("strain", "?"))
	if want == "*":
		return true
	if want == "":
		return not soul.written()
	return want == soul.primary or want == soul.secondary


static func available(soul: Soul, board: String) -> Array:
	var out: Array = []
	if not board_accepts(soul, board):
		return out
	var st := state(soul)
	for d: Variant in DEFS:
		var q: Dictionary = d
		if String(q["board"]) != board:
			continue
		if soul.grade > int(q["rank"]):
			continue
		var id := String(q["id"])
		var cur: Dictionary = st.get(id, {})
		var s := String(cur.get("s", ""))
		if s == "active" or s == "ready":
			continue
		if s == "done" and not bool(q.get("repeat", false)):
			continue
		out.append(id)
	return out


static func accept(soul: Soul, id: String) -> bool:
	var q := def(id)
	if q.is_empty() or active(soul).size() >= MAX_ACTIVE:
		return false
	if not available(soul, String(q["board"])).has(id):
		return false
	var st := state(soul)
	var cur: Dictionary = st.get(id, {})
	st[id] = {"s": "active", "n": 0, "t": int(cur.get("t", 0))}
	# a boss already beaten counts at once
	if String(q["kind"]) == "boss" and bool(soul.flags.get("beat_" + String(q["target"]), false)):
		st[id]["n"] = 1
		st[id]["s"] = "ready"
	return true


## Something happened. Returns the ids that just became ready to claim.
static func event(soul: Soul, kind: String, target: String = "any", region: String = "") -> Array:
	var done: Array = []
	var st := state(soul)
	for id: String in active(soul):
		var q := def(id)
		if q.is_empty() or String(q["kind"]) != kind:
			continue
		var want := String(q["target"])
		var hit := want == "any" or want == target
		if want.begins_with("any@"):
			hit = region == want.substr(4)
		if not hit:
			continue
		var cur: Dictionary = st[id]
		if String(cur["s"]) != "active":
			continue
		cur["n"] = int(cur["n"]) + 1
		if int(cur["n"]) >= int(q["count"]):
			cur["s"] = "ready"
			done.append(id)
	return done


## Hands a finished quest in. Returns its reward, or {} if it was not ready.
static func claim(soul: Soul, id: String) -> Dictionary:
	if not is_ready(soul, id):
		return {}
	var q := def(id)
	var st := state(soul)
	var cur: Dictionary = st[id]
	cur["s"] = "done"
	cur["n"] = 0
	cur["t"] = int(cur.get("t", 0)) + 1
	soul.standing += float(q["standing"])
	if String(q["kind"]) == "deliver":
		soul.materials[q["target"]] = int(soul.materials.get(q["target"], 0)) - int(q["count"])
	soul.shards += int(q.get("shards", 0))
	return {"standing": float(q["standing"]), "essence": float(q["essence"]), "shards": int(q.get("shards", 0))}


## A delivery is ready the moment the materials are in hand.
static func check_deliveries(soul: Soul) -> void:
	var st := state(soul)
	for id: String in active(soul):
		var q := def(id)
		if String(q.get("kind", "")) != "deliver":
			continue
		var have := int(soul.materials.get(q["target"], 0))
		var cur: Dictionary = st[id]
		cur["n"] = mini(have, int(q["count"]))
		cur["s"] = "ready" if have >= int(q["count"]) else "active"


static func is_npc(board: String) -> bool:
	return bool((BOARDS.get(board, {}) as Dictionary).get("npc", false))


static func prologue_done(soul: Soul) -> bool:
	for id: String in ["p_strays", "p_keepsakes", "p_king"]:
		if times_done(soul, id) < 1:
			return false
	return true


static func trial_boss(soul: Soul) -> String:
	if soul.primary == "" or soul.grade <= 0:
		return ""
	return String((TRIALS[soul.primary] as Dictionary).get(soul.grade, ""))


static func standing_need(soul: Soul) -> float:
	return float(STANDING_NEED.get(soul.grade, 99999))


static func can_promote(soul: Soul) -> bool:
	if not soul.written() or soul.grade <= 0:
		return false
	var boss := trial_boss(soul)
	return soul.standing >= standing_need(soul) and bool(soul.flags.get("beat_" + boss, false)) and Forge.gear_ok(soul)


## What still stands between a soul and its next grade, in words.
static func promotion_gap(soul: Soul) -> String:
	if not soul.written():
		return "Awaken first."
	if soul.grade <= 0:
		return "There is no grade above yours."
	var parts: Array = []
	if soul.standing < standing_need(soul):
		parts.append("%d more standing" % int(ceil(standing_need(soul) - soul.standing)))
	var boss := trial_boss(soul)
	if not bool(soul.flags.get("beat_" + boss, false)):
		parts.append("defeat %s (%s)" % [String(BOSS_NAMES[boss]), String(BOSS_WHERE[boss])])
	var gg := Forge.gear_gap(soul)
	if gg != "":
		parts.append(gg)
	if parts.is_empty():
		return "Ready for promotion."
	return "Needs: " + ", ".join(parts) + "."


## Returns the new grade, or -1.
static func promote(soul: Soul) -> int:
	if not can_promote(soul):
		return -1
	soul.standing -= standing_need(soul)
	soul.grade -= 1
	soul.marks += 3
	return soul.grade


static func title(soul: Soul) -> String:
	if not soul.written():
		return "Unwrit"
	var base := String((TITLES[soul.primary] as Dictionary)[clampi(soul.grade, 0, 5)])
	if soul.secondary != "":
		return "%s %s" % [soul.form_name(), base]
	return base


static func level_cap(soul: Soul) -> int:
	if not soul.written():
		return TRAINING_CAP if String(soul.flags.get("chapter", "prologue")) == "training" else PROLOGUE_CAP
	return int(LEVEL_CAP.get(clampi(soul.grade, 0, 5), 999))


static func line(soul: Soul, id: String) -> String:
	var q := def(id)
	if q.is_empty():
		return ""
	var where := "the board"
	if is_npc(String(q["board"])):
		where = String(BOARDS[q["board"]]["title"])
	var n := progress(soul, id)
	if String(q["kind"]) == "deliver":
		n = mini(int(soul.materials.get(q["target"], 0)), int(q["count"]))
	var tail := ("  READY: back to %s" % where) if is_ready(soul, id) else "  %d / %d" % [n, int(q["count"])]
	if String(q["kind"]) == "escort" and not is_ready(soul, id):
		tail = "  find them"
	return String(q["title"]) + tail

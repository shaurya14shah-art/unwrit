class_name WorldPlay
extends Node
## The small things a realm is full of, so it is more than a road between
## fights. One per open realm, made on its first frame:
##   folk       souls who linger and talk; some hand out a daily gift, mark
##              a chest or an orb for you, or teach at the dummy
##   breakables crates, barrels, urns, bone heaps: hit them for shards and
##              now and then a material
##   chests     wood, silver and gold; E to open, once a day; some bite back
##   orbs       spirit orbs to gather, a few up high; all of a realm's pays
##   stones     challenge stones: slay, rush or parry against the clock for
##              bronze, silver or gold
##   dummy      a training dummy that shows your damage a second
## Plus kill streaks and badges (core/badges.gd).

const REALMS: Array = ["town", "citadel", "ashfall", "reach", "undermark", "stacks"]
const ORB_COUNT: Dictionary = {"town": 30, "citadel": 24, "ashfall": 24, "reach": 24, "undermark": 24, "stacks": 24}
const BREAKABLES: int = 28
const CHESTS: int = 5
const STONES: Dictionary = {"town": ["rush", "slay"], "citadel": ["parry", "slay"], "ashfall": ["slay", "rush"], "reach": ["rush", "parry"], "undermark": ["slay", "parry"], "stacks": ["rush", "parry"]}
const CHALLENGE: Dictionary = {
	"slay": {"title": "Slay", "len": 60.0, "need": 6, "line": "Kill %d before the time runs out."},
	"rush": {"title": "Orb Rush", "len": 45.0, "need": 10, "line": "Gather %d gold orbs before the time runs out."},
	"parry": {"title": "Parry Drill", "len": 60.0, "need": 4, "line": "Parry %d blows before the time runs out."},
}
const MEDALS: Array = ["Bronze", "Silver", "Gold"]
const MEDAL_COLORS: Array = [Color(0.8, 0.52, 0.3), Color(0.82, 0.85, 0.9), Color(1.0, 0.82, 0.35)]
const STREAK_WORDS: Array = ["", "", "DOUBLE", "TRIPLE", "QUAD", "RAMPAGE"]
const STREAK_GAP: float = 3.0
const HEAVY_HITTER_DPS: float = 120.0

## Who lingers where: [name, what they do, kind, lines]. Kinds:
## talk, gift (once a day), seer (marks a chest), tracker (marks an orb),
## trainer (stands by the dummy).
const FOLK: Dictionary = {
	"town": [
		["Old Benno", "sweeps a street nobody walks", "gift", ["Mind the kerb. Not that it minds you.", "I swept this street for forty years. Death is no reason to stop.", "Here. Somebody dropped it. Somebody always does."]],
		["Pip", "counts the lights", "tracker", ["There are lights all over town. Little ones. Nobody else can see them.", "I know where one is. Want to know?", "Grown-ups never look up."]],
		["Madame Iri", "reads chains", "seer", ["Your chain is short. Mine is shorter.", "I see a box with a lock. I see it near.", "The living keep treasure. The dead keep better."]],
		["Hollis", "still on his round", "talk", ["Parcel for number nine. There is no number nine any more.", "If you see a red door, tell it I tried.", "Every road in this town ends at the river or the gate."]],
		["Sister Agathe", "keeps a candle lit", "gift", ["Sit, if you like. No? Then take this with you.", "The candle does not need me. I need the candle.", "Be kind to the ones who wander. You were one."]],
		["Corporal Wynn", "guards the dummy", "trainer", ["Hit it. Harder. It will not complain.", "Watch the number over its head. That is your worth a second.", "A blade you never practise with is just a weight."]],
		["Lena Vos", "waits at the bus stop", "talk", ["The 12 is late. It has been late for six years.", "I keep my ticket. In case.", "Do you think it stops for us?"]],
		["The Busker", "plays to nobody", "talk", ["Request? I only know the one.", "Coins? No. Listening will do.", "The hounds like the slow songs. Strange, that."]],
		["Tamsin", "counts the cars", "talk", ["Four hundred and twelve red cars. Two hundred blue.", "They drive right through me. I let them.", "When the fog comes I lose count."]],
		["Ferro", "fished the river", "talk", ["The river took me in the spring. It was a good spring.", "Something big lives at the weir. It used to be a dog.", "Rain makes the fish brave. And the dead."]],
	],
	"citadel": [
		["Recruit Ames", "on first watch", "talk", ["Officer Hana says I hold my blade like a broom.", "Have you fought the Gate? Is it true it speaks?", "I came here to stop being afraid. It is going slowly."]],
		["Quartermaster Dole", "keeps the stores", "gift", ["Sign here. No, there. Take it and go.", "Everything is counted. You are counted.", "Bring it back broken and I will know."]],
		["Instructor Varga", "runs the yard", "trainer", ["Strike the dummy until your arms know it.", "Damage is a number. Form is a habit.", "Hana thinks I am hard on recruits. Hana was one."]],
		["Sentry Bell", "watches the wall", "talk", ["Nothing came over the wall today. Nothing ever does. Until it does.", "In a storm you cannot see the far tower.", "The night shift sees things. They stop talking about it."]],
		["Archivist Lune", "keeps the ledger", "seer", ["Every chest in the Citadel is in my ledger. Most are lost from it.", "There is one I have not crossed off. I can show you.", "Paper outlasts us. That is the point of it."]],
		["Runner Tess", "carries messages", "tracker", ["I run the walls every morning. I see the lights.", "There is one near. Follow me. Well, follow the mark.", "Fast is not the same as early."]],
		["Recruit Oyelaran", "polishes a blade", "talk", ["My blade has no name yet. I talk to it anyway.", "Do they get easier? The great ones?", "I heard you can hear the steel if you sit at a cairn."]],
	],
	"ashfall": [
		["Hungry Tobin", "is always hungry", "talk", ["Do not stand so close. I am trying very hard.", "I ate a stone once. It did not help.", "The big ones march at night. Stay off their road."]],
		["Mask-Wright Seo", "carves masks", "gift", ["Every mask fits someone. This shard does not fit me.", "Take it. Bone is cheap out here.", "A cracked mask is a story. A whole one is a lie."]],
		["The Counting One", "counts the lights", "tracker", ["Seventeen. Eighteen. You made me lose count.", "There is a light that way. I counted it twice.", "Lights do not run. Lights wait."]],
		["Blind Ruu", "smells for treasure", "seer", ["I cannot see. I can smell old wood and older gold.", "There. Do you smell it? No. You will.", "The sand hides things. It is greedy too."]],
		["Packleader Orm", "teaches the pack", "trainer", ["Bite the post. Count what it costs it.", "A hungry fighter is a fast one. A full one hits harder.", "The dummy does not bleed. Practise on it anyway."]],
		["Quiet Hesk", "watches the dunes", "talk", ["...", "The wind talks enough for both of us.", "Storms bring the red sky. Then everyone is hungry."]],
	],
	"reach": [
		["Lampkeeper Ansel", "tends a lamp", "gift", ["Oil for the lamp, a little for you.", "We keep the lake frozen by keeping it lit.", "Take this. Light is better shared."]],
		["Sela", "fights for the Reach", "trainer", ["Odile keeps the lamps. I keep the line. Hit the dummy.", "A bow is a promise you keep at a distance.", "Watch your number. Then watch it climb."]],
		["Fisher Ilo", "fishes through the ice", "talk", ["Nothing bites. I keep trying. That is fishing.", "The Drowned Hound came from a lake like this one.", "On clear nights the ice sings."]],
		["Star-Reader Wen", "reads the sky", "seer", ["The stars point at something buried. That way.", "Silver wants to be found. Gold wants to be earned.", "The sky here is always nearly night."]],
		["Glimmer", "is a small light", "tracker", ["I am a light! There are more of me!", "My sister is over there. Go and get her!", "Will you collect me too? No? Good."]],
		["Nurse Corra", "binds wounds", "talk", ["You are hurt. You are always hurt. Everyone is.", "Rest at the cairn. Rest is not weakness.", "The archers come back with frost in their hair."]],
	],
	"stacks": [
		["Archivist Pell-Ro", "files what is kept", "seer", ["Everything here is filed. Some of it is filed under 'lost'.", "There is a box in my index nobody has opened today. Here.", "Do not reshelve anything. You will get it wrong."]],
		["Dusty", "a child who reads", "tracker", ["I read every book on this shelf. Twice.", "There are lights between the shelves. I count them when I am bored.", "One is just there. Go on."]],
		["Sister Vell", "mends torn pages", "gift", ["Hold still. You have a tear. There.", "Take this. Paper is cheap, ink is not.", "What is written down cannot be lost. Only misplaced."]],
		["Binder Orrin", "drills the new chains", "trainer", ["A chain is a whip that remembers. Hit the post.", "Watch your number climb. Then make it climb faster.", "Wren made me what I am. Wren also made me practise."]],
		["The Bookworm", "will not stop reading", "talk", ["Shh.", "This one is about a man who never died. It is very long.", "The deep shelves have books that read back."]],
		["Hollow Tam", "guards the stair", "talk", ["Up is the shop. Down is everything else.", "Binders come down tired and go up heavier.", "If a shelf moves on its own, walk the other way."]],
	],
	"undermark": [
		["Chained Marrow", "pulls at his chain", "talk", ["The chain is not heavy. It is long.", "Everyone down here was somebody. Most forget who.", "Do not let them hook you. Hooked souls stay."]],
		["The Ferryman's Daughter", "knows the deep places", "seer", ["My father carried the dead. I carry secrets.", "There is a box down here no one has opened. Go on.", "Gold is still gold, even here."]],
		["Fitch", "a brass imp", "tracker", ["Lights! Lights in the pit! Fitch shows you, yes?", "One that way. Fitch never lies. Fitch often lies.", "Bring Fitch a light? No? Fitch is sad."]],
		["Warden Sorrel", "keeps the yard", "trainer", ["Even here we train. Especially here.", "Hit the post. The post forgives you.", "The great ones below do not forgive."]],
		["Penitent Gale", "pays an old debt", "gift", ["I owe so much. I give a little. Take it.", "Every shard I give is one I did not steal.", "Go carefully. The fire listens."]],
	],
}

## Lines anyone says when the world gives them something to say.
const SITUATION: Dictionary = {
	"night": ["It is dark. The dead walk more at night.", "Night pays better. Night also bites."],
	"rain": ["Rain. It goes straight through me and still I feel cold.", "The ground shines when it rains. Watch your footing."],
	"fog": ["Fog. They cannot see you either. Use it.", "In fog the hollows walk right past you."],
	"storm": ["Stay out of the pale rings! The lightning picks its spot.", "Lure them under it. The sky is on nobody's side."],
	"snow": ["Snow. Everything is quiet in the snow.", "Winter is the only season the Wastes and the town agree on."],
	"unwritten": ["You are new. You still have the look.", "Your chain is still bright. Do not lose it."],
}

const BREAK_KIND: Dictionary = {"town": ["crate", "barrel"], "citadel": ["crate", "urn"], "ashfall": ["bones", "urn"], "reach": ["urn", "crate"], "undermark": ["bones", "barrel"], "stacks": ["crate", "urn"]}
const BREAK_COLORS: Dictionary = {"crate": Color(0.55, 0.38, 0.22), "barrel": Color(0.45, 0.3, 0.18), "urn": Color(0.62, 0.5, 0.42), "bones": Color(0.86, 0.84, 0.78)}
const CHEST_TIERS: Array = ["wood", "silver", "gold"]
const CHEST_COLORS: Dictionary = {"wood": Color(0.5, 0.33, 0.18), "silver": Color(0.72, 0.75, 0.8), "gold": Color(0.95, 0.75, 0.3)}
const CHEST_SHARDS: Dictionary = {"wood": 6.0, "silver": 12.0, "gold": 25.0}
const MIMIC_CHANCE: float = 0.12

var region: Region
var rid: String = ""
var folk: Array = []
var breakables: Array = []
var chests: Array = []
var orbs: Array = []
var stones: Array = []
var dummy: Dictionary = {}
var ch: Dictionary = {}          # the challenge under way
var hint: Dictionary = {}        # a spot a folk marked: {"at", "kind", "t"}
var streak: int = 0
var best_streak: int = 0
var _last_kill: float = -99.0
var _badge_t: float = 0.0
var _folk_t: float = 0.0
var _orb_chain: int = 0
var _orb_chain_t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _now: float = 0.0
var _tip_t: float = 1.0

## A line the first time a soul meets each thing, then never again.
const TIPS: Dictionary = {
	"folk": "Souls linger here. [E] to talk; a floating ! means they have something for you today.",
	"crate": "Crates, barrels and urns break: hit them or press [E] for shards.",
	"chest": "A chest. [E] to open it. It fills again tomorrow, and some bite.",
	"orb": "A spirit orb. Walk through it. Every one in a realm pays a prize.",
	"stone": "A challenge stone. [E] to start it: beat the clock for bronze, silver or gold.",
	"dummy": "A training dummy. Hit it to see your damage a second.",
	"night": "Night: more of the dead walk, and they pay a quarter more.",
	"rain": "Rain: enemies see you from a little less far.",
	"fog": "Fog: enemies notice you from only two-thirds as far. Slip past or strike first.",
	"storm": "Thunderstorm: a pale ring shows where lightning will fall. Stay out, or lure them in.",
	"snow": "Snow: it lies deeper while it falls. Enemies see a little less far.",
}


## Off in the play-through tests (their old checks count shards exactly);
## its own section turns it on.
static var enabled: bool = true


static func wants(region_id: String) -> bool:
	return enabled and REALMS.has(region_id)


func _solid(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	add_child(body)
	body.global_position = pos + Vector3(0, height * 0.5, 0)


func _solid_box(center: Vector3, size: Vector3, yaw: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	add_child(body)
	body.global_position = center
	body.rotation.y = yaw
	return body


func setup(r: Region) -> void:
	region = r
	rid = r.region_id
	_rng.seed = hash([rid, "play"])
	var visited: Dictionary = r.soul.flags.get("visited", {})
	visited[rid] = true
	r.soul.flags["visited"] = visited
	var hub := r.wake_point()
	var place_rng := Rng.make([rid, "play", "spots"])
	_build_folk(place_rng, hub)
	_build_dummy(place_rng, hub)
	_build_stones(place_rng, hub)
	_build_chests(place_rng, hub)
	_build_breakables(place_rng, hub)
	_build_orbs(place_rng, hub)
	apply_quality()


## Small props fade out past the quality's view distance.
func apply_quality() -> void:
	var far := Quality.prop_range()
	for list: Array in [breakables, chests, orbs]:
		for it: Variant in list:
			var n: Node3D = (it as Dictionary)["node"]
			if is_instance_valid(n):
				for c in n.find_children("*", "GeometryInstance3D", true, false):
					(c as GeometryInstance3D).visibility_range_end = far


# --- finding spots ---------------------------------------------------------

## True if nothing built stands at (x, z): the ray from above lands on the
## ground itself, at the centre and a little way round it.
func open_at(x: float, z: float, r: float = 0.8) -> bool:
	var space := region.get_world_3d().direct_space_state
	for o: Vector2 in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		var g := region.height_at(x + o.x, z + o.y)
		var q := PhysicsRayQueryParameters3D.create(Vector3(x + o.x, g + 40.0, z + o.y), Vector3(x + o.x, g - 2.0, z + o.y), 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and float((hit["position"] as Vector3).y) > g + 0.5:
			return false
	return true


func _spot(r: RandomNumberGenerator, from: Vector3, near: float, far: float, margin: float = 4.0, size: float = 0.8) -> Vector3:
	for i in range(60):
		var a := r.randf() * TAU
		var d := r.randf_range(near, far)
		var x := from.x + cos(a) * d
		var z := from.z + sin(a) * d
		if rid == "town":
			# out on the pavement, at the edge of a street
			var bx := _nearest_road(x)
			var bz := _nearest_road(z)
			var side := 8.5 if r.randf() < 0.5 else -8.5
			if absf(bx - x) < absf(bz - z):
				x = bx + side
			else:
				z = bz + side
		if absf(x) > region.bounds - 14.0 or absf(z) > region.bounds - 14.0:
			continue
		if not region.dress_clear(x, z, margin) or _near_people(x, z) or not open_at(x, z, size) or _taken(x, z, 2.5):
			continue
		return Vector3(x, region.height_at(x, z), z)
	return Vector3.INF


## Keeps clear of quest givers and the realm's own speakers, so E never
## lands on the wrong person.
func _near_people(x: float, z: float) -> bool:
	for lst: Array in [region.giver_list(), region.talker_list()]:
		for e: Variant in lst:
			if Vector2(float(e[0]) - x, float(e[1]) - z).length() < 7.0:
				return true
	return false


func _nearest_road(v: float) -> float:
	var best := 0.0
	for rv: float in [-160.0, -90.0, 0.0, 90.0, 160.0]:
		if absf(rv - v) < absf(best - v):
			best = rv
	return best


func _taken(x: float, z: float, r: float) -> bool:
	for list: Array in [folk, chests, stones, breakables]:
		for it: Variant in list:
			var n: Node3D = (it as Dictionary)["node"]
			if is_instance_valid(n) and Vector2(n.position.x - x, n.position.z - z).length() < r:
				return true
	if not dummy.is_empty() and Vector2((dummy["node"] as Node3D).position.x - x, (dummy["node"] as Node3D).position.z - z).length() < r:
		return true
	return false


# --- folk ------------------------------------------------------------------

func _build_folk(r: RandomNumberGenerator, hub: Vector3) -> void:
	var list: Array = FOLK.get(rid, [])
	for i in range(list.size()):
		var d: Array = list[i]
		var near := 8.0 if i < 4 else 20.0
		var far := 40.0 if i < 4 else 110.0
		if String(d[2]) == "trainer":
			continue   # trainers stand by the dummy, placed with it
		var at := _spot(r, hub, near, far, 4.0, 0.6)
		if at == Vector3.INF:
			continue
		_add_folk(i, d, at, r)


func _add_folk(i: int, d: Array, at: Vector3, r: RandomNumberGenerator) -> void:
	var rig := BlockRig.new()
	add_child(rig)
	rig.build(_folk_look(i, r))
	rig.position = at
	rig.rotation.y = r.randf() * TAU
	rig.play("idle", 0.0)
	region._name_plate(rig, String(d[0]), String(d[1]))
	var mark := Label3D.new()
	mark.font = Ink.title_font()
	mark.font_size = 64
	mark.pixel_size = 0.005
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.outline_size = 12
	mark.modulate = Color(0.75, 0.92, 1.0)
	mark.position = Vector3(0, rig.height + 1.2, 0)
	mark.visibility_range_end = 40.0
	rig.add_child(mark)
	folk.append({"node": rig, "home": at, "def": d, "id": "%s_%d" % [rid, i], "talks": 0, "mark": mark,
		"wander": i % 2 == 1, "goal": at, "wait": r.randf_range(2.0, 8.0), "cower": false})


func _folk_look(i: int, r: RandomNumberGenerator) -> Dictionary:
	var hair := int(r.randi() % 5)
	var look := {"hair": hair, "hair_color": [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.82, 0.74, 0.5), Color(0.62, 0.62, 0.64)][r.randi() % 4],
		"hair_seed": 400 + i * 7 + hash(rid) % 50, "face": int(r.randi() % 4), "scale": r.randf_range(0.82, 1.02)}
	match rid:
		"town":
			var clothes: Array = [Color(0.36, 0.42, 0.55), Color(0.5, 0.36, 0.3), Color(0.32, 0.4, 0.32), Color(0.55, 0.5, 0.42), Color(0.42, 0.3, 0.42)]
			look["cloth"] = clothes[r.randi() % clothes.size()]
			look["trim"] = (look["cloth"] as Color).darkened(0.35)
			look["coat"] = int(r.randi() % 2)
			look["tether"] = 3
		"citadel":
			look["cloth"] = Color(0.07, 0.07, 0.09)
			look["trim"] = Color(0.9, 0.9, 0.92)
			look["coat"] = 2
			look["sash"] = int(r.randi() % 3)
		"ashfall":
			look["cloth"] = Color(0.86, 0.85, 0.82)
			look["trim"] = Color(0.18, 0.18, 0.2)
			look["coat"] = 1
			look["mask"] = int(r.randi() % 3)
			look["mask_seed"] = 300 + i
			look["hole"] = true
		"reach":
			look["cloth"] = Color(0.9, 0.92, 0.97)
			look["trim"] = Color(0.6, 0.5, 0.3)
			look["coat"] = 2
			look["halo"] = i % 3 == 0
			look["accent"] = Color(1.0, 0.85, 0.5)
		"undermark":
			look["cloth"] = Color(0.3, 0.12, 0.1)
			look["trim"] = Color(0.12, 0.1, 0.1)
			look["coat"] = 1
			look["tether"] = 5
	return look


func _nearest_folk(within: float) -> int:
	var best := -1
	var bd := within
	for i in range(folk.size()):
		var n: Node3D = folk[i]["node"]
		var d := n.global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


func talk(i: int) -> void:
	var f: Dictionary = folk[i]
	var d: Array = f["def"]
	var s := region.soul
	var lines: Array = d[3]
	var n := int(f["talks"])
	var line := String(lines[n % lines.size()])
	var sit := _situation()
	if n % 3 == 2 and sit != "":
		var pool: Array = SITUATION[sit]
		line = String(pool[(n / 3) % pool.size()])
	f["talks"] = n + 1
	var met: Dictionary = s.flags.get("folk_met", {})
	met[String(f["id"])] = true
	s.flags["folk_met"] = met
	var rig: BlockRig = f["node"]
	var to := region.player.global_position - rig.global_position
	rig.rotation.y = atan2(-to.x, -to.z)
	region.player.face_now(-to)
	Sfx.play("ui_open", -6.0)
	match String(d[2]):
		"gift":
			var key := "gift_" + String(f["id"])
			var day := int(s.flags.get("days", 0))
			if int(s.flags.get(key, -1)) < day:
				s.flags[key] = day
				var amount := 6 + 2 * clampi(5 - s.grade, 0, 5) + _rng.randi_range(0, 6)
				s.shards += amount
				line = "%s  (+%d shards; come back tomorrow)" % [String(lines[lines.size() - 1]), amount]
				Sfx.play("quest", -6.0)
				Fx.word(rig.global_position + Vector3(0, 2.2, 0), "+%d" % amount, Color(1.0, 0.82, 0.4), 0.7)
		"seer":
			var ci := _nearest_closed_chest()
			if ci >= 0:
				hint = {"at": (chests[ci]["node"] as Node3D).global_position, "kind": "chest", "t": 120.0}
				line += "  (a chest is marked on your compass)"
			else:
				line = "Every box I can see is open. Come back tomorrow."
		"tracker":
			var oi := _nearest_orb()
			if oi >= 0:
				hint = {"at": (orbs[oi]["node"] as Node3D).global_position, "kind": "orb", "t": 120.0}
				line += "  (%d of %d left here; one is marked)" % [orbs_left(), orbs.size()]
			else:
				line = "You found them all. Every one. I am almost jealous."
	region.say("%s|%s" % [String(d[0]), line], "talk")


func _situation() -> String:
	var w := region.weather
	if w != null and w.kind != "clear":
		return w.kind
	if region.daynight != null and region.daynight.night() > 0.6:
		return "night"
	if not region.soul.written():
		return "unwritten"
	return ""


func _tick_folk(delta: float) -> void:
	var p := region.player.global_position
	var danger: Array = []
	for a: Variant in region.actors:
		if is_instance_valid(a) and a is Enemy and (a as Enemy).alive and (a as Enemy).aggro:
			danger.append((a as Enemy).global_position)
	for f: Variant in folk:
		var fd: Dictionary = f
		var rig: BlockRig = fd["node"]
		if not is_instance_valid(rig):
			continue
		var near_danger := false
		for dp: Variant in danger:
			if (dp as Vector3).distance_to(rig.global_position) < 12.0:
				near_danger = true
				break
		if near_danger != bool(fd["cower"]):
			fd["cower"] = near_danger
			rig.play("kneel" if near_danger else "idle", 0.2)
		var mark: Label3D = fd["mark"]
		var kind := String((fd["def"] as Array)[2])
		mark.text = "!" if (kind == "gift" and int(region.soul.flags.get("gift_" + String(fd["id"]), -1)) < int(region.soul.flags.get("days", 0))) else ""
		if near_danger:
			continue
		var to_p := p - rig.global_position
		if to_p.length() < 6.0:
			var want := atan2(-to_p.x, -to_p.z)
			rig.rotation.y = lerp_angle(rig.rotation.y, want, minf(1.0, delta * 4.0))
			continue
		if not bool(fd["wander"]):
			continue
		var goal: Vector3 = fd["goal"]
		var flat := Vector3(goal.x - rig.position.x, 0, goal.z - rig.position.z)
		if flat.length() > 0.3:
			var step := flat.normalized() * minf(flat.length(), 1.1 * delta)
			rig.position += step
			rig.position.y = region.height_at(rig.position.x, rig.position.z)
			rig.rotation.y = lerp_angle(rig.rotation.y, atan2(-flat.x, -flat.z), minf(1.0, delta * 5.0))
			rig.play("run", 0.25, 0.38)
		else:
			rig.play("idle", 0.3)
			fd["wait"] = float(fd["wait"]) - delta
			if float(fd["wait"]) <= 0.0:
				fd["wait"] = _rng.randf_range(4.0, 10.0)
				var home: Vector3 = fd["home"]
				var a := _rng.randf() * TAU
				var g := home + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(1.0, 3.5)
				if open_at(g.x, g.z, 0.4):
					fd["goal"] = g


# --- the training dummy ----------------------------------------------------

func _build_dummy(r: RandomNumberGenerator, hub: Vector3) -> void:
	var at := _spot(r, hub, 9.0, 26.0, 5.0, 1.2)
	if at == Vector3.INF:
		return
	var node := Node3D.new()
	add_child(node)
	node.position = at
	var straw := ForgeMesh.mat(Color(0.78, 0.66, 0.38), 0.95)
	var wood := ForgeMesh.mat(Color(0.36, 0.25, 0.15), 0.9)
	region._block(node, Vector3(0.22, 2.2, 0.22), Vector3(0, 1.1, 0), wood)
	region._block(node, Vector3(1.5, 0.18, 0.18), Vector3(0, 1.55, 0), wood)
	var body := Node3D.new()
	body.name = "body"
	node.add_child(body)
	region._block(body, Vector3(0.75, 0.95, 0.5), Vector3(0, 1.45, 0), straw)
	region._block(body, Vector3(0.55, 0.55, 0.55), Vector3(0, 2.25, 0), straw)
	region._block(body, Vector3(0.6, 0.08, 0.52), Vector3(0, 1.2, 0), ForgeMesh.mat(Color(0.55, 0.15, 0.12), 0.9))
	_solid(at, 0.45, 2.4)
	var label := Label3D.new()
	label.font = Ink.figures_font()
	label.font_size = 56
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 12
	label.outline_modulate = Color(0.04, 0.035, 0.03, 0.9)
	label.modulate = Ink.PAPER
	label.position = Vector3(0, 3.1, 0)
	label.text = "TRAINING DUMMY"
	label.visibility_range_end = 30.0
	node.add_child(label)
	dummy = {"node": node, "body": body, "label": label, "hits": [], "wob": 0.0, "wob_v": 0.0, "show": 0.0, "best": 0.0}
	# the realm's trainer stands beside it
	var list: Array = FOLK.get(rid, [])
	for i in range(list.size()):
		if String((list[i] as Array)[2]) == "trainer":
			var t_at := at + Vector3(2.4, 0, 1.2)
			t_at.y = region.height_at(t_at.x, t_at.z)
			_add_folk(i, list[i], t_at, r)
			(folk[folk.size() - 1]["node"] as Node3D).rotation.y = atan2(-(at.x - t_at.x), -(at.z - t_at.z))


func dummy_hit(dmg: float) -> void:
	if dummy.is_empty():
		return
	var hits: Array = dummy["hits"]
	hits.append([_now, dmg])
	while not hits.is_empty() and _now - float((hits[0] as Array)[0]) > 5.0:
		hits.pop_front()
	dummy["wob_v"] = float(dummy["wob_v"]) + 3.0 * (1.0 if _rng.randf() < 0.5 else -1.0)
	dummy["show"] = 6.0
	var node: Node3D = dummy["node"]
	Fx.word(node.global_position + Vector3(_rng.randf_range(-0.4, 0.4), 2.6, 0), "%d" % int(round(dmg)), Ink.PAPER, 0.8)
	Fx.puff(node.global_position + Vector3(0, 1.6, 0), Color(0.85, 0.75, 0.45, 0.6), 4, 0.4)
	region.soul.flags["dummy_hits"] = int(region.soul.flags.get("dummy_hits", 0)) + 1
	var dps := dummy_dps()
	dummy["best"] = maxf(float(dummy["best"]), dps)
	if dps >= HEAVY_HITTER_DPS and hits.size() >= 6:
		give_badge("heavy_hitter")


## Damage a second over the last five seconds of blows.
func dummy_dps() -> float:
	if dummy.is_empty():
		return 0.0
	var hits: Array = dummy["hits"]
	if hits.is_empty():
		return 0.0
	var total := 0.0
	for h: Variant in hits:
		total += float((h as Array)[1])
	var span := maxf(1.0, _now - float((hits[0] as Array)[0]))
	return total / span


func _tick_dummy(delta: float) -> void:
	if dummy.is_empty():
		return
	var body: Node3D = dummy["body"]
	var w := float(dummy["wob"])
	var v := float(dummy["wob_v"])
	v += -w * 60.0 * delta - v * 6.0 * delta
	w += v * delta
	dummy["wob"] = w
	dummy["wob_v"] = v
	body.rotation.z = clampf(w * 0.25, -0.5, 0.5)
	dummy["show"] = float(dummy["show"]) - delta
	var label: Label3D = dummy["label"]
	if float(dummy["show"]) > 0.0:
		label.text = "%d DPS\nBEST %d" % [int(round(dummy_dps())), int(round(float(dummy["best"])))]
		label.modulate = Ink.BRASS if dummy_dps() >= HEAVY_HITTER_DPS else Ink.PAPER
	else:
		label.text = "TRAINING DUMMY"
		label.modulate = Ink.PAPER
		(dummy["hits"] as Array).clear()


# --- breakables ------------------------------------------------------------

func _build_breakables(r: RandomNumberGenerator, hub: Vector3) -> void:
	var kinds: Array = BREAK_KIND.get(rid, ["crate"])
	var made := 0
	var guard := 0
	while made < BREAKABLES and guard < 40:
		guard += 1
		# they come in little heaps of two to four
		var centre := _spot(r, hub, 12.0, region.bounds * 0.75, 4.0, 1.2)
		if centre == Vector3.INF:
			continue
		var heap := r.randi_range(2, 4)
		for k in range(heap):
			var a := r.randf() * TAU
			var at := centre + Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else r.randf_range(1.1, 1.7))
			if k > 0 and (not open_at(at.x, at.z, 0.5) or _taken(at.x, at.z, 1.0)):
				continue
			at.y = region.height_at(at.x, at.z)
			_add_breakable(String(kinds[(made + k) % kinds.size()]), at, r.randf() * TAU)
			made += 1


func _add_breakable(kind: String, at: Vector3, yaw: float) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	var col: Color = BREAK_COLORS[kind]
	var m := ForgeMesh.mat(col, 0.9)
	var dark := ForgeMesh.mat(col.darkened(0.35), 0.9)
	var size := Vector3(0.9, 0.9, 0.9)
	match kind:
		"crate":
			region._block(node, size, Vector3(0, 0.45, 0), m)
			for sx: float in [-0.46, 0.46]:
				region._block(node, Vector3(0.04, 0.9, 0.12), Vector3(sx, 0.45, 0), dark)
			region._block(node, Vector3(0.94, 0.12, 0.94), Vector3(0, 0.84, 0), dark)
		"barrel":
			size = Vector3(0.8, 1.1, 0.8)
			region._block(node, size, Vector3(0, 0.55, 0), m)
			for y: float in [0.22, 0.88]:
				region._block(node, Vector3(0.86, 0.08, 0.86), Vector3(0, y, 0), ForgeMesh.mat(Color(0.25, 0.25, 0.27), 0.5, 0.6))
		"urn":
			size = Vector3(0.7, 1.0, 0.7)
			region._block(node, Vector3(0.7, 0.7, 0.7), Vector3(0, 0.4, 0), m)
			region._block(node, Vector3(0.42, 0.3, 0.42), Vector3(0, 0.88, 0), dark)
		"bones":
			size = Vector3(1.0, 0.7, 1.0)
			region._block(node, Vector3(1.0, 0.35, 0.8), Vector3(0, 0.18, 0), m)
			region._block(node, Vector3(0.5, 0.45, 0.5), Vector3(0.1, 0.55, 0), m, Vector3(0, 20, 12))
			region._block(node, Vector3(0.9, 0.12, 0.12), Vector3(0, 0.42, 0.2), dark, Vector3(0, -30, 0))
	var body := _solid_box(at + Vector3(0, size.y * 0.5, 0), size, yaw)
	breakables.append({"node": node, "body": body, "kind": kind, "alive": true})


func break_at(i: int) -> void:
	var b: Dictionary = breakables[i]
	if not bool(b["alive"]):
		return
	b["alive"] = false
	var node: Node3D = b["node"]
	var col: Color = BREAK_COLORS[String(b["kind"])]
	Fx.puff(node.global_position + Vector3(0, 0.5, 0), Color(col.r, col.g, col.b, 0.8), 14, 0.7)
	Fx.sparks(node.global_position + Vector3(0, 0.5, 0), col, 10, 6.0)
	Sfx.play("break", -6.0, 1.3)
	if is_instance_valid(b["body"]):
		(b["body"] as Node).queue_free()
	node.queue_free()
	var s := region.soul
	s.flags["crates"] = int(s.flags.get("crates", 0)) + 1
	var roll := _rng.randf()
	if roll < 0.55:
		var sh := _rng.randi_range(1, 3) + int(s.level / 8)
		s.shards += sh
		Fx.word(node.global_position + Vector3(0, 1.4, 0), "+%d" % sh, Color(1.0, 0.82, 0.4), 0.6)
	elif roll < 0.75:
		var kinds := _realm_kinds()
		if not kinds.is_empty():
			var drops := Items.roll_drops(String(kinds[_rng.randi() % kinds.size()]), s.level, true, _rng.randi())
			var mats: Dictionary = drops["materials"]
			if not mats.is_empty():
				var mk: Variant = mats.keys()[0]
				region._spawn_loot(node.global_position, {"materials": {mk: 1}})
	elif roll < 0.8 and region.player != null:
		region.player.heal(region.player.max_hp * 0.1)
		Fx.word(node.global_position + Vector3(0, 1.4, 0), "+HP", Color(0.5, 0.95, 0.6), 0.6)


func _nearest_breakable(within: float) -> int:
	var best := -1
	var bd := within
	for i in range(breakables.size()):
		if not bool(breakables[i]["alive"]):
			continue
		var d := (breakables[i]["node"] as Node3D).global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


func _tips() -> void:
	var s := region.soul
	if region.player.scripted or region.in_combat():
		return
	var near := ""
	if _nearest_folk(8.0) >= 0:
		near = "folk"
	elif _nearest_breakable(8.0) >= 0:
		near = "crate"
	elif _nearest_chest(8.0) >= 0:
		near = "chest"
	elif _nearest_stone(8.0) >= 0:
		near = "stone"
	elif not dummy.is_empty() and (dummy["node"] as Node3D).global_position.distance_to(region.player.global_position) < 8.0:
		near = "dummy"
	else:
		var oi := _nearest_orb()
		if oi >= 0 and (orbs[oi]["node"] as Node3D).global_position.distance_to(region.player.global_position) < 8.0:
			near = "orb"
	if near == "" and region.weather != null and region.weather.kind != "clear":
		near = region.weather.kind
	if near == "" and region.daynight != null and region.daynight.night() > 0.6:
		near = "night"
	if near != "" and not bool(s.flags.get("tip_" + near, false)):
		s.flags["tip_" + near] = true
		region.say(String(TIPS[near]), "hint")


## A swing of the player's: anything breakable or the dummy inside its arc.
func on_player_sweep(attacker: Actor, m: Dictionary) -> void:
	var reach := float(m.get("reach", 2.0)) * attacker.reach_scale + 0.6
	var half := deg_to_rad(float(m.get("arc", 90.0))) * 0.5
	var f := attacker.forward()
	for i in range(breakables.size()):
		if bool(breakables[i]["alive"]) and _in_arc(attacker, (breakables[i]["node"] as Node3D).global_position, reach, half, f):
			break_at(i)
	if not dummy.is_empty() and _in_arc(attacker, (dummy["node"] as Node3D).global_position, reach, half, f):
		dummy_hit(float(m.get("dmg", 10.0)) * attacker.damage_factor())


func _in_arc(attacker: Actor, at: Vector3, reach: float, half: float, f: Vector3) -> bool:
	var to := at - attacker.global_position
	if absf(to.y) > 2.6:
		return false
	to.y = 0.0
	var d := to.length()
	if d > reach:
		return false
	return d < 0.6 or half >= PI * 0.99 or f.angle_to(to / d) <= half + 0.35


func _realm_kinds() -> Array:
	var kinds: Array = []
	for sp: Variant in region.spawn_list():
		var k := String((sp as Array)[0])
		if not Bestiary.is_boss(k) and k != "drill" and not kinds.has(k):
			kinds.append(k)
	return kinds


# --- chests ----------------------------------------------------------------

func _build_chests(r: RandomNumberGenerator, hub: Vector3) -> void:
	for i in range(CHESTS):
		var at := _spot(r, hub, 30.0 + 25.0 * float(i), minf(region.bounds * 0.85, 70.0 + 40.0 * float(i)), 5.0, 1.0)
		if at == Vector3.INF:
			continue
		var tier := "gold" if i == CHESTS - 1 else ("silver" if i % 2 == 1 else "wood")
		_add_chest(i, tier, at, r.randf() * TAU)


func _add_chest(i: int, tier: String, at: Vector3, yaw: float) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	var col: Color = CHEST_COLORS[tier]
	var wood := ForgeMesh.mat(Color(0.42, 0.27, 0.15) if tier != "wood" else col, 0.85)
	var band := ForgeMesh.mat(col, 0.35, 0.7 if tier != "wood" else 0.0)
	region._block(node, Vector3(1.2, 0.6, 0.8), Vector3(0, 0.3, 0), wood)
	for sx: float in [-0.45, 0.45]:
		region._block(node, Vector3(0.1, 0.62, 0.84), Vector3(sx, 0.31, 0), band)
	var lid := Node3D.new()
	lid.name = "lid"
	lid.position = Vector3(0, 0.6, 0.4)
	node.add_child(lid)
	region._block(lid, Vector3(1.22, 0.3, 0.82), Vector3(0, 0.15, -0.4), wood)
	for sx: float in [-0.45, 0.45]:
		region._block(lid, Vector3(0.1, 0.32, 0.86), Vector3(sx, 0.15, -0.4), band)
	var lock := region._block(node, Vector3(0.2, 0.24, 0.08), Vector3(0, 0.55, 0.43), ForgeMesh.glow(col, 1.6))
	lock.name = "lock"
	var body := _solid_box(at + Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.8), yaw)
	chests.append({"node": node, "lid": lid, "lock": lock, "body": body, "i": i, "tier": tier})
	_sync_chest(chests.size() - 1)


func chest_open(i: int) -> bool:
	var key := "chest_%s_%d" % [rid, int(chests[i]["i"])]
	return int(region.soul.flags.get(key, -1)) >= int(region.soul.flags.get("days", 0))


func _sync_chest(i: int) -> void:
	var c: Dictionary = chests[i]
	var shut := not chest_open(i)
	(c["lid"] as Node3D).rotation.x = 0.0 if shut else -1.9
	(c["lock"] as Node3D).visible = shut


func _nearest_closed_chest() -> int:
	var best := -1
	var bd := INF
	for i in range(chests.size()):
		if chest_open(i):
			continue
		var d := (chests[i]["node"] as Node3D).global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


func _nearest_chest(within: float) -> int:
	var best := -1
	var bd := within
	for i in range(chests.size()):
		var d := (chests[i]["node"] as Node3D).global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


## Opens a chest: shards, a few materials, sometimes a charm. Silver and
## gold ones are now and then a mimic, which pays twice when it falls.
func open_chest(i: int, allow_mimic: bool = true, force_mimic: bool = false) -> void:
	if chest_open(i):
		return
	var c: Dictionary = chests[i]
	var s := region.soul
	s.flags["chest_%s_%d" % [rid, int(c["i"])]] = int(s.flags.get("days", 0))
	_sync_chest(i)
	var node: Node3D = c["node"]
	var tier := String(c["tier"])
	if hint.get("kind", "") == "chest" and (hint["at"] as Vector3).distance_to(node.global_position) < 1.0:
		hint = {}
	if force_mimic or (allow_mimic and tier != "wood" and _rng.randf() < MIMIC_CHANCE):
		var kinds := _realm_kinds()
		if not kinds.is_empty():
			var e: Enemy = region._spawn(String(kinds[_rng.randi() % kinds.size()]), node.global_position + node.global_transform.basis.z * 1.6, region.level_base + 2)
			e.display_name = "Mimic"
			e.set_meta("mimic", tier)
			e.max_hp *= 1.6
			e.hp = e.max_hp
			e.wake(region.player)
			Fx.word(node.global_position + Vector3(0, 1.6, 0), "MIMIC!", Ink.SEAL, 1.1)
			Sfx.play("roar", -4.0, 1.3)
			region.say("It was not a chest. Kill it and it pays double.", "hint")
			return
	_chest_loot(node.global_position, tier, 1.0)
	s.flags["chests"] = int(s.flags.get("chests", 0)) + 1


func _chest_loot(at: Vector3, tier: String, k: float) -> void:
	var s := region.soul
	var sh := int(round(float(Items.shards_for(maxi(s.level, 1), false, false)) * float(CHEST_SHARDS[tier]) * k))
	s.shards += sh
	Fx.word(at + Vector3(0, 1.6, 0), "+%d" % sh, Color(1.0, 0.82, 0.4), 1.0)
	Fx.sparks(at + Vector3(0, 0.8, 0), CHEST_COLORS[tier], 22, 7.0)
	Fx.pillar(at, CHEST_COLORS[tier], 5.0, 0.4, 0.6)
	Sfx.play("relic", -2.0, 1.1)
	region.say("Shards:%d" % sh, "loot")
	var kinds := _realm_kinds()
	var rolls: int = int({"wood": 1, "silver": 2, "gold": 3}[tier]) * int(k)
	for n in range(rolls):
		if kinds.is_empty():
			break
		var drops := Items.roll_drops(String(kinds[_rng.randi() % kinds.size()]), s.level, true, _rng.randi())
		var mats: Dictionary = drops["materials"]
		var j := 0
		for mk: Variant in mats.keys():
			region._spawn_loot(at + Vector3(cos(float(n * 3 + j)) * 1.4, 0, sin(float(n * 3 + j)) * 1.4), {"materials": {mk: mats[mk]}})
			j += 1
		if tier == "gold" and not (drops["charm"] as Dictionary).is_empty():
			region._spawn_loot(at + Vector3(0, 0, 1.8), {"charm": drops["charm"]})


# --- spirit orbs -----------------------------------------------------------

func _build_orbs(r: RandomNumberGenerator, hub: Vector3) -> void:
	var n := int(ORB_COUNT.get(rid, 20))
	var got: Dictionary = region.soul.flags.get("orbs_" + rid, {})
	for i in range(n):
		var at := _spot(r, hub, 10.0, region.bounds * 0.9, 3.0, 0.5)
		if at == Vector3.INF:
			continue
		var high := i % 4 == 3
		at.y += 3.0 if high else 1.1
		var node := Node3D.new()
		add_child(node)
		node.position = at
		var gem := region._block(node, Vector3(0.32, 0.32, 0.32), Vector3.ZERO, ForgeMesh.glow(Color(0.62, 0.9, 1.0), 2.2), Vector3(45, 0, 35))
		gem.name = "gem"
		node.visible = not got.has(str(i))
		orbs.append({"node": node, "i": i, "high": high, "taken": got.has(str(i))})


func orbs_left() -> int:
	var n := 0
	for o: Variant in orbs:
		if not bool((o as Dictionary)["taken"]):
			n += 1
	return n


func _nearest_orb() -> int:
	var best := -1
	var bd := INF
	for i in range(orbs.size()):
		if bool(orbs[i]["taken"]):
			continue
		var d := (orbs[i]["node"] as Node3D).global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


func take_orb(i: int) -> void:
	var o: Dictionary = orbs[i]
	if bool(o["taken"]):
		return
	o["taken"] = true
	var node: Node3D = o["node"]
	node.visible = false
	var s := region.soul
	var got: Dictionary = s.flags.get("orbs_" + rid, {})
	got[str(int(o["i"]))] = true
	s.flags["orbs_" + rid] = got
	s.flags["orbs"] = int(s.flags.get("orbs", 0)) + 1
	s.shards += 2
	if region.main != null:
		region.main.grant_essence(2.0 + float(s.level))
	# orbs gathered in a quick run ring higher and higher
	_orb_chain = _orb_chain + 1 if _orb_chain_t > 0.0 else 1
	_orb_chain_t = 2.5
	Sfx.play("ui_tick", -2.0, 1.2 + 0.08 * float(mini(_orb_chain, 10)), 0.0)
	Fx.sparks(node.global_position, Color(0.62, 0.9, 1.0), 10, 4.0)
	region.say("Spirit Orb:1", "loot")
	if hint.get("kind", "") == "orb" and (hint["at"] as Vector3).distance_to(node.global_position) < 1.0:
		hint = {}
	if orbs_left() == 0:
		s.shards += 150
		region.say("Every light in %s|+150 shards" % _realm_name(), "level")
		give_badge("lamplighter")
		var all := true
		for r2: String in REALMS:
			var have: Dictionary = s.flags.get("orbs_" + r2, {})
			if have.size() < int(ORB_COUNT.get(r2, 20)) - 2:
				all = false
		if all:
			give_badge("every_light")


func _realm_name() -> String:
	return String({"town": "Calder Town", "citadel": "the Citadel", "ashfall": "the Wastes", "reach": "the Silver Reach", "undermark": "the Undermark", "stacks": "the Stacks"}.get(rid, rid))


func _tick_orbs(delta: float) -> void:
	_orb_chain_t -= delta
	var p := region.player.global_position + Vector3(0, 0.9, 0)
	for i in range(orbs.size()):
		var o: Dictionary = orbs[i]
		if bool(o["taken"]):
			continue
		var node: Node3D = o["node"]
		var gem: Node3D = node.get_node("gem")
		gem.rotation.y += delta * 1.6
		gem.position.y = sin(_now * 2.0 + float(i)) * 0.15
		if node.global_position.distance_to(p) < 1.5:
			take_orb(i)
	for i in range(ch.get("orbs", []).size() - 1, -1, -1):
		var n: Node3D = ch["orbs"][i]
		if not is_instance_valid(n):
			continue
		n.rotation.y += delta * 2.5
		if n.global_position.distance_to(p) < 1.6:
			(ch["orbs"] as Array).remove_at(i)
			Fx.sparks(n.global_position, Color(1.0, 0.82, 0.35), 10, 5.0)
			n.queue_free()
			ch["got"] = int(ch["got"]) + 1
			Sfx.play("ui_tick", -2.0, 1.3 + 0.06 * float(ch["got"]), 0.0)


# --- challenge stones ------------------------------------------------------

func _build_stones(r: RandomNumberGenerator, hub: Vector3) -> void:
	var kinds: Array = STONES.get(rid, [])
	for i in range(kinds.size()):
		var at := _spot(r, hub, 22.0 + 30.0 * float(i), 60.0 + 40.0 * float(i), 8.0, 1.5)
		if at == Vector3.INF:
			continue
		var node := Node3D.new()
		add_child(node)
		node.position = at
		var stone := ForgeMesh.grain(Color(0.42, 0.42, 0.45), "slate")
		region._block(node, Vector3(1.0, 2.6, 0.6), Vector3(0, 1.3, 0), stone)
		region._block(node, Vector3(1.4, 0.3, 1.0), Vector3(0, 0.15, 0), stone)
		var rune := region._block(node, Vector3(0.5, 0.5, 0.04), Vector3(0, 1.8, 0.32), ForgeMesh.glow(Color(1.0, 0.82, 0.35), 1.8), Vector3(0, 0, 45))
		rune.name = "rune"
		var ring := ForgeMesh.inst(ForgeMesh.ring(0.92, 32), ForgeMesh.ghost(Color(1.0, 0.82, 0.35, 0.35), false), node, Vector3(0, 0.05, 0))
		ring.scale = Vector3(2.4, 1, 2.4)
		_solid(at, 0.6, 2.6)
		var plate := Label3D.new()
		plate.font = Ink.caps_font()
		plate.font_size = 40
		plate.pixel_size = 0.004
		plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plate.outline_size = 10
		plate.outline_modulate = Color(0.04, 0.035, 0.03, 0.9)
		plate.position = Vector3(0, 3.1, 0)
		plate.visibility_range_end = 30.0
		node.add_child(plate)
		stones.append({"node": node, "i": i, "kind": String(kinds[i]), "plate": plate})
		_sync_stone(stones.size() - 1)


func best_medal(i: int) -> int:
	return int(region.soul.flags.get("chal_%s_%d" % [rid, int(stones[i]["i"])], -1))


func _sync_stone(i: int) -> void:
	var st: Dictionary = stones[i]
	var c: Dictionary = CHALLENGE[String(st["kind"])]
	var b := best_medal(i)
	(st["plate"] as Label3D).text = "CHALLENGE · %s\n%s" % [String(c["title"]).to_upper(), ("BEST " + String(MEDALS[b]).to_upper()) if b >= 0 else "NOT YET RUN"]
	(st["plate"] as Label3D).modulate = MEDAL_COLORS[b] if b >= 0 else Ink.PAPER


func _nearest_stone(within: float) -> int:
	var best := -1
	var bd := within
	for i in range(stones.size()):
		var d := (stones[i]["node"] as Node3D).global_position.distance_to(region.player.global_position)
		if d < bd:
			bd = d
			best = i
	return best


func busy() -> bool:
	return not ch.is_empty()


func start_challenge(i: int) -> bool:
	if busy() or (region.events != null and not region.events.ev.is_empty()):
		return false
	var st: Dictionary = stones[i]
	var kind := String(st["kind"])
	var c: Dictionary = CHALLENGE[kind]
	var at: Vector3 = (st["node"] as Node3D).global_position
	ch = {"kind": kind, "stone": i, "t": 0.0, "len": float(c["len"]), "need": int(c["need"]), "got": 0, "foes": [], "spawned": 0, "orbs": [], "at": at}
	Sfx.play("horn", -4.0, 1.2)
	Fx.ring(at + Vector3(0, 0.2, 0), Color(1.0, 0.82, 0.35), 0.5, 8.0, 0.6)
	match kind:
		"slay":
			for n in range(3):
				_challenge_foe(at)
		"parry":
			var foe := _challenge_foe(at)
			if foe != null:
				foe.max_hp *= 5.0
				foe.hp = foe.max_hp
				foe.display_name = "Sparring " + foe.display_name
		"rush":
			for n in range(int(c["need"])):
				var a := TAU * float(n) / float(c["need"]) + _rng.randf_range(-0.3, 0.3)
				var d := _rng.randf_range(7.0, 26.0)
				var p := at + Vector3(cos(a), 0, sin(a)) * d
				if not open_at(p.x, p.z, 0.4):
					p = at + Vector3(cos(a), 0, sin(a)) * 6.0
				p.y = region.height_at(p.x, p.z) + (2.8 if n % 3 == 2 else 1.1)
				var node := Node3D.new()
				add_child(node)
				node.position = p
				region._block(node, Vector3(0.4, 0.4, 0.4), Vector3.ZERO, ForgeMesh.glow(Color(1.0, 0.82, 0.35), 2.4), Vector3(45, 0, 35))
				(ch["orbs"] as Array).append(node)
	region.say("%s|%s" % [String(c["title"]), String(c["line"]) % int(c["need"])], "level")
	return true


func _challenge_foe(at: Vector3) -> Enemy:
	var kinds := _realm_kinds()
	if kinds.is_empty():
		return null
	# the drill wants foes that come to you, not archers
	var melee: Array = []
	for k: Variant in kinds:
		if float((Bestiary.DEFS[String(k)] as Dictionary).get("keep", 0.0)) <= 0.0:
			melee.append(k)
	if melee.is_empty():
		melee = kinds
	var a := _rng.randf() * TAU
	var p := at + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(6.0, 9.0)
	p.y = region.height_at(p.x, p.z)
	var e: Enemy = region._spawn(String(melee[_rng.randi() % melee.size()]), p)
	e.set_meta("challenge", true)
	e.wake(region.player)
	Fx.pillar(p, Color(1.0, 0.82, 0.35), 5.0, 0.3, 0.5)
	(ch["foes"] as Array).append(e)
	ch["spawned"] = int(ch["spawned"]) + 1
	return e


func _tick_challenge(delta: float) -> void:
	if ch.is_empty():
		return
	ch["t"] = float(ch["t"]) + delta
	if not region.player.alive:
		end_challenge(false)
		return
	if int(ch["got"]) >= int(ch["need"]):
		end_challenge(true)
		return
	if float(ch["t"]) >= float(ch["len"]):
		end_challenge(false)


func end_challenge(won: bool) -> int:
	if ch.is_empty():
		return -1
	var i := int(ch["stone"])
	var left := 1.0 - float(ch["t"]) / float(ch["len"])
	for f: Variant in ch["foes"]:
		if is_instance_valid(f) and (f as Enemy).alive:
			region.actors.erase(f)
			(f as Node).queue_free()
	for o: Variant in ch["orbs"]:
		if is_instance_valid(o):
			(o as Node).queue_free()
	ch = {}
	if not won:
		region.say("Out of time|The stone goes quiet. Try again.", "level")
		Sfx.play("warn", -4.0)
		return -1
	var medal := 2 if left >= 0.45 else (1 if left >= 0.2 else 0)
	var before := best_medal(i)
	var s := region.soul
	var grade_k := 1.0 + 0.4 * float(clampi(5 - s.grade, 0, 5))
	var pay := int(round(float([40, 80, 160][medal]) * grade_k * (1.0 if medal > before else 0.34)))
	s.shards += pay
	if medal > before:
		s.flags["chal_%s_%d" % [rid, int(stones[i]["i"])]] = medal
	_sync_stone(i)
	region.say("%s medal|+%d shards%s" % [MEDALS[medal], pay, "" if medal > before else "  (beat your best for full pay)"], "level")
	Sfx.play("quest_done", -2.0)
	Fx.pillar((stones[i]["node"] as Node3D).global_position, MEDAL_COLORS[medal], 10.0, 0.6, 1.0)
	give_badge("challenger")
	if medal == 2:
		give_badge("gold_standard")
		if before < 2:
			_chest_loot((stones[i]["node"] as Node3D).global_position + Vector3(0, 0, 2.0), "silver", 1.0)
		var all := true
		for r2: String in REALMS:
			for k in range((STONES[r2] as Array).size()):
				if int(s.flags.get("chal_%s_%d" % [r2, k], -1)) < 2:
					all = false
		if all:
			give_badge("all_gold")
	return medal


## What the HUD card shows for a challenge under way.
func info() -> Dictionary:
	if ch.is_empty():
		return {}
	var c: Dictionary = CHALLENGE[String(ch["kind"])]
	var verb := String({"slay": "slain", "rush": "gathered", "parry": "parried"}[String(ch["kind"])])
	var left := 1.0 - float(ch["t"]) / float(ch["len"])
	var medal := "gold" if left >= 0.45 else ("silver" if left >= 0.2 else "bronze")
	return {"title": "Challenge · " + String(c["title"]), "line": "%d / %d %s   ·   %s pace" % [int(ch["got"]), int(ch["need"]), verb, medal],
		"left": left, "seconds": int(float(ch["len"]) - float(ch["t"])), "kind": "challenge"}


# --- the world's hooks -----------------------------------------------------

func on_noted(event: String) -> void:
	if event == "parry" and not ch.is_empty() and String(ch["kind"]) == "parry":
		ch["got"] = int(ch["got"]) + 1


func on_enemy_death(e: Enemy) -> void:
	var s := region.soul
	# a streak: kills each within three seconds of the last
	if _now - _last_kill <= STREAK_GAP:
		streak += 1
	else:
		streak = 1
	_last_kill = _now
	best_streak = maxi(best_streak, streak)
	if streak >= 2 and region.player != null:
		var word := String(STREAK_WORDS[mini(streak, STREAK_WORDS.size() - 1)])
		var bonus := 2 * streak
		s.shards += bonus
		Fx.word(region.player.global_position + Vector3(0, 3.0, 0), "%s KILL  +%d" % [word, bonus] if streak < 5 else "%s  +%d" % [word, bonus], Ink.BRASS, 0.9 + 0.08 * float(mini(streak, 6)))
		Sfx.play("crit", -6.0, 0.9 + 0.08 * float(mini(streak, 6)))
		if streak >= 5:
			give_badge("streak")
	if region.daynight != null and region.daynight.night() > 0.6:
		s.flags["night_kills"] = int(s.flags.get("night_kills", 0)) + 1
	if e.has_meta("mimic"):
		_chest_loot(e.global_position, String(e.get_meta("mimic")), 2.0)
		s.flags["chests"] = int(s.flags.get("chests", 0)) + 1
		give_badge("mimic_slayer")
	if e.has_meta("challenge") and not ch.is_empty() and String(ch["kind"]) == "slay":
		ch["got"] = int(ch["got"]) + 1
		(ch["foes"] as Array).erase(e)
		if int(ch["spawned"]) < int(ch["need"]) and int(ch["got"]) < int(ch["need"]):
			_challenge_foe(ch["at"])


func give_badge(id: String) -> void:
	var d := Badges.award(region.soul, id)
	if d.is_empty():
		return
	_announce(d)


func _announce(d: Array) -> void:
	region.say("Badge|%s|%s%s" % [String(d[1]), String(d[2]), ("  +%d shards" % int(d[3])) if int(d[3]) > 0 else ""], "drop")
	Sfx.play("quest_done", -4.0, 1.15)


# --- talking to the region -------------------------------------------------

func prompt() -> String:
	var fi := _nearest_folk(3.0)
	if fi >= 0:
		return "E  Talk to %s" % String((folk[fi]["def"] as Array)[0])
	var si := _nearest_stone(3.0)
	if si >= 0:
		if busy():
			return ""
		var c: Dictionary = CHALLENGE[String(stones[si]["kind"])]
		return "E  Start the challenge: %s" % String(c["title"])
	var ci := _nearest_chest(2.4)
	if ci >= 0:
		return "E  Open the %s chest" % String(chests[ci]["tier"]) if not chest_open(ci) else "Opened today. It fills again tomorrow."
	if _nearest_breakable(2.2) >= 0:
		return "LMB or E  Break it"
	return ""


func interact() -> bool:
	var fi := _nearest_folk(3.0)
	if fi >= 0:
		if region._talk_cd > 0.0:
			return true
		region._talk_cd = 0.35
		talk(fi)
		return true
	var si := _nearest_stone(3.0)
	if si >= 0:
		if region._talk_cd > 0.0:
			return true
		region._talk_cd = 0.35
		if busy():
			return true
		if region.events != null and not region.events.ev.is_empty():
			region.say("Not while the world is coming apart.", "hint")
			return true
		start_challenge(si)
		return true
	var ci := _nearest_chest(2.4)
	if ci >= 0:
		if not chest_open(ci):
			region.player.face_now(region.player.flat_to((chests[ci]["node"] as Node3D).global_position))
			region.player.begin_busy("chest", 0.6, "kneel", open_chest.bind(ci, true))
		return true
	var bi := _nearest_breakable(2.2)
	if bi >= 0:
		break_at(bi)
		return true
	return false


func markers() -> Array:
	var out: Array = []
	if not hint.is_empty():
		out.append([hint["at"], Color(1.0, 0.82, 0.35) if String(hint["kind"]) == "chest" else Color(0.62, 0.9, 1.0), String(hint["kind"])])
	for st: Variant in stones:
		out.append([((st as Dictionary)["node"] as Node3D).global_position, Color(1.0, 0.82, 0.35), "stone"])
	for o: Variant in ch.get("orbs", []):
		if is_instance_valid(o):
			out.append([(o as Node3D).global_position, Color(1.0, 0.82, 0.35), "orb"])
	return out


func tick(delta: float) -> void:
	_now += delta
	if region.player == null:
		return
	_folk_t -= delta
	if _folk_t <= 0.0:
		_tick_folk(0.1)
		_folk_t = 0.1
	_tick_dummy(delta)
	_tick_orbs(delta)
	_tick_challenge(delta)
	if not hint.is_empty():
		hint["t"] = float(hint["t"]) - delta
		if float(hint["t"]) <= 0.0:
			hint = {}
	_tip_t -= delta
	if _tip_t <= 0.0:
		_tip_t = 0.5
		_tips()
	_badge_t -= delta
	if _badge_t <= 0.0:
		_badge_t = 1.0
		for d: Variant in Badges.check(region.soul):
			_announce(d)

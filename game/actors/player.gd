class_name Player
extends Actor
## The soul the player wears. Input becomes intent, intent becomes blows.
## Tests fill `intent` by hand with `scripted` set, and press the same buttons.

class Intent:
	var move: Vector2 = Vector2.ZERO
	var light: bool = false
	var heavy: bool = false
	var block: bool = false
	var block_pressed: bool = false
	var dash: bool = false
	var jump: bool = false
	var jump_held: bool = false
	var tech: int = -1
	var release: bool = false
	var interact: bool = false
	var send: bool = false
	var lock: bool = false
	var sprint: bool = false
	var crit: bool = false
	var grip: bool = false
	var carry: bool = false
	var sense: bool = false
	var race: bool = false

	func clear_presses() -> void:
		crit = false
		grip = false
		carry = false
		light = false
		heavy = false
		block_pressed = false
		dash = false
		jump = false
		tech = -1
		release = false
		interact = false
		send = false
		lock = false


const LIGHTS: Array = [
	{"clip": "light1", "startup": 0.15, "active": 0.08, "recover": 0.26, "dmg": 1.0, "reach": 2.5, "arc": 150.0, "lunge": 5.0, "posture": 8.0, "cancel": 0.05, "roll": 12.0, "pitch": 1.05},
	{"clip": "light2", "startup": 0.14, "active": 0.08, "recover": 0.26, "dmg": 1.0, "reach": 2.5, "arc": 150.0, "lunge": 5.0, "posture": 8.0, "cancel": 0.05, "roll": -16.0, "pitch": 1.12},
	{"clip": "light1", "startup": 0.14, "active": 0.08, "recover": 0.26, "dmg": 1.05, "reach": 2.5, "arc": 150.0, "lunge": 5.0, "posture": 9.0, "cancel": 0.05, "roll": 34.0, "pitch": 1.08},
	{"clip": "light2", "startup": 0.14, "active": 0.08, "recover": 0.28, "dmg": 1.05, "reach": 2.5, "arc": 150.0, "lunge": 5.0, "posture": 9.0, "cancel": 0.05, "roll": -30.0, "pitch": 1.15},
	{"clip": "light3", "startup": 0.2, "active": 0.09, "recover": 0.4, "dmg": 1.4, "reach": 2.8, "arc": 70.0, "lunge": 6.5, "posture": 14.0, "cancel": 0.12, "roll": 88.0, "knock": 5.0, "pitch": 0.92},
]
const HEAVY_MOVE: Dictionary = {"clip": "heavy", "startup": 0.42, "active": 0.1, "recover": 0.42, "dmg": 1.0, "reach": 3.0, "arc": 70.0, "lunge": 5.5, "posture": 28.0, "roll": 90.0, "knock": 6.0, "armor": true, "sfx": "whoosh_heavy", "pitch": 0.85}
# ---- the race kits: once awakened, each strain fights its own way
const CLAWS: Array = [
	{"clip": "light1", "startup": 0.11, "active": 0.08, "recover": 0.2, "dmg": 0.78, "reach": 2.3, "arc": 150.0, "lunge": 6.0, "posture": 7.0, "cancel": 0.04, "roll": 12.0, "pitch": 1.2},
	{"clip": "light2", "startup": 0.1, "active": 0.08, "recover": 0.2, "dmg": 0.78, "reach": 2.3, "arc": 150.0, "lunge": 6.0, "posture": 7.0, "cancel": 0.04, "roll": -16.0, "pitch": 1.25},
	{"clip": "light1", "startup": 0.1, "active": 0.08, "recover": 0.22, "dmg": 0.82, "reach": 2.3, "arc": 150.0, "lunge": 6.0, "posture": 8.0, "cancel": 0.04, "roll": 30.0, "pitch": 1.3},
	{"clip": "light2", "startup": 0.1, "active": 0.08, "recover": 0.22, "dmg": 0.82, "reach": 2.3, "arc": 150.0, "lunge": 6.0, "posture": 8.0, "cancel": 0.04, "roll": -30.0, "pitch": 1.32},
	{"clip": "thrust", "startup": 0.16, "active": 0.09, "recover": 0.38, "dmg": 1.35, "reach": 2.7, "arc": 70.0, "lunge": 10.0, "posture": 14.0, "cancel": 0.1, "roll": 0.0, "knock": 5.0, "pitch": 0.95},
]
const MAW_BEAM: Dictionary = {"clip": "cast", "type": "bolt", "startup": 0.55, "active": 0.06, "recover": 0.42, "dmg": 1.3, "reach": 40.0, "arc": 10.0, "speed": 64.0, "posture": 26.0, "pierce": true, "beam": true, "armor": true, "sfx": "cast", "pitch": 0.6}
const ARROW: Dictionary = {"clip": "cast", "type": "bolt", "startup": 0.12, "active": 0.06, "recover": 0.2, "dmg": 0.72, "reach": 34.0, "arc": 10.0, "speed": 50.0, "posture": 5.0, "cancel": 0.02, "sfx": "bolt", "pitch": 1.35}
const PIERCING: Dictionary = {"clip": "cast", "type": "bolt", "startup": 0.48, "active": 0.06, "recover": 0.34, "dmg": 1.4, "reach": 44.0, "arc": 10.0, "speed": 74.0, "posture": 22.0, "pierce": true, "armor": true, "sfx": "cast", "pitch": 1.1}
const CHAIN_LIGHTS: Array = [
	{"clip": "light1", "startup": 0.18, "active": 0.1, "recover": 0.26, "dmg": 0.95, "reach": 3.9, "arc": 110.0, "lunge": 2.0, "posture": 8.0, "cancel": 0.06, "roll": 10.0, "pitch": 0.95},
	{"clip": "light2", "startup": 0.17, "active": 0.1, "recover": 0.26, "dmg": 0.95, "reach": 3.9, "arc": 110.0, "lunge": 2.0, "posture": 8.0, "cancel": 0.06, "roll": -14.0, "pitch": 1.0},
	{"clip": "light3", "startup": 0.22, "active": 0.11, "recover": 0.36, "dmg": 1.3, "reach": 4.4, "arc": 50.0, "lunge": 3.0, "posture": 14.0, "cancel": 0.12, "roll": 88.0, "knock": 4.0, "pitch": 0.9},
]
const CHAIN_PULL: Dictionary = {"clip": "thrust", "startup": 0.3, "active": 0.1, "recover": 0.4, "dmg": 0.8, "reach": 7.5, "arc": 34.0, "lunge": 0.0, "posture": 26.0, "pull": true, "roll": 0.0, "sfx": "whoosh_heavy", "pitch": 0.8}
const KIT_NAMES: Dictionary = {"sword": "Blade", "claw": "Claws and Maw Beam", "bow": "Bow of light", "chain": "Bound chain"}

const AIR_MOVE: Dictionary = {"clip": "aircut", "startup": 0.13, "active": 0.1, "recover": 0.2, "dmg": 1.1, "reach": 2.7, "arc": 170.0, "lunge": 3.0, "posture": 8.0, "roll": 50.0, "pitch": 1.15}

var soul: Soul
var stats: Dictionary = {}
var intent: Intent = Intent.new()
var scripted: bool = false

var max_anima: float = 100.0
var anima: float = 100.0
var swell: float = 0.0
var released: bool = false
var tech_cd: Array[float] = [0.0, 0.0, 0.0, 0.0]
var dash_cd_t: float = 0.0
var lock_target: Actor
var combo_i: int = 0
var combo_t: float = 0.0
var riposte_t: float = 0.0
var busy_kind: String = ""
var special_t: float = 0.0

var _buffer: String = ""
var _buffer_t: float = 0.0
var _buffer_tech: int = -1
var _dash_dir: Vector3 = Vector3.FORWARD
var _ghost_t: float = 0.0
var _air_dash: bool = false
var _last_block_press: float = 9.0
var _release_burst: bool = false
var _unbroken_used: bool = false
var _sever_from: Vector3 = Vector3.ZERO
var _step_t: float = 0.0
var _was_floor: bool = true
var _aura: OmniLight3D
var _busy_done: Callable = Callable()
var _blink_target: int = 0
var _sprint_t: float = 0.0
var style_pts: float = 0.0
var combo_hits: int = 0
var _style_idle: float = 0.0
var _recent_kinds: Array = []
var _air_dashes: int = 0
var _rend_from: Vector3 = Vector3.ZERO
var _orbit: Node3D
## Shift lock: the body faces where the camera looks and strafes, the
## camera sits over the shoulder. On by default, as players expect.
static var shift_lock: bool = true
var _feint_cd: float = 0.0
## Evasive: burst out of a combo while being hit. Critical: a red, unguardable
## strike with a tell. Both on long cooldowns, as in the genre.
const EVASIVE_CD: float = 12.0
const CRIT_CD: float = 9.0
var evasive_cd: float = 0.0
var crit_cd: float = 0.0
var _air_hits: int = 0
## One extra jump in the air, given back on landing.
var air_jumps: int = 1
## A body over the shoulder, if any.
var carrying: Enemy = null
## Spirit sense: held, it spends spirit energy to feel every enemy near.
const SENSE_RANGE: float = 70.0
const SENSE_COST: float = 6.0
var sensing: bool = false
## The race's own power on X, and what it leaves running.
const RACE_ARTS: Dictionary = {
	"vigil": {"name": "Binding Art", "short": "BIND", "cd": 14.0, "cost": 25.0},
	"maw": {"name": "Iron Hide", "short": "HIDE", "cd": 18.0, "cost": 15.0},
	"lumen": {"name": "Rail Step", "short": "RAIL", "cd": 8.0, "cost": 12.0},
	"relic": {"name": "Grapple", "short": "GRAPPLE", "cd": 6.0, "cost": 10.0},
}
## A power grows with its soul: a second form at Grade 3, a third at
## Grade 1; a grafted strain infuses it; the strongest habit tunes it.
const INFUSION: Dictionary = {"vigil": "Sworn", "maw": "Devouring", "lumen": "Radiant", "relic": "Chained"}
const HAND_TUNE: Dictionary = {
	"aggression": {"cd": 0.8, "line": "returns sooner"}, "patience": {"dur": 1.35, "cd": 1.1, "line": "lasts longer"},
	"mobility": {"reach": 1.3, "line": "reaches further"}, "range": {"reach": 1.4, "cost": 1.1, "line": "reaches much further"},
	"risk": {"dmg": 1.4, "cd": 1.15, "line": "hits harder, returns slower"}, "hunger": {"heal": 0.05, "line": "feeds you"},
	"precision": {"posture": 1.5, "line": "breaks stance"}, "weight": {"dmg": 1.3, "reach": 0.9, "line": "lands heavier"},
	"craft": {"cost": 0.7, "line": "costs less"}, "stillness": {"cd": 0.85, "cost": 0.85, "line": "comes easier"},
}
const ROMAN: Array = ["", "", "II", "III"]
var race_cd: float = 0.0
var race_charges: int = 1
var sworn_t: float = 0.0
var _art_name: String = ""
var _art_check: float = 0.0
var _hide_was: float = 0.0
var _rail_hit: Array = []
var _chain_left: int = 0
var hide_t: float = 0.0
var volley_t: float = 0.0
var _since_hurt: float = 0.0
var _grapple_to: Actor = null
var _sense_pulse: float = 0.0
var _jump_lock: float = 0.0
## What the socketed runes do: {effect: power}. Set in refresh_stats.
var runes: Dictionary = {}
var _rune_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _dash_held: float = 0.0


func setup(s: Soul) -> void:
	soul = s
	team = 0
	display_name = "You"
	rebuild_body()
	refresh_stats(true)


func look_spec() -> Dictionary:
	var look := soul.look()
	var tints: Array = [Color(0.08, 0.08, 0.1), Color(0.86, 0.86, 0.9), Color(0.5, 0.12, 0.12), Color(0.2, 0.28, 0.34)]
	var cloths: Array = [Color(0.06, 0.06, 0.08), Color(0.08, 0.07, 0.12), Color(0.11, 0.07, 0.07)]
	var skins: Array = [Color(0.96, 0.84, 0.7), Color(0.9, 0.72, 0.55), Color(0.76, 0.56, 0.4), Color(0.55, 0.38, 0.27), Color(0.36, 0.25, 0.19)]
	var hair_c: Color = tints[int(look["hair_tint"])]
	var col := current_color()
	var spec := {
		"scale": float(look["build"]), "cloth": cloths[int(look["coat"])], "trim": Color(0.88, 0.88, 0.9),
		"coat": 1 + (int(look["coat"]) % 2), "sash": int(look["sash"]), "hair": int(look["hair"]),
		"hair_color": hair_c.lerp(Color(0.5, 0.5, 0.55), float(look["hair_tone"]) * 0.4), "hair_seed": soul.seed, "mask_seed": soul.seed,
		"accent": col, "skin": skins[int(look["skin"])], "face": int(look["face"]),
	}
	spec["tether"] = int(soul.flags.get("tether", 0)) if not soul.written() else 0
	var strains: Array = [soul.primary, soul.secondary]
	if strains.has("maw"):
		spec["fragment"] = true
		spec["claws"] = soul.primary == "maw"
	if strains.has("lumen"):
		spec["halo"] = true
	if strains.has("relic"):
		spec["plates"] = true
	if strains.has("vigil"):
		spec["coat"] = 2
		spec["collar"] = soul.secondary != ""
	_stage_look(spec)
	var arm: Dictionary = soul.gear.get("armour", {})
	if not arm.is_empty():
		spec["armour"] = String(arm.get("look", "plate"))
		spec["armour_color"] = Forge.color_of(arm)
		if spec["armour"] == "robe":
			spec["coat"] = 2
			spec["trim"] = Forge.color_of(arm)
	return spec


## What a soul's grade does to how it looks. Devourers change the most.
func _stage_look(spec: Dictionary) -> void:
	var g := soul.grade
	match soul.primary:
		"maw":
			spec["hole"] = true
			spec["cloth"] = Color(0.86, 0.86, 0.84).lerp(spec["cloth"], 0.25)
			spec["trim"] = Color(0.18, 0.18, 0.2)
			if g >= 5:
				spec["mask"] = 0
				spec["fragment"] = false
			elif g == 4:
				spec["mask"] = 2
				spec["fragment"] = false
				spec["scale"] = float(spec["scale"]) * 1.32
				spec["bulk"] = 1.3
			elif g == 3:
				spec["mask"] = 2
				spec["fragment"] = false
				spec["scale"] = float(spec["scale"]) * 1.1
				spec["leg"] = 1.15
				spec["bulk"] = 0.9
			else:
				spec["fragment"] = true
				spec["collar"] = true
				spec["cloth"] = Color(0.95, 0.94, 0.9)
				spec["trim"] = Color(0.55, 0.08, 0.1)
		"vigil":
			if g <= 4:
				spec["sash"] = maxi(1, int(spec["sash"]))
			if g <= 2:
				spec["trim"] = spec["accent"]
			if g <= 1:
				spec["cloth"] = Color(0.92, 0.92, 0.94)
				spec["trim"] = Color(0.08, 0.08, 0.1)
		"lumen":
			spec["cloth"] = Color(0.9, 0.92, 0.96)
			spec["trim"] = Color(0.2, 0.4, 0.8).lerp(spec["accent"], 0.3)
			if g <= 2:
				spec["collar"] = true
		"relic":
			spec["cloth"] = [Color(0.2, 0.22, 0.3), Color(0.3, 0.18, 0.16), Color(0.18, 0.26, 0.2)][soul.seed % 3]
			spec["coat"] = 1
			if g <= 2:
				spec["collar"] = true


func current_color() -> Color:
	if released and not soul.release.is_empty():
		return AbilityForge.color_of(soul.release)
	return Strains.color_of(soul.primary, soul.secondary)


func rebuild_body() -> void:
	var keep_rot := rotation.y
	if rig != null:
		for c in get_children():
			c.queue_free()
	build_body(look_spec())
	rotation.y = keep_rot
	accent = current_color()
	_equip()
	_aura = OmniLight3D.new()
	_aura.light_energy = 0.0
	_aura.omni_range = 7.0
	_aura.position = Vector3(0, 1.2, 0)
	add_child(_aura)


## How this soul fights right now. Released, everyone fights with the form
## their spirit took; before the Awakening everyone has the sealed blade.
func kit() -> String:
	if released or soul == null or not soul.written():
		return "sword"
	match soul.primary:
		"maw": return "claw"
		"lumen": return "bow"
		"relic": return "chain"
	return "sword"


func _equip() -> void:
	if _orbit != null:
		_orbit.queue_free()
		_orbit = null
	if released and not soul.release.is_empty():
		rig.hold(Gear.released_blade(soul.release, soul.seed))
		if int(soul.release.get("stage", 1)) >= 3:
			# the Last Release: blades turn about you
			_orbit = Node3D.new()
			add_child(_orbit)
			_orbit.position = Vector3(0, 1.3, 0)
			var col := current_color()
			for i in range(6):
				var a := TAU * float(i) / 6.0
				var sh := ForgeMesh.inst(ForgeMesh.shard(1.1, 0.08, 4), ForgeMesh.glow(col, 3.0), _orbit, Vector3(cos(a) * 1.6, 0, sin(a) * 1.6))
				sh.rotation = Vector3(0, -a, PI * 0.5)
				sh.set_meta("no_ghost", true)
		return
	match kit():
		"claw":
			rig.hold(null)
		"bow":
			rig.hold(Gear.bow(current_color().lerp(_weapon_tint(), 0.5), soul.seed))
		"chain":
			var c := current_color().lerp(_weapon_tint(), 0.4)
			rig.hold(Gear.released_blade({"form": "chain", "color": [c.r, c.g, c.b], "reach": 1.2}, soul.seed))
		_:
			var w: Dictionary = soul.gear.get("weapon", {})
			rig.hold(Gear.sealed_blade(soul.seed, _weapon_tint(), float(w.get("length", 1.0)), int(w.get("tier", 0))))


func _weapon_tint() -> Color:
	var w: Dictionary = soul.gear.get("weapon", {})
	return Color.WHITE if w.is_empty() else Forge.color_of(w)


func refresh_stats(full: bool = false) -> void:
	var frac := 1.0 if full or max_hp <= 0.0 else hp / max_hp
	stats = Stats.compute(soul)
	if place != null and place.region_id_of() == "undermark":
		stats["max_hp"] = float(stats["max_hp"]) * (1.0 - 0.06 * float(mini(int(soul.flags.get("brands", 0)), 5)))
	if released and int(soul.release.get("stage", 1)) >= 3:
		stats["light_dmg"] = float(stats["light_dmg"]) * 1.25
		stats["heavy_dmg"] = float(stats["heavy_dmg"]) * 1.25
	runes = Forge.rune_effects(soul)
	max_hp = float(stats["max_hp"])
	hp = max_hp * frac
	posture_max = float(stats["posture_max"])
	parry_window = float(stats["parry_window"])
	max_anima = float(stats["max_anima"])
	if full:
		anima = max_anima
		posture = 0.0


func rel(key: String, fallback: float = 1.0) -> float:
	if not released:
		return fallback
	return float(soul.release.get(key, fallback))


func attack_speed() -> float:
	return float(stats["attack_speed"]) * rel("speed") * (0.75 if slow_t > 0.0 else 1.0)


func _timed(m: Dictionary) -> Dictionary:
	var out := m.duplicate()
	var sp := attack_speed()
	out["startup"] = float(m["startup"]) / sp
	out["active"] = float(m["active"])
	out["recover"] = float(m["recover"]) / sp
	out["reach"] = float(m["reach"]) * rel("reach")
	out["posture"] = float(m["posture"]) * float(stats["posture_dmg"]) * rel("posture") * (1.25 if sworn_t > 0.0 else 1.0)
	out["color"] = current_color()
	return out


func lights() -> Array:
	match kit():
		"claw": return CLAWS
		"bow": return [ARROW]
		"chain": return CHAIN_LIGHTS
	return LIGHTS


func light_move(i: int) -> Dictionary:
	var list := lights()
	var m := _timed(list[i % list.size()])
	m["kind"] = "ranged" if String(m.get("type", "")) == "bolt" else "light"
	if String(m.get("type", "")) == "bolt":
		m["reach"] = float(list[i % list.size()]["reach"])
	m["dmg"] = float(stats["light_dmg"]) * float(m["dmg"]) * rel("dmg") * (1.5 if riposte_t > 0.0 else 1.0)
	if volley_t > 0.0 and String(m.get("type", "")) == "bolt":
		m["count"] = 3
		m["spread"] = 8.0
	return m


func heavy_move() -> Dictionary:
	var base: Dictionary = HEAVY_MOVE
	match kit():
		"claw": base = MAW_BEAM
		"bow": base = PIERCING
		"chain": base = CHAIN_PULL
	var m := _timed(base)
	if String(m.get("type", "")) == "bolt":
		m["reach"] = float(base["reach"])
	m["kind"] = "ranged" if kit() == "bow" else "heavy"
	m["heavy"] = true
	m["dmg"] = float(stats["heavy_dmg"]) * float(base.get("dmg", 1.0)) * rel("dmg") * (1.5 if riposte_t > 0.0 else 1.0)
	return m


func air_move() -> Dictionary:
	var m := _timed(AIR_MOVE)
	m["kind"] = "air"
	m["dmg"] = float(stats["light_dmg"]) * 1.1 * rel("dmg")
	return m


# ------------------------------------------------------------------ input

func _gather() -> void:
	if scripted:
		return
	intent.clear_presses()
	if place != null and place.paused_input:
		intent.move = Vector2.ZERO
		intent.block = false
		intent.jump_held = false
		return
	intent.move = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward"))
	intent.light = Input.is_action_just_pressed("light")
	intent.heavy = Input.is_action_just_pressed("heavy")
	intent.block = Input.is_action_pressed("block")
	intent.block_pressed = Input.is_action_just_pressed("block")
	intent.dash = Input.is_action_just_pressed("dash")
	if Input.is_action_pressed("dash"):
		_dash_held += get_physics_process_delta_time()
	else:
		_dash_held = 0.0
	intent.sprint = Input.is_action_pressed("sprint") or (Input.get_connected_joypads().size() > 0 and _dash_held > 0.25)
	if Input.is_action_just_pressed("shiftlock"):
		shift_lock = not shift_lock
		Sfx.play("ui_tick", -6.0, 1.2 if shift_lock else 0.8)
		if place != null:
			place.say("Shift lock %s." % ("on" if shift_lock else "off"), "hint")
	intent.jump = Input.is_action_just_pressed("jump")
	intent.jump_held = Input.is_action_pressed("jump")
	intent.release = Input.is_action_just_pressed("release")
	intent.crit = Input.is_action_just_pressed("crit")
	intent.grip = Input.is_action_just_pressed("grip")
	intent.sense = Input.is_action_pressed("sense")
	intent.race = Input.is_action_just_pressed("race")
	intent.carry = Input.is_action_just_pressed("carry")
	intent.interact = Input.is_action_just_pressed("interact")
	intent.send = Input.is_action_just_pressed("send")
	intent.lock = Input.is_action_just_pressed("lock")
	for i in range(4):
		if Input.is_action_just_pressed("tech%d" % (i + 1)):
			intent.tech = i


func move_dir() -> Vector3:
	var v := intent.move
	if v.length() < 0.15:
		return Vector3.ZERO
	if v.length() > 1.0:
		v = v.normalized()
	var yaw := place.cam.yaw if place != null and place.cam != null else 0.0
	return Basis(Vector3.UP, yaw) * Vector3(v.x, 0.0, -v.y)


func cam_forward() -> Vector3:
	var yaw := place.cam.yaw if place != null and place.cam != null else rotation.y
	return Basis(Vector3.UP, yaw) * Vector3.FORWARD


func _buffer_presses() -> void:
	if intent.crit:
		_buffer = "crit"
		_buffer_t = 0.3
	if intent.light:
		_buffer = "light"
		_buffer_t = 0.24
	if intent.heavy:
		_buffer = "heavy"
		_buffer_t = 0.24
	if intent.dash:
		_buffer = "dash"
		_buffer_t = 0.2
	if intent.tech >= 0:
		_buffer = "tech"
		_buffer_tech = intent.tech
		_buffer_t = 0.24
	if intent.jump:
		_buffer = "jump"
		_buffer_t = 0.14
	if intent.block_pressed:
		block_age_reset()


func block_age_reset() -> void:
	# mashing the guard shrinks the window: a parry has to be meant
	var spam := _last_block_press < 0.4
	_last_block_press = 0.0
	block_age = 0.09 if spam else 0.0


# ------------------------------------------------------------------ frame

func _physics_process(delta: float) -> void:
	if place == null or soul == null:
		return
	_tick_common(delta)
	_gather()
	_tick_timers(delta)
	if alive:
		_buffer_presses()
		if intent.lock:
			_toggle_lock()
		if lock_target != null and (not is_instance_valid(lock_target) or not lock_target.alive or lock_target.yielded or flat_to(lock_target.global_position).length() > 34.0):
			lock_target = null
		match state:
			St.FREE:
				_tick_free(delta)
			St.BLOCK:
				_tick_block(delta)
			St.ATTACK:
				_tick_attack_player(delta)
			St.DASH:
				_tick_dash(delta)
			St.HIT, St.STAGGER:
				_tick_grabbed()
				_tick_recover(delta)
				if state == St.HIT and (intent.dash or _buffer == "dash"):
					evasive()
			St.BUSY:
				_tick_busy(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	_apply_gravity(delta)
	var pre := velocity
	move_and_slide()
	_wall_bounce(pre)
	_keep_in_world()
	_post(delta)


func _tick_timers(delta: float) -> void:
	_buffer_t -= delta
	if _buffer_t <= 0.0:
		_buffer = ""
	_last_block_press += delta
	dash_cd_t = maxf(0.0, dash_cd_t - delta)
	_feint_cd = maxf(0.0, _feint_cd - delta)
	evasive_cd = maxf(0.0, evasive_cd - delta)
	race_cd = maxf(0.0, race_cd - delta)
	_hide_was = hide_t
	hide_t = maxf(0.0, hide_t - delta)
	if _hide_was > 0.0 and hide_t <= 0.0 and race_art().get("tier", 1) >= 3 and soul.primary == "maw":
		_hide_burst()
	sworn_t = maxf(0.0, sworn_t - delta)
	_tick_charges()
	_art_check -= delta
	if _art_check <= 0.0:
		_art_check = 1.0
		_note_art_change()
	volley_t = maxf(0.0, volley_t - delta)
	_since_hurt += delta
	_tick_regrowth(delta)
	_tick_sense(delta)
	_jump_lock = maxf(0.0, _jump_lock - delta)
	crit_cd = maxf(0.0, crit_cd - delta)
	riposte_t = maxf(0.0, riposte_t - delta)
	special_t = maxf(0.0, special_t - delta)
	combo_t -= delta
	if combo_t <= 0.0 and state != St.ATTACK:
		combo_i = 0
	for i in range(4):
		tech_cd[i] = maxf(0.0, tech_cd[i] - delta)
	if alive:
		anima = minf(max_anima, anima + float(stats["anima_regen"]) * delta)
		if released:
			swell -= (100.0 / (40.0 if int(soul.release.get("stage", 1)) >= 3 else 26.0)) * delta
			if swell <= 0.0:
				_seal()
	if is_on_floor():
		_air_dash = false
		_air_dashes = 0
		_air_hits = 0
		air_jumps = 1
	_style_idle += delta
	if _style_idle > 3.0 and style_pts > 0.0:
		style_pts = maxf(0.0, style_pts - delta * (2.0 + style_pts * 0.05))
		if style_pts <= 0.0:
			combo_hits = 0


func _tick_free(delta: float) -> void:
	var dir := move_dir()
	var speed := float(stats["move_speed"]) * speed_factor()
	if carrying != null and not is_instance_valid(carrying):
		carrying = null
	if carrying != null:
		speed *= 0.7
		if intent.light or _buffer == "light":
			_buffer = ""
			throw_carried()
		elif intent.carry:
			drop_carried()
		elif _buffer != "jump":
			_buffer = ""
	elif intent.race:
		if try_race_art():
			return
	elif intent.grip and is_on_floor():
		if try_grip():
			return
	elif intent.carry and is_on_floor():
		try_carry()
	# hold the dash key while moving to run: the regions are big
	if intent.sprint and dir != Vector3.ZERO and is_on_floor():
		speed *= 1.75
		_sprint_t += delta
		if _sprint_t > 0.12:
			_sprint_t = 0.0
			if Vector2(velocity.x, velocity.z).length() > speed * 0.7:
				Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.35), 2, 0.3)
	else:
		_sprint_t = 0.0
	var accel := 70.0 if is_on_floor() else 22.0
	velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	if lock_target != null and (dir == Vector3.ZERO or shift_locked()):
		face(flat_to(lock_target.global_position), delta, 10.0)
	elif shift_locked():
		face(cam_forward(), delta, 24.0)
	elif dir != Vector3.ZERO:
		face(dir, delta, 16.0)
	if intent.block and is_on_floor():
		set_state(St.BLOCK)
		blocking = true
		rig.play("block", 0.06, 1.0, true)
		return
	if intent.release:
		try_release()
		return
	if intent.interact and is_on_floor() and place.interact():
		return
	if intent.send and is_on_floor() and place.send_on():
		return
	_try_buffer()


func _tick_block(delta: float) -> void:
	blocking = true
	var dir := move_dir()
	var speed := float(stats["move_speed"]) * 0.35
	velocity.x = move_toward(velocity.x, dir.x * speed, 50.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 50.0 * delta)
	var to := flat_to(lock_target.global_position) if lock_target != null else cam_forward()
	face(to, delta, 12.0)
	if rig.clip_name != "*" and rig.clip_name != "block" and rig.clip_name != "parry":
		rig.play("block", 0.08)
	elif rig.clip_name == "parry" and rig.finished:
		rig.play("block", 0.08)
	if not intent.block:
		set_state(St.FREE)
		return
	if _buffer == "dash" or _buffer == "light" or _buffer == "heavy" or _buffer == "tech":
		_try_buffer()


func _tick_attack_player(delta: float) -> void:
	var startup := float(move["startup"])
	var active := float(move["active"])
	if state_t < startup * 0.6:
		var t := _attack_target(7.0)
		if t != null:
			face(flat_to(t.global_position), delta, 18.0)
			# do not run through a body that is already in reach
			var gap := flat_to(t.global_position).length() - t.radius
			if gap < float(move["reach"]) * 0.55:
				move["lunge"] = minf(float(move.get("lunge", 0.0)), 1.0)
		elif shift_locked():
			face(cam_forward(), delta, 18.0)
		elif move_dir() != Vector3.ZERO:
			face(move_dir(), delta, 10.0)
	# a feint: guard during a heavy's wind-up to call it off and bait a parry
	if String(move.get("kind", "")) == "heavy" and state_t < startup * 0.8 and intent.block_pressed and _feint_cd <= 0.0 and is_on_floor():
		_feint_cd = 1.4
		set_state(St.BLOCK)
		blocking = true
		rig.play("block", 0.05, 1.0, true)
		Fx.word(global_position + Vector3(0, rig.height + 0.5, 0), "FEINT", Color(0.84, 0.81, 0.75), 0.6)
		Sfx.play("guard", -8.0, 1.4)
		place.note("feint")
		return
	_tick_attack(delta)
	if state != St.ATTACK:
		return
	var after := state_t - (startup + active)
	if after >= 0.0:
		if _buffer == "dash":
			_try_buffer()
		elif after >= float(move.get("cancel", 0.1)) and (_buffer == "light" or _buffer == "heavy" or _buffer == "tech"):
			_try_buffer()
		elif after >= 0.1 and intent.block:
			set_state(St.BLOCK)
			blocking = true
			rig.play("block", 0.06, 1.0, true)


func _attack_done() -> void:
	combo_t = 0.5
	rig.play(idle_clip(), 0.2)


func _attack_target(max_dist: float) -> Actor:
	if lock_target != null:
		return lock_target
	var dir := move_dir()
	if dir == Vector3.ZERO:
		dir = forward()
	return place.nearest_enemy(global_position, max_dist, dir, 0.1)


func _try_buffer() -> void:
	var what := _buffer
	match what:
		"dash":
			if dash_cd_t <= 0.0 and (is_on_floor() or not _air_dash):
				_buffer = ""
				_start_dash()
		"light":
			_buffer = ""
			if not is_on_floor() and kit() != "bow":
				velocity.y = maxf(velocity.y, 2.5)
				_air_hits += 1
				if _air_hits >= 3:
					_air_hits = 0
					_begin(_finisher(air_move(), "down"))
				else:
					_begin(air_move())
			else:
				var n := lights().size()
				var i := combo_i % n
				var m := light_move(i)
				if i == n - 1 and kit() != "bow":
					m = _finisher(m, "up" if intent.jump_held else "out")
				_begin(m)
				combo_i += 1
				if i == n - 1:
					combo_i = 0
			riposte_t = 0.0
		"heavy":
			_buffer = ""
			var broken := _broken_near()
			if broken != null:
				_execute(broken)
			else:
				_begin(heavy_move())
			riposte_t = 0.0
			combo_i = 0
		"tech":
			_buffer = ""
			use_tech(_buffer_tech)
		"crit":
			_buffer = ""
			try_crit()
		"jump":
			if is_on_floor():
				_buffer = ""
				velocity.y = 10.0
				_jump_lock = 0.08
				Sfx.play("jump", -8.0)
				Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.5), 5, 0.4)
			elif _jump_lock > 0.0:
				_buffer = ""
			elif air_jumps > 0 and velocity.y < 7.0:
				# the second jump: a kick off nothing, a ring of air under the feet
				_buffer = ""
				air_jumps -= 1
				velocity.y = 9.5
				var dir := move_dir()
				if dir != Vector3.ZERO:
					var carry := maxf(Vector2(velocity.x, velocity.z).length(), float(stats["move_speed"]))
					velocity.x = dir.x * carry
					velocity.z = dir.z * carry
				Sfx.play("air_jump", -4.0)
				Fx.ring(global_position + Vector3(0, 0.1, 0), Color(0.88, 0.88, 0.9), 0.2, 1.6, 0.25)
				rig.play("air", 0.06, 1.0, true)


## Held in a great enemy's grip: lifted, shaken, thrown. The evasive breaks
## free; nothing else does.
func _grabbed(by: Actor) -> void:
	if carrying != null:
		drop_carried()
	set_state(St.HIT, 1.0)
	_grabber = by
	velocity = Vector3.ZERO
	rig.play("hit", 0.04, 1.0, true)
	Fx.word(center() + Vector3(0, 1.0, 0), "GRABBED", Color(1, 0.3, 0.25), 0.9)
	Sfx.play("grab", -1.0)


var _grabber: Actor = null


func _tick_grabbed() -> void:
	if _grabber == null:
		return
	if not is_instance_valid(_grabber) or not _grabber.alive or state != St.HIT:
		_grabber = null
		return
	global_position = _grabber.global_position + _grabber.forward() * (_grabber.radius + 0.8) + Vector3(0, 1.2, 0)
	velocity = Vector3.ZERO
	if state_t >= 0.85:
		var g := _grabber
		_grabber = null
		push = g.forward() * 14.0
		velocity.y = 7.0
		airborne_t = 0.9
		hp = maxf(1.0, hp - max_hp * 0.06)
		Fx.add_shake(0.7)
		Sfx.play("slam", -3.0, 1.2)


## Bursts out of a combo: a ring that throws the near ones back, a moment
## of safety, and a dash away. Only while being hit, and only when ready;
## a broken stance cannot be escaped this way.
func evasive() -> bool:
	if state != St.HIT or evasive_cd > 0.0 or not alive:
		return false
	evasive_cd = EVASIVE_CD
	_grabber = null
	_buffer = ""
	posture = maxf(0.0, posture - posture_max * 0.3)
	for a in place.enemies_alive():
		var to := flat_to(a.global_position)
		if to.length() < 3.6:
			a.push += to.normalized() * 7.0
			a.posture = minf(a.posture_max, a.posture + 6.0)
	Fx.ring(global_position + Vector3(0, 0.9, 0), Color(0.92, 0.9, 0.85), 0.3, 3.6, 0.3)
	Fx.add_shake(0.3)
	Sfx.play("evasive", -2.0)
	set_state(St.FREE)
	dash_cd_t = 0.0
	_start_dash()
	invuln = maxf(invuln, 0.45)
	place.note("dodge")
	return true


## The critical: a slow, red strike that no guard stops. A parry still can.
## Each kit swings it its own way.
func crit_move() -> Dictionary:
	var base := {"clip": "thrust", "startup": 0.42, "active": 0.1, "recover": 0.46, "dmg": 2.3, "reach": 3.2, "arc": 60.0, "lunge": 12.0, "posture": 34.0, "roll": 0.0, "knock": 8.0, "launch": 3.0, "sfx": "whoosh_heavy", "pitch": 0.8}
	match kit():
		"claw":
			base.merge({"clip": "heavy", "reach": 2.8, "arc": 160.0, "lunge": 14.0, "dmg": 2.1, "roll": 90.0}, true)
		"chain":
			base.merge({"reach": 6.5, "lunge": 4.0, "dmg": 2.0, "arc": 40.0, "pull": true}, true)
		"bow":
			base = {"clip": "cast", "type": "bolt", "count": 3, "spread": 9.0, "startup": 0.5, "active": 0.06, "recover": 0.4, "dmg": 1.5, "reach": 40.0, "arc": 10.0, "speed": 64.0, "posture": 18.0, "pierce": true, "sfx": "cast", "pitch": 0.75}
	var m := _timed(base)
	if String(m.get("type", "")) == "bolt":
		m["reach"] = float(base["reach"])
	m["kind"] = "heavy"
	m["heavy"] = true
	m["armor"] = true
	m["crit"] = true
	m["red"] = true
	m["blockable"] = false
	m["parryable"] = true
	m["dmg"] = float(stats["light_dmg"]) * float(base["dmg"]) * rel("dmg")
	return m


func try_crit() -> bool:
	if crit_cd > 0.0 or not alive:
		return false
	crit_cd = CRIT_CD
	combo_i = 0
	_begin(crit_move())
	# the tell, the same one enemies give: a red glint, a mark, a warning
	Fx.sparks(global_position + Vector3(0, rig.height * 0.75, 0) + forward() * radius, Color(1, 0.12, 0.1), 6, 3.0)
	Fx.word(center() + Vector3(0, rig.height * 0.55, 0), "!", Color(1, 0.15, 0.15), 1.1)
	Sfx.play("crit", -3.0)
	return true


func _near_body(knocked_only: bool) -> Enemy:
	var best: Enemy = null
	var best_d := 2.8
	for a in place.actors:
		if not is_instance_valid(a) or not (a is Enemy):
			continue
		var e: Enemy = a
		if e.is_boss or e.carried_by != null or e.thrown_t > 0.0:
			continue
		var ok_body := e.knocked and e.alive
		if not knocked_only:
			ok_body = ok_body or (not e.alive and e.remnant)
		if not ok_body:
			continue
		var d := flat_to(e.global_position).length() - e.radius
		if d < best_d:
			best_d = d
			best = e
	return best


## Grip: kneel over a knocked enemy and finish it, for more than a plain
## blow gives. Being hit breaks the grip.
func try_grip() -> bool:
	var e := _near_body(true)
	if e == null:
		return false
	face_now(flat_to(e.global_position))
	e.gripped = true
	e.gripped_by = self
	begin_busy("grip", 1.3, "kneel", _grip_done.bind(e.get_instance_id()))
	Fx.ring(e.global_position + Vector3(0, 0.1, 0), current_color(), 0.3, 1.6, 1.2)
	Sfx.play("guard", -4.0, 0.7)
	return true


func _grip_done(id: int) -> void:
	var o: Object = instance_from_id(id)
	if o == null or not is_instance_valid(o) or not (o as Enemy).knocked:
		return
	var e: Enemy = o
	e.knocked = false
	e.hp = 0.0
	e.die(self)
	gain_swell(20.0)
	heal(max_hp * 0.06)
	add_style(5.0, "grip")
	if place is Region and (place as Region).main != null:
		(place as Region).main.grant_essence(e.essence * 0.3)
	place.note("grip")
	Fx.pillar(e.global_position, current_color(), 10.0, 0.4, 0.6)
	Fx.hitstop(0.08)
	Fx.add_shake(0.4)
	Sfx.play("break", -3.0, 0.9)


func try_carry() -> bool:
	var e := _near_body(false)
	if e == null:
		return false
	carrying = e
	e.pick_up(self)
	return true


func drop_carried() -> void:
	if carrying != null and is_instance_valid(carrying):
		carrying.put_down()
	carrying = null


func throw_carried() -> void:
	if carrying == null or not is_instance_valid(carrying):
		carrying = null
		return
	var dir := cam_forward() if shift_locked() else forward()
	# aim at the nearest standing enemy ahead, never at the body in hand
	var best: Actor = null
	var best_d := 16.0
	for a in place.enemies_alive():
		if a == carrying or ((a is Enemy) and (a as Enemy).knocked):
			continue
		var to := flat_to(a.global_position)
		if to.length() < best_d and to.normalized().dot(dir) > 0.3:
			best_d = to.length()
			best = a
	if best != null:
		dir = flat_to(best.global_position).normalized()
		face_now(dir)
	rig.play("thrust", 0.04, 1.0, true)
	carrying.throw_from(self, dir)
	carrying = null
	place.note("swing")


func _tick_sense(delta: float) -> void:
	var want := intent.sense and alive and anima > 1.0
	if want and not sensing:
		Sfx.play("breath_in", -8.0, 1.3)
	sensing = want
	if not sensing:
		return
	anima = maxf(0.0, anima - SENSE_COST * delta)
	_sense_pulse -= delta
	if _sense_pulse <= 0.0:
		_sense_pulse = 1.2
		Fx.ring(global_position + Vector3(0, 0.2, 0), current_color(), 1.0, 14.0, 0.8)


## What spirit sense reads off an enemy: how it stands against you.
func threat_of(e: Enemy) -> String:
	var lv := soul.level if soul != null else 1
	if e.is_boss or e.level >= lv + 4:
		return "stronger"
	if e.level <= lv - 4:
		return "weaker"
	return "even"


## The race's own power. Returns true if it went off.
func try_race_art() -> bool:
	if soul == null or not soul.written() or not RACE_ARTS.has(soul.primary):
		if place != null:
			place.say("Your power has not woken yet.", "hint")
		return false
	var art := race_art()
	var tier := int(art["tier"])
	var ready := race_cd <= 0.0 or (int(art["charges"]) > 1 and race_charges > 0)
	if not ready or anima < float(art["cost"]):
		Sfx.play("ui_tick", -8.0, 0.7)
		return false
	match soul.primary:
		"vigil":
			var t := _art_target(12.0 * float(art["reach"]))
			if t == null:
				return false
			face_now(flat_to(t.global_position))
			begin_busy("bind", 0.35, "cast", _bind.bind(t.get_instance_id()))
			Sfx.play("cast", -3.0, 1.2)
		"maw":
			hide_t = 6.0 * float(art["dur"])
			rig.flash(1.0)
			Fx.ring(global_position + Vector3(0, 0.9, 0), Color(0.75, 0.75, 0.78), 0.4, 2.6, 0.4)
			Sfx.play("guard", -2.0, 0.6)
		"lumen":
			var dir := move_dir()
			if dir == Vector3.ZERO:
				dir = cam_forward() if shift_locked() else forward()
			_dash_dir = dir
			face_now(dir)
			_rail_hit.clear()
			begin_busy("rail", 0.33 * float(art["reach"]), "dash")
			invuln = maxf(invuln, 0.38)
			volley_t = 2.5
			Fx.ring(global_position + Vector3(0, 0.15, 0), current_color(), 0.3, 2.0, 0.3)
			Sfx.play("dash", -2.0, 1.3)
		"relic":
			var g := _art_target(20.0 * float(art["reach"]))
			if g == null:
				return false
			_grapple_to = g
			_chain_left = 1 if tier >= 3 else 0
			face_now(flat_to(g.global_position))
			begin_busy("grapple", 1.0, "thrust")
			Fx.sparks(g.center(), current_color(), 8, 6.0)
			Sfx.play("whoosh_heavy", -2.0, 1.3)
	if int(art["charges"]) > 1:
		race_charges = maxi(0, race_charges - 1)
		if race_cd <= 0.0:
			race_cd = float(art["cd"])
	else:
		race_cd = float(art["cd"])
	anima -= float(art["cost"])
	place.note("tech")
	_infuse(art)
	return true


## The power as this soul has it now: its stage, its infusion, its tuning
## and its own name.
func race_art() -> Dictionary:
	if soul == null or not RACE_ARTS.has(soul.primary):
		return {}
	var base: Dictionary = RACE_ARTS[soul.primary]
	var tier := 1
	if soul.grade <= 1:
		tier = 3
	elif soul.grade <= 3:
		tier = 2
	var hand := soul.profile.dominant()
	var tune: Dictionary = HAND_TUNE.get(hand, {})
	var inf := soul.secondary if soul.secondary != "" and soul.secondary != soul.primary else ""
	var word := String((AbilityForge.QUIRK.get(hand, {"word": ""}) as Dictionary)["word"])
	var nm := String(base["name"])
	if inf != "":
		nm = "%s %s" % [String(INFUSION[inf]), nm]
	if word != "":
		nm = "%s %s" % [word, nm]
	if tier > 1:
		nm += " " + String(ROMAN[tier])
	var out := {
		"name": nm, "short": String(base["short"]) + ("" if tier == 1 else " " + String(ROMAN[tier])),
		"tier": tier, "infusion": inf, "hand": hand, "hand_line": String(tune.get("line", "")),
		"cd": float(base["cd"]) * float(tune.get("cd", 1.0)), "cost": float(base["cost"]) * float(tune.get("cost", 1.0)),
		"dur": float(tune.get("dur", 1.0)), "reach": float(tune.get("reach", 1.0)), "dmg": float(tune.get("dmg", 1.0)),
		"posture": float(tune.get("posture", 1.0)), "heal": float(tune.get("heal", 0.0)),
		"charges": 2 if soul.primary == "lumen" and tier >= 2 else 1,
	}
	return out


func _tick_charges() -> void:
	var art := race_art()
	if art.is_empty() or int(art["charges"]) <= 1:
		race_charges = 1
		return
	if race_cd <= 0.0 and race_charges < int(art["charges"]):
		race_charges += 1
		if race_charges < int(art["charges"]):
			race_cd = float(art["cd"])


## When a promotion or a graft changes the power, say so.
func _note_art_change() -> void:
	var art := race_art()
	var nm := String(art.get("name", ""))
	if nm != "" and _art_name != "" and nm != _art_name and place != null:
		var why := "Fused with your second strain" if String(art["infusion"]) != "" and not _art_name.contains(String(INFUSION.get(art["infusion"], "~"))) else "A new form"
		place.say("Your power deepens|%s: %s" % [why, nm], "level")
		Sfx.play("release_charge", -6.0, 1.3)
	_art_name = nm


## What a grafted second strain adds to every use of the power.
func _infuse(art: Dictionary) -> void:
	if float(art["heal"]) > 0.0:
		heal(max_hp * float(art["heal"]))
	match String(art["infusion"]):
		"maw":
			heal(max_hp * 0.06)
			Fx.sparks(center(), Color(1.0, 0.15, 0.2), 8, 5.0)
		"lumen":
			var foes := place.enemies_alive()
			var shots := 0
			for e in foes:
				if shots >= 3 or e.global_position.distance_to(global_position) > 24.0:
					continue
				var origin := center() + Vector3(0, 0.6, 0)
				var dir := (e.center() - origin).normalized()
				place.fire(self, origin, dir, {"kind": "ranged", "type": "bolt", "dmg": float(stats["light_dmg"]) * 0.5, "posture": 5.0, "speed": 40.0, "reach": 30.0, "ranged": true, "home": e.get_instance_id(), "color": Strains.color_of("lumen", "")})
				shots += 1
		"vigil":
			sworn_t = 3.0
		"relic":
			for e in place.enemies_alive():
				var to := flat_to(e.global_position)
				if to.length() < 7.0 and to.length() > 1.5:
					e.push += -to.normalized() * 6.0
			Fx.ring(global_position + Vector3(0, 0.3, 0), Strains.color_of("relic", ""), 6.0, 1.0, 0.35)


## Iron Hide III: the hide ends in a roar that throws the near ones back.
func _hide_burst() -> void:
	for e in place.enemies_alive():
		var to := flat_to(e.global_position)
		if to.length() < 5.5:
			e.push += to.normalized() * 10.0
			e.posture = minf(e.posture_max, e.posture + 25.0)
	Fx.ring(global_position + Vector3(0, 0.5, 0), Color(0.9, 0.85, 0.8), 0.5, 5.5, 0.4)
	Fx.add_shake(0.6)
	Sfx.play("roar", -3.0, 1.2)


## The nearest standing enemy ahead within reach, for powers that need one.
func _art_target(reach: float) -> Actor:
	var best: Actor = null
	var best_d := reach
	var ahead := cam_forward() if shift_locked() else forward()
	for a in place.enemies_alive():
		if (a is Enemy) and (a as Enemy).knocked:
			continue
		var to := flat_to(a.global_position)
		if to.length() < best_d and (to.length() < 4.0 or to.normalized().dot(ahead) > 0.2):
			best_d = to.length()
			best = a
	return best


## Binding Art lands: rods of light about it, and it cannot move for a
## while. II binds two; III binds all near the first, and the rods burn.
func _bind(id: int) -> void:
	var o: Object = instance_from_id(id)
	if o == null or not is_instance_valid(o) or not (o as Actor).alive:
		return
	var first: Actor = o
	var art := race_art()
	var tier := int(art.get("tier", 1))
	var bound: Array = [first]
	if tier >= 2:
		var others: Array = []
		for a in place.enemies_alive():
			if a != first and a.global_position.distance_to(first.global_position) < (8.0 if tier >= 3 else 6.0):
				others.append(a)
		others.sort_custom(func(x: Actor, y: Actor) -> bool: return x.global_position.distance_to(first.global_position) < y.global_position.distance_to(first.global_position))
		for a: Variant in others.slice(0, 1 if tier == 2 else 4):
			bound.append(a)
	for b: Variant in bound:
		_bind_one(b as Actor, art, tier)


func _bind_one(e: Actor, art: Dictionary, tier: int) -> void:
	var boss := (e is Enemy) and (e as Enemy).is_boss
	var hold := (0.8 if boss else 2.0) * float(art.get("dur", 1.0))
	if tier >= 3:
		place.strike(self, e, {"kind": "tech", "dmg": float(stats["light_dmg"]) * 0.8 * float(art.get("dmg", 1.0)), "posture": 10.0, "blockable": false, "parryable": false, "color": Color(0.85, 0.9, 1.0)})
		if not e.alive:
			return
	e.set_state(St.BUSY, hold)
	e.velocity = Vector3.ZERO
	e.posture = minf(e.posture_max, e.posture + 20.0 * float(art.get("posture", 1.0)))
	e.rig.play("hit", 0.05, 1.0, true)
	var rods := Node3D.new()
	e.add_child(rods)
	var glow := ForgeMesh.glow(Color(0.85, 0.9, 1.0), 2.0)
	for k in range(6):
		var a := TAU * float(k) / 6.0
		var rod := ForgeMesh.inst(ForgeMesh.box(Vector3(0.12, 2.2, 0.12)), glow, rods, Vector3(cos(a) * (e.radius + 0.5), 1.1, sin(a) * (e.radius + 0.5)))
		rod.rotation.z = 0.35 * cos(a)
		rod.rotation.x = 0.35 * sin(a)
	get_tree().create_timer(hold, false).timeout.connect(rods.queue_free)
	Fx.ring(e.global_position + Vector3(0, 0.2, 0), Color(0.85, 0.9, 1.0), 0.4, e.radius + 1.2, 0.4)
	Sfx.play("seal", -2.0, 1.2)


## Regrowth: a Devourer out of the fight knits back, slowly.
func _tick_regrowth(delta: float) -> void:
	if soul == null or not alive or hp >= max_hp:
		return
	var k := 1.0 if soul.primary == "maw" else (0.5 if soul.secondary == "maw" else 0.0)
	if k > 0.0 and _since_hurt > 5.0:
		heal(max_hp * 0.015 * k * delta)


func shift_locked() -> bool:
	return shift_lock and not scripted


## The last hit of a string, three ways, as these games do it: on the
## ground it knocks them flying; holding jump it launches them and you go
## up after them; in the air it slams them down.
func _finisher(m: Dictionary, how: String) -> Dictionary:
	m["finisher"] = how
	m["posture"] = float(m["posture"]) + 8.0
	match how:
		"out":
			m["knock"] = 13.0
			m["launch"] = 4.5
			m["dmg"] = float(m["dmg"]) * 1.2
		"up":
			m["clip"] = "rise"
			m["knock"] = 0.8
			m["launch"] = 12.0
			m["arc"] = 120.0
		"down":
			m["clip"] = "slam"
			m["knock"] = 3.0
			m["dmg"] = float(m["dmg"]) * 1.35
			m["reach"] = 3.2
			m["arc"] = 200.0
			velocity.y = -14.0
	return m


func _begin(m: Dictionary) -> void:
	var ranged := String(m.get("type", "")) == "bolt"
	var t := _attack_target(30.0 if ranged else 7.0)
	if t != null:
		face_now(flat_to(t.global_position))
		if ranged:
			m["home"] = t.get_instance_id()
	elif shift_locked():
		face_now(cam_forward())
	elif move_dir() != Vector3.ZERO:
		face_now(move_dir())
	start_attack(m)


# -------------------------------------------------------------- executions

## An enemy whose stance is broken, close and roughly in front.
func _broken_near() -> Enemy:
	var best: Enemy = null
	var best_d := 3.6
	for a in place.enemies_alive():
		if a.state != St.STAGGER:
			continue
		var d := flat_to(a.global_position).length() - a.radius
		if d < best_d:
			best_d = d
			best = a as Enemy
	return best


## The heavy button on a broken enemy: one great cut that nothing guards.
func _execute(e: Enemy) -> void:
	face_now(flat_to(e.global_position))
	var dmg := float(stats["heavy_dmg"]) * 3.2 * rel("dmg")
	if e.is_boss:
		dmg = maxf(dmg, e.max_hp * 0.07)
	var m := {"clip": "heavy", "startup": 0.16, "active": 0.1, "recover": 0.42, "dmg": dmg, "reach": 4.2 * maxf(1.0, e.reach_scale * 0.6),
		"arc": 140.0, "lunge": 0.0, "posture": 0.0, "roll": 90.0, "heavy": true, "blockable": false, "parryable": false, "armor": true,
		"knock": 8.0, "kind": "heavy", "execution": true, "color": current_color(), "sfx": "whoosh_heavy", "pitch": 0.7}
	invuln = 0.75
	start_attack(m)
	Fx.add_blur(0.8)


func _start_dash() -> void:
	var dir := move_dir()
	if dir == Vector3.ZERO:
		dir = -forward()
	else:
		face_now(dir)
	_dash_dir = dir
	if not is_on_floor():
		_air_dashes += 1
		_air_dash = _air_dashes >= (2 if kit() == "bow" else 1)
		velocity.y = maxf(velocity.y, 6.0 if kit() == "bow" else 1.5)
	dash_cd_t = float(stats["dash_cd"]) * (0.7 if kit() == "chain" else 1.0)
	_rend_from = global_position
	if soul != null and soul.written() and (soul.primary == "vigil" or soul.secondary == "vigil") and not released:
		_flash_step(dir)
		return
	set_state(St.DASH, 0.2)
	invuln = 0.2
	dash_age = 0.0
	collision_mask = 1
	_ghost_t = 0.0
	rig.play("dash", 0.04, 1.0, true)
	Sfx.play("dash", -4.0)
	Fx.add_blur(0.8)
	Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.5), 6, 0.5)


## The Reaper's dash: no run at all. You are simply somewhere else.
func _flash_step(dir: Vector3) -> void:
	var from := global_position
	var to := from + dir * 9.0
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1.0, 0), to + Vector3(0, 1.0, 0), 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		to = (hit["position"] as Vector3) - dir * 0.7 - Vector3(0, 1.0, 0)
	to.y = maxf(to.y, place.height_at(to.x, to.z) + 0.05)
	Fx.ghost(rig, current_color().lerp(Color(1, 1, 1), 0.4), 0.45)
	Fx.puff(from, Color(0.85, 0.9, 1.0, 0.5), 8, 0.5)
	global_position = to
	set_state(St.DASH, 0.12)
	invuln = 0.26
	dash_age = 0.0
	collision_mask = 1
	velocity = Vector3(dir.x * 4.0, velocity.y, dir.z * 4.0)
	rig.play("dash", 0.02, 1.0, true)
	Sfx.play("slip", -4.0, 1.4)
	Fx.ring(to + Vector3(0, 0.1, 0), current_color(), 0.3, 2.2, 0.25)
	Fx.add_blur(1.0)


func _tick_dash(delta: float) -> void:
	if state_len <= 0.13:
		if state_t >= state_len:
			collision_mask = 1 | 2
			set_state(St.FREE)
			rig.play(idle_clip(), 0.12)
		return
	var dash_speed := 30.0 if kit() == "bow" else 25.0
	velocity.x = _dash_dir.x * dash_speed
	velocity.z = _dash_dir.z * dash_speed
	_ghost_t -= delta
	if _ghost_t <= 0.0:
		_ghost_t = 0.055
		Fx.ghost(rig, current_color().lerp(Color(0.45, 0.65, 1.0), 0.5))
	if state_t >= state_len:
		collision_mask = 1 | 2
		velocity.x *= 0.3
		velocity.z *= 0.3
		set_state(St.FREE)
		rig.play(idle_clip(), 0.15)
		if kit() == "claw":
			_rend(_rend_from, global_position)


## The Devourer's dash tears at everything it passes.
func _rend(from: Vector3, to: Vector3) -> void:
	for a in place.enemies_alive():
		var c := a.global_position
		var near := Geometry3D.get_closest_point_to_segment(c, from, to)
		if near.distance_to(c) <= a.radius + 1.4:
			place.strike(self, a, {"kind": "light", "dmg": float(stats["light_dmg"]) * 0.8, "posture": 8.0, "from": from, "color": current_color()})
			Fx.slash(Transform3D(Basis(Vector3.UP, rotation.y + randf_range(-0.6, 0.6)) * Basis(Vector3.FORWARD, randf_range(-1.0, 1.0)), a.center()), 2.0, 140.0, Color(1, 0.2, 0.25), 0.25, 0.7)


func _toggle_lock() -> void:
	if lock_target != null:
		lock_target = null
		return
	lock_target = place.nearest_enemy(global_position, 26.0, cam_forward(), 0.3)
	if lock_target == null:
		lock_target = place.nearest_enemy(global_position, 14.0)
	if lock_target != null:
		Sfx.play("ui_tick", -8.0)


# -------------------------------------------------------------- techniques

func technique(slot: int) -> Dictionary:
	if slot < 0 or slot >= soul.loadout.size():
		return {}
	var idx := int(soul.loadout[slot])
	if idx < 0 or idx >= soul.techniques.size():
		return {}
	return soul.techniques[idx]


func use_tech(slot: int) -> bool:
	var t := technique(slot)
	if t.is_empty():
		return false
	if tech_cd[slot] > 0.0:
		return false
	var cost := float(t["cost"]) * float(stats.get("tech_cost", 1.0))
	if anima < cost:
		place.say("Not enough spirit energy.", "hint")
		return false
	anima -= cost
	tech_cd[slot] = float(t["cd"]) * float(stats.get("tech_cd", 1.0))
	place.note("tech")
	var dmg := float(t["dmg"]) * float(stats["tech_dmg"]) * rel("dmg") * float((stats.get("tech_kind", {}) as Dictionary).get(String(t.get("kind", "")), 1.0))
	if hp < max_hp * 0.5:
		dmg *= float(t.get("low_hp", 1.0))
	var reach := float(t.get("reach", 1.0))
	var base := {"kind": "tech", "dmg": dmg, "posture": float(t["posture"]) * float(stats["posture_dmg"]),
		"steal": float(t.get("steal", 0.0)), "color": current_color(), "active": 0.1}
	var target := _attack_target(16.0)
	if target != null:
		face_now(flat_to(target.global_position))
	elif move_dir() != Vector3.ZERO:
		face_now(move_dir())
	match String(t["kind"]):
		"sever":
			_sever_from = global_position
			_dash_dir = forward()
			move = base
			move["reach_len"] = 7.5 * reach
			set_state(St.BUSY, 0.17)
			busy_kind = "sever"
			invuln = 0.22
			dash_age = 0.0
			collision_mask = 1
			rig.play("dash", 0.03, 1.0, true)
			Sfx.play("sever", -2.0)
			Fx.add_blur(1.0)
		"rise":
			base.merge({"clip": "rise", "startup": 0.18, "recover": 0.36, "reach": 2.8 * reach, "arc": 110.0, "roll": -80.0,
				"launch": 11.0, "heavy": true, "lunge": 4.0, "sfx": "whoosh_heavy"})
			start_attack(base)
		"lance":
			base.merge({"clip": "cast", "type": "bolt", "startup": 0.2, "recover": 0.3, "reach": 30.0, "arc": 10.0, "speed": 38.0 * reach, "ranged": true, "sfx": "cast"})
			if target != null:
				base["home"] = target.get_instance_id()
			start_attack(base)
		"toll":
			base.merge({"clip": "slam", "type": "ring", "startup": 0.3, "recover": 0.45, "reach": 5.2 * reach, "arc": 360.0, "heavy": true, "knock": 6.0, "sfx": "toll"})
			start_attack(base)
		"guard":
			move = base
			counter_t = 0.95
			set_state(St.BUSY, 0.95)
			busy_kind = "guard"
			rig.play("block", 0.05, 1.0, true)
			Fx.ring(global_position + Vector3(0, 0.1, 0), current_color(), 2.4, 0.9, 0.9)
			Sfx.play("guard", -4.0)
		"gnash":
			base.merge({"clip": "thrust", "startup": 0.2, "recover": 0.4, "reach": 2.6, "arc": 70.0, "lunge": 15.0 * reach, "roll": 0.0, "sfx": "whoosh_heavy"})
			start_attack(base)
		"grave":
			base["steal"] = 0.4
			move = base
			counter_t = 1.2
			set_state(St.BUSY, 1.2)
			busy_kind = "guard"
			rig.play("block", 0.05, 1.0, true)
			Fx.ring(global_position + Vector3(0, 0.1, 0), Color(0.9, 0.15, 0.2), 2.8, 0.9, 1.1)
			Sfx.play("guard", -2.0, 0.8)
		"star":
			velocity.y = 9.0
			base.merge({"clip": "slam", "type": "starfall", "startup": 0.5, "recover": 0.45, "reach": 5.5 * reach, "arc": 360.0, "heavy": true, "knock": 7.0, "sfx": "special"})
			start_attack(base)
		"exhibit":
			base.merge({"clip": "cast", "type": "exhibit", "startup": 0.3, "recover": 0.4, "reach": 8.0 * reach, "arc": 360.0, "sfx": "toll"})
			start_attack(base)
		"blacksun":
			base.merge({"clip": "cast", "type": "blacksun", "startup": 0.35, "recover": 0.45, "reach": 9.0 * reach, "arc": 360.0, "sfx": "special"})
			start_attack(base)
		"worship":
			base.merge({"clip": "release", "type": "worship", "startup": 0.3, "recover": 0.5, "reach": 14.0 * reach, "arc": 360.0, "sfx": "rest"})
			start_attack(base)
		"orbit":
			base.merge({"clip": "cast", "type": "orbit", "startup": 0.25, "recover": 0.35, "reach": 30.0, "arc": 360.0, "ranged": true, "sfx": "cast"})
			start_attack(base)
	return true


func _finish_sever() -> void:
	collision_mask = 1 | 2
	var to := global_position
	var count := 0
	for a in place.enemies_alive():
		var c := a.global_position
		var near := Geometry3D.get_closest_point_to_segment(c, _sever_from, to)
		if near.distance_to(c) <= a.radius + 1.7:
			var m := move.duplicate()
			m["from"] = _sever_from
			place.strike(self, a, m)
			var t := Transform3D(Basis(Vector3.UP, rotation.y + randf_range(-0.6, 0.6)) * Basis(Vector3.FORWARD, randf_range(-1.0, 1.0)), a.center())
			Fx.slash(t, 2.6, 170.0, current_color(), 0.3, 0.9)
			count += 1
	velocity.x *= 0.15
	velocity.z *= 0.15
	set_state(St.HIT, 0.22)
	rig.play_clip(Poses.attack("light1", 0.01, 0.02, 0.2), 0.03)


# ----------------------------------------------------------------- release

func try_release() -> void:
	if soul.release.is_empty():
		place.say("Your blade has no name yet.", "hint")
		return
	if released:
		_special()
		return
	if swell < 100.0:
		place.say("Your spirit pressure is not full.", "hint")
		return
	_release_burst = false
	_unbroken_used = false
	set_state(St.BUSY, 1.9)
	busy_kind = "release"
	invuln = 2.1
	velocity = Vector3.ZERO
	rig.play("release", 0.1, 1.0, true)
	Sfx.play("release_charge", 0.0)
	place.say("%s %s." % [String(soul.release["call"]), String(soul.release["spirit"])], "release")
	var col := AbilityForge.color_of(soul.release)
	Fx.ring(global_position + Vector3(0, 0.1, 0), col, 9.0, 0.6, 0.85)


func _burst_release() -> void:
	released = true
	swell = 100.0
	accent = current_color()
	_equip()
	refresh_stats()
	var col := accent
	Sfx.play("release", 2.0)
	Fx.pillar(global_position, col, 40.0, 2.2, 1.4)
	Fx.ring(global_position + Vector3(0, 0.2, 0), col, 0.5, 16.0, 0.7)
	Fx.ring(global_position + Vector3(0, 1.0, 0), Color(1, 1, 1), 0.5, 10.0, 0.5, 0.92)
	Fx.sparks(center(), col, 40, 16.0)
	Fx.screen_flash(col.lerp(Color(1, 1, 1), 0.5), 0.6)
	Fx.add_shake(1.0)
	Fx.add_blur(1.0)
	Fx.hitstop(0.16)
	for a in place.enemies_alive():
		if flat_to(a.global_position).length() < 8.0:
			place.strike(self, a, {"kind": "release", "dmg": float(stats["heavy_dmg"]) * 0.6, "posture": 30.0, "heavy": true, "knock": 9.0, "color": col, "parryable": false, "blockable": false})


func _seal() -> void:
	released = false
	swell = 0.0
	accent = current_color()
	_equip()
	refresh_stats()
	Sfx.play("seal", -4.0)
	Fx.ring(center(), Color(0.8, 0.8, 0.85), 2.0, 0.3, 0.4)
	place.say("The name goes quiet.", "hint")


func _special() -> void:
	var sp: Dictionary = soul.release.get("special", {})
	if sp.is_empty() or special_t > 0.0:
		return
	var cost := float(sp["cost"])
	if swell < cost:
		place.say("Not enough spirit pressure left.", "hint")
		return
	swell -= cost
	special_t = 1.2
	var col := current_color()
	var dmg := float(stats["heavy_dmg"]) * float(sp["dmg"])
	var base := {"kind": "tech", "dmg": dmg, "posture": 30.0, "color": col, "heavy": true, "active": 0.12, "special": true}
	var target := _attack_target(20.0)
	if target != null:
		face_now(flat_to(target.global_position))
	Sfx.play("special", 0.0)
	Fx.screen_flash(col, 0.18)
	match String(sp["type"]):
		"counter":
			move = base
			counter_t = 1.5
			set_state(St.BUSY, 1.5)
			busy_kind = "guard"
			rig.play("block", 0.05, 1.0, true)
			Fx.ring(global_position + Vector3(0, 0.1, 0), col, 3.4, 1.0, 1.4)
		"wave":
			base.merge({"clip": "heavy", "startup": 0.3, "recover": 0.4, "reach": 13.0, "arc": 34.0, "roll": 90.0, "knock": 9.0, "sfx": "whoosh_heavy"})
			start_attack(base)
		"volley":
			base.merge({"clip": "cast", "type": "volley", "startup": 0.2, "recover": 0.35, "reach": 30.0, "arc": 10.0, "ranged": true, "heavy": false, "posture": 12.0, "sfx": "cast"})
			start_attack(base)
		"pyre":
			base.merge({"clip": "slam", "type": "ring", "startup": 0.25, "recover": 0.4, "reach": 6.5, "arc": 360.0, "steal": 0.3, "sfx": "toll"})
			start_attack(base)
		"blink":
			_blink_target = target.get_instance_id() if target != null else 0
			if target != null:
				var behind := target.global_position - target.forward() * (target.radius + 1.6)
				Fx.ghost(rig, col, 0.5)
				global_position = Vector3(behind.x, place.height_at(behind.x, behind.z) + 0.05, behind.z)
				face_now(flat_to(target.global_position))
			else:
				Fx.ghost(rig, col, 0.5)
				global_position += forward() * 8.0
			Fx.add_blur(1.0)
			base.merge({"clip": "light2", "startup": 0.08, "recover": 0.3, "reach": 3.2, "arc": 200.0, "roll": -10.0})
			start_attack(base)
		"ward":
			ward_t = 3.5
			base.merge({"clip": "slam", "type": "ring", "startup": 0.2, "recover": 0.3, "reach": 5.5, "arc": 360.0, "knock": 10.0, "sfx": "toll"})
			start_attack(base)


func _strike() -> void:
	var col := current_color()
	match String(move.get("type", "strike")):
		"starfall":
			Fx.pillar(global_position, col, 18.0, 1.2, 0.8)
			Fx.ring(global_position + Vector3(0, 0.2, 0), col, 0.5, float(move["reach"]), 0.45)
			Fx.add_shake(0.6)
			place.sweep(self, move)
			_fan_bolts(4, 0.35, 0.6)
			return
		"exhibit":
			Fx.ring(global_position + Vector3(0, 0.2, 0), col, float(move["reach"]), 0.6, 0.6)
			for a in place.enemies_alive():
				if flat_to(a.global_position).length() <= float(move["reach"]):
					a.posture = minf(a.posture_max - 1.0, a.posture + a.posture_max * 0.5)
					a.posture_rest = 3.0
					a.apply_effect("slow", 1.6, self)
					a.rig.flash(0.8)
			place.sweep(self, move)
			return
		"blacksun":
			Fx.ring(global_position + Vector3(0, 1.0, 0), Color(0.08, 0.02, 0.12), float(move["reach"]), 0.4, 0.8, 0.5)
			Fx.sparks(center(), Color(0.6, 0.2, 0.9), 24, 10.0)
			for a in place.enemies_alive():
				var d := flat_to(a.global_position)
				if d.length() <= float(move["reach"]):
					a.push += -d.normalized() * minf(d.length() * 2.0, 14.0)
					a.apply_effect("dot", 1.6, self)
			place.sweep(self, move)
			return
		"worship":
			heal(max_hp * 0.2)
			ward_t = 4.0
			Fx.pillar(global_position, Color(1.0, 0.85, 0.5), 20.0, 1.0, 1.0)
			for a in place.enemies_alive():
				if flat_to(a.global_position).length() <= float(move["reach"]):
					(a as Enemy).wake(self)
					a.face_now(a.flat_to(global_position))
			place.sweep(self, move)
			return
		"orbit":
			_fan_bolts(8, 0.6, 1.0, TAU / 8.0)
			return
	if String(move.get("type", "strike")) == "volley":
		var targets := place.enemies_alive()
		var origin := global_position + Vector3(0, rig.height * 0.8, 0)
		for i in range(5):
			var m := move.duplicate()
			m["dmg"] = float(move["dmg"]) * 0.45
			m["speed"] = 24.0
			if targets.size() > 0:
				m["home"] = targets[i % targets.size()].get_instance_id()
			var spread := Basis(Vector3.UP, rotation.y + deg_to_rad(-50.0 + 25.0 * float(i))) * Vector3(0, 0.5, -1)
			place.fire(self, origin, spread, m)
		return
	super._strike()
	if released and String(soul.release.get("scar", "")) == "far-sight" and String(move.get("kind", "")) == "light":
		var origin := global_position + Vector3(0, rig.height * 0.6, 0) + forward() * 0.8
		place.fire(self, origin, forward(), {"kind": "ranged", "dmg": float(move["dmg"]) * 0.5, "posture": 5.0, "speed": 30.0, "color": current_color()})


## Bolts thrown in a fan or a full ring, each turning to hunt the nearest
## enemy to where it was aimed.
func _fan_bolts(count: int, dmg_scale: float, rise: float, step: float = 0.45) -> void:
	var origin := global_position + Vector3(0, rig.height * 0.8, 0)
	var targets := place.enemies_alive()
	for i in range(count):
		var m := move.duplicate()
		m["type"] = "bolt"
		m["kind"] = "ranged"
		m["dmg"] = float(move["dmg"]) * dmg_scale
		m["speed"] = 22.0
		var dir := Basis(Vector3.UP, rotation.y + step * (float(i) - float(count - 1) * 0.5)) * Vector3(0, rise, -1)
		if targets.size() > 0:
			var best: Actor = targets[0]
			var best_d := 9999.0
			for t in targets:
				var dd := (t.global_position - (global_position + dir * 6.0)).length()
				if dd < best_d:
					best_d = dd
					best = t
			m["home"] = best.get_instance_id()
		place.fire(self, origin, dir, m)


func _aim_dir(origin: Vector3) -> Vector3:
	if move.has("home"):
		var t: Object = instance_from_id(int(move["home"]))
		if t != null and is_instance_valid(t):
			return ((t as Actor).center() - origin).normalized()
	return forward()


# -------------------------------------------------------------- busy states

func begin_busy(kind: String, length: float, clip: String, done: Callable = Callable()) -> void:
	set_state(St.BUSY, length)
	busy_kind = kind
	_busy_done = done
	velocity.x = 0.0
	velocity.z = 0.0
	if clip != "":
		rig.play(clip, 0.2, 1.0, true)


func end_busy() -> void:
	if state == St.BUSY:
		busy_kind = ""
		set_state(St.FREE)
		rig.play(idle_clip(), 0.25)


func _tick_busy(delta: float) -> void:
	match busy_kind:
		"grapple":
			if _grapple_to == null or not is_instance_valid(_grapple_to) or not _grapple_to.alive:
				_grapple_to = null
				end_busy()
				return
			var to := _grapple_to.global_position - global_position
			var flat := Vector3(to.x, 0, to.z)
			if flat.length() < _grapple_to.radius + 1.6 or state_t >= state_len:
				var t := _grapple_to
				_grapple_to = null
				end_busy()
				face_now(flat.normalized())
				var art := race_art()
				place.strike(self, t, {"kind": "heavy", "dmg": float(stats["light_dmg"]) * 1.3 * float(art.get("dmg", 1.0)), "posture": 18.0 * float(art.get("posture", 1.0)), "knock": 4.0, "heavy": true, "color": current_color()})
				if int(art.get("tier", 1)) >= 2 and is_instance_valid(t) and t.alive:
					t.set_state(St.BUSY, 1.0)
				if _chain_left > 0:
					_chain_left -= 1
					var next: Actor = null
					var nd := 10.0
					for e in place.enemies_alive():
						if e != t and e.global_position.distance_to(global_position) < nd:
							nd = e.global_position.distance_to(global_position)
							next = e
					if next != null:
						_grapple_to = next
						begin_busy("grapple", 0.8, "thrust")
						Sfx.play("whoosh_heavy", -4.0, 1.4)
				return
			velocity = flat.normalized() * 34.0 + Vector3(0, maxf(0.0, to.y) * 2.0, 0)
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.04
				Fx.ghost(rig, current_color())
			return
		"rail":
			velocity.x = _dash_dir.x * 36.0
			velocity.z = _dash_dir.z * 36.0
			if int(race_art().get("tier", 1)) >= 3:
				for e in place.enemies_alive():
					if not _rail_hit.has(e) and e.global_position.distance_to(global_position) < 2.2:
						_rail_hit.append(e)
						place.strike(self, e, {"kind": "tech", "dmg": float(stats["light_dmg"]) * 1.2 * float(race_art()["dmg"]), "posture": 12.0, "color": current_color(), "blockable": false})
			velocity.y = maxf(velocity.y, 0.0)
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.03
				Fx.ghost(rig, current_color())
			if state_t >= state_len:
				velocity.x *= 0.3
				velocity.z *= 0.3
				end_busy()
			return
		"sever":
			velocity.x = _dash_dir.x * float(move["reach_len"]) / 0.17
			velocity.z = _dash_dir.z * float(move["reach_len"]) / 0.17
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.03
				Fx.ghost(rig, current_color())
			if state_t >= state_len:
				_finish_sever()
		"guard":
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
			if state_t >= state_len:
				counter_t = 0.0
				end_busy()
		"release":
			velocity.x = 0.0
			velocity.z = 0.0
			if not _release_burst and state_t >= 0.95:
				_release_burst = true
				_burst_release()
			if state_t >= state_len:
				end_busy()
		"meditate":
			velocity.x = 0.0
			velocity.z = 0.0
		_:
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
			if state_len > 0.0 and state_t >= state_len:
				var cb := _busy_done
				_busy_done = Callable()
				end_busy()
				if cb.is_valid():
					cb.call()


# ----------------------------------------------------------------- results

func gain_swell(amount: float) -> void:
	if soul.release.is_empty():
		return
	swell = minf(100.0, swell + amount * float(stats["swell_gain"]) * (0.5 if released else 1.0))


func on_dealt(defender: Actor, m: Dictionary, res: Dictionary, died: bool) -> void:
	var outcome := String(res["outcome"])
	var dmg := float(res["dmg"])
	if bool(m.get("pull", false)) and (outcome == "hit" or outcome == "blocked") and is_instance_valid(defender):
		var to := flat_to(defender.global_position)
		var k := 0.3 if (defender as Enemy) != null and (defender as Enemy).is_boss else 1.0
		defender.push += -to.normalized() * maxf(0.0, to.length() - 1.8) * 3.4 * k
		Fx.sparks(defender.center(), current_color(), 10, 6.0)
	if bool(m.get("execution", false)) and outcome == "hit":
		Fx.word(defender.center() + Vector3(0, 1.4, 0), "EXECUTION", Color(1.0, 0.85, 0.4), 1.4)
		Fx.screen_flash(current_color().lerp(Color(1, 1, 1), 0.5), 0.4)
		Fx.hitstop(0.22)
		Fx.add_shake(1.0)
		Fx.pillar(defender.global_position, current_color(), 12.0, 0.8, 0.6)
		Sfx.play("break", 0.0, 0.6)
		add_style(8.0, "execution")
	if outcome == "hit" and m.has("finisher") and is_instance_valid(defender):
		match String(m["finisher"]):
			"out":
				Fx.hitstop(0.09)
				Fx.add_shake(0.5)
				Sfx.play("finisher", -2.0)
				Fx.puff(defender.global_position, Color(0.85, 0.85, 0.88, 0.5), 8, 0.6)
			"up":
				velocity.y = 11.0
				_air_hits = 0
				Fx.hitstop(0.06)
				Sfx.play("whoosh_heavy", -4.0, 1.2)
			"down":
				defender.velocity.y = -18.0
				Fx.hitstop(0.1)
				Fx.add_shake(0.8)
				Fx.ring(defender.global_position + Vector3(0, 0.2, 0), current_color(), 0.5, 4.5, 0.35)
				Sfx.play("slam", -3.0, 1.1)
		add_style(1.5, "finisher")
	if outcome == "hit" and not is_on_floor():
		# a hit in the air buys back an air dash and the second jump: juggles
		_air_dash = false
		_air_dashes = 0
		air_jumps = 1
	if outcome == "hit":
		add_style(1.0, String(m.get("kind", "")))
		if died:
			add_style(2.0, "kill")
		gain_swell(9.0 if bool(m.get("heavy", false)) else 4.5)
		anima = minf(max_anima, anima + 2.0)
		var steal := float(m.get("steal", 0.0))
		if steal > 0.0:
			heal(dmg * steal)
		if released and String(m.get("kind", "")) != "release":
			_apply_aspect(defender, dmg)
		_apply_runes(defender, dmg)
	if died and released and String(soul.release.get("scar", "")) == "long-hunger":
		swell = minf(100.0, swell + 25.0)


## The runes set into your gear, on every clean hit.
func _apply_runes(defender: Actor, dmg: float) -> void:
	if runes.is_empty() or not is_instance_valid(defender):
		return
	if runes.has("leech"):
		heal(dmg * float(runes["leech"]))
	if not defender.alive:
		return
	if runes.has("ember") and _rune_rng.randf() < float(runes["ember"]):
		defender.apply_effect("dot", 1.0, self)
		Fx.sparks(defender.center(), Color(1.0, 0.45, 0.12), 8, 4.0)
	if runes.has("frost") and _rune_rng.randf() < float(runes["frost"]):
		defender.apply_effect("slow", 1.0, self)
		Fx.sparks(defender.center(), Color(0.6, 0.9, 1.0), 8, 3.0)
	if runes.has("storm") and _rune_rng.randf() < float(runes["storm"]):
		var other: Actor = null
		var best := 7.0
		for a in place.enemies_alive():
			if a == defender:
				continue
			var d := a.global_position.distance_to(defender.global_position)
			if d < best:
				best = d
				other = a
		if other != null:
			other.hp = maxf(1.0, other.hp - dmg * 0.35)
			other.rig.flash(0.8)
			Fx.sparks(other.center(), Color(0.75, 0.8, 1.0), 12, 6.0)
			Sfx.play("spark", 0.0, 0.4)


func _apply_aspect(defender: Actor, dmg: float) -> void:
	if not is_instance_valid(defender) or not defender.alive:
		return
	var p := float(soul.release.get("effect_power", 1.0))
	match String(soul.release.get("effect", "")):
		"dot", "slow", "weaken":
			defender.apply_effect(String(soul.release["effect"]), p, self)
		"knock":
			defender.push += -defender.flat_to(global_position).normalized() * 3.5 * p
			defender.posture = minf(defender.posture_max, defender.posture + 5.0 * p)
		"posture":
			defender.posture = minf(defender.posture_max, defender.posture + 7.0 * p)
			defender.posture_rest = 2.5
			if defender.posture >= defender.posture_max and defender.state != St.STAGGER:
				defender.break_stance()
		"lifesteal":
			heal(dmg * 0.09 * p)
		"chain":
			var other: Actor = null
			var best := 7.0
			for a in place.enemies_alive():
				if a == defender:
					continue
				var d := a.global_position.distance_to(defender.global_position)
				if d < best:
					best = d
					other = a
			if other != null:
				other.hp = maxf(1.0, other.hp - dmg * 0.35 * p)
				other.rig.flash(0.8)
				Fx.sparks(other.center(), current_color(), 8, 8.0)
				Fx.ring(other.center(), current_color(), 0.2, 1.4, 0.2)


# ------------------------------------------------------------------ style

const STYLE_RANKS: Array = [["SS", 110.0], ["S", 75.0], ["A", 50.0], ["B", 30.0], ["C", 15.0], ["D", 5.0]]


## Fighting well and fighting variously raises the rank; getting hit drops it.
func add_style(amount: float, kind: String) -> void:
	var gain := amount
	if kind != "" and not _recent_kinds.has(kind):
		gain += 1.5
	_recent_kinds.append(kind)
	if _recent_kinds.size() > 3:
		_recent_kinds.pop_front()
	if amount <= 2.0 and kind != "kill":
		combo_hits += 1
	style_pts = minf(130.0, style_pts + gain)
	_style_idle = 0.0


func style_rank() -> String:
	for r: Variant in STYLE_RANKS:
		if style_pts >= float((r as Array)[1]):
			return String((r as Array)[0])
	return ""


func style_index() -> int:
	var r := style_rank()
	for i in range(STYLE_RANKS.size()):
		if String(STYLE_RANKS[i][0]) == r:
			return STYLE_RANKS.size() - i
	return 0


func receive(res: Dictionary, attacker: Actor, m: Dictionary) -> bool:
	if bool(m.get("grab", false)) and String(res["outcome"]) == "hit" and is_instance_valid(attacker):
		var died := super.receive(res, attacker, m)
		if not died and alive:
			_grabbed(attacker)
		return died
	if String(res["outcome"]) == "hit" and float(res["dmg"]) > 0.0:
		_since_hurt = 0.0
		if hide_t > 0.0:
			# Iron Hide: less harm, no flinch; from II, a share goes back
			res = res.duplicate()
			if int(race_art().get("tier", 1)) >= 2 and attacker != null and is_instance_valid(attacker) and attacker.alive:
				attacker.hp = maxf(1.0, attacker.hp - float(res["dmg"]) * 0.3)
				attacker.rig.flash(0.6)
			res["dmg"] = float(res["dmg"]) * 0.6
			res["stagger"] = false
			Fx.sparks(center(), Color(0.7, 0.7, 0.72), 6, 5.0)
		style_pts *= 0.4
		combo_hits = 0
		if carrying != null:
			drop_carried()
	if runes.has("ward") and float(res.get("dmg", 0.0)) > 0.0:
		res = res.duplicate()
		res["dmg"] = float(res["dmg"]) * (1.0 - minf(0.5, float(runes["ward"])))
	return super.receive(res, attacker, m)


func on_parry(attacker: Actor, _m: Dictionary) -> void:
	add_style(3.0, "parry")
	gain_swell(14.0)
	riposte_t = 0.9
	anima = minf(max_anima, anima + 6.0)
	if released and String(soul.release.get("scar", "")) == "tollbreaker":
		Fx.ring(global_position + Vector3(0, 0.3, 0), current_color(), 0.5, 5.0, 0.35)
		for a in place.enemies_alive():
			if flat_to(a.global_position).length() < 5.0:
				a.parried_by(self, 22.0)
	if counter_t > 0.0 and state == St.BUSY and busy_kind == "guard" and is_instance_valid(attacker):
		counter_t = 0.0
		face_now(flat_to(attacker.global_position))
		var m := move.duplicate()
		m.merge({"clip": "light2", "startup": 0.07, "recover": 0.3, "reach": 3.4, "arc": 160.0, "roll": -8.0, "heavy": true, "knock": 7.0}, true)
		start_attack(m)


func on_perfect_dodge(_attacker: Actor) -> void:
	add_style(2.5, "slip")
	gain_swell(8.0)
	Fx.add_blur(0.9)
	if released and String(soul.release.get("scar", "")) == "afterstep":
		var at := global_position - _dash_dir * 2.0
		for a in place.enemies_alive():
			if a.global_position.distance_to(at) < 3.4:
				place.strike(self, a, {"kind": "light", "dmg": float(stats["light_dmg"]) * 1.2, "posture": 10.0, "color": current_color(), "from": at})
		Fx.slash(Transform3D(Basis(Vector3.UP, rotation.y), at + Vector3(0, 1.0, 0)), 3.0, 300.0, current_color(), 0.3, 0.9)


func _survive_lethal() -> bool:
	if released and String(soul.release.get("scar", "")) == "unbroken" and not _unbroken_used:
		_unbroken_used = true
		Fx.word(center() + Vector3(0, 1, 0), "UNBROKEN", current_color(), 1.1)
		invuln = 1.0
		return true
	return false


func stagger_time() -> float:
	return 1.1


func revive(at: Vector3) -> void:
	alive = true
	collision_layer = 2
	collision_mask = 1 | 2
	released = false
	swell = 0.0
	dot_t = 0.0
	slow_t = 0.0
	weak_t = 0.0
	lock_target = null
	refresh_stats(true)
	accent = current_color()
	_equip()
	global_position = Vector3(at.x, place.height_at(at.x, at.z) + 0.05, at.z)
	velocity = Vector3.ZERO
	set_state(St.FREE)
	rig.play(idle_clip(), 0.0, 1.0, true)


# -------------------------------------------------------------------- look

func _post(delta: float) -> void:
	var flat := Vector2(velocity.x, velocity.z).length()
	rig.sway = lerpf(rig.sway, clampf(flat / 9.0, 0.0, 1.4), clampf(delta * 8.0, 0.0, 1.0))
	if _orbit != null:
		_orbit.rotation.y += delta * 3.0
	if _aura != null:
		_aura.light_color = current_color()
		_aura.light_energy = lerpf(_aura.light_energy, 2.2 if released else 0.0, clampf(delta * 4.0, 0.0, 1.0))
	if not alive:
		return
	var floor_now := is_on_floor()
	if floor_now and not _was_floor:
		Sfx.play("land", -8.0)
		Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.5), 6, 0.45)
	_was_floor = floor_now
	if state == St.FREE:
		if not floor_now:
			rig.play("air", 0.12)
		elif flat > 1.0:
			rig.play("run", 0.1, clampf(flat / 7.5, 0.6, 1.5))
			_step_t -= delta * flat
			if _step_t <= 0.0:
				_step_t = 2.3
				Sfx.play("step", -14.0, 1.0, 0.15)
		else:
			rig.play("idle", 0.2)

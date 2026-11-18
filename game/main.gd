extends Node
## The game's spine: one soul, one place at a time, and the screens over it.

const SAVE: String = "user://soul.json"

var soul: Soul
var place: Place
var hud: Hud
var post: Post
var lattice_ui: SkillTreeUI
var board_ui: BoardUI
var menus: Menus
var test_mode: bool = false
var in_title: bool = false
var save_path: String = SAVE

const BLUR_NAMES: Array[String] = ["off", "low", "high"]
const BLUR_STRENGTH: Array[float] = [0.0, 1.0, 2.4]
var blur_level: int = 1

var _ui: CanvasLayer
var _after_trial: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_mode = OS.get_cmdline_user_args().has("--test") or DisplayServer.get_name() == "headless"
	post = Post.new()
	add_child(post)
	_load_settings()
	_ui = CanvasLayer.new()
	_ui.layer = 5
	add_child(_ui)
	hud = Hud.new()
	_ui.add_child(hud)
	lattice_ui = SkillTreeUI.new()
	_ui.add_child(lattice_ui)
	lattice_ui.changed.connect(_lattice_changed)
	lattice_ui.closed.connect(_resume)
	board_ui = BoardUI.new()
	_ui.add_child(board_ui)
	menus = Menus.new()
	_ui.add_child(menus)
	menus.chose.connect(_menu)
	if not OS.get_cmdline_user_args().has("--no-title"):
		show_title()


# ------------------------------------------------------------------ places

func _clear_place() -> void:
	if place != null and is_instance_valid(place):
		place.queue_free()
	place = null
	Engine.time_scale = 1.0


func _enter(p: Place, at: Vector3, face_yaw: float) -> void:
	_clear_place()
	place = p
	p.main = self
	p.soul = soul
	p.test_mode = test_mode
	p.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(p)
	var player := Player.new()
	player.setup(soul)
	p.player = player
	p.add_actor(player, at)
	player.rotation.y = face_yaw
	var cam := CamRig.new()
	cam.place = p
	cam.target = player
	cam.yaw = face_yaw
	p.add_child(cam)
	p.cam = cam
	cam.snap()
	p.call("populate")
	hud.bind(p)
	post.cam = cam
	Quality.apply(p)
	post.player = player
	get_tree().paused = false


func home_region() -> String:
	return String(soul.flags.get("checkpoint_region", "town"))


## Enters a region. With `from`, the soul steps out of the rift that leads
## back there; without, it stands at its last cairn or where it woke.
func enter_region(id: String, from: String = "") -> Region:
	board_ui.visible = false
	var r: Region
	match id:
		"ashfall": r = Ashfall.new()
		"citadel": r = Citadel.new()
		"undercroft": r = Undercroft.new()
		"reach": r = Reach.new()
		"undermark": r = Undermark.new()
		"stacks": r = Stacks.new()
		_: r = Town.new()
	r.soul = soul
	r.region_id = id
	var start := r.arrival_point(from) if from != "" else r.start_point()
	_enter(r, start, 0.0)
	return r


func travel(id: String, from: String) -> void:
	save()
	var r := enter_region(id, from)
	r.say(r.place_name.to_upper(), "region")
	const FIRST: Dictionary = {
		"ashfall": "The living world is above you now. Everything here was a person once.",
		"undercroft": "Stairs down from the shop, and down, and down. The cellar is the size of a valley.",
		"citadel": "White walls and blue roofs. Somewhere in here is the Ledger, and your name is not in it.",
		"reach": "Snow, and a frozen lake ringed with lanterns. Nobody here is alive, and everyone here is watching.",
		"undermark": "Below everything. The Ledger struck these names out, and they fell here, and kept falling.",
		"stacks": "Shelves taller than houses, and on every shelf something somebody could not let go of.",
	}
	if FIRST.has(id) and not bool(soul.flags.get("seen_" + id, false)):
		soul.flags["seen_" + id] = true
		r.say(String(FIRST[id]), "whisper")
	_capture_mouse(true)


func enter_trial() -> void:
	save()
	var w := InnerWorld.new()
	w.soul = soul
	_enter(w, Vector3(0, 0, 8), 0.0)
	_capture_mouse(true)


## The Awakening. The strongest strain is fixed and the blade is named.
func finish_trial(trial: Profile, aspect: String) -> void:
	soul.primary = Strains.leading(soul.affinity)
	soul.release = AbilityForge.release(soul.seed, soul.profile, trial, aspect)
	if soul.flags.has("pending_scar"):
		soul.release = AbilityForge.unseal(soul.release, Profile.from_dict(soul.flags["pending_scar"]))
		soul.flags.erase("pending_scar")
	soul.flags["written"] = true
	soul.flags["chapter"] = "hub"
	soul.flags["hub"] = String(Undercroft.HUBS.get(soul.primary, "town"))
	soul.flags["training"] = 3
	save()
	var a := enter_region(home_region())
	a.player.swell = 100.0
	Sfx.play("write", 0.0)
	Fx.pillar(a.player.global_position, a.player.current_color(), 40.0, 2.0, 1.6)
	Fx.screen_flash(Color(1, 1, 1), 0.7)
	hud.push("%s, %s" % [String(soul.release["spirit"]).to_upper(), String(soul.release["title"])], "release")
	hud.push("You have awakened: %s. %s" % [soul.form_name(), String(Strains.INFO[soul.primary]["whisper"])], "gain")
	if Player.RACE_ARTS.has(soul.primary):
		hud.push("Your race's power wakes: X  %s." % String(place.player.race_art().get("name", Player.RACE_ARTS[soul.primary]["name"])) if place != null and place.player != null else "Your race's power wakes: X.", "hint")
	hud.push(String(soul.release["verb_line"]), "toast")
	hud.push("First Release: press R when the diamond is full of spirit pressure. R again spends it.", "toast")
	hud.push("Ivo Marsh has opened a gate to %s." % String(Undercroft.HUB_NAMES[soul.flags["hub"]]), "toast")
	_capture_mouse(true)


func fail_trial() -> void:
	var a := enter_region(home_region())
	a.say("The blade is still restless. Sit again when you are ready.", "whisper")
	_capture_mouse(true)


func grant_essence(amount: float) -> void:
	if soul == null or amount <= 0.0:
		return
	var ups := soul.gain_essence(amount)
	if ups > 0:
		Sfx.play("levelup", 0.0)
		hud.push("Level %d|%d skill point%s to spend  [K]" % [soul.level, soul.marks, "" if soul.marks == 1 else "s"], "level")
		if place != null and place.player != null:
			Fx.ring(place.player.global_position + Vector3(0, 0.2, 0), Color(1.0, 0.82, 0.4), 0.4, 6.0, 0.7)
			place.player.refresh_stats()


func save() -> void:
	if soul != null:
		soul.save_to(save_path)


# ----------------------------------------------------------------- screens

func show_title() -> void:
	in_title = true
	soul = Soul.load_from(save_path)
	var has_save := soul != null
	if soul == null:
		soul = Soul.create(1)
	var a := enter_region("town")
	a.paused_input = true
	a.attract = true
	a.cam.look_enabled = false
	a.cam.pitch = -0.1
	a.cam.dist = 9.0
	for e in a.enemies_alive():
		(e as Enemy).dormant = true
	hud.hidden_ui = true
	menus.show_title(has_save)
	_capture_mouse(false)


func new_soul(soul_seed: int = -1) -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path.replace(".json", "_previous.json")))
	if soul_seed < 0:
		soul_seed = int(Time.get_unix_time_from_system() * 1000.0) % 2000000000
	soul = Soul.create(soul_seed)
	soul.flags["chapter"] = "prologue"
	soul.flags["tether"] = 7
	soul.flags["checkpoint_region"] = "town"
	_begin()
	place.say("CALDER TOWN", "region")
	place.say("This is where you died. Nobody on the street can see you.", "whisper")
	place.say("LMB cut (five in a row)   RMB heavy   T critical   F guard (tap as a blow lands to parry)   Q dash (while hit: evasive)   TAB lock", "toast")
	place.say("A Reaper in a black coat is standing up the street. She can see you.", "toast")
	place.say("A chain hangs from your chest. Hold SHIFT to run. CTRL turns shift lock on and off. Knocked enemies: B grips, V carries.", "toast")


func continue_soul() -> void:
	soul = Soul.load_from(save_path)
	if soul == null:
		new_soul()
		return
	_begin()
	place.say(place.place_name.to_upper(), "region")


func _begin() -> void:
	in_title = false
	hud.hidden_ui = false
	menus.hide_all()
	enter_region(home_region())
	save()
	_capture_mouse(true)


func capture_mouse(on: bool) -> void:
	_capture_mouse(on)


func _capture_mouse(on: bool) -> void:
	if test_mode:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func _menu(what: String) -> void:
	if what.begins_with("set_"):
		var key := what.substr(4)
		var keep_shift := Player.shift_lock
		Settings.cycle(key)
		apply_settings()
		if key != "shift_lock" and not in_title:
			Player.shift_lock = keep_shift
		menus.show_settings(menus.back_to)
		return
	match what:
		"continue":
			continue_soul()
		"new":
			new_soul()
		"quit":
			save_if_playing()
			get_tree().quit()
		"resume":
			_resume()
		"lattice":
			menus.hide_all()
			lattice_ui.open(soul)
		"blur":
			cycle_blur()
			menus.show_pause(soul, "Motion blur: " + BLUR_NAMES[blur_level])
		"settings":
			menus.show_settings("title" if in_title else "pause")
		"controls":
			menus.show_controls(menus.mode if menus.mode == "settings" else ("title" if in_title else "pause"))
		"back":
			if menus.mode == "controls" and menus.back_to == "settings":
				menus.show_settings("title" if in_title else "pause")
			elif in_title:
				menus.show_title(FileAccess.file_exists(save_path))
			else:
				menus.show_pause(soul)
		"title":
			save()
			get_tree().paused = false
			show_title()


func _load_settings() -> void:
	Settings.testing = test_mode
	if not test_mode:
		Settings.load_all()
	apply_settings()


## Puts the saved settings into the running game.
func apply_settings() -> void:
	blur_level = int(Settings.get_value("blur"))
	post.strength = BLUR_STRENGTH[blur_level]
	Player.shift_lock = bool(Settings.get_value("shift_lock"))
	Sfx.master_db = Settings.db(float(Settings.get_value("master")))
	Sfx.music_db = Settings.db(float(Settings.get_value("music")))
	Sfx.sfx_db = Settings.db(float(Settings.get_value("sfx")))
	Sfx.refresh_loops()
	Quality.apply(place)


func cycle_blur() -> void:
	Settings.cycle("blur")
	apply_settings()


func save_if_playing() -> void:
	if not in_title:
		save()


func _lattice_changed() -> void:
	if place != null and place.player != null:
		place.player.refresh_stats()
	save()


func _resume() -> void:
	lattice_ui.visible = false
	menus.hide_all()
	get_tree().paused = false
	_capture_mouse(true)


func _pause(open_lattice: bool) -> void:
	if in_title or place == null or soul == null:
		return
	get_tree().paused = true
	Engine.time_scale = 1.0
	_capture_mouse(false)
	if open_lattice:
		lattice_ui.open(soul)
	else:
		menus.show_pause(soul, "Motion blur: " + BLUR_NAMES[blur_level])


func _process(delta: float) -> void:
	if in_title and place != null and is_instance_valid(place) and place.cam != null:
		place.cam.yaw += delta * 0.06


func _unhandled_input(e: InputEvent) -> void:
	if in_title or board_ui.visible:
		return
	if e.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause(false)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("inventory") and not get_tree().paused and place is Region:
		board_ui.open_inventory(place as Region)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("lattice"):
		if lattice_ui.visible:
			_resume()
		elif not get_tree().paused:
			_pause(true)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_if_playing()

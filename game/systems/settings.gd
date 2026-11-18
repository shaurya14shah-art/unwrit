class_name Settings
extends RefCounted
## What the player sets once and keeps: mouse, field of view, volumes,
## shift lock, motion blur. Saved in user://settings.cfg. Each setting steps
## through a short list of values, so the menu is one button per setting.

const PATH: String = "user://settings.cfg"
const STEPS: Dictionary = {
	"sens": [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
	"fov": [60.0, 70.0, 80.0, 90.0],
	"master": [0.0, 0.25, 0.5, 0.75, 1.0],
	"music": [0.0, 0.25, 0.5, 0.75, 1.0],
	"sfx": [0.0, 0.25, 0.5, 0.75, 1.0],
	"shift_lock": [true, false],
	"blur": [0, 1, 2],
	"quality": [2, 1, 0],
}
const TITLES: Dictionary = {
	"sens": "Mouse sensitivity", "fov": "Field of view", "master": "Master volume", "music": "Music volume",
	"sfx": "Effects volume", "shift_lock": "Shift lock at start", "blur": "Motion blur", "quality": "Graphics",
}
const ORDER: Array = ["sens", "fov", "quality", "shift_lock", "blur", "master", "music", "sfx"]

static var values: Dictionary = {"sens": 1.0, "fov": 70.0, "master": 1.0, "music": 0.75, "sfx": 1.0, "shift_lock": true, "blur": 1, "quality": 2}
static var testing: bool = false


static func get_value(key: String) -> Variant:
	return values.get(key, (STEPS[key] as Array)[0])


static func label(key: String) -> String:
	var v: Variant = get_value(key)
	match key:
		"sens":
			return "%s   %.2fx" % [TITLES[key], float(v)]
		"fov":
			return "%s   %d" % [TITLES[key], int(v)]
		"shift_lock":
			return "%s   %s" % [TITLES[key], "On" if bool(v) else "Off"]
		"blur":
			return "%s   %s" % [TITLES[key], ["Off", "Low", "High"][int(v)]]
		"quality":
			return "%s   %s" % [TITLES[key], Quality.NAMES[int(v)]]
	return "%s   %d%%" % [TITLES[key], int(round(float(v) * 100.0))]


## Steps a setting to its next value, round to the first.
static func cycle(key: String) -> void:
	var list: Array = STEPS[key]
	var i := list.find(values.get(key))
	values[key] = list[(i + 1) % list.size()]
	save()


static func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k: Variant in STEPS.keys():
		var list: Array = STEPS[k]
		var v: Variant = cfg.get_value("settings", String(k), values[k])
		if k == "blur":
			v = int(cfg.get_value("video", "blur", v))
		if list.has(v):
			values[k] = v


static func save() -> void:
	if testing:
		return
	var cfg := ConfigFile.new()
	for k: Variant in values.keys():
		cfg.set_value("settings", String(k), values[k])
	cfg.set_value("video", "blur", values["blur"])
	cfg.save(PATH)


static func db(linear: float) -> float:
	return -80.0 if linear <= 0.001 else linear_to_db(linear)

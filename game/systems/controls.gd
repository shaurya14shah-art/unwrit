extends Node
## Input map, built in code so the project file stays readable.

const KEYS: Dictionary = {
	"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"block": [KEY_F], "dash": [KEY_Q], "sprint": [KEY_SHIFT], "shiftlock": [KEY_CTRL], "jump": [KEY_SPACE], "lock": [KEY_TAB],
	"tech1": [KEY_1], "tech2": [KEY_2], "tech3": [KEY_3], "tech4": [KEY_4],
	"release": [KEY_R], "crit": [KEY_T], "grip": [KEY_B], "carry": [KEY_V], "sense": [KEY_Z], "race": [KEY_X], "interact": [KEY_E], "send": [KEY_G],
	"lattice": [KEY_K], "pause": [KEY_ESCAPE], "sheet": [KEY_C], "inventory": [KEY_I],
}
const MOUSE: Dictionary = {"light": MOUSE_BUTTON_LEFT, "heavy": MOUSE_BUTTON_RIGHT, "lock": MOUSE_BUTTON_MIDDLE}
const PAD: Dictionary = {
	"light": JOY_BUTTON_X, "heavy": JOY_BUTTON_Y, "jump": JOY_BUTTON_A, "dash": JOY_BUTTON_B,
	"block": JOY_BUTTON_LEFT_SHOULDER, "release": JOY_BUTTON_RIGHT_SHOULDER, "lock": JOY_BUTTON_RIGHT_STICK,
	"interact": JOY_BUTTON_LEFT_STICK, "pause": JOY_BUTTON_START, "lattice": JOY_BUTTON_BACK,
	"tech1": JOY_BUTTON_DPAD_LEFT, "tech2": JOY_BUTTON_DPAD_UP, "tech3": JOY_BUTTON_DPAD_RIGHT, "tech4": JOY_BUTTON_DPAD_DOWN,
}
const AXES: Dictionary = {
	"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0], "move_back": [JOY_AXIS_LEFT_Y, 1.0],
}

const LABEL: Dictionary = {
	"light": "LMB", "heavy": "RMB", "block": "F", "dash": "Q", "sprint": "SHIFT", "shiftlock": "CTRL", "jump": "SPACE", "lock": "TAB",
	"release": "R", "crit": "T", "grip": "B", "carry": "V", "sense": "Z", "race": "X", "interact": "E", "send": "G", "lattice": "K", "tech1": "1", "tech2": "2", "tech3": "3", "tech4": "4",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: Variant in KEYS.keys():
		_ensure(String(action))
		var list: Array = KEYS[action]
		for k: Variant in list:
			var ev := InputEventKey.new()
			ev.physical_keycode = int(k) as Key
			InputMap.action_add_event(String(action), ev)
	for action: Variant in MOUSE.keys():
		_ensure(String(action))
		var mb := InputEventMouseButton.new()
		mb.button_index = int(MOUSE[action]) as MouseButton
		InputMap.action_add_event(String(action), mb)
	for action: Variant in PAD.keys():
		_ensure(String(action))
		var jb := InputEventJoypadButton.new()
		jb.button_index = int(PAD[action]) as JoyButton
		InputMap.action_add_event(String(action), jb)
	for action: Variant in AXES.keys():
		_ensure(String(action))
		var pair: Array = AXES[action]
		var jm := InputEventJoypadMotion.new()
		jm.axis = int(pair[0]) as JoyAxis
		jm.axis_value = float(pair[1])
		InputMap.action_add_event(String(action), jm)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)


func label(action: String) -> String:
	return String(LABEL.get(action, action.to_upper()))

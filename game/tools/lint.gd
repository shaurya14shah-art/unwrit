extends Node
## Loads every script so parse errors show without opening a window.

func _ready() -> void:
	var bad := 0
	var stack: Array = ["res://"]
	while stack.size() > 0:
		var dir: String = stack.pop_back()
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for sub in d.get_directories():
			if not sub.begins_with("."):
				stack.append(dir + sub + "/")
		for f in d.get_files():
			if f.ends_with(".gd"):
				var s: Variant = load(dir + f)
				if s == null or not (s as GDScript).can_instantiate():
					bad += 1
					print("BAD  ", dir + f)
	print("lint: %d bad" % bad)
	get_tree().quit(1 if bad > 0 else 0)

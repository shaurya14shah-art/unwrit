class_name Strains
extends RefCounted
## The four Strains. A soul is never asked to pick one. Each grows from what
## the soul does, the strongest is fixed at the Awakening, and a second can be
## grafted later to make a hybrid form.

const ALL: Array[String] = ["vigil", "maw", "lumen", "relic"]

const INFO: Dictionary = {
	"vigil": {"title": "Reaper", "form": "Reaper", "color": Color(0.72, 0.86, 1.0),
		"whisper": "Something in you answers what is done to it."},
	"maw": {"title": "Devourer", "form": "Devourer", "color": Color(0.95, 0.16, 0.2),
		"whisper": "Something in you is hungry."},
	"lumen": {"title": "Archer", "form": "Archer", "color": Color(0.35, 0.95, 0.9),
		"whisper": "Something in you gathers the light that is left."},
	"relic": {"title": "Binder", "form": "Binder", "color": Color(0.78, 0.55, 1.0),
		"whisper": "Something in you remembers what things were."},
}

## What each recorded act feeds.
const GAIN: Dictionary = {
	"parry": {"vigil": 3.0},
	"block": {"vigil": 0.4},
	"light_hit": {"vigil": 0.5},
	"heavy_hit": {"vigil": 0.4, "maw": 0.6},
	"air_hit": {"lumen": 0.4, "vigil": 0.4},
	"trade": {"maw": 1.5},
	"devour": {"maw": 6.0},
	"kill_low": {"maw": 2.5},
	"ranged_hit": {"lumen": 2.5},
	"dodge": {"lumen": 1.2},
	"breath": {"lumen": 0.8, "vigil": 0.4},
	"tech": {"relic": 1.6},
	"relic": {"relic": 9.0},
	"read": {"relic": 3.0},
	"send": {"vigil": 2.5, "lumen": 1.5},
}

const HYBRID: Dictionary = {
	"maw+vigil": "Revenant",
	"lumen+vigil": "Seraph",
	"relic+vigil": "Curator",
	"lumen+maw": "Eclipse",
	"maw+relic": "Idol",
	"lumen+relic": "Constellate",
}

const GRAFT_THRESHOLD: float = 60.0


static func blank() -> Dictionary:
	return {"vigil": 0.0, "maw": 0.0, "lumen": 0.0, "relic": 0.0}


static func gain(aff: Dictionary, event: String, scale: float = 1.0) -> void:
	if not GAIN.has(event):
		return
	var g: Dictionary = GAIN[event]
	for k: Variant in g.keys():
		aff[k] = float(aff.get(k, 0.0)) + float(g[k]) * scale


## Highest affinity; ties go to the earlier name in ALL so the answer is stable.
static func leading(aff: Dictionary, skip: String = "") -> String:
	var best := ""
	var best_v := -1.0
	for s in ALL:
		if s == skip:
			continue
		var v := float(aff.get(s, 0.0))
		if v > best_v + 0.0001:
			best_v = v
			best = s
	return best


static func hybrid_key(a: String, b: String) -> String:
	var pair: Array[String] = [a, b]
	pair.sort()
	return pair[0] + "+" + pair[1]


static func hybrid_name(a: String, b: String) -> String:
	return String(HYBRID.get(hybrid_key(a, b), ""))


static func form_name(primary: String, secondary: String) -> String:
	if primary == "":
		return "Unwrit"
	if secondary == "":
		return String(INFO[primary]["form"])
	return hybrid_name(primary, secondary)


static func color_of(primary: String, secondary: String = "") -> Color:
	if primary == "":
		return Color(0.9, 0.9, 0.92)
	var c: Color = INFO[primary]["color"]
	if secondary != "":
		var c2: Color = INFO[secondary]["color"]
		c = c.lerp(c2, 0.4)
	return c

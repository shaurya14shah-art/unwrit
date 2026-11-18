class_name Profile
extends RefCounted
## The ledger of how a soul actually fights. Nothing in here is picked from a
## menu: it is counted while the player plays, and every unique thing a soul
## receives (first instinct, spirit, release, scars) is read out of it.

const KEYS: Array[String] = [
	"swings", "light_hits", "heavy_hits", "air_hits", "ranged_hits", "tech_uses",
	"parries", "blocks", "dodges", "hits_taken", "kills", "devours", "relics",
	"breaths_steady", "breaths_sharp", "breaths_held",
]
const TRAITS: Array[String] = [
	"aggression", "patience", "mobility", "range", "risk", "hunger",
	"precision", "weight", "craft", "stillness",
]

var n: Dictionary = {}
var time_fighting: float = 0.0
var time_low: float = 0.0
var end_hp_frac: float = 1.0


func _init() -> void:
	for k in KEYS:
		n[k] = 0.0


func add(key: String, amount: float = 1.0) -> void:
	n[key] = float(n.get(key, 0.0)) + amount


func count(key: String) -> float:
	return float(n.get(key, 0.0))


## (a + prior/2) / (b + prior): a ratio that starts at one half and only
## moves as evidence arrives, so three early fights cannot define a soul.
static func _ratio(a: float, b: float, prior: float) -> float:
	return clampf((a + prior * 0.5) / (b + prior), 0.0, 1.0)


func trait_of(name: String) -> float:
	var hits := count("light_hits") + count("heavy_hits") + count("air_hits") + count("ranged_hits")
	var guards := count("parries") + count("blocks") + count("dodges")
	match name:
		"aggression":
			return _ratio(count("swings"), time_fighting * 1.6, 6.0)
		"patience":
			return _ratio(count("parries") * 2.0 + count("blocks"), count("parries") * 2.0 + count("blocks") + count("hits_taken") * 2.0 + count("dodges"), 6.0)
		"mobility":
			return _ratio(count("dodges") * 2.0, guards + count("dodges") + count("hits_taken"), 6.0)
		"range":
			return _ratio(count("ranged_hits") * 2.0, hits + count("ranged_hits"), 8.0)
		"risk":
			return _ratio(time_low * 2.0, time_fighting, 20.0)
		"hunger":
			return _ratio(count("devours"), count("kills"), 4.0)
		"precision":
			return _ratio(hits, count("swings"), 8.0)
		"weight":
			return _ratio(count("heavy_hits") * 2.0, count("light_hits") + count("heavy_hits") * 2.0, 8.0)
		"craft":
			return _ratio(count("tech_uses") * 3.0, count("swings") + count("tech_uses") * 3.0, 8.0)
		"stillness":
			return _ratio(count("breaths_steady"), count("breaths_steady") + count("breaths_sharp") + count("breaths_held"), 4.0)
	return 0.5


func traits() -> Dictionary:
	var out := {}
	for t in TRAITS:
		out[t] = trait_of(t)
	return out


## The trait furthest from the middle, with its direction. Used for quirks.
func dominant() -> String:
	var best := "aggression"
	var best_d := -1.0
	for t in TRAITS:
		var d := absf(trait_of(t) - 0.5)
		if d > best_d + 0.0001:
			best_d = d
			best = t
	return best


func to_dict() -> Dictionary:
	return {"n": n.duplicate(), "tf": time_fighting, "tl": time_low, "eh": end_hp_frac}


static func from_dict(d: Dictionary) -> Profile:
	var p := Profile.new()
	var src: Dictionary = d.get("n", {})
	for k: Variant in src.keys():
		p.n[String(k)] = float(src[k])
	p.time_fighting = float(d.get("tf", 0.0))
	p.time_low = float(d.get("tl", 0.0))
	p.end_hp_frac = float(d.get("eh", 1.0))
	return p

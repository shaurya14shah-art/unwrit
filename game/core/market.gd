class_name Market
extends RefCounted
## The Exchange, pure. Prices move with supply: every sale pushes a good's
## price down, every purchase pushes it up, and both drift back over time.
## Other souls list goods and buy what you list. They are simulated here,
## but listings, prices and the sale log are plain data, the same a server
## would keep when the market goes online.
##
## soul.market = {"clock": seconds, "supply": {key: float},
##   "listings": [{seller, kind, key, count, item, price}],
##   "mine": [{kind, key, count, item, price, at}], "log": [strings]}

const FEE: float = 0.1
const TICK: float = 30.0
const MAX_LISTINGS: int = 8

const SELLER_HEAD: Array = ["Kaven", "Mira", "Oset", "Ruel", "Tamsin", "Ivra", "Dov", "Selk", "Anwe", "Corin", "Hesta", "Pell"]
const SELLER_TAIL: Array = ["of the Rings", "from the Wastes", "of Lantern House", "the Twice-Dead", "of the Undercity", "the Patient", "who Sells Bones", "of Calder", "the Unpromoted", "Half-Masked"]


static func state(soul: Soul) -> Dictionary:
	if soul.market.is_empty():
		soul.market = {"clock": 0.0, "supply": {}, "listings": [], "mine": [], "log": []}
	return soul.market


static func base_value(kind: String, key: String, item: Dictionary = {}) -> float:
	if kind == "charm":
		return float(item.get("value", (Items.CHARMS.get(key, {"value": 100}) as Dictionary).get("value", 100)))
	return float((Items.MATERIALS.get(key, {"value": 5}) as Dictionary)["value"])


## What a good is worth right now: its base, bent by supply. A glut halves
## it at worst; a shortage raises it by up to half again.
static func price(soul: Soul, kind: String, key: String, item: Dictionary = {}) -> int:
	var sup := float((state(soul)["supply"] as Dictionary).get(key, 0.0))
	var k := clampf(1.0 / (1.0 + 0.05 * sup), 0.5, 1.5)
	if sup < 0.0:
		k = clampf(1.0 - 0.05 * sup, 1.0, 1.5)
	return maxi(1, int(round(base_value(kind, key, item) * k)))


static func _push(soul: Soul, key: String, amount: float) -> void:
	var sup: Dictionary = state(soul)["supply"]
	sup[key] = float(sup.get(key, 0.0)) + amount


static func _log(soul: Soul, line: String) -> void:
	var lg: Array = state(soul)["log"]
	lg.append(line)
	while lg.size() > 12:
		lg.pop_front()


## Sells one of a material straight to the Exchange. Returns shards gained.
static func sell_material(soul: Soul, key: String) -> int:
	if int(soul.materials.get(key, 0)) <= 0:
		return 0
	var got := int(floor(float(price(soul, "mat", key)) * (1.0 - FEE)))
	soul.materials[key] = int(soul.materials[key]) - 1
	soul.shards += got
	_push(soul, key, 1.0)
	return got


## Puts an item up for other souls to buy, at a price you choose.
static func list_item(soul: Soul, item_index: int, ask: int) -> bool:
	if item_index < 0 or item_index >= soul.items.size() or ask <= 0:
		return false
	var mine: Array = state(soul)["mine"]
	if mine.size() >= MAX_LISTINGS:
		return false
	var it := Items.take_item(soul, item_index)
	mine.append({"kind": "charm", "key": String(it["key"]), "count": 1, "item": it, "price": ask, "at": float(state(soul)["clock"])})
	return true


static func cancel(soul: Soul, i: int) -> bool:
	var mine: Array = state(soul)["mine"]
	if i < 0 or i >= mine.size():
		return false
	var l: Dictionary = mine[i]
	mine.remove_at(i)
	soul.items.append(l["item"])
	return true


## Buys another soul's listing. Returns true if it was bought.
static func buy(soul: Soul, i: int) -> bool:
	var ls: Array = state(soul)["listings"]
	if i < 0 or i >= ls.size():
		return false
	var l: Dictionary = ls[i]
	if soul.shards < int(l["price"]):
		return false
	soul.shards -= int(l["price"])
	if String(l["kind"]) == "charm":
		soul.items.append(l["item"])
	else:
		soul.materials[l["key"]] = int(soul.materials.get(l["key"], 0)) + int(l["count"])
	_push(soul, String(l["key"]), -0.6 * float(l["count"]))
	ls.remove_at(i)
	_log(soul, "You bought %s from %s for %d." % [label(l), String(l["seller"]), int(l["price"])])
	return true


static func label(l: Dictionary) -> String:
	if String(l["kind"]) == "charm":
		var it: Dictionary = l["item"]
		return "%s %s" % [String(it["rarity"]), String(it["name"])]
	return "%d %s" % [int(l["count"]), String((Items.MATERIALS[l["key"]] as Dictionary)["name"])]


## Time passes on the Exchange: supply drifts back, other souls list goods,
## and some of them buy what you listed if your price is fair. Returns the
## shards you earned in that time.
static func tick(soul: Soul, seconds: float) -> int:
	var st := state(soul)
	var before := int(floor(float(st["clock"]) / TICK))
	st["clock"] = float(st["clock"]) + seconds
	var after := int(floor(float(st["clock"]) / TICK))
	var earned := 0
	for step in range(before + 1, after + 1):
		earned += _step(soul, step)
	return earned


static func _step(soul: Soul, step: int) -> int:
	var st := state(soul)
	var r := Rng.make([soul.seed, "market", step])
	var sup: Dictionary = st["supply"]
	for k: Variant in sup.keys():
		sup[k] = float(sup[k]) * 0.9
	var ls: Array = st["listings"]
	# a soul lists something
	if ls.size() < MAX_LISTINGS:
		var l := {"seller": "%s %s" % [String(Rng.pick(r, SELLER_HEAD)), String(Rng.pick(r, SELLER_TAIL))]}
		var roll := r.randf()
		if roll < 0.14:
			var pkeys: Array = Forge.PATTERNS.keys()
			pkeys.sort()
			var pk := String(Rng.pick(r, pkeys))
			var hands: Array = Forge.HAND.keys()
			hands.sort()
			var fi := Forge.make(pk, [], String(Rng.pick(r, hands)), hash([soul.seed, "listing", step]))
			l.merge({"kind": "charm", "key": pk, "count": 1, "item": fi})
		elif roll < 0.32:
			var keys: Array = Items.CHARMS.keys()
			keys.sort()
			var key := String(Rng.pick(r, keys))
			var it := Items.make_charm(key, hash([soul.seed, "listing", step]))
			l.merge({"kind": "charm", "key": key, "count": 1, "item": it})
		else:
			var mkeys: Array = Items.MATERIALS.keys()
			mkeys.sort()
			var key := String(Rng.pick(r, mkeys))
			l.merge({"kind": "mat", "key": key, "count": 1 + int(r.randi() % 5), "item": {}})
		var per := float(price(soul, String(l["kind"]), String(l["key"]), l["item"]))
		l["price"] = maxi(1, int(round(per * float(l["count"]) * r.randf_range(0.85, 1.3))))
		ls.append(l)
	elif r.randf() < 0.4:
		ls.remove_at(int(r.randi() % ls.size()))
	# souls buy what you listed, if the price is near what it is worth
	var earned := 0
	var mine: Array = st["mine"]
	var i := 0
	while i < mine.size():
		var m: Dictionary = mine[i]
		var worth := float(price(soul, "charm", String(m["key"]), m["item"]))
		var ratio := float(m["price"]) / maxf(worth, 1.0)
		var chance := clampf(1.3 - ratio, 0.05, 0.9)
		if r.randf() < chance:
			var got := int(floor(float(m["price"]) * (1.0 - FEE)))
			soul.shards += got
			earned += got
			_push(soul, String(m["key"]), 0.5)
			_log(soul, "%s bought your %s for %d (you got %d)." % [String(Rng.pick(r, SELLER_HEAD)), label(m), int(m["price"]), got])
			mine.remove_at(i)
		else:
			i += 1
	return earned

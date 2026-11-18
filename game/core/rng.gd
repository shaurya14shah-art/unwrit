class_name Rng
extends RefCounted
## Deterministic randomness. The same parts give the same stream on every run,
## so a soul's seed always grows the same lattice and the same possibilities.

static func make(parts: Array) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(parts)
	return r


static func unit(parts: Array) -> float:
	return make(parts).randf()


static func pick(r: RandomNumberGenerator, items: Array) -> Variant:
	return items[r.randi() % items.size()]


## Weighted pick over a {key: weight} dictionary, in sorted key order so the
## result does not depend on insertion order.
static func weighted(r: RandomNumberGenerator, weights: Dictionary) -> String:
	var keys: Array = weights.keys()
	keys.sort()
	var total := 0.0
	for k: Variant in keys:
		total += maxf(0.0, float(weights[k]))
	if total <= 0.0:
		return String(keys[0])
	var x := r.randf() * total
	for k: Variant in keys:
		x -= maxf(0.0, float(weights[k]))
		if x <= 0.0:
			return String(k)
	return String(keys[keys.size() - 1])

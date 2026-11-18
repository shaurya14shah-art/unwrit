class_name AbilityForge
extends RefCounted
## Builds what is unique to a soul: its first instinct, its techniques and the
## spirit it releases. Every result is drawn from the soul's seed and from how
## that soul has actually fought, and every result spends the same budget, so
## none is simply better than another.

const BUDGET: int = 100
const AXES: Array[String] = ["power", "reach", "speed", "utility"]

## aspect -> what a released hit does, and its colour.
const ASPECTS: Dictionary = {
	"ash": {"effect": "dot", "color": Color(0.82, 0.82, 0.86)},
	"ember": {"effect": "dot", "color": Color(1.0, 0.45, 0.12)},
	"frost": {"effect": "slow", "color": Color(0.6, 0.88, 1.0)},
	"hush": {"effect": "slow", "color": Color(0.62, 0.6, 0.85)},
	"tide": {"effect": "knock", "color": Color(0.2, 0.5, 1.0)},
	"gale": {"effect": "knock", "color": Color(0.7, 1.0, 0.85)},
	"bell": {"effect": "posture", "color": Color(1.0, 0.82, 0.35)},
	"stone": {"effect": "posture", "color": Color(0.75, 0.7, 0.62)},
	"bloom": {"effect": "lifesteal", "color": Color(1.0, 0.55, 0.75)},
	"thorn": {"effect": "lifesteal", "color": Color(0.55, 0.95, 0.35)},
	"rust": {"effect": "weaken", "color": Color(0.85, 0.42, 0.22)},
	"gloam": {"effect": "weaken", "color": Color(0.5, 0.25, 0.85)},
	"storm": {"effect": "chain", "color": Color(0.75, 0.75, 1.0)},
	"glass": {"effect": "chain", "color": Color(0.7, 1.0, 1.0)},
}

## What pushes a soul toward an aspect. trait -> aspects it favours.
const ASPECT_PULL: Dictionary = {
	"stillness": ["hush", "frost", "stone", "bell"],
	"aggression": ["storm", "ember", "gale"],
	"patience": ["bell", "stone", "glass"],
	"risk": ["ember", "thorn", "bloom"],
	"hunger": ["thorn", "rust", "gloam"],
	"range": ["glass", "gale", "storm"],
	"mobility": ["gale", "tide", "gloam"],
	"weight": ["stone", "tide", "rust"],
	"craft": ["glass", "ash", "hush"],
	"precision": ["frost", "ash", "bloom"],
}

## The shape a released weapon takes. The three numbers multiply to about one,
## so a form trades, it does not add.
const FORMS: Dictionary = {
	"greatblade": {"dmg": 1.3, "reach": 1.2, "speed": 0.8, "posture": 1.2, "pull": ["weight", "risk"]},
	"twinfang": {"dmg": 0.82, "reach": 0.9, "speed": 1.35, "posture": 0.8, "pull": ["aggression", "mobility"]},
	"glaive": {"dmg": 0.95, "reach": 1.45, "speed": 0.9, "posture": 1.0, "pull": ["patience", "precision"]},
	"chain": {"dmg": 0.8, "reach": 1.75, "speed": 0.92, "posture": 0.7, "pull": ["range", "craft"]},
	"gauntlet": {"dmg": 1.05, "reach": 0.72, "speed": 1.25, "posture": 1.5, "pull": ["aggression", "hunger"]},
	"needle": {"dmg": 0.88, "reach": 1.1, "speed": 1.15, "posture": 0.9, "pull": ["precision", "stillness"]},
	"crescent": {"dmg": 0.85, "reach": 1.3, "speed": 1.0, "posture": 0.85, "pull": ["range", "mobility"]},
}

const VERBS: Array[String] = ["answer", "sunder", "thread", "ember", "mirage", "bastion"]

const VERB_LINE: Dictionary = {
	"answer": "For a breath, every blow that reaches you is turned and returned.",
	"sunder": "One cut that keeps going after it has landed.",
	"thread": "Shards of your aspect seek what you are looking at.",
	"ember": "A ring that burns what is near and gives you back what it takes.",
	"mirage": "You are behind them before the cut is finished.",
	"bastion": "A ward that drinks harm and throws back what stands close.",
}

const SPECIAL: Dictionary = {
	"answer": {"type": "counter", "dmg": 2.2, "cost": 30.0},
	"sunder": {"type": "wave", "dmg": 3.0, "cost": 35.0},
	"thread": {"type": "volley", "dmg": 0.9, "cost": 30.0},
	"ember": {"type": "pyre", "dmg": 2.0, "cost": 35.0},
	"mirage": {"type": "blink", "dmg": 2.4, "cost": 28.0},
	"bastion": {"type": "ward", "dmg": 1.2, "cost": 32.0},
}

const TECH: Dictionary = {
	"sever": {"name": "Sever Step", "a": "edge", "b": "tempo", "dmg": 22.0, "cd": 5.0, "cost": 18.0, "posture": 18.0,
		"line": "Cross the gap and cut on the way through."},
	"rise": {"name": "Rising Arc", "a": "edge", "b": "frame", "dmg": 20.0, "cd": 6.0, "cost": 16.0, "posture": 26.0,
		"line": "A cut from the ground that lifts what it meets."},
	"lance": {"name": "Pale Lance", "a": "focus", "b": "tempo", "dmg": 18.0, "cd": 3.5, "cost": 14.0, "posture": 10.0,
		"line": "Throw a splinter of your own spirit energy."},
	"toll": {"name": "Low Toll", "a": "focus", "b": "frame", "dmg": 16.0, "cd": 8.0, "cost": 24.0, "posture": 34.0,
		"line": "Strike the ground. Everything near you hears it."},
	"guard": {"name": "Still Guard", "a": "focus", "b": "edge", "dmg": 30.0, "cd": 7.0, "cost": 14.0, "posture": 40.0,
		"line": "Stand ready. The next blow is answered."},
	"gnash": {"name": "Gnash", "a": "frame", "b": "edge", "dmg": 24.0, "cd": 6.5, "cost": 16.0, "posture": 16.0,
		"line": "Lunge and take a piece. Some of it becomes yours."},
	# the hybrid arts: one for each two-strain form, given by the graft
	"grave": {"name": "Grave Answer", "a": "frame", "b": "focus", "dmg": 34.0, "cd": 9.0, "cost": 20.0, "posture": 36.0,
		"line": "Stand ready. The next blow is answered, and the answer feeds you."},
	"star": {"name": "Falling Star", "a": "edge", "b": "focus", "dmg": 26.0, "cd": 10.0, "cost": 26.0, "posture": 28.0,
		"line": "Leap, and come down as light: a ring where you land, and shards that hunt."},
	"exhibit": {"name": "Exhibit", "a": "focus", "b": "frame", "dmg": 14.0, "cd": 11.0, "cost": 24.0, "posture": 10.0,
		"line": "Everything near you is held still for a moment, its stance half broken."},
	"blacksun": {"name": "Black Sun", "a": "focus", "b": "edge", "dmg": 18.0, "cd": 11.0, "cost": 28.0, "posture": 18.0,
		"line": "A dark star that drags what is near into it and burns."},
	"worship": {"name": "Worship", "a": "frame", "b": "tempo", "dmg": 10.0, "cd": 14.0, "cost": 22.0, "posture": 8.0,
		"line": "Everything near turns to face you. You mend, and harm barely reaches you for a while."},
	"orbit": {"name": "Star Map", "a": "focus", "b": "tempo", "dmg": 11.0, "cd": 9.0, "cost": 24.0, "posture": 8.0,
		"line": "Eight shards fly out in a ring, then turn to find what is near."},
}

const HYBRID_ART: Dictionary = {
	"Revenant": "grave", "Seraph": "star", "Curator": "exhibit",
	"Eclipse": "blacksun", "Idol": "worship", "Constellate": "orbit",
}

## What the dominant trait does to a technique when it sets. Each trades.
const QUIRK: Dictionary = {
	"aggression": {"word": "Restless", "cd": 0.8, "dmg": 0.9, "line": "Returns sooner, bites less."},
	"patience": {"word": "Measured", "posture": 1.35, "cd": 1.1, "line": "Breaks stances, returns slower."},
	"mobility": {"word": "Fleet", "reach": 1.3, "dmg": 0.92, "line": "Travels further, bites less."},
	"range": {"word": "Far", "reach": 1.4, "cost": 1.15, "line": "Reaches further, costs more."},
	"risk": {"word": "Desperate", "low_hp": 1.5, "dmg": 0.9, "line": "Half again as strong when you are nearly gone."},
	"hunger": {"word": "Starved", "steal": 0.2, "cost": 1.15, "line": "Returns a fifth of what it takes, costs more."},
	"precision": {"word": "Exact", "dmg": 1.15, "reach": 0.85, "line": "Bites harder, reaches less."},
	"weight": {"word": "Heavy", "dmg": 1.2, "cd": 1.2, "line": "Bites harder, returns slower."},
	"craft": {"word": "Practised", "cost": 0.75, "posture": 0.85, "line": "Costs less, breaks less."},
	"stillness": {"word": "Quiet", "cost": 0.85, "cd": 0.9, "dmg": 0.88, "line": "Cheap and quick, and gentle."},
}


## The first technique surfaces after a soul's first few kills, read from how
## it fought them. Nobody is offered a list.
static func instinct_kind(profile: Profile, soul_seed: int) -> String:
	var t := profile.traits()
	var score := {
		"sever": float(t["mobility"]) + float(t["aggression"]) * 0.5,
		"rise": float(t["weight"]) + float(t["precision"]) * 0.4,
		"lance": float(t["range"]) + float(t["stillness"]) * 0.4,
		"toll": float(t["craft"]) + float(t["risk"]) * 0.5,
		"guard": float(t["patience"]) * 1.2,
		"gnash": float(t["hunger"]) + float(t["risk"]) * 0.4,
	}
	var best := "sever"
	var best_v := -1.0
	var keys: Array = score.keys()
	keys.sort()
	for k: Variant in keys:
		var v := float(score[k]) + Rng.unit([soul_seed, "instinct", k]) * 0.12
		if v > best_v:
			best_v = v
			best = String(k)
	return best


## A technique takes its numbers from the soul's stats at the moment it sets,
## and its quirk from the soul's strongest habit. Same kind, different soul,
## different technique.
static func technique(kind: String, soul_seed: int, base: Dictionary, profile: Profile, serial: int = 0) -> Dictionary:
	var def: Dictionary = TECH[kind]
	var a := float(base.get(def["a"], 5.0))
	var b := float(base.get(def["b"], 5.0))
	var wobble := 0.92 + Rng.unit([soul_seed, "tech", kind, serial]) * 0.16
	var trait_name := profile.dominant()
	var q: Dictionary = QUIRK[trait_name]
	var out := {
		"kind": kind,
		"name": "%s %s" % [String(q["word"]), String(def["name"])],
		"line": String(def["line"]),
		"quirk": String(q["line"]),
		"trait": trait_name,
		"dmg": float(def["dmg"]) * (1.0 + 0.014 * a + 0.009 * b) * wobble * float(q.get("dmg", 1.0)),
		"cd": float(def["cd"]) * float(q.get("cd", 1.0)),
		"cost": float(def["cost"]) * float(q.get("cost", 1.0)),
		"posture": float(def["posture"]) * float(q.get("posture", 1.0)),
		"reach": float(q.get("reach", 1.0)),
		"low_hp": float(q.get("low_hp", 1.0)),
		"steal": float(q.get("steal", 0.0)) + (0.25 if kind == "gnash" else 0.0),
		"scale_a": String(def["a"]),
		"scale_b": String(def["b"]),
	}
	return out


static func verb_from_trial(trial: Profile, soul_seed: int) -> String:
	var score := {
		"answer": trial.count("parries") * 3.0,
		"sunder": trial.count("heavy_hits") * 2.0 + trial.count("light_hits") * 0.45,
		"thread": trial.count("ranged_hits") * 2.5 + trial.count("tech_uses") * 0.8,
		"ember": (9.0 if trial.end_hp_frac < 0.35 else 0.0) + trial.time_low * 0.5,
		"mirage": trial.count("dodges") * 2.5 + trial.count("air_hits") * 1.0,
		"bastion": trial.count("blocks") * 1.6,
	}
	var best := "sunder"
	var best_v := -1.0
	for v in VERBS:
		var s := float(score[v]) + Rng.unit([soul_seed, "verb", v]) * 0.5
		if s > best_v:
			best_v = s
			best = v
	return best


static func aspect_weights(profile: Profile, soul_seed: int) -> Dictionary:
	var w := {}
	for a: Variant in ASPECTS.keys():
		w[a] = 0.35 + Rng.unit([soul_seed, "aspect", a]) * 1.3
	for t: Variant in ASPECT_PULL.keys():
		var lean := profile.trait_of(String(t)) - 0.5
		if lean <= 0.0:
			continue
		var list: Array = ASPECT_PULL[t]
		for a: Variant in list:
			w[a] = float(w[a]) + lean * 4.0
	return w


static func form_weights(profile: Profile, soul_seed: int) -> Dictionary:
	var w := {}
	for f: Variant in FORMS.keys():
		var def: Dictionary = FORMS[f]
		var v := 0.4 + Rng.unit([soul_seed, "form", f]) * 0.9
		var pulls: Array = def["pull"]
		for t: Variant in pulls:
			v += maxf(0.0, profile.trait_of(String(t)) - 0.4) * 3.0
		w[f] = v
	return w


## Splits the budget over the four axes. Always sums to BUDGET.
static func split_budget(profile: Profile, soul_seed: int) -> Dictionary:
	var raw := {
		"power": 1.0 + profile.trait_of("weight") + profile.trait_of("risk") * 0.6,
		"reach": 1.0 + profile.trait_of("range") + profile.trait_of("patience") * 0.5,
		"speed": 1.0 + profile.trait_of("aggression") + profile.trait_of("mobility") * 0.6,
		"utility": 1.0 + profile.trait_of("craft") + profile.trait_of("stillness") * 0.6,
	}
	var total := 0.0
	for ax in AXES:
		raw[ax] = float(raw[ax]) * (0.8 + Rng.unit([soul_seed, "budget", ax]) * 0.4)
		total += float(raw[ax])
	var out := {}
	var spent := 0
	var floor_each := 10
	var free := BUDGET - floor_each * AXES.size()
	for ax in AXES:
		var pts := floor_each + int(floor(float(raw[ax]) / total * float(free)))
		out[ax] = pts
		spent += pts
	out["power"] = int(out["power"]) + (BUDGET - spent)
	return out


## The Writing: the spirit a soul meets and releases. `trial` is the record of
## the fight against it, and decides what the release does.
static func predict_aspect(soul_seed: int, profile: Profile) -> String:
	return Rng.weighted(Rng.make([soul_seed, "aspect-pick"]), aspect_weights(profile, soul_seed))


static func release(soul_seed: int, profile: Profile, trial: Profile, fixed_aspect: String = "") -> Dictionary:
	var r := Rng.make([soul_seed, "release"])
	var aspect := fixed_aspect if fixed_aspect != "" else predict_aspect(soul_seed, profile)
	var form := Rng.weighted(Rng.make([soul_seed, "form-pick"]), form_weights(profile, soul_seed))
	var verb := verb_from_trial(trial, soul_seed)
	var budget := split_budget(profile, soul_seed)
	var fdef: Dictionary = FORMS[form]
	var adef: Dictionary = ASPECTS[aspect]
	var col: Color = adef["color"]
	var sp: Dictionary = (SPECIAL[verb] as Dictionary).duplicate()
	var spirit_name := Names.spirit(r)
	return {
		"spirit": spirit_name,
		"title": Names.title(r, aspect),
		"call": Names.call_of(verb),
		"aspect": aspect,
		"effect": String(adef["effect"]),
		"form": form,
		"verb": verb,
		"verb_line": String(VERB_LINE[verb]),
		"color": [col.r, col.g, col.b],
		"budget": budget,
		"dmg": float(fdef["dmg"]) * (0.86 + 0.0056 * float(budget["power"])),
		"reach": float(fdef["reach"]) * (0.9 + 0.004 * float(budget["reach"])),
		"speed": float(fdef["speed"]) * (0.9 + 0.004 * float(budget["speed"])),
		"posture": float(fdef["posture"]),
		"effect_power": 0.6 + 0.016 * float(budget["utility"]),
		"special": sp,
		"stage": 1,
		"scar": "",
	}


## The Unsealing: the second stage, shaped by how a great enemy was beaten.
const SCARS: Dictionary = {
	"tollbreaker": "Each parry rings: a shock that staggers what is near.",
	"long-hunger": "Each kill while released feeds the release.",
	"unbroken": "While released, the first blow that would fell you does not.",
	"far-sight": "Released cuts throw a splinter of your aspect.",
	"afterstep": "Each dodge while released leaves a cut behind.",
}


static func scar_from_fight(fight: Profile) -> String:
	var score := {
		"tollbreaker": fight.count("parries") * 3.0,
		"long-hunger": fight.count("heavy_hits") * 1.6 + fight.count("light_hits") * 0.4,
		"unbroken": (10.0 if fight.end_hp_frac < 0.3 else 0.0) + fight.count("blocks") * 1.2,
		"far-sight": fight.count("ranged_hits") * 2.5 + fight.count("tech_uses") * 1.5,
		"afterstep": fight.count("dodges") * 2.2,
	}
	var best := "long-hunger"
	var best_v := -1.0
	var keys: Array = score.keys()
	keys.sort()
	for k: Variant in keys:
		if float(score[k]) > best_v:
			best_v = float(score[k])
			best = String(k)
	return best


static func unseal(spec: Dictionary, fight: Profile) -> Dictionary:
	var out := spec.duplicate(true)
	out["stage"] = 2
	out["scar"] = scar_from_fight(fight)
	out["scar_line"] = String(SCARS[out["scar"]])
	return out


static func color_of(spec: Dictionary) -> Color:
	var c: Array = spec.get("color", [0.9, 0.9, 0.95])
	return Color(float(c[0]), float(c[1]), float(c[2]))

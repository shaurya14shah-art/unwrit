class_name Names
extends RefCounted
## Names for the spirit inside a weapon. Built from syllables, so no two
## seeds are likely to share one and none is taken from anywhere else.

const HEAD: Array[String] = ["Ka", "Ve", "Or", "Shi", "Mau", "El", "Tha", "Ru", "Ny", "Ose", "Ira", "Dho", "Sae", "Ul", "Qe", "Ha", "Yr", "Bel", "Zo", "Ane"]
const MID: Array[String] = ["ra", "li", "no", "the", "ru", "mi", "va", "sha", "do", "ke", "", "", "ri", "lo", "ne"]
const TAIL: Array[String] = ["th", "n", "ra", "s", "dis", "mar", "el", "ko", "ne", "sai", "vir", "um", "ka", "ren", "os"]

const ORDINAL: Array[String] = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Last", "Unnumbered", "Borrowed"]

const NOUN: Dictionary = {
	"ash": ["Ash", "Cinder", "Pall"], "ember": ["Ember", "Kiln", "Coal"],
	"frost": ["Rime", "Winter", "Glass-of-Morning"], "hush": ["Hush", "Quiet", "Held Breath"],
	"tide": ["Tide", "Undertow", "Shoal"], "gale": ["Gale", "Draught", "Long Wind"],
	"bell": ["Bell", "Toll", "Knell"], "stone": ["Cairn", "Plinth", "Marker"],
	"bloom": ["Bloom", "Orchard", "Second Spring"], "thorn": ["Thorn", "Briar", "Hook"],
	"rust": ["Rust", "Verdigris", "Slow Ruin"], "gloam": ["Gloam", "Dusk", "Unlit Room"],
	"storm": ["Storm", "Levin", "Split Sky"], "glass": ["Glass", "Shard", "Pane"],
}

const CALL: Dictionary = {
	"answer": "Answer them,", "sunder": "Break it open,", "thread": "Reach,",
	"ember": "Burn longer,", "mirage": "Be elsewhere,", "bastion": "Stand,",
}


static func spirit(r: RandomNumberGenerator) -> String:
	var s: String = String(Rng.pick(r, HEAD)) + String(Rng.pick(r, MID)) + String(Rng.pick(r, TAIL))
	return s


static func title(r: RandomNumberGenerator, aspect: String) -> String:
	var nouns: Array = NOUN.get(aspect, ["Ash"])
	return "the %s %s" % [String(Rng.pick(r, ORDINAL)), String(Rng.pick(r, nouns))]


static func call_of(verb: String) -> String:
	return String(CALL.get(verb, "Wake,"))

class_name Meditation
extends RefCounted
## Sitting at a cairn. Hold to draw breath in, let go to release it. There is
## no right way: how a soul breathes is read, not scored, and it leans the
## aspect its spirit will have.

const NEED: int = 5

var breaths: int = 0
var holding: bool = false
var hold_t: float = 0.0
var done: bool = false
var last: String = ""
var counts: Dictionary = {"steady": 0, "sharp": 0, "held": 0}
var age: float = 0.0


static func classify(seconds: float) -> String:
	if seconds < 0.8:
		return "sharp"
	if seconds <= 3.0:
		return "steady"
	return "held"


## Returns "in" when a breath starts, the breath's kind when it ends, else "".
func tick(delta: float, held: bool) -> String:
	age += delta
	if done:
		return ""
	if held and not holding:
		holding = true
		hold_t = 0.0
		return "in"
	if held:
		hold_t += delta
		return ""
	if holding:
		holding = false
		last = classify(hold_t)
		counts[last] = int(counts[last]) + 1
		breaths += 1
		if breaths >= NEED:
			done = true
		return last
	return ""

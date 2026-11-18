class_name Bestiary
extends RefCounted
## Every enemy as data: body, numbers, blows. The AI in enemy.gd reads this
## and nothing here names a behaviour in code.
##
## Move types: strike (a cut in an arc), bolt (thrown, `count` for a spread,
## parryable back unless "parryable": false), ring (around the body), wave
## (a ring that runs along the ground: jump it), leap (lands where you were).
## "red": true marks a blow that cannot be guarded.
## Numbers are at level 1; enemy.gd scales vitality and damage by level.

const BONE := Color(0.9, 0.9, 0.88)
const RED := Color(1.0, 0.12, 0.14)

const DEFS: Dictionary = {
	# ------------------------------------------------------------ common
	"husk": {
		"name": "Ash Husk", "hp": 52.0, "posture": 38.0, "speed": 4.4, "essence": 16.0, "range": 2.3, "cool": [1.1, 2.0],
		"body": {"feral": true, "scale": 1.0, "cloth": Color(0.86, 0.86, 0.84), "trim": Color(0.25, 0.25, 0.27), "accent": RED,
			"coat": 0, "sleeves": false, "hair": -1, "mask": 0, "hole": true, "claws": true},
		"moves": [
			{"id": "swipe", "clip": "f_swipe", "startup": 0.52, "active": 0.1, "recover": 0.55, "dmg": 11.0, "posture": 12.0, "reach": 2.3, "arc": 120.0, "lunge": 4.5, "roll": 15.0, "w": 3.0},
			{"id": "swipe2", "clip": "f_swipe_l", "startup": 0.46, "active": 0.1, "recover": 0.6, "dmg": 10.0, "posture": 12.0, "reach": 2.3, "arc": 120.0, "lunge": 4.5, "roll": -15.0, "w": 2.0, "then": "swipe"},
		],
	},
	"hound": {
		"name": "Stray Hound", "hp": 38.0, "posture": 26.0, "speed": 7.6, "essence": 15.0, "range": 2.0, "cool": [0.8, 1.5],
		"body": {"feral": true, "scale": 0.85, "leg": 0.7, "arm": 0.85, "bulk": 0.9, "cloth": Color(0.3, 0.3, 0.33), "trim": Color(0.82, 0.82, 0.8), "accent": Color(1.0, 0.55, 0.15),
			"coat": 0, "sleeves": false, "hair": -1, "mask": 2, "hole": true, "claws": true},
		"moves": [
			{"id": "bite", "clip": "f_swipe", "startup": 0.38, "active": 0.1, "recover": 0.5, "dmg": 9.0, "posture": 10.0, "reach": 1.9, "arc": 90.0, "lunge": 11.0, "roll": 0.0, "w": 3.0},
			{"id": "pounce", "type": "leap", "clip": "f_slam", "startup": 0.72, "active": 0.1, "recover": 0.7, "dmg": 13.0, "posture": 12.0, "reach": 1.6, "arc": 360.0, "w": 2.0, "min": 5.0, "max": 13.0},
		],
	},
	"gleaner": {
		"name": "Gleaner", "hp": 40.0, "posture": 30.0, "speed": 3.8, "essence": 20.0, "range": 13.0, "keep": 9.0, "cool": [1.6, 2.6],
		"body": {"feral": false, "scale": 1.08, "cloth": Color(0.07, 0.07, 0.09), "trim": Color(0.8, 0.8, 0.82), "accent": Color(0.3, 0.95, 0.9),
			"coat": 2, "sleeves": true, "hair": -1, "mask": 1, "bulk": 0.86, "halo": true},
		"moves": [
			{"id": "bolt", "clip": "cast", "type": "bolt", "startup": 0.72, "active": 0.06, "recover": 0.7, "dmg": 13.0, "posture": 10.0, "reach": 22.0, "arc": 20.0, "speed": 21.0, "w": 5.0, "min": 5.0, "sfx": "cast"},
			{"id": "shove", "clip": "thrust", "startup": 0.4, "active": 0.1, "recover": 0.7, "dmg": 8.0, "posture": 16.0, "reach": 2.2, "arc": 80.0, "lunge": 3.0, "knock": 7.0, "w": 3.0, "max": 3.5},
		],
	},
	"wraith": {
		"name": "Wraith", "hp": 34.0, "posture": 24.0, "speed": 4.6, "essence": 19.0, "range": 15.0, "keep": 11.0, "cool": [1.8, 2.8],
		"body": {"feral": false, "scale": 1.12, "bulk": 0.78, "cloth": Color(0.82, 0.84, 0.9), "trim": Color(0.3, 0.32, 0.4), "accent": Color(0.6, 0.5, 1.0),
			"coat": 2, "sleeves": true, "hair": -1, "mask": 1, "halo": true, "face": -1},
		"moves": [
			{"id": "fan", "clip": "cast", "type": "bolt", "count": 3, "spread": 16.0, "startup": 0.8, "active": 0.06, "recover": 0.8, "dmg": 8.0, "posture": 8.0, "reach": 22.0, "arc": 20.0, "speed": 18.0, "w": 4.0, "min": 4.0, "sfx": "cast"},
			{"id": "flit", "type": "leap", "clip": "cast", "startup": 0.55, "active": 0.06, "recover": 0.5, "dmg": 6.0, "posture": 6.0, "reach": 1.4, "arc": 360.0, "w": 1.0, "max": 4.0},
		],
	},
	"rogue": {
		"name": "Rogue Reaper", "hp": 74.0, "posture": 52.0, "speed": 6.0, "essence": 28.0, "range": 2.6, "cool": [0.7, 1.5], "reacts": true, "blade": true,
		"body": {"feral": false, "scale": 1.0, "cloth": Color(0.06, 0.06, 0.08), "trim": Color(0.55, 0.12, 0.12), "accent": Color(0.9, 0.2, 0.2),
			"coat": 2, "sleeves": true, "hair": 1, "hair_color": Color(0.12, 0.12, 0.14), "face": 1, "sash": 1},
		"moves": [
			{"id": "r1", "clip": "light1", "startup": 0.36, "active": 0.08, "recover": 0.24, "dmg": 11.0, "posture": 10.0, "reach": 2.5, "arc": 150.0, "lunge": 6.0, "roll": 12.0, "w": 4.0, "then": "r2"},
			{"id": "r2", "clip": "light2", "startup": 0.28, "active": 0.08, "recover": 0.5, "dmg": 11.0, "posture": 10.0, "reach": 2.5, "arc": 150.0, "lunge": 6.0, "roll": -16.0, "w": 0.0},
			{"id": "thrust", "clip": "thrust", "startup": 0.55, "active": 0.08, "recover": 0.7, "dmg": 18.0, "posture": 18.0, "reach": 3.0, "arc": 40.0, "lunge": 12.0, "w": 2.0, "min": 3.0},
			{"id": "cleave", "clip": "heavy", "startup": 0.75, "active": 0.1, "recover": 0.8, "dmg": 24.0, "posture": 24.0, "reach": 3.0, "arc": 70.0, "lunge": 7.0, "roll": 90.0, "heavy": true, "w": 1.5, "red": true, "blockable": false, "parryable": false, "sfx": "whoosh_heavy"},
		],
	},
	"sentinel": {
		"name": "Stone Sentinel", "hp": 160.0, "posture": 120.0, "speed": 3.0, "essence": 50.0, "range": 3.4, "cool": [1.4, 2.2], "armored": true,
		"body": {"feral": false, "scale": 1.5, "bulk": 1.35, "cloth": Color(0.58, 0.6, 0.64), "trim": Color(0.36, 0.38, 0.42), "skin": Color(0.66, 0.68, 0.72),
			"accent": Color(0.4, 0.75, 1.0), "coat": 1, "sleeves": false, "hair": -1, "face": -1, "mask": 0},
		"moves": [
			{"id": "sweep", "clip": "heavy", "startup": 0.8, "active": 0.12, "recover": 0.85, "dmg": 20.0, "posture": 22.0, "reach": 3.0, "arc": 220.0, "lunge": 2.0, "roll": 90.0, "heavy": true, "knock": 6.0, "w": 3.0, "sfx": "whoosh_heavy"},
			{"id": "stomp", "clip": "slam", "type": "ring", "startup": 1.0, "active": 0.12, "recover": 1.0, "dmg": 26.0, "posture": 26.0, "reach": 3.4, "arc": 360.0, "heavy": true, "knock": 8.0, "w": 2.0, "red": true, "blockable": false, "parryable": false, "sfx": "toll"},
		],
	},
	"stalker": {
		"name": "Stalker", "hp": 62.0, "posture": 40.0, "speed": 8.6, "essence": 30.0, "range": 2.4, "cool": [0.6, 1.2],
		"body": {"feral": true, "scale": 1.15, "leg": 1.2, "arm": 1.05, "bulk": 0.9, "cloth": BONE, "trim": Color(0.2, 0.2, 0.22), "accent": Color(1.0, 0.3, 0.2),
			"coat": 0, "sleeves": false, "hair": -1, "mask": 2, "hole": true, "claws": true},
		"moves": [
			{"id": "rake", "clip": "f_swipe", "startup": 0.4, "active": 0.1, "recover": 0.3, "dmg": 13.0, "posture": 12.0, "reach": 2.4, "arc": 130.0, "lunge": 9.0, "roll": 14.0, "w": 3.0, "then": "rake2"},
			{"id": "rake2", "clip": "f_swipe_l", "startup": 0.3, "active": 0.1, "recover": 0.6, "dmg": 13.0, "posture": 12.0, "reach": 2.4, "arc": 130.0, "lunge": 9.0, "roll": -14.0, "w": 0.0},
			{"id": "pounce", "type": "leap", "clip": "f_slam", "startup": 0.7, "active": 0.1, "recover": 0.8, "dmg": 20.0, "posture": 18.0, "reach": 1.8, "arc": 360.0, "w": 2.0, "min": 5.0, "max": 15.0},
		],
	},
	"brute": {
		"name": "Gravebrute", "hp": 185.0, "posture": 110.0, "speed": 3.0, "essence": 60.0, "range": 3.4, "cool": [1.4, 2.4], "armored": true,
		"body": {"feral": true, "scale": 1.6, "bulk": 1.25, "cloth": Color(0.3, 0.3, 0.32), "trim": Color(0.75, 0.75, 0.72), "accent": Color(1.0, 0.9, 0.5),
			"coat": 0, "sleeves": false, "hair": -1, "mask": 2, "hole": true, "claws": false},
		"moves": [
			{"id": "slam", "clip": "f_slam", "type": "ring", "startup": 0.95, "active": 0.12, "recover": 1.0, "dmg": 30.0, "posture": 30.0, "reach": 3.6, "arc": 360.0,
				"blockable": false, "parryable": false, "heavy": true, "knock": 8.0, "w": 3.0, "red": true, "sfx": "whoosh_heavy"},
			{"id": "sweep", "clip": "f_swipe", "startup": 0.7, "active": 0.12, "recover": 0.8, "dmg": 18.0, "posture": 20.0, "reach": 2.6, "arc": 200.0, "lunge": 3.0, "heavy": true, "knock": 6.0, "w": 4.0, "sfx": "whoosh_heavy"},
		],
	},
	"giant": {
		"name": "the Tall", "hp": 520.0, "posture": 220.0, "speed": 2.2, "essence": 240.0, "range": 24.0, "keep": 9.0, "cool": [1.6, 2.6], "armored": true,
		"body": {"feral": true, "scale": 4.2, "bulk": 0.9, "leg": 1.3, "cloth": Color(0.05, 0.05, 0.06), "trim": BONE, "accent": RED,
			"coat": 1, "sleeves": false, "hair": -1, "mask": 1, "hole": true},
		"moves": [
			{"id": "beam", "clip": "cast", "type": "bolt", "startup": 1.2, "active": 0.06, "recover": 1.0, "dmg": 34.0, "posture": 30.0, "reach": 40.0, "arc": 10.0, "speed": 58.0, "w": 3.0, "min": 6.0,
				"red": true, "parryable": false, "sfx": "cast"},
			{"id": "stomp", "clip": "f_slam", "type": "ring", "startup": 1.1, "active": 0.12, "recover": 1.1, "dmg": 30.0, "posture": 30.0, "reach": 2.2, "arc": 360.0, "heavy": true, "knock": 10.0, "w": 3.0, "max": 10.0, "red": true, "blockable": false, "parryable": false, "sfx": "toll"},
		],
	},
	"drill": {
		"name": "Training Frame", "hp": 46.0, "posture": 34.0, "speed": 3.6, "essence": 8.0, "range": 2.5, "cool": [1.4, 2.2], "blade": true,
		"body": {"feral": false, "scale": 1.0, "cloth": Color(0.6, 0.45, 0.28), "trim": Color(0.38, 0.27, 0.16), "skin": Color(0.7, 0.55, 0.36),
			"accent": Color(1.0, 0.85, 0.5), "coat": 0, "sleeves": false, "hair": -1, "face": -1},
		"moves": [
			{"id": "slow", "clip": "light1", "startup": 0.7, "active": 0.08, "recover": 0.6, "dmg": 4.0, "posture": 6.0, "reach": 2.5, "arc": 140.0, "lunge": 3.0, "roll": 12.0, "w": 3.0},
			{"id": "slow2", "clip": "light2", "startup": 0.6, "active": 0.08, "recover": 0.8, "dmg": 4.0, "posture": 6.0, "reach": 2.5, "arc": 140.0, "lunge": 3.0, "roll": -16.0, "w": 2.0},
		],
	},

	# ------------------------------------------------------------ the Undermark
	"damned": {
		"name": "Damned", "hp": 90.0, "posture": 46.0, "speed": 5.2, "essence": 34.0, "range": 2.4, "cool": [0.8, 1.5], "regen": 0.05,
		"body": {"feral": false, "scale": 1.05, "cloth": Color(0.16, 0.12, 0.1), "trim": Color(0.55, 0.22, 0.1), "skin": Color(0.42, 0.36, 0.34), "accent": Color(1.0, 0.45, 0.1),
			"coat": 1, "sleeves": false, "hair": -1, "face": 2, "claws": true, "tether": 4},
		"moves": [
			{"id": "maul", "clip": "light1", "startup": 0.42, "active": 0.08, "recover": 0.3, "dmg": 14.0, "posture": 12.0, "reach": 2.4, "arc": 140.0, "lunge": 6.0, "roll": 12.0, "w": 3.0, "then": "maul2"},
			{"id": "maul2", "clip": "heavy", "startup": 0.5, "active": 0.1, "recover": 0.7, "dmg": 20.0, "posture": 18.0, "reach": 2.6, "arc": 80.0, "lunge": 7.0, "roll": 90.0, "heavy": true, "w": 0.0, "sfx": "whoosh_heavy"},
		],
	},
	"chainbound": {
		"name": "Chainbound", "hp": 70.0, "posture": 40.0, "speed": 4.6, "essence": 36.0, "range": 7.0, "keep": 4.0, "cool": [1.2, 2.0],
		"body": {"feral": false, "scale": 1.1, "cloth": Color(0.1, 0.1, 0.12), "trim": Color(0.62, 0.6, 0.56), "skin": Color(0.4, 0.38, 0.38), "accent": Color(1.0, 0.3, 0.1),
			"coat": 2, "sleeves": true, "hair": -1, "mask": 0, "tether": 7},
		"moves": [
			{"id": "hook", "clip": "thrust", "startup": 0.55, "active": 0.1, "recover": 0.6, "dmg": 10.0, "posture": 14.0, "reach": 7.5, "arc": 30.0, "pull": true, "w": 4.0, "min": 3.0, "sfx": "whoosh_heavy"},
			{"id": "lash", "clip": "light2", "startup": 0.38, "active": 0.1, "recover": 0.5, "dmg": 12.0, "posture": 10.0, "reach": 3.2, "arc": 160.0, "lunge": 2.0, "roll": -16.0, "w": 3.0, "max": 4.0},
		],
	},
	"gaoler": {
		"name": "Gaoler", "hp": 240.0, "posture": 150.0, "speed": 2.8, "essence": 90.0, "range": 3.6, "cool": [1.3, 2.2], "armored": true, "reforms": true,
		"body": {"feral": false, "scale": 2.1, "bulk": 1.35, "cloth": Color(0.08, 0.07, 0.07), "trim": Color(0.5, 0.45, 0.4), "skin": Color(0.3, 0.27, 0.26), "accent": Color(1.0, 0.35, 0.1),
			"coat": 2, "sleeves": false, "hair": -1, "mask": 3, "tether": 7},
		"moves": [
			{"id": "crush", "clip": "heavy", "startup": 0.9, "active": 0.12, "recover": 0.9, "dmg": 30.0, "posture": 28.0, "reach": 2.2, "arc": 120.0, "lunge": 2.0, "roll": 90.0, "heavy": true, "knock": 8.0, "w": 3.0, "sfx": "whoosh_heavy"},
			{"id": "bind", "clip": "thrust", "startup": 0.7, "active": 0.1, "recover": 0.7, "dmg": 14.0, "posture": 16.0, "reach": 5.0, "arc": 30.0, "pull": true, "w": 2.0, "min": 3.5, "sfx": "whoosh_heavy"},
			{"id": "quake", "clip": "slam", "type": "ring", "startup": 1.0, "active": 0.12, "recover": 1.0, "dmg": 30.0, "posture": 26.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 9.0, "w": 2.0, "red": true, "blockable": false, "parryable": false, "sfx": "slam"},
		],
	},
	"cinder": {
		"name": "Cinder", "hp": 46.0, "posture": 28.0, "speed": 5.4, "essence": 30.0, "range": 14.0, "keep": 9.0, "cool": [1.4, 2.4], "burns": true,
		"body": {"feral": true, "scale": 0.95, "bulk": 0.8, "cloth": Color(0.12, 0.06, 0.04), "trim": Color(1.0, 0.5, 0.15), "accent": Color(1.0, 0.45, 0.1),
			"coat": 0, "sleeves": false, "hair": 1, "hair_color": Color(1.0, 0.4, 0.1), "mask": 1, "hole": true},
		"moves": [
			{"id": "embers", "clip": "cast", "type": "bolt", "count": 3, "spread": 14.0, "startup": 0.7, "active": 0.06, "recover": 0.7, "dmg": 9.0, "posture": 6.0, "reach": 22.0, "arc": 20.0, "speed": 20.0, "burn": true, "w": 4.0, "min": 4.0, "sfx": "cast"},
			{"id": "flare", "clip": "f_slam", "type": "ring", "startup": 0.7, "active": 0.1, "recover": 0.7, "dmg": 12.0, "posture": 10.0, "reach": 3.2, "arc": 360.0, "burn": true, "w": 2.0, "max": 3.5, "sfx": "toll"},
		],
	},

	# ------------------------------------------------------------ great enemies
	"gutter_king": {
		"name": "the Gutter King", "hp": 430.0, "posture": 120.0, "speed": 4.6, "essence": 220.0, "range": 3.4, "cool": [0.9, 1.6], "armored": true, "boss": true,
		"phase_line": "It swallows the strays around it and swells.", "death_line": "The courtyard goes quiet.",
		"body": {"feral": true, "scale": 2.2, "bulk": 1.2, "cloth": Color(0.86, 0.86, 0.84), "trim": Color(0.25, 0.25, 0.27), "accent": RED,
			"coat": 0, "sleeves": false, "hair": 1, "hair_color": Color(0.35, 0.33, 0.3), "hair_seed": 12, "mask": 0, "mask_seed": 12, "hole": true, "claws": true},
		"moves": [
			{"id": "claw", "clip": "f_swipe", "startup": 0.6, "active": 0.1, "recover": 0.35, "dmg": 13.0, "posture": 14.0, "reach": 2.2, "arc": 130.0, "lunge": 6.0, "roll": 14.0, "w": 4.0, "then": "claw2", "max": 7.0},
			{"id": "claw2", "clip": "f_swipe_l", "startup": 0.42, "active": 0.1, "recover": 0.8, "dmg": 13.0, "posture": 14.0, "reach": 2.2, "arc": 130.0, "lunge": 6.0, "roll": -14.0, "w": 0.0},
			{"id": "slam", "clip": "f_slam", "type": "ring", "startup": 1.0, "active": 0.12, "recover": 1.0, "dmg": 24.0, "posture": 24.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 8.0, "w": 2.0, "red": true, "blockable": false, "parryable": false, "sfx": "whoosh_heavy"},
			{"id": "leap", "type": "leap", "clip": "f_slam", "startup": 1.0, "active": 0.12, "recover": 1.2, "dmg": 26.0, "posture": 24.0, "reach": 1.8, "arc": 360.0, "heavy": true, "knock": 9.0, "w": 2.0, "min": 7.0, "red": true, "blockable": false, "parryable": false},
		],
		"phase2": [
			{"id": "toll", "clip": "f_slam", "type": "wave", "startup": 0.9, "active": 0.12, "recover": 0.9, "dmg": 18.0, "posture": 20.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "min": 3.0, "sfx": "toll", "wave_speed": 11.0},
		],
	},
	"drowned_hound": {
		"name": "the Drowned Hound", "hp": 760.0, "posture": 150.0, "speed": 7.0, "essence": 380.0, "range": 3.2, "cool": [0.7, 1.3], "armored": true, "boss": true,
		"phase_line": "River water pours out of its mouth. It does not stop.", "death_line": "The river runs clear for a moment.",
		"body": {"feral": true, "scale": 2.6, "leg": 0.75, "arm": 0.95, "bulk": 1.05, "cloth": Color(0.2, 0.26, 0.32), "trim": Color(0.75, 0.82, 0.86), "accent": Color(0.3, 0.7, 1.0),
			"coat": 0, "sleeves": false, "hair": -1, "mask": 2, "mask_seed": 21, "hole": true, "claws": true, "collar": true, "hair_seed": 21},
		"moves": [
			{"id": "bite", "clip": "f_swipe", "startup": 0.5, "active": 0.1, "recover": 0.5, "dmg": 18.0, "posture": 16.0, "reach": 2.3, "arc": 100.0, "lunge": 15.0, "w": 4.0, "max": 12.0},
			{"id": "pounce", "type": "leap", "clip": "f_slam", "startup": 0.85, "active": 0.12, "recover": 1.0, "dmg": 26.0, "posture": 24.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 8.0, "w": 3.0, "min": 6.0, "red": true, "blockable": false, "parryable": false},
			{"id": "spray", "clip": "f_swipe", "type": "bolt", "count": 5, "spread": 12.0, "startup": 0.9, "active": 0.06, "recover": 0.9, "dmg": 9.0, "posture": 8.0, "reach": 24.0, "arc": 20.0, "speed": 20.0, "w": 2.0, "min": 6.0, "sfx": "cast"},
		],
		"phase2": [
			{"id": "flood", "clip": "f_slam", "type": "wave", "startup": 0.8, "active": 0.12, "recover": 0.7, "dmg": 20.0, "posture": 22.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 14.0, "then": "bite"},
		],
	},
	"thane": {
		"name": "Thane, the Gate", "hp": 900.0, "posture": 185.0, "speed": 2.6, "essence": 560.0, "range": 4.6, "cool": [1.5, 2.4], "armored": true, "boss": true,
		"phase_line": "The gate in its chest grinds open.", "death_line": "The great gate stands open.",
		"body": {"feral": false, "scale": 3.3, "bulk": 1.4, "cloth": Color(0.62, 0.64, 0.68), "trim": Color(0.3, 0.34, 0.4), "skin": Color(0.7, 0.72, 0.76),
			"accent": Color(0.4, 0.75, 1.0), "coat": 2, "sleeves": false, "hair": -1, "face": -1, "mask": 3, "mask_seed": 33},
		"moves": [
			{"id": "sweep", "clip": "heavy", "startup": 0.95, "active": 0.14, "recover": 0.95, "dmg": 20.0, "posture": 22.0, "reach": 2.0, "arc": 260.0, "lunge": 2.0, "roll": 90.0, "heavy": true, "knock": 7.0, "w": 4.0, "sfx": "whoosh_heavy"},
			{"id": "crush", "clip": "slam", "type": "ring", "startup": 1.25, "active": 0.12, "recover": 1.3, "dmg": 26.0, "posture": 24.0, "reach": 1.6, "arc": 360.0, "heavy": true, "knock": 10.0, "w": 3.0, "red": true, "blockable": false, "parryable": false, "sfx": "slam"},
			{"id": "quake", "clip": "slam", "type": "wave", "startup": 1.1, "active": 0.12, "recover": 1.15, "dmg": 17.0, "posture": 20.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "min": 4.0, "sfx": "toll", "wave_speed": 12.0},
		],
		"phase2": [
			{"id": "fall", "type": "leap", "clip": "slam", "startup": 1.25, "active": 0.12, "recover": 1.5, "dmg": 29.0, "posture": 24.0, "reach": 1.4, "arc": 360.0, "heavy": true, "knock": 10.0, "w": 2.5, "min": 7.0, "red": true, "blockable": false, "parryable": false},
		],
	},
	"vael": {
		"name": "Vael Morrow, the Oathbreaker", "hp": 1450.0, "posture": 170.0, "speed": 7.2, "essence": 900.0, "range": 2.8, "cool": [0.4, 1.0], "boss": true, "reacts": true, "blade": true, "patience": 0.75, "mobility": 0.6,
		"phase_line": "\"Answer them,\" Vael says, and his blade answers.", "death_line": "Vael lays his blade down.",
		"body": {"feral": false, "scale": 1.18, "cloth": Color(0.92, 0.92, 0.94), "trim": Color(0.08, 0.08, 0.1), "accent": Color(0.55, 0.3, 1.0),
			"coat": 2, "sleeves": true, "hair": 2, "hair_color": Color(0.85, 0.85, 0.9), "hair_seed": 44, "face": 1, "sash": 2, "collar": true},
		"moves": [
			{"id": "v1", "clip": "light1", "startup": 0.3, "active": 0.08, "recover": 0.2, "dmg": 18.0, "posture": 14.0, "reach": 2.7, "arc": 150.0, "lunge": 7.0, "roll": 12.0, "w": 4.0, "then": "v2"},
			{"id": "v2", "clip": "light2", "startup": 0.24, "active": 0.08, "recover": 0.2, "dmg": 18.0, "posture": 14.0, "reach": 2.7, "arc": 150.0, "lunge": 7.0, "roll": -16.0, "w": 0.0, "then": "v3"},
			{"id": "v3", "clip": "light3", "startup": 0.34, "active": 0.09, "recover": 0.7, "dmg": 24.0, "posture": 18.0, "reach": 3.0, "arc": 60.0, "lunge": 8.0, "roll": 88.0, "w": 0.0},
			{"id": "cleave", "clip": "heavy", "startup": 0.7, "active": 0.1, "recover": 0.8, "dmg": 36.0, "posture": 30.0, "reach": 3.2, "arc": 70.0, "lunge": 9.0, "roll": 90.0, "heavy": true, "knock": 7.0, "w": 2.0, "red": true, "blockable": false, "parryable": false, "sfx": "whoosh_heavy"},
			{"id": "lances", "clip": "cast", "type": "bolt", "count": 3, "spread": 10.0, "startup": 0.55, "active": 0.06, "recover": 0.5, "dmg": 14.0, "posture": 10.0, "reach": 26.0, "arc": 20.0, "speed": 30.0, "w": 2.0, "min": 6.0, "sfx": "cast"},
		],
		"phase2": [
			{"id": "sunder", "clip": "heavy", "type": "wave", "startup": 0.7, "active": 0.12, "recover": 0.7, "dmg": 26.0, "posture": 24.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 16.0},
			{"id": "descend", "type": "leap", "clip": "heavy", "startup": 0.75, "active": 0.12, "recover": 0.9, "dmg": 30.0, "posture": 26.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 8.0, "w": 2.0, "min": 6.0, "red": true, "blockable": false, "parryable": false},
		],
	},
	"many_mouthed": {
		"name": "the Many-Mouthed", "hp": 1620.0, "posture": 300.0, "speed": 2.0, "essence": 820.0, "range": 26.0, "keep": 10.0, "cool": [1.0, 1.8], "armored": true, "boss": true,
		"phase_line": "Every mouth opens at once.", "death_line": "It folds up like a dropped coat.",
		"body": {"feral": true, "scale": 5.2, "bulk": 1.0, "leg": 1.3, "cloth": Color(0.04, 0.04, 0.05), "trim": BONE, "accent": Color(1.0, 0.2, 0.5),
			"coat": 2, "sleeves": false, "hair": 1, "hair_color": Color(0.9, 0.9, 0.9), "hair_seed": 55, "mask": 1, "mask_seed": 55, "hole": true, "collar": true},
		"moves": [
			{"id": "beam", "clip": "cast", "type": "bolt", "startup": 1.0, "active": 0.06, "recover": 0.8, "dmg": 34.0, "posture": 30.0, "reach": 44.0, "arc": 10.0, "speed": 62.0, "w": 3.0, "min": 5.0, "red": true, "parryable": false, "sfx": "cast"},
			{"id": "spit", "clip": "cast", "type": "bolt", "count": 5, "spread": 14.0, "startup": 0.9, "active": 0.06, "recover": 0.9, "dmg": 14.0, "posture": 10.0, "reach": 30.0, "arc": 20.0, "speed": 24.0, "w": 3.0, "min": 4.0, "sfx": "cast"},
			{"id": "stomp", "clip": "f_slam", "type": "ring", "startup": 1.1, "active": 0.12, "recover": 1.0, "dmg": 34.0, "posture": 30.0, "reach": 1.8, "arc": 360.0, "heavy": true, "knock": 12.0, "w": 3.0, "max": 12.0, "red": true, "blockable": false, "parryable": false, "sfx": "slam"},
		],
		"phase2": [
			{"id": "drone", "clip": "f_slam", "type": "wave", "startup": 0.9, "active": 0.12, "recover": 0.8, "dmg": 24.0, "posture": 22.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 13.0, "then": "spit"},
		],
	},
	"odrel": {
		"name": "Odrel, the Bell-Eater", "hp": 1250.0, "posture": 180.0, "speed": 4.2, "essence": 700.0, "range": 4.4, "cool": [0.7, 1.5], "armored": true, "boss": true,
		"phase_line": "The bell in its chest begins to ring.", "death_line": "The bell is quiet.",
		"body": {"feral": true, "scale": 2.5, "bulk": 1.15, "cloth": Color(0.92, 0.92, 0.9), "trim": Color(0.14, 0.14, 0.16), "accent": RED,
			"coat": 1, "sleeves": false, "hair": 1, "hair_color": Color(0.5, 0.06, 0.08), "hair_seed": 77, "mask": 3, "mask_seed": 77, "hole": true, "claws": true, "collar": true},
		"moves": [
			{"id": "claw", "clip": "f_swipe", "startup": 0.55, "active": 0.1, "recover": 0.3, "dmg": 16.0, "posture": 16.0, "reach": 2.3, "arc": 130.0, "lunge": 7.0, "roll": 14.0, "w": 4.0, "then": "claw2", "max": 8.0},
			{"id": "claw2", "clip": "f_swipe_l", "startup": 0.36, "active": 0.1, "recover": 0.3, "dmg": 16.0, "posture": 16.0, "reach": 2.3, "arc": 130.0, "lunge": 7.0, "roll": -14.0, "w": 0.0, "then": "claw3"},
			{"id": "claw3", "clip": "f_slam", "startup": 0.6, "active": 0.12, "recover": 1.1, "dmg": 26.0, "posture": 24.0, "reach": 2.5, "arc": 90.0, "lunge": 5.0, "roll": 90.0, "heavy": true, "knock": 8.0, "w": 0.0, "sfx": "whoosh_heavy"},
			{"id": "toll", "clip": "f_slam", "type": "wave", "startup": 1.0, "active": 0.12, "recover": 1.0, "dmg": 22.0, "posture": 26.0, "reach": 3.0, "arc": 360.0, "heavy": true, "knock": 6.0, "w": 3.0, "min": 3.0, "sfx": "toll", "wave_speed": 12.0},
			{"id": "leap", "type": "leap", "clip": "f_slam", "startup": 1.05, "active": 0.12, "recover": 1.25, "dmg": 34.0, "posture": 30.0, "reach": 1.9, "arc": 360.0,
				"blockable": false, "parryable": false, "heavy": true, "knock": 9.0, "w": 2.5, "min": 7.0, "red": true},
		],
		"phase2": [
			{"id": "toll2", "clip": "f_slam", "type": "wave", "startup": 0.8, "active": 0.12, "recover": 0.5, "dmg": 22.0, "posture": 26.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "min": 3.0, "sfx": "toll", "wave_speed": 15.0, "then": "toll"},
			{"id": "rake", "clip": "f_swipe", "startup": 0.5, "active": 0.14, "recover": 0.7, "dmg": 24.0, "posture": 20.0, "reach": 2.4, "arc": 150.0, "lunge": 16.0, "roll": 10.0, "heavy": true, "w": 3.0, "min": 5.0, "sfx": "whoosh_heavy"},
		],
	},
	"sereth": {
		"name": "Sereth, Queen of Dunes", "hp": 2300.0, "posture": 200.0, "speed": 8.0, "essence": 1300.0, "range": 2.8, "cool": [0.4, 1.0], "boss": true, "reacts": true, "patience": 0.45, "mobility": 0.8,
		"phase_line": "The sand stands up and wears her face.", "death_line": "The throne is empty.",
		"body": {"feral": false, "scale": 1.35, "cloth": Color(0.95, 0.94, 0.9), "trim": Color(0.6, 0.1, 0.12), "skin": Color(0.95, 0.94, 0.9), "accent": Color(1.0, 0.75, 0.2),
			"coat": 2, "sleeves": true, "hair": 2, "hair_color": Color(0.1, 0.08, 0.08), "hair_seed": 66, "mask_seed": 66, "fragment": true, "hole": true, "claws": true, "collar": true, "face": 3},
		"moves": [
			{"id": "s1", "clip": "f_swipe", "startup": 0.32, "active": 0.1, "recover": 0.2, "dmg": 20.0, "posture": 14.0, "reach": 2.5, "arc": 140.0, "lunge": 9.0, "roll": 14.0, "w": 4.0, "then": "s2"},
			{"id": "s2", "clip": "f_swipe_l", "startup": 0.26, "active": 0.1, "recover": 0.2, "dmg": 20.0, "posture": 14.0, "reach": 2.5, "arc": 140.0, "lunge": 9.0, "roll": -14.0, "w": 0.0, "then": "s3"},
			{"id": "s3", "clip": "thrust", "startup": 0.4, "active": 0.1, "recover": 0.8, "dmg": 28.0, "posture": 20.0, "reach": 3.0, "arc": 50.0, "lunge": 16.0, "w": 0.0},
			{"id": "glass", "clip": "cast", "type": "bolt", "count": 7, "spread": 9.0, "startup": 0.6, "active": 0.06, "recover": 0.6, "dmg": 13.0, "posture": 8.0, "reach": 28.0, "arc": 20.0, "speed": 28.0, "w": 2.0, "min": 6.0, "sfx": "cast"},
			{"id": "dive", "type": "leap", "clip": "f_slam", "startup": 0.7, "active": 0.12, "recover": 0.9, "dmg": 34.0, "posture": 28.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 9.0, "w": 2.0, "min": 6.0, "red": true, "blockable": false, "parryable": false},
		],
		"phase2": [
			{"id": "dune", "clip": "f_slam", "type": "wave", "startup": 0.7, "active": 0.12, "recover": 0.5, "dmg": 26.0, "posture": 24.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 17.0, "then": "dune2"},
			{"id": "dune2", "clip": "f_slam", "type": "wave", "startup": 0.6, "active": 0.12, "recover": 0.8, "dmg": 26.0, "posture": 24.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 0.0, "sfx": "toll", "wave_speed": 12.0},
		],
	},
	"ysolde": {
		"name": "Ysolde, the Last Lantern", "hp": 1350.0, "posture": 150.0, "speed": 6.6, "essence": 760.0, "range": 16.0, "keep": 9.0, "cool": [0.6, 1.2], "boss": true, "reacts": true, "blade": true, "patience": 0.35, "mobility": 0.85,
		"phase_line": "Every lantern on the lake goes out at once. Hers burns brighter.", "death_line": "The lanterns on the lake come back on, one by one.",
		"body": {"feral": false, "scale": 1.15, "cloth": Color(0.92, 0.94, 0.98), "trim": Color(0.2, 0.4, 0.8), "accent": Color(0.45, 0.85, 1.0),
			"coat": 2, "sleeves": true, "hair": 2, "hair_color": Color(0.85, 0.9, 0.98), "hair_seed": 88, "face": 0, "halo": true, "mask_seed": 88, "collar": true},
		"moves": [
			{"id": "volley", "clip": "cast", "type": "bolt", "count": 7, "spread": 8.0, "startup": 0.55, "active": 0.06, "recover": 0.5, "dmg": 12.0, "posture": 8.0, "reach": 30.0, "arc": 20.0, "speed": 30.0, "w": 4.0, "min": 5.0, "sfx": "cast"},
			{"id": "pierce", "clip": "cast", "type": "bolt", "startup": 0.9, "active": 0.06, "recover": 0.6, "dmg": 34.0, "posture": 26.0, "reach": 40.0, "arc": 10.0, "speed": 70.0, "w": 2.0, "min": 8.0, "red": true, "parryable": false, "sfx": "cast"},
			{"id": "cut", "clip": "light1", "startup": 0.3, "active": 0.08, "recover": 0.4, "dmg": 16.0, "posture": 14.0, "reach": 2.6, "arc": 150.0, "lunge": 6.0, "roll": 12.0, "w": 3.0, "max": 4.0, "then": "cut2"},
			{"id": "cut2", "clip": "light3", "startup": 0.3, "active": 0.09, "recover": 0.6, "dmg": 20.0, "posture": 16.0, "reach": 2.8, "arc": 60.0, "lunge": 7.0, "roll": 88.0, "w": 0.0},
			{"id": "away", "type": "leap", "clip": "cast", "startup": 0.6, "active": 0.06, "recover": 0.4, "dmg": 10.0, "posture": 8.0, "reach": 2.2, "arc": 360.0, "w": 2.0, "max": 5.0},
		],
		"phase2": [
			{"id": "frost", "clip": "slam", "type": "wave", "startup": 0.7, "active": 0.12, "recover": 0.6, "dmg": 22.0, "posture": 20.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 15.0, "then": "volley"},
			{"id": "storm", "clip": "cast", "type": "bolt", "count": 12, "spread": 30.0, "startup": 0.8, "active": 0.06, "recover": 0.8, "dmg": 10.0, "posture": 6.0, "reach": 30.0, "arc": 20.0, "speed": 22.0, "w": 2.0, "sfx": "cast"},
		],
	},
	"branded_king": {
		"name": "the Branded King", "hp": 2600.0, "posture": 260.0, "speed": 4.8, "essence": 1500.0, "range": 3.6, "cool": [0.6, 1.2], "armored": true, "boss": true, "regen": 0.004,
		"phase_line": "Every brand on his body opens like an eye.", "death_line": "The brands go dark, one by one.",
		"body": {"feral": false, "scale": 2.4, "bulk": 1.2, "cloth": Color(0.12, 0.08, 0.06), "trim": Color(0.85, 0.6, 0.15), "skin": Color(0.4, 0.3, 0.26), "accent": Color(1.0, 0.5, 0.1),
			"coat": 2, "sleeves": true, "hair": 1, "hair_color": Color(0.15, 0.1, 0.08), "hair_seed": 101, "mask": 3, "mask_seed": 101, "collar": true, "tether": 7, "claws": true},
		"moves": [
			{"id": "b1", "clip": "light1", "startup": 0.42, "active": 0.1, "recover": 0.25, "dmg": 26.0, "posture": 18.0, "reach": 2.4, "arc": 150.0, "lunge": 8.0, "roll": 12.0, "w": 4.0, "then": "b2"},
			{"id": "b2", "clip": "light2", "startup": 0.32, "active": 0.1, "recover": 0.25, "dmg": 26.0, "posture": 18.0, "reach": 2.4, "arc": 150.0, "lunge": 8.0, "roll": -16.0, "w": 0.0, "then": "b3"},
			{"id": "b3", "clip": "heavy", "startup": 0.55, "active": 0.12, "recover": 1.0, "dmg": 40.0, "posture": 30.0, "reach": 2.6, "arc": 90.0, "lunge": 6.0, "roll": 90.0, "heavy": true, "knock": 9.0, "w": 0.0, "sfx": "whoosh_heavy"},
			{"id": "chains", "clip": "thrust", "startup": 0.7, "active": 0.1, "recover": 0.6, "dmg": 18.0, "posture": 20.0, "reach": 6.0, "arc": 50.0, "pull": true, "w": 3.0, "min": 4.0, "sfx": "whoosh_heavy"},
			{"id": "brand", "clip": "slam", "type": "wave", "startup": 0.9, "active": 0.12, "recover": 0.8, "dmg": 30.0, "posture": 26.0, "reach": 3.0, "arc": 360.0, "heavy": true, "burn": true, "w": 2.0, "min": 4.0, "sfx": "toll", "wave_speed": 14.0},
		],
		"phase2": [
			{"id": "judgement", "type": "leap", "clip": "heavy", "startup": 0.9, "active": 0.12, "recover": 1.1, "dmg": 48.0, "posture": 34.0, "reach": 1.4, "arc": 360.0, "heavy": true, "knock": 10.0, "w": 2.5, "min": 6.0, "red": true, "blockable": false, "parryable": false},
			{"id": "pyre", "clip": "cast", "type": "bolt", "count": 9, "spread": 12.0, "startup": 0.7, "active": 0.06, "recover": 0.6, "dmg": 16.0, "posture": 10.0, "reach": 30.0, "arc": 20.0, "speed": 24.0, "burn": true, "w": 2.0, "min": 5.0, "sfx": "cast"},
		],
	},
	"gaoler_prime": {
		"name": "Gaoler Prime", "hp": 3600.0, "posture": 380.0, "speed": 2.6, "essence": 2200.0, "range": 5.0, "cool": [0.9, 1.6], "armored": true, "boss": true,
		"phase_line": "The chains holding the Undermark together pull taut, and he wears them.", "death_line": "The great chains go slack. Somewhere far above, a lock opens.",
		"body": {"feral": false, "scale": 4.6, "bulk": 1.4, "cloth": Color(0.06, 0.05, 0.05), "trim": Color(0.55, 0.5, 0.45), "skin": Color(0.3, 0.27, 0.26), "accent": Color(1.0, 0.3, 0.1),
			"coat": 2, "sleeves": false, "hair": -1, "mask": 3, "mask_seed": 102, "tether": 7, "collar": true},
		"moves": [
			{"id": "sweep", "clip": "heavy", "startup": 0.95, "active": 0.14, "recover": 0.8, "dmg": 38.0, "posture": 30.0, "reach": 2.0, "arc": 260.0, "lunge": 2.0, "roll": 90.0, "heavy": true, "knock": 9.0, "w": 4.0, "sfx": "whoosh_heavy"},
			{"id": "drag", "clip": "thrust", "startup": 0.8, "active": 0.1, "recover": 0.7, "dmg": 20.0, "posture": 24.0, "reach": 3.0, "arc": 40.0, "pull": true, "w": 3.0, "min": 6.0, "sfx": "whoosh_heavy"},
			{"id": "lockdown", "clip": "slam", "type": "ring", "startup": 1.1, "active": 0.12, "recover": 1.0, "dmg": 44.0, "posture": 34.0, "reach": 1.6, "arc": 360.0, "heavy": true, "knock": 11.0, "w": 3.0, "red": true, "blockable": false, "parryable": false, "sfx": "slam"},
			{"id": "tremor", "clip": "slam", "type": "wave", "startup": 0.95, "active": 0.12, "recover": 0.9, "dmg": 28.0, "posture": 24.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "min": 5.0, "sfx": "toll", "wave_speed": 12.0},
		],
		"phase2": [
			{"id": "fall", "type": "leap", "clip": "slam", "startup": 1.1, "active": 0.12, "recover": 1.3, "dmg": 50.0, "posture": 36.0, "reach": 1.3, "arc": 360.0, "heavy": true, "knock": 12.0, "w": 2.5, "min": 8.0, "red": true, "blockable": false, "parryable": false},
			{"id": "tremor2", "clip": "slam", "type": "wave", "startup": 0.7, "active": 0.12, "recover": 0.4, "dmg": 28.0, "posture": 24.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 2.0, "sfx": "toll", "wave_speed": 16.0, "then": "tremor"},
		],
	},
	"first_unwrit": {
		"name": "the First Unwrit", "hp": 4200.0, "posture": 240.0, "speed": 7.4, "essence": 3000.0, "range": 2.8, "cool": [0.35, 0.9], "boss": true, "reacts": true, "blade": true, "patience": 0.8, "mobility": 0.8,
		"phase_line": "\"I was struck from the Ledger before there were names,\" it says. \"So were you.\"", "death_line": "It kneels, and for a moment it has a name. Then it is gone.",
		"body": {"feral": false, "scale": 1.25, "cloth": Color(0.02, 0.02, 0.03), "trim": Color(0.95, 0.95, 0.97), "skin": Color(0.95, 0.95, 0.97), "accent": Color(1.0, 1.0, 1.0),
			"coat": 2, "sleeves": true, "hair": 0, "hair_color": Color(0.98, 0.98, 1.0), "hair_seed": 103, "face": -1, "fragment": true, "halo": true, "plates": true, "collar": true, "hole": true, "mask_seed": 103},
		"moves": [
			{"id": "u1", "clip": "light1", "startup": 0.26, "active": 0.08, "recover": 0.18, "dmg": 30.0, "posture": 18.0, "reach": 2.8, "arc": 150.0, "lunge": 8.0, "roll": 12.0, "w": 4.0, "then": "u2"},
			{"id": "u2", "clip": "light2", "startup": 0.22, "active": 0.08, "recover": 0.18, "dmg": 30.0, "posture": 18.0, "reach": 2.8, "arc": 150.0, "lunge": 8.0, "roll": -16.0, "w": 0.0, "then": "u3"},
			{"id": "u3", "clip": "light3", "startup": 0.3, "active": 0.09, "recover": 0.6, "dmg": 40.0, "posture": 24.0, "reach": 3.0, "arc": 60.0, "lunge": 9.0, "roll": 88.0, "w": 0.0},
			{"id": "unname", "clip": "heavy", "startup": 0.65, "active": 0.1, "recover": 0.8, "dmg": 56.0, "posture": 34.0, "reach": 3.4, "arc": 80.0, "lunge": 10.0, "roll": 90.0, "heavy": true, "knock": 8.0, "w": 2.0, "red": true, "blockable": false, "parryable": false, "sfx": "whoosh_heavy"},
			{"id": "erase", "clip": "cast", "type": "bolt", "count": 5, "spread": 10.0, "startup": 0.5, "active": 0.06, "recover": 0.5, "dmg": 22.0, "posture": 12.0, "reach": 30.0, "arc": 20.0, "speed": 34.0, "w": 2.0, "min": 6.0, "sfx": "cast"},
		],
		"phase2": [
			{"id": "void", "clip": "heavy", "type": "wave", "startup": 0.6, "active": 0.12, "recover": 0.5, "dmg": 34.0, "posture": 26.0, "reach": 3.0, "arc": 360.0, "heavy": true, "w": 3.0, "sfx": "toll", "wave_speed": 18.0, "then": "erase"},
			{"id": "descend", "type": "leap", "clip": "heavy", "startup": 0.6, "active": 0.12, "recover": 0.8, "dmg": 46.0, "posture": 30.0, "reach": 2.0, "arc": 360.0, "heavy": true, "knock": 9.0, "w": 2.0, "min": 6.0, "red": true, "blockable": false, "parryable": false},
		],
	},
	"echo": {
		"name": "The one in your blade", "hp": 170.0, "posture": 70.0, "speed": 6.4, "essence": 0.0, "range": 2.6, "cool": [0.5, 1.2], "echo": true, "boss": true, "reacts": true,
		"body": {"feral": false, "scale": 1.0, "cloth": Color(0.92, 0.92, 0.94), "trim": Color(0.08, 0.08, 0.1), "skin": Color(0.95, 0.95, 0.97), "accent": Color(0.8, 0.9, 1.0),
			"coat": 2, "sleeves": true},
		"moves": [
			{"id": "l1", "clip": "light1", "startup": 0.34, "active": 0.08, "recover": 0.22, "dmg": 10.0, "posture": 10.0, "reach": 2.5, "arc": 150.0, "lunge": 6.0, "roll": 12.0, "w": 4.0, "then": "l2"},
			{"id": "l2", "clip": "light2", "startup": 0.26, "active": 0.08, "recover": 0.22, "dmg": 10.0, "posture": 10.0, "reach": 2.5, "arc": 150.0, "lunge": 6.0, "roll": -16.0, "w": 0.0, "then": "l3"},
			{"id": "l3", "clip": "light3", "startup": 0.34, "active": 0.09, "recover": 0.7, "dmg": 15.0, "posture": 14.0, "reach": 2.8, "arc": 60.0, "lunge": 7.0, "roll": 88.0, "w": 0.0},
			{"id": "heavy", "clip": "heavy", "startup": 0.7, "active": 0.1, "recover": 0.8, "dmg": 24.0, "posture": 26.0, "reach": 3.0, "arc": 70.0, "lunge": 8.0, "roll": 90.0, "heavy": true, "knock": 7.0, "w": 2.0, "sfx": "whoosh_heavy",
				"blockable": false, "parryable": false, "red": true},
			{"id": "lance", "clip": "cast", "type": "bolt", "startup": 0.5, "active": 0.06, "recover": 0.5, "dmg": 12.0, "posture": 8.0, "reach": 24.0, "arc": 20.0, "speed": 26.0, "w": 2.0, "min": 6.0, "sfx": "cast"},
		],
	},
}


static func get_def(kind: String) -> Dictionary:
	return DEFS[kind]


## Affixes an ordinary enemy can be born with, deeper in the realms.
const AFFIXES: Dictionary = {
	"swift": {"word": "Swift", "color": Color(0.4, 1.0, 0.8)},
	"stone": {"word": "Stone", "color": Color(0.8, 0.75, 0.6)},
	"leech": {"word": "Leeching", "color": Color(1.0, 0.25, 0.35)},
	"volatile": {"word": "Volatile", "color": Color(1.0, 0.6, 0.15)},
}


static func is_boss(kind: String) -> bool:
	return bool((DEFS.get(kind, {}) as Dictionary).get("boss", false))

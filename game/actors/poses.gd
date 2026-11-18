class_name Poses
extends RefCounted
## Every animation in the game, as joint angles in degrees. A body is a set of
## blocks on pivots; a pose turns the pivots; a clip is poses over time.
##
## Joints: hips torso head | sl el (left shoulder, elbow) | sr er | hl kl
## (left hip, knee) | hr kr | w (blade in the right hand) | wl (left hand).
## "y" lowers or lifts the whole body.
## Limbs hang down, so +x swings a limb forward and -x on a knee bends it.
## The torso and head rise, so -x leans them forward. +y turns left.
## +z lifts the right arm out to the side; -z lifts the left.

const V0 := Vector3.ZERO

const IDLE := {
	"torso": Vector3(-4, 14, 0), "head": Vector3(2, -12, 0),
	"sr": Vector3(16, 0, 3), "er": Vector3(30, 0, 0), "w": Vector3(-38, 0, 0),
	"sl": Vector3(-8, 0, -3), "el": Vector3(24, 0, 0),
	"hl": Vector3(-11, 0, -6), "kl": Vector3(-9, 0, 0), "hr": Vector3(15, 0, 6), "kr": Vector3(-16, 0, 0),
	"y": -0.03,
}
const IDLE_B := {
	"torso": Vector3(-6.5, 14, 0), "head": Vector3(4, -12, 0),
	"sr": Vector3(19, 0, 4), "er": Vector3(33, 0, 0), "w": Vector3(-41, 0, 0),
	"sl": Vector3(-6, 0, -4), "el": Vector3(27, 0, 0),
	"hl": Vector3(-12, 0, -6), "kl": Vector3(-12, 0, 0), "hr": Vector3(17, 0, 6), "kr": Vector3(-20, 0, 0),
	"y": -0.05,
}

const RUN_A := {
	"torso": Vector3(-22, 8, 0), "head": Vector3(14, -6, 0),
	"hl": Vector3(48, 0, 0), "kl": Vector3(-18, 0, 0), "hr": Vector3(-32, 0, 0), "kr": Vector3(-50, 0, 0),
	"sl": Vector3(-42, 0, -8), "el": Vector3(45, 0, 0),
	"sr": Vector3(-38, 0, 14), "er": Vector3(28, 0, 0), "w": Vector3(-150, 0, 0), "y": 0.0,
}
const RUN_P1 := {
	"torso": Vector3(-24, 0, 0), "head": Vector3(15, 0, 0),
	"hl": Vector3(4, 0, 0), "kl": Vector3(-6, 0, 0), "hr": Vector3(18, 0, 0), "kr": Vector3(-88, 0, 0),
	"sl": Vector3(0, 0, -8), "el": Vector3(55, 0, 0),
	"sr": Vector3(-42, 0, 14), "er": Vector3(24, 0, 0), "w": Vector3(-152, 0, 0), "y": -0.07,
}
const RUN_B := {
	"torso": Vector3(-22, -8, 0), "head": Vector3(14, 6, 0),
	"hl": Vector3(-32, 0, 0), "kl": Vector3(-50, 0, 0), "hr": Vector3(48, 0, 0), "kr": Vector3(-18, 0, 0),
	"sl": Vector3(40, 0, -8), "el": Vector3(45, 0, 0),
	"sr": Vector3(-46, 0, 14), "er": Vector3(28, 0, 0), "w": Vector3(-150, 0, 0), "y": 0.0,
}
const RUN_P2 := {
	"torso": Vector3(-24, 0, 0), "head": Vector3(15, 0, 0),
	"hl": Vector3(18, 0, 0), "kl": Vector3(-88, 0, 0), "hr": Vector3(4, 0, 0), "kr": Vector3(-6, 0, 0),
	"sl": Vector3(0, 0, -8), "el": Vector3(55, 0, 0),
	"sr": Vector3(-42, 0, 14), "er": Vector3(24, 0, 0), "w": Vector3(-152, 0, 0), "y": -0.07,
}

const DASH := {
	"torso": Vector3(-46, 0, 0), "head": Vector3(30, 0, 0),
	"hl": Vector3(58, 0, 0), "kl": Vector3(-35, 0, 0), "hr": Vector3(-50, 0, 0), "kr": Vector3(-30, 0, 0),
	"sl": Vector3(-70, 0, -14), "el": Vector3(10, 0, 0),
	"sr": Vector3(-70, 0, 14), "er": Vector3(10, 0, 0), "w": Vector3(-170, 0, 0), "y": -0.2,
}
const AIR := {
	"torso": Vector3(-8, 0, 0), "head": Vector3(4, 0, 0),
	"hl": Vector3(38, 0, -6), "kl": Vector3(-62, 0, 0), "hr": Vector3(8, 0, 6), "kr": Vector3(-38, 0, 0),
	"sl": Vector3(-10, 0, -42), "el": Vector3(25, 0, 0),
	"sr": Vector3(-14, 0, 38), "er": Vector3(25, 0, 0), "w": Vector3(-120, 0, 0),
}
const BLOCK := {
	"torso": Vector3(-8, 10, 0), "head": Vector3(6, -8, 0),
	"sr": Vector3(72, 38, 18), "er": Vector3(52, 0, 0), "w": Vector3(48, 0, 62),
	"sl": Vector3(74, -28, -8), "el": Vector3(64, 0, 0),
	"hl": Vector3(-18, 0, -8), "kl": Vector3(-14, 0, 0), "hr": Vector3(22, 0, 8), "kr": Vector3(-30, 0, 0),
	"y": -0.1,
}
const PARRY := {
	"torso": Vector3(-4, -22, 0), "head": Vector3(4, 18, 0),
	"sr": Vector3(86, -18, 52), "er": Vector3(26, 0, 0), "w": Vector3(70, 0, 24),
	"sl": Vector3(20, 0, -30), "el": Vector3(40, 0, 0),
	"hl": Vector3(-20, 0, -8), "kl": Vector3(-10, 0, 0), "hr": Vector3(26, 0, 8), "kr": Vector3(-30, 0, 0),
	"y": -0.08,
}
const HIT := {
	"torso": Vector3(20, -14, 0), "head": Vector3(-16, 10, 0),
	"sl": Vector3(-10, 0, -48), "el": Vector3(30, 0, 0), "sr": Vector3(-14, 0, 44), "er": Vector3(30, 0, 0),
	"w": Vector3(-70, 0, 0),
	"hl": Vector3(-10, 0, -6), "kl": Vector3(-20, 0, 0), "hr": Vector3(-4, 0, 6), "kr": Vector3(-26, 0, 0), "y": -0.08,
}
const STAGGER_A := {
	"torso": Vector3(-36, 8, 0), "head": Vector3(-22, 0, 0),
	"sl": Vector3(26, 0, -10), "el": Vector3(12, 0, 0), "sr": Vector3(22, 0, 10), "er": Vector3(10, 0, 0), "w": Vector3(-95, 0, 0),
	"hl": Vector3(24, 0, -8), "kl": Vector3(-44, 0, 0), "hr": Vector3(18, 0, 8), "kr": Vector3(-42, 0, 0), "y": -0.2,
}
const STAGGER_B := {
	"torso": Vector3(-42, -8, 0), "head": Vector3(-26, 0, 0),
	"sl": Vector3(30, 0, -12), "el": Vector3(16, 0, 0), "sr": Vector3(28, 0, 12), "er": Vector3(14, 0, 0), "w": Vector3(-100, 0, 0),
	"hl": Vector3(28, 0, -8), "kl": Vector3(-52, 0, 0), "hr": Vector3(22, 0, 8), "kr": Vector3(-48, 0, 0), "y": -0.26,
}
const DEAD_A := {
	"hips": Vector3(30, 0, 0), "torso": Vector3(24, 0, 0), "head": Vector3(-30, 0, 0),
	"sl": Vector3(-30, 0, -70), "sr": Vector3(-30, 0, 70), "w": Vector3(-90, 0, 0),
	"hl": Vector3(30, 0, -8), "kl": Vector3(-70, 0, 0), "hr": Vector3(20, 0, 8), "kr": Vector3(-60, 0, 0), "y": -0.3,
}
const DEAD_B := {
	"hips": Vector3(88, 0, 0), "torso": Vector3(2, 0, 0), "head": Vector3(-6, 14, 0),
	"sl": Vector3(-10, 0, -76), "el": Vector3(20, 0, 0), "sr": Vector3(-14, 0, 64), "er": Vector3(30, 0, 0), "w": Vector3(-90, 0, 40),
	"hl": Vector3(6, 0, -14), "kl": Vector3(-10, 0, 0), "hr": Vector3(-4, 0, 10), "kr": Vector3(-34, 0, 0), "y": -0.74,
}
const MEDITATE := {
	"torso": Vector3(-3, 0, 0), "head": Vector3(-12, 0, 0),
	"hl": Vector3(96, 0, -38), "kl": Vector3(-132, 0, 0), "hr": Vector3(96, 0, 38), "kr": Vector3(-132, 0, 0),
	"sl": Vector3(34, 0, -14), "el": Vector3(52, 0, 0), "sr": Vector3(34, 0, 14), "er": Vector3(52, 0, 0),
	"w": Vector3(-8, 78, 0), "y": -0.74,
}
const MEDITATE_B := {
	"torso": Vector3(-6, 0, 0), "head": Vector3(-15, 0, 0),
	"hl": Vector3(96, 0, -38), "kl": Vector3(-132, 0, 0), "hr": Vector3(96, 0, 38), "kr": Vector3(-132, 0, 0),
	"sl": Vector3(36, 0, -15), "el": Vector3(55, 0, 0), "sr": Vector3(36, 0, 15), "er": Vector3(55, 0, 0),
	"w": Vector3(-8, 78, 0), "y": -0.755,
}
const KNEEL := {
	"torso": Vector3(-52, 0, 0), "head": Vector3(-8, 0, 0),
	"hl": Vector3(84, 0, -8), "kl": Vector3(-110, 0, 0), "hr": Vector3(-6, 0, 6), "kr": Vector3(-96, 0, 0),
	"sl": Vector3(64, 0, -6), "el": Vector3(10, 0, 0), "sr": Vector3(-20, 0, 16), "er": Vector3(30, 0, 0), "w": Vector3(-100, 0, 0),
	"y": -0.5,
}
const RELEASE_A := {
	"torso": Vector3(-28, 0, 0), "head": Vector3(-20, 0, 0),
	"sl": Vector3(40, 30, -10), "el": Vector3(95, 0, 0), "sr": Vector3(40, -30, 10), "er": Vector3(95, 0, 0), "w": Vector3(20, 0, 0),
	"hl": Vector3(24, 0, -10), "kl": Vector3(-50, 0, 0), "hr": Vector3(24, 0, 10), "kr": Vector3(-50, 0, 0), "y": -0.24,
}
const RELEASE_B := {
	"torso": Vector3(20, 0, 0), "head": Vector3(26, 0, 0),
	"sl": Vector3(-10, 0, -112), "el": Vector3(8, 0, 0), "sr": Vector3(-10, 0, 112), "er": Vector3(8, 0, 0), "w": Vector3(-90, 0, 0),
	"hl": Vector3(-6, 0, -14), "kl": Vector3(-8, 0, 0), "hr": Vector3(-6, 0, 14), "kr": Vector3(-8, 0, 0), "y": 0.02,
}
const RELEASE_C := {
	"torso": Vector3(-6, 14, 0), "head": Vector3(6, -12, 0),
	"sl": Vector3(-14, 0, -24), "el": Vector3(30, 0, 0), "sr": Vector3(60, 0, 30), "er": Vector3(12, 0, 0), "w": Vector3(-30, 0, 0),
	"hl": Vector3(-14, 0, -8), "kl": Vector3(-10, 0, 0), "hr": Vector3(18, 0, 8), "kr": Vector3(-20, 0, 0), "y": -0.04,
}

# ---- attacks: [wind, contact, follow]

const LIGHT1 := [
	{"torso": Vector3(-6, -36, 0), "head": Vector3(4, 30, 0), "sr": Vector3(0, -34, 86), "er": Vector3(22, 0, 0), "w": Vector3(-60, 0, 0),
		"sl": Vector3(20, 0, -20), "el": Vector3(50, 0, 0), "hl": Vector3(-14, 0, -6), "kl": Vector3(-12, 0, 0), "hr": Vector3(16, 0, 6), "kr": Vector3(-22, 0, 0), "y": -0.08},
	{"torso": Vector3(-14, 22, 0), "head": Vector3(8, -18, 0), "sr": Vector3(0, 84, 86), "er": Vector3(6, 0, 0), "w": Vector3(-62, 0, 0),
		"sl": Vector3(-30, 0, -26), "el": Vector3(30, 0, 0), "hl": Vector3(-26, 0, -6), "kl": Vector3(-8, 0, 0), "hr": Vector3(34, 0, 6), "kr": Vector3(-36, 0, 0), "y": -0.13},
	{"torso": Vector3(-12, 48, 0), "head": Vector3(8, -40, 0), "sr": Vector3(0, 146, 80), "er": Vector3(24, 0, 0), "w": Vector3(-66, 0, 0),
		"sl": Vector3(-36, 0, -30), "el": Vector3(30, 0, 0), "hl": Vector3(-28, 0, -6), "kl": Vector3(-10, 0, 0), "hr": Vector3(32, 0, 6), "kr": Vector3(-34, 0, 0), "y": -0.12},
]
const LIGHT2 := [
	{"torso": Vector3(-8, 44, 0), "head": Vector3(4, -38, 0), "sr": Vector3(0, 150, 82), "er": Vector3(30, 0, 0), "w": Vector3(-116, 0, 0),
		"sl": Vector3(-20, 0, -18), "el": Vector3(40, 0, 0), "hl": Vector3(18, 0, -6), "kl": Vector3(-24, 0, 0), "hr": Vector3(-12, 0, 6), "kr": Vector3(-10, 0, 0), "y": -0.09},
	{"torso": Vector3(-14, -18, 0), "head": Vector3(8, 16, 0), "sr": Vector3(0, 66, 88), "er": Vector3(6, 0, 0), "w": Vector3(-116, 0, 0),
		"sl": Vector3(24, 0, -34), "el": Vector3(34, 0, 0), "hl": Vector3(36, 0, -6), "kl": Vector3(-38, 0, 0), "hr": Vector3(-26, 0, 6), "kr": Vector3(-8, 0, 0), "y": -0.13},
	{"torso": Vector3(-10, -46, 0), "head": Vector3(6, 40, 0), "sr": Vector3(0, -30, 86), "er": Vector3(20, 0, 0), "w": Vector3(-112, 0, 0),
		"sl": Vector3(30, 0, -38), "el": Vector3(34, 0, 0), "hl": Vector3(34, 0, -6), "kl": Vector3(-36, 0, 0), "hr": Vector3(-28, 0, 6), "kr": Vector3(-10, 0, 0), "y": -0.12},
]
const LIGHT3 := [
	{"torso": Vector3(12, 6, 0), "head": Vector3(-6, 0, 0), "sr": Vector3(168, 0, 10), "er": Vector3(28, 0, 0), "w": Vector3(-58, 0, 0),
		"sl": Vector3(40, 0, -16), "el": Vector3(40, 0, 0), "hl": Vector3(20, 0, -6), "kl": Vector3(-40, 0, 0), "hr": Vector3(-10, 0, 6), "kr": Vector3(-24, 0, 0), "y": 0.04},
	{"torso": Vector3(-26, 6, 0), "head": Vector3(16, 0, 0), "sr": Vector3(64, 0, 6), "er": Vector3(8, 0, 0), "w": Vector3(-108, 0, 0),
		"sl": Vector3(-34, 0, -22), "el": Vector3(24, 0, 0), "hl": Vector3(-30, 0, -6), "kl": Vector3(-10, 0, 0), "hr": Vector3(40, 0, 6), "kr": Vector3(-44, 0, 0), "y": -0.18},
	{"torso": Vector3(-36, 6, 0), "head": Vector3(20, 0, 0), "sr": Vector3(18, 0, 6), "er": Vector3(10, 0, 0), "w": Vector3(-122, 0, 0),
		"sl": Vector3(-40, 0, -24), "el": Vector3(24, 0, 0), "hl": Vector3(-34, 0, -6), "kl": Vector3(-12, 0, 0), "hr": Vector3(44, 0, 6), "kr": Vector3(-50, 0, 0), "y": -0.24},
]
const HEAVY := [
	{"torso": Vector3(16, 0, 0), "head": Vector3(-10, 0, 0), "sr": Vector3(172, 0, -8), "er": Vector3(38, 0, 0), "w": Vector3(-56, 0, 0),
		"sl": Vector3(166, 0, 8), "el": Vector3(42, 0, 0), "hl": Vector3(10, 0, -10), "kl": Vector3(-30, 0, 0), "hr": Vector3(10, 0, 10), "kr": Vector3(-30, 0, 0), "y": -0.1},
	{"torso": Vector3(-34, 0, 0), "head": Vector3(22, 0, 0), "sr": Vector3(58, 0, -10), "er": Vector3(14, 0, 0), "w": Vector3(-112, 0, 0),
		"sl": Vector3(62, 0, 10), "el": Vector3(20, 0, 0), "hl": Vector3(-34, 0, -10), "kl": Vector3(-14, 0, 0), "hr": Vector3(46, 0, 10), "kr": Vector3(-56, 0, 0), "y": -0.26},
	{"torso": Vector3(-44, 0, 0), "head": Vector3(26, 0, 0), "sr": Vector3(26, 0, -10), "er": Vector3(12, 0, 0), "w": Vector3(-124, 0, 0),
		"sl": Vector3(32, 0, 10), "el": Vector3(18, 0, 0), "hl": Vector3(-38, 0, -10), "kl": Vector3(-16, 0, 0), "hr": Vector3(50, 0, 10), "kr": Vector3(-62, 0, 0), "y": -0.33},
]
const AIRCUT := [
	{"torso": Vector3(4, -40, 0), "head": Vector3(0, 30, 0), "sr": Vector3(128, -24, 58), "er": Vector3(30, 0, 0), "w": Vector3(-60, 0, 0),
		"sl": Vector3(10, 0, -50), "el": Vector3(30, 0, 0), "hl": Vector3(44, 0, -6), "kl": Vector3(-74, 0, 0), "hr": Vector3(20, 0, 6), "kr": Vector3(-60, 0, 0)},
	{"torso": Vector3(-20, 30, 0), "head": Vector3(12, -22, 0), "sr": Vector3(56, 62, 40), "er": Vector3(8, 0, 0), "w": Vector3(-104, 0, 0),
		"sl": Vector3(-40, 0, -40), "el": Vector3(20, 0, 0), "hl": Vector3(10, 0, -6), "kl": Vector3(-30, 0, 0), "hr": Vector3(-30, 0, 6), "kr": Vector3(-40, 0, 0)},
	{"torso": Vector3(-26, 50, 0), "head": Vector3(14, -40, 0), "sr": Vector3(10, 104, 30), "er": Vector3(14, 0, 0), "w": Vector3(-116, 0, 0),
		"sl": Vector3(-46, 0, -42), "el": Vector3(20, 0, 0), "hl": Vector3(4, 0, -6), "kl": Vector3(-24, 0, 0), "hr": Vector3(-34, 0, 6), "kr": Vector3(-44, 0, 0)},
]
const THRUST := [
	{"torso": Vector3(-10, -40, 0), "head": Vector3(6, 36, 0), "sr": Vector3(-30, 0, 30), "er": Vector3(96, 0, 0), "w": Vector3(6, 0, 0),
		"sl": Vector3(60, 0, -10), "el": Vector3(20, 0, 0), "hl": Vector3(-20, 0, -6), "kl": Vector3(-20, 0, 0), "hr": Vector3(26, 0, 6), "kr": Vector3(-40, 0, 0), "y": -0.16},
	{"torso": Vector3(-30, 30, 0), "head": Vector3(22, -26, 0), "sr": Vector3(86, 20, 8), "er": Vector3(4, 0, 0), "w": Vector3(-88, 0, 0),
		"sl": Vector3(-50, 0, -20), "el": Vector3(16, 0, 0), "hl": Vector3(-44, 0, -6), "kl": Vector3(-6, 0, 0), "hr": Vector3(56, 0, 6), "kr": Vector3(-60, 0, 0), "y": -0.26},
	{"torso": Vector3(-30, 34, 0), "head": Vector3(22, -30, 0), "sr": Vector3(82, 24, 8), "er": Vector3(8, 0, 0), "w": Vector3(-88, 0, 0),
		"sl": Vector3(-52, 0, -20), "el": Vector3(16, 0, 0), "hl": Vector3(-44, 0, -6), "kl": Vector3(-8, 0, 0), "hr": Vector3(54, 0, 6), "kr": Vector3(-58, 0, 0), "y": -0.25},
]
const RISE := [
	{"torso": Vector3(-40, -20, 0), "head": Vector3(20, 16, 0), "sr": Vector3(-30, 0, 20), "er": Vector3(20, 0, 0), "w": Vector3(-130, 0, 0),
		"sl": Vector3(30, 0, -20), "el": Vector3(40, 0, 0), "hl": Vector3(40, 0, -8), "kl": Vector3(-80, 0, 0), "hr": Vector3(30, 0, 8), "kr": Vector3(-70, 0, 0), "y": -0.36},
	{"torso": Vector3(4, 14, 0), "head": Vector3(-10, -10, 0), "sr": Vector3(110, 10, 14), "er": Vector3(8, 0, 0), "w": Vector3(-80, 0, 0),
		"sl": Vector3(-30, 0, -30), "el": Vector3(20, 0, 0), "hl": Vector3(-10, 0, -6), "kl": Vector3(-6, 0, 0), "hr": Vector3(20, 0, 6), "kr": Vector3(-30, 0, 0), "y": 0.02},
	{"torso": Vector3(14, 24, 0), "head": Vector3(-16, -18, 0), "sr": Vector3(168, 10, 14), "er": Vector3(14, 0, 0), "w": Vector3(-70, 0, 0),
		"sl": Vector3(-40, 0, -34), "el": Vector3(20, 0, 0), "hl": Vector3(-14, 0, -6), "kl": Vector3(-6, 0, 0), "hr": Vector3(30, 0, 6), "kr": Vector3(-50, 0, 0), "y": 0.08},
]
const CAST := [
	{"torso": Vector3(-4, 34, 0), "head": Vector3(2, -30, 0), "sl": Vector3(-50, 0, -30), "el": Vector3(80, 0, 0),
		"sr": Vector3(10, 0, 16), "er": Vector3(30, 0, 0), "w": Vector3(-110, 0, 0), "hl": Vector3(14, 0, -6), "kl": Vector3(-20, 0, 0), "hr": Vector3(-10, 0, 6), "kr": Vector3(-10, 0, 0), "y": -0.06},
	{"torso": Vector3(-14, -24, 0), "head": Vector3(8, 20, 0), "sl": Vector3(88, 0, -6), "el": Vector3(4, 0, 0),
		"sr": Vector3(-20, 0, 20), "er": Vector3(30, 0, 0), "w": Vector3(-110, 0, 0), "hl": Vector3(30, 0, -6), "kl": Vector3(-34, 0, 0), "hr": Vector3(-22, 0, 6), "kr": Vector3(-8, 0, 0), "y": -0.12},
	{"torso": Vector3(-14, -28, 0), "head": Vector3(8, 24, 0), "sl": Vector3(80, 0, -6), "el": Vector3(10, 0, 0),
		"sr": Vector3(-22, 0, 20), "er": Vector3(30, 0, 0), "w": Vector3(-110, 0, 0), "hl": Vector3(30, 0, -6), "kl": Vector3(-34, 0, 0), "hr": Vector3(-22, 0, 6), "kr": Vector3(-8, 0, 0), "y": -0.12},
]
const SLAM := [
	{"torso": Vector3(-30, 0, 0), "head": Vector3(10, 0, 0), "sr": Vector3(150, 0, 20), "er": Vector3(60, 0, 0), "w": Vector3(-60, 0, 0),
		"sl": Vector3(40, 0, -20), "el": Vector3(60, 0, 0), "hl": Vector3(30, 0, -10), "kl": Vector3(-70, 0, 0), "hr": Vector3(30, 0, 10), "kr": Vector3(-70, 0, 0), "y": -0.3},
	{"torso": Vector3(-54, 0, 0), "head": Vector3(30, 0, 0), "sr": Vector3(66, 0, 4), "er": Vector3(6, 0, 0), "w": Vector3(-110, 0, 0),
		"sl": Vector3(-20, 0, -30), "el": Vector3(30, 0, 0), "hl": Vector3(60, 0, -10), "kl": Vector3(-100, 0, 0), "hr": Vector3(-20, 0, 10), "kr": Vector3(-70, 0, 0), "y": -0.46},
	{"torso": Vector3(-56, 0, 0), "head": Vector3(30, 0, 0), "sr": Vector3(60, 0, 4), "er": Vector3(8, 0, 0), "w": Vector3(-110, 0, 0),
		"sl": Vector3(-20, 0, -30), "el": Vector3(30, 0, 0), "hl": Vector3(60, 0, -10), "kl": Vector3(-100, 0, 0), "hr": Vector3(-20, 0, 10), "kr": Vector3(-70, 0, 0), "y": -0.47},
]

# ---- feral bodies: long arms, hunched, masked

const F_IDLE := {
	"torso": Vector3(-30, 0, 0), "head": Vector3(22, 0, 0),
	"sl": Vector3(26, 0, -14), "el": Vector3(18, 0, 0), "sr": Vector3(26, 0, 14), "er": Vector3(18, 0, 0),
	"hl": Vector3(28, 0, -10), "kl": Vector3(-50, 0, 0), "hr": Vector3(28, 0, 10), "kr": Vector3(-50, 0, 0), "y": -0.16,
}
const F_IDLE_B := {
	"torso": Vector3(-34, 4, 0), "head": Vector3(26, -6, 0),
	"sl": Vector3(30, 0, -16), "el": Vector3(22, 0, 0), "sr": Vector3(24, 0, 12), "er": Vector3(16, 0, 0),
	"hl": Vector3(30, 0, -10), "kl": Vector3(-56, 0, 0), "hr": Vector3(30, 0, 10), "kr": Vector3(-56, 0, 0), "y": -0.2,
}
const F_RUN_A := {
	"torso": Vector3(-44, 8, 0), "head": Vector3(34, -6, 0),
	"hl": Vector3(56, 0, -6), "kl": Vector3(-30, 0, 0), "hr": Vector3(-26, 0, 6), "kr": Vector3(-60, 0, 0),
	"sl": Vector3(-30, 0, -16), "el": Vector3(30, 0, 0), "sr": Vector3(60, 0, 16), "er": Vector3(20, 0, 0), "y": -0.16,
}
const F_RUN_B := {
	"torso": Vector3(-44, -8, 0), "head": Vector3(34, 6, 0),
	"hl": Vector3(-26, 0, -6), "kl": Vector3(-60, 0, 0), "hr": Vector3(56, 0, 6), "kr": Vector3(-30, 0, 0),
	"sl": Vector3(60, 0, -16), "el": Vector3(20, 0, 0), "sr": Vector3(-30, 0, 16), "er": Vector3(30, 0, 0), "y": -0.16,
}
const F_SWIPE := [
	{"torso": Vector3(-20, -44, 0), "head": Vector3(14, 36, 0), "sr": Vector3(-20, -40, 96), "er": Vector3(40, 0, 0),
		"sl": Vector3(30, 0, -20), "el": Vector3(40, 0, 0), "hl": Vector3(20, 0, -10), "kl": Vector3(-50, 0, 0), "hr": Vector3(34, 0, 10), "kr": Vector3(-60, 0, 0), "y": -0.2},
	{"torso": Vector3(-36, 30, 0), "head": Vector3(24, -24, 0), "sr": Vector3(10, 96, 80), "er": Vector3(6, 0, 0),
		"sl": Vector3(-30, 0, -30), "el": Vector3(30, 0, 0), "hl": Vector3(-20, 0, -10), "kl": Vector3(-30, 0, 0), "hr": Vector3(50, 0, 10), "kr": Vector3(-64, 0, 0), "y": -0.24},
	{"torso": Vector3(-36, 56, 0), "head": Vector3(24, -46, 0), "sr": Vector3(10, 150, 70), "er": Vector3(20, 0, 0),
		"sl": Vector3(-34, 0, -30), "el": Vector3(30, 0, 0), "hl": Vector3(-22, 0, -10), "kl": Vector3(-30, 0, 0), "hr": Vector3(50, 0, 10), "kr": Vector3(-64, 0, 0), "y": -0.24},
]
const F_SWIPE_L := [
	{"torso": Vector3(-20, 44, 0), "head": Vector3(14, -36, 0), "sl": Vector3(-20, 40, -96), "el": Vector3(40, 0, 0),
		"sr": Vector3(30, 0, 20), "er": Vector3(40, 0, 0), "hl": Vector3(34, 0, -10), "kl": Vector3(-60, 0, 0), "hr": Vector3(20, 0, 10), "kr": Vector3(-50, 0, 0), "y": -0.2},
	{"torso": Vector3(-36, -30, 0), "head": Vector3(24, 24, 0), "sl": Vector3(10, -96, -80), "el": Vector3(6, 0, 0),
		"sr": Vector3(-30, 0, 30), "er": Vector3(30, 0, 0), "hl": Vector3(50, 0, -10), "kl": Vector3(-64, 0, 0), "hr": Vector3(-20, 0, 10), "kr": Vector3(-30, 0, 0), "y": -0.24},
	{"torso": Vector3(-36, -56, 0), "head": Vector3(24, 46, 0), "sl": Vector3(10, -150, -70), "el": Vector3(20, 0, 0),
		"sr": Vector3(-34, 0, 30), "er": Vector3(30, 0, 0), "hl": Vector3(50, 0, -10), "kl": Vector3(-64, 0, 0), "hr": Vector3(-22, 0, 10), "kr": Vector3(-30, 0, 0), "y": -0.24},
]
const F_SLAM := [
	{"torso": Vector3(18, 0, 0), "head": Vector3(-6, 0, 0), "sr": Vector3(176, 0, -10), "er": Vector3(30, 0, 0), "sl": Vector3(176, 0, 10), "el": Vector3(30, 0, 0),
		"hl": Vector3(14, 0, -12), "kl": Vector3(-34, 0, 0), "hr": Vector3(14, 0, 12), "kr": Vector3(-34, 0, 0), "y": -0.06},
	{"torso": Vector3(-50, 0, 0), "head": Vector3(34, 0, 0), "sr": Vector3(50, 0, -8), "er": Vector3(8, 0, 0), "sl": Vector3(50, 0, 8), "el": Vector3(8, 0, 0),
		"hl": Vector3(40, 0, -12), "kl": Vector3(-74, 0, 0), "hr": Vector3(40, 0, 12), "kr": Vector3(-74, 0, 0), "y": -0.34},
	{"torso": Vector3(-56, 0, 0), "head": Vector3(36, 0, 0), "sr": Vector3(40, 0, -8), "er": Vector3(8, 0, 0), "sl": Vector3(40, 0, 8), "el": Vector3(8, 0, 0),
		"hl": Vector3(44, 0, -12), "kl": Vector3(-80, 0, 0), "hr": Vector3(44, 0, 12), "kr": Vector3(-80, 0, 0), "y": -0.38},
]
const F_ROAR_A := {
	"torso": Vector3(-50, 0, 0), "head": Vector3(10, 0, 0), "sl": Vector3(40, 0, -30), "el": Vector3(70, 0, 0), "sr": Vector3(40, 0, 30), "er": Vector3(70, 0, 0),
	"hl": Vector3(40, 0, -14), "kl": Vector3(-70, 0, 0), "hr": Vector3(40, 0, 14), "kr": Vector3(-70, 0, 0), "y": -0.32,
}
const F_ROAR_B := {
	"torso": Vector3(24, 0, 0), "head": Vector3(34, 0, 0), "sl": Vector3(-30, 0, -84), "el": Vector3(20, 0, 0), "sr": Vector3(-30, 0, 84), "er": Vector3(20, 0, 0),
	"hl": Vector3(4, 0, -16), "kl": Vector3(-20, 0, 0), "hr": Vector3(4, 0, 16), "kr": Vector3(-20, 0, 0), "y": -0.04,
}
const F_LEAP := {
	"torso": Vector3(-20, 0, 0), "head": Vector3(20, 0, 0), "sl": Vector3(150, 0, -30), "el": Vector3(30, 0, 0), "sr": Vector3(150, 0, 30), "er": Vector3(30, 0, 0),
	"hl": Vector3(60, 0, -12), "kl": Vector3(-100, 0, 0), "hr": Vector3(40, 0, 12), "kr": Vector3(-90, 0, 0), "y": 0.0,
}

const CLIPS := {
	"idle": {"len": 2.8, "loop": true, "keys": [[0.0, IDLE], [1.4, IDLE_B], [2.8, IDLE]]},
	"run": {"len": 0.52, "loop": true, "keys": [[0.0, RUN_A], [0.13, RUN_P1], [0.26, RUN_B], [0.39, RUN_P2], [0.52, RUN_A]]},
	"dash": {"len": 0.3, "loop": false, "keys": [[0.0, DASH], [0.3, DASH]]},
	"air": {"len": 0.6, "loop": false, "keys": [[0.0, AIR], [0.6, AIR]]},
	"block": {"len": 0.4, "loop": false, "keys": [[0.0, BLOCK], [0.4, BLOCK]]},
	"parry": {"len": 0.3, "loop": false, "keys": [[0.0, PARRY], [0.16, PARRY], [0.3, BLOCK]]},
	"hit": {"len": 0.34, "loop": false, "keys": [[0.0, HIT], [0.12, HIT], [0.34, IDLE]]},
	"stagger": {"len": 0.9, "loop": true, "keys": [[0.0, STAGGER_A], [0.45, STAGGER_B], [0.9, STAGGER_A]]},
	"dead": {"len": 0.9, "loop": false, "keys": [[0.0, HIT], [0.3, DEAD_A], [0.75, DEAD_B], [0.9, DEAD_B]]},
	"meditate": {"len": 4.0, "loop": true, "keys": [[0.0, MEDITATE], [2.0, MEDITATE_B], [4.0, MEDITATE]]},
	"kneel": {"len": 0.6, "loop": false, "keys": [[0.0, KNEEL], [0.6, KNEEL]]},
	"release": {"len": 2.0, "loop": false, "keys": [[0.0, RELEASE_A], [0.7, RELEASE_A], [0.95, RELEASE_B], [1.6, RELEASE_B], [2.0, RELEASE_C]]},
	"f_idle": {"len": 2.2, "loop": true, "keys": [[0.0, F_IDLE], [1.1, F_IDLE_B], [2.2, F_IDLE]]},
	"f_run": {"len": 0.6, "loop": true, "keys": [[0.0, F_RUN_A], [0.3, F_RUN_B], [0.6, F_RUN_A]]},
	"f_roar": {"len": 1.8, "loop": false, "keys": [[0.0, F_ROAR_A], [0.5, F_ROAR_A], [0.75, F_ROAR_B], [1.5, F_ROAR_B], [1.8, F_IDLE]]},
	"f_leap": {"len": 0.5, "loop": false, "keys": [[0.0, F_LEAP], [0.5, F_LEAP]]},
}

const ATTACKS := {
	"light1": LIGHT1, "light2": LIGHT2, "light3": LIGHT3, "heavy": HEAVY, "aircut": AIRCUT,
	"thrust": THRUST, "rise": RISE, "cast": CAST, "slam": SLAM,
	"f_swipe": F_SWIPE, "f_swipe_l": F_SWIPE_L, "f_slam": F_SLAM,
}


## An attack clip whose contact pose lands exactly when the blow goes active.
static func attack(kind: String, startup: float, active: float, recover: float, settle: Dictionary = IDLE) -> Dictionary:
	var a: Array = ATTACKS[kind]
	var total := startup + active + recover
	return {"len": total, "loop": false, "keys": [
		[0.0, a[0]],
		[startup * 0.72, a[0]],
		[startup + active * 0.4, a[1]],
		[startup + active + minf(0.07, recover * 0.4), a[2]],
		[startup + active + recover * 0.7, a[2]],
		[total, blend(a[2], settle, 0.6)],
	]}


static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for k: Variant in a.keys():
		out[k] = true
	for k: Variant in b.keys():
		out[k] = true
	for k: Variant in out.keys():
		if String(k) == "y":
			out[k] = lerpf(float(a.get(k, 0.0)), float(b.get(k, 0.0)), t)
		else:
			var va: Vector3 = a.get(k, V0)
			var vb: Vector3 = b.get(k, V0)
			out[k] = va.lerp(vb, t)
	return out


static func sample(clip: Dictionary, t: float) -> Dictionary:
	var keys: Array = clip["keys"]
	var length := float(clip["len"])
	if bool(clip["loop"]):
		t = fposmod(t, length)
	else:
		t = clampf(t, 0.0, length)
	var prev: Array = keys[0]
	for i in range(1, keys.size()):
		var k: Array = keys[i]
		if t <= float(k[0]):
			var span := float(k[0]) - float(prev[0])
			var u := 0.0 if span <= 0.0001 else (t - float(prev[0])) / span
			u = u * u * (3.0 - 2.0 * u)
			return blend(prev[1], k[1], u)
		prev = k
	return prev[1]

extends Node
## The balance report: numbers that decide how the game feels, per grade,
## for a representative soul (skill points spent, gear at the grade's bar).
## Headless, no window:
## godot --headless --path game res://tools/Balance.tscn

## Enemy levels a soul at each grade meets in its realms, and its trial.
const GRADE_FIGHTS: Dictionary = {
	5: {"region": "citadel", "trial": "thane"},
	4: {"region": "ashfall", "trial": "many_mouthed"},
	3: {"region": "reach", "trial": "vael"},
	2: {"region": "ashfall", "trial": "odrel"},
	1: {"region": "undermark", "trial": "sereth"},
}
const WALK_SECONDS: float = 7.0   # finding the next fight
var lines: Array = []


var misses: int = 0


func target(g: int, what: String, v: float, lo: float, hi: float) -> void:
	if v < lo or v > hi:
		misses += 1
		print("  FAIL  balance grade %d: %s (%.2f)" % [g, what, v])


func say(s: String) -> void:
	lines.append(s)
	print(s)


func _ready() -> void:
	Fx.quiet = true
	Sfx.muted = true
	report()
	get_tree().quit(1 if misses > 0 else 0)


func region_levels(rid: String, s: Soul) -> Array:
	var spawns: Array = []
	match rid:
		"town": spawns = Town.SPAWNS
		"citadel": spawns = Citadel.SPAWNS
		"ashfall": spawns = Ashfall.SPAWNS
		"reach": spawns = Reach.SPAWNS
		"undermark": spawns = Undermark.SPAWNS
		"stacks": spawns = Stacks.SPAWNS
	var out: Array = []
	for sp: Variant in spawns:
		var e: Array = sp
		var lv := int(e[3]) if e.size() > 3 else 1
		out.append([String(e[0]), Region.scaled_level(lv, rid, s)])
	return out


func trial_level(boss: String, s: Soul) -> int:
	return Region.trial_level(boss, s)


## A soul as it stands at the top of a grade: level at the cap, points
## spent down two neighbouring disciplines, gear at the grade's bar.
func seasoned(grade: int, strain: String) -> Soul:
	var s := Soul.create(99)
	s.primary = strain
	s.affinity[strain] = 80.0
	s.flags["chapter"] = "hub"
	s.grade = grade
	s.level = Quests.level_cap(s)
	var points := 2 + 2 * (s.level - 1) + 3 * (5 - grade)
	s.marks = points
	var order: Array = []
	for tier in range(1, SkillTree.TIERS + 1):
		for br: String in ["blade", "speed", "body", "spirit"]:
			order.append(String(SkillTree.nodes_of(br, tier)[0]))
	var guard := 0
	while s.marks > 0 and guard < 200:
		guard += 1
		var took := false
		for id: Variant in order:
			if SkillTree.take(s, String(id)):
				took = true
				break
		if not took:
			break
	var req: Dictionary = Forge.REQUIRE.get(mini(grade + 1, 5), Forge.REQUIRE[5])
	var w_by_tier := {1: "w_bone", 2: "w_oath", 3: "w_bell", 4: "w_brand", 5: "w_unwritten"}
	var a_by_tier := {1: "a_hide", 2: "a_oath", 3: "a_carapace", 4: "a_gaoler", 5: "a_pages"}
	var wt := clampi(int(req["weapon"]), 1, 5)
	var at := clampi(int(req["armour"]), 1, 5)
	s.gear["weapon"] = Forge.make(String(w_by_tier[wt]), [], "aggression", 5)
	if int(req["armour"]) > 0:
		s.gear["armour"] = Forge.make(String(a_by_tier[at]), [], "aggression", 6)
	return s


## Damage a second from a light string, in a kit, with this soul's stats.
func string_dps(s: Soul, kit_lights: Array, finisher_k: float) -> float:
	var st := Stats.compute(s)
	var dmg := 0.0
	var time := 0.0
	for i in range(kit_lights.size()):
		var m: Dictionary = kit_lights[i]
		var k := float(m["dmg"])
		if i == kit_lights.size() - 1:
			k *= finisher_k
		dmg += float(st["light_dmg"]) * k * float(m.get("count", 1))
		time += (float(m["startup"]) + float(m["active"]) + float(m["recover"])) / float(st["attack_speed"])
	return dmg / maxf(time, 0.01)


func enemy_hit(kind: String, level: int) -> float:
	var def: Dictionary = Bestiary.DEFS[kind]
	var total := 0.0
	var w := 0.0
	for mv: Variant in def["moves"]:
		var m: Dictionary = mv
		var ww := float(m.get("w", 1.0))
		total += float(m["dmg"]) * ww
		w += ww
	return total / maxf(w, 0.01) * (1.0 + 0.08 * float(level - 1))


func enemy_biggest(kind: String, level: int) -> float:
	var def: Dictionary = Bestiary.DEFS[kind]
	var big := 0.0
	for mv: Variant in (def["moves"] as Array) + (def.get("phase2", []) as Array):
		big = maxf(big, float((mv as Dictionary)["dmg"]))
	return big * (1.0 + 0.08 * float(level - 1))


func enemy_hp(kind: String, level: int) -> float:
	return float(Bestiary.DEFS[kind]["hp"]) * (1.0 + 0.12 * float(level - 1))


func report() -> void:
	say("UNWRIT balance report")
	say("")
	# kits at Grade 3
	var s3 := seasoned(3, "vigil")
	say("Kits, light-string damage a second at Grade 3 (finisher counted):")
	var kits := {"blade": Player.LIGHTS, "claws": Player.CLAWS, "bow": [Player.ARROW], "chain": Player.CHAIN_LIGHTS}
	var dps_by := {}
	for k: Variant in kits.keys():
		var fk := 1.2 if String(k) != "bow" else 1.0
		dps_by[k] = string_dps(s3, kits[k], fk)
	var best := 0.0
	for k: Variant in dps_by.keys():
		best = maxf(best, float(dps_by[k]))
	for k: Variant in dps_by.keys():
		say("  %-6s %6.1f  (%3d%% of best)" % [String(k), float(dps_by[k]), int(round(float(dps_by[k]) / best * 100.0))])
		target(0, "%s within 20%% of the best kit" % String(k), float(dps_by[k]) / best, 0.8, 1.01)
	say("")
	say("Per grade (Reaper, blade, at the grade's level cap):")
	say("  grade  lvl  hp    dps   realm      foe-lvl  ttk-s  hits-to-die  trial(lvl)      trial-ttk-s  big-hit%%  climb-kills  climb-min  gear-kills")
	for g: int in [5, 4, 3, 2, 1]:
		var s := seasoned(g, "vigil")
		var st := Stats.compute(s)
		var dps := string_dps(s, Player.LIGHTS, 1.2)
		var fight: Dictionary = GRADE_FIGHTS[g]
		var foes := region_levels(String(fight["region"]), s)
		var ttk := 0.0
		var hits := 0.0
		var foe_lv := 0.0
		var ess := 0.0
		for f: Variant in foes:
			var kind := String((f as Array)[0])
			var lv := int((f as Array)[1])
			foe_lv += float(lv)
			ttk += enemy_hp(kind, lv) / dps + 0.4
			hits += float(st["max_hp"]) / enemy_hit(kind, lv)
			var diff := s.level - lv
			var factor := 1.0 if diff <= 3 else maxf(0.1, 1.0 - 0.18 * float(diff - 3))
			ess += float(Bestiary.DEFS[kind]["essence"]) * (1.0 + 0.18 * float(lv - 1)) * factor
		var n := float(foes.size())
		ttk /= n
		hits /= n
		foe_lv /= n
		ess /= n
		var trial := String(fight["trial"])
		var tl := trial_level(trial, s)
		var t_ttk := enemy_hp(trial, tl) / dps
		var big := enemy_biggest(trial, tl) / float(st["max_hp"]) * 100.0
		# the climb: from the grade's floor to its cap
		var lo := Soul.create(1)
		lo.grade = g
		lo.primary = "vigil"
		var start_lv: int = Quests.LEVEL_CAP.get(g + 1, 1) if g < 5 else 1
		var need := 0.0
		for lv2 in range(start_lv, s.level):
			lo.level = lv2
			need += lo.essence_needed()
		var climb_kills := need / maxf(ess, 0.01)
		var climb_min := climb_kills * (ttk + WALK_SECONDS) / 60.0
		# gear for the next bar, in shards and materials, as kills
		var req: Dictionary = Forge.REQUIRE.get(g, {})
		var gear_shards := 0.0
		var w_by_tier := {1: "w_bone", 2: "w_oath", 3: "w_bell", 4: "w_brand", 5: "w_unwritten"}
		if not req.is_empty():
			gear_shards = float(Forge.PATTERNS[w_by_tier[clampi(int(req["weapon"]), 1, 5)]]["shards"]) * 2.5
		var gear_kills := gear_shards / maxf(float(Items.shards_for(int(round(foe_lv)), false, false)), 1.0)
		say("  %d      %2d   %4d  %5.1f  %-9s  %5.1f    %5.1f  %5.1f        %-12s(%2d) %6.1f       %5.1f     %6.0f       %6.0f     %5.0f" % [g, s.level, int(st["max_hp"]), dps, String(fight["region"]), foe_lv, ttk, hits, trial, tl, t_ttk, big, climb_kills, climb_min, gear_kills])
		target(g, "ordinary enemy down in 3 to 8 s", ttk, 3.0, 8.0)
		target(g, "8 to 16 ordinary hits to die", hits, 7.5, 16.0)
		target(g, "trial down in 40 to 130 s", t_ttk, 40.0, 130.0)
		target(g, "trial's biggest hit 15 to 38%% of vitality", big, 15.0, 38.0)
		target(g, "the grade's climb 5 to 90 minutes of fighting", climb_min, 5.0, 90.0)
	print("balance: %d out of range" % misses)
	var f := FileAccess.open("user://balance_report.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines))
		f.close()

extends SceneTree
## Headless checks for the pure core. godot --headless --path game --script res://tests/run_core.gd

var passed := 0
var failed := 0


func ok(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL  ", what)


func fighter(style: String) -> Profile:
	var p := Profile.new()
	p.time_fighting = 120.0
	match style:
		"duelist":
			p.add("swings", 90.0); p.add("light_hits", 70.0); p.add("parries", 40.0); p.add("blocks", 20.0); p.add("hits_taken", 6.0); p.add("kills", 12.0)
		"brute":
			p.add("swings", 260.0); p.add("heavy_hits", 90.0); p.add("light_hits", 60.0); p.add("hits_taken", 50.0); p.add("kills", 14.0); p.add("devours", 12.0)
			p.time_low = 50.0
		"ghost":
			p.add("swings", 120.0); p.add("light_hits", 50.0); p.add("ranged_hits", 60.0); p.add("dodges", 70.0); p.add("hits_taken", 8.0); p.add("kills", 10.0); p.add("tech_uses", 40.0)
	return p


func _init() -> void:
	print("== core ==")
	# determinism
	ok(Rng.unit([1, "a"]) == Rng.unit([1, "a"]), "rng repeats")
	ok(Rng.unit([1, "a"]) != Rng.unit([2, "a"]), "rng differs by seed")

	# profile
	var d := fighter("duelist")
	var b := fighter("brute")
	var g := fighter("ghost")
	ok(d.trait_of("patience") > b.trait_of("patience"), "duelist is more patient than brute")
	ok(b.trait_of("aggression") > d.trait_of("aggression"), "brute is more aggressive")
	ok(g.trait_of("mobility") > d.trait_of("mobility"), "ghost is more mobile")
	ok(g.trait_of("range") > b.trait_of("range"), "ghost prefers range")
	ok(b.trait_of("hunger") > d.trait_of("hunger"), "brute is hungrier")
	ok(absf(Profile.new().trait_of("patience") - 0.5) < 0.001, "empty profile sits in the middle")
	var back := Profile.from_dict(d.to_dict())
	ok(absf(back.trait_of("patience") - d.trait_of("patience")) < 0.0001, "profile round trip")

	# strains
	var aff := Strains.blank()
	for i in range(10):
		Strains.gain(aff, "parry")
	Strains.gain(aff, "devour")
	ok(Strains.leading(aff) == "vigil", "parries lead to vigil")
	ok(Strains.leading(aff, "vigil") == "maw", "maw is second")
	ok(Strains.hybrid_name("vigil", "maw") == "Revenant" and Strains.hybrid_name("maw", "vigil") == "Revenant", "hybrid is order free")
	for a in Strains.ALL:
		for c in Strains.ALL:
			if a != c:
				ok(Strains.hybrid_name(a, c) != "", "hybrid exists for %s+%s" % [a, c])
	ok(Strains.form_name("", "") == "Unwrit", "no strain yet means Unwrit")

	# forge: budget is equal for every soul
	var seen_aspect := {}
	var seen_form := {}
	var seen_name := {}
	for s in range(200):
		var prof: Profile = [d, b, g][s % 3]
		var trial := Profile.new()
		trial.add(["parries", "heavy_hits", "dodges"][s % 3], 10.0)
		var rel := AbilityForge.release(1000 + s, prof, trial)
		var bud: Dictionary = rel["budget"]
		var sum := int(bud["power"]) + int(bud["reach"]) + int(bud["speed"]) + int(bud["utility"])
		if sum != AbilityForge.BUDGET:
			ok(false, "budget sums to 100 (seed %d gave %d)" % [s, sum])
		seen_aspect[rel["aspect"]] = true
		seen_form[rel["form"]] = true
		seen_name[rel["spirit"]] = true
	ok(true, "budget checked over 200 souls")
	ok(seen_aspect.size() >= 12, "aspects are varied (%d of 14)" % seen_aspect.size())
	ok(seen_form.size() == 7, "all seven forms appear (%d)" % seen_form.size())
	ok(seen_name.size() > 150, "spirit names rarely repeat (%d of 200)" % seen_name.size())

	# forge: same soul and same play gives the same spirit; different trial changes the verb
	var t1 := Profile.new(); t1.add("parries", 9.0)
	var t2 := Profile.new(); t2.add("dodges", 9.0)
	var r1 := AbilityForge.release(77, d, t1)
	var r1b := AbilityForge.release(77, d, t1)
	var r2 := AbilityForge.release(77, d, t2)
	ok(JSON.stringify(r1) == JSON.stringify(r1b), "release is repeatable")
	ok(r1["verb"] == "answer" and r2["verb"] == "mirage", "how the spirit is beaten decides the verb")
	var t3 := Profile.new(); t3.add("light_hits", 3.0); t3.end_hp_frac = 0.2
	ok(AbilityForge.release(77, d, t3)["verb"] == "ember", "winning near death gives ember")
	# same seed, different habits: different outcome somewhere
	var ra := AbilityForge.release(5, d, t1)
	var rb := AbilityForge.release(5, b, t1)
	ok(JSON.stringify(ra["budget"]) != JSON.stringify(rb["budget"]), "habits change the budget split")

	# forms trade rather than add
	for f: Variant in AbilityForge.FORMS.keys():
		var fd: Dictionary = AbilityForge.FORMS[f]
		var prod := float(fd["dmg"]) * float(fd["reach"]) * float(fd["speed"])
		ok(prod > 0.9 and prod < 1.4, "form %s is within the trade band (%.2f)" % [f, prod])

	# techniques differ between souls
	var ta := AbilityForge.technique("sever", 1, {"edge": 5, "tempo": 5}, d)
	var tb := AbilityForge.technique("sever", 1, {"edge": 30, "tempo": 5}, d)
	var tc := AbilityForge.technique("sever", 1, {"edge": 5, "tempo": 5}, b)
	ok(float(tb["dmg"]) > float(ta["dmg"]), "a technique scales with the stats it set under")
	ok(ta["name"] != tc["name"], "habits give a technique its quirk (%s / %s)" % [ta["name"], tc["name"]])
	ok(AbilityForge.instinct_kind(d, 3) == "guard", "a patient soul's first instinct is to guard (%s)" % AbilityForge.instinct_kind(d, 3))
	ok(AbilityForge.instinct_kind(g, 3) in ["sever", "lance"], "a ghost's instinct is to move or throw (%s)" % AbilityForge.instinct_kind(g, 3))

	# unsealing
	var fight := Profile.new(); fight.add("parries", 12.0)
	var u := AbilityForge.unseal(r1, fight)
	ok(u["stage"] == 2 and u["scar"] == "tollbreaker", "parrying a great enemy leaves the tollbreaker scar")
	ok(r1["stage"] == 1, "unseal does not change the original")

	# the skill tree
	var names := {}
	var techs := {}
	var dup_name := false
	var dup_tech := false
	for n: Variant in SkillTree.NODES:
		var nd: Dictionary = n
		if names.has(nd["name"]):
			dup_name = true
		names[nd["name"]] = true
		for fx: Variant in nd["fx"]:
			if String((fx as Array)[0]) == "tech":
				if techs.has((fx as Array)[1]):
					dup_tech = true
				techs[(fx as Array)[1]] = true
	ok(not dup_name, "no skill name appears twice in the tree")
	ok(not dup_tech and techs.size() == 6, "each technique is taught in one place only (%d)" % techs.size())
	var every_branch := true
	for br: String in SkillTree.BRANCHES:
		for tier in range(1, SkillTree.TIERS + 1):
			var at := SkillTree.nodes_of(br, tier)
			if at.size() < 1 or at.size() > 2:
				every_branch = false
	ok(every_branch, "four disciplines, eight tiers each, one or two skills a tier")
	var caps_trade := true
	for br: String in SkillTree.BRANCHES:
		var has_down := false
		for fx: Variant in SkillTree.node(br + ".8")["fx"]:
			if String((fx as Array)[0]) == "pct" and float((fx as Array)[2]) < 0.0:
				has_down = true
		caps_trade = caps_trade and has_down
	ok(caps_trade, "every capstone is a trade")
	var soul := Soul.create(42)
	soul.marks = 3
	ok(not SkillTree.can_take(soul, "blade.2"), "tier 2 waits for tier 1")
	ok(SkillTree.take(soul, "blade.1") and soul.marks == 2, "tier 1 costs one point")
	ok(not SkillTree.take(soul, "blade.1"), "cannot take it twice")
	ok(SkillTree.take(soul, "blade.2") and soul.marks == 1, "tier 2 opens after it")
	ok(not SkillTree.can_take(soul, "blade.3a") and SkillTree.why_not(soul, "blade.3a").contains("2 skill points"), "tier 3 costs two: %s" % SkillTree.why_not(soul, "blade.3a"))
	soul.marks = 10
	ok(SkillTree.take(soul, "blade.3b"), "a fork can be taken")
	ok(not SkillTree.can_take(soul, "blade.3a") and SkillTree.why_not(soul, "blade.3a").begins_with("Closed"), "and the other side closes")
	ok(SkillTree.can_take(soul, "blade.4"), "either side of a fork opens the next tier")
	soul.marks = 0
	ok(not SkillTree.can_take(soul, "body.1"), "no points, no skill")

	# stats and habits
	var s2 := Soul.create(42)
	var base_stats := Stats.compute(s2)
	ok(absf(float(base_stats["max_hp"]) - 120.0) < 0.01, "starting vitality is 120")
	s2.marks = 999
	for tier in range(1, SkillTree.TIERS + 1):
		for br: String in ["blade", "speed"]:
			SkillTree.take(s2, String(SkillTree.nodes_of(br, tier)[0]))
	ok(s2.tree.size() == 16, "two neighbouring paths can be walked side by side (%d)" % s2.tree.size())
	ok(s2.techniques.size() == 2, "and it teaches its techniques")
	var grown := Stats.compute(s2)
	ok(float(grown["heavy_dmg"]) > float(base_stats["heavy_dmg"]) and float(grown["max_hp"]) < float(base_stats["max_hp"]) * 1.0 + 0.01, "the tree makes a soul hit harder, and its capstones cost vitality")
	var ranks0 := int(s2.mastery.get("blade", 0))
	ok(SkillTree.master(s2, "blade") and SkillTree.master(s2, "blade") and int(s2.mastery["blade"]) == ranks0 + 2, "Mastery ranks go on past the capstone")
	ok(not SkillTree.can_master(Soul.create(1), "blade"), "but not before it")
	var sa := Soul.create(42); sa.marks = 999; sa.profile = fighter("duelist")
	var sb := Soul.create(42); sb.marks = 999; sb.profile = fighter("brute")
	SkillTree.take(sa, "blade.1"); SkillTree.take(sa, "blade.2")
	SkillTree.take(sb, "blade.1"); SkillTree.take(sb, "blade.2")
	ok(float(sa.tree["blade.2"]["k"]) != float(sb.tree["blade.2"]["k"]), "the same skill sets differently for different habits (%.2f / %.2f)" % [float(sa.tree["blade.2"]["k"]), float(sb.tree["blade.2"]["k"])])
	# the disciplines lean on one another
	var lone := Soul.create(11)
	lone.marks = 999
	for tier in range(1, 5):
		SkillTree.take(lone, "blade.%d" % tier if tier != 3 else "blade.3a")
	ok(not SkillTree.can_take(lone, "blade.5") and SkillTree.why_not(lone, "blade.5").begins_with("Needs support"), "tier 5 needs a neighbour: %s" % SkillTree.why_not(lone, "blade.5"))
	SkillTree.take(lone, "spirit.1"); SkillTree.take(lone, "spirit.2")
	ok(not SkillTree.can_take(lone, "blade.5"), "the opposite discipline does not support it")
	SkillTree.take(lone, "speed.1"); SkillTree.take(lone, "speed.2")
	ok(SkillTree.can_take(lone, "blade.5"), "a neighbour at tier 2 does")
	ok(is_equal_approx(SkillTree.harmony(lone, "blade"), 1.0), "harmony needs both neighbours (body is at 0)")
	var heavy0 := float(Stats.compute(lone)["heavy_dmg"])
	SkillTree.take(lone, "body.1"); SkillTree.take(lone, "body.2")
	ok(is_equal_approx(SkillTree.harmony(lone, "blade"), 1.12), "both neighbours at 2: blade skills +12%% (%.2f)" % SkillTree.harmony(lone, "blade"))
	ok(float(Stats.compute(lone)["heavy_dmg"]) > heavy0 + 0.01, "climbing a neighbour lifts a skill already taken (heavy cuts %.2f to %.2f)" % [heavy0, float(Stats.compute(lone)["heavy_dmg"])])
	ok(float((Stats.compute(lone)["tech_kind"] as Dictionary)["rise"]) > 1.0, "and the technique that discipline taught")
	var opp := Soul.create(12)
	opp.marks = 999
	for tier in range(1, SkillTree.TIERS + 1):
		for br: String in ["blade", "speed", "spirit"]:
			SkillTree.take(opp, String(SkillTree.nodes_of(br, tier)[0]))
	ok(opp.tree.has("blade.8") and opp.tree.has("spirit.8") and SkillTree.opposed(opp, "blade"), "both opposed capstones can be held")
	var opp_hp := float(Stats.compute(opp)["max_hp"])
	opp.tree.erase("spirit.8")
	ok(float(Stats.compute(opp)["max_hp"]) > opp_hp + 0.5, "but holding both doubles their costs (vitality %.0f vs %.0f)" % [opp_hp, float(Stats.compute(opp)["max_hp"])])
	# a technique you already know is honed, not given twice
	var sh := Soul.create(5)
	sh.techniques.append(AbilityForge.technique("sever", 5, Stats.base_totals(sh), sh.profile, 0))
	var sev_dmg := float(sh.techniques[0]["dmg"])
	sh.marks = 99
	for tier in range(1, 5):
		SkillTree.take(sh, String(SkillTree.nodes_of("speed", tier)[0]))
	ok(sh.techniques.size() == 1 and float(sh.techniques[0]["dmg"]) > sev_dmg and bool(sh.techniques[0].get("honed", false)), "learning a technique you know hones it instead")
	# an old save with a Lattice gets its points back
	var old := Soul.create(3).to_dict()
	old.erase("tree")
	old["lattice"] = {"0.0": {"k": 1.0}, "0.1": {"k": 1.0}, "2.3": {"k": 1.0}}
	old["marks"] = 0
	var migrated := Soul.from_dict(old)
	ok(migrated.marks == 4 and migrated.tree.is_empty(), "an old Lattice save is refunded its points (%d)" % migrated.marks)
	var round := Soul.from_dict(s2.to_dict())
	ok(round.tree.size() == s2.tree.size() and int(round.mastery.get("blade", 0)) == int(s2.mastery["blade"]), "the tree is saved")

	# levelling
	var s3 := Soul.create(7)
	var need1 := s3.essence_needed()
	var ups := s3.gain_essence(need1 + 1.0)
	ok(ups == 1 and s3.level == 2 and s3.marks == 4, "essence levels a soul and grants marks")
	ok(s3.essence_needed() > need1 * 1.3, "each level costs more than the last")
	var big := Soul.create(8)
	big.gain_essence(1000000.0)
	ok(big.level == Quests.PROLOGUE_CAP, "a soul before Awakening stops at level %d (%d)" % [Quests.PROLOGUE_CAP, big.level])
	ok(big.essence <= big.essence_needed(), "and essence does not pile up past the cap")
	big.primary = "vigil"
	big.gain_essence(1000000.0)
	ok(big.level == 10, "Grade 5 caps at level 10 (%d)" % big.level)

	# writing and graft
	var s4 := Soul.create(7)
	ok(s4.form_name() == "Unwrit" and not s4.written(), "a new soul has no strain")
	s4.affinity = {"vigil": 80.0, "maw": 65.0, "lumen": 3.0, "relic": 0.0}
	s4.grade = 3
	ok(not s4.can_graft(), "cannot graft before the Writing")
	s4.primary = Strains.leading(s4.affinity)
	ok(s4.form_name() == "Reaper", "awakened as a Reaper")
	ok(s4.can_graft() and s4.graft() == "Revenant", "grafts into a Revenant")
	ok(not s4.can_graft(), "one graft only")

	# quests and grades
	var q := Soul.create(30)
	ok(Quests.available(q, "lingering").size() == 3, "an Unwrit soul sees three notices on the Lingering Board")
	ok(Quests.available(q, "citadel").is_empty(), "and none on the Citadel board")
	ok(Quests.accept(q, "p_strays") and Quests.active(q).size() == 1, "a notice can be taken")
	for i in range(4):
		Quests.event(q, "kill", "husk", "town")
	ok(not Quests.is_ready(q, "p_strays") and Quests.progress(q, "p_strays") == 4, "progress counts kills of the right kind")
	Quests.event(q, "kill", "hound", "town")
	ok(Quests.progress(q, "p_strays") == 4, "the wrong kind does not count")
	ok(Quests.event(q, "kill", "husk", "town") == ["p_strays"], "the fifth kill finishes it")
	ok(not Quests.claim(q, "p_strays").is_empty() and Quests.times_done(q, "p_strays") == 1, "it can be handed in once")
	ok(Quests.claim(q, "p_strays").is_empty(), "and not twice")
	ok(not Quests.available(q, "lingering").has("p_strays"), "a story notice does not come back")
	Quests.accept(q, "p_keepsakes")
	Quests.accept(q, "p_king")
	q.flags["beat_gutter_king"] = true
	ok(not Quests.is_ready(q, "p_king"), "a boss quest waits for the kill")
	Quests.event(q, "boss", "gutter_king")
	Quests.event(q, "relic"); Quests.event(q, "relic")
	Quests.claim(q, "p_keepsakes"); Quests.claim(q, "p_king")
	ok(Quests.prologue_done(q), "the prologue is done when all three are handed in")
	q.primary = "maw"
	ok(Quests.available(q, "hunt").size() >= 3 and Quests.available(q, "citadel").is_empty(), "a Devourer is served by the Hunt Stone only")
	ok(Quests.title(q) == "Husk", "a new Devourer is a Husk")
	ok(Quests.accept(q, "h_husks") and Quests.accept(q, "h_devour") and Quests.accept(q, "h_gleaners"), "three notices at once")
	ok(not Quests.accept(q, "h_stalkers"), "but not four (and not above its rank)")
	ok(not Quests.can_promote(q), "no promotion without standing")
	q.standing = 80.0
	ok(not Quests.can_promote(q) and Quests.promotion_gap(q).contains("Many-Mouthed"), "nor without the trial (%s)" % Quests.promotion_gap(q))
	q.flags["beat_many_mouthed"] = true
	ok(not Quests.can_promote(q) and Quests.promotion_gap(q).contains("tier 1 weapon"), "nor without forged gear (%s)" % Quests.promotion_gap(q))
	q.gear["weapon"] = Forge.make("w_bone", [], "patience", 5)
	ok(Quests.promote(q) == 4 and q.standing == 20.0 and Quests.title(q) == "Colossus", "promotion: a Husk becomes a Colossus")
	for st: String in Strains.ALL:
		for gr in range(1, 6):
			ok(Quests.BOSS_NAMES.has(String(Quests.TRIALS[st][gr])), "%s grade %d has a real trial" % [st, gr])
	var hp4 := float(Stats.compute(q)["max_hp"])
	q.grade = 3
	ok(float(Stats.compute(q)["move_speed"]) > float(Stats.compute(Soul.create(30))["move_speed"]), "a Stalker is faster than an Unwrit")
	ok(float(Stats.compute(q)["max_hp"]) < hp4, "and thinner than a Colossus")
	q.affinity = {"vigil": 0.0, "maw": 200.0, "lumen": 70.0, "relic": 0.0}
	q.grade = 4
	ok(not q.can_graft(), "no graft before Grade 3")
	q.grade = 3
	ok(q.can_graft() and q.second_strain() == "lumen", "a strong second strain can be grafted at Grade 3")
	q.flags["pure"] = true
	ok(not q.can_graft(), "a soul that refused stays pure")

	# hybrid arts and the hotbar
	for form: Variant in Strains.HYBRID.values():
		var art := String(AbilityForge.HYBRID_ART.get(form, ""))
		ok(AbilityForge.TECH.has(art), "%s has its own art (%s)" % [form, art])
	var arts: Array = AbilityForge.HYBRID_ART.values()
	for n: Variant in SkillTree.NODES:
		for fx: Variant in (n as Dictionary)["fx"]:
			if String((fx as Array)[0]) == "tech":
				ok(not arts.has((fx as Array)[1]), "the skill tree never teaches a hybrid art (%s)" % String((fx as Array)[1]))
	var hb := Soul.create(5)
	for i in range(6):
		hb.techniques.append({"kind": "sever"})
	hb.loadout = [0, 1, 2, 3]
	ok(hb.slot_technique(5) == 3 and int(hb.loadout[3]) == 5, "a fifth technique takes the fourth slot")
	ok(hb.cycle_slot(5) == 0 and int(hb.loadout[0]) == 5 and int(hb.loadout[3]) == 0, "and can be moved round, swapping places")
	ok(String(Quests.TRIALS["lumen"][3]) == "ysolde" and Quests.BOSS_NAMES.has("ysolde"), "Archers face Ysolde at Grade 3")

	# loot, charms, the bench
	var dr := Items.roll_drops("husk", 5, false, 77)
	ok(JSON.stringify(dr) == JSON.stringify(Items.roll_drops("husk", 5, false, 77)), "drops repeat from their seed")
	ok(int(dr["shards"]) == Items.shards_for(5, false, false) and int(dr["shards"]) > 0, "every kill pays shards")
	ok(Items.shards_for(5, true, false) > Items.shards_for(5, false, false), "elites pay more")
	var bk := Items.roll_drops("branded_king", 28, false, 5)
	ok(not (bk["charm"] as Dictionary).is_empty() and String(bk["charm"]["key"]) == "crown_of_brands", "the Branded King drops the Crown of Brands")
	ok(int((bk["materials"] as Dictionary).get("brand_iron", 0)) >= 8, "and brand iron")
	ok((Items.roll_drops("odrel", 16, false, 5)["charm"] as Dictionary).is_empty(), "a main trial boss drops materials, not charms")
	var all_down := true
	var all_in := true
	var seen_rarity := {}
	for key: Variant in Items.CHARMS.keys():
		for sd in range(40):
			var c := Items.make_charm(String(key), sd)
			if not Items.has_downside(c):
				all_down = false
			seen_rarity[c["rarity"]] = true
			var defs: Dictionary = Items.CHARMS[key]["mods"]
			for m: Variant in defs.keys():
				var lo := minf(float(defs[m][0]), float(defs[m][1]))
				var hi := maxf(float(defs[m][0]), float(defs[m][1]))
				if float(c["mods"][m]) < lo - 0.0001 or float(c["mods"][m]) > hi + 0.0001:
					all_in = false
	ok(all_down, "every charm has a cost as well as a gift")
	ok(all_in, "every roll lands inside its range")
	ok(seen_rarity.size() >= 3, "charms come in grades of quality (%s)" % str(seen_rarity.keys()))
	var ec := Soul.create(9)
	ec.primary = "vigil"
	var dmg0 := float(Stats.compute(ec)["light_dmg"])
	var hp0 := float(Stats.compute(ec)["max_hp"])
	ec.items.append(Items.make_charm("crown_of_brands", 1))
	ok(Items.toggle_equip(ec, 0), "a charm can be worn")
	ok(float(Stats.compute(ec)["light_dmg"]) > dmg0 and float(Stats.compute(ec)["max_hp"]) < hp0, "the Crown hits harder and leaves you frailer")
	for i in range(4):
		ec.items.append(Items.make_charm("bone_charm", 10 + i))
	ok(Items.toggle_equip(ec, 1) and Items.toggle_equip(ec, 2) and not Items.toggle_equip(ec, 3), "three charms at most")
	Items.take_item(ec, 0)
	ok(ec.equipped == [0, 1], "taking an item keeps the worn ones pointing right")
	ec.materials = {"ash_bone": 10}
	ec.shards = 59
	ok(not Items.can_craft(ec, 0), "the bench needs its shards")
	ec.shards = 60
	var crafted := Items.craft(ec, 0)
	ok(String(crafted.get("key", "")) == "bone_charm" and int(ec.materials["ash_bone"]) == 0 and ec.shards == 0, "the bench turns bone into a Bone Charm")

	# the Exchange
	var mk := Soul.create(11)
	var p0 := Market.price(mk, "mat", "mask_shard")
	mk.materials = {"mask_shard": 30}
	var first := Market.sell_material(mk, "mask_shard")
	for i in range(19):
		Market.sell_material(mk, "mask_shard")
	ok(first > 0 and Market.price(mk, "mat", "mask_shard") < p0, "selling floods the market and the price falls (%d to %d)" % [p0, Market.price(mk, "mat", "mask_shard")])
	var low := Market.price(mk, "mat", "mask_shard")
	Market.tick(mk, Market.TICK * 20.0)
	ok(Market.price(mk, "mat", "mask_shard") > low, "and recovers over time")
	ok((Market.state(mk)["listings"] as Array).size() > 0, "other souls list goods")
	mk.shards = 100000
	var held := mk.items.size() + mk.materials.size()
	ok(Market.buy(mk, 0) and mk.items.size() + mk.materials.size() >= held, "you can buy from them")
	mk.items.append(Items.make_charm("mask_charm", 3))
	var cheap := int(Market.price(mk, "charm", "mask_charm", mk.items[mk.items.size() - 1]) * 0.8)
	ok(Market.list_item(mk, mk.items.size() - 1, cheap), "you can list a charm")
	var sh0 := mk.shards
	Market.tick(mk, Market.TICK * 30.0)
	ok(mk.shards > sh0 and (Market.state(mk)["mine"] as Array).is_empty(), "a fair price finds a buyer while you play")

	# save round trip
	s2.primary = "maw"; s2.release = r1; s2.flags["x"] = true
	var path := "user://test_soul.json"
	ok(s2.save_to(path), "save writes")
	var loaded := Soul.load_from(path)
	ok(loaded != null and loaded.seed == s2.seed and loaded.grade == s2.grade and loaded.primary == "maw" and loaded.tree.size() == s2.tree.size() and loaded.techniques.size() == s2.techniques.size(), "save round trip keeps the soul")
	# JSON turns whole numbers into floats once; after that a save must be stable
	ok(loaded.save_to(path) and JSON.stringify(Soul.load_from(path).to_dict()) == JSON.stringify(loaded.to_dict()), "a loaded soul saves back unchanged")
	ok(JSON.stringify(Stats.compute(loaded)) == JSON.stringify(Stats.compute(s2)), "a loaded soul has the same numbers")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# look
	ok(JSON.stringify(Soul.create(1).look()) == JSON.stringify(Soul.create(1).look()), "a soul's look is fixed by its seed")

	# race passives: each its own, a graft at half
	var rv := Soul.create(31)
	var base_pw := float(Stats.compute(rv)["parry_window"])
	rv.primary = "vigil"
	ok(float(Stats.compute(rv)["parry_window"]) > base_pw * 1.1, "Reapers parry wider")
	var rl := Soul.create(31)
	var base_ar := float(Stats.compute(rl)["anima_regen"])
	rl.primary = "lumen"
	ok(float(Stats.compute(rl)["anima_regen"]) > base_ar * 1.3, "Archers gather spirit energy faster")
	var rh := Soul.create(31)
	rh.primary = "vigil"
	var half_ar := float(Stats.compute(rh)["anima_regen"])
	rh.secondary = "lumen"
	ok(float(Stats.compute(rh)["anima_regen"]) > half_ar * 1.15 and float(Stats.compute(rh)["anima_regen"]) < half_ar * 1.3, "a graft gives half its own gift")
	# combat rules
	var atk := {"dmg": 20.0, "posture": 10.0, "heavy": false, "blockable": true, "parryable": true}
	var open := {"posture": 0.0, "posture_max": 60.0}
	ok(CombatRules.resolve(atk, open)["outcome"] == "hit", "an open body is hit")
	ok(CombatRules.resolve(atk, {"invulnerable": true, "dash_age": 0.05})["perfect"], "an early dash is a perfect dodge")
	var blocked := CombatRules.resolve(atk, {"blocking": true, "block_age": 0.6, "parry_window": 0.17, "posture": 0.0, "posture_max": 60.0})
	ok(blocked["outcome"] == "blocked" and float(blocked["dmg"]) < 3.0, "a held block takes chip")
	var parried := CombatRules.resolve(atk, {"blocking": true, "block_age": 0.1, "parry_window": 0.17})
	ok(parried["outcome"] == "parried" and float(parried["dmg"]) == 0.0 and float(parried["attacker_posture"]) > 0.0, "a fresh block is a parry")
	var behind := CombatRules.resolve(atk, {"blocking": true, "block_age": 0.1, "parry_window": 0.17, "facing": false, "posture_max": 60.0})
	ok(behind["outcome"] == "hit", "a guard does not cover the back")
	var red := {"dmg": 30.0, "posture": 20.0, "blockable": false, "parryable": false}
	ok(CombatRules.resolve(red, {"blocking": true, "block_age": 0.05, "parry_window": 0.17, "posture_max": 60.0})["outcome"] == "hit", "a red blow goes through a guard")
	ok(CombatRules.resolve(atk, {"posture": 55.0, "posture_max": 60.0}).get("broke", false), "a full stance breaks")
	ok(not CombatRules.resolve(atk, {"armored": true, "posture": 0.0, "posture_max": 200.0})["stagger"], "an armoured body does not flinch")
	var bolt := {"dmg": 10.0, "ranged": true, "parryable": true, "blockable": true}
	ok(CombatRules.resolve(bolt, {"blocking": true, "block_age": 0.05, "parry_window": 0.17})["reflect"], "a parried bolt goes back")

	# the forge
	var f := Soul.create(808)
	f.shards = 10000
	ok(not Forge.can_forge(f, "w_bone"), "nothing is forged from nothing")
	f.materials = {"ash_bone": 30, "mask_shard": 20, "brand_iron": 12, "lantern_glass": 20, "tall_eye": 4, "oath_steel": 20, "gaoler_link": 4, "bell_bronze": 2}
	var fsh0 := f.shards
	var bone := Forge.forge(f, "w_bone")
	ok(not bone.is_empty() and String(bone["type"]) == "weapon" and int(f.materials["ash_bone"]) == 18 and f.shards == fsh0 - 80, "forging a Bone-Edge spends its bones and shards")
	ok(f.items.size() == 1 and int(bone["sockets"]) == 1, "and it lands in the pack with one socket")
	var hot := Forge.forge(f, "w_bone", ["brand_iron", "tall_eye"])
	ok(int(f.materials["brand_iron"]) == 9 and int(f.materials["tall_eye"]) == 1, "tempering costs three of each temper")
	ok(float(hot["mods"].get("heavy_dmg", 0.0)) > 0.0 and String(hot["name"]).contains("Brand Iron") and String(hot["name"]).contains("Tall"), "and pushes the piece toward it: %s" % String(hot["name"]))
	ok(not Forge.can_forge(f, "w_bone", ["tall_eye"]), "a temper you lack cannot be used")
	ok(not Forge.can_forge(f, "w_bone", ["ash_bone", "mask_shard", "oath_steel"]), "nor more than two")
	ok(not Forge.can_forge(f, "r_frost", ["ash_bone"]), "and runes take no temper")
	var p1 := Forge.make("a_oath", [], "aggression", 1)
	var p2 := Forge.make("a_oath", [], "patience", 1)
	var p3 := Forge.make("a_oath", [], "aggression", 2)
	ok(String(p1["name"]).begins_with("Restless") and String(p2["name"]).begins_with("Patient"), "the maker's habit marks the name: %s / %s" % [String(p1["name"]), String(p2["name"])])
	ok(float(p1["mods"]["max_hp"]) != float(p3["mods"]["max_hp"]), "two of the same pattern roll differently")
	var every_cost := true
	for k: Variant in Forge.PATTERNS.keys():
		var pc := Forge.make(String(k), [], "", 3)
		var has_down := false
		for m: Variant in (pc["mods"] as Dictionary).keys():
			var v := float(pc["mods"][m])
			if (v < 0.0 and String(m) != "tech_cost") or (v > 0.0 and String(m) == "tech_cost"):
				has_down = true
		every_cost = every_cost and has_down
	ok(every_cost, "every pattern carries a cost")
	ok(Forge.wear(f, 0) and Forge.tier_of(f, "weapon") == 1 and f.items.size() == 1, "a weapon can be worn")
	ok(Forge.wear(f, 0) and f.items.size() == 1 and String(f.items[0]["name"]) == String(bone["name"]), "wearing another sends the first back to the pack")
	var hp_before := float(Stats.compute(f)["max_hp"])
	var rn := Forge.forge(f, "r_leech")
	ok(not rn.is_empty() and String(rn["effect"]) == "leech", "runes are forged too")
	ok(Forge.socket(f, f.items.size() - 1) == "weapon" and Forge.rune_count(f) == 1, "and set into the weapon's socket")
	ok(float(Stats.compute(f)["max_hp"]) < hp_before, "a Leech Rune costs a little life")
	ok(Forge.rune_effects(f).has("leech"), "and makes hits heal")
	var rn2 := Forge.forge(f, "r_frost")
	ok(Forge.socket(f, f.items.find(rn2)) == "", "no free socket, no rune")
	ok(Forge.unsocket(f, "weapon", 0) and Forge.rune_count(f) == 0, "runes can be pulled back out")
	ok(not Items.toggle_equip(f, 0), "gear is not worn as a charm")
	f.grade = 3
	ok(Forge.gear_gap(f).contains("tier 3 weapon") and Forge.gear_gap(f).contains("tier 2 armour") and Forge.gear_gap(f).contains("1 rune"), "Grade 3 asks for more: %s" % Forge.gear_gap(f))
	var echo := Soul.create(9)
	echo.gear["weapon"] = Forge.make("w_bell", [], "", 4)
	(echo.gear["weapon"]["runes"] as Array).append(Forge.make("r_echo", [], "", 4))
	ok(float(Stats.compute(echo)["tech_cd"]) < 1.0 and float(Stats.compute(echo)["tech_cost"]) > 1.0, "an Echo Rune shortens cooldowns and dearens techniques")
	var fl := Soul.from_dict(f.to_dict())
	ok(Forge.tier_of(fl, "weapon") == 1 and fl.items.size() == f.items.size(), "gear is saved")

	# badges
	var b_ids := {}
	var b_names := {}
	for bd: Variant in Badges.ALL:
		b_ids[String((bd as Array)[0])] = true
		b_names[String((bd as Array)[1])] = true
	ok(b_ids.size() == Badges.ALL.size() and b_names.size() == Badges.ALL.size(), "every badge has its own id and name (%d)" % Badges.ALL.size())
	var bs := Soul.create(31)
	var bsh := bs.shards
	ok(not Badges.award(bs, "first_blood").is_empty() and bs.shards == bsh + 15, "a badge pays its shards")
	ok(Badges.award(bs, "first_blood").is_empty() and bs.shards == bsh + 15, "and only once")
	bs.flags["crates"] = 30
	var got_b: Array = Badges.check(bs)
	ok(Badges.has(bs, "crate_buster") and got_b.size() == 1, "a count earns its badge when it is reached")
	ok(Soul.from_dict(bs.to_dict()).flags.has("badges"), "badges are saved")

	print("core: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

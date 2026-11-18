extends Node
## Plays a scripted tour and saves stills. Opens a WINDOW: ask first.
## godot --path game res://tools/Capture.tscn -- --no-title --test /abs/out/dir
## Headless it is a dry run: no images, but every script error shows.

var main: Node
var p: Player
var out_dir: String = ""
var dry: bool = false
var times: Array = []
var shots: int = 0


func frames(n: int) -> void:
	for i in range(n + 1):
		await get_tree().physics_frame


func press(field: String, value: Variant = true) -> void:
	p.intent.set(field, value)
	await frames(1)
	p.intent.set(field, -1 if field == "tech" else false)


func shot(shot_name: String) -> void:
	shots += 1
	if dry:
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out_dir, shots, shot_name])
	times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)


func use_player() -> void:
	p = main.place.player
	p.scripted = true
	p.intent = Player.Intent.new()
	main.place.cam.look_enabled = false


func view(rel_yaw: float, pitch: float, dist: float) -> void:
	var cam: CamRig = main.place.cam
	cam.cine_t = 0.0
	cam.yaw = p.rotation.y + rel_yaw
	cam.pitch = pitch
	cam.dist = dist
	cam.snap()
	await frames(3)


func cine(from: Vector3, look: Vector3) -> void:
	var cam: CamRig = main.place.cam
	cam.cinematic(from, look, 1.5)
	cam.global_position = from
	await frames(4)


func clear_enemies() -> void:
	for a in main.place.actors.duplicate():
		if a != main.place.player and is_instance_valid(a):
			main.place.actors.erase(a)
			a.queue_free()


func dummy(kind: String, offset: Vector3) -> Enemy:
	var a: Region = main.place
	var at := p.global_position + Basis(Vector3.UP, p.rotation.y) * offset
	var e := a._spawn(kind, at)
	e.dormant = true
	e.passive = true
	e.max_hp = 9999.0
	e.hp = 9999.0
	e.face_now(e.flat_to(p.global_position))
	return e


func strike_shot(button: String, shot_name: String, e: Enemy, rel_yaw: float, value: Variant = true) -> void:
	e.global_position = p.global_position + p.forward() * 2.1
	e.posture = 0.0
	e.set_state(Actor.St.FREE)
	await view(rel_yaw, -0.12, 4.6)
	await press(button, value)
	var guard := 0
	while guard < 120 and not (p.state == Actor.St.ATTACK and p.move_hit):
		guard += 1
		await get_tree().physics_frame
	await frames(1)
	await shot(shot_name)
	await frames(50)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	dry = DisplayServer.get_name() == "headless"
	for a in args:
		if a.begins_with("/"):
			out_dir = a
	if out_dir == "" and not dry:
		print("capture: give an absolute output directory")
		get_tree().quit(1)
		return
	if not dry:
		DirAccess.make_dir_recursive_absolute(out_dir)
	Sfx.muted = true
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	add_child(main)
	main.save_path = "user://capture_soul.json"
	if FileAccess.file_exists(main.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	if args.has("--hud"):
		await run_hud()
	elif args.has("--scenery"):
		await run_scenery(args)
	else:
		await run()
	if not dry:
		var f := FileAccess.open(out_dir + "/metrics.json", FileAccess.WRITE)
		f.store_string(JSON.stringify({"process_ms_at_each_shot": times, "fps_at_end": Performance.get_monitor(Performance.TIME_FPS)}, "\t"))
		f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	print("capture: %d shots%s" % [shots, " (dry run)" if dry else " in " + out_dir])
	get_tree().quit(0)


func clear_all() -> void:
	clear_enemies()
	(main.place as Region).bosses.clear()


func at(x: float, z: float, yaw: float = 0.0) -> void:
	var a: Region = main.place
	p.global_position = Vector3(x, a.height_at(x, z) + 0.3, z)
	p.velocity = Vector3.ZERO
	p.rotation.y = yaw
	await frames(12)


func high(look: Vector3, from: Vector3) -> void:
	await cine(from, look)
	await frames(20)


func run() -> void:
	main.show_title()
	await frames(50)
	await shot("title")

	# the prologue: Calder Town
	main.new_soul(4242)
	main.soul.flags["weather"] = "clear"
	main.soul.flags["weather_left"] = 1.0e9
	use_player()
	await frames(50)
	await view(PI * 0.86, -0.02, 3.4)
	await shot("unwrit_with_tether")
	await view(0.0, -0.14, 5.6)
	await shot("wake_on_the_main_road")
	await high(Vector3(-10, 0, -20), Vector3(120, 150, 210))
	await shot("calder_town_from_above")
	await high(Vector3(-185, 0, -60), Vector3(-120, 60, 40))
	await shot("the_river_and_weir")
	var a: Region = main.place
	await at(14.0, 51.0, PI * 0.5)
	await view(PI * 0.75, -0.1, 5.0)
	main.board_ui.open_board(a, "lingering")
	await frames(4)
	await shot("lingering_board")
	main.board_ui.take(0)
	main.board_ui.take(0)
	main.board_ui.take(0)
	main.board_ui.close()
	await frames(4)
	await view(0.0, -0.12, 5.6)
	await shot("hud_compass_and_notices")
	# the Gutter King's courtyard
	var king: Enemy = a.bosses.get("gutter_king")
	if king != null:
		p.invuln = 999.0
		await at(Town.FLATS.x + 10.0, Town.FLATS.z + 10.0, PI * 0.25)
		await frames(50)
		await high(king.center(), king.global_position + Vector3(9, 5, 9))
		await shot("the_gutter_king")
		await force_kill(king)
		await frames(30)
		await high(Town.FLATS + Vector3(0, 0.8, 0), Town.FLATS + Vector3(4, 3, 6))
		await shot("its_mask_for_a_rematch")
	clear_all()
	# the shop and Ivo Marsh
	await at(40.0, 14.0, 0.0)
	await view(PI * 0.9, -0.05, 6.5)
	await shot("ivo_marsh_and_the_shop")
	await high(Vector3(20, 1.5, 0), Vector3(-6, 3.5, 34))
	await shot("the_living_on_the_main_road")
	await high(Vector3(150, 3, -52), Vector3(130, 14, -10))
	await shot("lantern_house")
	await high(Vector3(190, 4, -190), Vector3(204, 9, -170))
	await shot("the_ledger_gate")

	# the Undercroft
	s_flags_for_training()
	main.travel("undercroft", "town")
	use_player()
	await frames(40)
	await view(0.0, -0.12, 6.0)
	await shot("undercroft_arrival")
	await high(Vector3(0, 0, 40), Vector3(60, 50, 120))
	await shot("undercroft_cavern")
	var u: Undercroft = main.place
	await at(0.0, 66.0, 0.0)
	await frames(40)
	await view(PI * 0.3, -0.1, 6.0)
	await shot("the_drill")
	clear_all()
	main.soul.flags["drill_parry"] = 3
	main.soul.flags["drill_slip"] = 2
	main.soul.flags["drill_kill"] = 3
	u.begin_cut()
	await at(Undercroft.PIT.x, Undercroft.PIT.z + 6.0, 0.0)
	p.invuln = 999.0
	await frames(70)
	await high(Undercroft.PIT + Vector3(0, -6, 0), Undercroft.PIT + Vector3(18, 10, 30))
	await shot("the_cut_wave_one")
	clear_all()

	# the Awakening, done quickly, and the gate
	main.soul.profile.add("kills", 10.0)
	main.soul.affinity["vigil"] = 80.0
	var trial := Profile.new()
	trial.add("parries", 6.0)
	main.finish_trial(trial, "frost")
	use_player()
	await frames(30)
	await view(PI * 0.8, -0.05, 4.4)
	await shot("awakened")
	await at(22.0, 104.0, 0.0)
	await view(PI, -0.05, 7.0)
	await shot("marsh_opens_the_gate")

	# the Citadel
	main.travel("citadel", "undercroft")
	use_player()
	await frames(40)
	var c: Citadel = main.place
	await view(0.0, -0.1, 6.0)
	await shot("citadel_outpost")
	await high(Vector3(0, 10, -60), Vector3(110, 90, 160))
	await shot("citadel_from_above")
	main.board_ui.open_board(c, "citadel")
	await frames(4)
	await shot("citadel_duty_board")
	main.board_ui.close()
	var thane: Enemy = c.bosses.get("thane")
	if thane != null:
		p.invuln = 999.0
		await at(Citadel.GATE.x, Citadel.GATE.z + 16.0, 0.0)
		await frames(40)
		await high(thane.center(), thane.global_position + Vector3(10, 6, 20))
		await shot("thane_the_gate")
	clear_all()
	await at(0.0, -150.0, 0.0)
	await view(0.0, -0.05, 7.0)
	await shot("inner_citadel_and_spire")
	var vael_spot := Citadel.SPIRE + Vector3(0, 0, 10)
	c._spawn_bosses()
	var vael: Enemy = c.bosses.get("vael")
	if vael != null:
		await at(vael_spot.x, vael_spot.z + 12.0, 0.0)
		await frames(40)
		await high(vael.center(), vael.global_position + Vector3(4, 2.6, 7))
		await shot("vael_morrow")
	clear_all()

	# the Wastes
	main.travel("ashfall", "citadel")
	use_player()
	await frames(40)
	var w: Ashfall = main.place
	await high(Vector3(0, 0, 220), Vector3(30, 40, 345))
	await shot("wastes_dunes")
	await high(Ashfall.MOUTH, Ashfall.MOUTH + Vector3(60, 30, 60))
	await shot("crystal_undergrowth")
	var mm: Enemy = w.bosses.get("many_mouthed")
	if mm != null:
		p.invuln = 999.0
		await at(Ashfall.MOUTH.x + 20.0, Ashfall.MOUTH.z + 20.0, 0.0)
		await frames(40)
		await high(mm.center(), mm.global_position + Vector3(30, 10, 34))
		await shot("the_many_mouthed")
	clear_all()
	await high(Vector3(250, 0, -40), Vector3(300, 30, 60))
	await shot("bone_fields")
	w._spawn_bosses()
	var odrel: Enemy = w.bosses.get("odrel")
	if odrel != null:
		await at(Ashfall.COURT.x, Ashfall.COURT.z + 14.0, 0.0)
		await frames(40)
		await high(odrel.center(), odrel.global_position + odrel.forward() * 7.0 + Vector3(1.5, 2.2, 0))
		await shot("odrel")
	clear_all()
	w._spawn_bosses()
	var sereth: Enemy = w.bosses.get("sereth")
	if sereth != null:
		await at(Ashfall.THRONE.x, Ashfall.THRONE.z + 26.0, 0.0)
		await frames(40)
		await high(sereth.center(), sereth.global_position + Vector3(3, 2.5, 7))
		await shot("sereth_at_the_throne")
	clear_all()
	await high(Ashfall.THRONE + Vector3(0, 10, -30), Ashfall.THRONE + Vector3(40, 30, 80))
	await shot("the_sunken_throne")
	# every kind of enemy, side by side
	await at(0.0, 300.0, 0.0)
	var kinds := ["husk", "hound", "wraith", "gleaner", "rogue", "stalker", "sentinel", "brute"]
	for i in range(kinds.size()):
		var e := w._spawn(String(kinds[i]), p.global_position + Vector3(-14.0 + 4.0 * float(i), 0, -10.0), 7)
		e.dormant = true
		e.passive = true
		e.rotation.y = 0.0
	await frames(30)
	await high(p.global_position + Vector3(0, 1.5, -10), p.global_position + Vector3(0, 3.0, 2.0))
	await shot("the_bestiary")
	clear_all()

	# the Archers' realm
	main.travel("reach", "ashfall")
	use_player()
	await frames(40)
	var rr: Reach = main.place
	await view(0.0, -0.1, 6.0)
	await shot("silver_reach_arrival")
	await high(Vector3(0, 0, 0), Vector3(90, 60, 160))
	await shot("the_frozen_lake")
	var ys: Enemy = rr.bosses.get("ysolde")
	if ys != null:
		p.invuln = 999.0
		await at(Reach.SPIRE.x, Reach.SPIRE.z + 36.0, 0.0)
		await frames(40)
		await high(ys.center(), ys.global_position + Vector3(3, 2.4, 7))
		await shot("ysolde_the_last_lantern")
	clear_all()
	# a hybrid's art
	main.soul.grade = 3
	main.soul.secondary = "lumen" if main.soul.primary != "lumen" else "vigil"
	var form: String = main.soul.form_name()
	main.soul.techniques.append(AbilityForge.technique(String(AbilityForge.HYBRID_ART[form]), main.soul.seed, Stats.base_totals(main.soul), main.soul.profile, 0))
	main.soul.slot_technique(main.soul.techniques.size() - 1)
	p.rebuild_body()
	p.refresh_stats(true)
	await at(0.0, 150.0, 0.0)
	var target := dummy("husk", Vector3(0, 0, -5.0))
	target.max_hp = 9999.0
	target.hp = 9999.0
	await view(PI * 0.7, -0.08, 7.0)
	await press("tech", main.soul.loadout.find(main.soul.techniques.size() - 1))
	await frames(32)
	await shot("hybrid_art_" + String(AbilityForge.HYBRID_ART[form]))
	await frames(60)
	clear_all()

	# each race's kit
	main.soul.secondary = ""
	var kits: Array = [["lumen", "light", "kit_archer_arrows"], ["maw", "heavy", "kit_devourer_maw_beam"], ["relic", "heavy", "kit_binder_chain_pull"], ["vigil", "dash", "kit_reaper_flash_step"]]
	for k: Variant in kits:
		var kk: Array = k
		main.soul.primary = String(kk[0])
		p.released = false
		p.rebuild_body()
		p.refresh_stats(true)
		await at(0.0, 150.0, 0.0)
		var foe := dummy("husk", Vector3(0, 0, -7.0))
		foe.max_hp = 9999.0
		foe.hp = 9999.0
		await view(PI * 0.62, -0.1, 6.0)
		if String(kk[1]) == "dash":
			p.intent.move = Vector2(0, 1)
			await press("dash")
			await frames(2)
			p.intent.move = Vector2.ZERO
		else:
			await press(String(kk[1]))
			await frames(int(30 if String(kk[1]) == "light" else 40))
		await shot(String(kk[2]))
		await frames(40)
		clear_all()
	# an execution, and the style rank
	await at(0.0, 150.0, 0.0)
	var v := dummy("husk", Vector3(0, 0, -2.4))
	v.max_hp = 9999.0
	v.hp = 9999.0
	for i in range(6):
		p.add_style(4.0, "k%d" % i)
	v.posture = v.posture_max - 1.0
	main.place.strike(p, v, {"kind": "heavy", "dmg": 1.0, "posture": 10.0, "heavy": true})
	await frames(4)
	await view(PI * 0.55, -0.08, 5.0)
	await press("heavy")
	await frames(14)
	await shot("execution_and_style_rank")
	await frames(40)
	clear_all()

	# the Undermark
	main.soul.grade = 1
	main.travel("undermark", "reach")
	use_player()
	await frames(40)
	var um: Undermark = main.place
	p.invuln = 999.0
	await view(0.0, -0.1, 6.0)
	await shot("undermark_arrival")
	await high(Vector3(0, -2, 60), Vector3(70, 50, 190))
	await shot("undermark_lava_and_chains")
	var bk: Enemy = um.bosses.get("branded_king")
	if bk != null:
		await at(Undermark.KING.x + 20.0, Undermark.KING.z, PI * 0.5)
		await frames(40)
		await high(bk.center(), bk.global_position + Vector3(9, 4, 6))
		await shot("the_branded_king")
	clear_all()
	um._spawn_bosses()
	var gp: Enemy = um.bosses.get("gaoler_prime")
	if gp != null:
		await at(Undermark.YARD.x - 26.0, Undermark.YARD.z, -PI * 0.5)
		await frames(40)
		await high(gp.center(), gp.global_position + Vector3(-22, 8, 14))
		await shot("gaoler_prime")
	clear_all()
	um._spawn_bosses()
	var fu: Enemy = um.bosses.get("first_unwrit")
	if fu != null:
		await at(Undermark.THRONE.x, Undermark.THRONE.z + 26.0, 0.0)
		await frames(40)
		await high(fu.center(), fu.global_position + Vector3(3, 2.4, 7))
		await shot("the_first_unwrit")
	clear_all()
	await at(0.0, 200.0, 0.0)
	var dk := ["damned", "chainbound", "cinder", "gaoler"]
	for i in range(dk.size()):
		var e := um._spawn(String(dk[i]), p.global_position + Vector3(-9.0 + 6.0 * float(i), 0, -10.0), 24)
		e.dormant = true
		e.passive = true
		e.rotation.y = 0.0
	var elite := Enemy.new()
	elite.setup("stalker", 24, 777, {}, "volatile")
	um.add_actor(elite, p.global_position + Vector3(14.0, 0, -10.0))
	elite.dormant = true
	elite.passive = true
	await frames(30)
	await high(p.global_position + Vector3(2, 2, -10), p.global_position + Vector3(2, 4.0, 4.0))
	await shot("the_damned_chainbound_cinder_gaoler_and_an_elite")
	clear_all()
	main.soul.release["stage"] = 3
	main.soul.release["last"] = "the Last Name"
	p.swell = 100.0
	await view(PI * 0.8, -0.05, 5.0)
	await press("release")
	await frames(140)
	await view(PI * 0.8, -0.05, 5.0)
	await shot("last_release")
	p.swell = 0.5
	await frames(60)
	clear_all()
	um._spawn_bosses()
	var bk2: Enemy = um.bosses.get("branded_king")
	if bk2 != null:
		await at(Undermark.KING.x + 10.0, Undermark.KING.z + 4.0, PI * 0.5)
		await force_kill(bk2)
		await frames(40)
		await high(bk2.global_position + Vector3(0, 1.0, 1.0), bk2.global_position + Vector3(6, 4, 8))
		await shot("a_power_boss_drops_a_charm")
	clear_all()

	# the economy
	main.travel("town", "undermark")
	use_player()
	await frames(40)
	var tw: Region = main.place
	await at(8.5, 40.0, 0.0)
	for i in range(5):
		var h := tw._spawn("husk", p.global_position + Vector3(-4.0 + 2.0 * float(i), 0, -6.0), 3)
		h.dormant = true
		h.passive = true
		await force_kill(h)
	await frames(20)
	await view(PI * 0.75, -0.25, 6.0)
	await shot("loot_on_the_ground")
	main.soul.materials = {"ash_bone": 14, "mask_shard": 9, "lantern_glass": 7, "oath_steel": 3, "brand_iron": 9, "gaoler_link": 2}
	main.soul.shards = 1400
	for i in range(3):
		main.soul.items.append(Items.make_charm(["bone_charm", "glass_charm", "prime_link"][i], 50 + i))
	Items.toggle_equip(main.soul, 0)
	main.board_ui.open_inventory(tw)
	await frames(4)
	await shot("charms_and_the_bench")
	main.board_ui.close()
	Market.tick(main.soul, Market.TICK * 10.0)
	main.board_ui.open_market(tw)
	await frames(4)
	await shot("the_exchange")
	main.board_ui.close()
	# the forge
	main.soul.materials = {"ash_bone": 40, "mask_shard": 30, "lantern_glass": 30, "oath_steel": 30, "brand_iron": 30, "gaoler_link": 14, "dune_glass": 6, "tall_eye": 6, "bell_bronze": 4}
	main.soul.shards = 9000
	main.board_ui.open_forge(tw)
	main.board_ui.toggle_temper(main.board_ui.temper_keys().find("brand_iron"))
	main.board_ui.toggle_temper(main.board_ui.temper_keys().find("tall_eye"))
	await frames(4)
	await shot("the_forge_weapons")
	main.board_ui.set_forge_tab(2)
	await frames(4)
	await shot("the_forge_runes")
	main.board_ui.close()
	var wb := Forge.forge(main.soul, "w_brand", ["brand_iron"])
	var ap := Forge.forge(main.soul, "a_gaoler")
	var re := Forge.forge(main.soul, "r_ember")
	var rs := Forge.forge(main.soul, "r_storm")
	Forge.wear(main.soul, main.soul.items.find(wb))
	Forge.wear(main.soul, main.soul.items.find(ap))
	Forge.socket(main.soul, main.soul.items.find(re))
	Forge.socket(main.soul, main.soul.items.find(rs))
	p.refresh_stats()
	p.rebuild_body()
	await at(40.0, 6.0, PI)
	await frames(20)
	await view(PI * 0.8, -0.15, 5.0)
	await shot("forge_and_plate_armour")
	await view(PI * 0.15, -0.1, 3.4)
	await shot("plate_armour_front")
	main.board_ui.open_inventory(tw)
	await frames(4)
	await shot("gear_and_sockets")
	main.board_ui.close()
	var rb := Forge.forge(main.soul, "a_robe", ["lantern_glass"])
	Forge.wear(main.soul, main.soul.items.find(rb))
	p.refresh_stats()
	p.rebuild_body()
	await frames(10)
	await view(PI * 0.2, -0.1, 3.4)
	await shot("robe_armour")
	var hd := Forge.forge(main.soul, "a_hide")
	Forge.wear(main.soul, main.soul.items.find(hd))
	p.rebuild_body()
	await frames(10)
	await shot("hide_armour")


func force_kill(e: Enemy) -> void:
	var guard := 0
	while is_instance_valid(e) and e.alive and guard < 400:
		guard += 1
		e.invuln = 0.0
		main.place.strike(p, e, {"kind": "light", "dmg": 400.0, "posture": 2.0})
		await frames(1)


func s_flags_for_training() -> void:
	main.soul.flags["chapter"] = "training"
	for id: String in ["p_strays", "p_keepsakes", "p_king"]:
		Quests.state(main.soul)[id] = {"s": "done", "n": 0, "t": 1}


## A short tour of places only, for judging scenery and the HUD over it.
## Pass --scenery and optionally region ids (town citadel ashfall reach
## undermark undercroft) to limit it.
func run_scenery(args: PackedStringArray) -> void:
	main.new_soul(4242)
	use_player()
	await frames(40)
	var want: Array = []
	for a in args:
		if a in ["town", "citadel", "ashfall", "reach", "undermark", "undercroft"]:
			want.append(a)
	if want.is_empty():
		want = ["town", "citadel", "ashfall", "reach", "undermark", "undercroft"]
	for rid: String in want:
		if rid != "town":
			main.travel(rid, "town")
			await frames(30)
			main.board_ui.close()
		use_player()
		clear_all()
		var a: Region = main.place
		var w: Vector3 = a.wake_point()
		if rid == "town":
			await at(8.5, 40.0, PI)
			await view(0.3, -0.06, 6.0)
			await shot("town_main_road")
			await at(30.0, 4.0, 0.0)
			await view(PI * 0.8, -0.1, 7.0)
			await shot("town_shops")
			await at(-40.0, 90.0, 0.0)
			await view(PI * 0.6, -0.08, 7.0)
			await shot("town_houses")
			await at(40.0, -40.0, 0.0)
			await view(PI * 0.25, -0.3, 9.0)
			await shot("town_downtown")
			await high(Vector3(30, 10, -40), Vector3(-10, 40, 20))
			await shot("town_rooftops")
			await high(Vector3(-10, 0, -20), Vector3(120, 150, 210))
			await shot("town_from_above")
		else:
			await at(w.x, w.z, 0.0)
			await view(0.0, -0.1, 6.5)
			await shot(rid + "_arrival")
			await view(PI * 0.7, -0.05, 6.5)
			await shot(rid + "_arrival_back")
			await high(w + Vector3(0, 0, -60), w + Vector3(40, 30, 20))
			await shot(rid + "_over")
		if args.has("--perf"):
			await perf_probe(rid)


func perf_probe(rid: String) -> void:
	use_player()
	var w: Vector3 = (main.place as Region).wake_point()
	await at(w.x, w.z, 0.0)
	await view(0.3, -0.06, 6.0)
	for i in range(4):
		await get_tree().create_timer(1.0).timeout
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("perf %s: %.0f fps, %d draws, %d prims, process %.1f ms" % [rid, Performance.get_monitor(Performance.TIME_FPS), draws, prims, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])


## The HUD's pop-ups on demand: a control hint with keys, pickups that add
## up, a dropped charm, a level banner, and the hotbar mid-cooldown.
func run_hud() -> void:
	main.new_soul(4242)
	use_player()
	await frames(60)
	var s: Soul = main.soul
	s.techniques.append(AbilityForge.technique("sever", s.seed, {}, s.profile, 1))
	s.techniques.append(AbilityForge.technique("lance", s.seed, {}, s.profile, 2))
	s.techniques.append(AbilityForge.technique("toll", s.seed, {}, s.profile, 3))
	s.loadout = [0, 1, 2, -1]
	p.anima = 18.0
	p.tech_cd[1] = 4.2
	p.tech_cd[2] = 0.8
	p.crit_cd = 5.5
	var hud: Hud = main.hud
	hud._toasts.clear()
	hud.push("LMB cut  RMB heavy  F guard (tap as a blow lands to parry)  SHIFT dash  TAB lock", "hint")
	hud.push("Notice complete: The Gutter King. Hand it in at the board.", "gain")
	hud.push("A Reaper in a black coat is standing up the street. She can see you.", "toast")
	hud.push("A Reaper in a black coat is standing up the street. She can see you.", "toast")
	for i in range(3):
		hud.push("mask_shard:2", "loot")
	hud.push("ash_bone:4", "loot")
	hud.push("Fine|Bone Charm|-3% swing speed, +8% vitality   [I] to wear", "drop")
	hud.push("Level 4|2 skill points to spend  [K]", "level")
	await frames(30)
	await view(0.3, -0.06, 6.0)
	await shot("hud_popups_and_hotbar")
	await frames(140)
	await shot("hud_after_cooldowns")
	# a quest giver: name plate, the "!" over her head, the dialogue box
	hud._toasts.clear()
	hud._banner = {}
	hud._loot.clear()
	await at(19.0, 64.0, 0.4)
	await frames(30)
	hud.push("Mira Okafor|He was walking home. That is all. He was walking home.", "talk")
	await frames(60)
	await view(PI * 0.15, -0.08, 5.0)
	await shot("quest_giver_and_dialogue")
	# a world event: a rift tears open, its first wave, the card under the compass
	hud._toasts.clear()
	var tr: Region = main.place
	tr.events.start("raid")
	await frames(20)
	var rift_at: Vector3 = tr.events.ev["at"]
	await high(rift_at + Vector3(0, 3, 0), rift_at + Vector3(10, 7, 14))
	await shot("world_event_rift")
	tr.events.finish(false)
	clear_enemies()
	await frames(10)
	use_player()
	# a finisher in flight: the body tips back as it flies
	hud._toasts.clear()
	p.face_now(Vector3.FORWARD)
	var fl: Enemy = dummy("husk", Vector3(0, 0, -2.2))
	main.place.strike(p, fl, p._finisher(p.light_move(4), "out"))
	await frames(9)
	await view(PI * 0.5, -0.12, 7.0)
	await shot("finisher_knockback")
	await frames(60)
	clear_enemies()
	# the skill tree, part walked, a fork chosen, a card under the mouse
	s.marks = 14
	for id: String in ["blade.1", "blade.2", "blade.3b", "speed.1", "speed.2", "speed.3a", "body.1"]:
		SkillTree.take(s, id)
	main._pause(true)
	await frames(10)
	var ui: SkillTreeUI = main.lattice_ui
	ui.selected = "blade.4"
	ui.hover = "speed.4"
	await frames(6)
	await shot("skill_tree")
	ui.selected = "spirit.5"
	ui.hover = ""
	await frames(4)
	await shot("skill_tree_locked")


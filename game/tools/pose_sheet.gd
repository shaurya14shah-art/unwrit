extends Node3D
## Stands a row of bodies in every pose and saves stills. Opens a WINDOW.
## godot --path game res://tools/PoseSheet.tscn -- /abs/out/dir

var out_dir: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("/"):
			out_dir = a
	var dry := DisplayServer.get_name() == "headless"
	if not dry:
		DirAccess.make_dir_recursive_absolute(out_dir)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.44, 0.48)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 7.4
	cam.position = Vector3(0, 2.75, 12)
	add_child(cam)
	cam.current = true

	var human: Array = [
		["idle", Poses.IDLE], ["run a", Poses.RUN_A], ["run pass", Poses.RUN_P1], ["dash", Poses.DASH], ["air", Poses.AIR], ["guard", Poses.BLOCK],
		["parry", Poses.PARRY], ["hit", Poses.HIT], ["stagger", Poses.STAGGER_A], ["dead", Poses.DEAD_B], ["meditate", Poses.MEDITATE], ["kneel", Poses.KNEEL],
		["release a", Poses.RELEASE_A], ["release b", Poses.RELEASE_B], ["release c", Poses.RELEASE_C], ["light1 wind", Poses.LIGHT1[0]], ["light1 hit", Poses.LIGHT1[1]], ["light1 follow", Poses.LIGHT1[2]],
		["light2 wind", Poses.LIGHT2[0]], ["light2 hit", Poses.LIGHT2[1]], ["light2 follow", Poses.LIGHT2[2]], ["light3 wind", Poses.LIGHT3[0]], ["light3 hit", Poses.LIGHT3[1]], ["light3 follow", Poses.LIGHT3[2]],
		["heavy wind", Poses.HEAVY[0]], ["heavy hit", Poses.HEAVY[1]], ["heavy follow", Poses.HEAVY[2]], ["aircut hit", Poses.AIRCUT[1]], ["thrust wind", Poses.THRUST[0]], ["thrust hit", Poses.THRUST[1]],
		["rise wind", Poses.RISE[0]], ["rise hit", Poses.RISE[1]], ["rise follow", Poses.RISE[2]], ["cast wind", Poses.CAST[0]], ["cast hit", Poses.CAST[1]], ["slam hit", Poses.SLAM[1]],
	]
	var feral: Array = [
		["f idle", Poses.F_IDLE], ["f run a", Poses.F_RUN_A], ["f run b", Poses.F_RUN_B], ["f swipe wind", Poses.F_SWIPE[0]], ["f swipe hit", Poses.F_SWIPE[1]], ["f swipe follow", Poses.F_SWIPE[2]],
		["f slam wind", Poses.F_SLAM[0]], ["f slam hit", Poses.F_SLAM[1]], ["f roar a", Poses.F_ROAR_A], ["f roar b", Poses.F_ROAR_B], ["f leap", Poses.F_LEAP], ["f swipe l hit", Poses.F_SWIPE_L[1]],
	]
	var sheets: Array = [[human.slice(0, 12), false], [human.slice(12, 24), false], [human.slice(24, 36), false], [feral, true]]
	var index := 0
	for sh: Variant in sheets:
		var pair: Array = sh
		var holder := Node3D.new()
		add_child(holder)
		var list: Array = pair[0]
		for i in range(list.size()):
			var item: Array = list[i]
			var rig := BlockRig.new()
			holder.add_child(rig)
			if bool(pair[1]):
				rig.build((Bestiary.get_def("husk")["body"] as Dictionary).duplicate())
			else:
				rig.build({"hair": 0, "hair_color": Color(0.5, 0.1, 0.1), "coat": 2})
				rig.hold(Gear.sealed_blade(7))
			rig.set_process(false)
			rig._apply(item[1])
			rig.position = Vector3(-5.5 + 2.2 * float(i % 6), 3.7 if i < 6 else 0.0, 0)
			rig.rotation.y = PI - 0.65
			var label := Label3D.new()
			label.text = String(item[0])
			label.font_size = 48
			label.pixel_size = 0.005
			label.position = rig.position + Vector3(0, -0.22, 0.5)
			label.modulate = Color(1, 1, 1)
			holder.add_child(label)
		index += 1
		if not dry:
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/poses_%d.png" % [out_dir, index])
		holder.queue_free()
		await get_tree().process_frame
	print("pose sheet: %d sheets" % index)
	get_tree().quit(0)

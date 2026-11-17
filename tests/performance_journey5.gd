extends SceneTree

# Real-time continuous Base -> Koya -> Luma -> Base journey, normal audio.
# No staging, clock changes or resource edits after first launch; actual map API.
var game: Node
var ids := ["base_full", "koya_luma", "luma_base"]
var leg := -1
var frame := 0
var previous_us := 0
var start_us := 0
var physics_steps := 0
var waiting := 31
var finished := false
var intervals: Array = []
var regions: Dictionary = {}
var results: Array = []
var checkpoints: Array = []
var last_landing := "base"
var label := "journey"

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	if Engine.physics_ticks_per_second != 60 or Engine.time_scale != 1.0:
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.show_fps = true

func begin_leg() -> void:
	leg += 1
	game.open_map()
	if not game.select_contract(ids[leg]):
		finish(false)
		return
	game.start_run()
	game.select_gear(2)
	intervals = []
	regions = {}
	checkpoints = []
	physics_steps = 0
	start_us = Time.get_ticks_usec()
	previous_us = start_us
	print("REALTIME5 START " + ids[leg])

func _physics_process(delta: float) -> bool:
	if leg >= 0 and not finished and waiting == 0 and game.state == "running":
		var controls: Array = game.pilot_controls()
		game.simulate(delta, controls[0], controls[1], controls[2])
		physics_steps += 1
		if last_landing != game.profile.current_landing:
			last_landing = game.profile.current_landing
			checkpoints.append({"landing": last_landing, "simulation_s": game.elapsed, "support": game.run_support, "fuel": game.fuel, "hull": game.hull})
	return false

func region_name() -> String:
	var distance: float = -game.boat_pos.y
	if distance < 7000: return "original"
	if distance < 11800: return "fork"
	if distance > 13600 and distance < 15400: return "luma"
	if distance > 23000: return "koya"
	return "transit"

func _process(_delta: float) -> bool:
	if finished or not is_instance_valid(game): return false
	frame += 1
	if waiting > 0:
		waiting -= 1
		if waiting == 0: begin_leg()
		return false
	var now := Time.get_ticks_usec()
	var ms := float(now - previous_us) / 1000.0
	previous_us = now
	intervals.append(ms)
	var region := region_name()
	if not regions.has(region): regions[region] = []
	regions[region].append(ms)
	if game.state != "running" or now - start_us > 300000000:
		var row := {"contract": ids[leg], "wall_s": float(now-start_us)/1000000.0, "simulation_s": game.elapsed, "physics_steps": physics_steps, "state": game.state, "fuel": game.fuel, "hull": game.hull, "support": game.run_support, "landing": game.profile.current_landing, "checkpoint_events": checkpoints, "overall": stats(intervals), "regions": {}, "intervals_ms": intervals.duplicate()}
		for key: String in regions: row.regions[key] = stats(regions[key])
		results.append(row)
		print("REALTIME5 RESULT " + JSON.stringify(row).left(1800))
		game.save_capture.call_deferred("performance5-" + label + "-" + ids[leg] + "-result.png")
		if game.state != "success" or game.fuel < 5 or game.hull < 100:
			finish(false)
		elif leg == ids.size()-1:
			finish(true)
		else:
			waiting = 31
	return false

func stats(values: Array) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	var slow := 0
	for value: float in sorted:
		total += value
		if value > 33.333: slow += 1
	return {"frames": sorted.size(), "fps": 1000.0*sorted.size()/total, "mean_ms": total/sorted.size(), "p95_ms": sorted[int(sorted.size()*0.95)], "max_ms": sorted.back(), "over_33_ms": slow}

func finish(okay: bool) -> void:
	finished = true
	FileAccess.open("res://tmp/performance5-runtime-" + label + ".json", FileAccess.WRITE).store_string(JSON.stringify({"pass": okay, "normal_audio": true, "legs": results}, "\t"))
	print("REALTIME5 " + ("PASS" if okay else "FAIL"))
	cleanup.call_deferred(okay)

func cleanup(okay: bool) -> void:
	await process_frame
	game.queue_free()
	await process_frame
	quit(0 if okay else 1)


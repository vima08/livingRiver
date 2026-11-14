extends SceneTree

# Real-time graphical traversal: one real simulation step per engine physics tick.
# Isolated profile, no teleports, no resource edits, no timescale or tickrate changes.
var game: Node
var frames := 0
var physics_steps := 0
var previous_us := 0
var start_us := 0
var running := false
var finished := false
var all_frames: Array[float] = []
var regions: Dictionary = {}
var captures: Dictionary = {}

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	if Engine.physics_ticks_per_second != 60 or Engine.time_scale != 1.0:
		push_error("Expected untouched 60 Hz physics and 1.0 time scale")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.select_load("full")
	game.show_fps = true
	if "--quiet-output" in OS.get_cmdline_user_args():
		# Keep actual mixer/playback workload while avoiding overlapping human audio review.
		if is_instance_valid(game.audio) and game.audio.has_method("update_mix"):
			game.audio.update_mix()
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)

func _physics_process(delta: float) -> bool:
	if running and not finished:
		var controls: Array = game.pilot_controls()
		game.simulate(delta, controls[0], controls[1], controls[2])
		physics_steps += 1
	return false

func region_name() -> String:
	var distance: float = -game.boat_pos.y
	if distance < 7000:
		return "original"
	if distance < 11600:
		return "fork"
	if distance > 13600 and distance < 15400:
		return "luma"
	if distance > 23000:
		return "koya"
	return "transit"

func _process(_delta: float) -> bool:
	if finished or not is_instance_valid(game):
		return false
	frames += 1
	if frames == 31:
		game.start_run()
		game.select_gear(2)
		start_us = Time.get_ticks_usec()
		previous_us = start_us
		running = true
		return false
	if not running:
		return false
	var now := Time.get_ticks_usec()
	var milliseconds := float(now - previous_us) / 1000.0
	previous_us = now
	all_frames.append(milliseconds)
	var region := region_name()
	if not regions.has(region):
		regions[region] = []
	regions[region].append(milliseconds)
	if not captures.has(region):
		captures[region] = true
		game.save_capture.call_deferred("performance-fix-runtime-" + region + ".png")
	if game.state != "running" or now - start_us > 260000000:
		finished = true
		finish.call_deferred(now)
	return false

func statistics(values: Array) -> String:
	values.sort()
	var total := 0.0
	var slow := 0
	for value: float in values:
		total += value
		if value > 33.333:
			slow += 1
	return "%d | %.2f | %.3f | %.3f | %.3f | %.2f%%" % [values.size(), 1000.0 * values.size() / total, total / values.size(), values[int(values.size() * 0.95)], values.back(), float(slow) * 100.0 / values.size()]

func finish(now: int) -> void:
	var okay: bool = game.state == "success" and game.run_support == 160 and game.fuel >= 5
	var report := "# Real-time graphical full-relief route\n\n"
	report += "PASS\n\n" if okay else "FAIL\n\n"
	report += "Default player VSync/window/render settings. Default 60 Hz physics and time scale 1.0, one pilot-driven simulate(delta) per real physics tick, isolated in-memory progression. No position/resource staging within route. Not a human playtest. Includes capture overhead at first region entry; no frame samples discarded after initial 30-frame warmup.\n\n"
	if "--quiet-output" in OS.get_cmdline_user_args():
		report += "Test-only quiet output: Master gain attenuated to -80 dB after applying default settings, without bus mute, stopping players or disabling audio updates. Actual WASAPI playback/mixer work remains active. This differs from default output gain and is not audible-quality acceptance.\n\n"
	report += "Wall %.3f s; simulation %.3f s; %d physics steps; state %s; support %d; fuel %.3f; hull %.3f.\n\n" % [float(now - start_us) / 1000000.0, game.elapsed, physics_steps, game.state, game.run_support, game.fuel, game.hull]
	report += "| Region | Frames | Mean FPS | Mean ms | p95 ms | Max ms | >33.333 ms |\n|---|---:|---:|---:|---:|---:|---:|\n"
	report += "| overall | " + statistics(all_frames) + " |\n"
	for region: String in regions:
		report += "| " + region + " | " + statistics(regions[region]) + " |\n"
	print(report)
	FileAccess.open("res://tmp/performance-fix-runtime.md", FileAccess.WRITE).store_string(report)
	game.save_capture.call_deferred("performance-fix-runtime-result.png")
	await RenderingServer.frame_post_draw
	await process_frame
	game.queue_free()
	await process_frame
	quit(0 if okay else 1)



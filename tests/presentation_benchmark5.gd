extends SceneTree

# Shared, unchanged harness for the frozen pre-milestone-5 project and candidate.
# Actual graphical frames and audio output; simulation is disabled for this sweep.
var game: Node
var frame := 0
var samples := 600
var region := 5000.0
var label := "current-en-original"
var locale := "en"
var south := false
var audio_off := false
var quiet_output := false
var start_us := 0
var previous_us := 0
var startup_us := 0
var draws := 0.0
var intervals: Array[float] = []
var finished := false

func _initialize() -> void:
	call_deferred("setup")

func has_property(object: Object, property: String) -> bool:
	for item in object.get_property_list():
		if item.name == property:
			return true
	return false

func setup() -> void:
	var setup_start := Time.get_ticks_usec()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
		elif argument.begins_with("--region="):
			region = argument.trim_prefix("--region=").to_float()
		elif argument.begins_with("--locale="):
			locale = argument.trim_prefix("--locale=")
		elif argument.begins_with("--samples="):
			samples = argument.trim_prefix("--samples=").to_int()
		elif argument == "--south":
			south = true
		elif argument == "--audio-off":
			audio_off = true
		elif argument == "--quiet-output":
			quiet_output = true
	if samples < 30 or locale not in ["en", "ru"] or region not in [5000.0, 9200.0, 14500.0, 26000.0] or not label.is_valid_filename():
		push_error("Invalid benchmark arguments")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	if has_property(game, "settings"):
		game.settings.set_locale(locale)
		load("res://scripts/localization.gd").set_locale(locale)
	if has_property(game, "engine_throttle"):
		game.engine_throttle = 1.0
	if audio_off and is_instance_valid(game.audio):
		# Diagnostic only: stop all playback and per-frame audio updates.
		game.audio.set_process(false)
		for child in game.audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
	game.ui_screen = ""
	if has_property(game, "travel_sign"):
		game.travel_sign = 1.0 if south else -1.0
	game.state = "running"
	game.selected_gear = 2
	game.show_fps = true
	if quiet_output:
		if is_instance_valid(game.audio) and game.audio.has_method("update_mix"):
			game.audio.update_mix()
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)
	startup_us = Time.get_ticks_usec() - setup_start

func _process(_delta: float) -> bool:
	if finished or not is_instance_valid(game):
		return false
	frame += 1
	# Match both coordinates and visual animation time regardless of measured FPS.
	game.elapsed = float(frame) / 60.0
	var progress := clampf(float(frame - 31) / samples, 0.0, 1.0)
	game.boat_pos.y = -region + (-400.0 + progress * 800.0 if south else 400.0 - progress * 800.0)
	game.boat_pos.x = game.river_center(game.boat_pos.y)
	game.velocity = Vector2(0, 155 if south else -155)
	game.camera_y = game.boat_pos.y - (200 if south else 520)
	var now := Time.get_ticks_usec()
	if frame == 31:
		start_us = now
		previous_us = now
	if frame > 31:
		intervals.append(float(now - previous_us) / 1000.0)
		previous_us = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if frame == 31 + samples:
		finished = true
		finish.call_deferred(now)
	return false

func finish(now: int) -> void:
	var sorted := intervals.duplicate()
	sorted.sort()
	var seconds := float(now - start_us) / 1000000.0
	var slow := 0
	for interval in intervals:
		if interval > 33.333:
			slow += 1
	var report := {
		"label": label, "locale": locale, "south": south, "region": region, "samples": samples,
		"wall_seconds": seconds, "fps": samples / seconds,
		"mean_ms": seconds * 1000.0 / samples,
		"median_ms": sorted[samples / 2], "p95_ms": sorted[int(samples * 0.95)],
		"max_ms": sorted.back(), "over_33_ms": slow,
		"draws": draws / samples, "setup_ms": startup_us / 1000.0,
		"audio_off": audio_off, "quiet_output": quiet_output, "display": DisplayServer.get_name(),
		"audio_driver": AudioServer.get_driver_name(), "intervals_ms": intervals,
	}
	DirAccess.make_dir_recursive_absolute("res://tmp")
	FileAccess.open("res://tmp/presentation5-%s.json" % label, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	report.erase("intervals_ms")
	print("PRESENTATION5 " + JSON.stringify(report))
	DirAccess.make_dir_recursive_absolute("res://doc/evidence")
	root.get_texture().get_image().save_png("res://doc/evidence/performance5-" + label + ".png")
	game.queue_free()
	await process_frame
	quit()




extends SceneTree

# Uncapped, graphical comparison. Baseline snapshot is local ignored data.
var game: Node
var frame := 0
var start_us := 0
var draws := 0.0
var baseline := false
var precurrent := false
var step2 := false
var region := 5000.0
var samples := 180
var frame_times: Array[float] = []
var process_ms := 0.0

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	baseline = "--baseline" in OS.get_cmdline_user_args()
	precurrent = "--precurrent" in OS.get_cmdline_user_args()
	step2 = "--step2" in OS.get_cmdline_user_args()
	if "--long" in OS.get_cmdline_user_args():
		samples = 600
	if "--fork" in OS.get_cmdline_user_args():
		region = 9200
	if "--luma" in OS.get_cmdline_user_args():
		region = 14500
	if "--dock" in OS.get_cmdline_user_args():
		region = 26000
	if baseline or precurrent or step2:
		var snapshot := "res://tmp/river_view_precurrent.gd" if precurrent else "res://tmp/river_view_baseline.gd"
		if step2:
			snapshot = "res://tmp/river_view_step2.gd"
		if not FileAccess.file_exists(snapshot):
			push_error("Comparison needs renderer snapshot at %s (without class_name)." % snapshot)
			quit(1)
			return
		game.get_child(0).hide()
		var old_view: Node2D = load(snapshot).new()
		old_view.game = game
		game.add_child(old_view)
	game.state = "running"
	game.show_fps = true

func _process(delta: float) -> bool:
	if not is_instance_valid(game):
		return false
	frame += 1
	# Identical positions and animation time for each sample, independent of FPS.
	game.elapsed = float(frame) / 60.0
	var progress := clampf(float(frame - 31) / samples, 0.0, 1.0)
	game.boat_pos.y = -region + 400.0 - progress * 800.0
	game.boat_pos.x = game.river_center(game.boat_pos.y)
	game.velocity = Vector2(0, -155)
	game.camera_y = game.boat_pos.y - 520
	if frame == 31:
		start_us = Time.get_ticks_usec()
	if frame > 31:
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		frame_times.append(delta * 1000.0)
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	if frame == 31 + samples:
		var seconds := float(Time.get_ticks_usec() - start_us) / 1000000
		var label := "step2" if step2 else ("precurrent" if precurrent else ("baseline" if baseline else "cached"))
		if region == 9200:
			label += "_fork"
		elif region == 14500:
			label += "_luma"
		elif region == 26000:
			label += "_dock"
		if samples == 600:
			label += "_long"
		frame_times.sort()
		var report := "%s: %.2f FPS over %d frames (%.3fs); mean frame %.3f ms; median %.3f ms; p95 %.3f ms; mean process %.3f ms; mean draw calls %.1f; sweep %.0f..%.0f" % [label, samples / seconds, samples, seconds, seconds * 1000.0 / samples, frame_times[samples / 2], frame_times[int(samples * 0.95)], process_ms / samples, draws / samples, region - 400, region + 400]
		print(report)
		DirAccess.make_dir_recursive_absolute("res://tmp")
		FileAccess.open("res://tmp/benchmark_%s.txt" % label, FileAccess.WRITE).store_string(report)
		game.save_capture("performance_%s.png" % label)
		await RenderingServer.frame_post_draw
		quit()
	return false

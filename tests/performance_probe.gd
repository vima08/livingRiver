extends SceneTree

# Graphical diagnostic ablations. Removed scenery is never a product optimization.
# Freeze scripts/river_view.gd to ignored tmp/performance_probe_source.gd first.
var game: Node
var frame := 0
var samples := 180
var region := 9200.0
var mode := "baseline"
var start_us := 0
var draws := 0.0
var frame_times: Array[float] = []
var probe_view: Node2D

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		if argument == "--long":
			samples = 600
		if argument == "--luma":
			region = 14500.0
		if argument == "--original":
			region = 5000.0
		if argument == "--dock":
			region = 26000.0
	if mode not in ["baseline", "current", "wateroff", "palmsoff", "canopyoff", "foliageoff", "hudoff", "viewoff", "alloff"]:
		push_error("Unknown diagnostic mode: " + mode)
		quit(1)
		return
	var source_path := "res://scripts/river_view.gd" if mode == "current" else "res://tmp/performance_probe_source.gd"
	var source := FileAccess.get_file_as_string(source_path)
	if source.is_empty():
		push_error("Freeze the current renderer to tmp/performance_probe_source.gd first.")
		quit(1)
		return
	source = source.replace("\r\n", "\n").replace("class_name RiverView\n", "")
	var removed: Array[String] = []
	match mode:
		"wateroff": removed = ["_draw_water"]
		"palmsoff": removed = ["_draw_palm"]
		"canopyoff": removed = ["_draw_canopy"]
		"foliageoff": removed = ["_draw_palm", "_draw_canopy"]
	for method in removed:
		var expression := RegEx.new()
		expression.compile("(?ms)^func " + method + "\\([^\\n]+\\n.*?(?=^func |\\z)")
		var found := expression.search(source)
		if found == null:
			push_error("Missing ablation method: " + method)
			quit(1)
			return
		var header := found.get_string().split("\n")[0]
		source = source.substr(0, found.get_start()) + header + "\n\tpass\n\n" + source.substr(found.get_end())
	var snapshot_path := "res://tmp/performance_probe_%s.gd" % mode
	FileAccess.open(snapshot_path, FileAccess.WRITE).store_string(source)
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	# Disable the hidden production renderer so only the frozen snapshot redraws.
	game.get_child(0).hide()
	game.get_child(0).set_process(false)
	probe_view = load(snapshot_path).new()
	probe_view.game = game
	game.add_child(probe_view)
	if mode == "viewoff":
		probe_view.hide()
		probe_view.set_process(false)
	if mode == "hudoff" or mode == "alloff":
		game.hud.visible = false
		game.hud.set_process(false)
	if mode == "alloff":
		probe_view.hide()
		probe_view.set_process(false)
	game.state = "running"
	game.show_fps = true

func _process(delta: float) -> bool:
	if not is_instance_valid(game):
		return false
	frame += 1
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
	if frame == 31 + samples:
		var seconds := float(Time.get_ticks_usec() - start_us) / 1000000.0
		frame_times.sort()
		var report := "%s region=%.0f: %.2f FPS; %d frames %.3fs; mean %.3f ms; median %.3f ms; p95 %.3f ms; draws %.1f" % [mode, region, samples / seconds, samples, seconds, seconds * 1000.0 / samples, frame_times[samples / 2], frame_times[int(samples * 0.95)], draws / samples]
		print(report)
		FileAccess.open("res://tmp/performance_probe_%s_%.0f_%d.txt" % [mode, region, samples], FileAccess.WRITE).store_string(report)
		game.save_capture("performance-probe-%s-%.0f-%d.png" % [mode, region, samples])
		await RenderingServer.frame_post_draw
		quit()
	return false

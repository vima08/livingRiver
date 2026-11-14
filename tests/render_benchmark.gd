extends SceneTree

# Uncapped, graphical comparison. Baseline snapshot is local ignored data.
var game: Node
var frame := 0
var start_us := 0
var draws := 0.0
var baseline := false
var precurrent := false
var region := 5000.0

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
	if "--fork" in OS.get_cmdline_user_args():
		region = 9200
	if baseline or precurrent:
		var snapshot := "res://tmp/river_view_precurrent.gd" if precurrent else "res://tmp/river_view_baseline.gd"
		if not FileAccess.file_exists(snapshot):
			push_error("Baseline mode needs an uncached renderer snapshot at tmp/river_view_baseline.gd (without class_name).")
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
	game.elapsed += delta
	game.boat_pos.y = -region - game.elapsed * 155
	game.boat_pos.x = game.river_center(game.boat_pos.y)
	game.velocity = Vector2(0, -155)
	game.camera_y = game.boat_pos.y - 520
	if frame == 31:
		start_us = Time.get_ticks_usec()
	if frame > 31:
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if frame == 211:
		var seconds := float(Time.get_ticks_usec() - start_us) / 1000000
		var label := "precurrent" if precurrent else ("baseline" if baseline else "cached")
		if region == 9200:
			label += "_fork"
		var report := "%s: %.1f FPS over 180 frames (%.2fs); mean draw calls %.1f" % [label, 180 / seconds, seconds, draws / 180]
		print(report)
		DirAccess.make_dir_recursive_absolute("res://tmp")
		FileAccess.open("res://tmp/benchmark_%s.txt" % label, FileAccess.WRITE).store_string(report)
		game.save_capture("performance_%s.png" % label)
		await RenderingServer.frame_post_draw
		quit()
	return false

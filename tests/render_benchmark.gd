extends SceneTree

# Uncapped, graphical comparison. Baseline snapshot is local ignored data.
var game: Node
var frame := 0
var start_us := 0
var draws := 0.0
var baseline := false

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	baseline = "--baseline" in OS.get_cmdline_user_args()
	if baseline:
		if not FileAccess.file_exists("res://tmp/river_view_baseline.gd"):
			push_error("Baseline mode needs an uncached renderer snapshot at tmp/river_view_baseline.gd (without class_name).")
			quit(1)
			return
		game.get_child(0).hide()
		var old_view: Node2D = load("res://tmp/river_view_baseline.gd").new()
		old_view.game = game
		game.add_child(old_view)
	game.state = "running"
	game.show_fps = true

func _process(delta: float) -> bool:
	if not is_instance_valid(game):
		return false
	frame += 1
	game.elapsed += delta
	game.boat_pos.y = -5000 - game.elapsed * 155
	game.boat_pos.x = game.river_center(game.boat_pos.y)
	game.velocity = Vector2(0, -155)
	game.camera_y = game.boat_pos.y - 520
	if frame == 31:
		start_us = Time.get_ticks_usec()
	if frame > 31:
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if frame == 211:
		var seconds := float(Time.get_ticks_usec() - start_us) / 1000000
		var report := "%s: %.1f FPS over 180 frames (%.2fs); mean draw calls %.1f" % ["baseline" if baseline else "cached", 180 / seconds, seconds, draws / 180]
		print(report)
		DirAccess.make_dir_recursive_absolute("res://tmp")
		FileAccess.open("res://tmp/benchmark_%s.txt" % ("baseline" if baseline else "cached"), FileAccess.WRITE).store_string(report)
		game.save_capture("performance_%s.png" % ("baseline" if baseline else "cached"))
		await RenderingServer.frame_post_draw
		quit()
	return false

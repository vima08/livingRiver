extends SceneTree

# Full graphical runs use accelerated real simulation, no route teleports.
# --motion instead records normal-speed staged current/recovery examples.
var game: Node
var phase := "safe"
var frames := 0
var phase_frames := 0
var failures := 0
var results: Array[String] = []
var runs: Array[Dictionary] = []
var captures: Dictionary = {}
var motion := false

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.show_fps = true
	motion = "--motion" in OS.get_cmdline_user_args()
	game.start_run()
	game.select_gear(2)
	if motion:
		game.boat_pos = Vector2(game.river_center(-4200), -4200)
		game.camera_y = -4720
		phase = "motion"

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func capture(name: String) -> void:
	if not captures.has(name):
		captures[name] = true
		game.save_capture.call_deferred("milestone2_" + name + ".png")

func click(point: Vector2, pressed: bool) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	Input.parse_input_event(move)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)

func click_depot(index: int, pressed: bool) -> void:
	click(game.hud.canvas.depot_buttons[index].get_global_rect().get_center(), pressed)

func transition(next: String) -> void:
	phase = next
	phase_frames = 0

func start_case(branch: String, gear: int) -> void:
	game.pilot_branch = branch
	game.select_gear(gear)

func finish() -> void:
	var report := "# Milestone 2 graphical evidence\n\n"
	report += "Normal-speed staged current examples at 30 fps. Later examples teleport explicitly; no full-route claim from this recording.\n\n" if motion else "Three full routes rendered with 24 fixed simulation steps per frame (accelerated). No position/resource staging within a route. Depot purchase/equip/Plan next run uses real mouse events and actual buttons; this historical harness then calls start_run for cast off. Milestone-3 playback separately exercises physical Enter after planning. In-memory test profile, no player save changes. Not a human playtest.\n\n"
	for result in results:
		print(result)
		report += "- " + result + "\n"
	for result in runs:
		report += "\n%s / %s: %.2fs, hull%.1f, fuel%.1f\n" % [result.engine, result.branch, result.seconds, result.hull, result.fuel]
	FileAccess.open("res://doc/evidence/milestone2_%s.md" % ("motion" if motion else "graphical"), FileAccess.WRITE).store_string(report)
	quit(1 if failures else 0)

func _process(_delta: float) -> bool:
	if not is_instance_valid(game):
		return false
	frames += 1
	phase_frames += 1
	if motion:
		process_motion()
		return false
	if phase in ["safe", "upgrade_run", "rapids"]:
		for i in range(24):
			var input: Array = game.pilot_controls()
			game.simulate(1.0 / 60, input[0], input[1], input[2])
			if game.state != "running":
				break
		var p: float = -game.boat_pos.y
		for entry in [[4200, "gentle"], [6900, "choice"], [9300, "fork"], [12200, "refuel"]]:
			if absf(p - entry[0]) < 50:
				capture(phase + "_" + entry[1])
		if game.state != "running":
			check(game.state == "success", "%s full graphical route succeeds" % phase)
			check(game.reward_received, "%s delivery grants exactly one support reward" % phase)
			runs.append({"engine": game.engine.display_name, "branch": game.pilot_branch, "seconds": game.elapsed, "hull": game.hull, "fuel": game.fuel})
			capture(phase + "_success")
			transition(phase + "_done")
	elif phase == "safe_done" and phase_frames == 20:
		game.open_depot()
		transition("buy")
	elif phase == "buy":
		if phase_frames == 3:
			capture("depot_before_purchase")
		if phase_frames == 10: click_depot(1, true)
		if phase_frames == 11: click_depot(1, false)
		if phase_frames == 20:
			check("river_triple" in game.profile.owned and game.profile.credits == 0, "Real depot Buy button spends earned 100 credits once")
			capture("depot_purchased")
		if phase_frames == 30: click_depot(1, true)
		if phase_frames == 31: click_depot(1, false)
		if phase_frames == 40:
			check(game.engine.engine_id == "river_triple", "Real Equip button selects purchased three-gear engine")
			capture("depot_equipped")
		if phase_frames == 50: click_depot(3, true)
		if phase_frames == 51: click_depot(3, false)
		if phase_frames == 60:
			check(game.state == "ready" and game.engine.engine_id == "river_triple", "Real Plan next run button returns upgraded briefing")
			game.start_run()
			start_case("rapids", 3)
			transition("upgrade_run")
	elif phase == "upgrade_run_done" and phase_frames == 20:
		game.open_depot()
		transition("starter_equip")
	elif phase == "starter_equip":
		if phase_frames == 10: click_depot(0, true)
		if phase_frames == 11: click_depot(0, false)
		if phase_frames == 20:
			check(game.engine.engine_id == "river_twin", "Owned starter can be equipped free")
			capture("depot_starter_again")
		if phase_frames == 30: click_depot(3, true)
		if phase_frames == 31: click_depot(3, false)
		if phase_frames == 40:
			game.start_run()
			start_case("rapids", 2)
			transition("rapids")
	elif phase == "rapids_done" and phase_frames == 20:
		check(runs.size() == 3, "Three complete graphical runs recorded")
		finish()
	if frames > 3000:
		check(false, "Graphical sequence timeout")
		finish()
	return false

func process_motion() -> void:
	var input := Vector2(0, -1)
	if frames == 100:
		game.boat_pos = Vector2(game.river_center(-8500) + 185, -8500)
		game.velocity = Vector2(0, -155)
	if frames > 100:
		var pilot: Array = game.pilot_controls()
		game.pilot_branch = "rapids"
		input = pilot[0]
	if frames == 220:
		game.boat_pos = game.dock_pos + Vector2(0, -120)
		game.velocity = Vector2.ZERO
		game.select_gear(9)
	if frames >= 220:
		input = Vector2(0, -1)
	var braking := frames > 270
	game.simulate(1.0 / 30, input, braking, frames > 290)
	if frames in [40, 140, 240, 285, 350]:
		capture("motion_%03d" % frames)
	if frames == 360:
		check(game.state == "success", "Normal-speed missed-dock recovery brakes and unloads")
		finish()

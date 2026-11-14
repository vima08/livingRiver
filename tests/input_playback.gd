extends SceneTree

# Graphical input-pipeline evidence. Teleports are explicit scenario setup,
# never used to measure full-route duration (see mission_checks.gd).
var game: Node
var frame := 0
var failures := 0
var results: Array[String] = []

func _initialize() -> void:
	call_deferred("setup")

func setup() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func check(ok: bool, label: String) -> void:
	results.append(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func capture(name: String) -> void:
	game.save_capture.call_deferred(name + ".png")

func _process(_delta: float) -> bool:
	if not is_instance_valid(game):
		return false
	frame += 1
	match frame:
		10: capture("input_00_briefing")
		30: key(KEY_ENTER, true)
		31: key(KEY_ENTER, false)
		60:
			check(game.state == "running" and game.velocity.y < -100, "Enter starts cruise through Input Map")
			key(KEY_D, true)
		100:
			check(game.velocity.x > 100, "Physical D input steers right")
			capture("input_01_steer_right")
		105:
			key(KEY_D, false)
			key(KEY_A, true)
		140:
			check(game.velocity.x < 0, "Physical A input reverses rightward inertia into leftward motion (vx=%.1f)" % game.velocity.x)
			capture("input_02_steer_left")
		145:
			key(KEY_A, false)
			key(KEY_SPACE, true)
		185:
			check(game.velocity.length() < 1, "Space brakes to a full stop")
			capture("input_03_braked")
		195:
			key(KEY_SPACE, false)
			key(KEY_S, true)
		230:
			check(game.velocity.y > 80, "S reverses south for overshoot recovery")
			capture("input_04_reverse")
		235: key(KEY_S, false)
		250:
			game.boat_pos = game.rocks[0].pos + Vector2(0, 95)
			game.velocity = Vector2(0, -155)
		275:
			check(game.hull < 100, "Visible rock contact damages hull")
			capture("input_05_collision")
		300:
			game.boat_pos = game.dock_pos + Vector2(-10, 130)
			game.velocity = Vector2(0, -155)
		310: capture("input_06_dock_approach")
		315: key(KEY_SPACE, true)
		345:
			check(game.can_deliver(), "Dock approached and stopped through ordinary controls")
			key(KEY_E, true)
		375: capture("input_07_unloading")
		415:
			check(game.state == "success" and game.delivered, "Holding E completes unloading through Input Map")
			capture("input_08_success")
		430:
			key(KEY_E, false)
			key(KEY_SPACE, false)
			key(KEY_R, true)
		431: key(KEY_R, false)
		440:
			check(game.state == "running" and not game.delivered and not game.pickup_taken and game.hull == 100 and game.elapsed < 1, "R resets and restarts successful mission")
			capture("input_09_restart")
		450: game.fuel = 0.001
		460:
			check(game.state == "failure" and game.failure_reason.begins_with("Fuel"), "Fuel failure appears in running graphical build")
			capture("input_10_fuel_failure")
		480: key(KEY_R, true)
		481: key(KEY_R, false)
		490:
			game.hull = 1
			game.boat_pos = game.rocks[0].pos + Vector2(0, 50)
			game.velocity = Vector2(0, -155)
		505:
			check(game.state == "failure" and game.failure_reason.begins_with("Hull"), "Collision failure appears in running graphical build")
			capture("input_11_hull_failure")
		530:
			var report := "# Graphical keyboard playback\n\nNormal-speed 30fps engine input playback; not a human playtest. First 8 seconds use unmodified starting state. Later collision, dock, fuel and hull positions/resources are staged explicitly by `tests/input_playback.gd`. Full route evidence is separate.\n\n"
			for result in results:
				print(result)
				report += "- " + result + "\n"
			FileAccess.open("res://doc/evidence/input-checks.md", FileAccess.WRITE).store_string(report)
			quit(1 if failures else 0)
	return false

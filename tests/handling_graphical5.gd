extends SceneTree

# Independent graphical critic: normal clock/physics, physical-key Input Map events.
# Short scenarios explicitly stage initial positions; no continuous-route claim.
const Profile = preload("res://scripts/player_profile.gd")
const Contracts = preload("res://scripts/river_contracts.gd")
var game: Node
var failures := 0
var rows: Array[String] = []
var held: Dictionary = {}

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	rows.append(("PASS " if ok else "FAIL ") + label)
	print(rows.back())
	if not ok: failures += 1

func key(code: int, pressed: bool) -> void:
	if held.get(code, false) == pressed: return
	held[code] = pressed
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func tap(code: int) -> void:
	key(code, true)
	await wait(0.08)
	key(code, false)
	await wait(0.08)

func capture(name: String) -> void:
	await game.save_capture("handling5-" + name + ".png")

func setup(id: String) -> void:
	for code: int in held.keys(): key(code, false)
	var profile := Profile.new("", false)
	var origin: String = Contracts.job(id).origin
	if origin == "koya": profile.award_order(profile.begin_mission("base_light"), "koya_filters")
	if origin == "luma": profile.award_order(profile.begin_mission("base_full"), "luma_food")
	game.profile = profile
	game.ui_screen = "map"
	game.select_contract(id)
	await wait(0.15)
	await tap(KEY_ENTER)
	check(game.state == "running" and game.velocity.length() < 0.1, id + " launches at rest without automatic travel")
	await tap(KEY_2)

func drive_review(id: String) -> void:
	await setup(id)
	var sign_y: float = Contracts.direction(id)
	var start: Vector2 = game.boat_pos
	key(KEY_W, true)
	await wait(1.5)
	check((game.boat_pos.y-start.y)*sign_y > 60 and game.velocity.y*sign_y > 100, id + " forward W moves in trip direction")
	check(absf((game.boat_pos.y-game.camera_y)-(520.0 if sign_y < 0 else 200.0)) < 0.1, id + " camera provides ahead view in trip direction")
	await tap(KEY_9)
	check(game.selected_gear == 2, id + " reverse rejected at cruising ground speed")
	key(KEY_D, true)
	await wait(0.7)
	check(game.velocity.x > 70, id + " D steers screen right")
	await capture(id + "-forward-right")
	key(KEY_D, false)
	key(KEY_A, true)
	await wait(1.1)
	check(game.velocity.x < -70, id + " A steers screen left")
	key(KEY_A, false)
	key(KEY_W, false)
	key(KEY_S, true)
	await wait(0.8)
	check(game.velocity.length() < 0.1, id + " S stops both world axes at calm departure")
	key(KEY_S, false)
	await tap(KEY_9)
	key(KEY_W, true)
	await wait(0.8)
	check(game.selected_gear == 9 and game.velocity.y*sign_y < -50, id + " 9 then W backs away without rotating hull")
	await capture(id + "-reverse")
	key(KEY_W, false)
	key(KEY_S, true)
	await wait(0.8)
	check(game.velocity.length() < 0.1, id + " S brakes actual reverse velocity")
	key(KEY_S, false)

func approach(id: String, landing: String) -> void:
	await setup(id)
	await tap(KEY_1)
	var sign_y: float = Contracts.direction(id)
	# Staged setup 180 world units from dock, stopped, then input-only approach.
	game.boat_pos = game.landing_position(landing) - Vector2(0, sign_y * 180)
	game.velocity = Vector2.ZERO
	key(KEY_W, true)
	await wait(1.25)
	await capture(landing + "-approach")
	key(KEY_W, false)
	key(KEY_S, true)
	await wait(0.6)
	check(game.can_deliver(), id + " staged " + landing + " approach reaches calm receiving circle through W/S")
	key(KEY_E, true)
	await wait(2.2)
	check(game.state == "success" and game.profile.current_landing == landing, id + " E commits " + landing + " arrival")
	await capture(landing + "-arrived")
	key(KEY_E, false)
	key(KEY_S, false)

func fork(branch: String) -> void:
	await setup("luma_base")
	game.pilot_branch = branch
	# Explicit staged fork entrance; subsequent crossing uses physical-key events.
	game.boat_pos = Vector2(game.river_center(-12800), -12800)
	game.velocity = Vector2.ZERO
	var started := Time.get_ticks_msec()
	var shot := false
	var last_hull: float = game.hull
	while game.boat_pos.y < -7000 and Time.get_ticks_msec()-started < 40000 and game.state == "running":
		if game.hull < last_hull:
			rows.append("IMPACT " + branch + " at " + str(game.boat_pos))
			print(rows.back())
			last_hull = game.hull
		var controls: Array = game.pilot_controls()
		key(KEY_W, true)
		key(KEY_A, controls[0].x < -0.09)
		key(KEY_D, controls[0].x > 0.09)
		if game.boat_pos.y > -9600 and not shot:
			await capture("fork-south-" + branch)
			shot = true
		await physics_frame
	check(game.boat_pos.y > -7000 and game.hull == 100, "Southbound " + branch + " fork keyboard crossing clears both tips undamaged (hull %.1f)" % game.hull)
	for code: int in held.keys(): key(code, false)

func review() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	await wait(0.2)
	if "--fork-only" not in OS.get_cmdline_user_args():
		await drive_review("base_light")
		await drive_review("koya_luma")
		await approach("base_light", "koya")
		await approach("koya_luma", "luma")
		await approach("luma_base", "base")
	else:
		await setup("koya_luma")
		key(KEY_W, true)
		await wait(1.5)
		await capture("south-hud-corrected")
		key(KEY_W, false)
	await fork("safe")
	await fork("rapids")
	var report := "# Independent graphical handling review, milestone 5\n\nNormal time scale, ordinary 60 Hz physics, 1280 × 720 renderer, isolated test profile/preferences, InputEventKey physical keys through Input Map. Departure motion is unstaged; docking and fork positions are explicitly staged before their continuous input-only segments. This is automated graphical handling evidence, not a human comfort test or a complete journey. Screenshots accompany actual motion assertions.\n\n"
	for row in rows: report += "- " + row + "\n"
	report += "\nVerdict: " + ("PASS for scoped graphical motion/docking checks" if failures == 0 else "REWORK") + ". Human upstream/downstream attempts and listening remain open. Full real-time route evidence belongs to performance review.\n"
	FileAccess.open("res://doc/evidence/handling-review5-fork-recheck.md" if "--fork-only" in OS.get_cmdline_user_args() else "res://doc/evidence/handling-review5.md", FileAccess.WRITE).store_string(report)
	print("HANDLING_GRAPHICAL5 failures=%d" % failures)
	quit(1 if failures else 0)

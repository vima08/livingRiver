extends Node2D

const Layout = preload("res://scripts/river_layout.gd")
const Hud = preload("res://scripts/hud.gd")
const ROUTE_LENGTH := 26000.0
const BOAT_RADIUS := 18.0
const BOAT_HALF_AXIS := 17.0
const DOCK_SPEED := 45.0
const UNLOAD_SECONDS := 2.0
const METERS_PER_WORLD_UNIT := 0.05
const STARTER_ENGINE = preload("res://resources/engines/river_twin.tres")
const UPGRADE_ENGINE = preload("res://resources/engines/river_triple.tres")
const Profile = preload("res://scripts/player_profile.gd")
const Manifest = preload("res://scripts/relief_manifest.gd")
const Settings = preload("res://scripts/game_settings.gd")
const Text = preload("res://scripts/localization.gd")
const FrontEnd = preload("res://scripts/front_end.gd")
const Audio = preload("res://scripts/river_audio.gd")
const Contracts = preload("res://scripts/river_contracts.gd")

var boat_pos := Vector2(640, 0)
var velocity := Vector2.ZERO
var camera_y := -520.0
var fuel := 100.0
var hull := 100.0
var elapsed := 0.0
var delivered := false
var pickup_taken := false
var state := "ready"
var failure_reason := ""
var unload_progress := 0.0
var impact_cooldown := 0.0
var impact_flash := 0.0
var rocks: Array = []
var fuel_pickup := Vector2.ZERO
var dock_pos := Vector2.ZERO
var hud: CanvasLayer
var audio: Node
var low_fuel_warned := false
var demo := false
var demo_captures := 0
var show_fps := false
var engine: Resource = STARTER_ENGINE
var selected_gear := 1
var gear_notice := ""
var gear_notice_time := 0.0
var profile: RefCounted
var mission_id := 0
var reward_received := false
var depot_return_state := "ready"
var depot_notice := ""
var reset_profile_pending := false
var pilot_branch := "safe"
var load_preset := "light"
var manifest: RefCounted = Manifest.new()
var luma_pos := Vector2.ZERO
var unload_notice := ""
var run_support := 0
var unload_stop := ""
var pilot_skip_luma := false
var settings: RefCounted
var front_end: CanvasLayer
var ui_screen := ""
var screen_return := ""
var engine_throttle := 0.0
var cruise_active := false
var _input_guard_until := -1
var _notice_templates: Dictionary = {}
var contract_id := "base_light"
var travel_sign := -1.0
var base_pos := Vector2.ZERO
var depot_return_screen := ""

func contract() -> Dictionary:
	return Contracts.job(contract_id)

func landing_name(id: String) -> String:
	return str(Contracts.LANDINGS.get(id, id))

func landing_position(id: String) -> Vector2:
	return luma_pos if id == "luma" else dock_pos if id == "koya" else base_pos

func route_distance_total() -> float:
	var job := contract()
	return absf(float(Contracts.LANDING_Y[job.destination]) - float(Contracts.LANDING_Y[job.origin]))

func route_distance_remaining() -> float:
	return boat_pos.distance_to(next_stop_position())

func boat_angle() -> float:
	return (PI if travel_sign > 0 else 0.0) - travel_sign * clampf(velocity.x / 750.0, -0.22, 0.22)

func open_map() -> void:
	if ui_screen in ["language", "settings", "credits"]:
		return
	ui_screen = ""
	var jobs := Contracts.available(profile.current_landing)
	contract_id = jobs[0]
	reset_run()
	if is_instance_valid(front_end):
		front_end.inspected_landing = profile.current_landing
	ui_screen = "map"
	_guard_ui_transition()

func back_to_map() -> void:
	open_map()

func select_contract(id: String) -> bool:
	if ui_screen != "map" or id not in Contracts.available(profile.current_landing):
		return false
	contract_id = id
	ui_screen = ""
	reset_run()
	_guard_ui_transition()
	return true

func set_notice(kind: String, source: String, values: Array = []) -> void:
	var raw: String = source % values if not values.is_empty() else source
	set(kind, raw)
	_notice_templates[kind] = {"source": source, "values": values.duplicate(), "raw": raw}

func localized_notice(kind: String) -> String:
	var raw := str(get(kind))
	var entry: Dictionary = _notice_templates.get(kind, {})
	if not entry.is_empty() and entry.raw == raw:
		return Text.t(entry.source, entry.values)
	return Text.t(raw)

func _guard_ui_transition() -> void:
	# The Enter that activates Play/Back must not also cast off behind that screen.
	_input_guard_until = Engine.get_process_frames() + 1

func choose_language(code: String) -> void:
	if ui_screen not in ["language", "settings"] or code not in ["en", "ru"]:
		return
	settings.set_locale(code)
	Text.set_locale(settings.locale)
	if ui_screen == "language":
		ui_screen = "menu"
	_guard_ui_transition()

func play_from_menu() -> void:
	if ui_screen != "menu":
		return
	open_map()

func open_settings() -> void:
	if ui_screen not in ["", "menu", "map"] or state == "running":
		return
	screen_return = ui_screen
	ui_screen = "settings"
	_guard_ui_transition()

func close_screen() -> void:
	if ui_screen == "settings":
		ui_screen = screen_return
	elif ui_screen == "credits":
		ui_screen = "menu"
	elif ui_screen == "map":
		ui_screen = "menu"
	elif ui_screen.is_empty() and state == "ready":
		open_map()
	_guard_ui_transition()

func resume_run() -> void:
	if ui_screen.is_empty() and state == "paused":
		state = "running"
		_guard_ui_transition()

func return_to_menu() -> void:
	if ui_screen == "language":
		return
	demo = false
	Engine.time_scale = 1.0
	ui_screen = ""
	reset_run()
	ui_screen = "menu"
	_guard_ui_transition()

func quit_game() -> void:
	if ui_screen == "menu":
		get_tree().quit()

func select_load(preset: String) -> bool:
	if not ui_screen.is_empty() or state != "ready" or preset not in ["light", "full"] or contract().origin != "base":
		return false
	contract_id = "base_" + preset
	load_preset = preset
	manifest.configure(preset)
	return true

func completed_order(id: String) -> bool:
	return manifest.completed_order(id)

func nearby_stop() -> String:
	if boat_pos.distance_to(base_pos) < 95:
		return "base"
	if boat_pos.distance_to(luma_pos) < 95:
		return "luma"
	if boat_pos.distance_to(dock_pos) < 95:
		return "koya"
	return ""

func next_stop_position() -> Vector2:
	var order: Dictionary = manifest.next_order()
	return landing_position(str(order.stop) if not order.is_empty() else str(contract().destination))

func complete_order(stop: String) -> bool:
	if not ui_screen.is_empty() or state != "running" or nearby_stop() != stop or velocity.length() >= DOCK_SPEED:
		return false
	var order: Dictionary = manifest.pending_for_stop(stop)
	var empty_arrival: bool = manifest.orders.is_empty() and stop == contract().destination
	if order.is_empty() and not empty_arrival:
		return false
	var committed: bool = profile.commit_arrival(mission_id) if empty_arrival else profile.award_order(mission_id, order.id)
	if not committed:
		set_notice("unload_notice", "Delivery not saved. Cargo retained. Hold E to retry. %s", [profile.load_notice])
		return false
	if not empty_arrival:
		manifest.mark_completed(order.id)
	run_support = manifest.earned_support()
	reward_received = run_support > 0
	if empty_arrival:
		unload_notice = "Moored at Base. No cargo or support reward. Location saved."
	else:
		set_notice("unload_notice", "%s delivered to %s. +%d support saved.", [order.cargo, order.recipient, order.reward])
	unload_progress = 0
	play_tone(880, 0.35)
	if stop == contract().destination:
		delivered = manifest.completed_count() == manifest.total_count()
		state = "success" if delivered else "partial"
		velocity = Vector2.ZERO
		cruise_active = false
		engine_throttle = 0.0
	return true

func apply_equipped_engine() -> void:
	engine = UPGRADE_ENGINE if profile.equipped == "river_triple" else STARTER_ENGINE
	if not engine.valid_data():
		engine = STARTER_ENGINE
	selected_gear = 1

func open_depot() -> void:
	if ui_screen not in ["", "map"] or state not in ["ready", "success", "partial", "failure"]:
		return
	depot_return_screen = ui_screen
	ui_screen = ""
	depot_return_state = state
	state = "depot"
	depot_notice = profile.load_notice
	reset_profile_pending = false

func close_depot() -> void:
	if not ui_screen.is_empty():
		return
	if state == "depot":
		state = depot_return_state
		ui_screen = depot_return_screen
	_guard_ui_transition()
	reset_profile_pending = false

func buy_engine() -> void:
	if not ui_screen.is_empty() or state != "depot":
		return
	if profile.try_purchase("river_triple"):
		depot_notice = "River Triple purchased. Equip it to use third gear next run."
	else:
		depot_notice = profile.load_notice if not profile.load_notice.is_empty() else "Need 100 support credits. Complete a delivery first."

func equip_engine(id: String) -> void:
	if not ui_screen.is_empty() or state != "depot":
		return
	if profile.equip_engine(id):
		apply_equipped_engine()
		set_notice("depot_notice", "%s equipped for the next run.", [engine.display_name])
	else:
		depot_notice = profile.load_notice if not profile.load_notice.is_empty() else "Purchase this engine before equipping it."

func reset_progression() -> void:
	if not ui_screen.is_empty() or state != "depot":
		return
	if not reset_profile_pending:
		reset_profile_pending = true
		depot_notice = "Reset removes credits and engine ownership. Click Confirm reset to continue."
		return
	if profile.reset_profile():
		contract_id = "base_light"
		reset_run()
		state = "depot"
		depot_return_state = "ready"
		depot_return_screen = "map"
		apply_equipped_engine()
		depot_notice = "Progress reset. River Twin is ready."
		# Terminal delivery state cannot issue another reward after a reset.
		mission_id = 0
		reward_received = false
		run_support = 0
	else:
		depot_notice = profile.load_notice
	reset_profile_pending = false

func island_center(y: float) -> float:
	return Layout.island_center(y)

func island_half_width(y: float) -> float:
	return Layout.island_half_width(y)

func current_at(pos: Vector2) -> Vector2:
	return Layout.current_at(pos)

func speed_kmh() -> float:
	return velocity.length() * METERS_PER_WORLD_UNIT * 3.6

func select_gear(gear: int) -> bool:
	if not ui_screen.is_empty() or state not in ["ready", "running"]:
		return false
	if not engine.supports_gear(gear):
		set_notice("gear_notice", "This engine has %d forward gears. 9 selects reverse.", [engine.gear_count()])
		gear_notice_time = 2.5
		return false
	if (gear == 9) != (selected_gear == 9) and velocity.length() >= DOCK_SPEED:
		gear_notice = "Brake below 8 km/h before changing direction."
		gear_notice_time = 2.5
		return false
	selected_gear = gear
	if is_instance_valid(audio):
		audio.play_event("gear")
	gear_notice = ""
	gear_notice_time = 0.0
	return true

func river_center(y: float) -> float:
	return Layout.river_center(y)

func river_half_width(y: float) -> float:
	return Layout.river_half_width(y)

func _ready() -> void:
	var fixture := bool(get_meta("test_mode", false))
	settings = Settings.new("user://settings.cfg", not fixture)
	settings.load_settings()
	Text.set_locale(settings.locale)
	profile = Profile.new("user://profile.json", not fixture)
	profile.load_profile()
	apply_equipped_engine()
	setup_inputs()
	build_route()
	var view := get_node("RiverWorld")
	view.game = self
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	audio = Audio.new()
	audio.game = self
	add_child(audio)
	if not fixture or bool(get_meta("show_frontend", false)):
		ui_screen = "menu" if settings.language_chosen else "language"
	front_end = FrontEnd.new()
	front_end.game = self
	add_child(front_end)
	demo = "--demo" in OS.get_cmdline_user_args()
	if demo:
		ui_screen = ""
		start_run()
		select_gear(2)
		Engine.time_scale = 8.0

func setup_inputs() -> void:
	if InputMap.has_action("brake"):
		InputMap.erase_action("brake")
	var bindings := {
		"steer_left": [KEY_A, KEY_LEFT], "steer_right": [KEY_D, KEY_RIGHT],
		"accelerate": [KEY_W, KEY_UP], "slow_down": [KEY_S, KEY_DOWN],
		"deliver": [KEY_E], "restart": [KEY_R],
		"start_run": [KEY_ENTER], "pause_run": [KEY_ESCAPE],
		"toggle_fps": [KEY_QUOTELEFT], "depot": [KEY_B]
	}
	for gear in range(1, 10):
		bindings["gear_%d" % gear] = [KEY_0 + gear, KEY_KP_0 + gear]
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func build_route() -> void:
	var layout := Layout.build()
	rocks = layout.rocks
	fuel_pickup = layout.fuel_pickup
	base_pos = layout.base_pos
	dock_pos = layout.dock_pos
	luma_pos = layout.luma_pos

func reset_run() -> void:
	if not ui_screen.is_empty():
		return
	if contract().origin != profile.current_landing:
		contract_id = Contracts.available(profile.current_landing)[0]
	travel_sign = Contracts.direction(contract_id)
	boat_pos = landing_position(str(contract().origin))
	velocity = Vector2.ZERO
	camera_y = boat_pos.y - (520.0 if travel_sign < 0 else 200.0)
	fuel = 100.0
	hull = 100.0
	elapsed = 0.0
	delivered = false
	pickup_taken = false
	state = "ready"
	failure_reason = ""
	unload_progress = 0.0
	impact_cooldown = 0.0
	impact_flash = 0.0
	low_fuel_warned = false
	selected_gear = 1
	gear_notice = ""
	gear_notice_time = 0
	mission_id = 0
	reward_received = false
	manifest.configure_contract(contract_id)
	load_preset = manifest.preset
	unload_notice = ""
	run_support = 0
	unload_stop = ""
	engine_throttle = 0
	cruise_active = false
	_notice_templates.clear()
	apply_equipped_engine()

func start_run() -> void:
	if not ui_screen.is_empty() or state != "ready":
		return
	if contract().origin != profile.current_landing or manifest.contract_id != contract_id or not manifest.valid_data() or manifest.completed_count() != 0:
		gear_notice = "Choose a valid relief load before launch."
		gear_notice_time = 4
		return
	var briefing_gear := selected_gear
	apply_equipped_engine()
	if engine.supports_gear(briefing_gear):
		selected_gear = briefing_gear
	mission_id = profile.begin_mission(contract_id)
	if mission_id == 0:
		set_notice("gear_notice", "Launch not saved. Stay at the landing and retry. %s", [profile.load_notice])
		gear_notice_time = 6
		return
	state = "running"
	cruise_active = false

func _physics_process(delta: float) -> void:
	if not ui_screen.is_empty():
		if ui_screen == "map" and Input.is_action_just_pressed("depot"):
			open_depot()
		if Input.is_action_just_pressed("toggle_fps"):
			show_fps = not show_fps
		if Input.is_action_just_pressed("pause_run"):
			close_screen()
		return
	if Engine.get_process_frames() <= _input_guard_until:
		return
	gear_notice_time = maxf(0, gear_notice_time - delta)
	for gear in range(1, 10):
		if Input.is_action_just_pressed("gear_%d" % gear):
			select_gear(gear)
	if Input.is_action_just_pressed("toggle_fps"):
		show_fps = not show_fps
	if Input.is_action_just_pressed("depot"):
		if state == "depot":
			close_depot()
		else:
			open_depot()
	if Input.is_action_just_pressed("restart"):
		open_map()
		return
	if Input.is_action_just_pressed("start_run") and state == "ready":
		start_run()
	if Input.is_action_just_pressed("pause_run"):
		if state == "depot":
			close_depot()
		elif state == "ready":
			open_map()
			return
		elif state == "running":
			state = "paused"
			engine_throttle = 0
			cruise_active = false
		elif state == "paused":
			state = "running"
	# Independent axes preserve forward speed while steering diagonally.
	if state == "running":
		if Input.is_action_just_pressed("accelerate"):
			cruise_active = true
		if Input.is_action_pressed("slow_down"):
			cruise_active = false
	var steering := Vector2(Input.get_axis("steer_left", "steer_right"), -1.0 if cruise_active else 0.0)
	if demo:
		var controls := pilot_controls()
		simulate(delta, controls[0], controls[1], controls[2])
		capture_demo()
	else:
		var braking := not cruise_active
		simulate(delta, steering, braking, Input.is_action_pressed("deliver"))

func simulate(delta: float, steering: Vector2, braking: bool, unloading: bool) -> void:
	if not ui_screen.is_empty() or state != "running":
		return
	elapsed += delta
	impact_cooldown = maxf(0, impact_cooldown - delta)
	impact_flash = maxf(0, impact_flash - delta * 2.5)
	var throttle := maxf(0, -steering.y)
	var direction := travel_sign * (-1.0 if selected_gear == 9 else 1.0)
	var north_speed: float = direction * throttle * engine.speed_for(selected_gear)
	var target := Vector2(steering.x * 205, north_speed)
	var slowing := braking or steering.y > 0
	if slowing:
		target = Vector2.ZERO
	engine_throttle = 0.0 if slowing else throttle
	var drive_target := target
	# Current is incorporated once in target ground velocity, never in camera scroll.
	target += current_at(boat_pos)
	# Physical W/S latch cruise in the input layer; pilots supply explicit demand.
	var acceleration: float = engine.acceleration_for(selected_gear)
	var heavy: bool = manifest.full_load()
	acceleration *= 0.8 if heavy else 1.0
	var deceleration := 390.0 * (0.85 if heavy else 1.0)
	velocity = velocity.move_toward(target, (deceleration if slowing else acceleration) * delta)
	boat_pos += velocity * delta
	var bounded_y := clampf(boat_pos.y, -ROUTE_LENGTH - 150, 90)
	if bounded_y != boat_pos.y:
		boat_pos.y = bounded_y
		velocity.y = 0.0
	resolve_collisions()
	camera_y = boat_pos.y - (520.0 if travel_sign < 0 else 200.0)
	fuel = maxf(0, fuel - delta * (0.55 + drive_target.length() * 0.0008) * engine.fuel_multiplier)
	if not pickup_taken and boat_pos.distance_to(fuel_pickup) < 53:
		pickup_taken = true
		fuel = minf(100, fuel + 38)
		play_tone(660, 0.16)
	if fuel < 22 and not low_fuel_warned:
		low_fuel_warned = true
		play_tone(240, 0.3)
	if fuel <= 0:
		finish_failure("Fuel exhausted. The relief crew is safe; plan your refuel stop.")
		return
	if hull <= 0:
		finish_failure("Hull damaged. The relief crew is safe; take a wider line.")
		return
	var stop := nearby_stop()
	if stop != unload_stop:
		unload_progress = 0
		unload_stop = stop
		unload_notice = ""
	if can_deliver() and unloading:
		unload_progress = minf(UNLOAD_SECONDS, unload_progress + delta)
		if unload_progress >= UNLOAD_SECONDS:
			complete_order(stop)
			unload_progress = 0
	else:
		unload_progress = 0
		var already_delivered := completed_order("luma_food" if stop == "luma" else "koya_filters")
		var mooring: bool = manifest.orders.is_empty() and stop == contract().destination
		if unloading and not stop.is_empty() and manifest.pending_for_stop(stop).is_empty() and not already_delivered and not mooring:
			unload_notice = "No matching cargo for this landing. Continue to the next request."

func can_deliver() -> bool:
	var stop := nearby_stop()
	var matching: bool = not manifest.pending_for_stop(stop).is_empty() or (manifest.orders.is_empty() and stop == contract().destination)
	return state == "running" and matching and velocity.length() < DOCK_SPEED

func resolve_collisions() -> void:
	# A narrow capsule follows the hull rather than an oversized bounding circle.
	var axis := Vector2.DOWN.rotated(boat_angle()) * BOAT_HALF_AXIS
	for endpoint: Vector2 in [axis, -axis]:
		var sample := boat_pos + endpoint
		var center := river_center(sample.y)
		var limit := river_half_width(sample.y) - BOAT_RADIUS
		if absf(sample.x - center) > limit:
			boat_pos.x += clampf(sample.x, center - limit, center + limit) - sample.x
			take_impact(velocity.length())
			velocity.x *= -0.35
	# Sample the same island cross sections used by the renderer with hull support.
	for endpoint: Vector2 in [axis, Vector2.ZERO, -axis]:
		var sample := boat_pos + endpoint
		var half := island_half_width(sample.y)
		if half <= 0:
			continue
		var center := island_center(sample.y)
		if absf(sample.x - center) < half + BOAT_RADIUS:
			var side := -1.0 if sample.x < center else 1.0
			boat_pos.x += center + side * (half + BOAT_RADIUS) - sample.x
			take_impact(velocity.length())
			velocity.x = side * 35
	for rock: Dictionary in rocks:
		var segment_start := boat_pos - axis
		var nearest := Geometry2D.get_closest_point_to_segment(rock.pos, segment_start, boat_pos + axis)
		var offset: Vector2 = nearest - rock.pos
		var separation: float = BOAT_RADIUS + rock.radius
		if offset.length_squared() < separation * separation:
			var normal := offset.normalized() if offset.length() > 0.01 else Vector2.DOWN
			boat_pos += normal * (separation - offset.length())
			take_impact(velocity.length())
			velocity = velocity.slide(normal) + normal * 40

func take_impact(speed: float) -> void:
	if impact_cooldown > 0 or speed < 20:
		return
	hull = maxf(0, hull - clampf(speed * 0.075, 6, 19))
	impact_cooldown = 1.1
	impact_flash = 1
	play_tone(110, 0.12)

func finish_failure(reason: String) -> void:
	state = "failure"
	failure_reason = reason
	velocity = Vector2.ZERO
	engine_throttle = 0
	cruise_active = false
	unload_progress = 0
	play_tone(160, 0.4)

func play_tone(frequency: float, _duration: float) -> void:
	if not is_instance_valid(audio):
		return
	var event := {880: "delivery", 660: "refuel", 240: "low_fuel", 110: "collision", 160: "failure"}
	audio.play_event(event.get(int(frequency), "gear"))

func pilot_controls() -> Array:
	var target_x := river_center(boat_pos.y + travel_sign * 160)
	# This opt-in evidence pilot steers the same simulation as keyboard input.
	# Look ahead around protruding rocks instead of assuming center water is safe.
	for rock: Dictionary in rocks:
		var ahead: float = (rock.pos.y - boat_pos.y) * travel_sign
		if ahead > -90 and ahead < 350 and absf(target_x - rock.pos.x) < rock.radius + 75:
			var side := signf(river_center(rock.pos.y) - rock.pos.x)
			target_x = rock.pos.x + side * (rock.radius + 85)
	var approach_start := -7000.0 if travel_sign < 0 else -7300.0
	var approach_end := -11600.0 if travel_sign < 0 else -11800.0
	if boat_pos.y < approach_start and boat_pos.y > approach_end:
		# Begin choosing a passage before the island reaches the bow.
		target_x = river_center(boat_pos.y + travel_sign * 160) + (185.0 if pilot_branch == "rapids" else -155.0)
	if not pickup_taken and absf(boat_pos.y - fuel_pickup.y) < 450:
		target_x = fuel_pickup.x
	var destination := next_stop_position()
	if pilot_skip_luma and contract_id == "base_full":
		destination = dock_pos
	if absf(boat_pos.y - destination.y) < 600:
		target_x = destination.x
	var horizontal := clampf((target_x - boat_pos.x) * 0.025 - velocity.x * 0.004, -1, 1)
	var near_dock := boat_pos.distance_to(destination) < 75
	return [Vector2(horizontal, -1), near_dock, near_dock]

func capture_demo() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var milestones := [1.0, 35.0, 81.0, 145.0, 168.0]
	if demo_captures < milestones.size() and elapsed >= milestones[demo_captures]:
		save_capture.call_deferred("demo_%02d.png" % demo_captures)
		demo_captures += 1
	if state == "success":
		save_capture.call_deferred("delivery_success.png")
		demo = false
		Engine.time_scale = 1

func save_capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://doc/evidence")
	get_viewport().get_texture().get_image().save_png("res://doc/evidence/" + filename)

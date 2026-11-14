extends Node2D

const View = preload("res://scripts/river_view.gd")
const Hud = preload("res://scripts/hud.gd")
const ROUTE_LENGTH := 26000.0
const BOAT_RADIUS := 18.0
const BOAT_HALF_AXIS := 17.0
const DOCK_SPEED := 45.0
const UNLOAD_SECONDS := 2.0
const METERS_PER_WORLD_UNIT := 0.05
const STARTER_ENGINE = preload("res://resources/engines/river_twin.tres")

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
var audio: AudioStreamPlayer
var low_fuel_warned := false
var demo := false
var demo_captures := 0
var show_fps := false
var engine: Resource = STARTER_ENGINE
var selected_gear := 1
var gear_notice := ""
var gear_notice_time := 0.0

func speed_kmh() -> float:
	return velocity.length() * METERS_PER_WORLD_UNIT * 3.6

func select_gear(gear: int) -> bool:
	if state not in ["ready", "running"]:
		return false
	if not engine.supports_gear(gear):
		gear_notice = "This engine has %d forward gears. 9 selects reverse." % engine.gear_count()
		gear_notice_time = 2.5
		return false
	if (gear == 9) != (selected_gear == 9) and velocity.length() >= DOCK_SPEED:
		gear_notice = "Brake below 8 km/h before changing direction."
		gear_notice_time = 2.5
		return false
	selected_gear = gear
	gear_notice = ""
	gear_notice_time = 0.0
	return true

func river_center(y: float) -> float:
	return 640.0 + sin(-y / 2300.0) * 115.0 + sin(-y / 780.0) * 28.0

func river_half_width(y: float) -> float:
	return 285.0 + sin(-y / 1450.0) * 25.0

func _ready() -> void:
	setup_inputs()
	build_route()
	var view := View.new()
	view.game = self
	add_child(view)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	demo = "--demo" in OS.get_cmdline_user_args()
	if demo:
		start_run()
		select_gear(2)
		Engine.time_scale = 8.0

func setup_inputs() -> void:
	var bindings := {
		"steer_left": [KEY_A, KEY_LEFT], "steer_right": [KEY_D, KEY_RIGHT],
		"accelerate": [KEY_W, KEY_UP], "slow_down": [KEY_S, KEY_DOWN],
		"brake": [KEY_SPACE], "deliver": [KEY_E], "restart": [KEY_R],
		"start_run": [KEY_ENTER], "pause_run": [KEY_ESCAPE],
		"toggle_fps": [KEY_QUOTELEFT]
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
	rocks.clear()
	for i in range(1, 43):
		var y := -650.0 - i * 565.0
		var side := -1.0 if i % 2 == 0 else 1.0
		rocks.append({"pos": Vector2(river_center(y) + side * (95.0 + sin(i * 2.1) * 60.0), y), "radius": 29.0 + fmod(i * 7.0, 19.0)})
		if i % 4 == 0:
			rocks.append({"pos": Vector2(river_center(y + 140) - side * 205.0, y + 140), "radius": 30.0})
	fuel_pickup = Vector2(river_center(-12400), -12400)
	dock_pos = Vector2(river_center(-ROUTE_LENGTH) + river_half_width(-ROUTE_LENGTH) - 105, -ROUTE_LENGTH)

func reset_run() -> void:
	boat_pos = Vector2(river_center(0), 0)
	velocity = Vector2.ZERO
	camera_y = -520.0
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

func start_run() -> void:
	state = "running"

func _physics_process(delta: float) -> void:
	gear_notice_time = maxf(0, gear_notice_time - delta)
	for gear in range(1, 10):
		if Input.is_action_just_pressed("gear_%d" % gear):
			select_gear(gear)
	if Input.is_action_just_pressed("toggle_fps"):
		show_fps = not show_fps
	if Input.is_action_just_pressed("restart"):
		reset_run()
		start_run()
	if Input.is_action_just_pressed("start_run") and state == "ready":
		start_run()
	if Input.is_action_just_pressed("pause_run"):
		if state == "running":
			state = "paused"
		elif state == "paused":
			state = "running"
	# Independent axes preserve forward speed while steering diagonally.
	var steering := Vector2(Input.get_axis("steer_left", "steer_right"), Input.get_axis("accelerate", "slow_down"))
	if demo:
		var controls := pilot_controls()
		simulate(delta, controls[0], controls[1], controls[2])
		capture_demo()
	else:
		var braking := Input.is_action_pressed("brake") or Input.is_action_pressed("slow_down")
		simulate(delta, steering, braking, Input.is_action_pressed("deliver"))

func simulate(delta: float, steering: Vector2, braking: bool, unloading: bool) -> void:
	if state != "running":
		return
	elapsed += delta
	impact_cooldown = maxf(0, impact_cooldown - delta)
	impact_flash = maxf(0, impact_flash - delta * 2.5)
	var throttle := maxf(0, -steering.y)
	var direction := 1.0 if selected_gear == 9 else -1.0
	var north_speed: float = direction * throttle * engine.speed_for(selected_gear)
	var target := Vector2(steering.x * 205, north_speed)
	var slowing := braking or steering.y > 0
	if slowing:
		target = Vector2.ZERO
	# W drives the selected gear; S and Space brake. Release W to coast to rest.
	var acceleration: float = engine.acceleration_for(selected_gear)
	velocity = velocity.move_toward(target, (390.0 if slowing else acceleration) * delta)
	boat_pos += velocity * delta
	var bounded_y := clampf(boat_pos.y, -ROUTE_LENGTH - 150, 90)
	if bounded_y != boat_pos.y:
		boat_pos.y = bounded_y
		velocity.y = 0.0
	resolve_collisions()
	camera_y = boat_pos.y - 520
	fuel = maxf(0, fuel - delta * (0.55 + velocity.length() * 0.0008))
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
	if can_deliver() and unloading:
		unload_progress = minf(UNLOAD_SECONDS, unload_progress + delta)
		if unload_progress >= UNLOAD_SECONDS:
			delivered = true
			state = "success"
			velocity = Vector2.ZERO
			play_tone(880, 0.45)
	else:
		unload_progress = 0

func can_deliver() -> bool:
	return state == "running" and boat_pos.distance_to(dock_pos) < 95 and velocity.length() < DOCK_SPEED

func resolve_collisions() -> void:
	# A narrow capsule follows the hull rather than an oversized bounding circle.
	var axis := Vector2.DOWN.rotated(clampf(velocity.x / 750.0, -0.22, 0.22)) * BOAT_HALF_AXIS
	for endpoint: Vector2 in [axis, -axis]:
		var sample := boat_pos + endpoint
		var center := river_center(sample.y)
		var limit := river_half_width(sample.y) - BOAT_RADIUS
		if absf(sample.x - center) > limit:
			boat_pos.x += clampf(sample.x, center - limit, center + limit) - sample.x
			take_impact(velocity.length())
			velocity.x *= -0.35
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
	unload_progress = 0
	play_tone(160, 0.4)

func play_tone(frequency: float, duration: float) -> void:
	if not is_instance_valid(audio) or DisplayServer.get_name() == "headless":
		return
	var data := PackedByteArray()
	var count := int(duration * 22050)
	data.resize(count * 2)
	for i in count:
		var sample := int(sin(TAU * frequency * i / 22050.0) * 6500 * pow(1.0 - float(i) / count, 2))
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	audio.stream = stream
	audio.play()

func pilot_controls() -> Array:
	var target_x := river_center(boat_pos.y - 160)
	# This opt-in evidence pilot steers the same simulation as keyboard input.
	# Look ahead around protruding rocks instead of assuming center water is safe.
	for rock: Dictionary in rocks:
		var ahead: float = boat_pos.y - rock.pos.y
		if ahead > -90 and ahead < 350 and absf(target_x - rock.pos.x) < rock.radius + 75:
			var side := signf(river_center(rock.pos.y) - rock.pos.x)
			target_x = rock.pos.x + side * (rock.radius + 85)
	if not pickup_taken and absf(boat_pos.y - fuel_pickup.y) < 450:
		target_x = fuel_pickup.x
	if boat_pos.y < -ROUTE_LENGTH + 450:
		target_x = dock_pos.x
	var horizontal := clampf((target_x - boat_pos.x) * 0.025 - velocity.x * 0.004, -1, 1)
	var near_dock := boat_pos.distance_to(dock_pos) < 80
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

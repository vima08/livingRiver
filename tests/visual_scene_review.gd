@tool
extends SceneTree

# Independent scene critic. The editor branch instantiates only the save-free preview.
const Text = preload("res://scripts/localization.gd")
var rows: Array[String] = []
var failures := 0

func _initialize() -> void:
	call_deferred("review")

func check(ok: bool, label: String) -> void:
	rows.append(("PASS " if ok else "FAIL ") + label)
	print(rows.back())
	if not ok: failures += 1

func settle() -> void:
	await create_timer(0.18).timeout

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://doc/evidence/visual-scenes-" + label + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "Rendered capture " + label)

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()

func review() -> void:
	if Engine.is_editor_hint():
		var preview = load("res://scenes/river_world.tscn").instantiate()
		root.add_child(preview)
		await settle()
		check(preview.game is RefCounted and not preview.game is Node, "True editor hint uses data-only preview rather than mission controller")
		for region in range(5):
			preview.preview_region = region
			await settle()
			check(preview.get_node("Boat").visible, "Editor region %d positions native boat" % region)
			var boat: Vector2 = preview.game.boat_pos
			var island_width: float = preview.game.island_half_width(boat.y)
			if island_width > 0.0:
				check(absf(boat.x - preview.game.island_center(boat.y)) > island_width + 18.0, "Editor fork preview places boat in navigable branch")
			await capture("editor-preview-%d" % region)
		preview.preview_southbound = true
		check(is_equal_approx(preview.get_node("Boat").rotation, PI), "True editor hint updates southbound boat orientation")
		preview.queue_free()
	else:
		var gallery = load("res://scenes/asset_gallery.tscn").instantiate()
		root.add_child(gallery)
		await settle()
		check(not gallery.get_node("BoatEmpty/Filters").visible and not gallery.get_node("BoatEmpty/Food").visible, "Gallery empty boat hides cargo")
		check(gallery.get_node("BoatLoaded/Food").visible and gallery.get_node("BoatLoaded/Filters").visible, "Gallery full boat shows both cargo groups")
		check(gallery.get_node("BoatDamaged/Damage").visible, "Gallery damaged boat shows damage geometry")
		check(gallery.get_node("LumaReceived/Received").visible and not gallery.get_node("LumaReceived/Waiting").visible, "Gallery received state differs from waiting state")
		await capture("gallery")
		gallery.queue_free()
		await settle()
		var game = load("res://scenes/main.tscn").instantiate()
		game.set_meta("test_mode", true)
		root.add_child(game)
		await settle()
		var river = game.get_node("RiverWorld")
		check(river.game == game, "Gameplay serialized RiverWorld uses live mission controller")
		check(river.get_node("Boat").scene_file_path == "res://scenes/art/boat.tscn", "Gameplay uses same editable boat PackedScene")
		game.load_preset = "full"
		game.contract_id = "base_full"
		game.reset_run()
		game.start_run()
		await settle()
		check(river.get_node("Boat/Food").visible and river.get_node("Boat/Filters").visible, "Gameplay full contract displays both cargo groups")
		await key(KEY_W)
		var start: Vector2 = game.boat_pos
		await create_timer(0.8).timeout
		check(game.boat_pos.y < start.y and game.cruise_active, "Normal graphical physics continues north cruise after W release")
		check(is_equal_approx(river.get_node("Boat").rotation, game.boat_angle()), "Native boat uses authoritative collision orientation")
		await capture("north-cruise")
		await key(KEY_S)
		check(not game.cruise_active, "S cancels cruise after asset migration")
		game.set_physics_process(false)
		game.hud.visible = false
		for region in ["base", "luma", "koya"]:
			game.boat_pos = game.landing_position(region)
			game.camera_y = game.boat_pos.y - 520.0
			game.velocity = Vector2.ZERO
			game.hull = 30.0
			await settle()
			check(river.get_node("Boat/Damage").visible, "Live low hull displays native damage at " + region)
			await capture(region + "-en")
			Text.set_locale("ru")
			await settle()
			await capture(region + "-ru")
			Text.set_locale("en")
		game.travel_sign = 1.0
		game.camera_y = game.boat_pos.y - 200.0
		game.velocity = Vector2(55, 120)
		await settle()
		check(absf(river.get_node("Boat").rotation - PI) < 0.25, "Southbound native boat points south with steering")
		await capture("south-wake")
		game.queue_free()
	await settle()
	var mode := "editor" if Engine.is_editor_hint() else "graphical"
	var file := FileAccess.open("res://doc/evidence/visual-scenes-" + mode + "-checks.txt", FileAccess.WRITE)
	file.store_string("\n".join(rows) + "\nFailures: %d\n" % failures)
	print("VISUAL_SCENE_REVIEW ", mode, " failures=", failures)
	quit(1 if failures else 0)

@tool
class_name RiverView
extends Node2D

const Preview = preload("res://scripts/editor/river_preview.gd")
const RockScene = preload("res://scenes/art/rock.tscn")

@export_enum("Base", "Fork", "Refuel", "Luma", "Koya") var preview_region: int = 0:
	set(value):
		preview_region = value
		if Engine.is_editor_hint() and is_node_ready():
			_update_preview()
@export var preview_southbound := false:
	set(value):
		preview_southbound = value
		if Engine.is_editor_hint() and is_node_ready():
			_update_preview()
var _locale := ""
var _rock_nodes: Array[Node2D] = []

# All scenery is original geometry. World-anchored motifs keep the route stable.
var game
const WATER := Color("287e79")
const INK := Color("143e3b")
const CREAM := Color("f0ead0")
const ORANGE := Color("ee9251")
const FOAM := Color("b1d9c1")
const CANOPY_VARIANTS := 64
const CANOPY_RADIUS := 40.0
const CANOPY_TEXTURE_SIZE := 128.0
var canopy_textures: Array[Texture2D] = []

var current_textures: Array[Texture2D] = []
var palm_fronds: Texture2D
var island_land := PackedVector2Array()
var island_left := PackedVector2Array()
var island_right := PackedVector2Array()
var water_strokes := PackedVector2Array()
var water_glints := PackedVector2Array()

func _ready() -> void:
	if Engine.is_editor_hint() or not get_parent().has_method("river_center"):
		game = Preview.new()
	else:
		game = get_parent()
	palm_fronds = preload("res://assets/visual/palm_fronds.svg")
	# Reuse imported original leaf textures and keep dense trees batched.
	for variant in range(CANOPY_VARIANTS):
		canopy_textures.append(load("res://assets/visual/canopy_%02d.svg" % variant))
	current_textures = [preload("res://assets/visual/current_gentle.svg"), preload("res://assets/visual/current_rapids.svg") ]
	if Engine.is_editor_hint() or game is Preview:
		_update_preview()

func _process(_delta: float) -> void:
	if game == null:
		return
	if Engine.is_editor_hint():
		return
	_sync_scenes()
	queue_redraw()

func _update_preview() -> void:
	if not game is Preview:
		return
	var positions := [0.0, -9200.0, -12400.0, -14500.0, -26000.0]
	var y: float = positions[preview_region]
	game.boat_pos = Vector2(game.river_center(y), y)
	if preview_region == 1:
		game.boat_pos.x -= 160.0
	game.camera_y = y - (200.0 if preview_southbound else 520.0)
	game.travel_sign = 1.0 if preview_southbound else -1.0
	_sync_scenes()
	queue_redraw()

func _sync_scenes() -> void:
	if not has_node("Boat"):
		return
	if _rock_nodes.size() != game.rocks.size():
		for node in _rock_nodes:
			node.free()
		_rock_nodes.clear()
		for rock: Dictionary in game.rocks:
			var node := RockScene.instantiate() as Node2D
			$Rocks.add_child(node)
			node.scale = Vector2.ONE * float(rock.radius) / 24.0
			_rock_nodes.append(node)
	for i in range(_rock_nodes.size()):
		_position_asset(_rock_nodes[i], game.rocks[i].pos, 110.0)
	_position_asset($Boat, game.boat_pos, 100.0)
	$Boat.rotation = game.boat_angle()
	$Boat.set_boat_state(not game.manifest.pending_for_stop("koya").is_empty(), not game.manifest.pending_for_stop("luma").is_empty(), game.hull < 40)
	_position_asset($FuelBuoy, game.fuel_pickup, 100.0)
	$FuelBuoy.visible = $FuelBuoy.visible and not game.pickup_taken
	_position_asset($BaseLanding, game.base_pos, 200.0)
	_position_asset($LumaLanding, game.luma_pos, 300.0)
	_position_asset($KoyaLanding, game.dock_pos, 300.0)
	$LumaLanding.set_received(game.completed_order("luma_food"))
	$KoyaLanding.set_received(game.completed_order("koya_filters"))
	for node in [$FuelBuoy, $LumaLanding, $KoyaLanding]:
		if node.visible and node.has_method("set_animation_time"):
			node.set_animation_time(game.elapsed)
	if not Engine.is_editor_hint():
		var code: String = preload("res://scripts/localization.gd").locale
		if code != _locale:
			_locale = code
			for node in [$BaseLanding, $LumaLanding, $KoyaLanding]:
				node.refresh_locale()

func _position_asset(node: Node2D, world_position: Vector2, margin: float) -> void:
	node.position = _screen(world_position)
	node.visible = node.position.y > -margin and node.position.y < 720.0 + margin

func _screen(pos: Vector2) -> Vector2:
	return Vector2(pos.x, pos.y - game.camera_y)

func _noise(seed_value: float) -> float:
	return fposmod(sin(seed_value * 127.1 + 311.7) * 43758.5453, 1.0)

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(0, 0, 1280, 720), WATER)
	_draw_water()
	_draw_banks()
	_draw_island()
	_draw_boat()

func _draw_water() -> void:
	# Submit disjoint strokes together instead of hundreds of small AA commands.
	water_strokes.clear()
	water_glints.clear()
	var first := int(floor(game.camera_y / 115.0))
	for row in range(first - 1, first + 9):
		var world_y := float(row) * 115.0
		var center: float = game.river_center(world_y)
		var half: float = game.river_half_width(world_y)
		for column in range(7):
			var seed_value := float(row * 19 + column * 7)
			var x := center + (float(column) / 6.0 - 0.5) * (half * 1.75)
			var y: float = world_y - game.camera_y + _noise(seed_value) * 80.0
			var length := 22.0 + _noise(seed_value + 2.0) * 58.0
			var sway := sin(game.elapsed * 1.3 + seed_value) * 4.0
			var bend := Vector2(x + 3.0 + sway, y + length * 0.45)
			water_strokes.append(Vector2(x, y))
			water_strokes.append(bend)
			water_strokes.append(bend)
			water_strokes.append(Vector2(x, y + length))
			if column % 2 == 0:
				water_glints.append(Vector2(x + 13, y + 9))
				water_glints.append(Vector2(x + 16, y + 22))
	draw_multiline(water_strokes, Color(0.42, 0.74, 0.65, 0.15), 2.0, true)
	draw_multiline(water_glints, Color(0.65, 0.85, 0.72, 0.22), 1.5, true)
	_draw_current_marks()

func _draw_current_marks() -> void:
	# Sparse world-anchored arrows move in the same direction as the physical flow.
	# Double broken chevrons identify fast water through pattern as well as color.
	var first := int(floor(game.camera_y / 170.0))
	for row in range(first - 1, first + 6):
		var world_y := float(row) * 170.0
		var center: float = game.river_center(world_y)
		var half: float = game.river_half_width(world_y)
		for column in range(3):
			var world_pos := Vector2(center + float(column - 1) * half * 0.63, world_y)
			var island_width: float = game.island_half_width(world_y)
			if island_width > 0.0 and absf(world_pos.x - game.island_center(world_y)) < island_width + 20.0:
				continue
			var flow: Vector2 = game.current_at(world_pos)
			var speed := flow.length()
			if speed < 5.0:
				continue
			var direction := flow / speed
			var drift := fposmod(game.elapsed * speed * 0.65, 70.0) - 35.0
			var point := _screen(world_pos + direction * drift)
			var rapid := flow.y < -40.0
			draw_set_transform(point, direction.angle() + PI * 0.5)
			draw_texture_rect(current_textures[1 if rapid else 0], Rect2(-24, -30, 48, 60), false)
			draw_set_transform(Vector2.ZERO)

func _draw_island() -> void:
	if game.camera_y >= -7600.0 or game.camera_y + 720.0 <= -11200.0:
		return
	# Use the same cross-section as collision, including exact pointed ends.
	# Reuse these buffers; the geometry is bounded by the visible screen height.
	island_left.clear()
	island_right.clear()
	island_land.clear()
	var top := maxf(-11200.0, game.camera_y - 24.0)
	var bottom := minf(-7600.0, game.camera_y + 744.0)
	var y := top
	while y < bottom:
		_append_island_section(y)
		y += 16.0
	_append_island_section(bottom)
	island_land.append_array(island_left)
	for index in range(island_right.size() - 1, -1, -1):
		island_land.append(island_right[index])
	if island_land.size() < 4:
		return
	draw_colored_polygon(island_land, Color("a7a16b"))
	draw_polyline(island_left, Color("d1c28b"), 3.0, true)
	draw_polyline(island_right, Color("d1c28b"), 3.0, true)
	for tree_y in [-8400.0, -9400.0, -10400.0]:
		var point := _screen(Vector2(game.island_center(tree_y), tree_y))
		if point.y > -70.0 and point.y < 790.0:
			_draw_canopy(point, 30.0, tree_y * 0.01)

func _append_island_section(world_y: float) -> void:
	var center: float = game.island_center(world_y)
	var width: float = game.island_half_width(world_y)
	var screen_y: float = world_y - game.camera_y
	island_left.append(Vector2(center - width, screen_y))
	island_right.append(Vector2(center + width, screen_y))

func _draw_banks() -> void:
	for side in [-1.0, 1.0]:
		var edge := PackedVector2Array()
		var shallow := PackedVector2Array()
		var sand := PackedVector2Array()
		for sy in range(-48, 801, 16):
			var wy: float = float(sy) + game.camera_y
			var x: float = game.river_center(wy) + side * game.river_half_width(wy)
			edge.append(Vector2(x, sy))
			shallow.append(Vector2(x - side * 16.0, sy))
			sand.append(Vector2(x + side * 12.0, sy))
		var far_x := -100.0 if side < 0 else 1380.0
		var water_shape := shallow.duplicate()
		water_shape.append(Vector2(far_x, 800))
		water_shape.append(Vector2(far_x, -48))
		draw_colored_polygon(water_shape, Color("4b9581"))
		var land := edge.duplicate()
		land.append(Vector2(far_x, 800))
		land.append(Vector2(far_x, -48))
		draw_colored_polygon(land, Color("b4ab72"))
		var forest := sand.duplicate()
		forest.append(Vector2(far_x, 800))
		forest.append(Vector2(far_x, -48))
		draw_colored_polygon(forest, Color("254e3b"))
		draw_polyline(edge, Color("d1c28b"), 3.0, true)
		var start_row := int(floor(game.camera_y / 66.0))
		for row in range(start_row - 2, start_row + 14):
			var wy := float(row) * 66.0
			var edge_x: float = game.river_center(wy) + side * game.river_half_width(wy)
			for layer in range(4):
				var seed_value: float = float(row * 11 + layer * 31) + side * 9.0
				var point := Vector2(edge_x + side * (39.0 + layer * 77.0 + _noise(seed_value) * 23.0), wy - game.camera_y + _noise(seed_value + 2) * 27.0)
				# Leave the contemporary village clearing open at the final dock.
				if side > 0 and absf(wy - game.dock_pos.y) < 235.0:
					continue
				if side < 0 and absf(wy - game.luma_pos.y) < 235.0:
					continue
				_draw_canopy(point, 29.0 + _noise(seed_value + 8) * 21.0, seed_value)
			if row % 3 == 0:
				_draw_palm(Vector2(edge_x + side * 67.0, wy - game.camera_y), float(row) + side)

func _draw_canopy(pos: Vector2, radius: float, seed_value: float) -> void:
	var variant := int(_noise(seed_value) * CANOPY_VARIANTS)
	var size := Vector2.ONE * CANOPY_TEXTURE_SIZE * radius / CANOPY_RADIUS
	if not Rect2(pos - size * 0.5, size).intersects(Rect2(0, 0, 1280, 720)):
		return
	draw_texture_rect(canopy_textures[variant], Rect2(pos - size * 0.5, size), false)

func _draw_palm(pos: Vector2, seed_value: float) -> void:
	var crown := pos + Vector2(-12, -15)
	draw_line(pos + Vector2(13, 25), crown, Color("8c8856"), 6.0, true)
	draw_set_transform(crown, seed_value)
	draw_texture_rect(palm_fronds, Rect2(-64, -64, 128, 128), false)
	draw_set_transform(Vector2.ZERO)

func _draw_boat() -> void:
	var pos := _screen(game.boat_pos)
	if game.impact_flash > 0.0:
		var flash: float = clampf(game.impact_flash, 0.0, 1.0)
		var ring_radius := 40.0 + (1.0 - flash) * 30.0
		draw_circle(pos, 40.0, Color(1.0, 0.57, 0.29, flash * 0.27))
		draw_arc(pos, ring_radius, 0, TAU, 40, Color(1.0, 0.66, 0.37, flash), 4.0, true)
		draw_arc(pos, ring_radius + 8.0, 0, TAU, 40, Color(1.0, 0.91, 0.7, flash * 0.6), 1.5, true)
	var speed: float = game.velocity.length()
	if speed > 1.0:
		var strength := clampf(speed / 140.0, 0.0, 1.0)
		# Local +Y points opposite actual travel, including reverse and lateral motion.
		draw_set_transform(pos, game.velocity.angle() + PI * 0.5)
		for i in range(6):
			var distance := float(i) * 12.0 + fposmod(game.elapsed * 55.0, 12.0)
			var alpha := (1.0 - distance / 84.0) * strength * 0.52
			draw_arc(Vector2(0, 36 + distance), 8 + distance * 0.25, 0.2, PI - 0.2, 12, Color(0.85, 0.94, 0.82, alpha), 2.5, true)
		draw_set_transform(Vector2.ZERO)

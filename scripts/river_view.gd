class_name RiverView
extends Node2D

const Text = preload("res://scripts/localization.gd")

# All scenery is original geometry. World-anchored motifs keep the route stable.
var game: Node
const WATER := Color("287e79")
const INK := Color("143e3b")
const CREAM := Color("f0ead0")
const ORANGE := Color("ee9251")
const FOAM := Color("b1d9c1")
const CANOPY_VARIANTS := 64
const CANOPY_RADIUS := 40.0
const CANOPY_TEXTURE_SIZE := 128.0
var canopy_textures: Array[Texture2D] = []
var rounded_boxes: Dictionary = {}
var current_textures: Array[Texture2D] = []
var palm_fronds: Texture2D
var island_land := PackedVector2Array()
var island_left := PackedVector2Array()
var island_right := PackedVector2Array()
var water_strokes := PackedVector2Array()
var water_glints := PackedVector2Array()

func _ready() -> void:
	palm_fronds = _make_palm_texture()
	# Rasterize the original leaf geometry once, then batch textured trees while scrolling.
	for variant in range(CANOPY_VARIANTS):
		canopy_textures.append(_make_canopy_texture(float(variant) * 3.71))
	for rapid in [false, true]:
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="80" viewBox="0 0 64 80"><g fill="none" stroke="#d9efcc" stroke-width="2.7" stroke-linecap="round" opacity="%s"><path d="M32 58V18 M24 28L32 18L40 28"/>' % ("0.68" if rapid else "0.45")
		if rapid:
			svg += '<path d="M20 62L32 54L44 62 M54 43V55"/>'
		svg += '</g></svg>'
		var image := Image.new()
		image.load_svg_from_string(svg)
		current_textures.append(ImageTexture.create_from_image(image))

func _make_canopy_texture(seed_value: float) -> Texture2D:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="-64 -64 128 128">'
	svg += '<circle cx="7" cy="8" r="42" fill="#0d291f" fill-opacity="0.38"/>'
	svg += '<circle r="40" fill="#1b4937"/>'
	var palette := ["#36683f", "#4e7f45", "#6c944d", "#8da54f"]
	for i in range(7):
		var angle := float(i) * TAU / 7.0 + seed_value
		var center := Vector2.from_angle(angle) * CANOPY_RADIUS * 0.55
		var tint: String = palette[int(_noise(seed_value + i * 3) * 4.0)]
		svg += '<circle cx="%.3f" cy="%.3f" r="20.4" fill="%s"/>' % [center.x, center.y, tint]
		var points := ""
		for step in range(6):
			var arc_angle := lerpf(PI * 1.05, PI * 1.55, float(step) / 5.0)
			var point := center - Vector2(2, 2) + Vector2.from_angle(arc_angle) * CANOPY_RADIUS * 0.31
			points += "%.3f,%.3f " % [point.x, point.y]
		svg += '<polyline points="%s" fill="none" stroke="#a6bf59" stroke-opacity="0.3" stroke-width="1.8"/>' % points
	svg += '</svg>'
	var image := Image.new()
	var error := image.load_svg_from_string(svg)
	if error != OK:
		push_error("Could not rasterize canopy: %s" % error_string(error))
	return ImageTexture.create_from_image(image)

func _make_palm_texture() -> Texture2D:
	# The original seven fronds are static; rotate their cached image at each crown.
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="-64 -64 128 128">'
	for i in range(7):
		var direction := Vector2.from_angle(float(i) * TAU / 7.0)
		var perpendicular := direction.orthogonal()
		var points := "0,0 "
		for point: Vector2 in [direction * 29.0 + perpendicular * 12.0, direction * 59.0, direction * 27.0 - perpendicular * 7.0]:
			points += "%.3f,%.3f " % [point.x, point.y]
		svg += '<polygon points="%s" fill="%s"/>' % [points, "#9bad51" if i % 2 == 0 else "#608a45"]
		svg += '<path d="M0 0L%.3f %.3f" fill="none" stroke="#b6be69" stroke-width="1"/>' % [direction.x * 59.0, direction.y * 59.0]
	svg += '</svg>'
	var image := Image.new()
	var error := image.load_svg_from_string(svg)
	if error != OK:
		push_error("Could not rasterize palm fronds: %s" % error_string(error))
	return ImageTexture.create_from_image(image)

func _process(_delta: float) -> void:
	queue_redraw()

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
	for rock: Dictionary in game.rocks:
		var point := _screen(rock.pos)
		if point.y > -100 and point.y < 820:
			_draw_rock(point, float(rock.radius))
	if not game.pickup_taken:
		_draw_fuel(_screen(game.fuel_pickup))
	_draw_village()
	_draw_luma()
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

func _draw_rock(pos: Vector2, radius: float) -> void:
	draw_circle(pos + Vector2(2, 7), radius + 7, Color(0.07, 0.25, 0.24, 0.42))
	draw_arc(pos + Vector2(0, 5), radius + 9, 0.05, PI - 0.05, 16, FOAM, 3.0, true)
	draw_arc(pos + Vector2(0, 10), radius + 15, 0.35, 2.65, 12, Color(0.7, 0.86, 0.75, 0.35), 1.8, true)
	var shape := PackedVector2Array()
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		shape.append(pos + Vector2.from_angle(angle) * radius)
	draw_colored_polygon(shape, Color("5b6c64"))
	draw_colored_polygon(PackedVector2Array([shape[4], shape[5], shape[6], shape[7], pos + Vector2(3, 3)]), Color("9a9c83"))
	draw_colored_polygon(PackedVector2Array([shape[6], shape[7], shape[0], pos + Vector2(3, 3)]), Color("bab596"))
	draw_polyline(PackedVector2Array([shape[4], shape[5], shape[6], shape[7], shape[0]]), Color("d0c5a0"), 1.5, true)
	draw_line(pos + Vector2(3, 3), shape[2], Color("344c49"), 2.0, true)

func _draw_fuel(pos: Vector2) -> void:
	if pos.y < -80 or pos.y > 800:
		return
	draw_arc(pos, 35 + sin(game.elapsed * 3) * 3, 0, TAU, 28, Color(0.94, 0.75, 0.35, 0.5), 2.0, true)
	draw_circle(pos + Vector2(3, 5), 19, INK)
	draw_style_box(_rounded_box(Color("e9ad47"), 4), Rect2(pos - Vector2(15, 18), Vector2(30, 34)))
	draw_rect(Rect2(pos + Vector2(-5, -23), Vector2(13, 7)), CREAM)
	draw_line(pos + Vector2(-7, -8), pos + Vector2(7, 8), Color("8d6937"), 3.0, true)
	draw_line(pos + Vector2(7, -8), pos + Vector2(-7, 8), Color("8d6937"), 3.0, true)

func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var key := "%s:%d" % [color.to_html(), radius]
	if rounded_boxes.has(key):
		return rounded_boxes[key]
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	rounded_boxes[key] = box
	return box

func _draw_village() -> void:
	var dock := _screen(game.dock_pos)
	if dock.y < -300 or dock.y > 1020:
		return
	var shore: float = game.river_center(game.dock_pos.y) + game.river_half_width(game.dock_pos.y)
	draw_style_box(_rounded_box(Color("b8ac77"), 40), Rect2(shore + 12, dock.y - 180, 440, 350))
	for segment in range(16):
		var start_angle := float(segment) * TAU / 16.0
		draw_arc(dock, 95, start_angle, start_angle + 0.23, 4, Color(0.83, 0.91, 0.66, 0.6 + sin(game.elapsed * 2.0) * 0.15), 2.5, true)
	var pier := Rect2(dock.x + 25, dock.y - 42, shore - dock.x + 50, 84)
	draw_rect(Rect2(pier.position + Vector2(3, 7), pier.size), Color(0.05, 0.18, 0.16, 0.45))
	draw_rect(pier, Color("98754c"))
	for x in range(int(pier.position.x), int(pier.end.x), 13):
		draw_line(Vector2(x, pier.position.y), Vector2(x, pier.end.y), Color("c2a16b"), 2.0)
	for px in [pier.position.x + 4, pier.end.x - 4]:
		for py in [pier.position.y, pier.end.y]:
			draw_circle(Vector2(px, py), 5, Color("564a35"))
	# Solar-roofed clinic and smaller store; people are active at the landing.
	_draw_house(Vector2(shore + 92, dock.y - 125), Vector2(105, 76), true)
	_draw_house(Vector2(shore + 225, dock.y + 85), Vector2(100, 72), false)
	draw_rect(Rect2(shore + 28, dock.y + 115, 190, 30), INK)
	draw_string(ThemeDB.fallback_font, Vector2(shore + 39, dock.y + 136), Text.t("KOYA LANDING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
	var mast := Vector2(shore + 220, dock.y - 108)
	draw_circle(mast + Vector2(5, 5), 14, Color(0.1, 0.2, 0.13, 0.3))
	draw_line(mast + Vector2(-12, 7), mast + Vector2(0, -68), CREAM, 3, true)
	draw_line(mast + Vector2(12, 7), mast + Vector2(0, -68), CREAM, 3, true)
	for level in range(4):
		var y := float(level) * -16.0
		var width := 10.0 - float(level) * 2.0
		draw_line(mast + Vector2(-width, y), mast + Vector2(width - 2, y - 16), ORANGE, 2, true)
		draw_line(mast + Vector2(width, y), mast + Vector2(-width + 2, y - 16), ORANGE, 2, true)
	draw_line(mast + Vector2(0, -68), mast + Vector2(0, -82), INK, 2, true)
	var beacon := mast + Vector2(0, -73)
	if game.completed_order("koya_filters"):
		draw_circle(beacon, 13, Color(0.79, 0.91, 0.5, 0.2))
		draw_circle(beacon, 5, Color("e3ed9a"))
		draw_arc(beacon, 19 + sin(game.elapsed * 2.0) * 3, PI * 1.12, PI * 1.88, 14, Color(0.89, 0.96, 0.65, 0.8), 2, true)
	else:
		draw_circle(beacon, 4, Color("705343"))
	for i in range(3):
		var person := Vector2(shore + 54 + i * 21, dock.y - 7 + (i % 2) * 22)
		draw_circle(person + Vector2(2, 4), 7, Color(0.18, 0.23, 0.14, 0.3))
		draw_line(person + Vector2(0, -2), person + Vector2(0, 7), Color("d68e47") if i % 2 == 0 else Color("d8e6c4"), 9, true)
		draw_circle(person + Vector2(0, -7), 4.5, Color("67472f"))
	for i in range(2):
		var crate := Rect2(shore + 22 + i * 28, dock.y + 55, 23, 23)
		draw_rect(crate, Color("d0af70"))
		draw_rect(crate.grow(-3), Color("876d45"), false, 1)
	var pump := Vector2(shore + 148, dock.y + 27)
	draw_circle(pump, 15, Color("667f6a"))
	draw_line(pump, pump - Vector2(0, 25), Color("384c48"), 6, true)
	draw_line(pump - Vector2(0, 23), pump - Vector2(13, 23), CREAM, 4, true)
	if game.completed_order("koya_filters"):
		draw_circle(pump - Vector2(0, 28), 7, Color("d3e887"))
		draw_line(pump - Vector2(13, 20), pump - Vector2(13, 3), Color("98d8c6"), 3, true)

func _draw_luma() -> void:
	var dock := _screen(game.luma_pos)
	if dock.y < -300 or dock.y > 1020:
		return
	var shore: float = game.river_center(game.luma_pos.y) - game.river_half_width(game.luma_pos.y)
	var received: bool = game.completed_order("luma_food")
	draw_style_box(_rounded_box(Color("b8ac77"), 35), Rect2(shore - 430, dock.y - 180, 418, 350))
	for segment in range(16):
		var angle := float(segment) * TAU / 16.0
		draw_arc(dock, 95, angle, angle + 0.23, 4, Color(0.92, 0.79, 0.53, 0.7), 2.5, true)
	var pier := Rect2(shore - 30, dock.y - 42, dock.x - shore + 5, 84)
	draw_rect(Rect2(pier.position + Vector2(3, 7), pier.size), Color(0.05, 0.18, 0.16, 0.45))
	draw_rect(pier, Color("98754c"))
	for x in range(int(pier.position.x), int(pier.end.x), 13):
		draw_line(Vector2(x, pier.position.y), Vector2(x, pier.end.y), Color("c2a16b"), 2)
	for px in [pier.position.x + 4, pier.end.x - 4]:
		for py in [pier.position.y, pier.end.y]:
			draw_circle(Vector2(px, py), 5, Color("564a35"))
	# An open food shelter and striped awning distinguish this receiving team from Koya.
	var shelter := Vector2(shore - 135, dock.y - 100)
	_draw_house(shelter, Vector2(142, 92), false)
	for i in range(7):
		draw_rect(Rect2(shelter.x - 77 + i * 22, shelter.y + 30, 22, 34), CREAM if i % 2 == 0 else Color("758f5b"))
	for offset in [-70, 70]:
		draw_line(shelter + Vector2(offset, 45), shelter + Vector2(offset, 72), INK, 4)
	draw_rect(Rect2(shelter + Vector2(-72, -13), Vector2(144, 25)), INK)
	draw_string(ThemeDB.fallback_font, shelter + Vector2(-61, 5), Text.t("FOOD SHELTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CREAM)
	var sign := Vector2(shore - 115, dock.y + 90)
	draw_rect(Rect2(sign + Vector2(-86, -19), Vector2(172, 32)), INK)
	draw_string(ThemeDB.fallback_font, sign + Vector2(-72, 3), Text.t("LUMA LANDING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
	draw_string(ThemeDB.fallback_font, sign + Vector2(-72, 36), Text.t("FOOD RECEIVED" if received else "FOOD REQUEST"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)
	# Before arrival the crew prepares an empty receiving table; afterwards crates
	# sit under the shelter and the team works between its store and the landing.
	draw_rect(Rect2(shore - 70, dock.y - 18, 42, 31), Color("6e6947"))
	if received:
		for i in range(4):
			var crate := Rect2(shelter.x - 48 + (i % 2) * 35, shelter.y + 22 + int(i / 2) * 24, 29, 21)
			draw_rect(crate, Color("e0b471"))
			draw_rect(crate.grow(-3), Color("967647"), false, 1)
			draw_line(crate.position + Vector2(14, 1), crate.position + Vector2(14, 20), CREAM, 2)
	for i in range(3):
		var walk := sin(game.elapsed * 1.6 + i * 2.0) * (13.0 if received else 4.0)
		var person := Vector2(shore - 45 - i * 29 + walk, dock.y + 12 + (i % 2) * 28)
		draw_circle(person + Vector2(2, 4), 7, Color(0.18, 0.23, 0.14, 0.3))
		draw_line(person + Vector2(0, -2), person + Vector2(0, 7), ORANGE if i % 2 == 0 else CREAM, 9, true)
		draw_circle(person + Vector2(0, -7), 4.5, Color("67472f"))
		if received and i == 0:
			draw_rect(Rect2(person + Vector2(-6, -2), Vector2(12, 10)), Color("e0b471"))

func _draw_house(pos: Vector2, size: Vector2, solar: bool) -> void:
	var rect := Rect2(pos - size * 0.5, size)
	draw_rect(Rect2(rect.position + Vector2(7, 10), size), Color(0.1, 0.2, 0.13, 0.3))
	draw_rect(rect, Color("d2bd86"))
	draw_rect(Rect2(rect.position - Vector2(5, 5), size + Vector2(10, 0)), Color("af7750"))
	for i in range(8):
		var x: float = rect.position.x + i * size.x / 8.0
		draw_line(Vector2(x, rect.position.y - 4), Vector2(x, rect.end.y - 5), Color("d3a575"), 2)
	draw_line(Vector2(rect.position.x - 6, pos.y - 3), Vector2(rect.end.x + 6, pos.y - 3), Color("764e37"), 3)
	if solar:
		var panel := Rect2(rect.position + Vector2(12, 8), Vector2(64, 35))
		draw_rect(panel.grow(2), CREAM)
		draw_rect(panel, Color("315b6e"))
		for i in range(1, 4):
			draw_line(panel.position + Vector2(i * 16, 0), panel.position + Vector2(i * 16, 35), Color("97b8be"), 1)
		draw_line(panel.position + Vector2(0, 17), panel.position + Vector2(64, 17), Color("97b8be"), 1)

func _draw_boat() -> void:
	var pos := _screen(game.boat_pos)
	if game.impact_flash > 0.0:
		var flash: float = clampf(game.impact_flash, 0.0, 1.0)
		var ring_radius := 40.0 + (1.0 - flash) * 30.0
		draw_circle(pos, 40.0, Color(1.0, 0.57, 0.29, flash * 0.27))
		draw_arc(pos, ring_radius, 0, TAU, 40, Color(1.0, 0.66, 0.37, flash), 4.0, true)
		draw_arc(pos, ring_radius + 8.0, 0, TAU, 40, Color(1.0, 0.91, 0.7, flash * 0.6), 1.5, true)
	var angle: float = clampf(game.velocity.x / 750.0, -0.22, 0.22)
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
	draw_set_transform(pos, angle)
	var hull := PackedVector2Array([Vector2(0, -36), Vector2(13, -23), Vector2(18, 4), Vector2(15, 33), Vector2(-15, 33), Vector2(-18, 4), Vector2(-13, -23)])
	var shadow := PackedVector2Array()
	for point in hull:
		shadow.append(point + Vector2(5, 7))
	draw_colored_polygon(shadow, Color(0.03, 0.18, 0.18, 0.45))
	draw_colored_polygon(hull, ORANGE)
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[5], hull[6], hull[0]]), INK, 2, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(10, -19), Vector2(13, 5), Vector2(11, 28), Vector2(-11, 28), Vector2(-13, 5), Vector2(-10, -19)]), CREAM)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -13), Vector2(9, -13), Vector2(11, 2), Vector2(-11, 2)]), Color("325d65"))
	draw_line(Vector2(-8, -11), Vector2(7, -11), Color("b9d2c5"), 2, true)
	if not game.completed_order("koya_filters"):
		draw_rect(Rect2(-10, 6, 20, 19), Color("6c845a"))
		draw_rect(Rect2(-2, 9, 4, 13), CREAM)
		draw_rect(Rect2(-6, 13, 12, 4), CREAM)
	if not game.manifest.pending_for_stop("luma").is_empty():
		draw_rect(Rect2(-11, -5, 22, 11), Color("d0a061"))
		draw_line(Vector2(0, -4), Vector2(0, 5), CREAM, 2)
	draw_rect(Rect2(-5, 30, 10, 10), Color("28434a"))
	draw_line(Vector2(0, -29), Vector2(0, -39), INK, 2, true)
	if game.hull < 40:
		draw_line(Vector2(9, 0), Vector2(4, 8), Color("9f4b3e"), 3, true)
	draw_set_transform(Vector2.ZERO)

# Explicit migration tool. Editable .tscn files are the authoritative art.
# Run --script res://tools/bake_visual_scenes.gd -- --replace only to replace edits.
extends SceneTree
const INK := Color("143e3b")
const CREAM := Color("f0ead0")
const ORANGE := Color("ee9251")
const FOAM := Color("b1d9c1")
var canvas: Node2D
var owner_root: Node2D
var received := false
var filters := true
var food := true
var damaged := true
var counter := 0
var variant_index := 0
const CANOPY_RADIUS := 40.0

func _begin_group(title: String) -> void:
	canvas = Node2D.new()
	canvas.name = title
	owner_root.add_child(canvas)
	canvas.owner = owner_root

func _noise(seed_value: float) -> float:
	return fposmod(sin(seed_value * 127.1 + 311.7) * 43758.5453, 1.0)

func _bake_foliage() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/visual")
	for variant in range(64):
		variant_index = variant
		_make_canopy_texture(float(variant) * 3.71)
	_make_palm_texture()

func _initialize() -> void:
	if not "--replace" in OS.get_cmdline_user_args():
		print("Explicit bake only: pass -- --replace to replace editable art scenes.")
		quit()
		return
	DirAccess.make_dir_recursive_absolute("res://scenes/art")
	_new_root("Boat")
	owner_root.set_script(load("res://scripts/art/boat_art.gd"))
	_draw_boat()
	owner_root.get_node('Damage').visible = false
	_save("boat")
	for kind in ["luma", "koya", "base"]:
		_new_root(kind.capitalize() + "Landing")
		owner_root.set_script(load("res://scripts/art/landing_art.gd"))
		for state in [false, true]:
			received = state
			canvas = Node2D.new()
			canvas.name = "Received" if state else "Waiting"
			owner_root.add_child(canvas)
			canvas.owner = owner_root
			canvas.visible = not state
			if kind == "luma": _draw_luma()
			elif kind == "koya": _draw_village()
			else: _draw_base()
		_save(kind + "_landing")
	_new_root("Rock")
	_draw_rock(Vector2.ZERO, 24.0)
	_save("rock")
	_new_root("FuelBuoy")
	owner_root.set_script(load('res://scripts/art/fuel_buoy_art.gd'))
	_draw_fuel(Vector2.ZERO)
	_save("fuel_buoy")
	_new_root("House")
	_draw_house(Vector2.ZERO, Vector2(105, 76), true)
	_save("house")
	_bake_foliage()
	quit()

func _new_root(title: String) -> void:
	owner_root = Node2D.new()
	owner_root.name = title
	canvas = owner_root
	counter = 0

func _save(file_name: String) -> void:
	var packed := PackedScene.new()
	var result := packed.pack(owner_root)
	if result == OK: result = ResourceSaver.save(packed, "res://scenes/art/" + file_name + ".tscn")
	if result != OK: push_error("Could not save " + file_name)
	owner_root.free()

func _add(part: Node, title: String) -> void:
	counter += 1
	part.name = title + str(counter)
	canvas.add_child(part)
	part.owner = owner_root

func _record_draw_colored_polygon(points: PackedVector2Array, color: Color) -> void:
	var part := Polygon2D.new()
	part.polygon = points
	part.color = color
	_add(part, "Polygon")

func _record_draw_line(a: Vector2, b: Vector2, color: Color, width := 1.0, aa := false) -> void:
	_record_draw_polyline(PackedVector2Array([a, b]), color, width, aa)

func _record_draw_polyline(points: PackedVector2Array, color: Color, width := 1.0, aa := false) -> void:
	var part := Line2D.new()
	part.points = points
	part.default_color = color
	part.width = width
	part.antialiased = aa
	_add(part, "Line")

func _record_draw_circle(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(64): points.append(center + Vector2.from_angle(i * TAU / 64.0) * radius)
	_record_draw_colored_polygon(points, color)

func _record_draw_arc(center: Vector2, radius: float, start: float, end: float, count: int, color: Color, width := 1.0, aa := false) -> void:
	var points := PackedVector2Array()
	for i in range(count): points.append(center + Vector2.from_angle(lerpf(start, end, float(i) / float(count - 1))) * radius)
	_record_draw_polyline(points, color, width, aa)

func _record_draw_rect(rect: Rect2, color: Color, fill := true, width := 1.0) -> void:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	if fill: _record_draw_colored_polygon(points, color)
	else:
		points.append(rect.position)
		_record_draw_polyline(points, color, width)

func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func _record_draw_style_box(box: StyleBoxFlat, rect: Rect2) -> void:
	var radius := float(box.corner_radius_top_left)
	var points := PackedVector2Array()
	var centers := [rect.position + Vector2(radius, radius), Vector2(rect.end.x - radius, rect.position.y + radius), rect.end - Vector2(radius, radius), Vector2(rect.position.x + radius, rect.end.y - radius)]
	for corner in range(4):
		for step in range(9):
			var angle := PI + corner * PI * 0.5 + step * PI / 16.0
			points.append(centers[corner] + Vector2.from_angle(angle) * radius)
	_record_draw_colored_polygon(points, box.bg_color)

func _source(message: String) -> String:
	return message

func _record_draw_string(font: Font, position: Vector2, message: String, _alignment: int, _width: float, font_size: int, color: Color) -> void:
	var part := Label.new()
	part.position = position - Vector2(0, font.get_ascent(font_size))
	part.text = message
	part.add_theme_font_size_override("font_size", font_size)
	part.add_theme_color_override("font_color", color)
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	part.set_meta("localization_key", message)
	_add(part, "Label")

func _record_draw_set_transform(_position: Vector2) -> void:
	pass

func _draw_rock(pos: Vector2, radius: float) -> void:
	_record_draw_circle(pos + Vector2(2, 7), radius + 7, Color(0.07, 0.25, 0.24, 0.42))
	_record_draw_arc(pos + Vector2(0, 5), radius + 9, 0.05, PI - 0.05, 16, FOAM, 3.0, true)
	_record_draw_arc(pos + Vector2(0, 10), radius + 15, 0.35, 2.65, 12, Color(0.7, 0.86, 0.75, 0.35), 1.8, true)
	var shape := PackedVector2Array()
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		shape.append(pos + Vector2.from_angle(angle) * radius)
	_record_draw_colored_polygon(shape, Color("5b6c64"))
	_record_draw_colored_polygon(PackedVector2Array([shape[4], shape[5], shape[6], shape[7], pos + Vector2(3, 3)]), Color("9a9c83"))
	_record_draw_colored_polygon(PackedVector2Array([shape[6], shape[7], shape[0], pos + Vector2(3, 3)]), Color("bab596"))
	_record_draw_polyline(PackedVector2Array([shape[4], shape[5], shape[6], shape[7], shape[0]]), Color("d0c5a0"), 1.5, true)
	_record_draw_line(pos + Vector2(3, 3), shape[2], Color("344c49"), 2.0, true)



func _draw_fuel(pos: Vector2) -> void:
	if pos.y < -80 or pos.y > 800:
		return
	_begin_group('Pulse')
	_record_draw_arc(pos, 35 + sin(0.0 * 3) * 3, 0, TAU, 28, Color(0.94, 0.75, 0.35, 0.5), 2.0, true)
	canvas = owner_root
	_record_draw_circle(pos + Vector2(3, 5), 19, INK)
	_record_draw_style_box(_rounded_box(Color("e9ad47"), 4), Rect2(pos - Vector2(15, 18), Vector2(30, 34)))
	_record_draw_rect(Rect2(pos + Vector2(-5, -23), Vector2(13, 7)), CREAM)
	_record_draw_line(pos + Vector2(-7, -8), pos + Vector2(7, 8), Color("8d6937"), 3.0, true)
	_record_draw_line(pos + Vector2(7, -8), pos + Vector2(-7, 8), Color("8d6937"), 3.0, true)



func _draw_village() -> void:
	var dock := Vector2.ZERO
	if dock.y < -300 or dock.y > 1020:
		return
	var shore: float = 105.0
	_record_draw_style_box(_rounded_box(Color("b8ac77"), 40), Rect2(shore + 12, dock.y - 180, 440, 350))
	for segment in range(16):
		var start_angle := float(segment) * TAU / 16.0
		_record_draw_arc(dock, 95, start_angle, start_angle + 0.23, 4, Color(0.83, 0.91, 0.66, 0.6 + sin(0.0 * 2.0) * 0.15), 2.5, true)
		canvas.get_child(-1).set_meta('dock_pulse', true)
	var pier := Rect2(dock.x + 25, dock.y - 42, shore - dock.x + 50, 84)
	_record_draw_rect(Rect2(pier.position + Vector2(3, 7), pier.size), Color(0.05, 0.18, 0.16, 0.45))
	_record_draw_rect(pier, Color("98754c"))
	for x in range(int(pier.position.x), int(pier.end.x), 13):
		_record_draw_line(Vector2(x, pier.position.y), Vector2(x, pier.end.y), Color("c2a16b"), 2.0)
	for px in [pier.position.x + 4, pier.end.x - 4]:
		for py in [pier.position.y, pier.end.y]:
			_record_draw_circle(Vector2(px, py), 5, Color("564a35"))
	# Solar-roofed clinic and smaller store; people are active at the landing.
	_draw_house(Vector2(shore + 92, dock.y - 125), Vector2(105, 76), true)
	_draw_house(Vector2(shore + 225, dock.y + 85), Vector2(100, 72), false)
	_record_draw_rect(Rect2(shore + 28, dock.y + 115, 190, 30), INK)
	_record_draw_string(ThemeDB.fallback_font, Vector2(shore + 39, dock.y + 136), _source("KOYA LANDING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
	var mast := Vector2(shore + 220, dock.y - 108)
	_record_draw_circle(mast + Vector2(5, 5), 14, Color(0.1, 0.2, 0.13, 0.3))
	_record_draw_line(mast + Vector2(-12, 7), mast + Vector2(0, -68), CREAM, 3, true)
	_record_draw_line(mast + Vector2(12, 7), mast + Vector2(0, -68), CREAM, 3, true)
	for level in range(4):
		var y := float(level) * -16.0
		var width := 10.0 - float(level) * 2.0
		_record_draw_line(mast + Vector2(-width, y), mast + Vector2(width - 2, y - 16), ORANGE, 2, true)
		_record_draw_line(mast + Vector2(width, y), mast + Vector2(-width + 2, y - 16), ORANGE, 2, true)
	_record_draw_line(mast + Vector2(0, -68), mast + Vector2(0, -82), INK, 2, true)
	var beacon := mast + Vector2(0, -73)
	if received:
		_record_draw_circle(beacon, 13, Color(0.79, 0.91, 0.5, 0.2))
		_record_draw_circle(beacon, 5, Color("e3ed9a"))
		_record_draw_arc(beacon, 19 + sin(0.0 * 2.0) * 3, PI * 1.12, PI * 1.88, 14, Color(0.89, 0.96, 0.65, 0.8), 2, true)
		canvas.get_child(-1).set_meta('beacon_pivot', beacon)
	else:
		_record_draw_circle(beacon, 4, Color("705343"))
	for i in range(3):
		var person := Vector2(shore + 54 + i * 21, dock.y - 7 + (i % 2) * 22)
		_record_draw_circle(person + Vector2(2, 4), 7, Color(0.18, 0.23, 0.14, 0.3))
		_record_draw_line(person + Vector2(0, -2), person + Vector2(0, 7), Color("d68e47") if i % 2 == 0 else Color("d8e6c4"), 9, true)
		_record_draw_circle(person + Vector2(0, -7), 4.5, Color("67472f"))
	for i in range(2):
		var crate := Rect2(shore + 22 + i * 28, dock.y + 55, 23, 23)
		_record_draw_rect(crate, Color("d0af70"))
		_record_draw_rect(crate.grow(-3), Color("876d45"), false, 1)
	var pump := Vector2(shore + 148, dock.y + 27)
	_record_draw_circle(pump, 15, Color("667f6a"))
	_record_draw_line(pump, pump - Vector2(0, 25), Color("384c48"), 6, true)
	_record_draw_line(pump - Vector2(0, 23), pump - Vector2(13, 23), CREAM, 4, true)
	if received:
		_record_draw_circle(pump - Vector2(0, 28), 7, Color("d3e887"))
		_record_draw_line(pump - Vector2(13, 20), pump - Vector2(13, 3), Color("98d8c6"), 3, true)



func _draw_luma() -> void:
	var dock := Vector2.ZERO
	if dock.y < -300 or dock.y > 1020:
		return
	var shore: float = -105.0
	
	_record_draw_style_box(_rounded_box(Color("b8ac77"), 35), Rect2(shore - 430, dock.y - 180, 418, 350))
	for segment in range(16):
		var angle := float(segment) * TAU / 16.0
		_record_draw_arc(dock, 95, angle, angle + 0.23, 4, Color(0.92, 0.79, 0.53, 0.7), 2.5, true)
	var pier := Rect2(shore - 30, dock.y - 42, dock.x - shore + 5, 84)
	_record_draw_rect(Rect2(pier.position + Vector2(3, 7), pier.size), Color(0.05, 0.18, 0.16, 0.45))
	_record_draw_rect(pier, Color("98754c"))
	for x in range(int(pier.position.x), int(pier.end.x), 13):
		_record_draw_line(Vector2(x, pier.position.y), Vector2(x, pier.end.y), Color("c2a16b"), 2)
	for px in [pier.position.x + 4, pier.end.x - 4]:
		for py in [pier.position.y, pier.end.y]:
			_record_draw_circle(Vector2(px, py), 5, Color("564a35"))
	# An open food shelter and striped awning distinguish this receiving team from Koya.
	var shelter := Vector2(shore - 135, dock.y - 100)
	_draw_house(shelter, Vector2(142, 92), false)
	for i in range(7):
		_record_draw_rect(Rect2(shelter.x - 77 + i * 22, shelter.y + 30, 22, 34), CREAM if i % 2 == 0 else Color("758f5b"))
	for offset in [-70, 70]:
		_record_draw_line(shelter + Vector2(offset, 45), shelter + Vector2(offset, 72), INK, 4)
	_record_draw_rect(Rect2(shelter + Vector2(-72, -13), Vector2(144, 25)), INK)
	_record_draw_string(ThemeDB.fallback_font, shelter + Vector2(-61, 5), _source("FOOD SHELTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CREAM)
	var sign := Vector2(shore - 115, dock.y + 90)
	_record_draw_rect(Rect2(sign + Vector2(-86, -19), Vector2(172, 32)), INK)
	_record_draw_string(ThemeDB.fallback_font, sign + Vector2(-72, 3), _source("LUMA LANDING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CREAM)
	_record_draw_string(ThemeDB.fallback_font, sign + Vector2(-72, 36), _source("FOOD RECEIVED" if received else "FOOD REQUEST"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CREAM)
	# Before arrival the crew prepares an empty receiving table; afterwards crates
	# sit under the shelter and the team works between its store and the landing.
	_record_draw_rect(Rect2(shore - 70, dock.y - 18, 42, 31), Color("6e6947"))
	if received:
		for i in range(4):
			var crate := Rect2(shelter.x - 48 + (i % 2) * 35, shelter.y + 22 + int(i / 2) * 24, 29, 21)
			_record_draw_rect(crate, Color("e0b471"))
			_record_draw_rect(crate.grow(-3), Color("967647"), false, 1)
			_record_draw_line(crate.position + Vector2(14, 1), crate.position + Vector2(14, 20), CREAM, 2)
	for i in range(3):
		var crew_parent := canvas
		var crew := Node2D.new()
		crew.name = 'Crew' + str(i)
		crew.set_meta('crew_index', i)
		crew.set_meta('crew_amplitude', 13.0 if received else 4.0)
		canvas.add_child(crew)
		crew.owner = owner_root
		canvas = crew
		var walk := sin(0.0 * 1.6 + i * 2.0) * (13.0 if received else 4.0)
		var person := Vector2(shore - 45 - i * 29 + walk, dock.y + 12 + (i % 2) * 28)
		_record_draw_circle(person + Vector2(2, 4), 7, Color(0.18, 0.23, 0.14, 0.3))
		_record_draw_line(person + Vector2(0, -2), person + Vector2(0, 7), ORANGE if i % 2 == 0 else CREAM, 9, true)
		_record_draw_circle(person + Vector2(0, -7), 4.5, Color("67472f"))
		if received and i == 0:
			_record_draw_rect(Rect2(person + Vector2(-6, -2), Vector2(12, 10)), Color("e0b471"))
		canvas = crew_parent



func _draw_house(pos: Vector2, size: Vector2, solar: bool) -> void:
	var rect := Rect2(pos - size * 0.5, size)
	_record_draw_rect(Rect2(rect.position + Vector2(7, 10), size), Color(0.1, 0.2, 0.13, 0.3))
	_record_draw_rect(rect, Color("d2bd86"))
	_record_draw_rect(Rect2(rect.position - Vector2(5, 5), size + Vector2(10, 0)), Color("af7750"))
	for i in range(8):
		var x: float = rect.position.x + i * size.x / 8.0
		_record_draw_line(Vector2(x, rect.position.y - 4), Vector2(x, rect.end.y - 5), Color("d3a575"), 2)
	_record_draw_line(Vector2(rect.position.x - 6, pos.y - 3), Vector2(rect.end.x + 6, pos.y - 3), Color("764e37"), 3)
	if solar:
		var panel := Rect2(rect.position + Vector2(12, 8), Vector2(64, 35))
		_record_draw_rect(panel.grow(2), CREAM)
		_record_draw_rect(panel, Color("315b6e"))
		for i in range(1, 4):
			_record_draw_line(panel.position + Vector2(i * 16, 0), panel.position + Vector2(i * 16, 35), Color("97b8be"), 1)
		_record_draw_line(panel.position + Vector2(0, 17), panel.position + Vector2(64, 17), Color("97b8be"), 1)



func _draw_base() -> void:
	var dock := Vector2.ZERO
	if dock.y < -180 or dock.y > 900:
		return
	var shore: float = -105.0
	_record_draw_style_box(_rounded_box(Color("b8ac77"), 24), Rect2(shore - 230, dock.y - 100, 218, 200))
	_record_draw_rect(Rect2(shore - 15, dock.y - 30, dock.x - shore + 35, 60), Color("a98555"))
	_record_draw_rect(Rect2(shore - 205, dock.y - 80, 180, 30), INK)
	_record_draw_string(ThemeDB.fallback_font, Vector2(shore - 195, dock.y - 59), _source("BASE DEPOT"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, CREAM)
	_draw_house(Vector2(shore - 130, dock.y + 13), Vector2(92, 65), false)
	for i in range(8):
		_record_draw_arc(dock, 95, i * TAU / 8.0, i * TAU / 8.0 + 0.45, 4, FOAM, 2.0, true)



func _draw_boat() -> void:
	var hull := PackedVector2Array([Vector2(0, -36), Vector2(13, -23), Vector2(18, 4), Vector2(15, 33), Vector2(-15, 33), Vector2(-18, 4), Vector2(-13, -23)])
	var shadow := PackedVector2Array()
	for point in hull:
		shadow.append(point + Vector2(5, 7))
	_record_draw_colored_polygon(shadow, Color(0.03, 0.18, 0.18, 0.45))
	_record_draw_colored_polygon(hull, ORANGE)
	_record_draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[5], hull[6], hull[0]]), INK, 2, true)
	_record_draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(10, -19), Vector2(13, 5), Vector2(11, 28), Vector2(-11, 28), Vector2(-13, 5), Vector2(-10, -19)]), CREAM)
	_record_draw_colored_polygon(PackedVector2Array([Vector2(-9, -13), Vector2(9, -13), Vector2(11, 2), Vector2(-11, 2)]), Color("325d65"))
	_record_draw_line(Vector2(-8, -11), Vector2(7, -11), Color("b9d2c5"), 2, true)
	_begin_group('Filters')
	if filters:
		_record_draw_rect(Rect2(-10, 6, 20, 19), Color("6c845a"))
		_record_draw_rect(Rect2(-2, 9, 4, 13), CREAM)
		_record_draw_rect(Rect2(-6, 13, 12, 4), CREAM)
	canvas = owner_root
	_begin_group('Food')
	if food:
		_record_draw_rect(Rect2(-11, -5, 22, 11), Color("d0a061"))
		_record_draw_line(Vector2(0, -4), Vector2(0, 5), CREAM, 2)
	canvas = owner_root
	_record_draw_rect(Rect2(-5, 30, 10, 10), Color("28434a"))
	_record_draw_line(Vector2(0, -29), Vector2(0, -39), INK, 2, true)
	_begin_group('Damage')
	if damaged:
		_record_draw_line(Vector2(9, 0), Vector2(4, 8), Color("9f4b3e"), 3, true)
	_record_draw_set_transform(Vector2.ZERO)



func _make_canopy_texture(seed_value: float) -> void:
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
	FileAccess.open('res://assets/visual/canopy_%02d.svg' % variant_index, FileAccess.WRITE).store_string(svg)


func _make_palm_texture() -> void:
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
	FileAccess.open('res://assets/visual/palm_fronds.svg', FileAccess.WRITE).store_string(svg)




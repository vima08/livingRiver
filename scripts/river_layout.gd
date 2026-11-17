@tool
extends RefCounted

# Shared geography for gameplay and the save-free editor preview.
static func river_center(y: float) -> float:
	return 640.0 + sin(-y / 2300.0) * 115.0 + sin(-y / 780.0) * 28.0

static func river_half_width(y: float) -> float:
	return 285.0 + sin(-y / 1450.0) * 25.0

static func island_center(y: float) -> float:
	return river_center(y) + 45.0

static func island_half_width(y: float) -> float:
	var progress := -y
	if progress <= 7600 or progress >= 11200:
		return 0
	return sin(PI * (progress - 7600) / 3600) * 95.0

static func current_at(pos: Vector2) -> Vector2:
	var progress := -pos.y
	var gentle := smoothstep(3500, 3900, progress) * (1.0 - smoothstep(5100, 5500, progress))
	var fork := smoothstep(7600, 8100, progress) * (1.0 - smoothstep(10700, 11200, progress))
	var branch := Vector2(0, 32)
	if pos.x > island_center(pos.y):
		branch = Vector2(sin(progress / 210) * 12, 48)
	return Vector2(-12, 35) * gentle + branch * fork

static func build() -> Dictionary:
	var rocks: Array[Dictionary] = []
	for i in range(1, 43):
		var y := -650.0 - i * 565.0
		var side := -1.0 if i % 2 == 0 else 1.0
		rocks.append({"pos": Vector2(river_center(y) + side * (95.0 + sin(i * 2.1) * 60.0), y), "radius": 29.0 + fmod(i * 7.0, 19.0)})
		if i % 4 == 0:
			rocks.append({"pos": Vector2(river_center(y + 140) - side * 205.0, y + 140), "radius": 30.0})
	rocks = rocks.filter(func(rock: Dictionary) -> bool: return rock.pos.y > -7000 or rock.pos.y < -11800)
	for y in [-8500.0, -9700.0, -10600.0]:
		rocks.append({"pos": Vector2(river_center(y) + river_half_width(y) - 30, y), "radius": 28.0})
	var luma := Vector2(river_center(-14500) - river_half_width(-14500) + 105, -14500)
	rocks = rocks.filter(func(rock: Dictionary) -> bool: return absf(rock.pos.y - luma.y) > 450)
	return {"rocks": rocks,
		"fuel_pickup": Vector2(river_center(-12400), -12400),
		"base_pos": Vector2(river_center(0) - river_half_width(0) + 105, 0),
		"dock_pos": Vector2(river_center(-26000) + river_half_width(-26000) - 105, -26000),
		"luma_pos": luma}

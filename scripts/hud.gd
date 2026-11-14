extends CanvasLayer

var game: Node
var canvas: Control

func _ready() -> void:
	canvas = HudCanvas.new()
	canvas.game = game
	add_child(canvas)

class HudCanvas extends Control:
	var game: Node
	var ink := Color("102e2b")
	var cream := Color("f4eed9")
	var mint := Color("8cdbc0")
	var orange := Color("efad65")
	var font: Font = ThemeDB.fallback_font
	var styles: Dictionary = {}
	var depot_buttons: Array[Button] = []

	func _ready() -> void:
		make_button("Equip River Twin", Rect2(240, 398, 350, 34), func(): game.equip_engine("river_twin"))
		make_button("Buy River Triple", Rect2(670, 398, 350, 34), func():
			if "river_triple" in game.profile.owned:
				game.equip_engine("river_triple")
			else:
				game.buy_engine())
		make_button("Reset progression", Rect2(220, 520, 230, 38), func(): game.reset_progression())
		make_button("Launch new run", Rect2(580, 520, 220, 38), func():
			game.reset_run()
			game.start_run())
		make_button("Return / B", Rect2(830, 520, 220, 38), func(): game.close_depot())

	func make_button(label: String, rect: Rect2, callback: Callable) -> void:
		var button := Button.new()
		button.text = label
		button.position = rect.position
		button.size = rect.size
		button.add_theme_font_size_override("font_size", 16)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("27584d")
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate()
		hover.bg_color = Color("3d7966")
		button.add_theme_stylebox_override("hover", hover)
		button.pressed.connect(callback)
		button.visible = false
		add_child(button)
		depot_buttons.append(button)

	func _process(_delta: float) -> void:
		for button in depot_buttons:
			button.visible = game.state == "depot"
		if depot_buttons.size() == 5:
			depot_buttons[0].disabled = game.profile.equipped == "river_twin"
			depot_buttons[1].text = "Equip River Triple" if "river_triple" in game.profile.owned else "Buy / 100 credits"
			depot_buttons[1].disabled = game.profile.equipped == "river_triple"
			depot_buttons[2].text = "Confirm reset" if game.reset_profile_pending else "Reset progression"
		queue_redraw()

	func box(rect: Rect2, color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> void:
		var key := "%s/%d/%s" % [color.to_html(), radius, border.to_html()]
		if not styles.has(key):
			var fresh := StyleBoxFlat.new()
			fresh.bg_color = color
			fresh.set_corner_radius_all(radius)
			fresh.border_color = border
			fresh.set_border_width_all(1)
			styles[key] = fresh
		var style: StyleBoxFlat = styles[key]
		draw_style_box(style, rect)

	func text(at: Vector2, value: String, size: int = 18, color: Color = Color("f4eed9")) -> void:
		draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

	func resource(x: float, label: String, value: float, color: Color) -> void:
		text(Vector2(x, 39), label, 12, mint)
		text(Vector2(x + 155, 39), "%03d" % int(value), 16)
		box(Rect2(x, 50, 190, 6), Color("35524b"), 3)
		if value > 0:
			box(Rect2(x, 50, 190 * value / 100, 6), color, 3)

	func _draw() -> void:
		box(Rect2(22, 18, 1236, 58), Color(0.035, 0.12, 0.11, 0.95), 13, Color("496f5e"))
		text(Vector2(42, 44), "LIVING RIVER", 23)
		text(Vector2(43, 62), "RELIEF RUN  /  01", 10, mint)
		resource(290, "HULL", game.hull, mint)
		resource(515, "FUEL", game.fuel, orange if game.fuel > 22 else Color("ef735d"))
		text(Vector2(750, 39), "AID CARGO", 12, mint)
		text(Vector2(750, 59), "Delivered" if game.delivered else "01  /  Water filters", 17)
		var remaining: float = maxf(0, game.ROUTE_LENGTH + game.boat_pos.y) * game.METERS_PER_WORLD_UNIT
		text(Vector2(1020, 39), "KOYA LANDING", 12, mint)
		text(Vector2(1020, 59), "%0.1f km  /  %02d:%02d" % [remaining / 1000, int(game.elapsed) / 60, int(game.elapsed) % 60], 16)
		box(Rect2(22, 660, 1236, 42), Color(0.035, 0.12, 0.11, 0.96), 10)
		text(Vector2(40, 686), "A D  Steer   W  Throttle   S / SPACE  Brake   1-%d  Forward gears   9  Reverse   Hold E  Unload   R  Restart   ESC  Pause   `  FPS" % game.engine.gear_count(), 13)
		box(Rect2(22, 91, 216, 92), ink, 10)
		text(Vector2(38, 112), "SPEED / GEAR", 11, mint)
		text(Vector2(38, 145), "%02.0f" % game.speed_kmh(), 30)
		text(Vector2(84, 143), "km/h", 14, mint)
		text(Vector2(165, 145), "R" if game.selected_gear == 9 else str(game.selected_gear), 30, orange)
		text(Vector2(38, 168), "%s  |  %d + R" % [game.engine.display_name, game.engine.gear_count()], 12)
		if game.gear_notice_time > 0:
			box(Rect2(280, 140, 720, 32), ink, 8)
			text(Vector2(296, 162), game.gear_notice, 14, orange)
		if game.show_fps:
			box(Rect2(1142, 88, 116, 34), ink, 8)
			text(Vector2(1153, 111), "%d FPS" % Engine.get_frames_per_second(), 18, mint)
		if game.state == "depot":
			draw_depot()
			return
		if game.state == "running":
			var message := "NORTHBOUND  /  Follow the river to Koya Landing"
			if not game.pickup_taken and absf(game.boat_pos.y - game.fuel_pickup.y) < 650:
				message = "REFUEL BUOY AHEAD  /  Touch the orange buoy for +38 fuel"
			elif game.boat_pos.distance_to(game.dock_pos) < 600:
				message = "KOYA LANDING  /  Enter the marked circle. Hold SPACE to stop."
				if game.boat_pos.distance_to(game.dock_pos) < 95:
					message = "HOLD E TO UNLOAD  /  Keep SPACE held" if game.can_deliver() else "BRAKE TO UNLOAD  /  Hold S or SPACE until speed is below 8 km/h"
			elif game.fuel < 22:
				message = "LOW FUEL  /  Conserve your route. Watch for the refuel buoy."
			elif game.boat_pos.y < -6400 and game.boat_pos.y > -7600:
				message = "FORK AHEAD  /  LEFT: wide, slower  |  RIGHT: rapids, faster"
			elif game.island_half_width(game.boat_pos.y) > 0:
				message = "RAPIDS  /  Assisting flow. Keep clear of bank rocks." if game.boat_pos.x > game.island_center(game.boat_pos.y) else "WIDE CHANNEL  /  Gentle opposing flow. More room to maneuver."
			elif game.current_at(game.boat_pos).length() > 1:
				message = "RIVER FLOW  /  Arrows show current direction. Steer against drift."
			box(Rect2(280, 94, 720, 36), Color(0.035, 0.12, 0.11, 0.88), 8)
			text(Vector2(300, 118), message, 15)
			if game.unload_progress > 0:
				box(Rect2(505, 600, 270, 12), ink, 5)
				box(Rect2(505, 600, 270 * game.unload_progress / game.UNLOAD_SECONDS, 12), mint, 5)
			return
		var title := "A river. A lifeline."
		var eyebrow := "LIVING RIVER  /  FIRST RELIEF RUN"
		var lines: Array[String] = [
			"Bring water filters to Koya Landing, 1.3 km upriver.",
			"1-%d: forward gears. 9: reverse. W: throttle. S: brake." % game.engine.gear_count(),
			"Choose wide channel or rapids; refuel after the fork.",
			"At the dock: hold SPACE to stop, then hold E to unload."
		]
		var action := "ENTER  /  Cast off"
		if game.state == "success":
			eyebrow = "DELIVERY COMPLETE  /  KOYA LANDING"
			title = "Clean water starts here."
			var reward: String = "+100 support credits" if game.reward_received else "Reward not saved: " + game.profile.load_notice
			lines = ["The village crew has installed your water filters.", "%s  /  Balance: %d" % [reward, game.profile.credits], "Run time: %02d:%02d     Hull: %d%%     Fuel: %d%%" % [int(game.elapsed) / 60, int(game.elapsed) % 60, int(game.hull), int(game.fuel)], "B: visit the depot to buy or equip an engine."]
			action = "R  /  Run the river again"
		elif game.state == "failure":
			eyebrow = "RUN ENDED  /  RECOVERY CREW DISPATCHED"
			title = "A new route tomorrow."
			lines = [game.failure_reason, "Give rocks a wide berth and keep an eye on your fuel.", "An orange refuel buoy waits halfway along the river.", "Your cargo and crew will return to the starting point."]
			action = "R  /  Try again"
		elif game.state == "paused":
			eyebrow = "RIVER LOG  /  PAUSED"
			title = "Take a breath."
			lines = ["Your boat and resources are paused.", "1-%d: forward gears. 9: reverse. W: throttle. S: brake." % game.engine.gear_count(), "SPACE: brake. Hold E inside the dock circle to unload.", "R restarts the run. Backtick toggles the FPS counter."]
			action = "ESC  /  Continue upriver"
		# Leave the landing visible to the left on completion.
		var origin := Vector2(340, 205)
		box(Rect2(origin, Vector2(600, 320)), Color(0.025, 0.10, 0.09, 0.96), 18, Color("6b9a7b"))
		text(origin + Vector2(30, 36), eyebrow, 12, mint)
		text(origin + Vector2(30, 82), title, 32)
		for i in lines.size():
			text(origin + Vector2(30, 125 + i * 29), lines[i], 16)
		box(Rect2(origin + Vector2(30, 258), Vector2(540, 39)), orange, 7)
		text(origin + Vector2(48, 284), action, 18, ink)
		if game.state in ["ready", "success", "failure"]:
			text(Vector2(360, 554), "B  /  River depot    |    %d support credits    |    %s" % [game.profile.credits, game.engine.display_name], 16)

	func draw_depot() -> void:
		box(Rect2(190, 155, 900, 440), Color(0.025, 0.10, 0.09, 0.98), 18, mint)
		text(Vector2(220, 199), "River depot", 30)
		text(Vector2(820, 199), "%d support credits" % game.profile.credits, 18, orange)
		text(Vector2(220, 226), "Deliver aid to earn support. Engines can only change between runs.", 15, mint)
		for x in [220, 650]:
			box(Rect2(x, 245, 410 if x == 650 else 400, 200), Color("183d35"), 10)
		text(Vector2(240, 278), "River Twin", 24)
		text(Vector2(240, 309), "2 forward gears + reverse  /  17-28 km/h", 15)
		text(Vector2(240, 334), "Fast low-gear response. Proven relief engine.", 14, mint)
		text(Vector2(240, 359), "Base fuel use  /  Owned", 15, orange)
		text(Vector2(240, 383), "Equipped" if game.profile.equipped == "river_twin" else "Ready to equip", 14)
		text(Vector2(670, 278), "River Triple", 24)
		text(Vector2(670, 309), "3 forward gears + reverse  /  16-34 km/h", 15)
		text(Vector2(670, 334), "More top speed; softer acceleration in high gear.", 14, mint)
		text(Vector2(670, 359), "18% more fuel use  /  100 support credits", 15, orange)
		var ownership := "Owned" if "river_triple" in game.profile.owned else "Available after one successful delivery"
		text(Vector2(670, 383), "Equipped" if game.profile.equipped == "river_triple" else ownership, 14)
		text(Vector2(220, 479), game.depot_notice.left(105), 14, orange)
		text(Vector2(220, 503), "R restarts a run. Credits and owned engines persist. Reset progression is separate.", 14, mint)

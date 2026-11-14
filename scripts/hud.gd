extends CanvasLayer

const Text = preload("res://scripts/localization.gd")

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
	var load_buttons: Array[Button] = []
	var launch_button: Button
	var _button_signature := ""

	func _ready() -> void:
		depot_buttons.append(make_button("Equip River Twin", Rect2(240, 420, 350, 34), func(): game.equip_engine("river_twin")))
		depot_buttons.append(make_button("Buy River Triple", Rect2(670, 420, 350, 34), func():
			if "river_triple" in game.profile.owned:
				game.equip_engine("river_triple")
			else:
				game.buy_engine()))
		depot_buttons.append(make_button("Reset progression", Rect2(220, 520, 230, 38), func(): game.reset_progression()))
		depot_buttons.append(make_button("Plan next run", Rect2(580, 520, 220, 38), func(): game.reset_run()))
		depot_buttons.append(make_button("Return / B", Rect2(830, 520, 220, 38), func(): game.close_depot()))
		load_buttons.append(make_button("Choose light run", Rect2(290, 399, 320, 36), func(): game.select_load("light")))
		load_buttons.append(make_button("Choose full relief", Rect2(670, 399, 320, 36), func(): game.select_load("full")))
		launch_button = make_button("ENTER / Cast off", Rect2(390, 534, 500, 40), func(): game.start_run())

	func make_button(label: String, rect: Rect2, callback: Callable) -> Button:
		var button := Button.new()
		button.set_meta("source_text", label)
		button.text = Text.t(label)
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
		return button

	func _process(_delta: float) -> void:
		var ui_open: bool = game.get("ui_screen") != null and str(game.get("ui_screen")) != ""
		visible = not ui_open
		var signature := "%s/%s/%s/%s/%s/%s/%s" % [game.state, ui_open, Text.locale, game.load_preset, game.profile.equipped, "river_triple" in game.profile.owned, game.reset_profile_pending]
		if signature != _button_signature:
			_button_signature = signature
			refresh_buttons(ui_open)
		queue_redraw()

	func refresh_buttons(ui_open: bool) -> void:
		# Hidden labels must not alternate source/selected text and force layout each frame.
		for button in depot_buttons + load_buttons + [launch_button]:
			button.text = Text.t(str(button.get_meta("source_text")))
		for button in depot_buttons:
			button.visible = game.state == "depot" and not ui_open
		for button in load_buttons:
			button.visible = game.state == "ready" and not ui_open
		launch_button.visible = game.state == "ready" and not ui_open
		load_buttons[0].text = Text.t("Selected: light run" if game.load_preset == "light" else "Choose light run")
		load_buttons[1].text = Text.t("Selected: full relief" if game.load_preset == "full" else "Choose full relief")
		depot_buttons[0].disabled = game.profile.equipped == "river_twin"
		depot_buttons[1].text = Text.t("Equip River Triple" if "river_triple" in game.profile.owned else "Buy / 100 credits")
		depot_buttons[1].disabled = game.profile.equipped == "river_triple"
		depot_buttons[2].text = Text.t("Confirm reset" if game.reset_profile_pending else "Reset progression")

	func box(rect: Rect2, color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> void:
		var key := "%s/%d/%s" % [color.to_html(), radius, border.to_html()]
		if not styles.has(key):
			var fresh := StyleBoxFlat.new()
			fresh.bg_color = color
			fresh.set_corner_radius_all(radius)
			fresh.border_color = border
			fresh.set_border_width_all(1)
			styles[key] = fresh
		draw_style_box(styles[key], rect)

	func text(at: Vector2, value: String, size: int = 18, color: Color = Color("f4eed9")) -> void:
		draw_string(font, at, Text.t(value), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

	func paragraph(at: Vector2, value: String, width: float, size: int = 16, color: Color = Color("f4eed9")) -> float:
		var line := ""
		var y := at.y
		for word in Text.t(value).split(" "):
			var candidate := word if line.is_empty() else line + " " + word
			if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and not line.is_empty():
				text(Vector2(at.x, y), line, size, color)
				y += size + 5
				line = word
			else:
				line = candidate
		if not line.is_empty():
			text(Vector2(at.x, y), line, size, color)
		return y - at.y + size + 5

	func resource(x: float, label: String, value: float, color: Color) -> void:
		text(Vector2(x, 39), label, 12, mint)
		text(Vector2(x + 128, 39), "%03d" % int(value), 16)
		box(Rect2(x, 50, 165, 6), Color("35524b"), 3)
		if value > 0:
			box(Rect2(x, 50, 165 * value / 100, 6), color, 3)

	func _draw() -> void:
		if not visible:
			return
		var ended: bool = game.state in ["success", "partial", "failure"]
		box(Rect2(22, 18, 1236, 58), Color(0.035, 0.12, 0.11, 0.95), 13, Color("496f5e"))
		text(Vector2(42, 44), "LIVING RIVER", 23)
		text(Vector2(43, 62), Text.t("RELIEF RUN / %s LOAD", [game.load_preset.to_upper()]), 10, mint)
		resource(265, "HULL", game.hull, mint)
		resource(460, "FUEL", game.fuel, orange if game.fuel > 22 else Color("ef735d"))
		for i in game.manifest.orders.size():
			var order: Dictionary = game.manifest.orders[i]
			var cargo_status := "arrived" if order.completed else "returning" if ended else "aboard"
			text(Vector2(650, 39 + i * 21), Text.t("%s: %s / %s", [order.recipient, order.cargo, cargo_status]), 12, mint if order.completed else cream)
		var next: Dictionary = game.manifest.next_order()
		var remaining: float = game.boat_pos.distance_to(game.next_stop_position()) * game.METERS_PER_WORLD_UNIT
		text(Vector2(1060, 39), "RUN COMPLETE" if game.state == "success" else "RUN ENDED" if ended else Text.t("NEXT: %s", [str(next.get("recipient", "Koya Landing"))]), 12, mint)
		text(Vector2(1060, 59), Text.t("%02d:%02d elapsed", [int(game.elapsed) / 60, int(game.elapsed) % 60]) if ended else Text.t("%0.2f km / %02d:%02d", [remaining / 1000, int(game.elapsed) / 60, int(game.elapsed) % 60]), 15)
		box(Rect2(22, 660, 1236, 42), Color(0.035, 0.12, 0.11, 0.96), 10)
		text(Vector2(40, 686), Text.t("A D Steer   W Throttle   S / SPACE Brake   1-%d Gears   9 Reverse   Hold E Unload   R Briefing   ESC Pause   ` FPS", [game.engine.gear_count()]), 14)
		box(Rect2(22, 91, 216, 113), ink, 10)
		text(Vector2(38, 112), "ACTUAL SPEED / GEAR", 11, mint)
		text(Vector2(38, 145), "%02.0f" % game.speed_kmh(), 30)
		text(Vector2(84, 143), "km/h", 14, mint)
		text(Vector2(165, 145), "R" if game.selected_gear == 9 else str(game.selected_gear), 30, orange)
		text(Vector2(38, 168), Text.t("%s | %d + R", [game.engine.display_name, game.engine.gear_count()]), 12)
		paragraph(Vector2(38, 185), Text.t("CARGO LOG CLOSED" if ended else "HEAVY: brake earlier" if game.manifest.full_load() else "LIGHT: normal handling"), 185, 12, orange if game.manifest.full_load() and not ended else mint)
		if game.show_fps:
			box(Rect2(1142, 88, 116, 34), ink, 8)
			text(Vector2(1153, 111), Text.t("%d FPS", [Engine.get_frames_per_second()]), 18, mint)
		if game.state == "depot":
			draw_depot()
		elif game.state == "ready":
			draw_briefing()
		elif game.state == "running":
			draw_navigation()
		else:
			draw_result()
		if game.gear_notice_time > 0:
			box(Rect2(280, 148, 720, 32), ink, 8)
			text(Vector2(296, 170), game.localized_notice("gear_notice"), 14, orange)

	func draw_navigation() -> void:
		var next: Dictionary = game.manifest.next_order()
		var message := Text.t("NORTHBOUND / Next: %s", [str(next.get("recipient", "Koya Landing"))])
		var stop: String = game.nearby_stop()
		var threshold: float = game.DOCK_SPEED * game.METERS_PER_WORLD_UNIT * 3.6
		if not stop.is_empty():
			if game.manifest.pending_for_stop(stop).is_empty():
				message = Text.t("%s / No matching cargo to deliver. Continue upriver.", [stop.capitalize()])
				if game.completed_order("luma_food") and stop == "luma":
					message = "LUMA / Food delivered. Continue upriver to Koya Landing."
			elif game.speed_kmh() >= threshold:
				message = Text.t("BRAKE TO UNLOAD / Hold S or SPACE below %.1f km/h", [threshold])
			elif stop == "koya" and not game.manifest.pending_for_stop("luma").is_empty():
				message = "HOLD E: finish PARTIAL / Luma food will return to the depot."
			else:
				message = Text.t("HOLD E TO UNLOAD / Keep SPACE held below %.1f km/h", [threshold])
		elif not game.pickup_taken and absf(game.boat_pos.y - game.fuel_pickup.y) < 650:
			message = "REFUEL BUOY / Touch the orange buoy for fuel."
		elif game.boat_pos.distance_to(game.next_stop_position()) < 650:
			message = Text.t("%s / Enter the circle. Hold SPACE to stop.", [str(next.get("recipient", "Koya"))])
		elif game.fuel < 22:
			message = "LOW FUEL / Watch for the refuel buoy."
		elif game.boat_pos.y < -6400 and game.boat_pos.y > -7600:
			message = "FORK AHEAD / LEFT: wide, slower | RIGHT: rapids, faster"
		elif game.island_half_width(game.boat_pos.y) > 0:
			message = "RAPIDS / Assisting flow. Keep clear of rocks." if game.boat_pos.x > game.island_center(game.boat_pos.y) else "WIDE CHANNEL / Gentle opposing flow. More room."
		box(Rect2(280, 94, 720, 36), Color(0.035, 0.12, 0.11, 0.94), 8)
		text(Vector2(296, 118), message, 15)
		if not game.unload_notice.is_empty():
			box(Rect2(280, 198, 720, 86), ink, 8)
			paragraph(Vector2(296, 221), game.localized_notice("unload_notice"), 688, 14, orange)
		if game.unload_progress > 0:
			box(Rect2(505, 600, 270, 12), ink, 5)
			box(Rect2(505, 600, 270 * game.unload_progress / game.UNLOAD_SECONDS, 12), mint, 5)

	func draw_briefing() -> void:
		box(Rect2(250, 148, 780, 480), Color(0.025, 0.10, 0.09, 0.98), 18, Color("6b9a7b"))
		text(Vector2(280, 184), "COMMUNITY REQUESTS / CHOOSE YOUR LOAD", 13, mint)
		text(Vector2(280, 225), "More aid. A heavier boat.", 30)
		for i in range(2):
			var x := 275 + i * 380
			var selected: bool = game.load_preset == ("light" if i == 0 else "full")
			box(Rect2(x, 246, 350, 202), Color("214d41") if selected else ink, 10, mint if selected else Color("36574c"))
		text(Vector2(290, 278), "Light run / 100 support", 21)
		text(Vector2(290, 309), "1. Koya / water filters", 17)
		text(Vector2(290, 340), "One stop, normal handling.", 15, mint)
		text(Vector2(290, 367), "The lightest route to clean water.", 14)
		text(Vector2(670, 278), "Full relief / 160 support", 21)
		text(Vector2(670, 309), "1. Luma / food   2. Koya / filters", 16)
		text(Vector2(670, 340), "Both aboard: -20% acceleration", 15, orange)
		paragraph(Vector2(670, 365), Text.t("15% weaker brakes. Light after Luma."), 320, 14, orange)
		text(Vector2(280, 476), "Choose wide channel or rapids; refuel after the fork.", 17)
		paragraph(Vector2(280, 504), Text.t("Dock: brake below %.1f km/h, then hold E. Load locks at launch.", [game.DOCK_SPEED * game.METERS_PER_WORLD_UNIT * 3.6]), 720, 15, mint)
		text(Vector2(280, 605), Text.t("B Depot / %d credits / %s / R keeps credits and engines", [game.profile.credits, game.engine.display_name]), 15)

	func draw_result() -> void:
		box(Rect2(100, 220, 700, 390), Color(0.025, 0.10, 0.09, 0.97), 18, Color("6b9a7b"))
		if game.state == "paused":
			text(Vector2(130, 259), "RIVER LOG / PAUSED", 13, mint)
			text(Vector2(130, 305), "Take a breath.", 32)
			text(Vector2(130, 353), "Boat, resources and unload progress are paused.", 18)
			text(Vector2(130, 388), "ESC resumes. R returns to cargo selection.", 18)
			text(Vector2(130, 423), "Credits and owned engines are retained.", 17, mint)
			return
		var title := "Aid delivered." if game.state == "success" else "Partial delivery." if game.state == "partial" else "Run ended."
		text(Vector2(130, 259), Text.t("RELIEF RUN / %d OF %d REQUESTS COMPLETE", [game.manifest.completed_count(), game.manifest.total_count()]), 13, mint)
		text(Vector2(130, 305), title, 32)
		var y := 341
		if game.state == "failure":
			y += paragraph(Vector2(130, y), game.localized_notice("failure_reason"), 640, 17, orange) + 8
		for order: Dictionary in game.manifest.orders:
			var status := Text.t("+%d support saved", [int(order.reward)]) if order.completed else "undelivered / returns to depot"
			text(Vector2(130, y), Text.t("%s / %s: %s", [order.recipient, order.cargo, status]), 16, mint if order.completed else orange)
			y += 27
		if game.completed_order("luma_food"):
			text(Vector2(130, y), "Luma's team stocked the community food shelter.", 16)
			y += 27
		if game.completed_order("koya_filters"):
			text(Vector2(130, y), "Koya's crew can run the filtered-water pump and clinic radio.", 16)
			y += 27
		text(Vector2(130, 521), Text.t("Saved this run: %d support / Balance: %d", [game.run_support, game.profile.credits]), 18, mint)
		text(Vector2(130, 553), "R: choose a new load / B: depot", 19, orange)
		text(Vector2(130, 580), "Credits and owned engines are retained.", 15)

	func draw_depot() -> void:
		box(Rect2(190, 155, 900, 440), Color(0.025, 0.10, 0.09, 0.98), 18, mint)
		text(Vector2(220, 199), "River depot", 30)
		text(Vector2(820, 199), Text.t("%d support credits", [game.profile.credits]), 18, orange)
		text(Vector2(220, 226), "Deliver aid to earn support. Engines can only change between runs.", 15, mint)
		for x in [220, 650]:
			box(Rect2(x, 245, 410 if x == 650 else 400, 216), Color("183d35"), 10)
		text(Vector2(240, 278), "River Twin", 24)
		text(Vector2(240, 309), "2 forward gears + reverse / 17-28 km/h", 15)
		paragraph(Vector2(240, 334), Text.t("Fast low-gear response. Proven relief engine."), 360, 14, mint)
		text(Vector2(240, 378), "Base fuel use / Owned", 15, orange)
		text(Vector2(240, 402), "Equipped" if game.profile.equipped == "river_twin" else "Ready to equip", 14)
		text(Vector2(670, 278), "River Triple", 24)
		text(Vector2(670, 309), "3 forward gears + reverse / 16-34 km/h", 15)
		paragraph(Vector2(670, 334), Text.t("More top speed; softer acceleration in high gear."), 370, 14, mint)
		text(Vector2(670, 378), "18% more fuel use / 100 support credits", 15, orange)
		text(Vector2(670, 402), "Equipped" if game.profile.equipped == "river_triple" else "Owned" if "river_triple" in game.profile.owned else "Available to buy", 14)
		paragraph(Vector2(220, 470), game.localized_notice("depot_notice"), 840, 14, orange)
		text(Vector2(220, 510), "R returns to briefing. Credits and engines persist. Reset progression is separate.", 14, mint)

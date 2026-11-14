extends CanvasLayer

const Text = preload("res://scripts/localization.gd")
var game: Node
var canvas: Control
var content: VBoxContainer
var notice_label: Label
var _signature := ""
var _focus_controls: Array[Control] = []

func _ready() -> void:
	layer = 20
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()
	if is_instance_valid(notice_label):
		notice_label.text = Text.t(game.settings.notice)
		notice_label.visible = not game.settings.notice.is_empty()

func _refresh() -> void:
	var screen: String = game.ui_screen
	if screen.is_empty() and game.state == "paused":
		screen = "pause"
	if screen.is_empty() and game.state in ["ready", "success", "partial", "failure"]:
		screen = "menu_access"
	var signature := screen + ":" + Text.locale
	if signature == _signature:
		return
	_signature = signature
	for child in canvas.get_children():
		canvas.remove_child(child)
		child.queue_free()
	_focus_controls.clear()
	notice_label = null
	if screen.is_empty():
		return
	if screen == "menu_access":
		var access := Button.new()
		access.text = Text.t("Main menu")
		access.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		access.offset_left = -220
		access.offset_top = 132
		access.offset_right = -30
		access.offset_bottom = 168
		access.pressed.connect(game.return_to_menu)
		canvas.add_child(access)
		return
	var background := ColorRect.new()
	background.color = Color(0.025, 0.10, 0.09, 0.98 if screen != "pause" else 0.91)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("153f38")
	style.set_corner_radius_all(16)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	_label("Living River", 34)
	match screen:
		"language":
			_label("Choose your language", 22)
			_label("Select a language to begin. You can change it in Settings.")
			_button("English", func(): game.choose_language("en"), true)
			_button("Русский", func(): game.choose_language("ru"), true)
		"menu":
			_label("Relief journeys on a living river.")
			_button("Play", game.play_from_menu)
			_button("Settings", game.open_settings)
			_button("Credits", func(): game.ui_screen = "credits")
			_button("Quit", game.quit_game)
		"settings":
			_label("Settings", 24)
			_label("Language")
			var languages := HBoxContainer.new()
			content.add_child(languages)
			for code in ["en", "ru"]:
				var choice := Button.new()
				choice.text = "English" if code == "en" else "Русский"
				choice.toggle_mode = true
				choice.button_pressed = game.settings.locale == code
				choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				choice.custom_minimum_size.y = 38
				choice.pressed.connect(func(): game.choose_language(code))
				languages.add_child(choice)
				_focus_controls.append(choice)
			for kind in ["master", "music", "effects"]:
				_volume(kind)
			_label("Music can be muted independently. Effects includes the engine.")
			_button("Back", game.close_screen)
		"credits":
			_label("Credits", 24)
			_label("Original procedural art and audio created for Living River.")
			_label("Built with Godot. Font: Godot built-in fallback (see engine third-party licenses).")
			_button("Back", game.close_screen)
		"pause":
			_label("Paused", 24)
			_button("Resume", game.resume_run)
			_button("Settings", game.open_settings)
			_button("End run and return to menu", game.return_to_menu)
	notice_label = _label("")
	notice_label.add_theme_color_override("font_color", Color("ffd49b"))
	for i in _focus_controls.size():
		_focus_controls[i].focus_neighbor_top = _focus_controls[i].get_path_to(_focus_controls[(i - 1 + _focus_controls.size()) % _focus_controls.size()])
		_focus_controls[i].focus_neighbor_bottom = _focus_controls[i].get_path_to(_focus_controls[(i + 1) % _focus_controls.size()])
	if not _focus_controls.is_empty():
		_focus_controls[0].call_deferred("grab_focus")

func _label(source: String, font_size: int = 17) -> Label:
	var label := Label.new()
	label.text = Text.t(source)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f4eed9"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 490
	content.add_child(label)
	return label

func _button(source: String, callback: Callable, autonym: bool = false) -> Button:
	var button := Button.new()
	button.text = source if autonym else Text.t(source)
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	content.add_child(button)
	_focus_controls.append(button)
	return button

func _volume(kind: String) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var label := Label.new()
	label.text = Text.t(kind.capitalize())
	label.custom_minimum_size.x = 165
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = game.settings.get(kind)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	_focus_controls.append(slider)
	var value := Label.new()
	value.custom_minimum_size.x = 52
	value.text = "%d%%" % roundi(slider.value * 100)
	row.add_child(value)
	slider.value_changed.connect(func(level: float):
		game.settings.set_volume(kind, level)
		value.text = "%d%%" % roundi(level * 100))

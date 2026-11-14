extends SceneTree

const Text = preload("res://scripts/localization.gd")
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _initialize() -> void:
	Text.set_locale("en")
	check(Text.t("Play") == "Play", "English is the source language")
	check(Text.t("Unknown message %d", [7]) == "Unknown message 7", "Missing English template formats")
	Text.set_locale("ru")
	check(Text.catalog_errors.is_empty(), "All catalog placeholder signatures are valid: " + str(Text.catalog_errors))
	check(Text.t("Play") == "Играть", "Russian menu translation")
	check(Text.t("Unknown message %d", [7]) == "Unknown message 7", "Missing Russian entry falls back to English")
	check(Text.t("NEXT: %s", ["Koya Landing"]) == "ДАЛЕЕ: Причал Коя", "Nested display names translate without changing IDs")
	check(Text.t("This engine has %d forward gears. 9 selects reverse.", [3]).contains("3"), "Dynamic gear feedback")
	check(Text.t("%s delivered to %s. +%d support saved.", ["Food", "Luma Landing", 60]) == "Продовольствие → Причал Лума. Поддержка сохранена: +60.", "Complete receipt template with typed arguments")
	var profile_source := FileAccess.get_file_as_string("res://scripts/player_profile.gd")
	var expression := RegEx.new()
	expression.compile('load_notice = "([^"\\n]+)"')
	for matched in expression.search_all(profile_source):
		check(Text.has_translation(matched.get_string(1)), "Profile notice missing: " + matched.get_string(1))
	var font := ThemeDB.fallback_font
	for character in "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя":
		check(font.has_char(character.unicode_at(0)), "Fallback font lacks Cyrillic character " + character)
	# Layout metrics exercise the real font, while screenshots remain a separate review gate.
	var manifest := Text.t("%s: %s / %s", ["Koya Landing", "Water filters", "returning"])
	check(font.get_string_size(manifest, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= 400, "Russian manifest fits its header column")
	var controls := Text.t("A D Steer   W Throttle   S / SPACE Brake   1-%d Gears   9 Reverse   Hold E Unload   R Briefing   ESC Pause   ` FPS", [3])
	check(font.get_string_size(controls, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x <= 1200, "Russian controls fit the footer")
	var panel_lines := [
		["Light run / 100 support", 21, 320],
		["Full relief / 160 support", 21, 320],
		["1. Luma / food   2. Koya / filters", 16, 320],
		["Both aboard: -20% acceleration", 15, 320],
		["Choose wide channel or rapids; refuel after the fork.", 17, 720],
		["2 forward gears + reverse / 17-28 km/h", 15, 360],
		["3 forward gears + reverse / 16-34 km/h", 15, 360],
		["18% more fuel use / 100 support credits", 15, 370],
		["Koya's crew can run the filtered-water pump and clinic radio.", 16, 640],
		["FOOD SHELTER", 15, 122],
		["KOYA LANDING", 18, 170],
		["LUMA LANDING", 18, 144]
	]
	for item in panel_lines:
		check(font.get_string_size(Text.t(item[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, item[1]).x <= item[2], "Russian panel line exceeds its width: " + item[0])
	Text.set_locale("invalid")
	check(Text.locale == "en", "Invalid locale falls back to English")
	if failures.is_empty():
		print("PASS localization checks: catalog, formats, fallback, profile notices, Cyrillic and header/footer metrics")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

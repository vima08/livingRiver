extends RefCounted

# English source messages are stable catalog keys. Saved gameplay IDs never change.
static var locale := "en"
static var _catalog: Dictionary = {}
static var _loaded := false
static var catalog_errors: Array[String] = []

static func set_locale(code: String) -> void:
	locale = code if code in ["en", "ru"] else "en"
	_load_catalog()

static func _placeholders(message: String) -> Array[String]:
	var pattern := RegEx.new()
	pattern.compile("%(?:[0-9]+(?:\\.[0-9]+)?)?[sdf]")
	var result: Array[String] = []
	for matched in pattern.search_all(message):
		result.append(matched.get_string())
	return result

static func _load_catalog() -> void:
	if _loaded:
		return
	_loaded = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/translations/ru.json"))
	if not parsed is Dictionary:
		catalog_errors.append("Russian catalog could not be read.")
		return
	for source: String in parsed:
		var translated: Variant = parsed[source]
		if not translated is String or translated.is_empty() or _placeholders(source) != _placeholders(translated):
			catalog_errors.append("Invalid translation: " + source)
			continue
		_catalog[source] = translated

static func t(source: String, values: Array = []) -> String:
	_load_catalog()
	var message: String = _catalog.get(source, source) if locale == "ru" else source
	if values.is_empty():
		return message
	var localized: Array = []
	for value: Variant in values:
		localized.append(t(value) if value is String else value)
	return message % localized

static func has_translation(source: String) -> bool:
	_load_catalog()
	return _catalog.has(source)

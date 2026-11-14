extends RefCounted

const LOAD_NOTICE := "Settings could not be loaded. Safe defaults are active."
const SAVE_NOTICE := "Settings could not be saved. Your choices remain active for this session."
var locale := "en"
var language_chosen := false
var master := 0.8
var music := 0.35
var effects := 0.75
var notice := ""
var _save_path: String
var _persistence: bool

func _init(save_path: String = "user://settings.cfg", persistence: bool = true) -> void:
	_save_path = save_path
	_persistence = persistence

func load_settings() -> void:
	locale = "en"
	language_chosen = false
	master = 0.8
	music = 0.35
	effects = 0.75
	notice = ""
	if not _persistence:
		return
	if not FileAccess.file_exists(_save_path) and FileAccess.file_exists(_save_path + ".bak"):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(_save_path + ".bak"), ProjectSettings.globalize_path(_save_path))
	if not FileAccess.file_exists(_save_path):
		return
	var config := ConfigFile.new()
	if config.load(_save_path) != OK or not _valid(config):
		notice = LOAD_NOTICE
		return
	locale = config.get_value("preferences", "locale")
	language_chosen = config.get_value("preferences", "language_chosen")
	master = float(config.get_value("preferences", "master"))
	music = float(config.get_value("preferences", "music"))
	effects = float(config.get_value("preferences", "effects"))

func _valid(config: ConfigFile) -> bool:
	if config.get_sections().size() != 1 or not config.has_section("preferences"):
		return false
	var keys := config.get_section_keys("preferences")
	if keys.size() != 6:
		return false
	for key in ["version", "locale", "language_chosen", "master", "music", "effects"]:
		if not config.has_section_key("preferences", key):
			return false
	if typeof(config.get_value("preferences", "version")) != TYPE_INT or config.get_value("preferences", "version") != 1:
		return false
	if config.get_value("preferences", "locale") not in ["en", "ru"] or typeof(config.get_value("preferences", "language_chosen")) != TYPE_BOOL:
		return false
	for kind in ["master", "music", "effects"]:
		if not _valid_volume(config.get_value("preferences", kind)):
			return false
	return true

func _valid_volume(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 1.0

func set_locale(code: String) -> bool:
	if code not in ["en", "ru"]:
		return false
	locale = code
	language_chosen = true
	return _save()

func set_volume(kind: String, value: float) -> bool:
	if kind not in ["master", "music", "effects"] or not _valid_volume(value):
		return false
	set(kind, value)
	return _save()

func _save() -> bool:
	notice = ""
	if not _persistence:
		return true
	var config := ConfigFile.new()
	for key in ["locale", "language_chosen", "master", "music", "effects"]:
		config.set_value("preferences", key, get(key))
	config.set_value("preferences", "version", 1)
	if config.save(_save_path + ".tmp") != OK:
		notice = SAVE_NOTICE
		return false
	var path := ProjectSettings.globalize_path(_save_path)
	var backup := path + ".bak"
	if FileAccess.file_exists(_save_path):
		if FileAccess.file_exists(_save_path + ".bak"):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path, backup) != OK:
			notice = SAVE_NOTICE
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		if FileAccess.file_exists(_save_path + ".bak"):
			DirAccess.rename_absolute(backup, path)
		notice = SAVE_NOTICE
		return false
	if FileAccess.file_exists(_save_path + ".bak"):
		DirAccess.remove_absolute(backup)
	return true

extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const Profile = preload("res://scripts/player_profile.gd")
const SAVE := "res://tests/.settings-checks-isolated.cfg"
const PROFILE_SAVE := "res://tests/.settings-profile-isolated.json"
var failures := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func clean() -> void:
	for path in [SAVE, PROFILE_SAVE]:
		for suffix in ["", ".tmp", ".bak"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _initialize() -> void:
	clean()
	var profile := Profile.new(PROFILE_SAVE)
	var mission := profile.begin_mission()
	profile.award_delivery(mission)
	var original_profile := FileAccess.get_file_as_string(PROFILE_SAVE)
	var settings := Settings.new(SAVE)
	settings.load_settings()
	check(settings.locale == "en" and not settings.language_chosen and settings.notice.is_empty(), "Missing settings starts in English with unchosen language")
	check(settings.master == 0.8 and settings.music == 0.35 and settings.effects == 0.75, "Comfortable separate volume defaults")
	check(settings.set_volume("music", 0) and not settings.language_chosen, "Volume change does not mark first language selection")
	check(settings.set_locale("ru") and settings.set_volume("master", 0) and settings.set_volume("effects", 1), "Language and boundary volume values save")
	var reloaded := Settings.new(SAVE)
	reloaded.load_settings()
	check(reloaded.locale == "ru" and reloaded.language_chosen and reloaded.master == 0 and reloaded.music == 0 and reloaded.effects == 1, "Relaunch preserves language and independent mute values")
	check(not settings.set_locale("xx") and not settings.set_volume("wrong", 0.5) and not settings.set_volume("music", -0.1) and not settings.set_volume("music", 1.1) and not settings.set_volume("music", NAN), "Invalid locale, bus, range and non-finite values rejected")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(SAVE + ".bak"))
	reloaded.load_settings()
	check(reloaded.locale == "ru" and reloaded.master == 0, "Interrupted replacement recovers committed settings backup")
	var malformed := ["broken = [", "[preferences]\nversion=1\nlocale=\"ru\"", "[preferences]\nversion=1\nlocale=\"xx\"\nlanguage_chosen=true\nmaster=0.8\nmusic=0.3\neffects=0.7", "[preferences]\nversion=1\nlocale=\"ru\"\nlanguage_chosen=true\nmaster=true\nmusic=0.3\neffects=0.7", "[preferences]\nversion=1\nlocale=\"ru\"\nlanguage_chosen=true\nmaster=0.8\nmusic=2.0\neffects=0.7", "[preferences]\nversion=1\nlocale=\"ru\"\nlanguage_chosen=true\nmaster=0.8\nmusic=0.3\neffects=0.7\nextra=1"]
	for source in malformed:
		var file := FileAccess.open(SAVE, FileAccess.WRITE)
		file.store_string(source)
		file.close()
		reloaded.load_settings()
		check(reloaded.locale == "en" and not reloaded.language_chosen and reloaded.master == 0.8 and not reloaded.notice.is_empty(), "Corrupt or invalid settings fall back atomically with notice")
	var blocked := Settings.new("res://tests/missing-settings-check-directory/settings.cfg")
	check(not blocked.set_locale("ru") and blocked.locale == "ru" and blocked.language_chosen and not blocked.notice.is_empty(), "Failed locale write retains session choice with notice")
	check(not blocked.set_volume("effects", 0) and blocked.effects == 0 and not blocked.notice.is_empty(), "Failed volume write retains immediate session mute with notice")
	var memory := Settings.new("", false)
	check(memory.set_locale("ru") and memory.set_volume("music", 0) and memory.notice.is_empty(), "Explicit memory fixture performs no persistence")
	check(FileAccess.get_file_as_string(PROFILE_SAVE) == original_profile, "Settings operations never modify isolated progression")
	check(settings.set_locale("ru") and settings.set_volume("music", 0), "Preferences saved before progression reset")
	var original_settings := FileAccess.get_file_as_string(SAVE)
	profile.reset_profile()
	check(FileAccess.get_file_as_string(SAVE) == original_settings, "Progression reset does not write settings storage")
	reloaded.load_settings()
	check(reloaded.locale == "ru" and reloaded.music == 0, "Progression reset leaves language and music preference intact")
	clean()
	print("Settings checks: %d failure(s)" % failures)
	quit(failures)

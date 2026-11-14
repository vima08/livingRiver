extends SceneTree

# Independent normal-speed playback evidence. Staged states, not a complete mission.
var game: Node
var elapsed := 0.0
var phase := -1
var recorder: AudioEffectRecord
var failures := 0
var checks: Array[String] = []
var timeline: Array = []
var engine_id := 0
var music_id := 0
var finished := false

func _initialize() -> void:
	call_deferred("setup")

func check(ok: bool, label: String) -> void:
	checks.append(("PASS " if ok else "FAIL ") + label)
	print(checks.back())
	if not ok:
		failures += 1

func setup() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This evidence harness requires graphical audio output")
		quit(2)
		return
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("test_mode", true)
	root.add_child(game)
	game.set_physics_process(false)
	game.ui_screen = "menu"
	engine_id = game.audio.engine_player.get_instance_id()
	music_id = game.audio.music_player.get_instance_id()
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	check(game.audio.output_enabled and game.audio.music_player.playing, "Graphical mixer starts real music playback")
	check(not game.settings._persistence and not game.profile._persistence, "Real main fixture disables settings and progression persistence")

func stage(index: int) -> void:
	var labels := ["cold menu", "running idle", "first gear throttle", "second gear throttle", "braking coast", "reverse throttle", "current drift idle", "pause", "paused settings Effects mute", "resume full cargo", "delivery food cue", "delivery filters cue", "failure", "Music mute", "Master mute", "restored menu", "loop continuation", "engine mute", "restored running"]
	phase = index
	var audio: Node = game.audio
	game.settings.set_volume("master", 0.8)
	game.settings.set_volume("music", 0.35)
	game.settings.set_volume("effects", 0.75)
	game.ui_screen = ""
	game.state = "running"
	game.fuel = 100
	game.engine_throttle = 0
	game.selected_gear = 1
	match index:
		0, 15, 16:
			game.ui_screen = "menu"
			game.state = "ready"
		2:
			game.engine_throttle = 1
			game.select_gear(1)
		3:
			game.engine_throttle = 1
			game.select_gear(2)
		4:
			game.simulate(1.0 / 60.0, Vector2(0, -1), true, false)
		5:
			game.engine_throttle = 1
			game.select_gear(9)
		6:
			game.velocity = Vector2(0, 120)
		7:
			game.state = "paused"
		8:
			game.state = "paused"
			game.ui_screen = "settings"
			game.settings.set_volume("effects", 0)
		9:
			game.manifest.configure("full")
			game.engine_throttle = 1
		10, 11:
			game.play_tone(880, 0.4)
		12:
			game.finish_failure("test failure")
		13:
			game.settings.set_volume("music", 0)
		14:
			game.settings.set_volume("master", 0)
		17:
			game.settings.set_volume("effects", 0)
		18:
			game.engine_throttle = 1
	if index == 3:
		# Four concurrent distinct cues exercise actual busy voices; a fifth is dropped.
		for kind in ["collision", "refuel", "low_fuel", "delivery", "failure"]:
			audio.play_event(kind)
		var playing := 0
		for voice in audio.voices:
			if voice.playing:
				playing += 1
		check(playing == 4, "Actual playback burst fills four bounded event voices")
	check(audio.get_child_count() == 6, "Stage %d retains two loop players and four voices" % index)
	timeline.append({"seconds": elapsed, "stage": labels[index], "engine_playing": audio.engine_player.playing, "music_playing": audio.music_player.playing, "music_position": audio.music_player.get_playback_position()})
	print("AUDIO_RUNTIME_STAGE %d %.2f %s" % [index, elapsed, labels[index]])

func _process(delta: float) -> bool:
	if not is_instance_valid(game) or finished:
		return false
	elapsed += delta
	var next := mini(int(elapsed / 6.0), 18)
	if next != phase:
		if phase >= 0:
			check(game.audio.music_player.playing, "Music remains active through stage %d" % phase)
			check(game.audio.engine_player.get_instance_id() == engine_id and game.audio.music_player.get_instance_id() == music_id, "Stage %d keeps the same loop players" % phase)
		stage(next)
	if elapsed >= 114.0:
		finished = true
		finish()
	return false

func finish() -> void:
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	check(recording != null and recording.get_length() > 110, "Master mixer recording covers more than three 32-second music periods")
	if recording != null:
		var result := recording.save_to_wav("res://doc/evidence/milestone4-runtime-mix-114s.wav")
		check(result == OK, "Actual runtime mixer WAV saved")
	var output := "# Milestone 4 actual audio playback capture\n\nNormal-speed graphical real main scene with persistence disabled before scene insertion. States, engine demand and cue calls are staged directly; this is not a complete mission, physical input test or proof of hearing. A real AudioEffectRecord on Master captures actual Godot mixing. No time scale or global physics changes.\n\n"
	for item in checks:
		output += "- " + item + "\n"
	output += "\nTimeline: " + JSON.stringify(timeline) + "\n\nCapture limitation: AudioEffectRecord on Master taps before Master attenuation/mute; this WAV does not demonstrate hardware-output Master silence.\n\nAudible quality: BLOCKED. This critic cannot hear the recording. Human listening must approve clicks, fatigue, cue clarity and balance. Delivery stages trigger the actual cue integration but do not demonstrate completing deliveries.\n"
	FileAccess.open("res://doc/evidence/milestone4-runtime-audio-results.md", FileAccess.WRITE).store_string(output)
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("AUDIO_RUNTIME failures=%d" % failures)
	quit(1 if failures else 0)

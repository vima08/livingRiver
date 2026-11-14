extends Node

# Assets are rendered offline. Players and voices are created once per game instance.
const ENGINE_ASSET = preload("res://assets/audio/engine.wav")
const MUSIC_ASSET = preload("res://assets/audio/river_theme.wav")
const EVENTS := {
	"collision": preload("res://assets/audio/collision.wav"),
	"refuel": preload("res://assets/audio/refuel.wav"),
	"low_fuel": preload("res://assets/audio/low_fuel.wav"),
	"delivery": preload("res://assets/audio/delivery.wav"),
	"failure": preload("res://assets/audio/failure.wav"),
	"gear": preload("res://assets/audio/gear.wav"),
}
const VOICE_LIMIT := 4
const EVENT_GAPS := {"collision": 0.2, "refuel": 0.5, "low_fuel": 2.0, "delivery": 0.3, "failure": 1.0, "gear": 0.12}
var game: Node
var engine_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var engine_level := 0.0
var engine_pitch := 0.85
var music_level := 0.0
var applied_volumes := Vector3(-1, -1, -1)
var events_played := 0
var output_enabled := DisplayServer.get_name() != "headless"

func looped(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(source.get_length() * source.mix_rate))
	# Godot 4.7's WAV mixer can decode the inclusive loop_end frame before
	# wrapping. Keep the musical period unchanged, but provide that look-ahead
	# frame explicitly instead of allowing a read past the PCM data.
	if source.format == AudioStreamWAV.FORMAT_16_BITS:
		var bytes := source.data
		bytes.append_array(bytes.slice(0, 4 if source.stereo else 2))
		stream.data = bytes
	return stream

func _ready() -> void:
	# Runtime buses preserve project portability without replacing a global bus layout.
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	engine_player = make_player("Effects")
	engine_player.stream = looped(ENGINE_ASSET)
	engine_player.volume_db = -80.0
	if output_enabled:
		engine_player.play()
	music_player = make_player("Music")
	music_player.stream = looped(MUSIC_ASSET)
	music_player.volume_db = -80.0
	if output_enabled:
		music_player.play()
	for i in range(VOICE_LIMIT):
		voices.append(make_player("Effects"))
	update_mix()

func make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player

func update_mix() -> void:
	if not is_instance_valid(game) or game.settings == null:
		return
	var levels := Vector3(clampf(game.settings.master, 0, 1), clampf(game.settings.music, 0, 1), clampf(game.settings.effects, 0, 1))
	if levels == applied_volumes:
		return
	applied_volumes = levels
	var names := ["Master", "Music", "Effects"]
	for i in range(3):
		var bus := AudioServer.get_bus_index(names[i])
		if bus < 0:
			continue
		AudioServer.set_bus_mute(bus, levels[i] <= 0.0)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(levels[i], 0.0001)))

func targets() -> Vector2:
	if not is_instance_valid(game) or game.state != "running" or not game.ui_screen.is_empty() or game.fuel <= 0.0:
		return Vector2(0.0, 0.85)
	var throttle := clampf(game.engine_throttle, 0.0, 1.0)
	var gear := 1.0 if game.selected_gear == 9 else float(game.selected_gear)
	var heavy := 1.0 if game.manifest.full_load() else 0.0
	# Ground speed is deliberately absent: moving water cannot rev an unpowered engine.
	return Vector2(0.22 + throttle * 0.15, 0.85 + throttle * (0.43 + gear * 0.085 - heavy * 0.055))

func _process(delta: float) -> void:
	update_mix()
	for kind in cooldowns:
		cooldowns[kind] = maxf(0.0, cooldowns[kind] - delta)
	var target := targets()
	var blend := 1.0 - exp(-delta * 6.0)
	engine_level = lerpf(engine_level, target.x, blend)
	engine_pitch = lerpf(engine_pitch, target.y, blend)
	engine_player.volume_db = linear_to_db(maxf(engine_level, 0.0001))
	engine_player.pitch_scale = engine_pitch
	# Keep one loop phase through all transitions; fading never creates another player.
	engine_player.stream_paused = target.x == 0.0 and engine_level < 0.0005
	var paused: bool = is_instance_valid(game) and game.state == "paused"
	music_level = lerpf(music_level, 0.23 if paused else 0.35, 1.0 - exp(-delta * 3.0))
	music_player.volume_db = linear_to_db(maxf(music_level, 0.0001))

func play_event(kind: String) -> void:
	if not EVENTS.has(kind) or float(cooldowns.get(kind, 0.0)) > 0.0:
		return
	cooldowns[kind] = EVENT_GAPS[kind]
	# If every voice is busy, drop the new cue rather than allocating or interrupting loops.
	for voice in voices:
		if not voice.playing:
			voice.stream = EVENTS[kind]
			voice.volume_db = -7.0 if kind != "gear" else -10.0
			if output_enabled:
				voice.play()
			events_played += 1
			return

func _exit_tree() -> void:
	for player in voices:
		player.stop()
		player.stream = null
	if is_instance_valid(engine_player):
		engine_player.stop()
		engine_player.stream = null
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null

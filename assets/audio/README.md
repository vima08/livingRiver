# Original Living River prototype audio

All WAV files in this folder were composed and synthesized specifically for this repository by its coding agent on November 15, 2026. No recordings, downloaded music, reference tracks, sound libraries or third-party samples are included. These original generated assets are provided under the repository's own terms; there is no external attribution requirement.

Reproducible source: `tools/generate_audio.gd`. Run Godot with `--headless --path . --script tools/generate_audio.gd`. This offline tool writes 22,050 Hz, mono, signed 16-bit PCM WAV files. Tracked `.wav.import` settings retain uncompressed PCM (`compress/mode=0`), rather than the engine's default QOA compression. Gameplay preloads the resulting assets and never generates waveforms.

- `engine.wav`: two-second periodic, harmonic motor pulse with quiet mechanical partials. Every oscillator completes a whole number of cycles at the loop boundary. Runtime pitch follows throttle, gear and cargo load; current-driven speed does not influence it.
- `river_theme.wav`: original 32-second instrumental bed in D major, with Dmaj9 / Gmaj7 / Bm7 / Asus2 pads, bass and sparse plucked melody. Note tails wrap around the loop rather than being cut off.
- `collision`, `refuel`, `low_fuel`, `delivery`, `failure`, `gear`: short synthesized cues with onset/release envelopes. Four reusable event players and per-kind cooldowns bound concurrency and repetition.

Runtime buses are Master, Music and Effects (engine plus cues). Music's baseline player gain is 0.35 and engine gain is 0.22–0.37; user settings multiply these levels. Independent playback preserves the music/engine phase through events and restarts. At menus, pause, failure, completion and fuel exhaustion, the engine fades to silence; a silent engine pauses its stream until needed again.

Current player controls latch cruise with W and stop the engine with S. The stopped cruise state fades the engine to silence even while current carries the boat; a fresh W press starts drive demand in the selected gear. Automated pilots can still supply explicit demand independently. Music and the loop guard remain unchanged.

The runtime loop copies contain one additional PCM guard frame equal to the first source frame. The loop end remains the original frame count, preserving the engine's two-second and music's 32-second periods. Godot 4.7's WAV mixer can decode the inclusive end frame before wrapping; without the guard this reads past the source PCM and produced sharp transients at exact engine-loop intervals in actual mixer captures. The source assets and composition themselves remain unchanged. `tests/audio_loop_checks.gd` exercises the actual WAV playback mixer across constant and changing pitch, rather than inferring continuity from source endpoints.

`doc/evidence/milestone4-audio-listening-preview-102s.wav` is an offline listening aid, not a recording or evidence of hearing the running game. It includes over three music periods, engine idle/throttle/coast sections, silence representing pause and all six cues. Its levels approximate runtime defaults; Godot pitch interpolation, bus routing, transitions and system output require a separate runtime listening check. No listening approval is inferred from numerical checks.

Listening checklist: cold start; three loop boundaries; idle → first/second gear throttle → brake/coast → reverse; current drift at idle; full load versus food unloaded; pause/settings/resume; both deliveries; failure; all three mute controls and relaunch. Review clicks, fatigue, alert clarity and balance. Human listening remains a release gate.

Headless execution constructs the same players, streams, buses and control state, but deliberately does not start the audio output. Godot 4.7.2 headless Dummy playback retained `AudioStreamPlaybackWAV` references at shutdown even after stopping players and clearing their streams. Buffer and control checks therefore remain useful headlessly; actual playback, voice overlap, output, listening and audio-enabled performance must be verified in a graphical run.

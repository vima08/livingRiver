# Living River workbench

## Latest update — manual controls, FPS counter, and renderer performance

User feedback: poor performance, wake stays at stern during reverse, and preference for manual acceleration instead of automatic cruising. Implemented W/up to accelerate north, S/down to slow then reverse, A/D or left/right to steer. With no throttle the boat coasts to rest. This interprets the user's ambiguous “steer on S” as slowing/reversing; the interpretation was disclosed in the progress update.

- Backtick / grave accent toggles a top-right FPS counter. Hidden on application startup, available in the briefing, running, paused and terminal states. Display preference persists across mission restart.
- Wake is drawn opposite actual velocity, including reverse and lateral travel; no wake at rest.
- Renderer creates 64 original procedural canopy textures once, draws one textured rectangle per visible canopy, and culls offscreen canopies. HUD and renderer reuse rounded style boxes rather than allocating them every draw.
- Boat movement uses independent steering/throttle axes, so steering does not reduce forward throttle. The scripted evidence pilot now supplies forward throttle explicitly.
- On-screen instructions and README match the new controls.

### Verification of the latest update

- `tests/mission_checks.gd`: **20/20 PASS**, including no automatic motion, W acceleration, coasting to rest, and the unchanged complete route of **169.90 seconds** with full hull and 23.2 fuel.
- `tests/critic_regressions.gd`: **15/15 PASS**, also independently rerun by a fresh critic.
- Graphical `tests/input_playback.gd --fixed-fps 30`: **15/15 PASS**, including physical backtick show/hide, Enter without automatic movement, W travel, steering, braking, reverse, collision, docking and restart. Exit 0. Updated screenshots include `input_fps_visible.png` and the existing ordered input frames.
- Renderer builder inspected staged north, reverse, lateral and stationary screenshots `render_canopy_*.png`; the fresh critic independently inspected them and updated input frames.
- Fresh critic: **PASS for the scoped FPS, controls, wake and rendering changes**. Report: [controls-render-review.md](evidence/controls-render-review.md). Human enjoyment and sustained route-wide FPS are not certified.
- Graphical launch succeeds on NVIDIA MX150 / OpenGL Compatibility. The pre-existing sandbox certificate-store warning remains; no script/resource errors observed.

### Performance comparison

`tests/render_benchmark.gd` disables VSync and the FPS cap, warms up 30 frames and measures 180 rendered frames while scrolling the same river region. The old renderer is loaded from a local ignored snapshot of the original `HEAD:scripts/river_view.gd` with its class name removed. It uses the same current game/HUD. Baseline mode requires that snapshot at `tmp/river_view_baseline.gd`; ordinary benchmark mode tests the current renderer.

| Renderer | Measured FPS | Mean draw calls per frame |
|---|---:|---:|
| Original procedural geometry | 6.6 | 4,340.3 |
| Cached canopy textures, first sample | 56.5 | 600.7 |
| Cached canopy textures, confirmation | 50.4 | 601.7 |

These are short local uncapped measurements, not a sustained-performance guarantee. They show roughly an eightfold frame-rate improvement and an 86% reduction in draw calls in this scene. An initial baseline attempt accidentally captured the already-updated renderer due to overlapping file edits; that 64.2 FPS result was discarded and the original source was retrieved from Git before measuring the valid baseline above.

Commands: `--path . --script tests/render_benchmark.gd -- --baseline` and `--path . --script tests/render_benchmark.gd`. Local reports are under `tmp/benchmark_*.txt`; screenshots are `doc/evidence/performance_baseline.png` and `performance_cached.png`. Review media remains ignored according to the user's existing `evidence/` rule. The earlier `handling.avi` is historical evidence for the original controls; it was not regenerated for this update. Current screenshots, input checks, and scoped critic review supersede it for the revised controls.

## Active milestone

First playable three-minute humanitarian delivery run. Implementation started November 14, 2026. Acceptance criteria: [firstSteps.md](firstSteps.md). Reference: [conceptArt.jpg](conceptArt.jpg).

## Build 1 — integrated playable prototype

- Root builder: gameplay, mission state, controls, HUD, focused simulation checks.
- Separate visual builder: original procedural river, foliage, boat, hazards, and village.
- Toolchain: verified Godot 4.7.2, GDScript, Compatibility renderer, 1280 × 720.
- Planned evidence: import and launch output, automated scenario results, graphical captures, independent functional and visual reviews.
- Status: **playable build implemented; independent functional PASS and visual-readability PASS**. Graphical input playback passes 11/11 checks. Complete milestone acceptance remains open for human handling review.
- Actual route result: **169.90 simulated seconds**, full hull, 23.2 fuel, midpoint buoy collected. Scripted navigation through the real simulation, not a human playthrough.

## Artifacts

- `project.godot` / `scenes/main.tscn`: Godot project and entry scene.
- `scripts/main.gd`: controls, movement, capsule collisions, authored route, mission and resource state, optional evidence pilot.
- `scripts/river_view.gd`: original procedural jade river, jungle, rocks, boat, village, collision pulse, pump and radio beacon.
- `scripts/hud.gd`: briefing, resource bars, navigation guidance, docking instructions, unloading progress, pause and outcomes.
- `tests/mission_checks.gd`: complete route and mission-state checks.
- `tests/critic_regressions.gd`: independently authored adversarial checks.
- `tests/input_playback.gd`: physical-key event playback through the running engine and graphical evidence capture.
- `README.md`: launch instructions, controls and check commands.

## Gauntlet rounds

1. Builder's first route experiment failed at 102.75 seconds: the evidence pilot assumed center water was always safe and hit protruding rocks. Updated the pilot to steer around actual rock positions; the full route then passed in 169.90 seconds. Normal gameplay never runs this pilot.
2. Independent functional critic returned REWORK: overshooting the dock was unrecoverable because the boat could only move north; the original circular boat collider omitted its bow. Added S/down reverse, updated controls, and replaced the circle with a tilted capsule. Critic independently verified dock overshoot recovery, bow impact, restart input and terminal freezing, then returned scoped functional PASS.
3. Independent visual critic passed graybox readability but marked complete approval BLOCKED on missing motion evidence. Also identified the promised but absent radio beacon. Added a visible radio mast/beacon, wider village clearing, and collision pulse. Created normal-speed graphical keyboard playback and ordered scenario captures. Revised critic verdict is PASS for visible graybox criteria, explicitly excluding human handling enjoyment and video playback.
4. First keyboard playback exposed an overly strict test expectation: reversing lateral inertia from +205 to below -100 was expected in 1.16 seconds despite acceleration of 210 units/s². The actual required behavior is reversal into leftward travel, so the assertion now checks negative velocity and reports the value. Regenerated recording and report pass all 11 checks, including measured leftward velocity of -40.0.

## Checks actually performed

Using the console executable documented in `AGENTS.md`:

```powershell
$env:APPDATA = Join-Path $PWD 'tmp/appdata'
$env:LOCALAPPDATA = Join-Path $PWD 'tmp/localappdata'
& $godotExe --headless --path . --editor --import --log-file 'C:/Users/PC/Desktop/gitProjects/livingRiver/tmp/import.log'
& $godotExe --headless --path . --quit-after 120 --log-file 'C:/Users/PC/Desktop/gitProjects/livingRiver/tmp/smoke.log'
& $godotExe --headless --path . --script tests/mission_checks.gd
& $godotExe --headless --path . --script tests/critic_regressions.gd
& $godotExe --path . --script tests/input_playback.gd --fixed-fps 30 --write-movie doc/evidence/handling.avi
```

Create those temporary directories before using the sandbox environment override. It is needed only because this session cannot write Godot editor/user data to the normal Windows profile. All temporary data is ignored. `doc/.gdignore` keeps documentation and review media out of game imports.

- Import and headless smoke run: exit 0; no script or missing-resource errors.
- Full mission checks: 17/17 passed.
- Critic regression checks: 15/15 passed independently.
- Final root rerun of the independent regressions after renderer revisions: 15/15 passed, exit 0.
- Final graphical keyboard playback: 11/11 passed, exit 0; 17.67-second AVI finalized, all ordered screenshots inspected by the visual critic.
- Graphical run: launched successfully on NVIDIA MX150, OpenGL Compatibility renderer. Accelerated route reached delivery success and saved screenshots.
- Graphical keyboard playback: real engine input dispatch, first eight seconds at the normal starting position. Later collision, docking and failures use explicit staged setup. Recording is 530 frames / 30 fps (17.67 seconds), encoded slower than real time by Movie Maker. Staged elapsed time is not full-route timing.
- Known environment output: Godot reports `Failed to read the root certificate store` in this sandbox. The game uses no network connections; imports and game checks complete. This is recorded rather than presented as a clean platform log.

## Evidence and independent reports

- [Mission checks](evidence/mission-checks.md)
- [Functional critic report](evidence/functional-review.md)
- [Visual critic report](evidence/visual-review.md)
- [Graphical input checks](evidence/input-checks.md)
- [Normal-speed control and outcome recording](evidence/handling.avi)
- `evidence/demo_00.png`–`demo_04.png`: accelerated full-route snapshots from the earlier integrated build.
- `evidence/input_00_briefing.png`–`input_11_hull_failure.png`: updated normal-speed input scenarios; include turn reversal, brake, reverse, collision, docking, success, restart, and both failures.

## Remaining verification

The automated route and recorded keyboard playback establish working controls, traversability, timing, docking and outcomes. They do not establish whether a new human player enjoys steering or completes the route on a first attempt. Human playtesting and target-device performance testing remain limitations. Keep final milestone approval separate from the scoped functional/visual evidence until independent review is complete.

Next meaningful review: a human keyboard playthrough of the unmodified full route, including a deliberately missed dock and recovery using S/down. Reviewers inspected the rendered scenario frames but did not play the AVI, hear audio, or perform that human run. These limits are preserved rather than treating independent scoped passes as complete approval. The playable project and reproducible evidence are ready for this review.

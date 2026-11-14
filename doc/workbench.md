# Living River workbench

## Milestone 2 — complete, integrated review PASS

Implemented [secondSteps.md](secondSteps.md): readable currents, one safe/rapids fork, and a complete delivery-support / engine-purchase / replay loop. **Final independent integrated verdict: PASS**, with the performance and evidence qualifications below. The first milestone remains accepted. The user completed the requested second-milestone playtest and reported: “everithing is clear, bought 2nd boat and done new run. streams are clear with arrows”. This supports clear controls/current information and an actual purchase/replay. The current product sells an engine upgrade, not a second hull; no human completion time, branch choice or sustained-FPS measurement is inferred.

### Implemented build

- `scripts/main.gd`: one ground-velocity integration model with smooth bounded currents; a wide, opposing-current channel and narrower assisting rapids around a collidable island; still water at dock; explicit between-run depot integration and support rewards.
- `scripts/river_view.gd`: exact shared island cross-sections, animated directional marks and rapid chevrons, cached original glyph textures, cached foliage and offscreen culling.
- `scripts/boat_engine.gd`: validated finite, increasing speed curves, matching acceleration curves, reverse parameters, 1–8 forward gears, engine ID and fuel multiplier.
- `resources/engines/river_triple.tres`: three forward gears (90/155/190), softer top-gear acceleration and 18% higher matched-input fuel consumption. Starter remains fully viable.
- `scripts/player_profile.gd`: versioned local profile, atomic replacement/recovery, credits, ownership and equipped engine; mission IDs prevent repeat rewards. Transaction failures roll back and display notices. Invalid/missing data falls back to the starter profile.
- `scripts/hud.gd`: depot opened with B between runs; actual Buy/Equip/Launch buttons; engine comparisons; two-click progression reset separate from R; support balance and delivery reward; flow and route-choice prompts.
- R resets run state while preserving credits, ownership and equipment. Purchase/equip callbacks refuse changes during active play. Resetting progression clears the prior mission's ability to grant another reward.
- Test scenes set `test_mode` before tree entry so simulation and graphical checks use isolated in-memory progression. Disk-persistence suites use isolated workspace files and exercise actual reloads, leaving the player's profile alone.

### Measured complete scripted runs

| Engine | Channel | Simulated time | Hull | Fuel left |
|---|---|---:|---:|---:|
| River Twin | Wide / safe | 178.02 s | 100 | 16.6 |
| River Twin | Rapids | 167.57 s | 100 | 23.7 |
| River Triple | Rapids, gear 3 | 137.58 s | 100 | 22.5 |

Both starter branches finish with the same cargo and destination. The assisting rapids save 10.45 seconds and approximately 7.1 fuel but offer less lateral clearance and bank rocks; the wide channel avoids those hazards. The upgrade changes actual travel time; matched gear/throttle/time consumes 18% more fuel. Scripts establish viability, not human comfort or first-try completion.

### Final checks and review rounds

- `tests/river_checks.gd`: 24/24 PASS (flow direction, single integration, speedometer drift, freeze, smooth boundaries, delta comparison, island contacts, both starter routes, upgraded route, fuel trade-off).
- `tests/profile_checks.gd`: 34/34 PASS, independently rerun, including corrupt saves, reload, duplicate rewards, insufficient funds, repeated purchase, invalid engines and transaction rollback.
- `tests/profile_adversarial.gd`: 18/18 independent PASS; actual button callbacks, staged delivery repeated, mid-run guards, reset boundaries and measured engine differences.
- `tests/river_adversarial.gd`: 30/30 independent PASS; invalid engine data, all stopped states, boundaries, step sizes, reverse escape, poor approaches, speed and restart.
- Reviewer found a briefing regression: starting a run reset a preselected gear. Fixed by preserving valid briefing gear when applying the equipped engine. Updated old test-only engine injection to acquire/equip through the actual depot API. Starter gearbox suite passes 19/19 after the fix.
- Initial integrated HUD import exposed one inferred-Variant type error. Added explicit String annotation and reran headless smoke; no script or resource errors remain. Tests that ran despite the failed HUD dependency were discarded as integrated-build evidence.
- Refreshed prior suites: mission 20/20 PASS, original critic regressions 15/15 PASS, starter gearbox 19/19 PASS. Editor import and headless smoke complete without script/resource errors.
- Physical-key graphical playback: 19/19 PASS, including briefing-selected gear, unavailable 3, native Escape pause, reverse, first-gear docking, terminal outcomes and restart.
- Full graphical sequence: 11/11 PASS, three complete accelerated routes and real mouse Buy/Equip/Launch interactions. No route teleports within these runs. Report: [milestone2_graphical.md](evidence/milestone2_graphical.md).
- Normal-speed staged motion: 1/1 recovery check PASS, 360 frames at 30 fps / 12 seconds. Includes opposing flow, assisting rapids, reverse wake, braking and unloading. [Motion report](evidence/milestone2_motion.md), [recording](evidence/milestone2_motion.avi). Later example positions are explicitly staged; this is not a full route. The integration critic independently reran graphical recovery and inspected actual current/dock frames.
- Unique asserted checks across the retained suites: 191 passed. This count excludes repeated independent reruns and benchmarks.
- Scope reviews: [profile-independent-review.md](evidence/profile-independent-review.md) PASS for economy/profile plus recorded graphical UI/replay; [river-independent-review.md](evidence/river-independent-review.md) PASS for gear/current/fork gates after refreshed physical inputs and user feedback.
- Final fresh integration review: [milestone2-integration-review.md](evidence/milestone2-integration-review.md), **PASS with documented variable fork performance**. The critic inspected actual code/pixels and independently reran river/profile adversarial and core tests plus normal-speed graphical recovery. No integrated gameplay defect remains evidenced.

### Performance investigation

Pre-change local cached benchmark: root 61.6 FPS / 608.7 mean draw calls; visual builder 61.0 FPS / 608.8. Initial per-frame arrow primitives produced variable fork regressions above the plan's 10% investigation threshold. Investigated and replaced them with two cached original glyph textures. Paired post-cache builder samples were current 55.7 FPS / 612.8 draws versus preceding renderer 45.4 FPS / 592.6, and current 45.6 FPS / 613.2 versus preceding renderer 40.3 FPS / 591.6.

Final root pair in the original region: preceding renderer 52.9 FPS / 606.2 draws, current 50.1 FPS / 607.6 draws (about 5.6% more frame time). Final fork pair: preceding renderer 45.9 FPS / 595.1 draws, current 36.5 FPS / 616.4 draws (about 25.8% more frame time). A separate final current-only sample was 51.7 FPS / 607.7 draws. These contradictory short samples show substantial scene/system variance; **the slower fork sample is retained as a performance limitation, not hidden or certified resolved**. Investigation is complete for this milestone; sustained target-device FPS is not guaranteed. The integration critic accepted this qualification under the plan's investigation requirement. Full graphical routes display the FPS overlay, but accelerated simulation and fixed-fps evidence do not establish real-time sustained performance. Future river effects must be compared against these same-region samples before expansion.

`tests/render_benchmark.gd -- --precurrent` compares against the ignored preceding renderer snapshot; `--fork` samples the fork region. The snapshot is a local comparison artifact, not a required game dependency. Measurements use the same current gameplay/HUD and viewport while substituting only the renderer.

### Commands and limitations

Console engine and sandbox APPDATA overrides remain documented below. Latest commands include `--script tests/river_checks.gd`, `tests/profile_checks.gd`, `tests/profile_adversarial.gd`, `tests/river_adversarial.gd`, and graphical `--script tests/milestone2_graphical.gd --fixed-fps 30`. Screenshots/reports live under ignored `doc/evidence/`; descriptive test harnesses are retained in the repository. Godot's existing sandbox certificate-store warning is recorded; it is not a script/resource error and the game uses no network services.

All planned gates have evidence and the final integrated review passes. Remaining limitations: reviewers inspected selected motion frames and harness/logs rather than uninterrupted AVI playback; automated full routes use analog scripted steering and acceleration; user feedback is qualitative and does not identify branch or timing; sustained FPS varies by region/device. Godot's staged graphical-motion harness also reports two ObjectDB instances leaked at shutdown; this did not prevent recording or exit 0 and was reproduced by the integration critic. It is recorded as a harness shutdown warning, not asserted absent from every future game run. No GDScript/resource/runtime gameplay error was observed in final checks.

## Historical status — first step accepted; second-step foundation and plan

At this earlier stage, the user accepted the first playable milestone and [secondSteps.md](secondSteps.md) was prepared. The foundation and measurements below are historical; the completed second-milestone build and current verdict are recorded above. [conceptEn.md](conceptEn.md) separates confirmed direction from optional later proposals.

### Implemented foundation — speedometer and starter gearbox

- Actual ground-speed HUD in km/h, selected gear, engine name and gear count.
- Starter River Twin engine: two forward gears (95 and 155 world units/s) plus reverse (100). Starts in first; select second for the main delivery run.
- Confirmed controls: number-row or keypad **1/2** select forward gears, **9** reverse; **W/up** applies throttle, **S/down** or Space brakes, A/D or left/right steers. Keys 3–8 report unavailable gears on this engine. Releasing throttle coasts to rest.
- Direction changes require speed below 45 world units/s (about 8 km/h); forward-to-forward shifts remain available while moving. Invalid selection and unsafe changes preserve the current gear and show feedback.
- `scripts/boat_engine.gd` and `resources/engines/river_twin.tres` define the starter without engine-specific movement code. A test-only three-gear Resource proves additional gears; no purchase/profile UI or unlocked upgraded engine is claimed.
- World scale is now documented as **0.05 meters per world unit**. Speed uses actual velocity magnitude, including lateral travel. Route distance was corrected from unscaled 26 km to **1.3 km**, preserving geometry and approximately three-minute timing.
- Independent critic identified phantom speed at the route's longitudinal clamps. Clamping now clears blocked longitudinal velocity, so stationary boundary contact reports zero, stops the wake and permits gear recovery. Added start/far-boundary regressions.
- README, briefing, pause screen, footer and agent instructions describe the new controls. Historical notes below retain previous implementation rounds.

### Latest checks and review

- Starter gearbox suite: **19/19 PASS**, including both boundary stops and direction recovery; fresh critic independently reran all 19 checks.
- Mission suite: **20/20 PASS** after boundary correction; complete run remains 169.90 simulated seconds in second gear, hull100/fuel23.2.
- Critic regression suite: **15/15 PASS** with updated explicit brake / 9 / W recovery controls.
- Graphical key playback: **16/16 PASS**, exit 0. Current input frames show readable speed/gear panel, correct 1.3 km briefing, gear2 travel and gearR reverse. The visual test stages later scenarios explicitly and does not measure a full route.
- Fresh critic verdict **PASS for starter gears, speedometer and second-step planning**, recorded at `doc/evidence/gears-plan-review.md`. Initial REWORK for the boundary mismatch is preserved with the fix and independent recheck. Graphical captures were inspected at 1280 × 720.
- Known sandbox certificate-store warning persists. Human enjoyment and long-run performance of future milestone systems are not inferred from these checks.

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

## Historical first-milestone implementation

First playable three-minute humanitarian delivery run. Implementation started November 14, 2026. Acceptance criteria: [firstSteps.md](firstSteps.md). Reference: [conceptArt.jpg](conceptArt.jpg).

## Build 1 — integrated playable prototype

- Root builder: gameplay, mission state, controls, HUD, focused simulation checks.
- Separate visual builder: original procedural river, foliage, boat, hazards, and village.
- Toolchain: verified Godot 4.7.2, GDScript, Compatibility renderer, 1280 × 720.
- Planned evidence: import and launch output, automated scenario results, graphical captures, independent functional and visual reviews.
- Status: **accepted by the user as complete** after independent functional and visual-readability passes and subsequent control/performance refinements. The following evidence describes the original build; latest behavior and checks are recorded above.
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

## Historical verification limits

The automated route and recorded keyboard playback establish working controls, traversability, timing, docking and outcomes. They do not establish whether a new human player enjoys steering or completes the route on a first attempt. Human playtesting and target-device performance testing remain limitations. Keep final milestone approval separate from the scoped functional/visual evidence until independent review is complete.

The user subsequently accepted the first playable step and approved planning the second. Historical reviewers inspected rendered scenario frames but did not play the AVI, hear audio, or perform a human run. Preserve those evidence limits while treating the first step as accepted. Current missed-dock recovery uses S to brake, 9 to select reverse, then W to move south; the earlier S-only reverse controls were superseded.

# Living River workbench

## November 15 — investigate reported FPS drops

User reports occasional drops to 30 FPS in actual play. Prior variable renderer benchmarks did not establish acceptable sustained play performance; this report reopens performance work. Root optimized the largest costs found by a separate probe agent; a fresh independent critic reviewed actual motion and a complete real-time route. Preserve gameplay, profile data, current arrows, wake direction and visual readability. Final scoped [performance-fix review](evidence/performance-fix-review.md): **PASS with retained frame-time spikes**. Third-milestone human handling acceptance remains pending; this scoped pass does not certify the user's next run or perfectly stable 60 FPS.

User clarified drops occur throughout the river run. Fork ablations against a frozen exact pre-fix working renderer: baseline 24.044 ms / 609.4 draws; water off 16.039 ms / 345.4 draws; palms off 15.271 ms / 449.3 draws; canopy off 18.341 ms / 498.5 draws (180 measured frames each). These diagnostic removals locate cost; no scenery is removed in the product. Sequential timings have system variance and do not add linearly.

Implemented in `scripts/river_view.gd`: batch the same animated water stroke/glint points into two antialiased multiline submissions using reusable buffers; rasterize the original seven palm fronds once at startup and rotate the cached image at each existing crown. Keep trunks, palette, frond variation, current arrows, wake, geometry, collisions and physics. First 600-frame fork comparison: baseline 47.46 FPS / 21.072 ms mean / 27.083 ms p95 / 609.5 draws; optimized 83.65 FPS / 11.954 ms mean / 18.182 ms p95 / 221.7 draws. Mean frame time improves 43.3%, p95 32.9%, draw calls 63.6%. Other regions and a real-time run also passed below; no sustained-60-FPS claim.

### Same-path before/after results

[Probe report](evidence/performance-probe.md) retains all 12 sequential graphical runs, exact frozen working-tree baseline/hash, source snapshot, logs and reproduction. Godot 4.7.2 Compatibility, NVIDIA MX150, 1280×720; uncapped renderer sweeps use 31 warmup + 600 measured frames per long sample and identical frame-index coordinates/animation. Physics is disabled in these comparisons. Prior slow readings are retained in the historical sections below.

| Region | FPS before → after | Mean frame before → after | p95 before → after | Draws before → after |
|---|---:|---:|---:|---:|
| Original river | 46.05 → 80.80 | 21.718 → 12.376 ms | 27.853 → 16.194 ms | 616.4 → 228.8 |
| Fork | 47.46 → 83.65 | 21.072 → 11.954 ms | 27.083 → 18.182 ms | 609.5 → 221.7 |
| Luma | 42.30 → 60.36 | 23.641 → 16.566 ms | 33.333 → 21.667 ms | 632.1 → 245.5 |
| Koya | 43.87 → 76.00 | 22.795 → 13.158 ms | 33.333 → 20.390 ms | 636.2 → 249.6 |

All four regions improve mean frame time by 29.9–43.3% and p95 by 32.9–41.9%, removing approximately 387 draw calls per frame without removing visible layers. Luma's 21.667 ms p95 remains above the 16.667 ms budget for uniform 60 FPS; these samples do not certify a locked frame rate. No OS/GPU-specific exclusive timing or thermal stability claim. Candidate images still show the expected cached-raster versus vector antialiasing differences at palm edges; shape/colors/veins are preserved.

Fresh independent critic inspected actual before/after pixels for all four regions and passed 16/16 normal-speed physical-key/actual-button scenarios through both docks and replay. The complete real-time Full/Wide/Twin run used default VSync/window settings, unchanged 60 Hz physics and time scale 1, one real simulation step per physics tick, an isolated profile and no route staging. It passed in 181.185 wall-clock / 180.833 simulated seconds, with 10,850 physics steps, hull 100, fuel 14.628 and both deliveries / 160 support. This separates runtime performance from the uncapped renderer diagnostic.

### Actual real-time frame intervals

| Region | Mean FPS | p95 frame time | Maximum frame time | Frames above 33.333 ms |
|---|---:|---:|---:|---:|
| Overall, 10,739 frames | 59.27 | 18.815 ms | 328.600 ms | 0.10% |
| Original river | 59.73 | 17.799 ms | 189.927 ms | 0.10% |
| Fork | 58.49 | 20.326 ms | 328.600 ms | 0.05% |
| Luma | 58.20 | 20.940 ms | 200.413 ms | 0.24% |
| Koya | 59.50 | 17.393 ms | 219.841 ms | 0.16% |

No tails were discarded after the initial 30-frame warmup. Rare long stalls remain; first-entry PNG readback/saving is included and may contribute to maxima, but their cause is not established. Other Godot processes were present: root observed two Living River DEBUG windows during the one intentional runtime test. Our diagnostic launches were sequential; total background game/editor/OS load was not controlled. Unknown processes were not closed. No matching pre-fix real-time route was captured, so the full-run average is not presented as a before/after pair. The uncapped four-region comparisons independently establish the renderer improvement; their timings must not be directly compared with this VSync-enabled run.

Reusable source harnesses: `tests/performance_probe.gd` (ablation/current renderer, validates modes and normalizes Windows source line endings), `tests/performance_route.gd` (normal-speed complete route with per-region frame statistics). Frozen baseline is archived in local ignored evidence. Actual runtime report/log: `tmp/performance-fix-runtime.md` and `.log`; retained metrics and commands also appear in the independent review. Reproduce the complete run with the verified executable:

```powershell
& $godotExe --path . --script tests/performance_route.gd --log-file "$PWD/tmp/performance-fix-runtime.log"
```

Use isolated APPDATA/LOCALAPPDATA as in the probe report; do not add `--fixed-fps`, `--write-movie` or `--demo`. Editor import and 120-frame headless smoke were also refreshed after the change. The known certificate-store warning remains environmental; no script/resource errors or shutdown leaks occurred in the reviewed graphical runs. Next action: restart the game to load the renderer changes and check actual user feedback before certifying their throughout-route drops resolved.

## Milestone 3 — implemented, human acceptance pending

Implemented [thirdSteps.md](thirdSteps.md). Work split: root builder owns order state, cargo handling and integration; separate builder owns version-1 migration and bounded per-order receipts; separate visual builder owns load selection, manifest/results UI and the second village. Fresh independent critics inspected persistence, gameplay, actual graphical motion/UI and performance. No complete third-milestone pass claimed: required human load-choice/handling feedback is pending.

Final fresh [integration review](evidence/integration-review3.md): **BLOCKED solely on required human feedback**. Automated technical scopes pass and no remaining concrete implementation defect was observed after the notice fix. The integration critic inspected temporal captures and input/state traces, not continuous AVI playback; neither this nor scripted steering establishes human handling comfort. The unchecked meaningful-load-choice and human-playtest gates remain open.

Baseline before edits: the existing mission suite passed 20/20, starter wide-channel run 178.02 seconds, hull 100 / fuel 16.6. Initial short graphical sample: 46.7 FPS / 605.3 draws over 180 frames, 3.85 seconds. Longer paired comparisons are recorded below. A short sample does not establish sustained performance. Existing fork performance variation and historical harness shutdown warnings remain visible limitations. New tests use isolated profiles and preserve player data.

### Implemented artifacts and actual checks

- `relief_manifest.gd` separates fixed matching orders from run outcome. `main.gd` adds Luma after the buoy, validates/locks cargo, applies smooth weight-dependent acceleration/braking, and commits support before removing cargo. Full, partial and failed outcomes retain committed rewards; R returns to cargo selection.
- `player_profile.gd` uses version 2 with at most two receipts for the latest issued run. Valid version 1 data migrates preserving credits, ownership, equipment and mission-counter safety. Failed reward writes retain cargo and allow safe E retry.
- `hud.gd` adds actual load-card/launch buttons, two-item manifest, next destination, weight and matching unload prompts, missed-Luma warning and itemized outcomes. `river_view.gd` adds an original procedural Luma food shelter/team/crates; Koya pump/radio now follow the filter order. Completed food disappears from the boat and appears in the shelter.
- Delivery checks 35/35 PASS, including launch rejection for capacity, duplicate orders and non-finite reward, plus the notice regression below. Weight measurement: after equal 0.333-second gear 2 throttle, light 70.0 versus full 56.0 units/s; braking from 155 gives 29.52 versus 34.95 units stopping distance (18.4% farther). Food removal does not rescale velocity or position.
- Independent persistence [review](evidence/save-review3.md): scoped **PASS**, 35 profile + 119 order-profile + 12 actual-scene adversarial checks, all exit 0. Real obstructed temporary paths exercise rollback/retry. Backup recovery and valid-v1 migration tested. Sudden hardware power loss and concurrent game processes are not certified.
- Independent gameplay [review](evidence/delivery-review3.md): functional scoped **PASS**, 12 adversarial checks independently passed and root reran them. Physical lateral/combined velocity docking threshold, paused dwell, stop-switch dwell reset, R briefing, lightening without jumps and depot guards covered. Integrated acceptance remains pending graphical motion and human feedback.
- Refreshed baseline regression checks: critic 15/15, profile adversarial 18/18, gearbox 19/19, river adversarial 30/30 PASS. Updated old restart/depot assertions for the intentional briefing transition rather than weakening gameplay behavior.
- Visual builder imported successfully, inspected six staged `step3_staged_*.png` captures and exercised actual mouse Light/Full/Cast off plus physical R through engine input. Root inspected actual Luma and full-result pixels. These are staged scenarios, not route or human handling evidence.
- Fresh visual and integration critics found an actual feedback defect in normal-speed motion: held E overwrote Luma's receipt with a generic no-matching notice, which persisted into Koya's approach despite filters aboard. Fixed by keeping completed-stop confirmation and clearing stop-specific notices on stop change/departure. Added two passing regression assertions; integration critic independently ran five further passing actual-scene checks and inspected corrected Koya pixels. The first motion attempt also stopped just outside Koya's 95-unit circle due to staged approach setup; the harness start offset was corrected from 210 to 195 units. This setup failure was not treated as a game-physics defect or a passing delivery.
- Final editor import and 120-frame headless smoke exited 0 with no script/resource errors. Environment emitted the known certificate-store warning. Import/smoke are not graphical or human-play acceptance.
- Fresh [visual/motion review](evidence/visual-review3.md): scoped **PASS**, 16/16 normal-speed physical-key/actual-button checks and 2/2 complete graphical route assertions. Actual UI covers both load cards, Enter, weight comparison, no matching filters at Luma, both approaches/unloads, next destination, pause, R briefing, depot B, actual Plan next run click and Enter replay, and failure after food. Full, partial and failed result pixels were inspected; aid and support agree. Root also inspected corrected Koya approach and failed-after-food pixels.
- Final original physical-input playback: 19/19 PASS, exit 0. FPS toggle, unavailable gear, reverse, steering, braking, collision, docking, R briefing and both failure states preserved. No ObjectDB shutdown warnings in this run or the new graphical harnesses. Historical milestone-2 motion warnings were not reproduced by these new runs; their exact old cause remains unestablished.

### Graphical media and reproduction

Normal-speed [movie](evidence/step3_motion.avi) / [checks](evidence/step3_critic_motion.md): controlled physical-input scenarios, with positions staged at the start of each named example. Equal-duration acceleration measured full 67.2 versus light 84.0 units/s; food removal restores light handling. These are not a continuous human or full-route run. Separate accelerated [complete route movie](evidence/step3_route.avi) / [checks](evidence/step3_critic_route.md): starter Full/Wide, 24 fixed 1/60-second simulation steps per rendered frame, no position/resource staging within the route; 180.83 seconds, hull 100, fuel 14.63, support 160. The critic fixed a deferred-capture/teardown race in its harness and regenerated the final terminal frame; obsolete failed-attempt evidence is not the final verdict.

```powershell
$env:APPDATA = Join-Path $PWD 'tmp/appdata'
$env:LOCALAPPDATA = Join-Path $PWD 'tmp/localappdata'
$godotExe = 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path . --editor --import --log-file "$PWD/tmp/final_import3.log"
& $godotExe --headless --path . --script tests/delivery_checks.gd --log-file "$PWD/tmp/delivery_notice_fix3.log"
& $godotExe --path . --script tests/milestone3_graphical.gd --fixed-fps 30 --write-movie doc/evidence/step3_motion.avi -- --motion
& $godotExe --path . --script tests/milestone3_graphical.gd --fixed-fps 30 --write-movie doc/evidence/step3_route.avi
& $godotExe --path . --script tests/input_playback.gd --fixed-fps 30 --log-file "$PWD/tmp/input-playback3-final.log"
```

Persistence and adversarial suites are listed in README; scoped reports retain exact independent commands. Performance reproduction requires its pinned local renderer snapshot; see the performance report below. Do not run graphical benchmark/movie processes concurrently. All harnesses isolate progression; normal editor play retains the player's real profile.

### Complete scripted routes

`tests/delivery_checks.gd`: fixed 1/60-second real simulation, isolated in-memory profile; no position/resource staging within these full routes. Both engines and both starter channels succeed. Fuel balance and the 38-unit refuel buoy are unchanged.

| Load | Channel | Engine | Seconds | Hull | Fuel left | Support |
|---|---|---|---:|---:|---:|---:|
| Light | Wide | River Twin | 178.02 | 100 | 16.7 | 100 |
| Light | Rapids | River Twin | 167.57 | 100 | 23.7 | 100 |
| Full | Wide | River Twin | 180.83 | 100 | 14.6 | 160 |
| Full | Rapids | River Twin | 170.37 | 100 | 21.7 | 160 |
| Full | Rapids | River Triple | 140.72 | 84.5 | 19.9 | 160 |

The full starter pilot adds only 2.8 seconds, below the provisional 3:10–3:20 target; fuel viability takes priority and duration was not artificially extended. Pilot steering is analog and anticipatory, so the table does not establish novice comfort or a meaningful human cargo trade-off. The upgraded pilot suffers 15.5 hull damage; it proves completion, not a clean passage.

### Longer performance comparison

Independent [performance report](evidence/performance3.md): scoped **PASS** for measurement/investigation. Ten sequential graphical runs used Godot 4.7.2 Compatibility, NVIDIA MX150, 1280×720, uncapped FPS, 31 warmup + 600 measured frames each (12.5–19.7 seconds), deterministic same-coordinate sweeps. Snapshot renderer is pinned to milestone-2 commit `1d156063602e6b1a8b9276f55e3187c6e4d72d71`; gameplay/HUD remain identical in each pair. These are renderer comparisons, not complete historical-build or gameplay-physics benchmarks.

| Region | Current mean frame | Milestone-2 renderer | Additional frame time |
|---|---:|---:|---:|
| Original | 27.688 ms | 32.780 ms | -15.5% |
| Fork | 22.617 ms | 20.835 ms | +8.6% |
| Luma, first pair | 29.998 ms | 25.485 ms | +17.7% |
| Luma, reversed-order repeat | 22.650 ms | 21.875 ms | +3.5% |
| Koya dock | 23.490 ms | 31.006 ms | -24.2% |

Luma adds a stable 50.1 mean draw calls (632.1 versus 582.0). The initial >10% timing difference did not repeat; source inspection confirms bounded/cullable settlement geometry and preserved canopy/current caches, with no new per-frame texture generation or detail growth with total route length. No repeatable additional >10% frame-time regression was established. Retain the first slow Luma pair and historical 36.5-versus-45.9 FPS fork comparison. Sustained 60 FPS, thermal stability, background OS load and performance across devices remain unverified. No renderer rewrite was justified by the inconsistent timing alone.

### Remaining gates

Human third-milestone test requested: choose Full relief, food at Luma then filters at Koya, report weight/gear/channel trade-off, delivery/reward clarity and handling. User replied “I’ll try it and send feedback.” This is a pending test, not acceptance. Independent graphical, performance and final integration work is complete; next action is to address the largest problem in actual human feedback and repeat review as needed. Existing milestone-2 human acceptance is not reused for new cargo behavior. New evidence remains ignored by repository policy; reproducible test sources are retained.

## Third-step planning — proposed, not implemented

Created [thirdSteps.md](thirdSteps.md) from the completed second milestone and original concept. Proposed scope: two fixed cargo loads, one new intermediate village, food plus existing filters, weight-dependent acceleration/braking, matching deliveries, per-order support and explicit partial outcomes. Preserve existing engines, depot and version-1 player progress through a tested compatibility migration if the schema changes. The plan retains performance investigation, actual route/input evidence, fresh critics and human playtesting as acceptance gates. Updated the concept and document links. This planning change does not modify gameplay, profiles, controls or prior milestone verdicts.

Fresh-context planning critic: **PASS**, with a fuel-budget clarification incorporated. The original proposed four-minute upper bound would nearly exhaust the 138 available fuel on idle consumption alone; the plan now targets a modest extra stop time and prioritizes measured starter viability with a small reserve. Documentation links and whitespace checks pass. No gameplay tests or third-milestone acceptance are claimed for this documentation-only change.

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

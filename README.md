# Living River

A Godot 4.7.2 river-delivery prototype: choose filters for Koya alone or a heavier relief load with food for Luma too. Read the current, choose a passage, deliver matching aid, and use support to improve your engine. The starter-engine route takes about three minutes. Art and sound are generated from original code; no external game assets are required.

## Play

Open `project.godot` in Godot **4.7.2** and press **F6** with the main scene open, or **F5** to run the project. On first launch choose English or Russian, then select **Play**. Choose Light or Full relief in the briefing, then press **Enter** or click **Cast off**.

The start menu provides Settings, Credits and Quit. Settings offers live English/Russian switching plus separate Master, Music and Effects levels; zero mutes that bus, and Effects includes the engine. Language and levels persist separately from progression in `settings.cfg`. Open Settings from the pause screen to adjust them during a run; Back keeps the mission paused. **End run and return to menu** abandons unfinished cargo while retaining saved support and engines. Play opens a fresh briefing; mid-river resume is not implemented.

From PowerShell on this machine:

```powershell
& 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path .
```

| Controls | Action |
|---|---|
| A / D or Left / Right | Steer across the river |
| W / Up | Accelerate in the selected gear's direction |
| S / Down | Brake to a stop |
| 1 / 2 (number row or keypad) | Starter engine forward gears |
| 9 (number row or keypad) | Reverse gear; slow down before changing direction |
| Space | Brake to a complete stop |
| Hold E | Unload while stopped inside the dock circle |
| R | Return to load selection; keep credits and engines |
| Escape | Pause / resume |
| B | Open / close the depot between runs |
| Backtick / grave accent | Show / hide the FPS counter (hidden on startup) |

Start in first gear for maneuvering; select second for the main river run. Hold W to drive the selected gear, S to brake, and A/D to steer. To reverse, slow below about 8 km/h, press 9, then hold W. Releasing throttle coasts to a stop. The HUD shows actual ground speed in km/h, selected gear and engine gear count. The river uses 0.05 meters per world unit: the route is 1.3 km, with the same approximately three-minute duration as before. Previous 26 km text was unscaled world distance.

Collect the orange refuel buoy near the midpoint. Stay clear of rocks and the sandy bank edge. At Koya Landing, enter the dashed circle, hold S or Space, then hold E for two seconds. Delivery activates the village pump and radio beacon. Running out of fuel or hull ends the run.

Follow water arrows: current changes actual travel speed and can carry an unpowered boat. Before the island, choose the wider left channel with opposing flow, or the narrower right rapids with assisting flow and bank rocks. Both work with the starter engine. The channels rejoin before the orange refuel buoy. The dock is in still water.

Light carries filters to Koya for **100 support**. Full relief also carries food to **Luma Landing**, on the left bank after the buoy, for **60 support**. Both aboard means 20% slower acceleration and 15% less braking deceleration; brake earlier. Delivering food restores light handling and continues the run. Missing Luma and unloading at Koya ends with a partial result. Failure keeps already saved delivery rewards; undelivered cargo returns to the depot.

Press **B** in the briefing or after a run to open the depot. **River Triple** costs 100 credits, adds third gear and more top speed, and uses 18% more fuel at matched input. Buy, equip, then **Plan next run** to choose cargo. You can switch back to the owned starter for free. The depot compares the two engines before purchase.

Credits, ownership and equipped engine are saved in Godot's user-data directory as `profile.json`. Valid version-1 profiles migrate automatically. R abandons unfinished cargo and returns to a fresh briefing while retaining committed rewards. The depot's separate **Reset progression** button requires a second confirmation click and returns to the starter profile. Invalid saves fall back to the starter; failed reward saves retain cargo and permit unloading retry. Tests use isolated profiles and do not spend your credits.

The game has an original looping engine, a quiet 32-second instrumental theme and cached event cues. Throttle, gear and load affect the engine; unpowered current drift does not rev it. Music and engine use separate players so a delivery/collision cue cannot interrupt them. Audio provenance and regeneration instructions are in [assets/audio/README.md](assets/audio/README.md). Human listening/translation acceptance and performance qualifications are recorded in the workbench.

The starter **River Twin** and alternative **River Triple** are data Resources in `resources/engines/`. Number keys select supported gears; unavailable gears leave the selection unchanged and show a message. Data supports at most eight forward gears, with 9 reserved for reverse. Current speed is ground speed, so assisting flow can exceed the engine's still-water speed range.

## Checks and evidence

Use the console executable above as `$godotExe`:

```powershell
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --quit-after 120
& $godotExe --headless --path . --script tests/mission_checks.gd
& $godotExe --headless --path . --script tests/critic_regressions.gd
& $godotExe --headless --path . --script tests/gear_checks.gd
& $godotExe --headless --path . --script tests/river_checks.gd
& $godotExe --headless --path . --script tests/river_adversarial.gd
& $godotExe --headless --path . --script tests/profile_checks.gd
& $godotExe --headless --path . --script tests/profile_adversarial.gd
& $godotExe --headless --path . --script tests/delivery_checks.gd
& $godotExe --headless --path . --script tests/order_profile_checks.gd
& $godotExe --headless --path . --script tests/save_adversarial3.gd
& $godotExe --headless --path . --script tests/delivery_adversarial3.gd
& $godotExe --headless --path . --script tests/settings_checks.gd
& $godotExe --headless --path . --script tests/localization_checks.gd
& $godotExe --headless --path . --script tests/audio_checks.gd
& $godotExe --headless --path . --script tests/audio_loop_checks.gd
& $godotExe --headless --path . --script tests/presentation_adversarial4.gd
```

`tests/mission_checks.gd` measures the complete route with scripted steering and exercises resource/mission transitions. The independent regression suite covers dock overshoot recovery and real engine restart input. Neither is a human playtest.

Scene fixtures explicitly bypass the front end and isolate settings/progression unless `show_frontend` metadata is set. `presentation_adversarial4.gd` and `localization_adversarial4.gd` exercise the actual new screens graphically. Headless audio output is disabled to avoid engine Dummy-playback teardown leaks; headless buffer/control checks do not establish audible output. `audio_runtime4.gd` requires graphical real-time execution for 114 seconds and records actual mixer playback. Its Master-bus recording is before Master mute/fader, so physical mute and audible quality still require listening.

To reproduce normal-speed graphical keyboard playback (overwrites its evidence):

```powershell
& $godotExe --path . --script tests/input_playback.gd --fixed-fps 30 --write-movie doc/evidence/handling.avi
```

That playback records 17.7 seconds of simulation. The opening controls are exercised from the normal starting state; later collision, docking, and failure situations are staged explicitly. It is separate from full-route timing. Movie Maker may render slower than real time.

The opt-in `-- --demo` argument runs an accelerated, scripted full route and saves screenshots. Normal play never uses the demo pilot.

Milestone 2 graphical evidence can be reproduced separately:

```powershell
# Three complete accelerated graphical routes and real mouse-operated depot UI.
& $godotExe --path . --script tests/milestone2_graphical.gd --fixed-fps 30
# Twelve seconds of normal-speed staged current and dock-recovery motion.
& $godotExe --path . --script tests/milestone2_graphical.gd --fixed-fps 30 --write-movie doc/evidence/milestone2_motion.avi -- --motion
```

The second command explicitly stages later example positions. Neither script is a human playtest. See the workbench for acceptance status, measured route times, performance samples and independent verdicts.

Third-milestone evidence separates a complete accelerated full-load route from normal-speed staged physical input and dock approaches:

```powershell
& $godotExe --path . --script tests/milestone3_graphical.gd --fixed-fps 30 --write-movie doc/evidence/step3_route.avi
& $godotExe --path . --script tests/milestone3_graphical.gd --fixed-fps 30 --write-movie doc/evidence/step3_motion.avi -- --motion
```

Review media is local ignored evidence. These harnesses use test profiles and do not change player progression.

To measure rendering, use `tests/performance_probe.gd -- --mode=current --long` in a graphical run (uncapped, physics disabled). `tests/performance_route.gd` instead measures a complete real-time scripted Full relief run using the normal window/VSync settings and 60 Hz physics. Run these separately from the editor's game or other benchmark windows. See the workbench for before/after results and remaining frame-time spikes.

See [the workbench](doc/workbench.md) for exact review status and limitations, [the accepted first-step plan](doc/firstSteps.md), [the completed second-step plan](doc/secondSteps.md), [third-step acceptance](doc/thirdSteps.md), [the proposed fourth step and river-map follow-up](doc/fourthSteps.md), and [the concept](doc/conceptEn.md) for future directions. Art is intentionally a readable procedural prototype rather than finished painted artwork.

# Living River

A Godot 4.7.2 river-delivery prototype linking Base, Luma and Koya. Choose a locally supplied job, navigate upstream or downstream, deliver aid and depart next time from your last safe landing. The Base relief run takes about three minutes; village legs are shorter. Art and sound are original; no external game assets are required.

## Edit the artwork

Open [scenes/asset_gallery.tscn](scenes/asset_gallery.tscn) in Godot's **2D** workspace to browse the artwork, or press **F6** to view the gallery. Individual editable scenes are in [scenes/art/](scenes/art/): boat, rock, fuel buoy, house, landings, canopy and palm. Their polygons, lines, labels and sprites are ordinary scene children. The boat's Inspector exposes cargo and damage previews. Open an individual scene to edit its parts; gameplay instances use these scene files.

Open [scenes/river_world.tscn](scenes/river_world.tscn) for the assembled river preview. Select its root and change **Preview Region** or **Preview Southbound** in the Inspector to inspect Base, the fork, refuel buoy, Luma and Koya. The main scene also includes this world visibly in the editor. These previews do not load saves, change settings or play audio. **F5** still launches the game.

Dense riverbank foliage and water remain batched for performance, with their artwork visible in the river preview. Shared foliage SVG sources are in `assets/visual/`. [doc/editingArt.md](doc/editingArt.md) describes scene ownership and the explicit one-time migration tool.

## Play

Open `project.godot` in Godot **4.7.2** and press **F6** with the main scene open, or **F5** to run the project. On first launch choose English or Russian, then select **Play**. The map marks your saved landing; choose a local contract, read its briefing, then press **Enter** or click **Cast off**. Remote landings can be inspected but cannot start a trip.

The start menu provides Settings, Credits and Quit. Settings offers live English/Russian switching plus separate Master, Music and Effects levels; zero mutes that bus, and Effects includes the engine. Language and levels persist separately from progression in `settings.cfg`. Open Settings from the pause screen to adjust them during a run; Back keeps the mission paused. **End run and return to menu** abandons unfinished cargo while retaining saved support, engines and the last committed landing. Play opens that landing's map; mid-river resume is not implemented.

From PowerShell on this machine:

```powershell
& 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path .
```

| Controls | Action |
|---|---|
| A / D or Left / Right | Steer screen-left/right in either heading |
| W / Up | Start continuous cruise at the selected gear; backward in gear 9 |
| S / Down | Stop the engine and decelerate; stays stopped after release |
| 1 / 2 (number row or keypad) | Starter engine forward gears |
| 9 (number row or keypad) | Reverse gear; slow down before changing direction |
| Hold E | Unload or moor the empty return while stopped inside the destination circle |
| R | Abandon the leg and open the last-safe-landing map; retain committed progress |
| Escape | Pause / resume |
| B | Open / close the depot between runs |
| Backtick / grave accent | Show / hide the FPS counter (hidden on startup) |

Start in first gear for maneuvering; select second for the main river run. Tap W to start cruise at the selected gear; releasing W keeps the engine driving. Tap S to stop the engine and slow the boat, then hold E to unload. A/D steer. To reverse, use S to slow below about 8 km/h, press 9, then tap W. Space has no gameplay action. Pause cancels cruise; press W again after resuming. Current can still carry an unpowered boat. The HUD shows actual ground speed in km/h, selected gear and engine gear count. The river uses 0.05 meters per world unit: the whole route is 1.3 km and takes about three minutes.

All landings offer free fuel/repair before departure: each leg starts at 100 hull/fuel. Collect the orange buoy when your route passes it. Stay clear of rocks and the sandy bank edge. At your destination enter the dashed circle, brake, then hold E for two seconds. Running out of fuel or hull ends the run and retains the last committed landing.

The map stays north-up and current zones flow south toward Base. Northbound aid runs work against them; southbound trips use forward gears with the boat facing south. A/D remain screen-relative. Follow the water arrows: the left fork is wider with gentler southward flow; the right has stronger southward rapids and bank rocks. Both work with the starter engine. The old north-assisting shortcut has been retuned. Landing approaches are calm.

From Base, Light carries filters to Koya for **100 support**. Full relief also carries food to **Luma Landing** for **60 support**. Both aboard means 20% slower acceleration and 15% less braking deceleration; unloading food restores light handling. Skipping Luma and finishing at Koya gives a partial result. Koya's cooperative supplies food for Luma (60); Luma's cache supplies filters for Koya (100). Luma also offers an **empty return to Base**: no cargo or reward; hold E at Base to moor and save the arrival. Prototype supplies replenish between trips.

Every matching committed delivery saves its landing with its support. For example, delivering food at Luma then failing near Koya recovers at Luma with the earned 60. Failed saves retain cargo and the old checkpoint for retry. Incidental docking without a matching delivery does not move the checkpoint. **Plan next trip** opens the map at your saved landing.

Press **B** on the map, in the briefing or after a run to open the depot. **River Triple** costs 100 credits, adds third gear and more top speed, and uses 18% more fuel at matched input. Buy, equip, then **Plan next trip**. You can switch back to the owned starter for free. The depot compares the two engines before purchase.

Version-3 `profile.json` saves credits, engines and the last safe landing. Valid version-1/2 profiles migrate automatically, preserving progress and starting at Base. Invalid/future originals are preserved and progression changes stay blocked until an explicit reset. The depot's separate **Reset progression** action requires confirmation, returns to Base/starter progress and retains language/audio settings. Tests isolate both files and do not spend player credits.

The game has an original looping engine, a quiet 32-second instrumental theme and cached event cues. Throttle, gear and load affect the engine; unpowered current drift does not rev it. Music and engine use separate players so a delivery/collision cue cannot interrupt them. Audio provenance and regeneration instructions are in [assets/audio/README.md](assets/audio/README.md). Human listening/translation acceptance and performance qualifications are recorded in the workbench.

The starter **River Twin** and alternative **River Triple** are data Resources in `resources/engines/`. Number keys select supported gears; unavailable gears leave the selection unchanged and show a message. Data supports at most eight forward gears, with 9 reserved for reverse. Current speed is ground speed, so assisting flow can exceed the engine's still-water speed range.

## Checks and evidence

Use the console executable above as `$godotExe`:

```powershell
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --quit-after 120
& $godotExe --headless --path . --script tests/profile_journey5.gd
& $godotExe --headless --path . --script tests/save_adversarial5.gd
& $godotExe --headless --path . --script tests/journey_checks5.gd
& $godotExe --headless --path . --script tests/settings_checks.gd
& $godotExe --headless --path . --script tests/localization_checks.gd
& $godotExe --headless --path . --script tests/audio_checks.gd
& $godotExe --headless --path . --script tests/audio_loop_checks.gd
& $godotExe --path . --script tests/map_graphical5.gd
& $godotExe --path . --script tests/handling_graphical5.gd
```

`journey_checks5.gd` measures eleven full fixed-step cases without resource/position edits after launch. Graphical critics exercise physical inputs and actual map/depot controls; later dock/fork examples are explicitly staged. Neither is a human playtest. Older milestone-1–4 harnesses below are historical evidence fixtures: some encode superseded Base-only launch, R-to-briefing and version-2 save assumptions. Use the fifth-milestone suites for current acceptance.

Scene fixtures explicitly bypass the front end and isolate settings/progression unless `show_frontend` metadata is set. `presentation_adversarial4.gd` and `localization_adversarial4.gd` exercise the actual new screens graphically. Headless audio output is disabled to avoid engine Dummy-playback teardown leaks; headless buffer/control checks do not establish audible output. `audio_runtime4.gd` requires graphical real-time execution for 114 seconds and records actual mixer playback. Its Master-bus recording is before Master mute/fader, so physical mute and audible quality still require listening.

Historical normal-speed graphical keyboard playback (overwrites its evidence and requires its earlier behavior assumptions):

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

Current rendering comparisons use `tests/presentation_benchmark5.gd` with the identical harness in the frozen baseline. `tests/performance_journey5.gd` measures a continuous real-time Base Full → Koya food return → empty Base return using default audio, window/VSync and 60 Hz physics. Run graphical checks and benchmarks separately. Exact commands, source identities, results and remaining stalls are recorded in the workbench and local review reports.

See [the workbench](doc/workbench.md) for exact review status and limitations, [first](doc/firstSteps.md), [second](doc/secondSteps.md), [third](doc/thirdSteps.md), [fourth](doc/fourthSteps.md) and [fifth milestone criteria](doc/fifthSteps.md), and [the concept](doc/conceptEn.md) for future directions. Art is intentionally a readable procedural prototype rather than finished painted artwork.

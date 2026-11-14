# Living River

A Godot 4.7.2 river-delivery prototype: bring water filters to Koya Landing, read the current, choose a passage, and use logistics support to improve your engine. The starter-engine route takes about three minutes. Art and sound are generated from original code; no external game assets are required.

## Play

Open `project.godot` in Godot **4.7.2** and press **F6** with the main scene open, or **F5** to run the project. Press **Enter** at the mission briefing.

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
| R | Restart the entire run |
| Escape | Pause / resume |
| B | Open / close the depot between runs |
| Backtick / grave accent | Show / hide the FPS counter (hidden on startup) |

Start in first gear for maneuvering; select second for the main river run. Hold W to drive the selected gear, S to brake, and A/D to steer. To reverse, slow below about 8 km/h, press 9, then hold W. Releasing throttle coasts to a stop. The HUD shows actual ground speed in km/h, selected gear and engine gear count. The river uses 0.05 meters per world unit: the route is 1.3 km, with the same approximately three-minute duration as before. Previous 26 km text was unscaled world distance.

Collect the orange refuel buoy near the midpoint. Stay clear of rocks and the sandy bank edge. At Koya Landing, enter the dashed circle, hold S or Space, then hold E for two seconds. Delivery activates the village pump and radio beacon. Running out of fuel or hull ends the run.

Follow water arrows: current changes actual travel speed and can carry an unpowered boat. Before the island, choose the wider left channel with opposing flow, or the narrower right rapids with assisting flow and bank rocks. Both work with the starter engine. The channels rejoin before the orange refuel buoy. The dock is in still water.

Every successful aid delivery earns **100 support credits**, once. Press **B** in the briefing or after a run to open the depot. **River Triple** costs 100 credits, adds third gear and more top speed, and uses 18% more fuel at matched input. Buy, equip, then launch another run. You can switch back to the owned starter for free. The depot compares the two engines before purchase.

Credits, ownership and equipped engine are saved in Godot's user-data directory as `profile.json`. R restarts only the mission. The depot's separate **Reset progression** button requires a second confirmation click and returns to the starter profile. Invalid saves fall back to the starter; write failures cancel progression transactions and display a notice. Tests use isolated profiles and do not spend your credits.

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
```

`tests/mission_checks.gd` measures the complete route with scripted steering and exercises resource/mission transitions. The independent regression suite covers dock overshoot recovery and real engine restart input. Neither is a human playtest.

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

See [the workbench](doc/workbench.md) for exact review status and limitations, [the accepted first-step plan](doc/firstSteps.md), [the second-step plan](doc/secondSteps.md), and [the concept](doc/conceptEn.md) for future directions. Art is intentionally a readable procedural prototype rather than finished painted artwork.

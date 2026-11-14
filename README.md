# Living River

A first playable Godot 4.7.2 prototype: bring water filters to Koya Landing along a winding jungle river. The authored route takes about three minutes at cruising speed. Art and sound are generated from original code; no external game assets are required.

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
| Backtick / grave accent | Show / hide the FPS counter (hidden on startup) |

Start in first gear for maneuvering; select second for the main river run. Hold W to drive the selected gear, S to brake, and A/D to steer. To reverse, slow below about 8 km/h, press 9, then hold W. Releasing throttle coasts to a stop. The HUD shows actual ground speed in km/h, selected gear and engine gear count. The river uses 0.05 meters per world unit: the route is 1.3 km, with the same approximately three-minute duration as before. Previous 26 km text was unscaled world distance.

Collect the orange refuel buoy near the midpoint. Stay clear of rocks and the sandy bank edge. At Koya Landing, enter the dashed circle, hold S or Space, then hold E for two seconds. Delivery activates the village pump and radio beacon. Running out of fuel or hull ends the run.

The starter **River Twin** engine is defined in `resources/engines/river_twin.tres`. Number keys select supported gears; unavailable gears leave the selection unchanged and show a message. Future engines can define up to eight forward gears, with 9 reserved for reverse. Purchasing and ownership are planned in [secondSteps.md](doc/secondSteps.md); the current game has no shop.

## Checks and evidence

Use the console executable above as `$godotExe`:

```powershell
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --quit-after 120
& $godotExe --headless --path . --script tests/mission_checks.gd
& $godotExe --headless --path . --script tests/critic_regressions.gd
& $godotExe --headless --path . --script tests/gear_checks.gd
```

`tests/mission_checks.gd` measures the complete route with scripted steering and exercises resource/mission transitions. The independent regression suite covers dock overshoot recovery and real engine restart input. Neither is a human playtest.

To reproduce normal-speed graphical keyboard playback (overwrites its evidence):

```powershell
& $godotExe --path . --script tests/input_playback.gd --fixed-fps 30 --write-movie doc/evidence/handling.avi
```

That playback records 17.7 seconds of simulation. The opening controls are exercised from the normal starting state; later collision, docking, and failure situations are staged explicitly. It is separate from full-route timing. Movie Maker may render slower than real time.

The opt-in `-- --demo` argument runs an accelerated, scripted full route and saves screenshots. Normal play never uses the demo pilot.

See [the workbench](doc/workbench.md) for exact review status and limitations, [the accepted first-step plan](doc/firstSteps.md), [the second-step plan](doc/secondSteps.md), and [the concept](doc/conceptEn.md) for future directions. Art is intentionally a readable procedural prototype rather than finished painted artwork.

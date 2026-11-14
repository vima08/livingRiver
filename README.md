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
| W / Up | Accelerate northward |
| S / Down | Slow, then reverse south to recover a missed turn or dock |
| Space | Brake to a complete stop |
| Hold E | Unload while stopped inside the dock circle |
| R | Restart the entire run |
| Escape | Pause / resume |
| Backtick / grave accent | Show / hide the FPS counter (hidden on startup) |

Hold W to move forward, S to slow and reverse, and A/D to steer. Releasing the throttle lets the boat coast to a stop. Collect the orange refuel buoy near the midpoint. Stay clear of rocks and the sandy bank edge. At Koya Landing, enter the dashed circle, hold Space, then hold E for two seconds. Delivery activates the village pump and radio beacon. Running out of fuel or hull ends the run.

## Checks and evidence

Use the console executable above as `$godotExe`:

```powershell
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --quit-after 120
& $godotExe --headless --path . --script tests/mission_checks.gd
& $godotExe --headless --path . --script tests/critic_regressions.gd
```

`tests/mission_checks.gd` measures the complete route with scripted steering and exercises resource/mission transitions. The independent regression suite covers dock overshoot recovery and real engine restart input. Neither is a human playtest.

To reproduce normal-speed graphical keyboard playback (overwrites its evidence):

```powershell
& $godotExe --path . --script tests/input_playback.gd --fixed-fps 30 --write-movie doc/evidence/handling.avi
```

That playback records 17.7 seconds of simulation. The opening controls are exercised from the normal starting state; later collision, docking, and failure situations are staged explicitly. It is separate from full-route timing. Movie Maker may render slower than real time.

The opt-in `-- --demo` argument runs an accelerated, scripted full route and saves screenshots. Normal play never uses the demo pilot.

See [the workbench](doc/workbench.md) for exact review status and limitations, [the plan](doc/firstSteps.md) for acceptance criteria, and [the concept](doc/conceptEn.md) for future directions. Art is intentionally a readable procedural prototype rather than finished painted artwork.

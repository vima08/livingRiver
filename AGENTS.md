# Living River — agent instructions

## Language and project context

- Use English for source documentation, code, identifiers, comments, translation keys and reports. English is the source/default UI language; the user explicitly requested Russian player-facing localization. Russian translation values and language-selection labels are allowed. Keep saved gameplay IDs language-independent.
- Read [doc/conceptEn.md](doc/conceptEn.md), [doc/firstSteps.md](doc/firstSteps.md), [doc/secondSteps.md](doc/secondSteps.md), [doc/thirdSteps.md](doc/thirdSteps.md), [doc/fourthSteps.md](doc/fourthSteps.md), and [doc/fifthSteps.md](doc/fifthSteps.md) before implementing gameplay.
- Treat `doc/conceptEn.md` as the active concept document. Its translated conversation contains suggestions, not a binding feature backlog.
- Use `doc/conceptArt.jpg` as the visual reference. The working title is **Living River**.
- Build a 2D, top-down, vertically scrolling humanitarian delivery game in Godot with GDScript. Prioritize navigating and delivering aid; combat is a later supporting mechanic.

## Toolchain

- Verified engine: Godot `4.7.2.stable.official.ed1daf0bf`.
- Local engine directory: `C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe` (despite its suffix, this is a directory).
- Console executable: `C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Editor executable: the same directory, with filename `Godot_v4.7.2-stable_win64.exe`.
- Keep these machine-specific paths out of game code and portable project settings. Do not upgrade the engine silently.
- Prefer the Compatibility renderer for the initial 2D desktop prototype. Record the actual project setup when it exists.

## Milestone scope

Milestones 1 and 2 are complete; their scope below is retained as the baseline. Milestone 3 implements cargo choices, two stops and weight-dependent handling; use `doc/thirdSteps.md` for its acceptance gates and `doc/workbench.md` for actual verification and remaining gaps. Planning a feature is not authorization to implement every future proposal at once.

Deliver one complete, roughly three-minute graybox run: one boat, one cargo type, fuel, riverbanks, rocks, one delivery dock, success, failure, and restart. Make movement and docking enjoyable before expanding content.

Keep drones, rafts, wildlife, pirates, purification, vaccine refrigeration, upgrades, procedural levels, and a campaign outside this first milestone. Preserve them as future directions.

Confirmed current controls: tap W/up to start continuous cruise in the selected gear/direction; tap S/down to stop the engine and decelerate. Releasing W keeps cruising. Space has no gameplay action. A/D or left/right steer screen-left/right. Pause cancels cruise; resume requires a new W press. Starter forward gears use 1 and 2; 9 selects reverse. Number-row and keypad bindings share gear actions. Engines may define up to eight forward gears because 9 is reserved for reverse. An unpowered boat may drift with current.

Milestone 2 implements bounded current zones, one collidable island fork, and a between-run depot (B). A completed delivery grants 100 support credits once; River Triple costs 100, offers three forward gears and 18% higher matched-input fuel use. Credits, ownership and equipment persist locally. R resets run state only; progression reset is a separate confirmed depot action. Buy/equip must remain unavailable during active missions. Use isolated profiles for tests, preserving player progression. Integrated acceptance still requires actual graphical evidence and user handling feedback; consult `doc/workbench.md` for the latest verdict.

HUD speed is actual ground speed in km/h using 0.05 meters per world unit. Use the same scale for route distance. Preserve the FPS toggle, wake direction, and cached foliage performance when adding river forces.

Keep water strokes batched and palm fronds cached at startup. Individual antialiased strokes/frond lines caused hundreds of draw calls across the entire route; November 15 measurements and limits are in `doc/workbench.md`. Compare renderer changes with the same viewport, region and sample path, using frame time and tails as well as average FPS; diagnostic layer removal is not a shipped optimization.

Milestone 3 offers Light (Koya filters, 100 support) and Full relief (Luma food, 60; then Koya filters, 100). Full cargo reduces acceleration by 20% and braking deceleration by 15% until food arrives. R returns to the briefing; the depot's Plan next run does the same. Cargo locks at launch. Per-order rewards commit before removing cargo; failed saves retain cargo for retry. Version-2 profiles migrate valid version-1 progress and retain bounded receipts for the latest run only. Keep human handling acceptance distinct from automated checks.

Milestone 4 adds a first-launch language choice, start menu, English/Russian localization, separate `settings.cfg` preferences and original cached engine/music/event audio. Menu/settings/credits own their input; Play opens a fresh briefing, paused Settings preserves the mission, Back keeps it paused, and ending a run returns to menu with committed progression intact. Tests isolate both preferences and progression; ordinary scene fixtures bypass startup UI unless `show_frontend` metadata is true. Headless audio output is intentionally disabled; actual playback/heard quality requires graphical/listening evidence. Preserve the PCM guard frame that fixed loop clicks without changing the loop period. Use `doc/fourthSteps.md` and the workbench for acceptance and current limits.

Milestone 5 implements the Base–Luma–Koya map, local relief contracts, an explicit empty Luma–Base return, version-3 last-safe-landing progression and north/south navigation. Follow `doc/fifthSteps.md` and the workbench for actual review status; implementation is not human acceptance. Main-menu Play opens the saved landing map. R abandons the leg and recovers there; incidental no-order docking does not move the checkpoint. A matching delivery commits support/receipt/checkpoint atomically before removing cargo; the empty return commits a deduplicated zero-reward Base arrival. Valid versions 1/2 migrate preserving progress, starting at Base; invalid/future originals cannot be overwritten by normal progression actions. Explicit confirmed reset returns to Base/starter progress, keeping settings.

River geography stays north-up and current zones flow south. The old north-assisting rapids now flow more strongly south than the wide channel; old branch times/fuel are historical. Forward gears drive the trip heading, A/D remain screen-left/right, and reverse is relative to that heading. Preserve shared boat/collision orientation, direction-aware camera/pilot and world-velocity wake. All five contracts and their authoritative cargo/rewards are defined in `river_contracts.gd`; no arbitrary save-supplied rewards. Free fuel/repair before each departure is explicit. Connected location persistence does not imply mid-river resume, persistent village simulation or a new supply economy.

## Gauntlet workflow

The player has explicitly accepted milestone 5 as playable and successful. Latest concept direction is a more graphical map and branching tributaries/side streams; keep these as documentation-only future work until requested. Do not reopen the accepted step solely because earlier granular human checks were not individually reported; retain their actual evidence limits.

Method reference: [How to Run a Gauntlet Loop](https://somethingbig.ai/gauntlet-loop).

Use separate builders and fresh-context critics. Compare actual artifacts with explicit quality bars, fix the largest gap, and repeat until the bar passes or the user stops the work. Do not use a fixed round count as acceptance.

For implementation work, this repository authorizes delegation to separate builder and critic agents when available. The lead chooses small reviewable work units and coordinates file ownership to prevent conflicting edits. A builder cannot approve its own work.

Give a critic only the objective, relevant repository rules, acceptance criteria, reference material, and actual artifacts. Do not provide the builder's rationale or conversation history. Critics must inspect running behavior, screenshots, recordings, code, and test output as appropriate. A screenshot alone cannot establish movement quality or playability.

Each verdict must be `PASS`, `REWORK`, or `BLOCKED`, with evidence and the largest remaining gap. If independent review or a graphical run is unavailable, record that limitation; never claim the milestone passed. Continue independent work that remains possible.

Maintain `doc/workbench.md` when implementation starts, recording the current objective, changed artifacts, commands and results, critic verdicts, next gap, and remaining limitations. Store review media under `doc/evidence/` with descriptive names. Separate functional acceptance from visual progress: the graybox need not match finished illustration detail.

## Implementation and verification

- World artwork now has editable sources in `scenes/art/`, an overview in `scenes/asset_gallery.tscn`, and a save-free `@tool` river preview in `scenes/river_world.tscn`. Gameplay uses those same asset scenes. Keep native scene edits authoritative; never run `tools/bake_visual_scenes.gd -- --replace` automatically. Shared foliage SVGs remain batched in the river renderer. See `doc/editingArt.md` for editing boundaries.
- Use small scenes and scripts with clear ownership. Let the working prototype guide architecture; avoid speculative frameworks.
- Use Input Map actions, physics-step movement, and delta-aware resource consumption. Define scrolling and boat motion together to avoid double movement.
- Keep collision geometry consistent with visible banks and hazards. Show damage, fuel use, docking progress, and mission outcomes clearly.
- Make restart reset all mission state. Use a reproducible route for initial reviews.
- Respect the humanitarian setting: show communities as capable participants, and give wildlife avoidance priority.
- Use original or properly licensed assets; record external asset sources and licenses. The concept image is a reference, not a ready-made sprite sheet.
- Exclude `.godot/`, exports, and temporary logs from version control. Keep source assets and Godot UID files where applicable.
- After meaningful gameplay changes, import and launch the project and check relevant behavior. Add focused automated checks for state transitions, resource limits, and restart when useful; avoid tests that merely restate code.
- Report checks actually performed and any unavailable verification. Headless startup does not prove visual quality or that a mission can be completed.

From the repository root, once `project.godot` exists:

```powershell
$godotExe = 'C:\Users\PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path . --editor --import
& $godotExe --headless --path . --quit-after 120
& $godotExe --path .
```

The import command may need completion time on first launch. Inspect exit codes and output; investigate errors before continuing. The graphical command is for manual play and visual review.

# Living River — second steps

## Objective and starting point

The user has accepted the first playable step. Build the next milestone around a stronger version of its core loop: **read the river → choose a gear and passage → deliver aid → earn support → improve the boat → run again**. Keep one short authored route and one delivery destination while proving these decisions work together.

The existing project already has an approximately three-minute route, boat inertia, banks and rocks, fuel and hull, a refuel buoy, low-speed unloading at Koya Landing, visible delivery feedback, failure, restart, pause, and an optional FPS counter. Its latest recorded scripted route result is 169.90 simulated seconds; this is a historical measurement, not a timing guarantee after gearing or currents change. See [workbench.md](workbench.md) for actual checks and evidence limitations. User acceptance moves planning forward; it does not turn automated navigation into a human playtest.

Use Godot 4.7.2, GDScript, the Compatibility renderer, the existing 1280 × 720 framing, and [conceptArt.jpg](conceptArt.jpg). Preserve cached canopy rendering. Do not expand to the original suggested 8–12-minute showcase yet.

## Decisions and scope

**Confirmed user direction:** show a speedometer; select forward gears with number keys, with starter gears on **1 and 2**, and select **reverse with 9**. **W accelerates in the selected direction; S brakes.** Future engines can be bought and provide more forward gears. With 9 reserved for reverse, the direct-selection layout supports at most eight forward gears, on keys 1–8.

The accompanying implementation task adds the speedometer, starter gear controls, and a data-driven engine Resource foundation. Its code and verification belong in the workbench. This document plans the subsequent playable milestone; it does not claim currents, shops, rewards, ownership, or persistence already exist. Engine data by itself is not an economy.

**Proposed second-milestone scope:** one readable current system, one short rapids section, one fork with two viable passages, and a small delivery-reward / engine-purchase / replay loop. Offer the starter engine and one purchasable alternative, provisionally with three forward gears. Keep the existing cargo type and destination. A whirlpool is an alternative to the fork if playtesting shows it is the clearer single navigation experiment; do not add both to this milestone by default.

**Outside this milestone:** multiple villages, procedural routes, drones, rafts, wildlife encounters, pirates and weapons, blockages and cleanup equipment, refrigeration, cargo manifests, campaigns, boat fleets, and final painted art. Additional concept ideas below remain proposals, not hidden acceptance requirements.

## Playable increments and gates

### A. Establish speed and gear handling

Start with the accompanying foundation, then play it before tuning new river forces. Show the selected gear, available forward range, reverse, and actual speed. Unavailable gear keys must leave selection unchanged and explain the available range. A gear change must not instantly reverse velocity or teleport the boat; brake before a direction reversal takes effect. Keep the existing steering bindings, Space brake, unloading, pause, and restart discoverable alongside W and S.

Define speed units once. Use a documented world-distance conversion if displaying km/h; use the same conversion for route distance. The speedometer measures the boat's actual speed over the riverbed, including lateral movement and later current drift. It must show zero when physically stopped, not the selected gear's maximum speed. Docking uses that same actual motion, with a clearly presented speed threshold.

Acceptance: physical key playback covers gears 1, 2 and 9, unavailable selections, acceleration, braking, coast, direction changes, pause and restart. A graphical run demonstrates low-gear docking and missed-dock recovery. Engine data validation rejects invalid speed curves and more than eight forward gears. Focused checks verify speed display conversion, smooth reversal, and reset. This gate must pass before using currents to disguise handling problems.

### B. Add readable water forces in a short test stretch

Keep a single world-space movement model: engine-driven velocity plus current determines actual boat motion; the camera follows that motion. Never apply the same current again as scrolling or an extra translation. Apply forces and fuel use in the physics step using delta. Keep steering authority strong enough to escape the test current with the starter engine.

Use an authored gentle current zone followed by a brief stronger rapids zone. Show flow direction with sparse foam or water streaks; distinguish rocks, fast water and safe water through shape and motion as well as color. Signal entry before the player must react. Rapids create drift and handling pressure; they do not need an additional hidden damage rule. Existing rock and bank collisions remain the damage source.

Acceptance: the same throttle/gear produces visibly different travel with and against flow; speedometer and wake follow actual motion; leaving the zone removes its force smoothly; pause and terminal states freeze the simulation. A player can identify the current's direction before entering and recover from a poor approach without an unavoidable collision. Automated checks compare equal-duration simulations at different physics deltas within declared numerical tolerances, exercise zone boundaries, and verify no duplicate motion. Record normal-speed motion and a graphical starter-engine passage.

### C. Integrate one meaningful route choice

Add one short fork that rejoins before the existing destination. Proposed choice: a slower wide channel versus a shorter rapids channel with more steering demand. Both must be finishable with the starter engine; the upgrade must never be required to deliver aid. Show the choice before the split, with a concise route cue such as “Wide channel / longer” and “Rapids / shorter.” Provide enough visible lead to brake and decide.

Visible islands, banks, current zones and collision geometry must agree. Retain a forgiving final approach, with weak enough drift to make stopped unloading practical. Keep the full successful run roughly three minutes; use measured play to tune route length, fuel and current rather than locking the old 169.90-second result into tests.

Acceptance: record complete successful starter-engine runs through both branches, fuel remaining, damage, duration and any forced recovery. Demonstrate that the safer passage has a real handling benefit and the shorter passage a measurable time or fuel benefit. A fresh critic must be able to explain that choice from the running game. If neither branch changes a decision, simplify or retune before adding content.

### D. Close the smallest progression loop

After navigation passes, add a compact depot between runs with only two engines: the owned starter and one alternative. Present gear count, speed range, acceleration and fuel-use differences before purchase. Prefer plain engine names and a simple comparison over upgrade trees or speculative inventory architecture.

Proposed economy: completed aid delivery grants a fixed logistics-support credit reward, once per mission. Aid itself is not sold. Set the first alternative's price so one or two successful short runs afford it; show reward, balance and price explicitly. A failed run grants no delivery reward and incurs no debt. Do not reward collisions, wildlife harm, or repetitive interaction at an already completed dock.

The alternative adds a forward gear and a useful performance difference, with a visible cost such as greater fuel consumption at high throttle. More gears must not simply improve every statistic. Low gears remain useful for maneuvering; the starter remains viable. Use engine Resource data for gear curves and consumption rather than separate hardcoded movement paths per engine. State which properties are fixed for this milestone and tune only those needed by the two choices.

Keep run state separate from progression: R resets position, velocity, resources, pickup, current interaction, selected gear and mission outcome; it does not erase earned credits or engine ownership. Reset the gear to a valid starting forward gear for the equipped engine. Purchases deduct credits once, owned engines can be equipped free, and an equipped engine cannot change midway through an active mission. Show the equipped engine in the briefing.

For this proposed milestone, persist credits, ownership and equipped engine locally using Godot's user-data storage. Missing or invalid save data falls back to the starter profile without blocking play; write the smallest versioned data structure needed. Provide a clearly labeled progression-reset action separate from R. Decide persistence and reward boundaries before implementing the shop so reload or restart cannot duplicate delivery rewards.

Acceptance: earn → buy → equip → complete another run works through the actual UI. Verify insufficient funds, repeat purchase, repeat reward attempts, failure, restart, reload, invalid save data and switching back to the starter. Confirm the advertised engine differences in measured travel and fuel use. Reviewers must observe a meaningful choice, not only a changed gear-count label.

## Integrated acceptance and Gauntlet

Use small builder work units and separate fresh-context critics, following [AGENTS.md](../AGENTS.md). Give each critic the objective, repository rules, acceptance criteria, reference and actual build/evidence; exclude builder rationale and conversation history. Review the largest gap, fix it, and repeat until the applicable bar passes or the user stops. There is no fixed round count.

The complete milestone passes only when:

- Import, smoke launch and focused state/resource checks finish without script or missing-resource errors.
- A graphical input check proves the displayed controls, speedometer, starter gears, reverse recovery, docking, outcomes and restart.
- Normal-speed motion evidence and a complete graphical run establish readable currents, viable branches, and a reachable dock with both engines. A screenshot alone cannot establish handling.
- The depot completes the earn/buy/equip/replay loop; failure, repeated input, restart and reload cannot grant duplicate rewards or spend credits twice.
- A human playtest checks understanding and handling: the player can explain gear selection and the branch choice, attempt the route, and report where control or information failed. Record results and fixes; do not claim enjoyment from scripted steering.
- A fresh critic returns `PASS` against the integrated criteria, with evidence and any remaining limitations. `REWORK` names the largest gap. `BLOCKED` records unavailable graphical, human or independent review without certifying the milestone.

Update [workbench.md](workbench.md) with changed artifacts, exact commands/results, engine configuration, duration and resource measurements, evidence paths, verdicts, next gap and limitations. Store descriptive screenshots and recordings under `doc/evidence/`; record which cases use staged setup versus a complete route. Keep functional acceptance separate from progress toward the illustrated visual target.

## Performance guard

The cached-canopy renderer's recorded local benchmark samples were 50.4 and 56.5 uncapped FPS, roughly 601 draw calls per frame. These short samples are a comparison baseline on the recorded machine, not a promise of sustained 50–57 FPS or a new minimum requirement.

Before adding water effects, capture the current build using `tests/render_benchmark.gd` with the same viewport, renderer, machine and sampling conditions. Afterward repeat the same region and add a sample through the rapids and fork. Compare frame time and draw calls; investigate a repeatable frame-time regression above 10% before acceptance, rather than hiding it with a lower simulation rate. Record sample variation and a full-run check with the FPS overlay. Avoid per-frame texture generation, dense full-screen particles, and geometry that grows with route length. Preserve the cached canopy approach and offscreen culling. If the target device or graphical benchmark is unavailable, record the open performance gate.

## Additional concept proposals

These are candidates for later playtests, not second-milestone commitments:

- **Community river reports:** a briefing or radio message describes water level and a known channel hazard. Later scouting could improve uncertain information; begin with community knowledge before a drone system.
- **Cargo choices:** heavier supplies reduce acceleration or increase stopping distance; urgent cold-chain cargo trades payload space or reserve power for delivery time. Add only after basic handling and an engine choice are understandable.
- **Community partnerships:** previous deliveries unlock locally maintained channel markers, repair help or trusted route reports. Communities identify needs and contribute expertise; they are active partners.
- **Wildlife-safe navigation:** readable animal space, quiet approaches and bypasses make avoidance the preferred solution. Do not turn wildlife harm into a reward source.
- **Persistent aid outcomes and changing water:** a working pump, clinic radio or maintained landing reflects deliveries; a later water-level change alters an already familiar passage. Start with one observable outcome before simulating a region.

Choose the next proposal from playtest evidence. A useful addition changes a navigation or delivery decision and fits the humanitarian setting; a longer feature list is not a milestone.

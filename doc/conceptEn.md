# Living River — concept (English translation)

This English translation preserves the original concept request and response and serves as the active concept document. Proposed features and names remain proposals. The current concept artwork is [conceptArt.jpg](conceptArt.jpg).

## Original request

I want to make a game: a top-down vertical scroller in which you travel by motorboat through African jungle, along a river in West Africa, on a humanitarian mission. You carry food, medicine, and communications equipment to riverside villages; navigate rapids and whirlpools; blast through aquatic vegetation and garbage blockages; clean the water; send out drones and rafts carrying humanitarian supplies; pick up fuel and vaccinations against fevers; scare away crocodiles and hippos; and defend yourself against pirates. I am thinking of making the game with Codex in Godot. Help me come up with a name, draw up a work plan, and create concept art.

## Response

November 14, 2026, 18:22:38 · gpt-6.1-sol-wm

I will come up with a name and gameplay loop, put together a Godot development plan, and draw a concept of the gameplay screen: the boat, river, villages, and obstacles. I will base it on an adventure where delivering aid is the main goal, and combat helps you get through dangerous stretches.

I suggest the working title **Living River**. The central mechanic is choosing how much cargo to take and how to deliver it: a heavily loaded boat is harder to steer through rapids, a drone consumes battery power, and a raft needs to be launched into the right current. For the concept, I chose a hand-painted 2D style with rich greens and clearly distinguishable obstacles.

> Worked for 2m 15s

I would call the game **Living River**: an adventure scroller where you guide a motorboat along a dangerous river and deliver aid to riverside settlements. The main reward is seeing villages come back to life because of your journeys: clean water becomes available, the clinic starts operating, and communications are restored.

Here are a few more options. These are creative suggestions; name availability has not been checked.

| Title | Mood |
|---|---|
| **Living River** | Nature, aid, hope |
| **Against the Current** | Overcoming challenges and adventure |
| **River Runner** | Deliveries and constant movement |
| **The Last Mile** | Taking aid to hard-to-reach places |
| **River of Hope** | A warmer, family-friendly adventure |

### Main gameplay idea

A combination of arcade controls and small delivery decisions works best here:

**Receive village requests → load the boat → navigate a river section → deliver aid → upgrade the boat.**

Runs could last 8–12 minutes. The screen scrolls upward while the boat can maneuver freely, accelerate, and brake. In backwaters and near docks, scrolling slows or stops, giving the player time to unload and choose the next route.

The most interesting trade-off is **more cargo means more help, but harder handling**. A shortcut goes through rapids, a safe route requires extra fuel, and an urgent medicine delivery forces you to take risks.

| Mechanic | What the player does |
|---|---|
| Rapids and rocks | Chooses a passage while accounting for inertia and current |
| Whirlpools | Compensates for drift or uses the rotation to maneuver |
| Aquatic vegetation and garbage blockages | Clears a passage with a water jet, winch, or special charge |
| Pollution | Delivers filters and deploys a purification unit at a chosen location |
| Drone | Scouts a fork or delivers a small urgent package |
| Cargo raft | Carries heavy aid downstream; choosing the launch point matters |
| Crocodiles and hippos | Require keeping a distance, going around, or scaring them away |
| Pirates | Chase the boat, block passages, and force the player to maneuver and defend themselves |

I would make vaccines **valuable cargo with a delivery deadline and a limited cold-storage reserve**. This creates clear tension. Friendly docks, supply depots, and emergency pontoons are logical places to obtain fuel.

Villages can help in return: repair the engine, warn of an ambush, or mark safe channels. This builds a connection with the people receiving your aid.

### Visual direction

The concept above shows a painted treatment: green water, dense jungle, a white-and-orange boat, and contemporary riverside settlements. For the actual game, I would raise the camera to a strict top-down view and simplify detail somewhat for readability.

A useful idea is that **a village's appearance changes after a delivery**. A radio tower lights up, a water pump starts working, or new boats appear at the dock. The result is visible during your next run.

I suggest setting the game on a fictional river in the forested part of West Africa. This gives us freedom to create interesting geography and our own settlements.

### Godot development plan

For the first version, I suggest **2D and GDScript**. Godot has dedicated 2D tools, physics, particles, and animation suited to this project. ([Godot 2D documentation](https://docs.godotengine.org/en/stable/tutorials/2d/index.html))

| Stage | What to build | Completion criterion |
|---|---|---|
| **1. Controls** | Boat, inertia, braking, scrolling, riverbanks, and rocks | A simple route is fun to navigate even without missions |
| **2. First delivery** | Cargo, fuel, one dock, unloading, victory, and defeat | There is a complete three-minute run |
| **3. River character** | Current, rapids, a whirlpool, and a fork | Different sections require different maneuvers |
| **4. Showcase mission** | Two villages, a drone, a garbage blockage, and one pirate boat | There is a varied 8–12-minute mission |
| **5. Progression** | Rafts, animals, upgrades, and consequences of deliveries | Different ways to complete a run become available |
| **6. Presentation** | Final sprites, water, engine sound, music, and interface | Events are easy to read and controls feel responsive |

**Keep the first prototype tightly scoped:** one boat, one cargo type, one dock, rocks, and fuel. That alone will show whether boating and docking are enjoyable.

Give Codex small, complete tasks: “add current and a test area,” “implement unloading at a dock,” or “create a whirlpool with a clearly visible influence boundary.” After each task, launch the game and perform a short manual check. Establish the Godot version, controls, scene structure, and completion criteria at the start.

**First task for Codex:** create a graybox prototype of a three-minute run: navigate a winding river, preserve the cargo, and deliver it to a dock. This short route will become the foundation of the whole game.

### Sources in the original

- [Godot: 2D](https://docs.godotengine.org/en/stable/tutorials/2d/index.html)

## Current design additions — November 14, 2026

This section records current direction separately from the historical translated conversation above. The original stage table and feature suggestions are not a binding backlog. The user has accepted the first playable step; the next plan is [secondSteps.md](secondSteps.md). Actual implementation and verification remain recorded in [workbench.md](workbench.md).

### Confirmed controls and engine direction

- Add an actual-speed display so the player can judge cruising, braking and docking.
- Select starter forward gears with **1** and **2**; **9** selects reverse. **W** accelerates in the selected direction; **S** brakes. Direction changes preserve inertia and require slowing before reversal.
- Future purchasable engines can offer more forward gears. Reserve 9 for reverse, leaving keys **1–8** for at most eight forward gears. A higher gear count is not a commitment to eight gears in the next milestone.
- Engine choices should expose speed, acceleration and fuel-use trade-offs. A faster engine need not be best for every delivery; low gears and the starter engine should remain useful.

The immediate foundation is a speedometer, starter gear selection and data-driven engine parameters. A Resource defining an engine is preparation for purchases, not an implemented shop or economy. The second-step plan proposes the smallest complete earn/buy/equip/replay loop after navigation improvements pass review.

### Proposed next playable milestone

Keep a short authored humanitarian run with the existing aid cargo and destination. Add readable currents, a brief rapids section and one fork whose safer and faster passages both work with the starter engine. Use a whirlpool instead of the fork only if it proves a clearer single navigation experiment; do not assume both are required. Follow with one purchasable engine alternative and a small logistics-support reward for completed delivery. Aid is delivered to communities rather than sold to them.

This is a proposed scope with gated playable increments, not a commitment to the original full showcase. Defer drones, rafts, wildlife encounters, pirates, refrigeration, cleanup equipment and campaign systems. Compare real movement, docking, route choices and performance before expanding.

### Additional ideas to consider later

These proposals need playtesting and scope decisions before implementation:

- **River information:** communities provide radio reports, seasonal water-level warnings and safe-channel knowledge. Later reconnaissance improves uncertain information rather than replacing local expertise.
- **Cargo trade-offs:** payload mass affects acceleration and stopping distance; cold-chain cargo later creates space, power and time choices. Introduce one trade-off at a time.
- **Community partnerships:** deliveries support locally operated pumps, clinics and radios; partners can maintain markers, advise routes or help repair the boat.
- **Wildlife avoidance:** reserve space, slow approaches and alternate channels take priority over confrontation. Avoid rewards for harming animals.
- **Visible consequences:** aid changes a specific service at a landing, while later environmental changes make familiar routes worth reading again. Prefer one meaningful, observable effect to a broad simulation.

Retain navigation and delivery as the core. Each addition should produce a clear player decision or a visible humanitarian result, with performance and readability checked on the actual game.

### Second-milestone implementation snapshot

The current build now includes bounded river currents, a wide/slower versus narrow/assisting-rapids fork, and a between-run depot. Deliveries grant 100 logistics-support credits once. River Triple costs 100, adds a third forward gear and more speed, and consumes 18% more fuel at matched input. Credits, ownership and equipped engine persist locally; mission restart preserves them. These additions realize the small upgrade loop above without adding the later proposals. Actual checks, graphical evidence, remaining performance limits and user-playtest status are in [workbench.md](workbench.md).

### Third milestone — choose the relief load

[thirdSteps.md](thirdSteps.md) brings the original cargo-choice idea into the existing short run: filters for Koya alone, or filters plus food for Luma Landing after the refuel buoy. A full load responds more slowly and needs more braking distance; unloading food lightens it. Two matching deliveries create a reason to choose gears, a passage and an extra stop. Scripted runs establish starter viability; human handling acceptance remains separate.

The build includes load cards, a two-item manifest, per-order support (60 for food and 100 for filters), clear partial outcomes and version-1 progress migration. R returns to load selection while preserving progression. Luma's receiving team stocks its shelter; Koya's filters activate the pump and clinic radio. See the workbench for current review evidence and remaining acceptance gates. Drones, refrigeration, combat and a wider campaign remain deferred.

## Concept extension — November 15, 2026

The user wants a map of rivers and villages, with the next run starting where the previous journey ended, and some legs working against the current. They also requested a start menu, a language choice with Russian translation, engine sound and looping music. These are requested directions; the details below are proposed defaults, not already implemented behavior.

### A continuing relief journey

Extend the loop to **choose a contract at the current landing → load aid → read flow and choose a route → deliver → plan the next departure from the arrival village**. Begin with a small authored Base–Luma–Koya network. Communities can act as receiving partners and named resupply points. Use a few explicit contracts before adding a campaign generator or a larger economy.

Keep the geography recognizable on return journeys. A southbound leg should use forward gears with the boat facing south, and camera look-ahead following its travel. Show river-flow arrows and upstream/downstream labels on the map and in the briefing. Current belongs to the river reach; it must not reverse simply because a mission changes direction. The current assisting-rapids balance needs deliberate reconciliation with a consistent network flow and fresh fuel/docking measurements.

Proposed continuity uses a last-safe-landing checkpoint: successful committed arrivals update the departure location; failure or abandoning an unfinished leg returns to that landing. Credits, engines, rewards and location need consistent saved transactions. Do not imply mid-river save/resume. Keep service/refuel rules explicit before adding resource carry-over or repair costs. Persistent village simulation, reputation, free roaming and procedural geography remain later work.

### Welcome and language

Add a start menu and persistent language/audio settings around the current runs. English remains the source/default language; Russian is a complete player-facing translation, including manually drawn HUD and village text, save errors and dynamic outcomes. Verify Cyrillic fonts, longer labels and physical key bindings. Keep localization settings separate from progression, with stable language-independent gameplay IDs.

### Sound and atmosphere

An engine loop should communicate idle, throttle, gears and load without mistaking current-driven motion for engine power. Add quiet looping instrumental music and retain distinct event cues, with independent music/effects levels and mute. Loops must survive menu/restart transitions without stacking or clicks. Use original or properly licensed assets with documented provenance, and require actual listening review rather than inferring audible quality from code or meters.

### Planned sequence

[fourthSteps.md](fourthSteps.md) implements milestone 4 for menu, English/Russian UI and original engine/music audio. Settings persist separately from progression. The user confirms Russian is good and recurring engine clicks are fixed; remaining listening, handling and performance acceptance are tracked in [workbench.md](workbench.md). Milestone 5 now connects departures and two-way river travel, with its actual independent review status recorded there.

### Fifth milestone — connect the existing landings

[fifthSteps.md](fifthSteps.md) now implements a Base–Luma–Koya map, contracts supplied at the departure landing, saved last-safe-landings and upstream/downstream navigation through fixed geography. It keeps the original Base Light/Full deliveries and adds Koya food for Luma, Luma filters for Koya, and an explicitly empty, unpaid Luma–Base repositioning trip. The empty return lets the player revisit Base and cross the fork downstream without introducing another cargo type.

Successful committed deliveries or explicit terminal mooring move the checkpoint. Failure or abandonment recovers there; no mid-river resume or incidental-dock fast travel. Free departure services preserve the current per-run fuel/hull model. Current zones now flow consistently south; the old north-assisting rapids have been retuned and both directions measured in complete scripted runs. Version-3 profiles migrate valid older progress and commit checkpoint/reward/receipt together. These are implemented behaviors, while human handling and remaining acceptance still require actual evidence. Wider campaigns, persistent service simulation and new encounter systems remain later decisions.

### Player feedback — milestone 5 accepted, next map direction

The player tested milestone 5, reports that the game is playable and explicitly requests recording the step as a success. The map contains too much text, and a linear river network feels boring. These are accepted directions for a future milestone, not instructions to build them in the current control change:

- Present the map primarily as an image or node-and-river graph, with recognizable landings, connecting waterways, boat location and flow arrows. Put detailed cargo/source/service text in the selected contract's detail panel; avoid making the map itself a text-heavy board.
- Add authored tributaries and side streams so the network offers meaningful alternate destinations and route choices. Keep consistent upstream/downstream geography and clear return connections; decide scope, route balance, persistence and performance acceptance in a separate plan before implementation.

The current three-landing geography and map remain unchanged. The immediate control request is implemented separately: tap **W** to start continuous cruise at the selected gear; tap **S** to stop the engine and decelerate. Releasing W keeps cruise active. Space has no gameplay action. A/D stay screen-relative; gears and reverse retain their existing meaning. Pause cancels cruise and requires a new W press after resume. An unpowered boat can still drift with the river current.

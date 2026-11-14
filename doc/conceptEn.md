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

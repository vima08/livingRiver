# Living River — fifth steps: connected landings and return journeys

Status: **accepted by the player as a successful, playable step**. The player tested the game and explicitly requested recording milestone 5 as a success. Technical integration and scoped reviews passed with the limitations in [workbench.md](workbench.md). Feedback about excessive map text and the linear river is recorded in [conceptEn.md](conceptEn.md) for future graphical-map/tributary planning; those features are not built. The criteria below retain the original review history; acceptance does not invent exhaustive native-layout, listening or controlled-performance checks.

## Playable objective

Make the river feel like a connected place: **open the map at a safe landing → choose a locally supplied contract → load and navigate → commit an arrival → plan the next trip from that landing**. Include upstream aid runs and a downstream return driven with forward gears. Keep the existing authored river, controls, two engines, support economy and humanitarian focus.

The smallest complete journey is Base → Koya → Luma → Base. A Luma → Koya contract also allows repeated village-to-village relief runs. Each leg is a separate run; arrival changes where the following run begins. Saving at a landing does not mean resuming halfway along the river.

## Actual starting point and constraints

- Milestones 1 and 2 are accepted. Milestone 3 has Light/Full relief, two stops, cargo weight and version-2 per-order rewards; its human load/handling acceptance remains open.
- Milestone 4 implements start/pause menus, persistent English/Russian and volume settings, complete Russian UI, a demand-driven engine, a quiet music loop and bounded cues. The player reports Russian is good and engine clicks are fully fixed. Remaining mix/fatigue, native keyboard-layout, handling and user-machine performance gates are not inferred passed.
- Existing positions are Base near y=0, Luma at -14,500 and Koya at -26,000. At 0.05 meters/unit the whole route is approximately 1.3 km. Koya–Luma is about 575 m and does **not** include the island fork at y=-7,600 to -11,200. Luma–Base does.
- Northbound assumptions are embedded in movement, bounds, boat drawing/collision tilt, camera lead, pilot, HUD distance, missed-stop checks and dock completion. A return route needs these adapted together.
- Current already has opposing zones, but the right rapids channel assists northward travel. A consistent river network requires an explicit balance change, not a new upstream label on the old forces.
- Preserve batched water, cached palm fronds, cached HUD labels and the audio PCM loop guard. Prior real-time testing averaged approximately 59 FPS with rare 200–310 ms stalls; it did not prove stable 60 FPS. No scenery expansion before comparable measurements.

Planning and isolated implementation can proceed while old feedback is pending. Before accepting changed handling/current balance, obtain an actual player attempt in each direction and retain any unresolved earlier gates.

## 5A — fixed geography and a small contract board

Add a compact north-up map with **Base**, **Luma Landing** and **Koya Landing**, connected by the two existing reaches. Mark the current saved landing, downstream flow, upstream/downstream travel, available departures, destination, approximate river distance, cargo, support and service availability. Use the current visual palette and readable original code-drawn graphics; no external map service or procedural world is needed.

The map is a planning screen, not free navigation. Enable only departures from the current landing; selecting a remote node shows information without moving the boat. Selecting a contract opens a briefing and Back returns to the same landing's map without issuing a mission. Enter or Cast off issues one mission only after validation and a successful save. Input belongs to the map/briefing while open.

Use this small authored board as the default scope:

| Departure → destination | Job and named source | Choice/reward | Direction |
|---|---|---|---|
| Base → Koya, optionally via Luma | Base logistics depot supplies filters; Full relief also carries depot food to Luma | Existing Light: 100 support. Full: 60 at Luma + 100 at Koya | Upstream |
| Koya → Luma | Koya cooperative supplies food for Luma's receiving shelter | Food only, 60 support | Downstream |
| Luma → Koya | Luma regional supply cache provides filters for Koya's water service | Filters only, 100 support | Upstream |
| Luma → Base | Empty repositioning trip to the logistics depot | No cargo and no reward; clearly labeled before departure | Downstream |

These are repeatable prototype jobs; supplies are explicitly authored and replenished between runs. Do not imply inventory depletion, simulated production or transporting the same delivered filters back. Do not add new commodities, boats or a contract generator. Single-item relief jobs use light handling; only the Base Full load starts heavy. The empty return must have its own correct briefing/manifest and must not silently load Koya filters.

The optional empty return makes Base reachable again and exercises the fork downstream without inventing another aid commodity. All three landings offer the existing depot and free refuel/repair **before departure**. State this service rule on the map/briefing; start each leg with 100 hull/fuel and one fresh per-run buoy where geographically reachable. Buying/equipping remains between runs. A shorter leg need not pass the buoy.

Scope exit: actual map selection in both languages, location-specific board/briefing, empty-trip disclosure, and keyboard/mouse Back/Cast off behavior. Map entry/selection must not issue rewards, consume a mission ID or teleport to a remote node.

## 5B — save the last safe landing consistently

Use a strict version-3 progression schema, separate from the unchanged language/audio settings file. Record stable landing IDs and enough bounded latest-mission/contract context to validate checkpoint changes and deduplicate orders and zero-reward arrivals. Builders choose field names; do not create an unbounded journey history or serialize arbitrary boat positions.

Migration of valid versions 1 and 2 starts at Base and preserves credits, owned/equipped engines, mission-counter safety and already-earned reward protection. Older paid receipts must never be reinterpreted as payable new orders. Migration does not invent completed contracts or resume old cargo. Validate landing/contract IDs and receipt relationships; unknown/future schemas follow explicit safe error behavior without overwriting the original file. Preserve valid progress if migration cannot be written and explain that launch must wait for a safe commit.

Define arrival semantics before UI implementation:

| Event | Saved location and reward |
|---|---|
| Successful matching food delivery at Luma during Base Full | Atomically save +60, its receipt and Luma checkpoint; remaining filters continue toward Koya |
| Successful matching terminal relief delivery | Atomically save its support, receipt and destination checkpoint; then show the result |
| Finish the explicit empty Luma → Base trip | Hold E while stopped inside Base's landing circle to moor; atomically save a deduplicated arrival and Base checkpoint, with zero support |
| Incidental stop with no matching pending order and no explicit terminal mooring job | Explain no matching delivery; no reward/checkpoint change |
| Failure, R, end run/menu, quit or relaunch before another committed arrival | Recover at the last saved landing; retain committed support/ownership and abandon uncommitted cargo |
| Failed delivery/arrival write | Retain old checkpoint, credits, cargo and active run; explain the failure and allow safe E retry |

Checkpoint, reward and duplicate protection commit in one existing-style temporary/backup transaction. Only after success may the run remove cargo, lighten the boat, activate the received-aid effect or enter its terminal result. A duplicate callback/retry cannot pay twice, relocate backward to a previous stop or consume another mission ID. An empty arrival needs explicit idempotency despite having no reward. Begin-mission failure must not leave the map with an unsaved issued run.

If food was committed at Luma and the boat later fails near Koya, recovery starts at Luma with that 60 support. Relaunch after committing Koya starts at Koya even if the result/map was never shown. Partial completion at Koya retains only earned aid support and checkpoints Koya. Explicitly test Base Full skipping Luma, committing partial completion at Koya, then receiving a stale Luma callback: no extra support, cargo change or checkpoint rollback is allowed. No full-payout bonus is introduced.

R now abandons the leg and returns to the **last-safe-landing map**, rather than reopening a Base load card. Pause/menu text must state this change and the saved recovery landing. Back from Settings stays paused. Returning from the result offers **Plan next trip** at the committed landing. Main-menu Play opens that landing's map; use no mid-river Resume wording. Keep the existing explicit confirmed progression reset: it returns to Base/starter progress but retains language/audio preferences. No hidden fast travel through R or the depot.

Scope exit: separate-process migration/relaunch, intermediate Luma recovery, terminal/empty-arrival save failures and retries, bounded receipts and duplicate rejection. All fixtures isolate both save files before scene initialization.

## 5C — navigate both ways through the same river

Keep north up, the same world coordinates, villages on their original banks, and rocks/island geometry fixed across contracts. River water flows south toward Base. Upstream means northward travel against that field; downstream means southward travel with it. Keep dock/service approach zones calm.

Change the old north-assisting rapids to a clearly stronger **south-flowing** narrow channel. Preserve the wide alternative and lateral movement cues, but retune their actual velocities, hazard clearance and fuel costs for both directions. The narrow channel is no longer promised as an upstream speed shortcut. Any benefit/risk claims must follow measured runs; the wide channel should remain the forgiving starter choice. Small tuning of current/engine demand or existing hazard clearance is allowed when evidenced; do not remove layers or mirror geography to manufacture viability.

Use simple route/contract data for origin, destination, allowed stops/order, launch position, travel heading, camera lead, distance/progress and completion. Generalize manifest validation/weight handling rather than branching on the old `full` preset or one hardcoded order ID everywhere. Keep fixed, authoritative cargo/reward definitions; data-driven does not mean accepting arbitrary reward amounts from a save.

- **W/Up** starts continuous cruise along the route's boat heading; **1/2/3** keep their engine meaning. Southbound travel uses forward gears, not gear 9. Releasing W keeps cruising.
- **9** reverses relative to the boat's heading, with the same low-speed direction-change rule. **S/Down** stops the engine and decelerates. Space has no gameplay action. Pause cancels cruise; resume requires a new W press. These tap controls supersede the original hold-to-throttle baseline after the player's accepted playtest.
- **A/D** continue to mean screen-left/right steering on either heading. Explain this in English/Russian hints.
- Boat silhouette, engine/stern, shadows/cargo, collision capsule/tilt and wake agree. Wake follows actual motion, including current drift and reversing.
- Camera leads in the travel direction and shows an approach before the boat reaches it. Heading stays fixed for the leg; this milestone does not add free rotation.
- Distances and missed-stop prompts use the active route direction and next pending destination. Map location remains the last safe checkpoint during a run; it is not a live position save.
- Bounds allow safe launch, reverse maneuvers and arrival at either end without off-map escape. Starting inside the departure dock cannot auto-complete the destination.
- Update the opt-in pilot and test fixtures to exercise the same normal simulation in both directions. Do not negate only HUD speed or teleport through return routes.

Scope exit: real graphical north/south motion, steering, reverse, braking, collision/wake agreement, stable banks/landmarks, both dock approaches and a downstream fork crossing.

## 5D — complete journeys, presentation and measurements

Translate all new map, source/destination, service, abandonment, migration and mooring messages into Russian, including dynamic failure text. Preserve language-independent IDs. Inspect 1280×720 and 960×540, keyboard focus and native-layout physical keys where available. Preserve the confirmed loop-click repair; menu/map/briefing/result transitions must not stack loops, restart music or mistake current drift for throttle.

Add a minimal Base landing marker/receiving circle for the return trip. Reuse existing visual language and keep it light. Existing Luma food/Koya service effects continue after successful commits within the active run; a persistent village-services simulation is outside this milestone and must not be implied by the saved landing.

Measure complete runs with the starter engine for every offered aid load and both passages on any leg that crosses the fork. Include Base Light/Full upstream, Koya → Luma food downstream, Luma → Koya filters upstream and Luma → Base empty downstream. Record elapsed time, hull, fuel, support, checkpoint and actual current direction. Target at least **5 fuel remaining and no hull damage on the clean starter pilot**; fix or explicitly fail any route/branch that misses this bar. Recheck an upgraded-engine relief run and downstream return. Do not silently reuse the old route-time/fuel table after changing flow.

Keep the Base route approximately three minutes (provisional acceptable range 2.5–4 minutes after upstream tuning); shorter inter-village legs should remain shorter. Do not pad them with empty river for matching duration. Require an actual player upstream and downstream attempt, asking whether forward gears, screen-relative steering, flow, approach visibility and saved recovery location make sense. Scripted completion cannot approve handling comfort.

Freeze the actual pre-milestone build before runtime changes. Compare 600-frame same-path original/fork/Luma/Koya sweeps at the same viewport, language, audio settings and layers, using mean/p95 and tails; add a matched southbound fork/landing scenario. Investigate repeatable added frame-time cost above 10% and retain all samples/background-load limitations. Run complete real-time upstream and downstream legs at normal physics, time scale and audio output; separate these from accelerated viability tests. Preserve stalls in reports, avoid competing benchmark processes and disclose any attenuation/staging. No locked-FPS or heard-quality claim without supporting evidence.

## Work units and independent review

Implement in small reviewable units: (1) route/contract definitions and location-aware briefing, (2) profile migration/arrival transaction with isolated adversarial tests, (3) actual map and transitions, (4) southbound movement/camera/render/collision and retuned currents, (5) complete bilingual journeys and measured balance/performance. Keep old behavior usable in isolated fixtures while integration progresses; do not ship an always-enabled map whose buttons reference unimplemented routes.

Use separate fresh-context critics for persistence/recovery, actual map/bilingual interaction, graphical movement/docking and performance/audio regressions. Supply objective, acceptance criteria, current artifacts and evidence; builders do not approve their own results. The lead fixes the largest evidenced gap and repeats review until the applicable bar passes or the user stops. Record PASS/REWORK/BLOCKED with scoped evidence, rather than treating a round count as completion.

## Milestone 5 acceptance checklist

- [x] Actual map → local contract → briefing → run → committed arrival → map at that landing → another departure works by keyboard and mouse, in English and Russian.
- [x] Base Full delivers to both villages; Light/partial behavior stays clear. Return food, filters and explicit empty repositioning have correct source, manifest, rewards and handling.
- [x] Koya → Luma uses south-facing forward drive; Luma → Base crosses the same fork downstream. World current/geography stay consistent in both directions.
- [ ] Ground-speed HUD, direction/missed-stop cues, camera, wake, drawn hull and collision agree. Reverse/braking/physical bindings and calm docking remain comfortable in actual player attempts both ways.
- [x] Version-1/2 migrations preserve progress and reward safety; valid version-3 location/contract/receipt relationships are checked. Invalid/future saves and migration-write failure do not silently erase original progress.
- [x] Reward/checkpoint/receipt commits and zero-reward arrivals are atomic/idempotent; failed writes retain retryable cargo/run state. Relaunch immediately after each commit recovers the correct landing without another payout.
- [x] Food-at-Luma then failure/abandon/quit recovers at Luma; no incidental no-order docking or menu/Back/depot action changes the checkpoint. Confirmed reset preserves settings.
- [x] Every offered starter route/load and fork passage meets the clean viability bar; upgraded tests pass. Timing/fuel/current tables are refreshed rather than copied from old balance.
- [ ] New UI/errors/services are translated and inspected at both sizes; settings, audio loop guards, bounded voices, menus and progression remain intact. Preserve prior human acceptance separately from new claims.
- [x] Same-region mean/p95/tail comparisons and normal real-time upstream/downstream evidence are reviewed. Repeatable >10% regressions are investigated and addressed or explicitly left REWORK. Scoped review passes with all 18 sweeps retained: initial fork penalties reverse in later paired-order checks; the 1,096-ms sweep stall and unknown background load remain limitations. Default-audio real-time three-leg journey passes; this is not a locked-FPS or human acceptance claim.
- [ ] Fresh critics review actual artifacts and complete integration; required human handling/listening/performance feedback is recorded without certifying unavailable gates. Workbench lists actual commands, builds, source identities, media and limitations.

The unchecked mixed/human items preserve the original evidence limits. Technical graphical/translation/audio-buffer/loop checks pass, but agents did not hear the build or certify native OS-layout comfort. The player subsequently tested the game and explicitly accepted this step as playable and successful. Overall milestone acceptance is therefore recorded as success; no exhaustive per-item human result is fabricated. See the workbench for scoped reviews and retained limitations, including the slow sweep and upgraded relief collision.

## After this milestone

Use observed repeated journeys to choose the next addition. A small radio report about river conditions or one persistent visible service consequence would connect the concept to actual player choices. Defer new villages, procedural contracts, seasonal water, repair costs, refrigeration, drones, wildlife encounters, combat and a general campaign until continuity, upstream handling and performance pass. No milestone-6 implementation is authorized here.

## Ready-to-use implementation task

> Build Living River's fifth milestone in `doc/fifthSteps.md`, following `AGENTS.md`. Add the Base–Luma–Koya map, locally supplied contracts, last-safe-landing persistence and forward-driven upstream/downstream runs, including the explicit empty return to Base. Preserve progression through migration, English/Russian settings, sound and renderer optimizations. Choose small work units, use separate fresh-context critics for actual map/bilingual, persistence/recovery, graphical handling and performance evidence, and fix the largest evidenced gap until the criteria pass or I stop the run. Keep `doc/workbench.md` current; do not claim unperformed human/listening gates passed.

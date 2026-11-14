# Living River — third steps: choose the relief load

Status: **implemented; technical reviews passed, human playtest pending**. Milestones 1 and 2 are complete. This document retains the third milestone's design and acceptance gates, based on [conceptEn.md](conceptEn.md). Actual builds, measurements and remaining gaps are recorded in [workbench.md](workbench.md). This is not a complete milestone acceptance claim.

## Goal

Make the aid itself part of the player's decisions:

**Read two village requests → choose a light or full load → choose gears and a channel → make deliveries → see the results → use support at the depot.**

Keep the existing authored river, fork, currents, engines and depot. Add one village stop, one additional cargo type, and a simple cargo-weight effect. This develops the original concept's delivery choices without requiring the full showcase mission.

## Starting point and limits

The game currently has one water-filter delivery at Koya Landing, a 1.3 km route, two viable channels, a refuel buoy, hull/fuel failure, manual gears, a speedometer, current-aware wake, engine purchases and local progression. Successful scripted starter runs take 178.02 seconds through the wide channel or 167.57 through the rapids; River Triple takes 137.58 through the rapids. Those measurements describe milestone 2, not future timing requirements.

The current single-delivery flag and `award_delivery(mission_id)` award one fixed reward at terminal success. They cannot simply be called twice for two stops. The version-1 profile also validates an exact six-field schema. Multiple rewards and new saved fields require an intentional compatibility change, not silently treating old saves as corrupt.

Known limits remain: a short fork benchmark showed 36.5 FPS against a 45.9 FPS comparison, with other pairs varying in the opposite direction. Current arrows and foliage are cached. Automated route pilots use analog steering; user feedback establishes clear controls and a successful upgrade/replay, not novice completion rates or sustained FPS.

## Proposed playable scope

Use two fixed load presets initially. Names, reward amounts and handling multipliers below are tuning defaults, not newly confirmed user requirements.

| Preset | Requests loaded | Stops | Proposed support |
|---|---|---|---:|
| Light run | Water filters for Koya | Existing final dock | 100 |
| Full relief run | Food for new Luma Landing, plus Koya's filters | New intermediate dock, then Koya | 60 + 100 |

Place fictional **Luma Landing** after the fork and refuel buoy, before Koya, with its own still-water approach. Reuse river length where possible. Preserve Koya's identity and final location. Target roughly three minutes for the light run and a modestly longer full run, initially around 3:10–3:20 with the starter. Actual fuel viability takes priority over the duration target; do not extend to 8–12 minutes yet.

Budget the extra stop before tuning weight. The current wide-channel run leaves only 16.6 fuel, and the starting tank plus buoy provides at most 138 total. A four-minute run would consume 132 from idle burn alone, before throttle, so it is not a viable target with unchanged settings. Require at least a small measured fuel reserve (provisionally five units) on clean starter runs through both channels. Tune the approach/stop time first; if needed, explicitly rebalance the existing refuel amount rather than making an engine purchase compulsory. Record any change to the existing fuel balance.

The full load should accelerate more slowly and need more braking distance. Begin with an approximately 20% acceleration reduction and 15% braking-deceleration reduction while both deliveries remain aboard; tune from actual play. After food unloading, handling returns to the light-load setting. Preserve engine gear speed caps, steering authority and the existing fuel model initially. Weight, an extra stop, and route selection are enough new pressure without adding another fuel penalty or cargo-damage system at the same time.

Both loads and both channels must remain viable with River Twin. More support compensates for extra handling and a stop; River Triple should offer a useful alternative without becoming mandatory. Show the load effect before launch so slower response is an understood choice.

Keep current bindings. W applies selected-gear throttle; S/Space brake; A/D steer; 1–8 select supported forward gears; 9 is reverse; E unloads matching cargo. B remains a between-run depot action. No new shortcut is needed for cargo selection: use clear briefing buttons or cards.

## Implementation gates

### A. Establish a reproducible baseline and delivery state

First run the existing import, focused checks and graphical input scenarios. Record current same-region performance over longer samples, including the fork and dock. Retain milestone-2 measurements and investigate the slower fork instead of resetting the baseline to whichever sample looks best. Reproduce and locate the motion harness's two ObjectDB shutdown warnings if practical; distinguish harness shutdown from active-game behavior.

Represent orders, loaded cargo and completion separately from terminal mission state. Give each stop/order a stable identity and an explicit recipient, matching cargo, reward and completion flag. Separate these responsibilities from `main.gd` where it makes the implementation easier to review; avoid a general inventory or quest framework.

Exit: the existing one-stop light run still works with the new order model, exactly once, with unchanged controls and preserved progression. Profile-compatibility checks pass before writing new data over a player's existing profile.

### B. Add the second landing and matching unloading

Add Luma's dock, a distinct sign/silhouette, one request prompt, and a small community receiving area. Reuse cached scenery and existing docking interactions. Show both stops in route order before launch, plus the next pending destination and distance on the HUD. A compact two-item manifest replaces the single cargo label; it must fit with speed, gear and FPS displays.

Only the correct cargo unloads at each dock, at the same clearly displayed actual-speed threshold used by physics. Holding E after completion cannot unload or pay again. At Luma, food delivery grants its support once and the run continues toward Koya. At a stop with no loaded request, explain that there is nothing to deliver rather than inventing an interaction.

Exit: a graphical two-stop run shows food removed at Luma, filters retained, an updated next destination, and a successful Koya delivery. Deliberately visit the wrong stop/cargo combination and verify that neither cargo nor reward changes.

### C. Add the load decision and handling consequence

Offer Light and Full relief cards in the briefing with recipients, cargo, handling effect and support totals. Lock the manifest at launch. Restart returns to the briefing so the player can reconsider the load; it must clearly say that credits and owned engines are retained. This deliberately refines the current immediate R restart, so update all help and input tests together.

Keep cargo mass distinct from engine parameters: buying an engine must not erase the load effect. Change acceleration/braking smoothly as a consequence of unloading; never jump position or instantly rescale current velocity. Current contributes to actual motion once. Drift and lateral travel remain part of the speedometer and docking check.

Exit: compare both presets with the same engine, throttle duration and water conditions. Record acceleration, stopping distance, fuel and trip time. The extra load must be noticeable and recoverable; the human tester should be able to explain why they might choose a lower gear or the wider channel. Completed food unloading measurably lightens handling. Both engines still have their advertised differences.

### D. Make partial deliveries and saved rewards unambiguous

Pay support per completed order, with an exactly-once persisted receipt keyed to that run and order, or an equally safe bounded representation. A receipt and its credit change must commit together. Do not grow an unbounded history of every delivery. Validate unique orders, positive finite amounts, and compatibility with mission IDs and progression reset.

Define outcomes before implementing them:

- All loaded requests completed: full mission success, with each delivery and support amount itemized.
- Reach Koya and unload filters while Luma's food remains aboard: end with a clearly labeled partial result, retaining the Koya reward. Warn about the missed Luma request before final unloading; do not force an unexpected return trip.
- Hull/fuel failure after Luma: the run ends, but already earned support remains. Explain which aid arrived and which cargo returns to the depot. No debt or additional reward is created by failure.
- R or application restart: abandon unfinished run state and return to a fresh briefing. Keep committed rewards, ownership and equipment. A new launch gets a new run identity; repeated input or reload must not re-award an old delivery.
- A failed reward save: show a clear notice and keep order/credit state consistent. Retain a safe retry path; never display a payment as saved while discarding it silently, or permit unloading repeatedly to claim it twice.

If the profile schema changes, migrate a valid version-1 profile preserving credits, both engine ownership options, equipped engine and mission-counter safety. Invalid data still falls back safely with a notice; valid older data must not take that fallback. Test migration, rollback and backup recovery using isolated files. Continue to keep progression reset separate from R and available only between runs.

Exit: actual UI supports launch → Luma delivery → Koya delivery → itemized result → depot → replay. Test skipped Luma, failure after the first stop, interrupted reward save, repeated E, restart, reload, migration and progression reset. Credits and orders must agree in memory and after a disk reload.

### E. Show what the deliveries accomplished

Give each stop one readable in-run consequence: for example, Luma's team moves the food crates into a supply shelter, while Koya's existing pump/radio activates after filters arrive. Keep people and community work visible. The result screen names the service supported, not only the credit payout.

Persist credits and ownership as before; persistent village simulation, reputation and cumulative service unlocks are outside this milestone. Reset each run's visual feedback with its orders. Do not imply that a small food delivery instantly solves the village's needs.

Exit: a critic can identify the recipient, delivered aid, and visible consequence at each stop from the actual build. Art detail remains a readable procedural prototype.

## Integrated acceptance

- [x] Both load presets and both river channels complete with the starter and the declared fuel reserve; at least one complete upgraded-engine run also succeeds. Record duration, fuel, damage, deliveries and support. Fuel viability overrides a proposed duration target.
- [ ] The light preset preserves a complete one-stop option; the full preset adds a meaningful handling/stop decision. Capacity and matching cargo are validated before launch.
- [x] Physical input and actual UI checks cover load selection, gear/brake behavior, low-speed unloading, next objective, both docks, pause, restart-to-briefing and depot.
- [x] Full, partial and failed outcomes report aid delivered and support accurately. Repeated input, reload, interrupted saves and progression reset cannot duplicate credits or lose committed ownership. Filesystem obstruction/backup arrangements were tested; physical power-loss durability remains unverified.
- [x] Valid version-1 profiles migrate without erasing progress; invalid saves and write failures have tested safe behavior. Tests never modify player saves.
- [x] Normal-speed motion demonstrates the load's effect and both dock approaches. Complete route evidence is separated from staged scenarios and accelerated pilots.
- [ ] A human playtest chooses a load, explains the trade-off, delivers at both stops, and reports clarity and handling problems. Fix the largest observed gap and repeat as needed.
- [x] Performance is compared in the same regions and conditions, including the new settlement. Investigate repeatable additional frame-time regressions above 10%; retain unresolved measurements explicitly. No per-frame asset generation or world-detail growth with total route length. The first Luma +17.7% pair, reversed repeat +3.5%, and historical fork slowdown remain recorded; sustained FPS is not certified.
- [x] Fresh independent critics inspect functional, visual and persistence artifacts, followed by a complete integration review. Final review: **BLOCKED pending required human feedback**; automated technical scopes pass. No milestone pass based only on scripts, summaries or still images.

Follow [AGENTS.md](../AGENTS.md): choose small builder work units, use separate fresh-context critics, show the real artifacts and bar, fix the largest evidenced gap, and repeat without a fixed round limit. Update [workbench.md](workbench.md) with actual commands, media paths, verdicts, playtest feedback and limits. No implementation or third-milestone test pass is claimed by this planning document.

## Deferred directions

Drones, rafts, cold-chain timers, fragile cargo, wildlife, pirates, weapons, garbage-clearing equipment, whirlpools, procedural geography, additional engines/boats, campaign maps and persistent reputation remain later candidates. Once the two-stop run is enjoyable, choose the next addition from observed needs: a drone could solve a hard-to-reach delivery, or community radio reports could help choose a route. Each should earn its place through a new player decision.

## Ready-to-use implementation task

> Build Living River's third milestone in `doc/thirdSteps.md`, following `AGENTS.md`. Make choosing and delivering a relief load matter through two village requests, simple cargo weight, matching unloading and clear outcomes. Preserve the completed navigation, engines, depot and existing player progress. Choose the implementation and work decomposition, use separate fresh-context critics for meaningful artifacts, and fix the largest evidenced gap until the criteria pass or I stop the run. Keep `doc/workbench.md` updated with builds, review evidence, performance measurements and limitations. Obtain actual human playtest feedback before claiming the human gate passed.

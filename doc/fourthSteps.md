# Living River — fourth steps: welcome, language and sound

Status: **implemented; engine clicks fixed and human-confirmed, broader acceptance pending**. Menu, translation, preferences and original audio are built. The user confirms Russian is good and the engine click issue is fully fixed. Remaining listening/handling/performance gates are recorded separately. The connected-river milestone below remains unimplemented planning context. Current reviews and limits are in [workbench.md](workbench.md).

## Direction and current baseline

The next experience should feel like setting out on a continuing relief journey: choose a language, hear the boat, deliver aid, arrive somewhere, then plan the next leg from that landing.

The current build already has a short authored river, Light and Full relief loads, Luma and Koya, cargo weight, gears, currents, a fork, support credits, two engines and version-2 progression saves. A Full/Wide starter pilot completes in about 181 seconds with 14.6 fuel and full hull. These are scripted results, not human handling acceptance. The third milestone's load-choice/handling feedback remains pending.

The performance follow-up reduced mean renderer frame time by 30–43% in four regions. A complete real-time scripted run averaged 59.27 FPS, with rare long stalls retained in the evidence. Other Godot/background load was uncontrolled. Do not treat performance as permanently solved or enlarge scenery until comparing the same conditions again.

The pre-milestone baseline had no start menu, translated UI or continuous audio. Milestone 4 now adds these around the existing northbound route, without saved world locations. Current forces still include both assisting and opposing local zones; these do not yet define a consistent river network or whole-leg upstream travel.

## Sequence and scope

| Stage | Playable result | Boundary |
|---|---|---|
| 4A | Start menu and persistent settings | Existing missions and progression remain intact |
| 4B | Complete English/Russian interface | Includes drawn HUD, signs, notices and dynamic results |
| 4C | Engine, event sounds and looping music | Audible review and runtime performance are required |
| 5, next | A small connected river map with continuing departures and upstream/downstream legs | Separate route/location/save migration, described below |

Finish and review each increment before expanding it. Milestone 4 is the presentation/settings milestone, not an authorization to build milestone 5 simultaneously. No drones, combat, new cargo systems or procedural campaign are added here.

## 4A — enter the game and manage settings

First launch offers English and Russian, named clearly in their own languages. Default/fallback is English. Remember the selection. Subsequent launches open a compact start menu with **Play**, **Settings**, **Credits** and **Quit**. Play opens the existing cargo briefing with the saved engine and credits. Do not label it Resume: the current build does not save a boat halfway through a run.

Settings provide language and separate Master, Music and Effects volume controls; Effects includes the engine. A zero setting really mutes its bus. Music can be disabled independently. Defaults should be comfortable, with music below engine and important alerts. Keep the backtick FPS toggle and existing physical-key bindings. Keyboard navigation, focus and mouse use must all work, with a visible route back from Settings/Credits.

Keep R as return to the cargo briefing. Escape still pauses/resumes active play. The pause screen can open Settings and offer a clearly labeled **End run and return to menu** action: unfinished cargo is abandoned, committed support/ownership retained. Returning from Settings restores the previous paused/menu state; it must not silently resume simulation. Quit must not require issuing or rewarding a mission.

Menu, language chooser, Settings and Credits own their input. Existing global R/B/Enter/gear handlers cannot launch/reset a hidden mission, open its depot or mutate a paused run behind those screens. Enter may activate the focused UI control; Escape returns through the active UI before it can resume gameplay. Exercise these boundaries with physical-key events, not only direct button callbacks.

Store locale and volume in a small separate settings file, provisionally `user://settings.cfg`. Do not add them to the exact-schema version-2 progression document. Missing, corrupt or unwritable settings use safe defaults or retain the in-session choice with a clear localized notice; they must not reset credits or ownership. Progression reset remains the separate existing two-click depot action and does not erase language/audio preferences.

Automated checks isolate both settings and progression, including any settings/audio initialization that occurs before the main scene enters the tree. Tests must not alter the player's language, volumes or credits.

Exit evidence: actual menu → Settings → language/volume → Play → briefing → run → pause/settings → resume → end run/menu → Play, plus quit/relaunch. Verify saved settings, no accidental progression changes and no simulation while paused. Existing isolated scene fixtures may explicitly bypass the menu for focused checks; a separate physical UI scenario must exercise normal startup.

## 4B — English and Russian throughout the game

English remains the source language for code, identifiers, comments and documentation. Russian is an explicitly requested player-facing translation. Update repository language guidance accordingly; the old English-only UI rule must not block localization.

Use one translation catalog and stable message keys. Route, village, engine, order and receipt IDs stay language-independent. Language changes update the visible menu/HUD immediately; they must not rebuild the mission, change cargo, spend credits, reset a dock hold or issue a new mission ID.

Inventory all visible strings before translating:

- Menu, settings, controls, focus hints and depot buttons/comparisons.
- Briefing load cards, cargo/weight explanations, HUD speed/gear/distance and next objective.
- Luma/Koya signs, request/service labels and receiving-area text drawn by the renderer.
- Gear/direction feedback, docking threshold, unload progress and wrong-cargo/partial warnings.
- Delivery receipts, full/partial/failure results, profile recovery/write notices and reset confirmation.
- Credits, mute labels and any new settings errors.

Translate complete messages with validated placeholders, rather than concatenating translated fragments around English nouns. Check Russian quantity/plural forms where used; compact labeled counts are acceptable when natural. Use consistent glossary entries for support, gear, reverse, filters, food and landing names. Decide display translations/transliterations once, without changing saved IDs. Keep the application/working title Living River.

Use a font with verified Cyrillic coverage. Inspect both languages at 1280×720 and a smaller resized window; Russian text must wrap/reflow or use a suitable panel layout. Do not rely on current character-count truncation or simply shrink all text. Keep actions, numbers, recipients and save errors readable. Verify physical W/S/A/D, number-row/keypad gears, E, R, Escape and backtick on an active Russian keyboard layout; translated hints must still identify the bound keys.

Record any bundled font's license/provenance alongside other assets and include required attribution.

Exit evidence: actual English and Russian startup, load cards, full HUD, both docks, depot, pause/settings, full/partial/failure outcomes and save-failure notices. A bilingual reviewer/player checks meaning and naturalness; a catalog-completeness check cannot approve translation quality. Missing entries visibly fall back to English, never raw keys or empty labels. Reload preserves the chosen language and existing progression.

## 4C — hear the boat and the river journey

Add one continuous engine loop and one quiet, original or properly licensed instrumental music loop. The first music bed can cover menu and navigation, with smooth level changes; additional tracks are deferred. Engine, music and event sounds need separate playback so the current event-tone player cannot interrupt the engine or restart the music.

The engine has a low idle while a running boat is unpowered, rises smoothly under throttle and responds to gear/load. Base it on drive demand and selected gear, not actual ground speed alone: a drifting boat should idle, and a boat working against current can sound loaded while moving slowly. Reverse has the same intelligible throttle relationship. Do not add a speculative mechanical engine simulation; expose a few tunable audio parameters.

Engine fades out at the menu, pause and terminal states, returns smoothly on resume, and stops when fuel is exhausted. Music stays quieter than important cues, can continue softly through pause, and respects mute immediately. Restart/menu transitions cannot stack multiple loops. Gear shifts and existing collision/refuel/low-fuel/delivery cues remain distinguishable, with bounded simultaneous voices and sensible repetition limits.

Build/cache short event sounds and loop assets outside the frame loop. Engine pitch/volume updates are lightweight; no repeated waveform/file generation during rendering. Use seamless loop boundaries, short fades, conservative mix levels and no clipping. A simple original engine sample/synthesis render and original short score are acceptable prototype assets; record their actual origin. For external recordings/music, record author, exact source, license and required attribution under the audio asset folder, then show applicable credits. Do not ship reference tracks or assume a download is licensed.

Exit evidence requires listening, not only file existence or an amplitude check: cold start; at least three music/engine loop boundaries; idle → first/second gear throttle → brake/coast → reverse; current drift; pause/resume; both deliveries; failure; mute and reload. Ask the player about audible clicks, fatigue, cue clarity and balance. A critic who cannot hear the build records that limitation and cannot pass audible quality.

## Milestone 4 acceptance and review

- [ ] Existing third-step human cargo/handling feedback and post-fix performance feedback are obtained and any largest concrete gap addressed. Planning/independent work can proceed while feedback is pending; prior acceptance is not invented.
- [x] Actual menu/settings/briefing/pause/replay/quit flow works by keyboard and mouse without changing committed progression.
- [x] Language and volume survive relaunch. Missing/corrupt/unwritable settings do not erase player progress; progression reset leaves settings intact.
- [x] All user-visible game messages have complete English/Russian entries or intentional names/key symbols. Placeholders, Cyrillic font, Russian quantities and long text are verified in actual screens.
- [ ] A bilingual human reviews Russian meaning and readability, including dynamic failure/save messages and both load presets.
- [ ] Engine follows throttle/gear/load rather than current-driven ground speed; reverse, pause, failure and transitions behave audibly as specified.
- [ ] Music/engine loops are heard across multiple boundaries; mute, mix and important cues pass actual listening review. Asset licensing/provenance and credits are recorded.
- [ ] Both starter channels/loads and an upgraded run remain viable; profile receipts/migration, physical input and dock outcomes remain correct. Use focused regressions appropriate to the changes, preserving player saves.
- [ ] Compare original/fork/Luma/Koya frame time and p95 with audio enabled under the same settings; investigate repeatable additional regressions above 10%. Include a normal-settings real-time full run, report background load and retain rare stalls. Do not hide cost with lower physics frequency or fewer visual layers.
- [ ] Separate fresh critics review actual UI/localization, heard audio and persistence/performance evidence, then perform integrated review. Fix the largest evidenced gap and repeat until the applicable bar passes or the user stops.

Keep [workbench.md](workbench.md) current when implementation begins. Separate scripted/staged evidence from continuous routes, human feedback and heard-audio review. Do not certify unavailable listening, translation or human gates from screenshots/tests alone.

## Following milestone 5 — a river network that remembers arrival

The user's map extension is part of the concept direction. Start with an authored three-location network: **Base, Luma, Koya**, connected by two river reaches. Later expansion can add tributaries and other villages once continuity works. Show all three nodes, the boat's current safe landing, available delivery legs, flow arrows, upstream/downstream labels, estimated distance and available support. Selecting a contract from the current landing opens its load briefing. The current Base → Koya contract may traverse both reaches and retain Luma as an intermediate optional/full-load stop.

Successful arrival at Koya makes the next departure Koya. Offer a first return contract from Koya to Luma using a clearly stated locally available relief supply; arrival there unlocks departure from Luma. A subsequent Luma → Koya leg demonstrates chaining and the opposite travel direction. Use existing food/filters and a small authored contract board; defer a general economy, procedural map and unlimited mission generator. A source landing's supply and destination request must be named, rather than silently creating cargo wherever the boat appears.

### Define continuity before changing saves

Use a last-safe-landing checkpoint, not arbitrary in-river save positions. Initial/migrated players begin at Base while retaining credits, engines and mission-counter safety. Each successfully committed matching delivery at a safe dock can update the checkpoint; food at Luma can therefore remain the rescue/departure point after a later failure. Full or partial completion at Koya leaves the boat at Koya. Failure, R abandonment, menu exit or application restart return to the last committed safe landing, explained before abandoning an unfinished leg. No unearned reward or automatic completed leg is created by recovery.

Checkpoint changes and associated delivery rewards must commit consistently, with bounded receipts and safe retry on write failure. Define what docking without a matching request means explicitly before allowing it to move the checkpoint; do not silently change the existing no-matching-cargo behavior. A contract completed just before process exit must neither pay again nor send the boat back to Base on reload. A successful arrival without a reward, if supported, needs its own idempotent arrival rule.

Provisional resource rule: each named service landing includes clearly announced refuel/repair before departure, matching the current fresh-run resource model. Retain location, credits and engines between legs; do not quietly introduce carried-over damage/fuel or repair costs alongside route persistence. Change that economy only in a later reviewed step. Starting a new journey/resetting progression remains explicit and separate from Play/Continue or language settings.

### Make upstream a route property

On the provisional map, Base is downstream, Luma is intermediate and Koya is upstream. Current flows toward Base. Outbound Base/Luma → Koya legs work against current; Koya → Luma returns travel with it. Keep north up and the physical geography fixed so villages remain on their actual banks on return. Point the boat along departure travel, move camera look-ahead in that direction and keep W as forward throttle, S/Space as brakes, 9 as reverse, A/D as screen-left/right steering. Returning south is forward travel, not holding reverse for an entire mission.

This requires route data rather than only negating a speed: start/end coordinates, heading, bounds, objective distance/order, camera lead, dock approaches, pilot, HUD and visible boat orientation all currently assume northbound travel. Keep actual ground-speed/wake semantics and capsule collision agreement. Use the same world-space current field when traversing the same reach in either direction; do not flip flow with the mission to fake an upstream label.

The existing fork has a north-assisting rapids channel. It must be reconciled and retuned against the network's declared flow before being called a consistent upstream/downstream river. Show the flow on map and water, evaluate both directions, and explicitly document changes to the old assisting-channel balance. Do not assume the old branch times or fuel reserve still hold. A stronger-flow narrow passage may be attractive downstream and undesirable upstream; meaningful direction-specific choices take priority over mechanically mirroring the old shortcut. Tune current, route length, buoy access and still-water dock approaches so River Twin and available loads remain viable, provisionally with at least five fuel remaining on clean scripted runs. Record a human attempt in each direction.

### Milestone 5 implementation plan

The subsequent build is defined in [fifthSteps.md](fifthSteps.md), including an explicit empty Luma → Base return so Base and the fork are reachable downstream. It implements contract sources, incidental versus contract mooring, zero-reward arrival safety, location recovery and changed R/Play behavior. Its own acceptance requires actual map → contract → departure → arrival → map at the new landing → next leg; forward-driven return travel; consistent current/geography; measured starter viability both ways; migration and atomic reward/location failure tests; English/Russian/audio coverage; and comparable performance evidence. See the workbench for current fifth-milestone reviews; none certify pending human milestone-4 gates. Persistent village simulation, campaign reputation, free roaming and arbitrary save-anywhere behavior remain deferred.

## Ready-to-use implementation task

> Build Living River's fourth milestone in `doc/fourthSteps.md`, following `AGENTS.md`. Add a start menu, persistent English/Russian and audio settings, a complete Russian UI translation, an engine loop and quiet looping music around the existing relief runs. Preserve progression, controls, cargo/docking and the measured renderer optimizations. Milestone 5's map, saved locations and return routes are planning context, not part of this implementation. Choose small work units, use separate fresh-context critics for actual graphical, bilingual, audible and persistence/performance evidence, and fix the largest evidenced gap until the bar passes or I stop the run. Keep `doc/workbench.md` updated with actual builds, reviews and limitations; do not claim unperformed human/listening gates passed.

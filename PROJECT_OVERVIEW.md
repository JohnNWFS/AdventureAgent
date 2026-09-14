# AdventureAgent Project Overview

## What AdventureAgent is
AdventureAgent is a **single-room, single-controller GameMaker prototype** for a management-sim / strategy game where the player runs a fantasy adventurer agency (a guild office) rather than controlling characters directly in the field.

The game loop centers on office operations:
- unlocking patron contracts,
- selecting missions,
- assembling parties from adventurers,
- waiting for mission lifecycle updates,
- reacting to events, finances, and rival pressure.

## Core design pillars in the current build
The current implementation is focused on:
1. **Desk-centered command UI** (left/right information panels, center stage, bottom console + actions).
2. **Hybrid interaction model** (typed commands and clickable contextual action buttons).
3. **Time-based simulation** (hour ticks, day transitions, mission ETAs, contract expiries).
4. **Rival/world pressure** that continues even while the player is in other screens.
5. **Light personnel economy** (adventurer wages, commission, free-agent negotiation, injuries, retirements).

## Current architecture

### Runtime structure
The project is intentionally minimal:
- One project file (`AdventureAgent.yyp`),
- One room (`Room1`),
- One active object (`obj_heartbeat`).

All gameplay logic lives in `obj_heartbeat`'s events/scripts:
- `Create_0.gml`: bootstrap, data model, rules, simulation functions, command parsing, button wiring.
- `Step_0.gml`: text input handling, real-time heartbeat, scrolling, and click detection.
- `Draw_64.gml` (Draw GUI): full interface rendering.
- `Draw_0.gml`: empty/minimal world draw.

This is effectively a **monolithic simulation controller** pattern.

### State model
A single `state` struct acts as the source of truth and stores:
- clock/calendar values,
- resources (gold, reputation, debt),
- rosters (`adventurers`, `free_agents`),
- content (`patrons`, `contracts`, `missions`),
- mission lifecycle arrays (`active_missions`, `pending_reports`),
- UI/input state (buttons, logs, selected indices, input line),
- mode and minigame state,
- game-over flags.

### Mode system
`MODE` enums define top-level contexts:
- `PLANNING`,
- `BUYING` (free-agent market),
- placeholder business modes (`SELLING`, `CONTRACTING`, `PITCHING`, `ARGUING`, `SABOTAGE`),
- `MISSION_REVIEW`, `MISSION_RESULT`,
- `GAME_HOUSE`.

Only some modes currently have deep mechanics; others are scaffolds for roadmap expansion.

## Systems implemented so far

### 1) Contract + mission pipeline
- Patrons exist with personality/contact flavor.
- Contracts are generated from mission templates with randomized variants.
- Patron actions unlock contracts.
- Contracts can expire.
- Mission board is derived from unlocked, unaccepted, non-expired contracts.

### 2) Mission lifecycle (no instant resolve)
Starting a mission creates an active assignment with:
- outbound phase,
- objective checkpoint,
- return phase,
- due hour,
- periodic field updates,
- possible delay accumulation.

When due time is reached, mission resolution produces a report that must be acknowledged in `MISSION_RESULT` mode.

### 3) Mission simulation model
Mission outcome is based on:
- weighted party stats versus mission profile,
- reliability modifier,
- random roll,
- mission difficulty/risk,
- delay penalty.

Outcomes: success / partial / failure, with variable gold and reputation impact, plus injury chance.

### 4) Personnel progression and risk
- Adventurers can improve stats after successful missions.
- High-risk/high-difficulty jobs can produce stronger growth.
- Adventurers can become injured, unavailable (rival-poached), or retire at peak performance.

### 5) Finance model
- Starting gold/debt and recurring expenses.
- Monthly rent + annual tax events.
- Random minor operating gains/losses.
- Mission payout accounting includes adventurer day rates and agency commission cuts.
- Bankruptcy triggers game-over.

### 6) Rival/world pulse
A global pulse runs every few in-game hours and can:
- poach strong available adventurers,
- tighten contract deadlines,
- add/remove small amounts of gold,
- increase free-agent rival pressure.

This runs across modes, so the world keeps moving while player is occupied elsewhere.

### 7) Free-agent market and negotiation
Implemented negotiation includes:
- candidate generation with style/archetype,
- asking terms (bonus/rate/commission floor),
- offer scoring based on economics, reputation, and rival pressure,
- delayed decisions,
- possible counteroffers with deadlines,
- accept/decline flow and roster integration.

### 8) Game House side system
The office can visit a gambling venue with three minigames:
- Street Craps,
- Wyrm Wheel (roulette-like),
- Dragon 21 (blackjack-like).

Each action advances in-game time and therefore interacts with mission/world progression.

### 9) Input + UI
- Console command parser supports mission, patron, market, mode, and game-house commands.
- Button rail mirrors key actions contextually by mode.
- Layout is a polished panel dashboard with logs, mission details, ledger, and contract/world view.

## What appears to be complete vs. placeholder

### Built and playable now
- Core office loop,
- contract unlock/review,
- party assignment,
- time-driven mission lifecycle,
- result reports,
- free-agent negotiation,
- world/rival pulse,
- basic economy pressures,
- game-house detour mechanics.

### Clearly scaffolded / not yet fully realized
The roadmap (`TODO.md`) still calls out major pending work:
- richer time/calendar systems and overnight summaries,
- deeper rival agencies and strategic counterplay,
- expanded contract economics and consequences,
- full implementations for placeholder modes (selling, pitching, arguing, sabotage),
- save/load persistence and schema evolution,
- analytics/balancing tooling,
- larger content/data architecture externalized from code.

## Overall project vision (inferred)
The project seems aimed at a **"fantasy agency tycoon"**: a simulation-forward management game where tactical staffing, contract economics, and rival competition drive long-term progression.

Key directional themes visible in both code and roadmap:
- move from prototype hardcoded data to content-driven systems,
- deepen asynchronous world simulation and event reporting,
- increase strategic pressure via rivals, contracts, and staffing markets,
- preserve a "desk-command" fantasy (player as coordinator, not field hero),
- evolve toward a robust campaign loop with persistence and balancing telemetry.

In short: this is already a substantial prototype of the intended core loop, with the architecture currently optimized for speed of iteration rather than modularity.

## Recommended next implementation priorities
Based on current code shape and roadmap gaps, these are the highest-leverage next steps:

1. **Save/Load first**
   - Add minimal save slots + autosave at day end.
   - Persist the whole campaign state (clock, roster, missions, contracts, finances, logs, rivals, pending reports).
   - This is the clearest milestone that turns sessions from throwaway prototypes into long-run strategy gameplay.

2. **Externalize content to data files**
   - Move patrons, mission templates, candidate/name pools, and contract variants out of hardcoded GML and into datafiles.
   - Keep deterministic seed/debug support so balancing remains reproducible.
   - This dramatically increases iteration speed and designer throughput.

3. **Implement at least one placeholder strategic mode**
   - `PITCHING` and/or `SABOTAGE` are the most impactful first picks.
   - This closes the loop between rival pressure and player counterplay.
   - Existing `MODE` scaffolding is already in place.

4. **Deepen rivals from ambient pressure to visible actors**
   - Add named rival agencies with simple profiles.
   - Surface partial intel: active bids, poach attempts, contract contests.
   - Reuse the existing free-agent market pressure model to simulate contested hiring.

5. **Upgrade mission reports with narrative flavor tags**
   - Keep current quantitative result math.
   - Add lightweight report text variants by mission type/outcome/incidents.
   - This reinforces the desk-reports fantasy without needing field-scene rendering.

6. **Calibrate Game House risk/reward and strategic role**
   - Tune expected value and variance so it is neither dominant nor irrelevant.
   - Add context hooks (e.g., occasional intel opportunities, rival sightings, debt-recovery emergency use).
   - Preserve its current core strength: real opportunity cost via time advancement.

7. **Ship an overnight summary digest**
   - Morning rollup of: mission leg progress, market changes, rival moves, injuries/recovery, finance deltas.
   - This makes asynchronous world simulation legible and improves day-to-day pacing.

## Why this ordering
- **Save/load + data externalization** create production momentum and support tuning.
- **One strategic mode + richer rivals** materially increase game depth.
- **Narrative reporting + overnight digest** improve player clarity and emotional engagement.
- **Game House balancing** protects optional side content from destabilizing the economy loop.

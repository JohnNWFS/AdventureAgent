# Guild Agent - TODO Roadmap

This backlog translates the approved game direction into implementation milestones.

## 0. Current Prototype Baseline
- [x] Desk-centered UI shell with left/right panels and bottom operations console
- [x] Hybrid console: typed commands + contextual action buttons
- [x] Modes scaffolded, with active flow for PLANNING -> MISSION_REVIEW -> MISSION_RESULT
- [x] Mission simulation with weighted stats, risk, and injury outcomes

## 1. Immediate UX Fixes (Next)
- [ ] Replace instant mission completion with a mission lifecycle system
- [ ] Add in-UI mission timers (eta shown as days/hours)
- [ ] Add clear queue/status section for: preparing, in_progress, returning, completed
- [ ] Improve command vocabulary to use "START" language as primary and keep aliases for compatibility

## 2. Time Simulation Core (Priority)
### 2.1 World Clock
- [ ] Implement world time struct: year, season, day, hour
- [ ] Support variable mission durations (hours to weeks)
- [ ] Time advancement methods:
- [ ] Advance by 1 hour
- [ ] Advance to end of day
- [ ] Advance to next event completion

### 2.2 Day-End / Overnight Loop
- [ ] Add explicit "End Day" flow
- [ ] Simulate agent off-hours (office closed state)
- [ ] Run overnight maintenance pipeline:
- [ ] Injury recovery rolls
- [ ] Contract board refresh
- [ ] Rival activity updates
- [ ] Pending mission progress ticks
- [ ] Start-of-day summary report in console (overnight events digest)

### 2.3 Mission Lifecycle
- [ ] Add mission states: available, assigned, traveling, active, returning, resolved
- [ ] On "Start Mission", lock party members as on_mission
- [ ] Resolve mission only when ETA completes, not instantly
- [ ] Deliver result as inbound report/event on completion tick

## 3. Calendar, Seasons, and World Atmosphere
### 3.1 Calendar Systems
- [ ] Define calendar constants (days/season, seasons/year)
- [ ] Track seasonal tags and expose in mission generation
- [ ] Add seasonal contracts (harvest escort, winter supply, thaw road patrol, etc.)

### 3.2 Visual Atmosphere Layer (Placeholder-First)
- [ ] Add background ambience state: clear, cloudy, rain, fog, snow
- [ ] Daylight gradient transitions (sunrise/day/sunset/night)
- [ ] Subtle non-intrusive effects behind panels (no readability loss)

## 4. Roster Expansion and Personnel Systems
### 4.1 Large Adventurer Pool
- [ ] Move from fixed sample roster to generated + persistent roster entries
- [ ] Add hiring pipeline and candidate market
- [ ] Add roster pagination/filtering/sorting in UI
- [ ] Add naming pools and archetype templates for high variety

### 4.2 Adventurer Contract Pressure
- [ ] Track satisfaction/loyalty/contract terms
- [ ] Add events where rivals attempt poaching
- [ ] Add counter-offer mechanic and "let them go" branch

## 5. Rival Agent System (Core Strategy Layer)
### 5.1 Rival Models
- [ ] Add 1-3 rival agencies with simple strategy profiles
- [ ] Rival actions per cycle: underbid, poach attempt, sabotage rumor, patron pitch
- [ ] Add intel visibility (known vs unknown rival actions)

### 5.2 Player Responses
- [ ] Counteroffer flow
- [ ] Reputation defense actions
- [ ] Contract defense options
- [ ] Long-term rival relationship state (escalating competition)

## 6. Contracts and Market Dynamics
- [ ] Expand contract attributes: urgency, patron quality, legal risk, visibility
- [ ] Add contract expiry timers
- [ ] Add economy pressure on rewards and wages
- [ ] Add consequence chains for partial/failure outcomes

## 7. Mode Implementation Plan
Current placeholder modes should receive incremental functionality:
- [ ] BUYING: equipment, supplies, operational upgrades
- [ ] SELLING: excess gear, artifacts, captured intel
- [ ] CONTRACTING: hire/fire/negotiate adventurer terms
- [ ] PITCHING: secure patrons/contracts through persuasion
- [ ] ARGUING: dispute outcomes/penalties, legal negotiation minigame
- [ ] SABOTAGE: covert rival disruption (high risk/high consequence)

## 8. Data and Content Architecture
- [ ] Move sample data into datafiles/json for maintainability
- [ ] Define stable structs for save/load compatibility
- [ ] Introduce event log categories (mission, rival, finance, personnel, world)
- [ ] Add deterministic seed mode for balancing/debug

## 9. Save/Load and Persistence
- [ ] Add save slots and autosave at day-end
- [ ] Persist clock, missions, roster, rivals, finances, and logs
- [ ] Add migration/version tag for save schema updates

## 10. UI/UX Quality Passes
- [ ] Adaptive layout constraints so no action controls overlap input/log areas
- [ ] Replace bottom action paging with a mobile-friendly vertical action wheel/stack at bottom-right
- [ ] Add context label/header for action wheel and conditional up/down arrows when overflowing
- [ ] Support wheel/swipe-like scrolling behavior for action stack on desktop/mobile
- [ ] Tooltip/help glossary for stats and outcomes
- [ ] History browser for old reports and rival events
- [ ] Input command history and tab completion for console commands

## 11. Balancing and Telemetry
- [ ] Add debug panel with mission power breakdown and risk math
- [ ] Capture outcome rates by mission difficulty and party composition
- [ ] Tune economy, injury rates, and reliability impact with data

## 12. Test Checklist
- [ ] Mission assignment never resolves immediately
- [ ] Day-end correctly advances all active timers
- [ ] On-mission adventurers cannot be reassigned
- [ ] Acknowledge events are one-time and stateful
- [ ] Button panels remain bounded in all supported resolutions
- [ ] Rival poach/counteroffer flow works end-to-end

## Suggested Build Order (Practical)
1. Time Simulation Core + Mission Lifecycle (Sections 2.1 to 2.3)
2. Day-End Loop + Start-of-Day Reports (Section 2.2)
3. Large Roster Foundations + Rival Poaching v1 (Sections 4 and 5)
4. Seasonal/Calendar Content Gates (Section 3)
5. Expand placeholder modes one by one (Section 7)

## 13. Flavor and Narrative Messaging (New)
- [ ] Expand field communications system (pigeons, scrying, enchanted letters, dream-voice alerts)
- [ ] Add mission-leg reports: outbound, objective reached, return-leg incidents
- [ ] Introduce delay incidents pool (broken wagons, lame horses, weather, supply loss, rival interference)
- [ ] Ensure delays modify odds/timing without forcing deterministic auto-fail
- [ ] Add patron-funding economics: unused funded slots become agent margin (risk/reward pressure)
- [ ] Add clearer mission contract text for patron staffing cap and payout structure

## 14. Free-Agent Negotiation Refinements
- [ ] Add temperament chips and leverage hints directly in market UI (beyond log text)
- [ ] Add deeper personality dialogue variants and conditional bluff/intimidation beats
- [ ] Add multi-round offer memory so repeat lowballing changes candidate behavior
- [ ] Add rival named agents in negotiations with visible competing bid tiers

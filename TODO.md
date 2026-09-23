# Guild Agent - Prioritized Roadmap

This backlog is ordered by gameplay impact for a medieval-ish fantasy adventurer agency sim.

## 0. Current Playable Baseline
- [x] Desk-centered UI shell with bottom operations console and action wheel
- [x] Patron -> contract -> party -> launch drill-down flow
- [x] Recruit desk -> scout -> candidate -> offer -> counter -> sign drill-down flow
- [x] Mission travel / return lifecycle with field reports
- [x] Rival pressure, time pulse, and day progression
- [x] Adventurer purse tracking, kit basics, and file view

## 1. Client Contracts and Relationship Depth
- [x] Add represented-adventurer client contracts with:
- [x] Day rate
- [x] Agency commission
- [x] Contract term length
- [x] Exclusivity / representation type
- [x] Minimum activity expectations
- [x] Add trust and morale as separate values for each represented adventurer
- [x] Add client priorities such as:
- [x] Wants steady work
- [x] Wants prestige jobs
- [x] Avoids high-risk work
- [x] Wants larger personal payouts
- [ ] Add relationship changes from:
- [x] Idle time
- [x] Mission success/failure
- [x] Injury outcomes
- [x] Pay quality
- [x] Patron fit
- [x] Add renegotiation flow for existing clients
- [ ] Medieval fantasy dressing:
- [x] Guild charters
- [x] Sworn retainerships
- [x] Temple service oaths
- [x] Mercenary letters
- [x] Bardic sponsorship agreements

## 2. Morale, Usage Pressure, and Defection Risk
- [x] Expand idle-time complaints into escalating client pressure
- [x] Add "poachable star" behavior for famous or powerful clients
- [x] Add rival offers from lords, towers, temples, mercenary bands, and trade houses
- [x] Add burnout from overuse and resentment from repeated benching
- [x] Add departure warnings before a client leaves

## 3. Equipment, Kit, and Magic Inventory
- [x] Separate agency-owned gear from client-owned gear
- [ ] Add consumables:
- [x] Salves
- [x] Rations
- [x] Lockpicks
- [x] Ward scrolls
- [x] Healing kits
- [x] Add relic and magic-find categories
- [x] Add repair, replacement, and upgrade loops
- [x] Add equipment impact on mission scoring and injury reduction
- [ ] Medieval fantasy dressing:
- [x] Rune-etched shields
- [x] Abbey relics
- [x] Hedge charms
- [x] Dwarf-forged arms
- [x] Noble travel attire

## 4. Party Chemistry and Personality Synergy
- [ ] Add pair and party chemistry modifiers
- [x] Add personality conflict rules
- [x] Add shared-history bonuses from prior successful jobs
- [x] Add mentor/protege relationships
- [ ] Add role-combo synergy notes in roster and staffing views

## 5. Patron Depth and Patron Negotiation
- [x] Add patron satisfaction tracking
- [x] Add patron payment reliability and dispute likelihood
- [ ] Add pre-launch negotiation for:
- [x] Hazard premium
- [x] Urgency premium
- [x] Secrecy premium
- [x] Staffing cap flexibility
- [x] Add patron memory of prior wins, failures, and late deliveries
- [ ] Expand patron classes:
- [x] Abbots
- [x] Castellans
- [x] Guild factors
- [x] Harbor masters
- [x] Frontier wardens
- [x] Arcane colleges

## 6. Injury, Recovery, and Care
- [ ] Add injury tiers:
- [x] Minor
- [x] Serious
- [x] Lingering
- [x] Cursed
- [ ] Add treatment options:
- [x] Temple healing
- [x] Herbal care
- [x] Costly magical restoration
- [ ] Rest and rehab
- [x] Add long-term scars, stat penalties, or early retirement risks
- [x] Fix double escalation: resolve_active_mission raises the injury tier twice for one injury (once in the injury block, again after the report); keep one

## 7. Rival Agencies with Distinct Identities
- [x] Add named rival agencies with strategy profiles
- [ ] Add rival specialties:
- [x] Elite magical talent
- [x] Noble patronage
- [x] High-risk mercenary work
- [x] Cheap underbidding
- [x] Add direct competition on patrons and recruits
- [x] Add rumor, sabotage, and reputation warfare

## 8. Fame, Prestige, and Marketability
- [x] Add client fame and agency brand prestige
- [x] Add bardic rumor / tavern song / herald notice events
- [x] Add fame-driven patron offers and increased client demands
- [x] Add endorsements, sponsorships, and ceremonial invitations

## 9. Apprentice and Academy Pipeline
- [x] Add low-cost prospects and trainees
- [x] Add in-house development track for squires, acolytes, hedge apprentices, and wardens-in-training
- [x] Add training focus areas and growth paths
- [x] Add graduation into represented clients

## 10. Regional and Seasonal World Structure
- [ ] Add regions with different danger, patron, and gear profiles (a region is the country around a city in scr_cities; use its danger and patron_wealth)
- [ ] Add seasonal content gates:
- [x] Winter pass escorts
- [x] Spring goblin raids
- [x] Harvest protection
- [x] Dry-season ruin delves
- [x] Add regional reputation and travel flavor

## 11. Expanded Adventure Debriefs and Post-Contract Fallout
- [x] Add post-mission debrief choices
- [x] Add defend-team / blame-conditions / accept-loss / dispute-outcome branches
- [x] Add patron reaction consequences after debriefs
- [x] Add client reaction consequences after debriefs

## 12. Agency Operations and Staff
- [ ] Add hireable agency staff:
- [x] Clerks
- [x] Scouts
- [x] Quartermasters
- [x] Healers
- [x] Negotiators
- [x] Add office upgrade effects on recruitment, recovery, and patron trust

## 13. Law, Guild, and Politics
- [x] Add guild license systems, dues, and inspections
- [x] Add contract disputes and arbitration
- [x] Add blacklisting, sanctions, and noble favoritism
- [x] Add civic / church / guild political factions

## 14. World Customization and XML Content Packs
- [x] Add XML-driven content packs for:
- [x] Adventurer names
- [x] Patron names and titles
- [x] Place names
- [x] Weapons
- [x] Outfits
- [x] Relics and spell names
- [x] Mission flavor text
- [x] Rival agency names
- [ ] Support base world + optional theme packs
- [ ] Add example packs:
- [x] Generic medieval fantasy
- [x] Tolkien-esque inspired naming and place flavor
- [x] Grim mercenary variant
- [x] Keep simulation math in code while externalizing flavor/content data

## 15. Save/Load and Content Versioning
- [ ] Save roster contracts, morale, trust, client assets, and world content pack choice
- [x] Save active missions, patron state, rival state, and logs
- [x] Add schema versioning / migration support

## 16. UI/UX Refinement
- [ ] Add summary panes for:
- [x] Current client morale/trust
- [x] Patron satisfaction
- [x] Rival threat
- [ ] Agency finances
- [x] Add history browser for contracts, client changes, and rival incidents
- [x] Add tooltips / glossary for morale, trust, and contract terms

## 17. Balancing and Debugging
- [x] Add debug overlays for mission scoring and negotiation scoring
- [ ] Add telemetry for:
- [x] Retention rates
- [x] Average client earnings
- [x] Patron satisfaction distribution
- [x] Injury rate by mission type
- [x] Tune economy, morale decay, and rival pressure with data

## 18. Cities and Career Expansion
Foundation: scripts/scr_cities (state.cities, city_id on adventurers/patrons/contracts, travel,
transfers, expedition costs, CITIES and TRANSFER commands). Build on its helpers
(mark_city_known, add_city_contract, add_city_patron, start_city_transfer, adventurer_city_id,
contract_city_id, city_name); never hand-build city, contract, or patron structs.
- [x] City data: home city plus three rumored cities with theme, prestige requirement, travel days and cost, lodging, patron wealth, and danger
- [x] Every adventurer, patron, and contract carries a city_id (defaults to the home city)
- [x] Transfers between cities with travel time and road cost (TRANSFER <n> <city>)
- [x] Relocation willingness from morale, trust, ambition, and annoyance; reluctant clients need a relocation purse (TRANSFER <n> <city> PAY)
- [x] Expeditions: party members based elsewhere pay road and lodging, travel time is added, and they stay staged in the contract city afterwards
- [x] CITIES command lists known cities, their costs, and who is based where
- [ ] Stage 1 - Rumors:
- [x] Correspondence and field reports mention other cities; call mark_city_known the first time each is heard of
- [x] Patron gossip about other cities during patron research and contract review
- [x] Rival news from other cities (a rival agency expands there, a city event changes its demand)
- [ ] Bardic and herald notices carry the agency's fame to known cities
- [ ] Stage 2 - Expeditions:
- [x] Known cities send contracts once agency reputation reaches the city's prestige_required (use add_city_contract)
- [x] Each city's contracts follow its theme (frontier hazard work, canal trade escorts, temple archive recoveries)
- [x] City danger raises mission risk and injury chance for missions in that city
- [x] Post-mission choice for an away party: stay staged in that city or travel home (start_city_transfer)
- [ ] Stage 3 - Outposts:
- [x] Mission board and party selection show which city each contract and adventurer is in
- [x] Adventurer cards show where the client is based and any travel in progress
- [x] Local patrons for each city (use add_city_patron); new-city patrons start with lower satisfaction and less trust
- [x] Morale pressure for clients left far from home too long
- [x] Recruit local free agents in the city where your staged clients are
- [ ] Stage 4 - Branch offices and relocation:
- [x] Open a branch office in a known city once prestige allows (setup cost and daily upkeep)
- [ ] Branch delegation policies instead of duplicate micromanagement
- [x] Relocate the agency headquarters (change home_city_id) as a fresh start; clients decide whether to follow
- [x] Cities in XML content packs (names, themes, descriptions)

## 19. Campaign Depth (from the design backlog)
Each item is one slice: a rule the player can feel, reported in one console line. Prefer connecting
two systems that already exist over new meters. Backlog numbers in brackets.
- [x] Party-size opportunity cost: extra members raise wages and payout splits so a smaller expert team wins some contracts [3]
- [x] Assignment forecast before launch: broad fit, wage exposure, injury risk and missing capability, without exact numbers [4]
- [x] Morning briefing: one daily digest of deadlines, returning missions, injuries, rival moves and net finances [5]
- [x] Adventurer traits: six readable traits that each change a mission outcome and a relationship choice [7]
- [x] Patron fit: a patron or mission at odds with an adventurer's priorities moves their morale and trust, with the reason given [9]
- [x] Mission incidents built from facts: reports use the real party, gear, delays and outcome [13]
- [x] Structured history ledger: filter missions, finances, relationship changes and rival incidents by day and cause [15]
- [x] Campaign objective: a 30-day restoration goal with solvency warnings and optional endless play [16]
- [x] Rival contract bids: a premium contract names a competing agency and a deadline; improve terms or walk away [17]
- [x] Actionable poach offers: a named rival bid with a deadline and choices to counter, promise work or release gracefully [18]
- [x] Pitching mode: choose one agency strength and cite prior work to win a patron; failure costs time [19]
- [x] Rumor and intelligence economy: information carries source, confidence and expiry; research and scouting trade time and gold for reliability [20]
- [x] Mid-mission intervention: reinforce, spend supply, authorize retreat or stay the course, with the cost stated [21]
- [x] Relic disposition: assign, keep, return or sell notable finds; routine loot handles itself [24]
- [x] Branching office upgrades: recruitment, care or patron relations branches that create identity instead of a buy-everything ladder [26]
- [x] Fame with expectations: fame unlocks prestigious offers while raising wages, ambitions and poaching pressure [27]
- [x] Linked contract chains: an outcome unlocks an authored follow-up that tolerates refusal and branches on success or failure [31]
- [x] Game House social layer: patrons, rivals and informants appear there; gambling stays optional [32]
- [x] Priority dashboard: at most five ranked issues, each with why it matters now and a direct action [33]
- [x] Agency doctrine: an identity such as honorable, elite or civic service that grants benefits and closes other options [35]
- [x] Campaign crisis arc: a seasonal threat that alters mission supply, patrons and rivals, with choices carried to its finale [37]

## 20. Later Campaign Systems (design backlog, second pass)
Same rules as section 19: one slice each, a rule the player feels, reported in one console line.
- [x] Roster health summary: one console line per client with morale, trust and days idle when the roster opens [15]
- [x] Finance summary: gold, owed, weekly wage burn and last week's net, printed on request and at day end [15]
- [x] Gear procurement: a rotating market with batch repair priced by condition, no per-item clicking [23]
- [x] Seasonal operations: each season changes which mission families appear and one visible constraint [29]
- [ ] Dynamic contract market: scarcity and rewards shift with season, crises and rival strategy [41]
- [x] Retirement and legacy: a retiring veteran becomes staff, a mentor or a named contact based on their history [42]
- [x] Insurance and liability: one seasonal policy decision that changes injury costs and dispute outcomes [43]
- [x] Scenario starts: seeded starts that vary debt, roster and rivals while reusing the same rules [44]
- [x] Multiple endings: evaluate solvency, reputation, patron network, roster loyalty and rival standing separately [45]
- [x] Rival diplomacy: joint operations, lead trades and settlements anchored to remembered outcomes [39]
- [ ] Factions and licenses: guild, church, civic and noble standing that opens work and creates conflicts [38]
- [ ] Apprentice academy: term-level recruiting and training with future value against present wage cost [36]
- [ ] External content pass: move patrons, locations, incidents and relics into validated XML, formulas stay in code [34]

## 21. Interface and Art
Foundation: scripts/scr_ui (ui_theme, ui_panel, ui_label, ui_row, ui_bar, the portrait stage and the
LAYOUT report). Build screens from those helpers, put colours in ui_theme, and never hand-roll
rectangles. LAYOUT must report 0 problems after your change.
- [x] Shared theme, panel and row helpers callable from anywhere
- [x] LAYOUT command: panels, overlaps and overflowing text as console lines
- [x] Portrait stage: a patron or client slides into the centre panel when you open their file
- [ ] Draw the Guild Ledger panel with ui_row and ui_bar so morale and trust read as bars, not numbers
- [ ] Agency finances in the ledger panel: gold, owed, weekly wage burn and last week's net, using ui_row
- [ ] Fix the card gallery overlaps: buttons print over text in every column; LAYOUT must end at 0 problems
- [ ] Put the prospect on the portrait stage while scouting, and the rival agent during rival news
- [x] Show the returning party on the portrait stage when a mission resolves
- [ ] Desk scene in the centre panel: a desk drawn with ui helpers, with props that follow state (letters waiting, ledger open when gold is owed, lamp lit at night)
- [ ] Agent poses by mode: reading letters in contracting, at the wall map during a mission, counting coin at day end
- [ ] Contract location strip across the top of the centre panel: road, ruin, chapel or harbour by mission type
- [ ] Mode-specific centre panel: the centre shows the current screen's content instead of the same four lines everywhere

## Immediate Build Order
1. Client contracts and relationship depth
2. Morale / usage pressure / defection risk
3. Equipment / kit / magic inventory
4. Party chemistry and personality synergy
5. Patron depth and patron-side negotiation
6. XML content pack scaffold and first externalized flavor pools
7. Cities stage 1 (rumors), then stages 2-4 in order

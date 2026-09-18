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
- [ ] Add burnout from overuse and resentment from repeated benching
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
- [ ] Add repair, replacement, and upgrade loops
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
- [ ] Add mentor/protege relationships
- [ ] Add role-combo synergy notes in roster and staffing views

## 5. Patron Depth and Patron Negotiation
- [x] Add patron satisfaction tracking
- [x] Add patron payment reliability and dispute likelihood
- [ ] Add pre-launch negotiation for:
- [ ] Hazard premium
- [ ] Urgency premium
- [ ] Secrecy premium
- [x] Staffing cap flexibility
- [x] Add patron memory of prior wins, failures, and late deliveries
- [ ] Expand patron classes:
- [x] Abbots
- [ ] Castellans
- [ ] Guild factors
- [ ] Harbor masters
- [ ] Frontier wardens
- [ ] Arcane colleges

## 6. Injury, Recovery, and Care
- [ ] Add injury tiers:
- [x] Minor
- [ ] Serious
- [x] Lingering
- [ ] Cursed
- [ ] Add treatment options:
- [ ] Temple healing
- [ ] Herbal care
- [ ] Costly magical restoration
- [ ] Rest and rehab
- [ ] Add long-term scars, stat penalties, or early retirement risks

## 7. Rival Agencies with Distinct Identities
- [ ] Add named rival agencies with strategy profiles
- [ ] Add rival specialties:
- [x] Elite magical talent
- [ ] Noble patronage
- [ ] High-risk mercenary work
- [ ] Cheap underbidding
- [ ] Add direct competition on patrons and recruits
- [ ] Add rumor, sabotage, and reputation warfare

## 8. Fame, Prestige, and Marketability
- [ ] Add client fame and agency brand prestige
- [ ] Add bardic rumor / tavern song / herald notice events
- [x] Add fame-driven patron offers and increased client demands
- [x] Add endorsements, sponsorships, and ceremonial invitations

## 9. Apprentice and Academy Pipeline
- [ ] Add low-cost prospects and trainees
- [x] Add in-house development track for squires, acolytes, hedge apprentices, and wardens-in-training
- [x] Add training focus areas and growth paths
- [ ] Add graduation into represented clients

## 10. Regional and Seasonal World Structure
- [ ] Add regions with different danger, patron, and gear profiles
- [ ] Add seasonal content gates:
- [x] Winter pass escorts
- [x] Spring goblin raids
- [x] Harvest protection
- [x] Dry-season ruin delves
- [ ] Add regional reputation and travel flavor

## 11. Expanded Adventure Debriefs and Post-Contract Fallout
- [x] Add post-mission debrief choices
- [x] Add defend-team / blame-conditions / accept-loss / dispute-outcome branches
- [ ] Add patron reaction consequences after debriefs
- [ ] Add client reaction consequences after debriefs

## 12. Agency Operations and Staff
- [ ] Add hireable agency staff:
- [ ] Clerks
- [ ] Scouts
- [ ] Quartermasters
- [ ] Healers
- [ ] Negotiators
- [ ] Add office upgrade effects on recruitment, recovery, and patron trust

## 13. Law, Guild, and Politics
- [ ] Add guild license systems, dues, and inspections
- [ ] Add contract disputes and arbitration
- [x] Add blacklisting, sanctions, and noble favoritism
- [ ] Add civic / church / guild political factions

## 14. World Customization and XML Content Packs
- [x] Add XML-driven content packs for:
- [x] Adventurer names
- [ ] Patron names and titles
- [ ] Place names
- [ ] Weapons
- [ ] Outfits
- [ ] Relics and spell names
- [ ] Mission flavor text
- [x] Rival agency names
- [ ] Support base world + optional theme packs
- [ ] Add example packs:
- [ ] Generic medieval fantasy
- [ ] Tolkien-esque inspired naming and place flavor
- [ ] Grim mercenary variant
- [x] Keep simulation math in code while externalizing flavor/content data

## 15. Save/Load and Content Versioning
- [ ] Save roster contracts, morale, trust, client assets, and world content pack choice
- [ ] Save active missions, patron state, rival state, and logs
- [ ] Add schema versioning / migration support

## 16. UI/UX Refinement
- [ ] Add summary panes for:
- [ ] Current client morale/trust
- [x] Patron satisfaction
- [ ] Rival threat
- [ ] Agency finances
- [ ] Add history browser for contracts, client changes, and rival incidents
- [ ] Add tooltips / glossary for morale, trust, and contract terms

## 17. Balancing and Debugging
- [x] Add debug overlays for mission scoring and negotiation scoring
- [ ] Add telemetry for:
- [x] Retention rates
- [ ] Average client earnings
- [ ] Patron satisfaction distribution
- [ ] Injury rate by mission type
- [x] Tune economy, morale decay, and rival pressure with data

## Immediate Build Order
1. Client contracts and relationship depth
2. Morale / usage pressure / defection risk
3. Equipment / kit / magic inventory
4. Party chemistry and personality synergy
5. Patron depth and patron-side negotiation
6. XML content pack scaffold and first externalized flavor pools

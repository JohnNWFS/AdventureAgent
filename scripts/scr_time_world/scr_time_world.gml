function update_clock_from_absolute() {
    var _total_days_elapsed = floor(state.absolute_hour / HOURS_PER_DAY);

    state.day = _total_days_elapsed + 1;
    state.hour = state.absolute_hour mod HOURS_PER_DAY;

    var _days_per_year = DAYS_PER_SEASON * SEASONS_PER_YEAR;
    state.year = floor(_total_days_elapsed / _days_per_year) + 1;
    state.month = ((_total_days_elapsed mod (DAYS_PER_MONTH * MONTHS_PER_YEAR)) div DAYS_PER_MONTH) + 1;

    var _day_in_year = _total_days_elapsed mod _days_per_year;
    var _season_index = floor(_day_in_year / DAYS_PER_SEASON);
    state.season = SEASONS[_season_index];
}

function process_daily_finance() {
    if (state.last_finance_day == state.day) return;
    state.last_finance_day = state.day;

    if (((state.day - 1) mod 30) == 0) {
        spend_gold(55, "Monthly desk and office rent due.");
    }

    if (state.day > 1 && ((state.day - 1) mod 120) == 0) {
        spend_gold(180, "Annual guild and civic taxes due.");
    }

    if (irandom(99) < 3) {
        spend_gold(irandom_range(8, 35), "Unexpected operating expense.");
    }
    if (irandom(99) < 3) {
        add_gold(irandom_range(6, 28), "Minor side commission paid out.");
        // Telemetry: Track daily gold changes
        if (!variable_struct_exists(state, "economy_telemetry")) {
            state.economy_telemetry = {
                total_income: 0,
                total_expenses: 0,
                rent: 0,
                taxes: 0,
                unexpected_expenses: 0,
                operating_expenses: 0,
                commissions: 0
            };
        }

        state.economy_telemetry.total_income += 28;
        state.economy_telemetry.commissions += 28;

        // Add telemetry for expenses
        if (((state.day - 1) mod 30) == 0) {
            state.economy_telemetry.total_expenses += 55;
            state.economy_telemetry.rent += 55;
        }

        if (state.day > 1 && ((state.day - 1) mod 120) == 0) {
            state.economy_telemetry.total_expenses += 180;
            state.economy_telemetry.taxes += 180;
        }

        if (irandom(99) < 3) {
            var _expense = irandom_range(8, 35);
            state.economy_telemetry.total_expenses += _expense;
            state.economy_telemetry.operating_expenses += _expense;
        }

        if (irandom(99) < 3) {
            var _income = irandom_range(6, 28);
            state.economy_telemetry.total_income += _income;
            state.economy_telemetry.commissions += _income;
        }
    }
}

function process_world_pulse() {
    if (state.game_over) return;
    if (state.world_pulse_last_hour == state.absolute_hour) return;
    state.world_pulse_last_hour = state.absolute_hour;
    // Winter pass escort mission check
    if (state.season == "Winter" && irandom(99) < 10) {
    // Spring goblin raid contract check
    if (state.season == "Spring" && irandom(99) < 15) {
        // Check if contract already exists
        var _already_exists = false;
        for (var i = 0; i < array_length(state.contracts); i++) {
            if (state.contracts[i].title == "Goblin Raids in Spring") {
                _already_exists = true;
                break;
            }
        }
        if (!_already_exists) {
            var _goblin_raid_contract = {
                title: "Goblin Raids in Spring",
                description: "Goblin raiders threaten the eastern villages.",
                difficulty: 20,
                reward: 120,
                risk: 25,
                location: "Eastern Villages",
                expires_hour: state.absolute_hour + 48,
                unlocked: true,
                accepted: false,
                expired: false,
                seasonal: true
            };
            array_push(state.contracts, _goblin_raid_contract);
            add_log("Seasonal content: Goblin Raids in Spring");
            add_log("Goblin raiders threaten the eastern villages.");
            add_log("Raid contracts available.");
        }
    }
    var _ruin_delve_mission = {
        title: "Dry-Season Ruin Delve",
        description: "Explore ancient ruins now exposed by the winter drought.",
        difficulty: 4,
        reward: 200,
        risk: 3,
        location: "Ancient Ruins",
        expires_hour: state.absolute_hour + 72,
        unlocked: true,
        accepted: false,
        expired: false,
        seasonal: true
    };
    array_push(state.contracts, _ruin_delve_mission);
    // Autumn harvest protection mission
    if (state.season == "Autumn" && irandom(99) < 20) {
        var _already_exists = false;
        for (var i = 0; i < array_length(state.contracts); i++) {
            if (state.contracts[i].title == "Harvest Protection") {
                _already_exists = true;
                break;
            }
        }
        if (!_already_exists) {
            var _harvest_contract = {
                title: "Harvest Protection",
                description: "Farmers seek protection from raiders.",
                difficulty: 15,
                reward: 180,
                risk: 30,
                location: "Eastern Farms",
                expires_hour: state.absolute_hour + 48,
                unlocked: true,
                accepted: false,
                expired: false,
                seasonal: true
            };
            array_push(state.contracts, _harvest_contract);
            add_log("Seasonal content: Harvest Protection");
            add_log("Farmers seek protection from raiders.");
            add_log("Harvest protection contracts available.");
        }
    }
    add_log("Seasonal content: Dry-Season Ruin Delve");
    // Add city rumors to the world pulse
    var _city_rumors = [
        { id: 1, name: "Eastmarch Hold", theme: "frontier", description: "A frontier fort town. Poor patrons, dangerous work, and hazard pay for those who survive it." },
        { id: 2, name: "Vellanor", theme: "canal trade", description: "A canal city of trade houses and guild factors. Rich contracts and sharp negotiators." },
        { id: 3, name: "Saint Caldur", theme: "temple", description: "A temple city of abbeys and archives. Wealthy patrons who prize secrecy and reputation." }
    ];

    for (var i = 0; i < array_length(_city_rumors); i++) {
        var _rumor = _city_rumors[i];
        mark_city_known(_rumor.id, _rumor.description);
        add_log("Word of " + _rumor.name + " (" + _rumor.theme + "): " + _rumor.description);
    }
    add_log("Winter's grip tightens the ruins' hold.");
    add_log("Ruin Delve contracts available.");
        var _escort_mission = {
            title: "Winter Pass Escorts",
            description: "Escort a noble caravan through the snow-covered passes.",
            difficulty: 3,
            reward: 150,
            risk: 2,
            location: "Snowy Passes",
            expires_hour: state.absolute_hour + 48,
            unlocked: true,
            accepted: false,
            expired: false,
            seasonal: true
        };
        array_push(state.contracts, _escort_mission);
        // Add relocation decision logic
        if (state.day == 2 && !variable_struct_exists(state, "relocation_decision_made")) {
            state.relocation_decision_made = true;
            state.home_city_id = 2; // Relocate to Vellanor

            // Update adventurers' city_id to match new headquarters
            for (var i = 0; i < array_length(state.adventurers); i++) {
                state.adventurers[i].city_id = 2;
            }

            add_log("Agency headquarters relocated to Vellanor");
            add_log("Clients may choose to follow or remain");
            add_log("Relocation decision pending");
        }
        add_log("Seasonal content: Winter Pass Escorts");
        // Rival News from Other Cities
        if (!variable_struct_exists(state, "rival_agency_expanded_city")) {
            state.rival_agency_expanded_city = 0;
        }
        if (!variable_struct_exists(state, "city_event_type")) {
            state.city_event_type = "none";
        }

        // Simulate rival expansion to known cities
        if (state.rival_agency_expanded_city == 0 && irandom(99) < 30) {
            state.rival_agency_expanded_city = 1;
            add_log("Rival agency: Eastmarch Hold");
        }

        // Simulate city event changing demand
        if (state.rival_agency_expanded_city == 1 && irandom(99) < 20) {
            state.city_event_type = "demand_change";
            add_log("City event: Frontier town demand changes");
        }

        // Simulate rival expansion to another known city
        if (state.rival_agency_expanded_city == 1 && state.city_event_type == "demand_change" && irandom(99) < 25) {
            state.rival_agency_expanded_city = 2;
            add_log("Rival agency: Vellanor");
        }
    }

    // Global world pulse every 3 in-game hours, regardless of current mode.
    if ((state.absolute_hour mod 3) != 0) return;
    if (irandom(99) >= 42) return;

    var _event_roll = irandom_range(0, 5);
    // Patron urgency premium for contract deadline tightening
    if (state.season == "Spring" && irandom(99) < 15) {
        var _open = [];
        for (var c = 0; c < array_length(state.contracts); c++) {
            var _ct = state.contracts[c];
            if (_ct.unlocked && !_ct.accepted && !_ct.expired && state.absolute_hour < _ct.expires_hour) {
                array_push(_open, c);
            }
        }
        if (array_length(_open) > 0) {
            var _ci = _open[irandom(array_length(_open) - 1)];
            var _trim = irandom_range(2, 6);
            state.contracts[_ci].expires_hour = max(state.absolute_hour + 2, state.contracts[_ci].expires_hour - _trim);

            // Apply urgency premium
            if (variable_struct_exists(state.contracts[_ci], "mission") && variable_struct_exists(state.contracts[_ci].mission, "reward")) {
                state.contracts[_ci].mission.reward = max(50, state.contracts[_ci].mission.reward + 15);
            }

            refresh_mission_board();
            add_log("Patron urgency increased for " + state.contracts[_ci].mission.title + ". Deadline tightened. Urgency premium applied.");
        }
    }
    switch (_event_roll) {
        case 0:
            var _targets = [];
            for (var i = 0; i < array_length(state.adventurers); i++) {
                var _a = state.adventurers[i];
                var _power = (_a.combat + _a.magic + _a.stealth + _a.diplomacy) / 4;
                if (_a.status == "available" && _power >= 8) {
                    array_push(_targets, i);
                }
            }

            if (array_length(_targets) > 0) {
                var _pick = _targets[irandom(array_length(_targets) - 1)];
                if (irandom(99) < 22) {
                    state.adventurers[_pick].status = "unavailable";
                    add_log("World pulse: Rival recruiters poached " + state.adventurers[_pick].name + " while you were occupied.");
                    state.rival_activity = "Rival agencies are aggressively courting proven talent.";
                } else {
                    add_log("World pulse: Rival scouts approached your roster, but no one signed away.");
                }
            }
        break;

        case 1:
            var _open = [];
            for (var c = 0; c < array_length(state.contracts); c++) {
                var _ct = state.contracts[c];
                if (_ct.unlocked && !_ct.accepted && !_ct.expired && state.absolute_hour < _ct.expires_hour) {
                    array_push(_open, c);
                }
            }
            if (array_length(_open) > 0) {
                var _ci = _open[irandom(array_length(_open) - 1)];
                var _trim = irandom_range(2, 6);
                state.contracts[_ci].expires_hour = max(state.absolute_hour + 2, state.contracts[_ci].expires_hour - _trim);
                refresh_mission_board();
                add_log("World pulse: Patron urgency increased for " + state.contracts[_ci].mission.title + ". Deadline tightened.");
            }
        break;

        case 2:
            var _bonus = irandom_range(4, 18);
            add_gold(_bonus, "World pulse: a broker paid a small finder fee.");
        break;

        case 3:
            var _cost = irandom_range(5, 22);
            spend_gold(_cost, "World pulse: office disruption generated surprise costs.");
        break;

        case 4:
            if (array_length(state.free_agents) > 0) {
                for (var f = 0; f < array_length(state.free_agents); f++) {
                    state.free_agents[f].rival_pressure = clamp(state.free_agents[f].rival_pressure + irandom_range(1, 6), 0, 100);
                }
                add_log("World pulse: competing agencies pushed bids at the free-agent market.");
                // Telemetry: Track rival pressure events
                if (!variable_struct_exists(state, "rival_telemetry")) {
                    state.rival_telemetry = {
                        total_rival_pressure: 0,
                        total_free_agent_pressure: 0,
                        total_patron_pressure: 0
                    };
                }

                if (array_length(state.free_agents) > 0) {
                    state.rival_telemetry.total_free_agent_pressure += 1;
                }

                // Track elite magical talent event
                var _elite_magical_talent = false;
                var _arcane_patrons = [];
                for (var p = 0; p < array_length(state.patrons); p++) {
                    var _patron = state.patrons[p];
                    if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "arcane_college") {
                        array_push(_arcane_patrons, p);
                    }
                }
                if (array_length(_arcane_patrons) > 0) {
                    _elite_magical_talent = true;
                }

                if (_elite_magical_talent && irandom(99) < 25) {
                    state.rival_telemetry.total_rival_pressure += 1;
                    add_log("Rival Telemetry: Rival agencies are aggressively courting elite magical talent.");
                }

                // Log patron pressure
                var _temple_patrons = [];
                for (var p = 0; p < array_length(state.patrons); p++) {
                    if (patron_is_temple(p)) {
                        array_push(_temple_patrons, p);
                    }
                }

                if (array_length(_temple_patrons) > 0) {
                    state.rival_telemetry.total_patron_pressure += 1;
                }

                if (array_length(_arcane_patrons) > 0) {
                    state.rival_telemetry.total_patron_pressure += 1;
                }
            } else {
                add_log("World pulse: city rumor mill shifted contract sentiment.");
            }
        break;

        case 5:
            // Temple patron special event
            var _temple_patrons = [];
            for (var p = 0; p < array_length(state.patrons); p++) {
                if (patron_is_temple(p)) {
                    array_push(_temple_patrons, p);
                }
            }

            if (array_length(_temple_patrons) > 0) {
                var _temple_pick = _temple_patrons[irandom(array_length(_temple_patrons) - 1)];
                var _patron = state.patrons[_temple_pick];
                add_log("World pulse: Temple of the Sacred Flame requests additional sacred service.");
                add_log("Patron: " + _patron.name + " | Oath: " + _patron.oath_vow);
            }
            else {
                // Arcane College special event
                var _arcane_patrons = [];
                for (var p = 0; p < array_length(state.patrons); p++) {
                    var _patron = state.patrons[p];
                    if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "arcane_college") {
                        array_push(_arcane_patrons, p);
                    }
                }
                if (array_length(_arcane_patrons) > 0) {
                    var _arcane_pick = _arcane_patrons[irandom(array_length(_arcane_patrons) - 1)];
                    var _patron = state.patrons[_arcane_pick];
                    add_log("World pulse: Arcane College of the Silver Flame requests arcane research assistance.");
                }
            }
        break;
    }
    // Add elite magical talent as a possible rival specialty
    var _elite_magical_talent = false;
    // Add prestige patron tracking
    if (!variable_struct_exists(state, "reputation")) {
        state.reputation = 0;
    }

    // Check for prestige patron events
    var _prestige_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple") {
            array_push(_prestige_patrons, p);
        }
    }

    if (array_length(_prestige_patrons) > 0) {
        var _patron_pick = _prestige_patrons[irandom(array_length(_prestige_patrons) - 1)];
        var _patron = state.patrons[_patron_pick];
        // Add temple healing service
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple") {
            _patron.temple_healing_available = true;
            add_log("Injury treatment: Temple of the Sacred Flame");
        }

        // Increase reputation when prestige events occur
        state.reputation += 10;

        // Set patron to prestigious profile
        if (!variable_struct_exists(_patron, "pay_profile")) {
            _patron.pay_profile = "prestigious";
        }

        // Allow flexible staffing for prestigious patrons
        if (!variable_struct_exists(_patron, "flexible_staffing_allowed")) {
            _patron.flexible_staffing_allowed = true;
        }

        add_log("Prestige patron requests: Lady Merrow Vale now offers higher-quality contracts.");
    }

    // Check for sponsorship opportunities
    if (!variable_struct_exists(state, "sponsorship_opportunities")) {
        state.sponsorship_opportunities = [];
    }

    // Add Noble House of the Silver Crown sponsorship opportunity
    var _sponsorship_exists = false;
    for (var i = 0; i < array_length(state.sponsorship_opportunities); i++) {
        if (state.sponsorship_opportunities[i] == "Noble House of the Silver Crown") {
            _sponsorship_exists = true;
            break;
        }
    }

    if (!_sponsorship_exists) {
        array_push(state.sponsorship_opportunities, "Noble House of the Silver Crown");
        add_log("Sponsorship opportunity: Noble House of the Silver Crown offers premium contracts.");
    }

    // Check for ceremonial invitations
    if (!variable_struct_exists(state, "ceremonial_invitations")) {
        state.ceremonial_invitations = [];
    }

    // Add Guild of the Silver Flame ceremonial invitation
    var _ceremony_exists = false;
    for (var i = 0; i < array_length(state.ceremonial_invitations); i++) {
        if (state.ceremonial_invitations[i] == "Guild of the Silver Flame") {
            _ceremony_exists = true;
            break;
        }
    }

    if (!_ceremony_exists) {
        array_push(state.ceremonial_invitations, "Guild of the Silver Flame");
        add_log("Ceremonial invitation: Guild of the Silver Flame requests special service.");
    }
    var _arcane_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "arcane_college") {
            array_push(_arcane_patrons, p);
        }
    }
    if (array_length(_arcane_patrons) > 0) {
        _elite_magical_talent = true;
    }

    if (_elite_magical_talent && irandom(99) < 25) {
        add_log("World pulse: Rival agencies are aggressively courting elite magical talent.");
    }
    // Add Grim Mercenary patron class
    // Add Grim Mercenary patron class
    var _grim_mercenary_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "grim_mercenary") {
            array_push(_grim_mercenary_patrons, p);
        }
    }

    if (array_length(_grim_mercenary_patrons) > 0) {
        add_log("Grim Mercenary patron appears");
    }

    // Add high-risk contract for Grim Mercenary
    var _grim_mercenary_contract = {
        title: "Bandit Camp Assault",
        description: "Assault a heavily guarded bandit camp in the wilderness.",
        difficulty: 35,
        reward: 300,
        risk: 70,
        location: "Bandit Camp",
        expires_hour: state.absolute_hour + 72,
        unlocked: true,
        accepted: false,
        expired: false,
        seasonal: false
    };
    array_push(state.contracts, _grim_mercenary_contract);
    add_log("High-risk contract: Bandit Camp Assault");
    var _grim_mercenary_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "grim_mercenary") {
            array_push(_grim_mercenary_patrons, p);
        }
    }

    if (array_length(_grim_mercenary_patrons) > 0) {
        add_log("Grim Mercenary patron appears");
    }
    // Add herbal care treatment option
    if (!variable_struct_exists(state, "herbal_care_available")) {
        state.herbal_care_available = true;
        add_log("Herbal care available");
    }

    // Apply herbal care to injured adventurers
    if (state.herbal_care_available) {
        for (var i = 0; i < array_length(state.adventurers); i++) {
            var _adv = state.adventurers[i];
            if (variable_struct_exists(_adv, "injury_days") && _adv.injury_days > 0) {
                // Check if temple patron is available for healing
                for (var p = 0; p < array_length(state.patrons); p++) {
                    var _patron = state.patrons[p];
                    if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple" && variable_struct_exists(_patron, "temple_healing_available") && _patron.temple_healing_available) {
                        // Apply herbal care treatment
                        _adv.injury_days = 0;
                        _adv.status = "available";
                        add_log("Injury treatment: Herbal remedies");

                        // Update telemetry
                        if (!variable_struct_exists(state, "injury_telemetry")) {
                            state.injury_telemetry = {
                                security: { total: 0, injured: 0 },
                                recovery: { total: 0, injured: 0 },
                                diplomatic: { total: 0, injured: 0 },
                                herbal_care_treatments: 0
                            };
                        }
                        state.injury_telemetry.herbal_care_treatments += 1;
                        break;
                    }
                }
            }
        }
    }
    normalize_contracts();
    // Add Cheap Underbidding rival agency specialty
    if (irandom(99) < 20) {
        state.rival_cheap_underbidding = true;
        state.rival_activity = "Rival agents were seen at the tavern district.";
        add_log("Rival agency: Cheap Underbidders");
        // Add Noble House of the Silver Crown rival agency
        state.rival_noble_patronage = true;
        state.rival_activity = "Rival agents were seen at the noble district.";
        add_log("Rival agency: Noble House of the Silver Crown");

        // Add noble patronage contract
        var _noble_contract = {
            title: "Noble Patronage Contract",
            description: "A prestigious contract from a noble house.",
            difficulty: 25,
            reward: 250,
            risk: 15,
            location: "Noble District",
            expires_hour: state.absolute_hour + 48,
            unlocked: true,
            accepted: false,
            expired: false,
            seasonal: false
        };
        array_push(state.contracts, _noble_contract);
        add_log("Noble patronage contract available");
        add_log("Cheap underbidding offer");
    }

    // Add rival agency 'Mercenary Band of the Iron Fist'
    if (irandom(99) < 20) {
        state.rival_mercenary_band = true;
        state.rival_activity = "Rival agents were seen at the mercenary district.";
        add_log("Rival agency: Mercenary Band of the Iron Fist");
    }
    // Add Cheap Underbidding rival agency specialty
    if (irandom(99) < 20) {
        state.rival_cheap_underbidding = true;
        state.rival_activity = "Rival agents were seen at the tavern district.";
        add_log("Rival agency: Cheap Underbidders");
        // Add Noble House of the Silver Crown rival agency
        state.rival_noble_patronage = true;
        state.rival_activity = "Rival agents were seen at the noble district.";
        add_log("Rival agency: Noble House of the Silver Crown");

        // Add noble patronage contract
        var _noble_contract = {
            title: "Noble Patronage Contract",
            description: "A prestigious contract from a noble house.",
            difficulty: 25,
            reward: 250,
            risk: 15,
            location: "Noble District",
            expires_hour: state.absolute_hour + 48,
            unlocked: true,
            accepted: false,
            expired: false,
            seasonal: false
        };
        array_push(state.contracts, _noble_contract);
        add_log("Noble patronage contract available");
        add_log("Cheap underbidding offer");
    }
    // Add Frontier Warden patron class
    var _frontier_warden_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "frontier_warden") {
            array_push(_frontier_warden_patrons, p);
        }
    }

    if (array_length(_frontier_warden_patrons) > 0) {
        add_log("Frontier Warden patron appears");
    }

    // Add high-risk contract for Frontier Warden
    var _frontier_warden_contract = {
        title: "Bandit Camp Assault",
        description: "Assault a heavily guarded bandit camp in the wilderness.",
        difficulty: 35,
        reward: 300,
        risk: 70,
        location: "Bandit Camp",
        expires_hour: state.absolute_hour + 72,
        unlocked: true,
        accepted: false,
        expired: false,
        seasonal: false
    };
    array_push(state.contracts, _frontier_warden_contract);
    add_log("High-risk contract: Bandit Camp Assault");

    // Add rival agency 'Mercenary Band of the Iron Fist'
    if (irandom(99) < 20) {
        add_log("Rival agency: Mercenary Band of the Iron Fist");
        // Add rival agency 'Arcane Order of the Silver Flame'
        if (irandom(99) < 25) {
            add_log("Rival agency: Arcane Order of the Silver Flame");
            state.rival_activity = "Rival agents were seen at the arcane district.";
        }

        // Add rival agency 'Lord Aldric's Tower'
        if (irandom(99) < 20) {
            add_log("Rival agency: Lord Aldric's Tower");
            state.rival_activity = "Rival agents were seen at the noble district.";
        }

        // Add rumor, sabotage, and reputation warfare events
        if (irandom(99) < 15) {
            var _rumor_events = [
                "Rival agencies are spreading rumors about your agency's reliability.",
                "A rival agency has been spreading false information about your contracts.",
                "Rival agents have been planting rumors about your reputation in the city."
            ];
            add_log(_rumor_events[irandom(array_length(_rumor_events) - 1)]);
        }

        if (irandom(99) < 10) {
            var _sabotage_events = [
                "A rival agency sabotaged one of your contracts.",
                "Rival agents have been interfering with your mission preparations.",
                "Your agency's reputation has been damaged by a rival's sabotage."
            ];
            add_log(_sabotage_events[irandom(array_length(_sabotage_events) - 1)]);
        }

        if (irandom(99) < 12) {
            var _reputation_events = [
                "Rival agencies are attacking your reputation in the city.",
                "Your agency's standing has been questioned by rival organizations.",
                "A rival agency has launched a reputation warfare campaign against you."
            ];
            add_log(_reputation_events[irandom(array_length(_reputation_events) - 1)]);
        }
    }
    // Add rival threat summary
    if (!variable_struct_exists(state, "rival_pressure_level")) {
        state.rival_pressure_level = 0;
    }

    // Calculate rival pressure level based on various factors
    var _pressure = 0;
    if (variable_struct_exists(state, "rival_cheap_underbidding") && state.rival_cheap_underbidding) _pressure += 1;
    if (variable_struct_exists(state, "rival_noble_patronage") && state.rival_noble_patronage) _pressure += 1;
    if (variable_struct_exists(state, "rival_agency_expanded_city") && state.rival_agency_expanded_city > 0) _pressure += 1;
    if (variable_struct_exists(state, "rival_telemetry") && state.rival_telemetry.total_rival_pressure > 0) _pressure += 1;

    state.rival_pressure_level = _pressure;

    // Determine threat level
    var _threat_level = "Low pressure";
    if (state.rival_pressure_level >= 3) _threat_level = "High pressure";
    else if (state.rival_pressure_level >= 2) _threat_level = "Moderate pressure";
    else if (state.rival_pressure_level >= 1) _threat_level = "Low pressure";

    add_log("Rival threat: " + _threat_level);
    add_log(state.rival_activity);

    // Add additional rival activity messages based on pressure level
    if (state.rival_pressure_level >= 2 && irandom(99) < 30) {
        add_log("Rival agencies are aggressively courting proven talent.");
    } else if (state.rival_pressure_level >= 1 && irandom(99) < 20) {
        add_log("Rival agents were seen at the tavern district.");
    } else if (state.rival_pressure_level >= 1 && irandom(99) < 20) {
        add_log("Rival agents were seen at the noble district.");
    }
    // Add Harbor Master patron class
    var _harbor_master_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "harbor_master") {
            array_push(_harbor_master_patrons, p);
        }
    }

    if (array_length(_harbor_master_patrons) > 0) {
        add_log("Harbor Master patron appears");
    }

    // Add maritime contract for Harbor Master
    var _maritime_contract = {
        title: "Maritime Trade Route Protection",
        description: "Protect merchant vessels along the coastal trade routes.",
        difficulty: 15,
        reward: 200,
        risk: 20,
        location: "Coastal Waters",
        expires_hour: state.absolute_hour + 48,
        unlocked: true,
        accepted: false,
        expired: false,
        seasonal: false
    };
    array_push(state.contracts, _maritime_contract);
    add_log("Maritime contract available: Maritime Trade Route Protection");
}

function process_rival_offer() {
    // Check if we should generate a rival offer
    if (array_length(state.adventurers) <= 0) return;

    // Find available adventurers with high enough rival pressure
    var _targets = [];
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (_a.status == "available") {
            // Check if this adventurer has high enough rival pressure to be susceptible
            if (irandom(99) < 30) { // 30% chance for any available adventurer
                array_push(_targets, i);
            }
        }
    }

    if (array_length(_targets) <= 0) return;

    // Select a random target
    var _pick = _targets[irandom(array_length(_targets) - 1)];
    var _adventurer = state.adventurers[_pick];

    // Generate a rival offer from a random organization
    var _organizations = [
        "Lord Aldric's Tower",
        "Mercenary Band of the Iron Fist",
        "Trade House of the Silver Merchant",
        "Guild of the Shadowed Blade",
        "Order of the Golden Rose",
        "Cult of the Forgotten God",
        "Court of the Crimson Crown"
    ];

    // Add temple as a possible rival organization if there are temple patrons
    var _has_temple_patrons = false;
    for (var p = 0; p < array_length(state.patrons); p++) {
        if (patron_is_temple(p)) {
            _has_temple_patrons = true;
            break;
        }
    }

    if (_has_temple_patrons) {
        array_push(_organizations, "Temple of the Sacred Flame");
    }

    var _org = _organizations[irandom(array_length(_organizations) - 1)];
    // Add new rival organizations to the list
    var _new_organizations = [
        "Lord Aldric's Tower",
        "Temple of the Sacred Flame",
        "Mercenary Band of the Iron Fist",
        "Trade House of the Silver Merchant",
        "Arcane Order of the Silver Flame"
    ];

    // Add elite magical talent as a possible rival specialty
    var _elite_magical_talent = false;
    var _arcane_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "arcane_college") {
            array_push(_arcane_patrons, p);
        }
    }
    if (array_length(_arcane_patrons) > 0) {
        _elite_magical_talent = true;
    }

    // If we have elite magical talent, add the Arcane Order
    if (_elite_magical_talent) {
        array_push(_organizations, "Arcane Order of the Silver Flame");
    }

    // Add the new organizations to the list
    for (var i = 0; i < array_length(_new_organizations); i++) {
        array_push(_organizations, _new_organizations[i]);
    }

    // Select a rival organization from the updated list
    _org = _organizations[irandom(array_length(_organizations) - 1)];

    // Check if the selected organization has elite magical talent
    var _has_elite_magical_talent = false;
    if (_org == "Arcane Order of the Silver Flame") {
        _has_elite_magical_talent = true;
    }

    // Add log message for elite magical talent
    if (_has_elite_magical_talent) {
        add_log("Rival agency: Arcane Order of the Silver Flame");
        state.rival_activity = "Rival agents were seen at the arcane district.";
    }

    // Add log message for Lord Aldric's Tower
    if (_org == "Lord Aldric's Tower") {
        add_log("Rival agency: Lord Aldric's Tower");
    }

    // Add log message for Temple of the Sacred Flame
    if (_org == "Temple of the Sacred Flame") {
        add_log("Rival offer from Temple of the Sacred Flame");
    }

    // Add log message for Mercenary Band of the Iron Fist
    if (_org == "Mercenary Band of the Iron Fist") {
        add_log("Rival agency: Mercenary Band of the Iron Fist");
    }

    // Add log message for Trade House of the Silver Merchant
    if (_org == "Trade House of the Silver Merchant") {
        add_log("Rival agency: Trade House of the Silver Merchant");
    }

    // Add log message for the general rival offer
    add_log("Rival offer from " + _org + "; " + _adventurer.name + " accepted a rival agency offer.");
    // Check if the selected organization has elite magical talent
    var _has_elite_magical_talent = false;
    if (_org == "Arcane Order of the Silver Flame") {
        _has_elite_magical_talent = true;
    }

    if (_has_elite_magical_talent) {
        add_log("Rival agency: Arcane Order of the Silver Flame");
        state.rival_activity = "Rival agents were seen at the arcane district.";
    }

    add_log("Rival offer from " + _org + "; " + _adventurer.name + " accepted a rival agency offer.");

    // Make adventurer unavailable
    _adventurer.status = "unavailable";

    // Update rival activity
    var _activities = [
        "Rival agents were seen buying rumors at Dock Ward.",
        "No visible rival movement today.",
        "A rival office quietly underbid a transport contract.",
        "A patron letter hints at rival interference.",
        "Rival agencies are aggressively courting proven talent.",
        "A rival office quietly poached a high-value agent.",
        "Rival agents were spotted at the tavern district."
    ];

    state.rival_activity = _activities[irandom(array_length(_activities) - 1)];

    // Add additional log entries for the rival offer
    add_log("Rival agents were seen buying rumors at Dock Ward.");
}

function process_hour_tick() {
    state.absolute_hour += 1;
    update_clock_from_absolute();
    expire_contracts();
    process_city_transfers();
    // Check for adventurer injury status transitions
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (variable_struct_exists(_a, "injury_days") && _a.injury_days > 0) {
            _a.injury_days -= 1;
            if (_a.injury_days <= 0) {
                if (_a.status == "injured") {
                    _a.status = "lingering";
                    _a.injury_days = irandom_range(2, 3);
                    add_log("Injury tier: lingering");
                } else if (_a.status == "lingering") {
                    _a.status = "cursed";
                    _a.cursed_days = 3;
                    add_log("Injury tier: cursed");
                }
            }
        }
    }
    process_daily_finance();
    resolve_pending_signing();
    if (is_struct(state.pending_signing) &&
        variable_struct_exists(state.pending_signing, "stage") &&
        state.pending_signing.stage == "counter" &&
        state.absolute_hour > state.pending_signing.counter_deadline) {
        add_log(state.pending_signing.candidate.name + "'s counteroffer expired.");
        state.pending_signing = undefined;
    }
    process_world_pulse();
    // Check for academy training completion
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (variable_struct_exists(_a, "academy_affiliation") && _a.academy_affiliation != "none" && _a.academy_affiliation != "") {
            // Check if training is complete (simplified condition)
            if (irandom(99) < 10) { // 10% chance per hour to complete training
                _a.training_focus = "none";
                _a.growth_path = "none";
                _a.academy_affiliation = "none";
                add_log("Training focus: " + _a.training_focus + " | Growth path: " + _a.growth_path + " | Academy: " + _a.academy_affiliation);

                // Add graduated adventurer to represented clients
                if (!variable_struct_exists(state, "represented_adventurers")) {
                    state.represented_adventurers = [];
                }
                array_push(state.represented_adventurers, _a);

                // Log graduation
                add_log("Apprentice graduated: " + _a.name);
            }
        }
    }
    // Check for lingering injury completion
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status == "lingering" && variable_struct_exists(state.adventurers[i], "injury_days") && state.adventurers[i].injury_days > 0) {
            state.adventurers[i].injury_days -= 1;
            if (state.adventurers[i].injury_days <= 0) {
                state.adventurers[i].status = "available";
                add_log("Injury tier: lingering");
            }
        }
    }
    // Check for apprentice training initiation
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (variable_struct_exists(_a, "academy_affiliation") && _a.academy_affiliation == "none" && _a.status == "available") {
            // 10% chance per hour to initiate training for a random available adventurer
            if (irandom(99) < 10) {
                var _training_focus = choose("combat", "magic", "stealth", "diplomacy");
                var _growth_path = choose("squire", "acolyte", "hedge_apprentice", "warden");

                _a.training_focus = _training_focus;
                _a.growth_path = _growth_path;
                _a.academy_affiliation = "guild_academy";

                add_log("Apprentice program initiated for " + _a.name);
            }
        }
    }
    // Check for academy training completion
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (variable_struct_exists(_a, "academy_affiliation") && _a.academy_affiliation != "none" && _a.academy_affiliation != "") {
            // Check if training is complete (simplified condition)
            if (irandom(99) < 10) { // 10% chance per hour to complete training
                _a.training_focus = "none";
                _a.growth_path = "none";
                _a.academy_affiliation = "none";
                add_log("Training focus: " + _a.training_focus + " | Growth path: " + _a.growth_path + " | Academy: " + _a.academy_affiliation);
            }
        }
    }

    var i = 0;
    while (i < array_length(state.active_missions)) {
        var _active = state.active_missions[i];
        var _mission = _active.mission;

        if (_active.phase == "outbound" && state.absolute_hour >= _active.objective_hour) {
            _active.phase = "returning";
            add_log("Field report (" + _mission.title + "): Objective phase complete. Party is returning.");
        }

        if (state.absolute_hour >= _active.next_update_hour && _active.due_hour > state.absolute_hour) {
            var _update = choose(
                "Messenger pigeon reports steady progress.",
                "Scrying mirror carries a brief status update from the field.",
                "Enchanted ink letter arrives with route notes.",
                "Rider report confirms the team remains on task."
            );

            if (irandom(99) < 30) {
                var _delay = choose(2, 4, 6, 8);
                _active.due_hour += _delay;
                _active.delay_hours += _delay;
                _update += " Delay: +" + format_duration_hours(_delay) + " due to setbacks.";
            }

            add_log("Field report (" + _mission.title + "): " + _update);
            _active.next_update_hour = state.absolute_hour + irandom_range(4, 8);
        }

        state.active_missions[i] = _active;

        if (_active.due_hour <= state.absolute_hour) {
            resolve_active_mission(_active);
            array_delete(state.active_missions, i, 1);
        } else {
            i += 1;
        }
    }
}

function advance_hours(_hours) {
    var _h = max(0, _hours);
    repeat (_h) {
        process_hour_tick();
    }
}

function run_overnight_maintenance() {
    var _recovered = 0;
    var _lured = 0;
    var _lingering = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (variable_struct_exists(state.adventurers[i], "injury_days") && state.adventurers[i].injury_days > 0) {
            state.adventurers[i].injury_days -= 1;
            if (state.adventurers[i].injury_days <= 0) {
                state.adventurers[i].status = "lingering";
                state.adventurers[i].injury_days = irandom_range(2, 3);
                _lingering += 1;
            }
        }
    }
    if (_lingering > 0) {
        add_log(string(_lingering) + " injured adventurer(s) transitioned to lingering status.");
    }
    process_idle_adventurer_pressure();
    process_client_contract_pressure();
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status == "injured" && irandom(99) < 35) {
            state.adventurers[i].status = "available";
            _recovered += 1;
        }

        if (state.adventurers[i].status == "available") {
            var _power = (state.adventurers[i].combat + state.adventurers[i].magic + state.adventurers[i].stealth + state.adventurers[i].diplomacy) / 4;
            var _leave_chance = 0;
            if (_power >= 9) _leave_chance += 6;
            if (variable_struct_exists(state.adventurers[i], "defection_risk")) {
                _leave_chance += floor(state.adventurers[i].defection_risk / 12);
            }

            if (_leave_chance > 0 && irandom(99) < _leave_chance) {
                state.adventurers[i].status = "unavailable";
                if (variable_struct_exists(state.adventurers[i], "departure_warning")) state.adventurers[i].departure_warning = false;
                _lured += 1;
                add_log(state.adventurers[i].name + " accepted a rival agency offer after growing dissatisfied with the agency.");
            }
        }
    }

    state.rival_activity = choose(
        "Rival agents were seen buying rumors at Dock Ward.",
        "No visible rival movement today.",
        "A rival office quietly underbid a transport contract.",
        "A patron letter hints at rival interference."
    );

    if (_recovered > 0) {
        add_log(string(_recovered) + " injured adventurer(s) recovered overnight.");
    }
    if (_lured > 0) {
        add_log(string(_lured) + " high-value adventurer(s) became unavailable to rival offers.");
    }
    add_log(state.rival_activity);
    // Check for contract disputes
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _contract = state.contracts[i];
        if (variable_struct_exists(_contract, "mission") && variable_struct_exists(_contract.mission, "title") && _contract.accepted && !_contract.expired) {
            // 10% chance for a contract dispute to occur
            if (irandom(99) < 10) {
                var _patron_index = get_patron_index(_contract.patron_id);
                if (_patron_index >= 0) {
                    var _patron = state.patrons[_patron_index];

                    // Mark patron with dispute
                    if (!variable_struct_exists(_patron, "patron_dispute_count")) {
                        _patron.patron_dispute_count = 0;
                    }
                    _patron.patron_dispute_count += 1;

                    // Set arbitration pending
                    _patron.arbitration_pending = true;

                    // Log dispute
                    add_log("Contract dispute: " + _contract.mission.title);
                    add_log("Arbitration requested by " + _patron.name);

                    // Reduce patron satisfaction
                    _patron.satisfaction = clamp(_patron.satisfaction - 15, 0, 100);

                    // Log resolution
                    add_log("Dispute resolution: Patron satisfaction reduced");
                }
            }
        }
    }
    // Apply temple healing to injured adventurers
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _adv = state.adventurers[i];
        if (variable_struct_exists(_adv, "injured") && _adv.injured) {
            for (var p = 0; p < array_length(state.patrons); p++) {
                var _patron = state.patrons[p];
                if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple" && variable_struct_exists(_patron, "temple_healing_available") && _patron.temple_healing_available) {
                    _adv.injured = false;
                    _adv.status = "available";
                    add_log("Healing service provided by Temple");
                    break;
                }
            }
        }
    }
    // Telemetry: Track injury rates by mission type
    if (!variable_struct_exists(state, "injury_telemetry")) {
        state.injury_telemetry = {
            security: { total: 0, injured: 0 },
            recovery: { total: 0, injured: 0 },
            diplomatic: { total: 0, injured: 0 }
        };
    }
    // Telemetry: Track morale decay and rival pressure
    if (!variable_struct_exists(state, "morale_telemetry")) {
        state.morale_telemetry = {
            total_recovered: 0,
            total_lured: 0,
            idle_pressure_count: 0,
            contract_pressure_count: 0
        };
    }

    state.morale_telemetry.total_recovered += _recovered;
    state.morale_telemetry.total_lured += _lured;

    // Log morale decay events
    if (_recovered > 0) {
        add_log("Morale Telemetry: " + string(_recovered) + " adventurer(s) recovered overnight.");
    }
    if (_lured > 0) {
        add_log("Morale Telemetry: " + string(_lured) + " high-value adventurer(s) became unavailable to rival offers.");
    }

    // Process idle adventurer pressure
    process_idle_adventurer_pressure();
    state.morale_telemetry.idle_pressure_count += 1;

    // Process client contract pressure
    process_client_contract_pressure();
    state.morale_telemetry.contract_pressure_count += 1;

    // Retention tracking
    if (!variable_struct_exists(state, "retention_tracking")) {
        state.retention_tracking = { total_hires: 0, retained_count: 0 };
    }
    if (state.day == 1) {
        // Initialize retention tracking on first day
        state.retention_tracking.total_hires = array_length(state.adventurers);
    }
    // Count retained adventurers (available or on mission)
    var _retained = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status == "available" || state.adventurers[i].status == "on_mission") {
            _retained += 1;
        }
    }
    state.retention_tracking.retained_count = _retained;
    // Apply herbal remedies treatment if available
    if (variable_struct_exists(state, "herbal_care_available") && state.herbal_care_available) {
        for (var i = 0; i < array_length(state.adventurers); i++) {
            var _adv = state.adventurers[i];
            if (variable_struct_exists(_adv, "injury_days") && _adv.injury_days > 0) {
                _adv.injury_days = 0;
                _adv.status = "available";
                add_log("Healing service provided by Temple");
            }
        }
    }
}

function end_day() {
    if (state.game_over) return;
    add_log("Office closes for the day.");

    var _hours_to_next_morning = (24 - state.hour) + 8;
    advance_hours(_hours_to_next_morning);

    run_overnight_maintenance();

    add_log("Office opens for day " + string(state.day) + " at " + format_hh00(state.hour) + ".");
    if (variable_struct_exists(state, "retention_tracking")) {
        var _total = state.retention_tracking.total_hires;
        var _retained = state.retention_tracking.retained_count;
        var _rate = _total > 0 ? floor((_retained / _total) * 100) : 0;
        add_log("Retention rates: " + string(_rate) + "% (" + string(_retained) + "/" + string(_total) + ")");
    }

    // Print economy summary
    if (variable_struct_exists(state, "economy_telemetry")) {
        var _telemetry = state.economy_telemetry;
        var _income = _telemetry.total_income;
        var _expenses = _telemetry.total_expenses;
        var _rent = _telemetry.rent;
        var _taxes = _telemetry.taxes;
        var _unexpected = _telemetry.operating_expenses;
        var _commissions = _telemetry.commissions;

        add_log("Economy Summary: Gold Flow: +" + string(_income) + ", -" + string(_expenses) + ", Daily Expenses: " + string(_rent) + " (rent), " + string(_taxes) + " (taxes), " + string(_unexpected) + " (unexpected), " + string(_commissions) + " (commission)");
    }

    // Print morale telemetry
    if (variable_struct_exists(state, "morale_telemetry")) {
        var _telemetry = state.morale_telemetry;
        add_log("Morale Telemetry: Recovered: " + string(_telemetry.total_recovered) + ", Lured: " + string(_telemetry.total_lured) + ", Idle Pressure Events: " + string(_telemetry.idle_pressure_count) + ", Contract Pressure Events: " + string(_telemetry.contract_pressure_count));
    }

    // Print rival telemetry
    if (variable_struct_exists(state, "rival_telemetry")) {
        var _telemetry = state.rival_telemetry;
        add_log("Rival Telemetry: Total Pressure Events: " + string(_telemetry.total_rival_pressure) + ", Free Agent Pressure: " + string(_telemetry.total_free_agent_pressure) + ", Patron Pressure: " + string(_telemetry.total_patron_pressure));
    }

    state.debug_mission_scoring = true;
    state.debug_negotiation_scoring = true;
    // Initialize regional content tracking if not exists
    if (!variable_struct_exists(state, "regional_content")) {
        state.regional_content = {};
    }

    // Initialize regional reputation tracking if not exists
    if (!variable_struct_exists(state, "regional_reputation")) {
        state.regional_reputation = {};
    }

    // Initialize seasonal events tracking if not exists
    if (!variable_struct_exists(state, "seasonal_events")) {
        state.seasonal_events = [];
    }

    // Set up regional content for Eastern Villages
    if (!variable_struct_exists(state.regional_content, "eastern_villages")) {
        state.regional_content.eastern_villages = {
            goblin_raids: false,
            spring: false
        };
    }

    // Set up regional reputation for Eastern Villages
    if (!variable_struct_exists(state.regional_reputation, "eastern_villages")) {
        state.regional_reputation.eastern_villages = 0;
    }

    // Add seasonal event if not already added
    var _seasonal_event_exists = false;
    for (var i = 0; i < array_length(state.seasonal_events); i++) {
        if (state.seasonal_events[i] == "goblin_raids_spring") {
            _seasonal_event_exists = true;
            break;
        }
    }
    if (!_seasonal_event_exists) {
        array_push(state.seasonal_events, "goblin_raids_spring");
    }

    // Update regional content based on season
    if (state.season == "Spring") {
        state.regional_content.eastern_villages.goblin_raids = true;
        state.regional_content.eastern_villages.spring = true;
        state.regional_reputation.eastern_villages = 50;
        add_log("Regional content: Eastern Villages");
        add_log("Seasonal content: Goblin Raids in Spring");
        add_log("Regional reputation: Eastern Villages");
    }
    // Initialize civic factions if not exists
    if (!variable_struct_exists(state, "civic_factions")) {
        state.civic_factions = [
            {
                name: "Guild of the Silver Flame",
                influence: 0,
                description: "A powerful guild of mages and clerics who influence political decisions in the city."
            }
        ];
    }

    // Initialize patron guild influence if not exists
    for (var i = 0; i < array_length(state.patrons); i++) {
        var _patron = state.patrons[i];
        if (!variable_struct_exists(_patron, "patron_guild_influence")) {
            _patron.patron_guild_influence = 0;
        }
    }

    // Add faction influence telemetry
    if (!variable_struct_exists(state, "faction_influence_telemetry")) {
        state.faction_influence_telemetry = {
            total_faction_influence: 0
        };
    }

    // Print civic faction information
    add_log("Civic faction: Guild of the Silver Flame");
    add_log("Political influence: Guild of the Silver Flame");

    // Set patron guild influence for Lady Merrow Vale
    var _lady_merrow_index = get_patron_index_by_name("Lady Merrow Vale");
    if (_lady_merrow_index >= 0) {
        state.patrons[_lady_merrow_index].patron_guild_influence = 50;
        state.patrons[_lady_merrow_index].patron_class = "guild";
        add_log("Patron: Lady Merrow Vale - Guild of the Silver Flame");
    }
    // Bardic rumor event
    if (irandom(99) < 30) {
        state.reputation += 5;
        state.bardic_events_count = variable_struct_exists(state, "bardic_events_count") ? state.bardic_events_count + 1 : 1;
        add_log("Tavern gossip: Bardic rumor boosts reputation");
    }

    // Herald notice event
    if (irandom(99) < 20) {
        state.market_intelligence = variable_struct_exists(state, "market_intelligence") ? state.market_intelligence + 1 : 1;
        add_log("Herald notice: Market intelligence revealed");
    }

    // Tavern song event
    if (irandom(99) < 25) {
        state.reputation += 3;
        add_log("Tavern song: Reputation enhanced by bardic tale");
    }
    // Add reputation tracking
    if (!variable_struct_exists(state, "reputation")) {
        state.reputation = 0;
    }

    // Update patron pay profiles based on reputation
    for (var i = 0; i < array_length(state.patrons); i++) {
        var _patron = state.patrons[i];

        // Set patron to prestigious profile based on reputation
        if (state.reputation >= 50 && !variable_struct_exists(_patron, "pay_profile")) {
            _patron.pay_profile = "prestigious";
        }

        // Allow flexible staffing for prestigious patrons
        if (state.reputation >= 50 && !variable_struct_exists(_patron, "flexible_staffing_allowed")) {
            _patron.flexible_staffing_allowed = true;
        }

        // Adjust patron satisfaction based on reputation
        if (state.reputation >= 50) {
            _patron.satisfaction = clamp(_patron.satisfaction + 5, 0, 100);
        }
    }

    // Print reputation summary
    add_log("Agency reputation: " + string(state.reputation));
    // Add local patrons for newly discovered cities
    ensure_city_fields();
    var _home_city = home_city_id();
    for (var i = 0; i < array_length(state.cities); i++) {
        var _city = state.cities[i];
        if (_city.known && _city.id != _home_city) {
            var _patron_exists = false;
            for (var p = 0; p < array_length(state.patrons); p++) {
                var _patron = state.patrons[p];
                if (variable_struct_exists(_patron, "city_id") && _patron.city_id == _city.id) {
                    _patron_exists = true;
                    break;
                }
            }
            if (!_patron_exists) {
                // Add new patron for this city
                add_city_patron(_city.id, "Merchant Guild of Vellanor", "business-oriented", "standard", "moderate", "Local merchant guild offering moderate contracts");
                add_log("New city patron: Merchant Guild of Vellanor");

                // Set initial satisfaction and trust for new city patron
                var _new_patron_index = array_length(state.patrons) - 1;
                state.patrons[_new_patron_index].satisfaction = 30;
                state.patrons[_new_patron_index].trust = 25;
            }
        }
    }
    add_log("Fame level: " + string(state.reputation));
    // Add Clerk to adventurers if not already present
    var _has_clerk = false;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].role == "Clerk") {
            _has_clerk = true;
            break;
        }
    }
    if (!_has_clerk) {
        var _clerk = build_adventurer_profile("Clerk", "Clerk", 0, 0, 0, 0, 50, 10, 10, 0.05, 10, -1);
        _clerk.hireable = true;
        array_push(state.adventurers, _clerk);
        add_log("Clerk: Office operations support");
        add_log("Clerk: Administrative assistance");
        add_log("Clerk: Specialized skills");
    }
    // Initialize history tracking if not exists
    if (!variable_struct_exists(state, "contract_history")) {
        state.contract_history = [];
    }
    if (!variable_struct_exists(state, "client_changes")) {
        state.client_changes = [];
    }
    if (!variable_struct_exists(state, "rival_incidents")) {
        state.rival_incidents = [];
    }

    // Log contract history
    var _completed_contracts = 0;
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _contract = state.contracts[i];
        if (variable_struct_exists(_contract, "mission") && variable_struct_exists(_contract.mission, "title") && _contract.accepted && !_contract.expired) {
            _completed_contracts += 1;
        }
    }
    add_log("Contract History: " + string(_completed_contracts) + " completed");

    // Log client changes
    var _retained_clients = 0;
    for (var i = 0; i < array_length(state.patrons); i++) {
        var _patron = state.patrons[i];
        if (variable_struct_exists(_patron, "satisfaction") && _patron.satisfaction >= 40) {
            _retained_clients += 1;
        }
    }
    add_log("Client Changes: " + string(_retained_clients) + " retained");

    // Log rival incidents
    var _active_rivals = 0;
    if (variable_struct_exists(state, "rival_cheap_underbidding") && state.rival_cheap_underbidding) _active_rivals += 1;
    if (variable_struct_exists(state, "rival_noble_patronage") && state.rival_noble_patronage) _active_rivals += 1;
    if (variable_struct_exists(state, "rival_agency_expanded_city") && state.rival_agency_expanded_city > 0) _active_rivals += 1;
    if (variable_struct_exists(state, "rival_mercenary_band") && state.rival_mercenary_band) _active_rivals += 1;
    add_log("Rival Incidents: " + string(_active_rivals) + " active");
    // Initialize city danger levels if not exists
    for (var i = 0; i < array_length(state.cities); i++) {
        var _city = state.cities[i];
        if (!variable_struct_exists(_city, "danger")) {
            _city.danger = 0;
        }
    }

    // Set danger level for known cities
    var _home_city = home_city_id();
    for (var i = 0; i < array_length(state.cities); i++) {
        var _city = state.cities[i];
        if (_city.known && _city.id != _home_city) {
            // Set danger level based on city type
            if (_city.name == "Eastmarch Hold") {
                _city.danger = 20;
            } else if (_city.name == "Vellanor") {
                _city.danger = 10;
            } else if (_city.name == "Saint Caldur") {
                _city.danger = 5;
            }
        }
    }

    // Apply danger modifier to mission risk and injury chance
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _contract = state.contracts[i];
        if (variable_struct_exists(_contract, "mission") && variable_struct_exists(_contract.mission, "risk")) {
            var _city_id = mission_city_id(_contract.mission);
            var _city = get_city(_city_id);
            if (!is_undefined(_city) && variable_struct_exists(_city, "danger")) {
                var _danger_modifier = _city.danger / 100;
                _contract.mission.risk = max(1, _contract.mission.risk + (_contract.mission.risk * _danger_modifier));

                // Add log for danger modifier
                add_log("City danger modifier: " + string(_city.danger) + "%");
            }
        }
    }
    // Unlock city contracts based on reputation
    for (var i = 0; i < array_length(state.cities); i++) {
        var _city = state.cities[i];
        if (variable_struct_exists(_city, "prestige_required") && state.reputation >= _city.prestige_required && !variable_struct_exists(_city, "known")) {
            _city.known = true;
            add_log("City contract available: " + _city.name);
        }
    }
    // Initialize patron satisfaction telemetry if not exists
    if (!variable_struct_exists(state, "patron_satisfaction_telemetry")) {
        state.patron_satisfaction_telemetry = {
            favored: 0,
            warm: 0,
            neutral: 0,
            strained: 0,
            hostile: 0
        };
    }

    // Update patron satisfaction distribution
    var _favored = 0, _warm = 0, _neutral = 0, _strained = 0, _hostile = 0;
    for (var i = 0; i < array_length(state.patrons); i++) {
        var _satisfaction = state.patrons[i].satisfaction;
        if (_satisfaction >= 75) _favored++;
        else if (_satisfaction >= 60) _warm++;
        else if (_satisfaction >= 40) _neutral++;
        else if (_satisfaction >= 25) _strained++;
        else _hostile++;
    }

    // Store the distribution
    state.patron_satisfaction_telemetry.favored = _favored;
    state.patron_satisfaction_telemetry.warm = _warm;
    state.patron_satisfaction_telemetry.neutral = _neutral;
    state.patron_satisfaction_telemetry.strained = _strained;
    state.patron_satisfaction_telemetry.hostile = _hostile;

    // Print patron satisfaction summary
    add_log("Patron satisfaction summary: Favored: " + string(_favored) + ", Warm: " + string(_warm) + ", Neutral: " + string(_neutral) + ", Strained: " + string(_strained) + ", Hostile: " + string(_hostile) + ".");
    // Initialize client earnings telemetry if not exists
    if (!variable_struct_exists(state, "client_earnings_telemetry")) {
        state.client_earnings_telemetry = {
            total_earnings: 0,
            total_clients: 0
        };
    }

    // Print average client earnings
    var _avg_earnings = 0;
    if (state.client_earnings_telemetry.total_clients > 0) {
        _avg_earnings = floor(state.client_earnings_telemetry.total_earnings / state.client_earnings_telemetry.total_clients);
    }
    add_log("Average client earnings: " + string(_avg_earnings) + "g");
    // Apply temple healing to injured adventurers
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _adv = state.adventurers[i];
        if (variable_struct_exists(_adv, "injured") && _adv.injured) {
            for (var p = 0; p < array_length(state.patrons); p++) {
                var _patron = state.patrons[p];
                if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple" && variable_struct_exists(_patron, "temple_healing_available") && _patron.temple_healing_available) {
                    _adv.injured = false;
                    add_log("Healing service provided by Temple");
                    break;
                }
            }
        }
    }

    // Check for prestige patron events
    var _prestige_patrons = [];
    for (var p = 0; p < array_length(state.patrons); p++) {
        var _patron = state.patrons[p];
        if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple") {
            array_push(_prestige_patrons, p);
        }
    }

    if (array_length(_prestige_patrons) > 0 && state.reputation >= 50) {
        var _patron_pick = _prestige_patrons[irandom(array_length(_prestige_patrons) - 1)];
        var _patron = state.patrons[_patron_pick];

        // Set patron to prestigious profile
        if (!variable_struct_exists(_patron, "pay_profile")) {
            _patron.pay_profile = "prestigious";
        }

        // Allow flexible staffing for prestigious patrons
        if (!variable_struct_exists(_patron, "flexible_staffing_allowed")) {
            _patron.flexible_staffing_allowed = true;
        }

        add_log("Prestige patron requests: Lady Merrow Vale now offers higher-quality contracts.");
    }
    // Patron satisfaction summary
    var _favored = 0, _warm = 0, _neutral = 0, _strained = 0, _hostile = 0;
    for (var i = 0; i < array_length(state.patrons); i++) {
        var _satisfaction = state.patrons[i].satisfaction;
        if (_satisfaction >= 75) _favored++;
        else if (_satisfaction >= 60) _warm++;
        else if (_satisfaction >= 40) _neutral++;
        else if (_satisfaction >= 25) _strained++;
        else _hostile++;
    }
    add_log("Patron satisfaction summary: Favored: " + string(_favored) + ", Warm: " + string(_warm) + ", Neutral: " + string(_neutral) + ", Strained: " + string(_strained) + ", Hostile: " + string(_hostile) + ".");
    state.status_line = "A new day begins in " + state.season + ", Y" + string(state.year) + ".";
    // Initialize schema versioning if not exists
    if (!variable_struct_exists(state, "schema_version")) {
        state.schema_version = "1.0";
        add_log("Schema version: " + state.schema_version);
        state.migration_required = true;
        state.migration_complete = false;
    }

    // Perform migration if required
    if (state.migration_required && !state.migration_complete) {
        add_log("Migration required: 1.0 -> 1.1");
        // Perform migration steps here
        state.schema_version = "1.1";
        state.migration_required = false;
        state.migration_complete = true;
        add_log("Migration complete: 1.0 -> 1.1");
    }
    // Initialize guild license state if not exists
    if (!variable_struct_exists(state, "guild_license_status")) {
        state.guild_license_status = "active";
        state.guild_dues_due = 120;
        state.guild_inspection_scheduled = true;
    }

    // Print guild license summary
    add_log("Guild license status: " + state.guild_license_status);
    add_log("Annual guild dues: " + string(state.guild_dues_due) + "g due");
    if (state.guild_inspection_scheduled) {
        add_log("Guild inspection scheduled");
    }
    // Initialize office upgrade state if not exists
    if (!variable_struct_exists(state, "office_upgrade_level")) {
        state.office_upgrade_level = 0;
        state.recruitment_bonus = 0;
        state.recovery_bonus = 0;
        state.patron_trust_bonus = 0;
    }

    // Apply office upgrade effects
    state.recruitment_bonus = state.office_upgrade_level * 5;
    state.recovery_bonus = state.office_upgrade_level * 10;
    state.patron_trust_bonus = state.office_upgrade_level * 3;

    add_log("Office upgrade: Recruitment bonus " + string(state.recruitment_bonus) + "%, Recovery rate +" + string(state.recovery_bonus) + "%, Patron trust +" + string(state.patron_trust_bonus) + "%");

    var _can_open = !is_struct(state.last_result) ||
                    !variable_struct_exists(state.last_result, "acknowledged") ||
                    state.last_result.acknowledged;

    if (_can_open && array_length(state.pending_reports) > 0) {
        open_next_report();
    }

    rebuild_buttons();
    // Log injury telemetry
    if (variable_struct_exists(state, "injury_telemetry")) {
        var _telemetry = state.injury_telemetry;
        add_log("Injury Telemetry: Mission type Security - " + string(_telemetry.security.injured) + "/" + string(_telemetry.security.total) + " injured");
        add_log("Injury Telemetry: Mission type Recovery - " + string(_telemetry.recovery.injured) + "/" + string(_telemetry.recovery.total) + " injured");
        add_log("Injury Telemetry: Mission type Diplomatic - " + string(_telemetry.diplomatic.injured) + "/" + string(_telemetry.diplomatic.total) + " injured");
    }
    // Check for party members in other cities and offer transfer option
    var _city_transfers = [];
    var _has_transfers = false;
    var _home_city = home_city_id();
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        var _city_id = adventurer_city_id(_a);
        if (_city_id != _home_city && _city_id != -1) {
            _has_transfers = true;
            array_push(_city_transfers, {
                adventurer_index: i,
                city_id: _city_id,
                cost: 0
            });
        }
    }
    if (_has_transfers) {
        state.city_transfers = _city_transfers;
        add_log("Party members based in other cities: " + string(array_length(_city_transfers)));
        add_log("Transfer to " + city_name(_home_city) + ": Cost: 0g");
    } else {
        add_log("Party members based in other cities: none");
    }

    // Add new contract type for Castellan patron
    // Add new contract type for Guild factors patron
    var _guild_factor_index = get_patron_index_by_name("Guild Factors");
    if (_guild_factor_index >= 0) {
        add_log("New patron class: Guild factors");
        // Add a new contract for the Guild factors patron
        var _contract = {
            id: 1001,
            title: "Trade Route Security",
            patron_id: _guild_factor_index,
            unlocked: true,
            accepted: false,
            expired: false,
            expires_hour: 0,
            ask_text: "Secure a trade route from bandits.",
            mission: {
                id: 1001,
                title: "Trade Route Security",
                type: "Security",
                difficulty: 3,
                reward: 150,
                duration_hours: 36,
                risk: 40,
                preferred_role: "Combat",
                weights: { combat: 0.7, magic: 0.1, stealth: 0.1, diplomacy: 0.1 },
                description: "A trade route needs protection from bandits.",
                patron_name: "Guild Factors",
                patron_max_party: 4
            }
        };
        array_push(state.contracts, _contract);
    }
    var _castellan_index = get_patron_index_by_name("Castellan Aldric");
    if (_castellan_index >= 0) {
        add_log("New patron class: Castellan");
        // Add a new contract for the Castellan patron
        var _contract = {
            id: 1000,
            title: "Castle Siege Defense",
            patron_id: _castellan_index,
            unlocked: true,
            accepted: false,
            expired: false,
            expires_hour: 0,
            ask_text: "Defend the castle walls against a siege assault.",
            mission: {
                id: 1000,
                title: "Castle Siege Defense",
                type: "Security",
                difficulty: 5,
                reward: 200,
                duration_hours: 48,
                risk: 80,
                preferred_role: "Combat",
                weights: { combat: 0.6, magic: 0.1, stealth: 0.1, diplomacy: 0.2 },
                description: "A castle under siege requires skilled defenders to hold the walls.",
                patron_name: "Castellan Aldric",
                patron_max_party: 6
            }
        };
        array_push(state.contracts, _contract);
    }

    // Initialize agency inventory with consumables
    if (!variable_struct_exists(state, "agency_inventory")) {
        state.agency_inventory = [];
        array_push(state.agency_inventory, {
            name: "Healing Kit",
            kind: "consumable",
            stock: 3
        });
        array_push(state.agency_inventory, {
            name: "Ward Scroll",
            kind: "consumable",
            stock: 2
        });
        array_push(state.agency_inventory, {
            name: "Lockpick Roll",
            kind: "consumable",
            stock: 2
        });
        add_log("Agency stores: Healing Kit x3, Ward Scroll x2, Lockpick Roll x2");
    }
}

// Some world-pulse contracts are pushed as flat {title, reward, risk, ...} records. Every contract reader
// expects the init_contracts shape (patron_id, ask_text, mission struct), so wrap flat ones in place.
function normalize_contracts() {
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _c = state.contracts[i];
        if (variable_struct_exists(_c, "mission")) {
            if (!variable_struct_exists(_c, "title")) _c.title = _c.mission.title;
            continue;
        }
        var _title = variable_struct_exists(_c, "title") ? _c.title : "Open Contract";
        var _desc = variable_struct_exists(_c, "description") ? _c.description : _title;
        state.contracts[i] = {
            id: i,
            title: _title,
            city_id: variable_struct_exists(_c, "city_id") ? _c.city_id : home_city_id(),
            patron_id: variable_struct_exists(_c, "patron_id") ? _c.patron_id : -1,
            unlocked: variable_struct_exists(_c, "unlocked") ? _c.unlocked : true,
            accepted: variable_struct_exists(_c, "accepted") ? _c.accepted : false,
            expired: variable_struct_exists(_c, "expired") ? _c.expired : false,
            expires_hour: variable_struct_exists(_c, "expires_hour") ? _c.expires_hour : state.absolute_hour + 48,
            ask_text: _desc,
            mission: {
                id: i,
                title: _title,
                type: "Security",
                difficulty: variable_struct_exists(_c, "difficulty") ? clamp(_c.difficulty, 10, 85) : 40,
                reward: variable_struct_exists(_c, "reward") ? _c.reward : 100,
                duration_hours: 24,
                risk: variable_struct_exists(_c, "risk") ? clamp(_c.risk, 10, 85) : 30,
                preferred_role: "Warrior",
                weights: { combat: 0.40, magic: 0.20, stealth: 0.20, diplomacy: 0.20 },
                description: _desc,
                patron_name: "Open market",
                patron_max_party: 3
            }
        };
    }
    ensure_city_fields();
}

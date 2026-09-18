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
    }
}

function process_world_pulse() {
    if (state.game_over) return;
    if (state.world_pulse_last_hour == state.absolute_hour) return;
    state.world_pulse_last_hour = state.absolute_hour;
    // Winter pass escort mission check
    if (state.season == "Winter" && irandom(99) < 10) {
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
    add_log("Seasonal content: Dry-Season Ruin Delve");
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
        add_log("Seasonal content: Winter Pass Escorts");
    }

    // Global world pulse every 3 in-game hours, regardless of current mode.
    if ((state.absolute_hour mod 3) != 0) return;
    if (irandom(99) >= 42) return;

    var _event_roll = irandom_range(0, 5);
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
}

function end_day() {
    if (state.game_over) return;
    add_log("Office closes for the day.");

    var _hours_to_next_morning = (24 - state.hour) + 8;
    advance_hours(_hours_to_next_morning);

    run_overnight_maintenance();

    add_log("Office opens for day " + string(state.day) + " at " + format_hh00(state.hour) + ".");
    state.debug_mission_scoring = true;
    state.debug_negotiation_scoring = true;
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

    var _can_open = !is_struct(state.last_result) ||
                    !variable_struct_exists(state.last_result, "acknowledged") ||
                    state.last_result.acknowledged;

    if (_can_open && array_length(state.pending_reports) > 0) {
        open_next_report();
    }

    rebuild_buttons();
}

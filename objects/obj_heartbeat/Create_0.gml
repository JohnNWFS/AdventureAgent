/// Guild Agent prototype controller bootstrap

randomize();

MODE = {
    PLANNING: 0,
    BUYING: 1,
    SELLING: 2,
    CONTRACTING: 3,
    PITCHING: 4,
    ARGUING: 5,
    SABOTAGE: 6,
    MISSION_REVIEW: 7,
    MISSION_RESULT: 8,
    GAME_HOUSE: 9
};

SEASONS = ["Spring", "Summer", "Autumn", "Winter"];
HOURS_PER_DAY = 24;
DAYS_PER_SEASON = 30;
SEASONS_PER_YEAR = 4;
DAYS_PER_MONTH = 10;
MONTHS_PER_YEAR = 12;
STAT_CAP = 12;

state = {
    mode: MODE.PLANNING,

    // Time simulation
    absolute_hour: 8, // Day 1, 08:00
    day: 1,
    hour: 8,
    month: 1,
    year: 1,
    season: "Spring",

    gold: 280,
    gold_owed: 95,
    reputation: 42,
    patron_max_party: 3,
    patron_slot_fee: 25,
    rival_activity: "Rival office appears quiet.",
    status_line: "Morning briefing complete.",

    adventurers: [],
    missions: [],
    patrons: [],
    contracts: [],
    selected_patron_index: -1,

    selected_mission_index: -1,
    selected_party_ids: [],
    show_intro: true,

    // Mission lifecycle
    active_missions: [],
    pending_reports: [],
    last_result: undefined,

    input_line: "",
    logs: [],
    logs_cap: 120,
    log_scroll: 0,

    buttons: [],
    button_page: 0,
    button_nav_prev: { x1: 0, y1: 0, x2: 0, y2: 0 },
    button_nav_next: { x1: 0, y1: 0, x2: 0, y2: 0 },

    next_adv_id: 5,
    free_agents: [],
    selected_free_agent_index: -1,
    offer_bonus: 0,
    offer_rate_delta: 0,
    offer_commission: 0.22,
    pending_signing: undefined,
    last_finance_day: 1,
    world_pulse_last_hour: -1,
    realtime_step_accum: 0,
    realtime_hour_interval_steps: 0,

    game_house_game: "CRAPS",
    game_house_wager: 10,
    game_house: {
        craps_phase: "idle",
        craps_point: 0,
        craps_last_roll: 0,
        wheel_bet: "RED",
        wheel_last_number: -1,
        wheel_last_color: "-",
        cards_in_round: false,
        cards_player: [],
        cards_dealer: [],
        cards_last_outcome: ""
    },

    game_over: false,
    game_over_reason: ""
};

mode_to_string = function(_mode) {
    switch (_mode) {
        case MODE.PLANNING: return "PLANNING";
        case MODE.BUYING: return "BUYING";
        case MODE.SELLING: return "SELLING";
        case MODE.CONTRACTING: return "CONTRACTING";
        case MODE.PITCHING: return "PITCHING";
        case MODE.ARGUING: return "ARGUING";
        case MODE.SABOTAGE: return "SABOTAGE";
        case MODE.MISSION_REVIEW: return "MISSION_REVIEW";
        case MODE.MISSION_RESULT: return "MISSION_RESULT";
        case MODE.GAME_HOUSE: return "GAME_HOUSE";
    }
    return "UNKNOWN";
};

format_hh00 = function(_hour) {
    var _h = _hour mod 24;
    if (_h < 10) return "0" + string(_h) + ":00";
    return string(_h) + ":00";
};

format_duration_hours = function(_hours) {
    var _d = floor(_hours / 24);
    var _h = _hours mod 24;

    if (_d > 0 && _h > 0) return string(_d) + "d " + string(_h) + "h";
    if (_d > 0) return string(_d) + "d";
    return string(_h) + "h";
};

update_clock_from_absolute = function() {
    var _total_days_elapsed = floor(state.absolute_hour / HOURS_PER_DAY);

    state.day = _total_days_elapsed + 1;
    state.hour = state.absolute_hour mod HOURS_PER_DAY;

    var _days_per_year = DAYS_PER_SEASON * SEASONS_PER_YEAR;
    state.year = floor(_total_days_elapsed / _days_per_year) + 1;
    state.month = ((_total_days_elapsed mod (DAYS_PER_MONTH * MONTHS_PER_YEAR)) div DAYS_PER_MONTH) + 1;

    var _day_in_year = _total_days_elapsed mod _days_per_year;
    var _season_index = floor(_day_in_year / DAYS_PER_SEASON);
    state.season = SEASONS[_season_index];
};

add_log = function(_msg) {
    var _line = "[Y" + string(state.year) + " D" + string(state.day) + " " + format_hh00(state.hour) + "] " + string(_msg);
    array_push(state.logs, _line);
    while (array_length(state.logs) > state.logs_cap) {
        array_delete(state.logs, 0, 1);
    }
    state.log_scroll = 0;
};

check_game_over = function() {
    if (!state.game_over && state.gold <= 0) {
        state.gold = 0;
        state.game_over = true;
        state.game_over_reason = "Bankruptcy. The guild office can no longer operate.";
        state.status_line = state.game_over_reason;
        add_log("GAME OVER: " + state.game_over_reason);
        if (variable_instance_exists(id, "rebuild_buttons")) rebuild_buttons();
    }
};

add_gold = function(_amount, _reason) {
    state.gold += _amount;
    if (!is_undefined(_reason) && _reason != "") {
        add_log(_reason + " (" + string(_amount) + "g)");
    }
    check_game_over();
};

spend_gold = function(_amount, _reason) {
    state.gold -= _amount;
    if (!is_undefined(_reason) && _reason != "") {
        add_log(_reason + " (-" + string(_amount) + "g)");
    }
    check_game_over();
};

random_free_agent_name = function() {
    var _first = choose("Kael", "Iris", "Brom", "Nessa", "Varric", "Liora", "Fen", "Orin", "Mara", "Galen");
    var _last = choose("Dawnmere", "Blackfen", "Ashvale", "Runehart", "Thornfield", "Ironwill", "Mistbrook", "Crowley");
    return _first + " " + _last;
};

generate_free_agent = function() {
    var _roles = ["Warrior", "Mage", "Rogue", "Bard", "Cleric", "Ranger"];
    var _r = _roles[irandom(array_length(_roles) - 1)];
    var _base = irandom_range(3, 7);

    return {
        id: state.next_adv_id,
        name: random_free_agent_name(),
        role: _r,
        combat: _base + choose(-1, 0, 1, 2),
        magic: _base + choose(-1, 0, 1, 2),
        stealth: _base + choose(-1, 0, 1, 2),
        diplomacy: _base + choose(-1, 0, 1, 2),
        reliability: irandom_range(60, 88),
        age: irandom_range(18, 34),
        adventure_rate: irandom_range(20, 42),
        commission_rate: 0.22,
        status: "available"
    };
};

dismiss_intro = function() {
    if (state.show_intro) {
        state.show_intro = false;
        state.status_line = "Desk open. Review contracts and assemble a party.";
    }
};

init_adventurers = function() {
    return [
        { id: 0, name: "Mira Ashwind", role: "Mage", combat: 4, magic: 9, stealth: 3, diplomacy: 5, reliability: 78, age: 24, adventure_rate: 34, commission_rate: 0.22, status: "available" },
        { id: 1, name: "Bran Ironhook", role: "Warrior", combat: 9, magic: 1, stealth: 3, diplomacy: 4, reliability: 71, age: 31, adventure_rate: 30, commission_rate: 0.20, status: "available" },
        { id: 2, name: "Sable Quickstep", role: "Rogue", combat: 5, magic: 2, stealth: 9, diplomacy: 6, reliability: 64, age: 22, adventure_rate: 28, commission_rate: 0.24, status: "available" },
        { id: 3, name: "Tovin Reed", role: "Bard", combat: 3, magic: 4, stealth: 5, diplomacy: 9, reliability: 82, age: 27, adventure_rate: 26, commission_rate: 0.19, status: "available" },
        { id: 4, name: "Edda Stoneward", role: "Cleric", combat: 6, magic: 7, stealth: 2, diplomacy: 6, reliability: 88, age: 33, adventure_rate: 32, commission_rate: 0.18, status: "available" }
    ];
};

init_missions = function() {
    return [
        {
            id: 0,
            title: "Bandit Toll Road",
            type: "Security",
            difficulty: 52,
            reward: 140,
            duration_hours: 18,
            risk: 30,
            preferred_role: "Warrior",
            weights: { combat: 0.50, magic: 0.10, stealth: 0.15, diplomacy: 0.25 },
            description: "Escort caravans and break the extortion ring controlling the east road."
        },
        {
            id: 1,
            title: "Ruined Chapel Archive",
            type: "Recovery",
            difficulty: 60,
            reward: 185,
            duration_hours: 54,
            risk: 45,
            preferred_role: "Mage",
            weights: { combat: 0.15, magic: 0.45, stealth: 0.20, diplomacy: 0.20 },
            description: "Retrieve ecclesiastical records before grave robbers or rival agents do."
        },
        {
            id: 2,
            title: "Feud at Dunmere Court",
            type: "Diplomatic",
            difficulty: 50,
            reward: 150,
            duration_hours: 30,
            risk: 22,
            preferred_role: "Bard",
            weights: { combat: 0.10, magic: 0.15, stealth: 0.20, diplomacy: 0.55 },
            description: "Mediate a merchant conflict before street violence damages guild credibility."
        }
    ];
};

init_patrons = function() {
    return [
        { id: 0, name: "Lady Merrow Vale", personality: "courteous", contact: "sealed letter" },
        { id: 1, name: "Quartermaster Halden Pike", personality: "practical", contact: "guild messenger" },
        { id: 2, name: "Archivist Ilyra Quill", personality: "scholarly", contact: "arcane correspondence" },
        { id: 3, name: "Magistrate Doran Flint", personality: "stern", contact: "official courier" },
        { id: 4, name: "Captain Roen Blackwake", personality: "brisk", contact: "dock runner" },
        { id: 5, name: "Matron Ysabet Thorn", personality: "demanding", contact: "house steward" },
        { id: 6, name: "Prior Cedric Vale", personality: "calm", contact: "monastery letter" },
        { id: 7, name: "Guildmaster Olin Brass", personality: "transactional", contact: "clerk dispatch" },
        { id: 8, name: "Envoy Seris Dawn", personality: "polished", contact: "embassy aide" },
        { id: 9, name: "Warden Petra Stone", personality: "direct", contact: "watch courier" }
    ];
};

build_contract_mission = function(_id, _tpl, _patron_name, _variant) {
    var _title = _tpl.title;
    var _desc = _tpl.description;

    switch (_variant mod 4) {
        case 1:
            _title = _tpl.title + " - Urgent";
            _desc += " Timing is becoming critical.";
        break;

        case 2:
            _title = _tpl.title + " - Quiet Handling";
            _desc += " Discretion is specifically requested.";
        break;

        case 3:
            _title = _tpl.title + " - High Stakes";
            _desc += " Rival agencies are expected to compete.";
        break;
    }

    return {
        id: _id,
        title: _title,
        type: _tpl.type,
        difficulty: clamp(_tpl.difficulty + choose(-4, -2, 0, 2, 4), 35, 85),
        reward: max(80, _tpl.reward + choose(-20, -10, 0, 15, 25, 35)),
        duration_hours: max(8, _tpl.duration_hours + choose(-6, -3, 0, 4, 8, 12)),
        risk: clamp(_tpl.risk + choose(-8, -4, 0, 5, 10), 10, 85),
        preferred_role: _tpl.preferred_role,
        weights: _tpl.weights,
        description: _desc,
        patron_name: _patron_name,
        patron_max_party: choose(2, 3, 3)
    };
};

init_contracts = function(_patrons, _templates) {
    var _contracts = [];
    var _cid = 0;

    for (var i = 0; i < array_length(_patrons); i++) {
        var _p = _patrons[i];
        var _primary_tpl = _templates[i mod array_length(_templates)];
        var _m1 = build_contract_mission(_cid, _primary_tpl, _p.name, i);

        array_push(_contracts, {
            id: _cid,
            patron_id: _p.id,
            unlocked: false,
            accepted: false,
            expired: false,
            expires_hour: state.absolute_hour + irandom_range(36, 96),
            ask_text: _p.name + " (" + _p.contact + ") requests help: " + _m1.description,
            mission: _m1
        });
        _cid += 1;

        if (i < 3) {
            var _secondary_tpl = _templates[(i + 1) mod array_length(_templates)];
            var _m2 = build_contract_mission(_cid, _secondary_tpl, _p.name, i + 7);
            array_push(_contracts, {
                id: _cid,
                patron_id: _p.id,
                unlocked: false,
                accepted: false,
                expired: false,
                expires_hour: state.absolute_hour + irandom_range(48, 120),
                ask_text: _p.name + " sends a second inquiry with narrower terms.",
                mission: _m2
            });
            _cid += 1;
        }
    }

    return _contracts;
};

get_patron_index = function(_patron_id) {
    for (var i = 0; i < array_length(state.patrons); i++) {
        if (state.patrons[i].id == _patron_id) return i;
    }
    return -1;
};

refresh_mission_board = function() {
    state.missions = [];

    for (var i = 0; i < array_length(state.contracts); i++) {
        var _c = state.contracts[i];
        var _is_active = _c.unlocked && !_c.accepted && !_c.expired && (state.absolute_hour < _c.expires_hour);
        if (_is_active) {
            var _m = _c.mission;
            _m.contract_index = i;
            _m.expires_hour = _c.expires_hour;
            array_push(state.missions, _m);
        }
    }

    if (array_length(state.missions) <= 0) {
        state.selected_mission_index = -1;
        state.selected_party_ids = [];
    } else if (state.selected_mission_index < 0 || state.selected_mission_index >= array_length(state.missions)) {
        state.selected_mission_index = 0;
    }
};

unlock_patron_contracts = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return;

    var _patron = state.patrons[_patron_index];
    state.selected_patron_index = _patron_index;

    add_log(_patron.name + " contacted you via " + _patron.contact + ".");

    var _unlocked_any = false;
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (state.contracts[i].patron_id == _patron.id && !state.contracts[i].accepted && !state.contracts[i].expired) {
            if (!state.contracts[i].unlocked) {
                state.contracts[i].unlocked = true;
                _unlocked_any = true;
                add_log("Contract unlocked: " + state.contracts[i].mission.title + " (expires in " + format_duration_hours(max(1, state.contracts[i].expires_hour - state.absolute_hour)) + ").");
            }
            add_log("Ask: " + state.contracts[i].ask_text);
        }
    }

    if (!_unlocked_any) {
        add_log("No new contracts from this patron right now.");
    }

    refresh_mission_board();
};

expire_contracts = function() {
    var _changed = false;

    for (var i = 0; i < array_length(state.contracts); i++) {
        if (!state.contracts[i].accepted && !state.contracts[i].expired && state.absolute_hour >= state.contracts[i].expires_hour) {
            state.contracts[i].expired = true;
            _changed = true;
            if (state.contracts[i].unlocked) {
                add_log("Contract expired: " + state.contracts[i].mission.title + ".");
            }
        }
    }

    if (_changed) refresh_mission_board();
};

get_current_party_cap = function() {
    if (state.selected_mission_index >= 0 && state.selected_mission_index < array_length(state.missions)) {
        return state.missions[state.selected_mission_index].patron_max_party;
    }
    return 3;
};

adventurer_core_maxed = function(_a) {
    return (_a.combat >= STAT_CAP &&
            _a.magic >= STAT_CAP &&
            _a.stealth >= STAT_CAP &&
            _a.diplomacy >= STAT_CAP);
};

grow_adventurer_from_mission = function(_adv_id, _difficulty) {
    var _idx = get_adv_index(_adv_id);
    if (_idx < 0) return;

    if (state.adventurers[_idx].status == "retired") return;

    var _boosts = [];
    if (_difficulty >= 65) {
        if (irandom(99) < 50) {
            array_push(_boosts, choose("combat", "magic", "stealth", "diplomacy"));
            array_push(_boosts, _boosts[array_length(_boosts) - 1]);
        } else {
            array_push(_boosts, choose("combat", "magic", "stealth", "diplomacy"));
            var _second = choose("combat", "magic", "stealth", "diplomacy");
            if (_second == _boosts[0]) _second = "reliability";
            array_push(_boosts, _second);
        }
    } else {
        array_push(_boosts, choose("combat", "magic", "stealth", "diplomacy", "reliability"));
    }

    for (var i = 0; i < array_length(_boosts); i++) {
        var _stat = _boosts[i];
        switch (_stat) {
            case "combat": state.adventurers[_idx].combat = min(STAT_CAP, state.adventurers[_idx].combat + 1); break;
            case "magic": state.adventurers[_idx].magic = min(STAT_CAP, state.adventurers[_idx].magic + 1); break;
            case "stealth": state.adventurers[_idx].stealth = min(STAT_CAP, state.adventurers[_idx].stealth + 1); break;
            case "diplomacy": state.adventurers[_idx].diplomacy = min(STAT_CAP, state.adventurers[_idx].diplomacy + 1); break;
            case "reliability": state.adventurers[_idx].reliability = min(99, state.adventurers[_idx].reliability + 1); break;
        }
    }

    add_log(state.adventurers[_idx].name + " improved after mission success.");

    if (adventurer_core_maxed(state.adventurers[_idx]) && state.adventurers[_idx].reliability >= 95) {
        state.adventurers[_idx].status = "retired";
        add_log(state.adventurers[_idx].name + " retired after reaching peak capability.");
    }
};

enter_game_house = function() {
    if (state.game_over) return;
    state.mode = MODE.GAME_HOUSE;
    state.status_line = "At the Gilded Griffin Game House. Time and rivals keep moving.";
    add_log("You step into the Gilded Griffin Game House. The city clock and rival offices continue in the background.");
};

reset_game_house_round = function() {
    state.game_house.craps_phase = "idle";
    state.game_house.craps_point = 0;
    state.game_house.cards_in_round = false;
    state.game_house.cards_player = [];
    state.game_house.cards_dealer = [];
    state.game_house.cards_last_outcome = "";
};

set_game_house_game = function(_game) {
    state.game_house_game = _game;
    reset_game_house_round();
    switch (_game) {
        case "CRAPS": add_log("Table selected: Street Craps. Roll for point."); break;
        case "WHEEL": add_log("Table selected: Wyrm Wheel. Choose a bet and spin."); break;
        case "DRAGON21": add_log("Table selected: Dragon 21. Beat the dealer without busting."); break;
        default: add_log("Unknown table."); break;
    }
};

change_game_house_wager = function(_delta) {
    state.game_house_wager = clamp(state.game_house_wager + _delta, 10, 250);
    add_log("Table wager set to " + string(state.game_house_wager) + "g.");
};

card_draw_value = function() {
    var _rank = irandom_range(1, 13);
    if (_rank > 10) return 10;
    return _rank;
};

card_hand_total = function(_hand) {
    var _sum = 0;
    var _aces = 0;
    for (var i = 0; i < array_length(_hand); i++) {
        var _v = _hand[i];
        if (_v == 1) {
            _aces += 1;
            _sum += 1;
        } else {
            _sum += _v;
        }
    }

    while (_aces > 0 && _sum + 10 <= 21) {
        _sum += 10;
        _aces -= 1;
    }
    return _sum;
};

card_hand_text = function(_hand) {
    if (array_length(_hand) <= 0) return "-";
    var _txt = "";
    for (var i = 0; i < array_length(_hand); i++) {
        var _v = _hand[i];
        var _piece = string(_v);
        if (_v == 1) _piece = "A";
        if (_v == 10) _piece = "10";
        _txt += _piece;
        if (i < array_length(_hand) - 1) _txt += " ";
    }
    return _txt;
};

wheel_number_color = function(_n) {
    if (_n == 0) return "GREEN";
    var _reds = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
    for (var i = 0; i < array_length(_reds); i++) {
        if (_reds[i] == _n) return "RED";
    }
    return "BLACK";
};

game_house_roll_craps = function() {
    if (state.game_over) return;
    var _w = state.game_house_wager;
    if (_w > state.gold) {
        add_log("Not enough gold for that wager.");
        return;
    }

    var _roll = irandom_range(1, 6) + irandom_range(1, 6);
    state.game_house.craps_last_roll = _roll;
    var _phase = state.game_house.craps_phase;
    var _result = "";

    if (_phase == "idle") {
        if (_roll == 7 || _roll == 11) {
            add_gold(_w, "Craps win on come-out roll.");
            _result = "Natural. You win " + string(_w) + "g.";
        } else if (_roll == 2 || _roll == 3 || _roll == 12) {
            spend_gold(_w, "Craps loss on come-out roll.");
            _result = "Crap out. You lose " + string(_w) + "g.";
        } else {
            state.game_house.craps_phase = "point";
            state.game_house.craps_point = _roll;
            _result = "Point is set to " + string(_roll) + ". Roll again before a 7.";
        }
    } else {
        var _pt = state.game_house.craps_point;
        if (_roll == _pt) {
            add_gold(_w, "Craps point made.");
            _result = "Point made. You win " + string(_w) + "g.";
            state.game_house.craps_phase = "idle";
            state.game_house.craps_point = 0;
        } else if (_roll == 7) {
            spend_gold(_w, "Craps seven-out.");
            _result = "Seven out. You lose " + string(_w) + "g.";
            state.game_house.craps_phase = "idle";
            state.game_house.craps_point = 0;
        } else {
            _result = "No decision on " + string(_roll) + ". Point " + string(_pt) + " stands.";
        }
    }

    add_log("Street Craps roll: " + string(_roll) + ". " + _result);
    advance_hours(1);
};

game_house_spin_wheel = function() {
    if (state.game_over) return;
    var _w = state.game_house_wager;
    if (_w > state.gold) {
        add_log("Not enough gold for that wager.");
        return;
    }

    var _n = irandom_range(0, 36);
    var _color = wheel_number_color(_n);
    var _bet = state.game_house.wheel_bet;
    var _won = false;
    var _payout = 0;

    switch (_bet) {
        case "RED": _won = (_color == "RED"); _payout = _w; break;
        case "BLACK": _won = (_color == "BLACK"); _payout = _w; break;
        case "ODD": _won = (_n > 0 && ((_n mod 2) == 1)); _payout = _w; break;
        case "EVEN": _won = (_n > 0 && ((_n mod 2) == 0)); _payout = _w; break;
        case "LOW12": _won = (_n >= 1 && _n <= 12); _payout = _w * 2; break;
        case "MID12": _won = (_n >= 13 && _n <= 24); _payout = _w * 2; break;
        case "HIGH12": _won = (_n >= 25 && _n <= 36); _payout = _w * 2; break;
    }

    state.game_house.wheel_last_number = _n;
    state.game_house.wheel_last_color = _color;

    if (_won) add_gold(_payout, "Wyrm Wheel payout.");
    else spend_gold(_w, "Wyrm Wheel loss.");

    add_log("Wyrm Wheel spun " + string(_n) + " (" + _color + "). Bet: " + _bet + ". " + (_won ? ("Win +" + string(_payout) + "g.") : ("Loss -" + string(_w) + "g.")));
    advance_hours(1);
};

game_house_deal_21 = function() {
    if (state.game_over) return;
    var _w = state.game_house_wager;
    if (_w > state.gold) {
        add_log("Not enough gold for that wager.");
        return;
    }
    if (state.game_house.cards_in_round) {
        add_log("A Dragon 21 hand is already in progress.");
        return;
    }

    state.game_house.cards_player = [card_draw_value(), card_draw_value()];
    state.game_house.cards_dealer = [card_draw_value(), card_draw_value()];
    state.game_house.cards_in_round = true;
    state.game_house.cards_last_outcome = "";

    var _pt = card_hand_total(state.game_house.cards_player);
    var _d_up = state.game_house.cards_dealer[0];
    add_log("Dragon 21 deal: player " + card_hand_text(state.game_house.cards_player) + " (" + string(_pt) + "), dealer showing " + string(_d_up) + ".");

    if (_pt == 21) {
        add_gold(_w + floor(_w * 0.5), "Dragon 21 natural.");
        add_log("Black rune natural. Payout +" + string(_w + floor(_w * 0.5)) + "g.");
        state.game_house.cards_in_round = false;
        state.game_house.cards_last_outcome = "BLACK RUNE NATURAL";
    }

    advance_hours(1);
};

game_house_hit_21 = function() {
    if (!state.game_house.cards_in_round) {
        add_log("No Dragon 21 hand active. Deal first.");
        return;
    }

    array_push(state.game_house.cards_player, card_draw_value());
    var _pt = card_hand_total(state.game_house.cards_player);
    add_log("Dragon 21 hit: " + card_hand_text(state.game_house.cards_player) + " (" + string(_pt) + ").");

    if (_pt > 21) {
        spend_gold(state.game_house_wager, "Dragon 21 bust.");
        add_log("Bust. You lose " + string(state.game_house_wager) + "g.");
        state.game_house.cards_in_round = false;
        state.game_house.cards_last_outcome = "BUST";
    }

    advance_hours(1);
};

game_house_stand_21 = function() {
    if (!state.game_house.cards_in_round) {
        add_log("No Dragon 21 hand active. Deal first.");
        return;
    }

    var _pt = card_hand_total(state.game_house.cards_player);
    var _dt = card_hand_total(state.game_house.cards_dealer);

    while (_dt < 17) {
        array_push(state.game_house.cards_dealer, card_draw_value());
        _dt = card_hand_total(state.game_house.cards_dealer);
    }

    if (_dt > 21 || _pt > _dt) {
        add_gold(state.game_house_wager, "Dragon 21 win.");
        add_log("Dealer " + card_hand_text(state.game_house.cards_dealer) + " (" + string(_dt) + "). You win +" + string(state.game_house_wager) + "g.");
        state.game_house.cards_last_outcome = "WIN";
    } else if (_pt < _dt) {
        spend_gold(state.game_house_wager, "Dragon 21 loss.");
        add_log("Dealer " + card_hand_text(state.game_house.cards_dealer) + " (" + string(_dt) + "). You lose -" + string(state.game_house_wager) + "g.");
        state.game_house.cards_last_outcome = "LOSS";
    } else {
        add_log("Push at " + string(_pt) + ". No gold changes hands.");
        state.game_house.cards_last_outcome = "PUSH";
    }

    state.game_house.cards_in_round = false;
    advance_hours(1);
};

office_activity_visit_game_house = function() {
    enter_game_house();
};

office_activity_research = function() {
    if (state.game_over) return;
    var _options = [];
    for (var i = 0; i < array_length(state.patrons); i++) {
        array_push(_options, i);
    }
    if (array_length(_options) <= 0) return;

    var _pick = _options[irandom(array_length(_options) - 1)];
    unlock_patron_contracts(_pick);
    add_log("Research uncovered patron leads and opened contract channels.");
};

office_activity_recruit = function() {
    if (state.game_over) return;
    if (array_length(state.adventurers) >= 20) {
        add_log("Roster is full. Expand operations before recruiting more.");
        return;
    }

    if (array_length(state.free_agents) <= 0) {
        refresh_free_agent_market();
    }

    state.mode = MODE.BUYING;
    state.status_line = "Free-agent market open. Build your offer.";
    add_log("Entering free-agent market. Competing agencies are bidding.");
    rebuild_buttons();
};

office_activity_scout_rival = function() {
    if (state.game_over) return;
    var _cost = 18;
    if (state.gold < _cost) {
        add_log("Scouting rival talent requires 18g.");
        return;
    }
    spend_gold(_cost, "Paid scouts to profile rival bids.");

    if (array_length(state.free_agents) <= 0) {
        refresh_free_agent_market();
    }

    for (var i = 0; i < array_length(state.free_agents); i++) {
        state.free_agents[i].rival_pressure = max(5, state.free_agents[i].rival_pressure - irandom_range(3, 10));
    }
    add_log("Scouting report complete: rival pressure reduced across current free agents.");
};

office_activity_counteroffer = function() {
    if (state.game_over) return;
    var _targets = [];
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status == "unavailable") array_push(_targets, i);
    }

    if (array_length(_targets) <= 0) {
        add_log("No adventurers currently lured away by rivals.");
        return;
    }

    var _fee = 60;
    if (state.gold < _fee) {
        add_log("Counteroffers require 60g.");
        return;
    }
    spend_gold(_fee, "Issued a premium counteroffer package.");

    var _pick = _targets[irandom(array_length(_targets) - 1)];
    if (irandom(99) < 65) {
        state.adventurers[_pick].status = "available";
        add_log(state.adventurers[_pick].name + " accepted your counteroffer and returned.");
    } else {
        add_log(state.adventurers[_pick].name + " stayed with a rival agency for now.");
    }
};

process_daily_finance = function() {
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
};

process_world_pulse = function() {
    if (state.game_over) return;
    if (state.world_pulse_last_hour == state.absolute_hour) return;
    state.world_pulse_last_hour = state.absolute_hour;

    // Global world pulse every 3 in-game hours, regardless of current mode.
    if ((state.absolute_hour mod 3) != 0) return;
    if (irandom(99) >= 42) return;

    var _event_roll = irandom_range(0, 4);
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
    }
};

print_patrons = function() {
    add_log("Patron contacts:");

    for (var i = 0; i < array_length(state.patrons); i++) {
        var _p = state.patrons[i];
        var _available_contracts = 0;
        for (var c = 0; c < array_length(state.contracts); c++) {
            var _ct = state.contracts[c];
            if (_ct.patron_id == _p.id && !_ct.accepted && !_ct.expired) {
                _available_contracts += 1;
            }
        }

        add_log(string(i + 1) + ") " + _p.name + " [" + _p.personality + "] - open requests: " + string(_available_contracts));
    }
    add_log("Use PATRON <n> or click a patron button to read their ask and unlock contracts.");
};

build_market_candidate = function() {
    var _cand = generate_free_agent();
    var _power = (_cand.combat + _cand.magic + _cand.stealth + _cand.diplomacy) / 4;
    var _profile = clamp(round(_power * 10 + _cand.reliability * 0.3), 40, 120);
    var _styles = ["money_first", "prestige_first", "security_first", "loyalty_first", "hardline"];
    var _style = _styles[irandom(array_length(_styles) - 1)];

    _cand.ask_bonus = irandom_range(0, 120) + max(0, _profile - 80);
    _cand.ask_rate = max(16, _cand.adventure_rate + irandom_range(-6, 10) + floor((_profile - 70) / 6));
    _cand.min_commission = clamp(0.10 + irandom_range(0, 12) * 0.01, 0.10, 0.30);
    _cand.rival_pressure = irandom_range(30, 90);
    _cand.profile_score = _profile;
    _cand.negotiation_style = _style;

    _cand.pref_bonus_w = 1.0;
    _cand.pref_rate_w = 1.0;
    _cand.pref_comm_w = 1.0;
    _cand.pref_rep_w = 1.0;
    _cand.pref_rival_w = 1.0;
    _cand.style_blurb = "Balanced negotiator.";

    switch (_style) {
        case "money_first":
            _cand.pref_bonus_w = 1.5;
            _cand.pref_rate_w = 1.4;
            _cand.pref_comm_w = 0.8;
            _cand.pref_rep_w = 0.9;
            _cand.pref_rival_w = 1.1;
            _cand.style_blurb = "Money-first: values direct pay and bonus.";
        break;

        case "prestige_first":
            _cand.pref_bonus_w = 0.8;
            _cand.pref_rate_w = 0.9;
            _cand.pref_comm_w = 1.1;
            _cand.pref_rep_w = 1.7;
            _cand.pref_rival_w = 0.9;
            _cand.style_blurb = "Prestige-first: values your office reputation.";
        break;

        case "security_first":
            _cand.pref_bonus_w = 1.2;
            _cand.pref_rate_w = 0.9;
            _cand.pref_comm_w = 1.7;
            _cand.pref_rep_w = 1.0;
            _cand.pref_rival_w = 1.0;
            _cand.style_blurb = "Security-first: hates high commission cuts.";
        break;

        case "loyalty_first":
            _cand.pref_bonus_w = 0.9;
            _cand.pref_rate_w = 1.0;
            _cand.pref_comm_w = 1.1;
            _cand.pref_rep_w = 1.4;
            _cand.pref_rival_w = 0.7;
            _cand.style_blurb = "Loyalty-first: prefers stable long-term offices.";
        break;

        case "hardline":
            _cand.pref_bonus_w = 1.3;
            _cand.pref_rate_w = 1.3;
            _cand.pref_comm_w = 1.5;
            _cand.pref_rep_w = 1.2;
            _cand.pref_rival_w = 1.3;
            _cand.style_blurb = "Hardline: aggressive demands, difficult close.";
        break;
    }
    return _cand;
};

market_style_line = function(_style, _moment) {
    switch (_style) {
        case "money_first":
            switch (_moment) {
                case "target": return "\"I'm here for numbers. Show me real coin.\"";
                case "offer": return "\"Your offer is noted. Better terms close faster.\"";
                case "counter": return "\"Raise the money and we can finish this today.\"";
                case "accept": return "\"Terms are strong. We have a deal.\"";
                case "reject": return "\"Another agency beat your numbers.\"";
            }
        break;

        case "prestige_first":
            switch (_moment) {
                case "target": return "\"I sign where reputation opens doors.\"";
                case "offer": return "\"I will consider this in light of your office standing.\"";
                case "counter": return "\"Meet these terms and your banner earns my name.\"";
                case "accept": return "\"Your office carries weight. I accept.\"";
                case "reject": return "\"I chose an office with stronger standing.\"";
            }
        break;

        case "security_first":
            switch (_moment) {
                case "target": return "\"Stability first. Keep the cuts fair.\"";
                case "offer": return "\"I'm reviewing risk and long-term security.\"";
                case "counter": return "\"Lower the cut and we can move forward.\"";
                case "accept": return "\"Fair terms. I'm in.\"";
                case "reject": return "\"The structure was too risky for me.\"";
            }
        break;

        case "loyalty_first":
            switch (_moment) {
                case "target": return "\"I stay where trust is earned.\"";
                case "offer": return "\"I care more about fit than flash.\"";
                case "counter": return "\"Show commitment and I'll show loyalty.\"";
                case "accept": return "\"I believe in this office. Deal.\"";
                case "reject": return "\"The fit wasn't right this time.\"";
            }
        break;

        case "hardline":
            switch (_moment) {
                case "target": return "\"No soft offers. No wasted time.\"";
                case "offer": return "\"This starts the conversation, not the contract.\"";
                case "counter": return "\"These are my terms. Take them or walk.\"";
                case "accept": return "\"You met my demands. Signed.\"";
                case "reject": return "\"You couldn't meet the number. I'm gone.\"";
            }
        break;
    }

    switch (_moment) {
        case "target": return "\"Let's discuss terms.\"";
        case "offer": return "\"Offer received.\"";
        case "counter": return "\"I have a counterproposal.\"";
        case "accept": return "\"Deal accepted.\"";
        case "reject": return "\"Offer declined.\"";
    }
    return "";
};

refresh_free_agent_market = function() {
    state.free_agents = [];
    for (var i = 0; i < 5; i++) {
        array_push(state.free_agents, build_market_candidate());
    }

    state.selected_free_agent_index = 0;
    state.offer_bonus = 0;
    state.offer_rate_delta = 0;
    state.offer_commission = 0.22;
    add_log("Free-agent market board refreshed.");
};

select_free_agent_target = function(_idx) {
    if (array_length(state.free_agents) <= 0) {
        add_log("No free agents on the board. Refresh market.");
        return;
    }
    state.selected_free_agent_index = clamp(_idx, 0, array_length(state.free_agents) - 1);
    var _fa = state.free_agents[state.selected_free_agent_index];
    add_log("Target selected: " + _fa.name + " | Ask bonus " + string(_fa.ask_bonus) + "g | Ask rate " + string(_fa.ask_rate) + "g/day.");
    add_log("Negotiation style: " + string_upper(_fa.negotiation_style) + ". " + _fa.style_blurb);
    add_log(_fa.name + ": " + market_style_line(_fa.negotiation_style, "target"));
};

submit_free_agent_offer = function() {
    if (state.game_over) return;
    if (array_length(state.free_agents) <= 0 || state.selected_free_agent_index < 0) {
        add_log("Select a free agent first.");
        return;
    }
    if (is_struct(state.pending_signing)) {
        add_log("A signing negotiation is already pending.");
        return;
    }

    var _fa = state.free_agents[state.selected_free_agent_index];
    var _offer_rate = max(10, _fa.ask_rate + state.offer_rate_delta);
    var _offer_bonus = max(0, state.offer_bonus);
    var _offer_comm = clamp(state.offer_commission, 0.10, 0.35);
    if (_offer_bonus > state.gold) {
        add_log("Insufficient gold for that signing bonus.");
        return;
    }

    var _score = 35;
    _score += (state.reputation - 40) * (0.8 * _fa.pref_rep_w);
    _score += (_offer_bonus - _fa.ask_bonus) * (0.20 * _fa.pref_bonus_w);
    _score += (_offer_rate - _fa.ask_rate) * (1.2 * _fa.pref_rate_w);
    _score += (_fa.min_commission - _offer_comm) * (220 * _fa.pref_comm_w);
    _score -= _fa.rival_pressure * (0.45 * _fa.pref_rival_w);

    if (_fa.negotiation_style == "hardline") _score -= 6;
    if (_fa.negotiation_style == "loyalty_first" && state.reputation >= 55) _score += 5;
    _score += irandom_range(-15, 15);

    state.pending_signing = {
        stage: "submitted",
        candidate: _fa,
        candidate_index: state.selected_free_agent_index,
        offer_bonus: _offer_bonus,
        offer_rate: _offer_rate,
        offer_commission: _offer_comm,
        score: _score,
        due_hour: state.absolute_hour + irandom_range(6, 18)
    };

    add_log("Offer submitted to " + _fa.name + ": bonus " + string(_offer_bonus) + "g, rate " + string(_offer_rate) + "g/day, commission " + string(round(_offer_comm * 100)) + "%.");
    add_log("Negotiation read: " + _fa.style_blurb);
    add_log(_fa.name + ": " + market_style_line(_fa.negotiation_style, "offer"));
    add_log("Decision pending. Rival agencies are making counteroffers.");
};

resolve_pending_signing = function() {
    if (!is_struct(state.pending_signing)) return;
    if (!variable_struct_exists(state.pending_signing, "stage")) state.pending_signing.stage = "submitted";
    if (state.pending_signing.stage != "submitted") return;
    if (state.absolute_hour < state.pending_signing.due_hour) return;

    var _deal = state.pending_signing;
    var _accepted = (_deal.score >= 60);
    var _counter = (!_accepted && _deal.score >= 40);

    if (_accepted) {
        if (_deal.offer_bonus > 0) spend_gold(_deal.offer_bonus, "Signing bonus paid to " + _deal.candidate.name + ".");
        var _new = _deal.candidate;
        _new.id = state.next_adv_id;
        _new.adventure_rate = _deal.offer_rate;
        _new.commission_rate = _deal.offer_commission;
        _new.status = "available";
        state.next_adv_id += 1;
        array_push(state.adventurers, _new);
        add_log(_new.name + " accepted representation terms.");
        add_log(_new.name + ": " + market_style_line(_new.negotiation_style, "accept"));
        add_log("Contract terms: " + string(_new.adventure_rate) + "g/day with " + string(round(_new.commission_rate * 100)) + "% agency commission.");

        if (_deal.candidate_index >= 0 && _deal.candidate_index < array_length(state.free_agents)) {
            array_delete(state.free_agents, _deal.candidate_index, 1);
        }
        state.pending_signing = undefined;
    } else if (_counter) {
        var _counter_bonus = max(_deal.offer_bonus, _deal.candidate.ask_bonus + irandom_range(0, 35));
        var _counter_rate = max(_deal.offer_rate, _deal.candidate.ask_rate + irandom_range(0, 4));
        var _counter_comm = min(_deal.offer_commission, _deal.candidate.min_commission - choose(0.00, 0.01, 0.02));
        _counter_comm = clamp(_counter_comm, 0.10, 0.35);

        switch (_deal.candidate.negotiation_style) {
            case "money_first":
                _counter_bonus += irandom_range(15, 45);
                _counter_rate += irandom_range(2, 6);
                _counter_comm = max(_counter_comm, _deal.offer_commission - 0.01);
            break;

            case "prestige_first":
                _counter_bonus = max(0, _counter_bonus - irandom_range(5, 20));
                _counter_rate = max(_deal.offer_rate, _counter_rate - irandom_range(0, 3));
                if (state.reputation >= 60) _counter_comm = min(_counter_comm + 0.01, 0.35);
            break;

            case "security_first":
                _counter_bonus += irandom_range(5, 20);
                _counter_rate = max(_deal.offer_rate, _counter_rate - irandom_range(0, 2));
                _counter_comm = max(0.10, _counter_comm - 0.02);
            break;

            case "loyalty_first":
                if (state.reputation >= 55) {
                    _counter_bonus = max(0, _counter_bonus - irandom_range(10, 25));
                    _counter_rate = max(_deal.offer_rate, _counter_rate - irandom_range(1, 3));
                } else {
                    _counter_bonus += irandom_range(10, 25);
                }
            break;

            case "hardline":
                _counter_bonus += irandom_range(20, 55);
                _counter_rate += irandom_range(3, 8);
                _counter_comm = max(0.10, _counter_comm - 0.01);
            break;
        }

        _counter_bonus = max(0, _counter_bonus);
        _counter_rate = max(10, _counter_rate);
        _counter_comm = clamp(_counter_comm, 0.10, 0.35);

        state.pending_signing.stage = "counter";
        state.pending_signing.counter_bonus = _counter_bonus;
        state.pending_signing.counter_rate = _counter_rate;
        state.pending_signing.counter_commission = _counter_comm;
        state.pending_signing.counter_deadline = state.absolute_hour + irandom_range(8, 20);
        add_log(_deal.candidate.name + " countered your offer.");
        add_log("Counter terms: bonus " + string(_counter_bonus) + "g, rate " + string(_counter_rate) + "g/day, commission " + string(round(_counter_comm * 100)) + "%.");
        add_log(_deal.candidate.name + ": " + market_style_line(_deal.candidate.negotiation_style, "counter"));
        add_log("Respond before " + format_duration_hours(max(0, state.pending_signing.counter_deadline - state.absolute_hour)) + ".");
    } else {
        add_log(_deal.candidate.name + " rejected your offer and signed elsewhere.");
        add_log(_deal.candidate.name + ": " + market_style_line(_deal.candidate.negotiation_style, "reject"));
        state.pending_signing = undefined;
    }
    if (array_length(state.free_agents) <= 0) state.selected_free_agent_index = -1;
    else state.selected_free_agent_index = clamp(state.selected_free_agent_index, 0, array_length(state.free_agents) - 1);
};

accept_counter_offer = function() {
    if (!is_struct(state.pending_signing)) {
        add_log("No counteroffer to accept.");
        return;
    }
    if (!variable_struct_exists(state.pending_signing, "stage") || state.pending_signing.stage != "counter") {
        add_log("No counteroffer is currently pending.");
        return;
    }

    var _deal = state.pending_signing;
    if (state.absolute_hour > _deal.counter_deadline) {
        add_log("Counteroffer expired.");
        state.pending_signing = undefined;
        return;
    }
    if (_deal.counter_bonus > state.gold) {
        add_log("Insufficient gold to meet the counter bonus.");
        return;
    }

    if (_deal.counter_bonus > 0) spend_gold(_deal.counter_bonus, "Counteroffer signing bonus paid to " + _deal.candidate.name + ".");
    var _new = _deal.candidate;
    _new.id = state.next_adv_id;
    _new.adventure_rate = _deal.counter_rate;
    _new.commission_rate = _deal.counter_commission;
    _new.status = "available";
    state.next_adv_id += 1;
    array_push(state.adventurers, _new);

    if (_deal.candidate_index >= 0 && _deal.candidate_index < array_length(state.free_agents)) {
        array_delete(state.free_agents, _deal.candidate_index, 1);
    }
    add_log(_new.name + ": " + market_style_line(_new.negotiation_style, "accept"));
    add_log(_new.name + " accepted your acceptance of the counteroffer.");
    add_log("Contract terms: " + string(_new.adventure_rate) + "g/day with " + string(round(_new.commission_rate * 100)) + "% agency commission.");

    state.pending_signing = undefined;
    if (array_length(state.free_agents) <= 0) state.selected_free_agent_index = -1;
    else state.selected_free_agent_index = clamp(state.selected_free_agent_index, 0, array_length(state.free_agents) - 1);
};

decline_counter_offer = function() {
    if (!is_struct(state.pending_signing)) {
        add_log("No counteroffer to decline.");
        return;
    }
    if (!variable_struct_exists(state.pending_signing, "stage") || state.pending_signing.stage != "counter") {
        add_log("No counteroffer is currently pending.");
        return;
    }
    add_log("You declined " + state.pending_signing.candidate.name + "'s counteroffer.");
    state.pending_signing = undefined;
};
get_adv_index = function(_id) {
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].id == _id) return i;
    }
    return -1;
};

count_active_assignments_for_id = function(_id) {
    var _count = 0;
    for (var i = 0; i < array_length(state.active_missions); i++) {
        var _m = state.active_missions[i];
        for (var j = 0; j < array_length(_m.party_ids); j++) {
            if (_m.party_ids[j] == _id) {
                _count += 1;
            }
        }
    }
    return _count;
};

is_adventurer_committed = function(_id) {
    return count_active_assignments_for_id(_id) > 0;
};

party_has = function(_id) {
    for (var i = 0; i < array_length(state.selected_party_ids); i++) {
        if (state.selected_party_ids[i] == _id) return true;
    }
    return false;
};

selected_party = function() {
    var _party = [];
    for (var i = 0; i < array_length(state.selected_party_ids); i++) {
        var _idx = get_adv_index(state.selected_party_ids[i]);
        if (_idx >= 0 && state.adventurers[_idx].status == "available") {
            array_push(_party, state.adventurers[_idx]);
        }
    }
    return _party;
};

toggle_party = function(_id) {
    var _idx = get_adv_index(_id);
    if (_idx < 0) return;

    var _adv = state.adventurers[_idx];
    if (_adv.status != "available" || is_adventurer_committed(_id)) {
        add_log(_adv.name + " is not available.");
        return;
    }

    if (party_has(_id)) {
        for (var i = 0; i < array_length(state.selected_party_ids); i++) {
            if (state.selected_party_ids[i] == _id) {
                array_delete(state.selected_party_ids, i, 1);
                add_log(_adv.name + " removed from party.");
                return;
            }
        }
    } else {
        var _cap = get_current_party_cap();
        if (array_length(state.selected_party_ids) >= _cap) {
            add_log("This contract supports up to " + string(_cap) + " adventurer(s).");
            return;
        }
        array_push(state.selected_party_ids, _id);
        add_log(_adv.name + " added to party.");
    }
};

select_mission = function(_idx) {
    dismiss_intro();

    if (array_length(state.missions) <= 0) {
        state.selected_mission_index = -1;
        add_log("No unlocked missions. Review patron contacts first.");
        return;
    }

    state.selected_mission_index = clamp(_idx, 0, array_length(state.missions) - 1);
    add_log("Selected mission: " + state.missions[state.selected_mission_index].title + ".");
};

simulate_mission = function(_mission, _party, _delay_hours) {
    if (is_undefined(_delay_hours)) _delay_hours = 0;
    var _raw_power = 0;
    var _rel_sum = 0;

    for (var i = 0; i < array_length(_party); i++) {
        var _a = _party[i];
        var _weights = _mission.weights;
        var _member = (
            _a.combat * _weights.combat +
            _a.magic * _weights.magic +
            _a.stealth * _weights.stealth +
            _a.diplomacy * _weights.diplomacy
        ) * 10;

        if (_a.role == _mission.preferred_role) _member += 12;
        _raw_power += _member;
        _rel_sum += _a.reliability;
    }

    var _rel_avg = _rel_sum / max(1, array_length(_party));
    var _rel_mod = 0.85 + clamp((_rel_avg - 40) / 60, 0, 1) * 0.30;
    var _roll = irandom_range(-12, 12);
    var _target = _mission.difficulty + (_mission.risk * 0.20);
    var _delay_penalty = min(12, floor(_delay_hours / 6) * 2);
    var _score = (_raw_power * _rel_mod + _roll) - _delay_penalty;
    var _margin = round(_score - _target);

    var _outcome = "failure";
    var _gold = 0;
    var _rep = -2;

    if (_margin >= 12) {
        _outcome = "success";
        _gold = _mission.reward;
        _rep = 2;
    } else if (_margin >= -8) {
        _outcome = "partial";
        _gold = floor(_mission.reward * 0.60);
        _rep = 1;
    } else {
        _outcome = "failure";
        _gold = choose(0, floor(_mission.reward * 0.15));
        _rep = -2;
    }

    var _injury = false;
    var _injured_id = -1;
    var _injury_chance = 0;

    if (_outcome == "failure") _injury_chance = 28 + _mission.risk;
    else if (_outcome == "partial") _injury_chance = 10 + floor(_mission.risk * 0.5);
    else _injury_chance = floor(_mission.risk * 0.2);

    if (array_length(_party) > 0 && irandom(99) < _injury_chance) {
        _injury = true;
        _injured_id = _party[irandom(array_length(_party) - 1)].id;
    }

    var _events = [];
    array_push(_events, "Mission brief: " + _mission.title);
    array_push(_events, "Difficulty " + string(_mission.difficulty) + " / Risk " + string(_mission.risk) + "%");
    array_push(_events, "Team score " + string(round(_score)) + " vs target " + string(round(_target)) + ".");
    if (_delay_hours > 0) {
        array_push(_events, "Delays accumulated: " + format_duration_hours(_delay_hours) + " (efficiency penalty applied).");
    }

    switch (_outcome) {
        case "success": array_push(_events, "Outcome: SUCCESS. Patron terms fulfilled."); break;
        case "partial": array_push(_events, "Outcome: PARTIAL SUCCESS. Concessions required."); break;
        default: array_push(_events, "Outcome: FAILURE. Contract terms not met."); break;
    }

    if (_injury) array_push(_events, "An adventurer was injured during extraction.");
    else array_push(_events, "No major injuries reported.");

    return {
        outcome: _outcome,
        outcome_text: string_upper(_outcome),
        gold_earned: _gold,
        reputation_delta: _rep,
        injury_happened: _injury,
        injured_adv_id: _injured_id,
        event_log: _events,
        acknowledged: false
    };
};

open_next_report = function() {
    if (array_length(state.pending_reports) <= 0) return;

    state.last_result = state.pending_reports[0];
    array_delete(state.pending_reports, 0, 1);

    state.mode = MODE.MISSION_RESULT;
    state.status_line = "Mission report received: " + state.last_result.mission_title;
    rebuild_buttons();
};

resolve_active_mission = function(_active) {
    var _mission = _active.mission;
    var _party = [];
    var _party_names = "";

    for (var i = 0; i < array_length(_active.party_ids); i++) {
        var _id = _active.party_ids[i];
        var _idx = get_adv_index(_id);
        if (_idx >= 0) {
            array_push(_party, state.adventurers[_idx]);
            _party_names += state.adventurers[_idx].name;
            if (i < array_length(_active.party_ids) - 1) _party_names += ", ";
        }
    }

    var _result = simulate_mission(_mission, _party, _active.delay_hours);
    var _mission_hours = max(1, state.absolute_hour - _active.launched_hour);
    var _pay_days = max(1, ceil(_mission_hours / 24));
    var _adventurer_payout = 0;
    var _agent_cut = 0;

    for (var pay_i = 0; pay_i < array_length(_party); pay_i++) {
        var _mbr = _party[pay_i];
        var _day_rate = variable_struct_exists(_mbr, "adventure_rate") ? _mbr.adventure_rate : 24;
        var _commission = variable_struct_exists(_mbr, "commission_rate") ? _mbr.commission_rate : 0.22;
        var _gross_fee = _day_rate * _pay_days;
        var _cut = floor(_gross_fee * _commission);
        _agent_cut += _cut;
        _adventurer_payout += (_gross_fee - _cut);
    }

    var _net_gain = _result.gold_earned - _adventurer_payout;
    add_gold(_net_gain);
    _result.gold_earned = _net_gain;
    state.reputation = clamp(state.reputation + _result.reputation_delta, 0, 100);
    add_log("Payout breakdown: patron " + string(_result.gold_earned + _adventurer_payout) + "g, adventurers -" + string(_adventurer_payout) + "g, agency cut " + string(_agent_cut) + "g.");

    if (_result.outcome == "success") {
        for (var g = 0; g < array_length(_active.party_ids); g++) {
            grow_adventurer_from_mission(_active.party_ids[g], _mission.difficulty);
        }
    }

    for (var p = 0; p < array_length(_active.party_ids); p++) {
        var _ret_id = _active.party_ids[p];
        var _ret_idx = get_adv_index(_ret_id);
        if (_ret_idx >= 0) {
            // Keep on_mission if they are still assigned elsewhere.
            if (count_active_assignments_for_id(_ret_id) <= 1) {
                state.adventurers[_ret_idx].status = "available";
            }
        }
    }

    if (_result.injury_happened) {
        var _inj_idx = get_adv_index(_result.injured_adv_id);
        if (_inj_idx >= 0) {
            state.adventurers[_inj_idx].status = "injured";
        }
    }

    _result.acknowledged = false;
    _result.mission_title = _mission.title;
    _result.party_names = _party_names;
    _result.completed_day = state.day;
    _result.completed_hour = state.hour;
    _result.delay_hours = _active.delay_hours;

    add_log("Mission team returned: " + _mission.title + ". Report delivered to desk.");
    array_push(state.pending_reports, _result);

    var _can_open = !is_struct(state.last_result) ||
                    !variable_struct_exists(state.last_result, "acknowledged") ||
                    state.last_result.acknowledged;

    if (_can_open) {
        open_next_report();
    }
};

process_hour_tick = function() {
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
};

advance_hours = function(_hours) {
    var _h = max(0, _hours);
    repeat (_h) {
        process_hour_tick();
    }
};

run_overnight_maintenance = function() {
    var _recovered = 0;
    var _lured = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status == "injured" && irandom(99) < 35) {
            state.adventurers[i].status = "available";
            _recovered += 1;
        }

        if (state.adventurers[i].status == "available") {
            var _power = (state.adventurers[i].combat + state.adventurers[i].magic + state.adventurers[i].stealth + state.adventurers[i].diplomacy) / 4;
            if (_power >= 9 && irandom(99) < 6) {
                state.adventurers[i].status = "unavailable";
                _lured += 1;
                add_log(state.adventurers[i].name + " accepted a rival agency offer.");
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
};

end_day = function() {
    if (state.game_over) return;
    add_log("Office closes for the day.");

    var _hours_to_next_morning = (24 - state.hour) + 8;
    advance_hours(_hours_to_next_morning);

    run_overnight_maintenance();

    add_log("Office opens for day " + string(state.day) + " at " + format_hh00(state.hour) + ".");
    state.status_line = "A new day begins in " + state.season + ", Y" + string(state.year) + ".";

    var _can_open = !is_struct(state.last_result) ||
                    !variable_struct_exists(state.last_result, "acknowledged") ||
                    state.last_result.acknowledged;

    if (_can_open && array_length(state.pending_reports) > 0) {
        open_next_report();
    }

    rebuild_buttons();
};

start_mission = function() {
    if (state.game_over) {
        add_log("Operations halted: guild office is bankrupt.");
        return;
    }

    if (state.selected_mission_index < 0 || state.selected_mission_index >= array_length(state.missions)) {
        add_log("Select a mission first.");
        return;
    }

    var _party = selected_party();
    if (array_length(_party) == 0) {
        add_log("Select at least one available adventurer.");
        return;
    }

    var _mission = state.missions[state.selected_mission_index];
    var _one_way = max(1, _mission.duration_hours + irandom_range(-2, 2));
    var _round_trip = _one_way * 2;

    var _party_ids = [];
    for (var i = 0; i < array_length(_party); i++) {
        var _idx = get_adv_index(_party[i].id);
        if (_idx >= 0) {
            if (state.adventurers[_idx].status != "available" || is_adventurer_committed(state.adventurers[_idx].id)) {
                add_log(state.adventurers[_idx].name + " is already committed to another mission.");
                return;
            }
            state.adventurers[_idx].status = "on_mission";
            array_push(_party_ids, _party[i].id);
        }
    }

    var _assignment = {
        mission: _mission,
        contract_index: _mission.contract_index,
        party_ids: _party_ids,
        launched_hour: state.absolute_hour,
        objective_hour: state.absolute_hour + _one_way,
        planned_due_hour: state.absolute_hour + _round_trip,
        due_hour: state.absolute_hour + _round_trip,
        phase: "outbound",
        next_update_hour: state.absolute_hour + irandom_range(3, 6),
        delay_hours: 0,
        status: "active"
    };

    array_push(state.active_missions, _assignment);

    if (_mission.contract_index >= 0 && _mission.contract_index < array_length(state.contracts)) {
        state.contracts[_mission.contract_index].accepted = true;
    }
    refresh_mission_board();

    var _open_slots = max(0, _mission.patron_max_party - array_length(_party_ids));
    var _agent_margin = _open_slots * state.patron_slot_fee;
    if (_agent_margin > 0) {
        add_gold(_agent_margin);
        add_log("Agent margin secured: +" + string(_agent_margin) + "g (left " + string(_open_slots) + " funded slot(s) unused).");
    }

    state.selected_party_ids = [];
    add_log("Mission started: " + _mission.title + " | To objective " + format_duration_hours(_one_way) + ", est. full cycle " + format_duration_hours(_round_trip) + ".");
    state.status_line = "Mission in progress: " + _mission.title;

    state.mode = MODE.PLANNING;
    rebuild_buttons();
};

print_missions = function() {
    if (array_length(state.missions) <= 0) {
        add_log("No unlocked missions. Review patron messages first.");
        return;
    }

    add_log("Available missions:");
    for (var i = 0; i < array_length(state.missions); i++) {
        var _m = state.missions[i];
        var _expires_in = max(0, _m.expires_hour - state.absolute_hour);
        add_log(string(i + 1) + ") " + _m.title + " [Patron: " + _m.patron_name + ", Diff " + string(_m.difficulty) + ", Reward " + string(_m.reward) + "g, Expires in " + format_duration_hours(_expires_in) + "]");
    }
};

print_adventurers = function() {
    add_log("Adventurers:");
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        add_log(string(i + 1) + ") " + _a.name + " (" + _a.role + ") C" + string(_a.combat) + " M" + string(_a.magic) + " S" + string(_a.stealth) + " D" + string(_a.diplomacy) + " R" + string(_a.reliability) + " | " + string(_a.adventure_rate) + "g/day | Comm " + string(round(_a.commission_rate * 100)) + "% [" + string_upper(_a.status) + "]");
    }
};

button_add = function(_label, _action, _value) {
    var _b = {
        label: _label,
        action: _action,
        value: _value,
        row_units: 1,
        x1: 0, y1: 0, x2: 0, y2: 0
    };
    array_push(state.buttons, _b);
};

add_office_activity_buttons = function() {
    button_add("Visit Game House", "goto_game_house", -1);
    button_add("Research Patrons", "act_research", -1);
    button_add("Recruit Free Agent", "act_recruit", -1);
    button_add("Scout Rival Talent", "act_scout", -1);
    button_add("Counteroffer Talent", "act_counteroffer", -1);
};

rebuild_buttons = function() {
    state.buttons = [];
    state.button_page = 0;

    if (state.game_over) {
        button_add("Guild Closed - Review Logs", "noop", -1);
        return;
    }

    switch (state.mode) {
        case MODE.PLANNING:
            button_add("View Patron Requests", "goto_contracting", -1);
            button_add("View Missions", "goto_review", -1);
            button_add("Free Agent Market", "goto_market", -1);
            button_add("View Adventurers", "show_adventurers", -1);
            button_add("Start Mission", "start_mission", -1);
            button_add("End Day", "end_day", -1);
            add_office_activity_buttons();
        break;

        case MODE.BUYING:
            button_add("Back to Planning", "goto_planning", -1);
            button_add("Refresh Market", "market_refresh", -1);
            button_add("Submit Offer", "market_submit", -1);
            button_add("Bonus -10", "market_bonus_add", -10);
            button_add("Bonus +10", "market_bonus_add", 10);
            button_add("Rate -5", "market_rate_add", -5);
            button_add("Rate +5", "market_rate_add", 5);
            button_add("Commission -1%", "market_comm_add", -0.01);
            button_add("Commission +1%", "market_comm_add", 0.01);
            if (is_struct(state.pending_signing) &&
                variable_struct_exists(state.pending_signing, "stage") &&
                state.pending_signing.stage == "counter") {
                button_add("Accept Counter", "market_accept_counter", -1);
                button_add("Decline Counter", "market_decline_counter", -1);
            }
            for (var fa_i = 0; fa_i < array_length(state.free_agents); fa_i++) {
                button_add("Target " + string(fa_i + 1) + ": " + state.free_agents[fa_i].name, "market_select", fa_i);
            }
            add_office_activity_buttons();
        break;

        case MODE.CONTRACTING:
            button_add("Back to Planning", "goto_planning", -1);
            button_add("Mission Board", "goto_review", -1);
            for (var p = 0; p < array_length(state.patrons); p++) {
                button_add("Patron " + string(p + 1) + ": " + state.patrons[p].name, "select_patron", p);
            }
            add_office_activity_buttons();
        break;

        case MODE.MISSION_REVIEW:
            button_add("Back to Planning", "goto_planning", -1);
            button_add("Start Mission", "start_mission", -1);
            button_add("Clear Party", "clear_party", -1);
            for (var i = 0; i < array_length(state.missions); i++) {
                button_add("Mission " + string(i + 1) + ": " + state.missions[i].title, "select_mission", i);
            }
            for (var j = 0; j < array_length(state.adventurers); j++) {
                var _a = state.adventurers[j];
                if (_a.status == "available" && !is_adventurer_committed(_a.id)) {
                    var _mark = party_has(_a.id) ? "[X] " : "[ ] ";
                    button_add(_mark + "Party " + string(j + 1) + ": " + _a.name, "toggle_party", _a.id);
                }
            }
            add_office_activity_buttons();
        break;

        case MODE.MISSION_RESULT:
            if (!is_struct(state.last_result) || !variable_struct_exists(state.last_result, "acknowledged") || !state.last_result.acknowledged) {
                button_add("Acknowledge", "ack", -1);
            }
            button_add("Return to Planning", "goto_planning", -1);
            add_office_activity_buttons();
        break;

        case MODE.GAME_HOUSE:
            button_add("Back to Planning", "goto_planning", -1);
            button_add("Wager -10", "gh_wager_add", -10);
            button_add("Wager +10", "gh_wager_add", 10);
            button_add("Game: Street Craps", "gh_set_game", "CRAPS");
            button_add("Game: Wyrm Wheel", "gh_set_game", "WHEEL");
            button_add("Game: Dragon 21", "gh_set_game", "DRAGON21");

            switch (state.game_house_game) {
                case "CRAPS":
                    if (state.game_house.craps_phase == "idle") button_add("Roll Come-Out", "gh_craps_roll", -1);
                    else button_add("Roll For Point " + string(state.game_house.craps_point), "gh_craps_roll", -1);
                break;

                case "WHEEL":
                    button_add("Bet RED", "gh_wheel_bet", "RED");
                    button_add("Bet BLACK", "gh_wheel_bet", "BLACK");
                    button_add("Bet ODD", "gh_wheel_bet", "ODD");
                    button_add("Bet EVEN", "gh_wheel_bet", "EVEN");
                    button_add("Bet LOW 1-12", "gh_wheel_bet", "LOW12");
                    button_add("Bet MID 13-24", "gh_wheel_bet", "MID12");
                    button_add("Bet HIGH 25-36", "gh_wheel_bet", "HIGH12");
                    button_add("Spin Wyrm Wheel", "gh_wheel_spin", -1);
                break;

                case "DRAGON21":
                    if (!state.game_house.cards_in_round) {
                        button_add("Deal Dragon 21", "gh_21_deal", -1);
                    } else {
                        button_add("Hit", "gh_21_hit", -1);
                        button_add("Stand", "gh_21_stand", -1);
                    }
                break;
            }
        break;

        default:
            button_add("Return to Planning", "goto_planning", -1);
            button_add("End Day", "end_day", -1);
            add_office_activity_buttons();
        break;
    }
};

run_button = function(_action, _value) {
    if (_action != "noop") dismiss_intro();
    if (state.game_over && _action != "noop") return;

    switch (_action) {
        case "goto_review":
            refresh_mission_board();
            state.mode = MODE.MISSION_REVIEW;
            state.status_line = "Reviewing unlocked contracts and party assignments.";
            print_missions();
            rebuild_buttons();
        break;

        case "goto_contracting":
            state.mode = MODE.CONTRACTING;
            state.status_line = "Reviewing patron correspondence.";
            print_patrons();
            rebuild_buttons();
        break;

        case "goto_market":
            if (array_length(state.free_agents) <= 0) refresh_free_agent_market();
            state.mode = MODE.BUYING;
            state.status_line = "Free-agent market open. Structure your offer.";
            rebuild_buttons();
        break;

        case "goto_game_house":
            enter_game_house();
            rebuild_buttons();
        break;

        case "goto_planning":
            state.mode = MODE.PLANNING;
            state.status_line = "Back at the desk. Planning board active.";
            add_log("Back at the desk. Planning board active.");
            rebuild_buttons();
        break;

        case "show_adventurers": print_adventurers(); break;
        case "select_patron":
            unlock_patron_contracts(_value);
            refresh_mission_board();
            state.mode = MODE.MISSION_REVIEW;
            print_missions();
            rebuild_buttons();
        break;
        case "start_mission": start_mission(); break;
        case "end_day": end_day(); break;
        case "select_mission": select_mission(_value); rebuild_buttons(); break;
        case "toggle_party": toggle_party(_value); rebuild_buttons(); break;
        case "clear_party": state.selected_party_ids = []; add_log("Party cleared."); rebuild_buttons(); break;
        case "market_refresh": refresh_free_agent_market(); rebuild_buttons(); break;
        case "market_select": select_free_agent_target(_value); rebuild_buttons(); break;
        case "market_bonus_add":
            state.offer_bonus = max(0, state.offer_bonus + _value);
            add_log("Offer bonus set to " + string(state.offer_bonus) + "g.");
            rebuild_buttons();
        break;
        case "market_rate_add":
            state.offer_rate_delta = clamp(state.offer_rate_delta + _value, -20, 30);
            add_log("Offer rate adjustment set to " + string(state.offer_rate_delta) + "g/day.");
            rebuild_buttons();
        break;
        case "market_comm_add":
            state.offer_commission = clamp(state.offer_commission + _value, 0.10, 0.35);
            add_log("Offer commission set to " + string(round(state.offer_commission * 100)) + "%.");
            rebuild_buttons();
        break;
        case "market_submit": submit_free_agent_offer(); rebuild_buttons(); break;
        case "market_accept_counter": accept_counter_offer(); rebuild_buttons(); break;
        case "market_decline_counter": decline_counter_offer(); rebuild_buttons(); break;
        case "gh_wager_add": change_game_house_wager(_value); rebuild_buttons(); break;
        case "gh_set_game": set_game_house_game(_value); rebuild_buttons(); break;
        case "gh_craps_roll": game_house_roll_craps(); rebuild_buttons(); break;
        case "gh_wheel_bet":
            state.game_house.wheel_bet = _value;
            add_log("Wyrm Wheel bet set to " + _value + ".");
            rebuild_buttons();
        break;
        case "gh_wheel_spin": game_house_spin_wheel(); rebuild_buttons(); break;
        case "gh_21_deal": game_house_deal_21(); rebuild_buttons(); break;
        case "gh_21_hit": game_house_hit_21(); rebuild_buttons(); break;
        case "gh_21_stand": game_house_stand_21(); rebuild_buttons(); break;
        case "act_research": office_activity_research(); rebuild_buttons(); break;
        case "act_recruit": office_activity_recruit(); rebuild_buttons(); break;
        case "act_scout": office_activity_scout_rival(); rebuild_buttons(); break;
        case "act_counteroffer": office_activity_counteroffer(); rebuild_buttons(); break;
        case "noop": break;

        case "ack":
            if (is_struct(state.last_result)) {
                if (!variable_struct_exists(state.last_result, "acknowledged") || !state.last_result.acknowledged) {
                    add_log("Result recorded: " + state.last_result.outcome_text + " for " + state.last_result.mission_title + ".");
                    state.last_result.acknowledged = true;

                    if (array_length(state.pending_reports) > 0) {
                        open_next_report();
                    }

                    rebuild_buttons();
                }
            }
        break;
    }
};

process_command = function(_raw) {
    var _t = string_trim(_raw);
    if (_t == "") return;

    if (state.game_over) {
        add_log("Guild operations are closed. Review logs.");
        return;
    }

    dismiss_intro();

    var _u = string_upper(_t);
    var _parts = string_split(_u, " ");
    var _cmd = _parts[0];

    switch (_cmd) {
        case "HELP":
            add_log("Commands: HELP, MARKET, TARGET <n>, BONUS <g>, RATE <g>, COMM <pct>, OFFER, ACCEPTCOUNTER, DECLINECOUNTER, PATRONS, PATRON <n>, MISSIONS, ADVENTURERS, START, NEXTDAY, MISSION <n>, PARTY <n>, CASINO, WAGER <g>, GAME <CRAPS|WHEEL|DRAGON21>, ROLL, SPIN, DEAL, HIT, STAND, RESEARCH, RECRUIT, SCOUT, COUNTER, MODE <name>");
        break;

        case "MISSIONS":
            refresh_mission_board();
            state.mode = MODE.MISSION_REVIEW;
            state.status_line = "Reviewing mission board.";
            print_missions();
        break;

        case "ADVENTURERS":
            print_adventurers();
        break;

        case "PATRONS":
            state.mode = MODE.CONTRACTING;
            state.status_line = "Reviewing patron correspondence.";
            print_patrons();
        break;

        case "MARKET":
            if (array_length(state.free_agents) <= 0) refresh_free_agent_market();
            state.mode = MODE.BUYING;
            state.status_line = "Free-agent market open. Structure your offer.";
        break;

        case "CASINO":
        case "GAMEHOUSE":
            enter_game_house();
        break;

        case "TARGET":
            if (array_length(_parts) > 1) select_free_agent_target(clamp(real(_parts[1]) - 1, 0, array_length(state.free_agents) - 1));
            else add_log("Usage: TARGET <1-" + string(array_length(state.free_agents)) + ">");
        break;

        case "BONUS":
            if (array_length(_parts) > 1) {
                state.offer_bonus = max(0, real(_parts[1]));
                add_log("Offer bonus set to " + string(state.offer_bonus) + "g.");
            } else add_log("Usage: BONUS <gold>");
        break;

        case "RATE":
            if (array_length(_parts) > 1) {
                state.offer_rate_delta = clamp(real(_parts[1]), -20, 30);
                add_log("Offer rate adjustment set to " + string(state.offer_rate_delta) + "g/day.");
            } else add_log("Usage: RATE <-20..30>");
        break;

        case "COMM":
            if (array_length(_parts) > 1) {
                state.offer_commission = clamp(real(_parts[1]) / 100, 0.10, 0.35);
                add_log("Offer commission set to " + string(round(state.offer_commission * 100)) + "%.");
            } else add_log("Usage: COMM <10..35>");
        break;

        case "OFFER":
            submit_free_agent_offer();
        break;

        case "ACCEPTCOUNTER":
            accept_counter_offer();
        break;

        case "DECLINECOUNTER":
            decline_counter_offer();
        break;

        case "PATRON":
            if (array_length(_parts) > 1) {
                var _pidx = clamp(real(_parts[1]) - 1, 0, array_length(state.patrons) - 1);
                unlock_patron_contracts(_pidx);
                refresh_mission_board();
                state.mode = MODE.MISSION_REVIEW;
                state.status_line = "Patron asks reviewed. Contracts updated.";
                print_missions();
            } else add_log("Usage: PATRON <1-" + string(array_length(state.patrons)) + ">");
        break;

        case "SIMULATE":
        case "START":
            start_mission();
        break;

        case "NEXTDAY":
        case "ENDDAY":
            end_day();
        break;

        case "MISSION":
            if (array_length(_parts) > 1) {
                select_mission(clamp(real(_parts[1]) - 1, 0, array_length(state.missions) - 1));
                state.mode = MODE.MISSION_REVIEW;
                state.status_line = "Mission focus updated.";
            } else add_log("Usage: MISSION <1-" + string(array_length(state.missions)) + ">");
        break;

        case "PARTY":
            if (array_length(_parts) > 1) toggle_party(clamp(real(_parts[1]) - 1, 0, array_length(state.adventurers) - 1));
            else add_log("Usage: PARTY <1-" + string(array_length(state.adventurers)) + ">");
        break;

        case "WAGER":
            if (array_length(_parts) > 1) {
                state.game_house_wager = clamp(real(_parts[1]), 10, 250);
                add_log("Table wager set to " + string(state.game_house_wager) + "g.");
            } else add_log("Usage: WAGER <10..250>");
        break;

        case "GAME":
            if (array_length(_parts) > 1) {
                var _g = _parts[1];
                if (_g == "CRAPS" || _g == "WHEEL" || _g == "DRAGON21") {
                    state.mode = MODE.GAME_HOUSE;
                    set_game_house_game(_g);
                } else {
                    add_log("Usage: GAME <CRAPS|WHEEL|DRAGON21>");
                }
            } else add_log("Usage: GAME <CRAPS|WHEEL|DRAGON21>");
        break;

        case "ROLL":
            if (state.game_house_game == "CRAPS") game_house_roll_craps();
            else add_log("ROLL is for Street Craps. Use GAME CRAPS first.");
        break;

        case "SPIN":
            if (state.game_house_game == "WHEEL") game_house_spin_wheel();
            else add_log("SPIN is for Wyrm Wheel. Use GAME WHEEL first.");
        break;

        case "DEAL":
            if (state.game_house_game == "DRAGON21") game_house_deal_21();
            else add_log("DEAL is for Dragon 21. Use GAME DRAGON21 first.");
        break;

        case "HIT":
            if (state.game_house_game == "DRAGON21") game_house_hit_21();
            else add_log("HIT is for Dragon 21. Use GAME DRAGON21 first.");
        break;

        case "STAND":
            if (state.game_house_game == "DRAGON21") game_house_stand_21();
            else add_log("STAND is for Dragon 21. Use GAME DRAGON21 first.");
        break;

        case "DICE":
            state.mode = MODE.GAME_HOUSE;
            set_game_house_game("CRAPS");
            game_house_roll_craps();
        break;
        case "RESEARCH": office_activity_research(); break;
        case "RECRUIT": office_activity_recruit(); break;
        case "SCOUT": office_activity_scout_rival(); break;
        case "COUNTER": office_activity_counteroffer(); break;

        case "MODE":
            if (array_length(_parts) > 1) {
                var _m = _parts[1];
                switch (_m) {
                    case "PLANNING": state.mode = MODE.PLANNING; break;
                    case "BUYING": state.mode = MODE.BUYING; break;
                    case "SELLING": state.mode = MODE.SELLING; break;
                    case "CONTRACTING": state.mode = MODE.CONTRACTING; break;
                    case "PITCHING": state.mode = MODE.PITCHING; break;
                    case "ARGUING": state.mode = MODE.ARGUING; break;
                    case "SABOTAGE": state.mode = MODE.SABOTAGE; break;
                    case "MISSION_REVIEW": refresh_mission_board(); state.mode = MODE.MISSION_REVIEW; break;
                    case "MISSION_RESULT": state.mode = MODE.MISSION_RESULT; break;
                    case "GAME_HOUSE": state.mode = MODE.GAME_HOUSE; break;
                    default: add_log("Unknown mode: " + _m); break;
                }
                state.status_line = "Mode: " + mode_to_string(state.mode);
            } else add_log("Usage: MODE <name>");
        break;

        default:
            add_log("Unknown command. Type HELP.");
        break;
    }

    rebuild_buttons();
};

layout = {
    pad: 12,
    header_h: 50,
    console_h: 240,
    left_w: 270,
    right_w: 300
};

keyboard_string = "";
input_buffer_prev_len = 0;
state.realtime_hour_interval_steps = max(60, room_speed * 8);
state.realtime_step_accum = 0;

state.adventurers = init_adventurers();
var _mission_templates = init_missions();
state.patrons = init_patrons();
state.contracts = init_contracts(state.patrons, _mission_templates);
for (var fa_seed = 0; fa_seed < 5; fa_seed++) {
    array_push(state.free_agents, build_market_candidate());
}
state.selected_free_agent_index = 0;
refresh_mission_board();
update_clock_from_absolute();

add_log("Guild office opened.");
add_log("You inherited your late uncle's struggling adventurer agency.");
add_log("Only five clients remain on the roster. Rebuild the office to its former glory.");
add_log("To begin: open Patron Requests, read a patron ask to unlock contracts, then build a party.");
add_log("Free-agent market now uses negotiated offers (bonus, daily rate, and commission).");
add_log("Game House available: Street Craps, Wyrm Wheel, and Dragon 21.");
add_log("Type HELP for commands or use quick actions.");
add_log("Mission durations and global world pulses run over time in every mode.");

rebuild_buttons();



































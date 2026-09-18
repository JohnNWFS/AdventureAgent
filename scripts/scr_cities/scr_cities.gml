/// Cities: where the agency, its adventurers, patrons and contracts are based.
/// Foundation for TODO section 18 (Cities and Career Expansion). The agency starts in the home
/// city (id 0) and everything defaults to it, so play is unchanged until another city becomes
/// known and someone is sent there. Build city features on these helpers; do not hand-build
/// city, contract or patron structs.
///
/// Shapes:
///   city      {id, name, theme, tier, prestige_required, travel_days, travel_cost,
///              lodging_per_day, patron_wealth, danger, known, description}
///   transfer  {adventurer_id, from_city_id, to_city_id, arrive_hour}   (state.city_transfers)
///   city_id   on every adventurer, patron and contract; -1 means on the road.
/// Prestige is state.reputation. Travel between two non-home cities goes through home.

function init_cities() {
    return [
        { id: 0, name: "Saltmere", theme: "harbor", tier: 1, prestige_required: 0, travel_days: 0, travel_cost: 0, lodging_per_day: 0, patron_wealth: 1.0, danger: 0, known: true, description: "Your home port of dock wards and guild halls, where your uncle built the agency." },
        { id: 1, name: "Eastmarch Hold", theme: "frontier", tier: 1, prestige_required: 45, travel_days: 2, travel_cost: 20, lodging_per_day: 4, patron_wealth: 0.8, danger: 15, known: false, description: "A frontier fort town. Poor patrons, dangerous work, and hazard pay for those who survive it." },
        { id: 2, name: "Vellanor", theme: "canal trade", tier: 2, prestige_required: 60, travel_days: 3, travel_cost: 35, lodging_per_day: 8, patron_wealth: 1.3, danger: 0, known: false, description: "A canal city of trade houses and guild factors. Rich contracts and sharp negotiators." },
        { id: 3, name: "Saint Caldur", theme: "temple", tier: 3, prestige_required: 75, travel_days: 4, travel_cost: 45, lodging_per_day: 10, patron_wealth: 1.5, danger: -5, known: false, description: "A temple city of abbeys and archives. Wealthy patrons who prize secrecy and reputation." }
    ];
}

/// Make sure city state exists and every adventurer, patron and contract has a city_id.
/// Safe to call any time; the hour tick and contract normalization call it.
function ensure_city_fields() {
    if (!variable_struct_exists(state, "cities") || array_length(state.cities) == 0) state.cities = init_cities();
    if (!variable_struct_exists(state, "home_city_id")) state.home_city_id = 0;
    if (!variable_struct_exists(state, "city_transfers")) state.city_transfers = [];
    var _home = state.home_city_id;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (!variable_struct_exists(state.adventurers[i], "city_id")) state.adventurers[i].city_id = _home;
    }
    for (var i = 0; i < array_length(state.patrons); i++) {
        if (!variable_struct_exists(state.patrons[i], "city_id")) state.patrons[i].city_id = _home;
    }
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (is_struct(state.contracts[i]) && !variable_struct_exists(state.contracts[i], "city_id")) state.contracts[i].city_id = _home;
    }
}

function home_city_id() {
    return variable_struct_exists(state, "home_city_id") ? state.home_city_id : 0;
}

function city_index(_city_id) {
    if (!variable_struct_exists(state, "cities")) return -1;
    for (var i = 0; i < array_length(state.cities); i++) {
        if (state.cities[i].id == _city_id) return i;
    }
    return -1;
}

function get_city(_city_id) {
    var _i = city_index(_city_id);
    return (_i >= 0) ? state.cities[_i] : undefined;
}

function city_name(_city_id) {
    if (_city_id == -1) return "on the road";
    var _c = get_city(_city_id);
    return is_undefined(_c) ? "an unknown city" : _c.name;
}

function city_is_known(_city_id) {
    var _c = get_city(_city_id);
    return !is_undefined(_c) && _c.known;
}

/// True when the agency's reputation meets the city's prestige requirement.
function city_prestige_ok(_city_id) {
    var _c = get_city(_city_id);
    return !is_undefined(_c) && state.reputation >= _c.prestige_required;
}

/// First word of a city reaches the agency. Logs once; returns true only the first time.
function mark_city_known(_city_id, _source_text) {
    var _c = get_city(_city_id);
    if (is_undefined(_c) || _c.known) return false;
    _c.known = true;
    add_log("Word of " + _c.name + " (" + _c.theme + "): " + _source_text);
    return true;
}

function adventurer_city_id(_a) {
    return variable_struct_exists(_a, "city_id") ? _a.city_id : home_city_id();
}

function patron_city_id(_p) {
    return variable_struct_exists(_p, "city_id") ? _p.city_id : home_city_id();
}

function contract_city_id(_c) {
    return variable_struct_exists(_c, "city_id") ? _c.city_id : home_city_id();
}

/// City of the contract behind a mission-board entry (home if it has none).
function mission_city_id(_mission) {
    if (variable_struct_exists(_mission, "contract_index") && _mission.contract_index >= 0 && _mission.contract_index < array_length(state.contracts)) {
        return contract_city_id(state.contracts[_mission.contract_index]);
    }
    return home_city_id();
}

/// Indices into state.adventurers of clients based in a city.
function adventurers_in_city(_city_id) {
    var _out = [];
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (adventurer_city_id(state.adventurers[i]) == _city_id) array_push(_out, i);
    }
    return _out;
}

/// Days on the road between two cities (routes between two away cities pass through home).
function city_travel_days(_from_city_id, _to_city_id) {
    if (_from_city_id == _to_city_id) return 0;
    var _a = get_city(_from_city_id);
    var _b = get_city(_to_city_id);
    var _days = (is_undefined(_a) ? 0 : _a.travel_days) + (is_undefined(_b) ? 0 : _b.travel_days);
    return max(1, _days);
}

/// Road cost in gold for one traveller between two cities.
function city_travel_cost(_from_city_id, _to_city_id) {
    if (_from_city_id == _to_city_id) return 0;
    var _a = get_city(_from_city_id);
    var _b = get_city(_to_city_id);
    return (is_undefined(_a) ? 0 : _a.travel_cost) + (is_undefined(_b) ? 0 : _b.travel_cost);
}

/// 0-100: how willing a client is to be based in another city. 50 or more agrees outright.
function relocation_willingness(_a, _city_id) {
    var _c = get_city(_city_id);
    if (is_undefined(_c)) return 0;
    var _score = 50;
    if (variable_struct_exists(_a, "trust")) _score += (_a.trust - 55) * 0.5;
    if (variable_struct_exists(_a, "morale")) _score += (_a.morale - 55) * 0.3;
    if (variable_struct_exists(_a, "renegotiation_annoyance")) _score -= _a.renegotiation_annoyance * 5;
    if (variable_struct_exists(_a, "ambition")) {
        switch (_a.ambition) {
            case "prestige jobs": case "glory": _score += (_c.tier - 1) * 10; break;
            case "higher pay": _score += (_c.patron_wealth - 1) * 40; break;
            case "steady work": _score -= 10; break;
        }
    }
    if (variable_struct_exists(_a, "risk_preference")) {
        if (_a.risk_preference == "careful") _score -= _c.danger * 0.8;
        if (_a.risk_preference == "bold") _score += _c.danger * 0.4;
    }
    if (_city_id == home_city_id()) _score += 30;   // coming home is an easy sell
    return clamp(round(_score), 0, 100);
}

/// Gold a reluctant client wants before agreeing to move (0 when willing).
function relocation_purse_needed(_a, _city_id) {
    var _w = relocation_willingness(_a, _city_id);
    if (_w >= 50) return 0;
    return 10 + (50 - _w) * 2;
}

/// Send a client to be based in another city. Pays road cost (and the relocation purse when
/// _pay_purse is true and one is needed). They travel with status "traveling" and arrive via
/// process_city_transfers. Returns true if they set out.
function start_city_transfer(_adv_index, _city_id, _pay_purse) {
    ensure_city_fields();
    if (_adv_index < 0 || _adv_index >= array_length(state.adventurers)) return false;
    var _a = state.adventurers[_adv_index];
    var _from = adventurer_city_id(_a);
    if (city_index(_city_id) < 0) {
        add_log("No such city. Type CITIES for the list.");
        return false;
    }
    if (!city_is_known(_city_id)) {
        add_log("The agency has no contacts in that city yet.");
        return false;
    }
    if (_from == _city_id) {
        add_log(_a.name + " is already based in " + city_name(_city_id) + ".");
        return false;
    }
    if (_a.status != "available" || is_adventurer_committed(_a.id)) {
        add_log(_a.name + " is not available to travel.");
        return false;
    }
    var _purse = relocation_purse_needed(_a, _city_id);
    if (_purse > 0 && !_pay_purse) {
        add_log(_a.name + " refuses to move to " + city_name(_city_id) + ". A " + string(_purse) + "g relocation purse might change their mind (TRANSFER <n> <city> PAY).");
        return false;
    }
    var _road = city_travel_cost(_from, _city_id);
    if (_road + _purse > state.gold) {
        add_log("Moving " + _a.name + " costs " + string(_road + _purse) + "g; the agency cannot cover it.");
        return false;
    }
    var _days = city_travel_days(_from, _city_id);
    if (_road > 0) spend_gold(_road, "Road costs for " + _a.name + " to " + city_name(_city_id) + ".");
    if (_purse > 0) {
        spend_gold(_purse, "Relocation purse paid to " + _a.name + ".");
        if (variable_struct_exists(_a, "purse_gold")) _a.purse_gold += _purse;
    }
    _a.status = "traveling";
    _a.city_id = -1;
    array_push(state.city_transfers, { adventurer_id: _a.id, from_city_id: _from, to_city_id: _city_id, arrive_hour: state.absolute_hour + _days * 24 });
    add_log(_a.name + " sets out for " + city_name(_city_id) + " (" + string(_days) + " day(s) on the road).");
    return true;
}

/// Hourly: travellers who reach their city become available there.
function process_city_transfers() {
    if (!variable_struct_exists(state, "city_transfers")) return;
    for (var i = array_length(state.city_transfers) - 1; i >= 0; i--) {
        var _t = state.city_transfers[i];
        if (state.absolute_hour < _t.arrive_hour) continue;
        var _idx = get_adv_index(_t.adventurer_id);
        if (_idx >= 0) {
            var _a = state.adventurers[_idx];
            _a.city_id = _t.to_city_id;
            if (_a.status == "traveling") _a.status = "available";
            add_log(_a.name + " arrived in " + city_name(_t.to_city_id) + " and is ready for local work.");
        }
        array_delete(state.city_transfers, i, 1);
    }
}

/// Travel for a party about to launch: {city_id, cost, hours}. Members based elsewhere pay road
/// cost plus lodging in the contract city for the mission's days; the party's travel time is
/// the longest member's road time. Home missions for home-based parties cost nothing extra.
function city_mission_trip(_mission, _party, _round_trip_hours) {
    var _city = mission_city_id(_mission);
    var _c = get_city(_city);
    var _lodging = is_undefined(_c) ? 0 : _c.lodging_per_day;
    var _cost = 0;
    var _hours = 0;
    for (var i = 0; i < array_length(_party); i++) {
        var _from = adventurer_city_id(_party[i]);
        if (_from == _city) continue;
        _cost += city_travel_cost(_from, _city) + _lodging * max(1, ceil(_round_trip_hours / 24));
        _hours = max(_hours, city_travel_days(_from, _city) * 24);
    }
    return { city_id: _city, cost: _cost, hours: _hours };
}

/// After a mission, the party is based in the city where the job was.
function city_stage_party(_active) {
    var _city = mission_city_id(_active.mission);
    for (var i = 0; i < array_length(_active.party_ids); i++) {
        var _idx = get_adv_index(_active.party_ids[i]);
        if (_idx < 0) continue;
        var _a = state.adventurers[_idx];
        if (adventurer_city_id(_a) != _city) {
            _a.city_id = _city;
            add_log(_a.name + " is now staged in " + city_name(_city) + ". TRANSFER them to bring them home.");
        }
    }
}

/// Tell the player when a party pick is based in another city than the job.
function city_note_party_member(_a) {
    if (state.selected_mission_index < 0 || state.selected_mission_index >= array_length(state.missions)) return;
    var _city = mission_city_id(state.missions[state.selected_mission_index]);
    var _from = adventurer_city_id(_a);
    if (_from == _city) return;
    add_log(_a.name + " is in " + city_name(_from) + ": " + string(city_travel_days(_from, _city)) + " day(s) and road plus lodging costs are added at launch.");
}

/// A new contract in a city, in the full contract shape. Reward is scaled by the city's
/// patron_wealth. Returns its index in state.contracts.
function add_city_contract(_city_id, _patron_id, _title, _description, _difficulty, _reward, _risk, _hours_valid) {
    ensure_city_fields();
    var _c = get_city(_city_id);
    var _wealth = is_undefined(_c) ? 1 : _c.patron_wealth;
    var _i = array_length(state.contracts);
    var _patron_name = "Open market";
    var _pidx = get_patron_index(_patron_id);
    if (_pidx >= 0) _patron_name = state.patrons[_pidx].name;
    array_push(state.contracts, {
        id: _i,
        title: _title,
        city_id: _city_id,
        patron_id: _patron_id,
        unlocked: true,
        accepted: false,
        expired: false,
        expires_hour: state.absolute_hour + _hours_valid,
        ask_text: _description,
        mission: {
            id: _i,
            title: _title,
            type: "Security",
            difficulty: clamp(_difficulty, 10, 85),
            reward: round(_reward * _wealth),
            duration_hours: 24,
            risk: clamp(_risk + (is_undefined(_c) ? 0 : _c.danger), 10, 85),
            preferred_role: "Warrior",
            weights: { combat: 0.40, magic: 0.20, stealth: 0.20, diplomacy: 0.20 },
            description: _description,
            patron_name: _patron_name,
            patron_max_party: 3
        }
    });
    refresh_mission_board();
    return _i;
}

/// A new patron based in a city, in the full patron shape. New-city patrons start less
/// satisfied: your name gets you in the door, not their trust. Returns the patron's index.
function add_city_patron(_city_id, _name, _personality, _pay_profile, _risk_profile, _temperament_note) {
    ensure_city_fields();
    var _id = 0;
    for (var i = 0; i < array_length(state.patrons); i++) _id = max(_id, state.patrons[i].id + 1);
    array_push(state.patrons, { id: _id, city_id: _city_id, name: _name, personality: _personality, contact: "city courier", pay_profile: _pay_profile, bonus_profile: "sometimes", risk_profile: _risk_profile, temperament_note: _temperament_note, research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 40 });
    return array_length(state.patrons) - 1;
}

/// CITIES command: known cities, their costs, and who is based where.
function print_cities() {
    ensure_city_fields();
    add_log("Cities (agency prestige " + string(state.reputation) + "):");
    var _unknown = 0;
    for (var i = 0; i < array_length(state.cities); i++) {
        var _c = state.cities[i];
        if (!_c.known) {
            _unknown += 1;
            continue;
        }
        var _line = string(_c.id) + ") " + _c.name + " [" + _c.theme + "]";
        if (_c.id == home_city_id()) _line += " - home office";
        else _line += " - " + string(_c.travel_days) + " day(s), " + string(_c.travel_cost) + "g road, " + string(_c.lodging_per_day) + "g/day lodging";
        _line += ", clients based here: " + string(array_length(adventurers_in_city(_c.id)));
        if (!city_prestige_ok(_c.id)) _line += ", patrons want prestige " + string(_c.prestige_required);
        add_log(_line);
    }
    if (array_length(state.city_transfers) > 0) add_log("On the road: " + string(array_length(state.city_transfers)) + " client(s).");
    if (_unknown > 0) add_log(string(_unknown) + " other cities are only names on travelers' lips so far.");
}

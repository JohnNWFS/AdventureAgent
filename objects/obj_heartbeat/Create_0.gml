/// Guild Agent prototype controller bootstrap
//random_set_seed(12345);
// Deterministic content for automated test runs; normal play stays random.
if (string_length(environment_get_variable("AA_STORM_SEED")) > 0) {
    random_set_seed(real(environment_get_variable("AA_STORM_SEED")));
} else {
    randomize();
}

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
    GAME_HOUSE: 9,
    ADVENTURERS: 10
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

    // Rival offer tracking
    rival_offer_last_hour: -1,
    rival_offer_cooldown: 0,

    adventurers: [],
    missions: [],
    patrons: [],
    contracts: [],
    selected_patron_index: -1,
    selected_contract_index: -1,
    contracting_stage: "patrons",

    selected_mission_index: -1,
    mission_review_stage: "missions",
    adventurer_view_stage: "list",
    selected_adventurer_index: -1,
    adventurer_view_return_mode: MODE.PLANNING,
    renegotiation_rate_offer: 0,
    renegotiation_commission_offer: 0,
    renegotiation_term_offer: 0,
    selected_party_ids: [],
    show_intro: true,
    splash: undefined,

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
    card_overlay: {
        open: false,
        focus_type: "",
        focus_id: -1,
        columns: [],
        action_buttons: [],
        card_hitboxes: [],
        close_button: { x1: 0, y1: 0, x2: 0, y2: 0 }
    },

    next_adv_id: 5,
    free_agents: [],
    selected_free_agent_index: -1,
    market_stage: "hub",
    offer_bonus: 0,
    offer_rate_delta: 0,
    offer_commission: 0.22,
    pending_signing: undefined,
    last_finance_day: 1,
    world_pulse_last_hour: -1,
    realtime_step_accum: 0,
    realtime_hour_interval_steps: 0,
    world_content: undefined,
    agency_inventory: [],

    game_house_game: "CRAPS",
    game_house_view: "lobby",
    game_house_table_fresh: true,
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
        case MODE.ADVENTURERS: return "ADVENTURERS";
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

init_splash_screen = function() {
    var _title = "Adventure Agent";
    var _subtitle = "A Fantasy Agent Simulator by John Hoffer";
    return {
        active: true,
        progress: 0,
        title: _title,
        subtitle: _subtitle,
        total_chars: string_length(_title) + string_length(_subtitle) + 16,
        quill_exit: 0,
        start_button: { x1: 0, y1: 0, x2: 0, y2: 0 }
    };
};

splash_is_finished = function() {
    return is_struct(state.splash) && state.splash.progress >= state.splash.total_chars;
};

splash_finish_drawing = function() {
    if (!is_struct(state.splash)) return;
    state.splash.progress = state.splash.total_chars;
    state.splash.quill_exit = 1;
};

splash_begin_game = function() {
    if (!is_struct(state.splash)) return;
    state.splash.active = false;
    state.show_intro = false;
    state.status_line = "Desk open. Planning board active.";
    add_log("Splash complete. Office doors open.");
};

splash_reveal_text = function(_text, _count) {
    if (_count <= 0) return "";
    return string_copy(_text, 1, min(string_length(_text), floor(_count)));
};

splash_measure_start_button = function() {
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _bw = 180;
    var _bh = 42;
    return {
        x1: floor((_gw - _bw) * 0.5),
        y1: floor(_gh * 0.76),
        x2: floor((_gw - _bw) * 0.5) + _bw,
        y2: floor(_gh * 0.76) + _bh
    };
};

classify_log_category = function(_msg) {
    var _u = string_upper(string(_msg));

    if (string_pos("WORLD PULSE:", _u) > 0 || string_pos("RIVAL", _u) > 0) return "rival";
    if (string_pos("FIELD REPORT", _u) > 0 || string_pos("MISSION", _u) > 0 || string_pos("OUTCOME:", _u) > 0) return "mission";
    if (string_pos("PATRON", _u) > 0 || string_pos("CONTRACT", _u) > 0 || string_pos("ASK:", _u) > 0) return "patron";
    if (string_pos("FREE-AGENT", _u) > 0 || string_pos("OFFER", _u) > 0 || string_pos("COUNTER", _u) > 0 ||
        string_pos("SIGNING", _u) > 0 || string_pos("NEGOTIATION", _u) > 0 || string_pos("CANDIDATE", _u) > 0) return "market";
    if (string_pos("GOLD", _u) > 0 || string_pos("PAYOUT", _u) > 0 || string_pos("BONUS", _u) > 0 ||
        string_pos("RATE ", _u) > 0 || string_pos("COMMISSION", _u) > 0 || string_pos("COST", _u) > 0) return "finance";
    if (string_pos("RESTLESS", _u) > 0 || string_pos("ADVENTURER", _u) > 0 || string_pos("ROSTER", _u) > 0 ||
        string_pos("RECOVERED", _u) > 0 || string_pos("RETIRED", _u) > 0) return "roster";
    if (string_pos("CRAPS", _u) > 0 || string_pos("WHEEL", _u) > 0 || string_pos("DRAGON 21", _u) > 0 ||
        string_pos("TABLE", _u) > 0 || string_pos("WAGER", _u) > 0) return "game";

    return "general";
};

make_log_entry = function(_text, _category) {
    return {
        text: _text,
        category: _category
    };
};

add_log = function(_msg) {
    var _prefix = "[Y" + string(state.year) + " D" + string(state.day) + " " + format_hh00(state.hour) + "] ";
    var _text = string(_msg);
    var _category = classify_log_category(_text);

    var _max_px = 900;
    if (variable_instance_exists(id, "layout")) {
        var _gw = display_get_gui_width();
        var _action_w = 220;
        var _console_x1 = layout.pad;
        var _console_x2 = _gw - layout.pad - _action_w;
        _max_px = max(140, (_console_x2 - _console_x1) - 28);
    }

    var _old_font = draw_get_font();
    var _font_idx = asset_get_index("fnt_ui_console");
    if (_font_idx != -1) draw_set_font(_font_idx);

    while (string_length(_text) > 0) {
        if (string_width(_prefix + _text) <= _max_px) {
            array_push(state.logs, make_log_entry(_prefix + _text, _category));
            break;
        }

        var _split = 0;
        var _last_space = 0;
        var _len = string_length(_text);
        for (var _scan = 1; _scan <= _len; _scan++) {
            var _c = string_char_at(_text, _scan);
            if (_c == " ") _last_space = _scan;
            if (string_width(_prefix + string_copy(_text, 1, _scan)) > _max_px) {
                _split = _scan - 1;
                break;
            }
        }

        if (_split <= 0) _split = max(1, min(_len, 16));
        if (_last_space > 0 && _last_space < _split) _split = _last_space;

        var _chunk = string_trim(string_copy(_text, 1, _split));
        array_push(state.logs, make_log_entry(_prefix + _chunk, _category));

        var _next = _split + 1;
        while (_next <= _len && string_char_at(_text, _next) == " ") _next += 1;
        _text = string_copy(_text, _next, _len - _next + 1);
    }

    draw_set_font(_old_font);
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

default_world_content = function() {
    return {
        adventurer_first: ["Kael", "Iris", "Brom", "Nessa", "Varric", "Liora", "Fen", "Orin", "Mara", "Galen"],
        adventurer_last: ["Dawnmere", "Blackfen", "Ashvale", "Runehart", "Thornfield", "Ironwill", "Mistbrook", "Crowley"],
        patron_titles_noble: ["Lady", "Lord", "Dame"],
        patron_titles_civic: ["Magistrate", "Warden", "Harbor Master"],
        patron_titles_religious: ["Prior", "Abbess", "Canon"],
        locations_ruin: ["Blackbriar Vault", "Saint Caldur Archive", "Moonfen Barrow"],
        locations_road: ["Eastmarch Trade Road", "Old Kingway", "Harrow Pass"],
        locations_forest: ["Ashenwood", "Myr Fen", "Briar Hollow"],
        gear_weapons: ["iron longsword", "ash bow", "tempered spear", "rune knife"],
        gear_outfits: ["court cloak", "mail coat", "travel robes", "field leathers"],
        magic_names: ["spark ward", "ember sigil", "echo charm", "minor blessing"]
    };
};

read_text_file = function(_path) {
    if (!file_exists(_path)) return "";
    var _fh = file_text_open_read(_path);
    var _txt = "";
    while (!file_text_eof(_fh)) {
        _txt += file_text_read_string(_fh);
        if (!file_text_eof(_fh)) file_text_readln(_fh);
        if (!file_text_eof(_fh)) _txt += "\n";
    }
    file_text_close(_fh);
    return _txt;
};

string_pos_from = function(_needle, _haystack, _start_index) {
    var _needle_len = string_length(_needle);
    var _hay_len = string_length(_haystack);
    if (_needle_len <= 0) return 0;

    for (var i = max(1, _start_index); i <= (_hay_len - _needle_len + 1); i++) {
        if (string_copy(_haystack, i, _needle_len) == _needle) return i;
    }
    return 0;
};

xml_extract_tag_values = function(_text, _tag) {
    var _values = [];
    var _open = "<" + _tag + ">";
    var _close = "</" + _tag + ">";
    var _cursor = 1;

    while (true) {
        var _start = string_pos_from(_open, _text, _cursor);
        if (_start <= 0) break;
        var _value_start = _start + string_length(_open);
        var _end = string_pos_from(_close, _text, _value_start);
        if (_end <= 0) break;

        var _value = string_trim(string_copy(_text, _value_start, _end - _value_start));
        if (_value != "") array_push(_values, _value);
        _cursor = _end + string_length(_close);
    }

    return _values;
};

apply_world_content_xml = function(_text) {
    if (_text == "") return;

    var _map = [
    ["mission_flavor_text", "mission_flavor_text"],
    ["patron_title_grim_mercenary", "patron_titles_grim_mercenary"],
    ["rival_agency", "rival_agencies"],
        ["adventurer_first", "adventurer_first"],
        ["adventurer_last", "adventurer_last"],
        ["patron_title_noble", "patron_titles_noble"],
        ["patron_title_civic", "patron_titles_civic"],
        ["patron_title_religious", "patron_titles_religious"],
        ["location_ruin", "locations_ruin"],
        ["location_road", "locations_road"],
        ["location_forest", "locations_forest"],
        ["gear_weapon", "gear_weapons"],
        ["gear_outfit", "gear_outfits"],
        ["magic_name", "magic_names"],
        ["location_name", "location_names"]
    ];

    for (var i = 0; i < array_length(_map); i++) {
        var _tag = _map[i][0];
        var _field = _map[i][1];
        var _values = xml_extract_tag_values(_text, _tag);
        if (array_length(_values) > 0) {
            variable_struct_set(state.world_content, _field, _values);
        }
    }
};

load_world_content_xml = function() {
    state.world_content = default_world_content();

    var _paths = [
        working_directory + "datafiles/world_content.xml",
        "datafiles/world_content.xml"
    ];

    for (var i = 0; i < array_length(_paths); i++) {
        var _txt = read_text_file(_paths[i]);
        if (_txt != "") {
            apply_world_content_xml(_txt);
            // Load city content pack if available
            var _city_path = working_directory + "datafiles/city_content.xml";
            var _city_txt = read_text_file(_city_path);
            if (_city_txt != "") {
                apply_world_content_xml(_city_txt);
                add_log("City content pack loaded from XML");
            }
            // Load location content pack if available
            var _location_path = working_directory + "datafiles/location_content.xml";
            var _location_txt = read_text_file(_location_path);
            if (_location_txt != "") {
                apply_world_content_xml(_location_txt);
                add_log("Location content pack loaded from XML");
            }
            // Load outfit content pack if available
            var _outfit_path = working_directory + "datafiles/outfit_content.xml";
            var _outfit_txt = read_text_file(_outfit_path);
            if (_outfit_txt != "") {
                apply_world_content_xml(_outfit_txt);
                add_log("Outfit content pack loaded from XML");
            }
            add_log("World content pack loaded from XML.");
            // Load patron content pack if available
            var _patron_path = working_directory + "datafiles/patron_content.xml";
            var _patron_txt = read_text_file(_patron_path);
            if (_patron_txt != "") {
                apply_world_content_xml(_patron_txt);
                add_log("Patron content pack loaded from XML");
            }
            // Load relic content pack if available
            var _relic_path = working_directory + "datafiles/relic_content.xml";
            var _relic_txt = read_text_file(_relic_path);
            if (_relic_txt != "") {
                apply_world_content_xml(_relic_txt);
                add_log("Relic content pack loaded from XML");
            }
            // Load spell name content pack if available
            var _spell_path = working_directory + "datafiles/spell_content.xml";
            var _spell_txt = read_text_file(_spell_path);
            if (_spell_txt != "") {
                apply_world_content_xml(_spell_txt);
                // Load mission flavor content pack if available
                var _mission_flavor_path = working_directory + "datafiles/mission_flavor_content.xml";
                var _mission_flavor_txt = read_text_file(_mission_flavor_path);
                if (_mission_flavor_txt != "") {
                    apply_world_content_xml(_mission_flavor_txt);
                    add_log("Mission flavor content pack loaded from XML");
                }
                add_log("Spell name content pack loaded from XML");
            }
            // Load rival agencies from XML if available
            var _rival_agency_path = working_directory + "datafiles/rival_agencies.xml";
            var _rival_agency_txt = read_text_file(_rival_agency_path);
            if (_rival_agency_txt != "") {
                apply_world_content_xml(_rival_agency_txt);
                add_log("Rival agencies XML content pack loaded");
            }
            // Load example content pack if available
            var _example_path = working_directory + "datafiles/example_content.xml";
            var _example_txt = read_text_file(_example_path);
            if (_example_txt != "") {
                apply_world_content_xml(_example_txt);
                // Load rival agency names from XML
                var _rival_agency_path = working_directory + "datafiles/rival_agencies.xml";
                var _rival_agency_txt = read_text_file(_rival_agency_path);
                if (_rival_agency_txt != "") {
                    apply_world_content_xml(_rival_agency_txt);
                    add_log("Rival agencies XML content pack loaded");
                }
                add_log("Example XML content pack loaded");
                // Load generic medieval fantasy content pack if available
                var _fantasy_path = working_directory + "datafiles/fantasy_content.xml";
                var _fantasy_txt = read_text_file(_fantasy_path);
                if (_fantasy_txt != "") {
                    apply_world_content_xml(_fantasy_txt);
                    add_log("Generic medieval fantasy content pack loaded");
                }
                // Load weapon content pack if available
                var _weapon_path = working_directory + "datafiles/weapon_content.xml";
                var _weapon_txt = read_text_file(_weapon_path);
                if (_weapon_txt != "") {
                    apply_world_content_xml(_weapon_txt);
                    add_log("Weapon content pack loaded from XML");
                } else {
                    add_log("Gear weapon tag not found in XML");
                }
                // Load Tolkien-inspired content pack if available
                var _tolkien_path = working_directory + "datafiles/tolkien_content.xml";
                var _tolkien_txt = read_text_file(_tolkien_path);
                if (_tolkien_txt != "") {
                    apply_world_content_xml(_tolkien_txt);
                    add_log("Tolkien-inspired content pack loaded");
                }
            }
            return;
        }
    }

    add_log("Using built-in world content defaults.");
};

random_free_agent_name = function() {
    var _first_pool = state.world_content.adventurer_first;
    var _last_pool = state.world_content.adventurer_last;
    var _first = _first_pool[irandom(array_length(_first_pool) - 1)];
    var _last = _last_pool[irandom(array_length(_last_pool) - 1)];
    return _first + " " + _last;
};

default_adventurer_kit = function(_role) {
    switch (_role) {
        case "Warrior": return ["mail shirt", "shield", "camp blade"];
        case "Mage": return ["spell satchel", "focus rod", "field notes"];
        case "Rogue": return ["lock picks", "soft boots", "throwing knives"];
        case "Bard": return ["travel lute", "court attire", "letter case"];
        case "Cleric": return ["travel icon", "healer kit", "blessed wraps"];
        case "Ranger": return ["longbow", "trail cloak", "snare kit"];
    }
    return ["bedroll", "travel pack"];
};

default_adventurer_arcana = function(_role) {
    switch (_role) {
        case "Mage": return ["spark ward"];
        case "Cleric": return ["minor blessing"];
        case "Bard": return ["echo charm"];
    }
    return [];
};

default_adventurer_relics = function(_role) {
    switch (_role) {
        case "Cleric": return ["pilgrim icon", "saint's seal"];
        case "Warrior": return ["captain's favor", "saint's seal"];
        case "Ranger": return ["trail token", "ruin key fragment"];
    }
    return ["abbey lantern"];
};

default_agency_inventory = function() {
    return [
        { name: "Healing Kit", kind: "consumable", stock: 3, score_bonus: 0, injury_guard: 10, roles: ["Cleric", "Warrior", "Ranger"] },
        { name: "Ward Scroll", kind: "consumable", stock: 2, score_bonus: 8, injury_guard: 8, roles: ["Mage", "Cleric", "Bard"] },
        { name: "Lockpick Roll", kind: "consumable", stock: 2, score_bonus: 10, injury_guard: 0, roles: ["Rogue", "Bard"] },
        { name: "Fine Rations", kind: "consumable", stock: 4, score_bonus: 4, injury_guard: 0, roles: ["Warrior", "Ranger", "Cleric"] },
        { name: "Hedge Charm", kind: "consumable", stock: 3, score_bonus: 5, injury_guard: 0, roles: ["Warrior", "Mage", "Rogue", "Bard", "Cleric", "Ranger"] },
        { name: "Rune Shield", kind: "durable", stock: 2, score_bonus: 6, injury_guard: 14, roles: ["Warrior", "Cleric"] },
        { name: "Travel Cloak", kind: "durable", stock: 2, score_bonus: 5, injury_guard: 4, roles: ["Rogue", "Bard", "Ranger"] },
        { name: "Noble Travel Attire", kind: "durable", stock: 1, score_bonus: 7, injury_guard: 6, roles: ["Warrior", "Mage", "Rogue", "Bard", "Cleric", "Ranger"] },
        { name: "Dwarven Warhammer", kind: "durable", stock: 3, score_bonus: 12, injury_guard: 18, roles: ["Warrior"] },
        { name: "Dwarven Battleaxe", kind: "durable", stock: 3, score_bonus: 10, injury_guard: 16, roles: ["Warrior"] },
        { name: "Dwarven Shield", kind: "durable", stock: 3, score_bonus: 8, injury_guard: 22, roles: ["Warrior", "Cleric"] },
        { name: "Saint's Seal", kind: "relic", stock: 2, score_bonus: 0, injury_guard: 0, roles: ["Cleric", "Warrior", "Ranger"] },
        { name: "Abbey Lantern", kind: "relic", stock: 2, score_bonus: 0, injury_guard: 0, roles: ["Cleric", "Mage", "Bard"] },
        { name: "Ruin Key Fragment", kind: "relic", stock: 2, score_bonus: 0, injury_guard: 0, roles: ["Rogue", "Ranger"] }
    ];
};

build_adventurer_profile = function(_name, _role, _combat, _magic, _stealth, _diplomacy, _reliability, _age, _rate, _commission, _starting_gold, _id) {
    if (is_undefined(_starting_gold)) _starting_gold = irandom_range(18, 70);
    if (is_undefined(_id)) _id = -1;
    var _term = choose(20, 30, 45);
    return {
        id: _id,
        name: _name,
        role: _role,
        combat: _combat,
        magic: _magic,
        stealth: _stealth,
        diplomacy: _diplomacy,
        reliability: _reliability,
        age: _age,
        adventure_rate: _rate,
        commission_rate: _commission,
        status: "available",
        idle_days: 0,
        last_contract_day: 0,
        last_idle_notice_day: 0,
        purse_gold: _starting_gold,
        lifetime_earnings: 0,
        last_mission_payout: 0,
        morale: irandom_range(64, 82),
        trust: irandom_range(58, 76),
        representation_type: choose("exclusive charter", "guild retainer", "sworn representation"),
        contract_term_days: _term,
        contract_days_remaining: _term,
        activity_expectation_days: choose(2, 3, 4),
        risk_preference: choose("careful", "balanced", "bold"),
        ambition: choose("steady work", "prestige jobs", "higher pay", "glory"),
        renegotiation_annoyance: 0,
        last_renegotiation_day: 0,
        defection_risk: 0,
        training_focus: "none",
        growth_path: "none",
        academy_affiliation: "none",
        departure_warning: false,
        promised_work_by_day: 0,
        last_charter_notice_day: -1,
        issued_gear: [],
        kit: default_adventurer_kit(_role),
        found_magic: default_adventurer_arcana(_role),
        found_relics: default_adventurer_relics(_role),
        notable_finds: []
    };
};

array_join_text = function(_arr) {
    if (array_length(_arr) <= 0) return "- none -";
    var _txt = "";
    for (var i = 0; i < array_length(_arr); i++) {
        _txt += string(_arr[i]);
        if (i < array_length(_arr) - 1) _txt += ", ";
    }
    return _txt;
};

find_agency_inventory_index = function(_item_name) {
    for (var i = 0; i < array_length(state.agency_inventory); i++) {
        if (state.agency_inventory[i].name == _item_name) return i;
    }
    return -1;
};

find_contract_index_by_id = function(_contract_id) {
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (state.contracts[i].id == _contract_id) return i;
    }
    return -1;
};

get_focus_card_type = function() {
    if (!is_struct(state.card_overlay)) return "";
    return state.card_overlay.focus_type;
};

get_focus_card_id = function() {
    if (!is_struct(state.card_overlay)) return -1;
    return state.card_overlay.focus_id;
};

set_card_overlay_focus = function(_type, _id) {
    state.card_overlay.focus_type = _type;
    state.card_overlay.focus_id = _id;
};

card_stat = function(_label, _value) {
    return { label: _label, value: string(_value) };
};

card_action = function(_label, _action, _value) {
    return { label: _label, action: _action, value: _value };
};

card_palette = function(_type) {
    switch (_type) {
        case "patron":
            return {
                top: make_color_rgb(76, 46, 72),
                bottom: make_color_rgb(36, 22, 44),
                border: make_color_rgb(232, 175, 221),
                accent: make_color_rgb(248, 214, 241),
                plate: make_color_rgb(143, 105, 152)
            };
        case "contract":
            return {
                top: make_color_rgb(54, 80, 126),
                bottom: make_color_rgb(25, 42, 78),
                border: make_color_rgb(149, 195, 255),
                accent: make_color_rgb(221, 237, 255),
                plate: make_color_rgb(87, 127, 186)
            };
        case "location":
            return {
                top: make_color_rgb(58, 96, 74),
                bottom: make_color_rgb(28, 54, 42),
                border: make_color_rgb(176, 230, 191),
                accent: make_color_rgb(231, 251, 237),
                plate: make_color_rgb(100, 145, 113)
            };
        case "prospect":
            return {
                top: make_color_rgb(104, 78, 34),
                bottom: make_color_rgb(59, 44, 18),
                border: make_color_rgb(241, 209, 128),
                accent: make_color_rgb(255, 240, 200),
                plate: make_color_rgb(169, 128, 56)
            };
        default:
            return {
                top: make_color_rgb(82, 58, 112),
                bottom: make_color_rgb(40, 28, 62),
                border: make_color_rgb(206, 178, 255),
                accent: make_color_rgb(243, 236, 255),
                plate: make_color_rgb(120, 94, 170)
            };
    }
};

card_holo_text = function(_type, _id) {
    var _prefix = "FILE";
    switch (_type) {
        case "patron": _prefix = "PATRON"; break;
        case "contract": _prefix = "CONTRACT"; break;
        case "location": _prefix = "SITE"; break;
        case "prospect": _prefix = "PROSPECT"; break;
        default: _prefix = "ADVENTURER"; break;
    }
    return _prefix + " " + string(max(0, _id + 1));
};

mission_location_title = function(_mission) {
    if (variable_struct_exists(_mission, "title")) return _mission.title;
    return "Unmarked Site";
};

build_patron_card = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return undefined;
    var _p = state.patrons[_patron_index];
    var _open_requests = count_patron_open_requests(_patron_index);
    var _worked = _p.jobs_completed + _p.jobs_partial + _p.jobs_failed;

    var _subtitle = string_upper(_p.personality) + " patron";
    if (patron_is_temple(_patron_index)) {
        _subtitle = "Temple of the Sacred Flame (Oath-based)";
    }

    return {
        type: "patron",
        id: _patron_index,
        title: _p.name,
        subtitle: _subtitle,
        status: patron_satisfaction_label(_p.satisfaction) + " relationship",
        summary: _p.temperament_note,
        stats: [
            card_stat("Satisfaction", string(_p.satisfaction) + "/100"),
            card_stat("Open asks", _open_requests),
            card_stat("Jobs", _worked),
            card_stat("Pay profile", _p.pay_profile)
        ],
        details: [
            "Contact: " + _p.contact,
            "Bonuses: " + _p.bonus_profile,
            "Risk appetite: " + _p.risk_profile
        ],
        actions: [
            card_action("View Requests", "select_patron", _patron_index),
            card_action("Research File", "card_patron_research", _patron_index)
        ]
    };
};

build_contract_card = function(_contract_index) {
    if (_contract_index < 0 || _contract_index >= array_length(state.contracts)) return undefined;
    var _c = state.contracts[_contract_index];
    var _m = _c.mission;
    var _state = "Locked";
    if (_c.accepted) _state = "Accepted";
    else if (_c.expired || state.absolute_hour >= _c.expires_hour) _state = "Expired";
    else if (_c.unlocked) _state = "Open";

    var _actions = [card_action("Review Contract", "card_open_contract", _contract_index)];
    if (_c.unlocked && !_c.accepted && !_c.expired && state.absolute_hour < _c.expires_hour) {
        array_push(_actions, card_action("Assign Party", "card_accept_contract", _contract_index));
    }

    return {
        type: "contract",
        id: _contract_index,
        title: _m.title,
        subtitle: _m.type + " contract",
        status: _state,
        summary: _m.description,
        stats: [
            card_stat("Reward", string(_m.reward) + "g"),
            card_stat("Risk", string(_m.risk) + "%"),
            card_stat("Diff", _m.difficulty),
            card_stat("Party", "up to " + string(_m.patron_max_party))
        ],
        details: [
            "Patron: " + _m.patron_name,
            "ETA: " + format_duration_hours(_m.duration_hours),
            "Expires in: " + format_duration_hours(max(0, _c.expires_hour - state.absolute_hour))
        ],
        actions: _actions
    };
};

build_location_card = function(_contract_index) {
    if (_contract_index < 0 || _contract_index >= array_length(state.contracts)) return undefined;
    var _c = state.contracts[_contract_index];
    var _m = _c.mission;
    return {
        type: "location",
        id: _contract_index,
        title: mission_location_title(_m),
        subtitle: "Adventure target",
        status: _m.type + " posting",
        summary: _m.description,
        stats: [
            card_stat("Risk", string(_m.risk) + "%"),
            card_stat("Travel", format_duration_hours(_m.duration_hours)),
            card_stat("Best role", _m.preferred_role),
            card_stat("Reward", string(_m.reward) + "g")
        ],
        details: [
            "Contract: " + _m.title,
            "Patron: " + _m.patron_name,
            "Difficulty: " + string(_m.difficulty)
        ],
        actions: [
            card_action("Open Contract", "card_open_contract", _contract_index)
        ]
    };
};

build_adventurer_card = function(_adv_index, _type_name) {
    if (_adv_index < 0) return undefined;
    var _arr = (_type_name == "prospect") ? state.free_agents : state.adventurers;
    if (_adv_index >= array_length(_arr)) return undefined;
    var _a = _arr[_adv_index];
    var _actions = [];
    if (_type_name == "prospect") {
        _actions = [
            card_action("Scout Prospect", "market_select", _adv_index),
            card_action("Prepare Offer", "card_open_market_offer", _adv_index)
        ];
    } else {
        _actions = [card_action("Open File", "adventurer_select", _adv_index)];
        if (_a.status == "available") {
            array_push(_actions, card_action("Meet Client", "card_open_retention", _adv_index));
        }
    }

    return {
        type: _type_name,
        id: _adv_index,
        title: _a.name,
        subtitle: _a.role + ((_type_name == "prospect") ? " prospect" : " client"),
        status: string_upper(_a.status),
        location: get_adventurer_location_text(_a),
        summary: (_type_name == "prospect")
            ? ("Negotiation style " + string_upper(_a.negotiation_style) + ". " + _a.style_blurb)
            : ("Morale " + string(_a.morale) + ", trust " + string(_a.trust) + ", ambition " + _a.ambition + "."),
        stats: [
            card_stat("C", _a.combat),
            card_stat("M", _a.magic),
            card_stat("S", _a.stealth),
            card_stat("D", _a.diplomacy),
            card_stat("Rate", string(_a.adventure_rate) + "g"),
            card_stat("Rel", _a.reliability)
        ],
        details: (_type_name == "prospect")
            ? [
                "Ask bonus: " + string(_a.ask_bonus) + "g",
                "Ask rate: " + string(_a.ask_rate) + "g/day",
                "Min commission: " + string(round(_a.min_commission * 100)) + "%"
            ]
            : [
                "Commission: " + string(round(_a.commission_rate * 100)) + "%",
                "Charter: " + string(_a.contract_days_remaining) + "/" + string(_a.contract_term_days) + " day(s)",
                "Defection risk: " + string(_a.defection_risk)
            ],
        actions: _actions
    };
};

get_card_column_items = function(_column_key) {
    var _items = [];
    switch (_column_key) {
        case "patrons":
            for (var p = 0; p < array_length(state.patrons); p++) {
                array_push(_items, build_patron_card(p));
            }
        break;
        case "contracts":
            for (var c = 0; c < array_length(state.contracts); c++) {
                var _contract = state.contracts[c];
                if (_contract.unlocked && !_contract.accepted && !_contract.expired && state.absolute_hour < _contract.expires_hour) {
                    array_push(_items, build_contract_card(c));
                }
            }
        break;
        case "adventurers":
            for (var a = 0; a < array_length(state.adventurers); a++) {
                if (state.adventurers[a].status != "retired") {
                    array_push(_items, build_adventurer_card(a, "adventurer"));
                }
            }
        break;
        case "prospects":
            for (var f = 0; f < array_length(state.free_agents); f++) {
                array_push(_items, build_adventurer_card(f, "prospect"));
            }
        break;
        case "locations":
            for (var l = 0; l < array_length(state.contracts); l++) {
                var _site_contract = state.contracts[l];
                if (_site_contract.unlocked && !_site_contract.accepted && !_site_contract.expired && state.absolute_hour < _site_contract.expires_hour) {
                    array_push(_items, build_location_card(l));
                }
            }
        break;
    }
    return _items;
};

refresh_card_overlay = function() {
    if (!is_struct(state.card_overlay)) return;

    var _prev_keys = [];
    var _prev_values = [];
    for (var i = 0; i < array_length(state.card_overlay.columns); i++) {
        var _prev = state.card_overlay.columns[i];
        array_push(_prev_keys, _prev.key);
        array_push(_prev_values, _prev.scroll);
    }

    var _column_defs = [
        { key: "patrons", title: "Patrons" },
        { key: "contracts", title: "Contracts" },
        { key: "adventurers", title: "Adventurers" },
        { key: "locations", title: "Locations" }
    ];
    if (array_length(state.free_agents) > 0) {
        array_push(_column_defs, { key: "prospects", title: "Prospects" });
    }

    state.card_overlay.columns = [];
    state.card_overlay.action_buttons = [];
    state.card_overlay.card_hitboxes = [];

    for (var d = 0; d < array_length(_column_defs); d++) {
        var _def = _column_defs[d];
        var _items = get_card_column_items(_def.key);
        var _saved_scroll = 0;
        for (var s = 0; s < array_length(_prev_keys); s++) {
            if (_prev_keys[s] == _def.key) {
                _saved_scroll = _prev_values[s];
                break;
            }
        }
        array_push(state.card_overlay.columns, {
            key: _def.key,
            title: _def.title,
            scroll: _saved_scroll,
            items: _items,
            x1: 0, y1: 0, x2: 0, y2: 0,
            content_h: 0
        });
    }
};

open_card_overlay = function(_focus_type, _focus_id) {
    dismiss_intro();
    state.card_overlay.open = true;
    set_card_overlay_focus(_focus_type, _focus_id);
    refresh_card_overlay();
    state.status_line = "Card gallery open. Scroll each column to browse the desk dossiers.";
};

close_card_overlay = function() {
    state.card_overlay.open = false;
    state.card_overlay.action_buttons = [];
    state.card_overlay.card_hitboxes = [];
    state.status_line = "Returned to desk view.";
};

card_overlay_focus_selected_context = function() {
    if (state.mode == MODE.ADVENTURERS && state.selected_adventurer_index >= 0) {
        open_card_overlay("adventurer", state.selected_adventurer_index);
        return;
    }
    if (state.mode == MODE.BUYING && state.selected_free_agent_index >= 0) {
        open_card_overlay("prospect", state.selected_free_agent_index);
        return;
    }
    if (state.selected_contract_index >= 0) {
        open_card_overlay("contract", state.selected_contract_index);
        return;
    }
    if (state.selected_patron_index >= 0) {
        open_card_overlay("patron", state.selected_patron_index);
        return;
    }
    if (state.selected_mission_index >= 0 && state.selected_mission_index < array_length(state.missions)) {
        open_card_overlay("location", state.missions[state.selected_mission_index].contract_index);
        return;
    }
    open_card_overlay("", -1);
};

run_card_action = function(_action, _value) {
    switch (_action) {
        case "card_patron_research":
            log_patron_research_report(_value);
            refresh_card_overlay();
            rebuild_buttons();
        break;
        case "card_open_contract":
            if (_value >= 0 && _value < array_length(state.contracts)) {
                var _patron_idx = get_patron_index(state.contracts[_value].patron_id);
                if (_patron_idx >= 0) open_patron_contracts(_patron_idx);
                select_contract_for_review(_value);
                rebuild_buttons(true);
                open_card_overlay("contract", _value);
            }
        break;
        case "card_accept_contract":
            if (_value >= 0 && _value < array_length(state.contracts)) {
                var _pid = get_patron_index(state.contracts[_value].patron_id);
                if (_pid >= 0) open_patron_contracts(_pid);
                select_contract_for_review(_value);
                advance_to_party_assignment();
                rebuild_buttons(true);
                open_card_overlay("contract", _value);
            }
        break;
        case "card_open_market_offer":
            select_free_agent_target(_value);
            open_market_offer_stage();
            rebuild_buttons(true);
            open_card_overlay("prospect", _value);
        break;
        case "card_open_retention":
            open_adventurer_detail(_value);
            open_adventurer_retention_meeting();
            rebuild_buttons(true);
            open_card_overlay("adventurer", _value);
        break;
        default:
            run_button(_action, _value);
            refresh_card_overlay();
        break;
    }
};

get_agency_inventory_item = function(_item_name) {
    var _idx = find_agency_inventory_index(_item_name);
    if (_idx < 0) return undefined;
    return state.agency_inventory[_idx];
};

adventurer_has_issued_item = function(_a, _item_name) {
    for (var i = 0; i < array_length(_a.issued_gear); i++) {
        if (_a.issued_gear[i] == _item_name) return true;
    }
    return false;
};

adventurer_issued_gear_text = function(_a) {
    return array_join_text(_a.issued_gear);
};

open_adventurer_loadout = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status == "on_mission") {
        add_log(_a.name + " is currently in the field. Adjust issued gear after the mission.");
        return;
    }

    state.mode = MODE.ADVENTURERS;
    state.adventurer_view_stage = "loadout";
    state.status_line = "Managing issued gear for " + _a.name + ".";
    add_log("Loadout desk opened for " + _a.name + ".");
    add_log("Personal kit: " + array_join_text(_a.kit));
    add_log("Agency-issued kit: " + adventurer_issued_gear_text(_a) + ".");
};

issue_agency_gear_to_adventurer = function(_item_name) {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status == "on_mission") {
        add_log(_a.name + " is currently in the field. Gear changes will have to wait.");
        return;
    }
    var _item_idx = find_agency_inventory_index(_item_name);
    if (_item_idx < 0) return;

    var _item = state.agency_inventory[_item_idx];
    if (_item.stock <= 0) {
        add_log("No " + _item_name + " remain in agency stores.");
        return;
    }
    if (adventurer_has_issued_item(_a, _item_name)) {
        add_log(_a.name + " already has " + _item_name + " issued.");
        return;
    }

    array_push(_a.issued_gear, _item_name);
    state.agency_inventory[_item_idx].stock -= 1;
    add_log(_item_name + " issued to " + _a.name + ".");
};

reclaim_agency_gear_from_adventurer = function(_item_name) {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status == "on_mission") {
        add_log(_a.name + " is currently in the field. Gear changes will have to wait.");
        return;
    }
    for (var i = 0; i < array_length(_a.issued_gear); i++) {
        if (_a.issued_gear[i] == _item_name) {
            array_delete(_a.issued_gear, i, 1);
            var _item_idx = find_agency_inventory_index(_item_name);
            if (_item_idx >= 0) state.agency_inventory[_item_idx].stock += 1;
            add_log(_item_name + " returned from " + _a.name + " to agency stores.");
            return;
        }
    }

    add_log(_a.name + " does not currently have " + _item_name + " issued.");
};

adventurer_mission_gear_bonus = function(_a, _mission) {
    var _bonus = 0;
    for (var i = 0; i < array_length(_a.issued_gear); i++) {
        var _item = get_agency_inventory_item(_a.issued_gear[i]);
        if (!is_struct(_item)) continue;
        _bonus += _item.score_bonus;
        for (var r = 0; r < array_length(_item.roles); r++) {
            if (_item.roles[r] == _a.role) {
                _bonus += 3;
                break;
            }
        }
        if (_item.name == "Lockpick Roll" && (_mission.type == "Recovery" || _mission.type == "Diplomatic")) _bonus += 6;
        if (_item.name == "Ward Scroll" && (_mission.preferred_role == "Mage" || _mission.type == "Recovery")) _bonus += 4;
        if (_item.name == "Healing Kit" && _mission.risk >= 35) _bonus += 2;
    }
    return _bonus;
};

adventurer_collection_bonus = function(_a, _mission) {
    var _bonus = 0;
    _bonus += min(8, array_length(_a.found_magic) * 2);
    _bonus += min(6, array_length(_a.found_relics) * 2);

    for (var i = 0; i < array_length(_a.found_magic); i++) {
        var _magic = _a.found_magic[i];
        if ((_magic == "cipher sigil" || _magic == "warded chant" || _magic == "spark diagram") && _mission.type == "Recovery") _bonus += 2;
        if ((_magic == "binding phrase" || _magic == "court glamour" || _magic == "echo charm") && _mission.type == "Diplomatic") _bonus += 2;
    }

    for (var r = 0; r < array_length(_a.found_relics); r++) {
        var _relic = _a.found_relics[r];
        if ((_relic == "saint's seal" || _relic == "abbey lantern") && _mission.risk >= 35) _bonus += 2;
        if ((_relic == "border map case" || _relic == "old watch badge") && _mission.type == "Security") _bonus += 2;
    }

    return _bonus;
};

adventurer_mission_injury_guard = function(_a) {
    var _guard = 0;
    for (var i = 0; i < array_length(_a.issued_gear); i++) {
        var _item = get_agency_inventory_item(_a.issued_gear[i]);
        if (is_struct(_item)) _guard += _item.injury_guard;
    }
    return _guard;
};

resolve_agency_gear_after_mission = function(_party_ids, _mission, _outcome) {
    for (var p = 0; p < array_length(_party_ids); p++) {
        var _idx = get_adv_index(_party_ids[p]);
        if (_idx < 0) continue;

        var _a = state.adventurers[_idx];
        var _i = 0;
        while (_i < array_length(_a.issued_gear)) {
            var _gear_name = _a.issued_gear[_i];
            var _item = get_agency_inventory_item(_gear_name);
            if (!is_struct(_item) || _item.kind != "consumable") {
                _i += 1;
                continue;
            }

            var _consume = false;
            if (_outcome == "failure") _consume = true;
            else if (_mission.risk >= 30 && irandom(99) < 55) _consume = true;
            else if (irandom(99) < 25) _consume = true;

            if (_consume) {
                add_log(_a.name + " used " + _gear_name + " on " + _mission.title + ".");
                array_delete(_a.issued_gear, _i, 1);
            } else {
                _i += 1;
            }
        }
    }
};

generate_free_agent = function() {
    var _roles = ["Warrior", "Mage", "Rogue", "Bard", "Cleric", "Ranger"];
    var _r = _roles[irandom(array_length(_roles) - 1)];
    var _base = irandom_range(3, 7);
    return build_adventurer_profile(
        random_free_agent_name(),
        _r,
        _base + choose(-1, 0, 1, 2),
        _base + choose(-1, 0, 1, 2),
        _base + choose(-1, 0, 1, 2),
        _base + choose(-1, 0, 1, 2),
        irandom_range(60, 88),
        irandom_range(18, 34),
        irandom_range(20, 42),
        0.22
    );
};

dismiss_intro = function() {
    if (state.show_intro) {
        state.show_intro = false;
        state.status_line = "Desk open. Review contracts and assemble a party.";
    }
};

init_adventurers = function() {
    return [
        build_adventurer_profile("Mira Ashwind", "Mage", 4, 9, 3, 5, 78, 24, 34, 0.22, 56, 0),
        build_adventurer_profile("Bran Ironhook", "Warrior", 9, 1, 3, 4, 71, 31, 30, 0.20, 44, 1),
        build_adventurer_profile("Sable Quickstep", "Rogue", 5, 2, 9, 6, 64, 22, 28, 0.24, 31, 2),
        build_adventurer_profile("Tovin Reed", "Bard", 3, 4, 5, 9, 82, 27, 26, 0.19, 39, 3),
        build_adventurer_profile("Edda Stoneward", "Cleric", 6, 7, 2, 6, 88, 33, 32, 0.18, 62, 4)
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
        { id: 0, name: "Lady Merrow Vale", personality: "courteous", contact: "sealed letter", pay_profile: "high", bonus_profile: "sometimes", risk_profile: "measured", temperament_note: "Usually gracious, but expects polished results.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 1, name: "Quartermaster Halden Pike", personality: "practical", contact: "guild messenger", pay_profile: "steady", bonus_profile: "rare", risk_profile: "moderate", temperament_note: "Values reliability, logistics, and no-nonsense briefings.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 2, name: "Archivist Ilyra Quill", personality: "scholarly", contact: "arcane correspondence", pay_profile: "modest", bonus_profile: "rare", risk_profile: "low", temperament_note: "Prefers careful handling and detailed reports over speed.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 3, name: "Magistrate Doran Flint", personality: "stern", contact: "official courier", pay_profile: "steady", bonus_profile: "rare", risk_profile: "high", temperament_note: "Formal and demanding. Tolerates little improvisation.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 4, name: "Captain Roen Blackwake", personality: "brisk", contact: "dock runner", pay_profile: "high", bonus_profile: "often", risk_profile: "high", temperament_note: "Moves fast, pays for urgency, and accepts rough conditions.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 5, name: "Matron Ysabet Thorn", personality: "demanding", contact: "house steward", pay_profile: "high", bonus_profile: "sometimes", risk_profile: "moderate", temperament_note: "Generous when satisfied, difficult when crossed.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 6, name: "Prior Cedric Vale", personality: "calm", contact: "monastery letter", pay_profile: "modest", bonus_profile: "sometimes", risk_profile: "low", temperament_note: "Patient and fair. Usually prefers safer, service-minded work.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 7, name: "Guildmaster Olin Brass", personality: "transactional", contact: "clerk dispatch", pay_profile: "steady", bonus_profile: "rare", risk_profile: "moderate", temperament_note: "Treats every arrangement like a ledger entry.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 8, name: "Envoy Seris Dawn", personality: "polished", contact: "embassy aide", pay_profile: "high", bonus_profile: "often", risk_profile: "measured", temperament_note: "Refined, image-conscious, and willing to pay for discretion.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 9, name: "Warden Petra Stone", personality: "direct", contact: "watch courier", pay_profile: "steady", bonus_profile: "rare", risk_profile: "high", temperament_note: "Blunt, dependable, and more concerned with results than manners.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50 },
        { id: 10, name: "Temple of the Sacred Flame", personality: "devout", contact: "holy messenger", pay_profile: "high", bonus_profile: "sometimes", risk_profile: "low", temperament_note: "Deeply spiritual, expects sacred service and oaths.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50, oath_type: "sacred_service", oath_vow: "I swear to serve the flame and protect the innocent." },
        { id: 11, name: "Arcane College of the Silver Flame", personality: "scholarly", contact: "arcane correspondence", pay_profile: "high", bonus_profile: "sometimes", risk_profile: "measured", temperament_note: "Seeks arcane knowledge and magical research. Values scholarly rigor.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50, patron_class: "arcane_college" }
        ,
                { id: 12, name: "Abbot of the Sacred Flame", personality: "devout", contact: "holy messenger", pay_profile: "high", bonus_profile: "sometimes", risk_profile: "low", temperament_note: "Deeply spiritual, expects sacred service and oaths. Offers guidance and blessings.", research_hits: 0, contracts_seen: 0, jobs_completed: 0, jobs_partial: 0, jobs_failed: 0, total_patron_pay: 0, total_risk_observed: 0, total_reward_observed: 0, satisfaction: 50, patron_class: "abbot", oath_type: "sacred_service", oath_vow: "I swear to serve the flame and protect the innocent." }
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

    // Check if this is a temple patron with sacred service oath
    var _patron_index = get_patron_index_by_name(_patron_name);
    if (_patron_index >= 0 && patron_is_temple(_patron_index)) {
        _title = _title + " - Sacred Service";
        _desc += " This is a sacred service contract with vows to uphold divine principles.";
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

get_patron_index_by_name = function(_patron_name) {
    for (var i = 0; i < array_length(state.patrons); i++) {
        if (state.patrons[i].name == _patron_name) return i;
    }
    return -1;
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

count_patron_seen_contracts = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return 0;

    var _count = 0;
    var _patron_id = state.patrons[_patron_index].id;
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (state.contracts[i].patron_id == _patron_id && state.contracts[i].unlocked) {
            _count += 1;
        }
    }
    return _count;
};

count_patron_open_requests = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return 0;

    var _count = 0;
    var _patron_id = state.patrons[_patron_index].id;
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _c = state.contracts[i];
        if (_c.patron_id == _patron_id && _c.unlocked && !_c.accepted && !_c.expired && state.absolute_hour < _c.expires_hour) {
            _count += 1;
        }
    }
    return _count;
};

patron_average_offer_reward = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return 0;

    var _sum = 0;
    var _count = 0;
    var _patron_id = state.patrons[_patron_index].id;
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (state.contracts[i].patron_id == _patron_id) {
            _sum += state.contracts[i].mission.reward;
            _count += 1;
        }
    }

    if (_count <= 0) return 0;
    return floor(_sum / _count);
};

patron_average_offer_risk = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return 0;

    var _sum = 0;
    var _count = 0;
    var _patron_id = state.patrons[_patron_index].id;
    for (var i = 0; i < array_length(state.contracts); i++) {
        if (state.contracts[i].patron_id == _patron_id) {
            _sum += state.contracts[i].mission.risk;
            _count += 1;
        }
    }

    if (_count <= 0) return 0;
    return floor(_sum / _count);
};

record_patron_job_result = function(_contract_index, _result, _gross_patron_pay) {
    if (_contract_index < 0 || _contract_index >= array_length(state.contracts)) return;

    var _pidx = get_patron_index(state.contracts[_contract_index].patron_id);
    if (_pidx < 0) return;

    var _patron = state.patrons[_pidx];
    if (!variable_struct_exists(_patron, "job_history")) {
        _patron.job_history = [];
    }

    if (!variable_struct_exists(_result, "late_delivery")) _result.late_delivery = false;

    var _job_result = {
        outcome: _result.outcome,
        late_delivery: _result.late_delivery || false
    };
    array_push(_patron.job_history, _job_result);

    if (_result.late_delivery) {
        if (!variable_struct_exists(_patron, "late_delivery_count")) {
            _patron.late_delivery_count = 0;
        }
        _patron.late_delivery_count += 1;
    }

    // Update memory summary for research reports
    if (!variable_struct_exists(_patron, "memory_summary")) {
        _patron.memory_summary = {
            completed: 0,
            failed: 0,
            late_deliveries: 0
        };
    }

    if (_result.outcome == "success") {
        _patron.memory_summary.completed += 1;
    } else if (_result.outcome == "failed") {
        _patron.memory_summary.failed += 1;
    }

    if (_result.late_delivery) {
        _patron.memory_summary.late_deliveries += 1;
    }
    _patron.total_patron_pay += _gross_patron_pay;

    switch (_result.outcome) {
        case "success":
            _patron.jobs_completed += 1;
            // Temple patrons have special satisfaction handling
            if (patron_is_temple(_pidx)) {
                _patron.satisfaction = clamp(_patron.satisfaction + 12, 0, 100);
            } else {
                _patron.satisfaction = clamp(_patron.satisfaction + 8, 0, 100);
            }
        break;
        case "partial":
            _patron.jobs_partial += 1;
            // Temple patrons have special satisfaction handling
            if (patron_is_temple(_pidx)) {
                _patron.satisfaction = clamp(_patron.satisfaction + 4, 0, 100);
            } else {
                _patron.satisfaction = clamp(_patron.satisfaction + 2, 0, 100);
            }
        break;
        default:
        // Check for blacklisting and sanctions
        if (_patron.jobs_failed >= 3 && _patron.jobs_completed + _patron.jobs_partial < 2) {
            _patron.blacklisted = true;
            add_log("Patron blacklisted: " + _patron.name);
        }

        // Check for sanctions
        if (_patron.jobs_failed >= 2 && _patron.jobs_completed < 1) {
            _patron.sanctioned = true;
            add_log("Patron sanctioned: " + _patron.name);
        }

        // Check for noble favor
        if (_patron.jobs_completed >= 5 && _patron.satisfaction >= 90) {
            _patron.noble_favor = 15;
            add_log("Noble favor gained: " + _patron.name);
        }
            _patron.jobs_failed += 1;
            // Temple patrons have special satisfaction handling
            if (patron_is_temple(_pidx)) {
                _patron.satisfaction = clamp(_patron.satisfaction - 15, 0, 100);
            } else {
                _patron.satisfaction = clamp(_patron.satisfaction - 10, 0, 100);
            }
        break;
    }
};

patron_satisfaction_label = function(_score) {
    if (_score >= 75) return "favored";
    if (_score >= 60) return "warm";
    if (_score >= 40) return "neutral";
    if (_score >= 25) return "strained";
    return "hostile";
};

patron_is_temple = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return false;
    var _patron = state.patrons[_patron_index];
    return variable_struct_exists(_patron, "oath_type") && _patron.oath_type == "sacred_service" && (!variable_struct_exists(_patron, "patron_class") || _patron.patron_class != "arcane_college");
};

patron_is_temple_by_name = function(_patron_name) {
    for (var i = 0; i < array_length(state.patrons); i++) {
        if (state.patrons[i].name == _patron_name) {
            return patron_is_temple(i);
        }
    }
    return false;
};

award_adventurer_mission_find = function(_adv_id, _mission, _outcome) {
    var _idx = get_adv_index(_adv_id);
    if (_idx < 0) return;

    var _find_roll = irandom(99);
    if (_outcome == "failure" || _find_roll > 38) return;

    var _a = state.adventurers[_idx];
    var _item = "";

    if ((_a.role == "Mage" || _a.role == "Cleric" || _a.role == "Bard") && _find_roll < 18) {
        switch (_mission.type) {
            case "Recovery": _item = choose("cipher sigil", "ember cantrip", "restoration verse"); break;
            case "Diplomatic": _item = choose("binding phrase", "court glamour", "oath charm"); break;
            default: _item = choose("spark diagram", "warded chant", "field invocation"); break;
        }
        if (array_length(_a.found_magic) < 8) {
            array_push(_a.found_magic, _item);
            add_log(_a.name + " picked up new magic: " + _item + ".");
        }
        return;
    }

    if (_find_roll < 28) {
        switch (_mission.type) {
            case "Security": _item = choose("old watch badge", "captain's seal", "border map case"); break;
            case "Recovery": _item = choose("saint's seal", "abbey lantern", "ruin key fragment"); break;
            case "Diplomatic": _item = choose("court signet shard", "envoy ribbon", "oath token"); break;
            default: _item = choose("weathered charm", "road marker token", "guild tally plate"); break;
        }

        if (array_length(_a.found_relics) < 8) {
            array_push(_a.found_relics, _item);
            add_log(_a.name + " secured a relic: " + _item + ".");
        }
        return;
    }

    switch (_mission.type) {
        case "Security": _item = choose("reinforced buckler", "tempered spearhead", "bandit map case"); break;
        case "Recovery": _item = choose("relic satchel", "archive charm", "dust-proof field kit"); break;
        case "Diplomatic": _item = choose("signet ribbon", "negotiator's ledger", "silk envoy gloves"); break;
        default: _item = choose("well-made rope", "traveler's charm", "fine field tools"); break;
    }

    if (array_length(_a.notable_finds) < 8) {
        array_push(_a.notable_finds, _item);
        add_log(_a.name + " kept a notable find: " + _item + ".");
    }
};

log_patron_research_report = function(_patron_index) {
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return;

    var _p = state.patrons[_patron_index];
    _p.research_hits += 1;
    _p.contracts_seen = max(_p.contracts_seen, count_patron_seen_contracts(_patron_index));

    var _worked = _p.jobs_completed + _p.jobs_partial + _p.jobs_failed;
    var _open_requests = count_patron_open_requests(_patron_index);
    var _avg_offer_pay = patron_average_offer_reward(_patron_index);
    var _avg_offer_risk = patron_average_offer_risk(_patron_index);
    var _avg_paid = (_worked > 0) ? floor(_p.total_patron_pay / _worked) : 0;

    add_log("Patron research file updated: " + _p.name + ".");
    add_log("Profile: " + string_upper(_p.personality) + " | Contact usually via " + _p.contact + ".");
    add_log("Intel: pay tends " + _p.pay_profile + ", bonuses " + _p.bonus_profile + ", assignments trend " + _p.risk_profile + " risk.");
    add_log("Temperament: " + _p.temperament_note);
    add_log("Relationship standing: " + patron_satisfaction_label(_p.satisfaction) + " (" + string(_p.satisfaction) + "/100).");
    add_log("Patron payment quality: " + _p.pay_profile + ".");
    // Payment reliability and dispute likelihood indicators
    var _reliability = "unknown";
    var _dispute_likelihood = "unknown";
    var _payment_quality = "unknown";

    if (variable_struct_exists(_p, "total_patron_pay") && variable_struct_exists(_p, "jobs_completed")) {
        if (_p.jobs_completed > 0) {
            var _avg_payment = floor(_p.total_patron_pay / _p.jobs_completed);
            if (_avg_payment >= 100) {
                _payment_quality = "high";
            } else if (_avg_payment >= 50) {
                _payment_quality = "medium";
            } else {
                _payment_quality = "low";
            }
        }

        if (variable_struct_exists(_p, "jobs_failed") && variable_struct_exists(_p, "jobs_completed")) {
            var _total_jobs = _p.jobs_completed + _p.jobs_failed;
            if (_total_jobs > 0) {
                var _failure_rate = _p.jobs_failed / _total_jobs;
                if (_failure_rate < 0.2) {
                    _reliability = "high";
                } else if (_failure_rate < 0.5) {
                    _reliability = "medium";
                } else {
                    _reliability = "low";
                }

                if (_failure_rate < 0.1) {
                    _dispute_likelihood = "low";
                } else if (_failure_rate < 0.3) {
                    _dispute_likelihood = "medium";
                } else {
                    _dispute_likelihood = "high";
                }
            }
        }
    }

    add_log("Payment reliability: " + _reliability + " | Dispute likelihood: " + _dispute_likelihood + " | Payment quality: " + _payment_quality + ".");

    if (_worked > 0) {
        add_log("Agency history: worked " + string(_worked) + " contract(s) | success " + string(_p.jobs_completed) + ", partial " + string(_p.jobs_partial) + ", failed " + string(_p.jobs_failed) + ".");
        add_log("Observed patron pay: avg " + string(_avg_paid) + "g across completed work.");
    } else {
        add_log("Agency history: no completed contracts with this patron yet.");
    }

    add_log("Known requests on file: " + string(_p.contracts_seen) + " seen so far, " + string(_open_requests) + " currently visible from View Patron Requests.");
    add_log("Offer pattern: average listed pay " + string(_avg_offer_pay) + "g, average listed risk " + string(_avg_offer_risk) + ".");
    // Patron memory summary
    if (variable_struct_exists(_p, "memory_summary")) {
        add_log("Patron memory: " + string(_p.memory_summary.completed) + " completed, " + string(_p.memory_summary.failed) + " failed, " + string(_p.memory_summary.late_deliveries) + " late deliveries.");
    }

    // Special handling for temple patrons
    if (patron_is_temple(_patron_index)) {
        add_log("Special note: Temple of the Sacred Flame requires sacred service oaths and divine commitment.");
        if (variable_struct_exists(_p, "oath_vow")) {
            add_log("Oath vow: " + _p.oath_vow);
        }
    }
};

reset_market_offer_terms = function() {
    state.offer_bonus = 0;
    state.offer_rate_delta = 0;
    state.offer_commission = 0.22;
};

open_market_hub = function() {
    if (array_length(state.free_agents) <= 0) {
        refresh_free_agent_market();
    }

    state.mode = MODE.BUYING;
    state.market_stage = "hub";
    state.status_line = "Recruitment desk open. Scout or negotiate.";
};

open_market_board = function() {
    if (array_length(state.free_agents) <= 0) {
        refresh_free_agent_market();
    }

    state.mode = MODE.BUYING;
    state.market_stage = "board";
    state.status_line = "Scouting free-agent candidates.";
    add_log("Market board open. Review candidates before making an approach.");
};

open_market_candidate = function(_idx) {
    if (array_length(state.free_agents) <= 0) {
        add_log("No free agents on the board. Refresh market.");
        return;
    }

    state.selected_free_agent_index = clamp(_idx, 0, array_length(state.free_agents) - 1);
    state.mode = MODE.BUYING;
    state.market_stage = "candidate";
    state.status_line = "Reviewing candidate profile.";

    var _fa = state.free_agents[state.selected_free_agent_index];
    var _cand_score = adventurer_market_score(_fa);
    var _roster_score = average_roster_market_score();
    var _score_delta = _cand_score - _roster_score;
    var _roster_rate = average_roster_day_rate();
    var _rate_delta = _fa.ask_rate - _roster_rate;
    add_log("Candidate reviewed: " + _fa.name + " | " + _fa.role + " | profile " + string(_fa.profile_score) + ".");
    add_log("Stats: C" + string(_fa.combat) + " M" + string(_fa.magic) + " S" + string(_fa.stealth) + " D" + string(_fa.diplomacy) + " R" + string(_fa.reliability) + " | Age " + string(_fa.age) + ".");
    add_log("Roster comparison: score " + string(_cand_score) + " vs roster avg " + string(_roster_score) + " (" + market_score_label(_score_delta) + ", " + ((_score_delta >= 0) ? "+" : "") + string(_score_delta) + ").");
    add_log("Cost comparison: ask rate " + string(_fa.ask_rate) + "g/day vs roster avg " + string(_roster_rate) + "g/day (" + ((_rate_delta >= 0) ? "+" : "") + string(_rate_delta) + "g/day).");
    add_log("Ask bonus " + string(_fa.ask_bonus) + "g | Ask rate " + string(_fa.ask_rate) + "g/day | Minimum commission " + string(round(_fa.min_commission * 100)) + "%.");
    add_log("Negotiation style: " + string_upper(_fa.negotiation_style) + ". " + _fa.style_blurb);
    add_log("Why representation: " + market_representation_reason(_fa));
    add_log(_fa.name + ": " + market_style_line(_fa.negotiation_style, "target"));
};

open_market_offer_stage = function() {
    if (array_length(state.free_agents) <= 0 || state.selected_free_agent_index < 0) {
        add_log("Select a free agent first.");
        return;
    }

    reset_market_offer_terms();
    state.market_stage = "offer";
    state.status_line = "Drafting recruitment offer.";
    add_log("Adjust bonus, rate, and commission, then submit your proposal.");
};

match_market_offer_to_ask = function() {
    if (array_length(state.free_agents) <= 0 || state.selected_free_agent_index < 0) {
        add_log("Select a free agent first.");
        return;
    }

    var _fa = state.free_agents[state.selected_free_agent_index];
    state.offer_bonus = _fa.ask_bonus;
    state.offer_rate_delta = _fa.ask_rate - _fa.adventure_rate;
    state.offer_commission = _fa.min_commission;
    add_log("Offer terms matched to " + _fa.name + "'s stated ask.");
};

process_idle_adventurer_pressure = function() {
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];

        if (_a.status == "available") {
            _a.idle_days += 1;

            var _should_notice = (_a.idle_days >= 3) && ((_a.idle_days == 3) || ((_a.idle_days mod 2) == 1));
            if (_should_notice && _a.last_idle_notice_day != state.day) {
            if (_a.idle_days == 3) {
                add_log(_a.name + " has been idle for 3 days.");
            }

            if (_a.idle_days == 5) {
                add_log(_a.name + " has been idle for 5 days.");
            }

            if (_a.idle_days == 10) {
                add_log(_a.name + " has been idle for 10 days.");
            }
                _a.last_idle_notice_day = state.day;
                add_log(_a.name + " is getting restless after " + string(_a.idle_days) + " idle day(s) without a contract.");
            }
        } else {
            _a.idle_days = 0;
        }
    }
};

adventurer_market_score = function(_a) {
    var _core = (_a.combat + _a.magic + _a.stealth + _a.diplomacy) / 4;
    return round(_core * 10 + _a.reliability * 0.3);
};

average_roster_market_score = function() {
    var _sum = 0;
    var _count = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status != "retired") {
            _sum += adventurer_market_score(state.adventurers[i]);
            _count += 1;
        }
    }

    if (_count <= 0) return 0;
    return round(_sum / _count);
};

average_roster_day_rate = function() {
    var _sum = 0;
    var _count = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        if (state.adventurers[i].status != "retired") {
            _sum += state.adventurers[i].adventure_rate;
            _count += 1;
        }
    }

    if (_count <= 0) return 0;
    return round(_sum / _count);
};

market_score_label = function(_delta) {
    if (_delta >= 12) return "well above roster average";
    if (_delta >= 5) return "above roster average";
    if (_delta <= -12) return "well below roster average";
    if (_delta <= -5) return "below roster average";
    return "roughly on roster average";
};

change_adventurer_morale = function(_adv_id, _delta, _reason) {
    var _idx = get_adv_index(_adv_id);
    if (_idx < 0) return;
    var _a = state.adventurers[_idx];
    var _old = _a.morale;
    _a.morale = clamp(_a.morale + _delta, 0, 100);
    if (!is_undefined(_reason) && _reason != "" && _a.morale != _old) {
        add_log(_a.name + " morale " + ((_delta >= 0) ? "rose" : "fell") + " to " + string(_a.morale) + " (" + _reason + ").");
    }
};

change_adventurer_trust = function(_adv_id, _delta, _reason) {
    var _idx = get_adv_index(_adv_id);
    if (_idx < 0) return;
    var _a = state.adventurers[_idx];
    var _old = _a.trust;
    _a.trust = clamp(_a.trust + _delta, 0, 100);
    if (!is_undefined(_reason) && _reason != "" && _a.trust != _old) {
        add_log(_a.name + " trust " + ((_delta >= 0) ? "rose" : "fell") + " to " + string(_a.trust) + " (" + _reason + ").");
    }
};

process_client_contract_pressure = function() {
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];

        if (variable_struct_exists(_a, "contract_days_remaining")) {
            _a.contract_days_remaining = max(0, _a.contract_days_remaining - 1);
            if (_a.contract_days_remaining == 5) {
                add_log(_a.name + "'s " + _a.representation_type + " expires in 5 day(s).");
            } else if (_a.contract_days_remaining == 0 && _a.last_charter_notice_day != state.day) {
                _a.last_charter_notice_day = state.day;
                add_log(_a.name + "'s charter has expired. They expect a renewal meeting or a release.");
            }
        }

        if (_a.status == "available" && variable_struct_exists(_a, "activity_expectation_days") && _a.idle_days > _a.activity_expectation_days) {
            change_adventurer_morale(_a.id, -2, "too many quiet days between contracts");
            if ((_a.idle_days - _a.activity_expectation_days) >= 2) {
                change_adventurer_trust(_a.id, -1, "agency is not matching promised work tempo");
            }
        }

        if (variable_struct_exists(_a, "renegotiation_annoyance") && _a.renegotiation_annoyance > 0) {
            _a.renegotiation_annoyance = max(0, _a.renegotiation_annoyance - 1);
        }

        if (variable_struct_exists(_a, "promised_work_by_day") && _a.promised_work_by_day > 0) {
            if (_a.status == "on_mission") {
                _a.promised_work_by_day = 0;
            } else if (state.day > _a.promised_work_by_day) {
                _a.promised_work_by_day = 0;
                add_log("You missed a promised assignment window for " + _a.name + ".");
                change_adventurer_morale(_a.id, -3, "agency broke a promise of near-term work");
                change_adventurer_trust(_a.id, -4, "promised work never materialized");
                _a.renegotiation_annoyance = min(5, _a.renegotiation_annoyance + 1);
            }
        }

        var _risk = 0;
        if (_a.morale < 60) _risk += (60 - _a.morale);
        if (_a.trust < 55) _risk += (55 - _a.trust);
        if (_a.idle_days > _a.activity_expectation_days) _risk += (_a.idle_days - _a.activity_expectation_days) * 6;
        _risk += _a.renegotiation_annoyance * 5;
        if (_a.promised_work_by_day > 0) _risk -= 8;
        if (_a.contract_days_remaining <= 5) _risk += 8;
        if (_a.contract_days_remaining <= 0) _risk += 15;
        if (_a.idle_days >= 5) {
            change_adventurer_morale(_a.id, -1, "idle for too many days");
            _risk += 5;
        }

        if (_a.idle_days >= 10) {
            change_adventurer_morale(_a.id, -2, "extremely idle");
            _risk += 10;
        }

        if (_a.contract_days_remaining <= 0 && _a.idle_days >= 3) {
        if (variable_struct_exists(_a, "city_id") && _a.city_id != home_city_id()) {
            _a.remote_city_days = variable_struct_exists(_a, "remote_city_days") ? _a.remote_city_days + 1 : 1;
            if (_a.remote_city_days >= 4) {
                change_adventurer_morale(_a.id, -1, "away from home too long");
                add_log(_a.name + " has been away from home for " + string(_a.remote_city_days) + " days");
            }
        } else {
            _a.remote_city_days = 0;
        }
            change_adventurer_morale(_a.id, -1, "contract expired and idle");
            _risk += 5;
        }
        _a.defection_risk = clamp(_risk, 0, 100);

        if (_a.defection_risk >= 45 && !_a.departure_warning) {
            _a.departure_warning = true;
            add_log(_a.name + " is openly considering other banners. Defection risk is rising.");
        } else if (_a.defection_risk < 30 && _a.departure_warning) {
            _a.departure_warning = false;
            add_log(_a.name + " seems calmer about staying with the agency.");
        }
    }
};

apply_client_profile_from_negotiation_style = function(_a) {
    if (!variable_struct_exists(_a, "negotiation_style")) return;

    switch (_a.negotiation_style) {
        case "money_first":
            _a.ambition = "higher pay";
            _a.activity_expectation_days = 3;
            _a.risk_preference = "balanced";
        break;
        case "prestige_first":
            _a.ambition = "prestige jobs";
            _a.activity_expectation_days = 4;
            _a.risk_preference = "bold";
        break;
        case "security_first":
            _a.ambition = "steady work";
            _a.activity_expectation_days = 3;
            _a.risk_preference = "careful";
        break;
        case "loyalty_first":
            _a.ambition = "steady work";
            _a.activity_expectation_days = 2;
            _a.risk_preference = "balanced";
            _a.trust = min(100, _a.trust + 4);
        break;
        case "hardline":
            _a.ambition = "higher pay";
            _a.activity_expectation_days = 2;
            _a.risk_preference = "bold";
        break;
    }
};

refresh_mission_board = function() {
    normalize_contracts();
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

count_available_adventurers = function() {
    var _count = 0;
    for (var i = 0; i < array_length(state.adventurers); i++) {
        var _a = state.adventurers[i];
        if (_a.status == "available" && !is_adventurer_committed(_a.id)) {
            _count += 1;
        }
    }
    return _count;
};

get_selected_contract = function() {
    if (state.selected_contract_index < 0 || state.selected_contract_index >= array_length(state.contracts)) {
        return undefined;
    }
    return state.contracts[state.selected_contract_index];
};

select_mission_by_contract_index = function(_contract_index) {
    refresh_mission_board();

    for (var i = 0; i < array_length(state.missions); i++) {
        if (state.missions[i].contract_index == _contract_index) {
            state.selected_mission_index = i;
            return true;
        }
    }

    state.selected_mission_index = -1;
    return false;
};

get_patron_contract_indices = function(_patron_index) {
    var _matches = [];
    if (_patron_index < 0 || _patron_index >= array_length(state.patrons)) return _matches;

    var _patron_id = state.patrons[_patron_index].id;
    for (var i = 0; i < array_length(state.contracts); i++) {
        var _c = state.contracts[i];
        if (_c.patron_id == _patron_id && _c.unlocked && !_c.accepted && !_c.expired && state.absolute_hour < _c.expires_hour) {
            array_push(_matches, i);
        }
    }

    return _matches;
};

reset_contracting_selection = function() {
    state.selected_patron_index = -1;
    state.selected_contract_index = -1;
    state.selected_mission_index = -1;
    state.selected_party_ids = [];
    state.contracting_stage = "patrons";
};

reset_mission_review_selection = function() {
    state.selected_mission_index = -1;
    state.selected_party_ids = [];
    state.mission_review_stage = "missions";
};

open_adventurer_roster = function(_return_mode) {
    if (is_undefined(_return_mode)) _return_mode = MODE.PLANNING;
    state.adventurer_view_return_mode = _return_mode;
    state.mode = MODE.ADVENTURERS;
    state.adventurer_view_stage = "list";
    state.selected_adventurer_index = -1;
    state.status_line = "Reviewing represented adventurers.";
    print_adventurers();
};

open_adventurer_detail = function(_idx) {
    if (_idx < 0 || _idx >= array_length(state.adventurers)) return;

    state.mode = MODE.ADVENTURERS;
    state.adventurer_view_stage = "detail";
    state.selected_adventurer_index = _idx;

    var _a = state.adventurers[_idx];
    state.status_line = "Adventurer file: " + _a.name;
    add_log("Adventurer file: " + _a.name + " | " + _a.role + " | Age " + string(_a.age) + " [" + string_upper(_a.status) + "]");
    add_log("Stats: C" + string(_a.combat) + " M" + string(_a.magic) + " S" + string(_a.stealth) + " D" + string(_a.diplomacy) + " R" + string(_a.reliability) + ".");
    add_log("Contract terms: " + string(_a.adventure_rate) + "g/day | Agency commission " + string(round(_a.commission_rate * 100)) + "%.");
    add_log("Representation: " + _a.representation_type + " | " + string(_a.contract_days_remaining) + "/" + string(_a.contract_term_days) + " day(s) remaining.");
    add_log("Relationship: morale " + string(_a.morale) + " | trust " + string(_a.trust) + " | expects work every " + string(_a.activity_expectation_days) + " day(s) | priority " + _a.ambition + " | risk " + _a.risk_preference + " | negotiation annoyance " + string(_a.renegotiation_annoyance) + " | defection risk " + string(_a.defection_risk) + ".");
    add_log("Personal purse: " + string(_a.purse_gold) + "g | Lifetime earnings " + string(_a.lifetime_earnings) + "g | Last mission payout " + string(_a.last_mission_payout) + "g.");
    add_log("Kit: " + array_join_text(_a.kit));
    add_log("Agency-issued gear: " + adventurer_issued_gear_text(_a) + ".");
    add_log("Arcana known: " + array_join_text(_a.found_magic));
    add_log("Relics held: " + array_join_text(_a.found_relics));
    add_log("Field finds: " + array_join_text(_a.notable_finds));
};

open_adventurer_renegotiation = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    state.mode = MODE.ADVENTURERS;
    state.adventurer_view_stage = "renegotiate";
    state.renegotiation_rate_offer = _a.adventure_rate;
    state.renegotiation_commission_offer = _a.commission_rate;
    state.renegotiation_term_offer = _a.contract_term_days;
    state.status_line = "Renegotiating " + _a.name + "'s representation terms.";
    add_log("Renegotiation opened for " + _a.name + ".");
    add_log("Current terms: " + string(_a.adventure_rate) + "g/day | Agency commission " + string(round(_a.commission_rate * 100)) + "% | " + string(_a.contract_term_days) + "-day charter.");
};

open_adventurer_retention_meeting = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status == "on_mission") {
        add_log(_a.name + " is currently in the field. Meet them after the contract closes.");
        return;
    }

    state.mode = MODE.ADVENTURERS;
    state.adventurer_view_stage = "retention";
    state.status_line = "Meeting with " + _a.name + " about representation concerns.";
    add_log("Retention meeting opened for " + _a.name + ".");
    if (_a.departure_warning) {
        add_log(_a.name + " is clearly entertaining outside offers.");
    }
    if (_a.contract_days_remaining <= 0) {
        add_log("Their current charter has expired and needs a renewal decision.");
    } else if (_a.contract_days_remaining <= 5) {
        add_log("Their charter is nearly up. A renewal offer would steady the relationship.");
    }
};

adjust_adventurer_renegotiation = function(_field, _delta) {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    switch (_field) {
        case "rate":
            state.renegotiation_rate_offer = clamp(state.renegotiation_rate_offer + _delta, 10, 120);
            add_log("Renegotiation day rate set to " + string(state.renegotiation_rate_offer) + "g/day.");
        break;
        case "commission":
            state.renegotiation_commission_offer = clamp(state.renegotiation_commission_offer + _delta, 0.10, 0.35);
            add_log("Agency commission set to " + string(round(state.renegotiation_commission_offer * 100)) + "%.");
        break;
        case "term":
            state.renegotiation_term_offer = clamp(state.renegotiation_term_offer + _delta, 10, 90);
            add_log("Representation term set to " + string(state.renegotiation_term_offer) + " day(s).");
        break;
    }
};

evaluate_adventurer_renegotiation = function(_a) {
    var _desired_rate = _a.adventure_rate;
    var _desired_commission = _a.commission_rate;
    var _desired_term = _a.contract_term_days;

    switch (_a.ambition) {
        case "higher pay": _desired_rate += 4; _desired_commission -= 0.01; break;
        case "prestige jobs": _desired_rate += 2; break;
        case "steady work": _desired_term += 10; break;
        case "glory": _desired_rate += 1; _desired_term += 5; break;
    }

    switch (_a.risk_preference) {
        case "careful": _desired_commission -= 0.01; break;
        case "bold": _desired_rate += 1; break;
    }

    _desired_commission = clamp(_desired_commission, 0.10, 0.35);
    _desired_term = clamp(_desired_term, 10, 90);

    var _score = 48;
    _score += (state.renegotiation_rate_offer - _desired_rate) * 2.8;
    _score += (_desired_commission - state.renegotiation_commission_offer) * 260;
    _score += (state.renegotiation_term_offer - _desired_term) * 0.35;
    _score += (_a.trust - 60) * 0.30;
    _score += (_a.morale - 60) * 0.20;
    _score -= _a.renegotiation_annoyance * 4;
    _score += irandom_range(-6, 6);

    return {
        score: _score,
        desired_rate: _desired_rate,
        desired_commission: _desired_commission,
        desired_term: _desired_term
    };
};

submit_adventurer_renegotiation = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    var _eval = evaluate_adventurer_renegotiation(_a);
    _a.last_renegotiation_day = state.day;

    add_log("You propose: " + string(state.renegotiation_rate_offer) + "g/day | Agency commission " + string(round(state.renegotiation_commission_offer * 100)) + "% | " + string(state.renegotiation_term_offer) + "-day charter.");

    if (_eval.score >= 55) {
        _a.adventure_rate = state.renegotiation_rate_offer;
        _a.commission_rate = state.renegotiation_commission_offer;
        _a.contract_term_days = state.renegotiation_term_offer;
        _a.contract_days_remaining = max(_a.contract_days_remaining, state.renegotiation_term_offer);
        _a.renegotiation_annoyance = max(0, _a.renegotiation_annoyance - 1);
        add_log(_a.name + " accepted the revised charter terms.");
        change_adventurer_morale(_a.id, 3, "renegotiation concluded on acceptable terms");
        change_adventurer_trust(_a.id, 1, "agency responded to contract concerns");
        open_adventurer_detail(state.selected_adventurer_index);
    } else {
        _a.renegotiation_annoyance = min(5, _a.renegotiation_annoyance + ((_eval.score < 42) ? 2 : 1));
        add_log(_a.name + " rejected the proposal. They seem to want roughly " + string(_eval.desired_rate) + "g/day, agency commission near " + string(round(_eval.desired_commission * 100)) + "%, and about " + string(_eval.desired_term) + " days.");
        add_log(_a.name + " seems irritated by the terms. Negotiation annoyance is now " + string(_a.renegotiation_annoyance) + ".");
        change_adventurer_morale(_a.id, -2, "unsuccessful renegotiation");
        if (_eval.score < 42) change_adventurer_trust(_a.id, -2, "agency proposal missed client expectations");
    }
};

promise_adventurer_work = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status != "available") {
        add_log(_a.name + " is not waiting at the desk right now.");
        return;
    }

    _a.promised_work_by_day = state.day + 3;
    add_log("You promise " + _a.name + " a contract lead within 3 days.");
    change_adventurer_morale(_a.id, 2, "agency promised near-term work");
    change_adventurer_trust(_a.id, 2, "agency gave a concrete work promise");
};

pay_adventurer_retention_bonus = function(_amount) {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;
    if (_amount <= 0) return;
    if (_amount > state.gold) {
        add_log("Insufficient gold to offer that loyalty purse.");
        return;
    }

    var _a = state.adventurers[state.selected_adventurer_index];
    spend_gold(_amount, "Retention purse paid to " + _a.name + ".");
    _a.purse_gold += _amount;
    _a.renegotiation_annoyance = max(0, _a.renegotiation_annoyance - 1);
    add_log(_a.name + " accepts a " + string(_amount) + "g loyalty purse.");
    change_adventurer_morale(_a.id, (_amount >= 30) ? 5 : 3, "agency invested directly in client goodwill");
    change_adventurer_trust(_a.id, (_amount >= 30) ? 3 : 2, "agency backed words with coin");
};

evaluate_adventurer_renewal = function(_a, _term_days, _rate_delta) {
    var _score = 44;
    _score += (_a.trust - 55) * 0.45;
    _score += (_a.morale - 55) * 0.30;
    _score -= _a.renegotiation_annoyance * 4;
    _score -= floor(_a.defection_risk / 8);
    _score += _rate_delta * 4;
    _score += (_term_days >= 30) ? 4 : 1;
    if (_a.promised_work_by_day > 0) _score += 4;
    if (_a.ambition == "higher pay") _score += _rate_delta * 2;
    if (_a.ambition == "steady work") _score += (_term_days >= 30) ? 5 : 1;
    if (_a.ambition == "prestige jobs") _score += 1;
    if (_a.risk_preference == "careful" && _term_days >= 30) _score += 2;
    _score += irandom_range(-5, 5);

    return _score;
};

offer_adventurer_renewal = function(_term_days, _rate_delta) {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    var _score = evaluate_adventurer_renewal(_a, _term_days, _rate_delta);
    var _new_rate = _a.adventure_rate + _rate_delta;
    add_log("You offer " + _a.name + " a renewed charter: +" + string(_term_days) + " day(s) at " + string(_new_rate) + "g/day.");

    if (_score >= 52) {
        _a.adventure_rate = _new_rate;
        _a.contract_term_days = max(_a.contract_term_days, _term_days);
        _a.contract_days_remaining += _term_days;
        _a.departure_warning = false;
        _a.promised_work_by_day = 0;
        _a.renegotiation_annoyance = max(0, _a.renegotiation_annoyance - 1);
        add_log(_a.name + " renewed their charter with the agency.");
        change_adventurer_morale(_a.id, 4, "charter renewed on workable terms");
        change_adventurer_trust(_a.id, 3, "agency secured continued representation");
        open_adventurer_detail(state.selected_adventurer_index);
    } else {
        _a.renegotiation_annoyance = min(5, _a.renegotiation_annoyance + 1);
        add_log(_a.name + " rejected the renewal and wants better proof this agency is worth staying with.");
        if (_rate_delta <= 0 && _a.ambition == "higher pay") {
            add_log("Hint: they are leaning toward a sweeter pay package.");
        } else if (_term_days < 30 && _a.ambition == "steady work") {
            add_log("Hint: they want a longer, steadier charter.");
        } else {
            add_log("Hint: better trust, morale, or sweeter terms may be needed before they renew.");
        }
        change_adventurer_morale(_a.id, -1, "renewal talks stalled");
        change_adventurer_trust(_a.id, -1, "agency failed to close renewal concerns");
    }
};

release_adventurer_client = function() {
    if (state.selected_adventurer_index < 0 || state.selected_adventurer_index >= array_length(state.adventurers)) return;

    var _a = state.adventurers[state.selected_adventurer_index];
    if (_a.status == "on_mission") {
        add_log(_a.name + " cannot be released while currently on contract.");
        return;
    }
    _a.status = "unavailable";
    _a.departure_warning = false;
    _a.promised_work_by_day = 0;
    add_log("You released " + _a.name + " from representation. They leave the roster to seek other banners.");
    state.status_line = _a.name + " has left the agency roster.";
    open_adventurer_roster(state.adventurer_view_return_mode);
};

open_contracting_patron_list = function() {
    state.mode = MODE.CONTRACTING;
    state.contracting_stage = "patrons";
    state.selected_patron_index = -1;
    state.selected_contract_index = -1;
    state.selected_mission_index = -1;
    state.selected_party_ids = [];
    state.status_line = "Reviewing patron correspondence.";
    print_patrons();
};

open_mission_board = function() {
    refresh_mission_board();
    state.mode = MODE.MISSION_REVIEW;
    state.mission_review_stage = "missions";
    state.selected_party_ids = [];
    state.status_line = "Reviewing mission board.";
    print_missions();
};

open_patron_contracts = function(_patron_index) {
    unlock_patron_contracts(_patron_index);
    state.mode = MODE.CONTRACTING;
    state.contracting_stage = "contracts";
    state.selected_contract_index = -1;
    state.selected_party_ids = [];

    var _patron = state.patrons[_patron_index];
    state.status_line = "Reviewing contracts from " + _patron.name + ".";
};

select_contract_for_review = function(_contract_index) {
    if (_contract_index < 0 || _contract_index >= array_length(state.contracts)) return;

    var _contract = state.contracts[_contract_index];
    if (!_contract.unlocked || _contract.accepted || _contract.expired || state.absolute_hour >= _contract.expires_hour) {
        add_log("That contract is no longer available.");
        return;
    }

    state.selected_contract_index = _contract_index;
    state.contracting_stage = "contract";
    state.selected_party_ids = [];
    if (!select_mission_by_contract_index(_contract_index)) {
        add_log("That contract is no longer on the board.");
        state.selected_contract_index = -1;
        return;
    }
    state.status_line = "Contract review: " + _contract.mission.title;
};

advance_to_party_assignment = function() {
    var _contract = get_selected_contract();
    if (!is_struct(_contract)) {
        add_log("Select a contract first.");
        return;
    }

    if (count_available_adventurers() <= 0) {
        add_log("No available adventurers to assign right now.");
        return;
    }

    state.contracting_stage = "party";
    state.status_line = "Assign adventurers to " + _contract.mission.title + ".";
    add_log("Choose your adventurers, then click Done Selecting.");
};

finish_party_assignment = function() {
    if (array_length(selected_party()) <= 0) {
        add_log("Select at least one available adventurer.");
        return;
    }

    var _contract = get_selected_contract();
    if (!is_struct(_contract)) {
        add_log("Select a contract first.");
        return;
    }

    // Track patron payment quality when accepting contracts
    if (state.selected_patron_index >= 0 && state.selected_patron_index < array_length(state.patrons)) {
        var _patron = state.patrons[state.selected_patron_index];
        var _contract_reward = _contract.mission.reward;

        // Determine payment quality based on reward
        var _pay_quality = "modest";
        if (_contract_reward >= 200) {
            _pay_quality = "high";
        } else if (_contract_reward >= 100) {
            _pay_quality = "steady";
        }

        // Update patron's payment quality tracking
        if (_pay_quality == "high") {
            _patron.pay_profile = "high";
        } else if (_pay_quality == "steady") {
            if (_patron.pay_profile != "high") {
                _patron.pay_profile = "steady";
            }
        }

        // Update patron satisfaction based on payment quality
        if (_pay_quality == "high") {
            _patron.satisfaction = clamp(_patron.satisfaction + 5, 0, 100);
        } else if (_pay_quality == "steady") {
            _patron.satisfaction = clamp(_patron.satisfaction + 2, 0, 100);
        } else {
            _patron.satisfaction = clamp(_patron.satisfaction - 3, 0, 100);
        }

        // Log patron research update
        log_patron_research_report(state.selected_patron_index);
    }

    state.contracting_stage = "confirm";
    // Check if patron allows flexible staffing
    if (state.selected_patron_index >= 0 && state.selected_patron_index < array_length(state.patrons)) {
        var _patron = state.patrons[state.selected_patron_index];
        if (variable_struct_exists(_patron, "flexible_staffing_allowed") && _patron.flexible_staffing_allowed) {
            // Check if we're exceeding the patron's stated max party size
            var _contract = get_selected_contract();
            if (is_struct(_contract) && variable_struct_exists(_contract, "mission") && variable_struct_exists(_contract.mission, "patron_max_party")) {
                var _patron_max = _contract.mission.patron_max_party;
                var _party_size = array_length(selected_party());

                if (_party_size > _patron_max) {
                    // Patron allows flexible staffing
                    state.flexible_staffing_approved = true;
                    state.flexible_staffing_cap = _party_size;
                    state.contracting_stage = "flexible_staffing";
                    add_log("Patron allows flexible staffing: up to " + string(_party_size) + " adventurers");
                    return;
                }
            }
        }
    }
    state.status_line = "Ready to launch " + _contract.mission.title + ".";
};

cancel_contract_flow = function() {
    state.selected_contract_index = -1;
    state.selected_mission_index = -1;
    state.selected_party_ids = [];

    if (state.selected_patron_index >= 0) {
        state.contracting_stage = "contracts";
        state.status_line = "Reviewing contracts from " + state.patrons[state.selected_patron_index].name + ".";
    } else {
        state.contracting_stage = "patrons";
        state.status_line = "Reviewing patron correspondence.";
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
                if (variable_struct_exists(_patron, "satisfaction")) {
                    if (_patron.satisfaction >= 65) {
                        state.contracts[i].mission.reward += 15;
                        state.contracts[i].expires_hour += 8;
                    } else if (_patron.satisfaction <= 35) {
                        state.contracts[i].mission.reward = max(50, state.contracts[i].mission.reward - 12);
                        state.contracts[i].expires_hour = max(state.absolute_hour + 8, state.contracts[i].expires_hour - 6);
                    }
                }
                state.contracts[i].unlocked = true;
                // Apply hazard premium for patron risk profile
                if (variable_struct_exists(_patron, "risk_profile")) {
                    var _risk_profile = _patron.risk_profile;
                    var _hazard_premium = 0;
                    if (_risk_profile == "high") {
                        _hazard_premium = 20;
                    } else if (_risk_profile == "moderate") {
                        _hazard_premium = 15;
                    } else if (_risk_profile == "low") {
                        _hazard_premium = 5;
                    }
                    state.contracts[i].mission.reward += _hazard_premium;
                    add_log("Hazard premium " + string(_hazard_premium) + "g");
                }
                // Show patron risk profile
                if (variable_struct_exists(_patron, "risk_profile")) {
                    add_log("Patron risk profile: " + _patron.risk_profile);
                }
                // Show adjusted contract reward
                add_log("Contract reward adjusted for hazard: " + string(state.contracts[i].mission.reward) + "g");
                _unlocked_any = true;
                add_log("Contract unlocked: " + state.contracts[i].mission.title + " (expires in " + format_duration_hours(max(1, state.contracts[i].expires_hour - state.absolute_hour)) + ").");
            }
            add_log("Ask: " + state.contracts[i].ask_text);
            // Check for confidential work request
            if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple") {
                if (irandom(99) < 30) { // 30% chance for confidential work
                    state.contracts[i].mission.reward += 15;
                    state.contracts[i].confidential_work = true;
                    add_log("Confidential work requested: " + state.contracts[i].mission.title);
                    add_log("Secrecy premium +15g");
                }
            }
        }
    }

    if (!_unlocked_any) {
        add_log("No new contracts from this patron right now.");
        // Add fame-based patron benefits
        if (variable_struct_exists(state, "reputation")) {
            var _fame = state.reputation;
            add_log("Fame level: " + string(_fame));

            // Apply reputation-based contract quality
            if (_fame >= 50) {
                _patron.pay_profile = "prestigious";
                _patron.satisfaction = min(100, _patron.satisfaction + 5);
                _patron.flexible_staffing_allowed = true;
                add_log("Prestige patron requests: " + _patron.name + " now offers higher-quality contracts.");
            } else if (_fame >= 30) {
                _patron.pay_profile = "established";
                _patron.satisfaction = min(100, _patron.satisfaction + 2);
                add_log("Established patron requests: " + _patron.name + " now offers better rewards.");
            } else {
                _patron.pay_profile = "standard";
            }
        }
    }

    _patron.contracts_seen = max(_patron.contracts_seen, count_patron_seen_contracts(_patron_index));
    refresh_mission_board();
};

expire_contracts = function() {
    normalize_contracts();
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

office_activity_research = function() {
    if (state.game_over) return;
    var _options = [];
    for (var i = 0; i < array_length(state.patrons); i++) {
        array_push(_options, i);
    }
    if (array_length(_options) <= 0) return;

    var _pick = _options[irandom(array_length(_options) - 1)];
    log_patron_research_report(_pick);
    state.status_line = "Patron research updated.";
};

office_activity_recruit = function() {
    if (state.game_over) return;
    if (array_length(state.adventurers) >= 20) {
        add_log("Roster is full. Expand operations before recruiting more.");
        return;
    }

    open_market_hub();
    add_log("Recruitment desk opened. Scout the market before you approach a candidate.");
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

market_representation_reason = function(_cand) {
    switch (_cand.negotiation_style) {
        case "money_first": return "Seeking representation to secure better-paying contracts and stronger signing terms.";
        case "prestige_first": return "Wants an agency banner that opens higher-status doors and more visible work.";
        case "security_first": return "Looking for steadier contract flow and safer long-term terms.";
        case "loyalty_first": return "Wants a dependable office that will actually keep them working.";
        case "hardline": return "Between sponsors and shopping aggressively for the strongest representation package.";
    }

    return "Looking for a reliable agency relationship.";
};

refresh_free_agent_market = function() {
    state.free_agents = [];
    for (var i = 0; i < 5; i++) {
        array_push(state.free_agents, build_market_candidate());
    }

    state.selected_free_agent_index = 0;
    reset_market_offer_terms();
    add_log("Free-agent market board refreshed.");
};

select_free_agent_target = function(_idx) {
    open_market_candidate(_idx);
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
    state.market_stage = "submitted";
    state.status_line = "Offer submitted to " + _fa.name + ".";
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
        variable_struct_set(_new, "id", state.next_adv_id);
        _new.adventure_rate = _deal.offer_rate;
        _new.commission_rate = _deal.offer_commission;
        _new.status = "available";
        _new.idle_days = 0;
        _new.last_contract_day = state.day;
        _new.last_idle_notice_day = 0;
        apply_client_profile_from_negotiation_style(_new);
        state.next_adv_id += 1;
        array_push(state.adventurers, _new);
        add_log(_new.name + " accepted representation terms.");
        add_log(_new.name + ": " + market_style_line(_new.negotiation_style, "accept"));
        add_log("Contract terms: " + string(_new.adventure_rate) + "g/day with " + string(round(_new.commission_rate * 100)) + "% agency commission.");

        if (_deal.candidate_index >= 0 && _deal.candidate_index < array_length(state.free_agents)) {
            array_delete(state.free_agents, _deal.candidate_index, 1);
        }
        state.pending_signing = undefined;
        state.market_stage = "hub";
        state.status_line = "Recruit signed. Back at recruitment desk.";
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
        state.market_stage = "counter";
        state.status_line = "Counteroffer received from " + _deal.candidate.name + ".";
    } else {
        add_log(_deal.candidate.name + " rejected your offer and signed elsewhere.");
        add_log(_deal.candidate.name + ": " + market_style_line(_deal.candidate.negotiation_style, "reject"));
        state.pending_signing = undefined;
        state.market_stage = "hub";
        state.status_line = "Recruitment desk open. Scout or negotiate.";
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
    variable_struct_set(_new, "id", state.next_adv_id);
    _new.adventure_rate = _deal.counter_rate;
    _new.commission_rate = _deal.counter_commission;
    _new.status = "available";
    _new.idle_days = 0;
    _new.last_contract_day = state.day;
    _new.last_idle_notice_day = 0;
    apply_client_profile_from_negotiation_style(_new);
    state.next_adv_id += 1;
    array_push(state.adventurers, _new);

    if (_deal.candidate_index >= 0 && _deal.candidate_index < array_length(state.free_agents)) {
        array_delete(state.free_agents, _deal.candidate_index, 1);
    }
    add_log(_new.name + ": " + market_style_line(_new.negotiation_style, "accept"));
    add_log(_new.name + " accepted your acceptance of the counteroffer.");
    add_log("Contract terms: " + string(_new.adventure_rate) + "g/day with " + string(round(_new.commission_rate * 100)) + "% agency commission.");

    state.pending_signing = undefined;
    state.market_stage = "hub";
    state.status_line = "Recruit signed. Back at recruitment desk.";
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
    state.market_stage = "candidate";
    state.status_line = "Reviewing candidate profile.";
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
        city_note_party_member(_adv);
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
        _member += adventurer_mission_gear_bonus(_a, _mission);
        _member += adventurer_collection_bonus(_a, _mission);
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
    if (state.debug_mission_scoring) {
        add_log("DEBUG: Mission scoring details");
        add_log("DEBUG: Party composition score: " + string(_raw_power));
        add_log("DEBUG: Outcome probability: " + string(_margin));
    }

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

    var _guard_total = 0;
    for (var g = 0; g < array_length(_party); g++) {
        _guard_total += adventurer_mission_injury_guard(_party[g]);
    }
    _injury_chance = max(0, _injury_chance - floor(_guard_total / max(1, array_length(_party))));

    if (array_length(_party) > 0 && irandom(99) < _injury_chance) {
        _injury = true;
        _injured_id = _party[irandom(array_length(_party) - 1)].id;
    }

    var _events = [];
    array_push(_events, "Mission brief: " + _mission.title);
    array_push(_events, "Difficulty " + string(_mission.difficulty) + " / Risk " + string(_mission.risk) + "%");
    array_push(_events, "Team score " + string(round(_score)) + " vs target " + string(round(_target)) + ".");
    if (_guard_total > 0) array_push(_events, "Issued gear reduced injury pressure by " + string(floor(_guard_total / max(1, array_length(_party)))) + ".");
    var _collection_total = 0;
    for (var c = 0; c < array_length(_party); c++) {
        _collection_total += adventurer_collection_bonus(_party[c], _mission);
    }
    if (_collection_total > 0) array_push(_events, "Client finds and relics added " + string(_collection_total) + " field score.");
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
    add_log("Mission report ready: " + state.last_result.mission_title + ". Click Acknowledge to file the report and clear this result.");
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
        var _client_take = _gross_fee - _cut;
        _agent_cut += _cut;
        _adventurer_payout += _client_take;

        var _m_idx = get_adv_index(_mbr.id);
        if (_m_idx >= 0) {
            state.adventurers[_m_idx].purse_gold += _client_take;
            state.adventurers[_m_idx].lifetime_earnings += _client_take;
            state.adventurers[_m_idx].last_mission_payout = _client_take;
            state.adventurers[_m_idx].contract_days_remaining = state.adventurers[_m_idx].contract_term_days;
            add_log(state.adventurers[_m_idx].name + " received " + string(_client_take) + "g and now holds " + string(state.adventurers[_m_idx].purse_gold) + "g.");

            // Update client earnings telemetry
            if (!variable_struct_exists(state, "client_earnings_telemetry")) {
                state.client_earnings_telemetry = {
                    total_earnings: 0,
                    total_clients: 0
                };
            }
            state.client_earnings_telemetry.total_earnings += _client_take;
            state.client_earnings_telemetry.total_clients += 1;
        }
    }

    var _gross_patron_pay = _result.gold_earned;
    var _net_gain = _gross_patron_pay - _adventurer_payout;
    add_gold(_net_gain);
    _result.gold_earned = _net_gain;
    state.reputation = clamp(state.reputation + _result.reputation_delta, 0, 100);
    add_log("Payout breakdown: patron " + string(_gross_patron_pay) + "g, adventurers -" + string(_adventurer_payout) + "g, agency cut " + string(_agent_cut) + "g.");
    record_patron_job_result(_active.contract_index, _result, _gross_patron_pay);
    resolve_agency_gear_after_mission(_active.party_ids, _mission, _result.outcome);

    if (_result.outcome == "success") {
        for (var g = 0; g < array_length(_active.party_ids); g++) {
            grow_adventurer_from_mission(_active.party_ids[g], _mission.difficulty);
            change_adventurer_morale(_active.party_ids[g], 4, "successful contract delivery");
            change_adventurer_trust(_active.party_ids[g], 2, "agency delivered a win");
        }
    } else if (_result.outcome == "partial") {
        for (var gp = 0; gp < array_length(_active.party_ids); gp++) {
            change_adventurer_morale(_active.party_ids[gp], 1, "contract closed with partial success");
        }
    } else {
        for (var gf = 0; gf < array_length(_active.party_ids); gf++) {
            change_adventurer_morale(_active.party_ids[gf], -5, "contract ended badly");
            change_adventurer_trust(_active.party_ids[gf], -3, "agency could not secure a good result");
        }
    }
    if (_result.outcome == "success" || _result.outcome == "partial") {
        for (var f = 0; f < array_length(_active.party_ids); f++) {
            award_adventurer_mission_find(_active.party_ids[f], _mission, _result.outcome);
        }
    }

    city_stage_party(_active);
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
    // Update injury telemetry
    if (variable_struct_exists(state, "injury_telemetry")) {
        var _mission_type = _mission.type;
        if (_mission_type == "security") {
            state.injury_telemetry.security.total += array_length(_active.party_ids);
            if (_result.injury_happened) {
                state.injury_telemetry.security.injured += 1;
            }
        } else if (_mission_type == "recovery") {
            state.injury_telemetry.recovery.total += array_length(_active.party_ids);
            if (_result.injury_happened) {
                state.injury_telemetry.recovery.injured += 1;
            }
        } else if (_mission_type == "diplomatic") {
            state.injury_telemetry.diplomatic.total += array_length(_active.party_ids);
            if (_result.injury_happened) {
                state.injury_telemetry.diplomatic.injured += 1;
            }
        }
    }
        var _inj_idx = get_adv_index(_result.injured_adv_id);
        if (_inj_idx >= 0) {
        state.adventurers[_inj_idx].status = "injured";
        change_adventurer_morale(_result.injured_adv_id, -6, "injured on contract");
        change_adventurer_trust(_result.injured_adv_id, -2, "dangerous assignment aftermath");

        // Add long-term consequences for injuries
        if (variable_struct_exists(state.adventurers[_inj_idx], "injury_tier")) {
            var _tier = state.adventurers[_inj_idx].injury_tier;
            if (_tier == "minor") {
                state.adventurers[_inj_idx].injury_tier = "moderate";
                add_log("Injury tier: moderate");
            } else if (_tier == "moderate") {
                state.adventurers[_inj_idx].injury_tier = "severe";
                add_log("Injury tier: severe");
            } else if (_tier == "severe") {
                state.adventurers[_inj_idx].injury_tier = "cursed";
                add_log("Injury tier: cursed");
                // Apply stat penalty for cursed injuries
                state.adventurers[_inj_idx].combat -= 1;
                add_log("Stat penalty: combat -1");
            }
        } else {
            state.adventurers[_inj_idx].injury_tier = "minor";
            add_log("Injury tier: minor");
        }
            state.adventurers[_inj_idx].status = "injured";
            change_adventurer_morale(_result.injured_adv_id, -6, "injured on contract");
            change_adventurer_trust(_result.injured_adv_id, -2, "dangerous assignment aftermath");
        }
    }

    // Track party member job histories for chemistry
    var _party_job_histories = [];
    for (var i = 0; i < array_length(_party); i++) {
        var _mbr = _party[i];
        if (variable_struct_exists(_mbr, "successful_missions")) {
            array_push(_party_job_histories, _mbr.successful_missions);
        } else {
            array_push(_party_job_histories, []);
        }
    }

    // Calculate shared history bonuses
    var _shared_history_bonus = 0;
    var _compatible_personality = false;
    var _clash_detected = false;
    var _mentor_protege_pairs = [];
    var _mentor_protege_bonus = 0;

    // Check for mentor/protege relationships
    for (var i = 0; i < array_length(_party); i++) {
        var _mbr1 = _party[i];
        if (variable_struct_exists(_mbr1, "mentor_id")) {
            var _mentor_idx = get_adv_index(_mbr1.mentor_id);
            if (_mentor_idx >= 0) {
                var _mentor = state.adventurers[_mentor_idx];
                // Check if mentor is in the party
                for (var j = 0; j < array_length(_party); j++) {
                    if (_party[j].id == _mbr1.mentor_id) {
                        // Found a mentor-protege pair
                        array_push(_mentor_protege_pairs, [_mbr1.id, _mbr1.mentor_id]);
                        _mentor_protege_bonus += 3;
                        break;
                    }
                }
            }
        }
    }

    if (_mentor_protege_bonus > 0) {
        _result.field_score_bonus += _mentor_protege_bonus;
        add_log("Mentor-protege synergy: +" + string(_mentor_protege_bonus) + " field score");
    }

    if (array_length(_party_job_histories) > 1) {
        // Check for shared history between pairs
        for (var i = 0; i < array_length(_party_job_histories); i++) {
            for (var j = i + 1; j < array_length(_party_job_histories); j++) {
                var _hist1 = _party_job_histories[i];
                var _hist2 = _party_job_histories[j];

                // Count shared missions
                var _shared_count = 0;
                for (var k = 0; k < array_length(_hist1); k++) {
                    for (var l = 0; l < array_length(_hist2); l++) {
                        if (_hist1[k] == _hist2[l]) {
                            _shared_count++;
                            break;
                        }
                    }
                }

                // Apply bonus based on shared history
                if (_shared_count >= 2) {
                    _shared_history_bonus += 4;
                    _compatible_personality = true;
                } else if (_shared_count == 1) {
                    _shared_history_bonus += 2;
                } else if (_shared_count == 0) {
                    // Check for personality clash
                    var _mbr1 = _party[i];
                    var _mbr2 = _party[j];
                    if (variable_struct_exists(_mbr1, "personality") && variable_struct_exists(_mbr2, "personality")) {
                        if (_mbr1.personality == "reckless" && _mbr2.personality == "cautious") {
                            _clash_detected = true;
                        } else if (_mbr1.personality == "cautious" && _mbr2.personality == "reckless") {
                            _clash_detected = true;
                        }
                    }
                }
            }
        }
    }

    // Apply shared history bonus to mission result
    if (_shared_history_bonus > 0) {
        _result.field_score_bonus += _shared_history_bonus;
        add_log("Party chemistry: Compatible personalities detected");
        add_log("Party synergy bonus: +" + string(_shared_history_bonus) + " field score");
    }

    if (_clash_detected) {
        add_log("Personality clash detected: Adventurer personalities clash");
    }

    _result.acknowledged = false;
    _result.mission_title = _mission.title;
    _result.party_names = _party_names;
    _result.completed_day = state.day;
    _result.completed_hour = state.hour;
    _result.delay_hours = _active.delay_hours;
    _result.debrief_choices_available = true;
    _result.debrief_options = [
        {
            text: "Share victory celebration with team (+2 morale, +1 trust)",
            effect: function(_adv_id) {
                change_adventurer_morale(_adv_id, 2, "debrief celebration");
                change_adventurer_trust(_adv_id, 1, "debrief celebration");
                add_log("Debrief options available: Share victory celebration with team (+2 morale, +1 trust)");
            }
        }
    ];

    add_log("Mission team returned: " + _mission.title + ". Report delivered to desk.");
    // Patron reaction consequences after debrief
    var _patron = state.patrons[_active.contract_index];
    if (variable_struct_exists(_patron, "patron_class") && _patron.patron_class == "temple") {
        // Improve patron relationship based on debrief choice
        if (variable_struct_exists(_result, "debrief_choice") && _result.debrief_choice == "Share victory celebration with team (+2 morale, +1 trust)") {
            _patron.satisfaction = clamp(_patron.satisfaction + 5, 0, 100);
            _patron.future_work_opportunities = variable_struct_exists(_patron, "future_work_opportunities") ? _patron.future_work_opportunities + 1 : 2;
            _patron.relationship_improvement = variable_struct_exists(_patron, "relationship_improvement") ? _patron.relationship_improvement + 1 : 1;
            add_log("Patron relationship improved: Lady Merrow Vale now offers more contracts and higher satisfaction.");
        }
    }
    _result.debrief_choices_available = true;
    _result.debrief_options = [
        {
            text: "Share victory celebration with team (+2 morale, +1 trust)",
            effect: function(_adv_id) {
                change_adventurer_morale(_adv_id, 2, "debrief celebration");
                change_adventurer_trust(_adv_id, 1, "debrief celebration");
                add_log("Debrief options available: Share victory celebration with team (+2 morale, +1 trust)");
            }
        },
        {
            text: "Defend team from blame (lose 1 trust, gain 1 morale)",
            effect: function(_adv_id) {
                change_adventurer_morale(_adv_id, 1, "debrief blame defense");
                change_adventurer_trust(_adv_id, -1, "debrief blame defense");
                add_log("Debrief options available: Defend team from blame (lose 1 trust, gain 1 morale)");
            }
        },
        {
            text: "Accept loss gracefully (lose 2 morale, gain 1 trust)",
            effect: function(_adv_id) {
                change_adventurer_morale(_adv_id, -2, "debrief loss acceptance");
                change_adventurer_trust(_adv_id, 1, "debrief loss acceptance");
                add_log("Debrief options available: Accept loss gracefully (lose 2 morale, gain 1 trust)");
            }
        },
        {
            text: "Dispute outcome (lose 2 trust, gain 1 morale)",
            effect: function(_adv_id) {
                change_adventurer_morale(_adv_id, 1, "debrief outcome dispute");
                change_adventurer_trust(_adv_id, -2, "debrief outcome dispute");
                add_log("Debrief options available: Dispute outcome (lose 2 trust, gain 1 morale)");
            }
        }
    ];
    array_push(state.pending_reports, _result);

    var _can_open = !is_struct(state.last_result) ||
                    !variable_struct_exists(state.last_result, "acknowledged") ||
                    state.last_result.acknowledged;

    if (_can_open) {
        open_next_report();
    }
    // Only an injured adventurer has an injury tier to move; _inj_idx exists only after an injury.
    if (!_result.injury_happened || _inj_idx < 0) return;
    if (variable_struct_exists(state.adventurers[_inj_idx], "injury_tier")) {
        var _tier = state.adventurers[_inj_idx].injury_tier;
        if (_tier == "minor") {
            state.adventurers[_inj_idx].injury_tier = "moderate";
            add_log("Injury tier: moderate");
        } else if (_tier == "moderate") {
            state.adventurers[_inj_idx].injury_tier = "serious";
            add_log("Injury tier: serious");
            // Apply stat penalty for serious injuries
            state.adventurers[_inj_idx].combat -= 1;
            add_log("Stat penalty: combat -1");
        } else if (_tier == "serious") {
            state.adventurers[_inj_idx].injury_tier = "severe";
            add_log("Injury tier: severe");
        } else if (_tier == "severe") {
            state.adventurers[_inj_idx].injury_tier = "cursed";
            add_log("Injury tier: cursed");
            // Apply stat penalty for cursed injuries
            state.adventurers[_inj_idx].combat -= 1;
            add_log("Stat penalty: combat -1");
        }
    } else {
        state.adventurers[_inj_idx].injury_tier = "minor";
        add_log("Injury tier: minor");
    }
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
    // Party members based in another city travel to the job and pay road and lodging costs.
    var _trip = city_mission_trip(_mission, _party, _round_trip);
    // Check if mission is in a different city and set local recruitment opportunity
    if (_trip.city_id != home_city_id()) {
        state.local_recruitment_opportunity = true;
        state.city_recruitment_target = _trip.city_id;
        add_log("Local recruitment opportunity in " + city_name(_trip.city_id) + ": Recruit local talent in " + city_name(_trip.city_id) + ".");
    }
    if (_trip.cost > state.gold) {
        add_log("Travel and lodging for this party cost " + string(_trip.cost) + "g; the agency cannot cover it.");
        return;
    }
    _one_way += _trip.hours;
    _round_trip += _trip.hours;

    var _party_ids = [];
    for (var i = 0; i < array_length(_party); i++) {
        var _idx = get_adv_index(_party[i].id);
        if (_idx >= 0) {
            if (state.adventurers[_idx].status != "available" || is_adventurer_committed(state.adventurers[_idx].id)) {
                add_log(state.adventurers[_idx].name + " is already committed to another mission.");
                return;
            }
            state.adventurers[_idx].status = "on_mission";
            state.adventurers[_idx].idle_days = 0;
            state.adventurers[_idx].last_contract_day = state.day;
            if (variable_struct_exists(state.adventurers[_idx], "promised_work_by_day") && state.adventurers[_idx].promised_work_by_day > 0) {
                state.adventurers[_idx].promised_work_by_day = 0;
                add_log("Promise kept: " + state.adventurers[_idx].name + " has been placed on new work.");
                change_adventurer_trust(state.adventurers[_idx].id, 1, "agency followed through on promised work");
            }
            array_push(_party_ids, _party[i].id);
            // Check for personality conflicts in the party
            var _conflict_detected = false;
            var _conflict_text = "";
            for (var i = 0; i < array_length(_party_ids); i++) {
                var _id1 = _party_ids[i];
                var _idx1 = get_adv_index(_id1);
                if (_idx1 >= 0) {
                    var _adv1 = state.adventurers[_idx1];
                    for (var j = i + 1; j < array_length(_party_ids); j++) {
                        var _id2 = _party_ids[j];
                        var _idx2 = get_adv_index(_id2);
                        if (_idx2 >= 0) {
                            var _adv2 = state.adventurers[_idx2];
                            // Simple conflict check based on personality traits
                            if (variable_struct_exists(_adv1, "negotiation_style") &&
                                variable_struct_exists(_adv2, "negotiation_style") &&
                                _adv1.negotiation_style == _adv2.negotiation_style) {
                                _conflict_detected = true;
                                _conflict_text = "Party personality conflict detected: Adventurer personalities clash";
                                break;
                            }
                        }
                    }
                }
                if (_conflict_detected) break;
            }

            if (_conflict_detected) {
                add_log(_conflict_text);
                state.party_conflict_detected = true;
                state.party_conflict_resolution = "Conflict resolution required";
            } else {
                state.party_conflict_detected = false;
                state.party_conflict_resolution = "";
            }
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
    if (_trip.cost > 0) spend_gold(_trip.cost, "Road and lodging for the party to " + city_name(_trip.city_id) + ".");

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
    state.selected_contract_index = -1;
    state.mission_review_stage = "missions";
    add_log("Mission started: " + _mission.title + " | To objective " + format_duration_hours(_one_way) + ", est. full cycle " + format_duration_hours(_round_trip) + ".");
    state.status_line = "Mission in progress: " + _mission.title;

    state.mode = MODE.PLANNING;
    state.contracting_stage = "patrons";
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
        var _idle_text = "";
        if (_a.status == "available" && variable_struct_exists(_a, "idle_days") && _a.idle_days > 0) {
            _idle_text = " | Idle " + string(_a.idle_days) + "d";
        }
        add_log(string(i + 1) + ") " + _a.name + " (" + _a.role + ") C" + string(_a.combat) + " M" + string(_a.magic) + " S" + string(_a.stealth) + " D" + string(_a.diplomacy) + " R" + string(_a.reliability) + " | Purse " + string(_a.purse_gold) + "g | " + string(_a.adventure_rate) + "g/day | Comm " + string(round(_a.commission_rate * 100)) + "% [" + string_upper(_a.status) + "]" + _idle_text);
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

add_card_gallery_button = function() {
    button_add("Open Card Gallery", "cards_open", -1);
};

rebuild_buttons = function(_reset_scroll) {
    if (is_undefined(_reset_scroll)) _reset_scroll = false;
    var _prev_page = state.button_page;
    state.buttons = [];
    state.button_page = _reset_scroll ? 0 : _prev_page;

    if (state.game_over) {
        button_add("Guild Closed - Review Logs", "noop", -1);
        return;
    }

    switch (state.mode) {
        case MODE.PLANNING:
            add_card_gallery_button();
            button_add("View Patron Requests", "goto_contracting", -1);
            button_add("View Missions", "goto_review", -1);
            button_add("Free Agent Market", "goto_market", -1);
            button_add("View Adventurers", "show_adventurers", -1);
            button_add("Start Mission", "start_mission", -1);
            button_add("End Day", "end_day", -1);
            add_office_activity_buttons();
        break;

        case MODE.BUYING:
            add_card_gallery_button();
            switch (state.market_stage) {
                case "board":
                    button_add("Back to Recruit Desk", "market_back_hub", -1);
                    button_add("Refresh Market", "market_refresh", -1);
                    for (var fa_i = 0; fa_i < array_length(state.free_agents); fa_i++) {
                        button_add("Scout " + string(fa_i + 1) + ": " + state.free_agents[fa_i].name, "market_select", fa_i);
                    }
                    if (array_length(state.free_agents) <= 0) {
                        button_add("No Free Agents Available", "noop", -1);
                    }
                break;

                case "candidate":
                    button_add("Back to Market Board", "market_back_board", -1);
                    button_add("Prepare Offer", "market_open_offer", -1);
                    button_add("Review Adventurers", "show_adventurers", -1);
                break;

                case "offer":
                    button_add("Back to Candidate", "market_back_candidate", -1);
                    button_add("Match Exact Ask", "market_match_ask", -1);
                    button_add("Submit Offer", "market_submit", -1);
                    button_add("Bonus -10", "market_bonus_add", -10);
                    button_add("Bonus +10", "market_bonus_add", 10);
                    button_add("Rate -5", "market_rate_add", -5);
                    button_add("Rate +5", "market_rate_add", 5);
                    button_add("Commission -1%", "market_comm_add", -0.01);
                    button_add("Commission +1%", "market_comm_add", 0.01);
                break;

                case "submitted":
                    button_add("Back to Recruit Desk", "market_back_hub", -1);
                    button_add("Review Adventurers", "show_adventurers", -1);
                    button_add("Wait On Offer", "noop", -1);
                break;

                case "counter":
                    button_add("Back to Candidate", "market_back_candidate", -1);
                    button_add("Accept Counter", "market_accept_counter", -1);
                    button_add("Decline Counter", "market_decline_counter", -1);
                break;

                default:
                    button_add("Back to Planning", "goto_planning", -1);
                    button_add("Review Adventurers", "show_adventurers", -1);
                    button_add("Scout Free Agents", "market_open_board", -1);
                    button_add("Refresh Market", "market_refresh", -1);
                    if (is_struct(state.pending_signing)) {
                        button_add("Resume Negotiation", "market_resume_pending", -1);
                    }
                break;
            }
        break;

        case MODE.CONTRACTING:
            add_card_gallery_button();
            switch (state.contracting_stage) {
                case "contracts":
                    button_add("Back to Patrons", "contract_back_to_patrons", -1);
                    var _contract_ids = get_patron_contract_indices(state.selected_patron_index);
                    for (var c = 0; c < array_length(_contract_ids); c++) {
                        var _contract_index = _contract_ids[c];
                        var _ct = state.contracts[_contract_index];
                        button_add("Contract " + string(c + 1) + ": " + _ct.mission.title, "select_contract", _contract_index);
                    }
                    if (array_length(_contract_ids) <= 0) {
                        button_add("No Contracts Available", "noop", -1);
                    }
                break;

                case "contract":
                    button_add("Back to Contracts", "contract_back_to_contracts", -1);
                    button_add("Accept Contract", "contract_accept", -1);
                    button_add("Decline Contract", "contract_decline", -1);
                break;

                case "party":
                    button_add("Back to Contract", "contract_back_to_contract", -1);
                    button_add("Clear Party", "clear_party", -1);
                    button_add("Done Selecting", "contract_party_done", -1);
                    for (var j = 0; j < array_length(state.adventurers); j++) {
                        var _a = state.adventurers[j];
                        if (_a.status == "available" && !is_adventurer_committed(_a.id)) {
                            var _mark = party_has(_a.id) ? "[X] " : "[ ] ";
                            button_add(_mark + "Adventurer " + string(j + 1) + ": " + _a.name, "toggle_party", _a.id);
                        }
                    }
                break;

                case "confirm":
                    button_add("Back to Party Selection", "contract_back_to_party", -1);
                    button_add("Start Adventure", "start_mission", -1);
                    button_add("Cancel Contract", "contract_cancel", -1);
                break;

                default:
                    button_add("Back to Planning", "goto_planning", -1);
                    for (var p = 0; p < array_length(state.patrons); p++) {
                        button_add("Patron " + string(p + 1) + ": " + state.patrons[p].name, "select_patron", p);
                    }
                break;
            }
        break;

        case MODE.MISSION_REVIEW:
            add_card_gallery_button();
            switch (state.mission_review_stage) {
                case "party":
                    button_add("Back to Missions", "review_back_to_missions", -1);
                    button_add("Clear Party", "clear_party", -1);
                    button_add("Done Selecting", "review_party_done", -1);
                    for (var j = 0; j < array_length(state.adventurers); j++) {
                        var _a = state.adventurers[j];
                        if (_a.status == "available" && !is_adventurer_committed(_a.id)) {
                            var _mark = party_has(_a.id) ? "[X] " : "[ ] ";
                            button_add(_mark + "Adventurer " + string(j + 1) + ": " + _a.name, "toggle_party", _a.id);
                        }
                    }
                break;

                case "confirm":
                    button_add("Back to Party Selection", "review_back_to_party", -1);
                    button_add("Start Mission", "start_mission", -1);
                    button_add("Cancel Launch", "review_back_to_missions", -1);
                break;

                default:
                    button_add("Back to Planning", "goto_planning", -1);
                    for (var i = 0; i < array_length(state.missions); i++) {
                        button_add("Mission " + string(i + 1) + ": " + state.missions[i].title, "select_mission", i);
                    }
                    if (array_length(state.missions) <= 0) {
                        button_add("No Missions Available", "noop", -1);
                    }
                break;
            }
        break;

        case MODE.MISSION_RESULT:
            add_card_gallery_button();
            if (!is_struct(state.last_result) || !variable_struct_exists(state.last_result, "acknowledged") || !state.last_result.acknowledged) {
                button_add("Acknowledge", "ack", -1);
            }
            button_add("Return to Planning", "goto_planning", -1);
            add_office_activity_buttons();
        break;

        case MODE.ADVENTURERS:
            add_card_gallery_button();
            switch (state.adventurer_view_stage) {
                case "detail":
                    button_add("Back to Adventurers", "adventurers_back_list", -1);
                    button_add("Meet Client", "adventurer_open_retention", -1);
                    button_add("Manage Kit", "adventurer_open_loadout", -1);
                    button_add("Renegotiate Terms", "adventurer_open_renegotiation", -1);
                break;

                case "loadout":
                    button_add("Back to File", "adventurer_back_detail", -1);
                    for (var gi = 0; gi < array_length(state.agency_inventory); gi++) {
                        var _gear = state.agency_inventory[gi];
                        var _adv_load = state.adventurers[state.selected_adventurer_index];
                        if (adventurer_has_issued_item(_adv_load, _gear.name)) {
                            button_add("Return " + _gear.name, "adventurer_return_gear", gi);
                        } else {
                            button_add("Issue " + _gear.name + " (" + string(_gear.stock) + ")", "adventurer_issue_gear", gi);
                        }
                    }
                break;

                case "retention":
                    button_add("Back to File", "adventurer_back_detail", -1);
                    button_add("Promise Work", "adventurer_promise_work", -1);
                    button_add("Loyalty Purse 15g", "adventurer_retention_bonus", 15);
                    button_add("Loyalty Purse 35g", "adventurer_retention_bonus", 35);
                    button_add("Renew 20d", "adventurer_offer_renewal_basic", -1);
                    button_add("Renew 30d +2g/day", "adventurer_offer_renewal_better", -1);
                    button_add("Let Them Walk", "adventurer_release_client", -1);
                break;

                case "renegotiate":
                    button_add("Back to File", "adventurer_back_detail", -1);
                    button_add("Submit Charter", "adventurer_submit_renegotiation", -1);
                    button_add("Rate -2", "adventurer_renegotiate_rate", -2);
                    button_add("Rate +2", "adventurer_renegotiate_rate", 2);
                    button_add("Commission -1%", "adventurer_renegotiate_commission", -0.01);
                    button_add("Commission +1%", "adventurer_renegotiate_commission", 0.01);
                    button_add("Term -5d", "adventurer_renegotiate_term", -5);
                    button_add("Term +5d", "adventurer_renegotiate_term", 5);
                break;

                default:
                    button_add("Back", "adventurers_back", -1);
                    for (var av = 0; av < array_length(state.adventurers); av++) {
                        button_add("Adventurer " + string(av + 1) + ": " + state.adventurers[av].name, "adventurer_select", av);
                    }
                break;
            }
        break;

        case MODE.GAME_HOUSE: build_game_house_buttons(); break;

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
            open_mission_board();
            rebuild_buttons(true);
        break;

        case "cards_open":
            card_overlay_focus_selected_context();
        break;

        case "cards_close":
            close_card_overlay();
            refresh_card_overlay();
        break;

        case "goto_contracting":
            open_contracting_patron_list();
            rebuild_buttons(true);
        break;

        case "goto_market":
            open_market_hub();
            rebuild_buttons(true);
        break;

        case "goto_game_house":
            enter_game_house();
            rebuild_buttons(true);
        break;

        case "goto_planning":
            reset_contracting_selection();
            reset_mission_review_selection();
            state.mode = MODE.PLANNING;
            state.status_line = "Back at the desk. Planning board active.";
            add_log("Back at the desk. Planning board active.");
            rebuild_buttons(true);
        break;

        case "show_adventurers":
            open_adventurer_roster(state.mode);
            rebuild_buttons(true);
        break;
        case "adventurer_select":
            open_adventurer_detail(_value);
            rebuild_buttons(true);
        break;
        case "adventurer_open_renegotiation":
            open_adventurer_renegotiation();
            rebuild_buttons(true);
        break;
        case "adventurer_open_retention":
            open_adventurer_retention_meeting();
            rebuild_buttons(true);
        break;
        case "adventurer_open_loadout":
            open_adventurer_loadout();
            rebuild_buttons(true);
        break;
        case "adventurer_back_detail":
            open_adventurer_detail(state.selected_adventurer_index);
            rebuild_buttons(true);
        break;
        case "adventurer_issue_gear":
            if (_value >= 0 && _value < array_length(state.agency_inventory)) {
                issue_agency_gear_to_adventurer(state.agency_inventory[_value].name);
            }
            rebuild_buttons();
        break;
        case "adventurer_return_gear":
            if (_value >= 0 && _value < array_length(state.agency_inventory)) {
                reclaim_agency_gear_from_adventurer(state.agency_inventory[_value].name);
            }
            rebuild_buttons();
        break;
        case "adventurer_promise_work":
            promise_adventurer_work();
            rebuild_buttons();
        break;
        case "adventurer_retention_bonus":
            pay_adventurer_retention_bonus(_value);
            rebuild_buttons();
        break;
        case "adventurer_offer_renewal_basic":
            offer_adventurer_renewal(20, 0);
            rebuild_buttons(true);
        break;
        case "adventurer_offer_renewal_better":
            offer_adventurer_renewal(30, 2);
            rebuild_buttons(true);
        break;
        case "adventurer_release_client":
            release_adventurer_client();
            rebuild_buttons(true);
        break;
        case "adventurer_renegotiate_rate":
            adjust_adventurer_renegotiation("rate", _value);
            rebuild_buttons();
        break;
        case "adventurer_renegotiate_commission":
            adjust_adventurer_renegotiation("commission", _value);
            rebuild_buttons();
        break;
        case "adventurer_renegotiate_term":
            adjust_adventurer_renegotiation("term", _value);
            rebuild_buttons();
        break;
        case "adventurer_submit_renegotiation":
            submit_adventurer_renegotiation();
            rebuild_buttons(true);
        break;
        case "adventurers_back_list":
            open_adventurer_roster(state.adventurer_view_return_mode);
            rebuild_buttons(true);
        break;
        case "adventurers_back":
            state.mode = state.adventurer_view_return_mode;
            state.adventurer_view_stage = "list";
            state.selected_adventurer_index = -1;
            state.status_line = "Returned from adventurer files.";
            rebuild_buttons(true);
        break;
        case "select_patron":
            open_patron_contracts(_value);
            rebuild_buttons();
        break;
        case "select_contract": select_contract_for_review(_value); rebuild_buttons(); break;
        case "contract_back_to_patrons":
            open_contracting_patron_list();
            rebuild_buttons();
        break;
        case "contract_back_to_contracts":
            state.contracting_stage = "contracts";
            state.selected_contract_index = -1;
            state.selected_mission_index = -1;
            state.selected_party_ids = [];
            if (state.selected_patron_index >= 0) {
                state.status_line = "Reviewing contracts from " + state.patrons[state.selected_patron_index].name + ".";
            }
            rebuild_buttons();
        break;
        case "contract_back_to_contract":
            state.contracting_stage = "contract";
            state.selected_party_ids = [];
            if (is_struct(get_selected_contract())) {
                state.status_line = "Contract review: " + get_selected_contract().mission.title;
            }
            rebuild_buttons();
        break;
        case "contract_back_to_party":
            state.contracting_stage = "party";
            if (is_struct(get_selected_contract())) {
                state.status_line = "Assign adventurers to " + get_selected_contract().mission.title + ".";
            }
            rebuild_buttons();
        break;
        case "contract_accept": advance_to_party_assignment(); rebuild_buttons(); break;
        case "contract_decline":
            add_log("Contract declined: " + (is_struct(get_selected_contract()) ? get_selected_contract().mission.title : "selection cleared") + ".");
            cancel_contract_flow();
            rebuild_buttons();
        break;
        case "contract_party_done": finish_party_assignment(); rebuild_buttons(); break;
        case "contract_cancel":
            add_log("Contract cancelled before launch.");
            cancel_contract_flow();
            rebuild_buttons();
        break;
        case "start_mission": start_mission(); break;
        case "end_day": end_day(); break;
        case "select_mission":
            select_mission(_value);
            if (state.mode == MODE.MISSION_REVIEW && state.selected_mission_index >= 0) {
                state.mission_review_stage = "party";
                state.selected_party_ids = [];
                state.status_line = "Assign adventurers to " + state.missions[state.selected_mission_index].title + ".";
            }
            rebuild_buttons();
        break;
        case "toggle_party": toggle_party(_value); rebuild_buttons(); break;
        case "clear_party": state.selected_party_ids = []; add_log("Party cleared."); rebuild_buttons(); break;
        case "review_back_to_missions":
            state.mission_review_stage = "missions";
            state.selected_party_ids = [];
            state.status_line = "Reviewing mission board.";
            rebuild_buttons();
        break;
        case "review_party_done":
            if (array_length(selected_party()) <= 0) {
                add_log("Select at least one available adventurer.");
            } else {
                state.mission_review_stage = "confirm";
                if (state.selected_mission_index >= 0) {
                    state.status_line = "Ready to launch " + state.missions[state.selected_mission_index].title + ".";
                }
            }
            rebuild_buttons();
        break;
        case "review_back_to_party":
            state.mission_review_stage = "party";
            if (state.selected_mission_index >= 0) {
                state.status_line = "Assign adventurers to " + state.missions[state.selected_mission_index].title + ".";
            }
            rebuild_buttons();
        break;
        case "market_open_board": open_market_board(); rebuild_buttons(); break;
        case "market_open_offer": open_market_offer_stage(); rebuild_buttons(); break;
        case "market_back_hub": open_market_hub(); rebuild_buttons(true); break;
        case "market_resume_pending":
            if (is_struct(state.pending_signing) &&
                variable_struct_exists(state.pending_signing, "stage") &&
                state.pending_signing.stage == "counter") {
                state.market_stage = "counter";
                state.status_line = "Counteroffer received from " + state.pending_signing.candidate.name + ".";
            } else if (is_struct(state.pending_signing)) {
                state.market_stage = "submitted";
                state.status_line = "Offer submitted to " + state.pending_signing.candidate.name + ".";
            } else {
                open_market_hub();
            }
            rebuild_buttons();
        break;
        case "market_back_board": open_market_board(); rebuild_buttons(); break;
        case "market_back_candidate":
            if (state.selected_free_agent_index >= 0) open_market_candidate(state.selected_free_agent_index);
            else open_market_board();
            rebuild_buttons();
        break;
        case "market_refresh":
            refresh_free_agent_market();
            if (state.mode == MODE.BUYING && state.market_stage != "hub") state.market_stage = "board";
            rebuild_buttons();
        break;
        case "market_select": select_free_agent_target(_value); rebuild_buttons(); break;
        case "market_bonus_add":
            state.offer_bonus = max(0, state.offer_bonus + _value);
            add_log("Offer bonus set to " + string(state.offer_bonus) + "g.");
            rebuild_buttons();
        break;
        case "market_match_ask":
            match_market_offer_to_ask();
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
        case "gh_back_lobby":
            state.game_house_view = "lobby";
            state.status_line = "Browsing game house tables.";
            rebuild_buttons();
        break;
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
        case "act_recruit": office_activity_recruit(); rebuild_buttons(true); break;
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
            add_log("Commands: HELP, CARDS, MARKET, TARGET <n>, BONUS <g>, RATE <g>, COMM <pct>, OFFER, ACCEPTCOUNTER, DECLINECOUNTER, PATRONS, PATRON <n>, MISSIONS, ADVENTURERS, START, NEXTDAY, MISSION <n>, PARTY <n>, CITIES, TRANSFER <n> <city>, CASINO, WAGER <g>, GAME <CRAPS|WHEEL|DRAGON21>, ROLL, SPIN, DEAL, HIT, STAND, RESEARCH, RECRUIT, SCOUT, COUNTER, SIMULATE, DICE, MODE <name>");
            add_log("New patron type: Temple of the Sacred Flame; Oath-based contract; Sacred service");
        break;

        case "MISSIONS":
            open_mission_board();
        break;

        case "ADVENTURERS":
            open_adventurer_roster(MODE.PLANNING);
        break;

        case "PATRONS":
            open_contracting_patron_list();
        break;

        case "CITIES":
            print_cities();
        break;

        case "TRANSFER":
            if (array_length(_parts) > 2) start_city_transfer(real("0" + string_digits(_parts[1])) - 1, real("0" + string_digits(_parts[2])), array_length(_parts) > 3 && _parts[3] == "PAY");
            else add_log("Usage: TRANSFER <adventurer 1-" + string(array_length(state.adventurers)) + "> <city number from CITIES> [PAY]");
        break;

        case "MARKET":
            open_market_hub();
        break;

        case "CARDS":
            card_overlay_focus_selected_context();
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
                open_patron_contracts(_pidx);
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
                state.mission_review_stage = "party";
                state.selected_party_ids = [];
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
                    case "BUYING": open_market_hub(); break;
                    case "SELLING": state.mode = MODE.SELLING; break;
                    case "CONTRACTING": open_contracting_patron_list(); break;
                    case "PITCHING": state.mode = MODE.PITCHING; break;
                    case "ARGUING": state.mode = MODE.ARGUING; break;
                    case "SABOTAGE": state.mode = MODE.SABOTAGE; break;
                    case "MISSION_REVIEW": open_mission_board(); break;
                    case "MISSION_RESULT": state.mode = MODE.MISSION_RESULT; break;
                    case "GAME_HOUSE": state.mode = MODE.GAME_HOUSE; state.game_house_view = "lobby"; break;
                    case "ADVENTURERS": open_adventurer_roster(MODE.PLANNING); break;
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

get_adventurer_location_text = function(_a) {
    var _city_id = adventurer_city_id(_a);
    if (_city_id == -1) {
        return "On the road";
    } else {
        var _city_name = city_name(_city_id);
        var _traveling_to = "";
        if (variable_struct_exists(_a, "traveling_to_city_id")) {
            var _dest_id = _a.traveling_to_city_id;
            if (_dest_id != -1) {
                _traveling_to = ", traveling to " + city_name(_dest_id);
            }
        }
        return "Based in " + _city_name + _traveling_to;
    }
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
// Automated test runs freeze the clock and advance time explicitly with NEXTDAY, so a run
// depends only on its inputs. Normal play keeps the live one-hour-per-8-seconds pulse.
if (string_length(environment_get_variable("AA_STORM_SEED")) > 0) {
    state.realtime_hour_interval_steps = 0;
} else {
    state.realtime_hour_interval_steps = max(60, game_get_speed(gamespeed_fps) * 8);
}
state.realtime_step_accum = 0;
state.splash = init_splash_screen();

load_world_content_xml();
state.agency_inventory = default_agency_inventory();
state.adventurers = init_adventurers();
var _mission_templates = init_missions();
state.patrons = init_patrons();
state.contracts = init_contracts(state.patrons, _mission_templates);
ensure_city_fields();
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
add_log("Agency stores stocked with loadout gear and consumables.");
add_log("Game House available: Street Craps, Wyrm Wheel, and Dragon 21.");
add_log("Type HELP for commands or use quick actions.");
add_log("Mission durations and global world pulses run over time in every mode.");
add_log("Dwarven Warhammer; Dwarven Battleaxe; Dwarven Shield.");

rebuild_buttons(true);

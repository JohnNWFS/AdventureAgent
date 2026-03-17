/// Polished UI shell + mission panels + hybrid console
draw_set_font(fnt_ui_console);
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

var _ui_font = asset_get_index("fnt_ui_console");
if (_ui_font != -1) draw_set_font(_ui_font);

var _pad = layout.pad;
var _header_h = layout.header_h;
var _console_h = layout.console_h;
var _left_w = layout.left_w;
var _right_w = layout.right_w;

var _content_y1 = _header_h + _pad;
var _content_y2 = _gh - _console_h - _pad;

var _left_x1 = _pad;
var _left_x2 = _left_x1 + _left_w;

var _right_x2 = _gw - _pad;
var _right_x1 = _right_x2 - _right_w;

var _center_x1 = _left_x2 + _pad;
var _center_x2 = _right_x1 - _pad;

var _console_x1 = _pad;
var _action_w = 220;
var _console_x2 = _gw - _pad - _action_w;
var _console_y1 = _gh - _console_h;
var _console_y2 = _gh - _pad;
var _action_x1 = _console_x2 + 8;
var _action_x2 = _gw - _pad - 8;
var _action_y1 = _console_y1;
var _action_y2 = _console_y2;

// Backdrop
var _bg_top = make_color_rgb(17, 20, 29);
var _bg_bot = make_color_rgb(9, 11, 16);
draw_rectangle_color(0, 0, _gw, _gh, _bg_top, _bg_top, _bg_bot, _bg_bot, false);

// Utility panel function
var draw_panel = function(_x1, _y1, _x2, _y2, _title, _c1, _c2) {
    draw_rectangle_color(_x1, _y1, _x2, _y2, _c1, _c1, _c2, _c2, false);
    draw_set_color(make_color_rgb(78, 93, 120));
    draw_rectangle(_x1, _y1, _x2, _y2, true);

    draw_set_color(make_color_rgb(36, 45, 63));
    draw_rectangle(_x1 + 1, _y1 + 1, _x2 - 1, _y1 + 24, false);

    draw_set_color(c_white);
    draw_text(_x1 + 8, _y1 + 5, _title);
};

// Header
draw_panel(0, 0, _gw, _header_h, "Guild Agent - Office Command", make_color_rgb(25, 33, 50), make_color_rgb(19, 25, 38));
draw_set_color(make_color_rgb(220, 230, 245));
draw_text(12, 26,
    "Mode: " + mode_to_string(state.mode) +
    "    Y" + string(state.year) +
    " M" + string(state.month) +
    " D" + string(state.day) +
    " " + format_hh00(state.hour) +
    "    " + state.season);
draw_set_halign(fa_right);
draw_text(_gw - 14, 26, state.status_line);
draw_set_halign(fa_left);

// Side panels
draw_panel(_left_x1, _content_y1, _left_x2, _content_y2, "Guild Ledger", make_color_rgb(24, 31, 44), make_color_rgb(19, 24, 35));
draw_panel(_right_x1, _content_y1, _right_x2, _content_y2, "World & Contracts", make_color_rgb(24, 31, 44), make_color_rgb(19, 24, 35));

// Center stage
draw_panel(_center_x1, _content_y1, _center_x2, _content_y2, "Center Stage - Office Desk", make_color_rgb(27, 35, 50), make_color_rgb(20, 26, 39));

// Center stage visual dressing
draw_set_color(make_color_rgb(45, 58, 82));
draw_rectangle(_center_x1 + 24, _content_y2 - 120, _center_x2 - 24, _content_y2 - 48, false);
draw_set_color(make_color_rgb(72, 90, 120));
draw_rectangle(_center_x1 + 24, _content_y2 - 120, _center_x2 - 24, _content_y2 - 48, true);

draw_set_color(c_white);
draw_text(_center_x1 + 30, _content_y1 + 36, "Desk / Agent View");
draw_text(_center_x1 + 30, _content_y1 + 58, "Visitors and letters appear here.");
draw_text(_center_x1 + 30, _content_y2 - 92, "Desk placeholder");

var _has_selected_mission = (state.selected_mission_index >= 0 && state.selected_mission_index < array_length(state.missions));

if (state.mode == MODE.BUYING) {
    draw_text(_center_x1 + 30, _content_y1 + 100, "Free-Agent Market");
    if (array_length(state.free_agents) > 0 && state.selected_free_agent_index >= 0) {
        var _fa = state.free_agents[state.selected_free_agent_index];
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            _fa.name + " (" + _fa.role + ") | Age " + string(_fa.age) + " | Profile " + string(_fa.profile_score) +
            " | Rival pressure " + string(_fa.rival_pressure) + " | Style " + string_upper(_fa.negotiation_style),
            18, _center_x2 - _center_x1 - 60);
        draw_text_ext(_center_x1 + 30, _content_y1 + 154,
            "Asks: bonus " + string(_fa.ask_bonus) + "g, rate " + string(_fa.ask_rate) + "g/day, max commission " + string(round(_fa.min_commission * 100)) + "%.",
            18, _center_x2 - _center_x1 - 60);
        draw_text_ext(_center_x1 + 30, _content_y1 + 186,
            "Your offer: bonus " + string(state.offer_bonus) + "g, rate adj " + string(state.offer_rate_delta) + "g/day, commission " + string(round(state.offer_commission * 100)) + "%.",
            18, _center_x2 - _center_x1 - 60);
        draw_text_ext(_center_x1 + 30, _content_y1 + 202,
            "Read: " + _fa.style_blurb,
            18, _center_x2 - _center_x1 - 60);
    } else {
        draw_text_ext(_center_x1 + 30, _content_y1 + 122, "No free agents listed. Refresh market to source candidates.", 18, _center_x2 - _center_x1 - 60);
    }
    if (is_struct(state.pending_signing)) {
        if (variable_struct_exists(state.pending_signing, "stage") && state.pending_signing.stage == "counter") {
            draw_text_ext(_center_x1 + 30, _content_y1 + 218,
                "Counteroffer: bonus " + string(state.pending_signing.counter_bonus) + "g, rate " + string(state.pending_signing.counter_rate) + "g/day, commission " + string(round(state.pending_signing.counter_commission * 100)) + "%. Deadline " + format_duration_hours(max(0, state.pending_signing.counter_deadline - state.absolute_hour)) + ".",
                18, _center_x2 - _center_x1 - 60);
        } else {
            draw_text_ext(_center_x1 + 30, _content_y1 + 218,
                "Pending decision for " + state.pending_signing.candidate.name + " (ETA " + format_duration_hours(max(0, state.pending_signing.due_hour - state.absolute_hour)) + ").",
                18, _center_x2 - _center_x1 - 60);
        }
    }
} else if (state.mode == MODE.GAME_HOUSE) {
    draw_text(_center_x1 + 30, _content_y1 + 100, "Gilded Griffin Game House");
    if (state.game_house_view == "lobby") {
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            "Pick a table to sit down. While you are here, missions keep moving and rivals keep negotiating in the background.",
            18, _center_x2 - _center_x1 - 60);
        draw_text(_center_x1 + 30, _content_y1 + 170, "Available tables");
        draw_text(_center_x1 + 30, _content_y1 + 194, "1) Street Craps");
        draw_text(_center_x1 + 30, _content_y1 + 216, "2) Wyrm Wheel");
        draw_text(_center_x1 + 30, _content_y1 + 238, "3) Dragon 21");
        draw_text(_center_x1 + 30, _content_y1 + 272, "Current default wager: " + string(state.game_house_wager) + "g");
    } else {
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            "The house is loud, smoky, and expensive. Every move burns time while missions, patrons, and rivals continue to evolve.",
            18, _center_x2 - _center_x1 - 60);
        draw_text(_center_x1 + 30, _content_y1 + 170, "Table: " + state.game_house_game + "    Wager: " + string(state.game_house_wager) + "g");

        if (state.game_house_game == "CRAPS") {
            var _cr_phase = (state.game_house.craps_phase == "idle") ? "Come-out" : ("Point " + string(state.game_house.craps_point));
            draw_text(_center_x1 + 30, _content_y1 + 198, "Street Craps");
            draw_text(_center_x1 + 30, _content_y1 + 220, "Phase: " + _cr_phase);
            draw_text(_center_x1 + 30, _content_y1 + 242, "Last roll: " + string(state.game_house.craps_last_roll));
            draw_text_ext(_center_x1 + 30, _content_y1 + 266, "Natural (7/11) wins on come-out. 2/3/12 loses. Point repeats to win; 7 before point loses.", 18, _center_x2 - _center_x1 - 60);
        } else if (state.game_house_game == "WHEEL") {
            draw_text(_center_x1 + 30, _content_y1 + 198, "Wyrm Wheel");
            draw_text(_center_x1 + 30, _content_y1 + 220, "Current bet: " + state.game_house.wheel_bet);
            draw_text(_center_x1 + 30, _content_y1 + 242, "Last spin: " + string(state.game_house.wheel_last_number) + " (" + state.game_house.wheel_last_color + ")");
            draw_text_ext(_center_x1 + 30, _content_y1 + 266, "Color/parity bets pay 1:1. Dozens (1-12, 13-24, 25-36) pay 2:1.", 18, _center_x2 - _center_x1 - 60);
        } else {
            var _pt = card_hand_total(state.game_house.cards_player);
            var _dt = card_hand_total(state.game_house.cards_dealer);
            draw_text(_center_x1 + 30, _content_y1 + 198, "Dragon 21");
            draw_text(_center_x1 + 30, _content_y1 + 220, "Player: " + card_hand_text(state.game_house.cards_player) + " (" + string(_pt) + ")");
            draw_text(_center_x1 + 30, _content_y1 + 242, "Dealer: " + card_hand_text(state.game_house.cards_dealer) + " (" + string(_dt) + ")");
            if (state.game_house.cards_in_round) {
                draw_text(_center_x1 + 30, _content_y1 + 264, "Round active: choose HIT or STAND.");
            } else {
                draw_text(_center_x1 + 30, _content_y1 + 264, "Round inactive: deal a new hand.");
            }
            if (state.game_house.cards_last_outcome != "") {
                draw_text(_center_x1 + 30, _content_y1 + 286, "Last outcome: " + state.game_house.cards_last_outcome);
            }
        }
    }
} else {
    draw_text(_center_x1 + 30, _content_y1 + 100, "Selected Mission");
    if (_has_selected_mission) {
        var _mission = state.missions[state.selected_mission_index];
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            _mission.title + " (" + _mission.type + ") | Patron " + _mission.patron_name +
            " | Diff " + string(_mission.difficulty) + " | Reward " + string(_mission.reward) + "g" +
            " | ETA " + format_duration_hours(_mission.duration_hours) + " | Expires in " + format_duration_hours(max(0, _mission.expires_hour - state.absolute_hour)),
            18, _center_x2 - _center_x1 - 60);
        draw_text_ext(_center_x1 + 30, _content_y1 + 156, _mission.description, 18, _center_x2 - _center_x1 - 60);
    } else {
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            "No mission selected yet. Open Patron Requests, read an ask, then review unlocked contracts.",
            18, _center_x2 - _center_x1 - 60);
    }
}

if (state.show_intro) {
    var _intro_x1 = _center_x1 + 24;
    var _intro_x2 = _center_x2 - 24;
    var _intro_y1 = _content_y1 + 92;
    var _intro_y2 = _content_y1 + 246;

    draw_rectangle_color(_intro_x1, _intro_y1, _intro_x2, _intro_y2,
        make_color_rgb(38, 52, 78), make_color_rgb(38, 52, 78), make_color_rgb(27, 38, 60), make_color_rgb(27, 38, 60), false);
    draw_set_color(make_color_rgb(110, 132, 170));
    draw_rectangle(_intro_x1, _intro_y1, _intro_x2, _intro_y2, true);

    draw_set_color(make_color_rgb(232, 240, 252));
    draw_text(_intro_x1 + 12, _intro_y1 + 10, "Welcome, Agent.");
    draw_text_ext(_intro_x1 + 12, _intro_y1 + 34,
        "You have inherited your late uncle's nearly failing adventurer agency. Only five clients remain on the roster. Good luck restoring the business to the glory it once held.\n\nStart here: open Patron Requests, read a patron ask, then choose a contract and assign a party.",
        18, _intro_x2 - _intro_x1 - 24);
}

// Selected Party — positioned below intro box bottom (_content_y1 + 246)
var _party = selected_party();
if (state.mode != MODE.BUYING && state.mode != MODE.GAME_HOUSE) {
    var _party_cap = _has_selected_mission ? state.missions[state.selected_mission_index].patron_max_party : 3;
    var _party_label = _has_selected_mission
        ? "Selected Party (Client budget supports up to " + string(_party_cap) + ")"
        : "Selected Party (select a contract to confirm party size terms)";
    draw_text(_center_x1 + 30, _content_y1 + 258, _party_label);
    if (array_length(_party) == 0) {
        draw_text(_center_x1 + 30, _content_y1 + 280, "- none -");
    } else {
        for (var p = 0; p < array_length(_party); p++) {
            draw_text(_center_x1 + 30, _content_y1 + 280 + (p * 20), string(p + 1) + ") " + _party[p].name + " (" + _party[p].role + ")");
        }
    }
}

if (state.mode == MODE.MISSION_RESULT && is_struct(state.last_result)) {
    draw_set_color(make_color_rgb(232, 240, 255));
    draw_text(_center_x1 + 30, _content_y2 - 146,
        "Latest Result: " + state.last_result.mission_title + " -> " + state.last_result.outcome_text +
        " | Gold +" + string(state.last_result.gold_earned) +
        " | Rep " + string(state.last_result.reputation_delta));
}

if (state.game_over) {
    draw_rectangle_color(_center_x1 + 60, _content_y1 + 160, _center_x2 - 60, _content_y1 + 250,
        make_color_rgb(80, 24, 24), make_color_rgb(80, 24, 24), make_color_rgb(54, 18, 18), make_color_rgb(54, 18, 18), false);
    draw_set_color(make_color_rgb(190, 80, 80));
    draw_rectangle(_center_x1 + 60, _content_y1 + 160, _center_x2 - 60, _content_y1 + 250, true);
    draw_set_color(c_white);
    draw_text(_center_x1 + 76, _content_y1 + 174, "Guild Closed");
    draw_text_ext(_center_x1 + 76, _content_y1 + 198, state.game_over_reason, 18, (_center_x2 - _center_x1) - 152);
}

// Left stats
var _injured = 0;
var _on_mission = 0;
var _available = 0;
var _unavailable = 0;
var _retired = 0;
for (var i = 0; i < array_length(state.adventurers); i++) {
    if (state.adventurers[i].status == "injured") _injured += 1;
    if (state.adventurers[i].status == "on_mission") _on_mission += 1;
    if (state.adventurers[i].status == "available") _available += 1;
    if (state.adventurers[i].status == "unavailable") _unavailable += 1;
    if (state.adventurers[i].status == "retired") _retired += 1;
}

draw_set_color(c_white);
draw_text(_left_x1 + 12, _content_y1 + 34, "Gold on hand: " + string(state.gold) + "g");
draw_text(_left_x1 + 12, _content_y1 + 56, "Gold owed: " + string(state.gold_owed) + "g");
draw_text(_left_x1 + 12, _content_y1 + 78, "Reputation: " + string(state.reputation));
draw_text(_left_x1 + 12, _content_y1 + 100, "Available adventurers: " + string(_available));
draw_text(_left_x1 + 12, _content_y1 + 122, "On mission: " + string(_on_mission));
draw_text(_left_x1 + 12, _content_y1 + 144, "Unavailable (rivals): " + string(_unavailable));
draw_text(_left_x1 + 12, _content_y1 + 166, "Injured: " + string(_injured));
draw_text(_left_x1 + 12, _content_y1 + 188, "Retired: " + string(_retired));

// Right world panel
draw_text(_right_x1 + 12, _content_y1 + 34, "Clock: Y" + string(state.year) + " M" + string(state.month) + " D" + string(state.day) + " " + format_hh00(state.hour));
draw_text(_right_x1 + 12, _content_y1 + 56, "Season: " + state.season);
var _pending_patron_asks = 0;
for (var c = 0; c < array_length(state.contracts); c++) {
    var _ct = state.contracts[c];
    if (!_ct.unlocked && !_ct.accepted && !_ct.expired && state.absolute_hour < _ct.expires_hour) {
        _pending_patron_asks += 1;
    }
}

draw_text(_right_x1 + 12, _content_y1 + 78, "Unlocked contracts: " + string(array_length(state.missions)));
draw_text(_right_x1 + 12, _content_y1 + 100, "Patron asks waiting: " + string(_pending_patron_asks));
draw_text(_right_x1 + 12, _content_y1 + 122, "Active missions: " + string(array_length(state.active_missions)));

var _right_y = _content_y1 + 146;
for (var m = 0; m < min(3, array_length(state.active_missions)); m++) {
    var _a = state.active_missions[m];
    var _am = _a.mission;
    var _eta = max(0, _a.due_hour - state.absolute_hour);
    draw_text_ext(_right_x1 + 12, _right_y,
        "- " + _am.title + " (ETA " + format_duration_hours(_eta) + ")",
        18, _right_w - 24);
    _right_y += 34;
}

draw_text_ext(_right_x1 + 12, _content_y2 - 74, state.rival_activity, 18, _right_w - 24);

// Console
draw_panel(_console_x1, _console_y1, _console_x2, _console_y2, "Operations Console", make_color_rgb(21, 27, 39), make_color_rgb(15, 19, 29));

var log_category_style = function(_category) {
    switch (_category) {
        case "mission": return { color: make_color_rgb(255, 255, 255), alpha: 0.13 };
        case "patron": return { color: make_color_rgb(232, 242, 255), alpha: 0.11 };
        case "market": return { color: make_color_rgb(228, 255, 240), alpha: 0.11 };
        case "finance": return { color: make_color_rgb(255, 245, 212), alpha: 0.12 };
        case "rival": return { color: make_color_rgb(255, 225, 225), alpha: 0.12 };
        case "roster": return { color: make_color_rgb(239, 232, 255), alpha: 0.10 };
        case "game": return { color: make_color_rgb(225, 245, 245), alpha: 0.10 };
        default: return { color: make_color_rgb(255, 255, 255), alpha: 0.06 };
    }
};

var _log_top = _console_y1 + 30;
var _log_bottom = _console_y2 - 54;
var _line_h = 18;
var _visible_lines = max(1, floor((_log_bottom - _log_top) / _line_h));
var _max_scroll = max(0, array_length(state.logs) - _visible_lines);
state.log_scroll = clamp(state.log_scroll, 0, _max_scroll);

var _start = max(0, array_length(state.logs) - _visible_lines - state.log_scroll);
var _end = min(array_length(state.logs), _start + _visible_lines);
var _ly = _log_top;
for (var _line_index = _start; _line_index < _end; _line_index++) {
    var _entry = state.logs[_line_index];
    var _entry_text = is_struct(_entry) ? _entry.text : string(_entry);
    var _entry_category = is_struct(_entry) && variable_struct_exists(_entry, "category") ? _entry.category : "general";
    var _style = log_category_style(_entry_category);
    draw_set_alpha(_style.alpha);
    draw_set_color(_style.color);
    draw_rectangle(_console_x1 + 10, _ly - 1, _console_x2 - 10, _ly + _line_h - 1, false);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(220, 232, 245));
    draw_text(_console_x1 + 12, _ly, _entry_text);
    _ly += _line_h;
}

if (_max_scroll > 0) {
    draw_set_halign(fa_right);
    draw_set_color(make_color_rgb(165, 185, 212));
    draw_text(_console_x2 - 14, _console_y1 + 6, "Scroll: wheel / PgUp PgDn (" + string(state.log_scroll) + "/" + string(_max_scroll) + ")");
    draw_set_halign(fa_left);
}

// Input line
draw_rectangle_color(_console_x1 + 10, _console_y2 - 34, _console_x2 - 10, _console_y2 - 8,
    make_color_rgb(29, 36, 51), make_color_rgb(29, 36, 51), make_color_rgb(20, 25, 36), make_color_rgb(20, 25, 36), false);
draw_set_color(make_color_rgb(112, 132, 160));
draw_rectangle(_console_x1 + 10, _console_y2 - 34, _console_x2 - 10, _console_y2 - 8, true);
draw_set_color(c_white);
draw_text(_console_x1 + 16, _console_y2 - 28, "> " + state.input_line + "_");

// Action rail
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
draw_rectangle_color(_action_x1 - 4, _action_y1, _action_x2 + 4, _action_y2,
    make_color_rgb(21, 27, 39), make_color_rgb(21, 27, 39), make_color_rgb(15, 19, 29), make_color_rgb(15, 19, 29), false);
draw_set_color(make_color_rgb(78, 93, 120));
draw_rectangle(_action_x1 - 4, _action_y1, _action_x2 + 4, _action_y2, true);
draw_set_color(make_color_rgb(36, 45, 63));
draw_rectangle(_action_x1 - 3, _action_y1 + 1, _action_x2 + 3, _action_y1 + 24, false);
draw_set_color(c_white);
draw_text(_action_x1 + 6, _action_y1 + 5, "Action Wheel");

if (state.button_nav_prev.x2 > state.button_nav_prev.x1) {
    var _prev_hover = point_in_rectangle(_mx, _my, state.button_nav_prev.x1, state.button_nav_prev.y1, state.button_nav_prev.x2, state.button_nav_prev.y2);
    var _pc1 = _prev_hover ? make_color_rgb(62, 88, 118) : make_color_rgb(42, 54, 74);
    var _pc2 = _prev_hover ? make_color_rgb(45, 66, 92) : make_color_rgb(30, 40, 56);
    draw_rectangle_color(state.button_nav_prev.x1, state.button_nav_prev.y1, state.button_nav_prev.x2, state.button_nav_prev.y2, _pc1, _pc1, _pc2, _pc2, false);
    draw_set_color(make_color_rgb(130, 153, 183));
    draw_rectangle(state.button_nav_prev.x1, state.button_nav_prev.y1, state.button_nav_prev.x2, state.button_nav_prev.y2, true);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text((state.button_nav_prev.x1 + state.button_nav_prev.x2) * 0.5, state.button_nav_prev.y1 + 3, "^");
}

if (state.button_nav_next.x2 > state.button_nav_next.x1) {
    var _next_hover = point_in_rectangle(_mx, _my, state.button_nav_next.x1, state.button_nav_next.y1, state.button_nav_next.x2, state.button_nav_next.y2);
    var _pc1 = _next_hover ? make_color_rgb(62, 88, 118) : make_color_rgb(42, 54, 74);
    var _pc2 = _next_hover ? make_color_rgb(45, 66, 92) : make_color_rgb(30, 40, 56);
    draw_rectangle_color(state.button_nav_next.x1, state.button_nav_next.y1, state.button_nav_next.x2, state.button_nav_next.y2, _pc1, _pc1, _pc2, _pc2, false);
    draw_set_color(make_color_rgb(130, 153, 183));
    draw_rectangle(state.button_nav_next.x1, state.button_nav_next.y1, state.button_nav_next.x2, state.button_nav_next.y2, true);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text((state.button_nav_next.x1 + state.button_nav_next.x2) * 0.5, state.button_nav_next.y1 + 3, "v");
}

for (var b = 0; b < array_length(state.buttons); b++) {
    var _btn = state.buttons[b];
    if (_btn.x2 <= _btn.x1) continue;
    var _hover = point_in_rectangle(_mx, _my, _btn.x1, _btn.y1, _btn.x2, _btn.y2);

    var _c1 = _hover ? make_color_rgb(56, 96, 84) : make_color_rgb(45, 55, 74);
    var _c2 = _hover ? make_color_rgb(41, 74, 66) : make_color_rgb(30, 38, 53);
    draw_rectangle_color(_btn.x1, _btn.y1, _btn.x2, _btn.y2, _c1, _c1, _c2, _c2, false);
    draw_set_color(make_color_rgb(130, 153, 183));
    draw_rectangle(_btn.x1, _btn.y1, _btn.x2, _btn.y2, true);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_text_ext(_btn.x1 + 6, _btn.y1 + 5, _btn.label, 16, _btn.x2 - _btn.x1 - 10);
}
draw_set_halign(fa_left);






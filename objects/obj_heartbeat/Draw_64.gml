/// Polished UI shell + mission panels + hybrid console
draw_set_font(fnt_ui_console);
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

var _ui_font = asset_get_index("fnt_ui_console");
if (_ui_font != -1) draw_set_font(_ui_font);

if (is_struct(state.splash) && state.splash.active) {
    var _title = state.splash.title;
    var _subtitle = state.splash.subtitle;
    var _title_len = string_length(_title);
    var _subtitle_len = string_length(_subtitle);
    var _progress = state.splash.progress;
    var _title_reveal = clamp(floor(_progress), 0, _title_len);
    var _subtitle_reveal = clamp(floor(_progress - _title_len - 8), 0, _subtitle_len);
    var _title_text = splash_reveal_text(_title, _title_reveal);
    var _subtitle_text = splash_reveal_text(_subtitle, _subtitle_reveal);
    var _title_scale = 3.1;
    var _subtitle_scale = 1.35;
    var _title_x = 92;
    var _title_y = floor(_gh * 0.35);
    var _subtitle_x = 110;
    var _subtitle_y = floor(_gh * 0.52);
    var _ink = make_color_rgb(236, 240, 247);
    var _parchment = make_color_rgb(220, 211, 188);
    var _lead = make_color_rgb(255, 233, 162);
    var _spark = make_color_rgb(140, 231, 255);
    var _spark_hot = make_color_rgb(255, 250, 214);
    var _pulse = 0.5 + 0.5 * sin(current_time / 180);
    var _drawing = !splash_is_finished();
    var _quill_exit = state.splash.quill_exit;

    draw_rectangle_color(0, 0, _gw, _gh,
        make_color_rgb(12, 16, 24), make_color_rgb(18, 24, 34), make_color_rgb(8, 10, 16), make_color_rgb(8, 10, 16), false);

    draw_set_alpha(0.06);
    draw_set_color(_parchment);
    draw_rectangle(54, 54, _gw - 54, _gh - 54, false);
    draw_set_alpha(1);

    draw_set_alpha(0.08);
    draw_set_color(make_color_rgb(255, 255, 255));
    for (var _g = 0; _g < 7; _g++) {
        var _gy = 90 + (_g * 82);
        draw_line(60, _gy, _gw - 60, _gy + 10);
    }
    draw_set_alpha(1);

    draw_set_color(_ink);
    draw_text_transformed(_title_x, _title_y, _title_text, _title_scale, _title_scale, -4);
    draw_text_transformed(_subtitle_x, _subtitle_y, _subtitle_text, _subtitle_scale, _subtitle_scale, -2);

    var _pen_x = _title_x;
    var _pen_y = _title_y + 34;
    if (_title_reveal < _title_len) {
        _pen_x = _title_x + string_width(_title_text) * _title_scale;
        _pen_y = _title_y + 36;
        draw_set_alpha(0.22);
        draw_set_color(make_color_rgb(255, 255, 255));
        draw_line(_title_x, _pen_y + 6, _pen_x, _pen_y + 6);
        draw_set_alpha(1);
    } else {
        _pen_x = _subtitle_x + string_width(_subtitle_text) * _subtitle_scale;
        _pen_y = _subtitle_y + 18;
        draw_set_alpha(0.18);
        draw_set_color(make_color_rgb(255, 255, 255));
        draw_line(_subtitle_x, _pen_y + 4, _pen_x, _pen_y + 4);
        draw_set_alpha(1);
    }

    if (!_drawing) {
        _pen_x += (_quill_exit * (_gw * 0.65));
        _pen_y -= (_quill_exit * (_gh * 0.45));
    }

    var _quill_angle = -28 + (sin(current_time / 210) * 4);
    var _shaft_len = 68;
    var _shaft_x = _pen_x - 8;
    var _shaft_y = _pen_y - 4;
    var _shaft_dx = lengthdir_x(_shaft_len, _quill_angle);
    var _shaft_dy = lengthdir_y(_shaft_len, _quill_angle);
    var _feather_x = _shaft_x - _shaft_dx;
    var _feather_y = _shaft_y - _shaft_dy;

    draw_set_alpha(0.92);
    draw_set_color(make_color_rgb(230, 238, 252));
    draw_line(_shaft_x, _shaft_y, _feather_x, _feather_y);
    draw_line(_shaft_x + 1, _shaft_y, _feather_x + 1, _feather_y);
    draw_set_color(make_color_rgb(184, 202, 228));
    draw_triangle(_feather_x, _feather_y,
        _feather_x + lengthdir_x(30, _quill_angle - 108), _feather_y + lengthdir_y(30, _quill_angle - 108),
        _feather_x + lengthdir_x(24, _quill_angle + 102), _feather_y + lengthdir_y(24, _quill_angle + 102), false);
    draw_set_color(make_color_rgb(244, 226, 184));
    draw_line(_shaft_x + lengthdir_x(8, _quill_angle), _shaft_y + lengthdir_y(8, _quill_angle), _pen_x, _pen_y);
    draw_line(_shaft_x + lengthdir_x(8, _quill_angle) + 1, _shaft_y + lengthdir_y(8, _quill_angle), _pen_x + 1, _pen_y);
    draw_set_alpha(1);

    if (_drawing) {
        draw_set_alpha(0.28);
        draw_set_color(make_color_rgb(255, 255, 255));
        draw_circle(_pen_x, _pen_y, 14 + (_pulse * 5), false);
        draw_set_alpha(1);

        draw_set_color(_lead);
        draw_circle(_pen_x + sin(current_time / 90) * 2, _pen_y, 3 + _pulse, false);

        for (var _sp = 0; _sp < 10; _sp++) {
            var _t = current_time * 0.02 + (_sp * 7.13);
            var _ang = (_sp * 36) + (sin(_t) * 28);
            var _dist = 5 + ((sin(_t * 1.7) * 0.5 + 0.5) * 18);
            var _px = _pen_x + lengthdir_x(_dist, _ang);
            var _py = _pen_y + lengthdir_y(_dist * 0.75, _ang);
            var _rad = 1 + ((_sp mod 3) * 0.6);

            draw_set_alpha(0.22 + (((sin(_t * 2.3) * 0.5) + 0.5) * 0.5));
            draw_set_color((_sp mod 2 == 0) ? _spark : _spark_hot);
            draw_circle(_px, _py, _rad, false);
            draw_line(_pen_x, _pen_y, _px, _py);
        }

        draw_set_alpha(0.85);
        draw_set_color(_spark_hot);
        draw_line(_pen_x - 12, _pen_y, _pen_x + 12, _pen_y);
        draw_line(_pen_x, _pen_y - 12, _pen_x, _pen_y + 12);
        draw_line(_pen_x - 8, _pen_y - 8, _pen_x + 8, _pen_y + 8);
        draw_line(_pen_x - 8, _pen_y + 8, _pen_x + 8, _pen_y - 8);
        draw_set_alpha(1);
    }

    if (!splash_is_finished()) {
        draw_set_color(make_color_rgb(205, 215, 230));
        draw_text_transformed(94, floor(_gh * 0.76), "Click or press a key to finish the drawing", 1.15, 1.15, 0);
    } else {
        state.splash.start_button = splash_measure_start_button();
        var _btn = state.splash.start_button;
        var _hover = point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _btn.x1, _btn.y1, _btn.x2, _btn.y2);
        var _bc1 = _hover ? make_color_rgb(78, 108, 146) : make_color_rgb(46, 62, 92);
        var _bc2 = _hover ? make_color_rgb(58, 80, 118) : make_color_rgb(32, 42, 66);
        draw_rectangle_color(_btn.x1, _btn.y1, _btn.x2, _btn.y2, _bc1, _bc1, _bc2, _bc2, false);
        draw_set_color(make_color_rgb(170, 192, 224));
        draw_rectangle(_btn.x1, _btn.y1, _btn.x2, _btn.y2, true);
        draw_set_halign(fa_center);
        draw_set_color(c_white);
        draw_text((_btn.x1 + _btn.x2) * 0.5, _btn.y1 + 12, "Start");
        draw_set_halign(fa_left);

        draw_set_alpha(0.5 + (_pulse * 0.25));
        draw_set_color(make_color_rgb(238, 244, 255));
        draw_text_transformed(92, floor(_gh * 0.69), "Press Enter or click Start", 1.2, 1.2, 0);
        draw_set_alpha(1);
    }

    exit;
}

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
var _show_result_card = (state.mode == MODE.MISSION_RESULT && is_struct(state.last_result));
if (!_show_result_card) {
    draw_set_color(make_color_rgb(45, 58, 82));
    draw_rectangle(_center_x1 + 24, _content_y2 - 120, _center_x2 - 24, _content_y2 - 48, false);
    draw_set_color(make_color_rgb(72, 90, 120));
    draw_rectangle(_center_x1 + 24, _content_y2 - 120, _center_x2 - 24, _content_y2 - 48, true);
}

draw_set_color(c_white);
draw_text(_center_x1 + 30, _content_y1 + 36, "Desk / Agent View");
draw_text(_center_x1 + 30, _content_y1 + 58, "Visitors and letters appear here.");
if (!_show_result_card) {
    draw_text(_center_x1 + 30, _content_y2 - 92, "Desk placeholder");
}

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
} else if (state.mode == MODE.ADVENTURERS) {
    draw_text(_center_x1 + 30, _content_y1 + 100, "Adventurer Files");
    if (state.selected_adventurer_index >= 0 && state.selected_adventurer_index < array_length(state.adventurers)) {
        var _adv = state.adventurers[state.selected_adventurer_index];
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            _adv.name + " (" + _adv.role + ") | Age " + string(_adv.age) + " | Morale " + string(_adv.morale) + " | Trust " + string(_adv.trust),
            18, _center_x2 - _center_x1 - 60);

        if (state.adventurer_view_stage == "renegotiate") {
            draw_text_ext(_center_x1 + 30, _content_y1 + 156,
                "Renegotiation draft: " + string(state.renegotiation_rate_offer) + "g/day | Agency commission " + string(round(state.renegotiation_commission_offer * 100)) + "% | " + string(state.renegotiation_term_offer) + "-day charter.",
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 190,
                "Current terms: " + string(_adv.adventure_rate) + "g/day | Agency commission " + string(round(_adv.commission_rate * 100)) + "% | " + string(_adv.contract_term_days) + "-day charter.",
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 224,
                "Client profile: wants " + _adv.ambition + ", prefers " + _adv.risk_preference + " work, expects a contract every " + string(_adv.activity_expectation_days) + " day(s), and current negotiation annoyance is " + string(_adv.renegotiation_annoyance) + ".",
                18, _center_x2 - _center_x1 - 60);
        } else if (state.adventurer_view_stage == "loadout") {
            var _stock_text = "";
            for (var gi = 0; gi < array_length(state.agency_inventory); gi++) {
                var _item = state.agency_inventory[gi];
                _stock_text += _item.name + " x" + string(_item.stock);
                if (gi < array_length(state.agency_inventory) - 1) _stock_text += " | ";
            }
            draw_text_ext(_center_x1 + 30, _content_y1 + 156,
                "Personal kit: " + array_join_text(_adv.kit),
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 190,
                "Agency-issued gear: " + adventurer_issued_gear_text(_adv) + ".",
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 224,
                "Stores: " + _stock_text,
                18, _center_x2 - _center_x1 - 60);
        } else if (state.adventurer_view_stage == "retention") {
            var _promise_text = (_adv.promised_work_by_day > 0)
                ? ("Promise active until day " + string(_adv.promised_work_by_day) + ".")
                : "No active work promise is on the table.";
            var _warning_text = _adv.departure_warning
                ? "They are openly listening to rival banners."
                : "They are not openly shopping the market right now.";
            draw_text_ext(_center_x1 + 30, _content_y1 + 156,
                "Retention concerns: defection risk " + string(_adv.defection_risk) + " | annoyance " + string(_adv.renegotiation_annoyance) + " | " + _promise_text,
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 190,
                "Charter state: " + string(_adv.contract_days_remaining) + " day(s) remaining at " + string(_adv.adventure_rate) + "g/day. " + _warning_text,
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 224,
                "Interventions: promise near-term work, pay a loyalty purse, renew the charter, or release the client.",
                18, _center_x2 - _center_x1 - 60);
        } else {
            draw_text_ext(_center_x1 + 30, _content_y1 + 156,
                "Representation: " + _adv.representation_type + " | " + string(_adv.contract_days_remaining) + "/" + string(_adv.contract_term_days) + " day(s) remaining.",
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 190,
                "Terms: " + string(_adv.adventure_rate) + "g/day | Agency commission " + string(round(_adv.commission_rate * 100)) + "% | Priority " + _adv.ambition + ".",
                18, _center_x2 - _center_x1 - 60);
            draw_text_ext(_center_x1 + 30, _content_y1 + 224,
                "Assets: Purse " + string(_adv.purse_gold) + "g | Defection risk " + string(_adv.defection_risk) + " | Arcana " + array_join_text(_adv.found_magic) + " | Relics " + array_join_text(_adv.found_relics) + ".",
                18, _center_x2 - _center_x1 - 60);
        }
    } else {
        draw_text_ext(_center_x1 + 30, _content_y1 + 122,
            "Select an adventurer to review their contract, purse, equipment, and relationship state.",
            18, _center_x2 - _center_x1 - 60);
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
var _show_party_block = (
    (state.mode == MODE.CONTRACTING && (state.contracting_stage == "party" || state.contracting_stage == "confirm")) ||
    (state.mode == MODE.MISSION_REVIEW && (state.mission_review_stage == "party" || state.mission_review_stage == "confirm")) ||
    array_length(_party) > 0
);
if (_show_party_block) {
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
    var _awaiting_ack = !variable_struct_exists(state.last_result, "acknowledged") || !state.last_result.acknowledged;
    var _pulse = 0.5 + 0.5 * sin(current_time / 180);
    var _report_x1 = _center_x1 + 24;
    var _report_x2 = _center_x2 - 24;
    var _report_y1 = _awaiting_ack ? (_content_y2 - 194) : (_content_y2 - 134);
    var _report_y2 = _awaiting_ack ? (_content_y2 - 28) : (_content_y2 - 72);
    var _report_text_x = _report_x1 + 12;
    var _report_wrap_w = (_report_x2 - _report_x1) - 24;

    if (_awaiting_ack) {
        draw_set_alpha(0.14 + (_pulse * 0.08));
        draw_set_color(make_color_rgb(255, 255, 255));
        draw_rectangle(_report_x1, _report_y1, _report_x2, _report_y2, false);
        draw_set_alpha(1);
    }

    draw_set_color(make_color_rgb(102, 126, 168));
    draw_rectangle(_report_x1, _report_y1, _report_x2, _report_y2, true);
    draw_set_color(make_color_rgb(58, 72, 102));
    draw_rectangle(_report_x1 + 1, _report_y1 + 25, _report_x2 - 1, _report_y2 - 25, false);
    draw_set_color(make_color_rgb(232, 240, 255));
    draw_text(_report_text_x, _report_y1 + 10, "Mission Report Ready");
    var _gold_text = (state.last_result.gold_earned >= 0 ? "+" : "") + string(state.last_result.gold_earned);
    draw_text(_report_text_x, _report_y1 + 32,
        state.last_result.mission_title + " -> " + state.last_result.outcome_text +
        " | Agency Gold " + _gold_text +
        " | Rep " + string(state.last_result.reputation_delta));

    if (variable_struct_exists(state.last_result, "event_log")) {
        var _report_lines = _awaiting_ack ? min(3, array_length(state.last_result.event_log)) : min(2, array_length(state.last_result.event_log));
        for (var rl = 0; rl < _report_lines; rl++) {
            draw_text_ext(_report_text_x, _report_y1 + 54 + (rl * 20), state.last_result.event_log[rl], 18, _report_wrap_w);
        }
    }

    if (_awaiting_ack) {
        draw_set_color(make_color_rgb(255, 247, 214));
        draw_text_ext(_report_text_x, _report_y2 - 52,
            "Click Acknowledge to file this report. Rewards were already distributed.",
            18, _report_wrap_w);
    } else {
        draw_set_color(make_color_rgb(203, 218, 238));
        draw_text(_report_text_x, _report_y2 - 18, "Report filed.");
    }
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

if (state.card_overlay.open) {
    state.card_overlay.action_buttons = [];
    state.card_overlay.card_hitboxes = [];
    var _overlay_mx = device_mouse_x_to_gui(0);
    var _overlay_my = device_mouse_y_to_gui(0);

    var _overlay_pad = 30;
    var _overlay_x1 = _overlay_pad;
    var _overlay_y1 = 24;
    var _overlay_x2 = _gw - _overlay_pad;
    var _overlay_y2 = _gh - 24;
    var _header_h = 72;
    var _column_gap = 14;
    var _columns_y1 = _overlay_y1 + _header_h + 12;
    var _columns_y2 = _overlay_y2 - 16;
    var _column_count = array_length(state.card_overlay.columns);
    var _layout_column_count = max(1, _column_count);
    var _column_w = floor(((_overlay_x2 - _overlay_x1) - ((_layout_column_count - 1) * _column_gap)) / _layout_column_count);

    draw_set_alpha(0.74);
    draw_set_color(make_color_rgb(6, 8, 13));
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_rectangle_color(_overlay_x1, _overlay_y1, _overlay_x2, _overlay_y2,
        make_color_rgb(19, 23, 36), make_color_rgb(19, 23, 36), make_color_rgb(10, 13, 22), make_color_rgb(10, 13, 22), false);
    draw_set_color(make_color_rgb(101, 120, 156));
    draw_rectangle(_overlay_x1, _overlay_y1, _overlay_x2, _overlay_y2, true);
    draw_set_color(make_color_rgb(31, 39, 58));
    draw_rectangle(_overlay_x1 + 1, _overlay_y1 + 1, _overlay_x2 - 1, _overlay_y1 + _header_h, false);

    draw_set_color(make_color_rgb(238, 243, 255));
    draw_text(_overlay_x1 + 18, _overlay_y1 + 12, "Agency Card Gallery");
    draw_set_color(make_color_rgb(187, 201, 229));
    draw_text_ext(_overlay_x1 + 18, _overlay_y1 + 36,
        "Scroll inside a column to browse active dossiers. Click a card to spotlight it, or use the buttons under each card to act without leaving the desk flow.",
        18, (_overlay_x2 - _overlay_x1) - 160);

    state.card_overlay.close_button = {
        x1: _overlay_x2 - 104,
        y1: _overlay_y1 + 16,
        x2: _overlay_x2 - 18,
        y2: _overlay_y1 + 48
    };
    var _close_hover = point_in_rectangle(_overlay_mx, _overlay_my, state.card_overlay.close_button.x1, state.card_overlay.close_button.y1, state.card_overlay.close_button.x2, state.card_overlay.close_button.y2);
    draw_rectangle_color(state.card_overlay.close_button.x1, state.card_overlay.close_button.y1, state.card_overlay.close_button.x2, state.card_overlay.close_button.y2,
        _close_hover ? make_color_rgb(111, 73, 80) : make_color_rgb(73, 52, 61),
        _close_hover ? make_color_rgb(111, 73, 80) : make_color_rgb(73, 52, 61),
        _close_hover ? make_color_rgb(87, 54, 60) : make_color_rgb(50, 36, 43),
        _close_hover ? make_color_rgb(87, 54, 60) : make_color_rgb(50, 36, 43), false);
    draw_set_color(make_color_rgb(231, 212, 220));
    draw_rectangle(state.card_overlay.close_button.x1, state.card_overlay.close_button.y1, state.card_overlay.close_button.x2, state.card_overlay.close_button.y2, true);
    draw_text(state.card_overlay.close_button.x1 + 25, state.card_overlay.close_button.y1 + 8, "Close");

    var draw_card_button = function(_x1, _y1, _x2, _y2, _label, _action, _value, _mouse_x, _mouse_y) {
        var _hover_btn = point_in_rectangle(_mouse_x, _mouse_y, _x1, _y1, _x2, _y2);
        draw_rectangle_color(_x1, _y1, _x2, _y2,
            _hover_btn ? make_color_rgb(90, 125, 111) : make_color_rgb(57, 76, 72),
            _hover_btn ? make_color_rgb(90, 125, 111) : make_color_rgb(57, 76, 72),
            _hover_btn ? make_color_rgb(63, 90, 79) : make_color_rgb(37, 49, 48),
            _hover_btn ? make_color_rgb(63, 90, 79) : make_color_rgb(37, 49, 48), false);
        draw_set_color(make_color_rgb(164, 204, 191));
        draw_rectangle(_x1, _y1, _x2, _y2, true);
        draw_set_color(c_white);
        draw_text(_x1 + 8, _y1 + 5, _label);
        array_push(state.card_overlay.action_buttons, { x1: _x1, y1: _y1, x2: _x2, y2: _y2, action: _action, value: _value });
    };

    if (_column_count <= 0) {
        draw_set_color(make_color_rgb(219, 229, 245));
        draw_text(_overlay_x1 + 22, _columns_y1 + 12, "No active cards are available yet.");
    }

    for (var cc = 0; cc < _column_count; cc++) {
        var _column = state.card_overlay.columns[cc];
        var _cx1 = _overlay_x1 + (cc * (_column_w + _column_gap));
        var _cx2 = _cx1 + _column_w;
        var _cy1 = _columns_y1;
        var _cy2 = _columns_y2;
        var _column_view_y1 = _cy1 + 30;
        var _column_view_y2 = _cy2 - 10;
        var _content_cursor = 0;

        _column.x1 = _cx1;
        _column.y1 = _column_view_y1;
        _column.x2 = _cx2;
        _column.y2 = _column_view_y2;

        draw_rectangle_color(_cx1, _cy1, _cx2, _cy2,
            make_color_rgb(24, 28, 42), make_color_rgb(24, 28, 42), make_color_rgb(13, 16, 26), make_color_rgb(13, 16, 26), false);
        draw_set_color(make_color_rgb(74, 90, 121));
        draw_rectangle(_cx1, _cy1, _cx2, _cy2, true);
        draw_set_color(make_color_rgb(37, 46, 66));
        draw_rectangle(_cx1 + 1, _cy1 + 1, _cx2 - 1, _cy1 + 25, false);
        draw_set_color(make_color_rgb(241, 245, 255));
        draw_text(_cx1 + 8, _cy1 + 5, _column.title + " (" + string(array_length(_column.items)) + ")");

        if (array_length(_column.items) <= 0) {
            draw_set_color(make_color_rgb(168, 182, 208));
            draw_text_ext(_cx1 + 10, _column_view_y1 + 8, "No active dossiers in this column right now.", 18, _column_w - 20);
            _column.content_h = 0;
            continue;
        }

        for (var ci = 0; ci < array_length(_column.items); ci++) {
            var _card = _column.items[ci];
            if (!is_struct(_card)) continue;
            var _palette = card_palette(_card.type);
            var _card_h = 296;
            var _card_y1 = _column_view_y1 + _content_cursor - _column.scroll;
            var _card_y2 = _card_y1 + _card_h;
            var _card_x1 = _cx1 + 8;
            var _card_x2 = _cx2 - 8;
            var _focused = (get_focus_card_type() == _card.type && get_focus_card_id() == _card.id);

            _content_cursor += _card_h + 14;

            if (_card_y2 < _column_view_y1 || _card_y1 > _column_view_y2) {
                continue;
            }

            draw_rectangle_color(_card_x1, _card_y1, _card_x2, _card_y2, _palette.top, _palette.top, _palette.bottom, _palette.bottom, false);
            draw_set_color(_focused ? _palette.accent : _palette.border);
            draw_rectangle(_card_x1, _card_y1, _card_x2, _card_y2, true);
            draw_set_alpha(_focused ? 0.18 : 0.08);
            draw_set_color(_palette.accent);
            draw_rectangle(_card_x1 + 4, _card_y1 + 4, _card_x2 - 4, _card_y1 + 84, false);
            draw_set_alpha(1);

            array_push(state.card_overlay.card_hitboxes, { x1: _card_x1, y1: _card_y1, x2: _card_x2, y2: _card_y2, type: _card.type, id: _card.id });

            draw_set_color(_palette.accent);
            draw_text(_card_x1 + 10, _card_y1 + 10, _card.title);
            draw_set_color(make_color_rgb(229, 235, 246));
            draw_text(_card_x1 + 10, _card_y1 + 32, _card.subtitle);
            draw_set_color(make_color_rgb(212, 221, 238));
            draw_text(_card_x1 + 10, _card_y1 + 52, _card.status);

            var _art_x1 = _card_x1 + 10;
            var _art_x2 = _card_x2 - 10;
            var _art_y1 = _card_y1 + 78;
            var _art_y2 = _card_y1 + 138;
            draw_rectangle_color(_art_x1, _art_y1, _art_x2, _art_y2,
                merge_color(_palette.top, c_white, 0.20), merge_color(_palette.top, c_white, 0.20),
                merge_color(_palette.bottom, c_black, 0.10), merge_color(_palette.bottom, c_black, 0.10), false);
            draw_set_alpha(0.35);
            draw_set_color(_palette.border);
            draw_rectangle(_art_x1, _art_y1, _art_x2, _art_y2, true);
            draw_set_alpha(1);
            draw_set_color(make_color_rgb(236, 241, 251));
            draw_set_halign(fa_center);
            draw_text((_art_x1 + _art_x2) * 0.5, _art_y1 + 20, "Portrait / Illustration");
            draw_text((_art_x1 + _art_x2) * 0.5, _art_y1 + 38, "placeholder");
            draw_set_halign(fa_left);

            draw_set_color(make_color_rgb(239, 242, 249));
            draw_text_ext(_card_x1 + 10, _card_y1 + 146, _card.summary, 16, (_card_x2 - _card_x1) - 20);

            var _stats_y = _card_y1 + 194;
            for (var cs = 0; cs < min(6, array_length(_card.stats)); cs++) {
                var _stat = _card.stats[cs];
                var _sx1 = _card_x1 + 10 + ((cs mod 2) * floor((_card_x2 - _card_x1 - 26) * 0.5));
                var _sx2 = _sx1 + floor((_card_x2 - _card_x1 - 26) * 0.5);
                var _sy1 = _stats_y + (floor(cs / 2) * 24);
                draw_rectangle_color(_sx1, _sy1, _sx2, _sy1 + 20,
                    make_color_rgb(22, 26, 39), make_color_rgb(22, 26, 39), make_color_rgb(15, 18, 28), make_color_rgb(15, 18, 28), false);
                draw_set_color(make_color_rgb(95, 112, 146));
                draw_rectangle(_sx1, _sy1, _sx2, _sy1 + 20, true);
                draw_set_color(make_color_rgb(232, 238, 248));
                draw_text(_sx1 + 4, _sy1 + 3, _stat.label + ": " + _stat.value);
            }

            var _detail_y = _card_y1 + 268;
            if (array_length(_card.details) > 0) {
                draw_set_color(make_color_rgb(210, 221, 240));
                draw_text_ext(_card_x1 + 10, _detail_y, _card.details[0], 16, (_card_x2 - _card_x1) - 20);
            }

            var _button_y = _card_y2 - 48;
            var _button_w = floor(((_card_x2 - _card_x1) - 28) / max(1, array_length(_card.actions)));
            for (var ca = 0; ca < array_length(_card.actions); ca++) {
                var _act = _card.actions[ca];
                var _bx1 = _card_x1 + 10 + (ca * (_button_w + 8));
                var _bx2 = _bx1 + _button_w;
                draw_card_button(_bx1, _button_y, _bx2, _button_y + 24, _act.label, _act.action, _act.value, _overlay_mx, _overlay_my);
            }

            var _holo_w = 72;
            var _holo_x1 = ((_card_x1 + _card_x2) * 0.5) - (_holo_w * 0.5);
            var _holo_x2 = _holo_x1 + _holo_w;
            var _holo_y1 = _card_y2 - 15;
            var _holo_y2 = _holo_y1 + 10;
            draw_rectangle_color(_holo_x1, _holo_y1, _holo_x2, _holo_y2,
                make_color_rgb(121, 232, 255), make_color_rgb(255, 160, 210),
                make_color_rgb(164, 255, 226), make_color_rgb(220, 194, 255), false);
            draw_set_color(_palette.plate);
            draw_text(_holo_x1 - 4, _holo_y1 - 12, card_holo_text(_card.type, _card.id));
        }

        _column.content_h = _content_cursor;
    }
}

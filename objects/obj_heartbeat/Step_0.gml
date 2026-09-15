/// Input, commands, button clicks

if (is_struct(state.splash) && state.splash.active) {
    if (!variable_instance_exists(id, "aa_storm_run_id")) {
        aa_storm_run_id = environment_get_variable("AA_STORM_RUN_ID");
        aa_storm_startup_emitted = false;
    }

    state.splash.start_button = splash_measure_start_button();

    var _typed_during_splash = (string_length(keyboard_string) > input_buffer_prev_len);
    var _skip_draw = mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || _typed_during_splash;

    if (!splash_is_finished()) {
        state.splash.progress = min(state.splash.total_chars, state.splash.progress + 0.8);
        if (_skip_draw) {
            splash_finish_drawing();
            keyboard_string = "";
            input_buffer_prev_len = 0;
        }
    } else {
        state.splash.quill_exit = min(1, state.splash.quill_exit + 0.08);
        var _mx_splash = device_mouse_x_to_gui(0);
        var _my_splash = device_mouse_y_to_gui(0);
        var _start = state.splash.start_button;
        var _clicked_start = mouse_check_button_pressed(mb_left) && point_in_rectangle(_mx_splash, _my_splash, _start.x1, _start.y1, _start.x2, _start.y2);
        if (_clicked_start || keyboard_check_pressed(vk_enter)) {
            splash_begin_game();
            keyboard_string = "";
            input_buffer_prev_len = 0;

            // Verification channel startup message
            var _run_id = environment_get_variable("AA_STORM_RUN_ID");
            if (string_length(aa_storm_run_id) > 0 && !aa_storm_startup_emitted) {
                aa_storm_startup_emitted = true;
                var _data = {
                    "run_id": _run_id,
                    "last_command": "",
                    "day": state.day,
                    "hour": state.hour,
                    "gold": state.gold,
                    "reputation": state.reputation,
                    "mode": mode_to_string(state.mode)
                };
                show_debug_message("AA_STATE: " + json_stringify(_data));
            }
        }
    }

    exit;
}

// Pull typed changes from keyboard_string (supports key repeat + held backspace).
var _kb = keyboard_string;
var _kb_len = string_length(_kb);

if (_kb_len > input_buffer_prev_len) {
    var _added = string_copy(_kb, input_buffer_prev_len + 1, _kb_len - input_buffer_prev_len);

    // Keep only printable ASCII for this prototype console.
    var _clean = "";
    for (var _i = 1; _i <= string_length(_added); _i++) {
        var _c = string_char_at(_added, _i);
        var _o = ord(_c);
        if (_o >= 32 && _o <= 126) _clean += _c;
    }

    state.input_line += _clean;

    // Prevent runaway input length.
    if (string_length(state.input_line) > 140) {
        state.input_line = string_copy(state.input_line, 1, 140);
    }
}
else if (_kb_len < input_buffer_prev_len) {
    var _removed = input_buffer_prev_len - _kb_len;
    repeat (_removed) {
        if (string_length(state.input_line) > 0) {
            state.input_line = string_delete(state.input_line, string_length(state.input_line), 1);
        }
    }
}

input_buffer_prev_len = _kb_len;

if (keyboard_check_pressed(vk_enter)) {
    var _cmd = string_trim(state.input_line);
    if (_cmd != "") {
        add_log("> " + _cmd);
        process_command(_cmd);

        // Verification channel command message
        var _run_id = environment_get_variable("AA_STORM_RUN_ID");
        if (string_length(aa_storm_run_id) > 0 && aa_storm_startup_emitted) {
            var _data = {
                "run_id": _run_id,
                "last_command": _cmd,
                "day": state.day,
                "hour": state.hour,
                "gold": state.gold,
                "reputation": state.reputation,
                "mode": mode_to_string(state.mode)
            };
            show_debug_message("AA_STATE: " + json_stringify(_data));
        }
    }

    state.input_line = "";
    keyboard_string = "";
    input_buffer_prev_len = 0;
}

// Real-time heartbeat: one in-game hour every few real seconds.
if (!state.game_over && state.realtime_hour_interval_steps > 0) {
    state.realtime_step_accum += 1;
    if (state.realtime_step_accum >= state.realtime_hour_interval_steps) {
        state.realtime_step_accum = 0;
        advance_hours(1);
    }
}

if (state.card_overlay.open) {
    var _overlay_mx = device_mouse_x_to_gui(0);
    var _overlay_my = device_mouse_y_to_gui(0);

    if (keyboard_check_pressed(vk_escape)) {
        close_card_overlay();
        exit;
    }

    for (var oc = 0; oc < array_length(state.card_overlay.columns); oc++) {
        var _col = state.card_overlay.columns[oc];
        if (point_in_rectangle(_overlay_mx, _overlay_my, _col.x1, _col.y1, _col.x2, _col.y2)) {
            var _view_h = max(1, _col.y2 - _col.y1);
            var _max_card_scroll = max(0, _col.content_h - _view_h + 10);
            if (mouse_wheel_up()) _col.scroll = max(0, _col.scroll - 28);
            if (mouse_wheel_down()) _col.scroll = min(_max_card_scroll, _col.scroll + 28);
        }
    }

    if (mouse_check_button_pressed(mb_left)) {
        if (point_in_rectangle(_overlay_mx, _overlay_my, state.card_overlay.close_button.x1, state.card_overlay.close_button.y1, state.card_overlay.close_button.x2, state.card_overlay.close_button.y2)) {
            close_card_overlay();
            exit;
        }

        for (var ob = 0; ob < array_length(state.card_overlay.action_buttons); ob++) {
            var _action_btn = state.card_overlay.action_buttons[ob];
            if (point_in_rectangle(_overlay_mx, _overlay_my, _action_btn.x1, _action_btn.y1, _action_btn.x2, _action_btn.y2)) {
                run_card_action(_action_btn.action, _action_btn.value);
                exit;
            }
        }

        for (var oh = 0; oh < array_length(state.card_overlay.card_hitboxes); oh++) {
            var _hit = state.card_overlay.card_hitboxes[oh];
            if (point_in_rectangle(_overlay_mx, _overlay_my, _hit.x1, _hit.y1, _hit.x2, _hit.y2)) {
                set_card_overlay_focus(_hit.type, _hit.id);
                refresh_card_overlay();
                exit;
            }
        }
    }

    exit;
}

// Console log scrolling (mouse wheel + PageUp/PageDown)
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _action_w = 220;
var _action_x1 = _gw - layout.pad - _action_w + 8;
var _action_x2 = _gw - layout.pad - 8;
var _action_y1 = _gh - layout.console_h;
var _action_y2 = _gh - layout.pad;
var _mx_gui = device_mouse_x_to_gui(0);
var _my_gui = device_mouse_y_to_gui(0);
var _over_action = point_in_rectangle(_mx_gui, _my_gui, _action_x1 - 6, _action_y1 - 30, _action_x2 + 6, _action_y2 + 6);

var _visible_lines = max(1, floor((layout.console_h - 84) / 18));
var _max_scroll = max(0, array_length(state.logs) - _visible_lines);

if (!_over_action && mouse_wheel_up()) state.log_scroll = min(_max_scroll, state.log_scroll + 1);
if (!_over_action && mouse_wheel_down()) state.log_scroll = max(0, state.log_scroll - 1);
if (keyboard_check_pressed(vk_pageup)) state.log_scroll = min(_max_scroll, state.log_scroll + _visible_lines);
if (keyboard_check_pressed(vk_pagedown)) state.log_scroll = max(0, state.log_scroll - _visible_lines);
state.log_scroll = clamp(state.log_scroll, 0, _max_scroll);

// Vertical action rail layout (mobile-friendly stack), anchored at bottom-right.
var _console_x1 = layout.pad;
var _console_x2 = _gw - layout.pad - _action_w;
_action_x1 = _console_x2 + 8;
_action_x2 = _gw - layout.pad - 8;
_action_y1 = _gh - layout.console_h;
var _console_y2 = _gh - layout.pad;

var _buttons_count = array_length(state.buttons);
var _btn_h = 24;
var _btn_gap = 4;
var _slot_h = _btn_h + _btn_gap;
var _arrow_h = 22;
var _wheel_sep = 16;
var _wheel_wrap_w = max(24, _action_x2 - _action_x1 - 10);

for (var _ru = 0; _ru < _buttons_count; _ru++) {
    var _label_h = string_height_ext(state.buttons[_ru].label, _wheel_sep, _wheel_wrap_w);
    var _units = clamp(ceil((_label_h + 10) / _slot_h), 1, 3);
    state.buttons[_ru].row_units = _units;
}

var _buttons_y1 = _action_y1 + 30 + _arrow_h + 4;
var _buttons_y2 = _action_y2 - _arrow_h - 4;
var _buttons_h = max(_btn_h, _buttons_y2 - _buttons_y1);

var _max_offset = max(0, _buttons_count - 1);
state.button_page = clamp(state.button_page, 0, _max_offset);

if (keyboard_check_pressed(vk_up)) state.button_page = max(0, state.button_page - 1);
if (keyboard_check_pressed(vk_down)) state.button_page = min(_max_offset, state.button_page + 1);
if (_over_action && mouse_wheel_up()) state.button_page = max(0, state.button_page - 1);
if (_over_action && mouse_wheel_down()) state.button_page = min(_max_offset, state.button_page + 1);

var _start = state.button_page;
var _end = _start;
var _cursor_y = _buttons_y1;

for (var i = 0; i < _buttons_count; i++) {
    state.buttons[i].x1 = 0;
    state.buttons[i].y1 = 0;
    state.buttons[i].x2 = 0;
    state.buttons[i].y2 = 0;
}

for (var _idx = _start; _idx < _buttons_count; _idx++) {
    var _units_for_btn = state.buttons[_idx].row_units;
    var _btn_draw_h = (_units_for_btn * _slot_h) - _btn_gap;
    if (_idx > _start && (_cursor_y + _btn_draw_h > _buttons_y1 + _buttons_h)) break;

    var _x1 = _action_x1;
    var _y1 = _cursor_y;

    state.buttons[_idx].x1 = _x1;
    state.buttons[_idx].y1 = _y1;
    state.buttons[_idx].x2 = _action_x2;
    state.buttons[_idx].y2 = _y1 + _btn_draw_h;

    _cursor_y += (_units_for_btn * _slot_h);
    _end = _idx + 1;
}

var _has_up = (state.button_page > 0);
var _has_down = (_end < _buttons_count);

if (_has_up) {
    state.button_nav_prev.x1 = _action_x1;
    state.button_nav_prev.y1 = _action_y1 + 30;
    state.button_nav_prev.x2 = _action_x2;
    state.button_nav_prev.y2 = state.button_nav_prev.y1 + _arrow_h;
} else {
    state.button_nav_prev.x1 = 0; state.button_nav_prev.y1 = 0;
    state.button_nav_prev.x2 = 0; state.button_nav_prev.y2 = 0;
}

if (_has_down) {
    state.button_nav_next.x1 = _action_x1;
    state.button_nav_next.y1 = _action_y2 - _arrow_h - 2;
    state.button_nav_next.x2 = _action_x2;
    state.button_nav_next.y2 = state.button_nav_next.y1 + _arrow_h;
} else {
    state.button_nav_next.x1 = 0; state.button_nav_next.y1 = 0;
    state.button_nav_next.x2 = 0; state.button_nav_next.y2 = 0;
}

if (mouse_check_button_pressed(mb_left)) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    // Page controls first
    if (point_in_rectangle(_mx, _my, state.button_nav_prev.x1, state.button_nav_prev.y1, state.button_nav_prev.x2, state.button_nav_prev.y2)) {
        state.button_page = max(0, state.button_page - 1);
        exit;
    }
    if (point_in_rectangle(_mx, _my, state.button_nav_next.x1, state.button_nav_next.y1, state.button_nav_next.x2, state.button_nav_next.y2)) {
        state.button_page = min(_max_offset, state.button_page + 1);
        exit;
    }

    for (var b = _start; b < _end; b++) {
        var _btn = state.buttons[b];
        if (point_in_rectangle(_mx, _my, _btn.x1, _btn.y1, _btn.x2, _btn.y2)) {
            run_button(_btn.action, _btn.value);
            break;
        }
    }
}

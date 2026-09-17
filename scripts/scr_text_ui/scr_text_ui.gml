/// Text / keyboard driving layer.
/// Everything a mouse click can do is reachable by typing (LOOK, BUTTONS, PRESS <n>) or by keys
/// (Tab / Shift+Tab to move focus, Enter on an empty line to press, F1 = LOOK, F2-F12 = press 1-11,
/// Esc clears focus). Presses call exactly the same handlers as clicks, so game rules are unchanged.

/// Returns the numbered list of things that can be pressed on the current screen.
function text_ui_items() {
    var _items = [];
    if (state.card_overlay.open) {
        array_push(_items, { label: "Close card gallery", kind: "close", action: "", value: -1, type: "", id: -1 });
        for (var _c = 0; _c < array_length(state.card_overlay.columns); _c++) {
            var _column = state.card_overlay.columns[_c];
            for (var _i = 0; _i < array_length(_column.items); _i++) {
                var _card = _column.items[_i];
                if (!is_struct(_card)) continue;
                array_push(_items, { label: _column.title + " card: " + _card.title, kind: "card", action: "", value: -1, type: _card.type, id: _card.id });
                for (var _a = 0; _a < array_length(_card.actions); _a++) {
                    var _act = _card.actions[_a];
                    array_push(_items, { label: _card.title + " -> " + _act.label, kind: "card_action", action: _act.action, value: _act.value, type: _card.type, id: _card.id });
                }
            }
        }
    } else {
        for (var _b = 0; _b < array_length(state.buttons); _b++) {
            var _btn = state.buttons[_b];
            array_push(_items, { label: _btn.label, kind: "button", action: _btn.action, value: _btn.value, type: "", id: -1 });
        }
    }
    return _items;
}

function text_ui_focus_get() {
    if (!variable_instance_exists(id, "text_ui_focus")) text_ui_focus = -1;
    return text_ui_focus;
}

/// Presses item number _n (1-based) exactly as a mouse click would.
function text_ui_press(_n) {
    var _items = text_ui_items();
    if (_n < 1 || _n > array_length(_items)) {
        add_log("No button " + string(_n) + ". There are " + string(array_length(_items)) + ". Type BUTTONS.");
        return;
    }
    var _it = _items[_n - 1];
    add_log("Pressed [" + string(_n) + "] " + _it.label);
    text_ui_focus = -1;
    switch (_it.kind) {
        case "button":      run_button(_it.action, _it.value); break;
        case "close":       close_card_overlay(); break;
        case "card":        set_card_overlay_focus(_it.type, _it.id); refresh_card_overlay(); break;
        case "card_action": run_card_action(_it.action, _it.value); break;
    }
}

/// Finds a button by (partial, case-insensitive) label. Returns 1-based index or 0.
function text_ui_find(_text) {
    var _items = text_ui_items();
    var _needle = string_lower(string_trim(_text));
    for (var _i = 0; _i < array_length(_items); _i++) {
        if (string_lower(_items[_i].label) == _needle) return _i + 1;
    }
    for (var _j = 0; _j < array_length(_items); _j++) {
        if (string_pos(_needle, string_lower(_items[_j].label)) > 0) return _j + 1;
    }
    return 0;
}

function text_ui_list() {
    var _items = text_ui_items();
    if (array_length(_items) == 0) {
        add_log("No buttons on this screen.");
        return;
    }
    var _focus = text_ui_focus_get();
    for (var _i = 0; _i < array_length(_items); _i++) {
        add_log((_i == _focus ? "* " : "  ") + "[" + string(_i + 1) + "] " + _items[_i].label);
    }
    add_log("PRESS <n> or PRESS <label> to use one.");
}

function text_ui_look() {
    add_log("== " + (state.card_overlay.open ? "CARD GALLERY" : mode_to_string(state.mode)) + " | Day " + string(state.day)
        + " " + string(state.hour) + ":00 | Gold " + string(state.gold) + " | Rep " + string(state.reputation) + " ==");
    if (state.status_line != "") add_log(state.status_line);
    text_ui_list();
}

/// Handles text-UI console commands. Returns true when the command was handled here.
function text_ui_command(_raw) {
    var _t = string_trim(_raw);
    var _u = string_upper(_t);
    var _parts = string_split(_u, " ");
    switch (_parts[0]) {
        case "LOOK":
        case "SCREEN":
            text_ui_look();
            return true;
        case "BUTTONS":
            text_ui_list();
            return true;
        case "PRESS":
            if (array_length(_parts) < 2) { add_log("Usage: PRESS <n> or PRESS <label>"); return true; }
            var _arg = string_trim(string_delete(_t, 1, 5));
            var _n = string_digits(_arg) == _arg ? real(_arg) : text_ui_find(_arg);
            if (_n <= 0) add_log("No button matches '" + _arg + "'. Type BUTTONS.");
            else text_ui_press(_n);
            return true;
        case "HELP":
            process_command(_raw);
            add_log("Screen: LOOK, BUTTONS, PRESS <n|label>. Keys: Tab/Shift+Tab focus, Enter press, F1 look, F2-F12 press 1-11.");
            add_log("Patron payment quality tracked: high, steady, modest. See research reports.");
            return true;
    }
    return false;
}

/// Keyboard navigation. Call once per step after console typing is handled.
/// Returns a short key name when a key triggered an action (for telemetry), else "".
function text_ui_keys(_input_empty) {
    var _count = array_length(text_ui_items());
    var _focus = text_ui_focus_get();

    if (keyboard_check_pressed(vk_tab) && _count > 0) {
        if (keyboard_check(vk_shift)) _focus = (_focus <= 0) ? _count - 1 : _focus - 1;
        else _focus = (_focus + 1) mod _count;
        text_ui_focus = _focus;
        var _all = text_ui_items();
        var _label = _all[_focus].label;
        state.status_line = "Focus [" + string(_focus + 1) + "/" + string(_count) + "]: " + _label + "  (Enter to press)";
        if (!state.card_overlay.open) state.button_page = max(0, _focus - 2);
        keyboard_string = "";
        input_buffer_prev_len = 0;
        return "";
    }
    if (_focus >= _count) text_ui_focus = -1;

    if (keyboard_check_pressed(vk_escape) && !state.card_overlay.open && text_ui_focus >= 0) {
        text_ui_focus = -1;
        state.status_line = "Focus cleared.";
    }
    if (keyboard_check_pressed(vk_enter) && _input_empty && text_ui_focus >= 0) {
        text_ui_press(text_ui_focus + 1);
        return "key:enter";
    }
    if (keyboard_check_pressed(vk_f1)) {
        text_ui_look();
        return "key:f1";
    }
    var _fkeys = [vk_f2, vk_f3, vk_f4, vk_f5, vk_f6, vk_f7, vk_f8, vk_f9, vk_f10, vk_f11, vk_f12];
    for (var _k = 0; _k < array_length(_fkeys); _k++) {
        if (keyboard_check_pressed(_fkeys[_k])) {
            text_ui_press(_k + 1);
            return "key:f" + string(_k + 2);
        }
    }
    return "";
}

/// True when the focused item is this rail button (index) or card action — used for drawing the highlight.
function text_ui_is_focused_button(_index) {
    return !state.card_overlay.open && text_ui_focus_get() == _index;
}

function text_ui_is_focused_card_action(_action, _value) {
    var _focus = text_ui_focus_get();
    if (!state.card_overlay.open || _focus < 0) return false;
    var _items = text_ui_items();
    if (_focus >= array_length(_items)) return false;
    var _it = _items[_focus];
    return (_it.kind == "card_action" && _it.action == _action && _it.value == _value)
        || (_it.kind == "close" && _action == "__close__");
}

/// Opt-in verification telemetry (only when AA_STORM_RUN_ID is set).
function text_ui_emit_state(_last) {
    if (!variable_instance_exists(id, "aa_storm_run_id") || string_length(aa_storm_run_id) == 0) return;
    var _labels = [];
    var _items = text_ui_items();
    for (var _i = 0; _i < min(30, array_length(_items)); _i++) array_push(_labels, _items[_i].label);

    // Last console lines, verbatim: screen OCR truncates long lines, so tests read them from here.
    var _recent = [];
    var _log_count = array_length(state.logs);
    for (var _l = max(0, _log_count - 12); _l < _log_count; _l++) array_push(_recent, state.logs[_l]);
    var _data = {
        "run_id": aa_storm_run_id,
        "last_command": _last,
        "day": state.day,
        "hour": state.hour,
        "gold": state.gold,
        "reputation": state.reputation,
        "mode": mode_to_string(state.mode),
        "overlay": state.card_overlay.open,
        "status": state.status_line,
        "buttons": _labels,
        "log": _recent
    };
    show_debug_message("AA_STATE: " + json_stringify(_data));
}

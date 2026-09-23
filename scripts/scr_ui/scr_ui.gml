/// Shared UI vocabulary: one theme, real drawing helpers, and a layout the game can describe.
///
/// Before this, Draw_64 hardcoded colours in 76 places and its only helper was a local `var`
/// nothing else could call, so UI work meant inventing rectangle maths. Build screens from these
/// helpers instead, and add colours to ui_theme() rather than writing make_color_rgb inline.
///
/// Every helper records what it drew, so LAYOUT can report panels, overlaps and overflowing text
/// as console lines. That makes a UI change checkable by the same evidence the other gates use.

function ui_theme() {
    if (!variable_global_exists("ui_theme_cache")) {
        global.ui_theme_cache = {
            ink: make_color_rgb(236, 240, 247),
            dim: make_color_rgb(150, 160, 178),
            panel_top: make_color_rgb(27, 35, 50),
            panel_bottom: make_color_rgb(20, 26, 39),
            panel_edge: make_color_rgb(78, 93, 120),
            title_bar: make_color_rgb(36, 45, 63),
            accent: make_color_rgb(120, 170, 255),
            good: make_color_rgb(120, 200, 140),
            warn: make_color_rgb(230, 180, 90),
            bad: make_color_rgb(220, 110, 110),
            pad: 12,
            row_h: 22,
            title_h: 24,
            line_h: 18
        };
    }
    return global.ui_theme_cache;
}

/// Call once at the top of the draw event: starts a fresh record of what this frame contains.
function ui_frame_begin() {
    global.ui_rects = [];
    global.ui_texts = [];
}

function ui_record_rect(_name, _x1, _y1, _x2, _y2) {
    if (!variable_global_exists("ui_rects")) ui_frame_begin();
    array_push(global.ui_rects, { name: _name, x1: _x1, y1: _y1, x2: _x2, y2: _y2 });
}

function ui_record_text(_owner, _x, _y, _w, _h, _text) {
    if (!variable_global_exists("ui_texts")) ui_frame_begin();
    array_push(global.ui_texts, { owner: _owner, x: _x, y: _y, w: _w, h: _h, text: _text });
}

/// A titled panel. Same look as the shell has always had; now callable from anywhere and recorded.
function ui_panel(_x1, _y1, _x2, _y2, _title, _c1, _c2) {
    var _t = ui_theme();
    if (is_undefined(_c1)) _c1 = _t.panel_top;
    if (is_undefined(_c2)) _c2 = _t.panel_bottom;
    draw_rectangle_color(_x1, _y1, _x2, _y2, _c1, _c1, _c2, _c2, false);
    draw_set_color(_t.panel_edge);
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    draw_set_color(_t.title_bar);
    draw_rectangle(_x1 + 1, _y1 + 1, _x2 - 1, _y1 + _t.title_h, false);
    draw_set_color(c_white);
    draw_text(_x1 + 8, _y1 + 5, _title);
    ui_record_rect(_title, _x1, _y1, _x2, _y2);
    return { x1: _x1, y1: _y1, x2: _x2, y2: _y2, title: _title, y: _y1 + _t.title_h + 8 };
}

/// One line of text inside a panel, reported against that panel's bounds.
function ui_label(_panel, _x, _y, _text, _colour) {
    var _t = ui_theme();
    draw_set_color(is_undefined(_colour) ? _t.ink : _colour);
    draw_text(_x, _y, _text);
    ui_record_text(_panel.title, _x, _y, string_width(_text), string_height(_text), _text);
    return _y + _t.line_h;
}

/// A label/value row: the shape most of this game's panels are made of.
function ui_row(_panel, _x, _y, _label, _value, _colour) {
    var _t = ui_theme();
    draw_set_color(_t.dim);
    draw_text(_x, _y, _label);
    draw_set_color(is_undefined(_colour) ? _t.ink : _colour);
    var _vx = _x + 150;
    draw_text(_vx, _y, string(_value));
    ui_record_text(_panel.title, _x, _y, (_vx - _x) + string_width(string(_value)), string_height(_label), _label + " " + string(_value));
    return _y + _t.row_h;
}

/// A small filled bar for morale, trust, satisfaction: 0-100 with a colour band.
function ui_bar(_panel, _x, _y, _w, _value, _label) {
    var _t = ui_theme();
    var _h = 10;
    var _fill = clamp(_value / 100, 0, 1);
    var _colour = (_value >= 66) ? _t.good : ((_value >= 33) ? _t.warn : _t.bad);
    draw_set_color(_t.panel_edge);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_color(_colour);
    draw_rectangle(_x + 1, _y + 1, _x + max(1, _w * _fill) - 1, _y + _h - 1, false);
    draw_set_color(_t.dim);
    draw_text(_x + _w + 8, _y - 4, _label + " " + string(round(_value)));
    ui_record_text(_panel.title, _x, _y, _w + 8 + string_width(_label), _h, _label);
    return _y + _t.row_h;
}

/// ---------------------------------------------------------------- portrait stage
/// Who is "in the office" right now. A patron, client or prospect slides in from the right of the
/// centre panel and stays until someone else takes the chair. Art drops into ui_portrait_art()
/// later; until then each figure is a silhouette built from its own name, so faces stay stable.

function ui_stage_show(_kind, _name, _subtitle) {
    if (!variable_struct_exists(state, "stage")) state.stage = { kind: "", name: "", subtitle: "", slide: 0 };
    if (state.stage.name == _name && state.stage.kind == _kind) return;
    state.stage.kind = _kind;
    state.stage.name = _name;
    state.stage.subtitle = _subtitle;
    state.stage.slide = 0;              // 0 = off-stage right, 1 = seated
}

function ui_stage_clear() {
    if (variable_struct_exists(state, "stage")) {
        state.stage.kind = "";
        state.stage.name = "";
        state.stage.subtitle = "";
        state.stage.slide = 0;
    }
}

/// Advance the slide. Called once per drawn frame; 0.14 per frame is roughly a third of a second.
function ui_stage_step() {
    if (!variable_struct_exists(state, "stage")) return;
    if (state.stage.name == "") return;
    state.stage.slide = min(1, state.stage.slide + 0.14);
}

/// A stable colour per character, so the same person always arrives the same shade.
function ui_name_hue(_name) {
    var _sum = 0;
    for (var i = 1; i <= string_length(_name); i++) _sum += ord(string_char_at(_name, i));
    return _sum mod 360;
}

/// The placeholder figure: head, shoulders, and a plaque. Replaced by sprite art later.
function ui_portrait_figure(_x1, _y1, _x2, _y2, _name, _kind) {
    var _t = ui_theme();
    var _hue = ui_name_hue(_name);
    var _skin = make_color_hsv(((_hue mod 30) + 12) * 255 / 360, 70, 205);
    var _cloth = make_color_hsv(_hue * 255 / 360, 110, 130);
    var _w = _x2 - _x1;
    var _h = _y2 - _y1;
    var _cx = _x1 + _w / 2;
    var _plaque = 44;                              // name plate along the bottom
    var _fig_bottom = _y2 - _plaque;

    draw_set_color(make_color_rgb(16, 21, 31));
    draw_rectangle(_x1, _y1, _x2, _y2, false);

    // shoulders, clipped to the frame: an ellipse whose bottom sits on the plaque
    draw_set_color(_cloth);
    draw_ellipse(_cx - _w * 0.40, _fig_bottom - _h * 0.30, _cx + _w * 0.40, _fig_bottom, false);
    // neck and head
    draw_set_color(_skin);
    draw_rectangle(_cx - _w * 0.07, _fig_bottom - _h * 0.36, _cx + _w * 0.07, _fig_bottom - _h * 0.24, false);
    draw_circle(_cx, _fig_bottom - _h * 0.46, _w * 0.17, false);

    draw_set_color(make_color_rgb(24, 30, 44));
    draw_rectangle(_x1 + 1, _fig_bottom, _x2 - 1, _y2 - 1, false);
    draw_set_color(_t.panel_edge);
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    draw_set_halign(fa_center);
    draw_set_color(_t.ink);
    draw_text_ext(_cx, _fig_bottom + 6, _name, 16, _w - 12);
    draw_set_color(_t.dim);
    draw_text(_cx, _fig_bottom + 24, _kind);
    draw_set_halign(fa_left);
}


/// How much of a panel's right edge the portrait occupies, so text can wrap short of it.
function ui_stage_width() {
    if (!variable_struct_exists(state, "stage") || state.stage.name == "") return 0;
    return 210;
}


/// Draw whoever is on stage, sliding in from the right edge of the given panel.
function ui_stage_draw(_panel) {
    if (!variable_struct_exists(state, "stage") || state.stage.name == "") return;
    var _w = 190;
    var _h = 210;
    var _slide = state.stage.slide;
    var _eased = 1 - power(1 - _slide, 3);
    var _x2 = _panel.x2 - 18 + round((1 - _eased) * (_w + 30));
    var _x1 = _x2 - _w;
    var _y1 = _panel.y1 + 46;
    ui_portrait_figure(_x1, _y1, _x1 + _w, _y1 + _h, state.stage.name, state.stage.subtitle);
    ui_record_rect("Portrait: " + state.stage.name, _x1, _y1, _x1 + _w, _y1 + _h);
}

/// ---------------------------------------------------------------- layout self-report
/// LAYOUT prints what is on screen and what is wrong with it, so a UI change can be judged from
/// the console like every other gate: panels, their rectangles, overlaps, and text that runs out
/// of its panel.

function ui_rects_overlap(_a, _b) {
    return !(_a.x2 <= _b.x1 || _b.x2 <= _a.x1 || _a.y2 <= _b.y1 || _b.y2 <= _a.y1);
}

function ui_layout_report() {
    if (!variable_global_exists("ui_rects") || array_length(global.ui_rects) == 0) {
        add_log("LAYOUT: nothing recorded yet; the screen has not drawn a frame.");
        return;
    }
    add_log("LAYOUT: " + string(array_length(global.ui_rects)) + " panels this frame.");
    for (var i = 0; i < array_length(global.ui_rects); i++) {
        var _r = global.ui_rects[i];
        add_log("  " + _r.name + " [" + string(_r.x1) + "," + string(_r.y1) + " to " + string(_r.x2) + "," + string(_r.y2) + "]");
    }
    var _problems = 0;
    for (var i = 0; i < array_length(global.ui_rects); i++) {
        for (var j = i + 1; j < array_length(global.ui_rects); j++) {
            var _a = global.ui_rects[i];
            var _b = global.ui_rects[j];
            if (string_pos("Portrait", _a.name) > 0 || string_pos("Portrait", _b.name) > 0) continue;
            if (ui_rects_overlap(_a, _b)) {
                add_log("  OVERLAP: " + _a.name + " and " + _b.name);
                _problems += 1;
            }
        }
    }
    for (var i = 0; i < array_length(global.ui_texts); i++) {
        var _t = global.ui_texts[i];
        for (var p = 0; p < array_length(global.ui_rects); p++) {
            var _r = global.ui_rects[p];
            if (_r.name != _t.owner) continue;
            if (_t.x + _t.w > _r.x2 - 4 || _t.y + _t.h > _r.y2 - 4) {
                add_log("  OVERFLOW in " + _r.name + ": " + string_copy(_t.text, 1, 40));
                _problems += 1;
            }
        }
    }
    add_log("LAYOUT: " + string(_problems) + " problem(s).");
}

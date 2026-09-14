function enter_game_house() {
    if (state.game_over) return;
    state.mode = MODE.GAME_HOUSE;
    state.game_house_view = "lobby";
    state.status_line = "At the Gilded Griffin Game House. Time and rivals keep moving.";
    add_log("You step into the Gilded Griffin Game House. The city clock and rival offices continue in the background.");
}

function reset_game_house_round() {
    state.game_house.craps_phase = "idle";
    state.game_house.craps_point = 0;
    state.game_house.cards_in_round = false;
    state.game_house.cards_player = [];
    state.game_house.cards_dealer = [];
    state.game_house.cards_last_outcome = "";
}

function set_game_house_game(_game) {
    state.game_house_game = _game;
    state.game_house_view = "table";
    state.game_house_table_fresh = true;
    state.status_line = "Seated at " + _game + " table.";
    reset_game_house_round();
    switch (_game) {
        case "CRAPS": add_log("Table selected: Street Craps. Roll for point."); break;
        case "WHEEL": add_log("Table selected: Wyrm Wheel. Choose a bet and spin."); break;
        case "DRAGON21": add_log("Table selected: Dragon 21. Beat the dealer without busting."); break;
        default: add_log("Unknown table."); break;
    }
}

function change_game_house_wager(_delta) {
    state.game_house_wager = clamp(state.game_house_wager + _delta, 10, 250);
    add_log("Table wager set to " + string(state.game_house_wager) + "g.");
}

function card_draw_value() {
    var _rank = irandom_range(1, 13);
    if (_rank > 10) return 10;
    return _rank;
}

function card_hand_total(_hand) {
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
}

function card_hand_text(_hand) {
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
}

function wheel_number_color(_n) {
    if (_n == 0) return "GREEN";
    var _reds = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
    for (var i = 0; i < array_length(_reds); i++) {
        if (_reds[i] == _n) return "RED";
    }
    return "BLACK";
}

function game_house_roll_craps() {
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
    state.game_house_table_fresh = false;
    advance_hours(1);
}

function game_house_spin_wheel() {
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
    state.game_house_table_fresh = false;
    advance_hours(1);
}

function game_house_deal_21() {
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

    state.game_house_table_fresh = false;
    advance_hours(1);
}

function game_house_hit_21() {
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

    state.game_house_table_fresh = false;
    advance_hours(1);
}

function game_house_stand_21() {
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
    state.game_house_table_fresh = false;
    advance_hours(1);
}

function office_activity_visit_game_house() {
    enter_game_house();
}

function build_game_house_buttons() {
    add_card_gallery_button();
    button_add("Back to Planning", "goto_planning", -1);

    if (state.game_house_view == "lobby") {
        button_add("Street Craps", "gh_set_game", "CRAPS");
        button_add("Wyrm Wheel", "gh_set_game", "WHEEL");
        button_add("Dragon 21", "gh_set_game", "DRAGON21");
        return;
    }

    button_add("Return to Game List", "gh_back_lobby", -1);

    switch (state.game_house_game) {
        case "CRAPS":
            if (state.game_house_table_fresh && state.game_house.craps_phase == "idle" && state.game_house.craps_last_roll == 0) {
                button_add("Wager -10", "gh_wager_add", -10);
                button_add("Wager +10", "gh_wager_add", 10);
                button_add("Roll Come-Out", "gh_craps_roll", -1);
            } else {
                if (state.game_house.craps_phase == "idle") button_add("Roll Come-Out", "gh_craps_roll", -1);
                else button_add("Roll For Point " + string(state.game_house.craps_point), "gh_craps_roll", -1);
                button_add("Wager -10", "gh_wager_add", -10);
                button_add("Wager +10", "gh_wager_add", 10);
            }
        break;

        case "WHEEL":
            button_add("Spin Wyrm Wheel", "gh_wheel_spin", -1);
            button_add("Wager -10", "gh_wager_add", -10);
            button_add("Wager +10", "gh_wager_add", 10);
            button_add("Bet RED", "gh_wheel_bet", "RED");
            button_add("Bet BLACK", "gh_wheel_bet", "BLACK");
            button_add("Bet ODD", "gh_wheel_bet", "ODD");
            button_add("Bet EVEN", "gh_wheel_bet", "EVEN");
            button_add("Bet LOW 1-12", "gh_wheel_bet", "LOW12");
            button_add("Bet MID 13-24", "gh_wheel_bet", "MID12");
            button_add("Bet HIGH 25-36", "gh_wheel_bet", "HIGH12");
        break;

        case "DRAGON21":
            if (!state.game_house.cards_in_round) button_add("Deal Dragon 21", "gh_21_deal", -1);
            else {
                button_add("Hit", "gh_21_hit", -1);
                button_add("Stand", "gh_21_stand", -1);
            }
            button_add("Wager -10", "gh_wager_add", -10);
            button_add("Wager +10", "gh_wager_add", 10);
        break;
    }
}

"use strict";

var currentTrackMode = 1;

// Проверяем наличие Аганима в слотах или в виде съеденного баффа
function HasAghanim(unit) {
    if (!unit || unit === -1) return false;

    for (var i = 0; i <= 8; i++) {
        var item = Entities.GetItemInSlot(unit, i);
        if (item !== -1) {
            var itemName = Abilities.GetAbilityName(item);
            if (itemName === "item_ultimate_scepter" || itemName === "item_ultimate_scepter_2") {
                return true;
            }
        }
    }

    var numBuffs = Entities.GetNumBuffs(unit);
    for (var b = 0; b < numBuffs; b++) {
        var buff = Entities.GetBuff(unit, b);
        if (buff !== -1 && Buffs.GetName(unit, buff) === "modifier_item_ultimate_scepter_consumed") {
            return true;
        }
    }

    return false;
}

// Проверяем наличие ультимейта
function HasEarthquakeAbility(unit) {
    if (!unit || unit === -1) return false;
    var count = Entities.GetAbilityCount(unit);
    for (var i = 0; i < count; i++) {
        var ab = Entities.GetAbility(unit, i);
        if (ab !== -1) {
            var name = Abilities.GetAbilityName(ab);
            if (name === "custom_earthquake_bounce") {
                return true;
            }
        }
    }
    return false;
}

function UpdateUI() {
    var container = $("#SuprunovMusicContainer");
    if (!container) return;

    var localPlayerId = Game.GetLocalPlayerID();
    var selectedUnit = Players.GetLocalPlayerPortraitUnit();

    if (selectedUnit === -1 || !Entities.IsAlive(selectedUnit)) {
        container.SetHasClass("hidden", true);
        return;
    }

    if (!Entities.IsControllableByPlayer(selectedUnit, localPlayerId)) {
        container.SetHasClass("hidden", true);
        return;
    }

    if (!HasEarthquakeAbility(selectedUnit) || !HasAghanim(selectedUnit)) {
        container.SetHasClass("hidden", true);
        return;
    }

    // Если герой наш и у него есть Аганим — показываем меню
    container.SetHasClass("hidden", false);

    for (var i = 1; i <= 3; i++) {
        var btn = $("#TrackBtn" + i);
        if (btn) {
            btn.SetHasClass("selected", i === currentTrackMode);
        }
    }
}

function OnSelectTrack(mode) {
    var selectedUnit = Players.GetLocalPlayerPortraitUnit();
    if (selectedUnit === -1) return;

    currentTrackMode = mode;

    GameEvents.SendCustomGameEventToServer("suprunov_select_track", {
        unit: selectedUnit,
        mode: mode
    });

    Game.EmitSound("General.ButtonClick");
    UpdateUI();
}

(function () {
    GameEvents.Subscribe("suprunov_track_updated", function(data) {
        if (data && data.mode) {
            currentTrackMode = data.mode;
            UpdateUI();
        }
    });

    GameEvents.Subscribe("dota_player_update_selected_unit", UpdateUI);
    GameEvents.Subscribe("dota_player_update_query_unit", UpdateUI);

    function Loop() {
        UpdateUI();
        $.Schedule(0.25, Loop);
    }
    Loop();
})();
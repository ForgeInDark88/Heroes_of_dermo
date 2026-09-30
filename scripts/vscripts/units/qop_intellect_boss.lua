function QopBossThink(unit)
    if not unit or unit:IsNull() or not unit:IsAlive() then
        return 1
    end

    local ability = unit:FindAbilityByName("qop_steal_intellect")

    if not ability then
        print("[QOP AI] ERROR: ability not found!")
        return 1
    end

    if not ability:IsFullyCastable() then
        return 0.5
    end

    local enemies = FindUnitsInRadius(
        unit:GetTeamNumber(),
        unit:GetAbsOrigin(),
        nil,
        900,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    if #enemies == 0 then
        print("[QOP AI] No enemy heroes found")
        return 0.5
    end

    local target = enemies[1]

    print("[QOP AI] Casting on: " .. target:GetUnitName())

    ExecuteOrderFromTable({
        UnitIndex = unit:entindex(),
        OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
        TargetIndex = target:entindex(),
        AbilityIndex = ability:entindex(),
        Queue = false
    })

    return 1
end
-- Общие функции Дилдочки

function DildochkaGetEnemyUnits(caster, origin, radius)
    return FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )
end

function DildochkaApplyRottenFinger(caster, target, sourceAbility)
    if not caster or caster:IsNull() then return end
    if not target or target:IsNull() or not target:IsAlive() then return end

    local ability = sourceAbility or caster:FindAbilityByName("dildo_rotten_finger")
    if not ability then return end

    local duration = ability:GetSpecialValueFor("duration")
    local modifier = target:FindModifierByName("modifier_dildo_rotten_finger")

    if modifier then
        modifier:SetDuration(duration, true)
        return
    end

    target:AddNewModifier(caster, ability, "modifier_dildo_rotten_finger", {
        duration = duration
    })
end

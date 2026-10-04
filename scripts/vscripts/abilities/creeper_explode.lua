creeper_explode = class({})

LinkLuaModifier(
    "modifier_creeper_explode",
    "abilities/creeper_explode",
    LUA_MODIFIER_MOTION_NONE
)

function creeper_explode:GetIntrinsicModifierName()
    return "modifier_creeper_explode"
end


--------------------------------------------------------------------------------
-- ВЗРЫВ КРИПА
--------------------------------------------------------------------------------

function creeper_explode:ExplodeCreeper(unit)

    if not IsServer() then
        return
    end

    if not unit or unit:IsNull() then
        return
    end

    -- Защита от двойного взрыва
    if unit.creeper_has_exploded then
        return
    end

    unit.creeper_has_exploded = true

    local position = unit:GetAbsOrigin()

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")

    -- Талант Попчика: +урон к взрыву Ебанного брата
    local owner = unit:GetOwner()
    if owner and not owner:IsNull() and owner.FindAbilityByName then
        local talent = owner:FindAbilityByName("special_bonus_unique_popchik_creeper_damage")
        if talent and talent:GetLevel() > 0 then
            damage = damage + talent:GetSpecialValueFor("value")
        end
    end

    ----------------------------------------------------------------
    -- ЗВУК
    ----------------------------------------------------------------

    StartSoundEventFromPositionUnreliable(
        "soldatikboom",
        position
    )

    ----------------------------------------------------------------
    -- ЭФФЕКТ
    ----------------------------------------------------------------

    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_techies/techies_suicide.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )

    ParticleManager:SetParticleControl(
        particle,
        0,
        position
    )

    ParticleManager:SetParticleControl(
        particle,
        1,
        Vector(radius, 0, 0)
    )

    ParticleManager:ReleaseParticleIndex(particle)

    ----------------------------------------------------------------
    -- УРОН
    ----------------------------------------------------------------

    local enemies = FindUnitsInRadius(
        unit:GetTeamNumber(),
        position,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do

        if enemy
            and not enemy:IsNull()
            and enemy:IsAlive()
        then

            ApplyDamage({
                victim = enemy,
                attacker = unit,
                damage = damage,
                damage_type = DAMAGE_TYPE_MAGICAL,
                ability = self
            })

        end
    end
end


--------------------------------------------------------------------------------
-- ВЗРЫВ ПРИ СМЕРТИ
--------------------------------------------------------------------------------

modifier_creeper_explode = class({})

function modifier_creeper_explode:IsHidden()
    return true
end

function modifier_creeper_explode:IsPurgable()
    return false
end

function modifier_creeper_explode:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
    }
end


function modifier_creeper_explode:OnDeath(params)

    if not IsServer() then
        return
    end

    local unit = self:GetParent()

    -- Только смерть самого крипа
    if params.unit ~= unit then
        return
    end

    local ability = self:GetAbility()

    if not ability or ability:IsNull() then
        return
    end

    -- Взорвать сразу при убийстве
    GameRules:GetGameModeEntity():SetContextThink(
    DoUniqueString("creeper_explode_delay"),
    function()

        if not unit or unit:IsNull() then
            return nil
        end

        ability:ExplodeCreeper(unit)

        return nil
    end,
    0.1
    )
end
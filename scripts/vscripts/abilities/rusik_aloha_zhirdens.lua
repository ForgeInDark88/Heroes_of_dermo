-- Русик: врождёнка "Алоха жирденс"
-- Даёт интеллект, растущий с уровнем героя. Каждый раз, когда Русик применяет
-- способность, у него загораются волосы: вражеские герои в радиусе, которые в
-- этот момент смотрят на Русика (увидели W Завозика), каменеют на короткое время.
-- Аганим: способность, применённая на врага, ещё и выжигает ему ману.
-- Отключается истощением.

rusik_aloha_zhirdens = class({})

LinkLuaModifier("modifier_rusik_aloha_zhirdens", "abilities/rusik_aloha_zhirdens", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_aloha_zhirdens_stone", "abilities/rusik_aloha_zhirdens", LUA_MODIFIER_MOTION_NONE)

function rusik_aloha_zhirdens:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function rusik_aloha_zhirdens:GetIntrinsicModifierName()
    return "modifier_rusik_aloha_zhirdens"
end

modifier_rusik_aloha_zhirdens = class({})

function modifier_rusik_aloha_zhirdens:IsHidden() return true end
function modifier_rusik_aloha_zhirdens:IsPurgable() return false end
function modifier_rusik_aloha_zhirdens:RemoveOnDeath() return false end

function modifier_rusik_aloha_zhirdens:OnCreated()
    if not IsServer() then return end

    -- Врождёнка должна быть изучена, иначе значения из AbilityValues не берутся
    local ability = self:GetAbility()
    if ability and not ability:IsNull() and ability:GetLevel() == 0 then
        ability:SetLevel(1)
    end
end

function modifier_rusik_aloha_zhirdens:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }
end

function modifier_rusik_aloha_zhirdens:GetModifierBonusStats_Intellect()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() or self:GetParent():PassivesDisabled() then return 0 end
    return ability:GetSpecialValueFor("intellect_per_level") * self:GetParent():GetLevel()
end

function modifier_rusik_aloha_zhirdens:OnAbilityFullyCast(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.unit ~= parent then return end
    if parent:PassivesDisabled() or parent:IsIllusion() then return end

    local cast = params.ability
    if not cast or cast:IsNull() or cast:IsItem() then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() or cast == ability then return end

    self:BurnHair()
    self:Petrify()

    if parent:HasScepter() then
        self:ScepterManaBurn(params.target)
    end
end

function modifier_rusik_aloha_zhirdens:BurnHair()
    local parent = self:GetParent()
    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf",
        PATTACH_OVERHEAD_FOLLOW,
        parent
    )
    Timers:CreateTimer(1.5, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)
    parent:EmitSound("Hero_Huskar.Burning_Spear")
end

function modifier_rusik_aloha_zhirdens:Petrify()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local origin = parent:GetAbsOrigin()
    local max_angle = math.rad(ability:GetSpecialValueFor("facing_angle"))
    local duration = ability:GetSpecialValueFor("petrify_duration")

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        origin,
        nil,
        ability:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        local to_rusik = origin - enemy:GetAbsOrigin()
        to_rusik.z = 0
        local forward = enemy:GetForwardVector()
        forward.z = 0

        local looking = true
        if to_rusik:Length2D() > 1 then
            local dot = forward:Normalized():Dot(to_rusik:Normalized())
            looking = math.acos(math.max(-1, math.min(1, dot))) <= max_angle
        end

        if looking then
            enemy:AddNewModifier(parent, ability, "modifier_rusik_aloha_zhirdens_stone", {
                duration = duration * (1 - enemy:GetStatusResistance())
            })
            enemy:EmitSound("Hero_Medusa.StoneGaze.Stun")
        end
    end
end

function modifier_rusik_aloha_zhirdens:ScepterManaBurn(target)
    if not target or target:IsNull() or not target.GetMaxMana then return end

    local parent = self:GetParent()
    if target:GetTeamNumber() == parent:GetTeamNumber() then return end
    if target:GetMaxMana() <= 0 then return end

    local ability = self:GetAbility()
    local burn = ability:GetSpecialValueFor("scepter_mana_burn")
        + target:GetMaxMana() * ability:GetSpecialValueFor("scepter_mana_burn_pct") / 100
    burn = math.min(burn, target:GetMana())
    if burn <= 0 then return end

    target:SetMana(target:GetMana() - burn)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, target, burn, nil)

    local fx = ParticleManager:CreateParticle(
        "particles/generic_gameplay/generic_manaburn.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target
    )
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)
end

--------------------------------------------------------------------------------
-- ОКАМЕНЕНИЕ
--------------------------------------------------------------------------------

modifier_rusik_aloha_zhirdens_stone = class({})

function modifier_rusik_aloha_zhirdens_stone:IsHidden() return false end
function modifier_rusik_aloha_zhirdens_stone:IsDebuff() return true end
function modifier_rusik_aloha_zhirdens_stone:IsStunDebuff() return true end
function modifier_rusik_aloha_zhirdens_stone:IsPurgable() return false end
function modifier_rusik_aloha_zhirdens_stone:IsPurgeException() return true end

function modifier_rusik_aloha_zhirdens_stone:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }
end

function modifier_rusik_aloha_zhirdens_stone:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_rusik_aloha_zhirdens_stone:StatusEffectPriority()
    return MODIFIER_PRIORITY_ULTRA
end

function modifier_rusik_aloha_zhirdens_stone:GetEffectName()
    return "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
end

function modifier_rusik_aloha_zhirdens_stone:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

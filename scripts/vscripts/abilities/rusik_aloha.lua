-- Русик: врождёнка "Алоха Жирденс"
-- Пассивно даёт интеллект, который растёт с уровнем героя.
-- При применении любой способности у Русика загораются волосы: вражеские
-- герои рядом, которые в этот момент смотрят на Русика и видят его
-- (увидели W Завозик), окаменевают на короткое время.
-- Аганим: способность, применённая на врага, и каждое окаменение ещё и
-- выжигают ману.

rusik_aloha = class({})

LinkLuaModifier("modifier_rusik_aloha", "abilities/rusik_aloha", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_aloha_stone", "abilities/rusik_aloha", LUA_MODIFIER_MOTION_NONE)

function rusik_aloha:Spawn()
    if IsServer() and self:GetLevel() == 0 then
        self:SetLevel(1)
    end
end

function rusik_aloha:GetIntrinsicModifierName()
    return "modifier_rusik_aloha"
end

--------------------------------------------------------------------------------
-- ПАССИВКА
--------------------------------------------------------------------------------

modifier_rusik_aloha = class({})

function modifier_rusik_aloha:IsHidden() return true end
function modifier_rusik_aloha:IsPurgable() return false end
function modifier_rusik_aloha:RemoveOnDeath() return false end

function modifier_rusik_aloha:OnCreated()
    if not IsServer() then return end

    -- Врождёнка должна быть изучена, иначе значения из AbilityValues не берутся
    local ability = self:GetAbility()
    if ability and not ability:IsNull() and ability:GetLevel() == 0 then
        ability:SetLevel(1)
    end
end

function modifier_rusik_aloha:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    }
end

function modifier_rusik_aloha:GetModifierBonusStats_Intellect()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return 0 end
    if self:GetParent():PassivesDisabled() then return 0 end

    return ability:GetSpecialValueFor("bonus_int_base")
        + ability:GetSpecialValueFor("bonus_int_per_level") * self:GetParent():GetLevel()
end

function modifier_rusik_aloha:OnAbilityFullyCast(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.unit ~= parent then return end
    if parent:PassivesDisabled() or not parent:IsRealHero() then return end

    local cast = params.ability
    if not cast or cast:IsNull() or cast:IsItem() then return end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    self:IgniteHair()

    local origin = parent:GetAbsOrigin()
    local min_dot = math.cos(math.rad(ability:GetSpecialValueFor("facing_angle") / 2))
    local stone_duration = ability:GetSpecialValueFor("stone_duration")
    local burned = {}

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        origin,
        nil,
        ability:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        local to_rusik = origin - enemy:GetAbsOrigin()
        to_rusik.z = 0

        local facing = to_rusik:Length2D() < 1
            or enemy:GetForwardVector():Dot(to_rusik:Normalized()) >= min_dot

        if facing and enemy:CanEntityBeSeenByMyTeam(parent) then
            enemy:AddNewModifier(parent, ability, "modifier_rusik_aloha_stone", { duration = stone_duration })
            self:BurnMana(enemy, burned)
        end
    end

    local target = params.target or cast:GetCursorTarget()
    if target and not target:IsNull() and target.GetTeamNumber
        and target:GetTeamNumber() ~= parent:GetTeamNumber() then
        self:BurnMana(target, burned)
    end
end

function modifier_rusik_aloha:IgniteHair()
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

-- Аганим: выжигание маны. Каждого врага жжём не больше одного раза за каст.
function modifier_rusik_aloha:BurnMana(enemy, burned)
    local parent = self:GetParent()
    if not parent:HasScepter() then return end
    if burned[enemy] then return end
    if not enemy.GetMaxMana or enemy:GetMaxMana() <= 0 or not enemy:IsAlive() then return end
    burned[enemy] = true

    local ability = self:GetAbility()
    local burn = ability:GetSpecialValueFor("scepter_mana_burn")
        + parent:GetIntellect(false) * ability:GetSpecialValueFor("scepter_mana_burn_int_pct") / 100
    burn = math.min(burn, enemy:GetMana())
    if burn <= 0 then return end

    enemy:SetMana(math.max(0, enemy:GetMana() - burn))
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, enemy, burn, nil)

    local fx = ParticleManager:CreateParticle(
        "particles/generic_gameplay/generic_manaburn.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        enemy
    )
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)
end

--------------------------------------------------------------------------------
-- ОКАМЕНЕНИЕ
--------------------------------------------------------------------------------

modifier_rusik_aloha_stone = class({})

function modifier_rusik_aloha_stone:IsHidden() return false end
function modifier_rusik_aloha_stone:IsDebuff() return true end
function modifier_rusik_aloha_stone:IsStunDebuff() return true end
function modifier_rusik_aloha_stone:IsPurgable() return true end

function modifier_rusik_aloha_stone:OnCreated()
    if not IsServer() then return end
    self:GetParent():EmitSound("Hero_Medusa.StoneGaze.Stun")
end

function modifier_rusik_aloha_stone:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
    }
end

function modifier_rusik_aloha_stone:GetEffectName()
    return "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf"
end

function modifier_rusik_aloha_stone:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_rusik_aloha_stone:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_rusik_aloha_stone:StatusEffectPriority()
    return 10
end

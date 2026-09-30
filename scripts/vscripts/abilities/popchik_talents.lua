-- Popchik talent helper.
-- AbilityValues handle duration/root/damage talents directly.
-- This helper handles mana regen, +HP, and cooldown reductions.

LinkLuaModifier("modifier_popchik_talents", "abilities/popchik_talents", LUA_MODIFIER_MOTION_NONE)

popchik_talents = class({})

function popchik_talents:GetIntrinsicModifierName()
    return "modifier_popchik_talents"
end

modifier_popchik_talents = class({})

function modifier_popchik_talents:IsHidden()
    return true
end

function modifier_popchik_talents:IsPurgable()
    return false
end

function modifier_popchik_talents:RemoveOnDeath()
    return false
end

function modifier_popchik_talents:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    }
end

function modifier_popchik_talents:GetManaRegenConstant()
    local hero = self:GetParent()
    local talent = hero:FindAbilityByName("special_bonus_popchik_mana_regen")
    if talent and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("value")
    end
    return 0
end

function modifier_popchik_talents:GetModifierHealthBonus()
    local hero = self:GetParent()
    local talent = hero:FindAbilityByName("special_bonus_popchik_hp")
    if talent and talent:GetLevel() > 0 then
        return talent:GetSpecialValueFor("value")
    end
    return 0
end

local function ReduceCooldown(hero, abilityName, talentName)
    local talent = hero:FindAbilityByName(talentName)
    if not talent or talent:GetLevel() <= 0 then
        return
    end

    local ability = hero:FindAbilityByName(abilityName)
    if not ability then
        return
    end

    local remaining = ability:GetCooldownTimeRemaining()
    if remaining <= 0 then
        return
    end

    local reduction = math.abs(talent:GetSpecialValueFor("value"))
    if reduction <= 0 then
        return
    end

    ability:EndCooldown()
    ability:StartCooldown(math.max(0, remaining - reduction))
end

function modifier_popchik_talents:OnAbilityExecuted(params)
    local hero = self:GetParent()
    if params.unit ~= hero or not params.ability then
        return
    end

    local abilityName = params.ability:GetAbilityName()

    if abilityName == "throw_creeper" then
        ReduceCooldown(hero, "throw_creeper", "special_bonus_popchik_throw_creeper_cd")
    elseif abilityName == "chmoshnik" then
        ReduceCooldown(hero, "chmoshnik", "special_bonus_popchik_chmoshnik_cd")
    elseif abilityName == "custom_doom_aura" then
        ReduceCooldown(hero, "custom_doom_aura", "special_bonus_popchik_midas_cd")
    end
end

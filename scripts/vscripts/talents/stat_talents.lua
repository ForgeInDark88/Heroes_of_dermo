-- Общие таланты на статы (здоровье, дальность атаки, сила, ловкость, урон, реген маны).
-- Каждый талант из списка ниже — ability_lua с этим ScriptFile. Значение берётся
-- из AbilityValues таланта (bonus_health, bonus_attack_range, bonus_strength,
-- bonus_agility, bonus_damage, bonus_mana_regen) и действует, только когда талант изучен.

LinkLuaModifier("modifier_stat_talent", "talents/stat_talents", LUA_MODIFIER_MOTION_NONE)

local STAT_TALENTS = {
    "special_bonus_unique_artem_hp_150",
    "special_bonus_unique_artem_attack_range",
    "special_bonus_unique_rumka_strength",
    "special_bonus_unique_rumka_attack_damage",
    "special_bonus_unique_tugarchik_mana_regen_175",
    "special_bonus_unique_dildochka_agility",
}

for _, name in ipairs(STAT_TALENTS) do
    local talent = class({})

    function talent:GetIntrinsicModifierName()
        return "modifier_stat_talent"
    end

    _G[name] = talent
end

--------------------------------------------------------------------------------

modifier_stat_talent = class({})

function modifier_stat_talent:IsHidden() return true end
function modifier_stat_talent:IsPurgable() return false end
function modifier_stat_talent:RemoveOnDeath() return false end
function modifier_stat_talent:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_stat_talent:Value(key)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() or ability:GetLevel() <= 0 then
        return 0
    end
    return ability:GetSpecialValueFor(key)
end

function modifier_stat_talent:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

function modifier_stat_talent:GetModifierHealthBonus()
    return self:Value("bonus_health")
end

function modifier_stat_talent:GetModifierAttackRangeBonus()
    return self:Value("bonus_attack_range")
end

function modifier_stat_talent:GetModifierBonusStats_Strength()
    return self:Value("bonus_strength")
end

function modifier_stat_talent:GetModifierBonusStats_Agility()
    return self:Value("bonus_agility")
end

function modifier_stat_talent:GetModifierPreAttack_BonusDamage()
    return self:Value("bonus_damage")
end

function modifier_stat_talent:GetModifierConstantManaRegen()
    return self:Value("bonus_mana_regen")
end

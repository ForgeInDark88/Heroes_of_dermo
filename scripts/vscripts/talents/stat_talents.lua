-- Таланты на статы (здоровье, дальность атаки, сила, ловкость, интеллект, урон, реген маны и здоровья).
--
-- Сами таланты — обычные special_bonus_base (как все остальные таланты),
-- иначе движок не даёт доизучать вторую сторону дерева на 27-30 уровнях.
-- Бонусы даёт скрытый модификатор, который вешается на каждого героя
-- при спавне (events.lua, OnNPCSpawnedShared). Значения берутся из AbilityValues таланта.

LinkLuaModifier("modifier_stat_talents", "talents/stat_talents", LUA_MODIFIER_MOTION_NONE)

local STAT_TALENTS = {
    "special_bonus_unique_artem_hp_150",
    "special_bonus_unique_artem_attack_range",
    "special_bonus_unique_rumka_strength",
    "special_bonus_unique_rumka_attack_damage",
    "special_bonus_unique_tugarchik_mana_regen_175",
    "special_bonus_unique_dildochka_agility",
    "special_bonus_unique_arnold_hp_regen",
    "special_bonus_unique_rusik_intellect",
}

--------------------------------------------------------------------------------

modifier_stat_talents = class({})

function modifier_stat_talents:IsHidden() return true end
function modifier_stat_talents:IsPurgable() return false end
function modifier_stat_talents:RemoveOnDeath() return false end
function modifier_stat_talents:IsPermanent() return true end

function modifier_stat_talents:Value(key)
    local parent = self:GetParent()
    local total = 0

    for _, name in ipairs(STAT_TALENTS) do
        local talent = parent:FindAbilityByName(name)
        if talent and talent:GetLevel() > 0 then
            total = total + talent:GetSpecialValueFor(key)
        end
    end

    return total
end

function modifier_stat_talents:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
end

function modifier_stat_talents:GetModifierHealthBonus()
    return self:Value("bonus_health")
end

function modifier_stat_talents:GetModifierAttackRangeBonus()
    return self:Value("bonus_attack_range")
end

function modifier_stat_talents:GetModifierBonusStats_Strength()
    return self:Value("bonus_strength")
end

function modifier_stat_talents:GetModifierBonusStats_Agility()
    return self:Value("bonus_agility")
end

function modifier_stat_talents:GetModifierBonusStats_Intellect()
    return self:Value("bonus_intellect")
end

function modifier_stat_talents:GetModifierPreAttack_BonusDamage()
    return self:Value("bonus_damage")
end

function modifier_stat_talents:GetModifierConstantManaRegen()
    return self:Value("bonus_mana_regen")
end

function modifier_stat_talents:GetModifierConstantHealthRegen()
    return self:Value("bonus_health_regen")
end

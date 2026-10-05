-- Арнольд: 1. Вечное бомжество (пассивная)
-- Шанс уклонения от атак и бонус к скорости передвижения.

arnold_eternal_bum = class({})

LinkLuaModifier("modifier_arnold_eternal_bum", "abilities/arnold_eternal_bum", LUA_MODIFIER_MOTION_NONE)

function arnold_eternal_bum:GetIntrinsicModifierName()
    return "modifier_arnold_eternal_bum"
end

modifier_arnold_eternal_bum = class({})

function modifier_arnold_eternal_bum:IsHidden() return true end
function modifier_arnold_eternal_bum:IsPurgable() return false end
function modifier_arnold_eternal_bum:RemoveOnDeath() return false end

function modifier_arnold_eternal_bum:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    }
end

function modifier_arnold_eternal_bum:Value(key)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() or ability:GetLevel() <= 0 then return 0 end
    if self:GetParent():PassivesDisabled() then return 0 end
    return ability:GetSpecialValueFor(key)
end

function modifier_arnold_eternal_bum:GetModifierEvasion_Constant()
    return self:Value("evasion_chance")
end

function modifier_arnold_eternal_bum:GetModifierMoveSpeedBonus_Constant()
    return self:Value("bonus_movement_speed")
end

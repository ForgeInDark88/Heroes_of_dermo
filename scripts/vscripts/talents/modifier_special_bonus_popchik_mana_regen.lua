LinkLuaModifier("modifier_special_bonus_popchik_mana_regen", "talents/modifier_special_bonus_popchik_mana_regen", LUA_MODIFIER_MOTION_NONE)

modifier_special_bonus_popchik_mana_regen = class({})

function modifier_special_bonus_popchik_mana_regen:IsHidden() return true end
function modifier_special_bonus_popchik_mana_regen:IsPurgable() return false end

function modifier_special_bonus_popchik_mana_regen:DeclareFunctions()
    return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end

function modifier_special_bonus_popchik_mana_regen:GetModifierManaRegenConstant()
    return 2.5
end

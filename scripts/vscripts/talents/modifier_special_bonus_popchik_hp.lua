LinkLuaModifier("modifier_special_bonus_popchik_hp", "talents/modifier_special_bonus_popchik_hp", LUA_MODIFIER_MOTION_NONE)

modifier_special_bonus_popchik_hp = class({})

function modifier_special_bonus_popchik_hp:IsHidden() return true end
function modifier_special_bonus_popchik_hp:IsPurgable() return false end

function modifier_special_bonus_popchik_hp:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_BONUS }
end

function modifier_special_bonus_popchik_hp:GetModifierHealthBonus()
    return 200
end

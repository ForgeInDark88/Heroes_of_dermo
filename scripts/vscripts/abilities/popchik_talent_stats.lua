LinkLuaModifier("modifier_popchik_talent_stats", "abilities/popchik_talent_stats", LUA_MODIFIER_MOTION_NONE)

popchik_talent_stats = class({})
function popchik_talent_stats:GetIntrinsicModifierName() return "modifier_popchik_talent_stats" end

modifier_popchik_talent_stats = class({})
function modifier_popchik_talent_stats:IsHidden() return true end
function modifier_popchik_talent_stats:IsPurgable() return false end
function modifier_popchik_talent_stats:DeclareFunctions()
    return {MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}
end
local function Learned(p,n) local a=p:FindAbilityByName(n); return a ~= nil and a:GetLevel() > 0 end
function modifier_popchik_talent_stats:GetModifierHealthBonus()
    return Learned(self:GetParent(), "special_bonus_unique_popchik_hp") and 200 or 0
end
function modifier_popchik_talent_stats:GetModifierConstantManaRegen()
    return Learned(self:GetParent(), "special_bonus_unique_popchik_mana_regen") and 2.5 or 0
end

-- Дилдочка: врождёнка. Пирожочек

if dildo_pirozhechek == nil then dildo_pirozhechek = class({}) end

LinkLuaModifier("modifier_dildo_pirozhechek", "abilities/dildochka_innate_pirozhechek", LUA_MODIFIER_MOTION_NONE)

function dildo_pirozhechek:GetIntrinsicModifierName()
    return "modifier_dildo_pirozhechek"
end

modifier_dildo_pirozhechek = class({})

function modifier_dildo_pirozhechek:IsHidden() return false end
function modifier_dildo_pirozhechek:IsPurgable() return false end
function modifier_dildo_pirozhechek:GetTexture() return "marci_companion_run" end

function modifier_dildo_pirozhechek:DeclareFunctions()
    return { MODIFIER_PROPERTY_EVASION_CONSTANT }
end

-- 10% + 1% за каждый уровень героя
function modifier_dildo_pirozhechek:GetModifierEvasion_Constant()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return 0 end

    return ability:GetSpecialValueFor("evasion_chance")
        + ability:GetSpecialValueFor("evasion_per_hero_level") * self:GetParent():GetLevel()
end

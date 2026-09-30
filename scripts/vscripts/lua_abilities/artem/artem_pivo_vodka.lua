artem_pivo_vodka = class({})

LinkLuaModifier(
    "modifier_artem_pivo_vodka",
    "lua_abilities/artem/artem_pivo_vodka",
    LUA_MODIFIER_MOTION_NONE
)

local TALENT = "special_bonus_artem_pivo_vodka_armor"

function artem_pivo_vodka:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(
        caster,
        self,
        "modifier_artem_pivo_vodka",
        {
            duration = self:GetSpecialValueFor("duration")
        }
    )

    caster:EmitSound("vodka")
end


modifier_artem_pivo_vodka = class({})

function modifier_artem_pivo_vodka:IsPurgable()
    return true
end

function modifier_artem_pivo_vodka:OnCreated()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    if not ability then
        return
    end

    self.armor = ability:GetSpecialValueFor("bonus_armor")

    -- По умолчанию штраф есть
    self.magic_resist = -ability:GetSpecialValueFor("magic_resistance_loss")

    -- Aghanim's Shard убирает штраф
    if parent:HasModifier("modifier_item_aghanims_shard") then
        self.magic_resist = 0
    end

    -- Талант
    local talent = parent:FindAbilityByName(TALENT)

    if talent and talent:GetLevel() > 0 then
        self.armor = self.armor + 20
    end
end

function modifier_artem_pivo_vodka:OnRefresh()
    self:OnCreated()
end

function modifier_artem_pivo_vodka:GetModifierPhysicalArmorBonus()
    return self.armor or 0
end

function modifier_artem_pivo_vodka:GetModifierMagicalResistanceBonus()
    return self.magic_resist or 0
end

function modifier_artem_pivo_vodka:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

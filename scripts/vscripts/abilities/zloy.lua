ZLOY = class({})

LinkLuaModifier("modifier_tugarchik_zlost", "abilities/zloy.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tugarchik_zloy_mana", "abilities/zloy.lua", LUA_MODIFIER_MOTION_NONE)

function ZLOY:GetIntrinsicModifierName()
    return "modifier_tugarchik_zloy_mana"
end

function ZLOY:GetCooldown(level)
    return self:GetSpecialValueFor("AbilityCooldown")
end

function ZLOY:OnSpellStart()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    local talent = caster:FindAbilityByName("special_bonus_unique_tugarchik_zloy_dispel")
    if talent and talent:GetLevel() > 0 then
        -- Normal/basic dispel of the caster's debuffs.
        caster:Purge(false, true, false, false, false)
    end

    local duration = self:GetSpecialValueFor("dur")
    caster:AddNewModifier(caster, self, "modifier_tugarchik_zlost", { duration = duration })
    caster:EmitSound("zloy")
end

modifier_tugarchik_zlost = class({})

function modifier_tugarchik_zlost:IsBuff() return true end
function modifier_tugarchik_zlost:IsPurgable() return false end
function modifier_tugarchik_zlost:RemoveOnDeath() return true end

function modifier_tugarchik_zlost:OnCreated()
    local ability = self:GetAbility()
    self.damage = ability and ability:GetSpecialValueFor("dmg") or 0
end

function modifier_tugarchik_zlost:DeclareFunctions()
    return { MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end

function modifier_tugarchik_zlost:GetModifierDamageOutgoing_Percentage()
    return self.damage or 0
end

modifier_tugarchik_zloy_mana = class({})

function modifier_tugarchik_zloy_mana:IsHidden() return true end
function modifier_tugarchik_zloy_mana:IsPurgable() return false end
function modifier_tugarchik_zloy_mana:RemoveOnDeath() return false end

function modifier_tugarchik_zloy_mana:DeclareFunctions()
    return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end

function modifier_tugarchik_zloy_mana:GetModifierConstantManaRegen()
    local parent = self:GetParent()
    local talent = parent:FindAbilityByName("special_bonus_unique_tugarchik_mana_regen")
    return (talent and talent:GetLevel() > 0) and 1.25 or 0
end

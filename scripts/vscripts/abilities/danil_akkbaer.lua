-- Данил: 1. Аккбаер
-- Данил заявляет, что он аккбаер: на время растёт урон атаки и сама моделька.

danil_akkbaer = class({})

LinkLuaModifier("modifier_danil_akkbaer", "abilities/danil_akkbaer", LUA_MODIFIER_MOTION_NONE)

function danil_akkbaer:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_danil_akkbaer", {
        duration = self:GetSpecialValueFor("duration")
    })
    caster:EmitSound("Hero_Sven.GodsStrength")
end

modifier_danil_akkbaer = class({})

function modifier_danil_akkbaer:IsHidden() return false end
function modifier_danil_akkbaer:IsDebuff() return false end
function modifier_danil_akkbaer:IsPurgable() return true end

function modifier_danil_akkbaer:OnCreated()
    self:OnRefresh()
end

function modifier_danil_akkbaer:OnRefresh()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then return end

    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.model_scale = ability:GetSpecialValueFor("model_scale")
end

function modifier_danil_akkbaer:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_MODEL_SCALE,
    }
end

function modifier_danil_akkbaer:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage or 0
end

function modifier_danil_akkbaer:GetModifierModelScale()
    return self.model_scale or 0
end

function modifier_danil_akkbaer:GetEffectName()
    return "particles/units/heroes/hero_sven/sven_spell_gods_strength_ambient.vpcf"
end

function modifier_danil_akkbaer:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

-- Дилдочка: Ульта. Хуй знает кто по жизни

if dildo_who_the_fuck_is_he == nil then dildo_who_the_fuck_is_he = class({}) end

LinkLuaModifier("modifier_dildo_ultimate", "abilities/dildochka_4_who_the_fuck_is_he", LUA_MODIFIER_MOTION_NONE)
require("abilities/dildochka_shared")

function dildo_who_the_fuck_is_he:GetIntrinsicModifierName()
    return "modifier_dildo_ultimate"
end

function dildo_who_the_fuck_is_he:OnToggle()
    local caster = self:GetCaster()
    local active = self:GetToggleState()
    local mod = caster:FindModifierByName("modifier_dildo_ultimate")

    if mod then
        mod:ForceRefresh()
    end

    if active then
        caster:EmitSound("Hero_Marci.Unleash")
        caster:EmitSound("Hero_Marci.Unleash.Cast")

        local p = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_marci/marci_unleash.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            caster
        )
        ParticleManager:SetParticleControl(p, 0, caster:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(p)
    else
        caster:EmitSound("Hero_Marci.Unleash.End")
    end
end

modifier_dildo_ultimate = class({})

function modifier_dildo_ultimate:IsHidden() return false end
function modifier_dildo_ultimate:IsPurgable() return false end
function modifier_dildo_ultimate:GetTexture() return "marci_unleash" end

function modifier_dildo_ultimate:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_dildo_ultimate:OnCreated()
    self:RefreshValues()
end

function modifier_dildo_ultimate:OnRefresh()
    self:RefreshValues()
end

function modifier_dildo_ultimate:RefreshValues()
    local ability = self:GetAbility()
    self.level = ability and ability:GetLevel() or 0
    self.active = ability and ability:GetToggleState() or false
    self.attack_damage = ability and ability:GetSpecialValueFor("bonus_attack_damage") or 0
    self.crit_chance = ability and ability:GetSpecialValueFor("crit_chance") or 0
    self.crit_multiplier = ability and ability:GetSpecialValueFor("crit_multiplier") or 0
    self.on_hit_infection = ability and ability:GetSpecialValueFor("on_hit_infection") or 0
    self.spell_amp = ability and ability:GetSpecialValueFor("spell_amplify") or 0
end

function modifier_dildo_ultimate:GetModifierPreAttack_BonusDamage()
    if self.active then return 0 end
    return self.attack_damage
end

function modifier_dildo_ultimate:GetModifierPreAttack_CriticalStrike(params)
    if self.active or self.level < 2 then return nil end
    if RollPercentage(self.crit_chance) then
        return self.crit_multiplier
    end
    return nil
end

function modifier_dildo_ultimate:GetModifierSpellAmplify_Percentage()
    if not self.active then return 0 end
    return self.spell_amp
end

function modifier_dildo_ultimate:OnAttackLanded(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    if self.active or self.on_hit_infection ~= 1 then return end
    if not params.target or params.target:IsNull() then return end
    if params.target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end

    local rotten_finger = self:GetParent():FindAbilityByName("dildo_rotten_finger")
    if rotten_finger then
        DildochkaApplyRottenFinger(self:GetParent(), params.target, rotten_finger)
        params.target:EmitSound("Hero_Venomancer.VenomousGale")
    end
end

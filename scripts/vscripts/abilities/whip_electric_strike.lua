whip_electric_strike = class({})
require('libraries/timers')
LinkLuaModifier("modifier_whip_electric_stun", "abilities/whip_electric_strike", LUA_MODIFIER_MOTION_NONE)

function whip_electric_strike:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local stun_duration = self:GetSpecialValueFor("stun_duration")
    local damage = self:GetSpecialValueFor("damage")

    -- Одиночный звук удара при колдовстве
    EmitSoundOn("kuzya", target)

    -- Эффект электрического провода
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_razor/razor_static_link.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    Timers:CreateTimer(1.0, function()
        if particle then
            ParticleManager:DestroyParticle(particle, false)
            ParticleManager:ReleaseParticleIndex(particle)
        end
    end)
 

    -- Урон
   ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    })

    -- Наложение стана
    target:AddNewModifier(caster, self, "modifier_whip_electric_stun", { duration = stun_duration })
end

--------------------------------------------------------------------------------

modifier_whip_electric_stun = class({})

function modifier_whip_electric_stun:IsDebuff() return true end
function modifier_whip_electric_stun:IsStunDebuff() return true end
function modifier_whip_electric_stun:IsPurgeable() return true end

function modifier_whip_electric_stun:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
    }
end

function modifier_whip_electric_stun:GetEffectName()
    return "particles/units/heroes/hero_razor/razor_ambient_g.vpcf"
end

function modifier_whip_electric_stun:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
custom_aghanim_ability = class({})
LinkLuaModifier("modifier_custom_aghanim_debuff", "abilities/custom_aghanim_ability.lua", LUA_MODIFIER_MOTION_NONE)

function custom_aghanim_ability:OnChannelFinish(bInterrupted)
    if bInterrupted then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local target_pos
    EmitSoundOn("litvin", caster)
    
    if target then
        target_pos = target:GetAbsOrigin()
    else
        target_pos = self:GetCursorPosition()
    end

    local caster_pos = caster:GetAbsOrigin()
    local direction = (target_pos - caster_pos):Normalized()
    local distance = self:GetCastRange(caster_pos, target)
    local speed = self:GetSpecialValueFor("projectile_speed")

    -- Линейный снаряд строго в сторону цели
    local linear_info = {
        Ability = self,
        EffectName = "particles/units/heroes/hero_morphling/morphling_waveform.vpcf",
        vSpawnOrigin = caster_pos,
        fDistance = distance,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 10.0,
        vVelocity = direction * speed,
        bProvidesVision = true,
        iVisionRadius = 200,
        iVisionTeamNumber = caster:GetTeamNumber()
    }
    
    ProjectileManager:CreateLinearProjectile(linear_info)
end



function custom_aghanim_ability:OnProjectileHit(target, location)
    if not target or target:IsInvulnerable() then return end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(self:GetCaster(), self, "modifier_custom_aghanim_debuff", { duration = duration })
end

--------------------------------------------------------------------------------
-- МОДИФИКАТОР (Дебафф)
--------------------------------------------------------------------------------
modifier_custom_aghanim_debuff = class({})

function modifier_custom_aghanim_debuff:IsHidden() return false end
function modifier_custom_aghanim_debuff:IsDebuff() return true end
function modifier_custom_aghanim_debuff:IsPurgable() return true end

function modifier_custom_aghanim_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_custom_aghanim_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_custom_aghanim_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed_slow")
end

function modifier_custom_aghanim_debuff:GetEffectName()
    return "particles/units/heroes/hero_brewmaster/brewmaster_cinder_brew_debuff.vpcf"
end

function modifier_custom_aghanim_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
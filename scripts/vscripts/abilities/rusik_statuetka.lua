-- Русик: 3. Статуэтка
-- Писюлек даёт ауру камня: союзный герой (или сам Русик) превращается в
-- каменную статуэтку — не может атаковать, его нельзя атаковать, и он ходит
-- быстрее. Способности использовать может. Эффект можно развеять.

rusik_statuetka = class({})

LinkLuaModifier("modifier_rusik_statuetka", "abilities/rusik_statuetka", LUA_MODIFIER_MOTION_NONE)

function rusik_statuetka:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    target:AddNewModifier(caster, self, "modifier_rusik_statuetka", {
        duration = self:GetSpecialValueFor("duration")
    })

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_medusa/medusa_stone_gaze_debuff_stoned.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target
    )
    ParticleManager:ReleaseParticleIndex(fx)

    target:EmitSound("Hero_Medusa.StoneGaze.Target")
end

--------------------------------------------------------------------------------
-- КАМЕНЬ
--------------------------------------------------------------------------------

modifier_rusik_statuetka = class({})

function modifier_rusik_statuetka:IsHidden() return false end
function modifier_rusik_statuetka:IsPurgable() return true end

function modifier_rusik_statuetka:OnCreated()
    local ability = self:GetAbility()
    self.move_speed = ability and ability:GetSpecialValueFor("bonus_movement_speed") or 0

    if IsServer() then
        self:GetParent():Stop()
    end
end

function modifier_rusik_statuetka:OnRefresh()
    self:OnCreated()
end

function modifier_rusik_statuetka:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    }
end

function modifier_rusik_statuetka:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_rusik_statuetka:GetModifierMoveSpeedBonus_Percentage()
    return self.move_speed
end

function modifier_rusik_statuetka:GetStatusEffectName()
    return "particles/status_fx/status_effect_medusa_stone_gaze.vpcf"
end

function modifier_rusik_statuetka:StatusEffectPriority()
    return MODIFIER_PRIORITY_HIGH
end

-- Русик: 2. Ларпкрафт
-- Русик знает сюжет Варкрафта и опускает ларпера: снаряд наносит чистый урон,
-- накладывает безмолвие и замедление. Эффект можно развеять.

rusik_larpcraft = class({})

LinkLuaModifier("modifier_rusik_larpcraft_debuff", "abilities/rusik_larpcraft", LUA_MODIFIER_MOTION_NONE)

function rusik_larpcraft:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bDodgeable = false,
        bProvidesVision = true,
        iVisionRadius = 150,
        iVisionTeamNumber = caster:GetTeamNumber(),
    })

    caster:EmitSound("Hero_SkywrathMage.ConcussiveShot.Cast")
end

function rusik_larpcraft:OnProjectileHit(target, location)
    if not target or target:IsNull() or not target:IsAlive() then return true end
    if target:TriggerSpellAbsorb(self) then return true end

    local caster = self:GetCaster()

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = DAMAGE_TYPE_PURE,
        ability = self,
    })

    if target:IsAlive() then
        target:AddNewModifier(caster, self, "modifier_rusik_larpcraft_debuff", {
            duration = self:GetSpecialValueFor("duration") * (1 - target:GetStatusResistance())
        })
    end

    target:EmitSound("Hero_SkywrathMage.ConcussiveShot.Target")
    return true
end

--------------------------------------------------------------------------------
-- ОПУЩЕН: безмолвие + замедление
--------------------------------------------------------------------------------

modifier_rusik_larpcraft_debuff = class({})

function modifier_rusik_larpcraft_debuff:IsHidden() return false end
function modifier_rusik_larpcraft_debuff:IsDebuff() return true end
function modifier_rusik_larpcraft_debuff:IsPurgable() return true end

function modifier_rusik_larpcraft_debuff:OnCreated()
    local ability = self:GetAbility()
    self.slow = ability and ability:GetSpecialValueFor("slow") or 0
end

function modifier_rusik_larpcraft_debuff:CheckState()
    return { [MODIFIER_STATE_SILENCED] = true }
end

function modifier_rusik_larpcraft_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_rusik_larpcraft_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end

function modifier_rusik_larpcraft_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_rusik_larpcraft_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

-- Русик: 2. Ларпкрафт
-- Русик знает сюжет Варкрафта и опускает ларпера: снаряд наносит чистый урон,
-- накладывает безмолвие и замедление. С талантом бьёт всех врагов вокруг цели.

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
        EffectName = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf",
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        bDodgeable = false,
        bProvidesVision = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    })

    caster:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb")
end

function rusik_larpcraft:OnProjectileHit(target, location)
    if not target or target:IsNull() or not target:IsAlive() then return true end
    if target:TriggerSpellAbsorb(self) then return true end

    local caster = self:GetCaster()
    local victims = { target }

    local aoe_radius = self:GetSpecialValueFor("aoe_radius")
    if aoe_radius > 0 then
        victims = FindUnitsInRadius(
            caster:GetTeamNumber(),
            target:GetAbsOrigin(),
            nil,
            aoe_radius,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false
        )
    end

    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("silence_duration")

    for _, victim in pairs(victims) do
        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_PURE,
            ability = self,
        })

        if victim:IsAlive() then
            victim:AddNewModifier(caster, self, "modifier_rusik_larpcraft_debuff", { duration = duration })
        end
    end

    target:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb.Impact")
    return true
end

--------------------------------------------------------------------------------
-- ОПУЩЕННЫЙ ЛАРПЕР: безмолвие + замедление
--------------------------------------------------------------------------------

modifier_rusik_larpcraft_debuff = class({})

function modifier_rusik_larpcraft_debuff:IsHidden() return false end
function modifier_rusik_larpcraft_debuff:IsDebuff() return true end
function modifier_rusik_larpcraft_debuff:IsPurgable() return true end

function modifier_rusik_larpcraft_debuff:OnCreated()
    local ability = self:GetAbility()
    self.slow = ability and ability:GetSpecialValueFor("slow") or 0
end

function modifier_rusik_larpcraft_debuff:OnRefresh()
    self:OnCreated()
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

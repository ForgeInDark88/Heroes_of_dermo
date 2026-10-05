-- Арнольд: 2. Диванчик с мусорки
-- Кидает диван в направлении точки (как копьё Марса). Все задетые враги
-- получают магический урон и оцепенение. С аганимом с целей ещё
-- непрерывно снимаются положительные эффекты (как Nullifier).

arnold_divan = class({})

LinkLuaModifier("modifier_arnold_divan_root", "abilities/arnold_divan", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arnold_divan_purge", "abilities/arnold_divan", LUA_MODIFIER_MOTION_NONE)

function arnold_divan:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local point = self:GetCursorPosition()

    local direction = point - origin
    direction.z = 0
    if direction:Length2D() < 1 then
        direction = caster:GetForwardVector()
    end
    direction = direction:Normalized()

    local speed = self:GetSpecialValueFor("projectile_speed")
    local width = self:GetSpecialValueFor("projectile_width")
    local distance = self:GetCastRange(origin, nil) + caster:GetCastRangeBonus()

    -- Частицу ведём сами и удаляем сразу по прилёту: у копья Марса
    -- есть зацикленные части, которые иначе остаются на карте навсегда.
    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_mars/mars_spear.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(fx, 0, origin)
    ParticleManager:SetParticleControl(fx, 1, direction * speed)
    ParticleManager:SetParticleControl(fx, 2, Vector(0, 0, 0))
    Timers:CreateTimer(distance / speed, function()
        ParticleManager:DestroyParticle(fx, true)
        ParticleManager:ReleaseParticleIndex(fx)
    end)

    ProjectileManager:CreateLinearProjectile({
        Ability = self,
        EffectName = "",
        vSpawnOrigin = origin,
        fDistance = distance,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE, -- не проходит сквозь невосприимчивость
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
        vVelocity = direction * speed,
        bProvidesVision = true,
        iVisionRadius = width,
        iVisionTeamNumber = caster:GetTeamNumber(),
    })

    caster:EmitSound("Hero_Mars.Spear.Cast")
end

function arnold_divan:OnProjectileHit(target, location)
    if not target or target:IsNull() then return false end

    local caster = self:GetCaster()

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
    })

    target:AddNewModifier(caster, self, "modifier_arnold_divan_root", {
        duration = self:GetSpecialValueFor("root_duration")
    })

    if caster:HasScepter() then
        target:AddNewModifier(caster, self, "modifier_arnold_divan_purge", {
            duration = self:GetSpecialValueFor("scepter_purge_duration")
        })
    end

    target:EmitSound("Hero_Mars.Spear.Target")

    -- Диван летит дальше и задевает всех на пути
    return false
end

--------------------------------------------------------------------------------
-- ОЦЕПЕНЕНИЕ
--------------------------------------------------------------------------------

modifier_arnold_divan_root = class({})

function modifier_arnold_divan_root:IsHidden() return false end
function modifier_arnold_divan_root:IsDebuff() return true end
function modifier_arnold_divan_root:IsPurgable() return true end

function modifier_arnold_divan_root:CheckState()
    return { [MODIFIER_STATE_ROOTED] = true }
end

function modifier_arnold_divan_root:GetEffectName()
    return "particles/units/heroes/hero_mars/mars_spear_impact_debuff.vpcf"
end

function modifier_arnold_divan_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
-- АГАНИМ: НЕПРЕРЫВНОЕ СНЯТИЕ ПОЛОЖИТЕЛЬНЫХ ЭФФЕКТОВ
--------------------------------------------------------------------------------

modifier_arnold_divan_purge = class({})

function modifier_arnold_divan_purge:IsHidden() return false end
function modifier_arnold_divan_purge:IsDebuff() return true end
function modifier_arnold_divan_purge:IsPurgable() return true end
function modifier_arnold_divan_purge:GetTexture() return "item_nullifier" end

function modifier_arnold_divan_purge:GetEffectName()
    return "particles/items4_fx/nullifier_mute_debuff.vpcf"
end

function modifier_arnold_divan_purge:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_arnold_divan_purge:OnCreated()
    if not IsServer() then return end
    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_arnold_divan_purge:OnIntervalThink()
    -- RemovePositiveBuffs, RemoveDebuffs, FrameOnly, RemoveStuns, RemoveExceptions
    self:GetParent():Purge(true, false, false, false, false)
end

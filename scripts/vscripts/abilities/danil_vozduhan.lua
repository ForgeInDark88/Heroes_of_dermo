-- Данил: 3. Воздухан
-- Данил выпускает волну воздуха в направлении точки. Задетые враги получают
-- магический урон и отлетают по ходу волны.
-- Шард: волна ещё и замедляет задетых врагов.

danil_vozduhan = class({})

LinkLuaModifier("modifier_danil_vozduhan_slow", "abilities/danil_vozduhan", LUA_MODIFIER_MOTION_NONE)

local function HasShard(caster)
    return caster and not caster:IsNull() and caster:HasModifier("modifier_item_aghanims_shard")
end

function danil_vozduhan:GetCooldown(level)
    local cooldown = self.BaseClass.GetCooldown(self, level)
    if HasShard(self:GetCaster()) then
        cooldown = cooldown - self:GetSpecialValueFor("shard_cooldown_reduction")
    end
    return math.max(0, cooldown)
end

function danil_vozduhan:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()

    local direction = self:GetCursorPosition() - origin
    direction.z = 0
    if direction:Length2D() < 1 then
        direction = caster:GetForwardVector()
    end
    direction = direction:Normalized()

    local speed = self:GetSpecialValueFor("wave_speed")
    local width = self:GetSpecialValueFor("wave_width")

    ProjectileManager:CreateLinearProjectile({
        Ability = self,
        EffectName = "particles/units/heroes/hero_invoker/invoker_deafening_blast.vpcf",
        vSpawnOrigin = origin,
        fDistance = self:GetSpecialValueFor("wave_distance") + caster:GetCastRangeBonus(),
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
        vVelocity = direction * speed,
        bProvidesVision = true,
        iVisionRadius = width,
        iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData = { dir_x = direction.x, dir_y = direction.y },
    })

    caster:EmitSound("Hero_Invoker.DeafeningBlast")
end

function danil_vozduhan:OnProjectileHit_ExtraData(target, location, extra)
    if not target or target:IsNull() then return false end

    local caster = self:GetCaster()
    local direction = Vector(extra.dir_x or 0, extra.dir_y or 0, 0)
    if direction:Length2D() < 0.1 then
        direction = caster:GetForwardVector()
    end

    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self,
    })

    -- Центр отталкивания — позади цели, чтобы она летела по ходу волны
    local center = target:GetAbsOrigin() - direction * 100
    target:AddNewModifier(caster, self, "modifier_knockback", {
        center_x = center.x,
        center_y = center.y,
        center_z = center.z,
        duration = self:GetSpecialValueFor("knockback_duration"),
        knockback_duration = self:GetSpecialValueFor("knockback_duration"),
        knockback_distance = self:GetSpecialValueFor("knockback_distance"),
        knockback_height = 50,
        should_stun = 1,
    })

    if HasShard(caster) then
        target:AddNewModifier(caster, self, "modifier_danil_vozduhan_slow", {
            duration = self:GetSpecialValueFor("shard_slow_duration")
        })
    end

    -- Волна летит дальше и задевает всех на пути
    return false
end

--------------------------------------------------------------------------------
-- ШАРД: ЗАМЕДЛЕНИЕ
--------------------------------------------------------------------------------

modifier_danil_vozduhan_slow = class({})

function modifier_danil_vozduhan_slow:IsHidden() return false end
function modifier_danil_vozduhan_slow:IsDebuff() return true end
function modifier_danil_vozduhan_slow:IsPurgable() return true end

function modifier_danil_vozduhan_slow:OnCreated()
    local ability = self:GetAbility()
    self.slow = ability and not ability:IsNull() and ability:GetSpecialValueFor("shard_slow") or 0
end

function modifier_danil_vozduhan_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_danil_vozduhan_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end

function modifier_danil_vozduhan_slow:GetEffectName()
    return "particles/units/heroes/hero_invoker/invoker_deafening_blast_knockback_debuff.vpcf"
end

function modifier_danil_vozduhan_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

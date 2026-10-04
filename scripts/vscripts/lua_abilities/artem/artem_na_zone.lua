LinkLuaModifier(
    "modifier_artem_na_zone_cage",
    "lua_abilities/artem/artem_na_zone",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_artem_na_zone_disarm",
    "lua_abilities/artem/artem_na_zone",
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_artem_na_zone_break",
    "lua_abilities/artem/artem_na_zone",
    LUA_MODIFIER_MOTION_NONE
)

artem_na_zone = class({})

function artem_na_zone:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:IsNull() then
        return
    end

    -- Linken's Sphere
    if target:TriggerSpellAbsorb(self) then
        return
    end

    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")


    -- Сайленс
    target:AddNewModifier(
        caster,
        self,
        "modifier_silence",
        {
            duration = duration
        }
    )

    -- Дизарм
    target:AddNewModifier(
        caster,
        self,
        "modifier_artem_na_zone_disarm",
        {
            duration = duration
        }
    )

    -- КЛЕТКА
    target:AddNewModifier(
        caster,
        self,
        "modifier_artem_na_zone_cage",
        {
            duration = duration
        }
    )

    -- Талант 25 уровня: истощение
    local break_talent = caster:FindAbilityByName(
        "special_bonus_unique_artem_na_zone_break"
    )

    if break_talent and break_talent:GetLevel() > 0 then
        target:AddNewModifier(
            caster,
            self,
            "modifier_artem_na_zone_break",
            {
                duration = duration
            }
        )
    end

    -- Магический урон
    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self
    })

    caster:EmitSound("Hero_Mars.ArenaOfBlood")
end


--------------------------------------------------------------------------------
-- КЛЕТКА
--------------------------------------------------------------------------------

modifier_artem_na_zone_cage = class({})

function modifier_artem_na_zone_cage:IsHidden()
    return true
end

function modifier_artem_na_zone_cage:IsPurgable()
    return false
end

function modifier_artem_na_zone_cage:RemoveOnDeath()
    return true
end

function modifier_artem_na_zone_cage:OnCreated()
    if not IsServer() then
        return
    end

    self.target = self:GetParent()

    self.particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_furion/furion_sprout_damage_aoe.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )

    self:UpdateParticlePosition()

    self:StartIntervalThink(FrameTime())
end

function modifier_artem_na_zone_cage:OnIntervalThink()
    if not self.target or self.target:IsNull() then
        self:Destroy()
        return
    end

    self:UpdateParticlePosition()
end

function modifier_artem_na_zone_cage:UpdateParticlePosition()
    if not self.particle or self.particle == -1 then
        return
    end

    local position = self.target:GetAbsOrigin()

    ParticleManager:SetParticleControl(
        self.particle,
        0,
        position
    )

    ParticleManager:SetParticleControl(
        self.particle,
        1,
        Vector(180, 180, 180)
    )
end

function modifier_artem_na_zone_cage:OnDestroy()
    if not IsServer() then
        return
    end

    self:StartIntervalThink(-1)

    if self.particle and self.particle ~= -1 then
        ParticleManager:DestroyParticle(
            self.particle,
            false
        )

        ParticleManager:ReleaseParticleIndex(
            self.particle
        )

        self.particle = nil
    end
end


--------------------------------------------------------------------------------
-- ДИЗАРМ
--------------------------------------------------------------------------------

modifier_artem_na_zone_disarm = class({})

function modifier_artem_na_zone_disarm:IsHidden()
    return false
end

function modifier_artem_na_zone_disarm:IsDebuff()
    return true
end

function modifier_artem_na_zone_disarm:IsPurgable()
    return true
end

function modifier_artem_na_zone_disarm:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true
    }
end

function modifier_artem_na_zone_disarm:GetEffectName()
    return "particles/generic_gameplay/generic_disarm.vpcf"
end

function modifier_artem_na_zone_disarm:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end


--------------------------------------------------------------------------------
-- ТАЛАНТ: ИСТОЩЕНИЕ
--------------------------------------------------------------------------------

modifier_artem_na_zone_break = class({})

function modifier_artem_na_zone_break:IsHidden()
    return false
end

function modifier_artem_na_zone_break:IsDebuff()
    return true
end

function modifier_artem_na_zone_break:IsPurgable()
    return true
end

function modifier_artem_na_zone_break:CheckState()
    return {
        [MODIFIER_STATE_PASSIVES_DISABLED] = true
    }
end

function modifier_artem_na_zone_break:GetEffectName()
    return "particles/generic_gameplay/generic_break.vpcf"
end

function modifier_artem_na_zone_break:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

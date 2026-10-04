popchik_milk_rain = class({})

LinkLuaModifier("modifier_popchik_milk_rain_thinker", "abilities/popchik_milk_rain", LUA_MODIFIER_MOTION_NONE)

-- Молочный дождик (шард): область, где враги получают % от макс. HP в секунду,
-- а Попчик лечится на часть этого урона.

function popchik_milk_rain:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function popchik_milk_rain:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    CreateModifierThinker(
        caster,
        self,
        "modifier_popchik_milk_rain_thinker",
        { duration = self:GetSpecialValueFor("duration") },
        point,
        caster:GetTeamNumber(),
        false
    )

    EmitSoundOnLocationWithCaster(point, "Hero_Brewmaster.ThunderClap", caster)
end

--------------------------------------------------------------------------------
-- Зона дождика
--------------------------------------------------------------------------------
modifier_popchik_milk_rain_thinker = class({})

function modifier_popchik_milk_rain_thinker:IsHidden() return true end
function modifier_popchik_milk_rain_thinker:IsPurgable() return false end

function modifier_popchik_milk_rain_thinker:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    self.radius = ability:GetSpecialValueFor("radius")
    self.damage_pct = ability:GetSpecialValueFor("damage_pct_per_sec")
    self.heal_pct = ability:GetSpecialValueFor("heal_pct_per_sec")
    self.tick = ability:GetSpecialValueFor("tick_interval")

    local center = self:GetParent():GetAbsOrigin()
    self.particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_razor/razor_rain_storm.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.particle, 0, center)
    ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, self.radius, self.radius))
    self:AddParticle(self.particle, false, false, -1, false, false)

    self:StartIntervalThink(self.tick)
end

function modifier_popchik_milk_rain_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    if not caster or caster:IsNull() or not ability or ability:IsNull() then
        self:Destroy()
        return
    end

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        self:GetParent():GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, -- не проходит сквозь невосприимчивость к эффектам
        FIND_ANY_ORDER,
        false
    )

    local heal = 0
    for _, enemy in pairs(enemies) do
        local max_hp = enemy:GetMaxHealth()

        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = max_hp * self.damage_pct / 100 * self.tick,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability,
        })

        heal = heal + max_hp * self.heal_pct / 100 * self.tick
    end

    if heal > 0 and caster:IsAlive() then
        caster:Heal(heal, ability)
    end
end

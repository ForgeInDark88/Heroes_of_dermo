artem_vodka_kalyan_shlyuhi = class({})

LinkLuaModifier("modifier_artem_vodka_kalyan_shlyuhi", "lua_abilities/artem/artem_vodka_kalyan_shlyuhi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artem_vodka_liquid_slow", "lua_abilities/artem/artem_vodka_kalyan_shlyuhi", LUA_MODIFIER_MOTION_NONE)

function artem_vodka_kalyan_shlyuhi:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_artem_vodka_kalyan_shlyuhi", { duration = self:GetSpecialValueFor("duration") })
    caster:EmitSound("vodka2")
end

modifier_artem_vodka_kalyan_shlyuhi = class({})

function modifier_artem_vodka_kalyan_shlyuhi:IsPurgable() return false end

function modifier_artem_vodka_kalyan_shlyuhi:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end

    self.radius = ability:GetSpecialValueFor("radius")
    self.slow_duration = ability:GetSpecialValueFor("slow_duration")
    self.slow = ability:GetSpecialValueFor("slow")
    self.think_interval = ability:GetSpecialValueFor("think_interval")

    if IsServer() then
        self.particle = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            self:GetParent()
        )
        ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, self.radius, self.radius))
        self:AddParticle(self.particle, false, false, -1, false, false)
        self:StartIntervalThink(self.think_interval)
    end
end

function modifier_artem_vodka_kalyan_shlyuhi:OnIntervalThink()
    if not IsServer() then return end

    local caster = self:GetParent()
    local ability = self:GetAbility()
    if not caster or caster:IsNull() or not ability or ability:IsNull() then return end

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, ability, "modifier_artem_vodka_liquid_slow", {
            duration = self.slow_duration,
            slow = self.slow,
        })
    end
end

modifier_artem_vodka_liquid_slow = class({})

function modifier_artem_vodka_liquid_slow:IsDebuff() return true end
function modifier_artem_vodka_liquid_slow:IsPurgable() return true end

function modifier_artem_vodka_liquid_slow:OnCreated(kv)
    self.slow = tonumber(kv.slow) or 0
end

function modifier_artem_vodka_liquid_slow:OnRefresh(kv)
    self:OnCreated(kv)
end

function modifier_artem_vodka_liquid_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end

function modifier_artem_vodka_liquid_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

-- Дилдочка: 2. Гнилой пальчик

if dildo_rotten_finger == nil then dildo_rotten_finger = class({}) end

LinkLuaModifier("modifier_dildo_rotten_finger", "abilities/dildochka_2_rotten_finger", LUA_MODIFIER_MOTION_NONE)

require("abilities/dildochka_shared")

function dildo_rotten_finger:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:IsNull() then return end
    if target:TriggerSpellAbsorb(self) then return end

    DildochkaApplyRottenFinger(caster, target, self)
    caster:EmitSound("Hero_Venomancer.VenomousGale")

    local p = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        target
    )
    ParticleManager:SetParticleControl(p, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(p, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(p)
end

modifier_dildo_rotten_finger = class({})

function modifier_dildo_rotten_finger:IsHidden() return false end
function modifier_dildo_rotten_finger:IsDebuff() return true end
function modifier_dildo_rotten_finger:IsPurgable() return true end
function modifier_dildo_rotten_finger:GetTexture() return "marci_sidekick" end

function modifier_dildo_rotten_finger:OnCreated()
    local ability = self:GetAbility()

    self.damage = ability:GetSpecialValueFor("damage_per_second")
    self.magic_reduction = ability:GetSpecialValueFor("magic_resistance_reduction")
    self.radius = ability:GetSpecialValueFor("spread_radius")
    self.interval = ability:GetSpecialValueFor("spread_interval")
    self.caster = self:GetCaster()

    if IsServer() then
        self.particle = ParticleManager:CreateParticle(
            "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
            PATTACH_ABSORIGIN_FOLLOW,
            self:GetParent()
        )
        ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:SetParticleControl(self.particle, 1, self:GetParent():GetAbsOrigin())

        -- Урон тикает раз в секунду, распространение — раз в spread_interval
        self.think = 0.25
        self.damage_timer = self.damage_timer or 0
        self.spread_timer = self.spread_timer or 0
        self:StartIntervalThink(self.think)
    end
end

function modifier_dildo_rotten_finger:OnRefresh()
    if IsServer() and self.particle then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
        self.particle = nil
    end
    self:OnCreated()
end

function modifier_dildo_rotten_finger:DeclareFunctions()
    return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_dildo_rotten_finger:GetModifierMagicalResistanceBonus()
    return -self.magic_reduction
end

function modifier_dildo_rotten_finger:OnIntervalThink()
    if not IsServer() then return end

    local parent = self:GetParent()
    if not parent or parent:IsNull() or not parent:IsAlive() then return end

    self.damage_timer = self.damage_timer + self.think
    self.spread_timer = self.spread_timer + self.think

    if self.damage_timer >= 1.0 - 0.01 then
        self.damage_timer = 0

        ApplyDamage({
            victim = parent,
            attacker = self.caster,
            damage = self.damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })

        parent:EmitSound("Hero_Venomancer.PoisonNovaImpact")
    end

    local spread_interval = self.interval > 0 and self.interval or 1.0
    if self.spread_timer < spread_interval - 0.01 then return end
    self.spread_timer = 0

    local ability = self:GetAbility()
    for _, enemy in pairs(DildochkaGetEnemyUnits(self.caster, parent:GetAbsOrigin(), self.radius)) do
        if enemy ~= parent and enemy:IsAlive() and not enemy:FindModifierByName("modifier_dildo_rotten_finger") then
            DildochkaApplyRottenFinger(self.caster, enemy, ability)
        end
    end
end

function modifier_dildo_rotten_finger:OnDestroy()
    if IsServer() and self.particle then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
        self.particle = nil
    end
end

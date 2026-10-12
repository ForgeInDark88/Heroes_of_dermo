-- Данил: ульта "Сон по 24 часа"
-- Данил откидывается спать (поддерживаемая способность). Пока спит, он
-- неуязвим, а враги в радиусе каждую секунду получают магический урон
-- в процентах от своего максимального здоровья. Против не-героев урон
-- ограничен. Любой приказ будит Данила раньше времени.
-- Аганим: радиус больше, Данил лечится на часть урона по героям.

danil_son_24 = class({})

LinkLuaModifier("modifier_danil_son_24", "abilities/danil_son_24", LUA_MODIFIER_MOTION_NONE)

local TICK_INTERVAL = 0.5

function danil_son_24:GetChannelTime()
    return self:GetSpecialValueFor("duration")
end

function danil_son_24:GetAOERadius()
    local radius = self:GetSpecialValueFor("radius")
    if self:GetCaster():HasScepter() then
        radius = radius + self:GetSpecialValueFor("scepter_bonus_radius")
    end
    return radius
end

function danil_son_24:OnSpellStart()
    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_danil_son_24", {
        duration = self:GetChannelTime() + 0.1
    })
end

function danil_son_24:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_danil_son_24")
end

--------------------------------------------------------------------------------
-- СОН
--------------------------------------------------------------------------------

modifier_danil_son_24 = class({})

function modifier_danil_son_24:IsHidden() return false end
function modifier_danil_son_24:IsDebuff() return false end
function modifier_danil_son_24:IsPurgable() return false end

function modifier_danil_son_24:OnCreated()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.radius = ability:GetAOERadius()
    self.damage_pct = ability:GetSpecialValueFor("damage_pct")
    self.creep_damage_cap = ability:GetSpecialValueFor("creep_damage_cap")
    self.scepter_heal_pct = parent:HasScepter() and ability:GetSpecialValueFor("scepter_heal_pct") or 0

    self.pulse_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.pulse_fx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.pulse_fx, 1, Vector(self.radius, 0, 0))

    self.sleep_fx = ParticleManager:CreateParticle(
        "particles/generic_gameplay/generic_sleep.vpcf",
        PATTACH_OVERHEAD_FOLLOW,
        parent
    )

    parent:EmitSound("Hero_Enigma.Midnight_Pulse")

    self:StartIntervalThink(TICK_INTERVAL)
end

function modifier_danil_son_24:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
        self:Destroy()
        return
    end

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),
        parent:GetAbsOrigin(),
        nil,
        self.radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    local healed = 0

    for _, enemy in pairs(enemies) do
        local damage = enemy:GetMaxHealth() * self.damage_pct / 100 * TICK_INTERVAL
        if not enemy:IsHero() then
            damage = math.min(damage, self.creep_damage_cap * TICK_INTERVAL)
        end

        local dealt = ApplyDamage({
            victim = enemy,
            attacker = parent,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability,
        })

        if enemy:IsRealHero() then
            healed = healed + dealt
        end
    end

    if self.scepter_heal_pct > 0 and healed > 0 then
        parent:Heal(healed * self.scepter_heal_pct / 100, ability)
    end
end

function modifier_danil_son_24:OnDestroy()
    if not IsServer() then return end

    for _, key in ipairs({ "pulse_fx", "sleep_fx" }) do
        if self[key] then
            ParticleManager:DestroyParticle(self[key], false)
            ParticleManager:ReleaseParticleIndex(self[key])
            self[key] = nil
        end
    end

    self:GetParent():StopSound("Hero_Enigma.Midnight_Pulse")
end

function modifier_danil_son_24:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

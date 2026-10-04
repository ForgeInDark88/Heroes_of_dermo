artem_vodka_kalyan_shlyuhi = class({})

LinkLuaModifier("modifier_artem_vodka_kalyan_shlyuhi", "lua_abilities/artem/artem_vodka_kalyan_shlyuhi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artem_vodka_liquid_slow", "lua_abilities/artem/artem_vodka_kalyan_shlyuhi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_artem_vodyara", "lua_abilities/artem/artem_vodka_kalyan_shlyuhi", LUA_MODIFIER_MOTION_NONE)

-- Снимает все положительные эффекты с врагов в радиусе ульты
local function DispelEnemies(caster, radius)
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        caster:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        -- RemovePositiveBuffs, RemoveDebuffs, FrameOnly, RemoveStuns, RemoveExceptions
        enemy:Purge(true, false, false, false, true)
    end
end

-- Врождёнка Мукбанг прокачивается вместе с ультой
function artem_vodka_kalyan_shlyuhi:OnUpgrade()
    if not IsServer() then return end

    local mukbang = self:GetCaster():FindAbilityByName("artem_mukbang")
    if mukbang and mukbang.SyncLevelWithUltimate then
        mukbang:SyncLevelWithUltimate()
    end
end

function artem_vodka_kalyan_shlyuhi:OnSpellStart()
    local caster = self:GetCaster()

    -- Диспел в начале каста
    DispelEnemies(caster, self:GetSpecialValueFor("radius"))

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

function modifier_artem_vodka_kalyan_shlyuhi:OnDestroy()
    if not IsServer() then return end

    -- Диспел в конце каста
    local caster = self:GetParent()
    if caster and not caster:IsNull() and caster:IsAlive() then
        DispelEnemies(caster, self.radius)
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

-- Аганим: атаки во время ульты накладывают "водяру"
function modifier_artem_vodka_kalyan_shlyuhi:OnAttackLanded(params)
    if not IsServer() then return end

    local caster = self:GetParent()
    if params.attacker ~= caster then return end
    if not caster:HasScepter() then return end

    local target = params.target
    if not target or target:IsNull() or target:IsBuilding() then return end
    if target:GetTeamNumber() == caster:GetTeamNumber() then return end

    target:AddNewModifier(caster, self:GetAbility(), "modifier_artem_vodyara", {
        duration = self:GetRemainingTime(),
    })
end

function modifier_artem_vodka_kalyan_shlyuhi:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
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

--------------------------------------------------------------------------------
-- АГАНИМ: ВОДЯРА
-- Урон в секунду % от макс. HP цели и снижение сопротивления эффектам.
-- Висит, пока у Артёма активна ульта.
--------------------------------------------------------------------------------

modifier_artem_vodyara = class({})

function modifier_artem_vodyara:IsHidden() return false end
function modifier_artem_vodyara:IsDebuff() return true end
function modifier_artem_vodyara:IsPurgable() return true end
function modifier_artem_vodyara:GetTexture() return "item_ultimate_scepter" end

function modifier_artem_vodyara:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end

    self.damage_pct = ability:GetSpecialValueFor("scepter_vodyara_damage_pct")
    self.status_resist = ability:GetSpecialValueFor("scepter_vodyara_status_resist")
    self.tick = ability:GetSpecialValueFor("scepter_vodyara_tick")

    if IsServer() then
        self:StartIntervalThink(self.tick)
    end
end

function modifier_artem_vodyara:OnRefresh()
    self:OnCreated()
end

function modifier_artem_vodyara:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    -- Ульта закончилась (или Артём умер) — снимаем дебафф
    if not caster or caster:IsNull() or not caster:HasModifier("modifier_artem_vodka_kalyan_shlyuhi") then
        self:Destroy()
        return
    end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = parent:GetMaxHealth() * self.damage_pct / 100 * self.tick,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility(),
    })
end

function modifier_artem_vodyara:GetModifierStatusResistanceStacking()
    return -(self.status_resist or 0)
end

function modifier_artem_vodyara:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING }
end

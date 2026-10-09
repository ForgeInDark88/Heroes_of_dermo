-- Русик: 1. Яблочки
-- Отправляет героя в яблочки Даванкова: цель пропадает с карты (как Astral
-- Imprisonment) — неуязвима и вне игры. По возвращении вокруг неё бьёт волна
-- магического урона по врагам.
--   Враг: Русик забирает у него силу на время.
--   Союзник: союзник возвращается с бонусом к силе и урону атаки.
-- Талант: -5 сек. к перезарядке (cooldown_reduction).

rusik_yablochki = class({})

LinkLuaModifier("modifier_rusik_yablochki_banish", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_steal_debuff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_steal_buff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_ally_buff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)

function rusik_yablochki:GetCooldown(level)
    local cooldown = self.BaseClass.GetCooldown(self, level)
    return math.max(0, cooldown - self:GetSpecialValueFor("cooldown_reduction"))
end

function rusik_yablochki:CastFilterResultTarget(target)
    if target == self:GetCaster() then
        return UF_FAIL_CUSTOM
    end
    return UnitFilter(
        target,
        self:GetAbilityTargetTeam(),
        self:GetAbilityTargetType(),
        self:GetAbilityTargetFlags(),
        self:GetCaster():GetTeamNumber()
    )
end

function rusik_yablochki:GetCustomCastErrorTarget(target)
    if target == self:GetCaster() then
        return "#dota_hud_error_cant_cast_on_self"
    end
    return ""
end

function rusik_yablochki:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then
        return
    end

    target:AddNewModifier(caster, self, "modifier_rusik_yablochki_banish", {
        duration = self:GetSpecialValueFor("banish_duration")
    })

    target:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment")
end

function rusik_yablochki:OnBanishEnd(target)
    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not target or target:IsNull() then return end

    local origin = target:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison_end_dmg.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(fx, 0, origin)
    ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(fx)

    target:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment.End")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    local damage = self:GetSpecialValueFor("damage")
    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })
    end

    if not target:IsAlive() then return end

    if target:GetTeamNumber() == caster:GetTeamNumber() then
        target:AddNewModifier(caster, self, "modifier_rusik_yablochki_ally_buff", {
            duration = self:GetSpecialValueFor("ally_buff_duration")
        })
    elseif target:IsRealHero() then
        local steal = self:GetSpecialValueFor("strength_steal")
        local duration = self:GetSpecialValueFor("steal_duration")
        target:AddNewModifier(caster, self, "modifier_rusik_yablochki_steal_debuff", {
            duration = duration,
            amount = steal,
        })
        if caster:IsAlive() then
            caster:AddNewModifier(caster, self, "modifier_rusik_yablochki_steal_buff", {
                duration = duration,
                amount = steal,
            })
        end
    end
end

--------------------------------------------------------------------------------
-- В ЯБЛОЧКАХ: цель пропадает с карты
--------------------------------------------------------------------------------

modifier_rusik_yablochki_banish = class({})

function modifier_rusik_yablochki_banish:IsHidden() return false end
function modifier_rusik_yablochki_banish:IsDebuff()
    return self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
end
function modifier_rusik_yablochki_banish:IsPurgable() return false end

function modifier_rusik_yablochki_banish:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    self.fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.fx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.fx, 2, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.fx, 3, parent:GetAbsOrigin())

    parent:AddNoDraw()
    parent:Stop()
end

function modifier_rusik_yablochki_banish:OnDestroy()
    if not IsServer() then return end

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
    end

    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end
    parent:RemoveNoDraw()

    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
        ability:OnBanishEnd(parent)
    end
end

function modifier_rusik_yablochki_banish:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

--------------------------------------------------------------------------------
-- КРАЖА СИЛЫ (каждое применение — отдельный экземпляр)
--------------------------------------------------------------------------------

modifier_rusik_yablochki_steal_debuff = class({})

function modifier_rusik_yablochki_steal_debuff:IsHidden() return false end
function modifier_rusik_yablochki_steal_debuff:IsDebuff() return true end
function modifier_rusik_yablochki_steal_debuff:IsPurgable() return false end
function modifier_rusik_yablochki_steal_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_rusik_yablochki_steal_debuff:OnCreated(kv)
    if not IsServer() then return end
    self:SetStackCount(kv.amount or 0)
end

function modifier_rusik_yablochki_steal_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_rusik_yablochki_steal_debuff:GetModifierBonusStats_Strength()
    return -self:GetStackCount()
end

modifier_rusik_yablochki_steal_buff = class({})

function modifier_rusik_yablochki_steal_buff:IsHidden() return false end
function modifier_rusik_yablochki_steal_buff:IsPurgable() return false end
function modifier_rusik_yablochki_steal_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_rusik_yablochki_steal_buff:OnCreated(kv)
    if not IsServer() then return end
    self:SetStackCount(kv.amount or 0)
end

function modifier_rusik_yablochki_steal_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_rusik_yablochki_steal_buff:GetModifierBonusStats_Strength()
    return self:GetStackCount()
end

--------------------------------------------------------------------------------
-- СОЮЗНИК: сила и урон атаки
--------------------------------------------------------------------------------

modifier_rusik_yablochki_ally_buff = class({})

function modifier_rusik_yablochki_ally_buff:IsHidden() return false end
function modifier_rusik_yablochki_ally_buff:IsPurgable() return true end

function modifier_rusik_yablochki_ally_buff:OnCreated()
    local ability = self:GetAbility()
    self.strength = ability and ability:GetSpecialValueFor("ally_bonus_strength") or 0
    self.damage = ability and ability:GetSpecialValueFor("ally_bonus_damage") or 0
end

function modifier_rusik_yablochki_ally_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_rusik_yablochki_ally_buff:GetModifierBonusStats_Strength()
    return self.strength
end

function modifier_rusik_yablochki_ally_buff:GetModifierPreAttack_BonusDamage()
    return self.damage
end

function modifier_rusik_yablochki_ally_buff:GetEffectName()
    return "particles/econ/generic/generic_buff_1/generic_buff_1.vpcf"
end

function modifier_rusik_yablochki_ally_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

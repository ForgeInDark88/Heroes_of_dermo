-- Русик: 1. Яблочки
-- Отправляет героя в яблочки к Даванкову: цель пропадает с карты (как Astral
-- Imprisonment), а по возвращении:
--   * враг получает магический урон и отдаёт Русику силу на время;
--   * союзник получает бонус к урону атаки и силе.

rusik_yablochki = class({})

LinkLuaModifier("modifier_rusik_yablochki_prison", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_str_debuff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_str_buff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rusik_yablochki_ally_buff", "abilities/rusik_yablochki", LUA_MODIFIER_MOTION_NONE)

function rusik_yablochki:GetCooldown(level)
    return math.max(0, self.BaseClass.GetCooldown(self, level) - self:GetSpecialValueFor("cooldown_reduction"))
end

function rusik_yablochki:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    if not target or target:IsNull() then return end

    if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then
        return
    end

    target:AddNewModifier(caster, self, "modifier_rusik_yablochki_prison", {
        duration = self:GetSpecialValueFor("prison_duration")
    })
end

--------------------------------------------------------------------------------
-- В ЯБЛОЧКАХ У ДАВАНКОВА
--------------------------------------------------------------------------------

modifier_rusik_yablochki_prison = class({})

function modifier_rusik_yablochki_prison:IsHidden() return false end
function modifier_rusik_yablochki_prison:IsPurgable() return false end

function modifier_rusik_yablochki_prison:IsDebuff()
    return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber()
end

function modifier_rusik_yablochki_prison:CheckState()
    return {
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end

function modifier_rusik_yablochki_prison:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local origin = parent:GetAbsOrigin()

    self.fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison.vpcf",
        PATTACH_WORLDORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(self.fx, 0, origin)
    ParticleManager:SetParticleControl(self.fx, 2, origin)
    ParticleManager:SetParticleControl(self.fx, 3, origin)

    parent:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment")
    parent:AddNoDraw()
end

function modifier_rusik_yablochki_prison:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if self.fx then
        ParticleManager:DestroyParticle(self.fx, false)
        ParticleManager:ReleaseParticleIndex(self.fx)
    end

    if parent:IsNull() then return end

    parent:RemoveNoDraw()
    FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
    parent:StopSound("Hero_ObsidianDestroyer.AstralImprisonment")
    parent:EmitSound("Hero_ObsidianDestroyer.AstralImprisonment.End")

    local end_fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison_end_dmg.vpcf",
        PATTACH_ABSORIGIN,
        parent
    )
    ParticleManager:SetParticleControl(end_fx, 0, parent:GetAbsOrigin())
    Timers:CreateTimer(2.0, function()
        ParticleManager:DestroyParticle(end_fx, false)
        ParticleManager:ReleaseParticleIndex(end_fx)
    end)

    if not ability or ability:IsNull() or not caster or caster:IsNull() then return end
    if not parent:IsAlive() then return end

    local duration = ability:GetSpecialValueFor("steal_duration")

    if parent:GetTeamNumber() == caster:GetTeamNumber() then
        parent:AddNewModifier(caster, ability, "modifier_rusik_yablochki_ally_buff", { duration = duration })
        return
    end

    ApplyDamage({
        victim = parent,
        attacker = caster,
        damage = ability:GetSpecialValueFor("damage"),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability,
    })

    if parent:IsRealHero() then
        parent:AddNewModifier(caster, ability, "modifier_rusik_yablochki_str_debuff", { duration = duration })
        caster:AddNewModifier(caster, ability, "modifier_rusik_yablochki_str_buff", { duration = duration })
    end
end

--------------------------------------------------------------------------------
-- КРАЖА СИЛЫ (у врага минус, у Русика плюс; стаки независимые)
--------------------------------------------------------------------------------

modifier_rusik_yablochki_str_debuff = class({})

function modifier_rusik_yablochki_str_debuff:IsHidden() return false end
function modifier_rusik_yablochki_str_debuff:IsDebuff() return true end
function modifier_rusik_yablochki_str_debuff:IsPurgable() return false end
function modifier_rusik_yablochki_str_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_rusik_yablochki_str_debuff:OnCreated()
    local ability = self:GetAbility()
    self.str = ability and ability:GetSpecialValueFor("str_steal") or 0
end

function modifier_rusik_yablochki_str_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_rusik_yablochki_str_debuff:GetModifierBonusStats_Strength()
    return -self.str
end

modifier_rusik_yablochki_str_buff = class({})

function modifier_rusik_yablochki_str_buff:IsHidden() return false end
function modifier_rusik_yablochki_str_buff:IsPurgable() return false end
function modifier_rusik_yablochki_str_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_rusik_yablochki_str_buff:OnCreated()
    local ability = self:GetAbility()
    self.str = ability and ability:GetSpecialValueFor("str_steal") or 0
end

function modifier_rusik_yablochki_str_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_rusik_yablochki_str_buff:GetModifierBonusStats_Strength()
    return self.str
end

--------------------------------------------------------------------------------
-- СОЮЗНИК ВЕРНУЛСЯ ИЗ ЯБЛОЧЕК: + к урону и силе
--------------------------------------------------------------------------------

modifier_rusik_yablochki_ally_buff = class({})

function modifier_rusik_yablochki_ally_buff:IsHidden() return false end
function modifier_rusik_yablochki_ally_buff:IsPurgable() return true end

function modifier_rusik_yablochki_ally_buff:OnCreated()
    local ability = self:GetAbility()
    self.str = ability and ability:GetSpecialValueFor("str_steal") or 0
    self.damage = ability and ability:GetSpecialValueFor("ally_bonus_damage") or 0
end

function modifier_rusik_yablochki_ally_buff:OnRefresh()
    self:OnCreated()
end

function modifier_rusik_yablochki_ally_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_rusik_yablochki_ally_buff:GetModifierBonusStats_Strength()
    return self.str
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

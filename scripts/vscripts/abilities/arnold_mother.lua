-- Арнольд: ульта "Мать прекрасная женщина"
-- Звуковая волна вокруг: магический урон, безмолвие и замедление.
-- Проходит сквозь невосприимчивость к эффектам, дебафф можно развеять.
-- Аганим: -30 сек к перезарядке и максимальная скорость на 1 сек.

arnold_mother = class({})

LinkLuaModifier("modifier_arnold_mother_debuff", "abilities/arnold_mother", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arnold_mother_haste", "abilities/arnold_mother", LUA_MODIFIER_MOTION_NONE)

function arnold_mother:GetCooldown(level)
    local cooldown = self.BaseClass.GetCooldown(self, level)
    local caster = self:GetCaster()
    if caster and caster:HasScepter() then
        cooldown = cooldown - self:GetSpecialValueFor("scepter_cooldown_reduction")
    end
    return math.max(0, cooldown)
end

function arnold_mother:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")

    local fx = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf",
        PATTACH_ABSORIGIN,
        caster
    )
    ParticleManager:SetParticleControl(fx, 0, origin)
    Timers:CreateTimer(2.0, function()
        ParticleManager:DestroyParticle(fx, false)
        ParticleManager:ReleaseParticleIndex(fx)
    end)

    caster:EmitSound("Hero_QueenOfPain.ScreamOfPain")

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        origin,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- проходит сквозь невосприимчивость
        FIND_ANY_ORDER,
        false
    )

    for _, enemy in pairs(enemies) do
        ApplyDamage({
            victim = enemy,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })

        enemy:AddNewModifier(caster, self, "modifier_arnold_mother_debuff", { duration = duration })
    end

    if caster:HasScepter() then
        caster:AddNewModifier(caster, self, "modifier_arnold_mother_haste", {
            duration = self:GetSpecialValueFor("scepter_max_speed_duration")
        })
    end
end

--------------------------------------------------------------------------------
-- ДЕБАФФ: безмолвие + замедление
--------------------------------------------------------------------------------

modifier_arnold_mother_debuff = class({})

function modifier_arnold_mother_debuff:IsHidden() return false end
function modifier_arnold_mother_debuff:IsDebuff() return true end
function modifier_arnold_mother_debuff:IsPurgable() return true end

function modifier_arnold_mother_debuff:OnCreated()
    local ability = self:GetAbility()
    self.slow = ability and ability:GetSpecialValueFor("slow") or 0
end

function modifier_arnold_mother_debuff:CheckState()
    return { [MODIFIER_STATE_SILENCED] = true }
end

function modifier_arnold_mother_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_arnold_mother_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end

function modifier_arnold_mother_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_arnold_mother_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------
-- АГАНИМ: максимальная скорость передвижения
--------------------------------------------------------------------------------

modifier_arnold_mother_haste = class({})

function modifier_arnold_mother_haste:IsHidden() return false end
function modifier_arnold_mother_haste:IsPurgable() return true end

function modifier_arnold_mother_haste:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE }
end

function modifier_arnold_mother_haste:GetModifierMoveSpeed_Absolute()
    return 550
end

function modifier_arnold_mother_haste:GetEffectName()
    return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function modifier_arnold_mother_haste:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

chmoshnik = class({})
LinkLuaModifier("modifier_chmoshnik_attack_speed", "abilities/chmoshnik", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chmoshnik_root", "abilities/chmoshnik", LUA_MODIFIER_MOTION_NONE)

function chmoshnik:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:TriggerSpellAbsorb(self) then
        return
    end

    -- Получаем значения из AbilityValues с учетом уровня
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")
    local root_duration = self:GetSpecialValueFor("root_duration")

    -- Воспроизводим звук
    caster:EmitSound("chmoshnik")

    -- Наносим маг. урон
    ApplyDamage({
        victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })

    -- Накладываем оцепенение на цель
    target:AddNewModifier(caster, self, "modifier_chmoshnik_root", { duration = root_duration })

    -- Даём себе бонус скорости атаки
    caster:AddNewModifier(caster, self, "modifier_chmoshnik_attack_speed", { duration = duration })
end

--------------------------------------------------------------------------------
-- Модификатор оцепенения (Root)
--------------------------------------------------------------------------------
modifier_chmoshnik_root = class({})

function modifier_chmoshnik_root:IsHidden() return false end
function modifier_chmoshnik_root:IsDebuff() return true end
function modifier_chmoshnik_root:IsPurgable() return true end

function modifier_chmoshnik_root:GetEffectName()
    return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_chmoshnik_root:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_chmoshnik_root:CheckState()
    return {
        [MODIFIER_STATE_ROOTED] = true,
    }
end

--------------------------------------------------------------------------------
-- Бонус скорости атаки
--------------------------------------------------------------------------------
modifier_chmoshnik_attack_speed = class({})

function modifier_chmoshnik_attack_speed:IsHidden() return false end
function modifier_chmoshnik_attack_speed:IsDebuff() return false end
function modifier_chmoshnik_attack_speed:IsPurgable() return true end

function modifier_chmoshnik_attack_speed:OnCreated()
    local ability = self:GetAbility()
    self.attack_speed = ability and ability:GetSpecialValueFor("bonus_attack_speed") or 0
end

function modifier_chmoshnik_attack_speed:OnRefresh()
    self:OnCreated()
end

function modifier_chmoshnik_attack_speed:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_chmoshnik_attack_speed:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

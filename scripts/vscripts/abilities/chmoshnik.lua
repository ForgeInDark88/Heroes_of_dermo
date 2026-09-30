chmoshnik = class({})
LinkLuaModifier("modifier_chmoshnik_invis", "abilities/chmoshnik", LUA_MODIFIER_MOTION_NONE)
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

    -- Накладываем невидимость на себя
    caster:AddNewModifier(caster, self, "modifier_chmoshnik_invis", { duration = duration })
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
-- Модификатор невидимости (Invis)
--------------------------------------------------------------------------------
modifier_chmoshnik_invis = class({})

function modifier_chmoshnik_invis:IsHidden() return false end
function modifier_chmoshnik_invis:IsDebuff() return false end
function modifier_chmoshnik_invis:IsPurgable() return true end

function modifier_chmoshnik_invis:CheckState()
    return {
        [MODIFIER_STATE_INVISIBLE] = true,
    }
end

function modifier_chmoshnik_invis:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
        MODIFIER_EVENT_ON_ATTACK_START,     -- Для сброса инвиза в начале замаха/атаки
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    }
end

function modifier_chmoshnik_invis:GetModifierInvisibilityLevel()
    return 1
end
-- Сбрасываем невидимость при начале атаки
function modifier_chmoshnik_invis:OnAttackStart(keys)
    if keys.attacker == self:GetParent() then
        self:Destroy()
    end
end

-- Сбрасываем невидимость при касте любого скилла (или предмета)
function modifier_chmoshnik_invis:OnAbilityExecuted(keys)
    if keys.unit == self:GetParent() then
        self:Destroy()
    end
end
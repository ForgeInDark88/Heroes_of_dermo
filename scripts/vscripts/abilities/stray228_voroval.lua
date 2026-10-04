LinkLuaModifier(
    "modifier_stray228_voroval_debuff",
    "abilities/stray228_voroval.lua",
    LUA_MODIFIER_MOTION_NONE
)
LinkLuaModifier(
    "modifier_stray228_voroval_buff",
    "abilities/stray228_voroval.lua",
    LUA_MODIFIER_MOTION_NONE
)

--------------------------------------------------------------------------------
-- ВОРОВАЛ: ворует у цели ВСЮ броню на время и забирает её себе
--------------------------------------------------------------------------------

stray228_voroval = class({})

function stray228_voroval:OnSpellStart()
    if not IsServer() then
        return
    end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target then
        return
    end

    if target:TriggerSpellAbsorb(self) then
        return
    end

    local duration = self:GetSpecialValueFor("steal_duration")

    -- Если уже обокраден - снимаем старый дебафф, чтобы посчитать броню заново
    target:RemoveModifierByName("modifier_stray228_voroval_debuff")

    local armor = target:GetPhysicalArmorValue(false)

    if armor <= 0 then
        print("[STRAY228] Voroval: target has no armor to steal")
        return
    end

    target:AddNewModifier(
        caster,
        self,
        "modifier_stray228_voroval_debuff",
        {
            duration = duration,
            stolen_armor = armor
        }
    )

    caster:AddNewModifier(
        caster,
        self,
        "modifier_stray228_voroval_buff",
        {
            duration = duration,
            stolen_armor = armor
        }
    )

    EmitSoundOn("Hero_Slardar.Amplify_Damage", target)

    print("[STRAY228] Voroval: stolen " .. tostring(armor) .. " armor from " .. target:GetUnitName())
end

--------------------------------------------------------------------------------
-- Дебафф на цели: минус вся броня
--------------------------------------------------------------------------------

modifier_stray228_voroval_debuff = class({})

function modifier_stray228_voroval_debuff:IsHidden()
    return false
end

function modifier_stray228_voroval_debuff:IsDebuff()
    return true
end

function modifier_stray228_voroval_debuff:IsPurgable()
    return false
end

function modifier_stray228_voroval_debuff:OnCreated(kv)
    if not IsServer() then
        return
    end

    self.stolen_armor = tonumber(kv.stolen_armor) or 0
    self:SetStackCount(math.floor(self.stolen_armor + 0.5))
end

function modifier_stray228_voroval_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_stray228_voroval_debuff:GetModifierPhysicalArmorBonus()
    -- На клиенте используем stack count, чтобы тултип показывал верное значение
    if IsServer() then
        return -self.stolen_armor
    end

    return -self:GetStackCount()
end

function modifier_stray228_voroval_debuff:GetEffectName()
    return "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf"
end

function modifier_stray228_voroval_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------
-- Бафф на боссе: плюс украденная броня
--------------------------------------------------------------------------------

modifier_stray228_voroval_buff = class({})

function modifier_stray228_voroval_buff:IsHidden()
    return false
end

function modifier_stray228_voroval_buff:IsPurgable()
    return false
end

function modifier_stray228_voroval_buff:GetAttributes()
    -- Если украл у нескольких героев - броня складывается
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_stray228_voroval_buff:OnCreated(kv)
    if not IsServer() then
        return
    end

    self.stolen_armor = tonumber(kv.stolen_armor) or 0
    self:SetStackCount(math.floor(self.stolen_armor + 0.5))
end

function modifier_stray228_voroval_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_stray228_voroval_buff:GetModifierPhysicalArmorBonus()
    if IsServer() then
        return self.stolen_armor
    end

    return self:GetStackCount()
end

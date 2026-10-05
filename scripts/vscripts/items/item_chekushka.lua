------------------------------------------------------------
-- ЧЕКУШКА
-- Пассивно: все атрибуты, реген маны и здоровья.
-- Активка "Sushnyak": тратит заряд и восстанавливает здоровье
-- и ману за несколько секунд. Сбивается уроном от героя.
-- Заряды: +1 каждые charge_interval сек (до max_charges),
-- у союзного фонтана заполняются полностью. Руны не хранит.
------------------------------------------------------------

LinkLuaModifier("modifier_item_chekushka", "items/item_chekushka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_chekushka_sushnyak", "items/item_chekushka", LUA_MODIFIER_MOTION_NONE)

item_chekushka = class({})

function item_chekushka:GetIntrinsicModifierName()
    return "modifier_item_chekushka"
end

function item_chekushka:CastFilterResult()
    if self:GetCurrentCharges() <= 0 then
        return UF_FAIL_CUSTOM
    end
    return UF_SUCCESS
end

function item_chekushka:GetCustomCastError()
    return "#dota_hud_error_no_charges"
end

function item_chekushka:OnSpellStart()
    local caster = self:GetCaster()
    local charges = self:GetCurrentCharges()
    if charges <= 0 then return end

    self:SetCurrentCharges(charges - 1)

    caster:AddNewModifier(caster, self, "modifier_item_chekushka_sushnyak", {
        duration = self:GetSpecialValueFor("restore_duration")
    })

    caster:EmitSound("Bottle.Drink")
end

------------------------------------------------------------
-- ПАССИВКА + НАКОПЛЕНИЕ ЗАРЯДОВ
------------------------------------------------------------

modifier_item_chekushka = class({})

function modifier_item_chekushka:IsHidden() return true end
function modifier_item_chekushka:IsPurgable() return false end
function modifier_item_chekushka:RemoveOnDeath() return false end
function modifier_item_chekushka:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

local THINK = 0.25

function modifier_item_chekushka:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end

    self.all_stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.health_regen = ability:GetSpecialValueFor("bonus_health_regen")

    if IsServer() then
        self.charge_timer = 0
        self:StartIntervalThink(THINK)
    end
end

function modifier_item_chekushka:OnIntervalThink()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    if not ability or ability:IsNull() then return end

    local max_charges = ability:GetSpecialValueFor("max_charges")
    local charges = ability:GetCurrentCharges()

    -- У союзного фонтана заряды заполняются полностью
    if parent:HasModifier("modifier_fountain_aura_buff") then
        if charges < max_charges then
            ability:SetCurrentCharges(max_charges)
        end
        self.charge_timer = 0
        return
    end

    if charges >= max_charges then
        self.charge_timer = 0
        return
    end

    self.charge_timer = self.charge_timer + THINK
    if self.charge_timer >= ability:GetSpecialValueFor("charge_interval") then
        self.charge_timer = 0
        ability:SetCurrentCharges(charges + 1)
    end
end

function modifier_item_chekushka:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
end

function modifier_item_chekushka:GetModifierBonusStats_Strength() return self.all_stats or 0 end
function modifier_item_chekushka:GetModifierBonusStats_Agility() return self.all_stats or 0 end
function modifier_item_chekushka:GetModifierBonusStats_Intellect() return self.all_stats or 0 end
function modifier_item_chekushka:GetModifierConstantManaRegen() return self.mana_regen or 0 end
function modifier_item_chekushka:GetModifierConstantHealthRegen() return self.health_regen or 0 end

------------------------------------------------------------
-- СУШНЯК: восстановление, сбивается уроном от героя
------------------------------------------------------------

modifier_item_chekushka_sushnyak = class({})

function modifier_item_chekushka_sushnyak:IsHidden() return false end
function modifier_item_chekushka_sushnyak:IsDebuff() return false end
function modifier_item_chekushka_sushnyak:IsPurgable() return true end
function modifier_item_chekushka_sushnyak:GetTexture() return "item_bottle" end

function modifier_item_chekushka_sushnyak:GetEffectName()
    return "particles/items_fx/bottle.vpcf"
end

function modifier_item_chekushka_sushnyak:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_chekushka_sushnyak:OnCreated()
    local ability = self:GetAbility()
    local duration = math.max(0.1, self:GetDuration())

    self.health_per_sec = (ability and ability:GetSpecialValueFor("restore_health") or 0) / duration
    self.mana_per_sec = (ability and ability:GetSpecialValueFor("restore_mana") or 0) / duration
end

function modifier_item_chekushka_sushnyak:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_item_chekushka_sushnyak:GetModifierConstantHealthRegen() return self.health_per_sec end
function modifier_item_chekushka_sushnyak:GetModifierConstantManaRegen() return self.mana_per_sec end

function modifier_item_chekushka_sushnyak:OnTakeDamage(params)
    if not IsServer() then return end
    if params.unit ~= self:GetParent() then return end
    if params.damage <= 0 then return end

    local attacker = params.attacker
    if attacker and not attacker:IsNull() and attacker:IsHero()
        and attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        self:Destroy()
    end
end

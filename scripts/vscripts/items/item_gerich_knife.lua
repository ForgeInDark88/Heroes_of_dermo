------------------------------------------------------------
-- GERICH'S KNIFE
-- Пассивно: сила, сопротивление замедлениям, усиление
-- восстановления здоровья, броня.
-- Активка: шприц герыча — цель в ярости атакует владельца
-- предмета с повышенной скоростью атаки. Если за это время
-- цель убьёт владельца, она лечится на % от макс. здоровья.
------------------------------------------------------------

LinkLuaModifier("modifier_item_gerich_knife", "items/item_gerich_knife", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_gerich_knife_rage", "items/item_gerich_knife", LUA_MODIFIER_MOTION_NONE)

item_gerich_knife = class({})

function item_gerich_knife:GetIntrinsicModifierName()
    return "modifier_item_gerich_knife"
end

function item_gerich_knife:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target:IsNull() then return end
    if target:TriggerSpellAbsorb(self) then return end

    target:AddNewModifier(caster, self, "modifier_item_gerich_knife_rage", {
        duration = self:GetSpecialValueFor("rage_duration")
    })

    caster:EmitSound("Hero_Axe.Berserkers_Call")
end

------------------------------------------------------------
-- ПАССИВКА
------------------------------------------------------------

modifier_item_gerich_knife = class({})

function modifier_item_gerich_knife:IsHidden() return true end
function modifier_item_gerich_knife:IsPurgable() return false end
function modifier_item_gerich_knife:RemoveOnDeath() return false end
function modifier_item_gerich_knife:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_gerich_knife:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end

    self.strength = ability:GetSpecialValueFor("bonus_strength")
    self.slow_resistance = ability:GetSpecialValueFor("slow_resistance")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
end

function modifier_item_gerich_knife:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_SLOW_RESISTANCE_UNIQUE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_item_gerich_knife:GetModifierBonusStats_Strength() return self.strength or 0 end
function modifier_item_gerich_knife:GetModifierSlowResistance_Unique() return self.slow_resistance or 0 end
function modifier_item_gerich_knife:GetModifierHPRegenAmplify_Percentage() return self.hp_regen_amp or 0 end
function modifier_item_gerich_knife:GetModifierHealAmplify_PercentageTarget() return self.hp_regen_amp or 0 end
function modifier_item_gerich_knife:GetModifierPhysicalArmorBonus() return self.armor or 0 end

------------------------------------------------------------
-- ЯРОСТЬ (на враге)
------------------------------------------------------------

modifier_item_gerich_knife_rage = class({})

function modifier_item_gerich_knife_rage:IsHidden() return false end
function modifier_item_gerich_knife_rage:IsDebuff() return true end
function modifier_item_gerich_knife_rage:IsPurgable() return true end
function modifier_item_gerich_knife_rage:GetTexture() return "item_sange" end

function modifier_item_gerich_knife_rage:GetEffectName()
    return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_item_gerich_knife_rage:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_item_gerich_knife_rage:OnCreated()
    local ability = self:GetAbility()
    self.attack_speed = ability and ability:GetSpecialValueFor("rage_attack_speed") or 0
    self.heal_pct = ability and ability:GetSpecialValueFor("kill_heal_pct") or 0

    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()

    parent:SetForceAttackTarget(caster)
    parent:MoveToTargetToAttack(caster)

    self:StartIntervalThink(0.1)
end

function modifier_item_gerich_knife_rage:OnIntervalThink()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() or not caster:IsAlive() then
        self:Destroy()
    end
end

function modifier_item_gerich_knife_rage:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()
    if parent and not parent:IsNull() then
        parent:SetForceAttackTarget(nil)
    end
end

function modifier_item_gerich_knife_rage:CheckState()
    return {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    }
end

function modifier_item_gerich_knife_rage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_EVENT_ON_DEATH,
    }
end

function modifier_item_gerich_knife_rage:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

-- Убил владельца предмета — лечится
function modifier_item_gerich_knife_rage:OnDeath(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    if params.attacker ~= parent then return end
    if params.unit ~= self:GetCaster() then return end

    parent:Heal(parent:GetMaxHealth() * self.heal_pct / 100, self:GetAbility())
end

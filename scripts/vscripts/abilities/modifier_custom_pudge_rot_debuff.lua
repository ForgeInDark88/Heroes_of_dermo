modifier_custom_pudge_rot_debuff = class({})

function modifier_custom_pudge_rot_debuff:IsHidden() return false end
function modifier_custom_pudge_rot_debuff:IsDebuff() return true end
function modifier_custom_pudge_rot_debuff:IsPurgable() return true end

-- Иконка дебаффа в статусе юнита (рот паджа)
function modifier_custom_pudge_rot_debuff:GetTexture()
    return "pudge_rot"
end

function modifier_custom_pudge_rot_debuff:OnCreated()
    self:UpdateValues()
end

function modifier_custom_pudge_rot_debuff:OnRefresh()
    self:UpdateValues()
end

function modifier_custom_pudge_rot_debuff:UpdateValues()
    local ability = self:GetAbility()
    if ability then
        self.slow_pct = ability:GetSpecialValueFor("shard_slow_pct")
        self.heal_reduce_pct = ability:GetSpecialValueFor("shard_heal_reduce_pct")
    else
        self.slow_pct = -10
        self.heal_reduce_pct = -10
    end

    -- Переводим в отрицательные значения, если в npc_abilities указано положительное число
    if self.slow_pct > 0 then self.slow_pct = -self.slow_pct end
    if self.heal_reduce_pct > 0 then self.heal_reduce_pct = -self.heal_reduce_pct end
end

function modifier_custom_pudge_rot_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    }
end

function modifier_custom_pudge_rot_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow_pct or -10
end

function modifier_custom_pudge_rot_debuff:GetModifierHealAmplify_PercentageTarget()
    return self.heal_reduce_pct or -10
end

function modifier_custom_pudge_rot_debuff:GetModifierHPRegenAmplify_Percentage()
    return self.heal_reduce_pct or -10
end
titan = class({})

LinkLuaModifier("modifier_tugarchik_titan_buff", "abilities/titan.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tugarchik_titan_debuff", "abilities/titan.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tugarchik_titan_kill_reset", "abilities/titan.lua", LUA_MODIFIER_MOTION_NONE)

function titan:GetIntrinsicModifierName()
    return "modifier_tugarchik_titan_kill_reset"
end

function titan:GetChannelTime()
    return self:GetSpecialValueFor("channel_time")
end

function titan:OnSpellStart()
    local caster = self:GetCaster()
    if caster and not caster:IsNull() then
        caster:EmitSound("pesik")
    end
end

function titan:OnChannelFinish(interrupted)
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    if interrupted then
        local debuff = caster:AddNewModifier(caster, self, "modifier_tugarchik_titan_debuff", {duration = 3})
        if debuff then debuff:SetDuration(3, true) end
        caster:EmitSound("mel_vozm")
    else
        local buff = caster:AddNewModifier(caster, self, "modifier_tugarchik_titan_buff", {duration = 6})
        if buff then buff:SetDuration(6, true) end
        caster:EmitSound("burmalda")
    end
end

modifier_tugarchik_titan_buff = class({})
function modifier_tugarchik_titan_buff:IsBuff() return true end
function modifier_tugarchik_titan_buff:IsPurgable() return false end
function modifier_tugarchik_titan_buff:RemoveOnDeath() return true end
function modifier_tugarchik_titan_buff:OnCreated()
    local ability = self:GetAbility()
    self.ms = ability and ability:GetSpecialValueFor("sped") or 0
    self.as = ability and ability:GetSpecialValueFor("atcsped") or 0
    self.scale = ability and ability:GetSpecialValueFor("modl") or 1
end
function modifier_tugarchik_titan_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MODEL_SCALE,
    }
end
function modifier_tugarchik_titan_buff:GetModifierMoveSpeedBonus_Percentage() return self.ms or 0 end
function modifier_tugarchik_titan_buff:GetModifierAttackSpeedBonus_Constant() return self.as or 0 end
function modifier_tugarchik_titan_buff:GetModifierModelScale() return self.scale or 1 end

modifier_tugarchik_titan_debuff = class({})
function modifier_tugarchik_titan_debuff:IsDebuff() return true end
function modifier_tugarchik_titan_debuff:IsPurgable() return true end
function modifier_tugarchik_titan_debuff:OnCreated()
    local ability = self:GetAbility()
    self.as = ability and ability:GetSpecialValueFor("atksped") or 0
    self.ms = ability and ability:GetSpecialValueFor("unsped") or 0
end
function modifier_tugarchik_titan_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end
function modifier_tugarchik_titan_debuff:GetModifierAttackSpeedBonus_Constant() return self.as or 0 end
function modifier_tugarchik_titan_debuff:GetModifierMoveSpeedBonus_Percentage() return self.ms or 0 end

modifier_tugarchik_titan_kill_reset = class({})
function modifier_tugarchik_titan_kill_reset:IsHidden() return true end
function modifier_tugarchik_titan_kill_reset:IsPurgable() return false end
function modifier_tugarchik_titan_kill_reset:RemoveOnDeath() return false end
function modifier_tugarchik_titan_kill_reset:DeclareFunctions()
    return { MODIFIER_EVENT_ON_DEATH }
end
function modifier_tugarchik_titan_kill_reset:OnDeath(keys)
    if not IsServer() then return end
    local parent = self:GetParent()
    local talent = parent:FindAbilityByName("special_bonus_unique_tugarchik_titan_reset_on_kill")
    if not talent or talent:GetLevel() <= 0 then return end
    if keys.attacker ~= parent then return end
    if not keys.unit or keys.unit:IsNull() or keys.unit == parent then return end
    if keys.unit.GetTeamNumber and parent:GetTeamNumber() == keys.unit:GetTeamNumber() then return end

    local ability = parent:FindAbilityByName("titan")
    if ability and not ability:IsNull() then
        ability:EndCooldown()
    end
end

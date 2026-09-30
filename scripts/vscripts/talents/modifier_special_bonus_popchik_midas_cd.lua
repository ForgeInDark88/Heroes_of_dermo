LinkLuaModifier("modifier_special_bonus_popchik_midas_cd", "talents/modifier_special_bonus_popchik_midas_cd", LUA_MODIFIER_MOTION_NONE)

modifier_special_bonus_popchik_midas_cd = class({})

function modifier_special_bonus_popchik_midas_cd:IsHidden() return true end
function modifier_special_bonus_popchik_midas_cd:IsPurgable() return false end

function modifier_special_bonus_popchik_midas_cd:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end

function modifier_special_bonus_popchik_midas_cd:OnAbilityExecuted(params)
    local hero = self:GetParent()
    if params.unit ~= hero or not params.ability then return end
    if params.ability:GetAbilityName() ~= "custom_doom_aura" then return end
    local ability = hero:FindAbilityByName("custom_doom_aura")
    if not ability then return end
    local remaining = ability:GetCooldownTimeRemaining()
    if remaining <= 0 then return end
    ability:EndCooldown()
    ability:StartCooldown(math.max(0, remaining - 20))
end

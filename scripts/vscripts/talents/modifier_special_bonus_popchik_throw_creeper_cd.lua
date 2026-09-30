LinkLuaModifier("modifier_special_bonus_popchik_throw_creeper_cd", "talents/modifier_special_bonus_popchik_throw_creeper_cd", LUA_MODIFIER_MOTION_NONE)

modifier_special_bonus_popchik_throw_creeper_cd = class({})

function modifier_special_bonus_popchik_throw_creeper_cd:IsHidden() return true end
function modifier_special_bonus_popchik_throw_creeper_cd:IsPurgable() return false end

function modifier_special_bonus_popchik_throw_creeper_cd:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end

function modifier_special_bonus_popchik_throw_creeper_cd:OnAbilityExecuted(params)
    local hero = self:GetParent()
    if params.unit ~= hero or not params.ability then return end
    if params.ability:GetAbilityName() ~= "throw_creeper" then return end
    local ability = hero:FindAbilityByName("throw_creeper")
    if not ability then return end
    local remaining = ability:GetCooldownTimeRemaining()
    if remaining <= 0 then return end
    ability:EndCooldown()
    ability:StartCooldown(math.max(0, remaining - 2))
end

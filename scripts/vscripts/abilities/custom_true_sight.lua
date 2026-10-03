modifier_custom_true_sight = class({})

function modifier_custom_true_sight:IsHidden()
    return true
end

function modifier_custom_true_sight:IsPurgable()
    return false
end

function modifier_custom_true_sight:RemoveOnDeath()
    return false
end
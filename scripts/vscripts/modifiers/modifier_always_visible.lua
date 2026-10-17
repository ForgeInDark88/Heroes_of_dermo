-- Глобальный модификатор: герой не может стать невидимым.
-- Вешается только на героев, поэтому любой инвиз (руна, Shadow Blade,
-- Silver Edge, Chmoshnik, способности героев и т.д.) перестаёт скрывать героя.
-- Варды его не получают и остаются невидимыми.
modifier_always_visible = class({})

function modifier_always_visible:IsHidden() return true end
function modifier_always_visible:IsDebuff() return false end
function modifier_always_visible:IsPurgable() return false end
function modifier_always_visible:RemoveOnDeath() return false end
function modifier_always_visible:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

-- Максимальный приоритет, чтобы INVISIBLE = false перебивал INVISIBLE = true
-- от любых других модификаторов
function modifier_always_visible:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_always_visible:CheckState()
    return {
        [MODIFIER_STATE_INVISIBLE] = false,
    }
end

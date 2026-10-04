turbo_warrior = class({})
LinkLuaModifier("modifier_turbo_warrior_passive", "abilities/turbo_warrior", LUA_MODIFIER_MOTION_NONE)

-- Автоматически прокачиваем врождённый скилл
function turbo_warrior:Spawn()
    if IsServer() then
        self:SetLevel(1)
    end
end

-- Пассивная часть (Врождённая)
function turbo_warrior:GetIntrinsicModifierName()
    return "modifier_turbo_warrior_passive"
end

--------------------------------------------------------------------------------
-- Пассивный модификатор (-50% времени возрождения)
--------------------------------------------------------------------------------
modifier_turbo_warrior_passive = class({})

function modifier_turbo_warrior_passive:IsHidden() return true end
function modifier_turbo_warrior_passive:IsPurgable() return false end

function modifier_turbo_warrior_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_RESPAWNTIME,
    }
end

function modifier_turbo_warrior_passive:GetModifierRespawnTime()
    if IsServer() then
        local parent = self:GetParent()
        if parent then
            -- Вычисляем ровно половину от стандартного времени смерти
            local standard_respawn = parent:GetRespawnTime()
            return -(standard_respawn * 0.5)
        end
    end
    return 0
end
